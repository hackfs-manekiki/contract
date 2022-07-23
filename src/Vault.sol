//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IVault.sol";

contract Vault is IVault, Ownable {
    using Address for address;

    // global var
    mapping(address => Approver) approvers;
    mapping(address => string) admins;
    mapping(address => string) members;
    mapping(uint256 => Request) requests;
    mapping(uint256 => bool) executedRequest;
    uint256 internal _nextRequestId;
    string internal _name;

    constructor(address _owner, VaultParam memory param) {
        _transferOwnership(_owner);
        _name = param.name;
        _nextRequestId = 0;

        for (uint256 i = 0; i < param.admins.length; i++) {
            admins[param.admins[i].member] = param.admins[i].name;
            emit AddAdmin(param.admins[i].member, param.admins[i].name);
        }
        for (uint256 i = 0; i < param.approvers.length; i++) {
            approvers[param.approvers[i].approver] = param.approvers[i];
            emit AddApprover(
                param.approvers[i].approver,
                param.approvers[i].name,
                param.approvers[i].budget
            );
        }
        for (uint256 i = 0; i < param.members.length; i++) {
            members[param.members[i].member] = param.members[i].name;
            emit AddMember(param.members[i].member, param.members[i].name);
        }
    }

    function _canApprove(address sender, uint256 _budget)
        internal
        view
        returns (bool)
    {
        bool isOwner = sender == owner();
        return
            isOwner || _isAdmin(sender) || approvers[sender].budget >= _budget;
    }

    function _isMember(address sender) internal view returns (bool) {
        bytes memory name = bytes(members[sender]);
        return name.length != 0;
    }

    function _isAdmin(address sender) internal view returns (bool) {
        bytes memory name = bytes(admins[sender]);
        return name.length != 0;
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

    modifier onlyMember() {
        address sender = _msgSender();
        require(
            _isMember(sender) || _canApprove(sender, 1),
            "Vault: not a member"
        );
        _;
    }

    function requestApproval(Request memory request)
        external
        onlyMember
        returns (uint256 requestId)
    {
        require(request.requester == _msgSender(), "Vault: invalid requester");
        // save to request
        requestId = _nextRequestId;
        requests[requestId] = request;
        executedRequest[requestId] = false;
        emit RequestApproval(
            requestId,
            _msgSender(),
            request.value,
            request.budget
        );
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

        if (
            _msgSender() != owner() &&
            !_isAdmin(_msgSender()) &&
            approvers[_msgSender()].budget > 0
        ) {
            approvers[_msgSender()].budget -= request.budget;
        }
        executedRequest[requestId] = true;
        emit ApprovalExecute(
            requestId,
            _msgSender(),
            request.value,
            request.budget
        );
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
    }

    function addAdmin(address _admin, string memory _adminName)
        external
        onlyOwner
    {
        admins[_admin] = _adminName;
        emit AddAdmin(_admin, _adminName);
    }

    function removeAdmin(address _admin) external onlyOwner {
        delete admins[_admin];
        emit RemoveAdmin(_admin);
    }

    function addApprover(
        address _approver,
        string memory _approverName,
        uint256 _budget
    ) external onlyOwner {
        approvers[_approver] = Approver(_approver, _approverName, _budget);
        emit AddApprover(_approver, _approverName, _budget);
    }

    function removeApprover(address _approver) external onlyOwner {
        delete approvers[_approver];
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
        return _isAdmin(_admin);
    }

    function budget(address _approver) external view returns (uint256) {
        return approvers[_approver].budget;
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

    function getName() external view returns (string memory) {
        return _name;
    }
}
