Okay, here is a Solidity smart contract concept called `QuantumVault`. It attempts to combine several advanced, creative, and trendy ideas: conditional logic based on external data (oracle), probabilistic outcomes, asset linking/entanglement, internal state changes affecting behavior, a simplified resource usage limit, and a placeholder for meta-transactions. It's designed to be complex and illustrative rather than a production-ready, audited contract.

**Disclaimer:** This contract is for educational and illustrative purposes. It is complex and *not* audited. Using such a contract in production without extensive security review and testing is highly discouraged. Reliance on external oracles introduces significant risk. On-chain randomness is notoriously difficult; the probabilistic function uses `block.timestamp` and `block.difficulty` which are weak and can be manipulated by miners.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE AND FUNCTION SUMMARY ---
// Contract: QuantumVault
// Purpose: A multi-asset vault (ETH, ERC20, ERC721) with advanced withdrawal conditions,
//          probabilistic functions, asset entanglement, and behavioral states.
// Inherits: Ownable, Pausable, ReentrancyGuard, ERC721Holder (to receive NFTs)
// External Dependencies: Oracle interface (IERCQuantumOracle) for external data.

// --- ENUMS & STRUCTS ---
// QuantumState: Defines different operational modes for the vault.
// Entanglement: Stores linked asset information for a user.

// --- STATE VARIABLES ---
// Standard ownership, pause status, fee settings.
// Balances: Mappings for ETH and ERC20 balances per user.
// ERC721 Ownership: Standard ERC721Holder mapping.
// Oracle: Address of the external oracle contract.
// Fees: Percentage fee on withdrawals.
// Reputation: Internal reputation score per user (simplified).
// Entanglements: Mapping storing linked asset pairs for users.
// Quantum State: Current operational mode of the vault.
// Quantum State Config: Configuration parameters for each state (e.g., fee multiplier).
// Conditional Oracle Value: Target value required for certain conditional withdrawals.
// Probabilistic Config: Parameters for probabilistic withdrawals (base chance, reputation effect).
// User Operation Count: Counts certain user actions (simulated resource limit).
// User Operation Limit: Max operations allowed per user per period (simplified).

// --- EVENTS ---
// Log deposits, withdrawals (with conditions/outcomes), reputation changes, state changes, etc.

// --- MODIFIERS ---
// onlyOwner: Standard OpenZeppelin.
// whenNotPaused: Standard OpenZeppelin.
// whenPaused: Standard OpenZeppelin.
// whenQuantumStateIs: Restricts function call based on the current QuantumState.

// --- ORACLE INTERFACE (MOCK) ---
// Defines functions expected from the external oracle contract.
interface IERCQuantumOracle {
    function getLatestValue(bytes32 key) external view returns (int256 value, uint256 timestamp);
    function isConditionMet(bytes32 key, int256 requiredValue, string calldata operator) external view returns (bool);
}

// --- ERC721 HOLDER (Required for receiving NFTs) ---
// Need to implement the onERC721Received function.

