Okay, let's design a smart contract incorporating several advanced concepts: a Time-Locked Vault with NFT-based Governance and Generic Proposal Execution.

This contract will hold funds (ETH and ERC-20). Spending or withdrawing these funds is controlled by a governance process. The right to vote in this process is tied to holding a specific external NFT. Proposals, once approved by voters and passing quorum/threshold checks, are placed in a timelock queue before they can be executed, allowing for a final review period. It also includes the ability to execute arbitrary calls via approved proposals.

**Advanced/Creative/Trendy Concepts Used:**

1.  **NFT-Based Governance:** Voting power is derived from holding tokens of a specific (external) NFT contract.
2.  **Time-Locked Execution:** Approved proposals have a mandatory delay before execution.
3.  **Generic Proposal Execution:** The contract can execute arbitrary calls on itself or other contracts if approved by governance.
4.  **Delegated Call:** The execution uses low-level `call` allowing for flexible interaction.
5.  **Quorum & Threshold Voting:** Standard governance mechanics applied to NFT power.
6.  **Pausable:** Standard emergency mechanism.
7.  **ERC-20 & ETH Handling:** Manages multiple asset types.
8.  **Detailed Proposal State Management:** Tracks proposals through a lifecycle (Pending, Active, Succeeded, Queued, Executed, Failed, Canceled).
9.  **Distinct Voting Power vs. Vote Count:** Votes are weighted by the voter's NFT balance at the time of voting.
10. **Reentrancy Protection:** Standard practice, although less critical for outbound calls after a delay.

Let's aim for more than 20 *public/external* functions to cover setup, deposits, views, proposal creation, voting, and execution.

---

**Outline and Function Summary**

**Contract Name:** `TimeLockVaultWithVoting`

**Purpose:** A secure vault managing ETH and ERC-20 tokens, controlled by a time-locked governance process where voting power is determined by ownership of a specified external NFT.

**Inherits:** `Ownable`, `Pausable`, `SafeERC20` (for safe ERC-20 operations)

**State Variables:**

*   `_governanceNFT`: Address of the external NFT contract (ERC721 or ERC1155).
*   `_minVotingPeriod`: Minimum duration (in seconds) for voting on a proposal.
*   `_executionDelay`: Minimum delay (in seconds) between a proposal being queued and being executable.
*   `_proposalCreationDelay`: Delay (in seconds) after creation before voting starts.
*   `_quorumMinVotesPower`: Minimum total voting power required across 'For', 'Against', and 'Abstain' votes for a proposal to be considered for threshold check.
*   `_thresholdVotesPowerPercentage`: Percentage of (For + Against) voting power that must be 'For' for a proposal to succeed (e.g., 5100 for 51%).
*   `_proposalCounter`: Simple counter for proposal IDs.
*   `_proposals`: Mapping from proposal ID (uint256) to `Proposal` struct.

**Structs:**

*   `Proposal`: Defines the structure holding all details for a governance proposal.

**Enums:**

*   `ProposalState`: Defines the lifecycle states of a proposal.
*   `VoteType`: Defines the types of votes (Against, For, Abstain).

**Events:**

*   `DepositReceived`: Logs ETH or ERC-20 deposits.
*   `ProposalCreated`: Logs the creation of a new proposal.
*   `VoteCast`: Logs a vote being cast on a proposal.
*   `ProposalStateChanged`: Logs transitions between proposal states.
*   `ProposalQueued`: Logs a proposal being moved to the timelock queue.
*   `ProposalExecuted`: Logs the execution attempt of a proposal.
*   `ProposalCanceled`: Logs the cancellation of a proposal.
*   `ParametersUpdated`: Logs changes to governance parameters.
*   `VaultPaused`: Logs the pausing or unpausing of the vault.

**Functions:**

