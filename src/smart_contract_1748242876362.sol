Okay, here is a Solidity smart contract implementing a "Quantum Treasury" concept.

The idea behind "Quantum" here is analogous to a system that can exist in multiple potential states or dimensions (managing different asset types, interacting with various external protocols/strategies, executing actions conditionally based on external data), and where actions can trigger transitions between these complex states. It's a creative theme rather than a literal quantum computing implementation on-chain.

This contract goes beyond a simple multi-sig or standard token treasury by incorporating:
1.  **Multi-Asset Management:** Handling ETH, ERC-20, ERC-721, and ERC-1155 tokens.
2.  **Strategy Deployment:** Ability to deposit/withdraw assets into approved external DeFi/yield protocols (simulated via an interface).
3.  **Role-Based Access Control:** Differentiating permissions for owner, administrators, and strategists.
4.  **Conditional Execution:** Executing actions (like transfers or strategy deployments) only if an oracle price feed meets a specified threshold.
5.  **Batch Operations:** Performing multiple transfers or strategy interactions in a single transaction for efficiency.
6.  **Yield Management:** A placeholder function for claiming yield from strategies.
7.  **Security Features:** Reentrancy guard, pausable strategy interactions.

It aims for complexity and features not typically found together in a single basic open-source treasury example.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/interfaces/draft-IERC6093.sol"; // For receive() with data, safety fallback
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol"; // Required by ERC1155Holder

