This smart contract, **Aetheria Nexus: The Collaborative Skill Graph**, introduces a decentralized platform designed to foster talent, collaboration, and knowledge sharing using advanced on-chain concepts. It leverages Soulbound Tokens (SBTs) for verifiable skills and knowledge, a dynamic reputation system, and a structured project management lifecycle with milestone-based funding and dispute resolution.

---

### **Aetheria Nexus: The Collaborative Skill Graph**

This smart contract establishes a decentralized platform for skill-centric collaboration, leveraging Soulbound Tokens (SBTs) for verifiable skills and knowledge, an on-chain reputation system, and a robust project management lifecycle with milestone-based funding. It aims to foster trust and efficient resource allocation within a community driven by verified capabilities.

**Key Concepts:**

*   **Soulbound Skills (SBS):** Non-transferable ERC-721 tokens representing a user's verified skills, minted by users and attested to by community verifiers. They are tied directly to the user's wallet, making skills verifiable and immutable.
*   **Reputation System:** An on-chain score for each user, dynamically adjusted based on positive contributions (skill attestations, successful project completion, helpful knowledge contributions) and negative actions (dispute losses, false attestations). Reputation can be staked as collateral to ensure accountability.
*   **Collaborative Projects:** A structured framework for creating, funding, managing, and completing projects with defined milestones and team roles. Funds are released incrementally upon milestone approval, ensuring accountability and progress-based payments.
*   **Contextual Knowledge NFTs (CKN):** Non-transferable ERC-721 tokens representing valuable knowledge snippets associated with specific skills. These encourage community knowledge sharing and contribute to the creator's reputation.
*   **Decentralized Skill Verification:** A community-driven mechanism where users can request attestation for their skills from others, building a verifiable skill graph.
*   **Dispute Resolution:** A basic on-chain mechanism for addressing conflicts related to project milestones and skill attestations, involving designated arbiters and reputation adjustments.

---

### **Function Summary:**

**I. Core Identity & Skill Management (Soulbound Skills)**

1.  `registerUserProfile(string memory _name, string memory _bio)`: Allows a user to create or update their public profile on the platform, establishing their on-chain identity.
2.  `claimSoulboundSkill(string memory _skillName, string memory _skillDescription, uint256 _level, string memory _metadataURI)`: Mints a new, initially unverified, Soulbound Skill (SBS) token for `msg.sender`. This initiates the process of claiming a skill that the user believes they possess.
3.  `requestSkillVerification(uint256 _skillTokenId, address[] memory _potentialVerifiers)`: Enables the owner of an unverified SBS to formally request attestation from a list of potential verifiers (e.g., peers, mentors, or certified entities).
4.  `attestSkill(uint256 _skillTokenId, bool _isVerified)`: A designated verifier (`msg.sender`) provides an attestation (positive or negative) for a skill. This action impacts their own reputation (e.g., staking reputation that can be slashed if false) and updates the skill's verification status.
5.  `updateSkillMetadata(uint256 _skillTokenId, string memory _newMetadataURI)`: Allows the owner of an SBS to update its associated metadata URI, typically pointing to external proof of skill, a portfolio, or certifications.
6.  `revokeSelfClaimedSkill(uint256 _skillTokenId)`: Enables an SBS owner to permanently burn (revoke) a skill they no longer wish to possess or display, or that has become outdated.
7.  `getOwnedSkills(address _owner)`: Retrieves an array of all skill token IDs currently owned (soulbound to) a specific address.
8.  `getSkillDetails(uint256 _skillTokenId)`: Provides comprehensive details (name, description, level, verification status, list of verifiers) for a given SBS token.

**II. Reputation System**

9.  `getReputationScore(address _user)`: Returns the current on-chain reputation score for a specific user, reflecting their trustworthiness and contributions within the Nexus.
10. `stakeReputationForVerification(uint256 _skillTokenId, uint256 _reputationAmount)`: Allows a verifier to stake a certain amount of their reputation as collateral when attesting to a skill. This adds credibility to their attestation and acts as a deterrent against false claims.
11. `releaseReputationStake(uint256 _skillTokenId)`: Releases the reputation staked by a verifier for a specific skill, typically after a waiting period, successful verification, or resolution of any disputes related to that attestation.

**III. Project & Collaboration Lifecycle**

