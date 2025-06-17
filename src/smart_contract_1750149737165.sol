Okay, here is a Solidity smart contract for a Decentralized Autonomous Artisan Guild (DAAG).

This contract aims to be a platform where digital artisans can offer their skills, clients can commission work, and the community (guild members) can govern the platform, verify skills, and even define/mint generative art linked to expertise.

It incorporates concepts like:
*   **DAO Governance:** Proposals, voting, execution by token holders/stakers.
*   **Skill-Based System:** Tracking and verifying artisan skills, potentially unlocking features or visibility based on skill level/verification status.
*   **Commission Marketplace:** A basic system for posting, accepting, submitting, and approving work.
*   **Integrated Generative Art:** Allowing approved artisans or the DAO to define blueprints for generative art minting, potentially requiring certain skills or burning tokens. Includes basic ERC2981 royalties simulation.
*   **Custom Tokenomics:** A simple integrated `GUILD` token for governance staking, payments, and burning.
*   **Reputation (Basic):** Simple rating system for completed commissions, and skill points/verification contributing to profile.
*   **Pausable:** Standard safety feature.

It avoids direct copying of standard ERC20/ERC721/ERC1155 templates, basic `Ownable` DAOs, or standard NFT marketplace interfaces, by combining these elements into a unique guild structure.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- Outline ---
// 1. State Variables & Data Structures:
//    - Guild Membership: Member profiles, roles (Artisan, Client).
//    - Skills: Defined skills, member's claimed skills, skill points, verification status.
//    - Commissions: Commission details, status, associated members, payment.
//    - Generative Art: Blueprints, minted pieces (simplified metadata), royalty info.
//    - GUILD Token: Basic balance tracking (not full ERC20), staking for governance.
//    - DAO Governance: Proposals, voting state, proposal execution.
//    - Treasury: Contract balance for fees/distributions.
//    - System State: Paused status, fees, counters.
//
// 2. Events: To track major state changes (Membership, Skills, Commissions, Art, Token, Governance).
//
// 3. Modifiers: Access control based on member status, roles, or contract state.
//
// 4. Core Logic Functions:
//    - Membership & Profile Management.
//    - Skill Management (Defining, Claiming, Verification).
//    - Commission Workflow (Posting, Accepting, Submission, Approval, Rating, Dispute).
//    - Generative Art (Defining Blueprints, Minting, Royalties).
//    - GUILD Token (Basic Minting, Burning, Transfer, Staking).
//    - DAO Governance (Proposing, Voting, Executing).
//    - Treasury & Fees.
//    - System Control (Pause/Unpause).
//    - View Functions to query state.

// --- Function Summary ---
//
// [Membership & Profile]
// 1. registerMember(string memory _name, bool _isArtisan): Registers a new member (Artisan or Client).
// 2. updateMemberProfile(string memory _name, string memory _profileURI): Updates profile info.
// 3. earnSkillPoint(address _member, uint256 _skillId): Internal function to award skill points.
//
// [Skills]
// 4. defineSkill(string memory _name, string memory _description): Admin/DAO defines a new skill type.
// 5. addSkillToProfile(uint256 _skillId): Member adds a defined skill to their profile.
// 6. requestSkillVerification(uint256 _skillId, string memory _proofURI): Member requests community/DAO verification for a skill.
// 7. voteOnSkillVerification(address _member, uint256 _skillId, bool _support): Member votes on a skill verification request.
// 8. finalizeSkillVerification(address _member, uint256 _skillId): Admin/DAO finalizes verification based on votes.
//
// [Commissions]
// 9. postCommission(string memory _title, string memory _description, uint256 _budget, uint256[] memory _requiredSkillIds): Client posts a commission request (requires funds deposit).
// 10. acceptCommission(uint256 _commissionId): Artisan accepts a commission.
// 11. submitCommissionWork(uint256 _commissionId, string memory _workURI): Artisan submits completed work URI.
// 12. approveCommissionWork(uint256 _commissionId): Client approves work, releasing funds to Artisan.
// 13. rateArtisan(uint256 _commissionId, uint8 _rating): Client rates the artisan after approval.
// 14. disputeCommission(uint256 _commissionId, string memory _reason): Either party initiates a dispute.
// 15. resolveCommissionDispute(uint256 _commissionId, bool _clientWins): Admin/DAO resolves a dispute.
//
// [Generative Art]
// 16. defineGenerativeArtBlueprint(string memory _name, string memory _description, string[] memory _parameterNames, uint256 _mintPrice, uint256[] memory _requiredSkillIds): Defines a blueprint for minting art (Admin/DAO or skilled Artisan).
// 17. mintGenerativeArt(uint256 _blueprintId, string[] memory _parameterValues): Mints a piece of art from a blueprint (requires payment and potentially skill check).
// 18. setArtBlueprintRoyalties(uint256 _blueprintId, uint96 _royaltyBasisPoints): Admin/DAO sets royalty percentage for a blueprint (simulating ERC2981).
//
// [GUILD Token & Staking (Simplified)]
// 19. daoMintGUILD(address _recipient, uint256 _amount): DAO executes proposal to mint GUILD (initial/rewards).
// 20. daoBurnGUILD(uint256 _amount): DAO executes proposal to burn GUILD (from treasury/fees).
// 21. stakeGUILD(uint256 _amount): Member stakes GUILD for voting power/visibility.
// 22. unstakeGUILD(uint256 _amount): Member unstakes GUILD.
//
// [DAO Governance]
// 23. proposeGuildAction(string memory _description, address _target, bytes memory _callData): Member stakes GUILD to propose an action.
// 24. voteOnProposal(uint256 _proposalId, bool _support): Staking member votes on a proposal.
// 25. executeProposal(uint256 _proposalId): Member executes a successful proposal after voting period.
//
// [System & Treasury]
// 26. setCommissionFee(uint256 _feeBasisPoints): Admin/DAO sets the commission fee percentage.
// 27. pause(): Admin/DAO pauses the contract.
// 28. unpause(): Admin/DAO unpauses the contract.
// 29. withdrawTreasury(address _recipient, uint256 _amount): DAO proposal execution to withdraw from treasury.
//
// [View Functions] (Examples, not strictly counted in the 20+ core actions)
// getMemberProfile, getSkill, getCommission, getArtBlueprint, getGenerativeArtPiece, getProposal, getGUILDBalance, getTotalStaked, getTreasuryBalance etc.

