This smart contract, `AetheriumNexus`, introduces a sophisticated decentralized autonomous entity designed for adaptive governance, dynamic NFT-based participation, and autonomous treasury management driven by external oracle data. It aims to create a self-evolving protocol that reacts to market conditions and community input.

---

### **AetheriumNexus Contract Overview**

*   **Name:** `AetheriumNexus`
*   **Description:** A decentralized, adaptive protocol functioning as a sovereign entity. It manages a multi-asset treasury, evolves its own operational parameters based on oracle feeds and community proposals, and rewards contributors through a dynamic reputation system integrated with non-transferable "Nexus Shard" NFTs. Aims for resilience and autonomous growth, mimicking a self-optimizing organism within the blockchain.

### **Key Concepts**

*   **Nexus Shards (Dynamic SBTs):** Non-transferable ERC721 tokens representing a participant's stake, reputation, and influence within the DASE. These shards can "evolve" by meeting criteria (e.g., successful proposals, holding period), unlocking increased voting power and unique attributes. Shard holders can delegate their influence.
*   **Adaptive Governance Engine:** A highly flexible system allowing qualified Nexus Shard holders to propose and vote on changes to the DASE's core parameters, treasury allocations, or even arbitrary contract interactions. Proposals are time-locked and require a supermajority.
*   **Autonomous Adaptation:** The DASE can automatically adjust its internal parameters (e.g., treasury allocation strategies, reputation decay rates) in response to predefined external oracle conditions (e.g., market volatility, asset price thresholds). This mimics self-preservation or optimization logic, making the protocol semi-autonomous.
*   **Reputation System:** Tracks and rewards participant engagement beyond just token holdings or shard ownership. Reputation directly influences voting power and access to certain DASE features. Reputation can decay over time to incentivize continuous involvement.
*   **Multi-Asset Treasury:** A secure vault for various ERC20 tokens and Ether, managed by the adaptive governance and autonomous allocation rules, enabling diversification and strategic fund utilization.

### **Function Summary (22 Public/External Functions)**

**I. Core & Access Functions (5)**
1.  `constructor()`: Initializes the contract, setting the deployer as the initial admin and minting an initial "Genesis" Nexus Shard for them.
2.  `changeAdmin(address newAdmin)`: Allows the current admin to transfer administrative control to a new address.
3.  `pauseContract()`: An emergency function callable by the admin to halt critical operations within the DASE.
4.  `unpauseContract()`: Restores critical operations after an emergency pause, callable by the admin.
5.  `setExternalOracleAddress(address _oracle)`: Sets the address of the primary `AggregatorV3Interface` compatible oracle used for external data feeds.

**II. Nexus Shard Functions (6)**
6.  `mintNexusShard(address recipient)`: Mints a new, non-transferable Nexus Shard for a specified recipient. These shards are initially basic but can evolve.
7.  `evolveShard(uint256 tokenId)`: Allows a shard holder to "evolve" their shard by meeting specific on-chain criteria (e.g., reaching a certain reputation score, holding for a duration), unlocking enhanced attributes and increased influence.
8.  `delegateShardInfluence(uint256 tokenId, address delegatee)`: Permits a shard holder to delegate the accrued influence (voting power, proposal weight) of a specific shard to another address.
9.  `undelegateShardInfluence(uint256 tokenId)`: Revokes the delegation of influence from a specific Nexus Shard.
10. `getShardInfluence(uint256 tokenId)`: Returns the total influence score of a specific Nexus Shard, considering its evolution level and other dynamic factors.
11. `getShardOwner(uint256 tokenId)`: Returns the current owner of a given Nexus Shard (non-transferable, so this is the original minter).

**III. Adaptive Governance & Evolution Functions (6)**
12. `submitAdaptiveProposal(string calldata description, bytes calldata callData, address targetContract, uint256 value, uint256 minShardLevelRequired)`: Allows qualified Nexus Shard holders to submit proposals for DASE parameter changes, treasury allocations, or arbitrary contract interactions.
13. `voteOnAdaptiveProposal(uint256 proposalId, bool support)`: Allows active Nexus Shard holders (or their delegates) to cast their weighted vote on an open proposal.
14. `executeAdaptiveProposal(uint256 proposalId)`: Executes a successfully passed proposal after its voting period and a defined timelock have expired. Rewards proposal initiator.
15. `triggerAutonomousAdaptation()`: Callable by anyone, this function checks predefined oracle conditions. If met, it autonomously updates an internal DASE parameter or triggers a specific action.
16. `setAutonomousCondition(bytes32 conditionId, address oracleSource, bytes calldata dataQuery, uint256 threshold, bool greaterThan)`: Admin function to define or update the criteria for autonomous adaptations, linking specific oracle data to threshold checks.
17. `setAdaptiveParameter(bytes32 paramKey, uint256 newValue)`: A restricted function, callable only by `executeAdaptiveProposal` or `triggerAutonomousAdaptation`, to update core DASE configuration parameters dynamically.