1.  `constructor`: Initializes the contract with owner, NFT address, and initial governance parameters.
2.  `setGovernanceNFT(address newNFT)`: Updates the address of the governance NFT contract (Owner only).
3.  `setVotingParameters(uint32 minVotingPeriod, uint32 executionDelay, uint32 proposalCreationDelay, uint256 quorumMinVotesPower, uint256 thresholdVotesPowerPercentage)`: Updates core governance timing and voting parameters (Owner only).
4.  `pause()`: Pauses critical contract operations (Owner only, Pausable).
5.  `unpause()`: Unpauses critical contract operations (Owner only, Pausable).
6.  `depositETH()`: Allows users to deposit ETH into the vault.
7.  `receive()`: Fallback function to receive plain ETH deposits. Treated same as `depositETH`.
8.  `depositERC20(IERC20 token, uint256 amount)`: Allows users to deposit a specified ERC-20 token into the vault (requires prior approval).
9.  `createWithdrawETHProposal(address recipient, uint256 amount, string description)`: Creates a proposal to withdraw a specific amount of ETH to a recipient.
10. `createWithdrawERC20Proposal(IERC20 token, address recipient, uint256 amount, string description)`: Creates a proposal to withdraw a specific amount of a specific ERC-20 token to a recipient.
11. `createGenericProposal(address target, uint256 value, bytes data, string description)`: Creates a proposal to execute an arbitrary call on a target address with a specified value and calldata.
12. `castVote(uint256 proposalId, VoteType voteType)`: Allows an NFT holder to cast a vote on an active proposal. Voting power is determined by NFT balance.
13. `queueProposal(uint256 proposalId)`: Moves a successful proposal to the timelock queue, setting its execution start time. Anyone can call this.
14. `executeProposal(uint256 proposalId)`: Executes a queued proposal after its execution delay has passed. Anyone can call this.
15. `cancelProposal(uint256 proposalId)`: Allows the proposer or owner to cancel a proposal before it is queued/executed (rules apply based on state).
16. `getProposalState(uint256 proposalId)`: Returns the current state of a proposal. (View)
17. `getProposalDetails(uint256 proposalId)`: Returns the full details of a proposal struct. (View)
18. `getProposalVotes(uint256 proposalId)`: Returns the vote counts (power) for a proposal. (View)
19. `hasVoted(uint256 proposalId, address voter)`: Checks if a specific address has already voted on a proposal. (View)
20. `getVotingPower(address voter)`: Returns the current voting power of an address based on their NFT balance. (View)
21. `getTotalETHBalance()`: Returns the total ETH held in the vault. (View)
22. `getTotalERC20Balance(IERC20 token)`: Returns the total balance of a specific ERC-20 token held in the vault. (View)
23. `getGovernanceNFT()`: Returns the address of the governance NFT contract. (View)
24. `getVotingParameters()`: Returns the current governance timing and voting parameters. (View)

**Internal Helper Functions:**

*   `_state(uint256 proposalId)`: Internal function to calculate the current state of a proposal based on timestamps and votes.
*   `_getNFTBalance(address account)`: Reads the balance of the governance NFT for an account.
*   `_calculateVotingPower(address account)`: Calculates the voting power (simply NFT balance in this case).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// Assuming ERC1155 might also be used, import its interface if needed,
// but IERC721.balanceOf is often enough if just checking > 0 balance.
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


/**
 * @title TimeLockVaultWithVoting
 * @dev A time-locked vault governed by NFT holders with generic proposal execution capabilities.
 *
 * Outline:
 * - Manages ETH and ERC-20 deposits.
 * - Funds are spent or moved only via governance proposals.
 * - Voting power for governance is based on holding a specified external NFT.
 * - Proposals follow a lifecycle: Pending -> Active -> Succeeded/Failed -> Queued -> Executed/Canceled.
 * - Successful proposals are subject to a mandatory timelock (execution delay) before execution.
 * - Supports arbitrary calls (generic proposals) on specified targets.
 * - Includes owner-based pausing mechanism for emergencies.
 *
 * Function Summary:
 * - Core Setup: constructor, setGovernanceNFT, setVotingParameters.
 * - Control: pause, unpause.
 * - Deposits: depositETH, receive, depositERC20.
 * - Proposal Creation: createWithdrawETHProposal, createWithdrawERC20Proposal, createGenericProposal.
 * - Governance Action: castVote, queueProposal, executeProposal, cancelProposal.
 * - View Functions: getProposalState, getProposalDetails, getProposalVotes, hasVoted, getVotingPower,
 *                   getTotalETHBalance, getTotalERC20Balance, getGovernanceNFT, getVotingParameters.
 * - Internal Helpers: _state, _getNFTBalance, _calculateVotingPower.
 */
