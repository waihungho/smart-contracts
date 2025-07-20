This smart contract, named **"CuriosityProtocol"**, envisions a decentralized platform where users can collectively fund, discover, validate, and immortalize novel insights and data through on-chain mechanics. It blends concepts from dynamic NFTs, decentralized science (DeSci), oracle networks, and adaptive governance, creating a self-sustaining ecosystem for knowledge discovery.

---

## **CuriosityProtocol: Outline and Function Summary**

**Core Concept:** A protocol for incentivizing, validating, and curating "discoveries" (novel insights, data, research findings). Users sponsor research areas, submit findings, and a decentralized oracle network/community validates them. Validated discoveries become unique "Insight NFTs" and are rewarded from sponsorship pools.

**Token System (External):**
This protocol assumes the existence of two external contracts:
1.  **Curiosity Token (CRST):** An ERC-20 token used for staking, governance voting, and potentially as a reward currency. (Not implemented here, assumed interface).
2.  **Insight NFT (INF):** An ERC-721 token representing validated discoveries. Each unique, impactful discovery mints one INF. (Not implemented here, assumed interface).

---

### **Outline:**

1.  **State Variables & Data Structures:**
    *   `Discovery`: Represents a submitted insight.
    *   `Oracle`: Represents a registered validator.
    *   `SponsorshipPool`: Represents a pool of funds for specific categories.
    *   `Proposal`: Represents a governance proposal.
    *   `discoveryCounter`, `oracleCounter`, `poolCounter`, `proposalCounter`.
    *   Mappings for `discoveries`, `oracles`, `sponsorshipPools`, `proposals`.
    *   Governance parameters (`validationThreshold`, `rewardCoefficient`, `decayRate`).

2.  **Events:** Crucial for off-chain monitoring and data indexing.

3.  **Error Handling:** Custom errors for clarity and gas efficiency.

4.  **Constructor:** Initializes the contract with basic parameters and token addresses.

5.  **Discovery Management:**
    *   `submitDiscovery`: User submits a potential insight.
    *   `updateDiscoveryMetadata`: Update details for a pending discovery.
    *   `getDiscoveryDetails`: Retrieve information about a discovery.
    *   `getRecentDiscoveries`: Get a list of the most recent submissions.
    *   `getTopDiscoveriesByImpact`: Get discoveries sorted by current impact.

6.  **Oracle Network & Validation:**
    *   `registerOracle`: User registers as an oracle.
    *   `submitOracleValidation`: Oracle votes on a discovery's validity/novelty.
    *   `resolveDiscoveryValidation`: Finalizes validation status based on oracle votes.
    *   `penalizeOracle`: Governance can penalize misbehaving oracles.
    *   `getOracleReputation`: Check an oracle's current reputation score.

7.  **Sponsorship & Rewards:**
    *   `createSponsorshipPool`: Governance/sponsor creates a pool for a category.
    *   `contributeToSponsorshipPool`: Users add funds to a pool.
    *   `claimDiscoveryReward`: Discoverer claims their reward after validation.
    *   `withdrawUnusedSponsorship`: Sponsor can withdraw unused funds from their pool.

8.  **Insight NFT Management:**
    *   `mintInsightNFT`: Internal function called upon successful validation and reward.

9.  **Dynamic Impact & Relevance:**
    *   `decayImpactScores`: Periodically reduces the impact score of older discoveries.
    *   `updateDiscoveryRelevance`: Allows discoverers or governance to update relevance, potentially resetting decay.

10. **Governance (DAO Integration):**
    *   `proposeParameterChange`: CRST holders propose changes to protocol parameters.
    *   `voteOnProposal`: CRST holders vote on active proposals.
    *   `executeProposal`: Executes a passed proposal.
    *   `addDiscoveryCategory`: Governance adds a new category.
    *   `removeDiscoveryCategory`: Governance removes an existing category.

11. **Utility & Getters:**
    *   `getProtocolBalance`: Checks the contract's ETH balance.
    *   `getOracleCount`: Total registered oracles.
    *   `getSponsorshipPoolBalance`: Balance of a specific pool.

---

### **Function Summary (25 Functions):**

