Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts, focusing on a dynamic reputation-backed treasury and governance system.

It aims to be non-duplicative by combining features often found in separate contracts:
1.  **Dynamic, Decaying Reputation:** Reputation isn't fixed but decreases over time, incentivizing continuous engagement.
2.  **Reputation-Weighted Governance:** Voting power is directly tied to current reputation, including decay effects.
3.  **Active Treasury Management:** Governance controls execution of pre-defined or proposed external investment/yield strategies using treasury assets.
4.  **Tiered Access/Benefits:** Reputation unlocks different levels of interaction and privileges.
5.  **Puggable Strategies:** Investment strategies are defined as generic calls (`target`, `data`), allowing interaction with arbitrary DeFi protocols approved via governance.

It includes over 20 functions as requested.

---

**Outline and Function Summary**

**Contract Name:** `AdaptiveReputationTreasury`

**Core Concepts:**
*   Manages a treasury of various ERC20 tokens.
*   Tracks user reputation, which decays over time.
*   Reputation determines voting power in governance proposals.
*   Governance controls treasury operations (withdrawals, strategy execution) and contract parameters.
*   Reputation tiers unlock specific contract functionalities.

**State Variables:**
*   `owner`: Contract owner.
*   `paused`: Pausability state.
*   `tokenBalances`: Mapping of token addresses to treasury balances.
*   `userReputation`: Mapping of user addresses to their current reputation points.
*   `lastReputationUpdateTime`: Timestamp of the last reputation update or decay check for each user.
*   `reputationDecayRatePerSecond`: Rate at which reputation decays.
*   `reputationTierThresholds`: Thresholds for different reputation tiers.
*   `nextProposalId`: Counter for proposals.
*   `proposals`: Mapping of proposal IDs to `Proposal` structs.
*   `votes`: Mapping of proposal ID -> voter address -> vote (bool support, uint256 reputation at vote).
*   `votingPeriodDuration`: Duration proposals are open for voting.
*   `proposalQuorumRequired`: Minimum percentage of total *decayed* reputation needed for a proposal to pass.
*   `proposalReputationCost`: Reputation required to create a proposal.
*   `strategyBlueprints`: Mapping of strategy IDs to `InvestmentStrategy` structs.
*   `nextStrategyId`: Counter for strategy blueprints.

**Enums:**
*   `ProposalState`: Possible states for a proposal (Pending, Active, Passed, Failed, Executed, Canceled).

**Structs:**
*   `Proposal`: Details about a governance proposal (proposer, description, target, callData, creation time, state, vote counts, total reputation at vote).
*   `InvestmentStrategy`: Blueprint for an external interaction (name, description, target contract, calldata template).

**Events:**
*   `ReputationGained`: User gained reputation.
*   `ReputationLost`: User lost reputation.
*   `ReputationDecayed`: User's reputation decayed.
*   `TierChanged`: User moved to a different reputation tier.
*   `TokenDeposited`: Tokens deposited into the treasury.
*   `TokenWithdrawn`: Tokens withdrawn from the treasury.
*   `ProposalCreated`: A new governance proposal was created.
*   `Voted`: A user voted on a proposal.
*   `ProposalStateChanged`: A proposal's state was updated.
*   `StrategyBlueprintDefined`: A new investment strategy blueprint was defined.
*   `StrategyBlueprintRemoved`: An investment strategy blueprint was removed.
*   `StrategyExecuted`: An investment strategy was executed.

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `whenNotPaused`: Prevents execution when paused.
*   `whenPaused`: Allows execution only when paused.
*   `hasRequiredReputation(uint256 requiredRep)`: Checks if the caller has enough reputation after decay.

**Functions Summary (Grouped by Concept):**

*   **Reputation Management:**
    1.  `_updateReputation(address user)`: Internal helper to apply decay and update last decay timestamp.
    2.  `getUserReputation(address user)`: Public view to get a user's *current* decayed reputation.
    3.  `getReputationTier(address user)`: Public view to get a user's current reputation tier.
    4.  `earnReputation(address user, uint256 amount)`: Governance/Admin adds reputation to a user.
    5.  `loseReputation(address user, uint256 amount)`: Governance/Admin removes reputation from a user.
    6.  `penalizeUser(address user, uint256 penaltyAmount)`: Governance/Admin removes reputation and potentially triggers other penalties (example placeholder).
    7.  `setReputationDecayParams(uint256 ratePerSecond)`: Governance sets the reputation decay rate.
    8.  `setReputationTierThresholds(uint256[] memory thresholds)`: Governance sets the thresholds for different tiers.

