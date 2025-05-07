Okay, here is a Solidity smart contract featuring a unique concept: a "Chronicle Asset" (similar to an NFT, but with dynamic state and complex, configurable transition rules). It incorporates various triggers, internal progress, delegation, and owner overrides, going beyond standard token functionalities.

It's designed to be interesting by having assets evolve based on time, external data (simulated oracle), user actions, or internal progress thresholds, all governed by owner-defined rules. It avoids directly inheriting and merely extending standard ERCs by implementing core ownership/transfer logic internally, focusing on the state management layer as the primary feature.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleAsset
 * @dev A smart contract for managing dynamic assets with evolving states
 *      governed by configurable transition rules. Assets progress through
 *      states based on time, oracle data, caller actions, or internal progress counters.
 *      Designed to be a non-standard asset type focused on stateful behavior.
 */

// --- OUTLINE & FUNCTION SUMMARY ---
/*
1. Contract Setup & Ownership:
   - constructor: Initializes the contract and sets the owner.
   - renounceOwnership: Allows owner to transfer ownership (standard).
   - transferOwnership: Allows owner to transfer ownership (standard).
   - onlyOwner: Modifier to restrict functions to the contract owner.

2. Asset Core Data & Management:
   - AssetData Struct: Holds state, owner, creation time, last transition time, progress, lock status.
   - assets: Mapping from tokenId to AssetData.
   - totalSupply: Counter for total minted assets.
   - ownerToTokens: Mapping from owner address to a list of tokenIds (for tracking).
   - mintAsset: Creates a new asset with an initial state (Owner only).
   - transferAsset: Transfers asset ownership (Token Owner or approved delegate).
   - burnAsset: Destroys an asset (Token Owner or approved delegate).
   - getAssetOwner: Get owner of a specific asset.
   - getAssetState: Get current state of a specific asset.
   - getAssetProgress: Get current progress of a specific asset within its state.
   - getAssetLastTransitionTime: Get timestamp of the last state change for an asset.
   - getAssetCreationTime: Get timestamp when an asset was minted.
   - isAssetLocked: Check if an asset's state transitions are locked.

3. State Transition Rule Management:
   - TriggerType Enum: Defines possible transition triggers (TIME, ORACLE, CALL, PROGRESS_THRESHOLD).
   - TransitionRule Struct: Defines a rule: fromState, trigger type/data, toState, min progress needed, cooldown, enabled status.
   - transitionRules: Mapping from ruleId to TransitionRule.
   - nextRuleId: Counter for unique rule IDs.
   - defineStateTransitionRule: Owner defines a new rule.
   - removeStateTransitionRule: Owner removes/disables a rule.
   - updateStateTransitionRule: Owner modifies an existing rule.
   - getStateTransitionRule: Get details of a specific rule.
   - listDefinedTransitionRuleIds: Get all currently defined rule IDs.

4. State Transition Execution & Checking:
   - triggerStateTransition: Attempts to transition an asset's state based on a rule. Checks eligibility, cooldowns, progress, and trigger conditions. Can be called by anyone if conditions are met and allowed caller isn't set for CALL type.
   - checkTransitionRuleEligibility: Checks *if* a rule is met for an asset *at this moment* (view function).
   - canTriggerRuleNow: Checks if a rule is eligible AND the asset is off cooldown (view function).

5. Trigger-Specific Data & Settings:
   - simulatedOracleData: Owner-managed data for ORACLE trigger type simulation.
   - simulateOracleUpdate: Owner updates the simulated oracle data.
   - setRuleAllowedCaller: Owner sets an address allowed to trigger CALL type rules.
   - isRuleAllowedCaller: Check if an address is allowed to trigger a specific rule.

6. Asset Progress & Lock Management:
   - advanceAssetProgress: Increases an asset's progress counter (Token Owner or Management Delegate).
   - resetAssetProgress: Resets an asset's progress counter (Token Owner or Management Delegate).
   - delegateAssetManagement: Token Owner delegates rights to manage progress/reset for their asset.
   - revokeAssetManagementDelegation: Token Owner revokes management delegation.
   - getAssetManagementDelegate: Get the current management delegate for an asset.
   - lockAsset: Owner locks an asset, preventing state changes via rules.
   - unlockAsset: Owner unlocks an asset.

7. Emergency Owner Overrides:
   - emergencyTransferAsset: Owner can transfer any asset.
   - emergencyBurnAsset: Owner can burn any asset.
   - emergencyForceState: Owner can force an asset to a specific state, ignoring rules/locks (use with caution).

8. Utility & Information:
   - getTokensByOwner: Get all token IDs owned by an address (can be gas-intensive for many tokens).
   - getTokenCountByState: Get the number of assets in a specific state (requires iteration/mapping).
   - setAssetBaseURI: Owner sets base URI for metadata (useful if external metadata exists).
   - getAssetBaseURI: Get the base URI.
   - withdrawEther: Owner can withdraw any Ether sent to the contract.

9. Events:
   - AssetMinted
   - AssetTransferred
   - AssetBurned
   - StateChanged
   - RuleDefined
   - RuleRemoved
   - RuleUpdated
   - OracleUpdated
   - ProgressAdvanced
   - ProgressReset
   - ManagementDelegated
   - ManagementDelegationRevoked
   - AssetLocked
   - AssetUnlocked
   - EmergencyTransfer
   - EmergencyBurn
   - EmergencyForceState
   - RuleAllowedCallerSet
   - AssetBaseURISet
   - EtherWithdrawn
*/


