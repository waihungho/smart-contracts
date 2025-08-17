Okay, this is an exciting challenge! Creating a truly unique and advanced smart contract that isn't just a rehash of existing open-source projects requires blending several cutting-edge concepts.

I'll propose a contract called "**CogniGraph Nexus**" (CGN). It's a decentralized protocol for **Adaptive, Interconnected Skill & Reputation Profiles** powered by **On-Chain Attestation**, **Contextual AI Oracles**, and **Dynamic Soulbound Tokens (SBTs)**.

**Core Concepts:**

1.  **Adaptive Skill Soulbound Tokens (ASSBTs):** Not just static NFTs. These are SBTs tied to a user's address, representing their evolving skill set and reputation. Their metadata (or the data they point to) dynamically updates based on on-chain activities, successful task completions, oracle attestations, and even reputation decay.
2.  **On-Chain Attestation & Skill Graph:** Users can be attested for skills by other reputable users, dApps, or external oracles. These attestations form an on-chain skill graph, showing dependencies and interconnections.
3.  **Contextual AI Oracles:** The contract interacts with specialized oracles (e.g., Chainlink Functions, custom AI API bridges) that can perform complex evaluations (e.g., code quality analysis, sentiment analysis of on-chain activity, natural language understanding of submitted proofs) and feed back skill or reputation adjustments.
4.  **Decentralized Proof-of-Skill Bounties:** A system where users can propose tasks requiring specific skills, and successful completion leads to reputation, skill updates, and rewards, potentially validated by AI oracles.
5.  **Reputation & Decay Mechanisms:** Reputation is not static; it can grow with positive contributions and decay over time if inactive or if negative events occur, incentivizing continuous engagement.
6.  **Knowledge & Credential Interlinking:** Ability to link specific skill attestations to external verifiable credentials (e.g., Verifiable Credentials, DID-based certificates) or on-chain knowledge modules.

---

## **CogniGraph Nexus (CGN) Smart Contract**

**Outline:**

*   **I. Core Infrastructure & Access Control**
    *   Ownership & Pausability
    *   Emergency Operations
*   **II. Adaptive Skill Soulbound Token (ASSBT) Management**
    *   Profile Creation & Lifecycle
    *   Dynamic Metadata & Attribute Management
*   **III. Skill & Reputation System**
    *   Skill Definition & Categorization
    *   Attestation & Verification (Human & Oracle)
    *   Reputation Metrics & Decay
*   **IV. Decentralized Skill Bounties**
    *   Bounty Lifecycle (Creation, Application, Submission, Verification, Resolution)
*   **V. AI Oracle & External Data Integration**
    *   Oracle Management & Callback Handling
    *   Contextual Analysis Triggers
*   **VI. Knowledge & Credential Linking**
    *   On-chain Knowledge Module Indexing
    *   Verifiable Credential (VC) Linking
*   **VII. Query & Utility Functions**
    *   Information Retrieval for Profiles, Skills, Bounties

**Function Summary:**

1.  **`constructor()`**: Initializes the contract, setting up initial parameters.
2.  **`pause()`**: Pauses contract operations in emergencies (Owner only).
3.  **`unpause()`**: Resumes contract operations (Owner only).
4.  **`emergencyWithdrawERC20()`**: Allows owner to withdraw stuck ERC-20 tokens (Owner only).
5.  **`registerSkillProfile()`**: Mints a new Adaptive Skill Soulbound Token (ASSBT) for a user, creating their initial profile.
6.  **`updateProfileAttribute()`**: Allows a user to update *non-attested* profile attributes or link external profiles.
7.  **`setProfileVisibility()`**: Allows a user to control the public visibility of specific profile data points.
8.  **`defineSkillCategory()`**: Owner defines new skill categories (e.g., "Web Development", "AI/ML", "Design").
9.  **`attestSkillProficiency()`**: A user (or authorized attester) provides an on-chain attestation for another user's skill, including a proficiency score.
10. **`requestOracleSkillEvaluation()`**: Triggers an AI oracle request to evaluate a specific skill or proof, potentially adjusting a user's ASSBT.
11. **`fulfillOracleSkillEvaluation()`**: Callback function for the AI oracle to report evaluation results, dynamically updating the ASSBT.
12. **`proposeSkillBounty()`**: A user creates a decentralized bounty, specifying required skills, reward, and a deadline.
13. **`applyForSkillBounty()`**: A user with the required skills applies to complete a bounty.
14. **`submitBountyProof()`**: The bounty applicant submits proof of completion (e.g., IPFS hash of work, GitHub commit hash).
15. **`verifyBountyCompletion()`**: The bounty creator (or a designated verifier/oracle) verifies the submitted proof. If valid, reward is disbursed, and skills/reputation are updated.
16. **`raiseBountyDispute()`**: Allows either party to raise a dispute over bounty completion, triggering a resolution process.
17. **`resolveBountyDispute()`**: Owner/governance resolves a disputed bounty, potentially based on a vote or external arbitration.
18. **`triggerReputationDecay()`**: A callable function (e.g., by a keeper network) that periodically applies reputation decay to all active profiles.
19. **`linkVerifiableCredential()`**: Allows a user to link a hash or URI of an off-chain Verifiable Credential (VC) to their ASSBT for added trust.
20. **`addKnowledgeModuleRef()`**: Owner adds a reference to an on-chain or off-chain knowledge module (e.g., a tutorial, course) that can be linked to skills.
21. **`attestKnowledgeModuleCompletion()`**: A user can attest to completing a knowledge module, potentially earning a minor skill boost or badge.
22. **`querySkillProfile()`**: A view function to retrieve a user's full skill profile and ASSBT data.
23. **`querySkillAttestations()`**: A view function to get all attestations for a specific skill for a user.
24. **`queryBountyDetails()`**: A view function to retrieve all details of a specific bounty.
25. **`withdrawBountyFunds()`**: Allows the bounty creator to withdraw remaining funds if a bounty expires or is cancelled.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For bounty rewards

// Note: For a real-world AI Oracle integration, you would typically use Chainlink Functions,
// custom off-chain workers, or other oracle networks. This contract provides the *interface*
// for such interactions, but the actual off-chain AI logic is external.

