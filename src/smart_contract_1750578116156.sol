Okay, here is a smart contract concept focusing on a **Dynamic NFT Marketplace with Gamified Evolution and Community Governance Lite**. This combines several advanced and trendy concepts:

1.  **Dynamic NFTs:** The NFTs themselves have attributes that can change *on-chain* based on activity or events.
2.  **Gamified Evolution:** Specific actions (like participating via a function call) or holding time contribute to an NFT's "Activity Score" or "Maturity", potentially changing its state or visual representation (via metadata URI updates).
3.  **Decentralized Marketplace:** Users can list and trade these specific dynamic NFTs.
4.  **Dynamic Royalties:** Royalties might change based on the NFT's sales history (e.g., increasing slightly with each resale).
5.  **Governance Lite:** NFT holders have voting power to propose and vote on simple parameter changes for the contract (like marketplace fee percentage, base royalty rate, or thresholds for dynamic changes).

This contract aims for originality by integrating these features into a single, cohesive system where the NFT's value and attributes are tied to its history, holder activity, and community influence, rather than just static metadata.

---

## Smart Contract: DynamicNFTMarketplace

**Core Concepts:**

*   **Dynamic NFTs:** ERC721 tokens with on-chain attributes that evolve.
*   **Gamified Evolution:** NFT attributes (like activity score, maturity) change based on user interaction and time held.
*   **Decentralized Marketplace:** Platform for listing and trading these specific dynamic NFTs.
*   **Dynamic Royalties:** Royalty percentage potentially increases based on sales count per token.
*   **Governance Lite:** NFT holders vote on proposals to adjust contract parameters.

**Key Features:**

*   Minting of NFTs with initial dynamic attributes.
*   Functions for users to interact and boost their NFT's activity score.
*   Marketplace for listing, buying, and canceling orders.
*   Calculation of dynamic royalties based on sales history.
*   Community proposal and voting system using NFT holdings for power.
*   Admin functions for emergency control and treasury management.

**Outline and Function Summary:**

1.  **Interfaces & Libraries:** Import ERC721, Ownable, Pausable, ReentrancyGuard.
2.  **Error Definitions:** Custom errors for clarity and gas efficiency.
3.  **State Variables:**
    *   `NFTDynamics` struct: Stores dynamic attributes per token (e.g., creation time, last activity time, activity score, sales count).
    *   `Listing` struct: Stores marketplace listing details (seller, price).
    *   `Proposal` struct: Stores governance proposal details (description, parameter ID, new value, vote counts, state).
    *   Mappings: To store NFT dynamics, listings, token IDs to listing indices (if needed for retrieval), proposal details, vote records per voter/proposal.
    *   Counters: For token IDs, proposal IDs.
    *   Parameters: Marketplace fee, base royalty, royalty boost per sale, voting threshold, voting period.
4.  **Events:** For Minting, Listing, Buying, Canceling, Attribute Updates, Proposal Creation, Voting, Proposal Execution.
5.  **Modifiers:** `onlyNFTOwner`, `onlyListedItem`, `onlyActiveProposal`, `hasVotingPower`.
6.  **Constructor:** Initializes ERC721, sets initial owner and parameters.
7.  **NFT Dynamics & Minting (approx. 5 functions):**
    *   `mintWithDynamics(address to, string calldata uri)`: Mints a new NFT, assigning initial dynamic attributes.
    *   `updateNFTActivity(uint256 tokenId)`: Allows the token owner to 'interact' with their NFT, increasing its activity score.
    *   `getNFTDynamics(uint256 tokenId)`: View function to retrieve the current dynamic attributes of an NFT.
    *   `getNFTCurrentValueScore(uint256 tokenId)`: View function that calculates a potential value score based on dynamics (activity, age, sales count).
    *   `tokenURI(uint256 tokenId)`: Overrides ERC721's tokenURI to potentially reflect dynamic attributes (e.g., point to different metadata based on score/maturity).
