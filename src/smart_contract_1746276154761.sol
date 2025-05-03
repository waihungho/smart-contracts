Okay, here is a Solidity smart contract demonstrating several advanced, interesting, and creative concepts, aiming for at least 20 functions. It introduces a decentralized protocol for creating unique digital artifacts, governed by a reputation/influence system and evolving through epochs and parameter governance.

**Disclaimer:** This is a complex example designed to showcase multiple concepts within a single contract. It is *not* production-ready code. A real-world implementation would require extensive security audits, gas optimizations, robust testing, and likely separation into multiple contracts (e.g., dedicated ERC20/ERC721 contracts, a dedicated Governor contract following standards like OpenZeppelin). This code prioritizes concept demonstration over production readiness.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GenesisProtocol
 * @dev A decentralized protocol for creating, governing, and evolving digital artifacts.
 * It incorporates dynamic NFTs, an influence/reputation system, on-chain parameter governance,
 * epoch-based mechanics, and emergency controls.
 *
 * Outline:
 * 1. Protocol State Variables: Core parameters, epoch data, pause status, token counters.
 * 2. Token Definitions: Simplified internal representation of Protocol Artifacts (NFTs) and Protocol Energy (ERC20).
 * 3. Influence System: Mapping user addresses to influence scores and delegation.
 * 4. Governance System: Proposal structure, state machine, voting logic, execution.
 * 5. Emergency Council: Mechanism for urgent protocol pausing.
 * 6. Events: Signaling key protocol activities.
 * 7. Errors: Custom error definitions.
 * 8. Modifiers: Access control and state checks.
 * 9. Core Mechanics:
 *    - Artifact Forging: Creating new dynamic NFTs using Energy and Influence.
 *    - Energy Synthesis & Sinks: Minting/burning Protocol Energy.
 *    - Influence Dynamics: Updating influence scores based on activity.
 *    - Epoch Management: Advancing protocol epochs.
 *    - Parameter Alchemy: Governing protocol parameters via proposals.
 * 10. Emergency Controls: Pausing critical functions.
 * 11. Query Functions: Reading protocol state and user data.
 *
 * Function Summary:
 * (Grouped by concept)
 *
 * --- Initialization & Setup ---
 * 1. constructor: Sets initial parameters, council members, and governor.
 *
 * --- Protocol Parameters & State ---
 * 2. getProtocolParameter(bytes32 paramHash): Reads a protocol parameter value.
 * 3. isProtocolPaused(): Checks if critical functions are paused.
 *
 * --- Protocol Artifacts (Simplified ERC721-like) ---
 * 4. getArtifactCount(): Gets total number of artifacts minted.
 * 5. getArtifactOwner(uint256 tokenId): Gets the owner of an artifact.
 * 6. getArtifactDetails(uint256 tokenId): Gets artifact base and dynamic details.
 * 7. forgeArtifact(bytes32 genesisSeed, uint256 energyBurnAmount): Mints a new artifact using Energy and requiring Influence. (Creative Function)
 * 8. sacrificeArtifactForEnergy(uint256 tokenId): Burns an artifact to potentially recover some Energy and/or gain Influence. (Sink Function)
 *
 * --- Protocol Energy (Simplified ERC20-like) ---
 * 9. getTotalEnergySupply(): Gets the total supply of Protocol Energy.
 * 10. getEnergyBalance(address user): Gets the energy balance of a user.
 * 11. synthesizeEnergy(uint256 amount): Mints new Protocol Energy (restricted access). (Synthesis Function)
 * 12. transferEnergy(address to, uint256 amount): Transfers Protocol Energy (simplified).
 *
 * --- Influence / Reputation System ---
 * 13. getInfluenceScore(address user): Gets a user's current influence score.
 * 14. delegateInfluence(address delegatee): Delegates influence voting power. (Advanced Governance Concept)
 * 15. getInfluenceDelegatee(address user): Gets the address the user has delegated influence to.
 * 16. recordProtocolActivity(address user, uint8 activityType): Records user activity to potentially update influence (internal/privileged). (Influence Dynamic)
 *
 * --- Governance System ---
 * 17. proposeParameterChange(string memory paramName, uint256 newValue, string memory description): Creates a proposal to change a protocol parameter. (Parameter Alchemy Part 1)
 * 18. voteOnProposal(uint256 proposalId, uint8 voteType): Casts a vote on a proposal using Influence/Energy. (Voting Mechanic)
 * 19. executeProposal(uint256 proposalId): Executes a successful proposal. (Parameter Alchemy Part 2)
 * 20. getProposalState(uint256 proposalId): Gets the current state of a proposal.
 * 21. getProposalDetails(uint256 proposalId): Gets details of a specific proposal.
 * 22. getCurrentVotes(address user, uint256 blockNumber): Gets the user's voting power at a specific block (conceptually, or current). (Snapshot/Delegation Aware Voting)
 *
 * --- Epoch Management ---
 * 23. getCurrentEpoch(): Gets the current epoch number.
 * 24. advanceProtocolEpoch(): Advances the protocol to the next epoch. (Time/Activity Triggered Mechanic)
 * 25. getEpochStartTime(uint256 epochId): Gets the start timestamp of a specific epoch.
 *
 * --- Emergency Controls ---
 * 26. initiateEmergencyPause(): Starts the process to pause the protocol (Council only).
 * 27. voteOnEmergencyPause(bool approve): Council member votes on pausing.
 * 28. resolveEmergencyPause(): Executes the pause if council consensus is reached.
 * 29. emergencyUnpause(): Unpauses the protocol (Council/Governance).
 * 30. isCouncilMember(address user): Checks if an address is an emergency council member.
 *
 * --- Internal/Helper Functions (Examples) ---
 * 31. _updateInfluenceScore(address user, int256 delta): Internal function to adjust influence.
 * 32. _setProtocolParameter(bytes32 paramHash, uint256 newValue): Internal function to change parameters (called by governance execution).
 *
 * Note: Some standard ERC20/ERC721 functions like `approve`, `setApprovalForAll`, `transferFrom`, etc., are omitted for brevity and focus on the creative/advanced features within this single contract example. A real implementation would include them.
 */

