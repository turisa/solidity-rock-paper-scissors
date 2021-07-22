//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Game {

    event Received(address, uint);
    event GameFinished(address player1, Result result1, address player2, Result result2);

    enum Result {
        Default,
        Win,
        Loss,
        Draw
    }

    enum Move {
        Default,
        Rock, 
        Paper, 
        Scissors
    }

    address player1;
    address player2;
    address factory;

    mapping (address=>Move) playerMove;
    mapping (address=>Result) playerResult;

    mapping (address=>uint256) playerStake;
    mapping (address=>uint256) playerSecret;

    constructor (address factory_) {
        factory = factory_;
    }

    modifier onlyPlayer(address playerAddress) {
        require(playerSecret[playerAddress]!=uint256(0), "Not a player");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Not a factory");
        _;
    }

    modifier onlyRevealOnce(address playerAddress) {
        require(playerMove[playerAddress]==Move.Default, "Secret already revealed");
        _;
    }

    function commitMove(uint256 secret, uint256 stake, address player) external onlyFactory {
        _setPlayer(player);
        playerStake[player] = stake;
        playerSecret[player] = secret;
    }

    function revealMove(uint8 move, uint256 nonce) external onlyPlayer(msg.sender) onlyRevealOnce(msg.sender) {
        uint256 secret = uint256(keccak256(abi.encodePacked(move, nonce)));
        require(secret == playerSecret[msg.sender], "Move must not change");

        _setMove(msg.sender, move);
        if (playerMove[player1] != Move.Default && playerMove[player2] != Move.Default) {
            _rewardPlayers();
            emit GameFinished(player1, playerResult[player1], player2, playerResult[player2]);
        }
    }

    function isFull() public view returns (bool) {
        return player1 != address(0) && player2 != address(0);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function _setMove(address player, uint8 move) private {
        if (move <= 2) {
            playerMove[player] = Move(move);
        } else {
            playerMove[player] = Move.Rock;
        }
    }

    function _setPlayer(address player) private {
        if (player1 == address(0)) {
            player1 = player;
        } else {
            player2 = player;
        }
    }

    function _rewardPlayers() private {
        if (playerMove[player1] == playerMove[player2]) {
            playerResult[player1] = Result.Draw;
            playerResult[player2] = Result.Draw;
            payable(player1).transfer(playerStake[player1]);
            payable(player2).transfer(playerStake[player2]);
        } else if (playerMove[player1] == Move.Rock && playerMove[player2] == Move.Scissors || 
                playerMove[player1] == Move.Paper && playerMove[player2] == Move.Rock || 
                playerMove[player1] == Move.Scissors && playerMove[player2] == Move.Paper) {
            playerResult[player1] = Result.Win;
            playerResult[player2] = Result.Loss;
            payable(player1).transfer(address(this).balance);
        } else {
            playerResult[player1] = Result.Loss;
            playerResult[player2] = Result.Draw;
            payable(player2).transfer(address(this).balance);
            
        }
    }
    //function lateReward() external {
     //   if (secretsRevealed == 1 && lastRevealed - 24 hours > 0) {
      //      payable(currentWinner).transfer(address(this).balance);
       // }
    //}
}