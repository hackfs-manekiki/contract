//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    enum RequestType {
        TRANSFER,
        EXECUTE
    }

    struct Approver {
        address approver;
        uint256 budget;
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
    event AddAdmin(address indexed admin);
    event RemoveAdmin(address indexed admin);
    // approver
    event AddApprover(address indexed approver, uint256 budget);
    event RemoveApprover(address indexed approver);
    // request
    event RequestApproval(
        uint256 requestId,
        address indexed requester,
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

    function approveRequest(uint256 executeId) external payable;

    function addAdmin(address _admin) external;

    function removeAdmin(address _admin) external;

    function addApprover(address _approver, uint256 _budget) external;

    function removeApprover(address _approver) external;

    // getter
    function getOwner() external view returns (address);

    function isAdmin(address _admin) external view returns (bool);

    function budget(address _approver) external view returns (uint256);

    function getRequest(uint256 requestId)
        external
        view
        returns (Request memory);

    function nextRequestId() external view returns (uint256);
}
