Okay, here is a Solidity smart contract concept called "QuantumSwapBridge".

This contract is designed to facilitate *conditional, time-locked, and potentially cross-chain orchestrated* swaps between two parties for ERC20 tokens. It introduces the concept of a "Resolver" role responsible for attesting to off-chain or cross-chain conditions, adding complexity and decentralized oracle interaction. The name "QuantumSwap" is metaphorical, suggesting non-obvious states and conditional resolution, not actual quantum computing. The "Bridge" aspect implies its *intended use case* in cross-chain scenarios, where the condition verification might involve proofs or messages from other chains, though the contract itself lives on a single chain.

It attempts to be creative by combining:
1.  **Conditional Execution:** Swaps only happen if an external condition (verified by a resolver/oracle) is met.
2.  **Time-Locking/Expiry:** Swaps have deadlines.
3.  **Role-Based Interaction:** Distinct roles (Initiator, Counterparty, Resolver, Relayer, Owner).
4.  **Bonding/Slashing:** Incentivizing honest resolver behavior.
5.  **Delegated Execution:** Allowing anyone (a relayer) to trigger the final execution after the condition is met.

---

**QuantumSwapBridge Smart Contract Outline & Function Summary**

**Contract Name:** `QuantumSwapBridge`

**Core Concept:** Facilitates conditional, time-locked ERC20 swaps between two parties, relying on external "Resolvers" to attest to condition fulfillment. Designed with cross-chain use cases in mind (where conditions might relate to events on other chains verified via oracles/bridges).

**Key Roles:**
*   `Owner`: Contract administrator, sets fees, oracles, can pause.
*   `Initiator`: Creates the swap request and deposits their token.
*   `Counterparty`: Accepts the swap and deposits their token.
*   `Resolver`: Attests to whether the specified condition for a swap has been met. May need to stake a bond.
*   `Relayer`: Any address that can trigger the `executeSwap` or `expireSwap` functions (often for a fee).

**State Machine for Swaps:**
`Pending` (Initiator deposited) -> `CounterpartyDeposited` (Counterparty deposited) -> `ConditionMet` (Resolver attested) -> `Executed`
OR
`Pending` / `CounterpartyDeposited` / `ConditionMet` -> `Cancelled` / `Expired`

**Data Structures:**
*   `SwapState`: Enum (`Pending`, `CounterpartyDeposited`, `ConditionMet`, `Executed`, `Cancelled`, `Expired`, `BondClaimed`, `BondSlashed`)
*   `Swap`: Struct holding all details of a swap (participants, tokens, amounts, condition hash, deadline, state, resolver, bond details, etc.)

**State Variables:**
*   `owner`: Contract owner.
*   `paused`: Pausing state.
*   `swapCounter`: Counter for unique swap IDs.
*   `swaps`: Mapping from swap ID to `Swap` struct.
*   `resolverBonds`: Mapping from resolver address to bond amount.
*   `conditionOracles`: Mapping from a condition hash type to a trusted oracle address.
*   `resolverRegistry`: Mapping from resolver address to boolean (is registered).
*   `minResolverBond`: Minimum bond required for a resolver on certain conditions.
*   `executionFee`: Fee paid to a relayer for executing a swap.
*   `feeRecipient`: Address receiving collected fees.
*   `totalCollectedFees`: Total fees accumulated.
*   `trustedConditionTypes`: Mapping from condition hash prefix/type to boolean (whitelist).

**Events:**
*   `SwapInitiated`
*   `CounterpartyDeposited`
*   `ConditionAttested`
*   `SwapExecuted`
*   `SwapCancelled`
*   `SwapExpired`
*   `ResolverRegistered`
*   `ResolverDeregistered`
*   `BondProvided`
*   `BondClaimed`
*   `BondSlashed`
*   `OracleUpdated`
*   `ExecutionFeeUpdated`
*   `FeeRecipientUpdated`
*   `FeesWithdrawn`
*   `Paused`
*   `Unpaused`

**Function Summary:**

