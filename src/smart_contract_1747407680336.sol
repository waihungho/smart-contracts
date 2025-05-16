Okay, here is a Solidity smart contract incorporating various advanced, creative, and trendy concepts, designed *not* to be a direct copy of standard open-source templates like ERC-20, ERC-721, basic staking, or simple vaults.

This contract, `QuantumFusionVault`, aims to manage deposited assets (ETH, ERC-20, ERC-721) with complex state transitions, yield generation based on those states, conditional interactions (fusion, entanglement), oracle dependencies, and advanced owner controls.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// --- Outline and Function Summary ---
//
// Contract Name: QuantumFusionVault
// Purpose: A multi-asset vault (ETH, ERC-20, ERC-721) with advanced state transition logic,
//          conditional yield generation, deposit interaction mechanics (Fusion, Entanglement),
//          oracle dependencies, and sophisticated owner controls. It's designed to be a
//          complex system where the state and behavior of deposited assets evolve.
//
// Key Concepts:
// - Multi-Asset Handling: Supports ETH, ERC-20, and ERC-721 deposits/withdrawals.
// - Quantum States: Deposits exist in defined states (Initial, TimeLocked, ConditionMet,
//                   Fused, Entangled, Volatile, Degraded) influencing their behavior.
// - State Transitions: States change based on time elapsed, oracle data conditions,
//                      manual owner intervention, or specific deposit interactions (Fusion, Entanglement).
// - Rule-Based Transitions: Owner defines rules for state changes based on conditions.
// - Conditional Yield: Accrued yield (conceptual, represented by claimable amount) depends on the current state.
// - Deposit Interactions:
//   - Fusion: Combining two eligible deposits transitions them to a "Fused" state, potentially unlocking features.
//   - Entanglement: Linking two deposits so their state transitions can influence each other.
// - Oracle Dependency: State transitions can be contingent on external data fetched via an oracle feed.
// - Advanced Controls: Pausability, Emergency Withdrawal, Delayed Self-Destruct, Rule configuration.
//
// State Variables:
// - depositCounter: Unique ID for each deposit.
// - deposits: Mapping from depositId to Deposit struct.
// - userDeposits: Mapping from user address to list of their depositIds.
// - totalValueLocked: Mapping from AssetType to total amount/count locked.
// - stateTransitionRules: Mapping from (currentState, targetState) to TransitionRule struct.
// - yieldRates: Mapping from DepositState to yield rate (conceptual).
// - oracleData: Mapping from conditionKey (bytes32) to current oracle value (int256).
// - oracleFeeds: Mapping from conditionKey to oracle feed address.
// - selfDestructInitiatedAt: Timestamp when self-destruct was initiated (0 if not).
// - selfDestructDelay: Required delay before self-destruct can be confirmed.
//
// Enums:
// - AssetType: ETH, ERC20, ERC721.
// - DepositState: INITIAL, TIME_LOCKED, CONDITION_MET, FUSED, ENTANGLED, VOLATILE, DEGRADED.
// - ConditionType: NONE, TIME_ELAPSED, ORACLE_VALUE_GT, ORACLE_VALUE_LT, ORACLE_VALUE_EQ, IS_ENTANGLED, IS_FUSION_ELIGIBLE.
//
// Structs:
// - Deposit: Details of a single deposit (owner, asset, amount, state, timestamps, linked deposits).
// - TransitionRule: Defines conditions required to move from one state to another.
//
// Events:
// - DepositReceived: Logs new deposits.
// - WithdrawalExecuted: Logs withdrawals.
// - StateTransition: Logs changes in deposit state.
// - YieldClaimed: Logs claimable yield.
// - DepositsFused: Logs fusion events.
// - DepositsEntangled: Logs entanglement events.
// - TransitionRuleSet: Logs setting of new rules.
// - YieldRateSet: Logs setting of yield rates.
// - OracleFeedSet: Logs setting oracle feeds.
// - OracleDataUpdated: Logs updates to internal oracle data state.
// - EmergencyWithdrawal: Logs emergency withdrawals.
// - Paused/Unpaused: Logs pause status changes.
// - SelfDestructInitiated/Confirmed: Logs self-destruct process.
//
// Functions (Total: 25+):
// 1.  constructor(): Initializes the contract (Ownable).
// 2.  receive(): Fallback for receiving ETH deposits.
// 3.  depositETH(): Handles ETH deposits.
// 4.  depositERC20(): Handles ERC-20 deposits.
// 5.  depositERC721(): Handles ERC-721 deposits.
// 6.  getDepositState(): View function to get current state of a deposit.
// 7.  getDepositDetails(): View function to get full details of a deposit.
// 8.  checkAndTransitionState(): Allows anyone to trigger a state transition check for a deposit if rules are met.
// 9.  batchCheckAndTransitionStates(): Allows anyone to trigger state checks for multiple deposits.
// 10. ownerForceTransitionState(): Owner can override rules to force a state change.
// 11. withdrawETH(): Allows withdrawal of ETH deposit based on its state.
// 12. withdrawERC20(): Allows withdrawal of ERC-20 deposit based on its state.
// 13. withdrawERC721(): Allows withdrawal of ERC-721 deposit based on its state.
// 14. partialWithdrawETH(): Allows partial withdrawal of ETH in specific states.
// 15. claimAccruedYield(): Allows claiming conceptual yield based on deposit state and duration.
// 16. fuseDeposits(): Attempts to fuse two eligible deposits, transitioning them to FUSED state.
// 17. entangleDeposits(): Attempts to entangle two deposits, linking their state transitions.
// 18. disentangleDeposit(): Breaks entanglement for a deposit.
// 19. setTransitionRule(): Owner sets rules for state transitions.
// 20. setYieldRate(): Owner sets conceptual yield rates per state.
// 21. setOracleFeedAddress(): Owner sets address for an oracle data feed for a condition key.
// 22. updateOracleData(): Callable by owner/keeper to update internal oracle data based on external feeds.
// 23. emergencyWithdrawAllAssets(): Owner can withdraw all assets of a specific type in emergencies.
// 24. initiateSelfDestruct(): Owner starts the self-destruct process with a delay.
// 25. confirmSelfDestruct(): Owner confirms self-destruct after the delay.
// 26. getUserDeposits(): View function to get list of a user's deposit IDs.
// 27. getTotalValueLocked(): View function for total value locked per asset type.
// 28. pause(): Owner pauses contract interactions.
// 29. unpause(): Owner unpauses contract interactions.
// --- End of Outline and Summary ---

