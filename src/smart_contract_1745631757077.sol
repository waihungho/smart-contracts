Okay, let's design a smart contract concept centered around a novel token mechanism I'll call "Quantum Entanglement Pairs". This isn't a standard DeFi or NFT pattern. It involves users locking tokens into pairs that have a state ("coherence") which decays over time and is affected by interactions, influencing the outcome when the pair is "measured".

Here's the concept and the contract outline:

**Concept: Quantum Entangled ERC20 (QE20)**

This contract implements a standard ERC20 token with added functionality for creating and managing "Quantum Entanglement Pairs". Users can lock a certain amount of tokens (`amountA` and `amountB`) from their balance into a pair. This pair exists within the contract, owned by the user, and has a "coherence" level, initially high.

*   **Coherence:** A value representing the linkage between `amountA` and `amountB`. It naturally decays over time.
*   **Interactions:** Performing certain actions on the pair (like attempting to withdraw from `amountA`) reduces coherence and triggers a linked effect on `amountB` proportional to the current coherence.
*   **Boosting:** Users can stake additional tokens to "boost" the coherence of a pair.
*   **Measurement:** At any point, a user can "measure" a pair. This is a final action that collapses the state. The amount of `amountB` that is successfully unlocked (along with `amountA`) is directly proportional to the pair's coherence *at the time of measurement*. Low coherence means most of `amountB` is lost.
*   **Decoherence:** If coherence hits zero, a specific (likely unfavorable) decoherence outcome is triggered.

This creates a dynamic system where users manage pairs, balancing interaction frequency (which causes decoherence) against decay (which also causes decoherence) and the cost of boosting, aiming to measure the pair at an optimal coherence level.

---

**Smart Contract Outline: QuantumEntangledERC20.sol**

1.  **License and Pragma**
2.  **Imports:** Basic ERC20 implementation (manual to avoid direct open-source *file* duplication). Pausable mechanism. Ownable (for admin functions).
3.  **State Variables:**
    *   ERC20 core variables (`_balances`, `_totalSupply`, `_name`, `_symbol`, `_decimals`, `_allowances`).
    *   Entanglement Pair struct (`owner`, `amountA`, `amountB`, `coherence`, `creationTimestamp`, `lastCoherenceUpdate`, `isMeasured`, `isClaimed`).
    *   Mappings: `pairs(uint256 => EntangledPair)`, `userPairs(address => uint256[])`.
    *   Counters: `nextPairId`.
    *   Parameters: `coherenceDecayRatePerSecond`, `maxCoherence`, `measurementOutcomeFactor`, `boostAmountRequired`.
    *   Total staked amount in pairs: `totalStakedEntangled`.
4.  **Events:** `PairCreated`, `CoherenceDecayed`, `CoherenceBoosted`, `PrimaryInteracted`, `PairMeasured`, `OutcomeClaimed`, `DecoherenceTriggered`, `PairOwnershipTransferred`, `PairSplit`, `PairsMerged`.
5.  **Modifiers:** `onlyPairOwner`, `whenPairNotMeasured`, `whenPairMeasured`, `whenNotClaimed`.
6.  **ERC20 Core Functions (Basic Implementation):**
    *   `constructor`
    *   `name`
    *   `symbol`
    *   `decimals`
    *   `totalSupply`
    *   `balanceOf`
    *   `transfer`
    *   `approve`
    *   `allowance`
    *   `transferFrom`
    *   `_transfer` (internal)
    *   `_mint` (internal)
    *   `_burn` (internal)
7.  **Pausable Functionality (Inherited/Implemented):**
    *   `pause` (onlyOwner)
    *   `unpause` (onlyOwner)
8.  **Entanglement Core Functions:**
    *   `stakeEntangledPair(uint256 amountA, uint256 amountB)`: Creates a new entangled pair.
    *   `attemptWithdrawPrimary(uint256 pairId, uint256 withdrawAmount)`: Attempts to withdraw from amountA, triggers secondary effect, reduces coherence.
    *   `boostCoherence(uint256 pairId)`: Stakes required amount to increase coherence.
    *   `measurePair(uint256 pairId)`: Collapses state, calculates outcome.
    *   `claimMeasurementOutcome(uint256 pairId)`: Claims calculated outcome tokens.
    *   `emergencyWithdraw(uint256 pairId)`: Withdraws early with penalty.
    *   `splitPair(uint256 pairId, uint256 newAmountA1, uint256 newAmountB1)`: Splits a pair into two.
    *   `mergePairs(uint256 pairId1, uint256 pairId2)`: Merges two pairs into one.
    *   `observePair(uint256 pairId)`: Passive interaction causing minimal decay.
    *   `transferPairOwnership(uint256 pairId, address newOwner)`: Transfers pair ownership.
    *   `triggerDecoherenceOutcome(uint256 pairId)`: Triggers outcome if coherence is near zero.
    *   `_updateCoherence(uint256 pairId)`: Internal function to apply time-based decay.
9.  **Query/View Functions:**
    *   `getPairState(uint256 pairId)`: Returns full state of a pair.
    *   `listUserPairs(address user)`: Returns array of pair IDs for a user.
    *   `getPairCount()`: Total number of pairs created.
    *   `getPairOwner(uint256 pairId)`: Owner of a pair.
    *   `getPairAmounts(uint256 pairId)`: Returns amountA and amountB.
    *   `getPairCoherence(uint256 pairId)`: Returns current coherence (after decay update).
    *   `predictMeasurementOutcome(uint256 pairId)`: Predicts outcome based on current state.
    *   `isPairEntangled(uint256 pairId)`: Checks if pair exists and is not measured.
    *   `getTotalStakedEntangled()`: Returns total tokens in all pairs.
    *   `getUserTotalStakedEntangled(address user)`: Returns total tokens in user's pairs.
    *   `getCoherenceDecayRate()`: Returns decay rate.
    *   `getMeasurementOutcomeFactor()`: Returns outcome factor.
    *   `getBoostAmountRequired()`: Returns boost cost.
    *   `isPaused()`: Returns pause state.
