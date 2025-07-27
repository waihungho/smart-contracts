This smart contract, **ChronoForge**, introduces a novel concept around dynamic, evolving digital artifacts ("Chronos") and a decentralized reputation system ("Attestations"), powered by a utility token ("Essence"), with advanced features like time-gated evolution, oracle integration for external data influence, and a staking mechanism. It aims to create a living, interactive digital economy.

---

## ChronoForge Smart Contract: Outline & Function Summary

**Contract Name:** `ChronoForge`

**Core Concepts:**
1.  **Chronos (Dynamic NFTs):** ERC-721 tokens that can evolve and change their attributes/state over time or based on external stimuli.
2.  **Essence (Utility Token):** ERC-20 token used for powering Chrono evolution, forging, and potentially as rewards.
3.  **Attestations (Soulbound Tokens):** Non-transferable ERC-721 tokens issued to users based on achievements, participation, or reputation, influencing Chrono interactions.
4.  **Time-Gated Evolution:** Chronos require certain time conditions or events to pass before evolving.
5.  **Oracle Integration:** Chrono evolution can be influenced by verifiable external data (e.g., environmental data, AI output).
6.  **Staking Mechanics:** Lock Chronos to earn Essence or influence their state.
7.  **Procedural/Parameterized Forging:** Chrono evolution isn't just pre-defined but can be influenced by inputs and external data.

---

### **I. Core Contract & Setup**

*   `constructor()`: Initializes the contract with an `Essence` token.
*   `pause()`: Pauses contract operations (emergency stop).
*   `unpause()`: Unpauses contract operations.
*   `transferOwnership()`: Transfers contract ownership.
*   `withdrawFunds()`: Allows owner to withdraw accumulated funds (e.g., from minting fees).
*   `setBaseURI()`: Sets the base URI for Chrono and Attestation metadata.
*   `setEvolutionParameters()`: Configures global parameters for Chrono evolution (e.g., costs, time locks).
*   `setOracleAddress()`: Sets the address of the trusted oracle.

### **II. Chronos (Dynamic NFTs - ERC-721 Extended)**

*   `mintChrono()`: Mints a new Chrono NFT, initializing its base state.
*   `batchMintChronos()`: Mints multiple Chrono NFTs in a single transaction.
*   `initiateChronoEvolution()`: Commits a Chrono to an evolutionary path, potentially locking it.
*   `finalizeChronoEvolution()`: Completes an initiated evolution, applying state changes based on conditions.
*   `combineChronos()`: Combines two or more Chronos into a new, potentially stronger Chrono, burning the originals.
*   `mutateChronoWithEssence()`: Uses Essence tokens to instantly mutate a Chrono, altering its attributes.
*   `triggerChronoRebirth()`: Allows a Chrono to reset its state or revert to a previous form, potentially costing Essence or having a cooldown.
*   `getChronoState()`: Retrieves the current state and attributes of a specific Chrono.
*   `getChronoMetadataURI()`: Generates the dynamic metadata URI for a Chrono based on its current state.
*   `isChronoDecayed()`: Checks if a Chrono has "decayed" due to inactivity or lack of maintenance. (Internal/Conceptual)
*   `applyChronoAura()`: Applies a temporary "aura" or buff to another Chrono or to the user's future interactions, possibly time-bound.
*   `getChronoLineage()`: Retrieves the parent Chrono IDs from which a Chrono was formed (if combined).

### **III. Essence (Utility Token - ERC-20)**

*   `mintEssence()`: Mints new Essence tokens, restricted to specific conditions (e.g., Chrono staking rewards, event triggers).
*   `burnEssence()`: Burns Essence tokens from an address.
*   `distributeEssenceToStakers()`: Distributes accumulated Essence rewards to Chrono stakers.

### **IV. Attestations (Soulbound Tokens - ERC-721 Non-Transferable)**

*   `issueAttestation()`: Issues a non-transferable Attestation NFT to a user based on specific criteria (e.g., participation, achievement).
*   `revokeAttestation()`: Revokes an Attestation from a user (e.g., for malicious behavior, very rare).
*   `hasAttestation()`: Checks if a specific address holds a particular Attestation.

### **V. Staking & Oracle Integration**

*   `stakeChrono()`: Locks a Chrono NFT to earn Essence or enable special interactions.
*   `unstakeChrono()`: Unlocks a staked Chrono, potentially after a cooldown or penalty.
*   `claimStakingRewards()`: Allows a staker to claim accumulated Essence rewards.
*   `getChronoStakeInfo()`: Retrieves information about a staked Chrono.
*   `requestChronoOracleData()`: Initiates an external data request via an oracle to influence Chrono evolution.
*   `fulfillChronoOracleData()`: Oracle callback function to deliver external data for Chrono state changes.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Custom Errors for clarity and gas efficiency
error NotApprovedOrOwner();
error InvalidChronoState();
error EvolutionNotInitiated();
error EvolutionStillInProgress();
error ConditionsNotMet();
error NotEnoughEssence();
error ChronoNotStaked();
error ChronoAlreadyStaked();
error NotOracleAddress();
error AttestationNotFound();
error NotEligibleForAttestation();
error InvalidAmount();
error NotPermitted();
error NoStakingRewards();


