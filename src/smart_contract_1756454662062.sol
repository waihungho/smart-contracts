This smart contract, named **AuraWeaverProtocol**, introduces a unique blend of **Dynamic Non-Fungible Tokens (dNFTs)**, a **Reputation-Gated Decentralized Autonomous Task System**, and **On-chain Dispute Resolution**. It aims to foster a decentralized economy where users earn reputation through contributions, which in turn enhances their unique Aura NFTs and grants them greater influence within the protocol.

**Core Concepts:**

1.  **Dynamic Aura NFTs (dNFTs):** ERC721 tokens (Auras) whose metadata (e.g., visual traits, level, status) dynamically changes based on their owner's on-chain reputation and activity within the protocol.
2.  **Reputation System:** A non-transferable (soulbound-like) score tied to a user's address, which can be earned by delegating tasks, successfully completing tasks, staking Auras, or participating in dispute resolution. Higher reputation unlocks more powerful protocol interactions.
3.  **Autonomous Task Delegation:** A system for users to define and fund off-chain tasks (e.g., data collection, content creation, off-chain computation). Other users can claim and execute these tasks, earning rewards upon successful verification.
4.  **Incentivized Execution & Verification:** Task executors are rewarded for successful completion, while delegators verify results. Both parties can gain or lose reputation based on task outcomes.
5.  **On-chain Dispute Resolution:** A mechanism for executors to challenge delegator's rejections. High-reputation users can then vote on disputes, and the contract programmatically resolves them, applying financial penalties and reputation adjustments.
6.  **Aura Evolution:** Users can stake their Auras for periodic reputation boosts, or even "refine" multiple low-tier Auras into a single higher-tier one, or "merge" Auras to combine their strengths, burning the consumed NFTs.

---

## Outline:

**I. Core Components:**
    A. Dynamic Aura NFTs (ERC721-like with dynamic metadata):
       - Minting/Burning Auras.
       - Updating Aura metadata based on user actions/reputation.
       - Retrieving Aura data.
       - Generating dynamic `tokenURI`.
    B. Reputation System:
       - Earning/Losing reputation.
       - Querying reputation score.
       - Claiming periodic reputation boosts for Aura holders.
    C. Task Management:
       - Delegating new tasks (defining parameters, funding).
       - Claiming tasks by executors.
       - Submitting task results.
       - Delegator-initiated verification of task results.
       - Distributing rewards for non-disputed, verified tasks.
       - Canceling unclaimed or unsubmitted tasks.

**II. Advanced Features & Utilities:**
    A. Aura Customization/Evolution:
       - Staking Auras for boosted reputation or yield (conceptual).
       - Unstaking Auras after duration.
       - Refining Auras (burning lower-tier Auras for higher-tier ones).
       - Merging Auras (combining traits/levels from two Auras).
    B. Dispute Resolution for Tasks:
       - Challenging task verification decisions.
       - Reputation-gated voting on disputes.
       - Programmatic resolution of disputes based on voting outcome.
    C. Protocol Parameters & Governance:
       - Setting core parameters (fees, reputation multipliers).
       - Emergency pause/unpause functionality.
       - Withdrawing accumulated protocol fees.
    D. Query Functions:
       - General getters for protocol state, tasks, and disputes.

---

## Function Summary:

