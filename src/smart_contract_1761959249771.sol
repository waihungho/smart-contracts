Okay, this is an ambitious and exciting challenge! I'll design a smart contract named **`AptitudeLink`** that acts as a decentralized talent and reputation protocol. It incorporates several advanced concepts:

1.  **Soulbound Achievement NFTs (SBTs):** Non-transferable NFTs representing a talent's verified skills and reputation, with dynamic metadata updates.
2.  **Verifier-Attested Skill System:** Skills aren't just self-claimed; they can be verified by staked, governance-approved verifiers, adding a layer of trust.
3.  **Decentralized Task Escrow & Dispute Resolution:** A robust system for secure payments and conflict resolution, potentially involving governance.
4.  **On-chain Governance:** Community-driven evolution of the protocol via proposals and token-weighted voting (requires an external governance token, but the mechanics are here).
5.  **Staked Verifiers:** Verifiers put up collateral that can be slashed for malicious behavior, ensuring accountability.
6.  **Dynamic Reputation Scoring:** Achievement NFTs dynamically update their on-chain metadata (e.g., reputation points, task count, average rating) based on ongoing performance.

---

## AptitudeLink: Decentralized Talent & Reputation Protocol

**Contract Name:** `AptitudeLink`

**Description:**
`AptitudeLink` is a novel decentralized platform connecting talent with tasks, focusing on verifiable skills, reputation, and community governance. It introduces Soulbound Achievement NFTs (SBTs) to represent a talent's on-chain professional identity and uses a staked verifier system to attest to skill competencies. Tasks are managed through a secure escrow system with built-in dispute resolution, while protocol evolution is driven by on-chain governance.

---

### **Outline and Function Summary:**

This contract utilizes a modular approach, integrating several key functionalities. It interacts with an external ERC20 token for payments, staking, and governance.

**I. Core Setup & Administration (`Ownable`, `Pausable`)**
   - Essential functions for contract initialization, pausing, and setting administrative parameters.
   1.  `constructor`: Initializes the contract, sets the owner, and specifies the payment/staking token.
   2.  `setProtocolFeeRecipient`: Allows the owner to update the address receiving protocol fees.
   3.  `setProtocolFee`: Allows the owner to update the percentage fee taken from completed tasks.
   4.  `pauseContract`: Emergency function to pause critical contract operations.
   5.  `unpauseContract`: Unpauses the contract after an emergency.

**II. Talent Profile Management**
   - Functions for users to register, update, and retrieve their decentralized professional profiles.
   6.  `registerTalentProfile`: Allows a user to create their talent profile.
   7.  `updateTalentProfile`: Enables talent to update their profile details.
   8.  `getTalentProfile`: (View) Retrieves a talent's profile information.

**III. Skill Categories & Verification System (`Staked Verifiers`)**
   - Defines a system for skills to be proposed, added, claimed by talent, and crucially, attested by approved, staked verifiers.
   9.  `proposeSkillCategory`: (Governance) Submits a proposal for a new broad skill category (e.g., "Web Development").
   10. `addSkillToCategory`: (Governance) Submits a proposal to add a specific skill (e.g., "Solidity") to an approved category.
   11. `claimSkillProficiency`: Allows talent to declare proficiency in an approved skill.
   12. `requestSkillVerification`: Talent can request a verifier to formally attest to their skill proficiency.
   13. `attestSkillCompetence`: (Verifier) A registered verifier confirms a talent's proficiency in a claimed skill, after internal/external review.

**IV. Verifier Management**
   - Manages the lifecycle of verifiers, including registration, staking, and potential slashing for misconduct.
   14. `registerVerifier`: (Governance) Approves an address as a verifier and requires them to stake tokens.
   15. `deregisterVerifier`: (Governance/Verifier) Removes a verifier, releasing their stake after a cool-down period.
   16. `slashVerifierStake`: (Governance) Penalizes a verifier by slashing their staked tokens for proven malicious behavior (e.g., false attestations, biased dispute resolution).

**V. Task Lifecycle & Escrow (`Secure Escrow`, `Dispute Resolution`)**
   - Core functionality for clients to create tasks, talent to apply, secure payment escrow, and dispute resolution.
   17. `createTask`: A client posts a task, specifying details, bounty, and staking the payment.
   18. `applyForTask`: Talent applies to an open task.
   19. `selectTalent`: The client chooses a talent from the applicants.
   20. `submitWork`: The selected talent submits proof of completed work.
   21. `reviewAndApproveWork`: The client reviews and approves the work, releasing payment, deducting fees, and triggering Achievement NFT updates.
   22. `initiateDispute`: Either the client or talent can initiate a dispute if there's disagreement over task completion.
   23. `resolveDispute`: (Governance/Arbiters) Resolves an active dispute, determining payment distribution.

**VI. Achievement NFTs (SBTs) & Reputation (`ERC721`, `Dynamic Metadata`)**
   - Implements Soulbound Tokens (SBTs) that represent a talent's immutable, dynamic on-chain reputation.
   24. `mintAchievementNFT`: (Internal) Mints a new Achievement NFT for a talent upon their first successful task completion.
   25. `updateAchievementNFTMetadata`: (Internal) Dynamically updates the metadata of an existing Achievement NFT based on new task completions, ratings, and verified skills.
   26. `getAchievementNFTUri`: (View) Returns the URI for an Achievement NFT's metadata, which dynamically reflects reputation.

**VII. Governance (`Proposal System`, `Voting`)**
   - Enables community members (holding `_governanceToken`) to propose and vote on protocol changes.
   27. `submitGovernanceProposal`: Allows a user with governance power to propose changes (e.g., fee adjustment, new skill categories, verifier registration).
   28. `voteOnProposal`: Users vote on active proposals using their staked governance tokens.
   29. `executeProposal`: Executes a successfully voted-on proposal.
   30. `getProposalDetails`: (View) Retrieves the details and current status of a proposal.

