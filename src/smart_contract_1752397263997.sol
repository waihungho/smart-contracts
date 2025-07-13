Okay, here is a Solidity smart contract concept called `QuantumVault`. It attempts to be interesting and advanced by combining:

1.  **Multi-Asset Management:** Handles ETH, ERC20, and ERC721.
2.  **Complex Conditional Access Policies:** Withdrawal is based on meeting multiple, configurable criteria, not just simple ownership or time locks.
3.  **Oracle Integration:** Policies can depend on external data verified via trusted oracles.
4.  **Internal State Dependency:** Policies can depend on internal contract state variables ("Quantum State").
5.  **Dynamic Factors (Entropy):** Withdrawal amounts or conditions can change over time or based on state, introducing a decay or complexity factor.
6.  **Role-Based Policy Creation:** Control who can define the complex rules.

This contract is *not* a standard vault, vesting contract, or simple timelock. It's designed for scenarios requiring highly customized and dynamic conditions for asset release.

---

**Outline and Function Summary**

This contract, `QuantumVault`, serves as a secure vault capable of holding various assets (ETH, ERC20, ERC721). Access to these assets for withdrawal is governed by complex, multi-conditional *Policies*.

**Core Concepts:**

*   **Assets:** Can hold ETH, any ERC20, any ERC721.
*   **Policies:** Define the rules for withdrawing a *specific* asset (or type/amount). Each policy has a unique ID and requires *all* associated `Condition` objects to be met.
*   **Conditions:** Specific criteria that must be true for a policy to be valid. Examples include:
    *   Timestamp reached.
    *   External Oracle data matching a required value.
    *   Internal "Quantum State" variable matching a required value.
    *   Requiring the user to hold a specific NFT.
    *   Requiring the user to hold a minimum balance of a specific ERC20 token.
*   **Oracle Integration:** The contract can store trusted oracle addresses and verify conditions that rely on off-chain data by calling these oracles.
*   **Internal State ("Quantum State"):** Key-value mapping within the contract that can be updated by the owner and used as conditions in policies. This adds a layer of internal dependency.
*   **Entropy:** A dynamic factor tied to policies that can affect the amount withdrawn or the policy's state over time or based on internal state changes. (Implemented here as a time-based decay example).
*   **Roles:** Specific roles (like `POLICY_CREATOR_ROLE`) can be granted by the owner to allow certain addresses to create or modify policies.

**Function Summary:**

**I. Asset Deposits (3 Functions)**
1.  `depositETH()`: Receive native Ether into the vault.
2.  `depositERC20(address tokenAddress, uint256 amount)`: Receive a specified amount of an ERC20 token. Requires prior approval.
3.  `depositERC721(address tokenAddress, uint256 tokenId)`: Receive a specific ERC721 token. Requires prior approval or using `onERC721Received`.

**II. Asset Balance & Holding Views (3 Functions)**
4.  `getETHBalance() view`: Check the current ETH balance held by the contract.
5.  `getERC20Balance(address tokenAddress) view`: Check the balance of a specific ERC20 token held by the contract.
6.  `isHoldingERC721(address tokenAddress, uint256 tokenId) view`: Check if the contract holds a specific ERC721 token.

**III. Policy Management (7 Functions)**
7.  `createPolicy(Asset calldata targetAsset, Condition[] calldata conditions, EntropyParams calldata entropyParams)`: Create a new, complex withdrawal policy. Requires `POLICY_CREATOR_ROLE`.
8.  `getPolicy(uint256 policyId) view`: Retrieve the details of a specific policy.
9.  `updatePolicyConditions(uint256 policyId, Condition[] calldata newConditions) onlyOwner`: Update the conditions of an existing policy.
10. `togglePolicyActive(uint256 policyId, bool active) onlyOwner`: Activate or deactivate a policy.
11. `deletePolicy(uint256 policyId) onlyOwner`: Permanently remove a policy. Does NOT affect assets.
12. `getAllPolicyIds() view`: Get a list of all policy IDs that have been created.
13. `getPolicyEntropyParams(uint256 policyId) view`: Retrieve the entropy parameters for a policy.

**IV. Conditional Withdrawal (3 Functions)**
14. `withdrawETH(uint256 policyId, bytes calldata oracleProofData)`: Attempt to withdraw ETH using a specific policy, providing potential oracle data.
15. `withdrawERC20(address tokenAddress, uint256 policyId, bytes calldata oracleProofData)`: Attempt to withdraw ERC20 using a specific policy, providing potential oracle data.
16. `withdrawERC721(address tokenAddress, uint256 tokenId, uint256 policyId, bytes calldata oracleProofData)`: Attempt to withdraw ERC721 using a specific policy, providing potential oracle data.

