require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const MNEMONIC = process.env.MNEMONIC;
const ACCOUNTS = MNEMONIC ? { "mnemonic": MNEMONIC, "initialIndex": 0 } : "remote";

task("test-deploy", "Test deployment")
  .setAction(async (taskArgs) => {
    await hre.run("compile");

    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const paymentToken = await TestERC20.deploy();
    const paymentTokenAddress = await paymentToken.getAddress();

    console.log("TestERC20 deployed to ", paymentTokenAddress);

    const price = 10*18;
    const accounts = await hre.ethers.getSigners();

    const LifeHackatonItems = await ethers.getContractFactory("LifeHackatonItems");
    const lifeHackatonItems = await upgrades.deployProxy(
      LifeHackatonItems,
      ["https://test.uri", paymentTokenAddress, paymentTokenAddress, price, price, accounts[0].address]
    );
    await lifeHackatonItems.waitForDeployment();

    console.log("LifeHackatonItems deployed to ", await lifeHackatonItems.getAddress());
  });

module.exports = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    op_bnb_test: {
      url: process.env.POLYGON_ZKEVM_URL || "https://opbnb-testnet-rpc.bnbchain.org/",
      accounts: ACCOUNTS
    }
  },
};
