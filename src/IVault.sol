//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    enum RequestType {
        TRANSFER,
        EXECUTE
    }

    struct VaultParam {
        string name;
        IVault.Member[] admins;
        IVault.Approver[] approvers;
        IVault.Member[] members;
    }

    struct Approver {
        address approver;
        string name;
        uint256 budget;
    }

    struct Member {
        address member;
        string name;
    }

    struct Request {
        address requester;
        address to;
        RequestType requestType;
        uint256 value;
        uint256 budget;
        bytes data;
    }

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

    function requestApproval(
        RequestType requestType,
        address to,
        uint256 value,
        uint256 budget,
        bytes memory data
    ) external returns (uint256 requestId);

    function approveRequest(uint256 requestId)
        external
        payable
        returns (bool isSuccess, bytes memory result);

    function addAdmin(address _admin, string memory _adminName) external;

    function removeAdmin(address _admin) external;

    function addApprover(
        address _approver,
        string memory _approverName,
        uint256 _budget
    ) external;

    function removeApprover(address _approver) external;

    // getter
    function getName() external view returns (string memory);

    function getOwner() external view returns (address);

    function isAdmin(address _admin) external view returns (bool);

    function budget(address _approver) external view returns (uint256);

    function getRequest(uint256 requestId)
        external
        view
        returns (Request memory);

    function nextRequestId() external view returns (uint256);

    function isExecuted(uint256 requestId) external view returns (bool);

    function canApprove(address approver, uint256 budget)
        external
        view
        returns (bool);
}
