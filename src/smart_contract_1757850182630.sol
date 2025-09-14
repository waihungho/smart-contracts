This smart contract, named **SkillWeave**, introduces a novel decentralized platform for skill-based task delegation and reputation building. It utilizes **Proof-of-Skill NFTs (PoSNFTs)** that dynamically evolve based on completed tasks, peer attestations, and verifiable on-chain actions. Requesters can define tasks with specific skill requirements, bounty incentives, and various proof mechanisms (attestation, oracle, ZKP-compatible). Skilled individuals (PoSNFT holders) can claim and complete these tasks, earning reputation and skill upgrades. A dispute resolution system is also integrated.

It avoids direct duplication of open-source projects by combining several advanced concepts into a unique interaction model: dynamic SBT-like NFTs, decentralized skill attestation, flexible proof-of-work verification, and a comprehensive task lifecycle with dispute resolution.

---

## SkillWeave: Decentralized Proof-of-Skill & Task Protocol

### Outline:

**I. Core Management & Setup**
1.  `constructor`: Initializes the contract, setting the owner and NFT details.
2.  `updateBaseURI`: Allows the owner to update the base URI for PoSNFT metadata.
3.  `pauseContract`: Temporarily pauses critical contract functions in emergencies.
4.  `unpauseContract`: Resumes contract functions from a paused state.
5.  `setTrustedOracleVerifier`: Designates an address as a trusted entity for oracle-based task verifications.
6.  `removeTrustedOracleVerifier`: Revokes trusted verifier status.
7.  `defineSkill`: Registers a new skill, making it available for task requirements and attestations.
8.  `registerAcceptedBountyToken`: Whitelists ERC20 tokens that can be used for task bounties.

**II. Proof-of-Skill NFT (PoSNFT) Operations**
9.  `mintPoSNFT`: Mints a new PoSNFT for a participant, acting as their unique skill identity.
10. `getPoSNFTDetails`: Retrieves comprehensive data for a specific PoSNFT, including skills and reputation.
11. `updatePoSNFTMetadataURI`: Triggers an update signal for a PoSNFT's metadata, prompting off-chain services to regenerate it based on current on-chain attributes.
12. `freezePoSNFT`: An admin function to temporarily disable a PoSNFT, preventing its holder from engaging in tasks or attestations.
13. `unfreezePoSNFT`: Unfreezes a previously frozen PoSNFT.

**III. Skill Attestation & Reputation**
14. `attestSkill`: Enables a PoSNFT holder to vouch for another holder's specific skill, enhancing the attested individual's skill level and reputation. Requires the attester to possess a higher (or sufficient) level in that skill.
15. `revokeAttestation`: Allows an attester to retract a previously issued skill attestation.
16. `getSkillLevel`: Queries the current level of a specific skill for a given PoSNFT.

**IV. Task Creation & Management**
17. `createTask`: A requester initiates a new task, detailing skill prerequisites, bounty amount (in ETH or ERC20), desired proof method, and submission deadline.
18. `claimTask`: A PoSNFT holder who meets a task's skill requirements can claim it, becoming the assigned worker.
19. `submitTaskProof`: The assigned worker submits their proof of task completion, tailored to the task's specified verification method.
20. `verifyTaskCompletion`: The requester or a trusted oracle/verifier confirms the successful completion of a task based on the submitted proof.
21. `disputeTaskOutcome`: Either the requester or the worker can formally dispute the outcome of a task (e.g., rejection, non-payout).
22. `resolveDispute`: An authorized admin or dispute resolver mediates and makes a final decision on a disputed task.
23. `cancelTask`: Allows a requester to cancel an open task (unclaimed or before proof submission).

