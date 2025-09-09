Here's a smart contract in Solidity called "AetherForge," designed around a unique concept: a decentralized protocol for curating and generating AI-driven content blueprints. Users stake tokens to propose and curate AI prompts/configurations (blueprints). A designated oracle executes successful blueprints, storing the AI-generated content proof on-chain, and participants are rewarded based on their contribution and reputation.

This contract aims for uniqueness by combining:
*   **AI Blueprint Curation:** Users actively stake to support or challenge AI content generation parameters.
*   **Dynamic Reputation System:** User reputation is dynamically adjusted based on the success or failure of blueprints they propose, support, or challenge.
*   **Oracle-Driven Execution:** A trusted oracle acts as the bridge to off-chain AI models, submitting results back on-chain.
*   **Gamified Incentives:** Rewards and reputation boosts encourage active and high-quality participation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Contract: AetherForge - Decentralized AI Blueprint Curation Protocol
// AetherForge enables a community to propose, curate, and fund the generation of AI-driven content.
// Users stake a designated ERC20 token (ForgeToken) to support or challenge "Blueprints"
// (structured AI prompts/configurations). Successful blueprints are sent to an off-chain AI oracle
// for execution, and their results (e.g., IPFS CIDs of generated content) are recorded on-chain.
// Participants earn rewards and reputation based on the outcomes of the blueprints they engage with.

// Outline:
// I. Core Infrastructure & Access Control
//    - Ownership management, pausability, key address configuration (Oracle, Fee Recipient).
// II. User & Reputation Management
//    - User profile initialization, reputation score tracking and retrieval.
// III. Blueprint Lifecycle Management
//    - Proposing, staking on, challenging, and triggering execution for AI content blueprints.
//    - Managing the various states of a blueprint from proposal to execution and resolution.
// IV. Oracle Interaction & Content Proof
//    - Receiving AI execution results from the designated oracle, recording content proof.
// V. Reward & Incentive Mechanisms
//    - Distribution and claiming of rewards for successful blueprint participation and curation.
// VI. Protocol Parameter Adjustment
//    - Owner-controlled adjustment of various configurable parameters (e.g., periods, fees, reputation boosts).

// Function Summary:
// I. Core Infrastructure & Access Control
// 1.  constructor(): Initializes contract owner, ForgeToken, and sets initial protocol parameters.
// 2.  setOwner(): Transfers contract ownership.
// 3.  pause(): Pauses contract operations in emergencies.
// 4.  unpause(): Resumes contract operations.
// 5.  setOracleAddress(): Configures the address of the trusted AI Oracle.
// 6.  setFeeRecipient(): Sets the address to receive protocol fees.
// 7.  withdrawContractBalance(): Allows owner to withdraw native tokens (ETH) from contract.

// II. User & Reputation Management
// 8.  initializeUserProfile(): Users opt-in, establishing their profile and initial reputation.
// 9.  updateUserProfile(): Allows users to update their off-chain metadata URI.
// 10. getReputationScore(): Retrieves the current reputation score for a given user.

// III. Blueprint Lifecycle Management
// 11. proposeBlueprint(): Users propose new AI content blueprints by staking tokens.
// 12. stakeOnBlueprint(): Users stake tokens on an existing blueprint to support its curation.
// 13. challengeBlueprint(): Users challenge a blueprint they believe is undesirable, staking against it.
// 14. resolveChallenge(): (Owner/Oracle) Resolves a challenged blueprint's fate (Accept/Reject).
// 15. triggerBlueprintExecution(): (Owner/Oracle) Marks an 'Accepted' blueprint for AI execution.
// 16. getBlueprintDetails(): Retrieves all details for a specific blueprint.
// 17. getUserBlueprintStake(): Retrieves a user's stake on a specific blueprint (support and challenge).
// 18. getBlueprintState(): Returns the current state of a blueprint.
// 19. getBlueprintStakeSummary(): Provides a summary of total 'for' and 'against' stakes on a blueprint.

// IV. Oracle Interaction & Content Proof
// 20. submitBlueprintResult(): (Oracle) Submits the AI-generated content hash for an executed blueprint.
// 21. getContentProofCID(): Retrieves the content proof CID for an executed blueprint.

// V. Reward & Incentive Mechanisms
// 22. claimAllUserRewards(): Allows a user to claim all accumulated rewards across all their participations.

