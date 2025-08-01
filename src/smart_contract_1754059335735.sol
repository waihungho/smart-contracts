Okay, this is an exciting challenge! Let's design a smart contract that goes beyond typical ERC standards, focusing on a dynamic, reputation-based, and community-driven system.

The core concept I propose is a **"Sentient Nexus Chronicle" (SNC)**. This contract manages a system where users earn "Nexus Points" (NP) and "Echoes" (dynamic achievements/traits) by contributing to decentralized tasks, verifying claims, or interacting with integrated protocols. The SNC represents a user's evolving on-chain identity and reputation, which can gate access to features, influence governance, or even modify its own behavior based on accumulated data.

This contract aims for:
*   **Dynamic Identity:** A non-transferable (soulbound-like) NFT that evolves visually/metadata-wise based on user activity.
*   **Reputation System:** "Nexus Points" (NP) and "Echoes" for on-chain contributions and verified claims.
*   **Decentralized Tasking/Verification:** A system for creating tasks, submitting proofs, and community verification.
*   **Interoperability Synergies:** Mechanisms to recognize and reward interactions with *other* whitelisted protocols.
*   **Adaptive Governance:** Parameters that can be adjusted by the community (via accumulated NP).
*   **Temporal Decay/Engagement Incentives:** Nexus Points can decay, encouraging continuous engagement.

---

## Contract Outline & Function Summary

**Contract Name:** `SentientNexusChronicle`

**Core Concept:** A non-transferable, dynamic NFT (SNC) representing an evolving on-chain identity and reputation, earned through verifiable contributions and interactions within a multi-protocol ecosystem.

### **I. Core Identity & NFT Management**
1.  `constructor`: Initializes the contract, setting the owner and initial parameters.
2.  `mintSNC`: Allows a new user to mint their unique, non-transferable Sentient Nexus Chronicle.
3.  `tokenURI`: Returns the dynamic metadata URI for a given SNC, which updates based on the owner's Nexus Points and Echoes.
4.  `getSNCDetails`: Retrieves all detailed information about a specific SNC (points, echoes, last activity).
5.  `setBaseURI`: Owner/DAO can update the base URI for metadata resolution.
6.  `ownerOf`: Override to always revert as tokens are non-transferable.
7.  `balanceOf`: Override to always return 1 for a minted SNC, 0 otherwise.

### **II. Nexus Points (NP) & Echoes (Dynamic Achievements)**
8.  `awardNexusPoints`: Allows authorized entities (admin, verified task completions) to award NP to an SNC holder.
9.  `decayNexusPoints`: Initiates a decay process for a user's NP based on a predefined rate, incentivizing continuous engagement.
10. `getNexusPoints`: Retrieves the current Nexus Points for an SNC holder.
11. `defineEchoType`: Admin/DAO defines a new type of "Echo" (dynamic achievement) with specific criteria.
12. `grantEcho`: Awards a specific Echo to an SNC holder based on defined criteria or verified contribution.
13. `revokeEcho`: Removes an Echo from an SNC holder (e.g., if a claim is later invalidated).
14. `getSNCAnimaScore`: Calculates a composite "Anima Score" based on NP and specific Echoes, used for higher-level gating.

### **III. Decentralized Tasking & Claim Verification**
15. `createNexusTask`: Allows anyone to propose a new task that, upon completion, can award NP and/or Echoes.
16. `submitTaskProof`: A user submits proof of completion for an active Nexus Task.
17. `challengeTaskProof`: Allows other users to challenge a submitted task proof, initiating a dispute period.
18. `verifyTaskProof`: Authorized verifiers (or a community vote) confirm a task proof, leading to reward issuance.
19. `resolveTaskDispute`: Resolves a dispute for a challenged task proof, either confirming or rejecting it.

### **IV. Interoperability & Synergy Boosts**
20. `registerSynergyProtocol`: Admin/DAO registers an external protocol or contract as a "Synergy Source."
21. `applySynergyBoost`: Allows a whitelisted Synergy Protocol to trigger a temporary NP multiplier or unique Echo for an SNC holder who interacted with it.
22. `getActiveSynergyBoosts`: Returns a list of active synergy boosts for a specific SNC.

### **V. Adaptive Governance & Parameters**
23. `proposeParameterChange`: SNC holders (with sufficient Anima Score) can propose changes to contract parameters (e.g., NP decay rate, task creation fees).
24. `voteOnProposal`: SNC holders vote on active proposals.
25. `executeProposal`: Executes a proposal if it has passed and the voting period has ended.
26. `setVerifierRole`: Admin/DAO assigns or revokes the role of a "Verifier" for task proofs.

### **VI. Utility & View Functions**
27. `getTaskDetails`: Retrieves details about a specific Nexus Task.
28. `getProofDetails`: Retrieves details about a submitted task proof.
29. `getProposalDetails`: Retrieves details about a governance proposal.
30. `isVerifier`: Checks if an address holds the verifier role.
31. `getCurrentSNCCount`: Returns the total number of minted SNCs.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom Errors for better readability and gas efficiency
error SNC_NotMinted();
error SNC_AlreadyMinted();
error SNC_NotAuthorized();
error SNC_InvalidState();
error SNC_AccessDenied();
error SNC_NotFound();
error SNC_TooSoon();
error SNC_InvalidInput();
error SNC_InsufficientNexusPoints();