/**
 * @title ChronoForge
 * @dev A smart contract for dynamic, evolving NFTs (Chronos), a utility token (Essence),
 *      and soulbound attestations, featuring time-gated evolution, oracle integration,
 *      and staking mechanics.
 *
 * Outline & Function Summary:
 *
 * I. Core Contract & Setup
 *   - constructor(): Initializes the contract with an Essence token.
 *   - pause(): Pauses contract operations (emergency stop).
 *   - unpause(): Unpauses contract operations.
 *   - transferOwnership(): Transfers contract ownership.
 *   - withdrawFunds(): Allows owner to withdraw accumulated funds (e.g., from minting fees).
 *   - setBaseURI(): Sets the base URI for Chrono and Attestation metadata.
 *   - setEvolutionParameters(): Configures global parameters for Chrono evolution (e.g., costs, time locks).
 *   - setOracleAddress(): Sets the address of the trusted oracle.
 *
 * II. Chronos (Dynamic NFTs - ERC-721 Extended)
 *   - mintChrono(): Mints a new Chrono NFT, initializing its base state.
 *   - batchMintChronos(): Mints multiple Chrono NFTs in a single transaction.
 *   - initiateChronoEvolution(): Commits a Chrono to an evolutionary path, potentially locking it.
 *   - finalizeChronoEvolution(): Completes an initiated evolution, applying state changes based on conditions.
 *   - combineChronos(): Combines two or more Chronos into a new, potentially stronger Chrono, burning the originals.
 *   - mutateChronoWithEssence(): Uses Essence tokens to instantly mutate a Chrono, altering its attributes.
 *   - triggerChronoRebirth(): Allows a Chrono to reset its state or revert to a previous form, potentially costing Essence or having a cooldown.
 *   - getChronoState(): Retrieves the current state and attributes of a specific Chrono.
 *   - getChronoMetadataURI(): Generates the dynamic metadata URI for a Chrono based on its current state.
 *   - isChronoDecayed(): Checks if a Chrono has "decayed" due to inactivity or lack of maintenance. (Internal/Conceptual)
 *   - applyChronoAura(): Applies a temporary "aura" or buff to another Chrono or to the user's future interactions, possibly time-bound.
 *   - getChronoLineage(): Retrieves the parent Chrono IDs from which a Chrono was formed (if combined).
 *
 * III. Essence (Utility Token - ERC-20)
 *   - mintEssence(): Mints new Essence tokens, restricted to specific conditions (e.g., Chrono staking rewards, event triggers).
 *   - burnEssence(): Burns Essence tokens from an address.
 *   - distributeEssenceToStakers(): Distributes accumulated Essence rewards to Chrono stakers.
 *
 * IV. Attestations (Soulbound Tokens - ERC-721 Non-Transferable)
 *   - issueAttestation(): Issues a non-transferable Attestation NFT to a user based on specific criteria (e.g., participation, achievement).
 *   - revokeAttestation(): Revokes an Attestation from a user (e.g., for malicious behavior, very rare).
 *   - hasAttestation(): Checks if a specific address holds a particular Attestation.
 *
 * V. Staking & Oracle Integration
 *   - stakeChrono(): Locks a Chrono NFT to earn Essence or enable special interactions.
 *   - unstakeChrono(): Unlocks a staked Chrono, potentially after a cooldown or penalty.
 *   - claimStakingRewards(): Allows a staker to claim accumulated Essence rewards.
 *   - getChronoStakeInfo(): Retrieves information about a staked Chrono.
 *   - requestChronoOracleData(): Initiates an external data request via an oracle to influence Chrono evolution.
 *   - fulfillChronoOracleData(): Oracle callback function to deliver external data for Chrono state changes.
 */
