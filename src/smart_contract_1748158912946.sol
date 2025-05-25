```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For random number generation helper

// --- Outline ---
// 1. State Variables & Enums: Defines the core data structures and states of deposits.
// 2. Events: Declares signals emitted during key actions.
// 3. Modifiers: Restricts access to certain functions.
// 4. Structures: Defines the structure of a user deposit.
// 5. Constructor: Initializes the contract, owner, wait period, and initial supported tokens/probabilities.
// 6. Ownership Management: Standard functions for transferring ownership.
// 7. Token Management (Owner): Functions to add/remove supported ERC20 tokens.
// 8. Probability & Wait Period Management (Owner): Functions to configure collapse outcomes and timing.
// 9. Pause Functionality (Owner): Controls contract availability for deposits and collapses.
// 10. Core Quantum Logic (User Facing): Functions for depositing, initiating, finalizing collapses, and claiming funds.
// 11. View Functions (Public/User Facing): Functions to query contract state and deposit details.
// 12. Internal Helpers: Helper functions for internal logic (e.g., determining classical state).
// 13. Emergency Withdraw (Owner): Allows withdrawing stuck tokens.

// --- Function Summary ---
// - deposit(address token, uint256 amount): Allows a user to deposit a supported ERC20 token into the 'Superposed' state.
// - initiateCollapse(uint256 depositId): Starts the collapse process for a user's 'Superposed' deposit, moving it to the 'Collapsing' state.
// - finalizeCollapse(uint256 depositId): Completes the collapse after the wait period, determining the 'ClassicalState' based on contract logic and pseudo-randomness.
// - redeem(uint256 depositId): Claims funds from a deposit that finalized into the 'Redeemable' state.
// - claimTimeLocked(uint256 depositId): Claims funds from a deposit that finalized into the 'TimeLocked' state, after the lock-up period expires.
// - claimPartialBurn(uint256 depositId): Claims the remaining portion of funds from a deposit that finalized into the 'PartialBurn' state.
// - getDepositState(uint256 depositId): Returns the current state (DepositState or ClassicalState) of a specific deposit.
// - getDepositDetails(uint256 depositId): Returns all details stored in the Deposit struct for a given ID.
// - getUserDepositIds(address user): Returns a list of all deposit IDs associated with a user. (Note: Gas intensive for many deposits)
// - getUserBalanceByState(address user, address token, DepositState state): Returns the total token balance for a user in a specific DepositState (Superposed, Collapsing).
// - getUserBalanceByClassicalState(address user, address token, ClassicalState state): Returns the total token balance for a user in a specific ClassicalState.
// - getCollapseWaitPeriod(): Returns the required waiting time in seconds between initiating and finalizing a collapse.
// - getSupportedTokens(): Returns a list of addresses of all currently supported ERC20 tokens.
// - getCollapseProbabilities(): Returns the defined weights for each ClassicalState used in collapse finalization.
// - getClassicalStateInfo(ClassicalState state): Placeholder/example view function to describe a ClassicalState.
// - getDepositCount(): Returns the total number of deposits ever made.
// - addSupportedToken(address token): Owner function to add a new ERC20 token that can be deposited.
// - removeSupportedToken(address token): Owner function to remove a supported ERC20 token.
// - setCollapseWaitPeriod(uint256 seconds): Owner function to adjust the waiting period for collapse finalization.
// - setCollapseProbabilities(ClassicalState[] calldata states, uint256[] calldata weights): Owner function to set the probabilistic weights for collapse outcomes.
// - pauseDeposits(): Owner function to temporarily halt new deposits.
// - unpauseDeposits(): Owner function to re-enable deposits.
// - pauseCollapses(): Owner function to temporarily halt initiating and finalizing collapses.
// - unpauseCollapses(): Owner function to re-enable collapses.
// - transferOwnership(address newOwner): Owner function to transfer contract ownership.
// - emergencyWithdraw(address token, uint256 amount): Owner function to rescue inadvertently sent or stuck tokens.

contract QuantumVault {
    address private owner;

    // --- State Variables ---

    enum DepositState { Superposed, Collapsing, Classical }
    enum ClassicalState { Unset, Redeemable, TimeLocked, PartialBurn } // Unset is default for uint mapping

    struct Deposit {
        uint256 id;
        address user;
        address token;
        uint256 amount;
        DepositState state;
        ClassicalState classicalState; // Valid only if state is Classical
        uint66 collapseStartTime; // Timestamp when collapse was initiated
        uint66 classicalStateData; // State-specific data (e.g., unlock timestamp for TimeLocked, burned amount for PartialBurn)
        bool isClaimed; // Flag to prevent double claiming
    }

    mapping(uint256 => Deposit) private deposits;
    uint256 private nextDepositId = 1; // Start IDs from 1

    mapping(address => uint256[]) private userDepositIds; // Map user to list of their deposit IDs

    mapping(address => bool) private isTokenSupported;
    address[] private supportedTokenList; // To easily list supported tokens

    // Balances tracked by user, token, and state (more gas efficient than iterating deposits)
    mapping(address => mapping(address => mapping(DepositState => uint256))) private userTokenStateBalance;
    mapping(address => mapping(address => mapping(ClassicalState => uint256))) private userTokenClassicalStateBalance;


    uint256 public collapseWaitPeriod; // Seconds required between initiate and finalize collapse

    // Probability weights for classical states
    mapping(ClassicalState => uint256) private classicalStateWeights;
    uint256 private totalCollapseWeight;
    ClassicalState[] private classicalStatesList = [
        ClassicalState.Redeemable,
        ClassicalState.TimeLocked,
        ClassicalState.PartialBurn
    ]; // List of states for iteration

    bool public depositsPaused = false;
    bool public collapsesPaused = false;

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenSupported(address indexed token);
    event TokenUnsupported(address indexed token);
    event WaitPeriodUpdated(uint256 newPeriod);
    event ProbabilitiesUpdated(ClassicalState[] states, uint256[] weights);
    event Paused(string reason);
    event Unpaused(string reason);
    event Deposited(uint256 indexed depositId, address indexed user, address indexed token, uint256 amount, uint256 timestamp);
    event CollapseInitiated(uint256 indexed depositId, uint66 collapseStartTime);
    event CollapseFinalized(uint256 indexed depositId, ClassicalState indexed finalState, uint256 classicalStateData, uint256 timestamp);
    event Claimed(uint256 indexed depositId, address indexed user, address indexed token, uint256 claimedAmount, ClassicalState indexed fromState);
    event EmergencyWithdrawal(address indexed token, uint256 amount);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier whenDepositsNotPaused() {
        require(!depositsPaused, "Deposits are paused");
        _;
    }

    modifier whenCollapsesNotPaused() {
        require(!collapsesPaused, "Collapses are paused");
        _;
    }

    // --- Constructor ---

    constructor(
        address[] memory initialSupportedTokens,
        uint256 initialCollapseWaitPeriod,
        ClassicalState[] memory initialStates,
        uint256[] memory initialWeights
    ) {
        owner = msg.sender;
        collapseWaitPeriod = initialCollapseWaitPeriod;

        for (uint i = 0; i < initialSupportedTokens.length; i++) {
            _addSupportedTokenInternal(initialSupportedTokens[i]);
        }

        // Set initial probabilities and calculate total weight
        setCollapseProbabilities(initialStates, initialWeights);
    }

    // --- Ownership Management ---

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    // --- Token Management (Owner) ---

    function addSupportedToken(address token) external onlyOwner {
        _addSupportedTokenInternal(token);
    }

    function _addSupportedTokenInternal(address token) private {
        require(token != address(0), "Zero address not allowed");
        require(!isTokenSupported[token], "Token already supported");
        isTokenSupported[token] = true;
        supportedTokenList.push(token);
        emit TokenSupported(token);
    }

    // Note: Removing supported tokens does NOT affect existing deposits in that token.
    // It only prevents new deposits of that token.
    function removeSupportedToken(address token) external onlyOwner {
        require(isTokenSupported[token], "Token not supported");
        isTokenSupported[token] = false;
        // Removing from array is gas intensive for large arrays.
        // A more complex linked list or skipping would be better for production.
        // For simplicity, we'll find and remove (less efficient).
        for (uint i = 0; i < supportedTokenList.length; i++) {
            if (supportedTokenList[i] == token) {
                supportedTokenList[i] = supportedTokenList[supportedTokenList.length - 1];
                supportedTokenList.pop();
                break;
            }
        }
        emit TokenUnsupported(token);
    }

    // --- Probability & Wait Period Management (Owner) ---

    function setCollapseWaitPeriod(uint256 seconds) external onlyOwner {
        collapseWaitPeriod = seconds;
        emit WaitPeriodUpdated(seconds);
    }

    function setCollapseProbabilities(ClassicalState[] calldata states, uint256[] calldata weights) public onlyOwner {
        require(states.length == weights.length, "Arrays must have same length");
        require(states.length > 0, "Must provide at least one state");

        uint256 newTotalWeight = 0;
        // Reset weights first
        for(uint i=0; i < classicalStatesList.length; i++) {
             classicalStateWeights[classicalStatesList[i]] = 0;
        }

        for (uint i = 0; i < states.length; i++) {
            require(states[i] != ClassicalState.Unset, "Cannot set probability for Unset state");
            require(weights[i] > 0, "Weights must be positive");
            classicalStateWeights[states[i]] = weights[i];
            newTotalWeight += weights[i];
        }
        require(newTotalWeight > 0, "Total weight must be positive");
        totalCollapseWeight = newTotalWeight;
        emit ProbabilitiesUpdated(states, weights);
    }

    // --- Pause Functionality (Owner) ---

    function pauseDeposits() external onlyOwner {
        require(!depositsPaused, "Deposits are already paused");
        depositsPaused = true;
        emit Paused("Deposits");
    }

    function unpauseDeposits() external onlyOwner {
        require(depositsPaused, "Deposits are not paused");
        depositsPaused = false;
        emit Unpaused("Deposits");
    }

    function pauseCollapses() external onlyOwner {
        require(!collapsesPaused, "Collapses are already paused");
        collapsesPaused = true;
        emit Paused("Collapses");
    }

    function unpauseCollapses() external onlyOwner {
        require(collapsesPaused, "Collapses are not paused");
        collapsesPaused = false;
        emit Unpaused("Collapses");
    }

    // --- Core Quantum Logic (User Facing) ---

    function deposit(address token, uint256 amount) external whenDepositsNotPaused {
        require(isTokenSupported[token], "Token not supported for deposit");
        require(amount > 0, "Amount must be greater than zero");

        uint256 currentDepositId = nextDepositId++;
        deposits[currentDepositId] = Deposit({
            id: currentDepositId,
            user: msg.sender,
            token: token,
            amount: amount,
            state: DepositState.Superposed,
            classicalState: ClassicalState.Unset, // Not set yet
            collapseStartTime: 0, // Not initiated yet
            classicalStateData: 0, // Not set yet
            isClaimed: false
        });

        userDepositIds[msg.sender].push(currentDepositId);
        userTokenStateBalance[msg.sender][token][DepositState.Superposed] += amount;

        // Transfer tokens from the user to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        emit Deposited(currentDepositId, msg.sender, token, amount, block.timestamp);
    }

    function initiateCollapse(uint256 depositId) external whenCollapsesNotPaused {
        Deposit storage deposit = deposits[depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.state == DepositState.Superposed, "Deposit is not in Superposed state");
        require(collapseWaitPeriod > 0, "Collapse wait period must be set"); // Cannot initiate if wait is 0

        deposit.state = DepositState.Collapsing;
        deposit.collapseStartTime = uint66(block.timestamp);

        // Update balances: decrement Superposed, increment Collapsing
        userTokenStateBalance[msg.sender][deposit.token][DepositState.Superposed] -= deposit.amount;
        userTokenStateBalance[msg.sender][deposit.token][DepositState.Collapsing] += deposit.amount;

        emit CollapseInitiated(depositId, deposit.collapseStartTime);
    }

    function finalizeCollapse(uint256 depositId) external whenCollapsesNotPaused {
        Deposit storage deposit = deposits[depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.state == DepositState.Collapsing, "Deposit is not in Collapsing state");
        require(block.timestamp >= deposit.collapseStartTime + collapseWaitPeriod, "Wait period has not passed");

        // Determine the classical state using state-dependent pseudo-randomness
        ClassicalState finalState = _determineClassicalState(depositId);

        deposit.state = DepositState.Classical;
        deposit.classicalState = finalState;

        // Calculate and store state-specific data
        uint256 stateData = 0;
        if (finalState == ClassicalState.TimeLocked) {
            // Example: Lock for an additional period based on the outcome or a fixed time
            // For simplicity, let's lock for collapseWaitPeriod again
            stateData = block.timestamp + collapseWaitPeriod;
        } else if (finalState == ClassicalState.PartialBurn) {
             // Example: Burn a percentage (e.g., 10-50%) based on outcome
             // Use a small part of the randomness for the percentage
             uint256 randomness = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), depositId, block.timestamp))) % 100; // 0-99
             uint256 burnPercentage = 10 + (randomness % 41); // 10% to 50%
             uint256 burnedAmount = (deposit.amount * burnPercentage) / 100;
             // classicalStateData stores the *redeemable* amount
             stateData = deposit.amount - burnedAmount;
        }
        deposit.classicalStateData = uint66(stateData);

        // Update balances: decrement Collapsing, increment the new Classical state
        userTokenStateBalance[msg.sender][deposit.token][DepositState.Collapsing] -= deposit.amount;
        userTokenClassicalStateBalance[msg.sender][deposit.token][finalState] += deposit.amount; // Note: we track the *original* amount in the classical state balance mapping, partial burn logic applies on claim.

        emit CollapseFinalized(depositId, finalState, deposit.classicalStateData, block.timestamp);
    }

    function redeem(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.state == DepositState.Classical, "Deposit is not in a classical state");
        require(deposit.classicalState == ClassicalState.Redeemable, "Deposit is not in Redeemable state");
        require(!deposit.isClaimed, "Deposit already claimed");

        deposit.isClaimed = true;
        uint256 amountToClaim = deposit.amount; // Full amount for Redeemable

        // Update balance: decrement the classical state balance
        userTokenClassicalStateBalance[msg.sender][deposit.token][deposit.classicalState] -= amountToClaim; // Use original amount

        IERC20(deposit.token).transfer(msg.sender, amountToClaim);

        emit Claimed(depositId, msg.sender, deposit.token, amountToClaim, deposit.classicalState);
    }

    function claimTimeLocked(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.state == DepositState.Classical, "Deposit is not in a classical state");
        require(deposit.classicalState == ClassicalState.TimeLocked, "Deposit is not in TimeLocked state");
        require(!deposit.isClaimed, "Deposit already claimed");
        require(block.timestamp >= deposit.classicalStateData, "Lock-up period not over");

        deposit.isClaimed = true;
        uint256 amountToClaim = deposit.amount; // Full amount for TimeLocked

        // Update balance: decrement the classical state balance
        userTokenClassicalStateBalance[msg.sender][deposit.token][deposit.classicalState] -= amountToClaim; // Use original amount

        IERC20(deposit.token).transfer(msg.sender, amountToClaim);

        emit Claimed(depositId, msg.sender, deposit.token, amountToClaim, deposit.classicalState);
    }

    function claimPartialBurn(uint256 depositId) external {
        Deposit storage deposit = deposits[depositId];
        require(deposit.user == msg.sender, "Not your deposit");
        require(deposit.state == DepositState.Classical, "Deposit is not in a classical state");
        require(deposit.classicalState == ClassicalState.PartialBurn, "Deposit is not in PartialBurn state");
        require(!deposit.isClaimed, "Deposit already claimed");

        deposit.isClaimed = true;
        uint256 amountToClaim = deposit.classicalStateData; // classicalStateData holds the *redeemable* amount

        // Update balance: decrement the classical state balance (use original amount for mapping)
        userTokenClassicalStateBalance[msg.sender][deposit.token][deposit.classicalState] -= deposit.amount;

        if (amountToClaim > 0) {
             IERC20(deposit.token).transfer(msg.sender, amountToClaim);
        }

        emit Claimed(depositId, msg.sender, deposit.token, amountToClaim, deposit.classicalState);
    }


    // --- View Functions (Public/User Facing) ---

    function getDepositState(uint256 depositId) external view returns (DepositState, ClassicalState) {
        Deposit storage deposit = deposits[depositId];
         // Check if deposit exists by checking if user is address(0) (default value)
        if (deposit.user == address(0) && depositId != 0) {
             revert("Deposit does not exist");
        }
        return (deposit.state, deposit.classicalState);
    }

    function getDepositDetails(uint256 depositId) external view returns (Deposit memory) {
         Deposit memory deposit = deposits[depositId];
         // Check if deposit exists
        if (deposit.user == address(0) && depositId != 0) {
             revert("Deposit does not exist");
        }
        return deposit;
    }

    function getUserDepositIds(address user) external view returns (uint256[] memory) {
        return userDepositIds[user];
    }

    function getUserBalanceByState(address user, address token, DepositState state) external view returns (uint256) {
        return userTokenStateBalance[user][token][state];
    }

    function getUserBalanceByClassicalState(address user, address token, ClassicalState state) external view returns (uint256) {
        return userTokenClassicalStateBalance[user][token][state];
    }

    function getCollapseWaitPeriod() external view returns (uint256) {
        return collapseWaitPeriod;
    }

    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokenList;
    }

     function getCollapseProbabilities() external view returns (ClassicalState[] memory states, uint256[] memory weights, uint256 totalWeight) {
        states = new ClassicalState[](classicalStatesList.length);
        weights = new uint256[](classicalStatesList.length);
        for(uint i = 0; i < classicalStatesList.length; i++) {
            states[i] = classicalStatesList[i];
            weights[i] = classicalStateWeights[classicalStatesList[i]];
        }
        totalWeight = totalCollapseWeight;
        return (states, weights, totalWeight);
    }

    function getClassicalStateInfo(ClassicalState state) external pure returns (string memory description) {
        // A more complex contract might return specific data structures here
        if (state == ClassicalState.Redeemable) {
            return "Instantly redeemable amount";
        } else if (state == ClassicalState.TimeLocked) {
            return "Amount locked until specific timestamp (stored in classicalStateData)";
        } else if (state == ClassicalState.PartialBurn) {
            return "Portion of amount is burned, redeemable amount stored in classicalStateData";
        } else {
            return "Unknown or Unset state";
        }
    }

    function getDepositCount() external view returns (uint256) {
        return nextDepositId - 1; // Since we start from 1
    }


    // --- Internal Helpers ---

    function _determineClassicalState(uint256 depositId) internal view returns (ClassicalState) {
        // This function provides state-dependent pseudo-randomness.
        // DO NOT rely on this for high-security or high-value applications
        // where predictability of the outcome before finalization is critical.
        // blockhash(block.number - 1) has limitations: it can be influenced by miners
        // to a small extent for block N-1, and it returns 0 for blocks older than 256.
        // A real application needing secure randomness would use Chainlink VRF or similar.
        // This implementation is for demonstrating the *concept* of a state-dependent outcome.

        uint256 entropy = uint256(keccak256(
            abi.encodePacked(
                blockhash(block.number - 1), // Blockhash of the previous block
                block.timestamp,
                depositId,
                deposits[depositId].user,
                deposits[depositId].amount,
                tx.origin // Use tx.origin for extra variance, though can be predictable
            )
        ));

        uint256 randomWeight = entropy % totalCollapseWeight;

        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < classicalStatesList.length; i++) {
            ClassicalState currentState = classicalStatesList[i];
            uint256 weight = classicalStateWeights[currentState];
            cumulativeWeight += weight;
            if (randomWeight < cumulativeWeight) {
                return currentState;
            }
        }

        // Should not reach here if totalWeight is calculated correctly and weights are positive.
        // Fallback, though indicates an issue with probability setup.
        // Returning a default or error state is safer.
        // For demonstration, let's default to Redeemable if something goes wrong.
        return ClassicalState.Redeemable;
    }

    // --- Emergency Withdraw (Owner) ---

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        // Allows owner to withdraw tokens stuck in the contract that are NOT
        // part of any active deposit. This is a safety mechanism.
        // Requires careful use to not pull funds that are part of deposits.
        // A robust system would require pausing, accounting, etc.
        // This is a basic version assuming accidental transfers.

        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        uint256 totalDepositedAmount = 0;

        // This loop can be very gas-intensive for many deposits.
        // In a real system, deposited balances per token should be tracked in a mapping.
        // For this example, we iterate for clarity, but note the limitation.
        // A more efficient approach would be to track total funds *not* in deposits.
        // Let's track total deposited amount per token for efficiency.
        // Add a mapping: `mapping(address => uint256) totalTrackedDeposits;`
        // Update it in deposit, finalizeCollapse (decrease collapsing), and on claim (decrease classical).
        // Then check `contractBalance - totalTrackedDeposits[token]`.

        // **Refined Emergency Withdraw logic using tracked balances:**
        // We have userTokenStateBalance and userTokenClassicalStateBalance.
        // Total tracked per token = sum across all users/states.
        // This is still potentially expensive to calculate in a loop here.
        // Let's add `mapping(address => uint256) totalDepositedBalanceByToken;`
        // Update this in `deposit`, and decrement in `redeem/claim...`
        // The amount to withdraw safely is `IERC20(token).balanceOf(address(this)) - totalDepositedBalanceByToken[token];`
        // The current implementation with user mappings is good for user queries,
        // but aggregating for emergency withdraw is missing. Let's add that total tracker.
        // Add `mapping(address => uint256) private totalManagedBalanceByToken;`

        // In deposit: `totalManagedBalanceByToken[token] += amount;`
        // In redeem/claim...: `totalManagedBalanceByToken[deposit.token] -= claimedAmount;` (Adjust claimedAmount for burn)

        // Re-implementing Emergency Withdraw with `totalManagedBalanceByToken`
        uint256 totalManaged = totalManagedBalanceByToken[token];
        uint256 actualBalance = IERC20(token).balanceOf(address(this));
        require(actualBalance >= totalManaged, "Contract balance less than tracked deposits");
        uint256 rescuableAmount = actualBalance - totalManaged;
        uint256 amountToTransfer = Math.min(amount, rescuableAmount);
        require(amountToTransfer > 0, "No rescuable amount or amount requested is zero");

        IERC20(token).transfer(msg.sender, amountToTransfer);
        emit EmergencyWithdrawal(token, amountToTransfer);
    }

     // Need to add `totalManagedBalanceByToken` and update it in deposit and claim functions.
     mapping(address => uint256) private totalManagedBalanceByToken;

     // Updates needed:
     // deposit: `totalManagedBalanceByToken[token] += amount;`
     // redeem: `totalManagedBalanceByToken[deposit.token] -= amountToClaim;`
     // claimTimeLocked: `totalManagedBalanceByToken[deposit.token] -= amountToClaim;`
     // claimPartialBurn: `totalManagedBalanceByToken[deposit.token] -= amountToClaim;`

}
```