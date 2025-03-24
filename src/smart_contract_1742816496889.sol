```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with Evolving Traits and Governance
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace focused on Dynamic NFTs.
 *      These NFTs have traits that can evolve over time based on various on-chain interactions,
 *      and the marketplace includes governance features for community control.
 *
 * **Outline and Function Summary:**
 *
 * **Contract State Variables:**
 *   - `nftContractAddress`: Address of the Dynamic NFT contract.
 *   - `marketplaceFee`: Percentage fee charged on marketplace sales.
 *   - `feeRecipient`: Address to receive marketplace fees.
 *   - `listingFee`: Fixed fee for listing an NFT on the marketplace.
 *   - `listings`: Mapping of tokenId to NFTListing struct for NFTs listed on the marketplace.
 *   - `dynamicTraitWeights`: Mapping to configure the influence of interactions on NFT traits.
 *   - `paused`: Boolean to pause/unpause marketplace functionalities.
 *   - `governanceVotes`: Mapping to store votes for governance proposals.
 *   - `proposals`: Mapping to store governance proposals.
 *   - `proposalCount`: Counter for governance proposals.
 *   - `minQuorum`: Minimum votes required for a proposal to pass.
 *   - `proposalDuration`: Duration a proposal is active for voting.
 *   - `admin`: Address of the contract administrator.
 *
 * **Structs:**
 *   - `NFTListing`: Represents an NFT listing on the marketplace.
 *   - `DynamicTraits`: Represents the dynamic traits of an NFT. (Example: Could be expanded)
 *   - `GovernanceProposal`: Represents a governance proposal.
 *
 * **Modifiers:**
 *   - `onlyAdmin`: Modifier to restrict function access to the contract admin.
 *   - `whenNotPaused`: Modifier to restrict function access when the contract is not paused.
 *   - `whenPaused`: Modifier to restrict function access when the contract is paused.
 *   - `nftExists`: Modifier to check if an NFT with a given tokenId exists.
 *   - `nftNotListed`: Modifier to check if an NFT is not already listed on the marketplace.
 *   - `nftListed`: Modifier to check if an NFT is listed on the marketplace.
 *   - `onlyNFTContract`: Modifier to restrict function access to the designated NFT contract.
 *
 * **Functions:**
 *
 * **NFT Management & Dynamic Traits:**
 *   1. `setNFTContractAddress(address _nftContractAddress)`: [Admin] Set the address of the Dynamic NFT contract.
 *   2. `getNFTDynamicTraits(uint256 _tokenId)`: [View] Retrieve the dynamic traits of a specific NFT. (Example - could be expanded to more complex traits)
 *   3. `interactWithNFT(uint256 _tokenId, uint8 _interactionType)`: [User] Simulate user interaction with an NFT, triggering trait evolution.
 *   4. `evolveNFTTraitsByTime(uint256 _tokenId)`: [Internal/Automated] Evolve NFT traits based on time elapsed since last interaction. (Example - could be called by Chainlink Keepers or similar)
 *   5. `setDynamicTraitWeight(uint8 _traitIndex, uint8 _interactionType, uint8 _weight)`: [Admin] Configure the weight of interactions on specific traits.
 *
 * **Marketplace Functionality:**
 *   6. `listNFTForSale(uint256 _tokenId, uint256 _price)`: [User] List an NFT for sale on the marketplace.
 *   7. `cancelNFTListing(uint256 _tokenId)`: [User] Cancel an NFT listing.
 *   8. `buyNFT(uint256 _listingId)`: [User] Purchase an NFT listed on the marketplace.
 *   9. `updateListingPrice(uint256 _tokenId, uint256 _newPrice)`: [User] Update the price of an NFT listing.
 *   10. `getNFTListing(uint256 _tokenId)`: [View] Get details of a specific NFT listing.
 *   11. `getAllListings()`: [View] Get a list of all active NFT listings.
 *   12. `setMarketplaceFee(uint256 _feePercentage)`: [Admin] Set the marketplace fee percentage.
 *   13. `setFeeRecipient(address _recipient)`: [Admin] Set the address to receive marketplace fees.
 *   14. `setListingFee(uint256 _feeAmount)`: [Admin] Set the fixed fee for listing NFTs.
 *   15. `withdrawMarketplaceFees()`: [Admin] Withdraw accumulated marketplace fees.
 *
 * **Governance Functionality:**
 *   16. `createGovernanceProposal(string memory _description, bytes memory _calldata)`: [User] Create a new governance proposal.
 *   17. `voteOnProposal(uint256 _proposalId, bool _support)`: [User] Vote for or against a governance proposal.
 *   18. `executeProposal(uint256 _proposalId)`: [Admin/Automated] Execute a passed governance proposal.
 *   19. `getProposalDetails(uint256 _proposalId)`: [View] Get details of a specific governance proposal.
 *   20. `setGovernanceParameters(uint256 _minQuorum, uint256 _proposalDuration)`: [Admin] Set governance parameters like minimum quorum and proposal duration.
 *
 * **Admin & Utility Functions:**
 *   21. `pauseMarketplace()`: [Admin] Pause marketplace functionalities.
 *   22. `unpauseMarketplace()`: [Admin] Unpause marketplace functionalities.
 *   23. `setAdmin(address _newAdmin)`: [Admin] Transfer contract administration to a new address.
 *   24. `supportsInterface(bytes4 interfaceId)`: [View] Standard ERC165 interface support.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DynamicNFTMarketplace is Ownable, ERC165, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    Counters.Counter private _proposalIds;

    // Address of the Dynamic NFT contract
    address public nftContractAddress;

    // Marketplace Fees
    uint256 public marketplaceFee = 2; // 2% default marketplace fee
    address public feeRecipient;
    uint256 public listingFee = 0.01 ether; // Example listing fee

    // NFT Listings
    struct NFTListing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => NFTListing) public listings;
    mapping(uint256 => bool) public isListed; // For quick checks if tokenId is listed

    // Dynamic NFT Traits (Example - expandable)
    struct DynamicTraits {
        uint8 rarity;
        uint8 energyLevel;
        uint8 aestheticValue;
        uint256 lastInteractionTime;
    }
    mapping(uint256 => DynamicTraits) public nftTraits;

    // Dynamic Trait Evolution Weights (Example - expandable and configurable)
    mapping(uint8 => mapping(uint8 => uint8)) public dynamicTraitWeights; // traitIndex -> interactionType -> weight

    // Governance
    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        bytes calldataData; // Calldata to execute if proposal passes
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public governanceVotes; // proposalId -> voter -> voted
    uint256 public proposalCount = 0;
    uint256 public minQuorum = 5; // Minimum votes to pass a proposal
    uint256 public proposalDuration = 7 days; // Proposal voting duration

    // Events
    event NFTListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTListingCancelled(uint256 listingId, uint256 tokenId);
    event NFTSold(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event TraitEvolved(uint256 tokenId, uint8 traitIndex, uint8 newValue);
    event ProposalCreated(uint256 proposalId, string description, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event MarketplacePaused();
    event MarketplaceUnpaused();

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can call this function.");
        _;
    }

    modifier whenNotPausedMarketplace() {
        require(!paused(), "Marketplace is paused.");
        _;
    }

    modifier whenPausedMarketplace() {
        require(paused(), "Marketplace is not paused.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(IERC721(nftContractAddress).ownerOf(_tokenId) != address(0), "NFT does not exist.");
        _;
    }

    modifier nftNotListed(uint256 _tokenId) {
        require(!isListed[_tokenId], "NFT is already listed.");
        _;
    }

    modifier nftListed(uint256 _tokenId) {
        require(isListed[_tokenId], "NFT is not listed.");
        _;
    }

    modifier onlyNFTContract() {
        require(msg.sender == nftContractAddress, "Only NFT contract can call this function.");
        _;
    }

    constructor(address _nftContractAddress, address _feeRecipient) {
        nftContractAddress = _nftContractAddress;
        feeRecipient = _feeRecipient;
        _listingIds.increment(); // Start listing IDs from 1
        _proposalIds.increment(); // Start proposal IDs from 1

        // Initialize default trait weights (Example - can be customized)
        dynamicTraitWeights[0][1] = 2; // Rarity increased by interaction type 1 with weight 2
        dynamicTraitWeights[1][2] = 3; // EnergyLevel increased by interaction type 2 with weight 3
        dynamicTraitWeights[2][1] = 1; // AestheticValue increased by interaction type 1 with weight 1
    }

    /**
     * @dev Sets the address of the Dynamic NFT contract.
     * @param _nftContractAddress The address of the NFT contract.
     */
    function setNFTContractAddress(address _nftContractAddress) external onlyAdmin {
        nftContractAddress = _nftContractAddress;
    }

    /**
     * @dev Retrieves the dynamic traits of a specific NFT.
     * @param _tokenId The ID of the NFT.
     * @return The dynamic traits of the NFT.
     */
    function getNFTDynamicTraits(uint256 _tokenId) external view nftExists(_tokenId) returns (DynamicTraits memory) {
        return nftTraits[_tokenId];
    }

    /**
     * @dev Simulates user interaction with an NFT, triggering trait evolution.
     * @param _tokenId The ID of the NFT.
     * @param _interactionType An identifier for the type of interaction.
     */
    function interactWithNFT(uint256 _tokenId, uint8 _interactionType) external whenNotPausedMarketplace nftExists(_tokenId) {
        require(IERC721(nftContractAddress).ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");

        DynamicTraits storage traits = nftTraits[_tokenId];

        // Example: Evolve rarity trait based on interaction type 1
        if (dynamicTraitWeights[0][_interactionType] > 0) {
            uint8 weight = dynamicTraitWeights[0][_interactionType];
            traits.rarity = uint8(uint256(traits.rarity) + weight <= 255 ? uint256(traits.rarity) + weight : 255); // Cap at 255
            emit TraitEvolved(_tokenId, 0, traits.rarity);
        }

        // Example: Evolve energyLevel trait based on interaction type 2
        if (dynamicTraitWeights[1][_interactionType] > 0) {
            uint8 weight = dynamicTraitWeights[1][_interactionType];
            traits.energyLevel = uint8(uint256(traits.energyLevel) + weight <= 255 ? uint256(traits.energyLevel) + weight : 255);
            emit TraitEvolved(_tokenId, 1, traits.energyLevel);
        }

        // Example: Evolve aestheticValue trait based on interaction type 1
        if (dynamicTraitWeights[2][_interactionType] > 0) {
            uint8 weight = dynamicTraitWeights[2][_interactionType];
            traits.aestheticValue = uint8(uint256(traits.aestheticValue) + weight <= 255 ? uint256(traits.aestheticValue) + weight : 255);
            emit TraitEvolved(_tokenId, 2, traits.aestheticValue);
        }

        traits.lastInteractionTime = block.timestamp;
    }

    /**
     * @dev Evolve NFT traits based on time elapsed since the last interaction. (Example - Basic time evolution)
     *      This could be triggered by an external service like Chainlink Keepers or a similar automation solution.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFTTraitsByTime(uint256 _tokenId) external whenNotPausedMarketplace onlyNFTContract nftExists(_tokenId) {
        DynamicTraits storage traits = nftTraits[_tokenId];
        uint256 timeElapsed = block.timestamp - traits.lastInteractionTime;

        // Example: Decrease energyLevel over time
        if (timeElapsed > 1 days && traits.energyLevel > 0) {
            uint8 energyDecrease = uint8(timeElapsed / (1 days)); // Example: decrease by 1 per day
            traits.energyLevel = traits.energyLevel >= energyDecrease ? traits.energyLevel - energyDecrease : 0;
            emit TraitEvolved(_tokenId, 1, traits.energyLevel);
        }
    }

    /**
     * @dev Sets the weight of an interaction type on a specific dynamic trait.
     * @param _traitIndex Index of the trait to modify (e.g., 0 for rarity, 1 for energyLevel).
     * @param _interactionType The interaction type identifier.
     * @param _weight The weight to assign to this interaction type for this trait.
     */
    function setDynamicTraitWeight(uint8 _traitIndex, uint8 _interactionType, uint8 _weight) external onlyAdmin {
        dynamicTraitWeights[_traitIndex][_interactionType] = _weight;
    }

    /**
     * @dev Lists an NFT for sale on the marketplace.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The listing price in wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) external payable whenNotPausedMarketplace nftExists(_tokenId) nftNotListed(_tokenId) {
        require(IERC721(nftContractAddress).ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(_price > 0, "Price must be greater than zero.");
        require(msg.value >= listingFee, "Insufficient listing fee.");

        // Transfer listing fee to fee recipient
        payable(feeRecipient).transfer(listingFee);

        // Approve marketplace to transfer the NFT
        IERC721(nftContractAddress).approve(address(this), _tokenId);

        _listingIds.increment();
        uint256 listingId = _listingIds.current();

        listings[listingId] = NFTListing({
            listingId: listingId,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        isListed[_tokenId] = true;

        emit NFTListed(listingId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Cancels an NFT listing.
     * @param _tokenId The ID of the NFT to cancel the listing for.
     */
    function cancelNFTListing(uint256 _tokenId) external whenNotPausedMarketplace nftExists(_tokenId) nftListed(_tokenId) {
        uint256 listingIdToCancel = 0;
        for(uint256 i = 1; i <= _listingIds.current(); i++){
            if(listings[i].tokenId == _tokenId && listings[i].isActive){
                listingIdToCancel = i;
                break;
            }
        }
        require(listings[listingIdToCancel].seller == msg.sender, "You are not the seller of this NFT.");
        require(listings[listingIdToCancel].isActive, "Listing is not active.");

        listings[listingIdToCancel].isActive = false;
        isListed[_tokenId] = false;

        emit NFTListingCancelled(listingIdToCancel, _tokenId);
    }

    /**
     * @dev Buys an NFT listed on the marketplace.
     * @param _listingId The ID of the NFT listing to purchase.
     */
    function buyNFT(uint256 _listingId) external payable whenNotPausedMarketplace {
        require(listings[_listingId].isActive, "Listing is not active.");
        NFTListing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient payment.");
        require(msg.sender != listing.seller, "Seller cannot buy their own NFT.");

        uint256 tokenId = listing.tokenId;
        uint256 price = listing.price;
        address seller = listing.seller;

        // Transfer NFT to buyer
        IERC721(nftContractAddress).safeTransferFrom(seller, msg.sender, tokenId);

        // Calculate marketplace fee and transfer funds
        uint256 feeAmount = (price * marketplaceFee) / 100;
        uint256 sellerProceeds = price - feeAmount;

        payable(feeRecipient).transfer(feeAmount);
        payable(seller).transfer(sellerProceeds);

        // Deactivate listing
        listing.isActive = false;
        isListed[tokenId] = false;

        emit NFTSold(_listingId, tokenId, msg.sender, price);

        // Refund any excess payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @dev Updates the price of an NFT listing.
     * @param _tokenId The ID of the NFT to update the price for.
     * @param _newPrice The new price in wei.
     */
    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) external whenNotPausedMarketplace nftExists(_tokenId) nftListed(_tokenId) {
        uint256 listingIdToUpdate = 0;
        for(uint256 i = 1; i <= _listingIds.current(); i++){
            if(listings[i].tokenId == _tokenId && listings[i].isActive){
                listingIdToUpdate = i;
                break;
            }
        }
        require(listings[listingIdToUpdate].seller == msg.sender, "You are not the seller of this NFT.");
        require(_newPrice > 0, "New price must be greater than zero.");
        require(listings[listingIdToUpdate].isActive, "Listing is not active.");

        listings[listingIdToUpdate].price = _newPrice;
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _tokenId The ID of the NFT to get listing details for.
     * @return NFTListing struct containing listing details.
     */
    function getNFTListing(uint256 _tokenId) external view nftExists(_tokenId) nftListed(_tokenId) returns (NFTListing memory) {
        uint256 listingIdToGet = 0;
        for(uint256 i = 1; i <= _listingIds.current(); i++){
            if(listings[i].tokenId == _tokenId && listings[i].isActive){
                listingIdToGet = i;
                break;
            }
        }
        return listings[listingIdToGet];
    }

    /**
     * @dev Retrieves a list of all active NFT listings.
     * @return An array of NFTListing structs representing active listings.
     */
    function getAllListings() external view returns (NFTListing[] memory) {
        uint256 activeListingCount = 0;
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                activeListingCount++;
            }
        }

        NFTListing[] memory activeListings = new NFTListing[](activeListingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _listingIds.current(); i++) {
            if (listings[i].isActive) {
                activeListings[index] = listings[i];
                index++;
            }
        }
        return activeListings;
    }

    /**
     * @dev Sets the marketplace fee percentage.
     * @param _feePercentage The new marketplace fee percentage (e.g., 2 for 2%).
     */
    function setMarketplaceFee(uint256 _feePercentage) external onlyAdmin {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100.");
        marketplaceFee = _feePercentage;
    }

    /**
     * @dev Sets the address to receive marketplace fees.
     * @param _recipient The address to receive fees.
     */
    function setFeeRecipient(address _recipient) external onlyAdmin {
        require(_recipient != address(0), "Invalid recipient address.");
        feeRecipient = _recipient;
    }

    /**
     * @dev Sets the fixed fee for listing NFTs.
     * @param _feeAmount The listing fee amount in wei.
     */
    function setListingFee(uint256 _feeAmount) external onlyAdmin {
        listingFee = _feeAmount;
    }

    /**
     * @dev Withdraws accumulated marketplace fees to the fee recipient.
     */
    function withdrawMarketplaceFees() external onlyAdmin {
        uint256 balance = address(this).balance;
        payable(feeRecipient).transfer(balance);
    }

    /**
     * @dev Creates a new governance proposal.
     * @param _description A description of the proposal.
     * @param _calldata Calldata to execute if the proposal passes.
     */
    function createGovernanceProposal(string memory _description, bytes memory _calldata) external whenNotPausedMarketplace {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        proposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            proposer: msg.sender,
            calldataData: _calldata,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalDuration,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        proposalCount = proposalId;
        emit ProposalCreated(proposalId, _description, msg.sender);
    }

    /**
     * @dev Votes for or against a governance proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPausedMarketplace {
        require(proposals[_proposalId].endTime > block.timestamp, "Voting period ended.");
        require(!governanceVotes[_proposalId][msg.sender], "Already voted on this proposal.");

        governanceVotes[_proposalId][msg.sender] = true;
        if (_support) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes a passed governance proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyAdmin whenNotPausedMarketplace {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.endTime <= block.timestamp, "Voting period not ended.");
        require(!proposal.executed, "Proposal already executed.");
        require(proposal.yesVotes >= minQuorum, "Proposal does not meet quorum.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal not passed (more no votes).");

        (bool success, ) = address(this).call(proposal.calldataData);
        require(success, "Proposal execution failed.");

        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return GovernanceProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return proposals[_proposalId];
    }

    /**
     * @dev Sets governance parameters like minimum quorum and proposal duration.
     * @param _minQuorum The minimum number of yes votes required for a proposal to pass.
     * @param _proposalDuration The duration of the voting period in seconds.
     */
    function setGovernanceParameters(uint256 _minQuorum, uint256 _proposalDuration) external onlyAdmin {
        minQuorum = _minQuorum;
        proposalDuration = _proposalDuration;
    }

    /**
     * @dev Pauses marketplace functionalities.
     */
    function pauseMarketplace() external onlyAdmin whenNotPausedMarketplace {
        _pause();
        emit MarketplacePaused();
    }

    /**
     * @dev Unpauses marketplace functionalities.
     */
    function unpauseMarketplace() external onlyAdmin whenPausedMarketplace {
        _unpause();
        emit MarketplaceUnpaused();
    }

    /**
     * @dev Transfers contract administration to a new address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        transferOwnership(_newAdmin);
    }

    /**
     * @dev ERC165 interface support.
     * @param interfaceId The interface ID to check for.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721Marketplace).interfaceId || // Example - if you define a custom marketplace interface
            super.supportsInterface(interfaceId);
    }
}

// Example Interface (optional - for interface support in supportsInterface function)
interface IERC721Marketplace {
    function listNFTForSale(uint256 _tokenId, uint256 _price) external payable;
    function buyNFT(uint256 _listingId) external payable;
    function cancelNFTListing(uint256 _tokenId) external;
}
```