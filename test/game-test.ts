import { ethers } from 'hardhat';
import crypto from 'crypto';
import { step } from 'mocha-steps';
import chai from 'chai';
import { expect } from 'chai';
import chaiEthersBN from 'chai-ethers-bn';
chai.use(chaiEthersBN());

import {
  BigNumber,
  EventFilter,
  Contract,
  ContractTransaction,
  Signer,
  utils,
} from 'ethers';
import { setPriority } from 'os';
enum Move {
  Rock = 1,
  Paper,
  Scissors,
}

const getSecret = (move: Move) => {
  const nonce = utils.randomBytes(32);
  //const move = (crypto.randomBytes(1).readUInt8() % 3) + 1;
  const secret = ethers.utils.solidityKeccak256(
    ['uint8', 'uint256'],
    [move, nonce]
  );
  return { nonce, secret };
};

const getGameAddress = async (contract: Contract) => {
  const eventFilter = contract.filters.GameJoined();
  const events = await contract.queryFilter(eventFilter, 'latest');
  return events[0].args?.gameAddress;
};

describe('Game', function () {
  let alice: Signer;
  let bob: Signer;
  let gameFactory: Contract;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();

    alice = accounts[0];
    bob = accounts[1];

    const GameFactory = await ethers.getContractFactory('GameFactory');
    gameFactory = await GameFactory.deploy();
  });

  it('should create one game for two players', async function () {
    const factoryAccountAlice = gameFactory.connect(alice);
    const factoryAccountBob = gameFactory.connect(bob);

    const { nonce: nonceAlice, secret: secretAlice } = getSecret(Move.Rock);
    const { nonce: nonceBob, secret: secretBob } = getSecret(Move.Scissors);

    await factoryAccountAlice.joinGame(secretAlice, {
      value: ethers.utils.parseEther('1.0'),
    });
    await factoryAccountBob.joinGame(secretBob, {
      value: ethers.utils.parseEther('1.0'),
    });

    const eventFilterAlice = factoryAccountAlice.filters.GameJoined();
    const eventsAlice = await factoryAccountAlice.queryFilter(
      eventFilterAlice,
      'latest'
    );
    const eventFilterBob = factoryAccountAlice.filters.GameJoined();
    const eventsBob = await factoryAccountAlice.queryFilter(
      eventFilterBob,
      'latest'
    );

    const gameAddressAlice = eventsAlice[0].args?.gameAddress;
    const gameAddressBob = eventsBob[0].args?.gameAddress;

    chai.expect(gameAddressAlice).to.equal(gameAddressBob);

    const Game = await ethers.getContractFactory('Game');
    const game = Game.attach(gameAddressAlice);

    const gameAccountAlice = game.connect(alice);
    const gameAccountBob = game.connect(bob);

    const aliceBalanceBefore = await alice.getBalance();
    const bobBalanceBefore = await bob.getBalance();

    await gameAccountAlice.revealMove(Move.Rock, nonceAlice);
    await gameAccountBob.revealMove(Move.Scissors, nonceBob);

    const aliceBalanceAfter = await alice.getBalance();
    const bobBalanceAfter = await bob.getBalance();

    expect(aliceBalanceAfter).to.be.a.bignumber.greaterThan(aliceBalanceBefore);
    expect(bobBalanceAfter).to.be.a.bignumber.lessThan(bobBalanceBefore);
  });

  it('should join an existing game', async function () {});
});
