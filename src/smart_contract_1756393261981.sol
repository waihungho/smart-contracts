## EtherealForge: The Adaptive Soulbound Skill Tree & Reputation Protocol

### Contract Overview

`EtherealForge` is a novel smart contract system designed to create dynamic, non-transferable (Soulbound) tokens that represent a user's on-chain skills, achievements, and reputation. Unlike static NFTs, these "Soulbound Profiles" evolve over time based on the user's validated activities, earning them skills, mastery levels, and unique augmentations. The system incorporates a gamified skill tree, a decaying reputation score, and a decentralized verification mechanism, enabling a rich, verifiable on-chain identity for participants within various Web3 ecosystems.

### Core Concepts

1.  **Soulbound Profiles (SBTs):** Each user can mint a unique, non-transferable token representing their on-chain identity and achievements. These profiles are designed to be personal and enduring.
2.  **Dynamic Skill Tree:** Skills are defined and awarded to profiles with varying levels of mastery. These skills can be categorized and are verifiable by designated entities or oracles. A profile's metadata dynamically reflects its acquired skills.
3.  **Reputation & Level Progression:** A reputation score is automatically calculated based on the number of skills, their mastery levels, and profile activity. This score determines a profile's "level," which can grant access to special privileges, voting power multipliers, or unique features within integrated dApps. Reputation can also be subject to decay if not actively maintained.
4.  **Adaptive Traits & Augmentations:** Beyond skills, profiles can earn unique "augmentations" – special badges or modifiers that represent significant achievements or status. These augmentations can also influence a profile's functional behavior or visual representation in its metadata.
5.  **Decentralized Verification & Oracles:** The system allows for specific addresses (Verifiers) to be designated for awarding particular skills, enabling a more decentralized and context-specific verification process than a single centralized authority.
6.  **Gamified Progression:** The system encourages continuous engagement through the pursuit of new skills, higher mastery levels, and reputation, creating a gamified experience for building on-chain identity.

### Function Summary

