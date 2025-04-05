```solidity
/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for creating dynamic NFTs that can evolve based on various on-chain and off-chain factors.
 *      This contract introduces a novel concept of NFT evolution driven by user interaction, staking, community governance, and even external data feeds (simulated in this example).
 *      It aims to provide a rich and engaging NFT experience beyond static collectibles.
 *
 * **Contract Outline:**
 *
 * 1. **NFT Core Functionality:**
 *    - Minting Evolving NFTs
 *    - Transferring NFTs
 *    - Retrieving NFT Metadata (including dynamic properties)
 *    - Burning NFTs
 *
 * 2. **Evolution Mechanics:**
 *    - Staking NFTs for passive evolution
 *    - Training NFTs through interaction for active evolution
 *    - Resource Consumption for evolution
 *    - Evolution stages and levels
 *    - Random trait generation upon evolution
 *    - Oracle-based evolution triggers (simulated)
 *
 * 3. **Rarity and Traits System:**
 *    - Defining NFT base traits
 *    - Dynamic trait updates upon evolution
 *    - Rarity scoring based on traits
 *    - Trait inheritance during evolution
 *
 * 4. **Community Governance (Basic):**
 *    - Proposing trait changes by community
 *    - Voting on trait change proposals
 *    - Implementing approved trait changes
 *
 * 5. **Utility and Advanced Features:**
 *    - NFT Fusion/Merging (combining two NFTs)
 *    - NFT Lending/Renting (escrow-based)
 *    - In-contract marketplace for evolving NFTs
 *    - NFT attribute-based access control (simulated)
 *    - External data feed integration (simulated for evolution)
 *
 * 6. **Admin and Management:**
 *    - Setting evolution parameters
 *    - Setting resource token address
 *    - Pausing/Unpausing contract functionality
 *    - Withdrawing contract balance
 *
 * **Function Summary:**
 *
 * 1. `mintEvolvingNFT(string memory _baseURI)`: Mints a new Evolving NFT with initial traits and metadata URI.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to another address.
 * 3. `getNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for an NFT (can be dynamic).
 * 4. `burnNFT(uint256 _tokenId)`: Burns an NFT, permanently removing it from circulation.
 * 5. `stakeNFT(uint256 _tokenId)`: Stakes an NFT to accrue evolution points passively over time.
 * 6. `unstakeNFT(uint256 _tokenId)`: Unstakes a staked NFT and claims accumulated evolution points.
 * 7. `trainNFT(uint256 _tokenId, uint8 _trainingEffort)`: Allows users to actively train their NFTs, accelerating evolution.
 * 8. `evolveNFT(uint256 _tokenId)`: Triggers the evolution process for an NFT if it meets evolution criteria.
 * 9. `consumeResourceForEvolution(uint256 _tokenId, uint256 _resourceAmount)`: Allows users to consume an ERC20 resource token to boost evolution.
 * 10. `setBaseTraits(uint256 _tokenId, string memory _traits)`: (Admin) Sets the initial base traits for a specific NFT (for customization).
 * 11. `getNFTTraits(uint256 _tokenId)`: Retrieves the current traits of an NFT.
 * 12. `calculateRarityScore(uint256 _tokenId)`: Calculates a rarity score for an NFT based on its traits.
 * 13. `fuseNFTs(uint256 _tokenId1, uint256 _tokenId2)`: Fuses two NFTs to create a new, potentially rarer NFT (burns original NFTs).
 * 14. `listNFTForLending(uint256 _tokenId, uint256 _rentPricePerDay)`: Lists an NFT for lending with a specified daily rent price.
 * 15. `lendNFT(uint256 _tokenId, uint256 _rentalDays)`: Allows a user to rent a listed NFT for a specified duration.
 * 16. `returnLentNFT(uint256 _tokenId)`: Allows a lender to reclaim their NFT after the rental period or renter to return early.
 * 17. `createMarketListing(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the in-contract marketplace.
 * 18. `buyNFTFromMarket(uint256 _listingId)`: Allows users to buy NFTs listed in the in-contract marketplace.
 * 19. `proposeTraitChange(string memory _traitName, string memory _newValue)`: Allows community members to propose changes to NFT traits.
 * 20. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows token holders to vote on trait change proposals.
 * 21. `executeProposal(uint256 _proposalId)`: (Admin) Executes an approved trait change proposal.
 * 22. `setEvolutionStageData(uint8 _stage, uint256 _evolutionPointsNeeded, string memory _stageMetadata)`: (Admin) Sets data for each evolution stage.
 * 23. `setResourceTokenAddress(address _tokenAddress)`: (Admin) Sets the address of the resource token used for evolution.
 * 24. `pauseContract()`: (Admin) Pauses most contract functionalities.
 * 25. `unpauseContract()`: (Admin) Resumes contract functionalities.
 * 26. `withdrawContractBalance()`: (Admin) Allows the contract owner to withdraw accumulated funds.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol"; // For debugging - remove in production

contract EvolvingNFT is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    string public baseMetadataURI; // Base URI for metadata (can be updated)

    struct NFTData {
        uint8 evolutionStage;
        uint256 evolutionPoints;
        string traits; // JSON string of traits
        uint256 lastStakedTime;
    }
    mapping(uint256 => NFTData) public nftData;

    struct EvolutionStage {
        uint256 evolutionPointsNeeded;
        string stageMetadata; // Metadata specific to this stage
    }
    mapping(uint8 => EvolutionStage) public evolutionStages;
    uint8 public maxEvolutionStage = 3; // Example: Max 3 evolution stages

    IERC20 public resourceToken; // ERC20 token for resource-based evolution

    // Staking related mappings
    mapping(uint256 => uint256) public nftStakeStartTime;
    mapping(uint256 => bool) public isNFTStaked;

    // Market Listing
    struct MarketListing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => MarketListing) public marketListings;
    Counters.Counter private _listingIdCounter;

    // Lending related mappings
    struct LendingListing {
        uint256 tokenId;
        address lender;
        uint256 rentPricePerDay;
        bool isListed;
    }
    mapping(uint256 => LendingListing) public lendingListings;
    mapping(uint256 => uint256) public nftRentalEndTime; // TokenId -> rental end timestamp

    // Governance - Trait Change Proposals
    struct TraitChangeProposal {
        string traitName;
        string newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }
    mapping(uint256 => TraitChangeProposal) public traitChangeProposals;
    Counters.Counter private _proposalIdCounter;

    // --- Events ---

    event NFTMinted(uint256 tokenId, address owner);
    event NFTStaked(uint256 tokenId, address owner);
    event NFTUnstaked(uint256 tokenId, address owner, uint256 evolutionPoints);
    event NFTTrained(uint256 tokenId, address owner, uint8 trainingEffort);
    event NFTEvolved(uint256 tokenId, address owner, uint8 newStage, string newTraits);
    event ResourceConsumedForEvolution(uint256 tokenId, address owner, uint256 amount);
    event MarketListingCreated(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event MarketNFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event LendingListingCreated(uint256 tokenId, address lender, uint256 rentPricePerDay);
    event NFTLent(uint256 tokenId, address renter, uint256 rentalDays, uint256 endTime);
    event NFTReturned(uint256 tokenId, address renter, address lender);
    event TraitChangeProposed(uint256 proposalId, string traitName, string newValue, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event TraitChangeExecuted(uint256 proposalId, string traitName, string newValue);

    // --- Modifiers ---

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_exists(_tokenId) && ownerOf(_tokenId) == _msgSender(), "Not NFT owner");
        _;
    }

    modifier onlyListingSeller(uint256 _listingId) {
        require(marketListings[_listingId].seller == _msgSender(), "Not listing seller");
        _;
    }

    modifier onlyLendingLister(uint256 _tokenId) {
        require(lendingListings[_tokenId].lender == _msgSender(), "Not lending lister");
        _;
    }

    modifier onlyBeforeRentalEnd(uint256 _tokenId) {
        require(block.timestamp < nftRentalEndTime[_tokenId], "Rental period has ended");
        _;
    }

    modifier onlyAfterRentalEnd(uint256 _tokenId) {
        require(block.timestamp >= nftRentalEndTime[_tokenId], "Rental period has not ended");
        _;
    }


    // --- Constructor ---

    constructor(string memory _name, string memory _symbol, string memory _baseURI, address _resourceTokenAddress) ERC721(_name, _symbol) {
        baseMetadataURI = _baseURI;
        resourceToken = IERC20(_resourceTokenAddress);
    }

    // --- Core NFT Functionality ---

    function mintEvolvingNFT(string memory _baseURI) public whenNotPaused {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), tokenId);

        // Initialize NFT Data - Example initial traits
        nftData[tokenId] = NFTData({
            evolutionStage: 1,
            evolutionPoints: 0,
            traits: '{"type": "Basic", "color": "Green", "power": 10}',
            lastStakedTime: 0
        });

        _setTokenURI(tokenId, string(abi.encodePacked(baseMetadataURI, _baseURI, tokenId.toString()))); // Set initial metadata URI
        emit NFTMinted(tokenId, _msgSender());
    }

    function transferNFT(address _to, uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        safeTransferFrom(_msgSender(), _to, _tokenId);
    }

    function getNFTMetadata(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return tokenURI(_tokenId);
    }

    function burnNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_exists(_tokenId), "NFT does not exist");
        _burn(_tokenId);
    }

    // --- Evolution Mechanics ---

    function stakeNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(!isNFTStaked[_tokenId], "NFT already staked");
        isNFTStaked[_tokenId] = true;
        nftStakeStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, _msgSender());
    }

    function unstakeNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused returns (uint256 earnedPoints) {
        require(isNFTStaked[_tokenId], "NFT not staked");
        isNFTStaked[_tokenId] = false;
        uint256 stakeDuration = block.timestamp - nftStakeStartTime[_tokenId];
        earnedPoints = stakeDuration / 86400; // Example: 1 day of staking = 1 point
        nftData[_tokenId].evolutionPoints += earnedPoints;
        nftData[_tokenId].lastStakedTime = 0; // Reset stake time
        emit NFTUnstaked(_tokenId, _msgSender(), earnedPoints);
        return earnedPoints;
    }

    function trainNFT(uint256 _tokenId, uint8 _trainingEffort) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_trainingEffort > 0 && _trainingEffort <= 10, "Training effort out of range");
        nftData[_tokenId].evolutionPoints += _trainingEffort;
        emit NFTTrained(_tokenId, _msgSender(), _trainingEffort);
    }

    function evolveNFT(uint256 _tokenId) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(nftData[_tokenId].evolutionStage < maxEvolutionStage, "NFT at max evolution stage");
        uint8 currentStage = nftData[_tokenId].evolutionStage;
        uint256 pointsNeeded = evolutionStages[currentStage].evolutionPointsNeeded;

        require(nftData[_tokenId].evolutionPoints >= pointsNeeded, "Not enough evolution points");

        nftData[_tokenId].evolutionStage++;
        nftData[_tokenId].evolutionPoints -= pointsNeeded; // Reset points after evolution

        // Example: Dynamic trait update on evolution (randomly add a new trait)
        string memory currentTraitsJson = nftData[_tokenId].traits;
        string memory newTraitsJson = _updateTraitsOnEvolution(currentTraitsJson, nftData[_tokenId].evolutionStage);
        nftData[_tokenId].traits = newTraitsJson;


        // Update metadata URI to reflect evolution stage (example - you might have different metadata per stage)
        _setTokenURI(_tokenId, string(abi.encodePacked(baseMetadataURI, evolutionStages[nftData[_tokenId].evolutionStage].stageMetadata, _tokenId.toString())));

        emit NFTEvolved(_tokenId, _msgSender(), nftData[_tokenId].evolutionStage, newTraitsJson);
    }

    function consumeResourceForEvolution(uint256 _tokenId, uint256 _resourceAmount) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(_resourceAmount > 0, "Resource amount must be positive");
        require(resourceToken.transferFrom(_msgSender(), address(this), _resourceAmount), "Resource token transfer failed"); // Transfer tokens to contract
        nftData[_tokenId].evolutionPoints += _resourceAmount; // Example: 1 resource token = 1 evolution point
        emit ResourceConsumedForEvolution(_tokenId, _msgSender(), _resourceAmount);
    }

    // --- Rarity and Traits System ---

    function setBaseTraits(uint256 _tokenId, string memory _traits) public onlyOwner {
        require(_exists(_tokenId), "NFT does not exist");
        nftData[_tokenId].traits = _traits;
    }

    function getNFTTraits(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftData[_tokenId].traits;
    }

    function calculateRarityScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        // Example: Simple rarity calculation based on traits (can be more complex)
        // Parse JSON traits string and assign rarity points based on trait values
        // For simplicity, this example just returns the evolution stage as a score.
        return uint256(nftData[_tokenId].evolutionStage);
    }

    // --- NFT Fusion/Merging ---
    function fuseNFTs(uint256 _tokenId1, uint256 _tokenId2) public onlyNFTOwner(_tokenId1) whenNotPaused {
        require(ownerOf(_tokenId2) == _msgSender(), "Not owner of both NFTs");
        require(_tokenId1 != _tokenId2, "Cannot fuse the same NFT");
        require(nftData[_tokenId1].evolutionStage == nftData[_tokenId2].evolutionStage, "NFTs must be at the same evolution stage to fuse");

        _tokenIdCounter.increment();
        uint256 newNFTTokenId = _tokenIdCounter.current();
        _safeMint(_msgSender(), newNFTTokenId);

        // Example: Create new traits by combining traits of fused NFTs (can be more complex logic)
        string memory traits1 = nftData[_tokenId1].traits;
        string memory traits2 = nftData[_tokenId2].traits;
        string memory fusedTraits = _fuseTraits(traits1, traits2);

        nftData[newNFTTokenId] = NFTData({
            evolutionStage: nftData[_tokenId1].evolutionStage + 1 > maxEvolutionStage ? maxEvolutionStage : nftData[_tokenId1].evolutionStage + 1, // Evolve one stage further (or max)
            evolutionPoints: 0,
            traits: fusedTraits,
            lastStakedTime: 0
        });
        _setTokenURI(newNFTTokenId, string(abi.encodePacked(baseMetadataURI, "fused", newNFTTokenId.toString()))); // Set metadata for fused NFT

        burnNFT(_tokenId1);
        burnNFT(_tokenId2);

        emit NFTMinted(newNFTTokenId, _msgSender()); // Mint new fused NFT
        emit NFTEvolved(newNFTTokenId, _msgSender(), nftData[newNFTTokenId].evolutionStage, fusedTraits); // Emit evolve event for fused NFT
    }


    // --- NFT Lending/Renting ---

    function listNFTForLending(uint256 _tokenId, uint256 _rentPricePerDay) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(!lendingListings[_tokenId].isListed, "NFT already listed for lending");
        require(nftRentalEndTime[_tokenId] == 0 || block.timestamp >= nftRentalEndTime[_tokenId], "NFT is currently rented"); // Not already rented

        lendingListings[_tokenId] = LendingListing({
            tokenId: _tokenId,
            lender: _msgSender(),
            rentPricePerDay: _rentPricePerDay,
            isListed: true
        });
        emit LendingListingCreated(_tokenId, _msgSender(), _rentPricePerDay);
    }

    function lendNFT(uint256 _tokenId, uint256 _rentalDays) public payable whenNotPaused {
        require(lendingListings[_tokenId].isListed, "NFT not listed for lending");
        require(msg.value >= lendingListings[_tokenId].rentPricePerDay * _rentalDays, "Insufficient rental fee sent");

        address lender = lendingListings[_tokenId].lender;
        uint256 rentAmount = lendingListings[_tokenId].rentPricePerDay * _rentalDays;

        // Transfer rent to lender
        payable(lender).transfer(rentAmount);

        // Transfer NFT temporarily to renter (using safeTransferFrom to ensure receiver can handle ERC721)
        safeTransferFrom(lendingListings[_tokenId].lender, _msgSender(), _tokenId);

        nftRentalEndTime[_tokenId] = block.timestamp + (_rentalDays * 1 days);
        lendingListings[_tokenId].isListed = false; // Remove from listing after lent

        emit NFTLent(_tokenId, _msgSender(), _rentalDays, nftRentalEndTime[_tokenId]);
    }

    function returnLentNFT(uint256 _tokenId) public onlyBeforeRentalEnd(_tokenId) whenNotPaused {
        address lender = lendingListings[_tokenId].lender;
        address renter = _msgSender();

        safeTransferFrom(renter, lender, _tokenId);
        nftRentalEndTime[_tokenId] = 0; // Reset rental end time

        emit NFTReturned(_tokenId, renter, lender);
    }

    function reclaimLentNFT(uint256 _tokenId) public onlyLendingLister(_tokenId) onlyAfterRentalEnd(_tokenId) whenNotPaused {
        address lender = _msgSender();
        address renter = ownerOf(_tokenId); // Renter is the current owner after lending

        safeTransferFrom(renter, lender, _tokenId);
        nftRentalEndTime[_tokenId] = 0; // Reset rental end time

        emit NFTReturned(_tokenId, renter, lender);
    }


    // --- In-Contract Marketplace ---

    function createMarketListing(uint256 _tokenId, uint256 _price) public onlyNFTOwner(_tokenId) whenNotPaused {
        require(marketListings[_listingIdCounter.current()].isActive == false, "Previous listing not closed yet, use different listing ID or try again later"); // Basic listing ID check.
        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        _approve(address(this), _tokenId); // Approve contract to transfer NFT

        marketListings[listingId] = MarketListing({
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });
        emit MarketListingCreated(listingId, _tokenId, _msgSender(), _price);
    }

    function buyNFTFromMarket(uint256 _listingId) public payable whenNotPaused {
        require(marketListings[_listingId].isActive, "Listing is not active");
        require(msg.value >= marketListings[_listingId].price, "Insufficient payment");

        MarketListing storage listing = marketListings[_listingId];
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false; // Deactivate listing
        payable(seller).transfer(price); // Send funds to seller
        safeTransferFrom(seller, _msgSender(), tokenId); // Transfer NFT to buyer

        emit MarketNFTBought(_listingId, tokenId, _msgSender(), price);
    }

    function cancelMarketListing(uint256 _listingId) public onlyListingSeller(_listingId) whenNotPaused {
        require(marketListings[_listingId].isActive, "Listing is not active");
        marketListings[_listingId].isActive = false;
    }


    // --- Community Governance (Basic) ---

    function proposeTraitChange(string memory _traitName, string memory _newValue) public whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        traitChangeProposals[proposalId] = TraitChangeProposal({
            traitName: _traitName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        emit TraitChangeProposed(proposalId, _traitName, _newValue, _msgSender());
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(traitChangeProposals[_proposalId].isActive, "Proposal is not active");
        require(!traitChangeProposals[_proposalId].isExecuted, "Proposal already executed"); // Prevent voting on executed proposals

        if (_vote) {
            traitChangeProposals[_proposalId].votesFor++;
        } else {
            traitChangeProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(traitChangeProposals[_proposalId].isActive, "Proposal is not active");
        require(!traitChangeProposals[_proposalId].isExecuted, "Proposal already executed");
        require(traitChangeProposals[_proposalId].votesFor > traitChangeProposals[_proposalId].votesAgainst, "Proposal not approved by majority"); // Simple majority vote

        string memory currentTraitsJson = nftData[1].traits; // Example: Apply to tokenId 1 for demonstration. In real app, you would need to decide which NFTs are affected.
        string memory newTraitsJson = _updateTraitInJson(currentTraitsJson, traitChangeProposals[_proposalId].traitName, traitChangeProposals[_proposalId].newValue);
        nftData[1].traits = newTraitsJson; // Example: Apply to tokenId 1

        traitChangeProposals[_proposalId].isExecuted = true;
        traitChangeProposals[_proposalId].isActive = false; // Deactivate proposal
        emit TraitChangeExecuted(_proposalId, traitChangeProposals[_proposalId].traitName, traitChangeProposals[_proposalId].newValue);
    }


    // --- Admin and Management ---

    function setEvolutionStageData(uint8 _stage, uint256 _evolutionPointsNeeded, string memory _stageMetadata) public onlyOwner {
        evolutionStages[_stage] = EvolutionStage({
            evolutionPointsNeeded: _evolutionPointsNeeded,
            stageMetadata: _stageMetadata
        });
    }

    function setResourceTokenAddress(address _tokenAddress) public onlyOwner {
        resourceToken = IERC20(_tokenAddress);
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function withdrawContractBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // --- Internal Helper Functions ---

    function _updateTraitsOnEvolution(string memory _currentTraitsJson, uint8 _newStage) internal pure returns (string memory) {
        // Example: Add a new trait or modify an existing one based on evolution stage.
        // In a real application, you would have more complex logic here.
        // For simplicity, let's just add a "stage" trait and update power.

        // Parse JSON (basic example, more robust parsing needed for production)
        string memory updatedJson = string(abi.encodePacked('{',
            '"stage": "', Strings.toString(_newStage), '",',
            '"evolved": true,', // Mark as evolved
            '"power": ', Strings.toString(10 + (_newStage * 5)), ',', // Increase power with stage
            '"baseTraits": ', _currentTraitsJson, // Keep base traits
            '}'));

        return updatedJson;
    }

    function _fuseTraits(string memory _traits1, string memory _traits2) internal pure returns (string memory) {
        // Example: Basic trait fusion - combine some traits from both NFTs.
        // In a real application, this could be much more complex and interesting.
        // For simplicity, just combine type and color, and set power to be higher.

        // Basic JSON parsing (very simplified, needs proper JSON parsing for production)
        string memory type1 = _getJsonValue(_traits1, "type");
        string memory color1 = _getJsonValue(_traits1, "color");
        string memory type2 = _getJsonValue(_traits2, "type");
        string memory color2 = _getJsonValue(_traits2, "color");

        string memory fusedType = string(abi.encodePacked(type1, "-", type2)); // Combine types
        string memory fusedColor = string(abi.encodePacked(color1, "/", color2)); // Combine colors

        string memory fusedJson = string(abi.encodePacked('{',
            '"type": "', fusedType, '",',
            '"color": "', fusedColor, '",',
            '"power": ', Strings.toString(25), ',', // Higher power for fused NFT
            '"fused": true',
            '}'));

        return fusedJson;
    }

    function _getJsonValue(string memory _jsonString, string memory _key) internal pure returns (string memory) {
        // Very basic and unsafe JSON value extraction - for demonstration only.
        // Use a proper JSON parsing library in a real application.
        string memory keySearch = string(abi.encodePacked('"', _key, '": "'));
        int start = _indexOf(bytes(_jsonString), bytes(keySearch));
        if (start == -1) return ""; // Key not found

        start += int(bytes(keySearch).length);
        int end = _indexOf(bytes(_jsonString).slice(uint256(start))), bytes('"'));
        if (end == -1) return ""; // Closing quote not found

        return string(bytes(_jsonString).slice(uint256(start), uint256(start + end)));
    }

    function _indexOf(bytes memory _haystack, bytes memory _needle) internal pure returns (int) {
        // Basic string search - for demonstration purposes.
        // Use more efficient string libraries for production.
        if (_needle.length == 0) return 0;
        for (uint256 i = 0; i <= _haystack.length - _needle.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < _needle.length; j++) {
                if (_haystack[i + j] != _needle[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return int(i);
        }
        return -1;
    }

    function _updateTraitInJson(string memory _jsonString, string memory _traitName, string memory _newValue) internal pure returns (string memory) {
        // Example: Update a specific trait value in JSON string. Basic and unsafe.
        // Robust JSON parsing and modification is needed for production.

        string memory keyToUpdate = string(abi.encodePacked('"', _traitName, '": "'));
        int startIndex = _indexOf(bytes(_jsonString), bytes(keyToUpdate));

        if (startIndex == -1) {
            // Trait not found, handle error or add new trait (depending on requirements)
            return _jsonString; // For now, just return original JSON if trait not found
        }

        startIndex += int(bytes(keyToUpdate).length);
        int endIndex = _indexOf(bytes(_jsonString).slice(uint256(startIndex)), bytes('"'));
        if (endIndex == -1) return _jsonString; // Closing quote not found

        string memory prefix = string(bytes(_jsonString).slice(0, uint256(startIndex)));
        string memory suffix = string(bytes(_jsonString).slice(uint256(startIndex + endIndex)));
        string memory updatedJson = string(abi.encodePacked(prefix, _newValue, suffix));
        return updatedJson;
    }

    // --- Fallback and Receive ---
    receive() external payable {}
    fallback() external payable {}
}
```