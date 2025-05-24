Okay, let's create a smart contract called `QuantumLeapNFT`. This contract will manage NFTs that can "Quantum Leap" between different dimensions and states. The concept is an evolving NFT where its properties change based on interactions and time.

It will incorporate:
1.  **Dynamic State:** NFTs have dimensions and states within dimensions.
2.  **Evolution Mechanic:** A function (`attemptQuantumLeap`) that allows owners to try and change the NFT's dimension/state based on conditions (energy, cooldown) and a degree of pseudo-randomness.
3.  **Resource Management:** NFTs have "Energy" that is required for leaps and replenishes over time.
4.  **Temporal Echoes:** A state variable tracking failed leap attempts or unstable states, potentially influencing future outcomes.
5.  **Dynamic Metadata:** The `tokenURI` will change based on the NFT's current dimension and state.
6.  **Admin Configurable:** Key parameters of the leap mechanic are adjustable by an admin.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simple admin

// --- OUTLINE AND FUNCTION SUMMARY ---
/*
Contract: QuantumLeapNFT (ERC721Enumerable, ERC721URIStorage)

Core Concept:
An ERC721 NFT where each token represents an entity that can "Quantum Leap" between different
dimensions and states. These states are dynamic and can change based on owner actions
(attempting a leap) and time. Key mechanics include:
- Dimensions and States: Each token has a current dimension (uint8) and state (uint8).
- Energy: A resource required to attempt leaps, which replenishes over time.
- Temporal Echoes: A counter reflecting past instability (e.g., failed leaps), potentially affecting future outcomes.
- Quantum Leap: A function where an owner can try to advance their token's dimension/state,
  consuming energy and being subject to a cooldown. The outcome is influenced by the
  current state, energy, echoes, and pseudo-randomness.
- Dynamic Metadata: The tokenURI changes based on the token's current dimension and state.

Inheritance:
- ERC721: Standard NFT functionality.
- ERC721Enumerable: Allows listing all tokens and tokens owned by an address.
- ERC721URIStorage: Allows storing token URIs per token (though we'll override tokenURI).
- Ownable: Simple administration for configuring leap parameters.

State Variables:
- _tokenIdCounter: Tracks the next available token ID.
- _tokenData: Maps tokenId to QuantumLeapData struct.
- _leapCooldown: Minimum time between leap attempts (seconds).
- _energyPerLeapAttempt: Energy consumed per attempt.
- _energyReplenishRate: Energy gained per second.
- _minEnergyForLeap: Minimum energy required to attempt a leap.
- _maxDimension: The highest achievable dimension.
- _baseURI: Base for constructing dynamic metadata URIs.

Struct:
- QuantumLeapData: Holds dynamic data for each token (dimension, state, energy, echoes, timestamps, rarity, etc.).

Events:
- QuantumLeapAttempted: Emitted when a leap is attempted.
- QuantumLeapPerformed: Emitted when a leap successfully changes dimension/state.
- EnergyReplenished: Emitted when token energy is replenished.
- TraitEvolved: Emitted when a token's inherent traits (like rarity) change due to evolution.
- AdminConfigurationUpdated: Emitted when admin parameters change.

Functions (>= 20 required):

Standard ERC721/Enumerable/URIStorage (9+ functions):
1.  constructor: Initializes the contract with name and symbol, sets initial admin.
2.  supportsInterface: Standard ERC165 check.
3.  balanceOf: Returns count of tokens owned by an address.
4.  ownerOf: Returns owner of a specific token.
5.  approve: Approves an address to transfer a token.
6.  getApproved: Returns the approved address for a token.
7.  setApprovalForAll: Approves/disapproves an operator for all tokens.
8.  isApprovedForAll: Checks if an address is an approved operator.
9.  transferFrom: Transfers a token using approval/operator.
10. safeTransferFrom (overloaded): Safely transfers a token.
11. safeTransferFrom (overloaded): Safely transfers a token with data.
12. tokenOfOwnerByIndex: Returns token ID by index for an owner (Enumerable).
13. tokenByIndex: Returns token ID by global index (Enumerable).
14. tokenURI: Returns the metadata URI for a token (Dynamic based on state).

Minting (1 function):
15. mintGenesis: Mints initial tokens (admin only). Initializes token data.

Core Evolution Mechanics (4 functions):
16. attemptQuantumLeap: Initiates a leap attempt for a token. Checks eligibility, consumes energy, uses pseudo-randomness, updates state, records timestamp, emits events.
17. replenishEnergy: Calculates and adds energy based on time elapsed since last calculation.
18. checkLeapEligibility: View function to check if a token *can* attempt a leap (cooldown, min energy).
19. simulateLeapOutcome: View function to simulate a potential leap outcome based on current state and block data (non-deterministic).

Querying Token State/Data (8+ functions):
20. getTokenData: Retrieves the full QuantumLeapData struct for a token.
21. getDimension: Retrieves a token's current dimension.
22. getState: Retrieves a token's current state within its dimension.
23. getEnergy: Retrieves a token's current energy level.
24. getTemporalEchoes: Retrieves a token's temporal echo count.
25. getRarityScore: Retrieves a token's current rarity score.
26. getTimeSinceLastLeapAttempt: Calculates time elapsed since the last leap attempt.
27. getTimeSinceCreation: Calculates time elapsed since token creation.

Admin Configuration (7 functions):
28. setLeapCooldown: Sets the minimum time between leap attempts.
29. setEnergyPerLeapAttempt: Sets the energy consumed per leap attempt.
30. setEnergyReplenishRate: Sets the energy gained per second.
31. setMinEnergyForLeap: Sets the minimum energy required for a leap attempt.
32. setMaxDimension: Sets the maximum dimension a token can reach.
33. setBaseURI: Sets the base URI for token metadata.
34. transferOwnership: Transfers admin rights (from Ownable).

Internal Helpers:
- _generateRandomNumber: Pseudo-random number generation (basic and insecure for high-value outcomes).
- _calculateEnergy: Calculates total energy accumulated since last calculation.
- _updateEnergyCalculationTimestamp: Updates the timestamp used for energy calculation.
- _evolveTraitsInternal: Internal logic to update traits like rarity based on new state.
- _updateTokenURI: Updates the metadata URI (or ensures the dynamic tokenURI function works correctly).

Total Functions = 14 (ERC721) + 1 (Minting) + 4 (Evolution) + 8 (Querying) + 7 (Admin) = 34+ functions.
*/

