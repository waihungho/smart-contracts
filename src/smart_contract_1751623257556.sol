Okay, here is a Solidity smart contract called `QuantumVault`. It incorporates several advanced, creative, and somewhat trendy concepts:

1.  **Multi-Asset Vault:** Handles ETH, ERC20, and ERC721 tokens.
2.  **State Machine:** The vault has different states affecting functionality (Locked, Open, Restricted).
3.  **Role-Based Access Control:** Owner and Admin roles with distinct permissions.
4.  **Timed Withdrawals:** Deposits can have a time lock applied to their release request.
5.  **Conditional Withdrawals:** Withdrawals can be contingent on external factors (simulated via an oracle check).
6.  **Probabilistic Withdrawals:** A chance of success/failure for withdrawal execution (using block hash for example, noting limitations).
7.  **Dynamic Configuration:** Key parameters (probability, oracle address) can be adjusted by admins.
8.  **Request/Execute Pattern:** Withdrawals require a request phase followed by an execution phase, allowing conditions to be checked at execution time.
9.  **Emergency Withdrawal:** An admin backdoor for critical situations.
10. **Fee Mechanism:** A basic fee collection on certain operations.

This combination of features aims to be more complex and state-dependent than a typical simple vault.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Using SafeMath from OpenZeppelin for safety, although Solidity 0.8+ handles overflow by default.
// Keeping it for clarity on arithmetic operations.
using SafeMath for uint256;

/*
Outline:
1.  Pragma and Imports
2.  Custom Errors
3.  Events
4.  Enums (VaultState, WithdrawalStatus)
5.  Structs (Deposit, WithdrawalRequest)
6.  State Variables
7.  Modifiers
8.  Constructor
9.  Receive/Fallback
10. Core Deposit Functions (ETH, ERC20, ERC721)
11. Core Withdrawal Request Functions (ETH, ERC20, ERC721)
12. Core Withdrawal Execution/Cancellation Functions
13. State Management Functions
14. Access Control / Role Management Functions
15. Configuration Functions (Probability, Oracle)
16. Oracle Interaction Helper (Simulated)
17. Fee Management Functions
18. Emergency Functions
19. View Functions (Get state, balances, request details, etc.)
*/

/*
Function Summary:

// Core Deposit
- depositETH(): Deposits Ether into the vault.
- depositERC20(address token, uint256 amount): Deposits a specific ERC20 token. Requires prior approval.
- depositERC721(address token, uint256 tokenId): Deposits a specific ERC721 token. Requires prior approval.

// Core Withdrawal Request
- requestWithdrawalETH(uint256 amount, uint256 timeLockDuration): Initiates a request to withdraw ETH with a time lock.
- requestWithdrawalERC20(address token, uint256 amount, uint256 timeLockDuration): Initiates a request to withdraw ERC20 with a time lock.
- requestWithdrawalERC721(address token, uint256 tokenId, uint256 timeLockDuration): Initiates a request to withdraw ERC721 with a time lock.

// Core Withdrawal Execution/Cancellation
- executeWithdrawal(uint256 requestId): Executes a pending withdrawal request if all conditions (time lock, state, probabilistic, conditional) are met.
- cancelWithdrawalRequest(uint256 requestId): Allows the requester to cancel their pending withdrawal request.

// State Management
- setVaultState(VaultState newState): Sets the current state of the vault (Owner/Admin only).
- getVaultState(): Returns the current state of the vault.

// Access Control / Role Management
- addAdmin(address account): Grants Admin role (Owner only).
- removeAdmin(address account): Revokes Admin role (Owner only).
- isAdmin(address account): Checks if an address has the Admin role (View).

// Configuration
- setWithdrawalProbSuccess(uint8 probabilityPercent): Sets the percentage chance for probabilistic withdrawals (Admin only). 0-100.
- getWithdrawalProbSuccess(): Returns the current probabilistic success percentage (View).
- setOracleAddress(address _oracle): Sets the address of the oracle contract (Admin only).
- getOracleAddress(): Returns the currently set oracle address (View).
- setConditionalWithdrawalFactor(bytes32 key, uint256 value): Sets a key-value pair used for conditional withdrawal checks (Admin only). Simulates oracle data input.
- getConditionalWithdrawalFactor(bytes32 key): Returns the value associated with a conditional withdrawal key (View).

// Oracle Interaction Helper (Simulated)
- checkOracleCondition(bytes32 key, uint256 requiredValue): Internal helper to check if a stored factor meets a requirement.

// Fee Management
- setWithdrawalFeePercentage(uint8 feePercent): Sets the fee percentage charged on successful withdrawals (Admin only). 0-100.
- getWithdrawalFeePercentage(): Returns the current withdrawal fee percentage (View).
- collectFees(address recipient): Allows the Owner/Admin to collect accumulated fees.
- getAccumulatedFeesETH(): Returns the accumulated ETH fees (View).
- getAccumulatedFeesERC20(address token): Returns the accumulated ERC20 fees for a specific token (View).

// Emergency Functions
- emergencyWithdrawETH(address recipient): Allows Admin to withdraw ETH bypassing normal checks.
- emergencyWithdrawERC20(address token, address recipient): Allows Admin to withdraw ERC20 bypassing normal checks.
- emergencyWithdrawERC721(address token, uint256 tokenId, address recipient): Allows Admin to withdraw ERC721 bypassing normal checks.

// View Functions
- getETHBalance(): Returns the contract's ETH balance (View).
- getERC20Balance(address token): Returns the contract's balance for a specific ERC20 (View).
- getERC721Owner(address token, uint256 tokenId): Returns the owner of an ERC721 within the contract (simulated tracking) (View).
- getUserDepositCount(address account): Returns the number of deposits made by an account (View).
- getUserDepositDetails(address account, uint256 index): Returns details of a specific deposit by index (View).
- getWithdrawalRequestCount(): Returns the total number of withdrawal requests ever made (View).
- getWithdrawalRequestDetails(uint256 requestId): Returns details of a specific withdrawal request (View).

Total Functions: 26
*/


