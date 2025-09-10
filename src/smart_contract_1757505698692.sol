Here's a Solidity smart contract for a "SkillForge Nexus" – a decentralized skill attestation and reputation network. This contract combines several advanced concepts: dynamic non-transferable tokens (Soulbound Tokens - SBTs), an on-chain reputation system, decentralized attestation verification, a skill tree, and a simple DAO governance model.

---

### SkillForge Nexus Smart Contract

**Outline:**

1.  **Constants & Enums:** Define various states, statuses, and fixed parameters for clarity.
2.  **Structs:** Data structures for `Skill`, `Attestation`, `AttestationRequest`, `Validator`, `Challenge`, and `Proposal`.
3.  **Events:** For transparency, off-chain indexing, and user interface updates.
4.  **ERC721 & Ownable Inheritance:** Leverages OpenZeppelin's standard for NFT-like tokens and basic administrative control.
5.  **State Variables:** Mappings and counters to store all core protocol data.
6.  **Constructor:** Initializes the contract owner, base NFT URI, and initial protocol parameters.
7.  **Modifiers:** Custom access control and state-checking modifiers to enforce business logic.
8.  **I. Core Skill Management Functions:** For defining and retrieving the hierarchical structure of skills.
9.  **II. Skill Attestation (SNFT) Management Functions:** Handles the lifecycle of skill attestations, from request to issuance and revocation.
10. **III. Reputation & Role Management Functions:** Manages validator roles, the challenging of attestations, and updates the dynamic reputation scores.
11. **IV. DAO Governance Functions:** Enables validators to propose, vote on, and execute changes to the protocol's parameters or other contract calls.
12. **V. Utility & Protocol Parameters Functions:** For staking, managing protocol fees, and querying current parameter settings.
13. **Internal & Private Helper Functions:** Encapsulates complex logic for better readability and maintainability.

**Function Summary:**

**I. Core Skill Management**
1.  `addSkillCategory(string memory _name, string memory _description)`: Adds a new top-level (root) skill category to the network. Only callable by the DAO.
2.  `addSubSkill(uint256 _parentSkillId, string memory _name, string memory _description, uint256[] memory _prerequisiteSkillIds)`: Adds a new sub-skill under an existing `_parentSkillId`, with optional `_prerequisiteSkillIds` that must be held by a user before they can be attested for this sub-skill. Only callable by the DAO.
3.  `getSkillDetails(uint256 _skillId)`: Retrieves comprehensive details (name, description, parent, prerequisites) for a specific skill ID.
4.  `getSkillsByParent(uint256 _parentSkillId)`: Returns an array of skill IDs that are direct children of a given parent skill.

**II. Skill Attestation (SNFT) Management**
5.  `requestAttestation(uint256 _skillId, address _forUser, uint256 _validityDurationSeconds, string memory _evidenceCID)`: Initiates a request for a `SkillAttestation` for a specified `_forUser` and `_skillId`. Requires evidence (IPFS CID) and a validity duration. Callable by `_forUser` or a `Validator`.
6.  `validateAttestation(uint256 _requestId, bool _approve, string memory _reason)`: An active validator reviews an `AttestationRequest`. If approved, a new SNFT is minted; otherwise, the request is rejected.
7.  `revokeAttestation(uint256 _attestationId, string memory _reason)`: Allows the original issuer of an attestation to revoke it due to error, within a grace period or with a reputation penalty.
8.  `extendAttestationValidity(uint256 _attestationId, uint256 _newValidUntil)`: Extends the `validUntil` timestamp of an existing attestation. Can be done by the issuer or DAO.
9.  `getUserAttestations(address _user)`: Returns an array of active `attestationId`s for a specific user.
10. `getAttestationDetails(uint256 _attestationId)`: Retrieves full details of a specific `SkillAttestation` (SNFT).
11. `getAttestationRequests(address _requester)`: Returns an array of active `attestationRequestId`s initiated by or for a specific user.

**III. Reputation & Role Management**
12. `becomeValidator(string memory _validatorProfileCID)`: Allows a user to stake a minimum amount of ETH to become an active validator, providing a profile CID.
13. `resignValidator()`: Allows an active validator to unstake their ETH and resign their role, subject to a cooldown period and no active challenges/proposals.
14. `challengeAttestation(uint256 _attestationId, string memory _reasonCID)`: Any user can challenge an existing attestation, requiring a bond (ETH) to initiate the dispute.
15. `voteOnChallenge(uint256 _challengeId, bool _upholdAttestation)`: Active validators vote on whether to uphold (attestation is valid) or reject (attestation is invalid) a specific challenge.
16. `getUserReputation(address _user)`: Queries the current dynamic reputation score for any given address.
17. `getValidatorDetails(address _validator)`: Retrieves comprehensive details (stake, status, profile) for a specific validator.
18. `getChallengeDetails(uint256 _challengeId)`: Retrieves full details of a specific attestation challenge, including voting status.

**IV. DAO Governance**
19. `proposeCall(address _target, bytes memory _calldata, string memory _description)`: Allows active validators to propose an arbitrary call to any contract, including the SkillForgeNexus itself, to change parameters or execute logic.
20. `voteOnProposal(uint256 _proposalId, bool _support)`: Active validators vote to support or oppose an open proposal.
21. `executeProposal(uint256 _proposalId)`: Executes a proposal that has met its voting quorum and threshold and is within its execution window.
22. `getProposalDetails(uint256 _proposalId)`: Retrieves full details of a specific DAO proposal, including its state and voting outcome.