1.  `constructor(address _owner, address _crstTokenAddress, address _insightNFTAddress)`: Initializes protocol with owner and token addresses.
2.  `submitDiscovery(string calldata _metadataHash, string calldata _url, uint256 _initialNoveltyScore, string calldata _category)`: Allows a user to submit a new discovery.
3.  `updateDiscoveryMetadata(uint256 _discoveryId, string calldata _newMetadataHash, string calldata _newUrl, string calldata _newCategory)`: Allows the discoverer to update non-critical details of their pending discovery.
4.  `getDiscoveryDetails(uint256 _discoveryId)`: Retrieves all details for a specific discovery.
5.  `getRecentDiscoveries(uint256 _count)`: Returns details of the `_count` most recently submitted discoveries.
6.  `getTopDiscoveriesByImpact(uint256 _count)`: Returns details of discoveries with the highest current impact scores.
7.  `registerOracle()`: Allows any address to register as an oracle by staking CRST (conceptual, assumes CRST token logic).
8.  `submitOracleValidation(uint256 _discoveryId, bool _isValid, uint256 _noveltyVote, uint256 _impactVote)`: An oracle submits their validation vote for a discovery.
9.  `resolveDiscoveryValidation(uint256 _discoveryId)`: Triggers the final validation check for a discovery based on accumulated oracle votes.
10. `penalizeOracle(address _oracleAddress, uint256 _amount)`: Governance function to penalize a misbehaving oracle.
11. `getOracleReputation(address _oracleAddress)`: Retrieves the current reputation score of an oracle.
12. `createSponsorshipPool(string calldata _category, string calldata _description)`: Governance or approved sponsor creates a new pool for a specific research category.
13. `contributeToSponsorshipPool(uint256 _poolId) payable`: Users contribute ETH to a specific sponsorship pool.
14. `claimDiscoveryReward(uint256 _discoveryId)`: Allows the discoverer to claim their reward once a discovery is validated and funded.
15. `withdrawUnusedSponsorship(uint256 _poolId)`: Allows the original sponsor of a pool to withdraw any remaining, unused funds.
16. `_mintInsightNFT(uint256 _discoveryId, address _to)`: Internal function to mint an INF when a discovery is successfully validated and rewarded.
17. `decayImpactScores(uint256[] calldata _discoveryIds)`: Allows anyone (or a keeper bot) to trigger a periodic decay of impact scores for specified discoveries.
18. `updateDiscoveryRelevance(uint256 _discoveryId, string calldata _newMetadataHash, string calldata _newUrl)`: Allows the discoverer or governance to update details that might refresh its relevance score.
19. `proposeParameterChange(string calldata _description, string calldata _targetParam, uint256 _newValue)`: Allows a CRST holder to propose a change to a protocol parameter.
20. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows a CRST holder to vote on an active governance proposal.
21. `executeProposal(uint256 _proposalId)`: Executes a governance proposal if it has passed and its voting period has ended.
22. `addDiscoveryCategory(string calldata _categoryName)`: Governance function to add a new valid category for discoveries.
23. `removeDiscoveryCategory(string calldata _categoryName)`: Governance function to remove an existing discovery category.
24. `getProtocolBalance()`: Returns the total ETH held by the contract.
25. `getSponsorshipPoolBalance(uint256 _poolId)`: Returns the current ETH balance of a specific sponsorship pool.

---
**Smart Contract Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ICuriosityToken
 * @dev Interface for the Curiosity Token (CRST), an ERC-20 token used for staking and governance.
 * Assumed to have governance extensions like ERC20Votes for voting power delegation.
 */
interface ICuriosityToken is IERC20 {
    function getVotes(address account) external view returns (uint256);
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
    function delegate(address delegatee) external;
}

/**
 * @title IInsightNFT
 * @dev Interface for the Insight NFT (INF), an ERC-721 token representing validated discoveries.
 */
interface IInsightNFT is IERC721 {
    function mintInsight(address to, uint256 discoveryId, string calldata tokenURI) external returns (uint256);
}

/**
 * @title CuriosityProtocol
 * @dev A decentralized protocol for funding, discovering, validating, and curating novel insights.
 * It combines elements of DeSci, oracle networks, dynamic NFTs, and adaptive governance.
 */
