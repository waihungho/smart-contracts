This smart contract, "The Chronicle Weave," introduces a novel ecosystem where users mint and interact with "Chronicle Strands" (NFTs) that represent conceptual moments or data points. These strands possess an inherent "Resonance Frequency" and "Vibrancy." The core mechanic revolves around "Resonance Pulses," where users can initiate a pulse at a specific frequency, causing nearby strands to "resonate" and gain "Vibrancy" and "Echoes." Strands naturally decay in vibrancy, requiring "Catalyst" (an ERC-20 token) to maintain or boost them. This creates a dynamic, interconnected network where the "value" and "activity" of an NFT are emergent properties of its interaction within the "Weave," rather than just static ownership.

It's designed to be a living, evolving on-chain narrative or data fabric, encouraging strategic interaction, curation, and the creation of "resonant communities."

---

## **ChronicleWeave: Contract Outline and Function Summary**

**Contract Name:** `ChronicleWeave`

**Core Concepts:**
1.  **Chronicle Strands (ERC-721):** Unique NFTs representing conceptual data points or moments, each with a `resonanceFrequency`, `vibrancyScore`, and `echoCount`.
2.  **Catalyst (ERC-20):** A fungible token crucial for interacting with the Weave: minting strands, recharging vibrancy, modulating frequencies, and amplifying resonance.
3.  **Resonance Mechanics:** The central dynamic. Strands "resonate" when a `ResonancePulse` is initiated at or near their frequency. Resonating increases vibrancy and echoes.
4.  **Vibrancy Decay & Rejuvenation:** Strands naturally lose vibrancy over time, requiring Catalyst to stay "active" and impactful.
5.  **Emergent Properties:** The "value" or "significance" of a Strand is not fixed but dynamically influenced by its interaction within the Weave.

---

**I. Core Components (Interfaces & Standard Libraries):**
*   `ERC721Enumerable`: For NFT enumeration and lookup.
*   `ERC721URIStorage`: For managing NFT metadata URIs.
*   `ERC20`: For the fungible Catalyst token.
*   `Ownable`: For administrative control (initially, could evolve to DAO).

**II. Structs & Enums:**
*   `ChronicleStrand`: Defines the properties of an individual NFT.
*   `ResonancePulseDetail`: (Internal) Stores data about a specific resonance event.

**III. State Variables:**
*   **NFT Specific:** `_strandIdCounter`, `strands` (mapping), `_uriBase`.
*   **Token Specific:** `catalystSupply`.
*   **System Parameters:** `vibrancyDecayRatePerDay`, `resonanceMatchThreshold`, `mintStrandCost`, `rechargeVibrancyCostPerPoint`, `modulateFrequencyCost`, `echoResonanceCost`, `catalystEmissionRate`.
*   **Global Weave State:** `totalActiveResonanceEnergy`, `frequencyEchoCounts`.
*   **Event Loggers:** `resonancePulseEvents`.

**IV. Events:**
*   `StrandMinted`: When a new Chronicle Strand is created.
*   `ResonanceInitiated`: When a Resonance Pulse successfully activates strands.
*   `VibrancyRecharged`: When a strand's vibrancy is restored.
*   `FrequencyModulated`: When a strand's frequency is changed.
*   `ResonanceEchoed`: When a user amplifies an existing resonance event.
*   `SystemParameterUpdated`: When an admin parameter is changed.
*   `CatalystMinted`: When Catalyst tokens are issued.
*   `CatalystBurned`: When Catalyst tokens are consumed.

**V. Functions (29 Functions):**

**A. Chronicle Strand (NFT) Management:**
1.  `constructor(string memory name, string memory symbol)`: Initializes the contract, ERC-721, ERC-20, and sets initial owner/parameters.
2.  `mintChronicleStrand(uint256 _resonanceFrequency, string memory _tokenURI) returns (uint256)`: Mints a new Chronicle Strand NFT, deducting `mintStrandCost` in Catalyst.
3.  `getStrandDetails(uint256 _strandId) public view returns (ChronicleStrand memory)`: Retrieves all details of a specific Strand, calculating current vibrancy.
4.  `getCurrentVibrancy(uint256 _strandId) public view returns (uint256)`: Calculates and returns the *current* vibrancy score of a strand, accounting for decay.
5.  `tokenURI(uint256 tokenId) public view virtual override returns (string memory)`: Overrides ERC721URIStorage to provide token URI.
6.  `exists(uint256 tokenId) public view returns (bool)`: Checks if a strand ID exists (from ERC721).
7.  `totalSupply() public view returns (uint256)`: Returns the total number of minted strands (from ERC721Enumerable).
8.  `ownerOf(uint256 tokenId) public view virtual override returns (address)`: Returns the owner of a strand (from ERC721).
9.  `balanceOf(address owner) public view virtual override returns (uint256)`: Returns the number of strands an address owns (from ERC721).

