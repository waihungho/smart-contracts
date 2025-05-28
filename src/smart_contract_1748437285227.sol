Okay, let's design a smart contract for a Decentralized Autonomous Talent Platform. This platform will allow users to register as talents or clients, post gigs, bid on gigs, handle payments in escrow, manage reputation through staking, and resolve disputes via a basic on-chain governance mechanism.

It incorporates concepts like escrow, staking, reputation, on-chain status tracking, and a simplified DAO-like dispute resolution, aiming to be distinct from standard token, NFT, or basic marketplace contracts.

Here's the plan:

**Outline and Function Summary**

**Contract Name:** `DecentralizedAutonomousTalentPlatform`

**Purpose:** A decentralized platform connecting talents and clients for gig-based work, featuring escrow, reputation staking, and DAO-assisted dispute resolution.

**Core Concepts:**
1.  **User Roles:** Users can register as `Talent`, `Client`, or potentially both.
2.  **Reputation Staking:** Users stake tokens to earn reputation, influencing visibility and voting power.
3.  **Gig Lifecycle & Escrow:** Clients post gigs with a budget, funds are held in escrow, released upon completion or mediated by dispute resolution.
4.  **Proposals:** Talents bid on gigs by submitting proposals.
5.  **Dispute Resolution:** On-chain process for resolving disagreements, potentially involving community/DAO voting.
6.  **Basic Governance:** A simplified voting mechanism, initially focused on dispute outcomes.

**Data Structures:**
*   `User`: Profile information, role, reputation score, staked amount, balance.
*   `TalentOffering`: A specific service/skill offered by a Talent.
*   `Gig`: A job posting by a Client, including budget, status, assigned talent, proposals.
*   `Proposal`: A Talent's bid on a Gig.
*   `Dispute`: Details of a dispute for a specific Gig.
*   `GovernanceProposal`: A proposal for the DAO (e.g., dispute outcome, platform parameter changes).

**State Variables:**
*   Mappings to store Users, TalentOfferings, Gigs, Proposals, Disputes, GovernanceProposals by ID.
*   Counters for generating unique IDs.
*   Platform parameters (e.g., staking requirements, fees, dispute period).
*   Mapping to track user balances within the contract.

**Events:**
*   `UserRegistered`, `UserProfileUpdated`
*   `ReputationStaked`, `ReputationUnstaked`
*   `TalentOfferingAdded`, `TalentOfferingUpdated`, `TalentOfferingRemoved`
*   `GigPosted`, `GigUpdated`, `GigCancelled`, `GigInProgress`, `GigCompleted`
*   `ProposalSubmitted`, `ProposalWithdrawn`, `ProposalAccepted`, `ProposalRejected`
*   `FundsDeposited`, `FundsWithdrawalRequested`, `FundsWithdrawn`
*   `DisputeFiled`, `DisputeEvidenceSubmitted`, `DisputeResolved`
*   `GovernanceProposalCreated`, `VotedOnProposal`, `ProposalExecuted`

**Modifiers:**
*   `onlyRegisteredUser`: Ensures caller is a registered user.
*   `onlyRole(UserRole requiredRole)`: Ensures caller has a specific role.
*   `onlyGigClient(uint256 gigId)`: Ensures caller is the client of the gig.
*   `onlyGigTalent(uint256 gigId)`: Ensures caller is the assigned talent of the gig.
*   `onlyGigParticipant(uint256 gigId)`: Ensures caller is either the client or the assigned talent of the gig.
*   `onlyDisputeParticipant(uint256 disputeId)`: Ensures caller is involved in the dispute.
*   `onlyDAO(uint256 proposalId)`: Ensures caller is authorized to execute DAO proposals (simplified, maybe `owner` or a specific DAO multisig address).

**Functions (20+):**

1.  `registerUser(string calldata _name, string calldata _role)`: Registers a new user with a name and role (Talent or Client).
2.  `updateUserProfile(string calldata _name, string calldata _bio)`: Updates the caller's profile information.
3.  `depositFunds()`: Allows a user to deposit native tokens into their platform balance. (receives Ether)
4.  `withdrawFunds(uint256 _amount)`: Allows a user to request withdrawal from their platform balance (potentially with a delay/process).
5.  `stakeReputation()`: Allows a user to stake native tokens to increase their reputation score. (receives Ether)
6.  `unstakeReputation(uint256 _amount)`: Allows a user to unstake tokens (subject to cooldown).
7.  `addTalentOffering(string calldata _title, string calldata _description, string[] calldata _tags, uint256 _pricePerUnit)`: Talent adds a service offering.
8.  `updateTalentOffering(uint256 _offeringId, string calldata _title, string calldata _description, string[] calldata _tags, uint256 _pricePerUnit)`: Talent updates an existing offering.
9.  `removeTalentOffering(uint256 _offeringId)`: Talent removes an offering.
10. `postGig(string calldata _title, string calldata _description, string[] calldata _requiredSkills, uint256 _budget, uint256 _deadline)`: Client posts a new job. (receives Ether for budget)
11. `updateGig(uint256 _gigId, string calldata _description, uint256 _deadline)`: Client updates an open gig.
12. `cancelGig(uint256 _gigId)`: Client cancels an open gig (refunds budget).
13. `submitProposal(uint256 _gigId, uint256 _proposedPrice, uint256 _proposedTimeline, string calldata _message)`: Talent submits a bid on a gig. (requires staking a small proposal fee/stake)
14. `withdrawProposal(uint256 _proposalId)`: Talent withdraws their bid. (refunds proposal stake)
15. `acceptProposal(uint256 _proposalId)`: Client accepts a proposal, assigning the talent and changing gig status.
16. `closeGig(uint256 _gigId)`: Assigned talent or Client marks a gig as completed (triggers escrow release to talent, potentially minus platform fee).
17. `fileDispute(uint256 _gigId, string calldata _reason)`: Client or Talent files a dispute on a gig. (requires staking a dispute fee)
18. `submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceHash)`: Participant submits evidence hash (pointing to off-chain data).
19. `createGovernanceProposal(string calldata _description, uint256 _linkedDisputeId, bytes calldata _proposalData)`: Allows proposal creation (e.g., vote on dispute outcome, change fee). (requires staking)
20. `voteOnProposal(uint256 _proposalId, bool _support)`: Registered user with reputation votes on a governance proposal.
21. `executeProposal(uint256 _proposalId)`: Owner/DAO executes a passed proposal (e.g., distributing funds based on dispute vote).
22. `getGigDetails(uint256 _gigId)`: View details of a specific gig.
23. `getUserProfile(address _user)`: View a user's profile.
24. `getProposalsForGig(uint256 _gigId)`: List proposals submitted for a gig.
25. `getDisputeDetails(uint256 _disputeId)`: View details of a specific dispute.
26. `getGovernanceProposal(uint256 _proposalId)`: View details of a specific governance proposal.
27. `getPlatformBalance(address _user)`: View a user's balance within the contract.
28. `searchTalentBySkill(string calldata _skillTag)`: Search for talents by skill tag (returns list of talent IDs with that tag).
29. `searchGigsBySkill(string calldata _skillTag)`: Search for gigs by required skill tag (returns list of gig IDs with that tag).
30. `getTalentOfferingsByUser(address _user)`: List all offerings by a specific talent.
31. `getGigsPostedByClient(address _user)`: List all gigs posted by a client.
32. `getProposalsSubmittedByTalent(address _user)`: List all proposals submitted by a talent.
33. `calculateReputation(address _user)`: Internal/external view function to show derived reputation score. (Based on stake, possibly completed gigs, etc.)
34. `getReputationStake(address _user)`: View the current staked amount of a user.

