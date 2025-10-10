Here's a smart contract in Solidity called "SynergiaNexus", designed to be an advanced, creative, and trendy platform for decentralized skill attestation, dynamic soulbound NFTs (NSTs), community-driven project funding, and reputation-gated governance. It avoids direct duplication of major open-source projects by combining these concepts into a unique ecosystem.

---

## SynergiaNexus Smart Contract

**Contract Name:** `SynergiaNexus`

**Description:**
The SynergiaNexus is a decentralized platform designed to foster collaboration, recognize skills, and reward contributions within its community. It introduces **Nexus Soulbound Tokens (NSTs)**, which are dynamic, non-transferable NFTs representing a user's evolving reputation and attested skills. Users can attest to each other's abilities, propose and fund collaborative projects, and collectively govern a community treasury. The system incorporates reputation staking for attestations, a challenge mechanism for dispute resolution, and a dynamic NFT metadata system that reflects a user's journey and achievements.

**Core Concepts:**
1.  **Dynamic Nexus Soulbound Tokens (NSTs):** Non-transferable ERC-721 tokens (following ERC-5192) that evolve their metadata (visuals, attributes) based on a user's on-chain activities, such as received attestations, successful project contributions, and reputation score milestones.
2.  **Reputation-Gated Attestation System:** Users can vouch for others' skills. To prevent spam or malicious attestations, a small stake is required, which can be slashed if the attestation is successfully challenged.
3.  **On-chain Dispute Resolution:** A mechanism for challenging false or malicious attestations, involving a staked amount and a DAO-governed resolution process.
4.  **Community-Driven Project Funding:** Users can propose projects requiring funding and contributors. Approved contributors submit deliverables and are rewarded from project-specific escrow funds upon completion.
5.  **Reputation-Weighted Governance:** A simple DAO mechanism where voting power for grants and parameter changes is weighted by a user's calculated reputation score and NST level.
6.  **External Oracle Integration (Conceptual):** Placeholder for potential integration with off-chain data sources to verify external contributions and inject reputation boosts.

---

### Function Summary:

**A. Initialization & Core:**
1.  `initialize(string _baseURI)`: Sets the initial base URI for NST metadata and initializes contract owner.
2.  `pause()`: Pauses contract functionality in emergencies.
3.  `unpause()`: Unpauses the contract.

**B. Profile & NST Management:**
4.  `registerProfile(string _name, string _bio, string _ipfsHashForAvatar)`: Creates a user profile.
5.  `updateProfile(string _name, string _bio, string _ipfsHashForAvatar)`: Updates an existing user profile.
6.  `issueNexusSoulboundToken()`: Mints the unique, non-transferable NST for the caller.
7.  `getNSTMetadataURI(address _user)`: Generates and returns the dynamic metadata URI for a user's NST based on their current reputation.

**C. Attestation & Reputation:**
8.  `attestSkill(address _targetUser, string _skillName, uint8 _proficiencyLevel, string _contextURI) payable`: Attests to a user's skill, requiring a stake.
9.  `revokeAttestation(bytes32 _attestationId)`: Allows an attester to revoke their own attestation.
10. `challengeAttestation(bytes32 _attestationId, string _reasonURI) payable`: Initiates a challenge against an attestation, requiring a stake.
11. `resolveAttestationChallenge(bytes32 _attestationId, bool _isMalicious)`: Resolves an attestation challenge, distributing stakes.
12. `getAggregatedSkillProficiency(address _user, string _skillName)`: Calculates the weighted average proficiency for a skill.
13. `calculateReputationScore(address _user)`: Computes a user's overall reputation score.

**D. Project & Contribution:**
14. `proposeContributionProject(string _title, string _descriptionURI, uint256 _rewardAmount, uint256 _minReputationRequired)`: Allows high-reputation users to propose projects.
15. `fundContributionProject(uint256 _projectId) payable`: Funds a proposed project.
16. `submitProjectDeliverable(uint256 _projectId, string _deliverableURI)`: Allows an approved contributor to submit their work.
17. `approveProjectDeliverable(uint256 _projectId, address _contributor)`: Project creator approves submitted deliverable.
18. `distributeProjectReward(uint256 _projectId, address _contributor)`: Disburses rewards to a contributor after approval.

**E. Treasury & Governance:**
19. `depositToTreasury() payable`: Allows anyone to donate funds to the community treasury.
20. `proposeGrant(address _recipient, uint256 _amount, string _reasonURI)`: Proposes a grant from the treasury, requiring DAO vote.
21. `voteOnProposal(uint256 _proposalId, bool _support)`: Casts a reputation-weighted vote on a proposal.
22. `executeProposal(uint256 _proposalId)`: Executes a passed proposal.
23. `updateGlobalParameter(bytes32 _paramKey, uint256 _newValue)`: Allows the DAO to update certain global parameters (e.g., attestation stake).

