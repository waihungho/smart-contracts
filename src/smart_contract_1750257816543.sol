Okay, let's craft a smart contract that incorporates several interesting and advanced concepts without directly copying common open-source patterns like standard ERC20/ERC721, simple multi-sigs, or basic fixed-quorum DAOs.

We'll build a "Quantum Quorum" system. The core idea is a decentralized governance mechanism where members have a "Quantum Score" representing their reputation/influence, which decays over time if they are inactive but boosts upon participation. The unique part is a *dynamically adjusting quorum percentage* required for proposals to pass, influenced by the *system-wide engagement* and *average voter quality* in the previous governance epoch.

**Advanced Concepts Used:**

1.  **Dynamic Quorum:** Quorum percentage (required voting power participation) changes based on past system activity.
2.  **Reputation System (Quantum Score):** Members have a score influencing vote weight, which decays with inactivity and boosts with activity.
3.  **Epoch-based Mechanics:** Reputation decay and quorum adjustment happen cyclically.
4.  **Weighted Voting:** Vote power scales directly with Quantum Score.
5.  **Permissioned Membership (Initial):** Start with owner adding members, could be expanded to vote-based later.
6.  **Executable Proposals:** Proposals can trigger actions (like changing contract parameters or calling other approved contracts).
7.  **Approved Call Targets:** Restricting external calls to a whitelist for security.
8.  **Pause Mechanism:** Emergency pause functionality.
9.  **Complex State Interactions:** Member activity, epoch progress, vote outcomes, and system stats all feed into the dynamic quorum calculation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumQuorum
 * @dev A decentralized governance contract with dynamic quorum and reputation system.
 *
 * Outline:
 * 1. State Variables: Core parameters, member data, proposal data, epoch tracking, quorum stats.
 * 2. Events: Significant actions like member changes, proposals, votes, executions, epoch events.
 * 3. Enums & Structs: Define states and data structures for proposals and members.
 * 4. Modifiers: Restrict function access based on roles or state.
 * 5. Admin Functions: Owner-controlled setup and emergency functions.
 * 6. Membership Management: Adding/removing members.
 * 7. Proposals & Voting: Submitting, viewing, and voting on proposals.
 * 8. Proposal Execution: Executing passed proposals.
 * 9. Epoch & Reputation Management: Triggering epoch end, handling reputation decay and quorum adjustment.
 * 10. Views: Public functions to query contract state.
 *
 * Function Summary:
 *
 * Admin Functions:
 * - constructor(): Initializes contract owner, initial parameters.
 * - transferOwnership(): Transfers contract ownership.
 * - pauseContract(): Pauses contract functionality in case of emergency.
 * - unpauseContract(): Unpauses the contract.
 * - setEpochDuration(): Sets the length of an epoch.
 * - setReputationDecayRate(): Sets the percentage of Quantum Score decay per epoch.
 * - setReputationBoostAmount(): Sets the amount of Quantum Score boost per activity.
 * - setMinMaxQuorum(): Sets the minimum and maximum bounds for the dynamic quorum percentage.
 * - setMinInitialQuantumScore(): Sets the minimum initial score for new members.
 * - addApprovedCallTarget(): Whitelists an address that proposals can call.
 * - removeApprovedCallTarget(): Removes an address from the call whitelist.
 *
 * Membership Functions:
 * - addMember(): Adds a new member with an initial Quantum Score (owner only initially).
 * - removeMember(): Removes a member (owner only initially, could be voted on later).
 *
 * Proposal & Voting Functions:
 * - submitProposal(): Allows a member to submit a new governance proposal.
 * - voteOnProposal(): Allows a member to cast a weighted vote (Yes/No) on an active proposal.
 *
 * Execution Functions:
 * - executeProposal(): Executes a proposal that has met the required quorum and threshold after voting ends.
 *
 * Epoch & Reputation Functions:
 * - triggerEpochEnd(): Callable function to process epoch-end events (decay, quorum adjustment).
 *
 * Views:
 * - getMemberQuantumScore(): Gets the current Quantum Score of a member.
 * - getTotalQuantumSupply(): Gets the sum of all active members' Quantum Scores (total voting power).
 * - getProposalState(): Gets the current state of a proposal.
 * - getCurrentQuorumPercentage(): Gets the current dynamic quorum percentage required.
 * - getEpochEndTime(): Gets the timestamp when the current epoch will end.
 * - getMemberLastActivity(): Gets the timestamp of a member's last voting or proposal activity.
 * - getApprovedCallTargets(): Gets the list of currently approved addresses for proposal calls.
 * - getProposalDetails(): Gets detailed information about a proposal.
 * - getProposalVoteCounts(): Gets the total Yes/No vote power for a proposal.
 * - getMinInitialQuantumScore(): Gets the minimum initial score for new members.
 */

