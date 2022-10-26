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
      ).to.be.revertedWith("ERR:IV");
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

      expect(House.connect(owner).SetBuyPrice(0)).to.be.revertedWith("ERR:ZP");
    });

    it("Should not allow to set the buy while deal is in progress", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);
      expect(House.connect(deployer).SetBuyPrice);
    });

    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not", async () => {});
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

      expect(House.connect(owner).setRentPrice(0)).to.be.revertedWith("ERR:ZP");
    });

    it("Should not allow to set the new rent while currently rented.", async () => {});

    it("Should ", async () => {});
  });

  describe("SetPayPeriod", () => {
    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not allow to set the pay period of less than 7 days", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);
      //! Need to check the require statement
      expect(House.connect(owner).setPayPeriod());
    });

    it("Should not allow to set new pay period if the house is currently rented", async () => {});

    it("Should not", async () => {});
  });

  describe("SetForSale", () => {
    it("Should be reverted if caller is not owner", async () => {
      let { House, buyPrice, rentPrice, owner, deployer, renter, buyer } =
        await loadFixture(setup);

      expect(House.connect(renter).setRentPrice(1)).to.be.revertedWith(
        "ERR:NO"
      );
    });

    it("Should not allow to set for sale if currently in deal", async () => {});

    it("Should ", async () => {});
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
    it("Should ", async () => {});
  });

  describe("SetRentDetails", () => {
    it("Should not", async () => {});
    it("Should not", async () => {});
    it("Should not", async () => {});
    it("Should ", async () => {});
    it("Should ", async () => {});
  });
  describe("ProposeNewRentDetails", () => {
    it("Should not", async () => {});
    it("Should not", async () => {});
    it("Should not", async () => {});
    it("Should not", async () => {});
    it("Should ", async () => {});
  });
  describe("GetCurrentAmount", () => {
    it("Should ", async () => {});
  });
  describe("AgreeNewRentDetails", () => {
    it("Should not", async () => {});
    it("Should ", async () => {});
    it("Should ", async () => {});
  });
  describe("ChangeOwnership", () => {
    it("Should not", async () => {});
    it("Should ", async () => {});
    it("Should not", async () => {});
  });
  describe("AllowRenter", () => {});
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
