// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FoodCrispRegistration {
    address public fdaAuthority;
    address public contractOwner;

    struct Company {
        string name;
        string productDomain;
        string ownerName;
        string location;
        string contactNumber;
        bool authorized;
        bool isRegistered;
        address assignedBy;
        bool reject;
        Personnel personnel;
        bool documentsSubmitted; // Flag to track if all documents are submitted
        uint256 registrationTimestamp; // Timestamp when the registration request was made
        string[] documentHashes; // Array to store document IPFS hashes
    }

    struct Personnel {
        string name;
        string contact;
    }

    mapping(address => Company) public companies;
    address[] public companyAddresses; // Array to store company addresses

    event RegistrationApproved(address indexed companyAddress, address indexed assignedBy);
    event DocumentsSubmitted(address indexed companyAddress, string indexed documentType, string ipfsHash);
    event PersonnelAssigned(address indexed companyAddress, string personnelName, string personnelContact);

    modifier onlyFDAAuthority() {
        require(msg.sender == fdaAuthority, "Only FDA authority can call this function");
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        //fdaAuthority = msg.sender;
        contractOwner = msg.sender;
    }

    function setFDAAuthority(address _newFDAAuthority) external {
        fdaAuthority = _newFDAAuthority;
    }

    function registerNewCompany(
        string memory _name,
        string memory _productDomain,
        string memory _ownerName,
        string memory _location,
        string memory _contactNumber
    ) external {
        require(!companies[msg.sender].isRegistered, "Company already registered");

        companies[msg.sender] = Company({
            name: _name,
            productDomain: _productDomain,
            ownerName: _ownerName,
            location: _location,
            contactNumber: _contactNumber,
            authorized: false,
            isRegistered: false,
            reject: false,
            assignedBy: address(0),
            personnel: Personnel("", ""),
            documentsSubmitted: false, // Initialize documentsSubmitted to false
            registrationTimestamp: block.timestamp, // Set the registration timestamp
            documentHashes: new string[](0) // Initialize the documentHashes array
        });

        companyAddresses.push(msg.sender); // Add the new company address to the array
    }

    function authorize(address _companyAddress, bool authorized) external onlyFDAAuthority {
        require(!companies[_companyAddress].isRegistered, "License already assigned");

        if (authorized == true) {
            companies[_companyAddress].authorized = true;
            companies[_companyAddress].isRegistered = true;
            companies[_companyAddress].reject = false;
            companies[_companyAddress].assignedBy = msg.sender;
            emit RegistrationApproved(_companyAddress, msg.sender);
        } else {
            companies[_companyAddress].reject = true;
            companies[_companyAddress].assignedBy = msg.sender;
            companies[_companyAddress].isRegistered = false;
        }
    }

    function reject(address _companyAddress, bool rejected) external onlyFDAAuthority {
        require(companies[_companyAddress].isRegistered, "Company not registered");

        if (rejected == true) {
            companies[_companyAddress].authorized = false;
            companies[_companyAddress].isRegistered = false;
            companies[_companyAddress].reject = true;
            companies[_companyAddress].assignedBy = msg.sender;
            emit RegistrationApproved(_companyAddress, msg.sender);
        } else {
            companies[_companyAddress].reject = false;
            companies[_companyAddress].assignedBy = msg.sender;
            companies[_companyAddress].isRegistered = true;
        }
    }

    function submitDocuments(address _companyAddress, string[] memory _ipfsHashes) external onlyContractOwner {
        require(companies[_companyAddress].isRegistered, "Company is not registered");
        require(_ipfsHashes.length > 0, "No IPFS hashes provided");

        for (uint256 i = 0; i < _ipfsHashes.length; i++) {
            require(bytes(_ipfsHashes[i]).length > 0, "Invalid IPFS hash");
            companies[_companyAddress].documentHashes.push(_ipfsHashes[i]); // Append each hash to the array
            emit DocumentsSubmitted(_companyAddress, "Custom Document", _ipfsHashes[i]);
        }
    }

    function assignPersonnel(address _companyAddress, string memory _personnelName, string memory _personnelContact) external onlyFDAAuthority {
        require(companies[_companyAddress].isRegistered, "Company is not registered");
        require(companies[_companyAddress].documentsSubmitted, "Documents not yet submitted"); // Check if documents are submitted
        require(bytes(_personnelName).length > 0 && bytes(_personnelContact).length > 0, "Invalid personnel details");

        companies[_companyAddress].personnel = Personnel(_personnelName, _personnelContact);

        emit PersonnelAssigned(_companyAddress, _personnelName, _personnelContact);
    }

    function getCompanyCount() external view returns (uint256) {
        return companyAddresses.length;
    }

    function getAllCompanyDetails() external view returns (Company[] memory) {
    Company[] memory allCompanyDetails = new Company[](companyAddresses.length);
    for (uint256 i = 0; i < companyAddresses.length; i++) {
        address companyAddress = companyAddresses[i];
        allCompanyDetails[i] = Company({
            name: companies[companyAddress].name,
            productDomain: companies[companyAddress].productDomain,
            ownerName: companies[companyAddress].ownerName,
            location: companies[companyAddress].location,
            contactNumber: companies[companyAddress].contactNumber,
            authorized: companies[companyAddress].authorized,
            isRegistered: companies[companyAddress].isRegistered,
            reject: companies[companyAddress].reject,
            assignedBy: companies[companyAddress].assignedBy,
            personnel: companies[companyAddress].personnel,
            documentsSubmitted: companies[companyAddress].documentsSubmitted,
            registrationTimestamp: companies[companyAddress].registrationTimestamp,
            documentHashes: companies[companyAddress].documentHashes
        });
    }
    return allCompanyDetails;
}

}