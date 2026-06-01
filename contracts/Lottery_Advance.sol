// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LotteryGenerator {
    address[] public lotteries;

    struct LotteryInfo {
        uint256 index;
        address manager;
        bool exists;
    }

    mapping(address => LotteryInfo) private lotteryStructs;

    function createLottery(string memory name) public {
        require(bytes(name).length > 0, "Lottery name is required");

        Lottery newLottery = new Lottery(name, msg.sender);
        address lotteryAddress = address(newLottery);

        lotteries.push(lotteryAddress);
        lotteryStructs[lotteryAddress] = LotteryInfo({
            index: lotteries.length - 1,
            manager: msg.sender,
            exists: true
        });

        emit LotteryCreated(lotteryAddress);
    }

    function getLotteries() public view returns (address[] memory) {
        return lotteries;
    }

    function deleteLottery(address lotteryAddress) public {
        require(lotteryStructs[lotteryAddress].exists, "Lottery does not exist");
        require(msg.sender == lotteryStructs[lotteryAddress].manager, "Only manager can delete the lottery");

        uint256 indexToDelete = lotteryStructs[lotteryAddress].index;
        address lastAddress = lotteries[lotteries.length - 1];

        if (lotteryAddress != lastAddress) {
            lotteries[indexToDelete] = lastAddress;
            lotteryStructs[lastAddress].index = indexToDelete;
        }

        lotteries.pop();
        delete lotteryStructs[lotteryAddress];
    }

    event LotteryCreated(address lotteryAddress);
}

contract Lottery {
    string public lotteryName;
    address public manager;

    struct Player {
        string name;
        uint256 entryCount;
        uint256 index;
        address adrs;
    }

    address[] public addressIndexes;
    mapping(address => Player) private players;
    address payable[] public lotteryBag;

    Player public winner;
    bool public isLotteryLive;
    uint256 public maxEntriesForPlayer;
    uint256 public ethToParticipate;

    constructor(string memory name, address creator) {
        require(bytes(name).length > 0, "Lottery name is required");
        require(creator != address(0), "Manager address is required");

        manager = creator;
        lotteryName = name;
    }

    receive() external payable {
        participate("Unknown");
    }

    function participate(string memory playerName) public payable {
        require(bytes(playerName).length > 0, "Player name is required");
        require(isLotteryLive, "Lottery is not active");
        require(msg.value == ethToParticipate * 1 ether, "Incorrect ETH amount");
        require(players[msg.sender].entryCount < maxEntriesForPlayer, "Entry limit reached");

        if (isNewPlayer(msg.sender)) {
            players[msg.sender].entryCount = 1;
            players[msg.sender].name = playerName;
            players[msg.sender].adrs = msg.sender;
            addressIndexes.push(msg.sender);
            players[msg.sender].index = addressIndexes.length - 1;
        } else {
            players[msg.sender].entryCount += 1;
        }

        lotteryBag.push(payable(msg.sender));

        emit PlayerParticipated(players[msg.sender].name, players[msg.sender].entryCount);
    }

    function activateLottery(uint256 maxEntries, uint256 ethRequired) public restricted {
        require(!isLotteryLive, "Lottery is already active");

        isLotteryLive = true;
        maxEntriesForPlayer = maxEntries == 0 ? 1 : maxEntries;
        ethToParticipate = ethRequired == 0 ? 1 : ethRequired;
    }

    function declareWinner() public restricted {
        require(lotteryBag.length > 0, "No players in lottery");

        uint256 index = generateRandomNumber() % lotteryBag.length;
        address payable winnerAddress = lotteryBag[index];
        uint256 prize = address(this).balance;

        winner.name = players[winnerAddress].name;
        winner.entryCount = players[winnerAddress].entryCount;
        winner.adrs = winnerAddress;

        lotteryBag = new address payable[](0);
        addressIndexes = new address[](0);
        isLotteryLive = false;

        (bool sent, ) = winnerAddress.call{value: prize}("");
        require(sent, "Prize transfer failed");

        emit WinnerDeclared(winner.name, winner.entryCount);
    }

    function getPlayers() public view returns (address[] memory) {
        return addressIndexes;
    }

    function getLotterySoldCount() public view returns (uint256) {
        return lotteryBag.length;
    }

    function getPlayer(address playerAddress) public view returns (string memory, uint256) {
        if (isNewPlayer(playerAddress)) {
            return ("", 0);
        }

        return (players[playerAddress].name, players[playerAddress].entryCount);
    }

    function getWinningPrice() public view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentWinner() public view returns (string memory, uint256, address) {
        return (winner.name, winner.entryCount, winner.adrs);
    }

    function isNewPlayer(address playerAddress) private view returns (bool) {
        if (addressIndexes.length == 0) {
            return true;
        }

        return (addressIndexes[players[playerAddress].index] != playerAddress);
    }

    // NOTE: This should not be used for generating random number in real world
    function generateRandomNumber() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, lotteryBag.length)));
    }

    modifier restricted() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    event WinnerDeclared(string name, uint256 entryCount);
    event PlayerParticipated(string name, uint256 entryCount);
}
