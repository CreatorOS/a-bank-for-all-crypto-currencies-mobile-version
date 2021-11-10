dir_path=$(dirname $(realpath $0))
npx hardhat test $dir_path/../test/01_deployment.js