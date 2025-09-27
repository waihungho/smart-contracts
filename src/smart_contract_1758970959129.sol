Here's a Solidity smart contract named `AetherForge`. It introduces a novel concept of **Dynamic AetherNFTs** whose properties evolve based on external oracle data, a **Reputation System** for users, an **Integrated Prediction Market** to gamify forecasting NFT states, and **Reputation-Gated Curatorial Governance** over NFT evolution.

The core idea is to create NFTs that are not static JPEGs but rather living digital entities whose traits, rarity, or "mood" can change over time, influenced by real-world events or AI analysis (simulated via oracle feeds). Users can earn reputation by making accurate predictions about these NFTs' future states and can collectively curate how these NFTs evolve.

---

## `AetherForge` Smart Contract

### Outline and Function Summary

**Contract Name:** `AetherForge`
**Concept:** Dynamic, Oracle-Driven NFTs with a Reputation-Based Prediction and Curatorial Governance System.

**I. Core Dynamic AetherNFT Management (ERC-721 Compliant with Dynamic State)**
This section handles the creation, state retrieval, and internal updates of the `DynamicAetherNFT`s. Unlike standard NFTs, their `dynamicProperties` can change based on oracle inputs.

1.  `mintAetherNFT(address recipient, string memory initialMetadataURI)`: Mints a new `DynamicAetherNFT` for `recipient` with an initial static metadata URI.
2.  `getAetherNFTDynamicState(uint256 tokenId)`: Retrieves the current *computed dynamic properties* (e.g., "mood", "complexity score") of a specific NFT.
3.  `requestAetherNFTRecomputation(uint256 tokenId)`: Allows an NFT owner to request a re-evaluation and update of their NFT's dynamic state based on the latest linked oracle data. (May incur a gas fee).
4.  `updateAetherNFTPropertiesInternal(uint256 tokenId, bytes memory newPropertiesData)`: *Internal function.* Called by `AetherForge`'s logic or directly by a linked oracle to push updates to an NFT's dynamic properties.
5.  `setAetherNFTBaseURI(string memory newBaseURI)`: Sets the base URI for the static metadata of all AetherNFTs. Callable only by the contract owner.

**II. Oracle & Data Feed Management**
This section manages the external data sources (oracles) that feed information into the system, influencing the Dynamic AetherNFTs.

6.  `registerOracleFeed(string memory feedName, address feedAddress, string memory description)`: Registers a new external data source (e.g., a Chainlink oracle contract address) that can provide data updates. Only owner can register.
7.  `submitOracleFeedData(string memory feedName, bytes memory data)`: (Mock/privileged for demo) Allows a registered `feedAddress` to submit new data for its feed. Conceptually, this would be a callback from an actual oracle.
8.  `getLatestOracleFeedData(string memory feedName)`: Retrieves the last submitted data point for a specific registered oracle feed.
9.  `configureNFTFeedLinkage(uint256 tokenId, string memory feedName, bytes memory linkageLogic)`: Defines how a specific oracle feed's data should influence a particular dynamic property of an NFT. `linkageLogic` encodes the transformation rule.
10. `removeNFTFeedLinkage(uint256 tokenId, string memory feedName)`: Removes a previously configured linkage between an oracle feed and an NFT.

**III. Reputation System & Tiers**
A system to track and tier user reputation, earned through participation and positive contributions. Access to certain features is gated by reputation tiers.

11. `getReputationScore(address user)`: Returns the current reputation score for a given `user` address.
12. `getReputationTier(address user)`: Returns the name of the reputation tier an address currently belongs to.
13. `setReputationTierThresholds(uint256[] memory newThresholds, string[] memory newTierNames)`: Allows the owner/governance to adjust the score thresholds for different reputation tiers.
14. `_awardReputation(address user, uint256 amount, string memory reason)`: *Internal function.* Awards reputation points to a user for positive actions (e.g., correct predictions).
15. `_deductReputation(address user, uint256 amount, string memory reason)`: *Internal function.* Deducts reputation points from a user for negative actions (e.g., malicious proposals).

**IV. Prediction & Gamification Engine**
Users can stake ETH to predict future states of Dynamic AetherNFTs or oracle feed values, earning rewards and reputation for correct predictions.

16. `createPredictionMarket(string memory marketName, uint256 targetTokenId, bytes memory predictionTargetCondition, uint256 proposalPeriodEnd, uint256 resolutionPeriodEnd)`: Initiates a new prediction market on a future state of an NFT's dynamic properties. Requires a minimum ETH stake from the creator.
17. `submitPrediction(uint256 marketId, bytes memory proposedOutcome)`: Allows users to stake ETH and propose a specific outcome for a prediction market.
18. `voteOnPredictionOutcome(uint256 marketId, uint256 predictionIndex)`: Users can vote on which proposed outcome they believe is most likely to occur within a market. (This adds a layer of social prediction/curation).
19. `resolvePredictionMarket(uint256 marketId)`: Callable by anyone after `resolutionPeriodEnd`. It evaluates the market, identifies winners (based on the actual NFT state/oracle data), awards reputation, and prepares rewards.
20. `claimPredictionRewards(uint256 marketId)`: Allows winners of a resolved prediction market to claim their staked ETH plus a share of the rewards pool.

**V. Curator & Governance Features (Reputation-Gated)**
High-reputation users can propose and vote on how AetherNFT attributes evolve, enabling decentralized curation.

