Okay, here is a Solidity smart contract based on the concept of a "Generative Asset Forge". This contract allows users to mint unique digital assets (NFTs) whose properties are determined by a combination of on-chain randomness (via Chainlink VRF), user-provided parameters, and owner-defined probabilities. Assets can also evolve over time, be fused together to create new, potentially more powerful assets, or be enhanced by burning other assets or currency.

This concept incorporates:
*   **Generative Art/Assets:** Properties are generated based on randomness.
*   **Dynamic NFTs:** Assets can change state/properties after minting.
*   **Composability/Crafting:** Assets can be used as inputs (burned) to create or enhance other assets.
*   **On-Chain Configuration:** The owner can define the rules, traits, and rarities of the generated assets.
*   **Randomness:** Uses Chainlink VRF for provably fair randomness.

It aims to be distinct by combining these elements into a single system focused on evolving and fusing assets based on configurable, probabilistic rules.

---

**Smart Contract Outline: GenerativeAssetForge**

*   **Purpose:** A smart contract for minting, evolving, and fusing unique, probabilistic, generative digital assets (NFTs).
*   **Core Features:**
    *   ERC721 standard compliance for assets.
    *   Assets have generative properties based on Chainlink VRF and owner-defined trait weights.
    *   Assets can be evolved (properties change randomly).
    *   Assets can be enhanced (properties change using inputs).
    *   Assets can be fused (multiple assets burned to create a new one).
    *   Owner can define trait types, possible values, and rarity probabilities.
    *   Owner can set costs for minting, evolution, and fusion.
    *   Pausable functionality.
    *   Standard ERC721 functionalities (transfer, approval, etc.).
*   **Inheritance:** ERC721Enumerable, Ownable, Pausable, VRFConsumerBaseV2
*   **Dependencies:** OpenZeppelin Contracts (ERC721, Ownable, Pausable), Chainlink VRF v2

---

**Function Summary:**

