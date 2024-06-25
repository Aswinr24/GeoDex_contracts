// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LandRegistry is ERC721URIStorage, ReentrancyGuard {
    uint256 private _landIdCounter;

    struct Land {
        uint256 id;
        string propertyId;
        uint256 area;
        string landAddress;
        uint256 landPrice;
        bool isForSale;
        address ownerAddress;
        bool isLandVerified;
    }

    struct User {
        address id;
        string name;
        string aadharNo;
        string panNo;
        string phoneNumber;
        string email;
        bool isUserVerified;
    }

    struct GovtAuthority {
        address id;
        string govtId;
        string name;
        string designation;
    }

    mapping(uint256 => Land) public lands;
    mapping(address => User) public users;
    mapping(address => GovtAuthority) public govtAuthorities;
    mapping(uint256 => address) private landToBuyer;
    mapping(uint256 => string) private landTransactionProofs;
    mapping(uint256 => string) private landTokenURIs;

    event LandRegistered(uint256 indexed landId, address indexed owner);
    event UserRegistered(address indexed user);
    event GovtAuthorityRegistered(address indexed govtAuthority);
    event LandListedForSale(uint256 indexed landId);
    event BuyRequestMade(uint256 indexed landId, address indexed buyer);
    event SaleApprovedByOwner(uint256 indexed landId, address indexed buyer, string proofUrl);
    event SaleApprovedByAuthority(uint256 indexed landId, address indexed buyer);
    event LandNFTMinted(uint256 indexed landId, address indexed owner);

    constructor() ERC721("LandRegistryToken", "LRT") {}

    modifier onlyVerifiedUser() {
        require(users[msg.sender].isUserVerified, "User not verified");
        _;
    }

    modifier onlyLandOwner(uint256 landId) {
        require(lands[landId].ownerAddress == msg.sender, "Only the land owner can perform this action");
        _;
    }

    modifier onlyGovtAuthority() {
        require(govtAuthorities[msg.sender].id != address(0), "Only government authority can perform this action");
        _;
    }

    function registerUser(
        string memory name,
        string memory aadharNo,
        string memory panNo,
        string memory phoneNumber,
        string memory email
    ) public {
        require(users[msg.sender].id == address(0), "User already registered");
        require(bytes(phoneNumber).length == 10, "Phone number must be 10 digits");
        require(bytes(aadharNo).length == 12, "Aadhar number must be 12 digits");
        users[msg.sender] = User(msg.sender, name, aadharNo, panNo, phoneNumber, email, false); // Initially not verified
        emit UserRegistered(msg.sender);
    }

    function registerGovtAuthority(
        string memory govtId,
        string memory name,
        string memory designation
    ) public {
        require(govtAuthorities[msg.sender].id == address(0), "Authority already registered");
        govtAuthorities[msg.sender] = GovtAuthority(msg.sender, govtId, name, designation);
        emit GovtAuthorityRegistered(msg.sender);
    }

    function verifyUser(address userAddress) public onlyGovtAuthority {
        users[userAddress].isUserVerified = true;
    }

    function registerLand(
        string memory propertyId,
        uint256 area,
        string memory landAddress,
        uint256 landPrice
    ) public onlyVerifiedUser {
        _landIdCounter++;
        uint256 newLandId = _landIdCounter;
        lands[newLandId] = Land(newLandId, propertyId, area, landAddress, landPrice, false, msg.sender, false);
        emit LandRegistered(newLandId, msg.sender);
    }

    function listLandForSale(uint256 landId, uint256 price) public onlyLandOwner(landId) {
        require(lands[landId].isLandVerified, "Land must be verified by government");
        lands[landId].isForSale = true;
        lands[landId].landPrice = price;
        emit LandListedForSale(landId);
    }

    function setTokenURI(uint256 landId, string memory tokenURI) public onlyLandOwner(landId) {
        require(bytes(tokenURI).length > 0, "Token URI cannot be empty");
        landTokenURIs[landId] = tokenURI;
    }

    function verifyLand(uint256 landId) public onlyGovtAuthority {
        require(bytes(landTokenURIs[landId]).length > 0, "Token URI must be set before verification");
        lands[landId].isLandVerified = true;
        _mint(lands[landId].ownerAddress, landId);
        _setTokenURI(landId, landTokenURIs[landId]);
        emit LandNFTMinted(landId, lands[landId].ownerAddress);
    }

    function requestToBuyLand(uint256 landId) public onlyVerifiedUser {
        require(lands[landId].isForSale, "Land not for sale");
        require(lands[landId].isLandVerified, "Land not verified");
        landToBuyer[landId] = msg.sender;
        emit BuyRequestMade(landId, msg.sender);
    }

    function approveSaleByOwner(uint256 landId, string memory proofUrl) public onlyLandOwner(landId) {
        require(landToBuyer[landId] != address(0), "No buyer for this land");
        landTransactionProofs[landId] = proofUrl;
        emit SaleApprovedByOwner(landId, landToBuyer[landId], proofUrl);
    }

    function approveSaleByAuthority(uint256 landId) public onlyGovtAuthority nonReentrant {
        address buyer = landToBuyer[landId];
        require(buyer != address(0), "No buyer for this land");
        require(bytes(landTransactionProofs[landId]).length > 0, "No transaction proof provided");

        address seller = lands[landId].ownerAddress;
        lands[landId].ownerAddress = buyer;
        lands[landId].isForSale = false;
        _transfer(seller, buyer, landId);
        
        emit SaleApprovedByAuthority(landId, buyer);
    }
}
