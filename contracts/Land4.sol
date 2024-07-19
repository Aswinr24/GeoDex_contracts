// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LandRegistry is ReentrancyGuard {
    uint256 private _landIdCounter = 0;
    uint256 private _userIdCounter = 0; 
    uint256[] private _registeredUserIds; 
    uint256[] private _registeredLandIds; 
    uint256 private _latestSaleTokenId = 0;

    struct Land {
        uint256 id;
        string landDetails; 
        uint256 area;
        string landAddress;
        uint256 landPrice;
        bool isForSale;
        address ownerAddress;
        bool isLandVerified;
    }

    struct User {
        uint256 id;
        address accountAddress;
        string name;
        string details; 
        string phoneNumber;
        string email;
        bool isUserVerified;
    }

    struct GovtAuthority {
        address accountAddress;
        string govtId;
        string name;
        string email;
    }

    mapping(uint256 => Land) public lands;
    mapping(uint256 => User) public users;
    mapping(address => uint256) private userAddressToId;
    mapping(address => GovtAuthority) public govtAuthorities;
    mapping(uint256 => address) private landToBuyer;
    mapping(uint256 => string) private landTransactionProofs;
    mapping(uint256 => uint256) private _landToSaleId; // Maps land ID to sale ID
    mapping(uint256 => bool) private _approvedSales; // Tracks approved sales

    event LandRegistered(uint256 indexed landId, address indexed owner);
    event UserRegistered(uint256 indexed userId, address indexed accountAddress);
    event GovtAuthorityRegistered(address indexed accountAddress);
    event LandListedForSale(uint256 indexed landId);
    event BuyRequestMade(uint256 indexed landId, address indexed buyer);
    event SaleApprovedByOwner(uint256 indexed saleTokenId, uint256 indexed landId, address indexed buyer, string proofUrl);
    event SaleApprovedByAuthority(uint256 indexed saleTokenId, uint256 indexed landId, address indexed buyer);

    modifier onlyVerifiedUser() {
    require(users[userAddressToId[msg.sender]].isUserVerified, "User not verified");
    _;
}

    modifier onlyLandOwner(uint256 landId) {
        require(lands[landId].ownerAddress == msg.sender, "Only the land owner can perform this action");
        _;
    }

    modifier onlyGovtAuthority() {
        require(govtAuthorities[msg.sender].accountAddress != address(0), "Only government authority can perform this action");
        _;
    }

    function registerUser(
        string memory name,
        string memory details, 
        string memory phoneNumber,
        string memory email
    ) public {
        require(userAddressToId[msg.sender] == 0, "User already registered");
        _userIdCounter++;
        uint256 newUserId = _userIdCounter;
        users[newUserId] = User(newUserId, msg.sender, name, details, phoneNumber, email, false); 
        _registeredUserIds.push(newUserId); // Add user ID to the array
        userAddressToId[msg.sender] = newUserId; // Map the user address to the new user ID
        emit UserRegistered(newUserId, msg.sender);
    }


    function registerGovtAuthority(
        string memory govtId,
        string memory name,
        string memory email
    ) public {
        require(govtAuthorities[msg.sender].accountAddress == address(0), "Authority already registered");
        govtAuthorities[msg.sender] = GovtAuthority( msg.sender, govtId, name, email);
        emit GovtAuthorityRegistered(msg.sender);
    }

    function verifyUser(uint256 userId) public onlyGovtAuthority {
        users[userId].isUserVerified = true;
    }

    function registerLand(
        string memory landDetails, 
        uint256 area,
        string memory landAddress,
        uint256 landPrice
    ) public onlyVerifiedUser {
        _landIdCounter++;
        uint256 newLandId = _landIdCounter;
        lands[newLandId] = Land(newLandId, landDetails, area, landAddress, landPrice, false, msg.sender, false);
        _registeredLandIds.push(newLandId); // Add land ID to the array
        emit LandRegistered(newLandId, msg.sender);
    }


    function listLandForSale(uint256 landId, uint256 price) public onlyLandOwner(landId) {
        require(lands[landId].isLandVerified, "Land must be verified by government");
        lands[landId].isForSale = true;
        lands[landId].landPrice = price;
        emit LandListedForSale(landId);
    }

    function verifyLand(uint256 landId) public onlyGovtAuthority {
        lands[landId].isLandVerified = true;
    }

    function getLandDetails(uint256 landId) public view returns (
        string memory landDetails,
        uint256 area,
        string memory landAddress,
        uint256 landPrice,
        uint256 ownerId,
        bool isLandVerified
    ) {
        require(msg.sender == govtAuthorities[msg.sender].accountAddress || msg.sender == lands[landId].ownerAddress,
            "Caller is not authorized to view land details");
        uint256 userId = userAddressToId[lands[landId].ownerAddress];
        return (
            lands[landId].landDetails,
            lands[landId].area,
            lands[landId].landAddress,
            lands[landId].landPrice,
            userId, 
            lands[landId].isLandVerified
        );
    }

    function getUserDetails(uint256 userId) public view onlyGovtAuthority returns (
        uint256 id,
        string memory name,
        string memory details,
        string memory phoneNumber,
        string memory email,
        address accountAddress,
        bool isUserVerified
    ) {
        return (
            users[userId].id,
            users[userId].name,
            users[userId].details,
            users[userId].phoneNumber,
            users[userId].email,
            users[userId].accountAddress,
            users[userId].isUserVerified
        );
    }
    
    function getMyDetails() public view returns (
        uint256 id,
        string memory name,
        string memory details,
        string memory phoneNumber,
        string memory email,
        address accountAddress,
        bool isUserVerified
    ) {
        uint256 userId = userAddressToId[msg.sender];
        require(userId != 0, "User not found");
        User memory user = users[userId];
        return (
            user.id,
            user.name,
            user.details,
            user.phoneNumber,
            user.email,
            user.accountAddress,
            user.isUserVerified
        );
    }

    function getLandIds() public view onlyVerifiedUser returns (uint256[] memory) {
        return _registeredLandIds;
    }

    function getLandDetailsUser(uint256 landId) public view onlyVerifiedUser returns (
        uint256 area,
        string memory landAddress,
        uint256 landPrice,
        string memory ownerName,
        string memory ownerPhoneNumber,
        string memory ownerEmail
    ) {
        address landOwner = lands[landId].ownerAddress;
        User memory owner = users[userAddressToId[landOwner]];
        return (
            lands[landId].area,
            lands[landId].landAddress,
            lands[landId].landPrice,
            owner.name,
            owner.phoneNumber,
            owner.email
        );
    }

    function getBuyerDetails(uint256 landId) public view onlyLandOwner(landId) returns (
        address accountAddress,
        string memory name,
        string memory phoneNumber,
        string memory email
    ) {
        address buyer = landToBuyer[landId];
        require(buyer != address(0), "No buyer for this land");
        uint256 buyerId = userAddressToId[buyer];
        return (
            users[buyerId].accountAddress,
            users[buyerId].name,
            users[buyerId].phoneNumber,
            users[buyerId].email
        );
    }


    function getRegisteredUserIds() public view onlyGovtAuthority returns (uint256[] memory) {
        return _registeredUserIds;
    }

    function getRegisteredLandIds() public view onlyGovtAuthority returns (uint256[] memory) {
        return _registeredLandIds;
    }

    function requestToBuyLand(uint256 landId) public onlyVerifiedUser {
        require(lands[landId].isForSale, "Land not for sale");
        landToBuyer[landId] = msg.sender;
        emit BuyRequestMade(landId, msg.sender);
    }

    function approveSaleByOwner(uint256 landId, string memory proofUrl) public onlyLandOwner(landId) {
        require(landToBuyer[landId] != address(0), "No buyer for this land");
        _latestSaleTokenId++;
        _landToSaleId[landId] = _latestSaleTokenId;
        landTransactionProofs[landId] = proofUrl;
        emit SaleApprovedByOwner(_latestSaleTokenId, landId, landToBuyer[landId], proofUrl);
    }

   function getSaleDetailsForApproval(uint256 landId) public view onlyGovtAuthority returns (
        address ownerAddress,
        uint256 ownerId,
        address buyer,
        uint256 buyerId,
        string memory proofUrl
    ) {
        require(bytes(landTransactionProofs[landId]).length > 0, "Sale not approved by owner");
        ownerAddress = lands[landId].ownerAddress;
        ownerId = users[userAddressToId[ownerAddress]].id;
        buyer = landToBuyer[landId];
        if (buyer != address(0)) {
            buyerId = users[userAddressToId[buyer]].id;
        }
        proofUrl = landTransactionProofs[landId];
        return (ownerAddress, ownerId, buyer, buyerId, proofUrl);
   }

    function approveSaleByAuthority(uint256 landId) public onlyGovtAuthority {
        require(_landToSaleId[landId] != 0, "No sale approved for this land");
        require(!_approvedSales[_landToSaleId[landId]], "Sale already approved");
        uint256 saleTokenId = _landToSaleId[landId];
        _landToSaleId[landId] = 0;
        _approvedSales[saleTokenId] = true;
        lands[landId].ownerAddress = landToBuyer[landId];
        lands[landId].isForSale = false;
        delete landToBuyer[landId];
        emit SaleApprovedByAuthority(saleTokenId, landId, landToBuyer[landId]);
    }

    function getLatestSaleAndLandId() public view returns (uint256 saleTokenId, uint256 landId) {
        require(_latestSaleTokenId > 0, "No sales approved yet");
        uint256 latestSaleId = _latestSaleTokenId;
        uint256 latestLandId = _landIdCounter;
        while (latestSaleId > 0 && !_approvedSales[latestSaleId]) {
            latestSaleId--;
        }
        return (latestSaleId, latestLandId);
    }
}
