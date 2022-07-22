//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vault.sol";
import "./IVault.sol";

contract Factory is Ownable {
    using Address for address;

    struct VaultParam {
        string name;
        address[] admins;
        IVault.Approver[] approvers;
    }

    // event
    event VaultSetup(address indexed vault, string name, address indexed owner);

    constructor() {}

    function createVault(VaultParam calldata param)
        external
        returns (address vaultAddress)
    {
        vaultAddress = _createVault(param);
    }

    function batchCreateVault(VaultParam[] calldata params)
        external
        returns (address[] memory vaultAddresses)
    {
        vaultAddresses = new address[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            vaultAddresses[i] = _createVault(params[i]);
        }
    }

    function _createVault(VaultParam memory param)
        internal
        returns (address vaultAddress)
    {
        Vault vault = new Vault(
            param.name,
            _msgSender(),
            param.admins,
            param.approvers
        );
        vaultAddress = address(vault);
        emit VaultSetup(vaultAddress, param.name, _msgSender());
    }

    fallback() external payable {
        revert("Factory: unknown function");
    }

    receive() external payable {
        revert("Factory: not accept ETH here");
    }
}
