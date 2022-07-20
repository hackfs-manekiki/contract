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

    function _canApprove(address sender, uint256 _budget)
        internal
        view
        returns (bool)
    {
        return
            sender == owner() || admins[sender] || approvers[sender] >= _budget;
    }

    modifier authorized(uint256 requestId) {
        require(_nextRequestId >= requestId, "Vault: invalid requestId");
        require(!executedRequest[requestId], "Vault: request already executed");
        Request memory request = requests[requestId];
        uint256 _budget = request.budget;
        address sender = _msgSender();
        require(_canApprove(sender, _budget), "Vault: Unauthorized");
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

    function approveRequest(uint256 requestId)
        external
        payable
        override
        authorized(requestId)
        returns (bool isSuccess, bytes memory result)
    {
        Request memory request = requests[requestId];
        if (request.requestType == RequestType.TRANSFER) {
            address payable to = payable(request.to);
            require(to.send(request.value), "Vault: not enough ether");
            isSuccess = true;
            result = bytes("");
        } else {
            result = request.to.functionCallWithValue(
                request.data,
                request.value
            );
        }
        if (
            _msgSender() != owner() &&
            !admins[_msgSender()] &&
            approvers[_msgSender()] > 0
        ) {
            approvers[_msgSender()] -= request.budget;
        }
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

    function isExecuted(uint256 requestId) external view returns (bool) {
        return executedRequest[requestId];
    }

    function canApprove(address approver, uint256 _budget)
        external
        view
        returns (bool)
    {
        return _canApprove(approver, _budget);
    }
}
