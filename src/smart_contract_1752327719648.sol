Okay, this is an interesting challenge! We'll create a smart contract called `QuantumVault`. This contract will combine vault functionality with concepts inspired by quantum mechanics (metaphorically, of course, as EVM is classical) like "state superposition" and "entanglement" to add unique conditions for operations.

**Concepts Used:**

1.  **Quantum State Metaphor:** An internal state (`quantumParameterA`, `quantumParameterB`) that fluctuates (`triggerQuantumFluctuation`).
2.  **State Collapse:** The state must be "collapsed" (`collapseQuantumState`) by the owner *after* sufficient "observer" attestations, fixing the parameters for certain operations.
3.  **Observer Pattern:** Designated addresses (`observers`) who can attest to the state before collapse. A threshold is required.
4.  **Entanglement Metaphor:** Linking multiple accounts (`entangledAccounts`) such that actions (like withdrawals) require approval from a threshold of these accounts *after* the state is collapsed.
5.  **Conditional Operations:** Withdrawals and potentially other actions depend on the collapsed state and entanglement approvals.
6.  **Time Locks:** Standard feature added for layered security, potentially interacting with the quantum state logic.
7.  **Request-Based Workflow:** Withdrawals go through a request-approval-execution flow.

---

### QuantumVault Smart Contract

**Outline:**

1.  **State Variables:** Store ownership, balances, supported tokens, quantum parameters, state collapse status, observer/entangled mappings, attestation/approval counts, withdrawal requests, time lock details.
2.  **Events:** Log important actions and state changes.
3.  **Modifiers:** Define access control (e.g., `onlyOwner`, `onlyObserver`, `onlyEntangled`).
4.  **Constructor:** Initialize the contract with the owner.
5.  **Receive/Fallback:** Allow receiving Ether deposits.
6.  **Ownership Management:** Functions to transfer/renounce ownership.
7.  **Token Management:** Functions to add/remove supported ERC20 tokens.
8.  **Vault Operations:** Deposit Ether/ERC20.
9.  **Quantum State Management:** Functions to trigger fluctuations, record observer attestations, set observer threshold, collapse the state, reset attestations.
10. **Entanglement Management:** Functions to add/remove entangled accounts, set approval threshold.
11. **Withdrawal Request Workflow:** Functions to request withdrawal (requires collapsed state), record entanglement approvals, execute withdrawal (requires approval threshold), cancel request, get request status.
12. **Time Lock:** Functions to lock/unlock the vault based on time.
13. **Emergency Operations:** Emergency withdrawal bypassing some rules (owner only).
14. **Getter Functions:** Retrieve various state variables (balances, lists, statuses).

**Function Summary:**