**B. Resonance Mechanics:**
10. `initiateResonancePulse(uint256 _targetFrequency, uint256 _pulseStrength) returns (uint256)`: The core interaction. Initiates a pulse. Finds all active strands within `resonanceMatchThreshold` of `_targetFrequency`, boosts their vibrancy/echoes. Consumes Catalyst proportional to `_pulseStrength`.
11. `getStrandsMatchingFrequency(uint256 _targetFrequency) public view returns (uint256[] memory)`: Helper to find all currently active strands that would resonate with a given frequency. (Note: For efficiency, this might be limited in scope or require off-chain indexing for large datasets).
12. `rechargeStrandVibrancy(uint256 _strandId, uint256 _pointsToRecharge)`: Allows a Strand owner to spend Catalyst to restore their strand's vibrancy.
13. `modulateStrandFrequency(uint256 _strandId, uint256 _newFrequency)`: Allows a Strand owner to change their strand's `resonanceFrequency`, costing Catalyst.
14. `echoResonance(uint256 _pulseId)`: Allows any user to "echo" a previous resonance pulse, further boosting the vibrancy/echoes of participating strands, costing Catalyst.

**C. Catalyst Token Management (ERC-20 Overrides & Extensions):**
15. `name() public view virtual override returns (string memory)`: Returns the token name (from ERC20).
16. `symbol() public view virtual override returns (string memory)`: Returns the token symbol (from ERC20).
17. `decimals() public view virtual override returns (uint8)`: Returns the token decimals (from ERC20).
18. `totalSupply() public view virtual override returns (uint256)`: Returns the total Catalyst supply (from ERC20).
19. `balanceOf(address account) public view virtual override returns (uint256)`: Returns an account's Catalyst balance (from ERC20).
20. `transfer(address to, uint256 amount) public virtual override returns (bool)`: Transfers Catalyst (from ERC20).
21. `approve(address spender, uint256 amount) public virtual override returns (bool)`: Approves spender for Catalyst (from ERC20).
22. `transferFrom(address from, address to, uint256 amount) public virtual override returns (bool)`: Transfers Catalyst on behalf of an approved sender (from ERC20).
23. `allowance(address owner, address spender) public view virtual override returns (uint256)`: Returns allowance of a spender (from ERC20).
24. `_mintCatalyst(address account, uint256 amount)`: Internal function to mint new Catalyst tokens.
25. `_burnCatalyst(address account, uint256 amount)`: Internal function to burn Catalyst tokens.

**D. Weave Analytics & Global State:**
26. `getGlobalWeaveMetrics() public view returns (uint256 _totalStrands, uint256 _totalActiveResonanceEnergy, uint256 _catalystSupply)`: Provides key global statistics about the Weave.
27. `getTopResonantFrequencies(uint256 _count) public view returns (uint256[] memory)`: Returns a list of the top N most echoed frequencies. (Simplistic implementation, might require off-chain sorting for large datasets).

**E. Administration & Governance (Initially Owner-Only):**
28. `setSystemParameter(bytes32 _parameterName, uint256 _newValue)`: Allows the owner to update key system parameters like decay rates, costs, and thresholds.
29. `withdrawContractBalance() payable` : Allows the contract owner to withdraw any ETH accumulated (e.g., from future fees, though not implemented in this version for complexity).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For Math.abs

/**
 * @title ChronicleWeave
 * @dev A novel ecosystem where users mint and interact with "Chronicle Strands" (NFTs) that represent conceptual moments or data points.
 * These strands possess an inherent "Resonance Frequency" and "Vibrancy." The core mechanic revolves around "Resonance Pulses,"
 * where users can initiate a pulse at a specific frequency, causing nearby strands to "resonate" and gain "Vibrancy" and "Echoes."
 * Strands naturally decay in vibrancy, requiring "Catalyst" (an ERC-20 token) to maintain or boost them. This creates a dynamic,
 * interconnected network where the "value" and "activity" of an NFT are emergent properties of its interaction within the "Weave."
 */
