```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform that allows creators to publish dynamic content
 *      (e.g., articles, stories, interactive games, evolving art) as NFTs and users to subscribe
 *      for access. This platform incorporates advanced concepts like dynamic NFTs, content evolution,
 *      on-chain reputation, and decentralized governance features.
 *
 * **Outline and Function Summary:**
 *
 * **1. Content Creation and NFT Minting:**
 *    - `createContentNFT(string _initialContentHash, string _metadataURI, uint256 _subscriptionFee)`: Allows creators to mint a new Dynamic Content NFT.
 *    - `updateContent(uint256 _contentId, string _newContentHash)`: Allows the content creator to update the content associated with an NFT.
 *    - `setContentMetadataURI(uint256 _contentId, string _newMetadataURI)`: Allows the content creator to update the metadata URI of an NFT.
 *
 * **2. Subscription and Access Control:**
 *    - `subscribeToContent(uint256 _contentId)`: Allows users to subscribe to a content NFT by paying the subscription fee.
 *    - `unsubscribeFromContent(uint256 _contentId)`: Allows users to unsubscribe from content.
 *    - `checkSubscriptionStatus(uint256 _contentId, address _user)`: Checks if a user is subscribed to a specific content NFT.
 *    - `getContentSubscriptionFee(uint256 _contentId)`: Retrieves the subscription fee for a content NFT.
 *
 * **3. Content Evolution and Versioning:**
 *    - `getContentVersion(uint256 _contentId)`: Retrieves the current version number of the content.
 *    - `getContentHashForVersion(uint256 _contentId, uint256 _version)`: Retrieves the content hash for a specific version of the content.
 *    - `getAllContentVersions(uint256 _contentId)`: Returns an array of all content hashes and timestamps for each version.
 *
 * **4. On-Chain Reputation System (for Creators):**
 *    - `upvoteContentCreator(address _creatorAddress)`: Allows users to upvote a content creator, increasing their reputation.
 *    - `downvoteContentCreator(address _creatorAddress)`: Allows users to downvote a content creator, decreasing their reputation.
 *    - `getCreatorReputation(address _creatorAddress)`: Retrieves the reputation score of a content creator.
 *
 * **5. Decentralized Governance (Content Curation & Platform Parameters):**
 *    - `proposePlatformParameterChange(string _parameterName, uint256 _newValue)`: Allows users to propose changes to platform parameters (e.g., default subscription fee, curation thresholds).
 *    - `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on parameter change proposals.
 *    - `executeParameterChangeProposal(uint256 _proposalId)`: Executes a successful parameter change proposal.
 *    - `getParameterChangeProposalDetails(uint256 _proposalId)`: Retrieves details of a parameter change proposal.
 *    - `getCurrentPlatformParameter(string _parameterName)`: Retrieves the current value of a platform parameter.
 *
 * **6. Revenue Management and Creator Payouts:**
 *    - `withdrawCreatorEarnings()`: Allows content creators to withdraw their accumulated subscription earnings.
 *    - `getContentBalance(uint256 _contentId)`: Retrieves the current balance of subscription fees for a specific content NFT.
 *    - `getPlatformFeePercentage()`: Retrieves the platform fee percentage charged on subscriptions.
 *    - `setPlatformFeePercentage(uint256 _newPercentage)`: (Governance function) Sets the platform fee percentage.
 *
 * **7. Emergency Content Freeze (Governance/Admin Function):**
 *    - `freezeContent(uint256 _contentId)`: (Governance/Admin function) Freezes content, preventing further updates.
 *    - `unfreezeContent(uint256 _contentId)`: (Governance/Admin function) Unfreezes content, allowing updates again.
 *
 * **8. Platform Registry and Discovery (Basic):**
 *    - `getAllContentNFTs()`: Returns an array of all content NFT IDs on the platform.
 *    - `getContentCreator(uint256 _contentId)`: Retrieves the creator address of a content NFT.
 */

