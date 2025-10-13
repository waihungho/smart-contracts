Here's a smart contract written in Solidity that embodies several advanced, creative, and trendy concepts. It focuses on adaptive protocol governance, dynamic utility NFTs, community sentiment aggregation, and reputation-based mechanics.

The core idea is an "Echelon Nexus Protocol" (ENP) where the protocol's state, asset properties, and governance rules can dynamically adapt based on on-chain metrics, collective intelligence, and predefined triggers. It introduces "Nexus Glyphs" as Dynamic Utility NFTs (DU-NFTs) whose value and power shift according to protocol states and user actions, and a "Prognostication" system for weighted community insights.

---

## EchelonNexusProtocol

**Outline:**

1.  **Libraries & Interfaces:**
    *   `IERC20`: Standard interface for the ERC-20 token used for staking and voting.
2.  **Enums:**
    *   `EchelonState`: Defines the current operational state of the protocol (e.g., `Discovery`, `Expansion`, `Consolidation`, `Adaptation`).
    *   `NFTTier`: Tiers for Nexus Glyphs, influencing their utility and power.
    *   `MetricType`: Types of participation metrics recorded for reputation scores.
3.  **Structs:**
    *   `NexusGlyph`: Details for each Dynamic Utility NFT, including its owner, tier, and delegation status.
    *   `Proposal`: Details for formal governance proposals, including state, votes, and execution details.
    *   `Prognostication`: User-submitted insights or directional signals, with associated stake.
    *   `VoterState`: Stores a user's current voting power and delegation status.
4.  **State Variables:**
    *   `owner`: The contract administrator.
    *   `currentEchelonState`: The protocol's global operational state.
    *   `nexusGlyphs`: Mapping from `tokenId` to `NexusGlyph` struct.
    *   `_glyphOwners`: Mapping from `tokenId` to `owner address` (for internal NFT-like management).
    *   `_glyphApprovals`: Mapping for single-glyph approvals.
    *   `_operatorApprovals`: Mapping for overall operator approvals.
    *   `_tokenURIs`: Mapping for Nexus Glyph metadata URIs.
    *   `proposals`: Mapping from `proposalId` to `Proposal` struct.
    *   `prognostications`: Mapping from `prognosticationHash` to `Prognostication` struct.
    *   `reputationScores`: Mapping from `address` to `score`.
    *   `voterStates`: Mapping from `address` to `VoterState` struct.
    *   `coreParameters`: Mapping for various adjustable protocol parameters.
    *   `dynamicFeeParameters`: Mapping for configurable fee rates.
    *   `totalGlyphsMinted`: Counter for `Nexus Glyph` IDs.
    *   `proposalCounter`: Counter for `Proposal` IDs.
    *   `votingToken`: The `IERC20` contract address used for staking/voting.
    *   `protocolYieldFunds`: Balance of funds available for yield distribution.
    *   `grantPoolFunds`: Balance of funds available for grants.
    *   `_paused`: A boolean to pause/unpause critical functions.
5.  **Events:**
    *   `EchelonStateTransitioned`, `NexusGlyphMinted`, `GlyphTierUpgraded`, `GlyphUtilityDelegated`, `GlyphUtilityReclaimed`, `PrognosticationSubmitted`, `ProposalCreated`, `VotedOnProposal`, `ProposalFinalized`, `YieldDistributed`, `GrantAllocated`, `ReputationRecorded`, `ParameterUpdated`, `FeeParameterUpdated`, `TransferGlyph`, `ApproveGlyph`, `ApprovalForAllGlyph`, `Paused`, `Unpaused`.
6.  **Modifiers:**
    *   `onlyOwner`: Restricts function access to the contract owner.
    *   `onlyGlyphOwnerOrApproved`: Restricts function to the Glyph owner or an approved operator.
    *   `whenNotPaused`: Prevents execution when the contract is paused.
    *   `whenPaused`: Prevents execution when the contract is not paused.

**Function Summary:**

**I. Core Protocol & State Management:**
1.  `constructor(address _votingTokenAddress)`: Initializes the contract, sets the owner, and specifies the ERC-20 token for staking/voting.
2.  `setInitialParameters(uint256 initialMinStake, uint256 initialPrognosticationLifespanBlocks)`: Allows the owner to set initial configuration parameters post-deployment.
3.  `transitionEchelonState(EchelonState newState)`: Changes the overarching operational state of the protocol, affecting rules and logic.
4.  `getCurrentEchelonState()`: Returns the protocol's current `EchelonState`.
5.  `updateCoreParameter(bytes32 paramKey, uint256 newValue)`: Allows governance-approved updates to key protocol parameters (e.g., voting thresholds, staking minimums).
6.  `pause()`: Pauses the contract, preventing critical operations.
7.  `unpause()`: Unpauses the contract, re-enabling operations.
8.  `withdrawProtocolFunds(address token, uint256 amount)`: Allows the owner to withdraw funds from the contract in case of emergencies or upgrades.

**II. Dynamic Utility NFTs (Nexus Glyphs) - Partial ERC-721-like implementation:**
9.  `mintNexusGlyph(address to, uint256 initialTier, string memory tokenURI_ )`: Mints a new Nexus Glyph to an address, setting its initial tier and metadata URI.
10. `_transferGlyph(address from, address to, uint256 tokenId)`: Internal function to handle actual glyph transfers.
11. `transferFromGlyph(address from, address to, uint256 tokenId)`: Allows an owner or approved operator to transfer a Nexus Glyph.
12. `approveGlyph(address to, uint256 tokenId)`: Grants approval to an address to manage a specific Nexus Glyph.
13. `setApprovalForAllGlyph(address operator, bool approved)`: Grants or revokes approval for an operator to manage all of the caller's Nexus Glyphs.
14. `getApprovedGlyph(uint256 tokenId)`: Returns the address approved for a specific Nexus Glyph.
15. `isApprovedForAllGlyph(address owner_, address operator)`: Checks if an operator is approved for all of an owner's Nexus Glyphs.
16. `ownerOfGlyph(uint256 tokenId)`: Returns the owner of a specific Nexus Glyph.
17. `upgradeGlyphTier(uint256 tokenId)`: Allows a Nexus Glyph owner to upgrade its tier, increasing its utility and power. Requires burning `VOTING_TOKEN` tokens.
18. `getGlyphCurrentUtility(uint256 tokenId)`: Calculates and returns the dynamic utility value of a Nexus Glyph based on its tier, Echelon State, and other factors.
19. `getGlyphPowerFactor(uint256 tokenId)`: Returns the current voting/staking power multiplier granted by a specific Nexus Glyph.
20. `delegateGlyphUtility(uint256 tokenId, address delegatee)`: Allows a Glyph owner to delegate its utility and power to another address.
21. `reclaimGlyphUtility(uint256 tokenId)`: Allows a Glyph owner to revoke a previously delegated utility.
22. `tokenURI(uint256 tokenId)`: Returns the URI for the Nexus Glyph's metadata.

