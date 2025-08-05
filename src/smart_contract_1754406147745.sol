Here's a Solidity smart contract named `HyperCertificates` that embodies several advanced, creative, and trendy concepts. It focuses on decentralized identity, dynamic reputation, verifiable skill attestations, and micro-DAO formation, aiming to be unique by combining these elements with a time-decaying mechanism for skill relevance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For task force rewards

/**
 * @title HyperCertificates
 * @dev A protocol for issuing, managing, and leveraging dynamic, time-decaying, skill-based NFTs called "HyperCertificates" (HCs).
 *      These HCs form the basis of a user's on-chain expertise and reputation score, enable verifiable skill attestations,
 *      and facilitate the formation of specialized "Task Forces" for collaborative work.
 */

// --- OUTLINE AND FUNCTION SUMMARY ---
//
// This smart contract introduces a novel system for on-chain identity and reputation.
// It leverages Non-Fungible Tokens (NFTs) not just as static collectibles, but as dynamic,
// time-sensitive representations of an individual's validated skills, contributions, and achievements.
// The core innovation lies in the "HyperCertificate" (HC) concept, which combines:
//
// 1.  **Dynamic Reputation:** Each HC possesses a 'weight' that decays over time, encouraging continuous
//     learning and contribution to maintain relevance. A user's overall "Expertise Score" is a weighted
//     aggregate of their owned HCs, considering decay, peer attestations, and the reputation of attestors.
// 2.  **Verifiable Attestations:** Users with established reputation can issue and update attestations
//     to other HCs, forming a "skill graph" that reinforces validity. A challenge mechanism allows for
//     community-driven dispute resolution.
// 3.  **Task Forces (Micro-DAOs):** The system facilitates the creation of temporary, goal-oriented
//     Decentralized Autonomous Organizations (DAOs) where membership is determined by specific HC
//     combinations and expertise levels. This enables decentralized coordination for projects,
//     research, or public goods funding.
// 4.  **Proof of Work Linking:** HCs can be linked to verifiable off-chain proofs of work (e.g., cryptographic
//     hashes of code, verifiable computation results) to enhance credibility and provide concrete evidence of skills.
//
// Total Custom Functions: 26 (excluding standard inherited ERC-721 functions like `balanceOf`, `ownerOf`, etc.)
//
// I. Core HyperCertificate Management & ERC-721 Interface:
//    This section defines the fundamental structure and lifecycle of HyperCertificates,
//    extending the ERC-721 standard with advanced properties like soulbound and validity states.
//    1.  `constructor`: Initializes the contract with basic ERC-721, Ownable, and Pausable settings.
//    2.  `issueHyperCertificate`: Mints a new HyperCertificate (HC) to a recipient, specifying skill, validity
//        period, an option for it to be 'soulbound' (non-transferable), and initial skill tags.
//    3.  `revokeHyperCertificate`: Allows the original issuer to invalidate an existing HyperCertificate,
//        e.g., if the associated skill or achievement is no longer valid or was misrepresented.
//    4.  `getHyperCertificateDetails`: Retrieves all structured data associated with a given HyperCertificate ID.
//    5.  `updateHyperCertificateMetadataURI`: Allows the owner of an HC to update its off-chain metadata URI,
//        enabling dynamic updates to skill descriptions or associated proofs.
//    6.  `_beforeTokenTransfer`: Internal ERC-721 hook override to enforce the 'soulbound' property
//        for specific HyperCertificates, making them non-transferable if flagged.
//
// II. Attestation & Dynamic Reputation System:
//     This section introduces a mechanism for peer-to-peer attestation of HCs, contributing to a dynamic,
//     time-decaying reputation score for users, and a challenge system for validity.
//    7.  `attestToHyperCertificate`: Allows a user with a sufficiently high expertise score to attest to the
//        validity or impact of another HyperCertificate, boosting its reputational weight.
//    8.  `updateAttestationValidity`: Enables an attestor to update their previous attestation,
//        e.g., to strengthen or weaken their endorsement based on new information.
//    9.  `challengeAttestation`: Initiates a formal challenge against the validity or accuracy of a specific HyperCertificate.
//    10. `voteOnChallenge`: Allows designated arbiters (or the community with sufficient reputation) to cast votes on an active challenge.
//    11. `resolveChallenge`: Finalizes a challenge based on voting outcomes, potentially leading to the revocation of the challenged HC.
//    12. `calculateHyperCertificateWeight`: Computes the current dynamic reputational weight of a single HC,
//        factoring in its decay over time and the collective weight of its attestations.
//    13. `getUserExpertiseScore`: Aggregates the weighted scores of all HyperCertificates owned by a user
//        to calculate their overall dynamic expertise and reputation score within the system.
//    14. `setAttestorMinScore`: An admin function to set the minimum expertise score required for users
//        to be eligible to issue new HCs or attest to existing ones.
//
// III. Task Force (Micro-DAO) Management:
//      This section facilitates the formation and management of temporary, skill-specific decentralized
//      autonomous organizations (Task Forces) for collaborative project execution.
//    15. `proposeTaskForce`: Allows a user to propose the creation of a new Task Force, specifying the mission,
//        duration, reward, and the required HyperCertificate types/levels for membership.
//    16. `joinTaskForce`: Enables eligible users (those holding the specified HCs) to join an active Task Force.
//    17. `voteOnTaskForceDecision`: Allows members of a Task Force to vote on internal proposals or decisions relevant to their mission.
//    18. `completeTaskForceMission`: Marks a Task Force's mission as completed, triggering the potential
//        release of associated rewards to its members.
//    19. `claimTaskForceRewards`: Allows individual Task Force members to claim their share of rewards
//        allocated upon mission completion.
//    20. `submitProofOfWorkForHC`: Allows an HC owner to link their HyperCertificate to an external
//        cryptographic proof of work (e.g., a Git commit hash, IPFS CID of verifiable computation result),
//        enhancing the HC's credibility.
//
// IV. Admin & Utility Functions:
//     General administrative and view functions to manage protocol parameters and retrieve data.
//    21. `setDecayRate`: Admin function to adjust the global time-decay rate for HyperCertificates,
//        influencing how quickly their reputational weight diminishes.
//    22. `setChallengePeriod`: Admin function to set the duration (in seconds) for challenge voting.
//    23. `setTaskForceRewardPool`: Admin function to set the address of a designated reward pool
//        contract from which Task Force members can claim rewards.
//    24. `setHyperCertificateCategory`: Allows the issuer of an HC to assign a broad category (e.g., "Tech", "Arts")
//        to better organize and filter HyperCertificates.
//    25. `addSkillTagToHC`: Allows the owner of an HC to add descriptive skill tags (e.g., "Solidity", "AI/ML")
//        to their certificate for more granular classification.
//    26. `getHyperCertificatesBySkillTag`: Retrieves a list of HyperCertificate IDs filtered by a specific skill tag.


