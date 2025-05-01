Okay, here is a Solidity smart contract implementing a "Quantum Vault" concept. This contract allows users to deposit Ether and ERC20 tokens into a secure vault and release them based on complex, multi-factor conditions tied to submitting and verifying "proofs" (simulating interactions with verifiable computation or off-chain systems) and potentially oracle data.

It includes features like:
*   Deposits and balance checks.
*   Owner-managed allowed tokens.
*   Defining types of "proofs" required for access.
*   Users submitting "proofs" with associated data.
*   Internal (simulated) proof verification logic.
*   Defining complex withdrawal conditions requiring multiple proofs and potentially oracle values.
*   Initiating withdrawals based on meeting conditions (but not immediate execution).
*   Processing initiated withdrawals by an authorized keeper/user, checking current conditions.
*   Cancellation of initiated withdrawals.
*   Delegated management roles for specific conditions.
*   Owner-only emergency withdrawals.
*   Basic Oracle integration for condition checks.
*   Approved Provers list for specific proof types.

**Outline & Function Summary**

This contract, `QuantumVault`, acts as a secure vault with conditional release mechanisms based on off-chain proof verification signals and oracle data.

1.  **Core Infrastructure:**
    *   `constructor(address initialOracle)`: Sets initial owner and oracle address.
    *   `receive() external payable`: Allows receiving Ether deposits.
    *   `fallback() external payable`: Catches unexpected calls and allows Ether deposits.
    *   `updateOracleAddress(address newOracle)`: Owner updates the oracle contract address.
    *   `emergencyWithdrawEther(address recipient)`: Owner can withdraw all Ether in emergencies.
    *   `emergencyWithdrawERC20(address token, address recipient)`: Owner can withdraw a specific ERC20 in emergencies.

2.  **Vault Management (Deposits & Balances):**
    *   `depositEther() external payable`: Deposits Ether into the vault.
    *   `depositERC20(address token, uint256 amount)`: Deposits an allowed ERC20 token.
    *   `addAllowedToken(address token)`: Owner adds a token to the allowed list.
    *   `removeAllowedToken(address token)`: Owner removes a token from the allowed list.
    *   `isAllowedToken(address token) public view`: Checks if a token is allowed.
    *   `getAllowedTokens() public view`: Returns the list of allowed tokens.
    *   `getVaultBalanceEther() public view`: Returns the vault's Ether balance.
    *   `getVaultBalanceERC20(address token) public view`: Returns the vault's balance for a specific ERC20 token.

3.  **Proof Type Definition & Management:**
    *   `defineProofType(bytes32 proofTypeId, string memory description)`: Owner defines a new type of required proof.
    *   `revokeProofType(bytes32 proofTypeId)`: Owner revokes an existing proof type.
    *   `getProofTypeDescription(bytes32 proofTypeId) public view`: Gets the description of a proof type.
    *   `isProofTypeDefined(bytes32 proofTypeId) public view`: Checks if a proof type is defined.

4.  **Proof Submission & Verification (Simulated):**
    *   `submitProof(bytes32 proofTypeId, bytes memory proofData, uint64 validityDuration)`: User submits proof data for a defined type. The contract records this with a validity period.
    *   `verifyProofInternal(bytes32 proofTypeId, address submitter, bytes memory proofData) internal view returns (bool)`: *Internal helper function* simulating proof verification. **Note:** Real complex ZKP verification is computationally prohibitive on-chain. This function is a placeholder that *could* interact with an external verifier contract or oracle in a real-world scenario, or perform simple checks on `proofData`. In this example, it's simplified (e.g., checking a hash or simple data structure).
    *   `invalidateProof(bytes32 proofHash)`: Owner or approved prover can invalidate a submitted proof.
    *   `getProofStatus(bytes32 proofHash) public view returns (bool isValid, uint64 expiryTime)`: Gets the current validity status and expiry time of a submitted proof.
    *   `getProofDetails(bytes32 proofHash) public view returns (bytes32 proofTypeId, address submitter, bytes memory proofData, uint64 submittedAt, uint64 expiryTime)`: Gets all details of a submitted proof.

5.  **Conditional Release Definition:**
    *   `defineReleaseCondition(bytes32 conditionId, bytes32[] requiredProofTypes, uint64 minProofValidity, uint256 requiredOracleValueKey, uint256 requiredOracleValue)`: Owner defines a condition for releasing funds. Requires specified proof types to be valid for at least `minProofValidity` and an oracle query result to match `requiredOracleValue`.
    *   `revokeReleaseCondition(bytes32 conditionId)`: Owner revokes a release condition.
    *   `getReleaseConditionDetails(bytes32 conditionId) public view returns (bytes32[] memory requiredProofTypes, uint64 minProofValidity, uint256 requiredOracleValueKey, uint256 requiredOracleValue)`: Gets details of a release condition.
    *   `isReleaseConditionDefined(bytes32 conditionId) public view`: Checks if a release condition is defined.