// VI. Protocol Parameter Adjustment
// 23. updateProtocolParameter(): Allows the owner to adjust various configurable parameters.
// 24. getProtocolParameter(): Retrieves the value of a specific protocol parameter.
// 25. rescueERC20(): Allows owner to retrieve accidentally sent ERC20 tokens.

contract AetherForge is Ownable, Pausable {
    using SafeMath for uint256;

    // --- Custom Errors ---
    error Unauthorized();
    error UnauthorizedOracle();
    error InvalidBlueprintState();
    error InsufficientStake();
    error AlreadyInitialized();
    error NotInitialized();
    error BlueprintPeriodNotEnded();
    error ChallengePeriodNotEnded();
    error NoRewardsToClaim();
    error BlueprintStillActive();
    error ZeroAddress();
    error InvalidParameterValue();
    error ForbiddenTokenRescue();

    // --- State Variables ---
    IERC20 public immutable FORGE_TOKEN; // The ERC20 token used for staking and rewards

    address public oracleAddress; // The trusted address for AI execution and result submission
    address public feeRecipient;  // Address to receive protocol fees

    uint256 public nextBlueprintId; // Counter for unique blueprint IDs

    // --- User Management ---
    // Stores user-specific data including reputation and stakes on various blueprints.
    struct UserProfile {
        bool initialized;
        uint256 reputationScore;
        string metadataURI; // Link to off-chain profile data (e.g., IPFS hash)
        mapping(uint256 => uint256) blueprintStakes; // Blueprint ID => User's FORGE_TOKEN stake amount (support)
        mapping(uint256 => uint256) blueprintChallengeStakes; // Blueprint ID => User's FORGE_TOKEN challenge stake
        uint256 pendingRewards; // Accumulated rewards across all blueprints, ready to be claimed
    }
    mapping(address => UserProfile) public userProfiles;

    // --- Blueprint Management ---
    // Defines the possible states a blueprint can transition through.
    enum BlueprintState {
        Proposed,         // Initial state after proposal
        CurationActive,   // Open for staking (support or challenge)
        Challenged,       // A challenge has been made, awaiting resolution by owner/oracle
        Accepted,         // Curation successful, ready for oracle execution
        Rejected,         // Curation failed or challenge successful
        Executing,        // Oracle is processing the blueprint
        Executed          // Oracle has submitted result, content proof available
    }

    // Stores all relevant data for each AI blueprint.
    struct Blueprint {
        address proposer;
        string blueprintCID;      // IPFS CID of the AI prompt/configuration (off-chain data)
        uint256 creationTimestamp;
        uint256 proposalStake;    // Initial stake by the proposer (counts as support)
        uint256 totalSupportStake;  // Total FORGE_TOKEN staked supporting this blueprint
        uint256 totalChallengeStake; // Total FORGE_TOKEN staked challenging this blueprint
        BlueprintState state;
        string resultCID;         // IPFS CID of the AI-generated content result
        uint256 curationPeriodEnd;  // Timestamp when the initial curation period ends
        uint256 challengePeriodEnd; // Timestamp when the challenge period ends (same as curation for simplicity)
        bool challengeResolved;   // True if a challenge against this blueprint has been decided
        address[] stakers;        // List of unique addresses that staked for the blueprint
        address[] challengers;    // List of unique addresses that challenged the blueprint
        mapping(address => bool) hasStaked;    // Helper to track unique stakers
        mapping(address => bool) hasChallenged; // Helper to track unique challengers
    }
    mapping(uint256 => Blueprint) public blueprints;

    // --- Protocol Parameters (configurable by owner) ---
    // Stores various protocol settings that can be adjusted through governance or owner.
    mapping(bytes32 => uint256) public protocolParameters;

    // --- Events ---
    event UserProfileInitialized(address indexed user, uint256 initialReputation);
    event UserProfileUpdated(address indexed user, string newMetadataURI);
    event BlueprintProposed(uint256 indexed blueprintId, address indexed proposer, string blueprintCID, uint256 stakeAmount);
    event BlueprintStaked(uint256 indexed blueprintId, address indexed staker, uint256 amount, bool isChallenge);
    event BlueprintStateChanged(uint256 indexed blueprintId, BlueprintState oldState, BlueprintState newState);
    event ChallengeResolved(uint256 indexed blueprintId, bool acceptedByOracle);
    event BlueprintExecuted(uint256 indexed blueprintId, string resultCID);
    event RewardsClaimed(address indexed user, uint256 indexed blueprintId, uint256 amount);
    event ProtocolParameterUpdated(bytes32 indexed parameterName, uint256 newValue);
    event OracleAddressSet(address indexed newOracle);
    event FeeRecipientSet(address indexed newRecipient);

    // --- Constructor ---
    /// @notice Initializes the contract with the ERC20 token address, owner, and default parameters.
    /// @param _forgeTokenAddress The address of the ERC20 token used for staking and rewards.
    constructor(address _forgeTokenAddress) Ownable(msg.sender) {
        if (_forgeTokenAddress == address(0)) revert ZeroAddress();
        FORGE_TOKEN = IERC20(_forgeTokenAddress);
        oracleAddress = address(0); // Must be set by owner after deployment
        feeRecipient = address(0);  // Must be set by owner after deployment
        nextBlueprintId = 1;

        // Set initial configurable protocol parameters
        protocolParameters["INITIAL_REPUTATION"] = 1000;          // Starting reputation for new users
        protocolParameters["PROPOSAL_FEE_PERCENT"] = 5;           // 5% of proposal stake goes to fees
        protocolParameters["MIN_PROPOSAL_STAKE"] = 1e18;          // Minimum 1 FORGE_TOKEN to propose
        protocolParameters["MIN_CURATION_STAKE"] = 1e17;          // Minimum 0.1 FORGE_TOKEN to stake/challenge
        protocolParameters["CURATION_PERIOD_DURATION"] = 3 days;  // Duration for staking/challenging phase
        protocolParameters["CHALLENGE_THRESHOLD_PERCENT"] = 50;   // Challenge if challenge stake reaches 50% of support
        protocolParameters["REPUTATION_BOOST_FACTOR"] = 10;       // Points gained for success
        protocolParameters["REPUTATION_PENALTY_FACTOR"] = 5;      // Points lost for failure
        protocolParameters["REWARD_PERCENT_OF_STAKE"] = 10;       // % of total support stake distributed as reward
    }

    // I. Core Infrastructure & Access Control

    /// @notice Transfers contract ownership. Only callable by current owner.
    /// @param newOwner The address of the new owner.
    function setOwner(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @notice Pauses contract operations in emergencies. Only callable by owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Resumes contract operations. Only callable by owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Configures the address of the trusted AI Oracle. Only callable by owner.
    /// @param _oracle The address of the new oracle.
    function setOracleAddress(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert ZeroAddress();
        oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    /// @notice Sets the address to receive protocol fees. Only callable by owner.
    /// @param _recipient The address of the new fee recipient.
    function setFeeRecipient(address _recipient) public onlyOwner {
        if (_recipient == address(0)) revert ZeroAddress();
        feeRecipient = _recipient;
        emit FeeRecipientSet(_recipient);
    }

    /// @notice Allows the owner to withdraw native tokens (ETH) from the contract.
    /// @dev This function is for emergency recovery of accidentally sent ETH. It does not touch FORGE_TOKEN.
    function withdrawContractBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // II. User & Reputation Management

    /// @notice Users opt-in to the protocol, establishing their profile and initial reputation.
    /// @dev A user must initialize their profile before participating in any blueprint activities.
    function initializeUserProfile() public whenNotPaused {
        if (userProfiles[_msgSender()].initialized) revert AlreadyInitialized();
        userProfiles[_msgSender()].initialized = true;
        userProfiles[_msgSender()].reputationScore = protocolParameters["INITIAL_REPUTATION"];
        emit UserProfileInitialized(_msgSender(), userProfiles[_msgSender()].reputationScore);
    }

    /// @notice Allows users to update their off-chain metadata URI.
    /// @param _metadataURI The new IPFS/HTTP URI for user profile metadata.
    function updateUserProfile(string calldata _metadataURI) public whenNotPaused {
        if (!userProfiles[_msgSender()].initialized) revert NotInitialized();
        userProfiles[_msgSender()].metadataURI = _metadataURI;
        emit UserProfileUpdated(_msgSender(), _metadataURI);
    }

    /// @notice Retrieves the current reputation score for a given user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user) public view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    // III. Blueprint Lifecycle Management

    /// @notice Users propose new AI content blueprints by staking tokens.
    /// @dev The proposer's stake contributes to the blueprint's initial support.
    /// @param _blueprintCID IPFS CID of the AI prompt/configuration (off-chain).
    /// @param _stakeAmount The amount of FORGE_TOKEN to stake for this proposal.
    function proposeBlueprint(string calldata _blueprintCID, uint256 _stakeAmount) public whenNotPaused {
        if (!userProfiles[_msgSender()].initialized) revert NotInitialized();
        if (_stakeAmount < protocolParameters["MIN_PROPOSAL_STAKE"]) revert InsufficientStake();

        uint256 currentBlueprintId = nextBlueprintId;
        nextBlueprintId++;

        // Transfer stake from user to contract (requires prior approval)
        FORGE_TOKEN.transferFrom(_msgSender(), address(this), _stakeAmount);

        // Calculate and transfer fee to recipient
        uint256 proposalFee = _stakeAmount.mul(protocolParameters["PROPOSAL_FEE_PERCENT"]).div(100);
        if (feeRecipient != address(0) && proposalFee > 0) {
            FORGE_TOKEN.transfer(feeRecipient, proposalFee);
        }

        uint256 actualStake = _stakeAmount.sub(proposalFee);

        Blueprint storage newBlueprint = blueprints[currentBlueprintId];
        newBlueprint.proposer = _msgSender();
        newBlueprint.blueprintCID = _blueprintCID;
        newBlueprint.creationTimestamp = block.timestamp;
        newBlueprint.proposalStake = actualStake;
        newBlueprint.totalSupportStake = actualStake; // Proposer's stake is counted as initial support
        newBlueprint.curationPeriodEnd = block.timestamp + protocolParameters["CURATION_PERIOD_DURATION"];
        newBlueprint.challengePeriodEnd = newBlueprint.curationPeriodEnd; // Challenge period ends concurrently
        newBlueprint.stakers.push(_msgSender());
        newBlueprint.hasStaked[_msgSender()] = true;
        userProfiles[_msgSender()].blueprintStakes[currentBlueprintId] = actualStake;

        emit BlueprintProposed(currentBlueprintId, _msgSender(), _blueprintCID, _stakeAmount);
        emit BlueprintStateChanged(currentBlueprintId, BlueprintState.Proposed, BlueprintState.CurationActive);
        newBlueprint.state = BlueprintState.CurationActive; // Immediately enters curation phase
    }

    /// @notice Users stake tokens on an existing blueprint to support its curation.
    /// @dev Users must approve the contract to spend their tokens beforehand.
    /// @param _blueprintId The ID of the blueprint to stake on.
    /// @param _amount The amount of FORGE_TOKEN to stake.
    function stakeOnBlueprint(uint256 _blueprintId, uint256 _amount) public whenNotPaused {
        Blueprint storage blueprint = blueprints[_blueprintId];
        if (blueprint.state != BlueprintState.CurationActive) revert InvalidBlueprintState();
        if (block.timestamp >= blueprint.curationPeriodEnd) revert BlueprintPeriodNotEnded();
        if (_amount < protocolParameters["MIN_CURATION_STAKE"]) revert InsufficientStake();
        if (!userProfiles[_msgSender()].initialized) revert NotInitialized();

        FORGE_TOKEN.transferFrom(_msgSender(), address(this), _amount);

        if (!blueprint.hasStaked[_msgSender()]) {
            blueprint.stakers.push(_msgSender());
            blueprint.hasStaked[_msgSender()] = true;
        }
        blueprint.totalSupportStake = blueprint.totalSupportStake.add(_amount);
        userProfiles[_msgSender()].blueprintStakes[_blueprintId] = userProfiles[_msgSender()].blueprintStakes[_blueprintId].add(_amount);

        emit BlueprintStaked(_blueprintId, _msgSender(), _amount, false);
    }

    /// @notice Users challenge a blueprint they believe is undesirable, staking against it.
    /// @dev A blueprint enters 'Challenged' state if challenge stake crosses a threshold.
    /// @param _blueprintId The ID of the blueprint to challenge.
    /// @param _reasonCID IPFS CID of the off-chain reason for challenging (optional, for transparency).
    /// @param _amount The amount of FORGE_TOKEN to stake for the challenge.
    function challengeBlueprint(uint256 _blueprintId, string calldata _reasonCID, uint256 _amount) public whenNotPaused {
        Blueprint storage blueprint = blueprints[_blueprintId];
        if (blueprint.state != BlueprintState.CurationActive) revert InvalidBlueprintState();
        if (block.timestamp >= blueprint.challengePeriodEnd) revert ChallengePeriodNotEnded();
        if (_amount < protocolParameters["MIN_CURATION_STAKE"]) revert InsufficientStake();
        if (!userProfiles[_msgSender()].initialized) revert NotInitialized();

        FORGE_TOKEN.transferFrom(_msgSender(), address(this), _amount);

        if (!blueprint.hasChallenged[_msgSender()]) {
            blueprint.challengers.push(_msgSender());
            blueprint.hasChallenged[_msgSender()] = true;
        }
        blueprint.totalChallengeStake = blueprint.totalChallengeStake.add(_amount);
        userProfiles[_msgSender()].blueprintChallengeStakes[_blueprintId] = userProfiles[_msgSender()].blueprintChallengeStakes[_blueprintId].add(_amount);

        // Check if challenge threshold is met (challenge stake is X% of support stake)
        uint256 challengeThreshold = blueprint.totalSupportStake.mul(protocolParameters["CHALLENGE_THRESHOLD_PERCENT"]).div(100);
        if (blueprint.totalChallengeStake >= challengeThreshold) {
            emit BlueprintStateChanged(_blueprintId, blueprint.state, BlueprintState.Challenged);
            blueprint.state = BlueprintState.Challenged;
        }

        emit BlueprintStaked(_blueprintId, _msgSender(), _amount, true);
    }

    /// @notice (Owner/Oracle) Resolves a challenged blueprint's fate.
    /// @dev This function is critical for resolving disputes and maintaining protocol integrity.
    /// @param _blueprintId The ID of the blueprint to resolve.
    /// @param _accept True to accept the blueprint (challenge fails), False to reject (challenge succeeds).
    function resolveChallenge(uint256 _blueprintId, bool _accept) public onlyOwnerOrOracle {
        Blueprint storage blueprint = blueprints[_blueprintId];
        if (blueprint.state != BlueprintState.Challenged) revert InvalidBlueprintState();
        if (blueprint.challengeResolved) revert InvalidBlueprintState(); // Already resolved

        BlueprintState oldState = blueprint.state;
        blueprint.challengeResolved = true;

        if (_accept) {
            emit BlueprintStateChanged(_blueprintId, oldState, BlueprintState.Accepted);
            blueprint.state = BlueprintState.Accepted;
            _updateReputation(_blueprintId, true); // Proposer and stakers are successful, challengers fail
        } else {
            emit BlueprintStateChanged(_blueprintId, oldState, BlueprintState.Rejected);
            blueprint.state = BlueprintState.Rejected;
            _updateReputation(_blueprintId, false); // Proposer and stakers fail, challengers are successful
            _distributeChallengeOutcomes(_blueprintId, true); // Refund challenge stakes
        }

        // Refund support stakes for rejected blueprints. If challenge succeeded, support stakes lost.
        // If challenge failed (blueprint accepted), support stakes proceed to reward phase.
        _cleanupStakesOnChallengeResolution(_blueprintId, _accept);

        emit ChallengeResolved(_blueprintId, _accept);
    }

    /// @notice (Owner/Oracle) Marks an 'Accepted' blueprint for AI execution.
    /// @dev Can only be called after curation period ends and blueprint is `Accepted`.
    ///      Automatically processes `CurationActive` blueprints if their period has ended.
    /// @param _blueprintId The ID of the blueprint to trigger.
    function triggerBlueprintExecution(uint256 _blueprintId) public onlyOwnerOrOracle {
        Blueprint storage blueprint = blueprints[_blueprintId];

        // First, check if a CurationActive blueprint's period has ended and auto-resolve
        if (blueprint.state == BlueprintState.CurationActive) {
            if (block.timestamp < blueprint.curationPeriodEnd) {
                revert BlueprintPeriodNotEnded(); // Curation period still active
            }
            // If curation period ended and no challenge met threshold, it's accepted by default.
            emit BlueprintStateChanged(_blueprintId, blueprint.state, BlueprintState.Accepted);
            blueprint.state = BlueprintState.Accepted;
            _updateReputation(_blueprintId, true); // All supporters and proposer are successful
        }
        
        if (blueprint.state != BlueprintState.Accepted) revert InvalidBlueprintState();
        
        emit BlueprintStateChanged(_blueprintId, blueprint.state, BlueprintState.Executing);
        blueprint.state = BlueprintState.Executing;
    }

    /// @notice Retrieves all details for a specific blueprint.
    /// @param _blueprintId The ID of the blueprint.
    /// @return A tuple containing blueprint details.
    function getBlueprintDetails(uint256 _blueprintId)
        public
        view
        returns (
            address proposer,
            string memory blueprintCID,
            uint256 creationTimestamp,
            uint256 proposalStake,
            uint256 totalSupportStake,
            uint256 totalChallengeStake,
            BlueprintState state,
            string memory resultCID,
            uint256 curationPeriodEnd,
            uint256 challengePeriodEnd,
            bool challengeResolved
        )
    {
        Blueprint storage blueprint = blueprints[_blueprintId];
        return (
            blueprint.proposer,
            blueprint.blueprintCID,
            blueprint.creationTimestamp,
            blueprint.proposalStake,
            blueprint.totalSupportStake,
            blueprint.totalChallengeStake,
            blueprint.state,
            blueprint.resultCID,
            blueprint.curationPeriodEnd,
            blueprint.challengePeriodEnd,
            blueprint.challengeResolved
        );
    }

    /// @notice Retrieves a user's stake on a specific blueprint (both support and challenge).
    /// @param _blueprintId The ID of the blueprint.
    /// @param _user The address of the user.
    /// @return A tuple containing the user's support stake and challenge stake.
    function getUserBlueprintStake(uint256 _blueprintId, address _user) public view returns (uint256 supportStake, uint256 challengeStake) {
        return (userProfiles[_user].blueprintStakes[_blueprintId], userProfiles[_user].blueprintChallengeStakes[_blueprintId]);
    }

    /// @notice Returns the current state of a blueprint.
    /// @param _blueprintId The ID of the blueprint.
    /// @return The current BlueprintState.
    function getBlueprintState(uint256 _blueprintId) public view returns (BlueprintState) {
        return blueprints[_blueprintId].state;
    }

    /// @notice Provides a summary of total 'for' and 'against' stakes on a blueprint.
    /// @param _blueprintId The ID of the blueprint.
    /// @return A tuple containing total support stake and total challenge stake.
    function getBlueprintStakeSummary(uint256 _blueprintId) public view returns (uint256 totalSupport, uint256 totalChallenge) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        return (blueprint.totalSupportStake, blueprint.totalChallengeStake);
    }

    // IV. Oracle Interaction & Content Proof

    /// @notice (Oracle) Submits the AI-generated content hash for an executed blueprint.
    /// @dev Only callable by the designated oracle address. This transitions blueprint to `Executed`.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _resultCID IPFS CID of the AI-generated content.
    function submitBlueprintResult(uint256 _blueprintId, string calldata _resultCID) public onlyOracle {
        Blueprint storage blueprint = blueprints[_blueprintId];
        if (blueprint.state != BlueprintState.Executing) revert InvalidBlueprintState();

        blueprint.resultCID = _resultCID;
        emit BlueprintStateChanged(_blueprintId, blueprint.state, BlueprintState.Executed);
        blueprint.state = BlueprintState.Executed;

        // Distribute rewards to successful stakers and the proposer
        _distributeRewardsAndRefundStakes(_blueprintId);

        emit BlueprintExecuted(_blueprintId, _resultCID);
    }

    /// @notice Retrieves the content proof CID for an executed blueprint.
    /// @param _blueprintId The ID of the blueprint.
    /// @return The IPFS CID of the generated content, or an empty string if not executed.
    function getContentProofCID(uint256 _blueprintId) public view returns (string memory) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        if (blueprint.state != BlueprintState.Executed) return "";
        return blueprint.resultCID;
    }

    // V. Reward & Incentive Mechanisms

    /// @notice (Internal) Distributes rewards to successful stakers/proposer and refunds all stakes for an executed blueprint.
    /// @param _blueprintId The ID of the blueprint.
    function _distributeRewardsAndRefundStakes(uint256 _blueprintId) internal {
        Blueprint storage blueprint = blueprints[_blueprintId];
        if (blueprint.state != BlueprintState.Executed) return;

        uint256 totalSupportStaked = blueprint.totalSupportStake;
        if (totalSupportStaked == 0) return;

        // Calculate the total reward pool based on a percentage of total support stake.
        uint256 rewardPool = totalSupportStaked.mul(protocolParameters["REWARD_PERCENT_OF_STAKE"]).div(100);
        
        // Refund proposer's initial stake
        uint256 proposerStake = userProfiles[blueprint.proposer].blueprintStakes[_blueprintId];
        if (proposerStake > 0) {
            FORGE_TOKEN.transfer(blueprint.proposer, proposerStake);
            userProfiles[blueprint.proposer].blueprintStakes[_blueprintId] = 0;
            // Proposer also gets a share of rewards
            uint256 proposerReward = rewardPool.mul(proposerStake).div(totalSupportStaked);
            userProfiles[blueprint.proposer].pendingRewards = userProfiles[blueprint.proposer].pendingRewards.add(proposerReward);
        }

        // Refund other stakers and distribute their share of rewards
        for (uint256 i = 0; i < blueprint.stakers.length; i++) {
            address staker = blueprint.stakers[i];
            uint256 stakerStake = userProfiles[staker].blueprintStakes[_blueprintId];
            if (stakerStake > 0) {
                FORGE_TOKEN.transfer(staker, stakerStake);
                userProfiles[staker].blueprintStakes[_blueprintId] = 0;
                uint256 stakerReward = rewardPool.mul(stakerStake).div(totalSupportStaked);
                userProfiles[staker].pendingRewards = userProfiles[staker].pendingRewards.add(stakerReward);
            }
        }
        
        // If there were any challengers for an 'Executed' blueprint, it means they failed.
        // For simplicity, refund their stakes, but they incur reputation penalty.
        for (uint256 i = 0; i < blueprint.challengers.length; i++) {
            address challenger = blueprint.challengers[i];
            uint256 challengerStake = userProfiles[challenger].blueprintChallengeStakes[_blueprintId];
            if (challengerStake > 0) {
                FORGE_TOKEN.transfer(challenger, challengerStake);
                userProfiles[challenger].blueprintChallengeStakes[_blueprintId] = 0;
            }
        }
    }

    /// @notice (Internal) Distributes challenge outcomes for rejected blueprints.
    /// @dev Refunds challenge stakes if challenge was successful.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _challengeWasSuccessful True if the challenge was successful, false if it failed.
    function _distributeChallengeOutcomes(uint256 _blueprintId, bool _challengeWasSuccessful) internal {
        Blueprint storage blueprint = blueprints[_blueprintId];

        // Refund all support stakes (proposer and other stakers) if blueprint was rejected.
        for (uint256 i = 0; i < blueprint.stakers.length; i++) {
            address staker = blueprint.stakers[i];
            uint256 stake = userProfiles[staker].blueprintStakes[_blueprintId];
            if (stake > 0) {
                FORGE_TOKEN.transfer(staker, stake);
                userProfiles[staker].blueprintStakes[_blueprintId] = 0;
            }
        }

        if (_challengeWasSuccessful) {
            // Challenge succeeded: Refund challenge stakes
            for (uint256 i = 0; i < blueprint.challengers.length; i++) {
                address challenger = blueprint.challengers[i];
                uint256 stake = userProfiles[challenger].blueprintChallengeStakes[_blueprintId];
                if (stake > 0) {
                    FORGE_TOKEN.transfer(challenger, stake);
                    userProfiles[challenger].blueprintChallengeStakes[_blueprintId] = 0;
                    // Optional: Add a small reward for successful challenge
                    // userProfiles[challenger].pendingRewards = userProfiles[challenger].pendingRewards.add(stake.div(10));
                }
            }
        }
    }

    /// @notice (Internal) Cleans up stakes after challenge resolution, ensuring appropriate refunds or transfers.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _blueprintAccepted True if the blueprint was accepted (challenge failed), false if rejected (challenge succeeded).
    function _cleanupStakesOnChallengeResolution(uint256 _blueprintId, bool _blueprintAccepted) internal {
        Blueprint storage blueprint = blueprints[_blueprintId];

        if (_blueprintAccepted) {
            // Blueprint was accepted (challenge failed):
            // Support stakes remain in contract, waiting for execution/rewards.
            // Challenger stakes are refunded (as they lost the challenge, but principle is returned).
            for (uint256 i = 0; i < blueprint.challengers.length; i++) {
                address challenger = blueprint.challengers[i];
                uint256 stake = userProfiles[challenger].blueprintChallengeStakes[_blueprintId];
                if (stake > 0) {
                    FORGE_TOKEN.transfer(challenger, stake);
                    userProfiles[challenger].blueprintChallengeStakes[_blueprintId] = 0;
                }
            }
        } else {
            // Blueprint was rejected (challenge succeeded):
            // Support stakes (proposer and stakers) are fully refunded.
            // Challenger stakes are fully refunded.
            _distributeChallengeOutcomes(_blueprintId, true); // This handles refunding all stakes
        }
    }

    /// @notice (Internal) Updates reputation scores based on blueprint outcome.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _success True if the blueprint was accepted/executed, false if rejected/challenge succeeded.
    function _updateReputation(uint256 _blueprintId, bool _success) internal {
        Blueprint storage blueprint = blueprints[_blueprintId];
        uint256 reputationBoost = protocolParameters["REPUTATION_BOOST_FACTOR"];
        uint256 reputationPenalty = protocolParameters["REPUTATION_PENALTY_FACTOR"];

        // Proposer's reputation
        if (userProfiles[blueprint.proposer].initialized) {
            if (_success) {
                userProfiles[blueprint.proposer].reputationScore = userProfiles[blueprint.proposer].reputationScore.add(reputationBoost);
            } else {
                userProfiles[blueprint.proposer].reputationScore = userProfiles[blueprint.proposer].reputationScore.sub(reputationPenalty);
            }
        }

        // Stakers' reputation
        for (uint256 i = 0; i < blueprint.stakers.length; i++) {
            address staker = blueprint.stakers[i];
            if (userProfiles[staker].initialized) {
                if (userProfiles[staker].blueprintStakes[_blueprintId] > 0) { // Check if they actually staked
                    if (_success) {
                        userProfiles[staker].reputationScore = userProfiles[staker].reputationScore.add(reputationBoost.div(2)); // Less than proposer
                    } else {
                        userProfiles[staker].reputationScore = userProfiles[staker].reputationScore.sub(reputationPenalty.div(2));
                    }
                }
            }
        }

        // Challengers' reputation
        for (uint256 i = 0; i < blueprint.challengers.length; i++) {
            address challenger = blueprint.challengers[i];
            if (userProfiles[challenger].initialized) {
                if (userProfiles[challenger].blueprintChallengeStakes[_blueprintId] > 0) { // Check if they actually challenged
                    if (!_success) { // Challenger was successful (blueprint failed)
                        userProfiles[challenger].reputationScore = userProfiles[challenger].reputationScore.add(reputationBoost);
                    } else { // Challenger failed (blueprint succeeded)
                        userProfiles[challenger].reputationScore = userProfiles[challenger].reputationScore.sub(reputationPenalty);
                    }
                }
            }
        }
    }

    /// @notice Allows a user to claim all accumulated rewards across all their participations.
    function claimAllUserRewards() public whenNotPaused {
        address sender = _msgSender();
        if (!userProfiles[sender].initialized) revert NotInitialized();

        uint256 amount = userProfiles[sender].pendingRewards;
        if (amount == 0) revert NoRewardsToClaim();

        userProfiles[sender].pendingRewards = 0; // Reset pending rewards before transfer
        FORGE_TOKEN.transfer(sender, amount);

        emit RewardsClaimed(sender, 0, amount); // BlueprintId 0 for overall claims
    }

    // VI. Protocol Parameter Adjustment

    /// @notice Allows the owner to adjust various configurable parameters.
    /// @param _paramName The name of the parameter (e.g., "MIN_PROPOSAL_STAKE").
    /// @param _newValue The new value for the parameter.
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        // Basic sanity check, more complex validation logic could be added for specific parameters
        if (_newValue == 0 && _paramName != "FEE_RECIPIENT_ADDRESS") { 
             // Allow setting address to zero, but most other parameters should be > 0
             if (_paramName != "PROPOSAL_FEE_PERCENT" && _paramName != "REWARD_PERCENT_OF_STAKE") {
                 revert InvalidParameterValue();
             }
        }
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, _newValue);
    }

    /// @notice Retrieves the value of a specific protocol parameter.
    /// @param _paramName The name of the parameter.
    /// @return The current value of the parameter.
    function getProtocolParameter(bytes32 _paramName) public view returns (uint256) {
        return protocolParameters[_paramName];
    }

    /// @notice Allows owner to retrieve accidentally sent ERC20 tokens.
    /// @dev This function prevents accidental loss of ERC20 tokens sent directly to the contract.
    ///      It explicitly prevents rescuing the contract's primary FORGE_TOKEN.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _amount The amount of tokens to rescue.
    function rescueERC20(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_tokenAddress == address(FORGE_TOKEN)) revert ForbiddenTokenRescue();
        if (_tokenAddress == address(0)) revert ZeroAddress();
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }

    // --- Modifiers ---
    /// @dev Access control for functions callable by either the contract owner or the designated oracle.
    modifier onlyOwnerOrOracle() {
        if (_msgSender() != owner() && _msgSender() != oracleAddress) {
            revert Unauthorized();
        }
        _;
    }

    /// @dev Access control for functions callable only by the designated oracle.
    modifier onlyOracle() {
        if (_msgSender() != oracleAddress) {
            revert UnauthorizedOracle();
        }
        _;
    }
}
```