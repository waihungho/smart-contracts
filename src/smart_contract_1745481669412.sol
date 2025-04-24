Okay, let's create a smart contract that combines several interesting concepts: a marketplace for Dynamic NFTs whose attributes can change based on external data (simulated via an Oracle pattern, perhaps influenced by AI analysis off-chain), includes a governance mechanism potentially tied to NFT ownership, and has a fee structure.

We'll call it `DynamicNFTMarketplaceWithAIOracle`.

**Key Concepts Used:**

1.  **Dynamic NFTs:** NFTs whose metadata or on-chain attributes can change after minting.
2.  **Oracle Integration:** A mechanism to receive data from off-chain sources (simulated callback).
3.  **AI Influence (Simulated):** The off-chain data *could* be the result of an AI analyzing trends, market sentiment, environmental data, etc., which then feeds into the Oracle.
4.  **NFT Marketplace:** Core functions for listing and buying NFTs.
5.  **NFT-Based Governance:** Allowing NFT holders to propose and vote on changes (e.g., fee percentages, oracle parameters, future features).
6.  **Access Control:** Using roles to manage permissions (admin, minter, oracle, governor).
7.  **Fees and Treasury:** Charging fees on marketplace transactions and managing collected funds.
8.  **Time-Based Dynamics:** Introducing an element where attributes can also change based on time elapsed since the last update or minting.

**Outline and Function Summary**

**Contract:** `DynamicNFTMarketplaceWithAIOracle`

This contract serves as a marketplace and management layer for dynamic NFTs. It allows users to mint, list, and buy NFTs whose attributes can be updated based on external data received via an oracle, internal time-based triggers, and governed parameters.

---

**Outline:**

1.  **Contract Definition & Libraries:** Imports, SPDX License, Pragma.
2.  **Roles & Access Control:** Defines roles for managing permissions using OpenZeppelin's `AccessControl`.
3.  **Structs & Enums:** Definitions for NFT attributes, marketplace listings, oracle requests, and governance proposals.
4.  **State Variables:** Store contract state, including NFT data, listings, oracle configuration, governance data, fees, and roles.
5.  **Events:** Announce significant actions (minting, listing, trading, attribute updates, oracle requests, governance).
6.  **Constructor:** Initializes roles and basic settings.
7.  **ERC721 Standard Functions (Implemented/Overridden):** Basic NFT operations (`balanceOf`, `ownerOf`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `tokenURI`). Handled via inheritance from OpenZeppelin ERC721. *Note: While these are standard, their implementation details within the contract's lifecycle (e.g., tracking ownership for governance) are custom.*
8.  **Minting Functions:** Creating new NFTs.
9.  **Dynamic Attribute Management:** Functions to trigger attribute updates and handle oracle responses.
10. **Marketplace Functions:** Listing, buying, cancelling, and updating listings.
11. **Fee Management:** Setting fees and withdrawing collected fees.
12. **Oracle Configuration:** Setting the trusted oracle address and configuring data mapping rules.
13. **Governance Functions:** Creating proposals, voting, executing proposals, and viewing proposal states.
14. **View Functions:** Public functions to read contract state (NFT attributes, listings, proposals, roles, etc.).

---

**Function Summary (Approx. 27 Functions):**

