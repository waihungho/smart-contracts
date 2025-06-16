Okay, here is a Solidity smart contract implementing an "Entangled Quantum Asset" (EQA) ERC721 token. It features dynamic properties, a novel entanglement mechanism between tokens, a state observation process, utility delegation, and other concepts beyond standard ERC721.

**Concept:**

Quantum Entanglement ERC721 (EQA) tokens are non-fungible assets with dynamic, evolving properties (like level and experience). Two EQA tokens can become "entangled," creating a unique link where certain actions performed on one can affect its entangled partner. Tokens also exist in a "potential" state initially; their properties become "observed" and potentially locked or enhanced after a specific action. Utility delegation allows owners to grant limited control of their tokens to others.

**Outline:**

1.  **License and Pragma**
2.  **Imports (OpenZeppelin)**
3.  **Error Definitions**
4.  **Events**
5.  **Contract Definition (Inherits ERC721, Ownable)**
6.  **State Variables**
    *   Token Properties (Level, Experience, State, Entanglement)
    *   Entanglement Proposals
    *   Utility Delegation
    *   Configuration (Costs, Requirements, Paused State)
    *   Metadata
    *   Token Counter
7.  **Constructor**
8.  **Modifiers**
9.  **Internal/Helper Functions**
    *   `_gainExperience`
    *   `_checkLevelUp`
    *   `_clearEntanglementProposal`
    *   `_setEntanglement`
    *   `_clearEntanglement`
    *   `_checkEntanglementConditions`
    *   `_onlyTokenOwnerOrDelegate`
10. **Core ERC721 Overrides**
    *   `tokenURI`
11. **EQA Lifecycle & Properties Functions**
    *   `createQuantumAsset`
    *   `burnQuantumAsset`
    *   `getTokenLevel`
    *   `getTokenExperience`
    *   `isStateObserved`
    *   `levelUp`
    *   `observeQuantumState`
    *   `getRevealedProperties`
12. **Entanglement Functions**
    *   `proposeEntanglement`
    *   `acceptEntanglement`
    *   `rejectEntanglement`
    *   `breakEntanglement`
    *   `getEntangledToken`
    *   `isEntangled`
    *   `getEntanglementProposal`
    *   `performEntangledAction` (Example: Transfer Experience)
13. **Utility Delegation Functions**
    *   `delegateUtility`
    *   `revokeUtilityDelegation`
    *   `getUtilityDelegate`
    *   `isUtilityDelegate`
14. **Interactions & Dynamics Functions**
    *   `transferExperience` (Conditionally restricted)
    *   `mergeProperties` (Placeholder for a more complex interaction)
15. **Configuration & Admin Functions (Owner Only)**
    *   `setExpRequiredForLevel`
    *   `setEntanglementCost`
    *   `updateBaseURI`
    *   `pauseEntanglementCreation`
    *   `unpauseEntanglementCreation`

**Function Summary:**