*   **Treasury Management:**
    9.  `depositToken(address tokenAddress, uint256 amount)`: Allows anyone to deposit tokens into the treasury.
    10. `getTreasuryBalance(address tokenAddress)`: Public view to get the treasury's balance of a specific token.
    11. `withdrawToken(address tokenAddress, uint256 amount, address recipient)`: Governed withdrawal of tokens.
    12. `defineInvestmentStrategy(string memory name, string memory description, address targetContract, bytes memory callDataTemplate)`: Governance defines a blueprint for an external interaction (e.g., depositing into a yield farm).
    13. `removeInvestmentStrategy(uint256 strategyId)`: Governance removes a strategy blueprint.
    14. `executeInvestmentStrategy(uint256 strategyId, bytes memory executionData)`: Governed execution of a defined strategy blueprint, substituting `executionData` into the template (advanced concept: requires careful data handling).

*   **Governance:**
    15. `createProposal(string memory description, address targetContract, bytes memory callData)`: Users with sufficient reputation can create a governance proposal.
    16. `voteOnProposal(uint256 proposalId, bool support)`: Users vote on a proposal; their voting power is their reputation *at the time of voting*.
    17. `calculateProposalState(uint256 proposalId)`: Helper view to determine the *current* state of a proposal based on time and votes.
    18. `getProposalState(uint256 proposalId)`: Public view to get a proposal's state (internally calls `calculateProposalState`).
    19. `executeProposal(uint256 proposalId)`: Anyone can trigger execution of a proposal that has passed.
    20. `cancelProposal(uint256 proposalId)`: Governance or proposer cancels a proposal.
    21. `setVotingParams(uint256 period, uint256 quorum)`: Governance sets voting period and quorum.
    22. `setProposalReputationCost(uint256 cost)`: Governance sets the reputation required to create proposals.

*   **Utility/Access:**
    23. `pauseContract()`: Owner/Governance pauses contract.
    24. `unpauseContract()`: Owner/Governance unpauses contract.
    25. `transferOwnership(address newOwner)`: Owner transfers ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Outline and Function Summary Above Code ---

/**
 * @title AdaptiveReputationTreasury
 * @dev A smart contract managing a treasury, user reputation, and governance.
 * Reputation decays over time and dictates voting power and access tiers.
 * Governance proposals control treasury operations and contract parameters,
 * including executing external investment strategies.
 */
