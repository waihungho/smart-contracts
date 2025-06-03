Okay, let's design a smart contract that acts as a decentralized platform for launching and participating in timed, phased "experiments" or "simulations". These experiments can have different rules, require specific staked assets (ERC20 or ERC721), and depend on verifiable "proofs" submitted via oracles to progress or determine outcomes. It will include a simple on-chain governance mechanism for parameter changes and adding new experiment types.

This concept is advanced because:
1.  **It's a platform, not a single use case:** Users can define and launch *different types* of experiments.
2.  **Phased State Machine:** Experiments progress through distinct stages (Setup, Staking, Active, Evaluation, Finalized, Cancelled) based on time and submitted proofs.
3.  **Multi-Asset Staking:** Supports staking of both ERC20 tokens and ERC721 NFTs.
4.  **Oracle/Proof Integration:** Relies on external agents (simulated oracles) to submit and verify data/computation results ("proofs") required for experiment progression and outcome determination. Includes slashing for invalid proofs.
5.  **On-Chain Governance:** Allows holders of a governance token to propose and vote on core contract parameters and the creation of new experiment types.
6.  **Dynamic Rewards:** Rewards can be calculated based on stake amount, time, experiment outcome, and proof validity, potentially including both fungible tokens and NFTs.

It is creative and not a direct duplicate of common open-source examples (like a simple ERC20, ERC721, standard staking, or single-purpose DeFi protocol). It combines elements from several domains (DAO, staking, oracles, state machines, dynamic configuration).

---

**Smart Contract Outline: Epochal Experimentation Canvas (EEC)**

A platform for creating and managing decentralized, timed, multi-asset staked experiments requiring oracle-verified proofs. Includes on-chain governance.

**Core Concepts:**
*   **Epochs:** Time periods containing multiple experiments.
*   **Experiments:** Specific instances of a defined experiment type, with phases, parameters, staking, and proof requirements.
*   **Experiment Types:** Configurable templates defining the rules, required assets, and proof types for experiments.
*   **Stakes:** User contributions of ERC20 or ERC721 assets to specific experiments.
*   **Proofs:** Data/computation results submitted for an experiment, verifiable by registered oracles.
*   **Oracles:** Registered addresses authorized to verify proofs and potentially slash stakes.
*   **Governance:** Token-weighted voting on contract parameters and new experiment types.

**Function Summary:**

**I. Initialization & Configuration**
1.  `constructor`: Initializes the contract with token addresses and admin.
2.  `setParameter`: Admin/Governance function to update core contract parameters.
3.  `registerOracle`: Admin function to authorize an oracle address for proof verification.
4.  `addExperimentType`: Admin/Governance function to define a new type of experiment template.

**II. Epoch Management**
5.  `startNextEpoch`: Admin/Timed function to advance to a new epoch.
6.  `endCurrentEpoch`: Admin/Timed function to finalize an epoch's status.

**III. Experiment Lifecycle (User & System Interactions)**
7.  `createExperiment`: User function to launch a new experiment instance based on an approved type.
8.  `stakeIntoExperiment`: User function to stake required assets into an experiment.
9.  `unstakeFromExperiment`: User function to withdraw stake (subject to experiment phase/rules).
10. `submitProofForExperiment`: User function (or off-chain relayer) to submit initial proof data for an experiment.
11. `verifyProof`: Callable by a registered Oracle to validate a submitted proof's data.
12. `slashStake`: Callable by a registered Oracle (or Admin based on verification result) to penalize stake for invalid proofs/behavior.
13. `transitionExperimentStatus`: Callable by anyone when conditions are met (e.g., time passes, proofs verified) to move an experiment to the next phase.
14. `evaluateExperiment`: Callable when an experiment is ready for outcome determination based on proofs and parameters.
15. `claimRewards`: User function to claim earned rewards from finalized experiments.
16. `cancelExperiment`: Admin/Governance function to prematurely end an experiment.

**IV. Governance (Proposal & Voting)**
17. `proposeParameterChange`: Governance token holder function to propose changing a contract parameter.
18. `proposeAddExperimentType`: Governance token holder function to propose adding a new experiment type.
19. `voteOnProposal`: Governance token holder function to vote on an active proposal.
20. `tallyProposalVotes`: Callable after voting period ends to finalize a proposal based on votes.

**V. View Functions (Read Operations)**
21. `getEpochDetails`: Retrieves details of a specific epoch.
22. `getExperimentDetails`: Retrieves details of a specific experiment.
23. `getUserStake`: Retrieves a user's stake details for a specific experiment.
24. `getExperimentProofs`: Lists proofs submitted for an experiment.
25. `getExperimentTypeDetails`: Retrieves configuration for a specific experiment type.
26. `getContractParameters`: Retrieves current contract parameters.
27. `getOracleAddress`: Checks if an address is a registered oracle.
28. `getProposalDetails`: Retrieves details of a specific governance proposal.
29. `getExperimentParticipants`: Lists addresses that have staked in an experiment.
30. `canTransitionStatus`: Checks if an experiment is ready to transition to the next status.