1.  `constructor(string memory name, string memory symbol)`: Initializes the contract, ERC721, and Ownable.
2.  `tokenURI(uint256 tokenId) public view override returns (string memory)`: Returns the metadata URI for a token, incorporating its dynamic state.
3.  `createQuantumAsset(address owner) public onlyOwner returns (uint256)`: Mints a new EQA token for the specified owner, initializing its state.
4.  `burnQuantumAsset(uint256 tokenId) public`: Burns an EQA token. Can be called by owner/approved/delegate.
5.  `getTokenLevel(uint256 tokenId) public view returns (uint256)`: Gets the current level of a token.
6.  `getTokenExperience(uint256 tokenId) public view returns (uint256)`: Gets the current experience points of a token.
7.  `isStateObserved(uint256 tokenId) public view returns (bool)`: Checks if a token's quantum state has been observed.
8.  `levelUp(uint256 tokenId) public`: Attempts to level up a token if it meets the experience requirement. Can be called by owner/approved/delegate.
9.  `observeQuantumState(uint256 tokenId) public`: Observes and potentially crystallizes the properties of a token. Can be called by owner/approved/delegate.
10. `getRevealedProperties(uint256 tokenId) public view returns (uint256 level, uint256 experience, bool observed)`: Returns the properties of a token, primarily intended for use after observation.
11. `proposeEntanglement(uint256 tokenId1, uint256 tokenId2) public payable`: Proposes an entanglement link between two tokens. Requires caller owns/delegates `tokenId1` and pays a cost.
12. `acceptEntanglement(uint256 tokenId1, uint256 tokenId2) public`: Accepts an entanglement proposal from `tokenId1` to `tokenId2`. Requires caller owns/delegates `tokenId2`.
13. `rejectEntanglement(uint256 tokenId1, uint256 tokenId2) public`: Rejects an entanglement proposal. Requires caller owns/delegates `tokenId2`.
14. `breakEntanglement(uint256 tokenId) public`: Breaks the entanglement link for a token and its partner. Can be called by owner/approved/delegate of either token.
15. `getEntangledToken(uint256 tokenId) public view returns (uint256)`: Gets the ID of the token entangled with the given token (0 if none).
16. `isEntangled(uint256 tokenId) public view returns (bool)`: Checks if a token is currently entangled.
17. `getEntanglementProposal(uint256 tokenId) public view returns (uint256 proposedTokenId, uint256 expiresAt)`: Gets details of an active entanglement proposal originating from this token.
18. `performEntangledAction(uint256 tokenId, uint256 experienceAmount) public`: Performs a specific action (transferring experience) that leverages the entanglement link. Can be called by owner/approved/delegate of `tokenId`.
19. `delegateUtility(uint256 tokenId, address delegatee) public`: Delegates certain token utility functions to another address. Requires caller owns the token.
20. `revokeUtilityDelegation(uint256 tokenId) public`: Revokes utility delegation for a token. Requires caller owns the token.
21. `getUtilityDelegate(uint256 tokenId) public view returns (address)`: Gets the current utility delegate for a token.
22. `isUtilityDelegate(uint256 tokenId, address delegatee) public view returns (bool)`: Checks if an address is the utility delegate for a token.
23. `transferExperience(uint256 fromTokenId, uint256 toTokenId, uint256 amount) public`: Transfers experience between tokens. Only allowed if caller owns/delegates both, or if they are entangled.
24. `mergeProperties(uint256 tokenId1, uint256 tokenId2) public`: A placeholder for a more complex function, potentially combining properties if tokens meet certain criteria (e.g., entangled, same level, observed state). *Implementation is a simple placeholder.*
25. `setExpRequiredForLevel(uint256 level, uint256 requiredExp) public onlyOwner`: Sets the experience points required to reach a specific level.
26. `setEntanglementCost(uint256 cost) public onlyOwner`: Sets the native token cost to propose entanglement.
27. `updateBaseURI(string memory newURI) public onlyOwner`: Updates the base URI for token metadata.
28. `pauseEntanglementCreation() public onlyOwner`: Pauses new entanglement proposals.
29. `unpauseEntanglementCreation() public onlyOwner`: Unpauses new entanglement proposals.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. License and Pragma
// 2. Imports (OpenZeppelin)
// 3. Error Definitions
// 4. Events
// 5. Contract Definition (Inherits ERC721, Ownable)
// 6. State Variables (Token Properties, Entanglement, Delegation, Config, Metadata)
// 7. Constructor
// 8. Modifiers
// 9. Internal/Helper Functions
// 10. Core ERC721 Overrides (tokenURI)
// 11. EQA Lifecycle & Properties Functions (Create, Burn, Getters, LevelUp, Observe)
// 12. Entanglement Functions (Propose, Accept, Reject, Break, Getters, EntangledAction)
// 13. Utility Delegation Functions (Delegate, Revoke, Getters)
// 14. Interactions & Dynamics Functions (TransferExp, Merge)
// 15. Configuration & Admin Functions (Owner Only)

// Function Summary:
// 1. constructor(string memory name, string memory symbol): Initializes contract.
// 2. tokenURI(uint256 tokenId): Returns metadata URI including dynamic state.
// 3. createQuantumAsset(address owner): Mints a new EQA token.
// 4. burnQuantumAsset(uint256 tokenId): Burns an EQA token.
// 5. getTokenLevel(uint256 tokenId): Gets token level.
// 6. getTokenExperience(uint256 tokenId): Gets token experience.
// 7. isStateObserved(uint256 tokenId): Checks if state is observed.
// 8. levelUp(uint256 tokenId): Attempts to level up a token.
// 9. observeQuantumState(uint256 tokenId): Observes token state.
// 10. getRevealedProperties(uint256 tokenId): Gets properties after observation.
// 11. proposeEntanglement(uint256 tokenId1, uint256 tokenId2): Proposes entanglement.
// 12. acceptEntanglement(uint256 tokenId1, uint256 tokenId2): Accepts entanglement proposal.
// 13. rejectEntanglement(uint256 tokenId1, uint256 tokenId2): Rejects entanglement proposal.
// 14. breakEntanglement(uint256 tokenId): Breaks entanglement.
// 15. getEntangledToken(uint256 tokenId): Gets entangled partner.
// 16. isEntangled(uint256 tokenId): Checks if entangled.
// 17. getEntanglementProposal(uint256 tokenId): Gets proposal details.
// 18. performEntangledAction(uint256 tokenId, uint256 experienceAmount): Executes action using entanglement.
// 19. delegateUtility(uint256 tokenId, address delegatee): Delegates utility.
// 20. revokeUtilityDelegation(uint256 tokenId): Revokes utility delegation.
// 21. getUtilityDelegate(uint256 tokenId): Gets delegate address.
// 22. isUtilityDelegate(uint256 tokenId, address delegatee): Checks if address is delegate.
// 23. transferExperience(uint256 fromTokenId, uint256 toTokenId, uint256 amount): Transfers experience.
// 24. mergeProperties(uint256 tokenId1, uint256 tokenId2): Placeholder for merge logic.
// 25. setExpRequiredForLevel(uint256 level, uint256 requiredExp): Sets level requirements.
// 26. setEntanglementCost(uint256 cost): Sets entanglement proposal cost.
// 27. updateBaseURI(string memory newURI): Updates metadata URI.
// 28. pauseEntanglementCreation(): Pauses proposals.
// 29. unpauseEntanglementCreation(): Unpauses proposals.


