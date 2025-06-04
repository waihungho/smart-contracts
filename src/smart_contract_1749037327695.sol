Okay, here is a smart contract concept I've designed called `QuantumVault`. It focuses on a multi-layered, condition-based system for unlocking assets or capabilities, incorporating various on-chain and external data dependencies to create complex release mechanisms. It's not a direct copy of common DeFi or NFT protocols, aiming for a novel combination of features.

**Concept:**

The `QuantumVault` holds funds (ETH or ERC-20) and allows an owner to configure multiple "Vault Layers". Each layer has a set of *conditions* that must *all* be met simultaneously for that layer to become "unlocked". Unlocking a layer can add to a specific user's *claimable balance* from the vault or potentially trigger other internal state changes. This allows for complex escrow, multi-stage releases, gamified unlocks, or conditional access based on a combination of time, external data (like price), on-chain events, and user interaction (like revealing a secret).

**Interesting, Advanced, Creative, Trendy Aspects:**

1.  **Multi-factor Conditional Logic:** Unlocking depends on *all* conditions within a layer being true at the moment of `attemptUnlock`.
2.  **Layered Release:** Multiple independent layers can control access to different amounts or stages of the vault's contents.
3.  **Diverse Condition Types:** Includes common (time) and less common on-chain/external dependencies (price oracle, block hash, external contract state, NFT ownership, secret reveal).
4.  **Claimable Balance System:** Instead of direct withdrawal upon unlock, unlocking a layer contributes to a user's total `claimableAmount`, which they can withdraw later. This separates the unlock trigger from the withdrawal action.
5.  **On-chain "Secret" Integration:** Requires users to reveal a pre-computed hash secret to meet a specific condition type.
6.  **NFT Gating:** Access/unlock based on owning a specific NFT.
7.  **Dependency Conditions:** Layers can depend on other layers having been unlocked previously.
8.  **Dynamic Configuration:** Owner can configure layers and update certain condition parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Assuming standard interfaces are permissible as they define standards, not specific implementations.
// In a real scenario, import from node_modules/@openzeppelin/contracts/... or similar audited libraries.
// For this exercise, rudimentary interfaces are defined or assumed for brevity.
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

// Minimal Oracle interface (e.g., Chainlink Price Feed)
interface IPriceOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

// Minimal ERC721 interface for ownership check
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

// --- OUTLINE ---
// 1. State Variables: Contract owner, paused state, total deposits, layer counter, layer data, user claimable/claimed balances.
// 2. Enums & Structs: Condition types, Condition details, VaultLayer structure.
// 3. Events: For key actions like deposits, layer configuration, unlocks, claims, ownership changes, pausing.
// 4. Modifiers: Access control (onlyOwner, whenNotPaused, whenPaused), state checks (layerExists).
// 5. Constructor: Initialize owner and state.
// 6. Receive/Fallback: Handle direct ETH deposits.
// 7. Deposit Functions: depositETH, depositERC20.
// 8. Configuration Functions (Owner Only): addVaultLayer, configureLayerConditions, updateConditionParameter, setLayerRecipientAndAmount, setSecretHash.
// 9. Core Logic (Internal Helpers): check various condition types (_checkTimeWindow, _checkPriceOracle, etc.), _evaluateLayerConditions.
// 10. Core Action Functions: attemptUnlock (users try to unlock a layer).
// 11. Withdrawal/Claim Functions: claimUnlockedFunds (users withdraw claimable balance).
// 12. View Functions: Get total deposits, get layer config/status, get user claimable/claimed amounts, get condition details, get total layers.
// 13. Admin/Safety Functions (Owner Only): pause, unpause, emergencyWithdrawAdmin, transferOwnership, renounceOwnership.
// 14. Utility View Functions: isLayerUnlocked, isPaused, owner.

