//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Game is ReentrancyGuard {

    event Received(address, uint);

    // Defines different moves. 
    enum Move {Default, Rock, Paper, Scissors}

    // Factory address.
    address factory;

    // Player addresses.
    address player1;
    address player2;

    address lastPlayerRevealed;

    // Stores the timestamp of when the move was last revealed.
    uint256 lastTimeRevealed;
    
    // True when both players reveal their move.
    bool finished;

    // Mappings that store user info
    mapping (address=>Move) move;
    mapping (address=>uint256) secret;
    mapping (address=>uint256) stake;
    mapping (address=>uint256) reward;

    constructor (address factory_) {
        factory = factory_;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Not a factory");
        _;
    }

    modifier onlyPlayer() {
        require(secret[msg.sender]!=uint256(0), "Not a player");
        _;
    }

    modifier onlyWinner() {
        require(reward[msg.sender] > 0, "Not a winner");
        _;
    }

    modifier onlyRevealOnce() {
        require(move[msg.sender]==Move.Default, "Move already revealed");
        _;
    }

    // Commit the secret. Can only be called by the factory.
    // The secret should be calculated as follows:
    //      secret = uint256(keccak256(abi.encodePacked(move, nonce)));
    // See `revealMove` for details.
    function commitMove(uint256 secret_, uint256 stake_, address player) external onlyFactory {
        _setPlayer(player);
        stake[player] = stake_;
        secret[player] = secret_;
    }

    // Reveal the secret by submitting the move and the nonce. Can only be called by one of the players.
    function revealMove(uint8 move_, uint256 nonce) external onlyPlayer onlyRevealOnce {
        uint256 secret_ = uint256(keccak256(abi.encodePacked(move_, nonce)));
        require(secret_ == secret[msg.sender], "Move must not change");
        
        lastTimeRevealed = block.timestamp;
        lastPlayerRevealed = msg.sender;

        _setMove(msg.sender, move_);
        if (move[player1] != Move.Default && move[player2] != Move.Default) {
            _evaluate();

        }
    }    
    
    // Claim the reward.
    function claimReward() external nonReentrant {
        if (block.timestamp - lastTimeRevealed >= 24 hours && !finished) {      
            reward[lastPlayerRevealed] = stake[player1] + stake[player2];
            finished = true;
        }
        payable(msg.sender).transfer(reward[msg.sender]);
    }

    // View function to see if the game is full.
    function isFull() public view returns(bool) {
        return player1 != address(0) && player2 != address(0);
    }

    // View function to see if the game is finished.
    function isFinished() public view returns(bool) {
        return finished;
    }

    // Update the move of the player.
    function _setMove(address player, uint8 move_) private {
        if (move_ <= 2) {
            move[player] = Move(move_);
        } else {
            move[player] = Move.Rock;
        }
    }

    // Update the player address.
    function _setPlayer(address player) private {
        if (player1 == address(0)) {
            player1 = player;
        } else {
            player2 = player;
        }
    }

    // Update the rewards.
    function _evaluate() private {
        if (move[player1] == move[player2]) {
            reward[player1] = stake[player1];
            reward[player2] = stake[player2];
        } else if (move[player1] == Move.Rock && move[player2] == Move.Scissors || 
            move[player1] == Move.Paper && move[player2] == Move.Rock || 
            move[player1] == Move.Scissors && move[player2] == Move.Paper) {
            reward[player1] = stake[player1] + stake[player2];
        } else if (move[player1] != move[player2]) {
            reward[player2] = stake[player1] + stake[player2];
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}