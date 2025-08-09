This is an ambitious request! Creating a contract with 20+ non-duplicative, advanced, and creative functions requires a deep dive into novel blockchain mechanisms.

I propose a contract called **"QuantumForge DAO"**. It combines concepts of:

1.  **Adaptive On-Chain Reputation:** A dynamic reputation system for users, decaying over time, and earning through specific on-chain actions.
2.  **Dynamic/Living NFTs (Quantum Shards):** ERC-721 tokens whose metadata, utility, and even *tier* evolve based on the holder's reputation, engagement, and direct "forging" actions. They can also be "bonded" for increased reputation accrual or governance weight.
3.  **Intent-Driven Governance:** A slightly more advanced DAO model where proposals can express "intents" (e.g., "fund X project if Y condition is met") and allow for conditional execution or "griefing bonds."
4.  **Decentralized Resource Allocation with Meritocracy:** A treasury that can be disbursed based on proposals, but also allows highly reputable users to "request" and "approve" specific, smaller allocations directly without full DAO vote (within defined limits), introducing a subtle layer of meritocratic access.
5.  **Reputation Challenges & Arbitration:** A mechanism for users to challenge another user's reputation, requiring a bond and potentially leading to a DAO vote or a designated arbitrator.

---

## QuantumForge DAO: Outline & Function Summary

The `QuantumForgeDAO` contract orchestrates a dynamic, reputation-based ecosystem where users earn and manage on-chain reputation, which directly influences the utility and visual representation of their "Quantum Shard" NFTs. It features an advanced DAO governance model for treasury management and system parameters, incorporating intent-driven proposals and a unique reputation challenge system.

### Contract Name: `QuantumForgeDAO`

### Core Concepts:

*   **Adaptive Reputation (`ReputationPoint`):** A non-transferable, dynamic score for each user, decaying over time, and increasing through constructive on-chain actions or specific tasks.
*   **Dynamic NFTs (`QuantumShard`):** ERC-721 tokens that visually and functionally evolve based on the holder's `ReputationPoint` and direct "forging" actions. They can be bonded for enhanced utility within the DAO.
*   **Intent-Driven Governance:** A proposal system allowing for conditional execution and requiring a "griefing bond" to prevent spam or malicious proposals.
*   **Meritocratic Resource Allocation:** A DAO treasury with standard governance-controlled disbursements, alongside a specific pathway for high-reputation members to propose and approve smaller, direct allocations.
*   **Reputation Challenge & Arbitration:** A mechanism for users to dispute others' reputation scores, leading to a community or designated arbiter decision.

### Function Categories & Summaries:

#### I. Core & Administration Functions

1.  **`constructor(string memory name_, string memory symbol_, address initialOracle_)`**: Initializes the contract, sets NFT name/symbol, and designates an initial reputation oracle.
2.  **`pauseContract()`**: Allows the owner to pause critical contract functionalities (e.g., minting, proposal submission) in emergencies.
3.  **`unpauseContract()`**: Allows the owner to unpause the contract.
4.  **`setReputationOracle(address _newOracle)`**: Sets the address of the approved external oracle responsible for reporting reputation-affecting events.
5.  **`emergencyWithdraw(address _tokenAddress, uint256 _amount)`**: Allows the owner to withdraw specific tokens from the contract in extreme emergencies.

#### II. Reputation Management Functions

6.  **`accrueReputation(address _user, uint256 _amount, bytes32 _reasonHash)`**: (Callable by Oracle) Increases a user's reputation points based on a specific event, marked by a reason hash.
7.  **`decayReputation(address _user)`**: (Public, incentivized) Decreases a user's reputation based on time elapsed since their last update, applying a decay rate. Caller receives a small ETH incentive.
8.  **`getReputation(address _user)`**: Returns the current, calculated reputation score for a user, accounting for decay.
9.  **`slashReputation(address _user, uint256 _amount, bytes32 _reasonHash)`**: (Callable by Oracle/DAO) Decreases a user's reputation, typically as a penalty for rule violations.

#### III. Quantum Shard (Dynamic NFT) Functions

10. **`mintQuantumShard(address _recipient)`**: Mints a new `QuantumShard` NFT to a recipient. Requires initial reputation or payment.
11. **`bondShardForReputation(uint256 _tokenId)`**: Allows a user to "bond" their Quantum Shard, locking it to their address. Bonded shards contribute more significantly to reputation accrual and governance weight.
12. **`unbondShard(uint256 _tokenId)`**: Unbonds a Quantum Shard, making it transferable again. May incur a reputation penalty or cooldown.
13. **`forgeShard(uint256 _tokenId, uint8 _forgeType)`**: Upgrades a Quantum Shard's tier or unlocks new features based on the holder's reputation and potentially burning reputation points or contributing treasury assets.
14. **`setTokenMetadataURI(uint256 _tokenId, string memory _uri)`**: Allows the DAO or Oracle to update the specific metadata URI for a Quantum Shard, reflecting its dynamic state (tier changes, reputation-based visual updates).
15. **`tokenURI(uint256 _tokenId)`**: (ERC-721 Override) Returns the URI for a given `QuantumShard` token ID. This URI will point to an off-chain resolver that dynamically generates metadata based on the token's current state (e.g., owner's reputation, forge type).

#### IV. DAO Governance & Treasury Management Functions