// --- Outline & Function Summary ---
// Contract: QuantumTreasury
// Purpose: A multi-asset treasury capable of interacting with external protocols (strategies)
//          based on role-based access control, conditional logic via oracles, and batch operations.
// Inheritance: Ownable (basic ownership), ReentrancyGuard, ERC1155Holder (to receive ERC1155).
// Roles:
// - Owner: Can grant/revoke Admin and Strategist roles, transfer ownership.
// - Admin: Can withdraw any asset, approve/de-approve strategies, set oracle, set thresholds, pause/unpause strategies.
// - Strategist: Can deploy/withdraw assets to/from approved strategies, perform conditional and batch operations, claim yield.
// - Anyone: Can deposit assets, view treasury balances/status.
//
// State Variables:
// - _admins: Mapping of addresses to admin status.
// - _strategists: Mapping of addresses to strategist status.
// - _isApprovedStrategy: Mapping of strategy contract addresses to approval status.
// - _strategyDeployedBalances: Mapping (strategy address => token address => deployed amount). Tracks assets sent *to* strategies.
// - _oracleAddress: Address of the price feed oracle contract (e.g., Chainlink AggregatorV3).
// - _priceThreshold: Price threshold used for conditional execution.
// - _isStrategyPaused: Mapping of strategy addresses to paused status (prevents interactions).
//
// Events:
// - DepositETH, DepositERC20, DepositERC721, DepositERC1155: Record asset deposits.
// - WithdrawETH, WithdrawERC20, WithdrawERC721, WithdrawERC1155: Record asset withdrawals.
// - RoleGranted, RoleRevoked: Record changes in admin/strategist roles.
// - StrategyApproved, StrategyDeapproved: Record strategy approval changes.
// - StrategyDeployed, StrategyWithdrawn: Record asset movements to/from strategies.
// - ConditionalExecutionTriggered: Record when a conditional action is successfully executed.
// - BatchExecutionTriggered: Record when a batch action is performed.
// - YieldClaimed: Record yield received from a strategy.
// - OracleAddressUpdated, PriceThresholdUpdated: Record oracle settings changes.
// - StrategyPaused, StrategyUnpaused: Record strategy pause status changes.
//
// Modifiers:
// - onlyAdmin: Restricts access to addresses with admin role.
// - onlyStrategist: Restricts access to addresses with strategist role.
// - onlyAdminOrStrategist: Restricts access to addresses with either admin or strategist role.
// - whenStrategyActive: Checks if a specific strategy is not paused.
// - whenNotPausedGlobally: Checks if a global pause is not active (could add a global pause state variable). (Decided against a global pause for more granularity via per-strategy pause).
//
// External Interfaces (Required for Strategy/Oracle interaction):
// - IAggregatorV3: Interface for a price feed oracle (e.g., Chainlink).
// - IStrategy: Simple interface for approved external strategy contracts.
//
// Functions Summary (Min 20 functions):
// 1. constructor(address initialOracle): Initializes the contract with an oracle address and owner.
// 2. receive(): Allows receiving bare ETH.
// 3. depositETH(): Explicit function to deposit ETH.
// 4. depositERC20(address token, uint256 amount): Receives ERC20 tokens (requires prior approval/transferFrom or direct transfer).
// 5. depositERC721(address token, uint256 tokenId): Receives an ERC721 token (requires prior approval/transferFrom).
// 6. depositERC1155(address token, uint256 id, uint256 amount): Receives ERC1155 tokens (handled by ERC1155Holder).
// 7. withdrawETH(address payable recipient, uint256 amount): Admin withdraws ETH from treasury.
// 8. withdrawERC20(address token, address recipient, uint256 amount): Admin withdraws ERC20 from treasury.
// 9. withdrawERC721(address token, address recipient, uint256 tokenId): Admin withdraws ERC721 from treasury.
// 10. withdrawERC1155(address token, address recipient, uint256 id, uint256 amount): Admin withdraws ERC1155 from treasury.
// 11. grantRole(address account, string calldata role): Owner grants 'admin' or 'strategist' role.
// 12. revokeRole(address account, string calldata role): Owner revokes 'admin' or 'strategist' role.
// 13. isAdmin(address account): View function to check if an address is an admin.
// 14. isStrategist(address account): View function to check if an address is a strategist.
// 15. approveStrategyProtocol(address strategy): Admin approves an external protocol for strategy deployment.
// 16. deapproveStrategyProtocol(address strategy): Admin de-approves a protocol.
// 17. isStrategyApproved(address strategy): View function to check if a strategy is approved.
// 18. pauseStrategyInteractions(address strategy): Admin pauses interactions with a specific strategy.
// 19. unpauseStrategyInteractions(address strategy): Admin unpauses interactions with a specific strategy.
// 20. isStrategyPaused(address strategy): View function to check if a strategy is paused.
// 21. deployERC20ToStrategy(address token, address strategy, uint256 amount): Strategist deploys ERC20 to an approved, unpaused strategy.
// 22. withdrawERC20FromStrategy(address token, address strategy, uint256 amount): Strategist withdraws ERC20 from an approved, unpaused strategy.
// 23. getStrategyDeployedBalance(address strategy, address token): View function to get deployed amount of a token in a strategy.
// 24. setOracleAddress(address newOracle): Admin sets the oracle address.
// 25. getOracleAddress(): View function to get the oracle address.
// 26. setPriceThreshold(int256 threshold): Admin sets the oracle price threshold.
// 27. getPriceThreshold(): View function to get the price threshold.
// 28. checkOraclePrice(): Internal helper to get oracle price (simulated).
// 29. conditionalERC20Transfer(address token, address recipient, uint256 amount, int256 requiredPrice, bool greaterThan): Strategist executes transfer if oracle price meets condition.
// 30. conditionalStrategyDeployment(address token, address strategy, uint256 amount, int256 requiredPrice, bool greaterThan): Strategist deploys if oracle price meets condition.
// 31. batchERC20Transfer(address[] calldata tokens, address[] calldata recipients, uint256[] calldata amounts): Strategist performs multiple ERC20 transfers.
// 32. batchStrategyDeployment(address[] calldata tokens, address[] calldata strategies, uint256[] calldata amounts): Strategist performs multiple strategy deployments.
// 33. batchStrategyWithdrawal(address[] calldata tokens, address[] calldata strategies, uint256[] calldata amounts): Strategist performs multiple strategy withdrawals.
// 34. claimYieldFromStrategy(address strategy, address yieldToken): Strategist claims yield token from a strategy (requires strategy support).
// 35. getVersion(): View function returning contract version.
// 36. onERC1155Received: ERC1155Holder required function.
// 37. onERC1155BatchReceived: ERC1155Holder required function.
//
// Note: Oracle and Strategy interactions are simulated via interfaces. Real implementations would require specific protocol integrations.
// The ERC721/ERC1155 strategy deployment is not included as it's less common for generic yield/lending; focus is on fungible tokens.

// --- Imports ---

