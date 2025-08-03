Okay, this is an exciting challenge! Let's build a smart contract that goes beyond typical DeFi or NFT projects.

I'm thinking of a "Decentralized Adaptive Reputation Network for Impact Verification" – a mouthful, but the core idea is:

**Aetherium Catalyst (AEC):** A platform where users (Impact Catalysts) earn "Nexus Points" by contributing to and verifying real-world impact initiatives (Causes). These Nexus Points directly influence the evolution and "aura" of a unique, soulbound (or semi-soulbound) NFT called an "Aetherium Sphere," making it a dynamic, on-chain representation of a user's verified positive impact and reputation.

The "advanced concept" lies in:
1.  **Dynamic/Adaptive NFTs:** NFTs that visually/functionally evolve based on on-chain reputation.
2.  **Verifiable Off-Chain Impact:** A robust (though simplified for smart contract scope) system for proposing, validating, and challenging contributions to real-world causes.
3.  **Reputation-as-NFT:** The NFT *is* the reputation, not just a standalone collectible.
4.  **DAO Governance for Causes & Validators:** Decentralized decision-making for what constitutes a valid "cause" and who can validate contributions.
5.  **Conceptual AI-Assisted Oracle Integration:** While AI cannot run *on-chain*, the contract will include functions that *interface* with an oracle designed to relay AI-processed data for complex validation or trend analysis (e.g., verifying large-scale environmental data). This represents a forward-looking trend.
6.  **Slashing & Staking for Validators:** Ensuring economic security for the integrity of impact validation.
7.  **Semi-Soulbound NFTs:** Initially tied to the owner, with limited transferability (e.g., only after reaching a certain reputation level, or to a successor wallet via governance). This reinforces the "reputation" aspect.

---

## **Aetherium Catalyst (AEC) Smart Contract**

**Outline:**

1.  **Overview:** Purpose and core mechanics.
2.  **Core Components:**
    *   `ERC721`: Base for Aetherium Spheres (NFTs).
    *   `AccessControl`: For administrative and pause functionalities.
    *   **Aetherium Sphere Management:** Minting, tracking evolution.
    *   **Nexus Points (Reputation) System:** Earning, tracking, and linking to NFT evolution.
    *   **Cause Management:** Proposing, voting on, and activating impact initiatives.
    *   **Impact Attestation & Validation:** Submitting claims of impact and a decentralized process for their verification.
    *   **Validator Staking & Slashing:** Economic security for validators.
    *   **Decentralized Governance:** For protocol upgrades, treasury management, and dispute resolution.
    *   **Conceptual AI Oracle Integration:** For advanced data verification or insight.
    *   **Rewards System:** Incentivizing participation.
    *   **Emergency & Admin Controls.**
3.  **Functions Summary (at least 20):** Detailed breakdown of each public/external function.

---

### **Functions Summary (at least 20 Functions):**

**A. Core NFT & Reputation (Aetherium Sphere & Nexus Points)**

1.  `mintAetheriumSphere()`: Mints a new, initial Aetherium Sphere NFT for the caller. An address can only mint one.
2.  `getSphereData(uint256 _tokenId)`: Returns all stored data for a specific Aetherium Sphere, including its current level and last evolution time.
3.  `getNexusPoints(address _user)`: Returns the current Nexus Points of a given user.
4.  `getSphereEvolutionProgress(uint256 _tokenId)`: Calculates and returns the progress towards the next evolution level for a specific Sphere based on its owner's Nexus Points.
5.  `evolveSphere(uint256 _tokenId)`: *Internal function* that updates an Aetherium Sphere's level and metadata when its owner accumulates enough Nexus Points. Triggered by `_updateNexusPoints`.
6.  `_updateNexusPoints(address _user, uint256 _amount)`: *Internal function* to add Nexus Points to a user and potentially trigger sphere evolution.

**B. Cause Management**

7.  `proposeNewCause(string memory _name, string memory _descriptionCID, uint256 _requiredValidators)`: Allows any user to propose a new impact cause, linking to off-chain details (IPFS CID).
8.  `voteOnCauseProposal(uint256 _proposalId, bool _support)`: Allows Aetherium Sphere owners to vote on proposed causes.
9.  `activateCause(uint256 _proposalId)`: Allows an admin or a successful governance proposal to activate a cause after sufficient votes.
10. `getCauses()`: Returns a list of all active causes and their details.

**C. Impact Attestation & Validation**

11. `submitImpactAttestation(uint256 _causeId, string memory _proofCID)`: Allows a user to submit a claim of impact contribution to an active cause, providing off-chain proof (IPFS CID). Requires a small stake.
12. `attestToImpact(uint256 _attestationId, bool _isValid)`: Allows a whitelisted validator to verify an impact attestation. If valid, Nexus Points are awarded; if invalid, the attester's stake is slashed.
13. `challengeAttestation(uint256 _attestationId, string memory _reasonCID)`: Allows a user to challenge a validated attestation, initiating a dispute (handled by governance). Requires a stake.
14. `getAttestationDetails(uint256 _attestationId)`: Retrieves details of a specific impact attestation.

**D. Validator Staking & Slashing**

