Okay, let's design a creative, advanced smart contract. How about an NFT contract that simulates "Quantum Entanglement" and "Superposition"? The properties of these NFTs can be in a state of superposition (uncertainty) until observed, and observing one entangled NFT might influence the properties of its entangled partner, probabilistically. We'll use Chainlink VRF for verifiable randomness to determine the outcome of observations and mutations.

This contract will include:
*   **Core NFT functionality** (ERC721).
*   **Entanglement mechanism**: Linking two NFTs.
*   **Superposition mechanism**: Marking certain properties as uncertain.
*   **Observation trigger**: A function that "collapses" superposition and potentially triggers mutations.
*   **Probabilistic Mutations**: Using VRF, observed properties and potentially entangled partners' properties change based on randomness.
*   **Time-based states**: Observation cool-downs.
*   **Fees**: Mechanisms for collecting protocol fees on certain actions.
*   **Owner control**: Setting fees, mutation odds, etc.

This concept combines digital ownership, state management, verifiable randomness, probabilistic outcomes, and a unique interaction model inspired metaphorically by quantum mechanics. It's not a standard ERC-721, ERC-1155, or common DeFi/DAO pattern.

---

**Smart Contract: QuantumEntanglementNFT**

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports**: ERC721, Ownable, VRFConsumerBaseV2, SafeMath (though 0.8+ has overflow checks).
3.  **Error Definitions**
4.  **Events**: Minting, Entanglement, Unentanglement, Superposition Change, Observation, Mutation Triggered, Mutation Fulfilled, Fee Collection, VRF Request/Fulfillment.
5.  **Structs**: `NFTState` (stores properties, entanglement, superposition status, observation time).
6.  **State Variables**:
    *   ERC721 token counter, mappings for token data, owner, approvals.
    *   Mapping for entangled token pairs.
    *   Mapping for VRF request IDs to token IDs involved.
    *   VRF configuration (key hash, subscription ID, gas limit).
    *   Protocol fees (entanglement, observation).
    *   Mutation odds (probability thresholds).
    *   Observation cool-down duration.
    *   Collected protocol fees.