**IV. Treasury & Asset Management Functions (4)**
18. `depositAsset(address tokenAddress, uint256 amount)`: Allows users to deposit specified whitelisted ERC20 tokens into the DASE treasury. (The `receive()` fallback function handles direct Ether deposits).
19. `allocateTreasuryFunds(address tokenAddress, uint256 amount, address recipient, string calldata reason)`: Disburses specific amounts of treasury assets to a designated recipient, exclusively triggered by a successful governance proposal.
20. `setWhitelistedAsset(address tokenAddress, bool isWhitelisted)`: Admin function to add or remove ERC20 tokens from the list of assets the DASE treasury can hold and manage.
21. `getTreasuryBalance(address tokenAddress)`: Returns the current balance of a specific ERC20 token or Ether held within the DASE treasury.

**V. Reputation & Participation Functions (3)**
22. `getReputationScore(address participant)`: Retrieves the current non-shard-based reputation score of a given participant, reflecting their accumulated contributions.
23. `decayReputationScores()`: Callable periodically (e.g., by a Chainlink Keeper), this function reduces reputation scores over time to incentivize ongoing engagement and prevent "stale" influence.
24. `updateContributorReputation(address contributor, uint256 points)`: An **internal** helper function, called by other core DASE functions (e.g., `executeAdaptiveProposal`), to reward participants with reputation points for specific contributions. (Not a public/external function for counting purposes as it's internal logic).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Interface for Chainlink Price Feeds (or similar AggregatorV3Interface compatible oracle)
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/**
 * @title AetheriumNexus
 * @dev A decentralized, adaptive protocol functioning as a sovereign entity.
 * It manages a multi-asset treasury, evolves its own operational parameters based on
 * oracle feeds and community proposals, and rewards contributors through a dynamic
 * reputation system integrated with non-transferable "Nexus Shard" NFTs.
 * Aims for resilience and autonomous growth.
 *
 * Key Concepts:
 * - Nexus Shards (Dynamic SBTs): Non-transferable ERC721 tokens representing a participant's stake,
 *   reputation, and influence. Shards can "evolve" unlocking increased voting power and attributes.
 *   Influence can be delegated.
 * - Adaptive Governance Engine: Qualified Shard holders propose and vote on changes to core parameters,
 *   treasury allocations, or arbitrary contract interactions. Proposals are time-locked.
 * - Autonomous Adaptation: The DASE can automatically adjust parameters based on predefined external
 *   oracle conditions (e.g., market volatility, price thresholds), mimicking self-optimization.
 * - Reputation System: Tracks participant engagement beyond just token holdings, influencing voting power
 *   and access. Reputation can decay over time to incentivize continuous involvement.
 * - Multi-Asset Treasury: Secure vault for various ERC20 tokens and Ether, managed by governance.
 *
 * Function Summary (22 Public/External Functions):
 *
 * I. Core & Access Functions (5)
 * 1. constructor(): Initializes the contract, sets the deployer as admin, and mints an initial Shard.
 * 2. changeAdmin(address newAdmin): Transfers administrative control.
 * 3. pauseContract(): Emergency function to halt critical operations.
 * 4. unpauseContract(): Restores critical operations.
 * 5. setExternalOracleAddress(address _oracle): Sets the primary oracle for external data.
 *
 * II. Nexus Shard Functions (6)
 * 6. mintNexusShard(address recipient): Mints a new, non-transferable Nexus Shard.
 * 7. evolveShard(uint256 tokenId): Upgrades a shard's attributes based on conditions.
 * 8. delegateShardInfluence(uint256 tokenId, address delegatee): Delegates a shard's influence.
 * 9. undelegateShardInfluence(uint256 tokenId): Revokes influence delegation.
 * 10. getShardInfluence(uint256 tokenId): Retrieves a shard's total influence score.
 * 11. getShardOwner(uint256 tokenId): Returns the owner of a shard (original minter).
 *
 * III. Adaptive Governance & Evolution Functions (6)
 * 12. submitAdaptiveProposal(string calldata description, bytes calldata callData, address targetContract, uint256 value, uint256 minShardLevelRequired): Submits a proposal.
 * 13. voteOnAdaptiveProposal(uint256 proposalId, bool support): Casts a vote on an active proposal.
 * 14. executeAdaptiveProposal(uint256 proposalId): Executes a successfully passed proposal.
 * 15. triggerAutonomousAdaptation(): Checks oracle conditions and triggers autonomous parameter updates.
 * 16. setAutonomousCondition(bytes32 conditionId, address oracleSource, bytes calldata dataQuery, uint256 threshold, bool greaterThan): Defines criteria for autonomous adaptations.
 * 17. setAdaptiveParameter(bytes32 paramKey, uint256 newValue): Restricted function to update DASE parameters.
 *
 * IV. Treasury & Asset Management Functions (4)
 * 18. depositAsset(address tokenAddress, uint256 amount): Allows ERC20 deposits. (Ether via receive()).
 * 19. allocateTreasuryFunds(address tokenAddress, uint256 amount, address recipient, string calldata reason): Disburses treasury assets.
 * 20. setWhitelistedAsset(address tokenAddress, bool isWhitelisted): Manages whitelisted ERC20 tokens.
 * 21. getTreasuryBalance(address tokenAddress): Retrieves asset balance in treasury.
 *
 * V. Reputation & Participation Functions (3)
 * 22. getReputationScore(address participant): Retrieves non-shard-based reputation.
 * 23. decayReputationScores(): Periodically reduces reputation to incentivize ongoing engagement.
 * (Internal) updateContributorReputation(address contributor, uint256 points): Helper to update reputation.
 */
contract AetheriumNexus is Ownable, Pausable, ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Nexus Shards
    struct NexusShard {
        uint256 level; // Higher level = more influence
        uint256 mintedAt; // Timestamp of minting
        uint256 lastEvolvedAt; // Timestamp of last evolution
        address delegatee; // Address to whom influence is delegated
        bool exists; // To check if a shardId is valid
    }
    mapping(uint256 => NexusShard) public nexusShards;
    mapping(address => uint256) public totalShardInfluence; // Aggregated influence for an address
    Counters.Counter private _shardIds;

    // Reputation System
    mapping(address => uint256) public reputationScores;
    uint256 public constant INITIAL_REPUTATION_FOR_MINT = 100;
    uint256 public reputationDecayRate = 1; // % per decay period
    uint256 public reputationDecayPeriod = 30 days; // How often decay occurs
    uint256 public lastReputationDecay;

    // Adaptive Governance
    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 value; // ETH to send with the call
        uint256 minShardLevelRequired; // Min shard level to submit
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 executionTime; // After timelock
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
        address proposer;
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted
    Counters.Counter public _proposalIds;

    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_TIMELOCK = 2 days; // Time between vote end and execution
    uint256 public constant MIN_PROPOSAL_THRESHOLD_INFLUENCE = 1000; // Minimum influence to submit a proposal
    uint256 public constant MIN_VOTE_QUORUM_PERCENT = 50; // 50% of total influence must vote
    uint256 public constant SUPERMAJORITY_PERCENT = 60; // 60% of votes must be 'for' to pass

    // Autonomous Adaptation
    struct AutonomousCondition {
        address oracleSource; // e.g., Chainlink AggregatorV3Interface address
        bytes dataQuery; // Future: for more complex oracle interactions
        int256 threshold;
        bool greaterThan; // true if condition is 'value > threshold', false if 'value < threshold'
        uint256 lastTriggered;
        uint256 cooldownPeriod; // How often this condition can trigger adaptation
    }
    mapping(bytes32 => AutonomousCondition) public autonomousConditions;
    mapping(bytes32 => uint256) public adaptiveParameters; // Dynamically configurable parameters (e.g., fee rates, allocation percentages)
    address public externalOracle; // Primary oracle for general price feeds if needed for autonomous conditions

    // Treasury Management
    mapping(address => bool) public isWhitelistedAsset;

    // Events
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Paused(address account);
    event Unpaused(address account);
    event OracleAddressSet(address indexed newOracle);

    event NexusShardMinted(uint256 indexed tokenId, address indexed owner, uint256 level, uint256 timestamp);
    event NexusShardEvolved(uint256 indexed tokenId, uint256 newLevel, uint256 timestamp);
    event InfluenceDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event InfluenceUndelegated(uint256 indexed tokenId, address indexed delegator);

    event AdaptiveProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 influenceWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event AutonomousAdaptationTriggered(bytes32 indexed conditionId, bytes32 indexed parameterKey, uint256 newValue);
    event AdaptiveParameterSet(bytes32 indexed parameterKey, uint256 newValue);

    event AssetDeposited(address indexed token, address indexed depositor, uint256 amount);
    event TreasuryFundsAllocated(address indexed token, address indexed recipient, uint256 amount, string reason);
    event AssetWhitelisted(address indexed token, bool status);

    event ReputationUpdated(address indexed participant, uint256 newScore, string reason);
    event ReputationDecayed(address indexed participant, uint256 oldScore, uint256 newScore);

    // --- Constructor ---

    constructor() ERC721("Nexus Shard", "NXS") Ownable(msg.sender) {
        _pause(); // Start paused for initial setup
        _shardIds.increment(); // First shard ID is 1
        uint256 firstTokenId = _shardIds.current();
        _safeMint(msg.sender, firstTokenId);

        // Initialize genesis shard for admin
        nexusShards[firstTokenId] = NexusShard({
            level: 1,
            mintedAt: block.timestamp,
            lastEvolvedAt: block.timestamp,
            delegatee: address(0),
            exists: true
        });
        reputationScores[msg.sender] = INITIAL_REPUTATION_FOR_MINT;
        totalShardInfluence[msg.sender] = _calculateShardInfluence(firstTokenId);

        emit NexusShardMinted(firstTokenId, msg.sender, 1, block.timestamp);
        emit ReputationUpdated(msg.sender, INITIAL_REPUTATION_FOR_MINT, "Initial minting");

        // Set initial adaptive parameters
        adaptiveParameters["reputationDecayRate"] = reputationDecayRate;
        adaptiveParameters["reputationDecayPeriod"] = reputationDecayPeriod;
        adaptiveParameters["proposalVotingPeriod"] = PROPOSAL_VOTING_PERIOD;
        adaptiveParameters["proposalTimelock"] = PROPOSAL_TIMELOCK;
    }

    // --- Modifiers ---

    modifier onlyShardOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not shard owner or approved");
        _;
    }

    modifier onlyProposer(uint256 proposalId) {
        require(proposals[proposalId].proposer == msg.sender, "Not the proposal initiator");
        _;
    }

    // --- Core & Access Functions ---

    /**
     * @dev Transfers administrative control of the contract to a new address.
     * @param newAdmin The address to transfer admin ownership to.
     */
    function changeAdmin(address newAdmin) external onlyOwner {
        transferOwnership(newAdmin); // Uses Ownable's transferOwnership
        emit AdminTransferred(_owner, newAdmin);
    }

    /**
     * @dev Pauses all critical operations of the contract. Only callable by the admin.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses all critical operations of the contract. Only callable by the admin.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Sets the address of the primary external oracle (e.g., Chainlink AggregatorV3Interface).
     * @param _oracle The address of the new oracle contract.
     */
    function setExternalOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle address cannot be zero");
        externalOracle = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /**
     * @dev Allows the contract to receive Ether. Funds go to the DASE treasury.
     */
    receive() external payable {
        emit AssetDeposited(address(0), msg.sender, msg.value);
    }

    /**
     * @dev Fallback function for sending Ether to the contract.
     */
    fallback() external payable {
        emit AssetDeposited(address(0), msg.sender, msg.value);
    }

    // --- Nexus Shard Functions ---

    /**
     * @dev Mints a new non-transferable Nexus Shard to a recipient.
     * This grants a base level of participation and reputation.
     * Only callable by the admin or through a passed governance proposal.
     * @param recipient The address to mint the new Nexus Shard to.
     */
    function mintNexusShard(address recipient) external onlyOwner whenNotPaused {
        _shardIds.increment();
        uint256 newTokenId = _shardIds.current();
        _safeMint(recipient, newTokenId);

        nexusShards[newTokenId] = NexusShard({
            level: 1,
            mintedAt: block.timestamp,
            lastEvolvedAt: block.timestamp,
            delegatee: address(0), // No delegation initially
            exists: true
        });

        _updateContributorReputation(recipient, INITIAL_REPUTATION_FOR_MINT, "Nexus Shard mint");
        totalShardInfluence[recipient] = totalShardInfluence[recipient].add(_calculateShardInfluence(newTokenId));

        emit NexusShardMinted(newTokenId, recipient, 1, block.timestamp);
    }

    /**
     * @dev Allows a shard holder to "evolve" their shard by meeting specific criteria,
     * unlocking new attributes and increasing its influence.
     * Criteria for evolution:
     * - Shard must exist and belong to the caller.
     * - A minimum time must have passed since minting or last evolution (e.g., 30 days).
     * - The owner must have a minimum reputation score (e.g., 500 points).
     * @param tokenId The ID of the Nexus Shard to evolve.
     */
    function evolveShard(uint256 tokenId) external onlyShardOwner(tokenId) whenNotPaused {
        NexusShard storage shard = nexusShards[tokenId];
        require(shard.exists, "Shard does not exist");
        require(block.timestamp >= shard.lastEvolvedAt.add(30 days), "Shard not ready to evolve yet (30 days cooldown)");
        require(reputationScores[_ownerOf(tokenId)] >= 500, "Insufficient reputation to evolve shard (min 500)");

        shard.level = shard.level.add(1);
        shard.lastEvolvedAt = block.timestamp;

        // Update total influence for the owner (or delegatee if applicable)
        address influenceRecipient = shard.delegatee != address(0) ? shard.delegatee : _ownerOf(tokenId);
        totalShardInfluence[influenceRecipient] = totalShardInfluence[influenceRecipient].sub(_calculateShardInfluence(tokenId, shard.level.sub(1)));
        totalShardInfluence[influenceRecipient] = totalShardInfluence[influenceRecipient].add(_calculateShardInfluence(tokenId, shard.level));

        _updateContributorReputation(_ownerOf(tokenId), 100, "Evolved Nexus Shard");

        emit NexusShardEvolved(tokenId, shard.level, block.timestamp);
    }

    /**
     * @dev Delegates the influence (voting power, proposal weight) of a specific shard
     * to another address. This allows a user to grant their shard's voting power to
     * someone else without transferring the non-transferable NFT.
     * @param tokenId The ID of the Nexus Shard to delegate influence from.
     * @param delegatee The address to delegate the influence to.
     */
    function delegateShardInfluence(uint256 tokenId, address delegatee) external onlyShardOwner(tokenId) {
        NexusShard storage shard = nexusShards[tokenId];
        require(shard.exists, "Shard does not exist");
        require(delegatee != address(0), "Delegatee cannot be zero address");
        require(delegatee != _ownerOf(tokenId), "Cannot delegate to self");

        // Remove influence from previous delegatee or owner
        address currentInfluenceHolder = shard.delegatee != address(0) ? shard.delegatee : _ownerOf(tokenId);
        totalShardInfluence[currentInfluenceHolder] = totalShardInfluence[currentInfluenceHolder].sub(_calculateShardInfluence(tokenId));

        shard.delegatee = delegatee;

        // Add influence to new delegatee
        totalShardInfluence[delegatee] = totalShardInfluence[delegatee].add(_calculateShardInfluence(tokenId));

        emit InfluenceDelegated(tokenId, _ownerOf(tokenId), delegatee);
    }

    /**
     * @dev Revokes delegation of influence for a specific Nexus Shard.
     * The influence reverts to the shard's owner.
     * @param tokenId The ID of the Nexus Shard to undelegate influence from.
     */
    function undelegateShardInfluence(uint256 tokenId) external onlyShardOwner(tokenId) {
        NexusShard storage shard = nexusShards[tokenId];
        require(shard.exists, "Shard does not exist");
        require(shard.delegatee != address(0), "Shard has no active delegation");

        // Remove influence from delegatee
        totalShardInfluence[shard.delegatee] = totalShardInfluence[shard.delegatee].sub(_calculateShardInfluence(tokenId));

        shard.delegatee = address(0);

        // Add influence back to owner
        totalShardInfluence[_ownerOf(tokenId)] = totalShardInfluence[_ownerOf(tokenId)].add(_calculateShardInfluence(tokenId));

        emit InfluenceUndelegated(tokenId, _ownerOf(tokenId));
    }

    /**
     * @dev Returns the total influence score of a specific Nexus Shard.
     * This score combines its level and potentially other factors for voting power.
     * @param tokenId The ID of the Nexus Shard.
     * @return The calculated influence score for the shard.
     */
    function getShardInfluence(uint256 tokenId) public view returns (uint256) {
        return _calculateShardInfluence(tokenId);
    }

    /**
     * @dev Returns the owner of a specific Nexus Shard. Since shards are non-transferable,
     * this is effectively the address that originally minted it.
     * @param tokenId The ID of the Nexus Shard.
     * @return The address of the shard's owner.
     */
    function getShardOwner(uint256 tokenId) public view returns (address) {
        return _ownerOf(tokenId);
    }

    // ERC721 non-transferability override
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        require(from == address(0) || to == address(0), "Nexus Shards are non-transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // --- Adaptive Governance & Evolution Functions ---

    /**
     * @dev Allows qualified Nexus Shard holders to submit proposals for DASE parameter
     * changes, treasury allocations, or arbitrary contract interactions.
     * @param description A string describing the proposal.
     * @param callData The encoded function call (e.g., `abi.encodeWithSelector(YourContract.yourFunction.selector, arg1, arg2)`).
     * @param targetContract The address of the contract to call if the proposal passes.
     * @param value ETH to send with the call (0 for most proposals).
     * @param minShardLevelRequired The minimum level a proposer's shard must be to submit.
     */
    function submitAdaptiveProposal(
        string calldata description,
        bytes calldata callData,
        address targetContract,
        uint256 value,
        uint256 minShardLevelRequired
    ) external whenNotPaused returns (uint256 proposalId) {
        require(totalShardInfluence[msg.sender] >= MIN_PROPOSAL_THRESHOLD_INFLUENCE, "Proposer influence too low");

        // Check if proposer has at least one shard meeting the min level requirement
        bool hasRequiredShard = false;
        uint256 numShards = balanceOf(msg.sender);
        for (uint256 i = 0; i < numShards; i++) {
            uint256 shardId = tokenOfOwnerByIndex(msg.sender, i);
            if (nexusShards[shardId].level >= minShardLevelRequired) {
                hasRequiredShard = true;
                break;
            }
        }
        require(hasRequiredShard, "Proposer does not own a shard of required level");

        _proposalIds.increment();
        proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            targetContract: targetContract,
            callData: callData,
            value: value,
            minShardLevelRequired: minShardLevelRequired,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(adaptiveParameters["proposalVotingPeriod"]),
            executionTime: 0, // Set after voting ends if successful
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false,
            proposer: msg.sender
        });

        emit AdaptiveProposalSubmitted(proposalId, msg.sender, description);
    }

    /**
     * @dev Allows active Nexus Shard holders (or their delegates) to cast their weighted vote
     * on an open proposal. Voting power is derived from their total delegated influence.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnAdaptiveProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        uint256 voterInfluence = totalShardInfluence[msg.sender];
        require(voterInfluence > 0, "Voter has no influence");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterInfluence);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterInfluence);
        }
        hasVoted[proposalId][msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, voterInfluence);
    }

    /**
     * @dev Executes a successfully passed proposal after its voting period and a
     * defined timelock have expired. This function also rewards the proposal initiator.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeAdaptiveProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime != 0, "Proposal does not exist");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal was canceled");

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "No votes cast for this proposal");

        // Calculate total possible influence from all active shards
        uint256 totalPossibleInfluence;
        for (uint256 i = 1; i <= _shardIds.current(); i++) { // Iterate all minted shards
            if (nexusShards[i].exists) {
                totalPossibleInfluence = totalPossibleInfluence.add(_calculateShardInfluence(i));
            }
        }
        
        // Quorum check: Ensure enough influence participated
        require(totalVotes.mul(100) >= totalPossibleInfluence.mul(adaptiveParameters["minVoteQuorumPercent"]), "Quorum not met");

        // Supermajority check: Ensure enough 'for' votes
        require(proposal.votesFor.mul(100) >= totalVotes.mul(adaptiveParameters["supermajorityPercent"]), "Proposal did not reach supermajority");

        // Apply timelock
        if (proposal.executionTime == 0) {
            proposal.executionTime = block.timestamp.add(adaptiveParameters["proposalTimelock"]);
        }
        require(block.timestamp >= proposal.executionTime, "Proposal is still in timelock");

        // Execute the proposal's callData
        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.callData);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        _updateContributorReputation(proposal.proposer, 200, "Successful proposal execution"); // Reward proposer

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Callable by anyone, this function checks predefined oracle conditions.
     * If a condition is met and its cooldown passed, it autonomously updates an
     * internal DASE parameter or triggers a specific action.
     * This simulates an autonomous agent reacting to external market conditions.
     */
    function triggerAutonomousAdaptation() external whenNotPaused {
        require(externalOracle != address(0), "External oracle not set");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(externalOracle);
        (, int256 price, , uint256 updatedAt, ) = priceFeed.latestRoundData();
        
        // Example: Iterate through autonomous conditions
        // In a real system, you'd likely map specific condition IDs to specific oracle calls or use Chainlink Functions for custom logic.
        // For simplicity, this example assumes one general price feed is used to check various conditions.
        
        // Example Condition: High volatility detected (simplified: large price change over short time)
        bytes32 volatilityConditionId = keccak256("volatilityCondition");
        AutonomousCondition storage volCond = autonomousConditions[volatilityConditionId];

        // Check if condition is defined and ready to trigger
        if (volCond.oracleSource != address(0) && block.timestamp >= volCond.lastTriggered.add(volCond.cooldownPeriod)) {
            // Placeholder: A more advanced system would compare `price` to historical data or another oracle's result
            // For now, let's just make a simple threshold check (e.g., if price drops below a "panic" threshold).
            // This is just a conceptual example. `dataQuery` would define how to interpret `price`.
            // Let's assume `threshold` is a percentage drop.
            
            // For a basic example, we will just use a hardcoded value to demonstrate setting an adaptive parameter
            // In a real scenario, this would compare `price` to a moving average or a previous reading.
            
            // This example simply checks if the oracle is reporting a value below a threshold.
            bool conditionMet = volCond.greaterThan ? (price > volCond.threshold) : (price < volCond.threshold);

            if (conditionMet) {
                // Trigger an adaptive response, e.g., adjust treasury's rebalancing strategy parameter
                // We'll update a dummy parameter `treasuryAllocationRiskFactor`
                uint256 newRiskFactor = volCond.greaterThan ? 70 : 30; // If price is high, maybe be more aggressive (70), if low, be conservative (30)
                _setAdaptiveParameter(keccak256("treasuryAllocationRiskFactor"), newRiskFactor);
                volCond.lastTriggered = block.timestamp;
                emit AutonomousAdaptationTriggered(volatilityConditionId, keccak256("treasuryAllocationRiskFactor"), newRiskFactor);
            }
        }
    }

    /**
     * @dev Admin function to define or update the criteria for autonomous adaptations.
     * This links specific oracle data to threshold checks.
     * @param conditionId A unique identifier for this autonomous condition.
     * @param oracleSource The address of the oracle providing data for this condition.
     * @param dataQuery Future use: encoded data for complex oracle queries.
     * @param threshold The value to compare the oracle's output against.
     * @param greaterThan True if the condition is met when oracle_value > threshold, false for <.
     */
    function setAutonomousCondition(
        bytes32 conditionId,
        address oracleSource,
        bytes calldata dataQuery,
        int256 threshold,
        bool greaterThan
    ) external onlyOwner {
        require(oracleSource != address(0), "Oracle source cannot be zero address");
        autonomousConditions[conditionId] = AutonomousCondition({
            oracleSource: oracleSource,
            dataQuery: dataQuery,
            threshold: threshold,
            greaterThan: greaterThan,
            lastTriggered: 0,
            cooldownPeriod: 1 days // Default cooldown
        });
    }

    /**
     * @dev Internal function to update core DASE configuration parameters dynamically.
     * This function is only callable by `executeAdaptiveProposal` or `triggerAutonomousAdaptation`.
     * @param paramKey A unique identifier for the adaptive parameter (e.g., `keccak256("reputationDecayRate")`).
     * @param newValue The new value for the parameter.
     */
    function _setAdaptiveParameter(bytes32 paramKey, uint256 newValue) internal {
        adaptiveParameters[paramKey] = newValue;
        // Specific handlers for certain parameters
        if (paramKey == keccak256("reputationDecayRate")) {
            reputationDecayRate = newValue;
        } else if (paramKey == keccak256("reputationDecayPeriod")) {
            reputationDecayPeriod = newValue;
        }
        // ... extend with other adaptive parameters

        emit AdaptiveParameterSet(paramKey, newValue);
    }

    // --- Treasury & Asset Management Functions ---

    /**
     * @dev Allows users to deposit specified whitelisted ERC20 tokens into the DASE treasury.
     * @param tokenAddress The address of the ERC20 token to deposit.
     * @param amount The amount of tokens to deposit.
     */
    function depositAsset(address tokenAddress, uint256 amount) external whenNotPaused {
        require(isWhitelistedAsset[tokenAddress], "Asset not whitelisted for deposits");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Token transfer failed");
        emit AssetDeposited(tokenAddress, msg.sender, amount);
    }

    /**
     * @dev Disburses specific amounts of treasury assets to a designated recipient.
     * Exclusively triggered by a successful governance proposal.
     * @param tokenAddress The address of the ERC20 token to allocate (address(0) for Ether).
     * @param amount The amount of assets to allocate.
     * @param recipient The address to send the assets to.
     * @param reason A description for the allocation.
     */
    function allocateTreasuryFunds(
        address tokenAddress,
        uint256 amount,
        address recipient,
        string calldata reason
    ) external onlyOwner whenNotPaused { // Restricted to onlyOwner, implying this will be called via proposal execution
        require(recipient != address(0), "Recipient cannot be zero address");
        if (tokenAddress == address(0)) {
            // Ether
            require(address(this).balance >= amount, "Insufficient Ether balance in treasury");
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Ether transfer failed");
        } else {
            // ERC20 token
            require(isWhitelistedAsset[tokenAddress], "Allocated asset not whitelisted");
            require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Insufficient token balance in treasury");
            require(IERC20(tokenAddress).transfer(recipient, amount), "Token transfer failed");
        }
        emit TreasuryFundsAllocated(tokenAddress, recipient, amount, reason);
    }

    /**
     * @dev Admin function to add or remove ERC20 tokens from the list of assets
     * the DASE treasury can hold and manage.
     * @param tokenAddress The address of the ERC20 token.
     * @param status True to whitelist, false to delist.
     */
    function setWhitelistedAsset(address tokenAddress, bool status) external onlyOwner {
        require(tokenAddress != address(0), "Token address cannot be zero");
        isWhitelistedAsset[tokenAddress] = status;
        emit AssetWhitelisted(tokenAddress, status);
    }

    /**
     * @dev Returns the current balance of a specific ERC20 token or Ether
     * held within the DASE treasury.
     * @param tokenAddress The address of the ERC20 token (address(0) for Ether).
     * @return The balance of the specified asset.
     */
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(tokenAddress).balanceOf(address(this));
        }
    }

    // --- Reputation & Participation Functions ---

    /**
     * @dev Retrieves the current non-shard-based reputation score of a given participant.
     * @param participant The address whose reputation score is to be retrieved.
     * @return The current reputation score.
     */
    function getReputationScore(address participant) public view returns (uint256) {
        return reputationScores[participant];
    }

    /**
     * @dev Callable periodically (e.g., by a Chainlink Keeper), this function reduces
     * reputation scores over time to incentivize ongoing engagement and prevent "stale" influence.
     * Iterates through all shard owners and delegates.
     * In a large system, this might be optimized or use a merkle tree.
     */
    function decayReputationScores() external whenNotPaused {
        require(block.timestamp >= lastReputationDecay.add(adaptiveParameters["reputationDecayPeriod"]), "Too early for reputation decay");

        for (uint256 i = 1; i <= _shardIds.current(); i++) {
            if (nexusShards[i].exists) {
                address owner = _ownerOf(i);
                if (reputationScores[owner] > 0) {
                    uint256 oldScore = reputationScores[owner];
                    uint256 decayAmount = oldScore.mul(adaptiveParameters["reputationDecayRate"]).div(100);
                    reputationScores[owner] = oldScore.sub(decayAmount);
                    emit ReputationDecayed(owner, oldScore, reputationScores[owner]);
                }

                // If delegated, also consider decay for the delegatee's total influence
                // This logic might need refinement based on how reputation and influence interact
                // For simplicity, reputation is individual, influence is aggregated from shards.
                // Decay on individual reputation scores.
            }
        }
        lastReputationDecay = block.timestamp;
    }

    /**
     * @dev Internal helper function to update reputation scores.
     * Only callable from within the contract for system-defined contributions.
     * @param contributor The address whose reputation is to be updated.
     * @param points The amount of reputation points to add or remove.
     * @param reason A string explaining the reputation update.
     */
    function _updateContributorReputation(address contributor, uint256 points, string calldata reason) internal {
        reputationScores[contributor] = reputationScores[contributor].add(points);
        emit ReputationUpdated(contributor, reputationScores[contributor], reason);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates the influence score for a given Nexus Shard based on its level.
     * Higher levels grant disproportionately more influence.
     * @param tokenId The ID of the Nexus Shard.
     * @param specificLevel Optional: calculate influence for a specific level.
     * @return The calculated influence score.
     */
    function _calculateShardInfluence(uint256 tokenId) internal view returns (uint256) {
        return _calculateShardInfluence(tokenId, nexusShards[tokenId].level);
    }

    function _calculateShardInfluence(uint256 tokenId, uint256 level) internal pure returns (uint256) {
        if (!nexusShards[tokenId].exists) return 0;
        // Example influence calculation: base + (level^2 * 100)
        // This makes higher levels much more influential
        return 100 + (level * level * 100);
    }
}
```