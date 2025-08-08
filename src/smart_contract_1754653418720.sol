Here's a Solidity smart contract named `AetherForgeDAO`, designed to be an advanced, creative, and trendy protocol for decentralized, AI-assisted digital asset creation and curation. It integrates concepts like vote-escrowed tokens, dynamic NFTs, on-chain governance, and oracle-based AI integration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For active proposals
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For Artifacts (NFTs)

// --- Outline ---
// 1. Core Structures (Enums, Structs)
// 2. Access Control & Roles
// 3. Events
// 4. Token Management (AetherToken - AET)
// 5. Vote-Escrowed Staking (veAET)
// 6. AI Model Registry & Configuration
// 7. Raw Forging (AI Output) Management
// 8. Refinement & Curation Process
// 9. Artifact (NFT) Minting & Dynamic Traits
// 10. DAO Governance System
// 11. Treasury & Revenue Distribution
// 12. External Oracle Integration (Simulated)
// 13. Fallback Functions

// --- Function Summary ---

// I. AetherToken (AET) & Governance
// - constructor(string memory name, string memory symbol): Initializes the contract, AetherToken (ERC20), and sets up initial roles.
// - initialMint(address _to, uint256 _amount): Mints an initial supply of AET tokens to a specified address. Callable once by the admin.
// - transfer(address to, uint256 amount): Standard ERC20 token transfer, with checks for staked tokens.
// - approve(address spender, uint256 amount): Standard ERC20 token approval for spending.
// - transferFrom(address from, address to, uint256 amount): Standard ERC20 token transfer from an approved spender.
// - stakeAET(uint256 amount, uint256 lockDurationWeeks): Allows users to lock their AET for a specified duration to gain veAET (voting power).
// - unstakeAET(): Enables users to withdraw their staked AET once the lockup period has expired.
// - extendLockup(uint256 newLockDurationWeeks): Permits users to extend the lockup period of their existing veAET stake, increasing its voting power.
// - getVeAETBalance(address account): Calculates and returns an account's current vote-escrowed AET (veAET) balance, based on staked amount and remaining lock time.
// - delegate(address delegatee): Allows an account to delegate its veAET voting power to another address.

// II. AI Model & Oracle Management
// - registerAIModel(bytes32 modelId, address oracleAddress, uint256 costPerRequest, string memory outputType): Registers a new AI model with its parameters. This function is callable only via a successful DAO governance proposal.
// - updateAIModelConfig(bytes32 modelId, address newOracleAddress, uint256 newCostPerRequest, string memory newOutputType): Updates the configuration (oracle, cost, output type) of an existing AI model. Callable only via a successful DAO proposal.
// - deactivateAIModel(bytes32 modelId): Deactivates an AI model, preventing new forging requests for it. Callable only via a successful DAO proposal.
// - setOracleAddress(address _oracleAddress): Sets the primary trusted oracle address responsible for fulfilling AI generation requests. Initially set by admin, then changeable via DAO proposal.

// III. Forging & Refinement Lifecycle
// - requestForging(bytes32 modelId, string memory prompt, uint256 _nonce): Initiates an AI-assisted asset generation request by sending a prompt to a chosen AI model and paying a fee in AET.
// - fulfillForgingRequest(bytes32 forgingId, bytes32 modelId, uint256 oracleRequestId, string memory aiOutputURI): Callable only by the designated oracle, this function delivers the AI's output (e.g., an IPFS URI) for a specific request, marking it as a "Raw Forging."
// - proposeRefinement(bytes32 forgingId, string memory refinementDetailsURI, uint256 stakeAmount): Allows community members to stake AET and propose enhancements, categorization, or improvements for a Raw Forging.
// - voteOnRefinement(bytes32 forgingId, uint256 refinementIndex, bool support): Enables veAET holders to vote on specific refinement proposals associated with a Raw Forging.
// - finalizeRefinementPhase(bytes32 forgingId): Concludes the refinement voting phase for a Raw Forging, calculates its final "Refinement Score," and prepares rewards for successful proposers/voters.

// IV. Artifact (NFT) Management
// - setArtifactNFTContract(address _artifactNFT): Sets the address of the external ERC721 contract that will manage the minted "Artifact" NFTs. Callable only via a successful DAO proposal.
// - mintArtifact(bytes32 forgingId, string memory initialTokenURI): Mints a new Artifact NFT from a Raw Forging, provided it has reached a sufficient Refinement Score and the minting fee is paid.
// - updateArtifactDynamicMetadata(uint256 tokenId, bytes32 forgingId, string memory newMetadataURI): Allows the DAO to update an Artifact NFT's metadata dynamically (e.g., based on ongoing community interaction or AI evolution). Callable only via a successful DAO proposal.

// V. DAO Governance
// - createProposal(address targetContract, bytes memory callData, string memory description): Allows veAET holders to initiate new governance proposals for various on-chain actions (e.g., changing parameters, contract upgrades).
// - vote(uint256 proposalId, bool support): Casts a vote (yes/no) on an active governance proposal using the voter's veAET power.
// - executeProposal(uint256 proposalId): Executes a governance proposal that has successfully passed its voting period, met quorum, and achieved a majority.
// - cancelProposal(uint256 proposalId): Allows the proposer or an admin to cancel an active proposal before its voting period ends.

// VI. Treasury & Revenue Distribution
// - claimForgingRewards(bytes32 forgingId): Allows eligible participants (e.g., successful refiners) to claim AET rewards accumulated during the refinement process of a forging.
// - claimArtifactRevenue(address account): Placeholder for a more complex mechanism allowing eligible AET stakers to claim their share of protocol revenue generated from Artifact NFT sales.
// - withdrawFromTreasury(address recipient, uint256 amount): Allows the DAO (via a successful proposal) to withdraw AET from the contract's treasury to a specified recipient.

// VII. Administrative/Utility
// - getForgingDetails(bytes32 forgingId): Public view function to retrieve the full details of a specific Raw Forging.
// - getCurrentTimestamp(): Helper function to retrieve the current block timestamp, useful for testing and debugging time-based logic.

// Fallback Functions: `receive()` and `fallback()` allow the contract to receive ETH and handle calls to undefined functions.


