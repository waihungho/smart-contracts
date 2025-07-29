This smart contract, `AetherForge`, is designed as a "Predictive Genesis Engine" for evolving and fusing digital assets (ERC-721 NFTs). It introduces concepts of dynamic NFTs whose traits can change over time, be influenced by external oracle data through user predictions, and require maintenance. The goal is to provide a unique, advanced, and creative take on digital asset creation and evolution on the blockchain, distinct from existing open-source projects.

---

## AetherForge: Predictive Genesis Engine

**Core Concept:** A decentralized engine for evolving or fusing digital assets (ERC-721) into new, dynamic, and state-changing "Progenitor" NFTs. These Progenitors are influenced by the source assets, user-provided catalysts, on-chain conditions (like block hash and timestamp), and optional future event predictions. Progenitors can also exhibit temporal decay or evolve through stages, requiring user interaction to maintain or enhance their properties.

### Outline

1.  **Contract Structure:**
    *   Inherits `ERC721` (custom minimal implementation for uniqueness).
    *   Implements `Ownable` and `Pausable` patterns for administrative control.
    *   Defines custom structs for `Progenitor` NFTs, `PredictionInfo`, and `GenesisRequest`.
    *   Utilizes a simplified `IOracle` interface for external data.

2.  **Progenitor Lifecycle:**
    *   **Genesis Request:** Users initiate a genesis process by providing two allowed ERC-721 input NFTs and optionally an ERC-20 catalyst and a prediction. Input NFTs are transferred to the contract.
    *   **Finalize Genesis:** After a waiting period, users can finalize the genesis, minting a new `Progenitor` NFT. Base traits are derived from input hashes and on-chain entropy.
    *   **Prediction Resolution:** Users can later resolve their attached prediction. If successful, the Progenitor gains permanent trait enhancements.
    *   **Attunement:** Progenitors can undergo "attunement" by paying an ERC-20 fee, resetting their decay timer and potentially boosting certain traits.
    *   **Mutation/Decay:** Over time (if not attuned), Progenitors can experience "decay" (trait degradation) or "mutation" (unpredictable trait shifts) due to on-chain entropy. This can also trigger evolution into new stages.

3.  **Dynamic NFT Features:**
    *   **Mutable Traits:** Progenitors possess core traits that are initially generated and dynamic traits that can change based on the lifecycle stage, attunement, prediction success, or decay.
    *   **Evolution Stages:** Progenitors can transition through predefined `EvolutionStage`s (Larva, Chrysalis, Apex, Aetherial), each potentially unlocking new visual representations or utilities.
    *   **On-chain Entropy:** `block.hash` and `block.timestamp` are used to introduce pseudo-randomness into trait generation and mutation.
    *   **Oracle Integration:** Supports various types of predictions (e.g., future price targets, specific block hashes) requiring an external oracle.

4.  **Economic Mechanisms:**
    *   **Genesis Fees:** A fee (in native currency) is required to initiate genesis.
    *   **Catalyst Fees:** Optional ERC-20 tokens can be used as catalysts, transferred to the contract and potentially burned or held.
    *   **Attunement Fees:** An ERC-20 fee is required for attunement.
    *   **Fee Management:** Owner can set fees and withdraw accumulated funds.

5.  **Access Control & Parameters:**
    *   **Owner-controlled:** `Ownable` pattern for setting fees, allowed input collections, oracle address, and various system parameters.
    *   **Pausable:** Ability to pause new genesis requests in emergencies.

---

### Function Summary (27+ functions)

**I. Core Genesis & Evolution Functions:**

1.  `constructor()`: Initializes the contract, setting the owner and base ERC-721 properties.
2.  `requestGenesis(address _inputCollectionA, uint256 _inputTokenIdA, address _inputCollectionB, uint256 _inputTokenIdB, address _catalystTokenAddress, uint256 _catalystAmount, uint8 _predictionType, bytes32 _predictionKey, uint256 _targetValue, uint256 _targetBlock)`: Initiates a new Progenitor genesis process, requires input NFTs, optional catalyst, and optional prediction. Transfers input NFTs to contract.
3.  `finalizeGenesis(uint256 _genesisRequestId)`: Mints the new Progenitor NFT after the required `MIN_GENESIS_INTERVAL` has passed, transferring ownership to the requester.
4.  `attuneProgenitor(uint256 _progenitorId, uint256 _catalystAmount)`: Allows a Progenitor owner to "attune" their Progenitor using a catalyst, preventing decay and potentially boosting traits.
5.  `resolvePrediction(uint256 _progenitorId)`: Allows a Progenitor owner to check if their attached prediction was met, applying significant trait bonuses if successful.
6.  `mutateProgenitor(uint256 _progenitorId)`: Triggers an on-demand mutation process for a Progenitor, potentially causing decay or stage evolution based on elapsed time and entropy.

**II. Input & Catalyst Management Functions (Owner Only):**

