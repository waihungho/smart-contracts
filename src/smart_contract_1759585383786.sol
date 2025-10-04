The "Quantum Loom" is a sophisticated Solidity smart contract designed to manage a unique ecosystem of dynamic, generative, and interconnected digital assets called "Weaves" (ERC721 NFTs). Unlike static NFTs, Weaves possess on-chain "quantum states" and properties like `vibrancy`, `resonance`, and `entropy` that evolve over time, react to external oracle data, and can be influenced by owner interactions and a utility token called "Catalyst" (ERC20). Weaves can also be "threaded" together, forming complex on-chain relationships.

The contract integrates Chainlink Oracles to allow Weaves to "attune" to real-world data streams, making their properties react to external events in a trustless manner. This creates a living, evolving digital collection where each asset tells a unique story shaped by its genesis, owner interaction, and the broader digital environment.

---

### **Contract Outline and Function Summary**

**I. Core Weave (NFT) Management & Generative Logic**
1.  **`mintWeave(string memory _name, string memory _description)`**: Mints a new Weave NFT, generating its unique `seed` and initial dynamic properties based on on-chain data. Requires an ETH payment.
2.  **`getWeaveProperties(uint256 _tokenId)`**: Retrieves all current dynamic properties of a Weave (vibrancy, resonance, entropy, quantum state, attunement info, threads), calculating time-based decay/growth before returning.
3.  **`updateWeaveBaseURI(uint256 _tokenId, string memory _newURI)`**: Allows the Weave owner to update its metadata URI.
4.  **`getWeaveURI(uint256 _tokenId)`**: Returns the full token URI, potentially integrating on-chain properties via a data URI.
5.  **`getTokenName(uint256 _tokenId)`**: Returns the human-readable name of a specific Weave.
6.  **`getTokenDescription(uint256 _tokenId)`**: Returns the human-readable description of a specific Weave.

**II. Entropic & Evolutionary Mechanics**
7.  **`triggerEntropicDecay(uint256 _tokenId)`**: Allows anyone to trigger the update of a Weave's `vibrancy` and `entropy` if sufficient time has passed since its last update, making updates gas-efficient for owners.
8.  **`fortifyWeave(uint256 _tokenId, uint256 _amountCatalyst)`**: Spends `Catalyst` tokens to boost a Weave's `vibrancy` and reduce its `entropy`, with effectiveness influenced by its `quantumState`.
9.  **`shiftQuantumState(uint256 _tokenId, uint8 _targetState)`**: Enables the owner to attempt to transition a Weave to a `_targetState`. Requires `Catalyst` and specific on-chain conditions (e.g., property thresholds, attunement success).

**III. Interconnectivity & Threading**
10. **`threadWeaves(uint256 _weaverId, uint256 _targetId)`**: Creates a directional link (thread) from one Weave (`_weaverId`) to another (`_targetId`). Both must be owned by `msg.sender`.
11. **`unthreadWeaves(uint256 _weaverId, uint256 _targetId)`**: Removes an existing thread between two Weaves.
12. **`getDirectThreads(uint256 _tokenId)`**: Returns an array of Weave IDs that `_tokenId` is directly threaded to.
13. **`getThreadDepth(uint256 _startId, uint256 _targetId, uint256 _maxDepth)`**: Checks if a path exists between two Weaves within a specified `_maxDepth` by traversing the threading graph.

**IV. Catalyst Token (ERC20) Integration**
14. **`mintCatalyst(uint256 _amount)`**: Allows users to mint `Catalyst` tokens by paying ETH.
15. **`burnCatalyst(uint256 _amount)`**: Allows users to burn their `Catalyst` tokens, reducing supply.

**V. Oracle Integration (Chainlink)**
16. **`attuneWeaveToOracle(uint256 _tokenId, bytes32 _oracleJobId, bytes32 _dataKey, uint256 _callbackGasLimit)`**: Owner sets a Weave to "attune" to a specific external data stream via Chainlink, requiring `Catalyst` and a LINK deposit.
17. **`requestOracleAttunementData(uint256 _tokenId)`**: Anyone can trigger an on-demand Chainlink oracle data request for an attuned Weave by paying the LINK fee.
18. **`fulfillOracleAttunement(bytes32 _requestId, uint256 _dataValue)`**: The Chainlink callback function that processes received oracle data, updating the Weave's `resonance` and potentially `quantumState` based on its value.
19. **`getAttunementParameters(uint256 _tokenId)`**: Retrieves the current oracle job ID, data key, and last received value for an attuned Weave.

