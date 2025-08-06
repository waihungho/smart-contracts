This smart contract, **NexusAttestationProtocol (NAP)**, introduces a decentralized, verifiable reputation and skill registry leveraging non-transferable Soulbound Tokens (SBTs). It's designed to be a foundational layer for decentralized identity and skill verification, incorporating advanced concepts like hierarchical, community-curated skill trees, on-chain proof of contribution verification, dynamic reputation scoring, and robust governance mechanisms.

### Outline and Function Summary

**I. Core SBT Management (Non-Transferable ERC-721 Adaptation)**
This section handles the creation, revocation, and querying of non-transferable attestations, adapting the ERC-721 standard to enforce soulbound properties.

*   **`constructor()`**: Initializes the contract with ERC-721 name/symbol and sets initial reputation weights and attester roles (e.g., to the deployer).
*   **`_attest(address recipient, AttestationType _type, uint256 refId, string memory metadataURI)`**: (Internal) The core function responsible for minting a new SBT, storing its details, and updating associated counts. It ensures the token cannot be transferred after minting.
*   **`attestSkill(address recipient, uint256 skillId, string memory metadataURI)`**: Issues a `Skill` SBT to a recipient, granted by an authorized attester.
*   **`attestAchievement(address recipient, uint256 achievementId, string memory metadataURI)`**: Issues an `Achievement` SBT for general accomplishments.
*   **`attestContribution(address recipient, uint256 contributionId, string memory metadataURI)`**: Issues a `Contribution` SBT, typically after an on-chain proof of contribution has been verified.
*   **`attestRole(address recipient, uint256 roleId, string memory metadataURI)`**: Issues a `Role` SBT, granting a specific on-chain role (e.g., "Core Contributor," "Reviewer").
*   **`revokeAttestation(uint256 tokenId)`**: Allows the recipient of an SBT to voluntarily self-revoke it, effectively burning the token.
*   **`getSBTCount(address owner)`**: Returns the total number of non-revoked SBTs held by a given address.
*   **`hasSBT(address owner, AttestationType _type, uint256 refId)`**: Checks if an address possesses at least one specific type of SBT with a given reference ID (e.g., "has `Skill` SBT with `skillId` 123").
*   **`getAttestation(uint256 tokenId)`**: Retrieves the detailed information of a specific SBT by its token ID.
*   **`_beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)`**: (Internal ERC-721 override) This crucial function prevents any token transfers (i.e., `transferFrom` calls), ensuring the soulbound nature of the tokens.

**II. Skill Tree Management**
This section implements a hierarchical skill tree where new skills and their prerequisites can be proposed, voted on, and integrated into the system by the community.

*   **`proposeSkill(string memory name, string memory descriptionURI, uint256[] memory prerequisites)`**: Allows users with sufficient reputation to propose a new skill, specifying its name, description, and an array of prerequisite skill IDs.
*   **`voteOnSkillProposal(uint256 proposalId, bool _for)`**: Enables users with sufficient reputation to cast a vote (for or against) on an active skill proposal.
*   **`executeSkillProposal(uint256 proposalId)`**: Finalizes a skill proposal that has met its voting period and received a majority of "yes" votes, officially adding the new skill to the registry.
*   **`getSkillPrerequisites(uint256 skillId)`**: Retrieves the list of prerequisite skill IDs for a given skill.
*   **`isSkillPrerequisitesMet(address account, uint256 skillId)`**: Checks if a specific account holds all the necessary prerequisite Skill SBTs for a given target skill.

**III. Reputation System**
This system dynamically calculates a user's reputation score based on the types and quantities of SBTs they hold, with configurable weights for each SBT type.

*   **`calculateReputationScore(address account)`**: Calculates and returns an account's current reputation score by summing the weighted values of all their non-revoked SBTs. (Note: For very large numbers of SBTs, this might be better managed by off-chain indexing or a score update mechanism.)
*   **`getReputationWeight(AttestationType _type)`**: Returns the current reputation weight assigned to a specific attestation type.
*   **`updateReputationWeight(AttestationType _type, uint256 newWeight)`**: Allows the contract's governance to adjust the reputation weight of different attestation types, enabling dynamic value adjustments.

**IV. On-Chain Proofs of Contribution (PoC)**
This mechanism facilitates the submission and verification of off-chain contributions, enabling authorized entities to attest to them by issuing `Contribution` SBTs.

*   **`submitContributionProof(string memory contributionHash, uint256 skillId)`**: Users submit a hash (e.g., IPFS CID) of their off-chain work, linking it to a specific skill they aim to prove. Requires meeting the skill's prerequisites.
*   **`reviewContributionProof(uint256 proofId, bool verified)`**: An authorized attester (typically a `Contribution` type attester or a role holder) reviews the off-chain proof and marks it as verified or rejected.
*   **`finalizeContributionProof(uint256 proofId)`**: A governance function to finalize a *reviewed and verified* contribution proof, automatically minting a `Contribution` SBT to the original submitter.

