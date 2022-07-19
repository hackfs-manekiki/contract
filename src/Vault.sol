//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    using Address for address;

    struct Approver {
        address approver;
        uint256 budget;
    }

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
    // global var
    uint256 thereshold;

    mapping(address => uint256) public approvers;
    mapping(address => bool) public admins;

    constructor(
        address _owner,
        address[] memory _admins,
        Approver[] memory _approvers
    ) {
        _transferOwnership(_owner);
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
            emit AddAdmin(_admins[i]);
        }
        for (uint256 i = 0; i < _approvers.length; i++) {
            approvers[_approvers[i].approver] = _approvers[i].budget;
            emit AddApprover(_approvers[i].approver, _approvers[i].budget);
        }
    }

    modifier authorized(uint256 budget) {
        address sender = _msgSender();
        require(
            sender == owner() || admins[sender] || approvers[sender] >= budget,
            "Vault: Unauthorized"
        );
        _;
    }

    function transfer(
        address payable to,
        uint256 amount,
        uint256 budget
    ) external payable authorized(budget) {
        require(to.send(amount), "Vault: not enough ether");
        if (
            _msgSender() != owner() &&
            !admins[_msgSender()] &&
            approvers[_msgSender()] > 0
        ) {
            approvers[_msgSender()] -= budget;
        }
        emit TransferEther(_msgSender(), to, amount);
    }

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        uint256 budget
    ) external payable authorized(budget) returns (bytes memory result) {
        result = to.functionCallWithValue(data, value);
    }

    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
        emit AddAdmin(_admin);
    }

    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
        emit RemoveAdmin(_admin);
    }

    function addApprover(address _approver, uint256 _budget)
        external
        onlyOwner
    {
        approvers[_approver] = _budget;
        emit AddApprover(_approver, _budget);
    }

    function removeApprover(address _approver) external onlyOwner {
        approvers[_approver] = 0;
        emit RemoveApprover(_approver);
    }

    fallback() external payable {
        if (msg.value > 0) {
            emit ReceivedEther(_msgSender(), msg.value);
        }
    }

    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }
}
