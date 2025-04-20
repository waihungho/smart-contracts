```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI Integration
 * @author Gemini AI
 * @dev A smart contract for a dynamic NFT marketplace that incorporates AI-driven metadata updates and advanced trading functionalities.
 *
 * **Outline:**
 * 1. **Core NFT Functionality:**
 *    - Minting Dynamic NFTs with initial metadata.
 *    - Burning Dynamic NFTs.
 *    - Transferring Dynamic NFTs.
 *    - Approving operators for NFT transfers.
 *    - Getting NFT owner and approvals.
 * 2. **Dynamic Metadata Management:**
 *    - Setting an authorized AI Oracle address.
 *    - Updating NFT metadata based on AI Oracle's input.
 *    - Retrieving current NFT metadata URI.
 *    - Querying metadata update history for an NFT.
 * 3. **Marketplace Listing and Trading:**
 *    - Listing NFTs for sale with price.
 *    - Delisting NFTs from sale.
 *    - Buying listed NFTs.
 *    - Making offers for NFTs.
 *    - Accepting offers for NFTs.
 *    - Cancelling offers.
 * 4. **AI Model Parameter Management (Simplified):**
 *    - Setting AI model parameters (e.g., sensitivity, update frequency - for demonstration).
 *    - Retrieving AI model parameters.
 * 5. **Governance and Platform Features:**
 *    - Proposing new features/updates to the platform (basic proposal mechanism).
 *    - Voting on proposals (simple voting based on token ownership/staking - placeholder).
 *    - Executing approved proposals (placeholder for actual execution logic).
 *    - Setting platform fees.
 *    - Withdrawing platform fees.
 * 6. **Utility and Information Functions:**
 *    - Getting platform name and version.
 *    - Checking if an NFT is listed for sale.
 *    - Getting listing details for an NFT.
 *    - Getting offer details for an NFT.
 *
 * **Function Summary:**
 * - `mintDynamicNFT(address _to, string memory _initialMetadataURI)`: Mints a new dynamic NFT to the specified address with initial metadata URI.
 * - `burnNFT(uint256 _tokenId)`: Burns a specific NFT, removing it from circulation.
 * - `transferNFT(address _to, uint256 _tokenId)`: Transfers an NFT to a new owner.
 * - `approveOperator(address _operator, uint256 _tokenId)`: Approves an operator to manage a specific NFT.
 * - `setApprovalForAllOperators(address _operator, bool _approved)`: Sets approval for an operator to manage all NFTs for the caller.
 * - `getOwnerOfNFT(uint256 _tokenId)`: Retrieves the owner of a specific NFT.
 * - `isApprovedOperator(address _operator, uint256 _tokenId)`: Checks if an address is an approved operator for an NFT.
 * - `setAIOracleAddress(address _oracleAddress)`: Sets the address authorized to update NFT metadata via AI.
 * - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows the AI Oracle to update the metadata URI of a dynamic NFT.
 * - `getCurrentMetadataURI(uint256 _tokenId)`: Gets the current metadata URI of a dynamic NFT.
 * - `getMetadataUpdateHistory(uint256 _tokenId)`: Retrieves the history of metadata URIs for a dynamic NFT.
 * - `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 * - `delistItemFromSale(uint256 _tokenId)`: Removes an NFT listing from the marketplace.
 * - `buyItem(uint256 _listingId)`: Allows anyone to buy a listed NFT.
 * - `offerForItem(uint256 _tokenId, uint256 _price)`: Allows users to make offers to buy NFTs not currently listed.
 * - `acceptOffer(uint256 _offerId)`: Allows the NFT owner to accept a specific offer.
 * - `cancelOffer(uint256 _offerId)`: Allows the offer maker to cancel their offer.
 * - `setAIModelParameter(string memory _parameterName, uint256 _parameterValue)`: (Simplified) Sets a parameter for the AI model influence.
 * - `getAIModelParameter(string memory _parameterName)`: (Simplified) Retrieves a specific AI model parameter.
 * - `proposePlatformFeature(string memory _featureDescription)`: Allows users to propose new features for the platform.
 * - `voteOnProposal(uint256 _proposalId, bool _support)`: Allows (placeholder) voting on platform feature proposals.
 * - `executeProposal(uint256 _proposalId)`: (Placeholder) Executes an approved platform feature proposal.
 * - `setPlatformFee(uint256 _feePercentage)`: Sets the platform fee percentage for marketplace sales.
 * - `withdrawPlatformFees()`: Allows the contract owner to withdraw accumulated platform fees.
 * - `getPlatformName()`: Returns the name of the platform.
 * - `getPlatformVersion()`: Returns the version of the platform.
 * - `isListedForSale(uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 * - `getListingDetails(uint256 _tokenId)`: Retrieves details of a listing for a given NFT (if listed).
 * - `getOfferDetails(uint256 _offerId)`: Retrieves details of a specific offer.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplaceAI is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public platformName = "Dynamic NFT AI Marketplace";
    string public platformVersion = "1.0.0";

    // NFT Data
    mapping(uint256 => string) private _tokenMetadataURIs;
    mapping(uint256 => string[]) private _metadataUpdateHistory;
    Counters.Counter private _tokenIdCounter;

    // Dynamic Metadata Settings
    address public aiOracleAddress;
    mapping(string => uint256) public aiModelParameters; // Simplified parameter storage

    // Marketplace Listings
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    Counters.Counter private _listingIdCounter;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public nftToListingId; // tokenId to listingId

    // Offers
    struct Offer {
        uint256 offerId;
        uint256 tokenId;
        address offerer;
        uint256 price;
        bool isActive;
    }
    Counters.Counter private _offerIdCounter;
    mapping(uint256 => Offer) public offers;
    mapping(uint256 => uint256[]) public nftToOfferIds; // tokenId to offerId array

    // Platform Fees
    uint256 public platformFeePercentage = 2; // Default 2% fee

    // Governance (Simplified Proposal System)
    struct Proposal {
        uint256 proposalId;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
    }
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;

    event NFTMinted(uint256 tokenId, address to, string metadataURI);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI, address updatedBy);
    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemDelisted(uint256 listingId, uint256 tokenId);
    event ItemBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event OfferMade(uint256 offerId, uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(uint256 offerId, uint256 tokenId, address seller, address buyer, uint256 price);
    event OfferCancelled(uint256 offerId, uint256 tokenId, address offerer);
    event AIOracleAddressSet(address oracleAddress, address setter);
    event AIModelParameterSet(string parameterName, uint256 parameterValue, address setter);
    event PlatformFeeSet(uint256 feePercentage, address setter);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawer);
    event FeatureProposed(uint256 proposalId, string description, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);

    constructor() ERC721(platformName, "DYNFT") {}

    // 1. Core NFT Functionality

    /**
     * @dev Mints a new dynamic NFT to the specified address with initial metadata URI.
     * @param _to The address to mint the NFT to.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     */
    function mintDynamicNFT(address _to, string memory _initialMetadataURI) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_to, tokenId);
        _tokenMetadataURIs[tokenId] = _initialMetadataURI;
        _metadataUpdateHistory[tokenId].push(_initialMetadataURI);
        emit NFTMinted(tokenId, _to, _initialMetadataURI);
        return tokenId;
    }

    /**
     * @dev Burns a specific NFT, removing it from circulation.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) public onlyOwner {
        _burn(_tokenId);
        delete _tokenMetadataURIs[_tokenId];
        delete _metadataUpdateHistory[_tokenId];
        // Consider cleaning up marketplace listings/offers related to this token in a real application
    }

    /**
     * @dev Transfers an NFT to a new owner.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public {
        safeTransferFrom(_msgSender(), _to, _tokenId);
    }

    /**
     * @dev Approves an operator to manage a specific NFT.
     * @param _operator The address to approve as an operator.
     * @param _tokenId The ID of the NFT to approve the operator for.
     */
    function approveOperator(address _operator, uint256 _tokenId) public payable {
        approve(_operator, _tokenId);
    }

    /**
     * @dev Sets approval for an operator to manage all NFTs for the caller.
     * @param _operator The address to set as an operator.
     * @param _approved True if approving, false if revoking.
     */
    function setApprovalForAllOperators(address _operator, bool _approved) public {
        setApprovalForAll(_operator, _approved);
    }

    /**
     * @dev Retrieves the owner of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The address of the owner.
     */
    function getOwnerOfNFT(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }

    /**
     * @dev Checks if an address is an approved operator for an NFT.
     * @param _operator The address to check.
     * @param _tokenId The ID of the NFT.
     * @return True if the address is an approved operator, false otherwise.
     */
    function isApprovedOperator(address _operator, uint256 _tokenId) public view returns (bool) {
        return isApprovedForAll(ownerOf(_tokenId), _operator);
    }

    // 2. Dynamic Metadata Management

    /**
     * @dev Sets the address authorized to update NFT metadata via AI.
     * @param _oracleAddress The address of the AI Oracle.
     */
    function setAIOracleAddress(address _oracleAddress) public onlyOwner {
        aiOracleAddress = _oracleAddress;
        emit AIOracleAddressSet(_oracleAddress, _msgSender());
    }

    /**
     * @dev Allows the AI Oracle to update the metadata URI of a dynamic NFT.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataURI The new metadata URI for the NFT.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public onlyAIOracle {
        require(_exists(_tokenId), "NFT does not exist");
        _tokenMetadataURIs[_tokenId] = _newMetadataURI;
        _metadataUpdateHistory[_tokenId].push(_newMetadataURI);
        emit MetadataUpdated(_tokenId, _newMetadataURI, _msgSender());
    }

    /**
     * @dev Gets the current metadata URI of a dynamic NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current metadata URI.
     */
    function getCurrentMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return _tokenMetadataURIs[_tokenId];
    }

    /**
     * @dev Retrieves the history of metadata URIs for a dynamic NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of metadata URI history.
     */
    function getMetadataUpdateHistory(uint256 _tokenId) public view returns (string[] memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return _metadataUpdateHistory[_tokenId];
    }

    // 3. Marketplace Listing and Trading

    /**
     * @dev Lists an NFT for sale in the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price to list the NFT for (in wei).
     */
    function listItemForSale(uint256 _tokenId, uint256 _price) public payable nftOwnerOrApproved(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftToListingId[_tokenId] == 0, "NFT already listed");
        require(_price > 0, "Price must be greater than 0");

        _listingIdCounter.increment();
        uint256 listingId = _listingIdCounter.current();

        listings[listingId] = Listing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });
        nftToListingId[_tokenId] = listingId;

        _approve(address(this), _tokenId); // Approve marketplace to handle transfer
        emit ItemListed(listingId, _tokenId, _msgSender(), _price);
    }

    /**
     * @dev Delists an NFT from sale in the marketplace.
     * @param _tokenId The ID of the NFT to delist.
     */
    function delistItemFromSale(uint256 _tokenId) public payable nftOwnerOrApproved(_tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 listingId = nftToListingId[_tokenId];
        require(listingId != 0, "NFT is not listed");
        require(listings[listingId].isActive, "Listing is not active");
        require(listings[listingId].seller == _msgSender() || isApprovedOperator(_msgSender(), _tokenId), "Not the seller or approved operator");

        listings[listingId].isActive = false;
        delete nftToListingId[_tokenId]; // Remove listing association
        emit ItemDelisted(listingId, _tokenId);
    }

    /**
     * @dev Allows anyone to buy a listed NFT.
     * @param _listingId The ID of the listing to buy.
     */
    function buyItem(uint256 _listingId) public payable {
        require(listings[_listingId].isActive, "Listing is not active");
        require(msg.value >= listings[_listingId].price, "Insufficient funds");

        Listing memory listing = listings[_listingId];
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listings[_listingId].isActive = false; // Deactivate listing

        // Transfer NFT
        _transfer(seller, _msgSender(), tokenId);

        // Platform Fee Calculation and Transfer
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerPayout = price - platformFee;

        // Transfer funds
        payable(owner()).transfer(platformFee); // Platform fee to owner
        payable(seller).transfer(sellerPayout);  // Seller payout

        delete nftToListingId[tokenId]; // Remove listing association

        emit ItemBought(_listingId, tokenId, _msgSender(), price);
    }

    /**
     * @dev Allows users to make offers to buy NFTs not currently listed.
     * @param _tokenId The ID of the NFT to make an offer for.
     * @param _price The price offered (in wei).
     */
    function offerForItem(uint256 _tokenId, uint256 _price) public payable {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftToListingId[_tokenId] == 0, "NFT is currently listed for sale, use buyItem"); // Optional: Decide if offers are allowed on listed items
        require(_price > 0, "Offer price must be greater than 0");

        _offerIdCounter.increment();
        uint256 offerId = _offerIdCounter.current();

        offers[offerId] = Offer({
            offerId: offerId,
            tokenId: _tokenId,
            offerer: _msgSender(),
            price: _price,
            isActive: true
        });
        nftToOfferIds[_tokenId].push(offerId);

        emit OfferMade(offerId, _tokenId, _msgSender(), _price);
    }

    /**
     * @dev Allows the NFT owner to accept a specific offer.
     * @param _offerId The ID of the offer to accept.
     */
    function acceptOffer(uint256 _offerId) public payable nftOwnerOrApproved(offers[_offerId].tokenId) {
        require(offers[_offerId].isActive, "Offer is not active");
        Offer memory offer = offers[_offerId];
        require(offer.offerer != address(0), "Invalid offerer address"); // Sanity check
        require(offer.tokenId != 0, "Invalid token ID in offer");       // Sanity check

        uint256 tokenId = offer.tokenId;
        address offerer = offer.offerer;
        uint256 price = offer.price;

        offers[_offerId].isActive = false; // Deactivate offer

        // Transfer NFT
        _transfer(ownerOf(tokenId), offerer, tokenId);

        // Platform Fee Calculation and Transfer
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 sellerPayout = price - platformFee;

        // Transfer funds
        payable(owner()).transfer(platformFee); // Platform fee to owner
        payable(ownerOf(tokenId)).transfer(sellerPayout); // Seller (current owner) payout

        // Clean up offers for this token (optional, or keep history)
        // Consider removing offerId from nftToOfferIds mapping if needed

        emit OfferAccepted(_offerId, tokenId, ownerOf(tokenId), offerer, price);
    }

    /**
     * @dev Allows the offer maker to cancel their offer.
     * @param _offerId The ID of the offer to cancel.
     */
    function cancelOffer(uint256 _offerId) public {
        require(offers[_offerId].isActive, "Offer is not active");
        require(offers[_offerId].offerer == _msgSender(), "Only offerer can cancel");

        offers[_offerId].isActive = false;
        emit OfferCancelled(_offerId, offers[_offerId].tokenId, _msgSender());
    }

    // 4. AI Model Parameter Management (Simplified)

    /**
     * @dev (Simplified) Sets a parameter for the AI model influence.
     * @param _parameterName The name of the parameter.
     * @param _parameterValue The value of the parameter.
     */
    function setAIModelParameter(string memory _parameterName, uint256 _parameterValue) public onlyAIOracle {
        aiModelParameters[_parameterName] = _parameterValue;
        emit AIModelParameterSet(_parameterName, _parameterValue, _msgSender());
    }

    /**
     * @dev (Simplified) Retrieves a specific AI model parameter.
     * @param _parameterName The name of the parameter.
     * @return The value of the parameter.
     */
    function getAIModelParameter(string memory _parameterName) public view returns (uint256) {
        return aiModelParameters[_parameterName];
    }

    // 5. Governance and Platform Features (Simplified)

    /**
     * @dev Allows users to propose new features for the platform.
     * @param _featureDescription A description of the proposed feature.
     */
    function proposePlatformFeature(string memory _featureDescription) public {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: _featureDescription,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false
        });
        emit FeatureProposed(proposalId, _featureDescription, _msgSender());
    }

    /**
     * @dev Allows (placeholder) voting on platform feature proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        // In a real implementation, voting logic would be more sophisticated
        // (e.g., based on token ownership, staking, DAO membership, etc.)
        if (_support) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev (Placeholder) Executes an approved platform feature proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyOwner {
        require(proposals[_proposalId].isActive, "Proposal is not active");
        require(!proposals[_proposalId].isExecuted, "Proposal already executed");
        // In a real implementation, execution logic would depend on the proposal
        // and might involve complex state changes or external calls.
        proposals[_proposalId].isExecuted = true;
        proposals[_proposalId].isActive = false; // Mark as inactive after execution
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Sets the platform fee percentage for marketplace sales.
     * @param _feePercentage The new platform fee percentage (0-100).
     */
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage must be <= 100");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage, _msgSender());
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw");
        payable(owner()).transfer(balance);
        emit PlatformFeesWithdrawn(balance, _msgSender());
    }

    // 6. Utility and Information Functions

    /**
     * @dev Returns the name of the platform.
     * @return The platform name.
     */
    function getPlatformName() public view returns (string memory) {
        return platformName;
    }

    /**
     * @dev Returns the version of the platform.
     * @return The platform version.
     */
    function getPlatformVersion() public view returns (string memory) {
        return platformVersion;
    }

    /**
     * @dev Checks if an NFT is currently listed for sale.
     * @param _tokenId The ID of the NFT.
     * @return True if listed, false otherwise.
     */
    function isListedForSale(uint256 _tokenId) public view returns (bool) {
        return nftToListingId[_tokenId] != 0 && listings[nftToListingId[_tokenId]].isActive;
    }

    /**
     * @dev Retrieves details of a listing for a given NFT (if listed).
     * @param _tokenId The ID of the NFT.
     * @return Listing details struct if listed, otherwise default struct.
     */
    function getListingDetails(uint256 _tokenId) public view returns (Listing memory) {
        uint256 listingId = nftToListingId[_tokenId];
        if (listingId != 0 && listings[listingId].isActive) {
            return listings[listingId];
        } else {
            return Listing(0, 0, address(0), 0, false); // Return default struct if not listed
        }
    }

    /**
     * @dev Retrieves details of a specific offer.
     * @param _offerId The ID of the offer.
     * @return Offer details struct.
     */
    function getOfferDetails(uint256 _offerId) public view returns (Offer memory) {
        return offers[_offerId];
    }

    // Modifiers

    modifier onlyAIOracle() {
        require(_msgSender() == aiOracleAddress, "Only AI Oracle can call this function");
        _;
    }

    modifier nftOwnerOrApproved(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender() || getApproved(_tokenId) == _msgSender() || isApprovedForAll(ownerOf(_tokenId), _msgSender()), "Not NFT owner or approved operator");
        _;
    }

    // Override _beforeTokenTransfer to potentially add checks before transfers (e.g., pausing transfers, etc.)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
        // Add any custom logic here before token transfer if needed.
    }

    // Override tokenURI if you want to resolve metadata dynamically from the contract itself (less common for dynamic NFTs with external metadata)
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    //     return _tokenMetadataURIs[tokenId]; // Or potentially build URI dynamically
    // }
}
```