1.  `constructor(address initialOwner)`: Deploys the contract, sets the initial owner.
2.  `receive() external payable`: Allows receiving Ether directly into the vault.
3.  `depositERC20(address token, uint256 amount)`: Deposits a specified amount of a supported ERC20 token into the vault.
4.  `addSupportedERC20(address token)`: (Owner) Adds an ERC20 token address to the list of supported tokens.
5.  `removeSupportedERC20(address token)`: (Owner) Removes an ERC20 token address from the supported list.
6.  `getSupportedERC20s() view returns (address[])`: Get the list of supported ERC20 token addresses.
7.  `triggerQuantumFluctuation()`: (Owner or Observer) Simulates a quantum state change by altering internal parameters. Can only happen when state is *not* collapsed.
8.  `getQuantumParameters() view returns (uint256, uint256)`: Get the current values of the internal quantum parameters.
9.  `addObserver(address observer)`: (Owner) Adds an address to the list of official observers.
10. `removeObserver(address observer)`: (Owner) Removes an address from the observer list.
11. `isObserver(address potentialObserver) view returns (bool)`: Check if an address is an observer.
12. `setObserverAttestationThreshold(uint256 threshold)`: (Owner) Sets the minimum number of observer attestations required to collapse the state.
13. `recordObserverAttestation()`: (Observer) Records an attestation for the current quantum state. Can only attest once per state pre-collapse.
14. `getObserverAttestationCount() view returns (uint256)`: Get the current number of observer attestations.
15. `collapseQuantumState()`: (Owner) Finalizes the current quantum parameters into a derived value if the observer attestation threshold is met. Resets attestations.
16. `isStateCollapsed() view returns (bool)`: Check if the quantum state is currently collapsed.
17. `getCurrentCollapsedStateValue() view returns (uint256)`: Get the fixed value derived from parameters after collapse. (Returns 0 if not collapsed).
18. `addEntangledAccount(address account)`: (Owner) Adds an address to the list of entangled accounts.
19. `removeEntangledAccount(address account)`: (Owner) Removes an address from the entangled list.
20. `isEntangled(address potentialAccount) view returns (bool)`: Check if an address is entangled.
21. `setEntanglementApprovalThreshold(uint256 threshold)`: (Owner) Sets the minimum number of entangled account approvals needed for a withdrawal execution.
22. `requestWithdrawalEther(uint256 amount, address payable recipient)`: (Any address) Requests to withdraw Ether. Requires state to be collapsed and vault not time-locked. Creates a withdrawal request.
23. `requestWithdrawalERC20(address token, uint256 amount, address recipient)`: (Any address) Requests to withdraw an ERC20 token. Requires state to be collapsed and vault not time-locked. Creates a withdrawal request.
24. `recordEntanglementApproval(uint256 requestId)`: (Entangled Account) Approves a specific withdrawal request. Can only approve once per request.
25. `getWithdrawalRequestStatus(uint256 requestId) view returns (tuple)`: Get details and approval count for a specific withdrawal request.
26. `executeWithdrawal(uint256 requestId)`: (Request Initiator or Owner) Executes a withdrawal request if the entanglement approval threshold is met and the request is valid/not executed/not cancelled.
27. `cancelWithdrawalRequest(uint256 requestId)`: (Request Initiator or Owner) Cancels an open withdrawal request.
28. `lockVaultTemporarily(uint40 duration)`: (Owner) Locks the vault for withdrawals until a specific timestamp (current time + duration). Can only extend existing locks.
29. `unlockVault()`: (Owner) Removes the time lock if the lock period has expired.
30. `isVaultLocked() view returns (bool)`: Check if the vault is currently time-locked.
31. `emergencyWithdrawEther(uint256 amount, address payable recipient)`: (Owner) Allows owner to withdraw Ether immediately, bypassing quantum/entanglement/time lock rules. Use with caution.
32. `emergencyWithdrawERC20(address token, uint256 amount, address recipient)`: (Owner) Allows owner to withdraw ERC20 immediately, bypassing quantum/entanglement/time lock rules. Use with caution.
33. `transferOwnership(address newOwner)`: (Owner) Transfers ownership of the contract.
34. `renounceOwnership()`: (Owner) Renounces ownership of the contract (sets owner to zero address).
35. `getVaultEtherBalance() view returns (uint256)`: Get the Ether balance held in the vault.
36. `getVaultERC20Balance(address token) view returns (uint256)`: Get the balance of a specific ERC20 token held in the vault.
37. `getEntangledAccounts() view returns (address[])`: Get the list of entangled account addresses.
38. `getObservers() view returns (address[])`: Get the list of observer addresses.
39. `resetObserverAttestations()`: (Owner) Resets the observer attestation count and map. Useful after state collapse or if collapsing failed.
40. `resetEntanglementApprovals(uint256 requestId)`: (Owner) Resets entanglement approvals for a specific withdrawal request.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumVault
 * @dev A metaphorical "Quantum" influenced smart contract vault.
 * It introduces concepts like state "superposition" & "collapse",
 * "observers" for state attestation, and "entanglement" for conditional
 * multi-party withdrawal approvals.
 */