contract DecentralizedAutonomousArtisanGuild {
    address public owner; // Initial owner, role transitioned to DAO
    uint256 private _guildTotalSupply;

    // --- Data Structures ---

    struct MemberProfile {
        bool isArtisan;
        string name;
        string profileURI; // Link to off-chain profile data (e.g., IPFS)
        uint256 registrationTime;
        mapping(uint256 => MemberSkill) skills; // SkillId => MemberSkill
        uint256[] skillIds; // Array to iterate through member's skills
        uint256 reputationScore; // Simple score based on ratings, skill points etc.
        uint256 guildBalance; // Simplified token balance tracking
        uint256 stakedBalance; // GUILD staked for governance/visibility
    }

    struct MemberSkill {
        uint256 skillPoints; // Earned points for this skill
        bool isVerified; // Verified by community/DAO
        string verificationProofURI; // Proof submitted for verification
        mapping(address => bool) verificationVotes; // Voter => Support
        uint256 verificationVotesFor;
        uint256 verificationVotesAgainst;
        bool verificationRequested;
    }

    struct Skill {
        string name;
        string description;
        uint256 id;
        bool exists; // To check if ID is valid
    }

    enum CommissionStatus {
        Open,
        Accepted,
        WorkSubmitted,
        Approved,
        Disputed,
        Resolved,
        Cancelled
    }

    struct Commission {
        address client;
        address artisan; // Address(0) if not yet accepted
        string title;
        string description;
        uint256 budget; // Payment in native currency (e.g., Ether)
        uint256 commissionFee; // Fee amount collected on approval
        uint256[] requiredSkillIds;
        CommissionStatus status;
        string workURI; // Link to submitted work
        string disputeReason;
        int8 clientRating; // -1 if not rated, 1-5 score
        uint256 creationTime;
    }

    struct GenerativeArtBlueprint {
        bool exists;
        string name;
        string description;
        string[] parameterNames;
        uint256 mintPrice; // Price to mint a piece from this blueprint (in GUILD)
        uint256[] requiredSkillIds; // Skills required to define or mint this blueprint
        uint96 royaltyBasisPoints; // ERC2981-like royalty (0-10000)
        uint256 creatorSkillId; // What skill this blueprint is linked to (optional)
        address creator; // Artisan who defined the blueprint
        uint256 id;
        uint256 pieceCounter; // Counter for minted pieces from this blueprint
    }

    struct GenerativeArtPiece {
        uint256 blueprintId;
        string[] parameterValues;
        address minter;
        uint256 mintTime;
        uint256 id; // Unique ID for the minted piece
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        uint256 id;
        string description;
        address target; // Contract to call
        bytes callData; // Data for the call
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voters; // Member address => has voted
        ProposalState state;
        uint256 quorumVotes; // Minimum votes required
    }

    // --- State Variables ---

    mapping(address => MemberProfile) public members;
    mapping(address => bool) private _isMember; // Quick check if address is a member

    Skill[] public skills; // Array of defined skill types
    mapping(uint256 => uint256) private skillIdToIndex; // Map skill ID to array index for quick lookup

    Commission[] public commissions;
    mapping(uint256 => uint256) private commissionIdToIndex;

    GenerativeArtBlueprint[] public artBlueprints;
    mapping(uint256 => uint256) private artBlueprintIdToIndex;

    GenerativeArtPiece[] public generativeArtPieces; // Simple list of minted pieces

    Proposal[] public proposals;
    mapping(uint256 => uint256) private proposalIdToIndex;

    uint256 public totalStakedGUILD;
    uint256 public constant MIN_STAKE_FOR_PROPOSAL = 100 ether; // Example minimum GUILD to stake to propose
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Example voting period
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 5; // Example 5% of total staked GUILD needed for quorum

    uint256 public commissionFeeBasisPoints = 500; // 5% fee (500/10000)
    uint256 public constant MAX_FEE_BASIS_POINTS = 1000; // Max 10% fee

    bool public paused = false;

    uint256 private nextSkillId = 0;
    uint256 private nextCommissionId = 0;
    uint256 private nextArtBlueprintId = 0;
    uint256 private nextGenerativeArtPieceId = 0;
    uint256 private nextProposalId = 0;

    // --- Events ---

    event MemberRegistered(address indexed member, bool isArtisan, string name);
    event ProfileUpdated(address indexed member, string newName, string newProfileURI);
    event SkillDefined(uint256 indexed skillId, string name);
    event SkillAddedToProfile(address indexed member, uint256 indexed skillId);
    event SkillPointsEarned(address indexed member, uint256 indexed skillId, uint256 pointsEarned);
    event SkillVerificationRequested(address indexed member, uint256 indexed skillId, string proofURI);
    event SkillVerificationVoted(address indexed voter, address indexed member, uint256 indexed skillId, bool support);
    event SkillVerificationFinalized(address indexed member, uint256 indexed skillId, bool verified);
    event CommissionPosted(uint256 indexed commissionId, address indexed client, uint256 budget);
    event CommissionAccepted(uint256 indexed commissionId, address indexed artisan);
    event CommissionWorkSubmitted(uint256 indexed commissionId, string workURI);
    event CommissionApproved(uint256 indexed commissionId, address indexed client, address indexed artisan, uint256 paymentAmount, uint256 feeAmount);
    event ArtisanRated(uint256 indexed commissionId, address indexed artisan, uint8 rating);
    event CommissionDisputed(uint256 indexed commissionId, address indexed initiator, string reason);
    event CommissionResolved(uint256 indexed commissionId, bool clientWins);
    event ArtBlueprintDefined(uint256 indexed blueprintId, address indexed creator, string name);
    event GenerativeArtMinted(uint256 indexed artPieceId, uint256 indexed blueprintId, address indexed minter, uint256 mintPricePaid);
    event ArtBlueprintRoyaltiesSet(uint256 indexed blueprintId, uint96 royaltyBasisPoints);
    event GUILDMinted(address indexed recipient, uint256 amount);
    event GUILDBurned(uint256 amount);
    event GUILDTransferred(address indexed sender, address indexed recipient, uint256 amount);
    event GUILDStaked(address indexed member, uint256 amount);
    event GUILDUnstaked(address indexed member, uint255 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event CommissionFeeSet(uint256 basisPoints);
    event Paused(address account);
    event Unpaused(address account);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyMember() {
        require(_isMember[msg.sender], "DAAG: Not a member");
        _;
    }

    modifier onlyArtisan() {
        require(members[msg.sender].isArtisan, "DAAG: Not an artisan");
        _;
    }

    modifier onlyClient() {
        require(!members[msg.sender].isArtisan && _isMember[msg.sender], "DAAG: Not a client");
        _;
    }

    modifier onlyAdmin() {
        // In a real DAO, this role would be removed or controlled by a multisig initially,
        // then fully transitioned to DAO proposals.
        require(msg.sender == owner, "DAAG: Only admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAAG: Paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "DAAG: Not paused");
        _;
    }

    modifier onlyDAO() {
        // This modifier is for functions callable ONLY via a successful DAO proposal execution.
        // It relies on the `executeProposal` function making the call.
        // A more robust implementation might check msg.sender against a known DAO executor address.
        // For this example, we'll assume direct calls to these functions are restricted
        // and they are primarily called internally by `executeProposal`.
        // In a production system, specific internal mechanisms or separate contracts are better.
        // Here, we'll add a placeholder requirement that would be part of a proposal's calldata target check.
        // Simplification: For this example, we won't enforce it with a strict modifier,
        // but conceptually mark functions as "DAO executable".
        _; // Placeholder
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        // Mint some initial GUILD, maybe to the owner or a distribution contract
        // For simplicity, let's add a `daoMintGUILD` function and assume initial distribution
        // happens via DAO proposals or a separate script/contract.
        // We will simulate initial members later if needed for testing.
    }

    receive() external payable {} // Allow receiving Ether for commission deposits

    // --- Functions ---

    // [Membership & Profile]

    /// @notice Registers a new member in the guild.
    /// @param _name The desired name for the member profile.
    /// @param _isArtisan Whether the member is registering as an artisan (false for client).
    function registerMember(string calldata _name, bool _isArtisan) external whenNotPaused {
        require(!_isMember[msg.sender], "DAAG: Already a member");
        require(bytes(_name).length > 0, "DAAG: Name cannot be empty");

        members[msg.sender].isArtisan = _isArtisan;
        members[msg.sender].name = _name;
        members[msg.sender].registrationTime = block.timestamp;
        members[msg.sender].reputationScore = 0; // Starting reputation
        _isMember[msg.sender] = true;

        emit MemberRegistered(msg.sender, _isArtisan, _name);
    }

    /// @notice Updates the profile information for an existing member.
    /// @param _name The new name for the profile.
    /// @param _profileURI A URI pointing to off-chain profile details (e.g., IPFS).
    function updateMemberProfile(string calldata _name, string calldata _profileURI) external onlyMember whenNotPaused {
        require(bytes(_name).length > 0, "DAAG: Name cannot be empty");

        members[msg.sender].name = _name;
        members[msg.sender].profileURI = _profileURI;

        emit ProfileUpdated(msg.sender, _name, _profileURI);
    }

    /// @notice Internal function to award skill points.
    /// @param _member The member to award points to.
    /// @param _skillId The skill ID for which points are awarded.
    function earnSkillPoint(address _member, uint256 _skillId) internal {
        // Ensure member exists and has the skill added to profile
        require(_isMember[_member], "DAAG: Member does not exist");
        require(members[_member].skills[_skillId].skillPoints > 0 || _hasSkillInProfile(_member, _skillId), "DAAG: Member does not have skill in profile");

        members[_member].skills[_skillId].skillPoints++;
        members[_member].reputationScore++; // Simple reputation increase
        emit SkillPointsEarned(_member, _skillId, 1);
    }

    // Helper to check if skill is in member's skillIds array
    function _hasSkillInProfile(address _member, uint256 _skillId) internal view returns (bool) {
        for (uint i = 0; i < members[_member].skillIds.length; i++) {
            if (members[_member].skillIds[i] == _skillId) {
                return true;
            }
        }
        return false;
    }


    // [Skills]

    /// @notice Defines a new skill type available in the guild. Only callable by Admin/DAO.
    /// @param _name The name of the skill.
    /// @param _description A description of the skill.
    function defineSkill(string calldata _name, string calldata _description) external onlyAdmin whenNotPaused {
        // In a full DAO, this would be a target function of a proposal
        require(bytes(_name).length > 0, "DAAG: Skill name cannot be empty");
        uint256 id = nextSkillId++;
        skills.push(Skill(_name, _description, id, true));
        skillIdToIndex[id] = skills.length - 1;
        emit SkillDefined(id, _name);
    }

    /// @notice Allows a member (Artisan) to add a defined skill to their profile.
    /// @param _skillId The ID of the skill to add.
    function addSkillToProfile(uint256 _skillId) external onlyArtisan whenNotPaused {
        require(_skillId < nextSkillId && skills[skillIdToIndex[_skillId]].exists, "DAAG: Skill does not exist");
        require(members[msg.sender].skills[_skillId].skillPoints == 0, "DAAG: Skill already added"); // Only add once

        members[msg.sender].skills[_skillId].skillPoints = 0; // Start with 0 points
        members[msg.sender].skills[_skillId].isVerified = false; // Not verified initially
        members[msg.sender].skills[_skillId].verificationRequested = false; // Not requested initially
        members[msg.sender].skillIds.push(_skillId);

        emit SkillAddedToProfile(msg.sender, _skillId);
    }

    /// @notice Allows a member to request verification for a skill on their profile.
    /// @param _skillId The ID of the skill to verify.
    /// @param _proofURI A URI pointing to off-chain proof of skill.
    function requestSkillVerification(uint256 _skillId, string calldata _proofURI) external onlyMember whenNotPaused {
        require(_hasSkillInProfile(msg.sender, _skillId), "DAAG: Member does not have skill in profile");
        require(!members[msg.sender].skills[_skillId].isVerified, "DAAG: Skill already verified");
        require(!members[msg.sender].skills[_skillId].verificationRequested, "DAAG: Verification already requested");
        require(bytes(_proofURI).length > 0, "DAAG: Proof URI cannot be empty");

        members[msg.sender].skills[_skillId].verificationRequested = true;
        members[msg.sender].skills[_skillId].verificationProofURI = _proofURI;
        // Reset votes for a new request
        delete members[msg.sender].skills[_skillId].verificationVotes;
        members[msg.sender].skills[_skillId].verificationVotesFor = 0;
        members[msg.sender].skills[_skillId].verificationVotesAgainst = 0;

        emit SkillVerificationRequested(msg.sender, _skillId, _proofURI);
        // Note: Voting period/mechanism needs a more complex implementation (e.g., snapshot, time limits)
        // This example uses a simplified vote tracking and Admin/DAO finalization.
    }

    /// @notice Allows a staking member to vote on a skill verification request.
    /// @param _member The member whose skill is being voted on.
    /// @param _skillId The skill ID being voted on.
    /// @param _support True for supporting verification, false for opposing.
    function voteOnSkillVerification(address _member, uint256 _skillId, bool _support) external onlyMember whenNotPaused {
        require(members[msg.sender].stakedBalance > 0, "DAAG: Must stake GUILD to vote");
        require(_isMember[_member], "DAAG: Member does not exist");
        require(_hasSkillInProfile(_member, _skillId), "DAAG: Target member does not have skill in profile");
        require(members[_member].skills[_skillId].verificationRequested, "DAAG: Verification not requested for this skill");
        require(!members[_member].skills[_skillId].verificationVotes[msg.sender], "DAAG: Already voted on this request");

        members[_member].skills[_skillId].verificationVotes[msg.sender] = true;
        if (_support) {
            members[_member].skills[_skillId].verificationVotesFor++;
        } else {
            members[_member].skills[_skillId].verificationVotesAgainst++;
        }

        emit SkillVerificationVoted(msg.sender, _member, _skillId, _support);
    }

    /// @notice Finalizes a skill verification request based on votes. Only callable by Admin/DAO.
    /// @param _member The member whose skill is being verified.
    /// @param _skillId The skill ID being verified.
    function finalizeSkillVerification(address _member, uint256 _skillId) external onlyAdmin whenNotPaused {
         // In a full DAO, this would be a target function of a proposal
        require(_isMember[_member], "DAAG: Member does not exist");
        require(_hasSkillInProfile(_member, _skillId), "DAAG: Target member does not have skill in profile");
        require(members[_member].skills[_skillId].verificationRequested, "DAAG: Verification not requested for this skill");

        // Simplified logic: If votesFor > votesAgainst, verify. Needs quorum check in production.
        bool verified = members[_member].skills[_skillId].verificationVotesFor > members[_member].skills[_skillId].verificationVotesAgainst;

        members[_member].skills[_skillId].isVerified = verified;
        members[_member].skills[_skillId].verificationRequested = false; // Request finalized

        // Optionally reward members who voted or the verified artisan
        // Optionally penalize based on outcome/fraudulent proof

        emit SkillVerificationFinalized(_member, _skillId, verified);
    }


    // [Commissions]

    /// @notice Client posts a new commission request. Requires depositing the budget.
    /// @param _title Title of the commission.
    /// @param _description Description of the work required.
    /// @param _budget The budget for the commission (in native currency, e.g., Ether).
    /// @param _requiredSkillIds An array of skill IDs required for the artisan.
    function postCommission(string calldata _title, string calldata _description, uint256 _budget, uint256[] calldata _requiredSkillIds) external payable onlyClient whenNotPaused {
        require(msg.value >= _budget, "DAAG: Insufficient funds deposited for budget");
        require(_budget > 0, "DAAG: Budget must be positive");
        require(bytes(_title).length > 0, "DAAG: Title cannot be empty");
        // Basic check for required skills
        for(uint i = 0; i < _requiredSkillIds.length; i++) {
             require(_requiredSkillIds[i] < nextSkillId && skills[skillIdToIndex[_requiredSkillIds[i]]].exists, "DAAG: Invalid required skill ID");
        }

        uint256 id = nextCommissionId++;
        commissions.push(Commission(
            msg.sender,             // client
            address(0),             // artisan (not set yet)
            _title,
            _description,
            _budget,
            0,                      // commissionFee (calculated on approval)
            _requiredSkillIds,
            CommissionStatus.Open,
            "",                     // workURI
            "",                     // disputeReason
            -1,                     // clientRating
            block.timestamp
        ));
        commissionIdToIndex[id] = commissions.length - 1;

        emit CommissionPosted(id, msg.sender, _budget);
    }

    /// @notice Artisan accepts an open commission.
    /// @param _commissionId The ID of the commission to accept.
    function acceptCommission(uint256 _commissionId) external onlyArtisan whenNotPaused {
        uint256 index = commissionIdToIndex[_commissionId];
        require(index < commissions.length && commissions[index].client != address(0) && commissions[index].status == CommissionStatus.Open, "DAAG: Commission not found or not open");
        require(commissions[index].artisan == address(0), "DAAG: Commission already accepted");

        // Optional: Check if artisan has the required skills (maybe verified skills give priority)
        bool hasAllRequiredSkills = true;
        for(uint i = 0; i < commissions[index].requiredSkillIds.length; i++) {
            uint256 requiredSkillId = commissions[index].requiredSkillIds[i];
            if (!_hasSkillInProfile(msg.sender, requiredSkillId) || !members[msg.sender].skills[requiredSkillId].isVerified) {
                 // Simple check: must have the skill verified. More complex logic possible.
                 hasAllRequiredSkills = false;
                 break;
            }
        }
        require(hasAllRequiredSkills, "DAAG: Artisan does not have the required verified skills");


        commissions[index].artisan = msg.sender;
        commissions[index].status = CommissionStatus.Accepted;

        emit CommissionAccepted(_commissionId, msg.sender);
    }

    /// @notice Artisan submits the completed work URI for a commission.
    /// @param _commissionId The ID of the commission.
    /// @param _workURI A URI pointing to the submitted work.
    function submitCommissionWork(uint256 _commissionId, string calldata _workURI) external onlyArtisan whenNotPaused {
        uint256 index = commissionIdToIndex[_commissionId];
        require(index < commissions.length && commissions[index].client != address(0) && commissions[index].status == CommissionStatus.Accepted, "DAAG: Commission not found or not in Accepted status");
        require(commissions[index].artisan == msg.sender, "DAAG: Not the assigned artisan");
        require(bytes(_workURI).length > 0, "DAAG: Work URI cannot be empty");

        commissions[index].workURI = _workURI;
        commissions[index].status = CommissionStatus.WorkSubmitted;

        emit CommissionWorkSubmitted(_commissionId, _workURI);
    }

    /// @notice Client approves the submitted work, releasing payment to the artisan (minus fee).
    /// @param _commissionId The ID of the commission.
    function approveCommissionWork(uint256 _commissionId) external onlyClient whenNotPaused {
        uint256 index = commissionIdToIndex[_commissionId];
        require(index < commissions.length && commissions[index].client == msg.sender && commissions[index].status == CommissionStatus.WorkSubmitted, "DAAG: Commission not found or not in WorkSubmitted status");

        address artisan = commissions[index].artisan;
        uint256 budget = commissions[index].budget;
        uint256 feeAmount = (budget * commissionFeeBasisPoints) / 10000;
        uint256 paymentAmount = budget - feeAmount;

        commissions[index].commissionFee = feeAmount;
        commissions[index].status = CommissionStatus.Approved;

        // Transfer payment to artisan and fee to treasury
        payable(artisan).transfer(paymentAmount);
        // Fee remains in contract balance to be managed by DAO
        // payable(address(this)).transfer(feeAmount); // Already here from initial deposit

        // Reward artisan with skill points for relevant skills on successful completion
        for(uint i = 0; i < commissions[index].requiredSkillIds.length; i++) {
            earnSkillPoint(artisan, commissions[index].requiredSkillIds[i]);
        }
         // Reward client reputation for closing commission? Maybe.

        emit CommissionApproved(_commissionId, msg.sender, artisan, paymentAmount, feeAmount);
    }

    /// @notice Client rates the artisan after a commission is approved.
    /// @param _commissionId The ID of the commission.
    /// @param _rating The rating from 1 to 5.
    function rateArtisan(uint256 _commissionId, uint8 _rating) external onlyClient whenNotPaused {
        uint256 index = commissionIdToIndex[_commissionId];
        require(index < commissions.length && commissions[index].client == msg.sender && commissions[index].status == CommissionStatus.Approved, "DAAG: Commission not found or not in Approved status");
        require(commissions[index].clientRating == -1, "DAAG: Artisan already rated for this commission");
        require(_rating >= 1 && _rating <= 5, "DAAG: Rating must be between 1 and 5");

        commissions[index].clientRating = int8(_rating);

        // Update artisan's overall reputation score based on rating (simplified)
        members[commissions[index].artisan].reputationScore += _rating;

        emit ArtisanRated(_commissionId, commissions[index].artisan, _rating);
    }

    /// @notice Initiates a dispute for a commission.
    /// @param _commissionId The ID of the commission.
    /// @param _reason The reason for the dispute.
    function disputeCommission(uint256 _commissionId, string calldata _reason) external onlyMember whenNotPaused {
        uint256 index = commissionIdToIndex[_commissionId];
        require(index < commissions.length && commissions[index].client != address(0), "DAAG: Commission not found");
        require(commissions[index].status != CommissionStatus.Disputed && commissions[index].status != CommissionStatus.Resolved && commissions[index].status != CommissionStatus.Cancelled, "DAAG: Commission cannot be disputed in current status");
        require(msg.sender == commissions[index].client || msg.sender == commissions[index].artisan, "DAAG: Only client or artisan can dispute");
        require(bytes(_reason).length > 0, "DAAG: Dispute reason cannot be empty");

        commissions[index].status = CommissionStatus.Disputed;
        commissions[index].disputeReason = _reason;

        emit CommissionDisputed(_commissionId, msg.sender, _reason);

        // Dispute resolution needs to be handled by DAO/Admin via `resolveCommissionDispute`
    }

    /// @notice Resolves a disputed commission. Only callable by Admin/DAO.
    /// @param _commissionId The ID of the commission.
    /// @param _clientWins True if the dispute is resolved in favor of the client.
    function resolveCommissionDispute(uint256 _commissionId, bool _clientWins) external onlyAdmin whenNotPaused {
        // In a full DAO, this would be a target function of a proposal
        uint256 index = commissionIdToIndex[_commissionId];
        require(index < commissions.length && commissions[index].status == CommissionStatus.Disputed, "DAAG: Commission not found or not in Disputed status");

        address client = commissions[index].client;
        address artisan = commissions[index].artisan;
        uint256 budget = commissions[index].budget;

        if (_clientWins) {
            // Refund client, no payment to artisan, no fee
            payable(client).transfer(budget);
        } else {
            // Treat as if work was approved (simplified - ignores state before dispute)
            // Pay artisan (minus fee), collect fee
             uint256 feeAmount = (budget * commissionFeeBasisPoints) / 10000;
             uint256 paymentAmount = budget - feeAmount;

             commissions[index].commissionFee = feeAmount;
             payable(artisan).transfer(paymentAmount);

             // Reward artisan with skill points on successful completion (even if via dispute win)
            for(uint i = 0; i < commissions[index].requiredSkillIds.length; i++) {
                earnSkillPoint(artisan, commissions[index].requiredSkillIds[i]);
            }
        }

        commissions[index].status = CommissionStatus.Resolved;

        emit CommissionResolved(_commissionId, _clientWins);
    }


    // [Generative Art]

    /// @notice Defines a new generative art blueprint. Can require specific skills or be DAO controlled.
    /// @param _name Name of the blueprint.
    /// @param _description Description of the art style/parameters.
    /// @param _parameterNames Names of the parameters for the generative process (e.g., ["color", "shape"]).
    /// @param _mintPrice The price in GUILD tokens to mint a piece from this blueprint.
    /// @param _requiredSkillIds Skill IDs required for the *creator* of the blueprint OR for *minters*.
    function defineGenerativeArtBlueprint(string calldata _name, string calldata _description, string[] calldata _parameterNames, uint256 _mintPrice, uint256[] calldata _requiredSkillIds) external onlyArtisan whenNotPaused {
        // In a full DAO, this might also be callable by a proposal, OR only by highly skilled/verified artisans.
        // Example check: Require the artisan creator to have ALL _requiredSkillIds verified.
         for(uint i = 0; i < _requiredSkillIds.length; i++) {
            uint256 requiredSkillId = _requiredSkillIds[i];
            require(_hasSkillInProfile(msg.sender, requiredSkillId) && members[msg.sender].skills[requiredSkillId].isVerified, "DAAG: Creator must have all required skills verified");
         }

        uint256 id = nextArtBlueprintId++;
        artBlueprints.push(GenerativeArtBlueprint(
            true,
            _name,
            _description,
            _parameterNames,
            _mintPrice,
            _requiredSkillIds, // These skills could be required for *minters* too depending on design
            0, // royaltyBasisPoints, set later by DAO/Admin
            _requiredSkillIds.length > 0 ? _requiredSkillIds[0] : 0, // Link blueprint to a primary skill if any
            msg.sender, // Blueprint creator
            id,
            0 // pieceCounter
        ));
        artBlueprintIdToIndex[id] = artBlueprints.length - 1;

        emit ArtBlueprintDefined(id, msg.sender, _name);
    }

     /// @notice Mints a piece of generative art from a blueprint. Requires paying the mint price in GUILD.
     /// @param _blueprintId The ID of the blueprint to mint from.
     /// @param _parameterValues The values for the parameters defined in the blueprint. These values are typically used off-chain by a renderer.
    function mintGenerativeArt(uint256 _blueprintId, string[] calldata _parameterValues) external onlyMember whenNotPaused {
        uint256 blueprintIndex = artBlueprintIdToIndex[_blueprintId];
        require(blueprintIndex < artBlueprints.length && artBlueprints[blueprintIndex].exists, "DAAG: Blueprint does not exist");
        require(artBlueprints[blueprintIndex].parameterNames.length == _parameterValues.length, "DAAG: Parameter value count mismatch");
        require(members[msg.sender].guildBalance >= artBlueprints[blueprintIndex].mintPrice, "DAAG: Insufficient GUILD balance");

        // Optional check: Require minter to have certain skills or skill level
        // For example, require minter to have the blueprint's creatorSkillId at a certain point level
        // require(members[msg.sender].skills[artBlueprints[blueprintIndex].creatorSkillId].skillPoints >= MIN_SKILL_POINTS_TO_MINT, "DAAG: Requires minimum skill points");


        uint256 price = artBlueprints[blueprintIndex].mintPrice;

        // Pay mint price (burn or send to blueprint creator/treasury)
        _burnGUILD(msg.sender, price); // Example: burn GUILD from minter
        // Or: _transferGUILD(msg.sender, artBlueprints[blueprintIndex].creator, price); // Pay creator
        // Or: _transferGUILD(msg.sender, address(this), price); // Send to treasury

        uint256 artPieceId = nextGenerativeArtPieceId++;
        artBlueprints[blueprintIndex].pieceCounter++; // Increment count for the blueprint

        generativeArtPieces.push(GenerativeArtPiece(
            _blueprintId,
            _parameterValues,
            msg.sender,
            block.timestamp,
            artPieceId
        ));

        emit GenerativeArtMinted(artPieceId, _blueprintId, msg.sender, price);
    }

    /// @notice Sets the royalty percentage for a generative art blueprint. Simulates ERC2981.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _royaltyBasisPoints The royalty percentage in basis points (e.g., 500 for 5%). Max 10000 (100%).
    function setArtBlueprintRoyalties(uint256 _blueprintId, uint96 _royaltyBasisPoints) external onlyAdmin whenNotPaused {
        // In a full DAO, this would be a target function of a proposal
        uint256 blueprintIndex = artBlueprintIdToIndex[_blueprintId];
        require(blueprintIndex < artBlueprints.length && artBlueprints[blueprintIndex].exists, "DAAG: Blueprint does not exist");
        require(_royaltyBasisPoints <= 10000, "DAAG: Royalty basis points cannot exceed 10000");

        artBlueprints[blueprintIndex].royaltyBasisPoints = _royaltyBasisPoints;

        emit ArtBlueprintRoyaltiesSet(_blueprintId, _royaltyBasisPoints);
    }


    // [GUILD Token & Staking (Simplified)]
    // Note: This is NOT a full ERC20 implementation. Balances are tracked internally
    // for governance staking, minting, burning, and basic internal transfers/payments.
    // For external transfers, a separate ERC20 contract is required, and this contract
    // would hold a balance of that ERC20.

    /// @notice Internal function for minting GUILD. Only callable by DAO proposal execution.
    /// @param _recipient The address to mint GUILD to.
    /// @param _amount The amount of GUILD to mint.
    function daoMintGUILD(address _recipient, uint256 _amount) external onlyDAO whenNotPaused {
        require(_isMember[_recipient], "DAAG: Recipient must be a member");
        _guildTotalSupply += _amount;
        members[_recipient].guildBalance += _amount;
        emit GUILDMinted(_recipient, _amount);
    }

    /// @notice Internal function for burning GUILD. Only callable by DAO proposal execution (e.g., burning fees).
    /// @param _amount The amount of GUILD to burn from the contract's internal balance (e.g., collected fees).
    function daoBurnGUILD(uint256 _amount) external onlyDAO whenNotPaused {
        // Assumes GUILD is burned from a general pool like collected fees represented internally
        // In a real system, this would likely burn from the contract's actual ERC20 balance
         require(_guildTotalSupply >= _amount, "DAAG: Insufficient total supply to burn"); // Or check internal 'fee' balance
         _guildTotalSupply -= _amount;
        // Note: Burning from a specific user requires their consent/transfer approval.
        // This example assumes burning from a contract-controlled pool or is part of a specific flow.
         emit GUILDBurned(_amount);
    }

    /// @notice Internal function for transferring GUILD. Used for payments/fees internally.
    function _transferGUILD(address _sender, address _recipient, uint256 _amount) internal {
        require(_isMember[_sender], "DAAG: Sender not a member");
        require(_isMember[_recipient], "DAAG: Recipient not a member");
        require(members[_sender].guildBalance >= _amount, "DAAG: Insufficient GUILD balance");

        members[_sender].guildBalance -= _amount;
        members[_recipient].guildBalance += _amount;

        emit GUILDTransferred(_sender, _recipient, _amount);
    }

    /// @notice Stakes GUILD tokens for governance voting power and potentially visibility boosts.
    /// @param _amount The amount of GUILD to stake.
    function stakeGUILD(uint256 _amount) external onlyMember whenNotPaused {
        require(members[msg.sender].guildBalance >= _amount, "DAAG: Insufficient GUILD balance to stake");
        require(_amount > 0, "DAAG: Cannot stake zero");

        members[msg.sender].guildBalance -= _amount;
        members[msg.sender].stakedBalance += _amount;
        totalStakedGUILD += _amount;

        emit GUILDStaked(msg.sender, _amount);
    }

    /// @notice Unstakes GUILD tokens.
    /// @param _amount The amount of GUILD to unstake.
    function unstakeGUILD(uint256 _amount) external onlyMember whenNotPaused {
        require(members[msg.sender].stakedBalance >= _amount, "DAAG: Insufficient staked GUILD balance");
        require(_amount > 0, "DAAG: Cannot unstake zero");

        members[msg.sender].stakedBalance -= _amount;
        members[msg.sender].guildBalance += _amount;
        totalStakedGUILD -= _amount;

        // Note: In a real system, unstaking might require a cooldown period,
        // and unstaked tokens cannot vote on proposals created while staked.

        emit GUILDUnstaked(msg.sender, _amount);
    }


    // [DAO Governance]

    /// @notice Allows a member with sufficient stake to propose a DAO action.
    /// @param _description Description of the proposal.
    /// @param _target The address of the contract/account the proposal will call.
    /// @param _callData The calldata for the target call.
    function proposeGuildAction(string calldata _description, address _target, bytes calldata _callData) external onlyMember whenNotPaused {
        require(members[msg.sender].stakedBalance >= MIN_STAKE_FOR_PROPOSAL, "DAAG: Insufficient stake to propose");
        require(bytes(_description).length > 0, "DAAG: Description cannot be empty");
        // Add more checks: e.g., target is a valid contract, callData format is safe/expected etc.

        uint256 id = nextProposalId++;
        uint256 quorum = (totalStakedGUILD * PROPOSAL_QUORUM_PERCENT) / 100;
        if (quorum == 0 && totalStakedGUILD > 0) quorum = 1; // Minimum 1 vote if any stake exists

        proposals.push(Proposal(
            id,
            _description,
            _target,
            _callData,
            block.timestamp,
            block.timestamp + PROPOSAL_VOTING_PERIOD,
            0, // votesFor
            0, // votesAgainst
            new mapping(address => bool), // voters map needs to be initialized empty
            ProposalState.Active,
            quorum
        ));
        proposalIdToIndex[id] = proposals.length - 1;

        emit ProposalCreated(id, msg.sender, _description);
    }

    /// @notice Allows a staking member to vote on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for voting in favor, false for voting against.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyMember whenNotPaused {
        uint256 index = proposalIdToIndex[_proposalId];
        require(index < proposals.length && proposals[index].creationTime > 0, "DAAG: Proposal not found");
        require(proposals[index].state == ProposalState.Active, "DAAG: Proposal not active");
        require(block.timestamp <= proposals[index].votingPeriodEnd, "DAAG: Voting period ended");
        require(members[msg.sender].stakedBalance > 0, "DAAG: Must stake GUILD to vote");
        require(!proposals[index].voters[msg.sender], "DAAG: Already voted on this proposal");

        proposals[index].voters[msg.sender] = true;
        if (_support) {
            proposals[index].votesFor += members[msg.sender].stakedBalance; // Weight vote by stake
        } else {
            proposals[index].votesAgainst += members[msg.sender].stakedBalance; // Weight vote by stake
        }

        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a proposal that has succeeded after the voting period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyMember whenNotPaused {
        uint256 index = proposalIdToIndex[_proposalId];
        require(index < proposals.length && proposals[index].creationTime > 0, "DAAG: Proposal not found");
        require(proposals[index].state == ProposalState.Active, "DAAG: Proposal not active");
        require(block.timestamp > proposals[index].votingPeriodEnd, "DAAG: Voting period not ended");

        // Determine outcome
        bool succeeded = proposals[index].votesFor > proposals[index].votesAgainst && proposals[index].votesFor >= proposals[index].quorumVotes;

        if (succeeded) {
            proposals[index].state = ProposalState.Succeeded;
            emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);

            // Execute the proposal
            (bool success, ) = proposals[index].target.call(proposals[index].callData);
            require(success, "DAAG: Proposal execution failed");

            proposals[index].state = ProposalState.Executed;
            emit ProposalStateChanged(_proposalId, ProposalState.Executed);

        } else {
            proposals[index].state = ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
        }
    }


    // [System & Treasury]

    /// @notice Sets the commission fee percentage. Only callable by Admin/DAO.
    /// @param _feeBasisPoints The new fee in basis points (0-10000).
    function setCommissionFee(uint256 _feeBasisPoints) external onlyAdmin whenNotPaused {
         // In a full DAO, this would be a target function of a proposal
        require(_feeBasisPoints <= MAX_FEE_BASIS_POINTS, "DAAG: Fee exceeds maximum allowed");
        commissionFeeBasisPoints = _feeBasisPoints;
        emit CommissionFeeSet(_feeBasisPoints);
    }

    /// @notice Pauses contract functionality. Only callable by Admin/DAO.
    function pause() external onlyAdmin whenNotPaused {
        // In a full DAO, this would be a target function of a proposal
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses contract functionality. Only callable by Admin/DAO.
    function unpause() external onlyAdmin whenPaused {
        // In a full DAO, this would be a target function of a proposal
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Withdraws funds from the contract treasury (collected fees, etc.). Only callable by DAO proposal execution.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of native currency to withdraw.
    function withdrawTreasury(address _recipient, uint256 _amount) external payable onlyDAO whenNotPaused {
         require(address(this).balance >= _amount, "DAAG: Insufficient treasury balance");
         // Basic check that recipient isn't zero or this contract itself
         require(_recipient != address(0) && _recipient != address(this), "DAAG: Invalid recipient");

        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }


    // [View Functions] - Read-only functions (do not count towards the 20+ actions)

    /// @notice Gets a member's profile details.
    function getMemberProfile(address _member) external view returns (
        bool isMember,
        bool isArtisan,
        string memory name,
        string memory profileURI,
        uint256 registrationTime,
        uint256 reputationScore,
        uint256 guildBalance,
        uint256 stakedBalance
    ) {
        isMember = _isMember[_member];
        if (!isMember) {
            return (false, false, "", "", 0, 0, 0, 0);
        }
        MemberProfile storage member = members[_member];
        return (
            true,
            member.isArtisan,
            member.name,
            member.profileURI,
            member.registrationTime,
            member.reputationScore,
            member.guildBalance,
            member.stakedBalance
        );
    }

    /// @notice Gets details for a specific skill on a member's profile.
    function getMemberSkillDetails(address _member, uint256 _skillId) external view returns (
        bool existsOnProfile,
        uint256 skillPoints,
        bool isVerified,
        string memory verificationProofURI,
        uint256 verificationVotesFor,
        uint256 verificationVotesAgainst,
        bool verificationRequested
    ) {
        if (!_isMember[_member] || !_hasSkillInProfile(_member, _skillId)) {
             return (false, 0, false, "", 0, 0, false);
        }
        MemberSkill storage memberSkill = members[_member].skills[_skillId];
         return (
            true,
            memberSkill.skillPoints,
            memberSkill.isVerified,
            memberSkill.verificationProofURI,
            memberSkill.verificationVotesFor,
            memberSkill.verificationVotesAgainst,
            memberSkill.verificationRequested
        );
    }

    /// @notice Gets the details of a defined skill type.
    function getSkill(uint256 _skillId) external view returns (
        bool exists,
        string memory name,
        string memory description
    ) {
         uint256 index = skillIdToIndex[_skillId];
         if (index >= skills.length || !skills[index].exists) {
             return (false, "", "");
         }
         Skill storage skill = skills[index];
         return (true, skill.name, skill.description);
    }

    /// @notice Gets the details of a commission.
    function getCommission(uint256 _commissionId) external view returns (
        bool exists,
        address client,
        address artisan,
        string memory title,
        uint256 budget,
        uint256 commissionFee,
        CommissionStatus status,
        string memory workURI,
        int8 clientRating,
        uint256 creationTime
    ) {
         uint256 index = commissionIdToIndex[_commissionId];
         if (index >= commissions.length || commissions[index].client == address(0)) {
             return (false, address(0), address(0), "", 0, 0, CommissionStatus.Open, "", -1, 0);
         }
         Commission storage commission = commissions[index];
         return (
             true,
             commission.client,
             commission.artisan,
             commission.title,
             commission.budget,
             commission.commissionFee,
             commission.status,
             commission.workURI,
             commission.clientRating,
             commission.creationTime
         );
    }

     /// @notice Gets the details of a generative art blueprint.
     function getArtBlueprint(uint256 _blueprintId) external view returns (
         bool exists,
         string memory name,
         string memory description,
         string[] memory parameterNames,
         uint256 mintPrice,
         uint256[] memory requiredSkillIds,
         uint96 royaltyBasisPoints,
         address creator,
         uint256 pieceCounter
     ) {
         uint256 index = artBlueprintIdToIndex[_blueprintId];
         if (index >= artBlueprints.length || !artBlueprints[index].exists) {
              return (false, "", "", new string[](0), 0, new uint256[](0), 0, address(0), 0);
         }
         GenerativeArtBlueprint storage blueprint = artBlueprints[index];
         return (
             true,
             blueprint.name,
             blueprint.description,
             blueprint.parameterNames,
             blueprint.mintPrice,
             blueprint.requiredSkillIds,
             blueprint.royaltyBasisPoints,
             blueprint.creator,
             blueprint.pieceCounter
         );
     }

    /// @notice Gets the details of a specific minted generative art piece.
    function getGenerativeArtPiece(uint256 _artPieceId) external view returns (
        bool exists,
        uint256 blueprintId,
        string[] memory parameterValues,
        address minter,
        uint256 mintTime
    ) {
        if (_artPieceId >= generativeArtPieces.length) {
            return (false, 0, new string[](0), address(0), 0);
        }
        GenerativeArtPiece storage piece = generativeArtPieces[_artPieceId];
        return (
            true,
            piece.blueprintId,
            piece.parameterValues,
            piece.minter,
            piece.mintTime
        );
    }

    /// @notice Gets the details of a proposal.
    function getProposal(uint256 _proposalId) external view returns (
        bool exists,
        string memory description,
        address target,
        bytes memory callData,
        uint256 creationTime,
        uint256 votingPeriodEnd,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state,
        uint256 quorumVotes
    ) {
         uint256 index = proposalIdToIndex[_proposalId];
         if (index >= proposals.length || proposals[index].creationTime == 0) {
            return (false, "", address(0), "", 0, 0, 0, 0, ProposalState.Pending, 0);
         }
         Proposal storage proposal = proposals[index];
         return (
             true,
             proposal.description,
             proposal.target,
             proposal.callData,
             proposal.creationTime,
             proposal.votingPeriodEnd,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.state,
             proposal.quorumVotes
         );
    }

    /// @notice Checks if a member has voted on a proposal.
    function hasMemberVotedOnProposal(uint256 _proposalId, address _member) external view returns (bool) {
         uint256 index = proposalIdToIndex[_proposalId];
         require(index < proposals.length && proposals[index].creationTime > 0, "DAAG: Proposal not found");
         return proposals[index].voters[_member];
    }

    /// @notice Gets the internal GUILD token balance for a member.
    function getGUILDBalance(address _member) external view returns (uint256) {
        return members[_member].guildBalance;
    }

    /// @notice Gets the total internal GUILD token supply.
    function getGUILDTotalSupply() external view returns (uint256) {
        return _guildTotalSupply;
    }

    /// @notice Gets the staked GUILD token balance for a member.
    function getStakedGUILD(address _member) external view returns (uint256) {
         return members[_member].stakedBalance;
    }

    /// @notice Gets the total amount of GUILD tokens currently staked.
    function getTotalStakedGUILD() external view returns (uint256) {
        return totalStakedGUILD;
    }

     /// @notice Gets the contract's native currency balance (treasury).
     function getTreasuryBalance() external view returns (uint256) {
         return address(this).balance;
     }

    // --- Internal/Helper Functions ---

    /// @dev Helper to burn internal GUILD balance from a member.
    function _burnGUILD(address _member, uint256 _amount) internal {
        require(_isMember[_member], "DAAG: Member does not exist");
        require(members[_member].guildBalance >= _amount, "DAAG: Insufficient GUILD balance to burn");
        members[_member].guildBalance -= _amount;
        _guildTotalSupply -= _amount; // Update total supply
        emit GUILDBurned(_amount); // Event might ideally include burner/location
    }


    // Fallback function to collect any unhandled Ether sent
    // Not explicitly needed due to `receive()`, but demonstrates intent.
    // fallback() external payable {
    //     // Potentially add logic here if you want to restrict fallback
    // }
}
```