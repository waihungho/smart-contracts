Okay, here is a smart contract concept called `CryptoNexus`, designed with a focus on a dynamic, community-driven content/idea curation system that incorporates reputation, staking, time-based decay, and a simplified parameter suggestion mechanism.

It's not a standard ERC20, NFT, or pure DeFi protocol. It's more of a decentralized coordination/curation layer.

---

**Contract Name:** `CryptoNexus`

**Concept:** A decentralized platform where users can submit, endorse, and challenge "Artifacts" (abstract ideas, links, digital assets represented by a hash/ID). User reputation within the Nexus is earned based on their successful participation (endorsing valuable artifacts, submitting popular ones). The system incorporates time-based decay and dynamic scoring. Parameters of the Nexus can be suggested and potentially updated via a simple, reputation-weighted process.

**Key Advanced/Creative Concepts:**

1.  **Reputation System:** An internal, non-transferable score reflecting user's positive engagement.
2.  **Dynamic Artifact Scoring:** Artifacts have a score that changes based on endorsements, challenges, and time decay.
3.  **Time-Based Decay:** Artifact influence and endorsements naturally decay over time, encouraging fresh content and discouraging stagnation.
4.  **Staked Endorsement/Challenge:** Users put stake behind their opinions (endorsements or challenges), which can be rewarded or penalized.
5.  **Parameter Suggestion:** A mechanism for high-reputation users to suggest changes to contract constants.
6.  **Batch Processing:** Functions to handle decay and cleanup for multiple items efficiently (or semi-efficiently within gas limits).
7.  **Internal State Lifecycle:** Artifacts and suggestions move through different states (Active, Challenged, Resolved, Expired).

**Outline & Function Summary:**

*   **Initialization & Parameters:**
    *   `initializeParameters`: Sets initial, core parameters of the Nexus (admin function).
    *   `getNexusParameters`: Reads current Nexus parameters.
    *   `suggestParameterChange`: Propose a change to a Nexus parameter (requires reputation).
    *   `endorseParameterSuggestion`: Stake reputation to support a parameter change suggestion.
    *   `withdrawParameterSuggestionEndorsement`: Remove support for a suggestion.
    *   `applyParameterSuggestion`: Apply a parameter suggestion that has met criteria (can be triggered by anyone if conditions met, or admin).
    *   `getParameterSuggestionDetails`: Get details of a specific parameter suggestion.
    *   `getSuggestionStatus`: Get the current lifecycle status of a suggestion.

*   **Contributor Management:**
    *   `becomeContributor`: Stake ETH to become a contributor.
    *   `withdrawContributorStake`: Withdraw contributor stake (conditional on no active commitments).
    *   `getContributorStatus`: Check if an address is a contributor.
    *   `getUserReputation`: Get the reputation points for a user.
    *   `claimReputation`: Claim earned reputation rewards.
    *   `getEligibleReputationAmount`: Calculate potential claimable reputation.

*   **Artifact Management & Interaction:**
    *   `submitArtifact`: Submit a new artifact (requires contributor status and fee).
    *   `endorseArtifact`: Stake ETH to endorse an artifact (requires contributor status).
    *   `unendorseArtifact`: Remove an endorsement (might have conditions/penalties).
    *   `challengeArtifact`: Stake ETH to challenge an artifact (requires contributor status).
    *   `resolveArtifact`: Finalize the state of an artifact (e.g., after challenge period, or sufficient decay).
    *   `getArtifactDetails`: Get comprehensive details of an artifact.
    *   `getArtifactStatus`: Get the current lifecycle status of an artifact.
    *   `getArtifactScore`: Calculate the current dynamic score of an artifact.
    *   `getArtifactEndorsements`: Get list of active endorsers for an artifact.
    *   `getArtifactChallenges`: Get list of active challengers for an artifact.

*   **Staking & Claiming:**
    *   `claimStakes`: Claim back staked ETH from resolved/expired artifacts/endorsements.
    *   `getUserActiveEndorsements`: List active endorsement IDs for a user.
    *   `getEligibleStakeAmount`: Calculate total reclaimable stakes for a user.
    *   `getTotalStakedETH`: Get the total ETH currently staked in the contract.

*   **Maintenance & Utility:**
    *   `applyDecayAndCleanup`: Manually trigger decay and cleanup for artifacts and suggestions (can be called by anyone, costs gas). Processes items in batches.
    *   `getUserSubmittedArtifacts`: List artifact IDs submitted by a user.

*   **Admin & Safety:**
    *   `pauseNexus`: Admin function to pause key interactions.
    *   `unpauseNexus`: Admin function to unpause.
    *   `emergencyWithdrawEth`: Admin function to withdraw accrued ETH (e.g., fees, unclaimed stakes that default).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline & Function Summary is provided at the top of this document.

