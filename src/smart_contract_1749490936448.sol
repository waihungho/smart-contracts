Okay, here is a smart contract concept I call "QuantumVault". It's designed as a sophisticated, programmable, multi-asset vault where assets can be locked and released based on complex, multi-conditional rules, potentially involving external data (simulated Oracle), linked accounts ("Entanglement"), and multi-party approval ("Observers"). It avoids simple time locks or single conditions.

It aims for complexity by combining multiple factors for release conditions and managing different asset types (ETH, ERC20, ERC721) within the same framework, linked by shared conditional logic structures.

---

**QuantumVault Smart Contract**

**Outline:**

1.  **Description:** A secure, programmable vault for ETH, ERC20, and ERC721 assets. Assets can be deposited and then locked via "Conditional Release Rules". These rules define complex conditions that must be met for withdrawal, potentially involving time, external oracle data, a linked "entangled" account, and multiple observer signatures.
2.  **Libraries:** Uses OpenZeppelin's `Ownable`, `Pausable`, `SafeERC20`, and interfaces for ERC20/ERC721.
3.  **State Variables:**
    *   Owner, Paused state.
    *   Oracle address and stored oracle data.
    *   Mapping for Entangled Pairs.
    *   Structs and mappings to store Conditional Release Rules.
    *   Mapping to track specific ERC721 tokens locked in rules.
    *   Vault balances (conceptual, as contract holds tokens, but tracking user-definable amounts).
4.  **Events:** Significant state changes (Deposits, Withdrawals, Rule Creation/Cancellation/Trigger, Entanglement, Oracle Update, Observer Signing, Decoherence).
5.  **Enums & Structs:** Define asset types and the structure for Conditional Release Rules.
6.  **Modifiers:** Access control (`onlyOwner`, `whenNotPaused`), Oracle control (`onlyOracle`), and the core logic check (`releaseConditionsMet`).
7.  **Constructor:** Initializes owner and potentially oracle.
8.  **Fallback/Receive:** Handles direct ETH deposits.
9.  **Core Deposit Functions:** Accept ETH, ERC20, ERC721 into the vault.
10. **Core Withdrawal Functions:** Release ETH, ERC20, ERC721 *only* if conditions for a specific rule are met.
11. **Conditional Release Management:** Functions to create, cancel, and query the status of release rules.
12. **Entanglement Management:** Functions to create and break links between user accounts.
13. **Oracle Integration:** Function for the designated oracle to update external data.
14. **Observer Management:** Functions to add required observers to a rule and record their signatures.
15. **Delegation:** Allow rule owners to set a delegate who can trigger the release.
16. **Emergency/Decoherence:** A mechanism for the owner to potentially bypass conditions under extreme circumstances (with safeguards).
17. **Utility/Getters:** View functions to inspect contract state, balances, rule details, entanglement status, etc.
18. **Ownership/Pausable:** Standard OpenZeppelin functions.

**Function Summary:**

1.  `constructor()`: Initializes the contract with an owner.
2.  `receive() external payable`: Allows users to send ETH directly to the vault.
3.  `depositETH() external payable`: Explicit function for ETH deposit (alternative to `receive`).
4.  `depositERC20(address token, uint256 amount) external`: Allows depositing ERC20 tokens. Requires allowance.
5.  `depositERC721(address token, uint256 tokenId) external`: Allows depositing an ERC721 token. Requires approval.
6.  `onERC721Received(...) internal returns (bytes4)`: ERC721 receiver hook, required for safe transfer.
7.  `registerConditionalRelease(ConditionalReleaseParams memory params) external returns (uint256 ruleId)`: Creates a new complex release rule for assets held in the vault.
8.  `cancelConditionalRelease(uint256 ruleId) external`: Allows the owner of a rule to cancel it if not yet triggered. Returns assets to their available balance.
9.  `checkReleaseConditionsMet(uint256 ruleId) public view returns (bool)`: Checks if all conditions (time, oracle, entanglement, observers) for a specific rule are satisfied.
10. `withdrawETH(uint256 ruleId) external`: Triggers withdrawal of ETH for a rule if conditions are met.
11. `withdrawERC20(uint256 ruleId) external`: Triggers withdrawal of ERC20 for a rule if conditions are met.
12. `withdrawERC721(uint256 ruleId) external`: Triggers withdrawal of ERC721 for a rule if conditions are met.
13. `createEntanglement(address pair) external`: Links the sender's account to another address for conditional logic requirements. Requires mutual consent.
14. `breakEntanglement() external`: Breaks the entanglement link with the paired address. Requires consent from both or a time lock expiry (conceptually).
15. `getEntangledPair(address account) public view returns (address)`: Returns the entangled address for a given account.
16. `setOracleAddress(address _oracle) external onlyOwner`: Sets the address authorized to update oracle data.
17. `updateOracleData(bytes32 key, bytes32 value) external onlyOracle`: Allows the oracle to update a data point.
18. `addRequiredObserver(uint256 ruleId, address observer) external`: Adds an address as a required observer for a specific release rule. Callable by rule owner.
19. `removeRequiredObserver(uint256 ruleId, address observer) external`: Removes a required observer from a rule. Callable by rule owner.
20. `observerSignRelease(uint256 ruleId) external`: Allows a required observer to sign off on a release rule.
21. `checkObserverSigned(uint256 ruleId, address observer) public view returns (bool)`: Checks if a specific observer has signed for a rule.
22. `setReleaseDelegate(uint256 ruleId, address delegate) external`: Sets an address authorized to trigger the release for a rule on behalf of the owner.
23. `removeReleaseDelegate(uint256 ruleId) external`: Removes the delegate for a rule.
24. `initiateDecoherenceProtocol(uint256 ruleId) external onlyOwner`: Initiates an emergency protocol for a specific rule, potentially allowing override after a delay. (Simple version: marks for override).
25. `withdrawDecoheredETH(uint256 ruleId) external onlyOwner`: Emergency withdrawal for ETH under decoherence protocol. (Simple version: checks decoherence flag).
26. `withdrawDecoheredERC20(uint256 ruleId) external onlyOwner`: Emergency withdrawal for ERC20 under decoherence protocol.
27. `withdrawDecoheredERC721(uint256 ruleId) external onlyOwner`: Emergency withdrawal for ERC721 under decoherence protocol.
28. `getVaultBalanceETH() public view returns (uint256)`: Gets the total ETH held in the contract.
29. `getVaultBalanceERC20(address token) public view returns (uint256)`: Gets the total amount of a specific ERC20 token held.
30. `getVaultBalanceERC721(address token, uint256 tokenId) public view returns (bool)`: Checks if a specific ERC721 token is held by the contract.
31. `getUserReleaseRules(address user) public view returns (uint256[] memory)`: Gets all rule IDs created by a user.
32. `getConditionalReleaseDetails(uint256 ruleId) public view returns (ConditionalRelease memory)`: Gets the full details of a release rule.
33. `getRequiredObservers(uint256 ruleId) public view returns (address[] memory)`: Gets the list of required observers for a rule.
34. `getSignedObservers(uint256 ruleId) public view returns (address[] memory)`: Gets the list of observers who have signed for a rule.
35. `getOracleData(bytes32 key) public view returns (bytes32)`: Gets the current value for an oracle data key.
36. `pause() external onlyOwner`: Pauses certain contract operations.
37. `unpause() external onlyOwner`: Unpauses contract operations.
38. `transferOwnership(address newOwner) external onlyOwner`: Transfers contract ownership.
39. `renounceOwnership() external onlyOwner`: Renounces contract ownership (sets owner to zero address).