#### I. Profile Management (Soulbound Token - SBT)
1.  `forgeProfile(address _owner, string calldata _initialMetadataURI)`: Mints a new Soulbound Profile NFT for a given address.
2.  `deactivateProfile(uint256 _tokenId)`: Marks a profile as inactive, preventing further skill or augmentation awards.
3.  `reactivateProfile(uint256 _tokenId)`: Re-activates a previously deactivated profile.
4.  `getTokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for a profile, reflecting its current state.

#### II. Skill Tree & Definitions
5.  `defineSkillCategory(string calldata _categoryName)`: Admin defines a new category for skills (e.g., "DeFi", "Smart Contract Dev", "Governance").
6.  `proposeSkillDefinition(uint256 _categoryId, string calldata _skillName, string calldata _description, address _initialVerifier)`: Allows anyone to propose a new skill within a category, along with an initial verifier.
7.  `voteOnSkillDefinition(uint256 _proposalId, bool _approve)`: Governance participants vote on skill proposals.
8.  `activateSkillDefinition(uint256 _proposalId)`: Admin or governance activates a proposed skill after successful voting.
9.  `updateSkillDefinition(uint256 _skillId, string calldata _newName, string calldata _newDescription)`: Admin/governance updates an existing skill's name or description.
10. `getSkillDetails(uint256 _skillId)`: Retrieves comprehensive details about a specific skill.

#### III. Skill & Achievement Verification
11. `setSkillVerifier(uint256 _skillId, address _newVerifier)`: Admin/governance assigns or changes the designated verifier for a specific skill.
12. `awardSkillToProfile(uint256 _tokenId, uint256 _skillId, uint256 _masteryLevel)`: A designated verifier awards a skill to a profile with an initial mastery level.
13. `updateSkillMastery(uint256 _tokenId, uint256 _skillId, uint256 _newMasteryLevel)`: A designated verifier updates an existing skill's mastery level for a profile.
14. `revokeSkillFromProfile(uint256 _tokenId, uint256 _skillId)`: A designated verifier revokes a skill from a profile.
15. `hasSkill(uint256 _tokenId, uint256 _skillId, uint256 _minMastery)`: Checks if a profile possesses a specific skill with at least a minimum mastery level.
16. `getProfileSkills(uint256 _tokenId)`: Returns a list of all skills and their mastery levels for a given profile.

#### IV. Reputation & Progression
17. `calculateReputationScore(uint256 _tokenId)`: (View) Calculates the current reputation score for a profile based on skills and mastery.
18. `getLevelForReputation(uint256 _reputationScore)`: (View) Determines the profile level based on a given reputation score.
19. `getProfileLevelDetails(uint256 _tokenId)`: (View) Returns a profile's current level, reputation score, and associated benefits.
20. `updateReputationDecayPeriod(uint256 _newPeriodSeconds)`: Admin sets the time period after which reputation might start to decay if not refreshed.
21. `setReputationLevelThreshold(uint256 _level, uint256 _minReputation, string calldata _benefitsURI)`: Admin sets reputation thresholds for levels and associated benefits.

#### V. Profile Augmentations & Traits
22. `mintAugmentation(uint256 _tokenId, uint256 _augmentationId, string calldata _traitUri)`: Awards a unique, non-skill-based augmentation (e.g., "Early Adopter Badge") to a profile.
23. `revokeAugmentation(uint256 _tokenId, uint256 _augmentationId)`: Revokes a specific augmentation from a profile.
24. `getProfileAugmentations(uint256 _tokenId)`: Returns a list of all augmentations held by a profile.

#### VI. Governance & Access Control
25. `isAtLeastLevel(uint256 _tokenId, uint256 _minLevel)`: Checks if a profile meets a minimum required reputation level.
26. `canPerformActionBySkill(uint256 _tokenId, uint256 _requiredSkillId, uint256 _requiredMastery)`: Checks if a profile has the necessary skill and mastery to perform a specific action (for dApp integration).

#### VII. Admin & Utilities
27. `setBaseURI(string calldata _newBaseURI)`: Admin sets the base URI for NFT metadata, from which individual `tokenURI`s are composed.
28. `setContractOperator(address _operator, bool _isOperator)`: Allows the owner to designate trusted contracts or addresses that can perform certain actions on behalf of the EtherealForge.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary provided above the source code.

contract EtherealForge is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _skillIdCounter;
    Counters.Counter private _categoryIdCounter;
    Counters.Counter private _skillProposalIdCounter;
    Counters.Counter private _augmentationIdCounter;

    // Mapping from tokenId to its owner
    mapping(uint256 => address) private _owners; // Override ERC721 _owners to manage transfer restriction better

    // Profile State
    mapping(uint256 => bool) public isProfileActive; // True if profile is active

    // Skill Definition
    struct Skill {
        uint256 categoryId;
        string name;
        string description;
        address verifier; // Address designated to award this skill
        bool isActive;
    }
    mapping(uint256 => Skill) public skills; // skillId => Skill struct
    mapping(string => uint256) public skillNameToId; // For quick lookup

    // Skill Category Definition
    struct SkillCategory {
        string name;
    }
    mapping(uint256 => SkillCategory) public skillCategories;

    // Skill Proposals (for decentralized skill definition)
    struct SkillProposal {
        uint256 categoryId;
        string name;
        string description;
        address initialVerifier;
        mapping(address => bool) votes; // Voter => hasVoted
        uint256 yesVotes;
        uint256 noVotes;
        bool executed; // True if activated or rejected
    }
    mapping(uint256 => SkillProposal) public skillProposals;
    uint256 public minVotesForSkillApproval = 3; // Example, could be dynamic or by a DAO

    // Profile Skills (tokenId => skillId => masteryLevel)
    mapping(uint256 => mapping(uint256 => uint256)) public profileSkills;
    mapping(uint256 => uint256[]) public profileSkillList; // For easier retrieval

    // Profile Augmentations (tokenId => augmentationId => traitURI)
    struct Augmentation {
        uint256 id;
        string traitURI; // URI pointing to specific trait data or visual representation
    }
    mapping(uint256 => mapping(uint256 => Augmentation)) public profileAugmentations;
    mapping(uint256 => uint256[]) public profileAugmentationList; // For easier retrieval

    // Reputation & Levels
    struct LevelThreshold {
        uint256 minReputation;
        string benefitsURI; // URI pointing to details about level benefits
    }
    mapping(uint256 => LevelThreshold) public levelThresholds; // level => threshold
    uint256 public maxDefinedLevel = 0;

    uint256 public reputationDecayPeriodSeconds = 365 days; // How long before reputation starts to decay (if implemented)
    // For simplicity, reputation decay logic is only conceptual here, not fully implemented with timestamps

    // Contract Operators (trusted addresses that can call certain functions)
    mapping(address => bool) public isContractOperator;

    // Base URI for dynamic metadata
    string private _baseTokenURI;

    // --- Events ---

    event ProfileForged(address indexed owner, uint256 indexed tokenId, string initialMetadataURI);
    event ProfileStatusChanged(uint256 indexed tokenId, bool isActive);
    event SkillCategoryDefined(uint256 indexed categoryId, string categoryName);
    event SkillProposalSubmitted(uint256 indexed proposalId, uint256 categoryId, string skillName, address initialVerifier);
    event SkillProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 yesVotes, uint256 noVotes);
    event SkillDefinitionActivated(uint256 indexed skillId, uint256 indexed categoryId, string skillName, address verifier);
    event SkillDefinitionUpdated(uint256 indexed skillId, string newName, string newDescription);
    event SkillVerifierUpdated(uint256 indexed skillId, address indexed oldVerifier, address indexed newVerifier);
    event SkillAwarded(uint256 indexed tokenId, uint256 indexed skillId, uint256 masteryLevel);
    event SkillMasteryUpdated(uint256 indexed tokenId, uint256 indexed skillId, uint256 oldMasteryLevel, uint256 newMasteryLevel);
    event SkillRevoked(uint256 indexed tokenId, uint256 indexed skillId);
    event AugmentationMinted(uint256 indexed tokenId, uint256 indexed augmentationId, string traitUri);
    event AugmentationRevoked(uint256 indexed tokenId, uint256 indexed augmentationId);
    event ReputationDecayPeriodUpdated(uint256 newPeriodSeconds);
    event LevelThresholdSet(uint256 indexed level, uint256 minReputation, string benefitsURI);
    event ContractOperatorSet(address indexed operator, bool status);


    // --- Constructor ---

    constructor() ERC721("EtherealForgeProfile", "EFP") Ownable(msg.sender) {
        // Designate deployer as an initial operator
        isContractOperator[msg.sender] = true;
    }

    // --- Modifiers ---

    modifier onlyVerifier(uint256 _skillId) {
        require(msg.sender == skills[_skillId].verifier, "EFP: Not the designated verifier for this skill");
        _;
    }

    modifier onlyOperator() {
        require(isContractOperator[msg.sender], "EFP: Caller is not a designated operator");
        _;
    }

    // --- ERC721 Overrides (to make it Soulbound) ---

    // Cannot transfer, approve, or set approval for all
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("EFP: Soulbound tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("EFP: Soulbound tokens are non-transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("EFP: Soulbound tokens are non-transferable");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("EFP: Soulbound tokens cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("EFP: Soulbound tokens cannot have approval set for all");
    }

    // Override _ownerOf for better internal consistency or if we want to manage it manually
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "EFP: Invalid token ID");
        return owner;
    }

    // Override _exists to respect profile activation status
    function _exists(uint256 tokenId) internal view override returns (bool) {
        return _owners[tokenId] != address(0) && isProfileActive[tokenId];
    }

    // Override _mint function to allow our custom forging logic
    function _mint(address to, uint256 tokenId) internal override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    // Override _burn function
    function _burn(uint256 tokenId) internal override {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        delete _owners[tokenId];
        // Clear associated data for a clean burn (though for SBTs, we prefer deactivation)
        delete profileSkills[tokenId];
        delete profileAugmentations[tokenId];
        delete profileSkillList[tokenId];
        delete profileAugmentationList[tokenId];
        
        emit Transfer(owner, address(0), tokenId);
    }


    // --- I. Profile Management (Soulbound Token - SBT) ---

    /**
     * @notice Mints a new Soulbound Profile NFT for a given address.
     * @param _owner The address to whom the profile will be minted.
     * @param _initialMetadataURI An initial URI for the profile's metadata.
     */
    function forgeProfile(address _owner, string calldata _initialMetadataURI)
        public
        onlyOperator
        returns (uint256 tokenId)
    {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _mint(_owner, tokenId);
        isProfileActive[tokenId] = true;
        _setTokenURI(tokenId, _initialMetadataURI); // Set an initial URI that will be overridden by getTokenURI

        emit ProfileForged(_owner, tokenId, _initialMetadataURI);
    }

    /**
     * @notice Marks a profile as inactive, preventing further skill or augmentation awards.
     * @dev An inactive profile still exists but cannot gain new achievements.
     * @param _tokenId The ID of the profile to deactivate.
     */
    function deactivateProfile(uint256 _tokenId) public onlyOperator {
        require(_owners[_tokenId] != address(0), "EFP: Profile does not exist");
        require(isProfileActive[_tokenId], "EFP: Profile is already inactive");
        isProfileActive[_tokenId] = false;
        emit ProfileStatusChanged(_tokenId, false);
    }

    /**
     * @notice Re-activates a previously deactivated profile.
     * @param _tokenId The ID of the profile to reactivate.
     */
    function reactivateProfile(uint256 _tokenId) public onlyOperator {
        require(_owners[_tokenId] != address(0), "EFP: Profile does not exist");
        require(!isProfileActive[_tokenId], "EFP: Profile is already active");
        isProfileActive[_tokenId] = true;
        emit ProfileStatusChanged(_tokenId, true);
    }

    /**
     * @notice Returns the dynamic metadata URI for a profile, reflecting its current state.
     * @dev This function could assemble a JSON string on-chain or point to an API that generates it.
     *      For simplicity, it points to a base URI + tokenId, with the expectation that an external service
     *      will generate the dynamic JSON based on on-chain data.
     * @param _tokenId The ID of the profile.
     * @return The dynamic metadata URI.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        // This is where dynamic metadata would be generated.
        // For on-chain generation, it would be complex JSON string assembly.
        // For this example, we return a URL where an off-chain service dynamically generates the JSON.
        // The service would query the EtherealForge contract to get skills, reputation, etc. for _tokenId.
        return string(abi.encodePacked(_baseTokenURI, _tokenId.toString()));
    }
    
    /**
     * @notice Admin sets the base URI for NFT metadata.
     * @dev This URI is combined with the token ID to form the final tokenURI.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }


    // --- II. Skill Tree & Definitions ---

    /**
     * @notice Admin defines a new category for skills (e.g., "DeFi", "Smart Contract Dev", "Governance").
     * @param _categoryName The name of the new skill category.
     */
    function defineSkillCategory(string calldata _categoryName) public onlyOwner {
        _categoryIdCounter.increment();
        uint256 categoryId = _categoryIdCounter.current();
        skillCategories[categoryId] = SkillCategory({name: _categoryName});
        emit SkillCategoryDefined(categoryId, _categoryName);
    }

    /**
     * @notice Allows anyone to propose a new skill within a category, along with an initial verifier.
     * @param _categoryId The ID of the category this skill belongs to.
     * @param _skillName The name of the proposed skill.
     * @param _description A detailed description of the skill.
     * @param _initialVerifier The address initially proposed to verify this skill.
     * @return The ID of the new skill proposal.
     */
    function proposeSkillDefinition(
        uint256 _categoryId,
        string calldata _skillName,
        string calldata _description,
        address _initialVerifier
    ) public returns (uint256) {
        require(bytes(skillCategories[_categoryId].name).length > 0, "EFP: Category does not exist");

        _skillProposalIdCounter.increment();
        uint256 proposalId = _skillProposalIdCounter.current();
        
        SkillProposal storage proposal = skillProposals[proposalId];
        proposal.categoryId = _categoryId;
        proposal.name = _skillName;
        proposal.description = _description;
        proposal.initialVerifier = _initialVerifier;
        proposal.executed = false;

        emit SkillProposalSubmitted(proposalId, _categoryId, _skillName, _initialVerifier);
        return proposalId;
    }

    /**
     * @notice Governance participants vote on skill proposals.
     * @param _proposalId The ID of the skill proposal to vote on.
     * @param _approve True to vote yes, false to vote no.
     */
    function voteOnSkillDefinition(uint256 _proposalId, bool _approve) public {
        SkillProposal storage proposal = skillProposals[_proposalId];
        require(bytes(proposal.name).length > 0, "EFP: Proposal does not exist");
        require(!proposal.executed, "EFP: Proposal already executed");
        require(!proposal.votes[msg.sender], "EFP: Already voted on this proposal");

        proposal.votes[msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        
        emit SkillProposalVoted(_proposalId, msg.sender, _approve, proposal.yesVotes, proposal.noVotes);

        // Auto-activate if enough votes (simple example, could be more complex with token-weighted voting)
        if (proposal.yesVotes >= minVotesForSkillApproval) {
            activateSkillDefinition(_proposalId);
            proposal.executed = true; // Mark as executed
        } else if (proposal.noVotes >= minVotesForSkillApproval) { // Or if enough no votes
            proposal.executed = true; // Mark as executed without activation
        }
    }


    /**
     * @notice Admin or governance activates a proposed skill after successful voting.
     * @param _proposalId The ID of the skill proposal to activate.
     */
    function activateSkillDefinition(uint256 _proposalId) public onlyOwner { // OnlyOwner for simplicity, could be integrated with governance
        SkillProposal storage proposal = skillProposals[_proposalId];
        require(bytes(proposal.name).length > 0, "EFP: Proposal does not exist");
        require(!proposal.executed, "EFP: Proposal already executed");
        // Simplified check: can activate if enough positive votes (or directly by owner if governance not fully implemented)
        // require(proposal.yesVotes >= minVotesForSkillApproval, "EFP: Not enough votes to activate skill");

        _skillIdCounter.increment();
        uint256 skillId = _skillIdCounter.current();
        skills[skillId] = Skill({
            categoryId: proposal.categoryId,
            name: proposal.name,
            description: proposal.description,
            verifier: proposal.initialVerifier,
            isActive: true
        });
        skillNameToId[proposal.name] = skillId;
        proposal.executed = true; // Mark as executed
        emit SkillDefinitionActivated(skillId, proposal.categoryId, proposal.name, proposal.initialVerifier);
    }


    /**
     * @notice Admin/governance updates an existing skill's name or description.
     * @param _skillId The ID of the skill to update.
     * @param _newName The new name for the skill (optional, empty string to keep).
     * @param _newDescription The new description for the skill (optional, empty string to keep).
     */
    function updateSkillDefinition(
        uint256 _skillId,
        string calldata _newName,
        string calldata _newDescription
    ) public onlyOwner {
        Skill storage s = skills[_skillId];
        require(s.isActive, "EFP: Skill does not exist or is inactive");

        if (bytes(_newName).length > 0) {
            s.name = _newName;
        }
        if (bytes(_newDescription).length > 0) {
            s.description = _newDescription;
        }
        emit SkillDefinitionUpdated(_skillId, s.name, s.description);
    }

    /**
     * @notice Retrieves comprehensive details about a specific skill.
     * @param _skillId The ID of the skill.
     * @return A tuple containing skill details.
     */
    function getSkillDetails(uint256 _skillId)
        public
        view
        returns (
            uint256 categoryId,
            string memory categoryName,
            string memory skillName,
            string memory description,
            address verifier,
            bool isActive
        )
    {
        Skill storage s = skills[_skillId];
        require(s.isActive, "EFP: Skill does not exist or is inactive");
        return (
            s.categoryId,
            skillCategories[s.categoryId].name,
            s.name,
            s.description,
            s.verifier,
            s.isActive
        );
    }


    // --- III. Skill & Achievement Verification ---

    /**
     * @notice Admin/governance assigns or changes the designated verifier for a specific skill.
     * @param _skillId The ID of the skill.
     * @param _newVerifier The address of the new verifier.
     */
    function setSkillVerifier(uint256 _skillId, address _newVerifier) public onlyOwner {
        Skill storage s = skills[_skillId];
        require(s.isActive, "EFP: Skill does not exist or is inactive");
        address oldVerifier = s.verifier;
        s.verifier = _newVerifier;
        emit SkillVerifierUpdated(_skillId, oldVerifier, _newVerifier);
    }

    /**
     * @notice A designated verifier awards a skill to a profile with an initial mastery level.
     * @param _tokenId The ID of the profile.
     * @param _skillId The ID of the skill to award.
     * @param _masteryLevel The initial mastery level for the skill (e.g., 1-100).
     */
    function awardSkillToProfile(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _masteryLevel
    ) public onlyVerifier(_skillId) {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        require(skills[_skillId].isActive, "EFP: Skill does not exist or is inactive");
        require(_masteryLevel > 0, "EFP: Mastery level must be greater than 0");

        if (profileSkills[_tokenId][_skillId] == 0) { // Only add to list if new skill
            profileSkillList[_tokenId].push(_skillId);
        }
        profileSkills[_tokenId][_skillId] = _masteryLevel;
        emit SkillAwarded(_tokenId, _skillId, _masteryLevel);
    }

    /**
     * @notice A designated verifier updates an existing skill's mastery level for a profile.
     * @param _tokenId The ID of the profile.
     * @param _skillId The ID of the skill to update.
     * @param _newMasteryLevel The new mastery level.
     */
    function updateSkillMastery(
        uint256 _tokenId,
        uint256 _skillId,
        uint256 _newMasteryLevel
    ) public onlyVerifier(_skillId) {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        require(skills[_skillId].isActive, "EFP: Skill does not exist or is inactive");
        require(profileSkills[_tokenId][_skillId] > 0, "EFP: Profile does not possess this skill");
        require(_newMasteryLevel > 0, "EFP: Mastery level must be greater than 0");

        uint256 oldMastery = profileSkills[_tokenId][_skillId];
        profileSkills[_tokenId][_skillId] = _newMasteryLevel;
        emit SkillMasteryUpdated(_tokenId, _skillId, oldMastery, _newMasteryLevel);
    }

    /**
     * @notice A designated verifier revokes a skill from a profile.
     * @param _tokenId The ID of the profile.
     * @param _skillId The ID of the skill to revoke.
     */
    function revokeSkillFromProfile(uint256 _tokenId, uint256 _skillId) public onlyVerifier(_skillId) {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        require(profileSkills[_tokenId][_skillId] > 0, "EFP: Profile does not possess this skill");

        delete profileSkills[_tokenId][_skillId];
        // Remove from dynamic list (inefficient, consider refactoring profileSkillList if many revocations expected)
        for (uint256 i = 0; i < profileSkillList[_tokenId].length; i++) {
            if (profileSkillList[_tokenId][i] == _skillId) {
                profileSkillList[_tokenId][i] = profileSkillList[_tokenId][profileSkillList[_tokenId].length - 1];
                profileSkillList[_tokenId].pop();
                break;
            }
        }
        emit SkillRevoked(_tokenId, _skillId);
    }

    /**
     * @notice Checks if a profile possesses a specific skill with at least a minimum mastery level.
     * @param _tokenId The ID of the profile.
     * @param _skillId The ID of the skill.
     * @param _minMastery The minimum mastery level required.
     * @return True if the profile has the skill with the required mastery, false otherwise.
     */
    function hasSkill(uint256 _tokenId, uint256 _skillId, uint256 _minMastery) public view returns (bool) {
        return _exists(_tokenId) && profileSkills[_tokenId][_skillId] >= _minMastery;
    }

    /**
     * @notice Returns a list of all skills and their mastery levels for a given profile.
     * @param _tokenId The ID of the profile.
     * @return An array of skill IDs and an array of their corresponding mastery levels.
     */
    function getProfileSkills(uint256 _tokenId)
        public
        view
        returns (uint256[] memory skillIds, uint256[] memory masteryLevels)
    {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        uint256[] memory ids = profileSkillList[_tokenId];
        uint256[] memory levels = new uint256[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            levels[i] = profileSkills[_tokenId][ids[i]];
        }
        return (ids, levels);
    }


    // --- IV. Reputation & Progression ---

    /**
     * @notice Calculates the current reputation score for a profile based on skills and mastery.
     * @dev This is a simplified calculation. Real-world might involve decay, activity, etc.
     * @param _tokenId The ID of the profile.
     * @return The calculated reputation score.
     */
    function calculateReputationScore(uint256 _tokenId) public view returns (uint256) {
        if (!_exists(_tokenId)) return 0;

        uint256 totalReputation = 0;
        uint256[] memory skillIds = profileSkillList[_tokenId];

        for (uint256 i = 0; i < skillIds.length; i++) {
            // Simple: Each skill adds its mastery level to reputation
            totalReputation += profileSkills[_tokenId][skillIds[i]];
            // Could add a bonus for higher mastery, or skill rarity
        }
        // Could add a bonus for number of augmentations
        totalReputation += profileAugmentationList[_tokenId].length * 10; // Example bonus

        // Placeholder for decay logic:
        // if (block.timestamp > lastReputationUpdate[_tokenId] + reputationDecayPeriodSeconds) {
        //     // Apply some decay based on time elapsed
        // }
        return totalReputation;
    }

    /**
     * @notice Determines the profile level based on a given reputation score.
     * @param _reputationScore The reputation score to check.
     * @return The corresponding profile level.
     */
    function getLevelForReputation(uint256 _reputationScore) public view returns (uint256) {
        uint256 currentLevel = 0;
        for (uint256 i = 1; i <= maxDefinedLevel; i++) {
            if (_reputationScore >= levelThresholds[i].minReputation) {
                currentLevel = i;
            } else {
                break;
            }
        }
        return currentLevel;
    }

    /**
     * @notice Returns a profile's current level, reputation score, and associated benefits URI.
     * @param _tokenId The ID of the profile.
     * @return A tuple containing the level, reputation score, and benefits URI.
     */
    function getProfileLevelDetails(uint256 _tokenId)
        public
        view
        returns (uint256 level, uint256 reputationScore, string memory benefitsURI)
    {
        reputationScore = calculateReputationScore(_tokenId);
        level = getLevelForReputation(reputationScore);
        benefitsURI = levelThresholds[level].benefitsURI;
        return (level, reputationScore, benefitsURI);
    }

    /**
     * @notice Admin sets the time period after which reputation might start to decay if not refreshed.
     * @param _newPeriodSeconds The new decay period in seconds.
     */
    function updateReputationDecayPeriod(uint256 _newPeriodSeconds) public onlyOwner {
        reputationDecayPeriodSeconds = _newPeriodSeconds;
        emit ReputationDecayPeriodUpdated(_newPeriodSeconds);
    }

    /**
     * @notice Admin sets reputation thresholds for levels and associated benefits.
     * @param _level The level number.
     * @param _minReputation The minimum reputation score required for this level.
     * @param _benefitsURI An IPFS or HTTP URI pointing to details about the benefits of this level.
     */
    function setReputationLevelThreshold(
        uint256 _level,
        uint256 _minReputation,
        string calldata _benefitsURI
    ) public onlyOwner {
        require(_level > 0, "EFP: Level must be greater than 0");
        if (_level > maxDefinedLevel) {
            maxDefinedLevel = _level;
        }
        levelThresholds[_level] = LevelThreshold({minReputation: _minReputation, benefitsURI: _benefitsURI});
        emit LevelThresholdSet(_level, _minReputation, _benefitsURI);
    }


    // --- V. Profile Augmentations & Traits ---

    /**
     * @notice Awards a unique, non-skill-based augmentation (e.g., "Early Adopter Badge") to a profile.
     * @param _tokenId The ID of the profile.
     * @param _augmentationId A unique ID for the augmentation.
     * @param _traitUri An IPFS or HTTP URI pointing to specific trait data or visual representation.
     */
    function mintAugmentation(
        uint256 _tokenId,
        uint256 _augmentationId,
        string calldata _traitUri
    ) public onlyOperator {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        require(profileAugmentations[_tokenId][_augmentationId].id == 0, "EFP: Augmentation already exists for profile");
        
        profileAugmentations[_tokenId][_augmentationId] = Augmentation({id: _augmentationId, traitURI: _traitUri});
        profileAugmentationList[_tokenId].push(_augmentationId); // Add to list
        emit AugmentationMinted(_tokenId, _augmentationId, _traitUri);
    }

    /**
     * @notice Revokes a specific augmentation from a profile.
     * @param _tokenId The ID of the profile.
     * @param _augmentationId The ID of the augmentation to revoke.
     */
    function revokeAugmentation(uint256 _tokenId, uint256 _augmentationId) public onlyOperator {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        require(profileAugmentations[_tokenId][_augmentationId].id != 0, "EFP: Profile does not have this augmentation");

        delete profileAugmentations[_tokenId][_augmentationId];
        // Remove from dynamic list (similar to skill revocation)
        for (uint256 i = 0; i < profileAugmentationList[_tokenId].length; i++) {
            if (profileAugmentationList[_tokenId][i] == _augmentationId) {
                profileAugmentationList[_tokenId][i] = profileAugmentationList[_tokenId][profileAugmentationList[_tokenId].length - 1];
                profileAugmentationList[_tokenId].pop();
                break;
            }
        }
        emit AugmentationRevoked(_tokenId, _augmentationId);
    }

    /**
     * @notice Returns a list of all augmentations held by a profile.
     * @param _tokenId The ID of the profile.
     * @return An array of Augmentation structs.
     */
    function getProfileAugmentations(uint256 _tokenId)
        public
        view
        returns (Augmentation[] memory)
    {
        require(_exists(_tokenId), "EFP: Profile does not exist or is inactive");
        uint256[] memory augIds = profileAugmentationList[_tokenId];
        Augmentation[] memory augs = new Augmentation[](augIds.length);

        for (uint256 i = 0; i < augIds.length; i++) {
            augs[i] = profileAugmentations[_tokenId][augIds[i]];
        }
        return augs;
    }


    // --- VI. Governance & Access Control ---

    /**
     * @notice Checks if a profile meets a minimum required reputation level.
     * @dev This function can be used by integrated dApps for access control.
     * @param _tokenId The ID of the profile.
     * @param _minLevel The minimum level required.
     * @return True if the profile's current level is at least _minLevel, false otherwise.
     */
    function isAtLeastLevel(uint256 _tokenId, uint256 _minLevel) public view returns (bool) {
        return getLevelForReputation(calculateReputationScore(_tokenId)) >= _minLevel;
    }

    /**
     * @notice Checks if a profile has the necessary skill and mastery to perform a specific action.
     * @dev This function can be used by integrated dApps for feature gating or role-based access.
     * @param _tokenId The ID of the profile.
     * @param _requiredSkillId The ID of the skill required.
     * @param _requiredMastery The minimum mastery level required for the skill.
     * @return True if the profile has the required skill with sufficient mastery, false otherwise.
     */
    function canPerformActionBySkill(
        uint256 _tokenId,
        uint256 _requiredSkillId,
        uint256 _requiredMastery
    ) public view returns (bool) {
        return hasSkill(_tokenId, _requiredSkillId, _requiredMastery);
    }


    // --- VII. Admin & Utilities ---

    /**
     * @notice Allows the owner to designate trusted contracts or addresses that can perform certain actions on behalf of the EtherealForge.
     * @param _operator The address to set as an operator.
     * @param _isOperator True to grant operator status, false to revoke.
     */
    function setContractOperator(address _operator, bool _isOperator) public onlyOwner {
        isContractOperator[_operator] = _isOperator;
        emit ContractOperatorSet(_operator, _isOperator);
    }
}
```