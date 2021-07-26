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

    modifier onlyPositiveStake(uint256 stake) {
        require(stake > 0, "Stake must be positive");
        _;
    }

    function joinGame(uint256 secret) external payable onlyPositiveStake(msg.value) {
        if (currentGame.isFull()) {
            currentGame = new Game(address(this));
        }
        currentGame.commitMove(secret, msg.value, msg.sender);
        payable(address(currentGame)).transfer(msg.value);
        emit GameJoined(address(currentGame));
    }


}