contract CuriosityProtocol is Ownable {

    // --- Custom Errors ---
    error DiscoveryNotFound(uint256 discoveryId);
    error InvalidDiscoveryStatus(uint256 discoveryId, string expectedStatus);
    error UnauthorizedAction(address caller, string requiredRole);
    error OracleNotFound(address oracleAddress);
    error OracleAlreadyRegistered(address oracleAddress);
    error InsufficientStake(address oracleAddress, uint256 requiredStake);
    error ValidationAlreadySubmitted(uint256 discoveryId, address oracle);
    error NoValidationData(uint256 discoveryId);
    error SponsorshipPoolNotFound(uint256 poolId);
    error InsufficientFundsInPool(uint256 poolId, uint256 requestedAmount);
    error InvalidCategory(string category);
    error CategoryAlreadyExists(string category);
    error CategoryDoesNotExist(string category);
    error RewardAlreadyClaimed(uint256 discoveryId);
    error DiscoveryNotValidated(uint256 discoveryId);
    error DiscoveryNotSponsored(uint256 discoveryId);
    error ProposalNotFound(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error ProposalNotYetExecutable(uint256 proposalId);
    error VotingPeriodActive(uint256 proposalId);
    error InsufficientVotingPower(address voter, uint256 requiredPower);
    error AlreadyVoted(uint256 proposalId, address voter);
    error InvalidProposalValue(string paramName);


    // --- Enums ---
    enum DiscoveryStatus { PENDING, VALIDATING, VALIDATED, REJECTED, REWARDED }
    enum ProposalStatus { PENDING, ACTIVE, SUCCEEDED, FAILED, EXECUTED }
    enum ProposalType {
        SET_VALIDATION_THRESHOLD,
        SET_REWARD_COEFFICIENT,
        SET_DECAY_RATE,
        ADD_CATEGORY,
        REMOVE_CATEGORY
    }

    // --- Structs ---

    struct Discovery {
        uint256 id;
        address discoverer;
        uint256 timestamp;
        string metadataHash; // IPFS CID or similar for detailed data
        string url;          // Link to external resource
        uint256 initialNoveltyScore; // Discoverer's initial assessment
        uint256 currentImpactScore;  // Dynamically updated, influenced by oracle votes and decay
        string category;
        DiscoveryStatus status;
        uint256 sponsorshipAmount; // Amount of ETH sponsored for this discovery
        uint256 insightNFTId;      // ID of the minted Insight NFT
        uint256[] oracleVotes;     // Array of oracle votes (packed for efficiency if complex)
        mapping(address => bool) hasOracleVoted; // Tracks if an oracle has voted
        uint256 totalValidations;   // Count of 'true' votes from oracles
        uint256 totalInvalidations; // Count of 'false' votes from oracles
    }

    struct Oracle {
        address wallet;
        uint256 reputationScore; // Increases with good validations, decreases with bad/penalties
        bool isActive;
        uint256 lastValidationTime;
    }

    struct SponsorshipPool {
        uint256 id;
        address creator;
        string category;
        string description;
        uint256 totalAmount; // Total ETH in the pool
        bool isActive;
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        ProposalType pType;
        string targetParam; // e.g., "validationThreshold", "rewardCoefficient"
        uint256 newValue;   // The new value for the parameter
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        ProposalStatus status;
    }

    // --- State Variables ---

    uint256 public discoveryCounter;
    mapping(uint256 => Discovery) public discoveries;
    uint256[] public allDiscoveryIds; // To easily iterate through all discoveries

    uint256 public oracleCounter;
    mapping(address => Oracle) public oracles; // Oracles indexed by their wallet address

    uint256 public poolCounter;
    mapping(uint256 => SponsorshipPool) public sponsorshipPools;
    mapping(string => uint256) public categoryToPoolId; // Maps category name to its sponsorship pool ID
    mapping(string => bool) public approvedCategories; // Whitelist of categories

    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;

    ICuriosityToken public immutable CRST_TOKEN;
    IInsightNFT public immutable INSIGHT_NFT;

    // --- Governance Parameters (set by DAO) ---
    uint256 public validationThreshold;  // Minimum percentage of 'yes' oracle votes required (e.g., 70 for 70%)
    uint256 public rewardCoefficient;    // Multiplier for reward calculation
    uint256 public oracleStakeRequirement; // CRST required to register as an oracle
    uint256 public impactDecayRate;      // Rate at which impact scores decay over time (e.g., 10 for 10% per period)
    uint256 public proposalVoteQuorum;   // Minimum percentage of total CRST votes required for a proposal to pass
    uint256 public proposalVotingPeriod; // Duration in seconds for which a proposal is open for voting
    uint256 public minProposalStake;     // Minimum CRST required to create a proposal


    // --- Events ---

    event DiscoverySubmitted(uint256 indexed discoveryId, address indexed discoverer, string category, string metadataHash);
    event DiscoveryMetadataUpdated(uint256 indexed discoveryId, string newMetadataHash, string newUrl, string newCategory);
    event OracleRegistered(address indexed oracleAddress, uint256 oracleId);
    event OracleValidationSubmitted(uint256 indexed discoveryId, address indexed oracleAddress, bool isValid, uint256 noveltyVote, uint256 impactVote);
    event DiscoveryValidationResolved(uint256 indexed discoveryId, DiscoveryStatus newStatus, uint256 finalImpactScore);
    event OraclePenalized(address indexed oracleAddress, uint256 amount);
    event SponsorshipPoolCreated(uint256 indexed poolId, string category, address indexed creator, uint256 initialAmount);
    event FundsContributedToPool(uint256 indexed poolId, address indexed contributor, uint256 amount);
    event DiscoveryRewardClaimed(uint256 indexed discoveryId, address indexed discoverer, uint256 rewardAmount, uint256 insightNFTId);
    event UnusedSponsorshipWithdrawn(uint256 indexed poolId, address indexed receiver, uint256 amount);
    event ImpactScoreDecayed(uint256 indexed discoveryId, uint256 newImpactScore, uint256 decayAmount);
    event DiscoveryRelevanceUpdated(uint256 indexed discoveryId, string newMetadataHash, string newUrl);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, ProposalType pType, uint256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event CategoryAdded(string indexed categoryName);
    event CategoryRemoved(string indexed categoryName);


    // --- Modifiers ---

    modifier onlyOracle() {
        if (!oracles[msg.sender].isActive) {
            revert UnauthorizedAction(msg.sender, "Oracle");
        }
        _;
    }

    modifier onlyDiscoverer(uint256 _discoveryId) {
        if (discoveries[_discoveryId].discoverer != msg.sender) {
            revert UnauthorizedAction(msg.sender, "Discoverer of this discovery");
        }
        _;
    }

    modifier categoryExists(string calldata _category) {
        if (!approvedCategories[_category]) {
            revert InvalidCategory(_category);
        }
        _;
    }

    modifier discoveryExists(uint256 _discoveryId) {
        if (discoveries[_discoveryId].discoverer == address(0)) { // Check for existence using a default value
            revert DiscoveryNotFound(_discoveryId);
        }
        _;
    }

    // --- Constructor ---

    constructor(address _owner, address _crstTokenAddress, address _insightNFTAddress) Ownable(_owner) {
        require(_crstTokenAddress != address(0), "CRST token address cannot be zero");
        require(_insightNFTAddress != address(0), "Insight NFT address cannot be zero");

        CRST_TOKEN = ICuriosityToken(_crstTokenAddress);
        INSIGHT_NFT = IInsightNFT(_insightNFTAddress);

        // Initial governance parameters (can be changed by DAO later)
        validationThreshold = 70;      // 70% 'yes' votes required
        rewardCoefficient = 1000;      // Base reward multiplier (e.g., in ETH wei)
        oracleStakeRequirement = 100 * 10**18; // 100 CRST
        impactDecayRate = 5;           // 5% decay per period (to be defined in `decayImpactScores`)
        proposalVoteQuorum = 20;       // 20% of total supply (or staked supply) for quorum
        proposalVotingPeriod = 3 days; // 3 days for voting
        minProposalStake = 100 * 10**18; // 100 CRST to create a proposal

        // Add initial categories
        approvedCategories["General Research"] = true;
        approvedCategories["AI & Machine Learning"] = true;
        approvedCategories["Blockchain & Web3"] = true;
        approvedCategories["Biotechnology"] = true;
        approvedCategories["Physics"] = true;
    }

    // --- 1. Discovery Management ---

    /**
     * @dev Allows a user to submit a new potential insight or discovery.
     * Requires the specified category to be an approved category.
     * @param _metadataHash IPFS CID or hash of detailed discovery data.
     * @param _url A URL pointing to external context or data.
     * @param _initialNoveltyScore An initial score of novelty provided by the discoverer (0-100).
     * @param _category The category this discovery belongs to.
     */
    function submitDiscovery(
        string calldata _metadataHash,
        string calldata _url,
        uint256 _initialNoveltyScore,
        string calldata _category
    ) external categoryExists(_category) returns (uint256) {
        require(bytes(_metadataHash).length > 0, "Metadata hash cannot be empty");
        require(_initialNoveltyScore <= 100, "Initial novelty score must be between 0 and 100");

        discoveryCounter++;
        uint256 newId = discoveryCounter;

        Discovery storage newDiscovery = discoveries[newId];
        newDiscovery.id = newId;
        newDiscovery.discoverer = msg.sender;
        newDiscovery.timestamp = block.timestamp;
        newDiscovery.metadataHash = _metadataHash;
        newDiscovery.url = _url;
        newDiscovery.initialNoveltyScore = _initialNoveltyScore;
        newDiscovery.currentImpactScore = _initialNoveltyScore; // Initial impact
        newDiscovery.category = _category;
        newDiscovery.status = DiscoveryStatus.PENDING;
        newDiscovery.sponsorshipAmount = 0;
        newDiscovery.insightNFTId = 0; // Not minted yet

        allDiscoveryIds.push(newId);

        emit DiscoverySubmitted(newId, msg.sender, _category, _metadataHash);
        return newId;
    }

    /**
     * @dev Allows the discoverer to update the metadata or URL of a pending discovery.
     * Only allowed if the discovery is still in PENDING or VALIDATING status.
     * @param _discoveryId The ID of the discovery to update.
     * @param _newMetadataHash The new IPFS CID or hash.
     * @param _newUrl The new URL.
     * @param _newCategory The new category.
     */
    function updateDiscoveryMetadata(
        uint256 _discoveryId,
        string calldata _newMetadataHash,
        string calldata _newUrl,
        string calldata _newCategory
    ) external onlyDiscoverer(_discoveryId) discoveryExists(_discoveryId) categoryExists(_newCategory) {
        Discovery storage discovery = discoveries[_discoveryId];
        if (discovery.status != DiscoveryStatus.PENDING && discovery.status != DiscoveryStatus.VALIDATING) {
            revert InvalidDiscoveryStatus(_discoveryId, "PENDING or VALIDATING");
        }

        discovery.metadataHash = _newMetadataHash;
        discovery.url = _newUrl;
        discovery.category = _newCategory;

        emit DiscoveryMetadataUpdated(_discoveryId, _newMetadataHash, _newUrl, _newCategory);
    }

    /**
     * @dev Retrieves all details for a specific discovery.
     * @param _discoveryId The ID of the discovery.
     * @return A tuple containing all discovery properties.
     */
    function getDiscoveryDetails(uint256 _discoveryId)
        external
        view
        discoveryExists(_discoveryId)
        returns (
            uint256 id,
            address discoverer,
            uint256 timestamp,
            string memory metadataHash,
            string memory url,
            uint256 initialNoveltyScore,
            uint256 currentImpactScore,
            string memory category,
            DiscoveryStatus status,
            uint256 sponsorshipAmount,
            uint256 insightNFTId
        )
    {
        Discovery storage d = discoveries[_discoveryId];
        return (
            d.id,
            d.discoverer,
            d.timestamp,
            d.metadataHash,
            d.url,
            d.initialNoveltyScore,
            d.currentImpactScore,
            d.category,
            d.status,
            d.sponsorshipAmount,
            d.insightNFTId
        );
    }

    /**
     * @dev Returns details of the `_count` most recently submitted discoveries.
     * @param _count The number of recent discoveries to retrieve.
     * @return An array of Discovery structs.
     */
    function getRecentDiscoveries(uint256 _count) external view returns (Discovery[] memory) {
        uint256 numDiscoveries = allDiscoveryIds.length;
        uint256 actualCount = _count > numDiscoveries ? numDiscoveries : _count;
        Discovery[] memory result = new Discovery[](actualCount);

        for (uint256 i = 0; i < actualCount; i++) {
            uint256 discoveryIndex = numDiscoveries - 1 - i; // Get from newest to oldest
            result[i] = discoveries[allDiscoveryIds[discoveryIndex]];
        }
        return result;
    }

    /**
     * @dev Returns details of discoveries sorted by their current impact scores.
     * This is a simplified in-memory sort for demonstration. For large datasets,
     * off-chain indexing and querying would be required.
     * @param _count The number of top discoveries to retrieve.
     * @return An array of Discovery structs, sorted by impact.
     */
    function getTopDiscoveriesByImpact(uint256 _count) external view returns (Discovery[] memory) {
        uint256 numDiscoveries = allDiscoveryIds.length;
        uint256 actualCount = _count > numDiscoveries ? numDiscoveries : _count;
        
        // Create a temporary array of discovery IDs to sort
        uint256[] memory tempIds = new uint256[](numDiscoveries);
        for (uint256 i = 0; i < numDiscoveries; i++) {
            tempIds[i] = allDiscoveryIds[i];
        }

        // Simple bubble sort (inefficient for large N, but functional for example)
        for (uint256 i = 0; i < numDiscoveries; i++) {
            for (uint256 j = i + 1; j < numDiscoveries; j++) {
                if (discoveries[tempIds[i]].currentImpactScore < discoveries[tempIds[j]].currentImpactScore) {
                    uint256 temp = tempIds[i];
                    tempIds[i] = tempIds[j];
                    tempIds[j] = temp;
                }
            }
        }

        Discovery[] memory result = new Discovery[](actualCount);
        for (uint256 i = 0; i < actualCount; i++) {
            result[i] = discoveries[tempIds[i]];
        }
        return result;
    }


    // --- 2. Oracle Network & Validation ---

    /**
     * @dev Allows an address to register as an oracle by staking CRST.
     * Requires a minimum CRST stake (oracleStakeRequirement).
     * @notice This function assumes the CRST_TOKEN contract handles the actual staking logic.
     */
    function registerOracle() external {
        if (oracles[msg.sender].isActive) {
            revert OracleAlreadyRegistered(msg.sender);
        }
        // Conceptual: Call CRST_TOKEN.stake(oracleStakeRequirement)
        // require(CRST_TOKEN.balanceOf(msg.sender) >= oracleStakeRequirement, "Not enough CRST to stake");
        // require(CRST_TOKEN.transferFrom(msg.sender, address(this), oracleStakeRequirement), "CRST transfer failed");
        // CRST_TOKEN.stake(oracleStakeRequirement); // Assuming stake logic within CRST_TOKEN itself

        oracleCounter++;
        oracles[msg.sender] = Oracle({
            wallet: msg.sender,
            reputationScore: 100, // Initial reputation
            isActive: true,
            lastValidationTime: block.timestamp
        });

        emit OracleRegistered(msg.sender, oracleCounter);
    }

    /**
     * @dev An oracle submits their validation vote for a discovery.
     * @param _discoveryId The ID of the discovery to validate.
     * @param _isValid True if the oracle validates it as novel/true, false otherwise.
     * @param _noveltyVote A score from 0-100 for its novelty.
     * @param _impactVote A score from 0-100 for its potential impact.
     */
    function submitOracleValidation(
        uint256 _discoveryId,
        bool _isValid,
        uint256 _noveltyVote,
        uint256 _impactVote
    ) external onlyOracle discoveryExists(_discoveryId) {
        Discovery storage discovery = discoveries[_discoveryId];

        if (discovery.status != DiscoveryStatus.PENDING && discovery.status != DiscoveryStatus.VALIDATING) {
            revert InvalidDiscoveryStatus(_discoveryId, "PENDING or VALIDATING");
        }
        if (discovery.hasOracleVoted[msg.sender]) {
            revert ValidationAlreadySubmitted(_discoveryId, msg.sender);
        }
        require(_noveltyVote <= 100 && _impactVote <= 100, "Votes must be between 0 and 100");

        discovery.status = DiscoveryStatus.VALIDATING; // Set to validating if first vote comes in
        discovery.hasOracleVoted[msg.sender] = true;

        uint256 oracleVoteData = 0;
        if (_isValid) {
            discovery.totalValidations++;
            oracleVoteData = 1; // Mark as valid
        } else {
            discovery.totalInvalidations++;
            oracleVoteData = 0; // Mark as invalid
        }
        oracleVoteData = oracleVoteData | (_noveltyVote << 1); // Shift novelty vote
        oracleVoteData = oracleVoteData | (_impactVote << 8);  // Shift impact vote

        // In a real scenario, you'd store more complex data per oracle or aggregate.
        // For simplicity, we just store aggregated counts and a flag here.
        // A more advanced system might store all individual oracle votes in an array
        // or a separate mapping, but this can get very gas-intensive.
        discovery.oracleVotes.push(oracleVoteData); // Storing a packed vote (isValid|novelty|impact)

        // Update oracle's reputation (simplified)
        oracles[msg.sender].reputationScore += _isValid ? 1 : 0;
        oracles[msg.sender].lastValidationTime = block.timestamp;

        emit OracleValidationSubmitted(_discoveryId, msg.sender, _isValid, _noveltyVote, _impactVote);
    }

    /**
     * @dev Triggers the final validation check for a discovery based on accumulated oracle votes.
     * Can be called by anyone, incentivizing decentralized execution.
     * Calculates the final impact score and updates discovery status.
     * @param _discoveryId The ID of the discovery to resolve.
     */
    function resolveDiscoveryValidation(uint256 _discoveryId) external discoveryExists(_discoveryId) {
        Discovery storage discovery = discoveries[_discoveryId];
        if (discovery.status != DiscoveryStatus.VALIDATING) {
            revert InvalidDiscoveryStatus(_discoveryId, "VALIDATING");
        }
        if (discovery.oracleVotes.length == 0) {
            revert NoValidationData(_discoveryId);
        }

        uint256 totalVotes = discovery.totalValidations + discovery.totalInvalidations;
        require(totalVotes > 0, "No oracle votes submitted yet.");

        uint256 validPercentage = (discovery.totalValidations * 100) / totalVotes;

        if (validPercentage >= validationThreshold) {
            // Calculate average novelty and impact from valid votes
            uint256 sumNovelty = 0;
            uint256 sumImpact = 0;
            for (uint256 i = 0; i < discovery.oracleVotes.length; i++) {
                uint256 packedVote = discovery.oracleVotes[i];
                if ((packedVote & 1) == 1) { // Check if it's a valid vote
                    sumNovelty += (packedVote >> 1) & 0x7F; // Extract novelty
                    sumImpact += (packedVote >> 8) & 0x7F;  // Extract impact
                }
            }

            // Acknowledge possible division by zero if no valid votes, though logic above prevents this for passing.
            uint256 avgNovelty = sumNovelty / discovery.totalValidations;
            uint256 avgImpact = sumImpact / discovery.totalValidations;

            discovery.currentImpactScore = (avgNovelty + avgImpact) / 2; // Simple average
            discovery.status = DiscoveryStatus.VALIDATED;

        } else {
            discovery.currentImpactScore = 0;
            discovery.status = DiscoveryStatus.REJECTED;
        }

        emit DiscoveryValidationResolved(_discoveryId, discovery.status, discovery.currentImpactScore);
    }

    /**
     * @dev Governance function to penalize a misbehaving oracle.
     * This could involve slashing their staked CRST or reducing their reputation.
     * @param _oracleAddress The address of the oracle to penalize.
     * @param _amount The amount of CRST to penalize (conceptual).
     */
    function penalizeOracle(address _oracleAddress, uint256 _amount) external onlyOwner {
        if (!oracles[_oracleAddress].isActive) {
            revert OracleNotFound(_oracleAddress);
        }
        require(_amount > 0, "Penalty amount must be greater than zero");

        oracles[_oracleAddress].reputationScore = oracles[_oracleAddress].reputationScore > _amount ?
                                                  oracles[_oracleAddress].reputationScore - _amount : 0;
        
        // Conceptual: Transfer penalized CRST to a treasury or burn.
        // CRST_TOKEN.transfer(_owner, _amount); // Or burn
        
        emit OraclePenalized(_oracleAddress, _amount);
    }

    /**
     * @dev Retrieves the current reputation score of an oracle.
     * @param _oracleAddress The address of the oracle.
     * @return The oracle's reputation score.
     */
    function getOracleReputation(address _oracleAddress) external view returns (uint256) {
        if (!oracles[_oracleAddress].isActive) {
            revert OracleNotFound(_oracleAddress);
        }
        return oracles[_oracleAddress].reputationScore;
    }

    // --- 3. Sponsorship & Rewards ---

    /**
     * @dev Governance or approved sponsor creates a new sponsorship pool for a specific research category.
     * @param _category The category this pool is for.
     * @param _description A brief description of the pool's purpose.
     */
    function createSponsorshipPool(string calldata _category, string calldata _description) external onlyOwner categoryExists(_category) {
        if (categoryToPoolId[_category] != 0) {
            revert CategoryAlreadyExists(_category); // A category can only have one main pool
        }

        poolCounter++;
        uint256 newPoolId = poolCounter;

        sponsorshipPools[newPoolId] = SponsorshipPool({
            id: newPoolId,
            creator: msg.sender,
            category: _category,
            description: _description,
            totalAmount: 0,
            isActive: true
        });
        categoryToPoolId[_category] = newPoolId;

        emit SponsorshipPoolCreated(newPoolId, _category, msg.sender, 0);
    }

    /**
     * @dev Users contribute ETH to a specific sponsorship pool.
     * @param _poolId The ID of the pool to contribute to.
     */
    function contributeToSponsorshipPool(uint256 _poolId) external payable {
        SponsorshipPool storage pool = sponsorshipPools[_poolId];
        if (!pool.isActive) {
            revert SponsorshipPoolNotFound(_poolId); // Using same error for clarity
        }
        require(msg.value > 0, "Contribution must be greater than zero");

        pool.totalAmount += msg.value;
        emit FundsContributedToPool(_poolId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the discoverer to claim their reward once a discovery is validated and funded.
     * Mints an Insight NFT upon successful claim.
     * @param _discoveryId The ID of the discovery to claim reward for.
     */
    function claimDiscoveryReward(uint256 _discoveryId) external discoveryExists(_discoveryId) {
        Discovery storage discovery = discoveries[_discoveryId];

        if (discovery.discoverer != msg.sender) {
            revert UnauthorizedAction(msg.sender, "Discoverer of this discovery");
        }
        if (discovery.status != DiscoveryStatus.VALIDATED) {
            revert DiscoveryNotValidated(_discoveryId);
        }
        if (discovery.sponsorshipAmount > 0) {
            revert RewardAlreadyClaimed(_discoveryId); // Already sponsored and claimed
        }

        // Check for available funds in the category's sponsorship pool
        uint256 poolId = categoryToPoolId[discovery.category];
        if (poolId == 0 || !sponsorshipPools[poolId].isActive) {
            revert SponsorshipPoolNotFound(poolId);
        }
        
        SponsorshipPool storage pool = sponsorshipPools[poolId];
        uint256 rewardAmount = _calculateReward(_discoveryId);

        if (pool.totalAmount < rewardAmount) {
            revert InsufficientFundsInPool(poolId, rewardAmount);
        }

        // Transfer reward
        pool.totalAmount -= rewardAmount;
        discovery.sponsorshipAmount = rewardAmount; // Record the amount paid
        (bool success, ) = discovery.discoverer.call{value: rewardAmount}("");
        require(success, "Failed to transfer reward");

        // Mint Insight NFT
        uint256 newNFTId = _mintInsightNFT(_discoveryId, msg.sender);
        discovery.insightNFTId = newNFTId;
        discovery.status = DiscoveryStatus.REWARDED;

        emit DiscoveryRewardClaimed(_discoveryId, msg.sender, rewardAmount, newNFTId);
    }

    /**
     * @dev Allows the original sponsor of a pool to withdraw any remaining, unused funds.
     * Only the pool creator can withdraw.
     * @param _poolId The ID of the sponsorship pool.
     */
    function withdrawUnusedSponsorship(uint256 _poolId) external {
        SponsorshipPool storage pool = sponsorshipPools[_poolId];
        if (!pool.isActive || pool.creator != msg.sender) {
            revert UnauthorizedAction(msg.sender, "Sponsor of this pool");
        }
        
        uint256 amountToWithdraw = pool.totalAmount;
        require(amountToWithdraw > 0, "No unused funds to withdraw");

        pool.totalAmount = 0; // Clear the balance in the contract
        (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        require(success, "Failed to withdraw unused sponsorship");

        emit UnusedSponsorshipWithdrawn(_poolId, msg.sender, amountToWithdraw);
    }

    /**
     * @dev Internal function to calculate the reward for a validated discovery.
     * Reward is based on impact score and a global reward coefficient.
     * @param _discoveryId The ID of the discovery.
     * @return The calculated reward amount in wei.
     */
    function _calculateReward(uint256 _discoveryId) internal view returns (uint256) {
        Discovery storage discovery = discoveries[_discoveryId];
        // Example: Reward = currentImpactScore * rewardCoefficient * (1 + (time_since_submission / 1 day))
        // This is a simple example; a real system might use more complex curves or external data.
        uint256 ageBonus = (block.timestamp - discovery.timestamp) / 1 days; // Bonus for quicker validation/sponsorship
        if (ageBonus > 10) ageBonus = 10; // Cap bonus

        return (discovery.currentImpactScore * rewardCoefficient) + (ageBonus * 10**17); // Base + age bonus
    }

    // --- 4. Insight NFT Management ---

    /**
     * @dev Internal function to mint an Insight NFT when a discovery is successfully validated and rewarded.
     * @param _discoveryId The ID of the discovery that led to this NFT.
     * @param _to The address to mint the NFT to (the discoverer).
     * @return The ID of the newly minted NFT.
     */
    function _mintInsightNFT(uint256 _discoveryId, address _to) internal returns (uint256) {
        Discovery storage discovery = discoveries[_discoveryId];
        string memory tokenURI = string(abi.encodePacked("ipfs://", discovery.metadataHash)); // Example URI

        uint256 nftId = INSIGHT_NFT.mintInsight(_to, _discoveryId, tokenURI);
        return nftId;
    }

    // --- 5. Dynamic Impact & Relevance ---

    /**
     * @dev Allows anyone (or a keeper bot) to trigger a periodic decay of impact scores for specified discoveries.
     * This ensures older, less relevant discoveries gradually lose their "impact".
     * A small gas incentive could be added for calling this.
     * @param _discoveryIds An array of discovery IDs to process for decay.
     */
    function decayImpactScores(uint256[] calldata _discoveryIds) external {
        for (uint256 i = 0; i < _discoveryIds.length; i++) {
            uint256 id = _discoveryIds[i];
            Discovery storage discovery = discoveries[id];
            
            // Only decay validated/rewarded discoveries
            if (discovery.status == DiscoveryStatus.VALIDATED || discovery.status == DiscoveryStatus.REWARDED) {
                // Decay based on time elapsed since last significant update or last decay
                // Simplified: Decay daily
                uint256 daysSinceLastDecay = (block.timestamp - discovery.timestamp) / 1 days; // Placeholder for actual last decay timestamp

                if (daysSinceLastDecay > 0) {
                    uint256 decayAmount = (discovery.currentImpactScore * impactDecayRate * daysSinceLastDecay) / 100;
                    if (decayAmount > discovery.currentImpactScore) {
                        decayAmount = discovery.currentImpactScore; // Prevent negative scores
                    }
                    discovery.currentImpactScore -= decayAmount;
                    emit ImpactScoreDecayed(id, discovery.currentImpactScore, decayAmount);
                }
            }
        }
    }

    /**
     * @dev Allows the discoverer or governance to update details that might refresh its relevance score.
     * E.g., if new data makes an old discovery relevant again. This could reset its decay timer.
     * @param _discoveryId The ID of the discovery to update.
     * @param _newMetadataHash New metadata hash (e.g., pointing to updated research).
     * @param _newUrl New URL.
     */
    function updateDiscoveryRelevance(uint256 _discoveryId, string calldata _newMetadataHash, string calldata _newUrl) external discoveryExists(_discoveryId) {
        Discovery storage discovery = discoveries[_discoveryId];
        // Only discoverer or owner can update relevance
        require(discovery.discoverer == msg.sender || owner() == msg.sender, "Only discoverer or owner can update relevance.");

        // Update metadata and reset relevant decay timers (conceptual)
        discovery.metadataHash = _newMetadataHash;
        discovery.url = _newUrl;
        discovery.timestamp = block.timestamp; // Resets the effective "last updated" time for decay purposes

        emit DiscoveryRelevanceUpdated(_discoveryId, _newMetadataHash, _newUrl);
    }

    // --- 6. Governance (DAO Integration) ---

    /**
     * @dev Allows a CRST token holder to propose a change to a protocol parameter.
     * Requires minimum CRST stake to propose.
     * @param _description A description of the proposal.
     * @param _targetParam The name of the parameter to change (e.g., "validationThreshold").
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string calldata _description, string calldata _targetParam, uint256 _newValue) external {
        uint256 proposerVotes = CRST_TOKEN.getVotes(msg.sender);
        if (proposerVotes < minProposalStake) {
            revert InsufficientVotingPower(msg.sender, minProposalStake);
        }

        ProposalType pType;
        if (keccak256(abi.encodePacked(_targetParam)) == keccak256(abi.encodePacked("validationThreshold"))) {
            pType = ProposalType.SET_VALIDATION_THRESHOLD;
            require(_newValue <= 100, "Validation threshold must be <= 100");
        } else if (keccak256(abi.encodePacked(_targetParam)) == keccak256(abi.encodePacked("rewardCoefficient"))) {
            pType = ProposalType.SET_REWARD_COEFFICIENT;
        } else if (keccak256(abi.encodePacked(_targetParam)) == keccak256(abi.encodePacked("impactDecayRate"))) {
            pType = ProposalType.SET_DECAY_RATE;
            require(_newValue <= 100, "Decay rate must be <= 100");
        } else {
            revert InvalidProposalValue(_targetParam);
        }

        proposalCounter++;
        uint256 newProposalId = proposalCounter;

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            pType: pType,
            targetParam: _targetParam,
            newValue: _newValue,
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.ACTIVE
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, pType, _newValue);
    }

    /**
     * @dev Allows a CRST token holder to vote on an active governance proposal.
     * Voting power is based on staked CRST (conceptual: via CRST_TOKEN.getVotes()).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) { // Check for existence
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.status != ProposalStatus.ACTIVE) {
            revert InvalidProposalStatus(_proposalId, "ACTIVE");
        }
        if (block.timestamp > proposal.votingDeadline) {
            revert VotingPeriodActive(_proposalId); // Should be: VotingPeriodEnded
        }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted(_proposalId, msg.sender);
        }

        uint256 voterVotes = CRST_TOKEN.getVotes(msg.sender);
        if (voterVotes == 0) {
            revert InsufficientVotingPower(msg.sender, 1); // Need at least 1 vote
        }

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterVotes;
        } else {
            proposal.votesAgainst += voterVotes;
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterVotes);
    }

    /**
     * @dev Executes a governance proposal if it has passed its voting period and met the quorum.
     * Can be called by anyone.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert ProposalNotFound(_proposalId);
        }
        if (proposal.status == ProposalStatus.EXECUTED) {
            revert ProposalAlreadyExecuted(_proposalId);
        }
        if (block.timestamp <= proposal.votingDeadline) {
            revert ProposalNotYetExecutable(_proposalId);
        }

        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        uint256 totalCRSTSupply = CRST_TOKEN.totalSupply(); // Or CRST_TOKEN.totalStaked() for relevance
        uint256 requiredQuorum = (totalCRSTSupply * proposalVoteQuorum) / 100;

        if (totalVotesCast < requiredQuorum || proposal.votesFor <= proposal.votesAgainst) {
            proposal.status = ProposalStatus.FAILED;
            // Additional logic for failed proposals if needed (e.g., return stake)
        } else {
            // Execute the parameter change
            if (proposal.pType == ProposalType.SET_VALIDATION_THRESHOLD) {
                validationThreshold = proposal.newValue;
            } else if (proposal.pType == ProposalType.SET_REWARD_COEFFICIENT) {
                rewardCoefficient = proposal.newValue;
            } else if (proposal.pType == ProposalType.SET_DECAY_RATE) {
                impactDecayRate = proposal.newValue;
            } else {
                revert InvalidProposalValue(proposal.targetParam); // Should not happen if pType is correct
            }
            proposal.status = ProposalStatus.EXECUTED;
        }
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Governance function to add a new valid category for discoveries.
     * @param _categoryName The name of the new category.
     */
    function addDiscoveryCategory(string calldata _categoryName) external onlyOwner {
        if (approvedCategories[_categoryName]) {
            revert CategoryAlreadyExists(_categoryName);
        }
        approvedCategories[_categoryName] = true;
        emit CategoryAdded(_categoryName);
    }

    /**
     * @dev Governance function to remove an existing discovery category.
     * Prevents new submissions to this category, but existing discoveries remain.
     * @param _categoryName The name of the category to remove.
     */
    function removeDiscoveryCategory(string calldata _categoryName) external onlyOwner {
        if (!approvedCategories[_categoryName]) {
            revert CategoryDoesNotExist(_categoryName);
        }
        approvedCategories[_categoryName] = false;
        emit CategoryRemoved(_categoryName);
    }

    // --- 7. Utility & Getters ---

    /**
     * @dev Returns the total ETH held by the contract.
     */
    function getProtocolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total number of registered oracles.
     */
    function getOracleCount() external view returns (uint256) {
        return oracleCounter;
    }

    /**
     * @dev Returns the current ETH balance of a specific sponsorship pool.
     * @param _poolId The ID of the sponsorship pool.
     */
    function getSponsorshipPoolBalance(uint256 _poolId) external view returns (uint256) {
        SponsorshipPool storage pool = sponsorshipPools[_poolId];
        if (!pool.isActive) {
            revert SponsorshipPoolNotFound(_poolId);
        }
        return pool.totalAmount;
    }

    // Fallback function to receive ETH
    receive() external payable {
        // Optionally add a log here if direct ETH deposits are expected for anything other than specific calls.
    }
}
```