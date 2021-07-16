//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Game {

    mapping(uint8=>bool) moveValid;
    mapping(address=>uint8) playerMove;
    mapping(address=>uint256) playerBalance;
    mapping(address=>uint256) playerSecret;
 
    address currentWinner;
    uint8 playerCount;

    constructor () {
        playerCount = 0;
        _initializeMoves();
    }

    modifier onlyTwoPlayers () {
        require(playerCount < 2, "Game is full");
        _;
    }

    modifier onlyPlayer(address playerAddress) {
        require(playerSecret[playerAddress]!=uint256(0), "Not a player");
        _;
    }

    modifier onlyNewPlayer(address playerAddress) {
        require(playerSecret[playerAddress]==uint256(0), "Player already participated");
        _;
    }

    function _initializeMoves() internal {
        moveValid[0] = true;
        moveValid[1] = true;
        moveValid[2] = true;
    }

    function submitSecret(uint256 secret) external payable onlyTwoPlayers onlyNewPlayer(msg.sender) {
        playerBalance[msg.sender] = msg.value;
        playerSecret[msg.sender] = secret;
        playerCount++;
    }

    function revealSecret(uint8 move, uint256 nonce) external onlyPlayer(msg.sender) {
        uint256 secret = uint256(keccak256(abi.encodePacked(move, nonce)));
        require(secret == playerSecret[msg.sender], "Secret must not change");
        require(moveValid[move], "Move is invalid");

        playerMove[msg.sender] = move;
        if (currentWinner == address(0)) {
            currentWinner = msg.sender;
        } else {
            _payWinner(currentWinner, msg.sender);
        }
    }

    function _payWinner(address player1, address player2) internal {
        if (playerMove[player1] == playerMove[player2]) {
            payable(player1).transfer(playerBalance[player1]);
            payable(player2).transfer(playerBalance[player2]);
        } else if (playerMove[player1] == 0 && playerMove[player2] == 2 || 
                   playerMove[player1] == 1 && playerMove[player2] == 0 || 
                   playerMove[player1] == 2 && playerMove[player2] == 1) {
            payable(player1).transfer(address(this).balance);
        } else {
            payable(player2).transfer(address(this).balance);
        }
    }
}