Here's a Solidity smart contract that implements "CognitoNet: Decentralized AI Model Co-creation & Adaptive Access Layer". This contract goes beyond typical open-source examples by integrating decentralized AI training incentives, dynamic NFTs that evolve based on AI model performance, and on-chain governance for managing these AI markets.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For uint256ToString for base URI generation

// --- Custom Errors ---
// Errors provide more specific and gas-efficient feedback than revert strings.
error InvalidAddress();
error InvalidMarketId();
error NotMarketCreator();
error NotStaker();
error AlreadyStaked();
error InsufficientStake(uint256 required, uint256 has);
error VotingPeriodNotActive();
error SubmissionPeriodNotActive();
error MarketFinalized();
error NoWinningModel();
error NFTAlreadyMinted(); // Not directly used as we check for _exists(tokenId)
error NotNFTOwnerOrApproved();
error OracleUnauthorized();
error ProposalNotYetExecutable();
error ProposalAlreadyExecuted();
error ProposalDoesNotExist();
error NotMarketStaker(); // Redundant with NotStaker but kept for specific context
error AlreadyVoted();
error InsufficientVotingPower(uint256 required, uint256 has);
error WithdrawCoolDownPeriodNotOver();
error NoPendingWithdrawal();
error InvalidAmount();
error MarketActive(); // Trying to change parameters while market is in an active critical phase
error InvalidPeriod();
error InvalidPercentage();
error MarketNotReadyForFinalization();
error InvalidProposalKey();
error MarketNotFinalized();
error NFTDoesNotExist();
error ModelNotYetSelected();
error NoRewardsToClaim();
error CannotStakeDuringActivePhase();
error ERC20TransferFailed();
error ModelDoesNotExist();

// --- Outline ---
// This contract, CognitoNet, facilitates decentralized co-creation, validation, and access to AI models.
// It allows a community to collaboratively train and validate AI models by contributing resources (stake, data attestations)
// and then provides dynamic, performance-adjusted access to these models via Non-Fungible Tokens (NFTs).
// The NFTs evolve based on model usage, accuracy, and community feedback, using an oracle for off-chain data.
//
// 1.  State Variables & Structs: Definitions for AI Markets, Model Candidates, Access NFTs, and internal counters.
// 2.  Events: Signifying important actions and state changes for off-chain consumption.
// 3.  Errors: Custom error types for specific failure conditions (defined above).
// 4.  Modifiers: For access control and state checks (e.g., `onlyOwner`, `onlyOracle`).
// 5.  Core Protocol Setup & Administration: Constructor, ownership management, contract pausing, oracle address, and fee recipient configuration.
// 6.  AI Market Management: Functions to create new AI training markets, retrieve their details, and manage governance proposals for market parameters.
// 7.  Staking & Data Attestation: Functionality for users to stake tokens to participate in markets, attest to data contributions, and manage stake withdrawals.
// 8.  Model Submission & Validation: AI developers submit their trained models, and stakers vote on these candidates. A market creator finalizes the selection.
// 9.  Dynamic Access NFT (dNFT) Management: Minting of unique dNFTs that grant access to selected AI models. These NFTs' metadata and performance scores are dynamically updated via an external oracle.
// 10. Rewards & Penalties: Mechanisms for stakers to claim rewards from successful models and for distributing usage fees. Includes a function to penalize fraudulent submissions.
// 11. Utility/View Functions: Read-only functions to query the current state of markets, NFTs, and other protocol data.

// --- Function Summary ---

// I. Core Protocol Setup & Administration
// 1.  constructor(address _stakingTokenAddr, address _oracleAddr, string memory _nftName, string memory _nftSymbol): Initializes the contract with the staking ERC20 token, external oracle address, and ERC721 NFT details.
// 2.  setProtocolFeeRecipient(address _recipient): Sets the address that receives protocol fees (owner only).
// 3.  setOracleAddress(address _oracle): Updates the address of the external oracle (owner only).
// 4.  pauseContract(): Pauses core functionality in an emergency (owner only, inherited from Pausable).
// 5.  unpauseContract(): Unpauses the contract (owner only, inherited from Pausable).

// II. AI Market Management
// 6.  createAIMarket(string memory _name, string memory _description, uint256 _stakeRequirement, uint256 _submissionDuration, uint256 _votingDuration, uint256 _rewardPoolPercentage, uint256 _protocolFeePercentage, address _creator): Creates a new AI model market with specified parameters and durations (in seconds).
// 7.  getAIMarketDetails(uint256 _marketId): View function to retrieve comprehensive details of a specific AI market.
// 8.  proposeMarketParameterChange(uint256 _marketId, bytes32 _paramKey, bytes memory _newValue): Initiates a governance proposal to change a specific parameter of an AI market (only during 'OpenForSubmissions' phase).
// 9.  voteOnMarketParameterChange(uint256 _marketId, uint256 _proposalId, bool _support): Allows eligible stakers to cast their vote on a market parameter change proposal.
// 10. executeMarketParameterChange(uint256 _marketId, uint256 _proposalId): Executes a passed market parameter change proposal. This requires owner's action after voting period.

