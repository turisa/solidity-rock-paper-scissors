//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Game {

    enum Move {
        DEFAULT,
        ROCK, 
        PAPER, 
        SCISSORS
    }

    mapping(address=>Move) playerMove;
    mapping(address=>uint256) playerBalance;
    mapping(address=>uint256) playerSecret;
 
    uint8 playerCount;
    uint8 secretsRevealed;
    
    uint256 lastRevealed;

    address currentWinner;

    constructor () {
        playerCount = 0;
        secretsRevealed = 0;
    }

    modifier onlyTwoPlayers() {
        require(playerCount < 2, "Game is full");
        _;
    }

    modifier onlyPlayer(address playerAddress) {
        require(playerSecret[playerAddress]!=uint256(0), "Not a player");
        _;
    }

    modifier onlySubmitOnce(address playerAddress) {
        require(playerSecret[playerAddress]==uint256(0), "Player already participated");
        _;
    }

    modifier onlyRevealOnce(address playerAddress) {
        require(playerMove[playerAddress]==Move.DEFAULT, "Secret already revealed");
        _;
    }

    function _isLegal(uint8 move) internal pure returns(bool) {
        return move <= 2;
    }

    function _setMove(address player, uint8 move) internal {
        if (move <= 2) {
            playerMove[player] = Move(move);
        } else {
            playerMove[player] = Move.ROCK;
        }
    }

    function _payWinner(address player1, address player2) internal {
        if (playerMove[player1] == playerMove[player2]) {
            payable(player1).transfer(playerBalance[player1]);
            payable(player2).transfer(playerBalance[player2]);
        } else if (playerMove[player1] == Move.ROCK && playerMove[player2] == Move.SCISSORS || 
                   playerMove[player1] == Move.PAPER && playerMove[player2] == Move.ROCK || 
                   playerMove[player1] == Move.SCISSORS && playerMove[player2] == Move.PAPER) {
            payable(player1).transfer(address(this).balance);
        } else {
            payable(player2).transfer(address(this).balance);
        }
    }

    function revealSecret(uint8 move, uint256 nonce) external onlyPlayer(msg.sender) onlyRevealOnce(msg.sender) {
        uint256 secret = uint256(keccak256(abi.encodePacked(move, nonce)));
        require(secret == playerSecret[msg.sender], "Secret must not change");

        _setMove(msg.sender, move);
        secretsRevealed++;

        if (secretsRevealed == 0) {
            currentWinner = msg.sender;
            lastRevealed = block.timestamp;
        } else {
            _payWinner(currentWinner, msg.sender);
        }
    }

    function submitSecret(uint256 secret) external payable onlyTwoPlayers onlySubmitOnce(msg.sender) {
        playerBalance[msg.sender] = msg.value;
        playerSecret[msg.sender] = secret;
        playerCount++;
    }

    function claimReward() external {
        if (secretsRevealed == 1 && lastRevealed - 24 hours > 0) {
            payable(currentWinner).transfer(address(this).balance);
        }
    }

    function getPlayerCount() public view returns(uint8) {
        return playerCount;
    }
}