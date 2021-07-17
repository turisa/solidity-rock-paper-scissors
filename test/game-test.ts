import { ethers } from 'hardhat';
import { expect } from 'chai';
import { Contract, Signer } from 'ethers';

describe('Game', function () {
  let accounts: Signer[];
  let gameFactory: Contract;

  beforeEach(async function () {
    accounts = await ethers.getSigners();

    const GameFactory = await ethers.getContractFactory('GameFactory');

    gameFactory = await GameFactory.deploy();
    await gameFactory.deployed();
  });

  it('should create a new game with 1 player', async function () {
    const game: Contract = await gameFactory.getAvailableGame();
    console.log(game);
    expect(game.getPlayerCount()).to.equal(1);
  });
});
