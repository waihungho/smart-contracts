Okay, let's design a smart contract that goes beyond simple token transfers or basic interactions. We'll create a "Decentralized Talent Scout and Service Escrow" contract.

This contract allows users to register as Talents (offering skills) or Projects (seeking skills), and introduces a third role, Scouts, who earn rewards for successfully matching Talents with Projects. It incorporates skill claims, a basic reputation system, proposals, and an escrow mechanism for service payments with milestones.

It combines elements of marketplace, reputation, and escrow, with a unique scouting incentive layer.

---

**Outline:**

1.  **Contract Setup:** SPDX License, Pragma, Imports (e.g., ReentrancyGuard).
2.  **State Variables:**
    *   Counters for unique IDs (Talent, Project, Scout, Proposal, Service Contract).
    *   Mappings to store entities (Talents, Projects, Scouts, Proposals, Service Contracts).
    *   Mappings to look up entity IDs by address.
    *   Mapping for known/approved skills (hash to name, array of hashes).
    *   Owner/Dispute Resolver addresses.
3.  **Structs:**
    *   `Talent`: Details, skills claimed/endorsed, reputation.
    *   `Project`: Details, required skills, associated proposals.
    *   `Scout`: Details, reward tracking.
    *   `Proposal`: Scout-Talent-Project link, status.
    *   `ServiceContract`: Proposal link, payment escrow, milestones, status, dispute info.
4.  **Events:** For registrations, proposals, contract creation, milestones, payments, disputes.
5.  **Modifiers:** Access control (e.g., `onlyRegisteredTalent`, `onlyProjectOwner`, `onlyScout`, `onlyDisputeResolver`).
6.  **Core Functions (Grouped):**
    *   **Admin/Setup:** Add known skills, set dispute resolver.
    *   **Registration:** Register as Talent, Project, or Scout.
    *   **Skill Management:** Claim skills, Endorse skills (reputation weighted).
    *   **Project Management:** Create project, Add required skills, Get project details.
    *   **Scouting & Proposals:** Submit proposal, Accept/Reject proposal (by Project/Talent).
    *   **Service Contracts (Escrow):** Create contract (deposit funds), Mark/Approve milestones, Mark contract completion (Talent/Project).
    *   **Payment & Rewards:** Release full payment (to Talent), Claim Scout reward, Withdraw escrowed funds (e.g., on dispute/cancellation).
    *   **Dispute Resolution:** Raise dispute, Resolve dispute (by dispute resolver).
    *   **Getters:** Retrieve details for any entity by ID, get entity ID by address, get skill info.

---

**Function Summary (Approx. 30 functions):**

1.  `constructor()`: Initializes owner and potentially dispute resolver.
2.  `addKnownSkill(string skillName)`: Admin function to add a skill to a predefined list.
3.  `setDisputeResolver(address _disputeResolver)`: Admin function to set the dispute resolution address.
4.  `registerTalent(string name, string bio)`: Allows a user to register as a talent.
5.  `registerProject(string title, string description, uint256 requiredReputation)`: Allows a user to register a project.
6.  `registerScout(string name)`: Allows a user to register as a scout.
7.  `claimSkill(string skillName, uint256 claimedLevel)`: Talent claims a specific skill and level.
8.  `endorseSkill(uint256 talentId, string skillName, uint256 endorsementStrength)`: Allows a registered user to endorse a talent's skill, weighted by endorser's reputation.
9.  `addRequiredSkillToProject(uint256 projectId, string skillName, uint256 requiredLevel)`: Project owner specifies a required skill and level for a project.
10. `submitProposal(uint256 projectId, uint256 talentId, string scoutMotivation)`: Scout proposes a talent for a project.
11. `projectAcceptProposal(uint256 proposalId)`: Project owner accepts a proposal.
12. `talentAcceptProposal(uint256 proposalId)`: Talent accepts a proposal.
13. `createServiceContract(uint256 proposalId, uint256 milestoneCount) payable`: Creates a service contract from a mutually accepted proposal and receives the agreed payment into escrow.
14. `markMilestoneCompleted(uint256 serviceContractId, uint256 milestoneIndex)`: Talent marks a specific milestone as completed.
15. `approveMilestoneCompletion(uint256 serviceContractId, uint256 milestoneIndex)`: Project owner approves a completed milestone.
16. `talentMarkContractCompleted(uint256 serviceContractId)`: Talent marks the entire service contract as completed.
17. `projectApproveFullContract(uint256 serviceContractId)`: Project owner approves the full service contract completion.
18. `releaseFullPayment(uint256 serviceContractId)`: Releases the full escrowed payment to the talent after full project approval.
19. `raiseDispute(uint256 serviceContractId, string reason)`: Allows either party (Talent/Project) to raise a dispute.
20. `resolveDispute(uint256 serviceContractId, address winner, uint256 amountToWinner, uint256 amountToLoser)`: Dispute resolver settles a dispute and distributes funds.
21. `claimScoutReward(uint255 serviceContractId)`: Scout claims their reward after the service contract is successfully completed and paid out.
22. `withdrawEscrowedFunds(uint256 serviceContractId)`: Allows the Project Owner to withdraw funds if the contract is cancelled before starting or funds are awarded to them in a dispute.
23. `getTalentDetails(uint256 talentId)`: Retrieve talent information.
24. `getProjectDetails(uint256 projectId)`: Retrieve project information.
25. `getScoutDetails(uint256 scoutId)`: Retrieve scout information.
26. `getProposalDetails(uint256 proposalId)`: Retrieve proposal information.
27. `getServiceContractDetails(uint256 serviceContractId)`: Retrieve service contract information.
28. `getTalentIdByAddress(address user)`: Get talent ID for a given address.
29. `getProjectIdByAddress(address user)`: Get project ID for a given address.
30. `getScoutIdByAddress(address user)`: Get scout ID for a given address.
31. `getTalentSkillLevel(uint256 talentId, string skillName)`: Calculate effective skill level (claimed + endorsed).
32. `getProjectRequiredSkillLevel(uint256 projectId, string skillName)`: Get required skill level for a project.
33. `getSkillHash(string skillName)`: Helper to get the hash for a skill name.
34. `getSkillNameByHash(bytes32 skillHash)`: Helper to get the name for a skill hash.
35. `getKnownSkills()`: Get the list of known skill names.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Using OpenZeppelin for safety