contract TimeLockVaultWithVoting is Ownable, Pausable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    address public _governanceNFT; // Address of the external NFT contract (ERC721 or ERC1155)

    uint32 public _minVotingPeriod; // Minimum duration (seconds) for voting
    uint32 public _executionDelay; // Minimum delay (seconds) between queueing and execution
    uint32 public _proposalCreationDelay; // Delay (seconds) after creation before voting starts

    // Governance parameters based on total voting power cast
    uint256 public _quorumMinVotesPower; // Minimum total voting power (For + Against + Abstain) required for a proposal to pass quorum
    uint256 public _thresholdVotesPowerPercentage; // Percentage (0-10000, e.g., 5100 for 51%) of (For + Against) votes power that must be For

    uint256 private _proposalCounter; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) private _proposals; // Mapping from proposal ID to Proposal struct

    // --- Enums ---

    enum ProposalState {
        Pending, // Waiting for voting period to start
        Active, // Voting is open
        Canceled, // Proposal was canceled
        Succeeded, // Voting ended, conditions met
        Failed, // Voting ended, conditions not met
        Queued, // Succeeded proposal moved to timelock queue
        Executed // Proposal has been executed
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    // --- Structs ---

    struct Proposal {
        uint256 id;
        address proposer;
        address target; // Target contract for the proposal execution
        uint256 value; // ETH value to send with the execution
        bytes data; // Calldata for the execution
        string description; // A brief description of the proposal

        uint48 votingStartTime; // Timestamp when voting begins
        uint48 votingEndTime; // Timestamp when voting ends
        uint48 queueTime; // Timestamp when the proposal was queued for execution

        bool executed; // True if the proposal has been executed
        bool canceled; // True if the proposal has been canceled

        uint256 forVotesPower; // Total voting power of 'For' votes
        uint256 againstVotesPower; // Total voting power of 'Against' votes
        uint256 abstainVotesPower; // Total voting power of 'Abstain' votes

        mapping(address => VoteType) voters; // Address => VoteType to track who has voted and how
    }

    // --- Events ---

    event DepositReceived(address indexed token, address indexed sender, uint256 amount);
    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, address target, uint256 value);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votingPower, VoteType indexed voteType);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalQueued(uint256 indexed proposalId, uint48 queueTime);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ProposalCanceled(uint256 indexed proposalId);
    event ParametersUpdated(uint32 minVotingPeriod, uint32 executionDelay, uint32 proposalCreationDelay, uint256 quorumMinVotesPower, uint256 thresholdVotesPowerPercentage);
    event VaultPaused(bool paused);

    // --- Modifiers ---

    modifier onlyNFTGovernor() {
        require(_getNFTBalance(msg.sender) > 0, "TimeLockVault: Not an NFT governor");
        _;
    }

    // --- Constructor ---

    constructor(
        address initialOwner,
        address initialGovernanceNFT,
        uint32 initialMinVotingPeriod,
        uint32 initialExecutionDelay,
        uint32 initialProposalCreationDelay,
        uint256 initialQuorumMinVotesPower,
        uint256 initialThresholdVotesPowerPercentage
    ) Ownable(initialOwner) Pausable(false) {
        _governanceNFT = initialGovernanceNFT;
        _minVotingPeriod = initialMinVotingPeriod;
        _executionDelay = initialExecutionDelay;
        _proposalCreationDelay = initialProposalCreationDelay;
        _quorumMinVotesPower = initialQuorumMinVotesPower;
        _thresholdVotesPowerPercentage = initialThresholdVotesPowerPercentage;

        emit ParametersUpdated(_minVotingPeriod, _executionDelay, _proposalCreationDelay, _quorumMinVotesPower, _thresholdVotesPowerPercentage);
    }

    // --- Configuration Functions (Owner Only) ---

    /**
     * @dev Sets the address of the external NFT contract used for governance.
     * @param newNFT The address of the new governance NFT contract.
     */
    function setGovernanceNFT(address newNFT) external onlyOwner {
        _governanceNFT = newNFT;
    }

    /**
     * @dev Sets the governance timing and voting parameters.
     * @param minVotingPeriod_ Minimum duration (seconds) for voting.
     * @param executionDelay_ Minimum delay (seconds) between queueing and execution.
     * @param proposalCreationDelay_ Delay (seconds) after creation before voting starts.
     * @param quorumMinVotesPower_ Minimum total power needed for quorum.
     * @param thresholdVotesPowerPercentage_ Percentage of (For+Against) that must be For (e.g., 5100 for 51%).
     */
    function setVotingParameters(
        uint32 minVotingPeriod_,
        uint32 executionDelay_,
        uint32 proposalCreationDelay_,
        uint256 quorumMinVotesPower_,
        uint256 thresholdVotesPowerPercentage_
    ) external onlyOwner {
        _minVotingPeriod = minVotingPeriod_;
        _executionDelay = executionDelay_;
        _proposalCreationDelay = proposalCreationDelay_;
        _quorumMinVotesPower = quorumMinVotesPower_;
        _thresholdVotesPowerPercentage = thresholdVotesPowerPercentage_;

        emit ParametersUpdated(_minVotingPeriod, _executionDelay, _proposalCreationDelay, _quorumMinVotesPower, _thresholdVotesPowerPercentage);
    }

    // --- Pause Functions (Owner Only) ---

    function pause() public override onlyOwner {
        _pause();
        emit VaultPaused(true);
    }

    function unpause() public override onlyOwner {
        _unpause();
        emit VaultPaused(false);
    }

    // --- Deposit Functions ---

    /**
     * @dev Allows sending ETH to the vault.
     */
    receive() external payable whenNotPaused {
        emit DepositReceived(address(0), msg.sender, msg.value);
    }

    /**
     * @dev Allows depositing ETH into the vault. Same as receive().
     */
    function depositETH() external payable whenNotPaused {
        emit DepositReceived(address(0), msg.sender, msg.value);
    }

    /**
     * @dev Allows depositing ERC-20 tokens into the vault.
     * @param token The address of the ERC-20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(IERC20 token, uint256 amount) external whenNotPaused {
        require(amount > 0, "TimeLockVault: Deposit amount must be > 0");
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit DepositReceived(address(token), msg.sender, amount);
    }

    // --- Proposal Creation Functions ---

    /**
     * @dev Creates a proposal to withdraw ETH from the vault.
     * @param recipient Address to send ETH to.
     * @param amount Amount of ETH to withdraw.
     * @param description Brief description of the proposal.
     * @return The ID of the created proposal.
     */
    function createWithdrawETHProposal(
        address recipient,
        uint256 amount,
        string memory description
    ) external whenNotPaused returns (uint256) {
        require(recipient != address(0), "TimeLockVault: Invalid recipient");
        require(amount > 0, "TimeLockVault: Withdrawal amount must be > 0");

        // abi.encodeWithSignature("withdrawETH(address,uint256)", recipient, amount)
        // We are executing a call *from* this contract *to* the recipient,
        // but the governance call targets *this* contract to trigger that transfer.
        // So the target is THIS contract, the data calls an internal helper function.
        // Or, we can make it a generic call targeting the recipient directly?
        // Let's stick to the generic call model where governance calls an arbitrary target.
        // The target should be the recipient address, value is amount, data is empty for direct ETH transfer.
        // Using a generic call targeting `recipient` with `value=amount` and empty `data` is cleaner.
        return createGenericProposal(recipient, amount, "", description);
    }


    /**
     * @dev Creates a proposal to withdraw ERC-20 tokens from the vault.
     * @param token The address of the ERC-20 token.
     * @param recipient Address to send tokens to.
     * @param amount Amount of tokens to withdraw.
     * @param description Brief description of the proposal.
     * @return The ID of the created proposal.
     */
    function createWithdrawERC20Proposal(
        IERC20 token,
        address recipient,
        uint256 amount,
        string memory description
    ) external whenNotPaused returns (uint256) {
        require(token != address(0), "TimeLockVault: Invalid token address");
        require(recipient != address(0), "TimeLockVault: Invalid recipient");
        require(amount > 0, "TimeLockVault: Withdrawal amount must be > 0");

        // The target is the token contract, the data is the transfer call.
        bytes memory callData = abi.encodeWithSelector(token.transfer.selector, recipient, amount);

        return createGenericProposal(address(token), 0, callData, description);
    }

    /**
     * @dev Creates a generic proposal to execute an arbitrary call.
     * Can be used to call functions on this contract or other contracts.
     * @param target The address of the target contract.
     * @param value The amount of ETH (wei) to send with the call.
     * @param data The calldata for the function call.
     * @param description Brief description of the proposal.
     * @return The ID of the created proposal.
     */
    function createGenericProposal(
        address target,
        uint256 value,
        bytes memory data,
        string memory description
    ) public whenNotPaused returns (uint256) {
        require(target != address(0), "TimeLockVault: Invalid target address");
        require(bytes(description).length > 0, "TimeLockVault: Description cannot be empty");

        _proposalCounter++;
        uint256 proposalId = _proposalCounter;

        Proposal storage proposal = _proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.target = target;
        proposal.value = value;
        proposal.data = data;
        proposal.description = description;
        proposal.votingStartTime = uint48(block.timestamp + _proposalCreationDelay);
        proposal.votingEndTime = uint48(proposal.votingStartTime + _minVotingPeriod);
        proposal.queueTime = 0; // Not yet queued
        proposal.executed = false;
        proposal.canceled = false;
        proposal.forVotesPower = 0;
        proposal.againstVotesPower = 0;
        proposal.abstainVotesPower = 0;
        // Voters mapping is initialized empty

        emit ProposalCreated(proposalId, msg.sender, description, target, value);
        emit ProposalStateChanged(proposalId, ProposalState.Pending);

        return proposalId;
    }

    // --- Governance Action Functions ---

    /**
     * @dev Allows an NFT holder to cast a vote on a proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param voteType The type of vote (Against, For, Abstain).
     */
    function castVote(uint256 proposalId, VoteType voteType) external whenNotPaused onlyNFTGovernor {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "TimeLockVault: Proposal not found");
        require(_state(proposalId) == ProposalState.Active, "TimeLockVault: Voting is not active");
        require(proposal.voters[msg.sender] == VoteType(0), "TimeLockVault: Already voted"); // Check if default value (0)

        uint256 votingPower = _calculateVotingPower(msg.sender);
        require(votingPower > 0, "TimeLockVault: Voter has no voting power"); // Should be covered by onlyNFTGovernor, but good check

        proposal.voters[msg.sender] = voteType; // Store the vote type

        if (voteType == VoteType.For) {
            proposal.forVotesPower += votingPower;
        } else if (voteType == VoteType.Against) {
            proposal.againstVotesPower += votingPower;
        } else if (voteType == VoteType.Abstain) {
            proposal.abstainVotesPower += votingPower;
        }
        // No need to track total voters count explicitly if we use the mapping to check uniqueness
        // proposal.totalVoters++;

        emit VoteCast(proposalId, msg.sender, votingPower, voteType);
    }

    /**
     * @dev Moves a successful proposal to the timelock queue.
     * Any address can call this once the voting period ends and the proposal is Succeeded.
     * @param proposalId The ID of the proposal to queue.
     */
    function queueProposal(uint256 proposalId) external whenNotPaused {
        require(_state(proposalId) == ProposalState.Succeeded, "TimeLockVault: Proposal must be Succeeded to queue");
        Proposal storage proposal = _proposals[proposalId];

        proposal.queueTime = uint48(block.timestamp);

        emit ProposalQueued(proposalId, proposal.queueTime);
        emit ProposalStateChanged(proposalId, ProposalState.Queued);
    }

    /**
     * @dev Executes a proposal that is in the queue and the execution delay has passed.
     * Any address can call this.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused {
        require(_state(proposalId) == ProposalState.Queued, "TimeLockVault: Proposal must be Queued to execute");
        Proposal storage proposal = _proposals[proposalId];
        require(block.timestamp >= proposal.queueTime + _executionDelay, "TimeLockVault: Execution delay not passed");

        proposal.executed = true;

        // Execute the generic call
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.data);

        emit ProposalExecuted(proposalId, success);
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        // Note: If the call fails, the proposal state is still Executed, but success is false.
        // Funds (ETH/tokens) might be stuck if the call failed and wasn't for this contract.
        // Careful proposal creation is needed!
    }

    /**
     * @dev Cancels a proposal.
     * Can be called by the proposer before voting starts (Pending state),
     * or by the contract owner at any state before execution.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "TimeLockVault: Proposal not found");
        ProposalState currentState = _state(proposalId);

        bool isProposerCancel = (msg.sender == proposal.proposer && currentState == ProposalState.Pending);
        bool isOwnerCancel = (msg.sender == owner() && currentState != ProposalState.Executed && currentState != ProposalState.Canceled);

        require(isProposerCancel || isOwnerCancel, "TimeLockVault: Not authorized to cancel or cannot cancel in this state");

        proposal.canceled = true;

        emit ProposalCanceled(proposalId);
        emit ProposalStateChanged(proposalId, ProposalState.Canceled);
    }

    // --- View Functions ---

    /**
     * @dev Returns the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The current ProposalState.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
        require(_proposals[proposalId].id != 0, "TimeLockVault: Proposal not found");
        return _state(proposalId);
    }

    /**
     * @dev Returns the details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The Proposal struct.
     */
    function getProposalDetails(uint256 proposalId) external view returns (Proposal memory) {
        require(_proposals[proposalId].id != 0, "TimeLockVault: Proposal not found");
        Proposal storage proposal = _proposals[proposalId];
        // Return a memory copy, excluding the `voters` mapping
        return Proposal({
            id: proposal.id,
            proposer: proposal.proposer,
            target: proposal.target,
            value: proposal.value,
            data: proposal.data, // Note: large calldata can make this view call expensive
            description: proposal.description,
            votingStartTime: proposal.votingStartTime,
            votingEndTime: proposal.votingEndTime,
            queueTime: proposal.queueTime,
            executed: proposal.executed,
            canceled: proposal.canceled,
            forVotesPower: proposal.forVotesPower,
            againstVotesPower: proposal.againstVotesPower,
            abstainVotesPower: proposal.abstainVotesPower,
            voters: mapping(address => VoteType)(0) // Cannot return mappings directly
        });
    }


    /**
     * @dev Returns the vote counts (total power) for a proposal.
     * @param proposalId The ID of the proposal.
     * @return forVotesPower, againstVotesPower, abstainVotesPower.
     */
    function getProposalVotes(uint256 proposalId) external view returns (uint256 forVotesPower, uint256 againstVotesPower, uint256 abstainVotesPower) {
        require(_proposals[proposalId].id != 0, "TimeLockVault: Proposal not found");
        Proposal storage proposal = _proposals[proposalId];
        return (proposal.forVotesPower, proposal.againstVotesPower, proposal.abstainVotesPower);
    }

    /**
     * @dev Checks if a specific address has already voted on a proposal.
     * @param proposalId The ID of the proposal.
     * @param voter The address to check.
     * @return True if the voter has cast a vote other than the default (0).
     */
    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        require(_proposals[proposalId].id != 0, "TimeLockVault: Proposal not found");
        // Default enum value is 0 (Against). Need to check if it's set to something other than default state.
        // A better mapping would be address => bool hasVoted, and store vote type separately.
        // Let's update struct definition in thought process, but stick to this check for now.
        // A common pattern is mapping(address => uint8) vote; where 0 is not voted, 1=Against, 2=For, 3=Abstain.
        // With current enum: 0=Against, 1=For, 2=Abstain. If we use 0 for NotVoted, need to adjust enum.
        // Let's assume VoteType(0) is the default state before voting.
        return _proposals[proposalId].voters[voter] != VoteType(0);
    }

    /**
     * @dev Returns the current voting power of an address based on their NFT balance.
     * Assumes ERC-721 or ERC-1155 where balance > 0 means voting power.
     * Can be extended for tiered power based on NFT type/quantity.
     * @param voter The address to check.
     * @return The calculated voting power.
     */
    function getVotingPower(address voter) public view returns (uint256) {
        return _calculateVotingPower(voter);
    }

    /**
     * @dev Returns the total ETH balance held by the vault.
     */
    function getTotalETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total balance of a specific ERC-20 token held by the vault.
     * @param token The address of the ERC-20 token.
     */
    function getTotalERC20Balance(IERC20 token) external view returns (uint256) {
        require(address(token) != address(0), "TimeLockVault: Invalid token address");
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns the address of the governance NFT contract.
     */
    function getGovernanceNFT() external view returns (address) {
        return _governanceNFT;
    }

    /**
     * @dev Returns the current governance timing and voting parameters.
     * @return minVotingPeriod, executionDelay, proposalCreationDelay, quorumMinVotesPower, thresholdVotesPowerPercentage.
     */
    function getVotingParameters() external view returns (uint32, uint32, uint32, uint256, uint256) {
        return (_minVotingPeriod, _executionDelay, _proposalCreationDelay, _quorumMinVotesPower, _thresholdVotesPowerPercentage);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to determine the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The calculated ProposalState.
     */
    function _state(uint256 proposalId) internal view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.queueTime != 0) {
            return ProposalState.Queued;
        }
        if (block.timestamp < proposal.votingStartTime) {
            return ProposalState.Pending;
        }
        if (block.timestamp >= proposal.votingStartTime && block.timestamp < proposal.votingEndTime) {
            return ProposalState.Active;
        }
        // Voting period has ended. Check conditions for Succeeded/Failed.
        uint256 totalVotesPowerCast = proposal.forVotesPower + proposal.againstVotesPower + proposal.abstainVotesPower;
        uint256 forAgainstVotesPower = proposal.forVotesPower + proposal.againstVotesPower;

        // Check Quorum: Total voting power cast must meet minimum required quorum power
        bool hasQuorum = totalVotesPowerCast >= _quorumMinVotesPower;

        // Check Threshold: Percentage of 'For' power among 'For' + 'Against' power
        // Avoid division by zero if no For/Against votes
        bool hasThreshold = (forAgainstVotesPower > 0)
            ? (proposal.forVotesPower * 10000 >= forAgainstVotesPower * _thresholdVotesPowerPercentage)
            : false; // If no For/Against votes, threshold is not met

        if (hasQuorum && hasThreshold) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Failed;
        }
    }


    /**
     * @dev Internal function to get the NFT balance of an account.
     * Assumes the governance NFT is either ERC721 or ERC1155 where balanceOf works.
     * @param account The address to check.
     * @return The balance of the governance NFT for the account.
     */
    function _getNFTBalance(address account) internal view returns (uint256) {
        if (_governanceNFT == address(0)) {
            return 0; // No NFT set, no voting power
        }
        // Attempt ERC721/ERC1155 balance check. Both use balanceOf.
        // This is a simplified check. More complex logic needed for tiered power.
        try IERC721(_governanceNFT).balanceOf(account) returns (uint256 balance) {
             // For ERC721, balance is 0 or 1. For ERC1155 it can be more.
             // Using the raw balance as voting power.
             return balance;
        } catch {
            // If the contract doesn't support ERC721/ERC1155 balanceOf, treat as 0 power.
            // Or add checks for specific interface support if needed.
            return 0;
        }
    }

    /**
     * @dev Internal function to calculate the voting power for an address.
     * Currently, this is just the NFT balance. Can be extended later.
     * @param account The address to calculate power for.
     * @return The voting power.
     */
    function _calculateVotingPower(address account) internal view returns (uint256) {
        // Simple 1:1 mapping from NFT balance to voting power.
        // Could be extended: balance * weight, different power per NFT ID, etc.
        return _getNFTBalance(account);
    }
}
```