// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Factory.sol";
import "../src/IVault.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VaultTest is Test {
    // event
    event VaultSetup(address indexed owner);

    Factory factory;

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
    }

    function testCreateVault() public {
        address[] memory admins = new address[](2);
        admins[0] = admin1Address;
        admins[1] = admin2Address;

        Vault.Approver[] memory approvers = new Vault.Approver[](2);
        approvers[0] = IVault.Approver(approver1Address, 1000_000000);
        approvers[1] = IVault.Approver(approver2Address, 100_000000);

        Factory.VaultParam memory param = Factory.VaultParam(
            "test",
            admins,
            approvers
        );
        factory = new Factory();
        vm.prank(ownerAddress);
        address vaultAddress = factory.createVault(param);
        IVault vault = IVault(vaultAddress);
        assertEq(vault.getOwner(), ownerAddress);
        assertTrue(vault.isAdmin(admin1Address));
        assertTrue(vault.isAdmin(admin2Address));
        assertEq(vault.budget(approver1Address), 1000_000000);
        assertEq(vault.budget(approver2Address), 100_000000);
    }
}
