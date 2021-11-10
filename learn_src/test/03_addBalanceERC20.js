const { expect } = require('chai');
const { ethers } = require('hardhat');
const uniswap_v2 = require('../abis/uniswap_v2.json');
const dai = require('../abis/dai.json');

let bankContract, signer, daiContract;
describe('SmartBankAccount', () => {
  beforeEach(async () => {
    [signer] = await ethers.getSigners();
    const BankContractFactory = await ethers.getContractFactory('SmartBankAccount');
    bankContract = await BankContractFactory.deploy();
    await bankContract.deployed();

    expect((await bankContract.provider.getBalance(bankContract.address)).toString()).to.equal('0');
  });

  describe('getAllowanceERC20', () => {
    it('should transfer ERC20 token to the bank contract from sender', async () => {
      const uniswapContract = new ethers.Contract(uniswap_v2.address, uniswap_v2.abi, signer);
      daiContract = new ethers.Contract(dai.address, dai.abi, signer);
      const path = [];
      const resp = await uniswapContract.WETH();
      path.push(resp);
      path.push(dai.address);
      const deadline = Math.floor(Date.now() / 1000) + 24 * 60 * 60;

      await uniswapContract.swapExactETHForTokens(0, path, signer.address, deadline, {
        value: ethers.utils.parseEther('1'),
      });
      const bal = await daiContract.balanceOf(signer.address);
      console.log('balance dai: ', bal.toString());
      await daiContract.approve(bankContract.address, bal.toString());

      const allowance = await bankContract.getAllowanceERC20(dai.address);
      console.log('allowance: ', allowance.toString());
      await bankContract.addBalanceERC20(dai.address);
      const userBal = await daiContract.balanceOf(signer.address);
      console.log('User DAI balance: ', userBal.toString());
      const bankBal = await daiContract.balanceOf(bankContract.address);
      console.log('Bank DAI balance: ', bankBal.toString());
      expect(userBal.toString()).to.equal('0');
      expect(bankBal.toString()).to.equal(allowance.toString());
    });
  });
});