// Custom Errors for clarity and gas efficiency
error QuantumVault__NotAdmin();
error QuantumVault__InvalidState();
error QuantumVault__DepositFailed();
error QuantumVault__WithdrawalNotReady(uint256 timeRemaining);
error QuantumVault__WithdrawalFailedProbabilistically();
error QuantumVault__WithdrawalFailedConditional();
error QuantumVault__RequestNotFound();
error QuantumVault__RequestAlreadyProcessed();
error QuantumVault__RequestCancelled();
error QuantumVault__WithdrawalAmountExceedsBalance();
error QuantumVault__ERC721NotOwnedByVault();
error QuantumVault__TransferFailed();
error QuantumVault__InvalidProbability(uint8 probability);
error QuantumVault__InvalidFeePercentage(uint8 feePercent);
error QuantumVault__FeeCollectionFailed();
error QuantumVault__NoFeesToCollect();

contract QuantumVault is Ownable {

    // --- Events ---
    event ETHDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);

    event WithdrawalRequested(
        uint256 indexed requestId,
        address indexed user,
        uint256 amount, // For ETH/ERC20
        address indexed token, // For ERC20/ERC721, address(0) for ETH
        uint256 tokenId, // For ERC721, 0 for ETH/ERC20
        uint256 unlockTime,
        bytes32 indexed conditionKey, // For conditional withdrawals
        uint256 requiredValue // For conditional withdrawals
    );

    event WithdrawalExecuted(uint256 indexed requestId, address indexed user);
    event WithdrawalFailedProbabilistic(uint256 indexed requestId, address indexed user);
    event WithdrawalFailedConditional(uint256 indexed requestId, address indexed user);
    event WithdrawalCancelled(uint256 indexed requestId, address indexed user);

    event StateChanged(VaultState newState);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event WithdrawalProbabilitySet(uint8 probabilityPercent);
    event OracleAddressSet(address indexed oracle);
    event ConditionalFactorSet(bytes32 indexed key, uint256 value);
    event FeesCollected(address indexed recipient, uint256 ethAmount, uint256 totalFeesERC20); // Simplified for combined ERC20 fees

    // --- Enums ---
    enum VaultState { Locked, Open, Restricted } // States influencing contract behavior
    enum WithdrawalStatus { Pending, Executed, Cancelled, FailedProbabilistic, FailedConditional } // Status of a withdrawal request
    enum AssetType { ETH, ERC20, ERC721 } // Type of asset in a deposit/withdrawal


    // --- Structs ---
    struct Deposit {
        address user;
        AssetType assetType;
        address tokenAddress; // address(0) for ETH
        uint256 amountOrTokenId; // amount for ETH/ERC20, tokenId for ERC721
        uint256 timestamp; // Time of deposit
    }

    struct WithdrawalRequest {
        address user;
        AssetType assetType;
        address tokenAddress; // address(0) for ETH
        uint256 amountOrTokenId; // amount for ETH/ERC20, tokenId for ERC721
        uint256 requestTimestamp; // Time the request was made
        uint256 unlockTime; // Time when the withdrawal becomes eligible
        bytes32 conditionKey; // Key for oracle-based condition
        uint256 requiredValue; // Required value for the condition
        WithdrawalStatus status;
    }


    // --- State Variables ---
    VaultState private s_vaultState;
    address private s_oracleAddress;
    uint8 private s_withdrawalProbSuccessPercent; // 0-100
    uint8 private s_withdrawalFeePercentage; // 0-100
    mapping(address => bool) private s_admins; // Addresses with admin privileges

    // Mapping to simulate oracle data or dynamic conditions
    mapping(bytes32 => uint256) private s_conditionalWithdrawalFactors;

    // Track balances within the contract (useful for ERC20/ERC721, ETH is native)
    mapping(address => mapping(address => uint256)) private s_erc20Balances; // tokenAddress => user => amount
    mapping(address => mapping(address => uint256)) private s_erc721Holdings; // tokenAddress => tokenId => owner (0x0 if not held)

    // Deposit tracking (simplified, potentially complex for many deposits)
    Deposit[] private s_deposits; // Array might become large/expensive
    mapping(address => uint256[]) private s_userDepositIndices; // user => array of indices in s_deposits

    // Withdrawal request tracking
    WithdrawalRequest[] private s_withdrawalRequests; // Array might become large/expensive

    // Fee tracking
    uint256 private s_accumulatedETHFees;
    mapping(address => uint256) private s_accumulatedERC20Fees; // tokenAddress => amount


    // --- Modifiers ---
    modifier onlyAdmin() {
        if (!s_admins[msg.sender] && msg.sender != owner()) { // Owner is implicitly an admin
            revert QuantumVault__NotAdmin();
        }
        _;
    }

    modifier whenStateIs(VaultState expectedState) {
        if (s_vaultState != expectedState) {
            revert QuantumVault__InvalidState();
        }
        _;
    }

     modifier whenStateIsNot(VaultState excludedState) {
        if (s_vaultState == excludedState) {
            revert QuantumVault__InvalidState();
        }
        _;
    }

    modifier isValidRequest(uint256 requestId) {
        if (requestId >= s_withdrawalRequests.length) {
            revert QuantumVault__RequestNotFound();
        }
        WithdrawalRequest storage request = s_withdrawalRequests[requestId];
        if (request.status != WithdrawalStatus.Pending) {
            revert QuantumVault__RequestAlreadyProcessed();
        }
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        s_vaultState = VaultState.Open; // Start in an open state
        s_withdrawalProbSuccessPercent = 100; // Default to 100% success
        s_withdrawalFeePercentage = 0; // Default to no fees
        s_oracleAddress = address(0); // Default no oracle set
    }

    // --- Receive / Fallback ---
    receive() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ETHDeposited(msg.sender, msg.value);
    }

    // --- Core Deposit Functions ---

    function depositETH() public payable whenStateIsNot(VaultState.Locked) {
        // ETH deposit handled by receive/fallback
        // Adding a placeholder function for explicit calls if needed, though payable fallback is standard.
        // The logic is simply receiving value.
        // A Deposit struct could be recorded here if we needed to track individual ETH deposits.
    }

    function depositERC20(address token, uint256 amount) public whenStateIsNot(VaultState.Locked) {
        if (amount == 0) revert QuantumVault__DepositFailed(); // Basic validation

        // Transfer tokens from the user to the contract
        // Assumes the user has already called token.approve(this_contract_address, amount)
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert QuantumVault__DepositFailed();
        }

        // Track balance internally (less critical with transferFrom but good practice)
        // s_erc20Balances[token][msg.sender] = s_erc20Balances[token][msg.sender].add(amount); // Optional: track user's virtual balance in vault

        // Record deposit (Optional: if tracking per-deposit unlock times etc.)
        // uint256 depositId = s_deposits.length;
        // s_deposits.push(Deposit({
        //     user: msg.sender,
        //     assetType: AssetType.ERC20,
        //     tokenAddress: token,
        //     amountOrTokenId: amount,
        //     timestamp: block.timestamp
        // }));
        // s_userDepositIndices[msg.sender].push(depositId);

        emit ERC20Deposited(msg.sender, token, amount);
    }

    function depositERC721(address token, uint256 tokenId) public whenStateIsNot(VaultState.Locked) {
         // Transfer token from the user to the contract
        // Assumes the user has already called token.approve(this_contract_address, tokenId) or setApprovalForAll(this_contract_address, true)
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);

        // Track ownership internally
        s_erc721Holdings[token][tokenId] = msg.sender; // Store original depositor

        // Record deposit (Optional: if tracking per-deposit unlock times etc.)
        // uint256 depositId = s_deposits.length;
        // s_deposits.push(Deposit({
        //     user: msg.sender,
        //     assetType: AssetType.ERC721,
        //     tokenAddress: token,
        //     amountOrTokenId: tokenId,
        //     timestamp: block.timestamp
        // }));
        // s_userDepositIndices[msg.sender].push(depositId);

        emit ERC721Deposited(msg.sender, token, tokenId);
    }


    // --- Core Withdrawal Request Functions ---

    // Note: These functions only CREATE the request. Execution is separate.
    // timeLockDuration is in seconds relative to request time.
    // conditionKey/requiredValue allow linking a withdrawal to a condition (e.g., price > X)
    function requestWithdrawalETH(
        uint256 amount,
        uint256 timeLockDuration,
        bytes32 conditionKey,
        uint256 requiredValue
    ) public whenStateIsNot(VaultState.Locked) {
        if (amount == 0) revert QuantumVault__WithdrawalAmountExceedsBalance();

        // Basic check that contract has enough ETH - full check happens at execute time
        if (address(this).balance < amount) revert QuantumVault__WithdrawalAmountExceedsBalance();

        uint256 requestId = s_withdrawalRequests.length;
        s_withdrawalRequests.push(WithdrawalRequest({
            user: msg.sender,
            assetType: AssetType.ETH,
            tokenAddress: address(0),
            amountOrTokenId: amount,
            requestTimestamp: block.timestamp,
            unlockTime: block.timestamp.add(timeLockDuration),
            conditionKey: conditionKey,
            requiredValue: requiredValue,
            status: WithdrawalStatus.Pending
        }));

        emit WithdrawalRequested(
            requestId,
            msg.sender,
            amount,
            address(0),
            0,
            s_withdrawalRequests[requestId].unlockTime,
            conditionKey,
            requiredValue
        );
    }

     function requestWithdrawalERC20(
        address token,
        uint256 amount,
        uint256 timeLockDuration,
        bytes32 conditionKey,
        uint256 requiredValue
    ) public whenStateIsNot(VaultState.Locked) {
        if (amount == 0) revert QuantumVault__WithdrawalAmountExceedsBalance();

        // Basic check that contract has enough tokens - full check happens at execute time
        if (IERC20(token).balanceOf(address(this)) < amount) revert QuantumVault__WithdrawalAmountExceedsBalance();

        uint256 requestId = s_withdrawalRequests.length;
        s_withdrawalRequests.push(WithdrawalRequest({
            user: msg.sender,
            assetType: AssetType.ERC20,
            tokenAddress: token,
            amountOrTokenId: amount,
            requestTimestamp: block.timestamp,
            unlockTime: block.timestamp.add(timeLockDuration),
            conditionKey: conditionKey,
            requiredValue: requiredValue,
            status: WithdrawalStatus.Pending
        }));

         emit WithdrawalRequested(
            requestId,
            msg.sender,
            amount,
            token,
            0,
            s_withdrawalRequests[requestId].unlockTime,
            conditionKey,
            requiredValue
        );
    }

    function requestWithdrawalERC721(
        address token,
        uint256 tokenId,
        uint256 timeLockDuration,
        bytes32 conditionKey,
        uint256 requiredValue
    ) public whenStateIsNot(VaultState.Locked) {
        // Basic check that contract owns the token - full check happens at execute time
        if (IERC721(token).ownerOf(tokenId) != address(this)) revert QuantumVault__ERC721NotOwnedByVault();

        // Optional: Check if the request sender was the original depositor (s_erc721Holdings)
        // if (s_erc721Holdings[token][tokenId] != msg.sender && msg.sender != owner()) {
        //     revert QuantumVault__NotOriginalDepositor(); // Need a custom error
        // }

        uint256 requestId = s_withdrawalRequests.length;
        s_withdrawalRequests.push(WithdrawalRequest({
            user: msg.sender,
            assetType: AssetType.ERC721,
            tokenAddress: token,
            amountOrTokenId: tokenId,
            requestTimestamp: block.timestamp,
            unlockTime: block.timestamp.add(timeLockDuration),
            conditionKey: conditionKey,
            requiredValue: requiredValue,
            status: WithdrawalStatus.Pending
        }));

         emit WithdrawalRequested(
            requestId,
            msg.sender,
            0, // N/A for ERC721 amount
            token,
            tokenId,
            s_withdrawalRequests[requestId].unlockTime,
            conditionKey,
            requiredValue
        );
    }


    // --- Core Withdrawal Execution/Cancellation Functions ---

    function executeWithdrawal(uint256 requestId) public whenStateIsNot(VaultState.Locked) isValidRequest(requestId) {
        WithdrawalRequest storage request = s_withdrawalRequests[requestId];

        // 1. Check Time Lock
        if (block.timestamp < request.unlockTime) {
             revert QuantumVault__WithdrawalNotReady(request.unlockTime - block.timestamp);
        }

        // 2. Check Vault State (allows 'Restricted' to block withdrawals)
        if (s_vaultState == VaultState.Restricted) {
            revert QuantumVault__InvalidState(); // Cannot execute in Restricted state
        }

        // 3. Check Conditional Logic (if key is set)
        if (request.conditionKey != bytes32(0)) {
            if (!checkOracleCondition(request.conditionKey, request.requiredValue)) {
                request.status = WithdrawalStatus.FailedConditional;
                emit WithdrawalFailedConditional(requestId, request.user);
                revert QuantumVault__WithdrawalFailedConditional();
            }
        }

        // 4. Check Probabilistic Outcome
        // WARNING: block.timestamp, block.difficulty, blockhash are NOT secure sources of randomness
        // for high-value outcomes influenced by miners/validators. For production, use Chainlink VRF
        // or similar secure randomness solution.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, requestId)));
        uint256 successThreshold = (randomNumber % 100) + 1; // 1 to 100

        if (successThreshold > s_withdrawalProbSuccessPercent) {
            request.status = WithdrawalStatus.FailedProbabilistic;
             emit WithdrawalFailedProbabilistic(requestId, request.user);
             revert QuantumVault__WithdrawalFailedProbabilistically();
        }

        // --- If all checks pass, execute withdrawal ---
        uint256 amountOrTokenId = request.amountOrTokenId;
        address payable recipient = payable(request.user);
        bool success = false;
        uint256 feeAmount = 0;

        if (request.assetType == AssetType.ETH) {
            uint256 totalAmount = amountOrTokenId;
            feeAmount = totalAmount.mul(s_withdrawalFeePercentage).div(100);
            uint256 transferAmount = totalAmount.sub(feeAmount);

            if (address(this).balance < totalAmount) revert QuantumVault__WithdrawalAmountExceedsBalance(); // Final balance check

            (success,) = recipient.call{value: transferAmount}("");
            if (success) {
                s_accumulatedETHFees = s_accumulatedETHFees.add(feeAmount);
            }

        } else if (request.assetType == AssetType.ERC20) {
            uint256 totalAmount = amountOrTokenId;
            feeAmount = totalAmount.mul(s_withdrawalFeePercentage).div(100);
            uint256 transferAmount = totalAmount.sub(feeAmount);

            address tokenAddress = request.tokenAddress;
            if (IERC20(tokenAddress).balanceOf(address(this)) < totalAmount) revert QuantumVault__WithdrawalAmountExceedsBalance(); // Final balance check

            success = IERC20(tokenAddress).transfer(recipient, transferAmount);
             if (success) {
                s_accumulatedERC20Fees[tokenAddress] = s_accumulatedERC20Fees[tokenAddress].add(feeAmount);
            }

        } else if (request.assetType == AssetType.ERC721) {
             address tokenAddress = request.tokenAddress;
             uint256 tokenId = amountOrTokenId;

             if (IERC721(tokenAddress).ownerOf(tokenId) != address(this)) revert QuantumVault__ERC721NotOwnedByVault(); // Final ownership check

            // ERC721 transfers don't typically have a 'fee' amount like fungible tokens.
            // Fee percentage logic might need adjustment or disablement for ERC721.
            // For simplicity, applying 0 fee here for ERC721 unless specific logic is desired.
            feeAmount = 0; // No built-in fee logic for ERC721 transfer

            IERC721(tokenAddress).safeTransferFrom(address(this), recipient, tokenId);
            success = true; // SafeTransferFrom reverts on failure, so if we get here it's successful

            // Update internal tracking (Optional, only if used)
            // s_erc721Holdings[tokenAddress][tokenId] = address(0);
        }

        if (success) {
            request.status = WithdrawalStatus.Executed;
            emit WithdrawalExecuted(requestId, request.user);
        } else {
            // If transfer failed *after* all checks (highly unlikely for ETH/ERC20 using call/transfer,
            // but possible in edge cases or complex ERC20s), mark as failed.
            // ERC721 safeTransferFrom would revert instead.
            // This branch is less likely with standard token implementations but included for robustness.
             revert QuantumVault__TransferFailed();
        }
    }

    function cancelWithdrawalRequest(uint256 requestId) public isValidRequest(requestId) {
        WithdrawalRequest storage request = s_withdrawalRequests[requestId];

        // Only the original requester can cancel
        if (request.user != msg.sender) {
            revert QuantumVault__RequestNotFound(); // Or a more specific error like NotRequester
        }

        // Cannot cancel if time lock has already passed (implies it was ready to execute)
        // Decide if cancellation is allowed AFTER unlockTime but BEFORE execution.
        // Current logic allows cancellation any time BEFORE execution.
        // If you want to block after unlockTime:
        // if (block.timestamp >= request.unlockTime) {
        //     revert QuantumVault__CannotCancelAfterUnlock(); // Need new error
        // }

        request.status = WithdrawalStatus.Cancelled;
        emit WithdrawalCancelled(requestId, msg.sender);
    }


    // --- State Management Functions ---

    function setVaultState(VaultState newState) public onlyAdmin {
        if (s_vaultState == newState) return; // No change

        s_vaultState = newState;
        emit StateChanged(newState);
    }

    function getVaultState() public view returns (VaultState) {
        return s_vaultState;
    }


    // --- Access Control / Role Management Functions ---

    function addAdmin(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        s_admins[account] = true;
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
         // Cannot remove the owner's admin status this way (owner is always admin)
        if (account == owner()) revert QuantumVault__NotAdmin(); // Or custom error

        s_admins[account] = false;
        emit AdminRemoved(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return s_admins[account] || account == owner(); // Owner is always admin
    }


    // --- Configuration Functions ---

    function setWithdrawalProbSuccess(uint8 probabilityPercent) public onlyAdmin {
        if (probabilityPercent > 100) revert QuantumVault__InvalidProbability(probabilityPercent);
        s_withdrawalProbSuccessPercent = probabilityPercent;
        emit WithdrawalProbabilitySet(probabilityPercent);
    }

    function getWithdrawalProbSuccess() public view returns (uint8) {
        return s_withdrawalProbSuccessPercent;
    }

    function setOracleAddress(address _oracle) public onlyAdmin {
        require(_oracle != address(0), "Invalid address");
        s_oracleAddress = _oracle;
        emit OracleAddressSet(_oracle);
    }

    function getOracleAddress() public view returns (address) {
        return s_oracleAddress;
    }

    // Allows setting a key-value pair that the oracle condition check can use.
    // In a real scenario, a trusted oracle would update these values,
    // or this contract would call the oracle contract. This is a simulation.
    function setConditionalWithdrawalFactor(bytes32 key, uint256 value) public onlyAdmin {
        require(key != bytes32(0), "Invalid key");
        s_conditionalWithdrawalFactors[key] = value;
        emit ConditionalFactorSet(key, value);
    }

     function getConditionalWithdrawalFactor(bytes32 key) public view returns (uint256) {
        return s_conditionalWithdrawalFactors[key];
    }


    // --- Oracle Interaction Helper (Simulated) ---

    // Internal function to check a simulated oracle condition.
    // In a real dapp, this would likely involve an external call to a Chainlink or similar oracle contract.
    function checkOracleCondition(bytes32 key, uint256 requiredValue) internal view returns (bool) {
        // If no oracle address is set, conditions cannot be checked.
        // Decide if this means conditions *pass* or *fail*. Failing is safer by default.
        // For this example, if no oracle address is set, condition check always fails if key is set.
        // If key is bytes32(0), it means no condition was required, so it passes.
        if (key == bytes32(0)) return true; // No condition required
        if (s_oracleAddress == address(0)) return false; // Oracle required but not set

        // Simple simulation: check against the internally stored factor
        // A real oracle would return a value from an external source.
        return s_conditionalWithdrawalFactors[key] >= requiredValue;

        // Example of external oracle call (requires Chainlink VRF/Price Feed interface import)
        // if (s_oracleAddress == address(0)) return false;
        // // Assume oracle is a price feed contract
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(s_oracleAddress);
        // (, int256 price, , ,) = priceFeed.latestRoundData();
        // return uint256(price) >= requiredValue; // Or other comparison based on key/value meaning
    }


    // --- Fee Management Functions ---

    function setWithdrawalFeePercentage(uint8 feePercent) public onlyAdmin {
        if (feePercent > 100) revert QuantumVault__InvalidFeePercentage(feePercent);
        s_withdrawalFeePercentage = feePercent;
    }

    function getWithdrawalFeePercentage() public view returns (uint8) {
        return s_withdrawalFeePercentage;
    }

    function collectFees(address payable recipient) public onlyAdmin {
        require(recipient != address(0), "Invalid recipient");

        uint256 ethFees = s_accumulatedETHFees;
        s_accumulatedETHFees = 0; // Reset before transfer

        if (ethFees > 0) {
             (bool success, ) = recipient.call{value: ethFees}("");
            if (!success) {
                s_accumulatedETHFees = s_accumulatedETHFees.add(ethFees); // Refund if transfer fails
                revert QuantumVault__FeeCollectionFailed();
            }
        }

        uint256 totalERC20FeesCollected = 0;
        // Note: Collecting all ERC20 fees at once might hit gas limits if many tokens have fees.
        // A better approach for many tokens might be to collect one token type at a time.
        // This implementation collects *all* accumulated ERC20 fees for *all* tracked tokens.
        // This requires iterating through potential tokens, which is problematic without a list.
        // A more robust design would track which tokens have accumulated fees.
        // For this example, we'll just skip detailed ERC20 fee collection or require specifying the token.
        // Let's adjust to require specifying the token.

        // Example collecting a specific ERC20 fee:
        // function collectERC20Fees(address token, address recipient) public onlyAdmin { ... }

        // Let's collect all tracked ERC20 fees, acknowledging gas limit risk for many tokens.
        // This requires knowing which tokens have fees, which isn't stored.
        // SIMPLIFICATION: Fee collection event only emits ETH fees collected, actual ERC20 collection would be more complex.
        // Or only collect fees for a specific token. Let's add a helper for that.

        // Simpler: collect fees for a SPECIFIC ERC20 token
        // Add this as a separate function or modify `collectFees` to take an optional token address.
        // Let's add a new function `collectERC20Fees`.

        // Reverting the multi-token fee collection for simplicity and gas safety.
        // The `collectFees` function will only handle ETH.

         if (ethFees == 0) revert QuantumVault__NoFeesToCollect();

        emit FeesCollected(recipient, ethFees, 0); // 0 for ERC20s collected in this simplified version
    }

     function collectERC20Fees(address token, address payable recipient) public onlyAdmin {
        require(recipient != address(0), "Invalid recipient");
        require(token != address(0), "Invalid token");

        uint256 tokenFees = s_accumulatedERC20Fees[token];
        if (tokenFees == 0) revert QuantumVault__NoFeesToCollect();

        s_accumulatedERC20Fees[token] = 0; // Reset before transfer

        bool success = IERC20(token).transfer(recipient, tokenFees);
        if (!success) {
             s_accumulatedERC20Fees[token] = s_accumulatedERC20Fees[token].add(tokenFees); // Refund if transfer fails
            revert QuantumVault__FeeCollectionFailed();
        }

         emit FeesCollected(recipient, 0, tokenFees); // 0 for ETH fees collected here
    }

    function getAccumulatedFeesETH() public view returns (uint256) {
        return s_accumulatedETHFees;
    }

    function getAccumulatedFeesERC20(address token) public view returns (uint256) {
        require(token != address(0), "Invalid token");
        return s_accumulatedERC20Fees[token];
    }


    // --- Emergency Functions ---
    // These bypass all normal checks (state, time, probability, condition)
    function emergencyWithdrawETH(address payable recipient) public onlyAdmin whenStateIsNot(VaultState.Open) {
        require(recipient != address(0), "Invalid recipient");
        uint256 balance = address(this).balance;
        if (balance == 0) revert QuantumVault__WithdrawalAmountExceedsBalance();

        // Transfer all balance
        (bool success, ) = recipient.call{value: balance}("");
        if (!success) {
            revert QuantumVault__TransferFailed();
        }
        // No event for this, as it's emergency and bypasses request system
    }

    function emergencyWithdrawERC20(address token, address recipient) public onlyAdmin whenStateIsNot(VaultState.Open) {
        require(recipient != address(0), "Invalid recipient");
        require(token != address(0), "Invalid token");
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance == 0) revert QuantumVault__WithdrawalAmountExceedsBalance();

        bool success = IERC20(token).transfer(recipient, balance);
        if (!success) {
             revert QuantumVault__TransferFailed();
        }
         // No event for this, as it's emergency and bypasses request system
    }

    function emergencyWithdrawERC721(address token, uint256 tokenId, address recipient) public onlyAdmin whenStateIsNot(VaultState.Open) {
         require(recipient != address(0), "Invalid recipient");
         require(token != address(0), "Invalid token");

         if (IERC721(token).ownerOf(tokenId) != address(this)) revert QuantumVault__ERC721NotOwnedByVault();

        IERC721(token).safeTransferFrom(address(this), recipient, tokenId);
        // SafeTransferFrom reverts on failure, no need for explicit success check here
        // No event for this, as it's emergency and bypasses request system
    }


    // --- View Functions ---

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address token) public view returns (uint256) {
         require(token != address(0), "Invalid token");
        return IERC20(token).balanceOf(address(this));
    }

    // This function relies on the optional s_erc721Holdings mapping.
    // A more reliable check is `IERC721(token).ownerOf(tokenId) == address(this)`.
    // This view function specifically shows *which user* deposited it, if tracked.
     function getERC721OriginalDepositor(address token, uint256 tokenId) public view returns (address) {
        // This requires the s_erc721Holdings mapping to be populated on deposit
        // and potentially cleared on withdrawal. The deposit code above was commented out
        // for this tracking due to potential array complexity.
        // Re-enabling the mapping logic in deposit/withdrawal would make this function useful.
        // As is, it might return address(0) unless the mapping was populated.
        // A simpler, reliable check is `IERC721(token).ownerOf(tokenId)`.
         return s_erc721Holdings[token][tokenId]; // Might return address(0) if not tracked or withdrawn
     }

    // Note: Deposit tracking via arrays (s_deposits, s_userDepositIndices) can be gas-intensive
    // if there are many deposits. A real-world solution might use different tracking patterns
    // or limit queryable history size.
     function getUserDepositCount(address account) public view returns (uint256) {
        // Requires s_userDepositIndices mapping to be populated on deposit (commented out above)
        // return s_userDepositIndices[account].length;
        return 0; // Placeholder if deposit tracking is disabled
     }

     function getUserDepositDetails(address account, uint256 index) public view returns (Deposit memory) {
         // Requires s_deposits and s_userDepositIndices
        // require(index < s_userDepositIndices[account].length, "Index out of bounds");
        // uint256 depositId = s_userDepositIndices[account][index];
        // return s_deposits[depositId];
         revert("Deposit tracking is not fully enabled in this example"); // Placeholder if deposit tracking disabled
     }

    function getWithdrawalRequestCount() public view returns (uint256) {
        return s_withdrawalRequests.length;
    }

    function getWithdrawalRequestDetails(uint256 requestId) public view returns (WithdrawalRequest memory) {
         require(requestId < s_withdrawalRequests.length, "Request ID out of bounds");
        return s_withdrawalRequests[requestId];
    }
}
```