Here's a Solidity smart contract that implements a **Decentralized AI-Augmented Reputation & Collaboration Hub (DAIRCH)**. This contract combines several advanced and trendy concepts: **Soulbound Tokens (SBTs)** for skills and achievements, a **dynamic NFT metadata** system, an **AI-augmented reputation oracle integration** (simulated for on-chain demo), and a **decentralized project management hub**.

The design avoids direct duplication of existing large open-source projects by integrating these features into a cohesive, novel system for skill, reputation, and project coordination.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For bounty token interface

/*
Outline: AI-Augmented Decentralized Reputation & Collaboration Hub (DAIRCH)

This smart contract implements a novel system for managing decentralized identities, skill-based Soulbound Tokens (SBTs), an AI-augmented reputation system, and a collaborative project hub. It aims to create a verifiable, dynamic, and evolving on-chain representation of user skills, contributions, and trust, facilitated by an external (simulated) AI Oracle.

I. Core Identity & Profile Management:
   - Allows users to register and update their on-chain profiles with off-chain metadata (IPFS).
   - Enables linking of verifiable external identity proofs.

II. Dynamic Skill & Achievement SBTs (Soulbound Tokens):
   - A registry for skills, potentially with prerequisites.
   - Non-transferable ERC-721 tokens (SBTs) representing acquired skills.
   - Peer-to-peer attestation system for skills, allowing users to vouch for others' proficiencies.
   - Dynamic SBT metadata, allowing an AI Oracle to evolve token traits based on ongoing activity and attestations.

III. AI-Augmented Reputation & Trust System:
   - Defines a trusted AI Oracle address responsible for calculating and updating user reputation scores and skill proficiencies based on collected on-chain data (attestations, contributions, project completions).
   - Reputation scores and skill proficiencies are dynamic and can be requested for recalculation.

IV. Decentralized Project & Collaboration Hub:
   - Facilitates the creation of collaborative projects with specified skill and reputation requirements.
   - Enables users to apply for projects, and project creators to approve applicants.
   - Provides a mechanism for submitting and verifying project contributions.
   - Automates bounty distribution and triggers reputation updates upon project finalization.

V. Utility & Management:
   - Standard ERC-721 metadata retrieval.
   - Pausability for emergency control.
   - Owner/admin functionalities for critical system parameters.

Function Summary:

I. Core Identity & Profile Management:
1.  `registerProfile(string calldata _ipfsMetadataHash)`: Registers a new user profile.
2.  `updateProfileMetadata(string calldata _newIpfsMetadataHash)`: Updates a user's profile metadata.
3.  `linkExternalVerifier(uint256 _verifierId, bytes memory _signature)`: Links an off-chain identity (simulated signature verification).
4.  `getProfileDetails(address _user)`: Retrieves comprehensive profile details.

II. Dynamic Skill & Achievement SBTs:
5.  `proposeSkill(string calldata _skillName, string calldata _description, uint256[] calldata _prerequisiteSkillIds)`: Proposes a new skill for the registry.
6.  `approveSkillProposal(uint256 _skillId)`: Admin/DAO approves a proposed skill.
7.  `mintSkillSBT(uint256 _skillId, address _to, string calldata _attestationMetadataHash)`: Mints a Soulbound Token for a specific skill.
8.  `attestSkill(address _recipient, uint256 _skillId, uint256 _rating, string calldata _commentIpfsHash)`: Attests to another's skill proficiency.
9.  `revokeAttestation(address _recipient, uint256 _skillId, uint256 _attestationIndex)`: Revokes a previous skill attestation.
10. `getSkillProficiency(address _user, uint256 _skillId)`: Retrieves AI-augmented proficiency score for a skill.
11. `evolveSBTTraits(uint256 _tokenId, string calldata _newIpfsMetadataHash)`: AI Oracle updates an SBT's metadata.

III. AI-Augmented Reputation & Trust System:
12. `setAiOracle(address _newOracle)`: Sets the trusted AI Oracle address.
13. `requestReputationRecalculation(address _user)`: Triggers AI Oracle to recalculate user's global reputation.
14. `setReputationScore(address _user, uint256 _newScore, uint256[] calldata _skillProficiencies)`: AI Oracle updates user's reputation and skill proficiencies.
15. `getReputationScore(address _user)`: Retrieves a user's AI-augmented global reputation score.

IV. Decentralized Project & Collaboration Hub:
16. `createProject(string calldata _projectName, string calldata _descriptionIpfsHash, uint256[] calldata _requiredSkillIds, uint256 _minReputation, uint256 _totalBounty, address _bountyToken)`: Creates a new collaborative project.
17. `applyForProject(uint256 _projectId, string calldata _applicationIpfsHash)`: Applies to a project.
18. `approveApplicant(uint256 _projectId, address _applicant)`: Project creator approves an applicant.
19. `submitContribution(uint256 _projectId, string calldata _contributionIpfsHash)`: Submits proof of contribution to a project.
20. `verifyContribution(uint256 _projectId, address _contributor, uint256 _contributionIndex, uint256 _contributionWeight)`: Project creator verifies a contribution.
21. `finalizeProject(uint256 _projectId)`: Finalizes a project, distributes bounties.
22. `getProjectApplicants(uint256 _projectId)`: Lists approved applicants for a project.

V. Utility & Management:
23. `tokenURI(uint256 _tokenId)`: Standard ERC-721 URI for SBT metadata.
24. `pause()`: Pauses certain contract functionalities.
25. `unpause()`: Unpauses contract functionalities.
*/