**V. Bounty & Payouts**
24. `depositBounty`: Enables a requester to deposit the bounty for an existing task if not provided during task creation.
25. `releaseBounty`: Transfers the escrowed bounty to the worker upon successful and undisputed task verification.
26. `refundBounty`: Returns the escrowed bounty to the requester if a task is cancelled or ultimately fails verification/dispute resolution.
27. `getPoSNFTIdByAddress`: A utility view function to get a PoSNFT ID by owner address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SkillWeave is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _poSNFTIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _skillIds;

    // PoSNFT Data Structure
    struct PoSNFT {
        address owner;
        mapping(uint256 => uint256) skills; // skillId => level
        uint256 reputationPoints;
        uint256 tasksCompleted;
        bool isFrozen;
        uint256 lastMetadataUpdate; // Timestamp for metadata regeneration signal
    }
    mapping(uint256 => PoSNFT) private _poSNFTs; // tokenId => PoSNFT
    mapping(address => uint256) private _addressToPoSNFTId; // owner address => tokenId (each address can only have one PoSNFT)
    mapping(uint256 => mapping(uint256 => mapping(uint256 => bool))) private _skillAttestations; // attesterPoSNFTId => attestedPoSNFTId => skillId => bool

    // Skill Data Structure
    struct Skill {
        uint256 id;
        string name;
        string description;
        uint256 minAttesterLevel; // Minimum level required for an attester to vouch for this skill
    }
    mapping(uint256 => Skill) private _skills; // skillId => Skill struct
    mapping(string => uint256) private _skillNameToId; // skillName => skillId

    // Task Data Structure
    enum ProofVerificationMethod { Attestation, OracleHash, ZKPProof }
    enum TaskStatus { Open, Claimed, Submitted, Verified, Rejected, Disputed, Resolved, Cancelled }

    struct Task {
        address requester;
        uint256 workerPoSNFTId; // 0 if no worker assigned
        uint256 bountyAmount;
        address bountyToken; // address(0) for native ETH
        mapping(uint256 => uint256) requiredSkills; // skillId => minLevel
        ProofVerificationMethod proofVerificationMethod;
        bytes32 proofDataHash; // Hash of expected proof (for OracleHash, ZKPProof) or reference (for Attestation)
        uint40 submissionDeadline; // Unix timestamp
        TaskStatus status;
        uint40 disputePeriodEnd; // Unix timestamp for dispute window
        bool bountyDeposited; // True if bounty is held by contract
    }
    mapping(uint256 => Task) private _tasks; // taskId => Task

    // Whitelisted addresses for specific roles
    mapping(address => bool) private _isTrustedOracleVerifier;
    mapping(address => bool) private _acceptedBountyTokens; // ERC20 token address => bool

    // --- Constants & Configuration ---
    uint256 public constant MIN_REPUTATION_FOR_ATTESTATION = 100;
    uint256 public constant REPUTATION_PER_TASK_COMPLETED = 50;
    uint256 public constant REPUTATION_PER_ATTESTATION = 10;
    uint40 public constant DISPUTE_PERIOD_DURATION = 3 days; // Duration for dispute window

    // --- Events ---
    event PoSNFTMinted(uint256 indexed tokenId, address indexed owner, uint256 timestamp);
    event PoSNFTMetadataUpdated(uint256 indexed tokenId, uint256 timestamp);
    event PoSNFTFrozen(uint256 indexed tokenId, address indexed admin, uint256 timestamp);
    event PoSNFTUnfrozen(uint256 indexed tokenId, address indexed admin, uint256 timestamp);

    event SkillDefined(uint256 indexed skillId, string name, uint256 minAttesterLevel);
    event SkillAttested(uint256 indexed attesterPoSNFTId, uint256 indexed attestedPoSNFTId, uint256 indexed skillId, uint256 newLevel);
    event AttestationRevoked(uint256 indexed attesterPoSNFTId, uint256 indexed attestedPoSNFTId, uint256 indexed skillId);

    event TaskCreated(uint256 indexed taskId, address indexed requester, uint256 bountyAmount, address bountyToken, ProofVerificationMethod proofMethod);
    event TaskClaimed(uint256 indexed taskId, uint256 indexed workerPoSNFTId, uint256 timestamp);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed workerPoSNFTId, bytes32 proofDataHash);
    event TaskVerified(uint256 indexed taskId, uint256 indexed workerPoSNFTId, uint256 timestamp);
    event TaskRejected(uint256 indexed taskId, uint256 indexed workerPoSNFTId, string reason, uint256 timestamp);
    event TaskDisputed(uint256 indexed taskId, address indexed disputer, uint256 timestamp);
    event TaskDisputeResolved(uint256 indexed taskId, TaskStatus finalStatus, uint256 timestamp);
    event TaskCancelled(uint256 indexed taskId, address indexed requester, uint256 timestamp);

    event BountyDeposited(uint256 indexed taskId, address indexed depositor, uint256 amount, address token);
    event BountyReleased(uint256 indexed taskId, uint256 indexed workerPoSNFTId, uint256 amount, address token);
    event BountyRefunded(uint256 indexed taskId, address indexed requester, uint256 amount, address token);

    event TrustedOracleVerifierSet(address indexed verifier, bool isTrusted);
    event AcceptedBountyTokenRegistered(address indexed token, bool accepted);

    // --- Custom Errors ---
    error PoSNFTInvalidId();
    error PoSNFTAlreadyExists();
    error PoSNFTNotOwnedByUser();
    error PoSNFTFrozenError();
    error CallerNotPoSNFTOwner();
    error AttesterPoSNFTFrozen();
    error AttestedPoSNFTFrozen();
    error AttesterNotEnoughReputation();
    error AttesterSkillTooLow();
    error AlreadyAttested();
    error AttestationDoesNotExist();

    error SkillDoesNotExist();
    error SkillAlreadyExists();
    error InvalidMinAttesterLevel();

    error TaskInvalidId();
    error TaskNotOpen();
    error TaskNotClaimed();
    error TaskAlreadyClaimed();
    error TaskNotSubmitted();
    error TaskProofAlreadySubmitted(); // Should not happen if status is managed correctly
    error TaskSubmissionDeadlinePassed();
    error TaskNotAssignedToWorker();
    error WorkerSkillsInsufficient();
    error TaskRequesterMismatch();
    error TaskBountyAlreadyDeposited();
    error TaskStatusInvalidForOperation();
    error TaskDisputePeriodNotEnded();
    error TaskDisputePeriodActive();
    error InvalidProofVerificationMethod();
    error DisputePeriodEnded();

    error InsufficientBountyAmount();
    error BountyTokenNotAccepted();
    error BountyNotDeposited();
    error BountyAlreadyReleased();

    error NotTrustedOracleVerifier();
    error ETHTransferFailed();
    error ERC20TransferFailed();

    // --- Constructor ---
    /// @notice Initializes the contract, setting the owner and NFT collection details.
    /// @param baseURI_ The base URI for PoSNFT metadata, typically pointing to an off-chain service.
    constructor(string memory baseURI_) ERC721("ProofOfSkill NFT", "PoSNFT") Ownable(msg.sender) {
        _setBaseURI(baseURI_);
    }

    // --- Modifiers ---
    modifier onlyPoSNFTHolder(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert CallerNotPoSNFTOwner();
        _;
    }

    modifier onlyPoSNFTNotFrozen(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert PoSNFTInvalidId(); // Ensure NFT exists first
        if (_poSNFTs[_tokenId].isFrozen) revert PoSNFTFrozenError();
        _;
    }

    modifier onlyTrustedOracleVerifier() {
        if (!_isTrustedOracleVerifier[msg.sender]) revert NotTrustedOracleVerifier();
        _;
    }

    // --- I. Core Management & Setup ---

    /// @notice Updates the base URI for PoSNFT metadata. Only owner can call.
    /// @param baseURI_ The new base URI.
    function updateBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    /// @notice Pauses critical contract functions, preventing most state changes. Only owner can call.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses critical contract functions, resuming normal operations. Only owner can call.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Sets or unsets an address as a trusted oracle verifier. Only owner.
    ///         Trusted verifiers can verify tasks that specify `OracleHash` as their proof method.
    /// @param verifier_ The address to set/unset.
    /// @param isTrusted_ True to trust, false to untrust.
    function setTrustedOracleVerifier(address verifier_, bool isTrusted_) public onlyOwner {
        _isTrustedOracleVerifier[verifier_] = isTrusted_;
        emit TrustedOracleVerifierSet(verifier_, isTrusted_);
    }

    /// @notice Removes an address from the trusted oracle verifiers list. Only owner.
    /// @param verifier_ The address to remove.
    function removeTrustedOracleVerifier(address verifier_) public onlyOwner {
        setTrustedOracleVerifier(verifier_, false);
    }

    /// @notice Defines a new skill that can be used in tasks and attestations. Only owner.
    /// @param name_ The unique name of the skill (e.g., "Solidity Development").
    /// @param description_ A brief description of the skill.
    /// @param minAttesterLevel_ The minimum skill level an attester must possess in this skill to vouch for others.
    function defineSkill(string memory name_, string memory description_, uint256 minAttesterLevel_) public onlyOwner {
        if (_skillNameToId[name_] != 0) revert SkillAlreadyExists();
        if (minAttesterLevel_ == 0) revert InvalidMinAttesterLevel(); // Level 0 implies no skill, cannot attest

        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        _skills[newSkillId] = Skill(newSkillId, name_, description_, minAttesterLevel_);
        _skillNameToId[name_] = newSkillId;
        emit SkillDefined(newSkillId, name_, minAttesterLevel_);
    }

    /// @notice Registers an ERC20 token address as an accepted bounty token. Only owner.
    ///         Only accepted tokens can be used for task bounties.
    /// @param tokenAddress_ The address of the ERC20 token.
    /// @param accepted_ True to accept, false to reject.
    function registerAcceptedBountyToken(address tokenAddress_, bool accepted_) public onlyOwner {
        _acceptedBountyTokens[tokenAddress_] = accepted_;
        emit AcceptedBountyTokenRegistered(tokenAddress_, accepted_);
    }

    // --- II. Proof-of-Skill NFT (PoSNFT) Operations ---

    /// @notice Mints a new PoSNFT for the caller, serving as their unique on-chain skill identity.
    ///         Each address can only mint one PoSNFT.
    function mintPoSNFT() public whenNotPaused {
        if (_addressToPoSNFTId[msg.sender] != 0) revert PoSNFTAlreadyExists();

        _poSNFTIds.increment();
        uint256 newPoSNFTId = _poSNFTIds.current();
        _mint(msg.sender, newPoSNFTId);
        _poSNFTs[newPoSNFTId].owner = msg.sender;
        _poSNFTs[newPoSNFTId].reputationPoints = 0;
        _poSNFTs[newPoSNFTId].tasksCompleted = 0;
        _poSNFTs[newPoSNFTId].isFrozen = false;
        _poSNFTs[newPoSNFTId].lastMetadataUpdate = block.timestamp; // Initialize metadata update time
        _addressToPoSNFTId[msg.sender] = newPoSNFTId;

        emit PoSNFTMinted(newPoSNFTId, msg.sender, block.timestamp);
    }

    /// @notice Retrieves comprehensive details of a specific PoSNFT.
    /// @param _tokenId The ID of the PoSNFT.
    /// @return owner_ The owner's address.
    /// @return reputationPoints_ Total reputation points.
    /// @return tasksCompleted_ Number of tasks completed.
    /// @return isFrozen_ True if the PoSNFT is frozen.
    /// @return skillIds_ An array of skill IDs the PoSNFT holder possesses.
    /// @return skillLevels_ An array of corresponding skill levels.
    function getPoSNFTDetails(uint256 _tokenId) public view returns (address owner_, uint256 reputationPoints_, uint256 tasksCompleted_, bool isFrozen_, uint256[] memory skillIds_, uint256[] memory skillLevels_) {
        if (!_exists(_tokenId)) revert PoSNFTInvalidId();

        PoSNFT storage nft = _poSNFTs[_tokenId];
        owner_ = nft.owner;
        reputationPoints_ = nft.reputationPoints;
        tasksCompleted_ = nft.tasksCompleted;
        isFrozen_ = nft.isFrozen;

        // Count non-zero skills for dynamic array sizing
        uint256 currentSkillCount = 0;
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (nft.skills[i] > 0) {
                currentSkillCount++;
            }
        }

        skillIds_ = new uint256[](currentSkillCount);
        skillLevels_ = new uint256[](currentSkillCount);

        // Populate skill arrays
        uint256 j = 0;
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (nft.skills[i] > 0) {
                skillIds_[j] = i;
                skillLevels_[j] = nft.skills[i];
                j++;
            }
        }
    }

    /// @notice Triggers an update signal for a PoSNFT's metadata.
    ///         This function updates an internal timestamp, prompting off-chain services
    ///         to re-generate and refresh the metadata based on the PoSNFT's current on-chain attributes.
    /// @param _tokenId The ID of the PoSNFT.
    function updatePoSNFTMetadataURI(uint256 _tokenId) public onlyPoSNFTHolder(_tokenId) {
        if (!_exists(_tokenId)) revert PoSNFTInvalidId();
        _poSNFTs[_tokenId].lastMetadataUpdate = block.timestamp; // Update timestamp to signal change
        emit PoSNFTMetadataUpdated(_tokenId, block.timestamp);
    }

    /// @notice Freezes a PoSNFT, preventing its holder from participating in tasks or attestations. Only owner.
    /// @param _tokenId The ID of the PoSNFT to freeze.
    function freezePoSNFT(uint256 _tokenId) public onlyOwner {
        if (!_exists(_tokenId)) revert PoSNFTInvalidId();
        if (_poSNFTs[_tokenId].isFrozen) return; // Already frozen

        _poSNFTs[_tokenId].isFrozen = true;
        emit PoSNFTFrozen(_tokenId, msg.sender, block.timestamp);
    }

    /// @notice Unfreezes a previously frozen PoSNFT. Only owner.
    /// @param _tokenId The ID of the PoSNFT to unfreeze.
    function unfreezePoSNFT(uint256 _tokenId) public onlyOwner {
        if (!_exists(_tokenId)) revert PoSNFTInvalidId();
        if (!_poSNFTs[_tokenId].isFrozen) return; // Not frozen

        _poSNFTs[_tokenId].isFrozen = false;
        emit PoSNFTUnfrozen(_tokenId, msg.sender, block.timestamp);
    }

    // --- III. Skill Attestation & Reputation ---

    /// @notice Allows a PoSNFT holder to attest to another holder's specific skill.
    ///         This action increases the attested individual's skill level and reputation.
    ///         Requires the attester to have a strictly higher skill level than the attested,
    ///         or at least the `minAttesterLevel` for that skill if the attested has level 0.
    /// @param _attestedPoSNFTId The PoSNFT ID of the individual being attested.
    /// @param _skillId The ID of the skill being attested.
    function attestSkill(uint256 _attestedPoSNFTId, uint256 _skillId) public whenNotPaused {
        uint256 attesterPoSNFTId = _addressToPoSNFTId[msg.sender];
        if (attesterPoSNFTId == 0) revert PoSNFTNotOwnedByUser(); // Caller must own a PoSNFT
        if (!_exists(_attestedPoSNFTId)) revert PoSNFTInvalidId();
        if (attesterPoSNFTId == _attestedPoSNFTId) revert("Cannot attest your own skill.");

        PoSNFT storage attesterNFT = _poSNFTs[attesterPoSNFTId];
        PoSNFT storage attestedNFT = _poSNFTs[_attestedPoSNFTId];
        Skill storage skill = _skills[_skillId];

        if (attesterNFT.isFrozen) revert AttesterPoSNFTFrozen();
        if (attestedNFT.isFrozen) revert AttestedPoSNFTFrozen();
        if (skill.id == 0) revert SkillDoesNotExist();
        if (attesterNFT.reputationPoints < MIN_REPUTATION_FOR_ATTESTATION) revert AttesterNotEnoughReputation();

        uint256 attesterSkillLevel = attesterNFT.skills[_skillId];
        uint256 attestedSkillLevel = attestedNFT.skills[_skillId];

        // Attester must have a higher skill level or meet the minimum required level to attest
        if (attesterSkillLevel <= attestedSkillLevel || attesterSkillLevel < skill.minAttesterLevel) {
            revert AttesterSkillTooLow();
        }

        if (_skillAttestations[attesterPoSNFTId][_attestedPoSNFTId][_skillId]) revert AlreadyAttested();

        // Increase attested skill level and reputation
        attestedNFT.skills[_skillId]++;
        attestedNFT.reputationPoints += REPUTATION_PER_ATTESTATION;
        _skillAttestations[attesterPoSNFTId][_attestedPoSNFTId][_skillId] = true;
        attestedNFT.lastMetadataUpdate = block.timestamp; // Signal metadata update

        emit SkillAttested(attesterPoSNFTId, _attestedPoSNFTId, _skillId, attestedNFT.skills[_skillId]);
    }

    /// @notice Allows an attester to revoke a previously made skill attestation.
    ///         This action decreases the attested individual's skill level and reputation.
    /// @param _attestedPoSNFTId The PoSNFT ID of the individual whose skill was attested.
    /// @param _skillId The ID of the skill for which the attestation is to be revoked.
    function revokeAttestation(uint256 _attestedPoSNFTId, uint256 _skillId) public whenNotPaused {
        uint256 attesterPoSNFTId = _addressToPoSNFTId[msg.sender];
        if (attesterPoSNFTId == 0) revert PoSNFTNotOwnedByUser();
        if (!_exists(_attestedPoSNFTId)) revert PoSNFTInvalidId();
        if (_skills[_skillId].id == 0) revert SkillDoesNotExist();

        if (!_skillAttestations[attesterPoSNFTId][_attestedPoSNFTId][_skillId]) revert AttestationDoesNotExist();

        PoSNFT storage attestedNFT = _poSNFTs[_attestedPoSNFTId];
        
        // Decrease attested skill level and reputation. Simple decrement, could be more complex with weighted attestations.
        if (attestedNFT.skills[_skillId] > 0) attestedNFT.skills[_skillId]--;
        if (attestedNFT.reputationPoints >= REPUTATION_PER_ATTESTATION) attestedNFT.reputationPoints -= REPUTATION_PER_ATTESTATION;
        
        _skillAttestations[attesterPoSNFTId][_attestedPoSNFTId][_skillId] = false;
        attestedNFT.lastMetadataUpdate = block.timestamp; // Signal metadata update

        emit AttestationRevoked(attesterPoSNFTId, _attestedPoSNFTId, _skillId);
    }

    /// @notice Gets the current skill level of a specific PoSNFT for a given skill.
    /// @param _tokenId The PoSNFT ID.
    /// @param _skillId The skill ID.
    /// @return The skill level. Returns 0 if PoSNFT or skill does not exist, or if the PoSNFT has no level in that skill.
    function getSkillLevel(uint256 _tokenId, uint256 _skillId) public view returns (uint256) {
        if (!_exists(_tokenId)) return 0;
        if (_skills[_skillId].id == 0) return 0;
        return _poSNFTs[_tokenId].skills[_skillId];
    }

    // --- IV. Task Creation & Management ---

    /// @notice Creates a new task with specified skill requirements, bounty, and verification method.
    ///         If `_bountyToken` is address(0), native ETH is used and must be sent with the transaction.
    ///         For ERC20 bounties, `depositBounty` must be called separately after approval.
    /// @param _requiredSkillIds An array of skill IDs required for the task.
    /// @param _minSkillLevels An array of minimum skill levels corresponding to `_requiredSkillIds`.
    /// @param _bountyAmount The amount of bounty for completing the task.
    /// @param _bountyToken The address of the ERC20 token for bounty (address(0) for ETH).
    /// @param _proofVerificationMethod The method for verifying task completion (Attestation, OracleHash, ZKPProof).
    /// @param _proofDataHash A hash related to the proof (e.g., expected ZKP public inputs hash, IPFS CID, or a descriptive hash for attestation).
    /// @param _submissionDeadlineDays The number of days from the current timestamp until the submission deadline.
    function createTask(
        uint256[] memory _requiredSkillIds,
        uint256[] memory _minSkillLevels,
        uint256 _bountyAmount,
        address _bountyToken,
        ProofVerificationMethod _proofVerificationMethod,
        bytes32 _proofDataHash,
        uint40 _submissionDeadlineDays
    ) public payable whenNotPaused {
        if (_requiredSkillIds.length != _minSkillLevels.length) revert("Skill array length mismatch.");
        if (_bountyAmount == 0) revert InsufficientBountyAmount();
        if (_submissionDeadlineDays == 0) revert("Submission deadline must be in the future.");

        // Validate bounty token and deposit
        if (_bountyToken != address(0)) {
            if (!_acceptedBountyTokens[_bountyToken]) revert BountyTokenNotAccepted();
            if (msg.value > 0) revert("Do not send ETH for ERC20 bounty."); // Prevent accidental ETH send
        } else { // Native ETH bounty
            if (msg.value < _bountyAmount) revert InsufficientBountyAmount();
        }

        // Validate skills
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            if (_skills[_requiredSkillIds[i]].id == 0) revert SkillDoesNotExist();
            if (_minSkillLevels[i] == 0) revert InvalidMinAttesterLevel(); // Task cannot require level 0
        }

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();
        Task storage newTask = _tasks[newTaskId];

        newTask.requester = msg.sender;
        newTask.bountyAmount = _bountyAmount;
        newTask.bountyToken = _bountyToken;
        newTask.proofVerificationMethod = _proofVerificationMethod;
        newTask.proofDataHash = _proofDataHash;
        newTask.submissionDeadline = uint40(block.timestamp + (_submissionDeadlineDays * 1 days));
        newTask.status = TaskStatus.Open;
        newTask.bountyDeposited = (newTask.bountyToken == address(0)); // Only ETH bounties are deposited on creation

        // Store required skills
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            newTask.requiredSkills[_requiredSkillIds[i]] = _minSkillLevels[i];
        }

        emit TaskCreated(newTaskId, msg.sender, _bountyAmount, _bountyToken, _proofVerificationMethod);
    }

    /// @notice Allows a PoSNFT holder to claim an open task if they meet all skill requirements.
    /// @param _taskId The ID of the task to claim.
    function claimTask(uint256 _taskId) public whenNotPaused {
        uint256 workerPoSNFTId = _addressToPoSNFTId[msg.sender];
        if (workerPoSNFTId == 0) revert PoSNFTNotOwnedByUser();
        if (_poSNFTs[workerPoSNFTId].isFrozen) revert PoSNFTFrozenError();

        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId(); // Check if task exists
        if (task.status != TaskStatus.Open) revert TaskNotOpen();
        if (task.submissionDeadline < block.timestamp) revert TaskSubmissionDeadlinePassed();
        if (!task.bountyDeposited) revert BountyNotDeposited(); // Ensure bounty is ready before claiming

        // Check if worker meets skill requirements
        for (uint256 i = 1; i <= _skillIds.current(); i++) { // Iterate all defined skills
            uint256 requiredLevel = task.requiredSkills[i];
            if (requiredLevel > 0 && _poSNFTs[workerPoSNFTId].skills[i] < requiredLevel) {
                revert WorkerSkillsInsufficient();
            }
        }

        task.workerPoSNFTId = workerPoSNFTId;
        task.status = TaskStatus.Claimed;

        emit TaskClaimed(_taskId, workerPoSNFTId, block.timestamp);
    }

    /// @notice The assigned worker submits their proof of task completion.
    ///         The format of `_proofData` depends on the `proofVerificationMethod` defined for the task.
    /// @param _taskId The ID of the task.
    /// @param _proofData The actual proof data (e.g., a file hash, an attestation message, ZKP public inputs).
    function submitTaskProof(uint256 _taskId, bytes32 _proofData) public whenNotPaused {
        uint256 workerPoSNFTId = _addressToPoSNFTId[msg.sender];
        if (workerPoSNFTId == 0) revert PoSNFTNotOwnedByUser();

        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (task.workerPoSNFTId != workerPoSNFTId) revert TaskNotAssignedToWorker();
        if (task.status != TaskStatus.Claimed) revert TaskStatusInvalidForOperation();
        if (task.submissionDeadline < block.timestamp) revert TaskSubmissionDeadlinePassed();
        
        task.proofDataHash = _proofData; // Store the proof for verification
        task.status = TaskStatus.Submitted;

        emit TaskProofSubmitted(_taskId, workerPoSNFTId, _proofData);
    }

    /// @notice Verifies task completion. This function can be called by the requester or a trusted oracle/verifier.
    /// @param _taskId The ID of the task.
    /// @param _isSuccess True if verification is successful, false otherwise.
    /// @param _reason Optional reason for rejection, if `_isSuccess` is false.
    function verifyTaskCompletion(uint256 _taskId, bool _isSuccess, string memory _reason) public whenNotPaused {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (task.status != TaskStatus.Submitted) revert TaskNotSubmitted();

        // Only requester or trusted verifier can verify.
        // Trusted verifiers are specific to OracleHash method, requester for all.
        bool isAuthorized = (msg.sender == task.requester);
        if (task.proofVerificationMethod == ProofVerificationMethod.OracleHash) {
            isAuthorized = isAuthorized || _isTrustedOracleVerifier[msg.sender];
        }
        if (!isAuthorized) revert("Only requester or authorized verifier can verify.");

        if (_isSuccess) {
            task.status = TaskStatus.Verified;
            // Grant reputation and skill points to worker
            _poSNFTs[task.workerPoSNFTId].reputationPoints += REPUTATION_PER_TASK_COMPLETED;
            _poSNFTs[task.workerPoSNFTId].tasksCompleted++;

            // Optionally, increase skill levels for skills relevant to the task
            for (uint256 i = 1; i <= _skillIds.current(); i++) {
                if (task.requiredSkills[i] > 0) {
                    _poSNFTs[task.workerPoSNFTId].skills[i]++; // Simple increment, could be more complex based on task difficulty
                }
            }
            _poSNFTs[task.workerPoSNFTId].lastMetadataUpdate = block.timestamp; // Signal metadata update

            emit TaskVerified(_taskId, task.workerPoSNFTId, block.timestamp);
        } else {
            task.status = TaskStatus.Rejected;
            task.disputePeriodEnd = uint40(block.timestamp + DISPUTE_PERIOD_DURATION); // Start dispute period
            emit TaskRejected(_taskId, task.workerPoSNFTId, _reason, block.timestamp);
        }
    }

    /// @notice Allows either the requester or the worker to formally dispute a task outcome (currently, only from Rejected status).
    /// @param _taskId The ID of the task.
    function disputeTaskOutcome(uint256 _taskId) public whenNotPaused {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        
        uint256 callerPoSNFTId = _addressToPoSNFTId[msg.sender];
        bool isWorker = (callerPoSNFTId != 0 && task.workerPoSNFTId == callerPoSNFTId);
        bool isRequester = (msg.sender == task.requester);

        if (!isWorker && !isRequester) revert("Only task requester or worker can dispute.");

        if (task.status != TaskStatus.Rejected) revert TaskStatusInvalidForOperation();
        if (block.timestamp > task.disputePeriodEnd) revert DisputePeriodEnded();
        
        task.status = TaskStatus.Disputed;
        emit TaskDisputed(_taskId, msg.sender, block.timestamp);
    }

    /// @notice Resolves a disputed task. Only the contract owner (or a designated dispute resolver) can call this.
    ///         The owner decides the final status, either `Verified` or `Rejected`.
    /// @param _taskId The ID of the task.
    /// @param _finalStatus The final status to set for the task: `TaskStatus.Verified` or `TaskStatus.Rejected`.
    function resolveDispute(uint256 _taskId, TaskStatus _finalStatus) public onlyOwner {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (task.status != TaskStatus.Disputed) revert TaskStatusInvalidForOperation();

        if (block.timestamp <= task.disputePeriodEnd) revert TaskDisputePeriodActive(); // Dispute period must be over for resolution
        if (_finalStatus != TaskStatus.Verified && _finalStatus != TaskStatus.Rejected) {
            revert("Final status must be Verified or Rejected.");
        }

        task.status = _finalStatus;

        if (_finalStatus == TaskStatus.Verified) {
            // Grant reputation and skill points to worker if dispute resolved to Verified
            _poSNFTs[task.workerPoSNFTId].reputationPoints += REPUTATION_PER_TASK_COMPLETED;
            _poSNFTs[task.workerPoSNFTId].tasksCompleted++;
            for (uint256 i = 1; i <= _skillIds.current(); i++) {
                if (task.requiredSkills[i] > 0) {
                    _poSNFTs[task.workerPoSNFTId].skills[i]++;
                }
            }
            _poSNFTs[task.workerPoSNFTId].lastMetadataUpdate = block.timestamp; // Signal metadata update
        }
        // If rejected, no change to worker, bounty is refunded via refundBounty.

        emit TaskDisputeResolved(_taskId, _finalStatus, block.timestamp);
    }

    /// @notice Allows a requester to cancel an unclaimed task or a task before proof submission.
    /// @param _taskId The ID of the task to cancel.
    function cancelTask(uint256 _taskId) public whenNotPaused {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (msg.sender != task.requester) revert TaskRequesterMismatch();

        // Can only cancel if open or claimed but not submitted
        if (task.status != TaskStatus.Open && task.status != TaskStatus.Claimed) {
            revert TaskStatusInvalidForOperation();
        }

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId, msg.sender, block.timestamp);
    }

    // --- V. Bounty & Payouts ---

    /// @notice Allows the requester to deposit the bounty for an existing task.
    ///         This is required for ERC20 bounties (after approving the contract to spend tokens)
    ///         or if an ETH task was created without sufficient funds initially.
    /// @param _taskId The ID of the task.
    /// @param _amount The exact amount to deposit, must match `task.bountyAmount`.
    function depositBounty(uint256 _taskId, uint256 _amount) public payable whenNotPaused {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (msg.sender != task.requester) revert TaskRequesterMismatch();
        if (task.bountyDeposited) revert TaskBountyAlreadyDeposited();
        if (_amount == 0) revert InsufficientBountyAmount();
        if (task.bountyAmount != _amount) revert InsufficientBountyAmount(); // Must match exact amount

        if (task.bountyToken == address(0)) { // ETH bounty
            if (msg.value < _amount) revert InsufficientBountyAmount();
        } else { // ERC20 bounty
            if (msg.value > 0) revert("Do not send ETH for ERC20 bounty.");
            if (!_acceptedBountyTokens[task.bountyToken]) revert BountyTokenNotAccepted();
            // ERC20 deposit requires prior approval: msg.sender must have approved this contract
            // to transfer `_amount` from their balance.
            bool success = IERC20(task.bountyToken).transferFrom(msg.sender, address(this), _amount);
            if (!success) revert ERC20TransferFailed();
        }

        task.bountyDeposited = true;
        emit BountyDeposited(_taskId, msg.sender, _amount, task.bountyToken);
    }

    /// @notice Releases the escrowed bounty to the worker upon successful, undisputed task verification.
    ///         Can only be called when the task status is `Verified`.
    /// @param _taskId The ID of the task.
    function releaseBounty(uint256 _taskId) public whenNotPaused {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (task.status != TaskStatus.Verified && task.status != TaskStatus.Resolved) revert TaskStatusInvalidForOperation(); // Also allow release if dispute resolved to verified
        if (!task.bountyDeposited) revert BountyNotDeposited();
        if (msg.sender != task.requester && _addressToPoSNFTId[msg.sender] != task.workerPoSNFTId) revert("Only requester or worker can trigger payout.");

        address workerAddress = _poSNFTs[task.workerPoSNFTId].owner;

        if (task.bountyToken == address(0)) { // ETH
            (bool success, ) = payable(workerAddress).call{value: task.bountyAmount}("");
            if (!success) revert ETHTransferFailed();
        } else { // ERC20
            bool success = IERC20(task.bountyToken).transfer(workerAddress, task.bountyAmount);
            if (!success) revert ERC20TransferFailed();
        }

        task.bountyDeposited = false; // Mark bounty as released
        emit BountyReleased(_taskId, task.workerPoSNFTId, task.bountyAmount, task.bountyToken);
    }

    /// @notice Refunds the escrowed bounty to the requester if the task is cancelled, rejected, or dispute resolved to rejected.
    ///         For rejected tasks, the dispute period must have passed before a refund can be claimed.
    /// @param _taskId The ID of the task.
    function refundBounty(uint256 _taskId) public whenNotPaused {
        Task storage task = _tasks[_taskId];
        if (task.requester == address(0)) revert TaskInvalidId();
        if (msg.sender != task.requester) revert TaskRequesterMismatch();
        
        // Refund conditions: Cancelled, Rejected, or Dispute Resolved to Rejected
        if (task.status != TaskStatus.Cancelled && 
            task.status != TaskStatus.Rejected && 
            !(task.status == TaskStatus.Resolved && task.status == TaskStatus.Rejected)
            ) {
            revert TaskStatusInvalidForOperation();
        }
        // If rejected, dispute period must be over to allow refund
        if (task.status == TaskStatus.Rejected && block.timestamp <= task.disputePeriodEnd) {
             revert TaskDisputePeriodActive();
        }

        if (!task.bountyDeposited) revert BountyNotDeposited();

        if (task.bountyToken == address(0)) { // ETH
            (bool success, ) = payable(task.requester).call{value: task.bountyAmount}("");
            if (!success) revert ETHTransferFailed();
        } else { // ERC20
            bool success = IERC20(task.bountyToken).transfer(task.requester, task.bountyAmount);
            if (!success) revert ERC20TransferFailed();
        }

        task.bountyDeposited = false; // Mark bounty as refunded
        emit BountyRefunded(_taskId, task.requester, task.bountyAmount, task.bountyToken);
    }

    // --- View Functions ---

    /// @dev Overrides ERC721's tokenURI to return dynamic metadata based on on-chain state.
    ///      This implementation returns a URI that points to an off-chain service.
    ///      The service should use the `tokenId` and `lastMetadataUpdate` timestamp
    ///      to dynamically generate the JSON metadata reflecting the PoSNFT's current attributes.
    ///      A `data:` URI is possible for fully on-chain metadata but is typically gas-prohibitive.
    /// @param tokenId The ID of the PoSNFT.
    /// @return A string representing the URI for the PoSNFT's metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId(tokenId);

        string memory base = _baseURI();
        string memory tokenIdStr = Strings.toString(tokenId);
        string memory lastUpdateStr = Strings.toString(_poSNFTs[tokenId].lastMetadataUpdate); // Include last update time for caching purposes

        // Example: Base URI points to a service. E.g., `https://api.skillweave.xyz/metadata/`
        // The service then uses tokenId and lastUpdateStr to generate dynamic JSON.
        return string(abi.encodePacked(base, tokenIdStr, "-", lastUpdateStr, ".json"));
    }

    /// @notice Gets the PoSNFT ID associated with a given address.
    /// @param _owner The address to query.
    /// @return The PoSNFT ID owned by `_owner`, or 0 if no PoSNFT is owned by that address.
    function getPoSNFTIdByAddress(address _owner) public view returns (uint256) {
        return _addressToPoSNFTId[_owner];
    }
}
```