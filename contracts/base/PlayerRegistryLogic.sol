// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Storage.sol";

abstract contract PlayerRegistryLogic is EasyGameAdvanceStorage {
    function _registerPlayer(
        Player storage player,
        address playerAddress,
        address inviter
    ) internal {
        if (player.exists) return;

        player.exists = true;
        player.wallet = playerAddress;
        player.joinedAt = block.timestamp;

        if (
            inviter != address(0) &&
            inviter != playerAddress &&
            players[inviter].exists
        ) {
            player.inviter = inviter;
            player.secondLine = players[inviter].inviter;
            player.thirdLine = player.secondLine == address(0)
                ? address(0)
                : players[player.secondLine].inviter;
        }
    }
}
