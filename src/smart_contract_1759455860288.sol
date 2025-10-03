This smart contract, **Aetheria Nexus Guild**, is designed as a decentralized autonomous organization (DAO) with a unique blend of features focusing on impact initiatives, reputation-based governance, dynamic Soulbound NFTs, and AI-assisted proposal evaluation. It aims to create a vibrant, gamified community where member contributions drive positive change.

---

## Aetheria Nexus Guild Smart Contract

This contract implements a Decentralized Autonomous Organization (DAO) focused on impact initiatives, integrating a unique blend of reputation-based governance, dynamic Soulbound NFTs, AI oracle evaluation, and gamified engagement. Members join a "Guild", earn reputation through contributions, and their "ANG Artifact" (a Soulbound NFT) evolves with their reputation. This reputation, along with staked artifacts, directly influences their voting power on community proposals, especially those targeting social and environmental impact, which are also evaluated by an external AI oracle for guidance.

---

### Outline and Function Summary

**I. Core Guild Administration & Setup (6 Functions)**
1.  **`constructor()`**: Initializes the contract owner, sets up the default admin role, and defines initial core parameters for the guild.
2.  **`setGuardian(address _newGuardian)`**: Designates a guardian address responsible for executing approved treasury withdrawals, adding a layer of security.
3.  **`setAIGuidanceOracle(address _oracle)`**: Sets the address of an external AI Oracle contract, which provides impact scores for proposals.
4.  **`updateGuildParameter(bytes32 _paramName, uint256 _newValue)`**: Allows admins to update various configurable `uint256` parameters (e.g., minimum ETH to join, minimum reputation to propose).
5.  **`addGuildAdmin(address _newAdmin)`**: Grants the `ADMIN_ROLE` to a specified address, enabling them to manage guild operations like granting reputation or creating quests.
6.  **`removeGuildAdmin(address _adminToRemove)`**: Revokes the `ADMIN_ROLE` from a specified address.

**II. Membership & Reputation Management (Soulbound) (5 Functions)**
7.  **`joinGuild(string calldata _username)`**: Allows a new user to join the Guild by sending the required ETH, minting their initial soulbound ANG Artifact, and receiving starting reputation.
8.  **`earnReputation(address _member, uint256 _amount, string calldata _reasonHash)`**: (Admin-only) Grants reputation to a member for validated contributions or achievements, identified by a reason hash.
9.  **`getMemberReputation(address _member) view`**: Retrieves the current reputation score of a member.
10. **`getMemberLevel(address _member) view`**: Returns a descriptive tier name (e.g., "Aether Apprentice", "Nexus Elder") based on the member's reputation score.
11. **`_updateMemberActivity(address _member) internal`**: An internal utility to record the last active timestamp for a member, useful for potential future reputation decay logic (though not directly implemented as a decay function).

**III. Dynamic NFT (ANG Artifact) Management (Soulbound & Evolvable) (4 Functions)**
12. **`getArtifactUri(address _member) view`**: Generates and returns a dynamic metadata URI for a member's ANG Artifact. This URI changes based on their current reputation level, reflecting the artifact's evolution.
13. **`evolveArtifactStage(address _member)`**: (Admin-only) Explicitly triggers an update to a member's artifact metadata, signaling to off-chain services that the artifact's visual or descriptive stage should be refreshed based on their reputation.
14. **`stakeArtifactForBoost()`**: Allows a guild member to "stake" their soulbound ANG Artifact. This doesn't transfer the NFT but marks it as active to grant boosted voting power in governance.
15. **`unstakeArtifactForBoost()`**: Allows a guild member to "unstake" their ANG Artifact, removing the associated voting power boost.

**IV. Treasury & Funding Mechanisms (3 Functions)**
16. **`depositFunds() payable`**: Allows anyone to deposit ETH into the Guild's collective treasury.
17. **`submitTreasuryWithdrawalProposal(address _recipient, uint256 _amount, string calldata _reasonHash)`**: (Admin-only) Creates a specific type of proposal to withdraw funds from the treasury. These require governance approval and are executed by the Guardian.
18. **`executeApprovedWithdrawal(uint256 _proposalId)`**: (Guardian-only) Executes a treasury withdrawal proposal that has successfully passed the governance vote and meets all conditions.