**VIII. Funds Management (`ERC20 Deposits/Withdrawals`)**
   - Handles deposits and withdrawals of the specified ERC20 token for task bounties, verifier stakes, and general user balances.
   31. `depositFunds`: Allows users to deposit `_paymentToken` into their contract balance for tasks or staking.
   32. `withdrawFunds`: Allows users to withdraw their available `_paymentToken` balance.
   33. `getAvailableBalance`: (View) Returns a user's available `_paymentToken` balance within the contract.

---

### **Source Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol"; // For advanced signature-based attestations if needed

error AptitudeLink__AlreadyRegistered();
error AptitudeLink__NotRegistered();
error AptitudeLink__InvalidSkillCategory();
error AptitudeLink__SkillAlreadyClaimed();
error AptitudeLink__SkillNotClaimed();
error AptitudeLink__NotVerifier();
error AptitudeLink__VerifierAlreadyRegistered();
error AptitudeLink__InsufficientStake();
error AptitudeLink__TaskNotFound();
error AptitudeLink__TaskNotOpen();
error AptitudeLink__TaskAlreadyApplied();
error AptitudeLink__NotTaskCreator();
error AptitudeLink__NotSelectedTalent();
error AptitudeLink__TaskAlreadyApproved();
error AptitudeLink__TaskNotInDispute();
error AptitudeLink__InvalidProposalId();
error AptitudeLink__ProposalNotActive();
error AptitudeLink__ProposalAlreadyVoted();
error AptitudeLink__ProposalExpired();
error AptitudeLink__ProposalNotPassed();
error AptitudeLink__InsufficientFunds();
error AptitudeLink__NoFundsToWithdraw();
error AptitudeLink__ZeroAddressNotAllowed();
error AptitudeLink__InvalidFee();
error AptitudeLink__AccessDenied();
error AptitudeLink__CannotDeregisterActiveVerifier();
error AptitudeLink__MetadataGenerationFailed();

