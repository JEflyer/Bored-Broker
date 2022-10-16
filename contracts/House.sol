//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract House is Context, ReentrancyGuard {
    address private ownerOfProperty;

    address private deployer; // * Government

    // * Details of the House
    struct HouseDetails {
        uint256 buyPrice;
        // uint64 squareFootLand;
        // uint8 numOfBedrooms;
        // uint8 numOfBathrooms;
        // uint8 numOfFloors;
        bool forSale;
        // string city;
    }

    HouseDetails private house;

    // * Renting Details
    struct RenterDetails {
        uint256 amountPaidTotal; // * Total amount paid by the renter
        uint256 rentPrice; 
        uint64 timeRentDue; 
        uint64 timeRentedSince; 
        uint64 timeRentedUntil; 
        PayPeriod payPeriod;
        address renter; // * Address of the renter
        bool renting; // * Is the house being rented?
        bool hasPermission; // * Does the renter have permission to rent the house?
    }

    struct proposedNewRentDetails {
        uint256 rentPrice;
        PayPeriod payPeriod;
    }

    proposedNewRentDetails private newRentDetails;

    address private allowedRenter;

    uint256 private renterId;

    mapping(uint256 => RenterDetails) private renters;

    bool private currentlyInDeal;

    address private allowedPurchaser;

    // * Buying Deal Details
    struct DealDetails {
        uint256 amountPaidTotal;
        uint256 instalmentAmount;
        uint64 timeInstalmentDue;
        uint64 timeInstalmentSince;
        uint16 noOfInstalments;
        uint16 penaltyPercentForOwner; // * Penalty for the owner if he can the deal
        PayPeriod payPeriod;
        address buyer;
        bool termsAcceptedByOwner;
        bool cancellingPermission;
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

    // error ZeroValue();

    constructor(
        uint256 _buyPrice,
        uint256 _rentPrice,
        uint8 _payPeriod,
        bool _forSale,
        address _owner
    ) {
        // if(_rentPrice == 0) revert ZeroValue();
        require (_rentPrice!=0, "ERR:ZV");  // ZV => Zero Value

        require (_payPeriod <= uint8(type(PayPeriod).max), "ERR:IV"); // IV => Invalid Value
        require (_owner != address(0), "ERR:IA"); // IA => Invalid Address  

        house = HouseDetails({
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
        require(caller == deployer || caller == ownerOfProperty, "ERR:ND"); //ND => Not Deployer
        _;
    }

    modifier onlyRenter() {
        require(_msgSender() == renters[renterId].renter, "ERR:NA"); //NA => Not Approved
        _;
    }

    //* FUNCTION: To check whether the rent is due
    function isRentDue(uint256 _renterId) external view returns (bool) {
        return
            renters[_renterId].timeRentDue < uint64(block.timestamp)
                ? true
                : false;
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
        require(_period <= uint8(type(PayPeriod).max), "ERR:WV"); //WV => Wrong Value
        require(renters[renterId].timeRentedUntil != 0, "ERR:CR"); //CR => Currently Rented
        require(_rPrice != 0, "ERR:ZR"); //ZR => Zero Rent

        RenterDetails storage rDetails = renters[renterId + 1];

        rDetails.payPeriod = PayPeriod(_period);
        rDetails.rentPrice = _rPrice;

        //emit event
    }

    function proposeNewRentDetial(uint256 _rPrice, uint8 _period)
        external
        onlyOwner
    {
        require(_period <= uint8(type(PayPeriod).max), "ERR:ST"); //ST => Small Time
        require(renters[renterId].timeRentedUntil == 0, "ERR:CR"); // CR => Currently Rented
        require(_rPrice != 0, "ERR:ZR"); //ZR => Zero Rent

        newRentDetails = proposedNewRentDetails({
            rentPrice: _rPrice,
            payPeriod: PayPeriod(_period)
        });

        // emit Event
    }

    function getCurrentAmount() public view returns (uint256) {
        RenterDetails storage details = renters[renterId];

        uint64 curentPayPeriod = getSeconds(uint8(details.payPeriod));

        uint256 amountToPay = ((((block.timestamp -
            (details.timeRentDue - curentPayPeriod)) * 100) /
            (curentPayPeriod)) * details.rentPrice) / 100;

        return amountToPay;
    }

    //* Function: To accept the new rent details and update the rent details.
    function agreeNewRentDetail(bool accepted) external payable onlyRenter {
        proposedNewRentDetails storage rentDetails = newRentDetails;
        require(rentDetails.rentPrice != 0, "ERR:NS"); // NS=> Not Set

        if (accepted) {
            RenterDetails storage details = renters[renterId];

            uint64 curentPayPeriod = getSeconds(uint8(details.payPeriod));

            uint256 amountToPay = ((((block.timestamp -
                (details.timeRentDue - curentPayPeriod)) * 100) /
                (curentPayPeriod)) * details.rentPrice) / 100;

            uint256 value = msg.value;
            require(value >= amountToPay, "ERR:WV"); // WV => Wrong Value

            details.payPeriod = rentDetails.payPeriod;
            details.rentPrice = rentDetails.rentPrice;

            (bool success, ) = ownerOfProperty.call{value: value}("");
            require(success, "ERR:OT"); //OT=> On Transaction

            delete rentDetails.payPeriod;
            delete rentDetails.rentPrice;
        } else {
            delete rentDetails.payPeriod;
            delete rentDetails.rentPrice;

            // TODO: If not accepted, then kick out the renter or change the .
        }
        //emit Event (pass the bool)
    }

    //* FUNCTION: To transfer the propety.
    function changeOwnership(address _new) external onlyDeployer {
        require(_new != address(0), "ERR:ZA"); //ZA => Zero Address

        ownerOfProperty = _new;
    }

    //* FUNCTION: To kick out the renter with some grace period.
    function kickOutRenter(uint64 _gracePeriod) external onlyOwner {
        RenterDetails memory details = renters[renterId];

        require(!details.renting, "ERR:NR"); //NR => Not Renting
        require(_gracePeriod >= getSeconds(uint8(details.payPeriod)), "ERR:GP"); //GP => Grace Period

        details.timeRentedUntil = uint64(block.timestamp) + _gracePeriod;

        // Emit Event
    }

    //* FUNCTION: To kick out the renter immediately if he damages the property.
    function emergencyKick() external onlyOwner {
        RenterDetails storage details = renters[renterId];

        require(!details.renting, "ERR:NR"); //NR => Not renting

        uint256 amountToRefund = details.rentPrice - getCurrentAmount();

        (bool success, ) = renters[renterId].renter.call{value: amountToRefund}(
            ""
        );
        require(success, "ERR:OT"); //OT=> On Transaction

        renters[renterId].timeRentedUntil = uint64(block.timestamp);

        // Emit Event
    }

    function allowRenter(address _renter) external onlyDeployer {
        // Check there is currenlty no renter in this house
        require(renters[renterId].timeRentedUntil == 0, "ERR:CR"); //CR => Currently Rented

        require(_renter != address(0), "ERR:ZA"); //ZA => Zero Address
        allowedRenter = _renter;
    }

    function getSeconds(uint8 index) internal pure returns (uint64 time) {
        require(index <= uint8(type(PayPeriod).max), "ERR:ST"); //ST => Small Time

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

    // *  Functionality for Renter
    function startNewRent() external payable {
        address allowedRenterInstance = allowedRenter;

        require(allowedRenterInstance != address(0), "ERR:ZA"); //ZA => Zero Address
        require(allowedRenterInstance == _msgSender(), "ERR:NR"); //NR => Not Renter

        uint256 id = renterId;

        RenterDetails storage details = renters[id];

        require(details.rentPrice != 0, "ERR:NS"); //NS => Not Set

        uint256 valueSent = msg.value;

        require(valueSent == details.rentPrice, "ERR:WV"); //WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: valueSent}("");
        require(success, "ERR:OT"); //OT => On Transfer

        if (id != 0) {
            require(details.timeRentedUntil != 0, "ERR:CR"); //CR => Currently Rented
        }

        details.amountPaidTotal += valueSent;
        details.timeRentedSince = uint64(block.timestamp);
        details.timeRentDue =
            uint64(block.timestamp) +
            getSeconds(uint8(details.payPeriod));
        details.renter = allowedRenterInstance;
        details.renting = true;

        delete allowedRenter;
    }

    //* Functiona: For renter to leave after 1 set payperiod
    function leaveProperty() external payable onlyRenter {
        RenterDetails storage details = renters[renterId];

        uint256 value = msg.value;
        require(value == details.rentPrice, "ERR:WV"); //WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: value}("");
        require(success, "ERR:OT"); //OT => On Transfer

        details.timeRentedUntil =
            uint64(block.timestamp) +
            getSeconds(uint8(details.payPeriod));

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

    //* Function: for renter to leave immdetialtely after having the permission from the owner or government
    function leavePropertyImmediately() external onlyRenter {
        uint256 id = renterId;

        RenterDetails storage details = renters[id];
        require(details.hasPermission, "ERR:NP"); //NP => No Permission

        details.timeRentedUntil = uint64(block.timestamp);

        delete details.renting;
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

    //* FUNCTION: For buying the house
    function setDeal(
        uint256 _instalmentAmount,
        uint16 _noOfInstalments,
        uint16 _penaltyPercentageForOwner,
        uint8 _payPeriod,
        address _buyer
    ) external onlyDeployer {
        require(!currentlyInDeal, "ERR:ID"); // ID => In Deal
        
        require(_instalmentAmount!= 0, "ERR:ZV"); // ZV => Zero Value
        require(_penaltyPercentageForOwner!=0, "ERR:ZV"); // ZV => Zero Value
        require(_noOfInstalments!=0, "ERR:ZV"); // ZV => Zero Value
        require(_buyer != address(0), "ERR:ZA"); // ZA => Zero Address
        require(_payPeriod <= uint8(type(PayPeriod).max), "ERR:IV"); // IV => Invalid Value


        DealDetails storage deal = currentDeal;

        deal.instalmentAmount = _instalmentAmount;
        deal.buyer = _buyer;
        deal.penaltyPercentForOwner = _penaltyPercentageForOwner;
        deal.noOfInstalments = _noOfInstalments;
        deal.payPeriod = PayPeriod(_payPeriod);
    }

    // * FUUNCTION: For accepting the deal by the owner.
    function acceptDealByOwner() external onlyOwner {
        require(!currentlyInDeal, "ERR:ID"); // ID => In Deal

        DealDetails storage deal = currentDeal;

        require(!deal.termsAcceptedByOwner, "ERR:AA"); // AA => Already Accepted

        deal.termsAcceptedByOwner = true;
    }

    // * FUNCTION: For accepting the deal by the Buyer
    function acceptDealByBuyer() external payable onlyBuyer {
        require(!currentlyInDeal, "ERR:ID"); // ID => In Deal

        DealDetails storage deal = currentDeal;
        require(deal.termsAcceptedByOwner, "ERR:NA"); // NA => Not Accepted

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

    // * FUNCTION: Cancel the buying deal before in the the deal
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
            require(!currentlyInDeal, "ERR:ID"); // ID => In Deal
        }
        resetDetails(deal);
    }

    // * FUNCTION: Request to raise permission for canceling the active buying deal by the owner.
    function cancelActiveDealByOwner() external payable onlyOwner {
        DealDetails storage deal = currentDeal;

        if (deal.cancellingPermission) {
            resetDetails(deal);
        } else {
            uint256 value = msg.value;
            uint256 penaltyAmount = (deal.amountPaidTotal *
                deal.penaltyPercentForOwner) / 100;
            require(value == penaltyAmount, "ERR:WV"); // WV=> Wrong Value

            (bool success, ) = deal.buyer.call{value: value}("");
            require(success);

            resetDetails(deal);
        }

        // Emit Event
    }

    function givePermissionToCancelActiveDeal() external onlyDeployer {
        DealDetails storage deal = currentDeal;
        require(currentlyInDeal, "ERR:ND"); // ND=> No Deal
        deal.cancellingPermission = true;
    }

    //* FUNCTION: To reset the deal Details
    function resetDetails(DealDetails storage _deal) internal {
        delete _deal.amountPaidTotal;
        delete _deal.instalmentAmount;
        delete _deal.timeInstalmentDue;
        delete _deal.timeInstalmentSince;
        delete _deal.noOfInstalments;
        delete _deal.payPeriod;
        delete _deal.buyer;
        delete _deal.penaltyPercentForOwner;
    }

    // * FUNCTION: Paying the instalments of the house after buying.
    function payInstalments() external payable onlyBuyer nonReentrant {
        require(currentlyInDeal, "ERR:ND"); // ND => No Deal

        DealDetails storage deal = currentDeal;
        require(deal.timeInstalmentDue <= block.timestamp, "ERR:ND"); // ND => Not Due
        // require (deal.noOfInstalments !=0, "ERR:DC"); // DC => Deal Completed

        uint256 value = msg.value;
        require(value == deal.instalmentAmount, "ERR:WV"); // WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: value}("");

        require(success, "ERR:OT"); // OT => ON Transfer

        if (--deal.noOfInstalments == 0) {
            ownerOfProperty = deal.buyer;

            delete currentlyInDeal;

            resetDetails(deal);

            //emit event
        } else {
            deal.amountPaidTotal += value;

            deal.timeInstalmentDue += getSeconds(uint8(deal.payPeriod));
        }
    }

    // * FUNCTION: Giving permission to the address to buy the property at Once
    function givePermissionToBuyOutRight(address _approvedBuyer)
        external
        onlyDeployer
    {
        require(_approvedBuyer != address(0), "ERR:ZA"); // ZA => Zero Address
        allowedPurchaser = _approvedBuyer;
    }

    // * FUNCTION: Buy Out the property right away with permission from deployer.
    function buyOutRight() external payable {
        address caller = _msgSender();

        require(caller == allowedPurchaser, "ERR:NA"); // NA=> Not Allowed

        uint256 value = msg.value;
        require(value == house.buyPrice, "ERR:WV"); // WV => Wrong Value

        (bool success, ) = ownerOfProperty.call{value: value}("");
        require(success, "ERR:OT"); // OT => On transfer

        ownerOfProperty = caller;
    }
}