8.  **Marketplace (approx. 6 functions):**
    *   `listNFT(uint256 tokenId, uint256 price)`: Lists an NFT for sale at a fixed price. Requires NFT approval/transfer to the contract.
    *   `cancelListing(uint256 tokenId)`: Cancels an active listing. Only callable by the seller.
    *   `buyNFT(uint256 tokenId)`: Allows a user to purchase a listed NFT. Handles price payment, fee deduction, royalty distribution, NFT transfer, and updates sales count.
    *   `getListing(uint256 tokenId)`: View function to get details of an active listing.
    *   `getListedNFTsBySeller(address seller)`: View function to retrieve all token IDs listed by a specific seller.
    *   `getMarketplaceFeePercentage()`: View function to get the current marketplace fee percentage.
9.  **Dynamic Royalties (approx. 2 functions):**
    *   `getRoyaltyInfo(uint256 tokenId, uint256 salePrice)`: View function to calculate the royalty amount and recipient based on the current sales count for that token.
    *   `setBaseRoyaltyPercentage(uint16 percentage)`: Governance-controlled function to set the base royalty rate.
    *   `setRoyaltyBoostPerSale(uint16 percentageBoost)`: Governance-controlled function to set how much the royalty percentage increases per sale.
10. **Governance Lite (approx. 6 functions):**
    *   `createParameterProposal(string calldata description, uint8 parameterId, int256 newValue)`: Allows NFT holders to propose changes to specific contract parameters.
    *   `voteOnProposal(uint256 proposalId, bool support)`: Allows NFT holders to cast their vote (yes/no) on an active proposal. Voting power is proportional to the number of NFTs held.
    *   `executeProposal(uint256 proposalId)`: Allows anyone to execute a proposal that has met the voting threshold and the voting period has ended.
    *   `getProposal(uint256 proposalId)`: View function to get details of a specific proposal.
    *   `getVoteCount(uint256 proposalId, bool support)`: View function to get the current yes/no vote counts for a proposal.
    *   `getCurrentVotingPower(address voter)`: View function to calculate the current voting power of an address based on their NFT holdings.
11. **Admin & Utility (approx. 3 functions):**
    *   `withdrawMarketplaceFees()`: Allows the contract owner (or a designated treasury address set by governance) to withdraw accumulated marketplace fees.
    *   `pause()`: Pauses sensitive contract functions (listing, buying, voting, proposal creation).
    *   `unpause()`: Unpauses the contract.

**(Total functions: ~22+)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title DynamicNFTMarketplace
/// @dev A marketplace for dynamic NFTs whose attributes evolve based on user activity and sales history.
/// @dev Features dynamic royalties and a lightweight governance system based on NFT ownership.