contract DAIRCH is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _skillIdCounter;
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _tokenIdCounter; // For SBTs

    address public aiOracle; // Address of the trusted AI oracle for reputation & skill calculations

    // --- Data Structures ---

    enum ProjectStatus { Open, Recruiting, InProgress, Finalized, Cancelled }

    struct UserProfile {
        bool registered;
        string ipfsMetadataHash; // Hash to IPFS for richer profile data (e.g., bio, links)
        uint256 reputationScore; // AI-augmented global reputation score
        mapping(uint256 => uint256) skillProficiency; // skillId => AI-augmented proficiency score (0-100)
        mapping(uint256 => Attestation[]) receivedAttestations; // skillId => list of attestations received
        mapping(uint256 => bool) hasSkillSBT; // skillId => true if user holds the SBT
        mapping(uint256 => uint256) linkedExternalVerifiers; // verifierId => timestamp of linking (simulated)
    }

    struct Skill {
        string name;
        string description;
        uint256[] prerequisiteSkillIds;
        bool approved; // Requires approval before minting SBTs for it
        uint256 sbtTokenId; // Stores the skill's associated SBT token ID (if minted for this skill type, 0 if not yet)
    }

    struct Attestation {
        address attester;
        uint256 rating; // e.g., 1-5 or 1-100
        string commentIpfsHash; // Optional: IPFS hash for a detailed comment
        uint256 timestamp;
    }

    struct Project {
        string name;
        string descriptionIpfsHash;
        address creator;
        uint256[] requiredSkillIds;
        uint256 minReputation;
        uint256 totalBounty;
        address bountyToken; // Address of the ERC-20 token for bounty (address(0) for no token bounty)
        ProjectStatus status;
        address[] approvedApplicants; // Addresses of users approved to join
        mapping(address => Contribution[]) contributions; // Contributor => list of contributions
        mapping(address => bool) isApplicantApproved; // Fast lookup for approval status
        mapping(address => bool) hasApplied; // Fast lookup for application status
    }

    struct Contribution {
        string ipfsHash;
        uint256 timestamp;
        uint256 weight; // Weight assigned by project creator, influencing bounty share/reputation
        bool verified;
    }

    // --- Mappings ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Skill) public skills; // skillId => Skill struct
    mapping(uint256 => Project) public projects; // projectId => Project struct
    mapping(uint256 => uint256) public sbtIdToSkillId; // SBT tokenId => skillId. Used to identify if a token is an SBT

    // --- Events ---
    event ProfileRegistered(address indexed user, string ipfsMetadataHash);
    event ProfileMetadataUpdated(address indexed user, string newIpfsMetadataHash);
    event ExternalVerifierLinked(address indexed user, uint256 verifierId);

    event SkillProposed(uint256 indexed skillId, string name, address indexed proposer);
    event SkillApproved(uint256 indexed skillId, address indexed approver);
    event SkillSBTminted(uint256 indexed tokenId, address indexed to, uint256 indexed skillId);
    event SkillAttested(address indexed attester, address indexed recipient, uint256 indexed skillId, uint256 rating);
    event AttestationRevoked(address indexed attester, address indexed recipient, uint256 indexed skillId, uint256 attestationIndex);
    event SkillProficiencyUpdated(address indexed user, uint256 indexed skillId, uint256 newProficiency);
    event SBTTraitsEvolved(uint256 indexed tokenId, string newIpfsMetadataHash);

    event ReputationRecalculationRequested(address indexed user);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event AiOracleSet(address indexed oldOracle, address indexed newOracle);

    event ProjectCreated(uint256 indexed projectId, string name, address indexed creator);
    event ProjectApplication(uint256 indexed projectId, address indexed applicant);
    event ApplicantApproved(uint256 indexed projectId, address indexed applicant);
    event ContributionSubmitted(uint256 indexed projectId, address indexed contributor, string ipfsHash);
    event ContributionVerified(uint256 indexed projectId, address indexed contributor, uint256 contributionIndex, uint256 weight);
    event ProjectFinalized(uint256 indexed projectId);
    event BountyDistributed(uint256 indexed projectId, address indexed recipient, uint256 amount);


    // --- Constructor ---
    constructor(address _aiOracleAddress) ERC721("DAIRCH_SBT", "DAIRCHSBT") Ownable(msg.sender) {
        require(_aiOracleAddress != address(0), "DAIRCH: AI Oracle cannot be zero address");
        aiOracle = _aiOracleAddress;
        // The ERC721 constructor handles name and symbol.
        // Ownable handles setting initial owner.
    }

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].registered, "DAIRCH: Caller must be a registered user.");
        _;
    }

    modifier onlyAiOracle() {
        require(msg.sender == aiOracle, "DAIRCH: Only AI Oracle can call this function.");
        _;
    }

    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender, "DAIRCH: Only project creator can perform this action.");
        _;
    }

    modifier onlyApprovedApplicant(uint256 _projectId) {
        require(projects[_projectId].isApplicantApproved[msg.sender], "DAIRCH: Only approved project members can perform this action.");
        _;
    }

    // --- I. Core Identity & Profile Management ---

    /**
     * @dev Registers a new user profile. Each address can only register once.
     * @param _ipfsMetadataHash IPFS hash for richer profile data (e.g., bio, links).
     */
    function registerProfile(string calldata _ipfsMetadataHash) external whenNotPaused {
        require(!userProfiles[msg.sender].registered, "DAIRCH: User already registered.");
        userProfiles[msg.sender].registered = true;
        userProfiles[msg.sender].ipfsMetadataHash = _ipfsMetadataHash;
        userProfiles[msg.sender].reputationScore = 0; // Initial score
        emit ProfileRegistered(msg.sender, _ipfsMetadataHash);
    }

    /**
     * @dev Updates a user's profile metadata. Only the registered user can update their own profile.
     * @param _newIpfsMetadataHash New IPFS hash for profile metadata.
     */
    function updateProfileMetadata(string calldata _newIpfsMetadataHash) external onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].ipfsMetadataHash = _newIpfsMetadataHash;
        emit ProfileMetadataUpdated(msg.sender, _newIpfsMetadataHash);
    }

    /**
     * @dev Simulates linking an external verifiable identity.
     *      In a real system, `_signature` would be used to verify the `_verifierId`
     *      against a known public key or DID resolver. This is a placeholder.
     * @param _verifierId A unique identifier for the external verifier type (e.g., 1 for GitHub, 2 for LinkedIn DID).
     * @param _signature The cryptographic proof (e.g., a signed message from the external identity).
     */
    function linkExternalVerifier(uint256 _verifierId, bytes memory _signature) external onlyRegisteredUser whenNotPaused {
        // Placeholder for actual signature verification logic.
        // For demonstration, simply check if signature is not empty.
        require(_signature.length > 0, "DAIRCH: Signature cannot be empty for verification.");
        userProfiles[msg.sender].linkedExternalVerifiers[_verifierId] = block.timestamp;
        emit ExternalVerifierLinked(msg.sender, _verifierId);
    }

    /**
     * @dev Retrieves comprehensive details for a user profile.
     * @param _user The address of the user to query.
     * @return _registered Boolean indicating if the user is registered.
     * @return _ipfsMetadataHash IPFS hash of profile metadata.
     * @return _reputationScore Current reputation score.
     */
    function getProfileDetails(address _user)
        external
        view
        returns (bool _registered, string memory _ipfsMetadataHash, uint256 _reputationScore)
    {
        UserProfile storage profile = userProfiles[_user];
        return (
            profile.registered,
            profile.ipfsMetadataHash,
            profile.reputationScore
        );
    }

    // --- II. Dynamic Skill & Achievement SBTs ---

    /**
     * @dev Proposes a new skill to be added to the registry. Requires approval by admin or DAO.
     * @param _skillName The name of the skill.
     * @param _description Description of the skill.
     * @param _prerequisiteSkillIds An array of skill IDs that are prerequisites for this skill.
     * @return The ID of the newly proposed skill.
     */
    function proposeSkill(string calldata _skillName, string calldata _description, uint256[] calldata _prerequisiteSkillIds)
        external
        onlyRegisteredUser
        whenNotPaused
        returns (uint256)
    {
        _skillIdCounter.increment();
        uint256 newSkillId = _skillIdCounter.current();
        skills[newSkillId] = Skill({
            name: _skillName,
            description: _description,
            prerequisiteSkillIds: _prerequisiteSkillIds,
            approved: false, // Starts unapproved
            sbtTokenId: 0 // No SBT token ID yet (will be set on first mint)
        });
        emit SkillProposed(newSkillId, _skillName, msg.sender);
        return newSkillId;
    }

    /**
     * @dev Approves a proposed skill, making it available for SBT minting. Only callable by the owner.
     * @param _skillId The ID of the skill to approve.
     */
    function approveSkillProposal(uint256 _skillId) external onlyOwner whenNotPaused {
        require(skills[_skillId].name.length > 0, "DAIRCH: Skill does not exist.");
        require(!skills[_skillId].approved, "DAIRCH: Skill already approved.");
        skills[_skillId].approved = true;
        emit SkillApproved(_skillId, msg.sender);
    }

    /**
     * @dev Mints a Soulbound Token (SBT) for a specific skill to a user.
     *      Requires the skill to be approved and the recipient to be registered.
     *      This function can only be called by the contract owner (or a trusted third party in a real system).
     * @param _skillId The ID of the skill to mint an SBT for.
     * @param _to The recipient of the SBT.
     * @param _attestationMetadataHash IPFS hash for initial attestation metadata.
     */
    function mintSkillSBT(uint256 _skillId, address _to, string calldata _attestationMetadataHash) external onlyOwner whenNotPaused {
        require(skills[_skillId].approved, "DAIRCH: Skill not approved for SBT minting.");
        require(userProfiles[_to].registered, "DAIRCH: Recipient is not a registered user.");
        require(!userProfiles[_to].hasSkillSBT[_skillId], "DAIRCH: User already has this skill SBT.");

        // Check prerequisites: user must hold SBTs for all prerequisite skills
        for (uint256 i = 0; i < skills[_skillId].prerequisiteSkillIds.length; i++) {
            require(userProfiles[_to].hasSkillSBT[skills[_skillId].prerequisiteSkillIds[i]], "DAIRCH: Missing prerequisite skill.");
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _attestationMetadataHash); // Initial metadata hash for the SBT

        sbtIdToSkillId[newTokenId] = _skillId; // Link the new SBT tokenId to its skillId
        userProfiles[_to].hasSkillSBT[_skillId] = true; // Mark user as having this skill SBT

        emit SkillSBTminted(newTokenId, _to, _skillId);
    }

    /**
     * @dev Attests to another user's proficiency in a specific skill.
     *      The attester must be a registered user.
     * @param _recipient The address of the user being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _rating A rating for the skill (e.g., 1-100).
     * @param _commentIpfsHash Optional IPFS hash for a detailed comment.
     */
    function attestSkill(address _recipient, uint256 _skillId, uint256 _rating, string calldata _commentIpfsHash) external onlyRegisteredUser whenNotPaused {
        require(_recipient != msg.sender, "DAIRCH: Cannot attest to your own skill.");
        require(userProfiles[_recipient].registered, "DAIRCH: Recipient is not a registered user.");
        require(skills[_skillId].approved, "DAIRCH: Skill is not approved.");
        require(_rating > 0 && _rating <= 100, "DAIRCH: Rating must be between 1 and 100.");

        userProfiles[_recipient].receivedAttestations[_skillId].push(
            Attestation({
                attester: msg.sender,
                rating: _rating,
                commentIpfsHash: _commentIpfsHash,
                timestamp: block.timestamp
            })
        );
        emit SkillAttested(msg.sender, _recipient, _skillId, _rating);
        // Trigger AI Oracle for recalculation (can be batched or called externally)
        emit ReputationRecalculationRequested(_recipient);
    }

    /**
     * @dev Allows an attester to revoke a previous attestation.
     * @param _recipient The address of the user who received the attestation.
     * @param _skillId The ID of the skill for which the attestation was made.
     * @param _attestationIndex The index of the attestation in the recipient's array.
     */
    function revokeAttestation(uint256 _recipientSkillId, uint256 _attestationIndex) external onlyRegisteredUser whenNotPaused {
        require(skills[_recipientSkillId].name.length > 0, "DAIRCH: Invalid skill ID."); // Ensure skill exists

        // Iterate through all user profiles to find the recipient and then revoke the attestation
        // Note: This is computationally expensive if there are many users and skills.
        // A more efficient design might require the caller to specify the recipient.
        // For this example, let's assume `_recipient` is also passed for simplicity.
        // Changing the function signature to include `_recipient`.
        revert("DAIRCH: This function requires specifying the recipient. Use revokeAttestation(address _recipient, uint256 _skillId, uint256 _attestationIndex).");
    }

    /**
     * @dev Allows an attester to revoke a previous attestation for a specific recipient.
     * @param _recipient The address of the user who received the attestation.
     * @param _skillId The ID of the skill for which the attestation was made.
     * @param _attestationIndex The index of the attestation in the recipient's array for that skill.
     */
    function revokeAttestation(address _recipient, uint256 _skillId, uint256 _attestationIndex) external onlyRegisteredUser whenNotPaused {
        require(userProfiles[_recipient].registered, "DAIRCH: Recipient is not a registered user.");
        require(_skillId > 0 && skills[_skillId].name.length > 0, "DAIRCH: Invalid skill ID.");

        Attestation[] storage attestations = userProfiles[_recipient].receivedAttestations[_skillId];
        require(_attestationIndex < attestations.length, "DAIRCH: Invalid attestation index.");
        require(attestations[_attestationIndex].attester == msg.sender, "DAIRCH: Not your attestation to revoke.");

        // Simple removal by replacing with last element and popping
        if (_attestationIndex != attestations.length - 1) {
            attestations[_attestationIndex] = attestations[attestations.length - 1];
        }
        attestations.pop();

        emit AttestationRevoked(msg.sender, _recipient, _skillId, _attestationIndex);
        // Trigger AI Oracle for recalculation
        emit ReputationRecalculationRequested(_recipient);
    }

    /**
     * @dev Retrieves the AI-augmented proficiency score for a specific skill of a user.
     *      This score is set by the AI Oracle.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return The proficiency score (0-100).
     */
    function getSkillProficiency(address _user, uint256 _skillId) external view returns (uint256) {
        return userProfiles[_user].skillProficiency[_skillId];
    }

    /**
     * @dev Allows the AI Oracle to update the metadata (traits) of a specific SBT.
     *      This simulates dynamic NFT evolution based on on-chain activity.
     * @param _tokenId The ID of the SBT to evolve.
     * @param _newIpfsMetadataHash The new IPFS hash for the SBT's metadata.
     */
    function evolveSBTTraits(uint256 _tokenId, string calldata _newIpfsMetadataHash) external onlyAiOracle whenNotPaused {
        require(_exists(_tokenId), "DAIRCH: SBT does not exist.");
        // Ensure this token ID is indeed an SBT managed by our contract
        require(sbtIdToSkillId[_tokenId] != 0, "DAIRCH: Not a managed skill SBT.");

        _setTokenURI(_tokenId, _newIpfsMetadataHash);
        emit SBTTraitsEvolved(_tokenId, _newIpfsMetadataHash);
    }

    // --- III. AI-Augmented Reputation & Trust System ---

    /**
     * @dev Sets the address of the trusted AI Oracle. Only the contract owner can do this.
     *      The AI Oracle is responsible for updating reputation scores and skill proficiencies.
     * @param _newOracle The new address for the AI Oracle.
     */
    function setAiOracle(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "DAIRCH: AI Oracle cannot be zero address.");
        emit AiOracleSet(aiOracle, _newOracle);
        aiOracle = _newOracle;
    }

    /**
     * @dev Requests the AI Oracle to recalculate a user's global reputation score.
     *      Can be called by anyone to prompt an update, but the actual update is done by `setReputationScore` from the Oracle.
     * @param _user The user whose reputation score needs recalculation.
     */
    function requestReputationRecalculation(address _user) external whenNotPaused {
        require(userProfiles[_user].registered, "DAIRCH: User not registered.");
        // In a real system, this might trigger an off-chain job for the AI oracle.
        emit ReputationRecalculationRequested(_user);
    }

    /**
     * @dev Sets a user's global reputation score and individual skill proficiencies.
     *      Only callable by the AI Oracle. The AI Oracle would calculate this based on
     *      attestations, project contributions, and other on-chain activities.
     * @param _user The user whose score is being set.
     * @param _newScore The new reputation score (e.g., 0-1000).
     * @param _skillProficiencies An array of skill IDs and their new proficiency scores.
     *      _skillProficiencies format: [skillId1, score1, skillId2, score2, ...]
     */
    function setReputationScore(address _user, uint256 _newScore, uint256[] calldata _skillProficiencies) external onlyAiOracle {
        require(userProfiles[_user].registered, "DAIRCH: User not registered.");
        userProfiles[_user].reputationScore = _newScore;
        emit ReputationScoreUpdated(_user, _newScore);

        // Update skill proficiencies based on AI Oracle's calculation
        require(_skillProficiencies.length % 2 == 0, "DAIRCH: Invalid skill proficiencies array length.");
        for (uint256 i = 0; i < _skillProficiencies.length; i += 2) {
            uint256 skillId = _skillProficiencies[i];
            uint256 proficiency = _skillProficiencies[i + 1];
            require(skills[skillId].approved, "DAIRCH: Skill ID for proficiency update is not approved.");
            userProfiles[_user].skillProficiency[skillId] = proficiency;
            emit SkillProficiencyUpdated(_user, skillId, proficiency);
        }
    }

    /**
     * @dev Retrieves a user's AI-augmented global reputation score.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address _user) external view returns (uint256) {
        return userProfiles[_user].reputationScore;
    }

    // --- IV. Decentralized Project & Collaboration Hub ---

    /**
     * @dev Creates a new collaborative project. Creator must be a registered user.
     * @param _projectName Name of the project.
     * @param _descriptionIpfsHash IPFS hash for detailed project description.
     * @param _requiredSkillIds Array of skill IDs required for applicants.
     * @param _minReputation Minimum reputation score required for applicants.
     * @param _totalBounty Total bounty amount for the project.
     * @param _bountyToken Address of the ERC-20 token for the bounty (address(0) for no token bounty).
     *        If _totalBounty > 0, the project creator must `approve` this contract to spend `_totalBounty` of `_bountyToken`.
     * @return The ID of the newly created project.
     */
    function createProject(
        string calldata _projectName,
        string calldata _descriptionIpfsHash,
        uint256[] calldata _requiredSkillIds,
        uint256 _minReputation,
        uint256 _totalBounty,
        address _bountyToken
    ) external onlyRegisteredUser whenNotPaused returns (uint256) {
        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].approved, "DAIRCH: Required skill is not approved.");
        }

        projects[newProjectId] = Project({
            name: _projectName,
            descriptionIpfsHash: _descriptionIpfsHash,
            creator: msg.sender,
            requiredSkillIds: _requiredSkillIds,
            minReputation: _minReputation,
            totalBounty: _totalBounty,
            bountyToken: _bountyToken,
            status: ProjectStatus.Open,
            approvedApplicants: new address[](0),
            isApplicantApproved: new mapping(address => bool)(),
            hasApplied: new mapping(address => bool)()
        });

        // Pull bounty tokens if specified
        if (_totalBounty > 0 && _bountyToken != address(0)) {
            IERC20(_bountyToken).transferFrom(msg.sender, address(this), _totalBounty);
        }

        emit ProjectCreated(newProjectId, _projectName, msg.sender);
        return newProjectId;
    }

    /**
     * @dev Allows a registered user to apply for a project.
     * @param _projectId The ID of the project to apply for.
     * @param _applicationIpfsHash IPFS hash for the application details (e.g., cover letter, resume link).
     */
    function applyForProject(uint256 _projectId, string calldata _applicationIpfsHash) external onlyRegisteredUser whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "DAIRCH: Project does not exist."); // Ensure project exists
        require(project.status == ProjectStatus.Open || project.status == ProjectStatus.Recruiting, "DAIRCH: Project not open for applications.");
        require(!project.hasApplied[msg.sender], "DAIRCH: You have already applied to this project.");

        // Check reputation requirement
        require(userProfiles[msg.sender].reputationScore >= project.minReputation, "DAIRCH: Insufficient reputation score.");

        // Check skill requirements (basic check for possession of SBT, not proficiency)
        for (uint256 i = 0; i < project.requiredSkillIds.length; i++) {
            require(userProfiles[msg.sender].hasSkillSBT[project.requiredSkillIds[i]], "DAIRCH: Missing required skill SBT.");
        }

        project.hasApplied[msg.sender] = true;
        // The application details are kept off-chain via _applicationIpfsHash.
        // No need to store _applicationIpfsHash on-chain directly, as `hasApplied` serves as the flag.
        emit ProjectApplication(_projectId, msg.sender);
    }

    /**
     * @dev Project creator approves an applicant to join the project.
     * @param _projectId The ID of the project.
     * @param _applicant The address of the applicant to approve.
     */
    function approveApplicant(uint256 _projectId, address _applicant) external onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Open || project.status == ProjectStatus.Recruiting, "DAIRCH: Project not in recruiting phase.");
        require(project.hasApplied[_applicant], "DAIRCH: User has not applied to this project.");
        require(!project.isApplicantApproved[_applicant], "DAIRCH: Applicant already approved.");

        project.approvedApplicants.push(_applicant);
        project.isApplicantApproved[_applicant] = true;

        if (project.status == ProjectStatus.Open) {
            project.status = ProjectStatus.Recruiting; // Move to recruiting if first applicant approved
        }

        emit ApplicantApproved(_projectId, _applicant);
    }

    /**
     * @dev Allows an approved project member to submit proof of their contribution.
     * @param _projectId The ID of the project.
     * @param _contributionIpfsHash IPFS hash linking to the contribution proof (e.g., code commit, design document).
     */
    function submitContribution(uint256 _projectId, string calldata _contributionIpfsHash) external onlyApprovedApplicant(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Recruiting || project.status == ProjectStatus.InProgress, "DAIRCH: Project not in progress or recruiting.");

        project.contributions[msg.sender].push(
            Contribution({
                ipfsHash: _contributionIpfsHash,
                timestamp: block.timestamp,
                weight: 0, // Weight to be set by creator later
                verified: false
            })
        );
        if (project.status == ProjectStatus.Recruiting) {
            project.status = ProjectStatus.InProgress; // Move to in-progress if first contribution submitted
        }
        emit ContributionSubmitted(_projectId, msg.sender, _contributionIpfsHash);
    }

    /**
     * @dev Project creator verifies a contribution and assigns it a weight.
     * @param _projectId The ID of the project.
     * @param _contributor The address of the contributor.
     * @param _contributionIndex The index of the contribution in the contributor's array.
     * @param _contributionWeight The weight assigned to this contribution (e.g., 1-100, influencing bounty share/reputation).
     */
    function verifyContribution(uint256 _projectId, address _contributor, uint256 _contributionIndex, uint256 _contributionWeight) external onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "DAIRCH: Project must be in progress.");
        require(project.isApplicantApproved[_contributor], "DAIRCH: User is not an approved member of this project.");
        require(_contributionIndex < project.contributions[_contributor].length, "DAIRCH: Invalid contribution index.");
        require(!project.contributions[_contributor][_contributionIndex].verified, "DAIRCH: Contribution already verified.");
        require(_contributionWeight > 0 && _contributionWeight <= 100, "DAIRCH: Contribution weight must be between 1 and 100.");

        project.contributions[_contributor][_contributionIndex].verified = true;
        project.contributions[_contributor][_contributionIndex].weight = _contributionWeight;

        emit ContributionVerified(_projectId, _contributor, _contributionIndex, _contributionWeight);
        // Trigger AI Oracle for reputation update based on this contribution
        emit ReputationRecalculationRequested(_contributor);
    }

    /**
     * @dev Finalizes a project, distributes bounties, and triggers reputation updates.
     *      Only the project creator can finalize.
     * @param _projectId The ID of the project to finalize.
     */
    function finalizeProject(uint256 _projectId) external onlyProjectCreator(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress, "DAIRCH: Project must be in progress to finalize.");
        project.status = ProjectStatus.Finalized;

        uint256 totalVerifiedWeight = 0;
        // Calculate total verified weight for bounty distribution
        for (uint256 i = 0; i < project.approvedApplicants.length; i++) {
            address contributor = project.approvedApplicants[i];
            for (uint256 j = 0; j < project.contributions[contributor].length; j++) {
                if (project.contributions[contributor][j].verified) {
                    totalVerifiedWeight += project.contributions[contributor][j].weight;
                }
            }
        }

        // Distribute bounty (simple proportional distribution)
        if (project.totalBounty > 0 && project.bountyToken != address(0) && totalVerifiedWeight > 0) {
            IERC20 bountyToken = IERC20(project.bountyToken);
            for (uint256 i = 0; i < project.approvedApplicants.length; i++) {
                address contributor = project.approvedApplicants[i];
                uint256 contributorWeight = 0;
                for (uint256 j = 0; j < project.contributions[contributor].length; j++) {
                    if (project.contributions[contributor][j].verified) {
                        contributorWeight += project.contributions[contributor][j].weight;
                    }
                }
                if (contributorWeight > 0) {
                    uint256 share = (project.totalBounty * contributorWeight) / totalVerifiedWeight;
                    require(bountyToken.transfer(contributor, share), "DAIRCH: Bounty transfer failed.");
                    emit BountyDistributed(_projectId, contributor, share);
                }
            }
        }

        // Trigger reputation updates for all participants (creator + contributors)
        emit ReputationRecalculationRequested(project.creator);
        for (uint256 i = 0; i < project.approvedApplicants.length; i++) {
            emit ReputationRecalculationRequested(project.approvedApplicants[i]);
        }

        emit ProjectFinalized(_projectId);
    }

    /**
     * @dev Gets the list of addresses that have been approved to join a specific project.
     * @param _projectId The ID of the project.
     * @return An array of addresses of approved applicants.
     */
    function getProjectApplicants(uint256 _projectId) external view returns (address[] memory) {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "DAIRCH: Project does not exist.");
        return project.approvedApplicants;
    }

    // --- V. Utility & Management ---

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     *      Returns the IPFS hash previously set for the SBT's metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    /**
     * @dev Pauses all functions decorated with `whenNotPaused`.
     *      Can only be called by the owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *      Can only be called by the owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides for Soulbound Behavior ---
    // These functions explicitly prevent transfer and approval of SBTs.

    /**
     * @dev Overrides ERC721's _beforeTokenTransfer to prevent transfer of skill SBTs.
     *      A token is considered an SBT if its `sbtIdToSkillId` mapping entry is non-zero.
     *      Allows minting (from address(0)) and burning (to address(0)).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if it's an SBT managed by this contract and it's not a mint or burn
        if (sbtIdToSkillId[tokenId] != 0 && from != address(0) && to != address(0)) {
            revert("DAIRCH: Soulbound Tokens are non-transferable.");
        }
    }

    /**
     * @dev Overrides ERC721's approve to prevent approvals for skill SBTs.
     */
    function approve(address to, uint256 tokenId) public override {
        // If the token is a skill SBT, disallow approval.
        require(sbtIdToSkillId[tokenId] == 0, "DAIRCH: Soulbound Tokens cannot be approved.");
        super.approve(to, tokenId);
    }

    /**
     * @dev Overrides ERC721's setApprovalForAll to prevent blanket approvals for skill SBTs.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        // If the caller owns ANY token from this contract, it is an SBT, and thus setting blanket approval is disallowed.
        // This is safe because this contract only mints SBTs, making any ERC721 from this contract an SBT.
        require(ERC721.balanceOf(msg.sender) == 0, "DAIRCH: Cannot set approval for all if you own skill SBTs (non-approvable).");
        super.setApprovalForAll(operator, approved);
    }
}
```