contract ChronicleWeave is ERC721Enumerable, ERC721URIStorage, ERC20, Ownable {
    using Counters for Counters.Counter;

    // --- Structs ---
    /**
     * @dev Represents a single Chronicle Strand NFT.
     * @param creator The address that minted this strand.
     * @param creationTimestamp The timestamp when this strand was minted.
     * @param resonanceFrequency A numerical value representing the strand's unique frequency.
     * @param vibrancyScore The current "health" or activity score of the strand. Decays over time.
     * @param lastVibrancyUpdate The timestamp of the last vibrancy update (for decay calculation).
     * @param echoCount The number of times this strand has been impacted by resonance echoes.
     */
    struct ChronicleStrand {
        address creator;
        uint256 creationTimestamp;
        uint256 resonanceFrequency; // 0 to 1,000,000 (arbitrary scale)
        uint256 vibrancyScore;      // 0 to MAX_VIBRANCY (e.g., 1000)
        uint256 lastVibrancyUpdate;
        uint256 echoCount;
    }

    /**
     * @dev Internal struct to track details of a Resonance Pulse event.
     * Could be used for history or future advanced features.
     */
    struct ResonancePulseDetail {
        uint256 pulseId;
        address initiator;
        uint256 targetFrequency;
        uint256 pulseStrength;
        uint256 timestamp;
        uint256[] impactedStrands; // IDs of strands that resonated
    }

    // --- State Variables ---
    Counters.Counter private _strandIdCounter;

    // Mapping from strandId to ChronicleStrand details
    mapping(uint256 => ChronicleStrand) public strands;
    // Mapping from resonance frequency to list of strand IDs.
    // NOTE: For very large scale, this might be gas-inefficient for finding "nearby" frequencies.
    // A more robust solution for "nearby" search might involve off-chain indexing or a limited
    // on-chain search window. For this example, a simplified approach is used.
    mapping(uint256 => uint256[]) private _strandsByFrequency;

    // Mapping from pulseId to ResonancePulseDetail
    mapping(uint256 => ResonancePulseDetail) public resonancePulseEvents;
    Counters.Counter private _pulseIdCounter;

    // System Parameters (Tunable by owner, potentially by DAO in future)
    uint256 public vibrancyDecayRatePerDay; // Points of vibrancy lost per day
    uint256 public resonanceMatchThreshold; // Max difference for frequencies to resonate (e.g., 50 for a 1M scale)
    uint256 public mintStrandCost;          // Catalyst required to mint a new strand
    uint256 public rechargeVibrancyCostPerPoint; // Catalyst per vibrancy point
    uint256 public modulateFrequencyCost; // Catalyst to change a strand's frequency
    uint256 public echoResonanceCost;     // Catalyst to echo a resonance pulse
    uint256 public catalystEmissionRate;  // Catalyst awarded per resonance point generated by a pulse

    uint256 public constant MAX_VIBRANCY = 1000; // Max vibrancy score for a strand
    uint256 public constant MAX_FREQUENCY = 1_000_000; // Max value for resonance frequency

    // Global Weave Metrics
    uint256 public totalActiveResonanceEnergy; // Sum of vibrancy of all active strands
    mapping(uint256 => uint256) public frequencyEchoCounts; // Counts how many times a frequency has been echoed/impacted

    // --- Events ---
    event StrandMinted(uint256 indexed strandId, address indexed creator, uint256 resonanceFrequency, string tokenURI);
    event ResonanceInitiated(uint256 indexed pulseId, address indexed initiator, uint256 targetFrequency, uint256 pulseStrength, uint256[] impactedStrands);
    event VibrancyRecharged(uint256 indexed strandId, address indexed owner, uint256 pointsRecharged, uint256 newVibrancy);
    event FrequencyModulated(uint256 indexed strandId, address indexed owner, uint256 oldFrequency, uint256 newFrequency);
    event ResonanceEchoed(uint256 indexed pulseId, address indexed echoer, uint256[] boostedStrands);
    event SystemParameterUpdated(bytes32 indexed parameterName, uint256 oldValue, uint256 newValue);
    event CatalystMinted(address indexed to, uint256 amount);
    event CatalystBurned(address indexed from, uint256 amount);

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, string memory _catalystName, string memory _catalystSymbol)
        ERC721(_name, _symbol)
        ERC20(_catalystName, _catalystSymbol)
        Ownable(msg.sender)
    {
        // Set initial system parameters
        vibrancyDecayRatePerDay = 10; // 10 points per day
        resonanceMatchThreshold = 50; // Frequencies within 50 units match
        mintStrandCost = 100 * (10 ** decimals()); // 100 Catalyst
        rechargeVibrancyCostPerPoint = 1 * (10 ** decimals()) / 100; // 0.01 Catalyst per point
        modulateFrequencyCost = 50 * (10 ** decimals()); // 50 Catalyst
        echoResonanceCost = 25 * (10 ** decimals()); // 25 Catalyst
        catalystEmissionRate = 1 * (10 ** decimals()) / 100; // 0.01 Catalyst per resonance point

        // Initial Catalyst supply for the deployer for testing
        _mint(msg.sender, 10000 * (10 ** decimals())); // Mint 10,000 Catalyst to deployer
    }

    // --- Helper Functions ---

    /**
     * @dev Calculates the current vibrancy of a strand, applying decay since its last update.
     * @param _strand The ChronicleStrand struct.
     * @return The calculated current vibrancy score.
     */
    function _calculateCurrentVibrancy(ChronicleStrand storage _strand) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - _strand.lastVibrancyUpdate;
        uint256 daysElapsed = timeElapsed / 1 days;
        uint256 decayedVibrancy = _strand.vibrancyScore;

        if (daysElapsed > 0) {
            decayedVibrancy = decayedVibrancy > (daysElapsed * vibrancyDecayRatePerDay)
                                ? decayedVibrancy - (daysElapsed * vibrancyDecayRatePerDay)
                                : 0;
        }
        return decayedVibrancy;
    }

    /**
     * @dev Updates the vibrancy of a strand, applying decay and then setting new vibrancy.
     * @param _strandId The ID of the strand to update.
     * @param _newVibrancy The new vibrancy score to set (after decay).
     */
    function _updateStrandVibrancy(uint256 _strandId, uint256 _newVibrancy) internal {
        ChronicleStrand storage strand = strands[_strandId];
        uint256 oldVibrancy = strand.vibrancyScore;

        // Apply decay before setting new vibrancy to ensure accurate baseline
        strand.vibrancyScore = _calculateCurrentVibrancy(strand);
        totalActiveResonanceEnergy -= (oldVibrancy - strand.vibrancyScore); // Adjust global energy for decay

        // Set the new vibrancy, capped at MAX_VIBRANCY
        strand.vibrancyScore = Math.min(_newVibrancy, MAX_VIBRANCY);
        strand.lastVibrancyUpdate = block.timestamp;

        totalActiveResonanceEnergy += (strand.vibrancyScore - oldVibrancy); // Adjust global energy for new vibrancy
    }

    /**
     * @dev Checks if two frequencies are within the resonance threshold.
     * @param _freq1 The first frequency.
     * @param _freq2 The second frequency.
     * @return True if they resonate, false otherwise.
     */
    function _doFrequenciesResonate(uint256 _freq1, uint256 _freq2) internal view returns (bool) {
        // Use Math.abs for absolute difference in 0.8.x
        return Math.abs(int256(_freq1) - int256(_freq2)) <= int256(resonanceMatchThreshold);
    }

    /**
     * @dev Internal function to mint Catalyst tokens.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function _mintCatalyst(address _to, uint256 _amount) internal {
        _mint(_to, _amount);
        emit CatalystMinted(_to, _amount);
    }

    /**
     * @dev Internal function to burn Catalyst tokens.
     * @param _from The address to burn tokens from.
     * @param _amount The amount of tokens to burn.
     */
    function _burnCatalyst(address _from, uint256 _amount) internal {
        _burn(_from, _amount);
        emit CatalystBurned(_from, _amount);
    }

    // --- A. Chronicle Strand (NFT) Management ---

    /**
     * @dev Mints a new Chronicle Strand NFT.
     * Requires `mintStrandCost` in Catalyst from the sender.
     * @param _resonanceFrequency The initial resonance frequency for the new strand (0 to MAX_FREQUENCY).
     * @param _tokenURI The URI for the NFT's metadata.
     * @return The ID of the newly minted strand.
     */
    function mintChronicleStrand(uint256 _resonanceFrequency, string memory _tokenURI)
        public
        returns (uint256)
    {
        require(_resonanceFrequency <= MAX_FREQUENCY, "ChronicleWeave: Invalid frequency");
        require(balanceOf(msg.sender) >= mintStrandCost, "ChronicleWeave: Insufficient Catalyst balance");

        _burnCatalyst(msg.sender, mintStrandCost);

        _strandIdCounter.increment();
        uint256 newItemId = _strandIdCounter.current();

        strands[newItemId] = ChronicleStrand({
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            resonanceFrequency: _resonanceFrequency,
            vibrancyScore: MAX_VIBRANCY, // New strands start with max vibrancy
            lastVibrancyUpdate: block.timestamp,
            echoCount: 0
        });

        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        _strandsByFrequency[_resonanceFrequency].push(newItemId); // Add to frequency index

        totalActiveResonanceEnergy += MAX_VIBRANCY; // Add initial vibrancy to global energy

        emit StrandMinted(newItemId, msg.sender, _resonanceFrequency, _tokenURI);
        return newItemId;
    }

    /**
     * @dev Retrieves all details of a specific Chronicle Strand, calculating its current vibrancy.
     * @param _strandId The ID of the strand to query.
     * @return A ChronicleStrand struct containing all details.
     */
    function getStrandDetails(uint256 _strandId) public view returns (ChronicleStrand memory) {
        require(_exists(_strandId), "ChronicleWeave: Strand does not exist");
        ChronicleStrand storage strand = strands[_strandId];
        
        // Return a copy with calculated current vibrancy
        return ChronicleStrand({
            creator: strand.creator,
            creationTimestamp: strand.creationTimestamp,
            resonanceFrequency: strand.resonanceFrequency,
            vibrancyScore: _calculateCurrentVibrancy(strand), // Calculate current vibrancy on demand
            lastVibrancyUpdate: strand.lastVibrancyUpdate,
            echoCount: strand.echoCount
        });
    }

    /**
     * @dev Calculates and returns the *current* vibrancy score of a strand, accounting for decay.
     * This is a view function that internally calls the helper.
     * @param _strandId The ID of the strand to query.
     * @return The current vibrancy score.
     */
    function getCurrentVibrancy(uint256 _strandId) public view returns (uint256) {
        require(_exists(_strandId), "ChronicleWeave: Strand does not exist");
        return _calculateCurrentVibrancy(strands[_strandId]);
    }

    /**
     * @dev See {ERC721URIStorage-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, ERC721Enumerable)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, ERC721Enumerable)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, ERC721Enumerable)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override(ERC721, ERC721Enumerable) {
        super.approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721, ERC721Enumerable) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override(ERC721, ERC721Enumerable) returns (address) {
        return super.getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override(ERC721, ERC721Enumerable) returns (address) {
        return super.ownerOf(tokenId);
    }

    /**
     * @dev See {ERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev See {ERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenByIndex(index);
    }

    /**
     * @dev See {ERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(ERC721, ERC721Enumerable) returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    // --- B. Resonance Mechanics ---

    /**
     * @dev Initiates a Resonance Pulse at a specified frequency.
     * All active strands within the `resonanceMatchThreshold` will resonate,
     * increasing their vibrancy and echo count.
     * Requires `_pulseStrength` * catalystEmissionRate in Catalyst from sender.
     * @param _targetFrequency The frequency at which to initiate the pulse.
     * @param _pulseStrength The strength of the pulse, determining the impact on vibrancy/echoes.
     * @return The ID of the initiated resonance pulse.
     */
    function initiateResonancePulse(uint256 _targetFrequency, uint256 _pulseStrength)
        public
        returns (uint256)
    {
        require(_pulseStrength > 0, "ChronicleWeave: Pulse strength must be positive");
        require(_targetFrequency <= MAX_FREQUENCY, "ChronicleWeave: Invalid target frequency");

        uint256 catalystCost = _pulseStrength * catalystEmissionRate;
        require(balanceOf(msg.sender) >= catalystCost, "ChronicleWeave: Insufficient Catalyst for pulse");

        _burnCatalyst(msg.sender, catalystCost);

        uint256[] memory impactedStrandIds = new uint256[](0);
        uint256 totalResonanceGain = 0;

        // Iterate through all strands to find those that resonate.
        // NOTE: This loop can be very gas-intensive for large number of strands.
        // A more advanced design would use a more efficient data structure
        // or require off-chain computation to provide candidates.
        for (uint256 i = 0; i < _strandIdCounter.current(); i++) {
            uint256 strandId = tokenByIndex(i); // Get strandId by index
            ChronicleStrand storage strand = strands[strandId];

            // Apply decay before checking resonance to ensure up-to-date vibrancy
            _updateStrandVibrancy(strandId, _calculateCurrentVibrancy(strand));

            if (strand.vibrancyScore > 0 && _doFrequenciesResonate(strand.resonanceFrequency, _targetFrequency)) {
                uint256 resonanceGain = _pulseStrength; // Simple gain, could be more complex
                
                uint256 newVibrancy = strand.vibrancyScore + resonanceGain;
                _updateStrandVibrancy(strandId, newVibrancy); // Update vibrancy and global energy

                strand.echoCount += 1; // Increase echo count for the strand
                frequencyEchoCounts[strand.resonanceFrequency] += 1; // Increase global echo count for this frequency

                totalResonanceGain += resonanceGain;
                impactedStrandIds = _addToArray(impactedStrandIds, strandId);
            }
        }

        _pulseIdCounter.increment();
        uint256 currentPulseId = _pulseIdCounter.current();

        resonancePulseEvents[currentPulseId] = ResonancePulseDetail({
            pulseId: currentPulseId,
            initiator: msg.sender,
            targetFrequency: _targetFrequency,
            pulseStrength: _pulseStrength,
            timestamp: block.timestamp,
            impactedStrands: impactedStrandIds
        });

        // Potentially mint Catalyst as a reward for successful resonance pulse initiation
        // _mintCatalyst(msg.sender, totalResonanceGain * catalystEmissionRate);

        emit ResonanceInitiated(currentPulseId, msg.sender, _targetFrequency, _pulseStrength, impactedStrandIds);
        return currentPulseId;
    }

    /**
     * @dev Helper to find all currently active strands that would resonate with a given frequency.
     * @param _targetFrequency The frequency to match against.
     * @return An array of strand IDs that would resonate.
     */
    function getStrandsMatchingFrequency(uint256 _targetFrequency) public view returns (uint256[] memory) {
        uint256[] memory matchingStrands = new uint256[](0);

        for (uint256 i = 0; i < _strandIdCounter.current(); i++) {
            uint256 strandId = tokenByIndex(i);
            ChronicleStrand storage strand = strands[strandId];
            if (_calculateCurrentVibrancy(strand) > 0 && _doFrequenciesResonate(strand.resonanceFrequency, _targetFrequency)) {
                matchingStrands = _addToArray(matchingStrands, strandId);
            }
        }
        return matchingStrands;
    }

    /**
     * @dev Allows a strand owner to recharge their strand's vibrancy using Catalyst.
     * @param _strandId The ID of the strand to recharge.
     * @param _pointsToRecharge The number of vibrancy points to add.
     */
    function rechargeStrandVibrancy(uint256 _strandId, uint256 _pointsToRecharge) public {
        require(_exists(_strandId), "ChronicleWeave: Strand does not exist");
        require(ownerOf(_strandId) == msg.sender, "ChronicleWeave: Not strand owner");
        require(_pointsToRecharge > 0, "ChronicleWeave: Points to recharge must be positive");

        ChronicleStrand storage strand = strands[_strandId];
        uint256 currentVibrancy = _calculateCurrentVibrancy(strand);
        
        uint256 cost = _pointsToRecharge * rechargeVibrancyCostPerPoint;
        require(balanceOf(msg.sender) >= cost, "ChronicleWeave: Insufficient Catalyst for recharge");

        _burnCatalyst(msg.sender, cost);

        uint256 newVibrancy = currentVibrancy + _pointsToRecharge;
        _updateStrandVibrancy(_strandId, newVibrancy); // Update vibrancy and global energy

        emit VibrancyRecharged(_strandId, msg.sender, _pointsToRecharge, strand.vibrancyScore);
    }

    /**
     * @dev Allows a strand owner to change their strand's resonance frequency.
     * Costs `modulateFrequencyCost` in Catalyst.
     * @param _strandId The ID of the strand to modulate.
     * @param _newFrequency The new frequency for the strand (0 to MAX_FREQUENCY).
     */
    function modulateStrandFrequency(uint256 _strandId, uint256 _newFrequency) public {
        require(_exists(_strandId), "ChronicleWeave: Strand does not exist");
        require(ownerOf(_strandId) == msg.sender, "ChronicleWeave: Not strand owner");
        require(_newFrequency <= MAX_FREQUENCY, "ChronicleWeave: Invalid new frequency");
        require(_newFrequency != strands[_strandId].resonanceFrequency, "ChronicleWeave: Frequency is already this value");

        require(balanceOf(msg.sender) >= modulateFrequencyCost, "ChronicleWeave: Insufficient Catalyst for modulation");

        _burnCatalyst(msg.sender, modulateFrequencyCost);

        ChronicleStrand storage strand = strands[_strandId];
        uint256 oldFrequency = strand.resonanceFrequency;

        // Remove from old frequency index (simplified, might need proper array management)
        // For production, consider using a more robust data structure or removing by value
        // For now, simply changing the frequency effectively "abandons" its old index entry.
        // A `mapping(uint256 => mapping(uint256 => bool))` `_isInFrequencyIndex` for `frequency -> strandId -> bool`
        // would allow more robust removal. Or `mapping(uint256 => uint256[])` with custom remove logic.

        strand.resonanceFrequency = _newFrequency;
        _updateStrandVibrancy(_strandId, _calculateCurrentVibrancy(strand)); // Update vibrancy and global energy

        // Add to new frequency index (if using the array-based index)
        _strandsByFrequency[_newFrequency].push(_strandId);

        emit FrequencyModulated(_strandId, msg.sender, oldFrequency, _newFrequency);
    }

    /**
     * @dev Allows any user to "echo" a previous resonance pulse, further boosting
     * the vibrancy and echo counts of the strands involved in that pulse.
     * Costs `echoResonanceCost` in Catalyst.
     * @param _pulseId The ID of the resonance pulse to echo.
     */
    function echoResonance(uint256 _pulseId) public {
        require(_pulseId <= _pulseIdCounter.current() && _pulseId > 0, "ChronicleWeave: Invalid pulse ID");
        require(balanceOf(msg.sender) >= echoResonanceCost, "ChronicleWeave: Insufficient Catalyst for echoing");

        _burnCatalyst(msg.sender, echoResonanceCost);

        ResonancePulseDetail storage pulse = resonancePulseEvents[_pulseId];
        uint256[] memory boostedStrandIds = new uint256[](0);

        for (uint256 i = 0; i < pulse.impactedStrands.length; i++) {
            uint256 strandId = pulse.impactedStrands[i];
            ChronicleStrand storage strand = strands[strandId];

            // Apply decay before boosting
            _updateStrandVibrancy(strandId, _calculateCurrentVibrancy(strand));

            // Boost vibrancy and echo count again
            uint256 boostAmount = pulse.pulseStrength / 2; // Echo provides half the initial boost
            uint256 newVibrancy = strand.vibrancyScore + boostAmount;
            _updateStrandVibrancy(strandId, newVibrancy); // Update vibrancy and global energy

            strand.echoCount += 1;
            frequencyEchoCounts[strand.resonanceFrequency] += 1;
            boostedStrandIds = _addToArray(boostedStrandIds, strandId);
        }

        emit ResonanceEchoed(_pulseId, msg.sender, boostedStrandIds);
    }

    // --- C. Catalyst Token Management (ERC-20 Overrides & Extensions) ---
    // ERC20 functions (name, symbol, decimals, totalSupply, balanceOf, transfer,
    // approve, transferFrom, allowance) are inherited and automatically implemented by OpenZeppelin.
    // _mintCatalyst and _burnCatalyst are internal helper functions defined above.

    // --- D. Weave Analytics & Global State ---

    /**
     * @dev Provides key global statistics about the Weave.
     * @return _totalStrands The total number of Chronicle Strands minted.
     * @return _totalActiveResonanceEnergy The sum of vibrancy of all active strands.
     * @return _catalystSupply The total circulating supply of Catalyst tokens.
     */
    function getGlobalWeaveMetrics()
        public
        view
        returns (uint256 _totalStrands, uint256 _totalActiveResonanceEnergy, uint256 _catalystSupply)
    {
        return (totalSupply(), totalActiveResonanceEnergy, ERC20.totalSupply());
    }

    /**
     * @dev Returns a list of the top N most echoed frequencies.
     * Note: This is a simplistic implementation for demonstration. For a large number of frequencies,
     * sorting on-chain would be too gas-expensive. A real-world application would use off-chain indexing
     * or a more specialized data structure (e.g., a min-heap) if this needs to be on-chain.
     * @param _count The number of top frequencies to return.
     * @return An array of frequency values.
     */
    function getTopResonantFrequencies(uint256 _count) public view returns (uint256[] memory) {
        // Collect all distinct frequencies that have been echoed
        uint256[] memory distinctFrequencies = new uint256[](0);
        for (uint256 i = 0; i <= MAX_FREQUENCY; i++) { // Iterating up to MAX_FREQUENCY is highly inefficient for dense ranges
            if (frequencyEchoCounts[i] > 0) {
                distinctFrequencies = _addToArray(distinctFrequencies, i);
            }
        }

        // Sort by echo count (bubble sort for simplicity, not gas-efficient for large arrays)
        for (uint256 i = 0; i < distinctFrequencies.length; i++) {
            for (uint256 j = i + 1; j < distinctFrequencies.length; j++) {
                if (frequencyEchoCounts[distinctFrequencies[i]] < frequencyEchoCounts[distinctFrequencies[j]]) {
                    uint256 temp = distinctFrequencies[i];
                    distinctFrequencies[i] = distinctFrequencies[j];
                    distinctFrequencies[j] = temp;
                }
            }
        }

        // Return top _count
        uint256 returnCount = Math.min(_count, distinctFrequencies.length);
        uint256[] memory topFrequencies = new uint256[](returnCount);
        for (uint256 i = 0; i < returnCount; i++) {
            topFrequencies[i] = distinctFrequencies[i];
        }

        return topFrequencies;
    }

    // --- E. Administration & Governance ---

    /**
     * @dev Allows the owner to update key system parameters.
     * @param _parameterName The name of the parameter to update (e.g., "vibrancyDecayRatePerDay").
     * @param _newValue The new value for the parameter.
     */
    function setSystemParameter(bytes32 _parameterName, uint256 _newValue) public onlyOwner {
        uint256 oldValue;
        if (_parameterName == "vibrancyDecayRatePerDay") {
            oldValue = vibrancyDecayRatePerDay;
            vibrancyDecayRatePerDay = _newValue;
        } else if (_parameterName == "resonanceMatchThreshold") {
            oldValue = resonanceMatchThreshold;
            resonanceMatchThreshold = _newValue;
        } else if (_parameterName == "mintStrandCost") {
            oldValue = mintStrandCost;
            mintStrandCost = _newValue;
        } else if (_parameterName == "rechargeVibrancyCostPerPoint") {
            oldValue = rechargeVibrancyCostPerPoint;
            rechargeVibrancyCostPerPoint = _newValue;
        } else if (_parameterName == "modulateFrequencyCost") {
            oldValue = modulateFrequencyCost;
            modulateFrequencyCost = _newValue;
        } else if (_parameterName == "echoResonanceCost") {
            oldValue = echoResonanceCost;
            echoResonanceCost = _newValue;
        } else if (_parameterName == "catalystEmissionRate") {
            oldValue = catalystEmissionRate;
            catalystEmissionRate = _newValue;
        } else {
            revert("ChronicleWeave: Invalid parameter name");
        }
        emit SystemParameterUpdated(_parameterName, oldValue, _newValue);
    }

    /**
     * @dev Allows the contract owner to withdraw any Ether held by the contract.
     * This is useful if the contract ever receives ETH (e.g., from future fees).
     */
    function withdrawContractBalance() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ChronicleWeave: Failed to withdraw Ether");
    }

    // --- Internal Array Helper (for dynamic arrays in memory) ---
    /**
     * @dev Internal helper to add an element to a dynamic array in memory.
     * @param _array The array to add to.
     * @param _element The element to add.
     * @return The new array with the element appended.
     */
    function _addToArray(uint256[] memory _array, uint256 _element) internal pure returns (uint256[] memory) {
        uint256 newLength = _array.length + 1;
        uint256[] memory newArray = new uint256[](newLength);
        for (uint256 i = 0; i < _array.length; i++) {
            newArray[i] = _array[i];
        }
        newArray[_array.length] = _element;
        return newArray;
    }

    // --- Overrides for ERC721 & ERC20 ---
    // The OpenZeppelin contracts handle most overrides automatically for ERC721Enumerable and ERC721URIStorage.
    // `_beforeTokenTransfer` can be overridden for custom logic before transfers.
    // `_baseURI()` would be useful if all NFTs shared a base URI, but here `_setTokenURI` is used per-NFT.
}
```