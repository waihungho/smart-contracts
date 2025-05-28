Okay, here is a Solidity smart contract concept called `QuantumVault`. It's designed to hold both ERC-20 tokens and ERC-721 NFTs under complex, multi-faceted release conditions ("Quantum Conditions") that can involve time, external data (simulated via oracle interface), on-chain state checks, and even a simple cryptographic challenge proof. It incorporates multi-asset handling, conditional logic, role-based access (via Ownable + potentially internal logic), and state management.

It aims for over 20 functions by including specific deposit/withdrawal for each asset type, functions for managing conditions, submitting different types of "proofs", transitioning states, querying data, and standard administrative functions.

**Disclaimer:** This contract is for *educational and conceptual purposes*. Deploying such a contract on a mainnet would require extensive security audits, gas optimizations, and robust error handling far beyond this example. The "Oracle" and "State Proof" parts are simplified interfaces and require real implementations. The "Challenge Proof" is a basic hash pre-image concept.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Allows contract to receive ERC721
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice, though unchecked is common in 0.8+

// --- OUTLINE AND FUNCTION SUMMARY ---
/*
Contract Name: QuantumVault

Description:
The QuantumVault is a complex, multi-asset vault designed to hold ERC-20 tokens and ERC-721 NFTs.
Assets deposited into the vault are locked until a set of pre-defined "Quantum Conditions" are met.
These conditions can be a combination of:
1.  Time-based unlock.
2.  External data validation (via a simulated Oracle).
3.  On-chain state validation (checking a value in another contract).
4.  Submission of a correct cryptographic proof (hash pre-image challenge).

The vault operates through different states (Locked, ConditionMet, ChallengePeriod, Unlocked, Claimed),
transitioning based on condition checks and proof submissions.

It features extensive functions for:
- Asset deposit (ERC-20 and ERC-721).
- Defining, updating, and querying complex unlock conditions.
- Submitting various types of proofs to meet conditions.
- Managing the vault's state transitions.
- Claiming assets once unlocked.
- Querying vault status and deposited assets.
- Administrative controls (pausing, emergency withdrawal, allowed tokens).

Key Concepts:
- Multi-asset handling (ERC-20, ERC-721).
- State machine for vault lifecycle.
- Configurable, multi-factor unlock conditions.
- Simulation of external interactions (Oracle, State Check).
- Basic cryptographic challenge (hash pre-image).
- Role-based access (Ownable).

---

Function Summary:

// State & Configuration
1.  constructor(address initialOracleAddress, uint256 maxChallengeDurationInSeconds, bytes32 initialChallengeHash): Initializes owner, oracle, challenge parameters.
2.  getCurrentVaultState(): View the current state of the vault.
3.  getVaultConfig(): View main configuration parameters (oracle, challenge settings).
4.  setOracleAddress(address newOracle): Admin function to update the oracle address.
5.  setMaxChallengeDuration(uint256 duration): Admin function to set the challenge period duration.
6.  setAllowedERC20(address token, bool allowed): Admin function to whitelist/blacklist ERC20 tokens.
7.  setAllowedERC721(address token, bool allowed): Admin function to whitelist/blacklist ERC721 tokens.
8.  isERC20Allowed(address token): View if an ERC20 token is allowed.
9.  isERC721Allowed(address token): View if an ERC721 token is allowed.

// Deposit Functions
10. depositERC20(address tokenAddress, uint256 amount): Deposit specified amount of an allowed ERC20 token.
11. depositERC721(address tokenAddress, uint256 tokenId): Deposit a specific allowed ERC721 NFT.

// Condition Management
12. setVaultConditions(VaultConditions memory conditions): Admin function to define the unlock conditions.
13. updateVaultConditions(VaultConditions memory newConditions): Admin function to modify existing conditions (limited scope).
14. getVaultConditions(): View the currently set unlock conditions.
15. checkConditionsMet(): Internal helper to evaluate if all conditions (except proof) are satisfied.

// Proof Submission & State Transition
16. submitOracleProof(bytes memory oracleData): Submit data from an Oracle to potentially satisfy an oracle condition.
17. submitStateProof(address contractAddress, bytes memory callData, bytes memory expectedResult): Submit data to check a state condition in another contract.
18. submitChallengeProof(bytes32 preImage): Submit the pre-image for the hash challenge condition.
19. transitionToChallengePeriod(): Admin or condition-checker can propose transitioning to the challenge period if time/oracle/state conditions are met.
20. verifyChallengeProofAttempt(bytes32 preImage): Check if a submitted challenge proof is correct against the stored hash.
21. transitionToUnlocked(): Admin or condition-checker can transition to Unlocked state if all conditions AND proofs are met.

// Withdrawal/Claim Functions
22. claimERC20(address tokenAddress): Withdraw claimed ERC20 tokens once vault is Unlocked.
23. claimERC721(address tokenAddress, uint256 tokenId): Withdraw a claimed ERC721 NFT once vault is Unlocked.
24. emergencyWithdrawERC20(address tokenAddress): Owner-only function to withdraw ERC20 in emergencies while Paused.
25. emergencyWithdrawERC721(address tokenAddress, uint256 tokenId): Owner-only function to withdraw a specific ERC721 in emergencies while Paused.

// Query User/Vault Balances & Assets
26. getERC20BalanceInVault(address depositor, address tokenAddress): View a user's deposited balance for a specific ERC20.
27. getERC721TokensInVault(address depositor, address tokenAddress): View the list of token IDs a user has deposited for a specific ERC721.
28. getAllERC20Depositors(): View list of all addresses who have deposited *any* ERC20.
29. getAllERC721Depositors(): View list of all addresses who have deposited *any* ERC721.

// Administrative & Utility
30. pause(): Owner-only function to pause transfers and state changes.
31. unpause(): Owner-only function to unpause the contract.
32. transferOwnership(address newOwner): Standard Ownable function.
33. renounceOwnership(): Standard Ownable function.
34. getChallengeProofHash(): View the hash required for the challenge proof.

---
*/

