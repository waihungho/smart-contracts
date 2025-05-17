Okay, here is a Solidity smart contract for a "Decentralized Autonomous Investment Consortium" (DAIC).

This contract aims to combine several interesting concepts:
1.  **Stake-based Membership:** Users stake a specific ERC-20 token (the Membership Token) to join and participate.
2.  **Liquid Democracy Governance:** Voting power is weighted by stake. Members can delegate their voting power to others.
3.  **Basic Reputation System:** Tracks successful proposal initiations to potentially influence future roles or rewards (simple implementation: increment a counter).
4.  **Pooled Investment:** Members deposit other assets (like ETH, stablecoins) into a pool managed by the DAO.
5.  **Whitelisted External Calls:** Investment decisions are executed via governance-approved proposals that can make calls to *whitelisted* external contracts. This provides flexibility for DeFi interactions while maintaining some control against arbitrary malicious calls.
6.  **Profit Distribution:** A mechanism to distribute accrued profits from investments proportionally based on stake.

It avoids simple duplicates like basic ERC20/ERC721, standard multi-sigs, or generic "fund me" contracts. It incorporates elements of DAOs, DeFi interaction patterns, and custom tokenomics/governance.

---

### **Smart Contract Outline and Function Summary**

**Contract Name:** DecentralizedAutonomousInvestmentConsortium (DAIC)

**Purpose:** A decentralized autonomous organization where members pool funds and collectively decide on investments via stake-weighted liquid democracy, interacting with whitelisted external DeFi protocols.

**Key Components:**
*   **Membership Token:** A specific ERC-20 token required to be staked for membership and voting power.
*   **Investment Pool:** Holds various assets contributed by members for investment.
*   **Proposals:** Mechanisms for members to suggest actions (primarily external contract interactions).
*   **Voting:** Stake-weighted liquid democracy to approve proposals.
*   **Executor Role:** A designated address (controlled by governance) responsible for executing approved proposals.
*   **Whitelisting:** Governance process to approve external contract addresses for potential interactions.
*   **Basic Reputation:** Tracks successful proposal initiations.

**Function Summary:**

1.  `constructor`: Initializes the contract with the membership token address and initial parameters.
2.  `joinConsortium(uint256 amount)`: Stakes membership tokens to become a member. Requires minimum stake.
3.  `leaveConsortium()`: Unstakes membership tokens and removes membership after a timelock.
4.  `depositInvestmentFunds(address tokenAddress, uint256 amount)`: Deposits specified ERC-20 tokens into the investment pool.
5.  `depositEthInvestmentFunds() payable`: Deposits ETH into the investment pool.
6.  `withdrawInvestmentFunds(address tokenAddress, uint256 amount)`: Members can withdraw their *initial deposit contribution* (more complex profit/loss sharing would require a different model, keeping this simple). Note: Real-world DAOs need complex accounting here. This version assumes a simple return of principal.
7.  `createInvestmentProposal(address target, bytes calldata callData, string memory description)`: Creates a proposal to call a specific function on a target contract with given data. `target` must be whitelisted.
8.  `voteOnProposal(uint256 proposalId, uint8 voteType)`: Members cast a stake-weighted vote (Yes, No, Abstain) on a proposal. Supports delegation.
9.  `delegateVote(address delegatee)`: Delegates voting power to another member.
10. `revokeDelegate()`: Revokes existing vote delegation.
11. `executeProposal(uint256 proposalId)`: The Executor address executes an approved proposal after the voting period ends and a timelock (if any).
12. `distributeProfits(address profitToken, uint256 amount)`: Allows a designated role (e.g., Executor, or via governance) to signal and make available a specific amount of a token as profit for distribution.
13. `claimProfits(address profitToken)`: Members claim their proportional share of the available profits of a specific token.
14. `whitelistTargetContract(address target)`: Governance proposal function to add an address to the list of callable contracts.
15. `blacklistTargetContract(address target)`: Governance proposal function to remove an address from the whitelist.
16. `setVotingPeriod(uint40 newVotingPeriodSeconds)`: Governance proposal function to set the duration of voting periods.
17. `setMinStake(uint256 newMinStake)`: Governance proposal function to set the minimum tokens required to join.
18. `setProposalThresholds(uint256 newQuorumNumerator, uint256 newApprovalNumerator)`: Governance proposal function to set the quorum and approval thresholds for proposals.
19. `setExecutorAddress(address newExecutor)`: Governance proposal function to set the address of the executor role.
20. `emergencyShutdown()`: Allows governance (or a specific high-threshold vote) to pause all critical operations in an emergency.
21. `recoverERC20(address tokenAddress, uint256 amount)`: Allows governance to recover ERC-20 tokens accidentally sent to the contract (excluding the membership token and pool assets).
22. `getMemberStake(address member)`: View function to get the current stake of a member.
23. `getTotalStake()`: View function to get the total staked membership tokens.
24. `getPoolAssetBalance(address tokenAddress)`: View function to get the balance of a specific asset in the investment pool.
25. `getProposalState(uint256 proposalId)`: View function to get the current state of a proposal.
26. `getMemberVote(uint256 proposalId, address member)`: View function to get how a member voted on a proposal.
27. `getMemberReputation(address member)`: View function to get a member's reputation score.
28. `getMemberProfitShare(address profitToken, address member)`: View function to calculate a member's claimable profit share for a specific token.
29. `getMemberDelegate(address member)`: View function to see who a member has delegated their vote to.
30. `isWhitelisted(address target)`: View function to check if an address is whitelisted for calls.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// --- Outline and Function Summary (See above block for detailed summary) ---
// Contract: DecentralizedAutonomousInvestmentConsortium (DAIC)
// Purpose: Stake-based DAO for collective investment in whitelisted DeFi protocols.
// Concepts: Stake-based Membership, Liquid Democracy Governance, Basic Reputation, Pooled Investment, Whitelisted External Calls, Profit Distribution.
// Functions:
// 1. constructor: Initialize contract with membership token, params.
// 2. joinConsortium: Stake tokens to become member.
// 3. leaveConsortium: Unstake and leave (with timelock).
// 4. depositInvestmentFunds: Deposit ERC20 into pool.
// 5. depositEthInvestmentFunds: Deposit ETH into pool.
// 6. withdrawInvestmentFunds: Member withdraws principal deposit (simplified).
// 7. createInvestmentProposal: Propose external call to whitelisted target.
// 8. voteOnProposal: Stake-weighted vote (Yes/No/Abstain).
// 9. delegateVote: Delegate voting power.
// 10. revokeDelegate: Revoke delegation.
// 11. executeProposal: Executor executes approved proposal.
// 12. distributeProfits: Signal and make profits available.
// 13. claimProfits: Member claims proportional profit share.
// 14. whitelistTargetContract: Governance: Add target to whitelist.
// 15. blacklistTargetContract: Governance: Remove target from whitelist.
// 16. setVotingPeriod: Governance: Set proposal voting period.
// 17. setMinStake: Governance: Set min stake for membership.
// 18. setProposalThresholds: Governance: Set quorum/approval thresholds.
// 19. setExecutorAddress: Governance: Set executor address.
// 20. emergencyShutdown: Governance/high quorum: Pause operations.
// 21. recoverERC20: Governance: Recover misplaced tokens.
// 22. getMemberStake: View: Member's current stake.
// 23. getTotalStake: View: Total staked tokens.
// 24. getPoolAssetBalance: View: Balance of asset in pool.
// 25. getProposalState: View: State of a proposal.
// 26. getMemberVote: View: How a member voted.
// 27. getMemberReputation: View: Member's reputation score.
// 28. getMemberProfitShare: View: Member's claimable profits.
// 29. getMemberDelegate: View: Member's delegatee.
// 30. isWhitelisted: View: Check if target is whitelisted.
// --------------------------------------------------------------

