// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Vault is EIP712 {
    using Address for address;

    struct Weight {
        address owner;
        uint256 weight;
    }

    uint256 thereshold;

    mapping(address => uint256) public weights;

    constructor(Weight[] memory _weights, uint256 _thereshold)
        EIP712("ManekiVault", "1.0.0")
    {
        thereshold = _thereshold;
        for (uint256 i = 0; i < _weights.length; i++) {
            weights[_weights[i].owner] = _weights[i].weight;
        }
    }

    // transfer eth
    function execute(
        address to,
        uint256 value,
        bytes memory data
    ) external payable returns (bytes memory result) {
        result = to.functionCallWithValue(data, value);
    }

    function transfer(address payable to, uint256 amount) external payable {
        require(to.send(amount), "Vault: not enough ether");
    }

    function checkSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) external view returns (bool) {
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }

    function hashTransfer(
        address to,
        uint256 amount,
        uint256 nonce
    ) external view returns (bytes32 digest) {
        digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "TRANSFER(address to,uint256 amount,uint256 nonce)"
                    ),
                    to,
                    amount,
                    nonce
                )
            )
        );
    }

    function getHash(
        address to,
        uint256 amount,
        uint256 nonce
    ) external pure returns (bytes32 digest) {
        digest = keccak256(
            abi.encode(
                keccak256("TRANSFER(address to,uint256 amount,uint256 nonce)"),
                to,
                amount,
                nonce
            )
        );
    }

    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }
}