// OpenZeppelin Contracts
// https://docs.openzeppelin.com/contracts/5.x/api/access
// https://docs.openzeppelin.com/contracts/5.x/api/security
// https://docs.openzeppelin.com/contracts/5.x/api/token/erc20
// https://docs.openzeppelin.com/contracts/5.x/api/token/erc721
// https://docs.openzeppelin.com/contracts/5.x/api/token/erc1155
// https://docs.openzeppelin.com/contracts/5.x/api/token/erc1155#ERC1155Holder
// https://docs.openzeppelin.com/contracts/5.x/api/interfaces#IERC6093 (For receive with data)
// https://docs.openzeppelin.com/contracts/5.x/api/token/erc1155#IERC1155Receiver (Required by ERC1155Holder)

// --- External Interfaces ---

// Example Oracle Interface (Chainlink AggregatorV3)
interface IAggregatorV3 {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer, // Price
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// Simple Strategy Interface (Illustrative)
// Real strategies will have diverse function signatures.
// This assumes a strategy accepts deposit/withdraw calls with token/amount.
interface IStrategy {
    function deposit(address token, uint256 amount) external payable;
    function withdraw(address token, uint256 amount) external;
    // Assume a method to claim yield, e.g., 'claimYield(address yieldToken)'
    // function claimYield(address yieldToken) external;
}

// --- Contract Definition ---

contract QuantumTreasury is Ownable, ReentrancyGuard, ERC1155Holder {

    // --- State Variables ---

    mapping(address => bool) private _admins;
    mapping(address => bool) private _strategists;

    mapping(address => bool) private _isApprovedStrategy;
    mapping(address => mapping(address => uint256)) private _strategyDeployedBalances; // strategy address => token address => deployed amount

    address private _oracleAddress;
    int256 private _priceThreshold; // Used for conditional execution

    mapping(address => bool) private _isStrategyPaused; // Allows pausing interaction with specific strategies

    // --- Events ---

    event DepositETH(address indexed sender, uint256 amount);
    event DepositERC20(address indexed token, address indexed sender, uint256 amount);
    event DepositERC721(address indexed token, address indexed sender, uint256 tokenId);
    event DepositERC1155(address indexed token, address indexed sender, uint256 id, uint256 amount);

    event WithdrawETH(address indexed recipient, uint256 amount);
    event WithdrawERC20(address indexed token, address indexed recipient, uint256 amount);
    event WithdrawERC721(address indexed token, address indexed recipient, uint256 tokenId);
    event WithdrawERC1155(address indexed token, address indexed recipient, uint256 id, uint256 amount);

    event RoleGranted(address indexed account, string role);
    event RoleRevoked(address indexed account, string role);

    event StrategyApproved(address indexed strategy);
    event StrategyDeapproved(address indexed strategy);

    event StrategyDeployed(address indexed strategy, address indexed token, uint256 amount);
    event StrategyWithdrawn(address indexed strategy, address indexed token, uint256 amount);
    event YieldClaimed(address indexed strategy, address indexed yieldToken, uint256 amountReceived);

    event ConditionalExecutionTriggered(address indexed executor, string action, int256 currentPrice, int256 threshold, bool greaterThanConditionMet);
    event BatchExecutionTriggered(address indexed executor, string actionType, uint256 itemCount);

    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event PriceThresholdUpdated(int256 oldThreshold, int256 newThreshold);

    event StrategyPaused(address indexed strategy);
    event StrategyUnpaused(address indexed strategy);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(_admins[msg.sender], "Q: Not admin");
        _;
    }

    modifier onlyStrategist() {
        require(_strategists[msg.sender], "Q: Not strategist");
        _;
    }

    modifier onlyAdminOrStrategist() {
        require(_admins[msg.sender] || _strategists[msg.sender], "Q: Not admin or strategist");
        _;
    }

    modifier whenStrategyActive(address strategy) {
        require(!_isStrategyPaused[strategy], "Q: Strategy interactions paused");
        _;
    }

    // --- Constructor ---

    constructor(address initialOracle) Ownable(msg.sender) {
        _oracleAddress = initialOracle;
        // Set initial threshold to a value that won't likely trigger conditionals immediately
        _priceThreshold = type(int256).max;
        emit OracleAddressUpdated(address(0), initialOracle);
        emit PriceThresholdUpdated(0, _priceThreshold);
    }

    // --- Receive ETH Functions ---

    receive() external payable {
        emit DepositETH(msg.sender, msg.value);
    }

    // Explicit function to deposit ETH for clarity, though receive() handles it.
    function depositETH() external payable nonReentrant {
        require(msg.value > 0, "Q: ETH amount must be > 0");
        // receive() event already covers this
        // emit DepositETH(msg.sender, msg.value);
    }

