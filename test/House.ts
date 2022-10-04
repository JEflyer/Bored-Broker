import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("House", function () {
  async function setup() {
    const [deployer, owner, renter, buyer] = await ethers.getSigners();

    const buyPrice = 10000000;
    const rentPrice = 100000;

    const house = await ethers.getContractFactory("House", deployer);

    const House = await house.deploy(
      1,
      1,
      1,
      100,
      "Paris",
      buyPrice,
      rentPrice,
      0,
      true,
      owner.address
    );

    await House.deployed();

    return {
      House,
      buyPrice,
      rentPrice,
      owner,
      deployer,
      renter,
      buyer,
    };
  }

  describe("Testing", function () {
    it("", async function () {
      const { House, buyPrice, rentPrice, owner, deployer, renter, buyer } = await loadFixture(setup);




    });
    it("", async function () {
      const { House, buyPrice, rentPrice, owner, deployer, renter, buyer } = await loadFixture(setup);

      


    });
  });
});
