```solidity
/**
 * @title Decentralized Dynamic NFT Marketplace with AI-Powered Personalization
 * @author Bard (AI Assistant)
 * @dev This contract implements a dynamic NFT marketplace with advanced features,
 * including AI-powered personalization (simulated within the contract for demonstration),
 * dynamic NFT traits, royalty management, fractional ownership, voting mechanisms,
 * and more. It aims to be a comprehensive and innovative NFT platform.
 *
 * ## Contract Outline and Function Summary:
 *
 * **Core Concepts:**
 * - **Dynamic NFTs:** NFTs with traits that can evolve based on user interactions and external factors.
 * - **Personalized Marketplace:** Recommends NFTs to users based on their preferences (simulated AI).
 * - **Fractional Ownership:** Allows NFTs to be owned by multiple parties.
 * - **Voting Mechanism:** Enables fractional owners to vote on NFT decisions.
 * - **Royalty System:** Automatically distributes royalties to creators on secondary sales.
 * - **Staking & Rewards:** Users can stake NFTs to earn rewards.
 * - **DAO Governance (Basic):**  Simple governance for platform parameters (can be extended).
 * - **Event-Driven Actions:**  Triggers actions based on certain NFT events.
 *
 * **Function Summary:**
 *
 * **NFT Management (Minting, Traits, Personalization):**
 * 1. `mintNFT(string memory _metadataURI, string memory _initialDynamicTraits)`: Mints a new dynamic NFT.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers NFT ownership.
 * 3. `getNFTOwner(uint256 _tokenId)`: Returns the owner of an NFT.
 * 4. `getNFTMetadataURI(uint256 _tokenId)`: Returns the metadata URI of an NFT.
 * 5. `getDynamicTraits(uint256 _tokenId)`: Returns the dynamic traits of an NFT.
 * 6. `updateDynamicTraits(uint256 _tokenId, string memory _newTraits)`: Updates the dynamic traits of an NFT (owner-only).
 * 7. `personalizeNFTRecommendation(address _user)`: Simulates AI personalization to recommend NFTs to a user.
 * 8. `recordNFTInteraction(address _user, uint256 _tokenId, InteractionType _interaction)`: Records user interactions with NFTs for personalization.
 *
 * **Marketplace Functions (Listing, Buying, Selling, Bidding):**
 * 9. `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale on the marketplace.
 * 10. `buyNFT(uint256 _tokenId)`: Allows anyone to buy a listed NFT.
 * 11. `cancelNFTSale(uint256 _tokenId)`: Allows the seller to cancel an NFT listing.
 * 12. `placeBidOnNFT(uint256 _tokenId)`: Allows users to place bids on NFTs.
 * 13. `acceptNFTBid(uint256 _tokenId, uint256 _bidId)`: Allows the seller to accept a bid.
 * 14. `getNFTListingDetails(uint256 _tokenId)`: Retrieves details of an NFT listing.
 * 15. `getNFTBids(uint256 _tokenId)`: Retrieves all bids for an NFT.
 *
 * **Fractional Ownership & Voting:**
 * 16. `fractionalizeNFT(uint256 _tokenId, uint256 _shares)`: Fractionalizes an NFT into shares.
 * 17. `buyNFTShares(uint256 _tokenId, uint256 _sharesToBuy)`: Allows users to buy shares of a fractionalized NFT.
 * 18. `proposeNFTAction(uint256 _tokenId, string memory _actionDescription)`: Allows fractional owners to propose actions for the NFT.
 * 19. `voteOnNFTAction(uint256 _tokenId, uint256 _proposalId, bool _vote)`: Allows fractional owners to vote on NFT actions.
 * 20. `executeNFTAction(uint256 _tokenId, uint256 _proposalId)`: Executes an approved NFT action (simple example).
 *
 * **Royalty & Creator Features:**
 * 21. `setRoyaltyPercentage(uint256 _royaltyPercentage)`: Sets the royalty percentage for all NFTs.
 * 22. `getRoyaltyPercentage()`: Returns the current royalty percentage.
 * 23. `withdrawCreatorRoyalties()`: Allows creators to withdraw accumulated royalties.
 *
 * **Staking & Rewards (Basic):**
 * 24. `stakeNFT(uint256 _tokenId)`: Allows users to stake their NFTs for rewards.
 * 25. `unstakeNFT(uint256 _tokenId)`: Allows users to unstake their NFTs.
 * 26. `claimStakingRewards(uint256 _tokenId)`: Allows users to claim staking rewards.
 *
 * **Admin & Governance (Basic):**
 * 27. `setMarketplaceFee(uint256 _feePercentage)`: Sets the marketplace fee percentage.
 * 28. `getMarketplaceFee()`: Returns the current marketplace fee percentage.
 * 29. `pauseContract()`: Pauses the contract (admin-only).
 * 30. `unpauseContract()`: Unpauses the contract (admin-only).
 * 31. `withdrawContractBalance()`: Allows the admin to withdraw contract balance.
 *
 * **Utility Functions:**
 * 32. `getContractBalance()`: Returns the contract's ETH balance.
 * 33. `isContractPaused()`: Checks if the contract is paused.
 *
 * **Events:** (Defined inline throughout the code for clarity)
 */
