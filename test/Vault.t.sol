// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/MockNft.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VaultTest is Test {
    Vault vault;
    MockNFT nft;

    uint256 internal address1PrivateKey;

    address internal address1;

    address internal vaultAddress;
    address internal nftAddress;

    function setUp() public {
        address1PrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address1 = vm.addr(address1PrivateKey);
        emit log_address(address1);

        Vault.Weight[] memory weights = new Vault.Weight[](1);
        weights[0] = Vault.Weight(address1, 1);

        vault = new Vault(weights, 1);
        vaultAddress = address(vault);

        nft = new MockNFT("mock", "MOCK", vaultAddress);
        nftAddress = address(nft);

        vm.deal(address(vault), 1 ether);
    }

    function testExecute() public {
        vault.execute(
            nftAddress,
            0,
            abi.encodeWithSignature("mint(address,uint256)", address1, 1)
        );
        assertEq(address1, nft.ownerOf(1));
    }

    function testTransfer() public {
        address payable receiver = payable(address1);
        vault.transfer(receiver, 0.5 ether);
        assertEq(0.5 ether, address1.balance);
    }

    function testSignature() public {
        bytes32 digest = vault.hashTransfer(address1, 0.5 ether, 1);
        emit log_bytes32(digest);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(address1PrivateKey, digest);
        string memory v_string = Strings.toString(uint256(v));
        emit log_string(v_string);
        uint256 value = uint256(v);
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        bytes memory signature = bytes.concat(r, s, bytes1(v));
        emit log_bytes(signature);
        assertTrue(vault.checkSignature(address1, digest, signature));
    }
}
