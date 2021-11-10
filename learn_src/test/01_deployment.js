const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('SmartBankAccount', function () {
  it('Should deploy SmartBankAccount', async function () {
    const ContractFactory = await ethers.getContractFactory('SmartBankAccount');
    const contract = await ContractFactory.deploy();
    await contract.deployed();

    expect((await contract.provider.getBalance(contract.address)).toString()).to.equal('0');

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