// --- ERROR DEFINITIONS ---
error NotAdmin();
error InvalidTokenId();
error LeapNotEligible();
error InsufficientEnergy();
error MaxDimensionReached(uint8 currentDimension);
error InvalidDimensionOrState();

contract QuantumLeapNFT is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    struct QuantumLeapData {
        uint8 dimension;               // The current dimension the token is in (0 to maxDimension)
        uint8 state;                   // The state within the current dimension
        uint16 energy;                 // Energy level for attempts
        uint8 temporalEchoes;          // Counter for instabilities/failed attempts
        uint48 creationTimestamp;     // Timestamp of token creation
        uint48 lastLeapAttemptTimestamp; // Timestamp of the last leap attempt
        uint48 lastEnergyCalculationTimestamp; // Timestamp when energy was last calculated/used
        uint16 rarityScore;            // Base rarity, could evolve
        // Add more traits here if needed, e.g., uint16 strength, uint16 speed;
    }

    mapping(uint256 => QuantumLeapData) private _tokenData;

    // --- Admin Configurable Parameters ---
    uint32 public leapCooldown = 1 days; // Minimum time between leap attempts in seconds
    uint16 public energyPerLeapAttempt = 100; // Energy cost per leap attempt
    uint16 public energyReplenishRate = 10; // Energy gained per second
    uint16 public minEnergyForLeap = 200; // Minimum energy needed for a leap attempt
    uint8 public maxDimension = 10; // Maximum dimension achievable

    // --- Constructor ---
    constructor(string memory name, string memory symbol, string memory baseUri)
        ERC721(name, symbol)
        Ownable(msg.sender) // Sets the deployer as the initial admin
    {
        _baseURI = baseUri;
        // Set genesisTimestamp? Not strictly needed if creationTimestamp is per token
        // genesisTimestamp = uint48(block.timestamp);
    }

    // --- ERC721 Overrides & Standard Functions ---

    // Required for ERC721URIStorage and Enumerable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Override _update and _increaseBalance for ERC721Enumerable
    // Override _baseURI for ERC721URIStorage (using the internal variable _baseURI)

    // Standard ERC721 functions (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll)
    // are provided by inherited contracts and don't need explicit code here unless modified.

    // Transfer overrides to ensure token data remains with the token
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // No need to explicitly move _tokenData here, it's mapped by tokenId
    }

    function _safeMint(address to, uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._safeMint(to, tokenId);
        // Initialize QuantumLeapData upon minting
        _tokenData[tokenId] = QuantumLeapData({
            dimension: 0,
            state: 0,
            energy: 1000, // Starting energy
            temporalEchoes: 0,
            creationTimestamp: uint48(block.timestamp),
            lastLeapAttemptTimestamp: 0, // 0 indicates no attempt yet
            lastEnergyCalculationTimestamp: uint48(block.timestamp), // Start energy calculation now
            rarityScore: 100 // Base rarity
        });
        emit TraitEvolved(tokenId, _tokenData[tokenId].rarityScore);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token"); // Check existence first
        delete _tokenData[tokenId]; // Delete the associated data
        super._burn(tokenId);
    }

    // Dynamic tokenURI based on current state
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        QuantumLeapData storage data = _tokenData[tokenId];
        // Example: baseURI/dimension_state_tokenid.json
        // Or you might point to an API that generates metadata based on dimension, state, echoes etc.
        string memory base = _baseURI;
        return string(abi.encodePacked(base, "/", uint256(data.dimension).toString(), "_", uint256(data.state).toString(), "_", tokenId.toString(), ".json"));
        // If using ERC721URIStorage's _tokenURIs mapping for custom URIs, you'd check that first:
        // string memory uri = super.tokenURI(tokenId);
        // return bytes(uri).length > 0 ? uri : string(abi.encodePacked(base, ...));
    }

    // --- Minting Function ---

    /// @notice Mints genesis tokens (admin only).
    /// @param to The address to mint to.
    /// @param count The number of tokens to mint.
    function mintGenesis(address to, uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            uint256 newItemId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, newItemId);
        }
    }

    // --- Core Evolution Mechanics ---

    /// @notice Attempts a Quantum Leap for a specified token.
    /// Requires the token to be owned by the caller, sufficient energy, and pass the cooldown.
    /// Outcome is influenced by current state, energy, echoes, and pseudo-randomness.
    /// @param tokenId The ID of the token to attempt a leap with.
    function attemptQuantumLeap(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "QuantumLeapNFT: Caller is not the owner");

        QuantumLeapData storage data = _tokenData[tokenId];
        if (data.dimension >= maxDimension) {
             revert MaxDimensionReached(data.dimension);
        }

        // Ensure energy is updated before checking eligibility
        replenishEnergy(tokenId);

        if (block.timestamp < data.lastLeapAttemptTimestamp + leapCooldown || data.energy < minEnergyForLeap) {
             revert LeapNotEligible();
        }
         if (data.energy < energyPerLeapAttempt) {
             revert InsufficientEnergy();
         }

        emit QuantumLeapAttempted(tokenId, data.dimension, data.state, data.energy);

        // Consume energy for the attempt
        data.energy = data.energy.sub(energyPerLeapAttempt);
        // Update energy timestamp as energy was just used
        _updateEnergyCalculationTimestamp(tokenId);

        data.lastLeapAttemptTimestamp = uint48(block.timestamp);

        // --- Pseudo-Random Outcome Calculation ---
        // WARNING: This is NOT cryptographically secure and is vulnerable to miner front-running.
        // For production, use Chainlink VRF or a similar decentralized oracle for true randomness.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, data.temporalEchoes, data.energy)));
        uint256 outcome = _generateRandomNumber(randomSeed, 10000); // Outcome between 0 and 9999

        // Example Logic:
        // - Higher energy increases chance of success
        // - Higher echoes increase chance of instability (bad outcome or state change)
        // - Current dimension/state affects possible outcomes
        uint8 oldDimension = data.dimension;
        uint8 oldState = data.state;
        bool leapSuccess = false;

        if (outcome < 4000 + data.energy / 20) { // 40% base success chance + bonus from energy
            // Success: Advance dimension or state within dimension
            if (data.state < 255) { // Try to advance state first
                data.state++;
                leapSuccess = true;
            } else if (data.dimension < maxDimension) { // Max state, try advancing dimension
                data.dimension++;
                data.state = 0; // Reset state on dimension leap
                leapSuccess = true;
            } else {
                // Already at max dimension and max state, maybe a special outcome?
                // For now, just stay put but still consume energy/cooldown
            }

        } else if (outcome < 7000 + data.temporalEchoes * 50) { // 30% base chance of instability + bonus from echoes
            // Instability: State changes randomly within dimension, maybe add echoes
            data.temporalEchoes++;
            uint256 stateChange = _generateRandomNumber(randomSeed.add(1), 256);
            data.state = uint8(stateChange);
            // Maybe decrease rarity or energy slightly?
            if (data.rarityScore > 50) data.rarityScore = data.rarityScore.sub(10);
             emit TraitEvolved(tokenId, data.rarityScore);

        } else { // 30% base chance of failed attempt
            // Failure: Stay in current state/dimension, maybe add echoes
             data.temporalEchoes++;
             // No state/dimension change
        }

        if (leapSuccess) {
            emit QuantumLeapPerformed(tokenId, oldDimension, oldState, data.dimension, data.state);
            // Evolve other traits based on the new state
            _evolveTraitsInternal(tokenId, data.dimension, data.state);
        }
        // Note: Metadata URI doesn't need explicit update here as tokenURI is dynamic.
    }

    /// @notice Replenishes energy for a specific token based on elapsed time.
    /// Can be called by anyone, but only affects the token's energy.
    /// @param tokenId The ID of the token to replenish energy for.
    function replenishEnergy(uint256 tokenId) public {
        require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
        QuantumLeapData storage data = _tokenData[tokenId];

        uint48 currentTime = uint48(block.timestamp);
        uint48 timeElapsed = currentTime.sub(data.lastEnergyCalculationTimestamp);

        if (timeElapsed > 0) {
            uint256 energyGained = uint256(timeElapsed).mul(energyReplenishRate);
            data.energy = data.energy.add(uint16(energyGained));
            _updateEnergyCalculationTimestamp(tokenId);
            emit EnergyReplenished(tokenId, data.energy);
        }
    }

    /// @notice Checks if a token is eligible to attempt a Quantum Leap.
    /// Checks cooldown and minimum energy requirements.
    /// @param tokenId The ID of the token to check.
    /// @return isEligible True if eligible, false otherwise.
    function checkLeapEligibility(uint256 tokenId) public view returns (bool isEligible) {
         require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
         QuantumLeapData storage data = _tokenData[tokenId];

         // Check energy *after* potential replenishment calculation (simulate replenishment)
         uint48 currentTime = uint48(block.timestamp);
         uint48 timeElapsed = currentTime.sub(data.lastEnergyCalculationTimestamp);
         uint16 currentEnergy = data.energy.add(uint16(uint256(timeElapsed).mul(energyReplenishRate))); // Calculate potential energy

         return (block.timestamp >= data.lastLeapAttemptTimestamp + leapCooldown && currentEnergy >= minEnergyForLeap);
    }

    /// @notice Simulates a potential leap outcome based on the token's current state and block data.
    /// Note: This is a view function and does not change state. The outcome is based on current block data,
    /// which will be different during a real transaction, so this is for estimation only.
    /// @param tokenId The ID of the token to simulate for.
    /// @return predictedDimension The dimension in the simulated outcome.
    /// @return predictedState The state in the simulated outcome.
    /// @return predictedEchoes The temporal echoes in the simulated outcome.
    /// @return simulatedEnergyCost The energy that *would* be consumed.
    function simulateLeapOutcome(uint256 tokenId)
        public
        view
        returns (
            uint8 predictedDimension,
            uint8 predictedState,
            uint8 predictedEchoes,
            uint16 simulatedEnergyCost
        )
    {
        require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
        QuantumLeapData storage data = _tokenData[tokenId];

        if (data.dimension >= maxDimension) {
             return (data.dimension, data.state, data.temporalEchoes, energyPerLeapAttempt); // No change predicted if maxed
        }

        // Use current block data for simulation randomness
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, tokenId, data.temporalEchoes, data.energy)));
        uint256 outcome = _generateRandomNumber(randomSeed, 10000); // Outcome between 0 and 9999

        uint8 simDimension = data.dimension;
        uint8 simState = data.state;
        uint8 simEchoes = data.temporalEchoes;

        if (outcome < 4000 + data.energy / 20) {
             // Simulated Success
            if (simState < 255) {
                simState++;
            } else if (simDimension < maxDimension) {
                simDimension++;
                simState = 0;
            }
        } else if (outcome < 7000 + data.temporalEchoes * 50) {
             // Simulated Instability
            simEchoes++;
            uint256 stateChange = _generateRandomNumber(randomSeed.add(1), 256);
            simState = uint8(stateChange);
        } else {
             // Simulated Failure
            simEchoes++;
            // No state/dimension change
        }

        return (simDimension, simState, simEchoes, energyPerLeapAttempt);
    }


    // --- Querying Token State/Data ---

    /// @notice Retrieves the full QuantumLeapData struct for a token.
    /// @param tokenId The ID of the token.
    /// @return The QuantumLeapData struct.
    function getTokenData(uint256 tokenId) public view returns (QuantumLeapData memory) {
         require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
         return _tokenData[tokenId];
    }

    /// @notice Retrieves a token's current dimension.
    /// @param tokenId The ID of the token.
    /// @return The dimension (0 to maxDimension).
    function getDimension(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
         return _tokenData[tokenId].dimension;
    }

    /// @notice Retrieves a token's current state within its dimension.
    /// @param tokenId The ID of the token.
    /// @return The state (0 to 255).
    function getState(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
         return _tokenData[tokenId].state;
    }

    /// @notice Retrieves a token's current energy level (includes potential replenishment).
    /// @param tokenId The ID of the token.
    /// @return The energy level.
    function getEnergy(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
        QuantumLeapData storage data = _tokenData[tokenId];

        uint48 currentTime = uint48(block.timestamp);
        uint48 timeElapsed = currentTime.sub(data.lastEnergyCalculationTimestamp);
        return data.energy.add(uint16(uint256(timeElapsed).mul(energyReplenishRate)));
    }

    /// @notice Retrieves a token's temporal echo count.
    /// @param tokenId The ID of the token.
    /// @return The echo count.
    function getTemporalEchoes(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
        return _tokenData[tokenId].temporalEchoes;
    }

     /// @notice Retrieves a token's current rarity score.
    /// @param tokenId The ID of the token.
    /// @return The rarity score.
    function getRarityScore(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
        return _tokenData[tokenId].rarityScore;
    }

     /// @notice Calculates time elapsed since the token's last leap attempt.
     /// @param tokenId The ID of the token.
     /// @return Time elapsed in seconds.
     function getTimeSinceLastLeapAttempt(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
         uint48 lastAttempt = _tokenData[tokenId].lastLeapAttemptTimestamp;
         if (lastAttempt == 0) return type(uint256).max; // Indicate no attempt has been made
         return block.timestamp.sub(lastAttempt);
     }

     /// @notice Calculates time elapsed since the token was created.
     /// @param tokenId The ID of the token.
     /// @return Time elapsed in seconds.
     function getTimeSinceCreation(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QuantumLeapNFT: Token does not exist");
         return block.timestamp.sub(_tokenData[tokenId].creationTimestamp);
     }


    // --- Admin Configuration Functions ---

    /// @notice Sets the minimum time in seconds required between leap attempts.
    /// @param newLeapCooldown The new cooldown duration.
    function setLeapCooldown(uint32 newLeapCooldown) public onlyOwner {
        leapCooldown = newLeapCooldown;
        emit AdminConfigurationUpdated("leapCooldown", uint256(newLeapCooldown));
    }

    /// @notice Sets the energy consumed per leap attempt.
    /// @param newEnergyCost The new energy cost.
    function setEnergyPerLeapAttempt(uint16 newEnergyCost) public onlyOwner {
        energyPerLeapAttempt = newEnergyCost;
        emit AdminConfigurationUpdated("energyPerLeapAttempt", uint256(newEnergyCost));
    }

     /// @notice Sets the energy replenishment rate per second.
     /// @param newReplenishRate The new rate.
    function setEnergyReplenishRate(uint16 newReplenishRate) public onlyOwner {
        energyReplenishRate = newReplenishRate;
        emit AdminConfigurationUpdated("energyReplenishRate", uint256(newReplenishRate));
    }

     /// @notice Sets the minimum energy required to attempt a leap.
     /// @param newMinEnergy The new minimum energy.
    function setMinEnergyForLeap(uint16 newMinEnergy) public onlyOwner {
        minEnergyForLeap = newMinEnergy;
        emit AdminConfigurationUpdated("minEnergyForLeap", uint256(newMinEnergy));
    }

    /// @notice Sets the maximum dimension a token can reach.
    /// @param newMaxDimension The new maximum dimension.
    function setMaxDimension(uint8 newMaxDimension) public onlyOwner {
        maxDimension = newMaxDimension;
        emit AdminConfigurationUpdated("maxDimension", uint256(newMaxDimension));
    }

     /// @notice Sets the base URI for token metadata.
     /// @param newBaseURI The new base URI string.
     function setBaseURI(string calldata newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
        emit AdminConfigurationUpdated("baseURI", 0); // No numerical value for string change
     }

    // transferOwnership function is provided by Ownable

    // --- Internal Helper Functions ---

    /// @dev Generates a pseudo-random number based on block data and seed.
    /// WARNING: This is NOT cryptographically secure.
    /// @param seed Additional seed for randomness.
    /// @param max The upper bound (exclusive) for the random number.
    /// @return A pseudo-random number between 0 and max-1.
    function _generateRandomNumber(uint256 seed, uint256 max) internal view returns (uint256) {
        // Using block variables + seed for pseudo-randomness.
        // This is PREDICTABLE by miners. Do NOT use for high-value random outcomes
        // where security is critical (e.g., lottery wins, significant trait changes).
        // It's acceptable for illustrative purposes or low-stakes outcomes.
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tx.origin, seed))) % max;
    }

    /// @dev Updates the timestamp used for calculating energy gain.
    /// Should be called whenever energy is gained or spent.
    /// @param tokenId The ID of the token.
    function _updateEnergyCalculationTimestamp(uint256 tokenId) internal {
        _tokenData[tokenId].lastEnergyCalculationTimestamp = uint48(block.timestamp);
    }

    /// @dev Internal function to evolve other traits based on dimension and state changes.
    /// @param tokenId The ID of the token.
    /// @param dimension The new dimension.
    /// @param state The new state.
    function _evolveTraitsInternal(uint256 tokenId, uint8 dimension, uint8 state) internal {
        QuantumLeapData storage data = _tokenData[tokenId];
        uint16 oldRarity = data.rarityScore;

        // Example trait evolution logic:
        // Rarity increases with dimension and specific states
        uint16 newRarity = 100; // Base rarity
        newRarity = newRarity.add(dimension.mul(10)); // Add 10 rarity per dimension
        if (state == 255) newRarity = newRarity.add(50); // Bonus for max state
        if (data.temporalEchoes > 0) newRarity = newRarity.sub(uint16(data.temporalEchoes).mul(5)); // Penalty for echoes (capped at min 0?)
        if (newRarity < 50) newRarity = 50; // Minimum rarity floor

        data.rarityScore = newRarity;

        if (data.rarityScore != oldRarity) {
             emit TraitEvolved(tokenId, data.rarityScore);
        }

        // Could also trigger metadata updates here if not purely dynamic in tokenURI
        // For this contract, tokenURI is already dynamic based on dimension/state.
    }

    // --- Events ---

    event QuantumLeapAttempted(uint256 indexed tokenId, uint8 currentDimension, uint8 currentState, uint16 currentEnergy);
    event QuantumLeapPerformed(uint256 indexed tokenId, uint8 oldDimension, uint8 oldState, uint8 newDimension, uint8 newState);
    event EnergyReplenished(uint256 indexed tokenId, uint16 newEnergy);
    event TraitEvolved(uint256 indexed tokenId, uint16 newRarityScore); // Example event for trait changes
    event AdminConfigurationUpdated(string paramName, uint256 newValue); // Generic event for admin updates

    // --- Utility: uint to string ---
    // Helper function needed for tokenURI construction. Using OpenZeppelin's Strings is also an option.
    // Implementing a simple one here for self-containment if not using OZ Strings.
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }

}
```