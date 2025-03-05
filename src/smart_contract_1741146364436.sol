```solidity
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
 * ----------------------------------------------------------------------------
 *                      Dynamic Evolving NFT Contract
 * ----------------------------------------------------------------------------
 *
 * Outline:
 * This contract implements a dynamic NFT that evolves over time and reacts to on-chain randomness.
 * It uses Chainlink VRF v2 for secure randomness to drive NFT evolution stages.
 * The NFT's metadata (URI) changes dynamically based on its evolution stage, which is determined
 * by a combination of time elapsed since minting and random numbers from VRF.
 *
 * Function Summary:
 *
 * **Minting & NFT Basics:**
 * 1. `mintNFT(address _to)`: Mints a new Dynamic NFT to the specified address.
 * 2. `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a given NFT ID.
 * 3. `supportsInterface(bytes4 interfaceId)`:  Standard ERC165 interface support.
 * 4. `transferNFT(address _from, address _to, uint256 _tokenId)`: Allows owner to transfer an NFT.
 * 5. `ownerOfNFT(uint256 _tokenId)`: Returns the owner of a given NFT.
 * 6. `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 7. `getNFTMintTime(uint256 _tokenId)`: Returns the timestamp when an NFT was minted.
 *
 * **Evolution & Randomness:**
 * 8. `requestRandomWords(uint256 _tokenId)`: Initiates a request for random words from Chainlink VRF for a specific NFT.
 * 9. `fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)`: Callback function from Chainlink VRF to process random words and update NFT stage. (Internal, called by VRF Coordinator)
 * 10. `setEvolutionDuration(uint256 _duration)`:  Sets the duration (in seconds) of each evolution stage. (Admin function)
 * 11. `setMaxEvolutionStages(uint8 _stages)`: Sets the maximum number of evolution stages. (Admin function)
 * 12. `getCurrentStage(uint256 _tokenId)`: Calculates and returns the current evolution stage based on time and randomness. (Internal)
 * 13. `getStageDescription(uint256 _tokenId, uint8 _stage)`: Returns a description string for a given stage of an NFT. (Internal, example content generation)
 * 14. `getStageRandomSeed(uint256 _tokenId)`: Returns the random seed associated with the current stage (if applicable).
 *
 * **Configuration & Management:**
 * 15. `setVRFCoordinator(address _vrfCoordinator)`: Sets the Chainlink VRF Coordinator address. (Admin function)
 * 16. `setLinkToken(address _linkToken)`: Sets the Chainlink LINK token address. (Admin function)
 * 17. `setKeyHash(bytes32 _keyHash)`: Sets the Chainlink VRF Key Hash. (Admin function)
 * 18. `setSubscriptionId(uint64 _subscriptionId)`: Sets the Chainlink VRF Subscription ID. (Admin function)
 * 19. `setBaseURI(string memory _baseURI)`: Sets the base URI for NFT metadata. (Admin function)
 * 20. `pauseContract()`: Pauses the contract, preventing minting and evolution updates. (Admin function)
 * 21. `unpauseContract()`: Unpauses the contract. (Admin function)
 * 22. `withdrawLink()`: Allows the contract owner to withdraw LINK tokens from the contract. (Admin function)
 * 23. `getContractBalance()`: Returns the contract's ETH balance. (View function)
 * 24. `getLinkBalance()`: Returns the contract's LINK balance. (View function)
 * 25. `isPaused()`: Returns whether the contract is paused. (View function)
 *
 * **Events:**
 * 26. `NFTMinted(uint256 tokenId, address owner)`: Emitted when a new NFT is minted.
 * 27. `EvolutionStageUpdated(uint256 tokenId, uint8 stage)`: Emitted when an NFT's evolution stage is updated.
 * 28. `RandomWordsRequested(uint256 requestId, uint256 tokenId)`: Emitted when random words are requested for an NFT.
 *
 * **Advanced Concepts Used:**
 * - Dynamic NFT Metadata: `tokenURI` generates metadata on-the-fly based on NFT state.
 * - Time-Based Evolution: NFT stages progress over time since minting.
 * - On-Chain Randomness (Chainlink VRF): Secure and verifiable randomness to influence evolution.
 * - Pausable Contract: Emergency stop mechanism for contract operations.
 * - Admin Roles (Ownable): Controlled access to sensitive functions.
 * - ERC721URIStorage: Standard NFT with metadata storage.
 * - Counters: Safe and efficient token ID management.
 *
 * **Creative & Trendy Aspects:**
 * - Evolving NFT: NFTs are not static, their appearance and properties change over time.
 * - Randomness-Driven Evolution: Unpredictable evolution paths add an element of surprise and uniqueness.
 * - Dynamic Metadata: Metadata isn't fixed at minting, it's generated dynamically, reflecting the NFT's current state.
 * - Potential for Narrative/Storytelling: Evolution stages can be linked to a story or lore, revealed over time.
 */
contract DynamicEvolvingNFT is VRFConsumerBaseV2, Ownable, Pausable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Chainlink VRF Configuration ---
    VRFCoordinatorV2Interface private vrfCoordinator;
    address public linkTokenAddress;
    bytes32 public keyHash;
    uint64 public subscriptionId;
    uint32 public requestConfirmations = 3;
    uint32 public numWords = 1;
    mapping(uint256 => uint256) public requestIdToTokenId; // Map VRF request ID to NFT token ID
    mapping(uint256 => uint256) public stageRandomSeed; // Store random seed for each stage

    // --- NFT Evolution Configuration ---
    uint256 public evolutionDuration = 86400; // 1 day in seconds (default)
    uint8 public maxEvolutionStages = 5; // Maximum number of evolution stages
    mapping(uint256 => uint256) public nftMintTime; // Store mint timestamp for each NFT
    string public baseURI;

    // --- Events ---
    event NFTMinted(uint256 tokenId, address owner);
    event EvolutionStageUpdated(uint256 tokenId, uint8 stage);
    event RandomWordsRequested(uint256 requestId, uint256 tokenId);

    constructor(
        address _vrfCoordinator,
        address _linkTokenAddress,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        string memory _baseURI
    ) VRFConsumerBaseV2(_vrfCoordinator) ERC721("DynamicEvolvingNFT", "DENFT") {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        linkTokenAddress = _linkTokenAddress;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        baseURI = _baseURI;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // ------------------------------------------------------------------------
    //                          Minting & NFT Basics
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic NFT to the specified address.
     * @param _to The address to mint the NFT to.
     */
    function mintNFT(address _to) external onlyOwner whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);
        nftMintTime[tokenId] = block.timestamp;
        emit NFTMinted(tokenId, _to);
    }

    /**
     * @dev Returns the dynamic metadata URI for a given NFT ID.
     * The URI is generated based on the NFT's current evolution stage.
     * @param tokenId The ID of the NFT.
     * @return The metadata URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        uint8 currentStage = getCurrentStage(tokenId);
        string memory stageDescription = getStageDescription(tokenId, currentStage);

        string memory metadata = string(abi.encodePacked(
            '{"name": "Dynamic Evolving NFT #', Strings.toString(tokenId), '",',
            '"description": "', stageDescription, '",',
            '"image": "', baseURI, Strings.toString(currentStage), '.png",', // Example: baseURI/1.png, baseURI/2.png, etc.
            '"attributes": [{"trait_type": "Evolution Stage", "value": ', Strings.toString(currentStage), '}]',
            '}'
        ));

        string memory jsonBase64 = Base64.encode(bytes(metadata));
        return string(abi.encodePacked('data:application/json;base64,', jsonBase64));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Allows the contract owner to transfer an NFT.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) external onlyOwner {
        safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the owner of a given NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the NFT owner.
     */
    function ownerOfNFT(uint256 _tokenId) external view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage (uint8).
     */
    function getNFTStage(uint256 _tokenId) external view returns (uint8) {
        return getCurrentStage(_tokenId);
    }

    /**
     * @dev Returns the timestamp when an NFT was minted.
     * @param _tokenId The ID of the NFT.
     * @return The mint timestamp (uint256).
     */
    function getNFTMintTime(uint256 _tokenId) external view returns (uint256) {
        return nftMintTime[_tokenId];
    }


    // ------------------------------------------------------------------------
    //                        Evolution & Randomness
    // ------------------------------------------------------------------------

    /**
     * @dev Initiates a request for random words from Chainlink VRF for a specific NFT.
     * This function can be called periodically or based on triggers to update the NFT's stage.
     * @param _tokenId The ID of the NFT to request randomness for.
     */
    function requestRandomWords(uint256 _tokenId) public whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender || owner() == msg.sender, "Only owner or contract owner can request refresh");

        uint256 requestId = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            numWords
        );
        requestIdToTokenId[requestId] = _tokenId;
        emit RandomWordsRequested(requestId, _tokenId);
    }

    /**
     * @dev Chainlink VRF callback function to process random words and update NFT stage.
     * @param _requestId The request ID associated with the random words.
     * @param _randomWords An array of random words generated by Chainlink VRF.
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 tokenId = requestIdToTokenId[_requestId];
        require(_exists(tokenId), "NFT does not exist for requestId");

        uint8 currentStage = getCurrentStage(tokenId);
        uint8 nextStage = currentStage;

        if (currentStage < maxEvolutionStages) {
            // Example logic: Advance stage based on randomness
            uint256 randomValue = _randomWords[0] % 100; // Example: Random value between 0 and 99
            if (randomValue > 50) { // 50% chance to evolve (example logic, can be more complex)
                nextStage = currentStage + 1;
                stageRandomSeed[tokenId] = _randomWords[0]; // Store the random seed for this stage
            }
        }

        if (nextStage > currentStage) {
            // Evolution happened
            emit EvolutionStageUpdated(tokenId, nextStage);
        }
        // Even if stage didn't change due to randomness, we might still update based on time in `getCurrentStage` if time elapsed
    }

    /**
     * @dev Sets the duration (in seconds) of each evolution stage.
     * @param _duration The duration in seconds.
     */
    function setEvolutionDuration(uint256 _duration) external onlyOwner {
        evolutionDuration = _duration;
    }

    /**
     * @dev Sets the maximum number of evolution stages.
     * @param _stages The maximum number of stages.
     */
    function setMaxEvolutionStages(uint8 _stages) external onlyOwner {
        maxEvolutionStages = _stages;
    }

    /**
     * @dev Calculates and returns the current evolution stage based on time and randomness.
     * @param _tokenId The ID of the NFT.
     * @return The current evolution stage (uint8).
     */
    function getCurrentStage(uint256 _tokenId) public view returns (uint8) {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 timeElapsed = block.timestamp - nftMintTime[_tokenId];
        uint8 stage = uint8(timeElapsed / evolutionDuration) + 1; // Stage 1 starts after minting

        if (stage > maxEvolutionStages) {
            return maxEvolutionStages; // Cap at max stages
        }
        return stage;
    }

    /**
     * @dev Returns a description string for a given stage of an NFT.
     * This is an example function to generate dynamic content based on stage.
     * You can customize this to return different descriptions, images, etc.
     * @param _tokenId The ID of the NFT.
     * @param _stage The evolution stage.
     * @return The description string for the stage.
     */
    function getStageDescription(uint256 _tokenId, uint8 _stage) internal view returns (string memory) {
        // Example stage descriptions - customize these based on your NFT's lore/design
        if (_stage == 1) {
            return "Emerging form, nascent potential.";
        } else if (_stage == 2) {
            return "Awakening, senses sharpening.";
        } else if (_stage == 3) {
            return "Growing strength, adapting to its environment.";
        } else if (_stage == 4) {
            return "Approaching maturity, powers coalescing.";
        } else if (_stage == 5) {
            return "Fully evolved, realizing its destiny.";
        } else {
            return "Beyond evolution, in its final form."; // Stage beyond maxStages
        }
    }

    /**
     * @dev Returns the random seed associated with the current stage (if applicable).
     * @param _tokenId The ID of the NFT.
     * @return The random seed (uint256) or 0 if no seed is associated.
     */
    function getStageRandomSeed(uint256 _tokenId) external view returns (uint256) {
        return stageRandomSeed[_tokenId];
    }

    // ------------------------------------------------------------------------
    //                      Configuration & Management
    // ------------------------------------------------------------------------

    /**
     * @dev Sets the Chainlink VRF Coordinator address.
     * @param _vrfCoordinator The address of the VRF Coordinator.
     */
    function setVRFCoordinator(address _vrfCoordinator) external onlyOwner {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator); // For VRFConsumerBaseV2
    }

    /**
     * @dev Sets the Chainlink LINK token address.
     * @param _linkToken The address of the LINK token.
     */
    function setLinkToken(address _linkToken) external onlyOwner {
        linkTokenAddress = _linkToken;
        s_link = _linkToken; // For VRFConsumerBaseV2
    }

    /**
     * @dev Sets the Chainlink VRF Key Hash.
     * @param _keyHash The Key Hash for VRF requests.
     */
    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @dev Sets the Chainlink VRF Subscription ID.
     * @param _subscriptionId The Subscription ID for VRF requests.
     */
    function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
        subscriptionId = _subscriptionId;
    }

    /**
     * @dev Sets the base URI for NFT metadata.
     * @param _baseURI The base URI string.
     */
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @dev Pauses the contract, preventing minting and evolution updates.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, resuming normal operations.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw LINK tokens from the contract.
     */
    function withdrawLink() external onlyOwner {
        // Get the LINK token contract
        IERC20 linkToken = IERC20(linkTokenAddress);
        uint256 contractLinkBalance = linkToken.balanceOf(address(this));
        require(contractLinkBalance > 0, "Contract has no LINK balance to withdraw");
        bool success = linkToken.transfer(owner(), contractLinkBalance);
        require(success, "LINK withdrawal failed");
    }

    /**
     * @dev Returns the contract's ETH balance.
     * @return The contract's ETH balance in wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the contract's LINK balance.
     * @return The contract's LINK balance in wei.
     */
    function getLinkBalance() external view returns (uint256) {
        IERC20 linkToken = IERC20(linkTokenAddress);
        return linkToken.balanceOf(address(this));
    }

    /**
     * @dev Returns whether the contract is paused.
     * @return True if paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused();
    }

    // --- Base64 Encoding Library (from OpenZeppelin Contracts - modified for Solidity 0.8) ---
    // (Included here for self-contained contract, in a real project, consider importing a library or using a more robust solution)

    string internal constant _alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = _alphabet;

        // multiply by 3/4 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end in case we need to pad with '='
        string memory result = new string(encodedLen + 2);

        assembly {
            let dataLen := mload(data)
            let dataPtr := add(data, 0x20)
            let endPtr := add(dataPtr, dataLen)

            // Operate on data as long as there are at least 3 bytes left.
            // When there are less, pad with zeroes.
            for { let resultPtr := add(result, 0x20) } 1 { } {
                // keccak256("loop")
                if iszero(lt(dataPtr, endPtr)) { break }

                // slither-disable-next-line assembly-access
                let d := mload(dataPtr)
                // slither-disable-next-line assembly-access
                let d1 := mload(add(dataPtr, 1))
                // slither-disable-next-line assembly-access
                let d2 := mload(add(dataPtr, 2))

                // slither-disable-next-line assembly-access
                mstore8(resultPtr, byte(div(d, 0x400000), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 1), byte(mod(div(d, 0x1000), 0x40), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 2), byte(mod(div(d1, 0x400000), 0x40), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 3), byte(mod(div(d1, 0x1000), 0x40), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 4), byte(mod(div(d2, 0x400000), 0x40), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 5), byte(mod(div(d2, 0x1000), 0x40), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 6), byte(mod(d, 0x40), table))
                // slither-disable-next-line assembly-access
                mstore8(add(resultPtr, 7), byte(mod(d1, 0x40), table))

                dataPtr := add(dataPtr, 3)
                resultPtr := add(resultPtr, 4)
            }

            // Deal with the last chunk of data
            {
                let dataLeft := sub(endPtr, dataPtr)

                if eq(dataLeft, 1) {
                    // slither-disable-next-line assembly-access
                    let d := mload(dataPtr)

                    // slither-disable-next-line assembly-access
                    mstore8(add(result, encodedLen), byte(div(d, 0x400000), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 1)), byte(mod(div(d, 0x1000), 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 2)), byte(mod(d, 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 3)), byte(0x3d, table))
                }

                if eq(dataLeft, 2) {
                    // slither-disable-next-line assembly-access
                    let d := mload(dataPtr)
                    // slither-disable-next-line assembly-access
                    let d1 := mload(add(dataPtr, 1))

                    // slither-disable-next-line assembly-access
                    mstore8(add(result, encodedLen), byte(div(d, 0x400000), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 1)), byte(mod(div(d, 0x1000), 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 2)), byte(mod(div(d1, 0x400000), 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 3)), byte(mod(d1, 0x1000), 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 4)), byte(mod(d, 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 5)), byte(mod(d1, 0x40), table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 6)), byte(0x3d, table))
                    // slither-disable-next-line assembly-access
                    mstore8(add(result, add(encodedLen, 7)), byte(0x3d, table))
                }
            }
        }

        return result;
    }
}

// --- Interface for IERC20 (for LINK token) ---
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
```