```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Creative Commons - On-Chain IP and Licensing Platform
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized platform for registering, licensing, and managing intellectual property (IP) rights,
 *      inspired by Creative Commons but fully on-chain. It allows creators to register their works, define custom license terms,
 *      manage rights, and interact with a community around their creations.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `registerCreator(string memory _name, string memory _ipfsCID)`: Registers a new creator with a profile (name and IPFS CID for details).
 * 2. `updateCreatorProfile(string memory _ipfsCID)`: Allows creators to update their profile information (IPFS CID).
 * 3. `registerWork(string memory _title, string memory _ipfsCID, LicenseType _licenseType, uint256 _initialRoyaltyFee)`: Registers a new creative work with metadata, license type, and initial royalty fee.
 * 4. `updateWorkMetadata(uint256 _workId, string memory _ipfsCID)`: Updates the metadata (IPFS CID) of a registered work.
 * 5. `setWorkLicense(uint256 _workId, LicenseType _licenseType)`: Changes the license type of a registered work.
 * 6. `setRoyaltyFee(uint256 _workId, uint256 _royaltyFee)`: Updates the royalty fee for a work (if applicable under the license).
 * 7. `getWorkDetails(uint256 _workId)`: Retrieves detailed information about a registered work.
 * 8. `getCreatorWorks(address _creatorAddress)`: Retrieves a list of work IDs created by a specific address.
 * 9. `getCreatorProfile(address _creatorAddress)`: Retrieves the profile information of a creator.
 * 10. `getLicenseDetails(LicenseType _licenseType)`: Returns details about a specific LicenseType enum value.
 *
 * **Licensing and Rights Management:**
 * 11. `requestLicense(uint256 _workId, LicenseType _licenseType)`: Allows users to formally request a specific license for a work (can trigger workflows if needed).
 * 12. `grantLicense(uint256 _workId, address _userAddress, LicenseType _licenseType)`:  Allows creators to explicitly grant a specific license to a user (if needed for certain license types).
 * 13. `verifyLicense(uint256 _workId, address _userAddress, LicenseType _licenseType)`: Checks if a user has been granted a specific license for a work.
 * 14. `isLicenseAllowedAction(LicenseType _licenseType, ActionType _action)`:  Checks if a LicenseType allows a specific action (e.g., commercial use, modification).
 *
 * **Community and Interaction:**
 * 15. `donateToCreator(address _creatorAddress) payable`: Allows users to donate to creators they appreciate.
 * 16. `reportCopyrightInfringement(uint256 _workId, string memory _infringementDetails)`: Allows users to report potential copyright infringements.
 * 17. `getWorkLicenseHolders(uint256 _workId)`: Retrieves a list of addresses that have been explicitly granted licenses for a work.
 *
 * **Advanced Features:**
 * 18. `createDerivativeWork(uint256 _originalWorkId, string memory _derivativeTitle, string memory _derivativeIPFSCID, LicenseType _derivativeLicenseType)`: Allows creators to register derivative works, linking back to the original.
 * 19. `transferWorkOwnership(uint256 _workId, address _newOwner)`: Allows creators to transfer ownership of their registered works.
 * 20. `burnWork(uint256 _workId)`: Allows creators to permanently remove their work from the registry (effectively revoking rights).
 * 21. `getTotalRegisteredWorks()`: Returns the total number of works registered on the platform.
 * 22. `getTotalRegisteredCreators()`: Returns the total number of creators registered on the platform.
 */
contract DecentralizedCreativeCommons {

    // Enums for License Types and Actions
    enum LicenseType {
        CC_BY,              // Attribution
        CC_BY_SA,           // Attribution-ShareAlike
        CC_BY_ND,           // Attribution-NoDerivatives
        CC_BY_NC,           // Attribution-NonCommercial
        CC_BY_NC_SA,        // Attribution-NonCommercial-ShareAlike
        CC_BY_NC_ND,        // Attribution-NonCommercial-NoDerivatives
        CUSTOM_LICENSE      // For licenses defined outside of the predefined set
    }

    enum ActionType {
        USE,
        DISTRIBUTE,
        MODIFY,
        COMMERCIALIZE
    }

    // Structs for data organization
    struct CreatorProfile {
        string name;            // Creator's Name
        string ipfsCID;         // IPFS CID for creator details (website, social media, etc.)
        uint256 registrationTimestamp;
    }

    struct Work {
        address creator;        // Address of the creator
        string title;           // Title of the work
        string ipfsCID;         // IPFS CID for work metadata (description, actual content link, etc.)
        LicenseType licenseType; // License type applied to the work
        uint256 royaltyFee;     // Royalty fee (if applicable, in wei)
        uint256 registrationTimestamp;
        uint256 derivativeOfWorkId; // ID of the original work if this is a derivative, 0 if not
    }

    // State variables
    mapping(address => CreatorProfile) public creatorProfiles;
    mapping(uint256 => Work) public worksRegistry;
    mapping(uint256 => mapping(address => LicenseType)) public workLicenseGrants; // Explicitly granted licenses
    uint256 public workCounter;
    uint256 public creatorCounter;
    address public owner;

    // Events
    event CreatorRegistered(address creatorAddress, string name, string ipfsCID, uint256 timestamp);
    event CreatorProfileUpdated(address creatorAddress, string ipfsCID, uint256 timestamp);
    event WorkRegistered(uint256 workId, address creatorAddress, string title, string ipfsCID, LicenseType licenseType, uint256 royaltyFee, uint256 timestamp);
    event WorkMetadataUpdated(uint256 workId, string ipfsCID, uint256 timestamp);
    event WorkLicenseSet(uint256 workId, LicenseType licenseType, uint256 timestamp);
    event RoyaltyFeeSet(uint256 workId, uint256 royaltyFee, uint256 timestamp);
    event LicenseRequested(uint256 workId, address userAddress, LicenseType licenseType, uint256 timestamp);
    event LicenseGranted(uint256 workId, address userAddress, LicenseType licenseType, uint256 timestamp);
    event DonationReceived(address creatorAddress, address donorAddress, uint256 amount, uint256 timestamp);
    event CopyrightInfringementReported(uint256 workId, address reporterAddress, string details, uint256 timestamp);
    event DerivativeWorkCreated(uint256 derivativeWorkId, uint256 originalWorkId, address creatorAddress, string title, string ipfsCID, LicenseType licenseType, uint256 timestamp);
    event WorkOwnershipTransferred(uint256 workId, address oldOwner, address newOwner, uint256 timestamp);
    event WorkBurned(uint256 workId, address burnerAddress, uint256 timestamp);

    // Modifiers
    modifier onlyCreator(uint256 _workId) {
        require(worksRegistry[_workId].creator == msg.sender, "You are not the creator of this work.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }


    constructor() {
        owner = msg.sender;
        workCounter = 0;
        creatorCounter = 0;
    }

    // 1. Register Creator
    function registerCreator(string memory _name, string memory _ipfsCID) public {
        require(creatorProfiles[msg.sender].registrationTimestamp == 0, "Creator already registered.");
        creatorCounter++;
        creatorProfiles[msg.sender] = CreatorProfile({
            name: _name,
            ipfsCID: _ipfsCID,
            registrationTimestamp: block.timestamp
        });
        emit CreatorRegistered(msg.sender, _name, _ipfsCID, block.timestamp);
    }

    // 2. Update Creator Profile
    function updateCreatorProfile(string memory _ipfsCID) public {
        require(creatorProfiles[msg.sender].registrationTimestamp != 0, "Creator not registered.");
        creatorProfiles[msg.sender].ipfsCID = _ipfsCID;
        emit CreatorProfileUpdated(msg.sender, _ipfsCID, block.timestamp);
    }

    // 3. Register Work
    function registerWork(
        string memory _title,
        string memory _ipfsCID,
        LicenseType _licenseType,
        uint256 _initialRoyaltyFee
    ) public {
        require(creatorProfiles[msg.sender].registrationTimestamp != 0, "You must register as a creator first.");
        workCounter++;
        worksRegistry[workCounter] = Work({
            creator: msg.sender,
            title: _title,
            ipfsCID: _ipfsCID,
            licenseType: _licenseType,
            royaltyFee: _initialRoyaltyFee,
            registrationTimestamp: block.timestamp,
            derivativeOfWorkId: 0 // Not a derivative work
        });
        emit WorkRegistered(workCounter, msg.sender, _title, _ipfsCID, _licenseType, _initialRoyaltyFee, block.timestamp);
    }

    // 4. Update Work Metadata
    function updateWorkMetadata(uint256 _workId, string memory _ipfsCID) public onlyCreator(_workId) {
        worksRegistry[_workId].ipfsCID = _ipfsCID;
        emit WorkMetadataUpdated(_workId, _ipfsCID, block.timestamp);
    }

    // 5. Set Work License
    function setWorkLicense(uint256 _workId, LicenseType _licenseType) public onlyCreator(_workId) {
        worksRegistry[_workId].licenseType = _licenseType;
        emit WorkLicenseSet(_workId, _licenseType, block.timestamp);
    }

    // 6. Set Royalty Fee
    function setRoyaltyFee(uint256 _workId, uint256 _royaltyFee) public onlyCreator(_workId) {
        worksRegistry[_workId].royaltyFee = _royaltyFee;
        emit RoyaltyFeeSet(_workId, _royaltyFee, block.timestamp);
    }

    // 7. Get Work Details
    function getWorkDetails(uint256 _workId) public view returns (Work memory) {
        require(worksRegistry[_workId].registrationTimestamp != 0, "Work not registered.");
        return worksRegistry[_workId];
    }

    // 8. Get Creator Works
    function getCreatorWorks(address _creatorAddress) public view returns (uint256[] memory) {
        require(creatorProfiles[_creatorAddress].registrationTimestamp != 0, "Creator not registered.");
        uint256[] memory workIds = new uint256[](workCounter); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= workCounter; i++) {
            if (worksRegistry[i].creator == _creatorAddress) {
                workIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of works
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++) {
            result[i] = workIds[i];
        }
        return result;
    }

    // 9. Get Creator Profile
    function getCreatorProfile(address _creatorAddress) public view returns (CreatorProfile memory) {
        require(creatorProfiles[_creatorAddress].registrationTimestamp != 0, "Creator not registered.");
        return creatorProfiles[_creatorAddress];
    }

    // 10. Get License Details (Illustrative, can be expanded)
    function getLicenseDetails(LicenseType _licenseType) public pure returns (string memory, string memory) {
        if (_licenseType == LicenseType.CC_BY) {
            return ("CC BY", "Attribution");
        } else if (_licenseType == LicenseType.CC_BY_SA) {
            return ("CC BY-SA", "Attribution-ShareAlike");
        } else if (_licenseType == LicenseType.CC_BY_ND) {
            return ("CC BY-ND", "Attribution-NoDerivatives");
        } else if (_licenseType == LicenseType.CC_BY_NC) {
            return ("CC BY-NC", "Attribution-NonCommercial");
        } else if (_licenseType == LicenseType.CC_BY_NC_SA) {
            return ("CC BY-NC-SA", "Attribution-NonCommercial-ShareAlike");
        } else if (_licenseType == LicenseType.CC_BY_NC_ND) {
            return ("CC BY-NC-ND", "Attribution-NonCommercial-NoDerivatives");
        } else if (_licenseType == LicenseType.CUSTOM_LICENSE) {
            return ("Custom License", "License terms defined externally or off-chain.");
        } else {
            return ("Unknown License", "License type not recognized.");
        }
    }

    // 11. Request License (Simple Request - can be expanded for workflows)
    function requestLicense(uint256 _workId, LicenseType _licenseType) public {
        require(worksRegistry[_workId].registrationTimestamp != 0, "Work not registered.");
        emit LicenseRequested(_workId, msg.sender, _licenseType, block.timestamp);
        // In a more complex system, this might trigger notifications or on-chain workflows.
    }

    // 12. Grant License (Explicit Grant - useful for specific permissions)
    function grantLicense(uint256 _workId, address _userAddress, LicenseType _licenseType) public onlyCreator(_workId) {
        workLicenseGrants[_workId][_userAddress] = _licenseType;
        emit LicenseGranted(_workId, _userAddress, _licenseType, _licenseType, block.timestamp);
    }

    // 13. Verify License (Check if explicitly granted)
    function verifyLicense(uint256 _workId, address _userAddress, LicenseType _licenseType) public view returns (bool) {
        return workLicenseGrants[_workId][_userAddress] == _licenseType;
    }

    // 14. Is License Allowed Action (Simplified License Action Check)
    function isLicenseAllowedAction(LicenseType _licenseType, ActionType _action) public pure returns (bool) {
        if (_licenseType == LicenseType.CC_BY) {
            return true; // CC BY allows all actions (Use, Distribute, Modify, Commercialize)
        } else if (_licenseType == LicenseType.CC_BY_SA || _licenseType == LicenseType.CC_BY_NC_SA) {
            return true; // ShareAlike still generally allows most actions, but with conditions. Simplified here.
        } else if (_licenseType == LicenseType.CC_BY_ND || _licenseType == LicenseType.CC_BY_NC_ND) {
            return _action != ActionType.MODIFY; // NoDerivatives disallows modification.
        } else if (_licenseType == LicenseType.CC_BY_NC || _licenseType == LicenseType.CC_BY_NC_SA || _licenseType == LicenseType.CC_BY_NC_ND) {
            return _action != ActionType.COMMERCIALIZE; // NonCommercial disallows commercialization.
        } else if (_licenseType == LicenseType.CUSTOM_LICENSE) {
            return false; // Default to false for custom licenses, needs more logic.
        }
        return false; // Default deny for unknown license types
    }

    // 15. Donate to Creator
    function donateToCreator(address _creatorAddress) payable public {
        require(creatorProfiles[_creatorAddress].registrationTimestamp != 0, "Creator not registered.");
        (bool success, ) = _creatorAddress.call{value: msg.value}("");
        require(success, "Donation transfer failed.");
        emit DonationReceived(_creatorAddress, msg.sender, msg.value, block.timestamp);
    }

    // 16. Report Copyright Infringement
    function reportCopyrightInfringement(uint256 _workId, string memory _infringementDetails) public {
        require(worksRegistry[_workId].registrationTimestamp != 0, "Work not registered.");
        emit CopyrightInfringementReported(_workId, msg.sender, _infringementDetails, block.timestamp);
        // In a real application, this would likely trigger a more complex dispute resolution process.
    }

    // 17. Get Work License Holders (Explicitly Granted)
    function getWorkLicenseHolders(uint256 _workId) public view returns (address[] memory, LicenseType[] memory) {
        require(worksRegistry[_workId].registrationTimestamp != 0, "Work not registered.");
        address[] memory holders = new address[](workCounter); // Max size, could be optimized
        LicenseType[] memory licenses = new LicenseType[](workCounter);
        uint256 count = 0;
        for (uint256 i = 0; i < workCounter; i++) { // Iterate through possible user addresses (not efficient in practice)
            if (workLicenseGrants[_workId][address(uint160(uint256(i)))] != LicenseType.CUSTOM_LICENSE) { // Basic check, needs better iteration
                if (workLicenseGrants[_workId][address(uint160(uint256(i)))] != LicenseType(0)) { // Assuming LicenseType(0) is not used as a granted license, adjust as needed.
                    holders[count] = address(uint160(uint256(i)));
                    licenses[count] = workLicenseGrants[_workId][address(uint160(uint256(i)))];
                    count++;
                }
            }
        }
        // Resize arrays to actual count
        address[] memory resultHolders = new address[](count);
        LicenseType[] memory resultLicenses = new LicenseType[](count);
        for(uint256 i = 0; i < count; i++) {
            resultHolders[i] = holders[i];
            resultLicenses[i] = licenses[i];
        }
        return (resultHolders, resultLicenses);
    }


    // 18. Create Derivative Work
    function createDerivativeWork(
        uint256 _originalWorkId,
        string memory _derivativeTitle,
        string memory _derivativeIPFSCID,
        LicenseType _derivativeLicenseType
    ) public onlyCreator(_originalWorkId) { // Original creator can register derivatives
        require(worksRegistry[_originalWorkId].registrationTimestamp != 0, "Original work not registered.");
        workCounter++;
        worksRegistry[workCounter] = Work({
            creator: msg.sender,
            title: _derivativeTitle,
            ipfsCID: _derivativeIPFSCID,
            licenseType: _derivativeLicenseType,
            royaltyFee: 0, // Derivative works might have different royalty rules
            registrationTimestamp: block.timestamp,
            derivativeOfWorkId: _originalWorkId
        });
        emit DerivativeWorkCreated(workCounter, _originalWorkId, msg.sender, _derivativeTitle, _derivativeIPFSCID, _derivativeLicenseType, block.timestamp);
    }

    // 19. Transfer Work Ownership
    function transferWorkOwnership(uint256 _workId, address _newOwner) public onlyCreator(_workId) {
        address oldOwner = worksRegistry[_workId].creator;
        worksRegistry[_workId].creator = _newOwner;
        emit WorkOwnershipTransferred(_workId, oldOwner, _newOwner, block.timestamp);
    }

    // 20. Burn Work (Remove from Registry - Revoke Rights)
    function burnWork(uint256 _workId) public onlyCreator(_workId) {
        require(worksRegistry[_workId].registrationTimestamp != 0, "Work not registered.");
        delete worksRegistry[_workId]; // Effectively removes the work
        emit WorkBurned(_workId, msg.sender, block.timestamp);
    }

    // 21. Get Total Registered Works
    function getTotalRegisteredWorks() public view returns (uint256) {
        return workCounter;
    }

    // 22. Get Total Registered Creators
    function getTotalRegisteredCreators() public view returns (uint256) {
        return creatorCounter;
    }
}
```