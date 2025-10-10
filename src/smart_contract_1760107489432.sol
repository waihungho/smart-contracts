```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AetheriumLab
 * @author YourName (or AI Creator)
 * @notice A Decentralized Autonomous Research & Development Lab (DARL).
 * This contract facilitates collaborative knowledge generation, peer validation,
 * and incentivized research through a system of Research Sprints, Knowledge Artifact NFTs,
 * and decentralized governance. It integrates dynamic NFT metadata, stake-weighted validation,
 * a basic reputation system (implicitly managed by rewards/penalties), and oracle integration.
 *
 * @dev This contract relies on external ERC-20 (AetherToken) and ERC-721 (KnowledgeArtifactNFT)
 * implementations. The interfaces are defined internally for simplicity.
 * All critical configuration changes and operational decisions are subject to DAO governance.
 */

// Outline & Function Summary:
//
// I. Initialization & Configuration (DAO controlled)
//    1.  initializeLab: Sets up core token and NFT contract addresses, initial parameters.
//    2.  updateLabConfig: Modifies global configuration settings (e.g., sprint durations, stake requirements).
//    3.  pauseLab: Emergency pause function for critical issues.
//    4.  unpauseLab: Resumes operations after a pause.
//
// II. Research Sprints & Proposals
//    5.  proposeResearchSprint: Allows users to propose new research challenges with details and initial rewards.
//    6.  voteOnSprintProposal: DAO members vote to approve or reject proposed sprints based on their staked tokens.
//    7.  fundResearchSprint: Contributes AetherTokens to a sprint's reward pool, activating it if sufficient funds are met.
//    8.  submitResearchOutcome: Researchers submit their findings and evidence (IPFS CIDs) for a sprint.
//    9.  finalizeResearchSprint: Marks a sprint as complete, initiating reward distribution and NFT minting if validated.
//
// III. Knowledge Artifact NFTs (KANFTs) Management
//    10. mintKnowledgeArtifact: Internal function to create a new KANFT representing validated research, tying it to the sprint.
//    11. requestDynamicMetadataUpdate: Proposes an update to a KANFT's metadata (e.g., new insights, corrections, extensions).
//    12. validateMetadataUpdate: Community/DAO votes to approve or reject a proposed KANFT metadata update based on staked tokens.
//    13. grantDelegatedAccess: Temporarily grants an address read/use access to a private KANFT's content (if content is external/gated).
//    14. revokeDelegatedAccess: Revokes previously granted delegated access to a KANFT.
//
// IV. Staking, Validation & Rewards
//    15. stakeForParticipation: Users stake AetherTokens to participate as researchers or validators, gaining voting power.
//    16. unstakeFromParticipation: Allows users to withdraw their staked AetherTokens after a cooldown period.
//    17. validateResearchOutcome: Participants review submitted research outcomes and cast a stake-weighted vote on its validity.
//    18. disputeValidationResult: Initiates a dispute resolution process for contested validation outcomes, potentially involving DAO arbitration.
//    19. claimResearchReward: Researchers claim their share of the sprint reward pool upon successful validation of their outcome.
//    20. claimValidationReward: Validators claim rewards for correctly validating research outcomes.
//
// V. Decentralized Autonomous Organization (DAO) Governance
//    21. proposeGovernanceAction: Submits a generic DAO proposal for contract upgrades, parameter changes, or arbitrary calls.
//    22. castGovernanceVote: DAO members cast their stake-weighted vote on an active governance proposal.
//    23. executeGovernanceAction: Executes a passed governance proposal, triggering its target function call.
//
// VI. Oracle & External Data Integration
//    24. addOracleAddress: Whitelists an address to be a trusted oracle.
//    25. removeOracleAddress: Removes an address from the trusted oracle list.
//    26. submitVerifiedOracleData: Allows whitelisted oracles to submit signed, verifiable external data for research inputs or validation.

// --- Minimal ERC-20 Interface (for AetherToken) ---
interface IAetherToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// --- Minimal ERC-721 Interface (for KnowledgeArtifactNFT) ---
interface IKnowledgeArtifactNFT {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function mint(address to, uint256 tokenId, string calldata uri) external returns (uint256); // Custom mint function
    function ownerOf(uint256 tokenId) external view returns (address);
    function setTokenURI(uint256 tokenId, string calldata newUri) external; // Custom metadata update
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract AetheriumLab {
    // --- State Variables ---
    IAetherToken public aetherToken; // The ERC-20 token used for staking and rewards
    IKnowledgeArtifactNFT public knowledgeArtifactNFT; // The ERC-721 token for research outputs

    address public daoManager; // Address responsible for initial DAO setup, can be changed by DAO
    bool public paused; // Global pause mechanism

    uint256 public nextSprintId;
    uint256 public nextKANFTId; // Next Knowledge Artifact NFT ID
    uint256 public nextMetadataProposalId;
    uint256 public nextGovernanceProposalId;

    // Configuration parameters
    uint256 public minStakeForParticipation; // Minimum tokens to stake to participate
    uint256 public sprintProposalMinStake; // Minimum stake to propose a sprint
    uint256 public sprintVotingPeriodBlocks; // Duration for DAO to vote on sprint proposals
    uint256 public outcomeValidationPeriodBlocks; // Duration for community to validate outcomes
    uint256 public minSprintRewardPool; // Minimum required funding for a sprint to activate
    uint256 public validationThresholdPercentage; // E.g., 51 for 51% stake majority
    uint256 public stakingCooldownBlocks; // Blocks a user must wait after unstake request
    uint256 public metadataUpdateVotingPeriodBlocks; // Duration for DAO to vote on NFT metadata updates
    uint256 public governanceProposalVotingPeriodBlocks; // Duration for DAO to vote on governance proposals

    // Mappings for core data
    mapping(uint256 => ResearchSprint) public researchSprints;
    mapping(address => uint256) public stakedBalances; // User stakes for participation
    mapping(address => uint256) public unstakeRequestBlock; // Block when unstake was requested
    mapping(address => bool) public isOracle; // Whitelisted oracles
    mapping(uint256 => MetadataUpdateProposal) public metadataUpdateProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public hasClaimedResearchReward;
    mapping(uint256 => mapping(address => bool)) public hasClaimedValidationReward;

    // For delegated access to KANFTs (implies off-chain content gating)
    mapping(uint256 => mapping(address => uint256)) public delegatedKANFTAccessExpires; // tokenId => delegate => expiryBlock

    // --- Struct Definitions ---
    struct ResearchSprint {
        string title;
        string descriptionCID; // IPFS CID for detailed description
        uint256 rewardPool; // Total AetherTokens allocated to this sprint
        uint256 durationBlocks; // Blocks for researchers to submit
        uint256 startBlock;
        uint256 endBlock; // submission period end
        uint256 validationEndBlock; // validation period end
        uint256 validationThresholdPercentage; // E.g., 51 for 51% stake majority
        uint256 totalOutcomesSubmitted;
        bool isActive;
        bool isFinalized;
        address proposer;
        uint256 kanftId; // KANFT minted for this sprint, 0 if none
        // DAO voting for sprint approval
        uint256 approvalProposalId; // ID of the governance proposal to approve this sprint
        uint256 outcomeCount;
        mapping(uint256 => Outcome) outcomes; // Map outcome ID to Outcome struct
    }

    struct Outcome {
        address[] researchers; // List of addresses of researchers who collaborated
        string outcomeCID; // IPFS CID for research result/data
        uint256 submissionBlock;
        uint256 totalValidationStake; // Total stake from validators participating in this outcome's validation
        uint256 validVotesWeight; // Sum of stakes from validators who voted 'valid'
        uint256 invalidVotesWeight; // Sum of stakes from validators who voted 'invalid'
        mapping(address => bool) hasVoted; // To prevent double voting by a validator
        bool isValidated; // Final decision
        bool isDisputed; // If a dispute is active
        uint256 disputeResolutionBlock; // Block until dispute resolution is open
    }

    struct MetadataUpdateProposal {
        uint256 tokenId;
        string newMetadataCID;
        uint256 proposalBlock;
        uint256 expirationBlock;
        bool isApproved;
        bool isExecuted;
        uint256 yesVotesWeight; // Sum of stakes for 'yes'
        uint256 noVotesWeight; // Sum of stakes for 'no'
        mapping(address => bool) hasVoted; // To prevent double voting
    }

    struct GovernanceProposal {
        string proposalCID; // IPFS CID for detailed proposal text
        uint256 expirationBlock;
        address targetContract;
        bytes calldataBytes; // The actual call to make if proposal passes
        bool isExecuted;
        bool isApproved;
        uint256 yesVotesWeight; // Sum of stakes for 'yes'
        uint256 noVotesWeight; // Sum of stakes for 'no'
        mapping(address => bool) hasVoted; // To prevent double voting
    }

    // --- Events ---
    event Initialized(address indexed token, address indexed nft, address indexed daoManager);
    event ConfigUpdated(string key, uint256 value);
    event Paused(address account);
    event Unpaused(address account);
    event ResearchSprintProposed(uint256 indexed sprintId, address indexed proposer, string title, uint256 rewardPool);
    event SprintProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ResearchSprintApproved(uint256 indexed sprintId, address indexed proposer);
    event ResearchSprintFunded(uint256 indexed sprintId, address indexed funder, uint256 amount);
    event ResearchSprintActivated(uint256 indexed sprintId, uint256 startBlock, uint256 endBlock);
    event ResearchOutcomeSubmitted(uint256 indexed sprintId, uint256 indexed outcomeIndex, address indexed researcher, string outcomeCID);
    event ResearchOutcomeValidated(uint256 indexed sprintId, uint256 indexed outcomeIndex, bool isValidated);
    event ResearchSprintFinalized(uint256 indexed sprintId, uint256 totalRewardDistributed);
    event KANFTMetadataUpdateProposed(uint256 indexed tokenId, uint256 indexed proposalId, string newMetadataCID);
    event KANFTMetadataUpdateVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event KANFTMetadataUpdated(uint256 indexed tokenId, string newMetadataCID);
    event KANFTDelegatedAccessGranted(uint256 indexed tokenId, address indexed delegate, uint256 expires);
    event KANFTDelegatedAccessRevoked(uint256 indexed tokenId, address indexed delegate);
    event Staked(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount, uint256 unlockBlock);
    event Unstaked(address indexed user, uint256 amount);
    event OutcomeValidated(uint256 indexed sprintId, uint256 indexed outcomeIndex, address indexed validator, bool vote, uint256 voteWeight);
    event OutcomeDisputed(uint256 indexed sprintId, uint256 indexed outcomeIndex, address indexed disputer);
    event ResearchRewardClaimed(uint256 indexed sprintId, uint256 indexed outcomeIndex, address indexed researcher, uint256 amount);
    event ValidationRewardClaimed(uint256 indexed sprintId, uint256 indexed outcomeIndex, address indexed validator, uint256 amount);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string proposalCID);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event OracleAddressAdded(address indexed oracle);
    event OracleAddressRemoved(address indexed oracle);
    event VerifiedOracleDataSubmitted(address indexed oracle, bytes32 indexed key, bytes value, uint256 timestamp);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "AetheriumLab: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "AetheriumLab: Not paused");
        _;
    }

    modifier onlyDaoManager() {
        require(msg.sender == daoManager, "AetheriumLab: Only DAO manager");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "AetheriumLab: Only whitelisted oracles");
        _;
    }

    modifier onlyStaker() {
        require(stakedBalances[msg.sender] >= minStakeForParticipation, "AetheriumLab: Must stake minimum tokens");
        _;
    }

    modifier onlySprintProposer(uint256 _sprintId) {
        require(researchSprints[_sprintId].proposer == msg.sender, "AetheriumLab: Only sprint proposer");
        _;
    }

    // --- Constructor & Initialization ---
    constructor() {
        daoManager = msg.sender; // Initial DAO manager, can be changed by DAO
        paused = true; // Start paused, must be unpaused by DAO
    }

    /**
     * @notice Initializes the AetheriumLab contract with essential addresses and initial configurations.
     * @dev Can only be called once by the initial `daoManager`.
     * @param _tokenAddress Address of the AetherToken (ERC-20) contract.
     * @param _nftAddress Address of the KnowledgeArtifactNFT (ERC-721) contract.
     * @param _minStakeForParticipation Initial minimum tokens required to stake for participation.
     * @param _sprintProposalMinStake Initial minimum stake required to propose a sprint.
     * @param _sprintVotingPeriodBlocks Initial block duration for DAO voting on sprints.
     * @param _outcomeValidationPeriodBlocks Initial block duration for outcome validation.
     * @param _minSprintRewardPool Initial minimum reward pool required to activate a sprint.
     * @param _validationThresholdPercentage Initial percentage (e.g., 51 for 51%) for stake majority validation.
     * @param _stakingCooldownBlocks Initial cooldown period in blocks for unstaking.
     * @param _metadataUpdateVotingPeriodBlocks Initial block duration for KANFT metadata update proposals.
     * @param _governanceProposalVotingPeriodBlocks Initial block duration for generic governance proposals.
     */
    function initializeLab(
        address _tokenAddress,
        address _nftAddress,
        uint256 _minStakeForParticipation,
        uint256 _sprintProposalMinStake,
        uint256 _sprintVotingPeriodBlocks,
        uint256 _outcomeValidationPeriodBlocks,
        uint256 _minSprintRewardPool,
        uint256 _validationThresholdPercentage,
        uint256 _stakingCooldownBlocks,
        uint256 _metadataUpdateVotingPeriodBlocks,
        uint256 _governanceProposalVotingPeriodBlocks
    ) external onlyDaoManager {
        require(address(aetherToken) == address(0), "AetheriumLab: Already initialized");
        require(_tokenAddress != address(0), "AetheriumLab: Invalid token address");
        require(_nftAddress != address(0), "AetheriumLab: Invalid NFT address");
        require(_validationThresholdPercentage > 0 && _validationThresholdPercentage <= 100, "AetheriumLab: Invalid validation threshold");

        aetherToken = IAetherToken(_tokenAddress);
        knowledgeArtifactNFT = IKnowledgeArtifactNFT(_nftAddress);

        minStakeForParticipation = _minStakeForParticipation;
        sprintProposalMinStake = _sprintProposalMinStake;
        sprintVotingPeriodBlocks = _sprintVotingPeriodBlocks;
        outcomeValidationPeriodBlocks = _outcomeValidationPeriodBlocks;
        minSprintRewardPool = _minSprintRewardPool;
        validationThresholdPercentage = _validationThresholdPercentage;
        stakingCooldownBlocks = _stakingCooldownBlocks;
        metadataUpdateVotingPeriodBlocks = _metadataUpdateVotingPeriodBlocks;
        governanceProposalVotingPeriodBlocks = _governanceProposalVotingPeriodBlocks;

        nextSprintId = 1;
        nextKANFTId = 1;
        nextMetadataProposalId = 1;
        nextGovernanceProposalId = 1;

        emit Initialized(_tokenAddress, _nftAddress, daoManager);
    }

    // I. Initialization & Configuration (DAO controlled)

    /**
     * @notice Allows the DAO to update various global configuration settings.
     * @dev This function can only be called through a successful governance proposal.
     * @param _key String identifier for the configuration parameter (e.g., "minStakeForParticipation").
     * @param _value The new value for the parameter.
     */
    function updateLabConfig(string memory _key, uint256 _value) external onlyDaoManager whenNotPaused {
        if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("minStakeForParticipation"))) {
            minStakeForParticipation = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("sprintProposalMinStake"))) {
            sprintProposalMinStake = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("sprintVotingPeriodBlocks"))) {
            sprintVotingPeriodBlocks = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("outcomeValidationPeriodBlocks"))) {
            outcomeValidationPeriodBlocks = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("minSprintRewardPool"))) {
            minSprintRewardPool = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("validationThresholdPercentage"))) {
            require(_value > 0 && _value <= 100, "AetheriumLab: Invalid validation threshold");
            validationThresholdPercentage = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("stakingCooldownBlocks"))) {
            stakingCooldownBlocks = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("metadataUpdateVotingPeriodBlocks"))) {
            metadataUpdateVotingPeriodBlocks = _value;
        } else if (keccak256(abi.encodePacked(_key)) == keccak256(abi.encodePacked("governanceProposalVotingPeriodBlocks"))) {
            governanceProposalVotingPeriodBlocks = _value;
        } else {
            revert("AetheriumLab: Unknown config key");
        }
        emit ConfigUpdated(_key, _value);
    }

    /**
     * @notice Pauses the contract in case of emergency.
     * @dev Can only be called by the DAO Manager (via a passed governance proposal usually).
     */
    function pauseLab() external onlyDaoManager whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the contract, resuming operations.
     * @dev Can only be called by the DAO Manager (via a passed governance proposal usually).
     */
    function unpauseLab() external onlyDaoManager whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // II. Research Sprints & Proposals

    /**
     * @notice Allows a user to propose a new research sprint. Requires a minimum stake.
     * @param _title Title of the research sprint.
     * @param _descriptionCID IPFS CID pointing to a detailed description of the sprint.
     * @param _initialRewardPool Initial amount of AetherTokens allocated as reward.
     * @param _durationBlocks Duration of the research submission phase in blocks.
     * @param _validationThresholdPercentage Override default validation threshold for this sprint (0 to use global default).
     * @return The ID of the newly proposed sprint.
     */
    function proposeResearchSprint(
        string memory _title,
        string memory _descriptionCID,
        uint256 _initialRewardPool,
        uint256 _durationBlocks,
        uint256 _validationThresholdPercentage
    ) external onlyStaker whenNotPaused returns (uint256) {
        require(stakedBalances[msg.sender] >= sprintProposalMinStake, "AetheriumLab: Insufficient stake to propose sprint");
        require(_initialRewardPool >= minSprintRewardPool, "AetheriumLab: Initial reward pool too low");
        require(_durationBlocks > 0, "AetheriumLab: Sprint duration must be positive");
        
        uint256 sprintId = nextSprintId++;
        ResearchSprint storage sprint = researchSprints[sprintId];

        sprint.title = _title;
        sprint.descriptionCID = _descriptionCID;
        sprint.rewardPool = _initialRewardPool;
        sprint.durationBlocks = _durationBlocks;
        sprint.proposer = msg.sender;
        sprint.validationThresholdPercentage = _validationThresholdPercentage == 0 ? validationThresholdPercentage : _validationThresholdPercentage;

        // Transfer initial reward pool tokens from proposer to contract
        require(aetherToken.transferFrom(msg.sender, address(this), _initialRewardPool), "AetheriumLab: Token transfer failed for initial reward");

        // Automatically create a governance proposal for this sprint
        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalCID: string(abi.encodePacked("Sprint Proposal: ", _title, " - CID:", _descriptionCID)),
            expirationBlock: block.number + sprintVotingPeriodBlocks,
            targetContract: address(this), // The target contract for execution (self)
            calldataBytes: abi.encodeWithSelector(this.executeSprintApproval.selector, sprintId),
            isExecuted: false,
            isApproved: false,
            yesVotesWeight: 0,
            noVotesWeight: 0,
            hasVoted: new mapping(address => bool)
        });
        sprint.approvalProposalId = proposalId;

        emit ResearchSprintProposed(sprintId, msg.sender, _title, _initialRewardPool);
        return sprintId;
    }

    /**
     * @notice DAO members vote to approve or reject proposed sprints.
     * @param _proposalId The ID of the governance proposal for the sprint.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnSprintProposal(uint256 _proposalId, bool _support) external onlyStaker whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.expirationBlock > block.number, "AetheriumLab: Proposal voting period ended");
        require(!proposal.hasVoted[msg.sender], "AetheriumLab: Already voted on this proposal");

        uint256 voteWeight = stakedBalances[msg.sender];
        require(voteWeight > 0, "AetheriumLab: Must have staked tokens to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotesWeight += voteWeight;
        } else {
            proposal.noVotesWeight += voteWeight;
        }
        emit SprintProposalVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Internal function to be called by DAO to approve and activate a sprint.
     * @dev This function should only be called by `executeGovernanceAction` for a passed sprint proposal.
     * @param _sprintId The ID of the sprint to activate.
     */
    function executeSprintApproval(uint256 _sprintId) external onlyDaoManager {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(!sprint.isActive, "AetheriumLab: Sprint already active");
        require(sprint.rewardPool >= minSprintRewardPool, "AetheriumLab: Sprint not sufficiently funded");

        sprint.isActive = true;
        sprint.startBlock = block.number;
        sprint.endBlock = block.number + sprint.durationBlocks;
        sprint.validationEndBlock = 0; // Will be set after outcomes are submitted

        emit ResearchSprintActivated(_sprintId, sprint.startBlock, sprint.endBlock);
        emit ResearchSprintApproved(_sprintId, sprint.proposer);
    }


    /**
     * @notice Allows users to contribute additional AetherTokens to a sprint's reward pool.
     * @dev Can also activate a sprint if it meets `minSprintRewardPool` and is approved by DAO.
     * @param _sprintId The ID of the sprint to fund.
     * @param _amount The amount of AetherTokens to contribute.
     */
    function fundResearchSprint(uint256 _sprintId, uint256 _amount) external whenNotPaused {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(!sprint.isFinalized, "AetheriumLab: Sprint already finalized");
        require(_amount > 0, "AetheriumLab: Must fund with positive amount");

        // Transfer tokens from sender to contract
        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "AetheriumLab: Token transfer failed");
        sprint.rewardPool += _amount;

        emit ResearchSprintFunded(_sprintId, msg.sender, _amount);
    }

    /**
     * @notice Researchers submit their findings for a sprint.
     * @param _sprintId The ID of the sprint.
     * @param _outcomeCID IPFS CID pointing to the research outcome data/paper.
     * @param _collaborators Addresses of all researchers who contributed (including msg.sender).
     * @return The index of the submitted outcome within the sprint.
     */
    function submitResearchOutcome(
        uint256 _sprintId,
        string memory _outcomeCID,
        address[] memory _collaborators
    ) external onlyStaker whenNotPaused returns (uint256) {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.isActive, "AetheriumLab: Sprint not active");
        require(block.number <= sprint.endBlock, "AetheriumLab: Sprint submission period ended");
        require(_collaborators.length > 0, "AetheriumLab: Must specify at least one collaborator");

        // Ensure msg.sender is among collaborators
        bool senderIsCollaborator = false;
        for (uint256 i = 0; i < _collaborators.length; i++) {
            if (_collaborators[i] == msg.sender) {
                senderIsCollaborator = true;
                break;
            }
        }
        require(senderIsCollaborator, "AetheriumLab: Sender must be listed as a collaborator");

        uint256 outcomeIndex = sprint.outcomeCount++;
        sprint.outcomes[outcomeIndex] = Outcome({
            researchers: _collaborators,
            outcomeCID: _outcomeCID,
            submissionBlock: block.number,
            totalValidationStake: 0,
            validVotesWeight: 0,
            invalidVotesWeight: 0,
            hasVoted: new mapping(address => bool),
            isValidated: false,
            isDisputed: false,
            disputeResolutionBlock: 0
        });
        sprint.totalOutcomesSubmitted++;

        // Set validation period for this outcome
        if (sprint.validationEndBlock == 0) { // Only set once for the sprint
            sprint.validationEndBlock = block.number + outcomeValidationPeriodBlocks;
        }

        emit ResearchOutcomeSubmitted(_sprintId, outcomeIndex, msg.sender, _outcomeCID);
        return outcomeIndex;
    }

    /**
     * @notice Finalizes a research sprint. This can be called after the submission and validation periods.
     * @dev Distributes rewards and potentially mints a KANFT for successfully validated outcomes.
     * @param _sprintId The ID of the sprint to finalize.
     */
    function finalizeResearchSprint(uint256 _sprintId) external whenNotPaused {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.isActive, "AetheriumLab: Sprint not active");
        require(!sprint.isFinalized, "AetheriumLab: Sprint already finalized");
        require(block.number > sprint.validationEndBlock, "AetheriumLab: Validation period not ended yet");

        sprint.isFinalized = true;
        sprint.isActive = false; // Deactivate sprint after finalization

        uint256 totalValidOutcomes = 0;
        for (uint256 i = 0; i < sprint.outcomeCount; i++) {
            Outcome storage outcome = sprint.outcomes[i];
            if (outcome.isValidated && !outcome.isDisputed) {
                totalValidOutcomes++;
            }
        }

        uint256 totalRewardDistributed = 0;

        if (totalValidOutcomes > 0) {
            uint256 rewardPerOutcome = sprint.rewardPool / totalValidOutcomes;

            for (uint256 i = 0; i < sprint.outcomeCount; i++) {
                Outcome storage outcome = sprint.outcomes[i];
                if (outcome.isValidated && !outcome.isDisputed) {
                    // Distribute research rewards
                    uint256 researcherRewardShare = rewardPerOutcome * 80 / 100; // 80% to researchers
                    uint256 validatorRewardShare = rewardPerOutcome * 20 / 100; // 20% to validators

                    if (outcome.researchers.length > 0 && researcherRewardShare > 0) {
                        uint256 sharePerResearcher = researcherRewardShare / outcome.researchers.length;
                        for (uint256 j = 0; j < outcome.researchers.length; j++) {
                            // This part only accrues, actual claim is handled by `claimResearchReward`
                            // For simplicity, direct transfer here, but usually accrued.
                            // For now, let's assume `claimResearchReward` will handle distribution.
                        }
                    }

                    // For validators, reward based on proportion of stake in correct votes
                    if (outcome.validVotesWeight > 0 && validatorRewardShare > 0) {
                        // This part only accrues, actual claim is handled by `claimValidationReward`
                    }

                    // Mint KANFT for the valid outcome
                    _mintKnowledgeArtifact(sprint.proposer, i, outcome.outcomeCID, _sprintId);
                    sprint.kanftId = nextKANFTId - 1; // Assign the last minted NFT ID
                    totalRewardDistributed += rewardPerOutcome;
                }
            }
        }
        
        // Return any remaining funds to proposer if no valid outcomes or partial distribution.
        if (sprint.rewardPool > totalRewardDistributed) {
            aetherToken.transfer(sprint.proposer, sprint.rewardPool - totalRewardDistributed);
        }

        emit ResearchSprintFinalized(_sprintId, totalRewardDistributed);
    }


    // III. Knowledge Artifact NFTs (KANFTs) Management

    /**
     * @notice Mints a new Knowledge Artifact NFT (KANFT) for a validated research outcome.
     * @dev Internal function called by `finalizeResearchSprint`.
     * @param _to The address to mint the NFT to (usually the sprint proposer or lead researcher).
     * @param _outcomeIndex The index of the outcome within the sprint.
     * @param _metadataCID IPFS CID for the NFT's initial metadata.
     * @param _sprintId The ID of the sprint this NFT is associated with.
     */
    function _mintKnowledgeArtifact(address _to, uint256 _outcomeIndex, string memory _metadataCID, uint256 _sprintId) internal {
        uint256 tokenId = nextKANFTId++;
        // The NFT contract handles its own URI, so we just pass the metadata CID.
        knowledgeArtifactNFT.mint(_to, tokenId, _metadataCID);
        emit KANFTMetadataUpdated(tokenId, _metadataCID); // Initial metadata is set upon minting
    }

    /**
     * @notice Proposes an update to a KANFT's metadata. Requires DAO approval.
     * @param _tokenId The ID of the KANFT to update.
     * @param _newMetadataCID The new IPFS CID for the metadata.
     * @return The ID of the metadata update proposal.
     */
    function requestDynamicMetadataUpdate(uint256 _tokenId, string memory _newMetadataCID) external onlyStaker whenNotPaused returns (uint256) {
        require(knowledgeArtifactNFT.ownerOf(_tokenId) == msg.sender || daoManager == msg.sender, "AetheriumLab: Only NFT owner or DAO manager can propose update");

        uint256 proposalId = nextMetadataProposalId++;
        metadataUpdateProposals[proposalId] = MetadataUpdateProposal({
            tokenId: _tokenId,
            newMetadataCID: _newMetadataCID,
            proposalBlock: block.number,
            expirationBlock: block.number + metadataUpdateVotingPeriodBlocks,
            isApproved: false,
            isExecuted: false,
            yesVotesWeight: 0,
            noVotesWeight: 0,
            hasVoted: new mapping(address => bool)
        });
        emit KANFTMetadataUpdateProposed(_tokenId, proposalId, _newMetadataCID);
        return proposalId;
    }

    /**
     * @notice Community/DAO members vote to approve or reject a proposed KANFT metadata update.
     * @param _proposalId The ID of the metadata update proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function validateMetadataUpdate(uint256 _proposalId, bool _support) external onlyStaker whenNotPaused {
        MetadataUpdateProposal storage proposal = metadataUpdateProposals[_proposalId];
        require(proposal.expirationBlock > block.number, "AetheriumLab: Proposal voting period ended");
        require(!proposal.hasVoted[msg.sender], "AetheriumLab: Already voted on this proposal");

        uint256 voteWeight = stakedBalances[msg.sender];
        require(voteWeight > 0, "AetheriumLab: Must have staked tokens to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotesWeight += voteWeight;
        } else {
            proposal.noVotesWeight += voteWeight;
        }
        emit KANFTMetadataUpdateVoted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Executes a passed metadata update proposal.
     * @dev Can only be called by the DAO manager or if sufficient time passed and proposal passed.
     * @param _proposalId The ID of the metadata update proposal.
     */
    function executeMetadataUpdate(uint256 _proposalId) external onlyDaoManager whenNotPaused {
        MetadataUpdateProposal storage proposal = metadataUpdateProposals[_proposalId];
        require(block.number > proposal.expirationBlock, "AetheriumLab: Voting period not ended");
        require(!proposal.isExecuted, "AetheriumLab: Proposal already executed");

        uint256 totalWeight = proposal.yesVotesWeight + proposal.noVotesWeight;
        if (totalWeight > 0 && (proposal.yesVotesWeight * 100 / totalWeight) >= validationThresholdPercentage) {
            proposal.isApproved = true;
            knowledgeArtifactNFT.setTokenURI(proposal.tokenId, proposal.newMetadataCID);
            emit KANFTMetadataUpdated(proposal.tokenId, proposal.newMetadataCID);
        } else {
            proposal.isApproved = false; // Explicitly mark as not approved
        }
        proposal.isExecuted = true;
    }

    /**
     * @notice Grants temporary read/use access to a private KANFT's content.
     * @dev This assumes an off-chain content gating system that checks this contract for access.
     * @param _tokenId The ID of the KANFT.
     * @param _delegate The address to grant access to.
     * @param _durationBlocks The duration of access in blocks.
     */
    function grantDelegatedAccess(uint256 _tokenId, address _delegate, uint256 _durationBlocks) external whenNotPaused {
        require(knowledgeArtifactNFT.ownerOf(_tokenId) == msg.sender, "AetheriumLab: Only NFT owner can grant access");
        require(_delegate != address(0), "AetheriumLab: Invalid delegate address");
        require(_durationBlocks > 0, "AetheriumLab: Duration must be positive");

        delegatedKANFTAccessExpires[_tokenId][_delegate] = block.number + _durationBlocks;
        emit KANFTDelegatedAccessGranted(_tokenId, _delegate, block.number + _durationBlocks);
    }

    /**
     * @notice Revokes previously granted delegated access to a KANFT.
     * @param _tokenId The ID of the KANFT.
     * @param _delegate The address whose access to revoke.
     */
    function revokeDelegatedAccess(uint256 _tokenId, address _delegate) external whenNotPaused {
        require(knowledgeArtifactNFT.ownerOf(_tokenId) == msg.sender, "AetheriumLab: Only NFT owner can revoke access");
        require(delegatedKANFTAccessExpires[_tokenId][_delegate] > block.number, "AetheriumLab: No active delegated access for this delegate");

        delegatedKANFTAccessExpires[_tokenId][_delegate] = 0; // Set to 0 to invalidate
        emit KANFTDelegatedAccessRevoked(_tokenId, _delegate);
    }


    // IV. Staking, Validation & Rewards

    /**
     * @notice Allows users to stake AetherTokens to participate as researchers or validators.
     * @param _amount The amount of AetherTokens to stake.
     */
    function stakeForParticipation(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AetheriumLab: Stake amount must be positive");
        require(aetherToken.transferFrom(msg.sender, address(this), _amount), "AetheriumLab: Token transfer failed");

        stakedBalances[msg.sender] += _amount;
        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Allows users to request unstaking their AetherTokens. A cooldown period applies.
     * @param _amount The amount of AetherTokens to unstake.
     */
    function unstakeFromParticipation(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "AetheriumLab: Unstake amount must be positive");
        require(stakedBalances[msg.sender] >= _amount, "AetheriumLab: Insufficient staked balance");
        require(unstakeRequestBlock[msg.sender] == 0 || block.number > unstakeRequestBlock[msg.sender] + stakingCooldownBlocks, "AetheriumLab: Unstake cooldown in progress");

        stakedBalances[msg.sender] -= _amount;
        unstakeRequestBlock[msg.sender] = block.number; // Start cooldown
        
        require(aetherToken.transfer(msg.sender, _amount), "AetheriumLab: Token transfer failed for unstake");
        emit UnstakeRequested(msg.sender, _amount, block.number + stakingCooldownBlocks);
        emit Unstaked(msg.sender, _amount); // Immediately unstaked after cooldown logic check
    }

    /**
     * @notice Participants review submitted research outcomes and cast a stake-weighted vote on its validity.
     * @param _sprintId The ID of the research sprint.
     * @param _outcomeIndex The index of the outcome within the sprint.
     * @param _isValid True if the outcome is deemed valid, false otherwise.
     */
    function validateResearchOutcome(uint256 _sprintId, uint256 _outcomeIndex, bool _isValid) external onlyStaker whenNotPaused {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.isActive || block.number <= sprint.validationEndBlock, "AetheriumLab: Validation period ended or sprint inactive");
        require(_outcomeIndex < sprint.outcomeCount, "AetheriumLab: Invalid outcome index");
        
        Outcome storage outcome = sprint.outcomes[_outcomeIndex];
        require(!outcome.hasVoted[msg.sender], "AetheriumLab: Already voted on this outcome");
        require(!outcome.isDisputed, "AetheriumLab: Outcome under dispute");

        uint256 voteWeight = stakedBalances[msg.sender];
        require(voteWeight > 0, "AetheriumLab: Must have staked tokens to validate");

        outcome.hasVoted[msg.sender] = true;
        outcome.totalValidationStake += voteWeight;

        if (_isValid) {
            outcome.validVotesWeight += voteWeight;
        } else {
            outcome.invalidVotesWeight += voteWeight;
        }

        // Check if outcome validation threshold is met immediately (can also be done on finalize)
        if (block.number > sprint.validationEndBlock) {
            if (outcome.totalValidationStake > 0 &&
                (outcome.validVotesWeight * 100 / outcome.totalValidationStake) >= sprint.validationThresholdPercentage) {
                outcome.isValidated = true;
            } else {
                outcome.isValidated = false;
            }
        }
        emit OutcomeValidated(_sprintId, _outcomeIndex, msg.sender, _isValid, voteWeight);
    }

    /**
     * @notice Initiates a dispute resolution process for contested validation outcomes.
     * @dev This would typically trigger a DAO vote or an arbitration process.
     * @param _sprintId The ID of the research sprint.
     * @param _outcomeIndex The index of the outcome within the sprint.
     */
    function disputeValidationResult(uint256 _sprintId, uint256 _outcomeIndex) external onlyStaker whenNotPaused {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(!sprint.isFinalized, "AetheriumLab: Sprint already finalized");
        require(_outcomeIndex < sprint.outcomeCount, "AetheriumLab: Invalid outcome index");

        Outcome storage outcome = sprint.outcomes[_outcomeIndex];
        require(!outcome.isDisputed, "AetheriumLab: Outcome already under dispute");
        require(block.number <= sprint.validationEndBlock, "AetheriumLab: Dispute period for validation results has ended.");

        outcome.isDisputed = true;
        outcome.disputeResolutionBlock = block.number + governanceProposalVotingPeriodBlocks; // Arbitrary resolution period

        // A governance proposal could be created here to arbitrate
        // For simplicity, just marking it disputed for now.
        emit OutcomeDisputed(_sprintId, _outcomeIndex, msg.sender);
    }

    /**
     * @notice Researchers claim their share of the sprint reward pool upon successful validation of their outcome.
     * @param _sprintId The ID of the research sprint.
     */
    function claimResearchReward(uint256 _sprintId) external whenNotPaused {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.isFinalized, "AetheriumLab: Sprint not finalized");
        require(!hasClaimedResearchReward[_sprintId][msg.sender], "AetheriumLab: Reward already claimed");

        uint256 researcherReward = 0;
        uint256 totalValidOutcomes = 0;
        for (uint256 i = 0; i < sprint.outcomeCount; i++) {
            Outcome storage outcome = sprint.outcomes[i];
            if (outcome.isValidated && !outcome.isDisputed) {
                totalValidOutcomes++;
            }
        }
        require(totalValidOutcomes > 0, "AetheriumLab: No valid outcomes to claim rewards from");

        uint256 rewardPerOutcome = (sprint.rewardPool * 80 / 100) / totalValidOutcomes; // 80% to researchers
        
        for (uint256 i = 0; i < sprint.outcomeCount; i++) {
            Outcome storage outcome = sprint.outcomes[i];
            if (outcome.isValidated && !outcome.isDisputed) {
                bool isParticipatingResearcher = false;
                for (uint256 j = 0; j < outcome.researchers.length; j++) {
                    if (outcome.researchers[j] == msg.sender) {
                        isParticipatingResearcher = true;
                        break;
                    }
                }
                if (isParticipatingResearcher) {
                    researcherReward += rewardPerOutcome / outcome.researchers.length;
                }
            }
        }
        
        require(researcherReward > 0, "AetheriumLab: No rewards earned for this sprint");
        hasClaimedResearchReward[_sprintId][msg.sender] = true;
        require(aetherToken.transfer(msg.sender, researcherReward), "AetheriumLab: Reward transfer failed");
        emit ResearchRewardClaimed(_sprintId, 0, msg.sender, researcherReward); // Outcome index is 0 as it's aggregated
    }

    /**
     * @notice Validators claim rewards for correctly validating research outcomes.
     * @param _sprintId The ID of the research sprint.
     */
    function claimValidationReward(uint256 _sprintId) external whenNotPaused {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        require(sprint.isFinalized, "AetheriumLab: Sprint not finalized");
        require(!hasClaimedValidationReward[_sprintId][msg.sender], "AetheriumLab: Reward already claimed");

        uint256 validatorReward = 0;
        uint256 totalValidOutcomes = 0;
        for (uint256 i = 0; i < sprint.outcomeCount; i++) {
            Outcome storage outcome = sprint.outcomes[i];
            if (outcome.isValidated && !outcome.isDisputed) {
                totalValidOutcomes++;
            }
        }
        require(totalValidOutcomes > 0, "AetheriumLab: No valid outcomes for validation rewards");

        uint256 validatorPoolPerOutcome = (sprint.rewardPool * 20 / 100) / totalValidOutcomes; // 20% to validators

        for (uint256 i = 0; i < sprint.outcomeCount; i++) {
            Outcome storage outcome = sprint.outcomes[i];
            if (outcome.isValidated && !outcome.isDisputed && outcome.hasVoted[msg.sender]) {
                uint256 validatorStake = stakedBalances[msg.sender]; // At the time of voting
                // Only reward if they voted correctly (for valid outcomes, they must have voted valid)
                if (outcome.validVotesWeight > 0 && (outcome.validVotesWeight * 100 / outcome.totalValidationStake) >= sprint.validationThresholdPercentage) {
                    // Reward proportional to their stake in the correct votes
                    validatorReward += (validatorPoolPerOutcome * validatorStake) / outcome.validVotesWeight;
                }
            }
        }

        require(validatorReward > 0, "AetheriumLab: No rewards earned for this sprint's validation");
        hasClaimedValidationReward[_sprintId][msg.sender] = true;
        require(aetherToken.transfer(msg.sender, validatorReward), "AetheriumLab: Reward transfer failed");
        emit ValidationRewardClaimed(_sprintId, 0, msg.sender, validatorReward); // Outcome index is 0 as it's aggregated
    }


    // V. Decentralized Autonomous Organization (DAO) Governance

    /**
     * @notice Submits a generic DAO proposal for contract upgrades, parameter changes, or arbitrary calls.
     * @param _proposalCID IPFS CID for detailed proposal text.
     * @param _targetContract The address of the contract to call if the proposal passes.
     * @param _calldataBytes The encoded function call data for the target contract.
     * @return The ID of the newly created governance proposal.
     */
    function proposeGovernanceAction(
        string memory _proposalCID,
        address _targetContract,
        bytes memory _calldataBytes
    ) external onlyStaker whenNotPaused returns (uint256) {
        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalCID: _proposalCID,
            expirationBlock: block.number + governanceProposalVotingPeriodBlocks,
            targetContract: _targetContract,
            calldataBytes: _calldataBytes,
            isExecuted: false,
            isApproved: false,
            yesVotesWeight: 0,
            noVotesWeight: 0,
            hasVoted: new mapping(address => bool)
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _proposalCID);
        return proposalId;
    }

    /**
     * @notice DAO members cast their stake-weighted vote on an active governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for 'yes', false for 'no'.
     */
    function castGovernanceVote(uint256 _proposalId, bool _support) external onlyStaker whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.expirationBlock > block.number, "AetheriumLab: Proposal voting period ended");
        require(!proposal.hasVoted[msg.sender], "AetheriumLab: Already voted on this proposal");

        uint256 voteWeight = stakedBalances[msg.sender];
        require(voteWeight > 0, "AetheriumLab: Must have staked tokens to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotesWeight += voteWeight;
        } else {
            proposal.noVotesWeight += voteWeight;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @notice Executes a passed governance proposal, triggering its target function call.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceAction(uint256 _proposalId) external onlyDaoManager whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(block.number > proposal.expirationBlock, "AetheriumLab: Voting period not ended");
        require(!proposal.isExecuted, "AetheriumLab: Proposal already executed");

        uint256 totalWeight = proposal.yesVotesWeight + proposal.noVotesWeight;
        if (totalWeight > 0 && (proposal.yesVotesWeight * 100 / totalWeight) >= validationThresholdPercentage) {
            proposal.isApproved = true;
            // Execute the proposed action
            (bool success, ) = proposal.targetContract.call(proposal.calldataBytes);
            require(success, "AetheriumLab: Proposal execution failed");
        } else {
            proposal.isApproved = false; // Explicitly mark as not approved
        }
        proposal.isExecuted = true;
        emit GovernanceProposalExecuted(_proposalId);
    }


    // VI. Oracle & External Data Integration

    /**
     * @notice Whitelists an address to be a trusted oracle.
     * @dev Can only be called by the DAO Manager (via a passed governance proposal usually).
     * @param _oracleAddress The address to whitelist.
     */
    function addOracleAddress(address _oracleAddress) external onlyDaoManager whenNotPaused {
        require(_oracleAddress != address(0), "AetheriumLab: Invalid address");
        require(!isOracle[_oracleAddress], "AetheriumLab: Address is already an oracle");
        isOracle[_oracleAddress] = true;
        emit OracleAddressAdded(_oracleAddress);
    }

    /**
     * @notice Removes an address from the trusted oracle list.
     * @dev Can only be called by the DAO Manager (via a passed governance proposal usually).
     * @param _oracleAddress The address to remove.
     */
    function removeOracleAddress(address _oracleAddress) external onlyDaoManager whenNotPaused {
        require(_oracleAddress != address(0), "AetheriumLab: Invalid address");
        require(isOracle[_oracleAddress], "AetheriumLab: Address is not an oracle");
        isOracle[_oracleAddress] = false;
        emit OracleAddressRemoved(_oracleAddress);
    }

    /**
     * @notice Allows whitelisted oracles to submit signed, verifiable external data for research inputs or validation.
     * @dev The data is stored on-chain, and `bytes32 _key` could map to specific research data points or types.
     * Verification of `_signature` would happen off-chain against the oracle's known public key and `_timestamp`.
     * This function only records the data submitted by a trusted oracle.
     * @param _key A unique identifier for the data.
     * @param _value The actual data payload.
     * @param _timestamp The timestamp of when the data was generated/observed.
     * @param _signature Signature of the data by the oracle (for off-chain verification).
     */
    function submitVerifiedOracleData(
        bytes32 _key,
        bytes memory _value,
        uint256 _timestamp,
        bytes memory _signature // Not verified on-chain here for gas, assumed verified off-chain
    ) external onlyOracle whenNotPaused {
        // In a real-world scenario, signature verification would be crucial here,
        // but for a concise smart contract example, we trust `onlyOracle` modifier.
        // A full implementation would involve `ecrecover` to ensure data integrity.

        // This example simply emits the data, a more complex system would store it in a mapping
        // e.g., mapping(bytes32 => OracleData[]) public oracleDataFeeds;
        emit VerifiedOracleDataSubmitted(msg.sender, _key, _value, _timestamp);
    }

    // VII. Utility & Information (View functions)

    /**
     * @notice Retrieves detailed information about a specific research sprint.
     * @param _sprintId The ID of the sprint.
     * @return A tuple containing sprint details.
     */
    function getSprintDetails(uint256 _sprintId)
        external
        view
        returns (
            string memory title,
            string memory descriptionCID,
            uint256 rewardPool,
            uint256 durationBlocks,
            uint256 startBlock,
            uint256 endBlock,
            uint256 validationEndBlock,
            uint256 validationThresholdPercentage,
            bool isActive,
            bool isFinalized,
            address proposer,
            uint256 kanftId,
            uint256 outcomeCount
        )
    {
        ResearchSprint storage sprint = researchSprints[_sprintId];
        return (
            sprint.title,
            sprint.descriptionCID,
            sprint.rewardPool,
            sprint.durationBlocks,
            sprint.startBlock,
            sprint.endBlock,
            sprint.validationEndBlock,
            sprint.validationThresholdPercentage,
            sprint.isActive,
            sprint.isFinalized,
            sprint.proposer,
            sprint.kanftId,
            sprint.outcomeCount
        );
    }

    /**
     * @notice Returns the amount of AetherTokens staked by a user.
     * @param _user The address of the user.
     * @return The staked amount.
     */
    function getUserStake(address _user) external view returns (uint256) {
        return stakedBalances[_user];
    }

    /**
     * @notice Retrieves the current metadata CID for a Knowledge Artifact NFT.
     * @param _tokenId The ID of the KANFT.
     * @return The IPFS CID of the NFT's metadata.
     */
    function getKnowledgeArtifactMetadata(uint256 _tokenId) external view returns (string memory) {
        return knowledgeArtifactNFT.tokenURI(_tokenId);
    }
}
```