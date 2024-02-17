const { ethers, upgrades } = require('hardhat');

exports.deploy = async () => {
  const provider = ethers.provider;
  console.info('------------------------------------');
  console.info('Deploying Life2App Smart Contracts...');
  const [deployer] = await ethers.getSigners();
  const deployerAddress = await deployer.getAddress();
  console.info('------------------------------------');
  console.info('Deployer Address:', deployerAddress);
  console.info('Deployer Balance:', (await provider.getBalance(deployerAddress)).toString());
  console.info('------------------------------------');
  console.info('Deploying Contracts...');
  // TODO: Implement deployment script here
  console.info('------------------------------------');
  console.info('Deployment Completed!');
  console.info('------------------------------------');

  return {};
};