**V. Internal State ("Quantum State") Management (2 Functions)**
17. `updateInternalState(bytes32 stateKey, uint256 newValue) onlyOwner`: Update an internal state variable.
18. `getInternalState(bytes32 stateKey) view`: Retrieve the value of an internal state variable.

**VI. Oracle Management (2 Functions)**
19. `setOracleAddress(bytes32 oracleKey, address oracleContract) onlyOwner`: Set the trusted address for a specific type of oracle data.
20. `getOracleAddress(bytes32 oracleKey) view`: Get the trusted address for a specific oracle key.

**VII. Role Management (2 Functions)**
21. `setPolicyCreatorRole(address account, bool enabled) onlyOwner`: Grant or revoke the `POLICY_CREATOR_ROLE`.
22. `hasPolicyCreatorRole(address account) view`: Check if an address has the `POLICY_CREATOR_ROLE`.

**VIII. Entropy & Condition Evaluation (3 Functions)**
23. `getCurrentEntropyFactor(uint256 policyId) view`: Calculate the current entropy factor for a policy. (Based on time and stored params).
24. `canWithdrawWithPolicy(uint256 policyId, address user, bytes calldata oracleProofData) view`: Public helper to check if a user can currently withdraw using a policy *without* attempting withdrawal. Provides details on which conditions are met.
25. `checkPolicyConditions(uint256 policyId, address user, bytes calldata oracleProofData) internal view`: Internal function to evaluate if all conditions of a policy are met for a user with provided oracle data.

**IX. Emergency & Utility (4 Functions)**
26. `pause() onlyOwner`: Pause the contract operations (deposits, withdrawals).
27. `unpause() onlyOwner`: Unpause the contract.
28. `rescueERC20(address tokenAddress, uint256 amount) onlyOwner`: Rescue stuck ERC20 tokens sent without being intended for a policy.
29. `rescueERC721(address tokenAddress, uint256 tokenId) onlyOwner`: Rescue stuck ERC721 tokens.

**Total Functions:** 29

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive NFTs
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom Oracle Interface Example (replace with actual oracle interface if needed)
// This is a simplified example. A real oracle integration would involve specific function calls
// and data verification based on the chosen oracle network/design.
interface IQuantumOracle {
    // Example: returns a value for a given key, potentially requiring proof data
    function getValue(bytes32 dataKey, bytes calldata proofData) external view returns (uint256);
    // Example: verifies a condition based on proof data
    // function verifyCondition(bytes32 dataKey, uint256 requiredValue, bytes calldata proofData) external view returns (bool);
}


/**
 * @title QuantumVault
 * @dev A non-standard vault contract governing asset withdrawal via complex, conditional policies.
 * Policies can depend on time, internal state, external oracle data, user token/NFT holdings.
 * Includes a dynamic "Entropy" factor influencing withdrawal amounts.
 */