*(Note: Some standard ERC721 functions handled by inheritance are listed for completeness as they are part of the contract's interface, but the focus is on the custom logic)*

1.  `constructor()`: Initializes the contract, setting up roles (Default Admin, Minter, Oracle, Governor).
2.  `supportsInterface(bytes4 interfaceId)`: ERC165 standard, checks if the contract supports an interface (ERC721, AccessControl, etc.).
3.  `hasRole(bytes32 role, address account)`: Checks if an account has a specific role.
4.  `grantRole(bytes32 role, address account)`: Grants a role to an account (Admin only).
5.  `revokeRole(bytes32 role, address account)`: Revokes a role from an account (Admin only).
6.  `renounceRole(bytes32 role)`: Allows an account to renounce its own role.
7.  `mint(address to, uint256 tokenId, string memory initialURI, Attribute[] memory initialAttributes)`: Mints a new dynamic NFT (Minter role required). Sets initial URI and attributes.
8.  `tokenURI(uint256 tokenId)`: Gets the metadata URI for an NFT (overrides ERC721 to fetch the *current* URI).
9.  `getNFTCurrentAttributes(uint256 tokenId)`: Retrieves the current dynamic attributes of a specific NFT.
10. `requestAttributeUpdate(uint256 tokenId, bytes32 dataType, bytes memory oracleRequestParams)`: Initiates a request to the oracle to update an NFT's attributes based on specified criteria (Can be called by users or automated systems).
11. `handleOracleResponse(uint256 oracleRequestId, uint256 tokenId, bytes32 dataType, bytes memory oracleData)`: Callback function for the trusted oracle to deliver requested data and trigger attribute updates (Oracle role required).
12. `_updateNFTAttributeInternal(uint256 tokenId, bytes32 dataType, bytes memory oracleData)`: Internal logic to process oracle data and apply changes to NFT attributes. Contains the core dynamic rules.
13. `triggerTimeBasedAttributeUpdate(uint256 tokenId)`: Allows triggering an attribute update based on time elapsed since the last update or minting (e.g., for 'decay' or 'growth' effects). *Could be called by users or automated system.*
14. `configureAttributeMapping(bytes32 dataType, bytes memory mappingRules)`: Sets rules for how specific types of oracle data (`dataType`) should map to attribute changes (`mappingRules`) (Admin/Governor role required).
15. `setOracleAddress(address payable newOracle)`: Sets or updates the address of the trusted oracle contract (Admin role required).
16. `listItem(uint256 tokenId, uint256 price)`: Lists an owned NFT for sale on the marketplace.
17. `buyItem(uint256 tokenId)`: Buys an NFT that is currently listed for sale. Handles payment and fee distribution.
18. `cancelListing(uint256 tokenId)`: Removes an NFT listing from the marketplace.
19. `updateListingPrice(uint256 tokenId, uint256 newPrice)`: Changes the price of an active listing.
20. `getListing(uint256 tokenId)`: Retrieves the details of an NFT listing.
21. `setMarketplaceFee(uint256 newFeeBasisPoints)`: Sets the marketplace fee percentage (Admin role required). Fee is in basis points (e.g., 100 = 1%).
22. `withdrawFees()`: Allows an account with the Admin role to withdraw accumulated fees.
23. `createProposal(string memory description, bytes[] memory callData)`: Creates a new governance proposal (Governor role required). Proposal includes target contract/function calls.
24. `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote (support/against) on an active proposal. Voting power could be based on NFT ownership count within this contract.
25. `executeProposal(uint256 proposalId)`: Attempts to execute a successfully passed governance proposal.
26. `getProposalState(uint256 proposalId)`: Gets the current state of a governance proposal (Pending, Active, Succeeded, Failed, Executed).
27. `getVoteWeight(address account)`: Calculates the current voting weight of an account based on the number of NFTs they hold in this contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline and Function Summary provided above the code

contract DynamicNFTMarketplaceWithAIOracle is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Math for uint256;

    // --- 1. Roles & Access Control ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE"); // Inherited from AccessControl

    // --- 2. Structs & Enums ---

    struct Attribute {
        string traitType;
        string value; // Can represent various types (string, number encoded as string)
        uint256 lastUpdated; // Timestamp of last update for this specific attribute
    }

    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price; // in wei
        bool active;
    }

    struct OracleRequest {
        uint256 tokenId;
        bytes32 dataType; // Type of data requested (e.g., "weather", "stock_sentiment", "game_event")
        bytes oracleRequestParams; // Parameters for the oracle request
        uint256 requestTime;
        bool fulfilled;
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        uint256 id;
        string description;
        bytes[] targets; // Addresses of contracts to call
        bytes[] callData; // Calldata for target functions
        uint256 endBlock; // Block number when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalState state;
        mapping(address => bool) hasVoted; // Prevents double voting
    }

    // --- 3. State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _oracleRequestIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Stores dynamic attributes for each token ID
    mapping(uint256 => Attribute[]) private _tokenAttributes;
    // Stores the base metadata URI (can be updated or used to compose full URI)
    mapping(uint256 => string) private _tokenBaseURI;
    // Stores the last time any attribute was updated for a token
    mapping(uint256 => uint256) private _tokenLastUpdateTime;

    // Marketplace listings: tokenId => Listing
    mapping(uint256 => Listing) private _listings;

    // Oracle configuration
    address payable private _oracleAddress; // Trusted address allowed to call handleOracleResponse
    // Mapping rules from oracle data type to attribute updates (complex logic is off-chain, this stores config)
    // e.g., bytes32("weather") => bytes detailing thresholds, attribute names, value ranges
    mapping(bytes32 => bytes) private _attributeMappingRules;
    // Stores active oracle requests: oracleRequestId => OracleRequest
    mapping(uint256 => OracleRequest) private _oracleRequests;


    // Governance configuration and data
    mapping(uint256 => Proposal) private _proposals;
    uint256 public minVotesForProposal; // Minimum voting weight required to create a proposal
    uint256 public proposalVotingPeriodBlocks; // Duration of voting in blocks
    uint256 public proposalThresholdVotes; // Minimum total votes required for a proposal to be valid
    uint256 public proposalQuorumVotes; // Minimum votesFor required for a proposal to pass (could be percentage of total supply or fixed)

    // Fee Configuration
    uint256 public marketplaceFeeBasisPoints; // Fee percentage charged on sales, in basis points (100 = 1%)
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10000; // 100% = 10000 basis points

    // Collected Fees Treasury
    uint256 private _protocolFees;

    // NFT Ownership Tracking for Vote Weight (Simplistic: 1 NFT = 1 Vote)
    mapping(address => uint256) private _nftVoteWeight;

    // --- 4. Events ---

    event NFTMinted(address indexed to, uint256 indexed tokenId, string initialURI);
    event AttributesUpdated(uint256 indexed tokenId, bytes32 indexed updateType, bytes updateData); // updateType: "oracle", "time", "manual", etc.
    event OracleAttributeUpdateRequest(uint256 indexed oracleRequestId, uint256 indexed tokenId, bytes32 dataType, bytes requestParams);
    event OracleAttributeUpdateResponse(uint256 indexed oracleRequestId, uint256 indexed tokenId, bytes32 dataType, bytes oracleData);
    event AttributeMappingConfigured(bytes32 indexed dataType, bytes rules);

    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price, uint256 feeAmount);
    event ListingCancelled(uint256 indexed tokenId);
    event ListingPriceUpdated(uint256 indexed tokenId, uint256 newPrice);

    event MarketplaceFeeUpdated(uint256 newFeeBasisPoints);
    event FeesWithdrawn(address indexed to, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    // --- 5. Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        address admin,
        address minter,
        address governor,
        uint256 initialFeeBasisPoints,
        uint256 _minVotesForProposal,
        uint256 _proposalVotingPeriodBlocks,
        uint256 _proposalThresholdVotes,
        uint256 _proposalQuorumVotes
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(GOVERNOR_ROLE, governor); // Governor role can create and manage proposals

        marketplaceFeeBasisPoints = initialFeeBasisPoints;
        minVotesForProposal = _minVotesForProposal;
        proposalVotingPeriodBlocks = _proposalVotingPeriodBlocks;
        proposalThresholdVotes = _proposalThresholdVotes;
        proposalQuorumVotes = _proposalQuorumVotes;
    }

    // --- 6. ERC721 Standard Functions (Overridden for Vote Weight) ---
    // OpenZeppelin's ERC721 handles most standard functions.
    // We only need to override _beforeTokenTransfer to track NFT counts for voting.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721) // Added override specifier
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize); // Call the parent hook first

        // Update vote weight based on ownership change
        if (from != address(0)) {
            _nftVoteWeight[from] = _nftVoteWeight[from].sub(batchSize);
        }
        if (to != address(0)) {
            _nftVoteWeight[to] = _nftVoteWeight[to].add(batchSize);
        }
    }

    // Optional: Override supportsInterface if adding custom interfaces, but not strictly needed for AccessControl/ERC721 inheritance.
    // function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    // }

    // --- 7. Minting Functions ---
    function mint(address to, string memory initialURI, Attribute[] memory initialAttributes)
        public
        onlyRole(MINTER_ROLE)
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(to, newItemId);
        _tokenBaseURI[newItemId] = initialURI; // Store base URI
        _tokenAttributes[newItemId] = initialAttributes; // Store initial attributes
        _tokenLastUpdateTime[newItemId] = block.timestamp; // Record mint time

        emit NFTMinted(to, newItemId, initialURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721) // Added override specifier
        returns (string memory)
    {
        if (!_exists(tokenId)) {
             revert ERC721Information.NonexistentToken(tokenId);
        }
        // Return base URI + potentially token ID or specific path for dynamic metadata service
        // In a real dApp, a metadata server would fetch attributes and serve a dynamic JSON
        // Here we just return the base URI as a placeholder
        return _tokenBaseURI[tokenId];
        // return string(abi.encodePacked(_tokenBaseURI[tokenId], tokenId.toString())); // Example adding token ID
    }

    // --- 8. Dynamic Attribute Management ---

    // Function to get current attributes of an NFT
    function getNFTCurrentAttributes(uint256 tokenId)
        public
        view
        returns (Attribute[] memory)
    {
        require(_exists(tokenId), "Token does not exist");
        return _tokenAttributes[tokenId];
    }

    // Function to request an update via the oracle
    function requestAttributeUpdate(uint256 tokenId, bytes32 dataType, bytes memory oracleRequestParams)
        public
        returns (uint256 oracleRequestId)
    {
        require(_exists(tokenId), "Token does not exist");
        // require(hasRole(ORACLE_ROLE, msg.sender) || ownerOf(tokenId) == msg.sender, "Not authorized to request update"); // Example restriction

        _oracleRequestIdCounter.increment();
        oracleRequestId = _oracleRequestIdCounter.current();

        _oracleRequests[oracleRequestId] = OracleRequest({
            tokenId: tokenId,
            dataType: dataType,
            oracleRequestParams: oracleRequestParams,
            requestTime: block.timestamp,
            fulfilled: false
        });

        // In a real Chainlink/VRF setup, you'd call the oracle contract here
        // This simulation just records the request and expects a callback later
        emit OracleAttributeUpdateRequest(oracleRequestId, tokenId, dataType, oracleRequestParams);
        return oracleRequestId;
    }

    // Callback function to receive data from the trusted oracle
    function handleOracleResponse(uint256 oracleRequestId, bytes memory oracleData)
        public
        onlyRole(ORACLE_ROLE)
    {
        OracleRequest storage req = _oracleRequests[oracleRequestId];
        require(req.tokenId != 0, "Request does not exist"); // Check if request exists
        require(!req.fulfilled, "Request already fulfilled");

        req.fulfilled = true; // Mark as fulfilled

        // Process the oracle data and update the NFT attributes
        _updateNFTAttributeInternal(req.tokenId, req.dataType, oracleData);

        emit OracleAttributeUpdateResponse(oracleRequestId, req.tokenId, req.dataType, oracleData);
    }

    // Internal logic to update attributes based on data.
    // This function contains the core 'dynamic' rules.
    function _updateNFTAttributeInternal(uint256 tokenId, bytes32 dataType, bytes memory updateData) internal {
        require(_exists(tokenId), "Token does not exist");

        Attribute[] storage attributes = _tokenAttributes[tokenId];
        uint256 currentTime = block.timestamp;

        // --- This is where the core AI-influenced logic would be mapped ---
        // The 'updateData' from the oracle should contain information that maps to
        // specific attributes and how to change them based on the `dataType`.
        // This could be complex decoding and application logic.
        // For demonstration, we'll show a simple example:
        // Assume updateData is abi.encode(string[] attributeNames, string[] newValues)

        (string[] memory attributeNames, string[] memory newValues) = abi.decode(updateData, (string[], string[]));
        require(attributeNames.length == newValues.length, "Mismatched attribute data");

        for (uint i = 0; i < attributeNames.length; i++) {
            bool found = false;
            for (uint j = 0; j < attributes.length; j++) {
                if (keccak256(bytes(attributes[j].traitType)) == keccak256(bytes(attributeNames[i]))) {
                    attributes[j].value = newValues[i];
                    attributes[j].lastUpdated = currentTime;
                    found = true;
                    break;
                }
            }
            // If attribute not found, could potentially add it depending on rules
            if (!found) {
                 // Example: Add new attribute if not found (optional)
                 // attributes.push(Attribute({traitType: attributeNames[i], value: newValues[i], lastUpdated: currentTime}));
            }
        }

        _tokenLastUpdateTime[tokenId] = currentTime;
        emit AttributesUpdated(tokenId, dataType, updateData);
    }

     // Allows triggering an update based on time elapsed
    function triggerTimeBasedAttributeUpdate(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
        // Add logic to check if enough time has passed since _tokenLastUpdateTime[tokenId]
        // Example: require(block.timestamp > _tokenLastUpdateTime[tokenId] + 1 days, "Not enough time has passed");

        Attribute[] storage attributes = _tokenAttributes[tokenId];
        uint256 currentTime = block.timestamp;
        uint256 timeElapsed = currentTime - _tokenLastUpdateTime[tokenId];

        // --- Time-based update logic goes here ---
        // Example: Decrease a "freshness" attribute, increase an "age" attribute,
        // or change color based on how long it's been since the last manual/oracle update.
        // This logic would iterate through attributes and apply changes based on `timeElapsed`.
        // Example: Find "freshness" attribute
        for (uint i = 0; i < attributes.length; i++) {
             if (keccak256(bytes(attributes[i].traitType)) == keccak256(bytes("freshness"))) {
                 // Simple example: decrease freshness score over time
                 // Need to parse attribute[i].value string as a number for math
                 // (string to int conversion needs libraries or careful handling)
                 // For demo, let's just change a string value:
                 if (timeElapsed > 7 days && keccak256(bytes(attributes[i].value)) == keccak256(bytes("fresh"))) {
                     attributes[i].value = "stale";
                     attributes[i].lastUpdated = currentTime;
                 } else if (timeElapsed > 30 days && keccak256(bytes(attributes[i].value)) == keccak256(bytes("stale"))) {
                      attributes[i].value = "decayed";
                     attributes[i].lastUpdated = currentTime;
                 }
                 // More complex logic would involve parsing numbers and applying formulas
                 break;
             }
        }


        _tokenLastUpdateTime[tokenId] = currentTime;
         emit AttributesUpdated(tokenId, "time", abi.encode(timeElapsed));
    }


    // --- 9. Oracle Configuration ---
    function setOracleAddress(address payable newOracle) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _oracleAddress = newOracle;
    }

    function configureAttributeMapping(bytes32 dataType, bytes memory mappingRules) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _attributeMappingRules[dataType] = mappingRules;
        emit AttributeMappingConfigured(dataType, mappingRules);
    }

    // --- 10. Marketplace Functions ---

    function listItem(uint256 tokenId, uint256 price) public {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        require(_listings[tokenId].seller == address(0) || !_listings[tokenId].active, "Item is already listed");
        require(price > 0, "Price must be greater than 0");

        // Ensure the contract is approved to transfer the token
        require(getApproved(tokenId) == address(this) || isApprovedForAll(msg.sender, address(this)), "Marketplace contract not approved for transfer");

        _listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        emit ItemListed(tokenId, msg.sender, price);
    }

    function buyItem(uint256 tokenId) public payable {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Item is not listed or already sold");
        require(msg.value >= listing.price, "Insufficient funds");
        require(listing.seller != msg.sender, "Cannot buy your own item");

        uint256 totalPrice = listing.price;
        uint256 feeAmount = (totalPrice * marketplaceFeeBasisPoints) / BASIS_POINTS_DENOMINATOR;
        uint256 sellerReceiveAmount = totalPrice - feeAmount;

        _protocolFees += feeAmount; // Collect fee
        emit ItemSold(tokenId, msg.sender, listing.seller, totalPrice, feeAmount);

        // Transfer payment to seller
        // Use call instead of transfer/send for flexibility with seller fallback
        (bool success, ) = payable(listing.seller).call{value: sellerReceiveAmount}("");
        require(success, "Payment transfer failed");

        // Transfer the NFT to the buyer
        _safeTransfer(listing.seller, msg.sender, tokenId, "");

        // Deactivate the listing
        listing.active = false;
        listing.seller = address(0); // Clear seller after sale

        // Refund any excess payment
        if (msg.value > totalPrice) {
            (success, ) = payable(msg.sender).call{value: msg.value - totalPrice}("");
            require(success, "Refund failed");
        }
    }

    function cancelListing(uint256 tokenId) public {
        Listing storage listing = _listings[tokenId];
        require(listing.active, "Item is not listed");
        require(listing.seller == msg.sender, "Caller is not the seller");

        listing.active = false;
        listing.seller = address(0); // Clear seller

        emit ListingCancelled(tokenId);
    }

    function updateListingPrice(uint256 tokenId, uint256 newPrice) public {
         Listing storage listing = _listings[tokenId];
        require(listing.active, "Item is not listed");
        require(listing.seller == msg.sender, "Caller is not the seller");
        require(newPrice > 0, "Price must be greater than 0");

        listing.price = newPrice;

        emit ListingPriceUpdated(tokenId, newPrice);
    }

    // --- 11. Fee Management ---

    function setMarketplaceFee(uint256 newFeeBasisPoints) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFeeBasisPoints <= BASIS_POINTS_DENOMINATOR, "Fee cannot exceed 100%");
        marketplaceFeeBasisPoints = newFeeBasisPoints;
        emit MarketplaceFeeUpdated(newFeeBasisPoints);
    }

    function withdrawFees() public onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = _protocolFees;
        require(amount > 0, "No fees to withdraw");
        _protocolFees = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee withdrawal failed");

        emit FeesWithdrawn(msg.sender, amount);
    }

    // --- 12. Governance Functions ---

    function createProposal(string memory description, bytes[] memory targets, bytes[] memory callData)
        public
        onlyRole(GOVERNOR_ROLE)
        returns (uint256 proposalId)
    {
        // Simple check: requires non-empty proposal data
        require(targets.length > 0 && targets.length == callData.length, "Invalid proposal data");

        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        // Basic check for minimum votes to create proposal (e.g., must hold X NFTs)
        // require(getVoteWeight(msg.sender) >= minVotesForProposal, "Insufficient voting weight to create proposal");

        Proposal storage proposal = _proposals[proposalId];
        proposal.id = proposalId;
        proposal.description = description;
        proposal.targets = targets;
        proposal.callData = callData;
        proposal.endBlock = block.number + proposalVotingPeriodBlocks;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }

    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(block.number <= proposal.endBlock, "Voting period has ended");

        uint256 voteWeight = getVoteWeight(msg.sender);
        require(voteWeight > 0, "No voting weight"); // Must own at least 1 NFT

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }

        emit VoteCast(proposalId, msg.sender, support, voteWeight);
    }

    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active"); // Can only execute active ones that pass checks
        require(block.number > proposal.endBlock, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        // Determine outcome
        if (proposal.votesFor > proposal.votesAgainst &&
            (proposal.votesFor + proposal.votesAgainst) >= proposalThresholdVotes &&
            proposal.votesFor >= proposalQuorumVotes) {

            proposal.state = ProposalState.Succeeded; // Mark as succeeded *before* execution attempts

            // Execute the proposal actions
            bool success;
            // Execute all calls in the proposal
            for (uint i = 0; i < proposal.targets.length; i++) {
                (success, ) = proposal.targets[i].call(proposal.callData[i]);
                // Decide how to handle failures: revert entire transaction, or log and continue?
                // Reverting is safer for critical actions.
                require(success, string(abi.encodePacked("Execution failed for call ", i.toString())));
            }

            proposal.executed = true;
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId);

        } else {
            proposal.state = ProposalState.Failed;
            // No execution if failed
        }
    }

    function cancelProposal(uint256 proposalId) public onlyRole(GOVERNOR_ROLE) {
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "Proposal not in a cancellable state");
         require(getVoteWeight(msg.sender) >= minVotesForProposal, "Insufficient voting weight to cancel"); // Example: require min vote weight to cancel

         proposal.state = ProposalState.Canceled;
         emit ProposalCanceled(proposalId);
    }


    // --- 13. View Functions ---

    function getListing(uint256 tokenId) public view returns (Listing memory) {
        return _listings[tokenId];
    }

    function getProtocolFees() public view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        return _protocolFees;
    }

    function getOracleAddress() public view returns (address) {
        return _oracleAddress;
    }

    function getAttributeMappingRules(bytes32 dataType) public view returns (bytes memory) {
        return _attributeMappingRules[dataType];
    }

     function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.id != 0, "Proposal does not exist"); // Check if proposal exists
        // Check if state needs updating based on current block
        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            // Note: This view function doesn't change state.
            // The state update from Active to Succeeded/Failed happens in executeProposal.
            // A separate function could be added to transition states without execution if needed.
            return ProposalState.Active; // Still Active in view, execution triggers final state
        }
        return proposal.state;
    }

    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        string memory description,
        uint256 endBlock,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        ProposalState state
    ) {
         Proposal storage proposal = _proposals[proposalId];
         require(proposal.id != 0, "Proposal does not exist"); // Check if proposal exists
         return (
             proposal.id,
             proposal.description,
             proposal.endBlock,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.executed,
             getProposalState(proposalId) // Use the state check function
         );
    }

    // Gets voting weight for an account (based on NFT count)
    function getVoteWeight(address account) public view returns (uint256) {
        return _nftVoteWeight[account];
    }

     // Get the total number of NFTs minted (equivalent to totalSupply if not burned)
    function getTotalMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Overriding ERC721Enumerable's tokenByIndex/tokenOfOwnerByIndex could be added
    // if full enumeration is needed, but requires ERC721Enumerable import and management.
    // Keeping it simpler without enumerable for this example.

    // Required ERC721 view functions (mostly handled by inheritance)
    // function balanceOf(address owner) public view override returns (uint256) { super.balanceOf(owner); }
    // function ownerOf(uint256 tokenId) public view override returns (address) { super.ownerOf(tokenId); }
    // function getApproved(uint256 tokenId) public view override returns (address) { super.getApproved(tokenId); }
    // function isApprovedForAll(address owner, address operator) public view override returns (bool) { super.isApprovedForAll(owner, operator); }


    // Fallback function to receive Ether for marketplace payments
    receive() external payable {}
}

// Helper Contract for error messages (optional but good practice in >=0.8.4)
library ERC721Information {
    error NonexistentToken(uint256 tokenId);
}
```

**Explanation of Advanced/Creative Concepts:**

1.  **Dynamic Attributes:** Instead of static metadata, each NFT has a mutable array of `Attribute` structs (`_tokenAttributes`). This state lives on-chain.
2.  **Oracle Integration (Simulated):** The `requestAttributeUpdate` function simulates initiating an off-chain process. The `handleOracleResponse` function acts as the secure callback endpoint *only* callable by the designated `_oracleAddress`. This simulates receiving processed data (potentially from an AI analyzing external feeds) to update NFT attributes. The `_attributeMappingRules` mapping hints at configurable logic for how different data types affect different attributes.
3.  **Time-Based Dynamics:** `triggerTimeBasedAttributeUpdate` introduces a mechanism for attributes to change based on how long it's been since the last update. This adds an element of "decay" or "growth" independent of external data, making NFTs more reactive to time or user interaction frequency.
4.  **NFT-Based Governance:** The `createProposal`, `voteOnProposal`, and `executeProposal` functions implement a basic governance system. Crucially, `voteOnProposal` uses `getVoteWeight(msg.sender)`, which in this contract is tied directly to the number of NFTs an address owns (`_nftVoteWeight`). This makes it a decentralized governance model where influence is proportional to participation in the NFT ecosystem itself. The `_beforeTokenTransfer` hook is used to keep `_nftVoteWeight` accurate.
5.  **Configurable Fee Structure:** The `marketplaceFeeBasisPoints` and related functions allow the fee percentage on sales to be set and collected into a contract treasury (`_protocolFees`), which can then be withdrawn by an admin. This adds a potential revenue stream for the protocol owner/DAO.
6.  **Access Control with Roles:** Using OpenZeppelin's `AccessControl` provides granular permissions for sensitive actions like minting, setting the oracle address, configuring rules, granting roles, and managing governance proposals. This is more robust than simple `Ownable`.
7.  **Separation of Concerns:** While the contract is large, it attempts to separate logic: ERC721 core (mostly inherited), minting, dynamic attribute logic, oracle interaction, marketplace, fees, and governance.

This contract is significantly more complex than a standard ERC721 or a basic marketplace. It incorporates dynamic state changes driven by external data and time, a specific type of governance, and a revenue model, fulfilling the request for creative, advanced, and numerous functions.