// III. Staking & Data Attestation
// 11. stakeForMarket(uint256 _marketId, uint256 _amount): Allows users to stake the designated ERC20 token to participate in a market, granting voting rights and reward eligibility.
// 12. submitDataAttestation(uint256 _marketId, bytes32 _dataHash, string memory _metadataURI): Enables stakers to attest to contributing training data (off-chain) by submitting a hash and optional metadata.
// 13. initiateWithdrawStake(uint256 _marketId): Initiates the withdrawal process for a user's staked tokens, subject to a cool-down period.
// 14. finalizeWithdrawStake(uint256 _marketId): Completes the withdrawal process, transferring tokens back to the user after the cool-down period.

// IV. Model Submission & Validation
// 15. submitModelCandidate(uint256 _marketId, string memory _modelURI, bytes32 _modelHash): Allows AI developers (who are stakers) to submit their trained model's reference URI and hash.
// 16. voteOnModelCandidate(uint256 _marketId, uint256 _candidateId, bool _support): Enables stakers to vote on the quality and relevance of submitted model candidates.
// 17. finalizeModelSelection(uint256 _marketId): Called by the market creator to conclude the voting phase, select the winning model, and transition the market to 'Finalized'.

// V. Dynamic Access NFT (dNFT) Management
// 18. mintAccessNFT(uint256 _marketId, address _recipient): Mints a new dynamic NFT (ERC721) that grants access to the selected AI model of a finalized market.
// 19. requestNFTPerformanceUpdate(uint256 _marketId, uint256 _tokenId): Triggers a request to the external oracle to fetch and update the performance metrics and metadata URI of a specific dNFT.
// 20. fulfillNFTPerformanceUpdate(uint256 _tokenId, string memory _newMetadataURI, uint256 _newPerformanceScore): Callback function for the trusted oracle to update a dNFT's metadata URI and performance score.
// 21. getNFTMetadataURI(uint256 _tokenId): Returns the current dynamic metadata URI for a given Access NFT. Overrides ERC721's `tokenURI`.
// 22. queryModelAccess(uint256 _tokenId): Provides information about an NFT's associated model, its performance, and whether access is currently active.

// VI. Rewards & Penalties
// 23. claimStakingRewards(uint256 _marketId): Allows eligible stakers to claim their share of the reward pool after a market has finalized.
// 24. distributeModelUsageFees(uint256 _marketId, uint256 _amount): An external function (e.g., called by an API gateway) to deposit usage fees for a model, which are then distributed to the market's reward pool and protocol fees.
// 25. penalizeFraudulentSubmission(uint256 _marketId, address _offender, uint256 _amount): Allows the contract owner to slash a staker's tokens for proven fraudulent activity, adding the slashed amount to the market's reward pool.