contract QuantumEntanglementERC721 is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Error Definitions ---
    error EQA__TokenDoesNotExist(uint256 tokenId);
    error EQA__UnauthorizedCaller();
    error EQA__NotTokenOwnerOrApprovedOrDelegate(address caller, uint256 tokenId);
    error EQA__CannotLevelUp(uint256 tokenId, uint256 currentExp, uint256 requiredExp);
    error EQA__StateAlreadyObserved(uint256 tokenId);
    error EQA__StateNotObserved(uint256 tokenId);
    error EQA__CannotProposeSelfEntanglement();
    error EQA__TokensAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error EQA__EntanglementProposalExists(uint256 tokenId);
    error EQA__NoEntanglementProposalFound(uint256 tokenId1, uint256 tokenId2);
    error EQA__EntanglementProposalExpired(uint256 tokenId1, uint256 tokenId2);
    error EQA__NotEntangled(uint256 tokenId);
    error EQA__CannotDelegateSelf(address delegatee);
    error EQA__CannotTransferExperienceToSelf(uint256 tokenId);
    error EQA__TransferExperienceRequiresEntanglementOrOwnership(uint256 fromTokenId, uint256 toTokenId);
    error EQA__EntanglementCreationPaused();
    error EQA__InvalidMergeConditions(uint256 tokenId1, uint256 tokenId2); // For placeholder

    // --- Events ---
    event QuantumAssetCreated(uint256 indexed tokenId, address indexed owner);
    event QuantumAssetBurned(uint256 indexed tokenId);
    event LevelUp(uint256 indexed tokenId, uint256 newLevel);
    event StateObserved(uint256 indexed tokenId);
    event EntanglementProposed(uint256 indexed proposerTokenId, uint256 indexed proposedTokenId, uint256 expiresAt);
    event EntanglementAccepted(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementRejected(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event UtilityDelegated(uint256 indexed tokenId, address indexed delegatee);
    event UtilityRevoked(uint256 indexed tokenId, address indexed oldDelegatee);
    event ExperienceGained(uint256 indexed tokenId, uint256 amount, uint256 newTotalExperience);
    event ExperienceTransferred(uint256 indexed fromTokenId, uint256 indexed toTokenId, uint256 amount);
    event EntanglementCreationPausedEvent();
    event EntanglementCreationUnpausedEvent();

    // --- State Variables ---
    Counters.Counter private _nextTokenId;

    // Token Properties
    mapping(uint256 => uint256) private _tokenLevels;
    mapping(uint256 => uint256) private _tokenExperience;
    mapping(uint256 => bool) private _isStateObserved;

    // Entanglement
    mapping(uint256 => uint256) private _entangledTokens; // tokenId -> entangledTokenId (0 if none)
    mapping(uint256 => EntanglementProposal) private _entanglementProposals; // proposerTokenId -> proposal details

    struct EntanglementProposal {
        uint256 proposedTokenId;
        uint256 expiresAt;
    }

    // Utility Delegation
    mapping(uint256 => address) private _utilityDelegates; // tokenId -> delegatee address (address(0) if none)

    // Configuration
    mapping(uint256 => uint256) public expRequiredForLevel;
    uint256 public entanglementCost = 0; // Cost in native token (wei) to propose entanglement
    uint256 public proposalValidityPeriod = 24 * 60 * 60; // 24 hours in seconds

    bool public entanglementCreationPaused = false;

    // Metadata
    string private _baseTokenURI;

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Modifiers ---

    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert EQA__TokenDoesNotExist(tokenId);
        }
        _;
    }

    modifier onlyTokenOwnerOrApprovedOrDelegate(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        address approved = getApproved(tokenId);
        address delegatee = _utilityDelegates[tokenId];
        if (msg.sender != owner && msg.sender != approved && !isApprovedForAll(owner, msg.sender) && msg.sender != delegatee) {
            revert EQA__NotTokenOwnerOrApprovedOrDelegate(msg.sender, tokenId);
        }
        _;
    }

    modifier onlyTokenOwnerOrDelegate(uint256 tokenId) {
         address owner = ownerOf(tokenId);
         address delegatee = _utilityDelegates[tokenId];
         if (msg.sender != owner && msg.sender != delegatee) {
             revert EQA__NotTokenOwnerOrApprovedOrDelegate(msg.sender, tokenId);
         }
         _;
    }


    modifier whenEntanglementCreationIsNotPaused() {
        if (entanglementCreationPaused) {
            revert EQA__EntanglementCreationPaused();
        }
        _;
    }

    // --- Internal/Helper Functions ---

    function _gainExperience(uint256 tokenId, uint256 amount) internal {
        _tokenExperience[tokenId] += amount;
        emit ExperienceGained(tokenId, amount, _tokenExperience[tokenId]);
    }

    function _checkLevelUp(uint256 tokenId) internal {
        uint256 currentLevel = _tokenLevels[tokenId];
        uint256 requiredExp = expRequiredForLevel[currentLevel + 1];

        if (_tokenExperience[tokenId] >= requiredExp && requiredExp > 0) {
            _tokenLevels[tokenId]++;
            // Option: Reset experience after level up, or make it cumulative
            // _tokenExperience[tokenId] -= requiredExp; // Example: reset experience
            emit LevelUp(tokenId, _tokenLevels[tokenId]);
            // Recursively check if another level up is possible immediately
            _checkLevelUp(tokenId);
        }
    }

    function _clearEntanglementProposal(uint256 proposerTokenId) internal {
        delete _entanglementProposals[proposerTokenId];
    }

    function _setEntanglement(uint256 tokenId1, uint256 tokenId2) internal {
        _entangledTokens[tokenId1] = tokenId2;
        _entangledTokens[tokenId2] = tokenId1;
    }

    function _clearEntanglement(uint256 tokenId) internal {
        uint256 entangledTokenId = _entangledTokens[tokenId];
        delete _entangledTokens[tokenId];
        if (entangledTokenId != 0) {
             delete _entangledTokens[entangledTokenId];
             emit EntanglementBroken(tokenId, entangledTokenId);
        }
    }

    function _checkEntanglementConditions(uint256 tokenId1, uint256 tokenId2) internal view tokenExists(tokenId1) tokenExists(tokenId2) {
        if (tokenId1 == tokenId2) {
            revert EQA__CannotProposeSelfEntanglement();
        }
        if (isEntangled(tokenId1) || isEntangled(tokenId2)) {
             revert EQA__TokensAlreadyEntangled(tokenId1, tokenId2);
        }
    }

    // --- Core ERC721 Overrides ---

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        _requireOwned(ERC721.ownerOf(tokenId), tokenId); // Ensure token exists and owner can query URI

        // Append token ID and query parameters reflecting state if desired
        // Example: ipfs://<base_uri>/<tokenId>?level=<level>&exp=<exp>&observed=<bool>&entangled=<bool>
        // Note: Real world requires robust URI generation, potentially off-chain service
        // For simplicity here, just return base + token ID
        if (bytes(_baseTokenURI).length == 0) {
             return ""; // Or some default error URI
        }

        // A more complex example could include parameters:
        // string memory stateParams = string(abi.encodePacked(
        //     "?level=", _tokenLevels[tokenId].toString(),
        //     "&exp=", _tokenExperience[tokenId].toString(),
        //     "&observed=", _isStateObserved[tokenId] ? "true" : "false",
        //     "&entangled=", _entangledTokens[tokenId] != 0 ? "true" : "false"
        // ));
        // return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), stateParams));

        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    // --- EQA Lifecycle & Properties Functions ---

    /// @notice Mints a new Quantum Entanglement Asset token.
    /// Only callable by the contract owner.
    /// @param owner The address to mint the token for.
    /// @return The ID of the newly minted token.
    function createQuantumAsset(address owner) public onlyOwner returns (uint256) {
        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _mint(owner, newTokenId);

        // Initialize state
        _tokenLevels[newTokenId] = 0;
        _tokenExperience[newTokenId] = 0;
        _isStateObserved[newTokenId] = false;
        _entangledTokens[newTokenId] = 0; // 0 indicates not entangled

        emit QuantumAssetCreated(newTokenId, owner);
        return newTokenId;
    }

    /// @notice Burns a Quantum Entanglement Asset token.
    /// Can be called by the owner, an approved address, or the utility delegate.
    /// Breaks entanglement if the token is entangled.
    /// @param tokenId The ID of the token to burn.
    function burnQuantumAsset(uint256 tokenId) public tokenExists(tokenId) onlyTokenOwnerOrApprovedOrDelegate(tokenId) {
         // Break entanglement first if necessary
         if (_entangledTokens[tokenId] != 0) {
             _clearEntanglement(tokenId);
         }
         // Remove any delegation
         if (_utilityDelegates[tokenId] != address(0)) {
             delete _utilityDelegates[tokenId];
         }
        _burn(tokenId);
        emit QuantumAssetBurned(tokenId);
    }


    /// @notice Gets the current level of a Quantum Entanglement Asset.
    /// @param tokenId The ID of the token.
    /// @return The token's current level.
    function getTokenLevel(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _tokenLevels[tokenId];
    }

    /// @notice Gets the current experience points of a Quantum Entanglement Asset.
    /// @param tokenId The ID of the token.
    /// @return The token's current experience points.
    function getTokenExperience(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _tokenExperience[tokenId];
    }

    /// @notice Checks if a token's quantum state has been observed.
    /// @param tokenId The ID of the token.
    /// @return True if the state is observed, false otherwise.
    function isStateObserved(uint256 tokenId) public view tokenExists(tokenId) returns (bool) {
        return _isStateObserved[tokenId];
    }

    /// @notice Attempts to level up a Quantum Entanglement Asset.
    /// Requires the token to have enough experience for the next level.
    /// Can be called by the owner, an approved address, or the utility delegate.
    /// @param tokenId The ID of the token to level up.
    function levelUp(uint256 tokenId) public tokenExists(tokenId) onlyTokenOwnerOrApprovedOrDelegate(tokenId) {
        uint256 currentLevel = _tokenLevels[tokenId];
        uint256 requiredExp = expRequiredForLevel[currentLevel + 1];

        if (requiredExp == 0) {
             // No requirement set for the next level, or max level reached
             revert EQA__CannotLevelUp(tokenId, _tokenExperience[tokenId], requiredExp);
        }
        if (_tokenExperience[tokenId] < requiredExp) {
            revert EQA__CannotLevelUp(tokenId, _tokenExperience[tokenId], requiredExp);
        }

        _tokenLevels[tokenId]++;
        // Decide if experience is reset or cumulative upon level up
        // For this example, let's keep it cumulative
        // _tokenExperience[tokenId] -= requiredExp;

        emit LevelUp(tokenId, _tokenLevels[tokenId]);
        // Optional: Check for immediate subsequent level ups if exp is significantly higher
        _checkLevelUp(tokenId);
    }

    /// @notice Observes the quantum state of a token.
    /// This action is typically irreversible and might "crystallize" certain properties.
    /// Can be called by the owner, an approved address, or the utility delegate.
    /// @param tokenId The ID of the token to observe.
    function observeQuantumState(uint256 tokenId) public tokenExists(tokenId) onlyTokenOwnerOrApprovedOrDelegate(tokenId) {
        if (_isStateObserved[tokenId]) {
            revert EQA__StateAlreadyObserved(tokenId);
        }
        _isStateObserved[tokenId] = true;

        // Future logic could trigger based on state at observation:
        // e.g., if level > 5 when observed, gain a hidden trait.
        // This would require more complex state variables and potentially VRF for randomness.

        emit StateObserved(tokenId);
    }

    /// @notice Gets the properties of a token, primarily for use after observation.
    /// This function exists to potentially return *revealed* or fixed properties
    /// that become accessible or immutable after observation.
    /// @param tokenId The ID of the token.
    /// @return level The token's level.
    /// @return experience The token's experience.
    /// @return observed Whether the state is observed.
    function getRevealedProperties(uint256 tokenId) public view tokenExists(tokenId) returns (uint256 level, uint256 experience, bool observed) {
        // In a real system, this might return properties only accessible *after* observation.
        // For this example, it just returns the current state, emphasizing observation
        // as a prerequisite for querying these "revealed" values via this specific function.
        if (!_isStateObserved[tokenId]) {
            revert EQA__StateNotObserved(tokenId);
        }
        return (_tokenLevels[tokenId], _tokenExperience[tokenId], _isStateObserved[tokenId]);
    }

    // --- Entanglement Functions ---

    /// @notice Proposes an entanglement link between two tokens.
    /// Requires the caller to own or be the delegate of the proposing token (tokenId1).
    /// The proposed token's (tokenId2) owner/delegate must accept.
    /// Costs native token (entanglementCost).
    /// @param tokenId1 The ID of the token initiating the proposal.
    /// @param tokenId2 The ID of the token being proposed for entanglement.
    function proposeEntanglement(uint256 tokenId1, uint256 tokenId2) public payable tokenExists(tokenId1) tokenExists(tokenId2) onlyTokenOwnerOrDelegate(tokenId1) whenEntanglementCreationIsNotPaused {
        _checkEntanglementConditions(tokenId1, tokenId2);

        if (_entanglementProposals[tokenId1].proposedTokenId != 0) {
            revert EQA__EntanglementProposalExists(tokenId1);
        }

        if (msg.value < entanglementCost) {
            revert EQA__UnauthorizedCaller(); // Using this error as a shortcut for insufficient funds
        }

        _entanglementProposals[tokenId1] = EntanglementProposal({
            proposedTokenId: tokenId2,
            expiresAt: block.timestamp + proposalValidityPeriod
        });

        // Refund any excess ether
        if (msg.value > entanglementCost) {
             payable(msg.sender).transfer(msg.value - entanglementCost);
        }

        emit EntanglementProposed(tokenId1, tokenId2, block.timestamp + proposalValidityPeriod);
    }

    /// @notice Accepts an entanglement proposal.
    /// Requires the caller to own or be the delegate of the proposed token (tokenId2).
    /// @param tokenId1 The ID of the token that initiated the proposal.
    /// @param tokenId2 The ID of the token being accepted for entanglement.
    function acceptEntanglement(uint256 tokenId1, uint256 tokenId2) public tokenExists(tokenId1) tokenExists(tokenId2) onlyTokenOwnerOrDelegate(tokenId2) {
        EntanglementProposal storage proposal = _entanglementProposals[tokenId1];

        if (proposal.proposedTokenId != tokenId2) {
            revert EQA__NoEntanglementProposalFound(tokenId1, tokenId2);
        }
        if (block.timestamp > proposal.expiresAt) {
            _clearEntanglementProposal(tokenId1); // Clean up expired proposal
            revert EQA__EntanglementProposalExpired(tokenId1, tokenId2);
        }
        // Ensure the proposed token hasn't become entangled since the proposal was made
         if (isEntangled(tokenId1) || isEntangled(tokenId2)) {
             _clearEntanglementProposal(tokenId1); // Clean up invalid proposal
             revert EQA__TokensAlreadyEntangled(tokenId1, tokenId2);
        }

        _setEntanglement(tokenId1, tokenId2);
        _clearEntanglementProposal(tokenId1); // Clear the accepted proposal

        emit EntanglementAccepted(tokenId1, tokenId2);
    }

    /// @notice Rejects an entanglement proposal.
    /// Requires the caller to own or be the delegate of the proposed token (tokenId2).
    /// @param tokenId1 The ID of the token that initiated the proposal.
    /// @param tokenId2 The ID of the token being rejected for entanglement.
    function rejectEntanglement(uint256 tokenId1, uint256 tokenId2) public tokenExists(tokenId1) tokenExists(tokenId2) onlyTokenOwnerOrDelegate(tokenId2) {
         EntanglementProposal storage proposal = _entanglementProposals[tokenId1];

        if (proposal.proposedTokenId != tokenId2) {
            revert EQA__NoEntanglementProposalFound(tokenId1, tokenId2);
        }

        // Refund the entanglement cost to the original proposer
        // Note: A more complex system might handle refunds differently or require a claim function
        address proposerOwner = ownerOf(tokenId1); // Assumes owner at time of proposal is still owner
        if (entanglementCost > 0) {
            payable(proposerOwner).transfer(entanglementCost);
        }


        _clearEntanglementProposal(tokenId1);

        emit EntanglementRejected(tokenId1, tokenId2);
    }

    /// @notice Breaks the entanglement link between two tokens.
    /// Can be called by the owner, approved address, or delegate of *either* entangled token.
    /// @param tokenId The ID of one of the entangled tokens.
    function breakEntanglement(uint256 tokenId) public tokenExists(tokenId) onlyTokenOwnerOrApprovedOrDelegate(tokenId) {
        if (!isEntangled(tokenId)) {
            revert EQA__NotEntangled(tokenId);
        }
        _clearEntanglement(tokenId);
        // Note: No cost/refund for breaking entanglement in this example
    }

    /// @notice Gets the ID of the token entangled with the given token.
    /// @param tokenId The ID of the token.
    /// @return The ID of the entangled token, or 0 if not entangled.
    function getEntangledToken(uint256 tokenId) public view tokenExists(tokenId) returns (uint256) {
        return _entangledTokens[tokenId];
    }

    /// @notice Checks if a token is currently entangled.
    /// @param tokenId The ID of the token.
    /// @return True if entangled, false otherwise.
    function isEntangled(uint256 tokenId) public view tokenExists(tokenId) returns (bool) {
        return _entangledTokens[tokenId] != 0;
    }

    /// @notice Gets details of an active entanglement proposal originating from this token.
    /// @param tokenId The ID of the token that proposed entanglement.
    /// @return proposedTokenId The ID of the token proposed for entanglement (0 if no active proposal).
    /// @return expiresAt The timestamp when the proposal expires (0 if no active proposal).
    function getEntanglementProposal(uint256 tokenId) public view tokenExists(tokenId) returns (uint256 proposedTokenId, uint256 expiresAt) {
        EntanglementProposal storage proposal = _entanglementProposals[tokenId];
        return (proposal.proposedTokenId, proposal.expiresAt);
    }


    /// @notice Performs an action that leverages the entanglement link.
    /// Example: Transfers a specified amount of experience from the caller's token
    /// to its entangled partner.
    /// Can be called by the owner, approved address, or delegate of the token initiating the action.
    /// @param tokenId The ID of the token initiating the entangled action.
    /// @param experienceAmount The amount of experience to transfer to the entangled partner.
    function performEntangledAction(uint256 tokenId, uint256 experienceAmount) public tokenExists(tokenId) onlyTokenOwnerOrApprovedOrDelegate(tokenId) {
        uint256 entangledTokenId = _entangledTokens[tokenId];
        if (entangledTokenId == 0) {
            revert EQA__NotEntangled(tokenId);
        }
        if (experienceAmount == 0) return; // No action needed

        // Example Entangled Action: Transfer experience from caller's token to entangled partner
        if (_tokenExperience[tokenId] < experienceAmount) {
             experienceAmount = _tokenExperience[tokenId]; // Transfer max available
        }

        _tokenExperience[tokenId] -= experienceAmount;
        _gainExperience(entangledTokenId, experienceAmount); // Use internal helper to add exp and emit event

        // Check both tokens for level ups after the transfer
        _checkLevelUp(tokenId);
        _checkLevelUp(entangledTokenId);

        // Emit a specific event for this entangled action if distinct from transferExperience
        // emit EntangledExperienceTransfer(tokenId, entangledTokenId, experienceAmount);
    }


    // --- Utility Delegation Functions ---

    /// @notice Delegates certain utility functions for a token to another address.
    /// The delegatee can call functions marked with `onlyTokenOwnerOrDelegate` or `onlyTokenOwnerOrApprovedOrDelegate`.
    /// Requires the caller to be the owner of the token.
    /// Setting delegatee to address(0) revokes delegation.
    /// @param tokenId The ID of the token.
    /// @param delegatee The address to delegate utility to (address(0) to revoke).
    function delegateUtility(uint256 tokenId, address delegatee) public tokenExists(tokenId) {
        // Only the owner can delegate utility
        _requireOwned(msg.sender, tokenId);

        if (delegatee != address(0) && delegatee == msg.sender) {
             revert EQA__CannotDelegateSelf(delegatee);
        }

        address oldDelegatee = _utilityDelegates[tokenId];
        _utilityDelegates[tokenId] = delegatee;

        if (delegatee != address(0)) {
            emit UtilityDelegated(tokenId, delegatee);
        } else {
            emit UtilityRevoked(tokenId, oldDelegatee);
        }
    }

     /// @notice Revokes utility delegation for a token.
     /// Requires the caller to be the owner of the token.
     /// @param tokenId The ID of the token.
    function revokeUtilityDelegation(uint256 tokenId) public tokenExists(tokenId) {
        delegateUtility(tokenId, address(0));
    }

    /// @notice Gets the current utility delegate for a token.
    /// @param tokenId The ID of the token.
    /// @return The address of the utility delegate, or address(0) if none.
    function getUtilityDelegate(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return _utilityDelegates[tokenId];
    }

    /// @notice Checks if an address is the utility delegate for a token.
    /// @param tokenId The ID of the token.
    /// @param delegatee The address to check.
    /// @return True if the address is the delegate, false otherwise.
    function isUtilityDelegate(uint256 tokenId, address delegatee) public view tokenExists(tokenId) returns (bool) {
        return _utilityDelegates[tokenId] == delegatee && delegatee != address(0);
    }


    // --- Interactions & Dynamics Functions ---

    /// @notice Transfers experience points between two tokens.
    /// Requires the caller to own/delegate *both* tokens, OR for the two tokens to be entangled.
    /// @param fromTokenId The ID of the token to transfer experience from.
    /// @param toTokenId The ID of the token to transfer experience to.
    /// @param amount The amount of experience to transfer.
    function transferExperience(uint256 fromTokenId, uint256 toTokenId, uint256 amount) public tokenExists(fromTokenId) tokenExists(toTokenId) {
        if (fromTokenId == toTokenId) {
            revert EQA__CannotTransferExperienceToSelf(fromTokenId);
        }
        if (amount == 0) return;

        address caller = msg.sender;
        address ownerFrom = ownerOf(fromTokenId);
        address ownerTo = ownerOf(toTokenId);
        address delegateFrom = _utilityDelegates[fromTokenId];
        address delegateTo = _utilityDelegates[toTokenId];

        bool callerOwnsOrDelegatesBoth =
            ((caller == ownerFrom || caller == delegateFrom) || isApprovedForAll(ownerFrom, caller) || getApproved(fromTokenId) == caller) &&
            ((caller == ownerTo || caller == delegateTo) || isApprovedForAll(ownerTo, caller) || getApproved(toTokenId) == caller);

        bool tokensAreEntangled = _entangledTokens[fromTokenId] == toTokenId;

        if (!callerOwnsOrDelegatesBoth && !tokensAreEntangled) {
            revert EQA__TransferExperienceRequiresEntanglementOrOwnership(fromTokenId, toTokenId);
        }

        if (_tokenExperience[fromTokenId] < amount) {
            amount = _tokenExperience[fromTokenId]; // Transfer max available
        }

        _tokenExperience[fromTokenId] -= amount;
        _gainExperience(toTokenId, amount); // Use internal helper to add exp and emit event

        emit ExperienceTransferred(fromTokenId, toTokenId, amount);

        // Check both tokens for level ups after the transfer
        _checkLevelUp(fromTokenId);
        _checkLevelUp(toTokenId);
    }

    /// @notice Placeholder for a more complex interaction like merging token properties.
    /// This function is intended to demonstrate a potential advanced dynamic.
    /// Actual merge logic would be complex and depend heavily on desired game mechanics.
    /// Requires specific conditions (e.g., entangled, minimum level, observed state).
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function mergeProperties(uint256 tokenId1, uint256 tokenId2) public tokenExists(tokenId1) tokenExists(tokenId2) {
        // This is a placeholder. Actual merge logic would go here.
        // Example conditions:
        bool meetsMergeCriteria =
            isEntangled(tokenId1) && getEntangledToken(tokenId1) == tokenId2 && // Must be entangled
            isStateObserved(tokenId1) && isStateObserved(tokenId2) &&         // Must be observed
            _tokenLevels[tokenId1] >= 5 && _tokenLevels[tokenId2] >= 5;        // Minimum level requirement

        if (!meetsMergeCriteria) {
             revert EQA__InvalidMergeConditions(tokenId1, tokenId2);
        }

        // --- Complex Merge Logic Placeholder ---
        // Example:
        // - Break entanglement
        // _clearEntanglement(tokenId1);
        // - Combine experience/levels?
        // uint256 combinedExp = _tokenExperience[tokenId1] + _tokenExperience[tokenId2];
        // uint256 newLevel = max(_tokenLevels[tokenId1], _tokenLevels[tokenId2]) + 1; // Example logic
        // - Assign combined state to one token, maybe burn the other?
        // _tokenLevels[tokenId1] = newLevel;
        // _tokenExperience[tokenId1] = combinedExp;
        // burnQuantumAsset(tokenId2); // Example: Burn the second token after merge
        // - Emit specific merge event

        // As a simple placeholder: just emit an event
        emit EntanglementBroken(tokenId1, tokenId2); // Merging might break entanglement
        // Potentially emit a Merge event
        // emit PropertiesMerged(tokenId1, tokenId2, "details of merge outcome");
    }

    // --- Configuration & Admin Functions (Owner Only) ---

    /// @notice Sets the experience points required to reach a specific level.
    /// Callable only by the contract owner.
    /// @param level The level to set the requirement for (e.g., 1 for level 1, 2 for level 2, etc.).
    /// @param requiredExp The experience points needed to reach this level from the previous level.
    function setExpRequiredForLevel(uint256 level, uint256 requiredExp) public onlyOwner {
        require(level > 0, "Level must be greater than 0");
        expRequiredForLevel[level] = requiredExp;
    }

    /// @notice Sets the native token cost to propose entanglement.
    /// Callable only by the contract owner.
    /// @param cost The cost in wei.
    function setEntanglementCost(uint256 cost) public onlyOwner {
        entanglementCost = cost;
    }

     /// @notice Sets the base URI for token metadata.
     /// Callable only by the contract owner.
     /// @param newURI The new base URI.
    function updateBaseURI(string memory newURI) public onlyOwner {
        _baseTokenURI = newURI;
    }

    /// @notice Pauses new entanglement proposals.
    /// Callable only by the contract owner.
    function pauseEntanglementCreation() public onlyOwner {
        entanglementCreationPaused = true;
        emit EntanglementCreationPausedEvent();
    }

    /// @notice Unpauses new entanglement proposals.
    /// Callable only by the contract owner.
    function unpauseEntanglementCreation() public onlyOwner {
        entanglementCreationPaused = false;
        emit EntanglementCreationUnpausedEvent();
    }

    // --- Overrides for ERC721 Standard Functions ---
    // Ensure base ERC721 functions work as expected.
    // No need to list all of them here as they are inherited,
    // but confirm access controls and modifiers on custom functions that wrap or interact with token state.

    // Example: Adding tokenExists modifier to transfer functions if desired,
    // but OpenZeppelin's _exists check within _transfer/_safeTransferFrom is usually sufficient.
    // If adding custom pre-checks before OZ's internal ones, add the modifier.
    // function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) tokenExists(tokenId) {
    //     super.transferFrom(from, to, tokenId);
    // }
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) tokenExists(tokenId) {
    //     super.safeTransferFrom(from, to, tokenId);
    // }
     // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) tokenExists(tokenId) {
    //     super.safeTransferFrom(from, to, tokenId, data);
    // }
}
```