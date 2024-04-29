import { ethers } from "hardhat";

//npx hardhat run scripts/deploy.ts --network sepolia

async function main() {
  const users = await ethers.getSigners();
  const account = users[0];
  const listOfUsers = users.slice(1,101);
  console.log("Deploying contracts with the account:", account.address);
  const token = await ethers.deployContract("Functionality");
  console.log("Token address:", await token.getAddress());

  await token.registerUser("User_Name","User_Location","1234567890")

  const concurrentCalls =[]
  for(let i=0;i<listOfUsers.length;i++){
      concurrentCalls.push(
        token.connect(listOfUsers[i]).buycarbon_Credit(1,3)
      )
  }

  // This calls buycarbon_Credit function 100 times at once.
  await Promise.all(concurrentCalls);

  const buycarbon_CreditBySingleUser = []
  for(let i=0;i<100;i++){
    buycarbon_creditBySingleUser.push(
      token.connect(listOfUsers[0]).buycarbon_Credit(1,3)
    )
  }

  // This calls buycarbon_Credit from a single account 100 times.
  await Promise.all(buycarbon_CreditBySingleUser);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
