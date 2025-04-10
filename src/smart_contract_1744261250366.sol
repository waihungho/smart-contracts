```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Reputation & Governance
 * @author Bard (AI Assistant)
 * @dev A sophisticated NFT marketplace with dynamic NFTs, reputation system for users, and decentralized governance.
 *
 * **Outline and Function Summary:**
 *
 * **Core Marketplace Functions:**
 * 1. `listItem(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale.
 * 2. `buyItem(uint256 _listingId)`: Allows users to purchase listed NFTs.
 * 3. `cancelListing(uint256 _listingId)`: Allows sellers to cancel their NFT listings.
 * 4. `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows sellers to update the price of their listed NFTs.
 * 5. `getActiveListings()`: Returns a list of currently active NFT listings.
 * 6. `getListingsBySeller(address _seller)`: Returns a list of listings created by a specific seller.
 * 7. `getListingsByNFT(uint256 _tokenId)`: Returns a list of listings for a specific NFT token ID.
 *
 * **Dynamic NFT Functions:**
 * 8. `mintNFT(string memory _baseURI)`: Mints a new Dynamic NFT with an initial base URI.
 * 9. `setTokenMetadataAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue)`: Allows the NFT owner to set custom metadata attributes for their NFT, making it dynamic.
 * 10. `getTokenMetadata(uint256 _tokenId)`: Returns the full dynamic metadata URI for a given NFT token ID.
 * 11. `setBaseURIExtension(string memory _extension)`: Allows the contract owner to set a default extension for base URIs (e.g., ".json").
 *
 * **Reputation System Functions:**
 * 12. `addReputation(address _user, uint256 _amount)`: Adds reputation points to a user's account (governance controlled).
 * 13. `subtractReputation(address _user, uint256 _amount)`: Subtracts reputation points from a user's account (governance controlled).
 * 14. `getReputation(address _user)`: Returns the current reputation points of a user.
 * 15. `setUserReputationLevel(address _user, string memory _level)`: Sets a custom reputation level string for a user (governance controlled, for display purposes).
 * 16. `getUserReputationLevel(address _user)`: Returns the custom reputation level string of a user.
 *
 * **Decentralized Governance Functions:**
 * 17. `createGovernanceProposal(string memory _description, bytes memory _calldata)`: Allows users with sufficient reputation to create governance proposals.
 * 18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows users with reputation to vote on active governance proposals.
 * 19. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal (governance controlled).
 * 20. `getProposalState(uint256 _proposalId)`: Returns the current state of a governance proposal (e.g., Active, Pending, Executed, Defeated).
 * 21. `setGovernanceThresholdReputation(uint256 _threshold)`: Allows governance to change the reputation required to create proposals.
 * 22. `getGovernanceThresholdReputation()`: Returns the current reputation threshold for creating proposals.
 *
 * **Admin/Utility Functions:**
 * 23. `setMarketplaceFee(uint256 _feePercentage)`: Allows the contract owner to set the marketplace fee percentage.
 * 24. `withdrawMarketplaceFees()`: Allows the contract owner to withdraw accumulated marketplace fees.
 * 25. `pauseMarketplace()`: Pauses core marketplace functions for emergency situations (owner only).
 * 26. `unpauseMarketplace()`: Unpauses core marketplace functions (owner only).
 * 27. `transferNFT(address _to, uint256 _tokenId)`: Allows the contract owner to transfer any NFT in the contract (emergency/admin function).
 * 28. `setReputationController(address _reputationController)`: Allows the contract owner to set the address authorized to modify reputation scores.
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example of using advanced concepts - Merkle Proofs (can be used for whitelisting in future updates)

contract DynamicNFTMarketplace is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _listingIdCounter;
    Counters.Counter private _proposalIdCounter;

    string public baseURIExtension = ".json"; // Default extension for base URIs

    // Marketplace Fee
    uint256 public marketplaceFeePercentage = 2; // 2% fee by default
    address payable public feeRecipient;

    // NFT Listing struct
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }

    mapping(uint256 => Listing) public listings; // listingId => Listing
    mapping(uint256 => uint256) public nftToListingId; // tokenId => listingId (for quick lookup)
    mapping(address => uint256[]) public sellerListings; // seller address => array of listingIds

    // Dynamic NFT Metadata
    mapping(uint256 => string) public tokenBaseURIs; // tokenId => base URI
    mapping(uint256 => mapping(string => string)) public tokenMetadataAttributes; // tokenId => attributeName => attributeValue

    // Reputation System
    mapping(address => uint256) public userReputation; // user address => reputation points
    mapping(address => string) public userReputationLevel; // user address => custom reputation level string (e.g., "Trusted Seller")
    address public reputationController; // Address authorized to modify reputation scores
    uint256 public governanceThresholdReputation = 1000; // Reputation required to create governance proposals

    // Governance System
    enum ProposalState { Active, Pending, Executed, Defeated }
    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        bytes calldata;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        uint256 createdBlock;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals; // proposalId => GovernanceProposal
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter address => hasVoted (true/false)
    uint256 public governanceVotingPeriodBlocks = 100; // Proposal voting period in blocks


    // Events
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, address seller, uint256 price);
    event ListingCancelled(uint256 listingId, uint256 tokenId, address seller);
    event ListingPriceUpdated(uint256 listingId, uint256 tokenId, uint256 newPrice);
    event DynamicNFTMinted(uint256 tokenId, address minter, string baseURI);
    event TokenMetadataAttributeSet(uint256 tokenId, string attributeName, string attributeValue);
    event ReputationAdded(address user, uint256 amount, address by);
    event ReputationSubtracted(address user, uint256 amount, address by);
    event ReputationLevelSet(address user, string level, address by);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event MarketplaceFeeUpdated(uint256 newFeePercentage, address by);
    event MarketplaceFeesWithdrawn(address recipient, uint256 amount);
    event MarketplacePaused(address by);
    event MarketplaceUnpaused(address by);


    constructor(string memory _name, string memory _symbol, address payable _feeRecipient) ERC721(_name, _symbol) {
        feeRecipient = _feeRecipient;
        reputationController = _msgSender(); // Initially owner is the reputation controller
    }

    // --- Core Marketplace Functions ---

    modifier validPrice(uint256 _price) {
        require(_price > 0, "Price must be greater than zero.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId, "Listing does not exist.");
        _;
    }

    modifier itemExists(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist.");
        _;
    }

    modifier isListingActive(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier isSeller(uint256 _listingId) {
        require(listings[_listingId].seller == _msgSender(), "You are not the seller.");
        _;
    }

    modifier whenNotPausedMarketplace() {
        require(!paused(), "Marketplace is paused.");
        _;
    }

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listItem(uint256 _tokenId, uint256 _price)
        external
        payable
        whenNotPausedMarketplace()
        validPrice(_price)
        itemExists(_tokenId)
        payable
    {
        require(ownerOf(_tokenId) == _msgSender(), "You are not the owner of this NFT.");
        require(nftToListingId[_tokenId] == 0, "NFT is already listed."); // Prevent duplicate listings

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
        sellerListings[_msgSender()].push(listingId);

        _approve(address(this), _tokenId); // Marketplace contract needs approval to transfer
        emit NFTListed(listingId, _tokenId, _msgSender(), _price);
    }

    /// @notice Allows a user to buy a listed NFT.
    /// @param _listingId The ID of the listing to purchase.
    function buyItem(uint256 _listingId)
        external
        payable
        whenNotPausedMarketplace()
        listingExists(_listingId)
        isListingActive(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");

        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 price = listing.price;

        listing.isActive = false;
        nftToListingId[tokenId] = 0; // Clear the listing association

        // Remove listingId from sellerListings array (inefficient for large arrays, consider alternative if scale is critical)
        uint256[] storage sellerListingIds = sellerListings[seller];
        for (uint256 i = 0; i < sellerListingIds.length; i++) {
            if (sellerListingIds[i] == _listingId) {
                sellerListingIds[i] = sellerListingIds[sellerListingIds.length - 1];
                sellerListingIds.pop();
                break;
            }
        }


        // Transfer NFT to buyer
        _transfer(seller, _msgSender(), tokenId);

        // Transfer funds to seller (minus fee)
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee;

        (bool successSeller, ) = payable(seller).call{value: sellerPayout}("");
        require(successSeller, "Seller payment failed.");

        (bool successFee, ) = feeRecipient.call{value: marketplaceFee}("");
        require(successFee, "Marketplace fee payment failed.");

        emit NFTBought(_listingId, tokenId, _msgSender(), seller, price);
    }

    /// @notice Cancels an NFT listing. Only the seller can cancel.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId)
        external
        whenNotPausedMarketplace()
        listingExists(_listingId)
        isListingActive(_listingId)
        isSeller(_listingId)
    {
        Listing storage listing = listings[_listingId];
        uint256 tokenId = listing.tokenId;

        listing.isActive = false;
        nftToListingId[tokenId] = 0; // Clear the listing association

        // Remove listingId from sellerListings array (similar to buyItem)
        uint256[] storage sellerListingIds = sellerListings[_msgSender()];
        for (uint256 i = 0; i < sellerListingIds.length; i++) {
            if (sellerListingIds[i] == _listingId) {
                sellerListingIds[i] = sellerListingIds[sellerListingIds.length - 1];
                sellerListingIds.pop();
                break;
            }
        }

        emit ListingCancelled(_listingId, tokenId, _msgSender());
    }

    /// @notice Updates the price of an existing NFT listing. Only the seller can update.
    /// @param _listingId The ID of the listing to update.
    /// @param _newPrice The new price in wei.
    function updateListingPrice(uint256 _listingId, uint256 _newPrice)
        external
        whenNotPausedMarketplace()
        listingExists(_listingId)
        isListingActive(_listingId)
        isSeller(_listingId)
        validPrice(_newPrice)
    {
        listings[_listingId].price = _newPrice;
        emit ListingPriceUpdated(_listingId, listings[_listingId].tokenId, _newPrice);
    }

    /// @notice Returns an array of active listing IDs.
    function getActiveListings() external view whenNotPausedMarketplace() returns (uint256[] memory) {
        uint256 listingCount = _listingIdCounter.current();
        uint256 activeListingCount = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListingCount++;
            }
        }

        uint256[] memory activeListings = new uint256[](activeListingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= listingCount; i++) {
            if (listings[i].isActive) {
                activeListings[index] = i;
                index++;
            }
        }
        return activeListings;
    }

    /// @notice Returns an array of listing IDs for a specific seller.
    /// @param _seller The address of the seller.
    function getListingsBySeller(address _seller) external view whenNotPausedMarketplace() returns (uint256[] memory) {
        return sellerListings[_seller];
    }

    /// @notice Returns an array of listing IDs for a specific NFT token ID.
    /// @param _tokenId The ID of the NFT token.
    function getListingsByNFT(uint256 _tokenId) external view whenNotPausedMarketplace() returns (uint256[] memory) {
        uint256 listingId = nftToListingId[_tokenId];
        if (listingId == 0) {
            return new uint256[](0); // Return empty array if not listed
        } else {
            uint256[] memory nftListings = new uint256[](1);
            nftListings[0] = listingId;
            return nftListings;
        }
    }


    // --- Dynamic NFT Functions ---

    /// @notice Mints a new Dynamic NFT.
    /// @param _baseURI The base URI for the NFT's metadata.
    function mintNFT(string memory _baseURI) external onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_msgSender(), tokenId);
        tokenBaseURIs[tokenId] = _baseURI;
        emit DynamicNFTMinted(tokenId, _msgSender(), _baseURI);
        return tokenId;
    }

    /// @notice Sets a custom metadata attribute for a Dynamic NFT.
    /// @param _tokenId The ID of the NFT.
    /// @param _attributeName The name of the metadata attribute.
    /// @param _attributeValue The value of the metadata attribute.
    function setTokenMetadataAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue)
        external
        itemExists(_tokenId)
        onlyOwner // For simplicity, only owner can set attributes. In a real scenario, this might be more permissioned or dynamic.
    {
        tokenMetadataAttributes[_tokenId][_attributeName] = _attributeValue;
        emit TokenMetadataAttributeSet(_tokenId, _attributeName, _attributeValue);
    }

    /// @notice Returns the dynamic metadata URI for a given NFT token ID.
    /// @param _tokenId The ID of the NFT.
    function getTokenMetadata(uint256 _tokenId) external view itemExists(_tokenId) returns (string memory) {
        string memory baseURI = tokenBaseURIs[_tokenId];
        string memory tokenIdStr = _tokenId.toString();
        string memory metadata = string(abi.encodePacked(baseURI, tokenIdStr, baseURIExtension));

        // In a real-world scenario, you would typically fetch the baseURI and then construct the full URI
        // based on the token ID. This example simplifies by assuming baseURI is already somewhat complete.
        // For true dynamic metadata, the URI at `metadata` would be designed to dynamically generate JSON
        // based on `tokenMetadataAttributes[_tokenId]`.

        return metadata;
    }

    /// @notice Sets the default file extension for base URIs.
    /// @param _extension The new file extension (e.g., ".json", ".xml").
    function setBaseURIExtension(string memory _extension) external onlyOwner {
        baseURIExtension = _extension;
    }

    // --- Reputation System Functions ---

    modifier onlyReputationController() {
        require(_msgSender() == reputationController, "Only reputation controller can call this function.");
        _;
    }

    /// @notice Adds reputation points to a user's account. Only callable by the reputation controller.
    /// @param _user The address of the user to add reputation to.
    /// @param _amount The amount of reputation points to add.
    function addReputation(address _user, uint256 _amount) external onlyReputationController {
        userReputation[_user] += _amount;
        emit ReputationAdded(_user, _amount, _msgSender());
    }

    /// @notice Subtracts reputation points from a user's account. Only callable by the reputation controller.
    /// @param _user The address of the user to subtract reputation from.
    /// @param _amount The amount of reputation points to subtract.
    function subtractReputation(address _user, uint256 _amount) external onlyReputationController {
        require(userReputation[_user] >= _amount, "Insufficient reputation to subtract.");
        userReputation[_user] -= _amount;
        emit ReputationSubtracted(_user, _amount, _msgSender());
    }

    /// @notice Returns the current reputation points of a user.
    /// @param _user The address of the user.
    function getReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Sets a custom reputation level string for a user. Only callable by the reputation controller.
    /// @param _user The address of the user.
    /// @param _level The custom reputation level string (e.g., "Trusted Seller").
    function setUserReputationLevel(address _user, string memory _level) external onlyReputationController {
        userReputationLevel[_user] = _level;
        emit ReputationLevelSet(_user, _level, _msgSender());
    }

    /// @notice Returns the custom reputation level string of a user.
    /// @param _user The address of the user.
    function getUserReputationLevel(address _user) external view returns (string memory) {
        return userReputationLevel[_user];
    }

    /// @notice Sets the address authorized to modify reputation scores.
    /// @param _reputationController The new reputation controller address.
    function setReputationController(address _reputationController) external onlyOwner {
        reputationController = _reputationController;
    }


    // --- Decentralized Governance Functions ---

    modifier hasSufficientReputation() {
        require(userReputation[_msgSender()] >= governanceThresholdReputation, "Insufficient reputation to create proposal.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID.");
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].state == ProposalState.Active, "Proposal is not active.");
        _;
    }

    modifier notVotedYet(uint256 _proposalId) {
        require(!proposalVotes[_proposalId][_msgSender()], "Already voted on this proposal.");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId) {
        require(block.number <= governanceProposals[_proposalId].createdBlock + governanceVotingPeriodBlocks, "Voting period has ended.");
        _;
    }

    modifier onlyExecutableProposal(uint256 _proposalId) {
        require(governanceProposals[_proposalId].state == ProposalState.Pending, "Proposal is not pending execution.");
        require(block.number > governanceProposals[_proposalId].createdBlock + governanceVotingPeriodBlocks, "Voting period not yet ended.");
        require(governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst, "Proposal did not pass.");
        _;
    }

    /// @notice Creates a new governance proposal. Requires sufficient reputation.
    /// @param _description A description of the proposal.
    /// @param _calldata The calldata to execute if the proposal passes.
    function createGovernanceProposal(string memory _description, bytes memory _calldata) external hasSufficientReputation {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            calldata: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            createdBlock: block.number
        });

        emit GovernanceProposalCreated(proposalId, _msgSender(), _description);
    }

    /// @notice Allows users with reputation to vote on an active governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        hasSufficientReputation
        validProposalId(_proposalId)
        onlyActiveProposal(_proposalId)
        notVotedYet(_proposalId)
        votingPeriodActive(_proposalId)
    {
        proposalVotes[_proposalId][_msgSender()] = true;
        if (_support) {
            governanceProposals[_proposalId].votesFor++;
        } else {
            governanceProposals[_proposalId].votesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, _msgSender(), _support);

        // Check if voting period ended and proposal is ready to be pending
        if (block.number > governanceProposals[_proposalId].createdBlock + governanceVotingPeriodBlocks) {
            if (governanceProposals[_proposalId].votesFor > governanceProposals[_proposalId].votesAgainst) {
                governanceProposals[_proposalId].state = ProposalState.Pending;
            } else {
                governanceProposals[_proposalId].state = ProposalState.Defeated;
            }
        }
    }

    /// @notice Executes a passed governance proposal. Must be in Pending state and voting period must be over.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external validProposalId onlyExecutableProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        proposal.state = ProposalState.Executed;

        (bool success, ) = address(this).call(proposal.calldata); // Execute the proposal calldata
        require(success, "Governance proposal execution failed.");

        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Returns the current state of a governance proposal.
    /// @param _proposalId The ID of the proposal.
    function getProposalState(uint256 _proposalId) external view validProposalId(_proposalId) returns (ProposalState) {
        return governanceProposals[_proposalId].state;
    }

    /// @notice Sets the reputation threshold required to create governance proposals. Only callable through governance.
    /// @param _threshold The new reputation threshold.
    function setGovernanceThresholdReputation(uint256 _threshold) external {
        // This function should ideally be called via a governance proposal itself for full decentralization.
        // For simplicity in this example, we'll allow owner to call it directly.
        require(_msgSender() == owner() || (governanceProposals[_proposalIdCounter.current()].state == ProposalState.Executed), "Only owner or governance can set threshold."); // Example: only allow if last proposal was executed (simplistic governance check)
        governanceThresholdReputation = _threshold;
    }

    /// @notice Returns the current reputation threshold for creating proposals.
    function getGovernanceThresholdReputation() external view returns (uint256) {
        return governanceThresholdReputation;
    }


    // --- Admin/Utility Functions ---

    /// @notice Sets the marketplace fee percentage. Only callable by the contract owner.
    /// @param _feePercentage The new fee percentage (0-100).
    function setMarketplaceFee(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage, _msgSender());
    }

    /// @notice Allows the contract owner to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Subtract msg.value in case of accidental ether sent during call
        require(contractBalance > 0, "No marketplace fees to withdraw.");

        (bool success, ) = feeRecipient.call{value: contractBalance}("");
        require(success, "Fee withdrawal failed.");

        emit MarketplaceFeesWithdrawn(feeRecipient, contractBalance);
    }

    /// @notice Pauses core marketplace functions. Only callable by the contract owner.
    function pauseMarketplace() external onlyOwner whenNotPaused {
        _pause();
        emit MarketplacePaused(_msgSender());
    }

    /// @notice Unpauses core marketplace functions. Only callable by the contract owner.
    function unpauseMarketplace() external onlyOwner whenPaused {
        _unpause();
        emit MarketplaceUnpaused(_msgSender());
    }

    /// @notice Emergency function for owner to transfer any NFT in the contract. Use with caution.
    /// @param _to The recipient address.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) external onlyOwner itemExists(_tokenId) {
        address currentOwner = ownerOf(_tokenId);
        _transfer(currentOwner, _to, _tokenId);
    }

    // --- ERC721 Overrides (Optional, for custom URI logic if needed beyond dynamic attributes) ---
    // override tokenURI function if you need more complex URI logic than just combining baseURI and tokenID
    // For example, you might want to fetch data from an external source to construct the URI.
    // override _baseURI() function if you want to set a contract-level base URI for all tokens (less dynamic)
}
```