contract CryptoNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Enums ---
    enum ArtifactStatus {
        Active,
        Challenged,
        ResolvedAccepted,
        ResolvedRejected,
        Expired
    }

    enum SuggestionStatus {
        Pending,
        Accepted,
        Rejected,
        Applied
    }

    // --- Structs ---
    struct NexusParameters {
        uint256 contributorStakeAmount; // ETH required to become a contributor
        uint256 artifactSubmissionFee;  // ETH fee to submit an artifact
        uint256 endorsementStakeAmount; // ETH staked per endorsement
        uint256 challengeStakeAmount;   // ETH staked per challenge
        uint256 challengePeriodDuration; // Duration in seconds for a challenge to be active
        uint256 resolutionQuorumPercent; // Percentage of endorsement stake required for quick resolution (placeholder logic)
        uint256 reputationMultiplier;    // Multiplier for reputation gain
        uint256 decayRatePerSecond;      // Rate at which artifact score decays
        uint256 maxArtifactAge;          // Max age before an artifact becomes eligible for cleanup
        uint256 minReputationForSuggestion; // Min reputation required to suggest a parameter change
        uint256 suggestionEndorsementThreshold; // Reputation points needed to accept a suggestion
        uint256 suggestionVotingPeriod; // Duration for parameter suggestions
        uint256 cleanupBatchSize;        // Number of items to process per cleanup call
        uint256 unstakeCooldownPeriod;   // Cooldown period for withdrawing contributor stake
    }

    struct Artifact {
        uint256 id;
        bytes32 artifactHash; // Represents the content/idea
        address submitter;
        uint256 submissionTime;
        ArtifactStatus status;
        uint256 totalEndorsementStake; // Sum of all active endorsement stakes
        uint256 totalChallengeStake;   // Sum of all active challenge stakes
        uint256 lastInteractionTime;   // Time of last endorsement/challenge/decay
        uint256 resolvedTime;          // Time artifact was resolved
        address[] activeEndorsers;     // List of addresses actively endorsing
        address[] activeChallengers;    // List of addresses actively challenging
        uint256 challengeEndTime;      // End time of the challenge period if challenged
    }

     struct ParameterSuggestion {
        uint256 id;
        address proposer;
        bytes32 paramName;          // Name of the parameter being suggested (e.g., keccak256("contributorStakeAmount"))
        uint256 newValue;           // The proposed new value
        SuggestionStatus status;
        uint256 submissionTime;
        uint256 votingEndTime;
        mapping(address => uint256) reputationEndorsements; // Reputation staked on this suggestion by user
        uint256 totalReputationEndorsed; // Total reputation staked endorsing this suggestion
    }

    // --- State Variables ---
    NexusParameters public nexusParameters;
    uint256 private nextArtifactId = 1;
    mapping(uint256 => Artifact) public artifacts;
    mapping(address => uint256) public userReputation;
    mapping(address => bool) public isContributor;
    mapping(address => uint256) public contributorStake;
    mapping(address => uint256) public contributorUnstakeCooldown; // Time when cooldown ends

    // Mapping user => artifactId => endorsement stake (for tracking individual stakes)
    mapping(address => mapping(uint256 => uint256)) private userArtifactEndorsementStake;
    // Mapping user => artifactId => challenge stake (for tracking individual stakes)
    mapping(address => mapping(uint256 => uint256)) private userArtifactChallengeStake;
    // Mapping user => list of artifact IDs they've endorsed
    mapping(address => uint256[]) private userEndorsedArtifacts;
    // Mapping user => list of artifact IDs they've challenged
    mapping(address => uint256[]) private userChallengedArtifacts;
    // Mapping user => list of artifact IDs they submitted
    mapping(address => uint256[]) private userSubmittedArtifactsList;


    uint256 private nextSuggestionId = 1;
    mapping(uint256 => ParameterSuggestion) public parameterSuggestions;
    mapping(bytes32 => uint256) private currentParameterValues; // Store active parameter values by hash of name

    uint256[] private activeArtifactIds; // Simplified list for iteration/cleanup
    uint256[] private activeSuggestionIds; // Simplified list for iteration/cleanup

    // --- Events ---
    event ParametersInitialized(NexusParameters params);
    event ParameterSuggestionMade(uint256 suggestionId, bytes32 paramName, uint256 newValue, address proposer);
    event ParameterSuggestionEndorsed(uint256 suggestionId, address endorser, uint256 reputationStaked);
    event ParameterSuggestionEndorsementWithdrawn(uint256 suggestionId, address endorser, uint256 reputationReturned);
    event ParameterSuggestionApplied(uint256 suggestionId, bytes32 paramName, uint256 oldValue, uint256 newValue);
    event ContributorJoined(address contributor, uint256 stakeAmount);
    event ContributorStakeWithdrawn(address contributor, uint256 stakeAmount);
    event ArtifactSubmitted(uint256 artifactId, bytes32 artifactHash, address submitter, uint256 submissionTime);
    event ArtifactEndorsed(uint256 artifactId, address endorser, uint256 stakeAmount);
    event ArtifactUnendorsed(uint256 artifactId, address endorser, uint256 returnedStake);
    event ArtifactChallenged(uint256 artifactId, address challenger, uint256 stakeAmount);
    event ArtifactResolved(uint256 artifactId, ArtifactStatus newStatus, uint256 resolvedTime);
    event ReputationClaimed(address user, uint256 amount);
    event StakeClaimed(address user, uint256 amount);
    event DecayApplied(uint256[] artifactIds, uint256 decayedCount);
    event CleanupPerformed(uint256 artifactCount, uint256 suggestionCount);
    event NexusPaused(address account);
    event NexusUnpaused(address account);
    event EmergencyETHWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyContributor() {
        require(isContributor[msg.sender], "CryptoNexus: Not a contributor");
        _;
    }

    modifier onlyArtifactExists(uint256 _artifactId) {
        require(_artifactId > 0 && _artifactId < nextArtifactId, "CryptoNexus: Invalid Artifact ID");
        _;
    }

    modifier onlySuggestionExists(uint256 _suggestionId) {
        require(_suggestionId > 0 && _suggestionId < nextSuggestionId, "CryptoNexus: Invalid Suggestion ID");
        _;
    }

    modifier artifactInStatus(uint256 _artifactId, ArtifactStatus _status) {
         require(artifacts[_artifactId].status == _status, "CryptoNexus: Artifact not in required status");
         _;
    }

    modifier suggestionInStatus(uint256 _suggestionId, SuggestionStatus _status) {
         require(parameterSuggestions[_suggestionId].status == _status, "CryptoNexus: Suggestion not in required status");
         _;
    }


    // --- Constructor ---
    constructor(
        uint256 _contributorStakeAmount,
        uint256 _artifactSubmissionFee,
        uint256 _endorsementStakeAmount,
        uint256 _challengeStakeAmount,
        uint256 _challengePeriodDuration,
        uint256 _resolutionQuorumPercent,
        uint256 _reputationMultiplier,
        uint256 _decayRatePerSecond,
        uint256 _maxArtifactAge,
        uint256 _minReputationForSuggestion,
        uint256 _suggestionEndorsementThreshold,
        uint256 _suggestionVotingPeriod,
        uint256 _cleanupBatchSize,
        uint256 _unstakeCooldownPeriod
    ) Ownable(msg.sender) {
        initializeParameters(
            _contributorStakeAmount,
            _artifactSubmissionFee,
            _endorsementStakeAmount,
            _challengeStakeAmount,
            _challengePeriodDuration,
            _resolutionQuorumPercent,
            _reputationMultiplier,
            _decayRatePerSecond,
            _maxArtifactAge,
            _minReputationForSuggestion,
            _suggestionEndorsementThreshold,
            _suggestionVotingPeriod,
            _cleanupBatchSize,
            _unstakeCooldownPeriod
        );
    }

    // --- Initialization & Parameters ---

    /// @notice Initializes or updates the core parameters of the CryptoNexus. Can only be called once initially by the owner.
    /// @param _contributorStakeAmount ETH required to become a contributor.
    /// @param _artifactSubmissionFee ETH fee to submit an artifact.
    /// @param _endorsementStakeAmount ETH staked per endorsement.
    /// @param _challengeStakeAmount ETH staked per challenge.
    /// @param _challengePeriodDuration Duration in seconds for a challenge.
    /// @param _resolutionQuorumPercent Percentage of endorsement stake for quick resolution (simplified).
    /// @param _reputationMultiplier Multiplier for reputation gain.
    /// @param _decayRatePerSecond Rate at which artifact score decays per second.
    /// @param _maxArtifactAge Max age before cleanup eligibility.
    /// @param _minReputationForSuggestion Min reputation to suggest parameter change.
    /// @param _suggestionEndorsementThreshold Reputation points needed to accept a suggestion.
    /// @param _suggestionVotingPeriod Duration for parameter suggestions.
    /// @param _cleanupBatchSize Number of items processed in cleanup.
    /// @param _unstakeCooldownPeriod Cooldown for contributor stake withdrawal.
    function initializeParameters(
        uint256 _contributorStakeAmount,
        uint256 _artifactSubmissionFee,
        uint256 _endorsementStakeAmount,
        uint256 _challengeStakeAmount,
        uint256 _challengePeriodDuration,
        uint256 _resolutionQuorumPercent,
        uint256 _reputationMultiplier,
        uint256 _decayRatePerSecond,
        uint256 _maxArtifactAge,
        uint256 _minReputationForSuggestion,
        uint256 _suggestionEndorsementThreshold,
        uint256 _suggestionVotingPeriod,
        uint256 _cleanupBatchSize,
        uint256 _unstakeCooldownPeriod
    ) public onlyOwner {
        require(nexusParameters.contributorStakeAmount == 0, "CryptoNexus: Parameters already initialized"); // Simple check for first-time init

        nexusParameters = NexusParameters({
            contributorStakeAmount: _contributorStakeAmount,
            artifactSubmissionFee: _artifactSubmissionFee,
            endorsementStakeAmount: _endorsementStakeAmount,
            challengeStakeAmount: _challengeStakeAmount,
            challengePeriodDuration: _challengePeriodDuration,
            resolutionQuorumPercent: _resolutionQuorumPercent, // Simplified: needs more complex logic for real use
            reputationMultiplier: _reputationMultiplier,
            decayRatePerSecond: _decayRatePerSecond,
            maxArtifactAge: _maxArtifactAge,
            minReputationForSuggestion: _minReputationForSuggestion,
            suggestionEndorsementThreshold: _suggestionEndorsementThreshold,
            suggestionVotingPeriod: _suggestionVotingPeriod,
            cleanupBatchSize: _cleanupBatchSize,
            unstakeCooldownPeriod: _unstakeCooldownPeriod
        });

        // Store initial parameters in the dynamic mapping for lookup
        currentParameterValues[keccak256("contributorStakeAmount")] = _contributorStakeAmount;
        currentParameterValues[keccak256("artifactSubmissionFee")] = _artifactSubmissionFee;
        currentParameterValues[keccak256("endorsementStakeAmount")] = _endorsementStakeAmount;
        currentParameterValues[keccak256("challengeStakeAmount")] = _challengeStakeAmount;
        currentParameterValues[keccak256("challengePeriodDuration")] = _challengePeriodDuration;
        currentParameterValues[keccak256("resolutionQuorumPercent")] = _resolutionQuorumPercent;
        currentParameterValues[keccak256("reputationMultiplier")] = _reputationMultiplier;
        currentParameterValues[keccak256("decayRatePerSecond")] = _decayRatePerSecond;
        currentParameterValues[keccak256("maxArtifactAge")] = _maxArtifactAge;
        currentParameterValues[keccak256("minReputationForSuggestion")] = _minReputationForSuggestion;
        currentParameterValues[keccak256("suggestionEndorsementThreshold")] = _suggestionEndorsementThreshold;
        currentParameterValues[keccak256("suggestionVotingPeriod")] = _suggestionVotingPeriod;
        currentParameterValues[keccak256("cleanupBatchSize")] = _cleanupBatchSize;
        currentParameterValues[keccak256("unstakeCooldownPeriod")] = _unstakeCooldownPeriod;


        emit ParametersInitialized(nexusParameters);
    }

    /// @notice Gets the current values of all Nexus parameters.
    /// @return NexusParameters struct with current values.
    function getNexusParameters() public view returns (NexusParameters memory) {
         return nexusParameters; // Returns the struct directly
         // Or, to get values from the dynamic map:
         /*
         return NexusParameters({
            contributorStakeAmount: currentParameterValues[keccak256("contributorStakeAmount")],
            artifactSubmissionFee: currentParameterValues[keccak256("artifactSubmissionFee")],
            endorsementStakeAmount: currentParameterValues[keccak256("endorsementStakeAmount")],
            challengeStakeAmount: currentParameterValues[keccak256("challengeStakeAmount")],
            challengePeriodDuration: currentParameterValues[keccak256("challengePeriodDuration")],
            resolutionQuorumPercent: currentParameterValues[keccak256("resolutionQuorumPercent")],
            reputationMultiplier: currentParameterValues[keccak256("reputationMultiplier")],
            decayRatePerSecond: currentParameterValues[keccak256("decayRatePerSecond")],
            maxArtifactAge: currentParameterValues[keccak256("maxArtifactAge")],
            minReputationForSuggestion: currentParameterValues[keccak256("minReputationForSuggestion")],
            suggestionEndorsementThreshold: currentParameterValues[keccak256("suggestionEndorsementThreshold")],
            suggestionVotingPeriod: currentParameterValues[keccak256("suggestionVotingPeriod")],
            cleanupBatchSize: currentParameterValues[keccak256("cleanupBatchSize")],
            unstakeCooldownPeriod: currentParameterValues[keccak256("unstakeCooldownPeriod")]
         });
         */
    }

    /// @notice Suggests a change to a Nexus parameter. Requires minimum reputation.
    /// @param paramNameHash The keccak256 hash of the parameter name (e.g., keccak256("contributorStakeAmount")).
    /// @param newValue The proposed new value for the parameter.
    function suggestParameterChange(bytes32 paramNameHash, uint256 newValue) external whenNotPaused nonReentrancy {
        require(userReputation[msg.sender] >= nexusParameters.minReputationForSuggestion, "CryptoNexus: Insufficient reputation for suggestion");
        require(newValue > 0, "CryptoNexus: New value must be positive"); // Basic validation

        uint256 suggestionId = nextSuggestionId++;
        ParameterSuggestion storage suggestion = parameterSuggestions[suggestionId];

        suggestion.id = suggestionId;
        suggestion.proposer = msg.sender;
        suggestion.paramName = paramNameHash;
        suggestion.newValue = newValue;
        suggestion.status = SuggestionStatus.Pending;
        suggestion.submissionTime = block.timestamp;
        suggestion.votingEndTime = block.timestamp + nexusParameters.suggestionVotingPeriod;
        suggestion.totalReputationEndorsed = 0;

        activeSuggestionIds.push(suggestionId);

        emit ParameterSuggestionMade(suggestionId, paramNameHash, newValue, msg.sender);
    }

    /// @notice Endorse a parameter change suggestion by staking reputation.
    /// @param suggestionId The ID of the suggestion to endorse.
    function endorseParameterSuggestion(uint256 suggestionId) external whenNotPaused nonReentrancy onlySuggestionExists(suggestionId) suggestionInStatus(suggestionId, SuggestionStatus.Pending) {
        ParameterSuggestion storage suggestion = parameterSuggestions[suggestionId];
        require(userReputation[msg.sender] > 0, "CryptoNexus: No reputation to stake");
        require(suggestion.reputationEndorsements[msg.sender] == 0, "CryptoNexus: Already endorsed this suggestion");
        require(block.timestamp < suggestion.votingEndTime, "CryptoNexus: Suggestion voting period has ended");

        uint256 reputationToStake = userReputation[msg.sender];
        userReputation[msg.sender] = 0; // Stake all current reputation

        suggestion.reputationEndorsements[msg.sender] = reputationToStake;
        suggestion.totalReputationEndorsed += reputationToStake;

        // Check if suggestion is accepted (simplified logic: based on total reputation staked)
        if (suggestion.totalReputationEndorsed >= nexusParameters.suggestionEndorsementThreshold) {
            suggestion.status = SuggestionStatus.Accepted;
            // Note: Application happens via applyParameterSuggestion
        }

        emit ParameterSuggestionEndorsed(suggestionId, msg.sender, reputationToStake);
    }

    /// @notice Withdraw endorsement stake from a parameter suggestion if the voting period is not over.
    /// @param suggestionId The ID of the suggestion.
    function withdrawParameterSuggestionEndorsement(uint256 suggestionId) external whenNotPaused nonReentrancy onlySuggestionExists(suggestionId) {
        ParameterSuggestion storage suggestion = parameterSuggestions[suggestionId];
        require(suggestion.reputationEndorsements[msg.sender] > 0, "CryptoNexus: No active endorsement for this suggestion from user");
        require(block.timestamp < suggestion.votingEndTime, "CryptoNexus: Cannot withdraw endorsement after voting period ends");
        require(suggestion.status == SuggestionStatus.Pending, "CryptoNexus: Suggestion is no longer pending");


        uint256 stakedReputation = suggestion.reputationEndorsements[msg.sender];
        suggestion.reputationEndorsements[msg.sender] = 0;
        suggestion.totalReputationEndorsed -= stakedReputation;
        userReputation[msg.sender] += stakedReputation; // Return reputation

        emit ParameterSuggestionEndorsementWithdrawn(suggestionId, msg.sender, stakedReputation);
    }

    /// @notice Applies an accepted parameter suggestion. Can be called by anyone once conditions are met or by owner.
    /// @dev Simplified: Requires Accepted status and voting period passed (or callable by owner anytime after Accepted).
    /// @param suggestionId The ID of the suggestion to apply.
    function applyParameterSuggestion(uint256 suggestionId) external whenNotPaused nonReentrancy onlySuggestionExists(suggestionId) {
        ParameterSuggestion storage suggestion = parameterSuggestions[suggestionId];
        require(suggestion.status == SuggestionStatus.Accepted, "CryptoNexus: Suggestion not in Accepted status");
        // Optional: require(block.timestamp >= suggestion.votingEndTime, "CryptoNexus: Voting period not over yet"); // Can add this to force delay

        bytes32 paramHash = suggestion.paramName;
        uint256 oldValue = currentParameterValues[paramHash];

        // Directly update the parameter struct and the dynamic mapping
        if (paramHash == keccak256("contributorStakeAmount")) nexusParameters.contributorStakeAmount = suggestion.newValue;
        else if (paramHash == keccak256("artifactSubmissionFee")) nexusParameters.artifactSubmissionFee = suggestion.newValue;
        else if (paramHash == keccak256("endorsementStakeAmount")) nexusParameters.endorsementStakeAmount = suggestion.newValue;
        else if (paramHash == keccak256("challengeStakeAmount")) nexusParameters.challengeStakeAmount = suggestion.newValue;
        else if (paramHash == keccak256("challengePeriodDuration")) nexusParameters.challengePeriodDuration = suggestion.newValue;
        else if (paramHash == keccak256("resolutionQuorumPercent")) nexusParameters.resolutionQuorumPercent = suggestion.newValue;
        else if (paramHash == keccak256("reputationMultiplier")) nexusParameters.reputationMultiplier = suggestion.newValue;
        else if (paramHash == keccak256("decayRatePerSecond")) nexusParameters.decayRatePerSecond = suggestion.newValue;
        else if (paramHash == keccak256("maxArtifactAge")) nexusParameters.maxArtifactAge = suggestion.newValue;
        else if (paramHash == keccak256("minReputationForSuggestion")) nexusParameters.minReputationForSuggestion = suggestion.newValue;
        else if (paramHash == keccak256("suggestionEndorsementThreshold")) nexusParameters.suggestionEndorsementThreshold = suggestion.newValue;
        else if (paramHash == keccak256("suggestionVotingPeriod")) nexusParameters.suggestionVotingPeriod = suggestion.newValue;
         else if (paramHash == keccak256("cleanupBatchSize")) nexusParameters.cleanupBatchSize = suggestion.newValue;
        else if (paramHash == keccak256("unstakeCooldownPeriod")) nexusParameters.unstakeCooldownPeriod = suggestion.newValue;
        else {
            // Should not happen if paramNameHash is correct
            revert("CryptoNexus: Unknown parameter hash");
        }

        currentParameterValues[paramHash] = suggestion.newValue; // Update dynamic map

        suggestion.status = SuggestionStatus.Applied;

        // Return staked reputation to proposers/endorsers (simplified: return 100%)
        for(address endorser : _getParameterSuggestionEndorsers(suggestionId)) {
            uint256 staked = suggestion.reputationEndorsements[endorser];
            if(staked > 0) {
                 suggestion.reputationEndorsements[endorser] = 0; // Clear their stake
                 userReputation[endorser] += staked; // Return staked amount
            }
        }
         suggestion.totalReputationEndorsed = 0; // Reset total

        emit ParameterSuggestionApplied(suggestionId, paramHash, oldValue, suggestion.newValue);
    }

    /// @notice Gets the details of a parameter suggestion.
    /// @param suggestionId The ID of the suggestion.
    /// @return id, proposer, paramNameHash, newValue, status, submissionTime, votingEndTime, totalReputationEndorsed.
    function getParameterSuggestionDetails(uint256 suggestionId) public view onlySuggestionExists(suggestionId) returns (uint256 id, address proposer, bytes32 paramNameHash, uint256 newValue, SuggestionStatus status, uint256 submissionTime, uint256 votingEndTime, uint256 totalReputationEndorsed) {
        ParameterSuggestion storage suggestion = parameterSuggestions[suggestionId];
        return (
            suggestion.id,
            suggestion.proposer,
            suggestion.paramName,
            suggestion.newValue,
            suggestion.status,
            suggestion.submissionTime,
            suggestion.votingEndTime,
            suggestion.totalReputationEndorsed
        );
    }

    /// @notice Gets the current status of a parameter suggestion.
    /// @param suggestionId The ID of the suggestion.
    /// @return The SuggestionStatus.
    function getSuggestionStatus(uint256 suggestionId) public view onlySuggestionExists(suggestionId) returns (SuggestionStatus) {
        return parameterSuggestions[suggestionId].status;
    }

    // --- Contributor Management ---

    /// @notice Allows a user to become a contributor by staking the required amount of ETH.
    function becomeContributor() public payable whenNotPaused nonReentrancy {
        require(msg.value >= nexusParameters.contributorStakeAmount, "CryptoNexus: Insufficient stake amount");
        require(!isContributor[msg.sender], "CryptoNexus: Already a contributor");

        isContributor[msg.sender] = true;
        contributorStake[msg.sender] = msg.value;
        contributorUnstakeCooldown[msg.sender] = 0; // No cooldown initially

        // Return any excess ETH
        if (msg.value > nexusParameters.contributorStakeAmount) {
            payable(msg.sender).call{value: msg.value - nexusParameters.contributorStakeAmount}("");
        }

        emit ContributorJoined(msg.sender, nexusParameters.contributorStakeAmount);
    }

    /// @notice Allows a contributor to withdraw their stake after a cooldown period, provided they have no active commitments.
    function withdrawContributorStake() public whenNotPaused nonReentrancy {
        require(isContributor[msg.sender], "CryptoNexus: Not a contributor");
        require(contributorStake[msg.sender] > 0, "CryptoNexus: No contributor stake to withdraw");
        require(block.timestamp >= contributorUnstakeCooldown[msg.sender], "CryptoNexus: Contributor stake is under cooldown");

        // Check for active commitments (simplified: check if they have active endorsements or challenges)
        // This check might need to be more complex depending on how "active commitment" is defined
        // For this example, let's assume no active endorsements or challenges prevents withdrawal
        require(userEndorsedArtifacts[msg.sender].length == 0, "CryptoNexus: Cannot withdraw while having active endorsements");
        require(userChallengedArtifacts[msg.sender].length == 0, "CryptoNexus: Cannot withdraw while having active challenges");
        // Also check if they have submitted artifacts that are still Active or Challenged? Maybe allow, but they lose potential reputation?

        uint256 stakeAmount = contributorStake[msg.sender];
        contributorStake[msg.sender] = 0;
        isContributor[msg.sender] = false;
        contributorUnstakeCooldown[msg.sender] = block.timestamp + nexusParameters.unstakeCooldownPeriod; // Set cooldown for re-staking/future withdrawal

        payable(msg.sender).call{value: stakeAmount}("");

        emit ContributorStakeWithdrawn(msg.sender, stakeAmount);
    }

    /// @notice Checks if an address is currently a contributor.
    /// @param user The address to check.
    /// @return True if the address is a contributor, false otherwise.
    function getContributorStatus(address user) public view returns (bool) {
        return isContributor[user];
    }

    /// @notice Gets the current reputation points for a user.
    /// @param user The address to check.
    /// @return The user's reputation points.
    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    /// @notice Claims earned reputation rewards. Reputation is earned from successful artifacts and endorsements.
    /// @dev The calculation of *eligible* reputation happens dynamically or needs a separate accumulator system.
    /// This function simplifies it by adding a flat reward (for example) or transferring from a pending pool.
    /// A more advanced version would calculate rewards based on resolved artifacts.
    function claimReputation() public nonReentrancy {
        // Placeholder: In a real system, reputation would be accumulated in a separate balance
        // that becomes claimable after artifacts/suggestions resolve successfully.
        // This simplified version assumes `userReputation` is the claimable balance.
        // A real implementation would transfer from a pending balance.
        revert("CryptoNexus: Claiming reputation requires a specific reward calculation logic (not implemented)");

        /*
        uint256 claimable = _calculateEligibleReputation(msg.sender); // Needs internal calculation logic
        require(claimable > 0, "CryptoNexus: No reputation available to claim");

        userReputation[msg.sender] += claimable; // Add to active reputation
        // Deduct from pending/claimable balance

        emit ReputationClaimed(msg.sender, claimable);
        */
    }

    /// @notice Calculates the potential reputation rewards a user is eligible to claim.
    /// @dev Placeholder: Needs actual calculation logic based on resolved artifacts etc.
    /// @param user The address to check.
    /// @return The amount of reputation eligible for claiming.
    function getEligibleReputationAmount(address user) public view returns (uint256) {
        // Placeholder: In a real system, this would look at resolved artifacts/suggestions
        // where the user was involved (submitter/endorser of Accepted, challenger of Rejected).
        // This value would likely be stored in a separate mapping.
        return 0; // Represents no reputation available to claim in this simplified version
    }


    // --- Artifact Management & Interaction ---

    /// @notice Submits a new artifact to the Nexus. Requires contributor status and pays a fee.
    /// @param artifactHash A unique identifier (e.g., IPFS hash, content hash) for the artifact.
    /// @dev The `fee` parameter is expected via msg.value.
    function submitArtifact(bytes36 artifactHash) public payable whenNotPaused nonReentrancy onlyContributor {
        require(msg.value >= nexusParameters.artifactSubmissionFee, "CryptoNexus: Insufficient submission fee");
        require(artifactHash != bytes32(0), "CryptoNexus: Artifact hash cannot be zero");
        // Basic uniqueness check (can be bypassed if multiple submissions of same hash are allowed)
        // require(_artifactExists(artifactHash), "CryptoNexus: Artifact already exists"); // Needs mapping hash => id

        uint256 artifactId = nextArtifactId++;
        Artifact storage artifact = artifacts[artifactId];

        artifact.id = artifactId;
        artifact.artifactHash = bytes32(artifactHash); // Assuming bytes36 fits in bytes32 for simplicity, or use string/bytes
        artifact.submitter = msg.sender;
        artifact.submissionTime = block.timestamp;
        artifact.status = ArtifactStatus.Active;
        artifact.lastInteractionTime = block.timestamp;
        // totalEndorsementStake and totalChallengeStake start at 0
        // activeEndorsers and activeChallengers start empty

        userSubmittedArtifactsList[msg.sender].push(artifactId);
        activeArtifactIds.push(artifactId);

        // Return excess ETH
        if (msg.value > nexusParameters.artifactSubmissionFee) {
             payable(msg.sender).call{value: msg.value - nexusParameters.artifactSubmissionFee}("");
        }

        emit ArtifactSubmitted(artifactId, bytes32(artifactHash), msg.sender, block.timestamp);
    }

    /// @notice Endorses an artifact by staking ETH. Requires contributor status.
    /// @param artifactId The ID of the artifact to endorse.
    function endorseArtifact(uint256 artifactId) public payable whenNotPaused nonReentrancy onlyContributor onlyArtifactExists(artifactId) artifactInStatus(artifactId, ArtifactStatus.Active) {
        Artifact storage artifact = artifacts[artifactId];
        require(msg.value >= nexusParameters.endorsementStakeAmount, "CryptoNexus: Insufficient endorsement stake");
        require(userArtifactEndorsementStake[msg.sender][artifactId] == 0, "CryptoNexus: Already endorsed this artifact");
        require(artifact.submitter != msg.sender, "CryptoNexus: Cannot endorse your own artifact");

        uint256 stakeAmount = nexusParameters.endorsementStakeAmount;
        userArtifactEndorsementStake[msg.sender][artifactId] = stakeAmount;
        artifact.totalEndorsementStake += stakeAmount;
        artifact.activeEndorsers.push(msg.sender); // Add to active list
        artifact.lastInteractionTime = block.timestamp; // Update interaction time

        userEndorsedArtifacts[msg.sender].push(artifactId); // Track user's endorsements

         // Return excess ETH
        if (msg.value > stakeAmount) {
             payable(msg.sender).call{value: msg.value - stakeAmount}("");
        }

        emit ArtifactEndorsed(artifactId, msg.sender, stakeAmount);
    }

     /// @notice Unendorses an artifact, potentially with conditions or penalties.
     /// @dev Simplified: Allows withdrawal anytime for Active artifacts.
     /// @param artifactId The ID of the artifact to unendorse.
    function unendorseArtifact(uint256 artifactId) public whenNotPaused nonReentrancy onlyContributor onlyArtifactExists(artifactId) artifactInStatus(artifactId, ArtifactStatus.Active) {
        Artifact storage artifact = artifacts[artifactId];
        uint256 stakedAmount = userArtifactEndorsementStake[msg.sender][artifactId];
        require(stakedAmount > 0, "CryptoNexus: User has no active endorsement stake on this artifact");

        userArtifactEndorsementStake[msg.sender][artifactId] = 0;
        artifact.totalEndorsementStake -= stakedAmount;

        // Remove from activeEndorsers array (inefficient, but for simplicity)
        _removeAddressFromArray(artifact.activeEndorsers, msg.sender);
         // Remove from userEndorsedArtifacts array (inefficient)
        _removeArtifactIdFromArray(userEndorsedArtifacts[msg.sender], artifactId);


        // Return stake
        payable(msg.sender).call{value: stakedAmount}("");

        emit ArtifactUnendorsed(artifactId, msg.sender, stakedAmount);
    }

    /// @notice Challenges an artifact by staking ETH. Requires contributor status.
    /// @param artifactId The ID of the artifact to challenge.
    function challengeArtifact(uint256 artifactId) public payable whenNotPaused nonReentrancy onlyContributor onlyArtifactExists(artifactId) {
        Artifact storage artifact = artifacts[artifactId];
        require(artifact.status == ArtifactStatus.Active || artifact.status == ArtifactStatus.Challenged, "CryptoNexus: Artifact cannot be challenged in its current status");
        require(msg.value >= nexusParameters.challengeStakeAmount, "CryptoNexus: Insufficient challenge stake");
        require(userArtifactChallengeStake[msg.sender][artifactId] == 0, "CryptoNexus: Already challenged this artifact");
        require(artifact.submitter != msg.sender, "CryptoNexus: Cannot challenge your own artifact");

        uint256 stakeAmount = nexusParameters.challengeStakeAmount;
        userArtifactChallengeStake[msg.sender][artifactId] = stakeAmount;
        artifact.totalChallengeStake += stakeAmount;
        artifact.activeChallengers.push(msg.sender); // Add to active list
        artifact.lastInteractionTime = block.timestamp; // Update interaction time

        userChallengedArtifacts[msg.sender].push(artifactId); // Track user's challenges

        // If it was Active, change status to Challenged
        if (artifact.status == ArtifactStatus.Active) {
             artifact.status = ArtifactStatus.Challenged;
             artifact.challengeEndTime = block.timestamp + nexusParameters.challengePeriodDuration;
        }


        // Return excess ETH
        if (msg.value > stakeAmount) {
             payable(msg.sender).call{value: msg.value - stakeAmount}("");
        }

        emit ArtifactChallenged(artifactId, msg.sender, stakeAmount);
    }

    /// @notice Resolves an artifact's status. Can be called by anyone when conditions are met (e.g., challenge period ends).
    /// @dev Simplified: If challenged, resolves based on time. If Active and old enough, resolves to Expired (eligible for cleanup).
    /// @param artifactId The ID of the artifact to resolve.
    function resolveArtifact(uint256 artifactId) public nonReentrancy onlyArtifactExists(artifactId) {
        Artifact storage artifact = artifacts[artifactId];
        ArtifactStatus currentStatus = artifact.status;
        ArtifactStatus newStatus = currentStatus;

        if (currentStatus == ArtifactStatus.Challenged && block.timestamp >= artifact.challengeEndTime) {
             // Challenge period ended. Simplified resolution logic:
             // If total endorsements >= total challenges * resolutionQuorumPercent (scaled), it's Accepted. Otherwise Rejected.
             // A more complex system would involve voting, reputation weight etc.
             uint256 endorsementScore = artifact.totalEndorsementStake;
             uint256 challengeScore = artifact.totalChallengeStake;
             // Prevent division by zero if no challenges
             bool accepted = challengeScore == 0 || endorsementScore * 100 >= challengeScore * nexusParameters.resolutionQuorumPercent;

             if (accepted) {
                 newStatus = ArtifactStatus.ResolvedAccepted;
                 // Distribute rewards (placeholder)
                 // Unlock stakes for endorsers/challengers to claim
             } else {
                 newStatus = ArtifactStatus.ResolvedRejected;
                 // Distribute penalties/rewards (placeholder)
                 // Unlock stakes for endorsers/challengers to claim
             }

             // Clear active endorsers/challengers lists after resolution
             delete artifact.activeEndorsers;
             delete artifact.activeChallengers;


        } else if (currentStatus == ArtifactStatus.Active && block.timestamp >= artifact.submissionTime + nexusParameters.maxArtifactAge) {
             // Artifact is old and wasn't challenged. Mark as Expired (eligible for cleanup).
             newStatus = ArtifactStatus.Expired;
        } else {
            revert("CryptoNexus: Artifact is not ready for resolution");
        }

        if (newStatus != currentStatus) {
            artifact.status = newStatus;
            artifact.resolvedTime = block.timestamp;
            artifact.lastInteractionTime = block.timestamp; // Mark as resolved

            emit ArtifactResolved(artifactId, newStatus, artifact.resolvedTime);
        }
    }

    /// @notice Gets the details of a specific artifact.
    /// @param artifactId The ID of the artifact.
    /// @return artifact details struct.
    function getArtifactDetails(uint256 artifactId) public view onlyArtifactExists(artifactId) returns (Artifact memory) {
        return artifacts[artifactId];
    }

    /// @notice Gets the current lifecycle status of an artifact.
    /// @param artifactId The ID of the artifact.
    /// @return The ArtifactStatus.
     function getArtifactStatus(uint256 artifactId) public view onlyArtifactExists(artifactId) returns (ArtifactStatus) {
        return artifacts[artifactId].status;
    }


    /// @notice Calculates the dynamic score of an artifact based on current endorsements, challenges, and time decay.
    /// @param artifactId The ID of the artifact.
    /// @return The calculated score. Higher is generally better.
    function getArtifactScore(uint256 artifactId) public view onlyArtifactExists(artifactId) returns (int256) {
        Artifact storage artifact = artifacts[artifactId];
        if (artifact.status != ArtifactStatus.Active && artifact.status != ArtifactStatus.Challenged) {
             return 0; // Score is 0 if not active or challenged
        }

        uint256 timeSinceLastInteraction = block.timestamp - artifact.lastInteractionTime;
        uint256 decayAmount = timeSinceLastInteraction * nexusParameters.decayRatePerSecond; // Simplified linear decay

        int256 score = int256(artifact.totalEndorsementStake) - int256(artifact.totalChallengeStake) - int256(decayAmount);

        // A more advanced score could factor in reputation of endorsers/challengers
        // and use non-linear decay or growth curves.

        return score;
    }

    /// @notice Gets the list of addresses currently endorsing an artifact.
    /// @param artifactId The ID of the artifact.
    /// @return An array of endorser addresses.
    function getArtifactEndorsements(uint256 artifactId) public view onlyArtifactExists(artifactId) returns (address[] memory) {
        // Note: This returns the *current* list stored in the artifact struct.
        // For past endorsers after resolution, more complex tracking would be needed.
        return artifacts[artifactId].activeEndorsers;
    }

     /// @notice Gets the list of addresses currently challenging an artifact.
     /// @param artifactId The ID of the artifact.
     /// @return An array of challenger addresses.
    function getArtifactChallenges(uint256 artifactId) public view onlyArtifactExists(artifactId) returns (address[] memory) {
        // Note: This returns the *current* list stored in the artifact struct.
        // For past challengers after resolution, more complex tracking would be needed.
        return artifacts[artifactId].activeChallengers;
    }


    // --- Staking & Claiming ---

    /// @notice Allows a user to claim back staked ETH from resolved or expired artifacts/endorsements/challenges.
    /// @dev Processes stakes for a given list of artifact IDs. User must be the original staker.
    /// @param artifactIds The list of artifact IDs to check for claimable stakes.
    function claimStakes(uint256[] memory artifactIds) public nonReentrancy {
        uint256 totalClaimable = 0;

        for (uint i = 0; i < artifactIds.length; i++) {
            uint256 artifactId = artifactIds[i];
             // Skip if artifact doesn't exist (could happen if cleaned up)
            if (artifactId == 0 || artifactId >= nextArtifactId) continue;

            Artifact storage artifact = artifacts[artifactId];

            // Claim Endorsement Stake
            uint256 endorsementStake = userArtifactEndorsementStake[msg.sender][artifactId];
            if (endorsementStake > 0) {
                // Stake is claimable if artifact is resolved or expired
                if (artifact.status == ArtifactStatus.ResolvedAccepted ||
                    artifact.status == ArtifactStatus.ResolvedRejected ||
                    artifact.status == ArtifactStatus.Expired)
                {
                    totalClaimable += endorsementStake;
                    userArtifactEndorsementStake[msg.sender][artifactId] = 0; // Mark as claimed
                    // Note: TotalStake on artifact is NOT reduced here, only individual user stake tracking
                }
            }

            // Claim Challenge Stake
            uint256 challengeStake = userArtifactChallengeStake[msg.sender][artifactId];
             if (challengeStake > 0) {
                // Stake is claimable if artifact is resolved or expired
                if (artifact.status == ArtifactStatus.ResolvedAccepted ||
                    artifact.status == ArtifactStatus.ResolvedRejected ||
                    artifact.status == ArtifactStatus.Expired)
                {
                    totalClaimable += challengeStake;
                    userArtifactChallengeStake[msg.sender][artifactId] = 0; // Mark as claimed
                     // Note: TotalStake on artifact is NOT reduced here
                }
            }
        }

        require(totalClaimable > 0, "CryptoNexus: No claimable stakes for provided artifact IDs");

        // Transfer combined claimable amount
        payable(msg.sender).call{value: totalClaimable}("");

        emit StakeClaimed(msg.sender, totalClaimable);
    }

    /// @notice Gets the list of artifact IDs that a user has actively endorsed.
    /// @param user The address to check.
    /// @return An array of artifact IDs.
    function getUserActiveEndorsements(address user) public view returns (uint256[] memory) {
        // Note: This returns the list used for *tracking*. It might include resolved/expired artifacts until cleanup/claim.
        // A more accurate "active" list would iterate and check artifact status.
        return userEndorsedArtifacts[user];
    }

     /// @notice Calculates the total amount of ETH a user is eligible to claim from stakes.
     /// @dev Iterates through known endorsements/challenges to calculate. Can be gas-intensive for users with many interactions.
     /// @param user The address to check.
     /// @return The total amount of claimable ETH stake.
    function getEligibleStakeAmount(address user) public view returns (uint256) {
        uint256 totalClaimable = 0;

        // Check endorsements
        uint256[] memory endorsedIds = userEndorsedArtifacts[user];
        for (uint i = 0; i < endorsedIds.length; i++) {
            uint256 artifactId = endorsedIds[i];
            if (artifactId > 0 && artifactId < nextArtifactId) { // Check if artifact exists
                Artifact storage artifact = artifacts[artifactId];
                 if (userArtifactEndorsementStake[user][artifactId] > 0 && // User still has stake tracked
                     (artifact.status == ArtifactStatus.ResolvedAccepted ||
                      artifact.status == ArtifactStatus.ResolvedRejected ||
                      artifact.status == ArtifactStatus.Expired))
                 {
                     totalClaimable += userArtifactEndorsementStake[user][artifactId];
                 }
            }
        }

        // Check challenges
         uint256[] memory challengedIds = userChallengedArtifacts[user];
        for (uint i = 0; i < challengedIds.length; i++) {
            uint256 artifactId = challengedIds[i];
             if (artifactId > 0 && artifactId < nextArtifactId) { // Check if artifact exists
                Artifact storage artifact = artifacts[artifactId];
                 if (userArtifactChallengeStake[user][artifactId] > 0 && // User still has stake tracked
                     (artifact.status == ArtifactStatus.ResolvedAccepted ||
                      artifact.status == ArtifactStatus.ResolvedRejected ||
                      artifact.status == ArtifactStatus.Expired))
                 {
                     totalClaimable += userArtifactChallengeStake[user][artifactId];
                 }
            }
        }

        return totalClaimable;
    }

    /// @notice Gets the total amount of ETH currently held in the contract from all stakes and fees.
    /// @return The total ETH balance of the contract.
    function getTotalStakedETH() public view returns (uint256) {
        return address(this).balance;
    }


    // --- Maintenance & Utility ---

    /// @notice Applies time-based decay to artifact scores and cleans up old artifacts and suggestions.
    /// @dev Can be called by anyone to trigger maintenance. Processes a batch of items to manage gas costs.
    /// @dev Decay logic is simplified (linear). Cleanup removes Resolved/Expired/Applied items.
    function applyDecayAndCleanup() public nonReentrancy {
        uint256 decayCount = 0;
        uint256 cleanedArtifacts = 0;
        uint256 cleanedSuggestions = 0;
        uint256 batchSize = nexusParameters.cleanupBatchSize;

        // --- Apply Decay (for a batch of active artifacts) ---
        uint256 artifactsToProcess = activeArtifactIds.length;
        for (uint i = 0; i < artifactsToProcess && decayCount < batchSize; i++) {
            uint256 artifactId = activeArtifactIds[i];
            // Check if artifact exists and is active/challenged
            if (artifactId > 0 && artifactId < nextArtifactId) {
                 Artifact storage artifact = artifacts[artifactId];
                 if (artifact.status == ArtifactStatus.Active || artifact.status == ArtifactStatus.Challenged) {
                     uint256 timeElapsed = block.timestamp - artifact.lastInteractionTime;
                     uint256 decayAmount = timeElapsed * nexusParameters.decayRatePerSecond;
                     // Reduce total stakes by decay amount (simplified, actual stakes aren't burned)
                     // This is a simplified way to reflect decay in the score, not actual ETH movement.
                     // A real system would need a more complex scoring/decay mechanism.
                     if (artifact.totalEndorsementStake > decayAmount) {
                         artifact.totalEndorsementStake -= decayAmount;
                     } else {
                         artifact.totalEndorsementStake = 0;
                     }
                     artifact.lastInteractionTime = block.timestamp; // Update last interaction time
                     decayCount++;
                 }
            }
        }
        emit DecayApplied(activeArtifactIds, decayCount); // Emitting array might be too big

        // --- Cleanup (for a batch of artifacts) ---
        uint224 artifactCleanupIndex = 0; // Using uint224 for index
        while(cleanedArtifacts < batchSize && artifactCleanupIndex < activeArtifactIds.length) {
            uint256 artifactId = activeArtifactIds[artifactCleanupIndex];
             // Check if artifact exists and is eligible for cleanup
            if (artifactId > 0 && artifactId < nextArtifactId) {
                Artifact storage artifact = artifacts[artifactId];
                 if (artifact.status == ArtifactStatus.ResolvedAccepted ||
                     artifact.status == ArtifactStatus.ResolvedRejected ||
                     artifact.status == ArtifactStatus.Expired)
                 {
                     // Remove from artifacts mapping (sets to default zero value)
                     delete artifacts[artifactId];
                     // In a real system, also clean up associated user mappings if not already done on resolve/claim
                     // This is complex and omitted for simplicity.

                     // Remove from activeArtifactIds array (swap and pop - gas efficient)
                     uint2 lastIndex = activeArtifactIds.length - 1;
                     activeArtifactIds[artifactCleanupIndex] = activeArtifactIds[lastIndex];
                     activeArtifactIds.pop();
                     cleanedArtifacts++;
                     // Do NOT increment artifactCleanupIndex because the new element needs to be checked
                     continue; // Go to next iteration of the while loop
                 }
            }
             artifactCleanupIndex++; // Move to next index ONLY if current item wasn't removed
        }


        // --- Cleanup (for a batch of suggestions) ---
        uint224 suggestionCleanupIndex = 0; // Using uint224 for index
         while(cleanedSuggestions < batchSize && suggestionCleanupIndex < activeSuggestionIds.length) {
            uint256 suggestionId = activeSuggestionIds[suggestionCleanupIndex];
            // Check if suggestion exists and is eligible for cleanup
            if (suggestionId > 0 && suggestionId < nextSuggestionId) {
                 ParameterSuggestion storage suggestion = parameterSuggestions[suggestionId];
                 if (suggestion.status == SuggestionStatus.Applied ||
                     suggestion.status == SuggestionStatus.Rejected ||
                     (suggestion.status == SuggestionStatus.Pending && block.timestamp >= suggestion.votingEndTime) ) // Clean up expired pending suggestions too
                 {
                     // Remove from parameterSuggestions mapping
                     delete parameterSuggestions[suggestionId];
                     // In a real system, also clean up reputationEndorsements mapping
                     // This is complex and omitted for simplicity.

                     // Remove from activeSuggestionIds array (swap and pop)
                     uint2 lastIndex = activeSuggestionIds.length - 1;
                     activeSuggestionIds[suggestionCleanupIndex] = activeSuggestionIds[lastIndex];
                     activeSuggestionIds.pop();
                     cleanedSuggestions++;
                      // Do NOT increment suggestionCleanupIndex because the new element needs to be checked
                     continue; // Go to next iteration of the while loop
                 }
            }
             suggestionCleanupIndex++; // Move to next index ONLY if current item wasn't removed
         }


        emit CleanupPerformed(cleanedArtifacts, cleanedSuggestions);
    }

     /// @notice Gets the list of artifact IDs submitted by a specific user.
     /// @param user The address to check.
     /// @return An array of artifact IDs.
    function getUserSubmittedArtifacts(address user) public view returns (uint256[] memory) {
        return userSubmittedArtifactsList[user];
    }

    // --- Admin & Safety ---

    /// @notice Pauses the contract, preventing most state-changing operations.
    function pauseNexus() public onlyOwner whenNotPaused {
        _pause();
        emit NexusPaused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing operations to resume.
    function unpauseNexus() public onlyOwner whenPaused {
        _unpause();
        emit NexusUnpaused(msg.sender);
    }

    /// @notice Allows the owner to withdraw collected ETH (fees, unclaimed stakes that default to treasury).
    /// @param amount The amount of ETH to withdraw.
    function emergencyWithdrawEth(uint256 amount) public onlyOwner {
        require(amount > 0, "CryptoNexus: Amount must be greater than 0");
        require(amount <= address(this).balance, "CryptoNexus: Insufficient balance");

        payable(owner()).call{value: amount}("");

        emit EmergencyETHWithdrawal(owner(), amount);
    }


    // --- Internal Helper Functions ---

    /// @dev Helper to remove an address from an array. Inefficient O(n). Use only for small arrays or where order doesn't matter.
    function _removeAddressFromArray(address[] storage arr, address account) internal {
        uint256 index = type(uint256).max;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == account) {
                index = i;
                break;
            }
        }
        if (index != type(uint256).max) {
            // Swap and pop
            uint2 lastIndex = arr.length - 1;
            if (index != lastIndex) {
                arr[index] = arr[lastIndex];
            }
            arr.pop();
        }
    }

    /// @dev Helper to remove an artifact ID from an array. Inefficient O(n).
    function _removeArtifactIdFromArray(uint256[] storage arr, uint256 artifactId) internal {
         uint256 index = type(uint256).max;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == artifactId) {
                index = i;
                break;
            }
        }
        if (index != type(uint256).max) {
             // Swap and pop
            uint2 lastIndex = arr.length - 1;
            if (index != lastIndex) {
                arr[index] = arr[lastIndex];
            }
            arr.pop();
        }
    }

     /// @dev Helper to get list of addresses that endorsed a parameter suggestion. Inefficient O(n) on all addresses.
     /// @dev A better implementation would track endorsers in the struct itself, similar to Artifacts.
    function _getParameterSuggestionEndorsers(uint256 suggestionId) internal view returns (address[] memory) {
         // This is a highly inefficient placeholder. Iterating over *all* addresses is not feasible on chain.
         // A real implementation MUST store endorsers directly in the suggestion struct or a separate mapping.
         revert("CryptoNexus: Getting all suggestion endorsers directly is not implemented due to gas constraints. Implement proper tracking.");

         /*
         // Dummy implementation (for theoretical check, NOT gas-efficient)
         address[] memory endorsers;
         uint count = 0;
         // This loop is the problematic part - iterating potentially many addresses
         // for(address user = address(0); user <= address(type(uint160).max); user++) { // This doesn't work like this in practice
         //    if (parameterSuggestions[suggestionId].reputationEndorsements[user] > 0) {
         //        count++;
         //    }
         // }
         // endorsers = new address[](count);
         // uint current = 0;
         // for(address user = address(0); user <= address(type(uint160).max); user++) {
         //    if (parameterSuggestions[suggestionId].reputationEndorsements[user] > 0) {
         //        endorsers[current++] = user;
         //    }
         // }
         // return endorsers;
         */
    }
}
```

---

**Explanation of Key Functions and Concepts:**

1.  **`NexusParameters` Struct and Management:** The contract's behavior is governed by a set of parameters. These are stored in a struct and also in a dynamic mapping (`currentParameterValues`). The `initializeParameters` function sets them initially. The `suggestParameterChange`, `endorseParameterSuggestion`, and `applyParameterSuggestion` functions provide a decentralized way for *reputation holders* to propose and enact changes to these parameters, adding a layer of self-adjusting governance (though simplified).
2.  **`Artifact` Struct and Lifecycle:** The core item is an `Artifact`. It moves through `Active`, `Challenged`, `ResolvedAccepted`, `ResolvedRejected`, and `Expired` states. Submitting costs a fee, endorsing/challenging costs stake.
3.  **Reputation (`userReputation`):** Users earn reputation (conceptually) by participating successfully. In this simplified version, the `claimReputation` function is a placeholder; a real system would need logic to calculate *how much* reputation is earned when artifacts/suggestions resolve based on user involvement and the outcome. Reputation is required for suggesting parameters.
4.  **Staking (`contributorStake`, `userArtifactEndorsementStake`, `userArtifactChallengeStake`):** Users stake ETH to become contributors, endorse, or challenge. These stakes are held in the contract.
5.  **Claiming (`claimStakes`, `getEligibleStakeAmount`):** Users can claim back stakes once the relevant artifact or event is resolved or expired.
6.  **Dynamic Scoring (`getArtifactScore`):** The `getArtifactScore` function provides a view of an artifact's current standing, incorporating endorsements, challenges, and a basic time decay.
7.  **Time-Based Decay & Cleanup (`applyDecayAndCleanup`):** This function is crucial for managing the contract's state over time. Anyone can call it (paying gas) to trigger decay on a batch of active items and clean up a batch of old/resolved items. This prevents the contract from growing infinitely large and makes old items less prominent. Decay reduces the effective "score contribution" of old endorsements.
8.  **Batch Processing:** `applyDecayAndCleanup` processes items in limited batches defined by `cleanupBatchSize` to avoid hitting Ethereum's block gas limit.
9.  **Pausable & Ownable:** Standard OpenZeppelin patterns for administrative control (pausing in emergencies) and ownership.
10. **ReentrancyGuard:** Protects against reentrancy issues, especially important when handling ETH transfers.
11. **Helper Functions (`_removeAddressFromArray`, `_removeArtifactIdFromArray`):** These are included but marked as inefficient for array manipulation in Solidity. A production contract might use different data structures or alternative approaches for tracking endorsers/challengers. The `_getParameterSuggestionEndorsers` helper is explicitly marked as infeasible due to gas limits if trying to iterate over all possible addresses.

**Considerations & Potential Improvements (Beyond the Scope of this Example):**

*   **Reputation Calculation:** The logic for *earning* and *claiming* reputation is a placeholder. A robust system needs clear rules (e.g., earn X reputation if artifact you endorsed is ResolvedAccepted, lose Y if ResolvedRejected, earn Z if artifact you challenged is ResolvedRejected).
*   **Resolution Logic:** The `resolutionQuorumPercent` is a very simple example. Real-world systems often use more sophisticated voting, quadratic funding, or oracle-based dispute resolution.
*   **Gas Efficiency:** Array manipulations (`push`, `remove`) can be costly. Managing the `activeArtifactIds` and `activeSuggestionIds` arrays and the user-specific arrays efficiently upon status changes and cleanup is critical. Using linked lists or alternative mapping structures could be more gas-efficient for removal.
*   **Data Storage:** Storing lists of `activeEndorsers` and `activeChallengers` directly in the `Artifact` struct becomes expensive if lists get long. A mapping like `mapping(uint256 => mapping(address => bool))` could track active status more cheaply, but retrieving the *list* of endorsers/challengers would require off-chain indexing.
*   **Parameter Names:** Using `bytes32` hash for parameter names in suggestions saves storage but requires careful mapping to actual struct fields during `applyParameterSuggestion`. A typo in the hash would break it.
*   **Front-end Complexity:** Building a front-end for this would require significant off-chain indexing to display lists of artifacts, user history, calculate scores frequently, etc.
*   **Economic Model:** The stakes and fees need careful tuning to incentivize desired behavior and cover gas costs. Unclaimed stakes defaulting might be controversial; an alternative is allowing anyone to trigger cleanup and claim a small bounty.

This contract provides a foundation for a unique decentralized application, demonstrating several advanced Solidity concepts beyond standard token or simple interaction contracts. Remember to audit thoroughly before using any complex smart contract in production.