**V. Impact Initiatives & Governance (6 Functions)**
19. **`submitImpactProposal(string calldata _title, string calldata _descriptionHash, address _targetRecipient, uint256 _amountRequested, uint256 _fundingDeadline)`**: Allows members with sufficient reputation to propose impact projects for funding from the Guild treasury.
20. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows guild members to cast their vote (for or against) on an active proposal. Voting power is weighted by reputation and whether their artifact is staked.
21. **`evaluateProposalWithAI(uint256 _proposalId, uint256 _aiScore)`**: (Admin-only) Records the impact score provided by the external AI Oracle for a given proposal, influencing its chances of passing.
22. **`finalizeAndExecuteProposal(uint256 _proposalId)`**: Callable by anyone after the voting deadline. If the proposal meets the vote threshold and AI score threshold, its status is updated, and funds are transferred to the recipient.
23. **`getProposalDetails(uint256 _proposalId) view`**: Retrieves comprehensive details about a specific proposal.
24. **`getProposalVoteCount(uint256 _proposalId) view`**: Returns the current vote counts (for and against) for a proposal.

**VI. Gamified Engagement (Quests & Bounties) (3 Functions)**
25. **`createQuest(string calldata _title, string calldata _descriptionHash, uint256 _reputationReward, uint256 _deadline)`**: (Admin-only) Creates a new quest with a specified reputation reward and completion deadline for members.
26. **`submitQuestSolution(uint256 _questId, string calldata _solutionHash)`**: Allows a guild member to submit a hash of their solution or proof of completion for an active quest.
27. **`verifyQuestSolution(uint256 _questId, address _member, bool _approved)`**: (Admin-only) Verifies a submitted quest solution. If approved, the member earns the quest's reputation reward.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- Custom Errors ---
// Using custom errors for better gas efficiency and descriptive revert reasons in Solidity 0.8.x
error NotGuildMember();
error AlreadyGuildMember();
error InsufficientReputation(uint256 required, uint256 has);
error InvalidAmount();
error ProposalNotFound();
error ProposalAlreadyFinalized();
error ProposalNotYetFinalized();
error VotingClosed();
error VotingAlreadyDone();
error Unauthorized();
error QuestNotFound();
error QuestAlreadyCompleted();
error QuestDeadlinePassed();
error InvalidAIOracle();
error ParameterUpdateFailed();
error ArtifactAlreadyStaked();
error ArtifactNotStaked();
error NoArtifactFound();
error WithdrawalNotApproved();
error GuardianNotSet();
error InsufficientTreasuryFunds(uint256 requested, uint256 available);

// --- Interfaces ---
// Interface for the external AI Guidance Oracle
interface IAIGuidanceOracle {
    function getImpactScore(string calldata _proposalDescriptionHash) external view returns (uint256);
}