**VI. Ecosystem & Admin**
20. **`setGlobalDecayRate(uint256 _newRate)`**: Admin function to adjust the universal decay rate for Weave `vibrancy`.
21. **`setMintPrice(uint256 _newPrice)`**: Admin function to set the price in ETH for minting new Weaves.
22. **`setCatalystMintPrice(uint256 _newPrice)`**: Admin function to set the ETH price for minting `Catalyst` tokens.
23. **`emergencyWithdrawLink()`**: Admin function to withdraw excess LINK tokens from the contract in an emergency.
24. **`withdrawEther()`**: Admin function to withdraw accumulated ETH from the contract.
25. **`setChainlinkOperator(address _operator)`**: Admin function to set or update the Chainlink operator address for oracle requests.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/OracleInterface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title QuantumLoom
 * @dev A generative, evolving, and interconnected digital ecosystem of Weaves (ERC721 NFTs).
 *      Weaves possess dynamic on-chain properties (vibrancy, resonance, entropy, quantum state)
 *      that evolve over time, react to Chainlink oracle data, and are influenced by owner
 *      interactions and a utility token called Catalyst (ERC20). Weaves can also be "threaded"
 *      together, forming complex on-chain relationships.
 */
contract QuantumLoom is ERC721, ERC721Burnable, Ownable, Pausable, ChainlinkClient {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Enums and Structs ---

    // Represents the quantum state of a Weave, influencing its properties and behavior.
    enum QuantumState { Stable, Volatile, Resonant, Dormant, Attuned }

    // Defines the core data structure for a Weave NFT.
    struct Weave {
        uint256 seed;                  // Core deterministic seed derived at minting
        uint256 creationBlock;         // Block number of creation
        uint256 lastUpdateBlock;       // Block number of last entropic/attunement update
        address owner;                 // Current owner of the Weave
        string name;                   // Display name of the Weave
        string description;            // Display description of the Weave
        string baseURI;                // Base URI for off-chain metadata (can be updated)

        // Dynamic Properties (0-1000 scale)
        uint256 vibrancy;              // Decays over time, boosted by Catalyst
        uint256 resonance;             // Grows with successful oracle attunement
        uint256 entropy;               // Grows over time, reduced by Catalyst
        QuantumState quantumState;     // Current quantum state of the Weave

        // Attunement to Oracle (Chainlink)
        address attunementOracle;      // Chainlink Oracle address
        bytes32 attunementJobId;       // Chainlink Job ID for the data request
        bytes32 attunementDataKey;     // Key for specific data point (e.g., "temperature")
        uint256 lastAttunementValue;   // Last value received from oracle
        uint256 lastAttunementRequestBlock; // Block when last oracle request was made
        uint256 attunementFeeLink;     // LINK fee for this attunement job
        uint256 callbackGasLimit;      // Gas limit for the Chainlink fulfillment callback

        // Interconnectivity (Threading)
        uint256[] threadedTo;          // Array of Weave IDs this Weave is directly threaded to
    }

    // --- State Variables ---

    mapping(uint256 => Weave) private _weaves;
    mapping(bytes32 => uint256) private _requestIdToTokenId; // Maps Chainlink request IDs to Weave IDs

    uint256 public mintPrice = 0.05 ether;               // Price to mint a new Weave
    uint256 public globalDecayRate = 1;                  // Rate at which vibrancy decays per block (e.g., 1 unit per 10 blocks)
    uint256 public decayPeriodBlocks = 10;               // How many blocks for `globalDecayRate` to apply

    // Catalyst Token (ERC20)
    CatalystToken public catalyst;
    uint256 public catalystMintPrice = 0.001 ether;      // Price to mint 1 Catalyst token

    // --- Events ---

    event WeaveMinted(uint256 indexed tokenId, address indexed minter, uint256 seed);
    event PropertiesUpdated(uint256 indexed tokenId, uint256 vibrancy, uint256 resonance, uint256 entropy, QuantumState quantumState);
    event QuantumStateShifted(uint256 indexed tokenId, QuantumState oldState, QuantumState newState);
    event WeaveThreaded(uint256 indexed weaverId, uint256 indexed targetId);
    event WeaveUnthreaded(uint256 indexed weaverId, uint256 indexed targetId);
    event WeaveAttuned(uint256 indexed tokenId, address indexed oracle, bytes32 indexed jobId, bytes32 dataKey);
    event OracleAttunementRequested(uint256 indexed tokenId, bytes32 indexed requestId);
    event OracleAttunementFulfilled(bytes32 indexed requestId, uint256 indexed tokenId, uint256 dataValue);
    event CatalystMinted(address indexed minter, uint256 amount);
    event CatalystBurned(address indexed burner, uint256 amount);
    event LinkWithdrawn(address indexed to, uint256 amount);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event ChainlinkOperatorSet(address indexed newOperator);

    // --- Constructor ---

    constructor(address _link) ERC721("QuantumLoom Weave", "QLW") Ownable(msg.sender) {
        set
        setLinkToken(_link);
        catalyst = new CatalystToken(address(this));
    }

    // --- Modifiers ---

    modifier onlyWeaveOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not the owner or approved");
        _;
    }

    // --- INTERNAL HELPER FUNCTIONS ---

    /**
     * @dev Dynamically calculates current vibrancy and entropy based on elapsed blocks.
     *      Vibrancy decays, Entropy increases.
     * @param _weave Weave struct to update.
     * @return (uint256, uint256) Current vibrancy and entropy.
     */
    function _calculateDynamicProperties(Weave memory _weave) internal view returns (uint256, uint256) {
        if (block.number <= _weave.lastUpdateBlock) {
            return (_weave.vibrancy, _weave.entropy);
        }

        uint256 blocksSinceLastUpdate = block.number - _weave.lastUpdateBlock;
        uint256 decayAmount = (blocksSinceLastUpdate / decayPeriodBlocks) * globalDecayRate;

        uint256 currentVibrancy = _weave.vibrancy;
        uint256 currentEntropy = _weave.entropy;

        if (currentVibrancy > decayAmount) {
            currentVibrancy -= decayAmount;
        } else {
            currentVibrancy = 0;
        }

        uint256 entropyIncrease = decayAmount; // Entropy increases similarly to vibrancy decay
        currentEntropy = currentEntropy + entropyIncrease > 1000 ? 1000 : currentEntropy + entropyIncrease;

        return (currentVibrancy, currentEntropy);
    }

    /**
     * @dev Updates Weave properties in storage after dynamic calculation.
     * @param _tokenId The ID of the Weave.
     * @param _newVibrancy New vibrancy value.
     * @param _newEntropy New entropy value.
     * @param _newState New quantum state.
     */
    function _updateWeaveInStorage(uint256 _tokenId, uint256 _newVibrancy, uint256 _newEntropy, QuantumState _newState) internal {
        Weave storage weave = _weaves[_tokenId];
        weave.vibrancy = _newVibrancy;
        weave.entropy = _newEntropy;
        weave.quantumState = _newState;
        weave.lastUpdateBlock = block.number;
        emit PropertiesUpdated(_tokenId, _newVibrancy, weave.resonance, _newEntropy, _newState);
    }

    // --- I. Core Weave (NFT) Management & Generative Logic ---

    /**
     * @dev Mints a new Weave NFT. Generates its seed and initial properties.
     *      Requires ETH payment for minting.
     * @param _name The name of the new Weave.
     * @param _description The description of the new Weave.
     * @return The ID of the newly minted Weave.
     */
    function mintWeave(string memory _name, string memory _description) public payable whenNotPaused returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient ETH for minting");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Deterministic seed generation based on block, sender, and nonce
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId)));

        _weaves[newTokenId] = Weave({
            seed: seed,
            creationBlock: block.number,
            lastUpdateBlock: block.number,
            owner: msg.sender,
            name: _name,
            description: _description,
            baseURI: "", // Can be updated later
            vibrancy: (seed % 500) + 500, // Initial vibrancy 500-1000
            resonance: (seed % 100) + 100, // Initial resonance 100-200
            entropy: (seed % 100) + 100, // Initial entropy 100-200
            quantumState: QuantumState.Stable,
            attunementOracle: address(0),
            attunementJobId: bytes32(0),
            attunementDataKey: bytes32(0),
            lastAttunementValue: 0,
            lastAttunementRequestBlock: 0,
            attunementFeeLink: 0,
            callbackGasLimit: 0,
            threadedTo: new uint256[](0)
        });

        _safeMint(msg.sender, newTokenId);
        emit WeaveMinted(newTokenId, msg.sender, seed);
        return newTokenId;
    }

    /**
     * @dev Retrieves all current dynamic properties of a Weave.
     *      Performs dynamic calculations for vibrancy and entropy based on elapsed time.
     * @param _tokenId The ID of the Weave.
     * @return A tuple containing all Weave properties.
     */
    function getWeaveProperties(uint256 _tokenId) public view returns (
        uint256 seed,
        uint256 creationBlock,
        uint256 lastUpdateBlock,
        address owner,
        string memory name,
        string memory description,
        string memory baseURI,
        uint256 vibrancy,
        uint256 resonance,
        uint256 entropy,
        QuantumState quantumState,
        address attunementOracle,
        bytes32 attunementJobId,
        bytes32 attunementDataKey,
        uint256 lastAttunementValue,
        uint256 lastAttunementRequestBlock,
        uint256 attunementFeeLink,
        uint256 callbackGasLimit,
        uint256[] memory threadedTo
    ) {
        require(_exists(_tokenId), "Weave does not exist");
        Weave memory currentWeave = _weaves[_tokenId];
        (vibrancy, entropy) = _calculateDynamicProperties(currentWeave);

        return (
            currentWeave.seed,
            currentWeave.creationBlock,
            currentWeave.lastUpdateBlock,
            currentWeave.owner,
            currentWeave.name,
            currentWeave.description,
            currentWeave.baseURI,
            vibrancy,
            currentWeave.resonance,
            entropy,
            currentWeave.quantumState,
            currentWeave.attunementOracle,
            currentWeave.attunementJobId,
            currentWeave.attunementDataKey,
            currentWeave.lastAttunementValue,
            currentWeave.lastAttunementRequestBlock,
            currentWeave.attunementFeeLink,
            currentWeave.callbackGasLimit,
            currentWeave.threadedTo
        );
    }

    /**
     * @dev Allows the Weave owner to update its base metadata URI.
     * @param _tokenId The ID of the Weave.
     * @param _newURI The new base URI.
     */
    function updateWeaveBaseURI(uint256 _tokenId, string memory _newURI) public onlyWeaveOwner(_tokenId) {
        _weaves[_tokenId].baseURI = _newURI;
    }

    /**
     * @dev Returns the full token URI, potentially integrating on-chain properties via a data URI.
     *      For simplicity, this example returns just the baseURI. A more complex implementation
     *      could generate a data URI with on-chain properties.
     * @param _tokenId The ID of the Weave.
     * @return The token URI.
     */
    function getWeaveURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Weave does not exist");
        return _weaves[_tokenId].baseURI; // A more advanced implementation would generate a data URI here
    }

    /**
     * @dev Returns the human-readable name of a specific Weave.
     * @param _tokenId The ID of the Weave.
     * @return The name of the Weave.
     */
    function getTokenName(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Weave does not exist");
        return _weaves[_tokenId].name;
    }

    /**
     * @dev Returns the human-readable description of a specific Weave.
     * @param _tokenId The ID of the Weave.
     * @return The description of the Weave.
     */
    function getTokenDescription(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Weave does not exist");
        return _weaves[_tokenId].description;
    }

    // --- II. Entropic & Evolutionary Mechanics ---

    /**
     * @dev Allows anyone to trigger the update of a Weave's vibrancy and entropy.
     *      This makes property updates gas-efficient for owners as anyone can trigger it.
     *      Updates only if sufficient time has passed since the last update.
     * @param _tokenId The ID of the Weave.
     */
    function triggerEntropicDecay(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Weave does not exist");
        Weave storage weave = _weaves[_tokenId];
        
        // Only update if a decay period has passed
        require(block.number > weave.lastUpdateBlock + decayPeriodBlocks, "Not enough blocks passed for decay");

        (uint256 currentVibrancy, uint256 currentEntropy) = _calculateDynamicProperties(weave);
        _updateWeaveInStorage(_tokenId, currentVibrancy, currentEntropy, weave.quantumState);
    }

    /**
     * @dev Spends Catalyst tokens to boost a Weave's vibrancy and reduce its entropy.
     *      The effectiveness depends on the Weave's current quantumState.
     * @param _tokenId The ID of the Weave.
     * @param _amountCatalyst The amount of Catalyst tokens to spend.
     */
    function fortifyWeave(uint256 _tokenId, uint256 _amountCatalyst) public whenNotPaused onlyWeaveOwner(_tokenId) {
        require(_exists(_tokenId), "Weave does not exist");
        require(_amountCatalyst > 0, "Amount must be greater than zero");
        catalyst.transferFrom(msg.sender, address(this), _amountCatalyst);

        Weave storage weave = _weaves[_tokenId];
        (uint256 currentVibrancy, uint256 currentEntropy) = _calculateDynamicProperties(weave);

        uint256 vibrancyBoost = _amountCatalyst * 10; // Base boost
        uint256 entropyReduction = _amountCatalyst * 5; // Base reduction

        // Adjust effectiveness based on quantumState
        if (weave.quantumState == QuantumState.Volatile) {
            vibrancyBoost = vibrancyBoost / 2; // Less effective in volatile state
            entropyReduction = entropyReduction * 2; // More effective at reducing entropy
        } else if (weave.quantumState == QuantumState.Resonant) {
            vibrancyBoost = vibrancyBoost * 2; // Highly effective
            entropyReduction = entropyReduction / 2; // Less focus on entropy
        }

        currentVibrancy = currentVibrancy + vibrancyBoost > 1000 ? 1000 : currentVibrancy + vibrancyBoost;
        currentEntropy = currentEntropy > entropyReduction ? currentEntropy - entropyReduction : 0;

        _updateWeaveInStorage(_tokenId, currentVibrancy, currentEntropy, weave.quantumState);
    }

    /**
     * @dev Allows the owner to attempt to transition a Weave to a target quantum state.
     *      Requires Catalyst and specific on-chain conditions to be met for success.
     * @param _tokenId The ID of the Weave.
     * @param _targetState The desired new quantum state.
     */
    function shiftQuantumState(uint256 _tokenId, QuantumState _targetState) public whenNotPaused onlyWeaveOwner(_tokenId) {
        require(_exists(_tokenId), "Weave does not exist");
        require(_targetState != _weaves[_tokenId].quantumState, "Weave is already in target state");
        require(_targetState != QuantumState.Attuned, "Cannot shift to Attuned state directly, use attuneWeaveToOracle");

        Weave storage weave = _weaves[_tokenId];
        (uint256 currentVibrancy, uint256 currentEntropy) = _calculateDynamicProperties(weave);

        uint256 catalystCost = 100; // Base cost
        bool conditionsMet = false;

        // Example logic for state transitions
        if (_targetState == QuantumState.Volatile) {
            require(currentEntropy > 500, "Entropy must be high to become Volatile");
            catalystCost = 150;
            conditionsMet = true;
        } else if (_targetState == QuantumState.Resonant) {
            require(weave.resonance > 700, "Resonance must be high to become Resonant");
            catalystCost = 200;
            conditionsMet = true;
        } else if (_targetState == QuantumState.Dormant) {
            require(currentVibrancy < 200 && currentEntropy > 800, "Low vibrancy and high entropy for Dormant state");
            catalystCost = 50;
            conditionsMet = true;
        } else if (_targetState == QuantumState.Stable) {
            require(currentVibrancy > 600 && currentEntropy < 300, "High vibrancy and low entropy for Stable state");
            catalystCost = 100;
            conditionsMet = true;
        } else {
            revert("Invalid target state for direct shift");
        }

        require(conditionsMet, "Conditions for state shift not met");
        catalyst.transferFrom(msg.sender, address(this), catalystCost);

        QuantumState oldState = weave.quantumState;
        _updateWeaveInStorage(_tokenId, currentVibrancy, currentEntropy, _targetState);
        emit QuantumStateShifted(_tokenId, oldState, _targetState);
    }

    // --- III. Interconnectivity & Threading ---

    /**
     * @dev Creates a directional link (thread) from one Weave to another.
     *      Both Weaves must be owned by the caller. Prevents duplicate threads.
     * @param _weaverId The ID of the Weave initiating the thread.
     * @param _targetId The ID of the Weave being threaded to.
     */
    function threadWeaves(uint256 _weaverId, uint256 _targetId) public whenNotPaused {
        require(_exists(_weaverId), "Weaver Weave does not exist");
        require(_exists(_targetId), "Target Weave does not exist");
        require(ownerOf(_weaverId) == msg.sender, "Caller does not own weaver Weave");
        require(ownerOf(_targetId) == msg.sender, "Caller does not own target Weave");
        require(_weaverId != _targetId, "Cannot thread a Weave to itself");

        Weave storage weaverWeave = _weaves[_weaverId];
        for (uint256 i = 0; i < weaverWeave.threadedTo.length; i++) {
            if (weaverWeave.threadedTo[i] == _targetId) {
                revert("Weaves already threaded");
            }
        }

        weaverWeave.threadedTo.push(_targetId);
        emit WeaveThreaded(_weaverId, _targetId);
    }

    /**
     * @dev Removes an existing thread between two Weaves.
     * @param _weaverId The ID of the Weave initiating the thread.
     * @param _targetId The ID of the Weave being unthreaded from.
     */
    function unthreadWeaves(uint256 _weaverId, uint256 _targetId) public whenNotPaused {
        require(_exists(_weaverId), "Weaver Weave does not exist");
        require(_exists(_targetId), "Target Weave does not exist");
        require(ownerOf(_weaverId) == msg.sender, "Caller does not own weaver Weave");
        require(_weaverId != _targetId, "Cannot unthread a Weave from itself");

        Weave storage weaverWeave = _weaves[_weaverId];
        bool found = false;
        for (uint256 i = 0; i < weaverWeave.threadedTo.length; i++) {
            if (weaverWeave.threadedTo[i] == _targetId) {
                weaverWeave.threadedTo[i] = weaverWeave.threadedTo[weaverWeave.threadedTo.length - 1];
                weaverWeave.threadedTo.pop();
                found = true;
                break;
            }
        }
        require(found, "Weaves are not threaded");
        emit WeaveUnthreaded(_weaverId, _targetId);
    }

    /**
     * @dev Returns an array of all Weave IDs that a given Weave is directly threaded to.
     * @param _tokenId The ID of the Weave.
     * @return An array of Weave IDs.
     */
    function getDirectThreads(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "Weave does not exist");
        return _weaves[_tokenId].threadedTo;
    }

    /**
     * @dev Checks if a path exists between two Weaves through threading, up to a specified maximum depth.
     *      Uses a limited breadth-first search to prevent excessive gas usage.
     * @param _startId The starting Weave ID.
     * @param _targetId The target Weave ID.
     * @param _maxDepth The maximum depth to search.
     * @return True if a path is found, false otherwise.
     */
    function getThreadDepth(uint256 _startId, uint256 _targetId, uint256 _maxDepth) public view returns (bool) {
        require(_exists(_startId), "Start Weave does not exist");
        require(_exists(_targetId), "Target Weave does not exist");
        require(_startId != _targetId, "Start and target Weave are the same");
        require(_maxDepth > 0 && _maxDepth <= 5, "Max depth must be between 1 and 5 for gas efficiency"); // Limit depth for on-chain computation

        mapping(uint256 => bool) visited;
        uint256[] memory queue = new uint256[](1);
        queue[0] = _startId;
        visited[_startId] = true;
        
        uint256 head = 0;
        uint256 tail = 1;
        uint256 currentDepth = 0;

        // Implement a basic BFS
        while (head < tail && currentDepth < _maxDepth) {
            uint224 levelSize = uint224(tail - head); // Cast to smaller type
            for (uint256 i = 0; i < levelSize; i++) {
                uint256 currentWeaveId = queue[head++];
                uint256[] memory directThreads = _weaves[currentWeaveId].threadedTo;

                for (uint224 j = 0; j < directThreads.length; j++) {
                    uint256 nextWeaveId = directThreads[j];
                    if (nextWeaveId == _targetId) {
                        return true;
                    }
                    if (!visited[nextWeaveId]) {
                        visited[nextWeaveId] = true;
                        // Dynamically resize queue if needed (simple append)
                        uint256[] memory newQueue = new uint256[](queue.length + 1);
                        for(uint256 k = 0; k < queue.length; k++) {
                            newQueue[k] = queue[k];
                        }
                        newQueue[tail++] = nextWeaveId;
                        queue = newQueue;
                    }
                }
            }
            currentDepth++;
        }
        return false;
    }


    // --- IV. Catalyst Token (ERC20) Integration ---

    /**
     * @dev Allows users to mint Catalyst tokens by paying ETH.
     *      The amount of Catalyst minted depends on the `catalystMintPrice`.
     * @param _amount The amount of Catalyst tokens to mint.
     */
    function mintCatalyst(uint256 _amount) public payable whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(msg.value >= _amount * catalystMintPrice, "Insufficient ETH for Catalyst minting");
        catalyst.mint(msg.sender, _amount);
        emit CatalystMinted(msg.sender, _amount);
    }

    /**
     * @dev Allows users to burn their Catalyst tokens.
     * @param _amount The amount of Catalyst tokens to burn.
     */
    function burnCatalyst(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        catalyst.burn(msg.sender, _amount);
        emit CatalystBurned(msg.sender, _amount);
    }

    // --- V. Oracle Integration (Chainlink) ---

    /**
     * @dev Allows a Weave owner to set their Weave to "attune" to an external Chainlink data stream.
     *      Requires Catalyst and a LINK deposit for future oracle requests.
     * @param _tokenId The ID of the Weave to attune.
     * @param _oracle The address of the Chainlink oracle.
     * @param _oracleJobId The Chainlink Job ID for the data request.
     * @param _dataKey The key for the specific data point (e.g., "temperature", "volatility").
     * @param _attunementFeeLink The LINK fee required for each oracle request.
     * @param _callbackGasLimit The gas limit for the `fulfillOracleAttunement` callback.
     */
    function attuneWeaveToOracle(
        uint256 _tokenId,
        address _oracle,
        bytes32 _oracleJobId,
        bytes32 _dataKey,
        uint256 _attunementFeeLink,
        uint256 _callbackGasLimit
    ) public whenNotPaused onlyWeaveOwner(_tokenId) {
        require(_exists(_tokenId), "Weave does not exist");
        require(LinkTokenInterface(LINK).balanceOf(msg.sender) >= _attunementFeeLink, "Insufficient LINK for initial attunement fee");
        require(_oracle != address(0), "Oracle address cannot be zero");

        Weave storage weave = _weaves[_tokenId];
        weave.attunementOracle = _oracle;
        weave.attunementJobId = _oracleJobId;
        weave.attunementDataKey = _dataKey;
        weave.attunementFeeLink = _attunementFeeLink;
        weave.callbackGasLimit = _callbackGasLimit;
        
        // Transfer initial LINK fee from owner to this contract for future requests
        LinkTokenInterface(LINK).transferFrom(msg.sender, address(this), _attunementFeeLink);

        // Optionally, shift state to Attuned
        QuantumState oldState = weave.quantumState;
        weave.quantumState = QuantumState.Attuned;
        emit QuantumStateShifted(_tokenId, oldState, QuantumState.Attuned);
        
        emit WeaveAttuned(_tokenId, _oracle, _oracleJobId, _dataKey);
    }

    /**
     * @dev Allows anyone to trigger an on-demand Chainlink oracle data request for an attuned Weave.
     *      The caller must ensure the contract has sufficient LINK.
     * @param _tokenId The ID of the Weave to request data for.
     */
    function requestOracleAttunementData(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "Weave does not exist");
        Weave storage weave = _weaves[_tokenId];
        require(weave.attunementOracle != address(0), "Weave is not attuned to an oracle");
        
        // Ensure the contract has enough LINK to pay for the request
        require(LinkTokenInterface(LINK).balanceOf(address(this)) >= weave.attunementFeeLink, "Contract has insufficient LINK to fulfill request");

        Chainlink.Request memory request = buildChainlinkRequest(weave.attunementJobId, address(this), this.fulfillOracleAttunement.selector);
        request.add(_weaves[_tokenId].attunementDataKey, "1"); // Requesting specific data key from the oracle
        request.addUint("times", 100); // Example: Multiply result by 100 if it's a decimal
        
        // Set gas limit for the callback
        request.setBuffer(0); // Clear buffer for specific gas limit
        request.setGasLimit(weave.callbackGasLimit);

        bytes32 requestId = sendChainlinkRequestTo(_weaves[_tokenId].attunementOracle, request, weave.attunementFeeLink);
        
        _requestIdToTokenId[requestId] = _tokenId;
        weave.lastAttunementRequestBlock = block.number;
        emit OracleAttunementRequested(_tokenId, requestId);
    }

    /**
     * @dev Chainlink callback function to fulfill the oracle data request.
     *      Processes the received oracle data and updates the Weave's resonance and quantum state.
     *      Only callable by the Chainlink oracle.
     * @param _requestId The ID of the Chainlink request.
     * @param _dataValue The data value received from the oracle.
     */
    function fulfillOracleAttunement(bytes32 _requestId, uint256 _dataValue) public recordChainlinkFulfillment(_requestId) {
        uint256 tokenId = _requestIdToTokenId[_requestId];
        require(_exists(tokenId), "Weave does not exist for this requestId");

        Weave storage weave = _weaves[tokenId];
        (uint256 currentVibrancy, uint256 currentEntropy) = _calculateDynamicProperties(weave);

        weave.lastAttunementValue = _dataValue;
        
        // Example logic: Resonance increases based on data value
        uint224 resonanceIncrease = uint224(_dataValue / 10); // Scale data value
        weave.resonance = weave.resonance + resonanceIncrease > 1000 ? 1000 : weave.resonance + resonanceIncrease;

        // Example logic: Quantum state reaction to data
        QuantumState oldState = weave.quantumState;
        if (weave.resonance > 800 && weave.quantumState != QuantumState.Resonant) {
            weave.quantumState = QuantumState.Resonant;
        } else if (weave.resonance < 200 && weave.quantumState == QuantumState.Attuned) {
            // Revert to stable if attunement is weak
            weave.quantumState = QuantumState.Stable;
        }
        
        _updateWeaveInStorage(tokenId, currentVibrancy, currentEntropy, weave.quantumState);
        if (oldState != weave.quantumState) {
            emit QuantumStateShifted(tokenId, oldState, weave.quantumState);
        }
        emit OracleAttunementFulfilled(_requestId, tokenId, _dataValue);
        delete _requestIdToTokenId[_requestId]; // Clean up mapping
    }

    /**
     * @dev Retrieves the current oracle attunement parameters for a Weave.
     * @param _tokenId The ID of the Weave.
     * @return A tuple containing attunement details.
     */
    function getAttunementParameters(uint256 _tokenId) public view returns (
        address oracle,
        bytes32 jobId,
        bytes32 dataKey,
        uint256 lastValue,
        uint256 lastRequestBlock,
        uint256 feeLink,
        uint256 callbackGas
    ) {
        require(_exists(_tokenId), "Weave does not exist");
        Weave storage weave = _weaves[_tokenId];
        return (
            weave.attunementOracle,
            weave.attunementJobId,
            weave.attunementDataKey,
            weave.lastAttunementValue,
            weave.lastAttunementRequestBlock,
            weave.attunementFeeLink,
            weave.callbackGasLimit
        );
    }

    // --- VI. Ecosystem & Admin ---

    /**
     * @dev Admin function to set the universal decay rate for Weave vibrancy.
     * @param _newRate The new global decay rate (e.g., 1 unit per decayPeriodBlocks).
     */
    function setGlobalDecayRate(uint256 _newRate) public onlyOwner {
        globalDecayRate = _newRate;
    }

    /**
     * @dev Admin function to set the price in ETH for minting new Weaves.
     * @param _newPrice The new mint price in wei.
     */
    function setMintPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    /**
     * @dev Admin function to set the ETH price for minting Catalyst tokens.
     * @param _newPrice The new Catalyst mint price in wei per token.
     */
    function setCatalystMintPrice(uint256 _newPrice) public onlyOwner {
        catalystMintPrice = _newPrice;
    }

    /**
     * @dev Admin function to withdraw excess LINK tokens from the contract in an emergency.
     */
    function emergencyWithdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(LINK);
        uint256 balance = link.balanceOf(address(this));
        require(balance > 0, "No LINK to withdraw");
        link.transfer(owner(), balance);
        emit LinkWithdrawn(owner(), balance);
    }

    /**
     * @dev Admin function to withdraw accumulated ETH from the contract.
     */
    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        payable(owner()).transfer(balance);
        emit EtherWithdrawn(owner(), balance);
    }

    /**
     * @dev Admin function to set or update the Chainlink operator address.
     *      This is usually managed by the ChainlinkClient directly, but good to explicitly expose.
     * @param _operator The new Chainlink operator address.
     */
    function setChainlinkOperator(address _operator) public onlyOwner {
        setOracle(_operator); // ChainlinkClient's internal function
        emit ChainlinkOperatorSet(_operator);
    }

    // --- ERC721 Overrides ---
    // Ensure that Weave owner is set correctly on transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) { // Minting
            _weaves[tokenId].owner = to;
        } else if (to == address(0)) { // Burning
            delete _weaves[tokenId];
        } else { // Transferring
            _weaves[tokenId].owner = to;
        }
    }

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        // This is where ERC721 standard transfer logic is handled.
        // The _beforeTokenTransfer hook covers our internal Weave struct update.
        return super._update(to, tokenId, auth);
    }

    // --- Receive ETH ---
    receive() external payable {
        // Allows the contract to receive ETH for minting or general donations
    }
}

/**
 * @title CatalystToken
 * @dev An ERC20 token used for influencing Weave properties and interactions within QuantumLoom.
 */
contract CatalystToken is ERC20, ERC20Burnable {
    address public minterContract;

    constructor(address _minterContract) ERC20("Quantum Catalyst", "QCAT") {
        minterContract = _minterContract;
    }

    /**
     * @dev Mints new Catalyst tokens, callable only by the minterContract (QuantumLoom).
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public {
        require(msg.sender == minterContract, "Only minter contract can mint");
        _mint(to, amount);
    }

    // Override default _transfer and _approve to be pausable if needed
    // function _transfer(address from, address to, uint256 amount) internal override(ERC20) {
    //     // Optional: add pausable check here if Catalyst should pause independently
    //     super._transfer(from, to, amount);
    // }
}
```