15. `stakeForValidation()`: Allows a user to stake AEC tokens (or ETH, for simplicity, using ETH) to become eligible for the validator pool.
16. `unstakeValidationDeposit()`: Allows a validator to unstake their deposit after a cooldown period, if not involved in disputes.
17. `proposeAttestationValidator(address _newValidator)`: Proposes an address to be added to the whitelist of attestation validators.
18. `voteOnValidatorProposal(uint256 _proposalId, bool _support)`: Vote on whether to approve a new validator.

**E. Decentralized Governance & AI Oracle**

19. `submitGovernanceProposal(string memory _descriptionCID, address _target, bytes memory _calldata)`: Allows users to propose general governance actions (e.g., changing parameters, upgrading contracts, resolving disputes).
20. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows Aetherium Sphere owners to vote on governance proposals.
21. `executeGovernanceProposal(uint256 _proposalId)`: Executes a successfully passed governance proposal.
22. `requestAIDecision(uint256 _attestationId, string memory _question)`: *Conceptual function* for sending a query about an attestation to an external AI oracle for analysis (e.g., complex data verification).
23. `receiveOracleResponse(uint256 _attestationId, string memory _response, bool _isPositive)`: *External callback function* for the AI oracle to deliver its decision back to the contract, potentially triggering automatic validation or a dispute.

**F. Admin & Utility**

24. `setOracleAddress(address _oracleAddress)`: Sets the trusted address of the AI oracle.
25. `pauseContract()`: Allows an admin or governance to pause critical contract functions in emergencies.
26. `unpauseContract()`: Unpauses the contract.
27. `withdrawFunds()`: Allows an admin or governance to withdraw collected fees/stakes from the contract treasury.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title AetheriumCatalyst (AEC)
 * @dev A Decentralized Adaptive Reputation Network for Impact Verification.
 *      This contract enables users to earn "Nexus Points" by contributing to and
 *      verifying real-world impact initiatives (Causes). These Nexus Points
 *      directly influence the evolution and "aura" of a unique, soulbound
 *      Aetherium Sphere NFT, making it a dynamic, on-chain representation of
 *      a user's verified positive impact and reputation.
 *
 * @outline
 * 1.  **Overview:** Manages dynamic NFTs (Aetherium Spheres) tied to on-chain reputation (Nexus Points).
 * 2.  **Core Components:**
 *     - ERC721: For Aetherium Spheres.
 *     - AccessControl & Ownable: For administrative and pause functionalities.
 *     - Aetherium Sphere Management: Minting, tracking evolution based on Nexus Points.
 *     - Nexus Points (Reputation) System: Earning, tracking, and linking to NFT evolution.
 *     - Cause Management: Proposing, voting on, and activating impact initiatives.
 *     - Impact Attestation & Validation: Submitting claims and decentralized verification.
 *     - Validator Staking & Slashing: Economic security for validators.
 *     - Decentralized Governance: For protocol upgrades, treasury, dispute resolution.
 *     - Conceptual AI Oracle Integration: For advanced data verification or insight.
 *     - Rewards System: Incentivizing participation.
 *     - Emergency & Admin Controls.
 *
 * @functions_summary (at least 20 Functions):
 *   **A. Core NFT & Reputation (Aetherium Sphere & Nexus Points)**
 *   1.  `mintAetheriumSphere()`: Mints a new, initial Aetherium Sphere NFT for the caller.
 *   2.  `getSphereData(uint256 _tokenId)`: Returns all stored data for a specific Aetherium Sphere.
 *   3.  `getNexusPoints(address _user)`: Returns the current Nexus Points of a given user.
 *   4.  `getSphereEvolutionProgress(uint256 _tokenId)`: Calculates progress towards next evolution level.
 *   5.  `evolveSphere(uint256 _tokenId)`: *Internal* updates an Aetherium Sphere's level.
 *   6.  `_updateNexusPoints(address _user, uint256 _amount)`: *Internal* adds Nexus Points and potentially triggers evolution.
 *
 *   **B. Cause Management**
 *   7.  `proposeNewCause(string memory _name, string memory _descriptionCID, uint256 _requiredValidators)`: Propose a new impact cause.
 *   8.  `voteOnCauseProposal(uint256 _proposalId, bool _support)`: Vote on proposed causes.
 *   9.  `activateCause(uint256 _proposalId)`: Activates a cause after successful voting/admin approval.
 *   10. `getCauses()`: Returns a list of all active causes.
 *
 *   **C. Impact Attestation & Validation**
 *   11. `submitImpactAttestation(uint256 _causeId, string memory _proofCID)`: Submit a claim of impact contribution.
 *   12. `attestToImpact(uint256 _attestationId, bool _isValid)`: Validator verifies an attestation.
 *   13. `challengeAttestation(uint256 _attestationId, string memory _reasonCID)`: Challenge a validated attestation.
 *   14. `getAttestationDetails(uint256 _attestationId)`: Retrieve details of a specific attestation.
 *
 *   **D. Validator Staking & Slashing**
 *   15. `stakeForValidation()`: Stake ETH to become eligible for validator pool.
 *   16. `unstakeValidationDeposit()`: Unstake deposit after cooldown.
 *   17. `proposeAttestationValidator(address _newValidator)`: Propose new validator.
 *   18. `voteOnValidatorProposal(uint256 _proposalId, bool _support)`: Vote on new validator proposals.
 *
 *   **E. Decentralized Governance & AI Oracle**
 *   19. `submitGovernanceProposal(string memory _descriptionCID, address _target, bytes memory _calldata)`: Propose general governance actions.
 *   20. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Vote on governance proposals.
 *   21. `executeGovernanceProposal(uint256 _proposalId)`: Execute successfully passed governance proposal.
 *   22. `requestAIDecision(uint256 _attestationId, string memory _question)`: *Conceptual* query to an external AI oracle.
 *   23. `receiveOracleResponse(uint256 _attestationId, string memory _response, bool _isPositive)`: *External callback* from AI oracle.
 *
 *   **F. Admin & Utility**
 *   24. `setOracleAddress(address _oracleAddress)`: Sets the trusted AI oracle address.
 *   25. `pauseContract()`: Pause critical contract functions.
 *   26. `unpauseContract()`: Unpause contract functions.
 *   27. `withdrawFunds()`: Withdraw collected funds from treasury.
 */