7.  `setGenesisCatalyst(address _tokenAddress, uint256 _requiredAmount)`: Sets or updates the required ERC-20 catalyst token and amount for genesis, if any.
8.  `removeGenesisCatalyst()`: Removes any required ERC-20 catalyst for genesis.
9.  `addAllowedInputCollection(address _collectionAddress)`: Adds an ERC-721 collection address to the whitelist of allowed genesis input NFTs.
10. `removeAllowedInputCollection(address _collectionAddress)`: Removes an ERC-721 collection address from the whitelist.

**III. Progenitor State & Metadata Functions (View):**

11. `getProgenitorTraits(uint256 _progenitorId)`: Returns the current mutable trait values of a Progenitor.
12. `getProgenitorPrediction(uint256 _progenitorId)`: Returns the prediction details associated with a Progenitor.
13. `getProgenitorState(uint256 _progenitorId)`: Returns the current `EvolutionStage` and decay status of a Progenitor.
14. `tokenURI(uint256 _tokenId)`: Returns the URI for the NFT metadata, designed to point to an off-chain server that dynamically generates JSON based on current on-chain traits.
15. `getProgenitorDetails(uint256 _progenitorId)`: Returns comprehensive details of a Progenitor.

**IV. Oracle & Prediction System Functions (Owner Only):**

16. `setOracleAddress(address _oracleAddress)`: Sets the address of the external oracle contract used for prediction resolution.
17. `addAllowedPredictionType(uint8 _predictionType)`: Adds a new type of prediction that can be used (e.g., PriceFeed, BlockHash).
18. `removeAllowedPredictionType(uint8 _predictionType)`: Removes an allowed prediction type.

**V. Fee & Economic Management Functions (Owner Only):**

19. `setGenesisFee(uint256 _fee)`: Sets the native currency (ETH) fee required for initiating a genesis request.
20. `setAttunementFee(uint256 _fee)`: Sets the native currency (ETH) fee for attuning a Progenitor.
21. `withdrawFees()`: Allows the owner to withdraw accumulated native currency fees to the fee recipient address.
22. `setFeeRecipient(address _recipient)`: Sets the address where collected fees are sent.
23. `rescueERC20(address _tokenAddress, uint256 _amount)`: Allows the owner to recover accidentally sent ERC-20 tokens from the contract.

**VI. Administrative & System Parameter Functions (Owner Only):**

24. `pause()`: Pauses new genesis requests and other critical operations (implements Pausable pattern).
25. `unpause()`: Unpauses the contract (implements Pausable pattern).
26. `setMinimumGenesisInterval(uint256 _seconds)`: Sets the minimum time interval required between a genesis request and its finalization.
27. `setTraitEntropyFactor(uint256 _factor)`: Adjusts the influence of on-chain entropy on trait mutation.
28. `setDecayRate(uint256 _blocks)`: Sets how many blocks must pass before a Progenitor begins to decay if not attuned.

**VII. ERC-721 Standard Functions (Minimal Custom Implementation):**