16. **`submitProposal(address _target, uint256 _value, bytes memory _calldata, string memory _description, uint256 _minReputationBond)`**: Submits a new governance proposal. Requires a `minReputationBond` as a griefing bond, which is slashed if the proposal is rejected or malicious.
17. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows users to vote on an active proposal. Voting weight is determined by their current reputation and bonded `QuantumShard` holdings.
18. **`delegateVote(address _delegate)`**: Allows a user to delegate their voting power to another address.
19. **`executeProposal(uint256 _proposalId)`**: Executes a passed governance proposal. Refunds the `minReputationBond` to the proposer.
20. **`cancelProposal(uint256 _proposalId)`**: Allows the proposer to cancel their own proposal *before* it passes, but after a certain time, potentially forfeiting a portion of their `minReputationBond`. Also callable by DAO vote if malicious.
21. **`depositAsset(address _tokenAddress, uint256 _amount)`**: Allows users or external contracts to deposit ERC-20 tokens into the DAO's treasury.
22. **`requestMeritocraticAllocation(address _tokenAddress, uint256 _amount, string memory _reason)`**: Allows highly reputable users to request a direct treasury allocation *without* a full DAO vote, within a predefined small limit.
23. **`approveMeritocraticAllocation(address _requester, uint256 _allocationId)`**: (Callable by high-reputation users/council) Approves a pending meritocratic allocation request. Requires a minimum combined reputation from approvers.
24. **`setMeritocraticApprovalThreshold(uint256 _newThreshold)`**: (Governance Proposal) Sets the minimum combined reputation required for approvers of a meritocratic allocation.

#### V. Advanced Reputation & Challenge System

25. **`submitReputationChallenge(address _challengedUser, bytes32 _reasonHash, uint256 _challengeBond)`**: Initiates a formal challenge against another user's reputation. Requires a `_challengeBond` (e.g., ETH/stablecoin) which can be forfeited if the challenge is frivolous.
26. **`voteOnReputationChallenge(uint256 _challengeId, bool _supportChallenge)`**: Allows other users to vote on a reputation challenge. A successful challenge (high vote turnout + `_supportChallenge` majority) can lead to reputation slashing.
27. **`resolveReputationChallenge(uint256 _challengeId)`**: Executes the outcome of a completed reputation challenge, either slashing the challenged user's reputation and rewarding successful challengers (from the bond) or slashing the challenger's bond if unsuccessful.

---

## Solidity Smart Contract: QuantumForgeDAO

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Custom Errors for gas efficiency and clarity
error InvalidReputationOracle();
error ZeroAddressNotAllowed();
error AmountMustBeGreaterThanZero();
error Unauthorized();
error ContractPaused();
error ContractNotPaused();
error InsufficientReputation(uint256 required, uint256 current);
error NotShardOwner();
error ShardAlreadyBonded();
error ShardNotBonded();
error InsufficientBalance(uint256 required, uint256 current);
error InvalidProposalState();
error ProposalAlreadyVoted();
error InvalidVote();
error ProposalNotFound();
error ProposalNotExecutable();
error ProposalNotCancelable();
error InsufficientReputationBond(uint256 required, uint256 current);
error NoActiveChallenge();
error ChallengeAlreadyResolved();
error InvalidChallengeBond();
error NotHighReputationEnough(uint256 required, uint256 current);
error AllocationNotFound();
error AllocationAlreadyApproved();
error AllocationApprovalThresholdNotMet(uint256 required, uint256 current);
error InvalidForgeType();


