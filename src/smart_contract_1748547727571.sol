Okay, here is a Solidity smart contract for a "Decentralized Collaborative Network" or "Synthetica Guild".

This contract aims to be interesting and leverage several concepts:
1.  **Merit-Based Governance:** Decision power (like quest approval) is based on accumulated 'Merit' within the system, not simple token holdings or 1-person-1-vote.
2.  **Epoch Rewards:** Funds in the treasury are distributed periodically (epochs) based on the Merit earned *during* that specific epoch, incentivizing continuous contribution.
3.  **Dynamic Quests:** A system for proposing, approving (via merit-based signaling), assigning, and verifying tasks ("Quests") which are the primary way to earn Merit.
4.  **Role-Based Access:** Simple owner/admin/verifier roles managed within the contract.
5.  **Time-Based State Transitions:** Epoch finalization is triggered by time elapsed.

It avoids directly copying standard interfaces like ERC20 (though it handles ETH) or standard DAO frameworks like OpenZeppelin's Governor, implementing custom logic for merit tracking, quest lifecycle, and epoch rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Synthetica Guild: Decentralized Collaborative Network
 * @dev A contract for a merit-based decentralized collaborative network managing Quests and distributing Epoch Rewards.
 * @author [Your Name/Handle] - (Designed to be a unique concept, not copy-pasted)
 *
 * Outline:
 * 1. Contract Overview & Core Concepts
 * 2. Errors
 * 3. Events
 * 4. Enums & Structs
 * 5. State Variables
 * 6. Modifiers
 * 7. Constructor
 * 8. Admin & Ownership Functions
 * 9. Member Management Functions
 * 10. Treasury Management Functions
 * 11. Quest Management Functions (Propose, Approve, Assign, Complete, Cancel)
 * 12. Epoch & Reward Functions (Finalize, Claim)
 * 13. View Functions (Getters for state variables and computed values)
 *
 * Function Summary:
 * - Admin/Ownership: Functions to manage the contract owner, administrators, and verifiers, and set core parameters.
 *   - constructor: Initializes the contract owner and epoch duration.
 *   - transferOwnership: Transfers contract ownership.
 *   - addAdmin: Adds an admin address.
 *   - removeAdmin: Removes an admin address.
 *   - isAdmin: Checks if an address is an admin.
 *   - addVerifier: Adds a verifier address (for quest completion).
 *   - removeVerifier: Removes a verifier address.
 *   - isVerifier: Checks if an address is a verifier.
 *   - setEpochDuration: Sets the duration of an epoch.
 *   - setRequiredApprovalMerit: Sets the total merit needed to approve a quest.
 *   - setMinimumMeritForProposing: Sets minimum merit required to propose a quest.
 *   - slashMemberMerit: Reduces a member's total and epoch merit (admin function).
 *   - kickMember: Deactivates a member (admin function).
 * - Member Management: Functions for users to join/leave and query member status.
 *   - joinNetwork: Allows an address to become a member.
 *   - leaveNetwork: Allows a member to leave the network.
 *   - isMember: Checks if an address is an active member.
 *   - getMemberInfo: Retrieves detailed information about a member.
 * - Treasury Management: Functions for funding the contract and withdrawals (by owner/admin).
 *   - depositEth: Allows anyone to send ETH to the contract treasury.
 *   - withdrawEth: Allows owner/admin to withdraw ETH from the treasury.
 *   - getTreasuryBalance: Gets the current ETH balance of the contract.
 * - Quest Management: The core workflow for collaborative tasks.
 *   - proposeQuest: Allows a member with sufficient merit to propose a new quest.
 *   - signalQuestApproval: Member signals support for a proposed quest (adds their merit to approval total).
 *   - revokeQuestApproval: Member removes their support for a proposed quest.
 *   - assignToQuest: Member assigns themselves to work on an approved quest.
 *   - submitQuestCompletion: Assigned member submits evidence of completion.
 *   - verifyQuestCompletion: Verifier marks a submitted quest as completed or failed, distributing merit if successful.
 *   - cancelQuest: Proposer or admin can cancel a quest.
 *   - getQuest: Retrieves details about a quest.
 *   - getQuestState: Gets the current state of a quest.
 *   - getQuestTotalApprovalMerit: Gets the current cumulative merit signaling approval for a quest.
 * - Epoch & Reward System: Handles time periods and merit-based reward distribution.
 *   - finalizeEpoch: Triggers the end of an epoch, calculates the reward rate based on treasury balance and total epoch merit, and prepares for claims. Callable by anyone after duration.
 *   - claimEpochReward: Allows a member to claim their proportional share of the finalized epoch's reward based on their epoch merit.
 *   - getCurrentEpoch: Gets the current epoch number.
 *   - getTimeUntilNextEpochEnd: Calculates time remaining until the current epoch ends.
 *   - getClaimableEpochReward: Calculates the ETH a member can claim from the last finalized epoch.
 *   - getEpochData: Retrieves historical data for a finalized epoch.
 * - General Views:
 *   - getRequiredApprovalMerit: Gets the required merit for quest approval.
 *   - getMinimumMeritForProposing: Gets the minimum merit to propose a quest.
 */

