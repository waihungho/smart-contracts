Here's a Solidity smart contract for a decentralized AI Model Investment and Curation Platform, embodying advanced concepts, unique functionalities, and a comprehensive set of functions.

The core idea is a **"SynapseAI DAO"** where the community collaborates to fund, develop, and curate Artificial Intelligence models. It integrates elements of decentralized governance, tokenized intellectual property, staged funding with verifiable milestones (simulating ZKP integration), and automated royalty distribution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For interacting with the AI Model NFT contract
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Define an interface for the external AIModelNFT contract
interface IAIModelNFT is IERC721 {
    // Custom mint function that allows an external contract to mint on behalf of a user
    // In a real scenario, this might have more complex access control or be called directly by the DAO
    function mint(address to, uint256 tokenId, string calldata uri) external returns (uint256);
    // Optional: burn function if model IP needs to be retired/liquidated
    function burn(uint256 tokenId) external;
    // Optional: set URI for dynamic metadata updates
    function setTokenUri(uint256 tokenId, string calldata uri) external;
}

// Custom Errors for specific failure conditions
error SynapseAIDao__InvalidProposalState(string message);
error SynapseAIDao__InsufficientFunds(string message);
error SynapseAIDao__VotingPeriodNotEnded();
error SynapseAIDao__VotingPeriodEnded();
error SynapseAIDao__AlreadyVoted();
error SynapseAIDao__ProposalNotApproved();
error SynapseAIDao__FundingRoundNotActive(string message);
error SynapseAIDao__FundingRoundEnded(string message);
error SynapseAIDao__MilestoneAlreadyCompleted();
error SynapseAIDao__MilestoneVerificationPending();
error SynapseAIDao__MilestoneNotVerified();
error SynapseAIDao__AIModelAlreadyRegistered();
error SynapseAIDao__AIModelNotFound();
error SynapseAIDao__InsufficientReputation();
error SynapseAIDao__InvalidAmount(string message);
error SynapseAIDao__NoRoyaltiesToClaim();
error SynapseAIDao__Unauthorized(string message);
error SynapseAIDao__CallFailed(string message);
error SynapseAIDao__ProposalAlreadyExecuted();
error SynapseAIDao__CannotVoteOnSelfProposal();
error SynapseAIDao__InsufficientVotingPower();
error SynapseAIDao__FundingRoundNotFailed();
error SynapseAIDao__MilestoneNotFound();


/**
 * @title SynapseAI DAO: Decentralized AI Model Investment & Curation Platform
 * @notice This contract facilitates decentralized investment, development, and curation of AI models.
 *         It enables a community to propose, fund, and govern the lifecycle of AI projects,
 *         from initial concept to royalty distribution.
 *
 * @dev This contract relies on an external ERC20 governance token and an external ERC721
 *      AI Model NFT contract. ZKP verification is simulated by checking for a `proofHash`
 *      and marking as verified by a `CURATOR_ROLE`. Actual ZKP circuit verification would
 *      happen off-chain or by a dedicated on-chain verifier contract.
 */