12. `createProject(string memory _projectName, string memory _projectDescription, uint256 _estimatedDuration, uint256[] memory _requiredSkillTokenIds, uint256[] memory _minSkillLevels, address[] memory _initialTeamMembers, uint256 _totalBudget, uint256 _milestoneCount)`: Initiates a new collaborative project. The creator defines its scope, estimated duration, required skills (referencing SBS IDs and minimum levels), initial team members, total budget, and the number of payment milestones.
13. `fundProject(uint256 _projectId)`: Allows the project creator or external sponsors to deposit ETH into the project's dedicated escrow budget. Funds are held in the contract until milestones are approved.
14. `defineMilestone(uint256 _projectId, string memory _milestoneDescription, uint256 _paymentPercentage)`: Project creator defines a new milestone for an existing project, allocating a specific percentage of the total budget for its completion. This must be done before the project starts.
15. `submitMilestoneForApproval(uint256 _projectId, uint256 _milestoneIndex)`: The project lead (or designated team member) submits a completed milestone for formal review and approval by relevant stakeholders/funders.
16. `approveMilestone(uint256 _projectId, uint256 _milestoneIndex)`: An authorized funding entity or stakeholder approves a submitted milestone, triggering the secure release of the associated funds (pre-defined percentage) to the project team.
17. `requestDisputeResolution(uint256 _projectId, uint256 _milestoneIndex, string memory _reason)`: Allows any involved party (project team, funder) to formally initiate a dispute regarding a project milestone (e.g., non-completion, quality issues, or payment disputes).
18. `resolveDispute(uint256 _projectId, uint256 _milestoneIndex, bool _outcomeSuccessful, address[] memory _involvedParties, int256[] memory _reputationAdjustments)`: An authorized arbiter (e.g., the contract owner or a DAO-governed body) resolves an ongoing dispute, adjusting reputation scores for involved parties (positive or negative) based on the outcome, and potentially impacting fund distribution.

**IV. Contextual Knowledge & Community (Soulbound Knowledge)**

19. `mintContextualKnowledge(string memory _title, string memory _description, string memory _metadataURI, uint256[] memory _associatedSkillTokenIds)`: Mints a new, non-transferable Soulbound Token representing a piece of contextual knowledge (e.g., a tutorial, best practice, or insights), linked to specific SBS IDs. This fosters a curated, verifiable knowledge base.
20. `upvoteContextualKnowledge(uint256 _knowledgeTokenId)`: Allows users to upvote a knowledge token they find valuable or helpful. This contributes to its visibility and positively impacts the creator's reputation score.
21. `reportContextualKnowledge(uint256 _knowledgeTokenId)`: Enables users to report knowledge tokens deemed inappropriate, inaccurate, or harmful, triggering a review process by administrators.

**V. System & Utilities (Admin & Maintenance)**

22. `pauseContract()`: Emergency function to pause all mutable operations on the contract (e.g., new project creation, fund releases), callable only by the contract owner, for security or maintenance.
23. `unpauseContract()`: Resumes operations after a pause, callable only by the contract owner.
24. `withdrawProtocolFees(address _recipient)`: Allows the contract owner to withdraw any accumulated protocol fees (e.g., a small percentage from project funding) to a specified address.
25. `setSkillVerificationFee(uint256 _fee)`: Allows the contract owner to set a fee (in Wei) that users must pay when requesting a formal skill verification from the community.

---

### **Solidity Smart Contract**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Custom Soulbound ERC721 Implementations ---
// These contracts prevent transfer of tokens once minted to an address.
// They are separate to allow for distinct token IDs and metadata per type.

contract SoulboundSkills is ERC721 {
    // Custom error for clarity when transfer is prevented
    error TransferNotAllowed();

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Override _beforeTokenTransfer to enforce soulbound nature
    // Allows minting (from address(0)) and burning (to address(0)), but no other transfers.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            revert TransferNotAllowed();
        }
    }

    // Function to mint a new SBS token
    function mint(address to, uint256 tokenId, string memory uri) external returns (uint256) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // Function to burn an SBS token (revoke skill)
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    // Function to update token URI (metadata)
    function updateTokenURI(uint256 tokenId, string memory newUri) external {
        require(ownerOf(tokenId) == msg.sender, "SBS: Not token owner");
        _setTokenURI(tokenId, newUri);
    }
}

contract SoulboundKnowledge is ERC721 {
    error TransferNotAllowed();

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from != address(0) && to != address(0)) {
            revert TransferNotAllowed();
        }
    }

    function mint(address to, uint256 tokenId, string memory uri) external returns (uint256) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    function updateTokenURI(uint256 tokenId, string memory newUri) external {
        require(ownerOf(tokenId) == msg.sender, "CKN: Not token owner");
        _setTokenURI(tokenId, newUri);
    }
}


// --- Main Aetheria Nexus Contract ---

