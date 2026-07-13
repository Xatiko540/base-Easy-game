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
    IERC20Minimal public immutable usdcToken;
    IEasyGameBasePayCore public immutable gameCore;
    address public owner;
    address public fulfiller;
    mapping(bytes32 => bool) public processedPayments;
    uint256 private _lock = 1;

    event BasePayRoundFulfilled(
        bytes32 indexed paymentId,
        address indexed player,
        uint256 indexed roundId,
        uint256 amount
    );
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
        require(player != address(0), "Player required");
        require(usdcToken.balanceOf(address(this)) >= config.usdcPrice, "Payment not received");

        processedPayments[paymentId] = true;
        gameCore.activateRoundFromBasePay(config, signature, player, inviter);
        emit BasePayRoundFulfilled(paymentId, player, config.roundId, config.usdcPrice);
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
