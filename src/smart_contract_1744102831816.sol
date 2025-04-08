```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Decentralized Dynamic NFT Marketplace with Evolving Traits and Community Governance
 * @author Bard (Example Smart Contract - Conceptual and Not Audited)
 * @notice This contract implements a dynamic NFT marketplace where NFTs can evolve based on certain conditions,
 *         and the community can participate in governance aspects of the marketplace.
 *
 * ## Contract Outline and Function Summary:
 *
 * ### 1. NFT Management & Creation
 *    - `createDynamicNFT(string memory _uri, string memory _initialTrait)`: Mints a new Dynamic NFT with initial URI and trait.
 *    - `setBaseURI(string memory _baseURI)`: Sets the base URI for all NFTs (Owner only).
 *    - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows the NFT owner to update the metadata URI.
 *    - `getNFTTrait(uint256 _tokenId)`: Retrieves the current trait of a specific NFT.
 *    - `evolveNFT(uint256 _tokenId)`: Triggers the evolution logic for an NFT based on certain criteria.
 *
 * ### 2. Marketplace Functionality
 *    - `listItemForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale in the marketplace.
 *    - `unlistItemForSale(uint256 _tokenId)`: Removes an NFT listing from the marketplace.
 *    - `buyNFT(uint256 _tokenId)`: Allows anyone to purchase an NFT listed for sale.
 *    - `getListingPrice(uint256 _tokenId)`: Retrieves the current listing price of an NFT.
 *    - `isListed(uint256 _tokenId)`: Checks if an NFT is currently listed for sale.
 *    - `getAllListedNFTs()`: Returns a list of all token IDs currently listed for sale.
 *
 * ### 3. Dynamic Trait Evolution Logic
 *    - `setEvolutionCriteria(uint256 _tokenId, string memory _criteria)`: Sets custom evolution criteria for a specific NFT (Owner/Creator control).
 *    - `getEvolutionCriteria(uint256 _tokenId)`: Retrieves the evolution criteria for a specific NFT.
 *    - `triggerExternalEvolutionEvent(uint256 _tokenId, string memory _eventData)`: Allows an authorized external entity to trigger evolution based on off-chain events.
 *    - `setEvolutionLogicContract(address _evolutionLogicContract)`: Sets the address of an external contract containing complex evolution logic (Owner only).
 *
 * ### 4. Community Governance (Simple Example)
 *    - `proposeTraitEvolution(uint256 _tokenId, string memory _newTrait)`: Allows NFT holders to propose a new trait for an NFT evolution (requires voting).
 *    - `voteOnEvolutionProposal(uint256 _proposalId, bool _vote)`: Allows NFT holders to vote on a trait evolution proposal.
 *    - `executeEvolutionProposal(uint256 _proposalId)`: Executes an approved evolution proposal (Owner/Governance controlled).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific evolution proposal.
 *    - `getOpenProposalsForNFT(uint256 _tokenId)`: Returns a list of open proposals for a specific NFT.
 *
 * ### 5. Utility and Admin Functions
 *    - `withdrawMarketplaceBalance()`: Allows the contract owner to withdraw accumulated marketplace fees.
 *    - `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage (Owner only).
 *    - `getMarketplaceFee()`: Retrieves the current marketplace fee percentage.
 */
contract DynamicNFTMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    Counters.Counter private _tokenIdCounter;
    string private _baseURI;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee

    // Mapping from token ID to its current trait
    mapping(uint256 => string) public nftTraits;
    // Mapping from token ID to its custom evolution criteria (if any)
    mapping(uint256 => string) public nftEvolutionCriteria;
    // Mapping from token ID to listing price (if listed)
    mapping(uint256 => uint256) public nftListings;
    // Set of token IDs currently listed for sale
    EnumerableSet.UintSet private _listedTokenIds;

    // Evolution Logic Contract (Optional - for complex logic)
    address public evolutionLogicContract;

    // Struct to represent an evolution proposal
    struct EvolutionProposal {
        uint256 tokenId;
        string proposedTrait;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => EnumerableSet.AddressSet) public proposalVoters; // Track voters per proposal

    event NFTCreated(uint256 tokenId, address creator, string initialTrait);
    event NFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event NFTTraitEvolved(uint256 tokenId, string newTrait, string reason);
    event NFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event NFTUnlistedFromSale(uint256 tokenId, address seller);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event EvolutionProposed(uint256 proposalId, uint256 tokenId, string proposedTrait, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event EvolutionExecuted(uint256 proposalId, uint256 tokenId, string newTrait);

    constructor(string memory _name, string memory _symbol, string memory _uri) ERC721(_name, _symbol) {
        _baseURI = _uri;
    }

    // --- 1. NFT Management & Creation ---

    /**
     * @dev Creates a new Dynamic NFT with a given URI and initial trait.
     * @param _uri The metadata URI for the NFT.
     * @param _initialTrait The initial trait of the NFT.
     */
    function createDynamicNFT(string memory _uri, string memory _initialTrait) public returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _uri);
        nftTraits[tokenId] = _initialTrait;
        emit NFTCreated(tokenId, msg.sender, _initialTrait);
        return tokenId;
    }

    /**
     * @dev Sets the base URI for all NFTs. Only contract owner can call this.
     * @param _baseURI The new base URI.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _baseURI = _baseURI;
    }

    /**
     * @dev Updates the metadata URI of a specific NFT. Only the NFT owner can call this.
     * @param _tokenId The ID of the NFT to update.
     * @param _newMetadataURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        _setTokenURI(_tokenId, _newMetadataURI);
        emit NFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Gets the current trait of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The current trait of the NFT.
     */
    function getNFTTrait(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        return nftTraits[_tokenId];
    }

    /**
     * @dev Triggers the evolution logic for an NFT.
     *      This is a simplified example. In a real application, evolution logic could be complex and depend on various factors.
     *      For now, it's a simple stage-based evolution.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        string memory currentTrait = nftTraits[_tokenId];
        string memory newTrait;

        // Example Simple Evolution Logic:
        if (keccak256(bytes(currentTrait)) == keccak256(bytes("Stage 1"))) {
            newTrait = "Stage 2";
        } else if (keccak256(bytes(currentTrait)) == keccak256(bytes("Stage 2"))) {
            newTrait = "Stage 3 - Advanced";
        } else {
            newTrait = currentTrait; // No further evolution in this simple example
        }

        if (keccak256(bytes(newTrait)) != keccak256(bytes(currentTrait))) {
            nftTraits[_tokenId] = newTrait;
            emit NFTTraitEvolved(_tokenId, newTrait, "Natural Evolution");
        }
    }

    // --- 2. Marketplace Functionality ---

    /**
     * @dev Lists an NFT for sale in the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei for which the NFT is listed.
     */
    function listItemForSale(uint256 _tokenId, uint256 _price) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        require(nftListings[_tokenId] == 0, "NFT already listed");
        require(_price > 0, "Price must be greater than zero");

        nftListings[_tokenId] = _price;
        _listedTokenIds.add(_tokenId);
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Unlists an NFT from sale in the marketplace.
     * @param _tokenId The ID of the NFT to unlist.
     */
    function unlistItemForSale(uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        require(nftListings[_tokenId] > 0, "NFT not listed");

        delete nftListings[_tokenId];
        _listedTokenIds.remove(_tokenId);
        emit NFTUnlistedFromSale(_tokenId, msg.sender);
    }

    /**
     * @dev Allows anyone to buy an NFT listed for sale.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyNFT(uint256 _tokenId) public payable {
        require(nftListings[_tokenId] > 0, "NFT not listed for sale");
        uint256 price = nftListings[_tokenId];
        require(msg.value >= price, "Insufficient funds to buy NFT");

        address seller = ERC721.ownerOf(_tokenId);
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerProceeds = price - marketplaceFee;

        delete nftListings[_tokenId];
        _listedTokenIds.remove(_tokenId);

        payable(seller).transfer(sellerProceeds);
        payable(owner()).transfer(marketplaceFee); // Marketplace fee goes to contract owner

        transferFrom(seller, msg.sender, _tokenId);
        emit NFTBought(_tokenId, msg.sender, seller, price);
    }

    /**
     * @dev Gets the listing price of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The listing price in wei, or 0 if not listed.
     */
    function getListingPrice(uint256 _tokenId) public view returns (uint256) {
        return nftListings[_tokenId];
    }

    /**
     * @dev Checks if an NFT is currently listed for sale.
     * @param _tokenId The ID of the NFT.
     * @return True if listed, false otherwise.
     */
    function isListed(uint256 _tokenId) public view returns (bool) {
        return nftListings[_tokenId] > 0;
    }

    /**
     * @dev Gets a list of all token IDs currently listed for sale.
     * @return An array of token IDs.
     */
    function getAllListedNFTs() public view returns (uint256[] memory) {
        return _listedTokenIds.values();
    }

    // --- 3. Dynamic Trait Evolution Logic ---

    /**
     * @dev Sets custom evolution criteria for a specific NFT. Can be used by owner or NFT creator (if different).
     * @param _tokenId The ID of the NFT.
     * @param _criteria A string describing the evolution criteria.
     */
    function setEvolutionCriteria(uint256 _tokenId, string memory _criteria) public {
        require(_isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == owner(), "Not authorized to set criteria");
        nftEvolutionCriteria[_tokenId] = _criteria;
    }

    /**
     * @dev Gets the evolution criteria for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The evolution criteria string.
     */
    function getEvolutionCriteria(uint256 _tokenId) public view returns (string memory) {
        return nftEvolutionCriteria[_tokenId];
    }

    /**
     * @dev Allows an authorized external entity (e.g., oracle, game server) to trigger evolution based on off-chain events.
     *      This is a placeholder for more complex external trigger mechanisms.
     * @param _tokenId The ID of the NFT to evolve.
     * @param _eventData String data representing the external event that triggers evolution.
     */
    function triggerExternalEvolutionEvent(uint256 _tokenId, string memory _eventData) public onlyOwner { // For simplicity, only owner can trigger in this example
        require(_exists(_tokenId), "NFT does not exist");
        string memory currentTrait = nftTraits[_tokenId];
        string memory newTrait = string(abi.encodePacked(currentTrait, " - Evolved by External Event: ", _eventData)); // Simple example of event-based evolution
        nftTraits[_tokenId] = newTrait;
        emit NFTTraitEvolved(_tokenId, newTrait, "External Event Triggered");
    }

    /**
     * @dev Sets the address of an external contract that contains complex evolution logic.
     *      This allows for more sophisticated and modular evolution rules.
     * @param _evolutionLogicContract The address of the external evolution logic contract.
     */
    function setEvolutionLogicContract(address _evolutionLogicContract) public onlyOwner {
        evolutionLogicContract = _evolutionLogicContract;
        // In a real implementation, you would likely want to interact with the external contract
        // within the evolveNFT or triggerExternalEvolutionEvent functions to execute complex logic.
    }

    // --- 4. Community Governance (Simple Example) ---

    /**
     * @dev Allows NFT holders to propose a new trait for an NFT evolution.
     * @param _tokenId The ID of the NFT to propose evolution for.
     * @param _newTrait The new trait being proposed.
     */
    function proposeTraitEvolution(uint256 _tokenId, string memory _newTrait) public {
        require(ownerOf(_tokenId) == msg.sender, "Only NFT owner can propose evolution");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        evolutionProposals[proposalId] = EvolutionProposal({
            tokenId: _tokenId,
            proposedTrait: _newTrait,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        });
        emit EvolutionProposed(proposalId, _tokenId, _newTrait, msg.sender);
    }

    /**
     * @dev Allows NFT holders to vote on a trait evolution proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True to vote for, false to vote against.
     */
    function voteOnEvolutionProposal(uint256 _proposalId, bool _vote) public {
        require(evolutionProposals[_proposalId].isActive, "Proposal is not active");
        require(ownerOf(evolutionProposals[_proposalId].tokenId) == msg.sender, "Only NFT owner can vote");
        require(!proposalVoters[_proposalId].contains(msg.sender), "Already voted on this proposal");

        proposalVoters[_proposalId].add(msg.sender);
        if (_vote) {
            evolutionProposals[_proposalId].votesFor++;
        } else {
            evolutionProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes an approved evolution proposal. In this simple example, if 'votesFor' is significantly higher than 'votesAgainst'.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeEvolutionProposal(uint256 _proposalId) public onlyOwner { // For simplicity, only owner can execute in this example governance
        require(evolutionProposals[_proposalId].isActive, "Proposal is not active");
        require(evolutionProposals[_proposalId].votesFor > evolutionProposals[_proposalId].votesAgainst * 2, "Proposal not approved by community"); // Simple approval threshold

        uint256 tokenId = evolutionProposals[_proposalId].tokenId;
        string memory newTrait = evolutionProposals[_proposalId].proposedTrait;

        nftTraits[tokenId] = newTrait;
        evolutionProposals[_proposalId].isActive = false; // Mark proposal as executed/inactive
        emit EvolutionExecuted(_proposalId, tokenId, newTrait);
        emit NFTTraitEvolved(tokenId, newTrait, "Community Governance Evolution");
    }

    /**
     * @dev Gets details of a specific evolution proposal.
     * @param _proposalId The ID of the proposal.
     * @return Details of the evolution proposal.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (EvolutionProposal memory) {
        return evolutionProposals[_proposalId];
    }

    /**
     * @dev Gets a list of open proposals for a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return An array of proposal IDs.
     */
    function getOpenProposalsForNFT(uint256 _tokenId) public view returns (uint256[] memory) {
        uint256[] memory openProposals = new uint256[](_proposalIdCounter.current()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= _proposalIdCounter.current(); i++) {
            if (evolutionProposals[i].isActive && evolutionProposals[i].tokenId == _tokenId) {
                openProposals[count] = i;
                count++;
            }
        }
        // Resize the array to the actual number of open proposals
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = openProposals[i];
        }
        return result;
    }


    // --- 5. Utility and Admin Functions ---

    /**
     * @dev Allows the contract owner to withdraw accumulated marketplace balance (fees).
     */
    function withdrawMarketplaceBalance() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Sets the marketplace fee percentage. Only contract owner can call this.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100");
        marketplaceFeePercentage = _feePercentage;
    }

    /**
     * @dev Gets the current marketplace fee percentage.
     * @return The marketplace fee percentage.
     */
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    // Override _baseURI to use the contract's base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    // The following functions are overrides required by Solidity compiler to inherit from ERC721 and Ownable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```