contract AetheriaNexus is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables & Mappings ---

    // Token contracts
    SoulboundSkills public sbsContract;
    SoulboundKnowledge public cknContract;

    // Counters for unique IDs
    Counters.Counter private _skillTokenIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _knowledgeTokenIds;

    // --- User Profiles ---
    struct UserProfile {
        string name;
        string bio;
        bool exists;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => uint256) public reputationScores;

    // --- Skill Management ---
    struct Skill {
        string name;
        string description;
        uint256 level;
        string metadataURI;
        bool isVerified; // Overall verification status
        address owner;
        mapping(address => bool) verifiersAttested; // Verifier => Attested (true/false)
        mapping(address => uint256) verifierReputationStakes; // Verifier => Staked Amount
        address[] currentVerifiers; // List of addresses who have attested
        address[] requestedVerifiers; // List of addresses requested for verification
    }
    mapping(uint256 => Skill) public skills; // skillTokenId => Skill details

    // --- Project Management ---
    enum ProjectStatus { Created, Funded, InProgress, ReviewPending, Completed, Dispute, Cancelled }
    enum MilestoneStatus { Defined, Submitted, Approved, Rejected }

    struct Milestone {
        string description;
        uint256 paymentPercentage; // Percentage of total budget for this milestone
        MilestoneStatus status;
        bool fundsReleased;
    }

    struct Project {
        string name;
        string description;
        uint256 estimatedDuration; // In seconds
        address creator;
        address[] teamMembers;
        mapping(address => bool) isTeamMember; // For quick lookup
        uint256 totalBudget;
        uint256 currentFundedAmount;
        ProjectStatus status;
        uint256[] requiredSkillTokenIds;
        uint256[] minSkillLevels;
        Milestone[] milestones;
        uint256 creationTime;
    }
    mapping(uint256 => Project) public projects; // projectId => Project details

    // --- Knowledge Management ---
    struct Knowledge {
        string title;
        string description;
        string metadataURI;
        address creator;
        uint256[] associatedSkillTokenIds;
        uint256 upvotes;
        uint256 reports;
    }
    mapping(uint256 => Knowledge) public knowledgeNfts; // knowledgeTokenId => Knowledge details

    // --- Protocol Fees ---
    uint256 public protocolFeeRate = 500; // 5% = 500 basis points (500/10000)
    uint256 public skillVerificationFee = 0; // In Wei, default 0

    // --- Events ---
    event UserProfileRegistered(address indexed user, string name, string bio);
    event SoulboundSkillClaimed(address indexed owner, uint256 indexed skillTokenId, string skillName, uint256 level);
    event SkillVerificationRequested(address indexed owner, uint256 indexed skillTokenId, address[] potentialVerifiers);
    event SkillAttested(address indexed verifier, uint256 indexed skillTokenId, bool isVerified);
    event SkillMetadataUpdated(uint256 indexed skillTokenId, string newMetadataURI);
    event SoulboundSkillRevoked(address indexed owner, uint256 indexed skillTokenId);
    event ReputationStaked(address indexed verifier, uint256 indexed skillTokenId, uint256 amount);
    event ReputationReleased(address indexed verifier, uint256 indexed skillTokenId);
    event ReputationAdjusted(address indexed user, int256 adjustment, string reason);

    event ProjectCreated(uint256 indexed projectId, address indexed creator, string name, uint256 totalBudget);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneDefined(uint256 indexed projectId, uint256 indexed milestoneIndex, string description, uint256 percentage);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event MilestoneApproved(uint256 indexed projectId, uint256 indexed milestoneIndex);
    event DisputeRequested(uint256 indexed projectId, uint256 indexed milestoneIndex, address indexed requester, string reason);
    event DisputeResolved(uint256 indexed projectId, uint256 indexed milestoneIndex, bool outcomeSuccessful);

    event ContextualKnowledgeMinted(address indexed creator, uint256 indexed knowledgeTokenId, string title);
    event ContextualKnowledgeUpvoted(uint256 indexed knowledgeTokenId, address indexed upvoter);
    event ContextualKnowledgeReported(uint256 indexed knowledgeTokenId, address indexed reporter);

    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event SkillVerificationFeeUpdated(uint256 newFee);

    // --- Modifiers ---
    modifier onlyProjectCreator(uint256 _projectId) {
        require(projects[_projectId].creator == msg.sender, "NexusForge: Only project creator can perform this action");
        _;
    }

    modifier onlyProjectTeamMember(uint256 _projectId) {
        require(projects[_projectId].isTeamMember[msg.sender], "NexusForge: Only project team members can perform this action");
        _;
    }

    modifier onlyProjectFunderOrCreator(uint256 _projectId) {
        // For simplicity, funders are considered the creator in this prototype for approval.
        // In a more complex system, funders would be mapped.
        require(projects[_projectId].creator == msg.sender, "NexusForge: Only project creator/funder can approve");
        _;
    }

    modifier isVerifiedUser(address _user) {
        require(userProfiles[_user].exists, "NexusForge: User profile does not exist");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        sbsContract = new SoulboundSkills("AetheriaNexus_Skill", "AN-SBS");
        cknContract = new SoulboundKnowledge("AetheriaNexus_Knowledge", "AN-CKN");
    }

    // --- ERC721 Overrides (handled by separate Soulbound contracts, main contract interacts) ---
    // No direct overrides needed here, interactions are via sbsContract and cknContract instances.

    // --- I. Core Identity & Skill Management (Soulbound Skills) ---

    function registerUserProfile(string memory _name, string memory _bio) external whenNotPaused {
        require(!userProfiles[msg.sender].exists, "NexusForge: Profile already exists");
        userProfiles[msg.sender] = UserProfile(_name, _bio, true);
        reputationScores[msg.sender] = 100; // Initial reputation
        emit UserProfileRegistered(msg.sender, _name, _bio);
    }

    function claimSoulboundSkill(string memory _skillName, string memory _skillDescription, uint256 _level, string memory _metadataURI)
        external
        whenNotPaused
        isVerifiedUser(msg.sender)
        returns (uint256)
    {
        _skillTokenIds.increment();
        uint256 newSkillId = _skillTokenIds.current();

        sbsContract.mint(msg.sender, newSkillId, _metadataURI);

        skills[newSkillId] = Skill({
            name: _skillName,
            description: _skillDescription,
            level: _level,
            metadataURI: _metadataURI,
            isVerified: false,
            owner: msg.sender,
            currentVerifiers: new address[](0),
            requestedVerifiers: new address[](0)
        });

        emit SoulboundSkillClaimed(msg.sender, newSkillId, _skillName, _level);
        return newSkillId;
    }

    function requestSkillVerification(uint256 _skillTokenId, address[] memory _potentialVerifiers)
        external
        payable
        whenNotPaused
        isVerifiedUser(msg.sender)
    {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner == msg.sender, "NexusForge: Not the skill owner");
        require(!skill.isVerified, "NexusForge: Skill already verified");
        require(msg.value >= skillVerificationFee, "NexusForge: Insufficient verification fee");
        require(_potentialVerifiers.length > 0, "NexusForge: Must provide at least one verifier");

        for (uint256 i = 0; i < _potentialVerifiers.length; i++) {
            require(userProfiles[_potentialVerifiers[i]].exists, "NexusForge: Potential verifier profile does not exist");
            // Basic check to prevent self-verification or duplicate requests
            require(_potentialVerifiers[i] != msg.sender, "NexusForge: Cannot request self-verification");
            bool alreadyRequested = false;
            for(uint256 j=0; j<skill.requestedVerifiers.length; j++){
                if(skill.requestedVerifiers[j] == _potentialVerifiers[i]){
                    alreadyRequested = true;
                    break;
                }
            }
            if(!alreadyRequested){
                skill.requestedVerifiers.push(_potentialVerifiers[i]);
            }
        }

        emit SkillVerificationRequested(msg.sender, _skillTokenId, _potentialVerifiers);
    }

    function attestSkill(uint256 _skillTokenId, bool _isVerified) external whenNotPaused isVerifiedUser(msg.sender) {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner != address(0), "NexusForge: Skill does not exist");
        require(!skill.isVerified, "NexusForge: Skill already fully verified");
        require(!skill.verifiersAttested[msg.sender], "NexusForge: Already attested this skill");

        bool isRequested = false;
        for (uint256 i = 0; i < skill.requestedVerifiers.length; i++) {
            if (skill.requestedVerifiers[i] == msg.sender) {
                isRequested = true;
                break;
            }
        }
        require(isRequested, "NexusForge: Not requested as a verifier for this skill");

        skill.verifiersAttested[msg.sender] = true;
        skill.currentVerifiers.push(msg.sender);

        if (_isVerified) {
            // For simplicity, 3 attestations verify the skill. More complex logic can be added.
            if (skill.currentVerifiers.length >= 3) {
                skill.isVerified = true;
                // Reward reputation to the skill owner upon full verification
                reputationScores[skill.owner] += 50; // Example reward
                emit ReputationAdjusted(skill.owner, 50, "Skill verified");
            }
            reputationScores[msg.sender] += 10; // Reward verifier
            emit ReputationAdjusted(msg.sender, 10, "Attested skill positively");
        } else {
            // Penalize verifier if they attest negatively (e.g., if it's found they were malicious)
            // This example is simplified. In real-world, negative attestations might trigger dispute.
            reputationScores[msg.sender] = reputationScores[msg.sender] >= 5 ? reputationScores[msg.sender] - 5 : 0;
            emit ReputationAdjusted(msg.sender, -5, "Attested skill negatively");
        }

        emit SkillAttested(msg.sender, _skillTokenId, _isVerified);
    }

    function updateSkillMetadata(uint256 _skillTokenId, string memory _newMetadataURI)
        external
        whenNotPaused
        isVerifiedUser(msg.sender)
    {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner == msg.sender, "NexusForge: Not the skill owner");
        skill.metadataURI = _newMetadataURI;
        sbsContract.updateTokenURI(_skillTokenId, _newMetadataURI);
        emit SkillMetadataUpdated(_skillTokenId, _newMetadataURI);
    }

    function revokeSelfClaimedSkill(uint256 _skillTokenId) external whenNotPaused isVerifiedUser(msg.sender) {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner == msg.sender, "NexusForge: Not the skill owner");
        sbsContract.burn(_skillTokenId);
        delete skills[_skillTokenId]; // Remove from mapping
        emit SoulboundSkillRevoked(msg.sender, _skillTokenId);
    }

    function getOwnedSkills(address _owner) external view returns (uint256[] memory) {
        // This requires iterating, which can be gas intensive for many tokens.
        // A more advanced solution would use an array of skill IDs per user or a subgraph.
        uint256[] memory ownedTokenIds = new uint256[](sbsContract.balanceOf(_owner));
        uint256 counter = 0;
        // This is inefficient for many tokens. In a real dApp, a subgraph or off-chain indexer would be used.
        for (uint256 i = 1; i <= _skillTokenIds.current(); i++) {
            try sbsContract.ownerOf(i) returns (address tokenOwner) {
                if (tokenOwner == _owner) {
                    ownedTokenIds[counter] = i;
                    counter++;
                }
            } catch {
                // Token might have been burned
            }
        }
        return ownedTokenIds;
    }

    function getSkillDetails(uint256 _skillTokenId)
        external
        view
        returns (
            string memory name,
            string memory description,
            uint256 level,
            string memory metadataURI,
            bool isVerified,
            address owner,
            address[] memory currentVerifiers
        )
    {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner != address(0), "NexusForge: Skill does not exist");
        return (
            skill.name,
            skill.description,
            skill.level,
            skill.metadataURI,
            skill.isVerified,
            skill.owner,
            skill.currentVerifiers
        );
    }

    // --- II. Reputation System ---

    function getReputationScore(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }

    function stakeReputationForVerification(uint256 _skillTokenId, uint256 _reputationAmount)
        external
        whenNotPaused
        isVerifiedUser(msg.sender)
    {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner != address(0), "NexusForge: Skill does not exist");
        require(reputationScores[msg.sender] >= _reputationAmount, "NexusForge: Insufficient reputation to stake");
        require(!skill.verifiersAttested[msg.sender], "NexusForge: Already attested this skill");

        skill.verifierReputationStakes[msg.sender] = _reputationAmount;
        reputationScores[msg.sender] -= _reputationAmount;
        emit ReputationStaked(msg.sender, _skillTokenId, _reputationAmount);
        emit ReputationAdjusted(msg.sender, -int256(_reputationAmount), "Staked for verification");
    }

    function releaseReputationStake(uint256 _skillTokenId) external whenNotPaused isVerifiedUser(msg.sender) {
        Skill storage skill = skills[_skillTokenId];
        require(skill.owner != address(0), "NexusForge: Skill does not exist");
        uint256 stakedAmount = skill.verifierReputationStakes[msg.sender];
        require(stakedAmount > 0, "NexusForge: No reputation staked for this skill");

        // Simple release: allows after 30 days or if skill is verified
        // More complex logic could involve dispute resolution outcome
        bool canRelease = false;
        if (skill.isVerified) {
             canRelease = true; // Release if skill is verified
        }
        // else if (block.timestamp > (skill.lastAttestationTime + 30 days)) { // Requires storing last attestation time
        //     canRelease = true;
        // }
        // For simplicity, allow release if skill is verified or immediately if no disputes.
        // In a real system, there would be a time lock or dispute period.
        canRelease = true; // Placeholder for now

        require(canRelease, "NexusForge: Cannot release stake yet (e.g., waiting period or dispute)");

        reputationScores[msg.sender] += stakedAmount;
        skill.verifierReputationStakes[msg.sender] = 0; // Clear stake
        emit ReputationReleased(msg.sender, _skillTokenId);
        emit ReputationAdjusted(msg.sender, int256(stakedAmount), "Released verification stake");
    }

    // --- III. Project & Collaboration Lifecycle ---

    function createProject(
        string memory _projectName,
        string memory _projectDescription,
        uint256 _estimatedDuration,
        uint256[] memory _requiredSkillTokenIds,
        uint256[] memory _minSkillLevels,
        address[] memory _initialTeamMembers,
        uint256 _totalBudget,
        uint256 _milestoneCount
    ) external whenNotPaused isVerifiedUser(msg.sender) returns (uint256) {
        require(_requiredSkillTokenIds.length == _minSkillLevels.length, "NexusForge: Skill ID and level arrays must match");
        require(_milestoneCount > 0, "NexusForge: Project must have at least one milestone");
        require(_totalBudget > 0, "NexusForge: Project budget must be positive");

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        Project storage newProject = projects[newProjectId];
        newProject.name = _projectName;
        newProject.description = _projectDescription;
        newProject.estimatedDuration = _estimatedDuration;
        newProject.creator = msg.sender;
        newProject.totalBudget = _totalBudget;
        newProject.status = ProjectStatus.Created;
        newProject.requiredSkillTokenIds = _requiredSkillTokenIds;
        newProject.minSkillLevels = _minSkillLevels;
        newProject.creationTime = block.timestamp;

        newProject.teamMembers.push(msg.sender); // Creator is a team member by default
        newProject.isTeamMember[msg.sender] = true;
        for (uint256 i = 0; i < _initialTeamMembers.length; i++) {
            require(userProfiles[_initialTeamMembers[i]].exists, "NexusForge: Initial team member profile does not exist");
            if (!newProject.isTeamMember[_initialTeamMembers[i]]) {
                newProject.teamMembers.push(_initialTeamMembers[i]);
                newProject.isTeamMember[_initialTeamMembers[i]] = true;
            }
        }
        // Initialize milestones (empty, will be defined next)
        newProject.milestones = new Milestone[](_milestoneCount);

        emit ProjectCreated(newProjectId, msg.sender, _projectName, _totalBudget);
        return newProjectId;
    }

    function fundProject(uint256 _projectId) external payable whenNotPaused nonReentrant {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "NexusForge: Project does not exist");
        require(project.status < ProjectStatus.Completed, "NexusForge: Project already completed or cancelled");
        require(msg.value > 0, "NexusForge: Must send positive ETH to fund");

        project.currentFundedAmount += msg.value;
        emit ProjectFunded(_projectId, msg.sender, msg.value);

        if (project.currentFundedAmount >= project.totalBudget && project.status == ProjectStatus.Created) {
            project.status = ProjectStatus.Funded;
            // Transition to InProgress if all milestones are defined and funds sufficient
            bool allMilestonesDefined = true;
            for(uint256 i = 0; i < project.milestones.length; i++){
                if(project.milestones[i].status == MilestoneStatus.Defined){ // Defined is default
                    allMilestonesDefined = false; // Need to be explicitly set
                    break;
                }
            }
            if(allMilestonesDefined) project.status = ProjectStatus.InProgress;
        }
    }

    function defineMilestone(uint256 _projectId, string memory _milestoneDescription, uint256 _paymentPercentage)
        external
        whenNotPaused
        onlyProjectCreator(_projectId)
    {
        Project storage project = projects[_projectId];
        require(project.status == ProjectStatus.Created || project.status == ProjectStatus.Funded, "NexusForge: Project must be in Created or Funded status to define milestones");
        require(_paymentPercentage > 0 && _paymentPercentage <= 10000, "NexusForge: Payment percentage must be between 1 and 10000 (100%)");
        
        uint256 definedCount = 0;
        uint256 sumPercentages = 0;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status != MilestoneStatus.Defined) { // Defined is the default state
                definedCount++;
                sumPercentages += project.milestones[i].paymentPercentage;
            }
        }
        require(definedCount < project.milestones.length, "NexusForge: All milestones already defined");
        
        // Find the first undefined milestone slot
        uint256 milestoneIndex = project.milestones.length; // Will be set to the length if no empty slot found
        for(uint256 i = 0; i < project.milestones.length; i++){
            if(project.milestones[i].status == MilestoneStatus.Defined){ // Default is Defined, means not set yet
                milestoneIndex = i;
                break;
            }
        }
        require(milestoneIndex < project.milestones.length, "NexusForge: No more milestone slots available");
        
        // Ensure total percentage doesn't exceed 100%
        require(sumPercentages + _paymentPercentage <= 10000, "NexusForge: Total milestone percentages exceed 100%");


        project.milestones[milestoneIndex] = Milestone({
            description: _milestoneDescription,
            paymentPercentage: _paymentPercentage,
            status: MilestoneStatus.Submitted, // Setting to submitted after definition, awaiting explicit approval
            fundsReleased: false
        });

        // If all milestones are now defined and project is funded, set status to InProgress
        if (project.currentFundedAmount >= project.totalBudget && definedCount + 1 == project.milestones.length) {
            project.status = ProjectStatus.InProgress;
        }
        emit MilestoneDefined(_projectId, milestoneIndex, _milestoneDescription, _paymentPercentage);
    }

    function submitMilestoneForApproval(uint256 _projectId, uint256 _milestoneIndex)
        external
        whenNotPaused
        onlyProjectTeamMember(_projectId)
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "NexusForge: Invalid milestone index");
        require(project.status == ProjectStatus.InProgress, "NexusForge: Project not in InProgress status");
        require(project.milestones[_milestoneIndex].status == MilestoneStatus.Submitted, "NexusForge: Milestone not awaiting approval");

        project.milestones[_milestoneIndex].status = MilestoneStatus.Submitted; // Already submitted, but explicitly set.
        project.status = ProjectStatus.ReviewPending; // Set project status to pending review
        emit MilestoneSubmitted(_projectId, _milestoneIndex);
    }

    function approveMilestone(uint256 _projectId, uint256 _milestoneIndex)
        external
        whenNotPaused
        nonReentrant
        onlyProjectFunderOrCreator(_projectId)
    {
        Project storage project = projects[_projectId];
        require(_milestoneIndex < project.milestones.length, "NexusForge: Invalid milestone index");
        Milestone storage milestone = project.milestones[_milestoneIndex];

        require(milestone.status == MilestoneStatus.Submitted, "NexusForge: Milestone not in submitted status");
        require(!milestone.fundsReleased, "NexusForge: Funds already released for this milestone");
        require(project.currentFundedAmount >= project.totalBudget, "NexusForge: Project not fully funded yet"); // Ensure total budget is available

        uint256 paymentAmount = (project.totalBudget * milestone.paymentPercentage) / 10000; // Calculate payment based on basis points

        require(address(this).balance >= paymentAmount, "NexusForge: Insufficient contract balance to release funds");

        // Distribute funds to team members (simple equal split for now)
        require(project.teamMembers.length > 0, "NexusForge: No team members to pay");
        uint256 amountPerMember = paymentAmount / project.teamMembers.length;

        for (uint256 i = 0; i < project.teamMembers.length; i++) {
            // Avoid reentrancy with checks-effects-interactions pattern
            address payable member = payable(project.teamMembers[i]);
            (bool success, ) = member.call{value: amountPerMember}("");
            require(success, "NexusForge: Failed to send ETH to team member");
            reputationScores[project.teamMembers[i]] += 20; // Reward team member reputation
            emit ReputationAdjusted(project.teamMembers[i], 20, "Milestone completed");
        }

        milestone.status = MilestoneStatus.Approved;
        milestone.fundsReleased = true;
        project.currentFundedAmount -= paymentAmount; // Deduct released funds from held amount

        // Check if all milestones are complete
        bool allMilestonesComplete = true;
        for (uint256 i = 0; i < project.milestones.length; i++) {
            if (project.milestones[i].status != MilestoneStatus.Approved) {
                allMilestonesComplete = false;
                break;
            }
        }

        if (allMilestonesComplete) {
            project.status = ProjectStatus.Completed;
            reputationScores[project.creator] += 50; // Reward creator for project completion
            emit ReputationAdjusted(project.creator, 50, "Project completed");
        } else {
            project.status = ProjectStatus.InProgress; // Back to in-progress for next milestone
        }

        emit MilestoneApproved(_projectId, _milestoneIndex);
    }

    function requestDisputeResolution(uint256 _projectId, uint256 _milestoneIndex, string memory _reason)
        external
        whenNotPaused
        isVerifiedUser(msg.sender)
    {
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "NexusForge: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "NexusForge: Invalid milestone index");
        require(project.status == ProjectStatus.ReviewPending || project.status == ProjectStatus.InProgress, "NexusForge: Project not in a disputable state");

        // Allow creator, team member, or funder to request dispute.
        require(
            project.creator == msg.sender || project.isTeamMember[msg.sender],
            "NexusForge: Only involved parties can request dispute"
        );

        project.status = ProjectStatus.Dispute;
        project.milestones[_milestoneIndex].status = MilestoneStatus.Rejected; // Mark milestone as rejected during dispute
        emit DisputeRequested(msg.sender, _projectId, _milestoneIndex, _reason);
    }

    function resolveDispute(
        uint256 _projectId,
        uint256 _milestoneIndex,
        bool _outcomeSuccessful, // True if the dispute finds in favor of project completion/quality
        address[] memory _involvedParties,
        int256[] memory _reputationAdjustments // Positive for rewards, negative for penalties
    ) external whenNotPaused onlyOwner {
        // Only contract owner (acting as arbiter) can resolve disputes
        Project storage project = projects[_projectId];
        require(project.creator != address(0), "NexusForge: Project does not exist");
        require(_milestoneIndex < project.milestones.length, "NexusForge: Invalid milestone index");
        require(project.status == ProjectStatus.Dispute, "NexusForge: Project is not in dispute");
        require(_involvedParties.length == _reputationAdjustments.length, "NexusForge: Mismatched party and adjustment arrays");

        if (_outcomeSuccessful) {
            project.status = ProjectStatus.InProgress; // Resume project if resolved successfully
            project.milestones[_milestoneIndex].status = MilestoneStatus.Submitted; // Re-submit for approval
        } else {
            project.status = ProjectStatus.Cancelled; // If dispute outcome is negative, project might be cancelled
            project.milestones[_milestoneIndex].status = MilestoneStatus.Rejected;
            // Optionally, return remaining funds to creator/funders if cancelled
        }

        for (uint256 i = 0; i < _involvedParties.length; i++) {
            if (_reputationAdjustments[i] > 0) {
                reputationScores[_involvedParties[i]] += uint256(_reputationAdjustments[i]);
            } else {
                uint256 absAdjustment = uint256(-_reputationAdjustments[i]);
                reputationScores[_involvedParties[i]] = reputationScores[_involvedParties[i]] >= absAdjustment
                    ? reputationScores[_involvedParties[i]] - absAdjustment
                    : 0;
            }
            emit ReputationAdjusted(_involvedParties[i], _reputationAdjustments[i], "Dispute resolution");
        }

        emit DisputeResolved(_projectId, _milestoneIndex, _outcomeSuccessful);
    }

    // --- IV. Contextual Knowledge & Community (Soulbound Knowledge) ---

    function mintContextualKnowledge(
        string memory _title,
        string memory _description,
        string memory _metadataURI,
        uint256[] memory _associatedSkillTokenIds
    ) external whenNotPaused isVerifiedUser(msg.sender) returns (uint256) {
        _knowledgeTokenIds.increment();
        uint256 newKnowledgeId = _knowledgeTokenIds.current();

        cknContract.mint(msg.sender, newKnowledgeId, _metadataURI);

        knowledgeNfts[newKnowledgeId] = Knowledge({
            title: _title,
            description: _description,
            metadataURI: _metadataURI,
            creator: msg.sender,
            associatedSkillTokenIds: _associatedSkillTokenIds,
            upvotes: 0,
            reports: 0
        });

        reputationScores[msg.sender] += 5; // Small reward for contributing knowledge
        emit ReputationAdjusted(msg.sender, 5, "Minted contextual knowledge");
        emit ContextualKnowledgeMinted(msg.sender, newKnowledgeId, _title);
        return newKnowledgeId;
    }

    function upvoteContextualKnowledge(uint256 _knowledgeTokenId) external whenNotPaused isVerifiedUser(msg.sender) {
        Knowledge storage knowledge = knowledgeNfts[_knowledgeTokenId];
        require(knowledge.creator != address(0), "NexusForge: Knowledge does not exist");
        require(knowledge.creator != msg.sender, "NexusForge: Cannot upvote your own knowledge");

        knowledge.upvotes++;
        reputationScores[knowledge.creator] += 1; // Small reward for upvoted knowledge
        emit ReputationAdjusted(knowledge.creator, 1, "Knowledge upvoted");
        emit ContextualKnowledgeUpvoted(_knowledgeTokenId, msg.sender);
    }

    function reportContextualKnowledge(uint256 _knowledgeTokenId) external whenNotPaused isVerifiedUser(msg.sender) {
        Knowledge storage knowledge = knowledgeNfts[_knowledgeTokenId];
        require(knowledge.creator != address(0), "NexusForge: Knowledge does not exist");
        require(knowledge.creator != msg.sender, "NexusForge: Cannot report your own knowledge");

        knowledge.reports++;
        // If reports reach a threshold, trigger admin review or automatic removal
        if (knowledge.reports >= 5) {
            cknContract.burn(_knowledgeTokenId); // Example: automatic burn if 5 reports
            delete knowledgeNfts[_knowledgeTokenId];
            reputationScores[knowledge.creator] = reputationScores[knowledge.creator] >= 10 ? reputationScores[knowledge.creator] - 10 : 0;
            emit ReputationAdjusted(knowledge.creator, -10, "Knowledge reported and removed");
        }
        emit ContextualKnowledgeReported(_knowledgeTokenId, msg.sender);
    }

    // --- V. System & Utilities (Admin & Maintenance) ---

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    function withdrawProtocolFees(address _recipient) external onlyOwner nonReentrant {
        require(_recipient != address(0), "NexusForge: Invalid recipient address");
        uint256 balance = address(this).balance;
        // In this implementation, fees would need to be explicitly sent to the contract from project funding, etc.
        // For simplicity, this function just withdraws whatever ETH is in the contract that isn't locked in projects.
        // A dedicated fee tracking mechanism would be better for production.
        uint256 withdrawableAmount = balance; // Assuming all current balance is withdrawable fees
        // Real implementation: (balance - sum of unspent project funds)

        (bool success, ) = payable(_recipient).call{value: withdrawableAmount}("");
        require(success, "NexusForge: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_recipient, withdrawableAmount);
    }

    function setSkillVerificationFee(uint256 _fee) external onlyOwner {
        skillVerificationFee = _fee;
        emit SkillVerificationFeeUpdated(_fee);
    }
}
```