contract SyntheticaGuild {

    // --- 2. Errors ---
    error NotOwner();
    error NotAdmin();
    error NotVerifier();
    error NotMember();
    error MemberAlreadyActive();
    error MemberAlreadyInactive();
    error InsufficientMeritForAction(uint256 required, uint256 has);
    error QuestNotFound();
    error QuestNotInState(string requiredState);
    error QuestStateTransitionInvalid(string currentState, string attemptedAction);
    error NotQuestProposer();
    error NotQuestAssignee();
    error NoEthToWithdraw();
    error InsufficientBalance(uint256 requested, uint256 available);
    error EpochNotEndedYet(uint256 timeRemaining);
    error EpochAlreadyFinalized();
    error EpochNotFinalized();
    error NoMeritEarnedThisEpoch();
    error RewardAlreadyClaimed();
    error QuestAlreadyApproved();
    error QuestNotApproved();
    error ApprovalSignalAlreadyExists();
    error ApprovalSignalNotFound();
    error EpochDataNotFound();
    error QuestAlreadyAssigned();
    error InvalidEvidenceHash();
    error CannotCancelAfterApproval();

    // --- 3. Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event MemberJoined(address indexed member);
    event MemberLeft(address indexed member);
    event EthDeposited(address indexed depositor, uint256 amount);
    event EthWithdrawn(address indexed recipient, uint256 amount);
    event QuestProposed(uint256 indexed questId, address indexed proposer, string description, uint256 meritReward, uint256 requiredCompletionMerit);
    event QuestApprovalSignaled(uint256 indexed questId, address indexed signaler, uint256 totalApprovalMerit);
    event QuestApprovalRevoked(uint256 indexed questId, address indexed signaler, uint256 totalApprovalMerit);
    event QuestApproved(uint256 indexed questId);
    event QuestAssigned(uint256 indexed questId, address indexed assignee);
    event QuestCompletionSubmitted(uint256 indexed questId, address indexed submitter, string evidenceHash);
    event QuestVerified(uint256 indexed questId, bool success);
    event QuestMeritAwarded(uint256 indexed questId, address indexed member, uint256 meritAmount);
    event QuestCancelled(uint256 indexed questId);
    event EpochFinalized(uint256 indexed epochId, uint256 totalMeritThisEpoch, uint256 ethTreasuryBalance, uint256 ethDistributed, uint256 meritEthRate);
    event EpochRewardClaimed(uint256 indexed epochId, address indexed member, uint256 meritEarned, uint256 ethAmount);
    event MemberMeritSlashed(address indexed member, uint256 amount);
    event MemberKicked(address indexed member);

    // --- 4. Enums & Structs ---

    enum QuestState { Proposed, Approved, InProgress, Completed, Failed, Cancelled }

    struct Member {
        bool isActive;
        uint256 totalMerit; // Cumulative merit across all epochs
        uint256 currentEpochMerit; // Merit earned in the current (or last finalized) epoch
        bool epochRewardClaimed; // Flag for claiming reward in the last finalized epoch
        uint256 failedQuestCount; // Count of quests they were assigned and failed
        uint256 lastEpochClaimed; // The epoch ID they last claimed rewards for
    }

    struct Quest {
        uint256 id;
        address proposer;
        string description;
        uint256 meritReward; // Merit awarded upon successful completion
        uint256 requiredCompletionMerit; // Minimum merit proposer thinks is needed for assignee
        QuestState state;
        address assignedTo; // Address of the member assigned to the quest (single assignee for simplicity)
        string completionEvidenceHash; // Hash or link to evidence
        mapping(address => bool) approvalSignals; // Members who signaled approval
    }

    struct EpochData {
        uint256 totalMerit; // Total merit earned by all members in this epoch
        uint256 ethDistributed; // Total ETH distributed in this epoch
        uint256 meritEthRate; // Rate: (ETH distributed / total merit) * 1e18 (scaled for fixed point)
        bool finalized; // Has this epoch been finalized?
    }

    // --- 5. State Variables ---

    address public owner;
    mapping(address => bool) private admins;
    mapping(address => bool) private verifiers;

    mapping(address => Member) public members;
    uint256 public memberCount; // Track active members

    mapping(uint256 => Quest) public quests;
    uint256 private nextQuestId = 1; // Start quest IDs from 1

    mapping(uint256 => uint256) public questApprovalMeritTotal; // Sum of totalMerit of members who signaled approval

    uint256 public currentEpoch = 1;
    uint256 public epochStartTime;
    uint256 public epochDuration; // In seconds

    mapping(uint256 => EpochData) public epochData; // Historical data for finalized epochs

    // Configurable parameters
    uint256 public requiredApprovalMerit = 100; // Default merit needed from approvers
    uint256 public minimumMeritForProposing = 50; // Default minimum merit to propose a quest

    // --- 6. Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != owner && !admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier onlyVerifier() {
        if (msg.sender != owner && !admins[msg.sender] && !verifiers[msg.sender]) revert NotVerifier();
        _;
    }

    modifier onlyMember() {
        if (!members[msg.sender].isActive) revert NotMember();
        _;
    }

    // --- 7. Constructor ---

    constructor(uint256 _epochDuration) {
        owner = msg.sender;
        epochStartTime = block.timestamp;
        epochDuration = _epochDuration;
    }

    // --- 8. Admin & Ownership Functions ---

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert NotOwner(); // Prevent null address ownership
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Adds an address to the list of administrators. Admins have elevated privileges.
     * @param _admin The address to add as an admin.
     */
    function addAdmin(address _admin) external onlyOwner {
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    /**
     * @dev Removes an address from the list of administrators.
     * @param _admin The address to remove from admins.
     */
    function removeAdmin(address _admin) external onlyOwner {
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    /**
     * @dev Checks if an address is currently an administrator.
     * @param _admin The address to check.
     * @return bool True if the address is an admin, false otherwise.
     */
    function isAdmin(address _admin) external view returns (bool) {
        return admins[_admin];
    }

    /**
     * @dev Adds an address to the list of verifiers. Verifiers can mark quest completion.
     * @param _verifier The address to add as a verifier.
     */
    function addVerifier(address _verifier) external onlyAdmin {
        verifiers[_verifier] = true;
        emit VerifierAdded(_verifier);
    }

    /**
     * @dev Removes an address from the list of verifiers.
     * @param _verifier The address to remove from verifiers.
     */
    function removeVerifier(address _verifier) external onlyAdmin {
        verifiers[_verifier] = false;
        emit VerifierRemoved(_verifier);
    }

    /**
     * @dev Checks if an address is currently a verifier. Owner and Admins are implicitly verifiers.
     * @param _verifier The address to check.
     * @return bool True if the address is a verifier (or owner/admin), false otherwise.
     */
    function isVerifier(address _verifier) external view returns (bool) {
        return _verifier == owner || admins[_verifier] || verifiers[_verifier];
    }

    /**
     * @dev Sets the duration of each epoch in seconds. Affects when epochs can be finalized.
     * @param _duration The new epoch duration in seconds.
     */
    function setEpochDuration(uint256 _duration) external onlyAdmin {
        epochDuration = _duration;
    }

    /**
     * @dev Sets the cumulative merit required from distinct members to approve a quest.
     * @param _requiredMerit The new minimum required merit sum.
     */
    function setRequiredApprovalMerit(uint256 _requiredMerit) external onlyAdmin {
        requiredApprovalMerit = _requiredMerit;
    }

    /**
     * @dev Sets the minimum total merit a member must have to propose a quest.
     * @param _minimumMerit The new minimum merit requirement.
     */
    function setMinimumMeritForProposing(uint256 _minimumMerit) external onlyAdmin {
        minimumMeritForProposing = _minimumMerit;
    }

    /**
     * @dev Slashes (reduces) a member's total and current epoch merit.
     * @param _member The address of the member to slash.
     * @param _amount The amount of merit to slash.
     */
    function slashMemberMerit(address _member, uint256 _amount) external onlyAdmin {
         if (!members[_member].isActive) revert NotMember();

        uint256 slashAmount = _amount;
        if (members[_member].totalMerit < slashAmount) {
            slashAmount = members[_member].totalMerit; // Cannot slash more than they have
        }

        members[_member].totalMerit -= slashAmount;

        if (members[_member].currentEpochMerit < slashAmount) {
             members[_member].currentEpochMerit = 0;
        } else {
            members[_member].currentEpochMerit -= slashAmount;
        }

        // If epoch is not finalized, also reduce total epoch merit for current epoch calculation
        if (!epochData[currentEpoch].finalized) {
             if (epochData[currentEpoch].totalMerit < slashAmount) {
                epochData[currentEpoch].totalMerit = 0;
             } else {
                 epochData[currentEpoch].totalMerit -= slashAmount;
             }
        }

        emit MemberMeritSlashed(_member, slashAmount);
    }

    /**
     * @dev Kicks a member from the network by setting their status to inactive.
     * @param _member The address of the member to kick.
     */
    function kickMember(address _member) external onlyAdmin {
        if (!members[_member].isActive) revert MemberAlreadyInactive();
        members[_member].isActive = false;
        memberCount--;
        emit MemberKicked(_member);
    }


    // --- 9. Member Management Functions ---

    /**
     * @dev Allows a new address to join the network as an active member.
     * Requires the address not to be an existing active member.
     */
    function joinNetwork() external {
        if (members[msg.sender].isActive) revert MemberAlreadyActive();
        members[msg.sender].isActive = true;
        members[msg.sender].totalMerit = 0;
        members[msg.sender].currentEpochMerit = 0;
        members[msg.sender].epochRewardClaimed = false;
        members[msg.sender].failedQuestCount = 0;
        members[msg.sender].lastEpochClaimed = 0;
        memberCount++;
        emit MemberJoined(msg.sender);
    }

    /**
     * @dev Allows an active member to leave the network.
     * Their merit is preserved but they cannot participate or earn rewards.
     */
    function leaveNetwork() external onlyMember {
        if (!members[msg.sender].isActive) revert MemberAlreadyInactive();
        members[msg.sender].isActive = false;
        memberCount--;
        emit MemberLeft(msg.sender);
    }

    /**
     * @dev Checks if an address is an active member of the network.
     * @param _member The address to check.
     * @return bool True if the address is an active member, false otherwise.
     */
    function isMember(address _member) external view returns (bool) {
        return members[_member].isActive;
    }

    /**
     * @dev Retrieves information about a member.
     * @param _member The address of the member.
     * @return bool isActive Status.
     * @return uint256 totalMerit Cumulative merit.
     * @return uint256 currentEpochMerit Merit earned in the current/last epoch.
     * @return bool epochRewardClaimed Whether reward claimed for the last finalized epoch.
     * @return uint256 failedQuestCount Count of failed assigned quests.
     * @return uint256 lastEpochClaimed The ID of the last epoch claimed.
     */
    function getMemberInfo(address _member)
        external
        view
        returns (
            bool isActive,
            uint256 totalMerit,
            uint256 currentEpochMerit,
            bool epochRewardClaimed,
            uint256 failedQuestCount,
            uint256 lastEpochClaimed
        )
    {
        Member storage member = members[_member];
        return (
            member.isActive,
            member.totalMerit,
            member.currentEpochMerit,
            member.epochRewardClaimed,
            member.failedQuestCount,
            member.lastEpochClaimed
        );
    }


    // --- 10. Treasury Management Functions ---

    /**
     * @dev Allows anyone to deposit ETH into the contract's treasury.
     * @param amount The amount of ETH to deposit (implicit from msg.value).
     */
    receive() external payable {
        if (msg.value == 0) revert InsufficientBalance(0, 0); // Should technically not happen with payable, but good practice
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Alias for receive function.
     */
    function depositEth() external payable {
         if (msg.value == 0) revert InsufficientBalance(0, 0);
         emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner or an admin to withdraw ETH from the treasury.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdrawEth(uint256 _amount) external onlyAdmin {
        if (address(this).balance == 0) revert NoEthToWithdraw();
        if (address(this).balance < _amount) revert InsufficientBalance(_amount, address(this).balance);

        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "ETH transfer failed"); // Using require for critical state change
        emit EthWithdrawn(msg.sender, _amount);
    }

    /**
     * @dev Gets the current ETH balance held by the contract.
     * @return uint256 The current ETH balance.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- 11. Quest Management Functions ---

    /**
     * @dev Allows a member with sufficient merit to propose a new quest.
     * @param _description A description of the quest.
     * @param _meritReward The amount of merit the assigned member will earn upon successful completion.
     * @param _requiredCompletionMerit An indication of the merit level expected for a suitable assignee.
     * @return uint256 The ID of the newly created quest.
     */
    function proposeQuest(string memory _description, uint256 _meritReward, uint256 _requiredCompletionMerit) external onlyMember returns (uint256) {
        if (members[msg.sender].totalMerit < minimumMeritForProposing) {
            revert InsufficientMeritForAction(minimumMeritForProposing, members[msg.sender].totalMerit);
        }

        uint256 questId = nextQuestId++;
        quests[questId].id = questId;
        quests[questId].proposer = msg.sender;
        quests[questId].description = _description;
        quests[questId].meritReward = _meritReward;
        quests[questId].requiredCompletionMerit = _requiredCompletionMerit;
        quests[questId].state = QuestState.Proposed;

        emit QuestProposed(questId, msg.sender, _description, _meritReward, _requiredCompletionMerit);
        return questId;
    }

    /**
     * @dev Allows a member to signal their approval for a proposed quest.
     * Their current total merit is added to the quest's approval total.
     * @param _questId The ID of the quest to approve.
     */
    function signalQuestApproval(uint256 _questId) external onlyMember {
        Quest storage quest = quests[_questId];
        if (quest.id == 0) revert QuestNotFound();
        if (quest.state != QuestState.Proposed) revert QuestNotInState("Proposed");
        if (quest.approvalSignals[msg.sender]) revert ApprovalSignalAlreadyExists();

        quest.approvalSignals[msg.sender] = true;
        questApprovalMeritTotal[_questId] += members[msg.sender].totalMerit;

        emit QuestApprovalSignaled(_questId, msg.sender, questApprovalMeritTotal[_questId]);

        // Automatically transition to Approved if threshold met
        if (questApprovalMeritTotal[_questId] >= requiredApprovalMerit) {
            quest.state = QuestState.Approved;
            emit QuestApproved(_questId);
        }
    }

    /**
     * @dev Allows a member to revoke their approval signal for a proposed quest.
     * Removes their merit from the quest's approval total.
     * @param _questId The ID of the quest to revoke approval for.
     */
    function revokeQuestApproval(uint256 _questId) external onlyMember {
        Quest storage quest = quests[_questId];
        if (quest.id == 0) revert QuestNotFound();
        if (quest.state != QuestState.Proposed) revert QuestNotInState("Proposed");
        if (!quest.approvalSignals[msg.sender]) revert ApprovalSignalNotFound();

        quest.approvalSignals[msg.sender] = false;
        questApprovalMeritTotal[_questId] -= members[msg.sender].totalMerit;

        emit QuestApprovalRevoked(_questId, msg.sender, questApprovalMeritTotal[_questId]);
    }

    /**
     * @dev Allows a member to assign themselves to an approved quest.
     * Quest state changes to InProgress. Only one assignee allowed for simplicity.
     * @param _questId The ID of the quest to assign to.
     */
    function assignToQuest(uint256 _questId) external onlyMember {
        Quest storage quest = quests[_questId];
        if (quest.id == 0) revert QuestNotFound();
        if (quest.state != QuestState.Approved) revert QuestNotInState("Approved");
        if (quest.assignedTo != address(0)) revert QuestAlreadyAssigned();

        quest.assignedTo = msg.sender;
        quest.state = QuestState.InProgress;
        emit QuestAssigned(_questId, msg.sender);
    }

    /**
     * @dev Allows the assigned member to submit evidence of quest completion.
     * Quest state remains InProgress, awaiting verification.
     * @param _questId The ID of the quest.
     * @param _evidenceHash A hash or link representing the completion evidence.
     */
    function submitQuestCompletion(uint256 _questId, string memory _evidenceHash) external onlyMember {
        Quest storage quest = quests[_questId];
        if (quest.id == 0) revert QuestNotFound();
        if (quest.state != QuestState.InProgress) revert QuestNotInState("InProgress");
        if (quest.assignedTo != msg.sender) revert NotQuestAssignee();
        if (bytes(_evidenceHash).length == 0) revert InvalidEvidenceHash();

        quest.completionEvidenceHash = _evidenceHash;
        // No state change yet, needs verification
        emit QuestCompletionSubmitted(_questId, msg.sender, _evidenceHash);
    }

    /**
     * @dev Allows a verifier to mark a submitted quest as completed or failed.
     * If successful, awards merit to the assigned member.
     * @param _questId The ID of the quest to verify.
     * @param _success True if the quest was successfully completed, false if failed.
     */
    function verifyQuestCompletion(uint256 _questId, bool _success) external onlyVerifier {
        Quest storage quest = quests[_questId];
        if (quest.id == 0) revert QuestNotFound();
        if (quest.state != QuestState.InProgress) revert QuestNotInState("InProgress");
        if (quest.assignedTo == address(0)) revert QuestStateTransitionInvalid("InProgress", "Verify (no assignee)"); // Should not happen if assigned correctly
        // Check if completion evidence was submitted? Optional, assuming verifier checks externally
        // if (bytes(quest.completionEvidenceHash).length == 0) revert QuestStateTransitionInvalid("InProgress", "Verify (no evidence)");

        address assignee = quest.assignedTo;
        // Check if assignee is still an active member? Decide policy. Let's allow earning even if they left *after* assignment.
        // if (!members[assignee].isActive) { /* handle inactive assignee? maybe auto-fail? */ }

        if (_success) {
            quest.state = QuestState.Completed;
            // Award merit to the assigned member
            uint256 meritAmount = quest.meritReward;
            members[assignee].totalMerit += meritAmount;
            members[assignee].currentEpochMerit += meritAmount;

            // Add to total merit for current epoch distribution
            // Only if the epoch hasn't been finalized yet
            if (!epochData[currentEpoch].finalized) {
                 epochData[currentEpoch].totalMerit += meritAmount;
            }


            emit QuestVerified(_questId, true);
            emit QuestMeritAwarded(_questId, assignee, meritAmount);

        } else {
            quest.state = QuestState.Failed;
            // Penalize assignee? Increment failed count.
            members[assignee].failedQuestCount++;
            emit QuestVerified(_questId, false);
        }

        // Clear assignedTo regardless of outcome
        quest.assignedTo = address(0);
        quest.completionEvidenceHash = ""; // Clear evidence hash
    }

    /**
     * @dev Allows the proposer or an admin to cancel a quest.
     * Possible only if the quest is Proposed or Approved.
     * @param _questId The ID of the quest to cancel.
     */
    function cancelQuest(uint256 _questId) external {
        Quest storage quest = quests[_questId];
        if (quest.id == 0) revert QuestNotFound();
        if (msg.sender != quest.proposer && msg.sender != owner && !admins[msg.sender]) {
            revert NotQuestProposer(); // Simplified check, owner/admin can cancel any
        }
        if (quest.state != QuestState.Proposed && quest.state != QuestState.Approved) {
            revert CannotCancelAfterApproval(); // Or maybe allow cancelling InProgress by admin only? Let's restrict.
        }

        // If it was proposed, reset approval merit
        if (quest.state == QuestState.Proposed) {
            questApprovalMeritTotal[_questId] = 0; // Clear accumulated approval merit
            // No need to iterate approvalSignals mapping to clear
        }

        quest.state = QuestState.Cancelled;
        emit QuestCancelled(_questId);
    }

    /**
     * @dev Retrieves detailed information about a quest.
     * @param _questId The ID of the quest.
     * @return struct Quest The quest struct data.
     */
    function getQuest(uint256 _questId) external view returns (Quest memory) {
         if (quests[_questId].id == 0) revert QuestNotFound();
         // Cannot return the mapping field `approvalSignals` directly in public view
         Quest memory quest = quests[_questId];
         delete quest.approvalSignals; // Remove mapping before returning
         return quest;
    }

    /**
     * @dev Gets the current state of a quest.
     * @param _questId The ID of the quest.
     * @return QuestState The current state of the quest.
     */
    function getQuestState(uint256 _questId) external view returns (QuestState) {
        if (quests[_questId].id == 0) revert QuestNotFound();
        return quests[_questId].state;
    }

     /**
     * @dev Gets the total cumulative merit that has signaled approval for a proposed quest.
     * @param _questId The ID of the quest.
     * @return uint256 The sum of total merit from members who signaled approval.
     */
    function getQuestTotalApprovalMerit(uint256 _questId) external view returns (uint256) {
        if (quests[_questId].id == 0) revert QuestNotFound(); // Check if quest exists
        // This value is stored in a separate mapping questApprovalMeritTotal
        return questApprovalMeritTotal[_questId];
    }


    // --- 12. Epoch & Reward Functions ---

    /**
     * @dev Finalizes the current epoch, making rewards claimable.
     * Can be called by anyone once the epoch duration has passed.
     * Calculates the ETH/Merit rate for this epoch based on treasury balance and total epoch merit.
     */
    function finalizeEpoch() external {
        uint256 timeElapsed = block.timestamp - epochStartTime;
        if (timeElapsed < epochDuration) {
            revert EpochNotEndedYet(epochDuration - timeElapsed);
        }
        if (epochData[currentEpoch].finalized) {
            revert EpochAlreadyFinalized();
        }

        uint256 totalMeritThisEpoch = epochData[currentEpoch].totalMerit;
        uint256 ethBalanceAtFinalization = address(this).balance; // ETH available *now*

        uint256 meritEthRate = 0;
        uint256 ethDistributed = 0;

        // Calculate rate only if there's merit and ETH
        if (totalMeritThisEpoch > 0 && ethBalanceAtFinalization > 0) {
             // Calculate fixed-point rate (e.g., scaled by 1e18)
             // rate = (ethBalance * 1e18) / totalMerit
            meritEthRate = (ethBalanceAtFinalization * 1e18) / totalMeritThisEpoch;
            ethDistributed = ethBalanceAtFinalization; // Assume all available ETH is for distribution
        }

        // Store finalized epoch data
        epochData[currentEpoch].totalMerit = totalMeritThisEpoch;
        epochData[currentEpoch].ethDistributed = ethDistributed;
        epochData[currentEpoch].meritEthRate = meritEthRate;
        epochData[currentEpoch].finalized = true;

        // Increment epoch and reset start time for the next one
        uint256 finalizedEpochId = currentEpoch; // Capture before incrementing
        currentEpoch++;
        epochStartTime = block.timestamp; // Start next epoch immediately

        // Reset epochRewardClaimed flag for all *active* members for the *next* epoch's claiming
        // NOTE: Resetting this for ALL members iterating is gas-prohibitive on-chain.
        // A better pattern is lazy resetting: members' claim function checks if lastEpochClaimed < finalizedEpochId.
        // The epochRewardClaimed flag in Member struct is thus redundant if using lastEpochClaimed check.
        // Let's rely on `lastEpochClaimed < finalizedEpochId` check in `claimEpochReward`.

        emit EpochFinalized(finalizedEpochId, totalMeritThisEpoch, ethBalanceAtFinalization, ethDistributed, meritEthRate);
    }


    /**
     * @dev Allows a member to claim their share of the ETH rewards for a finalized epoch.
     * Rewards are proportional to the member's merit earned in that epoch.
     */
    function claimEpochReward() external onlyMember {
        uint256 epochToClaim = currentEpoch - 1; // Rewards are for the *last* finalized epoch

        if (epochToClaim == 0) { // No epochs have finished yet (only epoch 1 is active)
             revert EpochNotFinalized(); // More accurately, no epoch to claim
        }
        if (!epochData[epochToClaim].finalized) {
            revert EpochNotFinalized();
        }
         if (members[msg.sender].lastEpochClaimed >= epochToClaim) {
            revert RewardAlreadyClaimed();
        }


        uint256 memberEpochMerit = members[msg.sender].currentEpochMerit;
        if (memberEpochMerit == 0) {
            revert NoMeritEarnedThisEpoch(); // Or maybe revert if claimable reward is 0?
        }

        uint256 meritEthRate = epochData[epochToClaim].meritEthRate;
        // Calculate reward: (memberMerit * rate) / 1e18
        uint256 rewardAmount = (memberEpochMerit * meritEthRate) / 1e18;

        if (rewardAmount > 0) {
             (bool success,) = payable(msg.sender).call{value: rewardAmount}("");
            require(success, "Reward ETH transfer failed"); // Using require for critical transfer
        }

        // Reset member's epoch merit after claiming
        members[msg.sender].currentEpochMerit = 0;
        members[msg.sender].lastEpochClaimed = epochToClaim; // Mark this epoch as claimed

        emit EpochRewardClaimed(epochToClaim, msg.sender, memberEpochMerit, rewardAmount);
    }

    /**
     * @dev Gets the current epoch number.
     * @return uint256 The current epoch ID.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

     /**
     * @dev Calculates the time remaining until the current epoch ends.
     * Returns 0 if the epoch has already ended.
     * @return uint256 Time remaining in seconds.
     */
    function getTimeUntilNextEpochEnd() external view returns (uint256) {
        uint256 elapsed = block.timestamp - epochStartTime;
        if (elapsed >= epochDuration) {
            return 0;
        } else {
            return epochDuration - elapsed;
        }
    }

     /**
     * @dev Calculates the ETH amount a member can claim from the last finalized epoch.
     * @param _member The address of the member.
     * @return uint256 The claimable ETH amount.
     */
    function getClaimableEpochReward(address _member) external view returns (uint256) {
        uint256 epochToClaim = currentEpoch - 1;
        if (epochToClaim == 0 || !epochData[epochToClaim].finalized) {
            return 0; // No epoch to claim from yet or not finalized
        }

         Member memory member = members[_member];
        if (member.lastEpochClaimed >= epochToClaim) {
            return 0; // Already claimed for this epoch or a later one
        }

        uint256 memberEpochMerit = member.currentEpochMerit;
        if (memberEpochMerit == 0) {
            return 0; // No merit earned in this epoch
        }

        uint256 meritEthRate = epochData[epochToClaim].meritEthRate;
        // Calculate reward: (memberMerit * rate) / 1e18
         // Use a safe multiplication pattern if dealing with very large numbers, though uint256 is large.
        uint256 rewardAmount = (memberEpochMerit * meritEthRate) / 1e18;

        return rewardAmount;
    }

    /**
     * @dev Retrieves the finalized data for a specific epoch.
     * @param _epochId The ID of the epoch.
     * @return uint256 totalMerit Total merit earned in this epoch.
     * @return uint256 ethDistributed Total ETH distributed.
     * @return uint256 meritEthRate The ETH/Merit rate for this epoch (scaled by 1e18).
     * @return bool finalized Whether the epoch was finalized.
     */
    function getEpochData(uint256 _epochId) external view returns (uint256 totalMerit, uint256 ethDistributed, uint256 meritEthRate, bool finalized) {
        if (_epochId == 0 || _epochId >= currentEpoch || !epochData[_epochId].finalized) {
             // Cannot get data for epoch 0, future epochs, or unfinalized current epoch
            revert EpochDataNotFound();
        }
        EpochData memory data = epochData[_epochId];
        return (data.totalMerit, data.ethDistributed, data.meritEthRate, data.finalized);
    }

    // --- 13. General Views ---

    /**
     * @dev Gets the current required cumulative merit for quest approval.
     * @return uint256 The required merit value.
     */
    function getRequiredApprovalMerit() external view returns (uint256) {
        return requiredApprovalMerit;
    }

    /**
     * @dev Gets the minimum total merit required for a member to propose a quest.
     * @return uint256 The minimum merit value.
     */
     function getMinimumMeritForProposing() external view returns (uint256) {
         return minimumMeritForProposing;
     }
}
```