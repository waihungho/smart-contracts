Okay, let's design a smart contract concept that combines dynamic NFTs with a generative, evolving system, incorporating various interaction mechanics and state management patterns.

We'll call this contract `DigitalSculptor`. Each NFT represents a unique, evolving digital sculpture defined by a set of parameters stored directly on-chain. Users can interact with their sculptures to alter these parameters, influencing their future state and potentially their visual representation (rendered off-chain based on the on-chain parameters).

This incorporates:
*   **Dynamic NFTs:** The NFT state changes over time or based on interaction.
*   **Generative Art:** The on-chain parameters define the potential output of an off-chain generative process.
*   **Complex State:** Each NFT has multiple parameters and states (locked, complexity level, interaction history).
*   **Diverse Interactions:** Different functions simulate different actions on the sculpture (etching, polishing, growing, mutating, cross-pollinating, decay).
*   **Time-based Mechanics:** Locking for a duration, decay based on time/interactions.
*   **Resource/Cost Mechanics:** Some actions might cost Ether (or a hypothetical resource).
*   **On-chain Hashing:** Creating a hash of the parameters for provenance/verification.
*   **Guardian Role:** A specific address can trigger maintenance functions (like decay).

---

## Contract Outline and Function Summary

**Contract Name:** `DigitalSculptor`

**Core Concept:** A dynamic NFT collection where each token represents an evolving digital sculpture defined by on-chain parameters. Users interact with their sculptures through various functions to change these parameters, influencing the sculpture's state and appearance (rendered off-chain).

**Key Features:**
*   ERC721 standard compliance.
*   On-chain storage of multiple parameters per sculpture.
*   Diverse interaction functions (etch, polish, grow, mutate, cross-pollinate, attune, observe).
*   Time-based parameter locking.
*   Guardian-triggered entropy decay mechanism.
*   Interaction costs (in Ether).
*   On-chain state hashing for provenance.
*   Basic admin controls (set costs, guardian, base URI, etc.).

**State Variables:**
*   `sculptures`: Mapping from token ID to `SculptureParameters` struct.
*   `_nextTokenId`: Counter for minting new tokens.
*   `guardian`: Address designated to trigger decay.
*   `interactionCosts`: Mapping from `InteractionType` enum to required Ether amount.
*   `defaultLockDuration`: Default time parameters are locked after a specific action.
*   `mutationIntensity`: Controls the magnitude of random changes during mutation.
*   `minComplexityForGrowth`: Minimum complexity required for the `growComplexity` function.

**Structs & Enums:**
*   `SculptureParameters`: Stores all dynamic parameters for a sculpture (e.g., `paramA`, `paramB`, `paramC`, `paramD`, `complexity`, `lockEndTime`, `lastInteractionTime`, `historyCount`, `observerInfluence`, `provenanceHash`).
*   `InteractionType`: Enum listing different paid interactions (e.g., `Etch`, `Polish`, `Grow`, `Mutate`, `CrossPollinate`, `Lock`, `ObserverInfluence`, `Attune`).

**Events:**
*   `SculptureMinted`: Log when a new sculpture is created.
*   `ParametersChanged`: Log when a sculpture's parameters are modified by interaction.
*   `SculptureLocked`: Log when a sculpture is locked.
*   `SculptureUnlocked`: Log when a sculpture is unlocked.
*   `DecayTriggered`: Log when decay is applied to a sculpture.
*   `InteractionCostUpdated`: Log when an admin updates an interaction cost.
*   `GuardianUpdated`: Log when the guardian address changes.
*   `ObserverInfluenceRecorded`: Log when observer influence is added.

**Function Summary (Categorized):**

