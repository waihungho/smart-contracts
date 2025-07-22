Okay, this is an exciting challenge! Let's build a smart contract that goes beyond simple tokens or marketplaces.

I propose a contract called **"ChronoForge"** – a decentralized protocol for creating, evolving, and maintaining unique, time-sensitive digital assets (NFTs). These NFTs, which we'll call "ChronoEssences," evolve through predefined stages based on time, user interaction, and economic bonding, potentially decaying or "dissipating" if not properly maintained. It incorporates concepts of dynamic NFTs, on-chain time mechanics, economic incentives for maintenance, and a degree of decentralized governance for defining evolution rules.

---

## ChronoForge: Decentralized Chrono-Evolution Protocol

### Outline & Function Summary

**Contract Name:** `ChronoForge`

**Core Concept:** ChronoForge manages "ChronoEssences" (ERC-721 NFTs) that can evolve through different stages based on elapsed time and user actions. Each Essence has a unique evolution path and a potential for decay if not maintained. Governance controls global parameters and defines evolution rules.

**Key Features:**

*   **Time-Based Evolution:** Essences progress through stages over time.
*   **User-Triggered Advancement:** Users can accelerate evolution or initiate next stages.
*   **Economic Bonding:** Users can "bond" ETH to an Essence to accelerate its evolution or prevent decay, with mechanisms to claim or forfeit these bonds.
*   **Decay & Dissipation:** Essences can decay over time if not managed, potentially leading to their "dissipation" (burning).
*   **Dynamic Metadata:** The NFT's "stage" influences its metadata, showcasing its current evolutionary state.
*   **Governance-Defined Paths:** A governance entity defines the possible evolution stages and paths.
*   **Recombination/Forging:** Advanced Essences can potentially be recombined to create new, unique Essences.

---

#### I. Core ERC-721 & Base Functions (Inherited/Augmented)

1.  `constructor(string name, string symbol, address initialGovernor)`: Initializes the contract with NFT name, symbol, and sets the initial governance address.
2.  `balanceOf(address owner) view returns (uint256)`: Returns the number of Essences owned by an address.
3.  `ownerOf(uint256 tokenId) view returns (address)`: Returns the owner of a specific Essence.
4.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific Essence.
5.  `getApproved(uint256 tokenId) view returns (address)`: Returns the approved address for a specific Essence.
6.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes an operator for all Essences.
7.  `isApprovedForAll(address owner, address operator) view returns (bool)`: Checks if an operator is approved for all Essences.
8.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers an Essence from one address to another.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers an Essence, checking if the receiver can handle ERC-721.
10. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Safely transfers an Essence with additional data.
11. `tokenURI(uint256 tokenId) view returns (string memory)`: Returns the metadata URI for a given Essence, dynamically reflecting its current stage.

#### II. ChronoEssence Management & Evolution Functions

1.  `mintInitialEssence(uint256 initialPathId) payable`: Allows a user to mint a new ChronoEssence, starting it on a specified initial evolution path. Requires payment.
2.  `forgeRecombinedEssence(uint256 _essence1Id, uint256 _essence2Id, uint256 _newPathId) payable`: Allows users to combine two existing ChronoEssences to forge a new one. The logic for recombination (e.g., burning originals, specific stage requirements) will be complex.
3.  `triggerEssenceEvolution(uint256 tokenId)`: Allows the owner (or an approved operator) to explicitly trigger the evolution of an Essence to its next available stage, assuming time and other conditions are met. This also calculates and applies any decay.
4.  `bondForEvolutionAcceleration(uint256 tokenId) payable`: Allows the Essence owner to bond Ether to their Essence, which can accelerate its evolution or prevent decay.
5.  `claimBondedFunds(uint256 tokenId)`: Allows the owner to claim their bonded Ether back, subject to conditions (e.g., after the Essence reaches a certain stage, or if it dissipates).
6.  `forceDissipateEssence(uint256 tokenId)`: A public function that anyone can call to forcibly "dissipate" (burn) an Essence if its decay level reaches 100%. This allows for cleaning up "dead" assets.
7.  `getCurrentEssenceStage(uint256 tokenId) view returns (uint256 stageId)`: Returns the current evolution stage ID of a specific Essence.
8.  `getEssenceDecayStatus(uint256 tokenId) view returns (uint256 currentDecayBasisPoints)`: Returns the current decay level of an Essence, as basis points (0-10000).