/**
 * @title CogniGraphNexus
 * @dev A decentralized protocol for Adaptive, Interconnected Skill & Reputation Profiles
 *      powered by On-Chain Attestation, Contextual AI Oracles, and Dynamic Soulbound Tokens (SBTs).
 *
 * Outline:
 *   I. Core Infrastructure & Access Control
 *   II. Adaptive Skill Soulbound Token (ASSBT) Management
 *   III. Skill & Reputation System
 *   IV. Decentralized Skill Bounties
 *   V. AI Oracle & External Data Integration
 *   VI. Knowledge & Credential Linking
 *   VII. Query & Utility Functions
 *
 * Function Summary:
 *   1.  constructor(): Initializes the contract, setting up initial parameters.
 *   2.  pause(): Pauses contract operations in emergencies (Owner only).
 *   3.  unpause(): Resumes contract operations (Owner only).
 *   4.  emergencyWithdrawERC20(): Allows owner to withdraw stuck ERC-20 tokens (Owner only).
 *   5.  registerSkillProfile(): Mints a new Adaptive Skill Soulbound Token (ASSBT) for a user, creating their initial profile.
 *   6.  updateProfileAttribute(): Allows a user to update non-attested profile attributes or link external profiles.
 *   7.  setProfileVisibility(): Allows a user to control the public visibility of specific profile data points.
 *   8.  defineSkillCategory(): Owner defines new skill categories (e.g., "Web Development", "AI/ML").
 *   9.  attestSkillProficiency(): A user (or authorized attester) provides an on-chain attestation for another user's skill.
 *   10. requestOracleSkillEvaluation(): Triggers an AI oracle request to evaluate a skill or proof, potentially adjusting an ASSBT.
 *   11. fulfillOracleSkillEvaluation(): Callback for the AI oracle to report evaluation results, dynamically updating the ASSBT.
 *   12. proposeSkillBounty(): A user creates a decentralized bounty, specifying required skills, reward, and deadline.
 *   13. applyForSkillBounty(): A user with required skills applies to complete a bounty.
 *   14. submitBountyProof(): The bounty applicant submits proof of completion (e.g., IPFS hash of work).
 *   15. verifyBountyCompletion(): The bounty creator (or a designated verifier/oracle) verifies the submitted proof.
 *   16. raiseBountyDispute(): Allows either party to raise a dispute over bounty completion.
 *   17. resolveBountyDispute(): Owner/governance resolves a disputed bounty.
 *   18. triggerReputationDecay(): Periodically applies reputation decay to all active profiles.
 *   19. linkVerifiableCredential(): Allows a user to link a hash/URI of an off-chain Verifiable Credential (VC) to their ASSBT.
 *   20. addKnowledgeModuleRef(): Owner adds a reference to an on-chain or off-chain knowledge module.
 *   21. attestKnowledgeModuleCompletion(): A user can attest to completing a knowledge module.
 *   22. querySkillProfile(): A view function to retrieve a user's full skill profile and ASSBT data.
 *   23. querySkillAttestations(): A view function to get all attestations for a specific skill for a user.
 *   24. queryBountyDetails(): A view function to retrieve all details of a specific bounty.
 *   25. withdrawBountyFunds(): Allows bounty creator to withdraw remaining funds if a bounty expires/cancelled.
 */