10. **Admin Functions (onlyOwner):**
    *   `setCoherenceDecayRate(uint256 rate)`
    *   `setMeasurementOutcomeFactor(uint256 factor)`
    *   `setBoostAmountRequired(uint256 amount)`
    *   `recoverStuckTokens(address tokenAddress, uint256 amount)`: To recover accidentally sent tokens (excluding self).

---

**Function Summary:**

1.  `constructor(string name, string symbol, uint8 decimals, uint256 initialSupply)`: Initializes the token and core parameters.
2.  `name() view returns (string memory)`: Returns the token name.
3.  `symbol() view returns (string memory)`: Returns the token symbol.
4.  `decimals() view returns (uint8)`: Returns the token decimals.
5.  `totalSupply() view returns (uint256)`: Returns the total token supply.
6.  `balanceOf(address account) view returns (uint256)`: Returns the balance of an account.
7.  `transfer(address recipient, uint256 amount) returns (bool)`: Transfers tokens from the caller to a recipient.
8.  `approve(address spender, uint256 amount) returns (bool)`: Approves a spender to withdraw tokens.
9.  `allowance(address owner, address spender) view returns (uint256)`: Returns the allowance amount.
10. `transferFrom(address sender, address recipient, uint256 amount) returns (bool)`: Transfers tokens using allowance.
11. `pause()`: Pauses core contract functionality (entanglement creation, interactions). Only callable by owner.
12. `unpause()`: Unpauses contract functionality. Only callable by owner.
13. `stakeEntangledPair(uint256 amountA, uint256 amountB) returns (uint256 pairId)`: Locks `amountA + amountB` from caller's balance to create a new entangled pair, returning its ID.
14. `attemptWithdrawPrimary(uint256 pairId, uint256 withdrawAmount)`: Attempts to withdraw `withdrawAmount` from pair's AmountA. Transfers `withdrawAmount` to caller, calculates and potentially transfers a linked amount from AmountB based on coherence, and reduces pair coherence.
15. `boostCoherence(uint256 pairId)`: Stakes `boostAmountRequired` from caller's balance to increase the pair's coherence.
16. `measurePair(uint256 pairId)`: Finalizes the pair. Calculates the outcome (unlocked amount from AmountB) based on final coherence, marks the pair as measured.
17. `claimMeasurementOutcome(uint256 pairId)`: Transfers the unlocked AmountA and the calculated unlocked AmountB from a measured pair to the owner.
18. `emergencyWithdraw(uint256 pairId)`: Allows immediate withdrawal of locked tokens with a significant penalty proportional to coherence.
19. `splitPair(uint256 pairId, uint256 newAmountA1, uint256 newAmountB1) returns (uint256 pairId1, uint256 pairId2)`: Splits an existing unmeasured pair into two new pairs with specified amounts and adjusted coherence.
20. `mergePairs(uint256 pairId1, uint256 pairId2) returns (uint256 newPairId)`: Merges two unmeasured pairs owned by the caller into a single new pair with combined amounts and averaged coherence.
21. `observePair(uint256 pairId)`: A low-impact interaction that triggers minimal coherence decay and potential minor event without significant state change.
22. `transferPairOwnership(uint256 pairId, address newOwner)`: Transfers ownership of an unmeasured pair to another address.
23. `triggerDecoherenceOutcome(uint256 pairId)`: Allows anyone to trigger the final outcome for a pair whose coherence has reached zero.
24. `getPairState(uint256 pairId) view returns (address owner, uint256 amountA, uint256 amountB, uint256 coherence, uint256 creationTimestamp, uint256 lastCoherenceUpdate, bool isMeasured, bool isClaimed)`: Gets all details for a pair.
25. `listUserPairs(address user) view returns (uint256[] memory)`: Returns an array of pair IDs owned by a user.
26. `getPairCount() view returns (uint256)`: Returns the total number of pairs ever created.
27. `getPairOwner(uint256 pairId) view returns (address)`: Returns the owner of a specific pair.
28. `getPairAmounts(uint256 pairId) view returns (uint256 amountA, uint256 amountB)`: Returns the AmountA and AmountB locked in a pair.
29. `getPairCoherence(uint256 pairId) view returns (uint256)`: Returns the current coherence level of a pair, updated for time decay.
30. `predictMeasurementOutcome(uint256 pairId) view returns (uint256 predictedUnlockedB)`: Calculates and returns the expected AmountB unlocked if the pair were measured *now*.
31. `isPairEntangled(uint256 pairId) view returns (bool)`: Checks if a pair ID exists and is in an active (unmeasured) state.
32. `getTotalStakedEntangled() view returns (uint256)`: Returns the total amount of tokens locked across all active pairs.
33. `getUserTotalStakedEntangled(address user) view returns (uint256)`: Returns the total amount of tokens locked by a specific user across their active pairs.
34. `getCoherenceDecayRate() view returns (uint256)`: Returns the current coherence decay rate per second.
35. `getMeasurementOutcomeFactor() view returns (uint256)`: Returns the factor used in outcome calculation.
36. `getBoostAmountRequired() view returns (uint256)`: Returns the amount of tokens required to boost coherence.
37. `isPaused() view returns (bool)`: Returns the current paused state.
38. `setCoherenceDecayRate(uint256 rate)`: Admin function to set the decay rate.
39. `setMeasurementOutcomeFactor(uint256 factor)`: Admin function to set the outcome calculation factor.
40. `setBoostAmountRequired(uint256 amount)`: Admin function to set the cost of boosting.
41. `recoverStuckTokens(address tokenAddress, uint256 amount)`: Admin function to rescue tokens (other than QE20) sent to the contract address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledERC20 (QE20)
 * @author [Your Name/Alias]
 * @dev A novel token standard implementing "Quantum Entanglement Pairs".
 * Users lock tokens into pairs with a dynamic "coherence" level that decays
 * and is affected by interactions. The final outcome upon "measurement"
 * depends directly on the pair's coherence. This contract provides basic
 * ERC20 functionality alongside the entanglement mechanics.
 *
 * Outline:
 * 1. License and Pragma
 * 2. Basic ERC20 Implementation
 * 3. Pausable Mechanism
 * 4. Ownable for Admin
 * 5. Entanglement Pair Struct and State
 * 6. Events
 * 7. Modifiers
 * 8. Constructor
 * 9. ERC20 Standard Functions
 * 10. Pausable Functions
 * 11. Entanglement Core Logic Functions
 * 12. Entanglement Query/View Functions
 * 13. Admin Functions
 */

