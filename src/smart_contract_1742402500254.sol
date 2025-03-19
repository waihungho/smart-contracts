```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Feature Platform
 * @author Gemini AI
 * @dev A smart contract enabling dynamic feature activation and governance based on user reputation and community voting.
 *
 * Outline:
 *
 * I.  Core Functionality:
 *     1. Feature Definition and Management:
 *         - Define features with associated costs and access criteria.
 *         - Enable/Disable features by admin.
 *         - Set feature access types (reputation-based, NFT-gated, voting-based).
 *     2. User Reputation System:
 *         - Track user reputation points.
 *         - Reputation gain/loss mechanics based on platform activity.
 *         - Reputation tiers/levels.
 *     3. NFT Gated Access:
 *         - Integrate with ERC721/ERC1155 contracts for NFT-based feature access.
 *     4. Community Voting for Feature Activation:
 *         - Propose feature activation through voting.
 *         - Voting mechanism with quorum and duration.
 *         - Automatically activate features based on vote results.
 *     5. Dynamic Pricing and Rewards:
 *         - Adjust feature costs based on demand or community decisions.
 *         - Reward users for contributing to feature activation or platform growth.
 *     6. Data Analytics and Reporting (on-chain):
 *         - Track feature usage statistics.
 *         - Generate reports on feature popularity and user engagement.
 *     7. Decentralized Feature Marketplace (Basic):
 *         - Allow users to propose and "sell" new feature ideas to the platform.
 *
 * II. Advanced & Trendy Concepts:
 *     - Dynamic Feature Bundling: Combine features into bundles with discounted costs.
 *     - Reputation-Based Moderation:  Higher reputation users gain moderation powers for features.
 *     - AI-Driven Feature Recommendations (Conceptual - off-chain AI needed): Suggest features to users based on their activity.
 *     - Feature Staking: Users stake tokens to boost the priority of feature activation votes.
 *     - "Feature Bounties":  Offer rewards for users who contribute to the development or adoption of specific features.
 *     - Conditional Feature Activation: Activate features based on external oracle data (e.g., weather, market conditions - conceptual).
 *     - Personalized Feature Sets: Allow users to customize their active feature sets.
 *     - Feature "Trial" Periods: Offer limited-time free trials for certain features.
 *     - Decentralized Feature Documentation: Store feature documentation and guides on-chain (IPFS links).
 *     - Feature "Donations": Allow users to donate towards the development or maintenance of specific features.
 *
 * Function Summary:
 *
 * 1. defineFeature(string _featureName, uint256 _cost, FeatureAccessType _accessType): Defines a new platform feature with its cost and access type (Admin only).
 * 2. enableFeature(uint256 _featureId): Enables a defined feature making it available for access based on its type (Admin only).
 * 3. disableFeature(uint256 _featureId): Disables a feature, restricting access (Admin only).
 * 4. setFeatureCost(uint256 _featureId, uint256 _newCost): Updates the cost of accessing a feature (Admin only).
 * 5. setFeatureAccessType(uint256 _featureId, FeatureAccessType _newAccessType): Changes the access type of a feature (Admin only).
 * 6. grantReputation(address _user, uint256 _amount): Grants reputation points to a user (Admin/Moderator function).
 * 7. deductReputation(address _user, uint256 _amount): Deducts reputation points from a user (Admin/Moderator function).
 * 8. getUserReputation(address _user): Retrieves the reputation points of a user.
 * 9. setNFGAccessContract(uint256 _featureId, address _nftContract, uint256 _tokenId): Sets the NFT contract and token ID required for NFT-gated feature access (Admin only).
 * 10. proposeFeatureActivationVote(uint256 _featureId, string _proposalDescription): Allows users to propose a vote to activate a feature.
 * 11. voteOnFeatureActivation(uint256 _proposalId, bool _vote): Allows users to vote for or against a feature activation proposal.
 * 12. finalizeFeatureActivationVote(uint256 _proposalId): Finalizes a feature activation vote, activating the feature if passed (Admin/Automated function).
 * 13. accessFeature(uint256 _featureId): Allows users to attempt to access a feature, checking access conditions.
 * 14. getFeatureDetails(uint256 _featureId): Retrieves detailed information about a specific feature.
 * 15. getActiveFeatures(): Returns a list of currently active feature IDs.
 * 16. getFeatureUsageCount(uint256 _featureId): Returns the number of times a feature has been accessed.
 * 17. createFeatureBundle(string _bundleName, uint256[] _featureIds, uint256 _bundleDiscountPercentage): Creates a bundle of features with a discount (Admin only).
 * 18. purchaseFeatureBundle(uint256 _bundleId): Allows users to purchase a feature bundle to access multiple features at once.
 * 19. proposeNewFeatureIdea(string _featureIdea, uint256 _rewardAmount): Allows users to propose new feature ideas for community consideration (and potentially reward).
 * 20. donateToFeatureDevelopment(uint256 _featureId) payable: Allows users to donate funds towards the development of a specific feature.
 * 21. getFeatureDonationBalance(uint256 _featureId): Retrieves the donation balance for a feature.
 * 22. withdrawFeatureDonations(uint256 _featureId, address _recipient): Allows the admin to withdraw donations for feature development (Admin only).
 * 23. setReputationThresholdForFeature(uint256 _featureId, uint256 _reputationThreshold): Sets a reputation threshold required to access a feature (Admin only).
 * 24. setVotingQuorumForFeatureActivation(uint256 _featureId, uint256 _quorumPercentage): Sets the voting quorum percentage required for feature activation votes (Admin only).
 */

contract DynamicFeaturePlatform {

    // --- Enums and Structs ---

    enum FeatureAccessType {
        FREE,               // Free for all users
        REPUTATION_BASED,   // Requires a certain reputation level
        NFT_GATED,          // Requires holding a specific NFT
        VOTING_BASED        // Activated through community voting
    }

    struct Feature {
        string name;
        uint256 cost;
        FeatureAccessType accessType;
        bool isEnabled;
        address nftAccessContract;
        uint256 nftAccessTokenId;
        uint256 reputationThreshold;
        uint256 usageCount;
        uint256 donationBalance;
    }

    struct UserProfile {
        uint256 reputation;
        // Add more profile details if needed
    }

    struct FeatureActivationProposal {
        uint256 featureId;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        mapping(address => bool) voters; // Track voters to prevent double voting
    }

    struct FeatureBundle {
        string name;
        uint256[] featureIds;
        uint256 discountPercentage;
    }


    // --- State Variables ---

    address public owner;
    mapping(uint256 => Feature) public features;
    uint256 public featureCount;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => FeatureActivationProposal) public featureActivationProposals;
    uint256 public proposalCount;
    mapping(uint256 => FeatureBundle) public featureBundles;
    uint256 public bundleCount;

    uint256 public defaultVotingDuration = 7 days; // Default voting duration
    uint256 public defaultVotingQuorumPercentage = 50; // Default quorum percentage


    // --- Events ---

    event FeatureDefined(uint256 featureId, string featureName, uint256 cost, FeatureAccessType accessType);
    event FeatureEnabled(uint256 featureId);
    event FeatureDisabled(uint256 featureId);
    event FeatureCostUpdated(uint256 featureId, uint256 newCost);
    event FeatureAccessTypeUpdated(uint256 featureId, FeatureAccessType newAccessType);
    event ReputationGranted(address user, uint256 amount);
    event ReputationDeducted(address user, uint256 amount);
    event NFTAccessContractSet(uint256 featureId, address nftContract, uint256 tokenId);
    event FeatureActivationProposed(uint256 proposalId, uint256 featureId, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event FeatureActivationVoteFinalized(uint256 proposalId, uint256 featureId, bool activated);
    event FeatureAccessed(uint256 featureId, address user);
    event FeatureBundleCreated(uint256 bundleId, string bundleName, uint256[] featureIds, uint256 discountPercentage);
    event FeatureBundlePurchased(uint256 bundleId, address purchaser);
    event NewFeatureIdeaProposed(uint256 proposalId, string featureIdea, address proposer, uint256 rewardAmount);
    event DonationToFeature(uint256 featureId, address donor, uint256 amount);
    event FeatureDonationsWithdrawn(uint256 featureId, address recipient, uint256 amount);
    event ReputationThresholdSet(uint256 featureId, uint256 reputationThreshold);
    event VotingQuorumSet(uint256 featureId, uint256 quorumPercentage);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier featureExists(uint256 _featureId) {
        require(_featureId < featureCount, "Feature does not exist.");
        _;
    }

    modifier featureIsEnabled(uint256 _featureId) {
        require(features[_featureId].isEnabled, "Feature is disabled.");
        _;
    }

    modifier userExists(address _user) {
        if (userProfiles[_user].reputation == 0 && _user != owner) { // Owner implicitly exists
            createUserProfile(_user);
        }
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Proposal does not exist.");
        _;
    }

    modifier proposalIsActive(uint256 _proposalId) {
        require(featureActivationProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp <= featureActivationProposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        require(!featureActivationProposals[_proposalId].voters[msg.sender], "Already voted on this proposal.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        // Initialize some default features for demonstration (optional)
        defineFeature("Basic Chat", 0, FeatureAccessType.FREE);
        enableFeature(0);
        defineFeature("Advanced Analytics Dashboard", 1000, FeatureAccessType.REPUTATION_BASED);
        defineFeature("NFT Avatar Customization", 500, FeatureAccessType.NFT_GATED);
        defineFeature("Premium Support Channel", 2000, FeatureAccessType.VOTING_BASED);
    }


    // --- User Profile Management ---

    function createUserProfile(address _user) private {
        if (userProfiles[_user].reputation == 0 && _user != owner) {
             userProfiles[_user] = UserProfile({reputation: 0});
        }
    }

    function grantReputation(address _user, uint256 _amount) external onlyOwner userExists(_user) {
        userProfiles[_user].reputation += _amount;
        emit ReputationGranted(_user, _amount);
    }

    function deductReputation(address _user, uint256 _amount) external onlyOwner userExists(_user) {
        require(userProfiles[_user].reputation >= _amount, "Insufficient reputation to deduct.");
        userProfiles[_user].reputation -= _amount;
        emit ReputationDeducted(_user, _amount);
    }

    function getUserReputation(address _user) external view userExists(_user) returns (uint256) {
        return userProfiles[_user].reputation;
    }


    // --- Feature Definition and Management ---

    function defineFeature(string memory _featureName, uint256 _cost, FeatureAccessType _accessType) public onlyOwner {
        features[featureCount] = Feature({
            name: _featureName,
            cost: _cost,
            accessType: _accessType,
            isEnabled: false,
            nftAccessContract: address(0),
            nftAccessTokenId: 0,
            reputationThreshold: 0,
            usageCount: 0,
            donationBalance: 0
        });
        emit FeatureDefined(featureCount, _featureName, _cost, _accessType);
        featureCount++;
    }

    function enableFeature(uint256 _featureId) public onlyOwner featureExists(_featureId) {
        features[_featureId].isEnabled = true;
        emit FeatureEnabled(_featureId);
    }

    function disableFeature(uint256 _featureId) public onlyOwner featureExists(_featureId) {
        features[_featureId].isEnabled = false;
        emit FeatureDisabled(_featureId);
    }

    function setFeatureCost(uint256 _featureId, uint256 _newCost) public onlyOwner featureExists(_featureId) {
        features[_featureId].cost = _newCost;
        emit FeatureCostUpdated(_featureId, _newCost);
    }

    function setFeatureAccessType(uint256 _featureId, FeatureAccessType _newAccessType) public onlyOwner featureExists(_featureId) {
        features[_featureId].accessType = _newAccessType;
        emit FeatureAccessTypeUpdated(_featureId, _newAccessType);
    }

    function setReputationThresholdForFeature(uint256 _featureId, uint256 _reputationThreshold) public onlyOwner featureExists(_featureId) {
        require(features[_featureId].accessType == FeatureAccessType.REPUTATION_BASED, "Reputation threshold only applicable to REPUTATION_BASED features.");
        features[_featureId].reputationThreshold = _reputationThreshold;
        emit ReputationThresholdSet(_featureId, _reputationThreshold);
    }

    function setNFGAccessContract(uint256 _featureId, address _nftContract, uint256 _tokenId) public onlyOwner featureExists(_featureId) {
        require(features[_featureId].accessType == FeatureAccessType.NFT_GATED, "NFT Access Contract only applicable to NFT_GATED features.");
        features[_featureId].nftAccessContract = _nftContract;
        features[_featureId].nftAccessTokenId = _tokenId;
        emit NFTAccessContractSet(_featureId, _nftContract, _tokenId);
    }

    function getFeatureDetails(uint256 _featureId) external view featureExists(_featureId) returns (Feature memory) {
        return features[_featureId];
    }

    function getActiveFeatures() external view returns (uint256[] memory) {
        uint256[] memory activeFeatureIds = new uint256[](featureCount);
        uint256 activeCount = 0;
        for (uint256 i = 0; i < featureCount; i++) {
            if (features[i].isEnabled) {
                activeFeatureIds[activeCount] = i;
                activeCount++;
            }
        }
        // Resize the array to the actual number of active features
        assembly {
            mstore(activeFeatureIds, activeCount)
        }
        return activeFeatureIds;
    }


    // --- Feature Access Logic ---

    function accessFeature(uint256 _featureId) external payable featureExists(_featureId) featureIsEnabled(_featureId) userExists(msg.sender) {
        Feature storage feature = features[_featureId];

        if (feature.accessType == FeatureAccessType.FREE) {
            // Access granted for free features
        } else if (feature.accessType == FeatureAccessType.REPUTATION_BASED) {
            require(userProfiles[msg.sender].reputation >= feature.reputationThreshold, "Insufficient reputation to access this feature.");
        } else if (feature.accessType == FeatureAccessType.NFT_GATED) {
            // Implement NFT ownership check (ERC721/ERC1155) - Placeholder, requires external contract interaction
            // Example (requires interface import and external call - omitted for simplicity):
            // IERC721 nftContract = IERC721(feature.nftAccessContract);
            // require(nftContract.ownerOf(feature.nftAccessTokenId) == msg.sender, "NFT ownership required.");
            // For simplicity, assume an external NFT check function or oracle would be used in a real application.
            // In a real implementation, consider using ERC721/ERC1155 interfaces and cross-contract calls.
            // For now, a placeholder:
            require(checkNFTOwnership(feature.nftAccessContract, feature.nftAccessTokenId, msg.sender), "NFT ownership required.");
        } else if (feature.accessType == FeatureAccessType.VOTING_BASED) {
            // Voting-based features are enabled/disabled globally via voting, access is implicitly granted if enabled.
        }

        // Charge for feature access if there is a cost (even if currently 0, for future flexibility)
        if (feature.cost > 0) {
            require(msg.value >= feature.cost, "Insufficient funds to access feature.");
            payable(owner).transfer(msg.value); // Transfer funds to platform owner (or treasury contract in advanced scenarios)
        }

        feature.usageCount++;
        emit FeatureAccessed(_featureId, msg.sender);
    }

    // Placeholder for external NFT ownership check - Replace with actual ERC721/ERC1155 interaction in real implementation
    function checkNFTOwnership(address _nftContract, uint256 _tokenId, address _user) private pure returns (bool) {
        // In a real implementation, this would involve external calls to _nftContract
        // and checking if _user owns _tokenId.
        // For this example, we just return true as a placeholder to allow testing NFT_GATED access type.
        return true; // **WARNING: Insecure placeholder - Replace with actual NFT ownership verification.**
    }

    function getFeatureUsageCount(uint256 _featureId) external view featureExists(_featureId) returns (uint256) {
        return features[_featureId].usageCount;
    }


    // --- Feature Activation Voting ---

    function proposeFeatureActivationVote(uint256 _featureId, string memory _proposalDescription) public featureExists(_featureId) {
        require(!features[_featureId].isEnabled, "Feature is already enabled. No need to vote.");
        require(features[_featureId].accessType == FeatureAccessType.VOTING_BASED, "Voting is only applicable to VOTING_BASED features.");

        featureActivationProposals[proposalCount] = FeatureActivationProposal({
            featureId: _featureId,
            description: _proposalDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + defaultVotingDuration,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            voters: mapping(address => bool)()
        });
        emit FeatureActivationProposed(proposalCount, _featureId, msg.sender);
        proposalCount++;
    }

    function voteOnFeatureActivation(uint256 _proposalId, bool _vote) external proposalExists(_proposalId) proposalIsActive(_proposalId) notVotedYet(_proposalId) {
        FeatureActivationProposal storage proposal = featureActivationProposals[_proposalId];
        proposal.voters[msg.sender] = true; // Mark voter as voted

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function finalizeFeatureActivationVote(uint256 _proposalId) external proposalExists(_proposalId) {
        FeatureActivationProposal storage proposal = featureActivationProposals[_proposalId];
        require(block.timestamp > proposal.endTime, "Voting period has not ended yet.");
        require(proposal.isActive, "Proposal is not active.");

        proposal.isActive = false; // Deactivate the proposal

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (totalVotes * 100) / (address(this).balance > 0 ? 100 : 1); // Avoid division by zero if no balance yet. A better approach might be to use total users or a fixed value if appropriate for your platform.  Using contract balance is just a placeholder here for a dynamic quorum example.
        uint256 quorumPercentage = defaultVotingQuorumPercentage;
        if (features[proposal.featureId].accessType == FeatureAccessType.VOTING_BASED){
            quorumPercentage = getVotingQuorumForFeature(proposal.featureId);
        }

        bool votePassed = (proposal.votesFor * 100 >= totalVotes * quorumPercentage) && (quorum >= quorumPercentage); // Basic quorum and percentage check

        if (votePassed) {
            enableFeature(proposal.featureId); // Activate the feature if vote passes
        }
        emit FeatureActivationVoteFinalized(_proposalId, proposal.featureId, votePassed);
    }

    function setVotingQuorumForFeatureActivation(uint256 _featureId, uint256 _quorumPercentage) public onlyOwner featureExists(_featureId) {
        require(features[_featureId].accessType == FeatureAccessType.VOTING_BASED, "Voting quorum only applicable to VOTING_BASED features.");
        defaultVotingQuorumPercentage = _quorumPercentage; // In a real advanced system, you might want to store quorum per feature if needed.
        emit VotingQuorumSet(_featureId, _quorumPercentage);
    }

    function getVotingQuorumForFeature(uint256 _featureId) public view featureExists(_featureId) returns (uint256){
        if (features[_featureId].accessType == FeatureAccessType.VOTING_BASED) {
            return defaultVotingQuorumPercentage; // Or retrieve per-feature quorum if implemented.
        }
        return 0; // Or some default value if not voting-based.
    }


    // --- Feature Bundles ---

    function createFeatureBundle(string memory _bundleName, uint256[] memory _featureIds, uint256 _bundleDiscountPercentage) public onlyOwner {
        require(_bundleDiscountPercentage <= 100, "Discount percentage cannot exceed 100.");
        require(_featureIds.length > 0, "Bundle must contain at least one feature.");
        for (uint256 i = 0; i < _featureIds.length; i++) {
            require(_featureIds[i] < featureCount, "Invalid feature ID in bundle.");
        }

        featureBundles[bundleCount] = FeatureBundle({
            name: _bundleName,
            featureIds: _featureIds,
            discountPercentage: _bundleDiscountPercentage
        });
        emit FeatureBundleCreated(bundleCount, _bundleName, _featureIds, _bundleDiscountPercentage);
        bundleCount++;
    }

    function purchaseFeatureBundle(uint256 _bundleId) external payable userExists(msg.sender) {
        require(_bundleId < bundleCount, "Bundle does not exist.");
        FeatureBundle storage bundle = featureBundles[_bundleId];
        uint256 totalCost = 0;
        for (uint256 i = 0; i < bundle.featureIds.length; i++) {
            totalCost += features[bundle.featureIds[i]].cost;
        }

        uint256 discountedCost = (totalCost * (100 - bundle.discountPercentage)) / 100;
        require(msg.value >= discountedCost, "Insufficient funds to purchase bundle.");
        payable(owner).transfer(msg.value); // Transfer funds to platform owner

        // Grant access to all features in the bundle (logic depends on how you manage user feature access - omitted for simplicity, but would likely involve storing active features per user)
        // For now, just emit an event
        emit FeatureBundlePurchased(_bundleId, msg.sender);
    }


    // --- Feature Idea Proposals and Donations ---

    function proposeNewFeatureIdea(string memory _featureIdea, uint256 _rewardAmount) public userExists(msg.sender) {
        featureActivationProposals[proposalCount] = FeatureActivationProposal({ // Reusing proposal struct for simplicity, could create a separate struct if needed
            featureId: type(uint256).max, // Indicate this is a feature idea proposal, not feature activation
            description: _featureIdea,
            startTime: block.timestamp,
            endTime: block.timestamp + defaultVotingDuration, // Could have different voting duration for ideas
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            voters: mapping(address => bool)()
        });
        emit NewFeatureIdeaProposed(proposalCount, _featureIdea, msg.sender, _rewardAmount);
        proposalCount++;
    }

    function donateToFeatureDevelopment(uint256 _featureId) external payable featureExists(_featureId) {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        features[_featureId].donationBalance += msg.value;
        emit DonationToFeature(_featureId, msg.sender, msg.value);
    }

    function getFeatureDonationBalance(uint256 _featureId) external view featureExists(_featureId) returns (uint256) {
        return features[_featureId].donationBalance;
    }

    function withdrawFeatureDonations(uint256 _featureId, address _recipient) external onlyOwner featureExists(_featureId) {
        uint256 balance = features[_featureId].donationBalance;
        require(balance > 0, "No donations to withdraw for this feature.");
        features[_featureId].donationBalance = 0;
        payable(_recipient).transfer(balance);
        emit FeatureDonationsWithdrawn(_featureId, _recipient, balance);
    }


    // --- Fallback and Receive ---

    receive() external payable {}
    fallback() external payable {}
}
```