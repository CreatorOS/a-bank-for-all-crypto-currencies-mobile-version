const { expect } = require('chai');
const { ethers } = require('hardhat');
const uniswap_v2 = require('../abis/uniswap_v2.json');
const dai = require('../abis/dai.json');

let bankContract, signer;
describe('SmartBankAccount', () => {
  beforeEach(async () => {
    signer = await ethers.getSigner();
    const BankContractFactory = await ethers.getContractFactory('SmartBankAccount');
    bankContract = await BankContractFactory.deploy();
    await bankContract.deployed();

    expect((await bankContract.provider.getBalance(bankContract.address)).toString()).to.equal('0');
  });

  describe('getAllowanceERC20', () => {
    it('should return the correct allowance', async () => {
      const uniswapContract = new ethers.Contract(uniswap_v2.address, uniswap_v2.abi, signer);
      const daiContract = new ethers.Contract(dai.address, dai.abi, signer);
      const path = [];
      const resp = await uniswapContract.WETH();
      path.push(resp);
      path.push(dai.address);
      const deadline = Math.floor(Date.now() / 1000) + 24 * 60 * 60;

      await uniswapContract.swapExactETHForTokens(0, path, signer.address, deadline, {
        value: ethers.utils.parseEther('1'),
      });
      const bal = await daiContract.balanceOf(signer.address);
      console.log('User DAI balance: ', bal.toString());
      console.log('Calling approve() on DAI contract');
      await daiContract.approve(bankContract.address, bal.toString());

      const allowance = await bankContract.getAllowanceERC20(dai.address);
      console.log('allowance: ', allowance.toString());
      expect(allowance.toString()).to.equal(bal.toString());
    });
  });
});
