Okay, let's design a sophisticated, conceptual smart contract focusing on dynamic access control and probabilistic outcomes inspired by analogies from quantum mechanics. We'll call it `QuantumVault`.

This contract will manage deposits of ERC20 and ERC721 tokens, but access and outcomes of withdrawals or other actions will be influenced by states like "Entanglement," "Superposition," "Temporal Phase Locks," and "Quantum Tunneling."

**Disclaimer:** The "quantum" aspects are analogies for complex, non-standard, probabilistic, or state-dependent contract logic. This contract uses pseudorandomness (`blockhash`, `timestamp`, etc.) for conceptual illustration, which is **not secure** for high-value real-world applications. Secure randomness requires oracles like Chainlink VRF. Gas costs for complex operations might be high. This is a demonstration of advanced *concepts* in Solidity, not production-ready code.

---

## QuantumVault Smart Contract

**Outline:**

1.  **SPDX-License-Identifier & Version Pragma**
2.  **Imports:** ERC20, ERC721 Interfaces, Ownable.
3.  **Interfaces:** Define minimal interfaces for ERC20 and ERC721.
4.  **State Variables:**
    *   Balances/Holdings (ERC20, ERC721).
    *   Owner.
    *   Entanglement Mappings (Address/Asset Pairs).
    *   Temporal Phase Lock Mappings (Address/Asset Time Ranges).
    *   Superposition State Mappings (ERC20 Amount/ERC721 ID, Outcome Probability).
    *   Quantum Tunneling Parameters (Probability, Cost).
    *   State Entanglement Mappings (Linking two ERC20 amounts).
    *   Decoherence Trigger Address & Status.
    *   Quantum Key System (Current key, Expiry).
    *   Last Random Seed contributor.
5.  **Events:** To log significant actions and state changes.
6.  **Modifiers:** `onlyOwner`, `whenNotPaused` (if added, though not planned for 20+ functions easily).
7.  **Internal Helper Functions:** Pseudorandom number generation, State checks (locked, entangled, etc.).
8.  **Core Functionality (User & Owner):**
    *   Deposits (ERC20, ERC721).
    *   Standard Withdrawals (Subject to conditions).
    *   Setting Quantum States (Entanglement, Locks, Superposition - primarily Owner).
    *   Interacting with Quantum States (Triggering effects, collapsing superposition, tunneling - User).
    *   Managing Quantum Key.
    *   Triggering Decoherence.
    *   Probabilistic Swap.
    *   Emergency Functions (Owner).
    *   Ownership Management.
9.  **View/Query Functions:** To inspect contract state and conditions.

**Function Summary:**

1.  `constructor()`: Deploys the contract and sets the owner.
2.  `depositERC20(address token, uint256 amount)`: Allows users to deposit specified ERC20 tokens after approving the contract.
3.  `depositERC721(address token, uint256 tokenId)`: Allows users to deposit specified ERC721 tokens after approving/transferring to the contract.
4.  `withdrawERC20_Standard(address token, uint256 amount)`: Attempts to withdraw ERC20. Subject to Temporal Locks, Superposition, and Entanglement effects.
5.  `withdrawERC721_Standard(address token, uint256 tokenId)`: Attempts to withdraw ERC721. Subject to Temporal Locks, Superposition, and Entanglement effects.
6.  `setEntangledPair_Address(address addressA, address addressB, uint8 probability)`: Owner sets two addresses as entangled, with a probability of interaction side-effects.
7.  `unsetEntangledPair_Address(address addressA)`: Owner removes an address entanglement.
8.  `triggerEntanglementEffect_User(address user)`: Callable by an entangled user. May trigger a probabilistic side-effect on their paired address (e.g., locking funds, triggering superposition).
9.  `setTemporalPhaseLock_Address(address user, uint256 unlockTimestamp, uint256 unlockBlock)`: Owner locks a user's access until a specific time AND block are reached.
10. `unsetTemporalPhaseLock_Address(address user)`: Owner removes a temporal lock for a user.
11. `enterSuperposition_ERC20(address token, uint256 amount, uint8 successProbability)`: User or Owner can place a specific amount of their ERC20 balance into a superposition state, meaning the *actual* withdrawable amount will be probabilistic.
12. `collapseSuperpositionAndWithdraw_ERC20(address token)`: Attempts to withdraw ERC20 from a superposition state. The final amount received is determined based on the success probability set during `enterSuperposition_ERC20`.
13. `enterSuperposition_ERC721(address token, uint256 tokenId, uint8 successProbability)`: User or Owner can place an ERC721 into a superposition state, meaning withdrawal success is probabilistic.
14. `collapseSuperpositionAndWithdraw_ERC721(address token, uint256 tokenId)`: Attempts to withdraw an ERC721 from a superposition state. Success is determined probabilistically.
15. `setQuantumTunnelingParams(uint8 probabilityPercent, uint256 requiredFee)`: Owner sets the probability and fee for attempting a 'quantum tunnel' withdrawal.
16. `attemptQuantumTunnel_ERC20(address token, uint256 amount) payable`: Attempts to withdraw ERC20 *bypassing* temporal locks and some entanglement effects with a low probability, requiring a fee.
17. `attemptQuantumTunnel_ERC721(address token, uint256 tokenId) payable`: Attempts to withdraw ERC721 *bypassing* temporal locks and some entanglement effects with a low probability, requiring a fee.
18. `setStateEntanglement_ERC20Amount(address tokenA, address tokenB, uint8 linkageStrength)`: Owner links the *amounts* held of two different ERC20 tokens for a user. A withdrawal from one may affect the balance of the other probabilistically based on `linkageStrength`.
19. `triggerStateEntanglement_WithdrawERC20(address tokenWithdrawn, uint256 amount)`: Internal helper/called by withdrawal. Applies state entanglement effects if tokens are linked for the caller.
20. `setDecoherenceTriggerAddress(address _decoherenceAddress)`: Owner designates a specific address that can trigger system-wide decoherence.
21. `triggerDecoherence()`: Callable only by the decoherence trigger address. Collapses all active superposition states for all users and temporarily disables quantum tunneling.
22. `generateQuantumKey()`: User generates a temporary, time-sensitive "quantum key" based on current block state, required for certain future actions (e.g., `withdrawERC20_WithKey`).
23. `withdrawERC20_WithKey(address token, uint256 amount, uint256 key)`: Withdraws ERC20, but requires providing the currently valid quantum key generated by `generateQuantumKey`.
24. `probabilisticAssetSwap_ERC20(address tokenIn, address tokenOut, uint256 amountIn, uint8 minOutcomePercent, uint8 maxOutcomePercent)`: Allows a user to swap an amount of one ERC20 for another *within their vault balance*. The exchange rate/outcome amount is determined probabilistically within the specified min/max percentage range of a theoretical 1:1 swap.
25. `queryUserERC20Balance(address user, address token)`: View function to check a user's standard ERC20 balance in the vault.
26. `queryUserERC721Owner(address token, uint256 tokenId)`: View function to check if the vault owns a specific ERC721 and if it's assigned to a user internally.
27. `queryEntangledPair(address user)`: View function to see which address a user is entangled with.
28. `queryTemporalLock(address user)`: View function to check a user's temporal lock status.
29. `querySuperpositionState_ERC20(address user, address token)`: View function to see the amount and probability of an ERC20 in superposition for a user.
30. `querySuperpositionState_ERC721(address user, address token, uint256 tokenId)`: View function to check the probability of an ERC721 in superposition for a user.
31. `queryQuantumTunnelingParams()`: View function to get the current tunneling parameters.
32. `queryQuantumKey(address user)`: View function to get the current quantum key and expiry for a user.
33. `queryDecoherenceStatus()`: View function to check if decoherence is active.
34. `emergencyWithdrawAllERC20(address token)`: Owner can withdraw all balances of a specific ERC20 token from the contract.
35. `emergencyWithdrawAllERC721(address token, uint256[] memory tokenIds)`: Owner can withdraw specific ERC721 tokens owned by the contract.
36. `transferOwnership(address newOwner)`: Standard Ownable function.
37. `renounceOwnership()`: Standard Ownable function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/token/erc721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Minimal interfaces for ERC20 and ERC721
interface IMiniERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IMiniERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}