**F. External Integration & Utilities:**
24. `setExternalOracleAddress(address _oracleAddress)`: Sets the address of a trusted oracle.
25. `reportExternalContribution(address _user, string _contributionType, string _proofURI, uint256 _reputationBoost)`: Allows a trusted oracle to report external contributions and grant reputation boosts.
26. `tokenURI(uint256 _tokenId)`: ERC-721 standard; returns the dynamic metadata URI for an NST.
27. `transferFrom(address from, address to, uint256 tokenId)`: Overrides ERC-721 transfer to prevent NST transfers.
28. `supportsInterface(bytes4 interfaceId)`: ERC-165 standard; indicates supported interfaces, including ERC-5192.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC5192.sol"; // For Soulbound nature

/**
 * @title SynergiaNexus
 * @dev A decentralized platform for skill attestation, dynamic soulbound NFTs (NSTs),
 *      community-driven project funding, and reputation-gated governance.
 *      NSTs are non-transferable ERC-721 tokens (ERC-5192 compliant) whose metadata
 *      evolves based on user reputation, attestations, and contributions.
 */
contract SynergiaNexus is ERC721, Ownable, Pausable, IERC5192 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // 1. Core Configuration
    string private _baseTokenURI;
    Counters.Counter private _nextTokenId;
    uint256 public constant INITIAL_REPUTATION_BOOST = 100; // Base reputation for minting an NST
    uint256 public attestationStake = 0.005 ether; // ETH required to attest or challenge
    uint256 public challengePeriodDuration = 3 days; // Time for a challenge to be active
    uint256 public proposalQuorumPercentage = 51; // % of total reputation needed to pass a proposal
    uint256 public proposalVotingPeriod = 7 days; // Duration for voting on proposals

    // 2. User Profiles & NSTs
    struct UserProfile {
        string name;
        string bio;
        string ipfsHashForAvatar;
        uint256 reputationScore;
        bool hasNST;
    }
    mapping(address => UserProfile) public userProfiles; // address -> UserProfile

    // 3. Attestation System
    struct Attestation {
        bytes32 id; // keccak256 hash of (attester, target, skillName)
        address attester;
        address targetUser;
        string skillName;
        uint8 proficiencyLevel; // 1-100
        string contextURI; // IPFS hash or URL for proof/context
        uint256 timestamp;
        bool revoked;
        bool challenged;
        bool isMalicious; // Result of challenge resolution
        uint256 stake; // ETH staked by attester
    }
    mapping(bytes32 => Attestation) public attestations; // Attestation ID -> Attestation details
    mapping(address => bytes32[]) public userAttestationsReceived; // user -> list of attestation IDs
    mapping(address => bytes32[]) public userAttestationsGiven; // user -> list of attestation IDs

    // 4. Attestation Challenges
    struct AttestationChallenge {
        bytes32 attestationId;
        address challenger;
        string reasonURI;
        uint256 challengeStake; // ETH staked by challenger
        uint256 challengeStartTime;
        bool resolved;
    }
    mapping(bytes32 => AttestationChallenge) public attestationChallenges; // Attestation ID -> Challenge details

    // 5. Project System
    Counters.Counter private _nextProjectId;
    enum ProjectStatus { Proposed, Funded, Active, Completed, Cancelled }
    struct ContributionProject {
        uint256 projectId;
        address proposer;
        string title;
        string descriptionURI;
        uint256 rewardAmount; // Total ETH reward for the project
        uint256 minReputationRequired;
        uint256 fundedAmount; // Actual ETH received for funding
        ProjectStatus status;
        mapping(address => string) deliverables; // contributor -> deliverable URI
        mapping(address => bool) deliverablesApproved; // contributor -> approved status
        mapping(address => bool) rewardsDistributed; // contributor -> reward distributed status
        address[] contributors; // List of approved contributors
        uint256 timestamp;
    }
    mapping(uint256 => ContributionProject) public projects; // Project ID -> Project details

    // 6. Treasury & Governance (Simple DAO)
    address public treasuryAddress; // Where all contract funds are held
    Counters.Counter private _nextProposalId;
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string descriptionURI; // IPFS hash or URL for proposal details
        address targetAddress; // Address to interact with
        uint256 value; // ETH value to send (e.g., for grants)
        bytes callData; // Encoded function call for complex actions (e.g., parameter updates)
        uint256 creationTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted; // User -> Voted status
        ProposalStatus status;
    }
    mapping(uint252 => Proposal) public proposals; // Proposal ID -> Proposal details

    // 7. Oracles
    address public trustedOracleAddress; // Address of a trusted oracle for external contributions

    // --- Events ---
    event ProfileRegistered(address indexed user, string name, string ipfsHashForAvatar);
    event NSTIssued(address indexed owner, uint256 tokenId);
    event SkillAttested(bytes32 indexed attestationId, address indexed attester, address indexed targetUser, string skillName, uint8 proficiencyLevel);
    event AttestationRevoked(bytes32 indexed attestationId);
    event AttestationChallengeStarted(bytes32 indexed attestationId, address indexed challenger, string reasonURI);
    event AttestationChallengeResolved(bytes32 indexed attestationId, bool isMalicious, uint256 attesterStakeRefund, uint256 challengerStakeRefund);
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string title, uint256 rewardAmount);
    event ProjectFunded(uint256 indexed projectId, uint256 amount);
    event DeliverableSubmitted(uint256 indexed projectId, address indexed contributor, string deliverableURI);
    event DeliverableApproved(uint256 indexed projectId, address indexed contributor);
    event RewardDistributed(uint256 indexed projectId, address indexed contributor, uint256 amount);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string descriptionURI);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event GlobalParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event OracleAddressSet(address indexed oracleAddress);
    event ExternalContributionReported(address indexed user, string contributionType, uint256 reputationBoost);

    // --- Modifiers ---
    modifier onlyRegistered() {
        require(userProfiles[msg.sender].hasNST, "SynergiaNexus: Caller must have an NST and profile");
        _;
    }

    modifier onlyNSTOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "SynergiaNexus: Not owner of NST");
        _;
    }

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracleAddress, "SynergiaNexus: Only trusted oracle can call this function");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < _nextProposalId.current(), "SynergiaNexus: Proposal does not exist");
        _;
    }

    // --- Constructor & Initialization ---
    constructor() ERC721("Nexus Soulbound Token", "NST") Ownable(msg.sender) {
        treasuryAddress = address(this); // Contract itself acts as the treasury
    }

    /**
     * @dev Initializes the contract by setting the base URI for NST metadata.
     *      Can only be called once by the contract owner.
     * @param _baseURI The base URI for dynamic NFT metadata.
     */
    function initialize(string memory _baseURI) public onlyOwner {
        require(bytes(_baseTokenURI).length == 0, "SynergiaNexus: Contract already initialized");
        _baseTokenURI = _baseURI;
        _paused = false; // Ensure contract is not paused initially
    }

    // --- Pausable Overrides ---
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- B. Profile & NST Management ---

    /**
     * @dev Registers a new user profile. Each user can only have one profile.
     *      Automatically sets initial reputation and marks for NST minting.
     * @param _name User's chosen display name.
     * @param _bio User's short biography.
     * @param _ipfsHashForAvatar IPFS hash for the user's avatar image.
     */
    function registerProfile(string memory _name, string memory _bio, string memory _ipfsHashForAvatar)
        public
        whenNotPaused
    {
        require(!userProfiles[msg.sender].hasNST, "SynergiaNexus: User already has a profile.");
        require(bytes(_name).length > 0, "SynergiaNexus: Name cannot be empty.");

        userProfiles[msg.sender] = UserProfile({
            name: _name,
            bio: _bio,
            ipfsHashForAvatar: _ipfsHashForAvatar,
            reputationScore: INITIAL_REPUTATION_BOOST, // Start with a base reputation
            hasNST: false
        });
        emit ProfileRegistered(msg.sender, _name, _ipfsHashForAvatar);
    }

    /**
     * @dev Updates an existing user profile.
     * @param _name New display name.
     * @param _bio New biography.
     * @param _ipfsHashForAvatar New IPFS hash for avatar.
     */
    function updateProfile(string memory _name, string memory _bio, string memory _ipfsHashForAvatar)
        public
        onlyRegistered
        whenNotPaused
    {
        require(bytes(_name).length > 0, "SynergiaNexus: Name cannot be empty.");
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].bio = _bio;
        userProfiles[msg.sender].ipfsHashForAvatar = _ipfsHashForAvatar;
        emit ProfileRegistered(msg.sender, _name, _ipfsHashForAvatar); // Re-emit for update indication
    }

    /**
     * @dev Mints a Nexus Soulbound Token (NST) for the caller.
     *      Each user can only mint one NST, and it is non-transferable.
     *      Requires an existing profile.
     */
    function issueNexusSoulboundToken() public onlyRegistered whenNotPaused {
        require(!userProfiles[msg.sender].hasNST, "SynergiaNexus: User already has an NST.");

        _nextTokenId.increment();
        uint256 tokenId = _nextTokenId.current();
        _mint(msg.sender, tokenId);
        _setTokenBound(tokenId, true); // Mark as soulbound
        userProfiles[msg.sender].hasNST = true; // Mark profile as having an NST

        emit NSTIssued(msg.sender, tokenId);
    }

    /**
     * @dev Generates the dynamic metadata URI for a user's NST.
     *      This URI points to an external server or IPFS gateway that
     *      dynamically serves JSON metadata based on the user's current reputation and profile.
     * @param _user The address of the user whose NST metadata is requested.
     * @return The dynamic metadata URI.
     */
    function getNSTMetadataURI(address _user) public view returns (string memory) {
        require(userProfiles[_user].hasNST, "SynergiaNexus: User does not have an NST.");
        uint256 tokenId = _ownerToTokenId[_user]; // Assuming 1 NST per user, map owner to tokenId
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), "/dynamic/", userProfiles[_user].reputationScore.toString()));
    }

    // --- C. Attestation & Reputation ---

    /**
     * @dev Allows a user to attest to another user's skill.
     *      Requires a stake to prevent spam/malicious attestations.
     * @param _targetUser The user whose skill is being attested.
     * @param _skillName The name of the skill (e.g., "Solidity Development").
     * @param _proficiencyLevel The attested proficiency level (1-100).
     * @param _contextURI IPFS hash or URL providing context/proof for the attestation.
     */
    function attestSkill(
        address _targetUser,
        string memory _skillName,
        uint8 _proficiencyLevel,
        string memory _contextURI
    ) public payable onlyRegistered whenNotPaused {
        require(msg.sender != _targetUser, "SynergiaNexus: Cannot attest your own skill.");
        require(userProfiles[_targetUser].hasNST, "SynergiaNexus: Target user must have an NST.");
        require(_proficiencyLevel > 0 && _proficiencyLevel <= 100, "SynergiaNexus: Proficiency level must be between 1 and 100.");
        require(msg.value == attestationStake, "SynergiaNexus: Incorrect attestation stake provided.");

        bytes32 attestationId = keccak256(abi.encodePacked(msg.sender, _targetUser, _skillName));
        require(attestations[attestationId].attester == address(0), "SynergiaNexus: Attestation already exists for this skill by this attester.");

        attestations[attestationId] = Attestation({
            id: attestationId,
            attester: msg.sender,
            targetUser: _targetUser,
            skillName: _skillName,
            proficiencyLevel: _proficiencyLevel,
            contextURI: _contextURI,
            timestamp: block.timestamp,
            revoked: false,
            challenged: false,
            isMalicious: false,
            stake: msg.value
        });

        userAttestationsReceived[_targetUser].push(attestationId);
        userAttestationsGiven[msg.sender].push(attestationId);

        // Boost reputation of target user, weighted by proficiency
        userProfiles[_targetUser].reputationScore += (_proficiencyLevel * 2);

        emit SkillAttested(attestationId, msg.sender, _targetUser, _skillName, _proficiencyLevel);
    }

    /**
     * @dev Allows an attester to revoke their own attestation.
     *      The staked ETH is returned to the attester.
     * @param _attestationId The ID of the attestation to revoke.
     */
    function revokeAttestation(bytes32 _attestationId) public onlyRegistered whenNotPaused {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.attester == msg.sender, "SynergiaNexus: Not the attester.");
        require(!attestation.revoked, "SynergiaNexus: Attestation already revoked.");
        require(!attestation.challenged, "SynergiaNexus: Cannot revoke a challenged attestation.");

        attestation.revoked = true;
        
        // Deduct reputation (can be refined to be more complex)
        userProfiles[attestation.targetUser].reputationScore -= (attestation.proficiencyLevel * 2);
        if (userProfiles[attestation.targetUser].reputationScore < 0) { // Prevent negative reputation
            userProfiles[attestation.targetUser].reputationScore = 0;
        }

        (bool success, ) = payable(msg.sender).call{value: attestation.stake}("");
        require(success, "SynergiaNexus: Failed to return attester stake.");

        emit AttestationRevoked(_attestationId);
    }

    /**
     * @dev Initiates a challenge against a potentially false or malicious attestation.
     *      Requires a stake from the challenger.
     * @param _attestationId The ID of the attestation being challenged.
     * @param _reasonURI IPFS hash or URL detailing the reason for the challenge.
     */
    function challengeAttestation(bytes32 _attestationId, string memory _reasonURI)
        public
        payable
        onlyRegistered
        whenNotPaused
    {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.attester != address(0), "SynergiaNexus: Attestation does not exist.");
        require(!attestation.revoked, "SynergiaNexus: Cannot challenge a revoked attestation.");
        require(!attestation.challenged, "SynergiaNexus: Attestation is already under challenge.");
        require(msg.sender != attestation.attester, "SynergiaNexus: Cannot challenge your own attestation.");
        require(msg.value == attestationStake, "SynergiaNexus: Incorrect challenge stake provided.");

        attestation.challenged = true;
        attestationChallenges[_attestationId] = AttestationChallenge({
            attestationId: _attestationId,
            challenger: msg.sender,
            reasonURI: _reasonURI,
            challengeStake: msg.value,
            challengeStartTime: block.timestamp,
            resolved: false
        });

        emit AttestationChallengeStarted(_attestationId, msg.sender, _reasonURI);
    }

    /**
     * @dev Resolves an attestation challenge. This function is designed to be called
     *      by a DAO vote (via executeProposal) or by the contract owner in an emergency.
     * @param _attestationId The ID of the challenged attestation.
     * @param _isMalicious True if the attestation is deemed malicious/false, false otherwise.
     */
    function resolveAttestationChallenge(bytes32 _attestationId, bool _isMalicious) public onlyOwner whenNotPaused {
        // In a full DAO, this would be restricted to successful proposals, not direct owner.
        // For simplicity, owner can resolve.
        Attestation storage attestation = attestations[_attestationId];
        AttestationChallenge storage challenge = attestationChallenges[_attestationId];

        require(attestation.challenged, "SynergiaNexus: Attestation is not challenged.");
        require(!challenge.resolved, "SynergiaNexus: Challenge already resolved.");
        require(block.timestamp > challenge.challengeStartTime + challengePeriodDuration, "SynergiaNexus: Challenge period not over.");

        challenge.resolved = true;
        attestation.isMalicious = _isMalicious;

        uint256 attesterRefund = 0;
        uint256 challengerRefund = 0;

        if (_isMalicious) {
            // Attester loses stake, challenger gets their stake back.
            // Attester's reputation is also penalized.
            userProfiles[attestation.targetUser].reputationScore -= (attestation.proficiencyLevel * 5); // Larger penalty for receiving malicious attestation
            userProfiles[attestation.attester].reputationScore -= (attestation.proficiencyLevel * 10); // Penalty for giving malicious attestation
            if (userProfiles[attestation.targetUser].reputationScore < 0) userProfiles[attestation.targetUser].reputationScore = 0;
            if (userProfiles[attestation.attester].reputationScore < 0) userProfiles[attestation.attester].reputationScore = 0;

            challengerRefund = challenge.challengeStake;
            (bool success, ) = payable(challenge.challenger).call{value: challengerRefund}("");
            require(success, "SynergiaNexus: Failed to refund challenger stake.");
        } else {
            // Attestation is valid, challenger loses stake, attester gets their stake back.
            userProfiles[challenge.challenger].reputationScore /= 2; // Challenger's reputation penalized for false challenge

            attesterRefund = attestation.stake;
            (bool success, ) = payable(attestation.attester).call{value: attesterRefund}("");
            require(success, "SynergiaNexus: Failed to refund attester stake.");
        }

        emit AttestationChallengeResolved(_attestationId, _isMalicious, attesterRefund, challengerRefund);
    }


    /**
     * @dev Calculates the aggregated skill proficiency for a user in a specific skill.
     *      Considers all valid (non-revoked, non-malicious) attestations.
     * @param _user The user's address.
     * @param _skillName The skill name.
     * @return The aggregated proficiency level (0-100).
     */
    function getAggregatedSkillProficiency(address _user, string memory _skillName)
        public
        view
        returns (uint256)
    {
        uint256 totalProficiency = 0;
        uint256 count = 0;

        for (uint256 i = 0; i < userAttestationsReceived[_user].length; i++) {
            bytes32 attestationId = userAttestationsReceived[_user][i];
            Attestation storage att = attestations[attestationId];

            if (
                !att.revoked &&
                !att.isMalicious && // Only count non-malicious attestations
                keccak256(abi.encodePacked(att.skillName)) == keccak256(abi.encodePacked(_skillName))
            ) {
                totalProficiency += att.proficiencyLevel;
                count++;
            }
        }

        return count > 0 ? totalProficiency / count : 0;
    }

    /**
     * @dev Calculates a user's overall reputation score.
     *      This is a core metric influencing governance and project eligibility.
     *      Factors: initial boost, attestations (proficiency, validity), challenge history,
     *      project contributions, external boosts.
     *      Note: This is a simplified calculation; a production system would be more complex.
     * @param _user The user's address.
     * @return The calculated reputation score.
     */
    function calculateReputationScore(address _user) public view returns (uint256) {
        UserProfile storage profile = userProfiles[_user];
        if (!profile.hasNST) return 0; // No NST, no reputation.

        uint256 score = profile.reputationScore; // Base reputation

        // Add points for each valid, non-revoked attestation received
        for (uint256 i = 0; i < userAttestationsReceived[_user].length; i++) {
            bytes32 attestationId = userAttestationsReceived[_user][i];
            Attestation storage att = attestations[attestationId];
            if (!att.revoked && !att.isMalicious) {
                score += att.proficiencyLevel; // Each point of proficiency adds to reputation
            }
        }
        // Deduct for malicious attestations given
        for (uint256 i = 0; i < userAttestationsGiven[_user].length; i++) {
            bytes32 attestationId = userAttestationsGiven[_user][i];
            Attestation storage att = attestations[attestationId];
            if (att.isMalicious) {
                score -= att.proficiencyLevel * 2; // Heavier penalty for malicious attestations given
            }
        }

        // Add points for successful project contributions (simplified for this contract)
        // This would ideally iterate through projects and check for _user's approved contributions
        // For now, let's assume it's updated directly by reportExternalContribution or similar logic.

        return score > 0 ? score : 0; // Ensure reputation doesn't go negative
    }

    // --- D. Project & Contribution ---

    /**
     * @dev Proposes a new collaborative project.
     *      Requires a minimum reputation score from the proposer.
     * @param _title Project title.
     * @param _descriptionURI IPFS hash or URL for detailed project description.
     * @param _rewardAmount Total ETH reward allocated for the project upon completion.
     * @param _minReputationRequired Minimum reputation score required for contributors to join.
     */
    function proposeContributionProject(
        string memory _title,
        string memory _descriptionURI,
        uint256 _rewardAmount,
        uint256 _minReputationRequired
    ) public onlyRegistered whenNotPaused returns (uint256) {
        require(bytes(_title).length > 0, "SynergiaNexus: Project title cannot be empty.");
        require(calculateReputationScore(msg.sender) >= _minReputationRequired, "SynergiaNexus: Proposer does not meet minimum reputation.");

        _nextProjectId.increment();
        uint256 projectId = _nextProjectId.current();

        projects[projectId].projectId = projectId;
        projects[projectId].proposer = msg.sender;
        projects[projectId].title = _title;
        projects[projectId].descriptionURI = _descriptionURI;
        projects[projectId].rewardAmount = _rewardAmount;
        projects[projectId].minReputationRequired = _minReputationRequired;
        projects[projectId].status = ProjectStatus.Proposed;
        projects[projectId].timestamp = block.timestamp;

        emit ProjectProposed(projectId, msg.sender, _title, _rewardAmount);
        return projectId;
    }

    /**
     * @dev Funds a proposed project. Anyone can deposit ETH to fund a project.
     * @param _projectId The ID of the project to fund.
     */
    function fundContributionProject(uint256 _projectId) public payable whenNotPaused {
        ContributionProject storage project = projects[_projectId];
        require(project.proposer != address(0), "SynergiaNexus: Project does not exist.");
        require(project.status == ProjectStatus.Proposed, "SynergiaNexus: Project is not in 'Proposed' state.");
        require(msg.value > 0, "SynergiaNexus: Funding amount must be greater than zero.");

        project.fundedAmount += msg.value;
        if (project.fundedAmount >= project.rewardAmount) {
            project.status = ProjectStatus.Funded;
        }
        emit ProjectFunded(_projectId, msg.value);
    }

    /**
     * @dev Allows an approved contributor to submit their project deliverable.
     *      The contributor must meet the project's minimum reputation requirement.
     * @param _projectId The ID of the project.
     * @param _deliverableURI IPFS hash or URL for the deliverable.
     */
    function submitProjectDeliverable(uint256 _projectId, string memory _deliverableURI)
        public
        onlyRegistered
        whenNotPaused
    {
        ContributionProject storage project = projects[_projectId];
        require(project.proposer != address(0), "SynergiaNexus: Project does not exist.");
        require(project.status == ProjectStatus.Funded || project.status == ProjectStatus.Active, "SynergiaNexus: Project is not active for submissions.");
        require(calculateReputationScore(msg.sender) >= project.minReputationRequired, "SynergiaNexus: Contributor does not meet minimum reputation.");

        // For simplicity, anyone meeting min reputation can submit; in production, project proposer
        // might need to explicitly 'add contributor'.
        project.deliverables[msg.sender] = _deliverableURI;
        project.contributors.push(msg.sender); // Add to contributors list if not already there (handle duplicates if needed)
        project.status = ProjectStatus.Active; // Mark as active if not already

        emit DeliverableSubmitted(_projectId, msg.sender, _deliverableURI);
    }

    /**
     * @dev Allows the project proposer to approve a submitted deliverable.
     * @param _projectId The ID of the project.
     * @param _contributor The address of the contributor whose deliverable is being approved.
     */
    function approveProjectDeliverable(uint256 _projectId, address _contributor) public onlyRegistered whenNotPaused {
        ContributionProject storage project = projects[_projectId];
        require(project.proposer == msg.sender, "SynergiaNexus: Only the project proposer can approve deliverables.");
        require(project.proposer != address(0), "SynergiaNexus: Project does not exist.");
        require(bytes(project.deliverables[_contributor]).length > 0, "SynergiaNexus: No deliverable submitted by this contributor.");
        require(!project.deliverablesApproved[_contributor], "SynergiaNexus: Deliverable already approved.");

        project.deliverablesApproved[_contributor] = true;
        userProfiles[_contributor].reputationScore += 50; // Boost contributor's reputation

        emit DeliverableApproved(_projectId, _contributor);
    }

    /**
     * @dev Distributes the project reward to an approved contributor.
     * @param _projectId The ID of the project.
     * @param _contributor The address of the contributor to reward.
     */
    function distributeProjectReward(uint256 _projectId, address _contributor) public onlyRegistered whenNotPaused {
        ContributionProject storage project = projects[_projectId];
        require(project.proposer == msg.sender, "SynergiaNexus: Only the project proposer can distribute rewards.");
        require(project.proposer != address(0), "SynergiaNexus: Project does not exist.");
        require(project.deliverablesApproved[_contributor], "SynergiaNexus: Deliverable not yet approved.");
        require(!project.rewardsDistributed[_contributor], "SynergiaNexus: Reward already distributed.");
        require(project.fundedAmount >= project.rewardAmount, "SynergiaNexus: Project not fully funded.");

        uint256 rewardPerContributor = project.rewardAmount / project.contributors.length; // Simplified; ideally dynamic based on contribution

        project.rewardsDistributed[_contributor] = true;

        (bool success, ) = payable(_contributor).call{value: rewardPerContributor}("");
        require(success, "SynergiaNexus: Failed to distribute reward.");

        // Potentially mark project as completed if all rewards distributed
        // This logic can be more complex, e.g., requiring all contributors to be paid out.
        project.status = ProjectStatus.Completed;

        emit RewardDistributed(_projectId, _contributor, rewardPerContributor);
    }

    // --- E. Treasury & Governance (Simple DAO) ---

    /**
     * @dev Allows any user to deposit ETH into the community treasury.
     */
    function depositToTreasury() public payable whenNotPaused {
        require(msg.value > 0, "SynergiaNexus: Deposit amount must be greater than zero.");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Proposes a new governance action (e.g., a grant, parameter update).
     *      Requires a minimum reputation score from the proposer.
     * @param _recipient The target address for the action (e.g., grant recipient).
     * @param _amount The ETH amount to transfer (0 for parameter updates).
     * @param _reasonURI IPFS hash or URL for detailed proposal description.
     * @param _callData Encoded function call if the proposal involves calling a specific function on the contract itself.
     */
    function proposeGrant(
        address _recipient,
        uint256 _amount,
        string memory _reasonURI,
        bytes memory _callData
    ) public onlyRegistered whenNotPaused returns (uint256) {
        require(calculateReputationScore(msg.sender) >= 500, "SynergiaNexus: Proposer does not meet minimum reputation for proposals."); // Min rep for proposing
        require(bytes(_reasonURI).length > 0, "SynergiaNexus: Proposal reason cannot be empty.");

        _nextProposalId.increment();
        uint256 proposalId = _nextProposalId.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            descriptionURI: _reasonURI,
            targetAddress: _recipient,
            value: _amount,
            callData: _callData,
            creationTime: block.timestamp,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Pending,
            hasVoted: new mapping(address => bool) // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _reasonURI);
        return proposalId;
    }

    /**
     * @dev Allows a user to vote on a proposal. Voting power is weighted by their reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegistered whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "SynergiaNexus: Proposal is not in 'Pending' state.");
        require(!proposal.hasVoted[msg.sender], "SynergiaNexus: User already voted on this proposal.");
        require(block.timestamp <= proposal.creationTime + proposalVotingPeriod, "SynergiaNexus: Voting period has ended.");

        uint256 voteWeight = calculateReputationScore(msg.sender);
        require(voteWeight > 0, "SynergiaNexus: Cannot vote with zero reputation.");

        if (_support) {
            proposal.totalVotesFor += voteWeight;
        } else {
            proposal.totalVotesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support, voteWeight);
    }

    /**
     * @dev Executes a proposal if it has passed quorum and the voting period has ended.
     *      Only callable by the owner (or eventually by a dedicated executor contract/role).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "SynergiaNexus: Proposal is not pending.");
        require(block.timestamp > proposal.creationTime + proposalVotingPeriod, "SynergiaNexus: Voting period has not ended.");

        // Calculate total possible voting power (sum of all users' reputation scores) - simplified for this example
        // In a real DAO, this would be total reputation at snapshot time.
        uint256 totalAvailableReputation = 0;
        uint256 currentTokenId = _nextTokenId.current();
        for (uint256 i = 1; i <= currentTokenId; i++) {
            address owner = ownerOf(i); // Get owner of each NST
            totalAvailableReputation += calculateReputationScore(owner);
        }
        
        // Quorum check
        uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;
        require(totalVotesCast * 100 >= totalAvailableReputation * proposalQuorumPercentage, "SynergiaNexus: Quorum not met.");


        if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
            proposal.status = ProposalStatus.Approved;
            if (proposal.value > 0) {
                require(address(this).balance >= proposal.value, "SynergiaNexus: Insufficient treasury balance for grant.");
                (bool success, ) = payable(proposal.targetAddress).call{value: proposal.value}("");
                require(success, "SynergiaNexus: Failed to execute grant transfer.");
            }
            if (proposal.callData.length > 0) {
                // Execute arbitrary call data on this contract
                (bool success, bytes memory result) = address(this).call(proposal.callData);
                require(success, string(abi.encodePacked("SynergiaNexus: Failed to execute call data: ", string(result))));
            }
        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows the DAO to update certain global parameters via a successful proposal.
     *      This function would be called via `executeProposal` with specific `callData`.
     * @param _paramKey The key identifying the parameter to update (e.g., "attestationStake").
     * @param _newValue The new value for the parameter.
     */
    function updateGlobalParameter(bytes32 _paramKey, uint256 _newValue) public onlyOwner whenNotPaused {
        // This function is intended to be called by `executeProposal` as part of a DAO action.
        // It's `onlyOwner` for security, meaning only the contract itself (acting as owner for `callData`)
        // or the actual owner can call it directly.

        if (_paramKey == keccak256(abi.encodePacked("attestationStake"))) {
            attestationStake = _newValue;
        } else if (_paramKey == keccak256(abi.encodePacked("challengePeriodDuration"))) {
            challengePeriodDuration = _newValue;
        } else if (_paramKey == keccak256(abi.encodePacked("proposalQuorumPercentage"))) {
            require(_newValue > 0 && _newValue <= 100, "SynergiaNexus: Quorum must be 1-100.");
            proposalQuorumPercentage = _newValue;
        } else if (_paramKey == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            proposalVotingPeriod = _newValue;
        } else {
            revert("SynergiaNexus: Invalid parameter key.");
        }
        emit GlobalParameterUpdated(_paramKey, _newValue);
    }

    // --- F. External Integration & Utilities ---

    /**
     * @dev Sets the address of a trusted external oracle.
     *      Only the contract owner can set this.
     * @param _oracleAddress The address of the trusted oracle.
     */
    function setExternalOracleAddress(address _oracleAddress) public onlyOwner {
        trustedOracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Allows a trusted external oracle to report verifiable off-chain contributions.
     *      This can directly boost a user's reputation score.
     * @param _user The user who made the external contribution.
     * @param _contributionType Type of contribution (e.g., "GitHub Commit", "Event Speaker").
     * @param _proofURI IPFS hash or URL to the proof of contribution.
     * @param _reputationBoost The amount of reputation to add.
     */
    function reportExternalContribution(
        address _user,
        string memory _contributionType,
        string memory _proofURI,
        uint256 _reputationBoost
    ) public onlyTrustedOracle whenNotPaused {
        require(userProfiles[_user].hasNST, "SynergiaNexus: User must have an NST.");
        require(_reputationBoost > 0, "SynergiaNexus: Reputation boost must be positive.");

        userProfiles[_user].reputationScore += _reputationBoost;
        emit ExternalContributionReported(_user, _contributionType, _reputationBoost);
    }

    // --- ERC721 & ERC5192 Implementations ---

    // A mapping to store tokenId to owner (assuming 1 NST per user)
    mapping(address => uint256) private _ownerToTokenId;

    /**
     * @dev Returns the owner of the given token ID.
     *      Overrides the default to use our internal mapping for 1:1 owner-NST.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = super.ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Dynamically generates the token URI based on reputation and profile data.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address owner = ownerOf(tokenId); // Get the current owner of the token
        return getNSTMetadataURI(owner);
    }

    /**
     * @dev Prevents transfer of NSTs, making them Soulbound.
     *      Compliant with ERC-5192's `tokenBound` mechanism.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) {
            revert("SynergiaNexus: Nexus Soulbound Tokens are non-transferable.");
        }
    }

    /**
     * @dev Internal mapping to track if a token is bound.
     */
    mapping(uint256 => bool) private _tokenBoundStatus;

    /**
     * @dev Internal function to mark a token as bound/soulbound.
     */
    function _setTokenBound(uint256 tokenId, bool bound) internal {
        _tokenBoundStatus[tokenId] = bound;
    }

    /**
     * @dev See {IERC5192-isBound}. Returns true if the token is soulbound (non-transferable).
     */
    function isBound(uint256 tokenId) public view override returns (bool) {
        return _tokenBoundStatus[tokenId];
    }

    /**
     * @dev See {ERC165-supportsInterface}.
     *      Adds support for ERC-5192 interface.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Utility Functions ---

    /**
     * @dev Fallback function to allow receiving ETH.
     */
    receive() external payable {
        emit TreasuryDeposited(msg.sender, msg.value); // Assume direct ETH deposits go to treasury
    }

    /**
     * @dev Emergency withdraw function for the owner.
     *      In a real DAO, this would be a DAO-approved action.
     *      For emergency, it allows owner to retrieve funds.
     */
    function emergencyWithdraw(address _to, uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "SynergiaNexus: Insufficient balance.");
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "SynergiaNexus: Emergency withdraw failed.");
    }
}

```