**V. Governance & System Parameters**
This section defines how the community can propose and vote on changes to the protocol's core parameters and manage attester roles.

*   **`proposeParameterChange(string memory paramKey, bytes memory newValue)`**: Allows users with sufficient reputation to propose changes to configurable system parameters (e.g., voting periods, minimum votes).
*   **`voteOnParameterChange(uint256 proposalId, bool _for)`**: Enables users with sufficient reputation to vote for or against a parameter change proposal.
*   **`executeParameterChange(uint256 proposalId)`**: Executes a parameter change proposal that has passed its voting period and received enough "yes" votes, applying the new parameter value.
*   **`setAttesterRole(AttestationType _type, address attester, bool canAttest)`**: Grants or revokes the ability of a specific address to issue SBTs of a given type. This function is controlled by governance.

**VI. Dispute Resolution**
A simplified mechanism for users to initiate and resolve disputes over existing attestations, allowing the community (via governance) to vote on their validity.

*   **`initiateDispute(uint256 attestationTokenId, string memory reason)`**: Allows users with sufficient reputation to initiate a dispute against an existing SBT, providing a reason.
*   **`voteOnDispute(uint256 disputeId, bool _forRevoke)`**: Enables users with sufficient reputation to vote on whether a disputed attestation should be revoked or upheld.
*   **`resolveDispute(uint256 disputeId)`**: Finalizes a dispute after its voting period ends, revoking the SBT if the 'for revoke' votes prevail, otherwise upholding it. Controlled by governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI if needed, but I'll skip complex metadata for brevity.