// --- FUNCTION SUMMARY ---
// (Public/External Functions + Key Internal Helpers for >= 20 count)
// constructor() - Initializes the contract with the deployer as owner. (1)
// receive() - Allows receiving direct ETH transfers. (2)
// fallback() - Optional: handles calls to undefined functions or sends with data. (3)
// depositETH() - Deposits ETH into the vault. (4)
// depositERC20(address tokenAddress, uint256 amount) - Deposits a specific ERC-20 token into the vault. (5)
// addVaultLayer() - Owner adds a new empty layer configuration. (6)
// configureLayerConditions(uint256 layerId, Condition[] memory newConditions) - Owner sets the conditions for a specific layer. (7)
// updateConditionParameter(uint256 layerId, uint256 conditionIndex, int256 param) - Owner updates a specific numerical parameter within a condition. (8)
// setLayerRecipientAndAmount(uint256 layerId, address recipient, uint256 amount) - Owner sets who receives claimable balance and how much upon layer unlock. (9)
// setSecretHash(uint256 layerId, uint256 conditionIndex, bytes32 secretHash) - Owner sets the hash for a SECRET_REVEAL condition. (10)
// attemptUnlock(uint256 layerId, bytes32 secret) - User attempts to meet conditions and unlock a layer, providing secret if needed. (11)
// claimUnlockedFunds(address tokenAddress) - User claims their available unlocked ETH (tokenAddress = address(0)) or ERC20 balance. (12)
// pause() - Owner pauses contract functionality. (13)
// unpause() - Owner unpauses contract functionality. (14)
// emergencyWithdrawAdmin(address tokenAddress) - Owner can emergency withdraw under specific, limited conditions (e.g., paused state). (15)
// transferOwnership(address newOwner) - Owner transfers ownership. (16)
// renounceOwnership() - Owner renounces ownership (becomes zero address). (17)
// getETHBalance() - View: Returns contract's ETH balance. (18)
// getERC20Balance(address tokenAddress) - View: Returns contract's balance of a specific ERC-20 token. (19)
// getLayerConfig(uint256 layerId) - View: Returns configuration details of a layer. (20)
// getLayerStatus(uint256 layerId) - View: Returns the current unlocked status and timestamp of a layer. (21)
// getUserClaimableAmount(address user, address tokenAddress) - View: Returns amount user can claim for ETH or a token. (22)
// getUserClaimedAmount(address user, address tokenAddress) - View: Returns amount user has already claimed. (23)
// getTotalLayers() - View: Returns the total number of configured layers. (24)
// getConditionDetails(uint256 layerId, uint256 conditionIndex) - View: Returns details of a specific condition within a layer. (25)
// isLayerUnlocked(uint256 layerId) - View: Simple boolean check if a layer is unlocked. (26)
// isPaused() - View: Returns the paused state. (27)
// owner() - View: Returns the contract owner. (28)

// Internal Helper Functions (Logic units contributing to complexity & function count):
// _checkTimeWindow(...) - Internal: Checks if current time is within a window.
// _checkPriceOracle(...) - Internal: Checks if oracle price meets condition. Needs IPriceOracle interface & address.
// _checkBlockHashMatch(...) - Internal: Checks if current block hash matches criteria.
// _checkSecretReveal(...) - Internal: Checks if revealed secret matches hash (used within attemptUnlock).
// _checkExternalContractState(...) - Internal: Checks state on another contract (simulated).
// _checkPreviousLayerUnlocked(...) - Internal: Checks if a dependent layer is unlocked.
// _checkMinBalanceHeld(...) - Internal: Checks if an address holds a minimum balance of a token.
// _checkNFTOwnership(...) - Internal: Checks if an address owns a specific NFT. Needs IERC721 interface & address.
// _evaluateLayerConditions(...) - Internal: Evaluates ALL conditions for a layer.