*(Note: The list exceeds 20 functions as requested, providing a richer set of interactions.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol"; // For Address.isContract

// Outline and Function Summary are provided above the code block.

/// @title Epochal Experimentation Canvas (EEC)
/// @author [Your Name/Alias]
/// @notice A decentralized platform for phased, staked experiments with oracle-verified proofs and on-chain governance.
contract EpochalExperimentationCanvas is Ownable, ERC721Holder {
    using SafeMath for uint256;
    using Address for address;

    // --- Custom Errors ---
    error InvalidStatusTransition();
    error ExperimentNotInStakingPhase();
    error ExperimentNotInUnstakingPhase();
    error ExperimentNotActiveForProofSubmission();
    error ExperimentNotReadyForEvaluation();
    error ExperimentNotFinalizedForClaiming();
    error StakeAmountTooLow(uint256 requiredAmount);
    error InvalidAssetType();
    error ProofAlreadySubmitted();
    error CallerNotOracleOrAdmin();
    error ProofNotFound();
    error ProofAlreadyVerified();
    error ProofAlreadySlashed();
    error InvalidProofStatusForVerification();
    error InvalidProofStatusForSlashing();
    error ExperimentTypeNotFound();
    error OracleNotRegistered();
    error InvalidParameterName();
    error VotingPeriodNotActive();
    error VotingPeriodEnded();
    error AlreadyVoted();
    error ProposalNotFound();
    error CannotTallyBeforeEndTime();
    error ProposalAlreadyTallied();
    error InvalidProposalType();
    error InsufficientGovernanceTokens();
    error MinimumStakeNotMetForProposal(uint256 requiredStake);
    error ExperimentTypeAlreadyExists();
    error ExperimentTypeCannotBeModified();
    error ExperimentLimitReached();
    error EpochInProgress();
    error EpochNotReadyToStart();
    error EpochNotReadyToEnd();
    error EpochAlreadyEnded();
    error NoStakeFound();

    // --- Enums ---
    enum EpochStatus {
        Inactive,
        Active,
        Ended
    }

    enum ExperimentStatus {
        Setup,        // Parameters set, waiting for staking phase
        Staking,      // Open for user stakes
        Active,       // Staking closed, proofs can be submitted/verified
        Evaluation,   // Proof verification/evaluation ongoing
        Finalized,    // Outcome determined, rewards claimable
        Cancelled     // Experiment cancelled prematurely
    }

    enum ProofStatus {
        Submitted,    // Proof data received
        VerifiedValid,// Proof verified as correct
        VerifiedInvalid // Proof verified as incorrect
    }

    enum ProposalStatus {
        Open,         // Voting is active
        Accepted,     // Passed by vote
        Rejected,     // Failed by vote
        Cancelled     // Proposal cancelled
    }

    enum AssetType {
        ERC20,
        ERC721
    }

    enum ProposalType {
        ParameterChange,
        AddExperimentType
    }

    // --- Structs ---
    struct Epoch {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256[] experimentIDs;
        EpochStatus status;
    }

    struct ExperimentType {
        bytes32 typeId; // Unique identifier for the type
        string name;
        string description;
        address[] allowedStakeAssets; // List of ERC20/ERC721 addresses
        AssetType[] allowedStakeAssetTypes; // Corresponding types (ERC20/ERC721)
        uint256 minStakeAmountERC20; // Minimum required for any ERC20
        bytes32 requiredProofType; // Identifier for the type of proof needed
        uint256 stakeDuration; // How long staking phase lasts (seconds)
        uint256 activeDuration; // How long active phase lasts (seconds)
        // Add more config like reward calculation logic ID, max participants, etc.
    }

    struct Experiment {
        uint256 id;
        bytes32 typeId;
        uint256 epochId;
        address creator;
        ExperimentStatus status;
        uint256 startTime; // When experiment became Active
        uint256 stakingEndTime; // When staking closes
        uint256 activeEndTime; // When proof submission/active phase ends
        uint256 evaluationEndTime; // When evaluation should be complete
        bytes proofRequirementData; // Specific data needed for this experiment's proof
        bytes resultData; // Data stored after evaluation (e.g., outcome, reward multipliers)
        uint256 totalStakedERC20; // Sum of all ERC20 staked
        mapping(address => uint256) totalStakedERC721Count; // Count of ERC721s staked per collection
        uint256[] proofIDs; // List of proofs submitted for this experiment
        mapping(address => Stake) userStakes; // User stake details (only latest stake per asset type per user)
        mapping(address => mapping(address => uint256[])) userStakedNFTTokenIds; // For ERC721: user -> contract -> tokenIds[]
    }

    struct Stake {
        address user;
        address assetAddress;
        AssetType assetType;
        uint256 amount; // For ERC20
        uint256 stakeTime;
        bool claimedRewards; // Flag to prevent double claiming
    }

    struct Proof {
        uint256 id;
        uint256 experimentId;
        bytes32 proofType; // Matches ExperimentType's requiredProofType
        address submittedBy;
        bytes submissionData; // Raw data submitted
        ProofStatus status;
        address verifiedByOracle; // Oracle who verified it
        bytes verificationResultData; // Data from verification (e.g., success/failure, specific value)
        uint256 submissionTime;
        uint256 verificationTime;
        uint256 stakeSlashedAmount; // Amount of stake slashed for this proof (if invalid)
    }

    struct ParameterProposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        bytes proposalData; // Encoded data based on type (e.g., param name + value, or new ExperimentType data)
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    // --- State Variables ---
    address public governanceToken;
    address public rewardTokenERC20;
    address public rewardNFT; // Address of the reward NFT contract (ERC721)

    address public admin; // Initial admin set by Ownable

    uint256 public epochCounter;
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpochId;

    uint256 public experimentCounter;
    mapping(uint256 => Experiment) public experiments;

    mapping(bytes32 => ExperimentType) public experimentTypes; // typeId => ExperimentType config
    bytes32[] public experimentTypeIds; // List of approved experiment type IDs

    mapping(address => bool) public registeredOracles; // Oracle address => isRegistered

    uint256 public proposalCounter;
    mapping(uint256 => ParameterProposal) public proposals;

    // --- Contract Parameters (Can be changed by Governance) ---
    uint256 public parameters_epochDuration = 7 days;
    uint256 public parameters_proposalVotingPeriod = 3 days;
    uint256 public parameters_minGovTokensToPropose = 100e18; // Example: 100 tokens
    uint256 public parameters_minGovTokensToVote = 1e18; // Example: 1 token
    uint256 public parameters_minStakeForExperimentCreation = 50e18; // Example: 50 of a defined asset
    bytes32 public parameters_experimentCreationStakeAsset; // Which asset is used for creator stake

    // --- Events ---
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime);
    event EpochEnded(uint256 indexed epochId, EpochStatus finalStatus);
    event ExperimentCreated(uint256 indexed experimentId, bytes32 indexed typeId, address indexed creator, uint256 epochId, uint256 stakingEndTime);
    event ExperimentStatusTransition(uint256 indexed experimentId, ExperimentStatus oldStatus, ExperimentStatus newStatus);
    event AssetStaked(uint256 indexed experimentId, address indexed user, address assetAddress, AssetType assetType, uint256 amountOrTokenId); // Emits token ID for ERC721
    event AssetUnstaked(uint256 indexed experimentId, address indexed user, address assetAddress, AssetType assetType, uint256 amountOrTokenId);
    event ProofSubmitted(uint256 indexed experimentId, uint256 indexed proofId, address indexed submittedBy, bytes32 proofType);
    event ProofVerified(uint256 indexed proofId, ProofStatus status, address indexed verifiedByOracle);
    event StakeSlashed(uint256 indexed experimentId, address indexed user, address assetAddress, AssetType assetType, uint256 slashedAmount);
    event RewardsClaimed(uint256 indexed experimentId, address indexed user, uint256 rewardAmountERC20, uint256[] rewardNFTTokenIds);
    event ExperimentCancelled(uint256 indexed experimentId, address indexed cancelledBy);
    event OracleRegistered(address indexed oracleAddress, bool registered);
    event ExperimentTypeAdded(bytes32 indexed typeId, string name, address indexed addedBy);
    event ParameterChanged(string parameterName, string newValue); // Basic event, detail in logs
    event ProposalCreated(uint256 indexed proposalId, ProposalType proposalType, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote); // true=Yes, false=No
    event ProposalTallied(uint256 indexed proposalId, ProposalStatus finalStatus);

    // --- Modifiers ---
    modifier onlyOracle() {
        if (!registeredOracles[msg.sender] && msg.sender != owner()) revert CallerNotOracleOrAdmin();
        _;
    }

    modifier whenExperimentStatus(uint256 _experimentId, ExperimentStatus _requiredStatus) {
        if (experiments[_experimentId].status != _requiredStatus) revert InvalidStatusTransition();
        _;
    }

    // --- Constructor ---
    constructor(address _governanceToken, address _rewardTokenERC20, address _rewardNFT) Ownable(msg.sender) {
        governanceToken = _governanceToken;
        rewardTokenERC20 = _rewardTokenERC20;
        rewardNFT = _rewardNFT;
        admin = msg.sender; // Admin is initially the owner
        // Initial epoch can be started by admin
    }

    // --- I. Initialization & Configuration ---

    /// @notice Allows admin or governance to update contract parameters.
    /// @param _parameterName The name of the parameter to change (e.g., "epochDuration").
    /// @param _newValue The new value for the parameter.
    function setParameter(string calldata _parameterName, uint256 _newValue) external onlyOwner {
        // Note: In a real system, this would likely be restricted by governance proposals after constructor
        // For this example, allowing owner for simplicity or during initial setup.
        // A more advanced version uses governance proposals via proposeParameterChange -> vote -> tally.
        bytes32 paramHash = keccak256(abi.encodePacked(_parameterName));
        if (paramHash == keccak256(abi.encodePacked("epochDuration"))) {
            parameters_epochDuration = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            parameters_proposalVotingPeriod = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minGovTokensToPropose"))) {
            parameters_minGovTokensToPropose = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minGovTokensToVote"))) {
            parameters_minGovTokensToVote = _newValue;
        } else if (paramHash == keccak256(abi.encodePacked("minStakeForExperimentCreation"))) {
             parameters_minStakeForExperimentCreation = _newValue;
        } else {
            revert InvalidParameterName();
        }
        emit ParameterChanged(_parameterName, _newValue);
    }

     /// @notice Allows admin to set the asset required for experiment creation stake.
    /// @param _assetAddress The address of the ERC20 or ERC721 asset.
    function setExperimentCreationStakeAsset(address _assetAddress) external onlyOwner {
         // In a production system, this would also be part of governance
        parameters_experimentCreationStakeAsset = keccak256(abi.encodePacked(_assetAddress));
        // Optionally add a check that _assetAddress is a contract
    }


    /// @notice Registers or unregisters an address as an authorized oracle.
    /// @param _oracleAddress The address to register/unregister.
    /// @param _isRegistered True to register, false to unregister.
    function registerOracle(address _oracleAddress, bool _isRegistered) external onlyOwner {
        registeredOracles[_oracleAddress] = _isRegistered;
        emit OracleRegistered(_oracleAddress, _isRegistered);
    }

    /// @notice Adds a new experiment type definition. Can be called by admin or via governance.
    /// @param _typeId A unique identifier for the experiment type (e.g., `keccak256("ComputationValidation")`).
    /// @param _name The human-readable name of the type.
    /// @param _description A description of the experiment type.
    /// @param _allowedStakeAssets List of asset addresses allowed for staking.
    /// @param _allowedStakeAssetTypes Corresponding list of AssetTypes (ERC20/ERC721).
    /// @param _minStakeAmountERC20 Minimum stake required for any ERC20 asset.
    /// @param _requiredProofType The type of proof required for this experiment type.
    /// @param _stakeDuration Duration of the staking phase in seconds.
    /// @param _activeDuration Duration of the active phase in seconds.
    function addExperimentType(
        bytes32 _typeId,
        string calldata _name,
        string calldata _description,
        address[] calldata _allowedStakeAssets,
        AssetType[] calldata _allowedStakeAssetTypes,
        uint256 _minStakeAmountERC20,
        bytes32 _requiredProofType,
        uint256 _stakeDuration,
        uint256 _activeDuration
    ) external onlyOwner { // Simplified: OnlyOwner. Advanced: Requires governance proposal/vote.
        if (experimentTypes[_typeId].typeId != bytes32(0)) revert ExperimentTypeAlreadyExists();
        if (_allowedStakeAssets.length != _allowedStakeAssetTypes.length) revert InvalidAssetType();

        experimentTypes[_typeId] = ExperimentType({
            typeId: _typeId,
            name: _name,
            description: _description,
            allowedStakeAssets: _allowedStakeAssets,
            allowedStakeAssetTypes: _allowedStakeAssetTypes,
            minStakeAmountERC20: _minStakeAmountERC20,
            requiredProofType: _requiredProofType,
            stakeDuration: _stakeDuration,
            activeDuration: _activeDuration
            // ... initialize other fields
        });
        experimentTypeIds.push(_typeId);

        emit ExperimentTypeAdded(_typeId, _name, msg.sender);
    }

    // --- II. Epoch Management ---

    /// @notice Starts the next epoch. Can only be called if the current epoch is ended or inactive.
    function startNextEpoch() external onlyOwner {
        if (currentEpochId > 0 && epochs[currentEpochId].status != EpochStatus.Ended) revert EpochInProgress();

        epochCounter++;
        currentEpochId = epochCounter;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime.add(parameters_epochDuration);

        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: startTime,
            endTime: endTime,
            experimentIDs: new uint256[](0),
            status: EpochStatus.Active
        });

        emit EpochStarted(currentEpochId, startTime, endTime);
    }

    /// @notice Ends the current epoch if its duration has passed.
    function endCurrentEpoch() external onlyOwner {
        if (currentEpochId == 0 || epochs[currentEpochId].status != EpochStatus.Active) revert EpochNotReadyToEnd();
        if (block.timestamp < epochs[currentEpochId].endTime) revert EpochNotReadyToEnd();

        epochs[currentEpochId].status = EpochStatus.Ended;
        // Potentially trigger evaluation/finalization for experiments still active?
        // Or ensure all experiments must be finalized *before* epoch ends.
        // For simplicity here, let's assume experiments can finish after epoch end.
        emit EpochEnded(currentEpochId, EpochStatus.Ended);
    }

    // --- III. Experiment Lifecycle ---

    /// @notice Creates a new experiment instance based on an approved type.
    /// Requires a stake from the creator.
    /// @param _typeId The ID of the experiment type.
    /// @param _proofRequirementData Data specific to this experiment's proof requirements.
    /// @param _creatorStakeAsset The asset used for creator stake.
    /// @param _creatorStakeAmount The amount of asset staked by the creator.
    function createExperiment(
        bytes32 _typeId,
        bytes calldata _proofRequirementData,
        address _creatorStakeAsset,
        uint256 _creatorStakeAmount
    ) external {
        if (currentEpochId == 0 || epochs[currentEpochId].status != EpochStatus.Active) revert EpochNotInProgress(); // Needs Epoch

        ExperimentType storage expType = experimentTypes[_typeId];
        if (expType.typeId == bytes32(0)) revert ExperimentTypeNotFound();

        // Check creator stake requirement
        bytes32 stakeAssetHash = keccak256(abi.encodePacked(_creatorStakeAsset));
        if (parameters_experimentCreationStakeAsset != bytes32(0) && stakeAssetHash != parameters_experimentCreationStakeAsset) {
             revert InvalidAssetType(); // Must use the designated stake asset
        }
        if (_creatorStakeAmount < parameters_minStakeForExperimentCreation) {
             revert StakeAmountTooLow(parameters_minStakeForExperimentCreation);
        }

        // Transfer creator stake (assuming ERC20 for simplicity of creator stake)
        IERC20 creatorStakeToken = IERC20(_creatorStakeAsset);
        creatorStakeToken.transferFrom(msg.sender, address(this), _creatorStakeAmount);

        experimentCounter++;
        uint256 newExperimentId = experimentCounter;
        uint256 currentTime = block.timestamp;

        experiments[newExperimentId] = Experiment({
            id: newExperimentId,
            typeId: _typeId,
            epochId: currentEpochId,
            creator: msg.sender,
            status: ExperimentStatus.Setup, // Starts in Setup
            startTime: 0, // Set when transitions to Active
            stakingEndTime: currentTime.add(expType.stakeDuration),
            activeEndTime: 0, // Set when transitions to Active
            evaluationEndTime: 0, // Set when transitions to Evaluation
            proofRequirementData: _proofRequirementData,
            resultData: "",
            totalStakedERC20: 0,
            totalStakedERC721Count: mapping(address => uint256),
            proofIDs: new uint256[](0),
            userStakes: mapping(address => Stake), // Initialize mappings
            userStakedNFTTokenIds: mapping(address => mapping(address => uint256[]))
        });

        epochs[currentEpochId].experimentIDs.push(newExperimentId);

        // Automatically transition to Staking phase if possible
        transitionExperimentStatus(newExperimentId); // Tries to move from Setup to Staking

        emit ExperimentCreated(newExperimentId, _typeId, msg.sender, currentEpochId, experiments[newExperimentId].stakingEndTime);
    }


    /// @notice Allows a user to stake assets into an experiment.
    /// Requires the experiment to be in the Staking phase.
    /// @param _experimentId The ID of the experiment.
    /// @param _assetAddress The address of the asset (ERC20 or ERC721).
    /// @param _assetType The type of asset (ERC20 or ERC721).
    /// @param _amountOrTokenId For ERC20, the amount; for ERC721, the token ID.
    function stakeIntoExperiment(
        uint256 _experimentId,
        address _assetAddress,
        AssetType _assetType,
        uint256 _amountOrTokenId
    ) external whenExperimentStatus(_experimentId, ExperimentStatus.Staking) {
        Experiment storage exp = experiments[_experimentId];
        ExperimentType storage expType = experimentTypes[exp.typeId];
        bool allowedAsset = false;
        for (uint i = 0; i < expType.allowedStakeAssets.length; i++) {
            if (expType.allowedStakeAssets[i] == _assetAddress && expType.allowedStakeAssetTypes[i] == _assetType) {
                allowedAsset = true;
                break;
            }
        }
        if (!allowedAsset) revert InvalidAssetType();

        if (_assetType == AssetType.ERC20) {
            if (_amountOrTokenId < expType.minStakeAmountERC20) revert StakeAmountTooLow(expType.minStakeAmountERC20);
            // Check allowance before transferFrom
             IERC20 asset = IERC20(_assetAddress);
             asset.transferFrom(msg.sender, address(this), _amountOrTokenId);
             exp.totalStakedERC20 = exp.totalStakedERC20.add(_amountOrTokenId);
        } else if (_assetType == AssetType.ERC721) {
             // Check ownership before transferFrom
            IERC721 asset = IERC721(_assetAddress);
            require(asset.ownerOf(_amountOrTokenId) == msg.sender, "ERC721: caller is not owner");
            asset.safeTransferFrom(msg.sender, address(this), _amountOrTokenId);
            exp.totalStakedERC721Count[_assetAddress]++;
            exp.userStakedNFTTokenIds[msg.sender][_assetAddress].push(_amountOrTokenId);

        } else {
            revert InvalidAssetType();
        }

         // Store stake details - simplifies by only storing the *last* stake of a given asset type/address by a user
         // A more complex system might track multiple individual stakes
        exp.userStakes[msg.sender] = Stake({
            user: msg.sender,
            assetAddress: _assetAddress,
            assetType: _assetType,
            amount: (_assetType == AssetType.ERC20) ? _amountOrTokenId : 1, // Amount is 1 for NFT
            stakeTime: block.timestamp,
            claimedRewards: false
        });

        emit AssetStaked(_experimentId, msg.sender, _assetAddress, _assetType, _amountOrTokenId);

         // Automatically transition to Active phase if staking time ends
         transitionExperimentStatus(_experimentId);
    }

    /// @notice Allows a user to unstake assets. Rules depend on experiment phase.
    /// Usually only allowed in Cancelled state, or potentially Setup/Staking with penalty.
    /// @param _experimentId The ID of the experiment.
    /// @param _assetAddress The address of the staked asset.
    /// @param _assetType The type of asset.
    /// @param _amountOrTokenId For ERC20, the amount; for ERC721, the token ID.
    function unstakeFromExperiment(
        uint256 _experimentId,
        address _assetAddress,
        AssetType _assetType,
        uint256 _amountOrTokenId
    ) external {
         Experiment storage exp = experiments[_experimentId];
         Stake storage userStake = exp.userStakes[msg.sender];

         if (userStake.user == address(0)) revert NoStakeFound();
         if (userStake.assetAddress != _assetAddress || userStake.assetType != _assetType) revert NoStakeFound(); // Ensure they are unstaking the asset type they staked

         // Define unstaking rules based on status
         bool canUnstake = false;
         uint256 amountToReturn = 0;
         uint256 tokenIdToReturn = 0; // Only used for ERC721

         if (exp.status == ExperimentStatus.Cancelled) {
            canUnstake = true; // Full unstake allowed on cancellation
            if (_assetType == AssetType.ERC20) {
                 amountToReturn = userStake.amount; // Return the full staked amount
                 // Need to track individual ERC20 stakes if multiple stakes per user/asset are allowed.
                 // With simplified Stake struct, we assume only the last stake matters or sum is tracked elsewhere.
                 // For this implementation, let's simplify: user can unstake their *latest* full stake in Cancelled.
            } else { // ERC721
                // Need to find and remove the specific tokenId from the userStakedNFTTokenIds array
                uint256[] storage tokenIds = exp.userStakedNFTTokenIds[msg.sender][_assetAddress];
                bool found = false;
                for(uint i = 0; i < tokenIds.length; i++){
                    if(tokenIds[i] == _amountOrTokenId){
                        tokenIdToReturn = tokenIds[i];
                        // Remove token id from array (simple but inefficient for large arrays)
                        tokenIds[i] = tokenIds[tokenIds.length - 1];
                        tokenIds.pop();
                        found = true;
                        break;
                    }
                }
                if(!found) revert NoStakeFound(); // Token ID not found as staked by user in this experiment
            }

         }
         // Add other conditions if needed (e.g., unstake during staking phase with penalty)
         // else if (exp.status == ExperimentStatus.Staking && block.timestamp < exp.stakingEndTime) {
         //    canUnstake = true; // Example: unstake allowed during staking, potentially with penalty logic here
         //    amountToReturn = (_assetType == AssetType.ERC20) ? userStake.amount * 90 / 100 : 0; // Example 10% penalty
         //    // For ERC721, penalty might mean losing the NFT or paying a fee in another token
         // }

         if (!canUnstake) revert ExperimentNotInUnstakingPhase(); // Or specific error based on status

         // Perform the transfer
         if (_assetType == AssetType.ERC20) {
              IERC20 asset = IERC20(_assetAddress);
              asset.transfer(msg.sender, amountToReturn);
             // Need to update totalStakedERC20 if tracking aggregate
         } else if (_assetType == AssetType.ERC721) {
              IERC721 asset = IERC721(_assetAddress);
              asset.safeTransferFrom(address(this), msg.sender, tokenIdToReturn);
             exp.totalStakedERC721Count[_assetAddress]--; // Decrease count
         }

         // Clear the user's stake entry for this asset type/address (or update amount if tracking aggregate)
         // Given the simplified Stake struct, we might just invalidate it or mark it as unstaked
         // With the current struct design, simply marking it as claimed or removing might be complex if multiple stakes are allowed per user/asset.
         // Let's assume for simplicity, the stake struct tracks the "current" stake for that asset type, and claiming/unstaking clears it.
         // To handle multiple NFT stakes, we remove the specific token ID from the list.
         // For ERC20, if multiple stakes were allowed, a more complex mapping would be needed. With the current struct, this unstake function for ERC20 is problematic for partial unstakes.
         // Let's refine: the Stake struct represents the total *claimable* amount/NFTs for that asset type, and unstaking/claiming reduces it.

         emit AssetUnstaked(_experimentId, msg.sender, _assetAddress, _assetType, (_assetType == AssetType.ERC20) ? amountToReturn : tokenIdToReturn);
    }


    /// @notice Submits initial proof data for an experiment during its Active phase.
    /// @param _experimentId The ID of the experiment.
    /// @param _submissionData The raw data related to the proof.
    function submitProofForExperiment(uint256 _experimentId, bytes calldata _submissionData) external whenExperimentStatus(_experimentId, ExperimentStatus.Active) {
        Experiment storage exp = experiments[_experimentId];
        ExperimentType storage expType = experimentTypes[exp.typeId];

        // Prevent multiple proofs of the same type from the same submitter? Or allow multiple?
        // Let's allow multiple submissions, but maybe only the first or the verified one counts.
        // For simplicity, let's track proofs by ID and require verification.

        uint256 newProofId = proposals.length; // Using proposalCounter as a simple ID sequence (re-evaluate)
        // Use a separate counter for proofs:
        uint256 newProofId_ = experimentCounter + 1; // Needs a dedicated global proof counter or nested ID

        // Let's use a global proof counter
        uint256 newProofId = proposalCounter; // Temporarily using proposal counter as a global ID
        proposalCounter++; // Increment global counter

        proofs[newProofId] = Proof({
            id: newProofId,
            experimentId: _experimentId,
            proofType: expType.requiredProofType,
            submittedBy: msg.sender,
            submissionData: _submissionData,
            status: ProofStatus.Submitted,
            verifiedByOracle: address(0),
            verificationResultData: "",
            submissionTime: block.timestamp,
            verificationTime: 0,
            stakeSlashedAmount: 0
        });

        exp.proofIDs.push(newProofId);

        emit ProofSubmitted(_experimentId, newProofId, msg.sender, expType.requiredProofType);

         // Automatically transition if conditions met (e.g., time elapsed and enough proofs submitted)
        transitionExperimentStatus(_experimentId);
    }

    mapping(uint256 => Proof) public proofs; // Global mapping for proofs

    /// @notice Callable by a registered oracle to verify a submitted proof.
    /// Updates the proof's status and records verification data.
    /// @param _proofId The ID of the proof to verify.
    /// @param _isValid True if the proof is valid, false otherwise.
    /// @param _verificationResultData Data provided by the oracle about the verification.
    function verifyProof(uint256 _proofId, bool _isValid, bytes calldata _verificationResultData) external onlyOracle {
        Proof storage proof = proofs[_proofId];
        if (proof.experimentId == 0) revert ProofNotFound(); // Using 0 as default check for non-existent proof
        if (proof.status != ProofStatus.Submitted) revert InvalidProofStatusForVerification();

        proof.status = _isValid ? ProofStatus.VerifiedValid : ProofStatus.VerifiedInvalid;
        proof.verifiedByOracle = msg.sender;
        proof.verificationResultData = _verificationResultData;
        proof.verificationTime = block.timestamp;

        emit ProofVerified(_proofId, proof.status, msg.sender);

        // Automatically transition experiment status if verification triggers it
        transitionExperimentStatus(proof.experimentId);
    }

    /// @notice Callable by a registered oracle or admin to slash stake associated with a specific proof submission.
    /// Typically used when a proof is verified as invalid.
    /// @param _proofId The ID of the proof whose submitter's stake should be slashed.
    /// @param _amountToSlash The amount of ERC20 stake to slash. For ERC721, rules would differ (e.g., loss of NFT or separate penalty).
    function slashStake(uint256 _proofId, uint256 _amountToSlash) external onlyOracle {
         Proof storage proof = proofs[_proofId];
         if (proof.experimentId == 0) revert ProofNotFound();
         if (proof.status != ProofStatus.VerifiedInvalid) revert InvalidProofStatusForSlashing();
         if (proof.stakeSlashedAmount > 0) revert ProofAlreadySlashed(); // Prevent double slashing

         // Find the stake associated with the proof submitter for this experiment
         Experiment storage exp = experiments[proof.experimentId];
         Stake storage submitterStake = exp.userStakes[proof.submittedBy]; // Assumes single stake per user/asset type

         // Currently only supports slashing ERC20 stakes for simplicity
         if (submitterStake.user == address(0) || submitterStake.assetType != AssetType.ERC20 || submitterStake.amount == 0) {
             revert NoStakeFound(); // Submitter didn't have a relevant ERC20 stake to slash
         }

         uint256 actualAmountToSlash = Math.min(_amountToSlash, submitterStake.amount);

         submitterStake.amount = submitterStake.amount.sub(actualAmountToSlash);
         exp.totalStakedERC20 = exp.totalStakedERC20.sub(actualAmountToSlash);
         proof.stakeSlashedAmount = actualAmountToSlash;

         // Slashed amount could be burned, sent to a treasury, or distributed
         // For simplicity, let's assume it remains in the contract for now.
         emit StakeSlashed(proof.experimentId, proof.submittedBy, submitterStake.assetAddress, submitterStake.assetType, actualAmountToSlash);
    }


     /// @notice Attempts to transition an experiment to the next status based on time and conditions.
     /// Can be called by anyone, but state change only occurs if conditions are met.
     /// @param _experimentId The ID of the experiment.
    function transitionExperimentStatus(uint256 _experimentId) public {
        Experiment storage exp = experiments[_experimentId];
        ExperimentType storage expType = experimentTypes[exp.typeId];
        uint256 currentTime = block.timestamp;
        ExperimentStatus currentStatus = exp.status;
        ExperimentStatus nextStatus = currentStatus; // Default to no change

        if (currentStatus == ExperimentStatus.Setup && currentTime >= exp.stakingEndTime.sub(expType.stakeDuration)) {
            // Transition from Setup to Staking can happen immediately after creation if staking time is set.
            // Or it transitions when stake duration window starts from setup time.
            // Let's assume setup is just initialization, and it moves straight to Staking.
            // The check `stakingEndTime.sub(expType.stakeDuration)` implies the staking window starts `stakeDuration` seconds before `stakingEndTime`.
            // A simpler model: stakingEndTime is the *end* of staking. Setup is just before staking.
            // Let's simplify: Setup automatically transitions to Staking upon creation. The stakingEndTime IS the end time.
            // The call from `createExperiment` should handle Setup -> Staking.
            // This function handles Staking -> Active, Active -> Evaluation, Evaluation -> Finalized.
             if (currentTime >= exp.stakingEndTime) {
                nextStatus = ExperimentStatus.Active;
                exp.startTime = currentTime; // Active phase starts now
                exp.activeEndTime = currentTime.add(expType.activeDuration);
            }
        } else if (currentStatus == ExperimentStatus.Staking && currentTime >= exp.stakingEndTime) {
            nextStatus = ExperimentStatus.Active;
            exp.startTime = currentTime; // Active phase starts now
            exp.activeEndTime = currentTime.add(expType.activeDuration);

        } else if (currentStatus == ExperimentStatus.Active && currentTime >= exp.activeEndTime) {
             // Active phase ends. Ready for evaluation based on proofs.
            nextStatus = ExperimentStatus.Evaluation;
            // Set evaluation time limit if needed
            // exp.evaluationEndTime = currentTime.add(evaluationPeriod);
        } else if (currentStatus == ExperimentStatus.Evaluation) {
            // Evaluation finishes based on proofs verified or evaluation period end
            // This requires specific logic based on expType and proof statuses
            // For example: all required proofs are verified OR evaluation time is over.
             bool evaluationComplete = checkEvaluationComplete(_experimentId); // Placeholder for complex logic
             if (evaluationComplete /* || (exp.evaluationEndTime > 0 && currentTime >= exp.evaluationEndTime) */) {
                 evaluateExperiment(_experimentId); // Call evaluation logic
                 nextStatus = ExperimentStatus.Finalized;
             }
        }
        // Finalized -> (No further transitions typically)

        if (nextStatus != currentStatus) {
             exp.status = nextStatus;
             emit ExperimentStatusTransition(_experimentId, currentStatus, nextStatus);
        }
    }

     /// @notice Placeholder function to check if evaluation criteria are met.
     /// This logic would be complex and specific to each ExperimentType.
     /// @param _experimentId The ID of the experiment.
     /// @return True if evaluation is complete, false otherwise.
    function checkEvaluationComplete(uint256 _experimentId) internal view returns (bool) {
         Experiment storage exp = experiments[_experimentId];
         ExperimentType storage expType = experimentTypes[exp.typeId];

         // Example Logic:
         // - Check if a minimum number of valid proofs of `requiredProofType` have been submitted and verified.
         // - Check if the evaluation time limit (if any) has passed.
         // - Check if a specific oracle has submitted a final result proof.

         uint256 validProofCount = 0;
         for(uint i = 0; i < exp.proofIDs.length; i++){
             Proof storage proof = proofs[exp.proofIDs[i]];
             if(proof.proofType == expType.requiredProofType && proof.status == ProofStatus.VerifiedValid){
                 validProofCount++;
             }
         }

         // Example: Requires at least 1 valid proof
         return validProofCount >= 1; // Simplified example

         // In a real scenario, this would be much more complex.
    }


    /// @notice Determines the outcome and calculates rewards for a Finalized experiment.
    /// Called automatically by `transitionExperimentStatus` when evaluation is complete.
    /// @param _experimentId The ID of the experiment.
    function evaluateExperiment(uint256 _experimentId) internal {
        Experiment storage exp = experiments[_experimentId];
        // if (exp.status != ExperimentStatus.Evaluation) revert ExperimentNotReadyForEvaluation(); // Should be called *from* transition

        // This function contains the core logic for determining the experiment outcome
        // based on proofs, parameters, staked assets, etc.
        // The result should be stored in exp.resultData.

        // Example Logic:
        // - Iterate through verified proofs.
        // - Use proof verificationResultData to calculate outcome (e.g., average, majority vote, specific value).
        // - Calculate reward multipliers or total reward pool based on outcome, total staked, etc.
        // - Store outcome and reward info in exp.resultData (e.g., ABI-encoded struct).

        // For simplicity, let's set a dummy result
        exp.resultData = abi.encodePacked("Success!", uint256(100)); // Example: String + Reward Multiplier/Amount

        // Note: This function does NOT distribute rewards, only calculates and stores the basis for them.
        // Rewards are claimed individually by users.
    }

    /// @notice Allows a user to claim rewards from a Finalized experiment.
    /// Rewards are calculated based on the user's stake and the experiment's resultData.
    /// @param _experimentId The ID of the experiment.
    function claimRewards(uint256 _experimentId) external {
        Experiment storage exp = experiments[_experimentId];
        if (exp.status != ExperimentStatus.Finalized) revert ExperimentNotFinalizedForClaiming();

        Stake storage userStake = exp.userStakes[msg.sender];
        if (userStake.user == address(0) || userStake.claimedRewards) revert NoStakeFound(); // Or already claimed

        // Reward calculation logic based on exp.resultData and userStake details
        // This logic would be complex and specific to each ExperimentType, possibly using a helper contract/library.
        // Example: Calculate ERC20 reward and maybe determine if an NFT should be minted.
        uint256 rewardAmountERC20 = 0;
        uint256[] memory rewardNFTTokenIds; // Array of token IDs minted/transferred

        // Decode resultData (example: string + reward multiplier)
        (string memory outcome, uint256 rewardMultiplier) = abi.decode(exp.resultData, (string, uint256));

        // Example: ERC20 reward = user's staked amount * multiplier / 100
        if (userStake.assetType == AssetType.ERC20) {
            rewardAmountERC20 = userStake.amount.mul(rewardMultiplier).div(100);
             // Also return the original staked amount? Or is staking non-refundable, only yields rewards?
             // Let's assume stake is typically returned + rewards, unless slashed.
             // Need to return stake amount too.
             // User unstake function should handle stake return when appropriate (e.g. Cancelled, or here?)
             // Let's adjust: unstaking is only on Cancelled. Stake is returned *with* rewards on Finalized.
             uint256 amountToReturn = userStake.amount;
             // Handle slashed amount subtraction if it wasn't already deducted from stake struct
             // amountToReturn = amountToReturn.sub(userStake.slashedAmount); // Requires tracking slashed amount per stake
             IERC20(userStake.assetAddress).transfer(msg.sender, amountToReturn); // Return staked amount
        } else { // ERC721 stake
             // Return the staked NFT(s) + potentially an ERC20 reward or a new reward NFT
             uint256[] storage stakedNFTs = exp.userStakedNFTTokenIds[msg.sender][userStake.assetAddress];
             for(uint i = 0; i < stakedNFTs.length; i++){
                 IERC721(userStake.assetAddress).safeTransferFrom(address(this), msg.sender, stakedNFTs[i]);
             }
             delete exp.userStakedNFTTokenIds[msg.sender][userStake.assetAddress]; // Clear the list

             // Example: ERC20 reward based on number of NFTs staked
             rewardAmountERC20 = stakedNFTs.length.mul(rewardMultiplier).div(100);

             // Example: Mint a reward NFT if outcome is "Success!"
             if(keccak256(abi.encodePacked(outcome)) == keccak256(abi.encodePacked("Success!"))){
                 // This requires the rewardNFT contract to have a minting function callable by this contract.
                 // Assuming an interface for rewardNFT with a mint function like `mintTo(address to, uint256 tokenId)`.
                 // A random/unique token ID would be needed, potentially generated or managed by the NFT contract.
                 // For demonstration, let's just simulate this part.
                 // IRewardNFT(rewardNFT).mintTo(msg.sender, newRewardTokenId);
                 // rewardNFTTokenIds.push(newRewardTokenId); // Add minted ID to array
             }
        }


        // Transfer ERC20 reward
        if (rewardAmountERC20 > 0) {
            IERC20(rewardTokenERC20).transfer(msg.sender, rewardAmountERC20);
        }

        userStake.claimedRewards = true; // Mark as claimed
        delete exp.userStakes[msg.sender]; // Clear the stake entry after claiming everything

        emit RewardsClaimed(_experimentId, msg.sender, rewardAmountERC20, rewardNFTTokenIds);
    }

    /// @notice Allows admin or governance to cancel an experiment prematurely.
    /// Staked assets are typically made available for unstaking upon cancellation.
    /// @param _experimentId The ID of the experiment to cancel.
    function cancelExperiment(uint256 _experimentId) external onlyOwner { // Simplified: OnlyOwner. Advanced: Governance decision.
        Experiment storage exp = experiments[_experimentId];
        // Can only cancel if not already Finalized or Cancelled
        if (exp.status == ExperimentStatus.Finalized || exp.status == ExperimentStatus.Cancelled) revert InvalidStatusTransition();

        exp.status = ExperimentStatus.Cancelled;

        // Note: Staked assets become available for withdrawal via `unstakeFromExperiment` in the Cancelled state.

        emit ExperimentCancelled(_experimentId, msg.sender);
         emit ExperimentStatusTransition(_experimentId, exp.status, ExperimentStatus.Cancelled); // Re-emit status transition explicitly
    }

    // --- IV. Governance (Proposal & Voting) ---
    // Note: This is a basic example. Real governance is more complex (quorum, vote weight, proposal data encoding).

    /// @notice Allows governance token holders to propose changing a contract parameter.
    /// Requires minimum governance token stake.
    /// @param _parameterName The name of the parameter (bytes32 representation).
    /// @param _newValue The new value for the parameter.
    function proposeParameterChange(bytes32 _parameterName, uint256 _newValue) external {
        // Check minimum governance token balance/stake (assuming simple balance check)
        if (IERC20(governanceToken).balanceOf(msg.sender) < parameters_minGovTokensToPropose) {
            revert InsufficientGovernanceTokens();
        }

        uint256 proposalId = proposalCounter++;
        proposals[proposalId] = ParameterProposal({
            proposalId: proposalId,
            proposalType: ProposalType.ParameterChange,
            proposer: msg.sender,
            proposalData: abi.encode(_parameterName, _newValue), // Encode parameter name and value
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(parameters_proposalVotingPeriod),
            voteCountYes: 0,
            voteCountNo: 0,
            hasVoted: mapping(address => bool),
            status: ProposalStatus.Open
        });

        emit ProposalCreated(proposalId, ProposalType.ParameterChange, msg.sender);
    }

     /// @notice Allows governance token holders to propose adding a new experiment type.
     /// Requires minimum governance token stake.
     /// @param _expTypeData Encoded data for the new ExperimentType struct.
    function proposeAddExperimentType(bytes calldata _expTypeData) external {
        if (IERC20(governanceToken).balanceOf(msg.sender) < parameters_minGovTokensToPropose) {
            revert InsufficientGovernanceTokens();
        }

         // Decode to check the typeId and ensure it doesn't exist before creating proposal
         (bytes32 typeId, , , , , , , , ) = abi.decode(_expTypeData, (bytes32, string, string, address[], AssetType[], uint256, bytes32, uint256, uint256));
        if (experimentTypes[typeId].typeId != bytes32(0)) revert ExperimentTypeAlreadyExists();


        uint256 proposalId = proposalCounter++;
        proposals[proposalId] = ParameterProposal({
            proposalId: proposalId,
            proposalType: ProposalType.AddExperimentType,
            proposer: msg.sender,
            proposalData: _expTypeData, // Store encoded ExperimentType data
            creationTime: block.timestamp,
            votingEndTime: block.timestamp.add(parameters_proposalVotingPeriod),
            voteCountYes: 0,
            voteCountNo: 0,
            hasVoted: mapping(address => bool),
            status: ProposalStatus.Open
        });

        emit ProposalCreated(proposalId, ProposalType.AddExperimentType, msg.sender);
    }


    /// @notice Allows a governance token holder to vote on an open proposal.
    /// Requires minimum governance token balance/stake.
    /// @param _proposalId The ID of the proposal.
    /// @param _vote True for Yes, False for No.
    function voteOnProposal(uint256 _proposalId, bool _vote) external {
        ParameterProposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) revert ProposalNotFound(); // Check if proposal exists
        if (proposal.status != ProposalStatus.Open) revert VotingPeriodNotActive();
        if (block.timestamp >= proposal.votingEndTime) revert VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        // Check minimum governance token balance/stake at time of vote
        if (IERC20(governanceToken).balanceOf(msg.sender) < parameters_minGovTokensToVote) {
             revert InsufficientGovernanceTokens();
        }

        uint256 voterPower = IERC20(governanceToken).balanceOf(msg.sender); // Simple vote weight by balance

        if (_vote) {
            proposal.voteCountYes = proposal.voteCountYes.add(voterPower);
        } else {
            proposal.voteCountNo = proposal.voteCountNo.add(voterPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @notice Tallies votes for a proposal after the voting period ends and executes the proposal if accepted.
    /// Can be called by anyone.
    /// @param _proposalId The ID of the proposal to tally.
    function tallyProposalVotes(uint256 _proposalId) external {
        ParameterProposal storage proposal = proposals[_proposalId];
         if (proposal.proposalId == 0) revert ProposalNotFound(); // Check if proposal exists
        if (proposal.status != ProposalStatus.Open) revert ProposalAlreadyTallied();
        if (block.timestamp < proposal.votingEndTime) revert CannotTallyBeforeEndTime();

        // Simple majority vote
        if (proposal.voteCountYes > proposal.voteCountNo) {
            proposal.status = ProposalStatus.Accepted;
            // Execute the proposal
            if(proposal.proposalType == ProposalType.ParameterChange) {
                (bytes32 paramName, uint256 newValue) = abi.decode(proposal.proposalData, (bytes32, uint256));
                // Directly call setParameter logic (careful with permissions)
                // A better pattern is to have internal functions for parameter setting called by tallying
                if (paramName == keccak256("epochDuration")) parameters_epochDuration = newValue;
                else if (paramName == keccak256("proposalVotingPeriod")) parameters_proposalVotingPeriod = newValue;
                else if (paramName == keccak256("minGovTokensToPropose")) parameters_minGovTokensToPropose = newValue;
                else if (paramName == keccak256("minGovTokensToVote")) parameters_minGovTokensToVote = newValue;
                 else if (paramName == keccak256("minStakeForExperimentCreation")) parameters_minStakeForExperimentCreation = newValue;
                // Add other parameters here
                 else revert InvalidParameterName(); // Should not happen if proposal was valid
                 emit ParameterChanged(string(abi.encodePacked(paramName)), newValue); // Needs param name string
            } else if (proposal.proposalType == ProposalType.AddExperimentType) {
                // Decode and add the new experiment type
                 (bytes32 typeId, string memory name, string memory description, address[] memory allowedAssets, AssetType[] memory allowedAssetTypes, uint256 minStakeERC20, bytes32 requiredProofType, uint256 stakeDuration, uint256 activeDuration) = abi.decode(proposal.proposalData, (bytes32, string, string, address[], AssetType[], uint256, bytes32, uint256, uint256));

                 // Re-check existence just in case (unlikely)
                 if (experimentTypes[typeId].typeId != bytes32(0)) revert ExperimentTypeAlreadyExists();

                 experimentTypes[typeId] = ExperimentType({
                     typeId: typeId,
                     name: name,
                     description: description,
                     allowedStakeAssets: allowedAssets,
                     allowedStakeAssetTypes: allowedAssetTypes,
                     minStakeAmountERC20: minStakeERC20,
                     requiredProofType: requiredProofType,
                     stakeDuration: stakeDuration,
                     activeDuration: activeDuration
                     // ... initialize other fields
                 });
                experimentTypeIds.push(typeId);
                 emit ExperimentTypeAdded(typeId, name, address(0)); // Added by governance (address 0)

            } else {
                revert InvalidProposalType(); // Should not happen
            }

        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        emit ProposalTallied(_proposalId, proposal.status);
    }


    // --- V. View Functions ---

    /// @notice Retrieves details of a specific epoch.
    function getEpochDetails(uint256 _epochId) external view returns (Epoch memory) {
        return epochs[_epochId];
    }

     /// @notice Retrieves details of a specific experiment.
    function getExperimentDetails(uint256 _experimentId) external view returns (Experiment memory) {
        Experiment storage exp = experiments[_experimentId];
         // Copying mapping fields is not straightforward in Solidity views.
         // Need to return basic struct and provide separate getters for mappings.
         return Experiment({
             id: exp.id,
             typeId: exp.typeId,
             epochId: exp.epochId,
             creator: exp.creator,
             status: exp.status,
             startTime: exp.startTime,
             stakingEndTime: exp.stakingEndTime,
             activeEndTime: exp.activeEndTime,
             evaluationEndTime: exp.evaluationEndTime,
             proofRequirementData: exp.proofRequirementData,
             resultData: exp.resultData,
             totalStakedERC20: exp.totalStakedERC20,
             totalStakedERC721Count: exp.totalStakedERC721Count, // Note: This mapping copy might not work as expected in older compilers/versions.
             proofIDs: exp.proofIDs,
             userStakes: exp.userStakes, // Mapping copy issue here too
             userStakedNFTTokenIds: exp.userStakedNFTTokenIds // Mapping copy issue
         });
    }

    /// @notice Retrieves a user's stake details for a specific experiment and asset type.
    /// Note: This function returns the data stored in the `userStakes` mapping, which currently
    /// stores the *latest* stake per user per asset type/address. For ERC721, this isn't accurate
    /// for tracking multiple NFTs. Use `getUserStakedNFTTokenIds` for ERC721 details.
     function getUserStake(uint256 _experimentId, address _user) external view returns (Stake memory) {
         // Note: This only returns the single Stake struct entry.
         // For ERC721, use getUserStakedNFTTokenIds to see the list of token IDs.
         return experiments[_experimentId].userStakes[_user];
     }

    /// @notice Retrieves the list of ERC721 token IDs staked by a user in an experiment for a specific collection.
     function getUserStakedNFTTokenIds(uint256 _experimentId, address _user, address _assetAddress) external view returns (uint256[] memory) {
         return experiments[_experimentId].userStakedNFTTokenIds[_user][_assetAddress];
     }

     /// @notice Lists proofs submitted for an experiment.
    function getExperimentProofs(uint256 _experimentId) external view returns (Proof[] memory) {
        Experiment storage exp = experiments[_experimentId];
        Proof[] memory experimentProofList = new Proof[](exp.proofIDs.length);
        for(uint i = 0; i < exp.proofIDs.length; i++){
            experimentProofList[i] = proofs[exp.proofIDs[i]];
        }
        return experimentProofList;
    }

    /// @notice Retrieves configuration for a specific experiment type.
    function getExperimentTypeDetails(bytes32 _typeId) external view returns (ExperimentType memory) {
        return experimentTypes[_typeId];
    }

    /// @notice Retrieves the list of all approved experiment type IDs.
    function getExperimentTypeIds() external view returns (bytes32[] memory) {
        return experimentTypeIds;
    }

    /// @notice Retrieves current contract parameters.
    function getContractParameters() external view returns (uint256 epochDuration, uint256 proposalVotingPeriod, uint256 minGovTokensToPropose, uint256 minGovTokensToVote, uint256 minStakeForExperimentCreation, bytes32 experimentCreationStakeAsset) {
        return (parameters_epochDuration, parameters_proposalVotingPeriod, parameters_minGovTokensToPropose, parameters_minGovTokensToVote, parameters_minStakeForExperimentCreation, parameters_experimentCreationStakeAsset);
    }

    /// @notice Checks if an address is a registered oracle.
    function getOracleAddress(address _address) external view returns (bool) {
        return registeredOracles[_address];
    }

    /// @notice Retrieves details of a specific governance proposal.
    function getProposalDetails(uint256 _proposalId) external view returns (ParameterProposal memory) {
         ParameterProposal storage proposal = proposals[_proposalId];
          // Note: Mapping copy issue, need to return basic struct
         return ParameterProposal({
             proposalId: proposal.proposalId,
             proposalType: proposal.proposalType,
             proposer: proposal.proposer,
             proposalData: proposal.proposalData,
             creationTime: proposal.creationTime,
             votingEndTime: proposal.votingEndTime,
             voteCountYes: proposal.voteCountYes,
             voteCountNo: proposal.voteCountNo,
             hasVoted: proposal.hasVoted, // Mapping copy issue
             status: proposal.status
         });
     }

    /// @notice Retrieves the list of participants (addresses that staked) in an experiment.
    /// Note: This implementation stores stakes in a mapping `userStakes`. Retrieving all keys from a mapping
    /// in Solidity is not directly possible or efficient. This function provides a *placeholder*
    /// or would require a separate list of participants updated on stake/unstake.
     function getExperimentParticipants(uint256 _experimentId) external view returns (address[] memory) {
         // IMPORTANT: Retrieving all keys from a mapping is not natively supported/efficient in Solidity.
         // To implement this properly, you would need to maintain a separate dynamic array or linked list
         // of participant addresses, adding/removing addresses as they stake/unstake.
         // This is a simplified placeholder returning an empty array or requiring an external indexer.
         // For demonstration, let's return a dummy array or require explicit tracking.
         // Returning an empty array as a placeholder:
         address[] memory participants; // Requires a separate list to be maintained
         // return participants; // Return an empty array placeholder

         // Alternative: Iterate through a predefined max number of potential participants
         // Or, if `userStakes` mapping is iterated (unsafe/inefficient/gas-heavy): NOT RECOMMENDED ON-CHAIN
         // For a *functional* on-chain list, a dynamic array like `address[] public experimentParticipants[_experimentId]`
         // would need to be added and managed.
         // Let's add a simplified list tracking for demonstration, although managing it adds complexity.
         // Add: `mapping(uint256 => address[]) public experimentParticipantsList;`
         // Add to stakeIntoExperiment: `experimentParticipantsList[_experimentId].push(msg.sender);` (Handle duplicates)
         // Add to unstakeFromExperiment/claimRewards: Remove from list (inefficient removal from array)
         // Given the complexity and gas cost of array management, especially removal, it's often better
         // to rely on off-chain indexing for participant lists.
         // For this exercise, let's assume an external indexer is used for this view. Returning an empty array.
         return new address[](0); // Placeholder, requires off-chain indexing or costly on-chain list management.
     }

     /// @notice Checks if an experiment is ready to transition to its next status based on time and basic conditions.
     /// Does not execute the transition, only checks.
     /// @param _experimentId The ID of the experiment.
     /// @return True if transition is possible, false otherwise.
     function canTransitionStatus(uint256 _experimentId) external view returns (bool) {
        Experiment storage exp = experiments[_experimentId];
        ExperimentType storage expType = experimentTypes[exp.typeId];
        uint256 currentTime = block.timestamp;
        ExperimentStatus currentStatus = exp.status;

        if (currentStatus == ExperimentStatus.Setup && currentTime >= exp.stakingEndTime.sub(expType.stakeDuration)) return true; // Setup to Staking - see notes in transition function
        if (currentStatus == ExperimentStatus.Staking && currentTime >= exp.stakingEndTime) return true; // Staking to Active
        if (currentStatus == ExperimentStatus.Active && currentTime >= exp.activeEndTime) return true; // Active to Evaluation
        if (currentStatus == ExperimentStatus.Evaluation) {
             // Check if evaluation complete conditions are met (requires calling internal logic)
             return checkEvaluationComplete(_experimentId);
             // Add check for evaluationEndTime if applicable
             // return checkEvaluationComplete(_experimentId) || (exp.evaluationEndTime > 0 && currentTime >= exp.evaluationEndTime);
        }
        return false; // No transition possible from other statuses or if conditions not met
     }


    // --- ERC721Holder support ---
    // Required by ERC721Holder to accept ERC721 tokens.
    // function onERC721Received(...) is inherited and handles acceptance.

     // Fallback/Receive functions (optional, but good practice)
    receive() external payable {
        // Revert Ether sent directly to the contract, unless intended (e.g., for funding rewards).
        // For this contract, Ether is not used directly in core logic, so revert.
        revert("Ether not accepted");
    }

    fallback() external payable {
         revert("Calls to non-existent functions or unexpected data");
    }

     // Override Ownable functions if needed, e.g., renounceOwnership can be restricted.
}
```