import { ethers } from 'hardhat';
import chai from 'chai';
import { expect } from 'chai';
import chaiEthersBN from 'chai-ethers-bn';
chai.use(chaiEthersBN());

import { Contract, Signer, utils } from 'ethers';
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

describe('Game', function () {
  let alice: Signer;
  let bob: Signer;
  let factory: Contract;
  let factoryAlice: Contract;
  let factoryBob: Contract;

  beforeEach(async () => {
    const accounts = await ethers.getSigners();

    alice = accounts[0];
    bob = accounts[1];

    const GameFactory = await ethers.getContractFactory('GameFactory');
    factory = await GameFactory.deploy();

    factoryAlice = factory.connect(alice);
    factoryBob = factory.connect(bob);
  });

  it('Starts a new game', async () => {
    const { secret } = getSecret(Move.Rock);
    await expect(
      factory.joinGame(secret, { value: ethers.utils.parseEther('1.0') })
    ).to.emit(factory, 'GameJoined');
  });

  it('Rewards the winner', async () => {
    const { nonce: nonceAlice, secret: secretAlice } = getSecret(1);
    const { nonce: nonceBob, secret: secretBob } = getSecret(2);

    await factoryAlice.joinGame(secretAlice, {
      value: ethers.utils.parseEther('1.0'),
    });
    await factoryBob.joinGame(secretBob, {
      value: ethers.utils.parseEther('1.0'),
    });

    const eventFilterAlice = factoryAlice.filters.GameJoined();
    const eventsAlice = await factoryAlice.queryFilter(
      eventFilterAlice,
      'latest'
    );
    const eventFilterBob = factoryBob.filters.GameJoined();
    const eventsBob = await factoryBob.queryFilter(eventFilterBob, 'latest');

    const gameAddressAlice = eventsAlice[0].args?.gameAddress;
    const gameAddressBob = eventsBob[0].args?.gameAddress;

    expect(gameAddressAlice).to.equal(gameAddressBob);

    const Game = await ethers.getContractFactory('Game');
    const game = Game.attach(gameAddressAlice);

    const gameAccountAlice = game.connect(alice);
    const gameAccountBob = game.connect(bob);

    const aliceBalanceBefore = await alice.getBalance();
    const bobBalanceBefore = await bob.getBalance();

    await gameAccountAlice.revealMove(1, nonceAlice);
    await gameAccountBob.revealMove(2, nonceBob);

    const aliceBalanceAfter = await alice.getBalance();
    const bobBalanceAfter = await bob.getBalance();

    expect(bobBalanceAfter).to.be.a.bignumber.greaterThan(bobBalanceBefore);
    expect(aliceBalanceAfter).to.be.a.bignumber.lessThan(aliceBalanceBefore);
  });

  it('Rewards both players if result is draw', async () => {
    const { nonce: nonceAlice, secret: secretAlice } = getSecret(1);
    const { nonce: nonceBob, secret: secretBob } = getSecret(1);

    await factoryAlice.joinGame(secretAlice, {
      value: ethers.utils.parseEther('1.0'),
    });
    await factoryBob.joinGame(secretBob, {
      value: ethers.utils.parseEther('1.0'),
    });

    const eventFilterAlice = factoryAlice.filters.GameJoined();
    const eventsAlice = await factoryAlice.queryFilter(
      eventFilterAlice,
      'latest'
    );
    const eventFilterBob = factoryBob.filters.GameJoined();
    const eventsBob = await factoryBob.queryFilter(eventFilterBob, 'latest');

    const gameAddressAlice = eventsAlice[0].args?.gameAddress;
    const gameAddressBob = eventsBob[0].args?.gameAddress;

    expect(gameAddressAlice).to.equal(gameAddressBob);

    const Game = await ethers.getContractFactory('Game');
    const game = Game.attach(gameAddressAlice);

    const gameAccountAlice = game.connect(alice);
    const gameAccountBob = game.connect(bob);

    const aliceBalanceBefore = await alice.getBalance();
    const bobBalanceBefore = await bob.getBalance();

    await gameAccountAlice.revealMove(1, nonceAlice);
    await gameAccountBob.revealMove(1, nonceBob);

    const aliceBalanceAfter = await alice.getBalance();
    const bobBalanceAfter = await bob.getBalance();

    expect(bobBalanceAfter).to.be.a.bignumber.greaterThan(bobBalanceBefore);
    expect(aliceBalanceAfter).to.be.a.bignumber.greaterThan(aliceBalanceBefore);
  });
});
