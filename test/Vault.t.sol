// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/IVault.sol";
import "../src/Vault.sol";
import "../src/MockNft.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VaultTest is Test {
    // event
    event VaultSetup(address indexed owner);
    // admin
    event AddAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);
    // approver
    event AddApprover(address indexed approver, uint256 budget);
    event RemoveApprover(address indexed approver);
    // ether
    event ReceivedEther(address indexed sender, uint256 amount);
    event TransferEther(
        address indexed issuer,
        address indexed recipient,
        uint256 amount
    );

    Vault vault;
    MockNFT nft;

    uint256 private ownerPrivateKey;
    uint256 private admin1PrivateKey;
    uint256 private admin2PrivateKey;
    uint256 private approver1PrivateKey;
    uint256 private approver2PrivateKey;
    uint256 private recipientPrivateKey;

    address internal ownerAddress;
    address internal admin1Address;
    address internal admin2Address;
    address internal approver1Address;
    address internal approver2Address;
    address payable internal recipientAddress;

    address internal vaultAddress;
    address internal nftAddress;
    address internal tokenAddress;

    function setUp() public {
        ownerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        admin1PrivateKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
        admin2PrivateKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        approver1PrivateKey = 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6;
        approver2PrivateKey = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;
        recipientPrivateKey = 0xA11CE;

        ownerAddress = vm.addr(ownerPrivateKey);
        admin1Address = vm.addr(admin1PrivateKey);
        admin2Address = vm.addr(admin2PrivateKey);
        approver1Address = vm.addr(approver1PrivateKey);
        approver2Address = vm.addr(approver2PrivateKey);
        recipientAddress = payable(vm.addr(recipientPrivateKey));

        address[] memory admins = new address[](2);
        admins[0] = admin1Address;
        admins[1] = admin2Address;

        Vault.Approver[] memory approvers = new Vault.Approver[](2);
        approvers[0] = IVault.Approver(approver1Address, 1000_000000);
        approvers[1] = IVault.Approver(approver2Address, 100_000000);

        vault = new Vault(ownerAddress, admins, approvers);
        vaultAddress = address(vault);

        nft = new MockNFT("mock", "MOCK", vaultAddress);
        nftAddress = address(nft);

        vm.deal(address(vault), 5 ether);
    }

    function testInitialize() public {
        assertEq(vault.owner(), ownerAddress);
        assertTrue(vault.isAdmin(admin1Address));
        assertTrue(vault.isAdmin(admin2Address));
        assertEq(vault.budget(approver1Address), 1000_000000);
        assertEq(vault.budget(approver2Address), 100_000000);
    }

    function testManageAdmin() public {
        vm.startPrank(ownerAddress);
        vm.expectEmit(true, true, false, true);
        // remove admin
        emit RemoveAdmin(admin1Address);
        vault.removeAdmin(admin1Address);
        assertFalse(vault.isAdmin(admin1Address));
        assertTrue(vault.isAdmin(admin2Address));
        // add admin
        emit AddAdmin(admin1Address);
        vault.addAdmin(admin1Address);
        assertTrue(vault.isAdmin(admin1Address));
        assertTrue(vault.isAdmin(admin2Address));
        // stop impersonate
        vm.stopPrank();
    }

    function testRequestApproval() public {
        vm.prank(recipientAddress);
        // assume that 1 eth = 1000 usd
        uint256 requestId = vault.requestApproval(
            IVault.RequestType.TRANSFER,
            recipientAddress,
            1 ether,
            1000000000,
            ""
        );
        assertEq(requestId, 0);
        IVault.Request memory request = vault.getRequest(0);
        assertEq(request.requester, recipientAddress);
        assertEq(request.to, recipientAddress);
        assertEq(request.value, 1 ether);
        assertEq(request.budget, 1000_000000);
        assertEq(request.data, "");
    }

    function testCanApprove() public {
        assertTrue(vault.canApprove(ownerAddress, 0));
        assertTrue(vault.canApprove(admin1Address, 1));
        assertTrue(vault.canApprove(admin2Address, 10000000000));
        assertTrue(vault.canApprove(approver1Address, 1000_000000));
        assertFalse(vault.canApprove(approver2Address, 1000_000000));
    }

    function testApproveTransfer() public {
        // request with invalid request id
        vm.expectRevert("Vault: invalid requestId");
        vm.prank(ownerAddress);
        vault.approveRequest(1);
        // add request
        vm.prank(recipientAddress);
        uint256 requestId = vault.requestApproval(
            IVault.RequestType.TRANSFER,
            recipientAddress,
            1 ether,
            1000_000000,
            ""
        );
        // unauthorized
        vm.prank(recipientAddress);
        vm.expectRevert("Vault: Unauthorized");
        vault.approveRequest(requestId);
        // approver approve
        vm.prank(approver1Address);
        vault.approveRequest(requestId);
        address payable recipient = payable(recipientAddress);
        assertEq(recipient.balance, 1 ether);
        assertEq(vault.budget(approver1Address), 0);
    }

    // function testTransfer() public {
    //     vm.prank(ownerAddress);
    //     // assume that 1 eth = 1000 usd
    //     // owner transfer
    //     vault.transfer(recipientAddress, 1 ether, 0);
    //     assertEq(recipientAddress.balance, 1 ether);
    //     // admin transfer
    //     vm.prank(admin1Address);
    //     vault.transfer(recipientAddress, 1 ether, 1000_000000);
    //     assertEq(recipientAddress.balance, 2 ether);
    //     // approver transfer
    //     vm.prank(approver1Address);
    //     vault.transfer(recipientAddress, 1 ether, 1000_000000);
    //     assertEq(recipientAddress.balance, 3 ether);
    //     assertEq(vault.budget(approver1Address), 0);
    //     // approver2 transfer
    //     vm.expectRevert("Vault: Unauthorized");
    //     vm.prank(approver2Address);
    //     vault.transfer(recipientAddress, 1 ether, 1000_000000);
    // }
}
