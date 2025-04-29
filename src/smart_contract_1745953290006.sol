Okay, let's design a smart contract that implements a generative art NFT collection with advanced features like configurable on-chain trait generation based on randomness, dynamic evolution of NFTs, configurable minting phases, and direct on-chain SVG metadata generation.

This concept combines:
1.  **Generative Art:** Traits determined algorithmically upon minting or evolution.
2.  **On-Chain Data:** Traits and potentially SVG data stored and generated directly on the blockchain.
3.  **Dynamic NFTs:** NFTs that can change (evolve) after minting.
4.  **Configurability:** Owner can set parameters for generation, minting, and evolution.
5.  **Modularity:** Abstracting randomness source via an interface.

It avoids being a simple ERC721, basic staking, standard DeFi, or simple governance contract.

---

**Contract Name:** `GenerativeArtNFT`

**Description:** An ERC721 compliant smart contract for a generative art collection where traits are generated on-chain using randomness and owner-configured probabilities. NFTs can evolve, changing their traits. Metadata (including SVG) is generated dynamically on-chain.

**Outline:**

1.  **Pragma & Imports:** Solidity version, ERC721, Ownable, Base64 (for metadata).
2.  **Interfaces:** `IRandomnessSource` for pluggable randomness.
3.  **Libraries:** `Base64` (can use a simple inline version or import).
4.  **Events:** `Minted`, `TraitsGenerated`, `TokenEvolved`, `ConfigUpdated`, `MintPhaseUpdated`, `RoyaltyUpdated`, etc.
5.  **Enums:** `MintPhase`, `TraitType` (example trait types).
6.  **Structs:** `TokenTraits`, `TraitConfig` (for configuring trait probabilities).
7.  **State Variables:**
    *   ERC721 state (`_tokens`, `_owners`, etc. - handled by inheritance).
    *   `_owner`: Contract owner.
    *   `_nextTokenId`: Counter for new tokens.
    *   `_tokenTraits`: Mapping token ID to its `TokenTraits` struct.
    *   `_traitConfigurations`: Mapping `TraitType` to `TraitConfig`.
    *   `_randomnessSource`: Address of the randomness source contract.
    *   `_mintPhases`: Mapping phase index to configuration (cost, start/end time, max per wallet).
    *   `_currentMintPhase`: Index of the active mint phase.
    *   `_totalSupply`: Current number of minted tokens.
    *   `_maxSupply`: Maximum number of tokens.
    *   `_mintCosts`: Mapping mint phase index to cost.
    *   `_evolutionCost`: Cost to evolve a token.
    *   `_paused`: Flag for pausing minting.
    *   `_defaultRoyaltyRecipient`: Address for default royalties.
    *   `_defaultRoyaltyBps`: Basis points for default royalties.
    *   `_baseTokenURI`: Optional base URI (though metadata is on-chain).
    *   `_name`, `_symbol`: ERC721 standard name and symbol.
8.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `isValidTokenId`, `isMintPhaseActive`.
9.  **Constructor:** Sets name, symbol, initial owner, max supply, and potentially initial phase config.
10. **Core ERC721 Overrides:**
    *   `tokenURI`: Generates and returns the on-chain metadata URI (data URI).
    *   `supportsInterface`: Supports ERC721 and EIP-2981.
    *   `royaltyInfo`: Implements EIP-2981.
    *   `_beforeTokenTransfer`: Hook to potentially check transfer conditions (though not strictly necessary for this concept).
11. **Minting Functions (Public/External):**
    *   `mint`: Mints a single token.
    *   `mintBatch`: Mints multiple tokens.
    *   `setMintPhase`: Configures a specific mint phase.
    *   `setCurrentMintPhase`: Sets the currently active mint phase.
    *   `setMaxSupply`: Sets the maximum collection supply.
    *   `pauseMinting`: Pauses minting.
    *   `unpauseMinting`: Unpauses minting.
    *   `withdraw`: Withdraws collected funds (onlyOwner).
12. **Trait Configuration Functions (OnlyOwner):**
    *   `setTraitConfiguration`: Sets probabilities for values within a trait type.
    *   `addPossibleTraitValue`: Adds a new possible value string for a trait type.
    *   `removePossibleTraitValue`: Removes a possible value string.
13. **Trait Generation & Evolution Functions:**
    *   `_generateTraits`: Internal helper to generate traits using randomness and config.
    *   `evolveToken`: Allows token owner to pay to re-generate traits for an existing token.
    *   `setEvolutionCost`: Sets the cost to evolve a token (onlyOwner).
    *   `setRandomnessSource`: Sets the address of the randomness source contract (onlyOwner).
14. **Metadata Generation Functions (Internal):**
    *   `_generateMetadataJson`: Creates the JSON string for `tokenURI`.
    *   `_generateSvgImage`: Creates the SVG string based on traits (example implementation).
15. **Royalty Functions (OnlyOwner):**
    *   `setDefaultRoyalty`: Sets the default royalty recipient and amount.
    *   *(Could add token-specific royalty but keep it simple with default for count).*
16. **View Functions (Public/View):**
    *   `getTraits`: Retrieves traits for a specific token ID.
    *   `getTraitConfiguration`: Retrieves configuration for a trait type.
    *   `getRandomnessSource`: Gets the randomness source address.
    *   `getCurrentSupply`: Gets the current minted supply.
    *   `getMaxSupply`: Gets the max supply.
    *   `getCurrentMintPhase`: Gets the index of the current phase.
    *   `getMintPhaseConfig`: Gets configuration details for a phase.
    *   `getMintCost`: Gets the cost for the current phase.
    *   `getEvolutionCost`: Gets the cost to evolve.
    *   `getDefaultRoyaltyInfo`: Gets default royalty details.
    *   *(Inherited views: `balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`)*.

**Function Summary (Targeting >= 20 Public/External Functions):**