/**
 * @title QuantumVault
 * @dev A conceptual smart contract demonstrating advanced, non-standard access control
 * and probabilistic outcomes inspired by quantum mechanics analogies (Entanglement, Superposition, Temporal Locks, Tunneling, Decoherence).
 * Manages ERC20 and ERC721 deposits and withdrawals with complex, state-dependent logic.
 *
 * WARNING: Uses pseudorandomness (blockhash, timestamp, etc.) which is INSECURE for real-world applications
 * requiring unpredictable outcomes. This contract is for conceptual demonstration only.
 */
contract QuantumVault is Ownable, ERC721Holder {
    using SafeMath for uint256;

    // --- State Variables ---

    // ERC20 Balances held for each user within the vault {user => {token => amount}}
    mapping(address => mapping(address => uint256)) private userERC20Balances;
    // ERC721 Ownership mapping within the vault {token => {tokenId => ownerAddress}}
    mapping(address => mapping(uint256 => address)) private userERC721Ownership;

    // Entanglement: Linking two addresses such that action by one may affect the other.
    // {addressA => {addressB => probability (0-100)}}
    mapping(address => mapping(address => uint8)) private entangledPairs;
    // Reverse mapping for easier lookup
    mapping(address => address) private entangledReverseLookup;

    // Temporal Phase Lock: User access is locked until both timestamp and block conditions are met.
    // {user => {unlockTimestamp, unlockBlock}}
    mapping(address => uint256[2]) private temporalLocks;

    // Superposition State: Assets or amounts are in a probabilistic state for withdrawal outcome.
    // ERC20: {user => {token => {amountInSuperposition, successProbability (0-100)}} }
    mapping(address => mapping(address => uint256[2])) private superpositionERC20;
    // ERC721: {user => {token => {tokenId => successProbability (0-100)}} }
    mapping(address => mapping(address => mapping(uint256 => uint8))) private superpositionERC721;

    // Quantum Tunneling Parameters: Allows bypassing locks with low probability for a fee.
    uint8 public quantumTunnelingProbabilityPercent = 0; // 0-100
    uint256 public quantumTunnelingFee = 0;

    // State Entanglement: Linking the amounts of two different ERC20 tokens for a user.
    // {user => {tokenA => {tokenB => linkageStrength (0-100)}} }
    mapping(address => mapping(address => mapping(address => uint8))) private stateEntanglementERC20;

    // Decoherence Trigger: An address authorized to trigger system-wide decoherence.
    address public decoherenceTriggerAddress;
    bool public decoherenceActive = false;
    uint256 public decoherenceEndTime = 0; // Time when decoherence effect wears off

    // Quantum Key System: A temporary key required for certain actions.
    // {user => {key, expiryTimestamp}}
    mapping(address => uint256[2]) private quantumKeys;
    uint256 public quantumKeyValidityDuration = 10 minutes; // Example duration

    // Pseudorandomness helper: To ensure seed changes across calls
    address private lastRandomSeedContributor;


    // --- Events ---
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount);
    event ERC721Withdrawn(address indexed user, address indexed token, uint256 tokenId);
    event EntangledPairSet(address indexed addressA, address indexed addressB, uint8 probability);
    event EntangledPairUnset(address indexed addressA);
    event EntanglementEffectTriggered(address indexed triggerAddress, address indexed affectedAddress, bool effectOccurred);
    event TemporalLockSet(address indexed user, uint256 unlockTimestamp, uint256 unlockBlock);
    event TemporalLockUnset(address indexed user);
    event ERC20EnteredSuperposition(address indexed user, address indexed token, uint256 amount, uint8 probability);
    event ERC721EnteredSuperposition(address indexed user, address indexed token, uint256 tokenId, uint8 probability);
    event ERC20SuperpositionCollapsed(address indexed user, address indexed token, uint256 originalAmount, uint256 finalAmountReceived);
    event ERC721SuperpositionCollapsed(address indexed user, address indexed token, uint256 tokenId, bool success);
    event QuantumTunnelAttempt(address indexed user, address indexed token, uint256 amountOrId, bool success, uint256 feePaid);
    event StateEntanglementERC20Set(address indexed user, address indexed tokenA, address indexed tokenB, uint8 strength);
    event DecoherenceTriggerAddressSet(address indexed _decoherenceAddress);
    event DecoherenceTriggered(address indexed triggerAddress);
    event QuantumKeyGenerated(address indexed user, uint256 key, uint256 expiry);
    event QuantumKeyUsed(address indexed user, uint256 key);
    event ProbabilisticSwapExecuted(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event EmergencyWithdrawalERC20(address indexed owner, address indexed token, uint256 amount);
    event EmergencyWithdrawalERC721(address indexed owner, address indexed token, uint256 tokenId);


    // --- Modifiers ---
    // (No custom modifiers needed beyond onlyOwner from Ownable for this set of functions)


    // --- Internal Helper Functions ---

    /**
     * @dev Generates a pseudorandom number using block data and transaction details.
     * WARNING: This is NOT cryptographically secure and is predictable by miners.
     * Do not use this for applications requiring strong, unpredictable randomness.
     * @param seedModifier A value to mix into the seed, e.g., user address, token ID.
     * @return Pseudorandom uint256.
     */
    function _generatePseudorandom(uint256 seedModifier) internal returns (uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Deprecated in newer EVM versions, but still works on many chains. Use chainlink VRF for security.
            block.number,
            msg.sender,
            tx.origin, // tx.origin can be risky, used here for randomness variety only
            tx.gasprice,
            lastRandomSeedContributor, // Mix in the last contributor's address
            seedModifier // Mix in a function-specific modifier
        )));
        lastRandomSeedContributor = msg.sender; // Update last contributor for next call
        return seed;
    }

    /**
     * @dev Checks if a probabilistic event succeeds.
     * @param probability Percent probability (0-100).
     * @param seedModifier A value to mix into the seed.
     * @return True if the event succeeds, false otherwise.
     */
    function _checkProbabilisticOutcome(uint8 probability, uint256 seedModifier) internal returns (bool) {
        require(probability <= 100, "Probability must be <= 100");
        if (probability == 0) return false;
        if (probability == 100) return true;

        uint256 randomValue = _generatePseudorandom(seedModifier);
        // Map uint256 max to 100, check if random value falls within probability range
        // (randomValue % 100) is a simpler but slightly less uniform approach, used here for clarity
        return (randomValue % 100) < probability;
    }

    /**
     * @dev Checks if a user's access is currently locked by a temporal phase lock.
     * @param user The address to check.
     * @return True if locked, false otherwise.
     */
    function _isTemporalLocked(address user) internal view returns (bool) {
        uint256 unlockTimestamp = temporalLocks[user][0];
        uint256 unlockBlock = temporalLocks[user][1];

        // Locked if lock exists AND (current time < unlock time OR current block < unlock block)
        return (unlockTimestamp > 0 || unlockBlock > 0) &&
               (block.timestamp < unlockTimestamp || block.number < unlockBlock);
    }

    /**
     * @dev Transfers ERC20 tokens out of the contract.
     * @param token The token address.
     * @param recipient The recipient address.
     * @param amount The amount to transfer.
     */
    function _transferERC20Out(address token, address recipient, uint256 amount) internal {
        require(userERC20Balances[msg.sender][token] >= amount, "Insufficient user balance in vault");
        userERC20Balances[msg.sender][token] = userERC20Balances[msg.sender][token].sub(amount);
        IMiniERC20(token).transfer(recipient, amount);
        emit ERC20Withdrawn(msg.sender, token, amount);
    }

     /**
     * @dev Transfers ERC721 token out of the contract.
     * @param token The token address.
     * @param recipient The recipient address.
     * @param tokenId The token ID to transfer.
     */
    function _transferERC721Out(address token, address recipient, uint256 tokenId) internal {
        require(userERC721Ownership[token][tokenId] == msg.sender, "User does not own this NFT in vault");
        userERC721Ownership[token][tokenId] = address(0); // Clear ownership within vault
        IMiniERC721(token).safeTransferFrom(address(this), recipient, tokenId);
        emit ERC721Withdrawn(msg.sender, token, tokenId);
    }

    // --- Deposit Functions ---

    /**
     * @notice Deposits ERC20 tokens into the vault. Requires prior approval.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        IMiniERC20(token).transferFrom(msg.sender, address(this), amount);
        userERC20Balances[msg.sender][token] = userERC20Balances[msg.sender][token].add(amount);
        emit ERC20Deposited(msg.sender, token, amount);
    }

    /**
     * @notice Deposits ERC721 token into the vault. Requires prior approval or transfer.
     * Contract must implement `ERC721Holder` or equivalent `onERC721Received`.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to deposit.
     */
    function depositERC721(address token, uint256 tokenId) public {
         // The transfer must be initiated externally (e.g., user calls token.safeTransferFrom(msg.sender, address(this), tokenId))
         // The ERC721Holder onERC721Received callback will handle updating internal ownership.
         // This function serves as a user-facing wrapper or instruction, but the actual transfer
         // is handled by the ERC721 standard's transfer mechanism interacting with ERC721Holder.
         // For simplicity, we'll assume the user calls safeTransferFrom on the token contract directly,
         // and onERC721Received updates our state. This function is just a placeholder or could
         // be used to require a call *after* the token transfer has completed.
         // For a practical example here, let's assume the standard ERC721 transfer happens first,
         // and this function *confirms* and logs it, requiring the vault to own the NFT.

         require(IMiniERC721(token).ownerOf(tokenId) == address(this), "Vault must own the NFT");
         // Check if it's already recorded or if it's a new deposit for this user
         require(userERC721Ownership[token][tokenId] == address(0) || userERC721Ownership[token][tokenId] == msg.sender, "NFT already owned by another user in vault");

         userERC721Ownership[token][tokenId] = msg.sender;
         emit ERC721Deposited(msg.sender, token, tokenId);
    }

    // Override ERC721Holder's onERC721Received to track internal ownership
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) override external returns (bytes4) {
         // This function is called by the ERC721 contract when a token is transferred *to* this vault.
         // We need to record who the original owner was ('from') to manage their "vault" balance.
         // This logic assumes 'from' is the user depositing.
         // A more robust system might require an external call to `depositERC721` *after* this.
         // For simplicity in this example, we'll record 'from' as the internal owner.

         address token = msg.sender; // msg.sender is the ERC721 contract address
         userERC721Ownership[token][tokenId] = from; // 'from' is the actual depositor

         // Note: We don't emit deposit event here, assuming depositERC721 is called separately
         // after the transfer or this logic is embedded within depositERC721 itself.
         // Let's add the event emission here assuming deposit happens via transfer first.
         emit ERC721Deposited(from, token, tokenId);

         return this.onERC721Received.selector;
    }


    // --- Withdrawal Functions (Subject to Conditions) ---

    /**
     * @notice Attempts to withdraw ERC20 tokens under standard conditions.
     * Access may be blocked by Temporal Locks, and amount may be affected by State Entanglement.
     * Cannot withdraw amounts currently in Superposition.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20_Standard(address token, uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(!_isTemporalLocked(msg.sender), "Access is temporally locked");
        // Cannot withdraw amounts currently in Superposition via standard withdrawal
        require(userERC20Balances[msg.sender][token] >= amount + superpositionERC20[msg.sender][token][0], "Amount exceeds available balance (excl superposition)");
        require(userERC20Balances[msg.sender][token] >= amount, "Insufficient available balance in vault");

        // Apply state entanglement effects if any
        triggerStateEntanglement_WithdrawERC20(token, amount); // This might reduce/increase other balances

        _transferERC20Out(token, msg.sender, amount);
    }

    /**
     * @notice Attempts to withdraw ERC721 token under standard conditions.
     * Access may be blocked by Temporal Locks. Cannot withdraw NFTs currently in Superposition.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to withdraw.
     */
    function withdrawERC721_Standard(address token, uint256 tokenId) public {
        require(!_isTemporalLocked(msg.sender), "Access is temporally locked");
        require(userERC721Ownership[token][tokenId] == msg.sender, "User does not own this NFT in vault");
        // Cannot withdraw if in Superposition
        require(superpositionERC721[msg.sender][token][tokenId] == 0, "NFT is in superposition state");

        _transferERC721Out(token, msg.sender, tokenId);
    }


    // --- Entanglement Functions ---

    /**
     * @notice Owner sets up an entanglement between two user addresses.
     * Actions by `addressA` may probabilistically affect `addressB`.
     * @param addressA The first address in the pair.
     * @param addressB The second address in the pair.
     * @param probability The probability (0-100) that an effect is triggered on B when A acts.
     */
    function setEntangledPair_Address(address addressA, address addressB, uint8 probability) public onlyOwner {
        require(addressA != address(0) && addressB != address(0), "Addresses cannot be zero");
        require(addressA != addressB, "Addresses must be different");
        require(entangledPairs[addressA][addressB] == 0, "Pair is already set"); // Simple 1-to-1 linking for this example

        entangledPairs[addressA][addressB] = probability;
        entangledReverseLookup[addressB] = addressA;
        emit EntangledPairSet(addressA, addressB, probability);
    }

    /**
     * @notice Owner removes an address entanglement starting from `addressA`.
     * @param addressA The first address in the pair to remove.
     */
    function unsetEntangledPair_Address(address addressA) public onlyOwner {
        address addressB = address(0);
        for (uint8 i = 0; i <= 100; i++) { // Find entangled B if exists
            if (entangledPairs[addressA][address(i)] > 0) { // Iterate through possible probabilities (hacky way to find B)
                addressB = address(i); // This won't work reliably. A proper mapping or list is needed.
                                        // Let's rethink entanglement storage slightly for removal.
                                        // A direct mapping from A to B is better: {addressA => addressB}
                break;
            }
        }
         // Corrected logic assuming {addressA => addressB} mapping instead of {addressA => {addressB => prob}} for primary lookup
        address addressB_correct = entangledReverseLookup[addressA]; // Using reverse lookup assuming B is linked to A
        require(addressB_correct != address(0), "No entanglement found for this address");

        uint8 prob = entangledPairs[addressA][addressB_correct]; // Get probability before clearing
        delete entangledPairs[addressA][addressB_correct];
        delete entangledReverseLookup[addressB_correct]; // Assuming B is linked to A

        emit EntangledPairUnset(addressA);
    }
     // --- Let's simplify entanglement structure for the example: A single A -> B link with probability stored directly ---
     // {addressA => {addressB, probability}}
     mapping(address => address) private entangledAddressPair;
     mapping(address => uint8) private entangledAddressProbability;

     function setEntangledPair_Address_Simplified(address addressA, address addressB, uint8 probability) public onlyOwner {
         require(addressA != address(0) && addressB != address(0), "Addresses cannot be zero");
         require(addressA != addressB, "Addresses must be different");
         require(entangledAddressPair[addressA] == address(0), "addressA is already entangled");

         entangledAddressPair[addressA] = addressB;
         entangledAddressProbability[addressA] = probability;
         emit EntangledPairSet(addressA, addressB, probability);
     }

     function unsetEntangledPair_Address_Simplified(address addressA) public onlyOwner {
         address addressB = entangledAddressPair[addressA];
         require(addressB != address(0), "No entanglement found for this addressA");

         delete entangledAddressPair[addressA];
         delete entangledAddressProbability[addressA];
         emit EntangledPairUnset(addressA);
     }


    /**
     * @notice Callable by an entangled user (`addressA`). May trigger a probabilistic effect on `addressB`.
     * Effects could include temporarily locking B's funds, putting some of B's funds into superposition, etc.
     * @param user The address triggering the effect (must be the 'A' address in an entangled pair).
     */
    function triggerEntanglementEffect_User(address user) public {
        address addressB = entangledAddressPair[user];
        require(addressB != address(0) && user == msg.sender, "User is not the 'A' address in an entangled pair");

        uint8 probability = entangledAddressProbability[user];
        bool effectOccurred = _checkProbabilisticOutcome(probability, uint256(uint160(user)) + uint256(uint160(addressB)));

        if (effectOccurred) {
            // Example Effect: Put 10% of addressB's random ERC20 balance into superposition
            // (In a real contract, this would need careful design - iterating tokens is gas-intensive)
            // For simplicity, let's just apply a temporary temporal lock on addressB.
            uint256 lockDuration = 1 hours; // Example effect
            uint256 lockBlocks = 100; // Example effect
            temporalLocks[addressB][0] = block.timestamp + lockDuration;
            temporalLocks[addressB][1] = block.number + lockBlocks;
            emit TemporalLockSet(addressB, temporalLocks[addressB][0], temporalLocks[addressB][1]);
            // Could also trigger other effects like putting a small amount into superposition
            // if (userERC20Balances[addressB][someToken] > 0) {
            //    uint256 amountToSuperpose = userERC20Balances[addressB][someToken] / 10; // 10%
            //    if (amountToSuperpose > 0) {
            //        superpositionERC20[addressB][someToken][0] = superpositionERC20[addressB][someToken][0].add(amountToSuperpose);
            //        superpositionERC20[addressB][someToken][1] = 50; // 50% chance to get it back
            //        emit ERC20EnteredSuperposition(addressB, someToken, amountToSuperpose, 50);
            //    }
            // }
        }

        emit EntanglementEffectTriggered(user, addressB, effectOccurred);
    }


    // --- Temporal Phase Lock Functions ---

    /**
     * @notice Owner sets a temporal lock for a user's access to the vault.
     * Withdrawal functions will be blocked until both the specified timestamp and block number are reached.
     * Setting unlockTimestamp/unlockBlock to 0 removes the lock.
     * @param user The address to lock.
     * @param unlockTimestamp The timestamp when the lock expires.
     * @param unlockBlock The block number when the lock expires.
     */
    function setTemporalPhaseLock_Address(address user, uint256 unlockTimestamp, uint256 unlockBlock) public onlyOwner {
        require(user != address(0), "User address cannot be zero");
        temporalLocks[user][0] = unlockTimestamp;
        temporalLocks[user][1] = unlockBlock;
        emit TemporalLockSet(user, unlockTimestamp, unlockBlock);
    }

    /**
     * @notice Owner removes a temporal lock for a user.
     * @param user The address to unlock.
     */
    function unsetTemporalPhaseLock_Address(address user) public onlyOwner {
         setTemporalPhaseLock_Address(user, 0, 0); // Setting to 0 effectively removes the lock
         emit TemporalLockUnset(user);
    }

    // --- Superposition Functions ---

    /**
     * @notice User can place a specific amount of their ERC20 balance into a superposition state.
     * Withdrawal from this state via `collapseSuperpositionAndWithdraw_ERC20` will have a probabilistic outcome.
     * The amount is moved from standard balance to superposition balance.
     * @param token The address of the ERC20 token.
     * @param amount The amount to place into superposition.
     * @param successProbability The probability (0-100) of successfully withdrawing this amount later.
     */
    function enterSuperposition_ERC20(address token, uint256 amount, uint8 successProbability) public {
        require(amount > 0, "Amount must be greater than 0");
        require(userERC20Balances[msg.sender][token] >= amount, "Insufficient available balance");
        require(successProbability <= 100, "Probability must be <= 100");
        require(superpositionERC20[msg.sender][token][0] == 0, "Token already has amount in superposition"); // Simple: only one superposition state per token per user

        userERC20Balances[msg.sender][token] = userERC20Balances[msg.sender][token].sub(amount);
        superpositionERC20[msg.sender][token][0] = amount;
        superpositionERC20[msg.sender][token][1] = successProbability;
        emit ERC20EnteredSuperposition(msg.sender, token, amount, successProbability);
    }

    /**
     * @notice Attempts to withdraw ERC20 from a superposition state.
     * The outcome (final amount received) is determined probabilistically based on the state's probability.
     * The superposition state is then cleared.
     * @param token The address of the ERC20 token.
     */
    function collapseSuperpositionAndWithdraw_ERC20(address token) public {
        uint256 amountInSuperposition = superpositionERC20[msg.sender][token][0];
        uint8 successProbability = superpositionERC20[msg.sender][token][1];

        require(amountInSuperposition > 0, "No ERC20 amount in superposition for this token");
        require(!decoherenceActive, "Decoherence is active, cannot collapse superposition");

        uint256 finalAmountReceived = 0;
        if (_checkProbabilisticOutcome(successProbability, uint256(uint160(msg.sender)) + amountInSuperposition + block.number)) {
             finalAmountReceived = amountInSuperposition;
        }

        // Clear superposition state regardless of outcome
        delete superpositionERC20[msg.sender][token];

        if (finalAmountReceived > 0) {
             userERC20Balances[msg.sender][token] = userERC20Balances[msg.sender][token].add(finalAmountReceived); // Add back to standard balance
             _transferERC20Out(token, msg.sender, finalAmountReceived); // Then withdraw
        }

        emit ERC20SuperpositionCollapsed(msg.sender, token, amountInSuperposition, finalAmountReceived);
    }

    /**
     * @notice User can place an ERC721 token into a superposition state.
     * Withdrawal from this state via `collapseSuperpositionAndWithdraw_ERC721` will have a probabilistic outcome (success or failure).
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to place into superposition.
     * @param successProbability The probability (0-100) of successfully withdrawing this token later.
     */
    function enterSuperposition_ERC721(address token, uint256 tokenId, uint8 successProbability) public {
        require(userERC721Ownership[token][tokenId] == msg.sender, "User does not own this NFT in vault");
        require(successProbability <= 100, "Probability must be <= 100");
         require(superpositionERC721[msg.sender][token][tokenId] == 0, "NFT is already in superposition");

        superpositionERC721[msg.sender][token][tokenId] = successProbability;
        emit ERC721EnteredSuperposition(msg.sender, token, tokenId, successProbability);
    }

    /**
     * @notice Attempts to withdraw an ERC721 from a superposition state.
     * The outcome (success or failure) is determined probabilistically based on the state's probability.
     * The superposition state is then cleared.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to withdraw.
     */
    function collapseSuperpositionAndWithdraw_ERC721(address token, uint256 tokenId) public {
        uint8 successProbability = superpositionERC721[msg.sender][token][tokenId];

        require(successProbability > 0, "NFT is not in a valid superposition state"); // Check if state exists
        require(userERC721Ownership[token][tokenId] == msg.sender, "User does not own this NFT in vault");
        require(!decoherenceActive, "Decoherence is active, cannot collapse superposition");

        bool success = _checkProbabilisticOutcome(successProbability, uint256(uint160(msg.sender)) + tokenId + block.number);

        // Clear superposition state regardless of outcome
        delete superpositionERC721[msg.sender][token][tokenId];

        if (success) {
            _transferERC721Out(token, msg.sender, tokenId);
        }

        emit ERC721SuperpositionCollapsed(msg.sender, token, tokenId, success);
    }


    // --- Quantum Tunneling Functions ---

    /**
     * @notice Owner sets parameters for quantum tunneling attempts.
     * @param probabilityPercent The probability (0-100) of successful tunneling.
     * @param requiredFee The ETH fee required for each attempt.
     */
    function setQuantumTunnelingParams(uint8 probabilityPercent, uint256 requiredFee) public onlyOwner {
        require(probabilityPercent <= 100, "Probability must be <= 100");
        quantumTunnelingProbabilityPercent = probabilityPercent;
        quantumTunnelingFee = requiredFee;
    }

    /**
     * @notice Attempts to withdraw ERC20, potentially bypassing temporal locks and some entanglement effects, with a low probability and required fee.
     * @param token The address of the ERC20 token.
     * @param amount The amount to attempt to withdraw.
     */
    function attemptQuantumTunnel_ERC20(address token, uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");
        require(msg.value >= quantumTunnelingFee, "Insufficient tunneling fee");
        require(userERC20Balances[msg.sender][token] >= amount, "Insufficient balance in vault");
        require(!decoherenceActive, "Decoherence is active, tunneling is disabled");
        require(quantumTunnelingProbabilityPercent > 0, "Tunneling is disabled or misconfigured");

        bool success = _checkProbabilisticOutcome(quantumTunnelingProbabilityPercent, uint256(uint160(msg.sender)) + amount + block.timestamp);

        if (success) {
            // Bypass checks and transfer
             userERC20Balances[msg.sender][token] = userERC20Balances[msg.sender][token].sub(amount); // Update internal balance first
            IMiniERC20(token).transfer(msg.sender, amount); // Transfer the token
             // Fee is kept by the contract (sent to owner via Ownable mechanism or managed separately)
        } else {
            // Fee is kept as cost of attempt
        }

        emit QuantumTunnelAttempt(msg.sender, token, amount, success, msg.value);
    }

    /**
     * @notice Attempts to withdraw ERC721, potentially bypassing temporal locks and some entanglement effects, with a low probability and required fee.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the token to attempt to withdraw.
     */
    function attemptQuantumTunnel_ERC721(address token, uint256 tokenId) public payable {
        require(msg.value >= quantumTunnelingFee, "Insufficient tunneling fee");
        require(userERC721Ownership[token][tokenId] == msg.sender, "User does not own this NFT in vault");
         require(!decoherenceActive, "Decoherence is active, tunneling is disabled");
         require(quantumTunnelingProbabilityPercent > 0, "Tunneling is disabled or misconfigured");


        bool success = _checkProbabilisticOutcome(quantumTunnelingProbabilityPercent, uint256(uint160(msg.sender)) + tokenId + block.timestamp);

        if (success) {
            // Bypass checks and transfer
            userERC721Ownership[token][tokenId] = address(0); // Clear internal ownership
            IMiniERC721(token).safeTransferFrom(address(this), msg.sender, tokenId); // Transfer the NFT
            // Fee is kept
        } else {
            // Fee is kept as cost of attempt
        }

         emit QuantumTunnelAttempt(msg.sender, token, tokenId, success, msg.value);
    }


    // --- State Entanglement Functions ---

    /**
     * @notice Owner links the *amounts* held by a user for two different ERC20 tokens (tokenA and tokenB).
     * When the user withdraws tokenA, the amount of tokenB they hold may be probabilistically affected (reduced or increased slightly) based on linkage strength.
     * @param user The user whose balances are linked.
     * @param tokenA The first token in the link (withdrawal triggers effect).
     * @param tokenB The second token in the link (amount is affected).
     * @param linkageStrength The strength (0-100) of the linkage. Higher strength means stronger potential effect.
     */
    function setStateEntanglement_ERC20Amount(address user, address tokenA, address tokenB, uint8 linkageStrength) public onlyOwner {
        require(user != address(0) && tokenA != address(0) && tokenB != address(0), "Addresses cannot be zero");
        require(tokenA != tokenB, "Tokens must be different");
        require(linkageStrength <= 100, "Linkage strength must be <= 100");

        stateEntanglementERC20[user][tokenA][tokenB] = linkageStrength;
        emit StateEntanglementERC20Set(user, tokenA, tokenB, linkageStrength);
    }

    /**
     * @notice Internal helper function called during ERC20 withdrawal to apply state entanglement effects.
     * @param tokenWithdrawn The token being withdrawn.
     * @param amountWithdrawn The amount being withdrawn.
     */
    function triggerStateEntanglement_WithdrawERC20(address tokenWithdrawn, uint256 amountWithdrawn) internal {
        address user = msg.sender;
        // Find if the tokenWithdrawn is linked to any other token for this user
        // (Iterating through *all* possible tokens is gas-prohibitive on-chain.
        // In a real system, we'd need a mapping or list of linked token pairs per user, managed off-chain or via helper functions.)
        // For demonstration, let's assume a hardcoded check for a specific linked pair, or iterate a small list if we tracked it.
        // Let's simplify and assume the mapping `stateEntanglementERC20[user][tokenA][tokenB]` is directly queried.

        // Example: Check if tokenWithdrawn is linked to tokenB for msg.sender
        // We need to know what tokenB could be linked to tokenWithdrawn (as tokenA)
        // This structure {user => {tokenA => {tokenB => strength}}} means we need to find all tokenBs linked to tokenA for the user.
        // Again, iterating all possible tokens for tokenB is bad.

        // Simplified Example: Assume we only support ONE state entanglement pair per user: LINK->ETH.
        // If user withdraws LINK, ETH balance is affected.
        address tokenA_Example = address(0x...); // Example LINK address
        address tokenB_Example = address(0x...); // Example WETH address

        uint8 linkageStrength = stateEntanglementERC20[user][tokenWithdrawn][tokenB_Example];

        if (linkageStrength > 0 && tokenWithdrawn == tokenA_Example) {
            uint256 userBalanceB = userERC20Balances[user][tokenB_Example];
            if (userBalanceB > 0) {
                 // Probabilistically affect tokenB balance based on withdrawal amount and strength
                 uint256 seed = uint256(keccak256(abi.encodePacked(user, tokenWithdrawn, amountWithdrawn, tokenB_Example, block.number, block.timestamp)));
                 uint256 randomFactor = (seed % 100) + 1; // 1 to 100

                 // Effect: Reduce tokenB balance by up to 1% of amountWithdrawn, scaled by linkageStrength and random factor
                 uint256 potentialReduction = amountWithdrawn.mul(linkageStrength).div(100).mul(randomFactor).div(10000); // (amount * strength/100 * randomFactor/100) / 100

                 if (userBalanceB > potentialReduction) {
                     userERC20Balances[user][tokenB_Example] = userERC20Balances[user][tokenB_Example].sub(potentialReduction);
                 } else {
                     userERC20Balances[user][tokenB_Example] = 0; // Reduce to zero if reduction is more than balance
                 }
                 // Log this effect
                 emit StateEntanglementERC20Applied(user, tokenWithdrawn, tokenB_Example, amountWithdrawn, potentialReduction);
            }
        }
         // Note: State entanglement could also *increase* balances probabilistically, or affect other states.
         // This example is a simple reduction effect.
    }
     event StateEntanglementERC20Applied(address indexed user, address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 affectedAmountB);


    // --- Decoherence Functions ---

    /**
     * @notice Owner designates an address that can trigger decoherence.
     * @param _decoherenceAddress The address authorized to trigger decoherence.
     */
    function setDecoherenceTriggerAddress(address _decoherenceAddress) public onlyOwner {
        require(_decoherenceAddress != address(0), "Decoherence trigger address cannot be zero");
        decoherenceTriggerAddress = _decoherenceAddress;
        emit DecoherenceTriggerAddressSet(_decoherenceAddress);
    }

    /**
     * @notice Triggers a decoherence event.
     * Callable only by the designated decoherence trigger address.
     * Collapses all active superposition states for all users and temporarily disables quantum tunneling.
     * Decoherence lasts for a set duration (e.g., 1 hour).
     */
    function triggerDecoherence() public {
        require(msg.sender == decoherenceTriggerAddress, "Not authorized to trigger decoherence");
        require(!decoherenceActive, "Decoherence is already active");

        decoherenceActive = true;
        decoherenceEndTime = block.timestamp + 1 hours; // Decoherence lasts for 1 hour (example)

        // In a real contract, iterating through *all* users and their superposition states
        // to collapse them would be extremely gas-expensive or impossible.
        // A practical implementation might only collapse states on the *next interaction* by the user,
        // or use a different state mechanism.
        // For this conceptual example, we'll just set the flag and state that states *should* be treated as collapsed.
        // The collapse logic within the collapse functions will check `decoherenceActive`.

        emit DecoherenceTriggered(msg.sender);
    }

     /**
      * @dev Internal function to check and potentially end decoherence.
      */
     function _checkDecoherenceStatus() internal {
         if (decoherenceActive && block.timestamp >= decoherenceEndTime) {
             decoherenceActive = false;
             decoherenceEndTime = 0;
             emit DecoherenceEnded();
         }
     }
     event DecoherenceEnded();


    // --- Quantum Key System ---

    /**
     * @notice User generates a temporary quantum key.
     * This key is required for certain sensitive actions for a limited time.
     * Generates a new key, invalidating any previous one for the user.
     */
    function generateQuantumKey() public {
        uint256 newKey = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, _generatePseudorandom(uint256(uint160(msg.sender))))));
        uint256 expiry = block.timestamp + quantumKeyValidityDuration;

        quantumKeys[msg.sender][0] = newKey;
        quantumKeys[msg.sender][1] = expiry;
        emit QuantumKeyGenerated(msg.sender, newKey, expiry);
    }

    /**
     * @notice Withdraws ERC20 tokens requiring a valid quantum key.
     * Key must match the user's currently active key and not be expired.
     * @param token The address of the ERC20 token.
     * @param amount The amount to withdraw.
     * @param key The quantum key to use.
     */
    function withdrawERC20_WithKey(address token, uint256 amount, uint256 key) public {
        require(amount > 0, "Amount must be greater than 0");
        require(quantumKeys[msg.sender][0] != 0, "No quantum key generated or it was used");
        require(quantumKeys[msg.sender][0] == key, "Invalid quantum key");
        require(block.timestamp < quantumKeys[msg.sender][1], "Quantum key expired");
        require(userERC20Balances[msg.sender][token] >= amount, "Insufficient balance in vault");

        // Invalidate the key after use (simple example, could allow multiple uses until expiry)
        delete quantumKeys[msg.sender];
        emit QuantumKeyUsed(msg.sender, key);

        // Proceed with withdrawal (standard checks like temporal lock could still apply, or not, based on design)
        // Let's assume standard locks DO apply even with key for this example's complexity
        require(!_isTemporalLocked(msg.sender), "Access is temporally locked");
        // Cannot withdraw amounts currently in Superposition via this method either
        require(userERC20Balances[msg.sender][token] >= amount + superpositionERC20[msg.sender][token][0], "Amount exceeds available balance (excl superposition)");


        _transferERC20Out(token, msg.sender, amount);
    }

    // --- Probabilistic Swap ---

    /**
     * @notice Allows a user to swap an amount of one ERC20 for another *within their vault balance*.
     * The outcome amount of `tokenOut` is determined probabilistically based on a random factor within the specified percentage range of a 1:1 swap.
     * Example: minOutcomePercent=95, maxOutcomePercent=105 means the user gets between 95% and 105% of `amountIn` of tokenOut.
     * @param tokenIn The ERC20 token the user wants to swap from.
     * @param tokenOut The ERC20 token the user wants to receive.
     * @param amountIn The amount of tokenIn to swap.
     * @param minOutcomePercent The minimum percentage (0-100) of a 1:1 swap to receive (e.g., 95 for 95%).
     * @param maxOutcomePercent The maximum percentage (>= minOutcomePercent, <= 200) of a 1:1 swap to receive (e.g., 105 for 105%).
     */
    function probabilisticAssetSwap_ERC20(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8 minOutcomePercent,
        uint8 maxOutcomePercent
    ) public {
        require(amountIn > 0, "Amount must be greater than 0");
        require(tokenIn != tokenOut, "Tokens must be different");
        require(userERC20Balances[msg.sender][tokenIn] >= amountIn, "Insufficient tokenIn balance in vault");
        require(minOutcomePercent >= 0 && minOutcomePercent <= 100, "Min outcome percent must be 0-100"); // Typically > 0 for value
        require(maxOutcomePercent >= minOutcomePercent && maxOutcomePercent <= 200, "Max outcome percent must be between min and 200"); // Prevent excessive gains
        // This requires the contract to hold *both* tokenIn and tokenOut balances sufficient for the swap outcomes.
        // In a real AMM, liquidity is provided. Here, the contract acts as the counterparty using its own holdings.
        // This simple version assumes the contract *can* always fulfill the outcome. A robust version would check contract balances.

        userERC20Balances[msg.sender][tokenIn] = userERC20Balances[msg.sender][tokenIn].sub(amountIn);

        // Calculate outcome percentage probabilistically
        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, tokenIn, tokenOut, amountIn, block.number, block.timestamp, _generatePseudorandom(amountIn))));
        uint256 range = maxOutcomePercent - minOutcomePercent;
        uint256 randomPercent = (seed % (range + 1)) + minOutcomePercent; // Random percent between minOutcomePercent and maxOutcomePercent

        // Calculate amountOut based on random percentage of amountIn (assuming 1:1 base rate)
        uint256 amountOut = amountIn.mul(randomPercent).div(100);

        // Add amountOut to user's tokenOut balance in vault
        userERC20Balances[msg.sender][tokenOut] = userERC20Balances[msg.sender][tokenOut].add(amountOut);

        emit ProbabilisticSwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        // Note: This function swaps *within* the vault. User needs to withdraw later.
    }


    // --- Owner Emergency Functions ---

    /**
     * @notice Owner can withdraw all balances of a specific ERC20 token held by the contract (across all users).
     * Use with extreme caution. This bypasses all user-specific logic and emergency withdrawals.
     * @param token The address of the ERC20 token to withdraw.
     */
    function emergencyWithdrawAllERC20(address token) public onlyOwner {
        uint256 totalBalance = IMiniERC20(token).balanceOf(address(this));
        require(totalBalance > 0, "No balance of this token in the contract");

        // This empties the contract's token balance, but does NOT reset user ERC20 balances mapping.
        // This is an emergency measure, likely requiring off-chain or manual user balance adjustments if used outside full contract shutdown.
        IMiniERC20(token).transfer(owner(), totalBalance);

        // Consider clearing user balances in mapping if this implies a full shutdown or specific recovery
        // mapping(address => mapping(address => uint256)) private userERC20Balances;
        // This would be gas intensive. A better approach might be to mark contract as "emergency withdrawn"

        emit EmergencyWithdrawalERC20(owner(), token, totalBalance);
    }

     /**
     * @notice Owner can withdraw specific ERC721 tokens held by the contract.
     * Use with extreme caution. Bypasses user ownership mapping and logic.
     * @param token The address of the ERC721 token.
     * @param tokenIds An array of token IDs to withdraw.
     */
    function emergencyWithdrawAllERC721(address token, uint256[] memory tokenIds) public onlyOwner {
        IMiniERC721 tokenContract = IMiniERC721(token);
        for(uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            // Check if the contract actually owns the token
            if (tokenContract.ownerOf(tokenId) == address(this)) {
                 // Clear internal ownership tracking (assuming it exists)
                 delete userERC721Ownership[token][tokenId];
                 // Transfer to owner
                 tokenContract.safeTransferFrom(address(this), owner(), tokenId);
                 emit EmergencyWithdrawalERC721(owner(), token, tokenId);
            }
        }
    }


    // --- Query Functions ---

    /**
     * @notice View a user's standard ERC20 balance held in the vault (excluding superposition).
     * @param user The user's address.
     * @param token The ERC20 token address.
     * @return The standard balance.
     */
    function queryUserERC20Balance(address user, address token) public view returns (uint256) {
        return userERC20Balances[user][token];
    }

    /**
     * @notice View the internal owner of an ERC721 token held by the vault.
     * @param token The ERC721 token address.
     * @param tokenId The token ID.
     * @return The address of the user who deposited/internally owns the NFT, or address(0) if not in vault or not assigned.
     */
    function queryUserERC721Owner(address token, uint256 tokenId) public view returns (address) {
         // First, verify the vault actually owns the NFT
         if (IMiniERC721(token).ownerOf(tokenId) != address(this)) {
             return address(0); // Vault doesn't hold it
         }
         // Then, return the internally tracked owner
         return userERC721Ownership[token][tokenId];
    }

     /**
      * @notice View which address `userA` is entangled with.
      * @param userA The address to check entanglement for.
      * @return The address userA is entangled with, or address(0) if not entangled.
      */
    function queryEntangledPair(address userA) public view returns (address) {
         return entangledAddressPair[userA];
    }

     /**
      * @notice View the temporal lock status for a user.
      * @param user The user's address.
      * @return A tuple containing the unlock timestamp and unlock block number. Returns (0, 0) if not locked.
      */
    function queryTemporalLock(address user) public view returns (uint256 unlockTimestamp, uint256 unlockBlock) {
         return (temporalLocks[user][0], temporalLocks[user][1]);
    }

     /**
      * @notice View the superposition state for an ERC20 token amount for a user.
      * @param user The user's address.
      * @param token The ERC20 token address.
      * @return A tuple containing the amount in superposition and the success probability (0-100). Returns (0, 0) if not in superposition.
      */
    function querySuperpositionState_ERC20(address user, address token) public view returns (uint256 amountInSuperposition, uint8 successProbability) {
         return (superpositionERC20[user][token][0], uint8(superpositionERC20[user][token][1]));
    }

    /**
     * @notice View the superposition state for an ERC721 token for a user.
     * @param user The user's address.
     * @param token The ERC721 token address.
     * @param tokenId The token ID.
     * @return The success probability (0-100) of withdrawing this token from superposition. Returns 0 if not in superposition.
     */
    function querySuperpositionState_ERC721(address user, address token, uint256 tokenId) public view returns (uint8 successProbability) {
        return superpositionERC721[user][token][tokenId];
    }

    /**
     * @notice View the current quantum tunneling parameters.
     * @return A tuple containing the probability percent (0-100) and the required ETH fee.
     */
    function queryQuantumTunnelingParams() public view returns (uint8 probabilityPercent, uint256 requiredFee) {
         return (quantumTunnelingProbabilityPercent, quantumTunnelingFee);
    }

    /**
     * @notice View the current quantum key and expiry for a user.
     * @param user The user's address.
     * @return A tuple containing the key and its expiry timestamp. Returns (0, 0) if no key generated or it was used/expired.
     */
    function queryQuantumKey(address user) public view returns (uint256 key, uint256 expiry) {
        // Check if key is expired before returning
        if (quantumKeys[user][0] != 0 && block.timestamp < quantumKeys[user][1]) {
            return (quantumKeys[user][0], quantumKeys[user][1]);
        } else {
            return (0, 0); // Key is expired or not set
        }
    }

    /**
     * @notice View the current decoherence status.
     * @return True if decoherence is active, false otherwise.
     */
    function queryDecoherenceStatus() public view returns (bool) {
        // Check and potentially end decoherence just before returning status
        // (This is a simplified check; actual state change needs a non-view function call)
        // For true state update, _checkDecoherenceStatus() would need to be called in a mutable function.
        // For view, we just check the condition based on current block.timestamp.
        if (decoherenceActive && block.timestamp >= decoherenceEndTime) {
            return false; // Condition to end decoherence met, though state might not be updated yet
        }
        return decoherenceActive;
    }

     /**
     * @notice View the state entanglement linkage between two ERC20 tokens for a user.
     * @param user The user's address.
     * @param tokenA The first token in the potential linkage.
     * @param tokenB The second token in the potential linkage.
     * @return The linkage strength (0-100). Returns 0 if no linkage exists.
     */
    function queryStateEntanglement(address user, address tokenA, address tokenB) public view returns (uint8) {
        return stateEntanglementERC20[user][tokenA][tokenB];
    }


    // --- Ownable Overrides ---

    /**
     * @notice Transfers ownership of the contract to a new address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

     /**
      * @notice Renounces ownership of the contract.
      * Can only be called by the current owner.
      * The contract will not have an owner afterward, making some functions inaccessible.
      */
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    // Fallback and Receive functions to accept ETH for Quantum Tunneling Fee
    receive() external payable {}
    fallback() external payable {}
}
```