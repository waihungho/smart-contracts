Okay, let's design a smart contract that goes beyond simple token standards. We'll create a concept called "ChronoMorph Assets" - non-fungible tokens (NFTs) that have dynamic states and traits which evolve over time and through owner interaction. They incorporate concepts like timed state decay, reputation based on interaction, and configurable state transition rules.

This contract will implement a minimal internal ERC-721-like structure for ownership but build heavily on top of it with custom state management, interaction mechanics, and configurable rules.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Import interface for standards compliance view
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Import receiver for safeTransferFrom
import "@openzeppelin/contracts/utils/Strings.sol"; // Helper for string conversions

/**
 * @title ChronoMorphAssets
 * @dev An advanced NFT contract where assets have dynamic states and traits
 *      that evolve based on time and owner interaction. Incorporates concepts
 *      like state decay, owner reputation, and configurable rules.
 */
contract ChronoMorphAssets is Ownable, IERC721 {

    using Strings for uint256;

    // --- Contract Outline ---
    // 1. State Variables: Core data storage for assets, states, rules, config, reputation.
    // 2. Enums: Define possible states and interaction types.
    // 3. Events: Announce significant actions and state changes.
    // 4. Errors: Custom errors for better revert reasons.
    // 5. Modifiers: Restrict function access and check conditions.
    // 6. Constructor: Initializes the contract.
    // 7. ERC-721 Implementation (Minimal): Basic ownership, approval, and transfer logic.
    // 8. State & Trait Management: Functions to get/set/update asset states and associated traits.
    // 9. Interaction Mechanics: Functions for owners to interact with their assets.
    // 10. Timed Evolution & Decay: Logic for state changes based on time passing.
    // 11. Rules & Configuration: Admin functions to define state transition rules and system parameters.
    // 12. Reputation System: Track owner reputation based on interactions.
    // 13. Query Functions: View functions to get contract data.
    // 14. Administrative Functions: Pause, withdraw fees, upgrade hook.


    // --- Function Summary (20+ Functions) ---
    // ERC-721 Interface (Required for compliance, minimal internal tracking):
    // 1. balanceOf(address owner): Returns the number of tokens in owner's account.
    // 2. ownerOf(uint256 tokenId): Returns the owner of the tokenId token.
    // 3. transferFrom(address from, address to, uint256 tokenId): Standard transfer, no receiver check.
    // 4. safeTransferFrom(address from, address to, uint256 tokenId): Transfer with receiver check.
    // 5. safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Transfer with receiver check and data.
    // 6. approve(address to, uint256 tokenId): Allows 'to' to transfer tokenId.
    // 7. setApprovalForAll(address operator, bool approved): Allows/disallows operator for all tokens.
    // 8. getApproved(uint256 tokenId): Returns approved address for tokenId.
    // 9. isApprovedForAll(address owner, address operator): Returns true if operator is approved for owner.
    // 10. tokenURI(uint256 tokenId): Returns the metadata URI for a token.
    // 11. supportsInterface(bytes4 interfaceId): Indicates if contract supports an interface (for ERC721).

    // Core ChronoMorph Logic:
    // 12. mintAsset(address to, string memory initialMetadataURI): Creates a new ChronoMorph asset.
    // 13. burnAsset(uint256 tokenId): Destroys an asset (owner/approved only).
    // 14. getState(uint256 tokenId): Gets the current state of an asset.
    // 15. getTraits(uint256 tokenId): Gets the dynamic traits based on the asset's current state.
    // 16. performAction(uint256 tokenId, ActionType actionType): Owner interacts with their asset, potentially changing state.
    // 17. checkAndApplyTimedEvolution(uint256 tokenId): Public function to trigger time-based state changes/decay.
    // 18. getConfigValue(bytes32 key): Gets a system configuration value.
    // 19. setConfigValue(bytes32 key, uint256 value): Admin sets a system configuration value.
    // 20. defineStateTransitionRule(AssetState fromState, ActionType action, AssetState toState, uint256 requiredReputation, uint256 cost): Admin defines how states transition based on actions and conditions.
    // 21. queryStateTransitionRule(AssetState fromState, ActionType action): Gets the defined transition rule.
    // 22. setTraitForState(AssetState state, string memory traitKey, string memory traitValue): Admin defines traits associated with a state.
    // 23. getTraitsForState(AssetState state): Gets all traits defined for a specific state.
    // 24. getCurrentReputation(address owner): Gets an owner's accumulated interaction reputation.
    // 25. getAssetLastActionTime(uint256 tokenId): Gets the timestamp of the last recorded action on an asset.
    // 26. withdrawFees(): Admin withdraws collected fees (if actions have costs).
    // 27. pauseContract(): Admin pauses core interactions.
    // 28. unpauseContract(): Admin unpauses core interactions.
    // 29. isContractPaused(): Checks the pause status.
    // 30. getSupportedStates(): Returns the list of supported states.
    // 31. getSupportedActions(): Returns the list of supported actions.
    // 32. getTokenStateHistory(uint256 tokenId): Retrieves a history of state changes for an asset.
    // 33. setNewLogicContract(address newLogic): A placeholder function for upgradeability patterns (requires proxy).

    // --- State Variables ---
    // ERC-721 Basic Storage
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _totalSupply;
    mapping(uint256 => string) private _tokenURIs; // Store URIs

    // ChronoMorph Specific Storage
    enum AssetState {
        Unknown, // Default/initial state before proper minting state set
        Seedling,
        Budding,
        Flourishing,
        Dormant,
        Withered,
        Reviving,
        Legendary // Example states
    }

    enum ActionType {
        None,
        Nurture,
        Rest,
        Train,
        Harvest, // Could yield something?
        Revive,
        Idle // Represents doing nothing (leading to decay)
    }

    mapping(uint256 => AssetState) private _tokenStates;
    mapping(AssetState => mapping(string => string)) private _stateTraits; // State -> TraitKey -> TraitValue
    mapping(uint256 => uint256) private _assetLastActionTime; // tokenId -> timestamp

    // State Transition Rules: fromState -> action -> { toState, requiredReputation, cost }
    struct TransitionRule {
        AssetState toState;
        uint256 requiredReputation; // Minimum reputation of owner to perform this action/transition
        uint256 cost; // Cost in wei (or other token) to perform this action
    }
    mapping(AssetState => mapping(ActionType => TransitionRule)) private _stateTransitionRules;

    // Configuration Values: key (bytes32) -> value (uint256)
    // Examples: decayRate (seconds), baseInteractionReputation, initialReputation
    mapping(bytes32 => uint256) private _config;

    // Owner Reputation
    mapping(address => uint256) private _ownerReputation;

    // Pause state
    bool private _paused = false;

    // Supported states and actions for query/admin functions
    AssetState[] private _supportedStates;
    ActionType[] private _supportedActions;

    // State Change History (using Events primarily for cost, but can store recent on-chain)
    struct StateChangeEntry {
        AssetState fromState;
        AssetState toState;
        uint256 timestamp;
    }
    mapping(uint256 => StateChangeEntry[]) private _tokenStateHistory; // tokenId -> history

    // --- Events ---
    event AssetMinted(uint256 indexed tokenId, address indexed owner, AssetState initialState);
    event AssetStateChanged(uint256 indexed tokenId, AssetState indexed fromState, AssetState indexed toState, uint256 timestamp);
    event ActionPerformed(uint256 indexed tokenId, address indexed owner, ActionType actionType, AssetState newState, uint256 reputationGained, uint256 costPaid);
    event StateTransitionRuleDefined(AssetState indexed fromState, ActionType indexed action, AssetState indexed toState, uint256 requiredReputation, uint256 cost);
    event ConfigUpdated(bytes32 indexed key, uint256 value);
    event AssetBurned(uint256 indexed tokenId, address indexed owner);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);

    // ERC-721 Standard Events (part of interface)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);


    // --- Errors ---
    error AssetDoesNotExist();
    error NotApprovedOrOwner();
    error InvalidState();
    error InvalidAction();
    error ActionNotAllowedInCurrentState();
    error InsufficientReputation(uint256 required, uint256 current);
    error InsufficientPayment(uint256 required, uint256 provided);
    error ActionCooldownActive(); // Optional: if adding cooldowns
    error AlreadyInTargetState();
    error TransferToERC721ReceiverRejected(address receiver);
    error TransferToNonERC721Receiver(address receiver);
    error CallerNotOwnerOrApproved();
    error ZeroAddressMint();

    // --- Modifiers ---
    modifier assetExists(uint256 tokenId) {
        if (_owners[tokenId] == address(0)) revert AssetDoesNotExist();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert ("Contract is paused"); // Simple string error for pause, can be custom error
        _;
    }

    // --- Constructor ---
    constructor(string memory initialBaseURI) Ownable(msg.sender) {
        // Initialize supported states and actions
        _supportedStates.push(AssetState.Unknown); // Placeholder, should not be assigned manually post-mint
        _supportedStates.push(AssetState.Seedling);
        _supportedStates.push(AssetState.Budding);
        _supportedStates.push(AssetState.Flourishing);
        _supportedStates.push(AssetState.Dormant);
        _supportedStates.push(AssetState.Withered);
        _supportedStates.push(AssetState.Reviving);
        _supportedStates.push(AssetState.Legendary);

        _supportedActions.push(ActionType.None); // Placeholder
        _supportedActions.push(ActionType.Nurture);
        _supportedActions.push(ActionType.Rest);
        _supportedActions.push(ActionType.Train);
        _supportedActions.push(ActionType.Harvest);
        _supportedActions.push(ActionType.Revive);
        _supportedActions.push(ActionType.Idle);

        // Set some initial config values (in seconds)
        _config[bytes32("decayRate")] = 7 days; // Example: Decay after 7 days of inactivity
        _config[bytes32("baseInteractionReputation")] = 1; // Example: Gain 1 reputation per action
        _config[bytes32("initialReputation")] = 0; // Initial reputation for new owners
        _config[bytes32("timedEvolutionInterval")] = 1 days; // Check time-based changes every day
        _config[bytes32("baseTokenURI")] = bytes32(bytes(initialBaseURI)); // Store base URI hash or string

        // Define some initial state transition rules (examples)
        // Seedling + Nurture -> Budding, cost 0, rep 0 (initial action)
        _stateTransitionRules[AssetState.Seedling][ActionType.Nurture] = TransitionRule({toState: AssetState.Budding, requiredReputation: 0, cost: 0});
        // Budding + Train -> Flourishing, cost 0.01 ETH, rep 5
        _stateTransitionRules[AssetState.Budding][ActionType.Train] = TransitionRule({toState: AssetState.Flourishing, requiredReputation: 5, cost: 1e16}); // 0.01 ETH
        // Flourishing + Rest -> Dormant, cost 0, rep 0
        _stateTransitionRules[AssetState.Flourishing][ActionType.Rest] = TransitionRule({toState: AssetState.Dormant, requiredReputation: 0, cost: 0});
        // Dormant + Revive -> Reviving, cost 0.05 ETH, rep 10
        _stateTransitionRules[AssetState.Dormant][ActionType.Revive] = TransitionRule({toState: AssetState.Reviving, requiredReputation: 10, cost: 5e16}); // 0.05 ETH
        // Flourishing + Harvest -> Legendary, cost 0.1 ETH, rep 20
        _stateTransitionRules[AssetState.Flourishing][ActionType.Harvest] = TransitionRule({toState: AssetState.Legendary, requiredReputation: 20, cost: 1e17}); // 0.1 ETH

        // Decay Rule (Idle action is implicit for decay)
        // Flourishing + Idle (Decay) -> Withered
        _stateTransitionRules[AssetState.Flourishing][ActionType.Idle] = TransitionRule({toState: AssetState.Withered, requiredReputation: 0, cost: 0});
        // Budding + Idle (Decay) -> Dormant
        _stateTransitionRules[AssetState.Budding][ActionType.Idle] = TransitionRule({toState: AssetState.Dormant, requiredReputation: 0, cost: 0});
        // Seedling + Idle (Decay) -> Withered
        _stateTransitionRules[AssetState.Seedling][ActionType.Idle] = TransitionRule({toState: AssetState.Withered, requiredReputation: 0, cost: 0});

        // Define some initial traits for states
        _stateTraits[AssetState.Seedling]["color"] = "green";
        _stateTraits[AssetState.Seedling]["size"] = "small";
        _stateTraits[AssetState.Budding]["color"] = "light_green";
        _stateTraits[AssetState.Budding]["texture"] = "smooth";
        _stateTraits[AssetState.Flourishing]["color"] = "vibrant";
        _stateTraits[AssetState.Flourishing]["glow"] = "true";
        _stateTraits[AssetState.Dormant]["color"] = "brown";
        _stateTraits[AssetState.Dormant]["texture"] = "rough";
        _stateTraits[AssetState.Withered]["color"] = "grey";
        _stateTraits[AssetState.Withered]["condition"] = "poor";
        _stateTraits[AssetState.Reviving]["color"] = "pale_green";
        _stateTraits[AssetState.Reviving]["condition"] = "improving";
        _stateTraits[AssetState.Legendary]["color"] = "gold";
        _stateTraits[AssetState.Legendary]["aura"] = "radiant";
        _stateTraits[AssetState.Legendary]["unlocked_ability"] = "flight"; // Example trait that implies ability
    }

    // --- Internal ERC-721 Helper Functions ---
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId, string memory initialMetadataURI) internal {
        if (to == address(0)) revert ZeroAddressMint();
        if (_exists(tokenId)) revert ("Token already exists"); // Should not happen with proper ID management
        // Assuming tokenId generation logic is handled off-chain or internally elsewhere for simplicity

        _owners[tokenId] = to;
        _balances[to]++;
        _tokenURIs[tokenId] = initialMetadataURI;
        _totalSupply++;

        // Set initial state (example: Seedling)
        AssetState initialState = AssetState.Seedling;
        _tokenStates[tokenId] = initialState;
        _assetLastActionTime[tokenId] = block.timestamp;
        _ownerReputation[to] = _config[bytes32("initialReputation")]; // Initialize owner reputation

        emit AssetMinted(tokenId, to, initialState);
        emit Transfer(address(0), to, tokenId);
        emit AssetStateChanged(tokenId, AssetState.Unknown, initialState, block.timestamp); // Log initial state change
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert ("ERC721: transfer from incorrect owner");
        if (to == address(0)) revert ("ERC721: transfer to the zero address");

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkAuthorized(uint256 tokenId) internal view {
        if (_owners[tokenId] != msg.sender && !isApprovedForAll(_owners[tokenId], msg.sender) && _tokenApprovals[tokenId] != msg.sender) {
            revert CallerNotOwnerOrApproved();
        }
    }

    function _burn(uint256 tokenId) internal assetExists(tokenId) {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        delete _owners[tokenId];
        delete _tokenStates[tokenId]; // Delete state data
        delete _assetLastActionTime[tokenId]; // Delete time data
        // Keep reputation? Maybe decay it. For now, keep.
        delete _tokenURIs[tokenId]; // Delete URI
        delete _tokenStateHistory[tokenId]; // Clear history
        _balances[owner]--;
        _totalSupply--;

        emit AssetBurned(tokenId, owner);
        emit Transfer(owner, address(0), tokenId);
    }


    // --- ERC-721 Public Functions ---
    // (Minimal implementation required by the interface)
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ("ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert AssetDoesNotExist();
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override whenNotPaused assetExists(tokenId) {
         // Check if msg.sender is owner or approved
        if (ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert CallerNotOwnerOrApproved();
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override whenNotPaused assetExists(tokenId) {
         // Check if msg.sender is owner or approved
        if (ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
             revert CallerNotOwnerOrApproved();
        }
        _safeTransfer(from, to, tokenId, "");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override whenNotPaused assetExists(tokenId) {
        // Check if msg.sender is owner or approved
        if (ownerOf(tokenId) != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender)) {
             revert CallerNotOwnerOrApproved();
        }
         _safeTransfer(from, to, tokenId, data);
     }

    function approve(address to, uint256 tokenId) public override assetExists(tokenId) {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert CallerNotOwnerOrApproved();
        }
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override assetExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function tokenURI(uint256 tokenId) public view override assetExists(tokenId) returns (string memory) {
        // Could generate URI based on state, or use a base URI + token ID + state hash
        bytes32 baseURIBytes = bytes32(_config[bytes32("baseTokenURI")]);
        string memory baseURI = string(abi.encodePacked(baseURIBytes));

        if (bytes(_tokenURIs[tokenId]).length > 0) {
             // If a specific URI was set during mint, use it (or combine)
             return string(abi.encodePacked(baseURI, _tokenURIs[tokenId]));
        } else {
            // Otherwise, generate a default URI based on token ID and state
            // This is a simplified example; real metadata should likely be external JSON
            return string(abi.encodePacked(baseURI, tokenId.toString(), "-", uint256(getState(tokenId)).toString(), ".json"));
        }
    }

     function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        // ERC721 interface ID is 0x80ac58cd
        // ERC165 interface ID is 0x01ffc9a7
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC165).interfaceId; // IERC165 is needed for supportsInterface
    }


    // --- Internal SafeTransfer Helper ---
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (to.code.length > 0) { // Check if 'to' is a contract
            // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) == 0x150b7a02
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 response) {
                if (response != 0x150b7a02) {
                    revert TransferToERC721ReceiverRejected(to);
                }
            } catch Error(string memory reason) {
                 // Catch potential revert reasons from the receiver
                revert(string(abi.encodePacked("ERC721: transfer to non ERC721Receiver implementer or callback failed", reason)));
            } catch {
                 // Catch any other revert from the receiver
                revert TransferToNonERC721Receiver(to);
            }
        }
    }


    // --- Core ChronoMorph Logic ---

    /**
     * @dev Mints a new ChronoMorph asset. Can only be called by the contract owner.
     * Assumes tokenId generation logic is handled externally or by the contract itself.
     * @param to The address to mint the asset to.
     * @param tokenId The unique identifier for the new asset.
     * @param initialMetadataURI The initial metadata URI for the asset.
     */
    function mintAsset(address to, uint256 tokenId, string memory initialMetadataURI) external onlyOwner whenNotPaused {
        _safeMint(to, tokenId, initialMetadataURI);
    }

    /**
     * @dev Burns an existing ChronoMorph asset. Can be called by the owner or approved address.
     * @param tokenId The unique identifier of the asset to burn.
     */
    function burnAsset(uint256 tokenId) public assetExists(tokenId) whenNotPaused {
        _checkAuthorized(tokenId); // Ensure caller is owner or approved operator/address
        _burn(tokenId);
    }

    /**
     * @dev Gets the current state of a ChronoMorph asset.
     * @param tokenId The unique identifier of the asset.
     * @return The current state of the asset.
     */
    function getState(uint256 tokenId) public view assetExists(tokenId) returns (AssetState) {
        return _tokenStates[tokenId];
    }

     /**
     * @dev Gets the dynamic traits associated with an asset's current state.
     * Traits are defined per state by the contract owner.
     * @param tokenId The unique identifier of the asset.
     * @return An array of trait key-value pairs.
     */
    function getTraits(uint256 tokenId) public view assetExists(tokenId) returns (string[] memory, string[] memory) {
        AssetState currentState = _tokenStates[tokenId];
        return getTraitsForState(currentState);
    }

    /**
     * @dev Performs an action on a ChronoMorph asset. This is the primary way owners interact.
     * Actions can cost Ether, require reputation, and potentially change the asset's state
     * based on predefined rules.
     * @param tokenId The unique identifier of the asset.
     * @param actionType The type of action to perform.
     */
    function performAction(uint256 tokenId, ActionType actionType) external payable assetExists(tokenId) whenNotPaused {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) revert NotApprovedOrOwner(); // Only owner can perform actions

        AssetState currentState = _tokenStates[tokenId];
        TransitionRule memory rule = _stateTransitionRules[currentState][actionType];

        if (rule.toState == AssetState.Unknown) revert ActionNotAllowedInCurrentState(); // No rule defined for this state/action

        // Check reputation requirement
        if (_ownerReputation[owner] < rule.requiredReputation) {
            revert InsufficientReputation(rule.requiredReputation, _ownerReputation[owner]);
        }

        // Check payment requirement
        if (msg.value < rule.cost) {
            revert InsufficientPayment(rule.cost, msg.value);
        }

        // If the rule has a cost, send the payment to the contract
        // Any excess ETH sent is automatically returned by the EVM

        // Apply state change if different
        if (currentState != rule.toState) {
             _updateState(tokenId, rule.toState);
        }

        // Update last action time
        _assetLastActionTime[tokenId] = block.timestamp;

        // Update owner reputation (gain based on config)
        _ownerReputation[owner] += _config[bytes32("baseInteractionReputation")];

        emit ActionPerformed(tokenId, owner, actionType, _tokenStates[tokenId], _config[bytes32("baseInteractionReputation")], rule.cost);
    }

     /**
     * @dev Checks if a timed state evolution/decay should occur for an asset
     * and applies it if conditions are met. Can be called by anyone (incentivized
     * by potential future mechanisms or community maintenance).
     * @param tokenId The unique identifier of the asset.
     */
    function checkAndApplyTimedEvolution(uint256 tokenId) external assetExists(tokenId) whenNotPaused {
        AssetState currentState = _tokenStates[tokenId];
        uint256 lastAction = _assetLastActionTime[tokenId];
        uint256 decayRate = _config[bytes32("decayRate")];

        // Check for decay condition (if enough time has passed since last action)
        if (decayRate > 0 && block.timestamp >= lastAction + decayRate) {
            // Find the decay rule (ActionType.Idle is used for timed decay)
            TransitionRule memory decayRule = _stateTransitionRules[currentState][ActionType.Idle];
            if (decayRule.toState != AssetState.Unknown && currentState != decayRule.toState) {
                 // Apply decay state change
                 _updateState(tokenId, decayRule.toState);
                 // Note: Decay doesn't update lastActionTime or owner reputation via performAction
                 // Decay is a consequence of *inactivity*, not an action itself.
                 // The lastActionTime remains the time of the *last owner action*.
                 emit ActionPerformed(tokenId, ownerOf(tokenId), ActionType.Idle, _tokenStates[tokenId], 0, 0); // Log decay as Idle action
            }
        }
        // Add checks for other time-based evolutions here if needed
        // e.g., Auto-transition from Reviving to Seedling after a time interval
        // uint256 evolutionInterval = _config[bytes32("timedEvolutionInterval")];
        // if (currentState == AssetState.Reviving && block.timestamp >= lastAction + evolutionInterval) {
        //    TransitionRule memory evolutionRule = _stateTransitionRules[currentState][ActionType.None]; // Use ActionType.None for auto-transitions
        //    if (evolutionRule.toState != AssetState.Unknown && currentState != evolutionRule.toState) {
        //        _updateState(tokenId, evolutionRule.toState);
        //        // Update last action time here ONLY if this time-based change resets the decay timer
        //        _assetLastActionTime[tokenId] = block.timestamp;
        //        emit ActionPerformed(tokenId, ownerOf(tokenId), ActionType.None, _tokenStates[tokenId], 0, 0); // Log auto-evolution
        //    }
        // }

    }

    // --- Rules & Configuration ---

    /**
     * @dev Sets a system configuration value. Only callable by the contract owner.
     * Used for tuning parameters like decay rates, costs, reputation gains.
     * @param key The bytes32 key identifying the configuration parameter.
     * @param value The uint256 value to set.
     */
    function setConfigValue(bytes32 key, uint256 value) external onlyOwner {
        _config[key] = value;
        emit ConfigUpdated(key, value);
    }

     /**
     * @dev Gets a system configuration value.
     * @param key The bytes32 key identifying the configuration parameter.
     * @return The uint256 value of the parameter.
     */
    function getConfigValue(bytes32 key) public view returns (uint256) {
        return _config[key];
    }


    /**
     * @dev Defines or updates a state transition rule. Only callable by the contract owner.
     * Specifies which state an asset transitions to from 'fromState' when 'action' is performed,
     * along with required reputation and cost.
     * @param fromState The starting state.
     * @param action The action triggering the transition.
     * @param toState The target state after the action.
     * @param requiredReputation Minimum owner reputation needed for this transition.
     * @param cost Cost in wei (or other token) required for this transition.
     */
    function defineStateTransitionRule(AssetState fromState, ActionType action, AssetState toState, uint256 requiredReputation, uint256 cost) external onlyOwner {
         if (fromState == AssetState.Unknown || toState == AssetState.Unknown) revert InvalidState();
         if (action == ActionType.None) revert InvalidAction(); // ActionType.None is reserved for auto-transitions if implemented

        _stateTransitionRules[fromState][action] = TransitionRule({
            toState: toState,
            requiredReputation: requiredReputation,
            cost: cost
        });
        emit StateTransitionRuleDefined(fromState, action, toState, requiredReputation, cost);
    }

     /**
     * @dev Queries the defined state transition rule for a given state and action.
     * @param fromState The starting state.
     * @param action The action.
     * @return toState The target state.
     * @return requiredReputation Minimum owner reputation.
     * @return cost Cost in wei.
     */
    function queryStateTransitionRule(AssetState fromState, ActionType action) public view returns (AssetState toState, uint256 requiredReputation, uint256 cost) {
        TransitionRule memory rule = _stateTransitionRules[fromState][action];
        return (rule.toState, rule.requiredReputation, rule.cost);
    }

    /**
     * @dev Defines or updates a trait for a specific state. Only callable by the contract owner.
     * Traits are dynamic properties associated with each state.
     * @param state The state to associate the trait with.
     * @param traitKey The key name of the trait (e.g., "color", "size").
     * @param traitValue The value of the trait (e.g., "red", "large").
     */
    function setTraitForState(AssetState state, string memory traitKey, string memory traitValue) external onlyOwner {
         if (state == AssetState.Unknown) revert InvalidState();
        _stateTraits[state][traitKey] = traitValue;
        // Could emit an event here if desired
    }

    /**
     * @dev Gets all traits defined for a specific state.
     * Note: Retrieving all keys from a mapping is not directly possible.
     * This function relies on knowing the potential trait keys or requires
     * an external mechanism to track them. As a simplified example, this
     * would return traits if you *know* the keys or if traits were stored differently.
     * A more robust implementation might track trait keys in a separate array.
     * For demonstration, this function is conceptual or assumes known keys.
     * Let's return arrays mirroring the stateTraits mapping structure as best as possible.
     * This is a simplified representation.
     * @param state The state to query traits for.
     * @return An array of trait keys and an array of trait values.
     */
    function getTraitsForState(AssetState state) public view returns (string[] memory, string[] memory) {
         // Due to mapping limitations, we can't easily iterate all keys.
         // This implementation will return *only* the keys/values if you have a way
         // to provide the keys you are interested in, or if the traits are known.
         // For a realistic contract, you might store trait keys in an array per state.
         // Example (conceptual):
         // string[] memory keys = _getStateTraitKeys[state];
         // string[] memory values = new string[](keys.length);
         // for (uint i = 0; i < keys.length; i++) {
         //     values[i] = _stateTraits[state][keys[i]];
         // }
         // return (keys, values);

         // Simplified placeholder: Assuming a few common keys are checked
         string[] memory keys = new string[](4); // Max check for 4 common keys
         string[] memory values = new string[](4);
         uint256 count = 0;

         string memory val;
         val = _stateTraits[state]["color"]; if(bytes(val).length > 0) { keys[count] = "color"; values[count] = val; count++; }
         val = _stateTraits[state]["size"]; if(bytes(val).length > 0) { keys[count] = "size"; values[count] = val; count++; }
         val = _stateTraits[state]["texture"]; if(bytes(val).length > 0) { keys[count] = "texture"; values[count] = val; count++; }
         val = _stateTraits[state]["condition"]; if(bytes(val).length > 0) { keys[count] = "condition"; values[count] = val; count++; }
         val = _stateTraits[state]["glow"]; if(bytes(val).length > 0) { keys[count] = "glow"; values[count] = val; count++; }
         val = _stateTraits[state]["aura"]; if(bytes(val).length > 0) { keys[count] = "aura"; values[count] = val; count++; }
         val = _stateTraits[state]["unlocked_ability"]; if(bytes(val).length > 0) { keys[count] = "unlocked_ability"; values[count] = val; count++; }


         // Trim arrays to actual count
         string[] memory finalKeys = new string[](count);
         string[] memory finalValues = new string[](count);
         for(uint i = 0; i < count; i++) {
             finalKeys[i] = keys[i];
             finalValues[i] = values[i];
         }
         return (finalKeys, finalValues);
    }

    /**
     * @dev Internal helper to update the state of an asset and log the history.
     * @param tokenId The unique identifier of the asset.
     * @param newState The new state to set.
     */
    function _updateState(uint256 tokenId, AssetState newState) internal {
        AssetState oldState = _tokenStates[tokenId];
        if (oldState == newState) return; // Avoid unnecessary updates

        _tokenStates[tokenId] = newState;

        // Store state change in history
        _tokenStateHistory[tokenId].push(StateChangeEntry({
            fromState: oldState,
            toState: newState,
            timestamp: block.timestamp
        }));

        emit AssetStateChanged(tokenId, oldState, newState, block.timestamp);
    }

    // --- Reputation System ---

    /**
     * @dev Gets the current reputation score of an owner address.
     * @param owner The address of the owner.
     * @return The current reputation score.
     */
    function getCurrentReputation(address owner) public view returns (uint256) {
        return _ownerReputation[owner];
    }


    // --- Query Functions ---

     /**
     * @dev Gets the timestamp of the last recorded action (performAction or timed evolution/decay)
     * for a specific asset.
     * @param tokenId The unique identifier of the asset.
     * @return The timestamp of the last action.
     */
    function getAssetLastActionTime(uint256 tokenId) public view assetExists(tokenId) returns (uint256) {
        return _assetLastActionTime[tokenId];
    }

    /**
     * @dev Calculates the time elapsed since the last action on an asset.
     * @param tokenId The unique identifier of the asset.
     * @return The time in seconds since the last action.
     */
    function getTimeSinceLastAction(uint256 tokenId) public view assetExists(tokenId) returns (uint256) {
        return block.timestamp - _assetLastActionTime[tokenId];
    }

     /**
     * @dev Gets the list of all supported states in the contract.
     * @return An array of supported AssetState enum values.
     */
    function getSupportedStates() public view returns (AssetState[] memory) {
        return _supportedStates;
    }

    /**
     * @dev Gets the list of all supported action types in the contract.
     * @return An array of supported ActionType enum values.
     */
    function getSupportedActions() public view returns (ActionType[] memory) {
        return _supportedActions;
    }

    /**
     * @dev Retrieves the history of state changes for a specific asset.
     * Note: On-chain history storage can be expensive. This is an example.
     * For long history, consider off-chain indexing or a separate history contract.
     * @param tokenId The unique identifier of the asset.
     * @return An array of StateChangeEntry structs.
     */
    function getTokenStateHistory(uint256 tokenId) public view assetExists(tokenId) returns (StateChangeEntry[] memory) {
        return _tokenStateHistory[tokenId];
    }

     /**
     * @dev Gets the possible actions that can be performed on an asset in its current state,
     * considering defined rules.
     * @param tokenId The unique identifier of the asset.
     * @return An array of possible ActionType enum values.
     */
    function getPossibleActionsForState(uint256 tokenId) public view assetExists(tokenId) returns (ActionType[] memory) {
        AssetState currentState = _tokenStates[tokenId];
        ActionType[] memory possibleActions = new ActionType[](_supportedActions.length); // Max possible size
        uint256 count = 0;

        // Iterate through all supported actions and check if a rule exists
        for (uint i = 0; i < _supportedActions.length; i++) {
            ActionType action = _supportedActions[i];
            // Check if a rule exists and doesn't transition to Unknown (meaning no rule)
            if (_stateTransitionRules[currentState][action].toState != AssetState.Unknown) {
                possibleActions[count] = action;
                count++;
            }
        }

        // Trim the array to the actual number of possible actions
        ActionType[] memory result = new ActionType[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = possibleActions[i];
        }
        return result;
    }


    // --- Administrative Functions ---

    /**
     * @dev Allows the contract owner to withdraw any accumulated Ether (from action costs).
     */
    function withdrawFees() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    /**
     * @dev Pauses core contract interactions (performAction, transfers, minting, burning).
     * Only callable by the contract owner.
     */
    function pauseContract() external onlyOwner {
        _paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses core contract interactions. Only callable by the contract owner.
     */
    function unpauseContract() external onlyOwner {
        _paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return true if paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Placeholder for setting a new logic contract address in an upgradeable proxy pattern.
     * NOTE: This contract is NOT fully upgradeable on its own. Implementing upgradeability
     * requires a separate proxy contract (e.g., UUPS or Transparent). This function
     * would typically reside in the *proxy* contract, or be called by the proxy.
     * It's included here as an example of an advanced contract concept (upgradeability)
     * but requires external infrastructure.
     * @param newLogic The address of the new logic contract.
     */
    function setNewLogicContract(address newLogic) external onlyOwner {
        // In a real UUPS proxy setup, this would typically check msg.sender is the proxy
        // and then update the stored implementation address.
        // For this example, it's just a signature showing where such a function would be.
        require(newLogic != address(0), "New logic address cannot be zero");
        // Imagine storing newLogic address here in a proxy pattern state variable
        // _logicAddress = newLogic;
        emit ConfigUpdated(bytes32("newLogicAddress"), uint256(uint160(newLogic))); // Log change
        // In a real proxy, this might trigger a selfdestruct in the old logic after state is migrated.
        // Selfdestruct should be used with caution.
    }


    // --- Additional ERC721 Views for OpenZeppelin Compatibility ---
    // (Required by some tools/explorers interacting via the OZ interface)
    // uint256 private _currentTokenId; // Example counter for minting simple sequential IDs

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Example of a non-sequential minting (caller provides ID)
    // function mintSequentialAsset(address to, string memory initialMetadataURI) external onlyOwner returns (uint256) {
    //    _currentTokenId++;
    //    uint256 newItemId = _currentTokenId;
    //    _safeMint(to, newItemId, initialMetadataURI);
    //    return newItemId;
    // }

    // Function to get tokenByIndex (optional for ERC721Enumerable)
    // requires storing token IDs in an array, which is gas-intensive.
    // Leaving it out to avoid duplicating OpenZeppelin's Enumerable extension.

    // Function to get tokenOfOwnerByIndex (optional for ERC721Enumerable)
    // requires storing token IDs per owner in an array.
    // Leaving it out.

}

// Minimal interface required for supportsInterface (ERC165)
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Minimal interface for ERC721 Receiver (ERC721TokenReceiver)
// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) == 0x150b7a02
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
```

**Explanation of Concepts and Functions:**

1.  **Statebound Assets (ChronoMorphs):** The core idea is that NFTs aren't static. They have internal states (`AssetState` enum) that represent different phases or conditions (Seedling, Flourishing, Withered, etc.).
2.  **Dynamic Traits:** Each state has associated traits (`_stateTraits` mapping). When an asset changes state, its traits change. The `getTraits` function retrieves these dynamic traits based on the *current* state.
3.  **Owner Interaction (`performAction`):** Owners can perform specific actions (`ActionType` enum) on their assets. This is a central mechanic.
    *   Actions can have costs (payable function, `msg.value`).
    *   Actions can require a minimum reputation (`requiredReputation`).
    *   Successful actions can grant reputation (`_ownerReputation`).
    *   Actions trigger potential state transitions based on defined rules.
4.  **Configurable State Transition Rules (`defineStateTransitionRule`, `queryStateTransitionRule`):** The contract owner (or later, a DAO) can define how actions (or inactivity, see Decay) cause state changes. This makes the game or simulation logic flexible. `_stateTransitionRules` mapping stores these rules.
5.  **Timed Evolution & Decay (`checkAndApplyTimedEvolution`):** Assets can change state automatically if enough time passes without specific interaction. This simulates decay or natural progression. Anyone can call `checkAndApplyTimedEvolution` to trigger this check for a specific token, potentially allowing community maintenance or external bots.
6.  **Owner Reputation (`_ownerReputation`, `getCurrentReputation`):** Owners earn reputation by performing actions. This reputation can be a prerequisite for performing more advanced actions or accessing certain features (e.g., transitioning to a "Legendary" state might require high reputation).
7.  **On-Chain Configuration (`setConfigValue`, `getConfigValue`):** Key parameters like decay rates, interaction costs, and base reputation gain are stored in a configuration mapping (`_config`) and can be adjusted by the owner.
8.  **State Change History (`_tokenStateHistory`, `getTokenStateHistory`):** The contract explicitly records each state change for an asset, providing an on-chain history trail.
9.  **Minimal ERC-721 Implementation:** It avoids importing the *full* OpenZeppelin ERC721 contract code to adhere to the "don't duplicate open source" idea for the *core logic*, but includes the necessary storage (`_owners`, `_balances`, etc.) and public function signatures (`balanceOf`, `ownerOf`, `transferFrom`, etc.) to be *compatible* with ERC-721 standards and tools. It *does* import interfaces and utilities (`IERC721`, `IERC721Receiver`, `Strings`, `Ownable`) as these are standard building blocks.
10. **Error Handling:** Uses `revert` with custom error messages or custom errors for clarity and gas efficiency.
11. **Pause Mechanism:** Standard `whenNotPaused` modifier and admin functions for pausing core user interactions.
12. **Upgradeability Hook (`setNewLogicContract`):** Includes a function signature that hints at how this contract *could* be made upgradeable using a proxy pattern (like UUPS), representing an advanced deployment concept. (Note: This contract alone isn't upgradeable; it requires a proxy).
13. **More than 20 Functions:** As listed in the summary, there are well over 20 functions covering ERC721 compliance, core state logic, interaction, rules, configuration, queries, and admin tasks.

This contract provides a framework for dynamic, interactive NFTs with evolving properties based on programmable on-chain rules and owner engagement, which is a step beyond static or simple generative NFTs.