    // Fallback function for receiving data with ETH
    fallback(bytes calldata) external payable nonReentrant {
         require(msg.value > 0, "Q: ETH amount must be > 0");
        // receive() event already covers this
        // emit DepositETH(msg.sender, msg.value);
    }

    // --- Deposit Functions ---

    // For ERC20 tokens, requires allowance OR approve() followed by transferFrom() by the caller.
    // Or the caller can simply transfer() directly to the treasury address before calling this function.
    function depositERC20(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Q: Amount must be > 0");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit DepositERC20(token, msg.sender, amount);
    }

    // For ERC721 tokens, requires allowance OR approve() followed by transferFrom() by the caller.
    // The caller must approve the treasury contract first.
    function depositERC721(address token, uint256 tokenId) external nonReentrant {
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        emit DepositERC721(token, msg.sender, tokenId);
    }

    // ERC1155 tokens are received via the ERC1155Holder implementation's onERC1155Received/onERC1155BatchReceived.
    // Callers should use safeTransferFrom or safeBatchTransferFrom targeting this contract.
    function depositERC1155(address token, uint256 id, uint256 amount) external {
         // This function is just for the event log. The tokens are received via the holder functions.
         // A sender might call this *after* performing the safeTransferFrom to signal intent.
         // A more robust approach would involve custom ERC1155Receiver logic.
         // For simplicity, we assume the tokens were received via the standard hooks
         // and this function call signals the *intent* or is a placeholder.
         // In a real application, verify balance after the holder hook.
         // For this example, we trust the caller executed the transfer correctly.
         require(amount > 0, "Q: Amount must be > 0");
         // Check if the treasury actually received the tokens via onERC1155Received/BatchReceived
         // This check is complex as depositERC1155 might be called separately.
         // Let's assume for this example that safeTransferFrom was done correctly by the caller.
         emit DepositERC1155(token, msg.sender, id, amount);
    }

    // --- Withdrawal Functions (Admin Only) ---

    function withdrawETH(address payable recipient, uint256 amount) external onlyAdmin nonReentrant {
        require(amount > 0, "Q: Amount must be > 0");
        require(address(this).balance >= amount, "Q: Insufficient ETH balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Q: ETH transfer failed");
        emit WithdrawETH(recipient, amount);
    }

    function withdrawERC20(address token, address recipient, uint256 amount) external onlyAdmin nonReentrant {
        require(amount > 0, "Q: Amount must be > 0");
        IERC20(token).transfer(recipient, amount);
        emit WithdrawERC20(token, recipient, amount);
    }

    function withdrawERC721(address token, address recipient, uint256 tokenId) external onlyAdmin nonReentrant {
        // ERC721 standard transferFrom handles ownership check within the token contract
        IERC721(token).transferFrom(address(this), recipient, tokenId);
        emit WithdrawERC721(token, recipient, tokenId);
    }

    function withdrawERC1155(address token, address recipient, uint256 id, uint256 amount) external onlyAdmin nonReentrant {
        require(amount > 0, "Q: Amount must be > 0");
        // ERC1155 standard safeTransferFrom handles balance check within the token contract
        IERC1155(token).safeTransferFrom(address(this), recipient, id, amount, "");
        emit WithdrawERC1155(token, recipient, id, amount);
    }

    // --- Role Management (Owner Only) ---

    function grantRole(address account, string calldata role) external onlyOwner {
        if (compareStrings(role, "admin")) {
            require(!_admins[account], "Q: Account already admin");
            _admins[account] = true;
            emit RoleGranted(account, "admin");
        } else if (compareStrings(role, "strategist")) {
            require(!_strategists[account], "Q: Account already strategist");
            _strategists[account] = true;
            emit RoleGranted(account, "strategist");
        } else {
            revert("Q: Invalid role");
        }
    }

    function revokeRole(address account, string calldata role) external onlyOwner {
         if (compareStrings(role, "admin")) {
            require(_admins[account], "Q: Account not admin");
            _admins[account] = false;
            emit RoleRevoked(account, "admin");
        } else if (compareStrings(role, "strategist")) {
            require(_strategists[account], "Q: Account not strategist");
            _strategists[account] = false;
            emit RoleRevoked(account, "strategist");
        } else {
            revert("Q: Invalid role");
        }
    }

    // Helper for string comparison (Solidity doesn't have native string equality)
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // --- Role Check Views ---

