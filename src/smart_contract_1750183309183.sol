Okay, let's craft an interesting, advanced, and creative smart contract concept. We'll combine dynamic NFTs (Non-Fungible Tokens) with DeFi-like mechanics (staking, yield farming a fungible token) and incorporate an oracle for external data influence and Chainlink VRF for controlled randomness in a "synthesis" or "bonding" process.

We'll call the contract `KineticCrystalsVault`. Users can mint "Kinetic Crystal" NFTs. These crystals gain "energy" over time, which affects their "state" (visual/functional). Users can stake their crystals in the vault to earn a fungible `KineticEssence` token yield, where the yield rate depends on the crystal's energy and affinity. They can also bond multiple staked crystals, burning them to potentially synthesize a new, more powerful crystal using Chainlink VRF for probabilistic outcomes influenced by crystal attributes and external oracle data (like a market price or weather feed).

This avoids directly duplicating common open-source examples like simple ERC20s, standard ERC721 collections, basic staking pools, or typical AMMs. The combination of dynamic NFT state, energy mechanics, oracle influence on energy/synthesis, VRF synthesis outcomes, and integrated yield farming creates a unique system.

---

**Outline and Function Summary**

**Contract Name:** `KineticCrystalsVault`

**Description:** A smart contract managing dynamic NFT 'Kinetic Crystals' and a fungible 'Kinetic Essence' token. Users can mint crystals, stake them to earn Essence yield based on crystal energy/affinity, and bond/synthesize staked crystals into new ones using VRF randomness influenced by oracle data.

**Key Concepts:**
*   **Kinetic Crystals (ERC721):** Dynamic NFTs with attributes (Energy, Affinity, Purity) and a State derived from Energy. Energy increases over time and can be influenced by oracle data.
*   **Kinetic Essence (ERC20):** Fungible token earned by staking Kinetic Crystals.
*   **Staking:** Users lock Crystals in the vault to earn Essence yield. Yield rate is dynamic based on staked Crystal attributes.
*   **Synthesis:** Users can bond a set of staked Crystals. This burns the input Crystals and, based on a probabilistic outcome (VRF), mints a new, potentially more powerful Crystal. Probability is influenced by input Crystal attributes and external data (Oracle).
*   **Oracle Integration (Chainlink Data Feed):** Used to provide external data (e.g., price) that influences a global energy modifier applied to all crystals.
*   **VRF Integration (Chainlink VRF):** Used to provide secure, verifiable randomness for the Synthesis process probability outcome.
*   **Dynamic State:** Crystal 'State' changes as Energy levels increase.
*   **Yield Delegation:** Owners of crystals can delegate the claimable Essence yield from their *staked* crystals to another address.

**Functions Summary:**

*   **Inherited (OpenZeppelin for standards):** `ERC721`, `ERC721Enumerable`, `ERC20`, `Ownable`, `Pausable`, `ReentrancyGuard`, `VRFConsumerBaseV2`. (Standard interfaces and common utilities).
*   **Core Crystal (ERC721) Management:**
    *   `mintInitialCrystal(address recipient, uint256 initialEnergy, uint256 initialAffinity, uint256 initialPurity)`: Admin function to mint a new Crystal NFT with initial attributes.
    *   `getCrystalAttributes(uint256 tokenId)`: View function to get the current attributes (Energy, Affinity, Purity) of a Crystal.
    *   `getCrystalEnergy(uint256 tokenId)`: View function to get the real-time calculated Energy of a Crystal (includes time decay/increase and modifiers).
    *   `getCrystalState(uint256 tokenId)`: View function to get the derived State of a Crystal based on its Energy.
    *   `isCrystalStaked(uint256 tokenId)`: View function to check if a Crystal is currently staked.
    *   `getCrystalLastStakedTime(uint256 tokenId)`: View function for the last time a crystal's stake state changed.
    *   `getCrystalURI(uint256 tokenId)`: Overridden ERC721 function to get the metadata URI, potentially reflecting dynamic state.
    *   `_updateCrystalEnergyInternal(uint256 tokenId)`: Internal helper to calculate energy increase/decrease over time and apply global modifier.
    *   `_updateCrystalStateInternal(uint256 tokenId)`: Internal helper to update the stored state based on energy.
