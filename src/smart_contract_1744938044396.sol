```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Curation & Fractionalization
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for a dynamic NFT marketplace featuring AI-driven curation,
 *      fractionalization, and advanced marketplace functionalities. This contract aims to provide
 *      a unique and engaging NFT trading experience beyond typical marketplaces.
 *
 * **Outline and Function Summary:**
 *
 * **1. NFT Collection Management:**
 *    - `createNFTCollection(string memory _collectionName, string memory _collectionSymbol, string memory _baseURI)`: Allows the contract owner or designated roles to create new NFT collections.
 *    - `setCollectionBaseURI(address _collectionAddress, string memory _newBaseURI)`: Updates the base URI for an existing NFT collection.
 *    - `addCollectionAdmin(address _collectionAddress, address _admin)`: Adds an admin role for a specific NFT collection.
 *    - `removeCollectionAdmin(address _collectionAddress, address _admin)`: Removes an admin role for a specific NFT collection.
 *
 * **2. Dynamic NFT Features:**
 *    - `updateNFTMetadata(address _collectionAddress, uint256 _tokenId, string memory _newMetadataURI)`:  Allows collection admins to update the metadata URI of a specific NFT, enabling dynamic NFTs.
 *    - `triggerNFTStateChange(address _collectionAddress, uint256 _tokenId, bytes memory _stateData)`:  Triggers a state change for an NFT based on external data (simulating dynamic behavior). (Abstract/Simulated AI Input)
 *    - `batchUpdateNFTMetadata(address _collectionAddress, uint256[] memory _tokenIds, string[] memory _metadataURIs)`: Batch update metadata for multiple NFTs in a collection.
 *
 * **3. AI-Powered Curation (Simulated):**
 *    - `reportNFTQuality(address _collectionAddress, uint256 _tokenId, uint8 _qualityScore)`: Users can report the perceived quality of an NFT (simulating AI feedback data).
 *    - `getNFTQualityScore(address _collectionAddress, uint256 _tokenId)`: Retrieves the aggregated quality score for an NFT.
 *    - `featureNFT(address _collectionAddress, uint256 _tokenId)`: Allows admins to feature NFTs based on high quality scores or manual curation.
 *    - `unfeatureNFT(address _collectionAddress, uint256 _tokenId)`: Removes an NFT from the featured list.
 *
 * **4. Fractionalization Features:**
 *    - `fractionalizeNFT(address _collectionAddress, uint256 _tokenId, uint256 _numberOfFractions)`: Fractionalizes an NFT, creating fungible tokens representing fractions.
 *    - `redeemNFTFraction(address _fractionTokenAddress, uint256 _fractionAmount)`: Allows holders of fraction tokens to redeem them for a proportional share of the original NFT (complex redemption logic needed).
 *    - `getFractionTokenAddress(address _collectionAddress, uint256 _tokenId)`: Retrieves the fraction token address associated with an NFT.
 *    - `isNFTFractionalized(address _collectionAddress, uint256 _tokenId)`: Checks if an NFT is fractionalized.
 *
 * **5. Advanced Marketplace Functions:**
 *    - `listItemForSale(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 *    - `buyNFT(address _collectionAddress, uint256 _tokenId)`: Allows users to purchase an NFT listed for sale.
 *    - `cancelListing(address _collectionAddress, uint256 _tokenId)`: Cancels an NFT listing.
 *    - `makeOffer(address _collectionAddress, uint256 _tokenId, uint256 _offerPrice)`: Allows users to make offers on NFTs not currently listed.
 *    - `acceptOffer(address _offerMaker, address _collectionAddress, uint256 _tokenId)`: Allows NFT owners to accept offers.
 *    - `withdrawOffer(address _collectionAddress, uint256 _tokenId)`: Allows offer makers to withdraw their offers.
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage.
 *    - `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 *
 * **6. Utility and Access Control:**
 *    - `pauseMarketplace()`: Pauses all marketplace trading functions.
 *    - `unpauseMarketplace()`: Resumes marketplace trading functions.
 *    - `setContractOwner(address _newOwner)`: Transfers contract ownership.
 *    - `getContractOwner()`: Retrieves the contract owner address.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTMarketplaceAI is Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs and Enums ---

    struct NFTListing {
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isListed;
    }

    struct NFTOffer {
        address offerMaker;
        address collectionAddress;
        uint256 tokenId;
        uint256 offerPrice;
        bool isActive;
    }

    struct NFTFraction {
        address fractionTokenAddress;
        uint256 numberOfFractions;
        bool isFractionalized;
    }

    // --- State Variables ---

    mapping(address => mapping(uint256 => NFTListing)) public nftListings; // Nested mapping: collectionAddress -> tokenId -> Listing details
    mapping(address => mapping(uint256 => NFTOffer)) public nftOffers;      // Nested mapping: collectionAddress -> tokenId -> Offer details (only one active offer per NFT for simplicity)
    mapping(address => mapping(uint256 => NFTFraction)) public nftFractions; // Nested mapping: collectionAddress -> tokenId -> Fraction details
    mapping(address => mapping(uint256 => uint256)) public nftQualityScores; // Nested mapping: collectionAddress -> tokenId -> Quality Score
    mapping(address => bool) public isFeaturedNFT;                         // Mapping to track featured NFTs (collectionAddress + tokenId as key - simplified for demonstration)
    mapping(address => mapping(address => bool)) public collectionAdmins;    // Nested mapping: collectionAddress -> adminAddress -> isAdmin

    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    address payable public marketplaceFeeRecipient;

    Counters.Counter private _collectionCounter;

    // --- Events ---

    event CollectionCreated(address collectionAddress, string collectionName, string collectionSymbol, address creator);
    event NFTListed(address collectionAddress, uint256 tokenId, uint256 price, address seller);
    event NFTBought(address collectionAddress, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(address collectionAddress, uint256 tokenId, address seller);
    event OfferMade(address offerMaker, address collectionAddress, uint256 tokenId, uint256 offerPrice);
    event OfferAccepted(address offerMaker, address collectionAddress, uint256 tokenId, address seller, uint256 price);
    event OfferWithdrawn(address offerMaker, address collectionAddress, uint256 tokenId);
    event NFTMetadataUpdated(address collectionAddress, uint256 tokenId, string newMetadataURI);
    event NFTStateChanged(address collectionAddress, uint256 tokenId, bytes stateData);
    event NFTFractionalized(address collectionAddress, uint256 tokenId, address fractionTokenAddress, uint256 numberOfFractions);
    event NFTFractionRedeemed(address fractionTokenAddress, address redeemer, uint256 fractionAmount, address originalNFTCollection, uint256 originalNFTTokenId);
    event NFTQualityReported(address collectionAddress, uint256 tokenId, address reporter, uint8 qualityScore);
    event NFTFeatured(address collectionAddress, uint256 tokenId);
    event NFTUnfeatured(address collectionAddress, uint256 tokenId);
    event MarketplacePaused();
    event MarketplaceUnpaused();
    event MarketplaceFeeSet(uint256 feePercentage);
    event MarketplaceFeesWithdrawn(uint256 amount, address recipient);
    event CollectionAdminAdded(address collectionAddress, address admin);
    event CollectionAdminRemoved(address collectionAddress, address admin);

    // --- Modifiers ---

    modifier onlyCollectionAdmin(address _collectionAddress) {
        require(collectionAdmins[_collectionAddress][msg.sender] || msg.sender == owner(), "Not a collection admin");
        _;
    }

    modifier validCollection(address _collectionAddress) {
        require(address(_collectionAddress) != address(0), "Invalid collection address");
        // In a real scenario, you'd check if the address is indeed an ERC721 contract.
        _;
    }

    modifier validNFT(address _collectionAddress, uint256 _tokenId) {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) != address(0), "Invalid NFT token"); // Assumes ERC721Enumerable or similar for ownerOf
        _;
    }

    modifier validListing(address _collectionAddress, uint256 _tokenId) {
        require(nftListings[_collectionAddress][_tokenId].isListed, "NFT not listed for sale");
        _;
    }

    modifier notListed(address _collectionAddress, uint256 _tokenId) {
        require(!nftListings[_collectionAddress][_tokenId].isListed, "NFT already listed for sale");
        _;
    }

    modifier notFractionalized(address _collectionAddress, uint256 _tokenId) {
        require(!nftFractions[_collectionAddress][_tokenId].isFractionalized, "NFT is already fractionalized");
        _;
    }

    modifier isFractionalized(address _collectionAddress, uint256 _tokenId) {
        require(nftFractions[_collectionAddress][_tokenId].isFractionalized, "NFT is not fractionalized");
        _;
    }

    modifier offerExists(address _collectionAddress, uint256 _tokenId) {
        require(nftOffers[_collectionAddress][_tokenId].isActive, "No active offer exists for this NFT");
        _;
    }

    modifier noActiveOffer(address _collectionAddress, uint256 _tokenId) {
        require(!nftOffers[_collectionAddress][_tokenId].isActive, "Active offer already exists for this NFT");
        _;
    }

    modifier marketplaceActive() {
        require(!paused(), "Marketplace is paused");
        _;
    }

    // --- Constructor ---

    constructor(address payable _feeRecipient) payable {
        marketplaceFeeRecipient = _feeRecipient;
    }

    // --- 1. NFT Collection Management ---

    function createNFTCollection(string memory _collectionName, string memory _collectionSymbol, string memory _baseURI) external onlyOwner returns (address) {
        // In a real advanced scenario, you might deploy a new ERC721 contract instance here using create2 and factory pattern for more control.
        // For simplicity, we assume collections are pre-deployed and managed externally.
        // This function can be extended to integrate with a NFT factory contract for dynamic collection creation.

        // For this example, we'll simulate collection creation by just emitting an event and not actually deploying a new contract.
        address simulatedCollectionAddress = address(uint160(_collectionCounter.current())); // Simulate unique address
        _collectionCounter.increment();

        emit CollectionCreated(simulatedCollectionAddress, _collectionName, _collectionSymbol, msg.sender);
        return simulatedCollectionAddress; // Return the simulated address
    }

    function setCollectionBaseURI(address _collectionAddress, string memory _newBaseURI) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) {
        // In a real implementation, the ERC721 contract itself would need a function to set the base URI,
        // and this function would call that on-chain function.
        // For this example, we'll just emit an event to indicate the intention.

        emit NFTMetadataUpdated(_collectionAddress, 0, _newBaseURI); //tokenId 0 as placeholder to represent collection-level update
        // In a real ERC721 contract: IERC721Metadata(_collectionAddress).setBaseURI(_newBaseURI);
    }

    function addCollectionAdmin(address _collectionAddress, address _admin) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) {
        collectionAdmins[_collectionAddress][_admin] = true;
        emit CollectionAdminAdded(_collectionAddress, _admin);
    }

    function removeCollectionAdmin(address _collectionAddress, address _admin) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) {
        delete collectionAdmins[_collectionAddress][_admin];
        emit CollectionAdminRemoved(_collectionAddress, _admin);
    }

    // --- 2. Dynamic NFT Features ---

    function updateNFTMetadata(address _collectionAddress, uint256 _tokenId, string memory _newMetadataURI) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) {
        // In a real implementation, the ERC721 contract might have a function to update token URI if designed for dynamic metadata.
        // For this example, we simulate by emitting an event.

        emit NFTMetadataUpdated(_collectionAddress, _tokenId, _newMetadataURI);
        // In a real dynamic ERC721 contract: IERC721DynamicMetadata(_collectionAddress).setTokenURI(_tokenId, _newMetadataURI);
    }

    function triggerNFTStateChange(address _collectionAddress, uint256 _tokenId, bytes memory _stateData) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) {
        // This is a highly abstract function. In a real "dynamic" NFT, the contract might have logic to react to `_stateData`.
        // `_stateData` could represent input from an oracle, AI, game engine, etc.
        // For this example, we simply emit an event to represent a state change trigger.

        emit NFTStateChanged(_collectionAddress, _tokenId, _stateData);
        // In a real dynamic ERC721 contract, you would decode _stateData and update internal NFT state,
        // potentially triggering metadata updates or other on-chain actions.
        // Example:
        // (uint8 newState) = abi.decode(_stateData, (uint8));
        // _updateInternalNFTState(_collectionAddress, _tokenId, newState); // Hypothetical internal state update function
    }

    function batchUpdateNFTMetadata(address _collectionAddress, uint256[] memory _tokenIds, string[] memory _metadataURIs) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) {
        require(_tokenIds.length == _metadataURIs.length, "Token IDs and Metadata URIs arrays must be the same length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (IERC721(_collectionAddress).ownerOf(_tokenIds[i]) != address(0)) { // Check NFT validity for each token
                emit NFTMetadataUpdated(_collectionAddress, _tokenIds[i], _metadataURIs[i]);
                // In a real dynamic ERC721 contract: IERC721DynamicMetadata(_collectionAddress).setTokenURI(_tokenIds[i], _metadataURIs[i]);
            }
        }
    }


    // --- 3. AI-Powered Curation (Simulated) ---

    function reportNFTQuality(address _collectionAddress, uint256 _tokenId, uint8 _qualityScore) external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) marketplaceActive {
        require(_qualityScore <= 10, "Quality score must be between 0 and 10"); // Example score range
        nftQualityScores[_collectionAddress][_tokenId] += _qualityScore; // Simple aggregation - could be weighted averages, etc.
        emit NFTQualityReported(_collectionAddress, _tokenId, msg.sender, _qualityScore);
    }

    function getNFTQualityScore(address _collectionAddress, uint256 _tokenId) external view validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) returns (uint256) {
        return nftQualityScores[_collectionAddress][_tokenId];
    }

    function featureNFT(address _collectionAddress, uint256 _tokenId) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) {
        isFeaturedNFT[_collectionAddress] = true; // Simplified featured tracking for demonstration - in real app, need to handle multiple featured NFTs.
        emit NFTFeatured(_collectionAddress, _tokenId);
    }

    function unfeatureNFT(address _collectionAddress, uint256 _tokenId) external onlyCollectionAdmin(_collectionAddress) validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) {
        delete isFeaturedNFT[_collectionAddress]; // Simplified unfeaturing.
        emit NFTUnfeatured(_collectionAddress, _tokenId);
    }


    // --- 4. Fractionalization Features ---

    function fractionalizeNFT(address _collectionAddress, uint256 _tokenId, uint256 _numberOfFractions) external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) notFractionalized(_collectionAddress, _tokenId) marketplaceActive {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You must own the NFT to fractionalize it");
        require(_numberOfFractions > 0 && _numberOfFractions <= 10000, "Number of fractions must be between 1 and 10000"); // Example limit

        // Transfer NFT to this contract for safekeeping during fractionalization
        nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);

        // Create a new ERC20 token to represent fractions
        ERC20 fractionToken = new ERC20(string.concat(IERC721Metadata(_collectionAddress).name(), Strings.toString(_tokenId), " Fractions"), string.concat(IERC721Metadata(_collectionAddress).symbol(), Strings.toString(_tokenId), "FRAC"));

        // Mint fraction tokens to the NFT owner
        fractionToken.mint(msg.sender, _numberOfFractions);

        // Store fractionalization details
        nftFractions[_collectionAddress][_tokenId] = NFTFraction({
            fractionTokenAddress: address(fractionToken),
            numberOfFractions: _numberOfFractions,
            isFractionalized: true
        });

        emit NFTFractionalized(_collectionAddress, _tokenId, address(fractionToken), _numberOfFractions);
    }

    function redeemNFTFraction(address _fractionTokenAddress, uint256 _fractionAmount) external marketplaceActive {
        ERC20 fractionToken = ERC20(_fractionTokenAddress);
        require(fractionToken.balanceOf(msg.sender) >= _fractionAmount, "Insufficient fraction tokens");
        require(_fractionAmount > 0, "Redeem amount must be greater than zero");

        // Find the original NFT associated with the fraction token (this is a simplified lookup - in real app, more robust mapping needed)
        (address originalNFTCollection, uint256 originalNFTTokenId) = _getOriginalNFTDetails(_fractionTokenAddress); // Placeholder function - needs proper mapping

        require(nftFractions[originalNFTCollection][originalNFTTokenId].isFractionalized, "Original NFT is not fractionalized");

        NFTFraction memory fractionData = nftFractions[originalNFTCollection][originalNFTTokenId];
        uint256 totalFractions = fractionData.numberOfFractions;

        // Calculate the percentage of ownership the redeemer has
        uint256 ownershipPercentage = (_fractionAmount * 100) / totalFractions; // Example: Simple percentage calculation

        // In a real complex redemption system, you might have conditions:
        // - Require reaching a threshold percentage to redeem the full NFT.
        // - Implement voting mechanisms for fraction holders to decide on redemption.
        // - Handle scenarios where multiple users redeem fractions concurrently.

        // For this simplified example, if a user redeems ALL their fractions, we consider it a full redemption.
        if (fractionToken.balanceOf(msg.sender) == _fractionAmount && ownershipPercentage >= 90) { //Example 90% threshold for full redemption
            IERC721 originalNFT = IERC721(originalNFTCollection);

            // Transfer the original NFT back to the redeemer (assuming they have redeemed a significant portion)
            originalNFT.safeTransferFrom(address(this), msg.sender, originalNFTTokenId);

            // Burn the fraction tokens redeemed
            fractionToken.burnFrom(msg.sender, _fractionAmount);

            // Mark NFT as no longer fractionalized (or handle fractionalization state more granularly)
            nftFractions[originalNFTCollection][originalNFTTokenId].isFractionalized = false;

            emit NFTFractionRedeemed(_fractionTokenAddress, msg.sender, _fractionAmount, originalNFTCollection, originalNFTTokenId);
        } else {
            // Handle partial redemption scenarios here if needed - e.g., allow voting on NFT disposition with fraction tokens.
            // For this example, partial redemption is not fully implemented but acknowledged as a potential feature.
            // You might implement functionalities like:
            // - Staking fractions for voting rights on NFT decisions.
            // - Earning yield on fractions.
            // - Collective governance of the fractionalized NFT.
            fractionToken.burnFrom(msg.sender, _fractionAmount); // Burn the redeemed fractions even in partial redemption.
            emit NFTFractionRedeemed(_fractionTokenAddress, msg.sender, _fractionAmount, originalNFTCollection, originalNFTTokenId);
        }
    }

    // Placeholder function - needs to be implemented based on how you map fraction tokens to original NFTs.
    function _getOriginalNFTDetails(address _fractionTokenAddress) internal pure returns (address originalNFTCollection, uint256 originalNFTTokenId) {
        // In a real implementation, you'd need a mapping or method to reverse lookup the NFT from the fraction token address.
        // This could involve parsing the fraction token name/symbol, using a dedicated mapping, or more sophisticated indexing.
        // For this simplified example, we return dummy values.
        // **Important:** This is a critical part for real implementation and requires careful design.
        return (address(0), 0); // Placeholder - Replace with actual logic to retrieve original NFT details.
    }

    function getFractionTokenAddress(address _collectionAddress, uint256 _tokenId) external view validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) isFractionalized(_collectionAddress, _tokenId) returns (address) {
        return nftFractions[_collectionAddress][_tokenId].fractionTokenAddress;
    }

    function isNFTFractionalized(address _collectionAddress, uint256 _tokenId) external view validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) returns (bool) {
        return nftFractions[_collectionAddress][_tokenId].isFractionalized;
    }


    // --- 5. Advanced Marketplace Functions ---

    function listItemForSale(address _collectionAddress, uint256 _tokenId, uint256 _price) external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) notListed(_collectionAddress, _tokenId) marketplaceActive {
        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than zero");
        require(!nftFractions[_collectionAddress][_tokenId].isFractionalized, "Cannot list fractionalized NFTs"); // Prevent listing fractionalized NFTs

        // Approve this contract to transfer the NFT on sale
        nftContract.approve(address(this), _tokenId);

        nftListings[_collectionAddress][_tokenId] = NFTListing({
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isListed: true
        });

        emit NFTListed(_collectionAddress, _tokenId, _price, msg.sender);
    }

    function buyNFT(address _collectionAddress, uint256 _tokenId) external payable validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) validListing(_collectionAddress, _tokenId) marketplaceActive {
        NFTListing memory listing = nftListings[_collectionAddress][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        IERC721 nftContract = IERC721(_collectionAddress);
        require(nftContract.ownerOf(_tokenId) == listing.seller, "NFT ownership changed since listing"); // Double check ownership

        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = listing.price - marketplaceFee;

        // Transfer NFT to buyer
        nftContract.safeTransferFrom(listing.seller, msg.sender, _tokenId);

        // Transfer funds to seller and marketplace
        payable(listing.seller).transfer(sellerProceeds);
        marketplaceFeeRecipient.transfer(marketplaceFee);

        // Remove listing
        delete nftListings[_collectionAddress][_tokenId];

        emit NFTBought(_collectionAddress, _tokenId, msg.sender, listing.price);
    }

    function cancelListing(address _collectionAddress, uint256 _tokenId) external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) validListing(_collectionAddress, _tokenId) marketplaceActive {
        NFTListing memory listing = nftListings[_collectionAddress][_tokenId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        // Remove listing
        delete nftListings[_collectionAddress][_tokenId];

        emit ListingCancelled(_collectionAddress, _tokenId, msg.sender);
    }

    function makeOffer(address _collectionAddress, uint256 _tokenId, uint256 _offerPrice) external payable validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) noActiveOffer(_collectionAddress, _tokenId) marketplaceActive {
        require(msg.value >= _offerPrice, "Insufficient funds for offer");
        require(_offerPrice > 0, "Offer price must be greater than zero");
        require(!nftListings[_collectionAddress][_tokenId].isListed, "Cannot make offer on listed NFT"); // Optional: Decide if offers are allowed on listed NFTs

        nftOffers[_collectionAddress][_tokenId] = NFTOffer({
            offerMaker: msg.sender,
            collectionAddress: _collectionAddress,
            tokenId: _tokenId,
            offerPrice: _offerPrice,
            isActive: true
        });

        emit OfferMade(msg.sender, _collectionAddress, _tokenId, _offerPrice);
    }

    function acceptOffer(address _offerMaker, address _collectionAddress, uint256 _tokenId) external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) offerExists(_collectionAddress, _tokenId) marketplaceActive {
        NFTOffer memory offer = nftOffers[_collectionAddress][_tokenId];
        require(nftOffers[_collectionAddress][_tokenId].offerMaker == _offerMaker, "Offer maker mismatch");
        require(IERC721(_collectionAddress).ownerOf(_tokenId) == msg.sender, "Only owner can accept offer");

        uint256 offerPrice = offer.offerPrice;

        uint256 marketplaceFee = (offerPrice * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = offerPrice - marketplaceFee;

        IERC721 nftContract = IERC721(_collectionAddress);

        // Transfer NFT to offer maker
        nftContract.safeTransferFrom(msg.sender, offer.offerMaker, _tokenId);

        // Transfer funds to seller and marketplace
        payable(msg.sender).transfer(sellerProceeds);
        marketplaceFeeRecipient.transfer(marketplaceFee);

        // Deactivate offer
        nftOffers[_collectionAddress][_tokenId].isActive = false;

        emit OfferAccepted(offer.offerMaker, _collectionAddress, _tokenId, msg.sender, offerPrice);
    }

    function withdrawOffer(address _collectionAddress, uint256 _tokenId) external validCollection(_collectionAddress) validNFT(_collectionAddress, _tokenId) offerExists(_collectionAddress, _tokenId) marketplaceActive {
        NFTOffer memory offer = nftOffers[_collectionAddress][_tokenId];
        require(offer.offerMaker == msg.sender, "Only offer maker can withdraw offer");

        // Deactivate offer
        nftOffers[_collectionAddress][_tokenId].isActive = false;

        // Return offered funds (if funds were held in contract - not implemented in this basic offer system)
        // If you were holding funds, you'd transfer them back to msg.sender here.

        emit OfferWithdrawn(msg.sender, _collectionAddress, _tokenId);
    }

    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10, "Fee percentage cannot exceed 10%"); // Example limit
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage);
    }

    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No marketplace fees to withdraw");
        marketplaceFeeRecipient.transfer(balance);
        emit MarketplaceFeesWithdrawn(balance, marketplaceFeeRecipient);
    }


    // --- 6. Utility and Access Control ---

    function pauseMarketplace() external onlyOwner whenNotPaused {
        _pause();
        emit MarketplacePaused();
    }

    function unpauseMarketplace() external onlyOwner whenPaused {
        _unpause();
        emit MarketplaceUnpaused();
    }

    function setContractOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }

    function getContractOwner() external view returns (address) {
        return owner();
    }

    receive() external payable {} // To receive ETH for marketplace fees and offers (if funds are held in contract in a more advanced offer system).
}
```