    function isAdmin(address account) external view returns (bool) {
        return _admins[account];
    }

    function isStrategist(address account) external view returns (bool) {
        return _strategists[account];
    }

    function getRoleStatus(address account) external view returns (bool admin, bool strategist) {
         return (_admins[account], _strategists[account]);
    }

    // --- Strategy Approval (Admin Only) ---

    function approveStrategyProtocol(address strategy) external onlyAdmin {
        require(strategy != address(0), "Q: Invalid strategy address");
        require(!_isApprovedStrategy[strategy], "Q: Strategy already approved");
        _isApprovedStrategy[strategy] = true;
        emit StrategyApproved(strategy);
    }

    function deapproveStrategyProtocol(address strategy) external onlyAdmin {
         require(strategy != address(0), "Q: Invalid strategy address");
         require(_isApprovedStrategy[strategy], "Q: Strategy not approved");
         _isApprovedStrategy[strategy] = false;
         emit StrategyDeapproved(strategy);
    }

    function isStrategyApproved(address strategy) external view returns (bool) {
         return _isApprovedStrategy[strategy];
    }

    // --- Strategy Pause (Admin Only) ---

     function pauseStrategyInteractions(address strategy) external onlyAdmin {
        require(strategy != address(0), "Q: Invalid strategy address");
        require(!_isStrategyPaused[strategy], "Q: Strategy already paused");
        _isStrategyPaused[strategy] = true;
        emit StrategyPaused(strategy);
     }

     function unpauseStrategyInteractions(address strategy) external onlyAdmin {
         require(strategy != address(0), "Q: Invalid strategy address");
         require(_isStrategyPaused[strategy], "Q: Strategy not paused");
         _isStrategyPaused[strategy] = false;
         emit StrategyUnpaused(strategy);
     }

     function isStrategyPaused(address strategy) external view returns (bool) {
         return _isStrategyPaused[strategy];
     }

    // --- Strategy Execution (Strategist Only) ---

    // Note: This function assumes the strategy contract implements IStrategy or a compatible deposit function.
    // Real-world integrations require specific calls per protocol.
    function deployERC20ToStrategy(address token, address strategy, uint256 amount)
        external
        onlyStrategist
        whenStrategyActive(strategy)
        nonReentrant
    {
        require(amount > 0, "Q: Amount must be > 0");
        require(_isApprovedStrategy[strategy], "Q: Strategy not approved");
        // Transfer token from treasury to strategy contract
        IERC20(token).transfer(strategy, amount);
        // Call the strategy's deposit function (simulated interface call)
        // This requires the strategy contract to accept the transfer *before* deposit,
        // or for the deposit function to handle the transfer itself (less common).
        // Assuming transfer() followed by deposit() call.
        IStrategy(strategy).deposit(token, amount);

        _strategyDeployedBalances[strategy][token] += amount;
        emit StrategyDeployed(strategy, token, amount);
    }

    // Note: This function assumes the strategy contract implements IStrategy or a compatible withdraw function.
    function withdrawERC20FromStrategy(address token, address strategy, uint256 amount)
        external
        onlyStrategist
        whenStrategyActive(strategy)
        nonReentrant
    {
        require(amount > 0, "Q: Amount must be > 0");
        require(_isApprovedStrategy[strategy], "Q: Strategy not approved");
        require(_strategyDeployedBalances[strategy][token] >= amount, "Q: Not enough deployed balance tracked");

        // Call the strategy's withdraw function (simulated interface call)
        // This function MUST transfer the tokens back to the treasury (address(this)).
        IStrategy(strategy).withdraw(token, amount);

        _strategyDeployedBalances[strategy][token] -= amount;
        emit StrategyWithdrawn(strategy, token, amount);
    }

