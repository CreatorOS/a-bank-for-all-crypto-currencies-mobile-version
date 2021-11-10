// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

interface cETH {
    // define functions of COMPOUND we'll be using

    function mint() external payable; // to deposit to compound

    function redeem(uint256 redeemTokens) external returns (uint256); // to withdraw from compound

    //following 2 functions to determine how much you'll be able to withdraw
    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface UniswapRouter {
    function WETH() external pure returns (address);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract SmartBankAccount {
    uint256 totalContractBalance = 0;

    address COMPOUND_CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    cETH ceth = cETH(COMPOUND_CETH_ADDRESS);

    address UNISWAP_ROUTER_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
    UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);

    function getContractBalance() public view returns (uint256) {
        return totalContractBalance;
    }

    mapping(address => uint256) balances;
    mapping(address => uint256) depositTimestamps;

    function addBalance() public payable {
        uint256 cEthOfContractBeforeMinting = ceth.balanceOf(address(this)); //this refers to the current contract

        // send ethers to mint()
        ceth.mint{value: msg.value}();

        uint256 cEthOfContractAfterMinting = ceth.balanceOf(address(this)); // updated balance after minting
        uint256 cEthOfUser = cEthOfContractAfterMinting -
            cEthOfContractBeforeMinting; // the difference is the amount that has been created by the mint() function

        balances[msg.sender] = cEthOfUser;
    }

    function addBalanceERC20(address erc20TokenSmartContractAddress) public {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);

        // how many erc20tokens has the user (msg.sender) approved this contract to use?
        uint256 approvedAmountOfERC20Tokens = erc20.allowance(
            msg.sender,
            address(this)
        );

        address token = erc20TokenSmartContractAddress;
        uint256 amountETHMin = 0;
        address to = address(this);
        uint256 deadline = block.timestamp + (24 * 60 * 60);

        // transfer all those tokens that had been approved by user (msg.sender) to the smart contract (address(this))
        erc20.transferFrom(
            msg.sender,
            address(this),
            approvedAmountOfERC20Tokens
        );

        erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountOfERC20Tokens);

        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswap.WETH();

        uint256 contractEthBalance = address(this).balance;
        uniswap.swapExactTokensForETH(
            approvedAmountOfERC20Tokens,
            amountETHMin,
            path,
            to,
            deadline
        );
        uint256 ethAfterSwap = address(this).balance - contractEthBalance;

        uint256 cEthOfContractBeforeMinting = ceth.balanceOf(address(this)); //this refers to the current contract

        // send ethers to mint()
        ceth.mint{value: ethAfterSwap}();

        uint256 cEthOfContractAfterMinting = ceth.balanceOf(address(this)); // updated balance after minting
        uint256 cEthOfUser = cEthOfContractAfterMinting -
            cEthOfContractBeforeMinting; // the difference is the amount that has been created by the mint() function

        balances[msg.sender] = cEthOfUser;
    }

    function getAllowanceERC20(address erc20TokenSmartContractAddress)
        public
        view
        returns (uint256)
    {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
    }

    function getBalance(address userAddress) public view returns (uint256) {
        uint256 balance = (balances[userAddress] *
            (ceth.exchangeRateStored())) / 1e18;
        console.log("Balance: ", balance);
        return balance;
    }

    function getCethBalance(address userAddress) public view returns (uint256) {
        return balances[userAddress];
    }

    function withdraw() public payable {
        address payable withdrawTo = payable(msg.sender);
        uint256 amountToTransfer = getBalance(msg.sender);

        ceth.redeem(balances[msg.sender]);

        balances[msg.sender] = 0;

        withdrawTo.transfer(amountToTransfer);
    }

    function addMoneyToContract() public payable {}

    receive() external payable {}
}