1.  `mintAura(address to, string calldata initialMetadataURI) external`: Mints a new Aura NFT to `to` with an initial metadata URI.
2.  `updateAuraMetadata(uint256 tokenId) external`: Triggers a refresh of an Aura's metadata, prompting clients to re-fetch its dynamic `tokenURI`.
3.  `getAuraDetails(uint256 tokenId) public view returns (Aura memory)`: Retrieves all stored details for a given Aura NFT.
4.  `getCurrentAuraLevel(uint256 tokenId) public view returns (uint256)`: Calculates the current level or tier of an Aura based on its owner's reputation.
5.  `tokenURI(uint256 tokenId) public view override returns (string memory)`: Generates a dynamic, Base64-encoded JSON metadata URI for an Aura, incorporating its owner's current reputation and other on-chain stats.
6.  `getReputation(address user) public view returns (uint256)`: Returns the current reputation score of a user.
7.  `claimReputationBoost(uint256 tokenId) external`: Allows an Aura holder to claim a small, periodic reputation boost for their activity.
8.  `delegateTask(string calldata taskDescription, uint256 rewardAmount, uint256 verificationDeposit, uint256 reputationRequired) external payable returns (uint256 taskId)`: Creates a new task, requiring the delegator to fund the reward and a verification deposit. Delegator must meet minimum reputation.
9.  `claimTask(uint256 taskId) external`: Allows a user to claim an open task for execution if they meet the task's reputation requirement.
10. `submitTaskResult(uint256 taskId, string calldata resultHash) external`: Submits the result (represented by an off-chain hash) of a claimed task.
11. `verifyTaskResult(uint256 taskId, bool success) external`: The delegator verifies the submitted task result, marking it as successful or rejected.
12. `distributeTaskRewards(uint256 taskId) external`: Distributes rewards to the executor and returns the deposit to the delegator for tasks successfully verified without dispute.
13. `cancelTask(uint256 taskId) external`: Allows the delegator to cancel an unclaimed or unsubmitted task, refunding all associated funds.
14. `stakeAura(uint256 tokenId, uint256 duration) external`: Stakes an Aura NFT for a specified duration to potentially gain reputation or yield (conceptual).
15. `unstakeAura(uint256 tokenId) external`: Unstakes an Aura NFT after its staking duration has passed.
16. `refineAura(uint256[] calldata lowTierAuraIds) external`: Burns multiple low-tier Auras owned by the caller to mint a single higher-tier Aura, representing a form of NFT evolution.
17. `mergeAuras(uint256 aura1Id, uint256 aura2Id) external`: Merges the 'power' or level of two Auras into one, burning the second Aura and transferring its essence to the first.
18. `challengeTaskVerification(uint256 taskId) external payable`: Initiates a dispute if an executor disagrees with the delegator's task rejection, requiring a matching challenge bond.
19. `voteOnDispute(uint256 disputeId, bool supportVerification) external`: Allows high-reputation users to vote on an ongoing dispute, supporting either the delegator's verification or the executor's challenge.
20. `resolveDispute(uint256 disputeId) external`: Resolves a dispute based on the voting outcome, distributing funds (rewards, deposits, penalties) and updating reputations accordingly.
21. `setProtocolFee(uint256 newFeeBasisPoints) external onlyOwner`: Sets the protocol fee charged on task rewards (in basis points).
22. `setReputationMultiplier(uint256 newMultiplier) external onlyOwner`: Sets the multiplier applied to reputation gains and losses.
23. `withdrawProtocolFees(address recipient) external onlyOwner`: Allows the owner to withdraw accumulated protocol fees.
24. `pause() external onlyOwner`: Pauses the contract, halting sensitive operations in emergencies.
25. `unpause() external onlyOwner`: Unpauses the contract after an emergency.
26. `getTaskDetails(uint256 taskId) public view returns (Task memory)`: Retrieves full details of a specific task.
27. `getOpenTasks() public view returns (uint256[] memory)`: Returns an array of IDs for tasks that are currently open for claiming.
28. `getDisputeDetails(uint256 disputeId) public view returns (Dispute memory)`: Retrieves details of an ongoing or resolved dispute.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For toString

/**
 * @title AuraWeaverProtocol
 * @dev A smart contract implementing Dynamic NFTs (Auras), a Reputation-Gated Decentralized Task System,
 *      and On-chain Dispute Resolution. It encourages on-chain activity and contributions.
 */
