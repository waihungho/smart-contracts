Okay, here is a smart contract concept called "Quantum Vault". It incorporates ideas around dynamic state, conditional releases based on external data proofs, delegated access with granular permissions, and pseudo-random state transitions. It aims for creativity and complexity beyond basic vault or token contracts.

It's important to note that the "Quantum" aspect is a metaphor for dynamic and somewhat unpredictable (though deterministically controlled on-chain) behavior, not actual quantum computing. The randomness used is standard blockchain pseudo-randomness.

---

**Contract Name:** QuantumVault

**Concept:** A multi-asset vault (ETH and permitted ERC20s) with advanced features including:
1.  **Quantum States:** The vault operates in different "states" that can influence behavior (e.g., withdrawal limits, fees, or conditional release rules). States can transition based on internal logic and potentially pseudo-random factors.
2.  **Conditional Releases:** Assets can be locked until specific, pre-defined conditions are met and proven (simulated via a hash check of external data).
3.  **Delegated Custody:** The owner can delegate specific rights (like limited withdrawals or setting conditions) to other addresses without transferring full ownership. Permissions can be granular and revocable.
4.  **Permitted Assets:** Only whitelisted ERC20 tokens can be deposited.

**Outline:**

1.  **State Variables:** Define the core data storage (owner, state, balances, conditions, delegates, permitted tokens, etc.).
2.  **Enums:** Define the possible Quantum States.
3.  **Structs:** Define structures for `ConditionalRelease` and `DelegatePermissions`.
4.  **Events:** Declare events for key actions (deposit, withdrawal, state change, condition set, delegate added, etc.).
5.  **Modifiers:** Define access control and state-checking modifiers.
6.  **Constructor:** Initialize the contract owner and initial state.
7.  **Owner/Admin Functions:** Functions callable only by the owner or authorized admins (e.g., setting states, adding delegates, adding permitted tokens, emergency actions).
8.  **Deposit Functions:** Functions to deposit ETH and approved ERC20 tokens.
9.  **Withdrawal Functions:** Functions for owner and delegates to withdraw assets.
10. **Quantum State Management:** Functions to get, set, and attempt transitions between states.
11. **Conditional Release Management:** Functions to set, view, update, remove, and execute conditional releases.
12. **Delegation Management:** Functions to add, remove, set, and view delegate permissions.
13. **Permitted Asset Management:** Functions to add, remove, and check permitted ERC20s.
14. **View Functions:** Functions to query balances, states, conditions, and permissions.
15. **Emergency Functions:** Functions to pause/unpause or perform emergency withdrawals.
16. **Receive/Fallback:** Handle direct ETH transfers.

**Function Summary:**

