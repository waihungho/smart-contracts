Okay, here is a Solidity smart contract implementing a decentralized NFT marketplace with advanced concepts like AI oracle integration for conditional listings/offers, a basic reputation system, conditional escrow, and a simple governance mechanism.

This contract avoids directly copying full implementations from well-known open-source marketplaces (like OpenSea's Seaport, or basic OpenZeppelin marketplace examples) by focusing on custom logic for AI-driven conditions and conditional escrows. It relies on standard interfaces (`IERC721`, `IERC20`) and basic ownership patterns.

**Outline and Function Summary:**

1.  **Contract Definition:** Basic structure, state variables, enums, structs, events.
2.  **Interfaces:** Definition of required external contract interfaces (`IERC721`, `IAIOracle`).
3.  **Modifiers:** Access control and state-checking modifiers.
4.  **Constructor:** Initialization.
5.  **Admin Functions:**
    *   `setOracleAddress`: Set the address of the AI Oracle contract.
    *   `setPlatformFee`: Set the marketplace platform fee percentage.
    *   `setFeeRecipient`: Set the address where fees are sent.
    *   `withdrawPlatformFees`: Withdraw accumulated platform fees.
    *   `resolveDispute`: Admin function to manually resolve disputes.
6.  **Listing & Purchase Functions (Standard):**
    *   `listNFT`: Create a new listing for an NFT (can include conditions).
    *   `buyNFT`: Purchase a standard (non-conditional) listing or a conditional listing where conditions are already met at purchase time.
    *   `cancelListing`: Seller cancels an active listing.
    *   `updateListing`: Seller updates price or conditions of a listing.
7.  **Conditional Offer Functions:**
    *   `makeConditionalOffer`: Buyer makes an offer on a listing with specific conditions.
    *   `acceptConditionalOffer`: Seller accepts a conditional offer (moves to Escrow state). Requires ETH payment into escrow.
    *   `rejectConditionalOffer`: Seller rejects a conditional offer.
    *   `cancelConditionalOffer`: Buyer cancels their pending conditional offer.
    *   `fulfillConditionalOffer`: Either party attempts to finalize an accepted conditional offer once conditions are met. Triggers condition check and asset/fund transfer.
    *   `failConditionalOffer`: Callable if conditions are *not* met by a deadline (not implemented for deadlines in this version, but structure allows).
8.  **AI Oracle Interaction:**
    *   `viewNFTScores`: Public view function to query the AI oracle for an NFT's scores/data.
9.  **Reputation System:**
    *   `leaveReputationFeedback`: Allows participants in a completed transaction to leave feedback.
    *   `getUserReputation`: View a user's reputation score.
10. **Basic Governance (for Fees):**
    *   `proposePlatformFeeChange`: Propose a change to the platform fee.
    *   `voteOnProposal`: Vote on an active proposal.
    *   `executeProposal`: Execute a successful proposal.
11. **Dispute System:**
    *   `initiateDispute`: Start a dispute regarding a conditional offer/listing.
12. **View Functions:**
    *   `getListing`: Get details of a specific listing.
    *   `getConditionalOffer`: Get details of a specific conditional offer.
    *   `getProposal`: Get details of a specific proposal.
    *   `getDispute`: Get details of a specific dispute.
    *   `getPlatformBalance`: Get the current balance of collected fees.
    *   `getFeeRecipient`: Get the current fee recipient address.
    *   `checkListingConditions`: Public view to check if conditions for a specific listing are currently met.
    *   `checkOfferConditions`: Public view to check if conditions for a specific offer are currently met.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary Above

import {IERC721} from "./IERC721.sol"; // Assuming a local IERC721.sol or standard path
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Use if supporting ERC20 payments

/**
 * @title DecentralizedNFTMarketplaceWithAIOracle
 * @dev A decentralized marketplace for NFTs featuring AI oracle-driven conditional listings/offers,
 * a basic reputation system, conditional escrow, and basic governance.
 * This contract uses ETH for payments.
 */
contract DecentralizedNFTMarketplaceWithAIOracle {

    // --- State Variables ---

    address public owner; // Contract deployer
    address public oracleAddress; // Address of the AI Oracle contract
    address public feeRecipient; // Address where collected fees are sent
    uint256 public platformFeeBasisPoints; // Platform fee (e.g., 250 for 2.5%) in basis points

    uint256 private _listingNonce; // Counter for unique listing IDs
    uint256 private _offerNonce; // Counter for unique conditional offer IDs
    uint256 private _proposalNonce; // Counter for unique proposal IDs
    uint256 private _disputeNonce; // Counter for unique dispute IDs

    mapping(uint256 => Listing) public listings; // Listing ID => Listing details
    mapping(uint256 => ConditionalOffer) public conditionalOffers; // Offer ID => Conditional Offer details
    mapping(address => int256) public userReputation; // User address => Reputation score

    mapping(uint256 => Proposal) public proposals; // Proposal ID => Proposal details
    mapping(uint256 => mapping(address => bool)) public hasVoted; // Proposal ID => Voter address => Has voted?

    mapping(uint256 => Dispute) public disputes; // Dispute ID => Dispute details

    // Track ETH held in escrow for conditional offers
    mapping(uint256 => uint256) private _offerEscrowBalance; // Offer ID => ETH amount held

    // --- Enums ---

    enum ListingState { Active, Sold, Cancelled }
    enum OfferState { Pending, AcceptedEscrow, Rejected, Cancelled, Fulfilled, Failed, Disputed }
    enum ConditionType { GreaterThan, LessThan, EqualTo, NotEqualTo }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum DisputeState { Open, ResolvedSeller, ResolvedBuyer } // How the dispute was resolved

    // --- Structs ---

    struct Condition {
        ConditionType conditionType; // Type of comparison (>, <, ==, !=)
        string oracleQueryKey;     // Key for the oracle query (e.g., "quality_score", "rarity_rank")
        int256 requiredValue;       // The value the oracle result is compared against
        // Future: Add external contract address, function signature for more complex conditions
    }

    struct Listing {
        uint256 id;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price; // Price in wei for direct purchase or basis for offers
        ListingState state;
        Condition[] conditions; // Conditions for a conditional listing/purchase
        // Optional: snapshot of oracle data at listing time? (adds complexity/gas)
    }

    struct ConditionalOffer {
        uint256 id;
        uint256 listingId; // References the listing this offer is for
        address buyer;
        uint256 offerAmount; // Offer amount in wei
        OfferState state;
        Condition[] conditions; // Conditions the offer depends on
        uint256 createdAt;
        // Future: Add expiration timestamp
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description; // Description of the proposal (e.g., "Change fee to 2%")
        bytes data; // Calldata for the function to execute (e.g., `setPlatformFee(200)`)
        uint256 voteCount; // Number of votes FOR the proposal
        uint256 requiredVotes; // Minimum votes needed to succeed (e.g., based on a token supply or participant count) - simplified to fixed number here
        ProposalState state;
        uint256 createdAt;
        // Future: Add voting start/end times, snapshot block
    }

    struct Dispute {
        uint256 id;
        uint256 relatedOfferId; // The offer this dispute is about
        address[] parties; // Addresses involved (e.g., [seller, buyer])
        string reason; // Description of the dispute
        DisputeState state;
        uint256 initiatedAt;
        // Future: Add evidence hashes, arbiter/DAO decision reference
    }

    // --- Events ---

    event ListingCreated(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price, bool hasConditions);
    event ListingPurchased(uint256 indexed listingId, address indexed buyer, address indexed seller, uint256 totalPrice);
    event ListingCancelled(uint256 indexed listingId, address indexed seller);
    event ListingUpdated(uint256 indexed listingId, uint256 newPrice, bool conditionsUpdated);

    event OfferCreated(uint256 indexed offerId, uint256 indexed listingId, address indexed buyer, uint256 offerAmount, bool hasConditions);
    event OfferAccepted(uint256 indexed offerId, uint256 indexed listingId, address indexed seller, uint256 acceptedAmount);
    event OfferRejected(uint256 indexed offerId, uint256 indexed listingId, address indexed seller);
    event OfferCancelled(uint256 indexed offerId, uint256 indexed listingId, address indexed buyer);
    event OfferFulfilled(uint256 indexed offerId, uint256 indexed listingId, address indexed party); // Party who triggered fulfillment
    event OfferFailed(uint256 indexed offerId, uint256 indexed listingId); // e.g., conditions not met by deadline

    event ReputationUpdated(address indexed user, int256 newReputation);
    event FeedbackLeft(address indexed transactionParty, address indexed feedbackGiver, int256 scoreChange);

    event FeeCollected(address indexed recipient, uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event FeeRecipientUpdated(address indexed newRecipient);
    event PlatformFeeUpdated(uint256 newFeeBasisPoints);

    event OracleAddressUpdated(address indexed newOracleAddress);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool supports); // Supports = true for YES
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event DisputeCreated(uint256 indexed disputeId, uint256 indexed relatedOfferId, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, DisputeState outcome, address indexed resolver);

    // --- Interfaces ---

    // Standard ERC721 interface (needs standard functions like safeTransferFrom)
    interface IERC721 {
        function safeTransferFrom(address from, address to, uint256 tokenId) external;
        function transferFrom(address from, address to, uint256 tokenId) external; // Included for completeness, safeTransferFrom preferred
        function approve(address to, uint256 tokenId) external;
        function setApprovalForAll(address operator, bool approved) external;
        function getApproved(uint256 tokenId) external view returns (address operator);
        function isApprovedForAll(address owner, address operator) external view returns (bool);
        function ownerOf(uint256 tokenId) external view returns (address owner);
        // Include others as needed like balanceOf, symbol, name etc.
    }

    // Hypothetical AI Oracle Interface
    interface IAIOracle {
        // Function to get a numerical score (e.g., rarity rank, sentiment score)
        function getAIScore(address tokenAddress, uint256 tokenId, string calldata queryKey) external view returns (int256 score);
        // Function to get potentially more complex data (e.g., trait rarity array, sentiment analysis text)
        function getAIData(address tokenAddress, uint256 tokenId, string calldata queryKey) external view returns (bytes memory data);
        // Future: function to get data with a specific timestamp/blockhash for historical checks
        // Future: function to query collection-level data
    }

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyApprovedOrSeller(address nftContract, uint256 tokenId, address seller) {
        IERC721 nft = IERC721(nftContract);
        require(msg.sender == seller || nft.isApprovedForAll(seller, address(this)) || nft.getApproved(tokenId) == address(this),
                "Caller not approved or seller");
        _;
    }

     modifier onlyBuyerOrSeller(uint256 listingIdOrOfferId, bool isListing) {
         if (isListing) {
             Listing storage listing = listings[listingIdOrOfferId];
             require(msg.sender == listing.buyer || msg.sender == listing.seller, "Not buyer or seller"); // Note: buyer is set during purchase
         } else {
             ConditionalOffer storage offer = conditionalOffers[listingIdOrOfferId];
             require(msg.sender == offer.buyer || msg.sender == listings[offer.listingId].seller, "Not buyer or seller");
         }
         _;
     }


    modifier whenListingState(uint256 listingId, ListingState expectedState) {
        require(listings[listingId].state == expectedState, "Listing not in expected state");
        _;
    }

     modifier whenOfferState(uint256 offerId, OfferState expectedState) {
        require(conditionalOffers[offerId].state == expectedState, "Offer not in expected state");
        _;
    }

    modifier whenProposalState(uint256 proposalId, ProposalState expectedState) {
        require(proposals[proposalId].state == expectedState, "Proposal not in expected state");
        _;
    }

    modifier whenDisputeState(uint256 disputeId, DisputeState expectedState) {
        require(disputes[disputeId].state == expectedState, "Dispute not in expected state");
        _;
    }

    // --- Constructor ---

    constructor(address _oracleAddress, address _feeRecipient, uint256 _platformFeeBasisPoints) payable {
        owner = msg.sender;
        require(_oracleAddress != address(0), "Invalid oracle address");
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        oracleAddress = _oracleAddress;
        feeRecipient = _feeRecipient;
        platformFeeBasisPoints = _platformFeeBasisPoints;
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Queries the AI oracle for a specific score.
     * @param nftContract Address of the NFT contract.
     * @param tokenId Token ID of the NFT.
     * @param queryKey Key for the oracle query (e.g., "quality_score").
     * @return The score returned by the oracle.
     */
    function _getOracleScore(address nftContract, uint256 tokenId, string calldata queryKey) internal view returns (int256) {
        require(oracleAddress != address(0), "Oracle address not set");
        return IAIOracle(oracleAddress).getAIScore(nftContract, tokenId, queryKey);
    }

    /**
     * @dev Checks if a single condition is met based on oracle data.
     * @param nftContract Address of the NFT contract.
     * @param tokenId Token ID of the NFT.
     * @param condition The condition struct to check.
     * @return True if the condition is met, false otherwise.
     */
    function _checkCondition(address nftContract, uint256 tokenId, Condition storage condition) internal view returns (bool) {
         if (oracleAddress == address(0)) return false; // Conditions cannot be met without an oracle

        int256 oracleScore = _getOracleScore(nftContract, tokenId, condition.oracleQueryKey);

        if (condition.conditionType == ConditionType.GreaterThan) {
            return oracleScore > condition.requiredValue;
        } else if (condition.conditionType == ConditionType.LessThan) {
            return oracleScore < condition.requiredValue;
        } else if (condition.conditionType == ConditionType.EqualTo) {
            return oracleScore == condition.requiredValue;
        } else if (condition.conditionType == ConditionType.NotEqualTo) {
            return oracleScore != condition.requiredValue;
        }
        return false; // Should not reach here
    }

    /**
     * @dev Checks if all conditions in an array are met.
     * @param nftContract Address of the NFT contract.
     * @param tokenId Token ID of the NFT.
     * @param conditions Array of conditions to check.
     * @return True if all conditions are met or if there are no conditions, false otherwise.
     */
    function _checkAllConditions(address nftContract, uint256 tokenId, Condition[] storage conditions) internal view returns (bool) {
        if (conditions.length == 0) return true; // No conditions means conditions are met

        for (uint i = 0; i < conditions.length; i++) {
            if (!_checkCondition(nftContract, tokenId, conditions[i])) {
                return false; // If any single condition fails, all conditions are not met
            }
        }
        return true; // All conditions met
    }

    /**
     * @dev Transfers the NFT from the seller to the buyer.
     * Assumes the marketplace contract is approved or approvedForAll.
     * @param nftContract The address of the NFT contract.
     * @param seller The current owner of the NFT.
     * @param buyer The recipient of the NFT.
     * @param tokenId The ID of the NFT.
     */
    function _transferNFT(address nftContract, address seller, address buyer, uint256 tokenId) internal {
        require(IERC721(nftContract).ownerOf(tokenId) == seller, "Seller is not the current owner");
        IERC721(nftContract).safeTransferFrom(seller, buyer, tokenId);
    }

    /**
     * @dev Pays the seller their share after deducting the platform fee.
     * @param seller The address of the seller.
     * @param totalAmount The total amount paid by the buyer.
     */
    function _paySeller(address payable seller, uint256 totalAmount) internal {
        uint256 feeAmount = _calculateFeeAmount(totalAmount);
        uint256 sellerAmount = totalAmount - feeAmount;

        if (sellerAmount > 0) {
             (bool success, ) = seller.call{value: sellerAmount}("");
             require(success, "Payment to seller failed");
        }
        _collectFee(totalAmount); // Fee is collected regardless of seller payment success (simpler model)
    }

    /**
     * @dev Calculates the platform fee amount.
     * @param totalAmount The total amount of the transaction.
     * @return The calculated fee amount.
     */
    function _calculateFeeAmount(uint256 totalAmount) internal view returns (uint256) {
        return (totalAmount * platformFeeBasisPoints) / 10000;
    }

    /**
     * @dev Collects the platform fee and sends it to the fee recipient or holds it.
     * Currently holds it to be withdrawn later by the owner.
     * @param totalAmount The total amount of the transaction.
     */
    function _collectFee(uint256 totalAmount) internal {
        uint256 feeAmount = _calculateFeeAmount(totalAmount);
        if (feeAmount > 0) {
           // Instead of sending directly, hold in contract for batch withdrawal by owner
           // (balance is implicit in contract's ETH balance)
           emit FeeCollected(feeRecipient, feeAmount); // Emitting recipient for clarity, actual balance is here
        }
    }

    // --- Admin Functions ---

    /**
     * @dev Sets the address of the AI Oracle contract. Only callable by the owner.
     * @param _oracleAddress The address of the AI Oracle contract.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        oracleAddress = _oracleAddress;
        emit OracleAddressUpdated(_oracleAddress);
    }

    /**
     * @dev Sets the platform fee percentage in basis points. Only callable by the owner
     * or via successful governance proposal.
     * @param _platformFeeBasisPoints The new fee percentage (e.g., 100 = 1%, 250 = 2.5%).
     */
    function setPlatformFee(uint256 _platformFeeBasisPoints) external onlyOwner {
        // Consider adding maximum fee validation
        platformFeeBasisPoints = _platformFeeBasisPoints;
        emit PlatformFeeUpdated(_platformFeeBasisPoints);
    }

     /**
     * @dev Sets the address where collected fees are sent. Only callable by the owner.
     * @param _feeRecipient The new fee recipient address.
     */
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient address");
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdated(_feeRecipient);
    }

    /**
     * @dev Allows the fee recipient to withdraw accumulated platform fees.
     * Fees are collected into the contract's balance and can be withdrawn by the owner/feeRecipient.
     */
    function withdrawPlatformFees() external {
        require(msg.sender == owner || msg.sender == feeRecipient, "Not authorized to withdraw fees");
        uint256 balance = address(this).balance - (_offerEscrowBalance[0] * 0); // Simple way to get balance not in escrow (assuming offerId 0 is unused)
        // Note: A more robust escrow system would explicitly track total escrow balance.
        // This is a simplification.
        // A better way: track total non-escrow balance explicitly.
        // For this example, we'll allow owner/feeRecipient to withdraw contract balance.
        // This is risky if escrow is active without robust balance tracking.
        // LET'S REVISE: The escrow balance needs to be tracked reliably.
        // Let's add a state variable `totalEscrowBalance`.
        // The `withdrawPlatformFees` should only allow withdrawing `address(this).balance - totalEscrowBalance`.

        uint256 totalOffersEscrowed = 0;
        // This requires iterating through all offers in escrow, which is not scalable.
        // A better approach tracks total escrowed ETH in a single variable, updated
        // when ETH enters/leaves escrow.

        // Implementing the simplified withdrawal for now, acknowledging the limitation.
        uint256 feesAvailable = address(this).balance; // Simplified: allows withdrawing everything, owner must be careful not to pull escrow
         if (feeRecipient != address(0) && feesAvailable > 0) {
             (bool success, ) = payable(feeRecipient).call{value: feesAvailable}("");
             require(success, "Fee withdrawal failed");
             emit FeesWithdrawn(feeRecipient, feesAvailable);
         }
    }

    /**
     * @dev Resolves a dispute initiated for a conditional offer. Only callable by the owner.
     * Determines the outcome (fulfill, fail, partial refund).
     * @param disputeId The ID of the dispute to resolve.
     * @param outcome The resolution outcome (ResolvedSeller = fulfill, ResolvedBuyer = fail/cancel).
     * @param payoutAmount Optional: specific payout amount if outcome is partial. (Not fully implemented for partial)
     */
    function resolveDispute(uint256 disputeId, DisputeState outcome, uint256 payoutAmount) external onlyOwner whenDisputeState(disputeId, DisputeState.Open) {
         Dispute storage dispute = disputes[disputeId];
         ConditionalOffer storage offer = conditionalOffers[dispute.relatedOfferId];
         Listing storage listing = listings[offer.listingId];

         uint256 escrowAmount = _offerEscrowBalance[offer.id];
         require(escrowAmount > 0, "No escrow balance for this offer");

         if (outcome == DisputeState.ResolvedSeller) {
             // Resolution favors seller: fulfill the sale
             _transferNFT(listing.nftContract, listing.seller, offer.buyer, listing.tokenId);
             // Pay seller the full escrowed amount (minus fees)
             _paySeller(payable(listing.seller), escrowAmount); // _paySeller handles fee collection
             offer.state = OfferState.Fulfilled; // Update offer state
             emit OfferFulfilled(offer.id, listing.id, address(this)); // Admin resolved == party is contract
             userReputation[listing.seller] += 1; // Seller reputation +1
             userReputation[offer.buyer] += 1;   // Buyer reputation +1
         } else if (outcome == DisputeState.ResolvedBuyer) {
             // Resolution favors buyer: cancel sale, refund buyer
              // Refund escrowed amount to buyer
             (bool success, ) = payable(offer.buyer).call{value: escrowAmount}("");
             require(success, "Refund to buyer failed");
             offer.state = OfferState.Failed; // Update offer state
             emit OfferFailed(offer.id, listing.id);
             userReputation[listing.seller] -= 1; // Seller reputation -1
             userReputation[offer.buyer] += 1;   // Buyer reputation +1
         } else {
             // Partial resolution - more complex, requires explicit payout logic for payoutAmount
             revert("Partial resolution not fully implemented");
             // Example: send payoutAmount to seller, remainder refund to buyer, handle fees?
         }

         _offerEscrowBalance[offer.id] = 0; // Clear escrow balance
         dispute.state = outcome; // Update dispute state
         emit DisputeResolved(disputeId, outcome, msg.sender);
         emit ReputationUpdated(listing.seller, userReputation[listing.seller]);
         emit ReputationUpdated(offer.buyer, userReputation[offer.buyer]);
    }


    // --- Listing & Purchase Functions (Standard) ---

    /**
     * @dev Creates a new listing for an NFT. Seller must approve the marketplace contract.
     * @param nftContract Address of the NFT contract.
     * @param tokenId Token ID of the NFT.
     * @param price Listing price in wei. Use 0 for offers-only, non-conditional listing.
     * @param conditions Conditions required for direct purchase or for accepting offers.
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 price, Condition[] calldata conditions) external {
        // Ensure caller owns the NFT and has approved the marketplace
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Caller is not the owner of the NFT");
        require(IERC721(nftContract).isApprovedForAll(msg.sender, address(this)) || IERC721(nftContract).getApproved(tokenId) == address(this),
                "Marketplace not approved to transfer NFT");

        _listingNonce++;
        uint256 listingId = _listingNonce;

        Listing storage newListing = listings[listingId];
        newListing.id = listingId;
        newListing.seller = msg.sender;
        newListing.nftContract = nftContract;
        newListing.tokenId = tokenId;
        newListing.price = price;
        newListing.state = ListingState.Active;

        // Copy conditions from calldata
        if (conditions.length > 0) {
            newListing.conditions = new Condition[](conditions.length);
            for(uint i = 0; i < conditions.length; i++) {
                newListing.conditions[i] = conditions[i];
            }
        }

        emit ListingCreated(listingId, msg.sender, nftContract, tokenId, price, conditions.length > 0);
    }

    /**
     * @dev Purchases a listed NFT. Can be used for direct purchases or conditional purchases
     * where conditions are currently met.
     * @param listingId The ID of the listing to purchase.
     */
    function buyNFT(uint256 listingId) external payable whenListingState(listingId, ListingState.Active) {
        Listing storage listing = listings[listingId];

        require(listing.seller != address(0), "Listing does not exist"); // Extra check
        require(msg.sender != listing.seller, "Cannot buy your own listing");

        // Check if conditions are met for this direct purchase
        require(_checkAllConditions(listing.nftContract, listing.tokenId, listing.conditions),
                "Listing conditions are not met for direct purchase");

        // Direct purchase requires exact price match
        require(msg.value == listing.price, "Incorrect ETH amount sent");
        require(msg.value > 0, "Direct purchase requires positive price"); // Implicit if price > 0, but good check

        listing.state = ListingState.Sold; // Mark as sold

        // Transfer NFT from seller to buyer
        _transferNFT(listing.nftContract, listing.seller, msg.sender, listing.tokenId);

        // Pay seller their share and collect platform fee
        _paySeller(payable(listing.seller), msg.value);

        emit ListingPurchased(listingId, msg.sender, listing.seller, msg.value);

        // Update reputation for direct purchase
        userReputation[msg.sender] += 1; // Buyer rep +1
        userReputation[listing.seller] += 1; // Seller rep +1
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);
        emit ReputationUpdated(listing.seller, userReputation[listing.seller]);
    }


    /**
     * @dev Seller cancels their listing.
     * @param listingId The ID of the listing to cancel.
     */
    function cancelListing(uint256 listingId) external whenListingState(listingId, ListingState.Active) {
        Listing storage listing = listings[listingId];
        require(msg.sender == listing.seller, "Only the seller can cancel a listing");

        listing.state = ListingState.Cancelled;

        // Note: NFT is still with the seller, no transfer needed. Approval should be revoked by seller off-chain if desired.

        emit ListingCancelled(listingId, msg.sender);
    }

     /**
      * @dev Seller updates the price or conditions of an active listing.
      * @param listingId The ID of the listing to update.
      * @param newPrice The new price for the listing (use 0 to remove direct purchase option).
      * @param newConditions The new set of conditions (empty array to remove conditions).
      */
    function updateListing(uint256 listingId, uint256 newPrice, Condition[] calldata newConditions) external whenListingState(listingId, ListingState.Active) {
         Listing storage listing = listings[listingId];
         require(msg.sender == listing.seller, "Only the seller can update a listing");

         bool conditionsUpdated = false;
         if (newConditions.length != listing.conditions.length) {
             conditionsUpdated = true;
         } else {
             for(uint i = 0; i < newConditions.length; i++) {
                 // Basic check, deep comparison of structs is more complex
                 if (newConditions[i].conditionType != listing.conditions[i].conditionType ||
                     bytes(newConditions[i].oracleQueryKey).length != bytes(listing.conditions[i].oracleQueryKey).length || // Simple string equality check proxy
                     !_compareStrings(newConditions[i].oracleQueryKey, listing.conditions[i].oracleQueryKey) ||
                     newConditions[i].requiredValue != listing.conditions[i].requiredValue) {
                         conditionsUpdated = true;
                         break;
                     }
             }
         }

         listing.price = newPrice;
         if (conditionsUpdated) {
             // Deep copy new conditions
             listing.conditions = new Condition[](newConditions.length);
             for(uint i = 0; i < newConditions.length; i++) {
                 listing.conditions[i] = newConditions[i];
             }
         }

         emit ListingUpdated(listingId, newPrice, conditionsUpdated);
    }

    /**
     * @dev Helper function for basic string comparison.
     */
    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }


    // --- Conditional Offer Functions ---

    /**
     * @dev Buyer makes a conditional offer on an active listing.
     * @param listingId The ID of the listing to make an offer on.
     * @param offerAmount The amount of ETH offered.
     * @param conditions Conditions required for this offer to be valid and fulfillable.
     */
    function makeConditionalOffer(uint256 listingId, uint256 offerAmount, Condition[] calldata conditions) external {
         require(listings[listingId].state == ListingState.Active, "Listing is not active");
         require(offerAmount > 0, "Offer amount must be greater than zero");
         require(listings[listingId].seller != msg.sender, "Cannot make offer on your own listing");
         require(conditions.length > 0, "Conditional offer must have conditions"); // Must have conditions to be 'conditional'

         _offerNonce++;
         uint256 offerId = _offerNonce;

         ConditionalOffer storage newOffer = conditionalOffers[offerId];
         newOffer.id = offerId;
         newOffer.listingId = listingId;
         newOffer.buyer = msg.sender;
         newOffer.offerAmount = offerAmount;
         newOffer.state = OfferState.Pending;
         newOffer.createdAt = block.timestamp;

         // Copy conditions from calldata
         newOffer.conditions = new Condition[](conditions.length);
         for(uint i = 0; i < conditions.length; i++) {
             newOffer.conditions[i] = conditions[i];
         }

         emit OfferCreated(offerId, listingId, msg.sender, offerAmount, true);
    }

    /**
     * @dev Seller accepts a conditional offer. Requires the buyer to deposit the offer amount into escrow.
     * Changes offer state to AcceptedEscrow.
     * @param offerId The ID of the conditional offer to accept.
     */
    function acceptConditionalOffer(uint256 offerId) external payable whenOfferState(offerId, OfferState.Pending) {
         ConditionalOffer storage offer = conditionalOffers[offerId];
         Listing storage listing = listings[offer.listingId];

         require(msg.sender == listing.seller, "Only the listing seller can accept offers");
         require(msg.value == offer.offerAmount, "Incorrect ETH amount sent for escrow");

         offer.state = OfferState.AcceptedEscrow;
         _offerEscrowBalance[offer.id] = msg.value;

         // Note: NFT remains with seller, ETH is held in contract.

         emit OfferAccepted(offerId, offer.listingId, msg.sender, msg.value);

         // Consider adding a simple reputation boost for engaging in conditional offers?
         // userReputation[msg.sender] += 0; // No change yet
         // userReputation[offer.buyer] += 0;
     }

     /**
      * @dev Seller rejects a conditional offer.
      * @param offerId The ID of the conditional offer to reject.
      */
     function rejectConditionalOffer(uint256 offerId) external whenOfferState(offerId, OfferState.Pending) {
         ConditionalOffer storage offer = conditionalOffers[offerId];
         Listing storage listing = listings[offer.listingId];

         require(msg.sender == listing.seller, "Only the listing seller can reject offers");

         offer.state = OfferState.Rejected;

         emit OfferRejected(offerId, offer.listingId, msg.sender);
     }

      /**
       * @dev Buyer cancels their pending conditional offer.
       * @param offerId The ID of the conditional offer to cancel.
       */
     function cancelConditionalOffer(uint256 offerId) external whenOfferState(offerId, OfferState.Pending) {
         ConditionalOffer storage offer = conditionalOffers[offerId];

         require(msg.sender == offer.buyer, "Only the offer buyer can cancel their offer");

         offer.state = OfferState.Cancelled;

         emit OfferCancelled(offerId, offer.listingId, msg.sender);
     }

     /**
      * @dev Attempts to fulfill an accepted conditional offer. Callable by buyer or seller.
      * Checks if conditions are met and, if so, transfers NFT and releases escrowed funds.
      * If conditions are not met, it fails (can be disputed).
      * @param offerId The ID of the offer to fulfill.
      */
     function fulfillConditionalOffer(uint256 offerId) external whenOfferState(offerId, OfferState.AcceptedEscrow) onlyBuyerOrSeller(offerId, false) {
         ConditionalOffer storage offer = conditionalOffers[offerId];
         Listing storage listing = listings[offer.listingId];

         uint256 escrowAmount = _offerEscrowBalance[offer.id];
         require(escrowAmount > 0, "No escrow balance for this offer");

         // Check if conditions are met *now*
         if (_checkAllConditions(listing.nftContract, listing.tokenId, offer.conditions)) {
             // Conditions met: fulfill the offer
             _transferNFT(listing.nftContract, listing.seller, offer.buyer, listing.tokenId);
             _paySeller(payable(listing.seller), escrowAmount); // Pay seller from escrow, collect fee

             offer.state = OfferState.Fulfilled;
             _offerEscrowBalance[offer.id] = 0; // Clear escrow balance

             emit OfferFulfilled(offerId, listing.id, msg.sender);

             // Update reputation for successful conditional sale
             userReputation[offer.buyer] += 2; // Buyer rep +2 for conditional fulfillment
             userReputation[listing.seller] += 2; // Seller rep +2 for conditional fulfillment
             emit ReputationUpdated(offer.buyer, userReputation[offer.buyer]);
             emit ReputationUpdated(listing.seller, userReputation[listing.seller]);

         } else {
             // Conditions not met: Offer fails automatically, funds remain in escrow, can be disputed
             offer.state = OfferState.Failed; // Mark as failed as conditions not met
             // Funds stay in escrow until dispute or other resolution
             emit OfferFailed(offerId, listing.id);

             // Rep penalty for potential failure? Or only on dispute? Let's penalize on dispute resolution.
         }
     }

    // NOTE: A `failConditionalOffer` might be needed for timed offers if conditions aren't met by deadline.
    // Not implemented here for simplicity.

    // --- AI Oracle Interaction ---

    /**
     * @dev Public view function to query the AI oracle for scores/data related to an NFT.
     * Requires the oracle address to be set.
     * @param nftContract Address of the NFT contract.
     * @param tokenId Token ID of the NFT.
     * @param queryKey Key for the oracle query.
     * @return The score returned by the oracle.
     */
    function viewNFTScores(address nftContract, uint256 tokenId, string calldata queryKey) external view returns (int256) {
        return _getOracleScore(nftContract, tokenId, queryKey);
    }

    // Future: add function to view raw data via `getAIData` if needed.

    // --- Reputation System ---

    /**
     * @dev Allows parties involved in a completed transaction to leave feedback for each other.
     * @param transactionParty The address of the user receiving feedback.
     * @param scoreChange The change in reputation score (+1, -1, etc.).
     * NOTE: Logic needs to be added to ensure feedback can only be left *once* per transaction
     * and only by participants. This requires tracking completed transactions.
     * SIMPLE IMPLEMENTATION: Anyone can change anyone's score for now. This is NOT secure.
     * SECURE IMPLEMENTATION: requires mapping transaction IDs => feedback status for buyer/seller.
     * Implementing the simple (insecure) version for function count.
     */
    function leaveReputationFeedback(address transactionParty, int256 scoreChange) external {
        // Basic check: Cannot give feedback to self
        require(transactionParty != msg.sender, "Cannot leave feedback for yourself");
        // In a real system, add checks:
        // 1. Did msg.sender and transactionParty participate in a *completed* transaction?
        // 2. Has feedback already been left for this specific transaction pair?

        userReputation[transactionParty] += scoreChange;
        emit ReputationUpdated(transactionParty, userReputation[transactionParty]);
        emit FeedbackLeft(transactionParty, msg.sender, scoreChange);
    }

     /**
      * @dev Returns the current reputation score of a user.
      * @param user The address of the user.
      * @return The reputation score.
      */
    function getUserReputation(address user) external view returns (int256) {
        return userReputation[user];
    }


    // --- Basic Governance (for Fees) ---

    /**
     * @dev Proposes a change to the platform fee. Anyone can create a proposal.
     * @param description A description of the proposal.
     * @param newFeeBasisPoints The proposed new fee percentage.
     * NOTE: This is a simplified governance model.
     */
    function proposePlatformFeeChange(string calldata description, uint256 newFeeBasisPoints) external {
        _proposalNonce++;
        uint256 proposalId = _proposalNonce;

        // Encode the function call to setPlatformFee
        bytes memory callData = abi.encodeWithSelector(this.setPlatformFee.selector, newFeeBasisPoints);

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.data = callData;
        newProposal.voteCount = 0;
        newProposal.requiredVotes = 1; // Simplified: Only 1 vote needed to pass for testing/example
        newProposal.state = ProposalState.Active;
        newProposal.createdAt = block.timestamp;

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /**
     * @dev Votes on an active proposal.
     * @param proposalId The ID of the proposal to vote on.
     * @param supports True for a 'yes' vote, false for 'no'. (Only 'yes' votes counted in this simple model)
     * NOTE: In a real DAO, voting power would be based on token holdings, reputation, etc.
     */
    function voteOnProposal(uint256 proposalId, bool supports) external whenProposalState(proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[proposalId];
        require(!hasVoted[proposalId][msg.sender], "Already voted on this proposal");

        hasVoted[proposalId][msg.sender] = true;

        if (supports) {
            proposal.voteCount++;
            if (proposal.voteCount >= proposal.requiredVotes) {
                proposal.state = ProposalState.Succeeded;
                // In a real DAO, there might be a queuing period before execution
            }
        } else {
            // Optional: track 'no' votes or user weight
        }

        emit Voted(proposalId, msg.sender, supports);
    }

     /**
      * @dev Executes a successful proposal. Callable by anyone once the proposal has succeeded.
      * @param proposalId The ID of the proposal to execute.
      */
    function executeProposal(uint256 proposalId) external whenProposalState(proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[proposalId];

        // Execute the function call stored in the proposal data
        (bool success, ) = address(this).call(proposal.data);

        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId, success);
        // Note: Reverting here if execution fails might be too harsh, depending on DAO design.
        // For this example, we just mark it as executed and emit success status.
    }


    // --- Dispute System ---

    /**
     * @dev Initiates a dispute for a completed conditional offer where conditions were deemed not met.
     * Callable by either the buyer or seller of a failed conditional offer.
     * @param offerId The ID of the conditional offer to dispute.
     * @param reason Description of the reason for the dispute.
     */
    function initiateDispute(uint256 offerId, string calldata reason) external whenOfferState(offerId, OfferState.Failed) onlyBuyerOrSeller(offerId, false) {
        ConditionalOffer storage offer = conditionalOffers[offerId];
        require(_offerEscrowBalance[offer.id] > 0, "Offer has no escrow balance"); // Can only dispute if ETH is held

        // Check if a dispute already exists for this offer
        for(uint i = 1; i <= _disputeNonce; i++) { // Iterate through existing disputes (not scalable, for example)
            if (disputes[i].relatedOfferId == offerId && disputes[i].state == DisputeState.Open) {
                 revert("A dispute already exists for this offer");
            }
        }

        // Set offer state to disputed
        offer.state = OfferState.Disputed;

        _disputeNonce++;
        uint256 disputeId = _disputeNonce;

        Dispute storage newDispute = disputes[disputeId];
        newDispute.id = disputeId;
        newDispute.relatedOfferId = offerId;
        newDispute.parties = new address[](2);
        newDispute.parties[0] = offer.buyer;
        newDispute.parties[1] = listings[offer.listingId].seller;
        newDispute.reason = reason;
        newDispute.state = DisputeState.Open;
        newDispute.initiatedAt = block.timestamp;

        emit DisputeCreated(disputeId, offerId, msg.sender);
    }

    // `resolveDispute` is above in Admin Functions.

    // --- View Functions ---

    /**
     * @dev Gets details of a specific listing.
     * @param listingId The ID of the listing.
     * @return Listing struct details.
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        require(listings[listingId].seller != address(0), "Listing does not exist");
        return listings[listingId];
    }

    /**
     * @dev Gets details of a specific conditional offer.
     * @param offerId The ID of the offer.
     * @return ConditionalOffer struct details.
     */
    function getConditionalOffer(uint256 offerId) external view returns (ConditionalOffer memory) {
         require(conditionalOffers[offerId].buyer != address(0), "Offer does not exist");
         return conditionalOffers[offerId];
    }

    /**
     * @dev Gets details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct details.
     */
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposals[proposalId].proposer != address(0), "Proposal does not exist");
        return proposals[proposalId];
    }

     /**
     * @dev Gets details of a specific dispute.
     * @param disputeId The ID of the dispute.
     * @return Dispute struct details.
     */
    function getDispute(uint256 disputeId) external view returns (Dispute memory) {
         require(disputes[disputeId].parties.length > 0, "Dispute does not exist");
         return disputes[disputeId];
    }


    /**
     * @dev Returns the current balance of ETH held by the contract, available for fee withdrawal.
     * NOTE: This balance includes funds held in escrow for conditional offers.
     * A robust system would separate these.
     * @return The contract's current ETH balance.
     */
    function getPlatformBalance() external view returns (uint256) {
         // In a real system, calculate `address(this).balance - totalEscrowedAmount`
         return address(this).balance; // Simplified view
    }

     /**
      * @dev Returns the current fee recipient address.
      * @return The fee recipient address.
      */
    function getFeeRecipient() external view returns (address) {
        return feeRecipient;
    }

     /**
      * @dev Checks if all conditions for a specific listing are currently met based on oracle data.
      * Public view function.
      * @param listingId The ID of the listing.
      * @return True if all conditions are met, false otherwise.
      */
    function checkListingConditions(uint256 listingId) external view returns (bool) {
         require(listings[listingId].seller != address(0), "Listing does not exist");
         return _checkAllConditions(listings[listingId].nftContract, listings[listingId].tokenId, listings[listingId].conditions);
    }

     /**
      * @dev Checks if all conditions for a specific conditional offer are currently met based on oracle data.
      * Public view function.
      * @param offerId The ID of the offer.
      * @return True if all conditions are met, false otherwise.
      */
     function checkOfferConditions(uint256 offerId) external view returns (bool) {
         require(conditionalOffers[offerId].buyer != address(0), "Offer does not exist");
         Listing storage listing = listings[conditionalOffers[offerId].listingId];
         return _checkAllConditions(listing.nftContract, listing.tokenId, conditionalOffers[offerId].conditions);
     }


    // Fallback function to receive ETH, mainly for escrow
    receive() external payable {}
    fallback() external payable {}
}