    // Placeholder function to claim yield tokens from a strategy.
    // The actual mechanism depends heavily on the specific strategy protocol.
    // This assumes the strategy contract has a function to send yield tokens
    // directly to the caller (the treasury) or to a specified address.
    function claimYieldFromStrategy(address strategy, address yieldToken)
        external
        onlyStrategist
        whenStrategyActive(strategy)
        nonReentrant
    {
        require(_isApprovedStrategy[strategy], "Q: Strategy not approved");
        require(yieldToken != address(0), "Q: Invalid yield token address");

        uint256 balanceBefore = IERC20(yieldToken).balanceOf(address(this));

        // Simulate calling a claim function on the strategy.
        // This call must result in the strategy transferring yieldToken to address(this).
        // IStrategy(strategy).claimYield(yieldToken); // Assuming such a function exists

        // IMPORTANT: The actual strategy contract needs a function the treasury can call
        // that results in yield tokens being sent to the treasury.
        // The line below is a placeholder. A real contract needs specific integration.
        // For demonstration, we'll just log the event assuming tokens were received.
        // In a real scenario, verify balance increase or use a different pattern.
        // Let's simulate receiving some tokens for the event log.
        uint256 simulatedClaimedAmount = 1; // Replace with actual logic to check balance increase

        uint256 balanceAfter = IERC20(yieldToken).balanceOf(address(this));
        simulatedClaimedAmount = balanceAfter - balanceBefore;
        require(simulatedClaimedAmount > 0, "Q: No yield tokens received");


        emit YieldClaimed(strategy, yieldToken, simulatedClaimedAmount);
    }


    // --- Oracle & Conditional Execution (Strategist Only) ---

    function setOracleAddress(address newOracle) external onlyAdmin {
        require(newOracle != address(0), "Q: Invalid oracle address");
        address oldOracle = _oracleAddress;
        _oracleAddress = newOracle;
        emit OracleAddressUpdated(oldOracle, newOracle);
    }

    function getOracleAddress() external view returns (address) {
        return _oracleAddress;
    }

    function setPriceThreshold(int256 threshold) external onlyAdmin {
        int256 oldThreshold = _priceThreshold;
        _priceThreshold = threshold;
        emit PriceThresholdUpdated(oldThreshold, newThreshold);
    }

    function getPriceThreshold() external view returns (int256) {
        return _priceThreshold;
    }

    // Internal function to get the current price from the oracle
    function checkOraclePrice() internal view returns (int256) {
        require(_oracleAddress != address(0), "Q: Oracle address not set");
        (, int256 price, , ,) = IAggregatorV3(_oracleAddress).latestRoundData();
        // Consider checking updatedAt and answeredInRound for staleness in production
        return price;
    }

    // Executes an ERC20 transfer only if the oracle price meets the condition
    function conditionalERC20Transfer(
        address token,
        address recipient,
        uint256 amount,
        int256 requiredPrice, // Price threshold for this specific call
        bool greaterThan // True for >, False for <
    ) external onlyStrategist nonReentrant {
        require(amount > 0, "Q: Amount must be > 0");
        int256 currentPrice = checkOraclePrice();
        bool conditionMet = greaterThan ? (currentPrice > requiredPrice) : (currentPrice < requiredPrice);

        require(conditionMet, "Q: Oracle price condition not met");

        IERC20(token).transfer(recipient, amount);
        emit ConditionalExecutionTriggered(msg.sender, "ERC20Transfer", currentPrice, requiredPrice, greaterThanConditionMet);
        emit WithdrawERC20(token, recipient, amount); // Log as a withdrawal from treasury
    }

    // Executes a strategy deployment only if the oracle price meets the condition
    function conditionalStrategyDeployment(
        address token,
        address strategy,
        uint256 amount,
        int256 requiredPrice, // Price threshold for this specific call
        bool greaterThan // True for >, False for <
    ) external onlyStrategist whenStrategyActive(strategy) nonReentrant {
        require(amount > 0, "Q: Amount must be > 0");
        require(_isApprovedStrategy[strategy], "Q: Strategy not approved");

        int256 currentPrice = checkOraclePrice();
        bool conditionMet = greaterThan ? (currentPrice > requiredPrice) : (currentPrice < requiredPrice);

        require(conditionMet, "Q: Oracle price condition not met");

        // Execute the deployment logic (same as deployERC20ToStrategy)
        IERC20(token).transfer(strategy, amount);
        IStrategy(strategy).deposit(token, amount);
        _strategyDeployedBalances[strategy][token] += amount;

        emit ConditionalExecutionTriggered(msg.sender, "StrategyDeployment", currentPrice, requiredPrice, greaterThanConditionMet);
        emit StrategyDeployed(strategy, token, amount);
    }


    // --- Batch Operations (Strategist Only) ---