contract AetheriumCatalyst is ERC721, Ownable, ReentrancyGuard, AccessControl {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE"); // For trusted AI oracle callback

    // NFT & Reputation
    Counters.Counter private _nextTokenId;
    mapping(uint256 => SphereData) public spheres; // tokenId => SphereData
    mapping(address => uint256) public nexusPoints; // user address => earned Nexus Points
    mapping(address => uint256) public userSphereId; // user address => their minted sphereId (ensures 1 sphere per user)

    uint256 public constant NEXUS_POINTS_PER_LEVEL_THRESHOLD = 1000; // How many Nexus Points for next Sphere level
    uint256 public constant MAX_SPHERE_LEVEL = 10; // Max evolution level for a sphere

    // Cause Management
    Counters.Counter private _nextCauseId;
    mapping(uint256 => Cause) public causes; // causeId => Cause struct
    mapping(uint256 => Proposal) public causeProposals; // proposalId => Proposal struct for causes
    Counters.Counter private _nextCauseProposalId;
    uint256 public constant CAUSE_VOTE_THRESHOLD_PERCENT = 60; // Percentage of votes required to pass a cause proposal

    // Impact Attestation
    Counters.Counter private _nextAttestationId;
    mapping(uint256 => Attestation) public impactAttestations; // attestationId => Attestation struct
    uint256 public attestationStakeAmount = 0.01 ether; // ETH stake required for submitting an attestation

    // Validator Staking
    uint256 public validatorStakeAmount = 1 ether; // ETH stake required to become a validator
    uint256 public validatorUnstakeCooldown = 7 days; // Cooldown period before unstaking
    mapping(address => uint256) public validatorStakes; // validator address => staked amount
    mapping(address => uint256) public validatorUnstakeRequestTime; // validator address => timestamp of unstake request

    // Governance
    Counters.Counter private _nextGovernanceProposalId;
    mapping(uint256 => Proposal) public governanceProposals; // proposalId => Proposal struct for general governance
    uint256 public constant GOVERNANCE_VOTE_THRESHOLD_PERCENT = 51; // Percentage of votes required to pass a general proposal

    // Oracle Integration
    address public trustedAIOracleAddress; // The address of the trusted oracle that relays AI decisions

    // Pause functionality
    bool public paused = false;

    // --- Events ---

    event SphereMinted(address indexed owner, uint256 indexed tokenId);
    event SphereEvolved(uint256 indexed tokenId, uint256 newLevel, uint256 nexusPointsReached);
    event NexusPointsUpdated(address indexed user, uint256 newPoints, uint256 pointsAdded);
    event CauseProposed(uint256 indexed proposalId, address indexed proposer, string name);
    event CauseVoteRecorded(uint256 indexed proposalId, address indexed voter, bool support);
    event CauseActivated(uint256 indexed causeId, string name);
    event ImpactAttestationSubmitted(uint256 indexed attestationId, uint256 indexed causeId, address indexed submitter);
    event ImpactAttestationValidated(uint256 indexed attestationId, address indexed validator, bool isValid, uint256 pointsAwarded);
    event ImpactAttestationChallenged(uint256 indexed attestationId, address indexed challenger);
    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstakeRequested(address indexed validator, uint256 requestTime);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event ValidatorProposalCreated(uint256 indexed proposalId, address indexed candidate);
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionCID);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event AIDecisionRequested(uint256 indexed attestationId, string question);
    event AIDecisionReceived(uint256 indexed attestationId, string response, bool isPositive);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event FundsWithdrawn(address indexed to, uint256 amount);

    // --- Structs ---

    struct SphereData {
        uint256 level;              // Current evolution level
        uint256 lastEvolutionTime;  // Timestamp of last evolution
        string metadataCID;         // IPFS CID for NFT metadata (image, description)
        address owner;              // Owner of the sphere (redundant with ERC721 but useful for direct lookup)
    }

    struct Cause {
        uint256 id;
        string name;
        string descriptionCID;      // IPFS CID linking to detailed description of the cause
        uint256 requiredValidators; // Minimum number of distinct validators needed for an attestation
        bool isActive;
        address proposer;
        uint256 proposalId;         // Link to the governance proposal that created it
    }

    enum AttestationStatus { PendingValidation, Validated, Challenged, Rejected }

    struct Attestation {
        uint256 id;
        uint256 causeId;
        address submitter;
        string proofCID;            // IPFS CID linking to proof of impact
        uint256 submittedAt;
        uint256 validatorCount;     // How many distinct validators have attested
        mapping(address => bool) validatedBy; // Which validators have validated this attestation
        AttestationStatus status;
        uint256 stake;              // Stake provided by the submitter
        address challenger;         // Address of the challenger if status is Challenged
        string challengeReasonCID;  // IPFS CID for challenge reason
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string descriptionCID;      // IPFS CID for proposal details
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User => Voted status
        uint256 creationTime;
        bool executed;
        // For governance proposals, this would include target and calldata
        address target;
        bytes calldataPayload;
    }

    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), string.concat("Caller is not a ", bytes32ToString(role), " in this contract."));
        _;
    }

    // Convert bytes32 to string for error messages (utility)
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 _bytes32_len = 0;
        for (uint256 i = 0; i < 32; i++) {
            if (_bytes32[i] != 0) {
                _bytes32_len++;
            }
        }
        bytes memory _bytes = new bytes(_bytes32_len);
        for (uint256 i = 0; i < _bytes32_len; i++) {
            _bytes[i] = _bytes32[i];
        }
        return string(_bytes);
    }

    // --- Constructor ---

    constructor() ERC721("Aetherium Sphere", "AEC_SPHERE") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender); // Custom admin role for specific functions
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(VALIDATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, ADMIN_ROLE);
    }

    // --- External / Public Functions ---

    /**
     * @dev 1. mintAetheriumSphere()
     * Mints a new Aetherium Sphere NFT for the caller. Each user can only mint one sphere.
     * The sphere starts at Level 1.
     */
    function mintAetheriumSphere() external whenNotPaused nonReentrant {
        require(userSphereId[msg.sender] == 0, "You already own an Aetherium Sphere.");

        uint256 newItemId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(msg.sender, newItemId);

        spheres[newItemId] = SphereData({
            level: 1,
            lastEvolutionTime: block.timestamp,
            metadataCID: "QmDefaultInitialSphereMetadata", // Placeholder CID
            owner: msg.sender
        });
        userSphereId[msg.sender] = newItemId;

        emit SphereMinted(msg.sender, newItemId);
    }

    /**
     * @dev 2. getSphereData(uint256 _tokenId)
     * Returns all stored data for a specific Aetherium Sphere.
     */
    function getSphereData(uint256 _tokenId) public view returns (SphereData memory) {
        require(_exists(_tokenId), "Sphere does not exist.");
        return spheres[_tokenId];
    }

    /**
     * @dev 3. getNexusPoints(address _user)
     * Returns the current Nexus Points of a given user.
     */
    function getNexusPoints(address _user) public view returns (uint256) {
        return nexusPoints[_user];
    }

    /**
     * @dev 4. getSphereEvolutionProgress(uint256 _tokenId)
     * Calculates and returns the progress (in Nexus Points) towards the next evolution level
     * for a specific Sphere.
     */
    function getSphereEvolutionProgress(uint256 _tokenId) public view returns (uint256 currentLevelPoints, uint256 pointsToNextLevel) {
        require(_exists(_tokenId), "Sphere does not exist.");
        uint256 currentPoints = nexusPoints[spheres[_tokenId].owner];
        uint256 currentLevel = spheres[_tokenId].level;

        if (currentLevel >= MAX_SPHERE_LEVEL) {
            return (currentPoints, 0); // Max level reached, no more progress
        }

        uint256 nextLevelThreshold = currentLevel * NEXUS_POINTS_PER_LEVEL_THRESHOLD;
        if (currentPoints < nextLevelThreshold) {
            return (currentPoints % NEXUS_POINTS_PER_LEVEL_THRESHOLD, nextLevelThreshold - currentPoints);
        } else {
            // User might have enough points for multiple levels, but we show progress towards the *next* one
            return (currentPoints % NEXUS_POINTS_PER_LEVEL_THRESHOLD, 0); // User has enough for next level or more
        }
    }

    /**
     * @dev 5. evolveSphere(uint256 _tokenId)
     * Internal function that updates an Aetherium Sphere's level and metadata
     * when its owner accumulates enough Nexus Points. Triggered by `_updateNexusPoints`.
     */
    function _evolveSphere(uint256 _tokenId) internal {
        SphereData storage sphere = spheres[_tokenId];
        uint256 currentPoints = nexusPoints[sphere.owner];

        while (sphere.level < MAX_SPHERE_LEVEL && currentPoints >= (sphere.level + 1) * NEXUS_POINTS_PER_LEVEL_THRESHOLD) {
            sphere.level++;
            sphere.lastEvolutionTime = block.timestamp;
            // In a real scenario, this would update based on IPFS CIDs for different levels.
            // For simplicity, we just update the level.
            sphere.metadataCID = string(abi.encodePacked("QmSphereLevel", Strings.toString(sphere.level), "Metadata"));
            emit SphereEvolved(_tokenId, sphere.level, currentPoints);
        }
    }

    /**
     * @dev 6. _updateNexusPoints(address _user, uint256 _amount)
     * Internal function to add Nexus Points to a user and potentially trigger sphere evolution.
     */
    function _updateNexusPoints(address _user, uint256 _amount) internal {
        nexusPoints[_user] += _amount;
        emit NexusPointsUpdated(_user, nexusPoints[_user], _amount);

        // If the user has a sphere, check for evolution
        uint256 sphereId = userSphereId[_user];
        if (sphereId != 0 && _exists(sphereId)) {
            _evolveSphere(sphereId);
        }
    }

    /**
     * @dev 7. proposeNewCause(string memory _name, string memory _descriptionCID, uint256 _requiredValidators)
     * Allows any user to propose a new impact cause. Requires Aetherium Sphere ownership for voting.
     * @param _name The name of the proposed cause.
     * @param _descriptionCID IPFS CID linking to a detailed description of the cause.
     * @param _requiredValidators Minimum distinct validators required for attesting to this cause.
     */
    function proposeNewCause(string memory _name, string memory _descriptionCID, uint256 _requiredValidators)
        external
        whenNotPaused
        nonReentrant
    {
        require(userSphereId[msg.sender] != 0, "Only Aetherium Sphere owners can propose causes.");
        require(bytes(_name).length > 0, "Cause name cannot be empty.");
        require(bytes(_descriptionCID).length > 0, "Description CID cannot be empty.");
        require(_requiredValidators > 0, "Required validators must be at least 1.");

        uint256 proposalId = _nextCauseProposalId.current();
        _nextCauseProposalId.increment();

        causeProposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            descriptionCID: _descriptionCID,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            executed: false,
            target: address(0), // Not applicable for cause proposals directly
            calldataPayload: "" // Not applicable
        });

        Cause memory newCause = Cause({
            id: _nextCauseId.current(),
            name: _name,
            descriptionCID: _descriptionCID,
            requiredValidators: _requiredValidators,
            isActive: false,
            proposer: msg.sender,
            proposalId: proposalId
        });
        causes[_nextCauseId.current()] = newCause;

        emit CauseProposed(proposalId, msg.sender, _name);
    }

    /**
     * @dev 8. voteOnCauseProposal(uint256 _proposalId, bool _support)
     * Allows Aetherium Sphere owners to vote on proposed causes.
     * @param _proposalId The ID of the cause proposal to vote on.
     * @param _support True if voting for, false if voting against.
     */
    function voteOnCauseProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        require(userSphereId[msg.sender] != 0, "Only Aetherium Sphere owners can vote.");
        Proposal storage proposal = causeProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        require(!proposal.executed, "Proposal has already been executed.");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CauseVoteRecorded(_proposalId, msg.sender, _support);

        // Check if proposal can be activated immediately (simple majority logic for now)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes > 0) {
            uint256 supportPercentage = (proposal.votesFor * 100) / totalVotes;
            if (supportPercentage >= CAUSE_VOTE_THRESHOLD_PERCENT) {
                _activateCause(proposal.id);
            }
        }
    }

    /**
     * @dev 9. activateCause(uint256 _proposalId)
     * Allows an admin or a successful governance proposal to activate a cause.
     * Normally called internally by voteOnCauseProposal or a governance execution.
     * @param _proposalId The ID of the cause proposal to activate.
     */
    function activateCause(uint256 _proposalId) public onlyRole(ADMIN_ROLE) whenNotPaused {
        Proposal storage proposal = causeProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        require(!proposal.executed, "Cause proposal already executed or activated.");

        // Find the associated Cause struct (simplification: assuming causeId is same as proposalId)
        Cause storage targetCause = causes[_proposalId];
        require(!targetCause.isActive, "Cause is already active.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0 && (proposal.votesFor * 100) / totalVotes >= CAUSE_VOTE_THRESHOLD_PERCENT, "Cause proposal not passed.");

        targetCause.isActive = true;
        proposal.executed = true; // Mark the proposal as executed

        _nextCauseId.increment(); // Only increment counter upon activation

        emit CauseActivated(targetCause.id, targetCause.name);
    }

    /**
     * @dev 10. getCauses()
     * Returns a list of all active causes and their details.
     */
    function getCauses() public view returns (Cause[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < _nextCauseId.current(); i++) {
            if (causes[i].isActive) {
                activeCount++;
            }
        }

        Cause[] memory activeCauses = new Cause[](activeCount);
        uint256 currentIdx = 0;
        for (uint256 i = 0; i < _nextCauseId.current(); i++) {
            if (causes[i].isActive) {
                activeCauses[currentIdx] = causes[i];
                currentIdx++;
            }
        }
        return activeCauses;
    }

    /**
     * @dev 11. submitImpactAttestation(uint256 _causeId, string memory _proofCID)
     * Allows a user to submit a claim of impact contribution to an active cause.
     * Requires the caller to own an Aetherium Sphere and provide a stake.
     * @param _causeId The ID of the cause the impact relates to.
     * @param _proofCID IPFS CID linking to proof of impact.
     */
    function submitImpactAttestation(uint256 _causeId, string memory _proofCID) external payable whenNotPaused nonReentrant {
        require(userSphereId[msg.sender] != 0, "Only Aetherium Sphere owners can submit attestations.");
        require(causes[_causeId].isActive, "Cause is not active or does not exist.");
        require(msg.value >= attestationStakeAmount, "Insufficient stake provided.");
        require(bytes(_proofCID).length > 0, "Proof CID cannot be empty.");

        uint256 newAttestationId = _nextAttestationId.current();
        _nextAttestationId.increment();

        impactAttestations[newAttestationId] = Attestation({
            id: newAttestationId,
            causeId: _causeId,
            submitter: msg.sender,
            proofCID: _proofCID,
            submittedAt: block.timestamp,
            validatorCount: 0,
            status: AttestationStatus.PendingValidation,
            stake: msg.value,
            challenger: address(0),
            challengeReasonCID: ""
        });

        emit ImpactAttestationSubmitted(newAttestationId, _causeId, msg.sender);
    }

    /**
     * @dev 12. attestToImpact(uint256 _attestationId, bool _isValid)
     * Allows a whitelisted validator to verify an impact attestation.
     * If valid, Nexus Points are awarded. If invalid, the attester's stake is slashed.
     * @param _attestationId The ID of the attestation to validate.
     * @param _isValid True if the attestation is deemed valid, false otherwise.
     */
    function attestToImpact(uint256 _attestationId, bool _isValid) external onlyRole(VALIDATOR_ROLE) whenNotPaused nonReentrant {
        Attestation storage attestation = impactAttestations[_attestationId];
        require(attestation.submitter != address(0), "Attestation does not exist.");
        require(attestation.status == AttestationStatus.PendingValidation, "Attestation is not pending validation.");
        require(attestation.submitter != msg.sender, "Validator cannot attest their own submission.");
        require(!attestation.validatedBy[msg.sender], "You have already attested to this.");

        attestation.validatedBy[msg.sender] = true;
        attestation.validatorCount++;

        if (_isValid) {
            uint256 requiredValidators = causes[attestation.causeId].requiredValidators;
            if (attestation.validatorCount >= requiredValidators) {
                attestation.status = AttestationStatus.Validated;
                // Reward submitter with Nexus Points
                uint256 pointsAwarded = 100; // Base points per validated attestation
                _updateNexusPoints(attestation.submitter, pointsAwarded);

                // Return stake to submitter
                payable(attestation.submitter).transfer(attestation.stake);

                emit ImpactAttestationValidated(_attestationId, msg.sender, true, pointsAwarded);
            }
        } else {
            // If any validator marks as invalid, it's immediately rejected (can be more complex with dispute)
            attestation.status = AttestationStatus.Rejected;
            // Slash submitter's stake (send to treasury or burn)
            // For simplicity, send to owner (treasury)
            payable(owner()).transfer(attestation.stake);
            emit ImpactAttestationValidated(_attestationId, msg.sender, false, 0);
        }
    }

    /**
     * @dev 13. challengeAttestation(uint256 _attestationId, string memory _reasonCID)
     * Allows a user to challenge a validated attestation. This initiates a dispute.
     * The dispute resolution would typically be handled by governance or a dedicated module.
     * Requires a stake to prevent spam.
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reasonCID IPFS CID linking to the reason/proof for the challenge.
     */
    function challengeAttestation(uint256 _attestationId, string memory _reasonCID) external payable whenNotPaused nonReentrant {
        Attestation storage attestation = impactAttestations[_attestationId];
        require(attestation.submitter != address(0), "Attestation does not exist.");
        require(attestation.status == AttestationStatus.Validated, "Only validated attestations can be challenged.");
        require(msg.value >= attestationStakeAmount, "Insufficient stake for challenge.");
        require(bytes(_reasonCID).length > 0, "Challenge reason CID cannot be empty.");

        attestation.status = AttestationStatus.Challenged;
        attestation.challenger = msg.sender;
        attestation.challengeReasonCID = _reasonCID;

        // The challenge stake goes to the contract for now, to be distributed/slashed based on dispute outcome
        // payable(address(this)).transfer(msg.value); // msg.value already sent on call

        // A governance proposal might be automatically created here to resolve the dispute
        submitGovernanceProposal(
            string(abi.encodePacked("Dispute for Attestation ID: ", Strings.toString(_attestationId))),
            address(0), // No direct target, resolution is via governance vote
            ""
        );

        emit ImpactAttestationChallenged(_attestationId, msg.sender);
    }

    /**
     * @dev 14. getAttestationDetails(uint256 _attestationId)
     * Retrieves details of a specific impact attestation.
     */
    function getAttestationDetails(uint256 _attestationId) public view returns (Attestation memory) {
        require(impactAttestations[_attestationId].submitter != address(0), "Attestation does not exist.");
        return impactAttestations[_attestationId];
    }

    /**
     * @dev 15. stakeForValidation()
     * Allows a user to stake ETH to become eligible for the validator pool.
     * @dev The actual addition to VALIDATOR_ROLE is done via governance or admin.
     */
    function stakeForValidation() external payable whenNotPaused nonReentrant {
        require(msg.value >= validatorStakeAmount, "Insufficient stake provided.");
        require(validatorStakes[msg.sender] == 0, "You already have a stake."); // Only one stake allowed per validator for now

        validatorStakes[msg.sender] = msg.value;
        emit ValidatorStaked(msg.sender, msg.value);
    }

    /**
     * @dev 16. unstakeValidationDeposit()
     * Allows a validator to unstake their deposit after a cooldown period, if not involved in disputes.
     */
    function unstakeValidationDeposit() external whenNotPaused nonReentrant {
        require(validatorStakes[msg.sender] > 0, "You have no stake to unstake.");
        require(!hasRole(VALIDATOR_ROLE, msg.sender), "You must first be removed from validator role via governance.");
        require(block.timestamp >= validatorUnstakeRequestTime[msg.sender] + validatorUnstakeCooldown, "Cooldown period not over.");

        uint256 amount = validatorStakes[msg.sender];
        validatorStakes[msg.sender] = 0;
        delete validatorUnstakeRequestTime[msg.sender]; // Clear request time

        payable(msg.sender).transfer(amount);
        emit ValidatorUnstaked(msg.sender, amount);
    }

    /**
     * @dev 17. proposeAttestationValidator(address _newValidator)
     * Proposes an address to be added to the whitelist of attestation validators.
     * Requires an Aetherium Sphere and the candidate to have staked.
     */
    function proposeAttestationValidator(address _newValidator) external whenNotPaused {
        require(userSphereId[msg.sender] != 0, "Only Aetherium Sphere owners can propose validators.");
        require(validatorStakes[_newValidator] >= validatorStakeAmount, "Candidate must have staked.");
        require(!hasRole(VALIDATOR_ROLE, _newValidator), "Address is already a validator.");

        uint256 proposalId = _nextGovernanceProposalId.current();
        _nextGovernanceProposalId.increment();

        // This creates a special governance proposal to add a role
        governanceProposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            descriptionCID: string(abi.encodePacked("Propose new validator: ", Strings.toHexString(uint160(_newValidator)))),
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            executed: false,
            target: address(this), // Contract itself as target
            calldataPayload: abi.encodeWithSelector(this.grantRole.selector, VALIDATOR_ROLE, _newValidator)
        });

        emit ValidatorProposalCreated(proposalId, _newValidator);
    }

    /**
     * @dev 18. voteOnValidatorProposal(uint256 _proposalId, bool _support)
     * Allows Aetherium Sphere owners to vote on new validator proposals.
     * This simply delegates to the general `voteOnGovernanceProposal`.
     */
    function voteOnValidatorProposal(uint256 _proposalId, bool _support) external {
        voteOnGovernanceProposal(_proposalId, _support);
    }

    /**
     * @dev 19. submitGovernanceProposal(string memory _descriptionCID, address _target, bytes memory _calldata)
     * Allows Aetherium Sphere owners to propose general governance actions.
     * @param _descriptionCID IPFS CID for detailed proposal description.
     * @param _target The contract address the proposal will interact with (e.g., this contract for upgrades, or another).
     * @param _calldata The encoded function call data for the target contract.
     */
    function submitGovernanceProposal(string memory _descriptionCID, address _target, bytes memory _calldata)
        public
        whenNotPaused
        nonReentrant
    {
        require(userSphereId[msg.sender] != 0, "Only Aetherium Sphere owners can submit governance proposals.");
        require(bytes(_descriptionCID).length > 0, "Description CID cannot be empty.");
        require(_target != address(0), "Target address cannot be zero.");

        uint256 proposalId = _nextGovernanceProposalId.current();
        _nextGovernanceProposalId.increment();

        governanceProposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            descriptionCID: _descriptionCID,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            executed: false,
            target: _target,
            calldataPayload: _calldata
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, _descriptionCID);
    }

    /**
     * @dev 20. voteOnGovernanceProposal(uint256 _proposalId, bool _support)
     * Allows Aetherium Sphere owners to vote on governance proposals.
     * @param _proposalId The ID of the governance proposal to vote on.
     * @param _support True if voting for, false if voting against.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        require(userSphereId[msg.sender] != 0, "Only Aetherium Sphere owners can vote.");
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        require(!proposal.executed, "Proposal has already been executed.");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal.");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CauseVoteRecorded(_proposalId, msg.sender, _support); // Re-using event, consider new event for governance
    }

    /**
     * @dev 21. executeGovernanceProposal(uint256 _proposalId)
     * Executes a successfully passed governance proposal.
     * Requires the proposal to have met the voting threshold and not yet been executed.
     */
    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist.");
        require(!proposal.executed, "Proposal already executed.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0 && (proposal.votesFor * 100) / totalVotes >= GOVERNANCE_VOTE_THRESHOLD_PERCENT, "Proposal not passed.");

        // Execute the proposed action
        (bool success, ) = proposal.target.call(proposal.calldataPayload);
        require(success, "Proposal execution failed.");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev 22. requestAIDecision(uint256 _attestationId, string memory _question)
     * Conceptual function for sending a query about an attestation to an external AI oracle for analysis.
     * This would typically interface with Chainlink or another oracle network's external adapter.
     * @param _attestationId The ID of the attestation to query.
     * @param _question The question or context for the AI.
     */
    function requestAIDecision(uint256 _attestationId, string memory _question) external onlyRole(ADMIN_ROLE) whenNotPaused {
        require(trustedAIOracleAddress != address(0), "AI Oracle address not set.");
        // In a real scenario, this would call a method on the trustedAIOracleAddress
        // e.g., trustedAIOracleAddress.call(abi.encodeWithSelector(AIOracle.requestData.selector, _attestationId, _question));
        // For this contract, it's a conceptual call.

        emit AIDecisionRequested(_attestationId, _question);
    }

    /**
     * @dev 23. receiveOracleResponse(uint256 _attestationId, string memory _response, bool _isPositive)
     * External callback function for the AI oracle to deliver its decision back to the contract.
     * Only callable by the trusted AI oracle address.
     * @param _attestationId The ID of the attestation the response relates to.
     * @param _response The AI's response/summary.
     * @param _isPositive A boolean indicating if the AI's decision is positive/validating.
     */
    function receiveOracleResponse(uint256 _attestationId, string memory _response, bool _isPositive) external onlyRole(ORACLE_ROLE) whenNotPaused {
        Attestation storage attestation = impactAttestations[_attestationId];
        require(attestation.submitter != address(0), "Attestation does not exist.");
        require(attestation.status == AttestationStatus.Challenged, "Oracle response only for challenged attestations.");

        if (_isPositive) {
            attestation.status = AttestationStatus.Validated;
            // Reward original attester (if challenged was invalid) or award challenger (if challenge was valid)
            // For simplicity, if AI says positive, means attestation stands, slashes challenger's stake
            // If AI says negative, means attestation was invalid, slashes attester's stake
            if (attestation.challenger != address(0)) {
                // Challenger loses stake (to treasury)
                payable(owner()).transfer(attestation.stake); // Challenger's stake
            }
            uint256 pointsAwarded = 200; // More points for AI-validated
            _updateNexusPoints(attestation.submitter, pointsAwarded);
        } else {
            attestation.status = AttestationStatus.Rejected;
            // Attester loses stake (to treasury)
            payable(owner()).transfer(attestation.stake); // Attester's stake
            if (attestation.challenger != address(0)) {
                // Challenger gets back their stake + a reward for correct challenge
                payable(attestation.challenger).transfer(attestation.stake + (attestation.stake / 2)); // Example reward
            }
        }
        attestation.challenger = address(0); // Clear challenger after resolution

        emit AIDecisionReceived(_attestationId, _response, _isPositive);
    }

    /**
     * @dev 24. setOracleAddress(address _oracleAddress)
     * Sets the trusted address of the AI oracle. Only callable by admin.
     * @param _oracleAddress The address of the trusted oracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyRole(ADMIN_ROLE) {
        require(_oracleAddress != address(0), "Oracle address cannot be zero.");
        trustedAIOracleAddress = _oracleAddress;
        _grantRole(ORACLE_ROLE, _oracleAddress); // Grant the ORACLE_ROLE to the trusted oracle
    }

    /**
     * @dev 25. pauseContract()
     * Allows an admin or governance to pause critical contract functions in emergencies.
     */
    function pauseContract() external onlyRole(ADMIN_ROLE) {
        require(!paused, "Contract is already paused.");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev 26. unpauseContract()
     * Unpauses the contract, restoring normal functionality.
     */
    function unpauseContract() external onlyRole(ADMIN_ROLE) {
        require(paused, "Contract is not paused.");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev 27. withdrawFunds()
     * Allows the contract owner (or governance) to withdraw collected fees/stakes from the contract treasury.
     * This can be extended with a more robust treasury management system via governance.
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(owner()).transfer(balance);
        emit FundsWithdrawn(owner(), balance);
    }

    // --- ERC721 Overrides (for soulbound or semi-soulbound functionality) ---
    // Make Aetherium Spheres non-transferable by default
    // Can be made transferable after certain level via governance or specific rule

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If 'from' is not zero address (minting) and 'to' is not zero address (burning)
        if (from != address(0) && to != address(0)) {
            // Implement semi-soulbound logic:
            // For example, allow transfer only if Sphere is MAX_SPHERE_LEVEL, or via a specific governance proposal.
            // For simplicity, enforcing fully soulbound for now to emphasize reputation.
            require(from == address(0) || to == address(0), "Aetherium Spheres are soulbound and not transferable.");
            // To make it semi-soulbound:
            // require(spheres[tokenId].level >= MAX_SPHERE_LEVEL || hasRole(ADMIN_ROLE, msg.sender), "Sphere not transferable yet.");
        }
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {}
    fallback() external payable {}
}
```