contract AptitudeLink is Ownable, Pausable, ERC721 {
    using Strings for uint256;

    // --- State Variables ---

    IERC20 public immutable _paymentToken; // Token used for bounties, fees, and verifier staking
    IERC20 public immutable _governanceToken; // Token used for governance voting power

    address public _feeRecipient;
    uint256 public _protocolFeeBasisPoints; // e.g., 500 for 5% (500/10000)

    uint256 public constant VERIFIER_STAKE_AMOUNT = 10 ether; // Example stake amount for verifiers
    uint256 public constant VERIFIER_COOLDOWN_PERIOD = 7 days; // Time before stake can be fully withdrawn

    // --- Enums ---

    enum TaskStatus { Open, Applied, Selected, Submitted, Approved, Disputed, Resolved, Cancelled }
    enum ProposalStatus { Active, Passed, Failed, Executed }
    enum VoteType { Against, For }

    // --- Structs ---

    struct TalentProfile {
        string name;
        string bio;
        string contactInfo; // e.g., IPFS CID for detailed contact or social links
        address[] claimedSkills; // Array of skillCategoryHash for claimed skills
        mapping(address => bool) isSkillVerified; // Maps skillCategoryHash to verification status
        uint256 achievementNftId; // ID of their Soulbound Achievement NFT
        bool exists;
    }

    struct SkillCategory {
        string name;
        mapping(address => string) skills; // hash of skill => skill name
        address[] skillHashes; // Array of skill hashes within this category
        bool exists;
    }

    struct Verifier {
        uint256 stakedAmount;
        uint256 deregisterCooldownEnd; // Timestamp when stake can be withdrawn
        bool isActive;
    }

    struct Task {
        uint256 id;
        address client;
        string title;
        string description; // IPFS CID for detailed description
        uint256 bounty; // Amount in _paymentToken
        address selectedTalent;
        address[] applicants;
        TaskStatus status;
        uint256 createdAt;
        uint256 completedAt;
        uint256 disputeResolutionTime; // Timestamp for dispute resolution deadline
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description; // IPFS CID for proposal details
        bytes callData; // Encoded function call if the proposal involves on-chain execution
        address target; // Target contract for execution
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalStatus status;
    }

    // --- Mappings ---

    mapping(address => TalentProfile) public talentProfiles;
    mapping(address => bool) public isTalentRegistered;

    mapping(address => SkillCategory) public skillCategories; // hash(categoryName) => SkillCategory
    mapping(bytes32 => address[]) public categoryToSkillHashes; // hash(categoryName) => [hash(skill1), hash(skill2)]
    mapping(address => bool) public isSkillCategoryApproved; // hash(categoryName) => bool
    mapping(address => bool) public isSkillApproved; // hash(skillName) => bool

    mapping(address => Verifier) public verifiers;
    mapping(address => bool) public isVerifier;

    mapping(uint256 => Task) public tasks;
    uint256 public nextTaskId;

    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;

    mapping(address => uint256) public userBalances; // For _paymentToken

    // --- Events ---

    event TalentRegistered(address indexed talentAddress, string name);
    event TalentProfileUpdated(address indexed talentAddress);
    event SkillCategoryProposed(uint256 indexed proposalId, address indexed categoryHash, string categoryName);
    event SkillAddedToCategory(uint256 indexed proposalId, address indexed categoryHash, string categoryName, address indexed skillHash, string skillName);
    event SkillClaimed(address indexed talentAddress, address indexed skillHash);
    event SkillAttested(address indexed talentAddress, address indexed skillHash, address indexed verifierAddress);
    event VerifierRegistered(address indexed verifierAddress);
    event VerifierDeregistered(address indexed verifierAddress);
    event VerifierStakeSlashed(address indexed verifierAddress, uint256 amount);
    event TaskCreated(uint256 indexed taskId, address indexed client, uint256 bounty, string title);
    event TaskApplied(uint256 indexed taskId, address indexed talentAddress);
    event TalentSelected(uint256 indexed taskId, address indexed client, address indexed talentAddress);
    event WorkSubmitted(uint256 indexed taskId, address indexed talentAddress);
    event WorkApproved(uint256 indexed taskId, address indexed client, address indexed talentAddress, uint256 bounty);
    event DisputeInitiated(uint256 indexed taskId, address indexed disputer);
    event DisputeResolved(uint256 indexed taskId, TaskStatus finalStatus, address winner, uint256 amountToWinner);
    event AchievementNFTMinted(address indexed talentAddress, uint256 indexed tokenId);
    event AchievementNFTMetadataUpdated(address indexed talentAddress, uint256 indexed tokenId, string newUri);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, VoteType voteType, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount);
    event FeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeeUpdated(uint256 newFeeBasisPoints);

    // --- Constructor ---

    constructor(address paymentTokenAddress, address governanceTokenAddress, address initialFeeRecipient)
        ERC721("AptitudeLink Achievement", "ALA")
        Ownable(msg.sender)
        Pausable()
    {
        if (paymentTokenAddress == address(0) || governanceTokenAddress == address(0) || initialFeeRecipient == address(0)) {
            revert AptitudeLink__ZeroAddressNotAllowed();
        }
        _paymentToken = IERC20(paymentTokenAddress);
        _governanceToken = IERC20(governanceTokenAddress);
        _feeRecipient = initialFeeRecipient;
        _protocolFeeBasisPoints = 500; // 5% by default (500/10000)
        nextTaskId = 1;
        nextProposalId = 1;
    }

    // --- Modifiers ---

    modifier onlyTalent() {
        if (!isTalentRegistered[msg.sender]) revert AptitudeLink__NotRegistered();
        _;
    }

    modifier onlyVerifier() {
        if (!isVerifier[msg.sender] || !verifiers[msg.sender].isActive) revert AptitudeLink__NotVerifier();
        _;
    }

    modifier onlyTaskClient(uint256 _taskId) {
        if (tasks[_taskId].client != msg.sender) revert AptitudeLink__NotTaskCreator();
        _;
    }

    modifier onlySelectedTalent(uint256 _taskId) {
        if (tasks[_taskId].selectedTalent != msg.sender) revert AptitudeLink__NotSelectedTalent();
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        if (proposals[_proposalId].status != ProposalStatus.Active) revert AptitudeLink__ProposalNotActive();
        if (block.number > proposals[_proposalId].endBlock) revert AptitudeLink__ProposalExpired();
        _;
    }

    // --- I. Core Setup & Administration ---

    /**
     * @dev Updates the address that receives protocol fees.
     * @param _newRecipient The new address for fee collection.
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        if (_newRecipient == address(0)) revert AptitudeLink__ZeroAddressNotAllowed();
        _feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    /**
     * @dev Updates the protocol fee percentage.
     * @param _newFeeBasisPoints The new fee in basis points (e.g., 100 for 1%, 500 for 5%). Max 1000 (10%).
     */
    function setProtocolFee(uint256 _newFeeBasisPoints) external onlyOwner {
        if (_newFeeBasisPoints > 1000) revert AptitudeLink__InvalidFee(); // Max 10%
        _protocolFeeBasisPoints = _newFeeBasisPoints;
        emit ProtocolFeeUpdated(_newFeeBasisPoints);
    }

    /**
     * @dev Pauses the contract in case of an emergency.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- II. Talent Profile Management ---

    /**
     * @dev Allows a user to register their talent profile.
     * @param _name Talent's display name.
     * @param _bio Talent's short biography (IPFS CID recommended for long text).
     * @param _contactInfo IPFS CID or link for detailed contact/portfolio.
     */
    function registerTalentProfile(string calldata _name, string calldata _bio, string calldata _contactInfo)
        external
        whenNotPaused
    {
        if (isTalentRegistered[msg.sender]) revert AptitudeLink__AlreadyRegistered();

        talentProfiles[msg.sender] = TalentProfile({
            name: _name,
            bio: _bio,
            contactInfo: _contactInfo,
            claimedSkills: new address[](0),
            exists: true,
            achievementNftId: 0 // Will be set upon first successful task completion
        });
        isTalentRegistered[msg.sender] = true;
        emit TalentRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows talent to update their profile details.
     * @param _name New name.
     * @param _bio New bio (IPFS CID recommended).
     * @param _contactInfo New contact info (IPFS CID recommended).
     */
    function updateTalentProfile(string calldata _name, string calldata _bio, string calldata _contactInfo)
        external
        onlyTalent
        whenNotPaused
    {
        TalentProfile storage profile = talentProfiles[msg.sender];
        profile.name = _name;
        profile.bio = _bio;
        profile.contactInfo = _contactInfo;
        emit TalentProfileUpdated(msg.sender);
    }

    /**
     * @dev Retrieves a talent's profile information.
     * @param _talentAddress The address of the talent.
     * @return name, bio, contactInfo, claimedSkills, achievementNftId, exists.
     */
    function getTalentProfile(address _talentAddress)
        external
        view
        returns (string memory name, string memory bio, string memory contactInfo, address[] memory claimedSkills, uint256 achievementNftId, bool exists)
    {
        TalentProfile storage profile = talentProfiles[_talentAddress];
        return (profile.name, profile.bio, profile.contactInfo, profile.claimedSkills, profile.achievementNftId, profile.exists);
    }

    // --- III. Skill Categories & Verification System ---

    /**
     * @dev Allows governance to propose a new skill category.
     * @param _categoryName The name of the new skill category.
     * @param _description IPFS CID for detailed description of the category.
     */
    function proposeSkillCategory(string calldata _categoryName, string calldata _description)
        external
        whenNotPaused
    {
        // Requires governance voting. This function only submits the proposal.
        // A governance token holder would call this.
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: abi.encodeWithSelector(this.executeAddSkillCategory.selector, _categoryName),
            target: address(this),
            startBlock: block.number,
            endBlock: block.number + 100, // Example: 100 blocks voting period
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });
        emit SkillCategoryProposed(proposalId, address(uint160(uint256(keccak256(abi.encodePacked(_categoryName))))), _categoryName);
        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev Internal function to add a skill category after a successful governance vote.
     * Only callable by governance `executeProposal`.
     * @param _categoryName The name of the skill category to add.
     */
    function executeAddSkillCategory(string calldata _categoryName) external onlyOwner {
        // Only callable by this contract itself via governance `executeProposal`
        address categoryHash = address(uint160(uint256(keccak256(abi.encodePacked(_categoryName)))));
        if (isSkillCategoryApproved[categoryHash]) revert AptitudeLink__InvalidSkillCategory(); // Already exists

        skillCategories[categoryHash] = SkillCategory({
            name: _categoryName,
            skills: new mapping(address => string)(),
            skillHashes: new address[](0),
            exists: true
        });
        isSkillCategoryApproved[categoryHash] = true;
    }

    /**
     * @dev Allows governance to propose adding a specific skill to an approved category.
     * @param _categoryName The name of the category to add the skill to.
     * @param _skillName The name of the skill to add.
     * @param _description IPFS CID for detailed description of the skill.
     */
    function addSkillToCategory(string calldata _categoryName, string calldata _skillName, string calldata _description)
        external
        whenNotPaused
    {
        address categoryHash = address(uint160(uint256(keccak256(abi.encodePacked(_categoryName)))));
        if (!isSkillCategoryApproved[categoryHash]) revert AptitudeLink__InvalidSkillCategory();

        // Requires governance voting. This function only submits the proposal.
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: abi.encodeWithSelector(this.executeAddSkillToCategory.selector, _categoryName, _skillName),
            target: address(this),
            startBlock: block.number,
            endBlock: block.number + 100,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });
        emit SkillAddedToCategory(proposalId, categoryHash, _categoryName, address(uint160(uint256(keccak256(abi.encodePacked(_skillName))))), _skillName);
        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev Internal function to add a specific skill to a category after a successful governance vote.
     * Only callable by governance `executeProposal`.
     * @param _categoryName The name of the category.
     * @param _skillName The name of the skill to add.
     */
    function executeAddSkillToCategory(string calldata _categoryName, string calldata _skillName) external onlyOwner {
        // Only callable by this contract itself via governance `executeProposal`
        address categoryHash = address(uint160(uint256(keccak256(abi.encodePacked(_categoryName)))));
        address skillHash = address(uint160(uint256(keccak256(abi.encodePacked(_skillName)))));

        if (!isSkillCategoryApproved[categoryHash]) revert AptitudeLink__InvalidSkillCategory();
        if (isSkillApproved[skillHash]) return; // Already exists

        SkillCategory storage category = skillCategories[categoryHash];
        category.skills[skillHash] = _skillName;
        category.skillHashes.push(skillHash);
        isSkillApproved[skillHash] = true;
    }

    /**
     * @dev Allows talent to claim proficiency in an approved skill.
     * @param _skillName The name of the skill being claimed.
     */
    function claimSkillProficiency(string calldata _skillName) external onlyTalent whenNotPaused {
        address skillHash = address(uint160(uint256(keccak256(abi.encodePacked(_skillName)))));
        if (!isSkillApproved[skillHash]) revert AptitudeLink__InvalidSkillCategory(); // Skill not approved

        TalentProfile storage profile = talentProfiles[msg.sender];
        for (uint256 i = 0; i < profile.claimedSkills.length; i++) {
            if (profile.claimedSkills[i] == skillHash) revert AptitudeLink__SkillAlreadyClaimed();
        }
        profile.claimedSkills.push(skillHash);
        emit SkillClaimed(msg.sender, skillHash);
    }

    /**
     * @dev Allows talent to request a verifier to attest their proficiency in a specific skill.
     * @param _skillName The name of the skill to be verified.
     * @param _verifierAddress The address of the verifier requested.
     */
    function requestSkillVerification(string calldata _skillName, address _verifierAddress)
        external
        onlyTalent
        whenNotPaused
    {
        address skillHash = address(uint160(uint256(keccak256(abi.encodePacked(_skillName)))));
        if (!isSkillApproved[skillHash]) revert AptitudeLink__InvalidSkillCategory();
        if (!isVerifier[_verifierAddress] || !verifiers[_verifierAddress].isActive) revert AptitudeLink__NotVerifier();

        TalentProfile storage profile = talentProfiles[msg.sender];
        bool claimed = false;
        for (uint256 i = 0; i < profile.claimedSkills.length; i++) {
            if (profile.claimedSkills[i] == skillHash) {
                claimed = true;
                break;
            }
        }
        if (!claimed) revert AptitudeLink__SkillNotClaimed();

        // In a real system, this would involve off-chain proof submission and a payment to the verifier.
        // For this contract, it primarily serves as a signal. The actual attestation happens in attestSkillCompetence.
        // Could add an event: emit SkillVerificationRequested(msg.sender, skillHash, _verifierAddress);
    }

    /**
     * @dev A registered verifier attests to a talent's proficiency in a specific skill.
     * This implies the verifier has completed an off-chain due diligence process.
     * @param _talentAddress The address of the talent.
     * @param _skillName The name of the skill being attested.
     */
    function attestSkillCompetence(address _talentAddress, string calldata _skillName)
        external
        onlyVerifier
        whenNotPaused
    {
        address skillHash = address(uint160(uint256(keccak256(abi.encodePacked(_skillName)))));
        if (!isTalentRegistered[_talentAddress]) revert AptitudeLink__NotRegistered();
        if (!isSkillApproved[skillHash]) revert AptitudeLink__InvalidSkillCategory();

        TalentProfile storage profile = talentProfiles[_talentAddress];
        bool claimed = false;
        for (uint256 i = 0; i < profile.claimedSkills.length; i++) {
            if (profile.claimedSkills[i] == skillHash) {
                claimed = true;
                break;
            }
        }
        if (!claimed) revert AptitudeLink__SkillNotClaimed();

        profile.isSkillVerified[skillHash] = true;
        // If talent has an NFT, update its metadata
        if (profile.achievementNftId != 0) {
            _updateAchievementNFTMetadata(_talentAddress, profile.achievementNftId);
        }
        emit SkillAttested(_talentAddress, skillHash, msg.sender);
    }

    // --- IV. Verifier Management ---

    /**
     * @dev Allows governance to register a new verifier. Requires the verifier to stake tokens.
     * @param _verifierAddress The address to register as a verifier.
     * @param _description IPFS CID for verifier's credentials/details.
     */
    function registerVerifier(address _verifierAddress, string calldata _description)
        external
        whenNotPaused
    {
        // Requires governance voting. This function only submits the proposal.
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: abi.encodeWithSelector(this.executeRegisterVerifier.selector, _verifierAddress),
            target: address(this),
            startBlock: block.number,
            endBlock: block.number + 100,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });
        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev Internal function to register a verifier after a successful governance vote.
     * Only callable by governance `executeProposal`.
     * @param _verifierAddress The address to register as a verifier.
     */
    function executeRegisterVerifier(address _verifierAddress) external onlyOwner {
        if (isVerifier[_verifierAddress] && verifiers[_verifierAddress].isActive) revert AptitudeLink__VerifierAlreadyRegistered();

        // Verifier must deposit stake first via depositFunds
        if (userBalances[_verifierAddress] < VERIFIER_STAKE_AMOUNT) revert AptitudeLink__InsufficientFunds();

        userBalances[_verifierAddress] -= VERIFIER_STAKE_AMOUNT; // Move from user's available to verifier stake
        verifiers[_verifierAddress] = Verifier({
            stakedAmount: VERIFIER_STAKE_AMOUNT,
            deregisterCooldownEnd: 0,
            isActive: true
        });
        isVerifier[_verifierAddress] = true;
        emit VerifierRegistered(_verifierAddress);
    }

    /**
     * @dev Allows governance or the verifier themselves to initiate deregistration.
     * Stake is locked for a cooldown period.
     * @param _verifierAddress The address of the verifier to deregister.
     */
    function deregisterVerifier(address _verifierAddress) external whenNotPaused {
        if (!isVerifier[_verifierAddress] || !verifiers[_verifierAddress].isActive) revert AptitudeLink__NotVerifier();
        if (msg.sender != owner() && msg.sender != _verifierAddress) revert AptitudeLink__AccessDenied();

        // Implement a check if verifier has any open disputes or active attestations needed
        // For simplicity, this is omitted, but would be crucial for a production system.

        verifiers[_verifierAddress].isActive = false;
        verifiers[_verifierAddress].deregisterCooldownEnd = block.timestamp + VERIFIER_COOLDOWN_PERIOD;

        // Optionally, could make this require governance vote for non-self deregistration
        emit VerifierDeregistered(_verifierAddress);
    }

    /**
     * @dev Allows a verifier to withdraw their stake after the cooldown period.
     */
    function withdrawVerifierStake() external onlyVerifier whenNotPaused {
        Verifier storage verifier = verifiers[msg.sender];
        if (verifier.isActive) revert AptitudeLink__CannotDeregisterActiveVerifier();
        if (block.timestamp < verifier.deregisterCooldownEnd) revert AptitudeLink__InsufficientStake(); // Cooldown not over

        uint256 amount = verifier.stakedAmount;
        verifier.stakedAmount = 0;
        isVerifier[msg.sender] = false; // Fully remove verifier status
        _safeTransferERC20(msg.sender, amount); // Transfer from contract directly, not internal balance
        emit FundsWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Allows governance to slash a verifier's stake for proven misconduct.
     * @param _verifierAddress The address of the verifier to slash.
     * @param _amount The amount of tokens to slash.
     * @param _reason IPFS CID or string explaining the reason for slashing.
     */
    function slashVerifierStake(address _verifierAddress, uint256 _amount, string calldata _reason)
        external
        onlyOwner // Could be extended to governance vote
        whenNotPaused
    {
        if (!isVerifier[_verifierAddress]) revert AptitudeLink__NotVerifier();
        Verifier storage verifier = verifiers[_verifierAddress];
        if (_amount > verifier.stakedAmount) _amount = verifier.stakedAmount; // Slash full amount if requested is too high

        verifier.stakedAmount -= _amount;
        if (verifier.stakedAmount == 0) {
            verifier.isActive = false;
            isVerifier[_verifierAddress] = false;
        }
        // Slashed amount goes to fee recipient or a DAO treasury
        _safeTransferERC20(_feeRecipient, _amount);
        emit VerifierStakeSlashed(_verifierAddress, _amount);
    }

    // --- V. Task Lifecycle & Escrow ---

    /**
     * @dev A client posts a task, staking the bounty amount.
     * @param _title Task title.
     * @param _description IPFS CID for detailed task description.
     * @param _bounty Amount of _paymentToken for the task.
     * @param _durationDays Recommended duration for the task.
     */
    function createTask(string calldata _title, string calldata _description, uint256 _bounty, uint256 _durationDays)
        external
        whenNotPaused
    {
        if (_bounty == 0) revert AptitudeLink__InsufficientFunds();
        if (userBalances[msg.sender] < _bounty) revert AptitudeLink__InsufficientFunds();

        userBalances[msg.sender] -= _bounty; // Move bounty from client's available balance to escrow

        uint256 currentId = nextTaskId++;
        tasks[currentId] = Task({
            id: currentId,
            client: msg.sender,
            title: _title,
            description: _description,
            bounty: _bounty,
            selectedTalent: address(0),
            applicants: new address[](0),
            status: TaskStatus.Open,
            createdAt: block.timestamp,
            completedAt: 0,
            disputeResolutionTime: 0
        });
        emit TaskCreated(currentId, msg.sender, _bounty, _title);
    }

    /**
     * @dev Allows talent to apply for an open task.
     * @param _taskId The ID of the task.
     */
    function applyForTask(uint256 _taskId) external onlyTalent whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert AptitudeLink__TaskNotFound();
        if (task.status != TaskStatus.Open) revert AptitudeLink__TaskNotOpen();

        for (uint256 i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == msg.sender) revert AptitudeLink__TaskAlreadyApplied();
        }

        task.applicants.push(msg.sender);
        task.status = TaskStatus.Applied; // Task moves to applied once someone applies
        emit TaskApplied(_taskId, msg.sender);
    }

    /**
     * @dev The client selects a talent for the task from the applicants.
     * @param _taskId The ID of the task.
     * @param _talentAddress The address of the talent selected.
     */
    function selectTalent(uint256 _taskId, address _talentAddress)
        external
        onlyTaskClient(_taskId)
        whenNotPaused
    {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert AptitudeLink__TaskNotFound();
        if (task.status != TaskStatus.Applied && task.status != TaskStatus.Open) revert AptitudeLink__TaskNotOpen(); // Allow selection from open/applied

        bool isApplicant = false;
        for (uint256 i = 0; i < task.applicants.length; i++) {
            if (task.applicants[i] == _talentAddress) {
                isApplicant = true;
                break;
            }
        }
        if (!isApplicant) revert AptitudeLink__NotRegistered(); // Talent must have applied

        task.selectedTalent = _talentAddress;
        task.status = TaskStatus.Selected;
        emit TalentSelected(_taskId, msg.sender, _talentAddress);
    }

    /**
     * @dev The selected talent submits proof of work completion.
     * @param _taskId The ID of the task.
     * @param _workProof IPFS CID or link to the completed work proof.
     */
    function submitWork(uint256 _taskId, string calldata _workProof)
        external
        onlySelectedTalent(_taskId)
        whenNotPaused
    {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert AptitudeLink__TaskNotFound();
        if (task.status != TaskStatus.Selected) revert AptitudeLink__AccessDenied(); // Only selected talent can submit

        // In a real system, _workProof would likely be an IPFS CID for submitted files.
        // For simplicity, we just change status.
        task.status = TaskStatus.Submitted;
        emit WorkSubmitted(_taskId, msg.sender);
    }

    /**
     * @dev The client reviews and approves the work, releasing payment and updating reputation.
     * @param _taskId The ID of the task.
     * @param _rating A rating for the talent (e.g., 1-5, for reputation calculation).
     */
    function reviewAndApproveWork(uint256 _taskId, uint256 _rating)
        external
        onlyTaskClient(_taskId)
        whenNotPaused
    {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert AptitudeLink__TaskNotFound();
        if (task.status != TaskStatus.Submitted) revert AptitudeLink__TaskAlreadyApproved();
        if (_rating < 1 || _rating > 5) revert AptitudeLink__InvalidFee(); // Using InvalidFee error for simplicity, better to have a specific one.

        task.status = TaskStatus.Approved;
        task.completedAt = block.timestamp;

        // Calculate fees
        uint256 fee = (task.bounty * _protocolFeeBasisPoints) / 10000;
        uint256 talentPayment = task.bounty - fee;

        // Transfer funds
        _safeTransferERC20(task.selectedTalent, talentPayment);
        _safeTransferERC20(_feeRecipient, fee);

        // Update talent's Achievement NFT
        TalentProfile storage talentProfile = talentProfiles[task.selectedTalent];
        if (talentProfile.achievementNftId == 0) {
            _mintAchievementNFT(task.selectedTalent);
        }
        _updateAchievementNFTMetadata(task.selectedTalent, talentProfile.achievementNftId);

        emit WorkApproved(_taskId, msg.sender, task.selectedTalent, talentPayment);
    }

    /**
     * @dev Either the client or the selected talent can initiate a dispute.
     * @param _taskId The ID of the task.
     */
    function initiateDispute(uint256 _taskId) external whenNotPaused {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert AptitudeLink__TaskNotFound();
        if (task.status != TaskStatus.Submitted && task.status != TaskStatus.Selected) revert AptitudeLink__TaskNotInDispute(); // Can dispute if work not submitted or not approved

        if (msg.sender != task.client && msg.sender != task.selectedTalent) revert AptitudeLink__AccessDenied();

        task.status = TaskStatus.Disputed;
        task.disputeResolutionTime = block.timestamp + 7 days; // Example 7 days for resolution
        emit DisputeInitiated(_taskId, msg.sender);
    }

    /**
     * @dev (Governance/Arbiters) Resolves an active dispute, determining payment distribution.
     * This function would ideally be called after an off-chain arbitration process.
     * @param _taskId The ID of the task.
     * @param _resolutionStatus The final status (e.g., Approved, Cancelled).
     * @param _amountToTalent The amount of bounty to be paid to the talent.
     */
    function resolveDispute(uint256 _taskId, TaskStatus _resolutionStatus, uint256 _amountToTalent)
        external
        onlyOwner // For simplicity, owner acts as arbiter. In production, a DAO or dedicated arbiters.
        whenNotPaused
    {
        Task storage task = tasks[_taskId];
        if (task.id == 0) revert AptitudeLink__TaskNotFound();
        if (task.status != TaskStatus.Disputed) revert AptitudeLink__TaskNotInDispute();
        if (block.timestamp > task.disputeResolutionTime) revert AptitudeLink__ProposalExpired(); // Using proposal expired for simplicity.

        uint256 totalBounty = task.bounty;
        uint256 fee = (totalBounty * _protocolFeeBasisPoints) / 10000;

        if (_resolutionStatus == TaskStatus.Approved) {
            uint256 actualTalentPayment = _amountToTalent;
            if (actualTalentPayment > (totalBounty - fee)) actualTalentPayment = (totalBounty - fee); // Cap payment

            _safeTransferERC20(task.selectedTalent, actualTalentPayment);
            _safeTransferERC20(_feeRecipient, fee);
            // Refund remaining to client if talent payment was less than full bounty - fee
            if (actualTalentPayment < (totalBounty - fee)) {
                _safeTransferERC20(task.client, (totalBounty - fee) - actualTalentPayment);
            }

            // Update talent's Achievement NFT
            TalentProfile storage talentProfile = talentProfiles[task.selectedTalent];
            if (talentProfile.achievementNftId == 0) {
                _mintAchievementNFT(task.selectedTalent);
            }
            _updateAchievementNFTMetadata(task.selectedTalent, talentProfile.achievementNftId);

        } else if (_resolutionStatus == TaskStatus.Cancelled) {
            // Client wins dispute, talent gets nothing, client gets bounty back (minus fee)
            _safeTransferERC20(task.client, totalBounty - fee);
            _safeTransferERC20(_feeRecipient, fee);
        } else {
            revert AptitudeLink__InvalidFee(); // Invalid resolution status
        }

        task.status = _resolutionStatus;
        task.completedAt = block.timestamp;
        emit DisputeResolved(_taskId, _resolutionStatus, task.selectedTalent, _amountToTalent);
    }

    // --- VI. Achievement NFTs (SBTs) & Reputation ---

    // Override _beforeTokenTransfer to make NFTs non-transferable (Soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent transfers once minted, except from address(0) for initial minting
        if (from != address(0) || to == address(0)) {
             revert AptitudeLink__AccessDenied(); // "Achievement NFTs are soulbound and cannot be transferred."
        }
    }

    /**
     * @dev Internal function to mint a new Achievement NFT for a talent.
     * Only called when a talent successfully completes their first task.
     * @param _talentAddress The address of the talent.
     */
    function _mintAchievementNFT(address _talentAddress) internal {
        TalentProfile storage talent = talentProfiles[_talentAddress];
        require(talent.achievementNftId == 0, "NFT already minted");

        uint256 tokenId = super.totalSupply() + 1; // Simple incrementing ID
        _safeMint(_talentAddress, tokenId);
        talent.achievementNftId = tokenId;

        // Initial metadata generation
        _updateAchievementNFTMetadata(_talentAddress, tokenId);

        emit AchievementNFTMinted(_talentAddress, tokenId);
    }

    /**
     * @dev Internal function to dynamically update the metadata of an Achievement NFT.
     * This generates a new IPFS CID for the JSON metadata.
     * @param _talentAddress The address of the talent.
     * @param _tokenId The ID of the Achievement NFT.
     */
    function _updateAchievementNFTMetadata(address _talentAddress, uint256 _tokenId) internal {
        // This is a placeholder for actual IPFS pinning and metadata generation.
        // In a real dApp, this would involve:
        // 1. Fetching talent data (tasks completed, avg rating, verified skills).
        // 2. Constructing a JSON object with this data.
        // 3. Pinning the JSON to IPFS via an off-chain service (e.g., Chainlink, TheGraph + IPFS gateway, centralized API).
        // 4. Updating the tokenURI with the new IPFS CID.

        // For this example, we'll use a simplified on-chain string to represent dynamic URI.
        // A robust solution would involve Chainlink External Adapters for off-chain IPFS pinning.
        TalentProfile storage profile = talentProfiles[_talentAddress];
        uint256 tasksCompleted = 0; // Need to iterate tasks or store this in profile
        for(uint256 i = 1; i < nextTaskId; i++) {
            if(tasks[i].selectedTalent == _talentAddress && tasks[i].status == TaskStatus.Approved) {
                tasksCompleted++;
            }
        }

        string memory jsonUri = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name": "', profile.name, ' - AptitudeLink Achievement #', _tokenId.toString(), '",',
                        '"description": "Official AptitudeLink Achievement NFT representing verified skills and reputation.",',
                        '"image": "ipfs://Qmb8t9jF...",', // Placeholder image CID
                        '"attributes": [',
                            '{"trait_type": "Tasks Completed", "value": "', tasksCompleted.toString(), '"},',
                            '{"trait_type": "Verified Skills", "value": "', profile.claimedSkills.length.toString(), '"},',
                            '{"trait_type": "Overall Rating", "value": "N/A"}' // Placeholder, needs avg rating logic
                        ']}'
                    )
                )
            )
        ));

        _setTokenURI(_tokenId, jsonUri);
        emit AchievementNFTMetadataUpdated(_talentAddress, _tokenId, jsonUri);
    }

    // Helper for base64 encoding (if not using a library or for on-chain demo)
    // Borrowed simplified Base64 encoding for data URI,
    // in production, would use a library or external service for efficiency.
    library Base64 {
        function encode(bytes memory data) internal pure returns (string memory) {
            bytes memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
            bytes memory buffer = new bytes(((data.length * 4) / 3) + 3);
            uint256 ptr = 0;
            for (uint256 i = 0; i < data.length; i += 3) {
                uint256 combined = 0;
                uint256 numBytes = 0;
                for (uint256 j = 0; j < 3; j++) {
                    if (i + j < data.length) {
                        combined = (combined << 8) | data[i + j];
                        numBytes++;
                    } else {
                        combined <<= 8;
                    }
                }
                buffer[ptr++] = table[(combined >> 18) & 0x3F];
                buffer[ptr++] = table[(combined >> 12) & 0x3F];
                buffer[ptr++] = table[(combined >> 6) & 0x3F];
                buffer[ptr++] = table[combined & 0x3F];
            }
            if (numBytes == 1) {
                buffer[ptr - 2] = '=';
                buffer[ptr - 1] = '=';
            } else if (numBytes == 2) {
                buffer[ptr - 1] = '=';
            }
            return string(buffer);
        }
    }


    // --- VII. Governance ---

    /**
     * @dev Allows a user with governance tokens to submit a new proposal.
     * @param _description IPFS CID for detailed proposal document.
     * @param _target The address of the contract the proposal targets (often `this` contract).
     * @param _callData The encoded function call to be executed if the proposal passes.
     * @param _votingPeriodBlocks The number of blocks the voting period will last.
     */
    function submitGovernanceProposal(
        string calldata _description,
        address _target,
        bytes calldata _callData,
        uint256 _votingPeriodBlocks
    ) external whenNotPaused {
        uint256 voteWeight = _governanceToken.balanceOf(msg.sender);
        if (voteWeight == 0) revert AptitudeLink__AccessDenied(); // Only token holders can propose

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            target: _target,
            startBlock: block.number,
            endBlock: block.number + _votingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active
        });
        emit ProposalSubmitted(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows users to vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _voteType The type of vote (For/Against).
     */
    function voteOnProposal(uint256 _proposalId, VoteType _voteType)
        external
        onlyActiveProposal(_proposalId)
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.hasVoted[msg.sender]) revert AptitudeLink__ProposalAlreadyVoted();

        uint256 voteWeight = _governanceToken.balanceOf(msg.sender);
        if (voteWeight == 0) revert AptitudeLink__AccessDenied(); // Must hold governance tokens

        if (_voteType == VoteType.For) {
            proposal.votesFor += voteWeight;
        } else if (_voteType == VoteType.Against) {
            proposal.votesAgainst += voteWeight;
        } else {
            revert AptitudeLink__InvalidFee(); // Invalid vote type
        }

        proposal.hasVoted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _voteType, voteWeight);
    }

    /**
     * @dev Executes a successfully passed proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AptitudeLink__InvalidProposalId();
        if (block.number <= proposal.endBlock) revert AptitudeLink__ProposalNotExpired();
        if (proposal.status != ProposalStatus.Active) revert AptitudeLink__ProposalNotActive();

        if (proposal.votesFor <= proposal.votesAgainst) { // Simple majority for now
            proposal.status = ProposalStatus.Failed;
            revert AptitudeLink__ProposalNotPassed();
        }

        // Execute the call data
        (bool success, ) = proposal.target.call(proposal.callData);
        if (!success) {
            // Log failure, maybe revert, or mark as failed execution
            proposal.status = ProposalStatus.Failed; // Mark as failed execution
            revert AptitudeLink__MetadataGenerationFailed(); // Placeholder for actual execution failure
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves the details and current status of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return id, proposer, description, target, callData, startBlock, endBlock, votesFor, votesAgainst, status.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory description,
            address target,
            bytes memory callData,
            uint256 startBlock,
            uint256 endBlock,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalStatus status
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert AptitudeLink__InvalidProposalId();
        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.startBlock,
            proposal.endBlock,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status
        );
    }

    // --- VIII. Funds Management ---

    /**
     * @dev Allows users to deposit `_paymentToken` into their internal contract balance.
     * This is used for task bounties, verifier stakes, etc.
     * @param _amount The amount of `_paymentToken` to deposit.
     */
    function depositFunds(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert AptitudeLink__InsufficientFunds();
        _paymentToken.transferFrom(msg.sender, address(this), _amount);
        userBalances[msg.sender] += _amount;
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows users to withdraw their available `_paymentToken` balance.
     * @param _amount The amount of `_paymentToken` to withdraw.
     */
    function withdrawFunds(uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert AptitudeLink__NoFundsToWithdraw();
        if (userBalances[msg.sender] < _amount) revert AptitudeLink__InsufficientFunds();

        userBalances[msg.sender] -= _amount;
        _safeTransferERC20(msg.sender, _amount);
        emit FundsWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Returns a user's available `_paymentToken` balance within the contract.
     * @param _user The address of the user.
     * @return The available balance.
     */
    function getAvailableBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }

    /**
     * @dev Safely transfers ERC20 tokens, reverting on failure.
     * @param _to The recipient address.
     * @param _amount The amount to transfer.
     */
    function _safeTransferERC20(address _to, uint256 _amount) internal {
        if (_amount == 0) return; // No need to transfer zero
        bool success = _paymentToken.transfer(_to, _amount);
        require(success, "ERC20 transfer failed");
    }
}
```