contract NexusAttestationProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _nextTokenId; // Counter for unique SBT IDs
    Counters.Counter private _nextSkillId; // Counter for unique Skill IDs
    Counters.Counter private _nextSkillProposalId; // Counter for skill proposals
    Counters.Counter private _nextContributionProofId; // Counter for contribution proofs
    Counters.Counter private _nextParameterChangeProposalId; // Counter for parameter change proposals
    Counters.Counter private _nextDisputeId; // Counter for dispute IDs

    // --- Enums & Structs ---

    enum AttestationType {
        Skill,
        Achievement,
        Contribution,
        Role
    }

    struct Attestation {
        address attester;         // Address of the entity that issued the attestation
        address recipient;        // Address that received the SBT
        AttestationType attestationType; // Type of attestation
        uint256 refId;            // Reference ID: skillId, achievementId, contributionId, roleId
        uint256 timestamp;        // Timestamp of attestation issuance
        string metadataURI;       // URI pointing to off-chain metadata (e.g., IPFS CID of JSON)
        bool isRevoked;           // True if the attestation has been revoked (by recipient or governance)
    }

    struct SkillData {
        uint256 id;               // Unique ID of the skill
        string name;              // Name of the skill
        string descriptionURI;    // URI pointing to the skill's detailed description
        uint256[] prerequisites;  // Array of skill IDs that are prerequisites for this skill
        bool exists;              // To quickly check if a skillId is valid
    }

    struct SkillProposal {
        uint256 id;               // Unique ID of the proposal
        address proposer;         // Address that proposed the skill
        string name;              // Proposed name of the skill
        string descriptionURI;    // Proposed description URI
        uint256[] prerequisites;  // Proposed prerequisites
        uint256 yesVotes;         // Number of 'yes' votes
        uint256 noVotes;          // Number of 'no' votes
        uint256 expiration;       // Timestamp when voting ends
        bool executed;            // True if the proposal has been executed
        bool canceled;            // True if the proposal has been canceled (e.g., by proposer or governance)
    }

    enum ProofStatus {
        Pending,   // Awaiting review
        Reviewed,  // Has been reviewed by an attester
        Verified,  // Fully verified and SBT minted
        Rejected   // Rejected by a reviewer
    }

    struct ContributionProof {
        uint256 id;                 // Unique ID of the proof
        address submitter;          // Address that submitted the proof
        string contributionHash;    // Hash or identifier of the off-chain proof (e.g., IPFS CID, commit hash)
        uint256 skillId;            // The skill this contribution aims to prove
        address reviewer;           // Address of the last reviewer
        ProofStatus status;         // Current status of the proof
        uint256 submissionTimestamp;// Timestamp of submission
        uint256 reviewTimestamp;    // Timestamp of last review
    }

    struct ParameterChangeProposal {
        uint256 id;                 // Unique ID of the proposal
        address proposer;           // Address that proposed the change
        string paramKey;            // Key of the parameter to change (e.g., "skillVotingPeriod")
        bytes newValue;             // New value for the parameter, ABI-encoded
        uint256 yesVotes;           // Number of 'yes' votes
        uint256 noVotes;            // Number of 'no' votes
        uint256 expiration;         // Timestamp when voting ends
        bool executed;              // True if the proposal has been executed
        bool canceled;              // True if the proposal has been canceled
    }

    enum DisputeOutcome {
        Pending,  // Dispute is ongoing
        Revoked,  // Attestation was revoked
        Upheld    // Attestation was upheld
    }

    struct Dispute {
        uint256 id;                 // Unique ID of the dispute
        address disputer;           // Address that initiated the dispute
        uint256 attestationTokenId; // The SBT token ID being disputed
        string reason;              // Reason for the dispute
        uint256 votesForRevoke;     // Votes to revoke the attestation
        uint256 votesAgainstRevoke; // Votes to uphold the attestation
        uint256 expiration;         // Timestamp when voting ends
        bool resolved;              // True if the dispute has been resolved
        DisputeOutcome outcome;     // Final outcome of the dispute
    }

    // --- Mappings ---

    mapping(uint256 => Attestation) private _attestations; // tokenId => Attestation data
    // Tracks specific types of attestations per user (recipient => type => refId => count)
    mapping(address => mapping(AttestationType => mapping(uint256 => uint256))) private _sbtTypeCount;
    mapping(AttestationType => mapping(address => bool)) private _attesterRoles; // type => attester address => canAttest
    mapping(uint256 => SkillData) private _skills; // skillId => SkillData
    mapping(uint256 => SkillProposal) private _skillProposals; // proposalId => SkillProposal
    mapping(uint256 => mapping(address => bool)) private _skillProposalVotes; // proposalId => voter address => hasVoted
    mapping(AttestationType => uint256) private _reputationWeights; // AttestationType => weight
    mapping(uint256 => ContributionProof) private _contributionProofs; // proofId => ContributionProof
    mapping(uint256 => ParameterChangeProposal) private _parameterChangeProposals; // proposalId => ParameterChangeProposal
    mapping(uint256 => mapping(address => bool)) private _parameterChangeProposalVotes; // proposalId => voter address => hasVoted
    mapping(uint256 => Dispute) private _disputes; // disputeId => Dispute
    mapping(uint256 => mapping(address => bool)) private _disputeVotes; // disputeId => voter address => hasVoted

    // --- Configuration Parameters (Governance Controlled) ---
    uint256 public skillProposalVotingPeriod = 7 days; // Duration for skill proposal voting
    uint256 public parameterChangeVotingPeriod = 7 days; // Duration for parameter change voting
    uint256 public disputeVotingPeriod = 5 days; // Duration for dispute voting
    uint256 public minVotesForSkillProposal = 3; // Minimum total votes required for a skill proposal to pass
    uint256 public minVotesForParameterChange = 5; // Minimum total votes required for a parameter change to pass
    uint256 public minVotesForDispute = 3; // Minimum total votes required for a dispute to resolve
    uint256 public minReputationToProposeSkill = 100; // Minimum reputation needed to propose a skill or initiate a dispute/param change
    uint256 public minReputationToVote = 50; // Minimum reputation needed to cast a vote in governance/disputes

    // --- Events ---

    event AttestationIssued(uint256 indexed tokenId, address indexed recipient, AttestationType indexed attestationType, uint256 refId, address attester, string metadataURI);
    event AttestationRevoked(uint256 indexed tokenId, address indexed recipient, address revoker);
    event SkillProposed(uint256 indexed proposalId, string name, address indexed proposer);
    event SkillProposalVoted(uint256 indexed proposalId, address indexed voter, bool _for);
    event SkillProposalExecuted(uint256 indexed proposalId, uint256 indexed skillId);
    event ReputationWeightUpdated(AttestationType indexed _type, uint256 newWeight);
    event ContributionProofSubmitted(uint256 indexed proofId, address indexed submitter, uint256 indexed skillId, string contributionHash);
    event ContributionProofReviewed(uint256 indexed proofId, address indexed reviewer, ProofStatus newStatus);
    event ContributionProofFinalized(uint256 indexed proofId, uint256 indexed tokenId);
    event ParameterChangeProposed(uint256 indexed proposalId, string paramKey, bytes newValue, address indexed proposer);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool _for);
    event ParameterChangeExecuted(uint256 indexed proposalId, string paramKey);
    event AttesterRoleUpdated(AttestationType indexed _type, address indexed attester, bool canAttest);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed attestationTokenId, address indexed disputer);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool _forRevoke);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed attestationTokenId, DisputeOutcome outcome);

    // --- Constructor ---

    constructor() ERC721("NexusAttestationSBT", "NXSBT") Ownable(msg.sender) {
        // Initialize default reputation weights for different attestation types
        _reputationWeights[AttestationType.Skill] = 10;
        _reputationWeights[AttestationType.Achievement] = 15;
        _reputationWeights[AttestationType.Contribution] = 20;
        _reputationWeights[AttestationType.Role] = 25;

        // Grant the contract owner initial attester roles for all types
        // In a production system, these would likely be managed by a separate DAO or trusted entities
        _attesterRoles[AttestationType.Skill][msg.sender] = true;
        _attesterRoles[AttestationType.Achievement][msg.sender] = true;
        _attesterRoles[AttestationType.Contribution][msg.sender] = true;
        _attesterRoles[AttestationType.Role][msg.sender] = true;
    }

    // --- Modifiers ---

    /// @dev Restricts access to functions to addresses explicitly granted the attester role for a specific type.
    modifier onlyAttester(AttestationType _type) {
        require(_attesterRoles[_type][msg.sender], "NAP: Caller is not an authorized attester for this type.");
        _;
    }

    /// @dev Restricts access to functions to the actual recipient of a specific SBT.
    modifier onlySBTRecipient(uint256 tokenId) {
        require(_attestations[tokenId].recipient == msg.sender, "NAP: Caller is not the recipient of this SBT.");
        _;
    }

    /// @dev Restricts access to governance-related functions. In this example, it's simplified to `onlyOwner`.
    ///      In a full DAO, this would integrate with a separate governance module or require a specific 'governor' role SBT.
    modifier onlyGovernance() {
        require(owner() == msg.sender, "NAP: Caller is not authorized for governance operations.");
        _;
    }

    /// @dev Restricts access to functions to users who meet a minimum reputation score.
    modifier hasMinReputation(uint256 minRep) {
        require(calculateReputationScore(msg.sender) >= minRep, "NAP: Insufficient reputation.");
        _;
    }

    // --- I. Core SBT Management ---

    /// @dev Internal function to mint a new SBT. This overrides ERC721's _mint to ensure non-transferability.
    /// @param recipient The address that will receive the SBT.
    /// @param _type The type of attestation (Skill, Achievement, etc.).
    /// @param refId A reference ID specific to the attestation type (e.g., skillId, achievementId).
    /// @param metadataURI URI pointing to off-chain metadata for the SBT.
    /// @return tokenId The ID of the newly minted SBT.
    function _attest(
        address recipient,
        AttestationType _type,
        uint256 refId,
        string memory metadataURI
    ) internal returns (uint256 tokenId) {
        require(recipient != address(0), "NAP: Cannot attest to zero address");

        tokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _attestations[tokenId] = Attestation({
            attester: msg.sender,
            recipient: recipient,
            attestationType: _type,
            refId: refId,
            timestamp: block.timestamp,
            metadataURI: metadataURI,
            isRevoked: false
        });

        _safeMint(recipient, tokenId); // Mints the ERC721 token
        _sbtTypeCount[recipient][_type][refId]++; // Increments specific SBT type count for the recipient

        emit AttestationIssued(tokenId, recipient, _type, refId, msg.sender, metadataURI);
    }

    /// @notice Issues a Skill SBT to a recipient. Only callable by an authorized attester for `Skill` type.
    /// @param recipient The address to receive the Skill SBT.
    /// @param skillId The ID of the skill being attested.
    /// @param metadataURI URI for the skill's metadata.
    function attestSkill(address recipient, uint256 skillId, string memory metadataURI) external onlyAttester(AttestationType.Skill) {
        require(_skills[skillId].exists, "NAP: Skill does not exist.");
        // An attester can attest to a skill. Prerequisites can be an informal guideline for the attester,
        // or enforced through custom attester-specific logic in a more complex system.
        _attest(recipient, AttestationType.Skill, skillId, metadataURI);
    }

    /// @notice Issues an Achievement SBT to a recipient. Only callable by an authorized attester for `Achievement` type.
    /// @param recipient The address to receive the Achievement SBT.
    /// @param achievementId The ID of the achievement being attested.
    /// @param metadataURI URI for the achievement's metadata.
    function attestAchievement(address recipient, uint256 achievementId, string memory metadataURI) external onlyAttester(AttestationType.Achievement) {
        _attest(recipient, AttestationType.Achievement, achievementId, metadataURI);
    }

    /// @notice Issues a Contribution SBT to a recipient. Only callable by an authorized attester for `Contribution` type.
    /// @param recipient The address to receive the Contribution SBT.
    /// @param contributionId The ID of the contribution being attested (e.g., from `_contributionProofs`).
    /// @param metadataURI URI for the contribution's metadata.
    function attestContribution(address recipient, uint256 contributionId, string memory metadataURI) external onlyAttester(AttestationType.Contribution) {
        _attest(recipient, AttestationType.Contribution, contributionId, metadataURI);
    }

    /// @notice Issues a Role SBT to a recipient. Only callable by an authorized attester for `Role` type.
    /// @param recipient The address to receive the Role SBT.
    /// @param roleId The ID of the role being attested.
    /// @param metadataURI URI for the role's metadata.
    function attestRole(address recipient, uint256 roleId, string memory metadataURI) external onlyAttester(AttestationType.Role) {
        _attest(recipient, AttestationType.Role, roleId, metadataURI);
    }

    /// @notice Allows the recipient of an SBT to self-revoke it. This action burns the token.
    /// @param tokenId The ID of the SBT to revoke.
    function revokeAttestation(uint256 tokenId) external onlySBTRecipient(tokenId) {
        Attestation storage attestation = _attestations[tokenId];
        require(!attestation.isRevoked, "NAP: Attestation already revoked.");

        attestation.isRevoked = true;
        _sbtTypeCount[attestation.recipient][attestation.attestationType][attestation.refId]--; // Decrement the count
        _burn(tokenId); // Burn the token from the ERC721 registry

        emit AttestationRevoked(tokenId, attestation.recipient, msg.sender);
    }

    /// @notice Returns the total number of non-revoked SBTs held by an address.
    /// @param owner The address to query.
    /// @return The total count of SBTs.
    function getSBTCount(address owner) external view returns (uint256) {
        return balanceOf(owner); // ERC721's balanceOf tracks non-burned tokens
    }

    /// @notice Checks if an address holds a specific type of SBT with a reference ID.
    /// @param owner The address to query.
    /// @param _type The type of attestation.
    /// @param refId The reference ID (e.g., skillId).
    /// @return True if the address holds at least one such SBT, false otherwise.
    function hasSBT(address owner, AttestationType _type, uint256 refId) external view returns (bool) {
        return _sbtTypeCount[owner][_type][refId] > 0;
    }

    /// @notice Retrieves details of a specific attestation by its token ID.
    /// @param tokenId The ID of the SBT.
    /// @return Attestation struct containing all details.
    function getAttestation(uint256 tokenId) external view returns (Attestation memory) {
        require(_exists(tokenId), "NAP: SBT does not exist."); // Check if ERC721 token exists
        return _attestations[tokenId];
    }

    /// @dev Overrides ERC721's _beforeTokenTransfer to explicitly prevent any transfers between non-zero addresses.
    ///      Allows minting (from address(0)) and burning (to address(0)).
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (from != address(0) && to != address(0)) {
            revert("NAP: Soulbound tokens are non-transferable.");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // --- II. Skill Tree Management ---

    /// @notice Proposes a new skill to be added to the skill tree. Requires minimum reputation.
    /// @param name The name of the new skill.
    /// @param descriptionURI URI pointing to the skill's detailed description.
    /// @param prerequisites An array of skill IDs that are prerequisites for this new skill.
    /// @return The ID of the new skill proposal.
    function proposeSkill(
        string memory name,
        string memory descriptionURI,
        uint256[] memory prerequisites
    ) external hasMinReputation(minReputationToProposeSkill) returns (uint256) {
        // Ensure all proposed prerequisites actually exist as skills
        for (uint256 i = 0; i < prerequisites.length; i++) {
            require(_skills[prerequisites[i]].exists, "NAP: Prerequisite skill does not exist.");
        }

        uint256 proposalId = _nextSkillProposalId.current();
        _nextSkillProposalId.increment();

        _skillProposals[proposalId] = SkillProposal({
            id: proposalId,
            proposer: msg.sender,
            name: name,
            descriptionURI: descriptionURI,
            prerequisites: prerequisites,
            yesVotes: 0,
            noVotes: 0,
            expiration: block.timestamp + skillProposalVotingPeriod,
            executed: false,
            canceled: false
        });

        emit SkillProposed(proposalId, name, msg.sender);
        return proposalId;
    }

    /// @notice Allows a user with sufficient reputation to vote on a skill proposal.
    /// @param proposalId The ID of the skill proposal.
    /// @param _for True for a 'yes' vote, false for a 'no' vote.
    function voteOnSkillProposal(uint256 proposalId, bool _for) external hasMinReputation(minReputationToVote) {
        SkillProposal storage proposal = _skillProposals[proposalId];
        require(proposal.proposer != address(0), "NAP: Skill proposal does not exist."); // Check if proposal exists
        require(block.timestamp < proposal.expiration, "NAP: Skill proposal voting period ended.");
        require(!proposal.executed, "NAP: Skill proposal already executed.");
        require(!proposal.canceled, "NAP: Skill proposal canceled.");
        require(!_skillProposalVotes[proposalId][msg.sender], "NAP: Already voted on this skill proposal."); // Prevent double voting

        _skillProposalVotes[proposalId][msg.sender] = true;
        if (_for) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit SkillProposalVoted(proposalId, msg.sender, _for);
    }

    /// @notice Executes a skill proposal if it has passed its voting period and met approval criteria (more yes votes than no, minimum total votes).
    /// @param proposalId The ID of the skill proposal.
    function executeSkillProposal(uint256 proposalId) external {
        SkillProposal storage proposal = _skillProposals[proposalId];
        require(proposal.proposer != address(0), "NAP: Skill proposal does not exist.");
        require(block.timestamp >= proposal.expiration, "NAP: Skill proposal voting period not ended.");
        require(!proposal.executed, "NAP: Skill proposal already executed.");
        require(!proposal.canceled, "NAP: Skill proposal canceled.");
        require(proposal.yesVotes > proposal.noVotes, "NAP: Skill proposal did not pass (more yes votes needed).");
        require(proposal.yesVotes + proposal.noVotes >= minVotesForSkillProposal, "NAP: Not enough total votes for skill proposal.");

        uint256 skillId = _nextSkillId.current();
        _nextSkillId.increment();

        _skills[skillId] = SkillData({
            id: skillId,
            name: proposal.name,
            descriptionURI: proposal.descriptionURI,
            prerequisites: proposal.prerequisites,
            exists: true
        });

        proposal.executed = true; // Mark proposal as executed

        emit SkillProposalExecuted(proposalId, skillId);
    }

    /// @notice Returns the prerequisites (skill IDs) for a given skill.
    /// @param skillId The ID of the skill.
    /// @return An array of skill IDs that are prerequisites.
    function getSkillPrerequisites(uint256 skillId) external view returns (uint256[] memory) {
        require(_skills[skillId].exists, "NAP: Skill does not exist.");
        return _skills[skillId].prerequisites;
    }

    /// @notice Checks if an account meets all the prerequisites for a specific skill by holding the necessary Skill SBTs.
    /// @param account The address to check.
    /// @param skillId The ID of the skill.
    /// @return True if all prerequisites are met, false otherwise.
    function isSkillPrerequisitesMet(address account, uint256 skillId) public view returns (bool) {
        require(_skills[skillId].exists, "NAP: Skill does not exist.");
        uint256[] memory prerequisites = _skills[skillId].prerequisites;
        for (uint256 i = 0; i < prerequisites.length; i++) {
            // Check if the account has the prerequisite skill SBT
            if (_sbtTypeCount[account][AttestationType.Skill][prerequisites[i]] == 0) {
                return false; // Missing a prerequisite skill
            }
        }
        return true;
    }

    // --- III. Reputation System ---

    /// @notice Calculates an account's current reputation score based on their non-revoked SBTs and their assigned weights.
    /// @param account The address for which to calculate the score.
    /// @return The calculated reputation score.
    /// @dev This function iterates through all tokens owned by an account, which can be inefficient for a very large number of tokens.
    ///      For a highly scalable system, an off-chain indexer or a cached on-chain score updated via hooks would be more suitable.
    function calculateReputationScore(address account) public view returns (uint256) {
        uint256 score = 0;
        uint256 totalTokens = balanceOf(account); // Get the number of non-burned tokens owned by the account
        for (uint256 i = 0; i < totalTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(account, i); // Get tokenId by index (from ERC721 enumerable extension)
            Attestation storage attestation = _attestations[tokenId];
            // Only consider non-revoked attestations for reputation
            if (!attestation.isRevoked) {
                score += _reputationWeights[attestation.attestationType];
                // More complex logic could be added here, e.g., decaying reputation based on attestation age.
            }
        }
        return score;
    }

    /// @notice Retrieves the current reputation weight for a specific attestation type.
    /// @param _type The type of attestation.
    /// @return The weight assigned to that attestation type.
    function getReputationWeight(AttestationType _type) external view returns (uint256) {
        return _reputationWeights[_type];
    }

    /// @notice Allows governance to update the reputation weight of an SBT type.
    /// @param _type The attestation type to update.
    /// @param newWeight The new weight to assign.
    function updateReputationWeight(AttestationType _type, uint256 newWeight) external onlyGovernance {
        _reputationWeights[_type] = newWeight;
        emit ReputationWeightUpdated(_type, newWeight);
    }

    // --- IV. On-Chain Proofs of Contribution (PoC) ---

    /// @notice Submits a hash of an off-chain proof of contribution, initiating a review process.
    ///         Requires the submitter to have met the prerequisites for the target skill.
    /// @param contributionHash A unique identifier for the off-chain proof (e.g., IPFS CID, commit hash).
    /// @param skillId The skill this contribution aims to prove attainment of.
    /// @return The ID of the created contribution proof.
    function submitContributionProof(string memory contributionHash, uint256 skillId) external returns (uint256) {
        require(_skills[skillId].exists, "NAP: Target skill does not exist.");
        require(isSkillPrerequisitesMet(msg.sender, skillId), "NAP: Prerequisites not met for skill contribution proof."); // Enforce prerequisites

        uint256 proofId = _nextContributionProofId.current();
        _nextContributionProofId.increment();

        _contributionProofs[proofId] = ContributionProof({
            id: proofId,
            submitter: msg.sender,
            contributionHash: contributionHash,
            skillId: skillId,
            reviewer: address(0), // No reviewer assigned yet, initially empty
            status: ProofStatus.Pending,
            submissionTimestamp: block.timestamp,
            reviewTimestamp: 0
        });

        emit ContributionProofSubmitted(proofId, msg.sender, skillId, contributionHash);
        return proofId;
    }

    /// @notice Allows an authorized attester (e.g., a "Core Contributor" role holder or elected reviewer) to review a submitted proof.
    /// @param proofId The ID of the contribution proof to review.
    /// @param verified True if the proof is verified, false if rejected.
    function reviewContributionProof(uint256 proofId, bool verified) external onlyAttester(AttestationType.Contribution) {
        ContributionProof storage proof = _contributionProofs[proofId];
        require(proof.submitter != address(0), "NAP: Contribution proof does not exist.");
        require(proof.status == ProofStatus.Pending, "NAP: Contribution proof already reviewed or finalized."); // Can only review pending proofs

        proof.reviewer = msg.sender;
        proof.status = verified ? ProofStatus.Reviewed : ProofStatus.Rejected;
        proof.reviewTimestamp = block.timestamp;

        emit ContributionProofReviewed(proofId, msg.sender, proof.status);
    }

    /// @notice Finalizes a verified contribution proof, minting a Contribution SBT to the submitter.
    ///         This action is typically performed by a governance entity or a highly trusted role.
    /// @param proofId The ID of the contribution proof to finalize.
    function finalizeContributionProof(uint256 proofId) external onlyGovernance {
        ContributionProof storage proof = _contributionProofs[proofId];
        require(proof.submitter != address(0), "NAP: Contribution proof does not exist.");
        require(proof.status == ProofStatus.Reviewed, "NAP: Contribution proof not yet reviewed or not verified."); // Must be reviewed and verified

        // Mint a Contribution SBT to the original submitter of the proof
        uint256 tokenId = _attest(
            proof.submitter,
            AttestationType.Contribution,
            proof.id, // The proofId itself can serve as the refId for the Contribution SBT
            string(abi.encodePacked("ipfs://", proof.contributionHash)) // Example metadata URI construction
        );

        proof.status = ProofStatus.Verified; // Mark the proof as fully verified/finalized
        emit ContributionProofFinalized(proofId, tokenId);
    }

    // --- V. Governance & System Parameters ---

    /// @notice Proposes a change to a system parameter. Requires minimum reputation.
    /// @param paramKey The string key of the parameter to change (e.g., "skillProposalVotingPeriod").
    /// @param newValue The new value for the parameter, ABI-encoded as bytes.
    /// @return The ID of the new parameter change proposal.
    function proposeParameterChange(string memory paramKey, bytes memory newValue) external hasMinReputation(minReputationToProposeSkill) returns (uint256) {
        uint256 proposalId = _nextParameterChangeProposalId.current();
        _nextParameterChangeProposalId.increment();

        _parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            proposer: msg.sender,
            paramKey: paramKey,
            newValue: newValue,
            yesVotes: 0,
            noVotes: 0,
            expiration: block.timestamp + parameterChangeVotingPeriod,
            executed: false,
            canceled: false
        });

        emit ParameterChangeProposed(proposalId, paramKey, newValue, msg.sender);
        return proposalId;
    }

    /// @notice Allows a user with sufficient reputation to vote on a parameter change proposal.
    /// @param proposalId The ID of the parameter change proposal.
    /// @param _for True for a 'yes' vote, false for a 'no' vote.
    function voteOnParameterChange(uint256 proposalId, bool _for) external hasMinReputation(minReputationToVote) {
        ParameterChangeProposal storage proposal = _parameterChangeProposals[proposalId];
        require(proposal.proposer != address(0), "NAP: Parameter change proposal does not exist.");
        require(block.timestamp < proposal.expiration, "NAP: Parameter change voting period ended.");
        require(!proposal.executed, "NAP: Parameter change proposal already executed.");
        require(!proposal.canceled, "NAP: Parameter change proposal canceled.");
        require(!_parameterChangeProposalVotes[proposalId][msg.sender], "NAP: Already voted on this parameter change proposal.");

        _parameterChangeProposalVotes[proposalId][msg.sender] = true;
        if (_for) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit ParameterChangeVoted(proposalId, msg.sender, _for);
    }

    /// @notice Executes a parameter change proposal if it has passed its voting period and met approval criteria.
    ///         Only callable by governance.
    /// @param proposalId The ID of the parameter change proposal.
    function executeParameterChange(uint256 proposalId) external onlyGovernance {
        ParameterChangeProposal storage proposal = _parameterChangeProposals[proposalId];
        require(proposal.proposer != address(0), "NAP: Parameter change proposal does not exist.");
        require(block.timestamp >= proposal.expiration, "NAP: Parameter change voting period not ended.");
        require(!proposal.executed, "NAP: Parameter change proposal already executed.");
        require(!proposal.canceled, "NAP: Parameter change proposal canceled.");
        require(proposal.yesVotes > proposal.noVotes, "NAP: Parameter change proposal did not pass.");
        require(proposal.yesVotes + proposal.noVotes >= minVotesForParameterChange, "NAP: Not enough total votes for parameter change.");

        bytes memory newValue = proposal.newValue;
        // Apply the parameter change based on the paramKey
        // Using keccak256 for string comparison is a common pattern in Solidity for efficiency over direct string comparison
        if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("skillProposalVotingPeriod"))) {
            skillProposalVotingPeriod = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("parameterChangeVotingPeriod"))) {
            parameterChangeVotingPeriod = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("disputeVotingPeriod"))) {
            disputeVotingPeriod = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minVotesForSkillProposal"))) {
            minVotesForSkillProposal = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minVotesForParameterChange"))) {
            minVotesForParameterChange = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minVotesForDispute"))) {
            minVotesForDispute = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minReputationToProposeSkill"))) {
            minReputationToProposeSkill = abi.decode(newValue, (uint256));
        } else if (keccak256(abi.encodePacked(proposal.paramKey)) == keccak256(abi.encodePacked("minReputationToVote"))) {
            minReputationToVote = abi.decode(newValue, (uint256));
        } else {
            revert("NAP: Unknown parameter key.");
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(proposalId, proposal.paramKey);
    }

    /// @notice Grants or revokes an address's ability to attest specific SBT types. Only callable by governance.
    /// @param _type The attestation type for which to set the role.
    /// @param attester The address to grant/revoke the role.
    /// @param canAttest True to grant, false to revoke.
    function setAttesterRole(AttestationType _type, address attester, bool canAttest) external onlyGovernance {
        _attesterRoles[_type][attester] = canAttest;
        emit AttesterRoleUpdated(_type, attester, canAttest);
    }

    // --- VI. Dispute Resolution ---

    /// @notice Initiates a dispute against an existing attestation. Requires minimum reputation.
    /// @param attestationTokenId The ID of the SBT to dispute.
    /// @param reason A string explaining the reason for the dispute.
    /// @return The ID of the new dispute.
    function initiateDispute(uint256 attestationTokenId, string memory reason) external hasMinReputation(minReputationToProposeSkill) returns (uint256) {
        Attestation storage attestation = _attestations[attestationTokenId];
        require(attestation.recipient != address(0), "NAP: Attestation does not exist.");
        require(!attestation.isRevoked, "NAP: Attestation already revoked.");

        // Check for active disputes on the same attestation
        // (Simplified check for the most recent dispute. A more robust system would check all un-resolved disputes.)
        uint256 currentDisputeId = _nextDisputeId.current();
        if (currentDisputeId > 0 && _disputes[currentDisputeId - 1].attestationTokenId == attestationTokenId && !_disputes[currentDisputeId - 1].resolved) {
            revert("NAP: An active dispute already exists for this attestation.");
        }

        uint256 disputeId = _nextDisputeId.current();
        _nextDisputeId.increment();

        _disputes[disputeId] = Dispute({
            id: disputeId,
            disputer: msg.sender,
            attestationTokenId: attestationTokenId,
            reason: reason,
            votesForRevoke: 0,
            votesAgainstRevoke: 0,
            expiration: block.timestamp + disputeVotingPeriod,
            resolved: false,
            outcome: DisputeOutcome.Pending
        });

        emit DisputeInitiated(disputeId, attestationTokenId, msg.sender);
        return disputeId;
    }

    /// @notice Allows a user with sufficient reputation to vote on the outcome of a dispute.
    /// @param disputeId The ID of the dispute.
    /// @param _forRevoke True to vote for revoking the attestation, false to vote against revocation (uphold).
    function voteOnDispute(uint256 disputeId, bool _forRevoke) external hasMinReputation(minReputationToVote) {
        Dispute storage dispute = _disputes[disputeId];
        require(dispute.disputer != address(0), "NAP: Dispute does not exist.");
        require(block.timestamp < dispute.expiration, "NAP: Dispute voting period ended.");
        require(!dispute.resolved, "NAP: Dispute already resolved.");
        require(!_disputeVotes[disputeId][msg.sender], "NAP: Already voted on this dispute."); // Prevent double voting

        _disputeVotes[disputeId][msg.sender] = true;
        if (_forRevoke) {
            dispute.votesForRevoke++;
        } else {
            dispute.votesAgainstRevoke++;
        }

        emit DisputeVoted(disputeId, msg.sender, _forRevoke);
    }

    /// @notice Finalizes a dispute based on the voting outcome, potentially revoking an SBT. Only callable by governance.
    /// @param disputeId The ID of the dispute to resolve.
    function resolveDispute(uint256 disputeId) external onlyGovernance {
        Dispute storage dispute = _disputes[disputeId];
        require(dispute.disputer != address(0), "NAP: Dispute does not exist.");
        require(block.timestamp >= dispute.expiration, "NAP: Dispute voting period not ended.");
        require(!dispute.resolved, "NAP: Dispute already resolved.");
        require(dispute.votesForRevoke + dispute.votesAgainstRevoke >= minVotesForDispute, "NAP: Not enough total votes for dispute.");

        dispute.resolved = true; // Mark the dispute as resolved

        if (dispute.votesForRevoke > dispute.votesAgainstRevoke) {
            // If votes for revocation are greater, revoke the attestation
            Attestation storage attestation = _attestations[dispute.attestationTokenId];
            require(!attestation.isRevoked, "NAP: Attestation already revoked by other means."); // Should ideally not happen if checks are strict
            attestation.isRevoked = true;
            _sbtTypeCount[attestation.recipient][attestation.attestationType][attestation.refId]--; // Decrement count
            _burn(dispute.attestationTokenId); // Burn the SBT
            dispute.outcome = DisputeOutcome.Revoked;
            emit AttestationRevoked(dispute.attestationTokenId, attestation.recipient, address(this)); // Revoked by contract/governance
        } else {
            // Otherwise, uphold the attestation
            dispute.outcome = DisputeOutcome.Upheld;
        }

        emit DisputeResolved(disputeId, dispute.attestationTokenId, dispute.outcome);
    }
}

```