contract SynapseAIDao is Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== OUTLINE & FUNCTION SUMMARY ==========
     *
     * This contract implements a sophisticated DAO for AI model development with the following advanced concepts and functions:
     *
     * I.   Contract Imports & Interfaces: Standard OpenZeppelin contracts (`ERC20`, `ERC721`, `Ownable`, `AccessControl`, `Pausable`, `ReentrancyGuard`) for security and modularity. An interface `IAIModelNFT` defines interaction with an external ERC721 contract representing AI model IP.
     * II.  Error Handling: Custom errors provide precise and informative feedback to users.
     * III. Enums & Structs: Defines the core data structures for managing proposals, funding rounds, development milestones, and AI models.
     * IV.  State Variables: Stores the current state of the DAO, including parameters, proposal details, funding progress, and AI model records.
     * V.   Constructor & Initialization: Sets up the contract's initial admin, governance token, and AI Model NFT contract addresses, along with critical DAO parameters.
     * VI.  Access Control & Roles: Utilizes OpenZeppelin's `AccessControl` for granular permissions:
     *      - `DEFAULT_ADMIN_ROLE`: Initial owner with power over critical setup and emergency functions.
     *      - `GOVERNANCE_ROLE`: Held by the DAO's governance token holders (or a multisig elected by them), capable of proposing and executing protocol changes, updating developer reputations, and slashing funds.
     *      - `CURATOR_ROLE`: Granted by `GOVERNANCE_ROLE`, responsible for verifying AI model development milestones.
     *
     * VII. Core DAO Governance (7 Functions):
     *      1. `initialize()`: (Callable once by owner) Sets up initial DAO parameters (e.g., min stake, voting periods).
     *      2. `submitProposal()`: Allows members to propose new AI model development projects, requiring a stake.
     *      3. `voteOnProposal()`: Enables token holders to vote on project proposals, using their token balance as voting power.
     *      4. `executeProposal()`: Finalizes a successful project proposal vote and initiates its staged funding round.
     *      5. `proposeProtocolParameterChange()`: Initiates a governance vote to alter core DAO configuration parameters (e.g., voting periods, fees).
     *      6. `voteOnProtocolParameterChange()`: Votes on a proposed protocol parameter change.
     *      7. `executeProtocolParameterChange()`: Applies approved protocol parameter changes after a successful governance vote.
     *
     * VIII. Funding & Investment (3 Functions):
     *      8. `depositFunds()`: Allows users to deposit governance tokens into the DAO's treasury, making them available for investment.
     *      9. `contributeToFundingRound()`: Enables investors to commit their deposited funds to an active AI model development funding round.
     *      10. `withdrawUnusedFundingContribution()`: Allows investors to reclaim their contributed funds if a funding round fails (e.g., doesn't meet its goal).
     *
     * IX.  AI Model Lifecycle Management (7 Functions):
     *      11. `addMilestoneToFundingRound()`: Developers define progressive development milestones for their funded project, each tied to a percentage of the total funding.
     *      12. `submitMilestoneVerification()`: Developers submit an off-chain proof (e.g., a hash representing a ZKP or oracle report of model performance/progress) for a completed milestone.
     *      13. `markMilestoneAsVerifiedByCurator()`: Designated `CURATOR_ROLE` addresses verify the submitted milestone proofs, acting as quality assurance.
     *      14. `claimMilestoneFunds()`: Developers claim the allocated funds for a milestone once it has been successfully verified.
     *      15. `registerAIModelNFT()`: Upon full development and verification, the AI model's intellectual property is minted as a unique ERC721 NFT, representing ownership and royalty rights.
     *      16. `distributeRoyalties()`: External entities (e.g., an AI marketplace or usage contract) send revenue/royalties generated by a deployed AI model to the DAO contract.
     *      17. `claimRoyalties()`: Allows registered royalty recipients (developers and the DAO itself for the pooled investor share) to claim their proportional earnings from collected royalties.
     *
     * X.   Reputation & Slashing (2 Functions):
     *      18. `updateDeveloperReputation()`: `GOVERNANCE_ROLE` can adjust a developer's on-chain reputation score, impacting their ability to propose or attract future funding.
     *      19. `slashStakedFunds()`: `GOVERNANCE_ROLE` can penalize malicious behavior or fraudulent claims by slashing (seizing) a portion of a user's deposited funds.
     *
     * XI.  Emergency & Setup Functions (5 Functions):
     *      20. `grantCuratorRole()`: `GOVERNANCE_ROLE` can add new addresses to the `CURATOR_ROLE`.
     *      21. `revokeCuratorRole()`: `GOVERNANCE_ROLE` can remove addresses from the `CURATOR_ROLE`.
     *      22. `emergencyPause()`: Allows the `DEFAULT_ADMIN_ROLE` (owner) to pause critical contract functionalities in emergencies.
     *      23. `emergencyUnpause()`: Allows the `DEFAULT_ADMIN_ROLE` to unpause the contract after an emergency.
     *      24. `setGovernanceToken()`: (Owner-only) Sets the address of the governance ERC20 token.
     *      25. `setAIModelNFTContract()`: (Owner-only) Sets the address of the AI Model NFT contract.
     *
     * XII. Helper/View Functions: (Not counted in the 20+ functional functions as they don't change state).
     *      E.g., `getProposalDetails()`, `getFundingRoundDetails()`, `getAIModelDetails()`, etc., for querying contract state.
     */

    /* ========== ROLES ========== */
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    /* ========== STATE VARIABLES ========== */

    // Core Parameters (adjustable by governance votes)
    uint256 public minStakeForProposal;             // Minimum governance token stake to submit a proposal
    uint256 public minVotingPowerForVote;           // Minimum voting power (token balance) to vote
    uint256 public proposalVotingPeriod;            // Duration for proposal voting (seconds)
    uint256 public fundingRoundPeriod;              // Duration for a funding round to be filled (seconds)
    uint256 public curatorVerificationPeriod;       // Max time for curators to verify a milestone after submission (seconds)
    uint256 public constant MAX_MILESTONE_PERCENTAGE = 10000; // Represents 100% (e.g., 2500 for 25%)

    IERC20 public governanceToken;                  // The ERC20 token used for governance and funding
    IAIModelNFT public aiModelNFTContract;          // External contract for AI Model NFTs

    uint256 private _nextProposalId = 1;
    uint256 private _nextFundingRoundId = 1;
    uint256 private _nextAIModelId = 1; // Used for unique AI model NFT IDs
    uint256 private _nextParameterChangeProposalId = 1;

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal; // Total amount requested for the project
        uint256 currentVotesFor;
        uint256 currentVotesAgainst;
        uint256 voteEndTime;
        ProposalStatus status;
        uint256 fundingRoundId; // Link to FundingRound if approved/active
        bool executed; // True if the proposal's execution (creating funding round) has completed
        uint256 requiredReputation; // Minimum reputation for proposer to submit this proposal
        mapping(address => bool) hasVoted; // Tracks who voted on this specific proposal
    }

    struct FundingRound {
        uint256 id;
        uint256 proposalId;
        address developer; // The proposer or chosen developer of the AI model
        uint256 amountRaised; // Amount contributed by investors
        uint256 amountClaimed; // Amount claimed by the developer for completed milestones
        uint256 fundingDeadline;
        FundingRoundStatus status;
        Milestone[] milestones;
        uint256 aiModelId; // Link to the AI model NFT if created
        mapping(address => uint256) contributions; // Investor contributions to this round
    }

    struct Milestone {
        string description;
        uint256 percentageOfFunding; // e.g., 2500 for 25% of the total fundingGoal
        bool completed; // True if funds for this milestone have been claimed
        bool verified; // True if curators have verified the proof
        bytes32 verificationProofHash; // Hash of the ZKP/Oracle proof for this milestone
        uint256 verificationSubmissionTime; // Timestamp when proof was submitted by developer
    }

    struct AIModel {
        uint256 id;
        string name;
        string ipfsHash; // IPFS hash for model metadata, code, or documentation
        address developer; // Original developer/owner of the model NFT
        uint256 fundingRoundId;
        uint256 totalRoyaltiesReceived; // Total royalties collected by this contract for this model
        uint256 totalRoyaltiesDistributed; // Total royalties paid out for this model
        bool isActive; // If true, model is expected to generate royalties
        address[] royaltyRecipients; // Addresses (e.g., developer, DAO treasury for investors)
        uint256[] royaltyShares; // Proportional shares in basis points (e.g., 100 = 1%)
    }

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        uint256 paramType; // Enum or constant representing which parameter to change
        uint256 newValue;
        uint256 voteEndTime;
        uint256 currentVotesFor;
        uint256 currentVotesAgainst;
        bool executed; // True if the parameter change has been applied
        mapping(address => bool) hasVoted;
    }

    // --- Enums ---
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum FundingRoundStatus { Pending, Active, Completed, Failed }
    enum ParamType { MinStakeForProposal, MinVotingPowerForVote, ProposalVotingPeriod, FundingRoundPeriod, CuratorVerificationPeriod }

    // --- Mappings ---
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => FundingRound) public fundingRounds;
    mapping(uint256 => AIModel) public aiModels;
    mapping(address => int256) public developerReputation; // Reputation score for developers (can be positive or negative)
    mapping(address => uint256) public userBalances; // Governance tokens deposited by users into the DAO treasury
    mapping(uint256 => ParameterChangeProposal) public paramChangeProposals;


    /* ========== EVENTS ========== */
    event Initialized(address indexed owner, address indexed governanceToken, address indexed aiModelNFT);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 fundingGoal, string title);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, uint256 indexed fundingRoundId);
    event FundsDeposited(address indexed user, uint256 amount);
    event ContributionMade(uint256 indexed fundingRoundId, address indexed contributor, uint256 amount);
    event FundingRoundStarted(uint256 indexed fundingRoundId, uint256 proposalId, uint256 deadline);
    event MilestoneAdded(uint256 indexed fundingRoundId, uint256 milestoneIndex, string description, uint256 percentage);
    event MilestoneVerificationSubmitted(uint256 indexed fundingRoundId, uint256 indexed milestoneIndex, bytes32 proofHash);
    event MilestoneVerified(uint256 indexed fundingRoundId, uint256 indexed milestoneIndex, address indexed curator);
    event MilestoneFundsClaimed(uint256 indexed fundingRoundId, uint256 indexed milestoneIndex, address indexed developer, uint256 amount);
    event AIModelNFTRegistered(uint256 indexed aiModelId, uint256 indexed fundingRoundId, address indexed developer, string name, string ipfsHash);
    event RoyaltiesDistributed(uint256 indexed aiModelId, uint256 amountReceived, uint256 amountDistributed);
    event RoyaltiesClaimed(uint256 indexed aiModelId, address indexed recipient, uint256 amount);
    event DeveloperReputationUpdated(address indexed developer, int256 oldReputation, int256 newReputation);
    event FundsSlashed(address indexed offender, uint256 amount);
    event UnusedFundsWithdrawn(uint256 indexed fundingRoundId, address indexed contributor, uint256 amount);
    event ProtocolParameterChangeProposed(uint256 indexed proposalId, uint256 paramType, uint256 newValue);
    event ProtocolParameterChangeExecuted(uint256 indexed proposalId, uint256 paramType, uint256 newValue);


    /* ========== CONSTRUCTOR & INITIALIZATION ========== */

    /**
     * @notice Constructor for the SynapseAIDao contract.
     * @param _admin The initial admin address for the AccessControl and Ownable roles.
     *               This address initially holds DEFAULT_ADMIN_ROLE and GOVERNANCE_ROLE.
     */
    constructor(address _admin) Ownable(_admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GOVERNANCE_ROLE, _admin); // Initial governance role given to admin for initial setup
    }

    /**
     * @notice Initializes the core parameters of the DAO and sets up token contracts.
     *         Can only be called once by the owner.
     * @param _governanceToken Address of the ERC20 token used for governance and funding.
     * @param _aiModelNFTContract Address of the external AIModelNFT contract.
     * @param _minStake Minimum stake required to submit a proposal.
     * @param _minVotingPower Minimum token balance required to vote on proposals.
     * @param _proposalVotingPeriod Duration of voting for proposals in seconds.
     * @param _fundingPeriod Duration for a funding round to be filled in seconds.
     * @param _curatorVerificationPeriod Max time for curators to verify a milestone in seconds.
     */
    function initialize(
        address _governanceToken,
        address _aiModelNFTContract,
        uint256 _minStake,
        uint256 _minVotingPower,
        uint256 _proposalVotingPeriod,
        uint256 _fundingPeriod,
        uint256 _curatorVerificationPeriod
    ) external onlyOwner {
        if (governanceToken != address(0) || aiModelNFTContract != address(0) || minStakeForProposal != 0) {
            revert SynapseAIDao__Unauthorized("Contract already initialized.");
        }
        if (_governanceToken == address(0)) revert SynapseAIDao__InvalidAmount("Governance token address invalid.");
        if (_aiModelNFTContract == address(0)) revert SynapseAIDao__InvalidAmount("AI Model NFT contract address invalid.");
        if (_proposalVotingPeriod == 0 || _fundingPeriod == 0 || _curatorVerificationPeriod == 0) revert SynapseAIDao__InvalidAmount("Period durations cannot be zero.");

        governanceToken = IERC20(_governanceToken);
        aiModelNFTContract = IAIModelNFT(_aiModelNFTContract);
        minStakeForProposal = _minStake;
        minVotingPowerForVote = _minVotingPower;
        proposalVotingPeriod = _proposalVotingPeriod;
        fundingRoundPeriod = _fundingPeriod;
        curatorVerificationPeriod = _curatorVerificationPeriod;

        emit Initialized(owner(), _governanceToken, _aiModelNFTContract);
    }

    /**
     * @notice Allows the owner to set the governance token address after deployment.
     *         Intended for initial setup if not passed in constructor, or for upgrades.
     * @param _governanceToken The address of the governance ERC20 token.
     */
    function setGovernanceToken(address _governanceToken) external onlyOwner {
        if (_governanceToken == address(0)) revert SynapseAIDao__InvalidAmount("Zero address for token.");
        governanceToken = IERC20(_governanceToken);
    }

    /**
     * @notice Allows the owner to set the AI Model NFT contract address after deployment.
     *         Intended for initial setup if not passed in constructor, or for upgrades.
     * @param _aiModelNFTContract The address of the AIModelNFT contract.
     */
    function setAIModelNFTContract(address _aiModelNFTContract) external onlyOwner {
        if (_aiModelNFTContract == address(0)) revert SynapseAIDao__InvalidAmount("Zero address for NFT contract.");
        aiModelNFTContract = IAIModelNFT(_aiModelNFTContract);
    }


    /* ========== DAO GOVERNANCE FUNCTIONS (7 functions) ========== */

    /**
     * @notice Allows a user to submit a new proposal for AI model development.
     *         Requires a minimum stake of governance tokens, which is locked until proposal resolution.
     * @param _title The title of the proposal.
     * @param _description A detailed description of the proposed AI model and project.
     * @param _fundingGoal The total amount of governance tokens requested for the project.
     * @param _requiredReputation The minimum developer reputation required to propose this project.
     */
    function submitProposal(
        string calldata _title,
        string calldata _description,
        uint256 _fundingGoal,
        uint256 _requiredReputation
    ) external pausable nonReentrant {
        if (governanceToken == address(0)) revert SynapseAIDao__Unauthorized("Governance token not set.");
        if (developerReputation[msg.sender] < int256(_requiredReputation)) {
            revert SynapseAIDao__InsufficientReputation();
        }
        if (_fundingGoal == 0) revert SynapseAIDao__InvalidAmount("Funding goal cannot be zero.");
        if (minStakeForProposal == 0) revert SynapseAIDao__InvalidAmount("Minimum stake not set."); // Ensure initialized

        // User must stake minStakeForProposal governance tokens
        IERC20(governanceToken).safeTransferFrom(msg.sender, address(this), minStakeForProposal);

        uint256 proposalId = _nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.fundingGoal = _fundingGoal;
        newProposal.voteEndTime = block.timestamp + proposalVotingPeriod;
        newProposal.status = ProposalStatus.Pending;
        newProposal.requiredReputation = _requiredReputation;
        // The `hasVoted` mapping is implicitly initialized.

        emit ProposalSubmitted(proposalId, msg.sender, _fundingGoal, _title);
    }

    /**
     * @notice Allows governance token holders to vote on a submitted proposal.
     *         Requires a minimum voting power (token balance).
     *         Voting power is based on the current balance of governance tokens held by the voter.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external pausable nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SynapseAIDao__InvalidProposalState("Proposal does not exist.");
        if (proposal.status != ProposalStatus.Pending) revert SynapseAIDao__InvalidProposalState("Proposal not in pending state.");
        if (block.timestamp >= proposal.voteEndTime) revert SynapseAIDao__VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert SynapseAIDao__AlreadyVoted();
        if (msg.sender == proposal.proposer) revert SynapseAIDao__CannotVoteOnSelfProposal(); // Prevent self-voting

        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        if (voterBalance < minVotingPowerForVote) revert SynapseAIDao__InsufficientVotingPower();

        if (_support) {
            proposal.currentVotesFor += voterBalance; // Vote power based on token balance
        } else {
            proposal.currentVotesAgainst += voterBalance;
        }
        proposal.hasVoted[msg.sender] = true;

        emit ProposalVoted(_proposalId, msg.sender, _support, voterBalance);
    }

    /**
     * @notice Executes an approved proposal, initiating its funding round.
     *         Callable by anyone after the voting period ends and if the proposal is approved.
     *         Requires the proposal to have more 'for' votes than 'against'.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external pausable nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert SynapseAIDao__InvalidProposalState("Proposal does not exist.");
        if (proposal.status != ProposalStatus.Pending) revert SynapseAIDao__InvalidProposalState("Proposal not in pending state.");
        if (block.timestamp < proposal.voteEndTime) revert SynapseAIDao__VotingPeriodNotEnded();
        if (proposal.executed) revert SynapseAIDao__ProposalAlreadyExecuted();

        // Check for simple majority. Can be extended with quorum requirements.
        if (proposal.currentVotesFor <= proposal.currentVotesAgainst) {
            proposal.status = ProposalStatus.Rejected;
            // Refund proposal stake
            IERC20(governanceToken).safeTransfer(proposal.proposer, minStakeForProposal);
            revert SynapseAIDao__ProposalNotApproved();
        }

        proposal.status = ProposalStatus.Approved;
        proposal.executed = true;

        // Create a new FundingRound for the approved proposal
        uint256 fundingRoundId = _nextFundingRoundId++;
        FundingRound storage newFundingRound = fundingRounds[fundingRoundId];
        newFundingRound.id = fundingRoundId;
        newFundingRound.proposalId = _proposalId;
        newFundingRound.developer = proposal.proposer;
        newFundingRound.fundingDeadline = block.timestamp + fundingRoundPeriod;
        newFundingRound.status = FundingRoundStatus.Active;
        proposal.fundingRoundId = fundingRoundId; // Link proposal to its funding round

        // Refund proposal stake back to the proposer
        IERC20(governanceToken).safeTransfer(proposal.proposer, minStakeForProposal);

        emit ProposalExecuted(_proposalId, fundingRoundId);
        emit FundingRoundStarted(fundingRoundId, _proposalId, newFundingRound.fundingDeadline);
    }

    /**
     * @notice Allows the governance role to propose a change to a core protocol parameter.
     *         This initiates a new governance vote for the proposed change.
     * @param _paramType The type of parameter to change (from ParamType enum).
     * @param _newValue The new value for the parameter.
     */
    function proposeProtocolParameterChange(uint256 _paramType, uint256 _newValue) external onlyRole(GOVERNANCE_ROLE) pausable {
        if (_newValue == 0 && (_paramType == uint256(ParamType.MinStakeForProposal) || _paramType == uint256(ParamType.MinVotingPowerForVote) ||
                              _paramType == uint256(ParamType.ProposalVotingPeriod) || _paramType == uint256(ParamType.FundingRoundPeriod) ||
                              _paramType == uint256(ParamType.CuratorVerificationPeriod))) {
            revert SynapseAIDao__InvalidAmount("New value cannot be zero for these parameters.");
        }

        uint256 proposalId = _nextParameterChangeProposalId++;
        ParameterChangeProposal storage newParamProposal = paramChangeProposals[proposalId];
        newParamProposal.id = proposalId;
        newParamProposal.proposer = msg.sender;
        newParamProposal.paramType = _paramType;
        newParamProposal.newValue = _newValue;
        newParamProposal.voteEndTime = block.timestamp + proposalVotingPeriod; // Uses general proposal voting period

        emit ProtocolParameterChangeProposed(proposalId, _paramType, _newValue);
    }

    /**
     * @notice Allows governance token holders to vote on a protocol parameter change proposal.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProtocolParameterChange(uint256 _proposalId, bool _support) external pausable {
        ParameterChangeProposal storage paramProposal = paramChangeProposals[_proposalId];
        if (paramProposal.id == 0) revert SynapseAIDao__InvalidProposalState("Parameter change proposal does not exist.");
        if (block.timestamp >= paramProposal.voteEndTime) revert SynapseAIDao__VotingPeriodEnded();
        if (paramProposal.executed) revert SynapseAIDao__ProposalAlreadyExecuted();
        if (paramProposal.hasVoted[msg.sender]) revert SynapseAIDao__AlreadyVoted();

        uint256 voterBalance = governanceToken.balanceOf(msg.sender);
        if (voterBalance < minVotingPowerForVote) revert SynapseAIDao__InsufficientVotingPower();

        if (_support) {
            paramProposal.currentVotesFor += voterBalance;
        } else {
            paramProposal.currentVotesAgainst += voterBalance;
        }
        paramProposal.hasVoted[msg.sender] = true;
    }

    /**
     * @notice Executes an approved protocol parameter change proposal.
     *         Callable by anyone after the voting period ends and if the proposal is approved.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeProtocolParameterChange(uint256 _proposalId) external pausable {
        ParameterChangeProposal storage paramProposal = paramChangeProposals[_proposalId];
        if (paramProposal.id == 0) revert SynapseAIDao__InvalidProposalState("Parameter change proposal does not exist.");
        if (block.timestamp < paramProposal.voteEndTime) revert SynapseAIDao__VotingPeriodNotEnded();
        if (paramProposal.executed) revert SynapseAIDao__ProposalAlreadyExecuted();
        if (paramProposal.currentVotesFor <= paramProposal.currentVotesAgainst) revert SynapseAIDao__ProposalNotApproved();

        paramProposal.executed = true; // Mark as executed

        // Apply the parameter change based on the type
        if (paramProposal.paramType == uint256(ParamType.MinStakeForProposal)) {
            minStakeForProposal = paramProposal.newValue;
        } else if (paramProposal.paramType == uint256(ParamType.MinVotingPowerForVote)) {
            minVotingPowerForVote = paramProposal.newValue;
        } else if (paramProposal.paramType == uint256(ParamType.ProposalVotingPeriod)) {
            proposalVotingPeriod = paramProposal.newValue;
        } else if (paramProposal.paramType == uint256(ParamType.FundingRoundPeriod)) {
            fundingRoundPeriod = paramProposal.newValue;
        } else if (paramProposal.paramType == uint256(ParamType.CuratorVerificationPeriod)) {
            curatorVerificationPeriod = paramProposal.newValue;
        } else {
            revert SynapseAIDao__InvalidProposalState("Unknown parameter type.");
        }

        emit ProtocolParameterChangeExecuted(_proposalId, paramProposal.paramType, paramProposal.newValue);
    }


    /* ========== FUNDING & INVESTMENT FUNCTIONS (3 functions) ========== */

    /**
     * @notice Allows users to deposit governance tokens into the DAO's treasury.
     *         These funds increase the user's internal balance and can then be used for investment in funding rounds.
     * @param _amount The amount of governance tokens to deposit.
     */
    function depositFunds(uint256 _amount) external pausable nonReentrant {
        if (governanceToken == address(0)) revert SynapseAIDao__Unauthorized("Governance token not set.");
        if (_amount == 0) revert SynapseAIDao__InvalidAmount("Deposit amount cannot be zero.");

        IERC20(governanceToken).safeTransferFrom(msg.sender, address(this), _amount);
        userBalances[msg.sender] += _amount; // Track user's deposited balance
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Allows investors to contribute their deposited funds to an active funding round.
     *         Funds are moved from the user's internal balance to the funding round's raised amount.
     * @param _fundingRoundId The ID of the funding round to contribute to.
     * @param _amount The amount of governance tokens to contribute.
     */
    function contributeToFundingRound(uint256 _fundingRoundId, uint256 _amount) external pausable nonReentrant {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotActive("Funding round does not exist.");
        if (fundingRound.status != FundingRoundStatus.Active) revert SynapseAIDao__FundingRoundNotActive("Funding round not active.");
        if (block.timestamp >= fundingRound.fundingDeadline) {
            fundingRound.status = FundingRoundStatus.Failed; // Mark as failed if deadline passed
            revert SynapseAIDao__FundingRoundEnded("Funding round has ended.");
        }
        if (_amount == 0) revert SynapseAIDao__InvalidAmount("Contribution amount cannot be zero.");
        if (userBalances[msg.sender] < _amount) revert SynapseAIDao__InsufficientFunds("Insufficient deposited funds.");

        userBalances[msg.sender] -= _amount;
        fundingRound.amountRaised += _amount;
        fundingRound.contributions[msg.sender] += _amount; // Track individual contributions to this round

        emit ContributionMade(_fundingRoundId, msg.sender, _amount);
    }

    /**
     * @notice Allows an investor to withdraw their unused funds from a failed funding round.
     *         A funding round fails if it doesn't meet its `fundingGoal` by the `fundingDeadline`.
     * @param _fundingRoundId The ID of the funding round.
     */
    function withdrawUnusedFundingContribution(uint256 _fundingRoundId) external pausable nonReentrant {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotFailed("Funding round does not exist.");
        
        // Ensure funding round has actually failed (deadline passed and not fully funded)
        if (block.timestamp < fundingRound.fundingDeadline && fundingRound.status == FundingRoundStatus.Active) {
            revert SynapseAIDao__FundingRoundNotFailed("Funding round has not ended or is still active.");
        }
        if (fundingRound.status != FundingRoundStatus.Failed) {
            // If it's completed (fully funded and milestones paid out), funds are not "unused"
            if (fundingRound.status == FundingRoundStatus.Completed) revert SynapseAIDao__FundingRoundNotFailed("Funding round was completed.");
            // If deadline passed, but not marked as failed yet, mark it now.
            if (block.timestamp >= fundingRound.fundingDeadline && fundingRound.amountRaised < proposals[fundingRound.proposalId].fundingGoal) {
                fundingRound.status = FundingRoundStatus.Failed;
            } else {
                revert SynapseAIDao__FundingRoundNotFailed("Funding round not marked as failed yet.");
            }
        }

        uint256 amountToWithdraw = fundingRound.contributions[msg.sender];
        if (amountToWithdraw == 0) revert SynapseAIDao__InvalidAmount("No contributions to withdraw for this round.");

        fundingRound.contributions[msg.sender] = 0; // Reset contribution for this round
        IERC20(governanceToken).safeTransfer(msg.sender, amountToWithdraw);

        emit UnusedFundsWithdrawn(_fundingRoundId, msg.sender, amountToWithdraw);
    }


    /* ========== AI MODEL LIFECYCLE MANAGEMENT FUNCTIONS (7 functions) ========== */

    /**
     * @notice Allows the developer (proposer) of an active funding round to define development milestones.
     *         Milestones outline the stages of project development and their corresponding funding percentages.
     *         Can only be called while the funding round is active and before any funds are claimed.
     * @param _fundingRoundId The ID of the funding round.
     * @param _description A concise description of the milestone.
     * @param _percentage The percentage of the total funding goal allocated to this milestone (e.g., 2500 for 25%).
     */
    function addMilestoneToFundingRound(uint256 _fundingRoundId, string calldata _description, uint256 _percentage) external pausable {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotActive("Funding round does not exist.");
        if (msg.sender != fundingRound.developer) revert SynapseAIDao__Unauthorized("Only the developer can add milestones.");
        if (fundingRound.status != FundingRoundStatus.Active) revert SynapseAIDao__FundingRoundNotActive("Funding round not active.");
        if (fundingRound.amountClaimed > 0) revert SynapseAIDao__InvalidProposalState("Cannot add milestones after funds have been claimed.");
        if (_percentage == 0 || _percentage > MAX_MILESTONE_PERCENTAGE) revert SynapseAIDao__InvalidAmount("Invalid percentage. Must be > 0 and <= 10000.");

        uint256 currentTotalPercentage;
        for (uint i = 0; i < fundingRound.milestones.length; i++) {
            currentTotalPercentage += fundingRound.milestones[i].percentageOfFunding;
        }
        if (currentTotalPercentage + _percentage > MAX_MILESTONE_PERCENTAGE) {
            revert SynapseAIDao__InvalidAmount("Total milestone percentage exceeds 100%.");
        }

        fundingRound.milestones.push(Milestone({
            description: _description,
            percentageOfFunding: _percentage,
            completed: false,
            verified: false,
            verificationProofHash: bytes32(0), // Initial state: no proof submitted
            verificationSubmissionTime: 0
        }));

        emit MilestoneAdded(_fundingRoundId, fundingRound.milestones.length - 1, _description, _percentage);
    }

    /**
     * @notice Developer submits an off-chain verification proof (e.g., ZKP hash, signed oracle data hash) for a completed milestone.
     *         This proof is then subject to curator verification.
     * @param _fundingRoundId The ID of the funding round.
     * @param _milestoneIndex The index of the milestone within the funding round's milestones array.
     * @param _proofHash The cryptographic hash representing the off-chain ZKP or oracle proof.
     */
    function submitMilestoneVerification(
        uint256 _fundingRoundId,
        uint256 _milestoneIndex,
        bytes32 _proofHash
    ) external pausable {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotActive("Funding round does not exist.");
        if (msg.sender != fundingRound.developer) revert SynapseAIDao__Unauthorized("Only the developer can submit verification.");
        if (_milestoneIndex >= fundingRound.milestones.length) revert SynapseAIDao__MilestoneNotFound();

        Milestone storage milestone = fundingRound.milestones[_milestoneIndex];
        if (milestone.completed) revert SynapseAIDao__MilestoneAlreadyCompleted(); // Cannot resubmit for completed milestone
        if (_proofHash == bytes32(0)) revert SynapseAIDao__InvalidAmount("Proof hash cannot be zero.");

        milestone.verificationProofHash = _proofHash;
        milestone.verificationSubmissionTime = block.timestamp;
        milestone.verified = false; // Reset verified status upon new submission

        emit MilestoneVerificationSubmitted(_fundingRoundId, _milestoneIndex, _proofHash);
    }

    /**
     * @notice A designated curator (holding `CURATOR_ROLE`) verifies the submitted proof for a milestone.
     *         This function simulates the on-chain verification of an off-chain proof (e.g., a ZKP, or an oracle report).
     * @param _fundingRoundId The ID of the funding round.
     * @param _milestoneIndex The index of the milestone to verify.
     */
    function markMilestoneAsVerifiedByCurator(uint256 _fundingRoundId, uint256 _milestoneIndex) external onlyRole(CURATOR_ROLE) pausable {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotActive("Funding round does not exist.");
        if (_milestoneIndex >= fundingRound.milestones.length) revert SynapseAIDao__MilestoneNotFound();

        Milestone storage milestone = fundingRound.milestones[_milestoneIndex];
        if (milestone.completed) revert SynapseAIDao__MilestoneAlreadyCompleted(); // Cannot verify a completed milestone
        if (milestone.verificationProofHash == bytes32(0)) revert SynapseAIDao__MilestoneVerificationPending();
        if (milestone.verified) revert SynapseAIDao__MilestoneAlreadyCompleted(); // Already verified

        // Check if the curator has time to verify before period expires (developer might resubmit if expired)
        if (block.timestamp > milestone.verificationSubmissionTime + curatorVerificationPeriod) {
            revert SynapseAIDao__Unauthorized("Verification period for this submission expired.");
        }

        // In a full ZKP integration, this step would involve a ZKP verifier contract
        // `ZKPVerifier.verifyProof(milestone.verificationProofHash, publicInputs)`
        // For this example, we simply mark it as verified by a trusted curator.
        milestone.verified = true;

        emit MilestoneVerified(_fundingRoundId, _milestoneIndex, msg.sender);
    }

    /**
     * @notice Allows the developer to claim funds for a successfully verified milestone.
     *         Funds are transferred from the DAO's treasury to the developer.
     * @param _fundingRoundId The ID of the funding round.
     * @param _milestoneIndex The index of the milestone.
     */
    function claimMilestoneFunds(uint256 _fundingRoundId, uint256 _milestoneIndex) external pausable nonReentrant {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotActive("Funding round does not exist.");
        if (msg.sender != fundingRound.developer) revert SynapseAIDao__Unauthorized("Only the developer can claim funds.");
        if (_milestoneIndex >= fundingRound.milestones.length) revert SynapseAIDao__MilestoneNotFound();
        if (fundingRound.status != FundingRoundStatus.Active && fundingRound.status != FundingRoundStatus.Completed) {
            revert SynapseAIDao__FundingRoundNotActive("Funding round not active or completed.");
        }

        Milestone storage milestone = fundingRound.milestones[_milestoneIndex];
        if (milestone.completed) revert SynapseAIDao__MilestoneAlreadyCompleted();
        if (!milestone.verified) revert SynapseAIDao__MilestoneNotVerified();

        // Ensure the funding goal for the round has been met before payouts
        Proposal storage proposal = proposals[fundingRound.proposalId];
        if (fundingRound.amountRaised < proposal.fundingGoal) {
            revert SynapseAIDao__InsufficientFunds("Funding goal not yet fully met for this round.");
        }

        uint256 payoutAmount = (proposal.fundingGoal * milestone.percentageOfFunding) / MAX_MILESTONE_PERCENTAGE;
        if (payoutAmount == 0) revert SynapseAIDao__InvalidAmount("Calculated payout is zero.");
        if (governanceToken.balanceOf(address(this)) < payoutAmount) revert SynapseAIDao__InsufficientFunds("DAO treasury has insufficient funds.");

        milestone.completed = true;
        fundingRound.amountClaimed += payoutAmount;
        IERC20(governanceToken).safeTransfer(msg.sender, payoutAmount);

        // Check if all milestones are completed to mark funding round as fully completed
        uint256 totalMilestonePercentageCompleted;
        for (uint i = 0; i < fundingRound.milestones.length; i++) {
            if (fundingRound.milestones[i].completed) {
                totalMilestonePercentageCompleted += fundingRound.milestones[i].percentageOfFunding;
            }
        }
        if (totalMilestonePercentageCompleted >= MAX_MILESTONE_PERCENTAGE) {
            fundingRound.status = FundingRoundStatus.Completed;
        }

        emit MilestoneFundsClaimed(_fundingRoundId, _milestoneIndex, msg.sender, payoutAmount);
    }

    /**
     * @notice Registers a fully developed and verified AI model as an NFT on the external AIModelNFT contract.
     *         Callable by the developer once the associated funding round is completed and all milestones are paid out.
     * @param _fundingRoundId The ID of the funding round associated with the model.
     * @param _name The human-readable name of the AI model.
     * @param _ipfsHash IPFS hash linking to model metadata, documentation, or code.
     */
    function registerAIModelNFT(uint256 _fundingRoundId, string calldata _name, string calldata _ipfsHash) external pausable nonReentrant {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (fundingRound.id == 0) revert SynapseAIDao__FundingRoundNotActive("Funding round does not exist.");
        if (msg.sender != fundingRound.developer) revert SynapseAIDao__Unauthorized("Only the developer can register NFT.");
        if (fundingRound.status != FundingRoundStatus.Completed) revert SynapseAIDao__FundingRoundNotActive("Funding round not completed.");
        if (fundingRound.aiModelId != 0) revert SynapseAIDao__AIModelAlreadyRegistered(); // Ensure it's not registered twice
        if (aiModelNFTContract == address(0)) revert SynapseAIDao__Unauthorized("AI Model NFT contract not set.");

        uint256 aiModelId = _nextAIModelId++;
        AIModel storage newAIModel = aiModels[aiModelId];
        newAIModel.id = aiModelId;
        newAIModel.name = _name;
        newAIModel.ipfsHash = _ipfsHash;
        newAIModel.developer = msg.sender;
        newAIModel.fundingRoundId = _fundingRoundId;
        newAIModel.isActive = true;

        // Define royalty split: e.g., Developer gets 50%, DAO Treasury (for investors) gets 50%
        newAIModel.royaltyRecipients.push(msg.sender); // Developer
        newAIModel.royaltyShares.push(5000); // 50% (5000 basis points out of 10000)

        newAIModel.royaltyRecipients.push(address(this)); // DAO Treasury (to manage investor share)
        newAIModel.royaltyShares.push(5000); // 50%

        // Mint the AI Model NFT
        try aiModelNFTContract.mint(msg.sender, aiModelId, _ipfsHash) {
            // NFT successfully minted to the developer's address
        } catch Error(string memory reason) {
            revert SynapseAIDao__CallFailed(string(abi.encodePacked("NFT mint failed: ", reason)));
        } catch {
            revert SynapseAIDao__CallFailed("NFT mint failed unexpectedly.");
        }

        fundingRound.aiModelId = aiModelId; // Link the funding round to the minted NFT

        emit AIModelNFTRegistered(aiModelId, _fundingRoundId, msg.sender, _name, _ipfsHash);
    }

    /**
     * @notice Receives royalties for an AI model from an external source (e.g., a usage marketplace).
     *         These funds are then held by the DAO for distribution to recipients.
     * @dev This function assumes that the external system (the royalty payer) approves and calls
     *      `safeTransferFrom` on the `governanceToken` to send funds to this contract, or simply
     *      transfers them directly if this contract is set as a recipient.
     * @param _aiModelId The ID of the AI model receiving royalties.
     * @param _amount The amount of governance tokens received as royalties.
     */
    function distributeRoyalties(uint256 _aiModelId, uint256 _amount) external pausable nonReentrant {
        AIModel storage model = aiModels[_aiModelId];
        if (model.id == 0) revert SynapseAIDao__AIModelNotFound();
        if (!model.isActive) revert SynapseAIDao__AIModelNotFound("Model is not active for royalties.");
        if (_amount == 0) revert SynapseAIDao__InvalidAmount("Royalty amount cannot be zero.");

        // For simplicity, we assume the funds are already in the contract or approved.
        // A more robust system might have the external caller `IERC20(governanceToken).safeTransferFrom(msg.sender, address(this), _amount);`
        // Or it could be a `payable` function receiving ETH and converting it, etc.
        // For this example, we just update the internal accounting.
        model.totalRoyaltiesReceived += _amount;

        emit RoyaltiesDistributed(_aiModelId, _amount, model.totalRoyaltiesDistributed);
    }

    /**
     * @notice Allows registered royalty recipients (developer, DAO treasury for investors) to claim their share.
     *         Funds are transferred from the DAO's treasury.
     * @param _aiModelId The ID of the AI model to claim royalties from.
     */
    function claimRoyalties(uint256 _aiModelId) external pausable nonReentrant {
        AIModel storage model = aiModels[_aiModelId];
        if (model.id == 0) revert SynapseAIDao__AIModelNotFound();

        uint256 totalClaimable = model.totalRoyaltiesReceived - model.totalRoyaltiesDistributed;
        if (totalClaimable == 0) revert SynapseAIDao__NoRoyaltiesToClaim();
        if (governanceToken.balanceOf(address(this)) < totalClaimable) {
            revert SynapseAIDao__InsufficientFunds("DAO treasury does not hold enough royalties.");
        }

        uint256 recipientIndex = type(uint256).max;
        for (uint i = 0; i < model.royaltyRecipients.length; i++) {
            if (model.royaltyRecipients[i] == msg.sender) {
                recipientIndex = i;
                break;
            }
        }

        if (recipientIndex == type(uint256).max) {
             revert SynapseAIDao__Unauthorized("You are not a registered royalty recipient for this model.");
        }

        uint256 claimAmount = (totalClaimable * model.royaltyShares[recipientIndex]) / MAX_MILESTONE_PERCENTAGE;
        if (claimAmount == 0) revert SynapseAIDao__InvalidAmount("Calculated claim amount is zero.");

        model.totalRoyaltiesDistributed += claimAmount;
        IERC20(governanceToken).safeTransfer(msg.sender, claimAmount);

        emit RoyaltiesClaimed(_aiModelId, msg.sender, claimAmount);

        // Note: For the DAO's share (address(this) as recipient), this implies the funds are moved
        // from `totalRoyaltiesReceived` to be available within the general DAO treasury balance,
        // from where it could eventually be distributed to individual investors via a separate mechanism
        // (e.g., specific investor claims based on their contributions, or DAO votes for payout).
        // This simplified `claimRoyalties` function handles direct recipients.
    }


    /* ========== REPUTATION & SLASHING FUNCTIONS (2 functions) ========== */

    /**
     * @notice Allows addresses with `GOVERNANCE_ROLE` to update a developer's reputation score.
     *         This score can influence future proposal eligibility or funding attractiveness.
     * @param _developer The address of the developer whose reputation is being updated.
     * @param _change The integer amount to add or subtract from the current reputation score.
     */
    function updateDeveloperReputation(address _developer, int256 _change) external onlyRole(GOVERNANCE_ROLE) pausable {
        int256 oldReputation = developerReputation[_developer];
        int256 newReputation = oldReputation + _change;
        developerReputation[_developer] = newReputation;

        emit DeveloperReputationUpdated(_developer, oldReputation, newReputation);
    }

    /**
     * @notice Allows addresses with `GOVERNANCE_ROLE` to slash staked funds from an offender.
     *         This function is intended for penalizing malicious behavior, fraudulent claims, or severe misconduct.
     *         Slashed funds remain within the DAO's treasury.
     * @param _offender The address of the offender whose funds are to be slashed.
     * @param _amount The amount of governance tokens to slash from their `userBalances`.
     */
    function slashStakedFunds(address _offender, uint256 _amount) external onlyRole(GOVERNANCE_ROLE) pausable nonReentrant {
        if (_amount == 0) revert SynapseAIDao__InvalidAmount("Slash amount cannot be zero.");
        if (userBalances[_offender] < _amount) revert SynapseAIDao__InsufficientFunds("Offender does not have enough staked funds to slash.");

        userBalances[_offender] -= _amount;
        // Slashed funds conceptually remain in the contract treasury,
        // increasing the collective pool for future DAO initiatives or investments.
        emit FundsSlashed(_offender, _amount);
    }


    /* ========== ACCESS CONTROL & EMERGENCY FUNCTIONS (5 functions) ========== */

    /**
     * @notice Grants the `CURATOR_ROLE` to an address.
     *         Only callable by an address with `GOVERNANCE_ROLE`.
     * @param _curator The address to grant the role to.
     */
    function grantCuratorRole(address _curator) external onlyRole(GOVERNANCE_ROLE) {
        _grantRole(CURATOR_ROLE, _curator);
    }

    /**
     * @notice Revokes the `CURATOR_ROLE` from an address.
     *         Only callable by an address with `GOVERNANCE_ROLE`.
     * @param _curator The address to revoke the role from.
     */
    function revokeCuratorRole(address _curator) external onlyRole(GOVERNANCE_ROLE) {
        _revokeRole(CURATOR_ROLE, _curator);
    }

    /**
     * @notice Emergency pause function. Only callable by `DEFAULT_ADMIN_ROLE` (initial owner).
     *         This is a critical fail-safe mechanism to stop most contract operations in case of an exploit or severe bug.
     */
    function emergencyPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Emergency unpause function. Only callable by `DEFAULT_ADMIN_ROLE` (initial owner).
     *         Resumes operations after an emergency pause, once the issue is resolved.
     */
    function emergencyUnpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }


    /* ========== VIEW FUNCTIONS (Helpers, not counted in the 20+ functional functions) ========== */

    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            uint256 fundingGoal,
            uint256 currentVotesFor,
            uint256 currentVotesAgainst,
            uint256 voteEndTime,
            ProposalStatus status,
            uint256 fundingRoundId,
            bool executed,
            uint256 requiredReputation
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.title,
            proposal.description,
            proposal.fundingGoal,
            proposal.currentVotesFor,
            proposal.currentVotesAgainst,
            proposal.voteEndTime,
            proposal.status,
            proposal.fundingRoundId,
            proposal.executed,
            proposal.requiredReputation
        );
    }

    function getFundingRoundDetails(uint256 _fundingRoundId)
        external
        view
        returns (
            uint256 id,
            uint256 proposalId,
            address developer,
            uint256 amountRaised,
            uint256 amountClaimed,
            uint256 fundingDeadline,
            FundingRoundStatus status,
            uint256 aiModelId,
            uint256 milestoneCount
        )
    {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        return (
            fundingRound.id,
            fundingRound.proposalId,
            fundingRound.developer,
            fundingRound.amountRaised,
            fundingRound.amountClaimed,
            fundingRound.fundingDeadline,
            fundingRound.status,
            fundingRound.aiModelId,
            fundingRound.milestones.length
        );
    }

    function getMilestoneDetails(uint256 _fundingRoundId, uint256 _milestoneIndex)
        external
        view
        returns (
            string memory description,
            uint256 percentageOfFunding,
            bool completed,
            bool verified,
            bytes32 verificationProofHash,
            uint256 verificationSubmissionTime
        )
    {
        FundingRound storage fundingRound = fundingRounds[_fundingRoundId];
        if (_milestoneIndex >= fundingRound.milestones.length) revert SynapseAIDao__MilestoneNotFound(); // Added bounds check
        Milestone storage milestone = fundingRound.milestones[_milestoneIndex];
        return (
            milestone.description,
            milestone.percentageOfFunding,
            milestone.completed,
            milestone.verified,
            milestone.verificationProofHash,
            milestone.verificationSubmissionTime
        );
    }

    function getAIModelDetails(uint256 _aiModelId)
        external
        view
        returns (
            uint256 id,
            string memory name,
            string memory ipfsHash,
            address developer,
            uint256 fundingRoundId,
            uint256 totalRoyaltiesReceived,
            uint256 totalRoyaltiesDistributed,
            bool isActive,
            address[] memory royaltyRecipients,
            uint256[] memory royaltyShares
        )
    {
        AIModel storage model = aiModels[_aiModelId];
        return (
            model.id,
            model.name,
            model.ipfsHash,
            model.developer,
            model.fundingRoundId,
            model.totalRoyaltiesReceived,
            model.totalRoyaltiesDistributed,
            model.isActive,
            model.royaltyRecipients,
            model.royaltyShares
        );
    }

    function getUserDepositedBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }

    function getDeveloperReputation(address _developer) external view returns (int256) {
        return developerReputation[_developer];
    }

    function getParameterChangeProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            uint256 paramType,
            uint256 newValue,
            uint256 voteEndTime,
            uint256 currentVotesFor,
            uint256 currentVotesAgainst,
            bool executed
        )
    {
        ParameterChangeProposal storage paramProposal = paramChangeProposals[_proposalId];
        return (
            paramProposal.id,
            paramProposal.proposer,
            paramProposal.paramType,
            paramProposal.newValue,
            paramProposal.voteEndTime,
            paramProposal.currentVotesFor,
            paramProposal.currentVotesAgainst,
            paramProposal.executed
        );
    }

    /**
     * @notice Fallback function to prevent accidental ETH transfers.
     *         The contract expects governance tokens, not native currency.
     */
    receive() external payable {
        revert SynapseAIDao__Unauthorized("ETH not accepted. Please use governance token.");
    }

    /**
     * @notice Fallback function for calls to undefined functions.
     */
    fallback() external payable {
        revert SynapseAIDao__Unauthorized("Invalid function call or ETH transfer. Use governance token.");
    }
}
```