contract QuantumVault is Ownable, Pausable, ReentrancyGuard, ERC721Holder {
    using SafeMath for uint256;

    // --- Structs & Enums ---

    enum AssetType { ETH, ERC20, ERC721 }

    struct Asset {
        AssetType assetType;
        address tokenAddress; // Relevant for ERC20/ERC721
        uint256 amountOrId;   // Amount for ETH/ERC20, TokenId for ERC721
    }

    enum ConditionType {
        TimestampReached,           // Requires a specific timestamp
        OracleDataValueEquals,      // Requires oracle data for a key to equal a value
        InternalStateValueEquals,   // Requires internal state for a key to equal a value
        UserHoldsNFT,               // Requires msg.sender to hold a specific NFT
        UserHoldsMinTokenBalance    // Requires msg.sender to hold minimum balance of a token
    }

    struct Condition {
        ConditionType conditionType;
        uint256 value;          // Timestamp, required value, required balance, NFT ID (0 for any in collection)
        bytes32 dataKey;        // Oracle key, internal state key, NFT collection address, token address
    }

    struct EntropyParams {
        uint64 creationTimestamp; // Timestamp when policy was created (used for decay calculation)
        uint256 initialFactor;    // The starting multiplier (e.g., 1e18 for 1x)
        uint256 decayRate;        // Rate of decay per second (e.g., units per second)
        uint256 minFactor;        // Minimum factor (to prevent amount going to 0)
    }

    struct Policy {
        uint256 policyId;
        Asset targetAsset;
        Condition[] conditions;
        bool isActive;
        EntropyParams entropyParams;
    }

    // --- State Variables ---

    uint256 private nextPolicyId = 1;
    mapping(uint256 => Policy) private policies;
    uint256[] private policyIds; // To easily list all policy IDs

    // Internal "Quantum" State mapping
    mapping(bytes32 => uint256) private internalState;

    // Trusted Oracle Addresses mapping
    mapping(bytes32 => address) private trustedOracles;

    // --- Role Management ---
    bytes32 public constant POLICY_CREATOR_ROLE = keccak256("POLICY_CREATOR");
    mapping(address => bool) private policyCreators;

    // --- Events ---

    event ETHDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed sender, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed sender, address indexed token, uint256 tokenId);
    event ETHWithdrawn(address indexed recipient, uint256 amount, uint256 indexed policyId);
    event ERC20Withdrawn(address indexed recipient, address indexed token, uint256 amount, uint256 indexed policyId);
    event ERC721Withdrawn(address indexed recipient, address indexed token, uint256 tokenId, uint256 indexed policyId);
    event PolicyCreated(uint256 indexed policyId, address indexed creator, Asset targetAsset);
    event PolicyUpdated(uint256 indexed policyId);
    event PolicyToggled(uint256 indexed policyId, bool active);
    event PolicyDeleted(uint256 indexed policyId);
    event InternalStateUpdated(bytes32 indexed stateKey, uint256 newValue);
    event OracleAddressSet(bytes32 indexed oracleKey, address indexed oracleContract);
    event PolicyCreatorRoleSet(address indexed account, bool enabled);
    event EmergencyERC20Rescued(address indexed token, uint256 amount, address indexed recipient);
    event EmergencyERC721Rescued(address indexed token, uint256 tokenId, address indexed recipient);

    // --- Modifiers ---

    modifier onlyPolicyCreator() {
        require(policyCreators[msg.sender] || owner() == msg.sender, "QuantumVault: Not authorized policy creator");
        _;
    }

    // --- Constructor ---

    constructor(address initialOwner) Ownable(initialOwner) {
        // Grant owner the policy creator role by default
        policyCreators[initialOwner] = true;
    }

    // --- Receive ETH ---

    receive() external payable whenNotPaused {
        emit ETHDeposited(msg.sender, msg.value);
    }

    // --- Deposit Functions ---

    /**
     * @dev Deposit ERC20 tokens into the vault. Requires approval beforehand.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address tokenAddress, uint256 amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        require(amount > 0, "QuantumVault: Deposit amount must be greater than 0");
        IERC20 token = IERC20(tokenAddress);
        // Assumes sender has already approved this contract to spend 'amount' tokens
        token.transferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(msg.sender, tokenAddress, amount);
    }

    /**
     * @dev Deposit ERC721 tokens into the vault. Can be called directly or via safeTransferFrom.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the token to deposit.
     */
    function depositERC721(address tokenAddress, uint256 tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        // Assumes sender has already approved this contract or used safeTransferFrom
        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == msg.sender, "QuantumVault: Sender does not own the token");
        token.transferFrom(msg.sender, address(this), tokenId);
        // ERC721Holder handles the onERC721Received callback automatically
        emit ERC721Deposited(msg.sender, tokenAddress, tokenId);
    }

    // ERC721Holder callback - required to receive NFTs via safeTransferFrom
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // Can add custom logic here if needed, e.g., logging specific metadata from 'data'
        emit ERC721Deposited(from, msg.sender, tokenId); // operator is msg.sender in this context
        return this.onERC721Received.selector;
    }


    // --- Asset Balance & Holding Views ---

    /**
     * @dev Check the current ETH balance held by the contract.
     */
    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Check the balance of a specific ERC20 token held by the contract.
     * @param tokenAddress The address of the ERC20 token.
     */
    function getERC20Balance(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Check if the contract holds a specific ERC721 token.
     * Note: This relies on ERC721 standard ownerOf function.
     * @param tokenAddress The address of the ERC721 token collection.
     * @param tokenId The ID of the token.
     */
    function isHoldingERC721(address tokenAddress, uint256 tokenId) external view returns (bool) {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        try IERC721(tokenAddress).ownerOf(tokenId) returns (address owner) {
            return owner == address(this);
        } catch {
            // Token does not exist or contract is not standard ERC721
            return false;
        }
    }

    // --- Policy Management ---

    /**
     * @dev Create a new, complex withdrawal policy. Requires POLICY_CREATOR_ROLE.
     * @param targetAsset The asset type, address, and amount/ID targeted by the policy.
     * @param conditions The array of conditions that must ALL be met for withdrawal.
     * @param entropyParams Parameters defining how the policy's entropy factor evolves.
     */
    function createPolicy(
        Asset calldata targetAsset,
        Condition[] calldata conditions,
        EntropyParams calldata entropyParams
    ) external onlyPolicyCreator whenNotPaused nonReentrant returns (uint256) {
        require(conditions.length > 0, "QuantumVault: Policy must have at least one condition");
        require(targetAsset.assetType <= AssetType.ERC721, "QuantumVault: Invalid asset type");
        if (targetAsset.assetType != AssetType.ETH) {
            require(targetAsset.tokenAddress != address(0), "QuantumVault: Invalid token address for non-ETH asset");
        }
        if (targetAsset.assetType == AssetType.ERC721) {
            // For ERC721, amountOrId should be the tokenId. Policy is specific to one token.
            // If value is 0 in a UserHoldsNFT condition, it means any NFT in the collection,
            // but the targetAsset must specify a single token to withdraw.
             require(targetAsset.amountOrId > 0, "QuantumVault: ERC721 target must specify a tokenId > 0");
        } else {
             require(targetAsset.amountOrId > 0, "QuantumVault: ETH/ERC20 amount must be > 0");
        }

        uint256 policyId = nextPolicyId++;
        Policy storage newPolicy = policies[policyId];
        newPolicy.policyId = policyId;
        newPolicy.targetAsset = targetAsset;
        newPolicy.conditions = conditions;
        newPolicy.isActive = true; // Policies are active by default
        newPolicy.entropyParams = entropyParams;
        newPolicy.entropyParams.creationTimestamp = uint64(block.timestamp); // Record creation time

        policyIds.push(policyId);

        emit PolicyCreated(policyId, msg.sender, targetAsset);
        return policyId;
    }

    /**
     * @dev Retrieve the details of a specific policy.
     * @param policyId The ID of the policy.
     */
    function getPolicy(uint256 policyId)
        external
        view
        returns (
            uint256,
            Asset memory,
            Condition[] memory,
            bool,
            EntropyParams memory
        )
    {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        return (
            policy.policyId,
            policy.targetAsset,
            policy.conditions,
            policy.isActive,
            policy.entropyParams
        );
    }

    /**
     * @dev Update the conditions of an existing policy. Only callable by owner.
     * @param policyId The ID of the policy to update.
     * @param newConditions The new array of conditions.
     */
    function updatePolicyConditions(uint256 policyId, Condition[] calldata newConditions)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        require(newConditions.length > 0, "QuantumVault: Policy must have at least one condition");

        policy.conditions = newConditions; // This replaces the entire conditions array
        emit PolicyUpdated(policyId);
    }

     /**
     * @dev Update the entropy parameters of an existing policy. Only callable by owner.
     * @param policyId The ID of the policy to update.
     * @param newEntropyParams The new entropy parameters.
     */
    function updatePolicyEntropy(uint256 policyId, EntropyParams calldata newEntropyParams)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");

        policy.entropyParams = newEntropyParams;
        // Note: creationTimestamp might be reset here depending on desired logic.
        // Current logic keeps the original creation time for decay base.
        // policy.entropyParams.creationTimestamp = uint64(block.timestamp); // Uncomment to reset decay timer on update

        emit PolicyUpdated(policyId); // Re-use event for any policy structure update
    }

     /**
     * @dev Retrieve the entropy parameters for a policy.
     * @param policyId The ID of the policy.
     */
    function getPolicyEntropyParams(uint256 policyId)
        external
        view
        returns (EntropyParams memory)
    {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        return policy.entropyParams;
    }


    /**
     * @dev Activate or deactivate a policy. Only callable by owner.
     * Deactivating a policy prevents withdrawal attempts using it.
     * @param policyId The ID of the policy to toggle.
     * @param active The desired active state (true for active, false for inactive).
     */
    function togglePolicyActive(uint256 policyId, bool active)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        require(policy.isActive != active, "QuantumVault: Policy already in desired state");

        policy.isActive = active;
        emit PolicyToggled(policyId, active);
    }

    /**
     * @dev Permanently delete a policy. Only callable by owner.
     * This makes the policy unusable but does NOT affect the assets in the vault.
     * Assets previously associated with this policy might become inaccessible
     * unless other policies cover them.
     * @param policyId The ID of the policy to delete.
     */
    function deletePolicy(uint256 policyId) external onlyOwner whenNotPaused nonReentrant {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");

        delete policies[policyId];

        // Remove from the policyIds array (less efficient for large arrays)
        for (uint i = 0; i < policyIds.length; i++) {
            if (policyIds[i] == policyId) {
                policyIds[i] = policyIds[policyIds.length - 1];
                policyIds.pop();
                break;
            }
        }

        emit PolicyDeleted(policyId);
    }

    /**
     * @dev Get a list of all policy IDs that have been created.
     * Note: This list is not pruned when policies are deleted,
     * but fetching a deleted policy ID will revert.
     */
    function getAllPolicyIds() external view returns (uint256[] memory) {
        return policyIds;
    }


    // --- Internal State ("Quantum State") Management ---

    /**
     * @dev Update an internal state variable ("Quantum State"). Only callable by owner.
     * These states can be used as conditions within policies.
     * @param stateKey The key identifying the state variable.
     * @param newValue The new value for the state variable.
     */
    function updateInternalState(bytes32 stateKey, uint256 newValue)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        internalState[stateKey] = newValue;
        emit InternalStateUpdated(stateKey, newValue);
    }

    /**
     * @dev Retrieve the value of an internal state variable.
     * @param stateKey The key identifying the state variable.
     */
    function getInternalState(bytes32 stateKey) external view returns (uint256) {
        return internalState[stateKey];
    }

    // --- Oracle Management ---

    /**
     * @dev Set the trusted address for a specific type of oracle data. Only callable by owner.
     * Policies referencing `oracleKey` will call the contract at `oracleContract` address
     * to verify the condition.
     * @param oracleKey The key identifying the type of oracle data (e.g., hash of "ETH/USD Price").
     * @param oracleContract The address of the trusted oracle smart contract.
     */
    function setOracleAddress(bytes32 oracleKey, address oracleContract)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        require(oracleContract != address(0), "QuantumVault: Oracle address cannot be zero");
        trustedOracles[oracleKey] = oracleContract;
        emit OracleAddressSet(oracleKey, oracleContract);
    }

     /**
     * @dev Get the trusted address for a specific oracle key.
     * @param oracleKey The key identifying the oracle.
     */
    function getOracleAddress(bytes32 oracleKey) external view returns (address) {
        return trustedOracles[oracleKey];
    }


    // --- Role Management ---

    /**
     * @dev Grant or revoke the POLICY_CREATOR_ROLE to an account. Only callable by owner.
     * Accounts with this role can create new policies. Owner always has this ability.
     * @param account The address to grant or revoke the role for.
     * @param enabled True to grant the role, false to revoke.
     */
    function setPolicyCreatorRole(address account, bool enabled)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        require(account != address(0), "QuantumVault: Cannot set role for zero address");
        policyCreators[account] = enabled;
        emit PolicyCreatorRoleSet(account, enabled);
    }

     /**
     * @dev Check if an address has the POLICY_CREATOR_ROLE.
     * @param account The address to check.
     */
    function hasPolicyCreatorRole(address account) external view returns (bool) {
        return policyCreators[account] || owner() == account;
    }

    // --- Conditional Withdrawal Functions ---

    /**
     * @dev Attempt to withdraw ETH using a specific policy.
     * All conditions for the policy must be met and the policy must be active.
     * The amount withdrawn is affected by the policy's current entropy factor.
     * @param policyId The ID of the policy to use for withdrawal.
     * @param oracleProofData Data required by oracle conditions, if any.
     */
    function withdrawETH(uint256 policyId, bytes calldata oracleProofData)
        external
        whenNotPaused
        nonReentrant
    {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        require(policy.isActive, "QuantumVault: Policy is not active");
        require(policy.targetAsset.assetType == AssetType.ETH, "QuantumVault: Policy target is not ETH");

        // Check all conditions associated with the policy
        _checkConditions(policy, msg.sender, oracleProofData);

        // Calculate the amount to withdraw based on policy target and entropy
        uint256 targetAmount = policy.targetAsset.amountOrId;
        uint256 entropyFactor = _calculateCurrentEntropyFactor(policy.entropyParams);
        // Amount = (Target Amount * Entropy Factor) / 1e18 (assuming factor is 1e18 based)
        uint256 amountToWithdraw = targetAmount.mul(entropyFactor).div(1e18);

        require(amountToWithdraw > 0, "QuantumVault: Calculated withdrawal amount is zero");
        require(address(this).balance >= amountToWithdraw, "QuantumVault: Insufficient ETH balance in vault");

        // Perform withdrawal
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "QuantumVault: ETH withdrawal failed");

        emit ETHWithdrawn(msg.sender, amountToWithdraw, policyId);
    }

    /**
     * @dev Attempt to withdraw ERC20 tokens using a specific policy.
     * All conditions for the policy must be met and the policy must be active.
     * The amount withdrawn is affected by the policy's current entropy factor.
     * @param tokenAddress The address of the ERC20 token specified in the policy.
     * @param policyId The ID of the policy to use for withdrawal.
     * @param oracleProofData Data required by oracle conditions, if any.
     */
    function withdrawERC20(
        address tokenAddress,
        uint256 policyId,
        bytes calldata oracleProofData
    ) external whenNotPaused nonReentrant {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        require(policy.isActive, "QuantumVault: Policy is not active");
        require(policy.targetAsset.assetType == AssetType.ERC20, "QuantumVault: Policy target is not ERC20");
        require(policy.targetAsset.tokenAddress == tokenAddress, "QuantumVault: Policy target ERC20 address mismatch");

        // Check all conditions associated with the policy
        _checkConditions(policy, msg.sender, oracleProofData);

        // Calculate the amount to withdraw based on policy target and entropy
        uint256 targetAmount = policy.targetAsset.amountOrId;
        uint256 entropyFactor = _calculateCurrentEntropyFactor(policy.entropyParams);
         // Amount = (Target Amount * Entropy Factor) / 1e18 (assuming factor is 1e18 based)
        uint256 amountToWithdraw = targetAmount.mul(entropyFactor).div(1e18);

        require(amountToWithdraw > 0, "QuantumVault: Calculated withdrawal amount is zero");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amountToWithdraw, "QuantumVault: Insufficient ERC20 balance in vault");

        // Perform withdrawal
        token.transfer(msg.sender, amountToWithdraw);

        emit ERC20Withdrawn(msg.sender, tokenAddress, amountToWithdraw, policyId);
    }

    /**
     * @dev Attempt to withdraw a specific ERC721 token using a policy.
     * All conditions for the policy must be met and the policy must be active.
     * The policy must target the *exact* token ID requested.
     * Note: Entropy is currently applied as a factor on amount, less relevant for discrete NFTs.
     * Could be used to gate *which* NFTs are available based on decay if policies target groups.
     * For this implementation, entropy doesn't affect the discrete NFT withdrawal itself.
     * @param tokenAddress The address of the ERC721 token collection.
     * @param tokenId The ID of the token specified in the policy target.
     * @param policyId The ID of the policy to use for withdrawal.
     * @param oracleProofData Data required by oracle conditions, if any.
     */
    function withdrawERC721(
        address tokenAddress,
        uint256 tokenId,
        uint256 policyId,
        bytes calldata oracleProofData
    ) external whenNotPaused nonReentrant {
        Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        require(policy.isActive, "QuantumVault: Policy is not active");
        require(policy.targetAsset.assetType == AssetType.ERC721, "QuantumVault: Policy target is not ERC721");
        require(policy.targetAsset.tokenAddress == tokenAddress, "QuantumVault: Policy target ERC721 address mismatch");
        require(policy.targetAsset.amountOrId == tokenId, "QuantumVault: Policy target ERC721 tokenId mismatch"); // Policy must target the specific token

        // Check all conditions associated with the policy
        _checkConditions(policy, msg.sender, oracleProofData);

        // Check vault holds the specific token
        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == address(this), "QuantumVault: Vault does not hold the specified ERC721 token");

        // Perform withdrawal
        token.safeTransferFrom(address(this), msg.sender, tokenId);

        emit ERC721Withdrawn(msg.sender, tokenAddress, tokenId, policyId);
    }

    // --- Entropy Calculation ---

    /**
     * @dev Calculate the current entropy factor for a policy.
     * The factor decreases over time from the creation timestamp.
     * The decay rate is applied per second. Factor is based on 1e18.
     * Example: initialFactor=1e18 (1x), decayRate=1e17 (0.1x per sec), minFactor=1e17 (0.1x)
     * After 1 second: factor = 1e18 - 1e17 = 0.9e18
     * After 10 seconds: factor = 1e18 - 10*1e17 = 0
     * Capped at minFactor.
     * @param entropyParams The entropy parameters for the policy.
     */
    function _calculateCurrentEntropyFactor(EntropyParams memory entropyParams)
        internal
        view
        returns (uint256)
    {
        uint256 elapsedTime = block.timestamp.sub(entropyParams.creationTimestamp);
        uint256 decayAmount = elapsedTime.mul(entropyParams.decayRate);

        if (decayAmount >= entropyParams.initialFactor) {
            return entropyParams.minFactor;
        }

        uint256 currentFactor = entropyParams.initialFactor.sub(decayAmount);
        return currentFactor > entropyParams.minFactor ? currentFactor : entropyParams.minFactor;
    }

     /**
     * @dev Public view function to calculate the current entropy factor for a policy.
     * Useful for external users to check the factor before attempting withdrawal.
     * @param policyId The ID of the policy.
     */
    function getCurrentEntropyFactor(uint256 policyId) external view returns (uint256) {
         Policy storage policy = policies[policyId];
        require(policy.policyId != 0, "QuantumVault: Policy not found");
        return _calculateCurrentEntropyFactor(policy.entropyParams);
    }


    // --- Condition Evaluation ---

    /**
     * @dev Internal helper function to check if ALL conditions for a policy are met.
     * Reverts if any condition is NOT met.
     * @param policy The policy object.
     * @param user The address attempting to meet the conditions.
     * @param oracleProofData Data required by oracle conditions, if any.
     */
    function _checkConditions(Policy storage policy, address user, bytes calldata oracleProofData) internal view {
        for (uint i = 0; i < policy.conditions.length; i++) {
            Condition storage condition = policy.conditions[i];

            if (condition.conditionType == ConditionType.TimestampReached) {
                require(block.timestamp >= condition.value, "QuantumVault: Condition Timestamp not reached");
            } else if (condition.conditionType == ConditionType.OracleDataValueEquals) {
                address oracleAddress = trustedOracles[condition.dataKey];
                require(oracleAddress != address(0), "QuantumVault: Oracle not configured for key");
                // Call the trusted oracle contract to get or verify data
                // The exact call depends on the oracle interface. This is an example.
                // Assumes oracleAddress implements IQuantumOracle and getValue verifies the condition.
                IQuantumOracle oracle = IQuantumOracle(oracleAddress);
                 // Example: call oracle to get a value and compare it
                uint256 oracleValue = oracle.getValue(condition.dataKey, oracleProofData);
                require(oracleValue == condition.value, "QuantumVault: Oracle condition not met");

                // Alternative approach (if oracle verifies directly):
                // (bool success, bytes memory result) = oracleAddress.staticcall(abi.encodeWithSignature("verifyCondition(bytes32,uint256,bytes)", condition.dataKey, condition.value, oracleProofData));
                // require(success, "QuantumVault: Oracle call failed");
                // require(abi.decode(result, (bool)), "QuantumVault: Oracle condition not met");

            } else if (condition.conditionType == ConditionType.InternalStateValueEquals) {
                 require(internalState[condition.dataKey] == condition.value, "QuantumVault: Internal State condition not met");
            } else if (condition.conditionType == ConditionType.UserHoldsNFT) {
                require(condition.dataKey != address(0), "QuantumVault: NFT collection address cannot be zero for condition");
                IERC721 nftCollection = IERC721(condition.dataKey);
                if (condition.value == 0) {
                     // Check if user holds *any* NFT in the collection by checking balance > 0
                     require(nftCollection.balanceOf(user) > 0, "QuantumVault: User does not hold any NFT from collection");
                } else {
                    // Check if user holds a specific NFT ID
                    require(nftCollection.ownerOf(condition.value) == user, "QuantumVault: User does not hold specific NFT ID");
                }
            } else if (condition.conditionType == ConditionType.UserHoldsMinTokenBalance) {
                 require(condition.dataKey != address(0), "QuantumVault: Token address cannot be zero for condition");
                 IERC20 token = IERC20(condition.dataKey);
                 require(token.balanceOf(user) >= condition.value, "QuantumVault: User minimum token balance not met");
            } else {
                revert("QuantumVault: Unknown condition type"); // Should not happen with proper input validation
            }
        }
    }

     /**
     * @dev Public helper function to check if a user can currently withdraw using a policy.
     * Does not perform withdrawal, only condition checks. Useful for UIs.
     * Returns true if all conditions are met, false otherwise.
     * @param policyId The ID of the policy.
     * @param user The address to check conditions for.
     * @param oracleProofData Data required by oracle conditions, if any.
     */
    function canWithdrawWithPolicy(uint256 policyId, address user, bytes calldata oracleProofData) external view returns (bool) {
        Policy storage policy = policies[policyId];
        if (policy.policyId == 0 || !policy.isActive) {
            return false; // Policy not found or inactive
        }

        // Simulate condition checks without reverting
        for (uint i = 0; i < policy.conditions.length; i++) {
            Condition storage condition = policy.conditions[i];
            bool conditionMet = false;

            if (condition.conditionType == ConditionType.TimestampReached) {
                conditionMet = block.timestamp >= condition.value;
            } else if (condition.conditionType == ConditionType.OracleDataValueEquals) {
                 address oracleAddress = trustedOracles[condition.dataKey];
                 if (oracleAddress != address(0)) {
                     try IQuantumOracle(oracleAddress).getValue(condition.dataKey, oracleProofData) returns (uint256 oracleValue) {
                         conditionMet = oracleValue == condition.value;
                     } catch {
                         // Oracle call failed or reverted, condition not met
                         conditionMet = false;
                     }
                 } else {
                     conditionMet = false; // Oracle not configured
                 }
            } else if (condition.conditionType == ConditionType.InternalStateValueEquals) {
                 conditionMet = internalState[condition.dataKey] == condition.value;
            } else if (condition.conditionType == ConditionType.UserHoldsNFT) {
                 if (condition.dataKey != address(0)) {
                      try IERC721(condition.dataKey).balanceOf(user) returns (uint256 balance) {
                           if (condition.value == 0) { // Any NFT
                                conditionMet = balance > 0;
                           } else { // Specific NFT
                               try IERC721(condition.dataKey).ownerOf(condition.value) returns (address owner) {
                                    conditionMet = owner == user;
                               } catch {
                                    conditionMet = false; // ownerOf call failed
                               }
                           }
                      } catch {
                          conditionMet = false; // balanceOf call failed
                      }
                 } else {
                     conditionMet = false; // Invalid NFT address in condition
                 }
            } else if (condition.conditionType == ConditionType.UserHoldsMinTokenBalance) {
                 if (condition.dataKey != address(0)) {
                      try IERC20(condition.dataKey).balanceOf(user) returns (uint256 balance) {
                          conditionMet = balance >= condition.value;
                      } catch {
                          conditionMet = false; // balanceOf call failed
                      }
                 } else {
                     conditionMet = false; // Invalid token address in condition
                 }
            } else {
                 // Unknown condition type - consider it not met or revert in checkConditions
                 return false; // For view function, safer to return false
            }

            if (!conditionMet) {
                return false; // If ANY condition is not met, return false immediately
            }
        }
        // If the loop completes, all conditions were met
        return true;
    }


    // --- Emergency & Utility ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     * Prevents most state-changing operations like deposits, withdrawals, policy changes.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     * Allows state-changing operations to resume.
     */
    function unpause() external onlyOwner {
        _unpause();
    }


    /**
     * @dev Allows the owner to rescue ERC20 tokens that were sent directly
     * to the contract without being intended for a specific policy mechanism.
     * Use with caution as this bypasses policies.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "QuantumVault: Insufficient ERC20 balance to rescue");
        token.transfer(owner(), amount); // Send rescued tokens to the owner
        emit EmergencyERC20Rescued(tokenAddress, amount, owner());
    }

    /**
     * @dev Allows the owner to rescue ERC721 tokens that were sent directly
     * to the contract without being intended for a specific policy mechanism.
     * Use with caution as this bypasses policies.
     * @param tokenAddress The address of the ERC721 token collection.
     * @param tokenId The ID of the token to rescue.
     */
    function rescueERC721(address tokenAddress, uint256 tokenId) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "QuantumVault: Invalid token address");
        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == address(this), "QuantumVault: Vault does not hold the specified ERC721 token");
        token.safeTransferFrom(address(this), owner(), tokenId); // Send rescued token to the owner
        emit EmergencyERC721Rescued(tokenAddress, tokenId, owner());
    }
}
```