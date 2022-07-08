//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

contract House is Context {
    address private ownerOfProperty;

    address private deployer;

    struct HouseDetails {
        uint256 buyPrice;
        uint64 squareFootLand;
        uint8 numOfBedrooms;
        uint8 numOfBathrooms;
        uint8 numOfFloors;
        bool forSale;
        string city;
    }

    HouseDetails private house;

    struct RenterDetails {
        uint256 amountPaidTotal;
        uint256 rentPrice;
        uint64 timeRentDue;
        uint64 timeRentedSince;
        uint64 timeRentedUntil;
        PayPeriod payPeriod;
        address renter;
        bool renting;
        bool hasPermission;
    }

    mapping(uint256 => RenterDetails) private renters;

    address private allowedRenter;

    uint256 private renterId;

    bool private currentlyInDeal;

    struct DealDetails {
        uint256 amountPaidTotal;
        uint256 instalmentAmount;
        uint64 timeInstalmentDue;
        uint64 timeInstalmentSince;
        uint16 noOfInstalments;
        PayPeriod payPeriod;
        address buyer;
        bool termsAcceptedByOwner;
    }

    DealDetails private currentDeal;

    enum PayPeriod {
        week,
        twoWeeks,
        month,
        threeMonths,
        sixMonths,
        year
    }

    constructor(
        uint8 _numOfBedrooms,
        uint8 _numOfBathrooms,
        uint8 _numOfFloors,
        uint64 _squareFootLand,
        string memory _city,
        uint256 _buyPrice,
        uint256 _rentPrice,
        uint8 _payPeriod,
        bool _forSale,
        address _owner
    ) {
        house = HouseDetails({
            numOfBedrooms: _numOfBedrooms,
            numOfBathrooms: _numOfBathrooms,
            numOfFloors: _numOfFloors,
            squareFootLand: _squareFootLand,
            city: _city,
            buyPrice: _buyPrice,
            forSale: _forSale
        });
        deployer = _msgSender();

        RenterDetails storage renter = renters[1];

        renter.rentPrice = _rentPrice;
        renter.payPeriod = PayPeriod(_payPeriod);

        ownerOfProperty = _owner;
    }

    modifier onlyOwner() {
        require(_msgSender() == ownerOfProperty, "ERR:NO"); // NO => Not Owner
        _;
    }

    modifier onlyDeployer() {
        require(_msgSender() == deployer, "ERR:ND"); // ND => Not Deployer
        _;
    }

    modifier onlyBuyer() {
        require(_msgSender() == currentDeal.buyer, "ERR:NB"); // NB => Not Buyer
        _;
    }

    modifier onlyApproved() {
        address caller = _msgSender();
        require(caller == deployer || caller == ownerOfProperty, "ERR:ND"); //ND => No0t Deployer
        _;
    }

    modifier onlyRenter() {
        require(_msgSender() == renters[renterId].renter, "ERR:NA"); //NA => Not Approved
        _;
    }

    function setBuyPrice(uint256 _new) external onlyOwner {
        require(_new != 0, "ERR:ZP"); //ZP => Zero Price

        require(!currentlyInDeal, "ERR:ID"); //ID => In Deal

        house.buyPrice = _new;

        //emit event
    }

    function setRentPrice(uint256 _new) external onlyOwner {
        RenterDetails storage renter = renters[renterId];

        require(renter.timeRentedUntil != 0, "ERR:CR"); //CR => Currently Rented

        require(_new != 0, "ERR:ZR"); //ZR => Zero Rent

        renter.rentPrice = _new;

        //emit event
    }

    function setPayPeriod(uint8 _new) external onlyOwner {
        require(_new > uint64(7 days) - 1, "ERR:ST"); //ST => Small Time

        require(renters[renterId].timeRentedUntil != 0, "ERR:CR"); //CR => Currently Rented

        renters[renterId].payPeriod = PayPeriod(_new);

        //emit event
    }

    function setForSale(bool _state) external onlyOwner {
        require(!currentlyInDeal, "ERR:ID"); //ID => In Deal
        house.forSale = _state;

        //emit event
    }

    function setHouseDetails(uint256 _bPrice, bool _state) external onlyOwner {
        require(!currentlyInDeal, "ERR:ID"); //ID => In Deal
        require(_bPrice != 0, "ERR:ZP"); //ZR => Zero Price

        HouseDetails storage hDetails = house;

        hDetails.buyPrice = _bPrice;
        hDetails.forSale = _state;

        //emit event
    }

    function setRentDetail(uint256 _rPrice, uint8 _period) external onlyOwner {
        require(_period <= uint8(type(PayPeriod).max), "ERR:ST"); //ST => Small Time
        require(renters[renterId].timeRentedUntil != 0, "ERR:CR"); //CR => Currently Rented
        require(_rPrice != 0, "ERR:ZR"); //ZR => Zero Rent

        RenterDetails storage rDetails = renters[renterId + 1];

        rDetails.payPeriod = PayPeriod(_period);
        rDetails.rentPrice = _rPrice;

        //emit event
    }

    function changeOwnership(address _new) external onlyApproved {
        require(_new != address(0), "ERR:ZA"); //ZA => Zero Address

        ownerOfProperty = _new;
    }

    function kickOutRenter() external onlyOwner {
        renters[renterId].timeRentedUntil = uint64(block.timestamp + 7 days);
    }

    function emergencyKick() external onlyOwner {
        renters[renterId].timeRentedUntil = uint64(block.timestamp);
    }

    function allowRenter(address _renter) external onlyDeployer {
        require(_renter != address(0), "ERR:ZA"); //ZA => Zero Address
        allowedRenter = _renter;
    }

    function getSeconds(uint8 index) internal pure returns (uint64 time) {
        if (index == 0) {
            time = uint64(7 days);
        } else if (index == 1) {
            time = uint64(14 days);
        } else if (index == 2) {
            time = uint64(30 days);
        } else if (index == 3) {
            time = uint64(90 days);
        } else if (index == 4) {
            time = uint64(180 days);
        } else if (index == 5) {
            time = uint64(365 days);
        }
    }

    // Functionality for Renter
    function startNewRent() external payable onlyRenter {
        require(allowedRenter != address(0), "ERR:ZA"); //ZA => Zero Address

        uint256 id = renterId;

        RenterDetails storage details = renters[id];

        require(details.rentPrice != 0, "ERR:NS"); //NS => Not Set

        uint256 valueSent = msg.value;

        require(valueSent == details.rentPrice, "ERR:WV"); //WV => Wrong Value

        if (id != 0) {
            require(details.timeRentedUntil != 0, "ERR:CR"); //CR => Currently Rented
        }

        details.amountPaidTotal += valueSent;
        details.timeRentedSince = uint64(block.timestamp);
        details.timeRentDue =
            uint64(block.timestamp) +
            getSeconds(uint8(details.payPeriod));
        details.renter = allowedRenter;
        details.renting = true;

        delete allowedRenter;
    }

    // Functionality for renter to leave after 1 set payperiod
    function leaveProperty() external payable onlyRenter {
        RenterDetails storage details = renters[renterId];

        uint256 value = msg.value;
        require(value == details.rentPrice, "ERR:WV"); //WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: value}("");

        require(success, "ERR:OT"); //OT => On Trnasfer

        details.timeRentedUntil =
            uint64(block.timestamp) +
            getSeconds(uint8(details.payPeriod));

        delete details.renting;
    }

    // Functionality for renter to leave immdetialtely after having the permission from the owner or government
    function leavePropertyImmediately() external onlyRenter {
        uint256 id = renterId;

        RenterDetails storage details = renters[id];
        require(details.hasPermission, "ERR:NP"); //NP => No Permission

        details.timeRentedUntil = uint64(block.timestamp);

        delete details.renting;
    }

    function givePermissionFromGov() external onlyDeployer {
        uint256 id = renterId;

        RenterDetails storage details = renters[id];
        details.hasPermission = true;
    }

    function givePermissionFromOwner() external onlyOwner {
        uint256 id = renterId;

        RenterDetails storage details = renters[id];
        details.hasPermission = true;
    }

    function buyProperty() external payable {}

    function payRent() external payable onlyRenter {
        RenterDetails storage renter = renters[renterId];

        require(renter.renting, "ERR:NR"); //NR => Not Rented
        require(renter.timeRentDue <= block.timestamp, "ERR:ND"); // ND => Not Due

        uint256 value = msg.value;
        require(value == renter.rentPrice, "ERR:WV"); // WV => Wrong Price

        (bool success, ) = ownerOfProperty.call{value: value}("");
        require(success, "ERR:OT"); // OT => On Transfer

        renter.timeRentDue += getSeconds(uint8(renter.payPeriod));
        renter.amountPaidTotal += value;
    }

    function setDeal(
        uint256 _instalmentAmount,
        uint16 _noOfInstalments,
        PayPeriod _payPeriod,
        address _buyer
    ) external onlyDeployer {
        require(!currentlyInDeal, "ERR:ID"); // ID => In Deal

        DealDetails storage deal = currentDeal;

        deal.instalmentAmount = _instalmentAmount;
        deal.buyer = _buyer;
        deal.noOfInstalments = _noOfInstalments;
        deal.payPeriod = _payPeriod;
    }

    function acceptDealByOwner() external onlyOwner {
        require(!currentlyInDeal, "ERR:ID"); // ID => In Deal

        DealDetails storage deal = currentDeal;

        require(!deal.termsAcceptedByOwner, "ERR:AA"); // AA => Already Accepted

        deal.termsAcceptedByOwner = true;
    }

    function acceptDealByBuyer() external payable onlyBuyer {
        require(!currentlyInDeal, "ERR:ID"); // ID => In Deal

        DealDetails storage deal = currentDeal;

        uint256 value = msg.value;
        require(value == deal.instalmentAmount, "ERR:WV"); // WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: value}("");
        require(success, "ERR:OT"); // OT => On transfer

        deal.timeInstalmentSince = uint64(block.timestamp);
        --deal.noOfInstalments;
        deal.timeInstalmentDue =
            uint64(block.timestamp) +
            getSeconds(uint8(deal.payPeriod));
        deal.amountPaidTotal += value;
        currentlyInDeal = true;
    }

    //! TODO: Make seperate functions for owner to decline the deal after the approval of the deployer
    function cancelDeal() external {
        address caller = _msgSender();

        DealDetails storage deal = currentDeal;

        require(
            caller == ownerOfProperty ||
                caller == deal.buyer ||
                caller == deployer,
            "ERR:NA"
        ); // NA => Not Allowed

        if (caller != deal.buyer) {
            require(!currentlyInDeal, "ERR:ID");
        }
        delete deal.amountPaidTotal;
        delete deal.instalmentAmount;
        delete deal.timeInstalmentDue;
        delete deal.timeInstalmentSince;
        delete deal.noOfInstalments;
        delete deal.payPeriod;
        delete deal.buyer;
    }

    function payInstalments() external payable onlyBuyer {
        require(currentlyInDeal, "ERR:ND"); // ND => No Deal

        DealDetails storage deal = currentDeal;
        require(deal.timeInstalmentDue <= block.timestamp, "ERR:ND"); // ND => Not Due
        // require (deal.noOfInstalments !=0, "ERR:DC"); // DC => Deal Completed

        uint256 value = msg.value;
        require(value == deal.instalmentAmount, "ERR:WV"); // WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: value}("");

        require(success, "ERR:OT");

        if (--deal.noOfInstalments == 0) {
            ownerOfProperty = deal.buyer;

            delete currentlyInDeal;

            //emit event

            delete deal.amountPaidTotal;
            delete deal.instalmentAmount;
            delete deal.timeInstalmentDue;
            delete deal.timeInstalmentSince;
            delete deal.noOfInstalments;
            delete deal.payPeriod;
            delete deal.buyer;
        } else {
            deal.amountPaidTotal += value;

            deal.timeInstalmentDue += getSeconds(uint8(deal.payPeriod));
        }
    }
}