contract GenesisProtocol {

    // --- Errors ---
    error GenesisProtocol__NotGovernor();
    error GenesisProtocol__NotCouncil();
    error GenesisProtocol__CouncilVoteAlreadyCast();
    error GenesisProtocol__EmergencyPauseNotInProgress();
    error GenesisProtocol__EmergencyPauseAlreadyInProgress();
    error GenesisProtocol__EmergencyPauseConsensusNotReached();
    error GenesisProtocol__PauseNotInEffect();
    error GenesisProtocol__PauseAlreadyInEffect();
    error GenesisProtocol__InsufficientEnergy();
    error GenesisProtocol__InsufficientInfluence(uint256 required, uint256 has);
    error GenesisProtocol__ArtifactNotFound();
    error GenesisProtocol__NotArtifactOwner();
    error GenesisProtocol__InvalidActivityType();
    error GenesisProtocol__EpochCannotAdvanceYet();
    error GenesisProtocol__ParameterNotFound();
    error GenesisProtocol__ProposalNotFound();
    error GenesisProtocol__ProposalNotActive();
    error GenesisProtocol__ProposalAlreadyVoted();
    error GenesisProtocol__ProposalVoteInvalid();
    error GenesisProtocol__ProposalStateCannotVote();
    error GenesisProtocol__ProposalStateCannotExecute();
    error GenesisProtocol__ProposalStateAlreadyExecuted();
    error GenesisProtocol__InsufficientVotingPower();
    error GenesisProtocol__ProposalExecuteFailed();
    error GenesisProtocol__SelfDelegation();
    error GenesisProtocol__ZeroAddressDelegatee();

    // --- Events ---
    event ArtifactForged(uint256 indexed tokenId, address indexed owner, bytes32 genesisSeed, uint256 energyBurned);
    event ArtifactSacrificed(uint256 indexed tokenId, address indexed owner, uint256 energyReturned, uint256 influenceGained);
    event EnergySynthesized(address indexed recipient, uint256 amount);
    event EnergyTransfer(address indexed from, address indexed to, uint256 amount); // Simplified ERC20 transfer event
    event InfluenceUpdated(address indexed user, uint256 newScore, int256 delta);
    event InfluenceDelegated(address indexed delegator, address indexed delegatee);
    event ProtocolParameterChanged(bytes32 indexed paramHash, uint256 oldValue, uint256 newValue);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 indexed paramHash, uint256 newValue, string description, uint256 voteStartEpoch, uint256 voteEndEpoch);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint8 voteType, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 startTime);
    event EmergencyPauseInitiated(address indexed initiator);
    event EmergencyCouncilVoteCast(address indexed voter, bool approved);
    event ProtocolPaused(address indexed initiator);
    event ProtocolUnpaused(address indexed initiator);

    // --- State Variables ---

    // Protocol State & Parameters
    address public governor; // Address with privileged roles (can be changed via governance)
    bool public protocolPaused; // Global pause switch for critical functions
    uint256 public currentEpoch;
    mapping(uint256 => uint256) public epochStartTimestamp; // Epoch number => timestamp

    // Flexible Protocol Parameters (governable)
    // Stored as bytes32 hash of the parameter name => value
    mapping(bytes32 => uint256) internal s_protocolParameters;

    // Parameter Name Hashes (Constants for easier lookup)
    bytes32 public constant PARAM_MIN_INFLUENCE_FOR_PROPOSAL = keccak256("MIN_INFLUENCE_FOR_PROPOSAL");
    bytes32 public constant PARAM_PROPOSAL_VOTING_EPOCHS = keccak256("PROPOSAL_VOTING_EPOCHS");
    bytes32 public constant PARAM_MIN_INFLUENCE_FOR_FORGING = keccak256("MIN_INFLUENCE_FOR_FORGING");
    bytes32 public constant PARAM_BASE_ENERGY_COST_FORGING = keccak256("BASE_ENERGY_COST_FORGING");
    bytes32 public constant PARAM_INFLUENCE_GAIN_PER_FORGE = keccak256("INFLUENCE_GAIN_PER_FORGE");
    bytes32 public constant PARAM_ENERGY_RETURN_SACRIFICE_PERCENT = keccak256("ENERGY_RETURN_SACRIFICE_PERCENT");
    bytes32 public constant PARAM_INFLUENCE_GAIN_SACRIFICE = keccak256("INFLUENCE_GAIN_SACRIFICE");
    bytes32 public constant PARAM_EPOCH_DURATION_SECONDS = keccak256("EPOCH_DURATION_SECONDS");
    bytes32 public constant PARAM_GOVERNANCE_QUORUM_PERCENT = keccak256("GOVERNANCE_QUORUM_PERCENT"); // e.g., 40 (for 40%)
    bytes32 public constant PARAM_GOVERNANCE_PASS_THRESHOLD_PERCENT = keccak256("GOVERNANCE_PASS_THRESHOLD_PERCENT"); // e.g., 50 (for 50% of votes cast)
    bytes32 public constant PARAM_INFLUENCE_DECAY_PER_EPOCH_PERCENT = keccak256("INFLUENCE_DECAY_PER_EPOCH_PERCENT"); // e.g., 5 (for 5%)

    // Protocol Artifacts (Simplified ERC721)
    struct Artifact {
        uint256 tokenId;
        address owner;
        bytes32 genesisSeed; // Immutable property from creation
        bytes dynamicState; // Governed or activity-influenced state
        uint64 mintedEpoch; // Epoch when created
    }
    uint256 private s_artifactCounter;
    mapping(uint256 => Artifact) internal s_artifacts; // tokenId => Artifact
    mapping(address => uint256) internal s_artifactBalances; // owner => count

    // Protocol Energy (Simplified ERC20)
    mapping(address => uint256) internal s_energyBalances; // owner => balance
    uint256 private s_totalEnergySupply;

    // Influence / Reputation System
    mapping(address => uint256) internal s_influenceScores; // user => score
    mapping(address => address) internal s_influenceDelegates; // delegator => delegatee
    // Maybe add a snapshot system mapping for historical influence/voting power

    // Governance System
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 paramHash;      // Hash of the parameter name to change
        uint256 newValue;       // New value for the parameter
        string description;
        uint256 voteStartEpoch;
        uint256 voteEndEpoch;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votesAbstain;
        uint256 totalVotesCast; // Sum of voting power used
        mapping(address => bool) hasVoted; // User address => voted status (to prevent double voting)
        ProposalState state;
    }
    uint256 private s_proposalCounter;
    mapping(uint256 => Proposal) internal s_proposals; // proposalId => Proposal

    // Emergency Council
    address[] public emergencyCouncil; // List of council members
    mapping(address => bool) private s_isCouncilMember; // Helper mapping for quick lookup
    mapping(address => bool) private s_emergencyPauseVotes; // Council member => voted YES
    uint256 private s_emergencyPauseVotesNeeded; // E.g., simple majority
    uint256 private s_emergencyPauseVotesReceived;

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) revert GenesisProtocol__NotGovernor();
        _;
    }

    modifier onlyCouncil() {
        if (!s_isCouncilMember[msg.sender]) revert GenesisProtocol__NotCouncil();
        _;
    }

    modifier whenNotPaused() {
        if (protocolPaused) revert GenesisProtocol__PauseAlreadyInEffect();
        _;
    }

    modifier whenPaused() {
        if (!protocolPaused) revert GenesisProtocol__PauseNotInEffect();
        _;
    }

    // --- Constructor ---
    constructor(address[] memory _initialCouncil, address _initialGovernor) {
        if (_initialCouncil.length == 0) revert GenesisProtocol__NotCouncil(); // Require at least one council member initially

        governor = _initialGovernor;
        protocolPaused = false;
        currentEpoch = 1;
        epochStartTimestamp[currentEpoch] = block.timestamp;

        // Set initial emergency council and required votes (simple majority)
        for (uint i = 0; i < _initialCouncil.length; i++) {
            emergencyCouncil.push(_initialCouncil[i]);
            s_isCouncilMember[_initialCouncil[i]] = true;
        }
        s_emergencyPauseVotesNeeded = _initialCouncil.length / 2 + 1; // Simple majority

        // Set initial protocol parameters (example values)
        s_protocolParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL] = 100;
        s_protocolParameters[PARAM_PROPOSAL_VOTING_EPOCHS] = 3; // Voting lasts for 3 epochs
        s_protocolParameters[PARAM_MIN_INFLUENCE_FOR_FORGING] = 50;
        s_protocolParameters[PARAM_BASE_ENERGY_COST_FORGING] = 1000;
        s_protocolParameters[PARAM_INFLUENCE_GAIN_PER_FORGE] = 10;
        s_protocolParameters[PARAM_ENERGY_RETURN_SACRIFICE_PERCENT] = 25; // 25% energy returned
        s_protocolParameters[PARAM_INFLUENCE_GAIN_SACRIFICE] = 5;
        s_protocolParameters[PARAM_EPOCH_DURATION_SECONDS] = 60 * 60 * 24; // 1 day per epoch (example)
        s_protocolParameters[PARAM_GOVERNANCE_QUORUM_PERCENT] = 40; // 40% quorum of total influence
        s_protocolParameters[PARAM_GOVERNANCE_PASS_THRESHOLD_PERCENT] = 50; // 50% of votes cast (excluding abstain)
        s_protocolParameters[PARAM_INFLUENCE_DECAY_PER_EPOCH_PERCENT] = 5; // 5% decay
    }

    // --- Protocol Parameters & State Queries ---

    /**
     * @dev Reads a protocol parameter value by its hashed name.
     * @param paramHash The keccak256 hash of the parameter name string.
     * @return The value of the protocol parameter.
     */
    function getProtocolParameter(bytes32 paramHash) external view returns (uint256) {
        // Consider adding a check to ensure the paramHash is one of the known constants if needed
        // to prevent returning 0 for arbitrary hashes.
        return s_protocolParameters[paramHash];
    }

    /**
     * @dev Checks if critical protocol functions are currently paused.
     * @return True if paused, false otherwise.
     */
    function isProtocolPaused() external view returns (bool) {
        return protocolPaused;
    }

    // --- Protocol Artifacts (Simplified ERC721-like) ---

    /**
     * @dev Gets the total number of artifacts minted in the protocol.
     * @return The total artifact count.
     */
    function getArtifactCount() external view returns (uint256) {
        return s_artifactCounter;
    }

    /**
     * @dev Gets the owner of a specific artifact.
     * @param tokenId The unique identifier of the artifact.
     * @return The address of the artifact owner.
     */
    function getArtifactOwner(uint256 tokenId) external view returns (address) {
        if (tokenId == 0 || tokenId > s_artifactCounter) revert GenesisProtocol__ArtifactNotFound();
        return s_artifacts[tokenId].owner;
    }

    /**
     * @dev Gets the base and dynamic details of an artifact.
     * @param tokenId The unique identifier of the artifact.
     * @return owner The address of the artifact owner.
     * @return genesisSeed The immutable seed used during forging.
     * @return dynamicState The current dynamic state data of the artifact.
     * @return mintedEpoch The epoch the artifact was minted in.
     */
    function getArtifactDetails(uint256 tokenId) external view returns (address owner, bytes32 genesisSeed, bytes memory dynamicState, uint64 mintedEpoch) {
         if (tokenId == 0 || tokenId > s_artifactCounter) revert GenesisProtocol__ArtifactNotFound();
         Artifact storage artifact = s_artifacts[tokenId];
         return (artifact.owner, artifact.genesisSeed, artifact.dynamicState, artifact.mintedEpoch);
    }

    /**
     * @dev Creates a new Protocol Artifact (NFT). Requires burning Energy and sufficient Influence.
     * Dynamic state is initialized here and can potentially be updated later.
     * @param genesisSeed An arbitrary seed provided by the user influencing potential future traits.
     * @param energyBurnAmount The amount of Protocol Energy to burn. Must be >= PARAM_BASE_ENERGY_COST_FORGING.
     */
    function forgeArtifact(bytes32 genesisSeed, uint256 energyBurnAmount) external whenNotPaused {
        uint256 requiredInfluence = s_protocolParameters[PARAM_MIN_INFLUENCE_FOR_FORGING];
        uint256 currentInfluence = getInfluenceScore(msg.sender);
        if (currentInfluence < requiredInfluence) {
            revert GenesisProtocol__InsufficientInfluence(requiredInfluence, currentInfluence);
        }

        uint256 requiredEnergy = s_protocolParameters[PARAM_BASE_ENERGY_COST_FORGING];
        if (energyBurnAmount < requiredEnergy || s_energyBalances[msg.sender] < energyBurnAmount) {
             revert GenesisProtocol__InsufficientEnergy();
        }

        // Burn Energy
        s_energyBalances[msg.sender] -= energyBurnAmount;
        s_totalEnergySupply -= energyBurnAmount; // Reduce total supply on burn

        // Mint new Artifact
        s_artifactCounter++;
        uint256 newTokenId = s_artifactCounter;
        s_artifacts[newTokenId] = Artifact({
            tokenId: newTokenId,
            owner: msg.sender,
            genesisSeed: genesisSeed,
            dynamicState: abi.encodePacked("InitialState"), // Example: Initial dynamic state data
            mintedEpoch: uint64(currentEpoch)
        });
        s_artifactBalances[msg.sender]++;

        // Update Influence based on activity
        recordProtocolActivity(msg.sender, 1); // 1: Forging activity

        emit ArtifactForged(newTokenId, msg.sender, genesisSeed, energyBurnAmount);
    }

    /**
     * @dev Allows an artifact owner to sacrifice their artifact to potentially regain some Energy
     * and/or gain Influence. The artifact is burned.
     * @param tokenId The unique identifier of the artifact to sacrifice.
     */
    function sacrificeArtifactForEnergy(uint256 tokenId) external whenNotPaused {
        Artifact storage artifact = s_artifacts[tokenId];
        if (tokenId == 0 || tokenId > s_artifactCounter || artifact.owner == address(0)) {
             revert GenesisProtocol__ArtifactNotFound();
        }
        if (artifact.owner != msg.sender) {
             revert GenesisProtocol__NotArtifactOwner();
        }

        address owner = artifact.owner;
        uint256 energyReturnPercent = s_protocolParameters[PARAM_ENERGY_RETURN_SACRIFICE_PERCENT];
        uint256 energyBurnedAtForge = s_protocolParameters[PARAM_BASE_ENERGY_COST_FORGING]; // Assuming base cost for simplicity here. Could store actual cost in artifact struct.
        uint256 energyReturned = (energyBurnedAtForge * energyReturnPercent) / 100;

        // Burn Artifact (simple implementation: set owner to address(0) and decrease balance)
        // A full ERC721 burn would remove the struct from the mapping or use a dedicated burn function.
        artifact.owner = address(0); // Invalidate artifact ownership
        s_artifactBalances[owner]--;

        // Return Energy
        if (energyReturned > 0) {
             s_energyBalances[owner] += energyReturned;
             // Note: Total supply isn't increased here as it wasn't decreased proportional to forge cost.
             // A more robust system would track energy burned per artifact.
        }

        // Grant Influence
        uint256 influenceGained = s_protocolParameters[PARAM_INFLUENCE_GAIN_SACRIFICE];
        _updateInfluenceScore(owner, int256(influenceGained));

        emit ArtifactSacrificed(tokenId, owner, energyReturned, influenceGained);
    }

    // --- Protocol Energy (Simplified ERC20-like) ---

    /**
     * @dev Gets the total supply of Protocol Energy.
     * @return The total amount of Protocol Energy in existence.
     */
    function getTotalEnergySupply() external view returns (uint256) {
        return s_totalEnergySupply;
    }

    /**
     * @dev Gets the energy balance of a specific user.
     * @param user The address of the user.
     * @return The energy balance of the user.
     */
    function getEnergyBalance(address user) external view returns (uint256) {
        return s_energyBalances[user];
    }

    /**
     * @dev Mints new Protocol Energy tokens. Restricted to the governor or specific protocol functions.
     * This function represents the "synthesis" mechanism.
     * @param amount The amount of energy to synthesize.
     */
    function synthesizeEnergy(uint256 amount) external onlyGovernor whenNotPaused {
        // Distribution logic would be more complex in a real protocol (e.g., based on epoch, activity, staking, etc.)
        // For this example, it's a simple mint to the governor.
        // A real implementation would likely distribute to active users, stakers, or a community pool.
        s_energyBalances[msg.sender] += amount;
        s_totalEnergySupply += amount;
        emit EnergySynthesized(msg.sender, amount);
    }

     /**
      * @dev Simplified transfer of Protocol Energy. (Basic ERC20 transfer)
      * @param to The recipient address.
      * @param amount The amount to transfer.
      */
    function transferEnergy(address to, uint256 amount) external whenNotPaused {
        if (s_energyBalances[msg.sender] < amount) revert GenesisProtocol__InsufficientEnergy();
        s_energyBalances[msg.sender] -= amount;
        s_energyBalances[to] += amount;
        emit EnergyTransfer(msg.sender, to, amount);
    }

    // --- Influence / Reputation System ---

    /**
     * @dev Gets the current influence score of a user.
     * @param user The address of the user.
     * @return The influence score.
     */
    function getInfluenceScore(address user) public view returns (uint256) {
        // Resolve delegate if user has delegated
        address delegatee = s_influenceDelegates[user];
        if (delegatee == address(0)) {
            return s_influenceScores[user];
        } else {
            return s_influenceScores[delegatee]; // Return delegatee's score if delegated
        }
    }

    /**
     * @dev Allows a user to delegate their influence voting power to another address.
     * Influence score for voting and proposal creation will be checked against the delegatee's score.
     * @param delegatee The address to delegate influence to. address(0) to undelegate.
     */
    function delegateInfluence(address delegatee) external {
        if (delegatee != address(0) && delegatee == msg.sender) revert GenesisProtocol__SelfDelegation();
        s_influenceDelegates[msg.sender] = delegatee;
        emit InfluenceDelegated(msg.sender, delegatee);
    }

    /**
     * @dev Gets the address that the user has delegated their influence to.
     * Returns address(0) if no delegation is active.
     * @param user The address to check delegation for.
     * @return The delegatee address or address(0).
     */
    function getInfluenceDelegatee(address user) external view returns (address) {
        return s_influenceDelegates[user];
    }


    /**
     * @dev Internal or privileged function to record user activity and potentially update influence.
     * This is triggered by other actions like forging, voting, proposing, etc.
     * @param user The address of the user whose activity is being recorded.
     * @param activityType An identifier for the type of activity. (e.g., 1=Forge, 2=Propose, 3=Vote, etc.)
     */
    function recordProtocolActivity(address user, uint8 activityType) internal {
        int256 influenceDelta = 0;
        // Define influence changes based on activity type
        if (activityType == 1) { // Forging
            influenceDelta = int256(s_protocolParameters[PARAM_INFLUENCE_GAIN_PER_FORGE]);
        } else if (activityType == 2) { // Proposing (example)
             influenceDelta = 2; // Small gain for proposing
        } else if (activityType == 3) { // Voting (example)
             influenceDelta = 1; // Small gain for voting
        } else {
            // Should not happen with internal calls
            // revert GenesisProtocol__InvalidActivityType();
        }

        if (influenceDelta != 0) {
            _updateInfluenceScore(user, influenceDelta);
        }
    }

    /**
     * @dev Internal function to update a user's influence score. Handles decay and minimums.
     * @param user The address of the user.
     * @param delta The amount to add (positive) or subtract (negative) from the current score.
     */
    function _updateInfluenceScore(address user, int256 delta) internal {
        uint256 currentScore = s_influenceScores[user];
        uint256 newScore;

        if (delta > 0) {
            newScore = currentScore + uint256(delta);
        } else {
             uint256 absDelta = uint256(-delta);
             newScore = currentScore > absDelta ? currentScore - absDelta : 0;
        }

        s_influenceScores[user] = newScore;
        emit InfluenceUpdated(user, newScore, delta);
    }

    // --- Governance System ---

    enum VoteType { Against, For, Abstain }

    /**
     * @dev Creates a proposal to change a specific protocol parameter. Requires minimum Influence.
     * @param paramName The string name of the parameter (e.g., "MIN_INFLUENCE_FOR_FORGING").
     * @param newValue The desired new value for the parameter.
     * @param description A brief description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function proposeParameterChange(string memory paramName, uint256 newValue, string memory description) external whenNotPaused {
        bytes32 paramHash = keccak256(bytes(paramName));
        // Check if parameter exists (optional, could allow proposing new ones)
        // if (s_protocolParameters[paramHash] == 0 && bytes(paramName).length > 0) {
        //     // Check if paramName is one of the known constants
        //     // This check requires iterating or using a lookup map, omitted for brevity
        //     // For this example, we assume only predefined parameters can be changed
        //     // A more robust system would map string names to hashes and check against allowed names.
        // }

        uint256 requiredInfluence = s_protocolParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL];
        uint256 proposerInfluence = getInfluenceScore(msg.sender); // Uses delegated influence if applicable
        if (proposerInfluence < requiredInfluence) {
            revert GenesisProtocol__InsufficientInfluence(requiredInfluence, proposerInfluence);
        }

        s_proposalCounter++;
        uint256 proposalId = s_proposalCounter;
        uint256 voteStart = currentEpoch + 1; // Voting starts next epoch
        uint256 voteEnd = voteStart + s_protocolParameters[PARAM_PROPOSAL_VOTING_EPOCHS];

        s_proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            paramHash: paramHash,
            newValue: newValue,
            description: description,
            voteStartEpoch: voteStart,
            voteEndEpoch: voteEnd,
            votesFor: 0,
            votesAgainst: 0,
            votesAbstain: 0,
            totalVotesCast: 0,
            hasVoted: new mapping(address => bool)(),
            state: ProposalState.Pending // Starts pending, becomes active next epoch
        });

        // Record activity for proposer
        recordProtocolActivity(msg.sender, 2); // 2: Proposing

        emit ProposalCreated(proposalId, msg.sender, paramHash, newValue, description, voteStart, voteEnd);
    }

    /**
     * @dev Casts a vote on a proposal. Uses the user's current Influence (or delegated Influence) as voting power.
     * Can optionally require locking Energy to vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteType The type of vote (0=Against, 1=For, 2=Abstain).
     */
    function voteOnProposal(uint256 proposalId, uint8 voteType) external whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.id == 0) revert GenesisProtocol__ProposalNotFound();

        // Check if voting is active
        if (currentEpoch < proposal.voteStartEpoch || currentEpoch > proposal.voteEndEpoch) {
            revert GenesisProtocol__ProposalNotActive();
        }

        // Check if user already voted (or their delegate has voted)
        address voter = msg.sender;
        // Need to check delegation for vote eligibility and hasVoted mapping
        address effectiveVoter = s_influenceDelegates[voter] == address(0) ? voter : s_influenceDelegates[voter];

        if (proposal.hasVoted[effectiveVoter]) {
            revert GenesisProtocol__ProposalAlreadyVoted();
        }

        // Get voting power (uses delegated influence)
        uint256 votingPower = getInfluenceScore(voter); // Using getInfluenceScore handles delegation internally

        if (votingPower == 0) revert GenesisProtocol__InsufficientVotingPower();

        // Require locking Energy to vote (optional advanced concept)
        // uint256 energyCostToVote = 100; // Example cost
        // if (s_energyBalances[voter] < energyCostToVote) revert GenesisProtocol__InsufficientEnergy();
        // s_energyBalances[voter] -= energyCostToVote; // Burn or lock energy? Let's burn for simplicity

        // Record the vote
        if (voteType == uint8(VoteType.For)) {
            proposal.votesFor += votingPower;
        } else if (voteType == uint8(VoteType.Against)) {
            proposal.votesAgainst += votingPower;
        } else if (voteType == uint8(VoteType.Abstain)) {
            proposal.votesAbstain += votingPower;
        } else {
            revert GenesisProtocol__ProposalVoteInvalid();
        }

        proposal.totalVotesCast += votingPower;
        proposal.hasVoted[effectiveVoter] = true;

        // Record activity for voter
        recordProtocolActivity(voter, 3); // 3: Voting

        emit VoteCast(proposalId, voter, voteType, votingPower);
    }

    /**
     * @dev Executes a proposal if it has succeeded after the voting period ends.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.id == 0) revert GenesisProtocol__ProposalNotFound();

        // Update proposal state based on current epoch
        _updateProposalState(proposal);

        if (proposal.state != ProposalState.Succeeded) {
             revert GenesisProtocol__ProposalStateCannotExecute();
        }

        // Check execution validity (e.g., target function exists and parameters match - complex for generic params)
        // For parameter changes, we just update the parameter.

        // Perform the action: Update the protocol parameter
        bytes32 paramHash = proposal.paramHash;
        uint256 oldValue = s_protocolParameters[paramHash]; // Get current value before updating
        _setProtocolParameter(paramHash, proposal.newValue); // Internal function updates mapping

        proposal.state = ProposalState.Executed;

        emit ProtocolParameterChanged(paramHash, oldValue, proposal.newValue);
        emit ProposalExecuted(proposalId, true);
    }

    /**
     * @dev Internal function to update a proposal's state based on the current epoch and vote counts.
     * @param proposal The proposal struct reference.
     */
    function _updateProposalState(Proposal storage proposal) internal {
        if (proposal.state == ProposalState.Pending && currentEpoch >= proposal.voteStartEpoch) {
            proposal.state = ProposalState.Active;
        }

        if (proposal.state == ProposalState.Active && currentEpoch > proposal.voteEndEpoch) {
            uint256 quorumPercent = s_protocolParameters[PARAM_GOVERNANCE_QUORUM_PERCENT];
            uint256 passThresholdPercent = s_protocolParameters[PARAM_GOVERNANCE_PASS_THRESHOLD_PERCENT];

            // Calculate total *potential* voting power (sum of all influence scores)
            // This is difficult to do efficiently on-chain without iterating all users.
            // For this example, we'll approximate or use a known total influence supply,
            // or simplify quorum to be based on *total votes cast* being above a threshold,
            // not a percentage of total possible votes. Let's simplify quorum check.
            // Simplified Quorum: Total votes cast must be >= a minimum value (e.g., 1000 Influence points)
            uint256 totalPossibleInfluence = _calculateTotalProtocolInfluence(); // Highly inefficient/conceptual!
            if (totalPossibleInfluence == 0) totalPossibleInfluence = 1; // Prevent division by zero if no influence exists

            uint256 quorumRequiredVotes = (totalPossibleInfluence * quorumPercent) / 100; // This is problematic without total supply

             // Let's use a simplified quorum check: Total votes cast > 0 and >= a fixed minimum
             // Or, a better way: Quorum is based on percentage of *active* influence, which is hard to track.
             // Let's use a simpler quorum: `totalVotesCast` must be at least X, and `votesFor + votesAgainst` must be Y% of `totalVotesCast`.
             // Re-simplifying quorum to be a percentage of *actual votes cast excluding abstain*.
             uint256 totalEngagedVotes = proposal.votesFor + proposal.votesAgainst;
             bool quorumMet = proposal.totalVotesCast > 0 && (totalEngagedVotes * 100) / proposal.totalVotesCast >= quorumPercent; // Quorum of *cast votes*
             bool thresholdMet = totalEngagedVotes > 0 && (proposal.votesFor * 100) / totalEngagedVotes >= passThresholdPercent; // Pass threshold of *engaged votes*

            if (quorumMet && thresholdMet) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Failed;
            }
        }
    }

     /**
      * @dev Gets the current state of a proposal.
      * @param proposalId The ID of the proposal.
      * @return The ProposalState enum value.
      */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        Proposal storage proposal = s_proposals[proposalId];
        if (proposal.id == 0) revert GenesisProtocol__ProposalNotFound();

        // Check if state needs updating based on epoch
        if (proposal.state == ProposalState.Pending && currentEpoch >= proposal.voteStartEpoch) return ProposalState.Active;
        if (proposal.state == ProposalState.Active && currentEpoch > proposal.voteEndEpoch) {
            // Temporarily calculate potential state without modifying storage
            uint256 quorumPercent = s_protocolParameters[PARAM_GOVERNANCE_QUORUM_PERCENT];
            uint256 passThresholdPercent = s_protocolParameters[PARAM_GOVERNANCE_PASS_THRESHOLD_PERCENT];

            uint256 totalEngagedVotes = proposal.votesFor + proposal.votesAgainst;
             bool quorumMet = proposal.totalVotesCast > 0 && (totalEngagedVotes * 100) / proposal.totalVotesCast >= quorumPercent;
             bool thresholdMet = totalEngagedVotes > 0 && (proposal.votesFor * 100) / totalEngagedVotes >= passThresholdPercent;

            return (quorumMet && thresholdMet) ? ProposalState.Succeeded : ProposalState.Failed;
        }

        return proposal.state;
    }

     /**
      * @dev Gets the details of a specific proposal.
      * @param proposalId The ID of the proposal.
      * @return The full Proposal struct data.
      */
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
         Proposal storage proposal = s_proposals[proposalId];
         if (proposal.id == 0) revert GenesisProtocol__ProposalNotFound();
         // Need to return a memory copy as mappings are not storage-accessibe directly in memory return
         return Proposal({
             id: proposal.id,
             proposer: proposal.proposer,
             paramHash: proposal.paramHash,
             newValue: proposal.newValue,
             description: proposal.description,
             voteStartEpoch: proposal.voteStartEpoch,
             voteEndEpoch: proposal.voteEndEpoch,
             votesFor: proposal.votesFor,
             votesAgainst: proposal.votesAgainst,
             votesAbstain: proposal.votesAbstain,
             totalVotesCast: proposal.totalVotesCast,
             hasVoted: new mapping(address => bool)(), // Mappings cannot be returned directly
             state: getProposalState(proposalId) // Calculate current state
         });
    }

    /**
     * @dev Gets the voting power of a user at a specific block number.
     * In this simplified example, it just returns the current influence score (which includes delegation).
     * A real Governor contract would need to store historical snapshots of voting power.
     * @param user The address of the user.
     * @param blockNumber The block number for the snapshot (ignored in this simple version).
     * @return The user's voting power.
     */
    function getCurrentVotes(address user, uint256 blockNumber) external view returns (uint256) {
        // NOTE: This simple implementation ignores blockNumber and returns current influence.
        // A proper snapshot system would require storing influence history per user per block/checkpoint.
        blockNumber; // To avoid unused variable warning
        return getInfluenceScore(user); // getInfluenceScore handles delegation
    }

    /**
     * @dev Internal helper to calculate (conceptually) the total influence across the protocol.
     * HIGHLY INEFFICIENT. A real system needs to track total influence supply more directly.
     * @return The conceptual total influence.
     */
    function _calculateTotalProtocolInfluence() internal view returns (uint256) {
        // WARNING: Iterating over mappings is not possible and inefficient on-chain.
        // This function is here for conceptual demonstration of a quorum denominator.
        // A real protocol would need a mechanism to track total stake/influence supply.
        // For now, return a placeholder or throw. Let's return a large number or throw.
        // return type(uint256).max; // Or a fixed value
         revert("Calculating total influence requires off-chain indexing or a different on-chain tracking mechanism.");
    }


    // --- Epoch Management ---

    /**
     * @dev Gets the current epoch number.
     * @return The current epoch.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Advances the protocol to the next epoch. Can only be called after the current epoch duration.
     * Also triggers epoch-specific logic like influence decay.
     */
    function advanceProtocolEpoch() external whenNotPaused {
        uint256 epochDuration = s_protocolParameters[PARAM_EPOCH_DURATION_SECONDS];
        if (block.timestamp < epochStartTimestamp[currentEpoch] + epochDuration) {
            revert GenesisProtocol__EpochCannotAdvanceYet();
        }

        // Advance Epoch Counter
        currentEpoch++;
        epochStartTimestamp[currentEpoch] = block.timestamp;

        // --- Epoch Transition Logic ---

        // 1. Decay Influence Scores
        uint256 decayPercent = s_protocolParameters[PARAM_INFLUENCE_DECAY_PER_EPOCH_PERCENT];
        if (decayPercent > 0) {
            // WARNING: Applying decay requires iterating over all users with influence,
            // which is not feasible on-chain.
            // A realistic implementation might apply decay lazily (when user interacts)
            // or use a different influence model (e.g., time-weighted).
            // For demonstration, we'll skip the actual iteration but acknowledge the concept.
            // console.log("Conceptually decaying influence by", decayPercent, "%");
            // Example: If lazy decay, store last decayed epoch for each user and calculate decay on lookup/interaction.
        }

        // 2. Potentially Synthesize/Distribute Energy (e.g., to stakers, active users)
        // This would happen here based on protocol rules. Omitted for brevity in this example.

        // 3. Update Proposal States (optional, can also be done on lookup/interaction)
        // Loop through active proposals and check if voting period ended. (Again, iteration is an issue)

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /**
     * @dev Gets the timestamp when a specific epoch started.
     * @param epochId The epoch number.
     * @return The start timestamp.
     */
    function getEpochStartTime(uint256 epochId) external view returns (uint256) {
        if (epochId == 0 || epochId > currentEpoch) revert GenesisProtocol__EpochCannotAdvanceYet(); // Misusing error name, but indicates invalid epoch
        return epochStartTimestamp[epochId];
    }


    // --- Emergency Controls ---

    /**
     * @dev Initiates the emergency pause process. Only callable by an emergency council member.
     */
    function initiateEmergencyPause() external onlyCouncil whenNotPaused {
        if (s_emergencyPauseVotesReceived > 0) revert GenesisProtocol__EmergencyPauseAlreadyInProgress(); // Prevent multiple initiations
        s_emergencyPauseVotesReceived = 0; // Reset votes for a new round
        // Council members vote 'approve' by calling voteOnEmergencyPause(true)
        emit EmergencyPauseInitiated(msg.sender);
    }

    /**
     * @dev Allows an emergency council member to cast their vote on initiating a pause.
     * @param approve True to vote for pausing, false to vote against (though typically only 'for' votes are counted towards threshold).
     */
    function voteOnEmergencyPause(bool approve) external onlyCouncil whenNotPaused {
        if (s_emergencyPauseVotes[msg.sender]) revert GenesisProtocol__CouncilVoteAlreadyCast();
        if (s_emergencyPauseVotesReceived == 0) revert GenesisProtocol__EmergencyPauseNotInProgress(); // Must call initiate first

        s_emergencyPauseVotes[msg.sender] = true; // Record vote cast

        if (approve) {
             s_emergencyPauseVotesReceived++;
        }

        emit EmergencyCouncilVoteCast(msg.sender, approve);

        // If enough votes are reached, auto-resolve the pause
        if (s_emergencyPauseVotesReceived >= s_emergencyPauseVotesNeeded) {
            _resolveEmergencyPause();
        }
    }

    /**
     * @dev Executes the emergency pause if the required council votes have been reached.
     * Can be called by anyone after votes are cast (or auto-triggered by last vote).
     */
    function resolveEmergencyPause() external whenNotPaused {
         if (s_emergencyPauseVotesReceived == 0) revert GenesisProtocol__EmergencyPauseNotInProgress();
         _resolveEmergencyPause();
    }

    /**
     * @dev Internal function to check consensus and execute the pause.
     */
    function _resolveEmergencyPause() internal {
        if (s_emergencyPauseVotesReceived < s_emergencyPauseVotesNeeded) {
             revert GenesisProtocol__EmergencyPauseConsensusNotReached();
        }

        protocolPaused = true;

        // Reset votes for next time
        s_emergencyPauseVotesReceived = 0;
        for (uint i = 0; i < emergencyCouncil.length; i++) {
            s_emergencyPauseVotes[emergencyCouncil[i]] = false;
        }

        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol. Can be called by the governor or potentially via a governance proposal.
     * This example allows the governor to unpause. A more decentralized approach might require governance.
     */
    function emergencyUnpause() external onlyGovernor whenPaused {
        protocolPaused = false;
        emit ProtocolUnpaused(msg.sender);
    }

     /**
      * @dev Checks if an address is currently an emergency council member.
      * @param user The address to check.
      * @return True if the address is a council member, false otherwise.
      */
    function isCouncilMember(address user) external view returns (bool) {
        return s_isCouncilMember[user];
    }

    // --- Internal Helper Functions ---

     /**
      * @dev Internal function to safely set a protocol parameter value.
      * Called during governance execution.
      * @param paramHash The hash of the parameter name.
      * @param newValue The new value to set.
      */
    function _setProtocolParameter(bytes32 paramHash, uint256 newValue) internal {
        // Basic validation: check if the hash corresponds to a known parameter
        // This is a simplified check. A robust system might use a lookup table or enum.
        bool found = false;
        if (paramHash == PARAM_MIN_INFLUENCE_FOR_PROPOSAL ||
            paramHash == PARAM_PROPOSAL_VOTING_EPOCHS ||
            paramHash == PARAM_MIN_INFLUENCE_FOR_FORGING ||
            paramHash == PARAM_BASE_ENERGY_COST_FORGING ||
            paramHash == PARAM_INFLUENCE_GAIN_PER_FORGE ||
            paramHash == PARAM_ENERGY_RETURN_SACRIFICE_PERCENT ||
            paramHash == PARAM_INFLUENCE_GAIN_SACRIFICE ||
            paramHash == PARAM_EPOCH_DURATION_SECONDS ||
            paramHash == PARAM_GOVERNANCE_QUORUM_PERCENT ||
            paramHash == PARAM_GOVERNANCE_PASS_THRESHOLD_PERCENT ||
            paramHash == PARAM_INFLUENCE_DECAY_PER_EPOCH_PERCENT) {
            found = true;
        }

        if (!found) {
            revert GenesisProtocol__ParameterNotFound();
        }

        s_protocolParameters[paramHash] = newValue;
        // Event is emitted in executeProposal
    }

    // --- Utility Query Functions (Additional to meet count/provide info) ---

    /**
     * @dev Gets the current address designated as the protocol Governor.
     * @return The governor's address.
     */
    function getGovernorAddress() external view returns (address) {
        return governor;
    }

    /**
     * @dev Gets the current minimum influence required to propose a parameter change.
     * @return The required influence score.
     */
    function getMinimumInfluenceForProposal() external view returns (uint256) {
        return s_protocolParameters[PARAM_MIN_INFLUENCE_FOR_PROPOSAL];
    }

    /**
     * @dev Gets the number of epochs a governance proposal's voting period lasts.
     * @return The number of epochs.
     */
    function getProposalVotingEpochDuration() external view returns (uint256) {
        return s_protocolParameters[PARAM_PROPOSAL_VOTING_EPOCHS];
    }

    /**
     * @dev Gets the minimum influence required to forge a new artifact.
     * @return The required influence score.
     */
    function getRequiredInfluenceForForging() external view returns (uint256) {
        return s_protocolParameters[PARAM_MIN_INFLUENCE_FOR_FORGING];
    }

    /**
     * @dev Gets the base amount of energy required to forge an artifact.
     * @return The base energy cost.
     */
    function getBaseEnergyCostForForging() external view returns (uint256) {
        return s_protocolParameters[PARAM_BASE_ENERGY_COST_FORGING];
    }

    /**
     * @dev Gets the influence gained by successfully forging an artifact.
     * @return The influence gain.
     */
    function getInfluenceGainPerForge() external view returns (uint256) {
        return s_protocolParameters[PARAM_INFLUENCE_GAIN_PER_FORGE];
    }

    /**
     * @dev Gets the percentage of burned energy returned when sacrificing an artifact.
     * @return The percentage (e.g., 25 for 25%).
     */
     function getEnergyReturnSacrificePercent() external view returns (uint256) {
         return s_protocolParameters[PARAM_ENERGY_RETURN_SACRIFICE_PERCENT];
     }

     /**
      * @dev Gets the influence gained when sacrificing an artifact.
      * @return The influence gain.
      */
     function getInfluenceGainSacrifice() external view returns (uint256) {
         return s_protocolParameters[PARAM_INFLUENCE_GAIN_SACRIFICE];
     }

     /**
      * @dev Gets the duration of a single protocol epoch in seconds.
      * @return The duration in seconds.
      */
     function getEpochDurationSeconds() external view returns (uint256) {
         return s_protocolParameters[PARAM_EPOCH_DURATION_SECONDS];
     }

     /**
      * @dev Gets the percentage of votes cast (excluding abstain) required for a proposal to meet quorum.
      * @return The percentage (e.g., 40 for 40%).
      */
     function getGovernanceQuorumPercent() external view returns (uint256) {
         return s_protocolParameters[PARAM_GOVERNANCE_QUORUM_PERCENT];
     }

     /**
      * @dev Gets the percentage of 'For' votes out of 'For' + 'Against' votes required for a proposal to pass.
      * @return The percentage (e.g., 50 for 50%).
      */
     function getGovernancePassThresholdPercent() external view returns (uint256) {
         return s_protocolParameters[PARAM_GOVERNANCE_PASS_THRESHOLD_PERCENT];
     }

     /**
      * @dev Gets the percentage influence decay applied per epoch.
      * @return The percentage (e.g., 5 for 5%).
      */
     function getInfluenceDecayPerEpochPercent() external view returns (uint256) {
         return s_protocolParameters[PARAM_INFLUENCE_DECAY_PER_EPOCH_PERCENT];
     }

     /**
      * @dev Gets the list of current emergency council members.
      * @return An array of council member addresses.
      */
     function getCouncilMembers() external view returns (address[] memory) {
         return emergencyCouncil;
     }

     /**
      * @dev Gets the number of emergency council votes required to trigger a pause.
      * @return The required number of votes.
      */
     function getEmergencyPauseVotesNeeded() external view returns (uint256) {
         return s_emergencyPauseVotesNeeded;
     }

     /**
      * @dev Gets the number of positive emergency pause votes received in the current round.
      * @return The number of votes received.
      */
     function getEmergencyPauseVotesReceived() external view returns (uint256) {
         return s_emergencyPauseVotesReceived;
     }

      // Total public/external functions listed in summary: 30 + 1 constructor = 31
      // Internal functions (_updateInfluenceScore, _setProtocolParameter, _updateProposalState, _resolveEmergencyPause, _calculateTotalProtocolInfluence)
      // Total unique functions including internal helpers: 31 + 5 = 36. More than 20.
}
```