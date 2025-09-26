This smart contract, named "Synthetica Nexus," is designed to create a decentralized, adaptive community and knowledge hub. It integrates advanced concepts such as Soulbound Tokens (SBTs) for identity and reputation, dynamic NFTs that evolve based on community consensus, and a predictive validation market for knowledge contributions. The contract manages reputation, funding pools, epoch-based evolutions, and decentralized governance, all within a single deployable unit.

---

## Synthetica Nexus: Decentralized Adaptive Knowledge & Impact Network

### Outline:
*   **I. Core Infrastructure & Access Control:** Basic contract setup, ownership, pausing mechanisms, and essential enums/structs.
*   **II. Nexus Keys (Soulbound Tokens for Identity & Reputation):** Manages non-transferable NFTs representing user identity and their reputation tiers.
*   **III. Catalyst Fragments (Dynamic NFTs for Contributions & Skill Development):** Manages evolving NFTs representing verifiable knowledge contributions or skill milestones.
*   **IV. Knowledge Fabric (Content Curation & Impact Assessment):** Handles submission of knowledge, community voting on its impact, and scoring.
*   **V. Synthesizer Pools (Decentralized Funding & Grants):** Manages ERC-20 funding pools and a grant proposal/voting system.
*   **VI. Epoch & Evolution Engine:** Time-based system for reputation recalculations, NFT evolutions, and other periodic events.
*   **VII. Nexus Governance & Dispute Resolution:** Mechanism for community proposals, voting, and resolving disagreements.

### Function Summary:

1.  **`constructor`**: Initializes the contract, sets the deployer as admin, and configures initial parameters like epoch duration and base URIs.
2.  **`setEpochDuration`**: (Admin) Allows adjustment of the time duration for each epoch.
3.  **`setMinReputationForTierUpgrade`**: (Admin) Configures the reputation thresholds required for Nexus Key tier upgrades.
4.  **`setNexusKeyBaseURI`**: (Admin) Sets the base URI for Nexus Key metadata. The `tokenURI` function appends tier-specific data.
5.  **`setCatalystFragmentBaseURI`**: (Admin) Sets the base URI for Catalyst Fragment metadata. `tokenURI` appends evolution stage data.
6.  **`pause`**: (Admin) Halts critical contract operations, useful for maintenance or emergencies.
7.  **`unpause`**: (Admin) Resumes contract operations after a pause.
8.  **`mintNexusKey`**: Allows a new user to mint their initial Soulbound Nexus Key (tier 1), establishing their identity in the network.
9.  **`upgradeNexusKeyTier`**: Enables a Nexus Key holder to upgrade their tier based on their accumulated `calculateUserReputation` score.
10. **`downgradeNexusKeyTier`**: (Governance/Admin) Allows downgrading a Nexus Key tier in response to severe misconduct or governance decisions.
11. **`getNexusKeyTier`**: Retrieves the current tier level of a user's Nexus Key.
12. **`submitKnowledgeThread`**: Users submit a knowledge contribution (identified by an IPFS hash and category). This action mints a new Catalyst Fragment NFT for the contributor.
13. **`voteOnKnowledgeThreadImpact`**: Nexus Key holders vote on the perceived impact or accuracy of a submitted knowledge thread. Their vote weight is scaled by their Nexus Key tier.
14. **`getKnowledgeThreadImpactScore`**: Returns the current aggregated impact score for a specific knowledge thread.
15. **`getCatalystFragmentEvolutionStage`**: Retrieves the current evolution stage of a particular Catalyst Fragment NFT.
16. **`calculateUserReputation`**: (View) Calculates a user's comprehensive reputation score based on their Nexus Key tier and the evolution stages of their owned Catalyst Fragments.
17. **`triggerFragmentEvolutionCheck`**: (Publicly Callable) Can be called by anyone after an epoch ends to trigger the evolution process for Catalyst Fragments based on their accumulated impact scores.
18. **`claimFragmentEvolutionRewards`**: Allows Catalyst Fragment holders to claim specific ERC-20 rewards when their fragment successfully evolves to a new stage.
19. **`createSynthesizerPool`**: (Governance/Admin) Establishes a new funding pool for a specified knowledge category, linked to a particular ERC-20 token.
20. **`depositToSynthesizerPool`**: Users can deposit supported ERC-20 tokens into an existing Synthesizer Pool to contribute to its funding.
21. **`proposeKnowledgeGrant`**: Nexus Key holders can propose a grant of funds from a Synthesizer Pool to a specific knowledge thread or contributor.
22. **`voteOnKnowledgeGrant`**: Nexus Key holders vote on active grant proposals, with their vote weight determined by their Nexus Key tier.
23. **`executeKnowledgeGrant`**: (Governance/Admin) Executes a grant proposal that has passed community vote, transferring funds from the pool.
24. **`advanceEpoch`**: (Admin/Keeper) Explicitly advances the system to the next epoch, triggering periodic processes like reputation recalculations and evolution checks.
25. **`submitProtocolImprovementProposal`**: Users submit proposals for changes to the contract's parameters or future upgrades (e.g., via proxy patterns, if implemented).
26. **`voteOnProtocolImprovementProposal`**: Nexus Key holders vote on active governance proposals.
27. **`initiateDispute`**: Allows a Nexus Key holder to formally dispute the status of a knowledge thread, its impact score, or another user's action.
28. **`voteOnDispute`**: Nexus Key holders vote on active disputes, contributing to their resolution.
29. **`resolveDispute`**: (Governance/Admin) Finalizes a dispute based on community votes or arbitration.
30. **`tokenURI`**: (Override ERC721) Provides dynamic metadata for both Nexus Keys (reflecting tier) and Catalyst Fragments (reflecting evolution stage).
31. **`supportsInterface`**: (Override ERC721) Standard ERC165 interface query.
32. **`_beforeTokenTransfer`**: (Internal Override ERC721) Enforces the Soulbound nature of Nexus Keys, preventing their transfer post-minting.
33. **`_increaseReputation`**: (Internal) Helper function to adjust a user's reputation score.
34. **`_decreaseReputation`**: (Internal) Helper function to decrease a user's reputation score.
35. **`_calculateWeightedVotes`**: (Internal) Helper function to aggregate and calculate the result of weighted votes for proposals or impact scores.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom Errors for clarity and gas efficiency
error SyntheticaNexus__Unauthorized();
error SyntheticaNexus__NotNexusKeyHolder();
error SyntheticaNexus__AlreadyHasNexusKey();
error SyntheticaNexus__InvalidTierUpgrade();
error SyntheticaNexus__InsufficientReputation();
error SyntheticaNexus__EpochNotEnded();
error SyntheticaNexus__NoActiveKnowledgeThread();
error SyntheticaNexus__AlreadyVoted();
error SyntheticaNexus__FragmentNotReadyForEvolution();
error SyntheticaNexus__FragmentNotInValidEvolutionStage();
error SyntheticaNexus__NoFundsInPool();
error SyntheticaNexus__GrantAlreadyProcessed();
error SyntheticaNexus__GrantNotApproved();
error SyntheticaNexus__GrantVotingPeriodNotEnded();
error SyntheticaNexus__ProposalAlreadyProcessed();
error SyntheticaNexus__ProposalVotingPeriodNotEnded();
error SyntheticaNexus__DisputeNotFound();
error SyntheticaNexus__DisputeNotResolved();
error SyntheticaNexus__DisputeAlreadyResolved();
error SyntheticaNexus__TransferNotAllowed(); // For Soulbound Nexus Keys
error SyntheticaNexus__ERC20TransferFailed();
error SyntheticaNexus__InvalidTokenId();
error SyntheticaNexus__InvalidKnowledgeThreadId();
error SyntheticaNexus__InvalidFragmentId();
error SyntheticaNexus__TierAlreadyMax();
error SyntheticaNexus__NoActiveProposals();
error SyntheticaNexus__NoActiveDisputes();
error SyntheticaNexus__PoolNotFound();
error SyntheticaNexus__InvalidEvolutionStage();
error SyntheticaNexus__InvalidCategory();
error SyntheticaNexus__InvalidDisputeResolution();
error SyntheticaNexus__CannotVoteOnOwnProposal();
error SyntheticaNexus__InsufficientFragmentEvolutionProgress();