contract CogniGraphNexus is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _skillCategoryCounter;
    Counters.Counter private _bountyCounter;
    Counters.Counter private _knowledgeModuleCounter;

    // --- I. Core Infrastructure & Access Control ---

    // Modifier to restrict functions to authorized oracle addresses
    mapping(address => bool) public isOracleAddress;
    address public trustedSkillVerifier; // A single trusted address for certain attestations/disputes (can be replaced by DAO later)

    event OracleAddressSet(address indexed oracle, bool status);
    event TrustedSkillVerifierSet(address indexed verifier);

    modifier onlyOracle() {
        require(isOracleAddress(msg.sender), "CGN: Caller is not an authorized oracle");
        _;
    }

    modifier onlyTrustedVerifier() {
        require(msg.sender == trustedSkillVerifier, "CGN: Caller is not the trusted verifier");
        _;
    }

    constructor(address _initialTrustedVerifier)
        ERC721("CogniGraph Adaptive Skill Token", "ASSBT")
        Ownable(msg.sender) // Initialize Ownable with deployer as owner
    {
        trustedSkillVerifier = _initialTrustedVerifier;
    }

    /**
     * @dev Sets an address as an authorized oracle.
     * @param _oracle The address to set/unset as an oracle.
     * @param _status True to authorize, false to deauthorize.
     */
    function setOracleAddress(address _oracle, bool _status) public onlyOwner {
        isOracleAddress[_oracle] = _status;
        emit OracleAddressSet(_oracle, _status);
    }

    /**
     * @dev Sets the trusted skill verifier address. This address can perform certain high-privilege attestations.
     * @param _verifier The address to set as the trusted verifier.
     */
    function setTrustedSkillVerifier(address _verifier) public onlyOwner {
        trustedSkillVerifier = _verifier;
        emit TrustedSkillVerifierSet(_verifier);
    }

    /**
     * @dev Pauses the contract. Can only be called by the owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Can only be called by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows owner to withdraw stuck ERC-20 tokens from the contract.
     * Useful if ERC-20s are accidentally sent here or if bounty funds need to be recovered after a critical error.
     * @param _token The address of the ERC-20 token.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawERC20(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    // --- II. Adaptive Skill Soulbound Token (ASSBT) Management ---

    // A unique token ID for each user's profile. Soulbound by preventing transfer.
    mapping(address => uint256) public userToTokenId;
    mapping(uint256 => SkillProfile) public tokenIdToProfile;

    struct SkillProfile {
        address owner;
        uint256 tokenId;
        uint256 reputationScore; // Overall reputation based on attestations, bounties
        uint256 lastActivityTimestamp;
        mapping(bytes32 => string) dynamicAttributes; // General purpose key-value for dynamic data (e.g., "bio", "external_link")
        mapping(bytes32 => uint8) profileVisibility; // 0: Private, 1: Public, 2: Attesters-only
        bool isActive; // Allows deactivation instead of burning Soulbound Tokens
        uint256[] activeBounties; // Bounty IDs currently being worked on
        uint256[] completedBounties; // Bounty IDs successfully completed
    }

    enum AttributeVisibility { PRIVATE, PUBLIC, ATTESTERS_ONLY }

    event SkillProfileRegistered(address indexed user, uint256 indexed tokenId);
    event ProfileAttributeUpdated(uint256 indexed tokenId, bytes32 indexed attributeKey, string newValue);
    event ProfileVisibilitySet(uint256 indexed tokenId, bytes32 indexed attributeKey, AttributeVisibility visibility);
    event ProfileDeactivated(uint256 indexed tokenId);
    event ProfileActivated(uint256 indexed tokenId);

    /**
     * @dev Mints a new Adaptive Skill Soulbound Token (ASSBT) for the caller, creating their initial profile.
     * Each user can only have one ASSBT.
     */
    function registerSkillProfile() public whenNotPaused {
        require(userToTokenId[msg.sender] == 0, "CGN: User already has a skill profile");

        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked("ipfs://initial_profile/", Strings.toString(newTokenId)))); // Placeholder URI

        // Initialize the skill profile
        SkillProfile storage profile = tokenIdToProfile[newTokenId];
        profile.owner = msg.sender;
        profile.tokenId = newTokenId;
        profile.reputationScore = 0;
        profile.lastActivityTimestamp = block.timestamp;
        profile.isActive = true;

        userToTokenId[msg.sender] = newTokenId;

        // Set default public attributes
        profile.profileVisibility["bio"] = uint8(AttributeVisibility.PUBLIC);
        profile.profileVisibility["external_link"] = uint8(AttributeVisibility.PUBLIC);

        emit SkillProfileRegistered(msg.sender, newTokenId);
    }

    /**
     * @dev Allows a user to update their custom dynamic attributes in their skill profile.
     * This is for self-reported or general purpose data, not skill attestations.
     * @param _attributeKey The key for the attribute (e.g., "bio", "linkedin_url").
     * @param _newValue The new string value for the attribute.
     */
    function updateProfileAttribute(bytes32 _attributeKey, string calldata _newValue) public whenNotPaused {
        uint256 tokenId = userToTokenId[msg.sender];
        require(tokenId != 0, "CGN: No skill profile found for caller");

        tokenIdToProfile[tokenId].dynamicAttributes[_attributeKey] = _newValue;
        tokenIdToProfile[tokenId].lastActivityTimestamp = block.timestamp; // Update activity

        // Update token URI to reflect dynamic data.
        // In a real dApp, this would likely point to an API that generates metadata based on on-chain state.
        // For simplicity, we just update the base URI or a specific metadata field.
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(tokenId))));

        emit ProfileAttributeUpdated(tokenId, _attributeKey, _newValue);
    }

    /**
     * @dev Allows a user to set the visibility of a specific profile attribute.
     * @param _attributeKey The key of the attribute whose visibility is being set.
     * @param _visibility The desired visibility (0: Private, 1: Public, 2: Attesters-only).
     */
    function setProfileVisibility(bytes32 _attributeKey, AttributeVisibility _visibility) public whenNotPaused {
        uint256 tokenId = userToTokenId[msg.sender];
        require(tokenId != 0, "CGN: No skill profile found for caller");

        tokenIdToProfile[tokenId].profileVisibility[_attributeKey] = uint8(_visibility);
        emit ProfileVisibilitySet(tokenId, _attributeKey, _visibility);
    }

    /**
     * @dev Deactivates a user's skill profile, making it inactive and non-queryable in certain contexts.
     * Soulbound tokens cannot be transferred or burned; deactivation is the closest equivalent.
     * @param _tokenId The ID of the profile to deactivate.
     */
    function deactivateSkillProfile(uint256 _tokenId) public {
        require(tokenIdToProfile[_tokenId].owner == msg.sender, "CGN: Not your profile to deactivate");
        require(tokenIdToProfile[_tokenId].isActive, "CGN: Profile already inactive");
        tokenIdToProfile[_tokenId].isActive = false;
        emit ProfileDeactivated(_tokenId);
    }

    /**
     * @dev Reactivates a user's skill profile.
     * @param _tokenId The ID of the profile to activate.
     */
    function activateSkillProfile(uint256 _tokenId) public {
        require(tokenIdToProfile[_tokenId].owner == msg.sender, "CGN: Not your profile to activate");
        require(!tokenIdToProfile[_tokenId].isActive, "CGN: Profile already active");
        tokenIdToProfile[_tokenId].isActive = true;
        emit ProfileActivated(_tokenId);
    }

    // Override the ERC721 transfer functions to enforce soulbound nature
    function _approve(address to, uint256 tokenId) internal override {
        revert("CGN: ASSBTs are soulbound and cannot be transferred");
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        revert("CGN: ASSBTs are soulbound and cannot be transferred");
    }

    // --- III. Skill & Reputation System ---

    struct SkillInfo {
        uint256 id;
        string name;
        string description;
        uint256 categoryId;
        address defaultVerifier; // Optional: A specific address often verifying this skill
    }

    struct SkillCategory {
        uint256 id;
        string name;
        string description;
    }

    struct SkillAttestation {
        address attester;
        uint256 skillId;
        uint8 proficiencyScore; // 0-100 scale
        uint256 timestamp;
        string contextHash; // IPFS hash of proof or context
        bool revoked; // If attestation was disputed and revoked
    }

    mapping(uint256 => SkillInfo) public skillIdToInfo; // All defined skills
    mapping(uint256 => SkillCategory) public skillCategoryIdToInfo; // All defined skill categories

    // Stores attestations for a specific user (tokenId) and skill (skillId)
    mapping(uint256 => mapping(uint256 => SkillAttestation[])) public userSkillAttestations;

    event SkillCategoryDefined(uint256 indexed categoryId, string name);
    event SkillDefined(uint256 indexed skillId, string name, uint256 indexed categoryId);
    event SkillAttested(uint256 indexed tokenId, uint256 indexed skillId, address indexed attester, uint8 proficiency);
    event SkillAttestationRevoked(uint256 indexed tokenId, uint256 indexed skillId, address indexed attester, string reason);
    event ReputationUpdated(uint256 indexed tokenId, uint256 oldScore, uint256 newScore);

    /**
     * @dev Owner defines a new skill category.
     * @param _name The name of the skill category (e.g., "Blockchain Development").
     * @param _description A description of the category.
     */
    function defineSkillCategory(string calldata _name, string calldata _description) public onlyOwner {
        uint256 newCategoryId = _skillCategoryCounter.current();
        _skillCategoryCounter.increment();
        skillCategoryIdToInfo[newCategoryId] = SkillCategory(newCategoryId, _name, _description);
        emit SkillCategoryDefined(newCategoryId, _name);
    }

    /**
     * @dev Defines a new specific skill within a category.
     * @param _name The name of the skill (e.g., "Solidity Programming").
     * @param _description Description of the skill.
     * @param _categoryId The ID of the category this skill belongs to.
     * @param _defaultVerifier Optional: a trusted address usually verifying this skill.
     */
    function defineSkill(
        string calldata _name,
        string calldata _description,
        uint256 _categoryId,
        address _defaultVerifier
    ) public onlyOwner {
        require(skillCategoryIdToInfo[_categoryId].id == _categoryId, "CGN: Invalid skill category ID");

        uint256 newSkillId = _skillCategoryCounter.current(); // Reusing counter for simplicity for unique IDs
        _skillCategoryCounter.increment(); // Ensure unique IDs
        skillIdToInfo[newSkillId] = SkillInfo(newSkillId, _name, _description, _categoryId, _defaultVerifier);
        emit SkillDefined(newSkillId, _name, _categoryId);
    }

    /**
     * @dev Allows an authorized attester (user with a profile, trusted verifier, or oracle)
     * to attest to another user's skill proficiency.
     * Improves target's reputation and adds an attestation record.
     * @param _targetTokenId The tokenId of the user whose skill is being attested.
     * @param _skillId The ID of the skill being attested.
     * @param _proficiencyScore The proficiency score (0-100).
     * @param _contextHash IPFS hash or similar pointing to proof/context of attestation.
     */
    function attestSkillProficiency(
        uint256 _targetTokenId,
        uint256 _skillId,
        uint8 _proficiencyScore,
        string calldata _contextHash
    ) public whenNotPaused {
        require(tokenIdToProfile[_targetTokenId].isActive, "CGN: Target profile is inactive");
        require(skillIdToInfo[_skillId].id == _skillId, "CGN: Invalid skill ID");
        require(_proficiencyScore <= 100, "CGN: Proficiency score must be 0-100");

        address attesterAddress = msg.sender;
        uint256 attesterTokenId = userToTokenId[attesterAddress];

        // Ensure attester is valid: either has an active profile, is a trusted verifier, or an oracle
        require(
            (attesterTokenId != 0 && tokenIdToProfile[attesterTokenId].isActive) ||
            attesterAddress == trustedSkillVerifier ||
            isOracleAddress[attesterAddress],
            "CGN: Caller is not an authorized attester"
        );
        require(attesterAddress != tokenIdToProfile[_targetTokenId].owner, "CGN: Cannot self-attest skills");

        // Add the attestation
        userSkillAttestations[_targetTokenId][_skillId].push(
            SkillAttestation({
                attester: attesterAddress,
                skillId: _skillId,
                proficiencyScore: _proficiencyScore,
                timestamp: block.timestamp,
                contextHash: _contextHash,
                revoked: false
            })
        );

        // Update target's reputation score (simple linear increase for now, can be weighted later)
        SkillProfile storage targetProfile = tokenIdToProfile[_targetTokenId];
        uint256 oldReputation = targetProfile.reputationScore;
        targetProfile.reputationScore += _proficiencyScore / 10; // Example: 100 score gives 10 reputation
        targetProfile.lastActivityTimestamp = block.timestamp; // Update activity
        emit ReputationUpdated(_targetTokenId, oldReputation, targetProfile.reputationScore);

        // Update token URI to reflect dynamic data.
        _setTokenURI(_targetTokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(_targetTokenId))));

        emit SkillAttested(_targetTokenId, _skillId, attesterAddress, _proficiencyScore);
    }

    /**
     * @dev Allows the trusted verifier or owner to revoke an attestation, typically in case of dispute or fraud.
     * @param _targetTokenId The tokenId of the user whose attestation is being revoked.
     * @param _skillId The ID of the skill.
     * @param _attester The address of the original attester.
     * @param _index The index of the attestation in the array (careful with this, array modification can be tricky).
     * @param _reason A string explaining the reason for revocation.
     */
    function revokeSkillAttestation(
        uint256 _targetTokenId,
        uint256 _skillId,
        address _attester,
        uint256 _index,
        string calldata _reason
    ) public whenNotPaused onlyTrustedVerifier {
        require(tokenIdToProfile[_targetTokenId].isActive, "CGN: Target profile is inactive");
        require(userSkillAttestations[_targetTokenId][_skillId].length > _index, "CGN: Attestation index out of bounds");
        SkillAttestation storage attestation = userSkillAttestations[_targetTokenId][_skillId][_index];
        require(attestation.attester == _attester, "CGN: Attester mismatch for this index");
        require(!attestation.revoked, "CGN: Attestation already revoked");

        attestation.revoked = true;

        // Optionally, reduce reputation score upon revocation
        SkillProfile storage targetProfile = tokenIdToProfile[_targetTokenId];
        uint256 oldReputation = targetProfile.reputationScore;
        if (targetProfile.reputationScore >= attestation.proficiencyScore / 10) {
            targetProfile.reputationScore -= attestation.proficiencyScore / 10;
        } else {
            targetProfile.reputationScore = 0;
        }
        emit ReputationUpdated(_targetTokenId, oldReputation, targetProfile.reputationScore);
        emit SkillAttestationRevoked(_targetTokenId, _skillId, _attester, _reason);

        // Update token URI to reflect dynamic data.
        _setTokenURI(_targetTokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(_targetTokenId))));
    }

    /**
     * @dev Triggers periodic reputation decay for all *active* profiles that haven't been active recently.
     * Can be called by anyone (e.g., a keeper network) to keep reputation scores current.
     * @param _tokenId The ID of the profile to process.
     * @param _decayFactor Percentage decay (e.g., 5 for 5%)
     * @param _decayPeriod Seconds representing how often decay should apply (e.g., 30 days)
     */
    function triggerReputationDecay(uint256 _tokenId, uint256 _decayFactor, uint256 _decayPeriod) public whenNotPaused {
        SkillProfile storage profile = tokenIdToProfile[_tokenId];
        require(profile.isActive, "CGN: Profile is inactive");

        uint256 secondsSinceLastActivity = block.timestamp - profile.lastActivityTimestamp;

        // Apply decay if enough time has passed since last activity and profile is not at 0
        if (secondsSinceLastActivity >= _decayPeriod && profile.reputationScore > 0) {
            uint256 oldReputation = profile.reputationScore;
            profile.reputationScore = profile.reputationScore * (100 - _decayFactor) / 100;
            // Ensure minimum reputation to prevent it from going to absolute zero and never recovering
            if (profile.reputationScore < 10 && oldReputation >= 10) { // Set a floor if it was higher before decay
                profile.reputationScore = 1;
            } else if (oldReputation == 0) {
                 profile.reputationScore = 0; // If already 0, keep it 0
            }


            profile.lastActivityTimestamp = block.timestamp; // Reset activity to prevent immediate re-decay
            emit ReputationUpdated(_tokenId, oldReputation, profile.reputationScore);

            // Update token URI to reflect dynamic data.
            _setTokenURI(_tokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(_tokenId))));
        }
    }


    // --- IV. Decentralized Skill Bounties ---

    enum BountyStatus { OPEN, APPLIED, SUBMITTED, PENDING_VERIFICATION, COMPLETED, DISPUTED, CANCELLED }

    struct Bounty {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256[] requiredSkillIds; // IDs of skills needed for this bounty
        uint256 rewardAmount; // Amount in ERC-20
        address rewardToken; // Address of the ERC-20 token
        uint256 deadline;
        address applicant; // Address of the user who applied
        string submissionProofHash; // IPFS hash of the submitted work
        BountyStatus status;
        uint256 creationTimestamp;
        bool disputeRaised;
    }

    mapping(uint256 => Bounty) public bountyIdToBounty;

    event BountyProposed(uint256 indexed bountyId, address indexed creator, uint256 rewardAmount, address rewardToken);
    event BountyApplied(uint256 indexed bountyId, address indexed applicant);
    event BountyProofSubmitted(uint256 indexed bountyId, address indexed applicant, string proofHash);
    event BountyVerified(uint256 indexed bountyId, address indexed verifier);
    event BountyCompleted(uint256 indexed bountyId, address indexed beneficiary, uint256 reward);
    event BountyDisputeRaised(uint256 indexed bountyId);
    event BountyDisputeResolved(uint256 indexed bountyId, bool creatorWins);
    event BountyCancelled(uint256 indexed bountyId);
    event BountyFundsWithdrawn(uint256 indexed bountyId, uint256 amount);


    /**
     * @dev Proposes a new skill bounty. Requires the reward amount in the specified ERC-20 token.
     * @param _title The title of the bounty.
     * @param _description Description of the bounty.
     * @param _requiredSkillIds Array of skill IDs required to apply.
     * @param _rewardAmount The amount of ERC-20 tokens to reward.
     * @param _rewardToken The address of the ERC-20 token for the reward.
     * @param _deadlineTimestamp The timestamp by which the bounty must be completed.
     */
    function proposeSkillBounty(
        string calldata _title,
        string calldata _description,
        uint256[] calldata _requiredSkillIds,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256 _deadlineTimestamp
    ) public payable whenNotPaused {
        require(_deadlineTimestamp > block.timestamp, "CGN: Deadline must be in the future");
        require(_rewardAmount > 0, "CGN: Reward amount must be greater than zero");
        require(userToTokenId[msg.sender] != 0, "CGN: Creator must have a skill profile");

        // Transfer ERC-20 reward from creator to contract
        IERC20(_rewardToken).transferFrom(msg.sender, address(this), _rewardAmount);

        uint256 newBountyId = _bountyCounter.current();
        _bountyCounter.increment();

        Bounty storage newBounty = bountyIdToBounty[newBountyId];
        newBounty.id = newBountyId;
        newBounty.creator = msg.sender;
        newBounty.title = _title;
        newBounty.description = _description;
        newBounty.requiredSkillIds = _requiredSkillIds;
        newBounty.rewardAmount = _rewardAmount;
        newBounty.rewardToken = _rewardToken;
        newBounty.deadline = _deadlineTimestamp;
        newBounty.status = BountyStatus.OPEN;
        newBounty.creationTimestamp = block.timestamp;
        newBounty.disputeRaised = false;

        emit BountyProposed(newBountyId, msg.sender, _rewardAmount, _rewardToken);
    }

    /**
     * @dev Allows a user to apply for an open bounty.
     * Requires the applicant to have an active skill profile and meet the required skills.
     * @param _bountyId The ID of the bounty to apply for.
     */
    function applyForSkillBounty(uint256 _bountyId) public whenNotPaused {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.creator != address(0), "CGN: Bounty does not exist");
        require(bounty.status == BountyStatus.OPEN, "CGN: Bounty is not open for applications");
        require(block.timestamp < bounty.deadline, "CGN: Bounty has expired");
        require(userToTokenId[msg.sender] != 0 && tokenIdToProfile[userToTokenId[msg.sender]].isActive, "CGN: Applicant must have an active skill profile");
        require(bounty.applicant == address(0), "CGN: Bounty already has an applicant");

        // Basic check for required skills (can be enhanced with proficiency levels later)
        uint256 applicantTokenId = userToTokenId[msg.sender];
        for (uint256 i = 0; i < bounty.requiredSkillIds.length; i++) {
            uint256 skillId = bounty.requiredSkillIds[i];
            bool hasSkill = false;
            for (uint256 j = 0; j < userSkillAttestations[applicantTokenId][skillId].length; j++) {
                if (userSkillAttestations[applicantTokenId][skillId][j].proficiencyScore >= 50 && !userSkillAttestations[applicantTokenId][skillId][j].revoked) { // Example: need at least 50 proficiency
                    hasSkill = true;
                    break;
                }
            }
            require(hasSkill, "CGN: Applicant does not meet required skill proficiency for this bounty");
        }

        bounty.applicant = msg.sender;
        bounty.status = BountyStatus.APPLIED;
        tokenIdToProfile[applicantTokenId].activeBounties.push(_bountyId); // Add bounty to user's active list
        emit BountyApplied(_bountyId, msg.sender);
    }

    /**
     * @dev Allows the applicant to submit proof of completion for a bounty.
     * @param _bountyId The ID of the bounty.
     * @param _proofHash IPFS hash or URL pointing to the completed work.
     */
    function submitBountyProof(uint256 _bountyId, string calldata _proofHash) public whenNotPaused {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.applicant == msg.sender, "CGN: Only the assigned applicant can submit proof");
        require(bounty.status == BountyStatus.APPLIED, "CGN: Bounty is not in 'Applied' status");
        require(block.timestamp < bounty.deadline, "CGN: Bounty deadline has passed");

        bounty.submissionProofHash = _proofHash;
        bounty.status = BountyStatus.SUBMITTED;
        emit BountyProofSubmitted(_bountyId, msg.sender, _proofHash);
    }

    /**
     * @dev Allows the bounty creator (or a designated verifier/oracle) to verify the submitted proof.
     * If valid, rewards are disbursed, and reputation/skills are updated.
     * @param _bountyId The ID of the bounty.
     * @param _isSuccess True if verification is successful, false if rejected.
     */
    function verifyBountyCompletion(uint256 _bountyId, bool _isSuccess) public whenNotPaused {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.creator == msg.sender || isOracleAddress[msg.sender] || trustedSkillVerifier == msg.sender, "CGN: Only creator, oracle, or trusted verifier can verify");
        require(bounty.status == BountyStatus.SUBMITTED || bounty.status == BountyStatus.PENDING_VERIFICATION, "CGN: Bounty not in a verifiable state");
        require(bounty.applicant != address(0), "CGN: No applicant for this bounty");

        if (_isSuccess) {
            // Transfer reward to applicant
            IERC20(bounty.rewardToken).transfer(bounty.applicant, bounty.rewardAmount);
            bounty.status = BountyStatus.COMPLETED;

            // Update applicant's reputation and completed bounties
            uint256 applicantTokenId = userToTokenId[bounty.applicant];
            SkillProfile storage applicantProfile = tokenIdToProfile[applicantTokenId];
            uint256 oldReputation = applicantProfile.reputationScore;
            applicantProfile.reputationScore += 50; // Example: Flat reputation boost for completion
            applicantProfile.lastActivityTimestamp = block.timestamp;
            applicantProfile.completedBounties.push(_bountyId);

            // Remove from active bounties
            for (uint256 i = 0; i < applicantProfile.activeBounties.length; i++) {
                if (applicantProfile.activeBounties[i] == _bountyId) {
                    applicantProfile.activeBounties[i] = applicantProfile.activeBounties[applicantProfile.activeBounties.length - 1];
                    applicantProfile.activeBounties.pop();
                    break;
                }
            }
            emit ReputationUpdated(applicantTokenId, oldReputation, applicantProfile.reputationScore);
            emit BountyVerified(_bountyId, msg.sender);
            emit BountyCompleted(_bountyId, bounty.applicant, bounty.rewardAmount);

            // Update token URI to reflect dynamic data.
            _setTokenURI(applicantTokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(applicantTokenId))));

        } else {
            // Rejection: Bounty goes back to APPLIED or OPEN, or a new status like REJECTED
            bounty.status = BountyStatus.APPLIED; // Or a specific 'REJECTED_SUBMISSION' status
            emit BountyVerified(_bountyId, msg.sender); // Indicate it was verified (as rejected)
        }
    }

    /**
     * @dev Allows either the creator or applicant to raise a dispute if they disagree with verification.
     * Only callable after a submission has been made and before it's completed or cancelled.
     * @param _bountyId The ID of the bounty.
     */
    function raiseBountyDispute(uint256 _bountyId) public whenNotPaused {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.creator != address(0), "CGN: Bounty does not exist");
        require(bounty.status == BountyStatus.SUBMITTED || bounty.status == BountyStatus.PENDING_VERIFICATION, "CGN: Bounty is not in a dispute-eligible status");
        require(bounty.applicant == msg.sender || bounty.creator == msg.sender, "CGN: Only creator or applicant can raise a dispute");
        require(!bounty.disputeRaised, "CGN: Dispute already raised for this bounty");

        bounty.disputeRaised = true;
        bounty.status = BountyStatus.DISPUTED;
        emit BountyDisputeRaised(_bountyId);
    }

    /**
     * @dev Resolves a bounty dispute. Can only be called by the trusted verifier or contract owner.
     * @param _bountyId The ID of the bounty.
     * @param _creatorWins True if the dispute is resolved in favor of the creator (i.e., applicant gets no reward), false if applicant wins.
     */
    function resolveBountyDispute(uint256 _bountyId, bool _creatorWins) public whenNotPaused onlyTrustedVerifier {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.creator != address(0), "CGN: Bounty does not exist");
        require(bounty.status == BountyStatus.DISPUTED, "CGN: Bounty is not in dispute");

        if (_creatorWins) {
            // Creator wins, applicant does not get reward
            bounty.status = BountyStatus.CANCELLED; // Or a specific 'RESOLVED_CREATOR_WINS' status
            // Funds remain in contract until creator withdraws them via withdrawBountyFunds()
        } else {
            // Applicant wins, disburse reward
            IERC20(bounty.rewardToken).transfer(bounty.applicant, bounty.rewardAmount);
            bounty.status = BountyStatus.COMPLETED;

            // Update applicant's reputation and completed bounties
            uint256 applicantTokenId = userToTokenId[bounty.applicant];
            SkillProfile storage applicantProfile = tokenIdToProfile[applicantTokenId];
            uint256 oldReputation = applicantProfile.reputationScore;
            applicantProfile.reputationScore += 50; // Example: Flat reputation boost for completion
            applicantProfile.lastActivityTimestamp = block.timestamp;
            applicantProfile.completedBounties.push(_bountyId);

            // Remove from active bounties
            for (uint256 i = 0; i < applicantProfile.activeBounties.length; i++) {
                if (applicantProfile.activeBounties[i] == _bountyId) {
                    applicantProfile.activeBounties[i] = applicantProfile.activeBounties[applicantProfile.activeBounties.length - 1];
                    applicantProfile.activeBounties.pop();
                    break;
                }
            }
            emit ReputationUpdated(applicantTokenId, oldReputation, applicantProfile.reputationScore);

            // Update token URI to reflect dynamic data.
            _setTokenURI(applicantTokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(applicantTokenId))));
        }

        emit BountyDisputeResolved(_bountyId, _creatorWins);
    }

    /**
     * @dev Allows the bounty creator to withdraw remaining funds if bounty is cancelled or expired without completion.
     * @param _bountyId The ID of the bounty.
     */
    function withdrawBountyFunds(uint256 _bountyId) public whenNotPaused {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.creator == msg.sender, "CGN: Only bounty creator can withdraw funds");
        require(bounty.status == BountyStatus.CANCELLED ||
                (bounty.status != BountyStatus.COMPLETED && block.timestamp >= bounty.deadline && !bounty.disputeRaised),
                "CGN: Bounty not eligible for withdrawal (active, completed, or disputed)");

        uint256 amountToWithdraw = bounty.rewardAmount;
        bounty.rewardAmount = 0; // Prevent double withdrawal
        IERC20(bounty.rewardToken).transfer(msg.sender, amountToWithdraw);
        emit BountyFundsWithdrawn(_bountyId, amountToWithdraw);
    }

    // --- V. AI Oracle & External Data Integration ---

    // This section defines the *interface* for an AI oracle.
    // Real implementation would involve Chainlink VRF/Functions or a dedicated off-chain worker.

    bytes32 private latestOracleRequestId; // For tracking a single, latest request
    address public latestOracleRequester; // For tracking who requested it

    event OracleRequestSent(bytes32 indexed requestId, uint256 indexed tokenId, uint256 indexed skillId, string dataToEvaluate);
    event OracleResponseReceived(bytes32 indexed requestId, uint256 indexed tokenId, uint256 indexed skillId, uint8 evaluationScore, string metadata);

    /**
     * @dev Requests an AI oracle to evaluate a specific skill or data point for a user's profile.
     * Can be triggered by owner, trusted verifier, or the profile owner for self-evaluation.
     * @param _targetTokenId The ID of the user's profile to evaluate.
     * @param _skillId The specific skill ID to evaluate context for.
     * @param _dataToEvaluate A hash/URI pointing to the data (e.g., code repository, document) for AI analysis.
     */
    function requestOracleSkillEvaluation(uint256 _targetTokenId, uint256 _skillId, string calldata _dataToEvaluate) public whenNotPaused {
        require(tokenIdToProfile[_targetTokenId].isActive, "CGN: Target profile is inactive");
        require(msg.sender == owner() || msg.sender == trustedSkillVerifier || tokenIdToProfile[_targetTokenId].owner == msg.sender, "CGN: Unauthorized requester");

        // In a real scenario, this would send a request to a Chainlink or similar oracle contract
        // which would then callback to fulfillOracleSkillEvaluation
        latestOracleRequestId = bytes32(uint256(keccak256(abi.encodePacked(_targetTokenId, _skillId, block.timestamp)))); // Mock ID
        latestOracleRequester = msg.sender;

        emit OracleRequestSent(latestOracleRequestId, _targetTokenId, _skillId, _dataToEvaluate);
    }

    /**
     * @dev Callback function to receive the result from an AI oracle.
     * Only callable by an authorized oracle address. Updates the user's skill proficiency.
     * @param _requestId The ID of the original request.
     * @param _tokenId The ID of the user's profile.
     * @param _skillId The ID of the skill that was evaluated.
     * @param _evaluationScore The score provided by the AI (e.g., 0-100 proficiency).
     * @param _metadata Additional metadata from the oracle (e.g., explanation, confidence score).
     */
    function fulfillOracleSkillEvaluation(
        bytes32 _requestId,
        uint256 _tokenId,
        uint256 _skillId,
        uint8 _evaluationScore,
        string calldata _metadata
    ) public whenNotPaused onlyOracle {
        // In a real oracle setup, you'd verify _requestId matches an active request.
        // For simplicity, we assume the oracle is trusted and provides valid data.
        require(_evaluationScore <= 100, "CGN: Evaluation score must be 0-100");
        require(tokenIdToProfile[_tokenId].isActive, "CGN: Target profile is inactive");
        require(skillIdToInfo[_skillId].id == _skillId, "CGN: Invalid skill ID");

        // Similar to manual attestation, but from an oracle
        userSkillAttestations[_tokenId][_skillId].push(
            SkillAttestation({
                attester: msg.sender, // The oracle address
                skillId: _skillId,
                proficiencyScore: _evaluationScore,
                timestamp: block.timestamp,
                contextHash: _metadata, // Oracle's specific metadata
                revoked: false
            })
        );

        // Update reputation based on oracle's score
        SkillProfile storage targetProfile = tokenIdToProfile[_tokenId];
        uint256 oldReputation = targetProfile.reputationScore;
        targetProfile.reputationScore += _evaluationScore / 5; // AI evaluation gives more reputation? Example
        targetProfile.lastActivityTimestamp = block.timestamp;
        emit ReputationUpdated(_tokenId, oldReputation, targetProfile.reputationScore);

        // Update token URI to reflect dynamic data.
        _setTokenURI(_tokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(_tokenId))));

        emit OracleResponseReceived(_requestId, _tokenId, _skillId, _evaluationScore, _metadata);
    }

    // --- VI. Knowledge & Credential Linking ---

    struct KnowledgeModule {
        uint256 id;
        string title;
        string contentHash; // IPFS hash of the educational content
        uint256[] associatedSkillIds; // Skills that this module helps develop
        uint256 creationTimestamp;
    }

    // Mapping for knowledge modules
    mapping(uint256 => KnowledgeModule) public knowledgeModuleIdToInfo;

    // Mapping to track which users have attested to completing which knowledge modules
    mapping(uint256 => mapping(uint256 => bool)) public userCompletedKnowledgeModule; // tokenId => moduleId => true

    event KnowledgeModuleAdded(uint256 indexed moduleId, string title, string contentHash);
    event KnowledgeModuleCompleted(uint256 indexed tokenId, uint256 indexed moduleId);
    event VerifiableCredentialLinked(uint256 indexed tokenId, string vcHash, string vcType);

    /**
     * @dev Owner adds a reference to an on-chain or off-chain knowledge module (e.g., a tutorial, course).
     * @param _title The title of the knowledge module.
     * @param _contentHash IPFS hash or URL of the module's content.
     * @param _associatedSkillIds Array of skill IDs this module helps develop.
     */
    function addKnowledgeModuleRef(
        string calldata _title,
        string calldata _contentHash,
        uint256[] calldata _associatedSkillIds
    ) public onlyOwner {
        uint256 newModuleId = _knowledgeModuleCounter.current();
        _knowledgeModuleCounter.increment();

        for (uint256 i = 0; i < _associatedSkillIds.length; i++) {
            require(skillIdToInfo[_associatedSkillIds[i]].id == _associatedSkillIds[i], "CGN: Invalid associated skill ID");
        }

        knowledgeModuleIdToInfo[newModuleId] = KnowledgeModule(
            newModuleId,
            _title,
            _contentHash,
            _associatedSkillIds,
            block.timestamp
        );
        emit KnowledgeModuleAdded(newModuleId, _title, _contentHash);
    }

    /**
     * @dev Allows a user to attest to completing a knowledge module.
     * Can provide a small reputation boost or badge.
     * @param _moduleId The ID of the knowledge module completed.
     */
    function attestKnowledgeModuleCompletion(uint256 _moduleId) public whenNotPaused {
        uint256 tokenId = userToTokenId[msg.sender];
        require(tokenId != 0 && tokenIdToProfile[tokenId].isActive, "CGN: Caller must have an active skill profile");
        require(knowledgeModuleIdToInfo[_moduleId].id == _moduleId, "CGN: Invalid knowledge module ID");
        require(!userCompletedKnowledgeModule[tokenId][_moduleId], "CGN: Knowledge module already attested as completed");

        userCompletedKnowledgeModule[tokenId][_moduleId] = true;

        // Optionally, give a small reputation boost or trigger a skill attestation for associated skills
        SkillProfile storage profile = tokenIdToProfile[tokenId];
        uint256 oldReputation = profile.reputationScore;
        profile.reputationScore += 5; // Small reputation boost for learning
        profile.lastActivityTimestamp = block.timestamp;
        emit ReputationUpdated(tokenId, oldReputation, profile.reputationScore);

        // Potentially trigger minor skill updates for associated skills, or mark them as "studied"
        // For example: if _associatedSkillIds is [1,2], and proficiency < 10, raise by 5.
        // This is more complex and left as an exercise or for a dedicated function.

        emit KnowledgeModuleCompleted(tokenId, _moduleId);

        // Update token URI to reflect dynamic data.
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(tokenId))));
    }

    /**
     * @dev Allows a user to link a hash or URI of an off-chain Verifiable Credential (VC) to their ASSBT.
     * This acts as a reference point for external verifiable proofs without storing full VC on-chain.
     * @param _vcHash The cryptographic hash of the VC (or a URL to it).
     * @param _vcType The type of credential (e.g., "Educational", "Employment", "Certification").
     */
    function linkVerifiableCredential(string calldata _vcHash, string calldata _vcType) public whenNotPaused {
        uint256 tokenId = userToTokenId[msg.sender];
        require(tokenId != 0 && tokenIdToProfile[tokenId].isActive, "CGN: Caller must have an active skill profile");

        // Store this as a dynamic attribute
        bytes32 vcKey = keccak256(abi.encodePacked("vc_", Strings.toString(tokenIdToProfile[tokenId].dynamicAttributes.length), _vcType));
        tokenIdToProfile[tokenId].dynamicAttributes[vcKey] = _vcHash;

        emit VerifiableCredentialLinked(tokenId, _vcHash, _vcType);
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://dynamic_profile/", Strings.toString(tokenId))));
    }

    // --- VII. Query & Utility Functions ---

    /**
     * @dev Retrieves a user's full skill profile data.
     * @param _user The address of the user.
     * @return SkillProfileData A tuple containing all profile details.
     */
    function querySkillProfile(address _user)
        public
        view
        returns (
            uint256 tokenId,
            uint256 reputationScore,
            uint256 lastActivityTimestamp,
            bool isActive,
            uint256[] memory activeBounties,
            uint256[] memory completedBounties
        )
    {
        tokenId = userToTokenId[_user];
        require(tokenId != 0, "CGN: No skill profile found for user");

        SkillProfile storage profile = tokenIdToProfile[tokenId];
        reputationScore = profile.reputationScore;
        lastActivityTimestamp = profile.lastActivityTimestamp;
        isActive = profile.isActive;

        // Copy array for return (storage arrays cannot be returned directly)
        activeBounties = new uint256[](profile.activeBounties.length);
        for (uint256 i = 0; i < profile.activeBounties.length; i++) {
            activeBounties[i] = profile.activeBounties[i];
        }

        completedBounties = new uint256[](profile.completedBounties.length);
        for (uint256 i = 0; i < profile.completedBounties.length; i++) {
            completedBounties[i] = profile.completedBounties[i];
        }
    }

    /**
     * @dev Retrieves a user's dynamic attribute by key. Respects visibility settings.
     * @param _user The address of the user.
     * @param _attributeKey The key of the attribute.
     * @return The string value of the attribute.
     */
    function getProfileDynamicAttribute(address _user, bytes32 _attributeKey) public view returns (string memory) {
        uint256 tokenId = userToTokenId[_user];
        require(tokenId != 0, "CGN: No skill profile found for user");

        SkillProfile storage profile = tokenIdToProfile[tokenId];
        AttributeVisibility visibility = AttributeVisibility(profile.profileVisibility[_attributeKey]);

        // Access control for visibility
        if (visibility == AttributeVisibility.PRIVATE) {
            require(msg.sender == _user || msg.sender == owner(), "CGN: Private attribute");
        } else if (visibility == AttributeVisibility.ATTESTERS_ONLY) {
            bool isAttester = false;
            // Check if msg.sender has attested *any* skill for this user, or is a privileged verifier
            if (msg.sender == owner() || msg.sender == trustedSkillVerifier || isOracleAddress[msg.sender]) {
                isAttester = true;
            } else {
                uint256 callerTokenId = userToTokenId[msg.sender];
                if (callerTokenId != 0 && tokenIdToProfile[callerTokenId].isActive) {
                    // This is a simplified check. A robust check would iterate through all attestations.
                    // For now, assume if an attester, they can see relevant private data.
                    // This could be optimized or made more granular.
                    // For example: any attestation by msg.sender *to* _user grants access.
                    // As a placeholder, we'll check if the caller itself is an attester to *any* skill for this user.
                    for(uint256 i = 0; i < 100; i++) { // Arbitrary small loop to avoid gas limits, or make it paginated.
                        if (userSkillAttestations[tokenId][i].length > 0 && userSkillAttestations[tokenId][i][0].attester == msg.sender) {
                            isAttester = true;
                            break;
                        }
                    }
                }
            }
            require(isAttester, "CGN: Attesters-only attribute");
        }
        // Public attributes are always readable

        return profile.dynamicAttributes[_attributeKey];
    }


    /**
     * @dev Retrieves all skill attestations for a specific user and skill.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return An array of SkillAttestation structs.
     */
    function querySkillAttestations(address _user, uint256 _skillId) public view returns (SkillAttestation[] memory) {
        uint256 tokenId = userToTokenId[_user];
        require(tokenId != 0, "CGN: No skill profile found for user");
        return userSkillAttestations[tokenId][_skillId];
    }

    /**
     * @dev Retrieves the details of a specific bounty.
     * @param _bountyId The ID of the bounty.
     * @return A Bounty struct containing all details.
     */
    function queryBountyDetails(uint256 _bountyId)
        public
        view
        returns (
            uint256 id,
            address creator,
            string memory title,
            string memory description,
            uint256[] memory requiredSkillIds,
            uint256 rewardAmount,
            address rewardToken,
            uint256 deadline,
            address applicant,
            string memory submissionProofHash,
            BountyStatus status,
            uint256 creationTimestamp,
            bool disputeRaised
        )
    {
        Bounty storage bounty = bountyIdToBounty[_bountyId];
        require(bounty.creator != address(0), "CGN: Bounty does not exist");

        id = bounty.id;
        creator = bounty.creator;
        title = bounty.title;
        description = bounty.description;
        requiredSkillIds = bounty.requiredSkillIds; // This copies the array
        rewardAmount = bounty.rewardAmount;
        rewardToken = bounty.rewardToken;
        deadline = bounty.deadline;
        applicant = bounty.applicant;
        submissionProofHash = bounty.submissionProofHash;
        status = bounty.status;
        creationTimestamp = bounty.creationTimestamp;
        disputeRaised = bounty.disputeRaised;
    }

    /**
     * @dev Retrieves details of a specific knowledge module.
     * @param _moduleId The ID of the knowledge module.
     * @return KnowledgeModule struct.
     */
    function queryKnowledgeModule(uint256 _moduleId)
        public
        view
        returns (
            uint256 id,
            string memory title,
            string memory contentHash,
            uint256[] memory associatedSkillIds,
            uint256 creationTimestamp
        )
    {
        KnowledgeModule storage module = knowledgeModuleIdToInfo[_moduleId];
        require(module.id == _moduleId, "CGN: Knowledge module does not exist");

        id = module.id;
        title = module.title;
        contentHash = module.contentHash;
        associatedSkillIds = module.associatedSkillIds; // This copies the array
        creationTimestamp = module.creationTimestamp;
    }

    /**
     * @dev Checks if a user has completed a specific knowledge module.
     * @param _user The address of the user.
     * @param _moduleId The ID of the knowledge module.
     * @return True if completed, false otherwise.
     */
    function hasCompletedKnowledgeModule(address _user, uint256 _moduleId) public view returns (bool) {
        uint256 tokenId = userToTokenId[_user];
        require(tokenId != 0, "CGN: No skill profile found for user");
        return userCompletedKnowledgeModule[tokenId][_moduleId];
    }
}
```