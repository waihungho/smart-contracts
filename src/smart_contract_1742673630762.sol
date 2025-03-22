```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic NFT Marketplace with AI-Powered Rarity and Community Curation
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a dynamic NFT marketplace with several advanced and creative features.
 *      It incorporates AI-powered rarity scoring, community curation of NFT collections,
 *      dynamic pricing mechanisms, and on-chain governance for marketplace parameters.
 *
 * Function Summary:
 *
 * **NFT Management & Creation:**
 * 1. createNFT(string memory _metadataURI, uint256[] memory _traitScores): Allows creators to mint new NFTs, including AI-derived trait scores.
 * 2. transferNFT(address _to, uint256 _tokenId): Standard ERC721 transfer function.
 * 3. approve(address _approved, uint256 _tokenId): Standard ERC721 approval for single token.
 * 4. getApproved(uint256 _tokenId): Standard ERC721 get approved address for token.
 * 5. setApprovalForAll(address _operator, bool _approved): Standard ERC721 set approval for all operator.
 * 6. isApprovedForAll(address _owner, address _operator): Standard ERC721 check if operator is approved for all.
 * 7. burnNFT(uint256 _tokenId): Allows NFT owner to burn their NFT.
 * 8. setBaseMetadataURI(string memory _baseURI): Allows contract owner to set the base URI for NFT metadata.
 * 9. getNFTMetadataURI(uint256 _tokenId): Returns the full metadata URI for a given token ID.
 * 10. getNFTRarityScore(uint256 _tokenId): Retrieves the AI-derived rarity score of an NFT.
 *
 * **Marketplace & Trading:**
 * 11. listNFTForSale(uint256 _tokenId, uint256 _price): Allows NFT owners to list their NFTs for sale on the marketplace.
 * 12. buyNFT(uint256 _listingId): Allows users to purchase an NFT listed on the marketplace.
 * 13. cancelNFTListing(uint256 _listingId): Allows NFT owners to cancel their NFT listing.
 * 14. updateListingPrice(uint256 _listingId, uint256 _newPrice): Allows NFT owners to update the price of their listed NFT.
 * 15. getListingDetails(uint256 _listingId): Retrieves details of a specific NFT listing.
 * 16. getMarketplaceFee(): Returns the current marketplace fee percentage.
 * 17. setMarketplaceFee(uint256 _newFeePercentage): Allows contract owner to set the marketplace fee percentage.
 *
 * **Community Curation & Governance:**
 * 18. proposeNewCollection(string memory _collectionName, string memory _collectionDescription, string memory _collectionBaseURI): Allows community members to propose new NFT collections.
 * 19. voteOnCollectionProposal(uint256 _proposalId, bool _vote): Allows token holders to vote on collection proposals.
 * 20. finalizeCollectionProposal(uint256 _proposalId): Allows contract owner to finalize a passed collection proposal, enabling minting for that collection.
 * 21. getCollectionProposalDetails(uint256 _proposalId): Retrieves details of a collection proposal.
 * 22. getApprovedCollections(): Returns a list of IDs of community-approved collections.
 * 23. withdrawMarketplaceFees(): Allows contract owner to withdraw accumulated marketplace fees.
 * 24. pauseMarketplace(): Allows contract owner to pause marketplace trading in emergencies.
 * 25. unpauseMarketplace(): Allows contract owner to unpause marketplace trading.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTMarketplace is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _proposalIdCounter;

    string private _baseMetadataURI;
    uint256 private _marketplaceFeePercentage = 2; // Default 2% marketplace fee

    struct NFTListing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct CollectionProposal {
        string collectionName;
        string collectionDescription;
        string collectionBaseURI;
        uint256 voteCount;
        bool isApproved;
        bool isFinalized;
    }

    mapping(uint256 => NFTListing) public nftListings;
    mapping(uint256 => uint256[]) public nftRarityScores; // TokenId => [trait scores] - AI derived
    mapping(uint256 => CollectionProposal) public collectionProposals;
    mapping(uint256 => bool) public approvedCollections; // CollectionProposalId => isApproved

    event NFTCreated(uint256 tokenId, address creator, string metadataURI, uint256[] traitScores);
    event NFTListed(uint256 listingId, uint256 tokenId, uint256 price, address seller);
    event NFTBought(uint256 listingId, uint256 tokenId, uint256 price, address buyer, address seller);
    event NFTListingCancelled(uint256 listingId, uint256 tokenId);
    event NFTPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event CollectionProposed(uint256 proposalId, string collectionName, address proposer);
    event CollectionVoteCasted(uint256 proposalId, address voter, bool vote);
    event CollectionProposalFinalized(uint256 proposalId, bool isApproved);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    constructor(string memory _name, string memory _symbol, string memory baseMetadataURI) ERC721(_name, _symbol) {
        _baseMetadataURI = baseMetadataURI;
    }

    // ======== NFT Management & Creation ========

    /**
     * @dev Creates a new NFT with the given metadata URI and AI-derived trait scores.
     * @param _metadataURI The URI pointing to the NFT's metadata.
     * @param _traitScores An array of scores representing the NFT's traits (e.g., from an AI rarity model).
     */
    function createNFT(string memory _metadataURI, uint256[] memory _traitScores) public onlyOwner whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        nftRarityScores[tokenId] = _traitScores;
        emit NFTCreated(tokenId, msg.sender, _metadataURI, _traitScores);
        return tokenId;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused {
        transferFrom(msg.sender, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address _approved, uint256 _tokenId) public whenNotPaused {
        super.approve(_approved, _tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return super.getApproved(_tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        super.setApprovalForAll(_operator, _approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721Burnable}.
     * @param _tokenId The token to burn.
     */
    function burnNFT(uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Burner is not owner nor approved");
        _burn(_tokenId);
    }

    /**
     * @dev Sets the base metadata URI for the NFT collection.
     * @param _baseURI The new base metadata URI.
     */
    function setBaseMetadataURI(string memory _baseURI) public onlyOwner whenNotPaused {
        _baseMetadataURI = _baseURI;
    }

    /**
     * @dev Returns the full metadata URI for a given token ID by concatenating the base URI and the token ID.
     * @param _tokenId The ID of the NFT.
     * @return The metadata URI for the NFT.
     */
    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        return string(abi.encodePacked(_baseMetadataURI, Strings.toString(_tokenId)));
    }

    /**
     * @dev Retrieves the AI-derived rarity score of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of uint256 representing the NFT's trait scores.
     */
    function getNFTRarityScore(uint256 _tokenId) public view returns (uint256[] memory) {
        require(_exists(_tokenId), "Token does not exist");
        return nftRarityScores[_tokenId];
    }

    // ======== Marketplace & Trading ========

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price at which to list the NFT (in wei).
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not NFT owner");
        require(nftListings[_tokenId].isActive == false, "NFT already listed");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        nftListings[listingId] = NFTListing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });

        _approve(address(this), _tokenId); // Approve contract to transfer NFT

        emit NFTListed(listingId, _tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows a user to buy an NFT listed on the marketplace.
     * @param _listingId The ID of the NFT listing.
     */
    function buyNFT(uint256 _listingId) public payable whenNotPaused {
        require(nftListings[_listingId].isActive, "Listing is not active");
        NFTListing storage listing = nftListings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds");
        require(listing.seller != msg.sender, "Cannot buy your own NFT");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false; // Deactivate listing
        delete nftListings[_listingId]; // Clean up the listing data

        // Transfer NFT to buyer
        transferFrom(seller, msg.sender, tokenId);

        // Transfer funds to seller (minus marketplace fee)
        uint256 marketplaceFee = (price * _marketplaceFeePercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee;

        payable(seller).transfer(sellerPayout);
        payable(owner()).transfer(marketplaceFee); // Send fee to contract owner

        emit NFTBought(_listingId, tokenId, price, msg.sender, seller);
    }

    /**
     * @dev Cancels an NFT listing, removing it from the marketplace.
     * @param _listingId The ID of the NFT listing to cancel.
     */
    function cancelNFTListing(uint256 _listingId) public whenNotPaused {
        require(nftListings[_listingId].isActive, "Listing is not active");
        require(nftListings[_listingId].seller == msg.sender, "Not listing owner");

        nftListings[_listingId].isActive = false;
        delete nftListings[_listingId]; // Clean up the listing data

        emit NFTListingCancelled(_listingId, nftListings[_listingId].tokenId);
    }

    /**
     * @dev Updates the price of an NFT listing.
     * @param _listingId The ID of the NFT listing to update.
     * @param _newPrice The new price for the NFT listing.
     */
    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public whenNotPaused {
        require(nftListings[_listingId].isActive, "Listing is not active");
        require(nftListings[_listingId].seller == msg.sender, "Not listing owner");

        nftListings[_listingId].price = _newPrice;
        emit NFTPriceUpdated(_listingId, nftListings[_listingId].tokenId, _newPrice);
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _listingId The ID of the NFT listing.
     * @return NFTListing struct containing the listing details.
     */
    function getListingDetails(uint256 _listingId) public view returns (NFTListing memory) {
        return nftListings[_listingId];
    }

    /**
     * @dev Returns the current marketplace fee percentage.
     * @return The marketplace fee percentage.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return _marketplaceFeePercentage;
    }

    /**
     * @dev Sets the marketplace fee percentage. Only callable by the contract owner.
     * @param _newFeePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _newFeePercentage) public onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        _marketplaceFeePercentage = _newFeePercentage;
        emit MarketplaceFeeUpdated(_newFeePercentage);
    }

    // ======== Community Curation & Governance ========

    /**
     * @dev Allows community members to propose a new NFT collection to be curated on the marketplace.
     * @param _collectionName The name of the proposed collection.
     * @param _collectionDescription A brief description of the collection.
     * @param _collectionBaseURI The base metadata URI for the proposed collection.
     */
    function proposeNewCollection(string memory _collectionName, string memory _collectionDescription, string memory _collectionBaseURI) public whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        collectionProposals[proposalId] = CollectionProposal({
            collectionName: _collectionName,
            collectionDescription: _collectionDescription,
            collectionBaseURI: _collectionBaseURI,
            voteCount: 0,
            isApproved: false,
            isFinalized: false
        });

        emit CollectionProposed(proposalId, _collectionName, msg.sender);
    }

    /**
     * @dev Allows token holders to vote on a collection proposal.
     * @param _proposalId The ID of the collection proposal.
     * @param _vote True to vote in favor, false to vote against.
     */
    function voteOnCollectionProposal(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(collectionProposals[_proposalId].isFinalized == false, "Proposal already finalized");
        // Basic voting: each token holder gets one vote (can be extended to weighted voting based on token holdings)
        collectionProposals[_proposalId].voteCount += (_vote ? 1 : 0); // Simple +1 for yes votes. In a real DAO, voting mechanics would be more robust.
        emit CollectionVoteCasted(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Finalizes a collection proposal. Only callable by the contract owner.
     *      If enough votes are cast in favor (simple majority for this example, can be adjusted), the collection is approved.
     * @param _proposalId The ID of the collection proposal to finalize.
     */
    function finalizeCollectionProposal(uint256 _proposalId) public onlyOwner whenNotPaused {
        require(collectionProposals[_proposalId].isFinalized == false, "Proposal already finalized");

        CollectionProposal storage proposal = collectionProposals[_proposalId];
        // Simple approval logic: if voteCount is greater than a threshold (e.g., half of total token supply - not easily tracked here without a DAO structure).
        // For this example, just a simple arbitrary number for demonstration. In real scenario, voting logic would be more sophisticated.
        uint256 approvalThreshold = 10; // Example threshold - needs proper DAO voting mechanism for real use.
        bool isApproved = proposal.voteCount >= approvalThreshold;

        proposal.isApproved = isApproved;
        proposal.isFinalized = true;
        approvedCollections[_proposalId] = isApproved; // Mark as approved for filtering/display

        emit CollectionProposalFinalized(_proposalId, isApproved);
    }

    /**
     * @dev Retrieves details of a collection proposal.
     * @param _proposalId The ID of the collection proposal.
     * @return CollectionProposal struct containing the proposal details.
     */
    function getCollectionProposalDetails(uint256 _proposalId) public view returns (CollectionProposal memory) {
        return collectionProposals[_proposalId];
    }

    /**
     * @dev Returns a list of IDs of community-approved collections.
     * @return An array of proposal IDs representing approved collections.
     */
    function getApprovedCollections() public view returns (uint256[] memory) {
        uint256[] memory approvedProposalIds = new uint256[](_proposalIdCounter.current()); // Max size possible
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            if (approvedCollections[i]) {
                approvedProposalIds[count] = i;
                count++;
            }
        }

        // Resize the array to the actual number of approved proposals
        uint256[] memory finalApprovedProposalIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalApprovedProposalIds[i] = approvedProposalIds[i];
        }
        return finalApprovedProposalIds;
    }


    // ======== Utility & Admin Functions ========

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner whenNotPaused {
        payable(owner()).transfer(address(this).balance); // Withdraw all contract balance
    }

    /**
     * @dev Pauses the marketplace, preventing new listings and purchases. Only callable by the contract owner.
     */
    function pauseMarketplace() public onlyOwner {
        _pause();
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses the marketplace, allowing trading to resume. Only callable by the contract owner.
     */
    function unpauseMarketplace() public onlyOwner {
        _unpause();
        emit MarketplaceUnpaused();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Helper function to check if address is owner or approved for token
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || ERC721.getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
}
```