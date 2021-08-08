//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Game.sol";

contract GameFactory {

    event GameJoined(address gameAddress);

    // Games of each player
    mapping(address => Game[]) playerGames;
    
    // Joinable game
    Game currentGame;

    constructor() {
        currentGame = new Game(address(this));
    }

    modifier onlyPositiveStake() {
        require(msg.value > 0, "Stake must be positive");
        _;
    }

    // Join a game by paying and committing a secret. 
    // See `commitMove` of contract Game for details on how to create a secret.
    function joinGame(uint256 secret) external payable onlyPositiveStake {
        _createGame();
        currentGame.commitMove(secret, msg.value, msg.sender);
        payable(address(currentGame)).transfer(msg.value);
        emit GameJoined(address(currentGame));
    }

    // Create a new joinable game.
    function _createGame() private {
        if (currentGame.isFull()) {
            currentGame = new Game(address(this));
        }
    }

    // Return games of given player.
    function getGames(address player) external view returns(Game[] memory) {
        return playerGames[player];
    }

}