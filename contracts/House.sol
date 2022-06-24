//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

contract House is Context{

    address private ownerOfProperty;

    address private deployer;

    struct HouseDetails {
        uint256 buyPrice;
        uint256 rentPrice;
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
        uint64 timeRentDue;
        uint64 timeRentedSince;
        uint64 timeRentedUntil;
        address renter;
    }

    mapping(uint256 => RenterDetails) private renters;

    uint256 private renterId;

    bool private currentlyInDeal;

    address private allowedRenter;

    enum payPeriod {
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
        string _city,
        uint256 _buyPrice,
        uint256 _rentPrice,
        uint8 _payPeriod;
        bool _forSale,
        address _owner
    ){
        house = HouseDetails({
            numOfBedrooms = _numOfBedrooms;
            numOfBathrooms= _numOfBathrooms;
            numOfFloors = _numOfFloors;
            squareFootLand = _squareFootLand;
            city = _city;
            buyPrice = _buyPrice;
            rentPrice = _rentPrice;
            forSale = _forSale;
        })
        deployer = _msgSender();
    
        ownerOfProperty = _owner;
    }

    modifier onlyOwner{
        require(_msgSender() == ownerOfProperty, "ERR:NO");//NO => Not Owner
        _;
    }

    modifier onlyDeployer {
        require(_msgSender() == deployer, "ERR:ND");//ND => No0t Deployer
        _;
    }

    modifier onlyApproved {
        require(_msgSender() == deployer || _msgSender == ownerOfProperty, "ERR:ND");//ND => No0t Deployer
        _;
    }

    function setBuyPrice(uint256 _new) external onlyOwner {
        require(_new != 0, "ERR:ZP");//ZP => Zero Price

        require(!currentlyInDeal, "ERR:ID");//ID => In Deal

        house.buyPrice = _new;

        //emit event
    }

    function setRentPrice(uint256 _new) external onlyOwner {
        require(renters[renterId].timeRentedUntil != 0, "ERR:CR");//CR => Currently Rented

        require(_new != 0, "ERR:ZR");//ZR => Zero Rent

        house.rentPrice = _new;

        //emit event
    }


    function setPayPeriod(uint64 _new) external onlyOwner{
        require(_new > uint64(7 days)-1, "ERR:ST");//ST => Small Time

        require(renters[renterId].timeRentedUntil != 0, "ERR:CR");//CR => Currently Rented

        house.payPeriod = _new;

        //emit event
    }


    function setForSale(bool _state) external onlyOwner {
        require(!currentlyInDeal, "ERR:ID");//ID => In Deal
        house.forSale = _state;

        //emit event
    }

    function setDetails(uint256 _bPrice, uint256 _rPrice, uint64 _period, bool _state) external onlyOwner {
        require(!currentlyInDeal, "ERR:ID");//ID => In Deal
        require(renters[renterId].timeRentedUntil != 0, "ERR:CR");//CR => Currently Rented
        require(_period > uint64(7 days)-1, "ERR:ST");//ST => Small Time
        require(_bPrice != 0, "ERR:ZP");//ZR => Zero Price
        require(_rPrice != 0, "ERR:ZR");//ZR => Zero Rent

        HouseDetails storage _house;

        _house.buyPrice = _bPrice;
        _house.rentPrice = _rPrice;
        _house.payPeriod = _period;
        _house.forSale = _state;

        //emit event
    }

    function changeOwnership(address _new) external onlyApproved {
        require(_new != address(0), "ERR:ZA");//ZA => Zero Address

        ownerOfProperty = _new;
    }

    function kickOutRenter() external onlyOwner {
        renters[renterId].timeRentedUntil = uint64(block.timestamp  + 7 days);
    }

    function emergencyKick() external onlyOwner {
        renters[renterId].timeRentedUntil = uint64(block.timestamp);
    }

    function allowRenter(address _renter) external onlyDeployer {
        require(_renter != address(0), "ERR:ZA");//ZA => Zero Address
        allowedRenter = _renter;
    }

    function getSeconds(uint8 index) internal view returns(uint64 time){
        if(index == 0){
            time = uint64(7 days);
        }else if(index == 1){
            time = uint64(14 days);
        }else if(index == 2){
            time = uint64(30 days);
        }else if(index == 3){
            time = uint64(90 days);
        }else if(index == 4) {
            time = uint64(180 days);
        }else if(index == 5){
            time = uint64(365 days);
        }
    }

    function startNewRent() external payable {
        require(_msgSender() == allowedRenter, "ERR:NA");//NA => Not Allowed

        require(allowedRenter != address(0), "ERR:ZA");//ZA => Zero Address


        if(renterId != 0){
            require(renters[renterId].timeRentedUntil != 0, "ERR:CR");//CR => Currently Rented
        }

        uint256 id = renterId+1;

        RenterDetails storage details = renters[id];

        details.timeRentedSince = uint64(block.timestamp);
        details.timeRentDue = uint64(block.timestamp + house.payPeriod);
        details.renter = allowedRenter;

        delete allowedRenter;
    
    
    }


    
    function buyProperty() external payable{

    }
}



    // struct RenterDetails {
    //     uint256 amountPaidTotal;
    //     uint64 timeRentDue;
    //     uint64 timeRentedSince;
    //     uint64 timeRentedUntil;
    //     address renter;
    // }