1.  `constructor()`: Initializes the contract with the deployer as owner and sets an initial state.
2.  `receive() payable`: Allows receiving direct ETH transfers, forwarding them to `depositETH`.
3.  `fallback() external payable`: Handles unexpected calls, potentially forwarding to `depositETH`.
4.  `depositETH() payable`: Allows users to deposit Ether into the vault.
5.  `depositERC20(address tokenAddress, uint256 amount)`: Allows users to deposit a permitted ERC20 token, requiring prior approval.
6.  `withdrawETH(uint256 amount)`: Allows the contract owner to withdraw Ether.
7.  `withdrawERC20(address tokenAddress, uint256 amount)`: Allows the contract owner to withdraw a specific ERC20 token.
8.  `setQuantumState(QuantumState newState)`: Owner sets the vault's quantum state.
9.  `triggerStateTransitionAttempt()`: Callable by anyone. Uses block data for pseudo-randomness to potentially trigger a state change based on internal logic and current state.
10. `addConditionalRelease(address recipient, address tokenAddress, uint256 amount, uint256 unlockTime, bytes32 requiredDataHash, string description)`: Owner/Admin adds a new conditional release.
11. `updateConditionalRelease(uint256 releaseId, address recipient, address tokenAddress, uint256 amount, uint256 unlockTime, bytes32 requiredDataHash, string description)`: Owner/Admin updates an existing conditional release.
12. `removeConditionalRelease(uint256 releaseId)`: Owner/Admin removes a conditional release.
13. `executeConditionalRelease(uint256 releaseId, bytes memory offChainData)`: Anyone can call to attempt execution of a conditional release. Checks time, data hash (`sha256(offChainData) == requiredDataHash`), and vault balance.
14. `checkConditionalReleaseStatus(uint256 releaseId)`: View function to check if a specific conditional release is fulfilled or active.
15. `addDelegate(address delegateAddress, bool canWithdrawETH, bool canWithdrawERC20)`: Owner adds a delegate and sets their basic withdrawal permissions.
16. `setDelegateSpecificTokenPermission(address delegateAddress, address tokenAddress, bool allowed)`: Owner grants/revokes a delegate permission to withdraw a *specific* ERC20 token.
17. `revokeDelegatePermissions(address delegateAddress)`: Owner removes *all* permissions from a delegate.
18. `delegateWithdrawETH(uint256 amount)`: Allows a delegate with ETH withdrawal permission to withdraw Ether.
19. `delegateWithdrawERC20(address tokenAddress, uint256 amount)`: Allows a delegate with general or specific ERC20 withdrawal permission to withdraw tokens.
20. `addPermittedERC20(address tokenAddress)`: Owner adds an ERC20 token to the list of permitted deposit assets.
21. `removePermittedERC20(address tokenAddress)`: Owner removes an ERC20 token from the permitted list.
22. `isPermittedERC20(address tokenAddress)`: View function to check if a token is permitted.
23. `getVaultOwner()`: View function returning the contract owner's address.
24. `getCurrentETHBalance()`: View function returning the vault's current ETH balance.
25. `getCurrentERC20Balance(address tokenAddress)`: View function returning the vault's current balance of a specific ERC20 token.
26. `getQuantumState()`: View function returning the current quantum state.
27. `getDelegatePermissions(address delegateAddress)`: View function returning a delegate's basic permissions.
28. `getDelegateSpecificTokenPermission(address delegateAddress, address tokenAddress)`: View function returning if a delegate can withdraw a specific token.
29. `getConditionalRelease(uint256 releaseId)`: View function returning details of a conditional release.
30. `getConditionalReleaseCount()`: View function returning the total number of conditional releases ever added.
31. `pauseContract()`: Owner pauses critical contract operations (like withdrawals, state transitions).
32. `unpauseContract()`: Owner unpauses the contract.
33. `emergencyWithdrawETH(uint256 amount)`: Owner can force an ETH withdrawal even if paused.
34. `emergencyWithdrawERC20(address tokenAddress, uint256 amount)`: Owner can force an ERC20 withdrawal even if paused.
35. `transferOwnership(address newOwner)`: Standard function to transfer contract ownership.

