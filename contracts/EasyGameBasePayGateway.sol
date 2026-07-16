// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/Types.sol";

interface IEasyGameBasePayCore {
    function activateRoundFromBasePay(
        RoundConfig calldata config,
        bytes calldata signature,
        address player,
        address inviter
    ) external;
}

contract EasyGameBasePayGateway {
    struct RefundRequest {
        address recipient;
        uint128 amount;
        uint64 executableAt;
    }

    uint64 public constant REFUND_DELAY = 1 days;
    IERC20Minimal public immutable usdcToken;
    IEasyGameBasePayCore public immutable gameCore;
    address public owner;
    address public fulfiller;
    uint256 public reservedRefundUsdc;
    mapping(bytes32 => bool) public processedPayments;
    mapping(bytes32 => RefundRequest) public refundRequests;
    uint256 private _lock = 1;

    event BasePayRoundFulfilled(
        bytes32 indexed paymentId,
        address indexed player,
        uint256 indexed roundId,
        uint256 amount
    );
    event BasePayRefundRequested(
        bytes32 indexed paymentId,
        address indexed recipient,
        uint256 amount,
        uint64 executableAt
    );
    event BasePayRefundCancelled(bytes32 indexed paymentId);
    event BasePayPaymentRefunded(bytes32 indexed paymentId, address indexed recipient, uint256 amount);
    event FulfillerChanged(address indexed oldFulfiller, address indexed newFulfiller);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyFulfiller() {
        require(msg.sender == fulfiller, "Only fulfiller");
        _;
    }

    modifier nonReentrant() {
        require(_lock == 1, "Reentrant call");
        _lock = 2;
        _;
        _lock = 1;
    }

    constructor(address core_, address usdc_, address fulfiller_) {
        require(core_ != address(0) && usdc_ != address(0), "Invalid payment config");
        require(fulfiller_ != address(0), "Fulfiller required");
        owner = msg.sender;
        fulfiller = fulfiller_;
        gameCore = IEasyGameBasePayCore(core_);
        usdcToken = IERC20Minimal(usdc_);
        require(usdcToken.approve(core_, type(uint256).max), "USDC approval failed");
    }

    function fulfillRound(
        bytes32 paymentId,
        RoundConfig calldata config,
        bytes calldata signature,
        address player,
        address inviter
    ) external onlyFulfiller nonReentrant {
        require(paymentId != bytes32(0), "Payment ID required");
        require(!processedPayments[paymentId], "Payment already processed");
        require(refundRequests[paymentId].recipient == address(0), "Refund pending");
        require(player != address(0), "Player required");
        require(
            usdcToken.balanceOf(address(this)) >= config.usdcPrice + reservedRefundUsdc,
            "Payment not received"
        );

        processedPayments[paymentId] = true;
        gameCore.activateRoundFromBasePay(config, signature, player, inviter);
        emit BasePayRoundFulfilled(paymentId, player, config.roundId, config.usdcPrice);
    }

    /// @notice Queues a refund after the backend verifies the original Base Pay
    /// sender and amount. A separate owner confirmation is required after the
    /// delay, so a compromised fulfiller cannot immediately drain the gateway.
    function requestUnfulfilledPaymentRefund(
        bytes32 paymentId,
        address recipient,
        uint256 amount
    ) external onlyFulfiller nonReentrant {
        require(paymentId != bytes32(0), "Payment ID required");
        require(!processedPayments[paymentId], "Payment already processed");
        require(recipient != address(0), "Recipient required");
        require(amount > 0, "Refund amount required");
        require(amount <= type(uint128).max, "Refund amount too large");
        require(refundRequests[paymentId].recipient == address(0), "Refund already requested");
        require(
            usdcToken.balanceOf(address(this)) >= reservedRefundUsdc + amount,
            "Insufficient payment balance"
        );

        uint64 executableAt = uint64(block.timestamp + REFUND_DELAY);
        refundRequests[paymentId] = RefundRequest(recipient, uint128(amount), executableAt);
        reservedRefundUsdc += amount;
        emit BasePayRefundRequested(paymentId, recipient, amount, executableAt);
    }

    function executeUnfulfilledPaymentRefund(bytes32 paymentId)
        external
        onlyOwner
        nonReentrant
    {
        RefundRequest memory request = refundRequests[paymentId];
        require(request.recipient != address(0), "Refund not requested");
        require(block.timestamp >= request.executableAt, "Refund delay active");
        require(!processedPayments[paymentId], "Payment already processed");

        delete refundRequests[paymentId];
        reservedRefundUsdc -= request.amount;
        processedPayments[paymentId] = true;
        require(usdcToken.transfer(request.recipient, request.amount), "USDC refund failed");
        emit BasePayPaymentRefunded(paymentId, request.recipient, request.amount);
    }

    function cancelUnfulfilledPaymentRefund(bytes32 paymentId) external onlyOwner {
        RefundRequest memory request = refundRequests[paymentId];
        require(request.recipient != address(0), "Refund not requested");
        delete refundRequests[paymentId];
        reservedRefundUsdc -= request.amount;
        emit BasePayRefundCancelled(paymentId);
    }

    function setFulfiller(address newFulfiller) external onlyOwner {
        require(newFulfiller != address(0), "Fulfiller required");
        address oldFulfiller = fulfiller;
        fulfiller = newFulfiller;
        emit FulfillerChanged(oldFulfiller, newFulfiller);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner required");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