contract AetherForgeDAO is ERC20, AccessControl {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Access Control Roles ---
    // DEFAULT_ADMIN_ROLE: The initial deployer, can grant other roles and perform initial setup.
    // ADMIN_ROLE: A role intended to be controlled by the DAO itself for managing core parameters.
    // ORACLE_ROLE: Granted to the trusted off-chain AI oracle for fulfilling requests.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // --- Configuration Constants ---
    uint256 public constant MIN_LOCK_DURATION_WEEKS = 4;   // Minimum AET staking lockup (4 weeks)
    uint256 public constant MAX_LOCK_DURATION_WEEKS = 208; // Maximum AET staking lockup (4 years = 208 weeks)
    uint256 public constant LOCK_DURATION_FACTOR = 100;    // Multiplier for veAET calculation (e.g., 4x boost for max lock)
                                                           // veAET = AET_amount * (remaining_lock_weeks / MIN_LOCK_DURATION_WEEKS) * (LOCK_DURATION_FACTOR / 100)
    uint256 public constant ARTIFACT_MINT_FEE = 100 * (10 ** 18); // Example: 100 AET fee to mint an artifact
    uint256 public constant ARTIFACT_MINT_REWARD_PERCENTAGE = 30; // 30% of artifact mint fee goes to refiners/proposers
    uint256 public constant MIN_REFINEMENT_SCORE_FOR_MINT = 700; // Min score (out of 1000) for a forging to be mintable as NFT
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;     // Voting duration for DAO governance proposals
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 1 days;   // Delay before a successful proposal can be executed
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 4;      // 4% of total AET supply (simplified for veAET) needed for quorum

    address public trustedOracle; // Address of the primary oracle responsible for fulfilling AI requests
    IERC721 public artifactNFT;   // Address of the external Artifact NFT (ERC721) contract

    // --- Core Structures ---

    // Enum for the state of a Raw Forging throughout its lifecycle
    enum ForgingState {
        REQUESTED,          // Request made, awaiting oracle fulfillment
        FORGED,             // AI output received, ready for refinement proposals
        REFINEMENT_PHASE,   // Refinement proposals open for voting
        REFINED,            // Refinement phase finalized, score calculated
        MINTED              // Forging has been used to mint an Artifact NFT
    }

    // Structure for AI Model Configuration
    struct AIModel {
        address oracleAddress;  // Specific oracle address for this model (can be different from main trustedOracle)
        uint256 costPerRequest; // Cost in AET per request using this model
        string outputType;      // e.g., "image_prompt", "text_story", "3d_model_seed"
        bool isActive;          // Whether the model is currently active for requests
    }

    // Structure for a Raw Forging (the raw output from an AI model)
    struct RawForging {
        bytes32 forgingId;      // Unique ID for the forging request (keccak256 hash of request params)
        address requester;      // Address that initiated the forging request
        bytes32 modelId;        // ID of the AI model used
        string prompt;          // Original prompt sent to the AI
        uint256 requestTimestamp; // Timestamp of the request initiation
        uint256 fulfillmentTimestamp; // Timestamp when AI output was received from oracle
        string aiOutputURI;     // IPFS hash or URI pointing to the AI's raw output
        ForgingState state;     // Current state of the forging
        uint256 refinementScore; // Accumulated score from refinement votes (out of 1000), indicates quality
        uint256 artifactTokenId; // Token ID of the minted NFT, if any (0 if not minted yet)
        uint256 totalRefinementStake; // Total AET staked across all refinement proposals for this forging
        uint256 claimableRewards; // Rewards available for refiners/proposers after finalization

        uint256 refinementPhaseEndTime; // Timestamp when refinement voting ends for this forging
        EnumerableSet.UintSet activeRefinementProposals; // Set of indices of active refinement proposals for this forging
    }

    // Structure for a Refinement Proposal on a Raw Forging
    struct RefinementProposal {
        address proposer;       // Address that proposed this refinement
        string detailsURI;      // IPFS hash or URI to refinement details (e.g., improved prompt, new category, tags)
        uint256 stakeAmount;    // AET staked by the proposer for this refinement
        uint256 creationTime;   // Timestamp of proposal creation
        uint256 yesVotes;       // Total veAET votes in favor of this refinement
        uint256 noVotes;        // Total veAET votes against this refinement
        bool finalized;         // True if this refinement proposal's voting has concluded
        bool approved;          // True if the refinement was approved by majority vote
    }

    // Structure for Vote-Escrowed AET (veAET) stake
    struct VeAETStake {
        uint256 amount;          // AET amount staked
        uint256 lockEndTime;     // Timestamp when the staked AET can be withdrawn
    }

    // Enum for the state of a DAO Governance Proposal
    enum ProposalState {
        ACTIVE,      // Voting is open
        SUCCEEDED,   // Voting ended, quorum and majority met
        FAILED,      // Voting ended, quorum or majority not met
        EXECUTED,    // Proposal successfully executed
        CANCELED     // Proposal canceled by proposer or DAO
    }

    // Structure for a DAO Governance Proposal
    struct Proposal {
        uint256 id;                 // Unique proposal ID
        address proposer;           // Address that created the proposal
        address targetContract;     // Target contract for the proposed on-chain action
        bytes callData;             // Calldata for the function call on the target contract
        string description;         // Human-readable description of the proposal
        uint256 creationTime;       // Timestamp of proposal creation
        uint256 voteStartTime;      // Timestamp when voting starts (same as creationTime for simplicity)
        uint256 voteEndTime;        // Timestamp when voting ends
        uint256 executionTime;      // Timestamp when execution is possible after success
        uint256 yesVotes;           // Total veAET votes in favor
        uint256 noVotes;            // Total veAET votes against
        uint256 quorumRequired;     // Minimum veAET votes required for the proposal to be valid
        ProposalState state;        // Current state of the proposal
        bool executed;              // True if the proposal has been executed
    }

    // --- Mappings & Storage ---
    mapping(bytes32 => AIModel) public aiModels; // modelId => AIModel configuration
    mapping(bytes32 => RawForging) public rawForgings; // forgingId => RawForging details
    mapping(bytes32 => RefinementProposal[]) public refinementProposals; // forgingId => list of RefinementProposals
    mapping(address => VeAETStake) public veAETStakes; // staker address => VeAETStake details

    // Governance related storage
    uint256 public nextProposalId; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal details
    EnumerableSet.UintSet private _activeProposals; // Set of currently active proposal IDs for easy iteration
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter address => true if voted

    // Delegation for veAET voting power
    mapping(address => address) public delegates; // delegator address => delegatee address
    mapping(address => uint256) public delegatedVotes; // delegatee address => total votes delegated to them

    uint256 public treasuryBalance; // Total AET held by the contract, representing the DAO treasury

    // --- Events ---
    event InitialSupplyMinted(address indexed to, uint256 amount);
    event AETStaked(address indexed user, uint256 amount, uint256 lockEndTime, uint256 veAETAmount);
    event AETUnstaked(address indexed user, uint256 amount);
    event LockupExtended(address indexed user, uint256 newLockEndTime, uint256 newVeAETAmount);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event VotesChanged(address indexed delegator, uint256 previousVotes, uint256 newVotes);

    event AIModelRegistered(bytes32 indexed modelId, address indexed oracleAddress, uint256 costPerRequest, string outputType);
    event AIModelUpdated(bytes32 indexed modelId, address indexed newOracleAddress, uint256 newCostPerRequest);
    event AIModelDeactivated(bytes32 indexed modelId);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);

    event ForgingRequested(bytes32 indexed forgingId, address indexed requester, bytes32 modelId, string prompt, uint256 requestTimestamp);
    event ForgingFulfilled(bytes32 indexed forgingId, bytes32 indexed modelId, string aiOutputURI, uint256 fulfillmentTimestamp);
    event RefinementProposed(bytes32 indexed forgingId, uint256 indexed refinementIndex, address indexed proposer, uint256 stakeAmount);
    event RefinementVoted(bytes32 indexed forgingId, uint256 indexed refinementIndex, address indexed voter, bool support, uint256 votePower);
    event RefinementPhaseFinalized(bytes32 indexed forgingId, uint256 finalRefinementScore, uint256 totalRefinementStake);

    event ArtifactNFTContractSet(address indexed _artifactNFT);
    event ArtifactMinted(bytes32 indexed forgingId, uint256 indexed tokenId, address indexed minter, string tokenURI);
    event ArtifactMetadataUpdated(uint256 indexed tokenId, bytes32 indexed forgingId, string newMetadataURI);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address targetContract, bytes callData, uint256 voteEndTime);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    event ForgingRewardsClaimed(bytes32 indexed forgingId, address indexed claimant, uint256 amount);
    event ArtifactRevenueClaimed(address indexed account, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Grant DEFAULT_ADMIN_ROLE to the deployer. This role can then manage other roles.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant ADMIN_ROLE to the deployer. This role is used for functions that will eventually be DAO-governed.
        _grantRole(ADMIN_ROLE, msg.sender);
        nextProposalId = 1;
    }

    // --- Fallback Functions ---
    // Allows the contract to receive native currency (ETH) if sent.
    receive() external payable {
        // Potentially handle ETH contributions to treasury, or revert if not intended.
        // For this DAO, we focus on AET as the primary internal currency.
    }

    // Fallback for calls to non-existent functions.
    fallback() external payable {
    }

    // --- I. AetherToken (AET) & Governance ---

    /**
     * @notice Mints the initial supply of AET tokens to a specified address.
     *         Callable only once by an account with the `ADMIN_ROLE`.
     * @param _to The address to receive the initial AET supply.
     * @param _amount The amount of AET to mint (in smallest units, e.g., wei).
     */
    function initialMint(address _to, uint256 _amount) external onlyRole(ADMIN_ROLE) {
        require(totalSupply() == 0, "AetherForgeDAO: Initial supply already minted.");
        _mint(_to, _amount);
        treasuryBalance = treasuryBalance.add(_amount); // Consider initial mint as part of the DAO treasury
        emit InitialSupplyMinted(_to, _amount);
    }

    /**
     * @dev Overrides ERC20's `_beforeTokenTransfer` to prevent transfer of staked AET.
     *      This is a simplification; a full ve-token system might have more complex snapshotting.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        super._beforeTokenTransfer(from, to, amount);
        // Prevent transfer if AET is staked, unless it's a transfer to/from the contract itself for staking/unstaking.
        require(veAETStakes[from].amount == 0 || from == address(this), "AetherForgeDAO: Staked AET cannot be transferred. Unstake first.");
    }

    /**
     * @notice Locks AET for veAET, granting governance power based on the amount and lock duration.
     *         A user can only have one active stake at a time.
     * @param amount The amount of AET to stake.
     * @param lockDurationWeeks The duration in weeks to lock the AET (must be between MIN_LOCK_DURATION_WEEKS and MAX_LOCK_DURATION_WEEKS).
     */
    function stakeAET(uint256 amount, uint256 lockDurationWeeks) external {
        require(amount > 0, "AetherForgeDAO: Amount must be greater than 0.");
        require(lockDurationWeeks >= MIN_LOCK_DURATION_WEEKS && lockDurationWeeks <= MAX_LOCK_DURATION_WEEKS, "AetherForgeDAO: Invalid lock duration.");
        require(veAETStakes[msg.sender].amount == 0, "AetherForgeDAO: Already has an active stake. Unstake or extend existing stake.");

        _transfer(msg.sender, address(this), amount); // Transfer AET from user to contract (treasury)
        treasuryBalance = treasuryBalance.add(amount);

        uint256 lockEndTime = block.timestamp.add(lockDurationWeeks.mul(1 weeks));

        veAETStakes[msg.sender] = VeAETStake({
            amount: amount,
            lockEndTime: lockEndTime
        });

        _updateVotePower(msg.sender, getVeAETBalance(msg.sender)); // Update vote power for msg.sender or their delegate

        emit AETStaked(msg.sender, amount, lockEndTime, getVeAETBalance(msg.sender));
    }

    /**
     * @notice Unlocks and returns staked AET to the user after its lockup period expires.
     */
    function unstakeAET() external {
        VeAETStake storage stake = veAETStakes[msg.sender];
        require(stake.amount > 0, "AetherForgeDAO: No active stake found.");
        require(block.timestamp >= stake.lockEndTime, "AetherForgeDAO: Stake is still locked.");

        uint256 amount = stake.amount;
        // Reset stake data
        stake.amount = 0;
        stake.lockEndTime = 0;

        _updateVotePower(msg.sender, 0); // Remove vote power

        treasuryBalance = treasuryBalance.sub(amount); // Subtract from treasury
        _transfer(address(this), msg.sender, amount); // Transfer AET back to user

        emit AETUnstaked(msg.sender, amount);
    }

    /**
     * @notice Extends the lockup period for an existing veAET stake.
     *         The new lock duration must be longer than the currently remaining lock.
     * @param newLockDurationWeeks The new total duration in weeks from `block.timestamp`.
     */
    function extendLockup(uint256 newLockDurationWeeks) external {
        VeAETStake storage stake = veAETStakes[msg.sender];
        require(stake.amount > 0, "AetherForgeDAO: No active stake found.");
        require(newLockDurationWeeks >= MIN_LOCK_DURATION_WEEKS && newLockDurationWeeks <= MAX_LOCK_DURATION_WEEKS, "AetherForgeDAO: Invalid new lock duration.");
        require(block.timestamp.add(newLockDurationWeeks.mul(1 weeks)) > stake.lockEndTime, "AetherForgeDAO: New lock duration must be longer than current remaining lock.");

        stake.lockEndTime = block.timestamp.add(newLockDurationWeeks.mul(1 weeks));

        _updateVotePower(msg.sender, getVeAETBalance(msg.sender)); // Recalculate and update vote power

        emit LockupExtended(msg.sender, stake.lockEndTime, getVeAETBalance(msg.sender));
    }

    /**
     * @notice Calculates and returns an account's current veAET voting power.
     *         VeAET power scales with both the staked amount and the remaining lock duration.
     * @param account The address for which to calculate veAET.
     * @return The calculated veAET balance.
     */
    function getVeAETBalance(address account) public view returns (uint256) {
        VeAETStake storage stake = veAETStakes[account];
        if (stake.amount == 0 || block.timestamp >= stake.lockEndTime) {
            return 0; // No stake or lockup expired
        }

        uint256 remainingLockWeeks = (stake.lockEndTime.sub(block.timestamp)).div(1 weeks);
        // Calculation: (amount * remaining_lock_weeks / min_lock_weeks) * (LOCK_DURATION_FACTOR / 100)
        return stake.amount.mul(remainingLockWeeks).div(MIN_LOCK_DURATION_WEEKS).mul(LOCK_DURATION_FACTOR).div(100);
    }

    /**
     * @notice Delegates an account's veAET voting power to another address.
     *         The delegatee will cast votes on behalf of the delegator.
     * @param delegatee The address to delegate voting power to. Set to address(0) to self-delegate.
     */
    function delegate(address delegatee) external {
        address currentDelegate = delegates[msg.sender];
        require(currentDelegate != delegatee, "AetherForgeDAO: Cannot delegate to current delegatee.");
        require(delegatee != msg.sender, "AetherForgeDAO: Cannot delegate to self.");

        delegates[msg.sender] = delegatee;

        // Recalculate and update votes for old and new delegatees (or self if self-delegating)
        uint256 delegatorVotePower = getVeAETBalance(msg.sender);
        if (currentDelegate != address(0)) {
            // Remove votes from old delegate
            uint256 oldDelegatedVotes = delegatedVotes[currentDelegate];
            delegatedVotes[currentDelegate] = delegatedVotes[currentDelegate].sub(delegatorVotePower);
            emit VotesChanged(currentDelegate, oldDelegatedVotes, delegatedVotes[currentDelegate]);
        }
        if (delegatee != address(0)) {
            // Add votes to new delegate
            uint256 oldDelegatedVotes = delegatedVotes[delegatee];
            delegatedVotes[delegatee] = delegatedVotes[delegatee].add(delegatorVotePower);
            emit VotesChanged(delegatee, oldDelegatedVotes, delegatedVotes[delegatee]);
        }
        emit DelegateChanged(msg.sender, currentDelegate, delegatee);
    }

    /**
     * @notice Returns the total current voting power of an account, including any delegated votes.
     * @param account The address to query.
     * @return The total voting power.
     */
    function getVotes(address account) public view returns (uint256) {
        // If account has delegated their votes, their direct veAET balance doesn't contribute to `delegatedVotes[account]`.
        // Instead, the `delegatedVotes[account]` mapping stores the sum of votes *delegated to* this account.
        // So, `getVotes` should return either the veAETBalance if not delegated, OR the sum of votes delegated *to* this account.
        // This simple `delegatedVotes[account]` lookup assumes `delegates[account]` is empty if `account` wants to vote themselves.
        return delegatedVotes[account]; // This mapping tracks aggregated voting power.
    }

    /**
     * @dev Internal helper to update the actual voting power after stake changes or delegation.
     * @param account The user whose stake changed.
     * @param newPower The new veAET power for the account.
     */
    function _updateVotePower(address account, uint256 newPower) internal {
        address currentDelegatee = delegates[account];
        address actualVoteRecipient = (currentDelegatee == address(0)) ? account : currentDelegatee;

        uint256 oldPower = delegatedVotes[actualVoteRecipient]; // This might not be precise if called during a chain of delegation changes.
                                                              // For robustness, calculate old power more carefully, or use a simpler model.

        delegatedVotes[actualVoteRecipient] = newPower; // Direct assignment in this simplified model.
        emit VotesChanged(actualVoteRecipient, oldPower, newPower);
    }

    // --- II. AI Model & Oracle Management ---

    /**
     * @notice Registers a new AI model configuration. This function is typically executed via a DAO proposal.
     * @param modelId Unique identifier for the AI model.
     * @param oracleAddress The address of the specific oracle that serves this model.
     * @param costPerRequest Cost in AET for each request to this model.
     * @param outputType String describing the type of output (e.g., "image_prompt", "text").
     */
    function registerAIModel(
        bytes32 modelId,
        address oracleAddress,
        uint256 costPerRequest,
        string memory outputType
    ) external onlyRole(ADMIN_ROLE) { // Only callable by ADMIN_ROLE (controlled by DAO)
        require(aiModels[modelId].oracleAddress == address(0), "AetherForgeDAO: AI model already registered.");
        aiModels[modelId] = AIModel({
            oracleAddress: oracleAddress,
            costPerRequest: costPerRequest,
            outputType: outputType,
            isActive: true
        });
        emit AIModelRegistered(modelId, oracleAddress, costPerRequest, outputType);
    }

    /**
     * @notice Updates an existing AI model's parameters. Executed via a DAO proposal.
     * @param modelId Unique identifier for the AI model.
     * @param newOracleAddress The new oracle address for this model.
     * @param newCostPerRequest The new cost in AET for each request.
     * @param newOutputType The new output type string.
     */
    function updateAIModelConfig(
        bytes32 modelId,
        address newOracleAddress,
        uint256 newCostPerRequest,
        string memory newOutputType
    ) external onlyRole(ADMIN_ROLE) { // Only callable by ADMIN_ROLE (controlled by DAO)
        require(aiModels[modelId].oracleAddress != address(0), "AetherForgeDAO: AI model not registered.");
        aiModels[modelId].oracleAddress = newOracleAddress;
        aiModels[modelId].costPerRequest = newCostPerRequest;
        aiModels[modelId].outputType = newOutputType;
        emit AIModelUpdated(modelId, newOracleAddress, newCostPerRequest);
    }

    /**
     * @notice Deactivates an AI model, preventing new forging requests for it. Executed via a DAO proposal.
     * @param modelId Unique identifier for the AI model.
     */
    function deactivateAIModel(bytes32 modelId) external onlyRole(ADMIN_ROLE) { // Only callable by ADMIN_ROLE (controlled by DAO)
        require(aiModels[modelId].oracleAddress != address(0), "AetherForgeDAO: AI model not registered.");
        aiModels[modelId].isActive = false;
        emit AIModelDeactivated(modelId);
    }

    /**
     * @notice Sets the primary trusted oracle address for fulfilling AI requests.
     *         Initially set by ADMIN_ROLE, then changeable via DAO proposals.
     * @param _oracleAddress The address of the trusted oracle.
     */
    function setOracleAddress(address _oracleAddress) external onlyRole(ADMIN_ROLE) {
        require(_oracleAddress != address(0), "AetherForgeDAO: Oracle address cannot be zero.");
        emit OracleAddressSet(trustedOracle, _oracleAddress);
        trustedOracle = _oracleAddress;
    }

    // --- III. Forging & Refinement Lifecycle ---

    /**
     * @notice Initiates an AI generation request, paying AET for the model usage.
     *         This triggers an off-chain oracle call (simulated by emitting an event).
     * @param modelId The ID of the AI model to use.
     * @param prompt The original prompt string for the AI.
     * @param _nonce A unique nonce to ensure unique `forgingId` even with identical prompts.
     * @return The unique ID for the newly created forging request.
     */
    function requestForging(bytes32 modelId, string memory prompt, uint256 _nonce) external returns (bytes32) {
        AIModel storage model = aiModels[modelId];
        require(model.isActive, "AetherForgeDAO: AI model is not active.");
        require(model.costPerRequest > 0, "AetherForgeDAO: AI model has no cost defined.");

        bytes32 forgingId = keccak256(abi.encodePacked(msg.sender, modelId, prompt, _nonce, block.timestamp));
        require(rawForgings[forgingId].requester == address(0), "AetherForgeDAO: Forging ID already exists.");

        _transfer(msg.sender, address(this), model.costPerRequest); // User pays AET for the request
        treasuryBalance = treasuryBalance.add(model.costPerRequest); // Add cost to treasury

        rawForgings[forgingId] = RawForging({
            forgingId: forgingId,
            requester: msg.sender,
            modelId: modelId,
            prompt: prompt,
            requestTimestamp: block.timestamp,
            fulfillmentTimestamp: 0,
            aiOutputURI: "",
            state: ForgingState.REQUESTED,
            refinementScore: 0,
            artifactTokenId: 0,
            totalRefinementStake: 0,
            claimableRewards: 0,
            refinementPhaseEndTime: 0,
            activeRefinementProposals: EnumerableSet.UintSet(0) // Initialize empty set
        });

        emit ForgingRequested(forgingId, msg.sender, modelId, prompt, block.timestamp);
        return forgingId;
    }

    /**
     * @notice Delivers AI output for a specific request, registering it as a Raw Forging.
     *         Callable only by the designated `trustedOracle` (who has `ORACLE_ROLE`).
     * @param forgingId The unique ID of the forging request to fulfill.
     * @param modelId The ID of the AI model used (for validation).
     * @param oracleRequestId A request ID from the oracle system (for external cross-referencing).
     * @param aiOutputURI IPFS hash or URI pointing to the AI's actual output.
     */
    function fulfillForgingRequest(
        bytes32 forgingId,
        bytes32 modelId,
        uint256 oracleRequestId, // Included for potential external oracle system integration
        string memory aiOutputURI
    ) external onlyRole(ORACLE_ROLE) {
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.REQUESTED, "AetherForgeDAO: Forging not in requested state.");
        require(forging.modelId == modelId, "AetherForgeDAO: Model ID mismatch.");

        forging.aiOutputURI = aiOutputURI;
        forging.fulfillmentTimestamp = block.timestamp;
        forging.state = ForgingState.FORGED; // Ready for refinement proposals

        emit ForgingFulfilled(forgingId, modelId, aiOutputURI, block.timestamp);
    }

    /**
     * @notice Allows users to stake AET and propose enhancements or categorization for a Raw Forging.
     *         Starts the refinement phase if it's the first proposal for that forging.
     * @param forgingId The ID of the Raw Forging to refine.
     * @param refinementDetailsURI IPFS hash or URI to details of the proposed refinement.
     * @param stakeAmount The amount of AET to stake for this proposal (returned if approved).
     */
    function proposeRefinement(bytes32 forgingId, string memory refinementDetailsURI, uint256 stakeAmount) external {
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.FORGED || forging.state == ForgingState.REFINEMENT_PHASE, "AetherForgeDAO: Forging not in refinement-eligible state.");
        require(stakeAmount > 0, "AetherForgeDAO: Stake amount must be greater than 0.");

        _transfer(msg.sender, address(this), stakeAmount); // User stakes AET
        treasuryBalance = treasuryBalance.add(stakeAmount); // Staked AET temporarily held in treasury

        if (forging.state == ForgingState.FORGED) {
            forging.state = ForgingState.REFINEMENT_PHASE;
            forging.refinementPhaseEndTime = block.timestamp.add(PROPOSAL_VOTING_PERIOD); // Start refinement voting period
        } else {
            require(block.timestamp < forging.refinementPhaseEndTime, "AetherForgeDAO: Refinement phase has ended.");
        }

        uint256 refinementIndex = refinementProposals[forgingId].length;
        refinementProposals[forgingId].push(RefinementProposal({
            proposer: msg.sender,
            detailsURI: refinementDetailsURI,
            stakeAmount: stakeAmount,
            creationTime: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false
        }));

        forging.activeRefinementProposals.add(refinementIndex);
        forging.totalRefinementStake = forging.totalRefinementStake.add(stakeAmount);

        emit RefinementProposed(forgingId, refinementIndex, msg.sender, stakeAmount);
    }

    /**
     * @notice Allows veAET holders to vote on a specific refinement proposal associated with a Raw Forging.
     * @param forgingId The ID of the Raw Forging.
     * @param refinementIndex The index of the refinement proposal within that forging.
     * @param support True to vote 'yes' (support), false to vote 'no' (against).
     */
    function voteOnRefinement(bytes32 forgingId, uint256 refinementIndex, bool support) external {
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.REFINEMENT_PHASE, "AetherForgeDAO: Refinement voting not active.");
        require(block.timestamp < forging.refinementPhaseEndTime, "AetherForgeDAO: Refinement voting has ended for this forging.");
        require(refinementIndex < refinementProposals[forgingId].length, "AetherForgeDAO: Invalid refinement index.");

        RefinementProposal storage refinement = refinementProposals[forgingId][refinementIndex];
        require(!refinement.finalized, "AetherForgeDAO: Refinement proposal already finalized.");

        uint256 votePower = getVotes(msg.sender); // Use delegated voting power
        require(votePower > 0, "AetherForgeDAO: No voting power.");

        // For simplicity, this example does not prevent multiple votes from the same address on the same refinement.
        // In a production system, a mapping like `mapping(bytes32 => mapping(uint256 => mapping(address => bool))) public hasVotedOnRefinement;`
        // would be used to track individual votes.
        if (support) {
            refinement.yesVotes = refinement.yesVotes.add(votePower);
        } else {
            refinement.noVotes = refinement.noVotes.add(votePower);
        }

        emit RefinementVoted(forgingId, refinementIndex, msg.sender, support, votePower);
    }

    /**
     * @notice Concludes the voting phase for a Raw Forging's refinements, calculates its final "Refinement Score,"
     *         and prepares rewards for successful proposers/refiners.
     * @param forgingId The ID of the Raw Forging to finalize.
     */
    function finalizeRefinementPhase(bytes32 forgingId) external {
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.REFINEMENT_PHASE, "AetherForgeDAO: Forging not in refinement phase.");
        require(block.timestamp >= forging.refinementPhaseEndTime, "AetherForgeDAO: Refinement phase not yet ended.");

        uint256 totalYesVotesOverall = 0;
        uint256 totalNoVotesOverall = 0;
        uint256 approvedRefinementsCount = 0;
        uint256 totalApprovedProposerStake = 0;

        // Iterate through all refinement proposals for this forging to finalize them
        for (uint256 i = 0; i < refinementProposals[forgingId].length; i++) {
            RefinementProposal storage refinement = refinementProposals[forgingId][i];
            if (!refinement.finalized) {
                uint256 totalRefinementVotes = refinement.yesVotes.add(refinement.noVotes);
                if (totalRefinementVotes > 0 && refinement.yesVotes.mul(100) / totalRefinementVotes > 50) { // Simple majority
                    refinement.approved = true;
                    approvedRefinementsCount++;
                    totalApprovedProposerStake = totalApprovedProposerStake.add(refinement.stakeAmount);
                } else {
                    refinement.approved = false;
                    // Staked AET for rejected proposals remains in treasury or could be slashed/burned.
                }
                refinement.finalized = true;
            }
            if (refinement.approved) {
                totalYesVotesOverall = totalYesVotesOverall.add(refinement.yesVotes);
            } else {
                totalNoVotesOverall = totalNoVotesOverall.add(refinement.noVotes);
            }
        }

        // Calculate the overall refinement score for the Raw Forging
        if (totalYesVotesOverall.add(totalNoVotesOverall) > 0) {
            forging.refinementScore = totalYesVotesOverall.mul(1000).div(totalYesVotesOverall.add(totalNoVotesOverall));
        } else {
            forging.refinementScore = 0; // No votes, no score
        }

        // Prepare rewards for successful refiners/proposers
        // Simplified: A portion of the mint fee goes to a pool for approved proposers.
        uint256 rewardPoolForRefiners = forging.totalRefinementStake.mul(ARTIFACT_MINT_REWARD_PERCENTAGE).div(100);
        forging.claimableRewards = rewardPoolForRefiners; // Sum up for later claiming

        forging.state = ForgingState.REFINED;
        emit RefinementPhaseFinalized(forgingId, forging.refinementScore, forging.totalRefinementStake);
    }

    // --- IV. Artifact (NFT) Management ---

    /**
     * @notice Sets the address of the external ArtifactNFT (ERC721) contract that this DAO manages.
     *         Callable initially by `ADMIN_ROLE`, then changeable via DAO proposals.
     * @param _artifactNFT The address of the ArtifactNFT contract.
     */
    function setArtifactNFTContract(address _artifactNFT) external onlyRole(ADMIN_ROLE) {
        require(_artifactNFT != address(0), "AetherForgeDAO: NFT contract address cannot be zero.");
        artifactNFT = IERC721(_artifactNFT);
        emit ArtifactNFTContractSet(_artifactNFT);
    }

    /**
     * @notice Mints a new Artifact NFT from a highly refined Raw Forging, if it meets quality criteria.
     * @param forgingId The ID of the Raw Forging to mint an NFT from.
     * @param initialTokenURI The initial metadata URI for the minted NFT.
     */
    function mintArtifact(bytes32 forgingId, string memory initialTokenURI) external {
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.REFINED, "AetherForgeDAO: Forging not in refined state.");
        require(forging.artifactTokenId == 0, "AetherForgeDAO: Artifact already minted for this forging.");
        require(forging.refinementScore >= MIN_REFINEMENT_SCORE_FOR_MINT, "AetherForgeDAO: Refinement score too low for minting.");
        require(address(artifactNFT) != address(0), "AetherForgeDAO: Artifact NFT contract not set.");

        _transfer(msg.sender, address(this), ARTIFACT_MINT_FEE); // User pays mint fee
        treasuryBalance = treasuryBalance.add(ARTIFACT_MINT_FEE);

        // Call the external ArtifactNFT contract to mint the NFT.
        // In a real implementation, the ArtifactNFT contract would have a `mint` function like:
        // `function mint(address to, string memory tokenURI) external returns (uint256 tokenId);`
        // We'll simulate the token ID generation here, assuming `ArtifactNFT` handles its own ID management.
        uint256 newTokenId = uint256(keccak256(abi.encodePacked(forgingId, block.timestamp, initialTokenURI, msg.sender)));
        // artifactNFT.mint(msg.sender, newTokenId, initialTokenURI); // Actual call to NFT contract
        // To make this compile without a full IArtifactNFT implementation:
        // (bool success, ) = address(artifactNFT).call(abi.encodeWithSignature("mint(address,uint256,string)", msg.sender, newTokenId, initialTokenURI));
        // require(success, "AetherForgeDAO: NFT minting failed.");

        forging.artifactTokenId = newTokenId; // Record the minted token ID
        forging.state = ForgingState.MINTED;

        emit ArtifactMinted(forgingId, newTokenId, msg.sender, initialTokenURI);
    }

    /**
     * @notice Allows the DAO to update an Artifact NFT's metadata dynamically.
     *         This can be used to reflect changes based on ongoing data, community interaction, or AI evolution.
     *         Callable only via a successful DAO proposal.
     * @param tokenId The ID of the Artifact NFT.
     * @param forgingId The ID of the associated Raw Forging (for verification).
     * @param newMetadataURI The new IPFS hash or URI for the NFT's metadata.
     */
    function updateArtifactDynamicMetadata(uint256 tokenId, bytes32 forgingId, string memory newMetadataURI) external onlyRole(ADMIN_ROLE) { // Only callable by ADMIN_ROLE (controlled by DAO)
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.MINTED, "AetherForgeDAO: Forging not yet minted as artifact.");
        require(forging.artifactTokenId == tokenId, "AetherForgeDAO: Token ID mismatch for forging.");
        require(address(artifactNFT) != address(0), "AetherForgeDAO: Artifact NFT contract not set.");

        // In a real scenario, this would call a function on the ArtifactNFT contract:
        // e.g., artifactNFT.setTokenURI(tokenId, newMetadataURI);
        // (bool success, ) = address(artifactNFT).call(abi.encodeWithSignature("setTokenURI(uint256,string)", tokenId, newMetadataURI));
        // require(success, "AetherForgeDAO: NFT metadata update failed.");

        emit ArtifactMetadataUpdated(tokenId, forgingId, newMetadataURI);
    }

    // --- V. DAO Governance ---

    /**
     * @notice Initiates a new governance proposal for on-chain actions.
     *         Requires the proposer to have some veAET to prevent spam.
     * @param targetContract The address of the contract the proposal will interact with (can be `address(this)`).
     * @param callData The calldata for the function call on the target contract.
     * @param description A brief description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function createProposal(address targetContract, bytes memory callData, string memory description) external returns (uint256) {
        require(getVotes(msg.sender) > 0, "AetherForgeDAO: Proposer must have voting power."); // Minimum voting power to create proposal

        uint256 proposalId = nextProposalId++;
        uint256 proposalCreationTime = block.timestamp;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targetContract: targetContract,
            callData: callData,
            description: description,
            creationTime: proposalCreationTime,
            voteStartTime: proposalCreationTime,
            voteEndTime: proposalCreationTime.add(PROPOSAL_VOTING_PERIOD),
            executionTime: 0,
            yesVotes: 0,
            noVotes: 0,
            abstainVotes: 0, // Not explicitly used in voting logic for simplicity
            quorumRequired: (totalSupply().mul(PROPOSAL_QUORUM_PERCENTAGE)).div(100), // Simplified: quorum based on total supply
            state: ProposalState.ACTIVE,
            executed: false
        });

        _activeProposals.add(proposalId);
        emit ProposalCreated(proposalId, msg.sender, description, targetContract, callData, proposals[proposalId].voteEndTime);
        return proposalId;
    }

    /**
     * @notice Casts a vote on an active governance proposal using the caller's veAET power.
     *         Each address (or its delegate) can vote only once per proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True to vote 'yes', false to vote 'no'.
     */
    function vote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.ACTIVE, "AetherForgeDAO: Proposal not active for voting.");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "AetherForgeDAO: Voting not open.");
        require(!hasVotedOnProposal[proposalId][msg.sender], "AetherForgeDAO: Already voted on this proposal.");

        uint256 votePower = getVotes(msg.sender);
        require(votePower > 0, "AetherForgeDAO: No voting power.");

        if (support) {
            proposal.yesVotes = proposal.yesVotes.add(votePower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votePower);
        }
        hasVotedOnProposal[proposalId][msg.sender] = true;

        emit ProposalVoted(proposalId, msg.sender, support, votePower);
    }

    /**
     * @notice Executes a successful governance proposal after its voting period ends,
     *         quorum is met, and it passed with a majority. Includes an execution delay.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.ACTIVE, "AetherForgeDAO: Proposal not in active state (needs to be finalized).");
        require(block.timestamp >= proposal.voteEndTime, "AetherForgeDAO: Voting period not ended.");
        require(!proposal.executed, "AetherForgeDAO: Proposal already executed.");

        uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);

        // Check for quorum: total votes must meet the minimum required.
        require(totalVotes >= proposal.quorumRequired, "AetherForgeDAO: Quorum not met.");

        // Check for majority: 'yes' votes must strictly exceed 'no' votes.
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.SUCCEEDED;
        } else {
            proposal.state = ProposalState.FAILED; // Explicitly set to FAILED if majority not met.
            _activeProposals.remove(proposalId);
            revert("AetherForgeDAO: Proposal failed to pass majority.");
        }

        require(proposal.state == ProposalState.SUCCEEDED, "AetherForgeDAO: Proposal not succeeded.");

        // Enforce an execution delay to allow reaction time for users.
        require(block.timestamp >= proposal.voteEndTime.add(PROPOSAL_EXECUTION_DELAY), "AetherForgeDAO: Execution delay not met.");

        // Execute the proposed function call.
        (bool success, bytes memory returndata) = proposal.targetContract.call(proposal.callData);
        require(success, string(abi.encodePacked("AetherForgeDAO: Proposal execution failed: ", returndata)));

        proposal.executed = true;
        proposal.state = ProposalState.EXECUTED;
        _activeProposals.remove(proposalId); // Remove from active set

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Allows the proposer (or an account with `DEFAULT_ADMIN_ROLE`) to cancel a proposal
     *         before its voting period ends.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.ACTIVE, "AetherForgeDAO: Proposal not active.");
        require(msg.sender == proposal.proposer || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "AetherForgeDAO: Not authorized to cancel.");
        require(block.timestamp < proposal.voteEndTime, "AetherForgeDAO: Voting period already ended.");

        proposal.state = ProposalState.CANCELED;
        _activeProposals.remove(proposalId);

        emit ProposalCanceled(proposalId);
    }

    // --- VI. Treasury & Revenue Distribution ---

    /**
     * @notice Allows successful refiners and proposers to claim their AET rewards from the refinement process.
     *         This is a simplified model; a production system would track individual claimable amounts.
     * @param forgingId The ID of the Raw Forging for which rewards are being claimed.
     */
    function claimForgingRewards(bytes32 forgingId) external {
        RawForging storage forging = rawForgings[forgingId];
        require(forging.state == ForgingState.REFINED || forging.state == ForgingState.MINTED, "AetherForgeDAO: Forging not in reward-eligible state.");
        require(forging.claimableRewards > 0, "AetherForgeDAO: No claimable rewards for this forging.");

        uint256 rewardsToClaim = 0;
        // In this simplified example, we'll assume the original requester or a single major refiner claims.
        // A more robust system would require a `mapping(bytes32 => mapping(address => uint256))` to track specific claims.
        // For demonstration, let's allow the original requester of the forging to claim the prepared rewards.
        require(msg.sender == forging.requester, "AetherForgeDAO: Only the requester can claim general forging rewards (simplified).");
        rewardsToClaim = forging.claimableRewards;
        forging.claimableRewards = 0; // Reset after claim to prevent double claiming

        require(rewardsToClaim > 0, "AetherForgeDAO: No specific rewards for this claimant.");
        _transfer(address(this), msg.sender, rewardsToClaim); // Transfer AET from treasury
        treasuryBalance = treasuryBalance.sub(rewardsToClaim);

        emit ForgingRewardsClaimed(forgingId, msg.sender, rewardsToClaim);
    }

    /**
     * @notice Placeholder for allowing eligible AET stakers (based on their veAET contributions) to claim
     *         their share of protocol revenue from Artifact NFT sales.
     *         A complex dividend distribution system (e.g., Merkle tree, a share-based pool) would be needed for production.
     * @param account The account to claim revenue for.
     */
    function claimArtifactRevenue(address account) external {
        // This function requires sophisticated logic to track historical veAET balances
        // against total veAET supply over revenue accrual periods.
        // For now, it serves as a conceptual placeholder.
        uint256 claimable = 0; // This value would be calculated based on accumulated revenue and account's veAET contribution.

        require(claimable > 0, "AetherForgeDAO: No claimable artifact revenue for this account.");
        _transfer(address(this), account, claimable); // Transfer AET from treasury
        treasuryBalance = treasuryBalance.sub(claimable);

        emit ArtifactRevenueClaimed(account, claimable);
    }

    /**
     * @notice Allows the DAO to transfer AET from the contract's treasury to a specified recipient.
     *         This function is executed only via a successful DAO governance proposal.
     * @param recipient The address to send funds to.
     * @param amount The amount of AET to withdraw.
     */
    function withdrawFromTreasury(address recipient, uint256 amount) external onlyRole(ADMIN_ROLE) { // Only callable by ADMIN_ROLE (controlled by DAO)
        require(amount > 0, "AetherForgeDAO: Amount must be greater than 0.");
        require(treasuryBalance >= amount, "AetherForgeDAO: Insufficient treasury balance.");
        _transfer(address(this), recipient, amount);
        treasuryBalance = treasuryBalance.sub(amount);
        emit TreasuryWithdrawal(recipient, amount);
    }

    // --- VII. Administrative/Utility ---

    /**
     * @notice Retrieves the full details of a Raw Forging.
     * @param forgingId The ID of the Raw Forging.
     * @return Raw Forging details struct.
     */
    function getForgingDetails(bytes32 forgingId) external view returns (RawForging memory) {
        return rawForgings[forgingId];
    }

    /**
     * @notice Helper function to get the current block timestamp.
     *         Useful for testing and debugging time-based logic.
     * @return The current block timestamp.
     */
    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}

// Interface for a simplified ArtifactNFT contract.
// In a production environment, this would reference a full ERC721 implementation
// that handles token IDs, ownership, and metadata.
interface IArtifactNFT {
    // Example mint function signature. Actual implementation might vary.
    // This DAO contract would call this to mint new NFTs.
    function mint(address to, uint256 tokenId, string memory tokenURI) external;

    // Example function to update NFT metadata (for dynamic NFTs).
    // This DAO contract would call this to update existing NFT metadata.
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external;
}
```