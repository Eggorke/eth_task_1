const { ethers } = require('hardhat');

require('dotenv').config();
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const Token = await ethers.getContractFactory("Token");
  const token = await Token.deploy(process.env.WITHDRAW_PASSWORD);

  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(token.address);

  console.log("Token address:", token.address);
  console.log("Vault address:", vault.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
