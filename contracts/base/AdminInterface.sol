// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Types.sol";
import "./Errors.sol";
import "./Validation.sol";
import "./Storage.sol";

abstract contract AdminInterface is EasyGameAdvanceStorage {
    event LevelAvailabilityChanged(uint8 indexed level, bool available);
    event WalletsChanged(address projectWallet, address treasuryWallet, address operatorWallet);
    event UsdcTokenChanged(address indexed oldToken, address indexed newToken);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event RoundManagerChanged(address indexed oldManager, address indexed newManager);
    event SettlementContractChanged(address indexed oldSettlement, address indexed newSettlement);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier nonReentrant() {
        require(_reentrancyLock == 1, "Reentrant call");
        _reentrancyLock = 2;
        _;
        _reentrancyLock = 1;
    }

    function _validateLevel(uint8 level) internal pure {
        Validation.validateLevel(level);
    }

    function _safeTransfer(address payable receiver, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        (bool ok, ) = receiver.call{value: amount}("");
        require(ok, "Transfer failed");
    }

    function _safeTransferToken(
        IERC20Minimal token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        require(token.transfer(receiver, amount), "Token transfer failed");
    }

    function setRoundManager(address newManager) external onlyOwner {
        if (newManager == address(0)) revert ZeroAddress();
        address oldManager = roundManager;
        roundManager = newManager;
        emit RoundManagerChanged(oldManager, newManager);
    }

    function setSettlementContract(address newSettlement) external onlyOwner {
        if (newSettlement == address(0)) revert ZeroAddress();
        address oldSettlement = settlementContract;
        settlementContract = newSettlement;
        emit SettlementContractChanged(oldSettlement, newSettlement);
    }

    function getPlayer(address playerAddress) external view returns (Player memory) {
        return players[playerAddress];
    }

    /// @notice USDC is shared with immutable skills and settlement contracts.
    /// Changing only the core token would split accounting between different
    /// assets, so token migration requires a coordinated redeploy.
    function setUsdcToken(address) external view onlyOwner {
        revert UsdcTokenLocked();
    }

    function setLevelAvailable(uint8 level, bool available) external onlyOwner {
        _validateLevel(level);
        levelAvailable[level] = available;
        emit LevelAvailabilityChanged(level, available);
    }

    function setWallets(
        address newProjectWallet,
        address newTreasuryWallet,
        address newOperatorWallet
    ) external onlyOwner {
        require(newProjectWallet != address(0), "Project wallet required");
        require(newTreasuryWallet != address(0), "Treasury wallet required");
        require(newOperatorWallet != address(0), "Operator wallet required");

        projectWallet = newProjectWallet;
        treasuryWallet = newTreasuryWallet;
        operatorWallet = newOperatorWallet;

        emit WalletsChanged(projectWallet, treasuryWallet, operatorWallet);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner required");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