contract DynamicContentPlatform {
    // --- Data Structures ---

    struct ContentNFT {
        address creator;
        string currentContentHash;
        string metadataURI;
        uint256 subscriptionFee;
        uint256 version;
        mapping(uint256 => ContentVersion) versions; // Version history
        uint256 balance; // Accumulated subscription fees
        bool isFrozen;
    }

    struct ContentVersion {
        string contentHash;
        uint256 timestamp;
    }

    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        uint256 proposalStartTime;
        uint256 votingDuration; // e.g., in blocks or seconds
    }

    mapping(uint256 => ContentNFT) public contentNFTs;
    mapping(uint256 => mapping(address => bool)) public subscriptionStatus; // contentId => user => isSubscribed
    mapping(address => int256) public creatorReputation; // Creator address => reputation score
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(string => uint256) public platformParameters; // Platform-wide settings

    uint256 public contentNFTCounter;
    uint256 public proposalCounter;
    uint256 public platformFeePercentage = 5; // Default 5% platform fee
    address public platformAdmin; // Address that can perform admin/governance actions (initially contract deployer)
    uint256 public proposalVotingDuration = 7 days; // Default voting duration for proposals

    // --- Events ---

    event ContentNFTCreated(uint256 contentId, address creator, string initialContentHash);
    event ContentUpdated(uint256 contentId, string newContentHash, uint256 version);
    event SubscriptionStarted(uint256 contentId, address subscriber);
    event SubscriptionEnded(uint256 contentId, address subscriber);
    event CreatorReputationChanged(address creatorAddress, int256 newReputation);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContentFrozen(uint256 contentId);
    event ContentUnfrozen(uint256 contentId);
    event PlatformFeePercentageChanged(uint256 newPercentage);

    // --- Modifiers ---

    modifier onlyContentCreator(uint256 _contentId) {
        require(contentNFTs[_contentId].creator == msg.sender, "Only content creator can perform this action.");
        _;
    }

    modifier onlySubscribedUser(uint256 _contentId) {
        require(subscriptionStatus[_contentId][msg.sender], "User is not subscribed to this content.");
        _;
    }

    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can perform this action.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < parameterChangeProposals[_proposalId].proposalStartTime + parameterChangeProposals[_proposalId].votingDuration, "Voting period has ended.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].proposalStartTime != 0, "Proposal does not exist."); // Check if proposal was initialized
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp >= parameterChangeProposals[_proposalId].proposalStartTime + parameterChangeProposals[_proposalId].votingDuration, "Voting period has not ended.");
        require(parameterChangeProposals[_proposalId].votesFor > parameterChangeProposals[_proposalId].votesAgainst, "Proposal did not pass."); // Simple majority for now
        _;
    }


    // --- Constructor ---

    constructor() {
        platformAdmin = msg.sender;
        platformParameters["defaultSubscriptionFee"] = 1 ether; // Example default subscription fee
        platformParameters["minReputationForProposal"] = 10; // Example minimum reputation to propose
    }

    // --- 1. Content Creation and NFT Minting ---

    function createContentNFT(string memory _initialContentHash, string memory _metadataURI, uint256 _subscriptionFee) public payable {
        require(bytes(_initialContentHash).length > 0, "Initial content hash cannot be empty.");
        require(_subscriptionFee >= 0, "Subscription fee must be non-negative.");

        contentNFTCounter++;
        uint256 contentId = contentNFTCounter;

        contentNFTs[contentId] = ContentNFT({
            creator: msg.sender,
            currentContentHash: _initialContentHash,
            metadataURI: _metadataURI,
            subscriptionFee: _subscriptionFee,
            version: 1,
            balance: 0,
            isFrozen: false
        });
        contentNFTs[contentId].versions[1] = ContentVersion({
            contentHash: _initialContentHash,
            timestamp: block.timestamp
        });

        emit ContentNFTCreated(contentId, msg.sender, _initialContentHash);
    }

    function updateContent(uint256 _contentId, string memory _newContentHash) public onlyContentCreator(_contentId) {
        require(!contentNFTs[_contentId].isFrozen, "Content is frozen and cannot be updated.");
        require(bytes(_newContentHash).length > 0, "New content hash cannot be empty.");

        contentNFTs[_contentId].version++;
        contentNFTs[_contentId].currentContentHash = _newContentHash;
        contentNFTs[_contentId].versions[contentNFTs[_contentId].version] = ContentVersion({
            contentHash: _newContentHash,
            timestamp: block.timestamp
        });

        emit ContentUpdated(_contentId, _newContentHash, contentNFTs[_contentId].version);
    }

    function setContentMetadataURI(uint256 _contentId, string memory _newMetadataURI) public onlyContentCreator(_contentId) {
        require(!contentNFTs[_contentId].isFrozen, "Content is frozen and cannot be updated.");
        contentNFTs[_contentId].metadataURI = _newMetadataURI;
    }


    // --- 2. Subscription and Access Control ---

    function subscribeToContent(uint256 _contentId) public payable {
        require(!subscriptionStatus[_contentId][msg.sender], "Already subscribed to this content.");
        require(msg.value >= contentNFTs[_contentId].subscriptionFee, "Insufficient subscription fee.");

        subscriptionStatus[_contentId][msg.sender] = true;
        contentNFTs[_contentId].balance += msg.value;

        // Distribute fees (Creator and Platform)
        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 creatorEarning = msg.value - platformFee;

        payable(contentNFTs[_contentId].creator).transfer(creatorEarning); // Send earnings to creator
        // Platform fees can be accumulated in the contract or handled separately.
        // For simplicity, we are not explicitly tracking platform fees in this example but they are deducted from creator's earnings.

        emit SubscriptionStarted(_contentId, msg.sender);
    }

    function unsubscribeFromContent(uint256 _contentId) public {
        require(subscriptionStatus[_contentId][msg.sender], "Not subscribed to this content.");
        subscriptionStatus[_contentId][msg.sender] = false;
        emit SubscriptionEnded(_contentId, msg.sender);
    }

    function checkSubscriptionStatus(uint256 _contentId, address _user) public view returns (bool) {
        return subscriptionStatus[_contentId][_user];
    }

    function getContentSubscriptionFee(uint256 _contentId) public view returns (uint256) {
        return contentNFTs[_contentId].subscriptionFee;
    }

    // --- 3. Content Evolution and Versioning ---

    function getContentVersion(uint256 _contentId) public view returns (uint256) {
        return contentNFTs[_contentId].version;
    }

    function getContentHashForVersion(uint256 _contentId, uint256 _version) public view returns (string memory) {
        require(_version > 0 && _version <= contentNFTs[_contentId].version, "Invalid content version.");
        return contentNFTs[_contentId].versions[_version].contentHash;
    }

    function getAllContentVersions(uint256 _contentId) public view returns (ContentVersion[] memory) {
        ContentVersion[] memory versions = new ContentVersion[](contentNFTs[_contentId].version);
        for (uint256 i = 1; i <= contentNFTs[_contentId].version; i++) {
            versions[i-1] = contentNFTs[_contentId].versions[i];
        }
        return versions;
    }

    // --- 4. On-Chain Reputation System (for Creators) ---

    function upvoteContentCreator(address _creatorAddress) public {
        creatorReputation[_creatorAddress]++;
        emit CreatorReputationChanged(_creatorAddress, creatorReputation[_creatorAddress]);
    }

    function downvoteContentCreator(address _creatorAddress) public {
        creatorReputation[_creatorAddress]--;
        emit CreatorReputationChanged(_creatorAddress, creatorReputation[_creatorAddress]);
    }

    function getCreatorReputation(address _creatorAddress) public view returns (int256) {
        return creatorReputation[_creatorAddress];
    }

    // --- 5. Decentralized Governance (Content Curation & Platform Parameters) ---

    function proposePlatformParameterChange(string memory _parameterName, uint256 _newValue) public {
        require(creatorReputation[msg.sender] >= platformParameters["minReputationForProposal"], "Insufficient reputation to propose."); // Example reputation requirement

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            proposalStartTime: block.timestamp,
            votingDuration: proposalVotingDuration
        });
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue);
    }

    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) public proposalExists(_proposalId) validProposal(_proposalId) {
        require(creatorReputation[msg.sender] >= 1, "Insufficient reputation to vote."); // Example voting reputation - everyone can vote who has any rep.
        require(parameterChangeProposals[_proposalId].isActive, "Proposal is not active.");

        if (_vote) {
            parameterChangeProposals[_proposalId].votesFor++;
        } else {
            parameterChangeProposals[_proposalId].votesAgainst++;
        }
        emit ParameterChangeVoted(_proposalId, msg.sender, _vote);
    }

    function executeParameterChangeProposal(uint256 _proposalId) public proposalExists(_proposalId) proposalExecutable(_proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Proposal is not active.");

        string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
        uint256 newValue = parameterChangeProposals[_proposalId].newValue;

        platformParameters[parameterName] = newValue;
        parameterChangeProposals[_proposalId].isActive = false; // Mark proposal as executed

        emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
    }

    function getParameterChangeProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (ParameterChangeProposal memory) {
        return parameterChangeProposals[_proposalId];
    }

    function getCurrentPlatformParameter(string memory _parameterName) public view returns (uint256) {
        return platformParameters[_parameterName];
    }

    // --- 6. Revenue Management and Creator Payouts ---

    function withdrawCreatorEarnings() public {
        uint256 totalEarnings = 0;
        uint256 contentCount = contentNFTCounter;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentNFTs[i].creator == msg.sender) {
                totalEarnings += contentNFTs[i].balance;
                contentNFTs[i].balance = 0; // Reset balance after withdrawal
            }
        }
        require(totalEarnings > 0, "No earnings to withdraw.");
        payable(msg.sender).transfer(totalEarnings);
    }

    function getContentBalance(uint256 _contentId) public view returns (uint256) {
        return contentNFTs[_contentId].balance;
    }

    function getPlatformFeePercentage() public view returns (uint256) {
        return platformFeePercentage;
    }

    function setPlatformFeePercentage(uint256 _newPercentage) public onlyPlatformAdmin { // Can be changed to governance later
        require(_newPercentage <= 100, "Platform fee percentage cannot exceed 100.");
        platformFeePercentage = _newPercentage;
        emit PlatformFeePercentageChanged(_newPercentage);
    }

    // --- 7. Emergency Content Freeze (Governance/Admin Function) ---

    function freezeContent(uint256 _contentId) public onlyPlatformAdmin {
        contentNFTs[_contentId].isFrozen = true;
        emit ContentFrozen(_contentId);
    }

    function unfreezeContent(uint256 _contentId) public onlyPlatformAdmin {
        contentNFTs[_contentId].isFrozen = false;
        emit ContentUnfrozen(_contentId);
    }

    // --- 8. Platform Registry and Discovery (Basic) ---

    function getAllContentNFTs() public view returns (uint256[] memory) {
        uint256[] memory contentIds = new uint256[](contentNFTCounter);
        for (uint256 i = 1; i <= contentNFTCounter; i++) {
            contentIds[i-1] = i;
        }
        return contentIds;
    }

    function getContentCreator(uint256 _contentId) public view returns (address) {
        return contentNFTs[_contentId].creator;
    }
}
```