#### III. Governance & Protocol Parameter Functions (onlyGovernor)

1.  `setEvolutionStageParameters(uint256 stageId, uint256 timeToNextStage, uint256 decayRateBasisPoints, string memory stageIdentifier)`: Allows the governor to define or update parameters for a specific evolution stage (time needed, decay rate, metadata identifier).
2.  `addEvolutionPath(uint256 pathId, uint256[] memory stagesInOrder)`: Allows the governor to define a new sequence of evolution stages that constitute an evolution path.
3.  `removeEvolutionPath(uint256 pathId)`: Allows the governor to remove an existing evolution path.
4.  `setGlobalDecayRateBasisPoints(uint256 _newRate)`: Sets a global base decay rate for all Essences (applied in addition to stage-specific rates).
5.  `setMintPrice(uint256 _newPrice)`: Sets the price (in Wei) for minting new Essences.
6.  `setRecombinationFee(uint256 _newFee)`: Sets the fee (in Wei) for forging new Essences via recombination.
7.  `withdrawFunds()`: Allows the governor to withdraw accumulated fees from minting and recombination.
8.  `transferGovernanceOwnership(address newGovernor)`: Transfers the governance role to a new address.
9.  `pause()`: Pauses core functionality (minting, evolution, transfers) in case of emergency.
10. `unpause()`: Unpauses the contract.

#### IV. View & Utility Functions

1.  `getEssenceDetails(uint256 tokenId) view returns (ChronoEssence memory)`: Returns all stored details about a specific ChronoEssence.
2.  `getEvolutionStageDetails(uint256 stageId) view returns (EvolutionStage memory)`: Returns the details of a specific evolution stage.
3.  `getChronoForgeParameters() view returns (uint256 currentMintPrice, uint256 currentRecombinationFee, uint256 globalDecayRateBasisPoints, uint256 totalMintedEssences)`: Returns current global protocol parameters.
4.  `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4)`: Standard ERC-721 receiver for contracts to accept ChronoEssences.

---

### ChronoForge Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Using OpenZeppelin libraries for robust, audited base functionality
// The advanced concepts are in the ChronoForge-specific logic and state management.