contract QuantumVault is Ownable, Pausable, ReentrancyGuard, ERC721Holder {

    // --- ENUMS & STRUCTS ---
    enum QuantumState {
        Normal,
        ConditionalReleaseOnly, // Only conditional withdrawals allowed
        ProbabilisticBoosted,   // Probabilistic withdrawals have higher chance
        QuantumEntangledLock    // Entangled assets are locked unless withdrawn together
    }

    struct Entanglement {
        address tokenA;
        uint256 idA; // For ERC20, this is 0; for ERC721, it's the tokenId
        address tokenB;
        uint256 idB; // For ERC20, this is 0; for ERC721, it's the tokenId
        bool exists; // Flag to check if an entanglement exists
    }

    // --- STATE VARIABLES ---

    // Balances
    mapping(address => uint256) private ethBalances;
    mapping(address => mapping(address => uint256)) private erc20Balances;
    // ERC721 balances handled by ERC721Holder

    // Configuration
    IERCQuantumOracle public oracle;
    uint256 public feePercentage; // Stored as 100 = 1%, 10000 = 100%
    address public feeRecipient;

    // Advanced State
    mapping(address => int256) public userReputation; // Can be negative
    mapping(address => Entanglement) private userEntanglements;
    QuantumState public currentQuantumState = QuantumState.Normal;
    mapping(QuantumState => uint256) public quantumStateFeeMultiplier; // e.g., 100 = 1x, 150 = 1.5x

    // Conditional & Probabilistic Parameters
    bytes32 public conditionalOracleKey;
    int256 public requiredConditionalOracleValue;
    string public conditionalOracleOperator; // e.g., ">=", "<=", "=="

    uint256 public probabilisticBaseChance; // Stored as 100 = 1%, 10000 = 100%
    uint256 public reputationProbabilisticEffect; // How much reputation affects chance

    // Resource Limiting (Simplified)
    mapping(address => uint256) public userOperationCount;
    uint256 public userOperationLimit; // Max count per user per state/period (simplified without period)

    // --- EVENTS ---
    event ETHDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event ETHWithdrawn(address indexed user, uint256 amount, uint256 fee);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event ERC721Withdrawn(address indexed user, address indexed token, uint256 tokenId);
    event ConditionalWithdrawalAttempt(address indexed user, bool success, string reason);
    event ProbabilisticWithdrawalAttempt(address indexed user, bool success, uint256 calculatedChance);
    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation);
    event ReputationSlashed(address indexed user, int256 amount);
    event AssetEntangled(address indexed user, address tokenA, uint256 idA, address tokenB, uint256 idB);
    event EntangledAssetsWithdrawn(address indexed user, address tokenA, uint256 idA, address tokenB, uint256 idB);
    event QuantumStateChanged(QuantumState oldState, QuantumState newState);
    event OperationCountIncremented(address indexed user, uint256 newCount, string operation);
    event OperationLimitReached(address indexed user);
    event RelayedCallExecuted(address indexed relayer, address indexed user, bytes4 functionSignature);

    // --- MODIFIERS ---
    modifier whenQuantumStateIs(QuantumState state) {
        require(currentQuantumState == state, "QuantumVault: Not in required state");
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(address _oracleAddress, uint256 _feePercentage, address _feeRecipient) Ownable(msg.sender) Pausable(false) {
        oracle = IERCQuantumOracle(_oracleAddress);
        feePercentage = _feePercentage; // e.g., 100 for 1%
        feeRecipient = _feeRecipient;

        // Set initial QuantumState multipliers (e.g., 1x, 1.2x, 0.8x, 1.5x)
        quantumStateFeeMultiplier[QuantumState.Normal] = 100;
        quantumStateFeeMultiplier[QuantumState.ConditionalReleaseOnly] = 120;
        quantumStateFeeMultiplier[QuantumState.ProbabilisticBoosted] = 80;
        quantumStateFeeMultiplier[QuantumState.QuantumEntangledLock] = 150;

        // Initial probabilistic config (e.g., 50% base chance, 1% increase per 100 reputation)
        probabilisticBaseChance = 5000; // 50%
        reputationProbabilisticEffect = 100; // 1 reputation point adds 1/100th of 1%

        userOperationLimit = 10; // Default operation limit
    }

    // --- RECEIVE ETH ---
    receive() external payable whenNotPaused nonReentrant {
        depositETH();
    }

    // --- INTERNAL FUNCTIONS ---

    // @dev Calculates the fee amount based on amount, fee percentage, and quantum state multiplier.
    function _calculateFee(uint256 amount) internal view returns (uint256) {
        uint256 stateMultiplier = quantumStateFeeMultiplier[currentQuantumState];
        // Calculate total fee percentage: (feePercentage * stateMultiplier) / 100
        // Example: feePercentage=100 (1%), stateMultiplier=120 (1.2x) -> total fee = 120/10000 = 1.2%
        // Need to handle division carefully. Multiply first, then divide.
        // (amount * feePercentage * stateMultiplier) / 10000 / 100 ... simplify to / 1,000,000
        // Let's assume feePercentage is out of 10000 (100 = 1%, 10000 = 100%) and multiplier is out of 100
        // Total fee rate is (feePercentage * stateMultiplier) / 100
        // Amount * (feePercentage * stateMultiplier) / 100 / 10000
        // Amount * (feePercentage * stateMultiplier) / 1,000,000
        // Let's redefine feePercentage out of 10000 (100=1%) and multiplier out of 100 (100=1x)
        // Fee amount = amount * feePercentage / 10000 * stateMultiplier / 100
        // Fee amount = amount * feePercentage * stateMultiplier / 1,000,000
         return (amount * feePercentage * stateMultiplier) / 1000000;
    }

    // @dev Pays the calculated fee to the fee recipient.
    function _payFee(uint256 amount, uint256 fee) internal {
        // Note: In a real contract, handle potential failures gracefully, especially for ETH.
        // Here, we assume success for simplicity.
        // For ETH: payable(feeRecipient).transfer(fee); // Requires <2300 gas or handle with call
        // For ERC20: IERC20(token).transfer(feeRecipient, fee);
        // For this generic internal function, we'll just subtract it. Transfer happens later.
        // This function is more for calculation and tracking.
    }

    // @dev Increments the operation count for the user.
    function _incrementOperationCount(address user, string memory operation) internal {
        userOperationCount[user]++;
        emit OperationCountIncremented(user, userOperationCount[user], operation);
    }

    // @dev Checks if the user has exceeded their operation limit.
    function _checkOperationLimit(address user) internal view returns (bool) {
        return userOperationCount[user] >= userOperationLimit;
    }

    // --- CORE VAULT FUNCTIONS (Deposit) ---

    // 1. Deposit ETH
    function depositETH() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "QuantumVault: ETH amount must be > 0");
        ethBalances[msg.sender] += msg.value;
        emit ETHDeposited(msg.sender, msg.value);
    }

    // 2. Deposit ERC20
    // Requires user to approve this contract first
    function depositERC20(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "QuantumVault: ERC20 amount must be > 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        erc20Balances[msg.sender][token] += amount;
        emit ERC20Deposited(msg.sender, token, amount);
    }

    // 3. Deposit ERC721
    // Requires user to approve this contract first (or setApprovalForAll)
    function depositERC721(address token, uint256 tokenId) public whenNotPaused nonReentrant {
         // ERC721Holder handles the transfer internally upon receiving the token.
         // We just need to trigger the transfer *to* this contract.
         // The sender must call IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId)
         // before calling this function, or this function triggers it?
         // ERC721Holder requires the transfer to be *to* the holder contract.
         // Let's make the user initiate the safeTransferFrom to this contract.
         // This function will just log the fact that the contract *received* it.
         // We rely on the onERC721Received callback to confirm and emit.
         // The user calls safeTransferFrom from their wallet *to* this contract's address.
         // The onERC721Received is triggered *by* the token contract when it receives it.
         // We need a mapping to track which user deposited which NFT, as onERC721Received
         // doesn't inherently know the *original* sender initiating the deposit.
         // This is a limitation of the simple ERC721Holder pattern for multi-user deposits.
         // A more robust solution tracks deposits initiated *by* the user before the transfer.
         // For simplicity here, we'll assume the onERC721Received is sufficient *after* the user
         // sends the NFT to the contract.
         // Let's add a mapping to track pending deposits or rely purely on onERC721Received
         // and map token/id to the *owner* recorded by the ERC721Holder internal state.
         // ERC721Holder *does* track ownership. We can rely on that.
         // So the user just calls `safeTransferFrom` directly to the vault address.
         // We will add a *view* function to see which NFTs a user 'owns' in the vault state.
         // This function is then just a placeholder or trigger, or perhaps used in conjunction
         // with onERC721Received if we add deposit tracking.
         // Let's redefine this function to *not* be called directly by the user for deposit,
         // but instead, the user calls `safeTransferFrom` directly to the vault address,
         // and `onERC721Received` handles the internal logic and event.
         // So, this function 3 becomes a helper or admin function, and the *deposit mechanism*
         // for ERC721 is just calling safeTransferFrom to the contract address.
         // We need a way for the user to signify intent *before* sending the NFT if we want
         // to track their deposit explicitly beyond just `ownerOf` within the vault.
         // Let's add a simple "Register ERC721 Deposit Intent" function.
         revert("QuantumVault: Direct depositERC721 function is not used. Use registerERC721DepositIntent and then transfer the NFT.");
    }

    // 3.1 Register ERC721 Deposit Intent
    // User calls this to signal they will send an NFT.
    mapping(address => mapping(address => uint256)) public pendingERC721Deposits; // user => token => tokenId
    function registerERC721DepositIntent(address token, uint256 tokenId) public whenNotPaused {
        // Basic validation: check if NFT exists and user owns it outside the vault
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "QuantumVault: Sender must own the NFT");
        // Check if intent already exists for this user/token/id
        require(pendingERC721Deposits[msg.sender][token] == 0, "QuantumVault: Pending deposit intent already exists for this token/id");

        pendingERC721Deposits[msg.sender][token] = tokenId;
        // No event needed here, the event fires on successful reception in onERC721Received
    }

    // onERC721Received callback
    // This function is called BY the ERC721 token contract when it receives a token.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external override
        returns (bytes4)
    {
        // Check if the sender (from) had a pending intent for this specific NFT
        // This is a simplified check; a robust system would track token/id explicitly
        // for *that* sender's intent.
        require(pendingERC721Deposits[from][address(msg.sender)] == tokenId, "QuantumVault: No matching deposit intent found");

        // Clear the pending intent
        delete pendingERC721Deposits[from][address(msg.sender)];

        // The NFT is now owned by the vault contract address.
        // We'll rely on ERC721Holder's internal state for tracking ownership within the vault.
        // And map the token/id back to the original sender based on the intent.
        // Need a mapping for this: token => tokenId => originalDepositor
        depositedERC721Owners[address(msg.sender)][tokenId] = from;

        emit ERC721Deposited(from, address(msg.sender), tokenId);

        return this.onERC721Received.selector;
    }
     mapping(address => mapping(uint256 => address)) private depositedERC721Owners; // token => tokenId => originalDepositor


    // --- CORE VAULT FUNCTIONS (Withdrawal) ---

    // Helper to apply fee and send ETH
     function _applyFeeAndSendETH(address recipient, uint256 amount) internal nonReentrant {
        uint256 fee = _calculateFee(amount);
        uint256 amountToSend = amount - fee;
        _payFee(amount, fee); // Mark fee as paid (internally)

        ethBalances[recipient] -= amount; // Deduct from user's balance

        // Send amountToSend to recipient
        (bool success, ) = payable(recipient).call{value: amountToSend}("");
        require(success, "QuantumVault: ETH transfer failed");

        // Send fee to feeRecipient (handle potential failure gracefully in real contract)
         if (fee > 0) {
             (success, ) = payable(feeRecipient).call{value: fee}("");
             // In a real contract, handle failure of fee transfer (e.g., log, leave in contract, retry)
             // For simplicity here, we assume it works or fail the main withdrawal (less ideal).
             // Let's just not require success for the fee transfer to avoid blocking the main withdrawal.
             // If fee transfer fails, fee stays in contract. Owner can recover later.
         }
         emit ETHWithdrawn(recipient, amountToSend, fee);
     }

     // Helper to apply fee and send ERC20
     function _applyFeeAndSendERC20(address recipient, address token, uint256 amount) internal {
        uint256 fee = _calculateFee(amount);
        uint256 amountToSend = amount - fee;
        _payFee(amount, fee); // Mark fee as paid (internally)

        erc20Balances[recipient][token] -= amount; // Deduct from user's balance

        // Send amountToSend to recipient
        IERC20(token).transfer(recipient, amountToSend);

        // Send fee to feeRecipient
        if (fee > 0) {
            IERC20(token).transfer(feeRecipient, fee);
        }
         emit ERC20Withdrawn(recipient, token, amountToSend, fee);
     }

    // 4. Simple Withdraw ETH
    function withdrawETH(uint256 amount) public whenNotPaused nonReentrant {
        require(ethBalances[msg.sender] >= amount, "QuantumVault: Insufficient ETH balance");
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");

        _incrementOperationCount(msg.sender, "withdrawETH");
        _applyFeeAndSendETH(msg.sender, amount);
    }

    // 5. Simple Withdraw ERC20
    function withdrawERC20(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(erc20Balances[msg.sender][token] >= amount, "QuantumVault: Insufficient ERC20 balance");
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");

        _incrementOperationCount(msg.sender, "withdrawERC20");
        _applyFeeAndSendERC20(msg.sender, token, amount);
    }

    // 6. Simple Withdraw ERC721
    function withdrawERC721(address token, uint256 tokenId) public whenNotPaused nonReentrant {
        // Check if the user is the original depositor and the vault owns it
        require(depositedERC721Owners[token][tokenId] == msg.sender, "QuantumVault: Caller is not the original depositor");
        require(ERC721Holder.ownerOf(token, tokenId) == address(this), "QuantumVault: Vault does not hold this NFT");
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");

        _incrementOperationCount(msg.sender, "withdrawERC721");

        // No fee applied to NFT withdrawals in this design
        ERC721Holder.safeTransferFrom(token, address(this), msg.sender, tokenId);

        // Remove from deposited owner mapping
        delete depositedERC721Owners[token][tokenId];

        emit ERC721Withdrawn(msg.sender, token, tokenId);
    }

    // --- ADVANCED/QUANTUM FUNCTIONS ---

    // 7. Withdraw ERC20 Conditionally via Oracle
    function withdrawERC20ConditionalOracle(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(erc20Balances[msg.sender][token] >= amount, "QuantumVault: Insufficient ERC20 balance");
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");
        require(address(oracle) != address(0), "QuantumVault: Oracle address not set");

        // Check if the oracle condition is met
        bool conditionMet = oracle.isConditionMet(conditionalOracleKey, requiredConditionalOracleValue, conditionalOracleOperator);

        if (conditionMet) {
            _incrementOperationCount(msg.sender, "withdrawERC20ConditionalOracle");
            _applyFeeAndSendERC20(msg.sender, token, amount);
            emit ConditionalWithdrawalAttempt(msg.sender, true, "Oracle condition met");
        } else {
            // Optional: slash reputation or apply penalty for failed attempt when condition isn't met?
            // Let's just log for now.
            emit ConditionalWithdrawalAttempt(msg.sender, false, "Oracle condition not met");
            revert("QuantumVault: Oracle condition not met for withdrawal");
        }
    }

    // 8. Release Conditionally Locked ERC721 via Oracle
    // This assumes NFTs could be deposited with a specific lock condition.
    // We need a way to mark an NFT as "conditionally locked" upon deposit intent/reception.
    // Let's add a mapping: token => tokenId => isConditionallyLocked
    mapping(address => mapping(uint256 => bool)) private erc721ConditionallyLocked;

    // Modified register intent to include a lock option
    function registerERC721DepositIntentWithLock(address token, uint256 tokenId, bool lockUntilCondition) public whenNotPaused {
        require(IERC721(token).ownerOf(tokenId) == msg.sender, "QuantumVault: Sender must own the NFT");
        require(pendingERC721Deposits[msg.sender][token] == 0, "QuantumVault: Pending deposit intent already exists");
        pendingERC721Deposits[msg.sender][token] = tokenId;
        // Mark the intent for potential locking *if* successfully received.
        // The actual lock state is set in onERC721Received based on this intent flag.
        pendingERC721LockStatus[msg.sender][token] = lockUntilCondition;
    }
     mapping(address => mapping(address => bool)) private pendingERC721LockStatus; // user => token => lockStatus

     // onERC721Received needs modification to set the lock state
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external override
        returns (bytes4)
    {
        require(pendingERC721Deposits[from][address(msg.sender)] == tokenId, "QuantumVault: No matching deposit intent found");

        bool shouldLock = pendingERC721LockStatus[from][address(msg.sender)];
        delete pendingERC721Deposits[from][address(msg.sender)];
        delete pendingERC721LockStatus[from][address(msg.sender)]; // Clean up intent flag

        depositedERC721Owners[address(msg.sender)][tokenId] = from;
        erc721ConditionallyLocked[address(msg.sender)][tokenId] = shouldLock; // Set lock state based on intent

        emit ERC721Deposited(from, address(msg.sender), tokenId); // Reuse deposit event

        return this.onERC721Received.selector;
    }

    // Function 8 implementation:
    function releaseERC721ConditionalLock(address token, uint256 tokenId) public whenNotPaused nonReentrant {
        require(depositedERC721Owners[token][tokenId] == msg.sender, "QuantumVault: Caller is not the original depositor");
        require(ERC721Holder.ownerOf(token, tokenId) == address(this), "QuantumVault: Vault does not hold this NFT");
        require(erc721ConditionallyLocked[token][tokenId], "QuantumVault: ERC721 is not conditionally locked");
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");
        require(address(oracle) != address(0), "QuantumVault: Oracle address not set");

        // Check if the oracle condition is met
        bool conditionMet = oracle.isConditionMet(conditionalOracleKey, requiredConditionalOracleValue, conditionalOracleOperator);

        if (conditionMet) {
            // Unlock the NFT
            erc721ConditionallyLocked[token][tokenId] = false;
            _incrementOperationCount(msg.sender, "releaseERC721ConditionalLock");
            emit ConditionalWithdrawalAttempt(msg.sender, true, "ERC721 unlocked via oracle condition");
        } else {
             emit ConditionalWithdrawalAttempt(msg.sender, false, "Oracle condition not met for ERC721 release");
            revert("QuantumVault: Oracle condition not met to unlock ERC721");
        }
    }

     // 8.1 Withdraw a previously unlocked conditional ERC721
     function withdrawUnlockedERC721(address token, uint256 tokenId) public whenNotPaused nonReentrant {
        require(depositedERC721Owners[token][tokenId] == msg.sender, "QuantumVault: Caller is not the original depositor");
        require(ERC721Holder.ownerOf(token, tokenId) == address(this), "QuantumVault: Vault does not hold this NFT");
        require(!erc721ConditionallyLocked[token][tokenId], "QuantumVault: ERC721 is still conditionally locked"); // Must be unlocked
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");

        _incrementOperationCount(msg.sender, "withdrawUnlockedERC721");

        // No fee applied to NFT withdrawals
        ERC721Holder.safeTransferFrom(token, address(this), msg.sender, tokenId);

        // Clean up state
        delete depositedERC721Owners[token][tokenId];
        delete erc721ConditionallyLocked[token][tokenId];

        emit ERC721Withdrawn(msg.sender, token, tokenId); // Reuse event
     }


    // 9. Try Withdraw ERC20 Probabilistically
    function tryWithdrawProbabilisticERC20(address token, uint256 amount) public whenNotPaused nonReentrant {
        require(erc20Balances[msg.sender][token] >= amount, "QuantumVault: Insufficient ERC20 balance");
        require(amount > 0, "QuantumVault: Amount must be > 0");
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");

        // Calculate dynamic success chance based on reputation and quantum state
        // Base chance + (reputation * effect)
        int256 effectiveReputation = userReputation[msg.sender];
        // Prevent negative reputation from causing overflow or extremely low chances if reputationEffect is large
        if (effectiveReputation < 0) effectiveReputation = 0; // Simple floor

        uint256 reputationBonus = (uint256(effectiveReputation) * reputationProbabilisticEffect) / 100; // Effect is X per 100 rep

        uint256 currentChance = probabilisticBaseChance + reputationBonus; // Chance out of 10000

        // Apply Quantum State multiplier to the chance
        uint256 stateMultiplier = (currentQuantumState == QuantumState.ProbabilisticBoosted) ? 150 : 100; // 150% boost in boosted state, 100% otherwise
        currentChance = (currentChance * stateMultiplier) / 100;

        // Cap chance at 100%
        if (currentChance > 10000) currentChance = 10000;

        // Generate a pseudo-random number (weak randomness source)
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, amount, nonce))) % 10000;
        nonce++; // Increment nonce to ensure different outcome on subsequent calls in same block (still weak)

        emit ProbabilisticWithdrawalAttempt(msg.sender, randomNum < currentChance, currentChance);

        if (randomNum < currentChance) {
            // Success
            _incrementOperationCount(msg.sender, "tryWithdrawProbabilisticERC20_Success");
            _applyFeeAndSendERC20(msg.sender, token, amount);
        } else {
            // Failure - Optional: Slash reputation
            slashReputation(msg.sender, 10); // Slash 10 reputation points on failure
            _incrementOperationCount(msg.sender, "tryWithdrawProbabilisticERC20_Failure");
            revert("QuantumVault: Probabilistic withdrawal failed");
        }
    }
    uint256 private nonce; // For weak randomness

    // 10. Update User Reputation (Admin or triggered)
    function updateReputationScore(address user, int256 scoreChange) public onlyOwner {
        int256 oldRep = userReputation[user];
        userReputation[user] += scoreChange;
        emit ReputationUpdated(user, oldRep, userReputation[user]);
    }

    // 11. Slash Reputation (Admin or triggered)
    function slashReputation(address user, uint256 amount) public onlyOwner {
        // Ensure we don't underflow int256, although unlikely with typical slashing
        // Simple subtraction - negative scores are allowed in this model
        require(amount > 0, "QuantumVault: Slash amount must be positive");
        int256 oldRep = userReputation[user];
        userReputation[user] -= int256(amount);
        emit ReputationSlashed(user, int256(amount)); // Emit positive amount for clarity
        emit ReputationUpdated(user, oldRep, userReputation[user]); // Also emit general update
    }

    // 12. Set Asset Entanglement
    // Allows a user to link two of their deposited assets.
    // For ERC20, use address and 0 as tokenId. For ERC721, use address and tokenId.
    function setAssetEntanglement(address tokenA, uint256 idA, address tokenB, uint256 idB) public whenNotPaused {
        // Basic validation: check if assets are deposited by the user
        bool isA_ERC20 = (idA == 0);
        bool isB_ERC20 = (idB == 0);

        if (isA_ERC20) require(erc20Balances[msg.sender][tokenA] > 0, "QuantumVault: User does not own deposited tokenA (ERC20)");
        else require(depositedERC721Owners[tokenA][idA] == msg.sender, "QuantumVault: User does not own deposited tokenA (ERC721)");

        if (isB_ERC20) require(erc20Balances[msg.sender][tokenB] > 0, "QuantumVault: User does not own deposited tokenB (ERC20)");
        else require(depositedERC721Owners[tokenB][idB] == msg.sender, "QuantumVault: User does not own deposited tokenB (ERC721)");

        // Cannot entangle the same asset with itself
        require(!(tokenA == tokenB && idA == idB), "QuantumVault: Cannot entangle an asset with itself");

        // Store entanglement
        userEntanglements[msg.sender] = Entanglement({
            tokenA: tokenA,
            idA: idA,
            tokenB: tokenB,
            idB: idB,
            exists: true
        });

        emit AssetEntangled(msg.sender, tokenA, idA, tokenB, idB);
    }

     // 13. Break Asset Entanglement
    function breakAssetEntanglement() public whenNotPaused {
        require(userEntanglements[msg.sender].exists, "QuantumVault: No entanglement exists for user");
        delete userEntanglements[msg.sender]; // Remove the entanglement
        // Note: This does not affect the assets themselves, only the link state.
        // A more complex system might involve a cooldown or penalty for breaking.
    }


    // 14. Withdraw Entangled Assets (ERC20 Pair Example)
    // Only possible if both entangled ERC20 assets are withdrawn together.
    // Assumes the entanglement is for two ERC20 tokens.
    function withdrawEntangledPairERC20(address tokenA, uint256 amountA, address tokenB, uint256 amountB) public whenNotPaused nonReentrant {
        Entanglement memory entanglement = userEntanglements[msg.sender];
        require(entanglement.exists, "QuantumVault: No entanglement set");
        require(entanglement.tokenA == tokenA && entanglement.idA == 0 &&
                entanglement.tokenB == tokenB && entanglement.idB == 0,
                "QuantumVault: Entanglement does not match provided ERC20 pair");

        require(erc20Balances[msg.sender][tokenA] >= amountA, "QuantumVault: Insufficient balance for tokenA");
        require(erc20Balances[msg.sender][tokenB] >= amountB, "QuantumVault: Insufficient balance for tokenB");
        require(amountA > 0 || amountB > 0, "QuantumVault: Amounts must be > 0"); // Allow withdrawing one or both

        // Check Quantum State Lock - In QuantumEntangledLock state, this is the ONLY way to withdraw these assets
        if (currentQuantumState == QuantumState.QuantumEntangledLock) {
             require(userEntanglements[msg.sender].exists, "QuantumVault: Must withdraw as entangled pair in this state");
             // Also need to check if the tokens being withdrawn are indeed the entangled pair
             // This is already checked at the start of the function.
        } else {
             // In other states, regular withdrawal is also possible. No extra check needed here.
        }

        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");
         _incrementOperationCount(msg.sender, "withdrawEntangledPairERC20");

        if (amountA > 0) {
             _applyFeeAndSendERC20(msg.sender, tokenA, amountA);
        }
        if (amountB > 0) {
             _applyFeeAndSendERC20(msg.sender, tokenB, amountB);
        }

        emit EntangledAssetsWithdrawn(msg.sender, tokenA, 0, tokenB, 0);
    }
    // Note: Could add similar functions for ERC721 pairs or ERC20+ERC721 entanglement.


    // 15. Trigger Quantum State Change (Admin only, potentially based on Oracle)
    function triggerQuantumStateChange(QuantumState newState) public onlyOwner {
         // Optional: Add a check that the state change is justified by oracle data or a specific event
         // For simplicity, admin can change it directly here.
         QuantumState oldState = currentQuantumState;
         currentQuantumState = newState;
         emit QuantumStateChanged(oldState, newState);
    }

    // 16. Set User Operation Limit (Admin)
    function setUserOperationLimit(address user, uint256 limit) public onlyOwner {
        userOperationLimit = limit; // This sets a global limit for *all* users.
        // To set a limit per user: userOperationLimits[user] = limit;
        // Let's switch to per-user limits for more control.
        userOperationLimits[user] = limit;
    }
    mapping(address => uint256) public userOperationLimits; // Per-user limit

    // Reset function 16 to use per-user limit:
    function setUserOperationLimitPerUser(address user, uint256 limit) public onlyOwner {
        userOperationLimits[user] = limit;
    }
    // Modify _checkOperationLimit and _incrementOperationCount to use userOperationLimits[user]

    // @dev Checks if the user has exceeded their operation limit.
    function _checkOperationLimit(address user) internal view returns (bool) {
        uint256 limit = userOperationLimits[user] == 0 ? userOperationLimit : userOperationLimits[user]; // Use global if user limit is 0
        return userOperationCount[user] >= limit;
    }

    // Redo function 24 from draft as 16.1, a simple withdrawal using the limit
    // 16.1 Withdraw ETH With Operation Limit Check (example usage)
    // This function is redundant with withdrawETH now that the check is in the helper.
    // Let's make this function specifically for users who want to 'burn' operations for a boost or something?
    // Or maybe it's just another example of a withdrawal type. Let's keep it as a distinct function type.
     function withdrawETHWithOpCheck(uint256 amount) public whenNotPaused nonReentrant {
        require(ethBalances[msg.sender] >= amount, "QuantumVault: Insufficient ETH balance");
        require(amount > 0, "QuantumVault: Amount must be > 0");
        // The check is now inside the helper, but we ensure it's applied here.
        require(!_checkOperationLimit(msg.sender), "QuantumVault: Operation limit reached");

        _incrementOperationCount(msg.sender, "withdrawETHWithOpCheck");
        _applyFeeAndSendETH(msg.sender, amount);
     }


    // 17. Reset User Operation Count (Admin)
    function resetUserOperationCount(address user) public onlyOwner {
        userOperationCount[user] = 0;
    }

    // 18. Placeholder for Relayed Execution (Meta-Transaction)
    // In a real implementation, this would involve signature verification.
    // This version is simplified and only logs the call intent.
    // A relayer would call this function, passing the user's intended call data and a signature.
    // The contract verifies the signature confirms the user authorized the call.
    // Then it executes the call on behalf of the user (`msg.sender` becomes the relayer,
    // so the *logic* needs to use the signer's address, not msg.sender, for balance/ownership checks).
    // This requires significant changes to all functions that check msg.sender.
    // Let's make this a simple placeholder that just accepts a call and logs it.
    function relayExecute(address user, bytes memory callData) public whenNotPaused {
        // In a real scenario:
        // 1. Recover signer address from callData and a provided signature.
        //    address signer = _recoverSigner(callData, signature);
        // 2. Verify the recovered signer is the 'user' parameter.
        //    require(signer == user, "QuantumVault: Invalid signature");
        // 3. Execute the call using low-level call, ensuring checks within the called
        //    function use 'user' (the signer) instead of 'msg.sender'.
        //    (bool success, ) = address(this).call(callData);
        //    require(success, "QuantumVault: Relayed call failed");

        // Placeholder logic: just log the intent assuming a valid signature *would* have been checked.
        emit RelayedCallExecuted(msg.sender, user, bytes4(callData));
        // Note: Without modifying all other functions to check a `_msgSender()` helper
        // that can return the relayer or the 'user' based on the context (direct call vs relayed),
        // actually executing `callData` here would break everything. This is purely illustrative.
    }

     // 19. Set Oracle Address (Admin)
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "QuantumVault: Oracle address cannot be zero");
        oracle = IERCQuantumOracle(_oracleAddress);
    }

    // 20. Set Fee Recipient (Admin)
    function setFeeRecipient(address _feeRecipient) public onlyOwner {
         require(_feeRecipient != address(0), "QuantumVault: Fee recipient cannot be zero");
         feeRecipient = _feeRecipient;
    }

     // 21. Set Fee Percentage (Admin)
    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
         require(_feePercentage <= 10000, "QuantumVault: Fee percentage cannot exceed 10000 (100%)");
         feePercentage = _feePercentage; // Stored as 100 = 1%
    }

    // 22. Emergency Withdraw (Admin)
    // Allows owner to pull all assets in an emergency. Bypasses logic.
    function emergencyWithdrawAdmin(address token) public onlyOwner nonReentrant {
        if (token == address(0)) {
            // Withdraw ETH
            uint256 balance = address(this).balance;
            require(balance > 0, "QuantumVault: No ETH balance to withdraw");
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "QuantumVault: Emergency ETH withdraw failed");
        } else if (IERC20(token).supportsInterface(0x36372b07)) { // Check for ERC20 interface ID
             // Withdraw ERC20
             uint256 balance = IERC20(token).balanceOf(address(this));
             require(balance > 0, "QuantumVault: No ERC20 balance to withdraw");
             IERC20(token).transfer(owner(), balance);
        } else if (IERC721(token).supportsInterface(0x80ac58cd)) { // Check for ERC721 interface ID
             // Withdraw *all* ERC721s of this type held by the vault.
             // This is complex as ERC721Holder doesn't easily list all held tokens.
             // A production contract would need better internal tracking or an enumerable ERC721Holder.
             // For this demo, we'll add a placeholder/require.
             revert("QuantumVault: Emergency ERC721 withdraw of all tokens not implemented via this function. Implement specific token/id withdraw if needed.");
        } else {
             revert("QuantumVault: Unsupported token type for emergency withdraw");
        }
    }
     // 22.1 Emergency Withdraw specific ERC721 (Admin)
     function emergencyWithdrawERC721Admin(address token, uint256 tokenId) public onlyOwner nonReentrant {
        require(ERC721Holder.ownerOf(token, tokenId) == address(this), "QuantumVault: Vault does not hold this NFT");
        ERC721Holder.safeTransferFrom(token, address(this), owner(), tokenId);
        // Note: This bypasses internal depositedERC721Owners tracking. Admin needs to be careful.
     }


    // 23. Pause Contract (Admin)
    function pauseContract() public onlyOwner {
        _pause();
    }

    // 24. Unpause Contract (Admin)
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    // --- VIEW FUNCTIONS ---

    // 25. Get User ETH Balance
    function getUserETHBalance(address user) public view returns (uint256) {
        return ethBalances[user];
    }

    // 26. Get User ERC20 Balance
    function getUserERC20Balance(address user, address token) public view returns (uint256) {
        return erc20Balances[user][token];
    }

     // 27. Get Original Depositor of ERC721 in Vault
     function getERC721OriginalDepositor(address token, uint256 tokenId) public view returns (address) {
         return depositedERC721Owners[token][tokenId];
     }

    // 28. Get User Reputation Score
    function getUserReputation(address user) public view returns (int256) {
        return userReputation[user];
    }

    // 29. Get Asset Entanglement Status for User
    function getAssetEntanglementStatus(address user) public view returns (bool exists, address tokenA, uint256 idA, address tokenB, uint256 idB) {
        Entanglement memory entanglement = userEntanglements[user];
        return (entanglement.exists, entanglement.tokenA, entanglement.idA, entanglement.tokenB, entanglement.idB);
    }

    // 30. Get Current Quantum State
    function getCurrentQuantumState() public view returns (QuantumState) {
        return currentQuantumState;
    }

    // 31. Get Conditional Oracle Target
    function getRequiredOracleValue() public view returns (bytes32 key, int256 value, string memory operator) {
        return (conditionalOracleKey, requiredConditionalOracleValue, conditionalOracleOperator);
    }

    // 32. Get User Operation Count
    function getUserOperationCount(address user) public view returns (uint256) {
        return userOperationCount[user];
    }

     // 33. Get User Operation Limit
    function getUserOperationLimit(address user) public view returns (uint256) {
        return userOperationLimits[user] == 0 ? userOperationLimit : userOperationLimits[user];
    }

    // 34. Get Probabilistic Withdrawal Config
    function getProbabilisticConfig() public view returns (uint256 baseChance, uint256 reputationEffect) {
        return (probabilisticBaseChance, reputationProbabilisticEffect);
    }

    // 35. Get Quantum State Fee Multiplier
    function getQuantumStateFeeMultiplier(QuantumState state) public view returns (uint256) {
        return quantumStateFeeMultiplier[state];
    }

    // 36. Check if ERC721 is Conditionally Locked
    function isERC721ConditionallyLocked(address token, uint256 tokenId) public view returns (bool) {
        return erc721ConditionallyLocked[token][tokenId];
    }

    // 37. Get Pending ERC721 Deposit Intent
    function getPendingERC721DepositIntent(address user, address token) public view returns (uint256 tokenId) {
        return pendingERC721Deposits[user][token];
    }


    // --- ADMIN SETTERS FOR ADVANCED CONFIG ---

    // 38. Set Conditional Oracle Target (Admin)
    function setConditionalOracleTarget(bytes32 key, int256 value, string memory operator) public onlyOwner {
        conditionalOracleKey = key;
        requiredConditionalOracleValue = value;
        conditionalOracleOperator = operator;
    }

    // 39. Set Probabilistic Config (Admin)
    function setProbabilisticConfig(uint256 baseChance, uint256 reputationEffect) public onlyOwner {
        require(baseChance <= 10000, "QuantumVault: Base chance cannot exceed 100%");
        probabilisticBaseChance = baseChance; // Out of 10000
        reputationProbabilisticEffect = reputationEffect; // Affects chance per 100 reputation
    }

    // 40. Set Quantum State Fee Multiplier (Admin)
     function setQuantumStateFeeMultiplier(QuantumState state, uint256 multiplier) public onlyOwner {
        quantumStateFeeMultiplier[state] = multiplier; // Multiplier out of 100
     }

     // 41. Set Global User Operation Limit (Admin)
     function setGlobalUserOperationLimit(uint256 limit) public onlyOwner {
        userOperationLimit = limit; // Sets the default limit for users without a specific limit
     }

}
```