**III. Adaptive Governance & Prognostications:**
23. `submitPrognostication(string memory _prognosticationHash, uint256 _stakeAmount)`: Users stake tokens to signal their support or belief in a particular future direction or outcome for the protocol.
24. `createProposal(bytes32 _proposalHash, uint256 _durationBlocks)`: Initiates a formal governance proposal that requires voting.
25. `voteOnProposal(uint256 proposalId, bool support)`: Allows users to cast their weighted votes on an active proposal.
26. `calculateConsensusScore(uint256 proposalId)`: Aggregates prognostication stakes and formal votes to determine a "consensus score" for a proposal.
27. `finalizeProposal(uint256 proposalId)`: Executes the actions of a proposal if it has passed and consensus is reached, potentially triggering state changes.
28. `getVotingPower(address voter)`: Calculates an address's current effective voting power based on staked tokens, Nexus Glyphs, and reputation.
29. `delegateVote(address delegatee)`: Delegates general voting power to another address.
30. `undelegateVote()`: Revokes general voting power delegation.

**IV. Resource Allocation & Dynamic Fees:**
31. `depositYieldFunds(uint256 amount)`: Allows depositing funds into the protocol's yield pool.
32. `distributeProtocolYield()`: Distributes accumulated protocol yield to eligible participants based on their contributions and Nexus Glyphs.
33. `depositGrantFunds(uint256 amount)`: Allows depositing funds into the protocol's grant pool.
34. `allocateGrant(address recipient, uint256 amount, string memory reasonHash)`: Distributes funds from a dedicated grant pool, typically decided by governance.
35. `claimAllocatedResources(bytes32 resourceId)`: Allows eligible users to claim resources (e.g., tokens, specific access rights) previously allocated to them.
36. `setDynamicFeeParameter(bytes32 feeKey, uint256 basisPoints)`: Allows governance to dynamically adjust various protocol fee parameters (e.g., minting fees, transaction fees).
37. `getEffectiveProtocolFee(bytes32 feeType)`: Returns the current effective fee rate for a specified operation, potentially varying by Echelon State.

**V. Reputation & On-Chain History:**
38. `recordParticipationMetric(address participant, uint256 metricType, uint256 value)`: Records specific actions or contributions of a participant, feeding into their reputation score.
39. `getReputationScore(address participant)`: Calculates and returns a participant's dynamic reputation score, influencing their voting power and eligibility.

---
**Smart Contract Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EchelonNexusProtocol
 * @dev A cutting-edge smart contract implementing adaptive protocol governance,
 *      dynamic utility NFTs (Nexus Glyphs), community prognostication for
 *      consensus building, and a reputation-based resource allocation system.
 *      The protocol's behavior dynamically adjusts based on its 'EchelonState'.
 *
 * Concepts:
 * - Adaptive Governance: Voting power is dynamic, influenced by staked tokens,
 *   Nexus Glyph holdings, and accumulated reputation. Governance decisions can
 *   trigger protocol state transitions.
 * - Dynamic Utility NFTs (Nexus Glyphs): NFTs whose properties (e.g., utility,
 *   power factor) change based on their tier, the global Echelon State, and
 *   owner interactions. They are partially ERC-721 compatible for internal
 *   management (ownerOf, transfer, approve) but not a full OZ ERC721.
 * - Prognostication System: Users stake tokens to submit "insights" or "signals"
 *   about desired protocol directions. These insights contribute to a "consensus score"
 *   alongside formal votes, influencing proposal outcomes.
 * - Echelon States: The protocol can transition between predefined operational states
 *   (e.g., Discovery, Expansion, Consolidation, Adaptation), each potentially
 *   modifying core parameters, fee structures, and asset utility.
 * - On-chain Reputation: A system to track and score participant contributions,
 *   which can further influence voting power, reward distribution, and access.
 * - Dynamic Fees: Protocol fees can be adjusted via governance, potentially based
 *   on Echelon State or other metrics.
 */