pragma solidity ^0.8.0;

contract DynamicPersonalizedNFTMarketplace {
    // --- Data Structures ---

    struct NFT {
        uint256 id;
        address creator;
        address owner;
        string metadataURI;
        string dynamicTraits; // Can be JSON or structured string
        uint256 personalizationScore; // Simulated AI personalization score
        bool isFractionalized;
        uint256 totalShares;
    }

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
        uint256 listingTime;
    }

    struct Bid {
        uint256 id;
        uint256 tokenId;
        address bidder;
        uint256 amount;
        uint256 bidTime;
        bool isActive;
    }

    struct NFTActionProposal {
        uint256 id;
        uint256 tokenId;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
    }

    enum InteractionType {
        VIEW,
        LIKE,
        BUY,
        SHARE
    }

    // --- State Variables ---

    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => Listing) public NFTListings;
    mapping(uint256 => Bid[]) public NFTBids;
    mapping(uint256 => NFTActionProposal[]) public NFTProposals;
    mapping(uint256 => mapping(address => uint256)) public nftShares; // tokenId => (user => shares)
    mapping(uint256 => address) public nftCreators; // tokenId => creator address
    mapping(address => uint256) public creatorRoyaltiesDue; // creator => royalty amount
    mapping(uint256 => bool) public isNFTStaked; // tokenId => isStaked
    mapping(uint256 => uint256) public nftStakingStartTime; // tokenId => startTime

    uint256 public nftCounter;
    uint256 public bidCounter;
    uint256 public proposalCounter;
    uint256 public marketplaceFeePercentage = 2; // Default 2% marketplace fee
    uint256 public royaltyPercentage = 5; // Default 5% royalty
    bool public contractPaused = false;
    address public admin;
    uint256 public stakingRewardPerBlock = 0.0001 ether; // Example staking reward

    // --- Events ---

    event NFTMinted(uint256 tokenId, address creator, string metadataURI);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event NFTListingCancelled(uint256 tokenId, address seller);
    event NFTBidPlaced(uint256 bidId, uint256 tokenId, address bidder, uint256 amount);
    event NFTBidAccepted(uint256 bidId, uint256 tokenId, address seller, address bidder, uint256 amount);
    event NFTFractionalized(uint256 tokenId, uint256 shares);
    event NFTSharesBought(uint256 tokenId, address buyer, uint256 shares);
    event NFTActionProposed(uint256 proposalId, uint256 tokenId, address proposer, string description);
    event NFTActionVoted(uint256 proposalId, uint256 tokenId, address voter, bool vote);
    event NFTActionExecuted(uint256 proposalId, uint256 tokenId);
    event NFTRoyaltyPaid(uint256 tokenId, address creator, uint256 royaltyAmount);
    event NFTStaked(uint256 tokenId, address staker);
    event NFTUnstaked(uint256 tokenId, address unstaker);
    event StakingRewardsClaimed(uint256 tokenId, addressclaimer, uint256 rewards);
    event MarketplaceFeeUpdated(uint256 newFeePercentage);
    event RoyaltyPercentageUpdated(uint256 newRoyaltyPercentage);
    event ContractPaused();
    event ContractUnpaused();
    event AdminWithdrawal(uint256 amount);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(NFTs[_tokenId].id != 0, "NFT does not exist");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(NFTs[_tokenId].owner == msg.sender, "Only NFT owner can perform this action");
        _;
    }

    modifier onlyNFTCreator(uint256 _tokenId) {
        require(NFTs[_tokenId].creator == msg.sender, "Only NFT creator can perform this action");
        _;
    }

    modifier onlyFractionalOwner(uint256 _tokenId) {
        require(nftShares[_tokenId][msg.sender] > 0, "You are not a fractional owner");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(NFTListings[_tokenId].isActive, "NFT is not listed for sale");
        _;
    }

    modifier bidExists(uint256 _tokenId, uint256 _bidId) {
        require(NFTBids[_tokenId][_bidId].isActive, "Bid does not exist or is not active");
        _;
    }

    modifier proposalExists(uint256 _tokenId, uint256 _proposalId) {
        require(NFTProposals[_tokenId][_proposalId].isActive, "Proposal does not exist or is not active");
        _;
    }

    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- NFT Management Functions ---

    /// @notice Mints a new dynamic NFT.
    /// @param _metadataURI URI pointing to the NFT metadata.
    /// @param _initialDynamicTraits Initial dynamic traits for the NFT (e.g., JSON string).
    function mintNFT(string memory _metadataURI, string memory _initialDynamicTraits) public whenNotPaused returns (uint256) {
        nftCounter++;
        uint256 tokenId = nftCounter;

        NFTs[tokenId] = NFT({
            id: tokenId,
            creator: msg.sender,
            owner: msg.sender,
            metadataURI: _metadataURI,
            dynamicTraits: _initialDynamicTraits,
            personalizationScore: 0,
            isFractionalized: false,
            totalShares: 0
        });
        nftCreators[tokenId] = msg.sender; // Record creator
        emit NFTMinted(tokenId, msg.sender, _metadataURI);
        return tokenId;
    }

    /// @notice Transfers NFT ownership.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the NFT to transfer.
    function transferNFT(address _to, uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        NFTs[_tokenId].owner = _to;
        emit NFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @notice Returns the owner of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The address of the NFT owner.
    function getNFTOwner(uint256 _tokenId) public view nftExists(_tokenId) returns (address) {
        return NFTs[_tokenId].owner;
    }

    /// @notice Returns the metadata URI of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The metadata URI.
    function getNFTMetadataURI(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return NFTs[_tokenId].metadataURI;
    }

    /// @notice Returns the dynamic traits of an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return The dynamic traits (e.g., JSON string).
    function getDynamicTraits(uint256 _tokenId) public view nftExists(_tokenId) returns (string memory) {
        return NFTs[_tokenId].dynamicTraits;
    }

    /// @notice Updates the dynamic traits of an NFT (only callable by the NFT owner).
    /// @param _tokenId ID of the NFT.
    /// @param _newTraits New dynamic traits to set.
    function updateDynamicTraits(uint256 _tokenId, string memory _newTraits) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        NFTs[_tokenId].dynamicTraits = _newTraits;
    }

    /// @notice Simulates AI personalization to recommend NFTs to a user.
    /// @dev This is a simplified simulation. In a real application, this would involve off-chain AI.
    /// @param _user Address of the user to personalize for.
    /// @return An array of NFT token IDs recommended for the user.
    function personalizeNFTRecommendation(address _user) public view whenNotPaused returns (uint256[] memory) {
        // --- Simplified Personalization Logic (Replace with real AI integration in practice) ---
        uint256[] memory recommendedNFTs = new uint256[](3); // Recommend top 3
        uint256 bestScore = 0;
        uint256 bestNFTIndex = 0;
        uint256 recommendationCount = 0;

        for (uint256 i = 1; i <= nftCounter; i++) {
            if (NFTs[i].id != 0) { // Check if NFT exists
                // In a real system, personalizationScore would be influenced by AI based on user data
                // Here, we use a simple simulation based on NFT ID for demonstration
                uint256 currentScore = (NFTs[i].id * 10) % 100; // Example score
                if (currentScore > bestScore) {
                    bestScore = currentScore;
                    bestNFTIndex = i;
                }
                 if (recommendationCount < 3) {
                    recommendedNFTs[recommendationCount] = i;
                    recommendationCount++;
                 }
            }
        }

        // In a real system, you might sort NFTs by personalizationScore and return top recommendations
        return recommendedNFTs;
    }


    /// @notice Records user interactions with NFTs for personalization (e.g., views, likes).
    /// @param _user Address of the user interacting.
    /// @param _tokenId ID of the NFT interacted with.
    /// @param _interaction Type of interaction (VIEW, LIKE, BUY, SHARE).
    function recordNFTInteraction(address _user, uint256 _tokenId, InteractionType _interaction) public whenNotPaused nftExists(_tokenId) {
        // --- Simplified Interaction Recording (Expand based on AI requirements) ---
        if (_interaction == InteractionType.VIEW) {
            NFTs[_tokenId].personalizationScore += 1; // Increase score on view
        } else if (_interaction == InteractionType.LIKE) {
            NFTs[_tokenId].personalizationScore += 5; // Increase score more on like
        } else if (_interaction == InteractionType.BUY) {
            NFTs[_tokenId].personalizationScore += 10; // Significant increase on buy
        } // Add logic for other interaction types as needed

        // In a real system, this data would be fed to an off-chain AI personalization engine
        // which would update user profiles and NFT recommendations.
    }


    // --- Marketplace Functions ---

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param _tokenId ID of the NFT to list.
    /// @param _price Price to list the NFT for (in wei).
    function listNFTForSale(uint256 _tokenId, uint256 _price) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(!NFTs[_tokenId].isFractionalized, "Fractionalized NFTs cannot be listed directly");
        require(_price > 0, "Price must be greater than zero");
        require(!NFTListings[_tokenId].isActive, "NFT is already listed for sale");

        NFTListings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true,
            listingTime: block.timestamp
        });
        emit NFTListed(_tokenId, msg.sender, _price);
    }

    /// @notice Allows anyone to buy a listed NFT.
    /// @param _tokenId ID of the NFT to buy.
    function buyNFT(uint256 _tokenId) public payable whenNotPaused nftExists(_tokenId) listingExists(_tokenId) {
        Listing storage listing = NFTListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 royaltyAmount = (price * royaltyPercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee - royaltyAmount;

        // Pay royalty to creator if it's a secondary sale
        if (NFTs[_tokenId].owner != NFTs[_tokenId].creator) {
            creatorRoyaltiesDue[NFTs[_tokenId].creator] += royaltyAmount;
            emit NFTRoyaltyPaid(_tokenId, NFTs[_tokenId].creator, royaltyAmount);
        }

        // Transfer NFT ownership
        NFTs[_tokenId].owner = msg.sender;
        NFTListings[_tokenId].isActive = false; // Deactivate listing

        // Send funds to seller and marketplace (fee)
        payable(seller).transfer(sellerPayout);
        payable(admin).transfer(marketplaceFee);

        emit NFTBought(_tokenId, msg.sender, seller, price);

        recordNFTInteraction(msg.sender, _tokenId, InteractionType.BUY); // Record buy interaction
    }

    /// @notice Allows the seller to cancel an NFT listing.
    /// @param _tokenId ID of the NFT listing to cancel.
    function cancelNFTSale(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) listingExists(_tokenId) onlyNFTOwner(_tokenId) {
        NFTListings[_tokenId].isActive = false;
        emit NFTListingCancelled(_tokenId, msg.sender);
    }

    /// @notice Allows users to place bids on NFTs.
    /// @param _tokenId ID of the NFT to bid on.
    function placeBidOnNFT(uint256 _tokenId) public payable whenNotPaused nftExists(_tokenId) {
        require(msg.value > 0, "Bid amount must be greater than zero");

        bidCounter++;
        uint256 bidId = bidCounter;
        NFTBids[_tokenId].push(Bid({
            id: bidId,
            tokenId: _tokenId,
            bidder: msg.sender,
            amount: msg.value,
            bidTime: block.timestamp,
            isActive: true
        }));
        emit NFTBidPlaced(bidId, _tokenId, msg.sender, msg.value);
    }

    /// @notice Allows the seller to accept a bid on an NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _bidId ID of the bid to accept.
    function acceptNFTBid(uint256 _tokenId, uint256 _bidId) public whenNotPaused nftExists(_tokenId) listingExists(_tokenId) onlyNFTOwner(_tokenId) bidExists(_tokenId, _bidId) {
        Listing storage listing = NFTListings[_tokenId];
        require(listing.seller == msg.sender, "Only the seller can accept bids");

        Bid storage bid = NFTBids[_tokenId][_bidId - 1]; // Adjust index for array
        require(bid.tokenId == _tokenId, "Bid is not for this NFT");
        require(bid.isActive, "Bid is not active");

        address seller = listing.seller;
        address bidder = bid.bidder;
        uint256 price = bid.amount;

        // Calculate marketplace fee and royalty
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 100;
        uint256 royaltyAmount = (price * royaltyPercentage) / 100;
        uint256 sellerPayout = price - marketplaceFee - royaltyAmount;

        // Pay royalty to creator if it's a secondary sale
        if (NFTs[_tokenId].owner != NFTs[_tokenId].creator) {
            creatorRoyaltiesDue[NFTs[_tokenId].creator] += royaltyAmount;
            emit NFTRoyaltyPaid(_tokenId, NFTs[_tokenId].creator, royaltyAmount);
        }

        // Transfer NFT ownership
        NFTs[_tokenId].owner = bidder;
        NFTListings[_tokenId].isActive = false; // Deactivate listing
        bid.isActive = false; // Deactivate bid

        // Send funds to seller and marketplace (fee)
        payable(seller).transfer(sellerPayout);
        payable(admin).transfer(marketplaceFee);

        emit NFTBidAccepted(_bidId, _tokenId, seller, bidder, price);
        emit NFTBought(_tokenId, bidder, seller, price); // Emit NFTBought event for consistency

        recordNFTInteraction(bidder, _tokenId, InteractionType.BUY); // Record buy interaction
    }

    /// @notice Retrieves details of an NFT listing.
    /// @param _tokenId ID of the NFT.
    /// @return Listing struct containing listing details.
    function getNFTListingDetails(uint256 _tokenId) public view nftExists(_tokenId) returns (Listing memory) {
        return NFTListings[_tokenId];
    }

    /// @notice Retrieves all bids for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Array of Bid structs for the NFT.
    function getNFTBids(uint256 _tokenId) public view nftExists(_tokenId) returns (Bid[] memory) {
        return NFTBids[_tokenId];
    }


    // --- Fractional Ownership & Voting Functions ---

    /// @notice Fractionalizes an NFT into shares.
    /// @param _tokenId ID of the NFT to fractionalize.
    /// @param _shares Number of shares to fractionalize into.
    function fractionalizeNFT(uint256 _tokenId, uint256 _shares) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(!NFTs[_tokenId].isFractionalized, "NFT is already fractionalized");
        require(_shares > 1, "Must fractionalize into more than one share");

        NFTs[_tokenId].isFractionalized = true;
        NFTs[_tokenId].totalShares = _shares;
        nftShares[_tokenId][msg.sender] = _shares; // Initial owner gets all shares

        emit NFTFractionalized(_tokenId, _shares);
    }

    /// @notice Allows users to buy shares of a fractionalized NFT.
    /// @param _tokenId ID of the fractionalized NFT.
    /// @param _sharesToBuy Number of shares to buy.
    function buyNFTShares(uint256 _tokenId, uint256 _sharesToBuy) public payable whenNotPaused nftExists(_tokenId) {
        require(NFTs[_tokenId].isFractionalized, "NFT is not fractionalized");
        require(_sharesToBuy > 0, "Must buy at least one share");
        require(_sharesToBuy <= NFTs[_tokenId].totalShares - totalSharesOwned(_tokenId), "Not enough shares available");

        uint256 sharePrice = 0.01 ether; // Example share price - can be dynamic
        uint256 totalPrice = sharePrice * _sharesToBuy;
        require(msg.value >= totalPrice, "Insufficient funds to buy shares");

        nftShares[_tokenId][msg.sender] += _sharesToBuy;
        payable(NFTs[_tokenId].owner).transfer(totalPrice); // Send funds to original fractional owner

        emit NFTSharesBought(_tokenId, msg.sender, _sharesToBuy);
    }

    /// @notice Internal function to calculate total shares owned for an NFT.
    function totalSharesOwned(uint256 _tokenId) internal view returns (uint256) {
        uint256 totalOwned = 0;
        for (uint256 i = 1; i <= nftCounter; i++) { // Iterate through all possible users (inefficient in large scale - optimize if needed)
            if (nftShares[_tokenId][address(uint160(i))] > 0) { // Example: Iterate through potential user addresses
                totalOwned += nftShares[_tokenId][address(uint160(i))];
            }
        }
        return totalOwned;
    }


    /// @notice Allows fractional owners to propose actions for the NFT.
    /// @param _tokenId ID of the fractionalized NFT.
    /// @param _actionDescription Description of the proposed action.
    function proposeNFTAction(uint256 _tokenId, string memory _actionDescription) public whenNotPaused nftExists(_tokenId) onlyFractionalOwner(_tokenId) {
        require(NFTs[_tokenId].isFractionalized, "Action proposals only for fractionalized NFTs");

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        NFTProposals[_tokenId].push(NFTActionProposal({
            id: proposalId,
            tokenId: _tokenId,
            description: _actionDescription,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true
        }));
        emit NFTActionProposed(proposalId, _tokenId, msg.sender, _actionDescription);
    }

    /// @notice Allows fractional owners to vote on NFT actions.
    /// @param _tokenId ID of the fractionalized NFT.
    /// @param _proposalId ID of the action proposal.
    /// @param _vote True for vote in favor, false for vote against.
    function voteOnNFTAction(uint256 _tokenId, uint256 _proposalId, bool _vote) public whenNotPaused nftExists(_tokenId) onlyFractionalOwner(_tokenId) proposalExists(_tokenId, _proposalId) {
        NFTActionProposal storage proposal = NFTProposals[_tokenId][_proposalId - 1]; // Adjust index

        require(proposal.isActive, "Proposal is not active");

        if (_vote) {
            proposal.votesFor += nftShares[_tokenId][msg.sender]; // Weight vote by shares owned
        } else {
            proposal.votesAgainst += nftShares[_tokenId][msg.sender];
        }
        emit NFTActionVoted(_proposalId, _tokenId, msg.sender, _vote);
    }

    /// @notice Executes an approved NFT action (simple example: updating dynamic traits if majority votes yes).
    /// @param _tokenId ID of the fractionalized NFT.
    /// @param _proposalId ID of the action proposal.
    function executeNFTAction(uint256 _tokenId, uint256 _proposalId) public whenNotPaused nftExists(_tokenId) proposalExists(_tokenId, _proposalId) {
        NFTActionProposal storage proposal = NFTProposals[_tokenId][_proposalId - 1]; // Adjust index
        require(proposal.isActive, "Proposal is not active");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 majorityThreshold = NFTs[_tokenId].totalShares / 2 + 1; // Simple majority

        if (proposal.votesFor >= majorityThreshold) {
            // --- Example Action: Update dynamic traits based on proposal description ---
            updateDynamicTraits(_tokenId, proposal.description); // Using description as new traits for simplicity
            proposal.isActive = false; // Deactivate proposal after execution
            emit NFTActionExecuted(_proposalId, _tokenId);
        } else {
            revert("Proposal not approved by majority");
        }
    }


    // --- Royalty & Creator Functions ---

    /// @notice Sets the royalty percentage for all NFTs (admin-only).
    /// @param _royaltyPercentage New royalty percentage (e.g., 5 for 5%).
    function setRoyaltyPercentage(uint256 _royaltyPercentage) public onlyAdmin {
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100%");
        royaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageUpdated(_royaltyPercentage);
    }

    /// @notice Returns the current royalty percentage.
    /// @return The royalty percentage.
    function getRoyaltyPercentage() public view returns (uint256) {
        return royaltyPercentage;
    }

    /// @notice Allows creators to withdraw accumulated royalties.
    function withdrawCreatorRoyalties() public {
        uint256 amount = creatorRoyaltiesDue[msg.sender];
        require(amount > 0, "No royalties to withdraw");
        creatorRoyaltiesDue[msg.sender] = 0; // Reset royalty balance
        payable(msg.sender).transfer(amount);
    }


    // --- Staking & Rewards Functions ---

    /// @notice Allows users to stake their NFTs for rewards.
    /// @param _tokenId ID of the NFT to stake.
    function stakeNFT(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(!isNFTStaked[_tokenId], "NFT is already staked");
        isNFTStaked[_tokenId] = true;
        nftStakingStartTime[_tokenId] = block.timestamp;
        emit NFTStaked(_tokenId, msg.sender);
    }

    /// @notice Allows users to unstake their NFTs.
    /// @param _tokenId ID of the NFT to unstake.
    function unstakeNFT(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(isNFTStaked[_tokenId], "NFT is not staked");
        claimStakingRewards(_tokenId); // Automatically claim rewards before unstaking
        isNFTStaked[_tokenId] = false;
        delete nftStakingStartTime[_tokenId]; // Remove staking start time
        emit NFTUnstaked(_tokenId, msg.sender);
    }

    /// @notice Allows users to claim staking rewards for their staked NFTs.
    /// @param _tokenId ID of the staked NFT.
    function claimStakingRewards(uint256 _tokenId) public whenNotPaused nftExists(_tokenId) onlyNFTOwner(_tokenId) {
        require(isNFTStaked[_tokenId], "NFT is not staked");

        uint256 startTime = nftStakingStartTime[_tokenId];
        uint256 currentTime = block.timestamp;
        uint256 stakingDurationBlocks = (currentTime - startTime) / 15; // Assuming 15 seconds per block - adjust based on network
        uint256 rewards = stakingDurationBlocks * stakingRewardPerBlock;

        if (rewards > 0) {
            payable(msg.sender).transfer(rewards);
            emit StakingRewardsClaimed(_tokenId, msg.sender, rewards);
        }
        nftStakingStartTime[_tokenId] = block.timestamp; // Reset start time for next reward calculation
    }


    // --- Admin & Governance Functions ---

    /// @notice Sets the marketplace fee percentage (admin-only).
    /// @param _feePercentage New marketplace fee percentage (e.g., 2 for 2%).
    function setMarketplaceFee(uint256 _feePercentage) public onlyAdmin {
        require(_feePercentage <= 100, "Marketplace fee percentage cannot exceed 100%");
        marketplaceFeePercentage = _feePercentage;
        emit MarketplaceFeeUpdated(_feePercentage);
    }

    /// @notice Returns the current marketplace fee percentage.
    /// @return The marketplace fee percentage.
    function getMarketplaceFee() public view returns (uint256) {
        return marketplaceFeePercentage;
    }

    /// @notice Pauses the contract, preventing most functions from being called (admin-only).
    function pauseContract() public onlyAdmin whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing functions to be called again (admin-only).
    function unpauseContract() public onlyAdmin whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows the admin to withdraw the contract's ETH balance (e.g., collected fees).
    function withdrawContractBalance() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit AdminWithdrawal(balance);
    }


    // --- Utility Functions ---

    /// @notice Returns the contract's ETH balance.
    /// @return The contract's ETH balance.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Checks if the contract is paused.
    /// @return True if paused, false otherwise.
    function isContractPaused() public view returns (bool) {
        return contractPaused;
    }

    // Fallback function to receive ETH (for bidding, buying, etc.)
    receive() external payable {}
}
```