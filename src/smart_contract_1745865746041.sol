Okay, here is a concept for a smart contract that combines several advanced ideas: **A Dynamic NFT Marketplace with Community-Driven Attribute Evolution and Time-Based Decay.**

The core idea is that NFTs minted through this contract are not static. Their attributes can change based on elapsed time, user interactions, and collective decisions made via a simplified on-chain voting mechanism.

**Concept Breakdown:**

1.  **Dynamic NFTs (DNFTs):** NFTs have standard metadata (name, description, image URI) and *additional, specific numerical or status attributes* that can change over time or based on conditions.
2.  **Time-Based Decay/Growth:** Some attributes might automatically decrease (decay) or increase (grow) based on how long it's been since the last update or interaction. This incentivizes engagement.
3.  **Interaction-Based Changes:** Specific actions (e.g., transferring, trading, or calling a specific `interact` function) can trigger attribute changes.
4.  **Community Governance/Voting:** A simple on-chain voting system allows token holders (or anyone with a stake/bond) to propose and vote on *boosting* or *altering* specific attributes of specific NFTs. Successful proposals trigger attribute changes.
5.  **Integrated Marketplace:** The contract acts as a marketplace for these DNFTs, handling listings, sales, offers, fees, and creator royalties, ensuring attribute changes are processed during transfers if needed.

**Why this is Advanced/Creative/Trendy:**

*   **Dynamic State:** Moves beyond static JPEGs to NFTs that live and evolve on-chain.
*   **On-Chain Mechanics:** Attribute changes are enforced by the contract, not just off-chain metadata updates.
*   **Game-Fi Potential:** Introduces mechanics like decay, boosting, and interaction that are common in games.
*   **Decentralized Curation/Influence:** Community voting allows collective influence over the assets' state and perceived value.
*   **Integrated Ecosystem:** Combines the NFT lifecycle (minting, evolution, trading) into a single contract.

**Non-Duplication:** While individual components exist (ERC721, basic marketplaces, simple voting), the *integration* of dynamic attributes driven by *multiple* triggers (time, interaction, governance) within a *single* marketplace contract is less common and requires custom logic beyond standard libraries. We will implement ERC721-like functions internally rather than inheriting directly from OpenZeppelin to further ensure non-duplication of a common open-source codebase.

---

**Outline & Function Summary**

**Contract:** `DynamicNFTMarketplace`

**Core Concepts:** Dynamic NFTs, Time/Interaction/Governance based Attribute Evolution, Integrated Marketplace, Royalty Enforcement, Admin Controls.

**Data Structures:**
*   `DynamicAttributeTemplate`: Defines a type of dynamic attribute (decay, boostable, interaction-driven) and its parameters.
*   `DynamicAttribute`: Holds the current value/state of a specific dynamic attribute for a specific NFT.
*   `NFTDetails`: Stores static metadata, current owner, and array of `DynamicAttribute`.
*   `Listing`: Details for an NFT listed for sale (seller, price).
*   `Offer`: Details for an offer made on an NFT (buyer, price).
*   `Proposal`: Details for a governance proposal to change an NFT attribute (proposer, target NFT/attribute, proposed value/change, voting period, state).
*   `Vote`: Records a voter's decision for a specific proposal.