7.  **Constructor**: Initializes ERC721, Ownable, VRF Consumer, sets initial parameters.
8.  **Modifiers**: Check entanglement, check superposition status, check observation cool-down.
9.  **ERC721 Overrides**: `supportsInterface`, `tokenURI` (basic stub), potentially others if needed.
10. **Core NFT Functions**:
    *   `mintToken`: Mints a new NFT, assigns initial properties, sets initial superposition/entanglement status.
    *   `transferFrom`, `safeTransferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `ownerOf`, `balanceOf`, `totalSupply`: Standard ERC721 functions (mostly inherited/handled by parent).
11. **Quantum Mechanics Inspired Functions**:
    *   `entangleTokens`: Links two NFTs together. Requires certain conditions (e.g., neither is already entangled). Pays entanglement fee.
    *   `unentangleTokens`: Breaks the link between two entangled NFTs. Pays a fee or has a cool-down.
    *   `enterSuperposition`: Allows an owner to put specified properties of their NFT into a superposition state.
    *   `exitSuperposition`: Allows an owner to take specified properties out of superposition without observation.
    *   `observeToken`: The key interaction. Checks cool-down. If NFT has properties in superposition and is possibly entangled, it requests randomness via VRF. Pays observation fee.
    *   `fulfillRandomWords`: VRF callback. This function is triggered by Chainlink after `observeToken` requests randomness. It reads the random value and deterministically applies state changes/mutations based on the mutation odds, affecting the observed token and potentially its entangled partner (if also superpositioned).
    *   `getPropertyState`: Gets the *current* fixed state of a specific property.
    *   `getPropertyIndicesInSuperposition`: Lists which properties are currently in superposition for a token.
    *   `isSuperpositioned`: Checks if a token has *any* properties in superposition.
    *   `isEntangled`: Checks if a token is entangled.
    *   `getEntangledToken`: Returns the ID of the entangled token.
    *   `getLastObservedTime`: Gets the timestamp of the last observation.
    *   `canObserve`: Checks if a token is available for observation (not in cool-down).
12. **Owner/Admin Functions**:
    *   `withdrawFees`: Allows owner to withdraw collected protocol fees.
    *   `setEntanglementFee`: Sets the fee for entanglement.
    *   `setObservationFee`: Sets the fee for observation.
    *   `setMutationOdds`: Sets the probability thresholds used in `fulfillRandomWords`.
    *   `setObservationCooldown`: Sets the duration of the observation cool-down.
    *   `setVrfConfig`: Sets Chainlink VRF parameters.
    *   `rescueTokens`: Allows owner to rescue ERC20/ERC721 mistakenly sent to the contract (excluding its own tokens).
    *   `emergencyUnentangle`: Allows owner to break entanglement in an emergency.
13. **Internal/Helper Functions**:
    *   `_generateInitialProperties`: Creates initial properties for a new NFT.
    *   `_requestRandomMutation`: Internal function to handle VRF request logic.
    *   `_applyMutation`: Internal function to apply property changes based on randomness.
    *   `_updateTokenState`: Internal function to update the `NFTState` struct.
    *   `_exists`: Override ERC721 exists check.
    *   `_beforeTokenTransfer`: Override ERC721 hook (potentially add checks related to entanglement/superposition).

**Function Summary (20+ functions):**

1.  `constructor()`: Initializes contract state, ERC721, Ownable, VRFConsumer.
2.  `supportsInterface(bytes4 interfaceId)`: Standard ERC721 function.
3.  `tokenURI(uint256 tokenId)`: Standard ERC721 function (placeholder).
4.  `mintToken(address to, uint256[] initialProperties, bool[] initiallySuperpositioned)`: Mints a new QENFT with initial state.
5.  `entangleTokens(uint256 tokenId1, uint256 tokenId2)`: Links two NFTs together.
6.  `unentangleTokens(uint256 tokenId)`: Breaks the entanglement of an NFT and its partner.
7.  `enterSuperposition(uint256 tokenId, uint256[] propertyIndices)`: Sets specified properties of an NFT into superposition.
8.  `exitSuperposition(uint256 tokenId, uint256[] propertyIndices)`: Removes specified properties from superposition without observing.
9.  `observeToken(uint256 tokenId)`: Triggers the observation process, requesting VRF randomness if needed, potentially collapsing superposition and causing mutations.
10. `fulfillRandomWords(uint256 requestId, uint256[] randomWords)`: VRF callback. Applies mutations based on random word and entanglement state.
11. `getPropertyState(uint256 tokenId, uint256 propertyIndex)`: Gets the current value of a specific property.
12. `getPropertyIndicesInSuperposition(uint256 tokenId)`: Returns an array of indices for properties currently in superposition.
13. `isSuperpositioned(uint256 tokenId)`: Checks if the token has *any* property in superposition.
14. `isEntangled(uint256 tokenId)`: Checks if the token is entangled.
15. `getEntangledToken(uint256 tokenId)`: Returns the ID of the token entangled with the given one.
16. `getLastObservedTime(uint256 tokenId)`: Gets the timestamp of the last observation.
17. `canObserve(uint256 tokenId)`: Checks if the token is past its observation cool-down.
18. `withdrawFees(address tokenAddress)`: Owner function to withdraw collected fees for a specific token (ETH via zero address).
19. `setEntanglementFee(uint256 fee)`: Owner function to set the entanglement fee.
20. `setObservationFee(uint256 fee)`: Owner function to set the observation fee.
21. `setMutationOdds(uint256 observerMutationPercent, uint256 entangledMutationPercent)`: Owner function to set probability thresholds for mutations.
22. `setObservationCooldown(uint256 duration)`: Owner function to set the observation cool-down duration.
23. `setVrfConfig(uint64 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit)`: Owner function to set Chainlink VRF parameters.
24. `rescueTokens(address tokenAddress, address to, uint256 amountOrTokenId)`: Owner function to rescue misplaced tokens.
25. `emergencyUnentangle(uint256 tokenId)`: Owner function to force unentanglement.
26. `ownerOf(uint256 tokenId)`: Standard ERC721 getter.
27. `balanceOf(address owner)`: Standard ERC721 getter.
28. `totalSupply()`: Standard ERC721 getter.
29. `transferFrom(...)`, `safeTransferFrom(...)`, `approve(...)`, `setApprovalForAll(...)`, `getApproved(...)`, `isApprovedForAll(...)`: Standard ERC721 transfer and approval functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For rescue function

// Outline:
// 1. SPDX License & Pragma
// 2. Imports: ERC721, Ownable, VRFConsumerBaseV2, IERC20
// 3. Error Definitions
// 4. Events: State changes, fees, VRF requests/fulfills
// 5. Structs: NFTState (properties, entanglement, superposition, observation)
// 6. State Variables: Token counter, NFT data mapping, VRF config, fees, odds, cooldown, collected fees.
// 7. Constructor: Initializes bases, sets initial params.
// 8. Modifiers: Entanglement, superposition, observation cool-down checks.
// 9. ERC721 Overrides: supportsInterface, tokenURI, _beforeTokenTransfer
// 10. Core NFT Functions: mintToken, standard ERC721 functions (handled by parent)
// 11. Quantum Mechanics Inspired Functions: entangle, unentangle, enter/exit superposition, observe, fulfill random words, state getters.
// 12. Owner/Admin Functions: Set fees/odds/cooldown/VRF, withdraw fees, rescue, emergency unentangle.
// 13. Internal/Helper Functions: Generate properties, request VRF, apply mutation, update state.

// Function Summary (29 functions listed above outline):
// constructor, supportsInterface, tokenURI, mintToken, entangleTokens, unentangleTokens,
// enterSuperposition, exitSuperposition, observeToken, fulfillRandomWords, getPropertyState,
// getPropertyIndicesInSuperposition, isSuperpositioned, isEntangled, getEntangledToken,
// getLastObservedTime, canObserve, withdrawFees, setEntanglementFee, setObservationFee,
// setMutationOdds, setObservationCooldown, setVrfConfig, rescueTokens, emergencyUnentangle,
// ownerOf, balanceOf, totalSupply, transferFrom, safeTransferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll.
// Note: Standard ERC721 functions like ownerOf, balanceOf, transferFrom etc., while listed for count/completeness, are primarily handled by the inherited ERC721 contract. The *unique* functions are the quantum-inspired ones and owner controls. The unique count is well over 20.

contract QuantumEntanglementNFT is ERC721, Ownable, VRFConsumerBaseV2 {
    // --- Errors ---
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwnerOrApproved(uint256 tokenId);
    error TokensAlreadyEntangled(uint256 tokenId1, uint256 tokenId2);
    error TokensNotEntangled(uint256 tokenId);
    error SelfEntanglementNotAllowed();
    error InvalidPropertyIndex(uint256 tokenId, uint256 propertyIndex);
    error NoPropertiesInSuperposition(uint256 tokenId);
    error ObservationCooldownActive(uint256 tokenId, uint256 timeLeft);
    error NotEnoughFundsProvided();
    error OnlyZeroAddressForEth();
    error NothingToWithdraw();
    error CannotRescueOwnNFTs();
    error VRFSubscriptionNotSet();

    // --- Events ---
    event TokenMinted(uint256 indexed tokenId, address indexed owner, uint256[] initialProperties);
    event TokensEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event TokensUnentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PropertiesEnteredSuperposition(uint256 indexed tokenId, uint256[] propertyIndices);
    event PropertiesExitedSuperposition(uint256 indexed tokenId, uint256[] propertyIndices);
    event TokenObserved(uint256 indexed tokenId, uint256 vrfRequestId);
    event MutationTriggered(uint256 indexed tokenId, uint256 vrfRequestId);
    event MutationFulfilled(uint256 indexed requestId, uint256 indexed tokenId, uint256 randomNumber);
    event FeeCollected(address indexed tokenAddress, uint256 amount);
    event VRFConfigUpdated(uint64 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit);

    // --- Structs ---
    struct NFTState {
        uint256[] properties; // The fixed state of properties
        uint256 entangledTokenId; // 0 if not entangled
        bool[] propertiesInSuperposition; // Tracks which properties are in superposition
        uint256 lastObservedTimestamp; // Timestamp of the last observation
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    mapping(uint256 => NFTState) private _tokenStates;
    mapping(uint256 => uint256) private _entangledPairs; // tokenId => entangledWithTokenId

    // Chainlink VRF variables
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private s_callbackGasLimit;
    mapping(uint256 => uint256) private s_vrfRequestToTokenId; // VRF request ID => Token ID observed
    mapping(uint256 => uint256) private s_vrfRequestToEntangledTokenId; // VRF request ID => Entangled Token ID (0 if none or not entangled)

    // Protocol Fees (in wei)
    uint256 private _entanglementFee;
    uint256 private _observationFee;
    mapping(address => uint256) private _collectedFees; // Mapping token address (0x0 for ETH) to collected amount

    // Mutation Odds (represented as percentage / 100, e.g., 5000 is 50.00%)
    uint256 private _observerMutationPercent; // Probability observed token properties mutate if in superposition
    uint256 private _entangledMutationPercent; // Probability entangled token properties mutate if also in superposition

    // Time-based states
    uint256 private _observationCooldownDuration; // Duration in seconds

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint32 callbackGasLimit,
        uint256 entanglementFee,
        uint256 observationFee,
        uint256 observerMutationPercent,
        uint256 entangledMutationPercent,
        uint256 observationCooldownDuration
    )
        ERC721(name, symbol)
        Ownable(msg.sender)
        VRFConsumerBaseV2(0x01AI) // Dummy address, replace with actual VRF Coordinator address for chain
    {
        _nextTokenId = 1;
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;

        _entanglementFee = entanglementFee;
        _observationFee = observationFee;

        // Ensure percentages are reasonable (e.g., max 10000)
        _observerMutationPercent = observerMutationPercent;
        _entangledMutationPercent = entangledMutationPercent;

        _observationCooldownDuration = observationCooldownDuration;
    }

    // --- Modifiers ---
    modifier tokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        _;
    }

    modifier onlyTokenOwnerOrApproved(uint256 tokenId) {
        if (_tokenStates[tokenId].entangledTokenId != 0 && _isEntanglementLocked(tokenId)) {
             // If entangled and locked, maybe only the *pair* can perform certain actions?
             // For simplicity, stick to standard ownership/approval for now, but this is a potential complex mechanic.
             // For this version, let's just allow owner/approved standard ERC721 actions.
        }
        if (ownerOf(tokenId) != msg.sender && !isApprovedForAll(ownerOf(tokenId), msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotTokenOwnerOrApproved(tokenId);
        }
        _;
    }

    modifier notEntangled(uint256 tokenId) {
        if (_entangledPairs[tokenId] != 0) {
            revert TokensAlreadyEntangled(tokenId, _entangledPairs[tokenId]);
        }
        _;
    }

     modifier mustBeEntangled(uint256 tokenId) {
        if (_entangledPairs[tokenId] == 0) {
            revert TokensNotEntangled(tokenId);
        }
        _;
    }

    modifier mustHaveSuperposition(uint256 tokenId) {
        bool hasSuperposition = false;
        for (uint i = 0; i < _tokenStates[tokenId].propertiesInSuperposition.length; i++) {
            if (_tokenStates[tokenId].propertiesInSuperposition[i]) {
                hasSuperposition = true;
                break;
            }
        }
        if (!hasSuperposition) {
            revert NoPropertiesInSuperposition(tokenId);
        }
        _;
    }

    modifier mustBeObservable(uint256 tokenId) {
        uint256 lastObserved = _tokenStates[tokenId].lastObservedTimestamp;
        uint256 nextObservationTime = lastObserved + _observationCooldownDuration;
        if (lastObserved != 0 && block.timestamp < nextObservationTime) {
            revert ObservationCooldownActive(tokenId, nextObservationTime - block.timestamp);
        }
        _;
    }


    // --- ERC721 Overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, VRFConsumerBaseV2) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override tokenExists(tokenId) returns (string memory) {
        // Placeholder for metadata. Actual implementations would return a link to JSON metadata.
        // Metadata should reflect entanglement, superposition status, and property states.
        return string(abi.encodePacked("ipfs://QMNFT/", Strings.toString(tokenId)));
    }

    // Prevent transfers if entanglement is active or in a state that disallows movement (e.g. mid-observation?)
    // For simplicity, we will allow transfers but break entanglement upon transfer.
    // A more complex version might lock transfers while entangled or in superposition.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) { // Only if it's an actual transfer, not minting/burning
            if (_entangledPairs[tokenId] != 0) {
                // Break entanglement upon transfer
                _unentangleTokens(tokenId, _entangledPairs[tokenId]);
            }
            // Optional: Exit superposition upon transfer? Let's keep it for now.
            // A more complex version might lock transfers if superpositioned.
        }
    }

    // --- Core NFT Function ---
    function mintToken(address to, uint256[] memory initialProperties, bool[] memory initiallySuperpositioned)
        public onlyOwner returns (uint256)
    {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(to, newTokenId);

        // Validate input arrays match
        if (initialProperties.length != initiallySuperpositioned.length) {
            revert("Initial properties and superposition arrays must match in length");
        }

        _tokenStates[newTokenId] = NFTState({
            properties: initialProperties,
            entangledTokenId: 0, // Not entangled initially
            propertiesInSuperposition: initiallySuperpositioned,
            lastObservedTimestamp: 0 // Never observed initially
        });

        emit TokenMinted(newTokenId, to, initialProperties);
        return newTokenId;
    }

    // --- Quantum Mechanics Inspired Functions ---

    function entangleTokens(uint256 tokenId1, uint256 tokenId2)
        public payable
        tokenExists(tokenId1)
        tokenExists(tokenId2)
        notEntangled(tokenId1)
        notEntangled(tokenId2)
    {
        if (tokenId1 == tokenId2) {
            revert SelfEntanglementNotAllowed();
        }

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Require approval from one owner, or direct call by one owner with value
        bool callerIsOwnerOrApproved1 = (owner1 == msg.sender || isApprovedForAll(owner1, msg.sender) || getApproved(tokenId1) == msg.sender);
        bool callerIsOwnerOrApproved2 = (owner2 == msg.sender || isApprovedForAll(owner2, msg.sender) || getApproved(tokenId2) == msg.sender);

        if (!callerIsOwnerOrApproved1 && !callerIsOwnerOrApproved2) {
             revert NotTokenOwnerOrApproved(tokenId1); // Revert with one of the tokens
        }

        // Require fee payment if specified
        if (_entanglementFee > 0 && msg.value < _entanglementFee) {
            revert NotEnoughFundsProvided();
        }
        if (_entanglementFee > 0) {
             _collectedFees[address(0)] += msg.value; // Collect ETH fee
             emit FeeCollected(address(0), msg.value);
        }


        _entangledPairs[tokenId1] = tokenId2;
        _entangledPairs[tokenId2] = tokenId1;
        _tokenStates[tokenId1].entangledTokenId = tokenId2;
        _tokenStates[tokenId2].entangledTokenId = tokenId1;

        emit TokensEntangled(tokenId1, tokenId2);
    }

    function unentangleTokens(uint256 tokenId)
        public payable
        tokenExists(tokenId)
        mustBeEntangled(tokenId)
    {
        uint256 entangledWithId = _entangledPairs[tokenId];

        // Require approval from the owner of the token initiating the unentanglement
        address owner = ownerOf(tokenId);
        if (owner != msg.sender && !isApprovedForAll(owner, msg.sender) && getApproved(tokenId) != msg.sender) {
            revert NotTokenOwnerOrApproved(tokenId);
        }

        // Add an unentanglement fee or mechanism if desired (omitted for simplicity here)
        // E.g., require a fee, or have a cooldown before unentangling

        _unentangleTokens(tokenId, entangledWithId);
    }

    // Internal helper for unentanglement
    function _unentangleTokens(uint256 tokenId1, uint256 tokenId2) internal {
        delete _entangledPairs[tokenId1];
        delete _entangledPairs[tokenId2];
        _tokenStates[tokenId1].entangledTokenId = 0;
        _tokenStates[tokenId2].entangledTokenId = 0;
        emit TokensUnentangled(tokenId1, tokenId2);
    }


    function enterSuperposition(uint256 tokenId, uint256[] memory propertyIndices)
        public onlyTokenOwnerOrApproved(tokenId) tokenExists(tokenId)
    {
        NFTState storage tokenState = _tokenStates[tokenId];
        for (uint i = 0; i < propertyIndices.length; i++) {
            uint256 propIndex = propertyIndices[i];
            if (propIndex >= tokenState.propertiesInSuperposition.length) {
                revert InvalidPropertyIndex(tokenId, propIndex);
            }
            tokenState.propertiesInSuperposition[propIndex] = true;
        }
        emit PropertiesEnteredSuperposition(tokenId, propertyIndices);
    }

    function exitSuperposition(uint256 tokenId, uint256[] memory propertyIndices)
        public onlyTokenOwnerOrApproved(tokenId) tokenExists(tokenId)
    {
        NFTState storage tokenState = _tokenStates[tokenId];
        for (uint i = 0; i < propertyIndices.length; i++) {
            uint256 propIndex = propertyIndices[i];
             if (propIndex >= tokenState.propertiesInSuperposition.length) {
                revert InvalidPropertyIndex(tokenId, propIndex);
            }
            tokenState.propertiesInSuperposition[propIndex] = false;
        }
         emit PropertiesExitedSuperposition(tokenId, propertyIndices);
    }

    function observeToken(uint256 tokenId)
        public payable
        onlyTokenOwnerOrApproved(tokenId) // Only owner or approved can observe
        tokenExists(tokenId)
        mustHaveSuperposition(tokenId) // Must have at least one property in superposition
        mustBeObservable(tokenId)      // Must not be in observation cooldown
    {
         // Require fee payment if specified
        if (_observationFee > 0 && msg.value < _observationFee) {
            revert NotEnoughFundsProvided();
        }
         if (_observationFee > 0) {
             _collectedFees[address(0)] += msg.value; // Collect ETH fee
             emit FeeCollected(address(0), msg.value);
        }

        NFTState storage tokenState = _tokenStates[tokenId];
        tokenState.lastObservedTimestamp = block.timestamp;

        uint256 entangledTokenId = tokenState.entangledTokenId;

        // Request randomness for mutation outcome
        _requestRandomMutation(tokenId, entangledTokenId);

        emit TokenObserved(tokenId, s_vrfRequestToTokenId[tokenId]); // This mapping is set in _requestRandomMutation
    }

    // Internal function to handle VRF request
    function _requestRandomMutation(uint256 tokenId, uint256 entangledTokenId) internal {
        if (s_subscriptionId == 0) revert VRFSubscriptionNotSet();

        uint256 requestId = requestRandomWords(s_keyHash, s_subscriptionId, 1, s_callbackGasLimit, 1);

        s_vrfRequestToTokenId[requestId] = tokenId;
        s_vrfRequestToEntangledTokenId[requestId] = entangledTokenId;

        emit MutationTriggered(tokenId, requestId);
    }

    // VRF Callback function
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // This function is called by the VRF Coordinator
        uint256 observedTokenId = s_vrfRequestToTokenId[requestId];
        uint256 entangledTokenId = s_vrfRequestToEntangledTokenId[requestId];

        // Clean up the mapping immediately
        delete s_vrfRequestToTokenId[requestId];
        delete s_vrfRequestToEntangledTokenId[requestId];

        if (observedTokenId == 0) {
            // This request ID was not initiated by this contract (or already fulfilled)
            // Should not happen with correct VRF setup, but good defensive check.
            return;
        }

        // Use the single random word provided
        uint256 randomNumber = randomWords[0];

        emit MutationFulfilled(requestId, observedTokenId, randomNumber);

        // Apply mutation logic to the observed token
        _applyMutation(observedTokenId, randomNumber, _observerMutationPercent);

        // Apply mutation logic to the entangled token, if it exists and is also superpositioned
        if (entangledTokenId != 0 && _tokenStates[entangledTokenId].entangledTokenId == observedTokenId) { // Check entanglement symmetry
             bool entangledHasSuperposition = false;
             for(uint i = 0; i < _tokenStates[entangledTokenId].propertiesInSuperposition.length; i++) {
                 if (_tokenStates[entangledTokenId].propertiesInSuperposition[i]) {
                     entangledHasSuperposition = true;
                     break;
                 }
             }

             if (entangledHasSuperposition) {
                 // Use the *same* random number, but apply the entangled mutation odds
                 _applyMutation(entangledTokenId, randomNumber, _entangledMutationPercent);
             }
        }
    }

    // Internal function to apply mutation based on random number and odds
    function _applyMutation(uint256 tokenId, uint256 randomNumber, uint256 mutationPercent) internal {
         NFTState storage tokenState = _tokenStates[tokenId];

        // Use the random number to decide if mutation occurs based on mutationPercent
        // random number is uint256, scale it down to 0-9999 range for percentage check
        uint256 randomPercent = randomNumber % 10000; // gives value between 0 and 9999

        if (randomPercent < mutationPercent) { // If random value is less than the threshold percent
            // Mutation occurs!
            // Iterate through superpositioned properties and assign new random values
            for (uint i = 0; i < tokenState.properties.length; i++) {
                if (tokenState.propertiesInSuperposition[i]) {
                    // Generate a new random value for this property.
                    // The range/logic for the new value depends on the property meaning.
                    // For this generic example, let's just assign a new random value from a large range.
                    // In a real application, this would use the random number to pick from predefined states or generate within a specific type range.
                    // For simplicity here, let's use a chunk of the random number for each property.
                    // Using `keccak256` with the original random number, token ID, and property index can generate seemingly independent values.
                    uint256 propertyRandomness = uint256(keccak256(abi.encodePacked(randomNumber, tokenId, i)));
                    tokenState.properties[i] = propertyRandomness; // Assign a new random value

                    // After mutation, the property is no longer in superposition (it's observed/fixed)
                    tokenState.propertiesInSuperposition[i] = false;
                     // Emit event for this specific property mutation? Or just the overall fulfill event?
                     // Let's stick to the MutationFulfilled event for gas.
                }
            }
        } else {
             // No mutation, but superposition collapses for observed properties
             for (uint i = 0; i < tokenState.properties.length; i++) {
                 if (tokenState.propertiesInSuperposition[i]) {
                     tokenState.propertiesInSuperposition[i] = false;
                 }
             }
        }
        // The state is updated in the storage mapping
    }

    // --- Getters ---

    function getPropertyState(uint256 tokenId, uint256 propertyIndex)
        public view tokenExists(tokenId) returns (uint256)
    {
        NFTState storage tokenState = _tokenStates[tokenId];
        if (propertyIndex >= tokenState.properties.length) {
            revert InvalidPropertyIndex(tokenId, propertyIndex);
        }
        return tokenState.properties[propertyIndex];
    }

    function getPropertyIndicesInSuperposition(uint256 tokenId)
         public view tokenExists(tokenId) returns (uint256[] memory)
    {
        NFTState storage tokenState = _tokenStates[tokenId];
        uint256[] memory superpositionIndices = new uint256[](tokenState.properties.length);
        uint256 count = 0;
        for (uint i = 0; i < tokenState.propertiesInSuperposition.length; i++) {
            if (tokenState.propertiesInSuperposition[i]) {
                superpositionIndices[count] = i;
                count++;
            }
        }
        bytes memory packed = abi.encodePacked(superpositionIndices); // Pack to trim unused elements
        return abi.decode(packed, (uint256[])); // Decode back to the correct size array
    }

    function isSuperpositioned(uint256 tokenId)
        public view tokenExists(tokenId) returns (bool)
    {
        NFTState storage tokenState = _tokenStates[tokenId];
        for (uint i = 0; i < tokenState.propertiesInSuperposition.length; i++) {
            if (tokenState.propertiesInSuperposition[i]) {
                return true;
            }
        }
        return false;
    }

    function isEntangled(uint256 tokenId)
        public view tokenExists(tokenId) returns (bool)
    {
        return _entangledPairs[tokenId] != 0;
    }

    function getEntangledToken(uint256 tokenId)
        public view tokenExists(tokenId) returns (uint256)
    {
        return _entangledPairs[tokenId];
    }

     function getLastObservedTime(uint256 tokenId)
        public view tokenExists(tokenId) returns (uint256)
    {
        return _tokenStates[tokenId].lastObservedTimestamp;
    }

    function canObserve(uint256 tokenId)
        public view tokenExists(tokenId) returns (bool)
    {
        uint256 lastObserved = _tokenStates[tokenId].lastObservedTimestamp;
        if (lastObserved == 0) {
            return true; // Never observed
        }
        return block.timestamp >= lastObserved + _observationCooldownDuration;
    }

    // --- Owner/Admin Functions ---

    function withdrawFees(address tokenAddress) public onlyOwner {
        uint256 amount = _collectedFees[tokenAddress];
        if (amount == 0) {
            revert NothingToWithdraw();
        }

        _collectedFees[tokenAddress] = 0; // Reset balance first

        if (tokenAddress == address(0)) {
            // Withdraw ETH
            (bool success, ) = payable(owner()).call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            // Withdraw ERC20
            IERC20 token = IERC20(tokenAddress);
            token.transfer(owner(), amount);
        }

        emit FeeCollected(tokenAddress, amount); // Re-use event to indicate withdrawal
    }

     function setEntanglementFee(uint256 fee) public onlyOwner {
        _entanglementFee = fee;
     }

    function setObservationFee(uint256 fee) public onlyOwner {
        _observationFee = fee;
    }

    // Percentages are scaled by 100 (e.g., 5000 for 50%)
    function setMutationOdds(uint256 observerMutationPercent, uint256 entangledMutationPercent) public onlyOwner {
        require(observerMutationPercent <= 10000 && entangledMutationPercent <= 10000, "Percentages must be <= 10000 (100%)");
        _observerMutationPercent = observerMutationPercent;
        _entangledMutationPercent = entangledMutationPercent;
    }

    function setObservationCooldown(uint256 duration) public onlyOwner {
        _observationCooldownDuration = duration;
    }

    function setVrfConfig(uint64 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit) public onlyOwner {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        s_callbackGasLimit = callbackGasLimit;
         emit VRFConfigUpdated(subscriptionId, keyHash, callbackGasLimit);
    }

    // Allow owner to rescue mistakenly sent tokens (ERC20 or ERC721)
    function rescueTokens(address tokenAddress, address to, uint256 amountOrTokenId) public onlyOwner {
        require(to != address(0), "Recipient cannot be zero address");

        if (tokenAddress == address(0)) {
             revert OnlyZeroAddressForEth(); // Use withdrawFees for ETH
        }

        // Check if it's THIS contract's NFT
        if (tokenAddress == address(this)) {
            revert CannotRescueOwnNFTs();
        }

        // Attempt ERC20 transfer
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance >= amountOrTokenId) {
            token.transfer(to, amountOrTokenId);
            return;
        }

        // Attempt ERC721 transfer
        try IERC721(tokenAddress).ownerOf(amountOrTokenId) returns (address currentOwner) {
            if (currentOwner == address(this)) {
                IERC721(tokenAddress).safeTransferFrom(address(this), to, amountOrTokenId);
                return;
            }
        } catch {}

        revert("No transferable tokens found with that address/id/amount");
    }

    function emergencyUnentangle(uint256 tokenId) public onlyOwner tokenExists(tokenId) mustBeEntangled(tokenId) {
        uint256 entangledWithId = _entangledPairs[tokenId];
         _unentangleTokens(tokenId, entangledWithId);
    }


    // --- Internal/Helper Functions (as described in outline) ---
    // _generateInitialProperties - Logic is included directly in mintToken for this version.
    // _requestRandomMutation - Implemented above.
    // _applyMutation - Implemented above.
    // _updateTokenState - State is updated directly on the storage struct in the relevant functions.
    // _exists - Standard ERC721, not strictly needed to override unless custom logic is required.
    // _beforeTokenTransfer - Overridden above to handle unentanglement.

    // Note: Standard ERC721 functions like `ownerOf`, `balanceOf`, `transferFrom`, `approve`, etc., are inherited and function as expected using the internal _safeMint, _transfer, _approve helpers from the OpenZeppelin library. Their logic is not rewritten here but they are available and contribute to the total function count.

    // Example of a simple helper to check entanglement lock (could be added for more complex logic)
    function _isEntanglementLocked(uint256 tokenId) internal view returns (bool) {
        // Example: locked for 1 hour after entanglement, or while in superposition
        return false; // No lock implemented in this version
    }
}
```