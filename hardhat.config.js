require('@nomicfoundation/hardhat-toolbox');
require('@nomicfoundation/hardhat-chai-matchers');
require('@nomiclabs/hardhat-solhint');
require('@openzeppelin/hardhat-upgrades');
require('hardhat-deploy');
require('hardhat-contract-sizer');
require('hardhat-tracer');
require('hardhat-docgen');
require('hardhat-output-validator');
require('dotenv').config();

const config = {
  defaultNetwork: 'hardhat',
  networks: {
    'binance-mainnet': {
      url: `${process.env.BNB_MAINNET_URL ? process.env.BNB_MAINNET_URL : 'https://bsc-dataseed1.bnbchain.org'}`,
      chainId: 56,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    'binance-testnet': {
      url: `${process.env.BNB_TESTNET_URL ? process.env.BNB_MAINNET_URL : 'https://data-seed-prebsc-1-s1.bnbchain.org:8545'}`,
      chainId: 97,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 10000000000,
    },
    'opbnb-mainnet': {
      url: `${process.env.OPBNB_MAINNET_URL ? process.env.OPBNB_MAINNET_URL : 'https://opbnb-mainnet-rpc.bnbchain.org'}`,
      chainId: 204,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    'opbnb-testnet': {
      url: `${process.env.OPBNB_TESTNET_URL ? process.env.OPBNB_TESTNET_URL : 'https://opbnb-testnet-rpc.bnbchain.org'}`,
      chainId: 5611,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    local: {
      url: 'http://127.0.0.1:8545/',
      chainId: 31337,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
    hardhat: {
      allowUnlimitedContractSize: true,
      forking: {
        enabled: true,
        url: 'https://bsc-dataseed1.bnbchain.org', // mainnet
      },
      accounts: process.env.PRIVATE_KEY
        ? {
            privateKey: `0x${process.env.PRIVATE_KEY}`,
            balance: '10000000000000000000000',
          }
        : {},
    },
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY ? process.env.BSCSCAN_API_KEY : '',
  },
  solidity: {
    version: '0.8.23',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './tests',
    cache: './cache',
    artifacts: './artifacts',
  },
  contractSizer: {
    alphaSort: false,
    runOnCompile: true,
    disambiguatePaths: false,
  },
  mocha: {
    timeout: 12000000,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    admin: {
      default: 1,
    },
    user: {
      default: 2,
    },
    user2: {
      default: 3,
    },
    user3: {
      default: 4,
    },
  },
  docgen: {
    path: './docs',
    clear: true,
    runOnCompile: true,
  },
  outputValidator: {
    runOnCompile: true,
    enabled: true,
    checks: {
      title: 'error',
      details: 'warning',
      params: 'error',
      returns: 'error',
      compilationWarnings: 'warning',
      variables: false,
      events: true,
    },
  },
  gasReporter: {
    enabled: true,
    currency: 'BNB',
    gasPrice: 5,
  },
};

module.exports = config;
