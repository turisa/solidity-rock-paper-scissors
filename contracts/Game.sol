//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Game is ReentrancyGuard {

    event Received(address, uint);

    enum Move {Default, Rock, Paper, Scissors}

    address factory;
    address player1;
    address player2;

    address lastPlayerRevealed;
    uint256 lastTimeRevealed;
    
    bool finished;
    
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

    function commitMove(uint256 secret_, uint256 stake_, address player) external onlyFactory {
        _setPlayer(player);
        stake[player] = stake_;
        secret[player] = secret_;
    }

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
    
    function claimReward() external nonReentrant {
        if (block.timestamp - lastTimeRevealed >= 24 hours && !finished) {      
            reward[lastPlayerRevealed] = stake[player1] + stake[player2];
            finished = true;
        }
        payable(msg.sender).transfer(reward[msg.sender]);
    }

    function isFull() public view returns(bool) {
        return player1 != address(0) && player2 != address(0);
    }

    function isFinished() public view returns(bool) {
        return finished;
    }

    function _setMove(address player, uint8 move_) private {
        if (move_ <= 2) {
            move[player] = Move(move_);
        } else {
            move[player] = Move.Rock;
        }
    }

    function _setPlayer(address player) private {
        if (player1 == address(0)) {
            player1 = player;
        } else {
            player2 = player;
        }
    }

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