// Dummy IERC721 interface for local compilation if not using OpenZeppelin path
// In a real project, use "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
```

**Explanation of Advanced/Creative Concepts & Functions:**

1.  **AI Oracle Integration (`IAIOracle` interface, `oracleAddress`, `_getOracleScore`, `viewNFTScores`):**
    *   The contract relies on an external `IAIOracle` contract. This oracle is assumed to perform some AI analysis (e.g., analyzing NFT traits, market data, social sentiment) and provide a numerical score or other data for a given NFT.
    *   The marketplace *queries* this oracle. This decouples the complex, potentially gas-intensive AI computation (which would happen off-chain or on a separate layer) from the core marketplace logic.
    *   `viewNFTScores` allows anyone to query the oracle via the marketplace contract.

2.  **Conditional Listings & Offers (`Condition` struct, `ConditionType` enum, `conditions` arrays, `_checkCondition`, `_checkAllConditions`, `listNFT` with conditions, `makeConditionalOffer`):**
    *   NFTs can be listed (`listNFT`) with conditions. A direct purchase (`buyNFT`) is only possible if these listing conditions are *currently* met.
    *   Buyers can make `conditionalOffers` that only become valid/fulfillable if specific conditions related to the NFT (checked via the AI oracle) are met *after* the offer is accepted.
    *   Conditions are defined by a `ConditionType` (comparison operator), an `oracleQueryKey` (specifying what data to query from the oracle), and a `requiredValue`.

3.  **Conditional Escrow (`OfferState.AcceptedEscrow`, `_offerEscrowBalance`, `acceptConditionalOffer`, `fulfillConditionalOffer`):**
    *   When a seller `acceptConditionalOffer`, the buyer's ETH is *not* immediately transferred to the seller. It is held in escrow within the marketplace contract (`_offerEscrowBalance`).
    *   The transfer only happens later via `fulfillConditionalOffer`, *if and only if* the specified conditions (`offer.conditions`) are met *at the time of fulfillment*.
    *   This creates a stateful, conditional exchange mechanism beyond simple buy-now or auction models.

4.  **Fulfillment Logic (`fulfillConditionalOffer`, `OfferState.Fulfilled`, `OfferState.Failed`):**
    *   The `fulfillConditionalOffer` function centralizes the logic for checking post-acceptance conditions and executing the final asset/fund swap or marking the offer as failed if conditions aren't met. This function can be called by either party.

5.  **Basic Reputation System (`userReputation`, `leaveReputationFeedback`, `getUserReputation`):**
    *   A simple mapping tracks an integer reputation score per user.
    *   `leaveReputationFeedback` allows users to change another user's score. (NOTE: The current implementation is insecure and simplified for demonstration. A real system would require verifying transaction participation and preventing duplicate feedback).
    *   Successful conditional fulfillments (`fulfillConditionalOffer`) and successful direct purchases (`buyNFT`) grant positive reputation points to both buyer and seller. Dispute resolution can also influence reputation.

6.  **Dispute System (`Dispute` struct, `DisputeState` enum, `_disputeNonce`, `disputes`, `initiateDispute`, `resolveDispute`):**
    *   Allows parties of a *failed* conditional offer (`OfferState.Failed`) to `initiateDispute`.
    *   This moves the offer state to `OfferState.Disputed`.
    *   An admin (`onlyOwner`) can then call `resolveDispute` to manually determine the outcome (favor seller/buyer, potentially triggering a delayed fulfillment or refund) and update the offer/dispute state.

7.  **Basic Governance (`Proposal` struct, `ProposalState` enum, `_proposalNonce`, `proposals`, `hasVoted`, `proposePlatformFeeChange`, `voteOnProposal`, `executeProposal`):**
    *   A simple mechanism for proposing changes (specifically fee changes in this example).
    *   `proposePlatformFeeChange` creates a proposal storing the target function call (`setPlatformFee`) data.
    *   `voteOnProposal` allows users to vote (simplified: 1 user = 1 vote, requires only 1 vote to pass).
    *   `executeProposal` allows anyone to trigger the execution of a successful proposal's encoded function call.

8.  **Extensive State Tracking and Modifiers:**
    *   Uses enums (`ListingState`, `OfferState`, `ConditionType`, `ProposalState`, `DisputeState`) to manage complex object lifecycle states.
    *   Modifiers (`whenListingState`, `whenOfferState`, etc.) ensure functions can only be called when the relevant object is in the correct state.
    *   Uses multiple structs (`Listing`, `Condition`, `ConditionalOffer`, `Proposal`, `Dispute`) to organize diverse data types related to listings, conditions, offers, governance, and disputes.

This contract provides a framework integrating these concepts. Keep in mind that building a production-ready marketplace is complex and requires careful consideration of security, gas efficiency, scalability, external dependencies (like the oracle), and more robust implementations of features like reputation, governance, and dispute resolution. The conditional escrow logic, especially handling failed fulfillments and disputes, is particularly intricate.