// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/IVault.sol";
import "../src/Vault.sol";
import "../src/MockToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VaultTest is Test {
    // admin
    event AddAdmin(address indexed admin, string name);
    event RemoveAdmin(address indexed admin);
    // approver
    event AddApprover(
        address indexed approver,
        string _approverName,
        uint256 budget
    );
    event RemoveApprover(address indexed approver);
    // member
    event AddMember(address indexed member, string name);
    event RemoveMember(address indexed member);
    // request
    event RequestApproval(
        uint256 requestId,
        address indexed requester,
        uint256 value,
        uint256 budget
    );
    event ApprovalExecute(
        uint256 requestId,
        address indexed executor,
        uint256 value,
        uint256 budget
    );
    // ether
    event ReceivedEther(address indexed sender, uint256 amount);
    event TransferEther(
        address indexed issuer,
        address indexed recipient,
        uint256 amount
    );

    Vault vault;
    MockToken token;

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

        IVault.Member[] memory admins = new IVault.Member[](2);
        admins[0] = IVault.Member(admin1Address, "admin1");
        admins[1] = IVault.Member(admin2Address, "admin2");

        Vault.Approver[] memory approvers = new Vault.Approver[](2);
        approvers[0] = IVault.Approver(
            approver1Address,
            "approver1",
            1000_000000
        );
        approvers[1] = IVault.Approver(
            approver2Address,
            "approver2",
            100_000000
        );

        IVault.Member[] memory members = new IVault.Member[](1);
        members[0] = IVault.Member(recipientAddress, "member1");

        IVault.VaultParam memory param = IVault.VaultParam(
            "test",
            admins,
            approvers,
            members
        );

        vault = new Vault(ownerAddress, param);
        vaultAddress = address(vault);

        token = new MockToken("usd", "USD", 6);
        tokenAddress = address(token);

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
        emit AddAdmin(admin1Address, "admin1");
        vault.addAdmin(admin1Address, "admin1");
        assertTrue(vault.isAdmin(admin1Address));
        assertTrue(vault.isAdmin(admin2Address));
        // stop impersonate
        vm.stopPrank();
    }

    function testRequestApproval() public {
        vm.prank(recipientAddress);
        vm.expectEmit(true, true, true, false);
        emit RequestApproval(0, recipientAddress, 1 ether, 1000_000000);
        IVault.Request memory request = IVault.Request(
            recipientAddress,
            recipientAddress,
            IVault.RequestType.TRANSFER,
            1 ether,
            1000_000000,
            "",
            "test transfer ether",
            "hello world",
            "ipfs://test"
        );
        // assume that 1 eth = 1000 usd
        uint256 requestId = vault.requestApproval(request);
        assertEq(requestId, 0);
        IVault.Request memory requestOutput = vault.getRequest(0);
        assertEq(requestOutput.requester, recipientAddress);
        assertEq(requestOutput.to, recipientAddress);
        assertEq(requestOutput.value, 1 ether);
        assertEq(requestOutput.budget, 1000_000000);
        assertEq(requestOutput.data, "");
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
        IVault.Request memory request = IVault.Request(
            recipientAddress,
            recipientAddress,
            IVault.RequestType.TRANSFER,
            1 ether,
            1000_000000,
            "",
            "test transfer ether",
            "hello world",
            "ipfs://test"
        );
        uint256 requestId = vault.requestApproval(request);
        // unauthorized
        vm.prank(recipientAddress);
        vm.expectRevert("Vault: Unauthorized");
        vault.approveRequest(requestId);
        // approver approve
        vm.prank(approver1Address);
        vm.expectEmit(true, true, true, false);
        emit ApprovalExecute(0, approver1Address, 1 ether, 1000_000000);
        vault.approveRequest(requestId);
        address payable recipient = payable(recipientAddress);
        assertEq(recipient.balance, 1 ether);
        assertEq(vault.budget(approver1Address), 0);
        assertEq(vault.isExecuted(requestId), true);
        assertFalse(vault.canApprove(approver1Address, 1000_0000));
        // approver cannot approve
        vm.prank(recipientAddress);
        IVault.Request memory request2 = IVault.Request(
            recipientAddress,
            recipientAddress,
            IVault.RequestType.TRANSFER,
            100 ether,
            100000_000000,
            "",
            "test transfer ether",
            "hello world",
            "ipfs://test"
        );
        uint256 requestId2 = vault.requestApproval(request2);
        vm.prank(approver2Address);
        vm.expectRevert("Vault: Unauthorized");
        vault.approveRequest(requestId2);
        // approve executed request
        vm.prank(admin1Address);
        vm.expectRevert("Vault: request already executed");
        vault.approveRequest(requestId);
        // vault has not enough ether
        vm.prank(admin1Address);
        vm.expectRevert("Vault: not enough ether");
        vault.approveRequest(requestId2);
        // success
        vm.deal(address(vault), 2000 ether);
        vm.deal(recipientAddress, 0 ether);
        vm.prank(admin1Address);
        vm.expectEmit(true, true, true, false);
        emit ApprovalExecute(0, admin1Address, 1000 ether, 100000_000000);
        vault.approveRequest(requestId2);
        assertEq(recipient.balance, 100 ether);
        assertEq(vault.isExecuted(requestId2), true);
        assertTrue(vault.canApprove(admin1Address, 1000_0000));
    }

    function testApproveTransferToken() public {
        vm.prank(recipientAddress);
        IVault.Request memory request = IVault.Request(
            recipientAddress,
            tokenAddress,
            IVault.RequestType.EXECUTE,
            0,
            1000_000000,
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                recipientAddress,
                1000_000000
            ),
            "test transfer token",
            "hello world",
            "ipfs://test"
        );
        uint256 requestId = vault.requestApproval(request);
        token.mint(vaultAddress, 1000_000000);
        // approve
        vm.prank(approver1Address);
        vault.approveRequest(requestId);
        assertEq(token.balanceOf(recipientAddress), 1000_000000);
        assertEq(vault.budget(approver1Address), 0);
        assertEq(vault.isExecuted(requestId), true);
        assertFalse(vault.canApprove(approver1Address, 1000_0000));
    }
}