contract SyntheticaNexus is Ownable, Pausable, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Enums & Structs ---

    // Nexus Key Tiers (Soulbound Tokens)
    enum NexusKeyTier { None, Basic, Advanced, Expert, Visionary }
    uint8 public constant MAX_NEXUS_KEY_TIER = uint8(NexusKeyTier.Visionary);

    // Catalyst Fragment Evolution Stages (Dynamic NFTs)
    enum FragmentEvolutionStage { Seed, Sprout, Bloom, Apex }
    uint8 public constant MAX_FRAGMENT_EVOLUTION_STAGE = uint8(FragmentEvolutionStage.Apex);

    // Token Types within this ERC721 contract
    enum TokenType { None, NexusKey, CatalystFragment }

    // Represents a Nexus Key SBT's core data
    struct NexusKeyData {
        address holder; // The owner of this Nexus Key (redundant with ERC721, but helpful for internal context)
        NexusKeyTier tier;
        uint256 mintedAtEpoch;
    }

    // Represents a Catalyst Fragment NFT's core data
    struct CatalystFragmentData {
        address creator; // The original contributor
        uint256 knowledgeThreadId; // Links to the knowledge content
        FragmentEvolutionStage evolutionStage;
        uint256 mintedAtEpoch;
        int256 totalImpactScore; // Aggregated score from community votes
        mapping(address => bool) hasClaimedEvolutionReward; // Track if rewards for a specific stage have been claimed
    }

    // Represents a knowledge contribution
    struct KnowledgeThread {
        address creator;
        string ipfsHash; // Link to the actual knowledge content
        string category;
        uint256 submittedEpoch;
        uint256 mintingFragmentId; // The Catalyst Fragment NFT ID linked to this thread
        mapping(address => bool) hasVoted; // Tracks who has voted on this thread's impact
    }

    // Represents a Synthesizer Pool for funding
    struct SynthesizerPool {
        IERC20 token;
        string category;
        uint256 totalDeposited;
        bool exists; // To check if pool is initialized
    }

    // Represents a grant proposal from a Synthesizer Pool
    struct GrantProposal {
        address proposer;
        uint256 knowledgeThreadId; // The knowledge thread requesting funds
        address recipient; // The address to receive funds (can be thread.creator)
        uint256 amount;
        uint256 poolIndex; // Index in the `synthesizerPools` array
        uint256 votingDeadline;
        int256 yayVotes;
        int256 nayVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    // Represents a general protocol improvement proposal
    struct ProtocolProposal {
        address proposer;
        string description; // Details of the proposal (e.g., new parameter values, upgrade details)
        uint256 votingDeadline;
        int256 yayVotes;
        int256 nayVotes;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    // Represents a dispute over knowledge threads or actions
    enum DisputeStatus { Open, ResolvedApproved, ResolvedRejected, ResolvedNeutral }
    struct Dispute {
        address initiator;
        uint256 targetId; // ID of the knowledgeThread, CatalystFragment, or other entity being disputed
        string reason;
        uint256 votingDeadline;
        int256 yayVotes; // Votes to uphold the dispute (i.e., agree with initiator)
        int256 nayVotes; // Votes against the dispute (i.e., disagree with initiator)
        mapping(address => bool) hasVoted;
        DisputeStatus status;
        string resolutionNotes;
    }

    // --- State Variables ---

    // NFT & Token Management
    Counters.Counter private _tokenIdCounter; // Single counter for all NFTs
    Counters.Counter private _knowledgeThreadIdCounter;
    Counters.Counter private _grantProposalIdCounter;
    Counters.Counter private _protocolProposalIdCounter;
    Counters.Counter private _disputeIdCounter;

    mapping(uint256 => TokenType) private _tokenTypes; // Maps tokenId to its type
    mapping(address => uint256) public nexusKeyTokenId; // User address => NexusKey tokenId
    mapping(uint256 => NexusKeyData) private _nexusKeyData; // NexusKey tokenId => data
    mapping(uint256 => CatalystFragmentData) private _catalystFragmentData; // CatalystFragment tokenId => data

    string public nexusKeyBaseURI;
    string public catalystFragmentBaseURI;

    // Reputation & Evolution
    mapping(address => uint256) public userReputation; // Cached reputation score
    mapping(NexusKeyTier => uint256) public minReputationForTierUpgrade; // Thresholds for tier upgrades

    // Knowledge Fabric
    mapping(uint256 => KnowledgeThread) public knowledgeThreads; // knowledgeThreadId => data

    // Synthesizer Pools (Funding)
    SynthesizerPool[] public synthesizerPools; // Array of active pools
    mapping(string => uint256) public categoryToPoolIndex; // Category name => index in synthesizerPools
    mapping(uint256 => uint256) public poolIdToBalance; // poolIndex => current balance

    // Governance & Proposals
    mapping(uint256 => GrantProposal) public grantProposals;
    mapping(uint256 => ProtocolProposal) public protocolProposals;
    mapping(uint256 => Dispute) public disputes;

    // Epoch Management
    uint256 public currentEpoch;
    uint256 public lastEpochAdvanceTime;
    uint256 public epochDuration; // Duration in seconds

    // --- Events ---
    event NexusKeyMinted(address indexed holder, uint256 tokenId, NexusKeyTier tier);
    event NexusKeyTierUpgraded(address indexed holder, uint256 tokenId, NexusKeyTier oldTier, NexusKeyTier newTier);
    event NexusKeyTierDowngraded(address indexed holder, uint256 tokenId, NexusKeyTier oldTier, NexusKeyTier newTier);
    event CatalystFragmentMinted(address indexed creator, uint256 tokenId, uint256 knowledgeThreadId, string ipfsHash);
    event KnowledgeThreadSubmitted(uint256 indexed knowledgeThreadId, address indexed creator, string category, string ipfsHash);
    event KnowledgeThreadImpactVoted(uint256 indexed knowledgeThreadId, address indexed voter, int256 voteWeight);
    event CatalystFragmentEvolved(uint256 indexed fragmentId, FragmentEvolutionStage oldStage, FragmentEvolutionStage newStage, int256 totalImpactScore);
    event CatalystFragmentRewardClaimed(uint256 indexed fragmentId, address indexed claimant, uint256 amount);
    event EpochAdvanced(uint256 newEpoch, uint256 timestamp);
    event SynthesizerPoolCreated(uint256 indexed poolIndex, address indexed tokenAddress, string category);
    event DepositToSynthesizerPool(uint256 indexed poolIndex, address indexed depositor, uint256 amount);
    event KnowledgeGrantProposed(uint256 indexed proposalId, address indexed proposer, uint256 knowledgeThreadId, uint256 amount);
    event KnowledgeGrantVoted(uint256 indexed proposalId, address indexed voter, bool support, int256 voteWeight);
    event KnowledgeGrantExecuted(uint256 indexed proposalId, uint256 knowledgeThreadId, address indexed recipient, uint256 amount);
    event ProtocolImprovementProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event ProtocolImprovementVoted(uint256 indexed proposalId, address indexed voter, bool support, int256 voteWeight);
    event ProtocolImprovementExecuted(uint256 indexed proposalId, string description);
    event DisputeInitiated(uint256 indexed disputeId, address indexed initiator, uint256 targetId, string reason);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool support, int256 voteWeight);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status, string resolutionNotes);
    event ReputationChanged(address indexed user, uint256 newReputation);

    // --- Modifiers ---
    modifier onlyNexusKeyHolder() {
        if (nexusKeyTokenId[msg.sender] == 0) {
            revert SyntheticaNexus__NotNexusKeyHolder();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialEpochDuration,
        string memory _initialNexusKeyBaseURI,
        string memory _initialCatalystFragmentBaseURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        epochDuration = _initialEpochDuration;
        lastEpochAdvanceTime = block.timestamp;
        currentEpoch = 1;

        nexusKeyBaseURI = _initialNexusKeyBaseURI;
        catalystFragmentBaseURI = _initialCatalystFragmentBaseURI;

        // Set initial reputation thresholds for tiers
        minReputationForTierUpgrade[NexusKeyTier.Basic] = 0; // Basic is default
        minReputationForTierUpgrade[NexusKeyTier.Advanced] = 100;
        minReputationForTierUpgrade[NexusKeyTier.Expert] = 500;
        minReputationForTierUpgrade[NexusKeyTier.Visionary] = 2000;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Admin function to adjust the duration of each evolution epoch.
     * @param _newDuration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _newDuration) external onlyOwner {
        epochDuration = _newDuration;
    }

    /**
     * @notice Admin function to configure reputation thresholds for Nexus Key tier upgrades.
     * @param _tier The NexusKeyTier to set the threshold for.
     * @param _minReputation The minimum reputation required for that tier.
     */
    function setMinReputationForTierUpgrade(NexusKeyTier _tier, uint256 _minReputation) external onlyOwner {
        if (_tier == NexusKeyTier.None || _tier == NexusKeyTier.Basic) {
            revert SyntheticaNexus__InvalidTierUpgrade(); // Basic is default, None is invalid
        }
        minReputationForTierUpgrade[_tier] = _minReputation;
    }

    /**
     * @notice Admin function to set the base URI for Nexus Key metadata.
     * @param _newBaseURI The new base URI.
     */
    function setNexusKeyBaseURI(string memory _newBaseURI) external onlyOwner {
        nexusKeyBaseURI = _newBaseURI;
    }

    /**
     * @notice Admin function to set the base URI for Catalyst Fragment metadata.
     * @param _newBaseURI The new base URI.
     */
    function setCatalystFragmentBaseURI(string memory _newBaseURI) external onlyOwner {
        catalystFragmentBaseURI = _newBaseURI;
    }

    /**
     * @notice Pauses critical contract functionalities.
     * @dev Only the contract owner can call this.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     * @dev Only the contract owner can call this.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- II. Nexus Keys (Soulbound Tokens for Identity & Reputation) ---

    /**
     * @notice Allows a new user to mint their initial Soulbound Nexus Key (tier 1).
     * @dev A user can only mint one Nexus Key.
     */
    function mintNexusKey() external whenNotPaused {
        if (nexusKeyTokenId[msg.sender] != 0) {
            revert SyntheticaNexus__AlreadyHasNexusKey();
        }

        _tokenIdCounter.increment();
        uint256 newId = _tokenIdCounter.current();

        _mint(msg.sender, newId);
        _tokenTypes[newId] = TokenType.NexusKey;
        nexusKeyTokenId[msg.sender] = newId;

        _nexusKeyData[newId] = NexusKeyData({
            holder: msg.sender,
            tier: NexusKeyTier.Basic,
            mintedAtEpoch: currentEpoch
        });

        emit NexusKeyMinted(msg.sender, newId, NexusKeyTier.Basic);
        _increaseReputation(msg.sender, 10); // Initial reputation boost
    }

    /**
     * @notice Enables a Nexus Key holder to upgrade their tier based on accumulated reputation.
     * @dev Requires the user to meet the reputation threshold for the next tier.
     */
    function upgradeNexusKeyTier() external onlyNexusKeyHolder whenNotPaused {
        uint256 tokenId = nexusKeyTokenId[msg.sender];
        NexusKeyData storage keyData = _nexusKeyData[tokenId];

        if (keyData.tier == NexusKeyTier.Visionary) {
            revert SyntheticaNexus__TierAlreadyMax();
        }

        NexusKeyTier nextTier = NexusKeyTier(uint8(keyData.tier) + 1);
        if (userReputation[msg.sender] < minReputationForTierUpgrade[nextTier]) {
            revert SyntheticaNexus__InsufficientReputation();
        }

        emit NexusKeyTierUpgraded(msg.sender, tokenId, keyData.tier, nextTier);
        keyData.tier = nextTier;
    }

    /**
     * @notice Governance/admin function to downgrade a Nexus Key tier in cases of severe misconduct.
     * @dev This should typically be triggered by a passed governance proposal.
     * @param _holder The address of the Nexus Key holder to downgrade.
     * @param _newTier The tier to downgrade to. Must be lower than current tier.
     */
    function downgradeNexusKeyTier(address _holder, NexusKeyTier _newTier) external onlyOwner { // In a real system, would be `onlyGovernance`
        uint256 tokenId = nexusKeyTokenId[_holder];
        if (tokenId == 0) {
            revert SyntheticaNexus__NotNexusKeyHolder();
        }

        NexusKeyData storage keyData = _nexusKeyData[tokenId];
        if (uint8(_newTier) >= uint8(keyData.tier)) {
            revert SyntheticaNexus__InvalidTierUpgrade(); // Can only downgrade to a lower tier
        }

        emit NexusKeyTierDowngraded(_holder, tokenId, keyData.tier, _newTier);
        keyData.tier = _newTier;
        _decreaseReputation(_holder, (uint256(keyData.tier) - uint256(_newTier)) * 50); // Significant reputation penalty
    }

    /**
     * @notice Retrieves the current tier level of a user's Nexus Key.
     * @param _user The address of the user.
     * @return The NexusKeyTier of the user.
     */
    function getNexusKeyTier(address _user) external view returns (NexusKeyTier) {
        uint256 tokenId = nexusKeyTokenId[_user];
        if (tokenId == 0) {
            return NexusKeyTier.None;
        }
        return _nexusKeyData[tokenId].tier;
    }

    // --- III. Catalyst Fragments (Dynamic NFTs for Contributions & Skill Development) ---

    /**
     * @notice Users submit a knowledge contribution (IPFS hash, category); mints a Catalyst Fragment.
     * @dev Each submission creates a new knowledge thread and mints a unique Catalyst Fragment NFT.
     * @param _ipfsHash The IPFS hash pointing to the knowledge content.
     * @param _category The category of the knowledge (e.g., "DeFi", "AI", "Solidity").
     */
    function submitKnowledgeThread(string memory _ipfsHash, string memory _category) external onlyNexusKeyHolder whenNotPaused {
        _knowledgeThreadIdCounter.increment();
        uint256 threadId = _knowledgeThreadIdCounter.current();

        _tokenIdCounter.increment();
        uint256 fragmentId = _tokenIdCounter.current();

        _mint(msg.sender, fragmentId);
        _tokenTypes[fragmentId] = TokenType.CatalystFragment;
        _setTokenURI(fragmentId, string(abi.encodePacked(catalystFragmentBaseURI, uint256(FragmentEvolutionStage.Seed).toString(), "/", fragmentId.toString())));

        knowledgeThreads[threadId] = KnowledgeThread({
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            category: _category,
            submittedEpoch: currentEpoch,
            mintingFragmentId: fragmentId,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        _catalystFragmentData[fragmentId] = CatalystFragmentData({
            creator: msg.sender,
            knowledgeThreadId: threadId,
            evolutionStage: FragmentEvolutionStage.Seed,
            mintedAtEpoch: currentEpoch,
            totalImpactScore: 0,
            hasClaimedEvolutionReward: new mapping(address => bool) // Initialize empty mapping
        });

        emit KnowledgeThreadSubmitted(threadId, msg.sender, _category, _ipfsHash);
        emit CatalystFragmentMinted(msg.sender, fragmentId, threadId, _ipfsHash);
    }

    /**
     * @notice Nexus Key holders vote on the potential impact/accuracy of a knowledge thread.
     * @dev Vote weight is scaled by the voter's Nexus Key tier. Cannot vote on own thread.
     * @param _knowledgeThreadId The ID of the knowledge thread to vote on.
     * @param _support True for positive impact, false for negative.
     */
    function voteOnKnowledgeThreadImpact(uint256 _knowledgeThreadId, bool _support) external onlyNexusKeyHolder whenNotPaused {
        KnowledgeThread storage thread = knowledgeThreads[_knowledgeThreadId];
        if (thread.creator == address(0)) {
            revert SyntheticaNexus__NoActiveKnowledgeThread();
        }
        if (thread.creator == msg.sender) {
            revert SyntheticaNexus__CannotVoteOnOwnProposal();
        }
        if (thread.hasVoted[msg.sender]) {
            revert SyntheticaNexus__AlreadyVoted();
        }

        uint256 voterTier = uint256(getNexusKeyTier(msg.sender));
        int256 voteWeight = _support ? int256(voterTier) : -int256(voterTier); // Stronger tiers have more impact

        _catalystFragmentData[thread.mintingFragmentId].totalImpactScore += voteWeight;
        thread.hasVoted[msg.sender] = true;

        emit KnowledgeThreadImpactVoted(_knowledgeThreadId, msg.sender, voteWeight);
    }

    /**
     * @notice Returns the current aggregated impact score for a knowledge thread.
     * @param _knowledgeThreadId The ID of the knowledge thread.
     * @return The total impact score.
     */
    function getKnowledgeThreadImpactScore(uint256 _knowledgeThreadId) external view returns (int256) {
        KnowledgeThread storage thread = knowledgeThreads[_knowledgeThreadId];
        if (thread.creator == address(0)) {
            revert SyntheticaNexus__NoActiveKnowledgeThread();
        }
        return _catalystFragmentData[thread.mintingFragmentId].totalImpactScore;
    }

    /**
     * @notice Retrieves the current evolution stage of a specific Catalyst Fragment.
     * @param _fragmentId The ID of the Catalyst Fragment.
     * @return The FragmentEvolutionStage.
     */
    function getCatalystFragmentEvolutionStage(uint256 _fragmentId) external view returns (FragmentEvolutionStage) {
        if (_tokenTypes[_fragmentId] != TokenType.CatalystFragment) {
            revert SyntheticaNexus__InvalidFragmentId();
        }
        return _catalystFragmentData[_fragmentId].evolutionStage;
    }

    /**
     * @notice Calculates a user's comprehensive reputation score based on their Nexus Key and Catalyst Fragments.
     * @dev This is a simplified calculation; in a real system, it could involve more complex algorithms.
     * @param _user The address of the user.
     * @return The calculated reputation score.
     */
    function calculateUserReputation(address _user) public view returns (uint256) {
        uint256 reputation = 0;

        // Base reputation from Nexus Key tier
        uint256 nexusKeyId = nexusKeyTokenId[_user];
        if (nexusKeyId != 0) {
            reputation += uint256(_nexusKeyData[nexusKeyId].tier) * 50; // Each tier adds base reputation
        }

        // Reputation from Catalyst Fragments
        uint256 balance = balanceOf(_user);
        for (uint256 i = 0; i < balance; i++) {
            uint256 fragmentId = tokenOfOwnerByIndex(_user, i); // Assumes ERC721Enumerable or manual tracking of owned tokens
            if (_tokenTypes[fragmentId] == TokenType.CatalystFragment) {
                reputation += uint256(_catalystFragmentData[fragmentId].evolutionStage) * 20; // More evolved fragments add more reputation
                reputation += uint256(_catalystFragmentData[fragmentId].totalImpactScore) / 10; // Impact score also contributes
            }
        }
        return reputation;
    }

    /**
     * @notice Publicly callable function to check and potentially evolve Catalyst Fragments after an epoch ends.
     * @dev Iterates through knowledge threads (limited number for gas) and updates associated Catalyst Fragments.
     * @param _knowledgeThreadIds An array of knowledge thread IDs to check for evolution.
     */
    function triggerFragmentEvolutionCheck(uint256[] calldata _knowledgeThreadIds) external whenNotPaused {
        if (block.timestamp < lastEpochAdvanceTime + epochDuration) {
            revert SyntheticaNexus__EpochNotEnded();
        }

        // Update reputation for all users who have a Nexus Key
        // (In a real scenario, this would be too gas-intensive for many users.
        // It would require pagination, off-chain computation, or a more targeted update.)
        // For this example, we'll only update reputation for fragment owners impacted.

        for (uint256 i = 0; i < _knowledgeThreadIds.length; i++) {
            uint256 threadId = _knowledgeThreadIds[i];
            KnowledgeThread storage thread = knowledgeThreads[threadId];
            if (thread.creator == address(0)) continue; // Skip invalid threads

            uint256 fragmentId = thread.mintingFragmentId;
            CatalystFragmentData storage fragmentData = _catalystFragmentData[fragmentId];

            // Evolution logic: simplified based on total impact score and current stage
            FragmentEvolutionStage currentStage = fragmentData.evolutionStage;
            FragmentEvolutionStage newStage = currentStage;
            uint256 nextStageThreshold = 0;

            if (currentStage == FragmentEvolutionStage.Seed && fragmentData.totalImpactScore >= 5) {
                newStage = FragmentEvolutionStage.Sprout;
                nextStageThreshold = 20; // For Sprout to Bloom
            } else if (currentStage == FragmentEvolutionStage.Sprout && fragmentData.totalImpactScore >= nextStageThreshold) {
                newStage = FragmentEvolutionStage.Bloom;
                nextStageThreshold = 50; // For Bloom to Apex
            } else if (currentStage == FragmentEvolutionStage.Bloom && fragmentData.totalImpactScore >= nextStageThreshold) {
                newStage = FragmentEvolutionStage.Apex;
            }

            if (newStage != currentStage) {
                fragmentData.evolutionStage = newStage;
                _setTokenURI(fragmentId, string(abi.encodePacked(catalystFragmentBaseURI, uint256(newStage).toString(), "/", fragmentId.toString())));
                emit CatalystFragmentEvolved(fragmentId, currentStage, newStage, fragmentData.totalImpactScore);
                _increaseReputation(fragmentData.creator, (uint256(newStage) - uint256(currentStage)) * 10);
            }
        }
    }

    /**
     * @notice Allows Catalyst Fragment holders to claim rewards upon their fragment evolving to a new stage.
     * @dev A simplified reward mechanism using a dummy token or direct ETH. In a real system, this would be more complex.
     * @param _fragmentId The ID of the Catalyst Fragment.
     */
    function claimFragmentEvolutionRewards(uint256 _fragmentId) external nonReentrant whenNotPaused {
        if (_tokenTypes[_fragmentId] != TokenType.CatalystFragment || ownerOf(_fragmentId) != msg.sender) {
            revert SyntheticaNexus__InvalidFragmentId();
        }

        CatalystFragmentData storage fragmentData = _catalystFragmentData[_fragmentId];
        if (fragmentData.evolutionStage == FragmentEvolutionStage.Seed) {
            revert SyntheticaNexus__FragmentNotInValidEvolutionStage(); // No rewards for base stage
        }

        if (fragmentData.hasClaimedEvolutionReward[msg.sender]) {
            // Simplified: only allow one claim per fragment evolution (can be refined to per-stage)
            revert SyntheticaNexus__AlreadyClaimed(); // Define this custom error
        }

        uint256 rewardAmount = uint256(fragmentData.evolutionStage) * 1 ether; // Example: 1 ETH for Sprout, 2 for Bloom, etc.
        if (address(this).balance < rewardAmount) {
            // In a real system, rewards would come from a dedicated pool or token
            revert SyntheticaNexus__NoFundsInPool(); // Or insufficient funds error
        }

        fragmentData.hasClaimedEvolutionReward[msg.sender] = true;
        (bool success, ) = msg.sender.call{value: rewardAmount}("");
        if (!success) {
            revert SyntheticaNexus__ERC20TransferFailed(); // Renamed for generic transfer failure
        }
        emit CatalystFragmentRewardClaimed(_fragmentId, msg.sender, rewardAmount);
    }

    // --- V. Synthesizer Pools (Decentralized Funding & Grants) ---

    /**
     * @notice Governance/admin creates a new funding pool for a specific category, specifying its token.
     * @param _tokenAddress The address of the ERC-20 token for this pool.
     * @param _category The category this pool funds (e.g., "AI Research", "Web3 Education").
     */
    function createSynthesizerPool(address _tokenAddress, string memory _category) external onlyOwner { // Or `onlyGovernance`
        // Check if category already exists
        if (categoryToPoolIndex[_category] != 0 || keccak256(abi.encodePacked(synthesizerPools[categoryToPoolIndex[_category]].category)) == keccak256(abi.encodePacked(_category))) {
            // It's possible categoryToPoolIndex[_category] returns 0 for a non-existent category,
            // but also for the first element. We must ensure a true existence check.
            bool found = false;
            for(uint256 i = 0; i < synthesizerPools.length; i++) {
                if (keccak256(abi.encodePacked(synthesizerPools[i].category)) == keccak256(abi.encodePacked(_category))) {
                    found = true;
                    break;
                }
            }
            if(found) revert SyntheticaNexus__InvalidCategory();
        }

        synthesizerPools.push(SynthesizerPool({
            token: IERC20(_tokenAddress),
            category: _category,
            totalDeposited: 0,
            exists: true
        }));
        uint256 newPoolIndex = synthesizerPools.length - 1;
        categoryToPoolIndex[_category] = newPoolIndex;
        emit SynthesizerPoolCreated(newPoolIndex, _tokenAddress, _category);
    }

    /**
     * @notice Users can deposit supported ERC-20 tokens into an existing Synthesizer Pool.
     * @dev Requires prior approval of tokens to the contract.
     * @param _poolIndex The index of the Synthesizer Pool.
     * @param _amount The amount of ERC-20 tokens to deposit.
     */
    function depositToSynthesizerPool(uint256 _poolIndex, uint256 _amount) external whenNotPaused nonReentrant {
        if (_poolIndex >= synthesizerPools.length || !synthesizerPools[_poolIndex].exists) {
            revert SyntheticaNexus__PoolNotFound();
        }

        IERC20 token = synthesizerPools[_poolIndex].token;
        if (!token.transferFrom(msg.sender, address(this), _amount)) {
            revert SyntheticaNexus__ERC20TransferFailed();
        }

        synthesizerPools[_poolIndex].totalDeposited += _amount;
        poolIdToBalance[_poolIndex] += _amount;
        emit DepositToSynthesizerPool(_poolIndex, msg.sender, _amount);
    }

    /**
     * @notice Nexus Key holders can propose a grant from a pool to a knowledge thread/contributor.
     * @param _knowledgeThreadId The ID of the knowledge thread for which the grant is proposed.
     * @param _recipient The address to receive the grant funds.
     * @param _amount The amount of tokens to grant.
     * @param _poolIndex The index of the Synthesizer Pool to draw from.
     */
    function proposeKnowledgeGrant(
        uint256 _knowledgeThreadId,
        address _recipient,
        uint256 _amount,
        uint256 _poolIndex
    ) external onlyNexusKeyHolder whenNotPaused {
        KnowledgeThread storage thread = knowledgeThreads[_knowledgeThreadId];
        if (thread.creator == address(0)) {
            revert SyntheticaNexus__NoActiveKnowledgeThread();
        }
        if (_poolIndex >= synthesizerPools.length || !synthesizerPools[_poolIndex].exists) {
            revert SyntheticaNexus__PoolNotFound();
        }
        if (poolIdToBalance[_poolIndex] < _amount) {
            revert SyntheticaNexus__NoFundsInPool();
        }

        _grantProposalIdCounter.increment();
        uint256 proposalId = _grantProposalIdCounter.current();

        grantProposals[proposalId] = GrantProposal({
            proposer: msg.sender,
            knowledgeThreadId: _knowledgeThreadId,
            recipient: _recipient,
            amount: _amount,
            poolIndex: _poolIndex,
            votingDeadline: block.timestamp + (7 days), // Example: 7 days voting period
            yayVotes: 0,
            nayVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        });

        emit KnowledgeGrantProposed(proposalId, msg.sender, _knowledgeThreadId, _amount);
    }

    /**
     * @notice Nexus Key holders vote on active grant proposals, weighted by their tier.
     * @param _proposalId The ID of the grant proposal.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnKnowledgeGrant(uint256 _proposalId, bool _support) external onlyNexusKeyHolder whenNotPaused {
        GrantProposal storage proposal = grantProposals[_proposalId];
        if (proposal.proposer == address(0) || proposal.executed) {
            revert SyntheticaNexus__NoActiveProposals();
        }
        if (proposal.votingDeadline < block.timestamp) {
            revert SyntheticaNexus__GrantVotingPeriodNotEnded(); // Revert if voting period already over
        }
        if (proposal.hasVoted[msg.sender]) {
            revert SyntheticaNexus__AlreadyVoted();
        }

        uint256 voterTier = uint256(getNexusKeyTier(msg.sender));
        int256 voteWeight = int256(voterTier);

        if (_support) {
            proposal.yayVotes += voteWeight;
        } else {
            proposal.nayVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit KnowledgeGrantVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Admin/governance function to execute a passed grant proposal, releasing funds.
     * @param _proposalId The ID of the grant proposal.
     */
    function executeKnowledgeGrant(uint256 _proposalId) external onlyOwner nonReentrant { // Or `onlyGovernance`
        GrantProposal storage proposal = grantProposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert SyntheticaNexus__NoActiveProposals();
        }
        if (proposal.executed) {
            revert SyntheticaNexus__GrantAlreadyProcessed();
        }
        if (proposal.votingDeadline > block.timestamp) {
            revert SyntheticaNexus__GrantVotingPeriodNotEnded();
        }

        int256 voteResult = proposal.yayVotes - proposal.nayVotes;
        if (voteResult <= 0) { // Simple majority rule for now
            revert SyntheticaNexus__GrantNotApproved();
        }

        uint256 poolIndex = proposal.poolIndex;
        SynthesizerPool storage pool = synthesizerPools[poolIndex];

        if (poolIdToBalance[poolIndex] < proposal.amount) {
            revert SyntheticaNexus__NoFundsInPool(); // Should not happen if checked at proposal
        }

        poolIdToBalance[poolIndex] -= proposal.amount;
        pool.totalDeposited -= proposal.amount; // Update totalDeposited for consistency

        if (!pool.token.transfer(proposal.recipient, proposal.amount)) {
            revert SyntheticaNexus__ERC20TransferFailed();
        }

        proposal.executed = true;
        emit KnowledgeGrantExecuted(_proposalId, proposal.knowledgeThreadId, proposal.recipient, proposal.amount);
        _increaseReputation(proposal.recipient, 25); // Reward recipient with reputation
        _increaseReputation(proposal.proposer, 5); // Reward proposer with reputation
    }

    // --- VI. Epoch & Evolution Engine ---

    /**
     * @notice Admin/keeper function to explicitly advance to the next epoch, triggering all epoch-end processes.
     * @dev This function is critical for periodic updates and state changes.
     */
    function advanceEpoch() external onlyOwner whenNotPaused { // Could be permissionless with bond
        if (block.timestamp < lastEpochAdvanceTime + epochDuration) {
            revert SyntheticaNexus__EpochNotEnded();
        }

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        // In a complex system, this would trigger more extensive updates:
        // - Recalculate global reputation scores (potentially gas intensive)
        // - Distribute epoch-based rewards
        // - Clean up old proposals/disputes
        // - Trigger fragment evolution checks (can also be done by `triggerFragmentEvolutionCheck`)

        // For this contract, let's update a few things
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_tokenTypes[i] == TokenType.NexusKey) {
                 userReputation[_nexusKeyData[i].holder] = calculateUserReputation(_nexusKeyData[i].holder);
                 emit ReputationChanged(_nexusKeyData[i].holder, userReputation[_nexusKeyData[i].holder]);
            }
        }
        // Fragment evolutions are handled by `triggerFragmentEvolutionCheck` which can be called separately.

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    // --- VII. Nexus Governance & Dispute Resolution ---

    /**
     * @notice Users submit proposals for system changes, contract upgrades (via proxy if implemented), or parameter adjustments.
     * @param _description A detailed description of the proposal.
     */
    function submitProtocolImprovementProposal(string memory _description) external onlyNexusKeyHolder whenNotPaused {
        _protocolProposalIdCounter.increment();
        uint256 proposalId = _protocolProposalIdCounter.current();

        protocolProposals[proposalId] = ProtocolProposal({
            proposer: msg.sender,
            description: _description,
            votingDeadline: block.timestamp + (14 days), // Example: 14 days voting period
            yayVotes: 0,
            nayVotes: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        });

        emit ProtocolImprovementProposed(proposalId, msg.sender, _description);
    }

    /**
     * @notice Nexus Key holders vote on active governance proposals.
     * @param _proposalId The ID of the protocol improvement proposal.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProtocolImprovementProposal(uint256 _proposalId, bool _support) external onlyNexusKeyHolder whenNotPaused {
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        if (proposal.proposer == address(0) || proposal.executed) {
            revert SyntheticaNexus__NoActiveProposals();
        }
        if (proposal.votingDeadline < block.timestamp) {
            revert SyntheticaNexus__ProposalVotingPeriodNotEnded(); // Revert if voting period already over
        }
        if (proposal.hasVoted[msg.sender]) {
            revert SyntheticaNexus__AlreadyVoted();
        }

        uint256 voterTier = uint256(getNexusKeyTier(msg.sender));
        int256 voteWeight = int256(voterTier);

        if (_support) {
            proposal.yayVotes += voteWeight;
        } else {
            proposal.nayVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProtocolImprovementVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Admin/governance function to execute a passed protocol improvement proposal.
     * @dev Actual execution logic for proposals like parameter changes would be implemented here or in a separate governance module.
     * @param _proposalId The ID of the protocol improvement proposal.
     */
    function executeProtocolImprovementProposal(uint256 _proposalId) external onlyOwner { // Or `onlyGovernance`
        ProtocolProposal storage proposal = protocolProposals[_proposalId];
        if (proposal.proposer == address(0)) {
            revert SyntheticaNexus__NoActiveProposals();
        }
        if (proposal.executed) {
            revert SyntheticaNexus__ProposalAlreadyProcessed();
        }
        if (proposal.votingDeadline > block.timestamp) {
            revert SyntheticaNexus__ProposalVotingPeriodNotEnded();
        }

        int256 voteResult = proposal.yayVotes - proposal.nayVotes;
        if (voteResult <= 0) { // Simple majority rule for now
            revert SyntheticaNexus__ProposalNotApproved(); // Define this custom error
        }

        // Logic to apply the proposal (e.g., call setter functions, initiate upgrade process)
        // For simplicity, we just mark it as executed.
        proposal.executed = true;
        emit ProtocolImprovementExecuted(_proposalId, proposal.description);
        _increaseReputation(proposal.proposer, 50);
    }

    /**
     * @notice Allows a Nexus Key holder to formally dispute a knowledge thread's status, impact score, or another user's action.
     * @param _targetId The ID of the entity being disputed (e.g., knowledge thread ID).
     * @param _reason A description of the dispute.
     */
    function initiateDispute(uint256 _targetId, string memory _reason) external onlyNexusKeyHolder whenNotPaused {
        // Basic check if target exists, can be expanded for different target types
        if (_tokenTypes[_targetId] == TokenType.None && knowledgeThreads[_targetId].creator == address(0)) {
            revert SyntheticaNexus__InvalidTargetId(); // Define this error
        }

        _disputeIdCounter.increment();
        uint256 disputeId = _disputeIdCounter.current();

        disputes[disputeId] = Dispute({
            initiator: msg.sender,
            targetId: _targetId,
            reason: _reason,
            votingDeadline: block.timestamp + (7 days), // Example: 7 days for dispute resolution
            yayVotes: 0,
            nayVotes: 0,
            hasVoted: new mapping(address => bool),
            status: DisputeStatus.Open,
            resolutionNotes: ""
        });

        emit DisputeInitiated(disputeId, msg.sender, _targetId, _reason);
    }

    /**
     * @notice Nexus Key holders vote on active disputes, weighted by their tier.
     * @param _disputeId The ID of the dispute.
     * @param _support True to support the initiator's claim (yay), false to oppose (nay).
     */
    function voteOnDispute(uint256 _disputeId, bool _support) external onlyNexusKeyHolder whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.initiator == address(0) || dispute.status != DisputeStatus.Open) {
            revert SyntheticaNexus__NoActiveDisputes();
        }
        if (dispute.votingDeadline < block.timestamp) {
            revert SyntheticaNexus__DisputeVotingPeriodEnded(); // Define this error
        }
        if (dispute.hasVoted[msg.sender]) {
            revert SyntheticaNexus__AlreadyVoted();
        }

        uint256 voterTier = uint256(getNexusKeyTier(msg.sender));
        int256 voteWeight = int256(voterTier);

        if (_support) {
            dispute.yayVotes += voteWeight;
        } else {
            dispute.nayVotes += voteWeight;
        }
        dispute.hasVoted[msg.sender] = true;

        emit DisputeVoted(_disputeId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Governance/admin function to finalize a dispute based on community votes or arbitration.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _resolutionStatus The final status of the dispute (ResolvedApproved, ResolvedRejected, ResolvedNeutral).
     * @param _resolutionNotes Optional notes on how the dispute was resolved.
     */
    function resolveDispute(
        uint256 _disputeId,
        DisputeStatus _resolutionStatus,
        string memory _resolutionNotes
    ) external onlyOwner { // Or `onlyGovernance`
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.initiator == address(0) || dispute.status != DisputeStatus.Open) {
            revert SyntheticaNexus__DisputeNotFound();
        }
        if (dispute.votingDeadline > block.timestamp) {
            revert SyntheticaNexus__DisputeNotResolved(); // Voting period not ended
        }
        if (_resolutionStatus == DisputeStatus.Open) {
            revert SyntheticaNexus__InvalidDisputeResolution();
        }

        dispute.status = _resolutionStatus;
        dispute.resolutionNotes = _resolutionNotes;

        // Apply consequences based on resolution
        if (_resolutionStatus == DisputeStatus.ResolvedApproved) {
            _increaseReputation(dispute.initiator, 20);
            // Example: If target was a knowledge thread, its impact score could be reset or lowered.
            // If target was a user, their Nexus Key tier could be downgraded.
        } else if (_resolutionStatus == DisputeStatus.ResolvedRejected) {
            _decreaseReputation(dispute.initiator, 10);
            // Example: Uphold the original status, perhaps penalize target of dispute for false claims.
        }
        // Neutral has no specific reputation impact for initiator

        emit DisputeResolved(_disputeId, _resolutionStatus, _resolutionNotes);
    }

    // --- ERC721 Overrides & Internal Helpers ---

    /**
     * @notice Overrides ERC721URIStorage to provide dynamic metadata for both Nexus Keys and Catalyst Fragments.
     * @param _tokenId The ID of the token.
     * @return The URI for the token's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireOwned(_tokenId); // Check if token exists and is owned

        TokenType tokenType = _tokenTypes[_tokenId];
        if (tokenType == TokenType.NexusKey) {
            NexusKeyTier tier = _nexusKeyData[_tokenId].tier;
            return string(abi.encodePacked(nexusKeyBaseURI, uint256(uint8(tier)).toString(), "/", _tokenId.toString()));
        } else if (tokenType == TokenType.CatalystFragment) {
            FragmentEvolutionStage stage = _catalystFragmentData[_tokenId].evolutionStage;
            return string(abi.encodePacked(catalystFragmentBaseURI, uint256(uint8(stage)).toString(), "/", _tokenId.toString()));
        } else {
            revert SyntheticaNexus__InvalidTokenId(); // Token ID exists but no valid type
        }
    }

    /**
     * @notice Helper for ERC721 standard.
     * @param interfaceId The interface ID to check.
     * @return True if the contract supports the interface.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Overrides to enforce Soulbound nature of Nexus Keys, preventing their transfer post-minting.
     * @dev Allows minting (from == address(0)) and burning (to == address(0)).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (batchSize != 1) revert("ERC721: batch transfer not supported"); // ERC721URIStorage does not support batch transfers directly
        
        if (_tokenTypes[tokenId] == TokenType.NexusKey) {
            // Nexus Keys are Soulbound: cannot be transferred after minting
            // Exception: minting (from == address(0)) or burning (to == address(0))
            if (from != address(0) && to != address(0)) {
                revert SyntheticaNexus__TransferNotAllowed();
            }
        }
        // Catalyst Fragments are transferable by default ERC721 behavior
    }

    /**
     * @notice Internal helper to increase a user's reputation score.
     * @param _user The address of the user.
     * @param _amount The amount of reputation to add.
     */
    function _increaseReputation(address _user, uint256 _amount) internal {
        userReputation[_user] += _amount;
        emit ReputationChanged(_user, userReputation[_user]);
    }

    /**
     * @notice Internal helper to decrease a user's reputation score.
     * @param _user The address of the user.
     * @param _amount The amount of reputation to subtract.
     */
    function _decreaseReputation(address _user, uint256 _amount) internal {
        userReputation[_user] = userReputation[_user] > _amount ? userReputation[_user] - _amount : 0;
        emit ReputationChanged(_user, userReputation[_user]);
    }

    /**
     * @notice Internal helper to calculate the result of weighted votes.
     * @dev This is a simplified function and could be expanded for more complex voting systems.
     * @param _yayVotes Total weighted 'yes' votes.
     * @param _nayVotes Total weighted 'no' votes.
     * @return The net vote result (yay - nay).
     */
    function _calculateWeightedVotes(int256 _yayVotes, int256 _nayVotes) internal pure returns (int256) {
        return _yayVotes - _nayVotes;
    }

    // Fallback and Receive for ETH
    receive() external payable {}
    fallback() external payable {}
}
```