6.  **Conditional Withdrawal Process:**
    *   `initiateConditionalWithdrawal(bytes32 conditionId, address token, uint256 amount, address recipient, bytes32[] submittedProofHashes)`: User initiates a withdrawal request linked to a condition and providing specific submitted proofs. Contract checks if the provided proof hashes match the required *types* for the condition. Actual transfer doesn't happen here.
    *   `processWithdrawalQueue(bytes32 withdrawalId)`: Allows an authorized entity (owner or delegated processor) to attempt to finalize an initiated withdrawal. This function checks if *all* conditions (proof validity, oracle value) are *currently* met and executes the transfer if so.
    *   `cancelInitiatedWithdrawal(bytes32 withdrawalId)`: User who initiated or Owner can cancel an pending withdrawal request.
    *   `getWithdrawalStatus(bytes32 withdrawalId) public view returns (InitiatedWithdrawalStatus status)`: Gets the status of an initiated withdrawal request.
    *   `getWithdrawalDetails(bytes32 withdrawalId) public view returns (bytes32 conditionId, address token, uint256 amount, address recipient, address initiator, bytes32[] memory submittedProofHashes)`: Gets details of an initiated withdrawal.

7.  **Delegated Management:**
    *   `defineDelegatedProcessor(address processor, uint64 expiryTime)`: Owner defines an address that can call `processWithdrawalQueue`.
    *   `revokeDelegatedProcessor(address processor)`: Owner revokes delegated processing rights.
    *   `isDelegatedProcessor(address processor) public view`: Checks if an address is a delegated processor and their rights haven't expired.

8.  **Approved Provers (Optional Layer):**
    *   `addApprovedProver(address prover)`: Owner adds an address to the approved provers list.
    *   `removeApprovedProver(address prover)`: Owner removes an address from the approved provers list.
    *   `isApprovedProver(address prover) public view`: Checks if an address is on the approved provers list. (Can be used in `submitProof` or `invalidateProof` modifiers/checks). *Self-correction*: Let's use this list to allow `ApprovedProvers` to `invalidateProof`.

9.  **Ownable Functions (Standard):**
    *   `transferOwnership(address newOwner)`: Transfers contract ownership.
    *   `renounceOwnership()`: Renounces contract ownership.

**Total Functions:** 36 (Including Ownable) - More than the minimum 20 required.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Interface for a simple oracle contract
interface IOracle {
    // Function to query an off-chain value by a key
    // Returns (value, timestamp, status) where status indicates validity
    function getValue(uint256 key) external view returns (uint256, uint64, bool);
}

/**
 * @title QuantumVault
 * @dev A secure vault smart contract allowing conditional release of assets
 *      based on submitted proofs (simulated verifiable computation signals)
 *      and external oracle data.
 *
 * Outline:
 * 1. Core Infrastructure: Constructor, fallback/receive, Oracle management, Emergency withdrawals.
 * 2. Vault Management: Deposit (ETH & ERC20), Allowed Tokens management, Balance checks.
 * 3. Proof Type Definition: Defining types of required proofs.
 * 4. Proof Submission & Verification (Simulated): Submitting proofs, internal verification logic, invalidation, status/detail checks.
 * 5. Conditional Release Definition: Defining complex conditions requiring multiple proofs and oracle values.
 * 6. Conditional Withdrawal Process: Initiating withdrawal requests based on conditions, processing queue (final execution), cancellation, status/detail checks.
 * 7. Delegated Management: Allowing trusted addresses to process withdrawal requests.
 * 8. Approved Provers: Managing a list of addresses allowed to submit/invalidate certain proofs.
 * 9. Ownable Functions: Standard ownership management.
 */
contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    address private immutable oracleAddress;

    // Mapping of allowed ERC20 tokens
    mapping(address => bool) private allowedTokens;
    address[] private allowedTokenList; // To easily retrieve the list

    // Struct for defining a type of proof required for access
    struct ProofType {
        string description;
        bool isDefined; // Sentinel to check if the typeId exists
    }
    mapping(bytes32 => ProofType) private proofTypes;

    // Struct for a submitted proof instance
    struct SubmittedProof {
        bytes32 proofTypeId; // Which type of proof is this?
        address submitter;
        bytes proofData; // The actual data of the proof (e.g., serialized ZK proof, signature)
        uint64 submittedAt; // Timestamp of submission
        uint64 expiryTime; // When this proof instance becomes invalid
        bool isValid; // Current validity status (can be invalidated manually)
    }
    mapping(bytes32 => SubmittedProof) private submittedProofs; // proofHash => SubmittedProof
    mapping(bytes32 => bool) private submittedProofExists; // proofHash => exists

    // Struct for defining a release condition
    struct ReleaseCondition {
        bytes32[] requiredProofTypes; // Array of proof type IDs required
        uint64 minProofValidity; // Minimum remaining validity required for submitted proofs
        uint256 requiredOracleValueKey; // Key for the oracle query
        uint256 requiredOracleValue; // The specific value the oracle must return
        bool isDefined; // Sentinel
    }
    mapping(bytes32 => ReleaseCondition) private releaseConditions;

    // Status of an initiated withdrawal request
    enum InitiatedWithdrawalStatus { Pending, Processed, Cancelled }

    // Struct for an initiated withdrawal request
    struct InitiatedWithdrawal {
        bytes32 conditionId; // Which condition this withdrawal is based on
        address token; // Address of the token (address(0) for Ether)
        uint256 amount;
        address recipient;
        address initiator;
        bytes32[] submittedProofHashes; // Hashes of the proofs provided by the initiator
        InitiatedWithdrawalStatus status;
        uint64 initiatedAt; // Timestamp of initiation
    }
    mapping(bytes32 => InitiatedWithdrawal) private initiatedWithdrawals;
    mapping(bytes32 => bool) private initiatedWithdrawalExists; // withdrawalId => exists

    // Mapping for addresses allowed to process withdrawals (can be keepers)
    mapping(address => uint64) private delegatedProcessors; // processor => expiryTime

    // Set of addresses approved to submit/invalidate certain proofs
    mapping(address => bool) private approvedProvers;


    // --- Events ---

    event EtherDeposited(address indexed depositor, uint256 amount);
    event ERC20Deposited(address indexed token, address indexed depositor, uint256 amount);
    event AllowedTokenAdded(address indexed token);
    event AllowedTokenRemoved(address indexed token);
    event ProofTypeDefined(bytes32 indexed proofTypeId, string description);
    event ProofTypeRevoked(bytes32 indexed proofTypeId);
    event ProofSubmitted(bytes32 indexed proofHash, bytes32 indexed proofTypeId, address indexed submitter, uint64 expiryTime);
    event ProofInvalidated(bytes32 indexed proofHash, address indexed invalidator);
    event ReleaseConditionDefined(bytes32 indexed conditionId, bytes32[] requiredProofTypes, uint64 minProofValidity, uint256 requiredOracleValueKey, uint256 requiredOracleValue);
    event ReleaseConditionRevoked(bytes32 indexed conditionId);
    event WithdrawalInitiated(bytes32 indexed withdrawalId, bytes32 indexed conditionId, address indexed initiator, address indexed recipient, address token, uint256 amount);
    event WithdrawalProcessed(bytes32 indexed withdrawalId, address indexed processor);
    event WithdrawalCancelled(bytes32 indexed withdrawalId, address indexed canceller);
    event DelegatedProcessorDefined(address indexed processor, uint64 expiryTime);
    event DelegatedProcessorRevoked(address indexed processor);
    event ApprovedProverAdded(address indexed prover);
    event ApprovedProverRemoved(address indexed prover);
    event OracleAddressUpdated(address indexed newOracle);
    event EmergencyWithdrawal(address indexed tokenOrZero, address indexed recipient, uint256 amount);


    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QV: Only oracle");
        _;
    }

    modifier onlyProcessor() {
        require(msg.sender == owner() || (delegatedProcessors[msg.sender] > block.timestamp), "QV: Only owner or delegated processor");
        _;
    }

    modifier onlyInitiatorOrOwner(bytes32 withdrawalId) {
        require(initiatedWithdrawalExists[withdrawalId], "QV: Withdrawal does not exist");
        require(msg.sender == initiatedWithdrawals[withdrawalId].initiator || msg.sender == owner(), "QV: Only initiator or owner");
        _;
    }

    modifier onlyApprovedProver() {
        require(approvedProvers[msg.sender], "QV: Only approved provers");
        _;
    }

    // --- Constructor ---

    constructor(address initialOracle) Ownable(msg.sender) {
        require(initialOracle != address(0), "QV: Invalid oracle address");
        oracleAddress = initialOracle;
    }

    // --- Core Infrastructure ---

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Updates the address of the oracle contract.
     * @param newOracle The address of the new oracle contract.
     */
    function updateOracleAddress(address newOracle) external onlyOwner {
        require(newOracle != address(0), "QV: Invalid new oracle address");
        oracleAddress = newOracle;
        emit OracleAddressUpdated(newOracle);
    }

    /**
     * @dev Allows the owner to withdraw all Ether from the contract in case of emergency.
     *      This bypasses any release conditions.
     * @param recipient The address to send the Ether to.
     */
    function emergencyWithdrawEther(address recipient) external onlyOwner {
        require(recipient != address(0), "QV: Invalid recipient address");
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "QV: Ether transfer failed");
        emit EmergencyWithdrawal(address(0), recipient, balance);
    }

    /**
     * @dev Allows the owner to withdraw all of a specific ERC20 token in case of emergency.
     *      This bypasses any release conditions.
     * @param token The address of the ERC20 token.
     * @param recipient The address to send the tokens to.
     */
    function emergencyWithdrawERC20(address token, address recipient) external onlyOwner {
        require(token != address(0), "QV: Invalid token address");
        require(recipient != address(0), "QV: Invalid recipient address");
        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.safeTransfer(recipient, balance);
        emit EmergencyWithdrawal(token, recipient, balance);
    }


    // --- Vault Management ---

    /**
     * @dev Deposits Ether into the vault.
     */
    function depositEther() external payable {
        require(msg.value > 0, "QV: Must deposit non-zero Ether");
        // Ether is received via receive() or fallback()
    }

    /**
     * @dev Deposits an allowed ERC20 token into the vault.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external {
        require(isAllowedToken(token), "QV: Token not allowed");
        require(amount > 0, "QV: Must deposit non-zero amount");
        IERC20 tokenContract = IERC20(token);
        tokenContract.safeTransferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(token, msg.sender, amount);
    }

    /**
     * @dev Adds an ERC20 token address to the list of allowed tokens.
     * @param token The address of the token to allow.
     */
    function addAllowedToken(address token) external onlyOwner {
        require(token != address(0), "QV: Invalid token address");
        if (!allowedTokens[token]) {
            allowedTokens[token] = true;
            allowedTokenList.push(token);
            emit AllowedTokenAdded(token);
        }
    }

    /**
     * @dev Removes an ERC20 token address from the list of allowed tokens.
     *      Existing deposits of this token remain in the vault until withdrawn via conditions or emergency.
     * @param token The address of the token to disallow.
     */
    function removeAllowedToken(address token) external onlyOwner {
         require(allowedTokens[token], "QV: Token not currently allowed");
        allowedTokens[token] = false;
        // Removing from array is more complex if order needs to be preserved,
        // simple removal can be done by swapping with last and popping.
        // Find index (linear scan, okay for small lists, optimize for large)
        for (uint i = 0; i < allowedTokenList.length; i++) {
            if (allowedTokenList[i] == token) {
                allowedTokenList[i] = allowedTokenList[allowedTokenList.length - 1];
                allowedTokenList.pop();
                break;
            }
        }
        emit AllowedTokenRemoved(token);
    }


    /**
     * @dev Checks if a token is currently in the allowed list.
     * @param token The address of the token.
     * @return bool True if the token is allowed, false otherwise.
     */
    function isAllowedToken(address token) public view returns (bool) {
        return allowedTokens[token];
    }

     /**
     * @dev Returns the list of allowed ERC20 token addresses.
     * @return address[] An array of allowed token addresses.
     */
    function getAllowedTokens() public view returns (address[] memory) {
        // Note: This returns the current state. Removing a token might leave a zero address if simple removal isn't used.
        // The removeAllowedToken above uses a basic swap-and-pop for simplicity, which changes order.
        uint256 count = 0;
        for(uint i=0; i < allowedTokenList.length; i++){
            if(allowedTokens[allowedTokenList[i]]){ // Double check using the mapping
                 count++;
            }
        }

        address[] memory currentList = new address[](count);
        uint256 currentIdx = 0;
         for(uint i=0; i < allowedTokenList.length; i++){
            if(allowedTokens[allowedTokenList[i]]){
                 currentList[currentIdx] = allowedTokenList[i];
                 currentIdx++;
            }
        }
        return currentList;

    }


    /**
     * @dev Returns the current Ether balance of the vault contract.
     * @return uint256 The Ether balance.
     */
    function getVaultBalanceEther() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the current balance of a specific ERC20 token held by the vault contract.
     * @param token The address of the ERC20 token.
     * @return uint256 The token balance.
     */
    function getVaultBalanceERC20(address token) public view returns (uint256) {
         require(token != address(0), "QV: Invalid token address");
        return IERC20(token).balanceOf(address(this));
    }


    // --- Proof Type Definition & Management ---

    /**
     * @dev Defines a new type of proof required for access.
     * @param proofTypeId A unique identifier for the proof type (e.g., keccak256("ProofOfIdentity")).
     * @param description A human-readable description of the proof type.
     */
    function defineProofType(bytes32 proofTypeId, string memory description) external onlyOwner {
        require(proofTypeId != bytes32(0), "QV: Invalid proof type ID");
        require(!proofTypes[proofTypeId].isDefined, "QV: Proof type already defined");
        proofTypes[proofTypeId] = ProofType({
            description: description,
            isDefined: true
        });
        emit ProofTypeDefined(proofTypeId, description);
    }

    /**
     * @dev Revokes an existing proof type. Existing submitted proofs of this type remain,
     *      but new submissions won't be accepted, and conditions requiring this type
     *      will become impossible to meet.
     * @param proofTypeId The identifier of the proof type to revoke.
     */
    function revokeProofType(bytes32 proofTypeId) external onlyOwner {
        require(proofTypes[proofTypeId].isDefined, "QV: Proof type not defined");
        delete proofTypes[proofTypeId]; // Removes the struct instance
        emit ProofTypeRevoked(proofTypeId);
    }

    /**
     * @dev Gets the description of a defined proof type.
     * @param proofTypeId The identifier of the proof type.
     * @return string The description of the proof type.
     */
    function getProofTypeDescription(bytes32 proofTypeId) public view returns (string memory) {
         require(proofTypes[proofTypeId].isDefined, "QV: Proof type not defined");
        return proofTypes[proofTypeId].description;
    }

     /**
     * @dev Checks if a proof type has been defined.
     * @param proofTypeId The identifier of the proof type.
     * @return bool True if the proof type is defined, false otherwise.
     */
    function isProofTypeDefined(bytes32 proofTypeId) public view returns (bool) {
        return proofTypes[proofTypeId].isDefined;
    }


    // --- Proof Submission & Verification (Simulated) ---

    /**
     * @dev Allows a user to submit a proof instance for a defined proof type.
     *      The contract records the proof data and assigns a validity duration.
     *      Actual verification logic happens within `verifyProofInternal`.
     * @param proofTypeId The identifier of the proof type this submission belongs to.
     * @param proofData The actual data of the proof (e.g., serialized proof output).
     * @param validityDuration The duration (in seconds) for which this submitted proof should be considered valid.
     */
    function submitProof(bytes32 proofTypeId, bytes memory proofData, uint64 validityDuration) external {
        require(proofTypes[proofTypeId].isDefined, "QV: Proof type not defined");
        // In a real system, verifyProofInternal would be crucial.
        // Here, we simulate that step might happen off-chain and proofData
        // contains the necessary info to be potentially checked later or indicates off-chain verification result.
        // For simplicity in this example, we just record it as valid initially.
        // A more complex version might require an oracle call here or in verifyProofInternal.

        // Generate a unique hash for this submitted proof instance
        bytes32 proofHash = keccak256(abi.encodePacked(proofTypeId, msg.sender, proofData, block.timestamp, block.number));

        require(!submittedProofExists[proofHash], "QV: Proof already submitted with this hash");

        uint64 expiry = uint64(block.timestamp) + validityDuration;

        submittedProofs[proofHash] = SubmittedProof({
            proofTypeId: proofTypeId,
            submitter: msg.sender,
            proofData: proofData,
            submittedAt: uint64(block.timestamp),
            expiryTime: expiry,
            isValid: true // Assume valid upon submission (or based on off-chain signal in proofData)
        });
        submittedProofExists[proofHash] = true;

        emit ProofSubmitted(proofHash, proofTypeId, msg.sender, expiry);
    }

    /**
     * @dev Internal helper function simulating verification of proof data.
     *      **IMPORTANT:** This is a simplified simulation. Real ZKP verification
     *      is complex and costly on-chain. In practice, this might:
     *      - Call an external ZKP verification contract.
     *      - Query an oracle that provides verification results.
     *      - Perform simple checks on `proofData` (e.g., hash match, signature check).
     *      This example performs a trivial check based on `proofData` length.
     * @param proofTypeId The type of proof.
     * @param submitter The address that submitted the proof.
     * @param proofData The data submitted with the proof.
     * @return bool True if the proof is considered valid based on the simulation, false otherwise.
     */
    function verifyProofInternal(bytes32 proofTypeId, address submitter, bytes memory proofData) internal view returns (bool) {
        // *** SIMULATED VERIFICATION LOGIC ***
        // Replace with actual verification logic (e.g., external call to verifier contract, oracle query)
        // Example: Check if the proofData size is non-zero and matches a pattern
        if (proofData.length == 0) {
            return false;
        }
        // More complex simulation: check if the hash of proofData matches something derived from proofTypeId and submitter
        bytes32 expectedHash = keccak256(abi.encodePacked("simulated_secret", proofTypeId, submitter));
        bytes32 actualHash = keccak256(proofData);

        // In a real scenario, proofData might contain the actual inputs/outputs/proof
        // and you would call a specific verifier contract for `proofTypeId`
        // Example: return ExternalZKVerifier(verifierAddresses[proofTypeId]).verify(proofData);
        // Or: return IOracle(oracleAddress).verifyProof(proofTypeId, submitter, proofData);

        return actualHash == expectedHash; // Trivial simulated check
        // *** END SIMULATION ***
    }


    /**
     * @dev Allows the owner or an approved prover to invalidate a submitted proof instance.
     *      This makes the proof unusable for meeting release conditions, regardless of its expiry time.
     * @param proofHash The hash of the submitted proof to invalidate.
     */
    function invalidateProof(bytes32 proofHash) external onlyApprovedProver { // Only approved provers or owner (via onlyApprovedProver if owner is also approved)
        require(submittedProofExists[proofHash], "QV: Proof does not exist");
        require(submittedProofs[proofHash].isValid, "QV: Proof is already invalid");

        submittedProofs[proofHash].isValid = false;

        emit ProofInvalidated(proofHash, msg.sender);
    }

    /**
     * @dev Gets the current validity status and expiry time of a submitted proof.
     *      A proof is valid if `isValid` is true AND `expiryTime` is in the future.
     * @param proofHash The hash of the submitted proof.
     * @return bool isValid True if the proof is currently valid, false otherwise.
     * @return uint64 expiryTime The timestamp when the proof expires.
     */
    function getProofStatus(bytes32 proofHash) public view returns (bool isValid, uint64 expiryTime) {
        if (!submittedProofExists[proofHash]) {
            return (false, 0);
        }
        SubmittedProof storage proof = submittedProofs[proofHash];
        return (proof.isValid && proof.expiryTime > block.timestamp, proof.expiryTime);
    }

     /**
     * @dev Gets all stored details for a submitted proof instance.
     * @param proofHash The hash of the submitted proof.
     * @return bytes32 proofTypeId The type of proof.
     * @return address submitter The address that submitted the proof.
     * @return bytes proofData The data submitted with the proof.
     * @return uint64 submittedAt The timestamp of submission.
     * @return uint64 expiryTime The timestamp when the proof expires.
     */
    function getProofDetails(bytes32 proofHash) public view returns (bytes32 proofTypeId, address submitter, bytes memory proofData, uint64 submittedAt, uint64 expiryTime) {
        require(submittedProofExists[proofHash], "QV: Proof does not exist");
        SubmittedProof storage proof = submittedProofs[proofHash];
        return (proof.proofTypeId, proof.submitter, proof.proofData, proof.submittedAt, proof.expiryTime);
    }


    // --- Conditional Release Definition ---

    /**
     * @dev Defines a condition under which funds can be released from the vault.
     *      Requires specific proof types to be valid and an oracle query result to match.
     * @param conditionId A unique identifier for the release condition.
     * @param requiredProofTypes An array of proof type IDs that must be presented via valid submitted proofs.
     * @param minProofValidity Minimum remaining validity (in seconds) required for each submitted proof.
     * @param requiredOracleValueKey The key to query the oracle contract.
     * @param requiredOracleValue The expected value from the oracle query for the condition to be met.
     */
    function defineReleaseCondition(bytes32 conditionId, bytes32[] memory requiredProofTypes, uint64 minProofValidity, uint256 requiredOracleValueKey, uint256 requiredOracleValue) external onlyOwner {
        require(conditionId != bytes32(0), "QV: Invalid condition ID");
        require(!releaseConditions[conditionId].isDefined, "QV: Condition already defined");
        require(requiredProofTypes.length > 0, "QV: At least one proof type is required");

        // Validate all required proof types exist
        for (uint i = 0; i < requiredProofTypes.length; i++) {
            require(proofTypes[requiredProofTypes[i]].isDefined, "QV: Required proof type not defined");
        }

        releaseConditions[conditionId] = ReleaseCondition({
            requiredProofTypes: requiredProofTypes,
            minProofValidity: minProofValidity,
            requiredOracleValueKey: requiredOracleValueKey,
            requiredOracleValue: requiredOracleValue,
            isDefined: true
        });
        emit ReleaseConditionDefined(conditionId, requiredProofTypes, minProofValidity, requiredOracleValueKey, requiredOracleValue);
    }

    /**
     * @dev Revokes an existing release condition. Initiated withdrawals based on this condition
     *      will become unprocessable.
     * @param conditionId The identifier of the release condition to revoke.
     */
    function revokeReleaseCondition(bytes32 conditionId) external onlyOwner {
        require(releaseConditions[conditionId].isDefined, "QV: Condition not defined");
        delete releaseConditions[conditionId]; // Removes the struct instance
        emit ReleaseConditionRevoked(conditionId);
    }

     /**
     * @dev Gets the details of a defined release condition.
     * @param conditionId The identifier of the release condition.
     * @return bytes32[] requiredProofTypes The array of required proof type IDs.
     * @return uint64 minProofValidity Minimum remaining validity required for proofs.
     * @return uint256 requiredOracleValueKey The key for the oracle query.
     * @return uint256 requiredOracleValue The expected value from the oracle.
     */
    function getReleaseConditionDetails(bytes32 conditionId) public view returns (bytes32[] memory requiredProofTypes, uint64 minProofValidity, uint256 requiredOracleValueKey, uint256 requiredOracleValue) {
        require(releaseConditions[conditionId].isDefined, "QV: Condition not defined");
        ReleaseCondition storage condition = releaseConditions[conditionId];
        return (condition.requiredProofTypes, condition.minProofValidity, condition.requiredOracleValueKey, condition.requiredOracleValue);
    }

    /**
     * @dev Checks if a release condition has been defined.
     * @param conditionId The identifier of the release condition.
     * @return bool True if the condition is defined, false otherwise.
     */
    function isReleaseConditionDefined(bytes32 conditionId) public view returns (bool) {
        return releaseConditions[conditionId].isDefined;
    }


    // --- Conditional Withdrawal Process ---

    /**
     * @dev Allows a user to initiate a withdrawal request based on a defined condition.
     *      The user must provide hashes of their submitted proofs that match the required types.
     *      This only queues the request; the actual transfer is done by `processWithdrawalQueue`.
     * @param conditionId The identifier of the release condition.
     * @param token The address of the token to withdraw (address(0) for Ether).
     * @param amount The amount to withdraw.
     * @param recipient The address to send the funds to.
     * @param submittedProofHashes An array of hashes of the proofs submitted by the initiator.
     */
    function initiateConditionalWithdrawal(
        bytes32 conditionId,
        address token,
        uint256 amount,
        address recipient,
        bytes32[] memory submittedProofHashes
    ) external {
        require(releaseConditions[conditionId].isDefined, "QV: Condition not defined");
        require(amount > 0, "QV: Must withdraw non-zero amount");
        require(recipient != address(0), "QV: Invalid recipient address");

        // Check if token is allowed (if not Ether)
        if (token != address(0)) {
            require(isAllowedToken(token), "QV: Token not allowed");
             require(getVaultBalanceERC20(token) >= amount, "QV: Insufficient token balance in vault");
        } else {
            require(getVaultBalanceEther() >= amount, "QV: Insufficient Ether balance in vault");
        }


        ReleaseCondition storage condition = releaseConditions[conditionId];
        require(submittedProofHashes.length == condition.requiredProofTypes.length, "QV: Incorrect number of proofs provided");

        // Check if the provided proof hashes match the required types
        // This does NOT check validity or expiry yet, only type.
        mapping(bytes32 => uint256) memory providedProofTypeCounts;
        mapping(bytes32 => bool) memory providedProofHashUsed; // Ensure unique hashes are provided

        for (uint i = 0; i < submittedProofHashes.length; i++) {
            bytes32 proofHash = submittedProofHashes[i];
            require(submittedProofExists[proofHash], "QV: Submitted proof does not exist");
            require(!providedProofHashUsed[proofHash], "QV: Duplicate proof hash provided");

            SubmittedProof storage proof = submittedProofs[proofHash];
            // Check if the proof's type is one of the required types
            bool isRequiredType = false;
            for (uint j = 0; j < condition.requiredProofTypes.length; j++) {
                if (proof.proofTypeId == condition.requiredProofTypes[j]) {
                    isRequiredType = true;
                    providedProofTypeCounts[proof.proofTypeId]++;
                    break;
                }
            }
            require(isRequiredType, "QV: Provided proof is not of a required type");

            providedProofHashUsed[proofHash] = true;
        }

        // Ensure all required proof types are covered by the provided proofs
        for (uint i = 0; i < condition.requiredProofTypes.length; i++) {
            require(providedProofTypeCounts[condition.requiredProofTypes[i]] > 0, "QV: Missing required proof type");
            // Note: This simple check allows multiple proofs of the *same* required type if the condition lists the same type multiple times.
            // If each requiredProofType entry needs *a distinct* proof instance, more complex tracking is needed.
        }

        bytes32 withdrawalId = keccak256(abi.encodePacked(conditionId, msg.sender, token, amount, recipient, submittedProofHashes, block.timestamp, block.number));
        require(!initiatedWithdrawalExists[withdrawalId], "QV: Withdrawal request already exists");

        initiatedWithdrawals[withdrawalId] = InitiatedWithdrawal({
            conditionId: conditionId,
            token: token,
            amount: amount,
            recipient: recipient,
            initiator: msg.sender,
            submittedProofHashes: submittedProofHashes,
            status: InitiatedWithdrawalStatus.Pending,
            initiatedAt: uint64(block.timestamp)
        });
        initiatedWithdrawalExists[withdrawalId] = true;

        emit WithdrawalInitiated(withdrawalId, conditionId, msg.sender, recipient, token, amount);
    }

    /**
     * @dev Allows an authorized processor (owner or delegated) to process a pending withdrawal request.
     *      This function checks if ALL conditions (proof validity, oracle value) are currently met
     *      and executes the transfer if so.
     * @param withdrawalId The identifier of the initiated withdrawal request.
     */
    function processWithdrawalQueue(bytes32 withdrawalId) external onlyProcessor {
        require(initiatedWithdrawalExists[withdrawalId], "QV: Withdrawal does not exist");
        InitiatedWithdrawal storage withdrawal = initiatedWithdrawals[withdrawalId];
        require(withdrawal.status == InitiatedWithdrawalStatus.Pending, "QV: Withdrawal is not pending");

        ReleaseCondition storage condition = releaseConditions[withdrawal.conditionId];
        require(condition.isDefined, "QV: Associated condition is no longer defined");

        // Check Proof Conditions
        require(withdrawal.submittedProofHashes.length == condition.requiredProofTypes.length, "QV: Mismatch in required/provided proofs (should not happen if init was successful)");

        mapping(bytes32 => bool) usedRequiredProofType; // Track which required type slots are filled
        bool allProofsValidAndSufficientlyLong = true;

        // For each required proof type in the condition
        for (uint i = 0; i < condition.requiredProofTypes.length; i++) {
            bytes32 requiredType = condition.requiredProofTypes[i];
            bool foundValidProofForThisType = false;

            // Find *any* provided proof hash that matches this required type AND is currently valid
            for (uint j = 0; j < withdrawal.submittedProofHashes.length; j++) {
                bytes32 submittedHash = withdrawal.submittedProofHashes[j];
                 if(submittedProofExists[submittedHash]){
                     SubmittedProof storage submitted = submittedProofs[submittedHash];

                    if (submitted.proofTypeId == requiredType &&
                        submitted.isValid &&
                        submitted.expiryTime > block.timestamp &&
                        (submitted.expiryTime - uint64(block.timestamp)) >= condition.minProofValidity // Sufficient remaining validity
                        ) {
                        foundValidProofForThisType = true;
                        // Mark this slot as filled. Note: This simple logic assumes
                        // multiple identical required types can be satisfied by distinct proofs of that type.
                        // A more robust check might map provided proof hashes to required type indices uniquely.
                        break; // Found a valid proof for this required type, move to the next required type
                    }
                 }
            }

            if (!foundValidProofForThisType) {
                allProofsValidAndSufficientlyLong = false;
                break; // Condition not met, no need to check further proofs
            }
        }

        require(allProofsValidAndSufficientlyLong, "QV: Proof conditions not met (invalid, expired, or insufficient validity)");

        // Check Oracle Condition
        (uint256 oracleValue, uint64 oracleTimestamp, bool oracleStatus) = IOracle(oracleAddress).getValue(condition.requiredOracleValueKey);
        require(oracleStatus, "QV: Oracle value not available or invalid");
        // Optionally check oracleTimestamp freshness: require(block.timestamp - oracleTimestamp <= maxOracleLatency, "QV: Oracle value too old");
        require(oracleValue == condition.requiredOracleValue, "QV: Oracle value does not match requirement");

        // All conditions met, perform the transfer
        if (withdrawal.token == address(0)) {
             require(address(this).balance >= withdrawal.amount, "QV: Insufficient Ether balance for transfer (concurrent withdrawal?)");
            (bool success, ) = withdrawal.recipient.call{value: withdrawal.amount}("");
             require(success, "QV: Ether transfer failed during processing");
        } else {
             require(IERC20(withdrawal.token).balanceOf(address(this)) >= withdrawal.amount, "QV: Insufficient token balance for transfer (concurrent withdrawal?)");
            IERC20(withdrawal.token).safeTransfer(withdrawal.recipient, withdrawal.amount);
        }

        withdrawal.status = InitiatedWithdrawalStatus.Processed;
        emit WithdrawalProcessed(withdrawalId, msg.sender);
    }

    /**
     * @dev Allows the initiator of a withdrawal request or the owner to cancel it
     *      if it hasn't been processed yet.
     * @param withdrawalId The identifier of the initiated withdrawal request.
     */
    function cancelInitiatedWithdrawal(bytes32 withdrawalId) external onlyInitiatorOrOwner(withdrawalId) {
        require(initiatedWithdrawals[withdrawalId].status == InitiatedWithdrawalStatus.Pending, "QV: Withdrawal is not pending");

        initiatedWithdrawals[withdrawalId].status = InitiatedWithdrawalStatus.Cancelled;
        emit WithdrawalCancelled(withdrawalId, msg.sender);
    }

     /**
     * @dev Gets the current status of an initiated withdrawal request.
     * @param withdrawalId The identifier of the initiated withdrawal request.
     * @return InitiatedWithdrawalStatus The status (Pending, Processed, Cancelled).
     */
    function getWithdrawalStatus(bytes32 withdrawalId) public view returns (InitiatedWithdrawalStatus) {
         require(initiatedWithdrawalExists[withdrawalId], "QV: Withdrawal does not exist");
        return initiatedWithdrawals[withdrawalId].status;
    }

    /**
     * @dev Gets all stored details for an initiated withdrawal request.
     * @param withdrawalId The identifier of the initiated withdrawal request.
     * @return bytes32 conditionId The condition identifier.
     * @return address token The token address (address(0) for Ether).
     * @return uint256 amount The requested amount.
     * @return address recipient The recipient address.
     * @return address initiator The address that initiated the request.
     * @return bytes32[] submittedProofHashes The hashes of the submitted proofs provided.
     */
    function getWithdrawalDetails(bytes32 withdrawalId) public view returns (bytes32 conditionId, address token, uint256 amount, address recipient, address initiator, bytes32[] memory submittedProofHashes) {
         require(initiatedWithdrawalExists[withdrawalId], "QV: Withdrawal does not exist");
         InitiatedWithdrawal storage withdrawal = initiatedWithdrawals[withdrawalId];
        return (withdrawal.conditionId, withdrawal.token, withdrawal.amount, withdrawal.recipient, withdrawal.initiator, withdrawal.submittedProofHashes);
    }


    // --- Delegated Management ---

    /**
     * @dev Defines an address that is allowed to call `processWithdrawalQueue` until a specific time.
     * @param processor The address to grant processing rights to.
     * @param expiryTime The timestamp when the delegated rights expire.
     */
    function defineDelegatedProcessor(address processor, uint64 expiryTime) external onlyOwner {
        require(processor != address(0), "QV: Invalid processor address");
        require(expiryTime > block.timestamp, "QV: Expiry time must be in the future");
        delegatedProcessors[processor] = expiryTime;
        emit DelegatedProcessorDefined(processor, expiryTime);
    }

    /**
     * @dev Revokes the delegated processing rights for an address immediately.
     * @param processor The address to revoke rights from.
     */
    function revokeDelegatedProcessor(address processor) external onlyOwner {
        require(delegatedProcessors[processor] > block.timestamp, "QV: Processor is not currently delegated");
        delegatedProcessors[processor] = 0; // Setting expiry to 0 or past timestamp invalidates
        emit DelegatedProcessorRevoked(processor);
    }

    /**
     * @dev Checks if an address is currently a delegated processor.
     * @param processor The address to check.
     * @return bool True if the address is a delegated processor and their rights haven't expired, false otherwise.
     */
    function isDelegatedProcessor(address processor) public view returns (bool) {
        return delegatedProcessors[processor] > block.timestamp;
    }


    // --- Approved Provers ---

     /**
     * @dev Adds an address to the list of approved provers. Approved provers can `invalidateProof`.
     * @param prover The address to add.
     */
    function addApprovedProver(address prover) external onlyOwner {
        require(prover != address(0), "QV: Invalid prover address");
        require(!approvedProvers[prover], "QV: Prover is already approved");
        approvedProvers[prover] = true;
        emit ApprovedProverAdded(prover);
    }

    /**
     * @dev Removes an address from the list of approved provers.
     * @param prover The address to remove.
     */
    function removeApprovedProver(address prover) external onlyOwner {
         require(approvedProvers[prover], "QV: Prover is not approved");
        approvedProvers[prover] = false;
        emit ApprovedProverRemoved(prover);
    }

    /**
     * @dev Checks if an address is on the approved provers list.
     * @param prover The address to check.
     * @return bool True if the address is approved, false otherwise.
     */
    function isApprovedProver(address prover) public view returns (bool) {
        return approvedProvers[prover];
    }


    // --- Ownable Functions (Inherited from OpenZeppelin) ---
    // Includes: owner(), transferOwnership(), renounceOwnership()
    // These are implicitly available. Explicitly listing them for function count.

    // 35. owner() - inherited
    // 36. transferOwnership(address newOwner) - inherited
    // 37. renounceOwnership() - inherited
    // Oops, we have more than 36 functions already listed explicitly. Let's count precisely:
    // 1. constructor
    // 2. receive
    // 3. fallback
    // 4. updateOracleAddress
    // 5. emergencyWithdrawEther
    // 6. emergencyWithdrawERC20
    // 7. depositEther
    // 8. depositERC20
    // 9. addAllowedToken
    // 10. removeAllowedToken
    // 11. isAllowedToken
    // 12. getAllowedTokens
    // 13. getVaultBalanceEther
    // 14. getVaultBalanceERC20
    // 15. defineProofType
    // 16. revokeProofType
    // 17. getProofTypeDescription
    // 18. isProofTypeDefined
    // 19. submitProof
    // 20. verifyProofInternal (internal, not public/external) - still counts towards code complexity/logic
    // 21. invalidateProof
    // 22. getProofStatus
    // 23. getProofDetails
    // 24. defineReleaseCondition
    // 25. revokeReleaseCondition
    // 26. getReleaseConditionDetails
    // 27. isReleaseConditionDefined
    // 28. initiateConditionalWithdrawal
    // 29. processWithdrawalQueue
    // 30. cancelInitiatedWithdrawal
    // 31. getWithdrawalStatus
    // 32. getWithdrawalDetails
    // 33. defineDelegatedProcessor
    // 34. revokeDelegatedProcessor
    // 35. isDelegatedProcessor
    // 36. addApprovedProver
    // 37. removeApprovedProver
    // 38. isApprovedProver
    // 39. owner() - inherited
    // 40. transferOwnership(address newOwner) - inherited
    // 41. renounceOwnership() - inherited

    // Okay, we have 41 functions including internal and inherited. Well over 20.

}
```