*(Note: We already have 35+ functions listed here, meeting the requirement.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// Outline:
// 1. State Variables
// 2. Enums (Quantum States)
// 3. Structs (ConditionalRelease, DelegatePermissions)
// 4. Events
// 5. Modifiers (Custom)
// 6. Constructor
// 7. Receive/Fallback (Handle ETH deposits)
// 8. Deposit Functions (ETH, ERC20)
// 9. Withdrawal Functions (Owner ETH, Owner ERC20)
// 10. Quantum State Management (Set, Get, Trigger Transition)
// 11. Conditional Release Management (Add, Update, Remove, Execute, Check Status, Get)
// 12. Delegation Management (Add, Set Specific Token, Revoke All, Delegate Withdrawals, Get Permissions)
// 13. Permitted Asset Management (Add, Remove, Check IsPermitted, Get List - simplified by mapping)
// 14. View Functions (Balances, Owner, State, Counts)
// 15. Emergency Functions (Pause, Unpause, Emergency Withdrawals)
// 16. Ownership Transfer

// Function Summary:
// constructor(): Initialize owner and state.
// receive()/fallback(): Handle incoming ETH.
// depositETH(): Deposit ETH.
// depositERC20(address tokenAddress, uint256 amount): Deposit permitted ERC20.
// withdrawETH(uint256 amount): Owner withdraws ETH.
// withdrawERC20(address tokenAddress, uint256 amount): Owner withdraws ERC20.
// setQuantumState(QuantumState newState): Owner sets state.
// triggerStateTransitionAttempt(): Pseudo-randomly attempt state change.
// addConditionalRelease(address recipient, address tokenAddress, uint256 amount, uint256 unlockTime, bytes32 requiredDataHash, string description): Add timed+data-based release.
// updateConditionalRelease(uint256 releaseId, ...): Modify a conditional release.
// removeConditionalRelease(uint256 releaseId): Owner/Admin removes condition.
// executeConditionalRelease(uint256 releaseId, bytes memory offChainData): Execute release if conditions met (time + data hash).
// checkConditionalReleaseStatus(uint256 releaseId): Check if a condition is fulfilled.
// addDelegate(address delegateAddress, bool canWithdrawETH, bool canWithdrawERC20): Add delegate with basic rights.
// setDelegateSpecificTokenPermission(address delegateAddress, address tokenAddress, bool allowed): Set delegate's specific token right.
// revokeDelegatePermissions(address delegateAddress): Remove all delegate rights.
// delegateWithdrawETH(uint256 amount): Delegate withdraws ETH based on permission.
// delegateWithdrawERC20(address tokenAddress, uint256 amount): Delegate withdraws ERC20 based on permission.
// addPermittedERC20(address tokenAddress): Owner adds an allowed ERC20.
// removePermittedERC20(address tokenAddress): Owner removes an allowed ERC20.
// isPermittedERC20(address tokenAddress): Check if ERC20 is permitted.
// getVaultOwner(): Get owner address.
// getCurrentETHBalance(): Get vault's ETH balance.
// getCurrentERC20Balance(address tokenAddress): Get vault's ERC20 balance.
// getQuantumState(): Get current state.
// getDelegatePermissions(address delegateAddress): Get basic delegate permissions.
// getDelegateSpecificTokenPermission(address delegateAddress, address tokenAddress): Get specific delegate token permission.
// getConditionalRelease(uint256 releaseId): Get details of a conditional release.
// getConditionalReleaseCount(): Get total condition count.
// pauseContract(): Owner pauses contract.
// unpauseContract(): Owner unpauses contract.
// emergencyWithdrawETH(uint256 amount): Owner emergency withdraws ETH.
// emergencyWithdrawERC20(address tokenAddress, uint256 amount): Owner emergency withdraws ERC20.
// transferOwnership(address newOwner): Transfer ownership.


contract QuantumVault is Ownable, Pausable, ReentrancyGuard {

    // 1. State Variables
    enum QuantumState { Locked, Flow, Turbulent, Entropy }
    QuantumState private currentQuantumState;

    mapping(address => bool) private permittedERC20s;
    address[] private permittedERC20List; // To allow retrieval of the list

    uint256 private nextConditionalReleaseId = 0;

    // 3. Structs
    struct ConditionalRelease {
        address recipient;
        address token; // Address 0x0 for ETH
        uint256 amount;
        uint256 unlockTime;
        bytes32 requiredDataHash; // Hash of off-chain data required for release
        bool isFulfilled;
        bool isActive; // Allows deactivating without removing
        string description; // Added for clarity
    }

    mapping(uint256 => ConditionalRelease) private conditionalReleases;
    mapping(address => bool) private isDelegate; // Quick check if address is a delegate

    struct DelegatePermissions {
        bool canWithdrawETH;
        bool canWithdrawERC20; // General permission for *any* permitted token
    }

    mapping(address => DelegatePermissions) private delegatePermissions;
    mapping(address => mapping(address => bool)) private delegateSpecificTokenPermissions; // Specific token permissions override general


    // 4. Events
    event EtherDeposited(address indexed depositor, uint256 amount);
    event ERC20Deposited(address indexed depositor, address indexed token, uint256 amount);
    event EtherWithdrawn(address indexed recipient, uint256 amount);
    event ERC20Withdrawn(address indexed recipient, address indexed token, uint256 amount);
    event QuantumStateChanged(QuantumState newState);
    event StateTransitionAttempted(uint256 seed, bool stateChanged, QuantumState oldState, QuantumState newState);
    event ConditionalReleaseAdded(uint256 indexed releaseId, address indexed recipient, address indexed token, uint256 amount);
    event ConditionalReleaseUpdated(uint256 indexed releaseId);
    event ConditionalReleaseRemoved(uint256 indexed releaseId);
    event ConditionalReleaseExecuted(uint256 indexed releaseId, address indexed recipient, uint256 amount);
    event DelegateAdded(address indexed delegate);
    event DelegatePermissionsUpdated(address indexed delegate, bool canWithdrawETH, bool canWithdrawERC20);
    event DelegateSpecificTokenPermissionUpdated(address indexed delegate, address indexed token, bool allowed);
    event DelegateRevoked(address indexed delegate);
    event PermittedERC20Added(address indexed token);
    event PermittedERC20Removed(address indexed token);
    event EmergencyWithdrawal(address indexed recipient, uint256 ethAmount, uint256 erc20Amount);


    // 5. Modifiers
    modifier onlyDelegate(address _delegate) {
        require(isDelegate[_delegate], "QV: Caller is not a delegate");
        _;
    }

    // 6. Constructor
    constructor() Ownable(msg.sender) Pausable() {
        currentQuantumState = QuantumState.Locked; // Initial state
    }

    // 7. Receive/Fallback
    // Function to receive Ether. Triggered by a plain Ether transfer.
    receive() external payable {
        depositETH();
    }

    // Fallback function is called when msg.data is not empty and no function matches
    fallback() external payable {
        depositETH(); // Treat unexpected calls with value as deposits
    }


    // 8. Deposit Functions
    function depositETH() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "QV: Deposit amount must be greater than 0");
        // ETH balance is implicitly updated by payable
        emit EtherDeposited(msg.sender, msg.value);
    }

    function depositERC20(address tokenAddress, uint256 amount) public whenNotPaused nonReentrant {
        require(permittedERC20s[tokenAddress], "QV: Token is not permitted");
        require(amount > 0, "QV: Deposit amount must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        // Transfer tokens from the sender to the contract
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "QV: ERC20 transfer failed");
        emit ERC20Deposited(msg.sender, tokenAddress, amount);
    }


    // 9. Withdrawal Functions (Owner)
    function withdrawETH(uint256 amount) public onlyOwner whenNotPaused nonReentrant {
        require(address(this).balance >= amount, "QV: Insufficient ETH balance");
        require(amount > 0, "QV: Withdrawal amount must be greater than 0");

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "QV: ETH withdrawal failed");
        emit EtherWithdrawn(owner(), amount);
    }

    function withdrawERC20(address tokenAddress, uint256 amount) public onlyOwner whenNotPaused nonReentrant {
        require(permittedERC20s[tokenAddress], "QV: Token is not permitted");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QV: Insufficient ERC20 balance");
        require(amount > 0, "QV: Withdrawal amount must be greater than 0");

        bool success = token.transfer(owner(), amount);
        require(success, "QV: ERC20 withdrawal failed");
        emit ERC20Withdrawn(owner(), tokenAddress, amount);
    }


    // 10. Quantum State Management
    function setQuantumState(QuantumState newState) public onlyOwner {
        require(currentQuantumState != newState, "QV: Already in this state");
        QuantumState oldState = currentQuantumState;
        currentQuantumState = newState;
        emit QuantumStateChanged(currentQuantumState);
        emit StateTransitionAttempted(0, true, oldState, newState); // Explicit change, no randomness used
    }

    function triggerStateTransitionAttempt() public whenNotPaused {
        // This is a simple pseudo-random state transition based on block data
        // NOT cryptographically secure randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number, tx.origin, msg.sender)));
        uint256 randomValue = seed % 100; // Value between 0-99

        QuantumState oldState = currentQuantumState;
        bool stateChanged = false;
        QuantumState newState = currentQuantumState;

        // Example transition logic (can be complex based on state and randomValue)
        if (currentQuantumState == QuantumState.Locked && randomValue < 10) { // 10% chance to move from Locked
            newState = QuantumState.Flow;
            stateChanged = true;
        } else if (currentQuantumState == QuantumState.Flow && randomValue < 20) { // 20% chance from Flow
             // Randomly pick between Turbulent (e.g., <10) or Locked (e.g., >=10)
            if (randomValue < 10) newState = QuantumState.Turbulent;
            else newState = QuantumState.Locked;
            stateChanged = true;
        } else if (currentQuantumState == QuantumState.Turbulent && randomValue < 50) { // 50% chance from Turbulent
             // Randomly pick between Entropy (e.g., <25) or Flow (e.g., >=25)
            if (randomValue < 25) newState = QuantumState.Entropy;
            else newState = QuantumState.Flow;
            stateChanged = true;
        } else if (currentQuantumState == QuantumState.Entropy && randomValue < 5) { // 5% chance from Entropy
            newState = QuantumState.Locked; // Maybe Entropy is a terminal state or very unlikely to leave
            stateChanged = true;
        }

        if (stateChanged) {
            currentQuantumState = newState;
            emit QuantumStateChanged(currentQuantumState);
        }
        emit StateTransitionAttempted(seed, stateChanged, oldState, newState);
    }


    // 11. Conditional Release Management
    function addConditionalRelease(
        address recipient,
        address tokenAddress, // Use address(0) for ETH
        uint256 amount,
        uint256 unlockTime,
        bytes32 requiredDataHash, // Hash of the data that must be proven
        string memory description
    ) public onlyOwner whenNotPaused nonReentrant returns (uint256 releaseId) {
        require(recipient != address(0), "QV: Recipient cannot be zero address");
        if (tokenAddress != address(0)) {
            require(permittedERC20s[tokenAddress], "QV: Token is not permitted for conditional release");
        }
        require(amount > 0, "QV: Release amount must be greater than 0");
        // unlockTime can be 0 if only data hash is the condition trigger

        releaseId = nextConditionalReleaseId++;
        conditionalReleases[releaseId] = ConditionalRelease({
            recipient: recipient,
            token: tokenAddress,
            amount: amount,
            unlockTime: unlockTime,
            requiredDataHash: requiredDataHash,
            isFulfilled: false,
            isActive: true,
            description: description
        });

        emit ConditionalReleaseAdded(releaseId, recipient, tokenAddress, amount);
        return releaseId;
    }

    function updateConditionalRelease(
        uint256 releaseId,
        address recipient,
        address tokenAddress, // Use address(0) for ETH
        uint256 amount,
        uint256 unlockTime,
        bytes32 requiredDataHash,
        string memory description
    ) public onlyOwner whenNotPaused nonReentrant {
        ConditionalRelease storage release = conditionalReleases[releaseId];
        require(release.isActive, "QV: Release is not active");
        require(!release.isFulfilled, "QV: Release is already fulfilled");
        require(recipient != address(0), "QV: Recipient cannot be zero address");
         if (tokenAddress != address(0)) {
            require(permittedERC20s[tokenAddress], "QV: Token is not permitted for conditional release");
        }
        require(amount > 0, "QV: Release amount must be greater than 0");

        release.recipient = recipient;
        release.token = tokenAddress;
        release.amount = amount;
        release.unlockTime = unlockTime;
        release.requiredDataHash = requiredDataHash;
        release.description = description;

        emit ConditionalReleaseUpdated(releaseId);
    }

    function removeConditionalRelease(uint256 releaseId) public onlyOwner {
        ConditionalRelease storage release = conditionalReleases[releaseId];
        require(release.isActive, "QV: Release is not active or already removed");
        require(!release.isFulfilled, "QV: Release is already fulfilled");

        release.isActive = false; // Deactivate instead of deleting for history
        // Consider adding a way to hard delete for privacy/gas if needed, but soft delete is safer

        emit ConditionalReleaseRemoved(releaseId);
    }

    function executeConditionalRelease(uint256 releaseId, bytes memory offChainData) public nonReentrant {
        ConditionalRelease storage release = conditionalReleases[releaseId];
        require(release.isActive, "QV: Release is not active");
        require(!release.isFulfilled, "QV: Release is already fulfilled");

        // Check time condition
        require(block.timestamp >= release.unlockTime, "QV: Unlock time has not passed");

        // Check data condition (hash proof)
        // This simulates needing off-chain data (like a sports result, a complex computation result, etc.)
        // The caller provides the raw data, and the contract verifies its integrity via the hash
        require(sha256(offChainData) == release.requiredDataHash, "QV: Off-chain data hash does not match");

        // Check balance
        if (release.token == address(0)) { // ETH release
            require(address(this).balance >= release.amount, "QV: Insufficient ETH balance for release");
            (bool success, ) = payable(release.recipient).call{value: release.amount}("");
            require(success, "QV: Conditional ETH withdrawal failed");
        } else { // ERC20 release
            IERC20 token = IERC20(release.token);
            require(token.balanceOf(address(this)) >= release.amount, "QV: Insufficient ERC20 balance for release");
            bool success = token.transfer(release.recipient, release.amount);
            require(success, "QV: Conditional ERC20 withdrawal failed");
        }

        release.isFulfilled = true;
        emit ConditionalReleaseExecuted(releaseId, release.recipient, release.amount);
    }

     function checkConditionalReleaseStatus(uint256 releaseId) public view returns (bool isActive, bool isFulfilled, bool conditionsMet) {
        ConditionalRelease storage release = conditionalReleases[releaseId];
        isActive = release.isActive;
        isFulfilled = release.isFulfilled;

        if (!isActive || isFulfilled) {
            conditionsMet = false; // Already fulfilled or inactive
        } else {
             // Check if conditions *are* met (time + data hash - data hash check requires input,
             // so we can only check the *time* and if a hash is required vs 0)
             // A proper off-chain data check can't happen in a view function.
             // We'll approximate: conditions are potentially met if time passed AND a required hash is set OR if only time is required.
            bool timeConditionMet = block.timestamp >= release.unlockTime;
            bool dataConditionRequiredAndLikelyMet = (release.requiredDataHash != bytes32(0)); // Cannot check actual data hash in view

            // Simplified check for *potential* execution readiness for the view function:
            // Time must be met AND (either data hash is 0x0 OR a hash is set, assuming data *could* be provided externally)
            conditionsMet = timeConditionMet && (release.requiredDataHash == bytes32(0) || release.requiredDataHash != bytes32(0)); // This is not fully accurate for the data check
            // A better view would require the actual offChainData, which isn't possible.
            // This view just checks if time is met and if the condition *is* active and not fulfilled.
            conditionsMet = timeConditionMet && isActive && !isFulfilled;
        }
    }


    // 12. Delegation Management
    function addDelegate(address delegateAddress, bool canWithdrawETH, bool canWithdrawERC20) public onlyOwner {
        require(delegateAddress != address(0), "QV: Delegate cannot be zero address");
        isDelegate[delegateAddress] = true;
        delegatePermissions[delegateAddress] = DelegatePermissions({
            canWithdrawETH: canWithdrawETH,
            canWithdrawERC20: canWithdrawERC20
        });
        emit DelegateAdded(delegateAddress);
        emit DelegatePermissionsUpdated(delegateAddress, canWithdrawETH, canWithdrawERC20);
    }

    function setDelegateSpecificTokenPermission(address delegateAddress, address tokenAddress, bool allowed) public onlyOwner {
        require(isDelegate[delegateAddress], "QV: Address is not a delegate");
        require(tokenAddress != address(0), "QV: Token cannot be zero address");
        delegateSpecificTokenPermissions[delegateAddress][tokenAddress] = allowed;
        emit DelegateSpecificTokenPermissionUpdated(delegateAddress, tokenAddress, allowed);
    }

    function revokeDelegatePermissions(address delegateAddress) public onlyOwner {
        require(isDelegate[delegateAddress], "QV: Address is not a delegate");
        delete isDelegate[delegateAddress]; // Removes from delegate list
        delete delegatePermissions[delegateAddress]; // Removes basic permissions

        // Need to clear specific permissions - iterate over permitted tokens or just rely on isDelegate check?
        // Relying on isDelegate check is simpler: if not a delegate, specific permissions mapping is irrelevant.

        emit DelegateRevoked(delegateAddress);
    }

    function delegateWithdrawETH(uint256 amount) public onlyDelegate(msg.sender) whenNotPaused nonReentrant {
        require(delegatePermissions[msg.sender].canWithdrawETH, "QV: Delegate has no ETH withdrawal permission");
         require(amount > 0, "QV: Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "QV: Insufficient ETH balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "QV: Delegate ETH withdrawal failed");
        emit EtherWithdrawn(msg.sender, amount);
    }

    function delegateWithdrawERC20(address tokenAddress, uint256 amount) public onlyDelegate(msg.sender) whenNotPaused nonReentrant {
        require(permittedERC20s[tokenAddress], "QV: Token is not permitted");
        require(amount > 0, "QV: Withdrawal amount must be greater than 0");

        // Check general permission OR specific token permission
        bool hasPermission = delegatePermissions[msg.sender].canWithdrawERC20 ||
                             delegateSpecificTokenPermissions[msg.sender][tokenAddress];
        require(hasPermission, "QV: Delegate has no ERC20 withdrawal permission for this token");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QV: Insufficient ERC20 balance");

        bool success = token.transfer(msg.sender, amount);
        require(success, "QV: Delegate ERC20 withdrawal failed");
        emit ERC20Withdrawn(msg.sender, tokenAddress, amount);
    }


    // 13. Permitted Asset Management
    function addPermittedERC20(address tokenAddress) public onlyOwner {
        require(tokenAddress != address(0), "QV: Token address cannot be zero");
        require(!permittedERC20s[tokenAddress], "QV: Token already permitted");
        permittedERC20s[tokenAddress] = true;
        permittedERC20List.push(tokenAddress); // Add to list for retrieval
        emit PermittedERC20Added(tokenAddress);
    }

    function removePermittedERC20(address tokenAddress) public onlyOwner {
        require(permittedERC20s[tokenAddress], "QV: Token is not permitted");
        permittedERC20s[tokenAddress] = false;
        // Removing from array is complex and gas intensive. For simplicity, we'll
        // leave it in the list but rely on the mapping `permittedERC20s` for actual checks.
        // A more advanced version would use a linked list or other pattern for removal.
        emit PermittedERC20Removed(tokenAddress);
    }

    function isPermittedERC20(address tokenAddress) public view returns (bool) {
        return permittedERC20s[tokenAddress];
    }

    function getPermittedERC20List() public view returns (address[] memory) {
        // This returns the list of tokens EVER added. Check `isPermittedERC20` for current status.
        // Returning only *currently* permitted requires iterating, which can be gas intensive.
        // For simplicity and view function gas limits, we return the historical list.
         return permittedERC20List;
    }


    // 14. View Functions
    function getVaultOwner() public view returns (address) {
        return owner();
    }

    function getCurrentETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getCurrentERC20Balance(address tokenAddress) public view returns (uint256) {
        if (!permittedERC20s[tokenAddress] && tokenAddress != address(0)) {
             // Optionally revert or return 0 if not permitted. Returning 0 is safer for view.
             return 0;
        }
        if (tokenAddress == address(0)) return address(this).balance; // ETH case
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    function getQuantumState() public view returns (QuantumState) {
        return currentQuantumState;
    }

    function getDelegatePermissions(address delegateAddress) public view returns (bool canWithdrawETH, bool canWithdrawERC20) {
        DelegatePermissions storage perms = delegatePermissions[delegateAddress];
        return (perms.canWithdrawETH, perms.canWithdrawERC20);
    }

    function getDelegateSpecificTokenPermission(address delegateAddress, address tokenAddress) public view returns (bool) {
         if (!isDelegate[delegateAddress] || tokenAddress == address(0)) return false; // Must be a delegate and valid token
         return delegateSpecificTokenPermissions[delegateAddress][tokenAddress];
    }

    function getConditionalRelease(uint256 releaseId) public view returns (ConditionalRelease memory) {
        // Note: Will return empty struct if ID does not exist.
        return conditionalReleases[releaseId];
    }

    function getConditionalReleaseCount() public view returns (uint256) {
        return nextConditionalReleaseId;
    }


    // 15. Emergency Functions
    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function emergencyWithdrawETH(uint256 amount) public onlyOwner nonReentrant {
         require(address(this).balance >= amount, "QV: Insufficient ETH balance for emergency");
         require(amount > 0, "QV: Emergency withdrawal amount must be > 0");
         // Ignores pause state for emergency

         (bool success, ) = payable(owner()).call{value: amount}("");
         require(success, "QV: Emergency ETH withdrawal failed");
         emit EmergencyWithdrawal(owner(), amount, 0);
    }

    function emergencyWithdrawERC20(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        require(permittedERC20s[tokenAddress], "QV: Token is not permitted for emergency withdrawal");
        require(amount > 0, "QV: Emergency withdrawal amount must be > 0");
        // Ignores pause state for emergency

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QV: Insufficient ERC20 balance for emergency");

        bool success = token.transfer(owner(), amount);
        require(success, "QV: Emergency ERC20 withdrawal failed");
        emit EmergencyWithdrawal(owner(), 0, amount);
    }

    // 16. Ownership Transfer
    // inherit transferOwnership from Ownable
    // function transferOwnership(address newOwner) public virtual override onlyOwner {
    //     super.transferOwnership(newOwner);
    // }
    // It's already public and virtual in Ownable, so no need to redefine unless changing behavior.
    // Keeping it here in summary for completeness.

}
```