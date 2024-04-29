import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { expect } from "chai";
  import { ethers } from "hardhat";
  import { Functionality } from "../typechain-types";
  
  // npx hardhat test
  
  
  describe("Login", function () {
    let contract: Functionality;
  const load = 18;
    async function deployContract() {
      // Contracts are deployed using the first signer/account by default
      const accounts = 
        await ethers.getSigners();
      const owner =  accounts[0];
      const temp_user =  accounts[1];
        const users = accounts.slice(2,2+load);
  
  
      const instance = await ethers.getContractFactory("Functionality");
      contract = await instance.deploy();
  
      let count = 1;
      users.forEach(async user => {
          await contract
          .connect(user)
          .registerUser(`User ${count}`, "Location 1", "1234567890");
      
          await contract
          .connect(user)
          .addContactDetails(`Location 1.2_${count}`, `1134567890`);
         
          count++;
      })
  
  
      
      await contract
        .connect(users[0])
        .listProduct(1, "Product 1", 1000, 100, 3, 100, [
          "tag_1",
          "tag_1",
          "tag_1",
          "tag_1",
          "tag_1",
        ]);
  
        await contract
        .connect(users[1])
        .listProduct(2, "Product 2", 1000, 100, 3, 100, [
          "tag_2",
          "tag_2",
          "tag_2",
          "tag_2",
          "tag_2",
        ]);
  
        await contract
        .connect(users[0])
        .modifyListedProduct(1, "Product 1", 1000, 100, 3, 100, [
          "tag_1",
          "tag_1",
          "tag_1",
          "tag_1",
          "tag_1",
        ]);
  
  
        for(let i=1;i<users.length;i++){
          await contract
          .connect(users[i])
          .buyProduct(1,1,{value:1100})
        }
  
  
        await contract
          .connect(users[0])
          .deliverProduct(users[1],1)
  
        await contract
        .connect(users[0])
        .deleteProductFromListing(1);
      return { owner, temp_user, users };
    }
  
    describe("Registering", function () {
      it("Should register and login an user", async function () {
        const { owner, temp_user, users } = await loadFixture(deployContract);
        expect(
          await contract
            .connect(temp_user)
            .registerUser("Subham", "Hirakud", "9090")
        )
          .to.emit(contract, "UserRegistered")
          .withArgs(temp_user, "Subham");
        let res = await contract.connect(temp_user).loginUser();
        expect(res).to.equal(true);
  
        users.forEach(async (user) => {
          expect(
            await contract
              .connect(user)
              .addContactDetails(`Location 1.${user}`, `1134567890_${user}`)
          )
            .to.emit(contract, "addressAdded")
            .withArgs(user);
  
          expect(
            await contract
              .connect(user)
              .modifyContactDetails(`Location 1.${user}`, `1134567890_${user}`, 1)
          )
            .to.emit(contract, "addressEdited")
            .withArgs(user);
        });
  
        for (let i = 0; i < users.length; i++) {
          expect(
            await contract
              .connect(users[i])
              .listProduct(i+100, `Product ${i + 100}`, 1000, 100, 3, 100, [
                `tag_${i + 100}`,
                `tag_${i + 100}`,
                `tag_${i + 100}`,
                `tag_${i + 100}`,
                `tag_${i + 100}`,
              ])
          )
            .to.emit(contract, "ProductRegistered")
            .withArgs(i+100);
        }
  
        for (let i = 0; i < users.length; i++) {
          expect(
            await contract
              .connect(users[i])
              .modifyListedProduct(i+100, `Product ${i + 100}`, 1000, 100, 3, 100, [
                `tag_${i + 100}`,
                `tag_${i + 100}`,
                `tag_${i + 100}`,
                `tag_${i + 100}`,
                `tag_${i + 100}`,
              ])
          )
            .to.emit(contract, "ProductEdited")
            .withArgs(i+100);
        }
  
        for (let i = 0; i < users.length; i++) {
          let user_id = (i+1)%5;
          expect(
            await contract
              .connect(users[user_id])
              .buyProduct(i+100,1,{value:1100})
          )
            .to.emit(contract, "OrderPlaced")
            .withArgs(users[user_id],1);
        }
  
        // for (let i = 0; i < users.length; i++) {
        //   let buyer_id = (i+1)%5;
        //   expect(
        //     await contract
        //       .connect(users[i])
        //       .deliverProduct(users[buyer_id],2)
        //   )
        //     .to.emit(contract, "OrderDelivered")
        //     .withArgs(users[buyer_id],1);
        // }
        
  
        // Do at the end.
        for (let i = 0; i < users.length; i++) {
          expect(
            await contract
              .connect(users[i])
              .deleteProductFromListing(i+100)
          )
            .to.emit(contract, "ProductDeleted")
            .withArgs(i+100);
        }
  
  
      });
    });
  });
  