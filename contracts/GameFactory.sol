//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Game.sol";

contract GameFactory {

    mapping(uint256 => Game) games;
    uint256 nextGameIndex;

    constructor() {
        nextGameIndex = 0;
    }

    function getAvailableGame() external returns(address) {
        if (nextGameIndex == 0 || games[nextGameIndex].getPlayerCount() == 2) {
            _createGame();
        }
        return address(games[nextGameIndex-1]);
    }

    function _createGame() internal {
        games[nextGameIndex] = new Game();
        nextGameIndex++;
    }
}