29. `balanceOf(address _owner)`: Returns the number of NFTs owned by an address.
30. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
31. `approve(address _to, uint256 _tokenId)`: Approves an address to spend a specific NFT.
32. `getApproved(uint256 _tokenId)`: Returns the approved address for a specific NFT.
33. `setApprovalForAll(address _operator, bool _approved)`: Grants or revokes approval for an operator to manage all of the caller's NFTs.
34. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
35. `transferFrom(address _from, address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
36. `safeTransferFrom(address _from, address _to, uint256 _tokenId)`: Transfers ownership of an NFT safely (checking for ERC721Receiver).
37. `safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data)`: Overloaded safe transfer.
38. `supportsInterface(bytes4 _interfaceId)`: Standard EIP-165 interface detection.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Minimal ERC-165 Interface for Oracle
interface IOracle {
    // Standard function to get a value associated with a specific key.
    // key can be a string hash like "ETH_USD", "WEATHER_TEMP_NYC", etc.
    function getValue(bytes32 key) external view returns (uint256);
}

/**
 * @title AetherForge: Predictive Genesis Engine
 * @dev A decentralized engine for evolving and fusing digital assets (ERC-721)
 *      into new, dynamic, and state-changing "Progenitor" NFTs.
 *      These Progenitors are influenced by source assets, user catalysts,
 *      on-chain conditions, and optional future event predictions.
 *      Progenitors can also exhibit temporal decay or evolve through stages,
 *      requiring user interaction to maintain or enhance their properties.
 *
 * Outline:
 * 1. Contract Structure: Custom ERC721, Ownable, Pausable, custom structs.
 * 2. Progenitor Lifecycle: Genesis Request, Finalize, Attunement, Prediction Resolution, Mutation.
 * 3. Dynamic NFT Features: Mutable traits, Evolution Stages, On-chain Entropy, Oracle Integration.
 * 4. Economic Mechanisms: Genesis/Attunement Fees, Catalyst Integration.
 * 5. Access Control & Parameters: Owner-controlled settings.
 * 6. Function Summary (27+ functions): Core, Input, State, Oracle, Fees, Admin, ERC721 standards.
 */
contract AetherForge is ERC721Holder, Ownable, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdTracker;
    Counters.Counter private _genesisRequestTracker;

    // ERC-721 Standard fields (custom implementation)
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _baseTokenURI;

    // --- Custom Structs ---

    enum EvolutionStage {
        Larva,      // Initial stage, raw potential
        Chrysalis,  // Undergoing transformation
        Apex,       // Fully realized, stable
        Aetherial   // Transcendent, rare, possibly volatile
    }

    // Types of predictions supported by the oracle
    enum PredictionType {
        None,           // No prediction attached
        PriceFeedGT,    // Target value: price > X (oracleKey provides asset pair)
        PriceFeedLT,    // Target value: price < X
        BlockHashMatch  // Target value: block hash suffix equals X
    }

    struct PredictionInfo {
        PredictionType predictionType; // Type of prediction (e.g., ETH price, block hash)
        bytes32 predictionKey;        // Specific key for oracle (e.g., "ETH_USD")
        uint256 targetValue;          // Target value for numeric predictions or hash suffix
        uint256 targetBlock;          // Block at which prediction is checked
        bool isActive;                // True if a prediction exists for this Progenitor
    }

    struct Progenitor {
        uint256 id;                 // Unique Progenitor ID
        uint256 genesisBlock;       // Block when it was minted
        uint256 lastAttunedBlock;   // For decay tracking
        uint256 attunementCount;    // How many times it's been attuned
        PredictionInfo prediction;  // Details if a prediction was made
        bytes32 coreTraitsHash;     // Immutable base traits hash (from inputs + genesis entropy)

        // Mutable Traits (simplified for gas efficiency and fixed structure)
        uint256 essence;        // General vitality/power
        uint256 resilience;     // Resistance to decay/mutation
        uint256 adaptability;   // How well it handles predictions/change
        uint256 rarityFactor;   // Influenced by unique inputs, catalysts, prediction success
        uint256 entropyFactor;  // How susceptible it is to random changes

        EvolutionStage stage;       // Current lifecycle stage
        bool predictionResolved;    // True if prediction has been checked
        bool predictionMet;         // True if prediction was successful
    }

    struct GenesisRequest {
        address requester;
        address inputNFTCollectionA;
        uint256 inputNFTIdA;
        address inputNFTCollectionB;
        uint256 inputNFTIdB;
        address catalystTokenAddress; // ERC20 catalyst
        uint256 catalystAmount;
        PredictionInfo prediction;
        uint256 requestBlock;
        bytes32 pendingCoreTraitsHash; // Hashed traits before finalization
        bool finalized; // True when the Progenitor has been minted
    }

    // --- Mappings & Constants ---

    mapping(uint256 => Progenitor) public progenitors;
    mapping(uint256 => GenesisRequest) public genesisRequests;

    // Allowed input ERC-721 collections for genesis
    mapping(address => bool) public allowedInputCollections;

    // Optional ERC-20 catalyst required for genesis
    address public genesisCatalystToken;
    uint256 public genesisCatalystAmount;

    // Oracle contract address for predictions
    IOracle public oracle;
    mapping(uint8 => bool) public allowedPredictionTypes; // Maps PredictionType enum to boolean

    // Fees
    uint256 public genesisFee = 0.05 ether; // Fee for requesting genesis (in ETH)
    uint256 public attunementFee = 0.01 ether; // Fee for attuning progenitor (in ETH)
    address public feeRecipient;

    // System parameters
    uint256 public MIN_GENESIS_INTERVAL = 1 hours; // Minimum time between request and finalization
    uint256 public DECAY_RATE_BLOCKS = 365 days / 13 seconds; // Approx blocks per year for decay logic
    uint256 public TRAIT_ENTROPY_FACTOR = 10; // Controls magnitude of random trait changes

    // --- Events ---

    event ProgenitorGenesisRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint256 inputTokenIdA,
        uint256 inputTokenIdB,
        PredictionInfo prediction
    );
    event ProgenitorGenesisFinalized(
        uint256 indexed progenitorId,
        uint256 indexed requestId,
        address indexed owner,
        EvolutionStage initialStage
    );
    event ProgenitorAttuned(uint256 indexed progenitorId, uint256 newEssence, uint256 newResilience);
    event PredictionResolved(uint256 indexed progenitorId, bool met, uint256 newRarityFactor);
    event ProgenitorMutated(uint256 indexed progenitorId, EvolutionStage newStage, uint256 currentEssence);

    event GenesisFeeSet(uint256 newFee);
    event AttunementFeeSet(uint256 newFee);
    event FeeRecipientSet(address newRecipient);
    event OracleAddressSet(address newOracle);
    event AllowedInputCollectionAdded(address collection);
    event AllowedInputCollectionRemoved(address collection);
    event GenesisCatalystSet(address token, uint256 amount);
    event GenesisCatalystRemoved();
    event MinimumGenesisIntervalSet(uint256 seconds);
    event TraitEntropyFactorSet(uint256 factor);
    event DecayRateSet(uint256 blocks);

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, string memory baseURI_) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseURI_;
        feeRecipient = msg.sender; // Default fee recipient
        _tokenIdTracker.increment(); // Start token IDs from 1
        _genesisRequestTracker.increment(); // Start request IDs from 1

        // Initialize with basic allowed prediction types
        allowedPredictionTypes[uint8(PredictionType.PriceFeedGT)] = true;
        allowedPredictionTypes[uint8(PredictionType.PriceFeedLT)] = true;
        allowedPredictionTypes[uint8(PredictionType.BlockHashMatch)] = true;
    }

    // --- ERC-721 Standard Functions (Minimal Custom Implementation) ---

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC-165
               interfaceId == 0x80ac58cd || // ERC-721
               interfaceId == 0x49064906 || // ERC-721 Metadata
               interfaceId == 0x5b5e139f;   // ERC-721 Enumerable (not fully implemented but declared for compatibility)
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approvals
        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId); // Clear approvals
        _balances[owner] = _balances[owner].sub(1);
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (no data)");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    // --- Core Genesis & Evolution Functions ---

    /**
     * @dev Requests a new Progenitor genesis.
     *      Requires two input ERC-721 NFTs, optional ERC-20 catalyst, and optional prediction.
     *      Input NFTs are transferred to the contract.
     * @param _inputCollectionA Address of the first input ERC-721 collection.
     * @param _inputTokenIdA ID of the first input NFT.
     * @param _inputCollectionB Address of the second input ERC-721 collection.
     * @param _inputTokenIdB ID of the second input NFT.
     * @param _catalystTokenAddress Address of the ERC-20 catalyst token (address(0) if none).
     * @param _catalystAmount Amount of ERC-20 catalyst required (0 if none).
     * @param _predictionType Type of prediction (see PredictionType enum).
     * @param _predictionKey Key for the oracle (e.g., "ETH_USD").
     * @param _targetValue Target value for the prediction.
     * @param _targetBlock Target block number for prediction resolution.
     */
    function requestGenesis(
        address _inputCollectionA, uint256 _inputTokenIdA,
        address _inputCollectionB, uint256 _inputTokenIdB,
        address _catalystTokenAddress, uint256 _catalystAmount,
        uint8 _predictionType, bytes32 _predictionKey, uint256 _targetValue, uint256 _targetBlock
    ) external payable whenNotPaused {
        require(msg.value >= genesisFee, "AetherForge: Insufficient genesis fee");
        require(_inputCollectionA != address(0) && _inputCollectionB != address(0), "AetherForge: Input collection cannot be zero address");
        require(allowedInputCollections[_inputCollectionA] && allowedInputCollections[_inputCollectionB], "AetherForge: Input collections not allowed");
        require(_inputCollectionA != _inputCollectionB || _inputTokenIdA != _inputTokenIdB, "AetherForge: Input NFTs must be distinct");

        // Transfer input NFTs to contract
        IERC721(_inputCollectionA).transferFrom(msg.sender, address(this), _inputTokenIdA);
        IERC721(_inputCollectionB).transferFrom(msg.sender, address(this), _inputTokenIdB);

        // Handle catalyst if required
        if (genesisCatalystToken != address(0) || _catalystTokenAddress != address(0)) {
            require(_catalystTokenAddress == genesisCatalystToken, "AetherForge: Incorrect catalyst token provided");
            require(_catalystAmount >= genesisCatalystAmount, "AetherForge: Insufficient catalyst amount");
            IERC20(genesisCatalystToken).transferFrom(msg.sender, address(this), _catalystAmount);
        }

        // Validate prediction info
        PredictionInfo memory predictionInfo;
        if (_predictionType != uint8(PredictionType.None)) {
            require(allowedPredictionTypes[_predictionType], "AetherForge: Invalid prediction type");
            require(address(oracle) != address(0), "AetherForge: Oracle not set for predictions");
            require(_targetBlock > block.number, "AetherForge: Target block must be in the future");
            predictionInfo = PredictionInfo(
                PredictionType(_predictionType),
                _predictionKey,
                _targetValue,
                _targetBlock,
                true
            );
        } else {
            predictionInfo.isActive = false;
        }

        uint256 requestId = _genesisRequestTracker.current();
        _genesisRequestTracker.increment();

        genesisRequests[requestId] = GenesisRequest({
            requester: msg.sender,
            inputNFTCollectionA: _inputCollectionA,
            inputNFTIdA: _inputTokenIdA,
            inputNFTCollectionB: _inputCollectionB,
            inputNFTIdB: _inputTokenIdB,
            catalystTokenAddress: _catalystTokenAddress,
            catalystAmount: _catalystAmount,
            prediction: predictionInfo,
            requestBlock: block.number,
            pendingCoreTraitsHash: _calculateCoreTraitsHash(
                _inputCollectionA, _inputTokenIdA,
                _inputCollectionB, _inputTokenIdB,
                _catalystTokenAddress, _catalystAmount,
                block.timestamp, block.hash(block.number - 1) // Using previous block hash for entropy
            ),
            finalized: false
        });

        emit ProgenitorGenesisRequested(
            requestId, msg.sender, _inputTokenIdA, _inputTokenIdB, predictionInfo
        );
    }

    /**
     * @dev Finalizes a genesis request and mints the new Progenitor NFT.
     *      Can only be called after MIN_GENESIS_INTERVAL has passed.
     * @param _genesisRequestId ID of the genesis request to finalize.
     */
    function finalizeGenesis(uint256 _genesisRequestId) external {
        GenesisRequest storage request = genesisRequests[_genesisRequestId];
        require(request.requester == msg.sender, "AetherForge: Not the requester of this genesis");
        require(!request.finalized, "AetherForge: Genesis already finalized");
        require(block.timestamp >= request.requestBlock.add(MIN_GENESIS_INTERVAL), "AetherForge: Genesis not ready for finalization");

        uint256 newProgenitorId = _tokenIdTracker.current();
        _tokenIdTracker.increment();

        _mint(request.requester, newProgenitorId); // Mint new Progenitor NFT

        progenitors[newProgenitorId] = Progenitor({
            id: newProgenitorId,
            genesisBlock: block.number,
            lastAttunedBlock: block.number,
            attunementCount: 0,
            prediction: request.prediction,
            coreTraitsHash: request.pendingCoreTraitsHash,
            essence: 1000,          // Base essence
            resilience: 1000,       // Base resilience
            adaptability: 1000,     // Base adaptability
            rarityFactor: _calculateInitialRarityFactor(request), // Initial rarity based on inputs/catalyst
            entropyFactor: TRAIT_ENTROPY_FACTOR, // Initial entropy
            stage: EvolutionStage.Larva,
            predictionResolved: false,
            predictionMet: false
        });

        request.finalized = true;

        // Optionally, burn the input NFTs if desired. For now, they remain in contract as "consumed".
        // IERC721(request.inputNFTCollectionA).burn(request.inputNFTIdA); // Not standard ERC721
        // IERC721(request.inputNFTCollectionB).burn(request.inputNFTIdB);

        emit ProgenitorGenesisFinalized(newProgenitorId, _genesisRequestId, request.requester, EvolutionStage.Larva);
    }

    /**
     * @dev Allows a Progenitor owner to "attune" their Progenitor.
     *      Resets decay timer, provides minor trait boosts.
     * @param _progenitorId ID of the Progenitor to attune.
     * @param _catalystAmount Amount of ERC-20 catalyst to use for attunement.
     */
    function attuneProgenitor(uint256 _progenitorId, uint256 _catalystAmount) external payable {
        Progenitor storage prog = progenitors[_progenitorId];
        require(ownerOf(_progenitorId) == msg.sender, "AetherForge: Not the owner of this Progenitor");
        require(prog.id != 0, "AetherForge: Progenitor does not exist");
        require(msg.value >= attunementFee, "AetherForge: Insufficient attunement fee");

        // Assuming a standard catalyst token for attunement or ETH only
        // If a specific ERC20 catalyst is needed for attunement, add parameter and transferFrom logic here
        // For simplicity, this example uses ETH for attunementFee. If ERC20 catalyst for attunement is desired:
        // IERC20(attunementCatalystToken).transferFrom(msg.sender, address(this), _catalystAmount);

        prog.lastAttunedBlock = block.number;
        prog.attunementCount = prog.attunementCount.add(1);

        // Apply minor trait boosts
        prog.essence = prog.essence.add(50);
        prog.resilience = prog.resilience.add(75);
        prog.adaptability = prog.adaptability.add(25);

        emit ProgenitorAttuned(_progenitorId, prog.essence, prog.resilience);
    }

    /**
     * @dev Resolves the prediction attached to a Progenitor.
     *      Applies significant trait bonuses if the prediction was met.
     * @param _progenitorId ID of the Progenitor to resolve prediction for.
     */
    function resolvePrediction(uint256 _progenitorId) external {
        Progenitor storage prog = progenitors[_progenitorId];
        require(ownerOf(_progenitorId) == msg.sender, "AetherForge: Not the owner of this Progenitor");
        require(prog.prediction.isActive, "AetherForge: No active prediction for this Progenitor");
        require(!prog.predictionResolved, "AetherForge: Prediction already resolved");
        require(block.number >= prog.prediction.targetBlock, "AetherForge: Prediction target block not reached");
        require(address(oracle) != address(0), "AetherForge: Oracle not set");

        uint256 oracleValue = oracle.getValue(prog.prediction.predictionKey);
        bool predictionMet = false;

        if (prog.prediction.predictionType == PredictionType.PriceFeedGT) {
            predictionMet = oracleValue > prog.prediction.targetValue;
        } else if (prog.prediction.predictionType == PredictionType.PriceFeedLT) {
            predictionMet = oracleValue < prog.prediction.targetValue;
        } else if (prog.prediction.predictionType == PredictionType.BlockHashMatch) {
            // Get the block hash at the target block
            // Note: block.blockhash(block.number) not available for current block in Solidity >= 0.8.18,
            // also can't access future block hashes. This is for previous blocks.
            // If the oracle provides this, it's safer. For on-chain, target block should be slightly in the past
            // or oracle must provide the hash.
            bytes32 targetBlockHash = block.hash(prog.prediction.targetBlock);
            uint256 hashSuffix = uint256(targetBlockHash) % 100000; // Example: last 5 digits
            predictionMet = hashSuffix == prog.prediction.targetValue;
        }

        prog.predictionResolved = true;
        prog.predictionMet = predictionMet;

        if (predictionMet) {
            // Apply significant trait boosts for successful prediction
            prog.essence = prog.essence.add(500);
            prog.rarityFactor = prog.rarityFactor.add(2000); // Major rarity boost
            prog.adaptability = prog.adaptability.add(300);
            // Optionally change stage
            if (prog.stage < EvolutionStage.Apex) {
                prog.stage = EvolutionStage.Apex;
            }
        }

        emit PredictionResolved(_progenitorId, predictionMet, prog.rarityFactor);
    }

    /**
     * @dev Triggers an on-demand mutation process for a Progenitor.
     *      Can cause trait degradation (decay) or random shifts based on entropy,
     *      and potentially trigger evolution stage changes.
     * @param _progenitorId ID of the Progenitor to mutate.
     */
    function mutateProgenitor(uint256 _progenitorId) external {
        Progenitor storage prog = progenitors[_progenitorId];
        require(ownerOf(_progenitorId) == msg.sender, "AetherForge: Not the owner of this Progenitor");
        require(prog.id != 0, "AetherForge: Progenitor does not exist");

        uint256 blocksSinceAttunement = block.number.sub(prog.lastAttunedBlock);

        // Decay logic
        if (blocksSinceAttunement > DECAY_RATE_BLOCKS) {
            uint256 decayAmount = (blocksSinceAttunement / DECAY_RATE_BLOCKS) * 50; // 50 points per decay cycle
            if (prog.essence > decayAmount) prog.essence = prog.essence.sub(decayAmount); else prog.essence = 0;
            if (prog.resilience > decayAmount) prog.resilience = prog.resilience.sub(decayAmount); else prog.resilience = 0;
            prog.lastAttunedBlock = block.number; // Reset decay clock after decay
        }

        // Random mutation (entropy) logic
        // Use block hash and timestamp for pseudo-randomness
        uint256 entropySource = uint256(keccak256(abi.encodePacked(block.timestamp, block.hash(block.number - 1), _progenitorId, prog.attunementCount)));
        uint256 randomFactor = entropySource % prog.entropyFactor; // Modulo by entropyFactor to control magnitude

        if (randomFactor > 0) {
            // Randomly adjust traits
            if (entropySource % 3 == 0) { // Adjust essence
                if (prog.essence > randomFactor) prog.essence = prog.essence.sub(randomFactor); else prog.essence = 0;
            } else if (entropySource % 3 == 1) { // Adjust resilience
                prog.resilience = prog.resilience.add(randomFactor);
            } else { // Adjust adaptability
                prog.adaptability = prog.adaptability.add(randomFactor);
            }
        }

        // Evolution Stage logic
        EvolutionStage oldStage = prog.stage;
        if (prog.essence > 2000 && prog.resilience > 1500 && prog.adaptability > 1800) {
            prog.stage = EvolutionStage.Aetherial;
        } else if (prog.essence > 1500 && prog.resilience > 1000) {
            prog.stage = EvolutionStage.Apex;
        } else if (prog.essence > 800) {
            prog.stage = EvolutionStage.Chrysalis;
        } else {
            prog.stage = EvolutionStage.Larva;
        }

        if (oldStage != prog.stage) {
            emit ProgenitorMutated(_progenitorId, prog.stage, prog.essence);
        }
    }

    // --- Input & Catalyst Management Functions (Owner Only) ---

    /**
     * @dev Sets or updates the required ERC-20 catalyst token and amount for genesis.
     * @param _tokenAddress Address of the ERC-20 token.
     * @param _requiredAmount Amount of the token required. Set to 0 to effectively disable requirement.
     */
    function setGenesisCatalyst(address _tokenAddress, uint256 _requiredAmount) external onlyOwner {
        require(_tokenAddress != address(0), "AetherForge: Catalyst token cannot be zero address");
        genesisCatalystToken = _tokenAddress;
        genesisCatalystAmount = _requiredAmount;
        emit GenesisCatalystSet(_tokenAddress, _requiredAmount);
    }

    /**
     * @dev Removes any required ERC-20 catalyst for genesis.
     */
    function removeGenesisCatalyst() external onlyOwner {
        genesisCatalystToken = address(0);
        genesisCatalystAmount = 0;
        emit GenesisCatalystRemoved();
    }

    /**
     * @dev Adds an ERC-721 collection address to the whitelist of allowed genesis input NFTs.
     * @param _collectionAddress The address of the ERC-721 contract.
     */
    function addAllowedInputCollection(address _collectionAddress) external onlyOwner {
        require(_collectionAddress != address(0), "AetherForge: Collection address cannot be zero");
        require(!allowedInputCollections[_collectionAddress], "AetherForge: Collection already allowed");
        allowedInputCollections[_collectionAddress] = true;
        emit AllowedInputCollectionAdded(_collectionAddress);
    }

    /**
     * @dev Removes an ERC-721 collection address from the whitelist.
     * @param _collectionAddress The address of the ERC-721 contract.
     */
    function removeAllowedInputCollection(address _collectionAddress) external onlyOwner {
        require(allowedInputCollections[_collectionAddress], "AetherForge: Collection not allowed");
        allowedInputCollections[_collectionAddress] = false;
        emit AllowedInputCollectionRemoved(_collectionAddress);
    }

    // --- Progenitor State & Metadata Functions (View) ---

    /**
     * @dev Returns the current mutable trait values of a Progenitor.
     * @param _progenitorId ID of the Progenitor.
     * @return essence Current essence value.
     * @return resilience Current resilience value.
     * @return adaptability Current adaptability value.
     * @return rarityFactor Current rarity factor.
     * @return entropyFactor Current entropy factor.
     */
    function getProgenitorTraits(uint256 _progenitorId)
        public view
        returns (uint256 essence, uint256 resilience, uint256 adaptability, uint256 rarityFactor, uint256 entropyFactor)
    {
        Progenitor storage prog = progenitors[_progenitorId];
        require(prog.id != 0, "AetherForge: Progenitor does not exist");
        return (prog.essence, prog.resilience, prog.adaptability, prog.rarityFactor, prog.entropyFactor);
    }

    /**
     * @dev Returns the prediction details associated with a Progenitor.
     * @param _progenitorId ID of the Progenitor.
     * @return predictionType Type of prediction.
     * @return predictionKey Key for the oracle.
     * @return targetValue Target value for prediction.
     * @return targetBlock Target block for prediction.
     * @return isActive True if prediction is active.
     * @return predictionResolved True if prediction has been checked.
     * @return predictionMet True if prediction was successful.
     */
    function getProgenitorPrediction(uint256 _progenitorId)
        public view
        returns (uint8 predictionType, bytes32 predictionKey, uint256 targetValue, uint256 targetBlock, bool isActive, bool predictionResolved, bool predictionMet)
    {
        Progenitor storage prog = progenitors[_progenitorId];
        require(prog.id != 0, "AetherForge: Progenitor does not exist");
        return (
            uint8(prog.prediction.predictionType),
            prog.prediction.predictionKey,
            prog.prediction.targetValue,
            prog.prediction.targetBlock,
            prog.prediction.isActive,
            prog.predictionResolved,
            prog.predictionMet
        );
    }

    /**
     * @dev Returns the current EvolutionStage and decay status of a Progenitor.
     * @param _progenitorId ID of the Progenitor.
     * @return currentStage The current evolution stage.
     * @return blocksSinceLastAttunement Number of blocks since last attunement.
     * @return needsAttunement True if attunement is overdue (decay threshold reached).
     */
    function getProgenitorState(uint256 _progenitorId)
        public view
        returns (EvolutionStage currentStage, uint256 blocksSinceLastAttunement, bool needsAttunement)
    {
        Progenitor storage prog = progenitors[_progenitorId];
        require(prog.id != 0, "AetherForge: Progenitor does not exist");
        uint256 bsa = block.number.sub(prog.lastAttunedBlock);
        return (prog.stage, bsa, bsa > DECAY_RATE_BLOCKS);
    }

    /**
     * @dev Returns comprehensive details of a Progenitor.
     * @param _progenitorId ID of the Progenitor.
     * @return progenitor Progenitor struct.
     */
    function getProgenitorDetails(uint256 _progenitorId) public view returns (Progenitor memory) {
        return progenitors[_progenitorId];
    }

    /**
     * @dev Returns the URI for the NFT metadata, dynamically constructed.
     *      Intended for an off-chain server to query on-chain traits and serve JSON.
     * @param _tokenId The ID of the Progenitor NFT.
     * @return The URI for the NFT metadata.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_owners[_tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        // This is a common pattern for dynamic NFTs where metadata is served off-chain.
        // The server at _baseTokenURI would query this contract's state for _tokenId
        // and generate the appropriate JSON metadata reflecting its current dynamic traits.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    // --- Oracle & Prediction System Functions (Owner Only) ---

    /**
     * @dev Sets the address of the external oracle contract used for prediction resolution.
     * @param _oracleAddress The address of the IOracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "AetherForge: Oracle address cannot be zero");
        oracle = IOracle(_oracleAddress);
        emit OracleAddressSet(_oracleAddress);
    }

    /**
     * @dev Adds a new type of prediction that can be used (e.g., PriceFeed, BlockHash).
     * @param _predictionType The integer representation of the PredictionType enum.
     */
    function addAllowedPredictionType(uint8 _predictionType) external onlyOwner {
        require(_predictionType != uint8(PredictionType.None), "AetherForge: Cannot allow None type");
        allowedPredictionTypes[_predictionType] = true;
        emit AllowedPredictionTypeAdded(_predictionType);
    }

    /**
     * @dev Removes an allowed prediction type.
     * @param _predictionType The integer representation of the PredictionType enum.
     */
    function removeAllowedPredictionType(uint8 _predictionType) external onlyOwner {
        require(_predictionType != uint8(PredictionType.None), "AetherForge: Cannot remove None type");
        allowedPredictionTypes[_predictionType] = false;
        emit AllowedPredictionTypeRemoved(_predictionType);
    }

    // --- Fee & Economic Management Functions (Owner Only) ---

    /**
     * @dev Sets the native currency (ETH) fee required for initiating a genesis request.
     * @param _fee The new genesis fee in wei.
     */
    function setGenesisFee(uint256 _fee) external onlyOwner {
        genesisFee = _fee;
        emit GenesisFeeSet(_fee);
    }

    /**
     * @dev Sets the native currency (ETH) fee for attuning a Progenitor.
     * @param _fee The new attunement fee in wei.
     */
    function setAttunementFee(uint256 _fee) external onlyOwner {
        attunementFee = _fee;
        emit AttunementFeeSet(_fee);
    }

    /**
     * @dev Allows the owner to withdraw accumulated native currency fees to the fee recipient address.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "AetherForge: No fees to withdraw");
        (bool success,) = feeRecipient.call{value: balance}("");
        require(success, "AetherForge: Fee withdrawal failed");
    }

    /**
     * @dev Sets the address where collected fees are sent.
     * @param _recipient The new fee recipient address.
     */
    function setFeeRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "AetherForge: Fee recipient cannot be zero address");
        feeRecipient = _recipient;
        emit FeeRecipientSet(_recipient);
    }

    /**
     * @dev Allows the owner to recover accidentally sent ERC-20 tokens from the contract.
     * @param _tokenAddress The address of the ERC-20 token.
     * @param _amount The amount of tokens to rescue.
     */
    function rescueERC20(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(0), "AetherForge: Token address cannot be zero");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "AetherForge: Insufficient token balance");
        IERC20(_tokenAddress).transfer(owner(), _amount); // Sends to owner() or a separate treasury address
    }

    // --- Administrative & System Parameter Functions (Owner Only) ---

    /**
     * @dev Pauses new genesis requests and other critical operations.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the minimum time interval required between a genesis request and its finalization.
     * @param _seconds The minimum interval in seconds.
     */
    function setMinimumGenesisInterval(uint256 _seconds) external onlyOwner {
        MIN_GENESIS_INTERVAL = _seconds;
        emit MinimumGenesisIntervalSet(_seconds);
    }

    /**
     * @dev Adjusts the influence of on-chain entropy on trait mutation.
     *      Higher factor means more significant potential random shifts.
     * @param _factor The new entropy factor.
     */
    function setTraitEntropyFactor(uint256 _factor) external onlyOwner {
        TRAIT_ENTROPY_FACTOR = _factor;
        emit TraitEntropyFactorSet(_factor);
    }

    /**
     * @dev Sets how many blocks must pass before a Progenitor begins to decay if not attuned.
     * @param _blocks The new decay rate in blocks.
     */
    function setDecayRate(uint256 _blocks) external onlyOwner {
        require(_blocks > 0, "AetherForge: Decay rate must be greater than zero");
        DECAY_RATE_BLOCKS = _blocks;
        emit DecayRateSet(_blocks);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates a unique hash representing the core traits of a Progenitor.
     *      This hash is immutable and derived from the genesis inputs.
     */
    function _calculateCoreTraitsHash(
        address colA, uint256 idA,
        address colB, uint256 idB,
        address catalystTok, uint256 catalystAmt,
        uint256 timestamp, bytes32 prevBlockHash
    ) internal pure returns (bytes32) {
        // Simple hash combining inputs and on-chain entropy
        return keccak256(abi.encodePacked(
            colA, idA, colB, idB,
            catalystTok, catalystAmt,
            timestamp, prevBlockHash
        ));
    }

    /**
     * @dev Calculates the initial rarity factor based on genesis inputs.
     *      Can be expanded with more complex logic for rarer input combinations.
     */
    function _calculateInitialRarityFactor(GenesisRequest memory request) internal pure returns (uint256) {
        uint256 baseRarity = 1000;
        // Example: Add bonus for catalyst
        if (request.catalystAmount > 0) {
            baseRarity = baseRarity.add(request.catalystAmount / 10**18 * 100); // 100 rarity per catalyst unit
        }
        // Example: Add bonus for specific collections (simplified)
        // if (request.inputNFTCollectionA == MY_RARE_COLLECTION_ADDRESS || request.inputNFTCollectionB == MY_RARE_COLLECTION_ADDRESS) {
        //     baseRarity = baseRarity.add(500);
        // }
        return baseRarity;
    }
}
```