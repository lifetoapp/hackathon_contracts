require('@nomicfoundation/hardhat-toolbox');
require('@nomiclabs/hardhat-solhint');
require('@openzeppelin/hardhat-upgrades');
require('hardhat-deploy');
require('hardhat-contract-sizer');
require('hardhat-tracer');
require('hardhat-docgen');
require('hardhat-output-validator');
require("hardhat-abi-exporter");
require("dotenv").config();

const MNEMONIC = process.env.MNEMONIC;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ACCOUNTS = MNEMONIC ? { "mnemonic": MNEMONIC } : [PRIVATE_KEY];

task("test-deploy", "Test deployment")
  .setAction(async (taskArgs) => {
    await hre.run("compile");

    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const paymentToken = await TestERC20.deploy();
    const paymentTokenAddress = await paymentToken.getAddress();

    console.log("TestERC20 deployed to ", paymentTokenAddress);

    const price = ethers.parseUnits("11", 18);
    const accounts = await hre.ethers.getSigners();

    const LifeHackatonItems = await ethers.getContractFactory("LifeHackatonItems");
    const lifeHackatonItems = await upgrades.deployProxy(
      LifeHackatonItems,
      ["https://test.uri", paymentTokenAddress, paymentTokenAddress, price, price, accounts[0].address]
    );
    await lifeHackatonItems.waitForDeployment();
    const lifeHackatonItemsAddress = await lifeHackatonItems.getAddress()

    console.log("LifeHackatonItems deployed to ", lifeHackatonItemsAddress);

    const LifeHackatonPlayers = await ethers.getContractFactory("LifeHackatonPlayers");
    const lifeHackatonPlayers = await upgrades.deployProxy(
      LifeHackatonPlayers,
      [lifeHackatonItemsAddress]
    );
    await lifeHackatonPlayers.waitForDeployment();
    const lifeHackatonPlayersAddress = await lifeHackatonPlayers.getAddress()

    console.log("LifeHackatonPlayers deployed to ", lifeHackatonPlayersAddress);

    const rewardAmount = ethers.parseUnits("20", 18);
    const smallRatingChange = 10;
    const normalRatingChange = 20;
    const bigRatingChange = 30;

    const LifeHackatonBattles = await ethers.getContractFactory("LifeHackatonBattles");
    const lifeHackatonBattles = await upgrades.deployProxy(
      LifeHackatonBattles,
      [
        lifeHackatonPlayersAddress,
        paymentTokenAddress,
        rewardAmount,
        smallRatingChange,
        normalRatingChange,
        bigRatingChange
      ]
    );
    await lifeHackatonBattles.waitForDeployment();
    const lifeHackatonBattlesAddress = await lifeHackatonBattles.getAddress();

    await lifeHackatonPlayers.setAuthorizedOperator(lifeHackatonBattlesAddress, true);

    console.log("LifeHackatonBattles deployed to ", lifeHackatonBattlesAddress);
  });

task("upgrade", "Upgrades given contract")
  .addParam("name", "The name of the contract to upgrade")
  .addParam("address", "The address of the contract you want to upgrade")
  .setAction(async (taskArgs) => {
    await hre.run('compile');

    const Contract = await ethers.getContractFactory(taskArgs.name);
    await upgrades.upgradeProxy(taskArgs.address, Contract, {kind: 'uups'});

    console.log(taskArgs.name, " has been upgraded!");
  });

module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    'binance-mainnet': {
      url: `${process.env.BNB_MAINNET_URL ? process.env.BNB_MAINNET_URL : 'https://bsc-dataseed1.bnbchain.org'}`,
      chainId: 56,
      accounts: ACCOUNTS,
    },
    'binance-testnet': {
      url: `${process.env.BNB_TESTNET_URL ? process.env.BNB_MAINNET_URL : 'https://data-seed-prebsc-1-s1.bnbchain.org:8545'}`,
      chainId: 97,
      accounts: ACCOUNTS,
    },
    'opbnb-mainnet': {
      url: `${process.env.OPBNB_MAINNET_URL ? process.env.OPBNB_MAINNET_URL : 'https://opbnb-mainnet-rpc.bnbchain.org'}`,
      chainId: 204,
      accounts: ACCOUNTS,
    },
    'opbnb-testnet': {
      url: `${process.env.OPBNB_TESTNET_URL ? process.env.OPBNB_TESTNET_URL : 'https://opbnb-testnet-rpc.bnbchain.org'}`,
      chainId: 5611,
      accounts: ACCOUNTS,
    },
    hardhat: {
      forking: {
        enabled: false,
        url: 'https://bsc-dataseed1.bnbchain.org', // mainnet
      },
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
    runOnCompile: false,
  },
  outputValidator: {
    runOnCompile: false,
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
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    clear: true
  },
};