// --- Main Contract ---
contract AetheriaNexusGuild is Context, AccessControl, ReentrancyGuard {
    using SafeMath for uint256; // Although 0.8+ handles overflow, SafeMath provides explicit clarity.
    using Strings for uint256;  // For converting uint256 to string, useful for URI generation.
    using Strings for address;  // For converting address to hex string in URI generation.

    // --- Roles ---
    // ADMIN_ROLE: For general guild management (e.g., granting reputation, creating quests).
    // GUARDIAN_ROLE: Specific role for executing approved treasury withdrawals.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    // --- Structs ---

    // MemberDetails: Stores comprehensive information about each guild member.
    struct MemberDetails {
        string username;                // Display name of the member.
        uint256 reputation;             // Current reputation score.
        uint256 joinedTimestamp;        // Timestamp when the member joined the guild.
        uint256 lastActiveTimestamp;    // Timestamp of the member's last significant interaction.
        bool hasArtifact;               // True if the member has minted their soulbound ANG Artifact.
        bool artifactStaked;            // True if the ANG Artifact is currently staked for voting boost.
    }

    // ProposalStatus: Enum to track the lifecycle of a proposal.
    enum ProposalStatus {
        Pending,        // Initial state, not yet active for voting (unused in current flow, but good for completeness)
        Active,         // Currently open for voting.
        Passed,         // Met voting and AI score thresholds (if applicable).
        Failed,         // Did not meet thresholds or treasury funds insufficient.
        Executed,       // Funds have been successfully disbursed.
        Canceled        // Proposal was explicitly canceled (not used in current flow).
    }

    // Proposal: Stores all details related to a guild proposal.
    struct Proposal {
        uint256 id;                     // Unique identifier for the proposal.
        string title;                   // Short title of the proposal.
        string descriptionHash;         // IPFS hash or similar for detailed off-chain description.
        address proposer;               // Address of the member who submitted the proposal.
        address targetRecipient;        // Address that will receive funds if proposal passes.
        uint256 amountRequested;        // Amount of ETH requested.
        uint256 fundingDeadline;        // Timestamp when voting period ends.
        uint256 forVotes;               // Accumulated 'for' votes (weighted by reputation/artifact).
        uint256 againstVotes;           // Accumulated 'against' votes (weighted).
        uint256 aiImpactScore;          // Score from the AI oracle (0-100).
        ProposalStatus status;          // Current status of the proposal.
        mapping(address => bool) hasVoted; // Tracks if a member has already voted on this proposal.
        bool isTreasuryWithdrawal;      // True if this is a proposal to withdraw from treasury by admin.
    }

    // Quest: Stores details for gamified tasks that members can complete for reputation.
    struct Quest {
        uint256 id;                     // Unique identifier for the quest.
        string title;                   // Title of the quest.
        string descriptionHash;         // IPFS hash for detailed off-chain description.
        uint256 reputationReward;       // Reputation points awarded upon completion.
        uint256 deadline;               // Timestamp by which the quest must be completed.
        bool active;                    // True if the quest is currently available.
        mapping(address => bool) completedBy; // Tracks members who have successfully completed this quest.
        mapping(address => string) submittedSolutions; // Maps member to their solution hash for verification.
    }

    // --- State Variables ---
    IAIGuidanceOracle public aiGuidanceOracle; // Address of the AI oracle contract.
    address public guardian;                   // Address with GUARDIAN_ROLE for specific treasury ops.

    uint256 public proposalCount; // Counter for unique proposal IDs.
    uint256 public questCount;    // Counter for unique quest IDs.

    mapping(address => MemberDetails) public members; // Maps member address to their details.
    mapping(uint256 => Proposal) public proposals;   // Maps proposal ID to its details.
    mapping(uint256 => Quest) public quests;         // Maps quest ID to its details.

    // Configurable parameters, stored as bytes32 => uint256 for flexibility.
    mapping(bytes32 => uint256) public guildParameters;
    bytes32 public constant MIN_ETH_TO_JOIN = keccak256("MIN_ETH_TO_JOIN");                       // Minimum ETH required to join the guild.
    bytes32 public constant MIN_REP_TO_PROPOSE = keccak256("MIN_REP_TO_PROPOSE");                 // Minimum reputation to submit a proposal.
    bytes32 public constant PROPOSAL_VOTE_THRESHOLD_BPS = keccak256("PROPOSAL_VOTE_THRESHOLD_BPS"); // Percentage (in Basis Points) of 'for' votes needed to pass a proposal.
    bytes32 public constant AI_IMPACT_SCORE_THRESHOLD = keccak256("AI_IMPACT_SCORE_THRESHOLD");     // Minimum AI impact score needed for a proposal to pass.
    bytes32 public constant REPUTATION_FOR_ARTIFACT_STAGE_2 = keccak256("REPUTATION_FOR_ARTIFACT_STAGE_2"); // Reputation needed for artifact stage 2.
    bytes32 public constant REPUTATION_FOR_ARTIFACT_STAGE_3 = keccak256("REPUTATION_FOR_ARTIFACT_STAGE_3"); // Reputation needed for artifact stage 3.
    bytes32 public constant ARTIFACT_STAKE_VOTE_BOOST_PERCENT = keccak256("ARTIFACT_STAKE_VOTE_BOOST_PERCENT"); // Percentage boost to voting power when artifact is staked.

    // --- Events ---
    event GuildMemberJoined(address indexed member, string username, uint256 initialReputation);
    event ReputationEarned(address indexed member, uint256 amount, string reasonHash, uint256 newReputation);
    event GuildParameterUpdated(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event AIGuidanceOracleSet(address indexed newOracle);
    event GuardianSet(address indexed newGuardian);
    event ArtifactStaked(address indexed member);
    event ArtifactUnstaked(address indexed member);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string title, uint256 amountRequested);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event AIImpactScoreRecorded(uint256 indexed proposalId, uint256 score);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status);
    event FundsWithdrawn(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event QuestCreated(uint256 indexed questId, string title, uint256 reputationReward, uint256 deadline);
    event QuestSolutionSubmitted(uint256 indexed questId, address indexed member, string solutionHash);
    event QuestSolutionVerified(uint256 indexed questId, address indexed member, bool approved);

    // --- Constructor ---
    /// @notice Initializes the contract, granting the deployer DEFAULT_ADMIN_ROLE and ADMIN_ROLE.
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender()); // Deployer is also an initial Guild Admin.
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(GUARDIAN_ROLE, DEFAULT_ADMIN_ROLE);

        // Set initial configurable parameters for the guild.
        guildParameters[MIN_ETH_TO_JOIN] = 0.01 ether;       // Example: 0.01 ETH to join.
        guildParameters[MIN_REP_TO_PROPOSE] = 100;           // Example: 100 reputation to submit a proposal.
        guildParameters[PROPOSAL_VOTE_THRESHOLD_BPS] = 6000; // Example: 60% approval needed (6000 basis points).
        guildParameters[AI_IMPACT_SCORE_THRESHOLD] = 70;     // Example: AI score >= 70 to pass an impact proposal.
        guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_2] = 500; // Reputation for artifact to evolve to stage 2.
        guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_3] = 1500; // Reputation for artifact to evolve to stage 3.
        guildParameters[ARTIFACT_STAKE_VOTE_BOOST_PERCENT] = 25; // 25% boost in voting power when artifact is staked.
    }

    // --- I. Core Guild Administration & Setup ---

    /// @notice Sets or updates the guardian address. Only DEFAULT_ADMIN_ROLE can call this.
    ///         The guardian is responsible for executing approved treasury withdrawals.
    /// @param _newGuardian The address of the new guardian.
    function setGuardian(address _newGuardian) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newGuardian == address(0)) revert GuardianNotSet();
        if (guardian != address(0)) { // Revoke previous guardian's role if exists
             _revokeRole(GUARDIAN_ROLE, guardian);
        }
        guardian = _newGuardian;
        _grantRole(GUARDIAN_ROLE, _newGuardian);
        emit GuardianSet(_newGuardian);
    }

    /// @notice Sets the address of the external AI Guidance Oracle contract.
    ///         Only DEFAULT_ADMIN_ROLE can call this.
    /// @param _oracle The address of the IAIGuidanceOracle implementation.
    function setAIGuidanceOracle(address _oracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_oracle == address(0)) revert InvalidAIOracle();
        aiGuidanceOracle = IAIGuidanceOracle(_oracle);
        emit AIGuidanceOracleSet(_oracle);
    }

    /// @notice Updates a configurable guild parameter.
    ///         Only ADMIN_ROLE can call this.
    /// @param _paramName The keccak256 hash of the parameter name (e.g., `MIN_ETH_TO_JOIN`).
    /// @param _newValue The new `uint256` value for the parameter.
    function updateGuildParameter(bytes32 _paramName, uint256 _newValue) public onlyRole(ADMIN_ROLE) {
        if (_paramName == bytes32(0)) revert ParameterUpdateFailed();
        uint256 oldValue = guildParameters[_paramName];
        guildParameters[_paramName] = _newValue;
        emit GuildParameterUpdated(_paramName, oldValue, _newValue);
    }

    /// @notice Grants the `ADMIN_ROLE` to a specified address.
    ///         Only DEFAULT_ADMIN_ROLE can call this.
    /// @param _newAdmin The address to grant the admin role.
    function addGuildAdmin(address _newAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, _newAdmin);
    }

    /// @notice Revokes the `ADMIN_ROLE` from a specified address.
    ///         Only DEFAULT_ADMIN_ROLE can call this.
    /// @param _adminToRemove The address to revoke the admin role from.
    function removeGuildAdmin(address _adminToRemove) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, _adminToRemove);
    }

    // --- II. Membership & Reputation Management (Soulbound) ---

    /// @notice Allows a new user to join the Guild.
    ///         Requires sending `MIN_ETH_TO_JOIN` and provides initial reputation.
    ///         Mints an initial soulbound ANG Artifact for the new member.
    /// @param _username The desired username for the new member.
    function joinGuild(string calldata _username) public payable {
        if (members[_msgSender()].joinedTimestamp != 0) revert AlreadyGuildMember(); // Check if already a member.
        if (msg.value < guildParameters[MIN_ETH_TO_JOIN]) revert InvalidAmount();   // Check if enough ETH was sent.

        members[_msgSender()] = MemberDetails({
            username: _username,
            reputation: 100, // Initial reputation for new members.
            joinedTimestamp: block.timestamp,
            lastActiveTimestamp: block.timestamp,
            hasArtifact: true, // Mint artifact immediately upon joining.
            artifactStaked: false
        });

        // The initial artifact is implicitly "minted" by setting `hasArtifact = true`.
        // Its URI will be available via `getArtifactUri` based on initial reputation.

        emit GuildMemberJoined(_msgSender(), _username, members[_msgSender()].reputation);
    }

    /// @notice (Admin-only) Grants reputation to a member for validated contributions.
    ///         Updates the member's activity timestamp and potentially triggers artifact evolution.
    /// @param _member The address of the member to grant reputation to.
    /// @param _amount The amount of reputation to grant.
    /// @param _reasonHash A hash representing the reason or proof for earning reputation (off-chain storage reference).
    function earnReputation(address _member, uint256 _amount, string calldata _reasonHash) public onlyRole(ADMIN_ROLE) {
        if (members[_member].joinedTimestamp == 0) revert NotGuildMember(); // Member must be part of the guild.
        members[_member].reputation = members[_member].reputation.add(_amount);
        _updateMemberActivity(_member); // Update activity on reputation change.

        // Trigger artifact evolution if reputation crosses a predefined threshold.
        // This relies on `getArtifactUri` to dynamically reflect the new stage.
        // `evolveArtifactStage` would primarily be for an off-chain metadata service.
        if (members[_member].reputation >= guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_2] &&
            members[_member].reputation.sub(_amount) < guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_2]) {
            emit GuildParameterUpdated(keccak256("ARTIFACT_EVOLUTION_TRIGGERED"), uint256(uint160(_member)), 2);
        } else if (members[_member].reputation >= guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_3] &&
                   members[_member].reputation.sub(_amount) < guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_3]) {
            emit GuildParameterUpdated(keccak256("ARTIFACT_EVOLUTION_TRIGGERED"), uint256(uint160(_member)), 3);
        }
        
        emit ReputationEarned(_member, _amount, _reasonHash, members[_member].reputation);
    }

    /// @notice Retrieves the current reputation score of a member.
    /// @param _member The address of the member.
    /// @return The member's current reputation.
    function getMemberReputation(address _member) public view returns (uint256) {
        return members[_member].reputation;
    }

    /// @notice Returns a descriptive tier name based on the member's reputation score.
    /// @param _member The address of the member.
    /// @return The descriptive level string (e.g., "Aether Apprentice", "Nexus Elder").
    function getMemberLevel(address _member) public view returns (string memory) {
        uint256 reputation = members[_member].reputation;
        if (reputation >= guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_3]) {
            return "Nexus Elder";
        } else if (reputation >= guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_2]) {
            return "Aether Guide";
        } else if (reputation > 0) { // All joined members have at least 100 reputation.
            return "Aether Apprentice";
        } else {
            return "Uninitiated"; // For addresses not yet members.
        }
    }

    /// @notice Internal utility to update a member's `lastActiveTimestamp`.
    ///         Called on significant member interactions to track activity.
    /// @param _member The address of the member.
    function _updateMemberActivity(address _member) internal {
        members[_member].lastActiveTimestamp = block.timestamp;
    }

    // --- III. Dynamic NFT (ANG Artifact) Management ---

    /// @notice Generates a dynamic metadata URI for a member's ANG Artifact based on their reputation.
    ///         The artifact is Soulbound, tied to the member's address, and its metadata evolves.
    /// @param _member The address of the member.
    /// @return The dynamically generated metadata URI (data URI with JSON).
    function getArtifactUri(address _member) public view returns (string memory) {
        if (!members[_member].hasArtifact) revert NoArtifactFound();

        uint256 reputation = members[_member].reputation;
        uint256 stage;
        string memory level;

        // Determine the artifact's stage and corresponding level based on reputation thresholds.
        if (reputation >= guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_3]) {
            stage = 3;
            level = "Nexus Elder";
        } else if (reputation >= guildParameters[REPUTATION_FOR_ARTIFACT_STAGE_2]) {
            stage = 2;
            level = "Aether Guide";
        } else {
            stage = 1;
            level = "Aether Apprentice";
        }

        // Construct a JSON metadata string. In a real dApp, `image` would point to IPFS/HTTP,
        // and a dedicated metadata service would provide rich data.
        // For simplicity, we return a data URI containing the JSON directly.
        string memory imageUriBase = "ipfs://QmEXAMPLE_IPFS_HASH/"; // Placeholder IPFS base URI for images
        string memory jsonPart = string(abi.encodePacked(
            '{"name":"ANG Artifact #', _member.toHexString(), '",',
            '"description":"A Soulbound Artifact representing Aetheria Nexus Guild membership and progress, evolving with reputation.",',
            '"image":"', imageUriBase, "stage_", stage.toString(), ".png", '",',
            '"attributes":[{"trait_type":"Reputation Stage","value":"', stage.toString(), '"},',
            '{"trait_type":"Guild Level","value":"', level, '"},',
            '{"trait_type":"Reputation","value":"', reputation.toString(), '"}]}'
        ));

        return string(abi.encodePacked("data:application/json;utf8,", jsonPart));
    }

    /// @notice (Admin-only) Triggers an update to a member's artifact metadata.
    ///         This function is primarily for signaling off-chain systems to refresh metadata or assets.
    ///         The `getArtifactUri` function itself is dynamic.
    /// @param _member The address of the member whose artifact stage should be evolved.
    function evolveArtifactStage(address _member) public onlyRole(ADMIN_ROLE) {
        if (!members[_member].hasArtifact) revert NoArtifactFound();
        // This event serves as a signal for off-chain services (e.g., an indexer, NFT marketplace)
        // to update their cached metadata for this member's dynamic artifact.
        emit GuildParameterUpdated(keccak256("ARTIFACT_METADATA_REFRESH_TRIGGERED"), uint256(uint160(_member)), members[_member].reputation);
    }

    /// @notice Allows a guild member to "stake" their soulbound ANG Artifact.
    ///         This doesn't transfer the NFT but marks it to grant boosted voting power.
    function stakeArtifactForBoost() public {
        if (members[_msgSender()].joinedTimestamp == 0) revert NotGuildMember();
        if (!members[_msgSender()].hasArtifact) revert NoArtifactFound();
        if (members[_msgSender()].artifactStaked) revert ArtifactAlreadyStaked();

        members[_msgSender()].artifactStaked = true;
        _updateMemberActivity(_msgSender());
        emit ArtifactStaked(_msgSender());
    }

    /// @notice Allows a guild member to "unstake" their ANG Artifact, removing the voting power boost.
    function unstakeArtifactForBoost() public {
        if (members[_msgSender()].joinedTimestamp == 0) revert NotGuildMember();
        if (!members[_msgSender()].hasArtifact) revert NoArtifactFound();
        if (!members[_msgSender()].artifactStaked) revert ArtifactNotStaked();

        members[_msgSender()].artifactStaked = false;
        _updateMemberActivity(_msgSender());
        emit ArtifactUnstaked(_msgSender());
    }

    // --- IV. Treasury & Funding Mechanisms ---

    /// @notice Allows anyone to deposit ETH into the Guild's collective treasury.
    function depositFunds() public payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /// @notice (Admin-only) Submits a proposal to withdraw funds from the treasury.
    ///         These proposals require governance approval before the guardian can execute.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of ETH to withdraw.
    /// @param _reasonHash A hash representing the reason for withdrawal (off-chain storage reference).
    function submitTreasuryWithdrawalProposal(address _recipient, uint256 _amount, string calldata _reasonHash) public onlyRole(ADMIN_ROLE) {
        if (_recipient == address(0)) revert Unauthorized();
        if (_amount == 0) revert InvalidAmount();
        if (_amount > address(this).balance) revert InsufficientTreasuryFunds(_amount, address(this).balance);

        proposalCount = proposalCount.add(1);
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = "Treasury Withdrawal";
        newProposal.descriptionHash = _reasonHash;
        newProposal.proposer = _msgSender();
        newProposal.targetRecipient = _recipient;
        newProposal.amountRequested = _amount;
        newProposal.fundingDeadline = block.timestamp.add(7 days); // 7-day voting period for withdrawals.
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.aiImpactScore = 0; // AI score not strictly required for administrative withdrawals.
        newProposal.status = ProposalStatus.Active;
        newProposal.isTreasuryWithdrawal = true;

        emit ProposalSubmitted(newProposal.id, newProposal.proposer, newProposal.title, newProposal.amountRequested);
    }

    /// @notice (Guardian-only) Executes a treasury withdrawal proposal that has successfully passed governance.
    ///         Uses `nonReentrant` to protect against reentrancy attacks during fund transfers.
    /// @param _proposalId The ID of the treasury withdrawal proposal.
    function executeApprovedWithdrawal(uint256 _proposalId) public onlyRole(GUARDIAN_ROLE) nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || !proposal.isTreasuryWithdrawal) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Passed) revert WithdrawalNotApproved(); // Must be 'Passed' by governance.
        if (proposal.status == ProposalStatus.Executed) revert ProposalAlreadyFinalized(); // Cannot execute twice.
        if (address(this).balance < proposal.amountRequested) revert InsufficientTreasuryFunds(proposal.amountRequested, address(this).balance);

        proposal.status = ProposalStatus.Executed; // Mark as executed before transfer.
        (bool success,) = proposal.targetRecipient.call{value: proposal.amountRequested}("");
        require(success, "Withdrawal failed");

        emit FundsWithdrawn(_proposalId, proposal.targetRecipient, proposal.amountRequested);
    }

    // --- V. Impact Initiatives & Governance ---

    /// @notice Allows members with sufficient reputation to propose impact projects for funding.
    /// @param _title A concise title for the proposal.
    /// @param _descriptionHash A hash of the detailed proposal description (off-chain storage).
    /// @param _targetRecipient The address that will receive the funds if the proposal passes.
    /// @param _amountRequested The amount of ETH requested for the project.
    /// @param _fundingDeadline The timestamp when voting on this proposal ends.
    function submitImpactProposal(
        string calldata _title,
        string calldata _descriptionHash,
        address _targetRecipient,
        uint256 _amountRequested,
        uint256 _fundingDeadline
    ) public {
        if (members[_msgSender()].joinedTimestamp == 0) revert NotGuildMember();
        if (members[_msgSender()].reputation < guildParameters[MIN_REP_TO_PROPOSE]) {
            revert InsufficientReputation(guildParameters[MIN_REP_TO_PROPOSE], members[_msgSender()].reputation);
        }
        if (_targetRecipient == address(0)) revert Unauthorized(); // Cannot send to zero address.
        if (_amountRequested == 0) revert InvalidAmount();
        if (_fundingDeadline <= block.timestamp) revert VotingClosed(); // Deadline must be in the future.

        proposalCount = proposalCount.add(1);
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.title = _title;
        newProposal.descriptionHash = _descriptionHash;
        newProposal.proposer = _msgSender();
        newProposal.targetRecipient = _targetRecipient;
        newProposal.amountRequested = _amountRequested;
        newProposal.fundingDeadline = _fundingDeadline;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.aiImpactScore = 0; // AI score will be set by admin later.
        newProposal.status = ProposalStatus.Active;
        newProposal.isTreasuryWithdrawal = false; // This is a general impact proposal.

        _updateMemberActivity(_msgSender()); // Update activity for the proposer.
        emit ProposalSubmitted(newProposal.id, newProposal.proposer, newProposal.title, newProposal.amountRequested);
    }

    /// @notice Allows guild members to cast their vote on an active proposal.
    ///         Voting power is weighted by reputation and whether their artifact is staked.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert VotingClosed(); // Proposal must be active.
        if (block.timestamp > proposal.fundingDeadline) revert VotingClosed(); // Voting period must be open.
        if (members[_msgSender()].joinedTimestamp == 0) revert NotGuildMember(); // Only guild members can vote.
        if (proposal.hasVoted[_msgSender()]) revert VotingAlreadyDone();       // Prevent double voting.

        uint256 voteWeight = members[_msgSender()].reputation; // Base voting power is reputation.
        if (members[_msgSender()].artifactStaked) {
            // Apply a boost to voting power if the member's artifact is staked.
            voteWeight = voteWeight.add(voteWeight.mul(guildParameters[ARTIFACT_STAKE_VOTE_BOOST_PERCENT]).div(100));
        }

        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voteWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voteWeight);
        }
        proposal.hasVoted[_msgSender()] = true;

        _updateMemberActivity(_msgSender()); // Update activity for the voter.
        emit VoteCast(_proposalId, _msgSender(), _support, voteWeight);
    }

    /// @notice (Admin-only) Records the impact score provided by the external AI Oracle for a given proposal.
    ///         This score is a critical factor for impact proposal finalization.
    /// @param _proposalId The ID of the proposal.
    /// @param _aiScore The impact score (e.g., 0-100) returned by the AI oracle.
    function evaluateProposalWithAI(uint256 _proposalId, uint256 _aiScore) public onlyRole(ADMIN_ROLE) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.isTreasuryWithdrawal) revert Unauthorized(); // AI score is for impact proposals, not administrative withdrawals.
        if (proposal.status != ProposalStatus.Active) revert ProposalAlreadyFinalized(); // Only active proposals can be evaluated.
        if (aiGuidanceOracle == IAIGuidanceOracle(address(0))) revert InvalidAIOracle(); // Oracle must be set.

        // In a push-based oracle system, the admin submits the score received off-chain.
        // In a pull-based system, one might call `aiGuidanceOracle.getImpactScore(proposal.descriptionHash)` here.
        proposal.aiImpactScore = _aiScore;
        emit AIImpactScoreRecorded(_proposalId, _aiScore);
    }

    /// @notice Callable by anyone after the voting deadline. Finalizes the proposal's status and executes it if approved.
    ///         Uses `nonReentrant` to protect against reentrancy during fund transfers.
    /// @param _proposalId The ID of the proposal to finalize.
    function finalizeAndExecuteProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert ProposalAlreadyFinalized(); // Must be an active proposal.
        if (block.timestamp <= proposal.fundingDeadline) revert ProposalNotYetFinalized(); // Voting period must have ended.

        // Calculate total votes and check if 'for' votes meet the threshold.
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        bool passedVoteThreshold = totalVotes > 0 &&
                                  proposal.forVotes.mul(10000).div(totalVotes) >= guildParameters[PROPOSAL_VOTE_THRESHOLD_BPS];

        bool passedAIThreshold = true;
        if (!proposal.isTreasuryWithdrawal) { // AI score check is for impact proposals.
            passedAIThreshold = proposal.aiImpactScore >= guildParameters[AI_IMPACT_SCORE_THRESHOLD];
        }

        // Check if both voting and AI score (if applicable) thresholds are met.
        if (passedVoteThreshold && passedAIThreshold) {
            if (address(this).balance < proposal.amountRequested) {
                // Proposal passed governance but treasury lacks funds.
                proposal.status = ProposalStatus.Failed;
                emit ProposalFinalized(_proposalId, ProposalStatus.Failed);
                return;
            }
            proposal.status = ProposalStatus.Executed; // Mark as executed before transfer.
            (bool success,) = proposal.targetRecipient.call{value: proposal.amountRequested}("");
            require(success, "Proposal execution failed");
            emit FundsWithdrawn(_proposalId, proposal.targetRecipient, proposal.amountRequested);
        } else {
            proposal.status = ProposalStatus.Failed; // Proposal failed due to vote or AI score.
        }

        emit ProposalFinalized(_proposalId, proposal.status);
    }

    /// @notice Retrieves comprehensive details about a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing all relevant proposal details.
    function getProposalDetails(uint256 _proposalId) public view returns (
        uint256 id,
        string memory title,
        string memory descriptionHash,
        address proposer,
        address targetRecipient,
        uint256 amountRequested,
        uint256 fundingDeadline,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 aiImpactScore,
        ProposalStatus status,
        bool isTreasuryWithdrawal
    ) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        return (
            proposal.id,
            proposal.title,
            proposal.descriptionHash,
            proposal.proposer,
            proposal.targetRecipient,
            proposal.amountRequested,
            proposal.fundingDeadline,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.aiImpactScore,
            proposal.status,
            proposal.isTreasuryWithdrawal
        );
    }

    /// @notice Returns the current vote counts (for and against) for a proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return forVotes The total 'for' votes.
    /// @return againstVotes The total 'against' votes.
    function getProposalVoteCount(uint256 _proposalId) public view returns (uint256 forVotes, uint256 againstVotes) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        return (proposal.forVotes, proposal.againstVotes);
    }

    // --- VI. Gamified Engagement (Quests & Bounties) ---

    /// @notice (Admin-only) Creates a new quest for guild members to complete.
    /// @param _title The title of the quest.
    /// @param _descriptionHash A hash of the detailed quest description (off-chain storage).
    /// @param _reputationReward The reputation points awarded upon successful completion.
    /// @param _deadline The timestamp by which the quest must be completed.
    function createQuest(
        string calldata _title,
        string calldata _descriptionHash,
        uint256 _reputationReward,
        uint256 _deadline
    ) public onlyRole(ADMIN_ROLE) {
        if (_deadline <= block.timestamp) revert QuestDeadlinePassed(); // Quest deadline must be in the future.
        questCount = questCount.add(1);
        Quest storage newQuest = quests[questCount];
        newQuest.id = questCount;
        newQuest.title = _title;
        newQuest.descriptionHash = _descriptionHash;
        newQuest.reputationReward = _reputationReward;
        newQuest.deadline = _deadline;
        newQuest.active = true;

        emit QuestCreated(newQuest.id, newQuest.title, newQuest.reputationReward, newQuest.deadline);
    }

    /// @notice Allows a guild member to submit a hash of their solution for a quest.
    /// @param _questId The ID of the quest.
    /// @param _solutionHash A hash representing the member's solution or proof of completion.
    function submitQuestSolution(uint256 _questId, string calldata _solutionHash) public {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || !quest.active) revert QuestNotFound();
        if (block.timestamp > quest.deadline) revert QuestDeadlinePassed();
        if (members[_msgSender()].joinedTimestamp == 0) revert NotGuildMember();
        if (quest.completedBy[_msgSender()]) revert QuestAlreadyCompleted(); // Prevent resubmitting if already completed and approved.

        quest.submittedSolutions[_msgSender()] = _solutionHash; // Store the solution hash for admin verification.
        _updateMemberActivity(_msgSender());
        emit QuestSolutionSubmitted(_questId, _msgSender(), _solutionHash);
    }

    /// @notice (Admin-only) Verifies a submitted quest solution. If approved, the member earns reputation.
    /// @param _questId The ID of the quest.
    /// @param _member The address of the member whose solution is being verified.
    /// @param _approved True if the solution is approved, false otherwise.
    function verifyQuestSolution(uint256 _questId, address _member, bool _approved) public onlyRole(ADMIN_ROLE) {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || !quest.active) revert QuestNotFound();
        if (members[_member].joinedTimestamp == 0) revert NotGuildMember();
        if (!Strings.toSlice(quest.submittedSolutions[_member]).length > 0) revert QuestNotFound(); // No solution submitted by this member.

        if (_approved) {
            if (quest.completedBy[_member]) revert QuestAlreadyCompleted(); // Already approved for this member.
            quest.completedBy[_member] = true;
            // Grant reputation to the member upon successful verification.
            earnReputation(_member, quest.reputationReward, quest.descriptionHash); // Reuses `earnReputation` function.
        }
        // If not approved, no reputation is granted. The member might be able to resubmit if the quest is still active.

        emit QuestSolutionVerified(_questId, _member, _approved);
    }

    // --- Fallback & Receive ---

    /// @notice Allows receiving plain ETH transfers, which are treated as treasury deposits.
    receive() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }

    /// @notice Fallback function to handle calls to undefined functions, also treats as treasury deposits.
    fallback() external payable {
        emit FundsDeposited(_msgSender(), msg.value);
    }
}

```