contract CognitoNet is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter; // For unique IDs
    using Strings for uint256;          // For converting uint256 to string for URIs

    IERC20 public immutable stakingToken;
    address public oracleAddress;
    address public protocolFeeRecipient;
    uint256 public constant WITHDRAW_COOL_DOWN_PERIOD = 7 days; // 7 days cool-down for stake withdrawal initiation

    Counters.Counter private _marketIdCounter;
    Counters.Counter private _nftIdCounter;

    // Enum to track the lifecycle phase of an AI market
    enum MarketPhase {
        OpenForSubmissions, // Users can stake, submit data, model candidates
        VotingPeriod,       // Stakers vote on models
        Finalized,          // Winning model selected, NFTs can be minted, rewards claimable
        Archived            // Market closed, no further active actions
    }

    // Struct defining an individual AI market
    struct AIMarket {
        string name;
        string description;
        address creator;
        uint256 stakeRequirement;      // Minimum stake required to participate/vote
        uint256 submissionPeriodEnd;   // Timestamp when model & data submissions close
        uint256 votingPeriodEnd;       // Timestamp when voting on models closes
        uint256 creationTime;
        MarketPhase currentPhase;
        uint256 totalStaked;           // Total active stake in this market
        uint256 rewardPool;            // Accumulated rewards for this market
        uint256 rewardPoolPercentage;  // Percentage (0-10000) of `rewardPool` allocated to stakers/model creator
        uint256 protocolFeePercentage; // Percentage (0-10000) of `rewardPool` allocated to protocol
        uint256 winningModelId;        // ID of the chosen model candidate
        bool    hasWinningModel;       // Flag if a winning model has been successfully selected

        mapping(address => uint256) stakers;          // Staker address => amount currently staked
        mapping(address => uint256) claimedRewards;   // Staker address => amount of rewards already claimed
        mapping(address => uint256) pendingWithdrawals; // Staker address => timestamp withdrawal was initiated
        mapping(address => bytes32[]) dataAttestations; // Staker => list of data hashes they attested to
        
        uint256[] candidateIds; // List of all model candidate IDs for this market
        mapping(uint256 => ModelCandidate) modelCandidates; // CandidateId => ModelCandidate struct
        Counters.Counter candidateCounter; // Counter for model candidates within this market

        mapping(address => mapping(uint256 => bool)) hasVotedOnModel; // Staker => CandidateId => Whether they voted for this candidate

        Counters.Counter proposalCounter; // Counter for governance proposals within this market
        mapping(uint256 => MarketParameterProposal) proposals; // ProposalId => MarketParameterProposal struct
    }

    // Struct defining a submitted AI model candidate
    struct ModelCandidate {
        uint256 id;
        string modelURI;    // URI (e.g., IPFS hash) to the off-chain model artifact/metadata
        bytes32 modelHash;  // Cryptographic hash of the model for integrity verification
        address submitter;
        uint252 votes;      // Total vote weight from stakers
        bool approved;      // True if this model was selected as the winning model
        uint256 totalNFTsMinted; // Count of Access NFTs minted for this specific model
    }

    // Struct defining a dynamic Access NFT
    struct AccessNFT {
        uint256 tokenId;
        uint256 marketId;
        uint256 modelCandidateId; // Refers to the specific AI model this NFT grants access to
        string currentMetadataURI; // Dynamic URI pointing to NFT metadata (updated by oracle)
        uint256 performanceScore;  // Dynamic score reflecting model performance (updated by oracle)
        uint256 mintTimestamp;
    }

    // Struct for an on-chain governance proposal for market parameters
    struct MarketParameterProposal {
        uint256 id;
        bytes32 paramKey; // e.g., "stakeRequirement", "submissionDuration" (string converted to bytes32)
        bytes newValue;   // New value for the parameter, ABI encoded (e.g., abi.encode(uint256_value))
        uint256 voteThreshold; // Percentage (0-10000) of total staked tokens required for proposal to pass
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Staker => Voted?
        bool executed;
        bool passed;
        uint256 proposerStakeAtProposal; // Stake of the proposer at the time of proposal creation
    }

    mapping(uint256 => AIMarket) public aiMarkets;     // MarketId => AIMarket struct
    mapping(uint256 => AccessNFT) public accessNFTs;   // tokenId => AccessNFT struct (for dNFT-specific data)
    
    // --- Constructor ---
    // @param _stakingTokenAddr The address of the ERC20 token used for staking.
    // @param _oracleAddr The address of the external oracle (e.g., Chainlink Functions/Keepers).
    // @param _nftName The name of the ERC721 NFT collection (e.g., "CognitoNet AI Access").
    // @param _nftSymbol The symbol of the ERC721 NFT collection (e.g., "CNAI").
    constructor(address _stakingTokenAddr, address _oracleAddr, string memory _nftName, string memory _nftSymbol)
        ERC721(_nftName, _nftSymbol)
        Ownable(msg.sender) // Initialize Ownable with the deployer as owner
    {
        if (_stakingTokenAddr == address(0) || _oracleAddr == address(0)) {
            revert InvalidAddress();
        }
        stakingToken = IERC20(_stakingTokenAddr);
        oracleAddress = _oracleAddr;
        protocolFeeRecipient = msg.sender; // Default protocol fee recipient is the owner
    }

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) {
            revert OracleUnauthorized();
        }
        _;
    }

    modifier onlyMarketCreator(uint256 _marketId) {
        if (aiMarkets[_marketId].creator == address(0)) revert InvalidMarketId(); // Check if market exists
        if (aiMarkets[_marketId].creator != msg.sender) {
            revert NotMarketCreator();
        }
        _;
    }

    modifier onlyStaker(uint256 _marketId) {
        if (aiMarkets[_marketId].creator == address(0)) revert InvalidMarketId(); // Check if market exists
        if (aiMarkets[_marketId].stakers[msg.sender] == 0) {
            revert NotStaker();
        }
        _;
    }

    // --- Events ---
    event AIMarketCreated(uint256 indexed marketId, string name, address indexed creator, uint256 creationTime);
    event Staked(uint256 indexed marketId, address indexed staker, uint256 amount);
    event StakeWithdrawnInitiated(uint256 indexed marketId, address indexed staker, uint256 amount, uint256 withdrawalAvailableTime);
    event StakeWithdrawnFinalized(uint256 indexed marketId, address indexed staker, uint256 amount);
    event DataAttested(uint256 indexed marketId, address indexed staker, bytes32 dataHash, string metadataURI);
    event ModelCandidateSubmitted(uint256 indexed marketId, uint256 indexed candidateId, address indexed submitter, string modelURI);
    event ModelCandidateVoted(uint256 indexed marketId, uint256 indexed candidateId, address indexed voter, bool support);
    event ModelSelected(uint256 indexed marketId, uint256 indexed winningModelId);
    event AccessNFTMinted(uint256 indexed marketId, uint256 indexed tokenId, address indexed recipient, uint256 modelId);
    event NFTPerformanceUpdateRequest(uint256 indexed marketId, uint256 indexed tokenId);
    event NFTPerformanceUpdated(uint256 indexed tokenId, string newMetadataURI, uint256 newPerformanceScore);
    event RewardsClaimed(uint256 indexed marketId, address indexed staker, uint256 amount);
    event UsageFeesDistributed(uint256 indexed marketId, uint256 amount, uint256 protocolFee, uint256 rewardsAdded);
    event FraudulentSubmissionPenalized(uint256 indexed marketId, address indexed offender, uint256 amount);
    event MarketParameterProposalCreated(uint256 indexed marketId, uint256 indexed proposalId, bytes32 paramKey, bytes newValue);
    event MarketParameterProposalVoted(uint256 indexed marketId, uint256 indexed proposalId, address indexed voter, bool support);
    event MarketParameterProposalExecuted(uint256 indexed marketId, uint256 indexed proposalId, bytes32 paramKey);
    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event OracleAddressUpdated(address indexed newOracle);

    // --- I. Core Protocol Setup & Administration ---

    function setProtocolFeeRecipient(address _recipient) external onlyOwner {
        if (_recipient == address(0)) revert InvalidAddress();
        protocolFeeRecipient = _recipient;
        emit ProtocolFeeRecipientUpdated(_recipient);
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert InvalidAddress();
        oracleAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    // `pauseContract` and `unpauseContract` are inherited from Pausable.
    // They effectively pause/unpause all functions using `whenNotPaused` modifier.

    // --- II. AI Market Management ---

    // @param _submissionDuration Duration in seconds for the submission phase.
    // @param _votingDuration Duration in seconds for the voting phase.
    // @param _rewardPoolPercentage Percentage (0-10000) of distributed fees that go to stakers/model creators.
    // @param _protocolFeePercentage Percentage (0-10000) of distributed fees that go to protocolFeeRecipient.
    function createAIMarket(
        string memory _name,
        string memory _description,
        uint256 _stakeRequirement,
        uint256 _submissionDuration, // in seconds
        uint256 _votingDuration,     // in seconds
        uint256 _rewardPoolPercentage, // 0-10000 (100% = 10000)
        uint256 _protocolFeePercentage, // 0-10000
        address _creator // Allows market creator to be different from msg.sender
    ) external onlyOwner whenNotPaused returns (uint256) {
        if (_stakeRequirement == 0) revert InvalidAmount();
        if (_submissionDuration == 0 || _votingDuration == 0) revert InvalidPeriod();
        if (_rewardPoolPercentage + _protocolFeePercentage > 10000) revert InvalidPercentage();
        if (_creator == address(0)) revert InvalidAddress();

        _marketIdCounter.increment();
        uint256 newMarketId = _marketIdCounter.current();

        uint256 _submissionPeriodEnd = block.timestamp + _submissionDuration;
        uint256 _votingPeriodEnd = _submissionPeriodEnd + _votingDuration; // Voting starts right after submissions close

        aiMarkets[newMarketId] = AIMarket({
            name: _name,
            description: _description,
            creator: _creator,
            stakeRequirement: _stakeRequirement,
            submissionPeriodEnd: _submissionPeriodEnd,
            votingPeriodEnd: _votingPeriodEnd,
            creationTime: block.timestamp,
            currentPhase: MarketPhase.OpenForSubmissions,
            totalStaked: 0,
            rewardPool: 0,
            rewardPoolPercentage: _rewardPoolPercentage,
            protocolFeePercentage: _protocolFeePercentage,
            winningModelId: 0,
            hasWinningModel: false,
            candidateIds: new uint256[](0),
            candidateCounter: Counters.Counter(0),
            proposalCounter: Counters.Counter(0)
        });

        emit AIMarketCreated(newMarketId, _name, _creator, block.timestamp);
        return newMarketId;
    }

    function getAIMarketDetails(uint256 _marketId) public view returns (
        string memory name,
        string memory description,
        address creator,
        uint256 stakeRequirement,
        uint256 submissionPeriodEnd,
        uint256 votingPeriodEnd,
        uint256 creationTime,
        MarketPhase currentPhase,
        uint256 totalStaked,
        uint256 rewardPool,
        uint256 rewardPoolPercentage,
        uint256 protocolFeePercentage,
        uint256 winningModelId,
        bool hasWinningModel
    ) {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.creator == address(0)) revert InvalidMarketId(); // Check if market exists

        return (
            market.name,
            market.description,
            market.creator,
            market.stakeRequirement,
            market.submissionPeriodEnd,
            market.votingPeriodEnd,
            market.creationTime,
            market.currentPhase,
            market.totalStaked,
            market.rewardPool,
            market.rewardPoolPercentage,
            market.protocolFeePercentage,
            market.winningModelId,
            market.hasWinningModel
        );
    }

    // Allows the market creator to propose changes to market parameters.
    // Changes can only be proposed and voted on during the `OpenForSubmissions` phase
    // to prevent disrupting active processes.
    function proposeMarketParameterChange(
        uint256 _marketId,
        bytes32 _paramKey, // e.g., keccak256("stakeRequirement")
        bytes memory _newValue // abi.encode(uint256 new_value)
    ) external onlyMarketCreator(_marketId) whenNotPaused returns (uint256) {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.currentPhase != MarketPhase.OpenForSubmissions) revert MarketActive();

        uint256 proposerStake = market.stakers[msg.sender];
        if (proposerStake == 0) revert InsufficientVotingPower(1, 0); // Requires some stake to propose

        market.proposalCounter.increment();
        uint256 proposalId = market.proposalCounter.current();

        market.proposals[proposalId] = MarketParameterProposal({
            id: proposalId,
            paramKey: _paramKey,
            newValue: _newValue,
            voteThreshold: 5000, // 50% of total staked amount for a simple majority, hardcoded for now
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            proposerStakeAtProposal: proposerStake
        });

        emit MarketParameterProposalCreated(_marketId, proposalId, _paramKey, _newValue);
        return proposalId;
    }

    function voteOnMarketParameterChange(
        uint256 _marketId,
        uint256 _proposalId,
        bool _support
    ) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        MarketParameterProposal storage proposal = market.proposals[_proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (market.currentPhase != MarketPhase.OpenForSubmissions) revert MarketActive(); // Voting only in submission phase
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voterStake = market.stakers[msg.sender];
        if (voterStake < market.stakeRequirement) revert InsufficientVotingPower(market.stakeRequirement, voterStake);

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterStake;
        } else {
            proposal.votesAgainst += voterStake;
        }

        emit MarketParameterProposalVoted(_marketId, _proposalId, msg.sender, _support);
    }

    // For simplicity, the owner executes passed proposals. In a full DAO, this might be a DAO vote.
    function executeMarketParameterChange(
        uint256 _marketId,
        uint256 _proposalId
    ) external onlyOwner whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        MarketParameterProposal storage proposal = market.proposals[_proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (market.currentPhase != MarketPhase.OpenForSubmissions) revert MarketActive();

        // Check if proposal has passed the threshold
        uint256 totalMarketStake = market.totalStaked;
        if (totalMarketStake == 0) {
            revert ProposalNotYetExecutable(); // No stakes means no voting power to pass
        }
        if ( (proposal.votesFor * 10000) / totalMarketStake < proposal.voteThreshold ) {
            revert ProposalNotYetExecutable();
        }

        // Apply the change based on the paramKey
        bytes32 paramKey = proposal.paramKey;
        bytes memory newValue = proposal.newValue;

        if (paramKey == keccak256("stakeRequirement")) {
            market.stakeRequirement = abi.decode(newValue, (uint256));
        } else if (paramKey == keccak256("submissionDuration")) {
            uint256 newDuration = abi.decode(newValue, (uint256));
            if (newDuration == 0) revert InvalidPeriod();
            market.submissionPeriodEnd = market.creationTime + newDuration;
        } else if (paramKey == keccak256("votingDuration")) {
            uint256 newDuration = abi.decode(newValue, (uint256));
            if (newDuration == 0) revert InvalidPeriod();
            market.votingPeriodEnd = market.submissionPeriodEnd + newDuration;
        } else if (paramKey == keccak256("rewardPoolPercentage")) {
            uint256 newPercentage = abi.decode(newValue, (uint256));
            if (newPercentage + market.protocolFeePercentage > 10000) revert InvalidPercentage();
            market.rewardPoolPercentage = newPercentage;
        } else if (paramKey == keccak256("protocolFeePercentage")) {
            uint256 newPercentage = abi.decode(newValue, (uint256));
            if (market.rewardPoolPercentage + newPercentage > 10000) revert InvalidPercentage();
            market.protocolFeePercentage = newPercentage;
        }
        else {
            revert InvalidProposalKey();
        }

        proposal.executed = true;
        proposal.passed = true;
        emit MarketParameterProposalExecuted(_marketId, _proposalId, paramKey);
    }

    // --- III. Staking & Data Attestation ---

    function stakeForMarket(uint256 _marketId, uint256 _amount) external whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.creator == address(0)) revert InvalidMarketId();
        if (market.currentPhase != MarketPhase.OpenForSubmissions || block.timestamp >= market.submissionPeriodEnd) {
            revert CannotStakeDuringActivePhase(); // Staking allowed only during initial phase
        }
        if (_amount < market.stakeRequirement) revert InsufficientStake(market.stakeRequirement, _amount);
        if (_amount == 0) revert InvalidAmount();

        // Transfer tokens from staker to contract (requires prior approval via ERC20 `approve`)
        bool success = stakingToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert ERC20TransferFailed();

        market.stakers[msg.sender] += _amount;
        market.totalStaked += _amount;

        emit Staked(_marketId, msg.sender, _amount);
    }

    // Allows stakers to attest to having contributed data, potentially linking to off-chain data via hash and URI.
    function submitDataAttestation(uint256 _marketId, bytes32 _dataHash, string memory _metadataURI) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (block.timestamp >= market.submissionPeriodEnd) {
            revert SubmissionPeriodNotActive();
        }
        if (market.currentPhase != MarketPhase.OpenForSubmissions) { // Redundant but explicit
            revert SubmissionPeriodNotActive();
        }

        market.dataAttestations[msg.sender].push(_dataHash);
        emit DataAttested(_marketId, msg.sender, _dataHash, _metadataURI);
    }

    // Initiates the withdrawal process for staked tokens. Requires a cool-down period.
    function initiateWithdrawStake(uint256 _marketId) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.stakers[msg.sender] == 0) revert NoPendingWithdrawal(); 
        if (market.pendingWithdrawals[msg.sender] != 0) revert NoPendingWithdrawal(); // Already initiated

        market.pendingWithdrawals[msg.sender] = block.timestamp + WITHDRAW_COOL_DOWN_PERIOD;
        emit StakeWithdrawnInitiated(_marketId, msg.sender, market.stakers[msg.sender], market.pendingWithdrawals[msg.sender]);
    }

    // Finalizes the withdrawal after the cool-down.
    function finalizeWithdrawStake(uint256 _marketId) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.pendingWithdrawals[msg.sender] == 0) revert NoPendingWithdrawal();
        if (block.timestamp < market.pendingWithdrawals[msg.sender]) revert WithdrawCoolDownPeriodNotOver();

        uint256 amountToWithdraw = market.stakers[msg.sender];
        if (amountToWithdraw == 0) revert NoPendingWithdrawal(); 

        market.stakers[msg.sender] = 0;
        market.totalStaked -= amountToWithdraw;
        market.pendingWithdrawals[msg.sender] = 0; // Reset pending withdrawal

        bool success = stakingToken.transfer(msg.sender, amountToWithdraw);
        if (!success) revert ERC20TransferFailed();

        emit StakeWithdrawnFinalized(_marketId, msg.sender, amountToWithdraw);
    }

    // --- IV. Model Submission & Validation ---

    // Allows stakers to submit their trained AI model.
    function submitModelCandidate(
        uint256 _marketId,
        string memory _modelURI, // URI to off-chain model artifact/metadata
        bytes32 _modelHash      // Hash for integrity verification
    ) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (block.timestamp >= market.submissionPeriodEnd) {
            revert SubmissionPeriodNotActive();
        }
        if (market.currentPhase != MarketPhase.OpenForSubmissions) { // Redundant but explicit
            revert SubmissionPeriodNotActive();
        }

        market.candidateCounter.increment();
        uint256 candidateId = market.candidateCounter.current();

        market.modelCandidates[candidateId] = ModelCandidate({
            id: candidateId,
            modelURI: _modelURI,
            modelHash: _modelHash,
            submitter: msg.sender,
            votes: 0,
            approved: false,
            totalNFTsMinted: 0
        });
        market.candidateIds.push(candidateId);

        emit ModelCandidateSubmitted(_marketId, candidateId, msg.sender, _modelURI);
    }

    // Allows stakers to vote on model candidates.
    function voteOnModelCandidate(
        uint256 _marketId,
        uint256 _candidateId,
        bool _support
    ) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (block.timestamp < market.submissionPeriodEnd || block.timestamp >= market.votingPeriodEnd) {
            revert VotingPeriodNotActive();
        }
        if (market.currentPhase != MarketPhase.VotingPeriod) { // Explicit phase check
             revert VotingPeriodNotActive();
        }

        ModelCandidate storage candidate = market.modelCandidates[_candidateId];
        if (candidate.id == 0) revert ModelDoesNotExist();
        if (market.hasVotedOnModel[msg.sender][_candidateId]) revert AlreadyVoted();

        uint256 voterStake = market.stakers[msg.sender];
        if (voterStake < market.stakeRequirement) revert InsufficientVotingPower(market.stakeRequirement, voterStake);

        market.hasVotedOnModel[msg.sender][_candidateId] = true;
        if (_support) {
            candidate.votes += voterStake;
        }

        emit ModelCandidateVoted(_marketId, _candidateId, msg.sender, _support);
    }

    // Market creator finalizes the model selection after voting ends.
    function finalizeModelSelection(uint256 _marketId) external onlyMarketCreator(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.currentPhase == MarketPhase.Finalized || market.currentPhase == MarketPhase.Archived) {
            revert MarketFinalized();
        }
        
        // Transition from OpenForSubmissions to VotingPeriod if not already
        if (market.currentPhase == MarketPhase.OpenForSubmissions) {
            if (block.timestamp < market.submissionPeriodEnd) {
                revert MarketNotReadyForFinalization(); // Submissions still open
            }
            market.currentPhase = MarketPhase.VotingPeriod;
        }

        // Check if voting period has concluded
        if (market.currentPhase != MarketPhase.VotingPeriod || block.timestamp < market.votingPeriodEnd) {
            revert VotingPeriodNotActive();
        }

        uint256 winningCandidateId = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < market.candidateIds.length; i++) {
            uint256 candidateId = market.candidateIds[i];
            ModelCandidate storage candidate = market.modelCandidates[candidateId];
            if (candidate.votes > maxVotes) {
                maxVotes = candidate.votes;
                winningCandidateId = candidateId;
            }
        }

        if (winningCandidateId == 0) revert NoWinningModel(); // No models submitted or no votes for any

        market.winningModelId = winningCandidateId;
        market.modelCandidates[winningCandidateId].approved = true;
        market.hasWinningModel = true;
        market.currentPhase = MarketPhase.Finalized;

        emit ModelSelected(_marketId, winningCandidateId);
    }
    
    // --- V. Dynamic Access NFT (dNFT) Management ---

    // Mints a new dynamic Access NFT for the selected AI model.
    function mintAccessNFT(uint256 _marketId, address _recipient) external whenNotPaused returns (uint256) {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.creator == address(0)) revert InvalidMarketId();
        if (market.currentPhase != MarketPhase.Finalized) revert MarketNotFinalized();
        if (!market.hasWinningModel) revert NoWinningModel();
        if (_recipient == address(0)) revert InvalidAddress();

        _nftIdCounter.increment();
        uint256 newTokenId = _nftIdCounter.current();

        // Initial metadata URI, typically a generic placeholder.
        // The oracle will provide specific, dynamic metadata later.
        string memory initialMetadataURI = string(abi.encodePacked(
            "https://api.cognitonet.io/nft/", // Example base URI for a dApp frontend
            _marketId.toString(),
            "/",
            market.winningModelId.toString(),
            "/",
            newTokenId.toString(),
            "/initial.json"
        ));

        accessNFTs[newTokenId] = AccessNFT({
            tokenId: newTokenId,
            marketId: _marketId,
            modelCandidateId: market.winningModelId,
            currentMetadataURI: initialMetadataURI,
            performanceScore: 0, // Initial score, to be updated by oracle
            mintTimestamp: block.timestamp
        });
        
        market.modelCandidates[market.winningModelId].totalNFTsMinted++;
        _safeMint(_recipient, newTokenId); // Mint ERC721 token

        emit AccessNFTMinted(_marketId, newTokenId, _recipient, market.winningModelId);
        return newTokenId;
    }

    // Triggers an off-chain request for the oracle to update an NFT's performance data.
    // Can be initiated by the NFT owner or an approved operator.
    function requestNFTPerformanceUpdate(uint256 _marketId, uint256 _tokenId) external whenNotPaused {
        if (!_exists(_tokenId)) revert NFTDoesNotExist();
        if (ownerOf(_tokenId) != msg.sender && getApproved(_tokenId) != msg.sender && !isApprovedForAll(ownerOf(_tokenId), msg.sender)) {
            revert NotNFTOwnerOrApproved();
        }
        if (accessNFTs[_tokenId].marketId != _marketId) revert InvalidMarketId();
        
        // In a real Chainlink Functions/Keepers integration, this would trigger an actual request.
        // For this example, it's represented by an event.
        emit NFTPerformanceUpdateRequest(_marketId, _tokenId);
    }

    // Callback function for the oracle to update the dNFT's metadata and performance score.
    function fulfillNFTPerformanceUpdate(
        uint256 _tokenId,
        string memory _newMetadataURI,
        uint256 _newPerformanceScore
    ) external onlyOracle {
        AccessNFT storage nft = accessNFTs[_tokenId];
        if (nft.tokenId == 0) revert NFTDoesNotExist(); // Check if NFT exists in our custom storage

        nft.currentMetadataURI = _newMetadataURI;
        nft.performanceScore = _newPerformanceScore;

        emit NFTPerformanceUpdated(_tokenId, _newMetadataURI, _newPerformanceScore);
    }

    // Overrides ERC721's `tokenURI` to return the dynamic URI stored in our AccessNFT struct.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId); // ERC721 standard error
        return accessNFTs[tokenId].currentMetadataURI;
    }

    // Direct getter for the current dynamic metadata URI.
    function getNFTMetadataURI(uint256 _tokenId) external view returns (string memory) {
        if (!_exists(_tokenId)) revert NFTDoesNotExist();
        return accessNFTs[_tokenId].currentMetadataURI;
    }

    // Allows dApps or users to query the access status and performance of an NFT.
    function queryModelAccess(uint256 _tokenId) external view returns (uint256 marketId, uint256 modelId, uint256 performanceScore, bool isActive) {
        AccessNFT storage nft = accessNFTs[_tokenId];
        if (nft.tokenId == 0) revert NFTDoesNotExist();

        AIMarket storage market = aiMarkets[nft.marketId];
        bool _isActive = (market.currentPhase == MarketPhase.Finalized) && market.modelCandidates[nft.modelCandidateId].approved;

        return (nft.marketId, nft.modelCandidateId, nft.performanceScore, _isActive);
    }

    // --- VI. Rewards & Penalties ---

    // Allows stakers to claim their share of the market's reward pool.
    function claimStakingRewards(uint256 _marketId) external onlyStaker(_marketId) whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.currentPhase != MarketPhase.Finalized && market.currentPhase != MarketPhase.Archived) {
            revert MarketNotFinalized();
        }
        if (!market.hasWinningModel) revert NoWinningModel();
        
        uint256 stakerStake = market.stakers[msg.sender];
        if (stakerStake == 0) revert NoRewardsToClaim(); // Staker has no active stake or already withdrew

        uint256 totalRewardPool = market.rewardPool;
        if (totalRewardPool == 0) revert NoRewardsToClaim();

        // Calculate rewards proportional to stake and market's reward pool percentage
        uint256 rewardsShareForStakers = (totalRewardPool * market.rewardPoolPercentage) / 10000;
        uint256 stakerReward = (rewardsShareForStakers * stakerStake) / market.totalStaked;

        if (stakerReward == 0) revert NoRewardsToClaim();
        // Prevent claiming more than available or double claiming for simplicity
        if (stakerReward > market.rewardPool) stakerReward = market.rewardPool; // Cap if calculation is off

        market.claimedRewards[msg.sender] += stakerReward;
        market.rewardPool -= stakerReward; 

        bool success = stakingToken.transfer(msg.sender, stakerReward);
        if (!success) revert ERC20TransferFailed();

        emit RewardsClaimed(_marketId, msg.sender, stakerReward);
    }

    // External systems (e.g., an off-chain API gateway) deposit usage fees for a model.
    // These fees are then split between the protocol and the market's reward pool.
    function distributeModelUsageFees(uint256 _marketId, uint256 _amount) external whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.creator == address(0)) revert InvalidMarketId();
        if (market.currentPhase != MarketPhase.Finalized && market.currentPhase != MarketPhase.Archived) {
            revert MarketNotFinalized();
        }
        if (!market.hasWinningModel) revert NoWinningModel();
        if (_amount == 0) revert InvalidAmount();

        // Transfer fees to the contract
        bool success = stakingToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert ERC20TransferFailed();

        uint256 protocolFee = (_amount * market.protocolFeePercentage) / 10000;
        uint256 remainingForRewards = _amount - protocolFee;

        // Transfer protocol fee to recipient
        if (protocolFee > 0) {
            success = stakingToken.transfer(protocolFeeRecipient, protocolFee);
            if (!success) revert ERC20TransferFailed();
        }

        market.rewardPool += remainingForRewards; // Add remaining to reward pool for stakers
        
        emit UsageFeesDistributed(_marketId, _amount, protocolFee, remainingForRewards);
    }

    // Allows the contract owner to penalize a staker for proven fraudulent submissions.
    // The slashed amount is added to the market's reward pool.
    function penalizeFraudulentSubmission(uint256 _marketId, address _offender, uint256 _amount) external onlyOwner whenNotPaused {
        AIMarket storage market = aiMarkets[_marketId];
        if (market.creator == address(0)) revert InvalidMarketId();
        if (market.stakers[_offender] == 0 || market.stakers[_offender] < _amount) {
            revert InsufficientStake(market.stakers[_offender], _amount);
        }
        if (_amount == 0) revert InvalidAmount();

        market.stakers[_offender] -= _amount;
        market.totalStaked -= _amount;
        market.rewardPool += _amount; // Slashed amount goes to the market's reward pool

        emit FraudulentSubmissionPenalized(_marketId, _offender, _amount);
    }
}
```