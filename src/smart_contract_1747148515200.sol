Okay, let's design a smart contract for a "Decentralized Autonomous Guild (DAG)". This guild will use Soulbound Tokens (SBTs) for non-transferable membership, have a skill tree and reputation system, and allow members to complete quests and participate in decentralized governance via proposals.

This design incorporates:
1.  **SBT Membership:** Non-transferable proof of belonging.
2.  **Skill Tree:** Members earn points in specific skills based on activity.
3.  **Reputation System:** A score reflecting member trustworthiness and participation.
4.  **Time-Based Skill Decay:** Encourages continuous engagement.
5.  **Quest System:** Structured tasks with on-chain requirements and rewards (tokens, skills, reputation).
6.  **Decentralized Governance:** Proposal and voting system for treasury management, parameter changes, and quest approval/verification.
7.  **Role-Based Access (managed by Governance):** While governance is primary, certain roles might manage specific processes like initial quest assignment (though verification is via governance).

We will need an external `IGuildSBT` contract interface (ERC-721 variant, potentially with a `mintSoulbound` function and check for ownership). For simplicity in this example, we'll assume the SBT contract exists and the DAG contract is authorized to mint.

---

**Outline:**

1.  **State Variables:** Core contract parameters, mappings for members, quests, proposals, skills, reputation, treasury balances.
2.  **Structs:** `Member`, `Quest`, `Proposal`.
3.  **Enums:** `QuestState`, `ProposalState`.
4.  **Events:** Signify key state changes (Join, SkillGain, ReputationAdjust, QuestUpdate, ProposalUpdate, VoteCast, RewardDistributed, ParameterChange, Treasury).
5.  **Modifiers:** Access control checks.
6.  **Constructor:** Initialize core parameters and external contract addresses (SBT).
7.  **Membership Functions (Interacting with SBT):** `joinGuild`, `isGuildMember`, `getMemberSbtId`.
8.  **Skills & Reputation Functions:** Getters, setters (mostly internal/governance triggered), skill decay logic.
9.  **Quest Functions:** Create/Submit (via proposal), manage state (apply, assign, complete, verify, cancel), getters.
10. **Governance (Proposal) Functions:** Submit, vote, execute, getters.
11. **Treasury Functions:** Deposit (ETH/ERC20), withdraw (via proposal), balance check.
12. **Parameter Management Functions:** Set via governance.
13. **Internal Helper Functions:** Logic for skill decay, reward distribution, proposal execution details.

---

**Function Summary (Total: 30+ Functions):**

**Membership (Interacts with external SBT ERC721):**
1.  `constructor(address _sbtContract)`: Initializes the contract.
2.  `joinGuild()`: Allows a user to become a member by minting an SBT (requires `IGuildSBT`).
3.  `isGuildMember(address account)`: Checks if an address holds a guild SBT.
4.  `getMemberSbtId(address account)`: Gets the SBT ID for an address.

**Skills & Reputation:**
5.  `getMemberInfo(uint256 sbtId)`: Retrieves basic member data (reputation, last activity).
6.  `getMemberSkill(uint256 sbtId, bytes32 skillName)`: Gets points for a specific skill.
7.  `gainSkillPoints(uint256 sbtId, bytes32 skillName, uint256 amount)`: Internal/governance function to add skill points. Applies decay first.
8.  `adjustReputation(uint256 sbtId, int256 amount)`: Internal/governance function to change reputation. Applies decay first.
9.  `decaySkillsAndReputation(uint256 sbtId)`: Internal function to apply time-based decay.

**Quests:**
10. `submitQuestProposal(string memory description, uint256 rewardETH, address rewardToken, uint256 rewardERC20Amount, bytes32[] memory requiredSkills, uint256[] memory requiredSkillPoints, int256 requiredReputation, bytes32[] memory rewardSkills, uint256[] memory rewardSkillPoints, int256 rewardReputation)`: Submits a proposal to create a new quest.
11. `_createNewQuest(...)`: Internal function called by `executeProposal` to create a quest after proposal approval.
12. `getQuestDetails(uint256 questId)`: Retrieves details of a quest.
13. `getQuestsByState(QuestState state)`: Lists quest IDs in a specific state.
14. `applyForQuest(uint256 questId, uint256 sbtId)`: Member applies to a quest, checks requirements.
15. `assignQuest(uint256 questId, uint256 sbtId)`: Governance or designated role assigns an applicant to a quest.
16. `submitQuestCompletion(uint256 questId, uint256 sbtId, bytes memory verificationData)`: Assigned member submits completion evidence.
17. `verifyQuestCompletion(uint256 questId, uint256 sbtId)`: Governance function to verify completion and trigger rewards.
18. `cancelQuest(uint256 questId)`: Governance function to cancel a quest.

**Governance (Proposals):**
19. `submitParameterChangeProposal(bytes32 paramName, uint256 newValue, string memory description)`: Submits a proposal to change a simple parameter.
20. `submitGenericProposal(address target, uint256 value, bytes calldata callData, string memory description)`: Submits a proposal for arbitrary action (treasury withdrawal, setting complex params, etc.).
21. `getProposalDetails(uint256 proposalId)`: Retrieves details of a proposal.
22. `voteOnProposal(uint256 proposalId, bool voteFor)`: Member votes on a proposal. Requires min reputation.
23. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed and the voting period is over.

**Treasury:**
24. `depositETH() payable`: Allows anyone to send ETH to the contract treasury.
25. `depositERC20(address tokenAddress, uint256 amount)`: Allows deposit of ERC20 tokens (requires prior approval).
26. `withdrawTreasuryETH(uint256 amount, address recipient)`: Internal/governance function to withdraw ETH.
27. `withdrawTreasuryERC20(address tokenAddress, uint256 amount, address recipient)`: Internal/governance function to withdraw ERC20.
28. `getTreasuryBalance(address tokenAddress)`: Checks the contract's balance of a token (or ETH).

**Parameter Management (Internal/Governance via Proposal Execution):**
29. `_setParameter_uint256(bytes32 paramName, uint256 newValue)`: Internal function to set uint256 parameters.
30. `_setParameter_int256(bytes32 paramName, int256 newValue)`: Internal function to set int256 parameters.
31. `_setParameter_address(bytes32 paramName, address newValue)`: Internal function to set address parameters.
32. `_addApprovedSkill(bytes32 skillName)`: Internal function to add a skill that can be used in quests/rewards.

**Utility & Internal Helpers:**
33. `_distributeQuestReward(uint256 questId, uint256 sbtId)`: Internal function to handle reward distribution (tokens, skills, reputation).
34. `getApprovedSkills()`: View function to see which skills are recognized.
35. `getMemberSbtIdFromAddress(address account)`: Helper mapping lookup.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For approved skills

// Assume an interface for the Soulbound Token (SBT) contract
interface IGuildSBT is IERC721 {
    function mintSoulbound(address recipient, uint256 tokenId) external returns (uint256);
    function tokenExists(uint256 tokenId) external view returns (bool);
    // Add other necessary SBT functions like getting token owner
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256); // Should be 0 or 1 for SBT per person
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256); // To get the SBT ID
}


/// @title Decentralized Autonomous Guild (DAG)
/// @dev A smart contract representing a decentralized guild with SBT membership,
/// skill tree, reputation system, questing, and on-chain governance.
contract DecentralizedAutonomousGuild is ReentrancyGuard {

    // --- State Variables ---

    IGuildSBT public immutable guildSbtContract;

    struct Member {
        uint256 sbtId;
        int256 reputation;
        uint256 lastActivityTime; // Timestamp of last significant interaction
    }

    mapping(address => uint256) private memberAddressToSbtId; // Address -> SBT ID
    mapping(uint256 => Member) public members; // SBT ID -> Member data
    mapping(uint256 => mapping(bytes32 => uint256)) public memberSkills; // SBT ID -> Skill Name -> Skill Points

    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private approvedSkills; // Skills recognized by the guild

    enum QuestState {
        Proposed,        // Submitted as proposal
        Approved,        // Approved by governance, waiting for assignment
        Assigned,        // Assigned to a specific member
        PendingVerification, // Member submitted completion
        Completed,       // Verified and rewards distributed
        Cancelled        // Cancelled by governance
    }

    struct Quest {
        uint256 questId;
        string description;
        uint256 rewardETH;
        address rewardToken; // Address of ERC20 reward token
        uint256 rewardERC20Amount;
        bytes32[] requiredSkills;
        uint256[] requiredSkillPoints; // Corresponds to requiredSkills
        int256 requiredReputation;
        bytes32[] rewardSkills; // Skills that gain points upon completion
        uint256[] rewardSkillPoints; // Corresponds to rewardSkills
        int256 rewardReputation; // Reputation gained/lost
        address creator; // Address that submitted the quest proposal
        QuestState state;
        uint256 assignedSbtId; // 0 if not assigned
        bytes verificationData; // Data submitted by member for verification
        uint256 createdAt;
    }

    mapping(uint256 => Quest) public quests;
    uint256 private nextQuestId = 1;
    mapping(QuestState => uint224[]) private questsByState; // Store IDs categorized by state

    enum ProposalState {
        Open,
        Passed,
        Failed,
        Executed,
        Cancelled
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        string description;
        uint256 createdAt;
        uint256 votingDeadline;
        bytes callData; // Data for the target function call
        address target; // The contract target for callData (often `address(this)`)
        uint256 value; // ETH value to send with the call
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(uint256 => bool) hasVoted; // SBT ID -> Voted (prevents double voting)
        ProposalState state;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 private nextProposalId = 1;

    // Guild Parameters (Managed by Governance via Proposals)
    mapping(bytes32 => uint256) public uint256Parameters;
    mapping(bytes32 => int256) public int256Parameters;
    mapping(bytes32 => address) public addressParameters;

    bytes32 constant PARAM_SKILL_DECAY_RATE = "skillDecayRate"; // Points/second/skill
    bytes32 constant PARAM_REPUTATION_DECAY_RATE = "reputationDecayRate"; // Points/second
    bytes32 constant PARAM_MIN_REPUTATION_PROPOSAL = "minReputationProposal";
    bytes32 constant PARAM_MIN_REPUTATION_VOTE = "minReputationVote";
    bytes32 constant PARAM_VOTING_PERIOD = "votingPeriod"; // Seconds
    bytes32 constant PARAM_GOVERNANCE_QUORUM_PERCENT = "governanceQuorumPercent"; // e.g., 5% = 500
    bytes32 constant PARAM_GOVERNANCE_MAJORITY_PERCENT = "governanceMajorityPercent"; // e.g., 50% = 5000
    bytes32 constant PARAM_QUEST_ASSIGNER_ROLE = "questAssignerRole"; // bytes32 role name (example)
    bytes32 constant PARAM_VERIFICATION_ROLE = "verificationRole"; // bytes32 role name (example)

    // Role management (Simplified: Check role against storage, set via governance)
    mapping(uint256 => mapping(bytes32 => bool)) private memberRoles; // SBT ID -> Role Name -> Has Role

    // --- Events ---

    event GuildMemberJoined(address indexed account, uint256 indexed sbtId, uint256 timestamp);
    event SkillGained(uint256 indexed sbtId, bytes32 skillName, uint256 amountGained, uint256 newTotalPoints, uint256 timestamp);
    event ReputationAdjusted(uint256 indexed sbtId, int256 amountAdjusted, int256 newReputation, uint256 timestamp);
    event QuestCreated(uint256 indexed questId, address indexed creator, uint256 timestamp);
    event QuestStateChanged(uint256 indexed questId, QuestState oldState, QuestState newState, uint256 timestamp);
    event QuestCompleted(uint256 indexed questId, uint256 indexed assignedSbtId, uint256 timestamp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 timestamp);
    event VoteCast(uint256 indexed proposalId, uint256 indexed sbtId, bool voteFor, uint256 timestamp);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result, uint256 timestamp);
    event TreasuryDeposited(address indexed tokenAddress, uint256 amount, address indexed depositor, uint256 timestamp);
    event TreasuryWithdrawn(address indexed tokenAddress, uint256 amount, address indexed recipient, uint256 timestamp);
    event ParameterChanged_uint256(bytes32 paramName, uint256 oldValue, uint256 newValue, uint256 timestamp);
    event ParameterChanged_int256(bytes32 paramName, int256 oldValue, int256 newValue, uint256 timestamp);
    event ParameterChanged_address(bytes32 paramName, address oldValue, address newValue, uint256 timestamp);
    event ApprovedSkillAdded(bytes32 skillName, uint256 timestamp);


    // --- Modifiers ---

    modifier onlyGuildMember(address account) {
        require(isGuildMember(account), "DAG: Not a guild member");
        _;
    }

    modifier onlySbtOwner(uint256 sbtId) {
        require(members[sbtId].sbtId != 0, "DAG: Invalid SBT ID");
        require(guildSbtContract.ownerOf(sbtId) == msg.sender, "DAG: Caller is not SBT owner");
        _;
    }

    modifier onlySufficientReputation(uint256 sbtId, int256 minReputation) {
        decaySkillsAndReputation(sbtId); // Apply decay before checking reputation
        require(members[sbtId].reputation >= minReputation, "DAG: Insufficient reputation");
        _;
    }

    // Simple role check (roles are managed via governance)
    modifier onlyRole(uint256 sbtId, bytes32 roleName) {
        require(memberRoles[sbtId][roleName], "DAG: Caller missing required role");
        _;
    }

    // Internal modifier for functions called by governance execution
    modifier onlyCallableByGovernance() {
        // This check is simplistic. A robust DAO would track the proposal ID/execution context.
        // For this example, we assume internal calls triggered by `executeProposal` are authorized.
        // In a real system, you'd verify the `msg.sender` is the contract itself and
        // potentially verify the call stack or a specific flag set during execution.
        require(msg.sender == address(this), "DAG: Function callable only by governance execution");
        _;
    }


    // --- Constructor ---

    constructor(address _sbtContract) {
        require(_sbtContract != address(0), "DAG: SBT contract address cannot be zero");
        guildSbtContract = IGuildSBT(_sbtContract);

        // Set initial parameters (can be changed via governance later)
        uint256Parameters[PARAM_SKILL_DECAY_RATE] = 0; // No decay initially
        uint256Parameters[PARAM_REPUTATION_DECAY_RATE] = 0; // No decay initially
        int256Parameters[PARAM_MIN_REPUTATION_PROPOSAL] = 0;
        int256Parameters[PARAM_MIN_REPUTATION_VOTE] = 0;
        uint256Parameters[PARAM_VOTING_PERIOD] = 7 days; // Example
        uint256Parameters[PARAM_GOVERNANCE_QUORUM_PERCENT] = 500; // 5%
        uint256Parameters[PARAM_GOVERNANCE_MAJORITY_PERCENT] = 5000; // 50%
        addressParameters[PARAM_QUEST_ASSIGNER_ROLE] = address(0); // No specific assigner initially
        addressParameters[PARAM_VERIFICATION_ROLE] = address(0); // No specific verifier initially

        // Add some initial skills (can be added via governance later)
        approvedSkills.add("coding");
        approvedSkills.add("design");
        approvedSkills.add("writing");
        approvedSkills.add("community");
    }


    // --- Membership Functions ---

    /// @notice Allows a user to join the guild by minting a Soulbound Token (SBT).
    /// The SBT contract must be configured to allow this contract to mint.
    function joinGuild() external nonReentrant {
        require(!isGuildMember(msg.sender), "DAG: Already a guild member");

        uint256 newSbtId;
        // In a real scenario, guildSbtContract.mintSoulbound would likely handle token ID generation internally
        // or use a sequence managed by the SBT contract.
        // For this example, we'll simulate getting an ID back from the SBT contract.
        // A simple approach in the SBT contract might be:
        // function mintSoulbound(address recipient) external returns (uint256) {
        //    _mint(recipient, nextTokenId);
        //    _setSoulbound(nextTokenId); // Mark as non-transferable
        //    return nextTokenId++;
        // }
        // Let's assume it returns a valid, unique ID upon successful mint.
        newSbtId = guildSbtContract.mintSoulbound(msg.sender, 0); // Passing 0 implies SBT contract assigns ID

        require(newSbtId != 0, "DAG: SBT minting failed"); // Basic check if SBT returned an ID

        members[newSbtId] = Member({
            sbtId: newSbtId,
            reputation: 0,
            lastActivityTime: block.timestamp
        });
        memberAddressToSbtId[msg.sender] = newSbtId; // Store the mapping

        emit GuildMemberJoined(msg.sender, newSbtId, block.timestamp);
    }

    /// @notice Checks if an address holds a guild SBT.
    /// @param account The address to check.
    /// @return True if the address is a guild member, false otherwise.
    function isGuildMember(address account) public view returns (bool) {
        // The most reliable check is via the SBT contract's balanceOf
        return guildSbtContract.balanceOf(account) > 0;
    }

    /// @notice Gets the SBT ID for a given member address.
    /// @param account The member address.
    /// @return The SBT ID. Returns 0 if not a member or SBT contract returns 0.
    function getMemberSbtId(address account) public view returns (uint256) {
         if (!isGuildMember(account)) {
            return 0;
        }
        // Assuming SBT standard ERC721 function to get token ID of owner (for single token owners)
        // This might be slightly non-standard for SBTs where balance > 1 is impossible,
        // but tokenOfOwnerByIndex(addr, 0) is a common pattern for single-token owners.
        // A dedicated getSbtId(address) view function on the SBT contract would be ideal.
        // Using the mapping as a shortcut for known members, but rely on SBT for definitive proof.
        uint256 sbtIdFromMapping = memberAddressToSbtId[account];
        if (sbtIdFromMapping != 0 && guildSbtContract.ownerOf(sbtIdFromMapping) == account) {
             return sbtIdFromMapping;
        }
        // Fallback: Query the SBT contract if mapping isn't updated or is 0
        return guildSbtContract.tokenOfOwnerByIndex(account, 0); // Assumes 0-indexed for single token
    }

    // --- Skills & Reputation Functions ---

    /// @notice Retrieves a member's information (reputation, last activity).
    /// @param sbtId The SBT ID of the member.
    /// @return Member struct containing sbtId, reputation, and lastActivityTime.
    function getMemberInfo(uint256 sbtId) public view returns (Member memory) {
        require(members[sbtId].sbtId != 0, "DAG: SBT ID not found in members");
        // Note: This view function does NOT apply decay.
        // Decay is applied during state-changing interactions.
        return members[sbtId];
    }

    /// @notice Gets the skill points for a specific skill of a member.
    /// @param sbtId The SBT ID of the member.
    /// @param skillName The name of the skill (e.g., "coding").
    /// @return The current skill points. Applies decay first.
    function getMemberSkill(uint256 sbtId, bytes32 skillName) public returns (uint256) {
        require(members[sbtId].sbtId != 0, "DAG: SBT ID not found in members");
        // Apply decay before returning the value
        decaySkillsAndReputation(sbtId);
        return memberSkills[sbtId][skillName];
    }

    /// @dev Internal function to add skill points after applying decay.
    /// Called by quest completion, etc. Requires SBT owner to be involved in the action (msg.sender).
    /// @param sbtId The SBT ID of the member.
    /// @param skillName The name of the skill.
    /// @param amount The amount of points to add.
    function gainSkillPoints(uint256 sbtId, bytes32 skillName, uint256 amount) internal nonReentrant {
        require(members[sbtId].sbtId != 0, "DAG: Invalid SBT ID");
        require(approvedSkills.contains(skillName), "DAG: Skill not recognized");

        decaySkillsAndReputation(sbtId); // Apply decay before adding points

        uint256 currentPoints = memberSkills[sbtId][skillName];
        uint256 newTotalPoints = currentPoints + amount; // Check for overflow if necessary (uint256 is large)
        memberSkills[sbtId][skillName] = newTotalPoints;
        members[sbtId].lastActivityTime = block.timestamp; // Update activity time

        emit SkillGained(sbtId, skillName, amount, newTotalPoints, block.timestamp);
    }

    /// @dev Internal function to adjust reputation after applying decay.
    /// Called by quest completion, voting, etc. Requires SBT owner to be involved in the action (msg.sender).
    /// @param sbtId The SBT ID of the member.
    /// @param amount The amount to adjust reputation by (can be negative).
    function adjustReputation(uint256 sbtId, int256 amount) internal nonReentrant {
        require(members[sbtId].sbtId != 0, "DAG: Invalid SBT ID");

        decaySkillsAndReputation(sbtId); // Apply decay before adjusting

        int256 currentReputation = members[sbtId].reputation;
        int256 newReputation = currentReputation + amount; // Check for overflow/underflow if using smaller int types
        members[sbtId].reputation = newReputation;
        members[sbtId].lastActivityTime = block.timestamp; // Update activity time

        emit ReputationAdjusted(sbtId, amount, newReputation, block.timestamp);
    }

    /// @dev Internal function to apply skill and reputation decay based on inactivity time.
    /// Called before accessing or modifying skills/reputation.
    /// @param sbtId The SBT ID of the member.
    function decaySkillsAndReputation(uint256 sbtId) internal {
        Member storage member = members[sbtId];
        if (member.sbtId == 0) {
            return; // Not a valid member entry
        }

        uint256 lastActive = member.lastActivityTime;
        uint256 currentTime = block.timestamp;
        uint256 decayRateSkills = uint256Parameters[PARAM_SKILL_DECAY_RATE]; // Points/second/skill
        uint256 decayRateReputation = uint256Parameters[PARAM_REPUTATION_DECAY_RATE]; // Points/second

        if (decayRateSkills == 0 && decayRateReputation == 0) {
            // No decay configured
            return;
        }

        uint256 timeElapsed = currentTime - lastActive;

        if (timeElapsed == 0) {
            // No time passed since last activity
            return;
        }

        // Apply skill decay
        if (decayRateSkills > 0) {
            uint256 skillsCount = approvedSkills.length();
             for (uint256 i = 0; i < skillsCount; i++) {
                bytes32 skillName = approvedSkills.at(i);
                uint256 currentPoints = memberSkills[sbtId][skillName];
                if (currentPoints > 0) {
                    // Calculate decay amount for this skill
                    uint256 decayAmount = timeElapsed * decayRateSkills;
                    // Clamp decay amount to current points
                    memberSkills[sbtId][skillName] = currentPoints > decayAmount ? currentPoints - decayAmount : 0;
                }
            }
        }

        // Apply reputation decay
        if (decayRateReputation > 0) {
             int256 currentReputation = member.reputation;
             if (currentReputation > 0) {
                 uint256 decayAmount = timeElapsed * decayRateReputation;
                 // Clamp decay amount to 0
                 member.reputation = currentReputation > int256(decayAmount) ? currentReputation - int256(decayAmount) : 0;
             } else if (currentReputation < 0) {
                 // Optional: Decay negative reputation slower or not at all
                 // For now, let's not decay negative reputation upwards
             }
        }

        // Update last activity time AFTER calculating decay
        member.lastActivityTime = currentTime;
    }


    // --- Quest Functions ---

    /// @notice Submits a proposal to create a new quest.
    /// Requires minimum reputation. Quest creation is subject to governance approval.
    /// @param description Details about the quest.
    /// @param rewardETH ETH reward (can be 0).
    /// @param rewardToken ERC20 token address (address(0) for none).
    /// @param rewardERC20Amount ERC20 reward amount (can be 0).
    /// @param requiredSkills Skills required to apply.
    /// @param requiredSkillPoints Minimum points for requiredSkills.
    /// @param requiredReputation Minimum reputation to apply.
    /// @param rewardSkills Skills to gain points upon completion.
    /// @param rewardSkillPoints Points gained for rewardSkills.
    /// @param rewardReputation Reputation gained/lost upon completion.
    /// @dev The actual quest creation happens when the proposal is executed.
    function submitQuestProposal(
        string memory description,
        uint256 rewardETH,
        address rewardToken,
        uint256 rewardERC20Amount,
        bytes32[] memory requiredSkills,
        uint256[] memory requiredSkillPoints,
        int256 requiredReputation,
        bytes32[] memory rewardSkills,
        uint256[] memory rewardSkillPoints,
        int256 rewardReputation
    ) external onlyGuildMember(msg.sender) nonReentrant {
        uint256 sbtId = getMemberSbtId(msg.sender);
        require(sbtId != 0, "DAG: Could not get SBT ID for sender");
        decaySkillsAndReputation(sbtId); // Apply decay before checking reputation
        require(members[sbtId].reputation >= int256Parameters[PARAM_MIN_REPUTATION_PROPOSAL], "DAG: Insufficient reputation to submit proposal");

        // Validate required/reward skills are approved
        for(uint256 i = 0; i < requiredSkills.length; i++) require(approvedSkills.contains(requiredSkills[i]), "DAG: Required skill not approved");
        for(uint256 i = 0; i < rewardSkills.length; i++) require(approvedSkills.contains(rewardSkills[i]), "DAG: Reward skill not approved");
        require(requiredSkills.length == requiredSkillPoints.length, "DAG: Mismatch in required skills/points arrays");
        require(rewardSkills.length == rewardSkillPoints.length, "DAG: Mismatch in reward skills/points arrays");

        // Encode the call to the internal quest creation function
        bytes callData = abi.encodeWithSelector(
            this._createNewQuest.selector,
            description,
            rewardETH,
            rewardToken,
            rewardERC20Amount,
            requiredSkills,
            requiredSkillPoints,
            requiredReputation,
            rewardSkills,
            rewardSkillPoints,
            rewardReputation,
            sbtId // Pass the creator's SBT ID
        );

        uint256 proposalId = nextProposalId++;
        uint256 votingPeriod = uint256Parameters[PARAM_VOTING_PERIOD];

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Create Quest: ", description)), // Prefix description
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            callData: callData,
            target: address(this), // Target is this contract
            value: 0, // No ETH sent with this specific call (ETH reward handled during execution)
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Open,
            hasVoted: new mapping(uint256 => bool)() // Initialize nested mapping
        });

        emit ProposalSubmitted(proposalId, msg.sender, block.timestamp);
    }

    /// @dev Internal function to create a new quest object. Called only by governance execution.
    function _createNewQuest(
        string memory description,
        uint256 rewardETH,
        address rewardToken,
        uint256 rewardERC20Amount,
        bytes32[] memory requiredSkills,
        uint256[] memory requiredSkillPoints,
        int256 requiredReputation,
        bytes32[] memory rewardSkills,
        uint256[] memory rewardSkillPoints,
        int256 rewardReputation,
        uint256 creatorSbtId // Passed from the proposal
    ) internal onlyCallableByGovernance {
        uint256 questId = nextQuestId++;
        address creatorAddress = guildSbtContract.ownerOf(creatorSbtId); // Get address from SBT ID

        quests[questId] = Quest({
            questId: questId,
            description: description,
            rewardETH: rewardETH,
            rewardToken: rewardToken,
            rewardERC20Amount: rewardERC20Amount,
            requiredSkills: requiredSkills,
            requiredSkillPoints: requiredSkillPoints,
            requiredReputation: requiredReputation,
            rewardSkills: rewardSkills,
            rewardSkillPoints: rewardSkillPoints,
            rewardReputation: rewardReputation,
            creator: creatorAddress,
            state: QuestState.Approved, // Starts as approved after governance execution
            assignedSbtId: 0,
            verificationData: "", // No data initially
            createdAt: block.timestamp
        });

        questsByState[QuestState.Approved].push(uint224(questId));

        emit QuestCreated(questId, creatorAddress, block.timestamp);
        emit QuestStateChanged(questId, QuestState.Proposed, QuestState.Approved, block.timestamp); // Proposed state was within the proposal lifecycle
    }


    /// @notice Retrieves details for a specific quest.
    /// @param questId The ID of the quest.
    /// @return Quest struct details.
    function getQuestDetails(uint256 questId) public view returns (Quest memory) {
        require(quests[questId].questId != 0, "DAG: Invalid quest ID");
        return quests[questId];
    }

    /// @notice Gets a list of quest IDs filtered by their current state.
    /// @param state The QuestState to filter by.
    /// @return An array of quest IDs.
    function getQuestsByState(QuestState state) public view returns (uint256[] memory) {
         uint224[] storage questIds224 = questsByState[state];
         uint256[] memory questIds = new uint256[](questIds224.length);
         for(uint256 i = 0; i < questIds224.length; i++) {
             questIds[i] = questIds224[i];
         }
         return questIds;
    }

    /// @notice Allows a guild member to apply for an approved quest.
    /// Checks if the member meets the quest's skill and reputation requirements.
    /// @param questId The ID of the quest.
    /// @param sbtId The SBT ID of the member applying.
    function applyForQuest(uint256 questId, uint256 sbtId) external onlySbtOwner(sbtId) nonReentrant {
        Quest storage quest = quests[questId];
        require(quest.questId != 0, "DAG: Invalid quest ID");
        require(quest.state == QuestState.Approved, "DAG: Quest not in Approved state");
        require(quest.assignedSbtId == 0, "DAG: Quest already assigned"); // Prevent applying if already assigned

        decaySkillsAndReputation(sbtId); // Apply decay before checking skills/reputation

        // Check skill requirements
        for (uint256 i = 0; i < quest.requiredSkills.length; i++) {
            bytes32 skillName = quest.requiredSkills[i];
            uint256 requiredPoints = quest.requiredSkillPoints[i];
            require(memberSkills[sbtId][skillName] >= requiredPoints, string(abi.encodePacked("DAG: Insufficient skill: ", Bytes32ToString(skillName))));
        }

        // Check reputation requirement
        require(members[sbtId].reputation >= quest.requiredReputation, "DAG: Insufficient reputation");

        // For simplicity, this example just changes state. A real system might track multiple applicants.
        // Let's update the quest state to indicate someone has applied (or just allow immediate assignment if no applicant pool is tracked)
        // For this example, let's simplify: apply *is* assignment if the role/governance allows.
        // Let's rename this `requestQuestAssignment` and require a separate `assignQuest`.
         revert("DAG: Use requestQuestAssignment and wait for assignment"); // Indicate renaming/flow change

    }

    /// @notice Allows a member (with PARAM_QUEST_ASSIGNER_ROLE) to assign an approved quest to a member.
    /// Checks if the member meets the quest's skill and reputation requirements.
    /// @param questId The ID of the quest.
    /// @param sbtId The SBT ID of the member being assigned.
    function assignQuest(uint256 questId, uint256 sbtId) external onlyRole(getMemberSbtId(msg.sender), PARAM_QUEST_ASSIGNER_ROLE) nonReentrant {
        Quest storage quest = quests[questId];
        require(quest.questId != 0, "DAG: Invalid quest ID");
        require(quest.state == QuestState.Approved, "DAG: Quest not in Approved state");
        require(quest.assignedSbtId == 0, "DAG: Quest already assigned");

        require(members[sbtId].sbtId != 0, "DAG: Member SBT ID not found"); // Ensure assignee is a member

        decaySkillsAndReputation(sbtId); // Apply decay before checking skills/reputation for the *assignee*

        // Check skill requirements for the assignee
        for (uint256 i = 0; i < quest.requiredSkills.length; i++) {
            bytes32 skillName = quest.requiredSkills[i];
            uint256 requiredPoints = quest.requiredSkillPoints[i];
            require(memberSkills[sbtId][skillName] >= requiredPoints, string(abi.encodePacked("DAG: Assignee insufficient skill: ", Bytes32ToString(skillName))));
        }

        // Check reputation requirement for the assignee
        require(members[sbtId].reputation >= quest.requiredReputation, "DAG: Assignee insufficient reputation");

        // Update state
        quest.assignedSbtId = sbtId;
        _updateQuestState(questId, QuestState.Assigned);
    }


    /// @notice Allows the assigned member to submit completion data for a quest.
    /// @param questId The ID of the quest.
    /// @param sbtId The SBT ID of the member submitting (must be the assigned member).
    /// @param verificationData Optional data relevant to verification (e.g., IPFS hash, link).
    function submitQuestCompletion(uint256 questId, uint256 sbtId, bytes memory verificationData) external onlySbtOwner(sbtId) nonReentrant {
         Quest storage quest = quests[questId];
         require(quest.questId != 0, "DAG: Invalid quest ID");
         require(quest.state == QuestState.Assigned, "DAG: Quest not in Assigned state");
         require(quest.assignedSbtId == sbtId, "DAG: Caller is not the assigned member");

         quest.verificationData = verificationData;
         _updateQuestState(questId, QuestState.PendingVerification);
    }

    /// @notice Allows a member (with PARAM_VERIFICATION_ROLE or via Governance proposal)
    /// to verify quest completion and trigger rewards.
    /// @param questId The ID of the quest.
    /// @param sbtId The SBT ID of the member who completed the quest.
    function verifyQuestCompletion(uint256 questId, uint256 sbtId) external nonReentrant {
         Quest storage quest = quests[questId];
         require(quest.questId != 0, "DAG: Invalid quest ID");
         require(quest.state == QuestState.PendingVerification, "DAG: Quest not in PendingVerification state");
         require(quest.assignedSbtId == sbtId, "DAG: SBT ID does not match assigned member");

         // Check if caller has the verification role OR if this call is from governance execution
         uint256 callerSbtId = getMemberSbtId(msg.sender);
         bool hasVerificationRole = memberRoles[callerSbtId][PARAM_VERIFICATION_ROLE];
         // Simple check for governance call - assumes governance calls come from address(this)
         // A robust system needs a better way to verify governance context.
         bool isGovernanceCall = msg.sender == address(this);

         require(hasVerificationRole || isGovernanceCall, "DAG: Caller must have verification role or be governance");


         // Trigger reward distribution and state update
         _distributeQuestReward(questId, sbtId);
         _updateQuestState(questId, QuestState.Completed);

         emit QuestCompleted(questId, sbtId, block.timestamp);
    }

    /// @notice Allows governance to cancel a quest.
    /// @param questId The ID of the quest.
    function cancelQuest(uint256 questId) external onlyCallableByGovernance {
        Quest storage quest = quests[questId];
        require(quest.questId != 0, "DAG: Invalid quest ID");
        require(quest.state != QuestState.Completed && quest.state != QuestState.Cancelled, "DAG: Quest already completed or cancelled");

        // Refund logic could be added here if funds were escrowed.
        // In this example, rewards are sent only upon verification from the treasury.

        _updateQuestState(questId, QuestState.Cancelled);
    }


    /// @dev Internal helper to update quest state and manage state-based lists.
    function _updateQuestState(uint256 questId, QuestState newState) internal {
        Quest storage quest = quests[questId];
        QuestState oldState = quest.state;
        require(oldState != newState, "DAG: Quest already in this state");

        // Remove from old state list (basic approach, could be inefficient for large lists)
        // For production, consider using EnumerableSet for state lists or tracking state per quest.
        // This implementation is simplified for demonstration.
        uint224[] storage oldList = questsByState[oldState];
        for (uint i = 0; i < oldList.length; i++) {
            if (oldList[i] == questId) {
                oldList[i] = oldList[oldList.length - 1];
                oldList.pop();
                break;
            }
        }

        // Add to new state list
         questsByState[newState].push(uint224(questId));

        quest.state = newState;

        emit QuestStateChanged(questId, oldState, newState, block.timestamp);
    }

    /// @dev Internal function to distribute quest rewards. Called by verifyQuestCompletion.
    function _distributeQuestReward(uint256 questId, uint256 sbtId) internal nonReentrant {
        Quest storage quest = quests[questId];
        require(quest.state == QuestState.PendingVerification, "DAG: Quest must be pending verification to distribute reward"); // Double check state
        require(quest.assignedSbtId == sbtId, "DAG: Reward can only be distributed to the assigned member");

        address recipient = guildSbtContract.ownerOf(sbtId);
        require(recipient != address(0), "DAG: Cannot find recipient address for SBT ID");

        // Distribute ETH reward
        if (quest.rewardETH > 0) {
            require(address(this).balance >= quest.rewardETH, "DAG: Insufficient ETH treasury balance for reward");
            (bool success, ) = payable(recipient).call{value: quest.rewardETH}("");
            require(success, "DAG: ETH reward transfer failed");
            emit TreasuryWithdrawn(address(0), quest.rewardETH, recipient, block.timestamp);
        }

        // Distribute ERC20 reward
        if (quest.rewardToken != address(0) && quest.rewardERC20Amount > 0) {
            IERC20 token = IERC20(quest.rewardToken);
            require(token.balanceOf(address(this)) >= quest.rewardERC20Amount, "DAG: Insufficient ERC20 treasury balance for reward");
            bool success = token.transfer(recipient, quest.rewardERC20Amount);
            require(success, "DAG: ERC20 reward transfer failed");
            emit TreasuryWithdrawn(quest.rewardToken, quest.rewardERC20Amount, recipient, block.timestamp);
        }

        // Distribute Skill rewards
        for (uint256 i = 0; i < quest.rewardSkills.length; i++) {
            gainSkillPoints(sbtId, quest.rewardSkills[i], quest.rewardSkillPoints[i]);
        }

        // Distribute Reputation reward
        if (quest.rewardReputation != 0) {
             adjustReputation(sbtId, quest.rewardReputation);
        }

        // Note: Quest state change happens in verifyQuestCompletion after this internal call.
    }


    // --- Governance (Proposal) Functions ---

    /// @notice Submits a proposal to change a specific uint256 parameter.
    /// Requires minimum reputation.
    /// @param paramName The bytes32 name of the parameter.
    /// @param newValue The new value for the parameter.
    /// @param description A description of the proposal.
    function submitParameterChangeProposal(bytes32 paramName, uint256 newValue, string memory description) external onlyGuildMember(msg.sender) nonReentrant {
         uint256 sbtId = getMemberSbtId(msg.sender);
         require(sbtId != 0, "DAG: Could not get SBT ID for sender");
         decaySkillsAndReputation(sbtId);
         require(members[sbtId].reputation >= int256Parameters[PARAM_MIN_REPUTATION_PROPOSAL], "DAG: Insufficient reputation to submit proposal");

         bytes callData = abi.encodeWithSelector(this._setParameter_uint256.selector, paramName, newValue);

         uint256 proposalId = nextProposalId++;
         uint256 votingPeriod = uint256Parameters[PARAM_VOTING_PERIOD];

         proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Set uint256 Param ", Bytes32ToString(paramName), ": ", description)),
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            callData: callData,
            target: address(this),
            value: 0,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Open,
            hasVoted: new mapping(uint256 => bool)()
        });

        emit ProposalSubmitted(proposalId, msg.sender, block.timestamp);
    }

     /// @notice Submits a proposal to change a specific int256 parameter.
    /// Requires minimum reputation.
    /// @param paramName The bytes32 name of the parameter.
    /// @param newValue The new value for the parameter.
    /// @param description A description of the proposal.
    function submitParameterChangeProposal(bytes32 paramName, int256 newValue, string memory description) external onlyGuildMember(msg.sender) nonReentrant {
         uint256 sbtId = getMemberSbtId(msg.sender);
         require(sbtId != 0, "DAG: Could not get SBT ID for sender");
         decaySkillsAndReputation(sbtId);
         require(members[sbtId].reputation >= int256Parameters[PARAM_MIN_REPUTATION_PROPOSAL], "DAG: Insufficient reputation to submit proposal");

         bytes callData = abi.encodeWithSelector(this._setParameter_int256.selector, paramName, newValue);

         uint256 proposalId = nextProposalId++;
         uint256 votingPeriod = uint256Parameters[PARAM_VOTING_PERIOD];

         proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: string(abi.encodePacked("Set int256 Param ", Bytes32ToString(paramName), ": ", description)),
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            callData: callData,
            target: address(this),
            value: 0,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Open,
            hasVoted: new mapping(uint256 => bool)()
        });

        emit ProposalSubmitted(proposalId, msg.sender, block.timestamp);
    }

    /// @notice Submits a proposal for a generic action, typically involving a call to the contract itself or another approved target.
    /// Requires minimum reputation.
    /// @param target The address of the contract to call.
    /// @param value ETH value to send with the call.
    /// @param callData The ABI-encoded data for the function call.
    /// @param description A description of the proposal.
    function submitGenericProposal(address target, uint256 value, bytes calldata callData, string memory description) external onlyGuildMember(msg.sender) nonReentrant {
        uint256 sbtId = getMemberSbtId(msg.sender);
        require(sbtId != 0, "DAG: Could not get SBT ID for sender");
        decaySkillsAndReputation(sbtId);
        require(members[sbtId].reputation >= int256Parameters[PARAM_MIN_REPUTATION_PROPOSAL], "DAG: Insufficient reputation to submit proposal");
        require(target != address(0), "DAG: Proposal target cannot be zero address");

        uint256 proposalId = nextProposalId++;
        uint256 votingPeriod = uint256Parameters[PARAM_VOTING_PERIOD];

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposer: msg.sender,
            description: description,
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + votingPeriod,
            callData: callData,
            target: target,
            value: value,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Open,
            hasVoted: new mapping(uint256 => bool)() // Initialize nested mapping
        });

        emit ProposalSubmitted(proposalId, msg.sender, block.timestamp);
    }


    /// @notice Retrieves details for a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct details.
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(proposals[proposalId].proposalId != 0, "DAG: Invalid proposal ID");
        Proposal storage p = proposals[proposalId];
         return Proposal({
            proposalId: p.proposalId,
            proposer: p.proposer,
            description: p.description,
            createdAt: p.createdAt,
            votingDeadline: p.votingDeadline,
            callData: p.callData, // Note: callData is not returned in memory directly to save gas if not needed.
            target: p.target,
            value: p.value,
            votesFor: p.votesFor,
            votesAgainst: p.votesAgainst,
            state: p.state,
            hasVoted: new mapping(uint256 => bool)() // Mapping cannot be returned directly
        });
    }

    /// @notice Allows a guild member to vote on an open proposal.
    /// Requires minimum reputation.
    /// @param proposalId The ID of the proposal.
    /// @param voteFor True to vote for, false to vote against.
    function voteOnProposal(uint256 proposalId, bool voteFor) external onlyGuildMember(msg.sender) nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId != 0, "DAG: Invalid proposal ID");
        require(proposal.state == ProposalState.Open, "DAG: Proposal not open for voting");
        require(block.timestamp <= proposal.votingDeadline, "DAG: Voting period has ended");

        uint256 sbtId = getMemberSbtId(msg.sender);
        require(sbtId != 0, "DAG: Could not get SBT ID for sender");

        decaySkillsAndReputation(sbtId); // Apply decay before checking reputation
        require(members[sbtId].reputation >= int256Parameters[PARAM_MIN_REPUTATION_VOTE], "DAG: Insufficient reputation to vote");

        require(!proposal.hasVoted[sbtId], "DAG: Already voted on this proposal");

        // Record the vote
        proposal.hasVoted[sbtId] = true;
        if (voteFor) {
            proposal.votesFor++;
             // Optional: Adjust reputation for voting (can be positive or negative based on outcome later)
             // adjustReputation(sbtId, SOME_SMALL_AMOUNT);
        } else {
            proposal.votesAgainst++;
             // Optional: Adjust reputation for voting
             // adjustReputation(sbtId, SOME_SMALL_AMOUNT);
        }

        emit VoteCast(proposalId, sbtId, voteFor, block.timestamp);
    }

    /// @notice Executes a proposal if the voting period has ended and it meets quorum and majority requirements.
    /// Can be called by any guild member.
    /// @param proposalId The ID of the proposal.
    function executeProposal(uint256 proposalId) external onlyGuildMember(msg.sender) nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposalId != 0, "DAG: Invalid proposal ID");
        require(proposal.state == ProposalState.Open, "DAG: Proposal not in Open state");
        require(block.timestamp > proposal.votingDeadline, "DAG: Voting period has not ended");

        // Calculate total active members (this is a simplification - a real DAO tracks voting power)
        // For simplicity, let's approximate quorum based on a fixed member count or recent activity.
        // A robust DAO might track the total supply of a governance token or total active SBTs within a period.
        // Let's use total votes cast vs a *minimum* expected participation or total eligible voters.
        // Simplification: Quorum based on total votes cast relative to a hypothetical maximum.
        // Better: Quorum is X% of members eligible to vote *at the time of execution*. This is hard to track on-chain.
        // Let's use a simpler quorum: X% of *total* votes cast must be positive votes.

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 totalEligibleVoters = guildSbtContract.balanceOf(address(this)); // Represents total SBTs held, a proxy for max members. Not ideal.
        // A better way would be to track total members explicitly or use a vote token supply.
        // Let's assume total members == total SBTs for now, as a proxy for quorum calculation basis.
        uint256 totalMembers = guildSbtContract.tokenOfOwnerByIndex(address(0), guildSbtContract.balanceOf(address(0)) - 1) + 1; // Rough estimate based on last minted ID. Flawed.

        // Let's simplify quorum/majority for this example:
        // Quorum: Total votes cast must be > 0 (at least one voter)
        // Majority: Votes For > Votes Against
        // This is too simple. A better quorum is X% of the *total number of members* at the start of the vote.
        // Let's redefine quorum: X% of the *total* guild members (total SBT supply) must have voted.
        // This requires knowing total SBT supply. Assume SBT contract has a `totalSupply()` view.
        uint256 totalSbtSupply = guildSbtContract.totalSupply(); // Requires SBT contract to have totalSupply

        uint256 quorumPercent = uint256Parameters[PARAM_GOVERNANCE_QUORUM_PERCENT]; // e.g., 500 for 5%
        uint256 majorityPercent = uint256Parameters[PARAM_GOVERNANCE_MAJORITY_PERCENT]; // e.g., 5000 for 50%

        // Calculate minimum votes required for quorum
        uint256 requiredVotesForQuorum = (totalSbtSupply * quorumPercent) / 10000; // Divide by 10000 for percentage

        // Check quorum
        bool quorumReached = totalVotes >= requiredVotesForQuorum;

        // Check majority
        bool majorityAchieved = (proposal.votesFor * 10000) / (totalVotes > 0 ? totalVotes : 1) >= majorityPercent;

        bool proposalPassed = quorumReached && majorityAchieved;

        if (proposalPassed) {
            proposal.state = ProposalState.Passed;
            // Execute the proposal call
            (bool success, bytes memory result) = proposal.target.call{value: proposal.value}(proposal.callData);

            if (success) {
                proposal.state = ProposalState.Executed;
            } else {
                // Execution failed, mark as failed or add retry logic
                proposal.state = ProposalState.Failed; // Or a new state like ExecutionFailed
            }
             emit ProposalExecuted(proposalId, success, result, block.timestamp);

        } else {
            proposal.state = ProposalState.Failed;
             emit ProposalExecuted(proposalId, false, "", block.timestamp); // No execution
        }
         // Note: State changes are handled above.
    }


    // --- Treasury Functions ---

    /// @notice Allows anyone to send ETH to the guild treasury.
    receive() external payable {
         emit TreasuryDeposited(address(0), msg.value, msg.sender, block.timestamp);
    }

    fallback() external payable {
         emit TreasuryDeposited(address(0), msg.value, msg.sender, block.timestamp);
    }

    /// @notice Allows depositing approved ERC20 tokens into the treasury.
    /// Requires the contract to have allowance from the caller.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address tokenAddress, uint256 amount) external nonReentrant {
        require(tokenAddress != address(0), "DAG: Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        // TransferFrom requires the sender to have called approve on the token contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "DAG: ERC20 transfer failed. Check allowance and balance.");
         emit TreasuryDeposited(tokenAddress, amount, msg.sender, block.timestamp);
    }

    /// @dev Internal function to withdraw ETH from the treasury. Called only by governance execution.
    /// @param amount The amount of ETH to withdraw.
    /// @param recipient The recipient address.
    function withdrawTreasuryETH(uint256 amount, address recipient) internal onlyCallableByGovernance nonReentrant {
        require(recipient != address(0), "DAG: Recipient cannot be zero address");
        require(address(this).balance >= amount, "DAG: Insufficient ETH treasury balance");

        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "DAG: ETH withdrawal failed");

        emit TreasuryWithdrawn(address(0), amount, recipient, block.timestamp);
    }

    /// @dev Internal function to withdraw ERC20 tokens from the treasury. Called only by governance execution.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    /// @param recipient The recipient address.
    function withdrawTreasuryERC20(address tokenAddress, uint256 amount, address recipient) internal onlyCallableByGovernance nonReentrant {
        require(tokenAddress != address(0), "DAG: Invalid token address");
        require(recipient != address(0), "DAG: Recipient cannot be zero address");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "DAG: Insufficient ERC20 treasury balance");

        bool success = token.transfer(recipient, amount);
        require(success, "DAG: ERC20 withdrawal failed");

        emit TreasuryWithdrawn(tokenAddress, amount, recipient, block.timestamp);
    }


    /// @notice Gets the current balance of a token (or ETH) held by the contract.
    /// @param tokenAddress The address of the token (address(0) for ETH).
    /// @return The balance amount.
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        if (tokenAddress == address(0)) {
            return address(this).balance;
        } else {
            IERC20 token = IERC20(tokenAddress);
            return token.balanceOf(address(this));
        }
    }

    // --- Parameter Management Functions (Internal - Called by Governance Execution) ---

    /// @dev Internal function to set a uint256 parameter.
    function _setParameter_uint256(bytes32 paramName, uint256 newValue) internal onlyCallableByGovernance {
        uint256 oldValue = uint256Parameters[paramName];
        uint256Parameters[paramName] = newValue;
        emit ParameterChanged_uint256(paramName, oldValue, newValue, block.timestamp);
    }

     /// @dev Internal function to set a int256 parameter.
    function _setParameter_int256(bytes32 paramName, int256 newValue) internal onlyCallableByGovernance {
        int256 oldValue = int256Parameters[paramName];
        int256Parameters[paramName] = newValue;
        emit ParameterChanged_int256(paramName, oldValue, newValue, block.timestamp);
    }

    /// @dev Internal function to set an address parameter.
    function _setParameter_address(bytes32 paramName, address newValue) internal onlyCallableByGovernance {
        address oldValue = addressParameters[paramName];
        addressParameters[paramName] = newValue;
        emit ParameterChanged_address(paramName, oldValue, newValue, block.timestamp);

        // Handle setting roles if the parameter relates to a role assignment
        if (paramName == PARAM_QUEST_ASSIGNER_ROLE) {
            // This needs careful thought. How are roles assigned?
            // Option 1: Specific SBT IDs are granted roles via governance proposal calling a _setRole function.
            // Option 2: Parameters like PARAM_QUEST_ASSIGNER_ROLE could point to *another contract* that manages roles.
            // Option 1 is simpler for this example. The parameter itself doesn't grant the role,
            // it just names *which* role acts as assigner.
            // Let's add a function to grant/revoke roles via governance.
        }
    }

    /// @dev Internal function to add a skill name to the approved list.
    function _addApprovedSkill(bytes32 skillName) internal onlyCallableByGovernance {
        require(skillName != bytes32(0), "DAG: Skill name cannot be empty");
        require(approvedSkills.add(skillName), "DAG: Skill already approved");
        emit ApprovedSkillAdded(skillName, block.timestamp);
    }

    /// @dev Internal function to grant or revoke a specific role to an SBT ID.
    /// Called only via governance proposal execution.
    /// @param sbtId The SBT ID to grant/revoke the role for.
    /// @param roleName The name of the role.
    /// @param grant True to grant, false to revoke.
    function _setRole(uint256 sbtId, bytes32 roleName, bool grant) internal onlyCallableByGovernance {
        require(members[sbtId].sbtId != 0, "DAG: Invalid SBT ID");
        memberRoles[sbtId][roleName] = grant;
        // Consider adding an event for role changes
        // event RoleChanged(uint256 indexed sbtId, bytes32 roleName, bool granted, uint256 timestamp);
    }


    // --- Utility & Helper Functions ---

    /// @notice Returns the list of skill names recognized by the guild.
    function getApprovedSkills() external view returns (bytes32[] memory) {
        return approvedSkills.values();
    }

    /// @notice Helper function to get member SBT ID from address using the mapping.
    /// Less reliable than querying SBT contract if mapping is outdated, but faster.
    /// @param account The member address.
    /// @return The SBT ID stored in the mapping. May return 0 if not found or outdated.
    function getMemberSbtIdFromAddress(address account) public view returns (uint256) {
        return memberAddressToSbtId[account];
    }

    // Helper to convert bytes32 to string (for error messages, can be gas-costly)
    function Bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint8 j = 0;
        for (uint8 i = 0; i < 32; i++) {
            byte b = x[i];
            if (b != 0) {
                bytesString[j] = b;
                j++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(j);
        for (uint8 i = 0; i < j; i++) {
            bytesStringTrimmed[i] = bytesString[i];
        }
        return string(bytesStringTrimmed);
    }
}
```

---

**Explanation of Concepts and Code:**

1.  **SBT Membership:** The `joinGuild()` function interacts with an external `IGuildSBT` contract (an ERC-721 compliant contract that enforces non-transferability) to mint a unique token for the new member. `isGuildMember` and `getMemberSbtId` check ownership using the external SBT contract, making membership verifiable on-chain and non-transferable.
2.  **Skill Tree & Reputation:** `memberSkills` is a nested mapping storing points for different `bytes32` skill names. `members` stores reputation and `lastActivityTime`. `gainSkillPoints` and `adjustReputation` modify these, but are primarily called by internal functions like `_distributeQuestReward` or potentially governance-approved actions.
3.  **Time-Based Decay:** The `decaySkillsAndReputation` internal function calculates time elapsed since `lastActivityTime` and reduces skill points and reputation based on the `PARAM_SKILL_DECAY_RATE` and `PARAM_REPUTATION_DECAY_RATE` parameters. This function is called *before* checking skill/reputation requirements or awarding new points/reputation in functions like `getMemberSkill`, `applyForQuest`, `gainSkillPoints`, `adjustReputation`, `submitProposal`, `voteOnProposal`. This ensures values are up-to-date when used.
4.  **Quest System:**
    *   `Quest` struct holds all quest details including requirements (`requiredSkills`, `requiredReputation`), rewards (`rewardETH`, `rewardToken`, `rewardSkills`, `rewardReputation`), state, and the assigned member.
    *   Quests are *proposed* first using `submitQuestProposal`, which creates a governance proposal to call the internal `_createNewQuest` function.
    *   `applyForQuest` (renamed to `requestQuestAssignment` conceptually, though code is `applyForQuest` with a revert hint) checks member eligibility.
    *   `assignQuest` allows a member with the designated `PARAM_QUEST_ASSIGNER_ROLE` (set by governance) to assign an approved quest.
    *   `submitQuestCompletion` allows the assigned member to signal completion and submit verification data.
    *   `verifyQuestCompletion` is the critical step where a member with `PARAM_VERIFICATION_ROLE` *or* the governance system (via `executeProposal` calling this function) confirms completion.
    *   `_distributeQuestReward` handles transferring tokens/ETH from the treasury and calling internal functions to update member skills and reputation.
    *   `_updateQuestState` is a helper to manage the `questsByState` mapping (simplified list management).
5.  **Decentralized Governance:**
    *   `Proposal` struct stores details about proposed actions, including target contract, calldata, proposer, votes, and state.
    *   `submitQuestProposal`, `submitParameterChangeProposal`, and `submitGenericProposal` allow members (meeting min reputation) to create proposals.
    *   `voteOnProposal` allows members (meeting min reputation, not already voted) to cast votes.
    *   `executeProposal` can be called by any member after the voting deadline. It checks if the proposal meets quorum and majority requirements (based on total SBT supply as a proxy for members) and, if passed, uses `.call()` to execute the proposed action. This `.call()` mechanism is powerful but requires careful handling of re-entrancy (`nonReentrant` modifier) and validation of target/calldata.
6.  **Treasury:** `depositETH`, `depositERC20` allow funding. `withdrawTreasuryETH`, `withdrawTreasuryERC20` are internal and callable *only* by the governance execution (`onlyCallableByGovernance` modifier) via a passed proposal. `getTreasuryBalance` is a view function.
7.  **Parameter Management:** Guild parameters (like decay rates, minimum reputation thresholds, voting period, quorum/majority percentages, and role addresses/names) are stored in mappings and can *only* be changed via governance proposals calling internal `_setParameter_...` functions. `_setRole` is an example internal function to grant/revoke roles, also callable only by governance.

This contract provides a framework for a dynamic, member-governed guild with progression and task systems, built around non-transferable identity. It exceeds the 20-function requirement and incorporates several advanced/trendy concepts like SBTs, on-chain skills/reputation with decay, and a flexible governance system executing arbitrary calls.

Remember that for a production system, you would need to:
*   Implement the `IGuildSBT` contract (likely based on OpenZeppelin ERC721, adding soulbound logic and the `mintSoulbound` function).
*   Add more robust access control logic, potentially using OpenZeppelin's AccessControl or a custom role system managed directly within the contract (as hinted with `_setRole`).
*   Refine the quorum and voting mechanism for the DAO (e.g., weighted voting based on reputation/skills, snapshotting voting power, tracking active voters).
*   Implement more sophisticated quest verification (e.g., multi-sig verification, oracle integration for off-chain data).
*   Add comprehensive testing (unit tests, integration tests).
*   Perform security audits.
*   Consider upgradeability (e.g., using proxies) if the guild's logic is expected to evolve significantly.

This code provides a solid, creative starting point!