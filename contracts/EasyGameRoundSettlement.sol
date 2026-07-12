// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/Types.sol";
import "./rounds/IEasyGameRoundManager.sol";

interface IEasyGameSettlementCore {
    function getRoundGameStats(uint256 roundId) external view returns (
        uint256 prizePoolEth,
        uint256 prizePoolUsdc,
        uint256 totalWeight,
        uint256 activeCells,
        uint256 nextCell,
        uint256 nextOpenParent
    );
    function getRoundMatrixNode(uint256 roundId, uint256 cellId)
        external view returns (MatrixNode memory);
    function releaseRoundPools(uint256 roundId)
        external returns (uint256 ethAmount, uint256 usdcAmount);
}

interface IEasyGameArenaStatus {
    function arenaStatus(uint256 roundId, address player)
        external view returns (uint64 frozenUntil, uint16 freezeHits, uint16 freezeTokens);
}

contract EasyGameRoundSettlement {
    IEasyGameSettlementCore public immutable gameCore;
    IEasyGameRoundManager public immutable roundManager;
    IEasyGameArenaStatus public immutable arenaSkills;
    IERC20Minimal public immutable usdcToken;

    mapping(uint256 => bool) public roundSettled;
    mapping(uint8 => uint256) public rolloverEthByLevel;
    mapping(uint8 => uint256) public rolloverUsdcByLevel;
    mapping(address => uint256) public claimableEth;
    mapping(address => uint256) public claimableUsdc;
    uint256 private _lock = 1;

    event WinnerRegistered(
        uint256 indexed roundId,
        uint256 indexed cellId,
        address indexed winner
    );
    event FrozenWinnerSkipped(
        uint256 indexed roundId,
        uint256 indexed cellId,
        address indexed player
    );
    event RoundPrizeAllocated(
        uint256 indexed roundId,
        uint8 indexed level,
        uint16 winnerCount,
        uint256 ethAmount,
        uint256 usdcAmount
    );
    event PrizeRolledOver(
        uint256 indexed roundId,
        uint8 indexed level,
        uint256 ethAmount,
        uint256 usdcAmount
    );
    event SettlementPrizeClaimed(address indexed player, uint256 ethAmount, uint256 usdcAmount);

    modifier nonReentrant() {
        require(_lock == 1, "Reentrant call");
        _lock = 2;
        _;
        _lock = 1;
    }

    constructor(address core_, address manager_, address skills_, address usdc_) {
        require(
            core_ != address(0) && manager_ != address(0) &&
                skills_ != address(0) && usdc_ != address(0),
            "Invalid settlement config"
        );
        gameCore = IEasyGameSettlementCore(core_);
        roundManager = IEasyGameRoundManager(manager_);
        arenaSkills = IEasyGameArenaStatus(skills_);
        usdcToken = IERC20Minimal(usdc_);
    }

    receive() external payable {
        require(msg.sender == address(gameCore), "Only game core");
    }

    function settleRound(
        uint256 roundId,
        uint256[] calldata winningCellIds,
        bytes32[][] calldata proofs
    ) external nonReentrant {
        require(!roundSettled[roundId], "Round already settled");
        require(
            roundManager.getRoundPhase(roundId) == RoundPhase.SettlementReady,
            "Round is not ready"
        );
        RoundConfig memory config = roundManager.getRoundConfig(roundId);
        uint256 candidateCount = winningCellIds.length;
        require(candidateCount == config.maxWinners && proofs.length == candidateCount, "Complete winner set required");

        (,,,, uint256 nextCell,) = gameCore.getRoundGameStats(roundId);
        address[] memory winners = new address[](candidateCount);
        uint16 winnerCount;
        uint256 previousCell;
        for (uint256 i = 0; i < candidateCount; i++) {
            uint256 cellId = winningCellIds[i];
            require(cellId > previousCell, "Winning cells must be sorted");
            previousCell = cellId;
            bytes32 leaf = keccak256(abi.encode(roundId, cellId));
            require(_verifyProof(proofs[i], config.winningCellsRoot, leaf), "Invalid winning cell proof");
            if (cellId >= nextCell) continue;

            MatrixNode memory node = gameCore.getRoundMatrixNode(roundId, cellId);
            if (node.player == address(0) || _alreadyIncluded(winners, winnerCount, node.player)) continue;
            (uint64 frozenUntil,,) = arenaSkills.arenaStatus(roundId, node.player);
            if (frozenUntil >= config.endsAt) {
                emit FrozenWinnerSkipped(roundId, cellId, node.player);
                continue;
            }
            winners[winnerCount++] = node.player;
            emit WinnerRegistered(roundId, cellId, node.player);
        }

        (uint256 ethAmount, uint256 usdcAmount) = gameCore.releaseRoundPools(roundId);
        ethAmount += rolloverEthByLevel[config.level];
        usdcAmount += rolloverUsdcByLevel[config.level];
        rolloverEthByLevel[config.level] = 0;
        rolloverUsdcByLevel[config.level] = 0;

        if (winnerCount == 0) {
            rolloverEthByLevel[config.level] = ethAmount;
            rolloverUsdcByLevel[config.level] = usdcAmount;
            emit PrizeRolledOver(roundId, config.level, ethAmount, usdcAmount);
        } else {
            _allocate(winners, winnerCount, ethAmount, usdcAmount);
            emit RoundPrizeAllocated(roundId, config.level, winnerCount, ethAmount, usdcAmount);
        }

        roundSettled[roundId] = true;
        roundManager.markRoundSettled(roundId, winnerCount);
    }

    function claimPrize() external nonReentrant {
        uint256 ethAmount = claimableEth[msg.sender];
        uint256 usdcAmount = claimableUsdc[msg.sender];
        require(ethAmount > 0 || usdcAmount > 0, "No settlement prize");
        claimableEth[msg.sender] = 0;
        claimableUsdc[msg.sender] = 0;
        if (ethAmount > 0) {
            (bool ok,) = payable(msg.sender).call{value: ethAmount}("");
            require(ok, "ETH claim failed");
        }
        if (usdcAmount > 0) {
            require(usdcToken.transfer(msg.sender, usdcAmount), "USDC claim failed");
        }
        emit SettlementPrizeClaimed(msg.sender, ethAmount, usdcAmount);
    }

    function _allocate(
        address[] memory winners,
        uint16 winnerCount,
        uint256 ethAmount,
        uint256 usdcAmount
    ) private {
        uint256 ethShare = ethAmount / winnerCount;
        uint256 usdcShare = usdcAmount / winnerCount;
        uint256 ethRemainder = ethAmount - (ethShare * winnerCount);
        uint256 usdcRemainder = usdcAmount - (usdcShare * winnerCount);
        for (uint256 i = 0; i < winnerCount; i++) {
            claimableEth[winners[i]] += ethShare + (i == 0 ? ethRemainder : 0);
            claimableUsdc[winners[i]] += usdcShare + (i == 0 ? usdcRemainder : 0);
        }
    }

    function _alreadyIncluded(address[] memory winners, uint16 count, address player)
        private pure returns (bool)
    {
        for (uint256 i = 0; i < count; i++) {
            if (winners[i] == player) return true;
        }
        return false;
    }

    function _verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        private pure returns (bool)
    {
        bytes32 computed = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 sibling = proof[i];
            computed = computed < sibling
                ? keccak256(abi.encodePacked(computed, sibling))
                : keccak256(abi.encodePacked(sibling, computed));
        }
        return computed == root;
    }
}
