//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVault.sol";

contract Vault is IVault, Ownable {
    using Address for address;

    // global var
    mapping(address => uint256) approvers;
    mapping(address => bool) admins;
    mapping(uint256 => Request) requests;
    mapping(uint256 => bool) executedRequest;
    uint256 internal _nextRequestId;

    constructor(
        address _owner,
        address[] memory _admins,
        Approver[] memory _approvers
    ) {
        _transferOwnership(_owner);
        _nextRequestId = 0;
        for (uint256 i = 0; i < _admins.length; i++) {
            admins[_admins[i]] = true;
            emit AddAdmin(_admins[i]);
        }
        for (uint256 i = 0; i < _approvers.length; i++) {
            approvers[_approvers[i].approver] = _approvers[i].budget;
            emit AddApprover(_approvers[i].approver, _approvers[i].budget);
        }
    }

    modifier authorized(uint256 _budget) {
        address sender = _msgSender();
        require(
            sender == owner() || admins[sender] || approvers[sender] >= _budget,
            "Vault: Unauthorized"
        );
        _;
    }

    function requestApproval(
        RequestType requestType,
        address to,
        uint256 value,
        uint256 _budget,
        bytes memory data
    ) external returns (uint256 requestId) {
        // save to request
        Request memory request = Request(
            _msgSender(),
            to,
            requestType,
            value,
            _budget,
            data
        );
        requestId = _nextRequestId;
        requests[requestId] = request;
        executedRequest[requestId] = false;
        emit RequestApproval(requestId, _msgSender(), value, _budget);
        _nextRequestId += 1;
    }

    function approveRequest(uint256 executeId) external payable {}

    // function transfer(
    //     address payable to,
    //     uint256 amount,
    //     uint256 _budget
    // ) external payable override authorized(_budget) {
    //     require(to.send(amount), "Vault: not enough ether");
    //     if (
    //         _msgSender() != owner() &&
    //         !admins[_msgSender()] &&
    //         approvers[_msgSender()] > 0
    //     ) {
    //         approvers[_msgSender()] -= _budget;
    //     }
    //     emit TransferEther(_msgSender(), to, amount);
    // }

    // function execute(
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     uint256 _budget
    // )
    //     external
    //     payable
    //     override
    //     authorized(_budget)
    //     returns (bytes memory result)
    // {
    //     result = to.functionCallWithValue(data, value);
    // }

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

    // getter
    function getOwner() external view returns (address) {
        return owner();
    }

    function isAdmin(address _admin) external view returns (bool) {
        return admins[_admin];
    }

    function budget(address _approver) external view returns (uint256) {
        return approvers[_approver];
    }

    function getRequest(uint256 requestId)
        external
        view
        returns (Request memory)
    {
        return requests[requestId];
    }

    function nextRequestId() external view returns (uint256) {
        return _nextRequestId;
    }
}