// Minimal ERC-20 Interface for interaction with the voting token
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EchelonNexusProtocol {

    // --- Enums ---
    enum EchelonState {
        Discovery,    // Initial phase, focused on growth and data collection
        Expansion,    // Active growth, higher incentives
        Consolidation, // Optimization, lower volatility, stable fees
        Adaptation    // Responsive state, parameters can be more rapidly adjusted
    }

    enum NFTTier {
        Base,         // Default tier
        Ascendant,    // Mid-tier, increased utility
        Apex          // Highest tier, maximum utility and influence
    }

    enum MetricType {
        ProposalVotes,        // Number of votes cast on proposals
        PrognosticationStakes, // Total value staked in prognostications
        GlyphUpgrades,        // Number of glyphs upgraded
        SuccessfulProposals   // Number of proposals initiated and passed
    }

    // --- Structs ---
    struct NexusGlyph {
        uint256 tokenId;
        NFTTier tier;
        address delegatedTo; // Address to which its utility/power is delegated
        uint256 mintBlock;
        string tokenURI_; // Stores the metadata URI
    }

    struct Proposal {
        uint256 id;
        bytes32 proposalHash; // A hash representing the proposal content/actions
        address proposer;
        uint256 creationBlock;
        uint256 endBlock;
        uint256 totalForVotes;
        uint256 totalAgainstVotes;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        mapping(address => uint256) voterInfluence; // Stores effective voting power at time of vote
    }

    struct Prognostication {
        string prognosticationHash; // A hash representing the insight/signal
        address submitter;
        uint256 stakeAmount; // Tokens staked for this prognostication
        uint256 submissionBlock;
        bool claimed; // If stake has been claimed back
    }

    struct VoterState {
        address delegatee; // Address to which general voting power is delegated
        uint256 stakedTokens; // Tokens directly staked for voting/power
    }

    // --- State Variables ---

    // Owner and Pausability
    address private _owner;
    bool private _paused;

    // Protocol State
    EchelonState public currentEchelonState;

    // Nexus Glyphs (Dynamic Utility NFTs)
    mapping(uint256 => NexusGlyph) public nexusGlyphs;
    uint256 private _totalGlyphsMinted; // Counter for unique tokenId
    mapping(uint256 => address) private _glyphOwners; // tokenId => owner
    mapping(uint256 => address) private _glyphApprovals; // tokenId => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved
    mapping(uint256 => string) private _tokenURIs; // tokenId => URI

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 private _proposalCounter; // Counter for unique proposalId
    mapping(bytes32 => Prognostication) public prognostications; // prognosticationHash => Prognostication

    // Reputation
    mapping(address => uint256) public reputationScores;

    // Voter State (Staking and Delegation)
    mapping(address => VoterState) public voterStates;

    // Protocol Parameters (adjustable by governance)
    mapping(bytes32 => uint256) public coreParameters;
    // Keys: "MIN_STAKE_FOR_PROGN", "PROG_LIFESPAN_BLOCKS", "PROPOSAL_THRESHOLD", "VOTE_QUORUM_PERCENT", "GLYPH_UPGRADE_COST"

    // Dynamic Fees
    mapping(bytes32 => uint256) public dynamicFeeParameters; // Key => basisPoints (e.g., "MINT_FEE", "TRANSFER_FEE")

    // Tokens
    IERC20 public immutable votingToken;
    uint256 public protocolYieldFunds;
    uint256 public grantPoolFunds;

    // --- Events ---
    event EchelonStateTransitioned(EchelonState indexed oldState, EchelonState indexed newState, uint256 timestamp);
    event NexusGlyphMinted(address indexed to, uint256 indexed tokenId, NFTTier tier, string tokenURI_);
    event GlyphTierUpgraded(address indexed owner, uint256 indexed tokenId, NFTTier oldTier, NFTTier newTier);
    event GlyphUtilityDelegated(address indexed owner, uint256 indexed tokenId, address indexed delegatee);
    event GlyphUtilityReclaimed(address indexed owner, uint256 indexed tokenId);

    event PrognosticationSubmitted(address indexed submitter, string prognosticationHash, uint256 stakeAmount, uint256 submissionBlock);
    event ProposalCreated(uint256 indexed proposalId, bytes32 proposalHash, address indexed proposer, uint256 endBlock);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalFinalized(uint256 indexed proposalId, bool passed, bool executed);

    event YieldDistributed(uint256 indexed totalAmount, uint256 timestamp);
    event GrantAllocated(uint256 indexed grantId, address indexed recipient, uint256 amount, string reasonHash);

    event ReputationRecorded(address indexed participant, MetricType indexed metricType, uint256 value, uint256 newScore);
    event ParameterUpdated(bytes32 indexed paramKey, uint256 oldValue, uint256 newValue);
    event FeeParameterUpdated(bytes32 indexed feeKey, uint256 oldValue, uint256 newValue);

    event TransferGlyph(address indexed from, address indexed to, uint256 indexed tokenId);
    event ApproveGlyph(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAllGlyph(address indexed owner, address indexed operator, bool approved);

    event Paused(address account);
    event Unpaused(address account);
    event ProtocolFundsWithdrawn(address indexed token, address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "ENP: Not owner");
        _;
    }

    modifier onlyGlyphOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ENP: Not owner nor approved");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "ENP: Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "ENP: Not paused");
        _;
    }

    // --- Constructor ---
    constructor(address _votingTokenAddress) {
        require(_votingTokenAddress != address(0), "ENP: Voting token address cannot be zero");
        _owner = msg.sender;
        votingToken = IERC20(_votingTokenAddress);
        currentEchelonState = EchelonState.Discovery;
        _paused = false;

        // Set default core parameters
        coreParameters["MIN_STAKE_FOR_PROGN"] = 100 * 10**18; // 100 tokens
        coreParameters["PROG_LIFESPAN_BLOCKS"] = 1000;      // Approx 4 hours @ 14s/block
        coreParameters["PROPOSAL_THRESHOLD"] = 1000 * 10**18; // 1000 tokens needed to create proposal
        coreParameters["VOTE_QUORUM_PERCENT"] = 20;         // 20% quorum
        coreParameters["GLYPH_UPGRADE_COST_ASCENDANT"] = 500 * 10**18;
        coreParameters["GLYPH_UPGRADE_COST_APEX"] = 1500 * 10**18;

        // Set default dynamic fee parameters (basis points, 10000 = 100%)
        dynamicFeeParameters["MINT_FEE"] = 500; // 5%
        dynamicFeeParameters["TRANSFER_FEE"] = 100; // 1%
    }

    // --- I. Core Protocol & State Management ---

    /**
     * @dev Allows the owner to set initial configuration parameters post-deployment.
     *      Can be called multiple times if parameters are not final.
     * @param initialMinStake Minimum tokens required to submit a prognostication.
     * @param initialPrognosticationLifespanBlocks Number of blocks a prognostication is active.
     */
    function setInitialParameters(uint256 initialMinStake, uint256 initialPrognosticationLifespanBlocks) external onlyOwner {
        _updateCoreParameter("MIN_STAKE_FOR_PROGN", initialMinStake);
        _updateCoreParameter("PROG_LIFESPAN_BLOCKS", initialPrognosticationLifespanBlocks);
    }

    /**
     * @dev Transitions the protocol to a new Echelon State.
     *      This function would typically be called via a governance proposal.
     *      State transitions can alter various protocol behaviors (e.g., incentives, fees).
     * @param newState The EchelonState to transition to.
     */
    function transitionEchelonState(EchelonState newState) external onlyOwner whenNotPaused {
        require(newState != currentEchelonState, "ENP: Already in this Echelon state");
        emit EchelonStateTransitioned(currentEchelonState, newState, block.timestamp);
        currentEchelonState = newState;
        // Logic here to apply state-specific parameter changes, e.g.:
        // if (newState == EchelonState.Expansion) {
        //     dynamicFeeParameters["MINT_FEE"] = 200; // Lower mint fee for expansion
        // }
    }

    /**
     * @dev Returns the protocol's current Echelon state.
     */
    function getCurrentEchelonState() external view returns (EchelonState) {
        return currentEchelonState;
    }

    /**
     * @dev Allows governance-approved updates to key protocol parameters.
     *      This function should be callable only by the contract itself after a successful proposal execution.
     * @param paramKey A bytes32 key identifying the parameter to update.
     * @param newValue The new value for the parameter.
     */
    function updateCoreParameter(bytes32 paramKey, uint256 newValue) external onlyOwner whenNotPaused {
        _updateCoreParameter(paramKey, newValue);
    }

    /**
     * @dev Internal helper for updating core parameters and emitting event.
     */
    function _updateCoreParameter(bytes32 paramKey, uint256 newValue) internal {
        uint256 oldValue = coreParameters[paramKey];
        coreParameters[paramKey] = newValue;
        emit ParameterUpdated(paramKey, oldValue, newValue);
    }

    /**
     * @dev Pauses the contract, preventing critical operations.
     *      Can only be called by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, re-enabling operations.
     *      Can only be called by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to withdraw specific tokens from the contract in emergency.
     *      This is a safeguard and should be used responsibly.
     * @param token The address of the token to withdraw (e.g., `votingToken` or any other ERC-20).
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawProtocolFunds(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "ENP: Invalid token address");
        require(amount > 0, "ENP: Amount must be greater than zero");
        
        IERC20 tokenContract = IERC20(token);
        require(tokenContract.transfer(_owner, amount), "ENP: Token withdrawal failed");
        
        emit ProtocolFundsWithdrawn(token, _owner, amount);
    }


    // --- II. Dynamic Utility NFTs (Nexus Glyphs) ---

    // ERC-721-like internal functions and getters

    function _existsGlyph(uint256 tokenId) internal view returns (bool) {
        return _glyphOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOfGlyph(tokenId);
        return (spender == owner_ || getApprovedGlyph(tokenId) == spender || isApprovedForAllGlyph(owner_, spender));
    }

    /**
     * @dev Mints a new Nexus Glyph to an address, setting its initial tier and metadata URI.
     *      Applies a minting fee in `votingToken`.
     * @param to The address to mint the glyph to.
     * @param initialTier The initial tier of the glyph.
     * @param tokenURI_ The metadata URI for the glyph.
     */
    function mintNexusGlyph(address to, uint256 initialTier, string memory tokenURI_) external whenNotPaused {
        require(to != address(0), "ENP: Mint to the zero address");
        require(initialTier >= NFTTier.Base && initialTier <= NFTTier.Apex, "ENP: Invalid NFT tier");

        uint256 fee = (coreParameters["GLYPH_MINT_PRICE"] * dynamicFeeParameters["MINT_FEE"]) / 10000;
        if (fee > 0) {
            require(votingToken.transferFrom(msg.sender, address(this), fee), "ENP: Token transfer failed for mint fee");
        }

        _totalGlyphsMinted++;
        uint256 newId = _totalGlyphsMinted;

        nexusGlyphs[newId] = NexusGlyph({
            tokenId: newId,
            tier: initialTier,
            delegatedTo: address(0),
            mintBlock: block.number,
            tokenURI_: tokenURI_
        });
        _glyphOwners[newId] = to;
        _tokenURIs[newId] = tokenURI_;

        emit NexusGlyphMinted(to, newId, initialTier, tokenURI_);
    }

    /**
     * @dev Internal function to handle actual glyph transfers without approval checks.
     */
    function _transferGlyph(address from, address to, uint256 tokenId) internal {
        require(ownerOfGlyph(tokenId) == from, "ENP: From address not owner of glyph");
        require(to != address(0), "ENP: Transfer to the zero address");
        
        // Clear approvals for the transferred glyph
        _approveGlyph(address(0), tokenId);

        _glyphOwners[tokenId] = to;
        nexusGlyphs[tokenId].delegatedTo = address(0); // Clear delegation on transfer
        emit TransferGlyph(from, to, tokenId);
    }

    /**
     * @dev Transfers ownership of a Nexus Glyph from one address to another.
     *      Caller must be the owner or an approved operator. Applies a transfer fee.
     * @param from The current owner of the glyph.
     * @param to The address to transfer the glyph to.
     * @param tokenId The ID of the glyph to transfer.
     */
    function transferFromGlyph(address from, address to, uint256 tokenId) external whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ENP: Caller is not owner nor approved");
        
        uint256 fee = (coreParameters["GLYPH_TRANSFER_PRICE"] * dynamicFeeParameters["TRANSFER_FEE"]) / 10000;
        if (fee > 0) {
            require(votingToken.transferFrom(msg.sender, address(this), fee), "ENP: Token transfer failed for transfer fee");
        }
        
        _transferGlyph(from, to, tokenId);
    }

    /**
     * @dev Approves another address to manage a specific Nexus Glyph.
     * @param to The address to approve.
     * @param tokenId The ID of the glyph.
     */
    function approveGlyph(address to, uint256 tokenId) public whenNotPaused {
        address owner_ = ownerOfGlyph(tokenId);
        require(to != owner_, "ENP: Approval to current owner");
        require(msg.sender == owner_ || isApprovedForAllGlyph(owner_, msg.sender), "ENP: Not owner nor approved for all");
        
        _approveGlyph(to, tokenId);
        emit ApproveGlyph(owner_, to, tokenId);
    }

    /**
     * @dev Internal function to set approval.
     */
    function _approveGlyph(address to, uint256 tokenId) internal {
        _glyphApprovals[tokenId] = to;
    }

    /**
     * @dev Sets or unsets the approval for an operator to manage all of the caller's Nexus Glyphs.
     * @param operator The address to approve or revoke approval for.
     * @param approved True to approve, false to revoke.
     */
    function setApprovalForAllGlyph(address operator, bool approved) external whenNotPaused {
        require(operator != msg.sender, "ENP: Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAllGlyph(msg.sender, operator, approved);
    }

    /**
     * @dev Returns the address approved for a specific Nexus Glyph.
     * @param tokenId The ID of the glyph.
     */
    function getApprovedGlyph(uint256 tokenId) public view returns (address) {
        require(_existsGlyph(tokenId), "ENP: Glyph does not exist");
        return _glyphApprovals[tokenId];
    }

    /**
     * @dev Checks if an operator is approved for all of an owner's Nexus Glyphs.
     * @param owner_ The owner of the glyphs.
     * @param operator The operator to check.
     */
    function isApprovedForAllGlyph(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev Returns the owner of a specific Nexus Glyph.
     * @param tokenId The ID of the glyph.
     */
    function ownerOfGlyph(uint256 tokenId) public view returns (address) {
        address owner_ = _glyphOwners[tokenId];
        require(owner_ != address(0), "ENP: Glyph does not exist");
        return owner_;
    }

    /**
     * @dev Allows a Nexus Glyph owner to upgrade its tier, increasing its utility and power.
     *      Requires burning `VOTING_TOKEN` tokens.
     * @param tokenId The ID of the glyph to upgrade.
     */
    function upgradeGlyphTier(uint256 tokenId) external onlyGlyphOwnerOrApproved(tokenId) whenNotPaused {
        NexusGlyph storage glyph = nexusGlyphs[tokenId];
        require(glyph.tier < NFTTier.Apex, "ENP: Glyph is already at the highest tier");

        uint256 upgradeCost;
        NFTTier oldTier = glyph.tier;
        NFTTier newTier;

        if (glyph.tier == NFTTier.Base) {
            upgradeCost = coreParameters["GLYPH_UPGRADE_COST_ASCENDANT"];
            newTier = NFTTier.Ascendant;
        } else if (glyph.tier == NFTTier.Ascendant) {
            upgradeCost = coreParameters["GLYPH_UPGRADE_COST_APEX"];
            newTier = NFTTier.Apex;
        } else {
            revert("ENP: Invalid glyph tier for upgrade");
        }

        require(votingToken.transferFrom(msg.sender, address(this), upgradeCost), "ENP: Token transfer failed for upgrade cost");

        glyph.tier = newTier;
        _recordParticipationMetric(msg.sender, MetricType.GlyphUpgrades, 1);
        emit GlyphTierUpgraded(msg.sender, tokenId, oldTier, newTier);
    }

    /**
     * @dev Calculates and returns the dynamic utility value of a Nexus Glyph.
     *      Utility can vary based on tier, Echelon State, and other factors.
     * @param tokenId The ID of the glyph.
     */
    function getGlyphCurrentUtility(uint256 tokenId) public view returns (uint256) {
        require(_existsGlyph(tokenId), "ENP: Glyph does not exist");
        NexusGlyph storage glyph = nexusGlyphs[tokenId];
        uint256 baseUtility;

        if (glyph.tier == NFTTier.Base) {
            baseUtility = 100;
        } else if (glyph.tier == NFTTier.Ascendant) {
            baseUtility = 300;
        } else if (glyph.tier == NFTTier.Apex) {
            baseUtility = 1000;
        }

        // Example: Boost utility in Expansion state
        if (currentEchelonState == EchelonState.Expansion) {
            baseUtility = (baseUtility * 120) / 100; // 20% boost
        }
        // Further logic can be added based on other factors

        return baseUtility;
    }

    /**
     * @dev Returns the current voting/staking power multiplier granted by a specific Nexus Glyph.
     *      This is separate from utility but often correlated.
     * @param tokenId The ID of the glyph.
     */
    function getGlyphPowerFactor(uint256 tokenId) public view returns (uint256) {
        require(_existsGlyph(tokenId), "ENP: Glyph does not exist");
        NexusGlyph storage glyph = nexusGlyphs[tokenId];
        uint256 powerFactor;

        if (glyph.tier == NFTTier.Base) {
            powerFactor = 1; // 1x multiplier
        } else if (glyph.tier == NFTTier.Ascendant) {
            powerFactor = 3; // 3x multiplier
        } else if (glyph.tier == NFTTier.Apex) {
            powerFactor = 10; // 10x multiplier
        }

        // Example: Power can decay over time if not engaged, or boost based on state
        // uint256 ageBlocks = block.number - glyph.mintBlock;
        // if (ageBlocks > 5000) powerFactor = (powerFactor * 80) / 100; // 20% decay

        return powerFactor;
    }

    /**
     * @dev Allows a Glyph owner to delegate its utility and power to another address.
     *      The delegatee will gain the Glyph's benefits in governance calculations.
     * @param tokenId The ID of the glyph to delegate.
     * @param delegatee The address to delegate utility/power to.
     */
    function delegateGlyphUtility(uint256 tokenId, address delegatee) external onlyGlyphOwnerOrApproved(tokenId) whenNotPaused {
        require(delegatee != address(0), "ENP: Delegatee cannot be zero address");
        require(delegatee != ownerOfGlyph(tokenId), "ENP: Cannot delegate to self");

        NexusGlyph storage glyph = nexusGlyphs[tokenId];
        glyph.delegatedTo = delegatee;
        emit GlyphUtilityDelegated(ownerOfGlyph(tokenId), tokenId, delegatee);
    }

    /**
     * @dev Allows a Glyph owner to revoke a previously delegated utility.
     *      The Glyph's utility and power revert to the owner.
     * @param tokenId The ID of the glyph to reclaim.
     */
    function reclaimGlyphUtility(uint256 tokenId) external onlyGlyphOwnerOrApproved(tokenId) whenNotPaused {
        NexusGlyph storage glyph = nexusGlyphs[tokenId];
        require(glyph.delegatedTo != address(0), "ENP: Glyph not delegated");

        address originalOwner = ownerOfGlyph(tokenId);
        address oldDelegatee = glyph.delegatedTo;
        glyph.delegatedTo = address(0);
        emit GlyphUtilityReclaimed(originalOwner, tokenId);
    }

    /**
     * @dev Returns the URI for the Nexus Glyph's metadata.
     * @param tokenId The ID of the glyph.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_existsGlyph(tokenId), "ENP: Glyph does not exist");
        return _tokenURIs[tokenId];
    }

    // --- III. Adaptive Governance & Prognostications ---

    /**
     * @dev Users stake tokens to signal their support or belief in a particular future direction or outcome for the protocol.
     *      These "prognostications" contribute to a weighted consensus score for proposals.
     * @param _prognosticationHash A unique hash representing the prognostication's content or idea.
     * @param _stakeAmount The amount of `VOTING_TOKEN` to stake behind this prognostication.
     */
    function submitPrognostication(string memory _prognosticationHash, uint256 _stakeAmount) external whenNotPaused {
        require(_stakeAmount >= coreParameters["MIN_STAKE_FOR_PROGN"], "ENP: Stake amount too low");
        require(prognostications[bytes32(abi.encodePacked(_prognosticationHash))].submitter == address(0), "ENP: Prognostication already submitted");

        require(votingToken.transferFrom(msg.sender, address(this), _stakeAmount), "ENP: Token transfer failed for prognostication stake");

        prognostications[bytes32(abi.encodePacked(_prognosticationHash))] = Prognostication({
            prognosticationHash: _prognosticationHash,
            submitter: msg.sender,
            stakeAmount: _stakeAmount,
            submissionBlock: block.number,
            claimed: false
        });

        _recordParticipationMetric(msg.sender, MetricType.PrognosticationStakes, _stakeAmount);
        emit PrognosticationSubmitted(msg.sender, _prognosticationHash, _stakeAmount, block.number);
    }

    /**
     * @dev Allows the submitter of a prognostication to reclaim their stake
     *      after its active lifespan has passed.
     * @param _prognosticationHash The hash of the prognostication.
     */
    function reclaimPrognosticationStake(string memory _prognosticationHash) external whenNotPaused {
        bytes32 progKey = bytes32(abi.encodePacked(_prognosticationHash));
        Prognostication storage prog = prognostications[progKey];
        require(prog.submitter == msg.sender, "ENP: Not the submitter");
        require(!prog.claimed, "ENP: Stake already claimed");
        require(block.number > prog.submissionBlock + coreParameters["PROG_LIFESPAN_BLOCKS"], "ENP: Prognostication still active");

        prog.claimed = true;
        require(votingToken.transfer(msg.sender, prog.stakeAmount), "ENP: Failed to reclaim stake");
    }

    /**
     * @dev Initiates a formal governance proposal that requires voting.
     *      Requires a minimum `VOTING_TOKEN` stake to prevent spam.
     * @param _proposalHash A hash representing the proposal's content, actions, or off-chain link.
     * @param _durationBlocks The number of blocks the proposal will be open for voting.
     */
    function createProposal(bytes32 _proposalHash, uint256 _durationBlocks) external whenNotPaused {
        require(getVotingPower(msg.sender) >= coreParameters["PROPOSAL_THRESHOLD"], "ENP: Insufficient voting power to create proposal");
        require(_durationBlocks > 0, "ENP: Proposal duration must be greater than zero");

        _proposalCounter++;
        uint256 newId = _proposalCounter;

        proposals[newId] = Proposal({
            id: newId,
            proposalHash: _proposalHash,
            proposer: msg.sender,
            creationBlock: block.number,
            endBlock: block.number + _durationBlocks,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            executed: false,
            passed: false
        });

        // Store current voting power snapshot for the proposer
        proposals[newId].voterInfluence[msg.sender] = getVotingPower(msg.sender);

        emit ProposalCreated(newId, _proposalHash, msg.sender, block.number + _durationBlocks);
    }

    /**
     * @dev Allows users to cast their weighted votes on an active proposal.
     *      Voting power is calculated at the time of the vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ENP: Proposal does not exist");
        require(block.number <= proposal.endBlock, "ENP: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "ENP: Already voted on this proposal");

        address voter = msg.sender;
        address actualVoter = voterStates[msg.sender].delegatee != address(0) ? voterStates[msg.sender].delegatee : msg.sender;

        uint256 currentPower = getVotingPower(actualVoter);
        require(currentPower > 0, "ENP: No voting power");

        proposal.hasVoted[actualVoter] = true;
        proposal.voterInfluence[actualVoter] = currentPower; // Record power at vote time

        if (support) {
            proposal.totalForVotes += currentPower;
        } else {
            proposal.totalAgainstVotes += currentPower;
        }

        _recordParticipationMetric(actualVoter, MetricType.ProposalVotes, 1);
        emit VotedOnProposal(proposalId, actualVoter, support, currentPower);
    }

    /**
     * @dev Aggregates prognostication stakes and formal votes to determine a "consensus score" for a proposal.
     *      This is a read-only function, actual proposal finalization happens in `finalizeProposal`.
     * @param proposalId The ID of the proposal.
     * @return consensusScore A metric indicating the overall community sentiment.
     */
    function calculateConsensusScore(uint256 proposalId) public view returns (uint256) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ENP: Proposal does not exist");

        // Basic score calculation: (For Votes - Against Votes) + Weighted Prognostications
        int256 netVotes = int256(proposal.totalForVotes) - int256(proposal.totalAgainstVotes);
        int256 prognosticationImpact = 0;

        // Iterate through prognostications (simplified: might only consider active ones or those related to proposalHash)
        // For a more robust system, a direct link between proposalHash and prognosticationHash would be needed.
        // For this example, let's assume a direct match for simplicity in calculation.
        // In reality, this would likely involve a separate storage for proposal-linked prognostication IDs.
        
        // This part would be difficult to iterate over all prognostications on-chain
        // For a true implementation, one would need to explicitly link Prognostications to Proposals
        // or have an off-chain oracle sum up relevant prognostication stakes.
        // For demonstration purposes, we'll assume a simplified direct impact if hash matches.
        Prognostication storage prog = prognostications[proposal.proposalHash]; // simplified lookup
        if (prog.submitter != address(0) && block.number <= prog.submissionBlock + coreParameters["PROG_LIFESPAN_BLOCKS"]) {
            // Assume 10% of prognostication stake adds to consensus score as a simple example
            prognosticationImpact = int256(prog.stakeAmount / 10);
        }

        int256 rawScore = netVotes + prognosticationImpact;
        
        // Ensure score is non-negative for return type
        return rawScore > 0 ? uint256(rawScore) : 0;
    }

    /**
     * @dev Finalizes a proposal, checking if it has passed quorum and consensus.
     *      If passed, it can trigger associated actions (e.g., state transitions, parameter updates).
     *      Callable by anyone after the voting period ends.
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "ENP: Proposal does not exist");
        require(block.number > proposal.endBlock, "ENP: Voting period has not ended yet");
        require(!proposal.executed, "ENP: Proposal already executed");

        uint256 totalVotes = proposal.totalForVotes + proposal.totalAgainstVotes;
        // Simplified total supply for quorum - ideally would be total active voting power
        uint256 totalEffectiveVotingPower = (votingToken.totalSupply() / 1000) * getGlyphPowerFactor(1); // very rough estimate
        // In a real system, you would sum all current voting powers of all eligible voters.
        // Or, more practically, track a `totalVotingSupply` within the contract.
        // For now, let's use a placeholder if totalVotes is small, assume `totalEffectiveVotingPower` is high.

        // Quorum check (e.g., 20% of total voting power must participate)
        bool quorumReached = (totalVotes * 100) >= (totalEffectiveVotingPower * coreParameters["VOTE_QUORUM_PERCENT"]);
        if (!quorumReached && totalVotes < coreParameters["PROPOSAL_THRESHOLD"]) { // Fallback for low participation
             quorumReached = false; // Ensure strict quorum if low votes
        } else if (totalVotes >= coreParameters["PROPOSAL_THRESHOLD"]) { // if high participation, it implies quorum
             quorumReached = true;
        }


        // Pass condition (e.g., > 50% 'for' votes AND quorum reached AND positive consensus score)
        bool passed = false;
        if (quorumReached && proposal.totalForVotes > proposal.totalAgainstVotes) {
            uint256 consensusScore = calculateConsensusScore(proposalId);
            if (consensusScore > 0) { // A positive consensus score is required
                passed = true;
            }
        }

        proposal.passed = passed;
        proposal.executed = true; // Mark as executed regardless of pass/fail
        
        if (passed) {
            _recordParticipationMetric(proposal.proposer, MetricType.SuccessfulProposals, 1);
            // Example of proposal execution:
            // if (proposal.proposalHash == bytes32(abi.encodePacked("TRANSITION_TO_EXPANSION"))) {
            //     transitionEchelonState(EchelonState.Expansion);
            // } else if (proposal.proposalHash == bytes32(abi.encodePacked("UPDATE_MIN_STAKE"))) {
            //     // This would require a more complex proposal struct to pass parameters
            //     // For simplicity, direct owner call for updateCoreParameter is used
            // }
            // For general updates, a proposal would call `updateCoreParameter`
            // if the proposal body encodes `paramKey` and `newValue`.
            // Example: A proposal could be structured to call a specific function with arguments.
            // This would require proposal execution logic that decodes and calls arbitrary functions,
            // which is a full "governance executor" pattern (beyond current scope of simple demo).
            // For now, assume this triggers *internal* changes or external calls by the owner/multisig
            // based on the `proposalHash` and `passed` status.
            // A more advanced design would use `call` to execute arbitrary logic.
        }

        emit ProposalFinalized(proposalId, passed, true);
    }

    /**
     * @dev Calculates an address's current effective voting power.
     *      Includes staked tokens, Nexus Glyphs (via power factor), and reputation score.
     * @param voter The address for which to calculate voting power.
     * @return The total effective voting power.
     */
    function getVotingPower(address voter) public view returns (uint256) {
        address actualVoter = voterStates[voter].delegatee != address(0) ? voterStates[voter].delegatee : voter;
        uint256 power = voterStates[actualVoter].stakedTokens;

        // Add power from owned or delegated Nexus Glyphs
        // This would require iterating through all glyphs or keeping an index per user.
        // For simplicity, we'll assume a single glyph owner or delegate.
        // In a real system, you'd iterate `_totalGlyphsMinted` and check `_glyphOwners[i]` == `actualVoter`
        // or check `nexusGlyphs[i].delegatedTo` == `actualVoter`.
        // A more efficient way would be to maintain `_userGlyphBalances` or `_userDelegatedGlyphs` arrays.
        // For this demo, let's assume a simple lookup for a specific glyph if it was known.
        // As a placeholder, let's assume `actualVoter` owns `_totalGlyphsMinted` / 100 for example,
        // or iterate through known glyphs for simplicity in example.
        for (uint256 i = 1; i <= _totalGlyphsMinted; i++) {
            if (ownerOfGlyph(i) == actualVoter || nexusGlyphs[i].delegatedTo == actualVoter) {
                power += getGlyphCurrentUtility(i) * getGlyphPowerFactor(i);
            }
        }

        // Add power based on reputation
        power += reputationScores[actualVoter] / 100; // 1% of reputation score contributes to power

        return power;
    }

    /**
     * @dev Delegates general voting power to another address.
     *      All future votes by the delegator will be attributed to the delegatee.
     * @param delegatee The address to delegate voting power to.
     */
    function delegateVote(address delegatee) external whenNotPaused {
        require(delegatee != msg.sender, "ENP: Cannot delegate to self");
        require(delegatee != address(0), "ENP: Delegatee cannot be zero address");
        voterStates[msg.sender].delegatee = delegatee;
    }

    /**
     * @dev Revokes general voting power delegation.
     *      Voting power reverts to the caller.
     */
    function undelegateVote() external whenNotPaused {
        require(voterStates[msg.sender].delegatee != address(0), "ENP: No active delegation");
        voterStates[msg.sender].delegatee = address(0);
    }

    // --- IV. Resource Allocation & Dynamic Fees ---

    /**
     * @dev Allows depositing `VOTING_TOKEN` funds into the protocol's yield pool.
     *      These funds can then be distributed as yield.
     * @param amount The amount of tokens to deposit.
     */
    function depositYieldFunds(uint256 amount) external whenNotPaused {
        require(amount > 0, "ENP: Amount must be greater than zero");
        require(votingToken.transferFrom(msg.sender, address(this), amount), "ENP: Failed to deposit yield funds");
        protocolYieldFunds += amount;
    }

    /**
     * @dev Distributes accumulated protocol yield to eligible participants based on their contributions and Nexus Glyphs.
     *      This would typically be triggered periodically or by governance.
     *      (Simplified logic: In a real system, eligibility and share calculation would be complex).
     */
    function distributeProtocolYield() external onlyOwner whenNotPaused {
        require(protocolYieldFunds > 0, "ENP: No yield funds to distribute");

        uint256 totalYield = protocolYieldFunds;
        protocolYieldFunds = 0; // Reset pool

        // Example: Distribute based on reputation and glyph power
        // This requires iterating active participants/glyph holders, which is gas-intensive.
        // For a real system, you'd likely use a Merkle drop or snapshot-based distribution.
        // As a placeholder, let's just emit an event and assume an off-chain calculation
        // or a limited distribution to a fixed set of beneficiaries for demo.
        // Example: If 10% goes to Glyph holders, 5% to top proposers, etc.

        // Placeholder: Assuming a distribution mechanism where shares are calculated off-chain
        // and recipients claim. Or, if the contract could iterate through all relevant addresses.
        // For simplicity, we just reset the pool and emit.
        // A more advanced example would involve a loop through a predefined list or a dynamic list.
        // For instance, let's say a governance body decides to send a portion to a "StakingPool"
        // or direct to a specific address based on `protocolYieldFunds` and `EchelonState`.
        // Let's model a simplified "protocol treasury" transfer.
        
        // This could be:
        // votingToken.transfer(YIELD_RECIPIENT_ADDRESS, totalYield);
        // Or distributed to individual claimants. For now, just reset and emit.

        emit YieldDistributed(totalYield, block.timestamp);
    }

    /**
     * @dev Allows depositing `VOTING_TOKEN` funds into a dedicated grant pool.
     *      These funds are then allocated by governance.
     * @param amount The amount of tokens to deposit.
     */
    function depositGrantFunds(uint256 amount) external whenNotPaused {
        require(amount > 0, "ENP: Amount must be greater than zero");
        require(votingToken.transferFrom(msg.sender, address(this), amount), "ENP: Failed to deposit grant funds");
        grantPoolFunds += amount;
    }

    /**
     * @dev Distributes funds from a dedicated grant pool.
     *      This function would typically be called via a successful governance proposal.
     * @param recipient The address to receive the grant.
     * @param amount The amount of tokens to grant.
     * @param reasonHash A hash representing the reason or proposal for the grant.
     */
    function allocateGrant(address recipient, uint256 amount, string memory reasonHash) external onlyOwner whenNotPaused {
        require(recipient != address(0), "ENP: Recipient cannot be zero address");
        require(amount > 0, "ENP: Amount must be greater than zero");
        require(grantPoolFunds >= amount, "ENP: Insufficient funds in grant pool");

        grantPoolFunds -= amount;
        require(votingToken.transfer(recipient, amount), "ENP: Grant transfer failed");

        emit GrantAllocated(block.number, recipient, amount, reasonHash); // Using block.number as a pseudo-grantId
    }

    /**
     * @dev Allows eligible users to claim resources (e.g., tokens, specific access rights)
     *      previously allocated to them. This function assumes an off-chain system
     *      or another contract tracks specific allocations.
     *      (Simplified: currently acts as a placeholder or requires external context).
     * @param resourceId A unique ID for the allocated resource.
     */
    function claimAllocatedResources(bytes32 resourceId) external whenNotPaused {
        // This function would require complex logic to verify a user's entitlement
        // to a specific `resourceId` (e.g., a Merkle proof against an off-chain root,
        // or a mapping `allocatedResources[resourceId][msg.sender] = amount`).
        // For demonstration, it's a placeholder.
        
        // Example with placeholder logic:
        // if (myAllocationTracker[resourceId][msg.sender] > 0) {
        //     uint256 amountToClaim = myAllocationTracker[resourceId][msg.sender];
        //     myAllocationTracker[resourceId][msg.sender] = 0; // Mark as claimed
        //     require(votingToken.transfer(msg.sender, amountToClaim), "ENP: Claim failed");
        //     // emit ResourceClaimed(msg.sender, resourceId, amountToClaim);
        // } else {
        //     revert("ENP: No resources allocated or already claimed for this ID");
        // }
        revert("ENP: Claiming resources requires external allocation tracking (placeholder)");
    }

    /**
     * @dev Allows governance (via owner calls) to dynamically adjust various protocol fee parameters.
     *      Fees are specified in basis points (e.g., 100 = 1%).
     * @param feeKey A bytes32 key identifying the fee type (e.g., "MINT_FEE", "TRANSFER_FEE").
     * @param basisPoints The new fee rate in basis points (e.g., 100 for 1%).
     */
    function setDynamicFeeParameter(bytes32 feeKey, uint256 basisPoints) external onlyOwner whenNotPaused {
        require(basisPoints <= 10000, "ENP: Fee cannot exceed 100%");
        uint256 oldValue = dynamicFeeParameters[feeKey];
        dynamicFeeParameters[feeKey] = basisPoints;
        emit FeeParameterUpdated(feeKey, oldValue, basisPoints);
    }

    /**
     * @dev Returns the current effective fee rate for a specified operation.
     *      Could potentially vary by Echelon State in more complex scenarios.
     * @param feeType A bytes32 key identifying the fee type.
     * @return The fee rate in basis points.
     */
    function getEffectiveProtocolFee(bytes32 feeType) public view returns (uint256) {
        return dynamicFeeParameters[feeType];
    }

    // --- V. Reputation & On-Chain History ---

    /**
     * @dev Records specific actions or contributions of a participant, feeding into their reputation score.
     *      This is called internally by other functions.
     * @param participant The address of the participant.
     * @param metricType The type of participation metric.
     * @param value The value associated with the metric (e.g., amount staked, number of actions).
     */
    function _recordParticipationMetric(address participant, MetricType metricType, uint256 value) internal {
        uint256 currentScore = reputationScores[participant];
        uint256 scoreIncrease = 0;

        if (metricType == MetricType.ProposalVotes) {
            scoreIncrease = value * 5; // 5 points per vote
        } else if (metricType == MetricType.PrognosticationStakes) {
            scoreIncrease = value / 100; // 1 point per 100 staked tokens
        } else if (metricType == MetricType.GlyphUpgrades) {
            scoreIncrease = value * 50; // 50 points per glyph upgrade
        } else if (metricType == MetricType.SuccessfulProposals) {
            scoreIncrease = value * 200; // 200 points for a successful proposal
        }

        reputationScores[participant] = currentScore + scoreIncrease;
        emit ReputationRecorded(participant, metricType, value, reputationScores[participant]);
    }

    /**
     * @dev Calculates and returns a participant's dynamic reputation score.
     * @param participant The address of the participant.
     * @return The participant's current reputation score.
     */
    function getReputationScore(address participant) public view returns (uint256) {
        return reputationScores[participant];
    }
}
```