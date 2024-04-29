import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";

const config: HardhatUserConfig = {
  solidity: {
    version :"0.8.19",
    settings :{
      optimizer :{
        enabled :true,
        runs : 200,
      }
    }
  },
  networks :{
    sepolia :{
      url : `https://eth-sepolia.g.alchemy.com/v2/SF8CNghml1v_umZv2SpCU8KTq0sw02FF`,
      accounts: ["6fdcaa41d9968938d84d913f01ae27a23ba946c828b1fbc1b232fd0c9b0db789"]
    }
  },
  gasReporter :{
    currency :'INR',
    enabled :   true,
    coinmarketcap : "8ef7c7fd-e58a-4fc6-859c-ccd61d591db2"
    // gasPriceApi:"https://api.etherscan.io/api?module=proxy&action=eth_gasPrice"
  }
};

export default config;