contract HyperCertificates is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    // --- Structures ---

    // Represents a HyperCertificate
    struct HyperCertificate {
        address recipient;
        address issuer;
        string skillName;
        string skillCategory; // e.g., "Development", "Design", "Community"
        string metadataURI;
        uint64 issuedTimestamp;
        uint64 expirationTimestamp; // 0 for no expiration means it never expires naturally
        bool isSoulbound; // If true, cannot be transferred
        bool isValid; // Can be invalidated by revocation or challenge
        string[] skillTags; // Additional granular tags for searching and filtering
    }

    // Represents an attestation made by one HC holder towards another HC
    struct Attestation {
        address attestor; // Address of the attestor
        uint256 attestorHCId; // The ID of the HyperCertificate used by the attestor to attest
        uint64 timestamp;
        string context; // Short description of why the attestation is made
        uint256 weightBoost; // The 'strength' of this attestation, proportional to attestor's score at time of attestation
    }

    // Represents a challenge against a HyperCertificate's validity
    struct Challenge {
        address challenger;
        uint64 startedTimestamp;
        uint64 endTimestamp;
        bool resolved;
        mapping(address => bool) hasVoted; // Voter address => true
        uint256 votesForRevoke;
        uint256 votesAgainstRevoke;
        address[] arbiters; // Addresses of designated arbiters for this challenge (can be empty if open to all attestors)
    }

    // Represents a Task Force (Micro-DAO) for collaborative work
    struct TaskForce {
        string name;
        string missionDescription;
        uint64 creationTimestamp;
        uint64 deadlineTimestamp;
        bool missionCompleted;
        address proposer;
        uint256 rewardAmount; // Total reward for the task force (if any)
        address rewardToken; // Address of the reward token (ERC20)
        mapping(address => bool) isMember; // Member address => true
        address[] members; // List of current members
        mapping(address => bool) hasClaimedRewards; // Member address => true if rewards claimed

        // Required HCs for eligibility: skillName => minScoreRequired
        mapping(string => uint256) requiredHyperCertificates;
        string[] requiredSkillNamesList; // Array to iterate through required skills

        // Internal voting mechanism for task force decisions
        uint256 proposalCounter;
        mapping(uint256 => TaskForceProposal) proposals;
    }

    // Represents an internal proposal within a Task Force
    struct TaskForceProposal {
        string description;
        bool executed;
        uint64 voteEndTime;
        mapping(address => bool) hasVoted;
        uint256 votesYes;
        uint256 votesNo;
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for unique HyperCertificate IDs

    // Core HC data storage
    mapping(uint252 => HyperCertificate) public hyperCertificates; // tokenId to HC details
    mapping(uint252 => mapping(address => Attestation)) private _hcAttestations; // HC ID => Attestor Address => Attestation
    mapping(uint252 => address[]) private _attestorsForHC; // List of attestor addresses for a given HC ID (for iteration)

    // Challenge related data
    mapping(uint252 => Challenge) public activeChallenges; // Challenged HC ID => Challenge details
    mapping(uint252 => bool) public isChallenged; // Challenged HC ID => true if currently under challenge

    // Task Force related data
    uint252 public nextTaskForceId; // Counter for unique Task Force IDs
    mapping(uint252 => TaskForce) public taskForces; // Task Force ID to TaskForce details

    // Global Protocol Parameters (set by owner)
    uint256 public hcDecayRatePerYearBasisPoints; // e.g., 500 = 5% decay per year (500 basis points out of 10,000)
    uint256 public minAttestorScore; // Minimum expertise score required to issue/attest HCs
    uint64 public challengePeriodDuration; // Duration in seconds for a challenge to be active for voting
    address public taskForceRewardPoolAddress; // Address of an external contract holding rewards for Task Forces

    // Lookup mappings for filtering HCs by category or tags (indexed for faster retrieval)
    mapping(string => uint252[]) public hcsByCategory;
    mapping(string => uint252[]) public hcsBySkillTag;

    // --- Events ---
    event HyperCertificateIssued(uint252 indexed tokenId, address indexed recipient, address indexed issuer, string skillName);
    event HyperCertificateRevoked(uint252 indexed tokenId, address indexed revoker, string reason);
    event AttestationMade(uint252 indexed attestedTokenId, address indexed attestor, uint252 attestorHCId, uint256 weightBoost);
    event AttestationUpdated(uint252 indexed attestedTokenId, address indexed attestor, string newContext, uint256 newWeightBoost);
    event ChallengeRaised(uint252 indexed challengedTokenId, address indexed challenger, uint64 endTimestamp);
    event VoteCastOnChallenge(uint252 indexed challengedTokenId, address indexed voter, bool forRevoke);
    event ChallengeResolved(uint252 indexed challengedTokenId, bool revoked, string resolutionReason);
    event TaskForceProposed(uint252 indexed taskForceId, address indexed proposer, string name, string mission);
    event TaskForceJoined(uint252 indexed taskForceId, address indexed member);
    event TaskForceMissionCompleted(uint252 indexed taskForceId, address indexed completer);
    event TaskForceRewardsClaimed(uint252 indexed taskForceId, address indexed member, uint256 amount);
    event ProofOfWorkSubmitted(uint252 indexed tokenId, address indexed submitter, string proofCID);
    event ParameterUpdated(string indexed paramName, uint256 oldValue, uint256 newValue);
    event AddressParameterUpdated(string indexed paramName, address indexed oldValue, address indexed newValue);
    event HyperCertificateMetadataUpdated(uint252 indexed tokenId, string newURI);
    event SkillTagAdded(uint252 indexed tokenId, string tag);
    event TaskForceProposalVoted(uint252 indexed taskForceId, uint252 indexed proposalId, address indexed voter, bool vote);

    // --- Modifiers ---
    modifier onlyAttestor() {
        require(getUserExpertiseScore(msg.sender) >= minAttestorScore, "Not enough expertise to be an attestor");
        _;
    }

    modifier onlyHCRecipient(uint252 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the HC recipient");
        _;
    }

    modifier onlyTaskForceMember(uint252 _taskForceId) {
        require(taskForces[_taskForceId].isMember[msg.sender], "Caller is not a member of this task force");
        _;
    }

    modifier taskForceActive(uint252 _taskForceId) {
        require(!taskForces[_taskForceId].missionCompleted, "Task force mission already completed");
        require(block.timestamp <= taskForces[_taskForceId].deadlineTimestamp, "Task force deadline passed");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
    {
        _nextTokenId = 1;
        nextTaskForceId = 1;
        hcDecayRatePerYearBasisPoints = 500; // Default: 5% decay per year (500 basis points)
        minAttestorScore = 1000; // Default: Minimum score of 1000 to attest/issue HCs
        challengePeriodDuration = 7 days; // Default: 7 days for challenge voting
        taskForceRewardPoolAddress = address(0); // Needs to be set by owner later
    }

    // --- I. Core HyperCertificate Management & ERC-721 Interface ---

    /**
     * @dev Mints a new HyperCertificate (HC) to a recipient.
     *      Only callable by an address meeting the `minAttestorScore` requirement.
     * @param _recipient The address to receive the HC.
     * @param _skillName The name of the skill/achievement (e.g., "Solidity Development").
     * @param _skillCategory The broad category of the skill (e.g., "Tech", "Arts", "Community").
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS CID).
     * @param _expirationTimestamp Optional expiration timestamp (0 for no expiration).
     * @param _isSoulbound If true, the HC cannot be transferred from the recipient.
     * @param _initialSkillTags An array of initial granular tags for the skill.
     * @return The ID of the newly minted HyperCertificate.
     */
    function issueHyperCertificate(
        address _recipient,
        string memory _skillName,
        string memory _skillCategory,
        string memory _metadataURI,
        uint64 _expirationTimestamp,
        bool _isSoulbound,
        string[] memory _initialSkillTags
    ) external onlyAttestor whenNotPaused returns (uint252) {
        require(_recipient != address(0), "Recipient cannot be zero address");
        require(bytes(_skillName).length > 0, "Skill name cannot be empty");

        uint252 tokenId = uint252(_nextTokenId++); // Safely cast to uint252 for struct mapping
        _safeMint(_recipient, tokenId);

        HyperCertificate storage hc = hyperCertificates[tokenId];
        hc.recipient = _recipient;
        hc.issuer = msg.sender;
        hc.skillName = _skillName;
        hc.skillCategory = _skillCategory;
        hc.metadataURI = _metadataURI;
        hc.issuedTimestamp = uint64(block.timestamp);
        hc.expirationTimestamp = _expirationTimestamp;
        hc.isSoulbound = _isSoulbound;
        hc.isValid = true;
        hc.skillTags = _initialSkillTags; // Directly assign initial tags

        // Add to category/tag lookup arrays for easier discovery
        if (bytes(_skillCategory).length > 0) {
            hcsByCategory[_skillCategory].push(tokenId);
        }
        for (uint256 i = 0; i < _initialSkillTags.length; i++) {
            if (bytes(_initialSkillTags[i]).length > 0) {
                hcsBySkillTag[_initialSkillTags[i]].push(tokenId);
            }
        }

        emit HyperCertificateIssued(tokenId, _recipient, msg.sender, _skillName);
        return tokenId;
    }

    /**
     * @dev Allows the original issuer to revoke an existing HyperCertificate.
     *      This could be for reasons like misrepresentation or a policy change by the issuer.
     * @param _tokenId The ID of the HyperCertificate to revoke.
     * @param _reason A string explaining the reason for revocation.
     */
    function revokeHyperCertificate(uint252 _tokenId, string memory _reason) external whenNotPaused {
        require(hyperCertificates[_tokenId].issuer == msg.sender, "Only the issuer can revoke this HC");
        require(hyperCertificates[_tokenId].isValid, "HyperCertificate is already invalid");

        hyperCertificates[_tokenId].isValid = false; // Mark as invalid
        // Note: For simplicity, we don't remove from `hcsByCategory` or `hcsBySkillTag` arrays here
        // as array removal is gas-intensive. Clients should filter by `isValid`.

        emit HyperCertificateRevoked(_tokenId, msg.sender, _reason);
    }

    /**
     * @dev Retrieves all structured data for a given HyperCertificate.
     * @param _tokenId The ID of the HyperCertificate.
     * @return A tuple containing all HC details.
     */
    function getHyperCertificateDetails(uint252 _tokenId)
        public
        view
        returns (
            address recipient,
            address issuer,
            string memory skillName,
            string memory skillCategory,
            string memory metadataURI,
            uint64 issuedTimestamp,
            uint64 expirationTimestamp,
            bool isSoulbound,
            bool isValid,
            string[] memory skillTags
        )
    {
        HyperCertificate storage hc = hyperCertificates[_tokenId];
        require(hc.recipient != address(0), "HyperCertificate does not exist");
        return (
            hc.recipient,
            hc.issuer,
            hc.skillName,
            hc.skillCategory,
            hc.metadataURI,
            hc.issuedTimestamp,
            hc.expirationTimestamp,
            hc.isSoulbound,
            hc.isValid,
            hc.skillTags
        );
    }

    /**
     * @dev Allows the owner of an HC to update its off-chain metadata URI.
     * @param _tokenId The ID of the HyperCertificate.
     * @param _newURI The new URI for the metadata (e.g., IPFS CID, URL).
     */
    function updateHyperCertificateMetadataURI(uint252 _tokenId, string memory _newURI)
        external
        onlyHCRecipient(_tokenId)
        whenNotPaused
    {
        require(bytes(_newURI).length > 0, "Metadata URI cannot be empty");
        hyperCertificates[_tokenId].metadataURI = _newURI;
        emit HyperCertificateMetadataUpdated(_tokenId, _newURI);
    }

    /**
     * @dev Internal ERC-721 hook to enforce the 'soulbound' nature of specific HyperCertificates.
     *      Prevents transfer if HyperCertificate is marked as soulbound.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Only apply soulbound check if 'from' is not the zero address (i.e., not a mint)
        // and if the HC is marked as soulbound.
        if (from != address(0) && hyperCertificates[uint252(tokenId)].isSoulbound) {
            require(to == from, "Soulbound HyperCertificates cannot be transferred");
        }
    }

    // --- II. Attestation & Dynamic Reputation System ---

    /**
     * @dev Allows a user (attestor) to attest to the validity or impact of another HyperCertificate.
     *      The attestor must own an active HC and meet the `minAttestorScore` requirement.
     * @param _attestedTokenId The ID of the HyperCertificate being attested to.
     * @param _attestorHCId The ID of the attestor's HyperCertificate used as a credential for attestation.
     * @param _context Short description of why the attestation is made.
     */
    function attestToHyperCertificate(uint252 _attestedTokenId, uint252 _attestorHCId, string memory _context)
        external
        onlyAttestor
        whenNotPaused
    {
        require(hyperCertificates[_attestedTokenId].recipient != address(0), "Attested HC does not exist");
        require(hyperCertificates[_attestedTokenId].isValid, "Attested HC is invalid");
        require(ownerOf(_attestorHCId) == msg.sender, "Attestor must own the specified HC");
        require(hyperCertificates[_attestorHCId].isValid, "Attestor's HC is invalid");
        require(_attestedTokenId != _attestorHCId, "Cannot attest to your own HC using itself as credential");
        require(bytes(_context).length > 0, "Attestation context cannot be empty");

        // Prevent duplicate attestations from the same attestor address to the same HC
        require(_hcAttestations[_attestedTokenId][msg.sender].timestamp == 0, "Already attested to this HC from this address");

        // Calculate initial weight boost based on attestor's current score
        // Example: 1% of attestor's score, with a minimum boost to avoid zero.
        uint256 boost = getUserExpertiseScore(msg.sender) / 100;
        if (boost == 0) boost = 1; // Ensure a minimum boost value

        _hcAttestations[_attestedTokenId][msg.sender] = Attestation({
            attestor: msg.sender,
            attestorHCId: _attestorHCId,
            timestamp: uint64(block.timestamp),
            context: _context,
            weightBoost: boost
        });
        _attestorsForHC[_attestedTokenId].push(msg.sender); // Add attestor to list for iteration

        emit AttestationMade(_attestedTokenId, msg.sender, _attestorHCId, boost);
    }

    /**
     * @dev Allows an attestor to update their previous attestation to a HyperCertificate.
     *      This could be used to strengthen, weaken, or simply update the context of an attestation.
     * @param _attestedTokenId The ID of the HyperCertificate that was previously attested to.
     * @param _newContext The new context string for the attestation.
     * @param _newWeightBoost The new weight boost for the attestation (e.g., reflecting updated attestor score).
     */
    function updateAttestationValidity(uint252 _attestedTokenId, string memory _newContext, uint256 _newWeightBoost)
        external
        onlyAttestor
        whenNotPaused
    {
        Attestation storage att = _hcAttestations[_attestedTokenId][msg.sender];
        require(att.timestamp != 0, "No existing attestation from caller to this HC"); // Must have an existing attestation
        require(hyperCertificates[_attestedTokenId].isValid, "Attested HC is invalid");
        require(bytes(_newContext).length > 0, "New context cannot be empty");

        att.context = _newContext;
        att.weightBoost = _newWeightBoost;

        emit AttestationUpdated(_attestedTokenId, msg.sender, _newContext, _newWeightBoost);
    }

    /**
     * @dev Allows anyone to raise a formal challenge against the validity of a HyperCertificate.
     *      This initiates a voting period for resolution.
     * @param _tokenId The ID of the HyperCertificate to challenge.
     * @param _reason The reason for raising the challenge.
     */
    function challengeAttestation(uint252 _tokenId, string memory _reason) external whenNotPaused {
        require(hyperCertificates[_tokenId].recipient != address(0), "HyperCertificate does not exist");
        require(hyperCertificates[_tokenId].isValid, "HyperCertificate is already invalid");
        require(!isChallenged[_tokenId], "HyperCertificate is already under challenge");
        require(bytes(_reason).length > 0, "Challenge reason cannot be empty");

        activeChallenges[_tokenId] = Challenge({
            challenger: msg.sender,
            startedTimestamp: uint64(block.timestamp),
            endTimestamp: uint64(block.timestamp + challengePeriodDuration),
            resolved: false,
            votesForRevoke: 0,
            votesAgainstRevoke: 0,
            arbiters: new address[](0) // Arbiters can be an empty array if open to all attestors for voting
        });
        isChallenged[_tokenId] = true;

        emit ChallengeRaised(_tokenId, msg.sender, activeChallenges[_tokenId].endTimestamp);
    }

    /**
     * @dev Allows a designated arbiter (or anyone meeting `minAttestorScore`) to vote on an active challenge.
     * @param _tokenId The ID of the HyperCertificate under challenge.
     * @param _forRevoke True if voting to revoke the HC, false otherwise.
     */
    function voteOnChallenge(uint252 _tokenId, bool _forRevoke) external onlyAttestor whenNotPaused {
        Challenge storage challenge = activeChallenges[_tokenId];
        require(isChallenged[_tokenId], "HyperCertificate is not under challenge");
        require(!challenge.resolved, "Challenge has already been resolved");
        require(block.timestamp <= challenge.endTimestamp, "Challenge voting period has ended");
        require(!challenge.hasVoted[msg.sender], "Caller has already voted on this challenge");

        challenge.hasVoted[msg.sender] = true;
        if (_forRevoke) {
            challenge.votesForRevoke++;
        } else {
            challenge.votesAgainstRevoke++;
        }

        emit VoteCastOnChallenge(_tokenId, msg.sender, _forRevoke);
    }

    /**
     * @dev Resolves a challenge based on the accumulated votes. Can only be called after the challenge period ends.
     *      If votes for revoke exceed votes against revoke, the HC is revoked (marked as invalid).
     * @param _tokenId The ID of the HyperCertificate whose challenge is to be resolved.
     */
    function resolveChallenge(uint252 _tokenId) external whenNotPaused {
        Challenge storage challenge = activeChallenges[_tokenId];
        require(isChallenged[_tokenId], "HyperCertificate is not under challenge");
        require(!challenge.resolved, "Challenge has already been resolved");
        require(block.timestamp > challenge.endTimestamp, "Challenge voting period has not ended yet");

        challenge.resolved = true;
        isChallenged[_tokenId] = false; // Mark challenge as resolved regardless of outcome

        bool revoked = false;
        if (challenge.votesForRevoke > challenge.votesAgainstRevoke) {
            hyperCertificates[_tokenId].isValid = false; // Invalidate the challenged HC
            revoked = true;
        }

        emit ChallengeResolved(_tokenId, revoked, revoked ? "Revoked by community vote" : "Challenge failed");
        delete activeChallenges[_tokenId]; // Clean up challenge data
    }

    /**
     * @dev Calculates the current dynamic reputational weight of a single HyperCertificate.
     *      Factors in its time-decay and the sum of weight boosts from attestations received.
     * @param _tokenId The ID of the HyperCertificate.
     * @return The calculated weight (score). Returns 0 if invalid, non-existent, or expired.
     */
    function calculateHyperCertificateWeight(uint252 _tokenId) public view returns (uint256) {
        HyperCertificate storage hc = hyperCertificates[_tokenId];
        if (hc.recipient == address(0) || !hc.isValid || (hc.expirationTimestamp != 0 && block.timestamp > hc.expirationTimestamp)) {
            return 0; // Invalid, non-existent, or expired HC has no weight
        }

        uint256 currentWeight = 100; // Base weight for any valid HC

        // Apply time-decay based on `hcDecayRatePerYearBasisPoints`
        uint64 daysSinceIssue = (uint64(block.timestamp) - hc.issuedTimestamp) / 1 days;
        if (hcDecayRatePerYearBasisPoints > 0 && daysSinceIssue > 0) {
            // Calculate decay based on years passed
            uint255 yearsPassed = daysSinceIssue / 365; // Integer division gives full years
            uint255 decayFactor = (10000 - hcDecayRatePerYearBasisPoints) / 10000; // e.g., for 5% decay, factor is 0.95
            uint255 decayedWeight = currentWeight;

            // Apply decay exponentially for each year
            for (uint255 i = 0; i < yearsPassed; i++) {
                decayedWeight = (decayedWeight * decayFactor) / 10000;
            }
            currentWeight = decayedWeight;
        }

        // Apply attestation boost from all valid attestations
        uint256 totalAttestationBoost = 0;
        for (uint256 i = 0; i < _attestorsForHC[_tokenId].length; i++) {
            address attestorAddress = _attestorsForHC[_tokenId][i];
            Attestation storage att = _hcAttestations[_tokenId][attestorAddress];
            if (att.timestamp > 0) { // Check if attestation exists and is valid
                // Attestation weight can itself decay or be re-evaluated
                totalAttestationBoost += att.weightBoost;
            }
        }
        currentWeight += totalAttestationBoost;

        return currentWeight;
    }

    /**
     * @dev Calculates a user's overall dynamic expertise and reputation score.
     *      Aggregates the weighted scores of all valid HyperCertificates owned by the user.
     * @param _user The address of the user.
     * @return The total expertise score.
     */
    function getUserExpertiseScore(address _user) public view returns (uint256) {
        uint256 totalScore = 0;
        uint256 hcCount = balanceOf(_user); // Number of HCs owned by the user

        for (uint256 i = 0; i < hcCount; i++) {
            uint252 tokenId = uint252(tokenOfOwnerByIndex(_user, i)); // Retrieve HC ID by index
            totalScore += calculateHyperCertificateWeight(tokenId);
        }
        return totalScore;
    }

    /**
     * @dev Admin function to set the minimum expertise score required for users
     *      to be eligible to issue new HCs or attest to existing ones.
     * @param _score The new minimum score.
     */
    function setAttestorMinScore(uint256 _score) external onlyOwner whenNotPaused {
        emit ParameterUpdated("minAttestorScore", minAttestorScore, _score);
        minAttestorScore = _score;
    }

    // --- III. Task Force (Micro-DAO) Management ---

    /**
     * @dev Allows a user to propose the creation of a new Task Force (Micro-DAO).
     *      Proposers must meet the `minAttestorScore`.
     * @param _name The name of the Task Force.
     * @param _missionDescription A description of the Task Force's mission.
     * @param _deadlineTimestamp The timestamp by which the mission should be completed.
     * @param _rewardAmount The total reward for the task force (if any) to be claimed by members.
     * @param _rewardToken The address of the ERC20 reward token (if any).
     * @param _requiredSkillNames An array of skill names required for membership.
     * @param _minScoresForSkills An array of minimum expertise scores corresponding to `_requiredSkillNames`.
     * @return The ID of the newly created Task Force.
     */
    function proposeTaskForce(
        string memory _name,
        string memory _missionDescription,
        uint64 _deadlineTimestamp,
        uint256 _rewardAmount,
        address _rewardToken,
        string[] memory _requiredSkillNames,
        uint256[] memory _minScoresForSkills
    ) external onlyAttestor whenNotPaused returns (uint252) {
        require(bytes(_name).length > 0, "Task force name cannot be empty");
        require(_deadlineTimestamp > block.timestamp, "Deadline must be in the future");
        require(_requiredSkillNames.length == _minScoresForSkills.length, "Skill requirements array mismatch");

        uint252 taskForceId = uint252(nextTaskForceId++); // Safely cast
        TaskForce storage tf = taskForces[taskForceId];
        tf.name = _name;
        tf.missionDescription = _missionDescription;
        tf.creationTimestamp = uint64(block.timestamp);
        tf.deadlineTimestamp = _deadlineTimestamp;
        tf.missionCompleted = false;
        tf.proposer = msg.sender;
        tf.rewardAmount = _rewardAmount;
        tf.rewardToken = _rewardToken;
        tf.proposalCounter = 0;
        tf.requiredSkillNamesList = _requiredSkillNames; // Store skill names as an array for iteration

        for (uint256 i = 0; i < _requiredSkillNames.length; i++) {
            tf.requiredHyperCertificates[_requiredSkillNames[i]] = _minScoresForSkills[i];
        }

        emit TaskForceProposed(taskForceId, msg.sender, _name, _missionDescription);
        return taskForceId;
    }

    /**
     * @dev Allows eligible users to join an active Task Force.
     *      Eligibility is determined by holding specific HyperCertificates with minimum expertise scores,
     *      as defined by the Task Force's proposer.
     * @param _taskForceId The ID of the Task Force to join.
     */
    function joinTaskForce(uint252 _taskForceId) external taskForceActive(_taskForceId) whenNotPaused {
        TaskForce storage tf = taskForces[_taskForceId];
        require(!tf.isMember[msg.sender], "Already a member of this task force");

        // Check if the user meets all required HC criteria
        bool meetsAllRequirements = _checkTaskForceEligibility(msg.sender, tf.requiredSkillNamesList, tf.requiredHyperCertificates);
        require(meetsAllRequirements, "User does not meet all task force HC requirements");

        tf.isMember[msg.sender] = true;
        tf.members.push(msg.sender);

        emit TaskForceJoined(_taskForceId, msg.sender);
    }

    /**
     * @dev Internal helper function to check if a user meets a Task Force's HC requirements.
     * @param _user The address of the user.
     * @param _requiredSkillNamesList Array of skill names required.
     * @param _requiredHyperCertificates Mapping of skill name to minimum score.
     * @return True if the user holds HCs that satisfy all requirements, false otherwise.
     */
    function _checkTaskForceEligibility(
        address _user,
        string[] memory _requiredSkillNamesList,
        mapping(string => uint256) storage _requiredHyperCertificates
    ) internal view returns (bool) {
        if (_requiredSkillNamesList.length == 0) {
            return true; // No specific HC requirements, so user is eligible
        }

        uint256 userHcCount = balanceOf(_user);
        if (userHcCount == 0) {
            return false; // User has no HCs but requirements exist
        }

        // Track which requirements have been fulfilled
        mapping(string => bool) fulfilledRequirements;
        uint256 fulfilledCount = 0;

        // Iterate through the user's HCs
        for (uint256 i = 0; i < userHcCount; i++) {
            uint252 userTokenId = uint252(tokenOfOwnerByIndex(_user, i));
            HyperCertificate storage userHc = hyperCertificates[userTokenId];

            // Check if this HC fulfills any of the *unfulfilled* requirements
            for (uint256 j = 0; j < _requiredSkillNamesList.length; j++) {
                string memory requiredSkill = _requiredSkillNamesList[j];
                uint256 minScore = _requiredHyperCertificates[requiredSkill];

                if (!fulfilledRequirements[requiredSkill] && // Not already fulfilled
                    keccak256(abi.encodePacked(userHc.skillName)) == keccak256(abi.encodePacked(requiredSkill)) &&
                    calculateHyperCertificateWeight(userTokenId) >= minScore)
                {
                    fulfilledRequirements[requiredSkill] = true;
                    fulfilledCount++;
                    break; // This HC fulfilled a requirement, move to next HC
                }
            }
        }
        return fulfilledCount == _requiredSkillNamesList.length; // All requirements must be met
    }

    /**
     * @dev Allows members of a Task Force to vote on internal proposals or decisions.
     * @param _taskForceId The ID of the Task Force.
     * @param _proposalDescription The description of the proposal being voted on.
     * @param _voteDuration The duration (in seconds) for which this specific vote will be open.
     * @param _forProposal True if voting for the proposal, false otherwise.
     */
    function voteOnTaskForceDecision(uint252 _taskForceId, string memory _proposalDescription, uint64 _voteDuration, bool _forProposal)
        external
        onlyTaskForceMember(_taskForceId)
        taskForceActive(_taskForceId)
        whenNotPaused
    {
        TaskForce storage tf = taskForces[_taskForceId];
        uint252 proposalId = uint252(tf.proposalCounter++); // Increment proposal counter for a new unique ID

        TaskForceProposal storage proposal = tf.proposals[proposalId];
        proposal.description = _proposalDescription;
        proposal.voteEndTime = uint64(block.timestamp + _voteDuration);
        proposal.executed = false; // Initially not executed

        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_forProposal) {
            proposal.votesYes++;
        } else {
            proposal.votesNo++;
        }
        emit TaskForceProposalVoted(_taskForceId, proposalId, msg.sender, _forProposal);
    }

    /**
     * @dev Marks a Task Force's mission as completed. Can be called by any member.
     *      This action flags the mission as finished and enables reward claims.
     * @param _taskForceId The ID of the Task Force.
     */
    function completeTaskForceMission(uint252 _taskForceId) external onlyTaskForceMember(_taskForceId) whenNotPaused {
        TaskForce storage tf = taskForces[_taskForceId];
        require(!tf.missionCompleted, "Task force mission already completed");
        require(block.timestamp <= tf.deadlineTimestamp, "Cannot complete mission after deadline");

        tf.missionCompleted = true;
        emit TaskForceMissionCompleted(_taskForceId, msg.sender);
    }

    /**
     * @dev Allows individual Task Force members to claim their share of rewards.
     *      Assumes rewards are pre-loaded into the `taskForceRewardPoolAddress` (an ERC20 token contract).
     * @param _taskForceId The ID of the Task Force.
     */
    function claimTaskForceRewards(uint252 _taskForceId) external onlyTaskForceMember(_taskForceId) whenNotPaused {
        TaskForce storage tf = taskForces[_taskForceId];
        require(tf.missionCompleted, "Task force mission not yet completed");
        require(tf.rewardAmount > 0, "No rewards allocated for this task force");
        require(tf.rewardToken != address(0), "Reward token not set for this task force");

        require(!tf.hasClaimedRewards[msg.sender], "Rewards already claimed by this member");

        uint256 memberCount = tf.members.length;
        require(memberCount > 0, "No members in task force to distribute rewards");

        uint256 rewardPerMember = tf.rewardAmount / memberCount;

        // Mark that this member has claimed rewards
        tf.hasClaimedRewards[msg.sender] = true;

        // Attempt to transfer rewards from the designated reward pool to the member.
        // This assumes `taskForceRewardPoolAddress` is an ERC20 token contract and
        // that this `HyperCertificates` contract has been granted sufficient allowance
        // by the `taskForceRewardPoolAddress` or is the designated owner for transfers.
        // Alternatively, `taskForceRewardPoolAddress` could be a vault that handles distribution.
        IERC20(tf.rewardToken).transferFrom(taskForceRewardPoolAddress, msg.sender, rewardPerMember);

        emit TaskForceRewardsClaimed(_taskForceId, msg.sender, rewardPerMember);
    }

    /**
     * @dev Allows an HC owner to link their HyperCertificate to an external cryptographic proof of work.
     *      This could be a Git commit hash, an IPFS CID of verifiable computation result, or other evidence.
     *      This function does not verify the proof on-chain, but provides a reference point.
     * @param _tokenId The ID of the HyperCertificate.
     * @param _proofCID The CID or hash representing the external proof.
     */
    function submitProofOfWorkForHC(uint252 _tokenId, string memory _proofCID) external onlyHCRecipient(_tokenId) whenNotPaused {
        require(hyperCertificates[_tokenId].isValid, "HyperCertificate is invalid");
        require(bytes(_proofCID).length > 0, "Proof CID cannot be empty");

        // For this demo, we emit an event. In a full system, you might:
        // 1. Add a `string proofOfWorkCID` field to the `HyperCertificate` struct.
        // 2. Call an external Verifiable Compute Oracle contract to verify the CID/hash.
        // For simplicity, we just log the submission.
        emit ProofOfWorkSubmitted(_tokenId, msg.sender, _proofCID);
    }

    // --- IV. Admin & Utility Functions ---

    /**
     * @dev Admin function to adjust the global time-decay rate for HyperCertificates.
     *      A higher rate means HC weights diminish faster over time.
     * @param _newRateBasisPoints The new decay rate in basis points (e.g., 100 = 1%, 500 = 5%).
     *      Max 10000 (100%).
     */
    function setDecayRate(uint256 _newRateBasisPoints) external onlyOwner whenNotPaused {
        require(_newRateBasisPoints <= 10000, "Decay rate cannot exceed 100%"); // Max 100% decay per year
        emit ParameterUpdated("hcDecayRatePerYearBasisPoints", hcDecayRatePerYearBasisPoints, _newRateBasisPoints);
        hcDecayRatePerYearBasisPoints = _newRateBasisPoints;
    }

    /**
     * @dev Admin function to set the duration for challenge voting.
     * @param _duration The new duration in seconds (e.g., 7 days = 604800).
     */
    function setChallengePeriod(uint64 _duration) external onlyOwner whenNotPaused {
        require(_duration > 0, "Challenge period must be greater than zero");
        emit ParameterUpdated("challengePeriodDuration", challengePeriodDuration, _duration);
        challengePeriodDuration = _duration;
    }

    /**
     * @dev Admin function to set the address of a designated ERC20 reward pool contract
     *      from which Task Force members will claim their rewards.
     * @param _poolAddress The address of the reward pool contract.
     */
    function setTaskForceRewardPool(address _poolAddress) external onlyOwner whenNotPaused {
        require(_poolAddress != address(0), "Reward pool address cannot be zero");
        emit AddressParameterUpdated("taskForceRewardPoolAddress", taskForceRewardPoolAddress, _poolAddress);
        taskForceRewardPoolAddress = _poolAddress;
    }

    /**
     * @dev Allows the issuer of an HC to assign or update a broad category to it.
     *      This helps with general organization and filtering of HyperCertificates.
     * @param _tokenId The ID of the HyperCertificate.
     * @param _category The new category (e.g., "Tech", "Arts", "Community", "Research").
     */
    function setHyperCertificateCategory(uint252 _tokenId, string memory _category) external whenNotPaused {
        require(hyperCertificates[_tokenId].issuer == msg.sender, "Only the issuer can set/update HC category");
        require(bytes(_category).length > 0, "Category cannot be empty");

        // In a production system, you might want to remove the HC from the old category's list
        // in `hcsByCategory` before adding to the new one. This involves complex array manipulation
        // on-chain. For this demo, we simply update the HC struct and assume clients can re-index
        // or filter accordingly. Adding to `hcsByCategory` for new categories happens during minting.
        hyperCertificates[_tokenId].skillCategory = _category;
    }

    /**
     * @dev Allows the owner of an HC to add descriptive skill tags to their certificate.
     *      These tags enable more granular classification and searchability.
     * @param _tokenId The ID of the HyperCertificate.
     * @param _tag The skill tag to add (e.g., "Solidity", "AI/ML", "Decentralized Finance").
     */
    function addSkillTagToHC(uint252 _tokenId, string memory _tag) external onlyHCRecipient(_tokenId) whenNotPaused {
        require(bytes(_tag).length > 0, "Skill tag cannot be empty");

        // Check for duplicates before adding
        for (uint256 i = 0; i < hyperCertificates[_tokenId].skillTags.length; i++) {
            if (keccak256(abi.encodePacked(hyperCertificates[_tokenId].skillTags[i])) == keccak256(abi.encodePacked(_tag))) {
                revert("Skill tag already exists for this HC");
            }
        }
        hyperCertificates[_tokenId].skillTags.push(_tag);
        hcsBySkillTag[_tag].push(_tokenId); // Add to global lookup by tag
        emit SkillTagAdded(_tokenId, _tag);
    }

    /**
     * @dev Retrieves a list of HyperCertificate IDs filtered by a specific skill tag.
     * @param _tag The skill tag to filter by.
     * @return An array of HyperCertificate IDs that have the specified tag.
     */
    function getHyperCertificatesBySkillTag(string memory _tag) public view returns (uint252[] memory) {
        return hcsBySkillTag[_tag];
    }
}

```