1.  `constructor(address initialFeeRecipient, uint256 initialExecutionFee, uint256 initialMinResolverBond)`: Initializes owner, fee recipient, initial fees and bond.
2.  `pause()`: Owner can pause contract (preventing state-changing ops).
3.  `unpause()`: Owner can unpause contract.
4.  `registerResolver(address resolverAddress)`: Owner registers a trusted resolver address.
5.  `deregisterResolver(address resolverAddress)`: Owner deregisters a resolver.
6.  `setOracleAddress(bytes32 conditionTypeHash, address oracleAddress)`: Owner sets the trusted oracle address for a specific condition type.
7.  `setExecutionFee(uint256 fee)`: Owner sets the fee for executing swaps.
8.  `setFeeRecipient(address recipient)`: Owner sets the address to receive collected fees.
9.  `setMinimumResolverBond(uint256 bondAmount)`: Owner sets the minimum resolver bond amount.
10. `setTrustedConditionType(bytes32 conditionTypeHash, bool trusted)`: Owner whitelists/unwhitelists a condition type.
11. `withdrawFees(address token, uint256 amount)`: Owner withdraws accumulated fees in a specific token.
12. `initiateSwap(address counterparty, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut, uint64 deadline, bytes32 conditionHash, address resolver, uint256 requiredBondAmount)`: Initiates a new swap, requires `tokenIn` approval, transfers `amountIn` to contract. Sets swap state to `Pending`.
13. `depositCounterpartyFunds(uint256 swapId)`: Counterparty deposits their `tokenOut` funds after approving the contract. Sets swap state to `CounterpartyDeposited`.
14. `provideResolverBond(uint256 amount)`: A registered resolver stakes bond (e.g., in native token or specific bond token).
15. `attestConditionMet(uint256 swapId, bytes memory oracleProof)`: The designated resolver for a swap calls this to attest the condition is met, providing proof. Requires resolver bond (if applicable). If proof is valid, sets swap state to `ConditionMet`. Includes logic for basic proof validation (in a real scenario, this would be complex oracle interaction).
16. `executeSwap(uint256 swapId)`: Anyone (a relayer) can call this if swap state is `ConditionMet` and before the deadline. Transfers tokens to respective parties and sends execution fee. Sets swap state to `Executed`.
17. `cancelSwap(uint256 swapId)`: Initiator cancels the swap before counterparty deposits or condition is met (and before expiry). Returns `tokenIn`. Sets swap state to `Cancelled`.
18. `counterpartyCancelSwap(uint256 swapId)`: Counterparty cancels the swap before condition is met (and before expiry). Returns `tokenOut`. Sets swap state to `Cancelled`.
19. `expireSwap(uint256 swapId)`: Anyone can call this after the deadline if the swap is not `Executed` or `Cancelled`. Returns funds to respective depositors. Sets swap state to `Expired`.
20. `claimResolverBond(address resolverAddress, uint256 amount)`: A resolver can claim back their bond *after* all swaps they resolved have been completed (executed/expired/cancelled without slashing). More complex logic needed for tracking this properly in a real system. Simplified here.
21. `slashResolverBond(address resolverAddress, uint256 amount)`: Owner (or governance/oracle via trusted call) slashes a resolver's bond (e.g., for incorrect attestation). Slashed amount goes to fee recipient or treasury. Sets swap state to `BondSlashed` (if linked to a specific slashable event).
22. `getSwapDetails(uint256 swapId)`: View function to retrieve details of a specific swap.
23. `getResolverBond(address resolverAddress)`: View function to check a resolver's current bond amount.
24. `isResolverRegistered(address resolverAddress)`: View function.
25. `getOracleAddress(bytes32 conditionTypeHash)`: View function.
26. `getExecutionFee()`: View function.
27. `getFeeRecipient()`: View function.
28. `getTotalCollectedFees()`: View function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Note: For simplicity and to avoid duplicating OpenZeppelin's Ownable/Pausable fully,
// we implement basic versions here. In a production system, using standard libraries is recommended.