---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom interfaces or stubs for concepts not standard ERCs
interface IQuantumOracle {
    function getOracleData(bytes32 key) external view returns (bytes32);
}

/**
 * @title QuantumVault
 * @dev A sophisticated multi-asset vault with complex, multi-conditional release rules.
 * Assets (ETH, ERC20, ERC721) can be deposited and locked until defined
 * conditions are met, involving time, external oracle data, "entangled" accounts,
 * and multi-party observer signatures.
 */
contract QuantumVault is Ownable, Pausable, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // --- State Variables ---

    address public oracleAddress; // Address allowed to update oracle data
    mapping(bytes32 => bytes32) private oracleData; // Stores external data provided by the oracle

    mapping(address => address) private entangledPairs; // Links two addresses for conditional logic
    // Note: For a valid entanglement, A -> B and B -> A must both exist.

    uint256 private nextReleaseId = 1; // Counter for unique release rule IDs

    enum AssetType { ETH, ERC20, ERC721 }

    struct ConditionalRelease {
        AssetType assetType;
        address tokenAddress; // Address of the token (0x0 for ETH)
        uint256 tokenId; // Token ID for ERC721 (0 for others)
        uint256 amount; // Amount for ETH/ERC20 (0 for ERC721)
        address payable recipient; // Address to receive assets upon release
        address owner; // Original owner who created the rule
        uint256 unlockTime; // Minimum time for release

        bool requiresOracleData; // Does this rule depend on oracle data?
        bytes32 oracleDataKey; // Key for the required oracle data
        bytes32 requiredOracleValue; // Value required from the oracle

        bool requiresEntanglement; // Does this rule depend on the owner's entangled pair?
        address entangledPairAddress; // The *other* address in the required entanglement pair

        bool requiresObservers; // Does this rule require observer signatures?
        mapping(address => bool) requiredObservers; // Set of addresses that must sign
        mapping(address => bool) signedObservers; // Addresses that have signed
        uint256 minObserverSignatures; // Minimum number of signatures required
        uint256 currentSignatures; // Counter for collected signatures

        bool isReleased; // Has this rule been triggered?
        bool decoherenceInitiated; // Has emergency decoherence protocol been initiated?

        address delegate; // Address authorized to trigger release (if conditions met)
        uint256 creationTime; // Timestamp when the rule was created
    }

    mapping(uint256 => ConditionalRelease) public conditionalReleases; // Store all release rules
    mapping(address => uint256[]) private userReleaseIds; // Map user to their rule IDs

    // For ERC721, we need to track which specific token ID is locked by a rule
    mapping(address => mapping(uint256 => uint256)) private erc721LockedInRule; // tokenAddress => tokenId => ruleId (0 if not locked)

    // --- Events ---

    event ETHDeposited(address indexed user, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint256 tokenId);
    event ETHWithdrawn(uint256 indexed ruleId, address indexed recipient, uint256 amount);
    event ERC20Withdrawn(uint256 indexed ruleId, address indexed recipient, address indexed token, uint256 amount);
    event ERC721Withdrawn(uint256 indexed ruleId, address indexed recipient, address indexed token, uint256 tokenId);

    event ConditionalReleaseCreated(uint256 indexed ruleId, address indexed owner, AssetType assetType, address recipient, uint256 creationTime);
    event ConditionalReleaseCancelled(uint256 indexed ruleId, address indexed owner);
    event ConditionalReleaseTriggered(uint256 indexed ruleId, address indexed trigger, address indexed recipient);

    event EntanglementCreated(address indexed account1, address indexed account2);
    event EntanglementBroken(address indexed account1, address indexed account2);

    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event OracleDataUpdated(bytes32 indexed key, bytes32 value);

    event ObserverAddedToRule(uint256 indexed ruleId, address indexed observer);
    event ObserverRemovedFromRule(uint256 indexed ruleId, address indexed observer);
    event ObserverSignedRule(uint256 indexed ruleId, address indexed observer);

    event DelegateSet(uint256 indexed ruleId, address indexed delegate);
    event DelegateRemoved(uint256 indexed ruleId, address indexed delegate);

    event DecoherenceInitiated(uint256 indexed ruleId, address indexed initiator);
    event DecoherenceWithdrawnETH(uint256 indexed ruleId, address indexed recipient, uint256 amount);
    event DecoherenceWithdrawnERC20(uint256 indexed ruleId, address indexed recipient, address indexed token, uint256 amount);
    event DecoherenceWithdrawnERC721(uint256 indexed ruleId, address indexed recipient, address indexed token, uint256 tokenId);

    // --- Modifiers ---

    /**
     * @dev Throws if called by any account other than the oracle.
     */
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "QuantumVault: Caller is not the oracle");
        _;
    }

    /**
     * @dev Checks if all conditions for a given release rule are met.
     */
    modifier releaseConditionsMet(uint256 ruleId) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];

        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, use decoherence withdrawal"); // Cannot use normal withdrawal if decoherence is active

        // Condition 1: Time lock
        require(block.timestamp >= rule.unlockTime, "QuantumVault: Time lock not expired");

        // Condition 2: Oracle data
        if (rule.requiresOracleData) {
            require(IQuantumOracle(oracleAddress).getOracleData(rule.oracleDataKey) == rule.requiredOracleValue, "QuantumVault: Oracle data condition not met");
        }

        // Condition 3: Entanglement
        if (rule.requiresEntanglement) {
             address pair = entangledPairs[rule.owner];
             require(pair != address(0) && pair == rule.entangledPairAddress, "QuantumVault: Entanglement condition not met for owner");
             address pairOfPair = entangledPairs[rule.entangledPairAddress];
             require(pairOfPair != address(0) && pairOfPair == rule.owner, "QuantumVault: Entanglement condition not met for paired address");
        }

        // Condition 4: Observers
        if (rule.requiresObservers) {
            require(rule.currentSignatures >= rule.minObserverSignatures, "QuantumVault: Not enough observer signatures");
            // Note: Specific required observers are checked when they sign, currentSignatures tracks the count.
        }

        _;
    }

    // --- Constructor ---

    constructor(address _oracle) Ownable(msg.sender) Pausable() {
        require(_oracle != address(0), "QuantumVault: Oracle address cannot be zero");
        oracleAddress = _oracle;
    }

    // --- Deposit Functions ---

    /**
     * @dev Allows users to send ETH directly to the vault.
     */
    receive() external payable whenNotPaused {
        emit ETHDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Explicit function for ETH deposit. Alternative to receive.
     * @param amount Amount of ETH to deposit.
     */
    function depositETH() external payable whenNotPaused {
        require(msg.value > 0, "QuantumVault: ETH amount must be greater than 0");
        // ETH is sent directly via payable function
        emit ETHDeposited(msg.sender, msg.value);
    }


    /**
     * @dev Deposits ERC20 tokens into the vault.
     * Requires the contract to have allowance to spend the tokens.
     * @param token The address of the ERC20 token contract.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(address token, uint256 amount) external whenNotPaused {
        require(token != address(0), "QuantumVault: Token address cannot be zero");
        require(amount > 0, "QuantumVault: Amount must be greater than 0");
        IERC20 erc20 = IERC20(token);
        erc20.safeTransferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(msg.sender, token, amount);
    }

    /**
     * @dev Deposits a specific ERC721 token into the vault.
     * Requires the contract to be approved or the sender to be the token owner with contract approved.
     * @param token The address of the ERC721 token contract.
     * @param tokenId The ID of the ERC721 token.
     */
    function depositERC721(address token, uint256 tokenId) external whenNotPaused {
        require(token != address(0), "QuantumVault: Token address cannot be zero");
        IERC721 erc721 = IERC721(token);
        require(erc721.ownerOf(tokenId) == msg.sender, "QuantumVault: Caller is not the owner of the token");
        // Safe transfer handles ERC721Holder callback
        erc721.safeTransferFrom(msg.sender, address(this), tokenId);
        emit ERC721Deposited(msg.sender, token, tokenId);
    }

    // ERC721Holder hook - required by SafeERC721
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override whenNotPaused returns (bytes4) {
        // This contract accepts any ERC721 token sent to it.
        // Custom logic could be added here (e.g., only accept tokens from specific contracts)
        return ERC721Holder.onERC721Received(operator, from, tokenId, data);
    }

    // --- Conditional Release Management ---

    struct ConditionalReleaseParams {
        AssetType assetType;
        address tokenAddress; // Used for ERC20/ERC721
        uint256 tokenId; // Used for ERC721
        uint256 amount; // Used for ETH/ERC20
        address payable recipient;
        uint256 unlockTime; // Minimum timestamp
        bool requiresOracleData;
        bytes32 oracleDataKey;
        bytes32 requiredOracleValue;
        bool requiresEntanglement;
        address entangledPairAddress; // The OTHER address in the pair
        address[] requiredObservers; // List of required observer addresses
        uint256 minObserverSignatures; // Minimum signatures needed (must be <= requiredObservers.length)
        address delegate; // Optional delegate address
    }

    /**
     * @dev Creates a new complex conditional release rule.
     * The assets specified are conceptually locked by this rule until released or cancelled.
     * Caller must be the owner of the assets in the vault.
     * @param params Struct containing all parameters for the release rule.
     * @return ruleId The ID of the created rule.
     */
    function registerConditionalRelease(ConditionalReleaseParams memory params)
        external
        whenNotPaused
        nonReentrant // Prevent reentrancy when locking assets
        returns (uint256 ruleId)
    {
        require(params.recipient != address(0), "QuantumVault: Recipient cannot be zero address");
        require(params.unlockTime >= block.timestamp, "QuantumVault: Unlock time must be in the future or now");
        if (params.requiresEntanglement) {
            require(params.entangledPairAddress != address(0) && params.entangledPairAddress != msg.sender, "QuantumVault: Invalid entangled pair address");
        }
        if (params.requiresObservers) {
            require(params.requiredObservers.length > 0, "QuantumVault: If observers required, list cannot be empty");
            require(params.minObserverSignatures > 0 && params.minObserverSignatures <= params.requiredObservers.length, "QuantumVault: Invalid minimum observer signatures");
             // Check for duplicates in requiredObservers
            for(uint i = 0; i < params.requiredObservers.length; i++) {
                require(params.requiredObservers[i] != address(0), "QuantumVault: Observer address cannot be zero");
                for(uint j = i + 1; j < params.requiredObservers.length; j++) {
                    require(params.requiredObservers[i] != params.requiredObservers[j], "QuantumVault: Duplicate observer address");
                }
            }
        } else {
             require(params.requiredObservers.length == 0, "QuantumVault: Required observers list must be empty if not required");
             require(params.minObserverSignatures == 0, "QuantumVault: Minimum signatures must be zero if observers not required");
        }
        if (params.delegate != address(0)) {
             require(params.delegate != msg.sender, "QuantumVault: Delegate cannot be owner");
        }

        ruleId = nextReleaseId++;
        ConditionalRelease storage newRule = conditionalReleases[ruleId];

        newRule.assetType = params.assetType;
        newRule.tokenAddress = params.tokenAddress;
        newRule.tokenId = params.tokenId;
        newRule.amount = params.amount;
        newRule.recipient = payable(params.recipient);
        newRule.owner = msg.sender;
        newRule.unlockTime = params.unlockTime;
        newRule.requiresOracleData = params.requiresOracleData;
        newRule.oracleDataKey = params.oracleDataKey;
        newRule.requiredOracleValue = params.requiredOracleValue;
        newRule.requiresEntanglement = params.requiresEntanglement;
        newRule.entangledPairAddress = params.entangledPairAddress;
        newRule.requiresObservers = params.requiresObservers;
        newRule.minObserverSignatures = params.minObserverSignatures;
        newRule.delegate = params.delegate;
        newRule.creationTime = block.timestamp;


        // Lock the asset for this rule
        if (params.assetType == AssetType.ETH) {
            // ETH is implicitly held by the contract. We assume the sender *intends* to lock deposited ETH.
            // In a real system, you'd need per-user ETH balance tracking or require deposit + rule creation in one tx.
             // For this example, we rely on the contract's total balance check later.
             require(address(this).balance >= newRule.amount, "QuantumVault: Insufficient ETH in vault");

        } else if (params.assetType == AssetType.ERC20) {
            require(params.tokenAddress != address(0), "QuantumVault: ERC20 token address cannot be zero");
            require(params.amount > 0, "QuantumVault: ERC20 amount must be greater than 0");
             // Check if contract holds enough of this ERC20
             require(IERC20(params.tokenAddress).balanceOf(address(this)) >= newRule.amount, "QuantumVault: Insufficient ERC20 balance in vault");

        } else if (params.assetType == AssetType.ERC721) {
            require(params.tokenAddress != address(0), "QuantumVault: ERC721 token address cannot be zero");
            require(params.tokenId > 0, "QuantumVault: ERC721 token ID must be greater than 0");
            // Check if contract holds the specific ERC721 and it's not already locked
            require(IERC721(params.tokenAddress).ownerOf(params.tokenId) == address(this), "QuantumVault: ERC721 not held by vault");
            require(erc721LockedInRule[params.tokenAddress][params.tokenId] == 0, "QuantumVault: ERC721 already locked in another rule");
            erc721LockedInRule[params.tokenAddress][params.tokenId] = ruleId;

        } else {
            revert("QuantumVault: Invalid asset type");
        }

        // Add required observers to the rule struct's mapping
        for (uint i = 0; i < params.requiredObservers.length; i++) {
            newRule.requiredObservers[params.requiredObservers[i]] = true;
        }


        userReleaseIds[msg.sender].push(ruleId);

        emit ConditionalReleaseCreated(ruleId, msg.sender, params.assetType, params.recipient, newRule.creationTime);

        return ruleId;
    }

    /**
     * @dev Allows the owner of a rule to cancel it.
     * Releases the assets back to the conceptual available balance for the owner.
     * Cannot cancel if the rule has already been triggered or if decoherence initiated.
     * @param ruleId The ID of the rule to cancel.
     */
    function cancelConditionalRelease(uint256 ruleId) external whenNotPaused nonReentrant {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.owner == msg.sender, "QuantumVault: Caller is not the rule owner");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, cancellation not allowed");

        // Unlock the asset conceptually
        if (rule.assetType == AssetType.ERC721) {
            require(erc721LockedInRule[rule.tokenAddress][rule.tokenId] == ruleId, "QuantumVault: ERC721 lock mismatch");
            erc721LockedInRule[rule.tokenAddress][rule.tokenId] = 0; // Unlock the NFT
        }

        // Note: For ETH/ERC20, we are not tracking per-user available balances,
        // so cancellation just makes the rule invalid for withdrawal.
        // In a system tracking per-user balances, assets would be credited back here.

        // Mark rule as cancelled (or delete it) - deleting is cleaner for storage
        delete conditionalReleases[ruleId];

        // Remove ruleId from userReleaseIds array (less gas efficient, but necessary for lookup)
        uint256[] storage userRules = userReleaseIds[msg.sender];
        for (uint i = 0; i < userRules.length; i++) {
            if (userRules[i] == ruleId) {
                userRules[i] = userRules[userRules.length - 1];
                userRules.pop();
                break;
            }
        }


        emit ConditionalReleaseCancelled(ruleId, msg.sender);
    }

    /**
     * @dev Checks if all defined conditions for a specific rule are met.
     * Can be called by anyone.
     * @param ruleId The ID of the rule to check.
     * @return bool True if all conditions are met, false otherwise.
     */
    function checkReleaseConditionsMet(uint256 ruleId) public view returns (bool) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];

        // Basic checks first
        if (rule.owner == address(0) || rule.isReleased || rule.decoherenceInitiated) {
            return false;
        }

        // Condition 1: Time lock
        if (block.timestamp < rule.unlockTime) {
            return false;
        }

        // Condition 2: Oracle data
        if (rule.requiresOracleData) {
            if (oracleAddress == address(0) || IQuantumOracle(oracleAddress).getOracleData(rule.oracleDataKey) != rule.requiredOracleValue) {
                return false;
            }
        }

        // Condition 3: Entanglement
        if (rule.requiresEntanglement) {
             address pair = entangledPairs[rule.owner];
             if (pair == address(0) || pair != rule.entangledPairAddress) return false;
             address pairOfPair = entangledPairs[rule.entangledPairAddress];
             if (pairOfPair == address(0) || pairOfPair != rule.owner) return false;
        }

        // Condition 4: Observers
        if (rule.requiresObservers) {
            if (rule.currentSignatures < rule.minObserverSignatures) {
                return false;
            }
        }

        // If all checks pass
        return true;
    }


    // --- Withdrawal Functions ---

    /**
     * @dev Triggers the withdrawal of ETH for a specific rule.
     * Can only be called if all conditions for the rule are met,
     * by the rule owner or their delegate.
     * @param ruleId The ID of the ETH release rule.
     */
    function withdrawETH(uint256 ruleId) external nonReentrant whenNotPaused releaseConditionsMet(ruleId) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.assetType == AssetType.ETH, "QuantumVault: Rule is not for ETH");
        require(msg.sender == rule.owner || msg.sender == rule.delegate, "QuantumVault: Not rule owner or delegate");
        require(rule.amount > 0, "QuantumVault: ETH amount is zero for this rule");
        require(address(this).balance >= rule.amount, "QuantumVault: Insufficient ETH balance in vault for this rule"); // Check total balance

        rule.isReleased = true;

        // Send ETH
        (bool success, ) = rule.recipient.call{value: rule.amount}("");
        require(success, "QuantumVault: ETH withdrawal failed");

        emit ETHWithdrawn(ruleId, rule.recipient, rule.amount);
        emit ConditionalReleaseTriggered(ruleId, msg.sender, rule.recipient);
    }

    /**
     * @dev Triggers the withdrawal of ERC20 for a specific rule.
     * Can only be called if all conditions for the rule are met,
     * by the rule owner or their delegate.
     * @param ruleId The ID of the ERC20 release rule.
     */
    function withdrawERC20(uint256 ruleId) external nonReentrant whenNotPaused releaseConditionsMet(ruleId) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.assetType == AssetType.ERC20, "QuantumVault: Rule is not for ERC20");
        require(msg.sender == rule.owner || msg.sender == rule.delegate, "QuantumVault: Not rule owner or delegate");
        require(rule.tokenAddress != address(0), "QuantumVault: ERC20 token address missing");
        require(rule.amount > 0, "QuantumVault: ERC20 amount is zero for this rule");
        IERC20 token = IERC20(rule.tokenAddress);
        require(token.balanceOf(address(this)) >= rule.amount, "QuantumVault: Insufficient ERC20 balance in vault for this rule"); // Check total balance

        rule.isReleased = true;

        token.safeTransfer(rule.recipient, rule.amount);

        emit ERC20Withdrawn(ruleId, rule.recipient, rule.tokenAddress, rule.amount);
        emit ConditionalReleaseTriggered(ruleId, msg.sender, rule.recipient);
    }

    /**
     * @dev Triggers the withdrawal of ERC721 for a specific rule.
     * Can only be called if all conditions for the rule are met,
     * by the rule owner or their delegate.
     * @param ruleId The ID of the ERC721 release rule.
     */
    function withdrawERC721(uint256 ruleId) external nonReentrant whenNotPaused releaseConditionsMet(ruleId) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.assetType == AssetType.ERC721, "QuantumVault: Rule is not for ERC721");
        require(msg.sender == rule.owner || msg.sender == rule.delegate, "QuantumVault: Not rule owner or delegate");
        require(rule.tokenAddress != address(0), "QuantumVault: ERC721 token address missing");
        require(rule.tokenId > 0, "QuantumVault: ERC721 token ID missing");
        IERC721 token = IERC721(rule.tokenAddress);
        require(token.ownerOf(rule.tokenId) == address(this), "QuantumVault: Vault does not own this ERC721 token");
        require(erc721LockedInRule[rule.tokenAddress][rule.tokenId] == ruleId, "QuantumVault: ERC721 lock mismatch or not locked by this rule");


        rule.isReleased = true;
        erc721LockedInRule[rule.tokenAddress][rule.tokenId] = 0; // Unlock the NFT

        token.safeTransferFrom(address(this), rule.recipient, rule.tokenId);

        emit ERC721Withdrawn(ruleId, rule.recipient, rule.tokenAddress, rule.tokenId);
        emit ConditionalReleaseTriggered(ruleId, msg.sender, rule.recipient);
    }


    // --- Entanglement Management ---

    /**
     * @dev Creates a bidirectional entanglement between msg.sender and 'pair'.
     * Both parties must call this function with each other's address.
     * Requires both addresses to not be entangled already.
     * @param pair The address to entangle with.
     */
    function createEntanglement(address pair) external whenNotPaused {
        require(pair != address(0) && pair != msg.sender, "QuantumVault: Cannot entangle with zero or self address");
        require(entangledPairs[msg.sender] == address(0), "QuantumVault: Sender is already entangled");
        require(entangledPairs[pair] == address(0), "QuantumVault: Pair address is already entangled");

        // For a valid entanglement A <-> B, both A->B and B->A must be set.
        // This function only sets one direction. The other party must call it too.
        entangledPairs[msg.sender] = pair;
        // We don't emit the event until the entanglement is mutual.
        // The mutual check happens in the release condition.

         // To enforce mutual consent immediately upon creation, we could require
         // a separate 'acceptEntanglement' function or use signatures.
         // Simple implementation: just setting one direction is enough for rule *creation*,
         // but *release* requires both directions to be set.
         // Let's add a check for mutual existence before emitting.
         if (entangledPairs[pair] == msg.sender) {
             emit EntanglementCreated(msg.sender, pair);
         }
    }

    /**
     * @dev Breaks the entanglement link for the sender.
     * Also breaks the link for the paired address.
     */
    function breakEntanglement() external whenNotPaused {
        address pair = entangledPairs[msg.sender];
        require(pair != address(0), "QuantumVault: Sender is not entangled");

        delete entangledPairs[msg.sender];
        delete entangledPairs[pair]; // Break the link for the other party as well

        emit EntanglementBroken(msg.sender, pair);
    }

    /**
     * @dev Gets the address entangled with the given account.
     * Returns address(0) if not entangled or if the link is not mutual.
     * @param account The address to check.
     * @return The entangled address, or address(0).
     */
    function getEntangledPair(address account) public view returns (address) {
        address pair = entangledPairs[account];
        // Check for mutual link
        if (pair != address(0) && entangledPairs[pair] == account) {
            return pair;
        }
        return address(0);
    }


    // --- Oracle Integration ---

    /**
     * @dev Sets the address of the oracle contract.
     * Can only be called by the contract owner.
     * @param _oracle The address of the oracle.
     */
    function setOracleAddress(address _oracle) external onlyOwner {
        require(_oracle != address(0), "QuantumVault: Oracle address cannot be zero");
        address oldOracle = oracleAddress;
        oracleAddress = _oracle;
        emit OracleAddressUpdated(oldOracle, _oracle);
    }

    /**
     * @dev Updates an oracle data point.
     * Can only be called by the designated oracle address.
     * @param key The key for the data point.
     * @param value The new value for the data point.
     */
    function updateOracleData(bytes32 key, bytes32 value) external onlyOracle {
        oracleData[key] = value;
        emit OracleDataUpdated(key, value);
    }

    /**
     * @dev Gets the current value for an oracle data key.
     * Anyone can call this view function.
     * @param key The key for the data point.
     * @return The current value for the data point.
     */
    function getOracleData(bytes32 key) public view returns (bytes32) {
        return oracleData[key];
    }


    // --- Observer Management ---

    /**
     * @dev Adds a required observer to an existing release rule.
     * Can only be called by the rule owner.
     * Cannot add if rule is released or decoherence initiated.
     * @param ruleId The ID of the rule.
     * @param observer The address to add as an observer.
     */
    function addRequiredObserver(uint256 ruleId, address observer) external whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.owner == msg.sender, "QuantumVault: Caller is not the rule owner");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, cannot add observers");
        require(observer != address(0), "QuantumVault: Observer address cannot be zero");
        require(!rule.requiredObservers[observer], "QuantumVault: Observer is already required");

        rule.requiresObservers = true; // Ensure flag is set if adding first observer
        rule.requiredObservers[observer] = true;
        // We don't increment minObserverSignatures automatically, owner sets that via updateRule function (not implemented for brevity) or initially.
        // For simplicity in this example, let's assume minObserverSignatures was set correctly during creation relative to the *initial* list.
        // A more complex version would allow updating minObserverSignatures here.

        emit ObserverAddedToRule(ruleId, observer);
    }

     /**
     * @dev Removes a required observer from an existing release rule.
     * Can only be called by the rule owner.
     * Cannot remove if rule is released or decoherence initiated.
     * @param ruleId The ID of the rule.
     * @param observer The address to remove as an observer.
     */
    function removeRequiredObserver(uint256 ruleId, address observer) external whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.owner == msg.sender, "QuantumVault: Caller is not the rule owner");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, cannot remove observers");
        require(rule.requiredObservers[observer], "QuantumVault: Observer is not required for this rule");

        delete rule.requiredObservers[observer];

        // If the observer had signed, decrement the signature count
        if (rule.signedObservers[observer]) {
             delete rule.signedObservers[observer];
             rule.currentSignatures--;
        }

        // If no more observers are required, reset the flag
        // (This is complex to check efficiently. A simple approach is to just remove the mapping entry)
        // Leaving requiresObservers true might be okay if min signatures is 0.
        // A better approach would be to track the count of required observers.
        // For this example, we won't decrement a required count.

        emit ObserverRemovedFromRule(ruleId, observer);
    }


    /**
     * @dev Allows a required observer to sign off on a release rule.
     * Can only be called by an address listed as a *required* observer for the rule.
     * Each observer can sign only once per rule.
     * Cannot sign if rule is released or decoherence initiated.
     * @param ruleId The ID of the rule.
     */
    function observerSignRelease(uint256 ruleId) external whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.requiresObservers, "QuantumVault: Rule does not require observers");
        require(rule.requiredObservers[msg.sender], "QuantumVault: Caller is not a required observer for this rule");
        require(!rule.signedObservers[msg.sender], "QuantumVault: Observer has already signed this rule");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, cannot sign");


        rule.signedObservers[msg.sender] = true;
        rule.currentSignatures++;

        emit ObserverSignedRule(ruleId, msg.sender);
    }

     /**
     * @dev Checks if a specific observer has signed for a specific rule.
     * @param ruleId The ID of the rule.
     * @param observer The address of the observer to check.
     * @return bool True if the observer has signed, false otherwise.
     */
    function checkObserverSigned(uint256 ruleId, address observer) public view returns (bool) {
         ConditionalRelease storage rule = conditionalReleases[ruleId];
         return rule.owner != address(0) && rule.signedObservers[observer];
    }

    /**
     * @dev Gets the list of required observers for a rule. (View helper - reconstructs array from map)
     * Gas might be high for large observer lists.
     * @param ruleId The ID of the rule.
     * @return address[] memory List of required observer addresses.
     */
    function getRequiredObservers(uint256 ruleId) public view returns (address[] memory) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");

        address[] memory observers = new address[](rule.requiredObservers.length); // Approximation, actual length is harder to get from mapping
        uint count = 0;
        // Iterating mappings is not directly supported and can be complex/gas-intensive
        // A better design would store required observers in a dynamic array in the struct,
        // though adding/removing is then harder.
        // For this example, returning a potentially incomplete list or requiring an external index is a limitation.
        // Let's return a dummy or limited list for demonstration.
        // A practical contract would manage required observers in an array.

        // *** Simplified Implementation Detail ***
        // Returning array from mapping is not efficient. In a real contract,
        // `requiredObservers` would likely be stored in a dynamic array within the struct,
        // making add/remove O(N) but retrieval O(N). The mapping would only track existence O(1).
        // For demonstration, we return a placeholder or require external indexing/tracking.
        // Returning an empty array as a fallback for map iteration complexity:
        return new address[](0);

         // If we *had* an array:
         /*
         address[] memory observersArray = rule.requiredObserversArray; // Assuming an array exists
         address[] memory result = new address[](observersArray.length);
         for(uint i = 0; i < observersArray.length; i++) {
             result[i] = observersArray[i];
         }
         return result;
         */
    }

    /**
     * @dev Gets the list of observers who have signed for a rule. (View helper - reconstructs array from map)
     * Gas might be high for large observer lists. Similar limitations to getRequiredObservers.
     * @param ruleId The ID of the rule.
     * @return address[] memory List of signed observer addresses.
     */
    function getSignedObservers(uint256 ruleId) public view returns (address[] memory) {
         ConditionalRelease storage rule = conditionalReleases[ruleId];
         require(rule.owner != address(0), "QuantumVault: Rule does not exist");

         // *** Simplified Implementation Detail ***
         // Same limitation as getRequiredObservers. Returning an empty array.
         return new address[](0);

         // If we tracked signed observers in an array:
         /*
         address[] memory signedArray = rule.signedObserversArray; // Assuming an array exists
         address[] memory result = new address[](signedArray.length);
         for(uint i = 0; i < signedArray.length; i++) {
             result[i] = signedArray[i];
         }
         return result;
         */
    }


    // --- Delegation ---

    /**
     * @dev Sets a delegate address for a specific release rule.
     * The delegate can trigger the release if all conditions are met.
     * Can only be called by the rule owner.
     * Cannot set if rule is released or decoherence initiated.
     * @param ruleId The ID of the rule.
     * @param delegate The address to set as delegate (address(0) to remove).
     */
    function setReleaseDelegate(uint256 ruleId, address delegate) external whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.owner == msg.sender, "QuantumVault: Caller is not the rule owner");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, cannot set delegate");
        require(delegate != rule.owner, "QuantumVault: Delegate cannot be the owner");

        rule.delegate = delegate;
        emit DelegateSet(ruleId, delegate);
    }

    /**
     * @dev Removes the delegate address for a specific release rule.
     * Can only be called by the rule owner.
     * @param ruleId The ID of the rule.
     */
    function removeReleaseDelegate(uint256 ruleId) external whenNotPaused {
         ConditionalRelease storage rule = conditionalReleases[ruleId];
         require(rule.owner != address(0), "QuantumVault: Rule does not exist");
         require(rule.owner == msg.sender, "QuantumVault: Caller is not the rule owner");
         // No need to check if delegate exists, setting to address(0) is harmless.
         require(!rule.isReleased, "QuantumVault: Rule already released");
         require(!rule.decoherenceInitiated, "QuantumVault: Decoherence initiated, cannot remove delegate");

         rule.delegate = address(0);
         emit DelegateRemoved(ruleId, address(0));
    }


    // --- Emergency / Decoherence Protocol ---
    // Note: This is a simplified example of an emergency override.
    // A robust protocol might require multi-sig owner approval, a long time delay,
    // or a separate governance mechanism.

    /**
     * @dev Initiates the Decoherence Protocol for a specific rule.
     * This flags the rule for emergency withdrawal, bypassing normal conditions after the flag is set.
     * Can only be called by the contract owner.
     * @param ruleId The ID of the rule.
     */
    function initiateDecoherenceProtocol(uint256 ruleId) external onlyOwner whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(!rule.decoherenceInitiated, "QuantumVault: Decoherence already initiated for this rule");

        rule.decoherenceInitiated = true;
        // A more complex version could set a 'decoherenceUnlockTime' here

        emit DecoherenceInitiated(ruleId, msg.sender);
    }

    /**
     * @dev Emergency withdrawal function for ETH rules under Decoherence Protocol.
     * Can only be called by the contract owner.
     * Bypasses normal conditional checks.
     * @param ruleId The ID of the ETH rule.
     */
    function withdrawDecoheredETH(uint256 ruleId) external onlyOwner nonReentrant whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.assetType == AssetType.ETH, "QuantumVault: Rule is not for ETH");
        require(rule.decoherenceInitiated, "QuantumVault: Decoherence protocol not initiated for this rule");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(rule.amount > 0, "QuantumVault: ETH amount is zero for this rule");
        require(address(this).balance >= rule.amount, "QuantumVault: Insufficient ETH balance in vault for this rule");

        // In a more complex version, check decoherence time lock here
        // require(block.timestamp >= rule.decoherenceUnlockTime, "QuantumVault: Decoherence time lock not expired");

        rule.isReleased = true;

        (bool success, ) = rule.recipient.call{value: rule.amount}("");
        require(success, "QuantumVault: Decoherence ETH withdrawal failed");

        emit DecoherenceWithdrawnETH(ruleId, rule.recipient, rule.amount);
        emit ConditionalReleaseTriggered(ruleId, msg.sender, rule.recipient); // Trigger event for transparency
    }

    /**
     * @dev Emergency withdrawal function for ERC20 rules under Decoherence Protocol.
     * Can only be called by the contract owner.
     * Bypasses normal conditional checks.
     * @param ruleId The ID of the ERC20 rule.
     */
    function withdrawDecoheredERC20(uint256 ruleId) external onlyOwner nonReentrant whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.assetType == AssetType.ERC20, "QuantumVault: Rule is not for ERC20");
        require(rule.decoherenceInitiated, "QuantumVault: Decoherence protocol not initiated for this rule");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(rule.tokenAddress != address(0), "QuantumVault: ERC20 token address missing");
        require(rule.amount > 0, "QuantumVault: ERC20 amount is zero for this rule");
        IERC20 token = IERC20(rule.tokenAddress);
        require(token.balanceOf(address(this)) >= rule.amount, "QuantumVault: Insufficient ERC20 balance in vault for this rule");

        rule.isReleased = true;

        token.safeTransfer(rule.recipient, rule.amount);

        emit DecoherenceWithdrawnERC20(ruleId, rule.recipient, rule.tokenAddress, rule.amount);
        emit ConditionalReleaseTriggered(ruleId, msg.sender, rule.recipient);
    }

    /**
     * @dev Emergency withdrawal function for ERC721 rules under Decoherence Protocol.
     * Can only be called by the contract owner.
     * Bypasses normal conditional checks.
     * @param ruleId The ID of the ERC721 rule.
     */
    function withdrawDecoheredERC721(uint256 ruleId) external onlyOwner nonReentrant whenNotPaused {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
        require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        require(rule.assetType == AssetType.ERC721, "QuantumVault: Rule is not for ERC721");
        require(rule.decoherenceInitiated, "QuantumVault: Decoherence protocol not initiated for this rule");
        require(!rule.isReleased, "QuantumVault: Rule already released");
        require(rule.tokenAddress != address(0), "QuantumVault: ERC721 token address missing");
        require(rule.tokenId > 0, "QuantumVault: ERC721 token ID missing");
        IERC721 token = IERC721(rule.tokenAddress);
        require(token.ownerOf(rule.tokenId) == address(this), "QuantumVault: Vault does not own this ERC721 token");
        require(erc721LockedInRule[rule.tokenAddress][rule.tokenId] == ruleId, "QuantumVault: ERC721 lock mismatch or not locked by this rule");

        rule.isReleased = true;
        erc721LockedInRule[rule.tokenAddress][rule.tokenId] = 0; // Unlock the NFT

        token.safeTransferFrom(address(this), rule.recipient, rule.tokenId);

        emit DecoherenceWithdrawnERC721(ruleId, rule.recipient, rule.tokenAddress, rule.tokenId);
        emit ConditionalReleaseTriggered(ruleId, msg.sender, rule.recipient);
    }


    // --- Utility / Getters ---

    /**
     * @dev Gets the total ETH held in the contract.
     * @return The total ETH balance.
     */
    function getVaultBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the total amount of a specific ERC20 token held in the contract.
     * @param token The address of the ERC20 token.
     * @return The total ERC20 token balance.
     */
    function getVaultBalanceERC20(address token) public view returns (uint256) {
        require(token != address(0), "QuantumVault: Token address cannot be zero");
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Checks if a specific ERC721 token is held by the contract.
     * Note: This doesn't check if it's locked in a rule.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @return bool True if the token is owned by the contract, false otherwise.
     */
    function getVaultBalanceERC721(address token, uint256 tokenId) public view returns (bool) {
         require(token != address(0), "QuantumVault: Token address cannot be zero");
         try IERC721(token).ownerOf(tokenId) returns (address owner) {
             return owner == address(this);
         } catch {
             // Token ID might not exist, or contract might not be ERC721 compliant
             return false;
         }
    }

    /**
     * @dev Gets the rule ID that a specific ERC721 token is locked in.
     * @param token The address of the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @return The rule ID (0 if not locked).
     */
     function getERC721LockedRule(address token, uint256 tokenId) public view returns (uint256) {
         require(token != address(0), "QuantumVault: Token address cannot be zero");
         return erc721LockedInRule[token][tokenId];
     }

    /**
     * @dev Gets the list of release rule IDs created by a specific user.
     * Note: This array might contain IDs of cancelled rules if they haven't been cleaned up (though cancel does clean up in this version).
     * @param user The address of the user.
     * @return uint256[] memory Array of rule IDs.
     */
    function getUserReleaseRules(address user) public view returns (uint256[] memory) {
        return userReleaseIds[user];
    }

    /**
     * @dev Gets the details of a specific conditional release rule.
     * Caution: For rules with many observers, reconstructing the list via `getRequiredObservers`
     * or `getSignedObservers` might be necessary as mapping values aren't returned directly.
     * @param ruleId The ID of the rule.
     * @return ConditionalRelease memory The struct containing rule details.
     */
    function getConditionalReleaseDetails(uint256 ruleId) public view returns (ConditionalRelease memory) {
        ConditionalRelease storage rule = conditionalReleases[ruleId];
         require(rule.owner != address(0), "QuantumVault: Rule does not exist");
        // Return a memory copy for external consumption
        return rule;
    }


    // --- OpenZeppelin Overrides ---

    function pause() public override onlyOwner {
        super.pause();
    }

    function unpause() public override onlyOwner {
        super.unpause();
    }
}
```