const { ethers } = require("hardhat");
const { expect } = require("chai");


const sendValue = ethers.utils.parseEther("1")

describe("Deploy Contract", function () {
  it("Should deploy the contract with winner set to 0 ", async function () {
    const [owner] = await ethers.getSigners();

    const Predictoor_Contract = await ethers.getContractFactory("Predictoor");

    const hardhatToken = await Predictoor_Contract.deploy();
    const a = hardhatToken.setWinner(5);
    const winner = await hardhatToken.winner;
    expect(winner ==5);
  });
});

describe("minting", function () {
    // https://ethereum-waffle.readthedocs.io/en/latest/matchers.html
    // could also do assert.fail
    it("Should return 1 ", async () => {
        const [owner] = await ethers.getSigners();

        const Predictoor_Contract = await ethers.getContractFactory("Predictoor");
    
        const predictor = await Predictoor_Contract.deploy();

        await predictor.mintItem({ value: sendValue });
        const id =  predictor._tokenIds.mintItem(1, 1);

        expect (id == 1) ;
    });
});