contract QuantumFusionVault is Ownable, ReentrancyGuard {
    using Address for address payable;
    using Address for address;

    enum AssetType {
        ETH,
        ERC20,
        ERC721
    }

    enum DepositState {
        INITIAL,         // Default state upon deposit
        TIME_LOCKED,     // Locked for a minimum duration
        CONDITION_MET,   // Met specific criteria (e.g., oracle value)
        FUSED,           // Result of combining two eligible deposits
        ENTANGLED,       // Linked to another deposit
        VOLATILE,        // Higher potential yield but also risk/fees
        DEGRADED         // Penalty state, limited functionality
    }

    enum ConditionType {
        NONE,                  // No specific condition
        TIME_ELAPSED,          // Minimum time must have passed
        ORACLE_VALUE_GT,       // Oracle value Greater Than a threshold
        ORACLE_VALUE_LT,       // Oracle value Less Than a threshold
        ORACLE_VALUE_EQ,       // Oracle value Equal to a value
        IS_ENTANGLED,          // Deposit must be entangled
        IS_FUSION_ELIGIBLE     // Deposit meets criteria for fusion (internal check)
    }

    struct Deposit {
        address payable owner;
        AssetType assetType;
        address tokenAddress; // 0x0 for ETH
        uint256 tokenId;      // 0 for ERC20/ETH
        uint256 amount;       // For ETH/ERC20, or count (always 1) for ERC721
        DepositState currentState;
        uint256 timestamp; // Time of deposit
        uint256 lastStateChangeTimestamp;
        uint256 lastYieldClaimTimestamp;
        uint256 entangledDepositId; // 0 if not entangled
    }

    struct TransitionRule {
        DepositState targetState;
        ConditionType conditionType;
        uint256 conditionValue; // e.g., minimum time, oracle threshold
        bytes32 oracleConditionKey; // Key for oracleData mapping
        bool requiresEntanglement;
        bool requiresFusionEligibility; // Internal flag, not a rule trigger itself, but affects eligibility
    }

    uint256 private depositCounter;
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) private userDeposits; // Stores depositIds for each user

    mapping(AssetType => uint256) private totalValueLocked; // Sum of amounts for ETH/ERC20, count for ERC721

    // Mapping: fromState -> toState -> rule
    mapping(DepositState => mapping(DepositState => TransitionRule)) public stateTransitionRules;

    // Mapping: DepositState -> yield rate (per second, scaled)
    mapping(DepositState => uint256) public yieldRates; // Example: rate is scaled by 1e18

    // Mapping: conditionKey -> current oracle value
    mapping(bytes32 => int256) public oracleData;
    // Mapping: conditionKey -> oracle feed address (for reference, updating needs off-chain logic or keeper)
    mapping(bytes32 => address) public oracleFeeds;

    uint256 public selfDestructInitiatedAt;
    uint256 public selfDestructDelay;

    bool public paused;

    event DepositReceived(uint256 indexed depositId, address indexed owner, AssetType assetType, address tokenAddress, uint256 tokenId, uint256 amount);
    event WithdrawalExecuted(uint256 indexed depositId, address indexed owner, AssetType assetType, uint256 amount);
    event StateTransition(uint256 indexed depositId, DepositState indexed fromState, DepositState indexed toState, string reason);
    event YieldClaimed(uint256 indexed depositId, address indexed owner, uint256 amount);
    event DepositsFused(uint256 indexed depositId1, uint256 indexed depositId2, address indexed initiator);
    event DepositsEntangled(uint256 indexed depositId1, uint256 indexed depositId2, address indexed initiator);
    event DepositDisentangled(uint256 indexed depositId);
    event TransitionRuleSet(DepositState indexed fromState, DepositState indexed toState, ConditionType conditionType);
    event YieldRateSet(DepositState indexed state, uint256 rate);
    event OracleFeedSet(bytes32 indexed conditionKey, address indexed feedAddress);
    event OracleDataUpdated(bytes32 indexed conditionKey, int256 value);
    event EmergencyWithdrawal(AssetType indexed assetType, address indexed recipient, uint256 amountOrCount);
    event Paused(address account);
    event Unpaused(address account);
    event SelfDestructInitiated(uint256 timestamp, uint256 delay);
    event SelfDestructConfirmed(address indexed beneficiary);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    modifier selfDestructNotInitiated() {
        require(selfDestructInitiatedAt == 0, "Self-destruct initiated");
        _;
    }

    constructor() Ownable(msg.sender) {
        depositCounter = 0;
        paused = false;
        selfDestructInitiatedAt = 0;
        selfDestructDelay = 0; // Default no delay, owner must set > 0 to use delayed self-destruct
    }

    // --- Deposit Functions ---

    receive() external payable whenNotPaused selfDestructNotInitiated {
        depositETH();
    }

    /// @notice Deposits Ether into the vault.
    function depositETH() public payable whenNotPaused selfDestructNotInitiated nonReentrant {
        require(msg.value > 0, "ETH amount must be > 0");
        _createDeposit(msg.sender, AssetType.ETH, address(0), 0, msg.value);
        totalValueLocked[AssetType.ETH] += msg.value;
    }

    /// @notice Deposits an ERC-20 token into the vault.
    /// @param token The address of the ERC-20 token.
    /// @param amount The amount of the ERC-20 token to deposit.
    function depositERC20(address token, uint256 amount) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Amount must be > 0");
        IERC20 tokenContract = IERC20(token);
        require(tokenContract.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");

        _createDeposit(msg.sender, AssetType.ERC20, token, 0, amount);
        totalValueLocked[AssetType.ERC20] += amount;
    }

    /// @notice Deposits an ERC-721 token (NFT) into the vault.
    /// @param nftContract The address of the ERC-721 contract.
    /// @param tokenId The ID of the NFT to deposit.
    function depositERC721(address nftContract, uint256 tokenId) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(nftContract != address(0), "Invalid NFT contract address");
        IERC721 nftContractInstance = IERC721(nftContract);
        require(nftContractInstance.ownerOf(tokenId) == msg.sender, "Caller is not NFT owner");
        nftContractInstance.safeTransferFrom(msg.sender, address(this), tokenId);

        _createDeposit(msg.sender, AssetType.ERC721, nftContract, tokenId, 1); // Amount is always 1 for ERC721
        totalValueLocked[AssetType.ERC721]++;
    }

    /// @dev Internal function to create a new deposit record.
    function _createDeposit(
        address owner,
        AssetType assetType,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        depositCounter++;
        uint256 currentDepositId = depositCounter;
        uint256 currentTime = block.timestamp;

        deposits[currentDepositId] = Deposit({
            owner: payable(owner),
            assetType: assetType,
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            amount: amount,
            currentState: DepositState.INITIAL,
            timestamp: currentTime,
            lastStateChangeTimestamp: currentTime,
            lastYieldClaimTimestamp: currentTime,
            entangledDepositId: 0
        });

        userDeposits[owner].push(currentDepositId);

        emit DepositReceived(currentDepositId, owner, assetType, tokenAddress, tokenId, amount);
    }

    // --- View Functions ---

    /// @notice Gets the current state of a specific deposit.
    /// @param depositId The ID of the deposit.
    /// @return The current state of the deposit.
    function getDepositState(uint256 depositId) public view returns (DepositState) {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        return deposits[depositId].currentState;
    }

     /// @notice Gets the full details of a specific deposit.
     /// @param depositId The ID of the deposit.
     /// @return A tuple containing all deposit details.
     function getDepositDetails(uint256 depositId)
        public view
        returns (
            address owner,
            AssetType assetType,
            address tokenAddress,
            uint256 tokenId,
            uint256 amount,
            DepositState currentState,
            uint256 timestamp,
            uint256 lastStateChangeTimestamp,
            uint256 lastYieldClaimTimestamp,
            uint256 entangledDepositId
        )
    {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        Deposit storage d = deposits[depositId];
        return (
            d.owner,
            d.assetType,
            d.tokenAddress,
            d.tokenId,
            d.amount,
            d.currentState,
            d.timestamp,
            d.lastStateChangeTimestamp,
            d.lastYieldClaimTimestamp,
            d.entangledDepositId
        );
    }


    /// @notice Gets the list of deposit IDs owned by an address.
    /// @param account The address to query.
    /// @return An array of deposit IDs.
    function getUserDeposits(address account) public view returns (uint256[] memory) {
        return userDeposits[account];
    }

    /// @notice Gets the total value locked for a specific asset type.
    /// @param assetType The type of asset (ETH, ERC20, ERC721).
    /// @return The total amount (for ETH/ERC20) or count (for ERC721) locked.
    function getTotalValueLocked(AssetType assetType) public view returns (uint256) {
        return totalValueLocked[assetType];
    }

    // --- State Transition & Logic Functions ---

    /// @notice Attempts to transition the state of a deposit based on defined rules.
    /// Callable by anyone (e.g., keeper).
    /// @param depositId The ID of the deposit to check.
    function checkAndTransitionState(uint256 depositId) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        Deposit storage d = deposits[depositId];
        DepositState currentState = d.currentState;

        // Check potential transitions from the current state
        for (uint8 i = 0; i < uint8(DepositState.DEGRADED) + 1; i++) {
            DepositState targetState = DepositState(i);
            TransitionRule memory rule = stateTransitionRules[currentState][targetState];

            // Check if a rule exists for this transition
            if (rule.targetState == targetState) {
                 if (_checkRuleCondition(d, rule)) {
                    _transitionState(depositId, targetState, "Rule Met");
                    // Break after first successful transition to a new state based on rule priority implicitly set by loop order
                    break;
                }
            }
        }
    }

    /// @notice Attempts to transition states for a batch of deposits.
    /// Callable by anyone (e.g., keeper).
    /// @param depositIds An array of deposit IDs to check.
    function batchCheckAndTransitionStates(uint256[] calldata depositIds) external whenNotPaused selfDestructNotInitiated nonReentrant {
        for (uint i = 0; i < depositIds.length; i++) {
            // Use try/catch to handle potential errors in individual checks without stopping the batch
            try this.checkAndTransitionState(depositIds[i]) {} catch {}
        }
    }


    /// @dev Internal helper to check if a deposit meets the condition for a rule.
    function _checkRuleCondition(Deposit storage d, TransitionRule memory rule) internal view returns (bool) {
        if (rule.conditionType == ConditionType.NONE) {
            return true; // Always true if no specific condition
        }
        if (rule.requiresEntanglement && d.entangledDepositId == 0) {
            return false; // Requires entanglement but isn't
        }
        // requiresFusionEligibility check is typically for *becoming* eligible, not a transition *condition* itself.
        // We can add a flag to Deposit struct if needed for this. For now, it's informational.

        uint256 currentTime = block.timestamp;

        if (rule.conditionType == ConditionType.TIME_ELAPSED) {
            return currentTime >= d.lastStateChangeTimestamp + rule.conditionValue; // conditionValue is duration in seconds
        }
        if (rule.oracleConditionKey != bytes32(0)) {
            int256 oracleValue = oracleData[rule.oracleConditionKey];
            // Check oracle value conditions only if key is set and oracle data exists (non-zero, or handle sentinel values)
            if (rule.conditionType == ConditionType.ORACLE_VALUE_GT) {
                 return oracleValue > int256(rule.conditionValue);
            }
            if (rule.conditionType == ConditionType.ORACLE_VALUE_LT) {
                return oracleValue < int256(rule.conditionValue);
            }
            if (rule.conditionType == ConditionType.ORACLE_VALUE_EQ) {
                 return oracleValue == int256(rule.conditionValue);
            }
        }

        // Add checks for other ConditionTypes if implemented

        return false; // Condition not met or not recognized
    }

    /// @dev Internal function to perform a state transition.
    function _transitionState(uint256 depositId, DepositState newState, string memory reason) internal {
        Deposit storage d = deposits[depositId];
        require(d.currentState != newState, "Already in target state");
        DepositState oldState = d.currentState;
        d.currentState = newState;
        d.lastStateChangeTimestamp = block.timestamp;
        emit StateTransition(depositId, oldState, newState, reason);

        // If Entangled, attempt to trigger state check on the linked deposit
        if (d.entangledDepositId != 0) {
             // Use low-level call to avoid blocking if linked deposit check fails
             (bool success,) = address(this).call(abi.encodeWithSignature("checkAndTransitionState(uint256)", d.entangledDepositId));
             // Log or handle failure if necessary, but don't revert the primary transition
             if (!success) {
                 // Optionally emit a warning event or log
             }
        }
    }

    /// @notice Owner can force a deposit into a specific state, bypassing rules.
    /// @param depositId The ID of the deposit.
    /// @param newState The state to force the deposit into.
    function ownerForceTransitionState(uint256 depositId, DepositState newState) public onlyOwner whenNotPaused selfDestructNotInitiated {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        _transitionState(depositId, newState, "Owner Forced");
    }

    // --- Withdrawal Functions ---

    /// @notice Allows withdrawal of ETH deposit if its state permits.
    /// Only FUSED state is allowed in this example implementation.
    /// @param depositId The ID of the deposit.
    function withdrawETH(uint256 depositId) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        Deposit storage d = deposits[depositId];
        require(msg.sender == d.owner, "Not deposit owner");
        require(d.assetType == AssetType.ETH, "Deposit is not ETH");

        // Example: Only allow withdrawal from FUSED state
        require(d.currentState == DepositState.FUSED, "Deposit state does not allow withdrawal");

        uint256 amount = d.amount;
        require(amount > 0, "No ETH balance to withdraw");

        // Mark deposit as withdrawn/spent
        _cleanupDeposit(depositId);

        totalValueLocked[AssetType.ETH] -= amount;
        payable(d.owner).sendValue(amount);

        emit WithdrawalExecuted(depositId, d.owner, d.assetType, amount);
    }

    /// @notice Allows withdrawal of ERC-20 deposit if its state permits.
    /// Only FUSED state is allowed in this example implementation.
    /// @param depositId The ID of the deposit.
    function withdrawERC20(uint256 depositId) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        Deposit storage d = deposits[depositId];
        require(msg.sender == d.owner, "Not deposit owner");
        require(d.assetType == AssetType.ERC20, "Deposit is not ERC20");

        // Example: Only allow withdrawal from FUSED state
        require(d.currentState == DepositState.FUSED, "Deposit state does not allow withdrawal");

        uint256 amount = d.amount;
        require(amount > 0, "No ERC20 balance to withdraw");
        address tokenAddress = d.tokenAddress;

        // Mark deposit as withdrawn/spent
        _cleanupDeposit(depositId);

        totalValueLocked[AssetType.ERC20] -= amount;
        IERC20(tokenAddress).safeTransfer(d.owner, amount);

        emit WithdrawalExecuted(depositId, d.owner, d.assetType, amount);
    }

    /// @notice Allows withdrawal of ERC-721 deposit if its state permits.
    /// Only FUSED state is allowed in this example implementation.
    /// @param depositId The ID of the deposit.
    function withdrawERC721(uint256 depositId) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        Deposit storage d = deposits[depositId];
        require(msg.sender == d.owner, "Not deposit owner");
        require(d.assetType == AssetType.ERC721, "Deposit is not ERC721");

        // Example: Only allow withdrawal from FUSED state
        require(d.currentState == DepositState.FUSED, "Deposit state does not allow withdrawal");

        address nftContract = d.tokenAddress;
        uint256 tokenId = d.tokenId;

        // Mark deposit as withdrawn/spent
        _cleanupDeposit(depositId);

        totalValueLocked[AssetType.ERC721]--;
        IERC721(nftContract).safeTransferFrom(address(this), d.owner, tokenId);

        emit WithdrawalExecuted(depositId, d.owner, d.assetType, 1); // Amount is 1 for NFT
    }

    /// @notice Allows partial withdrawal of ETH deposit if its state permits.
    /// Example: Only allowed in VOLATILE state, maybe with a fee.
    /// @param depositId The ID of the deposit.
    /// @param amount The amount of ETH to withdraw.
    function partialWithdrawETH(uint256 depositId, uint256 amount) public whenNotPaused selfDestructNotInitiated nonReentrant {
         require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
         Deposit storage d = deposits[depositId];
         require(msg.sender == d.owner, "Not deposit owner");
         require(d.assetType == AssetType.ETH, "Deposit is not ETH");
         require(amount > 0, "Amount must be > 0");
         require(amount <= d.amount, "Partial amount exceeds total");

         // Example: Only allow partial withdrawal from VOLATILE state
         require(d.currentState == DepositState.VOLATILE, "Deposit state does not allow partial withdrawal");

         // Optional: Apply a fee or penalty in VOLATILE state
         // uint256 fee = amount * some_fee_percentage / 100;
         // uint256 amountToSend = amount - fee;
         // payable(owner()).sendValue(fee); // Send fee to owner or burn

         uint256 amountToSend = amount;

         d.amount -= amount;
         totalValueLocked[AssetType.ETH] -= amount;
         payable(d.owner).sendValue(amountToSend);

         emit WithdrawalExecuted(depositId, d.owner, d.assetType, amountToSend);

         // Optionally transition state after partial withdrawal
         if (d.amount == 0) {
             _cleanupDeposit(depositId); // If fully withdrawn partially
         } else {
              _transitionState(depositId, DepositState.DEGRADED, "Partial Withdrawal"); // Example: partial withdrawal degrades state
         }
    }


    /// @notice Allows claiming of accrued conceptual yield for a deposit.
    /// Yield calculation is state-dependent and time-based.
    /// @param depositId The ID of the deposit.
    function claimAccruedYield(uint256 depositId) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
        Deposit storage d = deposits[depositId];
        require(msg.sender == d.owner, "Not deposit owner");
        require(d.assetType != AssetType.ERC721, "NFT deposits do not accrue yield"); // Example: NFTs don't yield

        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - d.lastYieldClaimTimestamp;
        uint256 currentYieldRate = yieldRates[d.currentState]; // Scaled rate

        // Simple conceptual yield calculation: amount * rate * time
        // This would need refinement for precision, e.g., using fixed-point math or accumulating points
        // Example: yield in smallest unit of asset
        // Assuming rate is per second, scaled by 1e18
        // (amount * rate * timeElapsed) / 1e18
        // Simplified for example:
        uint256 accruedYieldAmount = (d.amount * currentYieldRate * timeElapsed) / 1e18;

        require(accruedYieldAmount > 0, "No yield accrued yet");

        d.lastYieldClaimTimestamp = currentTime;

        // In a real contract, this yield would be paid out, likely in the deposit's asset or a separate reward token.
        // For this conceptual example, we just emit the event. Payment logic would go here.

        // Example Payout (simplified): Assuming yield is paid in the deposit's asset
        if (d.assetType == AssetType.ETH) {
            payable(d.owner).sendValue(accruedYieldAmount);
            // Note: This adds complexity as ETH amount in deposit struct doesn't decrease,
            // yield is effectively paid from contract's balance.
            // A proper system would use a separate token or accounting.
        } else if (d.assetType == AssetType.ERC20) {
             IERC20(d.tokenAddress).safeTransfer(d.owner, accruedYieldAmount);
             // Same note as above applies.
        }

        emit YieldClaimed(depositId, d.owner, accruedYieldAmount);

        // Optional: State transition based on claiming yield
        // _transitionState(depositId, DepositState.INITIAL, "Yield Claimed"); // Example
    }

    // --- Interaction Functions ---

    /// @notice Attempts to fuse two eligible deposits.
    /// Requires specific states and potentially matching asset types (configurable logic).
    /// Transitions both deposits to the FUSED state upon success.
    /// @param depositId1 The ID of the first deposit.
    /// @param depositId2 The ID of the second deposit.
    function fuseDeposits(uint256 depositId1, uint256 depositId2) public whenNotPaused selfDestructNotInitiated nonReentrant {
        require(depositId1 > 0 && depositId1 <= depositCounter, "Invalid deposit ID 1");
        require(depositId2 > 0 && depositId2 <= depositCounter, "Invalid deposit ID 2");
        require(depositId1 != depositId2, "Cannot fuse a deposit with itself");

        Deposit storage d1 = deposits[depositId1];
        Deposit storage d2 = deposits[depositId2];

        // Require initiator to own both deposits
        require(msg.sender == d1.owner, "Not owner of deposit 1");
        require(msg.sender == d2.owner, "Not owner of deposit 2");

        // Example Fusion Eligibility: Both must be in CONDITION_MET state
        require(d1.currentState == DepositState.CONDITION_MET, "Deposit 1 not in CONDITION_MET state");
        require(d2.currentState == DepositState.CONDITION_MET, "Deposit 2 not in CONDITION_MET state");

        // Example: Require same asset type for fusion
        // require(d1.assetType == d2.assetType, "Cannot fuse deposits of different asset types");

        // Perform the fusion - transition both to FUSED state
        _transitionState(depositId1, DepositState.FUSED, "Fused");
        _transitionState(depositId2, DepositState.FUSED, "Fused");

        emit DepositsFused(depositId1, depositId2, msg.sender);

        // Additional fusion logic could go here, e.g.:
        // - Mint a new "Fusion Token" to the owner
        // - Create a new "Fused Deposit" representing the combination
        // - Transfer ownership/rights to a new entity (e.g., a DAO)
        // - Unlock a special feature or yield rate that is higher than FUSED state yield rate
    }

    /// @notice Attempts to entangle two deposits.
    /// Requires specific states and owner permission. Links deposits so state changes can propagate.
    /// @param depositId1 The ID of the first deposit.
    /// @param depositId2 The ID of the second deposit.
    function entangleDeposits(uint256 depositId1, uint256 depositId2) public whenNotPaused selfDestructNotInitiated nonReentrant {
         require(depositId1 > 0 && depositId1 <= depositCounter, "Invalid deposit ID 1");
         require(depositId2 > 0 && depositId2 <= depositCounter, "Invalid deposit ID 2");
         require(depositId1 != depositId2, "Cannot entangle a deposit with itself");

         Deposit storage d1 = deposits[depositId1];
         Deposit storage d2 = deposits[depositId2];

         // Require initiator to own both deposits
         require(msg.sender == d1.owner, "Not owner of deposit 1");
         require(msg.sender == d2.owner, "Not owner of deposit 2");

         // Example Entanglement Eligibility: Both must be in INITIAL state
         require(d1.currentState == DepositState.INITIAL, "Deposit 1 not in INITIAL state");
         require(d2.currentState == DepositState.INITIAL, "Deposit 2 not in INITIAL state");

         // Require they are not already entangled
         require(d1.entangledDepositId == 0, "Deposit 1 already entangled");
         require(d2.entangledDepositId == 0, "Deposit 2 already entangled");

         // Link the deposits bi-directionally
         d1.entangledDepositId = depositId2;
         d2.entangledDepositId = depositId1;

         // Transition both to ENTANGLED state
         _transitionState(depositId1, DepositState.ENTANGLED, "Entangled");
         _transitionState(depositId2, DepositState.ENTANGLED, "Entangled");

         emit DepositsEntangled(depositId1, depositId2, msg.sender);

         // Additional entanglement logic could go here, e.g.:
         // - Yield rate becomes an average of their potential yields
         // - Certain state transitions in one automatically trigger transitions in the other
         // - If one is withdrawn, the other is automatically disentangled or transitions to a DEGRADED state
     }

     /// @notice Disentangles a deposit from its entangled partner.
     /// Can be called by the owner of the deposit.
     /// @param depositId The ID of the deposit to disentangle.
     function disentangleDeposit(uint256 depositId) public whenNotPaused selfDestructNotInitiated nonReentrant {
         require(depositId > 0 && depositId <= depositCounter, "Invalid deposit ID");
         Deposit storage d = deposits[depositId];
         require(msg.sender == d.owner, "Not deposit owner");
         require(d.entangledDepositId != 0, "Deposit is not entangled");

         uint256 entangledId = d.entangledDepositId;
         Deposit storage entangledDeposit = deposits[entangledId];

         // Break the link
         d.entangledDepositId = 0;
         entangledDeposit.entangledDepositId = 0;

         // Transition out of ENTANGLED state (e.g., back to INITIAL or DEGRADED)
         _transitionState(depositId, DepositState.INITIAL, "Disentangled"); // Example transition
         _transitionState(entangledId, DepositState.INITIAL, "Disentangled Partner"); // Example transition

         emit DepositDisentangled(depositId);
     }


    // --- Owner Configuration & Emergency Functions ---

    /// @notice Owner sets or updates a transition rule between two states.
    /// Setting conditionType to NONE and conditionValue to 0 effectively removes a rule.
    /// @param fromState The starting state.
    /// @param toState The target state.
    /// @param rule The TransitionRule struct defining the condition.
    function setTransitionRule(DepositState fromState, DepositState toState, TransitionRule memory rule) public onlyOwner {
        stateTransitionRules[fromState][toState] = rule;
        emit TransitionRuleSet(fromState, toState, rule.conditionType);
    }

    /// @notice Owner sets or updates the conceptual yield rate for a specific state.
    /// Rate should be scaled (e.g., 1e18 = 100% per second). Use smaller values!
    /// @param state The deposit state.
    /// @param rate The scaled yield rate.
    function setYieldRate(DepositState state, uint256 rate) public onlyOwner {
        yieldRates[state] = rate;
        emit YieldRateSet(state, rate);
    }

    /// @notice Owner sets the oracle feed address associated with a condition key.
    /// This contract doesn't directly *call* the oracle feed, but uses this address for reference.
    /// Off-chain keepers would read the feed and call `updateOracleData`.
    /// @param conditionKey The bytes32 key identifying the condition.
    /// @param feedAddress The address of the oracle feed (e.g., Chainlink AggregatorV3).
    function setOracleFeedAddress(bytes32 conditionKey, address feedAddress) public onlyOwner {
         require(conditionKey != bytes32(0), "Condition key cannot be zero");
         require(feedAddress != address(0), "Feed address cannot be zero");
         oracleFeeds[conditionKey] = feedAddress;
         emit OracleFeedSet(conditionKey, feedAddress);
    }

    /// @notice Owner or trusted keeper role can update the internal oracle data value.
    /// In a real system, this would likely have more robust access control or be called by a designated keeper.
    /// For this example, Owner is sufficient.
    /// @param conditionKey The bytes32 key identifying the condition.
    /// @param value The latest value from the oracle feed.
    function updateOracleData(bytes32 conditionKey, int256 value) public onlyOwner whenNotPaused selfDestructNotInitiated {
        require(conditionKey != bytes32(0), "Condition key cannot be zero");
        oracleData[conditionKey] = value;
        emit OracleDataUpdated(conditionKey, value);
    }


    /// @notice Owner can withdraw all assets of a specific type in case of emergencies.
    /// Bypasses deposit states and ownership checks.
    /// @param assetType The type of asset to withdraw (ETH, ERC20, ERC721).
    function emergencyWithdrawAllAssets(AssetType assetType) public onlyOwner nonReentrant {
         uint256 totalAmountOrCount;

         if (assetType == AssetType.ETH) {
             totalAmountOrCount = address(this).balance;
             if (totalAmountOrCount > 0) {
                 payable(owner()).sendValue(totalAmountOrCount);
                 totalValueLocked[AssetType.ETH] = 0; // Reset TVL for this asset type
             }
         } else if (assetType == AssetType.ERC20) {
             // This requires knowing *which* ERC20 token addresses are held.
             // A real implementation would need a mapping or set of held token addresses.
             // For simplicity in this example, we'll require the owner to specify the token address.
             // NOTE: This is a simplified emergency withdrawal; a robust one needs to track held tokens.
             revert("Emergency withdrawal for ERC20 requires specifying token, not supported in this simplified function.");
             // Example if we knew a specific token:
             // address knownTokenAddress = ...;
             // totalAmountOrCount = IERC20(knownTokenAddress).balanceOf(address(this));
             // if (totalAmountOrCount > 0) {
             //     IERC20(knownTokenAddress).safeTransfer(owner(), totalAmountOrCount);
             //     // Need to update totalValueLocked for this *specific* token, not just ERC20 type
             // }
         } else if (assetType == AssetType.ERC721) {
            // This requires knowing *which* ERC721 contract addresses and tokenIds are held.
            // A robust implementation would need to track held NFTs.
            revert("Emergency withdrawal for ERC721 is complex and not supported in this simplified function.");
            // Example: Owner would provide contract address and array of token IDs to withdraw.
         }

         // This TVL reset is only accurate for ETH in this simplified version.
         emit EmergencyWithdrawal(assetType, owner(), totalAmountOrCount);
    }

    /// @notice Initiates the self-destruct process with a defined delay.
    /// Requires a non-zero selfDestructDelay to be set first via a separate owner function (not included to keep function count focused).
    /// @param delayInSeconds The minimum time (in seconds) before confirmSelfDestruct can be called.
    function initiateSelfDestruct(uint256 delayInSeconds) public onlyOwner {
        require(selfDestructInitiatedAt == 0, "Self-destruct already initiated");
        require(delayInSeconds > 0, "Self-destruct delay must be greater than zero");
        selfDestructDelay = delayInSeconds;
        selfDestructInitiatedAt = block.timestamp;
        paused = true; // Pause interactions during self-destruct period
        emit Paused(address(0)); // Indicate system pause
        emit SelfDestructInitiated(selfDestructInitiatedAt, selfDestructDelay);
    }

    /// @notice Confirms the self-destruct after the required delay has passed.
    /// Sends remaining ETH balance to the owner. Other assets are left in the contract (consider emergencyWithdraw before this).
    function confirmSelfDestruct() public onlyOwner {
        require(selfDestructInitiatedAt > 0, "Self-destruct not initiated");
        require(block.timestamp >= selfDestructInitiatedAt + selfDestructDelay, "Self-destruct delay not passed");

        emit SelfDestructConfirmed(owner());

        // Note: selfdestruct sends remaining ETH. Other tokens/NFTs remain in the contract.
        // A proper process would require emergency withdrawals before confirmation.
        selfdestruct(payable(owner()));
    }

    /// @notice Pauses contract interactions (deposits, withdrawals, state transitions).
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /// @notice Unpauses contract interactions.
    function unpause() public onlyOwner whenPaused {
        // Cannot unpause if self-destruct is initiated (unless self-destruct is cancelled, not implemented)
        require(selfDestructInitiatedAt == 0, "Cannot unpause during self-destruct initiation period");
        paused = false;
        emit Unpaused(_msgSender());
    }

    // --- Internal Helper Functions ---

    /// @dev Marks a deposit as spent/withdrawn by setting amount/id to 0 and changing state.
    function _cleanupDeposit(uint256 depositId) internal {
        Deposit storage d = deposits[depositId];
        d.amount = 0;
        d.tokenId = 0;
        d.currentState = DepositState.DEGRADED; // Mark as effectively inactive
        // Optionally remove from userDeposits array (gas intensive for large arrays)
        // Or simply filter out DEGRADED state deposits when retrieving user deposits
    }
}
```