contract QuantumQuorum {

    // --- State Variables ---

    address public owner;
    bool public paused;

    // Membership
    struct Member {
        bool isActive;
        uint256 quantumScore; // Represents voting power
        uint256 lastActivityTimestamp;
    }
    mapping(address => Member) public members;
    address[] private activeMemberAddresses; // List to iterate active members (potential scalability issue for very large sets)
    uint256 public totalQuantumSupply; // Sum of all active member quantumScores

    // Proposals
    enum ProposalState { Pending, Active, Passed, Failed, Expired }
    struct Proposal {
        address proposer;
        string description;
        bytes callData;       // Data for execution call
        address targetAddress; // Target contract for execution call
        uint256 value;        // Value to send with execution call
        uint256 creationTimestamp;
        uint256 expirationTimestamp; // Voting ends timestamp
        uint256 yesVotesPower; // Total quantumScore of 'Yes' votes
        uint256 noVotesPower;  // Total quantumScore of 'No' votes
        bool executed;
        ProposalState state;
        mapping(address => bool) hasVoted; // To ensure members only vote once per proposal
    }
    Proposal[] public proposals; // Array of all proposals
    uint256 public votingPeriodDuration = 7 days; // Default voting duration

    // Epoch and Reputation
    uint256 public epochDuration = 30 days; // Duration of a governance epoch
    uint256 public lastEpochEndTime;
    uint256 public reputationDecayRate = 5; // Percentage decay per epoch (e.g., 5 = 5%)
    uint256 public reputationBoostAmount = 10; // Fixed score boost per vote/proposal
    uint256 public minInitialQuantumScore = 100; // Minimum score for new members

    // Dynamic Quorum
    // Quorum is the MINIMUM percentage of totalQuantumSupply that must vote YES + NO for a proposal to be CONSIDERED for passing.
    // Passing Threshold is the MINIMUM percentage of total PARTICIPATING vote power (yesVotesPower + noVotesPower) that must be YES.
    uint256 public currentQuorumPercentage = 40; // Starts at 40%
    uint256 public constant passingThresholdPercentage = 51; // Fixed at 51% (simple majority of participating power)
    uint256 public minQuorumPercentage = 20;
    uint256 public maxQuorumPercentage = 60;

    // Epoch Stats for Dynamic Adjustment
    uint256 private epochTotalPotentialVotingPower; // totalQuantumSupply at start of epoch
    uint256 private epochTotalParticipatingVotingPower; // Sum of (yes + no) power across all votes in the epoch
    uint256 private epochVotesCompleted; // Number of proposals whose voting ended in the epoch
    uint256 private epochVotesPassed;    // Number of proposals that met *both* quorum and threshold in the epoch

    // Approved Call Targets for execution
    mapping(address => bool) public approvedCallTargets;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event MemberAdded(address indexed member, uint256 initialScore);
    event MemberRemoved(address indexed member);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description, address target, bytes callData, uint256 value, uint256 expirationTimestamp);
    event Voted(uint256 indexed proposalId, address indexed voter, bool vote, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event EpochEnded(uint256 indexed epochEndTime, uint256 newQuorumPercentage);
    event ReputationDecayed(address indexed member, uint256 oldScore, uint256 newScore);
    event ReputationBoosted(address indexed member, uint256 oldScore, uint256 newScore);
    event QuorumAdjusted(uint256 indexed oldQuorumPercentage, uint256 indexed newQuorumPercentage, uint256 epochParticipationRate, uint256 epochSuccessRate);
    event ApprovedCallTargetAdded(address indexed target);
    event ApprovedCallTargetRemoved(address indexed target);

    // --- Enums & Structs (Defined above) ---

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActive, "Not an active member");
        _;
    }

    modifier onlyActiveProposal(uint256 proposalId) {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.expirationTimestamp, "Proposal voting ended");
        _;
    }

    modifier onlyEndedProposal(uint256 proposalId) {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active && block.timestamp > proposal.expirationTimestamp, "Proposal voting not ended");
        _;
    }

    modifier onlyExecutableProposal(uint256 proposalId) {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Passed && !proposal.executed, "Proposal not executable");
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialEpochDuration, uint256 initialVotingPeriod, uint256 initialReputationDecayRate, uint256 initialReputationBoostAmount, uint256 initialMinQuorum, uint256 initialMaxQuorum, uint256 initialMinInitialScore) {
        owner = msg.sender;
        lastEpochEndTime = block.timestamp + initialEpochDuration; // Set first epoch end
        epochDuration = initialEpochDuration;
        votingPeriodDuration = initialVotingPeriod;
        reputationDecayRate = initialReputationDecayRate;
        reputationBoostAmount = initialReputationBoostAmount;
        minQuorumPercentage = initialMinQuorum;
        maxQuorumPercentage = initialMaxQuorum;
        require(minQuorumPercentage <= maxQuorumPercentage && minQuorumPercentage >= 0 && maxQuorumPercentage <= 100, "Invalid quorum bounds");
        minInitialQuantumScore = initialMinInitialScore;

        // Owner is implicitly the first member with initial score
        addMember(owner, minInitialQuantumScore, false); // Add owner as a member
    }

    // --- Admin Functions ---

    function transferOwnership(address newOwner_) external onlyOwner {
        require(newOwner_ != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner_, block.timestamp);
        owner = newOwner_;
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    function setEpochDuration(uint256 duration) external onlyOwner {
        require(duration > 0, "Duration must be positive");
        epochDuration = duration;
    }

    function setReputationDecayRate(uint256 rate) external onlyOwner {
        require(rate <= 100, "Decay rate cannot exceed 100%");
        reputationDecayRate = rate;
    }

    function setReputationBoostAmount(uint256 amount) external onlyOwner {
        reputationBoostAmount = amount;
    }

     function setMinMaxQuorum(uint256 min, uint256 max) external onlyOwner {
        require(min <= max && min >= 0 && max <= 100, "Invalid quorum bounds");
        minQuorumPercentage = min;
        maxQuorumPercentage = max;
     }

     function setMinInitialQuantumScore(uint256 score) external onlyOwner {
         minInitialQuantumScore = score;
     }

    function addApprovedCallTarget(address target) external onlyOwner {
        require(target != address(0), "Cannot add zero address");
        require(!approvedCallTargets[target], "Target already approved");
        approvedCallTargets[target] = true;
        emit ApprovedCallTargetAdded(target);
    }

    function removeApprovedCallTarget(address target) external onlyOwner {
         require(approvedCallTargets[target], "Target not approved");
         approvedCallTargets[target] = false;
         emit ApprovedCallTargetRemoved(target);
    }

    // --- Membership Functions ---

    // internal function to add a member, used by constructor and potentially future vote-based addMember
    function addMember(address memberAddress, uint256 initialScore, bool isAdminCall) public onlyOwner whenNotPaused {
        // Check if called by owner (initial setup) or internal mechanism
        require(isAdminCall || msg.sender == owner, "Not authorized to add members");
        require(memberAddress != address(0), "Cannot add zero address");
        require(!members[memberAddress].isActive, "Member already active");
        require(initialScore >= minInitialQuantumScore, "Initial score too low");

        members[memberAddress] = Member({
            isActive: true,
            quantumScore: initialScore,
            lastActivityTimestamp: block.timestamp
        });
        activeMemberAddresses.push(memberAddress); // Add to list
        totalQuantumSupply += initialScore;

        emit MemberAdded(memberAddress, initialScore);
    }

    // Simple remove for now, could be a proposal type later
    function removeMember(address memberAddress) external onlyOwner whenNotPaused {
        require(members[memberAddress].isActive, "Member not active");

        // Find and remove from activeMemberAddresses list (O(n), potentially expensive)
        // For production, consider a different data structure or only allowing removal via complex governance vote
        bool found = false;
        for (uint i = 0; i < activeMemberAddresses.length; i++) {
            if (activeMemberAddresses[i] == memberAddress) {
                activeMemberAddresses[i] = activeMemberAddresses[activeMemberAddresses.length - 1];
                activeMemberAddresses.pop();
                found = true;
                break;
            }
        }
        require(found, "Member not found in active list (internal error)");

        totalQuantumSupply -= members[memberAddress].quantumScore;
        members[memberAddress].isActive = false; // Mark as inactive
        members[memberAddress].quantumScore = 0; // Reset score

        emit MemberRemoved(memberAddress);
    }


    // --- Proposal & Voting Functions ---

    function submitProposal(string calldata description, address target, bytes calldata callData, uint256 value) external onlyMember whenNotPaused returns (uint256 proposalId) {
        // Check if target is approved for calls if callData is not empty or value is not zero
        if (callData.length > 0 || value > 0) {
             require(approvedCallTargets[target], "Target address not approved for execution");
        }

        proposalId = proposals.length;
        uint256 expiration = block.timestamp + votingPeriodDuration;

        proposals.push(Proposal({
            proposer: msg.sender,
            description: description,
            callData: callData,
            targetAddress: target,
            value: value,
            creationTimestamp: block.timestamp,
            expirationTimestamp: expiration,
            yesVotesPower: 0,
            noVotesPower: 0,
            executed: false,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize mapping
        }));

        // Boost proposer's reputation
        _boostReputation(msg.sender);

        emit ProposalSubmitted(proposalId, msg.sender, description, target, callData, value, expiration);
    }

    function voteOnProposal(uint256 proposalId, bool vote) external onlyMember whenNotPaused onlyActiveProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 voterScore = members[msg.sender].quantumScore;
        require(voterScore > 0, "Voter must have positive score"); // Should be true with onlyMember check, but good practice

        proposal.hasVoted[msg.sender] = true;

        if (vote) {
            proposal.yesVotesPower += voterScore;
        } else {
            proposal.noVotesPower += voterScore;
        }

        // Boost voter's reputation
        _boostReputation(msg.sender);

        emit Voted(proposalId, msg.sender, vote, voterScore);
    }

    // --- Execution Functions ---

    function executeProposal(uint256 proposalId) external whenNotPaused onlyEndedProposal(proposalId) returns (bool success, bytes memory result) {
         Proposal storage proposal = proposals[proposalId];

         // Check if the proposal has passed Quorum and Threshold
         (bool passedQuorum, bool passedThreshold) = _checkQuorumAndThreshold(proposalId);

         // Update proposal state based on outcome
         if (passedQuorum && passedThreshold) {
            proposal.state = ProposalState.Passed;

            // Execute the proposal if it involves a call
            if (proposal.targetAddress != address(0) || proposal.value > 0) {
                 require(approvedCallTargets[proposal.targetAddress], "Execution target not approved");
                 // Execute the call using low-level CALL
                 (success, result) = proposal.targetAddress.call{value: proposal.value}(proposal.callData);
                 proposal.executed = true;

                 emit ProposalExecuted(proposalId, success, result);
                 require(success, "Proposal execution failed"); // Revert if execution fails
            } else {
                 // Proposal passed but had no executable action (e.g., purely informational)
                 success = true;
                 result = ""; // No result for non-executable proposals
                 proposal.executed = true; // Still mark as executed/finalized
                 emit ProposalExecuted(proposalId, success, result);
            }

            // Record statistics for epoch adjustment AFTER outcome is determined and recorded
            epochTotalParticipatingVotingPower += (proposal.yesVotesPower + proposal.noVotesPower);
            epochVotesCompleted++;
            epochVotesPassed++;

         } else {
             proposal.state = ProposalState.Failed;
             success = false; // Execution failed because it didn't pass vote
             result = "";
             // Record statistics for epoch adjustment
             epochTotalParticipatingVotingPower += (proposal.yesVotesPower + proposal.noVotesPower);
             epochVotesCompleted++;
             // epochVotesPassed is NOT incremented
             emit ProposalExecuted(proposalId, false, ""); // Emit event for failed execution attempt
         }

         return (success, result);
    }

    // --- Epoch & Reputation Management ---

    // Anyone can trigger epoch end after the duration has passed
    function triggerEpochEnd() external whenNotPaused {
        require(block.timestamp >= lastEpochEndTime, "Epoch has not ended yet");

        // --- Process Reputation Decay ---
        // Note: This loop can become very gas-intensive with a large number of members.
        // For a production system, consider:
        // 1. Processing decay in batches.
        // 2. Requiring members to 'claim' or 'refresh' their score, applying decay only then (pull mechanism).
        // 3. Using a mechanism like ERC-4626 shares for a decay-like effect managed internally.
        // For this example, we use a direct loop for simplicity of demonstration.
        uint256 currentEpochEndTime = lastEpochEndTime; // Capture for comparison

        for (uint i = 0; i < activeMemberAddresses.length; i++) {
            address memberAddress = activeMemberAddresses[i];
            // Ensure member is still active in case they were removed during epoch
            if (members[memberAddress].isActive && members[memberAddress].lastActivityTimestamp < currentEpochEndTime) {
                 _decayReputation(memberAddress);
            }
        }

        // --- Adjust Dynamic Quorum ---
        // Capture total supply BEFORE decay for epoch stats
        epochTotalPotentialVotingPower = totalQuantumSupply; // This should ideally be supply *at the START* of the epoch

        _adjustQuorum();

        // --- Reset for next Epoch ---
        lastEpochEndTime = block.timestamp + epochDuration;
        epochTotalParticipatingVotingPower = 0;
        epochVotesCompleted = 0;
        epochVotesPassed = 0;

        emit EpochEnded(lastEpochEndTime, currentQuorumPercentage);
    }

    // Internal helper for reputation decay
    function _decayReputation(address memberAddress) internal {
        Member storage member = members[memberAddress];
        if (member.quantumScore > 1) { // Always keep a minimum score of 1 to remain an active member
             uint256 oldScore = member.quantumScore;
             // Calculate decay amount
             uint256 decayAmount = (member.quantumScore * reputationDecayRate) / 100;
             // Ensure score doesn't drop below 1
             uint256 newScore = member.quantumScore - decayAmount;
             if (newScore < 1) {
                 newScore = 1;
             }

             if (newScore != oldScore) {
                totalQuantumSupply -= (oldScore - newScore);
                member.quantumScore = newScore;
                emit ReputationDecayed(memberAddress, oldScore, newScore);
             }
        }
    }

     // Internal helper for reputation boost
    function _boostReputation(address memberAddress) internal {
        Member storage member = members[memberAddress];
        uint256 oldScore = member.quantumScore;
        uint256 newScore = member.quantumScore + reputationBoostAmount;
        // Note: No upper cap on score in this design. Could add one if needed.

        if (newScore != oldScore) {
            totalQuantumSupply += (newScore - oldScore);
            member.quantumScore = newScore;
            member.lastActivityTimestamp = block.timestamp;
            emit ReputationBoosted(memberAddress, oldScore, newScore);
        }
    }


    // Internal helper to adjust quorum based on last epoch's stats
    function _adjustQuorum() internal {
        uint256 oldQuorum = currentQuorumPercentage;
        uint256 newQuorum = currentQuorumPercentage;

        if (epochVotesCompleted > 0) {
            // Calculate participation rate (percentage of total supply that voted across all completed proposals)
            // Handle division by zero if totalQuantumSupply was 0 at epoch start
            uint256 participationRate = 0;
            if (epochTotalPotentialVotingPower > 0) {
                participationRate = (epochTotalParticipatingVotingPower * 100) / epochTotalPotentialVotingPower;
            }

            // Calculate success rate (percentage of completed votes that passed)
            uint256 successRate = (epochVotesPassed * 100) / epochVotesCompleted;

            // Adjustment Logic (Example):
            // If participation was low OR success rate was low -> Increase quorum (make it harder)
            // If participation was high AND success rate was high -> Decrease quorum (make it easier)

            // Define thresholds for 'low'/'high' - example values
            uint256 participationThreshold = 20; // e.g., >20% of total power participated
            uint256 successThreshold = 70;       // e.g., >70% of completed votes passed

            int256 adjustment = 0;
            if (participationRate < participationThreshold || successRate < successThreshold) {
                // System struggling with engagement or consensus -> increase quorum slightly
                adjustment = 2; // Increase by 2 percentage points
            } else if (participationRate >= participationThreshold && successRate >= successThreshold) {
                 // System is engaged and effective -> decrease quorum slightly
                 adjustment = -1; // Decrease by 1 percentage point
            }
            // No adjustment if stats are 'average' or mixed

            // Apply adjustment with bounds check
            int256 proposedQuorum = int256(currentQuorumPercentage) + adjustment;
            if (proposedQuorum < int256(minQuorumPercentage)) {
                newQuorum = minQuorumPercentage;
            } else if (proposedQuorum > int256(maxQuorumPercentage)) {
                newQuorum = maxQuorumPercentage;
            } else {
                 // Safely cast back to uint256 after bounds check
                 newQuorum = uint256(proposedQuorum);
            }

            // Prevent changing if proposed quorum is the same
            if (newQuorum != oldQuorum) {
                 currentQuorumPercentage = newQuorum;
                 emit QuorumAdjusted(oldQuorum, newQuorum, participationRate, successRate);
            }
        } else {
             // No votes completed in the epoch, perhaps slightly increase quorum to encourage activity?
             // Or keep it same? Let's slightly increase to encourage engagement.
             int256 proposedQuorum = int256(currentQuorumPercentage) + 1;
              if (proposedQuorum < int256(minQuorumPercentage)) {
                 newQuorum = minQuorumPercentage;
              } else if (proposedQuorum > int256(maxQuorumPercentage)) {
                 newQuorum = maxQuorumPercentage;
              } else {
                 newQuorum = uint256(proposedQuorum);
             }

            if (newQuorum != oldQuorum) {
                 currentQuorumPercentage = newQuorum;
                 emit QuorumAdjusted(oldQuorum, newQuorum, 0, 0); // Participation and success rates are 0
            }
        }
    }

    // Internal helper to check if a proposal meets Quorum and Threshold
    function _checkQuorumAndThreshold(uint256 proposalId) internal view returns (bool passedQuorum, bool passedThreshold) {
        Proposal storage proposal = proposals[proposalId];
        uint256 totalVotePower = proposal.yesVotesPower + proposal.noVotesPower;
        uint256 currentTotalSupply = totalQuantumSupply; // Use current supply for quorum calculation

        // 1. Check Quorum: Total participating power >= currentQuorumPercentage of total supply
        // Handle division by zero if total supply is 0
        passedQuorum = false;
        if (currentTotalSupply > 0) {
             passedQuorum = (totalVotePower * 100) / currentTotalSupply >= currentQuorumPercentage;
        }

        // 2. Check Threshold: Yes votes power >= passingThresholdPercentage of total participating power
        // Handle division by zero if no one voted
        passedThreshold = false;
        if (totalVotePower > 0) {
             passedThreshold = (proposal.yesVotesPower * 100) / totalVotePower >= passingThresholdPercentage;
        }

        return (passedQuorum, passedThreshold);
    }

    // --- Views ---

    function getMemberQuantumScore(address memberAddress) external view returns (uint256) {
        require(members[memberAddress].isActive, "Member not active");
        return members[memberAddress].quantumScore;
    }

    function getTotalQuantumSupply() public view returns (uint256) {
        // totalQuantumSupply is updated when scores change, this is a O(1) lookup
        return totalQuantumSupply;
    }

    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        // If state is Active but voting period ended, return Expired view state
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.expirationTimestamp) {
            return ProposalState.Expired;
        }
        return proposal.state;
    }

    function getCurrentQuorumPercentage() external view returns (uint256) {
        return currentQuorumPercentage;
    }

    function getEpochEndTime() external view returns (uint256) {
        return lastEpochEndTime;
    }

    function getMemberLastActivity(address memberAddress) external view returns (uint256) {
        require(members[memberAddress].isActive, "Member not active");
        return members[memberAddress].lastActivityTimestamp;
    }

    function getApprovedCallTargets() external view returns (address[] memory) {
        // Note: Retrieving all keys from a mapping is not possible directly.
        // This function would typically require storing targets in a list *in addition* to the mapping,
        // which adds complexity on add/remove, or iterating a limited set.
        // For demonstration, returning an empty array or needing an off-chain indexer is common.
        // Let's return a placeholder for now.
        // To make this work realistically, you'd add:
        // address[] private _approvedCallTargetList;
        // Update it in add/remove functions.
        // Then return _approvedCallTargetList here.
        // Example placeholder return:
        address[] memory targets = new address[](0); // Placeholder
        // For a real implementation, populate this list.
        return targets;
    }

    function getProposalDetails(uint256 proposalId) external view returns (
        address proposer,
        string memory description,
        address targetAddress,
        uint256 value,
        uint256 creationTimestamp,
        uint256 expirationTimestamp,
        bool executed,
        ProposalState state
    ) {
         require(proposalId < proposals.length, "Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         state = getProposalState(proposalId); // Use getter to get dynamic state

         return (
            proposal.proposer,
            proposal.description,
            proposal.targetAddress,
            proposal.value,
            proposal.creationTimestamp,
            proposal.expirationTimestamp,
            proposal.executed,
            state
         );
    }

    function getProposalVoteCounts(uint256 proposalId) external view returns (uint256 yesPower, uint256 noPower) {
        require(proposalId < proposals.length, "Invalid proposal ID");
        Proposal storage proposal = proposals[proposalId];
        return (proposal.yesVotesPower, proposal.noVotesPower);
    }

    function getMinInitialQuantumScore() external view returns (uint256) {
        return minInitialQuantumScore;
    }

    function getEpochStats() external view returns (uint256 totalPotentialVotingPower, uint256 totalParticipatingVotingPower, uint256 votesCompleted, uint256 votesPassed) {
         return (epochTotalPotentialVotingPower, epochTotalParticipatingVotingPower, epochVotesCompleted, epochVotesPassed);
    }

    // Helper view function to check passing conditions (useful off-chain before execution)
    function checkProposalPassingConditions(uint256 proposalId) external view returns (bool passedQuorum, bool passedThreshold) {
         require(proposalId < proposals.length, "Invalid proposal ID");
         // Check if voting has ended first (optional, but makes sense for checking final state)
         require(block.timestamp > proposals[proposalId].expirationTimestamp, "Voting period not ended yet");
         return _checkQuorumAndThreshold(proposalId);
    }

    // A view to check if a member is currently active
    function isMemberActive(address memberAddress) external view returns (bool) {
        return members[memberAddress].isActive;
    }

    // How many proposals exist
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    // Get number of active members (size of the list)
    function getActiveMemberCount() external view returns (uint256) {
        return activeMemberAddresses.length;
    }
}
```