/**
 * @title DecentralizedTalentScout
 * @dev A smart contract for decentralized talent discovery, scouting, and escrowed service contracts.
 * Allows users to register as Talents, Projects, or Scouts. Features skill claims, reputation-weighted endorsements,
 * scout-submitted proposals, escrowed service contracts with milestones, scout rewards, and basic dispute resolution.
 */
contract DecentralizedTalentScout is ReentrancyGuard {

    // --- State Variables ---
    uint256 private nextTalentId = 1;
    uint256 private nextProjectId = 1;
    uint256 private nextScoutId = 1;
    uint256 private nextProposalId = 1;
    uint256 private nextServiceContractId = 1;

    address public owner; // Contract owner
    address public disputeResolver; // Address responsible for resolving disputes

    // Mappings to store entities by ID
    mapping(uint256 => Talent) public talents;
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Scout) public scouts;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => ServiceContract) public serviceContracts;

    // Mappings to get ID from address
    mapping(address => uint256) private addressToTalentId;
    mapping(address => uint256) private addressToProjectId;
    mapping(address => uint256) private addressToScoutId;

    // Skill management
    mapping(bytes32 => string) private skillHashToName;
    bytes32[] private knownSkillHashes; // Array of hashes for known skills

    // --- Structs ---

    struct Talent {
        address owner;
        string name;
        string bio;
        uint256 registrationTime;
        bool isRegistered;
        mapping(bytes32 => uint256) claimedSkillLevel; // Skill hash => claimed level (1-100)
        mapping(bytes32 => uint256) skillEndorsementScoreSum; // Skill hash => sum of weighted endorsements
        uint256 reputationScore; // Overall reputation score
    }

    struct Project {
        address owner;
        string title;
        string description;
        uint256 postedTime;
        bool isActive;
        uint256 requiredReputation; // Minimum reputation for talent to be considered
        mapping(bytes32 => uint256) requiredSkills; // Skill hash => required level (1-100)
        uint256[] associatedProposals; // List of proposal IDs for this project
    }

    struct Scout {
        address owner;
        string name;
        uint256 registrationTime;
        uint256 successfulProposalsCount; // Number of proposals accepted by both parties
        uint256 totalScoutRewardsClaimed;
        mapping(uint256 => uint256) pendingScoutRewards; // ServiceContractId => Reward amount
    }

    struct Proposal {
        uint256 proposalId;
        uint256 projectId;
        uint256 talentId;
        uint256 scoutId;
        string scoutMotivation;
        uint256 submissionTime;
        bool acceptedByProject;
        bool acceptedByTalent;
        bool isActive; // False after contract created or rejected
    }

    enum ServiceContractStatus { Pending, InProgress, CompletedByTalent, ApprovedByProject, PaymentReleased, DisputeRaised, Cancelled }

    struct ServiceContract {
        uint256 serviceContractId;
        uint256 proposalId; // Link back to the proposal
        uint256 projectId;
        uint256 talentId;
        uint256 scoutId;
        address projectOwner;
        uint256 agreedPayment; // Payment amount in Wei
        uint256 fundsInEscrow; // Current funds held in escrow for this contract
        uint256 milestoneCount;
        mapping(uint256 => bool) milestonesCompleted; // Milestone index => completed by talent
        mapping(uint256 => bool) milestonesApproved; // Milestone index => approved by project owner
        ServiceContractStatus status;
        uint256 creationTime;
        uint256 completionTime; // When fully approved/paid
        bool disputeRaised;
        string disputeReason;
    }

    // --- Events ---

    event TalentRegistered(uint256 talentId, address owner, string name);
    event ProjectRegistered(uint256 projectId, address owner, string title);
    event ScoutRegistered(uint256 scoutId, address owner, string name);
    event SkillClaimed(uint256 talentId, bytes32 skillHash, uint256 level);
    event SkillEndorsed(uint256 talentId, bytes32 skillHash, uint256 endorserTalentId, uint256 endorsementStrength, uint256 weightedScoreAdded);
    event RequiredSkillAddedToProject(uint256 projectId, bytes32 skillHash, uint256 requiredLevel);
    event ProposalSubmitted(uint256 proposalId, uint256 projectId, uint256 talentId, uint256 scoutId);
    event ProposalAcceptedByProject(uint256 proposalId, uint256 projectId);
    event ProposalAcceptedByTalent(uint256 proposalId, uint256 talentId);
    event ServiceContractCreated(uint256 serviceContractId, uint256 proposalId, uint256 agreedPayment);
    event MilestoneCompleted(uint256 serviceContractId, uint256 milestoneIndex);
    event MilestoneApproved(uint256 serviceContractId, uint256 milestoneIndex);
    event ContractCompletedByTalent(uint256 serviceContractId);
    event ContractApprovedByProject(uint256 serviceContractId);
    event PaymentReleased(uint256 serviceContractId, uint256 amount, address talent);
    event DisputeRaised(uint256 serviceContractId, address party, string reason);
    event DisputeResolved(uint256 serviceContractId, address winner, uint256 amountToWinner, uint256 amountToLoser);
    event ScoutRewardClaimed(uint256 serviceContractId, uint256 scoutId, uint256 rewardAmount);
    event FundsWithdrawnFromEscrow(uint256 serviceContractId, address recipient, uint256 amount);
    event KnownSkillAdded(bytes32 skillHash, string skillName);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this");
        _;
    }

    modifier onlyDisputeResolver() {
        require(msg.sender == disputeResolver, "Only dispute resolver can call this");
        _;
    }

    modifier onlyRegisteredTalent(uint256 talentId) {
        require(talents[talentId].isRegistered && talents[talentId].owner == msg.sender, "Not a registered talent or not owner");
        _;
    }

    modifier onlyRegisteredProjectOwner(uint256 projectId) {
        require(projects[projectId].isActive && projects[projectId].owner == msg.sender, "Not a registered project or not owner");
        _;
    }

     modifier onlyRegisteredScout(uint256 scoutId) {
        require(scouts[scoutId].isRegistered && scouts[scoutId].owner == msg.sender, "Not a registered scout or not owner");
        _;
    }

    modifier onlyProjectParty(uint256 serviceContractId) {
        require(serviceContracts[serviceContractId].projectOwner == msg.sender, "Only project owner for this contract");
        _;
    }

    modifier onlyTalentParty(uint256 serviceContractId) {
        require(talents[serviceContracts[serviceContractId].talentId].owner == msg.sender, "Only talent for this contract");
        _;
    }

    // --- Constructor ---

    constructor(address _disputeResolver) {
        owner = msg.sender;
        disputeResolver = _disputeResolver;
    }

    // --- Admin Functions ---

    /**
     * @dev Allows the owner to add a skill to the list of known skills.
     * @param skillName The name of the skill.
     */
    function addKnownSkill(string memory skillName) public onlyOwner {
        bytes32 skillHash = getSkillHash(skillName);
        require(bytes(skillHashToName[skillHash]).length == 0, "Skill already known");
        skillHashToName[skillHash] = skillName;
        knownSkillHashes.push(skillHash);
        emit KnownSkillAdded(skillHash, skillName);
    }

    /**
     * @dev Allows the owner to set the address responsible for resolving disputes.
     * @param _disputeResolver The address of the dispute resolver.
     */
    function setDisputeResolver(address _disputeResolver) public onlyOwner {
        require(_disputeResolver != address(0), "Invalid dispute resolver address");
        disputeResolver = _disputeResolver;
    }

    // --- Registration Functions ---

    /**
     * @dev Registers the caller as a Talent.
     * @param name Talent's name/alias.
     * @param bio Talent's short biography/description.
     */
    function registerTalent(string memory name, string memory bio) public {
        require(addressToTalentId[msg.sender] == 0, "Address already registered as a Talent");
        uint256 id = nextTalentId++;
        talents[id].owner = msg.sender;
        talents[id].name = name;
        talents[id].bio = bio;
        talents[id].registrationTime = block.timestamp;
        talents[id].isRegistered = true;
        addressToTalentId[msg.sender] = id;
        emit TalentRegistered(id, msg.sender, name);
    }

    /**
     * @dev Registers the caller as a Project creator.
     * @param title Project title.
     * @param description Project description.
     * @param requiredReputation Minimum reputation required for talent proposals.
     */
    function registerProject(string memory title, string memory description, uint256 requiredReputation) public {
        require(addressToProjectId[msg.sender] == 0, "Address already registered as a Project owner");
        uint256 id = nextProjectId++;
        projects[id].owner = msg.sender;
        projects[id].title = title;
        projects[id].description = description;
        projects[id].postedTime = block.timestamp;
        projects[id].isActive = true;
        projects[id].requiredReputation = requiredReputation;
        addressToProjectId[msg.sender] = id;
        emit ProjectRegistered(id, msg.sender, title);
    }

    /**
     * @dev Registers the caller as a Scout.
     * @param name Scout's name/alias.
     */
    function registerScout(string memory name) public {
        require(addressToScoutId[msg.sender] == 0, "Address already registered as a Scout");
        uint256 id = nextScoutId++;
        scouts[id].owner = msg.sender;
        scouts[id].name = name;
        scouts[id].registrationTime = block.timestamp;
        scouts[id].isRegistered = true;
        addressToScoutId[msg.sender] = id;
        emit ScoutRegistered(id, msg.sender, name);
    }

    // --- Skill Management ---

    /**
     * @dev Allows a registered Talent to claim a level for a specific skill.
     * Skill must be a known skill added by admin.
     * @param skillName The name of the skill to claim.
     * @param claimedLevel The claimed proficiency level (1-100).
     */
    function claimSkill(string memory skillName, uint256 claimedLevel) public {
        uint256 talentId = addressToTalentId[msg.sender];
        require(talents[talentId].isRegistered, "Caller is not a registered Talent");
        bytes32 skillHash = getSkillHash(skillName);
        require(bytes(skillHashToName[skillHash]).length > 0, "Unknown skill");
        require(claimedLevel > 0 && claimedLevel <= 100, "Claimed level must be between 1 and 100");

        talents[talentId].claimedSkillLevel[skillHash] = claimedLevel;
        emit SkillClaimed(talentId, skillHash, claimedLevel);
    }

    /**
     * @dev Allows a registered user (preferably Talent/Scout) to endorse a Talent's skill.
     * The endorsement weight is based on the endorser's reputation score.
     * @param talentId The ID of the talent being endorsed.
     * @param skillName The name of the skill being endorsed.
     * @param endorsementStrength The strength of the endorsement (e.g., 1-5).
     */
    function endorseSkill(uint256 talentId, string memory skillName, uint256 endorsementStrength) public {
        require(talents[talentId].isRegistered, "Talent not registered");
        uint256 endorserTalentId = addressToTalentId[msg.sender];
        uint256 endorserScoutId = addressToScoutId[msg.sender];
        require(endorserTalentId > 0 || endorserScoutId > 0, "Endorser must be a registered Talent or Scout");
        require(endorsementStrength > 0 && endorsementStrength <= 10, "Endorsement strength must be between 1 and 10");

        bytes32 skillHash = getSkillHash(skillName);
        require(bytes(skillHashToName[skillHash]).length > 0, "Unknown skill");

        // Get endorser's effective reputation (Talent rep + Scout rep contribution?)
        // Simple approach: Use Talent reputation if available, otherwise a base value.
        uint256 endorserReputation = endorserTalentId > 0 ? talents[endorserTalentId].reputationScore : 1; // Base rep for Scout/Project?

        // Prevent self-endorsement
        require(talents[talentId].owner != msg.sender, "Cannot self-endorse");

        uint256 weightedScoreAdded = endorserReputation * endorsementStrength;
        talents[talentId].skillEndorsementScoreSum[skillHash] += weightedScoreAdded;

        emit SkillEndorsed(talentId, skillHash, endorserTalentId > 0 ? endorserTalentId : 0, endorsementStrength, weightedScoreAdded);
    }

    /**
     * @dev Gets the calculated effective skill level for a talent.
     * Effective level is a combination of claimed level and endorsement score.
     * @param talentId The ID of the talent.
     * @param skillName The name of the skill.
     * @return The calculated effective skill level (1-100+). Can exceed 100 with strong endorsements.
     */
    function getTalentSkillLevel(uint256 talentId, string memory skillName) public view returns (uint256) {
        require(talents[talentId].isRegistered, "Talent not registered");
        bytes32 skillHash = getSkillHash(skillName);
        // Simple formula: claimed level + (endorsement score sum / constant_factor)
        // constant_factor prevents small endorsements from having too much impact
        uint256 constantFactor = 100; // Adjust this value based on desired impact
        return talents[talentId].claimedSkillLevel[skillHash] + (talents[talentId].skillEndorsementScoreSum[skillHash] / constantFactor);
    }

    // --- Project Management ---

    /**
     * @dev Project owner adds a required skill and minimum level for their project.
     * Skill must be a known skill.
     * @param projectId The ID of the project.
     * @param skillName The name of the required skill.
     * @param requiredLevel The minimum required level (1-100).
     */
    function addRequiredSkillToProject(uint256 projectId, string memory skillName, uint256 requiredLevel) public onlyRegisteredProjectOwner(projectId) {
        bytes32 skillHash = getSkillHash(skillName);
        require(bytes(skillHashToName[skillHash]).length > 0, "Unknown skill");
        require(requiredLevel > 0 && requiredLevel <= 100, "Required level must be between 1 and 100");

        projects[projectId].requiredSkills[skillHash] = requiredLevel;
        emit RequiredSkillAddedToProject(projectId, skillHash, requiredLevel);
    }

    /**
     * @dev Gets details for a project.
     * @param projectId The ID of the project.
     * @return Project details.
     */
    function getProjectDetails(uint256 projectId) public view returns (Project memory) {
        require(projects[projectId].isActive, "Project not found or inactive");
        // Note: This returns a copy, mapping details like requiredSkills won't be fully visible directly in some tools.
        // Specific getters for mappings are often needed.
        Project memory project = projects[projectId];
        // Zero out mapping fields for external view as they can't be returned directly
        delete project.requiredSkills;
        delete project.associatedProposals;
        return project;
    }

     /**
     * @dev Gets the required skill level for a specific skill in a project.
     * @param projectId The ID of the project.
     * @param skillName The name of the skill.
     * @return The required skill level. Returns 0 if skill is not required.
     */
    function getProjectRequiredSkillLevel(uint256 projectId, string memory skillName) public view returns (uint256) {
        require(projects[projectId].isActive, "Project not found or inactive");
        bytes32 skillHash = getSkillHash(skillName);
        return projects[projectId].requiredSkills[skillHash];
    }

    // --- Scouting & Proposals ---

    /**
     * @dev Allows a registered Scout to submit a proposal linking a Talent to a Project.
     * Checks if Talent meets basic requirements (reputation, claimed skills).
     * @param projectId The ID of the project.
     * @param talentId The ID of the talent being proposed.
     * @param scoutMotivation A brief message from the scout.
     */
    function submitProposal(uint256 projectId, uint256 talentId, string memory scoutMotivation) public nonReentrant {
        uint256 scoutId = addressToScoutId[msg.sender];
        require(scouts[scoutId].isRegistered, "Caller is not a registered Scout");
        require(projects[projectId].isActive, "Project not found or inactive");
        require(talents[talentId].isRegistered, "Talent not found");
        require(talents[talentId].reputationScore >= projects[projectId].requiredReputation, "Talent does not meet minimum reputation requirement");

        // Optional: Check if Talent meets required skill levels (can be resource intensive for many skills)
        // For simplicity, let's rely on off-chain tools to filter/search and on-chain for reputation check.
        // Or add a loop: for each required skill, check getTalentSkillLevel. Skip for gas limit.

        uint256 id = nextProposalId++;
        Proposal storage proposal = proposals[id];
        proposal.proposalId = id;
        proposal.projectId = projectId;
        proposal.talentId = talentId;
        proposal.scoutId = scoutId;
        proposal.scoutMotivation = scoutMotivation;
        proposal.submissionTime = block.timestamp;
        proposal.isActive = true;

        projects[projectId].associatedProposals.push(id); // Add proposal ID to project's list

        emit ProposalSubmitted(id, projectId, talentId, scoutId);
    }

    /**
     * @dev Allows the Project owner to accept a submitted proposal.
     * Requires Talent acceptance afterwards to be confirmed.
     * @param proposalId The ID of the proposal to accept.
     */
    function projectAcceptProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.isActive, "Proposal not found or inactive");
        require(projects[proposal.projectId].owner == msg.sender, "Only project owner can accept this proposal");
        require(!proposal.acceptedByProject, "Proposal already accepted by project");

        proposal.acceptedByProject = true;
        emit ProposalAcceptedByProject(proposalId, proposal.projectId);
    }

    /**
     * @dev Allows the Talent to accept a submitted proposal.
     * Requires Project acceptance beforehand to be confirmed.
     * @param proposalId The ID of the proposal to accept.
     */
    function talentAcceptProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.isActive, "Proposal not found or inactive");
        require(talents[proposal.talentId].owner == msg.sender, "Only talent can accept this proposal");
        require(!proposal.acceptedByTalent, "Proposal already accepted by talent");

        proposal.acceptedByTalent = true;
        emit ProposalAcceptedByTalent(proposalId, proposal.talentId);
    }

    // --- Service Contracts (Escrow) ---

    /**
     * @dev Creates a Service Contract once a proposal is accepted by both Project and Talent.
     * The project owner must send the agreed payment amount with this transaction.
     * @param proposalId The ID of the mutually accepted proposal.
     * @param milestoneCount The number of milestones for the service contract.
     */
    function createServiceContract(uint256 proposalId, uint256 milestoneCount) public payable nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.isActive, "Proposal not found or inactive");
        require(proposal.acceptedByProject && proposal.acceptedByTalent, "Proposal not accepted by both parties");
        require(projects[proposal.projectId].owner == msg.sender, "Only project owner can create the contract");
        require(msg.value > 0, "Must send agreed payment with contract creation");
        require(milestoneCount > 0, "Must have at least one milestone");

        // Deactivate the proposal once the contract is created
        proposal.isActive = false;

        uint256 id = nextServiceContractId++;
        ServiceContract storage contract_ = serviceContracts[id];
        contract_.serviceContractId = id;
        contract_.proposalId = proposalId;
        contract_.projectId = proposal.projectId;
        contract_.talentId = proposal.talentId;
        contract_.scoutId = proposal.scoutId;
        contract_.projectOwner = msg.sender; // Store owner address directly for easy access
        contract_.agreedPayment = msg.value;
        contract_.fundsInEscrow = msg.value;
        contract_.milestoneCount = milestoneCount;
        contract_.status = ServiceContractStatus.InProgress;
        contract_.creationTime = block.timestamp;

        emit ServiceContractCreated(id, proposalId, msg.value);
    }

    /**
     * @dev Allows the Talent to mark a specific milestone as completed.
     * @param serviceContractId The ID of the service contract.
     * @param milestoneIndex The index of the milestone (0 to milestoneCount-1).
     */
    function markMilestoneCompleted(uint256 serviceContractId, uint256 milestoneIndex) public nonReentrant onlyTalentParty(serviceContractId) {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status == ServiceContractStatus.InProgress, "Contract is not in progress");
        require(milestoneIndex < contract_.milestoneCount, "Invalid milestone index");
        require(!contract_.milestonesCompleted[milestoneIndex], "Milestone already marked as completed");

        contract_.milestonesCompleted[milestoneIndex] = true;
        emit MilestoneCompleted(serviceContractId, milestoneIndex);
    }

    /**
     * @dev Allows the Project owner to approve a milestone marked as completed by the Talent.
     * @param serviceContractId The ID of the service contract.
     * @param milestoneIndex The index of the milestone (0 to milestoneCount-1).
     */
    function approveMilestoneCompletion(uint256 serviceContractId, uint256 milestoneIndex) public nonReentrant onlyProjectParty(serviceContractId) {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status == ServiceContractStatus.InProgress, "Contract is not in progress");
        require(milestoneIndex < contract_.milestoneCount, "Invalid milestone index");
        require(contract_.milestonesCompleted[milestoneIndex], "Milestone not marked as completed by Talent");
        require(!contract_.milestonesApproved[milestoneIndex], "Milestone already approved");

        contract_.milestonesApproved[milestoneIndex] = true;
        emit MilestoneApproved(serviceContractId, milestoneIndex);
    }

    /**
     * @dev Allows the Talent to mark the entire service contract as completed.
     * Typically called after the final milestone is done.
     * @param serviceContractId The ID of the service contract.
     */
    function talentMarkContractCompleted(uint256 serviceContractId) public nonReentrant onlyTalentParty(serviceContractId) {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status == ServiceContractStatus.InProgress, "Contract is not in progress");

        contract_.status = ServiceContractStatus.CompletedByTalent;
        emit ContractCompletedByTalent(serviceContractId);
    }

    /**
     * @dev Allows the Project owner to approve the entire service contract as completed.
     * This is the final approval step before payment can be released.
     * @param serviceContractId The ID of the service contract.
     */
    function projectApproveFullContract(uint256 serviceContractId) public nonReentrant onlyProjectParty(serviceContractId) {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status == ServiceContractStatus.CompletedByTalent, "Contract not marked completed by Talent");

        // Optional: Check if all milestones are approved before allowing full approval?
        // For simplicity, let's allow full approval directly after Talent completion mark.
        // If milestone tracking is strict, uncomment below or add checks:
        // for (uint256 i = 0; i < contract_.milestoneCount; i++) {
        //     require(contract_.milestonesApproved[i], "Not all milestones approved");
        // }

        contract_.status = ServiceContractStatus.ApprovedByProject;
        contract_.completionTime = block.timestamp;

        // Increase Talent's reputation upon successful contract completion
        uint256 talentId = contract_.talentId;
        talents[talentId].reputationScore += 10; // Simple reputation boost

        emit ContractApprovedByProject(serviceContractId);
    }

    // --- Payment & Rewards ---

    /**
     * @dev Releases the full escrowed payment to the Talent's address.
     * Can only be called after the project owner has approved the full contract.
     * Uses call for safe Ether transfer.
     * @param serviceContractId The ID of the service contract.
     */
    function releaseFullPayment(uint256 serviceContractId) public nonReentrant {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status == ServiceContractStatus.ApprovedByProject, "Contract not approved by Project");
        require(contract_.fundsInEscrow > 0, "No funds in escrow");

        uint256 talentId = contract_.talentId;
        address payable talentAddress = payable(talents[talentId].owner);
        uint256 amount = contract_.fundsInEscrow;

        contract_.fundsInEscrow = 0; // Zero out escrow balance *before* transfer
        contract_.status = ServiceContractStatus.PaymentReleased;

        // Calculate and store scout reward
        uint256 scoutRewardPercentage = 5; // Example: 5% of contract value
        uint256 scoutRewardAmount = (amount * scoutRewardPercentage) / 100;
        uint256 scoutId = contract_.scoutId;
        if (scoutId > 0 && scouts[scoutId].isRegistered) {
             scouts[scoutId].pendingScoutRewards[serviceContractId] = scoutRewardAmount;
             amount -= scoutRewardAmount; // Subtract reward from talent's payment
        }


        (bool success, ) = talentAddress.call{value: amount}("");
        require(success, "Payment transfer failed");

        emit PaymentReleased(serviceContractId, amount, talentAddress);
        // Note: Scout reward is claimed separately
    }

    /**
     * @dev Allows a registered Scout to claim their reward for a successfully completed and paid contract.
     * @param serviceContractId The ID of the service contract.
     */
    function claimScoutReward(uint256 serviceContractId) public nonReentrant {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        uint256 scoutId = addressToScoutId[msg.sender];
        require(scouts[scoutId].isRegistered, "Caller is not a registered Scout");
        require(contract_.status == ServiceContractStatus.PaymentReleased, "Contract payment not released yet");
        require(contract_.scoutId == scoutId, "Caller is not the scout for this contract");

        uint256 rewardAmount = scouts[scoutId].pendingScoutRewards[serviceContractId];
        require(rewardAmount > 0, "No pending reward for this contract");

        scouts[scoutId].pendingScoutRewards[serviceContractId] = 0; // Zero out before transfer
        scouts[scoutId].successfulProposalsCount++;
        scouts[scoutId].totalScoutRewardsClaimed += rewardAmount;

        address payable scoutAddress = payable(msg.sender);
        (bool success, ) = scoutAddress.call{value: rewardAmount}("");
        require(success, "Scout reward transfer failed");

        emit ScoutRewardClaimed(serviceContractId, scoutId, rewardAmount);
    }

    /**
     * @dev Allows the Project Owner to withdraw escrowed funds if the contract is cancelled (e.g., before starting)
     * or awarded to them via dispute resolution.
     * @param serviceContractId The ID of the service contract.
     */
    function withdrawEscrowedFunds(uint256 serviceContractId) public nonReentrant onlyProjectParty(serviceContractId) {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        // Can only withdraw if funds are still in escrow and contract is not completed/paid/disputed
        require(contract_.fundsInEscrow > 0, "No funds in escrow");
        require(
            contract_.status != ServiceContractStatus.ApprovedByProject &&
            contract_.status != ServiceContractStatus.PaymentReleased &&
            contract_.status != ServiceContractStatus.DisputeRaised,
            "Funds cannot be withdrawn by project owner in current status"
        );

        uint256 amount = contract_.fundsInEscrow;
        contract_.fundsInEscrow = 0; // Zero out before transfer
        contract_.status = ServiceContractStatus.Cancelled; // Mark as cancelled

        address payable projectAddress = payable(msg.sender);
        (bool success, ) = projectAddress.call{value: amount}("");
        require(success, "Withdrawal transfer failed");

        emit FundsWithdrawnFromEscrow(serviceContractId, msg.sender, amount);
    }

    // --- Dispute Resolution ---

    /**
     * @dev Allows either the Talent or Project party to raise a dispute on a service contract.
     * @param serviceContractId The ID of the service contract.
     * @param reason Brief reason for the dispute.
     */
    function raiseDispute(uint256 serviceContractId, string memory reason) public nonReentrant {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status > ServiceContractStatus.Pending && contract_.status < ServiceContractStatus.PaymentReleased, "Cannot raise dispute in current status");
        require(!contract_.disputeRaised, "Dispute already raised");
        require(contract_.projectOwner == msg.sender || talents[contract_.talentId].owner == msg.sender, "Only contract parties can raise a dispute");
        require(bytes(reason).length > 0, "Reason for dispute is required");

        contract_.status = ServiceContractStatus.DisputeRaised;
        contract_.disputeRaised = true;
        contract_.disputeReason = reason;

        emit DisputeRaised(serviceContractId, msg.sender, reason);
    }

    /**
     * @dev Allows the designated Dispute Resolver to settle a dispute.
     * Distributes the escrowed funds between the winner and loser (can be 100% to one party, or split).
     * @param serviceContractId The ID of the service contract.
     * @param winner The address designated as the winner (will receive amountToWinner).
     * @param amountToWinner Amount of escrowed funds to send to the winner.
     * @param amountToLoser Amount of escrowed funds to send to the other party (loser).
     */
    function resolveDispute(uint256 serviceContractId, address winner, uint256 amountToWinner, uint256 amountToLoser) public nonReentrant onlyDisputeResolver {
        ServiceContract storage contract_ = serviceContracts[serviceContractId];
        require(contract_.status == ServiceContractStatus.DisputeRaised, "Contract is not in a dispute");
        require(amountToWinner + amountToLoser <= contract_.fundsInEscrow, "Distribution amounts exceed escrowed funds");

        address payable winnerAddress = payable(winner);
        address payable loserAddress;

        // Determine the loser's address
        if (winner == contract_.projectOwner) {
            loserAddress = payable(talents[contract_.talentId].owner);
        } else if (winner == talents[contract_.talentId].owner) {
            loserAddress = payable(contract_.projectOwner);
        } else {
            // Handle case where winner is neither party? Maybe send remaining to owner?
            // For simplicity, require winner is one of the parties.
            revert("Invalid winner address");
        }
        require(winnerAddress != loserAddress, "Winner and loser addresses cannot be the same");


        uint256 totalDistributed = amountToWinner + amountToLoser;
        uint256 remainingFunds = contract_.fundsInEscrow - totalDistributed;

        contract_.fundsInEscrow = 0; // Zero out before transfers
        contract_.status = ServiceContractStatus.PaymentReleased; // Mark as resolved and funds distributed
        contract_.completionTime = block.timestamp; // Mark completion time upon resolution

        // Transfer funds
        if (amountToWinner > 0) {
            (bool successWinner, ) = winnerAddress.call{value: amountToWinner}("");
             if (!successWinner) {
                 // This is a critical failure, potential funds locked.
                 // A robust system might require manual recovery or have fallback.
                 // For this example, we just revert.
                 revert("Winner fund transfer failed");
             }
        }

        if (amountToLoser > 0) {
            (bool successLoser, ) = loserAddress.call{value: amountToLoser}("");
             if (!successLoser) {
                  // Similar critical failure potential
                 revert("Loser fund transfer failed");
             }
        }

        // If any funds remain due to rounding or explicit decision, send to project owner or dispute resolver?
        // Sending to project owner is simple default.
         if (remainingFunds > 0) {
             (bool successRemaining, ) = payable(contract_.projectOwner).call{value: remainingFunds}("");
             require(successRemaining, "Remaining fund transfer failed");
         }


        // Note: Reputation update on dispute resolution is complex.
        // Might penalize loser's reputation? Add complexity, skip for now.

        emit DisputeResolved(serviceContractId, winner, amountToWinner, amountToLoser);

        // Scout reward is NOT paid on disputed contracts in this simple model.
        // A complex model might have a partial scout reward.
    }

    // --- Getters ---

    /**
     * @dev Gets the hash for a given skill name (SHA-256).
     * @param skillName The name of the skill.
     * @return The bytes32 hash.
     */
    function getSkillHash(string memory skillName) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(skillName));
    }

    /**
     * @dev Gets the name of a skill from its hash.
     * @param skillHash The hash of the skill.
     * @return The skill name. Returns empty string if hash is unknown.
     */
     function getSkillNameByHash(bytes32 skillHash) public view returns (string memory) {
         return skillHashToName[skillHash];
     }

    /**
     * @dev Get the list of all known skill hashes.
     */
    function getKnownSkillHashes() public view returns (bytes32[] memory) {
        return knownSkillHashes;
    }

     /**
     * @dev Get the total count of known skills.
     */
    function getKnownSkillCount() public view returns (uint256) {
        return knownSkillHashes.length;
    }


    /**
     * @dev Get Talent ID for a given address. Returns 0 if not registered.
     */
    function getTalentIdByAddress(address user) public view returns (uint256) {
        return addressToTalentId[user];
    }

    /**
     * @dev Get Project ID for a given address. Returns 0 if not registered.
     */
    function getProjectIdByAddress(address user) public view returns (uint256) {
        return addressToProjectId[user];
    }

    /**
     * @dev Get Scout ID for a given address. Returns 0 if not registered.
     */
    function getScoutIdByAddress(address user) public view returns (uint256) {
        return addressToScoutId[user];
    }

    /**
     * @dev Retrieve Talent details by ID.
     */
    function getTalentDetails(uint256 talentId) public view returns (Talent memory) {
        require(talents[talentId].isRegistered, "Talent not registered");
        // Note: Mappings within the struct are not returned directly
        Talent memory talent = talents[talentId];
        delete talent.claimedSkillLevel;
        delete talent.skillEndorsementScoreSum;
        return talent;
    }


    /**
     * @dev Retrieve Scout details by ID.
     */
    function getScoutDetails(uint256 scoutId) public view returns (Scout memory) {
        require(scouts[scoutId].isRegistered, "Scout not registered");
         // Note: Mappings within the struct are not returned directly
        Scout memory scout = scouts[scoutId];
        delete scout.pendingScoutRewards;
        return scout;
    }


    /**
     * @dev Retrieve Proposal details by ID.
     */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(proposals[proposalId].proposalId != 0, "Proposal not found"); // Check if struct exists
        return proposals[proposalId];
    }

    /**
     * @dev Retrieve Service Contract details by ID.
     */
    function getServiceContractDetails(uint256 serviceContractId) public view returns (ServiceContract memory) {
        require(serviceContracts[serviceContractId].serviceContractId != 0, "Service Contract not found"); // Check if struct exists
         // Note: Mappings within the struct are not returned directly
        ServiceContract memory contract_ = serviceContracts[serviceContractId];
        delete contract_.milestonesCompleted;
        delete contract_.milestonesApproved;
        return contract_;
    }

    // --- Fallback to receive Ether ---
    // This is generally not recommended for contracts with specific payable functions like createServiceContract.
    // Including it only if unsolicited Ether might be sent and needs to be handled,
    // but it's better to design the contract to only receive Ether in expected functions.
    /*
    receive() external payable {
        // Optionally log received ether or just allow it
        emit EtherReceived(msg.sender, msg.value);
    }
    event EtherReceived(address indexed sender, uint256 amount);
    */

    // --- Additional Getters (To reach 20+ easily and provide more utility) ---

    function getTalentCount() public view returns (uint256) {
        return nextTalentId - 1;
    }

    function getProjectCount() public view returns (uint256) {
        return nextProjectId - 1;
    }

     function getScoutCount() public view returns (uint256) {
        return nextScoutId - 1;
    }

    function getProposalCount() public view returns (uint256) {
        return nextProposalId - 1;
    }

    function getServiceContractCount() public view returns (uint256) {
        return nextServiceContractId - 1;
    }

    /**
     * @dev Get the list of proposal IDs associated with a project.
     * @param projectId The ID of the project.
     */
    function getProjectProposalIds(uint256 projectId) public view returns (uint256[] memory) {
         require(projects[projectId].isActive, "Project not found or inactive");
         return projects[projectId].associatedProposals;
    }

     /**
      * @dev Check if a milestone is marked completed by talent.
      * @param serviceContractId The ID of the service contract.
      * @param milestoneIndex The index of the milestone.
      */
     function isMilestoneCompletedByTalent(uint256 serviceContractId, uint256 milestoneIndex) public view returns (bool) {
        require(serviceContracts[serviceContractId].serviceContractId != 0, "Service Contract not found");
        require(milestoneIndex < serviceContracts[serviceContractId].milestoneCount, "Invalid milestone index");
        return serviceContracts[serviceContractId].milestonesCompleted[milestoneIndex];
     }

     /**
      * @dev Check if a milestone is approved by project owner.
      * @param serviceContractId The ID of the service contract.
      * @param milestoneIndex The index of the milestone.
      */
     function isMilestoneApprovedByProject(uint256 serviceContractId, uint256 milestoneIndex) public view returns (bool) {
        require(serviceContracts[serviceContractId].serviceContractId != 0, "Service Contract not found");
        require(milestoneIndex < serviceContracts[serviceContractId].milestoneCount, "Invalid milestone index");
        return serviceContracts[serviceContractId].milestonesApproved[milestoneIndex];
     }

    // Total functions: Constructor (1) + Admin (2) + Registration (3) + Skills (3) + Project (3) + Proposals (4) + Contracts (5) + Payments (3) + Disputes (2) + Getters (14) = 40 functions. Exceeds the 20+ requirement significantly.

}
```