import "@nomiclabs/hardhat-etherscan";
import '@nomiclabs/hardhat-waffle';
import 'hardhat-deploy';
import "./tasks"

import { HardhatUserConfig } from 'hardhat/config';

const accounts = {
  mnemonic: process.env.MNEMONIC || 'case duty embody prison empty note limit amazing opera inspire misery bag enlist gym upon',
};

const config: HardhatUserConfig = {
  namedAccounts: {
    deployer: { default: 0 },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  networks: {
    localhost: {
      accounts,
      live: false,
      saveDeployments: true,
    },
    ganache: {
      chainId: 1337,
      url: 'http://127.0.0.1:7545',
      accounts,
      live: false,
      saveDeployments: true,
    },
    polygon: {
      chainId: 137,
      url: "https://rpc-mainnet.maticvigil.com",
      accounts,
      live: true,
      saveDeployments: true,
    }
  },
  solidity: {
    compilers: [{
      version: '0.8.17',
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        metadata: {
          bytecodeHash: 'none',
        },
      },
    }],
  },
};

export default config;