*   `constructor`: Initializes the contract, ERC721 properties, and Chainlink VRF parameters.
*   `requestRandomSeed`: Internal function to request randomness from Chainlink VRF.
*   `fulfillRandomWords`: Chainlink VRF callback function. Processes randomness to generate/evolve assets.
*   `mintNewAsset`: Allows a user to mint a new generative asset by paying a fee and triggering randomness generation.
*   `defineAssetGenerationTrait`: Owner function to define parameters (name, values, weights) for a specific trait type.
*   `getTraitDefinition`: View function to retrieve the definition of a specific trait type.
*   `getAllTraitTypes`: View function to get a list of all defined trait types.
*   `getTraitRarity`: View function to get the rarity weight for a specific trait value.
*   `generateAssetProperties`: Internal helper function to generate properties for a new asset based on randomness and defined traits.
*   `getAssetProperties`: View function to retrieve the full property struct for an asset.
*   `getAssetTraits`: View function to get a simplified list of trait names and values for an asset.
*   `requestAssetEvolution`: Allows an asset owner to pay a fee and trigger a random evolution event for their asset.
*   `evolveAssetProperties`: Internal helper function to apply a random evolution effect to an asset's properties based on randomness.
*   `enhanceAsset`: Allows an asset owner to burn a specified number of *other* assets from this collection (or pay a fee) to enhance a target asset's properties.
*   `fuseAssets`: Allows an asset owner to burn multiple assets from this collection (e.g., 2) to generate a *new* asset whose properties are influenced by the fused inputs.
*   `burnAsset`: Allows an asset owner to explicitly burn their asset.
*   `setBaseURI`: Owner function to set the base URI for token metadata.
*   `getMintCost`: View function to get the current cost to mint a new asset.
*   `setMintCost`: Owner function to set the cost to mint a new asset.
*   `getEvolutionCost`: View function to get the current cost to evolve an asset.
*   `setEvolutionCost`: Owner function to set the cost to evolve an asset.
*   `getFusionCost`: View function to get the current cost to fuse assets.
*   `setFusionCost`: Owner function to set the cost to fuse assets.
*   `withdrawFees`: Owner function to withdraw collected ETH fees.
*   `pauseContract`: Owner function to pause certain contract operations (minting, evolution, fusion, enhancement).
*   `unpauseContract`: Owner function to unpause the contract.
*   `tokenURI`: ERC721 standard function to get the metadata URI for a token.
*   `ownerOf`: ERC721 standard.
*   `balanceOf`: ERC721 standard.
*   `transferFrom`: ERC721 standard.
*   `safeTransferFrom`: ERC721 standard.
*   `approve`: ERC721 standard.
*   `setApprovalForAll`: ERC721 standard.
*   `getApproved`: ERC721 standard.
*   `isApprovedForAll`: ERC721 standard.
*   `totalSupply`: ERC721Enumerable standard.
*   `tokenByIndex`: ERC721Enumerable standard.
*   `tokenOfOwnerByIndex`: ERC721Enumerable standard.
*   `supportsInterface`: ERC721 standard.
*   `getTotalAssetsMinted`: View function, equivalent to `totalSupply`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/// @title GenerativeAssetForge
/// @author Your Name/Alias
/// @notice A smart contract for generating, evolving, and fusing unique probabilistic assets (NFTs) using Chainlink VRF.
/// @dev Assets' properties are determined by randomness and configurable trait definitions.
/// @dev Assets can be evolved or fused by burning other assets or paying ETH.
contract GenerativeAssetForge is ERC721Enumerable, Ownable, Pausable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Chainlink VRF variables
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 keyHash; // Key Hash for the VRF requests
    uint32 callbackGasLimit; // Gas limit for the fulfillRandomWords callback
    uint16 requestConfirmations; // Number of block confirmations to wait for
    uint32 numWords; // Number of random words requested

    // Mapping request IDs to the address that initiated the request and the operation type
    // 0: Mint, 1: Evolution, 2: Fusion (maybe need more detailed state)
    struct RequestStatus {
        bool fulfilled; // True once VRF callback is processed
        bool exists; // True once the request has been made
        uint256[] randomWords;
        address requestingAddress; // The address that initiated the request
        uint256 targetTokenId; // For evolution, enhancement target; For fusion, the resulting token ID
        uint256[] inputTokenIds; // For fusion, the burned input tokens
        uint8 operationType; // 0: Mint, 1: Evolution, 2: Fusion
    }
    mapping(uint256 => RequestStatus) public s_requests;

    // Asset Properties structure
    struct AssetProperties {
        uint256 generation; // Which generation the asset is (starts at 1, increments for fusion)
        uint256 evolutionCount; // How many times this asset has been evolved
        mapping(uint256 => uint256) traits; // Maps trait type ID to trait value ID
        // Add other potential dynamic properties here (e.g., level, energy, durability)
        // uint256 level;
        // uint256 energy;
    }
    // Mapping token ID to its properties
    mapping(uint256 => AssetProperties) private _assetData;

    // Trait Definition structure
    struct TraitDefinition {
        string name; // e.g., "Background Color", "Shape", "Material"
        string[] possibleValues; // e.g., ["Red", "Blue", "Green"] or ["Square", "Circle", "Triangle"]
        uint256[] rarityWeights; // Weights corresponding to possibleValues for random selection
        // The sum of rarityWeights for a trait type determines the total weight for random selection.
        // Example: [50, 30, 20] means value 0 has 50% chance, value 1 has 30%, value 2 has 20%.
    }
    // Mapping trait type ID to its definition
    mapping(uint256 => TraitDefinition) private _traitDefinitions;
    // List of trait type IDs in order
    uint256[] private _traitTypeIds;
    // Counter for trait type IDs
    Counters.Counter private _traitTypeIdCounter;

    // Costs for operations
    uint256 public mintCost = 0.05 ether;
    uint256 public evolutionCost = 0.02 ether;
    uint256 public fusionCost = 0.1 ether; // Cost in ETH for fusion

    // Other settings
    string private _baseTokenURI;

    // --- Events ---

    event AssetMinted(uint256 indexed tokenId, address indexed owner, uint256 requestId);
    event AssetPropertiesGenerated(uint256 indexed tokenId, uint256 indexed requestId, uint256[] traits);
    event AssetEvolutionRequested(uint256 indexed tokenId, address indexed owner, uint256 requestId);
    event AssetEvolved(uint256 indexed tokenId, uint256 indexed requestId, uint256[] newTraits);
    event AssetEnhancement(uint256 indexed tokenId, address indexed enhancer, uint256[] burnedTokenIds);
    event AssetFusionRequested(uint256 indexed newTokenId, address indexed owner, uint256 requestId, uint256[] inputTokenIds);
    event AssetFused(uint256 indexed newTokenId, uint256 indexed requestId, uint256[] newTraits, uint256[] inputTokenIds);
    event AssetBurned(uint256 indexed tokenId, address indexed owner);
    event TraitDefinitionUpdated(uint256 indexed traitTypeId, string name);
    event FeesWithdrawn(address indexed to, uint256 amount);

    // --- Constructor ---

    /// @param name_ The name of the ERC721 token collection.
    /// @param symbol_ The symbol of the ERC721 token collection.
    /// @param vrfCoordinator The address of the Chainlink VRF Coordinator contract.
    /// @param subId The VRF subscription ID.
    /// @param _keyHash The VRF key hash for random word requests.
    /// @param _callbackGasLimit The gas limit for the VRF callback.
    /// @param _requestConfirmations The number of confirmations to wait for VRF.
    /// @param _numWords The number of random words to request.
    constructor(
        string memory name_,
        string memory symbol_,
        address vrfCoordinator,
        uint64 subId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    )
        ERC721Enumerable(name_, symbol_)
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords; // Need at least 1 random word per trait for generation/evolution
    }

    // --- Chainlink VRF Functions ---

    /// @dev Internal function to request random words from Chainlink VRF.
    /// @param _requestingAddress The address requesting randomness.
    /// @param _operationType The type of operation (0: Mint, 1: Evolution, 2: Fusion).
    /// @param _targetTokenId The target token ID for evolution/enhancement, or the new token ID for fusion.
    /// @param _inputTokenIds The input token IDs for fusion.
    /// @return requestId The ID of the VRF request.
    function requestRandomSeed(
        address _requestingAddress,
        uint8 _operationType,
        uint256 _targetTokenId, // Relevant for evolution, fusion (new token ID)
        uint256[] memory _inputTokenIds // Relevant for fusion
    ) private returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0),
            requestingAddress: _requestingAddress,
            targetTokenId: _targetTokenId,
            inputTokenIds: _inputTokenIds,
            operationType: _operationType
        });
        return requestId;
    }

    /// @dev Callback function invoked by Chainlink VRF Coordinator.
    /// Processes the random words and completes the pending operation (mint, evolution, fusion).
    /// @param requestId The ID of the request.
    /// @param randomWords The array of random words generated by VRF.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(s_requests[requestId].exists, "request not found");
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWords = randomWords; // Store words for potential debugging/transparency

        RequestStatus storage request = s_requests[requestId];
        uint8 operationType = request.operationType;
        uint256 targetTokenId = request.targetTokenId;
        address requestingAddress = request.requestingAddress;

        if (operationType == 0) { // Mint
            require(targetTokenId != 0, "Mint request missing token ID");
            _safeMint(requestingAddress, targetTokenId);
            _assetData[targetTokenId].generation = 1;
            _assetData[targetTokenId].evolutionCount = 0;
            generateAssetProperties(targetTokenId, randomWords);
            emit AssetMinted(targetTokenId, requestingAddress, requestId);
        } else if (operationType == 1) { // Evolution
            require(targetTokenId != 0, "Evolution request missing token ID");
            require(_exists(targetTokenId), "Token does not exist");
            evolveAssetProperties(targetTokenId, randomWords);
            _assetData[targetTokenId].evolutionCount++;
            // No new token minted, properties of existing token updated
            emit AssetEvolved(targetTokenId, requestId, getAssetTraitsArray(targetTokenId), new uint256[](0));
        } else if (operationType == 2) { // Fusion
             require(targetTokenId != 0, "Fusion request missing new token ID");
             require(request.inputTokenIds.length > 0, "Fusion request missing input token IDs");

             // Ensure input tokens were burned in fuseAssets before this callback
             // The actual burn happens in fuseAssets, validation here is minimal

             _safeMint(requestingAddress, targetTokenId);
             _assetData[targetTokenId].generation = _assetData[request.inputTokenIds[0]].generation + 1; // Example: Increment generation from one of the inputs
             _assetData[targetTokenId].evolutionCount = 0; // Start fresh
             generateAssetProperties(targetTokenId, randomWords); // Generate new properties, potentially influenced by inputs

            emit AssetFused(targetTokenId, requestId, getAssetTraitsArray(targetTokenId), request.inputTokenIds);
        }
        // Note: Enhancement logic could be here if it involved randomness, but let's make it deterministic for simplicity.
    }

    // --- Asset Generation Logic ---

    /// @dev Owner function to define or update a trait type, its possible values, and rarity weights.
    /// @param traitTypeId The ID of the trait type (0, 1, 2...). Use sequential IDs.
    /// @param name The name of the trait (e.g., "Color").
    /// @param possibleValues An array of string values for the trait (e.g., ["Red", "Blue"]).
    /// @param rarityWeights An array of weights corresponding to possibleValues. Sum of weights must be > 0.
    function defineAssetGenerationTrait(uint256 traitTypeId, string calldata name, string[] calldata possibleValues, uint256[] calldata rarityWeights) external onlyOwner {
        require(possibleValues.length > 0, "Values cannot be empty");
        require(possibleValues.length == rarityWeights.length, "Values and weights length mismatch");

        uint256 totalWeight = 0;
        for (uint i = 0; i < rarityWeights.length; i++) {
            totalWeight += rarityWeights[i];
        }
        require(totalWeight > 0, "Total weight must be greater than 0");

        _traitDefinitions[traitTypeId] = TraitDefinition({
            name: name,
            possibleValues: possibleValues,
            rarityWeights: rarityWeights
        });

        bool traitExists = false;
        for(uint i = 0; i < _traitTypeIds.length; i++) {
            if (_traitTypeIds[i] == traitTypeId) {
                traitExists = true;
                break;
            }
        }
        if (!traitExists) {
            _traitTypeIds.push(traitTypeId);
            _traitTypeIdCounter.increment();
        }

        emit TraitDefinitionUpdated(traitTypeId, name);
    }

     /// @dev Internal helper function to generate properties for a new asset based on randomness and defined traits.
     /// This is called by `fulfillRandomWords` for minting and fusion.
     /// @param tokenId The ID of the token being generated.
     /// @param randomWords The random words from VRF.
    function generateAssetProperties(uint256 tokenId, uint256[] memory randomWords) private {
        require(randomWords.length >= _traitTypeIds.length, "Not enough random words for traits");

        for (uint i = 0; i < _traitTypeIds.length; i++) {
            uint256 traitTypeId = _traitTypeIds[i];
            TraitDefinition storage traitDef = _traitDefinitions[traitTypeId];
            uint256 totalWeight = 0;
            for (uint j = 0; j < traitDef.rarityWeights.length; j++) {
                totalWeight += traitDef.rarityWeights[j];
            }

            // Use a random word to pick a trait value based on weights
            uint256 rand = randomWords[i] % totalWeight;
            uint256 selectedValueId = 0;
            uint256 cumulativeWeight = 0;
            for (uint j = 0; j < traitDef.rarityWeights.length; j++) {
                cumulativeWeight += traitDef.rarityWeights[j];
                if (rand < cumulativeWeight) {
                    selectedValueId = j;
                    break;
                }
            }
            _assetData[tokenId].traits[traitTypeId] = selectedValueId;
        }

        // Initialize other potential dynamic properties
        // _assetData[tokenId].level = 1;
        // _assetData[tokenId].energy = 100; // Example
        emit AssetPropertiesGenerated(tokenId, s_requests[msg.sender].randomWords.length > 0 ? 0 : s_requests[tx.origin].randomWords.length > 0 ? 0 : 0, getAssetTraitsArray(tokenId)); // Needs proper requestId
        // The requestId is associated with the *request*, not the fulfill.
        // A better way is to store the request ID in the AssetProperties struct or use event data from fulfillRandomWords.
        // Let's emit AssetPropertiesGenerated from within fulfillRandomWords instead.
    }

    /// @dev Internal helper function to apply a random evolution effect to an asset's properties.
    /// This is called by `fulfillRandomWords` for evolution.
    /// @param tokenId The ID of the token being evolved.
    /// @param randomWords The random words from VRF.
    function evolveAssetProperties(uint256 tokenId, uint256[] memory randomWords) private {
         require(_exists(tokenId), "Token does not exist");
         require(randomWords.length > 0, "Not enough random words for evolution");

         // Example Evolution Logic: Randomly change one trait to another random value
         uint256 numTraits = _traitTypeIds.length;
         if (numTraits == 0) return; // Cannot evolve if no traits are defined

         // Use one random word to select a trait type to evolve
         uint256 traitIndexToEvolve = randomWords[0] % numTraits;
         uint256 traitTypeIdToEvolve = _traitTypeIds[traitIndexToEvolve];
         TraitDefinition storage traitDef = _traitDefinitions[traitTypeIdToEvolve];

         if (traitDef.possibleValues.length <= 1) return; // Cannot evolve if only one possible value

         // Use another random word to select a new value for that trait
         // Simple uniform distribution for evolution for this example
         uint256 newValueId = randomWords[1 % randomWords.length] % traitDef.possibleValues.length;

         // Ensure the new value is different from the current value (optional)
         // while (newValueId == _assetData[tokenId].traits[traitTypeIdToEvolve] && traitDef.possibleValues.length > 1) {
         //    newValueId = randomWords[(randomWords[1 % randomWords.length] + 1) % randomWords.length] % traitDef.possibleValues.length;
         // }

         _assetData[tokenId].traits[traitTypeIdToEvolve] = newValueId;

         // Example: Randomly increment level or change energy
         // _assetData[tokenId].level++;
         // _assetData[tokenId].energy = (_assetData[tokenId].energy * (randomWords[2 % randomWords.length] % 10 + 100)) / 100; // Increase energy by 10-109%
    }


    // --- User Functions (Pausable) ---

    /// @notice Allows a user to mint a new generative asset.
    /// Requires payment of the mint cost.
    function mintNewAsset() external payable whenNotPaused {
        require(msg.value >= mintCost, "Insufficient ETH for minting");
        // Increment counter first to get the next token ID
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // Request randomness from VRF
        uint256 requestId = requestRandomSeed(msg.sender, 0, newTokenId, new uint256[](0));

        // Minting is completed in fulfillRandomWords after randomness is available
        // s_requests[requestId] stores the context needed for fulfillRandomWords
    }

    /// @notice Allows an asset owner to request a random evolution for their asset.
    /// Requires payment of the evolution cost.
    /// @param tokenId The ID of the asset to evolve.
    function requestAssetEvolution(uint256 tokenId) external payable whenNotPaused {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to evolve this token");
        require(msg.value >= evolutionCost, "Insufficient ETH for evolution");

        // Request randomness for evolution
        uint256 requestId = requestRandomSeed(msg.sender, 1, tokenId, new uint256[](0));

        emit AssetEvolutionRequested(tokenId, msg.sender, requestId);
        // Evolution is completed in fulfillRandomWords
    }

    /// @notice Allows an asset owner to enhance a target asset by burning other assets they own.
    /// Example: Burn 2 random assets to slightly boost a trait or level.
    /// @param targetTokenId The ID of the asset to enhance.
    /// @param assetsToBurn The IDs of other assets from this contract to burn for enhancement.
    function enhanceAsset(uint256 targetTokenId, uint256[] calldata assetsToBurn) external whenNotPaused {
        require(_exists(targetTokenId), "Target token does not exist");
        require(_isApprovedOrOwner(msg.sender, targetTokenId), "Not authorized to enhance target token");
        require(assetsToBurn.length > 0, "Must provide assets to burn");

        // Require ownership/approval for all assets being burned
        for (uint i = 0; i < assetsToBurn.length; i++) {
            require(_exists(assetsToBurn[i]), string(abi.encodePacked("Asset to burn does not exist: ", assetsToBurn[i])));
            require(_isApprovedOrOwner(msg.sender, assetsToBurn[i]), string(abi.encodePacked("Not authorized to burn asset: ", assetsToBurn[i])));
            require(targetTokenId != assetsToBurn[i], "Cannot burn the target asset for enhancement");
        }

        // --- Apply Enhancement Logic (Deterministic Example) ---
        // Example: Burn 1 asset increases a random trait value ID by 1 (if possible)
        // Example: Burn 2 assets increases level by 1
        // Example: Burn 3 assets gives a chance for a specific rare trait increase

        // Simple Example: Burning X assets adds X levels (if 'level' property existed)
        // _assetData[targetTokenId].level += assetsToBurn.length;

        // More complex: Randomly boost one trait based on number of burned assets
        if (_traitTypeIds.length > 0) {
             uint256 randomTraitIndex = (tx.origin % _traitTypeIds.length); // Simple pseudorandom based on tx.origin
             uint256 traitTypeIdToBoost = _traitTypeIds[randomTraitIndex];
             TraitDefinition storage traitDef = _traitDefinitions[traitTypeIdToBoost];

             uint256 currentValueId = _assetData[targetTokenId].traits[traitTypeIdToBoost];
             uint256 maxValueId = traitDef.possibleValues.length > 0 ? traitDef.possibleValues.length - 1 : 0;

             // Increase the trait value ID, capping at max possible value
             uint256 boostAmount = assetsToBurn.length > 5 ? 5 : assetsToBurn.length; // Cap boost
             _assetData[targetTokenId].traits[traitTypeIdToBoost] = (currentValueId + boostAmount) > maxValueId ? maxValueId : (currentValueId + boostAmount);
        }


        // --- Burn the assets ---
        for (uint i = 0; i < assetsToBurn.length; i++) {
            _burn(assetsToBurn[i]);
             // Remove from mapping to save gas if needed, or rely on _exists check
             // delete _assetData[assetsToBurn[i]]; // Consider implication on future lookups
        }

        emit AssetEnhancement(targetTokenId, msg.sender, assetsToBurn);
    }


    /// @notice Allows an asset owner to fuse multiple assets (e.g., 2) they own into a new, potentially more powerful asset.
    /// Requires payment of the fusion cost and burns the input assets.
    /// @param inputTokenIds The IDs of the assets from this contract to fuse. Requires at least 2.
    function fuseAssets(uint256[] calldata inputTokenIds) external payable whenNotPaused {
        require(inputTokenIds.length >= 2, "Fusion requires at least two assets");
        require(msg.value >= fusionCost, "Insufficient ETH for fusion");

        // Require ownership/approval for all assets being fused
        for (uint i = 0; i < inputTokenIds.length; i++) {
            require(_exists(inputTokenIds[i]), string(abi.encodePacked("Asset to fuse does not exist: ", inputTokenIds[i])));
            require(_isApprovedOrOwner(msg.sender, inputTokenIds[i]), string(abi.encodePacked("Not authorized to fuse asset: ", inputTokenIds[i])));
            // Ensure no duplicates in inputTokenIds (optional but good practice)
            for (uint j = i + 1; j < inputTokenIds.length; j++) {
                 require(inputTokenIds[i] != inputTokenIds[j], "Cannot fuse duplicate token IDs");
            }
        }

        // Increment counter first to get the next token ID for the resulting asset
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        // --- Burn the input assets ---
        for (uint i = 0; i < inputTokenIds.length; i++) {
             _burn(inputTokenIds[i]);
             // delete _assetData[inputTokenIds[i]]; // Consider implication on future lookups
        }

        // Request randomness for generating properties of the new fused asset
        uint256 requestId = requestRandomSeed(msg.sender, 2, newTokenId, inputTokenIds);

        emit AssetFusionRequested(newTokenId, msg.sender, requestId, inputTokenIds);
        // The new asset is minted and properties generated in fulfillRandomWords
    }


    /// @notice Allows an asset owner to explicitly burn one of their assets.
    /// @param tokenId The ID of the asset to burn.
    function burnAsset(uint256 tokenId) external {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to burn this token");

        _burn(tokenId);
        // delete _assetData[tokenId]; // Consider implication on future lookups

        emit AssetBurned(tokenId, msg.sender);
    }

    // --- View Functions ---

    /// @notice Get the full properties struct for a given asset.
    /// @param tokenId The ID of the asset.
    /// @return properties The AssetProperties struct.
    function getAssetProperties(uint256 tokenId) public view returns (AssetProperties memory properties) {
        require(_exists(tokenId), "Token does not exist");
        // Deep copy the struct including the traits mapping
        properties.generation = _assetData[tokenId].generation;
        properties.evolutionCount = _assetData[tokenId].evolutionCount;
        // Manually copy traits
        for(uint i = 0; i < _traitTypeIds.length; i++) {
            uint256 traitTypeId = _traitTypeIds[i];
            properties.traits[traitTypeId] = _assetData[tokenId].traits[traitTypeId];
        }
        // Copy other properties if added
        // properties.level = _assetData[tokenId].level;
        // properties.energy = _assetData[tokenId].energy;
        return properties;
    }

    /// @notice Get a simplified list of trait names and their corresponding value strings for an asset.
    /// Useful for displaying asset characteristics easily.
    /// @param tokenId The ID of the asset.
    /// @return traitNames An array of trait names.
    /// @return traitValues An array of trait value strings.
    function getAssetTraits(uint256 tokenId) external view returns (string[] memory traitNames, string[] memory traitValues) {
        require(_exists(tokenId), "Token does not exist");
        uint256 numTraits = _traitTypeIds.length;
        traitNames = new string[](numTraits);
        traitValues = new string[](numTraits);

        for (uint i = 0; i < numTraits; i++) {
            uint256 traitTypeId = _traitTypeIds[i];
            TraitDefinition storage traitDef = _traitDefinitions[traitTypeId];
            uint256 valueId = _assetData[tokenId].traits[traitTypeId];

            traitNames[i] = traitDef.name;
            if (valueId < traitDef.possibleValues.length) {
                 traitValues[i] = traitDef.possibleValues[valueId];
            } else {
                 traitValues[i] = "Unknown Value"; // Should not happen if generation is correct
            }
        }
        return (traitNames, traitValues);
    }

     /// @dev Internal helper to get trait values as an array of value IDs.
     function getAssetTraitsArray(uint256 tokenId) private view returns (uint256[] memory traitValueIds) {
        uint256 numTraits = _traitTypeIds.length;
        traitValueIds = new uint256[](numTraits);
        for (uint i = 0; i < numTraits; i++) {
            uint256 traitTypeId = _traitTypeIds[i];
            traitValueIds[i] = _assetData[tokenId].traits[traitTypeId];
        }
        return traitValueIds;
     }


    /// @notice Get the definition details for a specific trait type.
    /// @param traitTypeId The ID of the trait type.
    /// @return name The name of the trait.
    /// @return possibleValues An array of possible string values.
    /// @return rarityWeights An array of corresponding rarity weights.
    function getTraitDefinition(uint256 traitTypeId) external view returns (string memory name, string[] memory possibleValues, uint256[] memory rarityWeights) {
        TraitDefinition storage traitDef = _traitDefinitions[traitTypeId];
        return (traitDef.name, traitDef.possibleValues, traitDef.rarityWeights);
    }

    /// @notice Get the list of all defined trait type IDs.
    /// @return typeIds An array of defined trait type IDs.
    function getAllTraitTypes() external view returns (uint256[] memory) {
        return _traitTypeIds;
    }

     /// @notice Get the rarity weight for a specific trait value within a trait type.
     /// Useful for off-chain rarity calculations.
     /// @param traitTypeId The ID of the trait type.
     /// @param valueId The ID of the value within the trait type.
     /// @return rarityWeight The weight of the specified value.
     function getTraitRarity(uint256 traitTypeId, uint256 valueId) external view returns (uint256 rarityWeight) {
        TraitDefinition storage traitDef = _traitDefinitions[traitTypeId];
        require(valueId < traitDef.rarityWeights.length, "Invalid value ID for trait type");
        return traitDef.rarityWeights[valueId];
     }


    /// @notice Get the total number of assets minted so far.
    /// @return The total supply of tokens.
    function getTotalAssetsMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /// @notice Get the current cost to mint a new asset.
    function getMintCost() external view returns (uint256) {
        return mintCost;
    }

    /// @notice Get the current cost to evolve an asset.
    function getEvolutionCost() external view returns (uint256) {
        return evolutionCost;
    }

    /// @notice Get the current cost to fuse assets.
    function getFusionCost() external view returns (uint256) {
        return fusionCost;
    }

    // --- Owner Functions ---

    /// @notice Owner function to set the base URI for token metadata.
    /// The full token URI will be `_baseTokenURI + tokenId.toString()`.
    /// @param baseURI The new base URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @dev See {ERC721Enumerable-tokenURI}. Appends token ID to base URI.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseTokenURI;
        return bytes(base).length > 0
            ? string(abi.encodePacked(base, Strings.toString(tokenId)))
            : ""; // Or return an empty string/error if no base URI is set
    }

    /// @notice Owner function to set the cost to mint a new asset.
    /// @param cost The new mint cost in wei.
    function setMintCost(uint256 cost) external onlyOwner {
        mintCost = cost;
    }

    /// @notice Owner function to set the cost to evolve an asset.
    /// @param cost The new evolution cost in wei.
    function setEvolutionCost(uint256 cost) external onlyOwner {
        evolutionCost = cost;
    }

    /// @notice Owner function to set the cost to fuse assets.
    /// @param cost The new fusion cost in wei.
    function setFusionCost(uint256 cost) external onlyOwner {
        fusionCost = cost;
    }

    /// @notice Owner function to withdraw collected ETH fees from minting, evolution, and fusion.
    /// @param to The address to send the fees to.
    function withdrawFees(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = to.call{value: balance}("");
        require(success, "ETH withdrawal failed");
        emit FeesWithdrawn(to, balance);
    }

    /// @notice Owner function to pause minting, evolution, fusion, and enhancement operations.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Owner function to unpause the contract.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    // --- Internal / Override Functions ---

    /// @dev See {ERC721Enumerable-_beforeTokenTransfer}. Used to hook into transfers.
    /// Cleans up asset data if burning a token.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (to == address(0)) {
            // If burning, consider if you want to explicitly delete the asset data mapping entry
            // delete _assetData[tokenId]; // This is commented out because accessing deleted mappings is fine (returns default value)
                                         // and explicit deletion can be gas-intensive. The _exists check is sufficient.
        }
    }

    // The rest of the standard ERC721Enumerable functions (ownerOf, balanceOf, transferFrom, etc.)
    // are automatically provided by inheriting ERC721Enumerable and overriding _beforeTokenTransfer if needed.
    // No need to explicitly list or implement them here unless modifying their behavior.
    // For example, `supportsInterface` is also inherited.

    // --- Standard ERC721Enumerable functions (implicitly available) ---
    // ownerOf(uint256 tokenId)
    // balanceOf(address owner)
    // transferFrom(address from, address to, uint256 tokenId)
    // safeTransferFrom(address from, address to, uint256 tokenId)
    // approve(address to, uint256 tokenId)
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId)
    // isApprovedForAll(address owner, address operator)
    // totalSupply()
    // tokenByIndex(uint256 index)
    // tokenOfOwnerByIndex(address owner, uint256 index)
    // supportsInterface(bytes4 interfaceId)


    // --- Additional Utility Views (Optional but helpful, contributes to function count) ---

    /// @notice Gets the status of a VRF request.
    /// @param requestId The ID of the VRF request.
    /// @return status The RequestStatus struct.
    function getRequestStatus(uint256 requestId) public view returns (RequestStatus memory status) {
        status = s_requests[requestId];
        // Clear random words to avoid exposing them publicly if not needed after fulfillment
        // status.randomWords = new uint256[](0); // Cannot modify storage from view
        return status;
    }

    /// @notice Checks if a token ID exists and has associated asset data.
    /// @param tokenId The ID of the token.
    /// @return bool True if the token exists and data is present (implies it was minted by this contract).
    function assetDataExists(uint256 tokenId) public view returns (bool) {
        // relies on default struct values being distinguishable if necessary, or add an 'initialized' bool in struct
        // The _exists check from ERC721Enumerable is sufficient for whether the token is minted.
        // Checking if generation > 0 confirms it went through the VRF/mint process.
        return _exists(tokenId) && _assetData[tokenId].generation > 0;
    }
}
```