contract ChronicleAsset {

    address public owner;
    uint256 private _totalSupply;
    string private _baseURI;

    enum TriggerType { NONE, TIME, ORACLE, CALL, PROGRESS_THRESHOLD }

    struct AssetData {
        uint8 currentState;
        address assetOwner;
        uint64 creationTime;       // uint64 sufficient for timestamps
        uint64 lastTransitionTime; // timestamp of the last state change
        uint32 progress;           // counter/timer within a state
        bool locked;               // prevents rule-based state transitions
    }

    struct TransitionRule {
        uint8 fromState;
        TriggerType triggerType;
        bytes triggerData;        // Data needed for the trigger (timestamp for TIME, value hash for ORACLE, specific value for CALL/PROGRESS)
        uint8 toState;
        uint32 minProgressRequired; // Minimum progress needed for PROGRESS_THRESHOLD trigger
        uint32 cooldownDuration;    // Seconds cooldown after transition before another can occur from the new state
        bool enabled;               // Allows temporary disabling of rules
    }

    mapping(uint256 => AssetData) public assets;
    mapping(uint256 => TransitionRule) public transitionRules; // ruleId => rule
    mapping(address => uint256[]) private ownerToTokens; // Tracks tokens per owner (gas caution)
    mapping(address => address) public assetManagementDelegates; // assetOwner => delegateAddress
    mapping(uint256 => mapping(address => bool)) public ruleAllowedCallers; // ruleId => callerAddress => isAllowed

    uint256 private nextTokenId;
    uint256 private nextRuleId;
    bytes public simulatedOracleData; // Owner can set this to simulate external data

    // --- Events ---
    event AssetMinted(uint256 indexed tokenId, address indexed owner, uint8 initialState);
    event AssetTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event AssetBurned(uint256 indexed tokenId, address indexed owner);
    event StateChanged(uint256 indexed tokenId, uint8 indexed fromState, uint8 indexed toState, uint256 indexed ruleId);
    event RuleDefined(uint256 indexed ruleId, uint8 fromState, TriggerType triggerType, uint8 toState, uint32 minProgressRequired, uint32 cooldownDuration);
    event RuleRemoved(uint256 indexed ruleId);
    event RuleUpdated(uint256 indexed ruleId, uint8 fromState, TriggerType triggerType, uint8 toState, uint32 minProgressRequired, uint32 cooldownDuration, bool enabled);
    event OracleUpdated(bytes indexed newData);
    event ProgressAdvanced(uint256 indexed tokenId, uint32 newProgress);
    event ProgressReset(uint256 indexed tokenId);
    event ManagementDelegated(address indexed assetOwner, address indexed delegate);
    event ManagementDelegationRevoked(address indexed assetOwner);
    event AssetLocked(uint256 indexed tokenId);
    event AssetUnlocked(uint256 indexed tokenId);
    event EmergencyTransfer(uint256 indexed tokenId, address indexed from, address indexed to, address indexed caller);
    event EmergencyBurn(uint256 indexed tokenId, address indexed owner, address indexed caller);
    event EmergencyForceState(uint256 indexed tokenId, uint8 indexed fromState, uint8 indexed toState, address indexed caller);
    event RuleAllowedCallerSet(uint256 indexed ruleId, address indexed caller, bool allowed);
    event AssetBaseURISet(string newURI);
    event EtherWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier assetExists(uint256 tokenId) {
        require(assets[tokenId].assetOwner != address(0), "Asset does not exist");
        _;
    }

    modifier onlyAssetOwnerOrDelegate(uint256 tokenId) {
        require(assets[tokenId].assetOwner == msg.sender || assetManagementDelegates[assets[tokenId].assetOwner] == msg.sender, "Not authorized for this asset");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        nextTokenId = 1;
        nextRuleId = 1;
    }

    // --- Ownership Functions ---
    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    // --- Asset Core Data & Management ---

    function mintAsset(address to, uint8 initialState) public onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId;
        unchecked { nextTokenId++; }

        AssetData storage newAsset = assets[tokenId];
        newAsset.currentState = initialState;
        newAsset.assetOwner = to;
        newAsset.creationTime = uint64(block.timestamp);
        newAsset.lastTransitionTime = uint64(block.timestamp);
        newAsset.progress = 0;
        newAsset.locked = false;

        _totalSupply++;
        ownerToTokens[to].push(tokenId); // Adds to owner's token list (gas warning for large lists)

        emit AssetMinted(tokenId, to, initialState);
    }

    function transferAsset(uint256 tokenId, address to) public assetExists(tokenId) {
        address currentOwner = assets[tokenId].assetOwner;
        require(msg.sender == currentOwner, "Only asset owner can transfer");
        require(to != address(0), "Cannot transfer to zero address");

        // Update owner mapping (simple removal - inefficient for large lists)
        uint256 tokenCount = ownerToTokens[currentOwner].length;
        for (uint256 i = 0; i < tokenCount; i++) {
            if (ownerToTokens[currentOwner][i] == tokenId) {
                ownerToTokens[currentOwner][i] = ownerToTokens[currentOwner][tokenCount - 1];
                ownerToTokens[currentOwner].pop();
                break;
            }
        }

        assets[tokenId].assetOwner = to;
        ownerToTokens[to].push(tokenId); // Add to new owner's list

        // Clear any management delegation upon transfer
        if (assetManagementDelegates[currentOwner] != address(0)) {
             delete assetManagementDelegates[currentOwner];
             emit ManagementDelegationRevoked(currentOwner);
        }


        emit AssetTransferred(tokenId, currentOwner, to);
    }

    function burnAsset(uint256 tokenId) public assetExists(tokenId) {
        address currentOwner = assets[tokenId].assetOwner;
        require(msg.sender == currentOwner, "Only asset owner can burn");

        // Update owner mapping (simple removal - inefficient for large lists)
        uint256 tokenCount = ownerToTokens[currentOwner].length;
        for (uint256 i = 0; i < tokenCount; i++) {
            if (ownerToTokens[currentOwner][i] == tokenId) {
                ownerToTokens[currentOwner][i] = ownerToTokens[currentOwner][tokenCount - 1];
                ownerToTokens[currentOwner].pop();
                break;
            }
        }

        // Clear any management delegation
        if (assetManagementDelegates[currentOwner] != address(0)) {
             delete assetManagementDelegates[currentOwner];
             emit ManagementDelegationRevoked(currentOwner);
        }

        delete assets[tokenId];
        _totalSupply--;

        emit AssetBurned(tokenId, currentOwner);
    }

    function getAssetOwner(uint256 tokenId) public view assetExists(tokenId) returns (address) {
        return assets[tokenId].assetOwner;
    }

    function getAssetState(uint256 tokenId) public view assetExists(tokenId) returns (uint8) {
        return assets[tokenId].currentState;
    }

    function getAssetProgress(uint256 tokenId) public view assetExists(tokenId) returns (uint32) {
        return assets[tokenId].progress;
    }

    function getAssetLastTransitionTime(uint256 tokenId) public view assetExists(tokenId) returns (uint64) {
        return assets[tokenId].lastTransitionTime;
    }

     function getAssetCreationTime(uint256 tokenId) public view assetExists(tokenId) returns (uint64) {
        return assets[tokenId].creationTime;
    }

     function isAssetLocked(uint256 tokenId) public view assetExists(tokenId) returns (bool) {
        return assets[tokenId].locked;
    }


    // --- State Transition Rule Management ---

    function defineStateTransitionRule(
        uint8 fromState,
        TriggerType triggerType,
        bytes calldata triggerData,
        uint8 toState,
        uint32 minProgressRequired,
        uint32 cooldownDuration
    ) public onlyOwner returns (uint256 ruleId) {
        ruleId = nextRuleId;
        unchecked { nextRuleId++; }

        transitionRules[ruleId] = TransitionRule({
            fromState: fromState,
            triggerType: triggerType,
            triggerData: triggerData,
            toState: toState,
            minProgressRequired: minProgressRequired,
            cooldownDuration: cooldownDuration,
            enabled: true
        });

        emit RuleDefined(ruleId, fromState, triggerType, toState, minProgressRequired, cooldownDuration);
    }

    function removeStateTransitionRule(uint256 ruleId) public onlyOwner {
        require(transitionRules[ruleId].enabled, "Rule not found or already removed");
        transitionRules[ruleId].enabled = false; // Soft remove by disabling

        emit RuleRemoved(ruleId);
    }

    function updateStateTransitionRule(
        uint256 ruleId,
        uint8 fromState,
        TriggerType triggerType,
        bytes calldata triggerData,
        uint8 toState,
        uint32 minProgressRequired,
        uint32 cooldownDuration,
        bool enabled
    ) public onlyOwner {
        require(transitionRules[ruleId].fromState == fromState, "Cannot change 'fromState' in update"); // Prevent changing the 'from' state anchor
        require(transitionRules[ruleId].enabled || enabled, "Rule must be enabled to update or re-enable"); // Can update if enabled or if trying to re-enable

        transitionRules[ruleId].triggerType = triggerType;
        transitionRules[ruleId].triggerData = triggerData;
        transitionRules[ruleId].toState = toState;
        transitionRules[ruleId].minProgressRequired = minProgressRequired;
        transitionRules[ruleId].cooldownDuration = cooldownDuration;
        transitionRules[ruleId].enabled = enabled;

        emit RuleUpdated(ruleId, fromState, triggerType, toState, minProgressRequired, cooldownDuration, enabled);
    }


    function getStateTransitionRule(uint256 ruleId)
        public view
        returns (
            uint8 fromState,
            TriggerType triggerType,
            bytes memory triggerData,
            uint8 toState,
            uint32 minProgressRequired,
            uint32 cooldownDuration,
            bool enabled
        )
    {
         TransitionRule storage rule = transitionRules[ruleId];
         require(rule.enabled, "Rule not found or disabled"); // Only return enabled rules via this getter
         return (
             rule.fromState,
             rule.triggerType,
             rule.triggerData,
             rule.toState,
             rule.minProgressRequired,
             rule.cooldownDuration,
             rule.enabled
         );
    }

    // Note: Listing all rule IDs can be gas-intensive if nextRuleId is very large
    function listDefinedTransitionRuleIds() public view returns (uint256[] memory) {
        uint256[] memory enabledRuleIds = new uint256[](nextRuleId);
        uint256 count = 0;
        // Iterate through potential rule IDs and collect enabled ones
        // This can be inefficient for a very large number of defined rules with gaps
        for (uint256 i = 1; i < nextRuleId; i++) {
            if (transitionRules[i].enabled) {
                enabledRuleIds[count] = i;
                count++;
            }
        }
        // Trim the array
        uint256[] memory result = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            result[i] = enabledRuleIds[i];
        }
        return result;
    }


    // --- State Transition Execution & Checking ---

    function triggerStateTransition(uint256 tokenId, uint256 ruleId, bytes calldata triggerExecutionData) public assetExists(tokenId) {
        AssetData storage asset = assets[tokenId];
        TransitionRule storage rule = transitionRules[ruleId];

        require(rule.enabled, "Rule is not enabled");
        require(asset.currentState == rule.fromState, "Asset is not in the correct starting state for this rule");
        require(!asset.locked, "Asset is locked");
        require(block.timestamp >= asset.lastTransitionTime + rule.cooldownDuration, "Asset is on cooldown");
        require(asset.progress >= rule.minProgressRequired, "Asset progress is insufficient");

        // Check specific trigger conditions
        bool triggerMet = false;
        if (rule.triggerType == TriggerType.TIME) {
            // triggerData should encode a required timestamp
            require(rule.triggerData.length == 8, "Invalid triggerData for TIME");
            uint64 requiredTimestamp = abi.decode(rule.triggerData, (uint64));
            triggerMet = block.timestamp >= requiredTimestamp;
        } else if (rule.triggerType == TriggerType.ORACLE) {
            // triggerData should encode the expected oracle data hash or value
             triggerMet = keccak256(simulatedOracleData) == keccak256(rule.triggerData);
            // Or simple byte comparison: triggerMet = simulatedOracleData == rule.triggerData;
        } else if (rule.triggerType == TriggerType.CALL) {
             // Caller must be allowed for this specific rule
            triggerMet = ruleAllowedCallers[ruleId][msg.sender];
            // Optional: require triggerExecutionData matches rule.triggerData if specific call payload is required
            // require(keccak256(triggerExecutionData) == keccak256(rule.triggerData), "Invalid trigger execution data");
        } else if (rule.triggerType == TriggerType.PROGRESS_THRESHOLD) {
             // Condition already checked by require(asset.progress >= rule.minProgressRequired)
             triggerMet = true;
        } else if (rule.triggerType == TriggerType.NONE) {
             // NONE type can be triggered by anyone if rule is enabled and other conditions met
             triggerMet = true;
        }

        require(triggerMet, "Trigger condition not met");

        uint8 oldState = asset.currentState;
        asset.currentState = rule.toState;
        asset.lastTransitionTime = uint64(block.timestamp);
        asset.progress = 0; // Reset progress on state change

        emit StateChanged(tokenId, oldState, asset.currentState, ruleId);
    }

    function checkTransitionRuleEligibility(uint256 tokenId, uint256 ruleId) public view assetExists(tokenId) returns (bool) {
        AssetData storage asset = assets[tokenId];
        TransitionRule storage rule = transitionRules[ruleId];

        if (!rule.enabled || asset.currentState != rule.fromState || asset.locked || asset.progress < rule.minProgressRequired) {
            return false;
        }

        // Check specific trigger conditions (view context)
        if (rule.triggerType == TriggerType.TIME) {
             if (rule.triggerData.length != 8) return false;
             uint64 requiredTimestamp = abi.decode(rule.triggerData, (uint64));
             return block.timestamp >= requiredTimestamp;
        } else if (rule.triggerType == TriggerType.ORACLE) {
             return keccak256(simulatedOracleData) == keccak256(rule.triggerData);
            // Or simple byte comparison: return simulatedOracleData == rule.triggerData;
        } else if (rule.triggerType == TriggerType.CALL) {
            // Check if *current* caller is allowed for this rule
             return ruleAllowedCallers[ruleId][msg.sender];
             // Note: Cannot check triggerExecutionData in view context unless passed in
        } else if (rule.triggerType == TriggerType.PROGRESS_THRESHOLD) {
             return true; // Already checked progress threshold above
        } else if (rule.triggerType == TriggerType.NONE) {
             return true; // No specific trigger required other than rule/asset conditions
        }

        return false; // Should not reach here
    }

    function canTriggerRuleNow(uint256 tokenId, uint256 ruleId) public view assetExists(tokenId) returns (bool) {
         TransitionRule storage rule = transitionRules[ruleId];
         if (!rule.enabled) return false;

         AssetData storage asset = assets[tokenId];
         if (block.timestamp < asset.lastTransitionTime + rule.cooldownDuration) return false;

         return checkTransitionRuleEligibility(tokenId, ruleId);
    }


    // --- Trigger-Specific Data & Settings ---

    function simulateOracleUpdate(bytes calldata newData) public onlyOwner {
        simulatedOracleData = newData;
        emit OracleUpdated(newData);
    }

    function setRuleAllowedCaller(uint256 ruleId, address caller, bool allowed) public onlyOwner {
        require(transitionRules[ruleId].enabled, "Rule not found or disabled");
        require(transitionRules[ruleId].triggerType == TriggerType.CALL, "Rule trigger type is not CALL");
        ruleAllowedCallers[ruleId][caller] = allowed;
        emit RuleAllowedCallerSet(ruleId, caller, allowed);
    }

    function isRuleAllowedCaller(uint256 ruleId, address caller) public view returns (bool) {
        // Does not require rule to be enabled, just checks the permission mapping
        return ruleAllowedCallers[ruleId][caller];
    }


    // --- Asset Progress & Lock Management ---

    function advanceAssetProgress(uint256 tokenId, uint32 amount) public assetExists(tokenId) onlyAssetOwnerOrDelegate(tokenId) {
         AssetData storage asset = assets[tokenId];
         require(!asset.locked, "Asset is locked, cannot advance progress");
         unchecked { asset.progress += amount; } // Allow progress to exceed minProgressRequired

         emit ProgressAdvanced(tokenId, asset.progress);
    }

    function resetAssetProgress(uint256 tokenId) public assetExists(tokenId) onlyAssetOwnerOrDelegate(tokenId) {
        AssetData storage asset = assets[tokenId];
        require(!asset.locked, "Asset is locked, cannot reset progress");
        asset.progress = 0;

        emit ProgressReset(tokenId);
    }

    function delegateAssetManagement(address delegate) public {
        require(msg.sender == assets[ownerToTokens[msg.sender][0]].assetOwner, "Caller must own at least one asset to delegate"); // Simple check, assumes caller owns at least one token and uses the first one found
        require(delegate != address(0), "Delegate cannot be zero address");
        require(delegate != msg.sender, "Cannot delegate to yourself");

        assetManagementDelegates[msg.sender] = delegate;
        emit ManagementDelegated(msg.sender, delegate);
    }

    function revokeAssetManagementDelegation() public {
         require(msg.sender == assets[ownerToTokens[msg.sender][0]].assetOwner, "Caller must own at least one asset to revoke delegation"); // Simple check as above
         require(assetManagementDelegates[msg.sender] != address(0), "No delegation active for this owner");

        delete assetManagementDelegates[msg.sender];
        emit ManagementDelegationRevoked(msg.sender);
    }

    function getAssetManagementDelegate(address assetOwner) public view returns (address) {
         return assetManagementDelegates[assetOwner];
    }

    function lockAsset(uint256 tokenId) public onlyOwner assetExists(tokenId) {
        require(!assets[tokenId].locked, "Asset is already locked");
        assets[tokenId].locked = true;
        emit AssetLocked(tokenId);
    }

    function unlockAsset(uint256 tokenId) public onlyOwner assetExists(tokenId) {
        require(assets[tokenId].locked, "Asset is not locked");
        assets[tokenId].locked = false;
        emit AssetUnlocked(tokenId);
    }


    // --- Emergency Owner Overrides ---

    function emergencyTransferAsset(uint256 tokenId, address to) public onlyOwner assetExists(tokenId) {
         address currentOwner = assets[tokenId].assetOwner;
         require(to != address(0), "Cannot transfer to zero address");

         // Update owner mapping (simple removal - inefficient)
        uint256 tokenCount = ownerToTokens[currentOwner].length;
        for (uint256 i = 0; i < tokenCount; i++) {
            if (ownerToTokens[currentOwner][i] == tokenId) {
                ownerToTokens[currentOwner][i] = ownerToTokens[currentOwner][tokenCount - 1];
                ownerToTokens[currentOwner].pop();
                break;
            }
        }

        assets[tokenId].assetOwner = to;
        ownerToTokens[to].push(tokenId);

        // Clear any management delegation upon transfer
        if (assetManagementDelegates[currentOwner] != address(0)) {
             delete assetManagementDelegates[currentOwner];
             emit ManagementDelegationRevoked(currentOwner);
        }

         emit EmergencyTransfer(tokenId, currentOwner, to, msg.sender);
    }

    function emergencyBurnAsset(uint256 tokenId) public onlyOwner assetExists(tokenId) {
        address currentOwner = assets[tokenId].assetOwner;

         // Update owner mapping (simple removal - inefficient)
        uint256 tokenCount = ownerToTokens[currentOwner].length;
        for (uint256 i = 0; i < tokenCount; i++) {
            if (ownerToTokens[currentOwner][i] == tokenId) {
                ownerToTokens[currentOwner][i] = ownerToTokens[currentOwner][tokenCount - 1];
                ownerToTokens[currentOwner].pop();
                break;
            }
        }

        // Clear any management delegation
        if (assetManagementDelegates[currentOwner] != address(0)) {
             delete assetManagementDelegates[currentOwner];
             emit ManagementDelegationRevoked(currentOwner);
        }

        delete assets[tokenId];
        _totalSupply--;

        emit EmergencyBurn(tokenId, currentOwner, msg.sender);
    }

    function emergencyForceState(uint256 tokenId, uint8 newState) public onlyOwner assetExists(tokenId) {
        uint8 oldState = assets[tokenId].currentState;
        assets[tokenId].currentState = newState;
        assets[tokenId].lastTransitionTime = uint64(block.timestamp); // Update time for potential future cooldowns
        assets[tokenId].progress = 0; // Reset progress

        // Note: This bypasses rules, lock, cooldowns, and progress checks. Use carefully.
        emit EmergencyForceState(tokenId, oldState, newState, msg.sender);
    }


    // --- Utility & Information ---

    function getTotalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // WARNING: This function can be very gas-intensive for owners with many tokens.
    // It's better practice to track token lists off-chain or use a more gas-efficient mapping structure if needed on-chain.
    function getTokensByOwner(address ownerAddress) public view returns (uint256[] memory) {
        return ownerToTokens[ownerAddress];
    }

    // WARNING: This function iterates over all *possible* token IDs up to nextTokenId.
    // It will be extremely gas-intensive and likely exceed block gas limits for a large number of tokens.
    // A better pattern involves iterating over ownerToTokens mapping per owner, or maintaining state => token lists (also complex).
    function getTokenCountByState(uint8 state) public view returns (uint256) {
        uint256 count = 0;
         // Inefficient iteration, but demonstrates the query intent
        for (uint256 i = 1; i < nextTokenId; i++) {
            if (assets[i].assetOwner != address(0) && assets[i].currentState == state) {
                count++;
            }
        }
        return count;
    }

    function setAssetBaseURI(string memory newURI) public onlyOwner {
        _baseURI = newURI;
        emit AssetBaseURISet(newURI);
    }

    function getAssetBaseURI() public view returns (string memory) {
        return _baseURI;
    }

    function withdrawEther(address payable recipient) public onlyOwner {
        require(recipient != address(0), "Recipient is the zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");

        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Ether withdrawal failed");

        emit EtherWithdrawn(recipient, balance);
    }

    // Receive Ether directly
    receive() external payable {}

    // Fallback for any other calls, allows receiving Ether
    fallback() external payable {}
}
```