contract DynamicNFTMarketplace is ERC721, Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256;

    // --- Custom Error Definitions ---
    error InvalidPrice();
    error NFTNotApprovedForMarketplace();
    error ItemNotListed();
    error NotSeller();
    error InsufficientPayment();
    error PurchaseFailed();
    error NFTAlreadyListed();
    error CannotBuyOwnNFT();
    error RoyaltyRecipientZeroAddress();
    error ParameterValueOutOfRange();
    error ProposalNotFound();
    error ProposalAlreadyActiveOrExecuted();
    error ProposalNotActive();
    error ProposalNotExecutable();
    error AlreadyVoted();
    error NoVotingPower();
    error InvalidProposalParameterId();
    error ListingNotFound();
    error ERC721TransferFailed();


    // --- State Variables & Structs ---

    /// @dev Stores dynamic attributes for each token.
    struct NFTDynamics {
        uint64 creationTime;      // Timestamp of creation
        uint64 lastActivityTime;  // Timestamp of last activity update
        uint256 activityScore;    // Score representing user interaction
        uint256 salesCount;       // Number of times the NFT has been sold on this marketplace
        string metadataUri;       // Base URI, potentially updated dynamically
    }

    /// @dev Stores details for an NFT listing on the marketplace.
    struct Listing {
        address seller;
        uint256 price;
        uint64 startTime; // Timestamp when listed
        bool isActive;
    }

    /// @dev Enum for parameters that can be changed via governance.
    enum ProposalParameter {
        MarketplaceFeePercentage,
        BaseRoyaltyPercentage,
        RoyaltyBoostPerSale,
        VotingThresholdNumerator, // For fractional threshold (Numerator/Denominator)
        VotingThresholdDenominator,
        VotingPeriod
    }

    /// @dev Stores details for a governance proposal.
    struct Proposal {
        string description;
        ProposalParameter parameterId;
        int256 newValue; // Use int256 as some parameters (like thresholds) might need complex representation
        uint256 yesVotes;
        uint256 noVotes;
        uint64 votingEndTime;
        bool executed;
        bool exists; // To differentiate between non-existent and initialized proposals
    }

    // Mappings
    mapping(uint256 => NFTDynamics) private _tokenDynamics;
    mapping(uint256 => Listing) private _listings;
    mapping(uint256 => mapping(address => bool)) private _proposalVotes; // proposalId => voterAddress => voted
    mapping(address => uint256[]) private _listedNFTsBySeller; // seller => array of listed tokenIds

    // Counters
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Marketplace & Royalty Parameters (can be changed via governance)
    uint16 public marketplaceFeePercentage; // Bips (1/100 of a percent), e.g., 100 = 1%
    uint16 public baseRoyaltyPercentage;    // Bips
    uint16 public royaltyBoostPerSale;      // Bips increase per sale

    // Governance Parameters
    uint256 public votingThresholdNumerator; // Minimum percentage (numerator) of total voting power needed to pass
    uint256 public votingThresholdDenominator; // Denominator for voting threshold (e.g., 50/100 for 50%)
    uint64 public votingPeriod;             // Duration in seconds for proposals

    // Accumulated Fees
    uint256 public marketplaceFeesAccumulated;

    // Address for fee distribution (can be a multisig or DAO treasury)
    address public feeRecipient;


    // --- Events ---

    event NFTMinted(uint256 indexed tokenId, address indexed owner, string uri);
    event NFTActivityUpdated(uint256 indexed tokenId, uint256 newActivityScore, uint64 lastActivity);
    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price, uint64 startTime);
    event NFTCancelled(uint256 indexed tokenId);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price, uint256 feeAmount, uint256 royaltyAmount, address royaltyRecipient);
    event ParameterProposalCreated(uint256 indexed proposalId, string description, ProposalParameter parameterId, int256 newValue, address indexed creator);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId, ProposalParameter parameterId, int256 newValue);
    event MarketplaceFeePercentageUpdated(uint16 newPercentage);
    event BaseRoyaltyPercentageUpdated(uint16 newPercentage);
    event RoyaltyBoostPerSaleUpdated(uint16 newBoost);
    event VotingThresholdUpdated(uint256 numerator, uint256 denominator);
    event VotingPeriodUpdated(uint64 newPeriod);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);


    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint16 initialMarketplaceFeeBips,
        uint16 initialBaseRoyaltyBips,
        uint16 initialRoyaltyBoostBips,
        uint256 initialVotingThresholdNumerator,
        uint256 initialVotingThresholdDenominator,
        uint64 initialVotingPeriodSeconds,
        address initialFeeRecipient
    )
        ERC721(name, symbol)
        Ownable(msg.sender) // Initial owner is the deployer
        Pausable()
        ReentrancyGuard()
    {
        if (initialFeeRecipient == address(0)) revert RoyaltyRecipientZeroAddress();
        if (initialMarketplaceFeeBips > 10000) revert ParameterValueOutOfRange(); // Max 100%
        if (initialBaseRoyaltyBips > 10000) revert ParameterValueOutOfRange(); // Max 100%
        if (initialVotingThresholdDenominator == 0) revert ParameterValueOutOfRange();

        marketplaceFeePercentage = initialMarketplaceFeeBips;
        baseRoyaltyPercentage = initialBaseRoyaltyBips;
        royaltyBoostPerSale = initialRoyaltyBoostBips;
        votingThresholdNumerator = initialVotingThresholdNumerator;
        votingThresholdDenominator = initialVotingThresholdDenominator;
        votingPeriod = initialVotingPeriodSeconds;
        feeRecipient = initialFeeRecipient;
    }


    // --- Pausable Overrides ---
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- ERC721 Overrides & Extensions ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        NFTDynamics storage dynamics = _tokenDynamics[tokenId];
        // Simple example: Append activity score to URI. More complex logic needed for real metadata changes.
        if (dynamics.activityScore > 0) {
             return string(abi.encodePacked(dynamics.metadataUri, "?activity=", dynamics.activityScore.toString()));
        }
        return dynamics.metadataUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Cancel listing if the NFT is transferred while listed (except transfers to/from self or approved operators)
        if (from != address(0) && to != address(0)) {
             // Check if the transfer is NOT part of the buy process initiated by this contract
             // This check is simplified. A more robust check might track transfers initiated internally.
            if (_listings[tokenId].isActive && msg.sender != address(this) && msg.sender != from && msg.sender != to) {
                 _cancelListingInternal(tokenId);
            }
        }
    }


    // --- Dynamic NFT Functions ---

    /// @dev Mints a new NFT and sets its initial dynamic attributes.
    /// @param to The recipient of the new NFT.
    /// @param uri The metadata URI for the NFT.
    function mintWithDynamics(address to, string calldata uri) public onlyOwner nonReentrant {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        _tokenDynamics[newTokenId] = NFTDynamics({
            creationTime: uint64(block.timestamp),
            lastActivityTime: uint64(block.timestamp),
            activityScore: 0,
            salesCount: 0,
            metadataUri: uri
        });

        emit NFTMinted(newTokenId, to, uri);
    }

    /// @dev Allows the current owner of the NFT to update its activity score.
    /// @dev This is a gamified interaction point. Could be time-gated or cost ETH.
    /// @param tokenId The ID of the NFT to update.
    function updateNFTActivity(uint256 tokenId) public nonReentrant whenNotPaused {
        _requireOwned(tokenId); // Ensure caller owns the token
        NFTDynamics storage dynamics = _tokenDynamics[tokenId];

        // Example logic: Increase score, update last activity time. Could add cooldowns.
        dynamics.activityScore = dynamics.activityScore + 1;
        dynamics.lastActivityTime = uint64(block.timestamp);

        // Optionally update metadata URI based on score here or let tokenURI handle it.
        // Example: if (dynamics.activityScore % 10 == 0) dynamics.metadataUri = "new_uri_for_level_" + (dynamics.activityScore/10).toString();

        emit NFTActivityUpdated(tokenId, dynamics.activityScore, dynamics.lastActivityTime);
    }

    /// @dev Gets the current dynamic attributes of an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The NFTDynamics struct for the token.
    function getNFTDynamics(uint256 tokenId) public view returns (NFTDynamics memory) {
        return _tokenDynamics[tokenId];
    }

     /// @dev Calculates a simple value score based on the NFT's dynamics and sales count.
     /// @dev This is a simplified example score calculation.
     /// @param tokenId The ID of the NFT.
     /// @return A calculated score.
    function getNFTCurrentValueScore(uint256 tokenId) public view returns (uint256) {
        NFTDynamics storage dynamics = _tokenDynamics[tokenId];
        uint256 age = block.timestamp - dynamics.creationTime; // Can be large
        uint256 activity = dynamics.activityScore;
        uint256 sales = dynamics.salesCount;

        // Simple weighted sum: activity + (sales * boost) + (age / time_factor)
        // Avoid large numbers or division by zero.
        uint256 timeFactor = 1 days; // Scale down age contribution
        uint256 ageContribution = age / timeFactor;

        uint256 score = activity + (sales * 5) + ageContribution; // Example weights

        return score;
    }


    // --- Marketplace Functions ---

    /// @dev Lists an NFT for sale on the marketplace.
    /// @param tokenId The ID of the NFT to list.
    /// @param price The price in native currency (ETH/MATIC/etc.) for the listing.
    function listNFT(uint256 tokenId, uint256 price) public nonReentrant whenNotPaused {
        if (price <= 0) revert InvalidPrice();
        if (_listings[tokenId].isActive) revert NFTAlreadyListed();
        _requireOwned(tokenId); // Ensure caller owns the token

        // Transfer NFT to the marketplace contract
        // Caller must have approved the contract first via ERC721's approve() or setApprovalForAll()
        try transferFrom(msg.sender, address(this), tokenId) {
            // Successfully transferred
        } catch Error(string memory reason) {
            revert ERC721TransferFailed(); // Indicate transfer failure
        } catch Panic(uint reason) {
            revert ERC721TransferFailed(); // Indicate transfer failure
        }


        _listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            startTime: uint64(block.timestamp),
            isActive: true
        });

        _listedNFTsBySeller[msg.sender].push(tokenId);

        emit NFTListed(tokenId, msg.sender, price, _listings[tokenId].startTime);
    }

    /// @dev Cancels an active NFT listing.
    /// @param tokenId The ID of the NFT listing to cancel.
    function cancelListing(uint256 tokenId) public nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isActive) revert ItemNotListed();
        if (listing.seller != msg.sender) revert NotSeller();

        _cancelListingInternal(tokenId);
    }

    /// @dev Internal function to cancel a listing and transfer NFT back.
    function _cancelListingInternal(uint256 tokenId) internal {
         Listing storage listing = _listings[tokenId];
         require(listing.isActive, "Listing must be active"); // Internal check

         listing.isActive = false; // Mark as inactive immediately

         // Find and remove token ID from seller's listed array (quadratic complexity, optimize for many listings if needed)
         uint256[] storage sellerListings = _listedNFTsBySeller[listing.seller];
         for (uint i = 0; i < sellerListings.length; i++) {
             if (sellerListings[i] == tokenId) {
                 sellerListings[i] = sellerListings[sellerListings.length - 1];
                 sellerListings.pop();
                 break;
             }
         }

         // Transfer NFT back to the seller
         try transferFrom(address(this), listing.seller, tokenId) {
             // Successfully transferred back
         } catch Error(string memory reason) {
             // Log or handle error if transfer back fails (rare but possible)
             emit ERC721TransferFailed(); // Use event for non-reverting error
         } catch Panic(uint reason) {
            emit ERC721TransferFailed(); // Use event for non-reverting error
         }

         emit NFTCancelled(tokenId);
    }


    /// @dev Allows a user to buy a listed NFT.
    /// @param tokenId The ID of the NFT to buy.
    function buyNFT(uint256 tokenId) public payable nonReentrant whenNotPaused {
        Listing storage listing = _listings[tokenId];
        if (!listing.isActive) revert ItemNotListed();
        if (listing.seller == msg.sender) revert CannotBuyOwnNFT();
        if (msg.value < listing.price) revert InsufficientPayment();

        address seller = listing.seller;
        uint256 price = listing.price;

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeePercentage) / 10000;
        (uint256 royaltyAmount, address royaltyRecipient) = getRoyaltyInfo(tokenId, price);

        uint256 amountForSeller = price - marketplaceFee - royaltyAmount;

        // Mark listing inactive BEFORE sending funds/transferring NFT
        listing.isActive = false;

        // Find and remove token ID from seller's listed array (same optimization note as cancel)
         uint256[] storage sellerListings = _listedNFTsBySeller[listing.seller];
         for (uint i = 0; i < sellerListings.length; i++) {
             if (sellerListings[i] == tokenId) {
                 sellerListings[i] = sellerListings[sellerListings.length - 1];
                 sellerListings.pop();
                 break;
             }
         }


        // Increment sales count BEFORE transferring ownership
        _tokenDynamics[tokenId].salesCount++;
        _tokenDynamics[tokenId].lastActivityTime = uint64(block.timestamp); // Buying counts as activity? Maybe.

        // Transfer NFT to buyer
        try transferFrom(address(this), msg.sender, tokenId) {
            // Successfully transferred
        } catch Error(string memory reason) {
             revert ERC721TransferFailed(); // Indicate transfer failure
        } catch Panic(uint reason) {
            revert ERC721TransferFailed(); // Indicate transfer failure
        }

        // Distribute funds (use pull pattern for safety)
        // Seller gets their cut (minus fees and royalties)
        (bool successSeller, ) = payable(seller).call{value: amountForSeller}("");
        require(successSeller, "Seller payment failed");

        // Royalty recipient gets their cut
        if (royaltyAmount > 0 && royaltyRecipient != address(0)) {
             (bool successRoyalty, ) = payable(royaltyRecipient).call{value: royaltyAmount}("");
             // Do not revert if royalty payment fails, potentially log it or let recipient claim later
             // For simplicity, we revert here, but a robust system might handle this differently.
             require(successRoyalty, "Royalty payment failed");
        }


        // Marketplace fee is held in the contract
        marketplaceFeesAccumulated += marketplaceFee;

        // Return any excess payment to the buyer
        if (msg.value > price) {
            (bool successRefund, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(successRefund, "Refund failed");
        }


        emit NFTSold(tokenId, msg.sender, seller, price, marketplaceFee, royaltyAmount, royaltyRecipient);
    }

    /// @dev Gets details of a specific NFT listing.
    /// @param tokenId The ID of the NFT.
    /// @return The Listing struct for the token.
    function getListing(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }

    /// @dev Gets a list of token IDs currently listed by a seller.
    /// @param seller The address of the seller.
    /// @return An array of listed token IDs.
    function getListedNFTsBySeller(address seller) public view returns (uint256[] memory) {
        // This mapping might contain old data from cancelled/sold listings if not cleaned up perfectly.
        // The buy/cancel logic does clean this up.
        return _listedNFTsBySeller[seller];
    }

    /// @dev Gets the current marketplace fee percentage.
    function getMarketplaceFeePercentage() public view returns (uint16) {
        return marketplaceFeePercentage;
    }


    // --- Dynamic Royalty Functions ---

    /// @dev Calculates the royalty amount and recipient for a sale.
    /// @param tokenId The ID of the NFT.
    /// @param salePrice The price of the sale.
    /// @return royaltyAmount The calculated royalty amount.
    /// @return royaltyRecipient The address to send the royalty to (e.g., original creator or feeRecipient).
    function getRoyaltyInfo(uint256 tokenId, uint256 salePrice) public view returns (uint256 royaltyAmount, address royaltyRecipient) {
        NFTDynamics storage dynamics = _tokenDynamics[tokenId];
        uint256 currentSalesCount = dynamics.salesCount;

        // Calculate dynamic royalty percentage: base + (salesCount * boost)
        uint256 effectiveRoyaltyPercentage = baseRoyaltyPercentage + (currentSalesCount * royaltyBoostPerSale);

        // Cap royalty at 100% (10000 Bips)
        effectiveRoyaltyPercentage = effectiveRoyaltyPercentage.min(10000);

        royaltyAmount = (salePrice * effectiveRoyaltyPercentage) / 10000;

        // Define royalty recipient. Could be original creator (requires tracking),
        // a fixed address, or controlled by governance. Using feeRecipient for simplicity here.
        royaltyRecipient = feeRecipient; // Or ownerOf(tokenId) if original creator was tracked

        return (royaltyAmount, royaltyRecipient);
    }

    // Note: setBaseRoyaltyPercentage and setRoyaltyBoostPerSale are governance controlled (see below)


    // --- Governance Lite Functions ---

    /// @dev Calculates the voting power of an address based on their NFT holdings.
    /// @param voter The address to calculate voting power for.
    /// @return The number of NFTs owned by the voter.
    function getCurrentVotingPower(address voter) public view returns (uint256) {
        // Simple voting power: 1 NFT = 1 Vote. Can be made more complex (e.g., based on activity score, holding time).
        return balanceOf(voter);
    }

    /// @dev Allows NFT holders to create a proposal to change a contract parameter.
    /// @param description A description of the proposal.
    /// @param parameterId The ID of the parameter to change.
    /// @param newValue The new value for the parameter (interpret based on parameterId).
    function createParameterProposal(string calldata description, ProposalParameter parameterId, int256 newValue) public nonReentrant whenNotPaused hasVotingPower(msg.sender) {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        // Basic validation for new value based on parameter type
        if (parameterId == ProposalParameter.MarketplaceFeePercentage || parameterId == ProposalParameter.BaseRoyaltyPercentage || parameterId == ProposalParameter.RoyaltyBoostPerSale) {
             if (newValue < 0 || newValue > 10000) revert ParameterValueOutOfRange(); // Percentages in Bips
        }
        if (parameterId == ProposalParameter.VotingThresholdNumerator) {
             if (newValue < 0) revert ParameterValueOutOfRange();
             // Cannot check against denominator here, needs execution logic
        }
         if (parameterId == ProposalParameter.VotingThresholdDenominator) {
             if (newValue <= 0) revert ParameterValueOutOfRange();
         }
         if (parameterId == ProposalParameter.VotingPeriod) {
             if (newValue <= 0) revert ParameterValueOutOfRange(); // Voting period must be positive
         }


        Proposal storage newProposal = _proposals[proposalId];
        newProposal.description = description;
        newProposal.parameterId = parameterId;
        newProposal.newValue = newValue;
        newProposal.votingEndTime = uint64(block.timestamp + votingPeriod);
        newProposal.executed = false;
        newProposal.exists = true;

        emit ParameterProposalCreated(proposalId, description, parameterId, newValue, msg.sender);
    }

    /// @dev Allows an NFT holder to vote on an active proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'yes', False for 'no'.
    function voteOnProposal(uint256 proposalId, bool support) public nonReentrant whenNotPaused hasVotingPower(msg.sender) onlyActiveProposal(proposalId) {
        if (_proposalVotes[proposalId][msg.sender]) revert AlreadyVoted();

        uint256 voterPower = getCurrentVotingPower(msg.sender);
        if (voterPower == 0) revert NoVotingPower(); // Should be caught by hasVotingPower, but double check

        Proposal storage proposal = _proposals[proposalId];

        if (support) {
            proposal.yesVotes += voterPower;
        } else {
            proposal.noVotes += voterPower;
        }

        _proposalVotes[proposalId][msg.sender] = true;

        emit Voted(proposalId, msg.sender, support, voterPower);
    }

    /// @dev Allows anyone to execute a successful proposal after the voting period ends.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public nonReentrant whenNotPaused onlyExecutableProposal(proposalId) {
        Proposal storage proposal = _proposals[proposalId];

        // Check if threshold is met
        uint256 totalVotingPower = ERC721.totalSupply(); // Total NFTs = Total Voting Power
        uint256 requiredYesVotes = (totalVotingPower * votingThresholdNumerator) / votingThresholdDenominator;

        if (proposal.yesVotes < requiredYesVotes) revert ProposalNotExecutable(); // Did not meet threshold

        // Execute the proposal
        _applyParameterChange(proposal.parameterId, proposal.newValue);

        proposal.executed = true; // Mark as executed

        emit ProposalExecuted(proposalId, proposal.parameterId, proposal.newValue);
    }

    /// @dev Applies the parameter change based on the proposal.
    function _applyParameterChange(ProposalParameter parameterId, int256 newValue) internal {
        if (parameterId == ProposalParameter.MarketplaceFeePercentage) {
            marketplaceFeePercentage = uint16(newValue);
            emit MarketplaceFeePercentageUpdated(uint16(newValue));
        } else if (parameterId == ProposalParameter.BaseRoyaltyPercentage) {
            baseRoyaltyPercentage = uint16(newValue);
            emit BaseRoyaltyPercentageUpdated(uint16(newValue));
        } else if (parameterId == ProposalParameter.RoyaltyBoostPerSale) {
            royaltyBoostPerSale = uint16(newValue);
            emit RoyaltyBoostPerSaleUpdated(uint16(newValue));
        } else if (parameterId == ProposalParameter.VotingThresholdNumerator) {
            votingThresholdNumerator = uint256(newValue);
            emit VotingThresholdUpdated(votingThresholdNumerator, votingThresholdDenominator);
        } else if (parameterId == ProposalParameter.VotingThresholdDenominator) {
            votingThresholdDenominator = uint256(newValue);
             emit VotingThresholdUpdated(votingThresholdNumerator, votingThresholdDenominator);
        } else if (parameterId == ProposalParameter.VotingPeriod) {
            votingPeriod = uint64(newValue);
             emit VotingPeriodUpdated(uint64(newValue));
        } else {
            revert InvalidProposalParameterId(); // Should not happen if enum is used correctly
        }
    }


    /// @dev Gets details of a specific governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The Proposal struct for the proposal.
    function getProposal(uint256 proposalId) public view returns (Proposal memory) {
         if (!_proposals[proposalId].exists) revert ProposalNotFound();
        return _proposals[proposalId];
    }

    /// @dev Gets the vote counts for a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for 'yes' votes, False for 'no' votes.
    /// @return The total voting power for the specified vote type.
    function getVoteCount(uint256 proposalId, bool support) public view returns (uint256) {
        if (!_proposals[proposalId].exists) revert ProposalNotFound();
        if (support) {
            return _proposals[proposalId].yesVotes;
        } else {
            return _proposals[proposalId].noVotes;
        }
    }


    // --- Admin & Utility Functions ---

    /// @dev Allows the feeRecipient address to withdraw accumulated marketplace fees.
    function withdrawMarketplaceFees() public nonReentrant {
        // Only the designated fee recipient can withdraw
        if (msg.sender != feeRecipient) revert OwnableUnauthorizedAccount(msg.sender); // Use Ownable's error for consistency

        uint256 amount = marketplaceFeesAccumulated;
        if (amount == 0) return;

        marketplaceFeesAccumulated = 0; // Set to 0 before sending

        (bool success, ) = payable(feeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");
    }

     /// @dev Allows the contract owner to update the fee recipient address.
     /// @param newFeeRecipient The new address to receive fees.
     function setFeeRecipient(address newFeeRecipient) public onlyOwner {
        if (newFeeRecipient == address(0)) revert RoyaltyRecipientZeroAddress(); // Using same error as zero address is invalid
        address oldRecipient = feeRecipient;
        feeRecipient = newFeeRecipient;
        emit FeeRecipientUpdated(oldRecipient, newFeeRecipient);
     }


    // --- Internal & Modifier Definitions ---

    mapping(uint256 => Proposal) private _proposals; // Stores proposals

    modifier onlyNFTOwner(uint256 tokenId) {
        if (_ownerOf(tokenId) != msg.sender) revert OwnableUnauthorizedAccount(msg.sender); // Using Ownable error
        _;
    }

    modifier onlyListedItem(uint256 tokenId) {
        if (!_listings[tokenId].isActive) revert ItemNotListed();
        _;
    }

    modifier hasVotingPower(address voter) {
        if (getCurrentVotingPower(voter) == 0) revert NoVotingPower();
        _;
    }

     modifier onlyActiveProposal(uint256 proposalId) {
        Proposal storage proposal = _proposals[proposalId];
        if (!proposal.exists) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyActiveOrExecuted(); // Already done
        if (block.timestamp >= proposal.votingEndTime) revert ProposalNotActive(); // Voting period ended
        _;
    }

    modifier onlyExecutableProposal(uint256 proposalId) {
        Proposal storage proposal = _proposals[proposalId];
         if (!proposal.exists) revert ProposalNotFound();
        if (proposal.executed) revert ProposalAlreadyActiveOrExecuted(); // Already done
        if (block.timestamp < proposal.votingEndTime) revert ProposalNotExecutable(); // Voting period not ended
        // Check threshold inside function body as it depends on current state (total supply)
        _;
    }
}
```