contract QuantumEntangledERC20 {

    // --- 2. Basic ERC20 Implementation ---
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // --- 3. Pausable Mechanism ---
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    // --- 4. Ownable for Admin ---
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    // --- 5. Entanglement Pair Struct and State ---

    struct EntangledPair {
        address owner;
        uint256 amountA;
        uint256 amountB;
        uint256 coherence; // Stored with a fixed point, e.g., 10000 = 100%
        uint256 creationTimestamp;
        uint256 lastCoherenceUpdate;
        bool isMeasured;
        bool isClaimed; // For claiming the result after measurement
    }

    mapping(uint256 => EntangledPair) private pairs;
    mapping(address => uint256[]) private userPairs; // Store pair IDs for each user

    uint256 private nextPairId;
    uint256 private totalStakedEntangled; // Total tokens locked in pairs

    // Entanglement Parameters (configurable by owner)
    uint256 public coherenceDecayRatePerSecond = 10; // Decay points per second (e.g., 10000 / (10 * 1000) = 1000s to reach 0 from 100%)
    uint256 public constant MAX_COHERENCE = 10000; // Represents 100% coherence
    uint256 public constant COHERENCE_BASIS = 10000; // For calculations using fixed point
    uint256 public measurementOutcomeFactor = 1; // Multiplier for outcome calculation (e.g., 1x unlocks based on coherence)
    uint256 public boostAmountRequired = 100 ether; // Tokens needed to boost coherence

    // --- 6. Events (Declared above with state variables) ---
    event PairCreated(uint256 indexed pairId, address indexed owner, uint256 amountA, uint256 amountB, uint256 initialCoherence);
    event CoherenceDecayed(uint256 indexed pairId, uint256 oldCoherence, uint256 newCoherence);
    event CoherenceBoosted(uint256 indexed pairId, uint256 oldCoherence, uint256 newCoherence);
    event PrimaryInteracted(uint256 indexed pairId, uint256 withdrawAmount, uint256 secondaryEffectAmount, uint256 newCoherence);
    event PairMeasured(uint256 indexed pairId, uint256 finalCoherence, uint256 unlockedB);
    event OutcomeClaimed(uint256 indexed pairId, uint256 claimedAmountA, uint256 claimedAmountB);
    event DecoherenceTriggered(uint256 indexed pairId, uint256 finalCoherence); // Coherence near zero
    event PairOwnershipTransferred(uint256 indexed pairId, address indexed oldOwner, address indexed newOwner);
    event PairSplit(uint256 indexed originalPairId, uint256 indexed newPairId1, uint256 indexed newPairId2);
    event PairsMerged(uint256 indexed pairId1, uint256 indexed pairId2, uint256 indexed newPairId);
    event ObservationMade(uint256 indexed pairId, uint256 newCoherence);
    event EmergencyWithdrawal(uint256 indexed pairId, uint256 returnedAmount);
    event StuckTokensRecovered(address indexed token, uint256 amount);


    // --- 7. Modifiers ---
    modifier onlyPairOwner(uint256 pairId) {
        require(pairs[pairId].owner == msg.sender, "QE20: Not pair owner");
        _;
    }

     modifier whenPairExists(uint256 pairId) {
        require(pairs[pairId].creationTimestamp > 0, "QE20: Pair does not exist");
        _;
    }

    modifier whenPairNotMeasured(uint256 pairId) {
        require(!pairs[pairId].isMeasured, "QE20: Pair already measured");
        _;
    }

    modifier whenPairMeasured(uint256 pairId) {
        require(pairs[pairId].isMeasured, "QE20: Pair not measured yet");
        _;
    }

    modifier whenPairNotClaimed(uint256 pairId) {
        require(!pairs[pairId].isClaimed, "QE20: Measurement outcome already claimed");
        _;
    }

    // --- 8. Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = initialSupply_;
        _balances[msg.sender] = initialSupply_; // Mint initial supply to deployer

        _owner = msg.sender; // Set deployer as owner
        emit OwnershipTransferred(address(0), _owner);

        _paused = false; // Start unpaused
        nextPairId = 1; // Start pair IDs from 1
    }

    // --- 9. ERC20 Standard Functions ---
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    // Internal ERC20 functions
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] -= amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

     function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            _balances[account] -= amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    // --- 10. Pausable Functions ---
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- 11. Entanglement Core Logic Functions ---

    /**
     * @dev Creates a new entangled pair by locking user's tokens.
     * @param amountA Amount for the first part of the pair.
     * @param amountB Amount for the second part of the pair.
     * @return pairId The unique ID of the newly created pair.
     */
    function stakeEntangledPair(uint256 amountA, uint256 amountB)
        public whenNotPaused
        returns (uint256 pairId)
    {
        require(amountA > 0 && amountB > 0, "QE20: Amounts must be positive");
        uint256 totalAmount = amountA + amountB;
        require(_balances[msg.sender] >= totalAmount, "QE20: Insufficient balance to stake");

        // Transfer tokens into the contract (locked state)
        _transfer(msg.sender, address(this), totalAmount);

        // Create pair struct
        pairId = nextPairId++;
        uint256 currentTime = block.timestamp;

        pairs[pairId] = EntangledPair({
            owner: msg.sender,
            amountA: amountA,
            amountB: amountB,
            coherence: MAX_COHERENCE, // Start with max coherence
            creationTimestamp: currentTime,
            lastCoherenceUpdate: currentTime,
            isMeasured: false,
            isClaimed: false
        });

        // Add pair ID to user's list
        userPairs[msg.sender].push(pairId);

        totalStakedEntangled += totalAmount;

        emit PairCreated(pairId, msg.sender, amountA, amountB, MAX_COHERENCE);
    }

    /**
     * @dev Attempts to withdraw from AmountA, causing coherence decay and Secondary effect.
     * The effect on AmountB and coherence decay depends on the amount withdrawn
     * relative to the initial AmountA and current coherence.
     * @param pairId The ID of the pair to interact with.
     * @param withdrawAmount The amount of AmountA the user wishes to withdraw.
     */
    function attemptWithdrawPrimary(uint256 pairId, uint256 withdrawAmount)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
    {
        EntangledPair storage pair = pairs[pairId];
        require(withdrawAmount > 0, "QE20: Withdraw amount must be positive");
        require(pair.amountA >= withdrawAmount, "QE20: Withdraw amount exceeds available AmountA");

        // Apply time-based decay first
        _updateCoherence(pairId);

        // Calculate secondary effect based on withdraw amount and current coherence
        // More withdrawal or higher coherence results in a stronger secondary effect
        // Example: Secondary effect = (WithdrawAmount / OriginalAmountA) * CurrentAmountB * (CurrentCoherence / MAX_COHERENCE)
        // Simplified: Let's base it on the *proportion* of AmountA withdrawn.
        // secondaryEffectAmount = (withdrawAmount * pair.amountB * pair.coherence) / (pair.amountA_at_creation * MAX_COHERENCE) <-- need original A amount, add to struct?
        // Let's simplify based on *current* amounts: secondaryEffectAmount = (withdrawAmount * pair.amountB * pair.coherence) / (pair.amountA * MAX_COHERENCE)
        // Requires careful division to avoid overflow and handle potential 0 denominators if amountA goes to 0.
        // Let's use a factor relative to withdrawal:
        // secondaryEffectAmount = withdrawAmount * (pair.coherence / COHERENCE_BASIS) * (pair.amountB / pair.amountA) (this still requires careful handling)
        // Simpler model: secondaryEffectAmount = (withdrawAmount * pair.amountB * pair.coherence) / (pair.amountA * COHERENCE_BASIS)
        // To avoid division by zero if amountA becomes 0 due to multiple small withdrawals, add a check or use original amount.
        // Let's use originalAmountA in calculation, but apply to current amountB. This needs originalAmountA in struct. Add originalAmountA.

        uint256 originalAmountA = pair.amountA + withdrawAmount; // Assuming this is the first/only withdrawal or need better tracking

        // Re-struct EntangledPair to track original amount
        // struct EntangledPair { owner, amountA, amountB, originalAmountA, originalAmountB, coherence, creationTimestamp, lastCoherenceUpdate, isMeasured, isClaimed }
        // For simplicity now, let's make the secondary effect proportional to withdrawAmount and coherence, irrespective of the ratio A:B, but limited by amountB.
        // secondaryEffectAmount = (withdrawAmount * pair.coherence) / COHERENCE_BASIS; Limited to pair.amountB.
        uint256 secondaryEffectAmount = (withdrawAmount * pair.coherence) / COHERENCE_BASIS;
        if (secondaryEffectAmount > pair.amountB) {
            secondaryEffectAmount = pair.amountB;
        }

        // Reduce amounts in pair
        pair.amountA -= withdrawAmount;
        pair.amountB -= secondaryEffectAmount; // Tokens effectively moved/affected from B

        // Transfer amounts to the caller/recipient
        // Note: Both amounts go to the caller in this interaction model
        uint256 totalReceived = withdrawAmount + secondaryEffectAmount;
        _transfer(address(this), msg.sender, totalReceived);
        totalStakedEntangled -= totalReceived;

        // Reduce coherence based on interaction (proportional to withdrawAmount relative to original AmountA)
        // Let's simplify interaction decay: fixed amount or proportional to withdraw amount?
        // Decay based on withdraw amount: decay = (withdrawAmount * InteractionDecayFactor) / OriginalAmountA
        // Let's use a simpler fixed interaction decay points per interaction, or proportional to withdraw amount relative to pair size.
        // Decay = (withdrawAmount * MAX_COHERENCE) / (pair.amountA + pair.amountB + withdrawAmount + secondaryEffectAmount) <-- size before interaction
        uint256 interactionDecay = (withdrawAmount * MAX_COHERENCE) / (pair.amountA + pair.amountB + withdrawAmount + secondaryEffectAmount); // Decay proportional to withdrawal relative to pair size before interaction

        if (pair.coherence > interactionDecay) {
            pair.coherence -= interactionDecay;
        } else {
            pair.coherence = 0;
        }

        emit PrimaryInteracted(pairId, withdrawAmount, secondaryEffectAmount, pair.coherence);

        // Check for decoherence after interaction
        if (pair.coherence == 0) {
             _triggerDecoherenceOutcome(pairId);
        }
    }

    /**
     * @dev Stakes required amount to increase pair's coherence.
     * @param pairId The ID of the pair to boost.
     */
    function boostCoherence(uint256 pairId)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
    {
        EntangledPair storage pair = pairs[pairId];
        require(_balances[msg.sender] >= boostAmountRequired, "QE20: Insufficient balance to boost");

        // Apply time-based decay first
        _updateCoherence(pairId);

        // Transfer boost amount to contract (burned or held?) Let's burn for simplicity/deflation
        _burn(msg.sender, boostAmountRequired);

        // Increase coherence, capped at MAX_COHERENCE
        // Increase amount could be fixed or proportional to boost amount / pair size
        // Let's use a fixed boost amount relative to MAX_COHERENCE, e.g., 10% of max coherence
        uint256 boostAmount = MAX_COHERENCE / 10; // Example: Boost by 10% of max coherence
        uint256 oldCoherence = pair.coherence;
        pair.coherence = pair.coherence + boostAmount > MAX_COHERENCE ? MAX_COHERENCE : pair.coherence + boostAmount;
        pair.lastCoherenceUpdate = block.timestamp; // Reset decay timer

        emit CoherenceBoosted(pairId, oldCoherence, pair.coherence);
    }

    /**
     * @dev Measures the pair, collapsing its state and determining the outcome.
     * The amount unlocked from AmountB is proportional to the coherence.
     * AmountA is fully unlocked upon measurement (unless emergency withdrawn).
     * @param pairId The ID of the pair to measure.
     */
    function measurePair(uint256 pairId)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
    {
        EntangledPair storage pair = pairs[pairId];

        // Apply time-based decay first
        _updateCoherence(pairId);

        // Calculate unlocked amount from AmountB based on final coherence
        // unlockedB = pair.amountB * (pair.coherence / COHERENCE_BASIS) * measurementOutcomeFactor
        uint256 unlockedB;
        if (pair.coherence > 0) {
            unlockedB = (pair.amountB * pair.coherence * measurementOutcomeFactor) / (COHERENCE_BASIS * measurementOutcomeFactor); // Simplified: unlockedB = (pair.amountB * pair.coherence) / COHERENCE_BASIS
            if (unlockedB > pair.amountB) unlockedB = pair.amountB; // Cap at available amountB
        } else {
            unlockedB = 0; // No unlock if coherence is zero
        }

        // Note: pair.amountA is considered fully unlocked upon measurement in this model,
        // unless it was already reduced by attemptWithdrawPrimary or emergencyWithdrawal.
        // The tokens for amountA and unlockedB become available for claiming.

        pair.isMeasured = true;
        // pair.amountB is not reduced here, it's reduced upon claiming or lost if not claimed/unlocked

        emit PairMeasured(pairId, pair.coherence, unlockedB);

        // Set amountB to the amount that *can* be claimed. Remaining is lost.
        pair.amountB = unlockedB; // Store the *claimable* amountB
    }

     /**
     * @dev Allows the owner to claim the tokens unlocked after a pair has been measured.
     * Includes the remaining AmountA and the calculated unlocked AmountB.
     * @param pairId The ID of the pair to claim from.
     */
    function claimMeasurementOutcome(uint256 pairId)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairMeasured(pairId)
        whenPairNotClaimed(pairId)
    {
        EntangledPair storage pair = pairs[pairId];

        uint256 claimableA = pair.amountA; // Remaining AmountA is claimable
        uint256 claimableB = pair.amountB; // This is the *calculated unlocked* AmountB from measurePair

        require(claimableA > 0 || claimableB > 0, "QE20: No tokens to claim");

        uint256 totalClaimAmount = claimableA + claimableB;

        // Transfer claimable amounts
        pair.amountA = 0; // Zero out amounts in pair state after claiming
        pair.amountB = 0;
        pair.isClaimed = true;

        _transfer(address(this), msg.sender, totalClaimAmount);
        totalStakedEntangled -= totalClaimAmount; // Reduce total staked

        emit OutcomeClaimed(pairId, claimableA, claimableB);

        // Clean up pair ID from userPairs array (optional, but good practice)
        _removePairIdFromUserList(msg.sender, pairId);
    }

    /**
     * @dev Allows immediate withdrawal of locked tokens with a significant penalty.
     * Penalty is proportional to coherence. Higher coherence = higher penalty.
     * This bypasses the normal measurement process.
     * @param pairId The ID of the pair to withdraw from.
     */
    function emergencyWithdraw(uint256 pairId)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
    {
        EntangledPair storage pair = pairs[pairId];

        // Apply time-based decay first
        _updateCoherence(pairId);

        uint256 totalStakedInPair = pair.amountA + pair.amountB;

        // Calculate penalty based on coherence (higher coherence = higher penalty)
        // Penalty = TotalStaked * (CurrentCoherence / MAX_COHERENCE)
        uint256 penaltyAmount = (totalStakedInPair * pair.coherence) / MAX_COHERENCE;

        uint256 returnAmount = totalStakedInPair - penaltyAmount;

        // Burn the penalty amount
        if (penaltyAmount > 0) {
            // Burning happens implicitly by not transferring the penalty amount back
            // from the tokens held by the contract.
        }

        // Transfer the reduced amount back to the owner
        if (returnAmount > 0) {
            _transfer(address(this), msg.sender, returnAmount);
            totalStakedEntangled -= totalStangledInPair; // Subtract full amount locked
        } else {
             totalStakedEntangled -= totalStakedInPair; // Subtract full amount even if nothing returned
        }


        // Mark as measured and claimed to prevent further interaction
        pair.isMeasured = true;
        pair.isClaimed = true;
        pair.amountA = 0; // Zero out amounts
        pair.amountB = 0;

        emit EmergencyWithdrawal(pairId, returnAmount);

        // Clean up pair ID from userPairs array
        _removePairIdFromUserList(msg.sender, pairId);
    }

    /**
     * @dev Splits an existing, unmeasured pair into two new pairs.
     * Amounts are specified for the first new pair; the remainder goes to the second.
     * Coherence of new pairs may be reduced.
     * @param pairId The ID of the pair to split.
     * @param newAmountA1 AmountA for the first new pair.
     * @param newAmountB1 AmountB for the first new pair.
     * @return pairId1 The ID of the first new pair.
     * @return pairId2 The ID of the second new pair.
     */
    function splitPair(uint256 pairId, uint256 newAmountA1, uint256 newAmountB1)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
        returns (uint256 pairId1, uint256 pairId2)
    {
        EntangledPair storage originalPair = pairs[pairId];
        require(newAmountA1 > 0 && newAmountB1 > 0, "QE20: New pair amounts must be positive");
        require(originalPair.amountA >= newAmountA1, "QE20: New AmountA1 exceeds original AmountA");
        require(originalPair.amountB >= newAmountB1, "QE20: New AmountB1 exceeds original AmountB");

        // Apply time-based decay first
        _updateCoherence(pairId);

        uint256 newAmountA2 = originalPair.amountA - newAmountA1;
        uint256 newAmountB2 = originalPair.amountB - newAmountB1;

        // Calculate coherence for new pairs (e.g., reduced or split)
        // Example: Coherence is split proportionally or reduced by a fixed factor
        uint256 newCoherence1 = (originalPair.coherence * (newAmountA1 + newAmountB1)) / (originalPair.amountA + originalPair.amountB);
        uint256 newCoherence2 = (originalPair.coherence * (newAmountA2 + newAmountB2)) / (originalPair.amountA + originalPair.amountB);

        // Invalidate original pair
        originalPair.isMeasured = true; // Mark as measured/resolved by splitting
        originalPair.isClaimed = true; // Mark as claimed (split result goes into new pairs)
        originalPair.amountA = 0; // Zero out amounts
        originalPair.amountB = 0;
         // Remove original pair ID from userPairs (will add new ones)
        _removePairIdFromUserList(msg.sender, pairId);

        // Create two new pairs
        uint256 currentTime = block.timestamp;

        pairId1 = nextPairId++;
        pairs[pairId1] = EntangledPair({
            owner: msg.sender,
            amountA: newAmountA1,
            amountB: newAmountB1,
            coherence: newCoherence1 > MAX_COHERENCE ? MAX_COHERENCE : newCoherence1, // Cap coherence
            creationTimestamp: currentTime,
            lastCoherenceUpdate: currentTime,
            isMeasured: false,
            isClaimed: false
        });
        userPairs[msg.sender].push(pairId1);

        pairId2 = nextPairId++;
         pairs[pairId2] = EntangledPair({
            owner: msg.sender,
            amountA: newAmountA2,
            amountB: newAmountB2,
            coherence: newCoherence2 > MAX_COHERENCE ? MAX_COHERENCE : newCoherence2, // Cap coherence
            creationTimestamp: currentTime,
            lastCoherenceUpdate: currentTime,
            isMeasured: false,
            isClaimed: false
        });
        userPairs[msg.sender].push(pairId2);

        // totalStakedEntangled doesn't change, tokens remain in contract under new pair IDs

        emit PairSplit(pairId, pairId1, pairId2);
    }

    /**
     * @dev Merges two unmeasured pairs owned by the caller into a single new pair.
     * Amounts are combined, coherence is averaged (weighted by size).
     * @param pairId1 The ID of the first pair to merge.
     * @param pairId2 The ID of the second pair to merge.
     * @return newPairId The ID of the newly created merged pair.
     */
    function mergePairs(uint256 pairId1, uint256 pairId2)
        public whenNotPaused
        whenPairExists(pairId1)
        whenPairExists(pairId2)
        onlyPairOwner(pairId1)
        onlyPairOwner(pairId2) // Ensure owner is the same for both
        whenPairNotMeasured(pairId1)
        whenPairNotMeasured(pairId2)
        returns (uint256 newPairId)
    {
        require(pairId1 != pairId2, "QE20: Cannot merge a pair with itself");

        EntangledPair storage pair1 = pairs[pairId1];
        EntangledPair storage pair2 = pairs[pairId2];

        // Apply time-based decay first to both pairs
        _updateCoherence(pairId1);
        _updateCoherence(pairId2);

        uint256 totalAmountA = pair1.amountA + pair2.amountA;
        uint256 totalAmountB = pair1.amountB + pair2.amountB;
        uint256 totalSize1 = pair1.amountA + pair1.amountB;
        uint256 totalSize2 = pair2.amountA + pair2.amountB;
        uint256 combinedSize = totalSize1 + totalSize2;

        // Calculate weighted average coherence
        uint256 newCoherence = 0;
        if (combinedSize > 0) {
             newCoherence = ((pair1.coherence * totalSize1) + (pair2.coherence * totalSize2)) / combinedSize;
        }


        // Invalidate original pairs
        pair1.isMeasured = true; // Mark as measured/resolved by merging
        pair1.isClaimed = true;
        pair1.amountA = 0;
        pair1.amountB = 0;
         _removePairIdFromUserList(msg.sender, pairId1);


        pair2.isMeasured = true; // Mark as measured/resolved by merging
        pair2.isClaimed = true;
        pair2.amountA = 0;
        pair2.amountB = 0;
        _removePairIdFromUserList(msg.sender, pairId2);


        // Create new merged pair
        uint256 currentTime = block.timestamp;

        newPairId = nextPairId++;
        pairs[newPairId] = EntangledPair({
            owner: msg.sender,
            amountA: totalAmountA,
            amountB: totalAmountB,
            coherence: newCoherence > MAX_COHERENCE ? MAX_COHERENCE : newCoherence, // Cap coherence
            creationTimestamp: currentTime,
            lastCoherenceUpdate: currentTime,
            isMeasured: false,
            isClaimed: false
        });
        userPairs[msg.sender].push(newPairId);

        // totalStakedEntangled doesn't change

        emit PairsMerged(pairId1, pairId2, newPairId);
    }

    /**
     * @dev A passive interaction that causes minimal coherence decay.
     * Doesn't transfer tokens or significantly change state besides coherence update.
     * @param pairId The ID of the pair to observe.
     */
    function observePair(uint256 pairId)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
    {
        // Apply time-based decay first
        _updateCoherence(pairId);

        // Apply a small, fixed interaction decay
        uint256 observationDecay = MAX_COHERENCE / 1000; // Example: 0.1% decay per observation
        EntangledPair storage pair = pairs[pairId];
         uint256 oldCoherence = pair.coherence;

        if (pair.coherence > observationDecay) {
            pair.coherence -= observationDecay;
        } else {
            pair.coherence = 0;
        }
        pair.lastCoherenceUpdate = block.timestamp; // Update timestamp to prevent immediate re-decay

        emit ObservationMade(pairId, pair.coherence);

         if (pair.coherence == 0) {
             _triggerDecoherenceOutcome(pairId);
        }
    }

    /**
     * @dev Transfers ownership of an unmeasured pair.
     * @param pairId The ID of the pair to transfer.
     * @param newOwner The address of the new owner.
     */
    function transferPairOwnership(uint256 pairId, address newOwner)
        public whenNotPaused
        whenPairExists(pairId)
        onlyPairOwner(pairId)
        whenPairNotMeasured(pairId)
    {
        require(newOwner != address(0), "QE20: New owner is the zero address");
        address oldOwner = msg.sender;
        EntangledPair storage pair = pairs[pairId];

        // Update time decay before transferring
        _updateCoherence(pairId);

        pair.owner = newOwner;

        // Update userPairs lists
        _removePairIdFromUserList(oldOwner, pairId);
        userPairs[newOwner].push(pairId);

        emit PairOwnershipTransferred(pairId, oldOwner, newOwner);
    }

    /**
     * @dev Allows anyone to trigger the unfavorable outcome for a pair whose coherence has reached zero.
     * This helps clean up expired pairs.
     * @param pairId The ID of the pair.
     */
    function triggerDecoherenceOutcome(uint256 pairId)
        public whenNotPaused
        whenPairExists(pairId)
        whenPairNotMeasured(pairId)
    {
         EntangledPair storage pair = pairs[pairId];

         // Apply decay to ensure coherence is updated
         _updateCoherence(pairId);

         require(pair.coherence == 0, "QE20: Coherence is not zero");

         _triggerDecoherenceOutcome(pairId);
    }

    /**
     * @dev Internal function to handle the outcome when coherence hits zero.
     * Sends a minimal amount back and locks the rest.
     * @param pairId The ID of the pair.
     */
    function _triggerDecoherenceOutcome(uint256 pairId) internal {
        EntangledPair storage pair = pairs[pairId];
        require(pair.coherence == 0, "QE20: Coherence must be zero for decoherence outcome");
        require(!pair.isMeasured, "QE20: Pair already measured");

        uint256 minimalReturnPercentage = 100; // Example: 1% return (100 / 10000)
        uint256 returnAmount = ((pair.amountA + pair.amountB) * minimalReturnPercentage) / COHERENCE_BASIS;

        uint256 totalStakedInPair = pair.amountA + pair.amountB;

        // Mark as measured and claimed
        pair.isMeasured = true;
        pair.isClaimed = true;
        pair.amountA = 0; // Zero out amounts
        pair.amountB = 0;

        // Transfer minimal amount back
        if (returnAmount > 0) {
             _transfer(address(this), pair.owner, returnAmount);
        }
         totalStakedEntangled -= totalStakedInPair; // Subtract full original amount


        emit DecoherenceTriggered(pairId, 0);

        // Clean up pair ID from userPairs array
        _removePairIdFromUserList(pair.owner, pairId);
    }


    /**
     * @dev Internal function to calculate and apply time-based coherence decay.
     * @param pairId The ID of the pair to update.
     */
    function _updateCoherence(uint256 pairId) internal {
        EntangledPair storage pair = pairs[pairId];
        if (pair.isMeasured) return; // No decay after measurement

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - pair.lastCoherenceUpdate;

        if (timeElapsed == 0) return; // No time passed

        uint256 decayPoints = timeElapsed * coherenceDecayRatePerSecond;

        if (pair.coherence > decayPoints) {
            pair.coherence -= decayPoints;
        } else {
            pair.coherence = 0;
        }
        pair.lastCoherenceUpdate = currentTime; // Update timestamp

        emit CoherenceDecayed(pairId, pair.coherence + decayPoints, pair.coherence); // Log old and new

        // Trigger decoherence if it hits zero
        if (pair.coherence == 0) {
            _triggerDecoherenceOutcome(pairId);
        }
    }

     /**
     * @dev Internal helper to remove a pair ID from a user's list.
     * @param user The address of the user.
     * @param pairIdToRemove The pair ID to remove.
     */
    function _removePairIdFromUserList(address user, uint256 pairIdToRemove) internal {
        uint256[] storage userPairList = userPairs[user];
        for (uint i = 0; i < userPairList.length; i++) {
            if (userPairList[i] == pairIdToRemove) {
                // Replace with the last element and pop
                userPairList[i] = userPairList[userPairList.length - 1];
                userPairList.pop();
                break; // Assuming pair IDs are unique per user list
            }
        }
    }


    // --- 12. Entanglement Query/View Functions ---

    /**
     * @dev Gets the full state details of a specific entangled pair.
     * @param pairId The ID of the pair.
     * @return owner The pair owner's address.
     * @return amountA The current amountA.
     * @return amountB The current amountB.
     * @return coherence The current coherence level (decay applied).
     * @return creationTimestamp The creation timestamp.
     * @return lastCoherenceUpdate The last time coherence was updated.
     * @return isMeasured Whether the pair has been measured.
     * @return isClaimed Whether the measurement outcome has been claimed.
     */
    function getPairState(uint256 pairId)
        public view whenPairExists(pairId)
        returns (address owner, uint256 amountA, uint256 amountB, uint256 coherence, uint256 creationTimestamp, uint256 lastCoherenceUpdate, bool isMeasured, bool isClaimed)
    {
         EntangledPair storage pair = pairs[pairId];
         uint256 currentCoherence = pair.coherence;
         uint256 currentTime = block.timestamp;
         if (!pair.isMeasured) {
              // Calculate potential decay without changing state for view function
              uint256 timeElapsed = currentTime - pair.lastCoherenceUpdate;
               uint256 decayPoints = timeElapsed * coherenceDecayRatePerSecond;
              if (currentCoherence > decayPoints) {
                  currentCoherence -= decayPoints;
              } else {
                  currentCoherence = 0;
              }
         }

        return (
            pair.owner,
            pair.amountA,
            pair.amountB,
            currentCoherence, // Return calculated current coherence
            pair.creationTimestamp,
            pair.lastCoherenceUpdate,
            pair.isMeasured,
            pair.isClaimed
        );
    }


    /**
     * @dev Returns an array of pair IDs owned by a specific user.
     * @param user The address of the user.
     * @return pairIds An array of pair IDs.
     */
    function listUserPairs(address user) public view returns (uint256[] memory) {
        return userPairs[user];
    }

    /**
     * @dev Returns the total number of entangled pairs ever created.
     */
    function getPairCount() public view returns (uint256) {
        return nextPairId - 1; // nextPairId is 1 ahead of the last ID used
    }

    /**
     * @dev Returns the owner of a specific pair.
     * @param pairId The ID of the pair.
     */
    function getPairOwner(uint256 pairId) public view whenPairExists(pairId) returns (address) {
        return pairs[pairId].owner;
    }

    /**
     * @dev Returns the current AmountA and AmountB locked in a specific pair.
     * @param pairId The ID of the pair.
     */
    function getPairAmounts(uint256 pairId) public view whenPairExists(pairId) returns (uint256 amountA, uint256 amountB) {
        EntangledPair storage pair = pairs[pairId];
        return (pair.amountA, pair.amountB);
    }

    /**
     * @dev Returns the current coherence level of a pair (decay applied).
     * @param pairId The ID of the pair.
     */
    function getPairCoherence(uint256 pairId) public view whenPairExists(pairId) returns (uint256) {
        EntangledPair storage pair = pairs[pairId];
        if (pair.isMeasured) return 0; // Coherence is effectively zero after measurement

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - pair.lastCoherenceUpdate;
        uint256 currentCoherence = pair.coherence;

        uint256 decayPoints = timeElapsed * coherenceDecayRatePerSecond;
        if (currentCoherence > decayPoints) {
            return currentCoherence - decayPoints;
        } else {
            return 0;
        }
    }

    /**
     * @dev Predicts the outcome (unlocked AmountB) if the pair were measured *now*.
     * Does not change contract state.
     * @param pairId The ID of the pair.
     */
    function predictMeasurementOutcome(uint256 pairId) public view whenPairExists(pairId) whenPairNotMeasured(pairId) returns (uint256 predictedUnlockedB) {
        EntangledPair storage pair = pairs[pairId];
        uint256 currentCoherence = getPairCoherence(pairId); // Get coherence with current decay applied

        // Calculate potential unlocked amount from AmountB
        if (currentCoherence > 0) {
             predictedUnlockedB = (pair.amountB * currentCoherence * measurementOutcomeFactor) / (COHERENCE_BASIS * measurementOutcomeFactor); // Simplified
            if (predictedUnlockedB > pair.amountB) predictedUnlockedB = pair.amountB; // Cap
        } else {
            predictedUnlockedB = 0;
        }
         return predictedUnlockedB;
    }

     /**
     * @dev Checks if a pair ID corresponds to an existing and unmeasured pair.
     * @param pairId The ID to check.
     */
    function isPairEntangled(uint256 pairId) public view returns (bool) {
        return pairs[pairId].creationTimestamp > 0 && !pairs[pairId].isMeasured;
    }

     /**
     * @dev Returns the total amount of QE20 tokens currently locked in all active (unmeasured) pairs.
     */
    function getTotalStakedEntangled() public view returns (uint256) {
        return totalStakedEntangled;
    }

     /**
     * @dev Returns the total amount of QE20 tokens currently locked in active (unmeasured) pairs owned by a specific user.
     * @param user The address of the user.
     */
    function getUserTotalStakedEntangled(address user) public view returns (uint256) {
        uint256 userStaked = 0;
        uint256[] storage pairIds = userPairs[user];
        for (uint i = 0; i < pairIds.length; i++) {
            uint256 pairId = pairIds[i];
            // Check if pair exists and is not measured
             if (pairs[pairId].creationTimestamp > 0 && !pairs[pairId].isMeasured) {
                 userStaked += pairs[pairId].amountA + pairs[pairId].amountB;
             }
        }
        return userStaked;
    }

     // Get parameter values (already public, adding specific views for clarity/completeness count)
     function getCoherenceDecayRate() public view returns (uint256) { return coherenceDecayRatePerSecond; }
     function getMeasurementOutcomeFactor() public view returns (uint256) { return measurementOutcomeFactor; }
     function getBoostAmountRequired() public view returns (uint256) { return boostAmountRequired; }
     function isPaused() public view returns (bool) { return _paused; }


    // --- 13. Admin Functions (onlyOwner) ---

    /**
     * @dev Admin function to set the rate at which coherence decays per second.
     * @param rate The new decay rate (points per second).
     */
    function setCoherenceDecayRate(uint256 rate) public onlyOwner {
        coherenceDecayRatePerSecond = rate;
    }

    /**
     * @dev Admin function to set the multiplier for the measurement outcome calculation.
     * @param factor The new outcome factor.
     */
    function setMeasurementOutcomeFactor(uint256 factor) public onlyOwner {
        measurementOutcomeFactor = factor;
    }

    /**
     * @dev Admin function to set the amount of tokens required to boost coherence.
     * @param amount The new boost amount.
     */
    function setBoostAmountRequired(uint256 amount) public onlyOwner {
        boostAmountRequired = amount;
    }

     /**
     * @dev Admin function to recover tokens accidentally sent to the contract address.
     * @param tokenAddress The address of the stuck token.
     * @param amount The amount of tokens to recover.
     */
    function recoverStuckTokens(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(this), "QE20: Cannot recover this contract's own tokens using this function");
        IERC20 stuckToken = IERC20(tokenAddress);
        require(stuckToken.balanceOf(address(this)) >= amount, "QE20: Contract does not have enough stuck tokens");
        stuckToken.transfer(msg.sender, amount);
        emit StuckTokensRecovered(tokenAddress, amount);
    }
}

// Basic IERC20 interface for recoverStuckTokens. Can be replaced with OpenZeppelin if desired.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```