contract QuantumVault {

    // --- Outline ---
    // 1. State Variables
    // 2. Events
    // 3. Modifiers
    // 4. Constructor
    // 5. Receive/Fallback
    // 6. Ownership Management
    // 7. Token Management
    // 8. Vault Operations (Deposit)
    // 9. Quantum State Management (Fluctuate, Attest, Collapse, Getters)
    // 10. Entanglement Management (Add/Remove, Set Threshold, Getters)
    // 11. Withdrawal Request Workflow (Request, Approve, Execute, Cancel, Getters)
    // 12. Time Lock (Lock, Unlock, Getter)
    // 13. Emergency Operations (Withdraw bypassing rules)
    // 14. Getter Functions (Balances, Lists, Statuses)

    // --- Function Summary ---
    // 1. constructor(address initialOwner): Initializes the contract owner.
    // 2. receive(): Allows receiving Ether.
    // 3. depositERC20(address token, uint256 amount): Deposit supported ERC20.
    // 4. addSupportedERC20(address token): (Owner) Add token to supported list.
    // 5. removeSupportedERC20(address token): (Owner) Remove token.
    // 6. getSupportedERC20s() view: Get supported tokens list.
    // 7. triggerQuantumFluctuation(): (Owner/Observer) Change quantum state params.
    // 8. getQuantumParameters() view: Get current quantum params.
    // 9. addObserver(address observer): (Owner) Add an observer.
    // 10. removeObserver(address observer): (Owner) Remove an observer.
    // 11. isObserver(address potentialObserver) view: Check if observer.
    // 12. setObserverAttestationThreshold(uint256 threshold): (Owner) Set attestation threshold for collapse.
    // 13. recordObserverAttestation(): (Observer) Attest to current state for collapse.
    // 14. getObserverAttestationCount() view: Get current attestations.
    // 15. collapseQuantumState(): (Owner) Collapse state if attestation threshold met.
    // 16. isStateCollapsed() view: Check if state is collapsed.
    // 17. getCurrentCollapsedStateValue() view: Get value after collapse.
    // 18. addEntangledAccount(address account): (Owner) Add entangled account.
    // 19. removeEntangledAccount(address account): (Owner) Remove entangled account.
    // 20. isEntangled(address potentialAccount) view: Check if entangled.
    // 21. setEntanglementApprovalThreshold(uint256 threshold): (Owner) Set approval threshold for withdrawals.
    // 22. requestWithdrawalEther(uint256 amount, address payable recipient): Request Ether withdrawal (requires collapsed state).
    // 23. requestWithdrawalERC20(address token, uint256 amount, address recipient): Request ERC20 withdrawal (requires collapsed state).
    // 24. recordEntanglementApproval(uint256 requestId): (Entangled) Approve a withdrawal request.
    // 25. getWithdrawalRequestStatus(uint256 requestId) view: Get withdrawal request details/status.
    // 26. executeWithdrawal(uint256 requestId): (Request Initiator/Owner) Execute withdrawal if approvals met.
    // 27. cancelWithdrawalRequest(uint256 requestId): (Request Initiator/Owner) Cancel a request.
    // 28. lockVaultTemporarily(uint40 duration): (Owner) Set a time lock.
    // 29. unlockVault(): (Owner) Remove time lock if expired.
    // 30. isVaultLocked() view: Check if vault is locked.
    // 31. emergencyWithdrawEther(uint256 amount, address payable recipient): (Owner) Bypass withdrawal rules.
    // 32. emergencyWithdrawERC20(address token, uint256 amount, address recipient): (Owner) Bypass withdrawal rules.
    // 33. transferOwnership(address newOwner): (Owner) Transfer ownership.
    // 34. renounceOwnership(): (Owner) Renounce ownership.
    // 35. getVaultEtherBalance() view: Get contract Ether balance.
    // 36. getVaultERC20Balance(address token) view: Get contract ERC20 balance.
    // 37. getEntangledAccounts() view: Get entangled accounts list.
    // 38. getObservers() view: Get observers list.
    // 39. resetObserverAttestations(): (Owner) Reset observer attestations.
    // 40. resetEntanglementApprovals(uint256 requestId): (Owner) Reset approvals for a request.


    // --- State Variables ---

    address private _owner;

    // Supported Tokens
    mapping(address => bool) private _isSupportedToken;
    address[] private _supportedTokens; // Keep track of supported tokens for listing

    // Quantum State Metaphor
    uint256 private _quantumParameterA;
    uint256 private _quantumParameterB;
    bool private _isStateCollapsed;
    uint256 private _currentCollapsedStateValue; // Fixed value after collapse

    // Observers (for State Attestation)
    mapping(address => bool) private _isObserverAccount;
    address[] private _observerAccounts; // Keep track for listing
    mapping(address => bool) private _observerAttestedForCollapse; // Has observer attested since last fluctuation/collapse?
    uint256 private _observerAttestationCount;
    uint256 private _observerAttestationThreshold;

    // Entangled Accounts (for Withdrawal Approvals)
    mapping(address => bool) private _isEntangledAccount;
    address[] private _entangledAccounts; // Keep track for listing
    uint256 private _entanglementApprovalThreshold;

    // Withdrawal Request Workflow
    struct WithdrawalRequest {
        address initiator;
        address payable recipient;
        address tokenAddress; // 0x0 for Ether
        uint256 amount;
        bool isEther;
        uint256 approvalCount;
        mapping(address => bool) approvals; // Which entangled accounts approved this request
        bool isExecuted;
        bool isCancelled;
    }
    mapping(uint256 => WithdrawalRequest) private _withdrawalRequests;
    uint256 private _nextWithdrawalRequestId = 1; // Start request IDs from 1

    // Time Lock
    uint40 private _lockEndTime; // Timestamp until vault is locked

    // --- Events ---

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event EtherDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed token, address indexed sender, uint256 amount);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event QuantumFluctuationTriggered(address indexed by, uint256 newParameterA, uint256 newParameterB);
    event ObserverAdded(address indexed observer);
    event ObserverRemoved(address indexed observer);
    event ObserverAttestationThresholdSet(uint256 threshold);
    event ObserverAttestationRecorded(address indexed observer, uint256 currentCount);
    event StateCollapsed(uint256 collapsedValue, uint256 timestamp);
    event EntangledAccountAdded(address indexed account);
    event EntangledAccountRemoved(address indexed account);
    event EntanglementApprovalThresholdSet(uint256 threshold);
    event WithdrawalRequested(uint256 indexed requestId, address indexed initiator, address recipient, address token, uint256 amount, bool isEther);
    event EntanglementApprovalRecorded(uint256 indexed requestId, address indexed approver, uint256 currentCount);
    event WithdrawalExecuted(uint256 indexed requestId, address indexed recipient, address token, uint256 amount, bool isEther);
    event WithdrawalCancelled(uint256 indexed requestId, address indexed initiator);
    event VaultLocked(uint40 until);
    event VaultUnlocked();
    event EmergencyWithdrawal(address indexed token, address indexed recipient, uint256 amount, bool isEther);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "QV: Not the owner");
        _;
    }

    // Basic IERC20 interface (no OpenZeppelin)
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

    // --- Constructor ---

    constructor(address initialOwner) {
        require(initialOwner != address(0), "QV: Owner cannot be zero address");
        _owner = initialOwner;
        _observerAttestationThreshold = 1; // Default threshold
        _entanglementApprovalThreshold = 1; // Default threshold
        // Initialize quantum parameters with some basic pseudo-randomness
        _quantumParameterA = uint256(keccak256(abi.encodePacked(block.timestamp, block.coinbase, msg.sender))) % 1000;
        _quantumParameterB = uint256(keccak256(abi.encodePacked(block.number, msg.sender, block.difficulty))) % 1000; // block.difficulty is deprecated but used here for illustrative randomness
        _isStateCollapsed = false;
    }

    // --- Receive/Fallback ---

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    // --- Ownership Management ---

    /**
     * @dev Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "QV: New owner cannot be zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Renounces the ownership of the contract.
     * Calling this leaves the contract without an owner.
     * It will not be possible to call functions guarded by the onlyOwner modifier.
     */
    function renounceOwnership() public onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    function owner() public view returns (address) {
        return _owner;
    }

    // --- Token Management ---

    /**
     * @dev Adds an ERC20 token address to the list of supported tokens.
     * Only supported tokens can be deposited or withdrawn normally.
     * @param token The address of the ERC20 token.
     */
    function addSupportedERC20(address token) public onlyOwner {
        require(token != address(0), "QV: Token address cannot be zero");
        require(!_isSupportedToken[token], "QV: Token already supported");
        _isSupportedToken[token] = true;
        _supportedTokens.push(token);
        emit SupportedTokenAdded(token);
    }

    /**
     * @dev Removes an ERC20 token address from the list of supported tokens.
     * @param token The address of the ERC20 token.
     */
    function removeSupportedERC20(address token) public onlyOwner {
        require(token != address(0), "QV: Token address cannot be zero");
        require(_isSupportedToken[token], "QV: Token not supported");
        delete _isSupportedToken[token];
        // Remove from array (inefficient for large arrays, but keeps list accurate)
        for (uint i = 0; i < _supportedTokens.length; i++) {
            if (_supportedTokens[i] == token) {
                _supportedTokens[i] = _supportedTokens[_supportedTokens.length - 1];
                _supportedTokens.pop();
                break;
            }
        }
        emit SupportedTokenRemoved(token);
    }

    /**
     * @dev Gets the list of supported ERC20 token addresses.
     */
    function getSupportedERC20s() public view returns (address[]) {
        return _supportedTokens;
    }

    // --- Vault Operations (Deposit) ---

    /**
     * @dev Deposits a specified amount of a supported ERC20 token into the vault.
     * Requires the sender to have approved the vault contract to spend the tokens.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) public {
        require(amount > 0, "QV: Deposit amount must be greater than zero");
        require(_isSupportedToken[token], "QV: Token is not supported for deposit");
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "QV: ERC20 transfer failed");
        emit ERC20Deposited(token, msg.sender, amount);
    }

    // --- Quantum State Management ---

    /**
     * @dev Simulates a quantum fluctuation, changing the internal parameters.
     * Can be triggered by the owner or any observer account.
     * Resets the state collapse status and observer attestations.
     * Requires the state to NOT be collapsed.
     */
    function triggerQuantumFluctuation() public {
        require(!_isStateCollapsed, "QV: State is already collapsed, cannot fluctuate");
        require(msg.sender == _owner || _isObserverAccount[msg.sender], "QV: Only owner or observer can trigger fluctuation");

        // Introduce pseudo-randomness based on varying block/sender data
        _quantumParameterA = uint256(keccak256(abi.encodePacked(_quantumParameterA, block.timestamp, tx.origin, msg.sender))) % 10000;
        _quantumParameterB = uint256(keccak256(abi.encodePacked(_quantumParameterB, block.number, msg.sender, block.coinbase))) % 10000;

        // Reset for next collapse cycle
        _isStateCollapsed = false;
        _observerAttestationCount = 0;
        // Re-initialize the attestation map
        for(uint i = 0; i < _observerAccounts.length; i++){
             _observerAttestedForCollapse[_observerAccounts[i]] = false;
        }

        emit QuantumFluctuationTriggered(msg.sender, _quantumParameterA, _quantumParameterB);
    }

    /**
     * @dev Gets the current internal quantum parameters A and B.
     * These values fluctuate until the state is collapsed.
     */
    function getQuantumParameters() public view returns (uint256 parameterA, uint256 parameterB) {
        return (_quantumParameterA, _quantumParameterB);
    }

    /**
     * @dev Adds an address to the list of official observers.
     * Observers can attest to the state before collapse.
     * @param observer The address to add as an observer.
     */
    function addObserver(address observer) public onlyOwner {
        require(observer != address(0), "QV: Observer address cannot be zero");
        require(!_isObserverAccount[observer], "QV: Address is already an observer");
        _isObserverAccount[observer] = true;
        _observerAccounts.push(observer);
        // Reset attestation status for this observer if state is not collapsed
        if (!_isStateCollapsed) {
             _observerAttestedForCollapse[observer] = false;
        }
        emit ObserverAdded(observer);
    }

    /**
     * @dev Removes an address from the list of official observers.
     * @param observer The address to remove.
     */
    function removeObserver(address observer) public onlyOwner {
        require(observer != address(0), "QV: Observer address cannot be zero");
        require(_isObserverAccount[observer], "QV: Address is not an observer");
        delete _isObserverAccount[observer];
        // Remove from array (inefficient)
        for (uint i = 0; i < _observerAccounts.length; i++) {
            if (_observerAccounts[i] == observer) {
                _observerAccounts[i] = _observerAccounts[_observerAccounts.length - 1];
                _observerAccounts.pop();
                break;
            }
        }
         // If they had attested before collapse, decrement count and reset their attestation status
        if (!_isStateCollapsed && _observerAttestedForCollapse[observer]) {
            _observerAttestationCount--;
        }
        delete _observerAttestedForCollapse[observer];

        emit ObserverRemoved(observer);
    }

    /**
     * @dev Checks if an address is currently an official observer.
     */
    function isObserver(address potentialObserver) public view returns (bool) {
        return _isObserverAccount[potentialObserver];
    }

    /**
     * @dev Sets the minimum number of observer attestations required to collapse the state.
     * @param threshold The new required threshold.
     */
    function setObserverAttestationThreshold(uint256 threshold) public onlyOwner {
        _observerAttestationThreshold = threshold;
        // If current attestations exceed new lower threshold, don't decrement count, just update threshold
        // If current attestations are below new higher threshold, collapse will fail until more attestations are recorded.
        emit ObserverAttestationThresholdSet(threshold);
    }

    /**
     * @dev Records an attestation from an observer for the current quantum state.
     * Observers can only attest once per state before it is collapsed or fluctuates again.
     * Requires the state to NOT be collapsed.
     */
    function recordObserverAttestation() public {
        require(!_isStateCollapsed, "QV: State is already collapsed");
        require(_isObserverAccount[msg.sender], "QV: Only official observers can attest");
        require(!_observerAttestedForCollapse[msg.sender], "QV: Observer has already attested for this state");

        _observerAttestedForCollapse[msg.sender] = true;
        _observerAttestationCount++;

        emit ObserverAttestationRecorded(msg.sender, _observerAttestationCount);
    }

     /**
     * @dev Resets the observer attestation count and individual attestation statuses.
     * Can be called by the owner to restart the attestation process before collapse.
     */
    function resetObserverAttestations() public onlyOwner {
        _observerAttestationCount = 0;
        for(uint i = 0; i < _observerAccounts.length; i++){
             _observerAttestedForCollapse[_observerAccounts[i]] = false;
        }
        // No specific event, perhaps log as owner action if needed
    }


    /**
     * @dev Attempts to collapse the quantum state.
     * Can only be called by the owner.
     * Requires the observer attestation threshold to be met.
     * Fixes the quantum parameters into a single value and allows conditional operations.
     */
    function collapseQuantumState() public onlyOwner {
        require(!_isStateCollapsed, "QV: State is already collapsed");
        require(_observerAttestationCount >= _observerAttestationThreshold, "QV: Observer attestation threshold not met");

        _isStateCollapsed = true;
        // Calculate the fixed state value - combining parameters in a simple way
        _currentCollapsedStateValue = _quantumParameterA ^ _quantumParameterB; // Example calculation

        // Reset attestations as the state has changed (collapsed)
        _observerAttestationCount = 0;
         for(uint i = 0; i < _observerAccounts.length; i++){
             _observerAttestedForCollapse[_observerAccounts[i]] = false;
        }


        emit StateCollapsed(_currentCollapsedStateValue, block.timestamp);
    }

    /**
     * @dev Checks if the quantum state is currently collapsed.
     */
    function isStateCollapsed() public view returns (bool) {
        return _isStateCollapsed;
    }

    /**
     * @dev Gets the fixed value derived from the quantum parameters after collapse.
     * Returns 0 if the state is not currently collapsed.
     */
    function getCurrentCollapsedStateValue() public view returns (uint256) {
        return _currentCollapsedStateValue;
    }


    // --- Entanglement Management ---

    /**
     * @dev Adds an address to the list of entangled accounts.
     * Entangled accounts are required to approve conditional withdrawals.
     * @param account The address to add as entangled.
     */
    function addEntangledAccount(address account) public onlyOwner {
        require(account != address(0), "QV: Account address cannot be zero");
        require(!_isEntangledAccount[account], "QV: Address is already entangled");
        _isEntangledAccount[account] = true;
        _entangledAccounts.push(account);
        emit EntangledAccountAdded(account);
    }

    /**
     * @dev Removes an address from the list of entangled accounts.
     * @param account The address to remove.
     */
    function removeEntangledAccount(address account) public onlyOwner {
        require(account != address(0), "QV: Account address cannot be zero");
        require(_isEntangledAccount[account], "QV: Address is not entangled");
        delete _isEntangledAccount[account];
         // Remove from array (inefficient)
        for (uint i = 0; i < _entangledAccounts.length; i++) {
            if (_entangledAccounts[i] == account) {
                _entangledAccounts[i] = _entangledAccounts[_entangledAccounts.length - 1];
                _entangledAccounts.pop();
                break;
            }
        }
        emit EntangledAccountRemoved(account);
    }

     /**
     * @dev Checks if an address is currently an entangled account.
     */
    function isEntangled(address potentialAccount) public view returns (bool) {
        return _isEntangledAccount[potentialAccount];
    }

    /**
     * @dev Sets the minimum number of entangled account approvals required to execute a withdrawal request.
     * @param threshold The new required threshold.
     */
    function setEntanglementApprovalThreshold(uint256 threshold) public onlyOwner {
        _entanglementApprovalThreshold = threshold;
        emit EntanglementApprovalThresholdSet(threshold);
    }

     /**
     * @dev Gets the list of entangled account addresses.
     */
    function getEntangledAccounts() public view returns (address[]) {
        return _entangledAccounts;
    }


    // --- Withdrawal Request Workflow ---

    /**
     * @dev Requests to withdraw Ether from the vault.
     * Requires the quantum state to be collapsed and the vault not time-locked.
     * Initiates a request that needs entanglement approvals before execution.
     * @param amount The amount of Ether to withdraw.
     * @param recipient The address to send the Ether to.
     */
    function requestWithdrawalEther(uint256 amount, address payable recipient) public {
        require(_isStateCollapsed, "QV: State must be collapsed to request withdrawal");
        require(!isVaultLocked(), "QV: Vault is time-locked");
        require(amount > 0, "QV: Withdrawal amount must be greater than zero");
        require(address(this).balance >= amount, "QV: Insufficient Ether balance");
        require(recipient != address(0), "QV: Recipient cannot be zero address");

        uint256 requestId = _nextWithdrawalRequestId++;
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        req.initiator = msg.sender;
        req.recipient = recipient;
        req.tokenAddress = address(0); // Indicates Ether
        req.amount = amount;
        req.isEther = true;
        req.approvalCount = 0;
        req.isExecuted = false;
        req.isCancelled = false;

        emit WithdrawalRequested(requestId, msg.sender, recipient, address(0), amount, true);
    }

     /**
     * @dev Requests to withdraw a supported ERC20 token from the vault.
     * Requires the quantum state to be collapsed and the vault not time-locked.
     * Initiates a request that needs entanglement approvals before execution.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     * @param recipient The address to send the tokens to.
     */
    function requestWithdrawalERC20(address token, uint256 amount, address recipient) public {
        require(_isStateCollapsed, "QV: State must be collapsed to request withdrawal");
        require(!isVaultLocked(), "QV: Vault is time-locked");
        require(amount > 0, "QV: Withdrawal amount must be greater than zero");
        require(_isSupportedToken[token], "QV: Token is not supported for withdrawal");
        require(IERC20(token).balanceOf(address(this)) >= amount, "QV: Insufficient ERC20 balance");
        require(recipient != address(0), "QV: Recipient cannot be zero address");

        uint256 requestId = _nextWithdrawalRequestId++;
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        req.initiator = msg.sender;
        req.recipient = payable(recipient); // Cast for struct
        req.tokenAddress = token;
        req.amount = amount;
        req.isEther = false;
        req.approvalCount = 0;
        req.isExecuted = false;
        req.isCancelled = false;

        emit WithdrawalRequested(requestId, msg.sender, recipient, token, amount, false);
    }

    /**
     * @dev Records an approval from an entangled account for a specific withdrawal request.
     * An entangled account can only approve a given request once.
     * @param requestId The ID of the withdrawal request to approve.
     */
    function recordEntanglementApproval(uint256 requestId) public {
        require(_isEntangledAccount[msg.sender], "QV: Only entangled accounts can approve");
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        require(req.initiator != address(0), "QV: Invalid withdrawal request ID"); // Check if request exists
        require(!req.isExecuted, "QV: Request already executed");
        require(!req.isCancelled, "QV: Request already cancelled");
        require(!req.approvals[msg.sender], "QV: Account already approved this request");

        req.approvals[msg.sender] = true;
        req.approvalCount++;

        emit EntanglementApprovalRecorded(requestId, msg.sender, req.approvalCount);
    }

     /**
     * @dev Gets the status and details of a specific withdrawal request.
     * @param requestId The ID of the withdrawal request.
     */
    function getWithdrawalRequestStatus(uint256 requestId) public view returns (
        address initiator,
        address recipient,
        address token,
        uint256 amount,
        bool isEther,
        uint256 approvalCount,
        uint256 requiredApprovals,
        bool isExecuted,
        bool isCancelled
    ) {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        require(req.initiator != address(0), "QV: Invalid withdrawal request ID"); // Check if request exists

        return (
            req.initiator,
            req.recipient,
            req.tokenAddress,
            req.amount,
            req.isEther,
            req.approvalCount,
            _entanglementApprovalThreshold,
            req.isExecuted,
            req.isCancelled
        );
    }

    /**
     * @dev Executes a withdrawal request if the entanglement approval threshold is met.
     * Can be called by the request initiator or the owner.
     * @param requestId The ID of the withdrawal request to execute.
     */
    function executeWithdrawal(uint256 requestId) public {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        require(req.initiator != address(0), "QV: Invalid withdrawal request ID"); // Check if request exists
        require(msg.sender == req.initiator || msg.sender == _owner, "QV: Only initiator or owner can execute");
        require(!req.isExecuted, "QV: Request already executed");
        require(!req.isCancelled, "QV: Request already cancelled");
        require(req.approvalCount >= _entanglementApprovalThreshold, "QV: Entanglement approval threshold not met");
        // Check balance again in case it changed since request
        if (req.isEther) {
             require(address(this).balance >= req.amount, "QV: Insufficient Ether balance");
        } else {
             require(IERC20(req.tokenAddress).balanceOf(address(this)) >= req.amount, "QV: Insufficient ERC20 balance");
        }

        req.isExecuted = true;

        if (req.isEther) {
            // Use call for safer Ether transfer
            (bool success, ) = req.recipient.call{value: req.amount}("");
            require(success, "QV: Ether transfer failed");
        } else {
            require(IERC20(req.tokenAddress).transfer(req.recipient, req.amount), "QV: ERC20 transfer failed");
        }

        emit WithdrawalExecuted(requestId, req.recipient, req.tokenAddress, req.amount, req.isEther);
    }

    /**
     * @dev Cancels an open withdrawal request.
     * Can be called by the request initiator or the owner.
     * @param requestId The ID of the withdrawal request to cancel.
     */
    function cancelWithdrawalRequest(uint256 requestId) public {
        WithdrawalRequest storage req = _withdrawalRequests[requestId];
        require(req.initiator != address(0), "QV: Invalid withdrawal request ID"); // Check if request exists
        require(msg.sender == req.initiator || msg.sender == _owner, "QV: Only initiator or owner can cancel");
        require(!req.isExecuted, "QV: Request already executed");
        require(!req.isCancelled, "QV: Request already cancelled");

        req.isCancelled = true;

        emit WithdrawalCancelled(requestId, msg.sender);
    }

    /**
     * @dev Resets the entanglement approvals for a specific withdrawal request.
     * Can be called by the owner.
     * @param requestId The ID of the withdrawal request.
     */
    function resetEntanglementApprovals(uint256 requestId) public onlyOwner {
         WithdrawalRequest storage req = _withdrawalRequests[requestId];
        require(req.initiator != address(0), "QV: Invalid withdrawal request ID"); // Check if request exists
        require(!req.isExecuted, "QV: Request already executed");
        require(!req.isCancelled, "QV: Request already cancelled");

        req.approvalCount = 0;
        // Clear individual approvals - need to iterate through entangled accounts to reset map entries
        for (uint i = 0; i < _entangledAccounts.length; i++) {
            delete req.approvals[_entangledAccounts[i]];
        }
        // No specific event, could log as owner action
    }


    // --- Time Lock ---

    /**
     * @dev Locks the vault, preventing conditional withdrawals until a specific timestamp.
     * Can only be called by the owner.
     * Duration is added to the *current* lock end time if already locked, extending it.
     * @param duration The duration in seconds to lock the vault for.
     */
    function lockVaultTemporarily(uint40 duration) public onlyOwner {
        uint40 currentTime = uint40(block.timestamp);
        uint40 newLockEndTime;
        if (_lockEndTime > currentTime) {
            // If already locked, extend the lock
            newLockEndTime = _lockEndTime + duration;
            require(newLockEndTime > _lockEndTime, "QV: Lock end time overflow"); // Check for overflow
        } else {
            // If not locked or lock expired, set a new lock from now
             newLockEndTime = currentTime + duration;
             require(newLockEndTime > currentTime, "QV: Lock duration too short or overflow"); // Check duration > 0 and no overflow
        }
        _lockEndTime = newLockEndTime;
        emit VaultLocked(_lockEndTime);
    }

    /**
     * @dev Unlocks the vault if the time lock period has expired.
     * Can only be called by the owner.
     */
    function unlockVault() public onlyOwner {
        require(block.timestamp >= _lockEndTime, "QV: Time lock has not expired yet");
        _lockEndTime = 0; // Setting to 0 indicates unlocked state
        emit VaultUnlocked();
    }

    /**
     * @dev Checks if the vault is currently time-locked.
     */
    function isVaultLocked() public view returns (bool) {
        return block.timestamp < _lockEndTime;
    }

    // --- Emergency Operations ---

    /**
     * @dev Allows the owner to withdraw Ether immediately in emergencies.
     * Bypasses quantum state, entanglement, and time lock rules. Use with extreme caution.
     * @param amount The amount of Ether to withdraw.
     * @param recipient The address to send the Ether to.
     */
    function emergencyWithdrawEther(uint256 amount, address payable recipient) public onlyOwner {
        require(amount > 0, "QV: Emergency withdrawal amount must be greater than zero");
        require(address(this).balance >= amount, "QV: Insufficient Ether balance for emergency withdrawal");
        require(recipient != address(0), "QV: Recipient cannot be zero address");

         (bool success, ) = recipient.call{value: amount}("");
         require(success, "QV: Emergency Ether transfer failed");

        emit EmergencyWithdrawal(address(0), recipient, amount, true);
    }

    /**
     * @dev Allows the owner to withdraw supported ERC20 tokens immediately in emergencies.
     * Bypasses quantum state, entanglement, and time lock rules. Use with extreme caution.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     * @param recipient The address to send the tokens to.
     */
    function emergencyWithdrawERC20(address token, uint256 amount, address recipient) public onlyOwner {
         require(amount > 0, "QV: Emergency withdrawal amount must be greater than zero");
         require(_isSupportedToken[token], "QV: Token is not supported for emergency withdrawal"); // Only supported tokens
         require(IERC20(token).balanceOf(address(this)) >= amount, "QV: Insufficient ERC20 balance for emergency withdrawal");
         require(recipient != address(0), "QV: Recipient cannot be zero address");

         require(IERC20(token).transfer(recipient, amount), "QV: Emergency ERC20 transfer failed");

        emit EmergencyWithdrawal(token, recipient, amount, false);
    }


    // --- Getter Functions ---

    /**
     * @dev Gets the current Ether balance held by the vault contract.
     */
    function getVaultEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the current balance of a specific ERC20 token held by the vault contract.
     * @param token The address of the ERC20 token.
     */
    function getVaultERC20Balance(address token) public view returns (uint256) {
         require(token != address(0), "QV: Token address cannot be zero");
        return IERC20(token).balanceOf(address(this));
    }

     /**
     * @dev Gets the list of official observer addresses.
     */
    function getObservers() public view returns (address[]) {
        return _observerAccounts;
    }

    // Note: getEntangledAccounts() and getSupportedERC20s() are already above (functions 37 & 6)
}
```