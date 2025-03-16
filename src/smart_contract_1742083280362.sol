```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Organization for Creative Content Licensing (DAOCCL)
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a DAO that manages creative content licensing, incorporating advanced concepts like dynamic pricing,
 *      reputation-based access, decentralized curation, and community-driven evolution.
 *
 * Outline and Function Summary:
 *
 * 1.  **Content Registration & Management:**
 *     - `registerContent(string memory _contentURI, string memory _metadataURI, uint256[] memory _initialLicenseTypes)`: Allows creators to register their content with metadata and initial license types.
 *     - `updateContentMetadata(uint256 _contentId, string memory _metadataURI)`: Updates the metadata URI of registered content.
 *     - `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a specific content item.
 *     - `setContentAvailability(uint256 _contentId, bool _isAvailable)`: Toggles the availability of content for licensing.
 *     - `getContentCreator(uint256 _contentId)`: Retrieves the creator address of a content item.
 *
 * 2.  **License Type Management (DAO Governed):**
 *     - `createLicenseType(string memory _licenseName, uint256 _basePrice, uint256 _durationDays)`: Proposes and creates a new license type (DAO approval required).
 *     - `updateLicenseTypePrice(uint256 _licenseTypeId, uint256 _newPrice)`: Proposes and updates the price of an existing license type (DAO approval required).
 *     - `updateLicenseTypeDuration(uint256 _licenseTypeId, uint256 _newDurationDays)`: Proposes and updates the duration of an existing license type (DAO approval required).
 *     - `getLicenseTypeDetails(uint256 _licenseTypeId)`: Retrieves details of a specific license type.
 *     - `getAllLicenseTypes()`: Returns a list of all available license type IDs.
 *
 * 3.  **Dynamic Pricing & Demand-Based Adjustments:**
 *     - `adjustLicensePriceBasedOnDemand(uint256 _licenseTypeId)`: Dynamically adjusts license price based on recent purchase volume (internal function triggered by purchases).
 *     - `setDemandSensitivity(uint256 _newSensitivity)`: DAO-governed function to adjust the sensitivity of price adjustments to demand changes.
 *
 * 4.  **Reputation & Tiered Access:**
 *     - `increaseUserReputation(address _user, uint256 _amount)`: DAO-governed function to increase user reputation.
 *     - `decreaseUserReputation(address _user, uint256 _amount)`: DAO-governed function to decrease user reputation.
 *     - `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 *     - `setReputationThresholdForLicense(uint256 _licenseTypeId, uint256 _threshold)`: DAO-governed function to set a reputation threshold required to purchase a specific license type.
 *     - `checkUserAccessForLicense(address _user, uint256 _licenseTypeId)`: Checks if a user meets the reputation threshold for a license.
 *
 * 5.  **Decentralized Curation & Content Discovery (Basic):**
 *     - `upvoteContent(uint256 _contentId)`: Allows users to upvote content (contributes to content discovery ranking - basic example).
 *     - `downvoteContent(uint256 _contentId)`: Allows users to downvote content (affects content discovery ranking - basic example).
 *     - `getContentRating(uint256 _contentId)`: Retrieves the net rating score (upvotes - downvotes) of content.
 *     - `getTrendingContent(uint256 _count)`: Retrieves a list of trending content IDs based on rating (basic example).
 *
 * 6.  **Licensing & Usage Tracking:**
 *     - `purchaseContentLicense(uint256 _contentId, uint256 _licenseTypeId)`: Allows users to purchase a license for content.
 *     - `checkLicenseValidity(uint256 _licenseId)`: Checks if a license is still valid based on its duration.
 *     - `getLicenseDetailsById(uint256 _licenseId)`: Retrieves details of a specific license by its ID.
 *     - `getLicensesForUser(address _user)`: Retrieves a list of license IDs purchased by a user.
 *     - `getLicensesForContent(uint256 _contentId)`: Retrieves a list of license IDs for a specific content item.
 *
 * 7.  **DAO Governance & Parameters:**
 *     - `proposeDAOParameterChange(string memory _parameterName, uint256 _newValue)`: Allows community members to propose changes to DAO parameters (e.g., demand sensitivity, curation weights).
 *     - `voteOnDAOProposal(uint256 _proposalId, bool _vote)`: Allows DAO members to vote on DAO parameter change proposals.
 *     - `executeDAOProposal(uint256 _proposalId)`: Executes a DAO proposal if it passes the voting threshold.
 *     - `getDAOParameter(string memory _parameterName)`: Retrieves the current value of a DAO parameter.
 *     - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a DAO proposal.
 *
 * 8.  **Emergency & Admin Functions (DAO Controlled):**
 *     - `pauseContract()`: DAO-governed function to pause the contract in case of emergency.
 *     - `unpauseContract()`: DAO-governed function to unpause the contract.
 *     - `withdrawPlatformFees()`: DAO-governed function to withdraw accumulated platform fees.
 *
 */

contract DAOCCL {
    // -------- State Variables --------

    // Content Management
    uint256 public contentCount;
    mapping(uint256 => Content) public contentRegistry;
    mapping(uint256 => address) public contentCreators;
    mapping(uint256 => bool) public contentAvailability;

    struct Content {
        string contentURI;      // URI pointing to the actual content
        string metadataURI;     // URI pointing to content metadata
        uint256[] licenseTypes; // Array of License Type IDs valid for this content
        uint256 upvotes;
        uint256 downvotes;
    }

    // License Type Management
    uint256 public licenseTypeCount;
    mapping(uint256 => LicenseType) public licenseTypes;
    mapping(uint256 => uint256) public licenseTypeDemand; // Track demand for dynamic pricing

    struct LicenseType {
        string name;
        uint256 basePrice;
        uint256 durationDays;
        uint256 reputationThreshold;
        uint256 currentPrice; // Dynamic price, starts as basePrice
    }

    // License Management
    uint256 public licenseCount;
    mapping(uint256 => License) public licenses;
    mapping(address => uint256[]) public userLicenses; // Licenses purchased by user
    mapping(uint256 => uint256[]) public contentLicenses; // Licenses for specific content

    struct License {
        uint256 contentId;
        uint256 licenseTypeId;
        address licensee;
        uint256 purchaseTimestamp;
        uint256 expiryTimestamp;
    }

    // User Reputation
    mapping(address => uint256) public userReputation;

    // DAO Governance Parameters (Example - Expand as needed)
    mapping(string => uint256) public daoParameters; // Store various DAO-controlled parameters
    uint256 public demandSensitivity; // How much demand affects price adjustment
    uint256 public curationWeightUpvote; // Weight of upvotes in trending algorithm
    uint256 public curationWeightDownvote; // Weight of downvotes in trending algorithm

    // DAO Proposals
    uint256 public proposalCount;
    mapping(uint256 => DAOProposal) public daoProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Track votes for each proposal

    struct DAOProposal {
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    uint256 public proposalVotingDurationDays = 7; // Example: 7 days for voting period
    uint256 public proposalQuorumPercentage = 50;   // Example: 50% quorum required for proposal to pass

    // Platform Fees & Treasury
    uint256 public platformFeePercentage = 5; // Example: 5% platform fee on license purchases
    address payable public daoTreasury;

    // Contract State
    bool public paused = false;
    address public daoGovernor; // Address of the DAO Governor/Multisig

    // -------- Events --------
    event ContentRegistered(uint256 contentId, address creator, string contentURI, string metadataURI);
    event ContentMetadataUpdated(uint256 contentId, string metadataURI);
    event ContentAvailabilityChanged(uint256 contentId, bool isAvailable);
    event LicenseTypeCreated(uint256 licenseTypeId, string name, uint256 basePrice, uint256 durationDays);
    event LicenseTypePriceUpdated(uint256 licenseTypeId, uint256 newPrice);
    event LicenseTypeDurationUpdated(uint256 licenseTypeId, uint256 newDurationDays);
    event LicensePurchased(uint256 licenseId, uint256 contentId, uint256 licenseTypeId, address licensee);
    event UserReputationIncreased(address user, uint256 amount);
    event UserReputationDecreased(address user, uint256 amount);
    event ContentUpvoted(uint256 contentId, address user);
    event ContentDownvoted(uint256 contentId, address user);
    event DAOParameterProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event DAOProposalVoted(uint256 proposalId, address voter, bool vote);
    event DAOProposalExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeesWithdrawn(uint256 amount, address treasury);


    // -------- Modifiers --------
    modifier onlyDAOGovernor() {
        require(msg.sender == daoGovernor, "Only DAO Governor can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // -------- Constructor --------
    constructor(address payable _daoTreasury) payable {
        daoGovernor = msg.sender; // Initially, the deployer is the DAO Governor
        daoTreasury = _daoTreasury;
        demandSensitivity = 10; // Example default sensitivity
        curationWeightUpvote = 1;
        curationWeightDownvote = 1;

        // Initialize some default DAO Parameters - Example
        daoParameters["defaultPlatformFeePercentage"] = 5;
        daoParameters["defaultProposalVotingDurationDays"] = 7;
        daoParameters["defaultProposalQuorumPercentage"] = 50;
    }


    // -------- 1. Content Registration & Management Functions --------

    function registerContent(string memory _contentURI, string memory _metadataURI, uint256[] memory _initialLicenseTypes) external whenNotPaused {
        contentCount++;
        uint256 contentId = contentCount;
        contentRegistry[contentId] = Content({
            contentURI: _contentURI,
            metadataURI: _metadataURI,
            licenseTypes: _initialLicenseTypes,
            upvotes: 0,
            downvotes: 0
        });
        contentCreators[contentId] = msg.sender;
        contentAvailability[contentId] = true;
        emit ContentRegistered(contentId, msg.sender, _contentURI, _metadataURI);
    }

    function updateContentMetadata(uint256 _contentId, string memory _metadataURI) external whenNotPaused {
        require(contentCreators[_contentId] == msg.sender, "Only content creator can update metadata");
        require(contentRegistry[_contentId].contentURI.length > 0, "Content not registered");
        contentRegistry[_contentId].metadataURI = _metadataURI;
        emit ContentMetadataUpdated(_contentId, _metadataURI);
    }

    function getContentDetails(uint256 _contentId) external view returns (string memory contentURI, string memory metadataURI, uint256[] memory licenseTypes, address creator, bool isAvailable, uint256 upvotes, uint256 downvotes) {
        require(contentRegistry[_contentId].contentURI.length > 0, "Content not registered");
        Content storage content = contentRegistry[_contentId];
        return (content.contentURI, content.metadataURI, content.licenseTypes, contentCreators[_contentId], contentAvailability[_contentId], content.upvotes, content.downvotes);
    }

    function setContentAvailability(uint256 _contentId, bool _isAvailable) external whenNotPaused {
        require(contentCreators[_contentId] == msg.sender, "Only content creator can set availability");
        require(contentRegistry[_contentId].contentURI.length > 0, "Content not registered");
        contentAvailability[_contentId] = _isAvailable;
        emit ContentAvailabilityChanged(_contentId, _isAvailable);
    }

    function getContentCreator(uint256 _contentId) external view returns (address) {
        require(contentRegistry[_contentId].contentURI.length > 0, "Content not registered");
        return contentCreators[_contentId];
    }


    // -------- 2. License Type Management (DAO Governed) Functions --------

    function createLicenseType(string memory _licenseName, uint256 _basePrice, uint256 _durationDays) external onlyDAOGovernor whenNotPaused {
        licenseTypeCount++;
        uint256 licenseTypeId = licenseTypeCount;
        licenseTypes[licenseTypeId] = LicenseType({
            name: _licenseName,
            basePrice: _basePrice,
            durationDays: _durationDays,
            reputationThreshold: 0, // Default no reputation threshold
            currentPrice: _basePrice
        });
        licenseTypeDemand[licenseTypeId] = 0; // Initialize demand
        emit LicenseTypeCreated(licenseTypeId, _licenseName, _basePrice, _durationDays);
    }

    function updateLicenseTypePrice(uint256 _licenseTypeId, uint256 _newPrice) external onlyDAOGovernor whenNotPaused {
        require(licenseTypes[_licenseTypeId].name.length > 0, "License type does not exist");
        licenseTypes[_licenseTypeId].basePrice = _newPrice;
        licenseTypes[_licenseTypeId].currentPrice = _newPrice; // Update current price as well
        emit LicenseTypePriceUpdated(_licenseTypeId, _newPrice);
    }

    function updateLicenseTypeDuration(uint256 _licenseTypeId, uint256 _newDurationDays) external onlyDAOGovernor whenNotPaused {
        require(licenseTypes[_licenseTypeId].name.length > 0, "License type does not exist");
        licenseTypes[_licenseTypeId].durationDays = _newDurationDays;
        emit LicenseTypeDurationUpdated(_licenseTypeId, _newDurationDays);
    }

    function getLicenseTypeDetails(uint256 _licenseTypeId) external view returns (string memory name, uint256 basePrice, uint256 durationDays, uint256 reputationThreshold, uint256 currentPrice) {
        require(licenseTypes[_licenseTypeId].name.length > 0, "License type does not exist");
        LicenseType storage licenseType = licenseTypes[_licenseTypeId];
        return (licenseType.name, licenseType.basePrice, licenseType.durationDays, licenseType.reputationThreshold, licenseType.currentPrice);
    }

    function getAllLicenseTypes() external view returns (uint256[] memory) {
        uint256[] memory allLicenseTypeIds = new uint256[](licenseTypeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= licenseTypeCount; i++) {
            if (licenseTypes[i].name.length > 0) { // Check if license type exists (in case of deletion or future updates)
                allLicenseTypeIds[index] = i;
                index++;
            }
        }
        // Resize the array to remove empty slots if any license types were "deleted" or not created sequentially.
        assembly {
            mstore(allLicenseTypeIds, index) // Update the array length in memory
        }
        return allLicenseTypeIds;
    }


    // -------- 3. Dynamic Pricing & Demand-Based Adjustments Functions --------

    function adjustLicensePriceBasedOnDemand(uint256 _licenseTypeId) internal {
        uint256 currentDemand = licenseTypeDemand[_licenseTypeId];
        uint256 basePrice = licenseTypes[_licenseTypeId].basePrice;
        uint256 priceAdjustment = (currentDemand * demandSensitivity) / 100; // Example adjustment formula
        uint256 newPrice = basePrice + priceAdjustment;
        licenseTypes[_licenseTypeId].currentPrice = newPrice > 0 ? newPrice : 1; // Ensure price is never zero or negative
        licenseTypeDemand[_licenseTypeId] = 0; // Reset demand counter after adjustment
    }

    function setDemandSensitivity(uint256 _newSensitivity) external onlyDAOGovernor whenNotPaused {
        demandSensitivity = _newSensitivity;
    }


    // -------- 4. Reputation & Tiered Access Functions --------

    function increaseUserReputation(address _user, uint256 _amount) external onlyDAOGovernor whenNotPaused {
        userReputation[_user] += _amount;
        emit UserReputationIncreased(_user, _amount);
    }

    function decreaseUserReputation(address _user, uint256 _amount) external onlyDAOGovernor whenNotPaused {
        require(userReputation[_user] >= _amount, "Reputation cannot be negative");
        userReputation[_user] -= _amount;
        emit UserReputationDecreased(_user, _amount);
    }

    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    function setReputationThresholdForLicense(uint256 _licenseTypeId, uint256 _threshold) external onlyDAOGovernor whenNotPaused {
        require(licenseTypes[_licenseTypeId].name.length > 0, "License type does not exist");
        licenseTypes[_licenseTypeId].reputationThreshold = _threshold;
    }

    function checkUserAccessForLicense(address _user, uint256 _licenseTypeId) public view returns (bool) {
        return userReputation[_user] >= licenseTypes[_licenseTypeId].reputationThreshold;
    }


    // -------- 5. Decentralized Curation & Content Discovery (Basic) Functions --------

    function upvoteContent(uint256 _contentId) external whenNotPaused {
        require(contentRegistry[_contentId].contentURI.length > 0, "Content not registered");
        contentRegistry[_contentId].upvotes += curationWeightUpvote;
        emit ContentUpvoted(_contentId, msg.sender);
    }

    function downvoteContent(uint256 _contentId) external whenNotPaused {
        require(contentRegistry[_contentId].contentURI.length > 0, "Content not registered");
        contentRegistry[_contentId].downvotes += curationWeightDownvote;
        emit ContentDownvoted(_contentId, msg.sender);
    }

    function getContentRating(uint256 _contentId) external view returns (int256) {
        return int256(contentRegistry[_contentId].upvotes) - int256(contentRegistry[_contentId].downvotes);
    }

    function getTrendingContent(uint256 _count) external view returns (uint256[] memory) {
        uint256[] memory trendingContent = new uint256[](_count);
        uint256[] memory contentIds = new uint256[](contentCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentRegistry[i].contentURI.length > 0 && contentAvailability[i]) {
                contentIds[index] = i;
                index++;
            }
        }
        // Basic sorting by rating (descending). For production, consider more robust ranking algorithms.
        for (uint256 i = 0; i < index; i++) {
            for (uint256 j = i + 1; j < index; j++) {
                if (getContentRating(contentIds[i]) < getContentRating(contentIds[j])) {
                    uint256 temp = contentIds[i];
                    contentIds[i] = contentIds[j];
                    contentIds[j] = temp;
                }
            }
        }

        uint256 count = _count > index ? index : _count; // Limit count to available content
        for (uint256 i = 0; i < count; i++) {
            trendingContent[i] = contentIds[i];
        }
        return trendingContent;
    }


    // -------- 6. Licensing & Usage Tracking Functions --------

    function purchaseContentLicense(uint256 _contentId, uint256 _licenseTypeId) external payable whenNotPaused {
        require(contentRegistry[_contentId].contentURI.length > 0 && contentAvailability[_contentId], "Content not available or not registered");
        require(licenseTypes[_licenseTypeId].name.length > 0, "License type does not exist");
        require(checkUserAccessForLicense(msg.sender, _licenseTypeId), "User reputation too low for this license type");

        uint256 licensePrice = licenseTypes[_licenseTypeId].currentPrice;
        require(msg.value >= licensePrice, "Insufficient payment for license");

        licenseCount++;
        uint256 licenseId = licenseCount;
        uint256 purchaseTimestamp = block.timestamp;
        uint256 expiryTimestamp = purchaseTimestamp + (licenseTypes[_licenseTypeId].durationDays * 1 days);

        licenses[licenseId] = License({
            contentId: _contentId,
            licenseTypeId: _licenseTypeId,
            licensee: msg.sender,
            purchaseTimestamp: purchaseTimestamp,
            expiryTimestamp: expiryTimestamp
        });
        userLicenses[msg.sender].push(licenseId);
        contentLicenses[_contentId].push(licenseId);

        licenseTypeDemand[_licenseTypeId]++; // Increase demand for dynamic pricing

        // Transfer funds - Creator gets (100 - platformFeePercentage)%, Platform gets platformFeePercentage%
        uint256 platformFeeAmount = (licensePrice * platformFeePercentage) / 100;
        uint256 creatorShare = licensePrice - platformFeeAmount;

        payable(contentCreators[_contentId]).transfer(creatorShare);
        daoTreasury.transfer(platformFeeAmount);

        adjustLicensePriceBasedOnDemand(_licenseTypeId); // Dynamic price adjustment after purchase

        emit LicensePurchased(licenseId, _contentId, _licenseTypeId, msg.sender);

        // Return any excess payment
        if (msg.value > licensePrice) {
            payable(msg.sender).transfer(msg.value - licensePrice);
        }
    }

    function checkLicenseValidity(uint256 _licenseId) external view returns (bool) {
        require(licenses[_licenseId].licensee != address(0), "License does not exist");
        return block.timestamp <= licenses[_licenseId].expiryTimestamp;
    }

    function getLicenseDetailsById(uint256 _licenseId) external view returns (uint256 contentId, uint256 licenseTypeId, address licensee, uint256 purchaseTimestamp, uint256 expiryTimestamp) {
        require(licenses[_licenseId].licensee != address(0), "License does not exist");
        License storage license = licenses[_licenseId];
        return (license.contentId, license.licenseTypeId, license.licensee, license.purchaseTimestamp, license.expiryTimestamp);
    }

    function getLicensesForUser(address _user) external view returns (uint256[] memory) {
        return userLicenses[_user];
    }

    function getLicensesForContent(uint256 _contentId) external view returns (uint256[] memory) {
        return contentLicenses[_contentId];
    }


    // -------- 7. DAO Governance & Parameters Functions --------

    function proposeDAOParameterChange(string memory _parameterName, uint256 _newValue) external whenNotPaused {
        proposalCount++;
        uint256 proposalId = proposalCount;
        daoProposals[proposalId] = DAOProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + (proposalVotingDurationDays * 1 days),
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit DAOParameterProposed(proposalId, _parameterName, _newValue);
    }

    function voteOnDAOProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(!daoProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp < daoProposals[_proposalId].endTime, "Voting period ended");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            daoProposals[_proposalId].yesVotes++;
        } else {
            daoProposals[_proposalId].noVotes++;
        }
        emit DAOProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeDAOProposal(uint256 _proposalId) external onlyDAOGovernor whenNotPaused {
        require(!daoProposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp >= daoProposals[_proposalId].endTime, "Voting period not ended");

        uint256 totalVotes = daoProposals[_proposalId].yesVotes + daoProposals[_proposalId].noVotes;
        uint256 quorum = (totalVotes * 100) / address(this).balance; // Simple quorum based on total ETH balance as example - **Replace with actual DAO member counting logic in real implementation**
        require(quorum >= proposalQuorumPercentage, "Quorum not met");
        require(daoProposals[_proposalId].yesVotes > daoProposals[_proposalId].noVotes, "Proposal failed to pass");

        string memory parameterName = daoProposals[_proposalId].parameterName;
        uint256 newValue = daoProposals[_proposalId].newValue;

        daoParameters[parameterName] = newValue; // Update the DAO parameter

        daoProposals[_proposalId].executed = true;
        emit DAOProposalExecuted(_proposalId, parameterName, newValue);
    }

    function getDAOParameter(string memory _parameterName) external view returns (uint256) {
        return daoParameters[_parameterName];
    }

    function getProposalDetails(uint256 _proposalId) external view returns (string memory parameterName, uint256 newValue, uint256 startTime, uint256 endTime, uint256 yesVotes, uint256 noVotes, bool executed) {
        DAOProposal storage proposal = daoProposals[_proposalId];
        return (proposal.parameterName, proposal.newValue, proposal.startTime, proposal.endTime, proposal.yesVotes, proposal.noVotes, proposal.executed);
    }


    // -------- 8. Emergency & Admin Functions (DAO Controlled) Functions --------

    function pauseContract() external onlyDAOGovernor whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyDAOGovernor whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    function withdrawPlatformFees() external onlyDAOGovernor whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Exclude value sent with this transaction
        require(contractBalance > 0, "No platform fees to withdraw");
        daoTreasury.transfer(contractBalance);
        emit PlatformFeesWithdrawn(contractBalance, daoTreasury);
    }

    // Fallback function to receive ETH in case of direct transfers (optional, for receiving platform fees passively)
    receive() external payable {}
}
```