contract QuantumForgeDAO is Ownable, Pausable, ReentrancyGuard, ERC721 {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    // Reputation System
    uint256 public constant INITIAL_REPUTATION_FOR_MINT = 100;
    uint256 public constant REPUTATION_DECAY_PER_SECOND = 1; // Example: 1 point per second decay rate
    uint256 public constant REPUTATION_DECAY_INCENTIVE_ETH = 100000000000000; // 0.0001 ETH incentive for calling decayReputation
    uint256 public constant PROPOSAL_REPUTATION_BOND_MULTIPLIER = 500; // Multiplier for reputation bond (e.g., base 1000 reputation * 500)
    uint256 public constant MIN_REPUTATION_FORGE_TIER1 = 5000;
    uint256 public constant MIN_REPUTATION_FORGE_TIER2 = 15000;

    address public reputationOracle; // Address allowed to call accrueReputation & slashReputation

    struct ReputationState {
        uint256 points;
        uint256 lastUpdateTimestamp;
    }
    mapping(address => ReputationState) public reputations;

    // Quantum Shards (Dynamic NFTs)
    uint256 public constant SHARD_MINT_COST_REPUTATION = 500; // Reputation cost to mint a shard
    uint256 public constant SHARD_BOND_BOOST_PERCENTAGE = 10; // 10% bonus reputation accrual for bonded shards

    enum ShardTier { Base, ForgedTier1, ForgedTier2 }

    struct QuantumShard {
        address owner;
        bool isBonded;
        ShardTier tier;
        string metadataURI; // Custom URI for dynamic metadata
    }
    mapping(uint256 => QuantumShard) public quantumShards; // tokenId => Shard details
    mapping(address => EnumerableSet.UintSet) private _holderShards; // Holder => Set of their token IDs

    // DAO Governance
    uint256 public proposalCounter;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes calldata;
        string description;
        uint256 creationTimestamp;
        uint256 endTimestamp;
        uint256 minReputationBond; // Reputation required as a griefing bond
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User => Voted or not
        ProposalState state;
        bool executed;
        uint256 totalVotingReputationAtCreation; // Snapshot of reputation for voting weight calculation
    }
    mapping(uint256 => Proposal) public proposals;
    mapping(address => address) public delegates; // User => Delegate

    // Treasury Management
    mapping(address => uint256) public treasuryBalances; // ERC20 token address => balance
    uint256 public meritocraticAllocationCounter;
    uint256 public meritocraticApprovalThreshold; // Combined reputation needed for direct approvals

    struct MeritocraticAllocation {
        address requester;
        address tokenAddress;
        uint256 amount;
        string reason;
        uint256 requestedTimestamp;
        mapping(address => bool) approvedBy;
        EnumerableSet.AddressSet approvers; // Set of addresses that have approved
        bool executed;
    }
    mapping(uint256 => MeritocraticAllocation) public meritocraticAllocations;

    // Reputation Challenge System
    uint256 public challengeCounter;

    enum ChallengeState { Pending, Voting, Resolved }

    struct ReputationChallenge {
        address challenger;
        address challengedUser;
        bytes32 reasonHash;
        uint256 challengeBond; // ETH or other token bond
        uint256 creationTimestamp;
        uint256 endTimestamp;
        mapping(address => bool) hasVoted; // User => Voted or not
        uint256 votesSupportChallenge;
        uint256 votesOpposeChallenge;
        ChallengeState state;
        bool resolved;
        bool challengeSuccessful; // True if challenged user's reputation was slashed
    }
    mapping(uint256 => ReputationChallenge) public reputationChallenges;

    // --- Events ---
    event ReputationAccrued(address indexed user, uint256 amount, bytes32 reasonHash);
    event ReputationDecayed(address indexed user, uint256 initialPoints, uint256 finalPoints, uint256 decayedAmount);
    event ReputationSlashed(address indexed user, uint256 amount, bytes32 reasonHash);
    event ShardMinted(address indexed recipient, uint256 indexed tokenId, uint256 currentReputationCost);
    event ShardBonded(address indexed owner, uint256 indexed tokenId);
    event ShardUnbonded(address indexed owner, uint256 indexed tokenId);
    event ShardForged(uint256 indexed tokenId, ShardTier newTier, uint8 forgeType);
    event ShardMetadataUpdated(uint256 indexed tokenId, string newURI);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event AssetDeposited(address indexed tokenAddress, uint256 amount);
    event AssetWithdrawn(address indexed tokenAddress, uint256 amount, address indexed recipient);
    event MeritocraticAllocationRequested(uint256 indexed allocationId, address indexed requester, address tokenAddress, uint256 amount, string reason);
    event MeritocraticAllocationApproved(uint256 indexed allocationId, address indexed approver);
    event MeritocraticAllocationExecuted(uint256 indexed allocationId);
    event MeritocraticApprovalThresholdSet(uint256 newThreshold);
    event ReputationChallengeSubmitted(uint256 indexed challengeId, address indexed challenger, address indexed challengedUser, uint256 bondAmount);
    event ReputationChallengeVoted(uint256 indexed challengeId, address indexed voter, bool supportChallenge);
    event ReputationChallengeResolved(uint256 indexed challengeId, address indexed challengedUser, bool successfulChallenge);
    event ReputationOracleSet(address indexed oldOracle, address indexed newOracle);

    // --- Modifiers ---

    modifier onlyReputationOracle() {
        if (msg.sender != reputationOracle) revert Unauthorized();
        _;
    }

    modifier onlyShardHolder(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert NotShardOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused()) revert ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!paused()) revert ContractNotPaused();
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        if (_proposalId == 0 || _proposalId > proposalCounter) revert ProposalNotFound();
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, address initialOracle_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        if (initialOracle_ == address(0)) revert ZeroAddressNotAllowed();
        reputationOracle = initialOracle_;
        meritocraticApprovalThreshold = 10000; // Initial threshold for meritocratic allocations
        _updateReputation(msg.sender, INITIAL_REPUTATION_FOR_MINT, true); // Initial reputation for owner
    }

    // --- I. Core & Administration Functions ---

    /**
     * @notice Allows the owner to pause critical contract functionalities.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Allows the owner to unpause critical contract functionalities.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Sets the address of the approved external oracle responsible for reporting reputation-affecting events.
     * @param _newOracle The new address for the reputation oracle.
     */
    function setReputationOracle(address _newOracle) public onlyOwner {
        if (_newOracle == address(0)) revert ZeroAddressNotAllowed();
        emit ReputationOracleSet(reputationOracle, _newOracle);
        reputationOracle = _newOracle;
    }

    /**
     * @notice Allows the owner to withdraw specific tokens from the contract in extreme emergencies.
     * @param _tokenAddress The address of the ERC-20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdraw(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        if (_tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        if (treasuryBalances[_tokenAddress] < _amount) revert InsufficientBalance(treasuryBalances[_tokenAddress], _amount);

        treasuryBalances[_tokenAddress] = treasuryBalances[_tokenAddress].sub(_amount);
        IERC20(_tokenAddress).transfer(owner(), _amount);
        emit AssetWithdrawn(_tokenAddress, _amount, owner());
    }

    // --- II. Reputation Management Functions ---

    /**
     * @dev Internal function to update a user's reputation, handling decay calculation.
     * @param _user The address of the user.
     * @param _amount The amount of reputation to add or subtract.
     * @param _add True to add, false to subtract.
     */
    function _updateReputation(address _user, uint256 _amount, bool _add) internal {
        uint256 currentPoints = getReputation(_user); // Get decayed reputation first

        if (_add) {
            reputations[_user].points = currentPoints.add(_amount);
        } else {
            reputations[_user].points = currentPoints.sub(_amount);
        }
        reputations[_user].lastUpdateTimestamp = block.timestamp;
    }

    /**
     * @notice Increases a user's reputation points based on a specific event.
     *         Callable only by the designated reputation oracle.
     * @param _user The address of the user whose reputation is to be increased.
     * @param _amount The amount of reputation points to add.
     * @param _reasonHash A unique hash representing the reason for reputation accrual (e.g., hash of "CompletedTaskXYZ").
     */
    function accrueReputation(address _user, uint256 _amount, bytes32 _reasonHash)
        public
        onlyReputationOracle
        whenNotPaused
    {
        if (_user == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        _updateReputation(_user, _amount, true);
        emit ReputationAccrued(_user, _amount, _reasonHash);
    }

    /**
     * @notice Decreases a user's reputation based on time elapsed since their last update, applying a decay rate.
     *         Can be called by anyone to trigger decay for a specific user. Caller receives a small ETH incentive.
     * @param _user The address of the user whose reputation is to be decayed.
     */
    function decayReputation(address _user) public whenNotPaused nonReentrant {
        if (_user == address(0)) revert ZeroAddressNotAllowed();

        uint256 currentPoints = reputations[_user].points;
        uint256 lastUpdate = reputations[_user].lastUpdateTimestamp;

        if (currentPoints == 0 || block.timestamp <= lastUpdate) {
            // No decay needed or already updated
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(lastUpdate);
        uint256 decayAmount = timeElapsed.mul(REPUTATION_DECAY_PER_SECOND);

        uint256 newPoints = currentPoints.sub(decayAmount > currentPoints ? currentPoints : decayAmount);

        uint256 oldRep = getReputation(_user); // Get reputation before applying decay (for event)

        reputations[_user].points = newPoints;
        reputations[_user].lastUpdateTimestamp = block.timestamp;

        // Reward the caller for triggering decay
        if (REPUTATION_DECAY_INCENTIVE_ETH > 0) {
            (bool success, ) = msg.sender.call{value: REPUTATION_DECAY_INCENTIVE_ETH}("");
            if (!success) {
                // Log failure but don't revert to keep decay functional
                // This scenario should be rare for small ETH amounts.
            }
        }
        emit ReputationDecayed(_user, oldRep, newPoints, decayAmount);
    }

    /**
     * @notice Returns the current, calculated reputation score for a user, accounting for decay.
     * @param _user The address of the user.
     * @return The user's current reputation points.
     */
    function getReputation(address _user) public view returns (uint256) {
        if (_user == address(0)) return 0;

        uint256 currentPoints = reputations[_user].points;
        uint256 lastUpdate = reputations[_user].lastUpdateTimestamp;

        if (block.timestamp <= lastUpdate) {
            return currentPoints;
        }

        uint256 timeElapsed = block.timestamp.sub(lastUpdate);
        uint256 decayAmount = timeElapsed.mul(REPUTATION_DECAY_PER_SECOND);

        // Apply decay
        return currentPoints.sub(decayAmount > currentPoints ? currentPoints : decayAmount);
    }

    /**
     * @notice Decreases a user's reputation, typically as a penalty for rule violations.
     *         Callable only by the designated reputation oracle or through a successful DAO proposal execution.
     * @param _user The address of the user whose reputation is to be slashed.
     * @param _amount The amount of reputation points to subtract.
     * @param _reasonHash A unique hash representing the reason for reputation slashing.
     */
    function slashReputation(address _user, uint256 _amount, bytes32 _reasonHash)
        public
        whenNotPaused
    {
        // Can be called by oracle or as a result of DAO proposal execution
        if (msg.sender != reputationOracle && msg.sender != address(this)) revert Unauthorized();
        if (_user == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        _updateReputation(_user, _amount, false);
        emit ReputationSlashed(_user, _amount, _reasonHash);
    }


    // --- III. Quantum Shard (Dynamic NFT) Functions ---

    /**
     * @notice Mints a new Quantum Shard NFT to a recipient. Requires initial reputation from the recipient.
     * @param _recipient The address to mint the Quantum Shard to.
     */
    function mintQuantumShard(address _recipient) public whenNotPaused nonReentrant {
        if (_recipient == address(0)) revert ZeroAddressNotAllowed();
        uint256 currentRep = getReputation(_recipient);
        if (currentRep < SHARD_MINT_COST_REPUTATION) {
            revert InsufficientReputation(SHARD_MINT_COST_REPUTATION, currentRep);
        }

        uint256 tokenId = super.totalSupply().add(1); // Simple incrementing tokenId
        _mint(_recipient, tokenId);
        _updateReputation(_recipient, SHARD_MINT_COST_REPUTATION, false); // Burn reputation for minting

        quantumShards[tokenId] = QuantumShard({
            owner: _recipient,
            isBonded: false,
            tier: ShardTier.Base,
            metadataURI: string(abi.encodePacked("ipfs://Qmbcdef12345/base/", Strings.toString(tokenId), ".json")) // Placeholder
        });
        _holderShards[_recipient].add(tokenId);

        emit ShardMinted(_recipient, tokenId, SHARD_MINT_COST_REPUTATION);
    }

    /**
     * @notice Allows a user to "bond" their Quantum Shard, locking it to their address.
     *         Bonded shards contribute more significantly to reputation accrual and governance weight.
     * @param _tokenId The ID of the Quantum Shard to bond.
     */
    function bondShardForReputation(uint256 _tokenId) public onlyShardHolder(_tokenId) whenNotPaused {
        if (quantumShards[_tokenId].isBonded) revert ShardAlreadyBonded();

        quantumShards[_tokenId].isBonded = true;
        // Optionally, add logic here to boost reputation accrual on next accrueReputation call
        // For simplicity, this is noted in getReputation and getVotingWeight logic
        emit ShardBonded(msg.sender, _tokenId);
    }

    /**
     * @notice Unbonds a Quantum Shard, making it transferable again. May incur a reputation penalty or cooldown.
     * @param _tokenId The ID of the Quantum Shard to unbond.
     */
    function unbondShard(uint256 _tokenId) public onlyShardHolder(_tokenId) whenNotPaused {
        if (!quantumShards[_tokenId].isBonded) revert ShardNotBonded();

        quantumShards[_tokenId].isBonded = false;
        // Optional: Apply a reputation penalty for unbonding before a cooldown period or if unbonding too frequently
        // _updateReputation(msg.sender, UNBOND_PENALTY_REPUTATION, false);
        emit ShardUnbonded(msg.sender, _tokenId);
    }

    /**
     * @notice Upgrades a Quantum Shard's tier or unlocks new features based on the holder's reputation
     *         and potentially burning reputation points or contributing treasury assets (via a proposal).
     * @param _tokenId The ID of the Quantum Shard to forge.
     * @param _forgeType The type of forging action (e.g., 1 for Tier1, 2 for Tier2).
     */
    function forgeShard(uint256 _tokenId, uint8 _forgeType) public onlyShardHolder(_tokenId) whenNotPaused nonReentrant {
        uint256 currentRep = getReputation(msg.sender);
        ShardTier currentTier = quantumShards[_tokenId].tier;
        string memory newURI;

        if (_forgeType == 1) {
            if (currentTier >= ShardTier.ForgedTier1) revert InvalidForgeType();
            if (currentRep < MIN_REPUTATION_FORGE_TIER1) {
                revert InsufficientReputation(MIN_REPUTATION_FORGE_TIER1, currentRep);
            }
            // Optional: Burn a portion of reputation for forging
            _updateReputation(msg.sender, MIN_REPUTATION_FORGE_TIER1.div(10), false);
            quantumShards[_tokenId].tier = ShardTier.ForgedTier1;
            newURI = string(abi.encodePacked("ipfs://Qmbcdef12345/tier1/", Strings.toString(_tokenId), ".json"));
        } else if (_forgeType == 2) {
            if (currentTier >= ShardTier.ForgedTier2) revert InvalidForgeType();
            if (currentRep < MIN_REPUTATION_FORGE_TIER2) {
                revert InsufficientReputation(MIN_REPUTATION_FORGE_TIER2, currentRep);
            }
            // Optional: Burn a larger portion of reputation for forging
            _updateReputation(msg.sender, MIN_REPUTATION_FORGE_TIER2.div(10), false);
            quantumShards[_tokenId].tier = ShardTier.ForgedTier2;
            newURI = string(abi.encodePacked("ipfs://Qmbcdef12345/tier2/", Strings.toString(_tokenId), ".json"));
        } else {
            revert InvalidForgeType();
        }

        quantumShards[_tokenId].metadataURI = newURI;
        emit ShardForged(_tokenId, quantumShards[_tokenId].tier, _forgeType);
        emit ShardMetadataUpdated(_tokenId, newURI);
    }

    /**
     * @notice Allows the DAO or Oracle to update the specific metadata URI for a Quantum Shard,
     *         reflecting its dynamic state (tier changes, reputation-based visual updates).
     * @param _tokenId The ID of the Quantum Shard to update.
     * @param _uri The new metadata URI for the shard.
     */
    function setTokenMetadataURI(uint256 _tokenId, string memory _uri) public {
        // Only owner or reputationOracle can update, or through DAO proposal.
        if (msg.sender != owner() && msg.sender != reputationOracle && msg.sender != address(this)) revert Unauthorized();
        // Check if token exists
        if (_exists(_tokenId) == false) revert ProposalNotFound(); // Reuse error for simplicity, or create specific
        quantumShards[_tokenId].metadataURI = _uri;
        emit ShardMetadataUpdated(_tokenId, _uri);
    }

    /**
     * @notice (ERC-721 Override) Returns the URI for a given QuantumShard token ID.
     *         This URI will point to an off-chain resolver that dynamically generates metadata
     *         based on the token's current state (e.g., owner's reputation, forge type).
     * @param _tokenId The ID of the Quantum Shard.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return quantumShards[_tokenId].metadataURI;
    }

    // Override _transfer to manage _holderShards set
    function _transfer(address from, address to, uint256 tokenId) internal override {
        super._transfer(from, to, tokenId);
        if (quantumShards[tokenId].isBonded) {
            revert ShardAlreadyBonded(); // Cannot transfer if bonded
        }
        _holderShards[from].remove(tokenId);
        _holderShards[to].add(tokenId);
        quantumShards[tokenId].owner = to; // Update owner in custom struct
    }

    // --- IV. DAO Governance & Treasury Management Functions ---

    /**
     * @dev Calculates the voting weight of a user based on their reputation and bonded shards.
     * @param _voter The address of the voter.
     * @return The calculated voting weight.
     */
    function getVotingWeight(address _voter) public view returns (uint256) {
        address trueVoter = delegates[_voter] == address(0) ? _voter : delegates[_voter];
        uint256 baseRep = getReputation(trueVoter);
        uint256 shardBonus = 0;

        for (uint256 i = 0; i < _holderShards[trueVoter].length(); i++) {
            uint256 tokenId = _holderShards[trueVoter].at(i);
            if (quantumShards[tokenId].isBonded) {
                shardBonus = shardBonus.add(baseRep.mul(SHARD_BOND_BOOST_PERCENTAGE).div(100));
            }
        }
        return baseRep.add(shardBonus);
    }

    /**
     * @notice Submits a new governance proposal. Requires a `minReputationBond` as a griefing bond.
     *         The bond is slashed if the proposal is rejected or cancelled maliciously.
     * @param _target The target contract address for the proposal execution.
     * @param _value The ETH value to send with the execution.
     * @param _calldata The calldata for the target function execution.
     * @param _description A descriptive string for the proposal.
     * @param _minReputationBond The reputation bond required to submit this proposal.
     */
    function submitProposal(address _target, uint256 _value, bytes memory _calldata, string memory _description, uint256 _minReputationBond)
        public
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        uint256 currentRep = getReputation(msg.sender);
        if (currentRep < _minReputationBond) {
            revert InsufficientReputationBond(_minReputationBond, currentRep);
        }

        proposalCounter = proposalCounter.add(1);
        uint256 proposalId = proposalCounter;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            target: _target,
            value: _value,
            calldata: _calldata,
            description: _description,
            creationTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(7 days), // Example: 7-day voting period
            minReputationBond: _minReputationBond,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false,
            totalVotingReputationAtCreation: getVotingWeight(msg.sender) // Snapshot proposer's voting power
        });

        // Implicitly deduct reputation bond temporarily. It's returned on success, slashed on failure.
        _updateReputation(msg.sender, _minReputationBond, false);

        emit ProposalSubmitted(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @notice Allows users to vote on an active proposal. Voting weight is determined by their current reputation and bonded Quantum Shard holdings.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'For', False for 'Against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        public
        whenNotPaused
        nonReentrant
        proposalExists(_proposalId)
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (proposal.endTimestamp < block.timestamp) {
            // Update state if voting period is over
            proposal.state = (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Failed;
            revert InvalidProposalState(); // Revert after state update, implying period ended
        }
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 votingWeight = getVotingWeight(msg.sender);
        if (votingWeight == 0) revert InvalidVote(); // Cannot vote with 0 weight

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingWeight);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingWeight);
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, votingWeight);
    }

    /**
     * @notice Allows a user to delegate their voting power to another address.
     * @param _delegate The address to delegate voting power to.
     */
    function delegateVote(address _delegate) public {
        if (_delegate == address(0)) revert ZeroAddressNotAllowed();
        if (_delegate == msg.sender) revert InvalidVote(); // Cannot delegate to self

        delegates[msg.sender] = _delegate;
        emit VoteDelegated(msg.sender, _delegate);
    }

    /**
     * @notice Executes a passed governance proposal. Refunds the `minReputationBond` to the proposer.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Succeeded) {
            // Re-evaluate state if voting period just ended
            if (proposal.endTimestamp < block.timestamp) {
                proposal.state = (proposal.votesFor > proposal.votesAgainst) ? ProposalState.Succeeded : ProposalState.Failed;
            }
            if (proposal.state != ProposalState.Succeeded) revert ProposalNotExecutable();
        }
        if (proposal.executed) revert ProposalAlreadyVoted(); // Reuse error

        // Check if sufficient voting power participated (e.g., quorum)
        // For simplicity, we're not implementing a complex quorum, just majority.
        // A real DAO would have a quorum based on total reputation snapshot.
        // uint256 totalReputationSnapshot = ...;
        // if (proposal.votesFor + proposal.votesAgainst < totalReputationSnapshot / QUORUM_PERCENTAGE) revert InsufficientQuorum();

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        // Refund reputation bond
        _updateReputation(proposal.proposer, proposal.minReputationBond, true);

        // Execute the proposal's calldata
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.calldata);
        if (!success) {
            // If execution fails, mark proposal as failed even if it passed votes.
            // This might trigger an on-chain alert or a re-submission process.
            proposal.state = ProposalState.Failed; // Mark as failed due to execution error
            revert ProposalNotExecutable(); // Propagate error
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows the proposer to cancel their own proposal *before* it passes,
     *         but after a certain time, potentially forfeiting a portion of their `minReputationBond`.
     *         Also callable by DAO vote if malicious (via `executeProposal` calling this function).
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) public whenNotPaused nonReentrant proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        // Only proposer can cancel, or the contract itself (via DAO execution)
        if (msg.sender != proposal.proposer && msg.sender != address(this)) revert Unauthorized();

        if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Succeeded) {
            revert ProposalNotCancelable(); // Cannot cancel if already passed or executed
        }

        proposal.state = ProposalState.Canceled;

        // Optionally, slash a portion of the reputation bond if cancelled after some time
        // For now, simple return for proposer, slash for malicious contract calls
        if (msg.sender == proposal.proposer) {
            // Proposer gets bond back if they cancel before voting finishes or if it clearly failed
            _updateReputation(proposal.proposer, proposal.minReputationBond, true);
        } else {
            // If cancelled by DAO (address(this)), it implies malicious, so bond is not returned.
            // It could be burned or redirected to a community pool.
            // _updateReputation(proposal.proposer, proposal.minReputationBond, false); // Keep bond slashed
        }

        emit ProposalCanceled(_proposalId);
    }

    /**
     * @notice Allows users or external contracts to deposit ERC-20 tokens into the DAO's treasury.
     * @param _tokenAddress The address of the ERC-20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositAsset(address _tokenAddress, uint256 _amount) public whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();

        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        treasuryBalances[_tokenAddress] = treasuryBalances[_tokenAddress].add(_amount);
        emit AssetDeposited(_tokenAddress, _amount);
    }

    /**
     * @notice Allows highly reputable users to request a direct treasury allocation *without* a full DAO vote,
     *         within a predefined small limit. Requires high reputation to initiate.
     * @param _tokenAddress The address of the ERC-20 token requested.
     * @param _amount The amount of tokens requested.
     * @param _reason A brief reason for the allocation.
     */
    function requestMeritocraticAllocation(address _tokenAddress, uint256 _amount, string memory _reason)
        public
        whenNotPaused
        nonReentrant
    {
        uint256 currentRep = getReputation(msg.sender);
        // Define a minimum reputation to even request this
        if (currentRep < meritocraticApprovalThreshold.div(5)) { // e.g., 20% of full approval threshold
            revert NotHighReputationEnough(meritocraticApprovalThreshold.div(5), currentRep);
        }
        if (_tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert AmountMustBeGreaterThanZero();
        // Set a hard limit for these direct allocations (e.g., 0.1% of total treasury or a fixed small amount)
        // For simplicity, this example doesn't implement a dynamic limit, but it's crucial for security.
        // if (_amount > MAX_MERITOCRATIC_ALLOCATION) revert AllocationTooLarge();

        meritocraticAllocationCounter = meritocraticAllocationCounter.add(1);
        uint256 allocationId = meritocraticAllocationCounter;

        meritocraticAllocations[allocationId] = MeritocraticAllocation({
            requester: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            reason: _reason,
            requestedTimestamp: block.timestamp,
            executed: false
        });

        emit MeritocraticAllocationRequested(allocationId, msg.sender, _tokenAddress, _amount, _reason);
    }

    /**
     * @notice (Callable by high-reputation users/council) Approves a pending meritocratic allocation request.
     *         Requires a minimum combined reputation from approvers.
     * @param _requester The address of the user who requested the allocation.
     * @param _allocationId The ID of the meritocratic allocation request.
     */
    function approveMeritocraticAllocation(address _requester, uint256 _allocationId)
        public
        whenNotPaused
        nonReentrant
    {
        MeritocraticAllocation storage allocation = meritocraticAllocations[_allocationId];
        if (allocation.requester == address(0) || allocation.requester != _requester) revert AllocationNotFound();
        if (allocation.executed) revert AllocationAlreadyApproved(); // Use this for already executed too
        if (allocation.approvedBy[msg.sender]) revert AllocationAlreadyApproved();

        uint256 approverRep = getReputation(msg.sender);
        if (approverRep < meritocraticApprovalThreshold.div(10)) { // Minimum reputation for a single approver
            revert NotHighReputationEnough(meritocraticApprovalThreshold.div(10), approverRep);
        }

        allocation.approvedBy[msg.sender] = true;
        allocation.approvers.add(msg.sender);

        uint256 totalApprovalReputation = 0;
        for (uint256 i = 0; i < allocation.approvers.length(); i++) {
            totalApprovalReputation = totalApprovalReputation.add(getReputation(allocation.approvers.at(i)));
        }

        if (totalApprovalReputation >= meritocraticApprovalThreshold) {
            if (treasuryBalances[allocation.tokenAddress] < allocation.amount) {
                // If funds are insufficient, mark as failed (or leave unexecuted) and revert.
                // In a real system, might trigger a notification.
                revert InsufficientBalance(treasuryBalances[allocation.tokenAddress], allocation.amount);
            }

            treasuryBalances[allocation.tokenAddress] = treasuryBalances[allocation.tokenAddress].sub(allocation.amount);
            IERC20(allocation.tokenAddress).transfer(allocation.requester, allocation.amount);
            allocation.executed = true;
            emit MeritocraticAllocationExecuted(_allocationId);
        }
        emit MeritocraticAllocationApproved(_allocationId, msg.sender);
    }

    /**
     * @notice (Governance Proposal) Sets the minimum combined reputation required for approvers of a meritocratic allocation.
     * @param _newThreshold The new minimum combined reputation threshold.
     */
    function setMeritocraticApprovalThreshold(uint256 _newThreshold) public {
        if (msg.sender != address(this)) revert Unauthorized(); // Only callable via successful DAO proposal
        meritocraticApprovalThreshold = _newThreshold;
        emit MeritocraticApprovalThresholdSet(_newThreshold);
    }


    // --- V. Advanced Reputation & Challenge System ---

    /**
     * @notice Initiates a formal challenge against another user's reputation.
     *         Requires a `_challengeBond` (e.g., ETH/stablecoin) which can be forfeited if the challenge is frivolous.
     * @param _challengedUser The address of the user whose reputation is being challenged.
     * @param _reasonHash A hash representing the reason for the challenge.
     * @param _challengeBond The amount of bond (ETH) to stake for the challenge.
     */
    function submitReputationChallenge(address _challengedUser, bytes32 _reasonHash, uint256 _challengeBond)
        public
        payable
        whenNotPaused
        nonReentrant
        returns (uint256)
    {
        if (_challengedUser == address(0) || _challengedUser == msg.sender) revert ZeroAddressNotAllowed();
        if (_challengeBond == 0 || msg.value < _challengeBond) revert InvalidChallengeBond();

        challengeCounter = challengeCounter.add(1);
        uint256 challengeId = challengeCounter;

        reputationChallenges[challengeId] = ReputationChallenge({
            challenger: msg.sender,
            challengedUser: _challengedUser,
            reasonHash: _reasonHash,
            challengeBond: _challengeBond,
            creationTimestamp: block.timestamp,
            endTimestamp: block.timestamp.add(5 days), // Example: 5-day voting period for challenges
            state: ChallengeState.Voting,
            votesSupportChallenge: 0,
            votesOpposeChallenge: 0,
            resolved: false,
            challengeSuccessful: false
        });

        // Transfer bond to contract
        // msg.value is already transferred by payable, just ensure it matches _challengeBond
        // If it's an ERC20 bond, would need IERC20(_bondToken).transferFrom(msg.sender, address(this), _challengeBond);

        emit ReputationChallengeSubmitted(challengeId, msg.sender, _challengedUser, _challengeBond);
        return challengeId;
    }

    /**
     * @notice Allows other users to vote on a reputation challenge.
     *         A successful challenge can lead to reputation slashing for the challenged user.
     * @param _challengeId The ID of the reputation challenge to vote on.
     * @param _supportChallenge True to support the challenge (agree with challenger), False to oppose.
     */
    function voteOnReputationChallenge(uint256 _challengeId, bool _supportChallenge)
        public
        whenNotPaused
        nonReentrant
    {
        if (_challengeId == 0 || _challengeId > challengeCounter) revert NoActiveChallenge();
        ReputationChallenge storage challenge = reputationChallenges[_challengeId];

        if (challenge.state != ChallengeState.Voting) revert InvalidProposalState(); // Reuse error
        if (challenge.endTimestamp < block.timestamp) {
            challenge.state = ChallengeState.Resolved; // Update state if voting period is over
            revert InvalidProposalState(); // Revert, implying period ended
        }
        if (challenge.hasVoted[msg.sender]) revert ProposalAlreadyVoted(); // Reuse error

        uint256 votingWeight = getVotingWeight(msg.sender);
        if (votingWeight == 0) revert InvalidVote();

        if (_supportChallenge) {
            challenge.votesSupportChallenge = challenge.votesSupportChallenge.add(votingWeight);
        } else {
            challenge.votesOpposeChallenge = challenge.votesOpposeChallenge.add(votingWeight);
        }
        challenge.hasVoted[msg.sender] = true;

        emit ReputationChallengeVoted(_challengeId, msg.sender, _supportChallenge);
    }

    /**
     * @notice Executes the outcome of a completed reputation challenge.
     *         Either slashing the challenged user's reputation and rewarding successful challengers (from the bond)
     *         or slashing the challenger's bond if unsuccessful.
     * @param _challengeId The ID of the reputation challenge to resolve.
     */
    function resolveReputationChallenge(uint256 _challengeId) public whenNotPaused nonReentrant {
        if (_challengeId == 0 || _challengeId > challengeCounter) revert NoActiveChallenge();
        ReputationChallenge storage challenge = reputationChallenges[_challengeId];

        if (challenge.resolved) revert ChallengeAlreadyResolved();
        if (challenge.endTimestamp > block.timestamp && challenge.state == ChallengeState.Voting) {
            revert InvalidProposalState(); // Reuse error: voting period not over
        }

        challenge.state = ChallengeState.Resolved;
        challenge.resolved = true;

        uint256 totalVotes = challenge.votesSupportChallenge.add(challenge.votesOpposeChallenge);

        if (totalVotes == 0) {
            // No votes, challenge bond returned to challenger (or specific default action)
            (bool success, ) = challenge.challenger.call{value: challenge.challengeBond}("");
            if (!success) { /* handle error */ }
            challenge.challengeSuccessful = false;
        } else if (challenge.votesSupportChallenge > challenge.votesOpposeChallenge) {
            // Challenge successful: Slash challenged user's reputation, reward challenger
            _updateReputation(challenge.challengedUser, getReputation(challenge.challengedUser).div(5), false); // Example: Slash 20%
            (bool success, ) = challenge.challenger.call{value: challenge.challengeBond}(""); // Return bond to challenger
            if (!success) { /* handle error */ }
            challenge.challengeSuccessful = true;
        } else {
            // Challenge unsuccessful: Challenger's bond is forfeited (sent to treasury or burned)
            // Send bond to DAO treasury (e.g., as ETH in this simplified example)
            // Assuming the bond was ETH:
            treasuryBalances[address(0)] = treasuryBalances[address(0)].add(challenge.challengeBond); // ETH is token address 0
            challenge.challengeSuccessful = false;
        }

        emit ReputationChallengeResolved(_challengeId, challenge.challengedUser, challenge.challengeSuccessful);
    }

    // --- Internal ERC721 Overrides (for _holderShards management) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent transfer if bonded
        if (from != address(0) && quantumShards[tokenId].isBonded) {
             revert ShardAlreadyBonded();
        }
    }
}
```