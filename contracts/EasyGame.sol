// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EasyGame {
    uint8 public constant LEVEL_COUNT = 17;
    uint16 private constant MATRIX_REWARD_BPS = 8000;
    uint16 private constant DIRECT_BONUS_BPS = 950;
    uint16 private constant OPERATOR_FEE_BPS = 50;
    uint16 private constant SECOND_LINE_BONUS_BPS = 600;
    uint16 private constant THIRD_LINE_BONUS_BPS = 400;
    uint16 private constant BPS_DENOMINATOR = 10000;

    address public owner;
    address payable public treasury;
    address payable public operatorWallet;

    mapping(uint8 => uint256) public levelPrices;
    mapping(uint8 => uint256) public levelMatrixSize;

    mapping(address => Player) private players;
    mapping(address => mapping(uint8 => PlayerLevel)) private playerLevels;
    mapping(uint8 => MatrixNode[]) private levelMatrix;
    mapping(uint8 => uint256) private nextOpenParentIds;

    struct Player {
        bool exists;
        address inviter;
        uint8 maxActiveLevel;
        uint256 totalPaid;
    }

    struct PlayerLevel {
        bool active;
        bool frozen;
        uint256 cycles;
        uint256 positionId;
        uint256 earned;
    }

    struct MatrixNode {
        address player;
        uint256 parentId;
        uint256 leftChildId;
        uint256 rightChildId;
        uint256 depth;
        bool closed;
    }

    event LevelActivated(
        address indexed player,
        uint8 indexed level,
        uint256 amount,
        address indexed inviter
    );
    event MatrixPlaced(
        address indexed player,
        uint8 indexed level,
        uint256 positionId,
        uint256 parentId
    );
    event MatrixRewardPaid(
        address indexed from,
        address indexed to,
        uint8 indexed level,
        uint256 amount
    );
    event ReferralPaid(
        address indexed player,
        address indexed receiver,
        uint8 line,
        uint256 amount
    );
    event Recycled(
        address indexed player,
        uint8 indexed level,
        uint256 cycle,
        uint256 newPositionId
    );
    event LevelFrozen(address indexed player, uint8 indexed level);
    event LevelUnfrozen(address indexed player, uint8 indexed level);
    event LevelPriceChanged(uint8 indexed level, uint256 oldPrice, uint256 newPrice);
    event TreasuryChanged(address indexed oldTreasury, address indexed newTreasury);
    event OperatorWalletChanged(address indexed oldOperatorWallet, address indexed newOperatorWallet);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address payable treasuryAddress) {
        require(treasuryAddress != address(0), "Treasury address is required");

        owner = msg.sender;
        treasury = treasuryAddress;
        operatorWallet = treasuryAddress;

        levelPrices[1] = 0.01 ether;
        levelPrices[2] = 0.015 ether;
        levelPrices[3] = 0.02 ether;
        levelPrices[4] = 0.03 ether;
        levelPrices[5] = 0.04 ether;
        levelPrices[6] = 0.06 ether;
        levelPrices[7] = 0.09 ether;
        levelPrices[8] = 0.13 ether;
        levelPrices[9] = 0.2 ether;
        levelPrices[10] = 0.3 ether;
        levelPrices[11] = 0.4 ether;
        levelPrices[12] = 0.6 ether;
        levelPrices[13] = 0.9 ether;
        levelPrices[14] = 1.3 ether;
        levelPrices[15] = 2 ether;
        levelPrices[16] = 3 ether;
        levelPrices[17] = 4 ether;
    }

    receive() external payable {
        revert("Use activateLevel");
    }

    function activateLevel(uint8 level, address inviter) external payable {
        _validateLevel(level);
        require(msg.value == levelPrices[level], "Incorrect payment amount");

        Player storage player = players[msg.sender];
        PlayerLevel storage state = playerLevels[msg.sender][level];
        require(!state.active, "Level is already active");

        if (level > 1) {
            require(playerLevels[msg.sender][level - 1].active, "Previous level is not active");
        }

        if (!player.exists) {
            player.exists = true;
            if (
                inviter != address(0) &&
                inviter != msg.sender &&
                players[inviter].exists
            ) {
                player.inviter = inviter;
            }
        }

        state.active = true;
        state.frozen = false;
        player.totalPaid += msg.value;
        if (level > player.maxActiveLevel) {
            player.maxActiveLevel = level;
        }

        uint256 positionId = _placePlayer(level, msg.sender);
        _distributePayment(msg.sender, level, msg.value, positionId);
        _unfreezePreviousLevel(msg.sender, level);

        emit LevelActivated(msg.sender, level, msg.value, player.inviter);
    }

    function isLevelActive(address playerAddress, uint8 level) external view returns (bool) {
        _validateLevel(level);
        return playerLevels[playerAddress][level].active;
    }

    function isLevelFrozen(address playerAddress, uint8 level) external view returns (bool) {
        _validateLevel(level);
        return playerLevels[playerAddress][level].frozen;
    }

    function getPlayer(address playerAddress)
        external
        view
        returns (bool exists, address inviter, uint8 maxActiveLevel, uint256 totalPaid)
    {
        Player storage player = players[playerAddress];
        return (player.exists, player.inviter, player.maxActiveLevel, player.totalPaid);
    }

    function getPlayerLevel(address playerAddress, uint8 level)
        external
        view
        returns (bool active, bool frozen, uint256 cycles, uint256 positionId, uint256 earned)
    {
        _validateLevel(level);
        PlayerLevel storage state = playerLevels[playerAddress][level];
        return (state.active, state.frozen, state.cycles, state.positionId, state.earned);
    }

    function getPlayerPosition(address playerAddress, uint8 level)
        external
        view
        returns (uint256 positionId, uint256 parentId, uint256 leftChildId, uint256 rightChildId, uint256 depth, bool closed)
    {
        _validateLevel(level);
        uint256 currentPositionId = playerLevels[playerAddress][level].positionId;
        if (currentPositionId == 0) {
            return (0, 0, 0, 0, 0, false);
        }

        MatrixNode storage node = levelMatrix[level][currentPositionId - 1];
        return (
            currentPositionId,
            node.parentId,
            node.leftChildId,
            node.rightChildId,
            node.depth,
            node.closed
        );
    }

    function getMatrixNode(uint8 level, uint256 positionId)
        external
        view
        returns (address player, uint256 parentId, uint256 leftChildId, uint256 rightChildId, uint256 depth, bool closed)
    {
        _validateLevel(level);
        require(positionId > 0 && positionId <= levelMatrix[level].length, "Invalid position");

        MatrixNode storage node = levelMatrix[level][positionId - 1];
        return (
            node.player,
            node.parentId,
            node.leftChildId,
            node.rightChildId,
            node.depth,
            node.closed
        );
    }

    function getLevelMatrixStats(uint8 level)
        external
        view
        returns (uint256 size, uint256 nextOpenParentId)
    {
        _validateLevel(level);
        return (levelMatrix[level].length, nextOpenParentIds[level]);
    }

    function setLevelPrice(uint8 level, uint256 newPrice) external onlyOwner {
        _validateLevel(level);
        require(newPrice > 0, "Price is required");

        uint256 oldPrice = levelPrices[level];
        levelPrices[level] = newPrice;

        emit LevelPriceChanged(level, oldPrice, newPrice);
    }

    function setTreasury(address payable newTreasury) external onlyOwner {
        require(newTreasury != address(0), "Treasury address is required");

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryChanged(oldTreasury, newTreasury);
    }

    function setOperatorWallet(address payable newOperatorWallet) external onlyOwner {
        require(newOperatorWallet != address(0), "Operator wallet is required");

        address oldOperatorWallet = operatorWallet;
        operatorWallet = newOperatorWallet;

        emit OperatorWalletChanged(oldOperatorWallet, newOperatorWallet);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner address is required");
        owner = newOwner;
    }

    function _placePlayer(uint8 level, address playerAddress) private returns (uint256) {
        MatrixNode[] storage matrix = levelMatrix[level];
        uint256 parentId;
        uint256 depth;
        uint256 positionId;

        if (matrix.length == 0) {
            matrix.push();
            MatrixNode storage rootNode = matrix[matrix.length - 1];
            rootNode.player = playerAddress;
            rootNode.depth = 0;
            rootNode.closed = false;

            nextOpenParentIds[level] = 1;
            positionId = matrix.length;
        }

        if (matrix.length > 1 || positionId == 0) {
            parentId = nextOpenParentIds[level];
            if (parentId == 0) {
                parentId = 1;
            }

            MatrixNode storage parent = matrix[parentId - 1];
            require(!parent.closed, "Matrix parent is closed");
            depth = parent.depth + 1;

            matrix.push();
            MatrixNode storage childNode = matrix[matrix.length - 1];
            childNode.player = playerAddress;
            childNode.parentId = parentId;
            childNode.depth = depth;
            childNode.closed = false;

            uint256 childId = matrix.length;
            positionId = childId;
            if (parent.leftChildId == 0) {
                parent.leftChildId = childId;
            }

            if (parent.leftChildId != childId) {
                parent.rightChildId = childId;
                parent.closed = true;
                _advanceNextOpenParent(level);
                _handleRecycle(level, parent.player);
            }
        }

        playerLevels[playerAddress][level].positionId = positionId;
        levelMatrixSize[level] = matrix.length;

        emit MatrixPlaced(playerAddress, level, positionId, parentId);
        return positionId;
    }

    function _advanceNextOpenParent(uint8 level) private {
        MatrixNode[] storage matrix = levelMatrix[level];
        uint256 nextId = nextOpenParentIds[level];
        if (nextId == 0) {
            nextId = 1;
        }

        while (nextId <= matrix.length && matrix[nextId - 1].closed) {
            nextId++;
        }

        nextOpenParentIds[level] = nextId <= matrix.length ? nextId : 0;
    }

    function _handleRecycle(uint8 level, address playerAddress) private {
        PlayerLevel storage state = playerLevels[playerAddress][level];
        if (!state.active || state.frozen) {
            return;
        }

        state.cycles += 1;
        uint256 newPositionId = _placePlayer(level, playerAddress);

        emit Recycled(playerAddress, level, state.cycles, newPositionId);

        if (
            level < LEVEL_COUNT &&
            state.cycles >= 2 &&
            !playerLevels[playerAddress][level + 1].active &&
            !state.frozen
        ) {
            state.frozen = true;
            emit LevelFrozen(playerAddress, level);
        }
    }

    function _distributePayment(
        address playerAddress,
        uint8 level,
        uint256 amount,
        uint256 positionId
    ) private {
        MatrixNode storage node = levelMatrix[level][positionId - 1];
        address matrixReceiver = _matrixRewardReceiver(level, node.parentId);

        uint256 matrixReward = (amount * MATRIX_REWARD_BPS) / BPS_DENOMINATOR;
        _payAndTrack(playerAddress, payable(matrixReceiver), level, matrixReward);

        uint256 paidReferrals = _payReferralLine(playerAddress, amount);
        uint256 paid = matrixReward + paidReferrals;
        if (amount > paid) {
            _safeTransfer(treasury, amount - paid);
        }
    }

    function _matrixRewardReceiver(uint8 level, uint256 parentId) private view returns (address) {
        if (parentId == 0) {
            return address(treasury);
        }

        address parentPlayer = levelMatrix[level][parentId - 1].player;
        if (playerLevels[parentPlayer][level].frozen) {
            return address(treasury);
        }

        return parentPlayer;
    }

    function _payAndTrack(
        address playerAddress,
        address payable receiver,
        uint8 level,
        uint256 amount
    ) private {
        _safeTransfer(receiver, amount);
        playerLevels[receiver][level].earned += amount;
        emit MatrixRewardPaid(playerAddress, receiver, level, amount);
    }

    function _payReferralLine(address playerAddress, uint256 amount) private returns (uint256) {
        address firstLine = players[playerAddress].inviter;
        uint256 paid;

        paid += _payReferral(playerAddress, firstLine, 1, amount, DIRECT_BONUS_BPS);
        paid += _payReferral(playerAddress, operatorWallet, 0, amount, OPERATOR_FEE_BPS);

        address secondLine = firstLine == address(0) ? address(0) : players[firstLine].inviter;
        paid += _payReferral(playerAddress, secondLine, 2, amount, SECOND_LINE_BONUS_BPS);

        address thirdLine = secondLine == address(0) ? address(0) : players[secondLine].inviter;
        paid += _payReferral(playerAddress, thirdLine, 3, amount, THIRD_LINE_BONUS_BPS);

        return paid;
    }

    function _payReferral(
        address playerAddress,
        address receiver,
        uint8 line,
        uint256 amount,
        uint16 bonusBps
    ) private returns (uint256) {
        uint256 bonus = (amount * bonusBps) / BPS_DENOMINATOR;
        address payable target = receiver == address(0) ? treasury : payable(receiver);

        _safeTransfer(target, bonus);
        emit ReferralPaid(playerAddress, target, line, bonus);
        return bonus;
    }

    function _unfreezePreviousLevel(address playerAddress, uint8 level) private {
        if (level <= 1) {
            return;
        }

        PlayerLevel storage previous = playerLevels[playerAddress][level - 1];
        if (previous.frozen) {
            previous.frozen = false;
            emit LevelUnfrozen(playerAddress, level - 1);
        }
    }

    function _validateLevel(uint8 level) private pure {
        require(level >= 1 && level <= LEVEL_COUNT, "Invalid level");
    }

    function _safeTransfer(address payable receiver, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }
}