contract QuantumSwapBridge is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private immutable i_owner;
    bool private s_paused;

    // --- State Variables ---
    uint256 private s_swapCounter;
    mapping(uint256 => Swap) private s_swaps;

    mapping(address => uint256) private s_resolverBonds; // Resolver address => bond amount
    mapping(address => bool) private s_resolverRegistry; // Registered resolver address => bool

    mapping(bytes32 => address) private s_conditionOracles; // Condition type hash => Trusted Oracle Address
    mapping(bytes32 => bool) private s_trustedConditionTypes; // Condition type hash => is trusted

    uint256 private s_minResolverBond; // Minimum bond required for a resolver
    uint256 private s_executionFee; // Fee paid to relayer for executing a swap
    address private s_feeRecipient; // Address receiving collected fees
    mapping(address => uint256) private s_totalCollectedFees; // Token address => collected amount

    // --- Enums ---
    enum SwapState {
        Pending,              // Initiator funds deposited
        CounterpartyDeposited, // Both parties funds deposited
        ConditionMet,         // Condition attested by resolver
        Executed,             // Swap completed, funds transferred
        Cancelled,            // Swap cancelled by initiator or counterparty
        Expired,              // Swap expired due to deadline
        BondClaimed,          // Resolver bond claimed (more complex logic needed for tracking per swap)
        BondSlashed           // Resolver bond slashed (more complex logic needed for tracking per swap)
    }

    // --- Structs ---
    struct Swap {
        address initiator;
        address counterparty;
        IERC20 tokenIn;
        uint256 amountIn;
        IERC20 tokenOut;
        uint256 amountOut;
        uint64 deadline; // Timestamp
        bytes32 conditionHash; // Hash representing the specific condition parameters
        address resolver;      // Designated resolver for this swap
        uint256 requiredBondAmount; // Bond amount required for this specific resolution
        SwapState state;
    }

    // --- Events ---
    event SwapInitiated(
        uint256 indexed swapId,
        address indexed initiator,
        address indexed counterparty,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint64 deadline,
        bytes32 conditionHash,
        address resolver
    );
    event CounterpartyDeposited(uint256 indexed swapId, address indexed counterparty);
    event ConditionAttested(uint256 indexed swapId, address indexed resolver, bytes32 conditionHash);
    event SwapExecuted(uint256 indexed swapId, address indexed executor);
    event SwapCancelled(uint256 indexed swapId, address indexed canceller);
    event SwapExpired(uint256 indexed swapId, address indexed liquidator);
    event ResolverRegistered(address indexed resolverAddress);
    event ResolverDeregistered(address indexed resolverAddress);
    event BondProvided(address indexed resolverAddress, uint256 amount);
    event BondClaimed(address indexed resolverAddress, uint256 amount);
    event BondSlashed(address indexed resolverAddress, uint256 amount, address indexed slasher);
    event OracleUpdated(bytes32 indexed conditionTypeHash, address indexed newOracleAddress);
    event ExecutionFeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address indexed newRecipient);
    event FeesWithdrawn(address indexed token, uint256 amount, address indexed recipient);
    event Paused(address account);
    event Unpaused(address account);
    event MinimumResolverBondUpdated(uint256 newBondAmount);
    event TrustedConditionTypeUpdated(bytes32 indexed conditionTypeHash, bool trusted);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!s_paused, "Paused");
        _;
    }

    modifier whenPaused() {
        require(s_paused, "Not paused");
        _;
    }

    modifier onlyRegisteredResolver() {
        require(s_resolverRegistry[msg.sender], "Not a registered resolver");
        _;
    }

    // --- Constructor ---
    constructor(address initialFeeRecipient, uint256 initialExecutionFee, uint256 initialMinResolverBond) {
        i_owner = msg.sender;
        s_feeRecipient = initialFeeRecipient;
        s_executionFee = initialExecutionFee;
        s_minResolverBond = initialMinResolverBond;
    }

    // --- Owner Functions ---

    /// @notice Pauses the contract. Only owner.
    function pause() external onlyOwner whenNotPaused {
        s_paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract. Only owner.
    function unpause() external onlyOwner whenPaused {
        s_paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice Registers a resolver address. Only owner.
    /// @param resolverAddress The address to register.
    function registerResolver(address resolverAddress) external onlyOwner {
        require(resolverAddress != address(0), "Invalid address");
        require(!s_resolverRegistry[resolverAddress], "Resolver already registered");
        s_resolverRegistry[resolverAddress] = true;
        emit ResolverRegistered(resolverAddress);
    }

    /// @notice Deregisters a resolver address. Only owner.
    /// @param resolverAddress The address to deregister.
    function deregisterResolver(address resolverAddress) external onlyOwner {
        require(s_resolverRegistry[resolverAddress], "Resolver not registered");
        s_resolverRegistry[resolverAddress] = false;
        // Note: Real implementation needs logic to handle active swaps for this resolver.
        emit ResolverDeregistered(resolverAddress);
    }

    /// @notice Sets the trusted oracle address for a specific condition type. Only owner.
    /// @param conditionTypeHash A hash identifier for the condition type (e.g., hash of price feed ID).
    /// @param oracleAddress The address of the trusted oracle contract.
    function setOracleAddress(bytes32 conditionTypeHash, address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid address");
        s_conditionOracles[conditionTypeHash] = oracleAddress;
        emit OracleUpdated(conditionTypeHash, oracleAddress);
    }

    /// @notice Sets the execution fee paid to relayers. Only owner.
    /// @param fee The new execution fee amount (in native token).
    function setExecutionFee(uint256 fee) external onlyOwner {
        s_executionFee = fee;
        emit ExecutionFeeUpdated(fee);
    }

    /// @notice Sets the address that receives collected fees. Only owner.
    /// @param recipient The new fee recipient address.
    function setFeeRecipient(address recipient) external onlyOwner {
        require(recipient != address(0), "Invalid address");
        s_feeRecipient = recipient;
        emit FeeRecipientUpdated(recipient);
    }

    /// @notice Sets the minimum bond amount required for resolvers on certain conditions. Only owner.
    /// @param bondAmount The new minimum bond amount (in native token).
    function setMinimumResolverBond(uint256 bondAmount) external onlyOwner {
        s_minResolverBond = bondAmount;
        emit MinimumResolverBondUpdated(bondAmount);
    }

    /// @notice Whitelists or unwhitelists a condition type hash. Swaps can only be initiated with whitelisted types. Only owner.
    /// @param conditionTypeHash The hash identifier for the condition type.
    /// @param trusted Whether the condition type should be trusted (true) or not (false).
    function setTrustedConditionType(bytes32 conditionTypeHash, bool trusted) external onlyOwner {
        s_trustedConditionTypes[conditionTypeHash] = trusted;
        emit TrustedConditionTypeUpdated(conditionTypeHash, trusted);
    }

    /// @notice Allows the owner to withdraw accumulated fees. Only owner.
    /// @param token The address of the token to withdraw (use address(0) for native token).
    /// @param amount The amount to withdraw.
    function withdrawFees(address token, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        uint256 collected = s_totalCollectedFees[token];
        require(amount <= collected, "Insufficient collected fees");

        s_totalCollectedFees[token] -= amount;

        if (token == address(0)) {
            payable(s_feeRecipient).transfer(amount); // For native token (ETH)
        } else {
            IERC20(token).safeTransfer(s_feeRecipient, amount);
        }

        emit FeesWithdrawn(token, amount, s_feeRecipient);
    }

    // --- Main Swap Functions ---

    /// @notice Initiates a new conditional swap. Requires tokenIn to be approved for the contract.
    /// @param counterparty The address of the counterparty.
    /// @param tokenIn The address of the token the initiator is offering.
    /// @param amountIn The amount of tokenIn the initiator is offering.
    /// @param tokenOut The address of the token the initiator wants.
    /// @param amountOut The amount of tokenOut the initiator wants.
    /// @param deadline The timestamp by which the swap must be executed or expired.
    /// @param conditionHash A hash representing the specific details of the condition. The first 4 bytes can denote the condition type.
    /// @param resolver The address of the registered resolver responsible for attesting the condition.
    /// @param requiredBondAmount The minimum bond amount required by the resolver for this specific swap.
    /// @return The unique ID of the created swap.
    function initiateSwap(
        address counterparty,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut,
        uint64 deadline,
        bytes32 conditionHash,
        address resolver,
        uint256 requiredBondAmount // Bond specific to *this* resolution
    ) external payable whenNotPaused nonReentrant returns (uint256) {
        require(counterparty != address(0) && counterparty != msg.sender, "Invalid counterparty");
        require(tokenIn != address(0) || msg.value > 0, "Invalid tokenIn or no ETH provided"); // Allow ETH or ERC20
        require(tokenOut != address(0), "Invalid tokenOut");
        require(amountIn > 0 && amountOut > 0, "Amounts must be > 0");
        require(deadline > block.timestamp, "Deadline must be in the future");
        require(s_resolverRegistry[resolver], "Resolver not registered");
        require(requiredBondAmount >= s_minResolverBond, "Required bond below minimum");

        // Check trusted condition type (using first 4 bytes of hash as type identifier)
        bytes32 conditionType = bytes32(uint256(conditionHash) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00);
        require(s_trustedConditionTypes[conditionType], "Untrusted condition type");
        require(s_conditionOracles[conditionType] != address(0), "No oracle set for condition type");


        s_swapCounter++;
        uint256 swapId = s_swapCounter;

        // Transfer tokenIn or receive ETH
        if (tokenIn == address(0)) {
            require(msg.value == amountIn, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "Cannot send ETH with ERC20 tokenIn");
            IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        s_swaps[swapId] = Swap({
            initiator: msg.sender,
            counterparty: counterparty,
            tokenIn: IERC20(tokenIn),
            amountIn: amountIn,
            tokenOut: IERC20(tokenOut),
            amountOut: amountOut,
            deadline: deadline,
            conditionHash: conditionHash,
            resolver: resolver,
            requiredBondAmount: requiredBondAmount,
            state: SwapState.Pending
        });

        emit SwapInitiated(
            swapId,
            msg.sender,
            counterparty,
            tokenIn,
            amountIn,
            tokenOut,
            amountOut,
            deadline,
            conditionHash,
            resolver
        );

        return swapId;
    }

    /// @notice Counterparty deposits their funds for an initiated swap. Requires tokenOut approval.
    /// @param swapId The ID of the swap.
    function depositCounterpartyFunds(uint256 swapId) external whenNotPaused nonReentrant {
        Swap storage swap = s_swaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist"); // Check if swap is initialized
        require(swap.state == SwapState.Pending, "Swap not in Pending state");
        require(msg.sender == swap.counterparty, "Not the counterparty");
        require(block.timestamp < swap.deadline, "Swap deadline passed");

        // Transfer tokenOut or receive ETH
        if (address(swap.tokenOut) == address(0)) {
             // Note: Current implementation expects Counterparty to provide tokenOut.
             // ETH as tokenOut requires different flow (recipient receives ETH from contract balance).
             // This needs careful handling or restriction (e.g., ETH only as tokenIn).
             // For simplicity, let's assume ERC20 for now for tokenOut, or contract holds enough ETH.
             // A robust bridge would manage ETH liquidity or use WETH.
             revert("ETH not supported as tokenOut in this version");
            // payable(address(this)).transfer(swap.amountOut); // Example for ETH tokenOut
        } else {
            swap.tokenOut.safeTransferFrom(msg.sender, address(this), swap.amountOut);
        }

        swap.state = SwapState.CounterpartyDeposited;
        emit CounterpartyDeposited(swapId, msg.sender);
    }

    /// @notice A registered resolver attests that the condition for a swap has been met.
    /// Requires the resolver to have provided the necessary bond.
    /// @param swapId The ID of the swap.
    /// @param oracleProof A byte array containing proof from the oracle.
    function attestConditionMet(uint256 swapId, bytes memory oracleProof) external whenNotPaused nonReentrant onlyRegisteredResolver {
        Swap storage swap = s_swaps[swapId];
        require(swap.state == SwapState.CounterpartyDeposited, "Swap not in CounterpartyDeposited state");
        require(msg.sender == swap.resolver, "Not the designated resolver");
        require(block.timestamp < swap.deadline, "Swap deadline passed");
        require(s_resolverBonds[msg.sender] >= swap.requiredBondAmount, "Resolver has insufficient bond");

        // Basic mock for proof validation - **Highly complex in reality**
        // A real implementation would interact with a specific oracle contract
        // or verify a cryptographic proof relating to the conditionHash.
        bytes32 conditionType = bytes32(uint256(swap.conditionHash) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00);
        address trustedOracle = s_conditionOracles[conditionType];
        require(trustedOracle != address(0), "No oracle set for condition type");

        // Example: Call a mock oracle contract function
        // (This part requires a mock Oracle interface/contract)
        // MockOracle(trustedOracle).verifyProof(swap.conditionHash, oracleProof);
        // For this concept, we'll just assume the proof is 'valid' if it's not empty
        require(oracleProof.length > 0, "Oracle proof required");
        // In a real system, this proof would be verified against the conditionHash

        // Simulate proof verification success
        bool proofIsValid = _mockVerifyOracleProof(trustedOracle, swap.conditionHash, oracleProof);
        require(proofIsValid, "Invalid oracle proof");

        swap.state = SwapState.ConditionMet;
        emit ConditionAttested(swapId, msg.sender, swap.conditionHash);
    }

    /// @notice Executes a swap after the condition is met and before the deadline. Callable by anyone (relayer).
    /// Transfers tokens and sends execution fee to the relayer.
    /// @param swapId The ID of the swap.
    function executeSwap(uint256 swapId) external payable whenNotPaused nonReentrant {
        Swap storage swap = s_swaps[swapId];
        require(swap.state == SwapState.ConditionMet, "Swap not in ConditionMet state");
        require(block.timestamp < swap.deadline, "Swap deadline passed");

        // Transfer tokens
        // Initiator gets tokenOut
        if (address(swap.tokenOut) == address(0)) {
             // ETH as tokenOut: Transfer from contract balance
             // This requires the contract to hold enough ETH (e.g., pre-funded or via ETH tokenIn swaps)
             // For robustness, using WETH is better.
             revert("ETH not supported as tokenOut in this version"); // Placeholder
             // payable(swap.initiator).transfer(swap.amountOut); // Example for ETH tokenOut
        } else {
            swap.tokenOut.safeTransfer(swap.initiator, swap.amountOut);
        }

        // Counterparty gets tokenIn
        if (address(swap.tokenIn) == address(0)) {
             // ETH as tokenIn: Send ETH received during initiation
             payable(swap.counterparty).transfer(swap.amountIn);
        } else {
            swap.tokenIn.safeTransfer(swap.counterparty, swap.amountIn);
        }

        swap.state = SwapState.Executed;
        emit SwapExecuted(swapId, msg.sender);

        // Pay execution fee to the relayer (msg.sender)
        if (s_executionFee > 0) {
             // Fee paid in native token
            payable(msg.sender).transfer(s_executionFee);
        }
    }

    /// @notice Initiator cancels the swap before it's fully deposited or condition is met and before expiry.
    /// Returns deposited funds.
    /// @param swapId The ID of the swap.
    function cancelSwap(uint256 swapId) external whenNotPaused nonReentrant {
        Swap storage swap = s_swaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist");
        require(msg.sender == swap.initiator, "Not the initiator");
        require(swap.state == SwapState.Pending || swap.state == SwapState.CounterpartyDeposited, "Swap not cancellable in current state");
        require(block.timestamp < swap.deadline, "Swap deadline passed");
        // Allow cancel if CounterpartyDeposited but condition not yet met
        if (swap.state == SwapState.CounterpartyDeposited) {
             revert("Counterparty has already deposited funds, cannot cancel unilaterally.");
             // Or implement a different cancellation flow requiring counterparty agreement
        }

        // Return Initiator's funds
        if (address(swap.tokenIn) == address(0)) {
             payable(swap.initiator).transfer(swap.amountIn);
        } else {
            swap.tokenIn.safeTransfer(swap.initiator, swap.amountIn);
        }

        swap.state = SwapState.Cancelled;
        emit SwapCancelled(swapId, msg.sender);
    }

     /// @notice Counterparty cancels the swap before condition is met and before expiry.
     /// Returns deposited funds.
     /// @param swapId The ID of the swap.
    function counterpartyCancelSwap(uint256 swapId) external whenNotPaused nonReentrant {
        Swap storage swap = s_swaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist");
        require(msg.sender == swap.counterparty, "Not the counterparty");
        require(swap.state == SwapState.CounterpartyDeposited, "Swap not in CounterpartyDeposited state");
        require(block.timestamp < swap.deadline, "Swap deadline passed");

        // Return Counterparty's funds
         if (address(swap.tokenOut) == address(0)) {
              revert("ETH not supported as tokenOut in this version"); // Placeholder
              // payable(swap.counterparty).transfer(swap.amountOut); // Example for ETH tokenOut
         } else {
             swap.tokenOut.safeTransfer(swap.counterparty, swap.amountOut);
         }

        swap.state = SwapState.Cancelled;
        emit SwapCancelled(swapId, msg.sender);
    }


    /// @notice Allows anyone to expire a swap after the deadline if it hasn't been executed or cancelled.
    /// Returns funds to respective depositors.
    /// @param swapId The ID of the swap.
    function expireSwap(uint256 swapId) external nonReentrant {
        Swap storage swap = s_swaps[swapId];
        require(swap.initiator != address(0), "Swap does not exist");
        require(swap.state != SwapState.Executed && swap.state != SwapState.Cancelled && swap.state != SwapState.Expired, "Swap in final state");
        require(block.timestamp >= swap.deadline, "Swap deadline not passed");

        // Return Initiator's funds
        if (address(swap.tokenIn) == address(0)) {
             payable(swap.initiator).transfer(swap.amountIn);
        } else {
            swap.tokenIn.safeTransfer(swap.initiator, swap.amountIn);
        }

        // Return Counterparty's funds if deposited
        if (swap.state >= SwapState.CounterpartyDeposited) {
             if (address(swap.tokenOut) == address(0)) {
                 revert("ETH not supported as tokenOut in this version"); // Placeholder
                 // payable(swap.counterparty).transfer(swap.amountOut); // Example for ETH tokenOut
             } else {
                 swap.tokenOut.safeTransfer(swap.counterparty, swap.amountOut);
             }
        }

        swap.state = SwapState.Expired;
        emit SwapExpired(swapId, msg.sender);
    }

    // --- Resolver Bond Functions ---

    /// @notice Allows a registered resolver to provide bond (in native token).
    /// @param amount The amount of bond to provide.
    function provideResolverBond(uint256 amount) external payable onlyRegisteredResolver {
        require(amount > 0, "Bond amount must be > 0");
        require(msg.value == amount, "ETH amount must match bond amount");
        s_resolverBonds[msg.sender] += amount;
        emit BondProvided(msg.sender, amount);
    }

    /// @notice Allows a registered resolver to claim back their bond.
    /// Note: In a real system, this would require verifying all associated swaps are finalized without slashing.
    /// This simplified version just allows claiming any amount up to their balance.
    /// @param amount The amount of bond to claim back.
    function claimResolverBond(address resolverAddress, uint256 amount) external onlyRegisteredResolver {
        require(msg.sender == resolverAddress, "Can only claim your own bond");
        require(amount > 0, "Amount must be > 0");
        require(s_resolverBonds[resolverAddress] >= amount, "Insufficient bond balance");

        s_resolverBonds[resolverAddress] -= amount;
        payable(resolverAddress).transfer(amount); // Transfer native token bond
        emit BondClaimed(resolverAddress, amount);
    }

    /// @notice Slashes a resolver's bond. Callable by owner or potentially via trusted oracle/governance.
    /// Slashed amount goes to the fee recipient.
    /// @param resolverAddress The resolver whose bond is being slashed.
    /// @param amount The amount to slash.
    function slashResolverBond(address resolverAddress, uint256 amount) external onlyOwner { // Or add specific slashing role/logic
        require(amount > 0, "Amount must be > 0");
        require(s_resolverBonds[resolverAddress] >= amount, "Insufficient bond balance to slash");
        require(s_feeRecipient != address(0), "Fee recipient not set");

        s_resolverBonds[resolverAddress] -= amount;
        // Transfer slashed amount to fee recipient (in native token)
        payable(s_feeRecipient).transfer(amount);
        s_totalCollectedFees[address(0)] += amount; // Record as collected fee

        // In a real system, you might also mark the specific swap related to the slashing.
        // This simplified version just updates the bond balance.
        emit BondSlashed(resolverAddress, amount, msg.sender);
    }


    // --- View Functions ---

    /// @notice Gets the details of a specific swap.
    /// @param swapId The ID of the swap.
    /// @return Swap details struct.
    function getSwapDetails(uint256 swapId) external view returns (Swap memory) {
        // Return empty struct for non-existent swap (initiator will be address(0))
        return s_swaps[swapId];
    }

    /// @notice Gets the current bond amount for a resolver.
    /// @param resolverAddress The resolver address.
    /// @return The bond amount in native token.
    function getResolverBond(address resolverAddress) external view returns (uint256) {
        return s_resolverBonds[resolverAddress];
    }

    /// @notice Checks if an address is a registered resolver.
    /// @param resolverAddress The address to check.
    /// @return True if registered, false otherwise.
    function isResolverRegistered(address resolverAddress) external view returns (bool) {
        return s_resolverRegistry[resolverAddress];
    }

    /// @notice Gets the trusted oracle address for a condition type.
    /// @param conditionTypeHash The hash identifier for the condition type.
    /// @return The oracle address.
    function getOracleAddress(bytes32 conditionTypeHash) external view returns (address) {
        return s_conditionOracles[conditionTypeHash];
    }

    /// @notice Gets the current execution fee.
    /// @return The execution fee amount in native token.
    function getExecutionFee() external view returns (uint256) {
        return s_executionFee;
    }

    /// @notice Gets the current fee recipient address.
    /// @return The fee recipient address.
    function getFeeRecipient() external view returns (address) {
        return s_feeRecipient;
    }

    /// @notice Gets the total collected fees for a token.
    /// @param token The token address (address(0) for native token).
    /// @return The total collected amount.
    function getTotalCollectedFees(address token) external view returns (uint256) {
        return s_totalCollectedFees[token];
    }

    /// @notice Checks if a condition type hash is trusted.
    /// @param conditionTypeHash The hash identifier for the condition type.
    /// @return True if trusted, false otherwise.
    function isTrustedConditionType(bytes32 conditionTypeHash) external view returns (bool) {
        return s_trustedConditionTypes[conditionTypeHash];
    }

    /// @notice Gets the minimum required resolver bond.
    /// @return The minimum bond amount.
    function getMinimumResolverBond() external view returns (uint256) {
        return s_minResolverBond;
    }

    // --- Internal / Mock Functions ---

    /// @dev Mock function to simulate oracle proof verification.
    /// In a real system, this would be complex interaction with a specific oracle contract.
    /// @param oracleAddress The address of the trusted oracle for this condition type.
    /// @param conditionHash The hash of the condition parameters.
    /// @param oracleProof The proof provided by the resolver.
    /// @return True if the proof is considered valid, false otherwise.
    function _mockVerifyOracleProof(address oracleAddress, bytes32 conditionHash, bytes memory oracleProof) internal view returns (bool) {
        // This is a simplified placeholder.
        // Real verification might involve:
        // - Calling a function on the `oracleAddress` contract with `conditionHash` and `oracleProof`.
        // - Verifying a cryptographic signature within `oracleProof` against a trusted oracle key.
        // - Checking that the `oracleAddress` is indeed the trusted oracle for this `conditionType`.

        // For this example, we'll just check that the oracle address is set and the proof is not empty.
        // A more complex mock could check if the proof matches a simple hardcoded value or pattern
        // related to the conditionHash.
        require(oracleAddress != address(0), "No oracle set for condition");
        return oracleProof.length > 0; // Basic validation: proof exists
    }


    // --- Receive/Fallback ---
    receive() external payable {
        // Allow receiving ETH for native token swaps or resolver bonds.
        // Could add logic here to distinguish purposes if needed.
    }

    fallback() external payable {
        // Optional: Handle unexpected ETH or calls. Default is revert.
    }
}
```

**Explanation of Features & Why they fit the criteria:**

1.  **Conditional Swaps (`initiateSwap`, `attestConditionMet`, `executeSwap`):** The core swap logic is gated by an external condition. This moves beyond simple atomic swaps (like HTLCs based on hash secrets) to allowing arbitrary, complex conditions (like price thresholds, event occurrences on other chains) verifiable by an oracle/resolver.
    *   *Advanced/Creative:* Introduces external state dependency and a dedicated attestation role.
    *   *Trendy:* Integrates with oracle patterns crucial for connecting blockchain to the real world or other chains.

2.  **Time-Locked/Expiry (`deadline`, `expireSwap`):** Ensures funds are not locked indefinitely if conditions are never met or execution doesn't happen.
    *   *Standard Pattern:* But essential for robustness in a time-sensitive conditional context.

3.  **Resolver Role (`registerResolver`, `attestConditionMet`, `provideResolverBond`, `claimResolverBond`, `slashResolverBond`):** A distinct role responsible for verifying the off-chain/cross-chain condition and signaling it to the contract. This decentralizes the oracle interaction part.
    *   *Advanced/Creative:* Defines a specific role with incentives (bond) and penalties (slashing).
    *   *Trendy:* Relates to decentralized oracle networks and proof-of-stake/attestation models.

4.  **Bonding and Slashing:** Resolvers stake a bond that can be slashed if they provide incorrect attestations (in a real system, this slashing would be triggered by a consensus mechanism or trusted governance/oracle).
    *   *Advanced:* Implements cryptoeconomic security mechanisms.

5.  **Delegated Execution (`executeSwap` callable by anyone):** Once the condition is met, anyone can pay gas to execute the swap and collect a fee. This incentivizes timely completion of the swap state transition.
    *   *Trendy:* Similar to relayer networks in meta-transactions or decentralized exchanges, improving user experience by abstracting gas costs.

6.  **Trusted Condition Types and Oracles (`setTrustedConditionType`, `setOracleAddress`, `isTrustedConditionType`, `getOracleAddress`):** The contract doesn't trust *any* condition or oracle. It requires specific condition types to be whitelisted and linked to a trusted oracle address managed by the owner. This adds a layer of control and security against arbitrary or malicious conditions.
    *   *Advanced:* Implements a permissioned oracle/condition system.

7.  **Multi-Token Support (ERC20 and Native Token):** Handles both ERC20 tokens and the chain's native token (like ETH) for inputs, outputs, and bonds/fees. Note: ETH as `tokenOut` requires contract pre-funding or complex WETH handling, which is noted as a limitation in this concept version.
    *   *Standard/Practical:* Necessary for a flexible swap contract.

8.  **Pause Functionality:** Basic emergency pause by the owner.
    *   *Standard/Security:* A common pattern for mitigating risks in complex contracts.

9.  **Minimum 20 Functions:** The contract includes 28 explicitly defined external/public functions (including views), meeting the requirement.

10. **Non-Duplication:** While it uses common Solidity patterns (SafeERC20, ReentrancyGuard, basic access control), the *combination* of conditional execution via a dedicated resolver role, bonding/slashing for resolvers, and explicit management of trusted condition types/oracles in a generalized swap contract is not a standard, directly copy-pasted open-source contract implementation. It's a unique design concept.

This contract is complex and would require significant auditing for production use, especially the oracle interaction and slashing logic. The mock oracle verification (`_mockVerifyOracleProof`) is the most simplified part and would need a robust, real-world implementation.