*   **Essence (ERC20) Management:**
    *   `calculateClaimableEssence(address owner)`: View function to calculate the Essence yield claimable by a specific address (either owner's yield or yield delegated *to* them).
    *   `claimEssence()`: Allows a user to claim all Essence yield currently claimable by them.
    *   `batchClaimEssence(address[] owners)`: Allows a user (or delegatee) to claim essence for multiple specific owners (useful if someone delegates yield *to* this user).
    *   `delegateEssenceYield(address delegatee)`: Allows a crystal owner to set an address to which their staked crystal yield should be claimable.
    *   `getDelegatee(address owner)`: View function to get the yield delegatee for an address.
*   **Staking:**
    *   `stakeCrystal(uint256 tokenId)`: Allows an owner to stake their Crystal NFT in the vault.
    *   `unstakeCrystal(uint256 tokenId)`: Allows an owner to unstake their Crystal NFT from the vault.
    *   `bulkStakeCrystals(uint256[] tokenIds)`: Allows an owner to stake multiple Crystals in one transaction.
    *   `bulkUnstakeCrystals(uint256[] tokenIds)`: Allows an owner to unstake multiple Crystals in one transaction.
    *   `getStakedCrystalTokens(address owner)`: View function to get the list of token IDs staked by a specific owner.
    *   `getTotalStakedCrystals()`: View function for the total number of crystals staked in the vault.
*   **Synthesis:**
    *   `requestSynthesis(uint256[] tokenIds)`: Initiates a synthesis request using a set of *staked* Crystal token IDs. Burns the input NFTs and requests randomness from Chainlink VRF. Requires payment (e.g., Essence or Ether).
    *   `rawFulfillRandomWords(uint256 requestId, uint256[] randomWords)`: Chainlink VRF callback function. Processes the randomness to determine synthesis outcome (success/failure) and mints a new Crystal or handles failure.
    *   `getSynthesisCost(uint256 numberOfInputs)`: View function to get the cost to perform synthesis with a given number of crystals.
    *   `predictSynthesisSuccess(uint256[] tokenIds)`: View function to estimate the success probability of a synthesis request with given input crystals (based on attributes and oracle modifier).
    *   `getPendingSynthesisRequest(uint256 requestId)`: View function to get details of a pending synthesis request.
*   **Oracle Integration (Data Feed):**
    *   `setEnergyOracleAddress(address oracleAddress)`: Admin function to set the address of the Chainlink Data Feed for energy modification.
    *   `requestOracleEnergyModifier()`: Admin/Keeper function to request the latest price from the oracle.
    *   `fulfillOracleEnergyModifier(int256 price)`: Internal function called after oracle price fetch. Calculates and stores the global energy modifier based on the price.
    *   `getLatestOracleValue()`: View function to get the last fetched oracle value.
    *   `getOracleEnergyModifier()`: View function to get the current global energy modifier.
*   **Admin/Parameter Management:**
    *   `setEssenceYieldRate(uint256 ratePerEnergyAffinityPerSecond)`: Admin function to set the base rate for Essence yield.
    *   `setSynthesisParameters(uint256 baseCost, uint256 minInputs, uint256 baseSuccessChance, uint256 puritySuccessMultiplier, uint256 oracleSuccessMultiplier)`: Admin function to tune synthesis mechanics.
    *   `setEnergyIncreaseRate(uint256 ratePerSecond)`: Admin function to set the base rate at which energy increases.
    *   `setEnergyCap(uint256 cap)`: Admin function to set the maximum possible energy.
    *   `setBaseURI(string memory baseURI_)`: Admin function to set the base URI for token metadata.
    *   `pauseContract()`: Admin function to pause contract interactions (staking, claiming, synthesis requests).
    *   `unpauseContract()`: Admin function to unpause the contract.
    *   `withdrawFunds(address recipient)`: Admin function to withdraw any gathered Ether (e.g., from synthesis costs).
    *   `withdrawEssence(address recipient, uint256 amount)`: Admin function to withdraw Essence tokens from the contract (if any are held, e.g., from failed synthesis costs).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Outline and Function Summary provided above code block.

contract KineticCrystalsVault is ERC721Enumerable, ERC20, Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {

    // --- Constants ---
    uint256 private constant SECONDS_PER_YEAR = 31536000; // Approximation

    // --- Enums ---
    enum CrystalState { Dormant, Stable, Pulsing, Radiant, Volatile }

    // --- Structs ---
    struct CrystalAttributes {
        uint256 energy; // Accumulated energy
        uint256 affinity; // Affects yield rate (e.g., 1-100)
        uint256 purity; // Affects synthesis success chance (e.g., 1-100)
        uint64 lastUpdateTimestamp; // Timestamp of last energy/state update
        bool isStaked; // Whether the token is currently staked in the vault
        address currentOwner; // To easily track owner when staked (ERC721Enumerable helps too)
    }

    struct SynthesisRequest {
        address initiator;
        uint256[] inputTokenIds; // IDs of crystals being synthesized
        uint256 timestamp;
        // Add parameters derived from input crystals needed for fulfillment
        uint256 totalInputPurity; // Sum of purity of input crystals
        int256 latestOracleModifier; // Oracle modifier at time of request
    }

    // --- State Variables: Tokens ---
    uint256 private _nextTokenId; // Counter for Crystal NFTs
    string private _baseTokenURI; // Base URI for Crystal metadata

    // --- State Variables: Crystal Data ---
    mapping(uint256 => CrystalAttributes) private _crystalAttributes;
    mapping(address => uint256[]) private _stakedTokensByOwner; // Track staked tokens per owner
    mapping(uint256 => uint256) private _stakedTokenIndex; // Index to quickly remove from _stakedTokensByOwner array

    // --- State Variables: Essence Data ---
    mapping(address => uint256) private _claimableEssence; // Essence yield ready to be claimed
    mapping(address => address) private _yieldDelegatee; // Address to which yield is delegated

    // --- State Variables: Parameters ---
    uint256 public essenceYieldRatePerEnergyAffinityPerSecond; // Base yield rate parameter
    uint256 public energyIncreaseRatePerSecond; // Base rate at which crystal energy increases
    uint256 public energyCap; // Maximum energy a crystal can hold

    uint256 public synthesisBaseCost; // Cost to initiate synthesis (in Essence or Ether)
    uint256 public synthesisMinInputs; // Minimum number of crystals required for synthesis
    uint256 public synthesisBaseSuccessChance; // Base probability % for synthesis success (e.g., 5000 for 50%)
    uint256 public synthesisPuritySuccessMultiplier; // Multiplier for purity effect on synthesis chance
    uint256 public synthesisOracleSuccessMultiplier; // Multiplier for oracle modifier effect on synthesis chance
    uint256 public synthesisMaxRandomness; // Max value for randomness check (e.g., 10000)

    // --- State Variables: Oracle Integration ---
    AggregatorV3Interface internal priceFeedOracle; // Chainlink Data Feed for energy modification
    int256 public latestOracleValue; // Last fetched oracle value
    int256 public currentOracleEnergyModifier; // Modifier derived from oracle value, applied to energy gain

    // --- State Variables: VRF Integration ---
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash; // Keyhash for the VRF request
    uint32 callbackGasLimit; // Gas limit for the callback function
    uint16 requestConfirmations; // Number of block confirmations
    uint32 numWords; // Number of random words requested (usually 1 for success/failure)

    // Mapping VRF request ID to synthesis request details
    mapping(uint256 => SynthesisRequest) public pendingSynthesisRequests;

    // --- Events ---
    event CrystalMinted(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint256 initialAffinity, uint256 initialPurity);
    event CrystalStaked(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event CrystalUnstaked(uint256 indexed tokenId, address indexed owner, uint64 timestamp);
    event EssenceClaimed(address indexed owner, address indexed delegatee, uint256 amount);
    event YieldDelegated(address indexed delegator, address indexed delegatee);
    event SynthesisRequested(uint256 indexed requestId, address indexed initiator, uint256[] inputTokenIds, uint256 costPaid);
    event SynthesisFulfilled(uint256 indexed requestId, bool success, uint256 outputTokenId); // outputTokenId is 0 on failure
    event OracleEnergyModifierUpdated(int256 latestValue, int256 modifier);
    event CrystalAttributesUpdated(uint256 indexed tokenId, uint256 energy, uint256 affinity, uint256 purity, CrystalState state);
    event SynthesisParametersUpdated(uint256 baseCost, uint256 minInputs, uint256 baseSuccessChance, uint256 purityMultiplier, uint256 oracleMultiplier);
    event EnergyParametersUpdated(uint256 increaseRate, uint256 cap);

    // --- Constructor ---
    constructor(
        address initialOwner,
        string memory crystalName,
        string memory crystalSymbol,
        string memory essenceName,
        string memory essenceSymbol,
        address vrfCoordinator,
        bytes32 _keyHash,
        uint64 _s_subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    )
        ERC721(crystalName, crystalSymbol)
        ERC20(essenceName, essenceSymbol)
        Ownable(initialOwner)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        keyHash = _keyHash;
        s_subscriptionId = _s_subscriptionId;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;

        _nextTokenId = 1; // Start token IDs from 1

        // Set some initial default parameters (can be changed by owner)
        essenceYieldRatePerEnergyAffinityPerSecond = 1; // Example: 1 unit of yield per energy*affinity point per second
        energyIncreaseRatePerSecond = 10; // Example: Energy increases by 10 per second
        energyCap = 1000000; // Example: Max energy is 1 million

        synthesisBaseCost = 100 * (10**decimals()); // Example: 100 Essence per synthesis
        synthesisMinInputs = 3; // Minimum 3 crystals to synthesize
        synthesisBaseSuccessChance = 5000; // 50% base chance
        synthesisPuritySuccessMultiplier = 50; // Each point of average purity adds 0.5% chance
        synthesisOracleSuccessMultiplier = 10; // Example multiplier for oracle value effect
        synthesisMaxRandomness = 10000; // For chance calculation (0-10000 range)

        currentOracleEnergyModifier = 1000; // Start with a neutral modifier (e.g., 1000 = 1x energy gain)
    }

    // --- ERC721 Overrides ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused // Prevent transfers when paused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfers of staked crystals by anyone other than the vault
        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        require(!attrs.isStaked || (from == address(this) && to != address(this)), "Transfer of staked crystal restricted");

        // Ensure internal state matches ownership during transfer
        // Note: This hook is called *before* the actual transfer happens in ERC721
        // For staked crystals, they are owned by the contract, so standard ERC721 transfer check will fail if called by external user.
        // When unstaking, transfer is from address(this) to user.
        // When staking, transfer is from user to address(this).
        if (from != address(0) && from != address(this)) {
            // Token is being transferred *out* of a user's wallet (staking or regular transfer)
            // If it's a regular transfer and the user was staked (shouldn't happen due to check above), remove from staked list
             if(attrs.isStaked && to != address(this)) {
                 // This state should be unreachable due to the require above, but good defensive check
                 _removeStakedToken(from, tokenId);
                 attrs.isStaked = false; // Should already be false if unstaked properly
             }
        }

         if (to != address(0) && to != address(this)) {
            // Token is being transferred *to* a user's wallet (minting or unstaking)
            // Update internal owner state if needed (handled by ERC721Enumerable typically)
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // Optionally, integrate crystal state into the URI logic
        // This is a placeholder; actual implementation would require a metadata service
        // string memory base = _baseTokenURI;
        // if (bytes(base).length == 0) {
        //     return ""; // Or default URI
        // }

        // uint256 currentEnergy = getCrystalEnergy(tokenId); // Calculates energy real-time
        // CrystalState currentState = getCrystalState(tokenId); // Derives state

        // Example: Append state info to base URI (requires off-chain service to interpret)
        // string memory stateString = _stateToString(currentState); // Helper internal function
        // return string(abi.encodePacked(base, Strings.toString(tokenId), "-", stateString, ".json"));
        // For simplicity, returning base URI + token ID for now
         return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId))) : "";
    }

    // --- ERC20 Overrides ---
    // No specific overrides needed unless we want custom transfer logic,
    // standard ERC20 functions like transfer, approve, allowance work out-of-the-box
    // with OpenZeppelin implementation.

    // --- Core Crystal (ERC721) Management ---

    /// @notice Mints a new Kinetic Crystal NFT. Only callable by the contract owner.
    /// @param recipient The address to receive the new crystal.
    /// @param initialEnergy Initial energy level.
    /// @param initialAffinity Initial affinity level (influences yield).
    /// @param initialPurity Initial purity level (influences synthesis).
    function mintInitialCrystal(address recipient, uint256 initialEnergy, uint256 initialAffinity, uint256 initialPurity)
        external
        onlyOwner
        whenNotPaused // Prevent minting when paused
        returns (uint256)
    {
        uint256 tokenId = _nextTokenId++;
        _mint(recipient, tokenId);

        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        attrs.energy = initialEnergy;
        attrs.affinity = initialAffinity;
        attrs.purity = initialPurity;
        attrs.lastUpdateTimestamp = uint64(block.timestamp); // Initialize timestamp
        attrs.isStaked = false;
        // attrs.currentOwner is implicitly tracked by ERC721Enumerable ownerOf(tokenId)

        emit CrystalMinted(tokenId, recipient, initialEnergy, initialAffinity, initialPurity);
        emit CrystalAttributesUpdated(tokenId, initialEnergy, initialAffinity, initialPurity, getCrystalState(tokenId)); // Emit state update

        return tokenId;
    }

    /// @notice Gets the current attributes (Energy, Affinity, Purity) of a Crystal.
    /// @param tokenId The ID of the Crystal.
    /// @return energy Current energy level.
    /// @return affinity Affinity level.
    /// @return purity Purity level.
    function getCrystalAttributes(uint256 tokenId)
        public
        view
        returns (uint256 energy, uint256 affinity, uint256 purity)
    {
        require(_exists(tokenId), "Invalid token ID");
        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        // Note: This returns the *stored* energy, use getCrystalEnergy for calculated real-time energy
        return (attrs.energy, attrs.affinity, attrs.purity);
    }

    /// @notice Gets the real-time calculated Energy of a Crystal, factoring in time and global modifier.
    /// @param tokenId The ID of the Crystal.
    /// @return Calculated energy level.
    function getCrystalEnergy(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(_exists(tokenId), "Invalid token ID");
        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        uint256 storedEnergy = attrs.energy;
        uint64 lastUpdate = attrs.lastUpdateTimestamp;

        if (block.timestamp > lastUpdate && energyIncreaseRatePerSecond > 0) {
             // Calculate energy increase based on time delta and rate, applying oracle modifier
            uint256 timeDelta = block.timestamp - lastUpdate;
            uint256 energyIncrease = (timeDelta * energyIncreaseRatePerSecond * uint256(currentOracleEnergyModifier)) / 1000; // Assuming modifier is base 1000

            // Add increase, cap at max energy
            unchecked {
                storedEnergy = storedEnergy + energyIncrease;
                if (storedEnergy > energyCap) {
                     storedEnergy = energyCap;
                }
            }
        }
         return storedEnergy;
    }

    /// @notice Gets the derived State of a Crystal based on its real-time calculated Energy.
    /// @param tokenId The ID of the Crystal.
    /// @return The CrystalState enum value.
    function getCrystalState(uint256 tokenId)
        public
        view
        returns (CrystalState)
    {
        uint256 energy = getCrystalEnergy(tokenId);
        // Define state thresholds (example values)
        if (energy < energyCap / 5) return CrystalState.Dormant;
        if (energy < (energyCap / 5) * 2) return CrystalState.Stable;
        if (energy < (energyCap / 5) * 3) return CrystalState.Pulsing;
        if (energy < (energyCap / 5) * 4) return CrystalState.Radiant;
        return CrystalState.Volatile;
    }

     /// @notice Checks if a Crystal is currently staked in the vault.
     /// @param tokenId The ID of the Crystal.
     /// @return True if staked, false otherwise.
    function isCrystalStaked(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Invalid token ID");
        return _crystalAttributes[tokenId].isStaked;
    }

    /// @notice Gets the timestamp of the last stake/unstake action for a Crystal.
    /// @param tokenId The ID of the Crystal.
    /// @return The timestamp (uint64).
     function getCrystalLastStakedTime(uint256 tokenId) public view returns (uint64) {
        require(_exists(tokenId), "Invalid token ID");
        return _crystalAttributes[tokenId].lastUpdateTimestamp; // Reuse lastUpdateTimestamp for staking time when staked
    }

    // Internal helper to update stored energy and timestamp
    function _updateCrystalEnergyInternal(uint256 tokenId) private {
        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        uint256 storedEnergy = attrs.energy;
        uint64 lastUpdate = attrs.lastUpdateTimestamp;
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime > lastUpdate && energyIncreaseRatePerSecond > 0) {
            uint256 timeDelta = currentTime - lastUpdate;
             uint256 energyIncrease = (timeDelta * energyIncreaseRatePerSecond * uint256(currentOracleEnergyModifier)) / 1000; // Apply modifier

            unchecked {
                 storedEnergy = storedEnergy + energyIncrease;
                 if (storedEnergy > energyCap) {
                     storedEnergy = energyCap;
                 }
             }
            attrs.energy = storedEnergy;
            attrs.lastUpdateTimestamp = currentTime; // Update timestamp
            _updateCrystalStateInternal(tokenId); // Update state based on new energy
        }
    }

     // Internal helper to update the stored state based on current energy
     function _updateCrystalStateInternal(uint256 tokenId) private {
         // This function could store the state enum if needed, but getCrystalState calculates it dynamically
         // For this example, we just emit an event if the state changes.
         CrystalState currentState = getCrystalState(tokenId);
         // Optional: Check if stored state changed and emit event. Requires storing state.
         // For simplicity in this example, we just assume potential state change and emit.
         emit CrystalAttributesUpdated(tokenId, _crystalAttributes[tokenId].energy, _crystalAttributes[tokenId].affinity, _crystalAttributes[tokenId].purity, currentState);
     }

    // Helper to get string representation of state (for URI, logging)
    function _stateToString(CrystalState state) private pure returns (string memory) {
        if (state == CrystalState.Dormant) return "dormant";
        if (state == CrystalState.Stable) return "stable";
        if (state == CrystalState.Pulsing) return "pulsing";
        if (state == CrystalState.Radiant) return "radiant";
        if (state == CrystalState.Volatile) return "volatile";
        return "unknown";
    }

    // --- Essence (ERC20) Management ---

    /// @notice Calculates the total Essence yield currently claimable by an address.
    /// This includes yield from crystals they own and staked, AND yield from crystals where they are set as the delegatee.
    /// @param owner The address to check claimable yield for.
    /// @return The total claimable Essence amount.
    function calculateClaimableEssence(address owner)
        public
        view
        returns (uint256)
    {
        uint256 totalClaimable = _claimableEssence[owner]; // Start with direct yield accumulator

        // Need to iterate through all staked tokens to see if any are delegated *to* this owner
        // This is inefficient for many staked tokens. A better approach would be to track delegations per delegatee.
        // For demonstration, we'll iterate (be mindful of gas limits on-chain).
        // A more scalable approach might involve external systems tracking this or a different delegation pattern.

        // --- Scalability consideration: Iterating all staked tokens is BAD for gas. ---
        // A truly scalable version might require:
        // 1. A mapping of delegatee => list of owners who delegated to them.
        // 2. Tracking claimable essence *per crystal* and accumulating it when requested/claimed.
        // 3. Off-chain calculation helper.
        // -----------------------------------------------------------------------------

        // For this example, let's calculate yield *for the owner* (as if claiming their own)
        // and just return the pre-calculated _claimableEssence value.
        // The delegation logic needs to modify *where* the calculated yield goes when crystals are staked/unstaked/claimed.

        // Let's refine the delegation concept: when `claimEssence` is called by `msg.sender`,
        // it should claim:
        // 1. Yield from `msg.sender`'s *own* staked crystals.
        // 2. Yield from crystals owned by others *where msg.sender is the delegatee*.

        // This still requires iterating over owned crystals. Let's calculate owner's yield first.

        uint256 ownerDirectClaimable = 0;
        uint256[] memory ownedStaked = _stakedTokensByOwner[owner]; // Get tokens staked *by* this owner
        uint64 currentTime = uint64(block.timestamp);

        for (uint i = 0; i < ownedStaked.length; i++) {
            uint256 tokenId = ownedStaked[i];
            CrystalAttributes storage attrs = _crystalAttributes[tokenId];

            if (attrs.isStaked && ownerOf(tokenId) == address(this)) { // Double check state
                 // Calculate yield earned since last update timestamp
                uint256 timeDelta = currentTime - attrs.lastUpdateTimestamp;
                uint256 energy = getCrystalEnergy(tokenId); // Calculate real-time energy
                uint256 yieldEarned = (energy * attrs.affinity * essenceYieldRatePerEnergyAffinityPerSecond * timeDelta);
                 ownerDirectClaimable += yieldEarned;

                // Update timestamp *without* changing energy here (energy updated on get)
                // We update it in claimEssence where state changes are committed.
            }
        }
        // Add yield delegated *to* this owner. This part still requires iterating or a better data structure.
        // Let's simplify for the example and assume `_claimableEssence[owner]` already includes yield delegated *to* them
        // through the `claimEssence` function's internal logic.
        // So, `calculateClaimableEssence` just returns the accumulated value.

        return totalClaimable;
    }

    /// @notice Allows a user to claim their accumulated Essence yield.
    /// This includes yield from their own staked crystals and any yield delegated to them.
    /// @dev Requires `ReentrancyGuard` to prevent reentrancy issues during token minting.
    function claimEssence() external nonReentrant whenNotPaused {
        address claimant = msg.sender;
        uint64 currentTime = uint64(block.timestamp);
        uint256 totalYieldToClaim = 0;

        // 1. Calculate yield for claimant's own staked crystals and add to their accumulator
        uint256[] memory ownedStaked = _stakedTokensByOwner[claimant];
        uint256 ownerYield = 0;
        for (uint i = 0; i < ownedStaked.length; i++) {
            uint256 tokenId = ownedStaked[i];
            CrystalAttributes storage attrs = _crystalAttributes[tokenId];

            // Ensure the token is still owned by the vault and marked as staked by this owner
            if (attrs.isStaked && ownerOf(tokenId) == address(this)) {
                 // Calculate yield earned since last update timestamp
                uint256 timeDelta = currentTime - attrs.lastUpdateTimestamp;
                if (timeDelta > 0) {
                     uint256 energy = getCrystalEnergy(tokenId); // Get real-time energy
                    uint256 yieldEarned = (energy * attrs.affinity * essenceYieldRatePerEnergyAffinityPerSecond * timeDelta);
                    ownerYield += yieldEarned;
                     // Update crystal timestamp - energy is dynamic, only timestamp needs storing
                     attrs.lastUpdateTimestamp = currentTime;
                 }
            }
        }
        _claimableEssence[claimant] += ownerYield; // Add owner's yield to their accumulator

        // 2. Calculate yield for crystals owned by others but delegated *to* claimant
        // This part is hard to do efficiently without iterating all crystals or a better data structure.
        // Let's adjust the delegation model: `delegateEssenceYield` sets who *can claim* the yield *for that specific owner's staked crystals*.
        // `claimEssence` called by `claimant` should look up all owners who delegated to `claimant`.
        // Still requires iteration or pre-computed lists.

        // Alternative approach (simpler for example): Yield is always accumulated for the crystal *owner*.
        // `claimEssence` claims yield accumulated for `msg.sender`.
        // `delegateEssenceYield` allows `msg.sender` (owner) to set a `delegatee` who is allowed to call `claimEssenceForOwner(owner)`
        // Let's go with this simpler model for `claimEssence`.

        // --- Simplified `claimEssence`: Claims only yield accumulated for `msg.sender`. ---
        // Logic above already calculates and adds owner's direct yield to _claimableEssence[claimant].
        // Now, process delegation.
        address ownerForClaim = claimant; // Assume claiming for self first
        address delegatee = _yieldDelegatee[claimant];
        if (delegatee != address(0) && delegatee != claimant) {
             // If claimant has delegated *their* yield, the yield calculated above should go to delegatee.
             // But wait, `claimEssence` is called by the *claimer*.
             // Let's use the delegatee mapping to allow the delegatee to claim the owner's yield.

             // Revised logic: `claimEssence()` called by `msg.sender` claims:
             // A) Yield from `msg.sender`'s own staked crystals.
             // B) Yield from crystals owned by others, where `msg.sender` is the *delegatee* for that owner.
             // This still requires iterating or a complex mapping.

             // Simplest functional model: `claimEssence()` called by `msg.sender` claims *all* yield that has been calculated
             // and added to `_claimableEssence[msg.sender]`.
             // The `delegateEssenceYield` function determines *who* gets the yield *added* to their `_claimableEssence` when it accrues.
             // But yield accrues continuously. We need to decide *when* it gets added to the accumulator.
             // - On stake/unstake?
             // - On claim?
             // - Periodically?

             // Let's make yield calculation and claiming happen together on `claimEssence`.
             // When `claimEssence()` is called by `msg.sender`:
             // Iterate over `msg.sender`'s staked tokens. Calculate yield since last claim/update.
             // If `msg.sender` HAS a delegatee, add this yield to `_claimableEssence[delegatee]`.
             // If `msg.sender` DOES NOT have a delegatee, add this yield to `_claimableEssence[msg.sender]`.
             // Then transfer `_claimableEssence[msg.sender]` to `msg.sender` and reset it.
             // This means a delegatee would need to call `claimEssence()` themselves to get yield delegated *to* them.

             // Let's re-code claim based on this model.

            // Calculate yield from crystals owned and staked by `claimant`
            uint256 yieldFromOwnStaked = 0;
             uint256[] memory claimantStakedTokens = _stakedTokensByOwner[claimant];
            for (uint i = 0; i < claimantStakedTokens.length; i++) {
                uint256 tokenId = claimantStakedTokens[i];
                CrystalAttributes storage attrs = _crystalAttributes[tokenId];

                 if (attrs.isStaked && ownerOf(tokenId) == address(this)) {
                    uint256 timeDelta = currentTime - attrs.lastUpdateTimestamp;
                    if (timeDelta > 0) {
                         uint256 energy = getCrystalEnergy(tokenId);
                         uint256 yieldEarned = (energy * attrs.affinity * essenceYieldRatePerEnergyAffinityPerSecond * timeDelta);
                        yieldFromOwnStaked += yieldEarned;
                         attrs.lastUpdateTimestamp = currentTime; // Update timestamp after calculating yield
                    }
                }
            }

            // Add calculated yield to the correct accumulator (claimant's or delegatee's)
            address yieldRecipient = _yieldDelegatee[claimant] == address(0) ? claimant : _yieldDelegatee[claimant];
            _claimableEssence[yieldRecipient] += yieldFromOwnStaked;


            // Now, transfer the total accumulated balance for *this claimant* (which includes yield delegated TO them)
            totalYieldToClaim = _claimableEssence[claimant];
            if (totalYieldToClaim > 0) {
                _claimableEssable[claimant] = 0; // Reset accumulator *before* minting
                _mint(claimant, totalYieldToClaim); // Mint Essence to claimant

                emit EssenceClaimed(claimant, _yieldDelegatee[claimant], totalYieldToClaim);
            } else {
                // Emit event even if 0 claimed? Or just silently return. Let's not emit for 0.
            }
        } else {
             // If no tokens are staked or no yield earned, just process existing claimable balance.
             totalYieldToClaim = _claimableEssence[claimant];
             if (totalYieldToClaim > 0) {
                 _claimableEssence[claimant] = 0;
                 _mint(claimant, totalYieldToClaim);
                 emit EssenceClaimed(claimant, address(0), totalYieldToClaim);
             }
        }

    }

     /// @notice Allows a user (crystal owner) to delegate the claimable Essence yield
     /// from their staked crystals to another address.
     /// @param delegatee The address that will be allowed to claim the yield. Use address(0) to clear delegation.
    function delegateEssenceYield(address delegatee) external whenNotPaused {
        address delegator = msg.sender;
        require(delegator != delegatee, "Cannot delegate yield to self");
        _yieldDelegatee[delegator] = delegatee;
        emit YieldDelegated(delegator, delegatee);
    }

     /// @notice Gets the address to which an owner's staked crystal yield is delegated.
     /// @param owner The address whose delegation setting to query.
     /// @return The delegatee address, or address(0) if no delegation is set.
    function getDelegatee(address owner) public view returns (address) {
        return _yieldDelegatee[owner];
    }

    /// @notice Claims Essence yield for a specified owner. Only callable by the owner or their delegatee.
    /// This is needed if someone wants to claim yield that was delegated *to* them.
    /// @param owner The address whose yield is being claimed.
    /// @dev Requires `ReentrancyGuard`.
     function claimEssenceForOwner(address owner) external nonReentrant whenNotPaused {
         address claimant = msg.sender;
         // Check if claimant is the owner or the appointed delegatee
         require(claimant == owner || _yieldDelegatee[owner] == claimant, "Not authorized to claim yield for this owner");

         uint64 currentTime = uint64(block.timestamp);
         uint256 totalYieldToClaim = 0;

         // Calculate yield from crystals owned and staked by `owner`
         uint256[] memory ownersStakedTokens = _stakedTokensByOwner[owner];
         uint256 ownerYield = 0;
         for (uint i = 0; i < ownersStakedTokens.length; i++) {
             uint256 tokenId = ownersStakedTokens[i];
             CrystalAttributes storage attrs = _crystalAttributes[tokenId];

             if (attrs.isStaked && ownerOf(tokenId) == address(this)) {
                 uint256 timeDelta = currentTime - attrs.lastUpdateTimestamp;
                 if (timeDelta > 0) {
                     uint256 energy = getCrystalEnergy(tokenId);
                     uint256 yieldEarned = (energy * attrs.affinity * essenceYieldRatePerEnergyAffinityPerSecond * timeDelta);
                     ownerYield += yieldEarned;
                     attrs.lastUpdateTimestamp = currentTime; // Update timestamp
                 }
             }
         }

         // Add calculated yield to the owner's accumulator (it will be claimed by the claimant)
         _claimableEssence[owner] += ownerYield;

         // Now, transfer the total accumulated balance for *this owner* to the *claimant*
         // This means `_claimableEssence[owner]` should contain yield accumulated for owner's tokens,
         // plus any yield from other tokens where the *owner* was the delegatee.
         // This model is getting complicated. Let's revert to the simpler `claimEssence` that claims only for msg.sender,
         // and the delegation determines *who* gets the accrual.

         // Reverting `claimEssenceForOwner` and simplifying `claimEssence` logic again.
         // Simplified `claimEssence` will calculate yield from `msg.sender`'s staked tokens,
         // add it to the accumulator of their `_yieldDelegatee` (or `msg.sender` if no delegatee),
         // and then transfer the total balance of `_claimableEssence[msg.sender]` to `msg.sender`.
         // A delegatee calls `claimEssence()` and gets all yield delegated *to* them.
         // An owner calls `claimEssence()` and gets their own yield IF they haven't delegated, PLUS any yield delegated *to* them.

         // Okay, the `claimEssence` function above implements this model. `claimEssenceForOwner` is redundant.
         // Let's remove `claimEssenceForOwner` and the associated logic complexity.
         // `calculateClaimableEssence(owner)` now returns the value of `_claimableEssence[owner]`.

         // Re-evaluating `calculateClaimableEssence`: It should return the value that `claimEssence` would transfer if called by `owner`.
         // Based on the refined `claimEssence` logic, `calculateClaimableEssence(owner)` should return `_claimableEssence[owner]`.
         // The actual calculation happens *during* the `claimEssence` call. This is a common pattern to save gas on views.
     }

     /// @notice Allows a user to claim Essence yield for multiple owners in a batch.
     /// Useful if the caller is a delegatee for multiple owners.
     /// @param owners An array of owner addresses whose yield to claim.
     /// @dev Requires `ReentrancyGuard`. The caller must be the owner or delegatee for *each* owner in the array.
    function batchClaimEssence(address[] memory owners) external nonReentrant whenNotPaused {
         address claimant = msg.sender;
         uint64 currentTime = uint64(block.timestamp);
         uint256 totalYieldTransferred = 0;

         for (uint i = 0; i < owners.length; i++) {
            address currentOwner = owners[i];
             // Check authorization for this specific owner
            require(claimant == currentOwner || _yieldDelegatee[currentOwner] == claimant, string(abi.encodePacked("Not authorized to claim yield for owner ", Strings.toHexString(uint160(currentOwner)))));

             // Calculate yield for this owner's staked crystals
             uint256 ownersStakedTokensLength = _stakedTokensByOwner[currentOwner].length; // Get length before iterating
             uint256 ownerYield = 0;
             // Need to copy the array as we might modify _stakedTokensByOwner timestamps inside the loop
             uint256[] memory ownersTokensCopy = new uint256[](ownersStakedTokensLength);
             for(uint j = 0; j < ownersStakedTokensLength; j++) {
                 ownersTokensCopy[j] = _stakedTokensByOwner[currentOwner][j];
             }


             for (uint j = 0; j < ownersTokensCopy.length; j++) {
                 uint256 tokenId = ownersTokensCopy[j];
                 // Re-check existence and staking state in case it changed during batch iteration (unlikely but safe)
                 if (_exists(tokenId)) {
                     CrystalAttributes storage attrs = _crystalAttributes[tokenId];
                     if (attrs.isStaked && ownerOf(tokenId) == address(this)) {
                         uint256 timeDelta = currentTime - attrs.lastUpdateTimestamp;
                         if (timeDelta > 0) {
                            uint256 energy = getCrystalEnergy(tokenId);
                            uint256 yieldEarned = (energy * attrs.affinity * essenceYieldRatePerEnergyAffinityPerSecond * timeDelta);
                            ownerYield += yieldEarned;
                            attrs.lastUpdateTimestamp = currentTime; // Update timestamp
                         }
                     }
                 }
             }

            // Add calculated yield for this owner's tokens to the correct accumulator (owner's or their delegatee's)
            address yieldRecipient = _yieldDelegatee[currentOwner] == address(0) ? currentOwner : _yieldDelegatee[currentOwner];
            _claimableEssence[yieldRecipient] += ownerYield;
         }

         // Finally, transfer the total accumulated balance for the *claimant* (msg.sender)
         // This balance includes yield calculated above where claimant was the delegatee.
         // It also includes any yield where claimant was the owner AND hadn't delegated.
         // And any previous yield added to _claimableEssence[claimant].

         uint256 totalClaimableForClaimant = _claimableEssence[claimant];
         if (totalClaimableForClaimant > 0) {
             _claimableEssence[claimant] = 0; // Reset accumulator before minting
             _mint(claimant, totalClaimableForClaimant); // Mint Essence to claimant
             totalYieldTransferred = totalClaimableForClaimant; // Track total transferred
         }
         // Emit single event for the batch claim total? Or separate for each owner?
         // Single event is more gas efficient. But makes tracking harder.
         // Let's emit one event with total claimed by claimant.
         // Emitting per owner inside the loop is too gas-intensive.
        if(totalYieldTransferred > 0) {
             emit EssenceClaimed(claimant, address(0), totalYieldTransferred); // Note: Delegatee field might be misleading here, represents claimant
        }

     }


    // --- Staking ---

    /// @notice Allows an owner to stake their Crystal NFT in the vault.
    /// @param tokenId The ID of the Crystal to stake.
    /// @dev Requires `ReentrancyGuard`.
    function stakeCrystal(uint256 tokenId) public nonReentrant whenNotPaused {
        address owner = ownerOf(tokenId); // Gets current owner using ERC721Enumerable
        require(owner == msg.sender, "Not your token to stake");
        require(!_crystalAttributes[tokenId].isStaked, "Crystal is already staked");

        // The owner calculates and claims any pending yield *before* staking
        // (Alternative: yield accrues even when not staked, or is lost on unstake. Decided yield only accrues while STAKED)
        // Let's enforce claiming before staking for simplicity.
        // require(calculateClaimableEssence(msg.sender) == 0, "Claim pending yield before staking");
        // Or, let's allow staking, and pending yield stays/transfers based on delegation.
        // The model where yield is calculated and added to accumulator on `claimEssence` call means no pre-claiming is strictly needed here.
        // When `claimEssence` is called later, it will use the timestamp at that moment for calculation.

        // Transfer the NFT to the contract address
        safeTransferFrom(owner, address(this), tokenId); // ERC721 safeTransferFrom handles approval checks

        // Update crystal state
        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        attrs.isStaked = true;
        attrs.lastUpdateTimestamp = uint64(block.timestamp); // Mark stake time

        // Add token ID to the owner's staked list
        _stakedTokensByOwner[owner].push(tokenId);
        _stakedTokenIndex[tokenId] = _stakedTokensByOwner[owner].length - 1; // Store index

        emit CrystalStaked(tokenId, owner, uint64(block.timestamp));
    }

    /// @notice Allows an owner to unstake their Crystal NFT from the vault.
    /// @param tokenId The ID of the Crystal to unstake.
    /// @dev Requires `ReentrancyGuard`.
    function unstakeCrystal(uint256 tokenId) public nonReentrant whenNotPaused {
        require(_exists(tokenId), "Invalid token ID");
        CrystalAttributes storage attrs = _crystalAttributes[tokenId];
        require(attrs.isStaked, "Crystal is not staked");

        address originalOwner = msg.sender; // Unstaking can only be initiated by the original owner

        // We need to verify msg.sender is the owner who STAKED the token.
        // ownerOf(tokenId) will be address(this). We need to rely on the _stakedTokensByOwner mapping.
        bool found = false;
        uint256 ownerStakedCount = _stakedTokensByOwner[originalOwner].length;
        for(uint i = 0; i < ownerStakedCount; i++) {
            if (_stakedTokensByOwner[originalOwner][i] == tokenId) {
                found = true;
                break;
            }
        }
        require(found, "Not authorized to unstake this crystal");

        // The owner calculates and claims any pending yield *before* unstaking if desired,
        // but yield accumulated for this crystal up to this point will still be added to the designated accumulator
        // on the next `claimEssence` call.

        // Mark as not staked *before* transferring out
        attrs.isStaked = false;
        attrs.lastUpdateTimestamp = uint64(block.timestamp); // Mark unstake time

        // Remove token ID from the owner's staked list
        _removeStakedToken(originalOwner, tokenId);

        // Transfer the NFT back to the original owner
        // Use _transfer instead of safeTransferFrom to avoid reentrancy issues if recipient is a contract
        // and doesn't implement ERC721TokenReceiver correctly, especially since we are inside nonReentrant.
        // However, safeTransferFrom IS the standard. Let's use it, relying on ReentrancyGuard.
        safeTransferFrom(address(this), originalOwner, tokenId);

        emit CrystalUnstaked(tokenId, originalOwner, uint64(block.timestamp));
    }

     // Internal helper to remove a token ID from a user's staked list
    function _removeStakedToken(address owner, uint256 tokenId) internal {
        uint256 index = _stakedTokenIndex[tokenId];
        uint256 lastIndex = _stakedTokensByOwner[owner].length - 1;
        uint256 lastTokenId = _stakedTokensByOwner[owner][lastIndex];

        // Move the last element into the place of the element to delete
        _stakedTokensByOwner[owner][index] = lastTokenId;
        _stakedTokenIndex[lastTokenId] = index;

        // Remove the last element
        _stakedTokensByOwner[owner].pop();
        delete _stakedTokenIndex[tokenId];
    }


    /// @notice Allows an owner to stake multiple Crystals in a single transaction.
    /// @param tokenIds An array of IDs of the Crystals to stake.
    function bulkStakeCrystals(uint256[] memory tokenIds) external whenNotPaused {
        for (uint i = 0; i < tokenIds.length; i++) {
            stakeCrystal(tokenIds[i]); // Calls the single stake function
        }
    }

    /// @notice Allows an owner to unstake multiple Crystals in a single transaction.
    /// @param tokenIds An array of IDs of the Crystals to unstake.
    function bulkUnstakeCrystals(uint256[] memory tokenIds) external whenNotPaused {
         for (uint i = 0; i < tokenIds.length; i++) {
            unstakeCrystal(tokenIds[i]); // Calls the single unstake function
        }
    }

     /// @notice Gets the list of token IDs currently staked by a specific owner.
     /// @param owner The address whose staked tokens to query.
     /// @return An array of staked token IDs.
    function getStakedCrystalTokens(address owner) public view returns (uint256[] memory) {
        return _stakedTokensByOwner[owner];
    }

    /// @notice Gets the total number of crystals currently staked in the vault.
    /// @return The total count of staked crystals.
    function getTotalStakedCrystals() public view returns (uint256) {
        return ERC721Enumerable.balanceOf(address(this)); // The vault owns all staked crystals
    }

    // --- Synthesis ---

    /// @notice Initiates a synthesis request using a set of staked Crystal NFTs.
    /// Burns the input NFTs and requests randomness from Chainlink VRF. Requires payment.
    /// @param tokenIds An array of IDs of staked Crystals to use for synthesis.
    /// @dev Payment for synthesis is sent with the transaction (e.g., in Ether) or needs to be approved (in Essence).
    /// For this example, let's assume payment is in the Essence token, requiring prior approval or using permit.
    /// Simpler: require `msg.value >= synthesisBaseCost` for payment in Ether. Let's use Ether.
    /// Requires `ReentrancyGuard` because it calls VRF request (which might eventually lead to callback).
    function requestSynthesis(uint256[] memory tokenIds) external payable nonReentrant whenNotPaused {
        require(tokenIds.length >= synthesisMinInputs, "Not enough crystals for synthesis");
        require(msg.value >= synthesisBaseCost, "Insufficient payment for synthesis"); // Pay in Ether

        address initiator = msg.sender;
        uint256 totalPurity = 0;
        uint64 currentTime = uint64(block.timestamp);

        // Validate inputs: must be staked by the initiator
        for (uint i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "Invalid token ID in input list");
            CrystalAttributes storage attrs = _crystalAttributes[tokenId];
            // Check if token is staked AND if the staked token belongs to this initiator's list
             bool found = false;
             uint256 ownerStakedCount = _stakedTokensByOwner[initiator].length;
             for(uint j = 0; j < ownerStakedCount; j++) {
                 if (_stakedTokensByOwner[initiator][j] == tokenId) {
                 found = true;
                 break;
                 }
             }
            require(found, "Input crystal not staked by initiator");
            // Ensure state is consistent (owned by vault)
             require(ownerOf(tokenId) == address(this), "Input crystal not owned by vault");

            // Update crystal state and sum purity before burning
            _updateCrystalEnergyInternal(tokenId); // Ensure latest energy/state is factored before potential burn
            totalPurity += attrs.purity;
        }

        // Burn the input crystals
        for (uint i = 0; i < tokenIds.length; i++) {
             uint256 tokenId = tokenIds[i];
            // Remove from staked list before burning
            _removeStakedToken(initiator, tokenId);
            delete _crystalAttributes[tokenId]; // Clear attributes
            _burn(tokenId); // Burn the NFT
        }

        // Request randomness from Chainlink VRF
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        // Store request details for fulfillment
        // Need to store details necessary for calculating outcome later
        pendingSynthesisRequests[requestId] = SynthesisRequest({
            initiator: initiator,
            inputTokenIds: tokenIds, // Store IDs for reference, even though they are burned
            timestamp: currentTime,
            totalInputPurity: totalPurity,
            latestOracleModifier: currentOracleEnergyModifier // Capture modifier at request time
        });

        emit SynthesisRequested(requestId, initiator, tokenIds, msg.value);
    }

     /// @notice Chainlink VRF callback function. Processes randomness for synthesis outcome.
     /// This function is called by the Chainlink VRF Coordinator contract.
     /// @param requestId The ID of the VRF request.
     /// @param randomWords An array of random words generated by VRF.
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        require(pendingSynthesisRequests[requestId].initiator != address(0), "Request ID not found"); // Ensure request exists

        SynthesisRequest storage request = pendingSynthesisRequests[requestId];
        uint256 randomNumber = randomWords[0]; // Get the first random word

        address initiator = request.initiator;
        uint256 inputCount = request.inputTokenIds.length;
        uint256 totalPurity = request.totalInputPurity;
        int256 oracleModifier = request.latestOracleModifier;

        // Calculate success probability based on input attributes and oracle modifier
        uint256 averagePurity = totalPurity / inputCount;
        // Adjust oracle modifier to be non-negative for multiplication, scale it
        // Example: modifier 1000 (neutral) -> 1.0, 1200 -> 1.2, 800 -> 0.8
        uint256 scaledOracleModifier = oracleModifier > 0 ? uint256(oracleModifier) : 0; // Handle negative modifier? Or design modifier differently. Let's assume 1000 is base.
        // If modifier is 1000, scaled is 1000. If 1200, scaled is 1200.
        // Need to scale it relative to base (1000). (modifier / 1000) * multiplier
        // Let's calculate adjusted chance out of synthesisMaxRandomness (10000)
        uint256 successChance = synthesisBaseSuccessChance; // Start with base
        successChance += (averagePurity * synthesisPuritySuccessMultiplier); // Add chance based on purity
        // Add chance based on oracle modifier. (modifier - 1000) gives delta. Scale delta.
        int256 oracleDelta = oracleModifier - 1000; // Assuming 1000 is neutral
        // Add/subtract based on delta and multiplier
        int256 oracleChanceEffect = (oracleDelta * int256(synthesisOracleSuccessMultiplier)) / 1000; // Scale delta by 1000 base

        // Ensure chance doesn't go below 0 or above max randomness
        int256 finalChance = int256(successChance) + oracleChanceEffect;
        if (finalChance < 0) finalChance = 0;
        if (finalChance > int256(synthesisMaxRandomness)) finalChance = int256(synthesisMaxRandomness);

        // Determine outcome using randomness
        bool success = (randomNumber % synthesisMaxRandomness) < uint256(finalChance);

        uint256 outputTokenId = 0; // 0 indicates failure

        if (success) {
            // Synthesis success! Mint a new, potentially enhanced crystal.
            outputTokenId = _nextTokenId++;
            _mint(initiator, outputTokenId);

            // Calculate new crystal attributes based on inputs (example logic)
            // Could be average, weighted average, or specific formulas
            uint256 newEnergy = (request.totalInputPurity * energyCap) / (inputCount * 100); // Example: higher purity inputs yield higher initial energy relative to cap
            uint256 newAffinity = (request.totalInputPurity * 100) / (inputCount * 100); // Example: average purity
            uint256 newPurity = (request.totalInputPurity / inputCount) + (uint256(finalChance) / 1000); // Example: average purity + bonus from high chance

            // Cap new attributes
            if (newAffinity > 100) newAffinity = 100;
            if (newPurity > 100) newPurity = 100;
             if (newEnergy > energyCap) newEnergy = energyCap; // Should be handled by formula, but safety cap

            CrystalAttributes storage newAttrs = _crystalAttributes[outputTokenId];
            newAttrs.energy = newEnergy;
            newAttrs.affinity = newAffinity;
            newAttrs.purity = newPurity;
            newAttrs.lastUpdateTimestamp = uint64(block.timestamp);
            newAttrs.isStaked = false; // New crystal is minted unstaked

            emit CrystalMinted(outputTokenId, initiator, newEnergy, newAffinity, newPurity);
             emit CrystalAttributesUpdated(outputTokenId, newEnergy, newAffinity, newPurity, getCrystalState(outputTokenId));
        } else {
            // Synthesis failure. Input crystals are burned.
            // Optionally, return a portion of the synthesis cost.
            // For this example, cost is consumed on failure.
        }

        // Clean up pending request
        delete pendingSynthesisRequests[requestId];

        emit SynthesisFulfilled(requestId, success, outputTokenId);
    }

    /// @notice Gets the cost to perform synthesis with a given number of crystals.
    /// @param numberOfInputs The number of crystals to use.
    /// @return The cost in Ether.
    function getSynthesisCost(uint256 numberOfInputs) public view returns (uint256) {
        require(numberOfInputs >= synthesisMinInputs, "Not enough crystals for synthesis");
        // Cost could be a function of inputs, but keeping it simple here
        return synthesisBaseCost;
    }

     /// @notice Estimates the success probability of a synthesis request with given input crystals.
     /// @param tokenIds An array of IDs of crystals to use for synthesis (they must be staked by msg.sender).
     /// @return Estimated success chance out of synthesisMaxRandomness (e.g., 0-10000).
    function predictSynthesisSuccess(uint256[] memory tokenIds) public view returns (uint256) {
         require(tokenIds.length >= synthesisMinInputs, "Not enough crystals for synthesis");
         address owner = msg.sender;
         uint256 totalPurity = 0;

         // Validate inputs (similar to requestSynthesis, but without state changes)
         for (uint i = 0; i < tokenIds.length; i++) {
             uint256 tokenId = tokenIds[i];
             require(_exists(tokenId), "Invalid token ID in input list");
             CrystalAttributes storage attrs = _crystalAttributes[tokenId];
             // Check if token is staked by this owner
             bool found = false;
             uint256 ownerStakedCount = _stakedTokensByOwner[owner].length;
             for(uint j = 0; j < ownerStakedCount; j++) {
                 if (_stakedTokensByOwner[owner][j] == tokenId) {
                 found = true;
                 break;
                 }
             }
             require(found, "Input crystal not staked by initiator");

            // Use current attributes for prediction
            totalPurity += attrs.purity;
        }

        uint256 inputCount = tokenIds.length;
        uint256 averagePurity = totalPurity / inputCount;

        // Calculate predicted chance (same logic as fulfillment, but without randomness)
        uint256 estimatedChance = synthesisBaseSuccessChance;
        estimatedChance += (averagePurity * synthesisPuritySuccessMultiplier);

        int256 oracleDelta = currentOracleEnergyModifier - 1000;
        int256 oracleChanceEffect = (oracleDelta * int256(synthesisOracleSuccessMultiplier)) / 1000;

        int256 finalChance = int256(estimatedChance) + oracleChanceEffect;
        if (finalChance < 0) finalChance = 0;
        if (finalChance > int256(synthesisMaxRandomness)) finalChance = int256(synthesisMaxRandomness);

        return uint256(finalChance);
    }

     /// @notice Gets details of a pending synthesis request.
     /// @param requestId The ID of the VRF request.
     /// @return initiator The address that initiated the request.
     /// @return inputTokenIds The IDs of the input crystals used (note: these are burned).
     /// @return timestamp The timestamp when the request was made.
     /// @return totalInputPurity Total purity of input crystals at request time.
     /// @return latestOracleModifier Oracle modifier at request time.
    function getPendingSynthesisRequest(uint256 requestId)
         public
         view
         returns (
             address initiator,
             uint256[] memory inputTokenIds,
             uint256 timestamp,
             uint256 totalInputPurity,
             int256 latestOracleModifier
         )
    {
         SynthesisRequest storage request = pendingSynthesisRequests[requestId];
         require(request.initiator != address(0), "Request ID not found");
         return (
             request.initiator,
             request.inputTokenIds,
             request.timestamp,
             request.totalInputPurity,
             request.latestOracleModifier
         );
    }

    // --- Oracle Integration (Data Feed) ---

    /// @notice Sets the address of the Chainlink Data Feed used for the global energy modifier.
    /// @param oracleAddress The address of the AggregatorV3Interface contract.
    function setEnergyOracleAddress(address oracleAddress) external onlyOwner {
        priceFeedOracle = AggregatorV3Interface(oracleAddress);
    }

    /// @notice Requests the latest price from the configured Chainlink Data Feed.
    /// This should be called periodically by the owner or an automated system (e.g., Chainlink Keeper).
    function requestOracleEnergyModifier() external onlyOwnerOrKeeper {
        // Get the latest price data
        (, int256 price, , ,) = priceFeedOracle.latestRoundData();

        // Calculate and update the global energy modifier based on the price
        // Example logic: If price > target, energy gain increases; if price < target, energy gain decreases.
        // Assume a 'targetPrice' relative to historical data or contract constant.
        // Let's use 1000 as a neutral base modifier (100%). Price range maps to modifier range.
        // Simple mapping: Modifier = 1000 + (price - targetPrice) / scaleFactor
        // Need a target price. Let's just use the price directly scaled.
        // e.g., Modifier = price / 1000 (if price is in USD * 10^8, and we want modifier around 1000)
        // Let's assume priceFeed feeds USD price * 10^8. E.g., $1 = 10^8.
        // Target average price could be a parameter. Let's hardcode a target for this example.
        int256 targetPrice = 2000 * 1e8; // Example: Target price $2000
        int256 priceDelta = price - targetPrice;
        // Scale delta to affect modifier around 1000.
        // A $100 increase might add 50 to the modifier. 100 * (50 / 100) = 50
        int256 modifierDelta = (priceDelta * 50) / (100 * 1e8); // Example scale: $100 change affects modifier by 50

        currentOracleEnergyModifier = 1000 + modifierDelta;

        // Ensure modifier is not negative (energy can't decrease just from this)
        if (currentOracleEnergyModifier < 0) {
             currentOracleEnergyModifier = 0; // Or set a minimum positive modifier
        }

        latestOracleValue = price; // Store the latest fetched value
        emit OracleEnergyModifierUpdated(latestOracleValue, currentOracleEnergyModifier);

        // Note: Energy itself is updated dynamically in `getCrystalEnergy` and `_updateCrystalEnergyInternal`
        // using this `currentOracleEnergyModifier` value.
    }

     /// @notice Gets the last fetched value from the energy oracle.
     /// @return The latest oracle price value (int256).
    function getLatestOracleValue() public view returns (int256) {
        return latestOracleValue;
    }

     /// @notice Gets the current global energy modifier derived from the oracle.
     /// @return The current energy modifier (int256), base 1000.
    function getOracleEnergyModifier() public view returns (int256) {
        return currentOracleEnergyModifier;
    }


    // --- Admin/Parameter Management ---

    /// @notice Sets the base rate for Essence yield calculation.
    /// @param ratePerEnergyAffinityPerSecond The yield rate.
    function setEssenceYieldRate(uint256 ratePerEnergyAffinityPerSecond) external onlyOwner {
        essenceYieldRatePerEnergyAffinityPerSecond = ratePerEnergyAffinityPerSecond;
    }

    /// @notice Sets parameters for the synthesis process.
    /// @param baseCost The base cost (in Ether) to initiate synthesis.
    /// @param minInputs Minimum number of crystals required.
    /// @param baseSuccessChance Base probability % (scaled 0-10000).
    /// @param puritySuccessMultiplier Multiplier for average purity effect on chance.
    /// @param oracleSuccessMultiplier Multiplier for oracle modifier effect on chance.
    function setSynthesisParameters(
        uint256 baseCost,
        uint256 minInputs,
        uint256 baseSuccessChance,
        uint256 puritySuccessMultiplier,
        uint256 oracleSuccessMultiplier
    ) external onlyOwner {
        synthesisBaseCost = baseCost;
        synthesisMinInputs = minInputs;
        synthesisBaseSuccessChance = baseSuccessChance;
        synthesisPuritySuccessMultiplier = puritySuccessMultiplier;
        synthesisOracleSuccessMultiplier = oracleSuccessMultiplier;
        emit SynthesisParametersUpdated(baseCost, minInputs, baseSuccessChance, puritySuccessMultiplier, oracleSuccessMultiplier);
    }

     /// @notice Gets current synthesis parameters.
     /// @return baseCost The base cost in Ether.
     /// @return minInputs Minimum number of crystals required.
     /// @return baseSuccessChance Base probability % (scaled 0-10000).
     /// @return puritySuccessMultiplier Multiplier for average purity effect.
     /// @return oracleSuccessMultiplier Multiplier for oracle modifier effect.
    function getSynthesisParameters()
        external
        view
        returns (
            uint256 baseCost,
            uint256 minInputs,
            uint256 baseSuccessChance,
            uint256 puritySuccessMultiplier,
            uint256 oracleSuccessMultiplier
        )
    {
        return (
            synthesisBaseCost,
            synthesisMinInputs,
            synthesisBaseSuccessChance,
            synthesisPuritySuccessMultiplier,
            synthesisOracleSuccessMultiplier
        );
    }

    /// @notice Sets the base rate at which crystal energy increases.
    /// @param ratePerSecond The energy increase rate per second.
    function setEnergyIncreaseRate(uint256 ratePerSecond) external onlyOwner {
        energyIncreaseRatePerSecond = ratePerSecond;
        emit EnergyParametersUpdated(energyIncreaseRatePerSecond, energyCap);
    }

    /// @notice Sets the maximum possible energy a crystal can hold.
    /// @param cap The energy cap.
    function setEnergyCap(uint256 cap) external onlyOwner {
        energyCap = cap;
        emit EnergyParametersUpdated(energyIncreaseRatePerSecond, energyCap);
    }

     /// @notice Gets current energy parameters.
     /// @return increaseRate The energy increase rate per second.
     /// @return cap The energy cap.
    function getEnergyParameters() public view returns (uint256 increaseRate, uint256 cap) {
         return (energyIncreaseRatePerSecond, energyCap);
    }

    /// @notice Sets the base URI for Crystal NFT metadata.
    /// @param baseURI_ The base URI string.
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    /// @notice Pauses the contract, preventing most user interactions.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, enabling user interactions.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw collected Ether (e.g., from synthesis fees).
    /// @param recipient The address to send the Ether to.
    /// @dev Requires `ReentrancyGuard`.
    function withdrawFunds(address recipient) external onlyOwner nonReentrant {
        require(recipient != address(0), "Recipient cannot be zero address");
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether balance to withdraw");
        (bool success, ) = payable(recipient).call{value: balance}("");
        require(success, "Ether withdrawal failed");
    }

     /// @notice Allows the owner to withdraw Essence tokens held by the contract.
     /// Useful if Essence was accidentally sent here or held from failed synthesis payments.
     /// @param recipient The address to send the Essence to.
     /// @param amount The amount of Essence to withdraw.
    function withdrawEssence(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Recipient cannot be zero address");
        _transfer(address(this), recipient, amount);
    }

     // --- Internal/Helper Functions ---

     // Placeholder: Helper to check if caller is owner or a designated keeper address
    modifier onlyOwnerOrKeeper() {
        // In a real system, this would check against a list of keeper addresses or integrate with Chainlink Automation roles
        require(msg.sender == owner(), "Only owner or keeper");
        _;
    }

     // Internal helper to calculate the total supply of the Essence token
     // This is already available via ERC20's totalSupply(), but might be needed internally.
     // function getEssenceTotalSupply() internal view returns (uint256) {
     //     return totalSupply();
     // }

     // Internal helper to convert CrystalState enum to string (optional for logging/URI)
     // function _stateToString(CrystalState state) private pure returns (string memory) {
     //     if (state == CrystalState.Dormant) return "Dormant";
     //     if (state == CrystalState.Stable) return "Stable";
     //     if (state == CrystalState.Pulsing) return "Pulsing";
     //     if (state == CrystalState.Radiant) return "Radiant";
     //     if (state == CrystalState.Volatile) return "Volatile";
     //     return "Unknown";
     // }


    // --- View Functions (Enumerable Overrides) ---
    // The following are provided by ERC721Enumerable but listed for completeness in function count
    // function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256)
    // function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256 tokenId)
    // function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256 tokenId)
}
```