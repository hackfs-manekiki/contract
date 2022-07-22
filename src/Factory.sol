//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vault.sol";
import "./IVault.sol";

contract Factory is Ownable {
    using Address for address;

    // event
    event VaultSetup(address indexed vault, string name, address indexed owner);

    constructor() {}

    function createVault(IVault.VaultParam calldata param)
        external
        returns (address vaultAddress)
    {
        vaultAddress = _createVault(param);
    }

    function batchCreateVault(IVault.VaultParam[] calldata params)
        external
        returns (address[] memory vaultAddresses)
    {
        vaultAddresses = new address[](params.length);
        for (uint256 i = 0; i < params.length; i++) {
            vaultAddresses[i] = _createVault(params[i]);
        }
    }

    function _createVault(IVault.VaultParam memory param)
        internal
        returns (address vaultAddress)
    {
        Vault vault = new Vault(_msgSender(), param);
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