contract AdaptiveReputationTreasury is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---
    // Treasury
    mapping(address => uint256) public tokenBalances; // Token address => balance in treasury

    // Reputation System
    mapping(address => uint256) private userReputation; // User address => current reputation points
    mapping(address => uint48) private lastReputationUpdateTime; // User address => timestamp of last update/decay check
    uint256 public reputationDecayRatePerSecond; // Rate of reputation decay per second (e.g., 1e18 for 1 point/sec, adjust based on scale)
    uint256[] public reputationTierThresholds; // Sorted list of reputation thresholds for tiers

    // Governance System
    enum ProposalState { Pending, Active, Passed, Failed, Executed, Canceled }

    struct Proposal {
        address proposer;
        string description;
        address targetContract; // The contract to call if the proposal passes
        bytes callData;         // The data to send with the call
        uint48 creationTimestamp; // Timestamp when the proposal was created
        ProposalState state;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        uint256 totalReputationAtVoteStart; // Sum of reputation of all voters at the start of proposal
        // Note: Quorum check requires total reputation *at the time of checking*
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) private hasVoted; // Proposal ID => voter address => voted?
    mapping(uint256 => mapping(address => uint256)) private userVoteReputation; // Proposal ID => voter address => reputation at time of vote

    uint256 public nextProposalId;
    uint256 public votingPeriodDuration = 3 days; // Default voting period
    uint256 public proposalQuorumRequired = 20; // % of total decayed reputation needed for 'for' votes
    uint256 public proposalReputationCost = 100; // Reputation required to create a proposal

    // Investment Strategy Blueprints (defined by governance)
    struct InvestmentStrategy {
        string name;
        string description;
        address targetContract;
        bytes callDataTemplate; // Bytes data with placeholders for execution-specific values (e.g., amounts)
        bool active; // Can this blueprint be executed?
    }

    mapping(uint256 => InvestmentStrategy) public strategyBlueprints;
    uint256 public nextStrategyId;

    // --- Events ---
    event ReputationGained(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationLost(address indexed user, uint256 amount, uint256 newReputation);
    event ReputationDecayed(address indexed user, uint256 decayedAmount, uint256 newReputation);
    event TierChanged(address indexed user, uint256 oldTier, uint256 newTier);

    event TokenDeposited(address indexed token, uint256 amount, address indexed depositor);
    event TokenWithdrawn(address indexed token, uint256 amount, address indexed recipient);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event StrategyBlueprintDefined(uint256 indexed strategyId, string name, address targetContract);
    event StrategyBlueprintRemoved(uint256 indexed strategyId);
    event StrategyExecuted(uint256 indexed strategyId, uint256 indexed proposalId, address targetContract);

    // --- Modifiers ---
    /**
     * @dev Checks if the caller has the required reputation after applying decay.
     */
    modifier hasRequiredReputation(uint256 requiredRep) {
        require(getUserReputation(_msgSender()) >= requiredRep, "ART: Insufficient reputation");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialDecayRatePerSecond) Ownable(_msgSender()) Pausable() {
        reputationDecayRatePerSecond = initialDecayRatePerSecond;
        // Default tiers: [0] for Tier 0 (none), [100] for Tier 1, [500] for Tier 2...
        // These should ideally be set by governance later.
        reputationTierThresholds = [0, 100, 500, 1000]; // Example tiers
    }

    // --- Internal Helpers ---

    /**
     * @dev Applies reputation decay for a user since the last update time.
     * Updates the user's reputation and the last update timestamp.
     * @param user The user address.
     */
    function _updateReputation(address user) internal {
        uint48 currentTime = uint48(block.timestamp);
        uint48 lastUpdateTime = lastReputationUpdateTime[user];

        if (lastUpdateTime == 0) {
             // First interaction or no updates yet, set initial time but no decay
             lastReputationUpdateTime[user] = currentTime;
             return;
        }

        if (currentTime > lastUpdateTime) {
            uint256 elapsedTime = currentTime - lastUpdateTime;
            uint256 currentReputation = userReputation[user];

            // Calculate decay amount
            // Decay is reputationDecayRatePerSecond * elapsedTime
            uint256 decayAmount = elapsedTime * reputationDecayRatePerSecond;

            if (decayAmount > 0) {
                uint256 newReputation = currentReputation > decayAmount ? currentReputation - decayAmount : 0;
                userReputation[user] = newReputation;
                emit ReputationDecayed(user, currentReputation - newReputation, newReputation);

                // Check and emit TierChanged event if necessary
                uint256 oldTier = getReputationTier(user); // This uses the old reputation *before* decay
                uint256 newTier = _calculateTier(newReputation);
                 if (oldTier != newTier) {
                    emit TierChanged(user, oldTier, newTier);
                 }
            }

            lastReputationUpdateTime[user] = currentTime; // Update timestamp AFTER decay calculation
        }
    }

    /**
     * @dev Calculates the current tier for a given reputation score.
     * Assumes reputationTierThresholds is sorted ascendingly.
     * @param reputation The reputation score.
     * @return The tier index (0-based).
     */
    function _calculateTier(uint256 reputation) internal view returns (uint256) {
        uint256 currentTier = 0;
        for (uint256 i = 0; i < reputationTierThresholds.length; i++) {
            if (reputation >= reputationTierThresholds[i]) {
                currentTier = i;
            } else {
                // Thresholds are sorted, so we found the tier
                break;
            }
        }
        return currentTier;
    }


    // --- Reputation Management ---

    /**
     * @dev Gets the current reputation of a user after applying decay.
     * Calling this function updates the user's last update time.
     * @param user The user address.
     * @return The user's current reputation.
     */
    function getUserReputation(address user) public whenNotPaused returns (uint256) {
        _updateReputation(user); // Apply decay before returning
        return userReputation[user];
    }

    /**
     * @dev Gets the current reputation tier of a user based on their decayed reputation.
     * @param user The user address.
     * @return The user's current tier index.
     */
    function getReputationTier(address user) public whenNotPaused view returns (uint256) {
        // Note: This view function does NOT trigger _updateReputation to save gas.
        // The tier returned is based on the reputation value as it currently stands in storage,
        // which might be slightly outdated until getUserReputation or another update function is called.
        // For accurate tier based on live reputation, call getUserReputation first then getTier.
         return _calculateTier(userReputation[user]);
    }

    /**
     * @dev Grants reputation to a user. Callable only by the owner or governance (via proposal).
     * Applying reputation also updates the user's last update time.
     * @param user The user address to grant reputation to.
     * @param amount The amount of reputation to grant.
     */
    function earnReputation(address user, uint256 amount) public onlyOwner whenNotPaused {
        require(amount > 0, "ART: Amount must be positive");
        _updateReputation(user); // Apply potential decay before adding
        uint256 oldRep = userReputation[user];
        uint256 newRep = oldRep + amount;
        userReputation[user] = newRep;
        lastReputationUpdateTime[user] = uint48(block.timestamp); // Update timestamp after gaining
        emit ReputationGained(user, amount, newRep);

        uint256 oldTier = _calculateTier(oldRep); // Tier before gaining
        uint256 newTier = _calculateTier(newRep); // Tier after gaining
        if (oldTier != newTier) {
            emit TierChanged(user, oldTier, newTier);
        }
    }

    /**
     * @dev Removes reputation from a user. Callable only by the owner or governance (via proposal).
     * Applying reputation loss also updates the user's last update time.
     * @param user The user address to remove reputation from.
     * @param amount The amount of reputation to remove.
     */
    function loseReputation(address user, uint256 amount) public onlyOwner whenNotPaused {
         require(amount > 0, "ART: Amount must be positive");
        _updateReputation(user); // Apply potential decay before removing
        uint256 oldRep = userReputation[user];
        uint256 newRep = oldRep > amount ? oldRep - amount : 0;
        userReputation[user] = newRep;
        lastReputationUpdateTime[user] = uint48(block.timestamp); // Update timestamp after losing
        emit ReputationLost(user, amount, newRep);

        uint256 oldTier = _calculateTier(oldRep); // Tier before losing
        uint256 newTier = _calculateTier(newRep); // Tier after losing
         if (oldTier != newTier) {
            emit TierChanged(user, oldTier, newTier);
        }
    }

    /**
     * @dev Function to penalize a user, reducing their reputation.
     * This can be extended to include other penalties like temporary voting lock.
     * Callable only by the owner or governance (via proposal).
     * @param user The user to penalize.
     * @param penaltyAmount The amount of reputation to remove as penalty.
     */
    function penalizeUser(address user, uint256 penaltyAmount) public onlyOwner whenNotPaused {
        // This function is essentially a specialized `loseReputation` with semantic difference.
        // Could add more logic here, e.g., freezing voting rights.
        loseReputation(user, penaltyAmount);
        // Example: You could add a mapping here: user -> penalty end timestamp
        // mapping(address => uint48) public penaltyEnds;
        // penaltyEnds[user] = uint48(block.timestamp) + 1 days; // Example penalty: 1 day
    }

    /**
     * @dev Allows governance to set the reputation decay rate per second.
     * Callable only by the owner or governance (via proposal).
     * @param ratePerSecond The new decay rate per second.
     */
    function setReputationDecayParams(uint256 ratePerSecond) public onlyOwner whenNotPaused {
        reputationDecayRatePerSecond = ratePerSecond;
    }

     /**
     * @dev Allows governance to set the reputation tier thresholds.
     * The input array must be sorted ascendingly. Tier 0 is below the first threshold.
     * Callable only by the owner or governance (via proposal).
     * @param thresholds An array of reputation thresholds.
     */
    function setReputationTierThresholds(uint256[] memory thresholds) public onlyOwner whenNotPaused {
        // Basic check: array must be sorted
        for(uint256 i = 0; i < thresholds.length - 1; i++) {
            require(thresholds[i] <= thresholds[i+1], "ART: Thresholds must be sorted ascendingly");
        }
        reputationTierThresholds = thresholds;
        // Note: Existing users' tiers change automatically upon next reputation update/check
        // This doesn't trigger individual TierChanged events for every user immediately.
    }


    // --- Treasury Management ---

    /**
     * @dev Allows anyone to deposit tokens into the treasury.
     * The contract must be approved to spend the tokens by the depositor.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount to deposit.
     */
    function depositToken(address tokenAddress, uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "ART: Amount must be positive");
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        require(token.transferFrom(_msgSender(), address(this), amount), "ART: Transfer failed");
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 receivedAmount = balanceAfter - balanceBefore; // Account for potential transfer fees

        tokenBalances[tokenAddress] += receivedAmount;
        emit TokenDeposited(tokenAddress, receivedAmount, _msgSender());
    }

    /**
     * @dev Gets the current balance of a specific token held in the treasury.
     * @param tokenAddress The address of the ERC20 token.
     * @return The balance of the token in the treasury.
     */
    function getTreasuryBalance(address tokenAddress) public view returns (uint256) {
        // Returns the internally tracked balance.
        // For the actual token balance on chain, use IERC20(tokenAddress).balanceOf(address(this)).
        // The internal balance should match the external one if deposits/withdrawals are handled correctly.
        return tokenBalances[tokenAddress];
    }

    /**
     * @dev Withdraws tokens from the treasury. Callable only by the owner or governance (via proposal).
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount to withdraw.
     * @param recipient The recipient address.
     */
    function withdrawToken(address tokenAddress, uint256 amount, address recipient) public onlyOwner whenNotPaused nonReentrant {
        require(amount > 0, "ART: Amount must be positive");
        require(tokenBalances[tokenAddress] >= amount, "ART: Insufficient balance in treasury");
        require(recipient != address(0), "ART: Invalid recipient address");

        tokenBalances[tokenAddress] -= amount;
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(recipient, amount), "ART: Withdrawal failed");

        emit TokenWithdrawn(tokenAddress, amount, recipient);
    }

    /**
     * @dev Allows governance to define a blueprint for an investment/yield strategy.
     * This does NOT execute the strategy, just stores its parameters.
     * Callable only by the owner or governance (via proposal).
     * The callDataTemplate should be the ABI-encoded call data for the targetContract,
     * potentially with placeholders that will be replaced by executeInvestmentStrategy.
     * (Note: Placeholder replacement logic is advanced and omitted for simplicity in this example,
     * assuming callDataTemplate is the full, ready-to-execute data or requires fixed data).
     * @param name A descriptive name for the strategy.
     * @param description A description of what the strategy does.
     * @param targetContract The address of the contract to interact with (e.g., DEX, yield farm).
     * @param callDataTemplate ABI-encoded call data for the targetContract.
     * @return The ID of the newly defined strategy blueprint.
     */
    function defineInvestmentStrategy(
        string memory name,
        string memory description,
        address targetContract,
        bytes memory callDataTemplate
    ) public onlyOwner whenNotPaused returns (uint256) {
        require(targetContract != address(0), "ART: Invalid target contract address");

        uint256 strategyId = nextStrategyId++;
        strategyBlueprints[strategyId] = InvestmentStrategy({
            name: name,
            description: description,
            targetContract: targetContract,
            callDataTemplate: callDataTemplate,
            active: true // Newly defined strategies are active by default
        });

        emit StrategyBlueprintDefined(strategyId, name, targetContract);
        return strategyId;
    }

     /**
     * @dev Allows governance to remove (deactivate) an investment strategy blueprint.
     * Callable only by the owner or governance (via proposal).
     * @param strategyId The ID of the strategy blueprint to remove.
     */
    function removeInvestmentStrategy(uint256 strategyId) public onlyOwner whenNotPaused {
        require(strategyBlueprints[strategyId].targetContract != address(0), "ART: Strategy blueprint not found"); // Check existence
        strategyBlueprints[strategyId].active = false; // Deactivate instead of deleting

        emit StrategyBlueprintRemoved(strategyId);
    }


    /**
     * @dev Executes a previously defined investment strategy blueprint.
     * Callable only by the owner or governance (via proposal).
     * Note: `executionData` could be used to fill in dynamic parts of the template,
     * but here it's simplified to just be the data passed directly if template is static.
     * A more complex implementation would involve replacing placeholders in `callDataTemplate`.
     * @param strategyId The ID of the strategy blueprint to execute.
     * @param executionData The specific data to use for this execution (e.g., amount, path).
     * This data is simply appended to or replaces the template depending on the strategy's design.
     * For this simplified example, we assume `executionData` IS the full callData.
     */
    function executeInvestmentStrategy(uint256 strategyId, bytes memory executionData) public onlyOwner whenNotPaused nonReentrant {
         InvestmentStrategy storage strategy = strategyBlueprints[strategyId];
         require(strategy.targetContract != address(0) && strategy.active, "ART: Strategy blueprint not found or inactive");
         require(executionData.length > 0, "ART: Execution data must be provided");

        // Execute the low-level call to the target contract
        (bool success, bytes memory returnData) = strategy.targetContract.call(executionData);
        // Note: Handling returnData and success/failure might be critical depending on the strategy
        require(success, string(abi.decode(returnData, (string)))); // Revert with target contract's error message

        emit StrategyExecuted(strategyId, 0, strategy.targetContract); // Link to proposal ID? Would require getting proposal ID from context (complex)
        // Let's assume this is called *from* an executed proposal, so we could pass proposalId if needed.
        // For now, emitting 0 as proposal ID if called directly by owner/governance.
    }

    // --- Governance ---

    /**
     * @dev Allows users with sufficient reputation to create a governance proposal.
     * The proposal targets a contract and contains the data for a function call.
     * Reputation cost is deducted upon proposal creation.
     * @param description A brief description of the proposal.
     * @param targetContract The address of the contract the proposal calls.
     * @param callData The ABI-encoded data for the function call.
     * @return The ID of the newly created proposal.
     */
    function createProposal(
        string memory description,
        address targetContract,
        bytes memory callData
    ) public hasRequiredReputation(proposalReputationCost) whenNotPaused returns (uint256) {
        require(targetContract != address(0), "ART: Invalid target contract");

        uint256 currentReputation = getUserReputation(_msgSender()); // Get decayed reputation
        require(currentReputation >= proposalReputationCost, "ART: Insufficient reputation to create proposal");

        // Deduct reputation cost
        // Note: Using loseReputation internally handles decay update and tier change emission
        loseReputation(_msgSender(), proposalReputationCost);

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: _msgSender(),
            description: description,
            targetContract: targetContract,
            callData: callData,
            creationTimestamp: uint48(block.timestamp),
            state: ProposalState.Active,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            totalReputationAtVoteStart: 0 // Will sum reputation as votes come in
        });

        emit ProposalCreated(proposalId, _msgSender(), description);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
        return proposalId;
    }

    /**
     * @dev Allows users with reputation to vote on an active proposal.
     * Voting power is based on the user's reputation *at the time of voting*.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for a 'for' vote, false for an 'against' vote.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "ART: Proposal not active");
        require(!hasVoted[proposalId][_msgSender()], "ART: Already voted on this proposal");
        require(block.timestamp <= proposal.creationTimestamp + votingPeriodDuration, "ART: Voting period has ended");

        uint256 voterReputation = getUserReputation(_msgSender()); // Get user's current decayed reputation
        require(voterReputation > 0, "ART: Voter must have reputation");

        hasVoted[proposalId][_msgSender()] = true;
        userVoteReputation[proposalId][_msgSender()] = voterReputation;
        proposal.totalReputationAtVoteStart += voterReputation; // Sum reputation of all voters

        if (support) {
            proposal.totalVotesFor += voterReputation;
        } else {
            proposal.totalVotesAgainst += voterReputation;
        }

        emit Voted(proposalId, _msgSender(), support, voterReputation);
    }

    /**
     * @dev Calculates the current state of a proposal.
     * Takes into account the voting period and quorum requirements.
     * This is a view function and does not change state, except potentially
     * updating the proposal's state in the mapping if called via `getProposalState`.
     * @param proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function calculateProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId]; // Use storage for potential state update later
        if (proposal.state != ProposalState.Active) {
            return proposal.state;
        }

        if (block.timestamp <= proposal.creationTimestamp + votingPeriodDuration) {
            return ProposalState.Active;
        } else {
            // Voting period has ended, determine if passed or failed
            // Calculate total *current* decayed reputation across ALL users for quorum check
            // NOTE: Calculating total decayed reputation of ALL users ON-CHAIN is GAS PROHIBITIVE.
            // A common workaround is to use an external Oracle/Keeper to provide this value,
            // or use a different quorum mechanism (e.g., percentage of *participating* reputation,
            // or use a separate reputation token where total supply is trackable).
            // For this example, we will use total *participating* reputation for the quorum check
            // as a simplification to keep it purely on-chain, acknowledging this is a deviation
            // from a true "percentage of total network power" quorum.
            // A more robust system would require off-chain data or a different token model.

            uint256 totalParticipatingReputation = proposal.totalVotesFor + proposal.totalVotesAgainst;

            if (totalParticipatingReputation == 0) {
                // No votes, fails by default
                return ProposalState.Failed;
            }

            // Check quorum: 'for' votes must be >= quorum % of total participating reputation
             if (proposal.totalVotesFor * 100 >= totalParticipatingReputation * proposalQuorumRequired) {
                // Check majority: 'for' votes must be strictly greater than 'against' votes
                 if (proposal.totalVotesFor > proposal.totalVotesAgainst) {
                    return ProposalState.Passed;
                } else {
                    return ProposalState.Failed;
                }
            } else {
                 return ProposalState.Failed;
            }
        }
    }

    /**
     * @dev Gets the state of a proposal, potentially updating it if the voting period ended.
     * @param proposalId The ID of the proposal.
     * @return The current state of the proposal.
     */
    function getProposalState(uint256 proposalId) public whenNotPaused returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        ProposalState currentState = calculateProposalState(proposalId);

        // Update the stored state if it changed from Active
        if (proposal.state == ProposalState.Active && currentState != ProposalState.Active) {
             proposal.state = currentState;
             emit ProposalStateChanged(proposalId, currentState);
        }
        return proposal.state;
    }


    /**
     * @dev Executes a proposal that has passed. Anyone can trigger execution.
     * The target contract's function will be called with the proposal's calldata.
     * Requires nonReentrant guard as it performs an external call.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        // Check if the state is 'Passed' - calling getProposalState ensures state is updated
        require(getProposalState(proposalId) == ProposalState.Passed, "ART: Proposal not in Passed state");
        require(proposal.state != ProposalState.Executed, "ART: Proposal already executed"); // Redundant check but safe

        // Execute the proposed call
        // Low-level call allows interacting with any contract/function
        (bool success, ) = proposal.targetContract.call(proposal.callData);

        // Update proposal state based on execution success
        if (success) {
            proposal.state = ProposalState.Executed;
            emit ProposalStateChanged(proposalId, ProposalState.Executed);
        } else {
            // Execution failed, mark as failed? Or keep 'Passed' but log failure?
            // Let's mark as Failed state after execution attempt.
            proposal.state = ProposalState.Failed; // Re-use Failed state for execution failure
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
             // Note: It might be useful to include error details from the call, requires more complex handling.
             // For now, if the call reverts, this transaction reverts.
        }
        require(success, "ART: Proposal execution failed");
    }

    /**
     * @dev Allows the proposer or governance to cancel a pending or active proposal.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "ART: Proposal not cancellable");
        require(_msgSender() == proposal.proposer || _msgSender() == owner(), "ART: Only proposer or owner can cancel");

        proposal.state = ProposalState.Canceled;
        emit ProposalStateChanged(proposalId, ProposalState.Canceled);
        // Note: Reputation cost is NOT refunded in this example. Could be added if desired.
    }

    /**
     * @dev Allows governance to set the voting parameters (period and quorum).
     * Callable only by the owner or governance (via proposal).
     * @param period The new voting period duration in seconds.
     * @param quorum The new quorum percentage (0-100).
     */
    function setVotingParams(uint256 period, uint256 quorum) public onlyOwner whenNotPaused {
        require(period > 0, "ART: Voting period must be positive");
        require(quorum <= 100, "ART: Quorum cannot exceed 100%");
        votingPeriodDuration = period;
        proposalQuorumRequired = quorum;
    }

    /**
     * @dev Allows governance to set the reputation cost for creating a proposal.
     * Callable only by the owner or governance (via proposal).
     * @param cost The new reputation cost.
     */
    function setProposalReputationCost(uint256 cost) public onlyOwner whenNotPaused {
        proposalReputationCost = cost;
    }


    // --- Utility / Access ---

    /**
     * @dev Pauses the contract execution. Callable only by the owner or governance (via proposal).
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract execution. Callable only by the owner or governance (via proposal).
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
    }

    // Ownership transfer inherited from Ownable

}
```