/**
 * @title SentientNexusChronicle
 * @dev A contract for managing dynamic, non-transferable (soulbound-like) NFTs
 *      representing on-chain identities. Users earn Nexus Points and Echoes through
 *      contributions, verified claims, and protocol interactions. These influence
 *      the NFT's metadata and grant access to features or governance.
 *
 * Outline:
 *   I. Core Identity & NFT Management
 *   II. Nexus Points (NP) & Echoes (Dynamic Achievements)
 *   III. Decentralized Tasking & Claim Verification
 *   IV. Interoperability & Synergy Boosts
 *   V. Adaptive Governance & Parameters
 *   VI. Utility & View Functions
 */
contract SentientNexusChronicle is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIds; // For SNC tokenId generation (simple auto-incrementing)
    string private _baseURI; // Base URI for dynamic metadata resolution

    // --- I. Core Identity & NFT Management ---
    struct Persona {
        uint256 nexusPoints; // Accumulates points based on contributions
        uint64 lastActivityTimestamp; // Last time NP/Echoes were awarded or decayed
        uint64 lastDecayTimestamp; // Last time decay was applied
        uint64 mintTimestamp; // When the SNC was minted
        mapping(uint256 => bool) echoes; // Map of EchoTypeID to presence (true if granted)
    }
    mapping(address => uint256) private _addressToTokenId; // Map address to minted SNC tokenId
    mapping(uint256 => Persona) private _personaData; // Map tokenId to Persona data

    // --- II. Nexus Points (NP) & Echoes (Dynamic Achievements) ---
    struct EchoType {
        string name;
        string description;
        uint256 value; // E.g., for Anima Score calculation
        bool active;
    }
    mapping(uint256 => EchoType) private _echoTypes;
    Counters.Counter private _echoTypeIds;

    uint256 public nexusPointsDecayRatePerSecond; // How many NP decay per second
    uint256 public nexusPointsDecayPeriod; // How often decay can be initiated (e.g., 24 hours)
    uint256 public minAnimaScoreForProposal; // Minimum Anima Score to propose changes

    // --- III. Decentralized Tasking & Claim Verification ---
    enum TaskStatus {
        Open,
        ProofSubmitted,
        Challenged,
        Verified,
        Rejected
    }
    struct NexusTask {
        address creator;
        string title;
        string description;
        uint256 rewardNexusPoints;
        uint256[] rewardEchoTypeIds;
        uint64 submissionDeadline;
        uint64 verificationPeriod; // Time for verifiers to act
        uint256 requiredAnimaScoreToSubmit; // Min Anima Score to submit proof
        TaskStatus status;
        uint256 currentProofId; // Points to the latest submitted proof
        bool active; // Can new proofs be submitted?
    }
    mapping(uint256 => NexusTask) private _nexusTasks;
    Counters.Counter private _nexusTaskIds;

    struct TaskProof {
        uint256 taskId;
        address submitter;
        string proofUri; // URI to off-chain proof (e.g., IPFS hash)
        uint64 submissionTimestamp;
        uint64 challengePeriodEnd; // When challenge period ends
        uint64 verificationPeriodEnd; // When verification period ends
        bool challenged;
        bool verified;
        address challenger; // Who challenged (if any)
    }
    mapping(uint256 => TaskProof) private _taskProofs;
    Counters.Counter private _taskProofIds;

    mapping(address => bool) public verifiers; // Addresses authorized to verify tasks
    uint256 public minVerifiersRequired; // Minimum verifiers to confirm a proof

    // --- IV. Interoperability & Synergy Boosts ---
    struct SynergyBoost {
        uint64 expiryTimestamp;
        uint256 multiplier; // e.g., 100 = 1x, 150 = 1.5x
        string identifier; // Unique identifier for the boost source/type
    }
    mapping(uint256 => SynergyBoost[]) private _activeSynergyBoosts; // tokenId -> list of active boosts
    mapping(address => bool) public synergyProtocols; // Addresses of whitelisted external protocols

    // --- V. Adaptive Governance & Parameters ---
    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }
    struct GovernanceProposal {
        address proposer;
        string description;
        bytes callData; // Encoded function call to execute if passed
        address targetContract; // Contract to call if passed
        uint66 startTimestamp;
        uint66 endTimestamp;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // Address of voter -> hasVoted
        ProposalStatus status;
    }
    mapping(uint256 => GovernanceProposal) private _proposals;
    Counters.Counter private _proposalIds;

    uint256 public votingPeriodDuration; // Duration for proposals (e.g., 7 days)
    uint256 public quorumPercentage; // Percentage of total NP required to pass (e.g., 5% * 10000 = 500 NP)

    // --- Events ---
    event SNCMinted(address indexed owner, uint256 indexed tokenId);
    event NexusPointsAwarded(address indexed owner, uint256 amount, string reason);
    event NexusPointsDecayed(address indexed owner, uint256 amount);
    event EchoGranted(address indexed owner, uint256 indexed echoTypeId);
    event EchoRevoked(address indexed owner, uint256 indexed echoTypeId);
    event EchoTypeDefined(uint256 indexed echoTypeId, string name);
    event NexusTaskCreated(uint256 indexed taskId, address indexed creator);
    event TaskProofSubmitted(uint256 indexed proofId, uint256 indexed taskId, address indexed submitter);
    event TaskProofChallenged(uint256 indexed proofId, address indexed challenger);
    event TaskProofVerified(uint256 indexed proofId, address indexed verifier);
    event TaskProofRejected(uint256 indexed proofId, string reason);
    event SynergyBoostApplied(uint256 indexed tokenId, string identifier, uint256 multiplier, uint64 expiry);
    event VerifierStatusChanged(address indexed verifier, bool isVerifier);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ParameterChanged(string indexed parameterName, uint256 oldValue, uint256 newValue);

    // --- Modifiers ---
    modifier onlySNCWinner(address _address) {
        if (_addressToTokenId[_address] == 0) revert SNC_NotMinted();
        _;
    }

    modifier onlyVerifier() {
        if (!verifiers[msg.sender]) revert SNC_AccessDenied();
        _;
    }

    modifier onlySynergyProtocol() {
        if (!synergyProtocols[msg.sender]) revert SNC_AccessDenied();
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory initialBaseURI,
        uint256 _decayRatePerSecond,
        uint256 _decayPeriod,
        uint256 _minAnimaForProposal,
        uint256 _votingPeriodDuration,
        uint256 _quorumPercentage
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _baseURI = initialBaseURI;
        nexusPointsDecayRatePerSecond = _decayRatePerSecond;
        nexusPointsDecayPeriod = _decayPeriod;
        minAnimaScoreForProposal = _minAnimaForProposal;
        votingPeriodDuration = _votingPeriodDuration;
        quorumPercentage = _quorumPercentage;
        minVerifiersRequired = 1; // Can be updated by DAO
    }

    // --- I. Core Identity & NFT Management ---

    /**
     * @dev Mints a new non-transferable Sentient Nexus Chronicle (SNC) for the caller.
     *      Each address can only mint one SNC.
     */
    function mintSNC() external {
        if (_addressToTokenId[msg.sender] != 0) revert SNC_AlreadyMinted();

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _personaData[newItemId].nexusPoints = 0; // Start with 0 points
        _personaData[newItemId].lastActivityTimestamp = uint64(block.timestamp);
        _personaData[newItemId].lastDecayTimestamp = uint64(block.timestamp);
        _personaData[newItemId].mintTimestamp = uint64(block.timestamp);
        _addressToTokenId[msg.sender] = newItemId;

        // Make the token non-transferable by overriding `_transfer` and `safeTransferFrom` later
        // and ensuring no `approve` or `setApprovalForAll` functionality.
        // For ERC721, this means overriding `_approve`, `_setApprovalForAll`, `transferFrom`, `safeTransferFrom`
        // to revert, or simply not exposing them. The default ERC721 implementation of transferFrom calls _transfer.
        // We will override `transferFrom` and `safeTransferFrom` to revert.

        emit SNCMinted(msg.sender, newItemId);
    }

    /**
     * @dev Returns the dynamic metadata URI for a given SNC.
     *      The actual JSON/SVG is resolved by an off-chain service using this base URI
     *      and querying the contract for the token's state.
     * @param tokenId The ID of the SNC.
     * @return The URI pointing to the metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId); // Checks if tokenId exists
        return string(abi.encodePacked(_baseURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev Retrieves all detailed information about a specific SNC.
     * @param _owner The address of the SNC owner.
     * @return A tuple containing nexusPoints, lastActivityTimestamp, lastDecayTimestamp,
     *         mintTimestamp, and an array of active EchoType IDs.
     */
    function getSNCDetails(address _owner)
        public
        view
        onlySNCWinner(_owner)
        returns (
            uint256 nexusPoints,
            uint64 lastActivityTimestamp,
            uint64 lastDecayTimestamp,
            uint64 mintTimestamp,
            uint256[] memory activeEchoIds
        )
    {
        uint256 tokenId = _addressToTokenId[_owner];
        Persona storage persona = _personaData[tokenId];

        nexusPoints = persona.nexusPoints;
        lastActivityTimestamp = persona.lastActivityTimestamp;
        lastDecayTimestamp = persona.lastDecayTimestamp;
        mintTimestamp = persona.mintTimestamp;

        uint256[] memory tempEchoIds = new uint256[](_echoTypeIds.current()); // Max possible echoes
        uint256 count = 0;
        for (uint256 i = 1; i <= _echoTypeIds.current(); i++) {
            if (persona.echoes[i]) {
                tempEchoIds[count] = i;
                count++;
            }
        }
        activeEchoIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            activeEchoIds[i] = tempEchoIds[i];
        }
    }

    /**
     * @dev Allows the owner or DAO to update the base URI for metadata resolution.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
        // No event for this, as it's a structural update, not a persona change.
    }

    // --- Overrides for Non-Transferable ERC721 (Soulbound-like) ---
    function transferFrom(address, address, uint256) public pure override {
        revert SNC_InvalidState(); // SNCs are non-transferable
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert SNC_InvalidState(); // SNCs are non-transferable
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override {
        revert SNC_InvalidState(); // SNCs are non-transferable
    }

    function approve(address, uint256) public pure override {
        revert SNC_InvalidState(); // SNCs cannot be approved for transfer
    }

    function setApprovalForAll(address, bool) public pure override {
        revert SNC_InvalidState(); // SNCs cannot be approved for transfer
    }

    function getApproved(uint256) public pure override returns (address) {
        revert SNC_InvalidState(); // SNCs cannot be approved for transfer
    }

    function isApprovedForAll(address, address) public pure override returns (bool) {
        revert SNC_InvalidState(); // SNCs cannot be approved for transfer
    }

    // --- II. Nexus Points (NP) & Echoes (Dynamic Achievements) ---

    /**
     * @dev Awards Nexus Points to an SNC holder. Callable by owner, verifiers for tasks, or synergy protocols.
     * @param _to The address of the SNC holder.
     * @param _amount The amount of Nexus Points to award.
     * @param _reason A string describing the reason for the award.
     */
    function awardNexusPoints(address _to, uint256 _amount, string memory _reason) public {
        if (!owner() == msg.sender && !verifiers[msg.sender] && !synergyProtocols[msg.sender]) {
            revert SNC_NotAuthorized();
        }
        uint256 tokenId = _addressToTokenId[_to];
        if (tokenId == 0) revert SNC_NotMinted();

        Persona storage persona = _personaData[tokenId];
        _applyDecay(tokenId); // Apply decay before awarding new points

        persona.nexusPoints += _amount;
        persona.lastActivityTimestamp = uint64(block.timestamp);
        emit NexusPointsAwarded(_to, _amount, _reason);
    }

    /**
     * @dev Initiates a decay process for a user's Nexus Points. Can be called by anyone, but
     *      actual decay only applies if `nexusPointsDecayPeriod` has passed.
     * @param _owner The address of the SNC holder.
     */
    function decayNexusPoints(address _owner) public onlySNCWinner(_owner) {
        uint256 tokenId = _addressToTokenId[_owner];
        _applyDecay(tokenId);
    }

    /**
     * @dev Internal function to apply Nexus Point decay.
     * @param _tokenId The tokenId of the SNC.
     */
    function _applyDecay(uint256 _tokenId) internal {
        Persona storage persona = _personaData[_tokenId];
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime >= persona.lastDecayTimestamp + nexusPointsDecayPeriod) {
            uint256 elapsedSeconds = currentTime - persona.lastDecayTimestamp;
            uint256 decayedAmount = (elapsedSeconds * nexusPointsDecayRatePerSecond) / 10**18; // Assuming 10^18 for full unit per second
            if (decayedAmount > persona.nexusPoints) {
                decayedAmount = persona.nexusPoints;
            }
            persona.nexusPoints -= decayedAmount;
            persona.lastDecayTimestamp = currentTime;
            emit NexusPointsDecayed(ownerOf(_tokenId), decayedAmount);
        }
    }

    /**
     * @dev Retrieves the current Nexus Points for an SNC holder.
     * @param _owner The address of the SNC holder.
     * @return The current Nexus Points.
     */
    function getNexusPoints(address _owner) public view onlySNCWinner(_owner) returns (uint256) {
        uint256 tokenId = _addressToTokenId[_owner];
        // Note: This view function doesn't apply decay to save gas.
        // Decay is applied on state-changing functions or via `decayNexusPoints`.
        return _personaData[tokenId].nexusPoints;
    }

    /**
     * @dev Admin/DAO defines a new type of "Echo" (dynamic achievement).
     * @param _name The name of the Echo (e.g., "Verified Contributor").
     * @param _description A description of the Echo.
     * @param _value A numerical value associated with the Echo, influencing Anima Score.
     * @return The ID of the newly defined EchoType.
     */
    function defineEchoType(string memory _name, string memory _description, uint255 _value)
        public
        onlyOwner
        returns (uint256)
    {
        _echoTypeIds.increment();
        uint256 newEchoTypeId = _echoTypeIds.current();
        _echoTypes[newEchoTypeId] = EchoType(_name, _description, _value, true);
        emit EchoTypeDefined(newEchoTypeId, _name);
        return newEchoTypeId;
    }

    /**
     * @dev Grants a specific Echo to an SNC holder. Callable by owner, verifiers, or synergy protocols.
     * @param _to The address of the SNC holder.
     * @param _echoTypeId The ID of the EchoType to grant.
     */
    function grantEcho(address _to, uint256 _echoTypeId) public {
        if (!owner() == msg.sender && !verifiers[msg.sender] && !synergyProtocols[msg.sender]) {
            revert SNC_NotAuthorized();
        }
        uint256 tokenId = _addressToTokenId[_to];
        if (tokenId == 0) revert SNC_NotMinted();
        if (_echoTypeId == 0 || _echoTypeId > _echoTypeIds.current() || !_echoTypes[_echoTypeId].active) {
            revert SNC_InvalidInput();
        }

        Persona storage persona = _personaData[tokenId];
        if (!persona.echoes[_echoTypeId]) {
            persona.echoes[_echoTypeId] = true;
            persona.lastActivityTimestamp = uint64(block.timestamp);
            emit EchoGranted(_to, _echoTypeId);
        }
    }

    /**
     * @dev Revokes an Echo from an SNC holder. Callable by owner or verifiers (e.g., if a claim is invalidated).
     * @param _from The address of the SNC holder.
     * @param _echoTypeId The ID of the EchoType to revoke.
     */
    function revokeEcho(address _from, uint256 _echoTypeId) public {
        if (!owner() == msg.sender && !verifiers[msg.sender]) {
            revert SNC_NotAuthorized();
        }
        uint256 tokenId = _addressToTokenId[_from];
        if (tokenId == 0) revert SNC_NotMinted();
        if (_echoTypeId == 0 || _echoTypeId > _echoTypeIds.current() || !_echoTypes[_echoTypeId].active) {
            revert SNC_InvalidInput();
        }

        Persona storage persona = _personaData[tokenId];
        if (persona.echoes[_echoTypeId]) {
            persona.echoes[_echoTypeId] = false;
            persona.lastActivityTimestamp = uint64(block.timestamp);
            emit EchoRevoked(_from, _echoTypeId);
        }
    }

    /**
     * @dev Calculates a composite "Anima Score" for an SNC holder based on NP and specific Echoes.
     *      Used for higher-level gating (e.g., voting power, special access).
     * @param _owner The address of the SNC holder.
     * @return The calculated Anima Score.
     */
    function getSNCAnimaScore(address _owner) public view onlySNCWinner(_owner) returns (uint256) {
        uint256 tokenId = _addressToTokenId[_owner];
        Persona storage persona = _personaData[tokenId];
        uint256 currentNexusPoints = persona.nexusPoints; // Use raw NP for score calculation

        uint256 animaScore = currentNexusPoints;
        for (uint256 i = 1; i <= _echoTypeIds.current(); i++) {
            if (persona.echoes[i] && _echoTypes[i].active) {
                animaScore += _echoTypes[i].value;
            }
        }
        return animaScore;
    }

    // --- III. Decentralized Tasking & Claim Verification ---

    /**
     * @dev Allows anyone to propose a new task that, upon completion, can award NP and/or Echoes.
     *      Requires a minimum Anima Score to deter spam.
     * @param _title The title of the task.
     * @param _description A detailed description of the task.
     * @param _rewardNexusPoints The amount of Nexus Points to reward.
     * @param _rewardEchoTypeIds An array of EchoType IDs to grant upon successful verification.
     * @param _submissionDeadline Unix timestamp when proof submissions are no longer accepted.
     * @param _verificationPeriod Duration in seconds for verifiers to verify after submission.
     * @param _requiredAnimaScoreToSubmit Minimum Anima Score required to submit a proof for this task.
     * @return The ID of the newly created Nexus Task.
     */
    function createNexusTask(
        string memory _title,
        string memory _description,
        uint256 _rewardNexusPoints,
        uint256[] memory _rewardEchoTypeIds,
        uint64 _submissionDeadline,
        uint64 _verificationPeriod,
        uint256 _requiredAnimaScoreToSubmit
    ) public onlySNCWinner(msg.sender) returns (uint256) {
        if (getSNCAnimaScore(msg.sender) < minAnimaScoreForProposal) revert SNC_InsufficientNexusPoints(); // Re-use param for task creation cost/spam filter

        if (_submissionDeadline <= block.timestamp || _verificationPeriod == 0) revert SNC_InvalidInput();
        for (uint256 i = 0; i < _rewardEchoTypeIds.length; i++) {
            if (_rewardEchoTypeIds[i] == 0 || _rewardEchoTypeIds[i] > _echoTypeIds.current() || !_echoTypes[_rewardEchoTypeIds[i]].active) {
                revert SNC_InvalidInput();
            }
        }

        _nexusTaskIds.increment();
        uint256 newTaskId = _nexusTaskIds.current();
        _nexusTasks[newTaskId] = NexusTask(
            msg.sender,
            _title,
            _description,
            _rewardNexusPoints,
            _rewardEchoTypeIds,
            _submissionDeadline,
            _verificationPeriod,
            _requiredAnimaScoreToSubmit,
            TaskStatus.Open,
            0, // No current proof initially
            true
        );
        emit NexusTaskCreated(newTaskId, msg.sender);
        return newTaskId;
    }

    /**
     * @dev A user submits proof of completion for an active Nexus Task.
     * @param _taskId The ID of the Nexus Task.
     * @param _proofUri URI to the off-chain proof (e.g., IPFS hash of a document/image).
     */
    function submitTaskProof(uint256 _taskId, string memory _proofUri) public onlySNCWinner(msg.sender) {
        NexusTask storage task = _nexusTasks[_taskId];
        if (task.status != TaskStatus.Open || !task.active) revert SNC_InvalidState();
        if (block.timestamp > task.submissionDeadline) revert SNC_TooSoon(); // Deadline passed
        if (getSNCAnimaScore(msg.sender) < task.requiredAnimaScoreToSubmit) revert SNC_InsufficientNexusPoints();

        _taskProofIds.increment();
        uint256 newProofId = _taskProofIds.current();
        _taskProofs[newProofId] = TaskProof(
            _taskId,
            msg.sender,
            _proofUri,
            uint64(block.timestamp),
            uint64(block.timestamp) + task.verificationPeriod, // Challenge period is same as verification initially
            uint64(block.timestamp) + task.verificationPeriod,
            false,
            false,
            address(0)
        );
        task.status = TaskStatus.ProofSubmitted;
        task.currentProofId = newProofId;
        emit TaskProofSubmitted(newProofId, _taskId, msg.sender);
    }

    /**
     * @dev Allows other users to challenge a submitted task proof, initiating a dispute period.
     * @param _proofId The ID of the task proof to challenge.
     */
    function challengeTaskProof(uint256 _proofId) public onlySNCWinner(msg.sender) {
        TaskProof storage proof = _taskProofs[_proofId];
        if (proof.taskId == 0) revert SNC_NotFound(); // Proof doesn't exist
        if (proof.challenged) revert SNC_InvalidState(); // Already challenged
        if (block.timestamp > proof.challengePeriodEnd) revert SNC_TooSoon(); // Challenge period ended

        NexusTask storage task = _nexusTasks[proof.taskId];
        if (task.status != TaskStatus.ProofSubmitted) revert SNC_InvalidState();

        proof.challenged = true;
        proof.challenger = msg.sender;
        task.status = TaskStatus.Challenged;

        // Extend verification period for dispute resolution (e.g., double it)
        proof.verificationPeriodEnd = uint64(block.timestamp) + (task.verificationPeriod * 2);

        emit TaskProofChallenged(_proofId, msg.sender);
    }

    /**
     * @dev Authorized verifiers confirm a task proof, leading to reward issuance.
     * @param _proofId The ID of the task proof to verify.
     */
    function verifyTaskProof(uint256 _proofId) public onlyVerifier {
        TaskProof storage proof = _taskProofs[_proofId];
        if (proof.taskId == 0) revert SNC_NotFound();
        if (proof.verified) revert SNC_InvalidState(); // Already verified
        if (block.timestamp > proof.verificationPeriodEnd) revert SNC_TooSoon(); // Verification period ended

        NexusTask storage task = _nexusTasks[proof.taskId];
        if (task.status == TaskStatus.Rejected || task.status == TaskStatus.Verified) revert SNC_InvalidState();

        // Simple verification: require only 1 verifier for now. Could implement multi-sig or majority voting later.
        proof.verified = true;
        task.status = TaskStatus.Verified;

        // Award rewards
        awardNexusPoints(proof.submitter, task.rewardNexusPoints, "Task Completion");
        for (uint256 i = 0; i < task.rewardEchoTypeIds.length; i++) {
            grantEcho(proof.submitter, task.rewardEchoTypeIds[i]);
        }

        emit TaskProofVerified(_proofId, msg.sender);
    }

    /**
     * @dev Resolves a dispute for a challenged task proof, either confirming or rejecting it.
     *      Only callable by verifiers.
     * @param _proofId The ID of the task proof under dispute.
     * @param _isApproved True to approve the proof, false to reject.
     */
    function resolveTaskDispute(uint256 _proofId, bool _isApproved) public onlyVerifier {
        TaskProof storage proof = _taskProofs[_proofId];
        if (proof.taskId == 0) revert SNC_NotFound();
        if (!proof.challenged) revert SNC_InvalidState(); // Not challenged
        if (block.timestamp > proof.verificationPeriodEnd) revert SNC_TooSoon(); // Dispute resolution period ended

        NexusTask storage task = _nexusTasks[proof.taskId];
        if (task.status != TaskStatus.Challenged) revert SNC_InvalidState();

        if (_isApproved) {
            proof.verified = true;
            task.status = TaskStatus.Verified;
            awardNexusPoints(proof.submitter, task.rewardNexusPoints, "Task Completion (Dispute Resolved)");
            for (uint256 i = 0; i < task.rewardEchoTypeIds.length; i++) {
                grantEcho(proof.submitter, task.rewardEchoTypeIds[i]);
            }
            emit TaskProofVerified(_proofId, msg.sender);
        } else {
            task.status = TaskStatus.Rejected;
            emit TaskProofRejected(_proofId, "Dispute failed, proof rejected.");
        }
    }

    // --- IV. Interoperability & Synergy Boosts ---

    /**
     * @dev Admin/DAO registers an external protocol or contract as a "Synergy Source".
     *      This allows them to call `applySynergyBoost`.
     * @param _protocolAddress The address of the external protocol/contract.
     * @param _isSynergy True to add, false to remove.
     */
    function registerSynergyProtocol(address _protocolAddress, bool _isSynergy) public onlyOwner {
        synergyProtocols[_protocolAddress] = _isSynergy;
        // No specific event, but `VerifierStatusChanged` could be reused or a new one created.
    }

    /**
     * @dev Allows a whitelisted Synergy Protocol to trigger a temporary NP multiplier or unique Echo
     *      for an SNC holder who interacted with it.
     * @param _to The address of the SNC holder.
     * @param _identifier A unique identifier for this boost (e.g., "UniswapLP-V3").
     * @param _multiplier The NP multiplier (e.g., 150 for 1.5x, 100 for 1x).
     * @param _duration The duration in seconds the boost is active.
     */
    function applySynergyBoost(address _to, string memory _identifier, uint256 _multiplier, uint64 _duration)
        public
        onlySynergyProtocol
    {
        uint256 tokenId = _addressToTokenId[_to];
        if (tokenId == 0) revert SNC_NotMinted();
        if (_multiplier == 0 || _duration == 0) revert SNC_InvalidInput();

        _activeSynergyBoosts[tokenId].push(SynergyBoost({
            expiryTimestamp: uint64(block.timestamp) + _duration,
            multiplier: _multiplier,
            identifier: _identifier
        }));
        emit SynergyBoostApplied(tokenId, _identifier, _multiplier, uint64(block.timestamp) + _duration);
    }

    /**
     * @dev Returns a list of active synergy boosts for a specific SNC.
     * @param _owner The address of the SNC owner.
     * @return An array of active SynergyBoost details (expiryTimestamp, multiplier, identifier).
     */
    function getActiveSynergyBoosts(address _owner)
        public
        view
        onlySNCWinner(_owner)
        returns (SynergyBoost[] memory)
    {
        uint256 tokenId = _addressToTokenId[_owner];
        SynergyBoost[] storage boosts = _activeSynergyBoosts[tokenId];
        uint256 activeCount = 0;
        for (uint256 i = 0; i < boosts.length; i++) {
            if (boosts[i].expiryTimestamp > block.timestamp) {
                activeCount++;
            }
        }

        SynergyBoost[] memory activeBoosts = new SynergyBoost[](activeCount);
        uint256 current = 0;
        for (uint256 i = 0; i < boosts.length; i++) {
            if (boosts[i].expiryTimestamp > block.timestamp) {
                activeBoosts[current] = boosts[i];
                current++;
            }
        }
        return activeBoosts;
    }

    // --- V. Adaptive Governance & Parameters ---

    /**
     * @dev Allows SNC holders with sufficient Anima Score to propose changes to contract parameters.
     *      The `callData` must be an encoded function call to an `_setParameter` style function within this contract.
     * @param _description A description of the proposed change.
     * @param _targetContract The contract address where the call will be executed (should be `address(this)`).
     * @param _callData The encoded function call (e.g., `abi.encodeWithSelector(this.setNexusPointsDecayRate.selector, newRate)`).
     * @return The ID of the new proposal.
     */
    function proposeParameterChange(
        string memory _description,
        address _targetContract,
        bytes calldata _callData
    ) public onlySNCWinner(msg.sender) returns (uint256) {
        if (getSNCAnimaScore(msg.sender) < minAnimaScoreForProposal) revert SNC_InsufficientNexusPoints();
        if (_targetContract != address(this)) revert SNC_InvalidInput(); // Only self-modifying proposals for now

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        _proposals[newProposalId] = GovernanceProposal(
            msg.sender,
            _description,
            _callData,
            _targetContract,
            uint66(block.timestamp),
            uint66(block.timestamp) + uint66(votingPeriodDuration),
            0,
            0,
            ProposalStatus.Active
        );
        emit ProposalCreated(newProposalId, msg.sender);
        return newProposalId;
    }

    /**
     * @dev SNC holders vote on active proposals.
     *      Voting power is proportional to their current Nexus Points.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlySNCWinner(msg.sender) {
        GovernanceProposal storage proposal = _proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert SNC_InvalidState();
        if (block.timestamp < proposal.startTimestamp || block.timestamp > proposal.endTimestamp) revert SNC_TooSoon();
        if (proposal.hasVoted[msg.sender]) revert SNC_InvalidState(); // Already voted

        uint256 tokenId = _addressToTokenId[msg.sender];
        uint256 votingPower = _personaData[tokenId].nexusPoints; // Use raw NP for voting power

        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a proposal if it has passed and the voting period has ended.
     *      Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        GovernanceProposal storage proposal = _proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert SNC_InvalidState();
        if (block.timestamp <= proposal.endTimestamp) revert SNC_TooSoon(); // Voting period not ended yet

        uint256 totalNexusPoints = _getTotalNexusPointsSupply(); // Sum of all persona NP
        uint256 requiredQuorumVotes = (totalNexusPoints * quorumPercentage) / 10000; // quorumPercentage is in basis points

        if (proposal.totalVotesFor > proposal.totalVotesAgainst && proposal.totalVotesFor >= requiredQuorumVotes) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposed function call
            (bool success,) = proposal.targetContract.call(proposal.callData);
            if (!success) {
                // Handle execution failure, e.g., revert or log. For this example, we'll log.
                // A more robust system might allow retries or specific error handling.
                proposal.status = ProposalStatus.Failed; // Mark as failed execution
                return;
            }
            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    /**
     * @dev Internal helper to calculate total Nexus Points across all minted SNCs for quorum calculation.
     *      This could be gas-intensive if many SNCs are minted. For a production system, consider a
     *      state variable that updates on NP changes, or sampling.
     */
    function _getTotalNexusPointsSupply() internal view returns (uint256) {
        uint256 total = 0;
        // This iterates through all tokenIds, which can be inefficient for many users.
        // For production, a cumulative sum updated on NP changes would be better.
        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            total += _personaData[i].nexusPoints;
        }
        return total;
    }

    /**
     * @dev Allows the owner or DAO to set the role of a "Verifier" for task proofs.
     * @param _verifierAddress The address to grant/revoke the verifier role.
     * @param _hasRole True to grant, false to revoke.
     */
    function setVerifierRole(address _verifierAddress, bool _hasRole) public onlyOwner {
        verifiers[_verifierAddress] = _hasRole;
        emit VerifierStatusChanged(_verifierAddress, _hasRole);
    }

    /**
     * @dev Admin/DAO function to set the Nexus Points decay rate.
     *      This would be a target for governance proposals.
     * @param _newRate The new decay rate (NP per second, scaled by 10^18).
     */
    function setNexusPointsDecayRate(uint256 _newRate) public onlyOwner {
        emit ParameterChanged("nexusPointsDecayRatePerSecond", nexusPointsDecayRatePerSecond, _newRate);
        nexusPointsDecayRatePerSecond = _newRate;
    }

    /**
     * @dev Admin/DAO function to set the period after which decay can be initiated.
     * @param _newPeriod The new decay period in seconds.
     */
    function setNexusPointsDecayPeriod(uint256 _newPeriod) public onlyOwner {
        emit ParameterChanged("nexusPointsDecayPeriod", nexusPointsDecayPeriod, _newPeriod);
        nexusPointsDecayPeriod = _newPeriod;
    }

    /**
     * @dev Admin/DAO function to set the minimum Anima Score required to create a proposal.
     * @param _newScore The new minimum Anima Score.
     */
    function setMinAnimaScoreForProposal(uint256 _newScore) public onlyOwner {
        emit ParameterChanged("minAnimaScoreForProposal", minAnimaScoreForProposal, _newScore);
        minAnimaScoreForProposal = _newScore;
    }

    /**
     * @dev Admin/DAO function to set the minimum number of verifiers required for a task (if a multi-verifier system is implemented).
     * @param _newMin The new minimum number of verifiers.
     */
    function setMinVerifiersRequired(uint256 _newMin) public onlyOwner {
        emit ParameterChanged("minVerifiersRequired", minVerifiersRequired, _newMin);
        minVerifiersRequired = _newMin;
    }

    /**
     * @dev Admin/DAO function to set the duration for governance proposals.
     * @param _newDuration The new duration in seconds.
     */
    function setVotingPeriodDuration(uint256 _newDuration) public onlyOwner {
        emit ParameterChanged("votingPeriodDuration", votingPeriodDuration, _newDuration);
        votingPeriodDuration = _newDuration;
    }

    /**
     * @dev Admin/DAO function to set the quorum percentage for governance proposals.
     * @param _newQuorum Percentage in basis points (e.g., 500 for 5%).
     */
    function setQuorumPercentage(uint256 _newQuorum) public onlyOwner {
        emit ParameterChanged("quorumPercentage", quorumPercentage, _newQuorum);
        quorumPercentage = _newQuorum;
    }

    // --- VI. Utility & View Functions ---

    /**
     * @dev Retrieves details about a specific Nexus Task.
     * @param _taskId The ID of the Nexus Task.
     * @return The NexusTask struct.
     */
    function getTaskDetails(uint256 _taskId) public view returns (NexusTask memory) {
        if (_taskId == 0 || _taskId > _nexusTaskIds.current()) revert SNC_NotFound();
        return _nexusTasks[_taskId];
    }

    /**
     * @dev Retrieves details about a submitted task proof.
     * @param _proofId The ID of the Task Proof.
     * @return The TaskProof struct.
     */
    function getProofDetails(uint256 _proofId) public view returns (TaskProof memory) {
        if (_proofId == 0 || _proofId > _taskProofIds.current()) revert SNC_NotFound();
        return _taskProofs[_proofId];
    }

    /**
     * @dev Retrieves details about a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The GovernanceProposal struct.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        if (_proposalId == 0 || _proposalId > _proposalIds.current()) revert SNC_NotFound();
        return _proposals[_proposalId];
    }

    /**
     * @dev Checks if an address holds the verifier role.
     * @param _address The address to check.
     * @return True if the address is a verifier, false otherwise.
     */
    function isVerifier(address _address) public view returns (bool) {
        return verifiers[_address];
    }

    /**
     * @dev Returns the current total number of minted SNCs.
     * @return The total supply of SNCs.
     */
    function getCurrentSNCCount() public view returns (uint256) {
        return _tokenIds.current();
    }
}
```