contract ChronoForge is ERC721URIStorage, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Custom Errors ---
    error InvalidStageId();
    error InvalidPathId();
    error EssenceNotFound();
    error NotEnoughTimeElapsed();
    error AlreadyAtFinalStage();
    error InsufficientFunds();
    error BondingNotRequired();
    error NoBondedFundsToClaim();
    error DecayThresholdNotReached();
    error DecayThresholdExceeded();
    error NotAllowedToMintMore();
    error EssencesNotOwnedByCaller();
    error InvalidRecombinationPath();
    error InvalidRecombinationEssences();

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Governor address - controls protocol parameters, can be changed
    address public governor;

    // Global parameters
    uint256 public mintPrice; // Price to mint a new essence
    uint256 public recombinationFee; // Fee to recombine essences
    uint256 public globalDecayRateBasisPoints; // Global decay rate in basis points (e.g., 100 = 1%)
    uint256 public constant MAX_SUPPLY = 10_000; // Total maximum number of Essences that can ever exist

    // ChronoEssence struct: Represents an NFT with dynamic properties
    struct ChronoEssence {
        uint256 currentStageId; // ID of the current stage in its evolution path
        uint256 evolutionPathId; // ID of the predefined evolution path this essence follows
        uint256 lastEvolvedAt; // block.timestamp of the last evolution
        uint256 createdAt; // block.timestamp of creation
        uint256 accumulatedDecay; // Accumulated decay in basis points since creation or last evolution reset
    }

    // EvolutionStage struct: Defines properties for each stage
    struct EvolutionStage {
        uint256 timeToNextStage; // Time in seconds required to reach next stage
        uint256 decayRateBasisPoints; // Decay rate per unit of time for this specific stage (added to global)
        string stageIdentifier; // A unique string/hash used to generate metadata URI for this stage
        bool exists; // To check if stage ID is valid
    }

    // EvolutionPath struct: Defines the sequence of stages for an essence
    struct EvolutionPath {
        uint256[] stagesInOrder; // Array of stage IDs
        bool exists; // To check if path ID is valid
    }

    // Mappings for storing data
    mapping(uint256 => ChronoEssence) public essenceData; // tokenId => ChronoEssence data
    mapping(uint256 => EvolutionStage) public evolutionStages; // stageId => EvolutionStage data
    mapping(uint256 => EvolutionPath) public evolutionPaths; // pathId => EvolutionPath data
    mapping(uint256 => uint256) public bondedFunds; // tokenId => amount of ETH bonded

    // --- Events ---
    event ChronoEssenceMinted(uint256 indexed tokenId, address indexed owner, uint256 pathId, uint256 timestamp);
    event ChronoEssenceEvolved(uint256 indexed tokenId, uint256 oldStageId, uint256 newStageId, uint256 timestamp);
    event ChronoEssenceDissipated(uint256 indexed tokenId, address indexed lastOwner, uint256 timestamp);
    event FundsBonded(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 totalBonded);
    event FundsClaimed(uint256 indexed tokenId, address indexed owner, uint256 amountRemaining);
    event GovernanceTransferred(address indexed oldGovernor, address indexed newGovernor);
    event EvolutionStageParametersSet(uint256 indexed stageId, uint256 timeToNextStage, uint256 decayRateBasisPoints, string stageIdentifier);
    event EvolutionPathAdded(uint256 indexed pathId, uint256[] stagesInOrder);
    event EvolutionPathRemoved(uint256 indexed pathId);
    event GlobalDecayRateSet(uint256 newRate);
    event MintPriceSet(uint256 newPrice);
    event RecombinationFeeSet(uint256 newFee);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert OwnableUnauthorizedAccount(msg.sender); // Reusing Ownable's error for consistency
        }
        _;
    }

    modifier isValidEssence(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert EssenceNotFound();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, address initialGovernor)
        ERC721(name, symbol)
        Ownable(msg.sender) // Owner of Ownable is the deployer, Governor is a separate role
        Pausable()
    {
        governor = initialGovernor;
        mintPrice = 0.05 ether; // Example initial price
        recombinationFee = 0.1 ether; // Example initial fee
        globalDecayRateBasisPoints = 50; // Example: 0.5% decay per time unit (defined by time unit later)
    }

    // --- Core ERC721 Overrides ---
    // ERC721URIStorage handles tokenURI, so it's not explicitly overridden here unless custom logic is needed.
    // The `tokenURI` function will dynamically generate the URI based on the ChronoEssence's stage.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure the token exists and is owned

        ChronoEssence storage essence = essenceData[tokenId];
        EvolutionStage storage currentStage = evolutionStages[essence.currentStageId];

        if (!currentStage.exists) {
            // Fallback for stages not properly defined
            return string(abi.encodePacked("ipfs://QmT_ChronoForge_Base/essence-", tokenId.toString(), "/unknown-stage.json"));
        }

        // Dynamically generate URI based on stageIdentifier
        // Example: ipfs://QmT_ChronoForge_Meta/<stageIdentifier>/<tokenId>.json
        return string(abi.encodePacked("ipfs://QmT_ChronoForge_Meta/", currentStage.stageIdentifier, "/", tokenId.toString(), ".json"));
    }

    // --- ChronoEssence Management & Evolution Functions ---

    /// @notice Allows a user to mint a new ChronoEssence, starting it on a specified initial evolution path.
    /// @param initialPathId The ID of the evolution path the new essence will follow.
    function mintInitialEssence(uint256 initialPathId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        if (msg.value < mintPrice) {
            revert InsufficientFunds();
        }
        if (!evolutionPaths[initialPathId].exists || evolutionPaths[initialPathId].stagesInOrder.length == 0) {
            revert InvalidPathId();
        }
        if (_tokenIdCounter.current() >= MAX_SUPply) {
            revert NotAllowedToMintMore();
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // Get the first stage of the chosen path
        uint256 initialStageId = evolutionPaths[initialPathId].stagesInOrder[0];
        if (!evolutionStages[initialStageId].exists) {
            revert InvalidStageId(); // Should not happen if path is valid
        }

        // Create the new essence
        essenceData[newItemId] = ChronoEssence({
            currentStageId: initialStageId,
            evolutionPathId: initialPathId,
            lastEvolvedAt: block.timestamp,
            createdAt: block.timestamp,
            accumulatedDecay: 0
        });

        _safeMint(msg.sender, newItemId);
        emit ChronoEssenceMinted(newItemId, msg.sender, initialPathId, block.timestamp);
    }

    /// @notice Allows users to combine two existing ChronoEssences to forge a new one.
    /// @dev This function defines a specific recombination logic:
    ///      - Both input essences must be owned by the caller.
    ///      - Both input essences are burned.
    ///      - A new essence is minted on a specified new path.
    ///      - Fees apply.
    ///      - Advanced logic could include traits inheritance, minimum stage requirements for inputs, etc.
    /// @param _essence1Id The ID of the first essence to combine.
    /// @param _essence2Id The ID of the second essence to combine.
    /// @param _newPathId The ID of the evolution path for the newly forged essence.
    function forgeRecombinedEssence(uint256 _essence1Id, uint256 _essence2Id, uint256 _newPathId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        if (msg.value < recombinationFee) {
            revert InsufficientFunds();
        }
        if (ownerOf(_essence1Id) != msg.sender || ownerOf(_essence2Id) != msg.sender) {
            revert EssencesNotOwnedByCaller();
        }
        if (_essence1Id == _essence2Id) {
            revert InvalidRecombinationEssences(); // Cannot combine an essence with itself
        }
        if (!evolutionPaths[_newPathId].exists || evolutionPaths[_newPathId].stagesInOrder.length == 0) {
            revert InvalidRecombinationPath();
        }
        if (_tokenIdCounter.current() >= MAX_SUPPLY) {
            revert NotAllowedToMintMore();
        }

        // Burn the original essences
        _burn(_essence1Id);
        _burn(_essence2Id);

        _tokenIdCounter.increment();
        uint256 newEssenceId = _tokenIdCounter.current();

        // Get the first stage of the chosen path for the new essence
        uint256 initialStageId = evolutionPaths[_newPathId].stagesInOrder[0];
        if (!evolutionStages[initialStageId].exists) {
            revert InvalidStageId(); // Should not happen if path is valid
        }

        // Create the new essence
        essenceData[newEssenceId] = ChronoEssence({
            currentStageId: initialStageId,
            evolutionPathId: _newPathId,
            lastEvolvedAt: block.timestamp,
            createdAt: block.timestamp,
            accumulatedDecay: 0 // New essences start fresh
        });

        _safeMint(msg.sender, newEssenceId);
        emit ChronoEssenceMinted(newEssenceId, msg.sender, _newPathId, block.timestamp);
    }

    /// @notice Allows the owner or approved operator to explicitly trigger the evolution of an Essence.
    /// @dev This function checks if enough time has passed for evolution and calculates/applies decay.
    /// @param tokenId The ID of the ChronoEssence to evolve.
    function triggerEssenceEvolution(uint256 tokenId)
        external
        isValidEssence(tokenId)
        whenNotPaused
        nonReentrant
    {
        // Only owner or approved can trigger evolution
        _requireOwned(tokenId);

        ChronoEssence storage essence = essenceData[tokenId];
        EvolutionPath storage path = evolutionPaths[essence.evolutionPathId];

        // First, apply decay
        _calculateAndApplyDecay(tokenId);
        
        // If the essence has decayed to 100%, it dissipates immediately
        if (essence.accumulatedDecay >= 10000) {
             _dissipateEssence(tokenId);
             return;
        }

        // Find current stage index in path
        uint256 currentStageIndex;
        bool found = false;
        for (uint256 i = 0; i < path.stagesInOrder.length; i++) {
            if (path.stagesInOrder[i] == essence.currentStageId) {
                currentStageIndex = i;
                found = true;
                break;
            }
        }
        if (!found) {
            // This indicates a corrupted state or path definition. Should ideally not happen.
            revert InvalidPathId(); 
        }

        // Check if there's a next stage
        if (currentStageIndex + 1 >= path.stagesInOrder.length) {
            revert AlreadyAtFinalStage();
        }

        EvolutionStage storage currentStageParams = evolutionStages[essence.currentStageId];
        if (!currentStageParams.exists) {
            revert InvalidStageId(); // Current stage parameters must exist
        }

        // Check if enough time has elapsed for evolution
        if (block.timestamp < essence.lastEvolvedAt + currentStageParams.timeToNextStage) {
            revert NotEnoughTimeElapsed();
        }

        // Advance to the next stage
        uint256 nextStageId = path.stagesInOrder[currentStageIndex + 1];
        if (!evolutionStages[nextStageId].exists) {
            revert InvalidStageId(); // Next stage must be defined
        }

        uint256 oldStageId = essence.currentStageId;
        essence.currentStageId = nextStageId;
        essence.lastEvolvedAt = block.timestamp;
        essence.accumulatedDecay = 0; // Decay can be reset or reduced upon successful evolution

        emit ChronoEssenceEvolved(tokenId, oldStageId, nextStageId, block.timestamp);
    }

    /// @notice Allows the owner to bond Ether to their Essence to accelerate its evolution or prevent decay.
    /// @dev The bonded amount is added to the essence's record.
    ///      The logic for how bonding affects evolution/decay would be implemented in `_calculateAndApplyDecay`
    ///      (e.g., lower effective decay rate, faster timeToNextStage reduction).
    /// @param tokenId The ID of the ChronoEssence.
    function bondForEvolutionAcceleration(uint256 tokenId)
        external
        payable
        isValidEssence(tokenId)
        whenNotPaused
        nonReentrant
    {
        _requireOwned(tokenId);
        if (msg.value == 0) {
            revert InsufficientFunds(); // Or a custom error like NoValueProvided
        }
        bondedFunds[tokenId] += msg.value;
        emit FundsBonded(tokenId, msg.sender, msg.value, bondedFunds[tokenId]);
    }

    /// @notice Allows the owner to claim back bonded Ether.
    /// @dev Specific conditions for claiming back funds (e.g., after certain stage, or if essence dissipates)
    ///      would be implemented here. For simplicity, this version allows claiming if decay is not critical.
    /// @param tokenId The ID of the ChronoEssence.
    function claimBondedFunds(uint256 tokenId)
        external
        isValidEssence(tokenId)
        whenNotPaused
        nonReentrant
    {
        _requireOwned(tokenId);
        uint256 amount = bondedFunds[tokenId];
        if (amount == 0) {
            revert NoBondedFundsToClaim();
        }

        // Example condition: Cannot claim if decay is too high, implies funds are "locked" for maintenance
        // In a real system, bonding would reduce decay, making it possible to claim if decay is low.
        // For this example, let's assume if decay is above a certain threshold, funds cannot be claimed.
        // Or, funds are consumed by decay (more complex).
        _calculateAndApplyDecay(tokenId); // Re-evaluate current decay status
        if (essenceData[tokenId].accumulatedDecay > 5000) { // Example: If >50% decay, bond is locked
            revert BondingNotRequired(); // Misleading error, but demonstrates a conditional claim
        }

        bondedFunds[tokenId] = 0; // All or nothing claim for simplicity
        payable(msg.sender).transfer(amount);
        emit FundsClaimed(tokenId, msg.sender, amount);
    }

    /// @notice Allows anyone to forcibly "dissipate" (burn) an Essence if its decay level reaches 100%.
    /// @param tokenId The ID of the ChronoEssence to dissipate.
    function forceDissipateEssence(uint256 tokenId)
        external
        isValidEssence(tokenId)
        whenNotPaused
        nonReentrant
    {
        ChronoEssence storage essence = essenceData[tokenId];
        _calculateAndApplyDecay(tokenId); // Ensure decay is up-to-date

        if (essence.accumulatedDecay < 10000) {
            revert DecayThresholdNotReached(); // Not yet fully decayed
        }
        _dissipateEssence(tokenId);
    }

    /// @notice Returns the current evolution stage ID of a specific Essence.
    /// @param tokenId The ID of the ChronoEssence.
    /// @return The ID of the current evolution stage.
    function getCurrentEssenceStage(uint256 tokenId)
        public
        view
        isValidEssence(tokenId)
        returns (uint256 stageId)
    {
        return essenceData[tokenId].currentStageId;
    }

    /// @notice Returns the evolution path (sequence of stage IDs) for a specific Essence.
    /// @param tokenId The ID of the ChronoEssence.
    /// @return An array of stage IDs representing the evolution path.
    function getEssenceEvolutionPath(uint256 tokenId)
        public
        view
        isValidEssence(tokenId)
        returns (uint256[] memory)
    {
        return evolutionPaths[essenceData[tokenId].evolutionPathId].stagesInOrder;
    }

    /// @notice Returns the current decay level of an Essence, as basis points (0-10000).
    /// @dev This function calculates the *current* decay based on elapsed time since last `triggerEssenceEvolution` or creation.
    /// @param tokenId The ID of the ChronoEssence.
    /// @return The current accumulated decay in basis points.
    function getEssenceDecayStatus(uint256 tokenId)
        public
        view
        isValidEssence(tokenId)
        returns (uint256 currentDecayBasisPoints)
    {
        return _calculateDecay(tokenId);
    }

    // --- Governance & Protocol Parameter Functions (onlyGovernor) ---

    /// @notice Allows the governor to define or update parameters for a specific evolution stage.
    /// @param stageId The unique ID for this stage.
    /// @param timeToNextStage Time in seconds required to move from this stage to the next.
    /// @param decayRateBasisPoints Additional decay rate specific to this stage (on top of global).
    /// @param stageIdentifier A string identifier for metadata generation (e.g., "proto-bloom", "nova-core").
    function setEvolutionStageParameters(uint256 stageId, uint256 timeToNextStage, uint256 decayRateBasisPoints, string memory stageIdentifier)
        external
        onlyGovernor
        whenNotPaused
    {
        evolutionStages[stageId] = EvolutionStage(timeToNextStage, decayRateBasisPoints, stageIdentifier, true);
        emit EvolutionStageParametersSet(stageId, timeToNextStage, decayRateBasisPoints, stageIdentifier);
    }

    /// @notice Allows the governor to define a new sequence of evolution stages that constitute an evolution path.
    /// @param pathId The unique ID for this evolution path.
    /// @param stagesInOrder An array of stage IDs in the desired order of evolution.
    function addEvolutionPath(uint256 pathId, uint256[] memory stagesInOrder)
        external
        onlyGovernor
        whenNotPaused
    {
        if (stagesInOrder.length == 0) {
            revert InvalidPathId();
        }
        for (uint256 i = 0; i < stagesInOrder.length; i++) {
            if (!evolutionStages[stagesInOrder[i]].exists) {
                revert InvalidStageId(); // All stages in path must be predefined
            }
        }
        evolutionPaths[pathId] = EvolutionPath(stagesInOrder, true);
        emit EvolutionPathAdded(pathId, stagesInOrder);
    }

    /// @notice Allows the governor to remove an existing evolution path.
    /// @dev Essences currently on this path will be stuck or require migration. Use with caution.
    /// @param pathId The ID of the evolution path to remove.
    function removeEvolutionPath(uint256 pathId) external onlyGovernor whenNotPaused {
        if (!evolutionPaths[pathId].exists) {
            revert InvalidPathId();
        }
        delete evolutionPaths[pathId];
        emit EvolutionPathRemoved(pathId);
    }

    /// @notice Sets a global base decay rate for all Essences.
    /// @param _newRate The new global decay rate in basis points (0-10000).
    function setGlobalDecayRateBasisPoints(uint256 _newRate) external onlyGovernor whenNotPaused {
        globalDecayRateBasisPoints = _newRate;
        emit GlobalDecayRateSet(_newRate);
    }

    /// @notice Sets the price (in Wei) for minting new Essences.
    /// @param _newPrice The new minting price in Wei.
    function setMintPrice(uint256 _newPrice) external onlyGovernor whenNotPaused {
        mintPrice = _newPrice;
        emit MintPriceSet(_newPrice);
    }

    /// @notice Sets the fee (in Wei) for forging new Essences via recombination.
    /// @param _newFee The new recombination fee in Wei.
    function setRecombinationFee(uint256 _newFee) external onlyGovernor whenNotPaused {
        recombinationFee = _newFee;
        emit RecombinationFeeSet(_newFee);
    }

    /// @notice Allows the governor to withdraw accumulated fees from minting and recombination.
    function withdrawFunds() external onlyGovernor nonReentrant {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) {
            revert InsufficientFunds(); // Or custom error like NoFundsToWithdraw
        }
        payable(msg.sender).transfer(contractBalance);
        emit FundsWithdrawn(msg.sender, contractBalance);
    }

    /// @notice Transfers the governance role to a new address.
    /// @param newGovernor The address of the new governor.
    function transferGovernanceOwnership(address newGovernor) external onlyGovernor {
        if (newGovernor == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernanceTransferred(oldGovernor, newGovernor);
    }

    /// @notice Pauses core functionality (minting, evolution, transfers) in case of emergency.
    function pause() external onlyGovernor whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyGovernor whenPaused {
        _unpause();
    }

    // --- View & Utility Functions ---

    /// @notice Returns all stored details about a specific ChronoEssence.
    /// @param tokenId The ID of the ChronoEssence.
    /// @return A ChronoEssence struct containing all its data.
    function getEssenceDetails(uint256 tokenId)
        public
        view
        isValidEssence(tokenId)
        returns (ChronoEssence memory)
    {
        return essenceData[tokenId];
    }

    /// @notice Returns the details of a specific evolution stage.
    /// @param stageId The ID of the evolution stage.
    /// @return An EvolutionStage struct containing its parameters.
    function getEvolutionStageDetails(uint256 stageId)
        public
        view
        returns (EvolutionStage memory)
    {
        return evolutionStages[stageId];
    }

    /// @notice Returns current global protocol parameters.
    /// @return currentMintPrice The current price to mint an essence.
    /// @return currentRecombinationFee The current fee for recombination.
    /// @return globalDecayRateBasisPoints The current global decay rate.
    /// @return totalMintedEssences The total number of essences minted so far.
    function getChronoForgeParameters()
        public
        view
        returns (uint256 currentMintPrice, uint256 currentRecombinationFee, uint256 globalDecayRateBasisPoints, uint256 totalMintedEssences)
    {
        return (mintPrice, recombinationFee, globalDecayRateBasisPoints, _tokenIdCounter.current());
    }

    // --- Internal/Private Helper Functions ---

    /// @dev Burns an Essence, marking it as dissipated.
    /// @param tokenId The ID of the essence to dissipate.
    function _dissipateEssence(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Get owner before burning
        _burn(tokenId);
        delete essenceData[tokenId]; // Clean up essence data
        delete bondedFunds[tokenId]; // Refund/clear bonded funds (consider refunding to owner here if desired)
        emit ChronoEssenceDissipated(tokenId, owner, block.timestamp);
    }

    /// @dev Calculates and updates the accumulated decay for an Essence.
    /// @param tokenId The ID of the Essence.
    /// @return The newly calculated accumulated decay in basis points.
    function _calculateAndApplyDecay(uint256 tokenId) internal returns (uint256) {
        ChronoEssence storage essence = essenceData[tokenId];
        uint256 elapsed = block.timestamp - essence.lastEvolvedAt;

        // Get stage-specific decay rate
        EvolutionStage storage currentStage = evolutionStages[essence.currentStageId];
        uint256 stageDecayRate = currentStage.exists ? currentStage.decayRateBasisPoints : 0;

        // Total effective decay rate (global + stage-specific)
        uint256 effectiveDecayRate = globalDecayRateBasisPoints + stageDecayRate;

        // Calculate new decay amount based on elapsed time and effective rate
        // Assuming effectiveDecayRate is per second for simplicity; adjust for hourly/daily as needed
        uint256 newDecay = (elapsed * effectiveDecayRate) / 10000; // Divide by 10000 to convert basis points to a fraction

        // Optional: Reduce decay based on bonded funds. This would require more complex logic:
        // - Define a "decay offset" per unit of bonded ETH per second
        // - `newDecay = max(0, newDecay - (bondedFunds[tokenId] * BOND_DECAY_OFFSET_FACTOR))`
        // For now, keeping it simpler.

        essence.accumulatedDecay += newDecay;
        if (essence.accumulatedDecay > 10000) {
            essence.accumulatedDecay = 10000; // Cap at 100% decay
        }
        return essence.accumulatedDecay;
    }

    /// @dev Calculates the potential decay without modifying the essence state.
    /// @param tokenId The ID of the Essence.
    /// @return The potential accumulated decay in basis points.
    function _calculateDecay(uint256 tokenId) internal view returns (uint256) {
        ChronoEssence storage essence = essenceData[tokenId];
        uint256 elapsed = block.timestamp - essence.lastEvolvedAt;

        EvolutionStage storage currentStage = evolutionStages[essence.currentStageId];
        uint256 stageDecayRate = currentStage.exists ? currentStage.decayRateBasisPoints : 0;

        uint256 effectiveDecayRate = globalDecayRateBasisPoints + stageDecayRate;

        uint256 newDecay = (elapsed * effectiveDecayRate) / 10000;
        uint256 totalDecay = essence.accumulatedDecay + newDecay;
        return totalDecay > 10000 ? 10000 : totalDecay;
    }
}
```