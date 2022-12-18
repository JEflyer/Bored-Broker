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
  describe("Constructor", () => {
    //   constructor(
    //     uint256 _buyPrice,
    //     uint256 _rentPrice,
    //     uint8 _payPeriod,
    //     bool _forSale,
    //     address _owner
    // )

    it("Should not allow the csontrasct to be deployed if the rentPrice is null", async () => {
      const [deployer, owner, renter, buyer] = await ethers.getSigners();

      const buyPrice = 10000000;
      const rentPrice = 100000;

      const house = await ethers.getContractFactory("House", deployer);

      expect(
        house.deploy(buyPrice, 0, 0, true, owner.address)
      ).to.be.revertedWith("ERR:ZV");
    });

    it("Should not allow the contract to be deployed if the payperiod index is invalid", async () => {
      const [deployer, owner, renter, buyer] = await ethers.getSigners();

      const buyPrice = 10000000;
      const rentPrice = 100000;

      const house = await ethers.getContractFactory("House", deployer);

      expect(
        house.deploy(buyPrice, rentPrice, 110, true, owner.address)
      ).to.be.revertedWith("ERR:IV");
    });

    it("Should not allow the contract to be deployed if the ownre address is null", async () => {
      const [deployer, owner, renter, buyer] = await ethers.getSigners();

      const buyPrice = 10000000;
      const rentPrice = 100000;

      const house = await ethers.getContractFactory("House", deployer);

      expect(
        house.deploy(
          buyPrice,
          rentPrice,
          110,
          true,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWith("ERR:IA");
    });

    it("Should allow the contract to be deployed when all conditions are met", async () => {
      const [deployer, owner, renter, buyer] = await ethers.getSigners();

      const buyPrice = 10000000;
      const rentPrice = 100000;

      const house = await ethers.getContractFactory("House", deployer);

      expect(await house.deploy(buyPrice, rentPrice, 0, true, owner.address));

      // await House.deployed();
    });
  });

  describe("IsRentDue", () => {
    it("Should not", async () => {});
    it("Should ", async () => {});
  });

  describe("SetBuyPrice", () => {
    it("Should not allow to set the buy price to 0", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(owner).setBuyPrice(0)).to.be.revertedWith("ERR:ZP");
    });

    it("Should not allow to set the buy while deal is in progress", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).setDeal(1000, 5, 2, 3, buyer.address);

      await House.connect(owner).acceptDealByOwner();

      await House.connect(buyer).acceptDealByBuyer();

      expect(House.connect(deployer).setBuyPrice(2)).to.be.revertedWith(
        "ERR:ID"
      );
    });

    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });
  });

  describe("SetRentPrice", () => {
    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not allow to set rent price to zero", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(owner).setRentPrice(0)).to.be.revertedWith("ERR:ZR");
    });

    it("Should not allow to set the new rent while currently rented.", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).allowRenter(renter.address);

      await House.connect(renter).startNewRent({ value: rentPrice });

      expect(House.connect(owner).setRentPrice(100000)).to.be.revertedWith(
        "ERR:CR"
      );
    });
  });

  describe("SetPayPeriod", () => {
    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not allow to set the pay period to an invlaid pay period", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);
      //! Need to check the require statement
      //* DONE
      expect(House.connect(owner).setPayPeriod(2000)).to.be.revertedWith(
        "ERR:PP"
      );
    });

    it("Should not allow to set new pay period if the house is currently rented", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).allowRenter(renter.address);

      await House.connect(renter).startNewRent({ value: rentPrice });

      expect(House.connect(owner).setPayPeriod(100000)).to.be.revertedWith(
        "ERR:CR"
      );
    });
  });

  describe("SetForSale", () => {
    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not allow to set for sale if currently in deal", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).setDeal(1000, 5, 2, 3, buyer.address);

      await House.connect(owner).acceptDealByOwner();

      await House.connect(buyer).acceptDealByBuyer();

      expect(House.connect(owner).setForSale(true)).to.be.revertedWith(
        "ERR:ID"
      );
    });
  });

  describe("SetHouseDetails", () => {
    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not allow to set the buy price to Zero", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(owner).setHouseDetails(0, true)).to.be.revertedWith(
        "ERR:ZP"
      );
    });

    it("Should not allow to change House Details if currently in deal", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).setDeal(1000, 5, 2, 3, buyer.address);

      await House.connect(owner).acceptDealByOwner();

      await House.connect(buyer).acceptDealByBuyer();

      expect(
        House.connect(owner).setHouseDetails(1000, true)
      ).to.be.revertedWith("ERR:ID");
    });
  });

  describe("SetRentDetails", () => {
    it("Should not allow if the caller is not the owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentDetail(1000, 1)).to.be.revertedWith(
        "ERR:NO"
      );
    });
    it("Should not allow if the period in the argument is wrong value", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(owner).setRentDetail(1000, 1000)).to.be.revertedWith(
        "ERR:WV"
      );
    });
    it("Should not allow to set rent if the house is currently rented", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).allowRenter(renter.address);

      await House.connect(renter).startNewRent({ value: rentPrice });

      expect(House.connect(owner).setRentDetail(1000, 1)).to.be.revertedWith(
        "ERR:CR"
      );
    });
    it("Should not allow to set rent if the rent is 0 ", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(owner).setRentDetail(0, 1)).to.be.revertedWith(
        "ERR:ZP"
      );
    });
  });

  describe("ProposeNewRentDetails", () => {
    it("Should not allow if the caller is not the owner.", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(renter).proposeNewRentDetails(1000, 1)
      ).to.be.revertedWith("ERR:NO");
    });
    it("Should not allow if the period in the argument is wrong value", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(owner).proposeNewRentDetail(1000, 1000)
      ).to.be.revertedWith("ERR:WV");
    });
    it("Should not allow if the house is currently rented", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).allowRenter(renter.address);

      await House.connect(renter).startNewRent({ value: rentPrice });

      expect(
        House.connect(owner).proposeNewRentDetail(1000, 1)
      ).to.be.revertedWith("ERR:CR");
    });
    it("Should not allow if the rent is set to 0", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(owner).proposeNewRentDetail(0, 1)
      ).to.be.revertedWith("ERR:ZP");
    });
  });

  //! TODO
  describe("GetCurrentAmount", () => {
    it("Should ", async () => {});
  });

  describe("AgreeNewRentDetails", () => {
    it("Should not allow if the caller is not the renter", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(owner).proposeNewRentDetail(1000, 1);

      expect(House.connect(owner).agreeNewRentDetail(true)).to.be.revertedWith(
        "ERR:NR"
      );
    });
    it("Should not allow if the rent price is 0", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(owner).proposeNewRentDetail(0, 1);

      expect(House.connect(renter).agreeNewRentDetail(true)).to.be.revertedWith(
        "ERR:ZP"
      );
    });
    it("Should fail the transaction if the value passed is less then amount to be paid", async () => {});
  });

  describe("ChangeOwnership", () => {
    it("Should not allow if the caller is not deployer", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(owner).changeOwnership(buyer.address)
      ).to.be.revertedWith("ERR:ND");
    });
    it("Should not allow if the address given is 0 ", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(deployer).changeOwnership(ethers.constants.AddressZero)
      ).to.be.revertedWith("ERR:ZA");
    });
    it("Should change if the address passed is not zero and the caller is the deployer", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).changeOwnership(buyer.address);

      expect(await House.owner()).to.equal(buyer.address);
    });
  });

  describe("AllowRenter", () => {
    it("Should not allow if the caller is not the deployer", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(renter).allowRenter(buyer.address)
      ).to.be.revertedWith("ERR:ND");
    });
    it("Should not allow if the address passed is 0", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(
        House.connect(deployer).allowRenter(ethers.constants.AddressZero)
      ).to.be.revertedWith("ERR:ZA");
    });
    it("Should not allow if the renter is currently rented the house", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).allowRenter(renter.address);

      await House.connect(renter).startNewRent({ value: rentPrice });

      expect(
        House.connect(deployer).allowRenter(buyer.address)
      ).to.be.revertedWith("ERR:CR");
    });
    it("Should allow if the address passed is not 0 and the caller is the deployer", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      await House.connect(deployer).allowRenter(buyer.address);

      expect(await House.renter()).to.equal(buyer.address);
    });
  });

  describe("EmergencyKick", () => {});
  describe("KickOutRenter", () => {});
  describe("GetSeconds", () => {});
  describe("StartNewRent", () => {});
  describe("LeaveProperty", () => {});
  describe("GivePermissionFromGov", () => {});
  describe("GivePermissionByOwner", () => {});
  describe("LeavePropertyImmediately", () => {});
  describe("PayRent", () => {});
  describe("SetDeal", () => {});
  describe("AcceptDealByOwner", () => {});
  describe("AcceptDealByBuyer", () => {});
  describe("CancleDeal", () => {});
  describe("CancelActiveDealByOwner", () => {});
  describe("PayInstalments", () => {});
  describe("GivePermissionToCancelDeal", () => {});
  describe("GivePermissionToBuyOutright", () => {});
  describe("BuyOutright", () => {});
});
