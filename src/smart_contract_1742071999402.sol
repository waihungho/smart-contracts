```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with Reputation and Curation
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a decentralized marketplace for Dynamic NFTs,
 * incorporating a reputation system for users and a community-driven curation mechanism
 * to enhance the quality and discoverability of listed NFTs.
 *
 * Function Summary:
 * -----------------
 * **NFT Management:**
 * - `listItem(uint256 _tokenId, uint256 _price)`: List an NFT for sale on the marketplace.
 * - `buyItem(uint256 _listingId)`: Purchase an NFT listed on the marketplace.
 * - `cancelListing(uint256 _listingId)`: Cancel an existing NFT listing.
 * - `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Update the price of an NFT listing.
 * - `getListingDetails(uint256 _listingId)`: Retrieve details of a specific listing.
 * - `getAllListings()`: Get a list of all active NFT listings.
 *
 * **Dynamic NFT Metadata Management:**
 * - `updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allow NFT owner to update the metadata URI of their NFT (Dynamic aspect).
 * - `setMetadataUpdaterContract(address _updaterContract)`: Set a contract authorized to trigger metadata updates (for more complex dynamic behavior).
 * - `triggerExternalMetadataUpdate(uint256 _tokenId)`: Allow authorized contract to trigger an external metadata update for an NFT.
 *
 * **Reputation System:**
 * - `getUserReputation(address _user)`: Get the reputation score of a user.
 * - `increaseReputation(address _user, uint256 _amount)`: Increase a user's reputation (internal function, e.g., for successful sales).
 * - `decreaseReputation(address _user, uint256 _amount)`: Decrease a user's reputation (internal function, e.g., for listing violations).
 * - `setReputationThreshold(uint256 _threshold)`: Set the reputation threshold required for certain actions (admin function).
 * - `getReputationThreshold()`: Get the current reputation threshold.
 *
 * **Curation and Community Features:**
 * - `submitCurationProposal(uint256 _listingId)`: Submit a listing for community curation/feature consideration.
 * - `voteOnCurationProposal(uint256 _proposalId, bool _vote)`: Vote on a curation proposal (community voting).
 * - `executeCuration(uint256 _proposalId)`: Execute the curation result (e.g., feature a listing if approved).
 * - `setCurationQuorum(uint256 _quorum)`: Set the quorum (percentage of votes needed) for curation proposals (admin function).
 * - `getCurationQuorum()`: Get the current curation quorum.
 * - `reportListing(uint256 _listingId, string memory _reason)`: Report a listing for policy violations.
 *
 * **Marketplace Management & Admin:**
 * - `setMarketplaceFee(uint256 _feePercentage)`: Set the marketplace fee percentage (admin function).
 * - `getMarketplaceFee()`: Get the current marketplace fee percentage.
 * - `withdrawMarketplaceFees()`: Admin function to withdraw accumulated marketplace fees.
 * - `pauseMarketplace()`: Pause all marketplace operations (admin function).
 * - `unpauseMarketplace()`: Resume marketplace operations (admin function).
 * - `setAdmin(address _newAdmin)`: Change the contract administrator (admin function).
 * - `getAdmin()`: Get the current contract administrator.
 */
contract DynamicNFTMarketplace {
    // **** Outline & Function Summary Above ****

    // --- State Variables ---
    address public nftContract; // Address of the NFT contract this marketplace is for
    address public admin; // Admin address of the marketplace contract
    uint256 public marketplaceFeePercentage = 2; // Marketplace fee percentage (e.g., 2% = 200)
    uint256 public reputationThreshold = 100; // Reputation score needed for certain actions
    uint256 public curationQuorum = 50; // Curation voting quorum (percentage)

    bool public paused = false; // Marketplace pause state

    uint256 public listingCounter = 0; // Counter for listing IDs
    mapping(uint256 => Listing) public listings; // Mapping of listing IDs to Listing structs
    mapping(uint256 => bool) public activeListings; // Track active listing IDs for iteration

    uint256 public curationProposalCounter = 0; // Counter for curation proposal IDs
    mapping(uint256 => CurationProposal) public curationProposals; // Mapping of proposal IDs to CurationProposal structs

    mapping(address => uint256) public userReputation; // Mapping of user addresses to reputation scores

    address public metadataUpdaterContract; // Optional authorized contract for metadata updates


    // --- Structs ---
    struct Listing {
        uint256 listingId;
        uint256 tokenId;
        address seller;
        uint256 price; // Price in native currency (e.g., wei)
        bool isActive;
        uint256 createdAt;
    }

    struct CurationProposal {
        uint256 proposalId;
        uint256 listingId;
        address proposer;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
        uint256 createdAt;
    }

    // --- Events ---
    event ItemListed(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event ItemBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event ListingCancelled(uint256 listingId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event MetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ReputationIncreased(address user, uint256 amount, string reason);
    event ReputationDecreased(address user, uint256 amount, string reason);
    event CurationProposalSubmitted(uint256 proposalId, uint256 listingId, address proposer);
    event CurationVoteCast(uint256 proposalId, address voter, bool vote);
    event CurationExecuted(uint256 proposalId, bool approved);
    event MarketplacePaused(address admin);
    event MarketplaceUnpaused(address admin);
    event MarketplaceFeeUpdated(uint256 newFeePercentage, address admin);
    event AdminChanged(address newAdmin, address oldAdmin);
    event ListingReported(uint256 listingId, address reporter, string reason);
    event MetadataUpdaterContractSet(address updaterContract, address admin);


    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier notPaused() {
        require(!paused, "Marketplace is currently paused");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId == _listingId, "Listing does not exist");
        _;
    }

    modifier activeListing(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active");
        _;
    }

    modifier validListingPrice(uint256 _price) {
        require(_price > 0, "Price must be greater than zero");
        _;
    }

    modifier reputationAtLeast(uint256 _minReputation) {
        require(userReputation[msg.sender] >= _minReputation, "Insufficient reputation");
        _;
    }

    modifier validCurationProposal(uint256 _proposalId) {
        require(curationProposals[_proposalId].proposalId == _proposalId, "Curation proposal does not exist");
        _;
    }

    modifier activeCurationProposal(uint256 _proposalId) {
        require(curationProposals[_proposalId].isActive, "Curation proposal is not active");
        _;
    }


    // --- Constructor ---
    constructor(address _nftContractAddress) {
        require(_nftContractAddress != address(0), "NFT contract address cannot be zero");
        nftContract = _nftContractAddress;
        admin = msg.sender;
    }


    // --- NFT Management Functions ---

    /// @notice List an NFT for sale on the marketplace.
    /// @param _tokenId The token ID of the NFT to list.
    /// @param _price The price of the NFT in native currency (e.g., wei).
    function listItem(uint256 _tokenId, uint256 _price)
        external
        notPaused
        validListingPrice(_price)
    {
        // 1. Check NFT ownership (using an assumed ERC721 interface on nftContract)
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

        // 2. Check if already listed
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (listings[i].tokenId == _tokenId && listings[i].seller == msg.sender && listings[i].isActive) {
                require(!listings[i].isActive, "NFT is already listed"); // Should ideally not happen, but double check
            }
        }

        // 3. Create new listing
        listingCounter++;
        listings[listingCounter] = Listing({
            listingId: listingCounter,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true,
            createdAt: block.timestamp
        });
        activeListings[listingCounter] = true;

        // 4. Transfer NFT to marketplace contract (for escrow - optional, can also use approval)
        // nft.safeTransferFrom(msg.sender, address(this), _tokenId); // Consider approval mechanism instead for less gas

        emit ItemListed(listingCounter, _tokenId, msg.sender, _price);
    }


    /// @notice Purchase an NFT listed on the marketplace.
    /// @param _listingId The ID of the listing to purchase.
    function buyItem(uint256 _listingId)
        external
        payable
        notPaused
        listingExists(_listingId)
        activeListing(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");
        require(listing.seller != msg.sender, "Cannot buy your own listed NFT");

        // 1. Transfer funds to seller (minus marketplace fee)
        uint256 marketplaceFee = (listing.price * marketplaceFeePercentage) / 10000; // Fee calculation with percentage
        uint256 sellerPayout = listing.price - marketplaceFee;

        (bool successSeller, ) = payable(listing.seller).call{value: sellerPayout}("");
        require(successSeller, "Seller payment failed");

        // 2. Transfer marketplace fee to contract owner (admin) - optional, can be accumulated
        if (marketplaceFee > 0) {
            (bool successMarketplace, ) = payable(admin).call{value: marketplaceFee}("");
            require(successMarketplace, "Marketplace fee payment failed");
        }

        // 3. Transfer NFT to buyer (from marketplace escrow or directly from seller if using approval)
        IERC721 nft = IERC721(nftContract);
        // If using escrow: nft.safeTransferFrom(address(this), msg.sender, listing.tokenId);
        // If using approval (more gas efficient, seller needs to approve marketplace):
        nft.safeTransferFrom(listing.seller, msg.sender, listing.tokenId);


        // 4. Update listing status and remove from active listings
        listing.isActive = false;
        delete activeListings[_listingId];

        // 5. Increase reputation of seller (as a reward for successful sale)
        increaseReputation(listing.seller, 10, "Successful NFT sale");
        increaseReputation(msg.sender, 5, "NFT purchase"); // Reward buyer too

        emit ItemBought(_listingId, listing.tokenId, msg.sender, listing.price);
    }


    /// @notice Cancel an existing NFT listing. Only the seller can cancel.
    /// @param _listingId The ID of the listing to cancel.
    function cancelListing(uint256 _listingId)
        external
        notPaused
        listingExists(_listingId)
        activeListing(_listingId)
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can cancel listing");

        listing.isActive = false;
        delete activeListings[_listingId];

        // If NFT was in escrow (optional): Transfer NFT back to seller
        // IERC721 nft = IERC721(nftContract);
        // nft.safeTransferFrom(address(this), msg.sender, listing.tokenId);

        emit ListingCancelled(_listingId);
    }


    /// @notice Update the price of an NFT listing. Only the seller can update.
    /// @param _listingId The ID of the listing to update.
    /// @param _newPrice The new price of the NFT in native currency (e.g., wei).
    function updateListingPrice(uint256 _listingId, uint256 _newPrice)
        external
        notPaused
        listingExists(_listingId)
        activeListing(_listingId)
        validListingPrice(_newPrice)
    {
        Listing storage listing = listings[_listingId];
        require(listing.seller == msg.sender, "Only seller can update listing price");

        listing.price = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    /// @notice Get details of a specific listing.
    /// @param _listingId The ID of the listing.
    /// @return Listing struct containing listing details.
    function getListingDetails(uint256 _listingId)
        external
        view
        listingExists(_listingId)
        returns (Listing memory)
    {
        return listings[_listingId];
    }

    /// @notice Get a list of all active NFT listings.
    /// @return An array of Listing structs representing active listings.
    function getAllListings()
        external
        view
        returns (Listing[] memory)
    {
        uint256 activeListingCount = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (activeListings[i]) {
                activeListingCount++;
            }
        }

        Listing[] memory allActiveListings = new Listing[](activeListingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= listingCounter; i++) {
            if (activeListings[i]) {
                allActiveListings[index] = listings[i];
                index++;
            }
        }
        return allActiveListings;
    }


    // --- Dynamic NFT Metadata Management Functions ---

    /// @notice Allow NFT owner to update the metadata URI of their NFT (Dynamic aspect).
    /// @param _tokenId The token ID of the NFT to update.
    /// @param _newMetadataURI The new metadata URI string.
    function updateNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)
        external
    {
        IERC721Metadata nftMetadata = IERC721Metadata(nftContract);
        require(nftMetadata.ownerOf(_tokenId) == msg.sender, "Only owner can update NFT metadata");

        // In a real dynamic NFT scenario, you might:
        // 1. Store metadata URI on-chain (less common for large URIs)
        // 2. Update off-chain metadata storage and ensure URI points to it.
        // 3. Use a metadata updater contract for more complex logic.

        // For simplicity in this example, let's assume the NFT contract itself has a function to update metadata.
        // This is a placeholder - real implementation depends on your NFT contract's capabilities.
        IDynamicNFT(nftContract).setTokenMetadataURI(_tokenId, _newMetadataURI); // Assuming such function exists in your NFT contract

        emit MetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @notice Set a contract authorized to trigger metadata updates.
    /// @param _updaterContract Address of the contract to authorize for metadata updates.
    function setMetadataUpdaterContract(address _updaterContract)
        external
        onlyAdmin
    {
        metadataUpdaterContract = _updaterContract;
        emit MetadataUpdaterContractSet(_updaterContract, admin);
    }

    /// @notice Allow authorized contract to trigger an external metadata update for an NFT.
    /// @param _tokenId The token ID of the NFT to update.
    function triggerExternalMetadataUpdate(uint256 _tokenId)
        external
    {
        require(msg.sender == metadataUpdaterContract, "Only authorized updater contract can trigger metadata update");
        IDynamicNFT(nftContract).triggerDynamicMetadataUpdate(_tokenId); // Assuming such function exists in your NFT contract
        // This function in your NFT contract would then handle external data retrieval and metadata update logic.
    }


    // --- Reputation System Functions ---

    /// @notice Get the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score of the user.
    function getUserReputation(address _user)
        external
        view
        returns (uint256)
    {
        return userReputation[_user];
    }

    /// @notice Increase a user's reputation score. (Internal function).
    /// @param _user The address of the user.
    /// @param _amount The amount to increase reputation by.
    /// @param _reason Reason for reputation increase (for event logging).
    function increaseReputation(address _user, uint256 _amount, string memory _reason)
        internal
    {
        userReputation[_user] += _amount;
        emit ReputationIncreased(_user, _amount, _reason);
    }

    /// @notice Decrease a user's reputation score. (Internal function, use cautiously).
    /// @param _user The address of the user.
    /// @param _amount The amount to decrease reputation by.
    /// @param _reason Reason for reputation decrease (for event logging).
    function decreaseReputation(address _user, uint256 _amount, string memory _reason)
        internal
    {
        if (userReputation[_user] >= _amount) {
            userReputation[_user] -= _amount;
        } else {
            userReputation[_user] = 0; // Don't go below zero
        }
        emit ReputationDecreased(_user, _amount, _reason);
    }

    /// @notice Set the reputation threshold required for certain actions. (Admin function).
    /// @param _threshold The new reputation threshold.
    function setReputationThreshold(uint256 _threshold)
        external
        onlyAdmin
    {
        reputationThreshold = _threshold;
    }

    /// @notice Get the current reputation threshold.
    /// @return The current reputation threshold.
    function getReputationThreshold()
        external
        view
        returns (uint256)
    {
        return reputationThreshold;
    }


    // --- Curation and Community Functions ---

    /// @notice Submit a listing for community curation/feature consideration.
    /// @param _listingId The ID of the listing to submit for curation.
    function submitCurationProposal(uint256 _listingId)
        external
        notPaused
        listingExists(_listingId)
        activeListing(_listingId)
        reputationAtLeast(reputationThreshold) // Require minimum reputation to propose curation
    {
        require(listings[_listingId].seller != msg.sender, "Cannot propose curation for your own listing");

        curationProposalCounter++;
        curationProposals[curationProposalCounter] = CurationProposal({
            proposalId: curationProposalCounter,
            listingId: _listingId,
            proposer: msg.sender,
            upvotes: 0,
            downvotes: 0,
            isActive: true,
            createdAt: block.timestamp
        });

        emit CurationProposalSubmitted(curationProposalCounter, _listingId, msg.sender);
    }


    /// @notice Vote on a curation proposal.
    /// @param _proposalId The ID of the curation proposal to vote on.
    /// @param _vote True for upvote, false for downvote.
    function voteOnCurationProposal(uint256 _proposalId, bool _vote)
        external
        notPaused
        validCurationProposal(_proposalId)
        activeCurationProposal(_proposalId)
        reputationAtLeast(reputationThreshold) // Require minimum reputation to vote
    {
        CurationProposal storage proposal = curationProposals[_proposalId];
        require(proposal.proposer != msg.sender, "Proposer cannot vote on their own proposal"); // Optional: Disallow proposer voting

        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }

        emit CurationVoteCast(_proposalId, msg.sender, _vote);
    }


    /// @notice Execute the curation result. Admin/DAO function to finalize curation.
    /// @param _proposalId The ID of the curation proposal to execute.
    function executeCuration(uint256 _proposalId)
        external
        onlyAdmin // Or could be a DAO function
        notPaused
        validCurationProposal(_proposalId)
        activeCurationProposal(_proposalId)
    {
        CurationProposal storage proposal = curationProposals[_proposalId];

        uint256 totalVotes = proposal.upvotes + proposal.downvotes;
        uint256 quorumVotesNeeded = (totalVotes * curationQuorum) / 100; // Calculate quorum based on percentage

        bool approved = proposal.upvotes >= quorumVotesNeeded && proposal.upvotes > proposal.downvotes; // Simple approval logic

        proposal.isActive = false; // Mark proposal as executed

        if (approved) {
            // Action if curation is approved (e.g., feature the listing, give reputation boost to proposer/voters)
            increaseReputation(proposal.proposer, 20, "Successful curation proposal");
            // ... additional actions like featuring listing ...
        } else {
            // Action if curation is rejected (e.g., no action, or maybe decrease proposer reputation for spam proposals)
            decreaseReputation(proposal.proposer, 5, "Unsuccessful curation proposal"); // Optional: Penalize bad proposals
        }

        emit CurationExecuted(_proposalId, approved);
    }

    /// @notice Set the quorum (percentage of votes needed) for curation proposals. (Admin function).
    /// @param _quorum The new curation quorum percentage (e.g., 51 for 51%).
    function setCurationQuorum(uint256 _quorum)
        external
        onlyAdmin
    {
        require(_quorum <= 100, "Quorum percentage cannot exceed 100%");
        curationQuorum = _quorum;
    }

    /// @notice Get the current curation quorum percentage.
    /// @return The current curation quorum percentage.
    function getCurationQuorum()
        external
        view
        returns (uint256)
    {
        return curationQuorum;
    }

    /// @notice Report a listing for policy violations.
    /// @param _listingId The ID of the listing to report.
    /// @param _reason The reason for reporting.
    function reportListing(uint256 _listingId, string memory _reason)
        external
        notPaused
        listingExists(_listingId)
        activeListing(_listingId)
        reputationAtLeast(reputationThreshold) // Require minimum reputation to report
    {
        // In a real application, you would:
        // 1. Store the report details (listingId, reporter, reason, timestamp).
        // 2. Implement an admin review process to handle reports.
        // 3. Potentially decrease reputation of reporters for false reports.

        // For this example, we just emit an event.
        emit ListingReported(_listingId, msg.sender, _reason);
        // Admin can then monitor events and take action manually.
    }



    // --- Marketplace Management & Admin Functions ---

    /// @notice Set the marketplace fee percentage. (Admin function).
    /// @param _feePercentage The new marketplace fee percentage (e.g., 200 for 2%).
    function setMarketplaceFee(uint256 _feePercentage)
        external
        onlyAdmin
    {
        require(_feePercentage <= 10000, "Fee percentage cannot exceed 100%"); // Max 100% fee
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage, admin);
    }

    /// @notice Get the current marketplace fee percentage.
    /// @return The current marketplace fee percentage.
    function getMarketplaceFee()
        external
        view
        returns (uint256)
    {
        return marketplaceFeePercentage;
    }

    /// @notice Admin function to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees()
        external
        onlyAdmin
    {
        payable(admin).transfer(address(this).balance); // Transfer all contract balance to admin
    }

    /// @notice Pause all marketplace operations. (Admin function).
    function pauseMarketplace()
        external
        onlyAdmin
        notPaused
    {
        paused = true;
        emit MarketplacePaused(admin);
    }

    /// @notice Resume marketplace operations. (Admin function).
    function unpauseMarketplace()
        external
        onlyAdmin
        paused
    {
        paused = false;
        emit MarketplaceUnpaused(admin);
    }

    /// @notice Change the contract administrator. (Admin function).
    /// @param _newAdmin The address of the new administrator.
    function setAdmin(address _newAdmin)
        external
        onlyAdmin
    {
        require(_newAdmin != address(0), "New admin address cannot be zero");
        address oldAdmin = admin;
        admin = _newAdmin;
        emit AdminChanged(_newAdmin, oldAdmin);
    }

    /// @notice Get the current contract administrator address.
    /// @return The current administrator address.
    function getAdmin()
        external
        view
        returns (address)
    {
        return admin;
    }
}


// --- Interfaces (assuming ERC721 and Dynamic NFT extensions) ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address approved, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address owner); // Re-declare if needed
}

// Interface for Dynamic NFT functionality (example - adjust to your NFT contract)
interface IDynamicNFT {
    function setTokenMetadataURI(uint256 _tokenId, string memory _metadataURI) external;
    function triggerDynamicMetadataUpdate(uint256 _tokenId) external; // Example function to trigger external update
}
```