    // Performs multiple ERC20 transfers in a single transaction
    function batchERC20Transfer(
        address[] calldata tokens,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyStrategist nonReentrant {
        require(tokens.length == recipients.length && tokens.length == amounts.length, "Q: Array length mismatch");
        require(tokens.length > 0, "Q: Arrays cannot be empty");

        for (uint i = 0; i < tokens.length; i++) {
            require(amounts[i] > 0, "Q: Amount must be > 0");
            IERC20(tokens[i]).transfer(recipients[i], amounts[i]);
             emit WithdrawERC20(tokens[i], recipients[i], amounts[i]); // Log each transfer
        }
        emit BatchExecutionTriggered(msg.sender, "ERC20Transfer", tokens.length);
    }

    // Performs multiple strategy deployments in a single transaction
    function batchStrategyDeployment(
        address[] calldata tokens,
        address[] calldata strategies,
        uint256[] calldata amounts
    ) external onlyStrategist nonReentrant {
        require(tokens.length == strategies.length && tokens.length == amounts.length, "Q: Array length mismatch");
        require(tokens.length > 0, "Q: Arrays cannot be empty");

        for (uint i = 0; i < tokens.length; i++) {
             require(amounts[i] > 0, "Q: Amount must be > 0");
             require(_isApprovedStrategy[strategies[i]], "Q: Strategy not approved in batch");
             require(!_isStrategyPaused[strategies[i]], "Q: Strategy paused in batch");

            // Execute the deployment logic (same as deployERC20ToStrategy internal part)
            IERC20(tokens[i]).transfer(strategies[i], amounts[i]);
            IStrategy(strategies[i]).deposit(tokens[i], amounts[i]);
            _strategyDeployedBalances[strategies[i]][tokens[i]] += amounts[i];

            emit StrategyDeployed(strategies[i], tokens[i], amounts[i]); // Log each deployment
        }
        emit BatchExecutionTriggered(msg.sender, "StrategyDeployment", tokens.length);
    }

    // Performs multiple strategy withdrawals in a single transaction
    function batchStrategyWithdrawal(
        address[] calldata tokens,
        address[] calldata strategies,
        uint256[] calldata amounts
    ) external onlyStrategist nonReentrant {
        require(tokens.length == strategies.length && tokens.length == amounts.length, "Q: Array length mismatch");
        require(tokens.length > 0, "Q: Arrays cannot be empty");

        for (uint i = 0; i < tokens.length; i++) {
            require(amounts[i] > 0, "Q: Amount must be > 0");
            require(_isApprovedStrategy[strategies[i]], "Q: Strategy not approved in batch");
            require(!_isStrategyPaused[strategies[i]], "Q: Strategy paused in batch");
            require(_strategyDeployedBalances[strategies[i]][tokens[i]] >= amounts[i], "Q: Not enough deployed balance tracked in batch");

            // Execute the withdrawal logic (same as withdrawERC20FromStrategy internal part)
            IStrategy(strategies[i]).withdraw(tokens[i], amounts[i]);
            _strategyDeployedBalances[strategies[i]][tokens[i]] -= amounts[i];

            emit StrategyWithdrawn(strategies[i], tokens[i], amounts[i]); // Log each withdrawal
        }
         emit BatchExecutionTriggered(msg.sender, "StrategyWithdrawal", tokens.length);
    }

    // --- View/Query Functions ---

    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function isERC721Owner(address token, uint256 tokenId) external view returns (bool) {
        return IERC721(token).ownerOf(tokenId) == address(this);
    }

    function getERC1155Balance(address token, uint256 id) external view returns (uint256) {
         return IERC1155(token).balanceOf(address(this), id);
    }

    // Note: Getting a list of *all* approved strategies from the mapping is not efficient on-chain.
    // This view function is just a placeholder to acknowledge the concept.
    // A real dapp would track approved strategies off-chain based on events.
    // function getApprovedStrategies() external view returns (address[] memory) {
    //    // Not possible to get all keys from a mapping efficiently.
    //    // This function is illustrative only.
    //    revert("Q: Cannot list all approved strategies on-chain");
    // }

    function getStrategyDeployedBalance(address strategy, address token) external view returns (uint256) {
         return _strategyDeployedBalances[strategy][token];
    }

    function getVersion() external pure returns (string memory) {
        return "QuantumTreasury v1.0";
    }

    // --- ERC1155Holder Implementation ---
    // Required functions for ERC1155Holder. Ensure these are present and correct.

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override returns (bytes4) {
        // Add custom logic here if needed, e.g., logging or access control for deposits
        // require(someCondition, "Deposit not allowed");
        emit DepositERC1155(msg.sender, from, id, amount); // Log arrival from original sender
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override returns (bytes4) {
        // Add custom logic here if needed
        // require(someCondition, "Batch deposit not allowed");
         for (uint i = 0; i < ids.length; i++) {
             emit DepositERC1155(msg.sender, from, ids[i], amounts[i]); // Log each arrival
         }
        return this.onERC1155BatchReceived.selector;
    }

    // The contract needs to signal that it supports the ERC1155Receiver interface.
    // ERC1155Holder does this automatically via `supportsInterface`.

}
```

---

**Explanation:**

1.  **Outline & Summary:** Clearly states the contract's purpose, roles, key features, state variables, events, modifiers, interfaces, and a summary of each function. This fulfills the user's requirement for documentation at the top.
2.  **Imports:** Includes necessary OpenZeppelin libraries for security (`Ownable`, `ReentrancyGuard`), token standards (`IERC20`, `IERC721`, `IERC1155`, `ERC1155Holder`), and a draft standard for `receive` with data.
3.  **Interfaces:** Defines simple interfaces for an `IAggregatorV3` (like Chainlink) to get price data and an `IStrategy` to interact with external protocols. These are necessary stubs for the contract to compile, but real interaction requires concrete implementations of these interfaces for specific protocols.
4.  **State Variables:** Mappings track roles, approved strategies, deployed balances within strategies, the oracle address, price threshold, and strategy pause status.
5.  **Events:** Comprehensive events log all significant actions for transparency and off-chain monitoring.
6.  **Modifiers:** Custom modifiers enforce role-based access (`onlyAdmin`, `onlyStrategist`, `onlyAdminOrStrategist`) and strategy activity status (`whenStrategyActive`).
7.  **Constructor:** Sets the initial owner (from `Ownable`) and configures the oracle address.
8.  **Receive/Deposit Functions:** Handles receiving ETH, ERC20, ERC721, and ERC1155 tokens into the treasury. Note the ERC20/ERC721 deposits require the caller to have approved the treasury first, or transfer directly before calling. ERC1155 is handled by the `ERC1155Holder` base class.
9.  **Withdrawal Functions:** Provides functions for admins to remove any supported asset type from the treasury. Secured by `onlyAdmin` and `nonReentrant`.
10. **Role Management:** Owner can grant and revoke `admin` and `strategist` roles. Helper functions `isAdmin`, `isStrategist`, `getRoleStatus` are provided.
11. **Strategy Approval:** Admins can explicitly approve external smart contract addresses as valid `strategies` that the treasury is allowed to interact with. This is a crucial security measure.
12. **Strategy Pause:** Admins can pause/unpause interactions with specific approved strategies, providing a circuit breaker for problematic protocols.
13. **Strategy Execution:** Strategists can `deployERC20ToStrategy` and `withdrawERC20FromStrategy`. These functions transfer tokens and then call the external strategy contract (via the `IStrategy` interface). `_strategyDeployedBalances` tracks the amount sent *out* to a strategy, which is a simple way to track capital allocation, though actual strategy balances might differ due to yield, losses, etc. A `claimYieldFromStrategy` function is included as a conceptual placeholder.
14. **Oracle & Conditional Execution:**
    *   Admins set the `_oracleAddress` and `_priceThreshold`.
    *   `checkOraclePrice` interacts with the oracle interface to get the latest price (requires a real oracle implementation).
    *   `conditionalERC20Transfer` and `conditionalStrategyDeployment` allow strategists to execute actions only if the current oracle price meets a condition relative to a specified price threshold. This enables automating responses to market movements.
15. **Batch Operations:** Strategists can use `batchERC20Transfer`, `batchStrategyDeployment`, and `batchStrategyWithdrawal` to execute multiple operations of the same type in a single transaction, saving gas compared to individual calls.
16. **View Functions:** Standard functions to check balances, token ownership, strategy status, and contract version.
17. **ERC1155Holder Implementation:** Includes the required `onERC1155Received` and `onERC1155BatchReceived` functions to correctly handle incoming ERC1155 transfers. Events are added here to log the arrivals.

This contract provides a solid foundation for a complex treasury with advanced management capabilities, moving beyond simple holding and controlled spending. It introduces concepts like role delegation, external protocol interaction with approval/pause mechanisms, and oracle-driven conditional logic combined with batching.