// Mock Interface for Oracle - In a real scenario, this would be a trusted Oracle contract
interface IOracle {
    function getData(bytes memory query) external view returns (bytes memory);
}

// Mock Interface for State Check - In a real scenario, call a specific view function
interface IStateChecker {
    function checkState(bytes memory callData) external view returns (bytes memory);
}


contract QuantumVault is Ownable, ReentrancyGuard, Pausable, ERC721Holder { // ERC721Holder enables receiving NFTs
    using SafeMath for uint256;
    using Address for address;

    enum VaultState {
        Locked,          // Assets are held, conditions not met
        ConditionMet,    // Non-proof conditions (Time, Oracle, State) are met
        ChallengePeriod, // Challenge proof is required and period is active
        Unlocked,        // All conditions, including proof, are met
        Claimed          // Assets have been fully claimed
    }

    struct VaultConfig {
        address oracleAddress;
        uint256 maxChallengeDurationInSeconds;
        bytes32 challengeProofHash; // Hash required for the challenge condition
    }

    struct VaultConditions {
        uint256 unlockTimestamp; // 0 means no time condition
        bool requireOracleProof;
        bytes oracleProofQuery;  // Data to query the oracle with
        bool requireStateProof;
        address stateCheckContract; // Contract to call for state proof
        bytes stateCheckCallData; // Data/selector for the state check call
        bytes stateCheckExpectedResult; // Expected result of the state check call
        bool requireChallengeProof; // Requires submitting the pre-image of challengeProofHash
    }

    // --- State Variables ---
    VaultState public currentVaultState;
    VaultConfig public vaultConfig;
    VaultConditions public vaultConditions;

    // Track deposited assets per user
    mapping(address => mapping(address => uint256)) private userERC20Balances; // user => token address => amount
    mapping(address => mapping(address => uint256[])) private userERC721Tokens; // user => token address => token IDs

    // Track overall vault holdings (redundant with user balances, but useful for total supply/admin view)
    mapping(address => uint255) private totalERC20Holdings; // token address => amount
    mapping(address => uint256[]) private totalERC721Holdings; // token address => token IDs

    // Track which conditions have been met (excluding state, which is re-checked)
    bool private oracleProofSubmitted;
    bool private challengeProofSubmitted;
    uint256 private challengePeriodStartTime;

    // List of allowed tokens
    mapping(address => bool) private allowedERC20;
    mapping(address => bool) private allowedERC721;

    // Keep track of depositors (can be inefficient for many users, consider alternatives for large scale)
    address[] private erc20Depositors;
    address[] private erc721Depositors;
    mapping(address => bool) private isERC20Depositor;
    mapping(address => bool) private isERC721Depositor;


    // --- Events ---
    event DepositERC20(address indexed depositor, address indexed token, uint256 amount);
    event DepositERC721(address indexed depositor, address indexed token, uint256 tokenId);
    event ConditionsSet(VaultConditions conditions);
    event ConditionsUpdated(VaultConditions newConditions);
    event OracleProofSubmitted(address indexed submitter, bytes data);
    event StateProofSubmitted(address indexed submitter, address indexed contractAddress, bytes callData, bytes expectedResult);
    event ChallengeProofSubmitted(address indexed submitter);
    event VaultStateChanged(VaultState oldState, VaultState newState);
    event ClaimERC20(address indexed claimant, address indexed token, uint256 amount);
    event ClaimERC721(address indexed claimant, address indexed token, uint256 tokenId);
    event EmergencyWithdrawERC20(address indexed owner, address indexed token, uint256 amount);
    event EmergencyWithdrawERC721(address indexed owner, address indexed token, uint256 tokenId);
    event TokenAllowed(address indexed token, bool allowed, bool isERC20);

    // --- Modifiers ---
    modifier whenState(VaultState _state) {
        require(currentVaultState == _state, "QuantumVault: Invalid state");
        _;
    }

    modifier notClaimed() {
        require(currentVaultState != VaultState.Claimed, "QuantumVault: Assets already claimed");
        _;
    }

    // --- Constructor ---
    /// @notice Initializes the Quantum Vault with required parameters.
    /// @param initialOracleAddress Address of the trusted Oracle contract.
    /// @param maxChallengeDurationInSeconds Maximum duration allowed for submitting the challenge proof.
    /// @param initialChallengeHash The keccak256 hash for the challenge proof (users submit the pre-image).
    constructor(address initialOracleAddress, uint256 maxChallengeDurationInSeconds, bytes32 initialChallengeHash) Ownable(msg.sender) Pausable() {
        vaultConfig = VaultConfig({
            oracleAddress: initialOracleAddress,
            maxChallengeDurationInSeconds: maxChallengeDurationInSeconds,
            challengeProofHash: initialChallengeHash
        });
        currentVaultState = VaultState.Locked;

        // Initialize conditions to a default 'impossible' or 'not set' state if needed, or rely on setVaultConditions.
        // Let's assume conditions must be explicitly set later.
        vaultConditions.unlockTimestamp = 0; // No time condition initially
        vaultConditions.requireOracleProof = false;
        vaultConditions.requireStateProof = false;
        vaultConditions.requireChallengeProof = false;
    }

    // --- State & Configuration Functions ---

    /// @notice View the current state of the vault.
    /// @return The current VaultState enum value.
    function getCurrentVaultState() public view returns (VaultState) {
        return currentVaultState;
    }

    /// @notice View the main configuration parameters of the vault.
    /// @return vaultConfig struct.
    function getVaultConfig() public view returns (VaultConfig memory) {
        return vaultConfig;
    }

    /// @notice Admin function to update the trusted Oracle contract address.
    /// @param newOracle The address of the new Oracle contract.
    function setOracleAddress(address newOracle) public onlyOwner {
        vaultConfig.oracleAddress = newOracle;
        // Consider implications if conditions are already set using the old oracle.
    }

    /// @notice Admin function to set the maximum duration for the challenge proof submission period.
    /// @param duration The duration in seconds.
    function setMaxChallengeDuration(uint256 duration) public onlyOwner {
        vaultConfig.maxChallengeDurationInSeconds = duration;
    }

    /// @notice Admin function to whitelist or blacklist an ERC20 token for deposits/withdrawals.
    /// @param token The address of the ERC20 token.
    /// @param allowed Whether the token is allowed (true) or disallowed (false).
    function setAllowedERC20(address token, bool allowed) public onlyOwner {
        allowedERC20[token] = allowed;
        emit TokenAllowed(token, allowed, true);
    }

    /// @notice Admin function to whitelist or blacklist an ERC721 token for deposits/withdrawals.
    /// @param token The address of the ERC721 token.
    /// @param allowed Whether the token is allowed (true) or disallowed (false).
    function setAllowedERC721(address token, bool allowed) public onlyOwner {
        allowedERC721[token] = allowed;
        emit TokenAllowed(token, allowed, false);
    }

    /// @notice View if a specific ERC20 token address is currently allowed for use with the vault.
    /// @param token The address of the ERC20 token.
    /// @return True if allowed, false otherwise.
    function isERC20Allowed(address token) public view returns (bool) {
        return allowedERC20[token];
    }

    /// @notice View if a specific ERC721 token address is currently allowed for use with the vault.
    /// @param token The address of the ERC721 token.
    /// @return True if allowed, false otherwise.
    function isERC721Allowed(address token) public view returns (bool) {
        return allowedERC721[token];
    }

    // --- Deposit Functions ---

    /// @notice Deposits a specified amount of an allowed ERC20 token into the vault.
    /// @dev Requires the user to have approved the vault contract to spend the tokens.
    /// @param tokenAddress The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address tokenAddress, uint256 amount) public payable nonReentrant whenNotPaused whenState(VaultState.Locked) {
        require(amount > 0, "QuantumVault: Deposit amount must be greater than 0");
        require(isERC20Allowed(tokenAddress), "QuantumVault: ERC20 token is not allowed");

        IERC20 token = IERC20(tokenAddress);

        // Add depositor to the list if new
        if (!isERC20Depositor[msg.sender]) {
            erc20Depositors.push(msg.sender);
            isERC20Depositor[msg.sender] = true;
        }

        // Update user balance mapping
        userERC20Balances[msg.sender][tokenAddress] = userERC20Balances[msg.sender][tokenAddress].add(amount);
        // Update total vault holdings
        totalERC20Holdings[tokenAddress] = totalERC20Holdings[tokenAddress].add(amount);

        // Transfer tokens from the user to the vault
        token.transferFrom(msg.sender, address(this), amount);

        emit DepositERC20(msg.sender, tokenAddress, amount);
    }

    /// @notice Deposits a specific allowed ERC721 NFT into the vault.
    /// @dev Requires the user to have approved the vault contract to transfer the NFT or setApprovalForAll.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the NFT to deposit.
    function depositERC721(address tokenAddress, uint256 tokenId) public payable nonReentrant whenNotPaused whenState(VaultState.Locked) {
        require(isERC721Allowed(tokenAddress), "QuantumVault: ERC721 token is not allowed");

        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == msg.sender, "QuantumVault: Not the owner of the token");

         // Add depositor to the list if new
        if (!isERC721Depositor[msg.sender]) {
            erc721Depositors.push(msg.sender);
            isERC721Depositor[msg.sender] = true;
        }

        // Add token ID to user's list
        userERC721Tokens[msg.sender][tokenAddress].push(tokenId);
         // Add token ID to total vault list
        totalERC721Holdings[tokenAddress].push(tokenId);


        // Transfer NFT to the vault
        token.safeTransferFrom(msg.sender, address(this), tokenId);

        emit DepositERC721(msg.sender, tokenAddress, tokenId);
    }

    // --- Condition Management Functions ---

    /// @notice Admin function to define the specific "Quantum Conditions" required to unlock the vault.
    /// @dev Can only be set when the vault is Locked. Overwrites previous conditions.
    /// @param conditions The struct containing all the unlock conditions.
    function setVaultConditions(VaultConditions memory conditions) public onlyOwner whenState(VaultState.Locked) {
        vaultConditions = conditions;
        oracleProofSubmitted = false; // Reset proofs when conditions change
        challengeProofSubmitted = false; // Reset proofs when conditions change
        challengePeriodStartTime = 0; // Reset challenge period start time

        // Basic validation for conditions
        if (conditions.requireOracleProof) {
             require(vaultConfig.oracleAddress != address(0), "QuantumVault: Oracle address not set for oracle condition");
             require(conditions.oracleProofQuery.length > 0, "QuantumVault: Oracle query data cannot be empty if required");
        }
        if (conditions.requireStateProof) {
             require(conditions.stateCheckContract != address(0), "QuantumVault: State check contract address not set");
             require(conditions.stateCheckCallData.length > 0, "QuantumVault: State check call data cannot be empty");
             require(conditions.stateCheckExpectedResult.length > 0, "QuantumVault: State check expected result cannot be empty");
        }
         if (conditions.requireChallengeProof) {
             require(vaultConfig.challengeProofHash != bytes32(0), "QuantumVault: Challenge hash not set for challenge condition");
        }

        emit ConditionsSet(conditions);
    }

    /// @notice Admin function to update specific fields in the existing vault conditions.
    /// @dev Allows modification without completely resetting proofs. Use with caution.
    ///      Only allowed in Locked or ConditionMet states.
    /// @param newConditions The struct containing the *new* values for conditions.
    function updateVaultConditions(VaultConditions memory newConditions) public onlyOwner whenNotPaused {
        require(currentVaultState == VaultState.Locked || currentVaultState == VaultState.ConditionMet, "QuantumVault: Can only update conditions when Locked or ConditionMet");

        // Selective update - define which fields can be updated
        vaultConditions.unlockTimestamp = newConditions.unlockTimestamp;
        vaultConditions.requireOracleProof = newConditions.requireOracleProof;
        vaultConditions.oracleProofQuery = newConditions.oracleProofQuery;
        vaultConditions.requireStateProof = newConditions.requireStateProof;
        vaultConditions.stateCheckContract = newConditions.stateCheckContract;
        vaultConditions.stateCheckCallData = newConditions.stateCheckCallData;
        vaultConditions.stateCheckExpectedResult = newConditions.stateCheckExpectedResult;
        vaultConditions.requireChallengeProof = newConditions.requireChallengeProof;

        // Re-evaluate state or require re-submission of proofs if conditions change significantly?
        // For this example, simply updating the conditions is enough. A real contract might be more complex.

        emit ConditionsUpdated(vaultConditions);
    }


    /// @notice View the currently set unlock conditions for the vault.
    /// @return The VaultConditions struct.
    function getVaultConditions() public view returns (VaultConditions memory) {
        return vaultConditions;
    }

    /// @notice Internal helper function to check if non-proof conditions (Time, Oracle, State) are met.
    /// @dev This function does NOT check the challenge proof condition or the vault state.
    /// @return True if conditions are met, false otherwise.
    function checkConditionsMet() public view returns (bool) {
        bool timeConditionMet = (vaultConditions.unlockTimestamp == 0 || block.timestamp >= vaultConditions.unlockTimestamp);
        bool oracleConditionMet = (!vaultConditions.requireOracleProof || oracleProofSubmitted); // Assumes oracleProofSubmitted means it was verified successfully
        bool stateConditionMet = true; // Assume true initially, check only if required

        if (vaultConditions.requireStateProof) {
            // Simulate calling another contract and checking the result
            (bool success, bytes memory result) = vaultConditions.stateCheckContract.staticcall(vaultConditions.stateCheckCallData);
            stateConditionMet = success && (result == vaultConditions.stateCheckExpectedResult);
             // Note: In a real scenario, the oracle/state check logic would be more complex and potentially involve gas costs.
        }

        return timeConditionMet && oracleConditionMet && stateConditionMet;
    }

    // --- Proof Submission & State Transition Functions ---

    /// @notice Submit data from an Oracle to potentially satisfy the oracle condition.
    /// @dev Can only be submitted in Locked or ConditionMet states.
    ///      This is a simplified example; a real oracle interaction would verify signatures or proof structure.
    /// @param oracleData The data received from the oracle.
    function submitOracleProof(bytes memory oracleData) public whenNotPaused nonReentrant {
         require(currentVaultState == VaultState.Locked || currentVaultState == VaultState.ConditionMet, "QuantumVault: Can only submit oracle proof in Locked or ConditionMet states");
         require(vaultConditions.requireOracleProof, "QuantumVault: Oracle proof is not required");
         require(vaultConfig.oracleAddress != address(0), "QuantumVault: Oracle address not set");

         // --- SIMULATION ---
         // In a real contract, you'd verify the oracle's signature or the data structure.
         // Here, we just check if *any* data was provided if required, and then potentially call the oracle contract.
         // Let's add a simple call simulation.
         (bool success, bytes memory result) = vaultConfig.oracleAddress.staticcall(vaultConditions.oracleProofQuery);
         require(success, "QuantumVault: Oracle call failed");

         // Add logic here to compare 'result' with some expected value or structure based on oracleData.
         // For simplicity, this example assumes successful call & data submission counts as proof.
         // A real oracle contract would have a specific function to verify proofs on-chain.
         // e.g., `require(IOracle(vaultConfig.oracleAddress).verifyProof(oracleData, vaultConditions.oracleProofQuery), "QuantumVault: Oracle proof verification failed");`

         oracleProofSubmitted = true;

        emit OracleProofSubmitted(msg.sender, oracleData);

        // Check if conditions are met and transition state if appropriate
        if (currentVaultState == VaultState.Locked && checkConditionsMet()) {
             // If Time, Oracle, and State conditions are now met, transition to ConditionMet
             _changeState(VaultState.ConditionMet);
         }
    }

    /// @notice Submit data to check a state condition in another contract.
    /// @dev Calls the target contract with provided call data and checks if the result matches the expected result.
    ///      Can only be submitted in Locked or ConditionMet states.
    /// @param contractAddress The address of the contract to check.
    /// @param callData The bytes data for the function call (including function selector and arguments).
    /// @param expectedResult The expected bytes result of the call.
    function submitStateProof(address contractAddress, bytes memory callData, bytes memory expectedResult) public whenNotPaused nonReentrant {
         require(currentVaultState == VaultState.Locked || currentVaultState == VaultState.ConditionMet, "QuantumVault: Can only submit state proof in Locked or ConditionMet states");
         require(vaultConditions.requireStateProof, "QuantumVault: State proof is not required");
         require(vaultConditions.stateCheckContract == contractAddress, "QuantumVault: Incorrect state check contract address");
         require(vaultConditions.stateCheckCallData == callData, "QuantumVault: Incorrect state check call data");
         require(vaultConditions.stateCheckExpectedResult == expectedResult, "QuantumVault: Incorrect state check expected result");


         // Re-check the condition directly (since it's re-evaluated every time)
         (bool success, bytes memory result) = contractAddress.staticcall(callData);
         require(success, "QuantumVault: State check call failed");
         require(result == expectedResult, "QuantumVault: State check result mismatch");

         emit StateProofSubmitted(msg.sender, contractAddress, callData, expectedResult);

         // Check if conditions are met and transition state if appropriate
         if (currentVaultState == VaultState.Locked && checkConditionsMet()) {
             // If Time, Oracle, and State conditions are now met, transition to ConditionMet
             _changeState(VaultState.ConditionMet);
         }
    }


    /// @notice Submit the pre-image of the challenge hash to satisfy the challenge condition.
    /// @dev Can only be submitted during the ChallengePeriod.
    /// @param preImage The bytes32 value that hashes to the stored challengeProofHash.
    function submitChallengeProof(bytes32 preImage) public whenNotPaused nonReentrant whenState(VaultState.ChallengePeriod) {
        require(vaultConditions.requireChallengeProof, "QuantumVault: Challenge proof is not required");
        require(block.timestamp <= challengePeriodStartTime.add(vaultConfig.maxChallengeDurationInSeconds), "QuantumVault: Challenge period has expired");

        bytes32 computedHash = keccak256(abi.encodePacked(preImage));
        require(computedHash == vaultConfig.challengeProofHash, "QuantumVault: Incorrect challenge proof");

        challengeProofSubmitted = true;

        emit ChallengeProofSubmitted(msg.sender);

        // Check if all conditions and proofs are met and transition state
        _tryTransitionToUnlocked();
    }

     /// @notice Allows anyone to check if a potential challenge proof (pre-image) is correct against the stored hash.
     /// @dev Does not change state or mark the proof as submitted. Useful for off-chain or pre-submission checks.
     /// @param preImage The bytes32 value to test.
     /// @return True if the pre-image hashes to the correct challenge hash, false otherwise.
    function verifyChallengeProofAttempt(bytes32 preImage) public view returns (bool) {
         if (!vaultConditions.requireChallengeProof || vaultConfig.challengeProofHash == bytes32(0)) {
             return false; // No challenge required or hash not set
         }
         bytes32 computedHash = keccak256(abi.encodePacked(preImage));
         return computedHash == vaultConfig.challengeProofHash;
    }


    /// @notice Allows the owner or anyone (if conditions allow) to propose transitioning to the ChallengePeriod.
    /// @dev This happens after the Time, Oracle, and State conditions are met.
    /// @dev Only transitions if the vault is in the ConditionMet state.
    function transitionToChallengePeriod() public whenNotPaused nonReentrant whenState(VaultState.ConditionMet) {
        require(vaultConditions.requireChallengeProof, "QuantumVault: Challenge proof is not required, skipping ChallengePeriod");
        require(checkConditionsMet(), "QuantumVault: Non-proof conditions are not met");

        challengePeriodStartTime = block.timestamp;
        _changeState(VaultState.ChallengePeriod);
    }

    /// @notice Internal helper to attempt transitioning to the Unlocked state.
    /// @dev Checks if all required conditions and proofs are met.
    function _tryTransitionToUnlocked() internal {
        // Check Time, Oracle, State conditions (re-evaluates State proof)
        if (!checkConditionsMet()) {
            return; // Conditions not met
        }

        // Check Challenge Proof condition if required
        bool challengeConditionMet = (!vaultConditions.requireChallengeProof || challengeProofSubmitted);
        if (vaultConditions.requireChallengeProof && !challengeProofSubmitted) {
             // If challenge required, must also be within the allowed time frame
             require(block.timestamp <= challengePeriodStartTime.add(vaultConfig.maxChallengeDurationInSeconds), "QuantumVault: Challenge period has expired");
        }


        if (challengeConditionMet) {
            _changeState(VaultState.Unlocked);
        }
    }

    /// @notice Allows the owner or anyone (if conditions allow) to transition the vault to the Unlocked state.
    /// @dev Can be called from ConditionMet (if no challenge required) or ChallengePeriod states.
    function transitionToUnlocked() public whenNotPaused nonReentrant {
        require(currentVaultState == VaultState.ConditionMet || currentVaultState == VaultState.ChallengePeriod, "QuantumVault: Can only transition from ConditionMet or ChallengePeriod");

        // If in ConditionMet and challenge is NOT required, transition directly.
        if (currentVaultState == VaultState.ConditionMet && !vaultConditions.requireChallengeProof) {
             _tryTransitionToUnlocked(); // This will change state if conditions met
             require(currentVaultState == VaultState.Unlocked, "QuantumVault: Non-proof conditions not met for unlock");
             return;
        }

         // If in ChallengePeriod, attempt unlock only if challenge proof is met (checked in _tryTransitionToUnlocked)
         if (currentVaultState == VaultState.ChallengePeriod) {
             _tryTransitionToUnlocked(); // This will change state if all conditions and proofs met
             require(currentVaultState == VaultState.Unlocked, "QuantumVault: Conditions or Challenge Proof not met for unlock");
         }
    }

    /// @dev Internal function to manage state transitions and emit events.
    function _changeState(VaultState newState) internal {
        emit VaultStateChanged(currentVaultState, newState);
        currentVaultState = newState;
    }

    // --- Withdrawal/Claim Functions ---

    /// @notice Allows a depositor to claim their deposited ERC20 tokens once the vault is Unlocked.
    /// @param tokenAddress The address of the ERC20 token to claim.
    function claimERC20(address tokenAddress) public nonReentrant whenNotPaused whenState(VaultState.Unlocked) notClaimed {
        uint256 amount = userERC20Balances[msg.sender][tokenAddress];
        require(amount > 0, "QuantumVault: No ERC20 balance to claim for this token");
        require(isERC20Allowed(tokenAddress), "QuantumVault: ERC20 token is not allowed for withdrawal"); // Should be allowed if deposited

        // Clear user balance
        userERC20Balances[msg.sender][tokenAddress] = 0;

        // Update total vault holdings (less efficient, but required for accuracy)
        // Better approach: track claims and reduce total, or recalculate total from user balances
        // For simplicity, let's just assume tokens are successfully sent from the vault's total.
        // A more robust implementation would need careful accounting here.

        // Transfer tokens to the user
        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit ClaimERC20(msg.sender, tokenAddress, amount);

        // Consider transitioning to Claimed state if all assets are withdrawn by all users.
        // This is complex to track, so we'll leave the state as Unlocked until owner manually claims leftovers or transitions.
    }

    /// @notice Allows a depositor to claim their deposited ERC721 NFT once the vault is Unlocked.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the NFT to claim.
    function claimERC721(address tokenAddress, uint256 tokenId) public nonReentrant whenNotPaused whenState(VaultState.Unlocked) notClaimed {
        // Check if the user deposited this specific token ID
        bool found = false;
        uint256 index = 0;
        uint256[] storage tokenIds = userERC721Tokens[msg.sender][tokenAddress];

        for (uint i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                found = true;
                index = i;
                break;
            }
        }
        require(found, "QuantumVault: You did not deposit this ERC721 token ID");
        require(isERC721Allowed(tokenAddress), "QuantumVault: ERC721 token is not allowed for withdrawal"); // Should be allowed if deposited

        // Remove the token ID from the user's list
        tokenIds[index] = tokenIds[tokenIds.length - 1];
        tokenIds.pop();

         // Remove the token ID from total vault list (also less efficient)
         // Similar note as ERC20 claiming - need careful accounting or recalculation
         uint256[] storage totalTokenIds = totalERC721Holdings[tokenAddress];
         for (uint i = 0; i < totalTokenIds.length; i++) {
             if (totalTokenIds[i] == tokenId) {
                 totalTokenIds[i] = totalTokenIds[totalTokenIds.length - 1];
                 totalTokenIds.pop();
                 break;
             }
         }


        // Transfer NFT to the user
        IERC721(tokenAddress).safeTransferFrom(address(this), msg.sender, tokenId);

        emit ClaimERC721(msg.sender, tokenAddress, tokenId);
    }

    /// @notice Owner-only function to withdraw specific ERC20 tokens in an emergency while the contract is Paused.
    /// @dev Useful if conditions cannot be met or contract gets stuck.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    function emergencyWithdrawERC20(address tokenAddress) public onlyOwner whenPaused nonReentrant {
        uint256 balance = totalERC20Holdings[tokenAddress]; // Withdraw total held by the vault for this token
        require(balance > 0, "QuantumVault: No ERC20 balance of this token in vault");

        // Clear total balance for this token
        totalERC20Holdings[tokenAddress] = 0;
        // Note: This doesn't clear individual user balances. A full emergency withdrawal should clear mappings.
        // For simplicity here, we only clear the total. A real one needs more logic.

        IERC20(tokenAddress).transfer(owner(), balance);

        emit EmergencyWithdrawERC20(owner(), tokenAddress, balance);

        // After emergency withdrawal, consider changing state or deleting conditions.
    }

    /// @notice Owner-only function to withdraw a specific ERC721 NFT in an emergency while the contract is Paused.
    /// @dev Useful if conditions cannot be met or contract gets stuck.
    /// @param tokenAddress The address of the ERC721 token.
    /// @param tokenId The ID of the NFT to withdraw.
    function emergencyWithdrawERC721(address tokenAddress, uint256 tokenId) public onlyOwner whenPaused nonReentrant {
         IERC721 token = IERC721(tokenAddress);
         require(token.ownerOf(tokenId) == address(this), "QuantumVault: Vault does not own this NFT");

         // Remove the token ID from total vault list (less efficient)
         uint256[] storage totalTokenIds = totalERC721Holdings[tokenAddress];
         bool found = false;
         for (uint i = 0; i < totalTokenIds.length; i++) {
             if (totalTokenIds[i] == tokenId) {
                 totalTokenIds[i] = totalTokenIds[totalTokenIds.length - 1];
                 totalTokenIds.pop();
                 found = true;
                 break;
             }
         }
         require(found, "QuantumVault: NFT not tracked in total holdings"); // Should match owner check, but good double check

         // Note: This doesn't clear the NFT from individual user balances if it was deposited by them.
         // A full emergency withdrawal should clear mappings. For simplicity, we only clear from total.

         token.safeTransferFrom(address(this), owner(), tokenId);

         emit EmergencyWithdrawERC721(owner(), tokenAddress, tokenId);

         // After emergency withdrawal, consider changing state or deleting conditions.
    }


    // --- Query User/Vault Balances & Assets Functions ---

    /// @notice View the amount of a specific ERC20 token a user has deposited in this vault.
    /// @param depositor The address of the user.
    /// @param tokenAddress The address of the ERC20 token.
    /// @return The balance amount.
    function getERC20BalanceInVault(address depositor, address tokenAddress) public view returns (uint256) {
        return userERC20Balances[depositor][tokenAddress];
    }

    /// @notice View the list of ERC721 token IDs a user has deposited for a specific token address.
    /// @param depositor The address of the user.
    /// @param tokenAddress The address of the ERC721 token contract.
    /// @return An array of token IDs.
    function getERC721TokensInVault(address depositor, address tokenAddress) public view returns (uint256[] memory) {
        return userERC721Tokens[depositor][tokenAddress];
    }

     /// @notice View the list of all addresses who have deposited any ERC20 into the vault.
     /// @dev Note: This list is appended to and does not shrink, even if users withdraw.
     /// @return An array of depositor addresses.
    function getAllERC20Depositors() public view returns (address[] memory) {
        return erc20Depositors;
    }

     /// @notice View the list of all addresses who have deposited any ERC721 into the vault.
     /// @dev Note: This list is appended to and does not shrink, even if users withdraw.
     /// @return An array of depositor addresses.
    function getAllERC721Depositors() public view returns (address[] memory) {
        return erc721Depositors;
    }


    // --- Administrative & Utility Functions ---

    /// @notice Owner-only function to pause core vault operations (deposits, claims, state transitions).
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Owner-only function to unpause core vault operations.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // transferOwnership & renounceOwnership are inherited from Ownable

    /// @notice View the challenge hash required for the challenge proof condition.
    /// @return The keccak256 hash value.
    function getChallengeProofHash() public view returns (bytes32) {
        return vaultConfig.challengeProofHash;
    }

    /// @notice Owner-only function to manually transition back to the Locked state.
    /// @dev Useful for resetting the vault or correcting errors. Requires pausing.
    function transitionToLocked() public onlyOwner whenPaused {
        _changeState(VaultState.Locked);
        // Consider also clearing proofs and resetting challenge timer here if desired for a full reset
        oracleProofSubmitted = false;
        challengeProofSubmitted = false;
        challengePeriodStartTime = 0;
        // Conditions themselves are kept unless explicitly reset
    }

    // Required by ERC721Holder
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This function is called by the ERC721 contract after a successful transfer to this contract.
        // We can optionally add checks here, e.g., ensure the sender is this contract itself from a deposit,
        // or log the receipt. For this contract, the checks are done in the deposit function.
        // We must return this specific value to signal successful receipt.
        return this.onERC721Received.selector;
    }
}
```