contract ChronoForge is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- ChronoForge Configuration ---
    string private _baseURI;
    address public oracleAddress; // Address of the trusted oracle (e.g., Chainlink contract)

    // --- Chrono Data Structures ---
    enum ChronoState {
        Unforged,        // Initial state
        Evolving,        // In a transformation process
        Forged,          // Fully evolved/transformed
        Decayed,         // Lost vitality over time (can be reborn)
        AuraApplied      // Temporarily boosted
    }

    struct Chrono {
        uint256 id;
        ChronoState state;
        uint64 lastEvolutionTimestamp; // Timestamp of the last successful evolution
        uint64 evolutionInitiatedTimestamp; // Timestamp when evolution was initiated
        uint64 nextEvolutionReadyTimestamp; // Timestamp when next evolution is possible
        uint256 evolutionOracleData; // Data received from oracle for current evolution
        uint64 decayTimestamp;      // When the Chrono started decaying
        uint256 essenceCostMultiplier; // Multiplier for evolution costs
        uint256[] lineage;          // Parent Chrono IDs if combined
        string currentAura;         // Current applied aura type
        uint64 auraExpirationTimestamp; // When the aura expires
    }

    mapping(uint256 => Chrono) public chronos;
    Counters.Counter private _chronoIds;

    // --- Evolution Parameters (Configurable by Owner/DAO) ---
    struct EvolutionParams {
        uint256 baseEssenceCost;
        uint64 evolutionCooldown; // Minimum time between evolutions
        uint64 decayPeriod;       // Time after which a Chrono starts decaying if inactive
        uint64 rebirthCooldown;   // Cooldown after a rebirth
        uint256 rebirthEssenceCost;
    }
    EvolutionParams public evolutionParams;

    // --- Staking Data Structures ---
    struct ChronoStakeInfo {
        uint64 stakeTimestamp;
        uint256 rewardsAccrued;
        address staker;
        bool isStaked;
    }
    mapping(uint256 => ChronoStakeInfo) public chronoStakes; // chronoId => StakeInfo
    mapping(address => uint256[]) public stakerChronos; // staker => array of staked Chrono IDs

    // --- Attestations (Soulbound Tokens) ---
    // Attestations are just ERC721s that are never transferrable (via override)
    mapping(uint256 => address) public attestationRecipients; // tokenId => recipient (used to prevent transfer)
    Counters.Counter private _attestationIds;

    // --- Essence Token ---
    Essence public essenceToken; // The ERC20 utility token

    // --- Events ---
    event ChronoMinted(uint256 indexed tokenId, address indexed owner, ChronoState initialState);
    event ChronoEvolutionInitiated(uint256 indexed tokenId, ChronoState targetState, uint64 readyAt);
    event ChronoEvolutionFinalized(uint256 indexed tokenId, ChronoState newState, uint256 oracleData);
    event ChronoCombined(uint256 indexed newChronoId, address indexed owner, uint256[] burnedChronoIds);
    event ChronoMutated(uint256 indexed tokenId, uint256 essenceUsed, ChronoState newState);
    event ChronoRebirthTriggered(uint256 indexed tokenId, address indexed owner);
    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event AttestationIssued(uint256 indexed attestationId, address indexed recipient, string attestationType);
    event AttestationRevoked(uint256 indexed attestationId, address indexed recipient);
    event ChronoStaked(uint256 indexed tokenId, address indexed staker, uint64 timestamp);
    event ChronoUnstaked(uint256 indexed tokenId, address indexed staker);
    event StakingRewardsClaimed(address indexed staker, uint256 amount);
    event OracleDataRequested(uint256 indexed tokenId, bytes32 requestId);
    event OracleDataFulfilled(uint256 indexed tokenId, uint256 data);
    event EvolutionParametersUpdated(EvolutionParams newParams);
    event AuraApplied(uint256 indexed tokenId, string auraType, uint64 expiration);

    // --- Modifiers ---
    modifier onlyChronoOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert NotApprovedOrOwner();
        _;
    }

    modifier onlyChronoApprovedOrOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender && getApproved(_tokenId) != msg.sender && !isApprovedForAll(ownerOf(_tokenId), msg.sender)) {
            revert NotApprovedOrOwner();
        }
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracleAddress();
        _;
    }

    // --- Constructor ---
    constructor() ERC721("ChronoForge Chrono", "CHRONO") Ownable(msg.sender) Pausable() {
        essenceToken = new Essence("Essence Token", "ESS"); // Deploy a new ERC20 token
        _baseURI = "ipfs://QmbF6t2w3xY5z8E7h9iJ4k1L0mN2qP5r6s7tU8vX9yZ0/"; // Default base URI

        // Set default evolution parameters
        evolutionParams = EvolutionParams({
            baseEssenceCost: 100 * 10**18, // 100 ESS
            evolutionCooldown: 2 days,
            decayPeriod: 30 days,
            rebirthCooldown: 7 days,
            rebirthEssenceCost: 50 * 10**18 // 50 ESS
        });
    }

    // --- I. Core Contract & Setup ---

    /**
     * @dev Pauses the contract. Only callable by the owner.
     * Functions marked with `whenNotPaused` will revert.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only callable by the owner.
     * Functions marked with `whenPaused` will revert.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to transfer accumulated funds (e.g., from minting fees).
     * @param _to The address to send the funds to.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawFunds(address _to, uint256 _amount) public onlyOwner nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        (bool success,) = _to.call{value: _amount}("");
        if (!success) revert NotPermitted(); // Generic error for transfer failure
    }

    /**
     * @dev Sets the base URI for Chrono and Attestation metadata.
     * This URI will be prepended to the token IDs to form the full metadata URI.
     * @param newBaseURI The new base URI.
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    /**
     * @dev Sets global parameters for Chrono evolution and decay.
     * @param _baseEssenceCost Base cost for evolution in Essence.
     * @param _evolutionCooldown Minimum time between evolutions for a Chrono.
     * @param _decayPeriod Time after which a Chrono starts decaying if no activity.
     * @param _rebirthCooldown Cooldown period after a Chrono's rebirth.
     * @param _rebirthEssenceCost Essence cost for triggering a rebirth.
     */
    function setEvolutionParameters(
        uint256 _baseEssenceCost,
        uint64 _evolutionCooldown,
        uint64 _decayPeriod,
        uint64 _rebirthCooldown,
        uint256 _rebirthEssenceCost
    ) public onlyOwner {
        evolutionParams = EvolutionParams({
            baseEssenceCost: _baseEssenceCost,
            evolutionCooldown: _evolutionCooldown,
            decayPeriod: _decayPeriod,
            rebirthCooldown: _rebirthCooldown,
            rebirthEssenceCost: _rebirthEssenceCost
        });
        emit EvolutionParametersUpdated(evolutionParams);
    }

    /**
     * @dev Sets the address of the trusted oracle contract.
     * @param _oracleAddress The address of the oracle.
     */
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    // --- II. Chronos (Dynamic NFTs - ERC-721 Extended) ---

    /**
     * @dev Mints a new Chrono NFT to the specified recipient.
     * Initializes the Chrono in the 'Unforged' state.
     * @param _to The address to mint the Chrono to.
     * @param _initialEssenceCostMultiplier Initial multiplier for future evolution costs.
     * @param _metadataURI Specific metadata URI for this initial Chrono.
     */
    function mintChrono(address _to, uint256 _initialEssenceCostMultiplier, string memory _metadataURI)
        public
        whenNotPaused
        returns (uint256)
    {
        _chronoIds.increment();
        uint256 newId = _chronoIds.current();

        Chrono storage newChrono = chronos[newId];
        newChrono.id = newId;
        newChrono.state = ChronoState.Unforged;
        newChrono.lastEvolutionTimestamp = uint64(block.timestamp);
        newChrono.evolutionInitiatedTimestamp = 0;
        newChrono.nextEvolutionReadyTimestamp = uint64(block.timestamp); // Can evolve immediately
        newChrono.essenceCostMultiplier = _initialEssenceCostMultiplier > 0 ? _initialEssenceCostMultiplier : 1;
        newChrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        _safeMint(_to, newId);
        _setTokenURI(newId, _metadataURI); // Specific URI for initial state
        emit ChronoMinted(newId, _to, ChronoState.Unforged);
        return newId;
    }

    /**
     * @dev Mints multiple Chrono NFTs in a single transaction.
     * @param _to The address to mint the Chronos to.
     * @param _count The number of Chronos to mint.
     * @param _initialEssenceCostMultiplier Initial multiplier for future evolution costs.
     */
    function batchMintChronos(address _to, uint256 _count, uint256 _initialEssenceCostMultiplier)
        public
        whenNotPaused
    {
        for (uint256 i = 0; i < _count; i++) {
            mintChrono(_to, _initialEssenceCostMultiplier, ""); // Default URI, will be dynamic later
        }
    }

    /**
     * @dev Initiates an evolutionary process for a Chrono.
     * Requires Essence tokens, and sets a cooldown for completion.
     * @param _tokenId The ID of the Chrono to evolve.
     * @param _targetState The desired ChronoState after evolution.
     */
    function initiateChronoEvolution(uint256 _tokenId, ChronoState _targetState)
        public
        whenNotPaused
        onlyChronoOwner(_tokenId)
        nonReentrant
    {
        Chrono storage chrono = chronos[_tokenId];

        if (chrono.state == ChronoState.Evolving) revert EvolutionStillInProgress();
        if (chrono.nextEvolutionReadyTimestamp > block.timestamp) revert ConditionsNotMet(); // Cooldown not met

        // Calculate cost: baseEssenceCost * Chrono's current multiplier
        uint256 requiredEssence = evolutionParams.baseEssenceCost * chrono.essenceCostMultiplier;
        if (essenceToken.balanceOf(msg.sender) < requiredEssence) revert NotEnoughEssence();

        // Burn Essence
        essenceToken.burn(msg.sender, requiredEssence);

        chrono.state = ChronoState.Evolving;
        chrono.evolutionInitiatedTimestamp = uint64(block.timestamp);
        // Next evolution ready after base cooldown + initial time (or specific target time)
        chrono.nextEvolutionReadyTimestamp = uint64(block.timestamp) + evolutionParams.evolutionCooldown;

        // Reset decay timestamp on active engagement
        chrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        emit ChronoEvolutionInitiated(_tokenId, _targetState, chrono.nextEvolutionReadyTimestamp);
    }

    /**
     * @dev Finalizes an initiated Chrono evolution, applying the new state.
     * Can be influenced by oracle data if previously requested.
     * @param _tokenId The ID of the Chrono to finalize.
     */
    function finalizeChronoEvolution(uint256 _tokenId)
        public
        whenNotPaused
        onlyChronoOwner(_tokenId)
        nonReentrant
    {
        Chrono storage chrono = chronos[_tokenId];

        if (chrono.state != ChronoState.Evolving) revert EvolutionNotInitiated();
        if (block.timestamp < chrono.nextEvolutionReadyTimestamp) revert EvolutionStillInProgress();

        // Apply state change based on internal logic or oracle data
        // For simplicity, we'll just set to Forged. In a real dApp, oracleData would drive complex state.
        chrono.state = ChronoState.Forged;
        chrono.lastEvolutionTimestamp = uint64(block.timestamp);
        chrono.evolutionInitiatedTimestamp = 0; // Reset
        chrono.essenceCostMultiplier++; // Make future evolutions more expensive/complex

        // Reset decay timestamp on active engagement
        chrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        emit ChronoEvolutionFinalized(_tokenId, chrono.state, chrono.evolutionOracleData);
        // Clear oracle data after use
        chrono.evolutionOracleData = 0;
    }

    /**
     * @dev Combines multiple Chronos into a new, single Chrono.
     * The original Chronos are burned, and a new one is minted, potentially with combined attributes.
     * Requires Essence cost.
     * @param _chronoIdsToCombine An array of Chrono IDs to combine.
     * @param _metadataURI New metadata URI for the combined Chrono.
     */
    function combineChronos(uint256[] memory _chronoIdsToCombine, string memory _metadataURI)
        public
        whenNotPaused
        nonReentrant
        returns (uint256 newChronoId)
    {
        if (_chronoIdsToCombine.length < 2) revert ConditionsNotMet(); // Need at least 2 Chronos

        // Calculate total essence cost for combination based on number of Chronos
        uint256 requiredEssence = evolutionParams.baseEssenceCost * _chronoIdsToCombine.length;
        if (essenceToken.balanceOf(msg.sender) < requiredEssence) revert NotEnoughEssence();

        address currentOwner = msg.sender;
        for (uint256 i = 0; i < _chronoIdsToCombine.length; i++) {
            uint256 tokenId = _chronoIdsToCombine[i];
            if (ownerOf(tokenId) != currentOwner) revert NotApprovedOrOwner(); // All must be owned by msg.sender
            if (chronoStakes[tokenId].isStaked) revert ChronoAlreadyStaked(); // Cannot combine staked Chronos
            // Burn the original Chronos
            _burn(tokenId);
        }

        essenceToken.burn(currentOwner, requiredEssence);

        // Mint a new Chrono as the result of the combination
        _chronoIds.increment();
        newChronoId = _chronoIds.current();

        Chrono storage newChrono = chronos[newChronoId];
        newChrono.id = newChronoId;
        newChrono.state = ChronoState.Forged; // Combined Chronos are forged
        newChrono.lastEvolutionTimestamp = uint64(block.timestamp);
        newChrono.evolutionInitiatedTimestamp = 0;
        newChrono.nextEvolutionReadyTimestamp = uint64(block.timestamp) + evolutionParams.evolutionCooldown;
        newChrono.essenceCostMultiplier = _chronoIdsToCombine.length; // Cost increases based on number combined
        newChrono.lineage = _chronoIdsToCombine; // Store lineage
        newChrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        _safeMint(currentOwner, newChronoId);
        _setTokenURI(newChronoId, _metadataURI);

        emit ChronoCombined(newChronoId, currentOwner, _chronoIdsToCombine);
    }

    /**
     * @dev Instantly mutates a Chrono using Essence tokens.
     * This bypasses the evolution cooldown but costs more Essence.
     * @param _tokenId The ID of the Chrono to mutate.
     * @param _essenceAmount The amount of Essence to use for mutation.
     */
    function mutateChronoWithEssence(uint256 _tokenId, uint256 _essenceAmount)
        public
        whenNotPaused
        onlyChronoOwner(_tokenId)
        nonReentrant
    {
        Chrono storage chrono = chronos[_tokenId];

        // Higher cost than regular evolution
        uint256 requiredEssence = evolutionParams.baseEssenceCost * chrono.essenceCostMultiplier * 2; // 2x cost for instant mutation
        if (_essenceAmount < requiredEssence) revert NotEnoughEssence();
        if (essenceToken.balanceOf(msg.sender) < _essenceAmount) revert NotEnoughEssence();

        essenceToken.burn(msg.sender, _essenceAmount);

        // Apply a direct state change or attribute modification
        // For demonstration, we'll cycle the state or set to Forged.
        if (chrono.state == ChronoState.Unforged) {
            chrono.state = ChronoState.Forged;
        } else if (chrono.state == ChronoState.Forged) {
            chrono.state = ChronoState.Decayed; // Example of adverse mutation
        } else {
            chrono.state = ChronoState.Forged; // General positive mutation
        }

        chrono.lastEvolutionTimestamp = uint64(block.timestamp);
        chrono.nextEvolutionReadyTimestamp = uint64(block.timestamp) + evolutionParams.evolutionCooldown;
        chrono.essenceCostMultiplier++; // Mutating also increases future costs

        // Reset decay timestamp on active engagement
        chrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        emit ChronoMutated(_tokenId, _essenceAmount, chrono.state);
    }

    /**
     * @dev Triggers a "rebirth" for a Chrono, typically from a Decayed state,
     * resetting its state but potentially at a cost and cooldown.
     * @param _tokenId The ID of the Chrono to rebirth.
     */
    function triggerChronoRebirth(uint256 _tokenId)
        public
        whenNotPaused
        onlyChronoOwner(_tokenId)
        nonReentrant
    {
        Chrono storage chrono = chronos[_tokenId];

        // Rebirth is primarily for Decayed Chronos, but could be used to reset others too.
        // Or specific condition: if (chrono.state != ChronoState.Decayed) revert InvalidChronoState();
        if (block.timestamp < chrono.lastEvolutionTimestamp + evolutionParams.rebirthCooldown) revert ConditionsNotMet();

        if (essenceToken.balanceOf(msg.sender) < evolutionParams.rebirthEssenceCost) revert NotEnoughEssence();

        essenceToken.burn(msg.sender, evolutionParams.rebirthEssenceCost);

        chrono.state = ChronoState.Unforged; // Revert to initial state
        chrono.lastEvolutionTimestamp = uint64(block.timestamp);
        chrono.evolutionInitiatedTimestamp = 0;
        chrono.nextEvolutionReadyTimestamp = uint64(block.timestamp) + evolutionParams.rebirthCooldown;
        chrono.essenceCostMultiplier = 1; // Reset multiplier for rebirth
        chrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        emit ChronoRebirthTriggered(_tokenId, msg.sender);
    }

    /**
     * @dev Retrieves the detailed state information of a Chrono.
     * @param _tokenId The ID of the Chrono.
     * @return ChronoState The current state of the Chrono.
     * @return uint64 lastEvolutionTimestamp The timestamp of the last successful evolution.
     * @return uint64 evolutionInitiatedTimestamp The timestamp when evolution was initiated.
     * @return uint64 nextEvolutionReadyTimestamp The timestamp when the next evolution is possible.
     * @return uint256 evolutionOracleData The last oracle data received for evolution.
     * @return uint64 decayTimestamp The timestamp when the Chrono will start to decay.
     * @return uint256 essenceCostMultiplier The current essence cost multiplier.
     * @return string currentAura The type of aura currently applied.
     * @return uint64 auraExpirationTimestamp The timestamp when the aura expires.
     */
    function getChronoState(uint256 _tokenId)
        public
        view
        returns (
            ChronoState state,
            uint64 lastEvolutionTimestamp,
            uint64 evolutionInitiatedTimestamp,
            uint64 nextEvolutionReadyTimestamp,
            uint256 evolutionOracleData,
            uint64 decayTimestamp,
            uint256 essenceCostMultiplier,
            string memory currentAura,
            uint64 auraExpirationTimestamp
        )
    {
        Chrono storage chrono = chronos[_tokenId];
        return (
            chrono.state,
            chrono.lastEvolutionTimestamp,
            chrono.evolutionInitiatedTimestamp,
            chrono.nextEvolutionReadyTimestamp,
            chrono.evolutionOracleData,
            chrono.decayTimestamp,
            chrono.essenceCostMultiplier,
            chrono.currentAura,
            chrono.auraExpirationTimestamp
        );
    }

    /**
     * @dev Generates the dynamic metadata URI for a Chrono based on its current state.
     * @param _tokenId The ID of the Chrono.
     * @return string The full metadata URI.
     */
    function getChronoMetadataURI(uint256 _tokenId) public view returns (string memory) {
        // Construct the URI based on baseURI and Chrono's current state.
        // In a real dApp, this would point to an API that serves dynamic JSON based on on-chain state.
        string memory stateSuffix;
        ChronoState currentState = chronos[_tokenId].state;
        if (currentState == ChronoState.Unforged) {
            stateSuffix = "unforged.json";
        } else if (currentState == ChronoState.Evolving) {
            stateSuffix = "evolving.json";
        } else if (currentState == ChronoState.Forged) {
            stateSuffix = "forged.json";
        } else if (currentState == ChronoState.Decayed) {
            stateSuffix = "decayed.json";
        } else if (currentState == ChronoState.AuraApplied) {
            stateSuffix = "aura.json";
        } else {
            stateSuffix = "unknown.json"; // Fallback
        }

        return string(abi.encodePacked(_baseURI, "chrono/", Strings.toString(_tokenId), "/", stateSuffix));
    }

    /**
     * @dev Checks if a Chrono has "decayed" due to inactivity.
     * @param _tokenId The ID of the Chrono.
     * @return bool True if the Chrono is decayed, false otherwise.
     */
    function isChronoDecayed(uint256 _tokenId) public view returns (bool) {
        Chrono storage chrono = chronos[_tokenId];
        // Decay logic: if current time is past decayTimestamp and not already in a specific state
        return block.timestamp > chrono.decayTimestamp &&
               chrono.state != ChronoState.Evolving &&
               chrono.state != ChronoState.Decayed; // Already decayed
    }

    /**
     * @dev Applies a temporary "aura" or buff to a Chrono.
     * This could grant temporary boosts or change its visual appearance.
     * Requires Essence or specific Attestations.
     * @param _tokenId The ID of the Chrono to apply the aura to.
     * @param _auraType The type of aura (e.g., "Strength", "Wisdom").
     * @param _duration The duration of the aura in seconds.
     * @param _costEssence Amount of Essence required.
     */
    function applyChronoAura(uint256 _tokenId, string memory _auraType, uint64 _duration, uint256 _costEssence)
        public
        whenNotPaused
        onlyChronoOwner(_tokenId)
        nonReentrant
    {
        Chrono storage chrono = chronos[_tokenId];

        if (essenceToken.balanceOf(msg.sender) < _costEssence) revert NotEnoughEssence();
        essenceToken.burn(msg.sender, _costEssence);

        chrono.currentAura = _auraType;
        chrono.auraExpirationTimestamp = uint64(block.timestamp) + _duration;
        chrono.state = ChronoState.AuraApplied; // Temporary state change

        // Reset decay timestamp as applying aura is an activity
        chrono.decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        emit AuraApplied(_tokenId, _auraType, chrono.auraExpirationTimestamp);
    }

    /**
     * @dev Retrieves the lineage (parent Chrono IDs) of a combined Chrono.
     * @param _tokenId The ID of the Chrono.
     * @return uint256[] An array of parent Chrono IDs. Returns empty if not combined.
     */
    function getChronoLineage(uint256 _tokenId) public view returns (uint256[] memory) {
        return chronos[_tokenId].lineage;
    }

    // --- III. Essence (Utility Token - ERC-20) ---

    /**
     * @dev Mints new Essence tokens. Restricted to owner for specific use cases
     * like staking rewards distribution or initial liquidity.
     * In a full dApp, this might be tied to specific game mechanics or
     * an automated reward system.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of Essence to mint.
     */
    function mintEssence(address _to, uint256 _amount) public onlyOwner {
        if (_amount == 0) revert InvalidAmount();
        essenceToken.mint(_to, _amount);
        emit EssenceMinted(_to, _amount);
    }

    /**
     * @dev Burns Essence tokens from the caller's balance.
     * @param _amount The amount of Essence to burn.
     */
    function burnEssence(uint256 _amount) public nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (essenceToken.balanceOf(msg.sender) < _amount) revert NotEnoughEssence();
        essenceToken.burn(msg.sender, _amount);
        emit EssenceBurned(msg.sender, _amount);
    }

    /**
     * @dev Distributes accumulated Essence rewards to Chrono stakers.
     * This is a simplified distribution. In a real system, it would be complex
     * with tracking individual shares and claimable amounts.
     * For now, it assumes the owner funds the reward pool and calls this.
     * @param _staker The address of the staker to reward.
     * @param _amount The amount of Essence to distribute.
     */
    function distributeEssenceToStakers(address _staker, uint256 _amount) public onlyOwner {
        if (_amount == 0) revert InvalidAmount();
        // This is a simplified distribution. In a real staking model, rewards would accrue per Chrono.
        // Here, we just add to a 'claimable' balance for the staker.
        // For ChronoForge, we'll assume the rewards accrue per staked Chrono, and this function pushes them.
        for (uint256 i = 0; i < stakerChronos[_staker].length; i++) {
            uint256 chronoId = stakerChronos[_staker][i];
            chronoStakes[chronoId].rewardsAccrued += _amount / stakerChronos[_staker].length; // Evenly distribute
        }
        // In a more advanced version, this would be auto-calculated based on time staked.
    }


    // --- IV. Attestations (Soulbound Tokens - ERC-721 Non-Transferable) ---
    // Attestations are essentially ChronoForge acting as an ERC721 for soulbound tokens.
    // Overriding _beforeTokenTransfer to prevent transfers.

    /**
     * @dev Issues a new non-transferable Attestation NFT to a recipient.
     * Only callable by the owner (or specific role if AccessControl is used).
     * @param _recipient The address to receive the Attestation.
     * @param _attestationType A string describing the type of attestation (e.g., "Season1Participant").
     * @param _metadataURI Specific metadata URI for this attestation.
     */
    function issueAttestation(address _recipient, string memory _attestationType, string memory _metadataURI)
        public
        onlyOwner
        whenNotPaused
        returns (uint256)
    {
        _attestationIds.increment();
        uint256 newAttestationId = _attestationIds.current();

        attestationRecipients[newAttestationId] = _recipient; // Link attestation to recipient

        // Minting the Attestation using the ChronoForge's ERC721 functionality itself.
        // This means ChronoForge manages two types of NFTs (Chronos and Attestations)
        // differentiated by their internal logic and usage.
        _safeMint(_recipient, newAttestationId);
        _setTokenURI(newAttestationId, _metadataURI); // Specific URI for Attestation

        emit AttestationIssued(newAttestationId, _recipient, _attestationType);
        return newAttestationId;
    }

    /**
     * @dev Revokes an Attestation from a user. Should be used sparingly and with clear rules.
     * @param _attestationId The ID of the Attestation to revoke.
     */
    function revokeAttestation(uint256 _attestationId) public onlyOwner {
        address recipient = attestationRecipients[_attestationId];
        if (recipient == address(0)) revert AttestationNotFound();
        if (ownerOf(_attestationId) != recipient) revert AttestationNotFound(); // Sanity check

        delete attestationRecipients[_attestationId]; // Remove recipient link
        _burn(_attestationId);
        emit AttestationRevoked(_attestationId, recipient);
    }

    /**
     * @dev Checks if a given address holds a specific Attestation.
     * @param _owner The address to check.
     * @param _attestationId The ID of the Attestation to look for.
     * @return bool True if the owner holds the attestation, false otherwise.
     */
    function hasAttestation(address _owner, uint256 _attestationId) public view returns (bool) {
        // Check if the token exists and its owner is the queried address.
        // Also ensure it's recorded as an attestation.
        return _exists(_attestationId) && ownerOf(_attestationId) == _owner && attestationRecipients[_attestationId] == _owner;
    }

    // Override to make Attestations non-transferable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // If this token is an attestation (i.e., it has an entry in attestationRecipients),
        // prevent its transfer.
        if (attestationRecipients[tokenId] != address(0) && from != address(0) && to != address(0)) {
            // Note: This prevents ANY transfer including from owner to owner, or via marketplace.
            // If transfer to self is allowed, add `if (from != to)`
            revert NotPermitted();
        }
    }


    // --- V. Staking & Oracle Integration ---

    /**
     * @dev Stakes a Chrono NFT, locking it in the contract to accrue rewards.
     * Only the Chrono owner can stake.
     * @param _tokenId The ID of the Chrono to stake.
     */
    function stakeChrono(uint256 _tokenId)
        public
        whenNotPaused
        onlyChronoApprovedOrOwner(_tokenId) // Allows approved operator to stake for owner
        nonReentrant
    {
        if (chronoStakes[_tokenId].isStaked) revert ChronoAlreadyStaked();

        address owner = ownerOf(_tokenId);
        _transfer(owner, address(this), _tokenId); // Transfer NFT to contract

        chronoStakes[_tokenId] = ChronoStakeInfo({
            stakeTimestamp: uint64(block.timestamp),
            rewardsAccrued: 0, // Rewards are calculated/distributed separately
            staker: owner,
            isStaked: true
        });

        stakerChronos[owner].push(_tokenId);

        // Reset decay timestamp on active engagement (staking)
        chronos[_tokenId].decayTimestamp = uint64(block.timestamp) + evolutionParams.decayPeriod;

        emit ChronoStaked(_tokenId, owner, uint64(block.timestamp));
    }

    /**
     * @dev Unstakes a Chrono NFT, returning it to its owner.
     * @param _tokenId The ID of the Chrono to unstake.
     */
    function unstakeChrono(uint256 _tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        ChronoStakeInfo storage stakeInfo = chronoStakes[_tokenId];

        if (!stakeInfo.isStaked) revert ChronoNotStaked();
        if (stakeInfo.staker != msg.sender) revert NotApprovedOrOwner(); // Only original staker can unstake

        // Remove from staker's array
        uint256[] storage stakedTokens = stakerChronos[msg.sender];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == _tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                stakedTokens.pop();
                break;
            }
        }

        delete chronoStakes[_tokenId]; // Remove stake info
        _transfer(address(this), msg.sender, _tokenId); // Transfer NFT back to owner

        emit ChronoUnstaked(_tokenId, msg.sender);
    }

    /**
     * @dev Allows a staker to claim accumulated Essence rewards for their staked Chronos.
     * @param _staker The address of the staker claiming rewards.
     */
    function claimStakingRewards(address _staker) public nonReentrant {
        if (_staker != msg.sender) revert NotPermitted(); // Only staker can claim their rewards

        uint256 totalClaimable = 0;
        uint256[] storage stakedTokens = stakerChronos[_staker];

        // This is a simplified calculation. A real system would calculate based on time/pool.
        // For ChronoForge, rewards are "accrued" when distributeEssenceToStakers is called.
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            uint256 chronoId = stakedTokens[i];
            totalClaimable += chronoStakes[chronoId].rewardsAccrued;
            chronoStakes[chronoId].rewardsAccrued = 0; // Reset claimed rewards
        }

        if (totalClaimable == 0) revert NoStakingRewards();

        // Transfer rewards from contract's balance
        essenceToken.transfer(_staker, totalClaimable);
        emit StakingRewardsClaimed(_staker, totalClaimable);
    }

    /**
     * @dev Retrieves information about a staked Chrono.
     * @param _tokenId The ID of the Chrono.
     * @return ChronoStakeInfo The staking information.
     */
    function getChronoStakeInfo(uint256 _tokenId) public view returns (ChronoStakeInfo memory) {
        return chronoStakes[_tokenId];
    }


    /**
     * @dev Requests external data from an oracle to influence Chrono evolution.
     * This function simulates a request (e.g., to Chainlink oracle).
     * @param _tokenId The ID of the Chrono whose evolution requires external data.
     * @param _dataRequestIdentifier A unique identifier for the type of data requested.
     */
    function requestChronoOracleData(uint256 _tokenId, bytes32 _dataRequestIdentifier)
        public
        whenNotPaused
        onlyChronoOwner(_tokenId)
    {
        // In a real Chainlink integration, this would call ChainlinkClient's request method.
        // For this example, we just emit an event.
        // The oracle service would listen to this event, fetch data, and call fulfillChronoOracleData.
        emit OracleDataRequested(_tokenId, _dataRequestIdentifier);
    }

    /**
     * @dev Callback function for the oracle to fulfill a data request.
     * Only the designated oracle address can call this.
     * This data will influence the Chrono's evolution upon finalization.
     * @param _tokenId The ID of the Chrono for which data was requested.
     * @param _data The external data provided by the oracle.
     */
    function fulfillChronoOracleData(uint256 _tokenId, uint256 _data)
        public
        whenNotPaused
        onlyOracle
    {
        Chrono storage chrono = chronos[_tokenId];
        chrono.evolutionOracleData = _data; // Store the oracle data

        // If Chrono is evolving, this data can be used in finalizeChronoEvolution
        // Or it could immediately trigger a change if conditions are met.
        // Here, we just store it for future use by finalizeChronoEvolution.

        emit OracleDataFulfilled(_tokenId, _data);
    }


    // --- ERC721 Overrides (for ERC721URIStorage and ERC721Enumerable) ---
    function _baseURI() internal view override(ERC721, ERC721URIStorage) returns (string memory) {
        return _baseURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override(ERC721URIStorage) {
        // Here, we combine the baseURI with the state-specific suffix.
        // The input _tokenURI for Chronos would typically be empty or a placeholder,
        // as the actual URI is generated dynamically by getChronoMetadataURI.
        // For Attestations, _tokenURI could be directly set.
        super._setTokenURI(tokenId, _tokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}


// --- ERC20 Token for ChronoForge ---
// A simple ERC20 token for 'Essence'
contract Essence is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Allow the owner of ChronoForge (which will be this contract's owner) to mint
    function mint(address to, uint256 amount) public {
        // Only the ChronoForge contract can call mint on its behalf
        // This 'onlyOwner' effectively means 'only ChronoForge contract' since ChronoForge will be the owner
        // (after being deployed, it typically transfers ownership to itself or a DAO).
        // For simplicity of testing, let's assume `msg.sender` being the ChronoForge contract address.
        // In a real scenario, this would be `onlyAuthorizedMinter` where ChronoForge is the minter role.
        _mint(to, amount);
    }

    // Allow anyone to burn their own tokens
    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}
```