**State Variables:**
*   Owner/Admin address.
*   Marketplace fee percentage.
*   Base royalty percentage for creators.
*   Counter for total NFTs minted.
*   Mapping from token ID to `NFTDetails`.
*   Mapping from token ID to `Listing`.
*   Mapping from token ID => offer ID => `Offer`.
*   Counter for offers per token.
*   Mapping from proposal ID to `Proposal`.
*   Mapping from proposal ID => voter address => `Vote`.
*   Counter for proposals.
*   Mapping from attribute template ID to `DynamicAttributeTemplate`.
*   Counter for attribute templates.
*   Internal ERC721-like state (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`).
*   Accumulated marketplace fees.
*   Accumulated creator royalties.

**Functions (26+ planned):**

**Admin & Configuration (5 functions):**
1.  `constructor(uint256 initialFeeBps, uint256 initialRoyaltyBps)`: Deploys contract, sets initial fees and owner.
2.  `setMarketplaceFeeBps(uint256 feeBps)`: Sets the marketplace fee percentage (basis points).
3.  `setBaseRoyaltyBps(uint256 royaltyBps)`: Sets the base royalty percentage for creators.
4.  `addDynamicAttributeTemplate(string memory name, uint8 templateType, int256 param1, uint256 param2, uint256 updateInterval)`: Adds a new template defining how an attribute type behaves (e.g., type 1=decay, param1=rate, param2=min value, interval=daily).
5.  `removeDynamicAttributeTemplate(uint256 templateId)`: Removes an attribute template.

**NFT Management & Dynamics (7 functions):**
6.  `mintNFT(address creator, string memory tokenURI, uint256[] memory initialTemplateIds)`: Mints a new NFT, assigns initial dynamic attributes based on provided template IDs, sets creator and owner.
7.  `getTokenDetails(uint256 tokenId)`: Returns static metadata and current dynamic attributes for a token.
8.  `updateDynamicAttributes(uint256 tokenId)`: Triggers the update logic for all dynamic attributes of a token based on their templates and elapsed time/interactions since last update. Anyone can call, possibly incentivized or with a small fee/gas cost.
9.  `triggerInteraction(uint256 tokenId, uint8 interactionType)`: Records a specific interaction for a token, potentially triggering attribute changes defined by templates.
10. `getInteractionCount(uint256 tokenId, uint8 interactionType)`: Gets the count for a specific interaction type on a token.
11. `getLastAttributeUpdateTime(uint256 tokenId, uint256 attributeId)`: Returns the timestamp of the last update for a specific attribute.
12. `getDynamicAttributeTemplate(uint256 templateId)`: Returns details of a dynamic attribute template.

**Marketplace (8 functions):**
13. `listNFTForSale(uint256 tokenId, uint256 price)`: Owner lists their NFT for sale at a fixed price.
14. `delistNFT(uint256 tokenId)`: Owner removes their NFT from listing.
15. `buyNFT(uint256 tokenId)`: Buyer purchases a listed NFT. Handles transfer, fees, royalties, and triggers attribute updates before transfer. Requires exactly the listing price to be sent.
16. `makeOffer(uint256 tokenId, uint256 price)`: User makes an offer on an NFT (listed or not). Requires offer amount to be sent with the call (escrow).
17. `cancelOffer(uint256 tokenId, uint256 offerId)`: User cancels their outstanding offer and withdraws escrowed ETH.
18. `acceptOffer(uint256 tokenId, uint256 offerId)`: NFT owner accepts an offer. Handles transfer, releases escrowed ETH, distributes fees/royalties, and triggers attribute updates before transfer.
19. `getListingDetails(uint256 tokenId)`: Returns listing information for a token.
20. `getOffersReceived(uint256 tokenId)`: Returns all active offers for a token.

**Governance & Voting (5 functions):**
21. `proposeAttributeBoost(uint256 tokenId, uint256 attributeId, int256 boostAmount, uint256 votingPeriodDuration)`: Anyone can propose a change (boost/alteration) to a specific attribute of an NFT. Requires a bond (ETH sent with call). Creates a proposal.
22. `voteForAttributeBoost(uint256 proposalId, bool support)`: Allows users (or token holders, simulated here by unique addresses) to vote on an open proposal.
23. `executeAttributeBoostProposal(uint256 proposalId)`: Callable by anyone after the voting period ends. Checks if the proposal passed (e.g., simple majority of voters). If passed, applies the attribute change to the NFT, releases the bond to the proposer. If failed, returns the bond to the proposer.
24. `getProposalDetails(uint256 proposalId)`: Returns details of a specific governance proposal.
25. `getVotesForProposal(uint256 proposalId)`: Returns vote counts for a proposal.

**Withdrawals (2 functions):**
26. `withdrawMarketplaceFees()`: Owner withdraws accumulated marketplace fees.
27. `withdrawRoyalty()`: Creator withdraws their accumulated royalties.

**(Implicit/Internal) ERC721-like functions:**
*   `balanceOf(address owner)`
*   `ownerOf(uint256 tokenId)`
*   `setApprovalForAll(address operator, bool approved)`
*   `isApprovedForAll(address owner, address operator)`
*   `transferFrom(address from, address to, uint256 tokenId)`
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`
*   `_mint(address to, uint256 tokenId)`
*   `_transfer(address from, address to, uint256 tokenId)`
*   `supportsInterface(bytes4 interfaceId)` (for ERC721 and ERC165)

Let's implement the core logic including internal ERC721-like functions to meet the "non-duplicate" requirement as much as possible.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DynamicNFTMarketplace
 * @dev A marketplace for Dynamic NFTs where attributes can evolve based on time, interactions,
 * and community governance votes. Implements custom logic for NFT ownership, transfer,
 * marketplace functions, dynamic attribute updates, and a simplified voting system.
 * Avoids direct inheritance from standard OpenZeppelin contracts to demonstrate custom
 * implementation of core concepts.
 */

// --- Outline & Function Summary ---
// State Variables:
// - Owner address, fees, royalties.
// - Counters for NFTs, Attribute Templates, Proposals, Offers.
// - Mappings for NFT details (static + dynamic attributes), Listings, Offers.
// - Mappings for Attribute Templates.
// - Mappings for Proposals, Votes.
// - Internal ERC721-like state (_owners, _balances, _operatorApprovals).
// - Accumulated fees and royalties balances.

// Data Structures:
// - DynamicAttributeTemplate: Defines dynamic attribute behavior (type, params, interval).
// - DynamicAttribute: Current state of a dynamic attribute on an NFT (templateId, value, lastUpdate).
// - NFTDetails: Static metadata, creator, owner, array of DynamicAttribute.
// - Listing: Seller, price for listed NFTs.
// - Offer: Buyer, price, active status for offers.
// - Proposal: Target NFT/attribute, proposed change, voting period, state, proposer, bond.
// - Vote: Voter address, decision.

// Functions:
// Admin & Configuration (5):
// 1. constructor: Sets initial owner, fees.
// 2. setMarketplaceFeeBps: Sets marketplace fee.
// 3. setBaseRoyaltyBps: Sets base royalty.
// 4. addDynamicAttributeTemplate: Adds a new dynamic attribute type/logic.
// 5. removeDynamicAttributeTemplate: Removes an attribute template.

// NFT Management & Dynamics (7):
// 6. mintNFT: Mints a new DNFT with initial attributes.
// 7. getTokenDetails: Gets full details (static + dynamic) of an NFT.
// 8. updateDynamicAttributes: Triggers calculation and update of dynamic attributes based on rules.
// 9. triggerInteraction: Records an interaction event on an NFT.
// 10. getInteractionCount: Gets the count of a specific interaction type.
// 11. getLastAttributeUpdateTime: Gets last update timestamp for an attribute.
// 12. getDynamicAttributeTemplate: Gets details of an attribute template.

// Marketplace (8):
// 13. listNFTForSale: Lists an NFT for sale.
// 14. delistNFT: Removes an NFT from listing.
// 15. buyNFT: Purchases a listed NFT (handles transfer, fees, royalties, attribute update).
// 16. makeOffer: Makes an offer on an NFT (escrows ETH).
// 17. cancelOffer: Cancels an offer (releases escrowed ETH).
// 18. acceptOffer: Accepts an offer (handles transfer, fees, royalties, attribute update, escrow release).
// 19. getListingDetails: Gets details of an NFT listing.
// 20. getOffersReceived: Gets active offers for an NFT.

// Governance & Voting (5):
// 21. proposeAttributeBoost: Creates a proposal to change an attribute (requires bond).
// 22. voteForAttributeBoost: Votes on an open proposal.
// 23. executeAttributeBoostProposal: Executes a passed proposal (applies change, handles bond).
// 24. getProposalDetails: Gets details of a proposal.
// 25. getVotesForProposal: Gets vote counts for a proposal.

// Withdrawals (2):
// 26. withdrawMarketplaceFees: Owner withdraws fees.
// 27. withdrawRoyalty: Creator withdraws royalties.

// Internal ERC721-like (Implicitly used/implemented):
// balance of, owner of, transfers, approvals, supportsInterface

contract DynamicNFTMarketplace {

    // --- Events ---
    event NFTMinted(uint256 indexed tokenId, address indexed creator, address indexed owner, string tokenURI);
    event AttributesUpdated(uint256 indexed tokenId, uint256 indexed attributeId, int256 newValue);
    event NFTListed(uint256 indexed tokenId, uint256 price, address indexed seller);
    event NFTDelisted(uint256 indexed tokenId);
    event NFTSold(uint256 indexed tokenId, uint256 price, address indexed buyer, address indexed seller);
    event OfferMade(uint256 indexed tokenId, uint256 indexed offerId, uint256 price, address indexed buyer);
    event OfferCancelled(uint256 indexed tokenId, uint256 indexed offerId);
    event OfferAccepted(uint256 indexed tokenId, uint256 indexed offerId, uint256 price, address indexed acceptor);
    event MarketplaceFeeWithdrawal(address indexed owner, uint256 amount);
    event RoyaltyWithdrawal(address indexed creator, uint256 amount);
    event AttributeTemplateAdded(uint256 indexed templateId, string name, uint8 templateType);
    event AttributeTemplateRemoved(uint256 indexed templateId);
    event InteractionTriggered(uint256 indexed tokenId, uint8 interactionType, uint256 count);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed tokenId, uint256 attributeId, int256 boostAmount, uint256 votingEnds);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Data Structures ---

    struct DynamicAttributeTemplate {
        string name;
        uint8 templateType; // e.g., 0=Decay, 1=Growth, 2=BoostableByVote, 3=InteractionTriggered
        int256 param1;      // Decay/Growth rate, Boost amount multiplier
        uint256 param2;      // Min/Max value, Interaction type threshold
        uint256 updateInterval; // Time in seconds for decay/growth interval
    }

    struct DynamicAttribute {
        uint256 templateId;
        int256 value;
        uint256 lastUpdateTimestamp;
        uint256 lastInteractionCount; // Used for interaction-triggered attributes
    }

    struct NFTDetails {
        string tokenURI;
        address creator;
        DynamicAttribute[] dynamicAttributes;
        // ERC721 state managed separately in mappings for gas efficiency
    }

    struct Listing {
        address seller;
        uint256 price;
        bool active;
    }

    struct Offer {
        address buyer;
        uint256 price;
        bool active;
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 tokenId;
        uint256 attributeId;
        int256 proposedChange;
        uint256 votingEnds;
        address proposer;
        uint256 bondAmount;
        ProposalState state;
        uint256 supportVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Internal map per proposal
    }

    // --- State Variables ---

    address private _owner;
    uint256 public marketplaceFeeBps; // Basis points (e.g., 250 = 2.5%)
    uint256 public baseRoyaltyBps;    // Basis points (e.g., 500 = 5%)

    uint256 private _nextTokenId;
    mapping(uint256 => NFTDetails) private _tokenDetails;

    mapping(uint256 => Listing) private _listings;

    mapping(uint256 => mapping(uint256 => Offer)) private _offers;
    mapping(uint256 => uint256) private _nextOfferId; // Counter for offers per token

    uint256 private _nextAttributeTemplateId;
    mapping(uint256 => DynamicAttributeTemplate) private _attributeTemplates;

    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) private _proposals;

    mapping(uint256 => mapping(uint8 => uint256)) private _interactionCounts; // tokenId => type => count

    // ERC721-like internal state
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals; // Not strictly needed for marketplace, but good ERC721 practice
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Balances held by the contract before withdrawal
    uint256 private _marketplaceFeesBalance;
    mapping(address => uint256) private _creatorRoyaltyBalances;
    mapping(uint256 => uint256) private _escrowBalances; // For offers

    // --- Access Control ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    // --- Constructor ---

    constructor(uint256 initialFeeBps, uint256 initialRoyaltyBps) {
        _owner = msg.sender;
        marketplaceFeeBps = initialFeeBps;
        baseRoyaltyBps = initialRoyaltyBps;
        _nextTokenId = 1; // Start token IDs from 1
        _nextAttributeTemplateId = 1;
        _nextProposalId = 1;
    }

    // --- Admin & Configuration Functions (5) ---

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function setMarketplaceFeeBps(uint256 feeBps) public onlyOwner {
        require(feeBps <= 10000, "Fee exceeds 100%");
        marketplaceFeeBps = feeBps;
    }

    function setBaseRoyaltyBps(uint256 royaltyBps) public onlyOwner {
        require(royaltyBps <= 10000, "Royalty exceeds 100%");
        baseRoyaltyBps = royaltyBps;
    }

    // templateType: 0=Decay (param1=rate, param2=min), 1=Growth (param1=rate, param2=max), 2=BoostableByVote (param1=boost amount), 3=InteractionTriggered (param1=boost per interaction, param2=interactionType)
    function addDynamicAttributeTemplate(string memory name, uint8 templateType, int256 param1, uint256 param2, uint256 updateInterval) public onlyOwner {
        uint256 templateId = _nextAttributeTemplateId++;
        _attributeTemplates[templateId] = DynamicAttributeTemplate({
            name: name,
            templateType: templateType,
            param1: param1,
            param2: param2,
            updateInterval: updateInterval
        });
        emit AttributeTemplateAdded(templateId, name, templateType);
    }

    function removeDynamicAttributeTemplate(uint256 templateId) public onlyOwner {
        require(_attributeTemplates[templateId].templateType != 0xFF, "Template does not exist"); // Using a dummy value to check existence
        delete _attributeTemplates[templateId];
        emit AttributeTemplateRemoved(templateId);
    }

    // --- NFT Management & Dynamics Functions (7) ---

    function mintNFT(address creator, string memory tokenURI, uint256[] memory initialTemplateIds) public returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        require(_owners[tokenId] == address(0), "Token already exists"); // Should not happen with counter

        NFTDetails storage details = _tokenDetails[tokenId];
        details.tokenURI = tokenURI;
        details.creator = creator;

        for (uint i = 0; i < initialTemplateIds.length; i++) {
            uint256 templateId = initialTemplateIds[i];
            require(_attributeTemplates[templateId].templateType != 0xFF, "Invalid attribute template ID");
            details.dynamicAttributes.push(DynamicAttribute({
                templateId: templateId,
                value: 0, // Initial value, can be set by another parameter if needed
                lastUpdateTimestamp: block.timestamp,
                lastInteractionCount: 0
            }));
        }

        // Internal ERC721-like minting
        _owners[tokenId] = creator; // Creator is initial owner
        _balances[creator]++;

        emit NFTMinted(tokenId, creator, creator, tokenURI);
    }

    function getTokenDetails(uint256 tokenId) public view returns (
        string memory tokenURI,
        address creator,
        address owner,
        DynamicAttribute[] memory dynamicAttributes
    ) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        NFTDetails storage details = _tokenDetails[tokenId];
        tokenURI = details.tokenURI;
        creator = details.creator;
        owner = _owners[tokenId];
        dynamicAttributes = new DynamicAttribute[](details.dynamicAttributes.length);
        for (uint i = 0; i < details.dynamicAttributes.length; i++) {
             // Note: Dynamic attributes fetched might be slightly out of date if not updated
             // Call updateDynamicAttributes before fetching for latest state if critical
            dynamicAttributes[i] = details.dynamicAttributes[i];
        }
    }

    // Helper to find attribute index by templateId
    function _findAttributeIndex(uint256 tokenId, uint256 templateId) internal view returns (uint256 index, bool found) {
        NFTDetails storage details = _tokenDetails[tokenId];
        for (uint i = 0; i < details.dynamicAttributes.length; i++) {
            if (details.dynamicAttributes[i].templateId == templateId) {
                return (i, true);
            }
        }
        return (0, false);
    }

    function updateDynamicAttributes(uint256 tokenId) public {
        require(_owners[tokenId] != address(0), "Token does not exist");
        NFTDetails storage details = _tokenDetails[tokenId];

        for (uint i = 0; i < details.dynamicAttributes.length; i++) {
            DynamicAttribute storage attr = details.dynamicAttributes[i];
            DynamicAttributeTemplate storage template = _attributeTemplates[attr.templateId];

            if (template.templateType == 0) { // Decay
                if (template.updateInterval > 0) {
                    uint256 timeElapsed = block.timestamp - attr.lastUpdateTimestamp;
                    uint256 intervals = timeElapsed / template.updateInterval;
                    if (intervals > 0) {
                        int256 decayAmount = template.param1 * int256(intervals); // param1 is decay rate
                        attr.value -= decayAmount;
                        if (template.param2 != 0) { // param2 is min value
                             if (attr.value < template.param2) attr.value = template.param2;
                        }
                        attr.lastUpdateTimestamp = block.timestamp;
                        emit AttributesUpdated(tokenId, attr.templateId, attr.value);
                    }
                }
            } else if (template.templateType == 1) { // Growth
                 if (template.updateInterval > 0) {
                    uint256 timeElapsed = block.timestamp - attr.lastUpdateTimestamp;
                    uint256 intervals = timeElapsed / template.updateInterval;
                    if (intervals > 0) {
                        int256 growthAmount = template.param1 * int256(intervals); // param1 is growth rate
                        attr.value += growthAmount;
                         if (template.param2 != 0) { // param2 is max value
                            if (attr.value > template.param2) attr.value = template.param2;
                         }
                        attr.lastUpdateTimestamp = block.timestamp;
                        emit AttributesUpdated(tokenId, attr.templateId, attr.value);
                    }
                }
            } else if (template.templateType == 3) { // Interaction Triggered
                uint8 interactionType = uint8(template.param2); // param2 is interaction type
                uint256 currentInteractionCount = _interactionCounts[tokenId][interactionType];
                if (currentInteractionCount > attr.lastInteractionCount) {
                    uint256 newInteractions = currentInteractionCount - attr.lastInteractionCount;
                    int256 boostAmount = template.param1 * int256(newInteractions); // param1 is boost per interaction
                    attr.value += boostAmount;
                    attr.lastInteractionCount = currentInteractionCount;
                     // No explicit max/min from template params for this type currently
                    emit AttributesUpdated(tokenId, attr.templateId, attr.value);
                }
            }
            // Type 2 (BoostableByVote) is updated by executeAttributeBoostProposal
        }
    }

    function triggerInteraction(uint256 tokenId, uint8 interactionType) public {
        require(_owners[tokenId] != address(0), "Token does not exist");
        _interactionCounts[tokenId][interactionType]++;
        emit InteractionTriggered(tokenId, interactionType, _interactionCounts[tokenId][interactionType]);
        // Optional: Automatically call updateDynamicAttributes here if desired
        // updateDynamicAttributes(tokenId); // Can be gas intensive
    }

    function getInteractionCount(uint256 tokenId, uint8 interactionType) public view returns (uint256) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _interactionCounts[tokenId][interactionType];
    }

    function getLastAttributeUpdateTime(uint255 tokenId, uint256 attributeId) public view returns (uint256) {
        require(_owners[tokenId] != address(0), "Token does not exist");
         NFTDetails storage details = _tokenDetails[tokenId];
        for (uint i = 0; i < details.dynamicAttributes.length; i++) {
            if (details.dynamicAttributes[i].templateId == attributeId) {
                return details.dynamicAttributes[i].lastUpdateTimestamp;
            }
        }
        revert("Attribute not found on token"); // Should not happen if attributeId comes from tokenDetails
    }

     function getDynamicAttributeTemplate(uint256 templateId) public view returns (
        string memory name, uint8 templateType, int256 param1, uint256 param2, uint256 updateInterval)
    {
        DynamicAttributeTemplate storage template = _attributeTemplates[templateId];
        require(template.templateType != 0xFF, "Template does not exist");
        return (template.name, template.templateType, template.param1, template.param2, template.updateInterval);
    }


    // --- Marketplace Functions (8) ---

    function listNFTForSale(uint256 tokenId, uint256 price) public {
        require(_owners[tokenId] == msg.sender, "Caller is not token owner");
        require(_listings[tokenId].active == false, "Token is already listed");
        require(price > 0, "Price must be positive");

        // ERC721-like approval check: Marketplace must be an approved operator or approved for the specific token
        require(getApproved(tokenId) == address(this) || isApprovedForAll(_owners[tokenId], address(this)),
                "Marketplace not approved to manage token");

        _listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            active: true
        });

        emit NFTListed(tokenId, price, msg.sender);
    }

    function delistNFT(uint256 tokenId) public {
        require(_listings[tokenId].active == true, "Token not listed");
        require(_listings[tokenId].seller == msg.sender, "Caller is not the seller");

        delete _listings[tokenId]; // Setting active to false is equivalent to deleting
        emit NFTDelisted(tokenId);
    }

    function buyNFT(uint256 tokenId) public payable {
        Listing storage listing = _listings[tokenId];
        require(listing.active == true, "Token not listed for sale");
        require(msg.value == listing.price, "Incorrect ETH amount sent");
        require(_owners[tokenId] != msg.sender, "Cannot buy your own token");

        address seller = listing.seller;
        address buyer = msg.sender;
        uint256 price = listing.price;

        // Important: Process dynamic attribute updates before transfer
        updateDynamicAttributes(tokenId);

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeeBps) / 10000;
        uint256 royaltyAmount = (price * baseRoyaltyBps) / 10000; // Using base royalty, could be per-NFT
        uint256 sellerPayout = price - marketplaceFee - royaltyAmount;

        // Distribute funds (hold in contract before withdrawal)
        _marketplaceFeesBalance += marketplaceFee;
        _creatorRoyaltyBalances[_tokenDetails[tokenId].creator] += royaltyAmount;

        // Transfer ownership (internal ERC721-like)
        _transfer(seller, buyer, tokenId);

        // Payout seller - Use Checks-Effects-Interactions pattern
        (bool success, ) = payable(seller).call{value: sellerPayout}("");
        require(success, "ETH transfer failed");

        // Clean up listing
        delete _listings[tokenId];

        emit NFTSold(tokenId, price, buyer, seller);
    }

    function makeOffer(uint256 tokenId, uint256 price) public payable {
        require(_owners[tokenId] != address(0), "Token does not exist");
        require(_owners[tokenId] != msg.sender, "Cannot make offer on your own token");
        require(msg.value == price && price > 0, "Incorrect or zero ETH amount sent");

        uint256 offerId = _nextOfferId[tokenId]++;
        _offers[tokenId][offerId] = Offer({
            buyer: msg.sender,
            price: price,
            active: true
        });
        _escrowBalances[offerId] += msg.value; // Escrow ETH in contract

        emit OfferMade(tokenId, offerId, price, msg.sender);
    }

    function cancelOffer(uint256 tokenId, uint256 offerId) public {
        Offer storage offer = _offers[tokenId][offerId];
        require(offer.active == true, "Offer is not active");
        require(offer.buyer == msg.sender, "Caller did not make this offer");

        offer.active = false; // Mark offer as inactive

        // Refund escrowed ETH - Use Checks-Effects-Interactions pattern
        uint256 refundAmount = _escrowBalances[offerId];
        _escrowBalances[offerId] = 0; // Clear balance before transfer

        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "ETH transfer failed");

        emit OfferCancelled(tokenId, offerId);
    }

    function acceptOffer(uint256 tokenId, uint256 offerId) public {
        require(_owners[tokenId] == msg.sender, "Caller is not token owner");

        Offer storage offer = _offers[tokenId][offerId];
        require(offer.active == true, "Offer is not active");

        // Ensure marketplace has approval
         require(getApproved(tokenId) == address(this) || isApprovedForAll(_owners[tokenId], address(this)),
                "Marketplace not approved to manage token");

        address seller = msg.sender;
        address buyer = offer.buyer;
        uint256 price = offer.price;

        // Important: Process dynamic attribute updates before transfer
        updateDynamicAttributes(tokenId);

        // Calculate fees and royalties
        uint256 marketplaceFee = (price * marketplaceFeeBps) / 10000;
        uint256 royaltyAmount = (price * baseRoyaltyBps) / 10000;
        uint256 sellerPayout = price - marketplaceFee - royaltyAmount;

        // Distribute funds from escrow (hold in contract before withdrawal)
        uint256 escrowAmount = _escrowBalances[offerId];
        require(escrowAmount >= price, "Escrow amount insufficient"); // Should not happen if makeOffer logic is correct

        _marketplaceFeesBalance += marketplaceFee;
        _creatorRoyaltyBalances[_tokenDetails[tokenId].creator] += royaltyAmount;
        _escrowBalances[offerId] -= price; // Deduct price from escrow (remaining is potential change if overpaid, or should be 0)

        // Transfer ownership (internal ERC721-like)
        _transfer(seller, buyer, tokenId);

        // Payout seller - Use Checks-Effects-Interactions pattern
        (bool success, ) = payable(seller).call{value: sellerPayout}("");
        require(success, "ETH transfer failed");

        // Any remaining escrow balance (e.g., if offer was > price) could be returned to buyer or handled differently.
        // For simplicity, let's assume offer price == value sent. If they differ, adjust makeOffer logic.
        // Here, any small dust remains in contract or is intended as part of offer.
        // A safer approach is to send exact price in makeOffer or handle change explicitly.

        // Clean up offer and any listing
        offer.active = false;
        if (_listings[tokenId].active) {
            delete _listings[tokenId];
        }

        emit OfferAccepted(tokenId, offerId, price, msg.sender);
    }

    function getListingDetails(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }

    function getOffersReceived(uint256 tokenId) public view returns (Offer[] memory) {
        // Note: This function could be gas intensive if there are many offers.
        // A more scalable approach would be pagination or external indexing.
        uint265 totalOffers = _nextOfferId[tokenId];
        Offer[] memory activeOffers = new Offer[](totalOffers);
        uint256 currentCount = 0;
        for(uint256 i = 0; i < totalOffers; i++) {
            if (_offers[tokenId][i].active) {
                activeOffers[currentCount] = _offers[tokenId][i];
                currentCount++;
            }
        }
        // Resize array
        Offer[] memory result = new Offer[](currentCount);
        for(uint256 i = 0; i < currentCount; i++) {
            result[i] = activeOffers[i];
        }
        return result;
    }

    // --- Governance & Voting Functions (5) ---

    // Requires sending bondAmount with the call
    function proposeAttributeBoost(uint256 tokenId, uint256 attributeTemplateId, int256 boostAmount, uint256 votingPeriodDuration) public payable returns (uint256 proposalId) {
        require(_owners[tokenId] != address(0), "Token does not exist");
        require(_attributeTemplates[attributeTemplateId].templateType == 2, "Attribute template not boostable by vote"); // Must be a boostable type

        uint256 attributeIndex;
        bool found;
        (attributeIndex, found) = _findAttributeIndex(tokenId, attributeTemplateId);
        require(found, "Attribute not found on token");

        require(msg.value > 0, "Proposal requires a bond"); // Simple bond mechanism

        proposalId = _nextProposalId++;
        Proposal storage proposal = _proposals[proposalId];

        proposal.tokenId = tokenId;
        proposal.attributeId = attributeTemplateId;
        proposal.proposedChange = boostAmount;
        proposal.votingEnds = block.timestamp + votingPeriodDuration;
        proposal.proposer = msg.sender;
        proposal.bondAmount = msg.value;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, tokenId, attributeTemplateId, boostAmount, proposal.votingEnds);
    }

    function voteForAttributeBoost(uint256 proposalId, bool support) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp <= proposal.votingEnds, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true; // Record vote
        if (support) {
            proposal.supportVotes++;
        } else {
            proposal.againstVotes++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    // Callable after voting period ends
    function executeAttributeBoostProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp > proposal.votingEnds, "Voting period has not ended yet");

        uint256 totalVotes = proposal.supportVotes + proposal.againstVotes;
        bool passed = false;

        // Simple majority rule (more support than against) and minimum voter threshold (e.g., 1 voter)
        if (totalVotes > 0 && proposal.supportVotes > proposal.againstVotes) {
             passed = true;
        }

        if (passed) {
            proposal.state = ProposalState.Succeeded;
            uint256 attributeIndex;
            bool found;
            (attributeIndex, found) = _findAttributeIndex(proposal.tokenId, proposal.attributeId);
            // Double check attribute still exists on token
            if (found) {
                 DynamicAttribute storage attr = _tokenDetails[proposal.tokenId].dynamicAttributes[attributeIndex];
                 attr.value += proposal.proposedChange; // Apply the boost/change
                 // Update timestamp? Maybe not for governance boosts, or update to block.timestamp
                 // attr.lastUpdateTimestamp = block.timestamp; // Optional
                 emit AttributesUpdated(proposal.tokenId, proposal.attributeId, attr.value);
            } else {
                // If attribute was removed since proposal, proposal effectively fails application
                passed = false;
                 proposal.state = ProposalState.Failed; // Change state if attribute not found
            }

            // Return bond to proposer on success
            (bool success, ) = payable(proposal.proposer).call{value: proposal.bondAmount}("");
            require(success, "Bond return failed"); // Potential issue if return fails

        } else {
            proposal.state = ProposalState.Failed;
            // Return bond to proposer on failure
            (bool success, ) = payable(proposal.proposer).call{value: proposal.bondAmount}("");
            require(success, "Bond return failed"); // Potential issue if return fails
        }

         // Mark proposal as executed regardless of pass/fail after handling bond and state
        proposal.state = (passed ? ProposalState.Executed : ProposalState.Failed); // Final state after bond transfer attempt

        emit ProposalExecuted(proposalId, passed);
    }

    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 tokenId, uint256 attributeId, int256 proposedChange, uint256 votingEnds,
        address proposer, uint256 bondAmount, ProposalState state, uint256 supportVotes, uint256 againstVotes
    ) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state != ProposalState.Pending, "Proposal does not exist"); // Pending is initial zero state

        return (proposal.tokenId, proposal.attributeId, proposal.proposedChange, proposal.votingEnds,
                proposal.proposer, proposal.bondAmount, proposal.state, proposal.supportVotes, proposal.againstVotes);
    }

     function getVotesForProposal(uint256 proposalId) public view returns (uint256 supportVotes, uint256 againstVotes) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state != ProposalState.Pending, "Proposal does not exist");
        return (proposal.supportVotes, proposal.againstVotes);
    }


    // --- Withdrawal Functions (2) ---

    function withdrawMarketplaceFees() public onlyOwner {
        uint256 amount = _marketplaceFeesBalance;
        require(amount > 0, "No fees to withdraw");
        _marketplaceFeesBalance = 0; // Clear balance before transfer

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit MarketplaceFeeWithdrawal(msg.sender, amount);
    }

    function withdrawRoyalty() public {
        address creator = msg.sender;
        uint256 amount = _creatorRoyaltyBalances[creator];
        require(amount > 0, "No royalties to withdraw");
        _creatorRoyaltyBalances[creator] = 0; // Clear balance before transfer

        (bool success, ) = payable(creator).call{value: amount}("");
        require(success, "Royalty withdrawal failed");
        emit RoyaltyWithdrawal(creator, amount);
    }

    // --- Internal ERC721-like Implementation (Partial) ---
    // Implementing necessary functions manually to avoid direct OpenZeppelin dependency

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // Basic ownership check
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals for the token being transferred
        _tokenApprovals[tokenId] = address(0);

        // Update balances and ownership
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // ERC721 Transfer event (optional, but good practice)
        // emit Transfer(from, to, tokenId); // Need ERC721 events if aiming for full compliance
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

     function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approval query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

     function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        // ERC721 ApprovalForAll event (optional)
        // emit ApprovalForAll(msg.sender, operator, approved); // Need ERC721 events
    }


    // Note: Full ERC721 requires `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`,
    // `transferFrom`, `safeTransferFrom`, `supportsInterface`.
    // We have implemented `ownerOf`, `balanceOf`, `_transfer`, `getApproved`, `isApprovedForAll`, `setApprovalForAll`
    // for marketplace needs. `transferFrom` and `safeTransferFrom` would require adding logic
    // to check approvals/operator status before calling `_transfer`. `supportsInterface`
    // requires implementing ERC165. Adding these would push function count higher if needed.
    // For this example, the core marketplace/dynamic logic is the focus.

    // Placeholder for ERC721/ERC165 interface support
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
         // Minimal implementation for ERC165 (0x01ffc9a7) and ERC721 (0x80ac58cd)
         return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd;
         // More comprehensive would check specific functions like tokenOfOwnerByIndex etc.
    }

    // --- Getters for Contract Balances (Auxiliary) ---
     function getMarketplaceBalance() public view onlyOwner returns (uint256) {
        return _marketplaceFeesBalance;
    }

     function getCreatorBalance(address creator) public view returns (uint256) {
        return _creatorRoyaltyBalances[creator];
    }

    // Getter for a single offer by ID (useful for client)
     function getOfferDetails(uint256 tokenId, uint256 offerId) public view returns (Offer memory) {
         require(_offers[tokenId][offerId].buyer != address(0) || offerId == 0, "Offer does not exist"); // Check if offer struct is default or ID 0
         return _offers[tokenId][offerId];
     }

    // Helper to get all tokens owned by an address (can be gas intensive)
    // ERC721Enumerable implements this more efficiently with token lists.
    // This is a basic implementation for demonstration.
     function getOwnerNFTs(address owner) public view returns (uint256[] memory) {
        uint265 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        uint256 currentCount = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) { // Iterate all possible token IDs
            if (_owners[i] == owner) {
                tokenIds[currentCount] = i;
                currentCount++;
            }
            if (currentCount == tokenCount) break; // Stop if we found all
        }
        return tokenIds;
     }

     // Function to get total NFTs minted
     function getTotalSupply() public view returns (uint256) {
         return _nextTokenId - 1;
     }
}
```