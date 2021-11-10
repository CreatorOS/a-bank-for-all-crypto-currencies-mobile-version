# A bank for all crypto currencies

In the previous Quest () we looked at how to create a bank account that actually allows you to earn an interest. You could deposit Ethers into the smart bank account and after some time withdraw it along with an additional interest rate.

This smart bank account, though completely functional, allows us to deposit only Ethers. In this quest we’ll explore how you can deposit one currency and withdraw another. We will also understand how the crypto currencies actually work and why they are a big deal.

## Getting some crypto currency other than ETH

You might have heard of many crypto currencies like Ethers, Bitcoin, Litecoin and many more. There are a lot of crypto currencies out there. However, there is a class of crypto currencies that are built on the ethereum network. These are called ERC20 tokens. Bitcoin is not an ERC20 token. Some examples of ERC20 tokens are DAI, MATIC.

An ERC20 Token is nothing but an implementation of a standard crypto currency smart contract. In this quest we will be looking at a crypto token called DAI, one of the most popular ERC20 tokens.

First, let’s look at what a smart contract for a crypto currency (ERC20) looks like.

[https://ropsten.etherscan.io/address/0xad6d458402f60fd3bd25163575031acdce07538d\#code](https://ropsten.etherscan.io/address/0xad6d458402f60fd3bd25163575031acdce07538d#code)

This is the link to the contract of the DAI token’s code.

I want you to look at the lines 137 - 167. That’s about 30 lines of code. Just a few lines of code that powers an entire crypto currency. DAI, a crypto currency handled by a ERC20 token contract, with a few lines of code has a market cap of more than $5B at the time of this writing!

![](https://qb-content-staging.s3.ap-south-1.amazonaws.com/public/fb231f7d-06af-4aff-bca3-fd51cb633f77/0ba8ac4e-b096-4246-8a22-6659549b7110.jpg)

I recommend you to read the lines 120-167, which is the meat of the contract. You should be able to follow what is happening there. We’ve written similar code already in our smart contract, if not more complex!

You’ll see a contract called StandardToken that extends/implements other contracts or interfaces like BasicToken and ERC20 interface that have been declared in the same file.

## Accepting ERC20 tokens (DAI etc) into our bank

How do we accept DAI?

We know the DAI Erc20 token is just a smart contract. We have already seen how to add balance by sending ETH to our smart account. We use the payable key word.

However, payable allows only ETH to be sent to the function. We cannot send an ERC20 token like DAI to a payable function. We’ll have to do something else.

The reason we can’t send an ERC20 token to a function just like ETH is because ETH is the native currency of Ethereum. So Solidity natively supports ETH. However, DAI and other ERC20 tokens are mere smart contracts. We can only interact with the smart contract just like how we interacted with the compound smart contract in the previous quest.

So, let’s do just that. Like what we had done in Compound example, we’ll have to define the interface and initialize an object with the appropriate smart contract address.

```
interface ERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}
```

Code this `addBalanceERC20` function to accept an ERC20 token for depositing into our bank:

```
function addBalanceERC20(address erc20TokenSmartContractAddress) public {
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
}
```

Explore the code of the DAI ERC20 token on Etherscan. Copy paste the signatures of the functions we’d want to use into the IERC20 interface. Then we will initialize the IERC20 object. But we want to accept ANY ERC20 token, not just DAI. We’ll use a variable address when we initialize the ERC20 token object. So when we need to do a transaction with DAI, we’ll use DAI’s erc20 compliant smart contract address; when we want to use MATIC we’ll use MATIC’s erc20 compliant smart contract address.

Here are the steps we need to do, intuitively

1. We need to transfer ERC20 tokens to the Smart contract
2. The smart contract will convert the ERC20 tokens into ETH using Uniswap
3. We’ll deposit the ETH to Compound to receive interest

## A new way to transfer Tokens

The first step is to send tokens along with a function call.

There are two ways to transfer an erc20 token.

The first is to use the transfer() function.Let us check the parameters of this function call. It is “To” and “amount”. So we’ll have to set the address of this smart bank account contract, and amount as the number of erc20 tokens we want to send.

That will work perfectly fine, but where’s the function call? What code should get executed immediately after this transfer? Immediately after the transfer we want to run some code. I.e. to convert it into ETH using Uniswap and then deposit to Compound.

There is another way to transfer money. But this is a two step process. The first step is to call the approve() function. The owner of the ERC20 tokens tells Ethereum that they are approving a certain user/smart contract to use a portion of tokens they hold.

So a user who wants to send money to a function call they will say, “Hey function, I’ve already approved you to spend 10 DAI from my account - go ahead and use it and execute whatever logic you want to execute there after”.

The second step after the function has been called is to use the transferFrom() function. The transferFrom function transfers the funds from the user to the smart bank account contract. Security is taken care of by the ERC20 token smart contract. Approve can be executed only by the owner of the tokens. The transferFrom can be executed only by the user/contract that has been given the approval (aka allowance).

The “approval” will have to happen outside the smart contract. Until the approval is granted, the smart contract cannot do anything with the users tokens. We cannot convert them to ETH using uniswap in our contract, we can’t deposit them to Compound etc.

We will transfer all the money the user has approved into the account of our smart contract. We will then send to the uniswap smart contract for converting to ETH.

```
    // how many erc20tokens has the user (msg.sender) approved this contract to use?
    uint approvedAmountOfERC20Tokens = erc20.allowance(msg.sender, address(this));

    // transfer all those tokens that had been approved by user (msg.sender) to the smart contract (address(this))
    erc20.transferFrom(msg.sender, address(this), approvedAmountOfERC20Tokens);
```

Also add a function to get the erc20 token balance of our smart contract, so that we can do a sanity check that everything is working.

```
function getAllowanceERC20(address erc20TokenSmartContractAddress) public view returns(uint){
        IERC20 erc20 = IERC20(erc20TokenSmartContractAddress);
        return erc20.allowance(msg.sender, address(this));
}
```

Usually the user has to fire the `approve()` function from outside the smart contract to allocate the allowance after that only smart contract can use the tokens.
But in our case, the test scripts running in the backend will take care of this step so that you don't have to manually do it.

Hit `Run` to test the code we just wrote.

- In 2nd test output you will see the test script approved some DAI token to our smart contract from one of the test accounts.
- After that it calls `approve()` function to approve the smart contract to spend the DAI tokens worth `1 ether` which is approximately 4304 DAI tokens at the time of writing.
- In 3rd test output you will see the test script transfers the approved DAI tokens to our smart contract from one of the test accounts using the code we wrote earlier in the `addBalanceERC20()` function.

## sending DAI to Uniswap

Now that we have transferred the DAIs from the user (msg.sender)’s account to the smart contract’s account using transferFrom(), we can now start looking at exchanging it for ETH before we can send it to compound.

For this we’ll integrate Uniswap, which is also a smart contract.

Search for “Uniswap Router v2 Mainnet Etherscan”

[https://etherscan.io/address/0xf164fc0ec4e93095b804a4795bbe1e041497b92a\#code](https://etherscan.io/address/0xf164fc0ec4e93095b804a4795bbe1e041497b92a#code)

Direct link ^

If we want to use a smart contract’s functions, we need their address and an interface in which we define what functions we want to call.

We’ll use only two functions here to convert erc20 tokens to eth and eth to erc20 tokens.

They are called:

swapExactETHForTokens (to convert eth to erc20 tokens)

swapExactTokensForETH (to convert erc20 tokens to eth)

Let’s as always, define the interface with the two functions above and initialize an object with the Uniswap Router contract address. You can look for the signatures of these two functions in the Contract tab on the above etherscan link.

```
interface UniswapRouter {
    function WETH() external pure returns (address);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )  external  payable  returns (uint[] memory amounts);
}
```

Also, we need to initialize the UniswapRouter object with the UniswapRouter contract address:

```
address UNISWAP_ROUTER_ADDRESS = 0xf164fC0Ec4E93095b804a4795bBe1e041497b92a;
UniswapRouter uniswap = UniswapRouter(UNISWAP_ROUTER_ADDRESS);
```

Let’s now go to addBalance function and add the code for converting erc20 tokens into eth. I.e. invoke swapExactTokensForETH with the right set of parameters..

It has a few parameters

- AmountIn : how many erc20 tokens we want to convert to eth
- AmountOutMin : How many eth do you expect at the end of this transaction? We can set this to be 0 for now.
- Path : array of addresses of tokens involved in transaction, one thing to keep in mind here is that pools for each consecutive pair of addresses must exist in uniswap ropsten network and have liquidity.  
  To verify this you can go to uniswap.exchange and try swapping the tokens you are trying to swap from the contract.
- To : whom should the eth be transferred to? This will be the address of our smart contract
- Deadline: Uniswap will try to make this swap asap, but might get delayed, till when are you willing to wait for this swap to happen?

But before we ask Uniswap to convert DAI to ETH, we need to give approval to Uniswap so that it can do it’s thing with the DAI that is currently held by our contract.

The user gave us permission to use the DAI from their metamask account. We used that approval to transfer the money into our smart contract’s account. Now we need to give approval from the smart contract who is now the owner of those DAI, to Uniswap so that it can do the appropriate computation - take DAI from us and transfer ETH to the account of our smart contract.

```
erc20.transferFrom(msg.sender, address(this), approvedAmountOfERC20Tokens);

erc20.approve(UNISWAP_ROUTER_ADDRESS, approvedAmountOfERC20Tokens);

address[] memory path = new address[](2);
path[0] = token;
path[1] = uniswap.WETH();

uniswap.swapExactTokensForETH(approvedAmountOfERC20Tokens, amountETHMin, path, to, deadline);
```

Hit `Run` to test the code we wrote for swapping ERC20 tokens to ETH.
In 4th test output you will see the DAI that gets sent to the function gets converted to ETH after calling `addBalance` function.

## Try it on your own

Now that we’ve included Uniswap and converted DAI to eth can you :

1. Fill in the rest of the logic to send the eth to Compound in addBalance and store the number of cETH tokens
2. We’ve not touched the withdraw function. Can you allow users to choose the currency in which they want to withdraw money too?

Once you've written code for sending ETH to compound in addBalance and stored the number of cETH tokens, you can test the code by clicking on `Run`.
5th test should pass and you should see the cETH tokens that you stored in addBalance.
