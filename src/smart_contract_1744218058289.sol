```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with On-Chain Evolution and Community Curation
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract implementing a Dynamic NFT marketplace with features like:
 *      - Dynamic NFTs that can evolve and change their metadata based on on-chain events and community votes.
 *      - Decentralized marketplace for trading these Dynamic NFTs with advanced listing and bidding options.
 *      - On-chain evolution mechanisms allowing NFTs to upgrade, morph, or gain new attributes.
 *      - Community curation features for influencing NFT evolution paths and marketplace parameters.
 *      - Staking and reward mechanisms for community participants.
 *      - Reputation system based on community contributions.
 *      - Advanced access control and governance features.
 *
 * Function Outline:
 * 1. initializeContract(): Initializes the contract with basic parameters and admin.
 * 2. createDynamicNFTCollection(string _name, string _symbol, string _baseURI): Creates a new Dynamic NFT collection.
 * 3. mintDynamicNFT(uint256 _collectionId, address _to, string _initialMetadataURI): Mints a new Dynamic NFT within a collection.
 * 4. updateNFTMetadata(uint256 _collectionId, uint256 _tokenId, string _newMetadataURI): Allows NFT owner to update their NFT's metadata.
 * 5. evolveNFT(uint256 _collectionId, uint256 _tokenId, uint256 _evolutionType): Triggers an on-chain evolution event for an NFT.
 * 6. proposeEvolutionPath(uint256 _collectionId, uint256 _tokenId, uint256 _proposedEvolutionType, string _rationale): Allows community to propose evolution paths for NFTs.
 * 7. voteOnEvolutionPath(uint256 _proposalId, bool _vote): Allows community members to vote on proposed evolution paths.
 * 8. executeEvolutionPath(uint256 _proposalId): Executes a successful evolution path proposal.
 * 9. listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price): Allows NFT owner to list their NFT for sale at a fixed price.
 * 10. cancelNFTSale(uint256 _collectionId, uint256 _tokenId): Allows NFT owner to cancel their NFT sale listing.
 * 11. buyNFT(uint256 _collectionId, uint256 _tokenId): Allows anyone to buy a listed NFT.
 * 12. placeBidOnNFT(uint256 _collectionId, uint256 _tokenId, uint256 _bidAmount): Allows anyone to place a bid on an NFT (if auction enabled).
 * 13. acceptNFTOffer(uint256 _collectionId, uint256 _tokenId, uint256 _bidId): Allows NFT owner to accept a specific bid for their NFT.
 * 14. withdrawNFTBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId): Allows bidder to withdraw their bid.
 * 15. setMarketplaceFee(uint256 _feePercentage): Allows admin to set the marketplace fee percentage.
 * 16. withdrawMarketplaceFees(): Allows admin to withdraw accumulated marketplace fees.
 * 17. stakeTokensForVotingPower(uint256 _amount): Allows users to stake tokens to gain voting power in community decisions.
 * 18. unstakeTokens(uint256 _amount): Allows users to unstake their tokens.
 * 19. getVotingPower(address _user): Returns the voting power of a user based on their staked tokens.
 * 20. setBaseURIForCollection(uint256 _collectionId, string _newBaseURI): Allows collection owner to update the base URI for a collection.
 * 21. pauseContract(): Pauses most contract functionalities for emergency or maintenance.
 * 22. unpauseContract(): Resumes contract functionalities after pausing.
 * 23. getContractVersion(): Returns the version of the smart contract.
 * 24. getNFTCollectionDetails(uint256 _collectionId): Returns details of a specific NFT collection.
 * 25. getNFTSaleDetails(uint256 _collectionId, uint256 _tokenId): Returns details of a specific NFT sale listing.
 * 26. getNFTMetadataURI(uint256 _collectionId, uint256 _tokenId): Returns the current metadata URI for an NFT, considering dynamic updates.
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFTMarketplace is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Contract Metadata
    string public contractName = "Dynamic NFT Marketplace";
    string public contractVersion = "1.0.0";

    // Marketplace Fee
    uint256 public marketplaceFeePercentage = 2; // 2% default fee
    address payable public feeRecipient;

    // NFT Collection Management
    Counters.Counter private _collectionIds;
    mapping(uint256 => NFTCollection) public nftCollections;

    struct NFTCollection {
        string name;
        string symbol;
        string baseURI;
        address owner;
        Counters.Counter tokenIds;
    }

    // Dynamic NFT Metadata Management
    mapping(uint256 => mapping(uint256 => string)) public nftMetadataURIs; // collectionId => tokenId => metadataURI

    // NFT Evolution Management
    enum EvolutionType { UPGRADE, MORPH, ATTRIBUTE_GAIN } // Example evolution types
    mapping(uint256 => mapping(uint256 => EvolutionType)) public nftEvolutionHistory; // collectionId => tokenId => lastEvolutionType

    // Evolution Proposal and Voting
    Counters.Counter private _proposalIds;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;

    struct EvolutionProposal {
        uint256 collectionId;
        uint256 tokenId;
        EvolutionType proposedEvolutionType;
        string rationale;
        address proposer;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
    }

    // Marketplace Listing and Bidding
    struct SaleListing {
        uint256 collectionId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => mapping(uint256 => SaleListing)) public nftListings; // collectionId => tokenId => SaleListing

    struct Bid {
        uint256 bidId;
        address bidder;
        uint256 bidAmount;
        bool isActive;
    }
    mapping(uint256 => mapping(uint256 => mapping(uint256 => Bid))) public nftBids; // collectionId => tokenId => bidId => Bid
    Counters.Counter private _bidIds;

    // Staking and Voting Power
    mapping(address => uint256) public stakedBalances;
    uint256 public stakingRatio = 100; // 1 token staked = 100 voting power (example)

    // Events
    event CollectionCreated(uint256 collectionId, string name, string symbol, address owner);
    event NFTMinted(uint256 collectionId, uint256 tokenId, address to, string metadataURI);
    event NFTMetadataUpdated(uint256 collectionId, uint256 tokenId, string newMetadataURI);
    event NFTEvolved(uint256 collectionId, uint256 tokenId, EvolutionType evolutionType);
    event EvolutionPathProposed(uint256 proposalId, uint256 collectionId, uint256 tokenId, EvolutionType proposedEvolutionType, address proposer);
    event EvolutionPathVoted(uint256 proposalId, address voter, bool vote);
    event EvolutionPathExecuted(uint256 proposalId);
    event NFTListedForSale(uint256 collectionId, uint256 tokenId, uint256 price, address seller);
    event NFTSaleCancelled(uint256 collectionId, uint256 tokenId);
    event NFTBought(uint256 collectionId, uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTBidPlaced(uint256 collectionId, uint256 tokenId, uint256 bidId, address bidder, uint256 bidAmount);
    event NFTBidAccepted(uint256 collectionId, uint256 tokenId, uint256 bidId, address seller, address bidder, uint256 bidAmount);
    event NFTBidWithdrawn(uint256 collectionId, uint256 tokenId, uint256 bidId, address bidder);
    event MarketplaceFeeSet(uint256 feePercentage, address recipient);
    event MarketplaceFeesWithdrawn(uint256 amount, address recipient);
    event TokensStaked(address user, uint256 amount);
    event TokensUnstaked(address user, uint256 amount);
    event BaseURISet(uint256 collectionId, string newBaseURI);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // Modifier to check if the caller is the collection owner
    modifier onlyCollectionOwner(uint256 _collectionId) {
        require(nftCollections[_collectionId].owner == _msgSender(), "Caller is not the collection owner");
        _;
    }

    // Modifier to check if the caller is the NFT owner
    modifier onlyNFTOwner(uint256 _collectionId, uint256 _tokenId) {
        address owner = ownerOf(getNFTTokenId(_collectionId, _tokenId));
        require(owner == _msgSender(), "Caller is not the NFT owner");
        _;
    }

    // Modifier to check if the contract is paused
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // Modifier to check if the contract is not paused
    modifier whenPaused() {
        require(paused(), "Contract is not paused");
        _;
    }


    constructor(address payable _feeRecipient) ERC721("DynamicNFTMarketplace", "DNM") Ownable() {
        feeRecipient = _feeRecipient;
    }

    /**
     * @dev Initializes the contract. (Currently handled in constructor, can be expanded)
     */
    function initializeContract() public onlyOwner {
        // Additional initialization logic if needed beyond constructor.
        // For now, constructor handles basic setup.
    }

    /**
     * @dev Creates a new Dynamic NFT collection.
     * @param _name The name of the NFT collection.
     * @param _symbol The symbol of the NFT collection.
     * @param _baseURI The base URI for the collection's metadata.
     */
    function createDynamicNFTCollection(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) public onlyOwner whenNotPaused {
        _collectionIds.increment();
        uint256 collectionId = _collectionIds.current();
        nftCollections[collectionId] = NFTCollection({
            name: _name,
            symbol: _symbol,
            baseURI: _baseURI,
            owner: _msgSender(),
            tokenIds: Counters.Counter(0)
        });
        emit CollectionCreated(collectionId, _name, _symbol, _msgSender());
    }

    /**
     * @dev Mints a new Dynamic NFT within a specific collection.
     * @param _collectionId The ID of the NFT collection.
     * @param _to The address to mint the NFT to.
     * @param _initialMetadataURI The initial metadata URI for the NFT.
     */
    function mintDynamicNFT(
        uint256 _collectionId,
        address _to,
        string memory _initialMetadataURI
    ) public onlyCollectionOwner(_collectionId) whenNotPaused {
        nftCollections[_collectionId].tokenIds.increment();
        uint256 tokenId = nftCollections[_collectionId].tokenIds.current();
        uint256 fullTokenId = getNFTTokenId(_collectionId, tokenId);
        _safeMint(_to, fullTokenId);
        nftMetadataURIs[_collectionId][tokenId] = _initialMetadataURI;
        emit NFTMinted(_collectionId, tokenId, _to, _initialMetadataURI);
    }

    /**
     * @dev Allows NFT owner to update their NFT's metadata URI.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _newMetadataURI The new metadata URI for the NFT.
     */
    function updateNFTMetadata(
        uint256 _collectionId,
        uint256 _tokenId,
        string memory _newMetadataURI
    ) public onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        nftMetadataURIs[_collectionId][_tokenId] = _newMetadataURI;
        emit NFTMetadataUpdated(_collectionId, _tokenId, _newMetadataURI);
    }

    /**
     * @dev Triggers an on-chain evolution event for an NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _evolutionType The type of evolution event (e.g., UPGRADE, MORPH).
     */
    function evolveNFT(
        uint256 _collectionId,
        uint256 _tokenId,
        uint256 _evolutionType
    ) public onlyCollectionOwner(_collectionId) whenNotPaused { // For simplicity, only collection owner can trigger evolution
        // In a real-world scenario, evolution might be triggered by various on-chain events or oracles.
        nftEvolutionHistory[_collectionId][_tokenId] = EvolutionType(_evolutionType);
        // Here, you would typically implement logic to update the NFT's metadata or on-chain attributes
        // based on the _evolutionType. For example, you might fetch new metadata from IPFS based on evolution type.
        string memory newMetadataURI = string(abi.encodePacked(nftCollections[_collectionId].baseURI, "/", Strings.toString(_tokenId), "/", Strings.toString(_evolutionType), ".json"));
        nftMetadataURIs[_collectionId][_tokenId] = newMetadataURI; // Example: Update metadata based on evolution type
        emit NFTEvolved(_collectionId, _tokenId, EvolutionType(_evolutionType));
    }

    /**
     * @dev Allows community to propose evolution paths for NFTs.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _proposedEvolutionType The proposed evolution type.
     * @param _rationale A brief rationale for the proposed evolution.
     */
    function proposeEvolutionPath(
        uint256 _collectionId,
        uint256 _tokenId,
        uint256 _proposedEvolutionType,
        string memory _rationale
    ) public whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        evolutionProposals[proposalId] = EvolutionProposal({
            collectionId: _collectionId,
            tokenId: _tokenId,
            proposedEvolutionType: EvolutionType(_proposedEvolutionType),
            rationale: _rationale,
            proposer: _msgSender(),
            upvotes: 0,
            downvotes: 0,
            executed: false
        });
        emit EvolutionPathProposed(proposalId, _collectionId, _tokenId, EvolutionType(_proposedEvolutionType), _msgSender());
    }

    /**
     * @dev Allows community members to vote on proposed evolution paths.
     * @param _proposalId The ID of the evolution proposal.
     * @param _vote True for upvote, false for downvote.
     */
    function voteOnEvolutionPath(uint256 _proposalId, bool _vote) public whenNotPaused {
        require(!evolutionProposals[_proposalId].executed, "Proposal already executed");
        // In a real-world scenario, voting power would be determined by staked tokens or other reputation mechanisms.
        // For simplicity, every address has equal voting power here.
        if (_vote) {
            evolutionProposals[_proposalId].upvotes++;
        } else {
            evolutionProposals[_proposalId].downvotes++;
        }
        emit EvolutionPathVoted(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes a successful evolution path proposal if it reaches a quorum.
     * @param _proposalId The ID of the evolution proposal.
     */
    function executeEvolutionPath(uint256 _proposalId) public whenNotPaused {
        require(!evolutionProposals[_proposalId].executed, "Proposal already executed");
        // Example quorum: More upvotes than downvotes (can be adjusted)
        require(evolutionProposals[_proposalId].upvotes > evolutionProposals[_proposalId].downvotes, "Proposal not approved by community");

        uint256 collectionId = evolutionProposals[_proposalId].collectionId;
        uint256 tokenId = evolutionProposals[_proposalId].tokenId;
        EvolutionType proposedEvolutionType = evolutionProposals[_proposalId].proposedEvolutionType;

        evolveNFT(collectionId, tokenId, uint256(proposedEvolutionType)); // Execute the evolution

        evolutionProposals[_proposalId].executed = true;
        emit EvolutionPathExecuted(_proposalId);
    }

    /**
     * @dev Allows NFT owner to list their NFT for sale at a fixed price.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _price The sale price in wei.
     */
    function listNFTForSale(uint256 _collectionId, uint256 _tokenId, uint256 _price) public onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        require(nftListings[_collectionId][_tokenId].isActive == false, "NFT already listed for sale");
        _approve(address(this), getNFTTokenId(_collectionId, _tokenId)); // Approve contract to handle transfer
        nftListings[_collectionId][_tokenId] = SaleListing({
            collectionId: _collectionId,
            tokenId: _tokenId,
            seller: _msgSender(),
            price: _price,
            isActive: true
        });
        emit NFTListedForSale(_collectionId, _tokenId, _price, _msgSender());
    }

    /**
     * @dev Allows NFT owner to cancel their NFT sale listing.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     */
    function cancelNFTSale(uint256 _collectionId, uint256 _tokenId) public onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        require(nftListings[_collectionId][_tokenId].isActive == true, "NFT not listed for sale");
        nftListings[_collectionId][_tokenId].isActive = false;
        emit NFTSaleCancelled(_collectionId, _tokenId);
    }

    /**
     * @dev Allows anyone to buy a listed NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     */
    function buyNFT(uint256 _collectionId, uint256 _tokenId) public payable whenNotPaused {
        require(nftListings[_collectionId][_tokenId].isActive == true, "NFT not listed for sale");
        SaleListing storage listing = nftListings[_collectionId][_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        uint256 feeAmount = (listing.price * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = listing.price - feeAmount;

        // Transfer NFT
        _transfer(listing.seller, _msgSender(), getNFTTokenId(_collectionId, _tokenId));

        // Pay seller and marketplace fee
        payable(listing.seller).transfer(sellerAmount);
        feeRecipient.transfer(feeAmount);

        listing.isActive = false; // Deactivate listing

        emit NFTBought(_collectionId, _tokenId, _msgSender(), listing.seller, listing.price);
    }

    /**
     * @dev Allows anyone to place a bid on an NFT (if auction enabled - not fully implemented in this example).
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _bidAmount The bid amount in wei.
     */
    function placeBidOnNFT(uint256 _collectionId, uint256 _tokenId, uint256 _bidAmount) public payable whenNotPaused {
        require(msg.value >= _bidAmount, "Bid amount must be equal to or greater than sent value");
        require(nftListings[_collectionId][_tokenId].isActive == true, "NFT is not listed for sale"); // For simplicity, bidding on listed NFTs only

        _bidIds.increment();
        uint256 bidId = _bidIds.current();
        nftBids[_collectionId][_tokenId][bidId] = Bid({
            bidId: bidId,
            bidder: _msgSender(),
            bidAmount: _bidAmount,
            isActive: true
        });

        emit NFTBidPlaced(_collectionId, _tokenId, bidId, _msgSender(), _bidAmount);
    }

    /**
     * @dev Allows NFT owner to accept a specific bid for their NFT.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _bidId The ID of the bid to accept.
     */
    function acceptNFTOffer(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) public onlyNFTOwner(_collectionId, _tokenId) whenNotPaused {
        require(nftListings[_collectionId][_tokenId].isActive == true, "NFT not listed for sale");
        require(nftBids[_collectionId][_tokenId][_bidId].isActive == true, "Bid is not active");
        Bid storage bidToAccept = nftBids[_collectionId][_tokenId][_bidId];

        uint256 feeAmount = (bidToAccept.bidAmount * marketplaceFeePercentage) / 100;
        uint256 sellerAmount = bidToAccept.bidAmount - feeAmount;

        // Transfer NFT
        _transfer(nftListings[_collectionId][_tokenId].seller, bidToAccept.bidder, getNFTTokenId(_collectionId, _tokenId));

        // Pay seller and marketplace fee
        payable(nftListings[_collectionId][_tokenId].seller).transfer(sellerAmount);
        feeRecipient.transfer(feeAmount);

        // Deactivate listing and all bids for this NFT
        nftListings[_collectionId][_tokenId].isActive = false;
        deactivateAllBids(_collectionId, _tokenId);

        emit NFTBidAccepted(_collectionId, _tokenId, _bidId, nftListings[_collectionId][_tokenId].seller, bidToAccept.bidder, bidToAccept.bidAmount);
    }

    /**
     * @dev Allows bidder to withdraw their bid.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @param _bidId The ID of the bid to withdraw.
     */
    function withdrawNFTBid(uint256 _collectionId, uint256 _tokenId, uint256 _bidId) public whenNotPaused {
        require(nftBids[_collectionId][_tokenId][_bidId].bidder == _msgSender(), "Only bidder can withdraw bid");
        require(nftBids[_collectionId][_tokenId][_bidId].isActive == true, "Bid is not active");
        Bid storage bidToWithdraw = nftBids[_collectionId][_tokenId][_bidId];

        bidToWithdraw.isActive = false;
        payable(_msgSender()).transfer(bidToWithdraw.bidAmount); // Return bid amount to bidder

        emit NFTBidWithdrawn(_collectionId, _tokenId, _bidId, _msgSender());
    }

    /**
     * @dev Sets the marketplace fee percentage. Only callable by contract owner.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner whenNotPaused {
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeSet(_feePercentage, feeRecipient);
    }

    /**
     * @dev Allows admin to withdraw accumulated marketplace fees.
     */
    function withdrawMarketplaceFees() public onlyOwner whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Subtract any value sent with this transaction
        require(contractBalance > 0, "No marketplace fees to withdraw");
        feeRecipient.transfer(contractBalance);
        emit MarketplaceFeesWithdrawn(contractBalance, feeRecipient);
    }

    /**
     * @dev Allows users to stake tokens to gain voting power. (Simplified staking - needs token implementation in a real scenario)
     * @param _amount The amount of tokens to stake.
     */
    function stakeTokensForVotingPower(uint256 _amount) public whenNotPaused {
        // In a real implementation, you would integrate with an ERC20 token contract.
        // For simplicity, we're just updating an on-chain balance here.
        stakedBalances[_msgSender()] += _amount;
        emit TokensStaked(_msgSender(), _amount);
    }

    /**
     * @dev Allows users to unstake their tokens.
     * @param _amount The amount of tokens to unstake.
     */
    function unstakeTokens(uint256 _amount) public whenNotPaused {
        require(stakedBalances[_msgSender()] >= _amount, "Insufficient staked balance");
        stakedBalances[_msgSender()] -= _amount;
        emit TokensUnstaked(_msgSender(), _amount);
    }

    /**
     * @dev Returns the voting power of a user based on their staked tokens.
     * @param _user The address of the user.
     * @return The voting power of the user.
     */
    function getVotingPower(address _user) public view returns (uint256) {
        return stakedBalances[_user] * stakingRatio;
    }

    /**
     * @dev Allows collection owner to update the base URI for a collection.
     * @param _collectionId The ID of the NFT collection.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURIForCollection(uint256 _collectionId, string memory _newBaseURI) public onlyCollectionOwner(_collectionId) whenNotPaused {
        nftCollections[_collectionId].baseURI = _newBaseURI;
        emit BaseURISet(_collectionId, _newBaseURI);
    }

    /**
     * @dev Pauses the contract, preventing most functionalities. Only callable by contract owner.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(_msgSender());
    }

    /**
     * @dev Unpauses the contract, restoring functionalities. Only callable by contract owner.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(_msgSender());
    }

    /**
     * @dev Returns the version of the smart contract.
     * @return The contract version string.
     */
    function getContractVersion() public view returns (string memory) {
        return contractVersion;
    }

    /**
     * @dev Returns details of a specific NFT collection.
     * @param _collectionId The ID of the NFT collection.
     * @return NFTCollection struct containing collection details.
     */
    function getNFTCollectionDetails(uint256 _collectionId) public view returns (NFTCollection memory) {
        return nftCollections[_collectionId];
    }

    /**
     * @dev Returns details of a specific NFT sale listing.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @return SaleListing struct containing sale details.
     */
    function getNFTSaleDetails(uint256 _collectionId, uint256 _tokenId) public view returns (SaleListing memory) {
        return nftListings[_collectionId][_tokenId];
    }

    /**
     * @dev Returns the current metadata URI for an NFT, considering dynamic updates.
     * @param _collectionId The ID of the NFT collection.
     * @param _tokenId The ID of the NFT within the collection.
     * @return The metadata URI string.
     */
    function getNFTMetadataURI(uint256 _collectionId, uint256 _tokenId) public view override returns (string memory) {
        return nftMetadataURIs[_collectionId][_tokenId];
    }

    /**
     * @dev Internal helper function to get the full ERC721 token ID from collection and token IDs.
     */
    function getNFTTokenId(uint256 _collectionId, uint256 _tokenId) internal pure returns (uint256) {
        // Simple combined ID scheme: (collectionId << 128) | tokenId
        return (_collectionId << 128) | _tokenId;
    }

    /**
     * @dev Internal helper function to deactivate all bids for a specific NFT.
     */
    function deactivateAllBids(uint256 _collectionId, uint256 _tokenId) internal {
        uint256 bidCount = _bidIds.current(); // Assuming bidIds counter is somewhat related to total bids ever placed (can be optimized)
        for (uint256 i = 1; i <= bidCount; i++) {
            if (nftBids[_collectionId][_tokenId][i].isActive) {
                nftBids[_collectionId][_tokenId][i].isActive = false;
            }
        }
    }

    // Override _baseURI to use collection-specific base URIs
    function _baseURI() internal view virtual override returns (string memory) {
        return ""; // Base URI is handled per collection
    }

    // Override tokenURI to fetch dynamic metadata URI
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        uint256 collectionId = _tokenId >> 128;
        uint256 tokenId = _tokenId & ((1 << 128) - 1); // Mask to get lower 128 bits
        require(exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getNFTMetadataURI(collectionId, tokenId);
    }

    /**
     * @dev Override supportsInterface to indicate support for ERC721Enumerable.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```