contract DecentralizedAutonomousInvestmentConsortium is ReentrancyGuard {
    using Address for address;

    IERC20 public immutable membershipToken;

    // --- State Variables ---

    // Membership and Staking
    mapping(address => uint256) public memberStake;
    mapping(address => bool) public isMember;
    uint256 public totalStaked;
    uint256 public minStake; // Minimum stake required to join/maintain membership
    uint64 public constant LEAVE_TIMELOCK_SECONDS = 7 days; // Timelock before unstaking on leaving
    mapping(address => uint64) public leaveTimelockEnd;

    // Investment Pool
    mapping(address => uint256) public poolAssets; // ERC20 token addresses -> balances
    mapping(address => uint256) public memberPrincipalDeposit; // Member -> their initial deposit amount (Simplified - real accounting is complex)

    // Governance and Proposals
    enum ProposalState { Pending, Active, Passed, Failed, Executed, Defeated }
    uint256 public nextProposalId;

    struct Proposal {
        address proposer;
        address target; // The contract address to interact with
        bytes callData; // The data payload for the interaction (function selector + args)
        string description;
        uint40 startBlock;
        uint40 endBlock;
        uint256 votesYes;
        uint256 votesNo;
        uint256 votesAbstain;
        bool executed;
        ProposalState state; // Current state derived from block/votes
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => uint8)) public proposalVotes; // proposalId -> voter -> voteType (0=No, 1=Yes, 2=Abstain)
    mapping(address => address) public delegates; // voter -> delegatee
    mapping(address => uint256) public votingPower; // delegatee -> total delegated stake

    uint40 public votingPeriodBlocks; // How many blocks voting is open for
    uint256 public quorumNumerator; // Numerator for quorum calculation (denominator is totalStaked)
    uint256 public approvalNumerator; // Numerator for approval calculation (denominator is total votes cast)

    address public executorAddress; // Address authorized to execute passed proposals

    // Whitelisted Contracts for Interaction
    mapping(address => bool) public whitelistedTargets;

    // Basic Reputation (Incremented for successful proposers)
    mapping(address => uint256) public memberReputation;

    // Profit Distribution (Simplified)
    mapping(address => mapping(address => uint256)) public availableProfits; // profitToken -> member -> claimable amount
    mapping(address => uint256) public totalAvailableProfits; // profitToken -> total available for this token

    // Emergency State
    bool public paused;

    // --- Events ---

    event MemberJoined(address indexed member, uint256 stake);
    event MemberLeft(address indexed member, uint256 unstakedAmount);
    event LeaveTimelockSet(address indexed member, uint64 timelockEnd);
    event FundsDeposited(address indexed member, address indexed token, uint256 amount);
    event FundsWithdrawalRequested(address indexed member, address indexed token, uint256 amount); // Withdrawal initiation
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address indexed target, bytes callData, string description, uint40 startBlock, uint44 endBlock); // Using uint44 for endBlock for safety
    event Voted(uint256 indexed proposalId, address indexed voter, uint8 voteType, uint256 stakeWeight);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegatee, uint256 oldVotes, uint256 newVotes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success, bytes result);
    event TargetWhitelisted(address indexed target);
    event TargetBlacklisted(address indexed target);
    event ParametersSet(string paramName, uint256 value); // Generic event for parameter changes
    event ExecutorAddressSet(address indexed oldExecutor, address indexed newExecutor);
    event ProfitsDistributed(address indexed profitToken, uint256 amount);
    event ProfitsClaimed(address indexed member, address indexed profitToken, uint256 amount);
    event EmergencyShutdown();
    event RecoveredERC20(address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyMember() {
        require(isMember[msg.sender], "DAIC: Not a member");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executorAddress, "DAIC: Only executor");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAIC: Paused");
        _;
    }

    // --- Constructor ---

    constructor(address _membershipToken, uint256 _minStake, uint40 _votingPeriodBlocks, uint256 _quorumNumerator, uint256 _approvalNumerator, address _initialExecutor) {
        require(_membershipToken != address(0), "DAIC: Invalid membership token address");
        membershipToken = IERC20(_membershipToken);
        minStake = _minStake;
        votingPeriodBlocks = _votingPeriodBlocks;
        quorumNumerator = _quorumNumerator;
        approvalNumerator = _approvalNumerator;
        executorAddress = _initialExecutor; // Can be set to address(0) initially and set later via governance
        paused = false;
        nextProposalId = 1;

        // Initial whitelist (optional: can be added later via governance)
        // whitelistedTargets[address(0x1)] = true; // Example
    }

    // --- Membership Functions ---

    /**
     * @notice Stakes membership tokens to join the consortium.
     * @param amount The amount of membership tokens to stake.
     */
    function joinConsortium(uint256 amount) public nonReentrant whenNotPaused {
        require(amount >= minStake, "DAIC: Stake less than minimum");
        require(memberStake[msg.sender] == 0, "DAIC: Already a member"); // Prevent joining multiple times

        // Transfer tokens from sender to contract
        require(membershipToken.transferFrom(msg.sender, address(this), amount), "DAIC: Token transfer failed");

        memberStake[msg.sender] = amount;
        isMember[msg.sender] = true;
        totalStaked += amount;

        // Initial voting power is self-delegated
        _updateDelegate(msg.sender, address(0), msg.sender);

        emit MemberJoined(msg.sender, amount);
    }

    /**
     * @notice Initiates the process to leave the consortium and unstake tokens.
     * Requires a timelock period before tokens can be withdrawn.
     */
    function leaveConsortium() public onlyMember nonReentrant whenNotPaused {
        require(leaveTimelockEnd[msg.sender] == 0, "DAIC: Leave process already initiated");

        isMember[msg.sender] = false; // Immediately revoke membership rights (voting, proposal creation)

        // Timelock starts now
        leaveTimelockEnd[msg.sender] = uint64(block.timestamp + LEAVE_TIMELOCK_SECONDS);

        // Remove voting power by revoking delegation
        address currentDelegatee = delegates[msg.sender];
         if (currentDelegatee != address(0)) { // Should always be true for active members initially
             _updateDelegate(msg.sender, currentDelegatee, address(0));
         } else {
             // This case should not happen for an active member, but handle defensively
             // If somehow not self-delegated, ensure their stake is removed from votingPower
             if (delegates[msg.sender] == msg.sender) {
                 votingPower[msg.sender] -= memberStake[msg.sender];
             }
         }
        delegates[msg.sender] = address(0); // Clear delegation

        emit LeaveTimelockSet(msg.sender, leaveTimelockEnd[msg.sender]);
    }

    /**
     * @notice Completes the leaving process and unstakes tokens after the timelock.
     * Can only be called after `leaveConsortium` and the timelock has passed.
     */
    function completeLeave() public nonReentrant whenNotPaused {
        require(!isMember[msg.sender], "DAIC: Still an active member"); // Must have called leaveConsortium first
        require(memberStake[msg.sender] > 0, "DAIC: No stake to unstake");
        require(block.timestamp >= leaveTimelockEnd[msg.sender], "DAIC: Timelock not passed yet");

        uint256 amountToUnstake = memberStake[msg.sender];
        memberStake[msg.sender] = 0;
        totalStaked -= amountToUnstake;
        leaveTimelockEnd[msg.sender] = 0; // Reset timelock

        // Transfer tokens back to sender
        require(membershipToken.transfer(msg.sender, amountToUnstake), "DAIC: Unstake token transfer failed");

        emit MemberLeft(msg.sender, amountToUnstake);
    }

    // --- Investment Pool Functions ---

    /**
     * @notice Deposits ERC20 tokens into the investment pool.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount to deposit.
     */
    function depositInvestmentFunds(address tokenAddress, uint256 amount) public nonReentrant whenNotPaused {
        require(tokenAddress != address(membershipToken), "DAIC: Cannot deposit membership token");
        require(tokenAddress != address(0), "DAIC: Invalid token address");
        require(amount > 0, "DAIC: Deposit amount must be greater than 0");

        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "DAIC: Token transfer failed");

        poolAssets[tokenAddress] += amount;
        // Simple tracking of member principal deposit for simplified withdrawal
        memberPrincipalDeposit[msg.sender] += amount;

        emit FundsDeposited(msg.sender, tokenAddress, amount);
    }

     /**
     * @notice Deposits native ETH into the investment pool.
     */
    function depositEthInvestmentFunds() public payable nonReentrant whenNotPaused {
        require(msg.value > 0, "DAIC: Deposit amount must be greater than 0");

        poolAssets[address(0)] += msg.value; // Use address(0) for ETH
        // Simple tracking of member principal deposit for simplified withdrawal
        memberPrincipalDeposit[msg.sender] += msg.value; // This is not perfectly accurate if member deposits multiple times, but serves basic example

        emit FundsDeposited(msg.sender, address(0), msg.value);
    }


    /**
     * @notice Allows a member to withdraw their *initial principal deposit* of a specific token.
     * This is a simplified model and does not account for profits or losses from investments.
     * A real system needs complex accounting.
     * @param tokenAddress The address of the token to withdraw (address(0) for ETH).
     * @param amount The amount to withdraw. Cannot exceed their recorded principal deposit.
     */
    function withdrawInvestmentFunds(address tokenAddress, uint256 amount) public nonReentrant whenNotPaused {
        require(amount > 0, "DAIC: Withdraw amount must be greater than 0");
        // Check if they have enough recorded principal deposit
        require(memberPrincipalDeposit[msg.sender] >= amount, "DAIC: Amount exceeds principal deposit");
        // Check if the contract actually holds enough of the asset (it might not if investments failed)
        require(poolAssets[tokenAddress] >= amount, "DAIC: Not enough asset in pool");

        poolAssets[tokenAddress] -= amount;
        memberPrincipalDeposit[msg.sender] -= amount; // Decrease principal tracking

        if (tokenAddress == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: amount}("");
            require(success, "DAIC: ETH withdrawal failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(msg.sender, amount), "DAIC: ERC20 withdrawal failed");
        }

        emit FundsWithdrawalRequested(msg.sender, tokenAddress, amount);
    }


    // --- Governance and Proposal Functions ---

    /**
     * @notice Creates a new investment proposal.
     * @param target The address of the contract to call. Must be whitelisted.
     * @param callData The calldata for the external function call.
     * @param description A brief description of the proposal.
     * @return The ID of the newly created proposal.
     */
    function createInvestmentProposal(address target, bytes calldata callData, string memory description) public onlyMember whenNotPaused returns (uint256) {
        require(whitelistedTargets[target], "DAIC: Target contract not whitelisted");
        require(bytes(description).length > 0, "DAIC: Description cannot be empty");

        uint256 proposalId = nextProposalId;
        nextProposalId++;

        Proposal storage proposal = proposals[proposalId];
        proposal.proposer = msg.sender;
        proposal.target = target;
        proposal.callData = callData;
        proposal.description = description;
        proposal.startBlock = uint40(block.number);
        proposal.endBlock = proposal.startBlock + votingPeriodBlocks; // Using uint44 for endBlock event for safety in case of very large block numbers, but calculations use uint40
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, target, callData, description, proposal.startBlock, uint44(proposal.endBlock));

        return proposalId;
    }

    /**
     * @notice Casts a stake-weighted vote on a proposal.
     * Voting power is based on current stake or delegated stake at the time of voting.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteType The type of vote (0=No, 1=Yes, 2=Abstain).
     */
    function voteOnProposal(uint256 proposalId, uint8 voteType) public onlyMember whenNotPaused {
        require(voteType <= 2, "DAIC: Invalid vote type"); // 0: Against, 1: For, 2: Abstain

        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "DAIC: Proposal not active");
        require(block.number <= proposal.endBlock, "DAIC: Voting period ended");
        require(proposalVotes[proposalId][msg.sender] == 0, "DAIC: Already voted on this proposal"); // Check if voter already cast any vote

        uint256 weight = _getVotingWeight(msg.sender);
        require(weight > 0, "DAIC: Voter has no voting power");

        proposalVotes[proposalId][msg.sender] = voteType + 1; // Store 1, 2, or 3 to distinguish from 0 (no vote)

        if (voteType == 0) { // No
            proposal.votesNo += weight;
        } else if (voteType == 1) { // Yes
            proposal.votesYes += weight;
        } else { // Abstain
            proposal.votesAbstain += weight;
        }

        emit Voted(proposalId, msg.sender, voteType, weight);

        // Optional: Check and update state immediately if end block reached (less gas efficient per vote)
        // Or rely on executeProposal or a separate state update function to check endBlock
    }

     /**
     * @notice Delegates voting power to another member.
     * @param delegatee The address of the member to delegate to. address(0) to self-delegate (or revoke).
     */
    function delegateVote(address delegatee) public onlyMember whenNotPaused {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != delegatee, "DAIC: Cannot delegate to current delegatee");
        require(isMember[delegatee] || delegatee == address(0), "DAIC: Delegatee must be a member or address(0)");

        _updateDelegate(msg.sender, currentDelegatee, delegatee);
        emit DelegateChanged(msg.sender, currentDelegatee, delegatee);
    }

     /**
     * @notice Revokes existing vote delegation.
     * Effectively self-delegates voting power.
     */
    function revokeDelegate() public onlyMember whenNotPaused {
        address currentDelegatee = delegates[msg.sender];
        require(currentDelegatee != msg.sender, "DAIC: Delegation already revoked (self-delegated)");

        _updateDelegate(msg.sender, currentDelegatee, msg.sender);
        emit DelegateChanged(msg.sender, currentDelegatee, msg.sender);
    }

    /**
     * @dev Internal function to update delegatee and voting power.
     * @param delegator The member delegating.
     * @param oldDelegatee The previous delegatee.
     * @param newDelegatee The new delegatee.
     */
    function _updateDelegate(address delegator, address oldDelegatee, address newDelegatee) internal {
        uint256 stake = memberStake[delegator];

        if (oldDelegatee != address(0)) {
            uint256 oldVotes = votingPower[oldDelegatee];
            votingPower[oldDelegatee] -= stake;
            emit DelegateVotesChanged(oldDelegatee, oldVotes, votingPower[oldDelegatee]);
        }

        delegates[delegator] = newDelegatee;

        if (newDelegatee != address(0)) {
            uint256 oldVotes = votingPower[newDelegatee];
            votingPower[newDelegatee] += stake;
            emit DelegateVotesChanged(newDelegatee, oldVotes, votingPower[newDelegatee]);
        }
    }

    /**
     * @dev Internal function to get a member's effective voting weight.
     * @param voter The address of the member.
     * @return The voting weight.
     */
    function _getVotingWeight(address voter) internal view returns (uint256) {
        address delegatee = delegates[voter];
        if (delegatee == address(0)) {
            return 0; // No delegation set, effectively 0 voting power if not self-delegated
        }
        if (delegatee == voter) {
             // Self-delegated, use their own stake, but only if they are an active member
            return isMember[voter] ? memberStake[voter] : 0;
        } else {
            // Delegated to someone else, use the delegated power
             return isMember[voter] ? votingPower[delegatee] : 0; // Voting power follows the delegatee, but only if delegator is still a member
        }
         // Note: A more robust system might snapshot stake/delegation at proposal creation or voting start.
         // This implementation uses current effective power.
    }

    /**
     * @notice Calculates the outcome of a proposal based on current state and votes.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal (Pending, Active, Passed, Failed, Executed, Defeated).
     */
    function calculateProposalOutcome(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.startBlock == 0) return ProposalState.Pending; // Proposal doesn't exist

        if (proposal.executed) return ProposalState.Executed;

        uint40 currentBlock = uint40(block.number);

        // Determine active state based on block number
        if (currentBlock < proposal.startBlock) return ProposalState.Pending;
        if (currentBlock <= proposal.endBlock) return ProposalState.Active;

        // Voting period has ended. Determine outcome.
        if (proposal.state == ProposalState.Active) { // Only update state if it was Active
            uint256 totalVotesCast = proposal.votesYes + proposal.votesNo + proposal.votesAbstain;

            // Check quorum
            // Avoid division by zero if totalStaked is 0
            uint256 currentTotalStaked = totalStaked; // Snapshot total staked for this check
            uint256 quorumRequired = (currentTotalStaked > 0) ? (currentTotalStaked * quorumNumerator) / 100 : 0; // Assuming quorumNumerator is percentage * 100

            if (totalVotesCast < quorumRequired) {
                return ProposalState.Defeated; // Did not meet quorum
            }

            // Check approval threshold (using total votes cast for denominator)
            // Avoid division by zero if totalVotesCast is 0
             uint256 approvalThreshold = (totalVotesCast > 0) ? (proposal.votesYes * 100) / totalVotesCast : 0;

            if (approvalThreshold >= approvalNumerator) { // Assuming approvalNumerator is percentage
                return ProposalState.Passed;
            } else {
                return ProposalState.Failed; // Did not meet approval threshold
            }
        }

        // If state was already determined (Passed, Failed, Defeated) and not executed
        return proposal.state;
    }


    /**
     * @notice Executes a passed proposal. Can only be called by the Executor address.
     * Includes a small execution delay/timelock after voting ends.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public onlyExecutor nonReentrant whenNotPaused {
         Proposal storage proposal = proposals[proposalId];
         require(!proposal.executed, "DAIC: Proposal already executed");

         ProposalState currentState = calculateProposalOutcome(proposalId);

         require(currentState == ProposalState.Passed, "DAIC: Proposal not passed");
         require(block.number > proposal.endBlock, "DAIC: Voting period not ended yet");
         // Add a short timelock after voting ends before execution is possible
         require(block.timestamp > uint64(proposal.endBlock * 12) + 600, "DAIC: Execution timelock not passed"); // Example: block time ~12s, 600s = 10 mins timelock

         proposal.executed = true;
         proposal.state = ProposalState.Executed;
         emit ProposalStateChanged(proposalId, ProposalState.Executed);

         // Increment reputation for the proposer if the proposal is successfully executed
         memberReputation[proposal.proposer]++;

         // Execute the external call
         (bool success, bytes memory result) = proposal.target.call(proposal.callData);

         // Note: In a real system, you might want to verify the success of the external call,
         // but `call` itself returns success/failure. Reverting here if the call fails is standard.
         require(success, "DAIC: External call execution failed");

         emit ProposalExecuted(proposalId, success, result);
    }


    // --- System Configuration (via Governance Proposals) ---

    /**
     * @notice Proposes to whitelist a target contract address for external calls.
     * This function should ideally be called via a proposal mechanism itself,
     * but included here as a direct function for governance execution.
     * @param target The address to whitelist.
     */
    function whitelistTargetContract(address target) public onlyExecutor whenNotPaused {
        require(target != address(0), "DAIC: Invalid target address");
        require(!whitelistedTargets[target], "DAIC: Target already whitelisted");
        whitelistedTargets[target] = true;
        emit TargetWhitelisted(target);
    }

     /**
     * @notice Proposes to blacklist a target contract address, removing it from the whitelist.
     * This function should ideally be called via a proposal mechanism itself.
     * @param target The address to blacklist.
     */
    function blacklistTargetContract(address target) public onlyExecutor whenNotPaused {
        require(whitelistedTargets[target], "DAIC: Target not whitelisted");
        whitelistedTargets[target] = false;
        emit TargetBlacklisted(target);
    }

    /**
     * @notice Proposes to set the voting period in blocks.
     * This function should be called via a proposal mechanism.
     * @param newVotingPeriodBlocks The new voting period in blocks.
     */
    function setVotingPeriod(uint40 newVotingPeriodBlocks) public onlyExecutor whenNotPaused {
        require(newVotingPeriodBlocks > 0, "DAIC: Voting period must be positive");
        votingPeriodBlocks = newVotingPeriodBlocks;
        emit ParametersSet("votingPeriodBlocks", newVotingPeriodBlocks);
    }

    /**
     * @notice Proposes to set the minimum stake required for membership.
     * This function should be called via a proposal mechanism.
     * @param newMinStake The new minimum stake amount.
     */
    function setMinStake(uint256 newMinStake) public onlyExecutor whenNotPaused {
        minStake = newMinStake; // Note: This does not affect existing members below the new minimum
        emit ParametersSet("minStake", newMinStake);
    }

    /**
     * @notice Proposes to set the quorum and approval numerator percentages (out of 100).
     * This function should be called via a proposal mechanism.
     * @param newQuorumNumerator The new numerator for quorum percentage (e.g., 40 for 40%).
     * @param newApprovalNumerator The new numerator for approval percentage of votes cast (e.g., 51 for 51%).
     */
    function setProposalThresholds(uint256 newQuorumNumerator, uint256 newApprovalNumerator) public onlyExecutor whenNotPaused {
        require(newQuorumNumerator <= 100 && newApprovalNumerator <= 100, "DAIC: Numerators must be <= 100");
        quorumNumerator = newQuorumNumerator;
        approvalNumerator = newApprovalNumerator;
        emit ParametersSet("quorumNumerator", newQuorumNumerator);
        emit ParametersSet("approvalNumerator", newApprovalNumerator);
    }

     /**
     * @notice Proposes to set the address of the executor role.
     * This function should be called via a proposal mechanism.
     * @param newExecutor The address to set as the new executor.
     */
    function setExecutorAddress(address newExecutor) public onlyExecutor whenNotPaused {
        address oldExecutor = executorAddress;
        executorAddress = newExecutor;
        emit ExecutorAddressSet(oldExecutor, newExecutor);
    }


    // --- Profit Distribution (Simplified Model) ---

    /**
     * @notice Allows a trusted role (like the Executor, or via a successful proposal)
     * to signal that a certain amount of a token is available as profit
     * for distribution among current stakers.
     * The actual tokens must be transferred to the contract *before* or *by* calling this function.
     * @param profitToken The address of the token to distribute (address(0) for ETH).
     * @param amount The amount of profit token available for distribution.
     */
    function distributeProfits(address profitToken, uint256 amount) public onlyExecutor nonReentrant whenNotPaused {
        require(amount > 0, "DAIC: Amount must be greater than 0");
        // Basic check: Ensure contract holds at least this much (tokens might have been sent externally)
        require(poolAssets[profitToken] >= amount, "DAIC: Contract does not hold enough profit token");

        // Make the total amount available for claiming
        totalAvailableProfits[profitToken] += amount;

        // Note: This simple model distributes based on *current* stake weight *at the time of claiming*.
        // More complex models would track stake over time or at the moment of profit generation.

        emit ProfitsDistributed(profitToken, amount);
    }

    /**
     * @notice Allows a member to claim their proportional share of available profits for a specific token.
     * The proportion is based on their *current* stake relative to the *total current* staked tokens.
     * This is a simplified 'pull' mechanism.
     * @param profitToken The address of the token to claim profits for (address(0) for ETH).
     */
    function claimProfits(address profitToken) public onlyMember nonReentrant whenNotPaused {
         uint256 memberStakeAmount = memberStake[msg.sender];
         require(memberStakeAmount > 0, "DAIC: No stake to claim profits based on");

         uint256 currentTotalStake = totalStaked;
         require(currentTotalStake > 0, "DAIC: No total stake to calculate share");
         require(totalAvailableProfits[profitToken] > 0, "DAIC: No profits available for this token");

         // Calculate proportional share of the *total* available profits for this token
         // Using integer division. Can be improved with scaled arithmetic for precision if needed.
         uint256 share = (totalAvailableProfits[profitToken] * memberStakeAmount) / currentTotalStake;

         // Only allow claiming if a non-zero share is calculated and not already claimed
         // The amount available for claiming per member is tracked in availableProfits mapping.
         // We need to adjust this based on what they *can* claim now vs what they've already claimed.

         // Let's refine: Instead of tracking total available and calculating share on claim,
         // a better pull model pre-calculates or tracks per-member.
         // Simpler V2: Distribute function should *calculate* and *update* per-member mapping directly.

         // Let's adjust `distributeProfits` logic in thinking...
         // When `distributeProfits` is called with `amount`, that `amount` is added to
         // `totalAvailableProfits[profitToken]`.
         // A member's claimable amount *at any point* is (their_stake / total_stake_at_claim_time) * total_available_profits.
         // We need to prevent claiming the *same* share multiple times from the *same* pool of available profits.
         // This requires tracking what each member *has claimed* from the `totalAvailableProfits`.

         // Let's stick to the V1 simple model where `distributeProfits` just increases the pot,
         // and `claimProfits` calculates a share of the *current total pot* based on *current stake*.
         // This is potentially unfair if stakes change drastically, but simple.

         // A more robust pull model:
         // 1. `distributeProfits` adds `amount` to `totalAvailableProfits[profitToken]`.
         // 2. It also records the `totalStaked` at that moment.
         // 3. When `claimProfits` is called, calculate the amount earned *since the last claim*:
         //    (Current Member Stake / Total Stake at last Profit Distribution) * New Profits Distributed - Already Claimed

         // This is getting complex. Let's simplify back to the initial model but track total claimed per member per token.
         // `availableProfits[profitToken][member]` = amount they CAN claim.
         // `distributeProfits` needs to iterate or use a weighted distribution mechanism which is gas-prohibitive for many members.

         // Let's try a different simplified model: `distributeProfits` adds the amount to `totalAvailableProfits`.
         // `claimProfits` calculates their share of the *total* available, subtracts what they've *already claimed* for this token, and transfers the difference.

         uint256 totalAvailable = totalAvailableProfits[profitToken];
         if (totalAvailable == 0) {
             // This check is redundant due to earlier require, but good for logic flow clarity.
             revert("DAIC: No profits available for this token");
         }

         // Calculate theoretical total profits earned by this member based on current stake vs total available
         // This is still flawed as it ignores stake changes *between* distributions.
         // Correct model needs checkpoints or per-share tracking like Uniswap V2 LPs or complex accumulator patterns.

         // Let's just implement the simplest proportional pull from the CURRENT pot:
         // Amount member can claim = (Their Current Stake / Total Current Stake) * Total Available Profits
         // This is only fair if stakes are static between distributions.

         // RETHINK: The `availableProfits[token][member]` mapping should track how much each member is *eligible* to claim from the *total* distributed profits.
         // When `distributeProfits(token, amount)` is called:
         // Calculate share per unit of stake: `sharePerUnit = amount / totalStaked`.
         // For each member M with stake S: `availableProfits[token][M] += S * sharePerUnit`.
         // This requires iterating or using a complex accumulator pattern (like Compound's Comptroller or Yearn's strategies). Iteration is gas expensive.

         // OK, let's use a *slightly* less simple pull model.
         // `distributeProfits` adds to `totalAvailableProfits`.
         // `claimProfits` calculates the *current total share* they are eligible for based on their current stake and the *total* distributed, then subtracts what they *already claimed*.

         uint256 currentTotalStake = totalStaked;
         if (currentTotalStake == 0) {
             // If total staked is 0, no one can claim based on stake.
             revert("DAIC: Total stake is 0, cannot calculate profit share");
         }

         // Calculate the *potential* total amount the member is eligible for based on all profits distributed so far
         // and their *current* stake's proportion of the *current* total stake.
         // This is still not perfect, but better than a simple proportional slice of the *current* pot.
         // A fully correct model would use a cumulative share per unit of stake, like in Compound/Aave.
         // Let's use a simpler accumulator-like idea: Keep track of total profit-units distributed per unit of stake.
         // TotalProfitUnits = sum(amount / totalStaked_at_distribution) for all distributions.
         // MemberClaimable = (Member Stake at Claim) * TotalProfitUnits - MemberClaimedAmount.

         // Let's use a Cumulative Profit Per Stake Unit (CPPSU) model.
         // Add `cumulativeProfitPerStakeUnit[token]`.
         // When `distributeProfits(token, amount)`:
         // `cumulativeProfitPerStakeUnit[token] += (amount * 1e18) / totalStaked;` (scale by 1e18 for fixed point)
         // Member state: `memberLastClaimedProfitUnits[token][member]`
         // Member claimable: `(memberStake[member] * cumulativeProfitPerStakeUnit[token]) / 1e18 - memberLastClaimedProfitUnits[token][member]`

         // This is advanced but necessary for fairness. Let's add these state variables.

         // Reworking state for CPPSU:
         mapping(address => uint256) public cumulativeProfitPerStakeUnit; // profitToken -> cumulative profit units per stake token (scaled by 1e18)
         mapping(address => mapping(address => uint256)) public memberProfitUnitCheckpoints; // profitToken -> member -> profit units checkpoint at last claim

         // Add/Modify Events:
         // event CumulativeProfitUpdated(address indexed profitToken, uint256 newCumulativeProfitPerStakeUnit);
         // event MemberProfitCheckpointUpdated(address indexed profitToken, address indexed member, uint256 checkpoint);

         // Modify `distributeProfits` and `claimProfits` accordingly.

         // --- Revised Profit Distribution Functions ---

         // ** (Redefine state vars before these functions)**
         // mapping(address => uint256) public cumulativeProfitPerStakeUnit; // profitToken -> cumulative profit units per stake token (scaled by 1e18)
         // mapping(address => mapping(address => uint256)) public memberProfitUnitCheckpoints; // profitToken -> member -> profit units checkpoint at last claim


    } // End of original claimProfits function body - Will replace with revised version below


    // --- Revised Profit Distribution using CPPSU ---

    mapping(address => uint256) public cumulativeProfitPerStakeUnit; // profitToken -> cumulative profit units per stake token (scaled by 1e18)
    mapping(address => mapping(address => uint256)) public memberProfitUnitCheckpoints; // profitToken -> member -> profit units checkpoint at last claim
    // Need to also track total distributed per token for the `distributeProfits` require check
    mapping(address => uint256) private _totalDistributedProfits; // Internal tracking

    event CumulativeProfitUpdated(address indexed profitToken, uint256 newCumulativeProfitPerStakeUnit);
    event MemberProfitCheckpointUpdated(address indexed profitToken, address indexed member, uint256 checkpoint);


    /**
     * @notice Allows a trusted role (like the Executor, or via a successful proposal)
     * to signal that a certain amount of a token is available as profit
     * for distribution among current stakers.
     * The actual tokens must be transferred to the contract *before* or *by* calling this function.
     * Updates the cumulative profit per stake unit.
     * @param profitToken The address of the token to distribute (address(0) for ETH).
     * @param amount The amount of profit token available for distribution.
     */
    function distributeProfits(address profitToken, uint256 amount) public onlyExecutor nonReentrant whenNotPaused {
        require(amount > 0, "DAIC: Amount must be greater than 0");

        // Verify the contract holds the amount *after* any potential external transfer
        uint256 contractBalance;
        if (profitToken == address(0)) {
            contractBalance = address(this).balance;
        } else {
            IERC20 token = IERC20(profitToken);
            contractBalance = token.balanceOf(address(this));
        }
        // Ensure the contract has received at least the sum of previously distributed + new amount
        // This requires the Executor to ensure the transfer happens before or during the execution of the distribute call.
        require(contractBalance >= _totalDistributedProfits[profitToken] + amount, "DAIC: Contract balance insufficient for distribution");


        _totalDistributedProfits[profitToken] += amount;

        uint256 currentTotalStake = totalStaked;
        if (currentTotalStake > 0) {
            // Calculate profit units per stake unit and add to cumulative
            // Scale by 1e18 to maintain precision
            uint256 profitUnits = (amount * 1e18) / currentTotalStake;
            cumulativeProfitPerStakeUnit[profitToken] += profitUnits;
            emit CumulativeProfitUpdated(profitToken, cumulativeProfitPerStakeUnit[profitToken]);
        }
        // If totalStaked is 0, the amount is added to _totalDistributedProfits but no cumulative units are updated.
        // This profit remains undistributable by the CPPSU method until stake exists.
        // A real DAO might handle this differently (e.g., hold until stakers exist).

        emit ProfitsDistributed(profitToken, amount);
    }

    /**
     * @notice Calculates the claimable profit for a member for a specific token.
     * @param profitToken The address of the token (address(0) for ETH).
     * @param member The address of the member.
     * @return The amount of profit the member can claim.
     */
    function getMemberProfitShare(address profitToken, address member) public view returns (uint256) {
        uint256 stake = memberStake[member];
        if (stake == 0) return 0;

        uint256 cumulativeUnits = cumulativeProfitPerStakeUnit[profitToken];
        uint256 checkpointUnits = memberProfitUnitCheckpoints[profitToken][member];

        // Total units earned by this member: stake * cumulativeUnits (scaled down)
        uint256 totalEarnedUnits = (stake * cumulativeUnits) / 1e18;

        // Claimable = Total earned units - units claimed at last checkpoint
        return totalEarnedUnits - checkpointUnits;
    }


    /**
     * @notice Allows a member to claim their available profit share for a specific token.
     * @param profitToken The address of the token to claim profits for (address(0) for ETH).
     */
    function claimProfits(address profitToken) public onlyMember nonReentrant whenNotPaused {
         uint256 claimableAmount = getMemberProfitShare(profitToken, msg.sender);
         require(claimableAmount > 0, "DAIC: No claimable profits for this token");

         // Update the member's checkpoint to the current cumulative total
         uint256 currentCumulativeUnits = cumulativeProfitPerStakeUnit[profitToken];
         memberProfitUnitCheckpoints[profitToken][msg.sender] = (memberStake[msg.sender] * currentCumulativeUnits) / 1e18; // Update checkpoint based on current stake

         // Perform the transfer
         if (profitToken == address(0)) {
             (bool success, ) = payable(msg.sender).call{value: claimableAmount}("");
             require(success, "DAIC: ETH profit withdrawal failed");
         } else {
             IERC20 token = IERC20(profitToken);
             require(token.transfer(msg.sender, claimableAmount), "DAIC: ERC20 profit withdrawal failed");
         }

         emit ProfitsClaimed(msg.sender, profitToken, claimableAmount);
         // Note: _totalDistributedProfits is NOT decreased here. It tracks the total *ever* distributed.
     }


    // --- Emergency and Recovery Functions ---

    /**
     * @notice Initiates an emergency shutdown, pausing critical operations.
     * This should be triggerable by a highly privileged governance mechanism (e.g., high quorum vote).
     * Placeholder implementation: Only Executor can call. Should be more decentralized.
     */
    function emergencyShutdown() public onlyExecutor whenNotPaused {
        paused = true;
        emit EmergencyShutdown();
    }

    /**
     * @notice Allows recovery of accidentally sent ERC20 tokens (excluding core contract tokens).
     * This function should be callable only by a trusted role or via governance.
     * @param tokenAddress The address of the ERC20 token to recover.
     * @param amount The amount of tokens to recover.
     */
    function recoverERC20(address tokenAddress, uint256 amount) public onlyExecutor whenNotPaused {
        require(tokenAddress != address(membershipToken), "DAIC: Cannot recover membership token");
        // Add checks to prevent recovering main pool assets if necessary
        // For this example, allowing recovery *if* not membership token.
        // In a real system, might need explicit whitelisting of *recoverable* tokens.

        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "DAIC: Recovery transfer failed");
        emit RecoveredERC20(tokenAddress, amount);
    }

    // --- View Functions ---

    /**
     * @notice Returns the state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        // This internal function already does the state calculation based on current block.
        return calculateProposalOutcome(proposalId);
    }

    /**
     * @notice Returns the current staked amount of a member.
     * @param member The address of the member.
     * @return The staked amount.
     */
    function getMemberStake(address member) public view returns (uint256) {
        return memberStake[member];
    }

    /**
     * @notice Returns the total amount of membership tokens staked in the contract.
     * @return The total staked amount.
     */
    function getTotalStake() public view returns (uint256) {
        return totalStaked;
    }

    /**
     * @notice Returns the balance of a specific asset in the investment pool.
     * @param tokenAddress The address of the token (address(0) for ETH).
     * @return The balance of the asset in the pool.
     */
    function getPoolAssetBalance(address tokenAddress) public view returns (uint256) {
         if (tokenAddress == address(0)) {
             return address(this).balance;
         } else {
             IERC20 token = IERC20(tokenAddress);
             return token.balanceOf(address(this));
         }
    }

    /**
     * @notice Returns how a member voted on a specific proposal.
     * @param proposalId The ID of the proposal.
     * @param member The address of the member.
     * @return The vote type (0=Did Not Vote, 1=No, 2=Yes, 3=Abstain).
     */
    function getMemberVote(uint256 proposalId, address member) public view returns (uint8) {
        // proposalVotes stores 1, 2, 3 for No, Yes, Abstain respectively, 0 for no vote.
        return proposalVotes[proposalId][member];
    }

    /**
     * @notice Returns the reputation score of a member.
     * @param member The address of the member.
     * @return The reputation score.
     */
    function getMemberReputation(address member) public view returns (uint256) {
        return memberReputation[member];
    }

    /**
     * @notice Returns the current delegatee of a member.
     * @param member The address of the member.
     * @return The delegatee address, or address(0) if no delegation set (defaults to self-delegation implicitly if memberStake > 0).
     */
    function getMemberDelegate(address member) public view returns (address) {
        return delegates[member];
    }

    /**
     * @notice Checks if a target address is whitelisted for external calls.
     * @param target The address to check.
     * @return True if whitelisted, false otherwise.
     */
    function isWhitelisted(address target) public view returns (bool) {
        return whitelistedTargets[target];
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
```