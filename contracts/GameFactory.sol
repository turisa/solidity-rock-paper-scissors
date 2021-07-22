//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Game.sol";

contract GameFactory {

    event GameJoined(address gameAddress);

    mapping(address => Game[]) playerGames;
    Game currentGame;

    constructor() {
        currentGame = new Game(address(this));
    }

    function joinGame(uint256 secret) external payable {
        if (currentGame.isFull()) {
            currentGame = new Game(address(this));
        }
        currentGame.commitMove(secret, msg.value, msg.sender);
        payable(address(currentGame)).transfer(msg.value);
        emit GameJoined(address(currentGame));
    }


}