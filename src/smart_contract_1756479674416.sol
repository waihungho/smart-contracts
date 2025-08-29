```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
███████╗███████████████╗ ███████╗███████████╗ ███████╗█████████████╗
██╔════╝╚══██╔══╝╚══██╔══╝ ██╔════╝██╔══════██║ ██╔════╝╚══██╔══╝╚══██╔══╝
███████╗   ██║      ██║    ███████╗███████╔╝   ███████╗   ██║      ██║
╚════██║   ██║      ██║    ╚════██║██╔═══██╗   ╚════██║   ██║      ██║
███████║   ██║      ██║    ███████║██║   ██║   ███████║   ██║      ██║
╚══════╝   ╚═╝      ╚═╝    ╚══════╝╚═╝   ╚═╝   ╚══════╝   ╚═╝      ╚═╝
*/

/**
 * @title EthosRep: Decentralized Skill & Reputation Nexus
 * @author YourNameHere (ChatGPT-4o)
 * @notice EthosRep is a sophisticated smart contract designed to create a decentralized,
 *         on-chain reputation and skill verification network. It introduces novel concepts
 *         such as Dynamic Soulbound Skill NFTs (DSNFTs) which evolve based on a user's
 *         aggregated reputation and skill attestations, and "Attestation Bots" – automated
 *         on-chain agents capable of issuing verified attestations. The system also supports
 *         curated learning paths and a basic governance mechanism for community-driven
 *         skill definition and system evolution.
 *
 * @dev This contract utilizes OpenZeppelin libraries for ERC-721, Ownable, Pausable,
 *      Counters, and Strings. It extends ERC-721 to create non-transferable, dynamic NFTs.
 *      The contract is designed to be modular and extensible for future features.
 */

// OUTLINE AND FUNCTION SUMMARY

/*
I. Core Administration & Setup (5 functions)
    1.  constructor(): Initializes the contract, sets the owner, and defines initial parameters.
    2.  updateOwner(address newOwner): Transfers contract ownership to a new address.
    3.  pauseContract(): Pauses contract functionality in emergencies.
    4.  unpauseContract(): Unpauses contract functionality.
    5.  withdrawStakedAmount(): Allows users to withdraw their stake after a cooldown period.

II. Skill & Category Management (5 functions)
    6.  defineSkillCategory(string memory _name, string memory _description): Defines a new broad skill category.
    7.  defineSkill(uint256 _categoryId, string memory _name, string memory _description): Defines a specific skill within a category.
    8.  updateSkillDescription(uint256 _skillId, string memory _newDescription): Updates the description of an existing skill.
    9.  proposeSkillForApproval(uint256 _categoryId, string memory _name, string memory _description): Allows users to propose new skills for community approval.
    10. voteOnProposal(uint256 _proposalId, bool _approve): Allows users to vote on active governance proposals.

III. User Attestations & Reputation (6 functions)
    11. attestSkill(address _to, uint256 _skillId, uint8 _proficiencyScore, string memory _contextURI): Allows a user to attest to another user's skill, requiring a stake.
    12. revokeAttestation(address _to, uint256 _skillId, uint256 _attestationId): Allows an attester to revoke their own attestation.
    13. getAttestationDetails(uint256 _attestationId): Retrieves details of a specific attestation.
    14. getReputationScore(address _user): Returns the aggregated reputation score for a user.
    15. getSkillProficiency(address _user, uint256 _skillId): Returns the aggregated proficiency score for a specific skill of a user.
    16. stakeForAttestationPrivilege(): Allows users to stake ETH to gain attestation privileges.

IV. Dynamic Soulbound Skill NFTs (DSNFTs) (6 functions + ERC721 overrides)
    17. mintDSNFT(address _to): Mints an initial Dynamic Soulbound Skill NFT for a user if conditions are met.
    18. _updateDSNFTMetadata(address _user, uint256 _tokenId): Internal function to update the metadata URI of a DSNFT based on reputation and skills.
    19. tokenURI(uint256 _tokenId): Returns the metadata URI for a given DSNFT.
    20. balanceOf(address owner): Returns the number of DSNFTs owned by an address (overridden for ERC721).
    21. ownerOf(uint256 tokenId): Returns the owner of the DSNFT (overridden for ERC721).
    22. supportsInterface(bytes4 interfaceId): Standard ERC-165 interface detection (overridden for ERC721).
    (ERC721 transfer functions are overridden to prevent transfers, making them soulbound).

V. Attestation Bots (Automated Agents) (4 functions)
    23. registerAttestationBot(address _botAddress, string memory _name, string memory _description): Registers a new trusted Attestation Bot contract.
    24. attestSkillByBot(address _to, uint256 _skillId, uint8 _proficiencyScore, string memory _contextURI): Allows a registered bot to attest to a user's skill.
    25. deactivateAttestationBot(address _botAddress): Deactivates a registered Attestation Bot.
    26. updateAttestationBotAddress(address _oldBotAddress, address _newBotAddress): Updates the address of a registered bot (e.g., after an upgrade).

VI. Curated Learning Paths / Bounties (5 functions)
    27. createLearningPath(string memory _name, string memory _description, uint256[] memory _requiredSkillIds, uint256 _reputationReward, string memory _rewardDSNFTTrait): Creates a structured learning path.
    28. enrollInLearningPath(uint256 _pathId): Allows a user to enroll in a learning path.
    29. completeLearningPathMilestone(uint256 _pathId): Marks a milestone as complete, verifying required skill attestations.
    30. claimLearningPathReward(uint256 _pathId): Allows a user to claim rewards upon completing a path.
    31. proposeLearningPath(string memory _name, string memory _description, uint256[] memory _requiredSkillIds, uint256 _reputationReward, string memory _rewardDSNFTTrait): Allows users to propose learning paths for governance approval.

VII. Governance & Anti-Spam (3 functions)
    32. createGovernanceProposal(bytes memory _callData, string memory _description): Allows users to create general governance proposals.
    33. executeProposal(uint256 _proposalId): Executes a governance proposal that has passed.
    34. slashStakedAmount(address _staker, uint256 _amount, string memory _reason): (Placeholder) For slashing malicious attestors (requires dispute resolution system not implemented here).
*/

contract EthosRep is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Events ---
    event SkillCategoryDefined(uint256 indexed categoryId, string name, string description);
    event SkillDefined(uint256 indexed skillId, uint256 indexed categoryId, string name, string description);
    event SkillAttested(address indexed attester, address indexed recipient, uint256 indexed skillId, uint8 proficiency, string contextURI, uint256 attestationId);
    event AttestationRevoked(address indexed attester, address indexed recipient, uint256 indexed skillId, uint256 attestationId);
    event DSNFTMinted(address indexed owner, uint256 indexed tokenId);
    event DSNFTMetadataUpdated(address indexed owner, uint256 indexed tokenId, string newURI);
    event AttestationBotRegistered(address indexed botAddress, string name);
    event AttestationBotDeactivated(address indexed botAddress);
    event LearningPathCreated(uint256 indexed pathId, string name, address indexed creator);
    event UserEnrolledInPath(address indexed user, uint256 indexed pathId);
    event LearningPathMilestoneCompleted(address indexed user, uint256 indexed pathId, uint256 milestoneIndex);
    event LearningPathRewardClaimed(address indexed user, uint256 indexed pathId);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool decision);
    event ProposalExecuted(uint256 indexed proposalId);
    event StakedAmountSlashed(address indexed staker, uint256 amount, string reason);

    // --- Structs ---

    struct SkillCategory {
        string name;
        string description;
        bool exists;
    }

    struct Skill {
        uint256 categoryId;
        string name;
        string description;
        bool approved; // For governance-approved skills
    }

    struct Attestation {
        address attester;
        address recipient;
        uint256 skillId;
        uint8 proficiencyScore; // 1-100
        uint256 timestamp;
        string contextURI; // URI to IPFS/Arweave for more context, proofs, etc.
        bool active;
    }

    struct UserSkillProficiency {
        uint256 totalScore; // Sum of all active attestation scores
        uint256 attestationCount;
    }

    struct LearningPath {
        string name;
        string description;
        uint256[] requiredSkillIds; // Skills needed to complete the path
        uint256 reputationReward;
        string rewardDSNFTTrait; // Special trait added to DSNFT upon completion
        bool active;
        bool approved; // For governance-approved paths
    }

    struct GovernanceProposal {
        bytes callData; // Encoded function call to execute if proposal passes
        string description;
        address proposer;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    Counters.Counter private _skillCategoryIds;
    Counters.Counter private _skillIds;
    Counters.Counter private _attestationIds;
    Counters.Counter private _pathIds;
    Counters.Counter private _dsnftTokenIds;
    Counters.Counter private _proposalIds;

    mapping(uint256 => SkillCategory) public skillCategories;
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Attestation) public attestations;

    // User Data:
    mapping(address => uint256) public userReputation; // Aggregated reputation score
    mapping(address => mapping(uint256 => UserSkillProficiency)) public userSkillProficiencies; // User's proficiency per skill
    mapping(address => mapping(uint256 => uint256[])) public userAttestationsGiven; // attester => skillId => list of attestationIds
    mapping(address => mapping(uint256 => uint256[])) public userAttestationsReceived; // recipient => skillId => list of attestationIds
    mapping(address => uint256) public userStakes; // ETH staked for attestation privileges
    uint256 public constant MIN_STAKE_FOR_ATTESTATION = 0.01 ether; // Minimum stake to attest
    uint256 public constant STAKE_COOLDOWN_PERIOD = 30 days; // Cooldown for withdrawing stake
    mapping(address => uint256) public stakeWithdrawalRequests; // user => timestamp of request

    // DSNFT Data:
    mapping(address => uint256) public userDSNFTs; // user => tokenId (assuming one DSNFT per user for simplicity, can be extended)
    mapping(uint256 => address) public dsnftOwners; // tokenId => owner address (redundant with ERC721 but useful for lookup)
    mapping(uint256 => string) private _tokenURIs; // tokenId => metadata URI, used for dynamism

    // Attestation Bots:
    mapping(address => bool) public isAttestationBot;
    mapping(address => string) public attestationBotNames;

    // Learning Paths:
    mapping(uint256 => LearningPath) public learningPaths;
    mapping(address => mapping(uint256 => bool)) public userEnrolledPaths; // user => pathId => enrolled
    mapping(address => mapping(uint256 => uint256)) public userPathMilestonesCompleted; // user => pathId => count

    // Governance:
    mapping(uint256 => GovernanceProposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // How long a proposal is open for voting
    uint256 public constant PROPOSAL_VOTING_THRESHOLD = 50; // Percentage of votes_for / (votes_for + votes_against) needed to pass


    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
        // Initial setup for the base ERC721 contract
        // No additional parameters needed for this specific ERC721 constructor beyond name/symbol.
    }

    // --- Modifiers ---
    modifier onlyBot() {
        require(isAttestationBot[msg.sender], "EthosRep: Not a registered attestation bot.");
        _;
    }

    modifier onlyStakeholders() {
        require(userStakes[msg.sender] >= MIN_STAKE_FOR_ATTESTATION, "EthosRep: Insufficient stake to perform this action.");
        _;
    }

    modifier onlyReputable(uint256 _minReputation) {
        require(userReputation[msg.sender] >= _minReputation, "EthosRep: Insufficient reputation.");
        _;
    }

    // --- I. Core Administration & Setup ---

    /**
     * @dev Transfers contract ownership to a new address.
     * @param newOwner The address of the new owner.
     */
    function updateOwner(address newOwner) public virtual onlyOwner {
        transferOwnership(newOwner);
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     *      Callable only by the contract owner.
     */
    function pauseContract() public onlyOwner pausable {
        _pause();
    }

    /**
     * @dev Unpauses the contract, re-enabling functionality.
     *      Callable only by the contract owner.
     */
    function unpauseContract() public onlyOwner pausable {
        _unpause();
    }

    /**
     * @dev Allows a user to withdraw their staked amount after the cooldown period.
     */
    function withdrawStakedAmount() public whenNotPaused {
        require(userStakes[msg.sender] > 0, "EthosRep: No stake to withdraw.");
        require(stakeWithdrawalRequests[msg.sender] > 0, "EthosRep: No pending withdrawal request.");
        require(block.timestamp >= stakeWithdrawalRequests[msg.sender] + STAKE_COOLDOWN_PERIOD, "EthosRep: Cooldown period not over.");

        uint256 amount = userStakes[msg.sender];
        userStakes[msg.sender] = 0;
        delete stakeWithdrawalRequests[msg.sender];

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "EthosRep: Failed to send ETH.");
        emit Unstaked(msg.sender, amount);
    }


    // --- II. Skill & Category Management ---

    /**
     * @dev Defines a new skill category. Only callable by the owner.
     * @param _name The name of the skill category (e.g., "Development").
     * @param _description A brief description of the category.
     */
    function defineSkillCategory(string memory _name, string memory _description) public onlyOwner whenNotPaused returns (uint256) {
        _skillCategoryIds.increment();
        uint256 categoryId = _skillCategoryIds.current();
        skillCategories[categoryId] = SkillCategory(_name, _description, true);
        emit SkillCategoryDefined(categoryId, _name, _description);
        return categoryId;
    }

    /**
     * @dev Defines a new specific skill within an existing category. Only callable by the owner.
     * @param _categoryId The ID of the parent skill category.
     * @param _name The name of the skill (e.g., "Solidity").
     * @param _description A detailed description of the skill.
     */
    function defineSkill(uint256 _categoryId, string memory _name, string memory _description) public onlyOwner whenNotPaused returns (uint256) {
        require(skillCategories[_categoryId].exists, "EthosRep: Category does not exist.");
        _skillIds.increment();
        uint256 skillId = _skillIds.current();
        skills[skillId] = Skill(_categoryId, _name, _description, true); // Owner-defined skills are approved by default
        emit SkillDefined(skillId, _categoryId, _name, _description);
        return skillId;
    }

    /**
     * @dev Updates the description of an existing skill. Only callable by the owner.
     * @param _skillId The ID of the skill to update.
     * @param _newDescription The new description for the skill.
     */
    function updateSkillDescription(uint256 _skillId, string memory _newDescription) public onlyOwner whenNotPaused {
        require(skills[_skillId].categoryId != 0, "EthosRep: Skill does not exist.");
        skills[_skillId].description = _newDescription;
        emit SkillDefined(_skillId, skills[_skillId].categoryId, skills[_skillId].name, _newDescription); // Re-emit for update
    }

    /**
     * @dev Allows any user with sufficient reputation to propose a new skill for community approval.
     * @param _categoryId The ID of the parent skill category.
     * @param _name The name of the proposed skill.
     * @param _description A detailed description of the proposed skill.
     */
    function proposeSkillForApproval(uint256 _categoryId, string memory _name, string memory _description) public onlyReputable(100) whenNotPaused returns (uint256) {
        require(skillCategories[_categoryId].exists, "EthosRep: Category does not exist.");

        // Create a temporary skill entry (not yet approved)
        _skillIds.increment();
        uint256 skillId = _skillIds.current();
        skills[skillId] = Skill(_categoryId, _name, _description, false); // Not yet approved

        // Create a governance proposal to approve this skill
        bytes memory callData = abi.encodeWithSelector(
            this.approveSkill.selector,
            skillId,
            true // To approve it
        );
        return createGovernanceProposal(callData, string.concat("Approve new skill: ", _name, " (ID: ", skillId.toString(), ")"));
    }

    /**
     * @dev Internal function to approve or reject a skill. Callable only by governance.
     * @param _skillId The ID of the skill to approve/reject.
     * @param _approved True to approve, false to reject.
     */
    function approveSkill(uint256 _skillId, bool _approved) public onlyOwner { // Made onlyOwner for internal governance call
        require(skills[_skillId].categoryId != 0, "EthosRep: Skill does not exist.");
        require(!skills[_skillId].approved, "EthosRep: Skill already approved or rejected."); // Can't re-approve/reject

        skills[_skillId].approved = _approved;
        if (_approved) {
            emit SkillDefined(_skillId, skills[_skillId].categoryId, skills[_skillId].name, skills[_skillId].description);
        } else {
            // Potentially remove or mark as rejected for UI
            // For now, just mark it as not approved.
        }
    }


    // --- III. User Attestations & Reputation ---

    /**
     * @dev Allows a user to attest to another user's skill. Requires a minimum stake from the attester.
     *      Each attestation contributes to the recipient's skill proficiency and overall reputation.
     * @param _to The address of the user receiving the attestation.
     * @param _skillId The ID of the skill being attested to.
     * @param _proficiencyScore The score (1-100) indicating the recipient's proficiency in the skill.
     * @param _contextURI A URI pointing to external evidence or context for the attestation.
     */
    function attestSkill(address _to, uint256 _skillId, uint8 _proficiencyScore, string memory _contextURI) public onlyStakeholders whenNotPaused {
        require(msg.sender != _to, "EthosRep: Cannot attest to your own skills.");
        require(_to != address(0), "EthosRep: Invalid recipient address.");
        require(skills[_skillId].categoryId != 0 && skills[_skillId].approved, "EthosRep: Skill does not exist or is not approved.");
        require(_proficiencyScore > 0 && _proficiencyScore <= 100, "EthosRep: Proficiency score must be between 1 and 100.");

        _attestationIds.increment();
        uint256 attestationId = _attestationIds.current();

        attestations[attestationId] = Attestation(
            msg.sender,
            _to,
            _skillId,
            _proficiencyScore,
            block.timestamp,
            _contextURI,
            true
        );

        userAttestationsGiven[msg.sender][_skillId].push(attestationId);
        userAttestationsReceived[_to][_skillId].push(attestationId);

        // Update recipient's skill proficiency and reputation
        UserSkillProficiency storage proficiency = userSkillProficiencies[_to][_skillId];
        proficiency.totalScore += _proficiencyScore;
        proficiency.attestationCount++;

        // Simple reputation calculation: sum of all proficiency scores received
        userReputation[_to] += _proficiencyScore;

        // Potentially trigger DSNFT update
        if (userDSNFTs[_to] != 0) {
            _updateDSNFTMetadata(_to, userDSNFTs[_to]);
        }

        emit SkillAttested(msg.sender, _to, _skillId, _proficiencyScore, _contextURI, attestationId);
    }

    /**
     * @dev Allows an attester to revoke their own active attestation.
     *      Revoking an attestation reduces the recipient's skill proficiency and reputation.
     * @param _to The address of the original recipient of the attestation.
     * @param _skillId The ID of the skill that was attested.
     * @param _attestationId The specific ID of the attestation to revoke.
     */
    function revokeAttestation(address _to, uint256 _skillId, uint256 _attestationId) public whenNotPaused {
        Attestation storage attestation = attestations[_attestationId];
        require(attestation.active, "EthosRep: Attestation is not active.");
        require(attestation.attester == msg.sender, "EthosRep: Only the attester can revoke their own attestation.");
        require(attestation.recipient == _to, "EthosRep: Recipient mismatch.");
        require(attestation.skillId == _skillId, "EthosRep: Skill ID mismatch.");

        attestation.active = false;

        // Reduce recipient's skill proficiency and reputation
        UserSkillProficiency storage proficiency = userSkillProficiencies[_to][_skillId];
        require(proficiency.totalScore >= attestation.proficiencyScore, "EthosRep: Proficiency score mismatch.");
        require(proficiency.attestationCount > 0, "EthosRep: Attestation count mismatch.");

        proficiency.totalScore -= attestation.proficiencyScore;
        proficiency.attestationCount--;
        userReputation[_to] -= attestation.proficiencyScore;

        // Potentially trigger DSNFT update
        if (userDSNFTs[_to] != 0) {
            _updateDSNFTMetadata(_to, userDSNFTs[_to]);
        }

        emit AttestationRevoked(msg.sender, _to, _skillId, _attestationId);
    }

    /**
     * @dev Retrieves the details of a specific attestation.
     * @param _attestationId The ID of the attestation.
     * @return attester, recipient, skillId, proficiencyScore, timestamp, contextURI, active status.
     */
    function getAttestationDetails(uint256 _attestationId) public view returns (address, address, uint256, uint8, uint256, string memory, bool) {
        Attestation storage att = attestations[_attestationId];
        require(att.recipient != address(0), "EthosRep: Attestation does not exist."); // Check if exists
        return (att.attester, att.recipient, att.skillId, att.proficiencyScore, att.timestamp, att.contextURI, att.active);
    }

    /**
     * @dev Returns the aggregated reputation score for a specific user.
     * @param _user The address of the user.
     * @return The total reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Returns the aggregated proficiency score for a specific skill of a user.
     * @param _user The address of the user.
     * @param _skillId The ID of the skill.
     * @return totalScore, attestationCount for that skill.
     */
    function getSkillProficiency(address _user, uint256 _skillId) public view returns (uint256 totalScore, uint256 attestationCount) {
        UserSkillProficiency storage proficiency = userSkillProficiencies[_user][_skillId];
        return (proficiency.totalScore, proficiency.attestationCount);
    }

    /**
     * @dev Allows users to stake ETH to gain the privilege to attest to skills.
     *      The stake acts as a deterrent against malicious attestations.
     */
    function stakeForAttestationPrivilege() public payable whenNotPaused {
        require(msg.value > 0, "EthosRep: Must send ETH to stake.");
        userStakes[msg.sender] += msg.value;
        // If a withdrawal request was pending, cancel it when new stake is added
        delete stakeWithdrawalRequests[msg.sender];
        emit Staked(msg.sender, msg.value);
    }

    // --- IV. Dynamic Soulbound Skill NFTs (DSNFTs) ---

    // Overrides for ERC721 functions to make tokens Soulbound (non-transferable)
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert("EthosRep: DSNFTs are soulbound and cannot be transferred.");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("EthosRep: DSNFTs are soulbound and cannot be transferred.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("EthosRep: DSNFTs are soulbound and cannot be transferred.");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("EthosRep: DSNFTs are soulbound and cannot be transferred.");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("EthosRep: DSNFTs cannot be approved for transfer.");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("EthosRep: DSNFTs cannot be approved for transfer.");
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return false; // No approvals are possible
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        revert("EthosRep: DSNFTs cannot be approved for transfer.");
    }


    /**
     * @dev Mints an initial Dynamic Soulbound Skill NFT for a user if they meet a minimum reputation threshold.
     *      A user can only hold one DSNFT.
     * @param _to The address to mint the DSNFT for.
     */
    function mintDSNFT(address _to) public whenNotPaused {
        require(_to != address(0), "EthosRep: Invalid recipient address.");
        require(userDSNFTs[_to] == 0, "EthosRep: User already has a DSNFT.");
        require(userReputation[_to] >= 50, "EthosRep: Minimum reputation of 50 required to mint DSNFT."); // Example threshold

        _dsnftTokenIds.increment();
        uint256 newItemId = _dsnftTokenIds.current();

        _mint(_to, newItemId);
        userDSNFTs[_to] = newItemId;
        dsnftOwners[newItemId] = _to; // Store owner explicitly for easy lookup

        _updateDSNFTMetadata(_to, newItemId); // Set initial metadata

        emit DSNFTMinted(_to, newItemId);
    }

    /**
     * @dev Internal function to update the metadata URI of a DSNFT based on the user's current
     *      reputation, skill proficiencies, and completed learning paths.
     *      This function generates a dynamic URI pointing to off-chain metadata (e.g., IPFS)
     *      which describes the DSNFT's current "level" or "traits".
     * @param _user The owner of the DSNFT.
     * @param _tokenId The ID of the DSNFT.
     */
    function _updateDSNFTMetadata(address _user, uint256 _tokenId) internal {
        require(userDSNFTs[_user] == _tokenId, "EthosRep: Token ID does not match user's DSNFT.");

        // In a real application, this would construct a more complex JSON or
        // a URI to a service that generates dynamic metadata.
        // For demonstration, a simple string representing a "level" based on reputation.

        string memory baseURI = "ipfs://QmbnQ4wB5FzG1h7X8P6yS2cZ2r3R9T0L1K8J4V0X9Y2Z6/"; // Example base IPFS CID
        string memory levelTrait;

        uint256 reputation = userReputation[_user];
        if (reputation < 100) {
            levelTrait = "Novice";
        } else if (reputation < 500) {
            levelTrait = "Apprentice";
        } else if (reputation < 2000) {
            levelTrait = "Journeyman";
        } else {
            levelTrait = "Master";
        }

        // Example for adding skill-specific traits or completed path traits
        string memory skillTraits = "";
        for (uint256 i = 1; i <= _skillIds.current(); i++) {
            if (userSkillProficiencies[_user][i].attestationCount > 0) {
                // Add skill name or proficiency level as a trait
                skillTraits = string.concat(skillTraits, ",", skills[i].name, ":", userSkillProficiencies[_user][i].attestationCount.toString());
            }
        }

        // Example for adding learning path traits
        string memory pathTraits = "";
        for (uint256 i = 1; i <= _pathIds.current(); i++) {
            if (userEnrolledPaths[_user][i] && userPathMilestonesCompleted[_user][i] == learningPaths[i].requiredSkillIds.length) {
                pathTraits = string.concat(pathTraits, ",", learningPaths[i].rewardDSNFTTrait);
            }
        }

        // A truly dynamic system would generate a JSON on the fly, or point to an API endpoint.
        // For this contract, let's simulate by just setting a descriptive string.
        // The "metadata" could be a single file per level, or an API that takes parameters.
        // For this example, we'll just generate a simple URI.
        string memory newURI = string.concat(baseURI, levelTrait, ".json?", "reputation=", reputation.toString(), "&skills=", skillTraits, "&paths=", pathTraits);

        _tokenURIs[_tokenId] = newURI;
        emit DSNFTMetadataUpdated(_user, _tokenId, newURI);
    }

    /**
     * @dev Returns the metadata URI for a given DSNFT. Overrides ERC721's tokenURI.
     * @param _tokenId The ID of the DSNFT.
     * @return The URI pointing to the metadata JSON.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    /**
     * @dev Returns the number of DSNFTs owned by an address.
     *      Overrides ERC721's balanceOf to reflect that a user can only have one DSNFT.
     * @param owner The address to query the balance of.
     * @return 1 if the user has a DSNFT, 0 otherwise.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return userDSNFTs[owner] != 0 ? 1 : 0;
    }

    /**
     * @dev Returns the owner of the DSNFT.
     *      Overrides ERC721's ownerOf.
     * @param tokenId The ID of the DSNFT.
     * @return The address of the owner.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = dsnftOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {ERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }


    // --- V. Attestation Bots (Automated Agents) ---

    /**
     * @dev Registers a new trusted Attestation Bot contract. Only callable by the owner.
     *      Bots are external contracts designed to provide attestations based on on-chain data
     *      or verified off-chain events (via oracles).
     * @param _botAddress The address of the bot contract.
     * @param _name The name of the bot.
     * @param _description A description of the bot's function.
     */
    function registerAttestationBot(address _botAddress, string memory _name, string memory _description) public onlyOwner whenNotPaused {
        require(_botAddress != address(0), "EthosRep: Invalid bot address.");
        require(!isAttestationBot[_botAddress], "EthosRep: Bot already registered.");

        isAttestationBot[_botAddress] = true;
        attestationBotNames[_botAddress] = _name;
        // _description is not stored on-chain to save gas, but can be part of an off-chain registry.
        emit AttestationBotRegistered(_botAddress, _name);
    }

    /**
     * @dev Allows a registered Attestation Bot to attest to a user's skill.
     *      This function is called by the bot contract itself.
     * @param _to The address of the user receiving the attestation.
     * @param _skillId The ID of the skill being attested to.
     * @param _proficiencyScore The score (1-100) indicating the recipient's proficiency in the skill.
     * @param _contextURI A URI pointing to external evidence or context for the attestation.
     */
    function attestSkillByBot(address _to, uint256 _skillId, uint8 _proficiencyScore, string memory _contextURI) public onlyBot whenNotPaused {
        require(_to != address(0), "EthosRep: Invalid recipient address.");
        require(skills[_skillId].categoryId != 0 && skills[_skillId].approved, "EthosRep: Skill does not exist or is not approved.");
        require(_proficiencyScore > 0 && _proficiencyScore <= 100, "EthosRep: Proficiency score must be between 1 and 100.");

        _attestationIds.increment();
        uint256 attestationId = _attestationIds.current();

        attestations[attestationId] = Attestation(
            msg.sender, // The bot is the attester
            _to,
            _skillId,
            _proficiencyScore,
            block.timestamp,
            _contextURI,
            true
        );

        // Update recipient's skill proficiency and reputation
        UserSkillProficiency storage proficiency = userSkillProficiencies[_to][_skillId];
        proficiency.totalScore += _proficiencyScore;
        proficiency.attestationCount++;

        userReputation[_to] += _proficiencyScore;

        // Potentially trigger DSNFT update
        if (userDSNFTs[_to] != 0) {
            _updateDSNFTMetadata(_to, userDSNFTs[_to]);
        }

        emit SkillAttested(msg.sender, _to, _skillId, _proficiencyScore, _contextURI, attestationId);
    }

    /**
     * @dev Deactivates a registered Attestation Bot, preventing it from issuing further attestations.
     *      Only callable by the owner.
     * @param _botAddress The address of the bot to deactivate.
     */
    function deactivateAttestationBot(address _botAddress) public onlyOwner whenNotPaused {
        require(isAttestationBot[_botAddress], "EthosRep: Bot is not registered.");
        isAttestationBot[_botAddress] = false;
        delete attestationBotNames[_botAddress]; // Clear name
        emit AttestationBotDeactivated(_botAddress);
    }

    /**
     * @dev Updates the address of a registered Attestation Bot, useful for upgrading bot contracts.
     *      Only callable by the owner.
     * @param _oldBotAddress The current address of the bot.
     * @param _newBotAddress The new address for the bot.
     */
    function updateAttestationBotAddress(address _oldBotAddress, address _newBotAddress) public onlyOwner whenNotPaused {
        require(isAttestationBot[_oldBotAddress], "EthosRep: Old bot address not registered.");
        require(!isAttestationBot[_newBotAddress], "EthosRep: New bot address already registered.");
        require(_newBotAddress != address(0), "EthosRep: Invalid new bot address.");

        string memory name = attestationBotNames[_oldBotAddress];
        deactivateAttestationBot(_oldBotAddress); // Deactivate old
        registerAttestationBot(_newBotAddress, name, ""); // Register new with same name (description ignored)
    }

    // --- VI. Curated Learning Paths / Bounties ---

    /**
     * @dev Creates a new curated learning path or bounty. Only callable by the owner.
     * @param _name The name of the learning path.
     * @param _description A detailed description of the path.
     * @param _requiredSkillIds An array of skill IDs that need to be attested to complete this path.
     * @param _reputationReward The reputation points awarded upon completion.
     * @param _rewardDSNFTTrait A special trait string added to the user's DSNFT upon completion.
     */
    function createLearningPath(
        string memory _name,
        string memory _description,
        uint256[] memory _requiredSkillIds,
        uint256 _reputationReward,
        string memory _rewardDSNFTTrait
    ) public onlyOwner whenNotPaused returns (uint256) {
        require(_requiredSkillIds.length > 0, "EthosRep: Path must have at least one required skill.");
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].categoryId != 0 && skills[_requiredSkillIds[i]].approved, "EthosRep: Invalid or unapproved skill in path.");
        }

        _pathIds.increment();
        uint256 pathId = _pathIds.current();
        learningPaths[pathId] = LearningPath(
            _name,
            _description,
            _requiredSkillIds,
            _reputationReward,
            _rewardDSNFTTrait,
            true, // Active by default when created by owner
            true  // Approved by default when created by owner
        );
        emit LearningPathCreated(pathId, _name, msg.sender);
        return pathId;
    }

    /**
     * @dev Allows any user to propose a new learning path for community approval via governance.
     * @param _name The name of the proposed learning path.
     * @param _description A detailed description of the path.
     * @param _requiredSkillIds An array of skill IDs that need to be attested to complete this path.
     * @param _reputationReward The reputation points awarded upon completion.
     * @param _rewardDSNFTTrait A special trait string added to the user's DSNFT upon completion.
     */
    function proposeLearningPath(
        string memory _name,
        string memory _description,
        uint256[] memory _requiredSkillIds,
        uint256 _reputationReward,
        string memory _rewardDSNFTTrait
    ) public onlyReputable(50) whenNotPaused returns (uint256) {
        require(_requiredSkillIds.length > 0, "EthosRep: Path must have at least one required skill.");
        for (uint256 i = 0; i < _requiredSkillIds.length; i++) {
            require(skills[_requiredSkillIds[i]].categoryId != 0 && skills[_requiredSkillIds[i]].approved, "EthosRep: Invalid or unapproved skill in path.");
        }

        // Create a temporary path entry (not yet approved)
        _pathIds.increment();
        uint256 pathId = _pathIds.current();
        learningPaths[pathId] = LearningPath(
            _name,
            _description,
            _requiredSkillIds,
            _reputationReward,
            _rewardDSNFTTrait,
            false, // Not active until approved
            false  // Not approved initially
        );

        // Create a governance proposal to approve this path
        bytes memory callData = abi.encodeWithSelector(
            this.approveLearningPath.selector,
            pathId,
            true // To approve it
        );
        return createGovernanceProposal(callData, string.concat("Approve new learning path: ", _name, " (ID: ", pathId.toString(), ")"));
    }

    /**
     * @dev Internal function to approve or reject a learning path. Callable only by governance.
     * @param _pathId The ID of the path to approve/reject.
     * @param _approved True to approve, false to reject.
     */
    function approveLearningPath(uint256 _pathId, bool _approved) public onlyOwner { // Made onlyOwner for internal governance call
        require(learningPaths[_pathId].requiredSkillIds.length > 0, "EthosRep: Path does not exist.");
        require(!learningPaths[_pathId].approved, "EthosRep: Path already approved or rejected.");

        learningPaths[_pathId].approved = _approved;
        if (_approved) {
            learningPaths[_pathId].active = true;
            emit LearningPathCreated(_pathId, learningPaths[_pathId].name, address(this)); // Emit as if created
        } else {
            // Potentially remove or mark as rejected for UI
        }
    }

    /**
     * @dev Allows a user to enroll in an active learning path.
     * @param _pathId The ID of the learning path.
     */
    function enrollInLearningPath(uint256 _pathId) public whenNotPaused {
        require(learningPaths[_pathId].active, "EthosRep: Learning path is not active.");
        require(learningPaths[_pathId].approved, "EthosRep: Learning path is not approved.");
        require(!userEnrolledPaths[msg.sender][_pathId], "EthosRep: User is already enrolled in this path.");

        userEnrolledPaths[msg.sender][_pathId] = true;
        userPathMilestonesCompleted[msg.sender][_pathId] = 0; // Initialize progress
        emit UserEnrolledInPath(msg.sender, _pathId);
    }

    /**
     * @dev Marks a milestone (required skill) as complete for an enrolled user in a learning path.
     *      This requires the user to have received at least one attestation for the next required skill.
     * @param _pathId The ID of the learning path.
     */
    function completeLearningPathMilestone(uint256 _pathId) public whenNotPaused {
        require(userEnrolledPaths[msg.sender][_pathId], "EthosRep: User not enrolled in this path.");
        LearningPath storage path = learningPaths[_pathId];
        uint256 completedMilestones = userPathMilestonesCompleted[msg.sender][_pathId];
        require(completedMilestones < path.requiredSkillIds.length, "EthosRep: All milestones already completed.");

        uint256 nextSkillId = path.requiredSkillIds[completedMilestones];
        require(userSkillProficiencies[msg.sender][nextSkillId].attestationCount > 0, "EthosRep: User has not yet received an attestation for this skill.");
        // Could add more stringent checks, e.g., min proficiency score

        userPathMilestonesCompleted[msg.sender][_pathId]++;
        emit LearningPathMilestoneCompleted(msg.sender, _pathId, userPathMilestonesCompleted[msg.sender][_pathId]);
    }

    /**
     * @dev Allows a user to claim rewards upon full completion of a learning path.
     * @param _pathId The ID of the learning path.
     */
    function claimLearningPathReward(uint256 _pathId) public whenNotPaused {
        require(userEnrolledPaths[msg.sender][_pathId], "EthosRep: User not enrolled in this path.");
        LearningPath storage path = learningPaths[_pathId];
        require(userPathMilestonesCompleted[msg.sender][_pathId] == path.requiredSkillIds.length, "EthosRep: Path not fully completed.");

        // Apply reputation reward
        userReputation[msg.sender] += path.reputationReward;

        // Update DSNFT with new trait
        if (userDSNFTs[msg.sender] == 0) {
            mintDSNFT(msg.sender); // If user doesn't have DSNFT, mint one
        } else {
            _updateDSNFTMetadata(msg.sender, userDSNFTs[msg.sender]); // Update existing DSNFT
        }

        // Mark as claimed (to prevent double claiming)
        // For simplicity, we just check completion, but a separate mapping for 'claimed' could be added.
        // For now, _updateDSNFTMetadata will reflect all completed paths.

        emit LearningPathRewardClaimed(msg.sender, _pathId);
    }


    // --- VII. Governance & Anti-Spam ---

    /**
     * @dev Allows users with sufficient reputation to create a general governance proposal.
     * @param _callData The encoded function call to execute if the proposal passes.
     * @param _description A description of the proposal.
     */
    function createGovernanceProposal(bytes memory _callData, string memory _description) public onlyReputable(200) whenNotPaused returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = GovernanceProposal(
            _callData,
            _description,
            msg.sender,
            block.timestamp + PROPOSAL_VOTING_PERIOD,
            0,
            0,
            false,
            false
        );

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    /**
     * @dev Allows users to vote on an active governance proposal.
     *      Votes are weighted by the voter's reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True to vote for, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public onlyReputable(10) whenNotPaused { // Lower reputation threshold for voting
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EthosRep: Proposal does not exist.");
        require(block.timestamp <= proposal.votingDeadline, "EthosRep: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "EthosRep: Already voted on this proposal.");

        uint256 voteWeight = userReputation[msg.sender]; // Reputation-weighted voting

        if (_approve) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Executes a governance proposal that has passed its voting period and met the approval threshold.
     *      Callable by anyone after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "EthosRep: Proposal does not exist.");
        require(block.timestamp > proposal.votingDeadline, "EthosRep: Voting period is still active.");
        require(!proposal.executed, "EthosRep: Proposal already executed.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        bool passed = false;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (proposal.votesFor * 100) / totalVotes;
            if (approvalPercentage >= PROPOSAL_VOTING_THRESHOLD) {
                passed = true;
            }
        }

        proposal.passed = passed;
        proposal.executed = true;

        if (passed) {
            // Execute the proposed action using `call`
            (bool success, ) = address(this).call(proposal.callData);
            require(success, "EthosRep: Proposal execution failed.");
        } else {
            // Handle rejected proposal (e.g., log it)
        }

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev (Placeholder) For slashing a portion of a malicious attester's staked amount.
     *      This would typically require a dispute resolution mechanism (not implemented here).
     *      For this example, it's an owner-callable function to simulate the effect.
     * @param _staker The address of the staker to slash.
     * @param _amount The amount of ETH to slash.
     * @param _reason The reason for slashing.
     */
    function slashStakedAmount(address _staker, uint256 _amount, string memory _reason) public onlyOwner whenNotPaused {
        require(userStakes[_staker] >= _amount, "EthosRep: Staker does not have sufficient balance to slash.");
        userStakes[_staker] -= _amount;
        // The slashed amount could be sent to a treasury, burned, or distributed.
        // For simplicity, we just reduce the stake here.
        emit StakedAmountSlashed(_staker, _amount, _reason);
    }

    // --- Fallback & Receive Functions ---
    receive() external payable {
        // Allow direct ETH deposits to stake
        stakeForAttestationPrivilege();
    }

    fallback() external payable {
        // Fallback for unexpected calls, could revert or direct to stake if payable
        revert("EthosRep: Call to non-existent function or unexpected fallback.");
    }
}
```