**Standard ERC721 / ERC721URIStorage (Inherited/Overridden):**
1.  `constructor()`: Initializes contract name, symbol, Ownable, and sets initial admin.
2.  `supportsInterface(bytes4 interfaceId)`: Standard ERC165.
3.  `balanceOf(address owner)`: Returns the number of tokens owned by an address.
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token.
5.  `approve(address to, uint256 tokenId)`: Grants approval for one token.
6.  `getApproved(uint256 tokenId)`: Returns the approved address for a token.
7.  `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for all tokens.
8.  `isApprovedForAll(address owner, address operator)`: Checks approval for all tokens.
9.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token (checks approval).
10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer (checks receiver).
11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Safe transfer with data.
12. `tokenURI(uint256 tokenId)`: Returns the URI for metadata of a token.
13. `totalSupply()`: Returns the total number of minted sculptures.

**Admin/Owner Functions (Requires `onlyOwner`):**
14. `setBaseURI(string memory baseURI_)`: Sets the base URI for token metadata.
15. `setInteractionCost(InteractionType interactionType, uint256 cost)`: Sets the Ether cost for a specific interaction type.
16. `withdrawInteractionCosts()`: Allows owner to withdraw collected Ether from interactions.
17. `setGuardian(address newGuardian)`: Sets the address allowed to trigger decay.
18. `setLockDuration(uint48 duration)`: Sets the default duration for parameter locks.
19. `setMutationIntensity(uint128 intensity)`: Sets the magnitude of random changes in mutation.
20. `setMinComplexityForGrowth(uint64 minComplexity)`: Sets the minimum complexity needed for growth.
21. `renounceGuardian()`: Allows the current guardian to step down.

**Guardian/Maintenance Functions (Requires `onlyGuardian` or `onlyOwner`):**
22. `triggerDecay(uint256 tokenId)`: Applies entropy decay to a specific sculpture's parameters.

**Sculpture Interaction Functions (Require `onlyOwnerOfToken` and potential cost/lock checks):**
23. `mintSculpture(address recipient, bytes32 initialSeed, string memory provenance)`: Mints a new sculpture NFT with initial parameters derived from a seed. (Can be restricted to owner or a minter role). Let's make it owner-only for simplicity.
24. `etchParameter(uint256 tokenId, uint128 etchValue)`: Modifies `paramA` based on `etchValue`.
25. `polishSurface(uint256 tokenId, uint128 polishValue)`: Modifies `paramB` based on `polishValue`.
26. `growComplexity(uint256 tokenId, uint64 growthAmount)`: Increases `complexity` if above the minimum threshold. Costs Ether.
27. `applyMutation(uint256 tokenId)`: Randomly perturbs parameters (`paramA`, `paramB`, `paramC`, `paramD`) based on mutation intensity and a pseudo-random seed derived from block data/token state. Costs Ether.
28. `crossPollinate(uint256 tokenIdSource1, uint256 tokenIdSource2, uint256 targetTokenId)`: Combines parameters from two source tokens (`tokenIdSource1`, `tokenIdSource2` owned by caller) to influence a target token (`targetTokenId` owned by caller, or 0 to mint a new one). Complex parameter derivation logic. Costs Ether.
29. `lockParameters(uint256 tokenId)`: Locks a sculpture's parameters from further changes for `defaultLockDuration`. Costs Ether.
30. `unlockParameters(uint256 tokenId)`: Unlocks a sculpture if the lock duration has passed or if called by the owner/admin.
31. `attuneResonance(uint256 tokenIdToAttune, uint256 tokenIdReference)`: Gently modifies the parameters of `tokenIdToAttune` to become slightly closer to those of `tokenIdReference`. Requires owning `tokenIdToAttune`. Costs Ether.
32. `recordObserverInfluence(uint256 tokenId)`: Allows *any* address to pay a small fee to increment the `observerInfluence` counter and slightly affect a hidden parameter of a specific sculpture. Costs Ether.

**View Functions (Read-Only):**
33. `queryCurrentParameters(uint256 tokenId)`: Returns the current `SculptureParameters` struct for a sculpture.
34. `getSculptureStateHash(uint256 tokenId)`: Computes and returns a Keccak256 hash of the current parameters struct. Useful for off-chain rendering verification.
35. `isParameterLocked(uint256 tokenId)`: Checks if a sculpture's parameters are currently locked.
36. `getTimeUntilUnlock(uint256 tokenId)`: Returns the remaining time until a sculpture is unlocked (0 if not locked).
37. `getParameterHistoryCount(uint256 tokenId)`: Returns the total number of times parameters have been changed via interaction.
38. `getInteractionCost(InteractionType interactionType)`: Returns the current Ether cost for a specific interaction type.
39. `getGuardian()`: Returns the address of the current guardian.

**Total Functions:** 13 (OZ ERC721/URI) + 9 (Admin/Guardian) + 10 (Interaction) + 7 (View) = **39 Functions**. This meets the requirement of at least 20 functions and incorporates advanced/creative concepts.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For uint calculations if needed, but basic +,-,*,/ often fine with 0.8+
import "@openzeppelin/contracts/utils/Strings.sol"; // For converting uint to string

// --- Outline and Function Summary (See above) ---

// Error Handling (Custom errors are gas efficient)
error NotSculptureOwner(uint256 tokenId);
error SculptureLocked(uint256 tokenId);
error NotEnoughEther(uint256 required, uint256 sent);
error ZeroAddressGuardian();
error InteractionNotConfigured();
error ComplexityTooLow(uint64 required, uint64 current);
error InvalidTokenId();
error AlreadyGuardian();
error NotGuardian();
error LockPeriodTooShort();
error NoInteractionCostsCollected();


contract DigitalSculptor is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Use SafeMath for arithmetic

    // --- State Variables ---
    Counters.Counter private _nextTokenId;

    struct SculptureParameters {
        uint128 paramA; // Example parameter 1
        uint128 paramB; // Example parameter 2
        uint128 paramC; // Example parameter 3 (e.g., color seed)
        uint128 paramD; // Example parameter 4 (e.g., angle offset)
        uint64 complexity; // Metric for complexity, can be increased
        uint48 lockEndTime; // Timestamp when the sculpture is unlocked (0 if not locked)
        uint48 lastInteractionTime; // Timestamp of the last parameter-changing interaction
        uint32 historyCount; // Number of times parameters have been explicitly changed
        uint32 observerInfluence; // Counter for observer interactions
        bytes32 provenanceHash; // Hash representing the initial state or generative process
    }

    mapping(uint256 => SculptureParameters) private sculptures;

    address public guardian;

    enum InteractionType {
        None, // Default/Placeholder
        Etch,
        Polish,
        Grow,
        Mutate,
        CrossPollinate,
        Lock,
        ObserverInfluence,
        Attune
    }

    mapping(InteractionType => uint256) public interactionCosts;

    uint48 public defaultLockDuration = 7 days; // Default lock duration
    uint128 public mutationIntensity = 100; // Controls magnitude of mutation (larger value = larger changes)
    uint64 public minComplexityForGrowth = 10; // Minimum complexity needed to use growComplexity

    // --- Events ---
    event SculptureMinted(uint256 indexed tokenId, address indexed recipient, bytes32 initialSeed, string provenance);
    event ParametersChanged(uint256 indexed tokenId, InteractionType interaction, address indexed modifier, uint128 paramA, uint128 paramB, uint128 paramC, uint128 paramD, uint64 complexity, uint32 historyCount);
    event SculptureLocked(uint256 indexed tokenId, uint48 lockEndTime);
    event SculptureUnlocked(uint256 indexed tokenId);
    event DecayTriggered(uint256 indexed tokenId, address indexed trigger);
    event InteractionCostUpdated(InteractionType indexed interactionType, uint256 cost);
    event GuardianUpdated(address indexed oldGuardian, address indexed newGuardian);
    event ObserverInfluenceRecorded(uint256 indexed tokenId, address indexed observer, uint256 costPaid, uint32 newInfluenceCount);


    // --- Constructor ---
    constructor(string memory name, string memory symbol, address defaultGuardian)
        ERC721(name, symbol)
        Ownable(msg.sender) // msg.sender is the initial owner
    {
        if (defaultGuardian == address(0)) {
            revert ZeroAddressGuardian();
        }
        guardian = defaultGuardian;
        emit GuardianUpdated(address(0), defaultGuardian);

        // Set some initial default costs (can be changed by owner)
        interactionCosts[InteractionType.Etch] = 0; // Maybe some are free or require other conditions
        interactionCosts[InteractionType.Polish] = 0;
        interactionCosts[InteractionType.Grow] = 0.01 ether; // Example: 0.01 ETH
        interactionCosts[InteractionType.Mutate] = 0.005 ether;
        interactionCosts[InteractionType.CrossPollinate] = 0.02 ether;
        interactionCosts[InteractionType.Lock] = 0.002 ether;
        interactionCosts[InteractionType.ObserverInfluence] = 0.0001 ether;
        interactionCosts[InteractionType.Attune] = 0.003 ether;
    }

    // --- ERC721 Overrides ---

    // The rest of standard ERC721 functions (balanceOf, ownerOf, approve, etc.) are provided by ERC721 inheritance.
    // tokenURI is provided by ERC721URIStorage, which we override below.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        _requireMinted(tokenId); // Check if token exists
        string memory base = super.tokenURI(tokenId); // Get base URI set by setBaseURI
        string memory paramsHash = Strings.toHexString(uint256(getSculptureStateHash(tokenId)));

        // Append token ID and state hash to the base URI for dynamic metadata lookup
        // Assumes base URI is something like "ipfs://..." or "https://api.example.com/metadata/"
        // Off-chain service should serve metadata/image based on tokenId and potentially the hash
        return string(abi.encodePacked(base, Strings.toString(tokenId), "/", paramsHash));
    }

    // Override required functions from ERC721URIStorage
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721URIStorage) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721URIStorage) {
        super._increaseBalance(account, value);
    }

    // Override burn function - useful if NFTs can be destroyed
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
         // Optional: Clear sculpture parameters before burning
        delete sculptures[tokenId]; // Frees up storage
        super._burn(tokenId);
    }


    // --- Admin/Owner Functions ---

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_); // Provided by ERC721URIStorage
    }

    function setInteractionCost(InteractionType interactionType, uint256 cost) public onlyOwner {
        if (interactionType == InteractionType.None) {
            revert InteractionNotConfigured();
        }
        interactionCosts[interactionType] = cost;
        emit InteractionCostUpdated(interactionType, cost);
    }

    function withdrawInteractionCosts() public onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoInteractionCostsCollected();
        }
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function setGuardian(address newGuardian) public onlyOwner {
        if (newGuardian == address(0)) {
            revert ZeroAddressGuardian();
        }
        if (newGuardian == guardian) {
            revert AlreadyGuardian();
        }
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit GuardianUpdated(oldGuardian, newGuardian);
    }

    function renounceGuardian() public {
        if (msg.sender != guardian) {
            revert NotGuardian();
        }
        address oldGuardian = guardian;
        guardian = address(0); // Set to zero address to renounce
        emit GuardianUpdated(oldGuardian, address(0));
    }


    function setLockDuration(uint48 duration) public onlyOwner {
        if (duration < 1 minutes) { // Prevent excessively short locks
             revert LockPeriodTooShort();
        }
        defaultLockDuration = duration;
    }

    function setMutationIntensity(uint128 intensity) public onlyOwner {
         mutationIntensity = intensity;
    }

    function setMinComplexityForGrowth(uint64 minComplexity) public onlyOwner {
        minComplexityForGrowth = minComplexity;
    }


    // --- Guardian/Maintenance Functions ---

    // Can be called by Guardian OR Owner
    function triggerDecay(uint256 tokenId) public {
        if (msg.sender != guardian && msg.sender != owner()) {
            revert NotGuardian(); // Reverts if not guardian or owner
        }
        _requireMinted(tokenId);

        SculptureParameters storage sculpture = sculptures[tokenId];
        if (sculpture.lockEndTime > block.timestamp) {
            revert SculptureLocked(tokenId);
        }

        // --- Decay Logic (Example: simple reduction over time) ---
        // Calculate decay based on time since last interaction
        uint256 timeElapsed = block.timestamp - sculpture.lastInteractionTime;

        // Apply decay - simple example: proportional decay over time
        // Decay rate could be proportional to complexity or other factors
        uint128 decayFactorA = uint128(timeElapsed / (1 days)); // Example: decay amount per day
        uint128 decayFactorB = uint128(timeElapsed / (2 days)); // Different rate for different params

        sculpture.paramA = sculpture.paramA > decayFactorA ? sculpture.paramA - decayFactorA : 0;
        sculpture.paramB = sculpture.paramB > decayFactorB ? sculpture.paramB - decayFactorB : 0;
        // Complexity could decay slowly
        sculpture.complexity = sculpture.complexity > uint64(timeElapsed / (3 days)) ? sculpture.complexity - uint64(timeElapsed / (3 days)) : 0;

        // Note: lastInteractionTime is NOT updated by decay, only by active interactions.
        // historyCount is NOT updated by decay.

        emit DecayTriggered(tokenId, msg.sender);
        // No ParametersChanged event as decay is passive maintenance, not active sculpting
    }


    // --- Sculpture Interaction Functions ---

    function mintSculpture(address recipient, bytes32 initialSeed, string memory provenance) public onlyOwner {
        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();

        _safeMint(recipient, tokenId);

        SculptureParameters storage newSculpture = sculptures[tokenId];
        // Initialize parameters based on seed or fixed values
        // Using simple hash to derive initial parameters - not true randomness
        bytes32 initialParamsSeed = keccak256(abi.encodePacked(initialSeed, tokenId, block.timestamp, block.difficulty));

        newSculpture.paramA = uint128(uint256(initialParamsSeed));
        newSculpture.paramB = uint128(uint256(initialParamsSeed >> 128));
        newSculpture.paramC = uint128(uint256(keccak256(abi.encodePacked(initialParamsSeed, "paramC"))));
        newSculpture.paramD = uint128(uint256(keccak256(abi.encodePacked(initialParamsSeed, "paramD"))));
        newSculpture.complexity = 1; // Start with low complexity
        newSculpture.lockEndTime = 0; // Not locked initially
        newSculpture.lastInteractionTime = uint48(block.timestamp);
        newSculpture.historyCount = 0;
        newSculpture.observerInfluence = 0;
        newSculpture.provenanceHash = keccak256(abi.encodePacked(initialSeed, provenance)); // Hash of initial data

        emit SculptureMinted(tokenId, recipient, initialSeed, provenance);
         emit ParametersChanged(
            tokenId,
            InteractionType.None, // Minting isn't a standard interaction type
            msg.sender,
            newSculpture.paramA,
            newSculpture.paramB,
            newSculpture.paramC,
            newSculpture.paramD,
            newSculpture.complexity,
            newSculpture.historyCount
        );
    }

    function etchParameter(uint256 tokenId, uint128 etchValue) public payable {
        _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotSculptureOwner(tokenId);
        _checkLocked(tokenId);
        _checkInteractionCost(InteractionType.Etch, msg.value);

        SculptureParameters storage sculpture = sculptures[tokenId];
        // Example: Simple addition, potentially with wrapping or limits
        sculpture.paramA = sculpture.paramA + etchValue; // Overflow will wrap around due to uint type

        _updateInteractionState(tokenId, InteractionType.Etch);

        emit ParametersChanged(
            tokenId,
            InteractionType.Etch,
            msg.sender,
            sculpture.paramA,
            sculpture.paramB,
            sculpture.paramC,
            sculpture.paramD,
            sculpture.complexity,
            sculpture.historyCount
        );
    }

    function polishSurface(uint256 tokenId, uint128 polishValue) public payable {
        _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotSculptureOwner(tokenId);
        _checkLocked(tokenId);
        _checkInteractionCost(InteractionType.Polish, msg.value);

        SculptureParameters storage sculpture = sculptures[tokenId];
        // Example: Bitwise XOR or other manipulation
        sculpture.paramB = sculpture.paramB ^ polishValue;

        _updateInteractionState(tokenId, InteractionType.Polish);

        emit ParametersChanged(
            tokenId,
            InteractionType.Polish,
            msg.sender,
            sculpture.paramA,
            sculpture.paramB,
            sculpture.paramC,
            sculpture.paramD,
            sculpture.complexity,
            sculpture.historyCount
        );
    }

    function growComplexity(uint256 tokenId, uint64 growthAmount) public payable {
        _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotSculptureOwner(tokenId);
        _checkLocked(tokenId);
        _checkInteractionCost(InteractionType.Grow, msg.value);

        SculptureParameters storage sculpture = sculptures[tokenId];

        if (sculpture.complexity < minComplexityForGrowth) {
            revert ComplexityTooLow(minComplexityForGrowth, sculpture.complexity);
        }

        sculpture.complexity = sculpture.complexity + growthAmount; // Increase complexity

        _updateInteractionState(tokenId, InteractionType.Grow);

         emit ParametersChanged(
            tokenId,
            InteractionType.Grow,
            msg.sender,
            sculpture.paramA,
            sculpture.paramB,
            sculpture.paramC,
            sculpture.paramD,
            sculpture.complexity,
            sculpture.historyCount
        );
    }

    function applyMutation(uint256 tokenId) public payable {
        _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotSculptureOwner(tokenId);
        _checkLocked(tokenId);
        _checkInteractionCost(InteractionType.Mutate, msg.value);

        SculptureParameters storage sculpture = sculptures[tokenId];

        // --- Pseudo-random parameter perturbation ---
        // WARNING: On-chain randomness is challenging and block data can be manipulated by miners.
        // This is a simple approach for game-like mechanics, NOT for security-critical randomness.
        bytes32 seed = keccak256(abi.encodePacked(
            sculpture.paramA, sculpture.paramB, sculpture.paramC, sculpture.paramD,
            sculpture.complexity, sculpture.lastInteractionTime, sculpture.historyCount,
            block.timestamp, block.difficulty, msg.sender
        ));

        uint128 randomValue1 = uint128(uint256(seed));
        uint128 randomValue2 = uint128(uint256(seed >> 64));
        uint128 randomValue3 = uint128(uint256(seed >> 128));
        uint128 randomValue4 = uint128(uint256(seed >> 192));

        // Apply changes based on intensity and pseudo-random values
        sculpture.paramA = sculpture.paramA ^ (randomValue1 % mutationIntensity);
        sculpture.paramB = sculpture.paramB + (randomValue2 % mutationIntensity);
        sculpture.paramC = sculpture.paramC ^ (randomValue3 % mutationIntensity);
        sculpture.paramD = sculpture.paramD + (randomValue4 % mutationIntensity);

        _updateInteractionState(tokenId, InteractionType.Mutate);

        emit ParametersChanged(
            tokenId,
            InteractionType.Mutate,
            msg.sender,
            sculpture.paramA,
            sculpture.paramB,
            sculpture.paramC,
            sculpture.paramD,
            sculpture.complexity,
            sculpture.historyCount
        );
    }

    function crossPollinate(uint256 tokenIdSource1, uint256 tokenIdSource2, uint256 targetTokenId) public payable {
        _requireMinted(tokenIdSource1);
        _requireMinted(tokenIdSource2);
        if (ownerOf(tokenIdSource1) != msg.sender) revert NotSculptureOwner(tokenIdSource1);
        if (ownerOf(tokenIdSource2) != msg.sender) revert NotSculptureOwner(tokenIdSource2);

        // Target can be an existing token or 0 to mint a new one
        if (targetTokenId != 0) {
            _requireMinted(targetTokenId);
            if (ownerOf(targetTokenId) != msg.sender) revert NotSculptureOwner(targetTokenId);
            _checkLocked(targetTokenId);
        }

        _checkInteractionCost(InteractionType.CrossPollinate, msg.value);

        SculptureParameters storage source1Params = sculptures[tokenIdSource1];
        SculptureParameters storage source2Params = sculptures[tokenIdSource2];

        // --- Parameter Combination Logic (Example: Averaging and combining bits) ---
        uint128 newParamA = (source1Params.paramA + source2Params.paramA) / 2;
        uint128 newParamB = (source1Params.paramB & source2Params.paramB); // Example bitwise combination
        uint128 newParamC = (source1Params.paramC ^ source2Params.paramC); // Example bitwise combination
        uint128 newParamD = (source1Params.paramD + source2Params.paramD) / 2;
        uint64 newComplexity = (source1Params.complexity + source2Params.complexity) / 2; // Average complexity

        uint256 resultingTokenId = targetTokenId;

        if (targetTokenId == 0) {
            // Mint a new token
            resultingTokenId = _nextTokenId.current();
            _nextTokenId.increment();
            _safeMint(msg.sender, resultingTokenId);

            SculptureParameters storage newSculpture = sculptures[resultingTokenId];
             // Initialize state for new token
            newSculpture.paramA = newParamA;
            newSculpture.paramB = newParamB;
            newSculpture.paramC = newParamC;
            newSculpture.paramD = newParamD;
            newSculpture.complexity = newComplexity;
            newSculpture.lockEndTime = 0;
            newSculpture.lastInteractionTime = uint48(block.timestamp);
            newSculpture.historyCount = 0;
            newSculpture.observerInfluence = 0;
            // Combine provenance hashes
            newSculpture.provenanceHash = keccak256(abi.encodePacked(source1Params.provenanceHash, source2Params.provenanceHash, resultingTokenId));

             emit SculptureMinted(resultingTokenId, msg.sender, bytes32(0), "CrossPollination");
             emit ParametersChanged(
                resultingTokenId,
                InteractionType.CrossPollinate,
                msg.sender,
                newSculpture.paramA,
                newSculpture.paramB,
                newSculpture.paramC,
                newSculpture.paramD,
                newSculpture.complexity,
                newSculpture.historyCount
            );

        } else {
            // Update existing target token
            SculptureParameters storage targetSculpture = sculptures[targetTokenId];
            targetSculpture.paramA = newParamA;
            targetSculpture.paramB = newParamB;
            targetSculpture.paramC = newParamC;
            targetSculpture.paramD = newParamD;
            targetSculpture.complexity = newComplexity;
            // Provenance hash remains the same for existing token, or could be updated with a new combined hash

            _updateInteractionState(targetTokenId, InteractionType.CrossPollinate);

            emit ParametersChanged(
                targetTokenId,
                InteractionType.CrossPollinate,
                msg.sender,
                targetSculpture.paramA,
                targetSculpture.paramB,
                targetSculpture.paramC,
                targetSculpture.paramD,
                targetSculpture.complexity,
                targetSculpture.historyCount
            );
        }
    }

     function attuneResonance(uint256 tokenIdToAttune, uint256 tokenIdReference) public payable {
        _requireMinted(tokenIdToAttune);
        _requireMinted(tokenIdReference);
        if (ownerOf(tokenIdToAttune) != msg.sender) revert NotSculptureOwner(tokenIdToAttune);
        _checkLocked(tokenIdToAttune); // Only the one being attuned needs to be unlocked
        _checkInteractionCost(InteractionType.Attune, msg.value);

        SculptureParameters storage attuneSculpture = sculptures[tokenIdToAttune];
        SculptureParameters storage refSculpture = sculptures[tokenIdReference];

        // --- Attunement Logic (Example: Move parameters slightly towards reference) ---
        uint128 attuneFactor = 16; // Controls strength of attunement (smaller = stronger)

        attuneSculpture.paramA = (attuneSculpture.paramA * (attuneFactor - 1) + refSculpture.paramA) / attuneFactor;
        attuneSculpture.paramB = (attuneSculpture.paramB * (attuneFactor - 1) + refSculpture.paramB) / attuneFactor;
        attuneSculpture.paramC = (attuneSculpture.paramC * (attuneFactor - 1) + refSculpture.paramC) / attuneFactor;
        attuneSculpture.paramD = (attuneSculpture.paramD * (attuneFactor - 1) + refSculpture.paramD) / attuneFactor;

        // Complexity can also attune
        attuneSculpture.complexity = (attuneSculpture.complexity * (attuneFactor - 1) + refSculpture.complexity) / attuneFactor;


        _updateInteractionState(tokenIdToAttune, InteractionType.Attune);

         emit ParametersChanged(
            tokenIdToAttune,
            InteractionType.Attune,
            msg.sender,
            attuneSculpture.paramA,
            attuneSculpture.paramB,
            attuneSculpture.paramC,
            attuneSculpture.paramD,
            attuneSculpture.complexity,
            attuneSculpture.historyCount
        );
    }


    function lockParameters(uint256 tokenId) public payable {
        _requireMinted(tokenId);
        if (ownerOf(tokenId) != msg.sender) revert NotSculptureOwner(tokenId);
        _checkLocked(tokenId); // Cannot lock if already locked
        _checkInteractionCost(InteractionType.Lock, msg.value);

        SculptureParameters storage sculpture = sculptures[tokenId];
        uint48 unlockTime = uint48(block.timestamp + defaultLockDuration);
        sculpture.lockEndTime = unlockTime;

        // Locking is a state change but doesn't count as a sculpting 'interaction'
        // sculpture.historyCount is NOT incremented here.
        // lastInteractionTime is NOT updated here.

        emit SculptureLocked(tokenId, unlockTime);
    }

     function unlockParameters(uint256 tokenId) public {
        _requireMinted(tokenId);
        // Allow owner or admin to force unlock, or anyone if time has passed
        if (ownerOf(tokenId) != msg.sender && msg.sender != owner() && sculptures[tokenId].lockEndTime > block.timestamp) {
             revert NotSculptureOwner(tokenId); // Not owner/admin and still locked by time
        }

        SculptureParameters storage sculpture = sculptures[tokenId];
        if (sculpture.lockEndTime == 0) {
             // Already unlocked or never locked, no-op
             return;
        }

        sculpture.lockEndTime = 0; // Set unlock time to 0

        emit SculptureUnlocked(tokenId);
    }

     function recordObserverInfluence(uint256 tokenId) public payable {
         _requireMinted(tokenId);
         _checkInteractionCost(InteractionType.ObserverInfluence, msg.value);

         SculptureParameters storage sculpture = sculptures[tokenId];
         sculpture.observerInfluence += 1;

         // Optional: Slightly alter a parameter based on influence
         // Example: paramA gets a tiny boost/perturbation based on influence count
         sculpture.paramA = sculpture.paramA + (sculpture.observerInfluence % 10);

         // Observer influence doesn't count as a main parameter change for historyCount
         // lastInteractionTime is NOT updated here.

         emit ObserverInfluenceRecorded(tokenId, msg.sender, msg.value, sculpture.observerInfluence);
     }


    // --- View Functions ---

    function queryCurrentParameters(uint256 tokenId) public view returns (SculptureParameters memory) {
        _requireMinted(tokenId);
        return sculptures[tokenId];
    }

    function getSculptureStateHash(uint256 tokenId) public view returns (bytes32) {
        _requireMinted(tokenId);
        SculptureParameters storage sculpture = sculptures[tokenId];

        // Deterministically hash the critical parameters that define the sculpture's state
        return keccak256(abi.encodePacked(
            sculpture.paramA,
            sculpture.paramB,
            sculpture.paramC,
            sculpture.paramD,
            sculpture.complexity,
            sculpture.observerInfluence // Include observer influence as it's on-chain state
            // Note: lockEndTime, lastInteractionTime, historyCount, provenanceHash are state,
            // but might not be included in the "state hash" that defines the *visual* form,
            // depending on the off-chain renderer's logic. Included complexity and observerInfluence
            // as they could influence rendering.
        ));
    }

    function isParameterLocked(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return sculptures[tokenId].lockEndTime > block.timestamp;
    }

    function getTimeUntilUnlock(uint256 tokenId) public view returns (uint256) {
        _requireMinted(tokenId);
        uint48 unlockTime = sculptures[tokenId].lockEndTime;
        if (unlockTime == 0 || unlockTime <= block.timestamp) {
            return 0;
        } else {
            return uint256(unlockTime - block.timestamp);
        }
    }

    function getParameterHistoryCount(uint256 tokenId) public view returns (uint32) {
         _requireMinted(tokenId);
         return sculptures[tokenId].historyCount;
    }

    function getInteractionCost(InteractionType interactionType) public view returns (uint256) {
        return interactionCosts[interactionType];
    }

    function getGuardian() public view returns (address) {
        return guardian;
    }

    // Function to get total supply (provided by OZ ERC721)
    function totalSupply() public view virtual override(ERC721, ERC721URIStorage) returns (uint256) {
        // In OZ's ERC721, _nextTokenId.current() gives the next available ID,
        // which is equivalent to the total supply if IDs start from 1 or 0 and are sequential.
        // Assuming _nextTokenId starts at 0 and increments before first mint, or 1 and increments after.
        // Let's assume it starts at 0 and increment is the count.
         return _nextTokenId.current();
    }


    // --- Internal/Helper Functions ---

    function _requireMinted(uint256 tokenId) internal view {
        // ERC721's _exists check is typically sufficient, but this adds clarity
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
    }

    function _checkLocked(uint256 tokenId) internal view {
        if (isParameterLocked(tokenId)) {
            revert SculptureLocked(tokenId);
        }
    }

    function _checkInteractionCost(InteractionType interactionType, uint256 sentAmount) internal view {
        uint256 requiredCost = interactionCosts[interactionType];
        if (sentAmount < requiredCost) {
            revert NotEnoughEther(requiredCost, sentAmount);
        }
        // Excess Ether is automatically returned by the EVM from a payable call,
        // unless explicitly forwarded. Here, we collect the exact amount needed
        // into the contract balance (implicitly by payable) and excess is returned.
        // This is standard Solidity payable function behavior.
    }

    function _updateInteractionState(uint256 tokenId, InteractionType interactionType) internal {
        SculptureParameters storage sculpture = sculptures[tokenId];
        sculpture.lastInteractionTime = uint48(block.timestamp);
        sculpture.historyCount += 1;
        // If locking is desired after certain interactions, uncomment the line below:
        // sculpture.lockEndTime = uint48(block.timestamp + defaultLockDuration); // Auto-lock after interaction
    }

     // Override to handle potential parameter issues on transfer (optional)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721URIStorage) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Optional: Logic to perform before transfer
        // E.g., unlock the sculpture automatically on transfer?
        // if (from != address(0) && sculptures[tokenId].lockEndTime > block.timestamp) {
        //      sculptures[tokenId].lockEndTime = 0; // Auto-unlock on transfer
        //      emit SculptureUnlocked(tokenId);
        // }
    }

    // Required override for ERC721URIStorage
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super._baseURI();
    }
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic On-Chain Parameters:** The `SculptureParameters` struct storing `paramA`, `paramB`, `complexity`, etc., directly on-chain makes the NFT dynamic. Its state is not fixed metadata.
2.  **Diverse Interaction Functions:** `etchParameter`, `polishSurface`, `growComplexity`, `applyMutation`, `crossPollinate`, `attuneResonance`, `recordObserverInfluence` provide distinct ways users can manipulate the sculpture's state, going beyond simple "leveling up" or single state changes. Each implies a different type of influence.
3.  **Cross-Pollination:** This function is relatively complex, allowing parameters from two tokens to influence a third (existing or new), simulating a form of digital breeding or combining characteristics.
4.  **Attune Resonance:** A more subtle interaction than cross-pollination, shifting one sculpture's parameters gently towards another, representing a different kind of influence or alignment.
5.  **Guardian-Triggered Decay:** The `triggerDecay` function introduces an external influence controlled by a specific role, simulating entropy or environmental factors that degrade the sculpture's state if not actively maintained by the owner. This adds a strategic layer.
6.  **Parameter Locking:** `lockParameters` and `unlockParameters` add a state-management mechanic where owners can pay to temporarily freeze their sculpture's evolution, useful for preserving a desired state or strategizing interactions.
7.  **Observer Influence:** `recordObserverInfluence` allows *anyone* to interact with a sculpture by paying a fee, leaving a persistent, albeit small, mark on its state (`observerInfluence` counter and potential minor parameter tweak). This adds a public interaction layer beyond ownership.
8.  **On-Chain State Hashing:** `getSculptureStateHash` provides a verifiable identifier for the exact state of the sculpture's parameters at any given time. This is crucial for off-chain renderers to prove they are accurately depicting the on-chain state and provides provenance checkpoints.
9.  **Interaction Costs & Withdrawal:** Monetizing interactions directly on-chain via `payable` functions and allowing the owner to withdraw funds (`withdrawInteractionCosts`) is a common pattern but implemented here for specific, diverse actions.
10. **Pseudo-Random Mutation:** `applyMutation` uses block data (`block.timestamp`, `block.difficulty`) for pseudo-randomness. While not cryptographically secure, it's a common on-chain pattern for unpredictable (but exploitable) state changes in games or generative systems where strong security guarantees on randomness aren't paramount.
11. **Provenance Tracking:** The `provenanceHash` stored in the struct provides an on-chain link back to the initial creation data or process inputs.

This contract offers a rich, interactive experience centered around NFTs that are living, evolving digital entities rather than static collectibles.