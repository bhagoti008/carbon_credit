import { ethers } from "hardhat";

//npx hardhat run scripts/deploy_sepolia.ts --network sepolia
async function main() {
  const users = await ethers.getSigners();
  const account = users[0];
  console.log("Deploying contracts with the account:", account.address);
  const token = await ethers.deployContract("Functionality");
  console.log("Token Deployed! Token address:", await token.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