1.  `constructor()`: Initializes the contract.
2.  `balanceOf(address owner) external view override`: ERC721 standard.
3.  `ownerOf(uint256 tokenId) external view override`: ERC721 standard.
4.  `safeTransferFrom(address from, address to, uint256 tokenId) external override`: ERC721 standard (2 versions count as one concept here, but distinct signatures).
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external override`: ERC721 standard.
6.  `transferFrom(address from, address to, uint256 tokenId) external override`: ERC721 standard.
7.  `approve(address to, uint256 tokenId) external override`: ERC721 standard.
8.  `setApprovalForAll(address operator, bool approved) external override`: ERC721 standard.
9.  `getApproved(uint256 tokenId) external view override`: ERC721 standard.
10. `isApprovedForAll(address owner, address operator) external view override`: ERC721 standard.
11. `tokenURI(uint256 tokenId) public view override`: Generates on-chain metadata URI.
12. `supportsInterface(bytes4 interfaceId) public view override`: EIP-165 and EIP-2981.
13. `royaltyInfo(uint256 tokenId, uint256 salePrice) external view override`: EIP-2981 implementation.
14. `mint(uint256 quantity) external payable whenNotPaused isMintPhaseActive`: Mints tokens for caller.
15. `setMintPhase(uint256 phaseIndex, uint256 cost, uint64 startTime, uint64 endTime, uint16 maxPerWallet) external onlyOwner`: Configures a minting phase.
16. `setCurrentMintPhase(uint256 phaseIndex) external onlyOwner`: Activates a configured minting phase.
17. `setMaxSupply(uint256 supply) external onlyOwner`: Sets total collection cap.
18. `pauseMinting() external onlyOwner whenNotPaused`: Pauses minting.
19. `unpauseMinting() external onlyOwner whenPaused`: Unpauses minting.
20. `withdraw(address payable recipient) external onlyOwner`: Withdraws contract balance.
21. `setTraitConfiguration(uint8 traitType, string[] memory possibleValues, uint256[] memory probabilities) external onlyOwner`: Sets trait options and weights.
22. `addPossibleTraitValue(uint8 traitType, string memory value, uint256 probability) external onlyOwner`: Adds a single trait option and its weight.
23. `removePossibleTraitValue(uint8 traitType, string memory value) external onlyOwner`: Removes a trait option.
24. `setRandomnessSource(address source) external onlyOwner`: Sets the address of the randomness oracle/contract.
25. `evolveToken(uint256 tokenId) external payable isValidTokenId`: Re-generates traits for a token.
26. `setEvolutionCost(uint256 cost) external onlyOwner`: Sets cost for token evolution.
27. `setDefaultRoyalty(address recipient, uint96 basisPoints) external onlyOwner`: Sets collection-wide royalty.
28. `getTraits(uint256 tokenId) public view isValidTokenId`: Gets traits for a token.
29. `getTraitConfiguration(uint8 traitType) public view`: Gets configuration for a trait type.
30. `getRandomnessSource() public view`: Gets randomness source address.
31. `getCurrentSupply() public view`: Gets current minted supply.
32. `getMaxSupply() public view`: Gets maximum supply.
33. `getCurrentMintPhase() public view`: Gets current mint phase index.
34. `getMintPhaseConfig(uint256 phaseIndex) public view`: Gets phase configuration.
35. `getMintCost() public view`: Gets cost for the active phase.
36. `getEvolutionCost() public view`: Gets token evolution cost.
37. `getDefaultRoyaltyInfo() public view`: Gets default royalty info.
38. `transferOwnership(address newOwner) external override onlyOwner`: Ownable standard.

This provides 38 public/external functions, well over the requested 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // For Royalty Standard

// --- Contract Name: GenerativeArtNFT ---
// Description: An ERC721 compliant smart contract for a generative art collection
//              where traits are generated on-chain using randomness and owner-configured probabilities.
//              NFTs can evolve, changing their traits. Metadata (including SVG) is
//              generated dynamically on-chain. Implements EIP-2981 for royalties.

// --- Outline ---
// 1. Pragma & Imports (ERC721, Ownable, Base64, Counters, SafeMath, IERC2981)
// 2. Interfaces (IRandomnessSource)
// 3. Libraries (Base64) - Used via import
// 4. Events (Minted, TraitsGenerated, TokenEvolved, ConfigUpdated, MintPhaseUpdated, RoyaltyUpdated, etc.)
// 5. Enums (MintPhaseState, TraitType)
// 6. Structs (TokenTraits, TraitConfig, MintPhaseConfig)
// 7. State Variables (ERC721 state, owner, counters, traits data, config, mint phases, supply limits, costs, pause, royalty, base URI)
// 8. Modifiers (onlyOwner, whenNotPaused, whenPaused, isValidTokenId, isMintPhaseActive)
// 9. Constructor (Initializes contract)
// 10. Core ERC721 Overrides (tokenURI, supportsInterface, royaltyInfo, _beforeTokenTransfer)
// 11. Minting Functions (mint, mintBatch, setMintPhase, setCurrentMintPhase, setMaxSupply, pauseMinting, unpauseMinting, withdraw)
// 12. Trait Configuration Functions (setTraitConfiguration, addPossibleTraitValue, removePossibleTraitValue)
// 13. Trait Generation & Evolution Functions (_generateTraits, evolveToken, setEvolutionCost, setRandomnessSource)
// 14. Metadata Generation Functions (Internal helpers: _generateMetadataJson, _generateSvgImage)
// 15. Royalty Functions (setDefaultRoyalty)
// 16. View Functions (getTraits, getTraitConfiguration, getRandomnessSource, getCurrentSupply, getMaxSupply, getCurrentMintPhase, getMintPhaseConfig, getMintCost, getEvolutionCost, getDefaultRoyaltyInfo)

// --- Function Summary (Public/External) ---
// 1. constructor()
// 2. balanceOf(address owner)
// 3. ownerOf(uint256 tokenId)
// 4. safeTransferFrom(address from, address to, uint256 tokenId)
// 5. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// 6. transferFrom(address from, address to, uint256 tokenId)
// 7. approve(address to, uint256 tokenId)
// 8. setApprovalForAll(address operator, bool approved)
// 9. getApproved(uint256 tokenId)
// 10. isApprovedForAll(address owner, address operator)
// 11. tokenURI(uint256 tokenId)
// 12. supportsInterface(bytes4 interfaceId)
// 13. royaltyInfo(uint256 tokenId, uint256 salePrice)
// 14. mint(uint256 quantity)
// 15. setMintPhase(uint256 phaseIndex, uint256 cost, uint64 startTime, uint64 endTime, uint16 maxPerWallet)
// 16. setCurrentMintPhase(uint256 phaseIndex)
// 17. setMaxSupply(uint256 supply)
// 18. pauseMinting()
// 19. unpauseMinting()
// 20. withdraw(address payable recipient)
// 21. setTraitConfiguration(uint8 traitType, string[] memory possibleValues, uint256[] memory probabilities)
// 22. addPossibleTraitValue(uint8 traitType, string memory value, uint256 probability)
// 23. removePossibleTraitValue(uint8 traitType, string memory value)
// 24. setRandomnessSource(address source)
// 25. evolveToken(uint256 tokenId)
// 26. setEvolutionCost(uint256 cost)
// 27. setDefaultRoyalty(address recipient, uint96 basisPoints)
// 28. getTraits(uint256 tokenId)
// 29. getTraitConfiguration(uint8 traitType)
// 30. getRandomnessSource()
// 31. getCurrentSupply()
// 32. getMaxSupply()
// 33. getCurrentMintPhase()
// 34. getMintPhaseConfig(uint256 phaseIndex)
// 35. getMintCost()
// 36. getEvolutionCost()
// 37. getDefaultRoyaltyInfo()
// 38. transferOwnership(address newOwner) - From Ownable

interface IRandomnessSource {
    // Function signature expected to request randomness
    // Implementations would typically handle asynchronous request/callback patterns
    // For this example, we'll simulate a synchronous call in _generateTraits
    // A real implementation would use Chainlink VRF or similar
    function getRandomNumber(uint256 seed) external returns (uint256);

    // Optional: Function to get a verifiable random result from a request ID in a real VRF
    // function fulfillRandomness(bytes32 requestId, uint256 randomness) external;
}

contract GenerativeArtNFT is ERC721, Ownable, IERC2981 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _nextTokenId;

    // --- State Variables ---

    // Trait Data: Mapping token ID to its generated traits
    struct TokenTraits {
        // Example trait types - can be extended
        uint8 background; // Index into possible values
        uint8 body;
        uint8 eyes;
        uint8 accessory;
        // Add more trait types as needed
    }
    mapping(uint256 => TokenTraits) private _tokenTraits;

    // Trait Configuration: Defines possible values and probabilities for each trait type
    struct TraitConfig {
        string[] possibleValues;
        // Probabilities are stored as cumulative sum for easier random selection
        // Example: [1000, 3000, 6000, 10000] for probabilities 10%, 20%, 30%, 40%
        uint256[] cumulativeProbabilities;
        // Sum of probabilities for validation (should be 10000 if using basis points)
        uint256 totalProbabilitySum;
    }
    // Using uint8 as key for TraitType enum
    mapping(uint8 => TraitConfig) private _traitConfigurations;

    // Randomness Source
    address public _randomnessSource;

    // Minting Configuration
    struct MintPhaseConfig {
        uint256 cost;
        uint64 startTime;
        uint64 endTime;
        uint16 maxPerWallet; // 0 for no limit
        mapping(address => uint16) mintedPerWallet; // Tracks mints per phase per address
    }
    mapping(uint256 => MintPhaseConfig) private _mintPhases;
    uint256 public _currentMintPhase;

    uint256 public _totalSupply;
    uint256 public _maxSupply;

    bool public _paused;

    uint256 public _evolutionCost;

    // Royalty (EIP-2981)
    address private _defaultRoyaltyRecipient;
    uint96 private _defaultRoyaltyBps; // Basis points (e.g., 250 = 2.5%)

    // Base URI (fallback, though we generate data URI)
    string private _baseTokenURI;

    // --- Enums ---
    enum MintPhaseState {Inactive, Active, Ended} // Not stored, calculated

    enum TraitType {Background, Body, Eyes, Accessory} // Example types

    // --- Events ---
    event Minted(address indexed recipient, uint256[] tokenIds, uint256 quantity);
    event TraitsGenerated(uint256 indexed tokenId, TokenTraits traits);
    event TokenEvolved(uint256 indexed tokenId, TokenTraits oldTraits, TokenTraits newTraits);
    event ConfigUpdated(string configName);
    event MintPhaseUpdated(uint256 indexed phaseIndex, MintPhaseConfig config);
    event CurrentMintPhaseSet(uint256 indexed phaseIndex);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event RandomnessSourceSet(address indexed source);
    event EvolutionCostUpdated(uint256 newCost);
    event RoyaltyUpdated(address indexed recipient, uint96 basisPoints);
    event Withdrawal(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!_paused, "Minting is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Minting is not paused");
        _;
    }

    modifier isValidTokenId(uint256 tokenId) {
        require(_exists(tokenId), "Invalid token ID");
        _;
    }

    modifier isMintPhaseActive(uint256 quantity) {
        MintPhaseConfig storage phase = _mintPhases[_currentMintPhase];
        require(phase.startTime != 0, "Mint phase not configured");
        require(block.timestamp >= phase.startTime, "Mint phase not started");
        require(block.timestamp < phase.endTime || phase.endTime == 0, "Mint phase ended"); // endTime 0 means infinite
        require(_totalSupply.add(quantity) <= _maxSupply, "Max supply reached");

        if (phase.maxPerWallet > 0) {
            require(phase.mintedPerWallet[msg.sender].add(uint16(quantity)) <= phase.maxPerWallet, "Max per wallet exceeded for this phase");
        }
        _;
    }

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address initialOwner,
        address initialRandomnessSource
    ) ERC721(name_, symbol_) Ownable(initialOwner) {
        _maxSupply = maxSupply_;
        _randomnessSource = initialRandomnessSource;
        _paused = false;
        _evolutionCost = 0.1 ether; // Example default evolution cost
        _defaultRoyaltyBps = 500; // Default 5% royalty
        _defaultRoyaltyRecipient = initialOwner;
        _baseTokenURI = "ipfs://YOUR_FALLBACK_URI/"; // Example fallback/base URI

        // Initialize some example trait configurations (owner can change these later)
        // Backgrounds: Red (10%), Blue (20%), Green (70%) -> Cumulative: [1000, 3000, 10000]
        setTraitConfiguration(uint8(TraitType.Background), new string[]('Red', 'Blue', 'Green'), new uint256[](1000, 2000, 7000)); // sum 10000
        // Body: Square (50%), Circle (50%) -> Cumulative: [5000, 10000]
        setTraitConfiguration(uint8(TraitType.Body), new string[]('Square', 'Circle'), new uint256[](5000, 5000)); // sum 10000
        // Eyes: Dot (80%), Star (20%) -> Cumulative: [8000, 10000]
        setTraitConfiguration(uint8(TraitType.Eyes), new string[]('Dot', 'Star'), new uint256[](8000, 2000)); // sum 10000
        // Accessory: Hat (30%), Glasses (30%), None (40%) -> Cumulative: [3000, 6000, 10000]
        setTraitConfiguration(uint8(TraitType.Accessory), new string[]('Hat', 'Glasses', 'None'), new uint256[](3000, 3000, 4000)); // sum 10000
    }

    // --- Core ERC721 Overrides ---

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId`.
     * This is the core function for on-chain metadata.
     * It generates the full data URI including JSON and SVG image.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            // As per ERC721 spec, should return empty string for non-existent tokens
            return "";
            // Alternatively, could revert: revert("Invalid token ID");
        }

        // Generate metadata JSON string
        string memory json = _generateMetadataJson(tokenId);

        // Base64 encode the JSON
        string memory jsonBase64 = Base64.encode(bytes(json));

        // Construct the data URI
        return string(abi.encodePacked("data:application/json;base64,", jsonBase64));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * Adds support for ERC721 and EIP-2981.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     * Implements the default collection royalty.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address, uint256) {
        // _tokenId is ignored here as it's a collection-wide royalty
        // Calculate royalty amount: salePrice * defaultRoyaltyBps / 10000
        uint256 royaltyAmount = (_salePrice * _defaultRoyaltyBps) / 10000;
        return (_defaultRoyaltyRecipient, royaltyAmount);
    }

    // The `_beforeTokenTransfer` hook can be used for custom logic before transfers,
    // e.g., locking tokens. Not needed for this basic concept, but good practice to know.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    // }

    // --- Minting Functions ---

    /**
     * @dev Mints one or more tokens to the caller.
     * Traits are generated automatically for each new token.
     */
    function mint(uint256 quantity) external payable whenNotPaused isMintPhaseActive(quantity) {
        require(quantity > 0, "Quantity must be greater than 0");

        MintPhaseConfig storage phase = _mintPhases[_currentMintPhase];
        uint256 totalCost = phase.cost.mul(quantity);
        require(msg.value >= totalCost, "Insufficient funds");

        uint256[] memory mintedTokenIds = new uint256[](quantity);

        for (uint i = 0; i < quantity; i++) {
            uint256 newItemId = _nextTokenId.current();
            _nextTokenId.increment();

            require(_totalSupply < _maxSupply, "Max supply reached"); // Double check inside loop

            // Generate traits for the new token
            _generateTraits(newItemId);

            // Mint the ERC721 token
            _safeMint(msg.sender, newItemId);

            _totalSupply++;
            mintedTokenIds[i] = newItemId;
        }

        // Update per-wallet mint count for the phase
        if (phase.maxPerWallet > 0) {
             phase.mintedPerWallet[msg.sender] = phase.mintedPerWallet[msg.sender].add(uint16(quantity));
        }

        // Refund excess payment if any
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit Minted(msg.sender, mintedTokenIds, quantity);
    }

    /**
     * @dev Alias for minting a batch (same as mint for simplicity, but could have different logic).
     */
    function mintBatch(uint256 quantity) external payable {
         mint(quantity); // Using the single mint function for batch logic
    }


    /**
     * @dev Allows the owner to configure a specific minting phase.
     * @param phaseIndex The index of the phase to configure.
     * @param cost The cost per token in this phase.
     * @param startTime The start timestamp (0 for immediate upon phase activation).
     * @param endTime The end timestamp (0 for no end time).
     * @param maxPerWallet Max tokens a single address can mint in this phase (0 for no limit).
     */
    function setMintPhase(
        uint256 phaseIndex,
        uint256 cost,
        uint64 startTime,
        uint64 endTime,
        uint16 maxPerWallet
    ) external onlyOwner {
        require(phaseIndex > 0, "Phase index must be greater than 0"); // Index 0 reserved or unused
        // Basic validation: start <= end, unless end is 0
        require(startTime <= endTime || endTime == 0, "Start time must be before or equal to end time");

        MintPhaseConfig storage phase = _mintPhases[phaseIndex];
        phase.cost = cost;
        phase.startTime = startTime;
        phase.endTime = endTime;
        phase.maxPerWallet = maxPerWallet;

        // Note: mintedPerWallet counters are reset by setting a new phase config for that index
        // If you needed to preserve counts across config updates for the *same* phase concept,
        // you'd need a different structure. This assumes setting a phase *replaces* the old one.

        emit MintPhaseUpdated(phaseIndex, phase);
    }

    /**
     * @dev Allows the owner to set the currently active minting phase.
     * Only one phase is active at a time.
     * @param phaseIndex The index of the phase to activate.
     */
    function setCurrentMintPhase(uint256 phaseIndex) external onlyOwner {
        require(phaseIndex > 0, "Phase index must be greater than 0");
        // Optionally check if the phase is configured: require(_mintPhases[phaseIndex].startTime != 0, "Phase not configured");
        _currentMintPhase = phaseIndex;
        emit CurrentMintPhaseSet(phaseIndex);
    }

    /**
     * @dev Allows the owner to set the maximum total supply for the collection.
     * Can only increase the supply, not decrease below current supply.
     * @param supply The new maximum supply.
     */
    function setMaxSupply(uint256 supply) external onlyOwner {
        require(supply >= _totalSupply, "New max supply cannot be less than current supply");
        _maxSupply = supply;
        emit MaxSupplyUpdated(supply);
    }

    /**
     * @dev Pauses the minting process.
     */
    function pauseMinting() external onlyOwner whenNotPaused {
        _paused = true;
        emit ConfigUpdated("MintingPaused");
    }

    /**
     * @dev Unpauses the minting process.
     */
    function unpauseMinting() external onlyOwner whenPaused {
        _paused = false;
        emit ConfigUpdated("MintingUnpaused");
    }

    /**
     * @dev Allows the owner to withdraw the collected funds from the contract balance.
     * @param recipient The address to send the funds to.
     */
    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit Withdrawal(recipient, balance);
    }

    // --- Trait Configuration Functions (OnlyOwner) ---

    /**
     * @dev Sets or updates the possible values and their probabilities for a specific trait type.
     * Probabilities should sum to 10000 (basis points).
     * @param traitType The enum value of the trait type (converted to uint8).
     * @param possibleValues Array of string representations for trait values.
     * @param probabilities Array of probabilities (basis points) corresponding to possibleValues.
     * Must be same length as possibleValues.
     */
    function setTraitConfiguration(
        uint8 traitType,
        string[] memory possibleValues,
        uint256[] memory probabilities
    ) external onlyOwner {
        require(possibleValues.length == probabilities.length, "Arrays must have same length");
        require(possibleValues.length > 0, "Must provide at least one possible value");

        TraitConfig storage config = _traitConfigurations[traitType];
        delete config.possibleValues; // Clear old data
        delete config.cumulativeProbabilities;
        config.totalProbabilitySum = 0;

        uint256 cumulativeSum = 0;
        for (uint i = 0; i < possibleValues.length; i++) {
            require(probabilities[i] > 0, "Probabilities must be positive");
            config.possibleValues.push(possibleValues[i]);
            cumulativeSum = cumulativeSum.add(probabilities[i]);
            config.cumulativeProbabilities.push(cumulativeSum);
        }
        config.totalProbabilitySum = cumulativeSum;

        // Optional: Enforce sum to 10000 if using exact basis points.
        // require(config.totalProbabilitySum == 10000, "Probabilities must sum to 10000");

        emit ConfigUpdated(string(abi.encodePacked("TraitConfigUpdated_", Strings.toString(traitType))));
    }

     /**
     * @dev Adds a single possible value and its probability to an existing trait type configuration.
     * Updates cumulative probabilities. Only possible if trait type is already configured.
     * @param traitType The enum value of the trait type (converted to uint8).
     * @param value The string representation of the new trait value.
     * @param probability The probability (basis points) for the new value.
     */
    function addPossibleTraitValue(uint8 traitType, string memory value, uint256 probability) external onlyOwner {
        TraitConfig storage config = _traitConfigurations[traitType];
        require(config.possibleValues.length > 0, "Trait type not configured yet");
        require(probability > 0, "Probability must be positive");

        // Ensure the value doesn't already exist (simple check, could be improved for efficiency)
        for(uint i = 0; i < config.possibleValues.length; i++) {
            require(keccak256(bytes(config.possibleValues[i])) != keccak256(bytes(value)), "Value already exists");
        }

        config.possibleValues.push(value);
        uint256 cumulativeSum = config.totalProbabilitySum.add(probability);
        config.cumulativeProbabilities.push(cumulativeSum);
        config.totalProbabilitySum = cumulativeSum;

        emit ConfigUpdated(string(abi.encodePacked("TraitConfigAddValue_", Strings.toString(traitType))));
    }

     /**
     * @dev Removes a possible value from a trait type configuration.
     * Recalculates cumulative probabilities.
     * @param traitType The enum value of the trait type (converted to uint8).
     * @param value The string representation of the trait value to remove.
     */
    function removePossibleTraitValue(uint8 traitType, string memory value) external onlyOwner {
        TraitConfig storage config = _traitConfigurations[traitType];
        require(config.possibleValues.length > 1, "Cannot remove the last possible value");

        int256 indexToRemove = -1;
        uint256 probabilityOfRemoved = 0;

        for(uint i = 0; i < config.possibleValues.length; i++) {
            if (keccak256(bytes(config.possibleValues[i])) == keccak256(bytes(value))) {
                indexToRemove = int256(i);
                // Calculate the probability of the removed element
                probabilityOfRemoved = (i == 0) ? config.cumulativeProbabilities[i] : config.cumulativeProbabilities[i] - config.cumulativeProbabilities[i-1];
                break;
            }
        }

        require(indexToRemove != -1, "Value not found in trait configuration");

        // Shift elements and update cumulative probabilities
        string[] memory newPossibleValues = new string[](config.possibleValues.length - 1);
        uint256[] memory newCumulativeProbabilities = new uint256[](config.possibleValues.length - 1);
        uint256 currentCumulativeSum = 0;

        for (uint i = 0; i < config.possibleValues.length; i++) {
            if (int256(i) < indexToRemove) {
                newPossibleValues[i] = config.possibleValues[i];
                currentCumulativeSum = config.cumulativeProbabilities[i];
                newCumulativeProbabilities[i] = currentCumulativeSum;
            } else if (int256(i) > indexToRemove) {
                newPossibleValues[i - 1] = config.possibleValues[i];
                // Subtract the probability of the removed item from subsequent cumulative sums
                currentCumulativeSum = config.cumulativeProbabilities[i] - probabilityOfRemoved;
                newCumulativeProbabilities[i - 1] = currentCumulativeSum;
            }
        }

        delete config.possibleValues;
        delete config.cumulativeProbabilities;
        config.possibleValues = newPossibleValues;
        config.cumulativeProbabilities = newCumulativeProbabilities;
        config.totalProbabilitySum = currentCumulativeSum; // This is the new sum (should be 10000 - probabilityOfRemoved if starting sum was 10k)

        emit ConfigUpdated(string(abi.encodePacked("TraitConfigRemoveValue_", Strings.toString(traitType))));
    }


    // --- Trait Generation & Evolution ---

    /**
     * @dev Internal function to generate traits for a given token ID.
     * Requires a randomness source to be set.
     * Uses the configured trait probabilities.
     */
    function _generateTraits(uint256 tokenId) internal {
        require(_randomnessSource != address(0), "Randomness source not set");
        // Basic seed based on block data and token ID.
        // For real applications, use a secure VRF like Chainlink.
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, _totalSupply)));

        // Call the randomness source contract
        uint256 randomResult;
        try IRandomnessSource(_randomnessSource).getRandomNumber(seed) returns (uint256 number) {
            randomResult = number;
        } catch {
            // Fallback or error handling if randomness call fails
            // In a real scenario, this might trigger a retry or mint failure
            revert("Randomness source call failed");
        }

        // Use the random result to determine traits
        // Split the large random number into smaller parts for each trait
        uint256 traitRandomness = randomResult; // Use the full number initially

        TokenTraits storage traits = _tokenTraits[tokenId];

        // Iterate through each trait type and select a value based on randomness
        // The specific mapping from random number to trait index depends on your distribution logic.
        // Here we divide the random number repeatedly and use modulo/scaling.
        // A better approach uses the cumulative probability arrays set in TraitConfig.

        traits.background = _generateTraitValue(uint8(TraitType.Background), traitRandomness);
        traitRandomness /= _traitConfigurations[uint8(TraitType.Background)].totalProbabilitySum; // Consume randomness

        traits.body = _generateTraitValue(uint8(TraitType.Body), traitRandomness);
        traitRandomness /= _traitConfigurations[uint8(TraitType.Body)].totalProbabilitySum; // Consume randomness

        traits.eyes = _generateTraitValue(uint8(TraitType.Eyes), traitRandomness);
        traitRandomness /= _traitConfigurations[uint8(TraitType.Eyes)].totalProbabilitySum; // Consume randomness

        traits.accessory = _generateTraitValue(uint8(TraitType.Accessory), traitRandomness);
        // No division after the last trait

        emit TraitsGenerated(tokenId, traits);
    }

    /**
     * @dev Internal helper to select a trait value index based on randomness and probability configuration.
     * @param traitType The enum value of the trait type.
     * @param randomValue A random number used for selection.
     * @return The index of the selected trait value in the TraitConfig's possibleValues array.
     */
    function _generateTraitValue(uint8 traitType, uint256 randomValue) internal view returns (uint8) {
        TraitConfig storage config = _traitConfigurations[traitType];
        require(config.possibleValues.length > 0, "Trait config missing for type");
        require(config.totalProbabilitySum > 0, "Trait probabilities not set for type");

        // Scale the random value to the total probability sum range
        uint256 scaledRandom = randomValue % config.totalProbabilitySum;

        // Find the first cumulative probability that is greater than the scaled random value
        for (uint i = 0; i < config.cumulativeProbabilities.length; i++) {
            if (scaledRandom < config.cumulativeProbabilities[i]) {
                return uint8(i); // Return the index of the selected trait value
            }
        }

        // Should not reach here if probabilities sum correctly and scaledRandom is within range
        // Return the last trait as a fallback or revert
        return uint8(config.possibleValues.length - 1);
    }


    /**
     * @dev Allows the owner of a token to pay a fee to re-generate the traits for that token.
     * This makes the NFT dynamic - its appearance can change.
     * @param tokenId The ID of the token to evolve.
     */
    function evolveToken(uint256 tokenId) external payable isValidTokenId(tokenId) {
        require(msg.sender == ownerOf(tokenId), "Only token owner can evolve");
        require(msg.value >= _evolutionCost, "Insufficient funds for evolution");
        require(_evolutionCost > 0, "Evolution is not enabled (cost is 0)");

        TokenTraits memory oldTraits = _tokenTraits[tokenId]; // Copy before potential overwrite
        _generateTraits(tokenId); // Regenerate traits for the same token ID
        TokenTraits memory newTraits = _tokenTraits[tokenId];

        // Refund excess payment if any
        if (msg.value > _evolutionCost) {
            payable(msg.sender).transfer(msg.value - _evolutionCost);
        }

        emit TokenEvolved(tokenId, oldTraits, newTraits);
    }

    /**
     * @dev Allows the owner to set the cost required to evolve a token.
     * Set to 0 to disable evolution.
     * @param cost The new cost to evolve a token (in wei).
     */
    function setEvolutionCost(uint256 cost) external onlyOwner {
        _evolutionCost = cost;
        emit EvolutionCostUpdated(cost);
    }

    /**
     * @dev Allows the owner to set the address of the randomness source contract.
     * This contract must implement the IRandomnessSource interface.
     * @param source The address of the randomness source contract.
     */
    function setRandomnessSource(address source) external onlyOwner {
        require(source != address(0), "Randomness source cannot be zero address");
        _randomnessSource = source;
        emit RandomnessSourceSet(source);
    }


    // --- Metadata Generation (Internal Helpers) ---

    /**
     * @dev Internal function to generate the full JSON metadata string for a token.
     * Includes name, description, traits, and SVG image data.
     * @param tokenId The ID of the token.
     * @return The JSON metadata string.
     */
    function _generateMetadataJson(uint256 tokenId) internal view returns (string memory) {
        TokenTraits memory traits = _tokenTraits[tokenId];
        TraitConfig storage backgroundConfig = _traitConfigurations[uint8(TraitType.Background)];
        TraitConfig storage bodyConfig = _traitConfigurations[uint8(TraitType.Body)];
        TraitConfig storage eyesConfig = _traitConfigurations[uint8(TraitType.Eyes)];
        TraitConfig storage accessoryConfig = _traitConfigurations[uint8(TraitType.Accessory)];

        // Basic validation that configs exist (should be set in constructor or by owner)
        require(backgroundConfig.possibleValues.length > traits.background, "Invalid background trait index");
        require(bodyConfig.possibleValues.length > traits.body, "Invalid body trait index");
        require(eyesConfig.possibleValues.length > traits.eyes, "Invalid eyes trait index");
        require(accessoryConfig.possibleValues.length > traits.accessory, "Invalid accessory trait index");

        string memory name = string(abi.encodePacked("Generative Art #", Strings.toString(tokenId)));
        string memory description = "A unique piece of generative art, defined by on-chain traits.";

        // Attributes JSON array
        string memory attributes = string(abi.encodePacked(
            '[',
            '{"trait_type": "Background", "value": "', backgroundConfig.possibleValues[traits.background], '"},',
            '{"trait_type": "Body", "value": "', bodyConfig.possibleValues[traits.body], '"},',
            '{"trait_type": "Eyes", "value": "', eyesConfig.possibleValues[traits.eyes], '"},',
            '{"trait_type": "Accessory", "value": "', accessoryConfig.possibleValues[traits.accessory], '"}'
            // Add more traits here
            ,']'
        ));

        // Generate SVG image data on-chain (example implementation - can be gas intensive!)
        string memory svgImage = _generateSvgImage(traits);
        string memory imageBase64 = Base64.encode(bytes(svgImage));
        string memory imageUri = string(abi.encodePacked("data:image/svg+xml;base64,", imageBase64));

        // Construct the final JSON string
        return string(abi.encodePacked(
            '{',
            '"name": "', name, '",',
            '"description": "', description, '",',
            '"image": "', imageUri, '",', // Or use _baseTokenURI for external image hosting
            '"attributes": ', attributes,
            '}'
        ));
    }

    /**
     * @dev Internal function to generate a simple SVG image based on token traits.
     * This is a highly simplified example. Real on-chain SVG generation can be complex
     * and gas-intensive depending on the art complexity.
     * @param traits The traits of the token.
     * @return The SVG XML string.
     */
    function _generateSvgImage(TokenTraits memory traits) internal view returns (string memory) {
        // Get string values for traits based on indices
        string memory background = _traitConfigurations[uint8(TraitType.Background)].possibleValues[traits.background];
        string memory body = _traitConfigurations[uint8(TraitType.Body)].possibleValues[traits.body];
        string memory eyes = _traitConfigurations[uint8(TraitType.Eyes)].possibleValues[traits.eyes];
        string memory accessory = _traitConfigurations[uint8(TraitType.Accessory)].possibleValues[traits.accessory];

        // Map trait values to SVG properties (e.g., colors, shapes)
        string memory bgColor = "white";
        if (keccak256(bytes(background)) == keccak256(bytes("Red"))) bgColor = "red";
        else if (keccak256(bytes(background)) == keccak256(bytes("Blue"))) bgColor = "blue";
        else if (keccak256(bytes(background)) == keccak256(bytes("Green"))) bgColor = "green";

        string memory bodyShape = "";
        if (keccak256(bytes(body)) == keccak256(bytes("Square"))) bodyShape = '<rect x="75" y="75" width="50" height="50" fill="purple"/>';
        else if (keccak256(bytes(body)) == keccak256(bytes("Circle"))) bodyShape = '<circle cx="100" cy="100" r="30" fill="orange"/>';

        string memory eyeShape = "";
         if (keccak256(bytes(eyes)) == keccak256(bytes("Dot"))) eyeShape = '<circle cx="90" cy="90" r="3" fill="black"/><circle cx="110" cy="90" r="3" fill="black"/>';
         else if (keccak256(bytes(eyes)) == keccak256(bytes("Star"))) eyeShape = '<text x="85" y="95" font-size="15">*</text><text x="105" y="95" font-size="15">*</text>';


        string memory accessoryShape = "";
        if (keccak256(bytes(accessory)) == keccak256(bytes("Hat"))) accessoryShape = '<path d="M 80 70 L 120 70 L 110 50 L 90 50 Z" fill="brown"/>';
        else if (keccak256(bytes(accessory)) == keccak256(bytes("Glasses"))) accessoryShape = '<rect x="85" y="92" width="30" height="5" fill="gray"/>';
        // "None" means no accessory shape

        // Construct the SVG string
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">',
            '<rect width="100%" height="100%" fill="', bgColor, '"/>', // Background
            bodyShape, // Body shape
            eyeShape, // Eyes
            accessoryShape, // Accessory
            // Add text or other elements based on traits
            '</svg>'
        ));
    }

    // --- Royalty Functions (OnlyOwner) ---

    /**
     * @dev Sets the default royalty information for the entire collection (EIP-2981).
     * @param recipient The address that receives the royalty payments.
     * @param basisPoints The royalty percentage in basis points (e.g., 500 for 5%). Max 10000.
     */
    function setDefaultRoyalty(address recipient, uint96 basisPoints) external onlyOwner {
        require(basisPoints <= 10000, "Royalty basis points cannot exceed 10000 (100%)");
        _defaultRoyaltyRecipient = recipient;
        _defaultRoyaltyBps = basisPoints;
        emit RoyaltyUpdated(recipient, basisPoints);
    }

    // --- View Functions (Public/View) ---

    /**
     * @dev Gets the generated traits for a specific token ID.
     * @param tokenId The ID of the token.
     * @return The TokenTraits struct.
     */
    function getTraits(uint256 tokenId) public view isValidTokenId(tokenId) returns (TokenTraits memory) {
        return _tokenTraits[tokenId];
    }

     /**
     * @dev Gets the configuration details for a specific trait type.
     * @param traitType The enum value of the trait type (converted to uint8).
     * @return possibleValues Array of possible string values.
     * @return cumulativeProbabilities Array of cumulative probabilities.
     * @return totalProbabilitySum The sum of all probabilities.
     */
    function getTraitConfiguration(uint8 traitType) public view returns (string[] memory, uint256[] memory, uint256) {
        TraitConfig storage config = _traitConfigurations[traitType];
        return (config.possibleValues, config.cumulativeProbabilities, config.totalProbabilitySum);
    }

    /**
     * @dev Gets the address of the configured randomness source contract.
     */
    function getRandomnessSource() public view returns (address) {
        return _randomnessSource;
    }

    /**
     * @dev Gets the current total number of minted tokens.
     */
    function getCurrentSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the maximum allowed total supply for the collection.
     */
    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

     /**
     * @dev Gets the index of the currently active minting phase.
     */
    function getCurrentMintPhase() public view returns (uint256) {
        return _currentMintPhase;
    }

    /**
     * @dev Gets the configuration details for a specific minting phase.
     * @param phaseIndex The index of the phase.
     * @return cost The cost per token.
     * @return startTime The start timestamp.
     * @return endTime The end timestamp.
     * @return maxPerWallet Max tokens per wallet (0 for no limit).
     */
    function getMintPhaseConfig(uint256 phaseIndex) public view returns (uint256 cost, uint64 startTime, uint64 endTime, uint16 maxPerWallet) {
        MintPhaseConfig storage phase = _mintPhases[phaseIndex];
        return (phase.cost, phase.startTime, phase.endTime, phase.maxPerWallet);
    }

     /**
     * @dev Gets the cost to mint a single token in the current active phase.
     * Returns 0 if no phase is active or configured.
     */
    function getMintCost() public view returns (uint256) {
        return _mintPhases[_currentMintPhase].cost;
    }

    /**
     * @dev Gets the cost required to evolve a token.
     */
    function getEvolutionCost() public view returns (uint256) {
        return _evolutionCost;
    }

     /**
     * @dev Gets the default royalty recipient and basis points.
     */
    function getDefaultRoyaltyInfo() public view returns (address, uint96) {
        return (_defaultRoyaltyRecipient, _defaultRoyaltyBps);
    }

    // --- Inherited View Functions (already public/external) ---
    // balanceOf(address owner)
    // ownerOf(uint256 tokenId)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)

    // --- Internal/Private Functions ---
    // _generateMetadataJson(uint256 tokenId)
    // _generateSvgImage(TokenTraits memory traits)
    // _generateTraits(uint256 tokenId)
    // _generateTraitValue(uint8 traitType, uint256 randomValue)
    // _exists(uint256 tokenId) - From ERC721
    // _safeMint(address to, uint256 tokenId) - From ERC721
    // _burn(uint256 tokenId) - From ERC721 (can be exposed if public burn is desired)
    // _setApprovalForAll(address owner, address operator, bool approved) - From ERC721
    // _approve(address to, uint256 tokenId) - From ERC721
    // _transfer(address from, address to, uint256 tokenId) - From ERC721
    // _checkAuthorized(address owner) - From ERC721 (internal helper)
    // _update(address to, uint256 tokenId) - From ERC721 (internal state update)
    // _startTokenId() - From ERC721 (internal helper)

    // Note: The provided Base64 library is typically included via import from OpenZeppelin.
    // If not using OpenZeppelin, you would need to include the Base64 library code directly.
}
```

**Explanation of Concepts and Advanced Features:**

1.  **On-Chain Trait Generation:** Instead of linking to an external JSON/image file, the core properties (`_tokenTraits`) are stored directly on the blockchain. The `_generateTraits` function determines these traits using randomness and configurable rules.
2.  **Configurable Trait Probabilities:** The `setTraitConfiguration`, `addPossibleTraitValue`, and `removePossibleTraitValue` functions allow the owner to define the possible values for each trait type (e.g., Background: Red, Blue, Green) and set their probabilities. The `_generateTraitValue` helper uses these probabilities (stored as cumulative sums) to randomly select a trait value index. This makes the collection generation rules dynamic and owner-controlled.
3.  **Puggable Randomness Source:** Using the `IRandomnessSource` interface and the `setRandomnessSource` function, the contract owner can specify *which* contract provides the randomness. This allows upgrading the randomness source (e.g., from a simple blockhash-based method to a Chainlink VRF consumer) without changing the core logic of the NFT contract itself.
4.  **Dynamic Evolution (`evolveToken`):** The `evolveToken` function introduces dynamism. Token owners can pay a fee to completely re-generate the traits of their existing NFT. This changes the NFT's appearance and rarity based on the *current* trait configurations and randomness source, rather than being fixed forever at mint.
5.  **On-Chain SVG Metadata (`_generateSvgImage`, `_generateMetadataJson`, `tokenURI`):** The contract generates the entire metadata JSON, including the image data encoded as an SVG, directly within the `tokenURI` function. This means the NFT's appearance is fully determined and rendered *by the smart contract data itself*, removing reliance on external servers for image generation. The `_generateSvgImage` is a simplified example; complex generative art SVGs on-chain can be very gas-intensive.
6.  **Configurable Mint Phases:** The `setMintPhase` and `setCurrentMintPhase` functions allow the owner to define different stages for minting with varying costs, time limits, and per-wallet limits. This is common in NFT drops but implemented here with explicit phase management.
7.  **EIP-2981 Royalty Standard:** Implemented `royaltyInfo` to support marketplaces that read this standard for secondary sales royalties.
8.  **Extensive Owner Controls:** Many functions (`set...`, `pause...`, `unpause...`, `withdraw`, `transferOwnership`) are `onlyOwner`, giving the deployer fine-grained control over the collection's parameters, minting process, and revenue.

This contract goes beyond a standard ERC721 by implementing core generative and dynamic logic, along with metadata generation and configuration, entirely on-chain. The pluggable randomness source and token evolution add layers of advanced functionality not found in typical static NFT contracts.