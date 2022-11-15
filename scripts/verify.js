// imports
const { ethers, run, network } = require("hardhat")

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Token = await ethers.getContractFactory("Predictoor");
    const token = await Token.deploy();
  
    console.log("Predictoor address:", token.address);
    console.log("ETHERSCAN KEY :", process.env.ETHERSCAN_API_KEY); 

    if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for block confirmations...")
        await token.deployTransaction.wait(6)
        await verify(token.address, [])
      }

  }
  
// async function verify(contractAddress, args) {
    const verify = async (contractAddress, args) => {
        console.log("Verifying contract...")
        try {
          await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
          })
        } catch (e) {
          if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already Verified!")
          } else {
            console.log(e)
          }
        }
      }

  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });