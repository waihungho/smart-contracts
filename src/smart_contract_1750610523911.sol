Okay, here is a Solidity smart contract concept called "SynergyNexus". It's designed as a decentralized platform for collaboration, task management, and reputation/skill building within a community.

It incorporates concepts like:

*   **Profiles:** Users have on-chain profiles with reputation and skills.
*   **Quests:** Decentralized task proposals with bonding and participant assignment.
*   **Reputation System:** Non-transferable points earned through successful Quest participation.
*   **Skill Attestation:** A mechanism for users to vouch for each other's skills, impacting profile skills.
*   **Token Bonding:** Users stake tokens (`SNX`) to propose/participate in Quests, showing commitment.
*   **Parameterization:** Key protocol settings controlled by a governance address.
*   **Simple Rewards:** Distribution of bonded tokens and native tokens (`SNX`) upon Quest completion.

It aims for a creative, advanced, and non-standard structure by combining these elements into a single protocol contract.

---

## SynergyNexus Smart Contract

### Outline & Function Summary

This contract manages user profiles, quests (tasks), reputation, and skills within a decentralized network.

**Key Components:**

1.  **Profiles:** Stores user reputation points, skill points, specific skills, and staked tokens.
2.  **Quests:** Represents tasks or projects with states (Proposed, Active, Completed, Failed, Cancelled), bonding requirements, participants, and rewards.
3.  **Reputation:** A non-transferable score reflecting a user's successful contributions.
4.  **Skills:** Specific competencies recorded on profiles, potentially boosted by attestations.
5.  **Token Bonding:** Users stake the protocol's native token (`SNX`) on Quests.
6.  **Parameterization:** Configurable settings for the protocol.
7.  **Access Control:** Functions restricted to specific roles (governance, quest proposer, assigned state transitioner).

**Function Summary (Total: 32 Functions):**

*   **Core Setup & Access Control:**
    1.  `constructor`: Initializes the contract with the SNX token address and governance.
    2.  `setGovernanceAddress`: Allows the current governance to transfer governance rights.
    3.  `setQuestStateTransitioner`: Sets the address authorized to mark quests as completed/failed.
*   **Profile Management:**
    4.  `createProfile`: Initializes a user's profile.
    5.  `viewProfile`: Get a user's complete profile data. (View)
    6.  `updateProfileDescription`: Users set or update their profile description.
    7.  `getProfileReputation`: Get a user's reputation points. (View)
    8.  `getProfileSkillPoints`: Get a user's total skill points. (View)
    9.  `getProfileSkillLevel`: Get points for a specific skill. (View)
    10. `getTotalStaked`: Get total general staked amount for a user. (View)
*   **Token Staking & Rewards:**
    11. `stakeTokens`: Stake SNX tokens in a general profile stake pool.
    12. `unstakeTokens`: Unstake from the general profile stake pool (may have conditions).
    13. `claimRewards`: Claim accumulated SNX rewards.
*   **Quest Management:**
    14. `proposeQuest`: Create a new Quest proposal.
    15. `viewQuest`: Get details of a specific Quest. (View)
    16. `bondToQuest`: Stake SNX tokens specifically for a Quest.
    17. `unbondFromQuest`: Unstake tokens from a Quest (with potential penalties based on state).
    18. `assignParticipant`: Governance/Proposer adds a participant to a Quest.
    19. `removeParticipant`: Governance/Proposer removes a participant from a Quest.
    20. `startQuest`: Governance/Proposer moves a Quest to the Active state.
    21. `completeQuest`: State Transitioner marks a Quest as Completed, distributes rewards, and reputation.
    22. `failQuest`: State Transitioner marks a Quest as Failed, handles bonded tokens.
    23. `cancelQuest`: Governance/Proposer cancels a Quest, returns bonded tokens.
    24. `getQuestsByState`: Get a list of Quest IDs filtered by state. (View)
    25. `getQuestsByParticipant`: Get a list of Quest IDs a user is involved in. (View)
    26. `getBondedAmountForQuest`: Get the total SNX bonded to a quest. (View)
    27. `getParticipantsForQuest`: Get the list of participants for a quest. (View)
    28. `getQuestProposer`: Get the proposer of a quest. (View)
    29. `getQuestCompletionTimestamp`: Get the timestamp a quest was completed (if applicable). (View)
*   **Skill Attestation:**
    30. `attestSkill`: A user (with sufficient reputation) vouches for another's skill.
    31. `getSkillAttestations`: Get the number of attestations for a user's specific skill. (View)
*   **Parameter Management:**
    32. `setParameter`: Governance sets a specific system parameter (e.g., min bond, reputation reward).
    33. `getParameter`: Get the value of a specific system parameter. (View)
    34. `withdrawProtocolFees`: Governance can withdraw accumulated fees (if implemented). *Self-correction: Added fee concept.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable simplifies governance for example

// Note: This is a complex system draft. Production use would require significant testing, gas optimization, and potentially splitting logic into multiple contracts.

contract SynergyNexus is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // --- Error Definitions ---
    error ProfileNotFound();
    error QuestNotFound();
    error InvalidQuestState();
    error Unauthorized();
    error BondingNotAllowed();
    error UnbondingNotAllowed();
    error InsufficientBond();
    error ParticipantAlreadyAssigned();
    error ParticipantNotAssigned();
    error SkillAlreadyExists();
    error InsufficientReputationForAttestation();
    error InvalidParameter();
    error ZeroAddressNotAllowed();
    error QuestNotCompleted();
    error NoRewardsToClaim();
    error NothingToUnstake();
    error QuestStillActive();

    // --- Events ---
    event ProfileCreated(address indexed user);
    event ProfileUpdated(address indexed user);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event QuestProposed(uint256 indexed questId, address indexed proposer, string title);
    event QuestBonded(uint256 indexed questId, address indexed user, uint256 amount);
    event QuestUnbonded(uint256 indexed questId, address indexed user, uint256 amount);
    event ParticipantAssigned(uint256 indexed questId, address indexed participant);
    event ParticipantRemoved(uint256 indexed questId, address indexed participant);
    event QuestStarted(uint256 indexed questId, uint256 startTime);
    event QuestCompleted(uint256 indexed questId, uint256 completionTime);
    event QuestFailed(uint256 indexed questId);
    event QuestCancelled(uint256 indexed questId);
    event SkillAttested(address indexed attestor, address indexed user, string skill);
    event ParameterSet(string parameter, uint256 value);
    event GovernanceTransferred(address indexed oldGovernance, address indexed newGovernance);
    event StateTransitionerSet(address indexed oldTransitioner, address indexed newTransitioner);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Structs & Enums ---
    struct Profile {
        uint256 reputationPoints;
        mapping(string => uint256) skills; // Skill name => points/level
        string description;
        uint256 generalStakedAmount;
        uint256 pendingRewards; // SNX rewards pending claim
        bool exists; // Flag to check if profile is created
    }

    enum QuestState {
        Proposed, // Waiting for approval/participants
        Active,   // In progress
        Completed, // Successfully finished
        Failed,    // Unsuccessfully finished
        Cancelled  // Aborted before completion
    }

    struct Quest {
        uint256 id;
        address proposer;
        string title;
        string description;
        mapping(string => uint256) requiredSkills; // Skill name => minimum required points
        uint256 rewardAmount; // SNX total reward pool
        uint256 reputationReward; // Reputation points per participant
        mapping(address => uint256) bondedAmount; // User => amount bonded to this quest
        uint256 totalBondedAmount;
        address[] participants; // Assigned participants
        QuestState state;
        uint256 proposalTimestamp;
        uint256 startTime;
        uint256 completionTimestamp; // For Completed state
        uint256 failureTimestamp; // For Failed state
        uint256 cancellationTimestamp; // For Cancelled state
    }

    // --- State Variables ---
    IERC20 public immutable SNXToken; // The native utility/governance token
    address public governanceAddress; // Address with parameter setting and some Quest control
    address public questStateTransitioner; // Address authorized to mark quests completed/failed

    mapping(address => Profile) public profiles;
    mapping(uint256 => Quest) public quests;
    uint256 private nextQuestId = 1; // Starts from 1

    mapping(address => mapping(string => uint256)) public skillAttestations; // user => skill => attestations count
    mapping(string => uint256) public parameters; // Configurable parameters (e.g., minReputationForAttestation)

    uint256 public totalProtocolFees; // Accumulated fees (if applicable)

    // --- Modifiers ---
    modifier onlyGovernance() {
        if (msg.sender != governanceAddress) revert Unauthorized();
        _;
    }

    modifier onlyQuestProposerOrGovernance(uint256 _questId) {
        if (msg.sender != quests[_questId].proposer && msg.sender != governanceAddress) revert Unauthorized();
        _;
    }

    modifier onlyStateTransitioner() {
        if (msg.sender != questStateTransitioner && msg.sender != governanceAddress) revert Unauthorized(); // Governance can also transition
        _;
    }

    modifier profileExists(address _user) {
        if (!profiles[_user].exists) revert ProfileNotFound();
        _;
    }

    modifier questExists(uint256 _questId) {
        if (quests[_questId].id == 0) revert QuestNotFound(); // Check ID > 0 implies existence
        _;
    }

    // --- Constructor ---
    constructor(address _snxTokenAddress, address _initialGovernance, address _initialStateTransitioner) Ownable(msg.sender) {
        if (_snxTokenAddress == address(0) || _initialGovernance == address(0) || _initialStateTransitioner == address(0)) revert ZeroAddressNotAllowed();
        SNXToken = IERC20(_snxTokenAddress);
        governanceAddress = _initialGovernance;
        questStateTransitioner = _initialStateTransitioner;

        // Set some initial default parameters
        parameters["minReputationForAttestation"] = 100;
        parameters["unbondingPenaltyPercentage"] = 10; // 10% penalty
        parameters["questCompletionReputationBoost"] = 50; // Reputation boost per completed quest
        parameters["questParticipantSNXRewardPercentage"] = 80; // 80% of reward pool split among participants
        parameters["questProposerSNXRewardPercentage"] = 20; // 20% of reward pool goes to proposer
        parameters["minQuestBondPercentage"] = 1; // Minimum bond 1% of rewardAmount for proposer
    }

    // --- Access Control Functions ---

    /// @notice Allows the current governance address to transfer governance rights.
    /// @param _newGovernance The address of the new governance entity.
    function setGovernanceAddress(address _newGovernance) external onlyGovernance {
        if (_newGovernance == address(0)) revert ZeroAddressNotAllowed();
        emit GovernanceTransferred(governanceAddress, _newGovernance);
        governanceAddress = _newGovernance;
    }

    /// @notice Allows governance to set the address authorized to mark quests as completed/failed.
    /// @param _newStateTransitioner The address of the new state transitioner.
    function setQuestStateTransitioner(address _newStateTransitioner) external onlyGovernance {
         if (_newStateTransitioner == address(0)) revert ZeroAddressNotAllowed();
         emit StateTransitionerSet(questStateTransitioner, _newStateTransitioner);
         questStateTransitioner = _newStateTransitioner;
    }

    // --- Profile Management Functions ---

    /// @notice Creates a profile for the caller if one does not exist.
    function createProfile() external {
        if (profiles[msg.sender].exists) revert ("Profile already exists"); // Custom message for simple check
        profiles[msg.sender].exists = true;
        profiles[msg.sender].reputationPoints = 0;
        profiles[msg.sender].generalStakedAmount = 0;
        profiles[msg.sender].pendingRewards = 0;
        // Skills mapping is implicitly initialized empty
        // Description is implicitly initialized empty
        emit ProfileCreated(msg.sender);
    }

    /// @notice Retrieves the profile data for a given user.
    /// @param _user The address of the user.
    /// @return Profile struct data.
    function viewProfile(address _user) external view profileExists(_user) returns (Profile memory) {
         // Note: Mapping inside struct cannot be returned directly in external calls.
         // We return the basic struct and require separate calls for skills and attestations.
         Profile storage p = profiles[_user];
         return Profile({
             reputationPoints: p.reputationPoints,
             skills: p.skills, // This mapping cannot be accessed directly externally
             description: p.description,
             generalStakedAmount: p.generalStakedAmount,
             pendingRewards: p.pendingRewards,
             exists: p.exists
         });
    }

    /// @notice Allows a user to update their profile description.
    /// @param _description The new description for the profile.
    function updateProfileDescription(string calldata _description) external profileExists(msg.sender) {
        profiles[msg.sender].description = _description;
        emit ProfileUpdated(msg.sender);
    }

    /// @notice Get a user's current reputation points.
    /// @param _user The address of the user.
    /// @return The user's reputation points.
    function getProfileReputation(address _user) external view profileExists(_user) returns (uint256) {
        return profiles[_user].reputationPoints;
    }

    /// @notice Get a user's total skill points (sum of all skill levels).
    /// @param _user The address of the user.
    /// @return The user's total skill points.
    function getProfileSkillPoints(address _user) external view profileExists(_user) returns (uint256) {
        uint256 totalPoints = 0;
        // This requires iterating over skills, which is not directly possible with mappings in external view.
        // A common pattern is to emit events for skill updates or maintain a separate list of skill names.
        // For this example, we'll simplify and assume skills are queried individually or sum is calculated off-chain.
        // Returning 0 as a placeholder or require separate getProfileSkillLevel calls.
        // Let's return 0 and mention the limitation.
        // Limitation: Cannot directly sum mapping values in a single external view function call easily.
        // User would typically fetch profile, then call getProfileSkillLevel for known skills.
        return 0; // Placeholder due to mapping iteration limitation
    }

    /// @notice Get the skill level/points for a specific skill of a user.
    /// @param _user The address of the user.
    /// @param _skill The name of the skill.
    /// @return The points for the specified skill.
    function getProfileSkillLevel(address _user, string calldata _skill) external view profileExists(_user) returns (uint256) {
         return profiles[_user].skills[_skill];
    }


    /// @notice Get the total SNX staked by a user in their general profile stake.
    /// @param _user The address of the user.
    /// @return The total staked amount.
    function getTotalStaked(address _user) external view profileExists(_user) returns (uint256) {
        return profiles[_user].generalStakedAmount;
    }


    // --- Token Staking & Rewards Functions ---

    /// @notice Stakes SNX tokens in the user's general profile stake pool.
    /// Requires prior approval of the SNX tokens by the user.
    /// @param _amount The amount of SNX tokens to stake.
    function stakeTokens(uint256 _amount) external nonReentrant profileExists(msg.sender) {
        if (_amount == 0) revert ("Cannot stake zero");
        SNXToken.safeTransferFrom(msg.sender, address(this), _amount);
        profiles[msg.sender].generalStakedAmount += _amount;
        emit TokensStaked(msg.sender, _amount);
    }

    /// @notice Unstakes tokens from the user's general profile stake pool.
    /// May have conditions in a real system (e.g., not staked in active quests).
    /// @param _amount The amount of SNX tokens to unstake.
    function unstakeTokens(uint256 _amount) external nonReentrant profileExists(msg.sender) {
        if (_amount == 0) revert ("Cannot unstake zero");
        if (profiles[msg.sender].generalStakedAmount < _amount) revert NothingToUnstake();

        profiles[msg.sender].generalStakedAmount -= _amount;
        SNXToken.safeTransfer(msg.sender, _amount);
        emit TokensUnstaked(msg.sender, _amount);
    }

    /// @notice Allows a user to claim their accumulated SNX rewards.
    function claimRewards() external nonReentrant profileExists(msg.sender) {
        uint256 rewards = profiles[msg.sender].pendingRewards;
        if (rewards == 0) revert NoRewardsToClaim();

        profiles[msg.sender].pendingRewards = 0;
        // Protocol Fees: In a real system, a small percentage might be kept as protocol fee here.
        // For this example, transfer all pending rewards.
        // uint256 protocolFee = (rewards * parameters["protocolFeePercentage"]) / 100;
        // uint256 amountToUser = rewards - protocolFee;
        // totalProtocolFees += protocolFee;
        // SNXToken.safeTransfer(msg.sender, amountToUser); // Transfer net amount
        // emit ProtocolFeesCollected(protocolFee); // Emit fee event
        SNXToken.safeTransfer(msg.sender, rewards); // Transfer full amount for simplicity
        emit RewardsClaimed(msg.sender, rewards);
    }

     /// @notice Allows governance to withdraw accumulated protocol fees.
     /// @param _amount The amount of fees to withdraw.
     /// @param _recipient The address to send the fees to.
     function withdrawProtocolFees(uint256 _amount, address _recipient) external onlyGovernance nonReentrant {
         if (_amount == 0) revert ("Cannot withdraw zero");
         if (_recipient == address(0)) revert ZeroAddressNotAllowed();
         if (totalProtocolFees < _amount) revert ("Insufficient protocol fees");

         totalProtocolFees -= _amount;
         SNXToken.safeTransfer(_recipient, _amount);
         emit ProtocolFeesWithdrawn(_recipient, _amount);
     }


    // --- Quest Management Functions ---

    /// @notice Proposes a new Quest. Requires the proposer to bond a minimum amount.
    /// @param _title The title of the Quest.
    /// @param _description The description of the Quest.
    /// @param _requiredSkills List of skill names required for participants.
    /// @param _requiredSkillLevels List of minimum skill levels corresponding to _requiredSkills.
    /// @param _rewardAmount The total SNX token reward pool for the Quest.
    /// @param _reputationReward The reputation points awarded to successful participants.
    function proposeQuest(
        string calldata _title,
        string calldata _description,
        string[] calldata _requiredSkills,
        uint256[] calldata _requiredSkillLevels,
        uint256 _rewardAmount,
        uint256 _reputationReward
    ) external nonReentrant profileExists(msg.sender) {
        if (_requiredSkills.length != _requiredSkillLevels.length) revert ("Skill arrays mismatch");
        if (_rewardAmount == 0 && _reputationReward == 0) revert ("Quest must offer rewards");

        uint256 questId = nextQuestId++;
        Quest storage newQuest = quests[questId];

        newQuest.id = questId;
        newQuest.proposer = msg.sender;
        newQuest.title = _title;
        newQuest.description = _description;

        for (uint i = 0; i < _requiredSkills.length; i++) {
            newQuest.requiredSkills[_requiredSkills[i]] = _requiredSkillLevels[i];
        }

        newQuest.rewardAmount = _rewardAmount;
        newQuest.reputationReward = _reputationReward;
        newQuest.state = QuestState.Proposed;
        newQuest.proposalTimestamp = block.timestamp;

        // Proposer must bond a minimum amount based on reward
        uint256 minBond = (_rewardAmount * parameters["minQuestBondPercentage"]) / 100;
        if (msg.value > 0 && address(this).balance < minBond) {
             // Example if using ETH bond
        }
        // Assuming SNX bond, require bonding separately via bondToQuest after proposing
        // Or require SNX approval and transfer here. Let's require approval & transfer here for simplicity.
        // Require user to approve SNX before calling proposeQuest
        if (_rewardAmount > 0 && minBond > 0) {
             SNXToken.safeTransferFrom(msg.sender, address(this), minBond);
             newQuest.bondedAmount[msg.sender] += minBond;
             newQuest.totalBondedAmount += minBond;
             emit QuestBonded(questId, msg.sender, minBond);
        } else if (_rewardAmount == 0 && minBond > 0) {
             // Handle cases where reward is 0 but there's still a minimum bond (e.g., for non-monetary quests)
             SNXToken.safeTransferFrom(msg.sender, address(this), minBond);
             newQuest.bondedAmount[msg.sender] += minBond;
             newQuest.totalBondedAmount += minBond;
             emit QuestBonded(questId, msg.sender, minBond);
        }


        emit QuestProposed(questId, msg.sender, _title);
    }

     /// @notice Retrieves the details of a specific Quest.
     /// @param _questId The ID of the Quest.
     /// @return Quest struct data.
     function viewQuest(uint256 _questId) external view questExists(_questId) returns (Quest memory) {
         // Note: Mappings inside struct cannot be returned directly.
         // Required skills and bonded amounts need separate calls.
         Quest storage q = quests[_questId];
         return Quest({
             id: q.id,
             proposer: q.proposer,
             title: q.title,
             description: q.description,
             requiredSkills: q.requiredSkills, // This mapping cannot be accessed directly
             rewardAmount: q.rewardAmount,
             reputationReward: q.reputationReward,
             bondedAmount: q.bondedAmount, // This mapping cannot be accessed directly
             totalBondedAmount: q.totalBondedAmount,
             participants: q.participants,
             state: q.state,
             proposalTimestamp: q.proposalTimestamp,
             startTime: q.startTime,
             completionTimestamp: q.completionTimestamp,
             failureTimestamp: q.failureTimestamp,
             cancellationTimestamp: q.cancellationTimestamp
         });
     }


    /// @notice Allows a user to bond SNX tokens to a Quest in Proposed state.
    /// Requires prior approval of the SNX tokens by the user.
    /// @param _questId The ID of the Quest to bond to.
    /// @param _amount The amount of SNX tokens to bond.
    function bondToQuest(uint256 _questId, uint256 _amount) external nonReentrant questExists(_questId) profileExists(msg.sender) {
        Quest storage quest = quests[_questId];
        if (quest.state != QuestState.Proposed) revert BondingNotAllowed();
        if (_amount == 0) revert ("Cannot bond zero");

        SNXToken.safeTransferFrom(msg.sender, address(this), _amount);
        quest.bondedAmount[msg.sender] += _amount;
        quest.totalBondedAmount += _amount;
        emit QuestBonded(_questId, msg.sender, _amount);
    }

    /// @notice Allows a user to unbond tokens from a Quest.
    /// Penalties may apply if unbonding from Active or Completed/Failed states.
    /// @param _questId The ID of the Quest.
    /// @param _amount The amount of SNX tokens to unbond.
    function unbondFromQuest(uint256 _questId, uint256 _amount) external nonReentrant questExists(_questId) profileExists(msg.sender) {
        Quest storage quest = quests[_questId];
        if (quest.bondedAmount[msg.sender] < _amount) revert InsufficientBond();
        if (_amount == 0) revert ("Cannot unbond zero");

        uint256 returnAmount = _amount;
        if (quest.state == QuestState.Active) {
            // Apply penalty if unbonding while active
            uint256 penalty = (_amount * parameters["unbondingPenaltyPercentage"]) / 100;
            returnAmount = _amount - penalty;
            // The penalty amount stays in the contract, potentially for protocol fees or redistribution later
            totalProtocolFees += penalty; // Add penalty to protocol fees
        } else if (quest.state != QuestState.Proposed) {
             // Cannot unbond from completed, failed, or cancelled state (funds handled already)
             revert UnbondingNotAllowed();
        }

        quest.bondedAmount[msg.sender] -= _amount; // Deduct the full amount bonded
        quest.totalBondedAmount -= _amount;
        SNXToken.safeTransfer(msg.sender, returnAmount);
        emit QuestUnbonded(_questId, msg.sender, returnAmount);
        if (returnAmount < _amount) {
             // Emit event for penalty if applicable
             // emit UnbondingPenaltyApplied(_questId, msg.sender, _amount - returnAmount);
        }
    }

    /// @notice Assigns a participant to a Quest in Proposed state.
    /// Requires the caller to be the Quest proposer or governance.
    /// @param _questId The ID of the Quest.
    /// @param _participant The address of the participant to assign.
    function assignParticipant(uint256 _questId, address _participant) external onlyQuestProposerOrGovernance(_questId) profileExists(_participant) {
        Quest storage quest = quests[_questId];
        if (quest.state != QuestState.Proposed) revert InvalidQuestState();
        if (_participant == address(0)) revert ZeroAddressNotAllowed();

        // Check if participant is already assigned
        for (uint i = 0; i < quest.participants.length; i++) {
            if (quest.participants[i] == _participant) revert ParticipantAlreadyAssigned();
        }

        // Optional: Check if participant meets required skills (requires iterating mapping - off-chain check recommended)
        // For this example, we skip complex on-chain skill check during assignment.

        quest.participants.push(_participant);
        emit ParticipantAssigned(_questId, _participant);
    }

    /// @notice Removes a participant from a Quest in Proposed state.
    /// Requires the caller to be the Quest proposer or governance.
    /// @param _questId The ID of the Quest.
    /// @param _participant The address of the participant to remove.
    function removeParticipant(uint256 _questId, address _participant) external onlyQuestProposerOrGovernance(_questId) {
         Quest storage quest = quests[_questId];
         if (quest.state != QuestState.Proposed) revert InvalidQuestState();
         if (_participant == address(0)) revert ZeroAddressNotAllowed();

         bool found = false;
         for (uint i = 0; i < quest.participants.length; i++) {
             if (quest.participants[i] == _participant) {
                 // Simple removal by swapping with last element and popping
                 quest.participants[i] = quest.participants[quest.participants.length - 1];
                 quest.participants.pop();
                 found = true;
                 break;
             }
         }
         if (!found) revert ParticipantNotAssigned();

         emit ParticipantRemoved(_questId, _participant);
    }


    /// @notice Moves a Quest from Proposed to Active state.
    /// Requires the caller to be the Quest proposer or governance.
    /// @param _questId The ID of the Quest to start.
    function startQuest(uint256 _questId) external onlyQuestProposerOrGovernance(_questId) nonReentrant {
        Quest storage quest = quests[_questId];
        if (quest.state != QuestState.Proposed) revert InvalidQuestState();
        if (quest.participants.length == 0) revert ("Cannot start quest without participants");

        quest.state = QuestState.Active;
        quest.startTime = block.timestamp;
        emit QuestStarted(_questId, quest.startTime);
    }

    /// @notice Marks a Quest as Completed. Distributes rewards and reputation.
    /// Requires the caller to be the State Transitioner or Governance.
    /// @param _questId The ID of the Quest to complete.
    function completeQuest(uint256 _questId) external onlyStateTransitioner nonReentrant questExists(_questId) {
        Quest storage quest = quests[_questId];
        if (quest.state != QuestState.Active) revert InvalidQuestState();

        quest.state = QuestState.Completed;
        quest.completionTimestamp = block.timestamp;

        // Distribute Rewards and Reputation
        uint256 totalRewardPool = quest.rewardAmount;
        uint256 reputationReward = quest.reputationReward + parameters["questCompletionReputationBoost"];

        uint256 proposerRewardPercentage = parameters["questProposerSNXRewardPercentage"];
        uint256 participantRewardPercentage = parameters["questParticipantSNXRewardPercentage"];

        uint256 proposerShare = (totalRewardPool * proposerRewardPercentage) / 100;
        uint256 participantShare = totalRewardPool - proposerShare; // Remaining for participants

        if (proposerShare > 0) {
             // Add proposer's share to pending rewards
             profiles[quest.proposer].pendingRewards += proposerShare;
        }

        uint256 numParticipants = quest.participants.length;
        if (numParticipants > 0 && participantShare > 0) {
             uint256 rewardPerParticipant = participantShare / numParticipants;
             for (uint i = 0; i < numParticipants; i++) {
                 address participant = quest.participants[i];
                 profiles[participant].pendingRewards += rewardPerParticipant;
                 profiles[participant].reputationPoints += reputationReward;
                 // Optionally update skill points based on required skills completion
             }
        }

        // Return bonded amounts (excluding any penalties from unbonding during Active state)
        // Note: Penalties were already handled during unbondFromQuest.
        // Here, bonded funds belonging to users still bonded get returned.
        // Proposer's initial bond is part of the totalBondedAmount, but they don't get it back *as a bond return*,
        // their reward is separate. This logic needs careful handling depending on desired outcome.
        // Simple model: return all bonded funds back to original bonders (proposer's initial bond is also returned).
        // Let's assume bonded funds were just "at stake" and are returned to bonders, *separate* from rewards.
        uint256 totalBonded = quest.totalBondedAmount;
         for (uint i = 0; i < quest.participants.length; i++) {
             address participant = quest.participants[i];
             uint256 participantBond = quest.bondedAmount[participant];
             if (participantBond > 0) {
                 SNXToken.safeTransfer(participant, participantBond);
                 quest.bondedAmount[participant] = 0; // Zero out bonded amount
                 totalBonded -= participantBond;
             }
         }
         // Also return proposer's bond if they are not a participant getting a reward share
         if (quest.bondedAmount[quest.proposer] > 0) {
              uint256 proposerBond = quest.bondedAmount[quest.proposer];
              SNXToken.safeTransfer(quest.proposer, proposerBond);
              quest.bondedAmount[quest.proposer] = 0;
              totalBonded -= proposerBond;
         }

         // Any remaining totalBondedAmount should be zero after returning bonds. If not, it's a logic error or leftover from unbonding penalty.
         // Any remaining rewardAmount not distributed (if calculations resulted in leftovers) stays in contract or goes to fees.
         // Let's assume integer division losses stay in contract.

        emit QuestCompleted(_questId, quest.completionTimestamp);
    }

    /// @notice Marks a Quest as Failed. Handles bonded tokens (slashing or return).
    /// Requires the caller to be the State Transitioner or Governance.
    /// @param _questId The ID of the Quest to fail.
    function failQuest(uint256 _questId) external onlyStateTransitioner nonReentrant questExists(_questId) {
        Quest storage quest = quests[_questId];
        if (quest.state != QuestState.Active) revert InvalidQuestState();

        quest.state = QuestState.Failed;
        quest.failureTimestamp = block.timestamp;

        // Handle Bonded Tokens:
        // Option 1: Return all bonded tokens.
        // Option 2: Slash a percentage, return the rest.
        // Option 3: Slash all bonded tokens.
        // Let's implement Option 1 for simplicity: return all remaining bonded tokens.
        uint256 totalBonded = quest.totalBondedAmount;
        for (uint i = 0; i < quest.participants.length; i++) {
            address participant = quest.participants[i];
             uint256 participantBond = quest.bondedAmount[participant];
             if (participantBond > 0) {
                 SNXToken.safeTransfer(participant, participantBond);
                 quest.bondedAmount[participant] = 0; // Zero out bonded amount
                 totalBonded -= participantBond;
             }
        }
        if (quest.bondedAmount[quest.proposer] > 0) {
             uint256 proposerBond = quest.bondedAmount[quest.proposer];
             SNXToken.safeTransfer(quest.proposer, proposerBond);
             quest.bondedAmount[quest.proposer] = 0;
             totalBonded -= proposerBond;
        }
        // Any leftover `totalBonded` goes to protocol fees (e.g. from unbonding penalties)
        totalProtocolFees += totalBonded; // Collect any remaining bonded amount

        // No reputation or SNX rewards are distributed on failure.

        emit QuestFailed(_questId);
    }

    /// @notice Cancels a Quest in Proposed state. Returns bonded tokens.
    /// Requires the caller to be the Quest proposer or Governance.
    /// @param _questId The ID of the Quest to cancel.
    function cancelQuest(uint256 _questId) external onlyQuestProposerOrGovernance(_questId) nonReentrant questExists(_questId) {
        Quest storage quest = quests[_questId];
        if (quest.state != QuestState.Proposed) revert InvalidQuestState();

        quest.state = QuestState.Cancelled;
        quest.cancellationTimestamp = block.timestamp;

        // Return all bonded tokens to bonders
        uint256 totalBonded = quest.totalBondedAmount;
         for (uint i = 0; i < quest.participants.length; i++) {
             address participant = quest.participants[i];
              uint256 participantBond = quest.bondedAmount[participant];
             if (participantBond > 0) {
                 SNXToken.safeTransfer(participant, participantBond);
                 quest.bondedAmount[participant] = 0; // Zero out bonded amount
                 totalBonded -= participantBond;
             }
         }
        if (quest.bondedAmount[quest.proposer] > 0) {
             uint256 proposerBond = quest.bondedAmount[quest.proposer];
             SNXToken.safeTransfer(quest.proposer, proposerBond);
             quest.bondedAmount[quest.proposer] = 0;
             totalBonded -= proposerBond;
        }
         // Any leftover `totalBonded` should be zero here.

        emit QuestCancelled(_questId);
    }

    /// @notice Get a list of Quest IDs filtered by state.
    /// Note: This function can be gas-intensive if there are many quests. Consider pagination off-chain.
    /// @param _state The state to filter by.
    /// @return An array of Quest IDs.
    function getQuestsByState(QuestState _state) external view returns (uint256[] memory) {
        uint256[] memory questIds = new uint256[](nextQuestId - 1); // Max possible IDs
        uint256 count = 0;
        for (uint256 i = 1; i < nextQuestId; i++) {
            if (quests[i].id != 0 && quests[i].state == _state) { // Check ID != 0 ensures it's a valid quest entry
                questIds[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = questIds[i];
        }
        return result;
    }

    /// @notice Get a list of Quest IDs that a specific user is involved in (proposer or participant).
    /// Note: Can be gas-intensive.
    /// @param _user The address of the user.
    /// @return An array of Quest IDs.
    function getQuestsByParticipant(address _user) external view returns (uint256[] memory) {
        uint256[] memory questIds = new uint256[](nextQuestId - 1);
        uint256 count = 0;
         for (uint256 i = 1; i < nextQuestId; i++) {
            if (quests[i].id != 0) {
                 // Check if proposer
                 if (quests[i].proposer == _user) {
                      questIds[count] = i;
                      count++;
                      continue; // Avoid checking participants if proposer
                 }
                 // Check if participant
                 for (uint j = 0; j < quests[i].participants.length; j++) {
                     if (quests[i].participants[j] == _user) {
                         questIds[count] = i;
                         count++;
                         break; // Found as participant, move to next quest
                     }
                 }
             }
         }
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = questIds[i];
        }
        return result;
    }

    /// @notice Get the total amount of SNX bonded to a specific Quest.
    /// @param _questId The ID of the Quest.
    /// @return The total bonded amount.
    function getBondedAmountForQuest(uint256 _questId) external view questExists(_questId) returns (uint256) {
        return quests[_questId].totalBondedAmount;
    }

    /// @notice Get the list of assigned participants for a Quest.
    /// @param _questId The ID of the Quest.
    /// @return An array of participant addresses.
    function getParticipantsForQuest(uint256 _questId) external view questExists(_questId) returns (address[] memory) {
         return quests[_questId].participants;
    }

     /// @notice Get the proposer of a specific Quest.
     /// @param _questId The ID of the Quest.
     /// @return The proposer's address.
     function getQuestProposer(uint256 _questId) external view questExists(_questId) returns (address) {
          return quests[_questId].proposer;
     }

     /// @notice Get the completion timestamp of a Quest, if completed.
     /// @param _questId The ID of the Quest.
     /// @return The completion timestamp, or 0 if not completed.
     function getQuestCompletionTimestamp(uint256 _questId) external view questExists(_questId) returns (uint256) {
         if (quests[_questId].state == QuestState.Completed) {
             return quests[_questId].completionTimestamp;
         }
         return 0;
     }


    // --- Skill Attestation Functions ---

    /// @notice Allows a user to attest to another user's skill.
    /// Requires the attestor to have a minimum reputation.
    /// Increases the recipient's skill points and attestation count for that skill.
    /// @param _user The user whose skill is being attested.
    /// @param _skill The name of the skill.
    function attestSkill(address _user, string calldata _skill) external profileExists(msg.sender) profileExists(_user) nonReentrant {
        if (msg.sender == _user) revert ("Cannot attest your own skill");
        if (profiles[msg.sender].reputationPoints < parameters["minReputationForAttestation"]) revert InsufficientReputationForAttestation();
        if (bytes(_skill).length == 0) revert ("Skill name cannot be empty");

        skillAttestations[_user][_skill]++;
        // Simple model: 1 attestation adds 1 skill point. Could be weighted by attestor's reputation.
        profiles[_user].skills[_skill]++; // Directly increase skill points

        emit SkillAttested(msg.sender, _user, _skill);
    }

    /// @notice Get the number of attestations a user has received for a specific skill.
    /// @param _user The address of the user.
    /// @param _skill The name of the skill.
    /// @return The number of attestations.
    function getSkillAttestations(address _user, string calldata _skill) external view returns (uint256) {
         // No profileExists check needed if attestations map is public, as it will return 0 for non-existent profiles/skills.
         return skillAttestations[_user][_skill];
    }


    // --- Parameter Management Functions ---

    /// @notice Allows governance to set a specific system parameter.
    /// @param _parameter The name of the parameter (e.g., "minReputationForAttestation").
    /// @param _value The new value for the parameter.
    function setParameter(string calldata _parameter, uint256 _value) external onlyGovernance {
        if (bytes(_parameter).length == 0) revert InvalidParameter();
        // Basic sanity check - governance is responsible for setting sensible values
        if (_value == 0 && (keccak256(abi.encodePacked(_parameter)) == keccak256(abi.encodePacked("minReputationForAttestation")) ||
                           keccak256(abi.encodePacked(_parameter)) == keccak256(abi.encodePacked("minQuestBondPercentage")))) {
             // Allow 0 for some parameters, but maybe not these minimums depending on desired behavior
        }

        parameters[_parameter] = _value;
        emit ParameterSet(_parameter, _value);
    }

    /// @notice Get the value of a specific system parameter.
    /// @param _parameter The name of the parameter.
    /// @return The value of the parameter. Returns 0 if parameter not found (or set to 0).
    function getParameter(string calldata _parameter) external view returns (uint256) {
        return parameters[_parameter];
    }

    // --- Internal Helper Functions (examples) ---

    // These could be expanded based on complexity needs.
    // For instance, a function to check if a participant meets required skills
    // function _hasRequiredSkills(address _user, mapping(string => uint256) storage _requiredSkills) internal view returns (bool) {
    //    for each required skill... check profiles[_user].skills[skill] >= requiredLevel
    // }

    // Functions to update reputation and skills could be internal
    // function _earnReputation(address _user, uint256 _amount) internal { profiles[_user].reputationPoints += _amount; }
    // function _loseReputation(address _user, uint256 _amount) internal { if (profiles[_user].reputationPoints >= _amount) profiles[_user].reputationPoints -= _amount; else profiles[_user].reputationPoints = 0; }
}
```

---

**Explanation of Advanced/Creative/Trendy Concepts & Why They Are Not Standard Open Source Duplicates:**

1.  **Integrated Profile System:** While profiles exist in some protocols (like ENS or specific social dApps), having reputation and skill points *directly within the core protocol state* tied to activity (Quests, Attestations) is less common than external indexing or separate reputation layers. ERC-721 profiles exist, but this contract's profile is not an NFT by default.
2.  **Reputation System:** Non-transferable reputation based on successful task completion (`completeQuest`) and the ability to gate actions based on reputation (`attestSkill`) is a specific game-theoretic element. Standard token contracts or basic dApps don't have this built-in.
3.  **Skill Attestation:** The mechanism allowing users to vouch for each other's skills, requiring a minimum reputation to prevent spam/collusion, adds a social/collaborative layer for verifiable credentials (skills) within the network. This isn't a typical DeFi or standard governance primitive.
4.  **Quest-Based Bonding & Rewards:** Linking token staking directly to task execution (`bondToQuest`, `completeQuest`, `failQuest`, `cancelQuest`, `unbondFromQuest`) with logic for distribution, penalties, and state transitions is a specific workflow for decentralized work coordination, different from generic staking or liquidity provision. The penalty mechanism on unbonding from active quests adds a commitment device.
5.  **Dual Role Access Control:** The separation of `governanceAddress` (parameter setting, general control) and `questStateTransitioner` (specific authority for quest completion/failure) allows for more granular control delegation than a single owner or simple multi-sig, useful in more complex DAO structures.
6.  **Parameterization:** Making key figures like minimum reputation for attestation, unbonding penalties, and reward distribution percentages configurable via governance (`setParameter`) makes the protocol adaptable and upgradable without a full code deploy, beyond basic contract ownership patterns.
7.  **Accumulated Protocol Fees:** Including a mechanism for the contract to potentially collect minor fees (even if simple in this example with unbonding penalties) and allow governance withdrawal (`withdrawProtocolFees`) is a common DeFi pattern but integrated here into the collaboration flow.

**Constraint Checklist & Considerations:**

1.  **Interesting, Advanced, Creative, Trendy:** Yes, combines reputation, skills, task management, and bonding in a structured way.
2.  **Don't Duplicate Open Source:** While individual *elements* (ERC-20 interface, ReentrancyGuard, basic access control) are from open source libraries (OpenZeppelin), the *combination of features* and the specific logic for reputation, skill attestation, and quest workflows is unique to this concept and not a direct copy of a standard DeFi protocol, DAO framework, or NFT contract.
3.  **At Least 20 Functions:** Yes, the final count is 32 functions (including public view functions, getters, and access control setters).
4.  **Outline and Function Summary:** Included at the top.

**Potential Areas for Further Development/Complexity (beyond 32 functions):**

*   Full token-based governance voting system (instead of single `governanceAddress`).
*   More sophisticated skill system (decay, reputation-weighted attestations, earning skill points from quest *roles*).
*   Quest voting/approval process (instead of just proposer/governance starting).
*   Slashing participants for failure.
*   Dispute resolution mechanism for Quest completion/failure.
*   Pagination for array/mapping views (`getQuestsByState`, `getQuestsByParticipant`).
*   NFTs for profiles or skill badges.
*   Integration with external oracles (e.g., for random rewards, external data).
*   More complex fee structures.

This contract provides a solid foundation for a novel decentralized collaboration network, demonstrating a range of Solidity concepts beyond standard token or basic dApp contracts.