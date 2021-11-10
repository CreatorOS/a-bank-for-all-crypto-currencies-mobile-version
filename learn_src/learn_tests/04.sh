dir_path=$(dirname $(realpath $0))
npx hardhat test $dir_path/../test/04_addBalanceERC20_swap.js