21. `proposeAetherNFTAttributeEvolution(uint256 tokenId, string memory attributeName, bytes memory newEvolutionLogic, uint256 minimumReputation)`: Users above a `minimumReputation` can propose new evolution logic for a specific NFT attribute. `newEvolutionLogic` defines how the attribute should change.
22. `voteOnAttributeEvolutionProposal(uint256 proposalId, bool approve)`: Users meeting a certain reputation tier can vote to `approve` or `reject` an attribute evolution proposal.
23. `executeApprovedEvolutionProposal(uint256 proposalId)`: Executes an approved evolution proposal, applying the new logic to the target NFT.
24. `accessPremiumAetherData(string memory dataFeedName, uint256 minimumReputation)`: Allows users with a sufficient reputation score to conceptually "access" premium, reputation-gated data feeds or features.

**VI. Standard ERC-721 Functions**
(Included for full compliance, but not counted towards the 20 custom functions)
`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AetherForge
 * @dev A smart contract for Dynamic AetherNFTs, featuring oracle-driven evolution,
 *      a reputation system, prediction markets, and reputation-gated curation.
 *      NFTs' properties evolve based on external data. Users earn reputation
 *      by making accurate predictions and participating in governance.
 *      High-reputation users can curate NFT evolution and access premium features.
 *
 * Concepts:
 * - Dynamic NFTs: NFTs whose metadata/properties change based on oracle data.
 * - Oracle Integration: External data feeds influencing NFT states.
 * - Reputation System: Tracks user contribution and accuracy, gating access.
 * - Prediction Markets: Gamified forecasting of NFT states/oracle data.
 * - Curatorial Governance: High-reputation users propose and vote on NFT evolution logic.
 */
contract AetherForge is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // NFT Data
    Counters.Counter private _tokenIdCounter;
    struct AetherNFTState {
        uint256 tokenId;
        address owner; // Redundant with ERC721 ownerOf, but useful for internal lookup.
        string metadataURI; // Base URI for static metadata (e.g., IPFS hash of initial image/description)
        mapping(string => bytes) dynamicProperties; // Key: property name (e.g., "mood", "rarityScore"), Value: encoded dynamic data
        mapping(string => bytes) oracleFeedLinkages; // Key: feedName, Value: encoded linkageLogic (how feed influences properties)
        uint256 lastUpdateTimestamp;
    }
    mapping(uint256 => AetherNFTState) public aetherNFTs; // TokenId => AetherNFTState

    // Oracle Feed Data
    struct OracleFeed {
        string name;
        address feedAddress; // The actual contract/address that submits data
        string description;
        bytes latestData;
        uint256 lastUpdateTimestamp;
        bool isActive;
    }
    mapping(string => OracleFeed) public oracleFeeds; // feedName => OracleFeed
    string[] public registeredFeedNames; // For iterating over registered feeds

    // Reputation System
    struct ReputationTier {
        string name;
        uint256 threshold; // Minimum score to be in this tier
    }
    mapping(address => uint256) public reputationScores;
    ReputationTier[] public reputationTiers; // e.g., "Novice", "Curator", "Architect"

    // Prediction Markets
    Counters.Counter private _marketIdCounter;
    enum MarketStatus { Created, OpenForProposals, Voting, Resolved, Cancelled }
    struct PredictionMarket {
        string name;
        uint256 targetTokenId;
        bytes predictionTargetCondition; // Encoded condition for resolution (e.g., abi.encodePacked("mood", "joyful", timestamp))
        uint256 proposalPeriodEnd; // When new proposals can no longer be submitted
        uint256 resolutionPeriodEnd; // When market can be resolved
        MarketStatus status;
        address creator;
        uint256 totalStakedForMarket; // Total ETH staked across all proposals for this market
        uint256 rewardPool; // Additional ETH added by creator or system
        uint256 winningProposalIndex; // Index of the winning proposal, once resolved
        uint256 winningVoteCount; // Number of votes for the winning proposal
        uint256 totalVotesForMarket; // Sum of votes across all proposals
    }
    mapping(uint256 => PredictionMarket) public predictionMarkets;

    // A single prediction proposal within a market
    Counters.Counter private _proposalIdCounter; // Local counter for each market
    struct PredictionProposal {
        address proposer;
        bytes proposedOutcome; // Specific outcome proposed (e.g., abi.encodePacked("mood", "sad"))
        uint256 stakedAmount; // Total ETH staked on THIS specific proposal
        mapping(address => uint256) stakers; // User => amount staked on THIS proposal
        uint256 votes; // Total votes received for THIS proposal
    }
    mapping(uint256 => mapping(uint256 => PredictionProposal)) public marketProposals; // marketId => proposalIndex => PredictionProposal
    mapping(uint256 => uint256) public marketProposalCount; // marketId => number of proposals

    mapping(uint256 => mapping(address => bool)) public hasVotedInMarket; // marketId => user => bool

    // Attribute Evolution Proposals (Curatorial Governance)
    Counters.Counter private _attrProposalIdCounter;
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    struct AttributeEvolutionProposal {
        uint256 proposalId;
        uint256 targetTokenId;
        string attributeName;
        bytes newEvolutionLogic; // Encoded new logic for attribute (e.g., how "mood" changes)
        uint256 minimumReputationToPropose;
        address proposer;
        uint256 creationTimestamp;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        mapping(address => bool) hasVoted; // User => did they vote on this proposal
        ProposalStatus status;
    }
    mapping(uint256 => AttributeEvolutionProposal) public attributeEvolutionProposals;

    // Configuration
    uint256 public constant MIN_PREDICTION_STAKE = 0.01 ether; // Minimum ETH to stake for a prediction
    uint256 public constant MARKET_RESOLUTION_FEE = 0.001 ether; // Fee for triggering market resolution
    uint256 public constant AETHER_RECOMPUTATION_FEE = 0.0005 ether; // Fee for requesting NFT recomputation

    // --- Events ---

    event AetherNFTMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event AetherNFTPropertiesUpdated(uint256 indexed tokenId, string propertyName, bytes newValue);
    event OracleFeedRegistered(string indexed feedName, address indexed feedAddress, string description);
    event OracleFeedDataSubmitted(string indexed feedName, bytes data, uint256 timestamp);
    event NFTFeedLinkageConfigured(uint256 indexed tokenId, string indexed feedName, bytes linkageLogic);
    event ReputationAwarded(address indexed user, uint256 amount, string reason);
    event ReputationDeducted(address indexed user, uint256 amount, string reason);
    event PredictionMarketCreated(uint256 indexed marketId, string name, uint256 targetTokenId, address creator);
    event PredictionSubmitted(uint256 indexed marketId, uint256 indexed proposalIndex, address indexed proposer, bytes proposedOutcome, uint256 stakedAmount);
    event PredictionVoted(uint256 indexed marketId, uint256 indexed proposalIndex, address indexed voter);
    event PredictionMarketResolved(uint256 indexed marketId, uint256 winningProposalIndex, uint256 totalRewardPool);
    event RewardsClaimed(uint256 indexed marketId, address indexed claimant, uint256 amount);
    event AttributeEvolutionProposed(uint256 indexed proposalId, uint256 indexed tokenId, string attributeName, address indexed proposer);
    event AttributeEvolutionVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event AttributeEvolutionExecuted(uint256 indexed proposalId, uint256 indexed tokenId);
    event PremiumDataAccessed(address indexed user, string indexed dataFeedName);

    // --- Constructor ---

    constructor() ERC721("AetherForge NFT", "AETHER") Ownable(msg.sender) {
        // Initialize reputation tiers
        reputationTiers.push(ReputationTier("Novice", 0));
        reputationTiers.push(ReputationTier("Learner", 100));
        reputationTiers.push(ReputationTier("Curator", 500));
        reputationTiers.push(ReputationTier("Architect", 2000));
    }

    // --- Modifiers ---

    modifier onlyFeedAddress(string memory _feedName) {
        require(oracleFeeds[_feedName].isActive, "AetherForge: Feed not active");
        require(oracleFeeds[_feedName].feedAddress == msg.sender, "AetherForge: Only registered feed address can submit data");
        _;
    }

    modifier hasMinReputation(uint256 _minReputation) {
        require(reputationScores[msg.sender] >= _minReputation, "AetherForge: Insufficient reputation");
        _;
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to award reputation points.
     * @param _user The address to award reputation to.
     * @param _amount The amount of reputation points to award.
     * @param _reason The reason for awarding reputation.
     */
    function _awardReputation(address _user, uint256 _amount, string memory _reason) internal {
        reputationScores[_user] += _amount;
        emit ReputationAwarded(_user, _amount, _reason);
    }

    /**
     * @dev Internal function to deduct reputation points.
     * @param _user The address to deduct reputation from.
     * @param _amount The amount of reputation points to deduct.
     * @param _reason The reason for deducting reputation.
     */
    function _deductReputation(address _user, uint256 _amount, string memory _reason) internal {
        reputationScores[_user] = reputationScores[_user] >= _amount ? reputationScores[_user] - _amount : 0;
        emit ReputationDeducted(_user, _amount, _reason);
    }

    /**
     * @dev Internal function to apply a new dynamic property based on oracle data and linkage logic.
     *      This is a placeholder for complex on-chain logic. In a real scenario, `linkageLogic`
     *      would be an ABI-encoded call to a resolver contract or a hash pointing to off-chain logic.
     *      For this example, we assume `linkageLogic` simply specifies which part of `feedData`
     *      to use, and `newPropertiesData` is the direct new value.
     * @param _tokenId The ID of the NFT to update.
     * @param _propertyName The name of the property to update (e.g., "mood").
     * @param _feedData The raw data from the oracle.
     * @param _linkageLogic The logic defining how feedData translates to property.
     */
    function _applyOracleToNFT(uint256 _tokenId, string memory _propertyName, bytes memory _feedData, bytes memory _linkageLogic) internal view returns (bytes memory) {
        // Example: If linkageLogic is "first16bytes", take first 16 bytes of _feedData.
        // If linkageLogic is "hash", hash _feedData.
        // This is highly simplified for demonstration. Real logic would be complex.
        if (keccak256(_linkageLogic) == keccak256(abi.encodePacked("direct"))) {
            return _feedData; // Direct application
        } else if (keccak256(_linkageLogic) == keccak256(abi.encodePacked("length_as_property"))) {
            return abi.encodePacked(bytes(_feedData).length); // Example: property becomes length of feed data
        }
        // Default or more complex logic based on interpretation
        return abi.encodePacked("unknown_effect");
    }

    // --- I. Core Dynamic AetherNFT Management (ERC-721 Compliant with Dynamic State) ---

    /**
     * @dev Mints a new DynamicAetherNFT with an initial static metadata URI.
     * @param _recipient The address to mint the NFT to.
     * @param _initialMetadataURI The initial static metadata URI for the NFT.
     */
    function mintAetherNFT(address _recipient, string memory _initialMetadataURI) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_recipient, newTokenId);
        aetherNFTs[newTokenId].tokenId = newTokenId;
        aetherNFTs[newTokenId].owner = _recipient;
        aetherNFTs[newTokenId].metadataURI = _initialMetadataURI;
        aetherNFTs[newTokenId].lastUpdateTimestamp = block.timestamp;

        // Initialize a default dynamic property
        aetherNFTs[newTokenId].dynamicProperties["mood"] = abi.encodePacked("neutral");

        emit AetherNFTMinted(newTokenId, _recipient, _initialMetadataURI);
    }

    /**
     * @dev Retrieves the current *computed dynamic properties* of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return A tuple containing arrays of property names and their encoded byte values.
     */
    function getAetherNFTDynamicState(uint256 _tokenId) public view returns (string[] memory, bytes[] memory) {
        require(_exists(_tokenId), "AetherForge: NFT does not exist");

        uint256 count = 0;
        for (uint256 i = 0; i < registeredFeedNames.length; i++) {
            if (aetherNFTs[_tokenId].oracleFeedLinkages[registeredFeedNames[i]].length > 0) {
                count++;
            }
        }

        string[] memory propertyNames = new string[](count + 1); // +1 for "mood" or other initial properties
        bytes[] memory propertyValues = new bytes[](count + 1);

        uint256 idx = 0;
        // Include default dynamic properties
        propertyNames[idx] = "mood";
        propertyValues[idx] = aetherNFTs[_tokenId].dynamicProperties["mood"];
        idx++;

        // Iterate through linked oracle feeds to show their influence (simulated)
        for (uint256 i = 0; i < registeredFeedNames.length; i++) {
            string memory feedName = registeredFeedNames[i];
            if (aetherNFTs[_tokenId].oracleFeedLinkages[feedName].length > 0) {
                propertyNames[idx] = string(abi.encodePacked("linked_", feedName));
                propertyValues[idx] = _applyOracleToNFT(
                    _tokenId,
                    feedName, // Property name based on feed, simplified
                    oracleFeeds[feedName].latestData,
                    aetherNFTs[_tokenId].oracleFeedLinkages[feedName]
                );
                idx++;
            }
        }

        return (propertyNames, propertyValues);
    }

    /**
     * @dev Allows an NFT owner to request a re-evaluation and update of their NFT's dynamic state
     *      based on the latest linked oracle data. May incur a small ETH fee.
     * @param _tokenId The ID of the NFT to recompute.
     */
    function requestAetherNFTRecomputation(uint256 _tokenId) public payable {
        require(ownerOf(_tokenId) == msg.sender, "AetherForge: Caller is not the NFT owner");
        require(msg.value >= AETHER_RECOMPUTATION_FEE, "AetherForge: Insufficient ETH for recomputation fee");

        // Simulate recomputation logic
        // In a real scenario, this might trigger an off-chain oracle call or a more complex on-chain computation.
        // For now, we iterate through linked feeds and update properties.
        for (uint256 i = 0; i < registeredFeedNames.length; i++) {
            string memory feedName = registeredFeedNames[i];
            bytes memory linkageLogic = aetherNFTs[_tokenId].oracleFeedLinkages[feedName];

            if (linkageLogic.length > 0) {
                bytes memory newPropertyValue = _applyOracleToNFT(
                    _tokenId,
                    feedName,
                    oracleFeeds[feedName].latestData,
                    linkageLogic
                );
                // Update a dynamic property based on the feed's influence
                // For simplicity, let's say a feed named "mood_influence" updates "mood"
                string memory targetPropertyName = string(abi.encodePacked(feedName, "_influence")); // Simplified mapping
                if (keccak256(abi.encodePacked(feedName)) == keccak256(abi.encodePacked("mood_feed"))) {
                    targetPropertyName = "mood";
                }

                _updateAetherNFTPropertiesInternal(_tokenId, targetPropertyName, newPropertyValue);
            }
        }
        aetherNFTs[_tokenId].lastUpdateTimestamp = block.timestamp;
        // Fee collected by contract, owner can withdraw later
    }

    /**
     * @dev Internal function to update a specific dynamic property of an NFT.
     *      This is called by internal logic (e.g., from oracle data processing).
     * @param _tokenId The ID of the NFT.
     * @param _propertyName The name of the dynamic property to update.
     * @param _newValue The new encoded value for the property.
     */
    function _updateAetherNFTPropertiesInternal(uint256 _tokenId, string memory _propertyName, bytes memory _newValue) internal {
        require(_exists(_tokenId), "AetherForge: NFT does not exist");
        aetherNFTs[_tokenId].dynamicProperties[_propertyName] = _newValue;
        aetherNFTs[_tokenId].lastUpdateTimestamp = block.timestamp;
        emit AetherNFTPropertiesUpdated(_tokenId, _propertyName, _newValue);
    }

    /**
     * @dev Sets the base URI for the static metadata of all AetherNFTs.
     *      Callable only by the contract owner.
     * @param _newBaseURI The new base URI (e.g., pointing to an IPFS gateway).
     */
    function setAetherNFTBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    // --- II. Oracle & Data Feed Management ---

    /**
     * @dev Registers a new external data source that can influence NFTs.
     *      Only callable by the contract owner.
     * @param _feedName A unique name for the oracle feed.
     * @param _feedAddress The address of the oracle contract/provider.
     * @param _description A brief description of the feed.
     */
    function registerOracleFeed(string memory _feedName, address _feedAddress, string memory _description) public onlyOwner {
        require(oracleFeeds[_feedName].feedAddress == address(0), "AetherForge: Oracle feed name already registered");
        oracleFeeds[_feedName] = OracleFeed({
            name: _feedName,
            feedAddress: _feedAddress,
            description: _description,
            latestData: "",
            lastUpdateTimestamp: 0,
            isActive: true
        });
        registeredFeedNames.push(_feedName);
        emit OracleFeedRegistered(_feedName, _feedAddress, _description);
    }

    /**
     * @dev Allows a registered oracle feed's address to submit new data.
     *      This function mimics an oracle callback.
     * @param _feedName The name of the oracle feed.
     * @param _data The new data submitted by the oracle, in bytes.
     */
    function submitOracleFeedData(string memory _feedName, bytes memory _data) public onlyFeedAddress(_feedName) {
        require(oracleFeeds[_feedName].isActive, "AetherForge: Oracle feed is not active");
        oracleFeeds[_feedName].latestData = _data;
        oracleFeeds[_feedName].lastUpdateTimestamp = block.timestamp;
        emit OracleFeedDataSubmitted(_feedName, _data, block.timestamp);
    }

    /**
     * @dev Retrieves the latest data point submitted for a specific oracle feed.
     * @param _feedName The name of the oracle feed.
     * @return The latest data in bytes.
     */
    function getLatestOracleFeedData(string memory _feedName) public view returns (bytes memory) {
        require(oracleFeeds[_feedName].feedAddress != address(0), "AetherForge: Oracle feed not registered");
        return oracleFeeds[_feedName].latestData;
    }

    /**
     * @dev Configures how a specific oracle feed's data should influence a specific NFT's dynamic properties.
     *      `_linkageLogic` conceptually defines the transformation rule.
     * @param _tokenId The ID of the NFT.
     * @param _feedName The name of the oracle feed to link.
     * @param _linkageLogic Encoded logic (e.g., a hash of a function, an identifier for a pre-defined rule).
     */
    function configureNFTFeedLinkage(uint256 _tokenId, string memory _feedName, bytes memory _linkageLogic) public {
        require(ownerOf(_tokenId) == msg.sender, "AetherForge: Caller is not the NFT owner");
        require(oracleFeeds[_feedName].feedAddress != address(0), "AetherForge: Oracle feed not registered");
        aetherNFTs[_tokenId].oracleFeedLinkages[_feedName] = _linkageLogic;
        emit NFTFeedLinkageConfigured(_tokenId, _feedName, _linkageLogic);
    }

    /**
     * @dev Removes a previously configured linkage between an oracle feed and an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _feedName The name of the oracle feed to unlink.
     */
    function removeNFTFeedLinkage(uint256 _tokenId, string memory _feedName) public {
        require(ownerOf(_tokenId) == msg.sender, "AetherForge: Caller is not the NFT owner");
        require(aetherNFTs[_tokenId].oracleFeedLinkages[_feedName].length > 0, "AetherForge: No active linkage for this feed");
        delete aetherNFTs[_tokenId].oracleFeedLinkages[_feedName];
    }

    // --- III. Reputation System & Tiers ---

    /**
     * @dev Returns the current reputation score for a given user address.
     * @param _user The address to query.
     * @return The reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    /**
     * @dev Returns the name of the reputation tier an address belongs to.
     * @param _user The address to query.
     * @return The name of the reputation tier.
     */
    function getReputationTier(address _user) public view returns (string memory) {
        uint256 score = reputationScores[_user];
        string memory currentTierName = "Unknown";
        // Tiers are sorted by threshold, so we find the highest tier the user qualifies for.
        for (uint256 i = 0; i < reputationTiers.length; i++) {
            if (score >= reputationTiers[i].threshold) {
                currentTierName = reputationTiers[i].name;
            } else {
                break; // Assumes tiers are sorted low to high
            }
        }
        return currentTierName;
    }

    /**
     * @dev Allows the owner/governance to adjust the score thresholds and names for different reputation tiers.
     *      New thresholds must be in strictly ascending order.
     * @param _newThresholds An array of new reputation score thresholds.
     * @param _newTierNames An array of new names for the tiers, corresponding to _newThresholds.
     */
    function setReputationTierThresholds(uint256[] memory _newThresholds, string[] memory _newTierNames) public onlyOwner {
        require(_newThresholds.length == _newTierNames.length, "AetherForge: Thresholds and names length mismatch");
        require(_newThresholds.length > 0, "AetherForge: At least one reputation tier required");

        // Validate thresholds are ascending
        for (uint256 i = 0; i < _newThresholds.length - 1; i++) {
            require(_newThresholds[i] < _newThresholds[i+1], "AetherForge: Thresholds must be in ascending order");
        }

        delete reputationTiers; // Clear existing tiers
        for (uint256 i = 0; i < _newThresholds.length; i++) {
            reputationTiers.push(ReputationTier({
                name: _newTierNames[i],
                threshold: _newThresholds[i]
            }));
        }
    }

    // --- IV. Prediction & Gamification Engine ---

    /**
     * @dev Initiates a new prediction market on a future state of an NFT's dynamic properties.
     *      Creator pays a small initial reward pool.
     * @param _marketName A descriptive name for the market.
     * @param _targetTokenId The ID of the NFT whose state is being predicted.
     * @param _predictionTargetCondition Encoded condition (e.g., abi.encodePacked("mood", "joyful", timestamp)).
     * @param _proposalPeriodEnd Timestamp when new prediction proposals close.
     * @param _resolutionPeriodEnd Timestamp when market can be resolved.
     */
    function createPredictionMarket(
        string memory _marketName,
        uint256 _targetTokenId,
        bytes memory _predictionTargetCondition,
        uint256 _proposalPeriodEnd,
        uint256 _resolutionPeriodEnd
    ) public payable {
        require(_exists(_targetTokenId), "AetherForge: Target NFT does not exist");
        require(block.timestamp < _proposalPeriodEnd, "AetherForge: Proposal period must be in the future");
        require(_proposalPeriodEnd < _resolutionPeriodEnd, "AetherForge: Resolution period must be after proposal period");
        require(msg.value >= MIN_PREDICTION_STAKE, "AetherForge: Market creator must stake at least MIN_PREDICTION_STAKE for initial reward pool");

        _marketIdCounter.increment();
        uint256 newMarketId = _marketIdCounter.current();

        predictionMarkets[newMarketId] = PredictionMarket({
            name: _marketName,
            targetTokenId: _targetTokenId,
            predictionTargetCondition: _predictionTargetCondition,
            proposalPeriodEnd: _proposalPeriodEnd,
            resolutionPeriodEnd: _resolutionPeriodEnd,
            status: MarketStatus.OpenForProposals,
            creator: msg.sender,
            totalStakedForMarket: 0,
            rewardPool: msg.value, // Initial reward contributed by creator
            winningProposalIndex: 0,
            winningVoteCount: 0,
            totalVotesForMarket: 0
        });

        emit PredictionMarketCreated(newMarketId, _marketName, _targetTokenId, msg.sender);
    }

    /**
     * @dev Allows users to stake ETH and propose a specific outcome for a prediction market.
     *      Users can stake on existing proposals or create new ones.
     * @param _marketId The ID of the prediction market.
     * @param _proposedOutcome The specific outcome being predicted (encoded).
     */
    function submitPrediction(uint256 _marketId, bytes memory _proposedOutcome) public payable {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.creator != address(0), "AetherForge: Market does not exist");
        require(market.status == MarketStatus.OpenForProposals, "AetherForge: Market is not open for proposals");
        require(block.timestamp < market.proposalPeriodEnd, "AetherForge: Proposal period has ended");
        require(msg.value >= MIN_PREDICTION_STAKE, "AetherForge: Insufficient stake amount");

        bool proposalExists = false;
        uint256 existingProposalIndex = 0;

        for(uint256 i = 1; i <= marketProposalCount[_marketId]; i++) { // Proposals are 1-indexed
            if (keccak256(marketProposals[_marketId][i].proposedOutcome) == keccak256(_proposedOutcome)) {
                proposalExists = true;
                existingProposalIndex = i;
                break;
            }
        }

        if (proposalExists) {
            PredictionProposal storage proposal = marketProposals[_marketId][existingProposalIndex];
            proposal.stakedAmount += msg.value;
            proposal.stakers[msg.sender] += msg.value;
        } else {
            marketProposalCount[_marketId]++;
            uint256 newProposalIndex = marketProposalCount[_marketId];
            marketProposals[_marketId][newProposalIndex] = PredictionProposal({
                proposer: msg.sender,
                proposedOutcome: _proposedOutcome,
                stakedAmount: msg.value,
                votes: 0
            });
            marketProposals[_marketId][newProposalIndex].stakers[msg.sender] += msg.value;
            existingProposalIndex = newProposalIndex;
        }

        market.totalStakedForMarket += msg.value;
        emit PredictionSubmitted(_marketId, existingProposalIndex, msg.sender, _proposedOutcome, msg.value);
    }

    /**
     * @dev Users can vote on which proposed outcome they believe is most likely to occur within a market.
     *      This adds a layer of social prediction/curation, influencing the ultimate resolution if no clear oracle data.
     * @param _marketId The ID of the prediction market.
     * @param _predictionIndex The index of the prediction proposal to vote for.
     */
    function voteOnPredictionOutcome(uint256 _marketId, uint256 _predictionIndex) public {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.creator != address(0), "AetherForge: Market does not exist");
        require(market.status == MarketStatus.OpenForProposals || market.status == MarketStatus.Voting, "AetherForge: Market is not in voting phase");
        require(block.timestamp < market.resolutionPeriodEnd, "AetherForge: Voting period has ended");
        require(_predictionIndex > 0 && _predictionIndex <= marketProposalCount[_marketId], "AetherForge: Invalid prediction proposal index");
        require(!hasVotedInMarket[_marketId][msg.sender], "AetherForge: Already voted in this market");

        PredictionProposal storage proposal = marketProposals[_marketId][_predictionIndex];
        proposal.votes++;
        market.totalVotesForMarket++;
        hasVotedInMarket[_marketId][msg.sender] = true;

        emit PredictionVoted(_marketId, _predictionIndex, msg.sender);
    }

    /**
     * @dev Resolves a prediction market. Callable by anyone after the resolution period has ended.
     *      The caller pays a small fee for triggering the resolution.
     *      Identifies winners, awards reputation, and prepares rewards.
     *      Resolution logic:
     *      1. Get actual NFT state for target.
     *      2. Compare with `predictionTargetCondition`.
     *      3. If direct match, that's the winner.
     *      4. If multiple/no direct match, defer to the proposal with most votes.
     * @param _marketId The ID of the prediction market to resolve.
     */
    function resolvePredictionMarket(uint256 _marketId) public payable {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.creator != address(0), "AetherForge: Market does not exist");
        require(market.status != MarketStatus.Resolved && market.status != MarketStatus.Cancelled, "AetherForge: Market already resolved or cancelled");
        require(block.timestamp >= market.resolutionPeriodEnd, "AetherForge: Resolution period has not ended yet");
        require(msg.value >= MARKET_RESOLUTION_FEE, "AetherForge: Insufficient ETH for resolution fee");

        market.status = MarketStatus.Resolved;
        market.rewardPool += msg.value; // Add resolution fee to reward pool

        uint256 winningProposalIndex = 0;
        uint256 highestVotes = 0;

        // Step 1: Determine the actual outcome of the NFT's dynamic property
        // For simplicity, let's say predictionTargetCondition is abi.encodePacked("mood", "joyful")
        // We will compare against the current mood property of the NFT.
        bytes memory actualOutcomeData = aetherNFTs[market.targetTokenId].dynamicProperties["mood"]; // Placeholder for actual complex logic

        // This is a placeholder for complex comparison logic.
        // In a real scenario, `_predictionTargetCondition` would specify how to evaluate.
        // E.g., check if `actualOutcomeData` matches `predictionTargetCondition`.
        // For this example, we assume _predictionTargetCondition is just a specific byte value to match.
        bool foundDirectMatch = false;
        for (uint256 i = 1; i <= marketProposalCount[_marketId]; i++) {
            PredictionProposal storage proposal = marketProposals[_marketId][i];
            if (keccak256(proposal.proposedOutcome) == keccak256(actualOutcomeData)) { // Direct match
                winningProposalIndex = i;
                foundDirectMatch = true;
                break;
            }
        }

        // If no direct oracle-based match, or if oracle provides range, defer to popular vote
        if (!foundDirectMatch && market.totalVotesForMarket > 0) {
            for (uint256 i = 1; i <= marketProposalCount[_marketId]; i++) {
                PredictionProposal storage proposal = marketProposals[_marketId][i];
                if (proposal.votes > highestVotes) {
                    highestVotes = proposal.votes;
                    winningProposalIndex = i;
                }
            }
        } else if (!foundDirectMatch && market.totalVotesForMarket == 0 && marketProposalCount[_marketId] > 0) {
            // If no oracle match and no votes, just pick the first proposal as a fallback or cancel the market
            // For now, let's pick the first for demonstration. A real contract might cancel.
             winningProposalIndex = 1; // Fallback
        } else if (marketProposalCount[_marketId] == 0) {
            // No proposals, cancel market
            market.status = MarketStatus.Cancelled;
            // Refund creator initial rewardPool
            payable(market.creator).transfer(market.rewardPool);
            emit PredictionMarketResolved(_marketId, 0, 0); // 0 indicates cancelled or no winner
            return;
        }

        market.winningProposalIndex = winningProposalIndex;
        market.winningVoteCount = highestVotes;

        // Distribute rewards and reputation
        if (winningProposalIndex > 0) {
            PredictionProposal storage winningProposal = marketProposals[_marketId][winningProposalIndex];
            uint256 totalWinnersStaked = winningProposal.stakedAmount;
            
            for (uint256 i = 1; i <= marketProposalCount[_marketId]; i++) {
                PredictionProposal storage proposal = marketProposals[_marketId][i];
                 for (address staker : proposal.stakers) { // Simplified iteration, a mapping of address to uint256 is not iterable directly, need helper
                     // In real code, we'd iterate through known stakers or maintain a list.
                     // For demo, assume `proposal.stakers` is a way to get all individual stakers.
                    if (i == winningProposalIndex) {
                        _awardReputation(staker, 50, "Correct prediction");
                    }
                }
            }

            // Simplified reward distribution: each winning staker gets their stake back + proportional share of total pool
            uint256 totalRewardAmount = market.rewardPool + market.totalStakedForMarket;
            uint256 rewardPerUnitStaked = totalRewardAmount / totalWinnersStaked; // This will truncate for small amounts

            for (uint256 i = 1; i <= marketProposalCount[_marketId]; i++) {
                PredictionProposal storage proposal = marketProposals[_marketId][i];
                 for (address staker : proposal.stakers) {
                    if (i == winningProposalIndex) {
                        // Store claimable amount for each winner
                        // This would need a `mapping(uint256 => mapping(address => uint256)) public claimableRewards`
                        // For demo, we just say rewards are ready.
                    } else {
                        // Losers lose their stake; it's distributed to winners (conceptually)
                    }
                 }
            }
        }
        
        emit PredictionMarketResolved(_marketId, winningProposalIndex, market.rewardPool + market.totalStakedForMarket);
    }

    /**
     * @dev Allows winners of a resolved prediction market to claim their staked ETH plus a share of the rewards pool.
     *      Requires a separate `claimableRewards` mapping in a real implementation.
     *      For this example, we will just simulate the claim based on the winning proposal.
     * @param _marketId The ID of the prediction market.
     */
    function claimPredictionRewards(uint256 _marketId) public {
        PredictionMarket storage market = predictionMarkets[_marketId];
        require(market.creator != address(0), "AetherForge: Market does not exist");
        require(market.status == MarketStatus.Resolved, "AetherForge: Market not yet resolved");
        require(market.winningProposalIndex > 0, "AetherForge: No winning proposal or market cancelled");

        PredictionProposal storage winningProposal = marketProposals[_marketId][market.winningProposalIndex];
        uint256 stakedByClaimant = winningProposal.stakers[msg.sender];
        require(stakedByClaimant > 0, "AetherForge: Caller did not stake on the winning proposal");

        // Calculate proportional share
        uint256 totalWinnersStaked = winningProposal.stakedAmount;
        uint256 totalRewardAmount = market.rewardPool + market.totalStakedForMarket;
        uint256 share = (stakedByClaimant * totalRewardAmount) / totalWinnersStaked;

        // Clear claimable amount
        winningProposal.stakers[msg.sender] = 0;

        // Transfer funds
        payable(msg.sender).transfer(share);
        emit RewardsClaimed(_marketId, msg.sender, share);
    }

    // --- V. Curator & Governance Features (Reputation-Gated) ---

    /**
     * @dev High-reputation users can propose new evolution logic for an NFT's specific attribute.
     *      Requires the proposer to meet a `_minimumReputation`.
     * @param _tokenId The ID of the NFT.
     * @param _attributeName The name of the attribute to modify (e.g., "mood").
     * @param _newEvolutionLogic Encoded new logic for how the attribute should evolve.
     * @param _minimumReputation The minimum reputation score required to propose this change.
     */
    function proposeAetherNFTAttributeEvolution(
        uint256 _tokenId,
        string memory _attributeName,
        bytes memory _newEvolutionLogic,
        uint256 _minimumReputation
    ) public hasMinReputation(_minimumReputation) {
        require(_exists(_tokenId), "AetherForge: NFT does not exist");
        require(bytes(_attributeName).length > 0, "AetherForge: Attribute name cannot be empty");
        require(_newEvolutionLogic.length > 0, "AetherForge: Evolution logic cannot be empty");

        _attrProposalIdCounter.increment();
        uint256 newProposalId = _attrProposalIdCounter.current();

        attributeEvolutionProposals[newProposalId] = AttributeEvolutionProposal({
            proposalId: newProposalId,
            targetTokenId: _tokenId,
            attributeName: _attributeName,
            newEvolutionLogic: _newEvolutionLogic,
            minimumReputationToPropose: _minimumReputation,
            proposer: msg.sender,
            creationTimestamp: block.timestamp,
            approvalVotes: 0,
            rejectionVotes: 0,
            status: ProposalStatus.Pending
        });

        emit AttributeEvolutionProposed(newProposalId, _tokenId, _attributeName, msg.sender);
    }

    /**
     * @dev Users meeting a certain reputation tier can vote to `approve` or `reject` an attribute evolution proposal.
     * @param _proposalId The ID of the attribute evolution proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnAttributeEvolutionProposal(uint256 _proposalId, bool _approve) public hasMinReputation(100) { // Example: 100 rep to vote
        AttributeEvolutionProposal storage proposal = attributeEvolutionProposals[_proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "AetherForge: Proposal is not pending");
        require(!proposal.hasVoted[msg.sender], "AetherForge: Already voted on this proposal");

        if (_approve) {
            proposal.approvalVotes++;
        } else {
            proposal.rejectionVotes++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit AttributeEvolutionVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes an approved evolution proposal, applying the new logic to the target NFT.
     *      Requires a certain number of approval votes and a threshold of (approvals > rejections).
     * @param _proposalId The ID of the attribute evolution proposal.
     */
    function executeApprovedEvolutionProposal(uint256 _proposalId) public {
        AttributeEvolutionProposal storage proposal = attributeEvolutionProposals[_proposalId];
        require(proposal.proposer != address(0), "AetherForge: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "AetherForge: Proposal is not pending");
        
        uint256 totalVotes = proposal.approvalVotes + proposal.rejectionVotes;
        require(totalVotes > 0, "AetherForge: No votes cast yet");

        // Example: Require 60% approval and at least 5 votes total to pass
        uint256 approvalThreshold = 60; // 60%
        uint256 minTotalVotes = 5;

        if (totalVotes >= minTotalVotes && (proposal.approvalVotes * 100) / totalVotes >= approvalThreshold) {
            // Proposal approved
            _updateAetherNFTPropertiesInternal(proposal.targetTokenId, proposal.attributeName, proposal.newEvolutionLogic);
            proposal.status = ProposalStatus.Executed;
            _awardReputation(proposal.proposer, 100, "Attribute evolution proposal executed");
            emit AttributeEvolutionExecuted(_proposalId, proposal.targetTokenId);
        } else {
            // Proposal rejected (or failed to meet quorum/threshold)
            proposal.status = ProposalStatus.Rejected;
            _deductReputation(proposal.proposer, 20, "Attribute evolution proposal rejected/failed");
        }
    }

    /**
     * @dev Allows users with a sufficient reputation score to conceptually "access" premium,
     *      reputation-gated data feeds or features. In a real application, this would
     *      trigger an off-chain API call or unveil encrypted data.
     * @param _dataFeedName The name of the premium data feed to access.
     * @param _minimumReputation The minimum reputation score required to access this data.
     */
    function accessPremiumAetherData(string memory _dataFeedName, uint256 _minimumReputation) public hasMinReputation(_minimumReputation) {
        // This function would conceptually unlock access to premium data.
        // E.g., it could emit an event that an off-chain service monitors to grant access,
        // or return a hash that can decrypt a premium data payload.
        // For demonstration, we simply emit an event.
        emit PremiumDataAccessed(msg.sender, _dataFeedName);
        // You might want to return some identifier or data here if it's on-chain
        // return keccak256(abi.encodePacked("premium_access_granted", msg.sender, _dataFeedName, block.timestamp));
    }

    // --- Standard ERC-721 Overrides (not counted in 20 custom functions) ---
    function _baseURI() internal view override returns (string memory) {
        return "ipfs://"; // Placeholder, can be set by setAetherNFTBaseURI
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```