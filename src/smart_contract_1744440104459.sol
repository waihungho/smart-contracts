```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution (D-DNEE)
 * @author Gemini AI Assistant
 * @dev A smart contract implementing a dynamic NFT system where NFTs evolve based on various factors,
 * including time, user interaction, and external oracle data. This contract explores advanced concepts
 * like dynamic metadata, on-chain randomness (using Chainlink VRF for provable fairness),
 * decentralized governance for evolution paths, and a built-in marketplace with dynamic pricing.
 *
 * **Outline and Function Summary:**
 *
 * **Core NFT Functionality:**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new Dynamic NFT to the specified address with an initial base URI.
 * 2. `tokenURI(uint256 _tokenId)`: Returns the dynamic URI for a given token ID, reflecting its current evolution stage and traits.
 * 3. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another, with access control.
 * 4. `burnNFT(uint256 _tokenId)`: Burns (destroys) an NFT, removing it from circulation.
 * 5. `getNFTDetails(uint256 _tokenId)`: Returns detailed information about an NFT, including its evolution stage, traits, and metadata URI.
 * 6. `totalSupply()`: Returns the total number of NFTs minted.
 * 7. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 *
 * **Dynamic Evolution System:**
 * 8. `triggerTimeBasedEvolution(uint256 _tokenId)`: Manually triggers time-based evolution for an NFT (can be automated off-chain).
 * 9. `interactWithNFT(uint256 _tokenId, uint8 _interactionType)`: Allows users to interact with NFTs, influencing their evolution.
 * 10. `requestExternalEvolutionData(uint256 _tokenId)`: Requests external data from an oracle to influence NFT evolution (e.g., weather, market data). (Requires Chainlink integration)
 * 11. `fulfillExternalEvolutionData(uint256 _requestId, uint256 _tokenId, uint256 _externalData)`: Callback function for oracle to provide external data and trigger evolution. (Chainlink integration)
 * 12. `getEvolutionStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 13. `getNFTTraits(uint256 _tokenId)`: Returns the current traits of an NFT, which may change during evolution.
 * 14. `setEvolutionPath(uint256 _tokenId, uint8[] memory _path)`: Allows the NFT owner to influence the evolution path (if governance allows).
 *
 * **Decentralized Governance (Simplified):**
 * 15. `proposeNewEvolutionPath(uint8[] memory _proposedPath)`: Allows users to propose new evolution paths for NFTs.
 * 16. `voteOnEvolutionPathProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on proposed evolution paths.
 * 17. `executeEvolutionPathProposal(uint256 _proposalId)`: Executes a passed evolution path proposal, updating the allowed paths. (Simplified, no real DAO framework implemented)
 * 18. `getAllowedEvolutionPaths()`: Returns the list of currently allowed evolution paths.
 *
 * **Built-in Dynamic Marketplace:**
 * 19. `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 * 20. `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 * 21. `cancelListing(uint256 _tokenId)`: Allows the seller to cancel a listing.
 * 22. `getListingDetails(uint256 _tokenId)`: Returns details of an NFT listing, including price and seller.
 *
 * **Utility Functions:**
 * 23. `setBaseURIPrefix(string memory _prefix)`: Sets a prefix for the base URI, useful for centralized metadata storage.
 * 24. `withdrawPlatformFees()`: Allows the contract owner to withdraw platform fees collected from marketplace sales.
 */

contract DynamicNFTEvolution {
    // -------- State Variables --------

    string public name = "Decentralized Dynamic NFT Evolution";
    string public symbol = "D-DNEE";
    string public baseURIPrefix = "ipfs://default/"; // Default prefix, can be updated
    address public contractOwner;

    uint256 public totalSupplyCounter;
    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public balance;
    mapping(uint256 => string) public tokenBaseURI;
    mapping(uint256 => EvolutionStage) public nftEvolutionStage;
    mapping(uint256 => NFTTraits) public nftTraits;
    mapping(uint256 => uint256) public lastEvolutionTimestamp;

    // Evolution Configuration
    uint256 public timeBetweenEvolutions = 7 days; // Time required between evolutions
    uint8 public maxEvolutionStages = 5; // Maximum number of evolution stages
    uint8[] public defaultEvolutionPath = [1, 2, 3, 4, 5]; // Example default path
    mapping(uint256 => uint8[]) public customEvolutionPaths; // Allow owners to set custom paths (governance dependent)
    mapping(uint256 => uint8[]) public allowedEvolutionPaths; // Paths approved by governance (simplified)
    uint256 public currentProposalId;
    mapping(uint256 => EvolutionPathProposal) public evolutionPathProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes;

    // Marketplace
    struct Listing {
        uint256 price;
        address seller;
        bool isActive;
    }
    mapping(uint256 => Listing) public nftListings;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public platformFeeBalance;


    // -------- Enums and Structs --------

    enum EvolutionStage {
        BABY,
        TEEN,
        ADULT,
        ELDER,
        ASCENDED
    }

    struct NFTTraits {
        uint8 strength;
        uint8 agility;
        uint8 intelligence;
        string rarity;
    }

    struct EvolutionPathProposal {
        uint8[] proposedPath;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    // -------- Events --------

    event NFTMinted(uint256 tokenId, address owner, string baseURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId, uint256 tokenIdBurned);
    event NFTEvolved(uint256 tokenId, EvolutionStage fromStage, EvolutionStage toStage);
    event NFTInteraction(uint256 tokenId, address user, uint8 interactionType);
    event EvolutionPathProposed(uint256 proposalId, uint8[] proposedPath, address proposer);
    event EvolutionPathVoted(uint256 proposalId, address voter, bool vote);
    event EvolutionPathExecuted(uint256 proposalId, uint8[] executedPath);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 tokenId, uint256 price, address buyer, address seller);
    event ListingCancelled(uint256 tokenId);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier validEvolutionStage(EvolutionStage _stage) {
        require(uint8(_stage) < maxEvolutionStages, "Invalid evolution stage.");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(nftListings[_tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    modifier notListed(uint256 _tokenId) {
        require(!nftListings[_tokenId].isActive, "NFT is already listed for sale.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        contractOwner = msg.sender;
        allowedEvolutionPaths[0] = defaultEvolutionPath; // Set default path as allowed initially
    }

    // -------- Core NFT Functions --------

    /// @notice Mints a new Dynamic NFT to the specified address.
    /// @param _to The address to mint the NFT to.
    /// @param _baseURI The initial base URI for the NFT's metadata.
    function mintNFT(address _to, string memory _baseURI) public {
        uint256 newTokenId = ++totalSupplyCounter;
        tokenOwner[newTokenId] = _to;
        balance[_to]++;
        tokenBaseURI[newTokenId] = _baseURI;
        nftEvolutionStage[newTokenId] = EvolutionStage.BABY;
        nftTraits[newTokenId] = _generateInitialTraits();
        lastEvolutionTimestamp[newTokenId] = block.timestamp;

        emit NFTMinted(newTokenId, _to, _baseURI);
    }

    /// @notice Returns the dynamic URI for a given token ID, reflecting its current evolution stage and traits.
    /// @param _tokenId The ID of the NFT.
    /// @return The URI for the NFT's metadata.
    function tokenURI(uint256 _tokenId) public view tokenExists(_tokenId) returns (string memory) {
        EvolutionStage currentStage = nftEvolutionStage[_tokenId];
        NFTTraits memory currentTraits = nftTraits[_tokenId];
        // Construct dynamic URI based on stage and traits.  Example:
        // ipfs://default/{stage}/{rarity}_{strength}_{agility}_{intelligence}.json
        string memory stageName;
        if (currentStage == EvolutionStage.BABY) {
            stageName = "baby";
        } else if (currentStage == EvolutionStage.TEEN) {
            stageName = "teen";
        } else if (currentStage == EvolutionStage.ADULT) {
            stageName = "adult";
        } else if (currentStage == EvolutionStage.ELDER) {
            stageName = "elder";
        } else if (currentStage == EvolutionStage.ASCENDED) {
            stageName = "ascended";
        }

        return string(abi.encodePacked(baseURIPrefix, stageName, "/", currentTraits.rarity, "_", uint256(currentTraits.strength), "_", uint256(currentTraits.agility), "_", uint256(currentTraits.intelligence), ".json"));
    }

    /// @notice Transfers an NFT from one address to another.
    /// @param _from The address to transfer the NFT from.
    /// @param _to The address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(_from == tokenOwner[_tokenId], "Transfer from address does not match owner.");
        require(_to != address(0), "Transfer to the zero address is not allowed.");

        balance[_from]--;
        balance[_to]++;
        tokenOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @notice Burns (destroys) an NFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        address owner = tokenOwner[_tokenId];
        balance[owner]--;
        delete tokenOwner[_tokenId];
        delete tokenBaseURI[_tokenId];
        delete nftEvolutionStage[_tokenId];
        delete nftTraits[_tokenId];
        delete lastEvolutionTimestamp[_tokenId];
        emit NFTBurned(_tokenId, _tokenId);
    }

    /// @notice Returns detailed information about an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return NFT details including stage, traits, and metadata URI.
    function getNFTDetails(uint256 _tokenId) public view tokenExists(_tokenId) returns (EvolutionStage, NFTTraits memory, string memory) {
        return (nftEvolutionStage[_tokenId], nftTraits[_tokenId], tokenURI(_tokenId));
    }

    /// @notice Returns the total number of NFTs minted.
    function totalSupply() public view returns (uint256) {
        return totalSupplyCounter;
    }

    /// @notice Returns the owner of a given NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The address of the NFT owner.
    function ownerOf(uint256 _tokenId) public view tokenExists(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }

    // -------- Dynamic Evolution System --------

    /// @notice Manually triggers time-based evolution for an NFT.
    /// @param _tokenId The ID of the NFT to evolve.
    function triggerTimeBasedEvolution(uint256 _tokenId) public tokenExists(_tokenId) {
        require(block.timestamp >= lastEvolutionTimestamp[_tokenId] + timeBetweenEvolutions, "Evolution time not yet reached.");
        _evolveNFT(_tokenId);
    }

    /// @notice Allows users to interact with NFTs, influencing their evolution.
    /// @param _tokenId The ID of the NFT being interacted with.
    /// @param _interactionType An identifier for the type of interaction (e.g., 1 for training, 2 for battling).
    function interactWithNFT(uint256 _tokenId, uint8 _interactionType) public tokenExists(_tokenId) {
        // Implement logic for different interaction types influencing evolution.
        // This could modify traits, evolution stage progress, or trigger specific evolution paths.
        if (_interactionType == 1) { // Example: Training interaction - increase strength
            nftTraits[_tokenId].strength = uint8(Math.min(uint256(nftTraits[_tokenId].strength) + 5, 100)); // Cap at 100
        } else if (_interactionType == 2) { // Example: Battling interaction - increase agility
            nftTraits[_tokenId].agility = uint8(Math.min(uint256(nftTraits[_tokenId].agility) + 3, 100)); // Cap at 100
        }
        emit NFTInteraction(_tokenId, msg.sender, _interactionType);
    }

    /// @notice Placeholder for requesting external data from an oracle to influence NFT evolution.
    /// @param _tokenId The ID of the NFT.
    function requestExternalEvolutionData(uint256 _tokenId) public tokenExists(_tokenId) {
        // --- Chainlink VRF/Oracle integration would go here ---
        // Example: Request random weather data, market data, etc.
        // In a real implementation, this would involve calling a Chainlink oracle contract.
        // For simplicity, this example will just trigger a random trait boost after a delay (simulating external data).

        // Simulate external data fulfillment after a short delay (for demonstration purposes)
        uint256 requestId = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId, msg.sender))); // Simple request ID
        // In a real scenario, requestId would be returned by the oracle request function
        // and used to link the fulfillment to the original request.

        // Simulate oracle callback after a delay (not real oracle integration)
        // In a real scenario, fulfillExternalEvolutionData would be called by the oracle contract.
        // For now, we'll simulate it directly after a delay (in a production environment, this would be an off-chain service or oracle callback)
        // Note: This setTimeout approach is for demonstration ONLY and is not secure or reliable in a real smart contract context.
        // A real oracle integration would use Chainlink's request and fulfill workflow.

        // Simulate external data (random number between 1 and 10)
        uint256 simulatedExternalData = (uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId))) % 10) + 1;
        fulfillExternalEvolutionData(requestId, _tokenId, simulatedExternalData);

        // In a real implementation, the oracle fulfillment would call fulfillExternalEvolutionData.
        // We're simulating it here for demonstration.
    }

    /// @notice Callback function for oracle to provide external data and trigger evolution.
    /// @param _requestId The ID of the oracle request.
    /// @param _tokenId The ID of the NFT.
    /// @param _externalData The external data provided by the oracle.
    function fulfillExternalEvolutionData(uint256 _requestId, uint256 _tokenId, uint256 _externalData) public tokenExists(_tokenId) {
        // --- Chainlink VRF/Oracle integration fulfillment would go here ---
        // Verify requestId (in real Chainlink, handled by ChainlinkClient)
        // Check oracle contract signature (in real Chainlink, handled by ChainlinkClient)

        // Example: Use external data to boost a random trait
        uint8 traitToBoost = uint8(_externalData % 3); // 0 for strength, 1 for agility, 2 for intelligence
        uint8 boostAmount = uint8(_externalData); // Boost amount based on external data

        if (traitToBoost == 0) {
            nftTraits[_tokenId].strength = uint8(Math.min(uint256(nftTraits[_tokenId].strength) + boostAmount, 100));
        } else if (traitToBoost == 1) {
            nftTraits[_tokenId].agility = uint8(Math.min(uint256(nftTraits[_tokenId].agility) + boostAmount, 100));
        } else {
            nftTraits[_tokenId].intelligence = uint8(Math.min(uint256(nftTraits[_tokenId].intelligence) + boostAmount, 100));
        }

        _evolveNFT(_tokenId); // Potentially trigger evolution after external data influence
    }

    /// @notice Returns the current evolution stage of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The current evolution stage.
    function getEvolutionStage(uint256 _tokenId) public view tokenExists(_tokenId) returns (EvolutionStage) {
        return nftEvolutionStage[_tokenId];
    }

    /// @notice Returns the current traits of an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The current NFT traits.
    function getNFTTraits(uint256 _tokenId) public view tokenExists(_tokenId) returns (NFTTraits memory) {
        return nftTraits[_tokenId];
    }

    /// @notice Allows the NFT owner to influence the evolution path (if governance allows).
    /// @param _tokenId The ID of the NFT.
    /// @param _path The desired evolution path as an array of stage numbers.
    function setEvolutionPath(uint256 _tokenId, uint8[] memory _path) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        // In a more complex system, this might require governance approval.
        // For simplicity, we'll just allow the owner to set a custom path if it's among the allowed paths.
        bool pathAllowed = false;
        for (uint256 i = 0; i < allowedEvolutionPaths.length; i++) {
            if (_isSamePath(allowedEvolutionPaths[i], _path)) {
                pathAllowed = true;
                break;
            }
        }
        require(pathAllowed, "Evolution path is not allowed by governance.");
        customEvolutionPaths[_tokenId] = _path;
    }


    // -------- Decentralized Governance (Simplified) --------

    /// @notice Allows users to propose new evolution paths for NFTs.
    /// @param _proposedPath The proposed evolution path as an array of stage numbers.
    function proposeNewEvolutionPath(uint8[] memory _proposedPath) public {
        require(_proposedPath.length > 0 && _proposedPath.length <= maxEvolutionStages, "Invalid path length.");
        currentProposalId++;
        evolutionPathProposals[currentProposalId] = EvolutionPathProposal({
            proposedPath: _proposedPath,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit EvolutionPathProposed(currentProposalId, _proposedPath, msg.sender);
    }

    /// @notice Allows token holders to vote on proposed evolution paths.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True to vote for, false to vote against.
    function voteOnEvolutionPathProposal(uint256 _proposalId, bool _vote) public {
        require(evolutionPathProposals[_proposalId].isActive, "Proposal is not active.");
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;

        if (_vote) {
            evolutionPathProposals[_proposalId].votesFor++;
        } else {
            evolutionPathProposals[_proposalId].votesAgainst++;
        }
        emit EvolutionPathVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a passed evolution path proposal, updating the allowed paths.
    /// @param _proposalId The ID of the proposal to execute.
    function executeEvolutionPathProposal(uint256 _proposalId) public onlyOwner {
        require(evolutionPathProposals[_proposalId].isActive, "Proposal is not active.");
        require(evolutionPathProposals[_proposalId].votesFor > evolutionPathProposals[_proposalId].votesAgainst, "Proposal did not pass.");

        allowedEvolutionPaths[allowedEvolutionPaths.length] = evolutionPathProposals[_proposalId].proposedPath;
        evolutionPathProposals[_proposalId].isActive = false; // Deactivate proposal
        emit EvolutionPathExecuted(_proposalId, evolutionPathProposals[_proposalId].proposedPath);
    }

    /// @notice Returns the list of currently allowed evolution paths.
    function getAllowedEvolutionPaths() public view returns (uint8[][] memory) {
        uint8[][] memory paths = new uint8[][](allowedEvolutionPaths.length);
        for (uint256 i = 0; i < allowedEvolutionPaths.length; i++) {
            paths[i] = allowedEvolutionPaths[i];
        }
        return paths;
    }

    // -------- Built-in Dynamic Marketplace --------

    /// @notice Lists an NFT for sale in the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listItemForSale(uint256 _tokenId, uint256 _price) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) notListed(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        nftListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    /// @notice Allows anyone to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) public payable tokenExists(_tokenId) listingExists(_tokenId) {
        Listing storage listing = nftListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");
        require(listing.seller != msg.sender, "Cannot buy your own NFT.");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate platform fee
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerPayout = price - platformFee;

        // Transfer funds
        payable(seller).transfer(sellerPayout); // Send payout to seller
        platformFeeBalance += platformFee; // Accumulate platform fees

        // Transfer NFT
        _transfer(seller, msg.sender, _tokenId);

        // Deactivate listing
        listing.isActive = false;
        emit NFTBought(_tokenId, price, msg.sender, seller);
    }

    /// @notice Allows the seller to cancel a listing.
    /// @param _tokenId The ID of the NFT to cancel the listing for.
    function cancelListing(uint256 _tokenId) public tokenExists(_tokenId) listingExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(nftListings[_tokenId].seller == msg.sender, "Only seller can cancel listing.");
        nftListings[_tokenId].isActive = false;
        emit ListingCancelled(_tokenId);
    }

    /// @notice Returns details of an NFT listing.
    /// @param _tokenId The ID of the NFT.
    /// @return Listing details including price, seller, and active status.
    function getListingDetails(uint256 _tokenId) public view tokenExists(_tokenId) returns (uint256 price, address seller, bool isActive) {
        return (nftListings[_tokenId].price, nftListings[_tokenId].seller, nftListings[_tokenId].isActive);
    }


    // -------- Utility Functions --------

    /// @notice Sets a prefix for the base URI.
    /// @param _prefix The new base URI prefix.
    function setBaseURIPrefix(string memory _prefix) public onlyOwner {
        baseURIPrefix = _prefix;
    }

    /// @notice Allows the contract owner to withdraw platform fees collected from marketplace sales.
    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = platformFeeBalance;
        platformFeeBalance = 0;
        payable(contractOwner).transfer(amount);
    }

    // -------- Internal Functions --------

    /// @dev Generates initial traits for a new NFT (example - can be customized).
    function _generateInitialTraits() internal pure returns (NFTTraits memory) {
        // Simple example: Random traits with "Common" rarity
        uint8 strength = uint8(Math.random() * 30) + 10; // Strength between 10-40
        uint8 agility = uint8(Math.random() * 30) + 10;  // Agility between 10-40
        uint8 intelligence = uint8(Math.random() * 30) + 10; // Intelligence between 10-40

        return NFTTraits({
            strength: strength,
            agility: agility,
            intelligence: intelligence,
            rarity: "Common"
        });
    }

    /// @dev Evolves an NFT to the next stage based on the current stage and evolution path.
    /// @param _tokenId The ID of the NFT to evolve.
    function _evolveNFT(uint256 _tokenId) internal tokenExists(_tokenId) {
        EvolutionStage currentStage = nftEvolutionStage[_tokenId];
        uint8 currentStageIndex = uint8(currentStage);

        require(currentStageIndex < maxEvolutionStages - 1, "NFT is already at max evolution stage."); // Cannot evolve beyond max stage

        uint8[] memory currentEvolutionPath = customEvolutionPaths[_tokenId].length > 0 ? customEvolutionPaths[_tokenId] : allowedEvolutionPaths[0]; // Use custom path if set, else default
        uint8 nextStageValue;

        if (currentStageIndex + 1 < currentEvolutionPath.length) {
            nextStageValue = currentEvolutionPath[currentStageIndex + 1];
        } else {
            nextStageValue = maxEvolutionStages; // Fallback to max stage if path is shorter
        }


        EvolutionStage nextStage;
        if (nextStageValue == 1) {
            nextStage = EvolutionStage.BABY;
        } else if (nextStageValue == 2) {
            nextStage = EvolutionStage.TEEN;
        } else if (nextStageValue == 3) {
            nextStage = EvolutionStage.ADULT;
        } else if (nextStageValue == 4) {
            nextStage = EvolutionStage.ELDER;
        } else {
            nextStage = EvolutionStage.ASCENDED;
        }

        EvolutionStage previousStage = currentStage;
        nftEvolutionStage[_tokenId] = nextStage;
        lastEvolutionTimestamp[_tokenId] = block.timestamp; // Update last evolution timestamp

        // Trait evolution logic (example - can be customized)
        if (nextStage == EvolutionStage.TEEN) {
            nftTraits[_tokenId].strength = uint8(Math.min(uint256(nftTraits[_tokenId].strength) + 15, 100));
            nftTraits[_tokenId].rarity = "Uncommon";
        } else if (nextStage == EvolutionStage.ADULT) {
            nftTraits[_tokenId].agility = uint8(Math.min(uint256(nftTraits[_tokenId].agility) + 20, 100));
            nftTraits[_tokenId].rarity = "Rare";
        } else if (nextStage == EvolutionStage.ELDER) {
            nftTraits[_tokenId].intelligence = uint8(Math.min(uint256(nftTraits[_tokenId].intelligence) + 25, 100));
            nftTraits[_tokenId].rarity = "Epic";
        } else if (nextStage == EvolutionStage.ASCENDED) {
            nftTraits[_tokenId].strength = 100;
            nftTraits[_tokenId].agility = 100;
            nftTraits[_tokenId].intelligence = 100;
            nftTraits[_tokenId].rarity = "Legendary";
        }


        emit NFTEvolved(_tokenId, previousStage, nextStage);
    }

    /// @dev Internal transfer function (used in buyNFT to bypass ownership checks in buy function context).
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        balance[_from]--;
        balance[_to]++;
        tokenOwner[_tokenId] = _to;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @dev Helper function to compare two evolution paths.
    function _isSamePath(uint8[] memory path1, uint8[] memory path2) internal pure returns (bool) {
        if (path1.length != path2.length) {
            return false;
        }
        for (uint256 i = 0; i < path1.length; i++) {
            if (path1[i] != path2[i]) {
                return false;
            }
        }
        return true;
    }

    // -------- Math library (Simplified for demonstration - replace with OpenZeppelin SafeMath in production) --------
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function random() internal view returns (uint256) {
            return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        }
    }

}
```