contract QuantumVault {
    address private _owner;
    bool private _paused;

    uint256 private _nextLayerId; // Counter for unique layer IDs
    mapping(uint256 => VaultLayer) public vaultLayers; // Layer configurations and state

    // Track total deposited funds per token
    mapping(address => uint256) private _totalDepositedERC20;
    uint256 private _totalDepositedETH;

    // Track claimable balances for each user per token based on unlocked layers
    mapping(address => mapping(address => uint256)) private _userClaimable;
    // Track claimed balances for each user per token to prevent double claiming
    mapping(address => mapping(address => uint256)) private _userClaimed;

    // External dependencies (Owner configurable or set in constructor)
    address public priceOracleAddress;
    address public nftContractAddress; // Example: for ConditionType.NFT_OWNERSHIP

    enum ConditionType {
        NONE, // Default or unconfigured state
        TIME_WINDOW, // Params: [startTime, endTime] (unix timestamps)
        PRICE_ORACLE, // Params: [oracleThreshold, comparisonType]. comparisonType: 0 = >=, 1 = <=
        BLOCK_HASH_MATCH, // Params: [blockNumberOffset, hashSegmentLength, targetHashSegment]. blockNumberOffset: relative to current, 0 for current, 1 for next etc. hashSegmentLength: num bytes from start. targetHashSegment: the bytes to match.
        SECRET_REVEAL, // Params: [0, 0]. Requires user to provide pre-image of a stored hash. Stored hash in layer config.
        EXTERNAL_CONTRACT_STATE, // Params: [targetValue, comparisonType]. Needs externalContractAddress and function signature hash in layer config.
        PREVIOUS_LAYER_UNLOCKED, // Params: [dependencyLayerId, 0]
        MIN_BALANCE_HELD, // Params: [requiredAmount, 0]. Needs tokenAddress in layer config.
        NFT_OWNERSHIP // Params: [tokenId, 0]. Needs nftContractAddress in state variables.
    }

    struct Condition {
        ConditionType conditionType;
        int256 param1;
        int256 param2;
        address targetAddress; // e.g., token address for MIN_BALANCE, contract address for EXTERNAL_CONTRACT_STATE
        bytes32 dataHash; // e.g., secret hash for SECRET_REVEAL, function signature hash for EXTERNAL_CONTRACT_STATE
    }

    struct VaultLayer {
        bool isConfigured;
        bool isUnlocked;
        uint256 unlockedTimestamp;
        address unlockRecipient; // Address whose claimable balance increases
        uint256 claimableAmountPerUnlock; // Amount added to recipient's claimable balance (in wei)
        address claimableTokenAddress; // Address of the token (0x0 for ETH)
        Condition[] conditions;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event Deposit(address indexed tokenAddress, address indexed depositor, uint256 amount);
    event LayerAdded(uint256 indexed layerId);
    event LayerConfigured(uint256 indexed layerId);
    event ConditionParameterUpdated(uint256 indexed layerId, uint256 indexed conditionIndex, int256 param1, int256 param2, address targetAddress, bytes32 dataHash);
    event LayerRecipientAndAmountSet(uint256 indexed layerId, address indexed recipient, address indexed tokenAddress, uint256 amount);
    event LayerUnlockAttempt(uint256 indexed layerId, address indexed caller, bool success);
    event LayerUnlocked(uint256 indexed layerId, address indexed recipient, address indexed tokenAddress, uint256 amountAddedToClaimable, uint256 timestamp);
    event FundsClaimed(address indexed tokenAddress, address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed tokenAddress, address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier layerExists(uint256 layerId) {
        require(layerId < _nextLayerId, "Layer does not exist");
        require(vaultLayers[layerId].isConfigured, "Layer not configured");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _paused = false;
        _nextLayerId = 0;
    }

    // Fallback function to accept direct ETH deposits
    receive() external payable whenNotPaused {
        depositETH();
    }

    // Fallback function for calls with data to unsupported functions
    fallback() external payable {
        revert("Function not found or contract is paused");
    }

    // --- Deposit Functions ---

    function depositETH() public payable whenNotPaused {
        require(msg.value > 0, "Must send non-zero ETH");
        _totalDepositedETH += msg.value;
        emit Deposit(address(0), msg.sender, msg.value);
    }

    function depositERC20(address tokenAddress, uint256 amount) public whenNotPaused {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Must deposit non-zero amount");

        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "ERC20 transfer failed");

        _totalDepositedERC20[tokenAddress] += amount;
        emit Deposit(tokenAddress, msg.sender, amount);
    }

    // --- Configuration Functions (Owner Only) ---

    function addVaultLayer() public onlyOwner {
        uint256 layerId = _nextLayerId;
        // Initialize with default values, set isConfigured false initially
        vaultLayers[layerId] = VaultLayer({
            isConfigured: false,
            isUnlocked: false,
            unlockedTimestamp: 0,
            unlockRecipient: address(0),
            claimableAmountPerUnlock: 0,
            claimableTokenAddress: address(0),
            conditions: new Condition[](0)
        });
        _nextLayerId++;
        emit LayerAdded(layerId);
    }

    function configureLayerConditions(uint256 layerId, Condition[] memory newConditions) public onlyOwner layerExists(layerId) {
        vaultLayers[layerId].conditions = newConditions;
        vaultLayers[layerId].isConfigured = true; // Mark as configured once conditions are set
        emit LayerConfigured(layerId);
    }

    // Flexible function to update a single parameter within a condition
    function updateConditionParameter(
        uint256 layerId,
        uint256 conditionIndex,
        int256 param1,
        int256 param2,
        address targetAddr,
        bytes32 dataH
    ) public onlyOwner layerExists(layerId) {
        require(conditionIndex < vaultLayers[layerId].conditions.length, "Condition index out of bounds");
        vaultLayers[layerId].conditions[conditionIndex].param1 = param1;
        vaultLayers[layerId].conditions[conditionIndex].param2 = param2;
        vaultLayers[layerId].conditions[conditionIndex].targetAddress = targetAddr;
        vaultLayers[layerId].conditions[conditionIndex].dataHash = dataH;
        emit ConditionParameterUpdated(layerId, conditionIndex, param1, param2, targetAddr, dataH);
    }

    function setLayerRecipientAndAmount(uint256 layerId, address recipient, address tokenAddress, uint256 amount) public onlyOwner layerExists(layerId) {
        require(recipient != address(0), "Invalid recipient address");
        vaultLayers[layerId].unlockRecipient = recipient;
        vaultLayers[layerId].claimableAmountPerUnlock = amount;
        vaultLayers[layerId].claimableTokenAddress = tokenAddress; // 0x0 for ETH
        emit LayerRecipientAndAmountSet(layerId, recipient, tokenAddress, amount);
    }

    // Owner sets the secret hash for a specific SECRET_REVEAL condition
    function setSecretHash(uint256 layerId, uint256 conditionIndex, bytes32 secretHash) public onlyOwner layerExists(layerId) {
        require(conditionIndex < vaultLayers[layerId].conditions.length, "Condition index out of bounds");
        require(vaultLayers[layerId].conditions[conditionIndex].conditionType == ConditionType.SECRET_REVEAL, "Condition is not SECRET_REVEAL type");
        vaultLayers[layerId].conditions[conditionIndex].dataHash = secretHash;
        emit ConditionParameterUpdated(layerId, conditionIndex, 0, 0, address(0), secretHash); // Use general update event
    }

    // --- Core Logic (Internal Helpers) ---

    function _checkTimeWindow(int256 startTime, int256 endTime) internal view returns (bool) {
        uint256 currentTime = block.timestamp;
        return uint256(startTime) <= currentTime && currentTime <= uint256(endTime);
    }

    function _checkPriceOracle(int256 threshold, int256 comparisonType) internal view returns (bool) {
        require(priceOracleAddress != address(0), "Price oracle not set");
        IPriceOracle oracle = IPriceOracle(priceOracleAddress);
        int256 price = oracle.latestAnswer();
        if (comparisonType == 0) { // >=
            return price >= threshold;
        } else { // <=
            return price <= threshold;
        }
    }

    function _checkBlockHashMatch(int256 blockNumberOffset, int256 segmentLength, bytes32 targetHashSegment) internal view returns (bool) {
        require(block.number > uint256(blockNumberOffset), "Block number offset too large");
        bytes32 blockHash = blockhash(block.number - uint256(blockNumberOffset));
        // Basic segment comparison - needs careful handling of segmentLength (max 32 bytes)
        require(segmentLength > 0 && segmentLength <= 32, "Invalid segment length");
        bytes32 blockHashSegment = blockHash & bytes32(uint256(2**(uint256(segmentLength) * 8) - 1) << (32 - uint256(segmentLength)) * 8); // Masking
        return blockHashSegment == targetHashSegment;
    }

     // Note: Secret reveal requires the secret *at the time of calling attemptUnlock*.
     // The hash is stored in the layer's condition dataHash.
    function _checkSecretReveal(bytes32 providedSecretPreimage, bytes32 storedSecretHash) internal pure returns (bool) {
         // require(providedSecretPreimage != bytes32(0), "Secret preimage must be provided"); // Not strictly needed here, check in attemptUnlock
         return keccak256(abi.encodePacked(providedSecretPreimage)) == storedSecretHash;
     }


    // This is a simulation. Actual external calls need interfaces and might fail.
    // Assumes the target contract has a view function returning a uint256 or similar.
    function _checkExternalContractState(address targetContract, bytes32 functionSigHash, int256 targetValue, int256 comparisonType) internal view returns (bool) {
        // This is highly simplified. A real implementation would require a generic way
        // to call external contracts or specific interfaces.
        // For demonstration, let's assume a simple check against a public variable or view function.
        // We can't reliably call arbitrary functions with arbitrary return types here.
        // Let's simulate checking a boolean state variable or a simple uint256 getter.
        // This simulation assumes `targetContract` has a boolean `isStateTrue` or uint256 `getValue`.
        // In practice, this would need a pre-defined interface or a more complex low-level call with abi.decode.

        // Simplistic simulation: requires targetContract to have a view function
        // e.g., `uint256 getValue()` and `functionSigHash` is its selector.
        // This is fragile and for concept only.
        // bytes memory data = abi.encodeWithSelector(bytes4(functionSigHash));
        // (bool success, bytes memory result) = targetContract.staticcall(data);
        // require(success, "External contract call failed");
        // uint256 externalValue = abi.decode(result, (uint256)); // Assumes returns uint256

        // Since generic external contract calls are complex and unsafe without strict interfaces,
        // let's make this condition type check if a boolean *flag* is set on a *known* external contract.
        // Or, check if a specific address *is* the owner of an external contract.
        // Let's redefine EXTERNAL_CONTRACT_STATE to check if a targetAddress is the owner of targetContract.
        // targetAddress = address to check, targetContract = contract with owner() view function.
        // functionSigHash unused in this redefinition. params unused.
        // If `targetContract` has an `owner()` function:
        try OwnableMock(targetContract).owner() returns (address contractOwner) {
            return contractOwner == targetAddress;
        } catch {
            // If external contract doesn't have owner(), or call fails
            return false;
        }
    }

    // Mock Ownable interface for the external contract state check simulation
    interface OwnableMock {
        function owner() external view returns (address);
    }


    function _checkPreviousLayerUnlocked(uint256 dependencyLayerId) internal view returns (bool) {
        if (dependencyLayerId >= _nextLayerId) {
            return false; // Dependent layer doesn't exist
        }
        // Note: Does *not* require the dependent layer to be configured, only that it was unlocked.
        return vaultLayers[dependencyLayerId].isUnlocked;
    }

    function _checkMinBalanceHeld(address tokenAddress, address account, uint256 requiredAmount) internal view returns (bool) {
         if (tokenAddress == address(0)) {
             return account.balance >= requiredAmount;
         } else {
             IERC20 token = IERC20(tokenAddress);
             return token.balanceOf(account) >= requiredAmount;
         }
    }

    function _checkNFTOwnership(address nftContract, address account, uint256 tokenId) internal view returns (bool) {
        require(nftContract != address(0), "NFT contract address not set for condition");
        IERC721 nft = IERC721(nftContract);
        try nft.ownerOf(tokenId) returns (address currentOwner) {
            return currentOwner == account;
        } catch {
            // If token ID does not exist or call fails
            return false;
        }
    }

    // Evaluates all conditions for a given layer
    function _evaluateLayerConditions(uint256 layerId, bytes32 providedSecret) internal view returns (bool) {
        require(layerId < _nextLayerId && vaultLayers[layerId].isConfigured, "Layer does not exist or is not configured");

        Condition[] memory conditions = vaultLayers[layerId].conditions;
        if (conditions.length == 0) {
             // A layer with no conditions is trivially met? Or requires unlockRecipient/Amount set?
             // Let's require at least one condition unless explicitly designed otherwise.
             // For this contract, let's say no conditions means cannot be unlocked via attemptUnlock.
             return false;
        }

        bool allConditionsMet = true;
        for (uint i = 0; i < conditions.length; i++) {
            bool currentConditionMet = false;
            Condition memory cond = conditions[i];

            if (cond.conditionType == ConditionType.TIME_WINDOW) {
                currentConditionMet = _checkTimeWindow(cond.param1, cond.param2);
            } else if (cond.conditionType == ConditionType.PRICE_ORACLE) {
                currentConditionMet = _checkPriceOracle(cond.param1, cond.param2);
            } else if (cond.conditionType == ConditionType.BLOCK_HASH_MATCH) {
                 currentConditionMet = _checkBlockHashMatch(cond.param1, cond.param2, cond.dataHash);
            } else if (cond.conditionType == ConditionType.SECRET_REVEAL) {
                 currentConditionMet = _checkSecretReveal(providedSecret, cond.dataHash);
            } else if (cond.conditionType == ConditionType.EXTERNAL_CONTRACT_STATE) {
                // Using the redefined check: targetAddress is owner of targetContract (cond.targetAddress is owner, cond.param1 is contract address)
                // This redefinition makes the params/targetAddress usage slightly inconsistent with the struct definition comment, but fits the helper check.
                currentConditionMet = _checkExternalContractState(cond.targetAddress, cond.dataHash, cond.param1, cond.param2);
            } else if (cond.conditionType == ConditionType.PREVIOUS_LAYER_UNLOCKED) {
                 currentConditionMet = _checkPreviousLayerUnlocked(uint256(cond.param1));
            } else if (cond.conditionType == ConditionType.MIN_BALANCE_HELD) {
                 // targetAddress is the account to check balance for, param1 is requiredAmount
                 currentConditionMet = _checkMinBalanceHeld(cond.targetAddress, msg.sender, uint256(cond.param1)); // Check caller's balance
            } else if (cond.conditionType == ConditionType.NFT_OWNERSHIP) {
                 // targetAddress is the NFT contract, param1 is the tokenId
                currentConditionMet = _checkNFTOwnership(cond.targetAddress, msg.sender, uint256(cond.param1)); // Check caller's ownership
            }
            // Add more condition types here

            if (!currentConditionMet) {
                allConditionsMet = false;
                break; // Optimization: if one condition fails, the whole layer fails
            }
        }
        return allConditionsMet;
    }


    // --- Core Action Function ---

    // Anyone can attempt to unlock a layer by meeting its conditions.
    // The secret parameter is only used if a SECRET_REVEAL condition is present.
    function attemptUnlock(uint256 layerId, bytes32 secret) public whenNotPaused layerExists(layerId) {
        VaultLayer storage layer = vaultLayers[layerId];
        require(!layer.isUnlocked, "Layer is already unlocked");
        require(layer.unlockRecipient != address(0), "Layer recipient not set"); // Must have a recipient to add claimable amount

        bool success = _evaluateLayerConditions(layerId, secret);

        emit LayerUnlockAttempt(layerId, msg.sender, success);

        if (success) {
            layer.isUnlocked = true;
            layer.unlockedTimestamp = block.timestamp;

            // Add amount to the designated recipient's claimable balance
            _userClaimable[layer.unlockRecipient][layer.claimableTokenAddress] += layer.claimableAmountPerUnlock;

            emit LayerUnlocked(
                layerId,
                layer.unlockRecipient,
                layer.claimableTokenAddress,
                layer.claimableAmountPerUnlock,
                block.timestamp
            );
        } else {
             // Optionally add specific error details based on which condition failed (more complex)
             revert("Layer conditions not met");
        }
    }

    // --- Withdrawal/Claim Functions ---

    function claimUnlockedFunds(address tokenAddress) public whenNotPaused {
        address user = msg.sender;
        uint256 claimable = _userClaimable[user][tokenAddress];
        uint256 claimed = _userClaimed[user][tokenAddress];
        uint256 availableToClaim = claimable - claimed;

        require(availableToClaim > 0, "No funds available to claim for this token");

        // Check if contract has enough balance (might be drained by other claims)
        uint256 contractBalance;
        if (tokenAddress == address(0)) {
            contractBalance = address(this).balance;
        } else {
            IERC20 token = IERC20(tokenAddress);
            contractBalance = token.balanceOf(address(this));
        }

        uint256 amountToWithdraw = availableToClaim;
        if (amountToWithdraw > contractBalance) {
             // Cannot withdraw more than contract holds
             amountToWithdraw = contractBalance;
        }

        require(amountToWithdraw > 0, "Insufficient contract balance for withdrawal");

        _userClaimed[user][tokenAddress] += amountToWithdraw;

        if (tokenAddress == address(0)) {
            (bool success, ) = user.call{value: amountToWithdraw}("");
            require(success, "ETH withdrawal failed");
        } else {
            IERC20 token = IERC20(tokenAddress);
            require(token.transfer(user, amountToWithdraw), "ERC20 withdrawal failed");
        }

        emit FundsClaimed(tokenAddress, user, amountToWithdraw);
    }

    // --- Admin/Safety Functions (Owner Only) ---

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // Emergency withdraw function - maybe only callable when paused?
    // Or add a time delay, or requires multiple conditions (like in a real DAO/multisig)?
    // For this example, allow owner to withdraw when paused.
    function emergencyWithdrawAdmin(address tokenAddress) public onlyOwner whenPaused {
        uint256 amount;
        if (tokenAddress == address(0)) {
            amount = address(this).balance;
            (bool success, ) = _owner.call{value: amount}("");
            require(success, "Emergency ETH withdrawal failed");
             _totalDepositedETH = 0; // Reset tracked balance as all is withdrawn
        } else {
            IERC20 token = IERC20(tokenAddress);
            amount = token.balanceOf(address(this));
            require(token.transfer(_owner, amount), "Emergency ERC20 withdrawal failed");
             _totalDepositedERC20[tokenAddress] = 0; // Reset tracked balance
        }
        emit EmergencyWithdraw(tokenAddress, _owner, amount);
         // Note: This emergency withdraw ignores claimable balances.
         // In a real system, this needs careful consideration of user funds vs admin capability.
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() public onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    // --- View Functions ---

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

     function getERC20Balance(address tokenAddress) public view returns (uint256) {
         if (tokenAddress == address(0)) return 0; // Cannot get ERC20 balance for address(0)
         IERC20 token = IERC20(tokenAddress);
         return token.balanceOf(address(this));
     }

    function getLayerConfig(uint256 layerId) public view layerExists(layerId) returns (
        bool isConfigured,
        bool isUnlocked,
        uint256 unlockedTimestamp,
        address unlockRecipient,
        uint256 claimableAmountPerUnlock,
        address claimableTokenAddress,
        Condition[] memory conditions // Note: Returning complex types like arrays can be gas-intensive off-chain.
    ) {
        VaultLayer storage layer = vaultLayers[layerId];
        return (
            layer.isConfigured,
            layer.isUnlocked,
            layer.unlockedTimestamp,
            layer.unlockRecipient,
            layer.claimableAmountPerUnlock,
            layer.claimableTokenAddress,
            layer.conditions
        );
    }

     function getLayerStatus(uint256 layerId) public view returns (bool isConfigured, bool isUnlocked, uint256 unlockedTimestamp) {
         if (layerId >= _nextLayerId) {
              return (false, false, 0); // Layer does not exist
         }
          VaultLayer storage layer = vaultLayers[layerId];
          return (layer.isConfigured, layer.isUnlocked, layer.unlockedTimestamp);
     }


    function getUserClaimableAmount(address user, address tokenAddress) public view returns (uint256) {
        return _userClaimable[user][tokenAddress] - _userClaimed[user][tokenAddress];
    }

    function getUserClaimedAmount(address user, address tokenAddress) public view returns (uint256) {
        return _userClaimed[user][tokenAddress];
    }

    function getTotalLayers() public view returns (uint256) {
        return _nextLayerId;
    }

     function getConditionDetails(uint256 layerId, uint256 conditionIndex) public view layerExists(layerId) returns (
         ConditionType conditionType,
         int256 param1,
         int256 param2,
         address targetAddress,
         bytes32 dataHash
     ) {
         require(conditionIndex < vaultLayers[layerId].conditions.length, "Condition index out of bounds");
         Condition memory cond = vaultLayers[layerId].conditions[conditionIndex];
         return (cond.conditionType, cond.param1, cond.param2, cond.targetAddress, cond.dataHash);
     }

    // --- Utility View Functions ---

    function isLayerUnlocked(uint256 layerId) public view returns (bool) {
         if (layerId >= _nextLayerId) return false;
         return vaultLayers[layerId].isUnlocked;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function owner() public view returns (address) {
        return _owner;
    }

     // Utility function to set external contract addresses (Owner only)
    function setPriceOracleAddress(address _oracleAddress) public onlyOwner {
        priceOracleAddress = _oracleAddress;
    }

    function setNFTContractAddress(address _nftContractAddress) public onlyOwner {
        nftContractAddress = _nftContractAddress;
    }
}
```