*Note: Functions 28, 29 are simplified searches. True on-chain string search is complex/gas-intensive. These would iterate through relevant items and filter.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAutonomousTalentPlatform
 * @dev A decentralized platform connecting talents and clients for gig-based work,
 * featuring escrow, reputation staking, and DAO-assisted dispute resolution.
 *
 * Outline:
 * - Enums for User Roles, Gig Status, Proposal Status, Dispute Status, Governance Proposal Status
 * - Structs for User, TalentOffering, Gig, Proposal, Dispute, GovernanceProposal
 * - State variables for mappings, counters, platform parameters, balances
 * - Events for tracking key actions
 * - Modifiers for access control
 * - Core Functions (User, TalentOffering, Gig, Proposal, Payment, Dispute, Governance, Getters/Search)
 */
contract DecentralizedAutonomousTalentPlatform {

    // --- Enums ---

    enum UserRole { None, Talent, Client }
    enum GigStatus { Open, InProgress, Completed, Disputed, Cancelled }
    enum ProposalStatus { Submitted, Accepted, Rejected, Withdrawn }
    enum DisputeStatus { Open, EvidenceSubmission, Voting, Resolved }
    enum GovernanceProposalStatus { Open, Approved, Rejected, Executed }
    enum DisputeOutcome { Undecided, FavorClient, FavorTalent, Split }

    // --- Structs ---

    struct User {
        uint256 id;
        address wallet;
        string name;
        string bio;
        UserRole role;
        uint256 reputationScore; // Derived or based on stake/activity
        uint256 reputationStake; // Tokens staked for reputation
        uint256 lastReputationUnstake; // Timestamp for cooldown
        bool registered;
    }

    struct TalentOffering {
        uint256 id;
        uint256 userId; // Link to User struct
        string title;
        string description;
        string[] tags; // e.g., ["Solidity", "React", "Design"]
        uint256 pricePerUnit; // e.g., per hour, per project milestone
        bool isActive;
    }

    struct Gig {
        uint256 id;
        uint256 clientId; // Link to User struct
        string title;
        string description;
        string[] requiredSkills;
        uint256 budget; // Total budget in native tokens
        uint256 deadline; // Unix timestamp
        GigStatus status;
        uint256 assignedTalentId; // Link to User struct (0 if none assigned)
        uint256 createdAt; // Unix timestamp
    }

    struct Proposal {
        uint256 id;
        uint256 gigId; // Link to Gig struct
        uint256 talentId; // Link to User struct
        uint256 proposedPrice; // Bid price for the gig
        uint256 proposedTimeline; // Proposed completion time (e.g., in days)
        string message; // Cover letter/details
        ProposalStatus status;
        uint256 stake; // Stake required to submit proposal
        uint256 createdAt; // Unix timestamp
    }

    struct Dispute {
        uint256 id;
        uint256 gigId; // Link to Gig struct
        uint256 filerId; // User ID of the filer
        uint256 counterpartyId; // Other participant's User ID
        string reason;
        mapping(uint256 => string[]) evidenceHashes; // userId => evidence hashes (points off-chain)
        DisputeStatus status;
        uint256 stake; // Stake required to file dispute
        uint256 filingTime; // Unix timestamp
        uint256 votingEnds; // Unix timestamp for voting phase end
        uint256 resolutionGovernanceProposalId; // Link to the governance proposal handling resolution
    }

     struct GovernanceProposal {
        uint256 id;
        uint256 creatorId; // User ID of the creator
        string description;
        bytes proposalData; // Data specific to the proposal type (e.g., DisputeOutcome for dispute resolution)
        uint256 linkedDisputeId; // If this proposal is for a dispute, link it
        mapping(uint256 => bool) votes; // userId => true for support, false against (simple binary)
        mapping(uint256 => bool) hasVoted; // userId => true if voted
        uint256 totalSupportVotes;
        uint256 totalAgainstVotes;
        GovernanceProposalStatus status;
        uint256 creationTime;
        uint256 votingEnds; // Unix timestamp
        uint256 stake; // Stake required to create proposal
    }


    // --- State Variables ---

    uint256 private _userIdCounter = 0;
    mapping(address => uint256) private _userWalletToId;
    mapping(uint256 => User) private _users;

    uint256 private _talentOfferingIdCounter = 0;
    mapping(uint256 => TalentOffering) private _talentOfferings;
    mapping(uint256 => uint256[]) private _userTalentOfferings; // userId => array of offering IDs
    mapping(string => uint256[]) private _talentOfferingsByTag; // tag => array of offering IDs

    uint256 private _gigIdCounter = 0;
    mapping(uint256 => Gig) private _gigs;
    mapping(uint256 => uint256[]) private _clientGigs; // clientId => array of gig IDs
     mapping(string => uint256[]) private _gigsBySkill; // skill => array of gig IDs

    uint256 private _proposalIdCounter = 0;
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => uint256[]) private _gigProposals; // gigId => array of proposal IDs
    mapping(uint256 => uint256[]) private _talentProposals; // talentId => array of proposal IDs

    uint256 private _disputeIdCounter = 0;
    mapping(uint256 => Dispute) private _disputes;
    mapping(uint256 => uint256) private _gigDispute; // gigId => disputeId (0 if no active dispute)

    uint256 private _governanceProposalIdCounter = 0;
    mapping(uint256 => GovernanceProposal) private _governanceProposals;
    uint256[] private _activeGovernanceProposals; // Array of IDs for currently votable proposals

    mapping(address => uint256) private _balances; // User balances within the contract

    // Platform Parameters (Example - could be made configurable via governance)
    uint256 public minReputationStake = 0.1 ether;
    uint256 public reputationUnstakeCooldown = 7 days;
    uint256 public proposalStakeAmount = 0.01 ether;
    uint256 public disputeStakeAmount = 0.05 ether;
    uint256 public platformFeeRate = 50; // 50 = 5.0% (rate * 100)
    uint256 public evidenceSubmissionPeriod = 3 days;
    uint256 public votingPeriod = 5 days;

    address public immutable platformOwner; // Address for receiving platform fees (initially, could become a DAO treasury)


    // --- Events ---

    event UserRegistered(uint256 indexed userId, address indexed wallet, UserRole role, string name);
    event UserProfileUpdated(uint256 indexed userId, string newName, string newBio);
    event ReputationStaked(uint256 indexed userId, uint256 amount, uint256 newStake);
    event ReputationUnstaked(uint256 indexed userId, uint256 amount, uint256 newStake);
    event TalentOfferingAdded(uint256 indexed offeringId, uint256 indexed userId, string title);
    event TalentOfferingUpdated(uint256 indexed offeringId, string title);
    event TalentOfferingRemoved(uint256 indexed offeringId);
    event GigPosted(uint256 indexed gigId, uint256 indexed clientId, string title, uint256 budget);
    event GigUpdated(uint256 indexed gigId, uint256 deadline);
    event GigCancelled(uint256 indexed gigId, uint256 indexed clientId, uint256 refundAmount);
    event GigInProgress(uint256 indexed gigId, uint256 indexed assignedTalentId);
    event GigCompleted(uint256 indexed gigId, uint256 indexed assignedTalentId, uint256 payoutAmount, uint256 platformFee);
    event ProposalSubmitted(uint256 indexed proposalId, uint256 indexed gigId, uint256 indexed talentId);
    event ProposalWithdrawn(uint256 indexed proposalId);
    event ProposalAccepted(uint255 indexed proposalId, uint256 indexed gigId);
    event ProposalRejected(uint256 indexed proposalId);
    event FundsDeposited(address indexed user, uint256 amount, uint256 newBalance);
    event FundsWithdrawalRequested(address indexed user, uint256 amount, uint256 newBalance); // Can implement a withdrawal queue
    event FundsWithdrawn(address indexed user, uint256 amount, uint256 newBalance);
    event DisputeFiled(uint256 indexed disputeId, uint256 indexed gigId, uint256 indexed filerId, string reason);
    event DisputeEvidenceSubmitted(uint256 indexed disputeId, uint256 indexed userId, string evidenceHash);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus newStatus, DisputeOutcome outcome, uint256 governanceProposalId);
    event GovernanceProposalCreated(uint256 indexed proposalId, uint256 indexed creatorId, string description);
    event VotedOnProposal(uint256 indexed proposalId, uint256 indexed userId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, GovernanceProposalStatus newStatus);


    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(_userWalletToId[msg.sender] != 0, "User not registered");
        _;
    }

    modifier onlyRole(UserRole requiredRole) {
        require(_users[_userWalletToId[msg.sender]].role == requiredRole, "User does not have required role");
        _;
    }

    modifier onlyGigClient(uint256 gigId) {
        require(_gigs[gigId].clientId == _userWalletToId[msg.sender], "Not the gig client");
        _;
    }

     modifier onlyGigTalent(uint256 gigId) {
        require(_gigs[gigId].assignedTalentId != 0, "Gig has no assigned talent");
        require(_gigs[gigId].assignedTalentId == _userWalletToId[msg.sender], "Not the assigned gig talent");
        _;
    }

    modifier onlyGigParticipant(uint256 gigId) {
        uint256 userId = _userWalletToId[msg.sender];
        require(userId != 0, "User not registered");
        require(_gigs[gigId].clientId == userId || _gigs[gigId].assignedTalentId == userId, "Not a participant in this gig");
        _;
    }

     modifier onlyDisputeParticipant(uint256 disputeId) {
        uint256 userId = _userWalletToId[msg.sender];
        require(userId != 0, "User not registered");
        require(_disputes[disputeId].filerId == userId || _disputes[disputeId].counterpartyId == userId, "Not a participant in this dispute");
        _;
    }

    // --- Constructor ---

    constructor() {
        platformOwner = msg.sender;
        // Increment user counter for ID 0 to be invalid/unassigned
        _userIdCounter++;
    }

    // --- User Management (3 Functions + 2 Balance, 2 Stake) ---

    /**
     * @dev Registers a new user on the platform.
     * @param _name The user's desired name.
     * @param _role The user's role (Talent or Client).
     */
    function registerUser(string calldata _name, string calldata _role) public {
        require(_userWalletToId[msg.sender] == 0, "User already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");

        _userIdCounter++;
        uint256 newUserId = _userIdCounter;
        UserRole userRole;

        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Talent"))) {
            userRole = UserRole.Talent;
        } else if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("Client"))) {
            userRole = UserRole.Client;
        } else {
            revert("Invalid user role specified");
        }

        _users[newUserId] = User({
            id: newUserId,
            wallet: msg.sender,
            name: _name,
            bio: "",
            role: userRole,
            reputationScore: 0,
            reputationStake: 0,
            lastReputationUnstake: 0,
            registered: true
        });
        _userWalletToId[msg.sender] = newUserId;

        emit UserRegistered(newUserId, msg.sender, userRole, _name);
    }

    /**
     * @dev Updates the profile information for the registered user.
     * @param _name The new name.
     * @param _bio The new bio.
     */
    function updateUserProfile(string calldata _name, string calldata _bio) public onlyRegisteredUser {
        uint256 userId = _userWalletToId[msg.sender];
        User storage user = _users[userId];
        require(bytes(_name).length > 0, "Name cannot be empty");

        user.name = _name;
        user.bio = _bio;

        emit UserProfileUpdated(userId, _name, _bio);
    }

    /**
     * @dev Allows a user to deposit native tokens into their platform balance.
     */
    function depositFunds() public payable onlyRegisteredUser {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value, _balances[msg.sender]);
    }

    /**
     * @dev Allows a user to withdraw native tokens from their platform balance.
     * @param _amount The amount to withdraw.
     */
    function withdrawFunds(uint256 _amount) public onlyRegisteredUser {
        require(_balances[msg.sender] >= _amount, "Insufficient balance");
        require(_amount > 0, "Withdrawal amount must be greater than 0");

        _balances[msg.sender] -= _amount;

        // Simple withdrawal for now, a queue/process could be implemented
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(msg.sender, _amount, _balances[msg.sender]);
    }

     /**
     * @dev Allows a user to stake native tokens for reputation.
     * @param _amount The amount to stake.
     * @dev Requires sending the stake amount with the transaction.
     */
    function stakeReputation(uint256 _amount) public payable onlyRegisteredUser {
        require(msg.value == _amount, "Sent amount must match stake amount");
        require(_amount > 0, "Stake amount must be greater than 0");

        uint256 userId = _userWalletToId[msg.sender];
        User storage user = _users[userId];

        user.reputationStake += _amount;
        // Simple reputation calculation: stake amount
        user.reputationScore += _amount; // Can be refined later

        emit ReputationStaked(userId, _amount, user.reputationStake);
    }

    /**
     * @dev Allows a user to unstake tokens from their reputation stake.
     * @param _amount The amount to unstake.
     */
    function unstakeReputation(uint256 _amount) public onlyRegisteredUser {
        uint256 userId = _userWalletToId[msg.sender];
        User storage user = _users[userId];

        require(user.reputationStake >= _amount, "Insufficient staked amount");
        require(_amount > 0, "Unstake amount must be greater than 0");
        require(block.timestamp >= user.lastReputationUnstake + reputationUnstakeCooldown, "Reputation unstake cooldown period active");

        user.reputationStake -= _amount;
        // Simple reputation calculation: decrease based on unstake
         user.reputationScore -= _amount; // Can be refined later
        user.lastReputationUnstake = block.timestamp;

        // Transfer unstaked amount back to user's platform balance (or wallet directly?)
        // Let's add to platform balance for simplicity
         _balances[msg.sender] += _amount;

        emit ReputationUnstaked(userId, _amount, user.reputationStake);
        emit FundsDeposited(msg.sender, _amount, _balances[msg.sender]); // Log as funds deposit for consistency
    }


    // --- Talent Offering Management (3 Functions + 3 Getters/Search) ---

    /**
     * @dev Allows a Talent to add a service offering.
     * @param _title The title of the offering.
     * @param _description The description of the offering.
     * @param _tags Keywords describing the skill/service.
     * @param _pricePerUnit The price per unit (e.g., per hour, per deliverable).
     */
    function addTalentOffering(string calldata _title, string calldata _description, string[] calldata _tags, uint256 _pricePerUnit) public onlyRole(UserRole.Talent) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_pricePerUnit > 0, "Price must be greater than 0");

        _talentOfferingIdCounter++;
        uint256 newOfferingId = _talentOfferingIdCounter;
        uint256 userId = _userWalletToId[msg.sender];

        _talentOfferings[newOfferingId] = TalentOffering({
            id: newOfferingId,
            userId: userId,
            title: _title,
            description: _description,
            tags: _tags,
            pricePerUnit: _pricePerUnit,
            isActive: true
        });

        _userTalentOfferings[userId].push(newOfferingId);
        for(uint i = 0; i < _tags.length; i++) {
            _talentOfferingsByTag[_tags[i]].push(newOfferingId);
        }

        emit TalentOfferingAdded(newOfferingId, userId, _title);
    }

    /**
     * @dev Allows a Talent to update an existing service offering.
     * @param _offeringId The ID of the offering to update.
     * @param _title The new title.
     * @param _description The new description.
     * @param _tags The new keywords.
     * @param _pricePerUnit The new price per unit.
     */
    function updateTalentOffering(uint256 _offeringId, string calldata _title, string calldata _description, string[] calldata _tags, uint256 _pricePerUnit) public onlyRole(UserRole.Talent) {
        TalentOffering storage offering = _talentOfferings[_offeringId];
        require(offering.userId == _userWalletToId[msg.sender], "Not your talent offering");
        require(offering.isActive, "Offering is not active");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_pricePerUnit > 0, "Price must be greater than 0");

        // Simple update - tags are replaced. Removing old tags from index requires iteration, let's skip for simplicity now.
        // In a real DApp, off-chain indexing or a more complex on-chain tag management would be needed.
        offering.title = _title;
        offering.description = _description;
        offering.tags = _tags;
        offering.pricePerUnit = _pricePerUnit;

        emit TalentOfferingUpdated(_offeringId, _title);
    }

    /**
     * @dev Allows a Talent to remove (deactivate) a service offering.
     * @param _offeringId The ID of the offering to remove.
     */
    function removeTalentOffering(uint256 _offeringId) public onlyRole(UserRole.Talent) {
        TalentOffering storage offering = _talentOfferings[_offeringId];
        require(offering.userId == _userWalletToId[msg.sender], "Not your talent offering");
        require(offering.isActive, "Offering is already inactive");

        offering.isActive = false;

        emit TalentOfferingRemoved(_offeringId);
    }


    // --- Gig Management (4 Functions + 3 Getters/Search) ---

    /**
     * @dev Allows a Client to post a new job gig.
     * @param _title The title of the gig.
     * @param _description The description of the work required.
     * @param _requiredSkills Keywords for required skills.
     * @param _budget The total budget for the gig (sent with the transaction).
     * @param _deadline The deadline for completion (Unix timestamp).
     */
    function postGig(string calldata _title, string calldata _description, string[] calldata _requiredSkills, uint256 _budget, uint256 _deadline) public payable onlyRole(UserRole.Client) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(msg.value >= _budget, "Sent amount must match the gig budget");
        require(_budget > 0, "Budget must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        _gigIdCounter++;
        uint256 newGigId = _gigIdCounter;
        uint256 clientId = _userWalletToId[msg.sender];

        _gigs[newGigId] = Gig({
            id: newGigId,
            clientId: clientId,
            title: _title,
            description: _description,
            requiredSkills: _requiredSkills,
            budget: _budget, // Held in contract escrow
            deadline: _deadline,
            status: GigStatus.Open,
            assignedTalentId: 0,
            createdAt: block.timestamp
        });

        _clientGigs[clientId].push(newGigId);
        for(uint i = 0; i < _requiredSkills.length; i++) {
            _gigsBySkill[_requiredSkills[i]].push(newGigId);
        }

        emit GigPosted(newGigId, clientId, _title, _budget);
    }

    /**
     * @dev Allows a Client to update an open gig.
     * @param _gigId The ID of the gig to update.
     * @param _description The new description.
     * @param _deadline The new deadline.
     */
    function updateGig(uint256 _gigId, string calldata _description, uint256 _deadline) public onlyGigClient(_gigId) {
        Gig storage gig = _gigs[_gigId];
        require(gig.status == GigStatus.Open, "Gig is not open");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        gig.description = _description;
        gig.deadline = _deadline;

        emit GigUpdated(_gigId, _deadline);
    }

    /**
     * @dev Allows a Client to cancel an open gig.
     * @param _gigId The ID of the gig to cancel.
     */
    function cancelGig(uint256 _gigId) public onlyGigClient(_gigId) {
        Gig storage gig = _gigs[_gigId];
        require(gig.status == GigStatus.Open, "Gig is not open");

        gig.status = GigStatus.Cancelled;

        // Refund the budget to the client
        uint256 refundAmount = gig.budget;
         (bool success,) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Refund failed");

        emit GigCancelled(_gigId, gig.clientId, refundAmount);
    }

    /**
     * @dev Allows the assigned Talent or the Client to mark a gig as completed.
     * @param _gigId The ID of the gig to close.
     */
    function closeGig(uint256 _gigId) public onlyGigParticipant(_gigId) {
        Gig storage gig = _gigs[_gigId];
        require(gig.status == GigStatus.InProgress, "Gig is not in progress");
        require(gig.assignedTalentId != 0, "Gig has no assigned talent");

        // Check if deadline passed - could auto-close or require resolution
        // For simplicity, allow closing even after deadline by participant

        gig.status = GigStatus.Completed;

        // Calculate platform fee and talent payout
        uint256 platformFee = (gig.budget * platformFeeRate) / 1000; // platformFeeRate is stored as rate * 100
        uint256 talentPayout = gig.budget - platformFee;

        address talentWallet = _users[gig.assignedTalentId].wallet;

        // Transfer funds to platform owner (fee) and talent
        (bool feeSuccess,) = payable(platformOwner).call{value: platformFee}("");
        require(feeSuccess, "Fee transfer failed");

        (bool payoutSuccess,) = payable(talentWallet).call{value: talentPayout}("");
        require(payoutSuccess, "Talent payout failed");

        emit GigCompleted(_gigId, gig.assignedTalentId, talentPayout, platformFee);
    }


    // --- Proposal Management (4 Functions + 2 Getters) ---

    /**
     * @dev Allows a Talent to submit a proposal for an open gig.
     * @param _gigId The ID of the gig to propose on.
     * @param _proposedPrice The Talent's proposed price.
     * @param _proposedTimeline The Talent's proposed timeline (e.g., in days).
     * @param _message A message from the Talent to the Client.
     * @dev Requires sending the proposalStakeAmount with the transaction.
     */
    function submitProposal(uint256 _gigId, uint256 _proposedPrice, uint256 _proposedTimeline, string calldata _message) public payable onlyRole(UserRole.Talent) {
        Gig storage gig = _gigs[_gigId];
        require(gig.status == GigStatus.Open, "Gig is not open for proposals");
        require(_proposedPrice > 0, "Proposed price must be greater than 0");
        require(_proposedTimeline > 0, "Proposed timeline must be greater than 0");
        require(msg.value == proposalStakeAmount, "Must send required proposal stake");

        _proposalIdCounter++;
        uint256 newProposalId = _proposalIdCounter;
        uint256 talentId = _userWalletToId[msg.sender];

        _proposals[newProposalId] = Proposal({
            id: newProposalId,
            gigId: _gigId,
            talentId: talentId,
            proposedPrice: _proposedPrice,
            proposedTimeline: _proposedTimeline,
            message: _message,
            status: ProposalStatus.Submitted,
            stake: msg.value,
            createdAt: block.timestamp
        });

        _gigProposals[_gigId].push(newProposalId);
        _talentProposals[talentId].push(newProposalId);

        emit ProposalSubmitted(newProposalId, _gigId, talentId);
    }

    /**
     * @dev Allows a Talent to withdraw their submitted proposal.
     * @param _proposalId The ID of the proposal to withdraw.
     */
    function withdrawProposal(uint256 _proposalId) public onlyRole(UserRole.Talent) {
        Proposal storage proposal = _proposals[_proposalId];
        require(proposal.talentId == _userWalletToId[msg.sender], "Not your proposal");
        require(proposal.status == ProposalStatus.Submitted, "Proposal cannot be withdrawn");

        proposal.status = ProposalStatus.Withdrawn;

        // Refund proposal stake to user's balance
        _balances[msg.sender] += proposal.stake;

        emit ProposalWithdrawn(_proposalId);
    }

    /**
     * @dev Allows a Client to accept a proposal for their gig.
     * @param _proposalId The ID of the proposal to accept.
     */
    function acceptProposal(uint256 _proposalId) public onlyRole(UserRole.Client) {
        Proposal storage proposal = _proposals[_proposalId];
        Gig storage gig = _gigs[proposal.gigId];

        require(gig.clientId == _userWalletToId[msg.sender], "Not your gig");
        require(gig.status == GigStatus.Open, "Gig is not open for accepting proposals");
        require(proposal.status == ProposalStatus.Submitted, "Proposal is not in a submitted state");

        // Mark proposal as accepted
        proposal.status = ProposalStatus.Accepted;

        // Assign talent to the gig
        gig.assignedTalentId = proposal.talentId;
        gig.status = GigStatus.InProgress;

        // Refund stakes of all other proposals for this gig (optional, could keep stake)
        // For simplicity, let's *not* refund stakes automatically here. Talent needs to withdraw.
        // A DApp front-end could list non-accepted proposals for withdrawal.

        emit ProposalAccepted(_proposalId, proposal.gigId);
        emit GigInProgress(proposal.gigId, proposal.talentId);
    }

    /**
     * @dev Allows a Client to reject a submitted proposal.
     * @param _proposalId The ID of the proposal to reject.
     */
    function rejectProposal(uint256 _proposalId) public onlyRole(UserRole.Client) {
        Proposal storage proposal = _proposals[_proposalId];
        Gig storage gig = _gigs[proposal.gigId];

        require(gig.clientId == _userWalletToId[msg.sender], "Not your gig");
        require(gig.status == GigStatus.Open, "Gig is not open");
        require(proposal.status == ProposalStatus.Submitted, "Proposal is not in a submitted state");

        proposal.status = ProposalStatus.Rejected;
        // Stake remains in the contract, can be withdrawn by talent later using withdrawProposal

        emit ProposalRejected(_proposalId);
    }


    // --- Dispute Resolution (3 Functions + 1 Getter) ---

    /**
     * @dev Allows a Gig participant (Client or Talent) to file a dispute.
     * @param _gigId The ID of the gig to dispute.
     * @param _reason The reason for filing the dispute.
     * @dev Requires sending the disputeStakeAmount with the transaction.
     */
    function fileDispute(uint256 _gigId, string calldata _reason) public payable onlyGigParticipant(_gigId) {
        Gig storage gig = _gigs[_gigId];
        require(gig.status == GigStatus.InProgress || gig.status == GigStatus.Completed, "Gig must be in progress or completed to file a dispute");
        require(_gigDispute[_gigId] == 0, "A dispute already exists for this gig");
        require(msg.value == disputeStakeAmount, "Must send required dispute stake");
        require(bytes(_reason).length > 0, "Reason cannot be empty");

        _disputeIdCounter++;
        uint256 newDisputeId = _disputeIdCounter;
        uint256 filerId = _userWalletToId[msg.sender];
        uint256 counterpartyId;

        if (filerId == gig.clientId) {
            counterpartyId = gig.assignedTalentId;
        } else { // filerId must be assignedTalentId because of onlyGigParticipant
            counterpartyId = gig.clientId;
        }
        require(counterpartyId != 0, "Counterparty must be assigned");


        _disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            gigId: _gigId,
            filerId: filerId,
            counterpartyId: counterpartyId,
            reason: _reason,
            evidenceHashes: new mapping(uint256 => string[]), // Initialize the mapping
            status: DisputeStatus.Open, // Starts in Open/Evidence Submission
            stake: msg.value,
            filingTime: block.timestamp,
            votingEnds: 0, // Set when moving to voting
            resolutionGovernanceProposalId: 0
        });

        // Participants should also stake the dispute amount
        // For simplicity, require filer to stake here. Counterparty might need to stake to participate.
        // A more complex system would manage stakes from both sides.

        _gigDispute[_gigId] = newDisputeId;
        gig.status = GigStatus.Disputed; // Change gig status

        emit DisputeFiled(newDisputeId, _gigId, filerId, _reason);

        // Automatically transition to Evidence Submission period
        _disputes[newDisputeId].status = DisputeStatus.EvidenceSubmission;
        // No event for state change within a function, implicitly covered by DisputeFiled
    }

    /**
     * @dev Allows a participant in a dispute to submit evidence hash(es).
     * @param _disputeId The ID of the dispute.
     * @param _evidenceHash A hash pointing to off-chain evidence data (e.g., IPFS hash).
     */
    function submitDisputeEvidence(uint256 _disputeId, string calldata _evidenceHash) public onlyDisputeParticipant(_disputeId) {
        Dispute storage dispute = _disputes[_disputeId];
        require(dispute.status == DisputeStatus.EvidenceSubmission, "Dispute is not in evidence submission phase");
        require(block.timestamp < dispute.filingTime + evidenceSubmissionPeriod, "Evidence submission period has ended");
        require(bytes(_evidenceHash).length > 0, "Evidence hash cannot be empty");

        uint256 userId = _userWalletToId[msg.sender];
        dispute.evidenceHashes[userId].push(_evidenceHash);

        emit DisputeEvidenceSubmitted(_disputeId, userId, _evidenceHash);
    }

    /**
     * @dev Internal/DAO function to resolve a dispute based on a governance proposal outcome.
     * @param _disputeId The ID of the dispute.
     * @param _outcome The determined outcome of the dispute.
     * @param _governanceProposalId The ID of the governance proposal that determined the outcome.
     */
    function _resolveDispute(uint256 _disputeId, DisputeOutcome _outcome, uint256 _governanceProposalId) internal {
        Dispute storage dispute = _disputes[_disputeId];
        Gig storage gig = _gigs[dispute.gigId];

        require(dispute.status == DisputeStatus.Voting, "Dispute is not in voting phase"); // Should be called after voting ends

        dispute.status = DisputeStatus.Resolved;
        dispute.resolutionGovernanceProposalId = _governanceProposalId;

        uint256 totalStake = dispute.stake * 2; // Assuming both parties staked

        uint256 clientUserId = gig.clientId;
        uint256 talentUserId = gig.assignedTalentId;
        address clientWallet = _users[clientUserId].wallet;
        address talentWallet = _users[talentUserId].wallet;

        if (_outcome == DisputeOutcome.FavorClient) {
             // Refund client stake, penalize talent stake + gig budget to client
             // A simpler model: winner gets stake back, loser stake + budget distributed per outcome
             // Let's say: winner gets stake back, budget goes based on outcome.
             // Penalized stake goes to DAO or burned. For simplicity, DAO (platformOwner).

            // Refund Client Stake
             (bool clientStakeSuccess,) = payable(clientWallet).call{value: dispute.stake}("");
             require(clientStakeSuccess, "Client stake refund failed");

            // Budget and Talent Stake goes to Client
            uint256 payoutToClient = gig.budget + dispute.stake;
            (bool budgetSuccess,) = payable(clientWallet).call{value: payoutToClient}("");
            require(budgetSuccess, "Client payout failed");

        } else if (_outcome == DisputeOutcome.FavorTalent) {
             // Refund Talent Stake
            (bool talentStakeSuccess,) = payable(talentWallet).call{value: dispute.stake}("");
            require(talentStakeSuccess, "Talent stake refund failed");

            // Budget and Client Stake goes to Talent
            uint256 payoutToTalent = gig.budget + dispute.stake;
             (bool budgetSuccess,) = payable(talentWallet).call{value: payoutToTalent}("");
            require(budgetSuccess, "Talent payout failed");

        } else if (_outcome == DisputeOutcome.Split) {
             // Refund both stakes
            (bool clientStakeSuccess,) = payable(clientWallet).call{value: dispute.stake}("");
             require(clientStakeSuccess, "Client stake refund failed");
             (bool talentStakeSuccess,) = payable(talentWallet).call{value: dispute.stake}("");
            require(talentStakeSuccess, "Talent stake refund failed");

             // Split budget (e.g., 50/50) - could be proportional to complexity of work done etc.
             // For simplicity, let's split budget 50/50
             uint256 halfBudget = gig.budget / 2;
             (bool clientBudgetSuccess,) = payable(clientWallet).call{value: halfBudget}("");
             require(clientBudgetSuccess, "Client split payout failed");
             (bool talentBudgetSuccess,) = payable(talentWallet).call{value: halfBudget}("");
             require(talentBudgetSuccess, "Talent split payout failed");

        }
        // Note: The platform fee logic for resolved disputes is more complex.
        // Here, we're assuming the budget is fully distributed per outcome, and stakes refunded or forfeited.
        // A real system might take a fee on the distributed amount or forfeited stakes.

        gig.status = GigStatus.Completed; // Mark gig as resolved/completed (could have a separate Resolved status)

        emit DisputeResolved(_disputeId, dispute.status, _outcome, _governanceProposalId);
        // Funds transfer events are emitted by the calls within this function
    }

    // Helper to move dispute to voting phase - could be triggered automatically after evidence period
    function _startDisputeVoting(uint256 _disputeId) internal {
         Dispute storage dispute = _disputes[_disputeId];
         require(dispute.status == DisputeStatus.EvidenceSubmission, "Dispute not in evidence submission phase");
         // require(block.timestamp >= dispute.filingTime + evidenceSubmissionPeriod, "Evidence submission period not over"); // Ensure evidence time is up

         dispute.status = DisputeStatus.Voting;
         dispute.votingEnds = block.timestamp + votingPeriod;

         // Create a governance proposal specifically for resolving this dispute
         bytes memory proposalData = abi.encode(DisputeOutcome.FavorClient, DisputeOutcome.FavorTalent, DisputeOutcome.Split); // Options for the vote
         createGovernanceProposal("Dispute Resolution", _disputeId, proposalData); // Example: DAO votes on the outcome
    }


    // --- Governance (5 Functions + 2 Getters) ---

    /**
     * @dev Allows a registered user with sufficient reputation to create a governance proposal.
     * @param _description A description of the proposal.
     * @param _linkedDisputeId If this proposal is for a dispute resolution, link it here (0 otherwise).
     * @param _proposalData Data relevant to the proposal execution (e.g., new parameter values, dispute outcome).
     * @dev Requires sending a stake amount with the transaction.
     */
    function createGovernanceProposal(string calldata _description, uint256 _linkedDisputeId, bytes calldata _proposalData) public payable onlyRegisteredUser {
        uint256 creatorId = _userWalletToId[msg.sender];
        // require(_users[creatorId].reputationScore >= minReputationStake, "Insufficient reputation stake to create proposal"); // Optional reputation check

        require(msg.value >= minReputationStake, "Must send required proposal creation stake");
        require(bytes(_description).length > 0, "Description cannot be empty");

        _governanceProposalIdCounter++;
        uint256 newProposalId = _governanceProposalIdCounter;

        _governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            creatorId: creatorId,
            description: _description,
            proposalData: _proposalData,
            linkedDisputeId: _linkedDisputeId,
            votes: new mapping(uint256 => bool),
            hasVoted: new mapping(uint256 => bool),
            totalSupportVotes: 0,
            totalAgainstVotes: 0,
            status: GovernanceProposalStatus.Open,
            creationTime: block.timestamp,
            votingEnds: block.timestamp + votingPeriod, // Set voting period
            stake: msg.value
        });

        _activeGovernanceProposals.push(newProposalId);

        if (_linkedDisputeId != 0) {
            require(_disputes[_linkedDisputeId].status == DisputeStatus.EvidenceSubmission || _disputes[_linkedDisputeId].status == DisputeStatus.Voting, "Linked dispute not in a state to receive a resolution proposal");
             _disputes[_linkedDisputeId].status = DisputeStatus.Voting; // Move dispute to voting if not already
             _disputes[_linkedDisputeId].votingEnds = _governanceProposals[newProposalId].votingEnds; // Sync voting end
             _disputes[_linkedDisputeId].resolutionGovernanceProposalId = newProposalId; // Link the proposal
        }


        emit GovernanceProposalCreated(newProposalId, creatorId, _description);
    }

    /**
     * @dev Allows a registered user with reputation to vote on an open governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, False for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegisteredUser {
        GovernanceProposal storage proposal = _governanceProposals[_proposalId];
        uint256 userId = _userWalletToId[msg.sender];

        require(proposal.status == GovernanceProposalStatus.Open, "Proposal is not open for voting");
        require(block.timestamp < proposal.votingEnds, "Voting period has ended");
        require(!proposal.hasVoted[userId], "User has already voted on this proposal");
        // require(_users[userId].reputationScore > 0, "User must have reputation to vote"); // Require reputation to vote

        proposal.votes[userId] = _support;
        proposal.hasVoted[userId] = true;

        // Voting weight based on reputation stake (simple: 1 token stake = 1 vote weight)
        uint256 voteWeight = _users[userId].reputationStake;
         if (voteWeight == 0 && _users[userId].reputationScore > 0) {
             // Fallback for basic reputation score if stake is 0
             voteWeight = _users[userId].reputationScore;
         }
         require(voteWeight > 0, "User must have reputation to vote");


        if (_support) {
            proposal.totalSupportVotes += voteWeight;
        } else {
            proposal.totalAgainstVotes += voteWeight;
        }

        emit VotedOnProposal(_proposalId, userId, _support);
    }

    /**
     * @dev Allows the platform owner (or potentially a DAO contract) to execute a passed proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public { // Could be `onlyOwner` or `onlyDAOContract`
        // Using onlyOwner for simplicity, but ideally this would be callable by a DAO execution module
        require(msg.sender == platformOwner, "Only platform owner can execute proposals"); // Simple access control

        GovernanceProposal storage proposal = _governanceProposals[_proposalId];
        require(proposal.status == GovernanceProposalStatus.Open, "Proposal is not in open status");
        require(block.timestamp >= proposal.votingEnds, "Voting period has not ended");

        // Determine outcome (simple majority based on reputation stake weight)
        bool passed = proposal.totalSupportVotes > proposal.totalAgainstVotes;

        if (passed) {
            proposal.status = GovernanceProposalStatus.Approved; // Temporarily mark as approved

            // Execute the proposal logic based on _proposalData and linkedDisputeId
            if (proposal.linkedDisputeId != 0) {
                // Execute dispute resolution
                DisputeOutcome outcome = abi.decode(proposal.proposalData, (DisputeOutcome)); // Assuming outcome is encoded
                _resolveDispute(proposal.linkedDisputeId, outcome, _proposalId);

            } else {
                // Handle other proposal types (e.g., changing parameters)
                // This would require decoding specific proposalData structures
                // For this example, let's just mark it as executed without complex logic.
                 proposal.status = GovernanceProposalStatus.Executed;
            }

            // Refund proposal stake to creator's balance
            _balances[_users[proposal.creatorId].wallet] += proposal.stake;


        } else {
            proposal.status = GovernanceProposalStatus.Rejected;
            // Stake is not refunded on rejection (discourages frivolous proposals)
        }

         // Remove from active list (simple removal, not gas efficient for large arrays)
         for (uint i = 0; i < _activeGovernanceProposals.length; i++) {
             if (_activeGovernanceProposals[i] == _proposalId) {
                 _activeGovernanceProposals[i] = _activeGovernanceProposals[_activeGovernanceProposals.length - 1];
                 _activeGovernanceProposals.pop();
                 break;
             }
         }


        emit ProposalExecuted(_proposalId, proposal.status);
    }


    // --- Getters & Search (Lots of these) ---

    /**
     * @dev Gets the profile details for a user.
     * @param _user The address of the user.
     * @return User struct.
     */
    function getUserProfile(address _user) public view returns (User memory) {
        uint256 userId = _userWalletToId[_user];
        require(userId != 0, "User not registered");
        return _users[userId];
    }

    /**
     * @dev Gets the details of a specific talent offering.
     * @param _offeringId The ID of the talent offering.
     * @return TalentOffering struct.
     */
    function getTalentOffering(uint256 _offeringId) public view returns (TalentOffering memory) {
        require(_talentOfferings[_offeringId].id != 0, "Talent offering not found");
        return _talentOfferings[_offeringId];
    }

    /**
     * @dev Gets the IDs of all talent offerings by a specific user.
     * @param _user The address of the user.
     * @return Array of talent offering IDs.
     */
    function getTalentOfferingsByUser(address _user) public view returns (uint256[] memory) {
        uint256 userId = _userWalletToId[_user];
        require(userId != 0, "User not registered");
        return _userTalentOfferings[userId];
    }

    /**
     * @dev Gets the details of a specific gig.
     * @param _gigId The ID of the gig.
     * @return Gig struct.
     */
    function getGigDetails(uint256 _gigId) public view returns (Gig memory) {
        require(_gigs[_gigId].id != 0, "Gig not found");
        return _gigs[_gigId];
    }

     /**
     * @dev Gets the IDs of all gigs posted by a specific client.
     * @param _user The address of the client.
     * @return Array of gig IDs.
     */
    function getGigsPostedByClient(address _user) public view returns (uint256[] memory) {
        uint256 userId = _userWalletToId[_user];
        require(userId != 0, "User not registered");
        return _clientGigs[userId];
    }

    /**
     * @dev Gets the details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
        require(_proposals[_proposalId].id != 0, "Proposal not found");
        return _proposals[_proposalId];
    }

    /**
     * @dev Gets the IDs of all proposals submitted for a specific gig.
     * @param _gigId The ID of the gig.
     * @return Array of proposal IDs.
     */
    function getProposalsForGig(uint256 _gigId) public view returns (uint256[] memory) {
         require(_gigs[_gigId].id != 0, "Gig not found");
        return _gigProposals[_gigId];
    }

     /**
     * @dev Gets the IDs of all proposals submitted by a specific talent.
     * @param _user The address of the talent.
     * @return Array of proposal IDs.
     */
    function getProposalsSubmittedByTalent(address _user) public view returns (uint256[] memory) {
        uint256 userId = _userWalletToId[_user];
        require(userId != 0, "User not registered");
        return _talentProposals[userId];
    }

     /**
     * @dev Gets the details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return Dispute struct.
     */
    function getDisputeDetails(uint256 _disputeId) public view returns (Dispute memory) {
        require(_disputes[_disputeId].id != 0, "Dispute not found");
        // Note: Retrieving the evidenceHashes mapping directly in Solidity return is complex.
        // A separate function or event logging should be used to access all evidence.
        // This getter returns the struct *without* the nested mapping content directly.
        // DApps would need to query evidence per user ID.
         Dispute memory dispute = _disputes[_disputeId];
         // Clear the mapping part before returning as mappings cannot be returned directly
         // This is a simplification. Proper access requires a helper function.
         // delete dispute.evidenceHashes; // This line is invalid syntax
         // Need to return it as is and the DApp accesses evidenceHashes[userId] separately

        return dispute; // Returns struct, DApp calls getDisputeEvidenceHashes
    }

    /**
     * @dev Gets the evidence hashes submitted by a specific participant in a dispute.
     * @param _disputeId The ID of the dispute.
     * @param _user The address of the participant.
     * @return Array of evidence hash strings.
     */
    function getDisputeEvidenceHashes(uint256 _disputeId, address _user) public view returns (string[] memory) {
         uint256 userId = _userWalletToId[_user];
         require(_disputes[_disputeId].id != 0, "Dispute not found");
         // Ensure the user is actually a participant if needed, though mapping lookup is safe
         return _disputes[_disputeId].evidenceHashes[userId];
    }


     /**
     * @dev Gets the details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return GovernanceProposal struct.
     */
    function getGovernanceProposal(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        require(_governanceProposals[_proposalId].id != 0, "Governance proposal not found");
         // Similar to Dispute, votes/hasVoted mappings cannot be returned directly.
         // Need helper functions or access via DApp.
         GovernanceProposal memory proposal = _governanceProposals[_proposalId];
         // Clear mapping parts for return safety/compatibility
         // delete proposal.votes; // Invalid syntax
         // delete proposal.hasVoted; // Invalid syntax
        return proposal; // Returns struct, DApp accesses votes/hasVoted via helpers
    }

     /**
     * @dev Gets the current balance of a user within the contract.
     * @param _user The address of the user.
     * @return The user's balance.
     */
    function getPlatformBalance(address _user) public view returns (uint256) {
        return _balances[_user];
    }

     /**
     * @dev Gets the IDs of talent offerings matching a specific skill tag (simple listing).
     * @param _skillTag The skill tag to search for.
     * @return Array of matching talent offering IDs.
     */
    function searchTalentBySkill(string calldata _skillTag) public view returns (uint256[] memory) {
        return _talentOfferingsByTag[_skillTag]; // Returns list of IDs, DApp fetches details
    }

    /**
     * @dev Gets the IDs of gigs matching a specific required skill tag (simple listing).
     * @param _skillTag The skill tag to search for.
     * @return Array of matching gig IDs.
     */
    function searchGigsBySkill(string calldata _skillTag) public view returns (uint256[] memory) {
         return _gigsBySkill[_skillTag]; // Returns list of IDs, DApp fetches details
    }

    /**
     * @dev Calculates or retrieves the user's reputation score.
     * @param _user The address of the user.
     * @return The user's current reputation score.
     */
    function calculateReputation(address _user) public view onlyRegisteredUser returns (uint256) {
        uint256 userId = _userWalletToId[_user];
        // More complex reputation could include completed gigs, positive reviews (off-chain hashes?), dispute outcomes etc.
        // For now, it's tied directly to stake + a base score.
        return _users[userId].reputationScore; // Currently directly reflects stake + initial
    }

     /**
     * @dev Gets the amount of tokens a user has staked for reputation.
     * @param _user The address of the user.
     * @return The amount staked.
     */
    function getReputationStake(address _user) public view onlyRegisteredUser returns (uint256) {
        uint256 userId = _userWalletToId[_user];
        return _users[userId].reputationStake;
    }

    // Helper to manually transition dispute to voting (for testing/manual trigger)
    // In a real system, this would be triggered automatically after evidencePeriod
    function startDisputeVoting(uint256 _disputeId) public onlyOwner { // Restricted access
         _startDisputeVoting(_disputeId);
    }

     // Helper to manually execute dispute resolution (for testing/manual trigger)
     // In a real system, this would be part of executeProposal logic based on voting outcome
     function executeDisputeResolutionManual(uint256 _disputeId, DisputeOutcome _outcome) public onlyOwner {
         Dispute storage dispute = _disputes[_disputeId];
         require(dispute.status == DisputeStatus.Voting || dispute.status == DisputeStatus.EvidenceSubmission, "Dispute not in a state to be manually resolved");
         // Simulate a resolution proposal ID if none exists
         if (dispute.resolutionGovernanceProposalId == 0) {
              _governanceProposalIdCounter++;
             dispute.resolutionGovernanceProposalId = _governanceProposalIdCounter; // Use a dummy ID
             // Create a basic placeholder proposal
             _governanceProposals[dispute.resolutionGovernanceProposalId] = GovernanceProposal({
                id: dispute.resolutionGovernanceProposalId,
                creatorId: _userWalletToId[msg.sender], // Owner as creator
                description: "Manual Dispute Resolution",
                proposalData: abi.encode(_outcome),
                linkedDisputeId: _disputeId,
                 votes: new mapping(uint256 => bool),
                 hasVoted: new mapping(uint256 => bool),
                 totalSupportVotes: 1, // Assume success for manual execution
                 totalAgainstVotes: 0,
                status: GovernanceProposalStatus.Approved,
                creationTime: block.timestamp,
                votingEnds: block.timestamp,
                stake: 0
             });
         }
         _resolveDispute(_disputeId, _outcome, dispute.resolutionGovernanceProposalId);
     }

     // --- Owner/Platform Functions ---
     // Example: Function to withdraw collected platform fees
     function withdrawPlatformFees() public {
         require(msg.sender == platformOwner, "Only platform owner can withdraw fees");
         uint256 balance = address(this).balance;
         // Need to track what portion is fees vs escrow/stakes
         // This is a simplified withdrawal assuming all current balance *except* active escrow/stakes is fees
         // In a real system, you'd track fees explicitly or manage liquidity carefully.
         // This simple example only withdraws fees collected directly in closeGig.
         // A proper fee withdrawal function would need to track accumulated fees.
         // Let's assume platformOwner receives fees directly in closeGig for now.
         // A dedicated fee pool and withdrawal logic would be needed.

         // Placeholder: A real system would have a dedicated variable for collected fees.
         // For this example, fees are transferred directly to platformOwner in closeGig, so no need to withdraw from contract balance unless other fees exist.
         // Let's add a function to transfer any excess ETH if needed (dangerous, for dev/cleanup only)
         // function rescueETH(uint256 amount) public onlyOwner { (bool success,) = payable(owner).call{value: amount}(""); require(success, "Transfer failed"); }
         revert("Platform fees are sent directly to the owner on gig completion in this version.");
     }

      modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only owner");
        _;
    }
}
```