**V. Utility & Protocol Parameters**
23. `updateProtocolParameters(uint256 _minValidatorStake, uint256 _challengeFee, uint256 _validatorCoolDownPeriod, uint256 _challengeVoteDuration, uint256 _proposalVoteDuration, uint256 _attestationGracePeriod)`: A DAO-only function to update core tunable parameters of the protocol.
24. `depositStake()`: Allows any user to deposit additional ETH into the protocol, typically used by validators to meet stake requirements.
25. `withdrawStake()`: Allows users to withdraw their available (unstaked) ETH from the protocol.
26. `getProtocolBalance()`: Returns the total ETH currently held by the SkillForge Nexus contract (stakes + fees).
27. `getProtocolFees()`: Returns the accumulated protocol fees (from challenge failures, etc.) available for DAO distribution.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title SkillForgeNexus
 * @dev A decentralized skill attestation and reputation network.
 *      Users can earn soulbound (non-transferable) Skill Attestation NFTs (SNFTs).
 *      Attestations are issued by staked validators and can be challenged by the community.
 *      A dynamic reputation system tracks validator and user performance.
 *      The protocol is governed by a decentralized autonomous organization (DAO).
 */
contract SkillForgeNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    // --- Constants & Enums ---

    enum RequestStatus { Pending, Approved, Rejected, Cancelled }
    enum AttestationStatus { Active, Revoked, Expired }
    enum ValidatorStatus { Active, Inactive, Resigning }
    enum ChallengeStatus { Open, Upheld, Rejected, Resolved }
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct Skill {
        string name;
        string description;
        uint256 parentSkillId; // 0 for root categories
        uint256[] prerequisiteSkillIds;
        bool exists; // To distinguish between non-existent and root (parent 0)
    }

    struct Attestation {
        address user;
        uint256 skillId;
        address issuer; // The validator who issued this attestation
        uint256 issuedAt;
        uint256 validUntil;
        string evidenceCID; // IPFS CID for evidence
        AttestationStatus status;
        uint256 lastUpdate; // Timestamp of last status change or validity extension
    }

    struct AttestationRequest {
        address forUser;
        uint256 skillId;
        uint256 validityDurationSeconds;
        string evidenceCID;
        address requester; // Who initiated the request (can be forUser or a validator)
        uint256 requestedAt;
        RequestStatus status;
    }

    struct Validator {
        uint256 stake;
        string profileCID; // IPFS CID for validator's public profile/credentials
        ValidatorStatus status;
        uint256 joinedAt;
        uint256 resignRequestedAt; // Timestamp when resignation was requested
        uint256 lastActionTimestamp; // For activity tracking / reputation decay considerations
    }

    struct Challenge {
        uint256 attestationId;
        address challenger;
        string reasonCID; // IPFS CID for challenge reason
        uint256 challengedAt;
        ChallengeStatus status;
        uint256 totalVotesFor; // Validators who voted to uphold the attestation
        uint256 totalVotesAgainst; // Validators who voted to reject the attestation
        mapping(address => bool) hasVoted; // Tracks if a validator has voted
    }

    struct Proposal {
        address target;
        bytes calldataPayload; // Encoded function call
        string description;
        address proposer;
        uint256 proposedAt;
        uint256 voteEndTime;
        uint256 gracePeriodEnd; // Time until proposal can be executed after vote ends
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    struct ProtocolParameters {
        uint256 minValidatorStake; // Minimum ETH required to be a validator
        uint256 challengeFee; // ETH required to challenge an attestation
        uint256 validatorCoolDownPeriod; // Time before validator can withdraw stake after resignation
        uint256 challengeVoteDuration; // How long validators have to vote on a challenge
        uint256 proposalVoteDuration; // How long validators have to vote on a DAO proposal
        uint256 proposalExecutionGracePeriod; // Time after proposal passes before it can be executed
        uint256 attestationGracePeriod; // Time an issuer can revoke an attestation without penalty
        uint256 reputationInitialScore;
        int256 reputationAttestationApprovedValidator;
        int256 reputationAttestationApprovedUser;
        int256 reputationAttestationRejectedValidator;
        int256 reputationChallengeSuccessfulChallenger;
        int256 reputationChallengeSuccessfulIssuerPenalty;
        int256 reputationChallengeFailedChallengerPenalty;
        int256 reputationChallengeVoteCorrect;
        int256 reputationChallengeVoteIncorrect;
        uint256 minProposalQuorumPercentage; // e.g., 50 (for 50% of active validators)
        uint256 minProposalVoteThresholdPercentage; // e.g., 60 (for 60% of votes must be 'for')
    }

    // --- Events ---

    event SkillCategoryAdded(uint256 indexed skillId, string name, address indexed by);
    event SubSkillAdded(uint256 indexed skillId, uint256 indexed parentSkillId, string name, address indexed by);
    event AttestationRequested(uint256 indexed requestId, uint256 indexed skillId, address indexed forUser, address requester, uint256 validityDuration);
    event AttestationValidated(uint256 indexed requestId, uint256 indexed attestationId, address indexed validator, bool approved);
    event AttestationRevoked(uint256 indexed attestationId, address indexed by, string reason);
    event AttestationValidityExtended(uint256 indexed attestationId, address indexed by, uint256 newValidUntil);
    event ValidatorRegistered(address indexed validator, uint256 stake, string profileCID);
    event ValidatorResigned(address indexed validator, uint256 stake, uint256 resignRequestedAt);
    event ChallengeInitiated(uint256 indexed challengeId, uint256 indexed attestationId, address indexed challenger, string reasonCID);
    event ChallengeVoted(uint256 indexed challengeId, address indexed voter, bool upholdAttestation);
    event ChallengeResolved(uint256 indexed challengeId, ChallengeStatus status, address indexed winner, address indexed loser);
    event ReputationUpdated(address indexed user, int256 oldScore, int256 newScore);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address target, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);
    event ProtocolParametersUpdated(ProtocolParameters newParams);

    // --- State Variables ---

    Counters.Counter private _skillIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _requestIds;
    Counters.Counter private _challengeIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Attestation) public attestations;
    mapping(uint256 => AttestationRequest) public attestationRequests;
    mapping(address => Validator) public validators;
    mapping(uint256 => Challenge) public challenges;
    mapping(uint256 => Proposal) public proposals;

    // Stores all attestation IDs for a user, to quickly query user's SNFTs
    mapping(address => uint256[]) private _userAttestations;
    // Stores all request IDs for a user (either as requester or forUser)
    mapping(address => uint256[]) private _userRequests;
    // Stores all sub-skill IDs for a parent skill
    mapping(uint256 => uint256[]) private _skillsByParent;
    // Stores all active validator addresses
    address[] public activeValidatorAddresses;

    mapping(address => int256) public reputationScores;
    uint256 public totalProtocolFees;

    ProtocolParameters public protocolParameters;

    // --- Constructor ---

    constructor(string memory baseTokenURI) ERC721("Skill Attestation NFT", "SNFT") Ownable(msg.sender) {
        _setBaseURI(baseTokenURI);

        // Initialize default protocol parameters
        protocolParameters = ProtocolParameters({
            minValidatorStake: 1 ether, // 1 ETH
            challengeFee: 0.1 ether, // 0.1 ETH
            validatorCoolDownPeriod: 7 days,
            challengeVoteDuration: 3 days,
            proposalVoteDuration: 5 days,
            proposalExecutionGracePeriod: 1 days,
            attestationGracePeriod: 1 days, // Time for issuer to revoke without penalty
            reputationInitialScore: 100,
            reputationAttestationApprovedValidator: 5,
            reputationAttestationApprovedUser: 10,
            reputationAttestationRejectedValidator: -2,
            reputationChallengeSuccessfulChallenger: 20,
            reputationChallengeSuccessfulIssuerPenalty: -30,
            reputationChallengeFailedChallengerPenalty: -10,
            reputationChallengeVoteCorrect: 1,
            reputationChallengeVoteIncorrect: -1,
            minProposalQuorumPercentage: 30, // 30% of active validators must vote
            minProposalVoteThresholdPercentage: 50 // 50% + 1 of votes must be 'for'
        });

        // Add the owner as the first validator (optional, but useful for bootstrap)
        _addValidator(msg.sender, protocolParameters.minValidatorStake, "Initial Owner Validator", false);
        reputationScores[msg.sender] = int256(protocolParameters.reputationInitialScore);
        _updateActiveValidatorAddresses(msg.sender, true);
        emit ValidatorRegistered(msg.sender, protocolParameters.minValidatorStake, "Initial Owner Validator");
    }

    // --- Modifiers ---

    modifier onlyValidator() {
        require(validators[_msgSender()].status == ValidatorStatus.Active, "SkillForgeNexus: Only active validators can call this function.");
        _;
    }

    modifier onlySkillIssuer(uint256 _attestationId) {
        require(attestations[_attestationId].issuer == _msgSender(), "SkillForgeNexus: Only the original issuer can perform this action.");
        _;
    }

    // DAO related
    modifier onlyDAO() {
        require(_msgSender() == address(this), "SkillForgeNexus: This function can only be called by the DAO (via proposal execution).");
        _;
    }

    // --- I. Core Skill Management Functions ---

    /**
     * @dev Adds a new top-level skill category.
     * @param _name The name of the skill category.
     * @param _description A description of the skill category.
     */
    function addSkillCategory(string memory _name, string memory _description) external onlyDAO {
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skills[newSkillId] = Skill({
            name: _name,
            description: _description,
            parentSkillId: 0, // 0 indicates a root category
            prerequisiteSkillIds: new uint256[](0),
            exists: true
        });
        emit SkillCategoryAdded(newSkillId, _name, _msgSender());
    }

    /**
     * @dev Adds a sub-skill under an existing skill, potentially with prerequisites.
     * @param _parentSkillId The ID of the parent skill.
     * @param _name The name of the sub-skill.
     * @param _description A description of the sub-skill.
     * @param _prerequisiteSkillIds An array of skill IDs that must be attested for before this sub-skill can be.
     */
    function addSubSkill(uint256 _parentSkillId, string memory _name, string memory _description, uint256[] memory _prerequisiteSkillIds) external onlyDAO {
        require(skills[_parentSkillId].exists, "SkillForgeNexus: Parent skill does not exist.");
        
        _skillIds.increment();
        uint256 newSkillId = _skillIds.current();
        skills[newSkillId] = Skill({
            name: _name,
            description: _description,
            parentSkillId: _parentSkillId,
            prerequisiteSkillIds: _prerequisiteSkillIds,
            exists: true
        });
        _skillsByParent[_parentSkillId].push(newSkillId);
        emit SubSkillAdded(newSkillId, _parentSkillId, _name, _msgSender());
    }

    /**
     * @dev Retrieves details for a specific skill ID.
     * @param _skillId The ID of the skill to retrieve.
     * @return name, description, parentSkillId, prerequisiteSkillIds
     */
    function getSkillDetails(uint256 _skillId) external view returns (string memory, string memory, uint256, uint256[] memory) {
        require(skills[_skillId].exists, "SkillForgeNexus: Skill does not exist.");
        Skill storage skill = skills[_skillId];
        return (skill.name, skill.description, skill.parentSkillId, skill.prerequisiteSkillIds);
    }

    /**
     * @dev Lists all direct sub-skills of a given parent skill.
     * @param _parentSkillId The ID of the parent skill.
     * @return An array of sub-skill IDs.
     */
    function getSkillsByParent(uint256 _parentSkillId) external view returns (uint256[] memory) {
        return _skillsByParent[_parentSkillId];
    }

    // --- II. Skill Attestation (SNFT) Management ---

    /**
     * @dev Initiates an attestation request for a skill for a user, with evidence.
     * @param _skillId The ID of the skill being requested.
     * @param _forUser The address of the user who will receive the attestation.
     * @param _validityDurationSeconds How long the attestation should be valid (in seconds).
     * @param _evidenceCID IPFS CID pointing to evidence supporting the attestation.
     */
    function requestAttestation(uint256 _skillId, address _forUser, uint256 _validityDurationSeconds, string memory _evidenceCID) external {
        require(skills[_skillId].exists, "SkillForgeNexus: Skill does not exist.");
        require(_forUser != address(0), "SkillForgeNexus: Cannot attest for zero address.");
        require(_validityDurationSeconds > 0, "SkillForgeNexus: Validity duration must be positive.");

        // Check prerequisites for _forUser
        Skill storage skill = skills[_skillId];
        for (uint256 i = 0; i < skill.prerequisiteSkillIds.length; i++) {
            require(_hasActiveAttestation(_forUser, skill.prerequisiteSkillIds[i]), "SkillForgeNexus: User missing prerequisite skill.");
        }

        _requestIds.increment();
        uint256 newRequestId = _requestIds.current();
        attestationRequests[newRequestId] = AttestationRequest({
            forUser: _forUser,
            skillId: _skillId,
            validityDurationSeconds: _validityDurationSeconds,
            evidenceCID: _evidenceCID,
            requester: _msgSender(),
            requestedAt: block.timestamp,
            status: RequestStatus.Pending
        });

        _userRequests[_forUser].push(newRequestId);
        if (_msgSender() != _forUser) {
            _userRequests[_msgSender()].push(newRequestId);
        }

        emit AttestationRequested(newRequestId, _skillId, _forUser, _msgSender(), _validityDurationSeconds);
    }

    /**
     * @dev A validator reviews and approves/rejects an attestation request.
     *      If approved, a new SNFT is minted for the user.
     * @param _requestId The ID of the attestation request.
     * @param _approve True to approve, false to reject.
     * @param _reason A reason string for approval or rejection.
     */
    function validateAttestation(uint256 _requestId, bool _approve, string memory _reason) external onlyValidator {
        AttestationRequest storage req = attestationRequests[_requestId];
        require(req.status == RequestStatus.Pending, "SkillForgeNexus: Request is not pending.");
        require(req.forUser != _msgSender(), "SkillForgeNexus: Validators cannot validate their own attestations.");

        req.status = _approve ? RequestStatus.Approved : RequestStatus.Rejected;

        if (_approve) {
            _attestationIds.increment();
            uint256 newAttestationId = _attestationIds.current();
            attestations[newAttestationId] = Attestation({
                user: req.forUser,
                skillId: req.skillId,
                issuer: _msgSender(),
                issuedAt: block.timestamp,
                validUntil: block.timestamp + req.validityDurationSeconds,
                evidenceCID: req.evidenceCID,
                status: AttestationStatus.Active,
                lastUpdate: block.timestamp
            });

            _safeMint(req.forUser, newAttestationId); // Mint the SNFT
            _userAttestations[req.forUser].push(newAttestationId);
            _updateReputation(_msgSender(), protocolParameters.reputationAttestationApprovedValidator);
            _updateReputation(req.forUser, protocolParameters.reputationAttestationApprovedUser);
            emit AttestationValidated(_requestId, newAttestationId, _msgSender(), true);
        } else {
            _updateReputation(_msgSender(), protocolParameters.reputationAttestationRejectedValidator);
            emit AttestationValidated(_requestId, 0, _msgSender(), false); // 0 for attestationId as none minted
        }
        // TODO: Consider reputation penalty for _forUser if request is rejected
    }

    /**
     * @dev An attestation issuer can revoke their previously issued attestation.
     *      Can be done without penalty within a grace period, or with penalty afterwards.
     * @param _attestationId The ID of the attestation to revoke.
     * @param _reason A reason for revocation.
     */
    function revokeAttestation(uint256 _attestationId, string memory _reason) external onlySkillIssuer(_attestationId) {
        Attestation storage att = attestations[_attestationId];
        require(att.status == AttestationStatus.Active, "SkillForgeNexus: Attestation is not active.");

        att.status = AttestationStatus.Revoked;
        att.lastUpdate = block.timestamp;

        // If revoked after grace period, penalize issuer
        if (block.timestamp > att.issuedAt + protocolParameters.attestationGracePeriod) {
            _updateReputation(att.issuer, protocolParameters.reputationChallengeSuccessfulIssuerPenalty); // Same penalty as failing a challenge
        }
        // TODO: Consider reputation impact on attestation holder (user)

        emit AttestationRevoked(_attestationId, _msgSender(), _reason);
    }

    /**
     * @dev Extends the valid-until date of an existing attestation.
     * @param _attestationId The ID of the attestation.
     * @param _newValidUntil The new timestamp until which the attestation is valid.
     */
    function extendAttestationValidity(uint256 _attestationId, uint256 _newValidUntil) external {
        Attestation storage att = attestations[_attestationId];
        require(att.status == AttestationStatus.Active, "SkillForgeNexus: Attestation is not active.");
        require(att.issuer == _msgSender() || _isDAOExecutor(), "SkillForgeNexus: Only issuer or DAO can extend validity.");
        require(_newValidUntil > att.validUntil, "SkillForgeNexus: New validity must be in the future beyond current.");

        att.validUntil = _newValidUntil;
        att.lastUpdate = block.timestamp;
        emit AttestationValidityExtended(_attestationId, _msgSender(), _newValidUntil);
    }

    /**
     * @dev Returns a list of active attestation IDs for a user.
     * @param _user The address of the user.
     * @return An array of active attestation IDs.
     */
    function getUserAttestations(address _user) external view returns (uint256[] memory) {
        uint256[] storage allUserAttestations = _userAttestations[_user];
        uint256[] memory activeAttestations = new uint256[](allUserAttestations.length);
        uint256 count = 0;
        for (uint256 i = 0; i < allUserAttestations.length; i++) {
            uint256 attId = allUserAttestations[i];
            if (attestations[attId].status == AttestationStatus.Active && attestations[attId].validUntil > block.timestamp) {
                activeAttestations[count] = attId;
                count++;
            }
        }
        // Resize array to actual count
        assembly {
            mstore(activeAttestations, count)
            mstore(add(activeAttestations, 0x20), activeAttestations)
        }
        return activeAttestations;
    }

    /**
     * @dev Retrieves full details of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return user, skillId, issuer, issuedAt, validUntil, evidenceCID, status, lastUpdate
     */
    function getAttestationDetails(uint256 _attestationId) external view returns (address, uint256, address, uint256, uint256, string memory, AttestationStatus, uint256) {
        Attestation storage att = attestations[_attestationId];
        require(att.user != address(0), "SkillForgeNexus: Attestation does not exist."); // Check existence
        return (att.user, att.skillId, att.issuer, att.issuedAt, att.validUntil, att.evidenceCID, att.status, att.lastUpdate);
    }

    /**
     * @dev Returns active attestation request IDs made by or for a user.
     * @param _requester The address of the user (who requested or for whom it was requested).
     * @return An array of active attestation request IDs.
     */
    function getAttestationRequests(address _requester) external view returns (uint256[] memory) {
        uint256[] storage allUserRequests = _userRequests[_requester];
        uint256[] memory activeRequests = new uint256[](allUserRequests.length);
        uint256 count = 0;
        for (uint256 i = 0; i < allUserRequests.length; i++) {
            uint256 reqId = allUserRequests[i];
            if (attestationRequests[reqId].status == RequestStatus.Pending) {
                activeRequests[count] = reqId;
                count++;
            }
        }
        assembly {
            mstore(activeRequests, count)
            mstore(add(activeRequests, 0x20), activeRequests)
        }
        return activeRequests;
    }

    // --- III. Reputation & Role Management ---

    /**
     * @dev Allows a user to stake funds and become a network validator.
     * @param _validatorProfileCID IPFS CID for the validator's public profile.
     */
    function becomeValidator(string memory _validatorProfileCID) external payable {
        require(msg.value >= protocolParameters.minValidatorStake, "SkillForgeNexus: Insufficient stake.");
        require(validators[_msgSender()].status == ValidatorStatus.Inactive, "SkillForgeNexus: User is already an active or resigning validator.");
        
        _addValidator(_msgSender(), msg.value, _validatorProfileCID, true);
        reputationScores[_msgSender()] = int256(protocolParameters.reputationInitialScore);
        _updateActiveValidatorAddresses(_msgSender(), true);
        emit ValidatorRegistered(_msgSender(), msg.value, _validatorProfileCID);
    }

    /**
     * @dev Allows a validator to unstake their funds and resign their role.
     *      Funds are subject to a cool-down period.
     */
    function resignValidator() external onlyValidator {
        Validator storage val = validators[_msgSender()];
        require(val.status == ValidatorStatus.Active, "SkillForgeNexus: Validator is not active.");
        
        val.status = ValidatorStatus.Resigning;
        val.resignRequestedAt = block.timestamp;
        _updateActiveValidatorAddresses(_msgSender(), false);
        emit ValidatorResigned(_msgSender(), val.stake, val.resignRequestedAt);
    }

    /**
     * @dev Any user can challenge an existing attestation, requiring a bond (ETH).
     * @param _attestationId The ID of the attestation to challenge.
     * @param _reasonCID IPFS CID for the detailed reason for the challenge.
     */
    function challengeAttestation(uint256 _attestationId, string memory _reasonCID) external payable {
        Attestation storage att = attestations[_attestationId];
        require(att.user != address(0), "SkillForgeNexus: Attestation does not exist.");
        require(att.status == AttestationStatus.Active, "SkillForgeNexus: Attestation is not active or already expired.");
        require(msg.value >= protocolParameters.challengeFee, "SkillForgeNexus: Insufficient challenge fee.");
        require(_msgSender() != att.issuer, "SkillForgeNexus: Cannot challenge your own issued attestation.");
        require(_msgSender() != att.user, "SkillForgeNexus: Cannot challenge your own received attestation.");

        // Check if there's an existing open challenge for this attestation
        for(uint256 i = 1; i <= _challengeIds.current(); i++){
            if(challenges[i].attestationId == _attestationId && challenges[i].status == ChallengeStatus.Open){
                revert("SkillForgeNexus: An open challenge already exists for this attestation.");
            }
        }

        _challengeIds.increment();
        uint256 newChallengeId = _challengeIds.current();
        challenges[newChallengeId] = Challenge({
            attestationId: _attestationId,
            challenger: _msgSender(),
            reasonCID: _reasonCID,
            challengedAt: block.timestamp,
            status: ChallengeStatus.Open,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        totalProtocolFees += (msg.value - protocolParameters.challengeFee); // Excess fee kept by protocol
        emit ChallengeInitiated(newChallengeId, _attestationId, _msgSender(), _reasonCID);
    }

    /**
     * @dev Active validators vote to uphold (attestation is valid) or reject (attestation is invalid) a specific challenge.
     * @param _challengeId The ID of the challenge to vote on.
     * @param _upholdAttestation True if the validator believes the attestation is valid, false if invalid.
     */
    function voteOnChallenge(uint256 _challengeId, bool _upholdAttestation) external onlyValidator {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "SkillForgeNexus: Challenge is not open for voting.");
        require(block.timestamp <= challenge.challengedAt + protocolParameters.challengeVoteDuration, "SkillForgeNexus: Voting period for challenge has ended.");
        require(!challenge.hasVoted[_msgSender()], "SkillForgeNexus: Validator has already voted on this challenge.");

        challenge.hasVoted[_msgSender()] = true;
        if (_upholdAttestation) {
            challenge.totalVotesFor++;
        } else {
            challenge.totalVotesAgainst++;
        }

        emit ChallengeVoted(_challengeId, _msgSender(), _upholdAttestation);

        // Check if all active validators have voted or vote duration ended
        if (challenge.totalVotesFor + challenge.totalVotesAgainst >= activeValidatorAddresses.length || block.timestamp > challenge.challengedAt + protocolParameters.challengeVoteDuration) {
            _resolveChallenge(_challengeId);
        }
    }

    /**
     * @dev Queries the current dynamic reputation score for any given address.
     * @param _user The address to query.
     * @return The reputation score.
     */
    function getUserReputation(address _user) external view returns (int256) {
        return reputationScores[_user];
    }

    /**
     * @dev Retrieves comprehensive details for a specific validator.
     * @param _validator The address of the validator.
     * @return stake, profileCID, status, joinedAt, resignRequestedAt, lastActionTimestamp
     */
    function getValidatorDetails(address _validator) external view returns (uint256, string memory, ValidatorStatus, uint256, uint256, uint256) {
        Validator storage val = validators[_validator];
        return (val.stake, val.profileCID, val.status, val.joinedAt, val.resignRequestedAt, val.lastActionTimestamp);
    }

    /**
     * @dev Retrieves full details of a specific attestation challenge.
     * @param _challengeId The ID of the challenge.
     * @return attestationId, challenger, reasonCID, challengedAt, status, totalVotesFor, totalVotesAgainst
     */
    function getChallengeDetails(uint256 _challengeId) external view returns (uint256, address, string memory, uint256, ChallengeStatus, uint256, uint256) {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.challenger != address(0), "SkillForgeNexus: Challenge does not exist.");
        return (challenge.attestationId, challenge.challenger, challenge.reasonCID, challenge.challengedAt, challenge.status, challenge.totalVotesFor, challenge.totalVotesAgainst);
    }

    // --- IV. DAO Governance ---

    /**
     * @dev Allows active validators to propose an arbitrary call to any contract, including the SkillForgeNexus itself.
     * @param _target The address of the contract to call.
     * @param _calldata The encoded function call (e.g., `abi.encodeWithSelector(YourContract.yourFunction.selector, arg1, arg2)`).
     * @param _description A human-readable description of the proposal.
     */
    function proposeCall(address _target, bytes memory _calldata, string memory _description) external onlyValidator {
        require(_target != address(0), "SkillForgeNexus: Target address cannot be zero.");
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            target: _target,
            calldataPayload: _calldata,
            description: _description,
            proposer: _msgSender(),
            proposedAt: block.timestamp,
            voteEndTime: block.timestamp + protocolParameters.proposalVoteDuration,
            gracePeriodEnd: 0, // Set after vote ends
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            status: ProposalStatus.Pending
        });

        // Proposer automatically votes for their own proposal
        proposals[newProposalId].hasVoted[_msgSender()] = true;
        proposals[newProposalId].votesFor++;

        emit ProposalCreated(newProposalId, _msgSender(), _target, _description);
    }

    /**
     * @dev Active validators vote to support or oppose an open proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyValidator {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "SkillForgeNexus: Proposal is not active for voting.");
        require(block.timestamp < proposal.voteEndTime, "SkillForgeNexus: Voting period for proposal has ended.");
        require(!proposal.hasVoted[_msgSender()], "SkillForgeNexus: Validator has already voted on this proposal.");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a proposal that has met its voting quorum and threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "SkillForgeNexus: Proposal has not succeeded.");
        require(block.timestamp >= proposal.gracePeriodEnd, "SkillForgeNexus: Proposal execution grace period not over.");

        proposal.status = ProposalStatus.Executed;
        (bool success, ) = proposal.target.call(proposal.calldataPayload);
        require(success, "SkillForgeNexus: Proposal execution failed.");

        emit ProposalExecuted(_proposalId, _msgSender());
    }
    
    /**
     * @dev Retrieves full details of a specific DAO proposal.
     * @param _proposalId The ID of the proposal.
     * @return target, calldataPayload, description, proposer, proposedAt, voteEndTime, gracePeriodEnd, votesFor, votesAgainst, status
     */
    function getProposalDetails(uint256 _proposalId) external view returns (address, bytes memory, string memory, address, uint256, uint256, uint256, uint256, uint256, ProposalStatus) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "SkillForgeNexus: Proposal does not exist.");
        return (
            proposal.target,
            proposal.calldataPayload,
            proposal.description,
            proposal.proposer,
            proposal.proposedAt,
            proposal.voteEndTime,
            proposal.gracePeriodEnd,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status
        );
    }

    // --- V. Utility & Protocol Parameters ---

    /**
     * @dev DAO-only function to update core tunable parameters of the protocol.
     */
    function updateProtocolParameters(
        uint256 _minValidatorStake,
        uint256 _challengeFee,
        uint256 _validatorCoolDownPeriod,
        uint256 _challengeVoteDuration,
        uint256 _proposalVoteDuration,
        uint256 _proposalExecutionGracePeriod,
        uint256 _attestationGracePeriod,
        uint256 _reputationInitialScore,
        int256 _reputationAttestationApprovedValidator,
        int256 _reputationAttestationApprovedUser,
        int256 _reputationAttestationRejectedValidator,
        int256 _reputationChallengeSuccessfulChallenger,
        int256 _reputationChallengeSuccessfulIssuerPenalty,
        int256 _reputationChallengeFailedChallengerPenalty,
        int256 _reputationChallengeVoteCorrect,
        int256 _reputationChallengeVoteIncorrect,
        uint256 _minProposalQuorumPercentage,
        uint256 _minProposalVoteThresholdPercentage
    ) external onlyDAO {
        protocolParameters = ProtocolParameters({
            minValidatorStake: _minValidatorStake,
            challengeFee: _challengeFee,
            validatorCoolDownPeriod: _validatorCoolDownPeriod,
            challengeVoteDuration: _challengeVoteDuration,
            proposalVoteDuration: _proposalVoteDuration,
            proposalExecutionGracePeriod: _proposalExecutionGracePeriod,
            attestationGracePeriod: _attestationGracePeriod,
            reputationInitialScore: _reputationInitialScore,
            reputationAttestationApprovedValidator: _reputationAttestationApprovedValidator,
            reputationAttestationApprovedUser: _reputationAttestationApprovedUser,
            reputationAttestationRejectedValidator: _reputationAttestationRejectedValidator,
            reputationChallengeSuccessfulChallenger: _reputationChallengeSuccessfulChallenger,
            reputationChallengeSuccessfulIssuerPenalty: _reputationChallengeSuccessfulIssuerPenalty,
            reputationChallengeFailedChallengerPenalty: _reputationChallengeFailedChallengerPenalty,
            reputationChallengeVoteCorrect: _reputationChallengeVoteCorrect,
            reputationChallengeVoteIncorrect: _reputationChallengeVoteIncorrect,
            minProposalQuorumPercentage: _minProposalQuorumPercentage,
            minProposalVoteThresholdPercentage: _minProposalVoteThresholdPercentage
        });
        emit ProtocolParametersUpdated(protocolParameters);
    }

    /**
     * @dev Allows users to deposit additional stake into the protocol.
     */
    function depositStake() external payable {
        validators[_msgSender()].stake += msg.value;
        if (validators[_msgSender()].status == ValidatorStatus.Inactive && validators[_msgSender()].stake >= protocolParameters.minValidatorStake) {
            // Automatically reactivate if enough stake is added and was inactive
            validators[_msgSender()].status = ValidatorStatus.Active;
            validators[_msgSender()].joinedAt = block.timestamp;
            _updateActiveValidatorAddresses(_msgSender(), true);
        }
    }

    /**
     * @dev Allows users to withdraw their available stake (after resignation/cool-down).
     */
    function withdrawStake() external {
        Validator storage val = validators[_msgSender()];
        require(val.status == ValidatorStatus.Resigning, "SkillForgeNexus: Validator must be in resigning state.");
        require(block.timestamp >= val.resignRequestedAt + protocolParameters.validatorCoolDownPeriod, "SkillForgeNexus: Cool-down period not over.");
        
        uint256 amount = val.stake;
        val.stake = 0;
        val.status = ValidatorStatus.Inactive;
        
        (bool sent, ) = _msgSender().call{value: amount}("");
        require(sent, "SkillForgeNexus: Failed to withdraw stake.");
    }

    /**
     * @dev Returns the total ETH held by the contract as stake and fees.
     */
    function getProtocolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the amount of collected protocol fees available for DAO distribution.
     */
    function getProtocolFees() external view returns (uint256) {
        return totalProtocolFees;
    }

    /**
     * @dev Transfers accumulated protocol fees to a specified address. Callable only by the DAO.
     * @param _to The address to send the fees to.
     * @param _amount The amount of fees to transfer.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyDAO {
        require(_amount > 0 && _amount <= totalProtocolFees, "SkillForgeNexus: Invalid amount to withdraw.");
        totalProtocolFees -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "SkillForgeNexus: Failed to transfer protocol fees.");
    }


    // --- Internal & Private Helper Functions ---

    /**
     * @dev Override ERC721 transfer functions to make tokens soulbound.
     *      Attestations are non-transferable.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from == address(0)) and burning (to == address(0))
        require(from == address(0) || to == address(0), "SkillForgeNexus: Attestations are soulbound and non-transferable.");
    }

    /**
     * @dev Checks if a user has an active attestation for a specific skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return True if the user has an active attestation, false otherwise.
     */
    function _hasActiveAttestation(address _user, uint256 _skillId) private view returns (bool) {
        for (uint256 i = 0; i < _userAttestations[_user].length; i++) {
            uint256 attId = _userAttestations[_user][i];
            Attestation storage att = attestations[attId];
            if (att.skillId == _skillId && att.status == AttestationStatus.Active && att.validUntil > block.timestamp) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Updates the reputation score of a user.
     * @param _user The address of the user.
     * @param _change The change in reputation score (can be negative).
     */
    function _updateReputation(address _user, int256 _change) private {
        int256 oldScore = reputationScores[_user];
        reputationScores[_user] = oldScore + _change;
        emit ReputationUpdated(_user, oldScore, reputationScores[_user]);
    }

    /**
     * @dev Internal function to add or update validator status.
     */
    function _addValidator(address _validatorAddress, uint256 _stake, string memory _profileCID, bool _isNew) private {
        Validator storage val = validators[_validatorAddress];
        if (_isNew) {
            val.joinedAt = block.timestamp;
        }
        val.stake += _stake; // Allows adding stake to existing validator entry
        val.profileCID = _profileCID;
        val.status = ValidatorStatus.Active;
        val.lastActionTimestamp = block.timestamp;
    }

    /**
     * @dev Internal function to manage the list of active validator addresses.
     * @param _validator The validator address.
     * @param _add True to add, false to remove.
     */
    function _updateActiveValidatorAddresses(address _validator, bool _add) private {
        if (_add) {
            bool found = false;
            for (uint256 i = 0; i < activeValidatorAddresses.length; i++) {
                if (activeValidatorAddresses[i] == _validator) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                activeValidatorAddresses.push(_validator);
            }
        } else {
            for (uint256 i = 0; i < activeValidatorAddresses.length; i++) {
                if (activeValidatorAddresses[i] == _validator) {
                    activeValidatorAddresses[i] = activeValidatorAddresses[activeValidatorAddresses.length - 1];
                    activeValidatorAddresses.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Resolves an attestation challenge based on validator votes.
     * @param _challengeId The ID of the challenge to resolve.
     */
    function _resolveChallenge(uint256 _challengeId) private {
        Challenge storage challenge = challenges[_challengeId];
        Attestation storage att = attestations[challenge.attestationId];

        require(challenge.status == ChallengeStatus.Open, "SkillForgeNexus: Challenge is not open.");
        require(block.timestamp > challenge.challengedAt + protocolParameters.challengeVoteDuration || challenge.totalVotesFor + challenge.totalVotesAgainst >= activeValidatorAddresses.length, "SkillForgeNexus: Voting period still active or not enough votes.");

        ChallengeStatus resultStatus;
        address winner = address(0);
        address loser = address(0);
        
        // Determine outcome
        if (challenge.totalVotesFor > challenge.totalVotesAgainst) {
            resultStatus = ChallengeStatus.Upheld;
            winner = att.issuer; // Issuer wins
            loser = challenge.challenger; // Challenger loses
        } else if (challenge.totalVotesAgainst > challenge.totalVotesFor) {
            resultStatus = ChallengeStatus.Rejected;
            winner = challenge.challenger; // Challenger wins
            loser = att.issuer; // Issuer loses
        } else {
            // Tie-breaker: If tie, attestation is upheld by default (status quo)
            resultStatus = ChallengeStatus.Upheld;
            winner = att.issuer;
            loser = challenge.challenger;
        }

        challenge.status = ChallengeStatus.Resolved;
        
        // Apply reputation changes and manage challenge fee/bond
        if (resultStatus == ChallengeStatus.Upheld) {
            // Attestation upheld: Challenger loses bond, issuer gets reputation boost
            totalProtocolFees += protocolParameters.challengeFee; // Challenger's fee goes to protocol
            _updateReputation(challenge.challenger, protocolParameters.reputationChallengeFailedChallengerPenalty);
            _updateReputation(att.issuer, -protocolParameters.reputationChallengeSuccessfulIssuerPenalty/2); // Small boost to issuer for attestation being valid
        } else { // ChallengeStatus.Rejected
            // Attestation rejected: Challenger gets bond back, issuer penalized, attestation revoked
            (bool success, ) = challenge.challenger.call{value: protocolParameters.challengeFee}("");
            require(success, "SkillForgeNexus: Failed to return challenge fee to challenger.");
            att.status = AttestationStatus.Revoked;
            att.lastUpdate = block.timestamp;
            _updateReputation(challenge.challenger, protocolParameters.reputationChallengeSuccessfulChallenger);
            _updateReputation(att.issuer, protocolParameters.reputationChallengeSuccessfulIssuerPenalty);
            _burn(att.user, challenge.attestationId); // Burn the SNFT
            // TODO: Remove attestationId from _userAttestations array
        }

        // Apply reputation changes to voters
        for (uint256 i = 0; i < activeValidatorAddresses.length; i++) {
            address voter = activeValidatorAddresses[i];
            if (challenge.hasVoted[voter]) {
                bool votedCorrectly;
                if (resultStatus == ChallengeStatus.Upheld) {
                    votedCorrectly = challenge.hasVoted[voter]; // True means they voted FOR uphold
                } else { // ChallengeStatus.Rejected
                    votedCorrectly = !challenge.hasVoted[voter]; // True means they voted AGAINST uphold
                }
                _updateReputation(voter, votedCorrectly ? protocolParameters.reputationChallengeVoteCorrect : protocolParameters.reputationChallengeVoteIncorrect);
            }
        }

        emit ChallengeResolved(_challengeId, resultStatus, winner, loser);
    }
    
    /**
     * @dev Internal function to check and finalize proposals after voting ends.
     */
    function _finalizeProposal(uint256 _proposalId) private {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Pending || block.timestamp < proposal.voteEndTime) {
            return; // Not ready to finalize
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 activeValidatorCount = activeValidatorAddresses.length;

        // Check Quorum
        require(activeValidatorCount > 0, "SkillForgeNexus: No active validators to form quorum.");
        if ((totalVotes * 100) < (activeValidatorCount * protocolParameters.minProposalQuorumPercentage)) {
            proposal.status = ProposalStatus.Failed;
            return;
        }

        // Check Threshold
        if ((proposal.votesFor * 100) > (totalVotes * protocolParameters.minProposalVoteThresholdPercentage)) {
            proposal.status = ProposalStatus.Succeeded;
            proposal.gracePeriodEnd = block.timestamp + protocolParameters.proposalExecutionGracePeriod;
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    /**
     * @dev Checks if the message sender is the contract itself (i.e., executed by the DAO).
     */
    function _isDAOExecutor() private view returns (bool) {
        return _msgSender() == address(this);
    }

    // Fallback function to receive Ether for staking and fees
    receive() external payable {}
    fallback() external payable {}
}
```