contract AuraWeaverProtocol is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // NFT, Task, and Dispute Counters
    Counters.Counter private _auraIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _disputeIds;

    // Reputation System
    mapping(address => uint256) public reputations;          // User reputation score
    mapping(uint256 => Aura) public auras;                   // Aura NFT details

    // Task Management
    enum TaskStatus { Open, Claimed, Submitted, Verified, Rejected, Disputed, Resolved, Canceled }
    mapping(uint256 => Task) public tasks;
    uint256[] public openTaskIds;                            // List of task IDs that are currently open for claiming

    // Dispute Resolution
    enum DisputeStatus { Pending, Voting, ResolvedChallengerWon, ResolvedDelegatorWon } // Simplified states
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => mapping(address => bool)) public hasVotedInDispute; // disputeId => voter => hasVoted
    mapping(uint256 => uint256) public disputeVotesFor;        // Total reputation supporting delegator's verification
    mapping(uint256 => uint256) public disputeVotesAgainst;    // Total reputation supporting challenger's rejection

    // Protocol Parameters (adjustable by owner)
    uint256 public protocolFeeBasisPoints = 500;             // 5% fee (500 / 10000)
    uint256 public reputationMultiplier = 100;               // Multiplier for reputation changes (e.g., 100 for 1x)
    uint256 public minReputationForDelegation = 100;         // Minimum reputation to delegate a task
    uint256 public minReputationForVoting = 500;             // Minimum reputation to vote on disputes
    uint256 public auraReputationBoostInterval = 1 days;     // How often an Aura can give a boost
    uint256 public auraReputationBoostAmount = 10;           // Amount of reputation boost per interval
    uint256 public disputeVotingPeriod = 3 days;             // Duration for dispute voting

    // Accumulated fees collected by the protocol
    uint256 public accumulatedProtocolFees;

    // --- Structs ---

    /**
     * @dev Represents a Dynamic Aura NFT. Its 'level' can change based on owner's reputation,
     *      and its metadata dynamically generated via `tokenURI`.
     */
    struct Aura {
        address owner;
        uint256 mintTime;
        uint256 lastReputationBoostClaimTime;
        uint256 level; // Represents tier/power for refinement/merge. Dynamically set by getCurrentAuraLevel.
        bool staked;
        uint256 stakeStartTime;
        uint256 stakeDuration; // In seconds
        uint256 initialMetadataHash; // Hash of the initial URI for tracking.
    }

    /**
     * @dev Represents a task delegated through the protocol.
     */
    struct Task {
        uint256 id;
        string description;
        address delegator;
        address executor;
        uint256 rewardAmount;            // Amount for successful executor
        uint256 verificationDeposit;     // Deposit held from delegator, returned if verification is upheld
        uint256 reputationRequired;      // Minimum reputation for an executor to claim
        TaskStatus status;
        string resultHash;               // Hash of off-chain result data submitted by executor
        uint256 createdAt;
        uint256 claimedAt;
        uint256 submittedAt;
        uint256 verifiedAt;
        uint256 disputeId;               // 0 if no dispute
    }

    /**
     * @dev Represents an ongoing or resolved dispute for a task verification.
     */
    struct Dispute {
        uint256 id;
        uint256 taskId;
        address challenger;              // The executor who challenged the verification
        address delegator;
        uint256 challengeBond;           // The amount sent by challenger (matches task.verificationDeposit)
        uint256 startVoteTime;
        uint256 endVoteTime;
        DisputeStatus status;
        bool challengerWon;              // True if challenger won, false if delegator won
    }

    // --- Events ---

    event AuraMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event AuraMetadataUpdated(uint256 indexed tokenId, address indexed owner, uint256 newLevel);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event TaskDelegated(uint256 indexed taskId, address indexed delegator, uint256 rewardAmount, uint256 reputationRequired);
    event TaskClaimed(uint256 indexed taskId, address indexed executor);
    event TaskResultSubmitted(uint256 indexed taskId, address indexed executor, string resultHash);
    event TaskVerified(uint256 indexed taskId, address indexed delegator, bool success);
    event TaskRewardsDistributed(uint256 indexed taskId, address indexed executor, uint256 rewardAmount);
    event TaskCanceled(uint256 indexed taskId, address indexed delegator);
    event AuraStaked(uint256 indexed tokenId, address indexed owner, uint256 duration);
    event AuraUnstaked(uint256 indexed tokenId, address indexed owner);
    event AuraRefined(address indexed owner, uint256 indexed newAuraId, uint256[] burnedAuraIds);
    event AuraMerged(address indexed owner, uint256 indexed targetAuraId, uint256 mergedAuraId);
    event DisputeChallenged(uint256 indexed disputeId, uint256 indexed taskId, address indexed challenger);
    event DisputeVoteCast(uint256 indexed disputeId, address indexed voter, bool supportVerification, uint256 reputation);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed taskId, bool challengerWon);
    event ProtocolFeeSet(uint256 newFeeBasisPoints);
    event ReputationMultiplierSet(uint256 newMultiplier);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    /**
     * @dev Restricts access to functions to users with at least `_minReputation`.
     */
    modifier onlyReputable(uint256 _minReputation) {
        require(reputations[msg.sender] >= _minReputation, "AuraWeaver: Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner)
        ERC721("AuraWeaverNFT", "AURA")
        Ownable(initialOwner)
    {}

    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to update a user's reputation score.
     *      Applies the `reputationMultiplier`.
     * @param user The address whose reputation is being updated.
     * @param amount The amount to change reputation by (can be negative).
     */
    function _updateReputation(address user, int256 amount) internal {
        uint256 currentRep = reputations[user];
        if (amount > 0) {
            reputations[user] = currentRep + (uint256(amount) * reputationMultiplier / 100);
        } else {
            uint256 deduction = uint256(-amount) * reputationMultiplier / 100;
            reputations[user] = currentRep > deduction ? currentRep - deduction : 0;
        }
        emit ReputationUpdated(user, reputations[user]);
    }

    /**
     * @dev Internal function to remove a task ID from the `openTaskIds` array.
     * @param taskId The ID of the task to remove.
     */
    function _removeOpenTask(uint256 taskId) internal {
        for (uint256 i = 0; i < openTaskIds.length; i++) {
            if (openTaskIds[i] == taskId) {
                openTaskIds[i] = openTaskIds[openTaskIds.length - 1]; // Swap with last element
                openTaskIds.pop(); // Remove last element
                break;
            }
        }
    }

    // --- I. Core Components ---

    // A. Dynamic Aura NFTs

    /**
     * @dev Mints a new Aura NFT to a specified address.
     * @param to The recipient of the new Aura.
     * @param initialMetadataURI An initial URI for the Aura's metadata (can be dynamic later).
     * @return The ID of the newly minted Aura.
     */
    function mintAura(address to, string calldata initialMetadataURI) external whenNotPaused returns (uint256) {
        _auraIds.increment();
        uint256 newAuraId = _auraIds.current();

        _safeMint(to, newAuraId);
        _setTokenURI(newAuraId, initialMetadataURI); // Store initial URI as fallback

        uint256 initialMetadataHash = uint256(keccak256(abi.encodePacked(initialMetadataURI)));

        auras[newAuraId] = Aura({
            owner: to,
            mintTime: block.timestamp,
            lastReputationBoostClaimTime: 0,
            level: 1, // Start at level 1, will be dynamically updated
            staked: false,
            stakeStartTime: 0,
            stakeDuration: 0,
            initialMetadataHash: initialMetadataHash
        });

        emit AuraMinted(newAuraId, to, initialMetadataURI);
        return newAuraId;
    }

    /**
     * @dev Triggers a metadata update for an Aura NFT.
     *      This function primarily signals off-chain clients that the Aura's dynamic metadata
     *      (returned by `tokenURI`) might have changed due to owner's activity or reputation.
     * @param tokenId The ID of the Aura NFT.
     */
    function updateAuraMetadata(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "AuraWeaver: Aura does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuraWeaver: Not Aura owner");

        uint256 newLevel = getCurrentAuraLevel(tokenId);
        auras[tokenId].level = newLevel; // Update internal level state

        emit AuraMetadataUpdated(tokenId, msg.sender, newLevel);
    }

    /**
     * @dev Retrieves all stored details for a given Aura NFT.
     * @param tokenId The ID of the Aura NFT.
     * @return A struct containing the Aura's details.
     */
    function getAuraDetails(uint256 tokenId) public view returns (Aura memory) {
        require(_exists(tokenId), "AuraWeaver: Aura does not exist");
        return auras[tokenId];
    }

    /**
     * @dev Calculates the current "level" or tier of an Aura based on its owner's reputation.
     *      This is a simple, example-based scaling.
     * @param tokenId The ID of the Aura NFT.
     * @return The calculated level of the Aura.
     */
    function getCurrentAuraLevel(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "AuraWeaver: Aura does not exist");
        address auraOwner = ownerOf(tokenId);
        uint256 rep = reputations[auraOwner];

        if (rep < 100) return 1;
        if (rep < 500) return 2;
        if (rep < 2000) return 3;
        if (rep < 10000) return 4;
        return 5; // Max level in this example
    }

    /**
     * @dev Overrides the standard ERC721 `tokenURI` function to provide dynamic JSON metadata.
     *      The metadata is generated on-the-fly, reflecting the owner's reputation, Aura level,
     *      and staking status.
     * @param tokenId The ID of the Aura NFT.
     * @return A Base64-encoded data URI containing the dynamic JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        address auraOwner = ownerOf(tokenId);
        uint256 currentRep = reputations[auraOwner];
        uint256 currentLevel = getCurrentAuraLevel(tokenId);
        Aura storage aura = auras[tokenId];

        // Construct dynamic JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name": "Aura #', tokenId.toString(),
            '", "description": "A dynamic representation of on-chain reputation and activity within AuraWeaverProtocol.", ',
            '"image": "ipfs://QmEXAMPLE/aura_level_', currentLevel.toString(), // Placeholder for IPFS image
            '.png", ',
            '"attributes": [',
            '{"trait_type": "Owner", "value": "', Strings.toHexString(uint160(auraOwner), 20), '"},',
            '{"trait_type": "Reputation", "value": ', currentRep.toString(), '},',
            '{"trait_type": "Level", "value": ', currentLevel.toString(), '},',
            '{"trait_type": "Mint Time", "value": ', aura.mintTime.toString(), '},',
            '{"trait_type": "Staked", "value": ', aura.staked ? '"True"' : '"False"', '}'
            // Add more dynamic attributes as needed, e.g., "Tasks Completed", "Disputes Won"
            ,']}'
        ));

        // Base64 encode the JSON string
        string memory baseURI = "data:application/json;base64,";
        return string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));
    }

    // B. Reputation System

    /**
     * @dev Returns the current reputation score of a user.
     * @param user The address of the user.
     * @return The reputation score.
     */
    function getReputation(address user) public view returns (uint256) {
        return reputations[user];
    }

    /**
     * @dev Allows an Aura holder to claim a small, periodic reputation boost.
     *      Can only be claimed once per `auraReputationBoostInterval`.
     * @param tokenId The ID of the Aura NFT.
     */
    function claimReputationBoost(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "AuraWeaver: Aura does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuraWeaver: Not Aura owner");

        Aura storage aura = auras[tokenId];
        require(block.timestamp >= aura.lastReputationBoostClaimTime + auraReputationBoostInterval, "AuraWeaver: Boost not yet available");

        _updateReputation(msg.sender, int256(auraReputationBoostAmount));
        aura.lastReputationBoostClaimTime = block.timestamp;
    }

    // C. Task Management

    /**
     * @dev Delegates a new task, funding it with a reward and verification deposit.
     *      The delegator must meet a minimum reputation requirement.
     * @param taskDescription A description of the task (off-chain).
     * @param rewardAmount The reward for the executor upon successful completion.
     * @param verificationDeposit A deposit held from the delegator, returned if verification is upheld,
     *                            or lost if a dispute proves delegator was wrong.
     * @param reputationRequired Minimum reputation an executor needs to claim this task.
     * @return The ID of the newly created task.
     */
    function delegateTask(
        string calldata taskDescription,
        uint256 rewardAmount,
        uint256 verificationDeposit,
        uint256 reputationRequired
    ) external payable whenNotPaused onlyReputable(minReputationForDelegation) returns (uint256 taskId) {
        require(msg.value == rewardAmount + verificationDeposit, "AuraWeaver: Incorrect ETH amount sent");
        require(rewardAmount > 0, "AuraWeaver: Reward must be greater than 0");
        require(verificationDeposit > 0, "AuraWeaver: Verification deposit must be greater than 0");

        _taskIds.increment();
        taskId = _taskIds.current();

        tasks[taskId] = Task({
            id: taskId,
            description: taskDescription,
            delegator: msg.sender,
            executor: address(0),
            rewardAmount: rewardAmount,
            verificationDeposit: verificationDeposit,
            reputationRequired: reputationRequired,
            status: TaskStatus.Open,
            resultHash: "",
            createdAt: block.timestamp,
            claimedAt: 0,
            submittedAt: 0,
            verifiedAt: 0,
            disputeId: 0
        });

        openTaskIds.push(taskId); // Add to list of open tasks
        _updateReputation(msg.sender, int256(reputationRequired / 10)); // Small rep boost for delegating
        emit TaskDelegated(taskId, msg.sender, rewardAmount, reputationRequired);
    }

    /**
     * @dev Allows a user to claim an open task for execution.
     *      The claimant must meet the task's reputation requirement.
     * @param taskId The ID of the task to claim.
     */
    function claimTask(uint256 taskId) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "AuraWeaver: Task does not exist");
        require(task.status == TaskStatus.Open, "AuraWeaver: Task not open");
        require(msg.sender != task.delegator, "AuraWeaver: Delegator cannot claim their own task");
        require(reputations[msg.sender] >= task.reputationRequired, "AuraWeaver: Insufficient reputation to claim task");

        task.executor = msg.sender;
        task.status = TaskStatus.Claimed;
        task.claimedAt = block.timestamp;
        _removeOpenTask(taskId); // Remove from list of open tasks

        emit TaskClaimed(taskId, msg.sender);
    }

    /**
     * @dev Submits the result of a claimed task. The result is represented by a hash
     *      pointing to off-chain data.
     * @param taskId The ID of the task.
     * @param resultHash The hash of the off-chain result data.
     */
    function submitTaskResult(uint256 taskId, string calldata resultHash) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "AuraWeaver: Task does not exist");
        require(task.status == TaskStatus.Claimed, "AuraWeaver: Task not claimed");
        require(msg.sender == task.executor, "AuraWeaver: Only executor can submit result");
        require(bytes(resultHash).length > 0, "AuraWeaver: Result hash cannot be empty");

        task.resultHash = resultHash;
        task.status = TaskStatus.Submitted;
        task.submittedAt = block.timestamp;

        emit TaskResultSubmitted(taskId, msg.sender, resultHash);
    }

    /**
     * @dev The delegator verifies a submitted task result.
     *      If successful, rewards can be distributed. If rejected, the executor can challenge.
     * @param taskId The ID of the task.
     * @param success True if the delegator accepts the result, false if rejected.
     */
    function verifyTaskResult(uint256 taskId, bool success) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "AuraWeaver: Task does not exist");
        require(task.status == TaskStatus.Submitted, "AuraWeaver: Task not submitted for verification");
        require(msg.sender == task.delegator, "AuraWeaver: Only delegator can verify task");
        require(task.disputeId == 0, "AuraWeaver: Task is under dispute");

        task.status = success ? TaskStatus.Verified : TaskStatus.Rejected;
        task.verifiedAt = block.timestamp;

        emit TaskVerified(taskId, msg.sender, success);
    }

    /**
     * @dev Distributes rewards for a task that has been successfully `Verified` by the delegator
     *      and is not under dispute.
     * @param taskId The ID of the task.
     */
    function distributeTaskRewards(uint256 taskId) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "AuraWeaver: Task does not exist");
        require(task.executor != address(0), "AuraWeaver: Task has no executor");
        require(task.status == TaskStatus.Verified && task.disputeId == 0, "AuraWeaver: Task not ready for reward distribution (either not verified or under dispute)");
        require(task.rewardAmount > 0, "AuraWeaver: Rewards already distributed or zero");

        uint256 rewardToExecutor = task.rewardAmount;
        uint256 fee = rewardToExecutor * protocolFeeBasisPoints / 10000;
        uint256 finalReward = rewardToExecutor - fee;

        // Send final reward to executor
        (bool successExecutor,) = task.executor.call{value: finalReward}("");
        require(successExecutor, "AuraWeaver: Failed to send reward to executor");

        // Return verification deposit to delegator
        (bool successDelegator,) = task.delegator.call{value: task.verificationDeposit}("");
        require(successDelegator, "AuraWeaver: Failed to return deposit to delegator");

        // Update reputation
        _updateReputation(task.executor, int256(rewardToExecutor / 100)); // Rep boost for success
        _updateReputation(task.delegator, int256(rewardToExecutor / 200)); // Small rep boost for successful delegation

        // Collect protocol fee
        accumulatedProtocolFees += fee;

        // Mark task as fully handled by clearing fund amounts
        task.rewardAmount = 0;
        task.verificationDeposit = 0;
        task.status = TaskStatus.Resolved; // Mark as resolved after distribution

        emit TaskRewardsDistributed(taskId, task.executor, finalReward);
    }

    /**
     * @dev Allows the delegator to cancel an unclaimed or unsubmitted task.
     *      All associated funds are refunded to the delegator.
     * @param taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 taskId) external whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "AuraWeaver: Task does not exist");
        require(msg.sender == task.delegator, "AuraWeaver: Only delegator can cancel task");
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Claimed, "AuraWeaver: Task cannot be canceled in its current state");
        require(task.rewardAmount > 0, "AuraWeaver: Task funds already handled"); // Ensure funds are still there

        if (task.status == TaskStatus.Open) {
            _removeOpenTask(taskId);
        }
        // Refund full amount (reward + deposit) to delegator
        (bool success,) = task.delegator.call{value: task.rewardAmount + task.verificationDeposit}("");
        require(success, "AuraWeaver: Failed to refund delegator");

        _updateReputation(task.delegator, -int256(task.rewardAmount / 200)); // Small rep penalty for cancellation

        task.status = TaskStatus.Canceled;
        task.rewardAmount = 0; // Mark funds as withdrawn
        task.verificationDeposit = 0;

        emit TaskCanceled(taskId, msg.sender);
    }


    // --- II. Advanced Features & Utilities ---

    // A. Aura Customization/Evolution

    /**
     * @dev Stakes an Aura NFT for a specified duration. While staked, the Aura
     *      might provide additional benefits (e.g., boosted reputation gain, special yield - conceptual).
     *      A staked Aura cannot be transferred, refined, or merged.
     * @param tokenId The ID of the Aura NFT to stake.
     * @param duration The duration in seconds for which the Aura will be staked.
     */
    function stakeAura(uint256 tokenId, uint256 duration) external whenNotPaused {
        require(_exists(tokenId), "AuraWeaver: Aura does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuraWeaver: Not Aura owner");
        require(duration > 0, "AuraWeaver: Staking duration must be positive");

        Aura storage aura = auras[tokenId];
        require(!aura.staked, "AuraWeaver: Aura is already staked");

        aura.staked = true;
        aura.stakeStartTime = block.timestamp;
        aura.stakeDuration = duration;

        // In a real system, you might transfer the NFT to the contract for locking,
        // or prevent transfer via custom ERC721 logic. For this example, it's marked internally.

        _updateReputation(msg.sender, int256(duration / 1 days)); // Rough rep boost for staking
        emit AuraStaked(tokenId, msg.sender, duration);
    }

    /**
     * @dev Unstakes an Aura NFT after its staking duration has passed.
     * @param tokenId The ID of the Aura NFT to unstake.
     */
    function unstakeAura(uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), "AuraWeaver: Aura does not exist");
        require(ownerOf(tokenId) == msg.sender, "AuraWeaver: Not Aura owner");

        Aura storage aura = auras[tokenId];
        require(aura.staked, "AuraWeaver: Aura is not staked");
        require(block.timestamp >= aura.stakeStartTime + aura.stakeDuration, "AuraWeaver: Staking period not over");

        aura.staked = false;
        aura.stakeStartTime = 0;
        aura.stakeDuration = 0;

        // If NFT was transferred to contract, transfer it back here.

        emit AuraUnstaked(tokenId, msg.sender);
    }

    /**
     * @dev Allows a user to "refine" multiple low-tier Auras into a single higher-tier Aura.
     *      This burns the low-tier Auras and mints a new, more powerful one.
     * @param lowTierAuraIds An array of IDs of the low-tier Auras to burn.
     */
    function refineAura(uint256[] calldata lowTierAuraIds) external whenNotPaused {
        require(lowTierAuraIds.length >= 3, "AuraWeaver: Need at least 3 low-tier Auras to refine");
        uint256 combinedLevel = 0;

        for (uint256 i = 0; i < lowTierAuraIds.length; i++) {
            uint256 tokenId = lowTierAuraIds[i];
            require(_exists(tokenId), "AuraWeaver: Aura does not exist");
            require(ownerOf(tokenId) == msg.sender, "AuraWeaver: Not Aura owner");
            require(!auras[tokenId].staked, "AuraWeaver: Staked Auras cannot be refined");
            // Example: Only level 1 Auras can be refined into something new
            require(auras[tokenId].level == 1, "AuraWeaver: Only level 1 Auras can be refined in this example");
            combinedLevel += auras[tokenId].level;

            _burn(tokenId);
            delete auras[tokenId]; // Clear Aura struct data
        }

        // Mint a new, higher-tier Aura
        _auraIds.increment();
        uint256 newAuraId = _auraIds.current();

        _safeMint(msg.sender, newAuraId);
        _setTokenURI(newAuraId, "initial_refined_uri_placeholder"); // Placeholder URI

        auras[newAuraId] = Aura({
            owner: msg.sender,
            mintTime: block.timestamp,
            lastReputationBoostClaimTime: 0,
            level: combinedLevel / 2, // Example logic for new level
            staked: false,
            stakeStartTime: 0,
            stakeDuration: 0,
            initialMetadataHash: uint256(keccak256(abi.encodePacked("initial_refined_uri_placeholder")))
        });

        _updateReputation(msg.sender, int256(combinedLevel * 50)); // Rep boost for refining
        emit AuraRefined(msg.sender, newAuraId, lowTierAuraIds);
    }

    /**
     * @dev Merges two Auras into one. The target Aura gains power/level from the merged Aura,
     *      and the merged Aura is burned.
     * @param aura1Id The ID of the target Aura (will remain).
     * @param aura2Id The ID of the Aura to be merged (will be burned).
     */
    function mergeAuras(uint256 aura1Id, uint256 aura2Id) external whenNotPaused {
        require(_exists(aura1Id), "AuraWeaver: Aura 1 does not exist");
        require(_exists(aura2Id), "AuraWeaver: Aura 2 does not exist");
        require(aura1Id != aura2Id, "AuraWeaver: Cannot merge an Aura with itself");
        require(ownerOf(aura1Id) == msg.sender, "AuraWeaver: Not owner of Aura 1");
        require(ownerOf(aura2Id) == msg.sender, "AuraWeaver: Not owner of Aura 2");
        require(!auras[aura1Id].staked && !auras[aura2Id].staked, "AuraWeaver: Staked Auras cannot be merged");

        Aura storage aura1 = auras[aura1Id];
        Aura storage aura2 = auras[aura2Id];

        // Example merge logic: Aura1 gains level from Aura2
        aura1.level += aura2.level / 2; // Aura1 gets half of Aura2's level
        aura1.lastReputationBoostClaimTime = block.timestamp; // Reset boost timer

        _burn(aura2Id);
        delete auras[aura2Id]; // Clear Aura struct data

        _updateReputation(msg.sender, int256(aura2.level * 20)); // Rep boost for merging
        emit AuraMerged(msg.sender, aura1Id, aura2Id);
    }


    // B. Dispute Resolution for Tasks

    /**
     * @dev Initiates a dispute if an executor disagrees with the delegator's rejection
     *      of a submitted task result. Requires a challenge bond matching the verification deposit.
     * @param taskId The ID of the task to challenge.
     */
    function challengeTaskVerification(uint256 taskId) external payable whenNotPaused {
        Task storage task = tasks[taskId];
        require(task.id == taskId, "AuraWeaver: Task does not exist");
        require(task.executor == msg.sender, "AuraWeaver: Only executor can challenge");
        require(task.status == TaskStatus.Rejected, "AuraWeaver: Task must be rejected to challenge");
        require(task.disputeId == 0, "AuraWeaver: Task already under dispute");
        require(msg.value == task.verificationDeposit, "AuraWeaver: Must provide matching verification deposit as challenge bond");

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            taskId: taskId,
            challenger: msg.sender,
            delegator: task.delegator,
            challengeBond: msg.value, // The bond sent by the challenger
            startVoteTime: block.timestamp,
            endVoteTime: block.timestamp + disputeVotingPeriod,
            status: DisputeStatus.Voting,
            challengerWon: false // Default
        });

        task.status = TaskStatus.Disputed;
        task.disputeId = newDisputeId;

        emit DisputeChallenged(newDisputeId, taskId, msg.sender);
    }

    /**
     * @dev Allows high-reputation users to vote on an ongoing dispute.
     * @param disputeId The ID of the dispute.
     * @param supportVerification True if the voter supports the delegator's original verification (i.e., executor was wrong).
     *                            False if the voter supports the executor's challenge (i.e., delegator was wrong).
     */
    function voteOnDispute(uint256 disputeId, bool supportVerification) external whenNotPaused onlyReputable(minReputationForVoting) {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.id == disputeId, "AuraWeaver: Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "AuraWeaver: Dispute not in voting phase");
        require(block.timestamp <= dispute.endVoteTime, "AuraWeaver: Voting period has ended");
        require(!hasVotedInDispute[disputeId][msg.sender], "AuraWeaver: Already voted in this dispute");

        uint256 voterRep = reputations[msg.sender];
        
        hasVotedInDispute[disputeId][msg.sender] = true;

        if (supportVerification) {
            disputeVotesFor[disputeId] += voterRep;
        } else {
            disputeVotesAgainst[disputeId] += voterRep;
        }

        _updateReputation(msg.sender, int256(voterRep / 50)); // Small rep boost for voting
        emit DisputeVoteCast(disputeId, msg.sender, supportVerification, voterRep);
    }

    /**
     * @dev Resolves a dispute after the voting period has ended, distributing funds
     *      and adjusting reputations based on the voting outcome.
     * @param disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 disputeId) external whenNotPaused {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.id == disputeId, "AuraWeaver: Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "AuraWeaver: Dispute not in voting phase");
        require(block.timestamp > dispute.endVoteTime, "AuraWeaver: Voting period not yet ended");

        Task storage task = tasks[dispute.taskId];
        require(task.id == dispute.taskId, "AuraWeaver: Associated task does not exist");
        require(task.rewardAmount > 0 || task.verificationDeposit > 0, "AuraWeaver: Task funds already handled");

        bool challengerWins = false;
        if (disputeVotesAgainst[disputeId] > disputeVotesFor[disputeId]) {
            challengerWins = true;
            dispute.status = DisputeStatus.ResolvedChallengerWon;
            dispute.challengerWon = true;

            // Challenger (executor) gets task reward + their challenge bond back
            uint256 rewardToExecutor = task.rewardAmount;
            uint256 fee = rewardToExecutor * protocolFeeBasisPoints / 10000;
            uint256 finalReward = rewardToExecutor - fee;

            (bool successExecutorReward,) = task.executor.call{value: finalReward}("");
            require(successExecutorReward, "AuraWeaver: Failed to send reward to executor after dispute");

            (bool successChallengerBond,) = dispute.challenger.call{value: dispute.challengeBond}("");
            require(successChallengerBond, "AuraWeaver: Failed to return challenger's bond");

            // Delegator loses their original verification deposit as penalty to protocol
            accumulatedProtocolFees += task.verificationDeposit;
            // Protocol also gets the fee from the reward
            accumulatedProtocolFees += fee;

            _updateReputation(task.executor, int256(finalReward / 100)); // Rep boost for winning dispute
            _updateReputation(task.delegator, -int256(task.rewardAmount / 50)); // Rep penalty for losing dispute

        } else { // Delegator wins or tie (original verification upheld)
            dispute.status = DisputeStatus.ResolvedDelegatorWon;
            dispute.challengerWon = false;

            // Delegator gets their original verification deposit back
            (bool successDelegatorDeposit,) = dispute.delegator.call{value: task.verificationDeposit}("");
            require(successDelegatorDeposit, "AuraWeaver: Failed to return delegator's deposit");

            // Delegator also gets the original reward amount back (as executor failed)
            (bool successDelegatorReward,) = dispute.delegator.call{value: task.rewardAmount}("");
            require(successDelegatorReward, "AuraWeaver: Failed to return task reward to delegator");

            // Challenger (executor) loses their challenge bond as penalty to protocol
            accumulatedProtocolFees += dispute.challengeBond;

            _updateReputation(task.executor, -int256(task.rewardAmount / 100)); // Rep penalty for losing dispute
            _updateReputation(task.delegator, int256(task.rewardAmount / 100)); // Rep boost for winning dispute
        }

        // Mark task and dispute funds as handled
        task.rewardAmount = 0;
        task.verificationDeposit = 0;
        task.status = TaskStatus.Resolved; // Task is resolved either way

        emit DisputeResolved(disputeId, dispute.taskId, challengerWins);
    }

    // C. Protocol Parameters & Governance

    /**
     * @dev Sets the protocol fee charged on task rewards (in basis points, 10000 = 100%).
     *      Callable only by the contract owner.
     * @param newFeeBasisPoints The new fee rate in basis points (e.g., 500 for 5%).
     */
    function setProtocolFee(uint256 newFeeBasisPoints) external onlyOwner whenNotPaused {
        require(newFeeBasisPoints <= 1000, "AuraWeaver: Fee cannot exceed 10%"); // Max 10%
        protocolFeeBasisPoints = newFeeBasisPoints;
        emit ProtocolFeeSet(newFeeBasisPoints);
    }

    /**
     * @dev Sets the multiplier for reputation gains and losses.
     *      Callable only by the contract owner.
     * @param newMultiplier The new multiplier (e.g., 100 for 1x, 200 for 2x).
     */
    function setReputationMultiplier(uint256 newMultiplier) external onlyOwner whenNotPaused {
        require(newMultiplier > 0, "AuraWeaver: Multiplier must be positive");
        reputationMultiplier = newMultiplier;
        emit ReputationMultiplierSet(newMultiplier);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) external onlyOwner whenNotPaused {
        require(recipient != address(0), "AuraWeaver: Invalid recipient");
        require(accumulatedProtocolFees > 0, "AuraWeaver: No fees to withdraw");

        uint256 amount = accumulatedProtocolFees;
        accumulatedProtocolFees = 0;

        (bool success,) = recipient.call{value: amount}("");
        require(success, "AuraWeaver: Failed to withdraw fees");

        emit ProtocolFeesWithdrawn(recipient, amount);
    }

    /**
     * @dev Pauses the contract, halting sensitive operations in case of emergencies.
     *      Callable only by the contract owner.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming normal operations.
     *      Callable only by the contract owner.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // D. Query Functions

    /**
     * @dev Retrieves full details of a specific task.
     * @param taskId The ID of the task.
     * @return A struct containing the task's details.
     */
    function getTaskDetails(uint256 taskId) public view returns (Task memory) {
        require(tasks[taskId].id == taskId, "AuraWeaver: Task does not exist");
        return tasks[taskId];
    }

    /**
     * @dev Returns an array of IDs for tasks that are currently open for claiming.
     * @return An array of open task IDs.
     */
    function getOpenTasks() public view returns (uint256[] memory) {
        return openTaskIds;
    }

    /**
     * @dev Retrieves details of an ongoing or resolved dispute.
     * @param disputeId The ID of the dispute.
     * @return A struct containing the dispute's details.
     */
    function getDisputeDetails(uint256 disputeId) public view returns (Dispute memory) {
        require(disputes[disputeId].id == disputeId, "AuraWeaver: Dispute does not exist");
        return disputes[disputeId];
    }
}
```