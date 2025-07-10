Okay, let's design a smart contract called `QuantumEstate` that represents fractionalized, time-sliced, dynamic, and potentially "entangled" digital real estate parcels, incorporating governance and yield mechanics.

This contract will combine elements of ERC721 (for the parcels), internal tracking of fractional shares, time-based access rights, dynamic attributes that can change based on triggers (simulating external conditions or "observation"), and simulated "entanglement" between parcels. It will *not* inherit a full standard library like OpenZeppelin directly to ensure uniqueness in implementation details, but will define necessary interfaces or minimal internal helper functions where needed (like basic ownership tracking for ERC721 compatibility concepts).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEstate
 * @dev An advanced smart contract for managing digital or tokenized real estate parcels.
 *      It combines concepts of ERC721 ownership, internal fractional shares, time-based access,
 *      dynamic attributes, simulated 'entanglement' between parcels, yield distribution, and basic governance.
 *      The 'Quantum' aspect refers to dynamic, non-linear state changes and potential interdependencies.
 */

/**
 * OUTLINE:
 * 1.  Contract Information & SPDX License
 * 2.  Error Definitions
 * 3.  Event Definitions
 * 4.  Struct Definitions (Parcel, TimeSlice, Proposal)
 * 5.  State Variables (Mapping parcels, shares, time slices, entanglement, yield, governance, roles)
 * 6.  Basic ERC721-like Internal Implementations (for token IDs, ownership, approvals - minimally implemented to avoid direct open-source duplication)
 * 7.  Access Control (Owner, Managers)
 * 8.  Constructor
 * 9.  Core Parcel Management Functions (Minting, Metadata, Burning - careful with burning)
 * 10. Dynamic Attributes & Quantum Simulation Functions (Setting, Getting, Triggering changes)
 * 11. Fractional Shares Management Functions (Issuing, Transferring, Getting balance, Listing/Buying)
 * 12. Time-Slice / Rental Management Functions (Adding, Booking, Releasing, Getting details)
 * 13. Entanglement Management Functions (Creating, Breaking links, Propagating effects)
 * 14. Yield / Distribution Functions (Collecting parcel yield, Claiming pooled yield)
 * 15. Governance / Proposal System Functions (Proposing, Voting, Executing)
 * 16. Utility / Getters (Count, Existence, Approvals, Balances, Specific details)
 */

/**
 * FUNCTION SUMMARY (Alphabetical Order - counts >= 20 custom external functions):
 *
 *  1. addTimeSliceListing(uint256 _parcelId, uint64 _startTime, uint64 _endTime, uint256 _pricePerSlice): List a specific time range of a parcel for rent/use.
 *  2. bookTimeSlice(uint256 _parcelId, uint256 _sliceId): Book/rent a specific time slice listing by its ID. Requires payment (simplified).
 *  3. breakEntanglementLink(uint256 _parcelId1, uint256 _parcelId2): Remove an entanglement link between two parcels.
 *  4. buyFractionalShares(uint256 _parcelId, address _from, uint256 _amount): Purchase listed fractional shares from another user.
 *  5. checkTimeSliceAvailability(uint256 _parcelId, uint64 _checkStartTime, uint64 _checkEndTime): Check if a specific time range overlaps with booked slices. (View function)
 *  6. claimPooledYield(): Claim accumulated yield from the pooled yield fund based on fractional share holdings.
 *  7. collectParcelYield(uint256 _parcelId): Allow the primary owner (or significant shareholder) to collect yield earned by a specific parcel (e.g., from time slice bookings).
 *  8. createEntanglementLink(uint256 _parcelId1, uint256 _parcelId2): Create a simulated 'entanglement' link between two distinct parcels.
 *  9. executeProposalIfPassed(uint256 _proposalId): Attempt to execute a proposal if it has passed its voting period and met quorum/threshold.
 * 10. getEntangledParcels(uint256 _parcelId): Get a list of parcels entangled with a given parcel. (View function)
 * 11. getFractionalSharesBalance(uint256 _parcelId, address _owner): Get the fractional share balance for a specific parcel held by an address. (View function)
 * 12. getParcelDynamicAttribute(uint256 _parcelId, string calldata _attributeName): Retrieve the current value of a dynamic attribute for a parcel. (View function)
 * 13. getParcelTimeSlices(uint256 _parcelId): Get a list of all time slice IDs for a parcel. (View function - returns IDs, details require `getTimeSliceDetails`)
 * 14. getProposalDetails(uint256 _proposalId): Retrieve the details of a specific governance proposal. (View function)
 * 15. getTimeSliceDetails(uint256 _parcelId, uint256 _sliceId): Get the full details of a specific time slice for a parcel. (View function)
 * 16. grantManagerRole(address _manager): Grant manager permissions to an address.
 * 17. issueFractionalShares(uint256 _parcelId, address _to, uint256 _amount): Issue new fractional shares for a parcel to an address. (Requires permissions)
 * 18. listFractionalSharesForSale(uint256 _parcelId, uint256 _amount, uint256 _pricePerShare): List fractional shares of a parcel for sale.
 * 19. mintParcel(address _to, string calldata _baseMetadataURI): Mint a new Quantum Estate parcel (ERC721 token) and assign it to an address.
 * 20. propagateEntanglementEffect(uint256 _sourceParcelId): Simulate the propagation of a dynamic state change effect through entangled links.
 * 21. proposeConfigChange(string calldata _description, bytes calldata _data): Create a new governance proposal to change a contract configuration (e.g., fees, parameters). Requires Manager role.
 * 22. redeemFractionalShares(uint256 _parcelId, uint256 _amount): Attempt to redeem fractional shares for potential underlying value or claim process (abstract concept here).
 * 23. releaseTimeSlice(uint256 _parcelId, uint256 _sliceId): Release a time slice (e.g., if booking expires or is canceled).
 * 24. resolveProbabilisticOutcome(uint256 _parcelId): Simulate the 'collapse' of a probabilistic state, potentially setting a dynamic attribute based on (simulated) external factors or block data.
 * 25. revokeManagerRole(address _manager): Revoke manager permissions from an address.
 * 26. setParcelBaseMetadataURI(uint256 _parcelId, string calldata _uri): Set the static base metadata URI for a parcel.
 * 27. setParcelDynamicAttribute(uint256 _parcelId, string calldata _attributeName, string calldata _attributeValue): Set or update a specific dynamic attribute for a parcel. Requires permissions/triggers.
 * 28. transferFractionalShares(uint256 _parcelId, address _to, uint256 _amount): Transfer internal fractional shares of a parcel to another address.
 * 29. triggerDynamicStateChange(uint256 _parcelId, string calldata _dataSource, string calldata _condition): Manually trigger a potential dynamic state change based on simulated external data/condition.
 * 30. voteOnProposal(uint256 _proposalId, bool _support): Cast a vote on an active governance proposal. Voting weight could be based on fractional shares/parcels held.
 *
 * Note: Basic ERC721 functions like `ownerOf`, `balanceOf`, `transferFrom`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll` are implied by the ERC721 concept but not counted towards the 20+ *custom* functions to avoid direct duplication of standard interface methods. Minimal internal helpers might be implemented for clarity.
 */

// Minimal ERC165 and ERC721 interfaces/helpers for type compatibility and core concepts
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 /* is IERC165 */ {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract QuantumEstate is IERC721, IERC165 {

    // --- Error Definitions ---
    error NotManager();
    error NotParcelOwnerOrManager();
    error NotApprovedOrOwner();
    error ParcelDoesNotExist(uint256 _parcelId);
    error ParcelAlreadyExists(uint256 _parcelId);
    error InvalidAddressZero();
    error InvalidParcelId();
    error InsufficientFractionalShares(address _owner, uint256 _parcelId, uint256 _required, uint256 _available);
    error ZeroAmount();
    error TimeSliceOverlap();
    error TimeSliceDoesNotExist(uint256 _parcelId, uint256 _sliceId);
    error TimeSliceAlreadyBooked(uint256 _parcelId, uint256 _sliceId);
    error TimeSliceNotBooked(uint256 _parcelId, uint256 _sliceId);
    error TimeSliceExpired();
    error EntanglementExists(uint256 _parcelId1, uint256 _parcelId2);
    error NoEntanglementExists(uint256 _parcelId1, uint256 _parcelId2);
    error CannotEntangleSelf();
    error ProposalDoesNotExist(uint256 _proposalId);
    error ProposalVotingPeriodActive(uint256 _proposalId);
    error ProposalAlreadyExecuted(uint256 _proposalId);
    error ProposalVotingPeriodEnded(uint256 _proposalId);
    error VoteAlreadyCast(uint256 _proposalId, address _voter);
    error InsufficientVotesToExecute(uint256 _proposalId);
    error ExecutionFailed(uint256 _proposalId);
    error FractionalSharesNotForSale(uint256 _parcelId, address _seller);
    error InsufficientFunds();
    error CallableOnlyBySelfOrManager(); // For internal calls or specific triggers

    // --- Event Definitions ---
    event ParcelMinted(uint256 indexed parcelId, address indexed owner, string uri);
    event ParcelBurned(uint256 indexed parcelId); // Care needed if implementing burn
    event DynamicAttributeUpdated(uint256 indexed parcelId, string attributeName, string attributeValue);
    event ProbabilisticOutcomeResolved(uint256 indexed parcelId, string resolvedAttribute, string resolvedValue, bytes32 seed);
    event FractionalSharesIssued(uint256 indexed parcelId, address indexed to, uint256 amount);
    event FractionalSharesTransferred(uint256 indexed parcelId, address indexed from, address indexed to, uint256 amount);
    event FractionalSharesListed(uint256 indexed parcelId, address indexed seller, uint256 amount, uint256 pricePerShare);
    event FractionalSharesPurchased(uint256 indexed parcelId, address indexed seller, address indexed buyer, uint256 amount, uint256 totalPrice);
    event TimeSliceListed(uint256 indexed parcelId, uint256 indexed sliceId, uint64 startTime, uint64 endTime, uint256 price);
    event TimeSliceBooked(uint256 indexed parcelId, uint256 indexed sliceId, address indexed user);
    event TimeSliceReleased(uint256 indexed parcelId, uint256 indexed sliceId);
    event EntanglementCreated(uint256 indexed parcelId1, uint256 indexed parcelId2);
    event EntanglementBroken(uint256 indexed parcelId1, uint256 indexed parcelId2);
    event YieldCollected(uint256 indexed parcelId, address indexed collector, uint256 amount);
    event PooledYieldClaimed(address indexed claimant, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ManagerGranted(address indexed manager);
    event ManagerRevoked(address indexed manager);
    event ConfigParameterChanged(bytes32 indexed paramHash, bytes newValue); // Generic event for executed config changes

    // --- Struct Definitions ---
    struct Parcel {
        string baseMetadataURI; // Static part of URI
        mapping(string => string) dynamicAttributes; // Dynamic, changing attributes
        uint256 totalFractionalShares; // Total shares issued for this parcel
        uint256 nextTimeSliceId; // Counter for unique time slices per parcel
        mapping(uint256 => TimeSlice) timeSlices; // Mapping of slice ID to TimeSlice struct
        uint256 accumulatedYield; // Yield earned by this parcel
        mapping(uint256 => bool) entangledWith; // Simplified mapping to other parcel IDs
    }

    struct TimeSlice {
        uint64 startTime; // Start timestamp (seconds)
        uint64 endTime;   // End timestamp (seconds)
        address currentUser; // Address currently holding/booked (address(0) if available)
        uint256 price;    // Price to book this slice (simplified, token assumed ETH or internal)
        bool isBooked;    // Flag to indicate if currently booked
    }

    struct Proposal {
        string description; // Description of the proposal
        bytes data;         // Data to execute if proposal passes (e.g., function call + params encoded)
        uint256 creationTime; // Timestamp of creation
        uint256 votingPeriodEnd; // Timestamp when voting ends
        mapping(address => bool) hasVoted; // Track who has voted
        uint256 votesFor;   // Total 'for' votes (can be weighted by stake)
        uint256 votesAgainst; // Total 'against' votes (can be weighted)
        bool executed;      // Flag if the proposal has been executed
        bool passed;        // Flag if the proposal passed (evaluated after voting period)
        uint256 proposerVoteWeight; // Weight assigned to the proposer's vote initially (simplified)
    }

    // --- State Variables ---
    address private _owner; // Contract owner (can be a multisig or DAO contract)
    mapping(address => bool) private _managers; // Addresses with manager privileges

    // Basic ERC721-like state
    mapping(uint256 => address) private _tokenOwners; // Mapping token ID to owner address
    mapping(address => uint256) private _balanceOf;   // Mapping owner address to number of tokens owned
    mapping(uint256 => address) private _tokenApprovals; // Mapping token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Mapping owner address to operator address to approval status
    uint256 private _nextTokenId; // Counter for minting new token IDs

    // Parcel Data
    mapping(uint256 => Parcel) private _parcels;
    mapping(uint256 => bool) private _parcelExists; // To efficiently check if a parcel ID is valid

    // Fractional Share Data: parcelId -> ownerAddress -> amount
    mapping(uint256 => mapping(address => uint256)) private _fractionalShareHoldings;
    // Fractional Share Sales Listings: parcelId -> sellerAddress -> {amount, pricePerShare}
    mapping(uint256 => mapping(address => uint256)) private _fractionalSharesForSaleAmount;
    mapping(uint256 => mapping(address => uint256)) private _fractionalSharesForSalePrice;

    // Pooled Yield Data (Simplified: ETH held in contract to be claimed)
    uint256 private _pooledYield;

    // Governance Data
    uint256 private _nextProposalId;
    mapping(uint256 => Proposal) private _proposals;
    uint256 public votingPeriodDuration = 7 days; // Default voting period
    uint256 public proposalExecutionGracePeriod = 1 days; // Time after voting ends execution is possible

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotManager(); // Using NotManager as a generic access error for owner/managers
        _;
    }

    modifier onlyManager() {
        if (!_managers[msg.sender] && msg.sender != _owner) revert NotManager();
        _;
    }

    modifier onlyParcelOwner(uint256 _parcelId) {
        if (_tokenOwners[_parcelId] != msg.sender && msg.sender != _owner && !_managers[msg.sender]) revert NotParcelOwnerOrManager();
        _;
    }

    modifier parcelExists(uint256 _parcelId) {
        if (!_parcelExists[_parcelId]) revert ParcelDoesNotExist(_parcelId);
        _;
    }

    // --- Basic ERC721-like Internal Helpers (minimal implementation) ---
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _parcelExists[tokenId];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = _tokenOwners[tokenId];
        if (owner == address(0)) revert InvalidParcelId(); // Or specific DoesNotExist
        return owner;
    }

    function _safeMint(address to, uint256 tokenId, string calldata uri) internal {
        if (to == address(0)) revert InvalidAddressZero();
        if (_parcelExists[tokenId]) revert ParcelAlreadyExists(tokenId);

        _tokenOwners[tokenId] = to;
        _balanceOf[to]++;
        _parcelExists[tokenId] = true;
        _parcels[tokenId].baseMetadataURI = uri;
        _parcels[tokenId].nextTimeSliceId = 0; // Initialize slice counter

        emit Transfer(address(0), to, tokenId);
        emit ParcelMinted(tokenId, to, uri);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (_tokenOwners[tokenId] != from) revert NotParcelOwnerOrManager(); // More specific error could be used
        if (to == address(0)) revert InvalidAddressZero();
        if (!_exists(tokenId)) revert ParcelDoesNotExist(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        _balanceOf[from]--;
        _balanceOf[to]++;
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    // --- Constructor ---
    constructor(address initialOwner) {
        if (initialOwner == address(0)) revert InvalidAddressZero();
        _owner = initialOwner;
        _managers[initialOwner] = true; // Owner is also a manager by default
    }

    // --- ERC165 Support ---
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        // ERC165 interface ID: 0x01ffc9a7
        // ERC721 interface ID: 0x80ac58cd
        // ERC721Metadata interface ID: 0x5b5e139f (Simplified metadata support)
        return interfaceId == 0x01ffc9a7 ||
               interfaceId == 0x80ac58cd ||
               interfaceId == 0x5b5e139f;
    }

    // --- Basic ERC721 Getters (External) ---
    function ownerOf(uint256 tokenId) external view override returns (address) {
        return _ownerOf(tokenId);
    }

    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) revert InvalidAddressZero();
        return _balanceOf[owner];
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
         if (!_exists(tokenId)) revert ParcelDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- Basic ERC721 Transfer/Approval (External - minimal implementation) ---
    function approve(address to, uint256 tokenId) external override {
        address owner = _ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotApprovedOrOwner();
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (_ownerOf(tokenId) != from) revert NotParcelOwnerOrManager(); // More specific error
        if (msg.sender != from && !isApprovedForAll(from, msg.sender) && _tokenApprovals[tokenId] != msg.sender) revert NotApprovedOrOwner();
        _transfer(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) external override {
         safeTransferFrom(from, to, tokenId, "");
     }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        transferFrom(from, to, tokenId); // Use internal _transfer
        // Basic ERC721Receiver check (simplified, no interface check)
        if (to.code.length > 0) {
             // This is a simplified check. A full ERC721 implementation would call
             // to.onERC721Received(msg.sender, from, tokenId, data)
             // and check the return value. Skipping for custom function count focus.
        }
    }

    // --- Access Control Functions ---
    function isManager(address _addr) public view returns (bool) {
        return _managers[_addr];
    }

    // @dev Grant manager permissions
    // @param _manager The address to grant manager permissions to.
    function grantManagerRole(address _manager) external onlyOwner {
        if (_manager == address(0)) revert InvalidAddressZero();
        _managers[_manager] = true;
        emit ManagerGranted(_manager);
    }

    // @dev Revoke manager permissions
    // @param _manager The address to revoke manager permissions from.
    function revokeManagerRole(address _manager) external onlyOwner {
        if (_manager == address(0)) revert InvalidAddressZero();
        // Prevent revoking owner's manager role via this function if owner is manager
        if (_manager == _owner) revert NotManager(); // Or specific error
        _managers[_manager] = false;
        emit ManagerRevoked(_manager);
    }

    // --- 9. Core Parcel Management Functions ---

    // @dev Mint a new Quantum Estate parcel (ERC721 token).
    // @param _to The address to mint the parcel to.
    // @param _baseMetadataURI The static base metadata URI for the parcel.
    function mintParcel(address _to, string calldata _baseMetadataURI) external onlyManager returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(_to, newTokenId, _baseMetadataURI);
        // Initialize parcel-specific data structures
        _parcels[newTokenId].totalFractionalShares = 0; // Initially no fractional shares
        _parcels[newTokenId].accumulatedYield = 0;

        return newTokenId;
    }

    // @dev Set the static base metadata URI for a parcel.
    // @param _parcelId The ID of the parcel.
    // @param _uri The new base metadata URI.
    function setParcelBaseMetadataURI(uint256 _parcelId, string calldata _uri) external onlyParcelOwner(_parcelId) parcelExists(_parcelId) {
        _parcels[_parcelId].baseMetadataURI = _uri;
        // Consider emitting a Metadata Update event if desired
    }

    // Note: No explicit burn function implemented to keep it simpler and safer.
    // ERC721 `_burn` internal function would be needed if burning is desired.

    // --- 10. Dynamic Attributes & Quantum Simulation Functions ---

    // @dev Set or update a specific dynamic attribute for a parcel.
    //      Requires parcel owner or manager permissions. Can represent a state change.
    // @param _parcelId The ID of the parcel.
    // @param _attributeName The name of the dynamic attribute (e.g., "weather", "status", "quantumState").
    // @param _attributeValue The new value for the attribute.
    function setParcelDynamicAttribute(uint256 _parcelId, string calldata _attributeName, string calldata _attributeValue) external onlyParcelOwner(_parcelId) parcelExists(_parcelId) {
         _parcels[_parcelId].dynamicAttributes[_attributeName] = _attributeValue;
         emit DynamicAttributeUpdated(_parcelId, _attributeName, _attributeValue);
    }

    // @dev Retrieve the current value of a dynamic attribute for a parcel.
    // @param _parcelId The ID of the parcel.
    // @param _attributeName The name of the dynamic attribute.
    // @return The current value of the attribute.
    function getParcelDynamicAttribute(uint256 _parcelId, string calldata _attributeName) external view parcelExists(_parcelId) returns (string memory) {
        return _parcels[_parcelId].dynamicAttributes[_attributeName];
    }

    // @dev Manually trigger a potential dynamic state change based on simulated external data/condition.
    //      This function simulates receiving input from an oracle or external system.
    //      Could involve complex internal logic changing multiple attributes.
    //      Requires Manager role to simulate external trigger.
    // @param _parcelId The ID of the parcel to trigger the change for.
    // @param _dataSource A string representing the source of the trigger (e.g., "weather_oracle", "game_event").
    // @param _condition A string representing the condition met (e.g., "rain", "player_entered", "high_pollution").
    function triggerDynamicStateChange(uint256 _parcelId, string calldata _dataSource, string calldata _condition) external onlyManager parcelExists(_parcelId) {
        // ### SIMULATION of Dynamic Logic ###
        // In a real contract, this might read from a Chainlink oracle, check internal state,
        // or interact with another contract. Here, we simulate by changing an attribute
        // based on the input strings.

        string memory currentAttribute = _parcels[_parcelId].dynamicAttributes["state"];
        string memory newState = currentAttribute; // Default to no change

        // Example: Simulate state changes based on dataSource and condition
        if (keccak256(abi.encodePacked(_dataSource)) == keccak256(abi.encodePacked("weather_oracle"))) {
            if (keccak256(abi.encodePacked(_condition)) == keccak256(abi.encodePacked("rain"))) {
                 newState = "wet";
            } else if (keccak256(abi.encodePacked(_condition)) == keccak256(abi.encodePacked("sun"))) {
                 newState = "dry";
            }
        } else if (keccak256(abi.encodePacked(_dataSource)) == keccak256(abi.encodePacked("user_interaction"))) {
             if (keccak256(abi.encodePacked(_condition)) == keccak256(abi.encodePacked("activated"))) {
                 newState = "active";
             } else if (keccak256(abi.encodePacked(_condition)) == keccak256(abi.encodePacked("deactivated"))) {
                 newState = "inactive";
             }
        }

        if (keccak256(abi.encodePacked(newState)) != keccak256(abi.encodePacked(currentAttribute))) {
            _parcels[_parcelId].dynamicAttributes["state"] = newState;
            emit DynamicAttributeUpdated(_parcelId, "state", newState);

            // Optionally trigger entanglement effect propagation
            propagateEntanglementEffect(_parcelId);
        }
         // ### END SIMULATION ###
    }

     // @dev Simulate the 'collapse' of a probabilistic state, potentially setting a dynamic attribute.
     //      This uses block data as a pseudo-random seed for the simulation.
     //      Represents a 'quantum observation' analogue.
     // @param _parcelId The ID of the parcel.
     function resolveProbabilisticOutcome(uint256 _parcelId) external parcelExists(_parcelId) onlyParcelOwner(_parcelId) { // Or onlyCallableBySelfOrManager
         // ### SIMULATION of Probabilistic Resolution ###
         // Use block hash and timestamp for a pseudo-random seed on EVM
         bytes32 seed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, _parcelId, msg.sender));

         // Example: Resolve a 'quantumState' attribute
         string memory attributeName = "quantumState";
         string memory currentValue = _parcels[_parcelId].dynamicAttributes[attributeName];

         // Simulate a 50/50 chance outcome based on the seed
         // In a real complex scenario, this could involve multiple possible outcomes
         string memory resolvedValue;
         if (uint256(seed) % 2 == 0) {
             resolvedValue = "State A";
         } else {
             resolvedValue = "State B";
         }

         // Only update if the state actually changes (though in quantum analogy, observation might change it regardless)
         if (keccak256(abi.encodePacked(resolvedValue)) != keccak256(abi.encodePacked(currentValue))) {
             _parcels[_parcelId].dynamicAttributes[attributeName] = resolvedValue;
             emit DynamicAttributeUpdated(_parcelId, attributeName, resolvedValue);
             emit ProbabilisticOutcomeResolved(_parcelId, attributeName, resolvedValue, seed);

             // Optionally trigger entanglement effect propagation
             propagateEntanglementEffect(_parcelId);
         }
          // ### END SIMULATION ###
     }


    // --- 11. Fractional Shares Management Functions ---

    // @dev Issue new fractional shares for a parcel to an address.
    //      Increases the total supply of shares for that parcel. Requires Manager role.
    // @param _parcelId The ID of the parcel.
    // @param _to The address to issue shares to.
    // @param _amount The number of shares to issue.
    function issueFractionalShares(uint256 _parcelId, address _to, uint256 _amount) external onlyManager parcelExists(_parcelId) {
        if (_to == address(0)) revert InvalidAddressZero();
        if (_amount == 0) revert ZeroAmount();

        _fractionalShareHoldings[_parcelId][_to] += _amount;
        _parcels[_parcelId].totalFractionalShares += _amount;

        emit FractionalSharesIssued(_parcelId, _to, _amount);
    }

    // @dev Transfer internal fractional shares of a parcel to another address.
    // @param _parcelId The ID of the parcel.
    // @param _to The address to transfer shares to.
    // @param _amount The number of shares to transfer.
    function transferFractionalShares(uint256 _parcelId, address _to, uint256 _amount) external parcelExists(_parcelId) {
        if (_to == address(0)) revert InvalidAddressZero();
        if (_amount == 0) revert ZeroAmount();
        if (_fractionalShareHoldings[_parcelId][msg.sender] < _amount)
            revert InsufficientFractionalShares(msg.sender, _parcelId, _amount, _fractionalShareHoldings[_parcelId][msg.sender]);

        _fractionalShareHoldings[_parcelId][msg.sender] -= _amount;
        _fractionalShareHoldings[_parcelId][_to] += _amount;

        emit FractionalSharesTransferred(_parcelId, msg.sender, _to, _amount);
    }

    // @dev Get the fractional share balance for a specific parcel held by an address.
    // @param _parcelId The ID of the parcel.
    // @param _owner The address whose balance to check.
    // @return The number of fractional shares held.
    function getFractionalSharesBalance(uint256 _parcelId, address _owner) external view parcelExists(_parcelId) returns (uint256) {
        return _fractionalShareHoldings[_parcelId][_owner];
    }

    // @dev Attempt to redeem fractional shares for potential underlying value or claim process.
    //      This is an abstract concept. In a real system, this might trigger a sale,
    //      allow claiming a portion of an asset, or interact with a redemption pool.
    //      Here it primarily serves to 'burn' internal shares. Requires shares balance.
    // @param _parcelId The ID of the parcel.
    // @param _amount The number of shares to redeem.
    function redeemFractionalShares(uint256 _parcelId, uint256 _amount) external parcelExists(_parcelId) {
        if (_amount == 0) revert ZeroAmount();
         if (_fractionalShareHoldings[_parcelId][msg.sender] < _amount)
            revert InsufficientFractionalShares(msg.sender, _parcelId, _amount, _fractionalShareHoldings[_parcelId][msg.sender]);

        _fractionalShareHoldings[_parcelId][msg.sender] -= _amount;
        _parcels[_parcelId].totalFractionalShares -= _amount; // Assuming redemption decreases total supply

        // ### SIMULATION of Redemption Effect ###
        // Here, we just emit an event. In a real scenario, this might
        // transfer tokens, trigger a payout, or burn actual underlying assets.
        // ### END SIMULATION ###

        // Emit a generic event or a specific Redemption event if defined
        emit FractionalSharesTransferred(_parcelId, msg.sender, address(0), _amount); // Transfer to address(0) implies burn/redemption
    }

    // @dev List fractional shares of a parcel for sale.
    //      Allows a user to list their internal shares on an internal marketplace.
    // @param _parcelId The ID of the parcel.
    // @param _amount The number of shares to list.
    // @param _pricePerShare The price per share (in contract's payment token, e.g., ETH).
    function listFractionalSharesForSale(uint256 _parcelId, uint256 _amount, uint256 _pricePerShare) external parcelExists(_parcelId) {
        if (_amount == 0) revert ZeroAmount();
        if (_fractionalShareHoldings[_parcelId][msg.sender] < _amount)
             revert InsufficientFractionalShares(msg.sender, _parcelId, _amount, _fractionalShareHoldings[_parcelId][msg.sender]);

        _fractionalSharesForSaleAmount[_parcelId][msg.sender] = _amount;
        _fractionalSharesForSalePrice[_parcelId][msg.sender] = _pricePerShare;

        emit FractionalSharesListed(_parcelId, msg.sender, _amount, _pricePerShare);
    }

    // @dev Buy listed fractional shares from another user.
    //      Requires sending the total payment along with the transaction.
    // @param _parcelId The ID of the parcel.
    // @param _from The address selling the shares.
    // @param _amount The number of shares to buy.
    function buyFractionalShares(uint256 _parcelId, address _from, uint256 _amount) external payable parcelExists(_parcelId) {
        if (_amount == 0) revert ZeroAmount();
        uint256 listedAmount = _fractionalSharesForSaleAmount[_parcelId][_from];
        uint256 pricePerShare = _fractionalSharesForSalePrice[_parcelId][_from];

        if (listedAmount == 0 || listedAmount < _amount)
            revert FractionalSharesNotForSale(_parcelId, _from);

        uint256 totalPrice = _amount * pricePerShare;
        if (msg.value < totalPrice) revert InsufficientFunds();

        // Transfer shares internally
        _fractionalShareHoldings[_parcelId][_from] -= _amount;
        _fractionalShareHoldings[_parcelId][msg.sender] += _amount;

        // Update listing (reduce amount listed, remove if 0)
        if (listedAmount == _amount) {
            delete _fractionalSharesForSaleAmount[_parcelId][_from];
            delete _fractionalSharesForSalePrice[_parcelId][_from];
        } else {
            _fractionalSharesForSaleAmount[_parcelId][_from] -= _amount;
        }

        // Transfer payment (simplified to sending ETH directly)
        (bool success, ) = payable(_from).call{value: totalPrice}("");
        require(success, "Payment transfer failed"); // Basic check

        // Handle potential excess payment (optional, can return or keep as fee)
        uint256 excess = msg.value - totalPrice;
        if (excess > 0) {
             // Send excess back or transfer to a fee address
             (bool successExcess, ) = payable(msg.sender).call{value: excess}("");
             require(successExcess, "Excess payment refund failed");
        }

        emit FractionalSharesPurchased(_parcelId, _from, msg.sender, _amount, totalPrice);
        emit FractionalSharesTransferred(_parcelId, _from, msg.sender, _amount); // Also emit share transfer event
    }

     // @dev Get the details of a fractional share listing.
     // @param _parcelId The ID of the parcel.
     // @param _seller The address of the seller.
     // @return amount The number of shares listed.
     // @return pricePerShare The price per share.
     function getFractionalSharesListing(uint256 _parcelId, address _seller) external view parcelExists(_parcelId) returns (uint256 amount, uint256 pricePerShare) {
         return (_fractionalSharesForSaleAmount[_parcelId][_seller], _fractionalSharesForSalePrice[_parcelId][_seller]);
     }


    // --- 12. Time-Slice / Rental Management Functions ---

    // @dev List a specific time range of a parcel for rent/use.
    //      Requires parcel owner or manager permissions.
    // @param _parcelId The ID of the parcel.
    // @param _startTime The start timestamp of the time slice.
    // @param _endTime The end timestamp of the time slice.
    // @param _pricePerSlice The price to book this time slice (simplified).
    function addTimeSliceListing(uint256 _parcelId, uint64 _startTime, uint64 _endTime, uint256 _pricePerSlice) external onlyParcelOwner(_parcelId) parcelExists(_parcelId) {
        if (_startTime >= _endTime) revert TimeSliceOverlap(); // Basic check
        if (_startTime < block.timestamp) revert TimeSliceExpired(); // Cannot list past times

        uint256 sliceId = _parcels[_parcelId].nextTimeSliceId++;
        _parcels[_parcelId].timeSlices[sliceId] = TimeSlice({
            startTime: _startTime,
            endTime: _endTime,
            currentUser: address(0), // Available initially
            price: _pricePerSlice,
            isBooked: false
        });

        emit TimeSliceListed(_parcelId, sliceId, _startTime, _endTime, _pricePerSlice);
    }

    // @dev Book/rent a specific time slice listing by its ID.
    //      Requires sending the price of the slice.
    // @param _parcelId The ID of the parcel.
    // @param _sliceId The ID of the time slice listing.
    function bookTimeSlice(uint256 _parcelId, uint256 _sliceId) external payable parcelExists(_parcelId) {
        TimeSlice storage slice = _parcels[_parcelId].timeSlices[_sliceId];

        if (slice.startTime == 0 && slice.endTime == 0) revert TimeSliceDoesNotExist(_parcelId, _sliceId); // Check if slice exists
        if (slice.isBooked) revert TimeSliceAlreadyBooked(_parcelId, _sliceId);
        if (slice.endTime < block.timestamp) revert TimeSliceExpired();
        if (msg.value < slice.price) revert InsufficientFunds();

        slice.currentUser = msg.sender;
        slice.isBooked = true;

        // Transfer payment to parcel owner (simplified - could go to pool/owner/fees)
        address parcelOwner = _ownerOf(_parcelId);
        (bool success, ) = payable(parcelOwner).call{value: slice.price}("");
        require(success, "Time slice payment failed");

        // Add remaining funds to pooled yield or refund
        uint256 excess = msg.value - slice.price;
        if (excess > 0) {
             // Refund excess
             (bool successExcess, ) = payable(msg.sender).call{value: excess}("");
             require(successExcess, "Excess payment refund failed");
        }

        // Accumulate yield for the parcel itself (if owner collects individually)
        _parcels[_parcelId].accumulatedYield += slice.price; // Simplified, assuming price is yield

        emit TimeSliceBooked(_parcelId, _sliceId, msg.sender);
    }

     // @dev Release a time slice (e.g., if booking expires or is canceled).
     //      Callable by the current user of the slice, the parcel owner, or a manager.
     //      Does not refund payment.
     // @param _parcelId The ID of the parcel.
     // @param _sliceId The ID of the time slice listing.
     function releaseTimeSlice(uint256 _parcelId, uint256 _sliceId) external parcelExists(_parcelId) {
         TimeSlice storage slice = _parcels[_parcelId].timeSlices[_sliceId];

         if (slice.startTime == 0 && slice.endTime == 0) revert TimeSliceDoesNotExist(_parcelId, _sliceId);
         if (!slice.isBooked) revert TimeSliceNotBooked(_parcelId, _sliceId);

         // Check if caller is the current user, parcel owner, or manager
         address parcelOwner = _ownerOf(_parcelId);
         if (msg.sender != slice.currentUser && msg.sender != parcelOwner && !_managers[msg.sender]) {
              revert NotApprovedOrOwner(); // Or specific error like NotAuthorizedToRelease
         }

         slice.currentUser = address(0); // Make available
         slice.isBooked = false;
         // Note: Does not delete the slice listing itself, just marks it as available again

         emit TimeSliceReleased(_parcelId, _sliceId);
     }


     // @dev Get the full details of a specific time slice for a parcel.
     // @param _parcelId The ID of the parcel.
     // @param _sliceId The ID of the time slice.
     // @return TimeSlice struct data.
     function getTimeSliceDetails(uint256 _parcelId, uint256 _sliceId) external view parcelExists(_parcelId) returns (TimeSlice memory) {
         TimeSlice storage slice = _parcels[_parcelId].timeSlices[_sliceId];
         if (slice.startTime == 0 && slice.endTime == 0) revert TimeSliceDoesNotExist(_parcelId, _sliceId);
         return slice;
     }

     // @dev Check if a specific time range overlaps with existing booked slices for a parcel.
     //      Useful for potential renters to see availability.
     // @param _parcelId The ID of the parcel.
     // @param _checkStartTime The start timestamp of the range to check.
     // @param _checkEndTime The end timestamp of the range to check.
     // @return True if any booked slice overlaps, False otherwise.
     function checkTimeSliceAvailability(uint256 _parcelId, uint64 _checkStartTime, uint64 _checkEndTime) external view parcelExists(_parcelId) returns (bool) {
         if (_checkStartTime >= _checkEndTime) return false; // Invalid range

         uint256 nextId = _parcels[_parcelId].nextTimeSliceId;
         for (uint256 i = 0; i < nextId; i++) {
             TimeSlice storage slice = _parcels[_parcelId].timeSlices[i];
             // Check if slice exists and is booked
             if (slice.startTime != 0 || slice.endTime != 0) { // Basic check for existence
                 if (slice.isBooked) {
                     // Check for overlap: [start1, end1] and [start2, end2] overlap if start1 < end2 AND start2 < end1
                     if (_checkStartTime < slice.endTime && slice.startTime < _checkEndTime) {
                         return false; // Found an overlap with a booked slice - meaning the *requested* period is NOT fully available
                     }
                 }
             }
         }
         return true; // No overlapping booked slices found
     }

      // @dev Get a list of all time slice IDs for a parcel.
      //      Helper function to iterate through time slices.
      // @param _parcelId The ID of the parcel.
      // @return An array of time slice IDs.
      function getParcelTimeSlices(uint256 _parcelId) external view parcelExists(_parcelId) returns (uint256[] memory) {
          uint256 nextId = _parcels[_parcelId].nextTimeSliceId;
          uint256[] memory sliceIds = new uint256[](nextId);
          for(uint256 i = 0; i < nextId; i++) {
              // Basic check if this slice ID was ever used (avoids returning 0 if some were "deleted" conceptually)
              if (_parcels[_parcelId].timeSlices[i].startTime != 0 || _parcels[_parcelId].timeSlices[i].endTime != 0) {
                   sliceIds[i] = i;
              }
          }
          return sliceIds;
      }


    // --- 13. Entanglement Management Functions ---

    // @dev Create a simulated 'entanglement' link between two distinct parcels.
    //      Requires Manager role.
    // @param _parcelId1 The ID of the first parcel.
    // @param _parcelId2 The ID of the second parcel.
    function createEntanglementLink(uint256 _parcelId1, uint256 _parcelId2) external onlyManager parcelExists(_parcelId1) parcelExists(_parcelId2) {
        if (_parcelId1 == _parcelId2) revert CannotEntangleSelf();
        if (_parcels[_parcelId1].entangledWith[_parcelId2]) revert EntanglementExists(_parcelId1, _parcelId2);

        _parcels[_parcelId1].entangledWith[_parcelId2] = true;
        _parcels[_parcelId2].entangledWith[_parcelId1] = true; // Entanglement is mutual

        emit EntanglementCreated(_parcelId1, _parcelId2);
    }

    // @dev Remove an entanglement link between two parcels.
    //      Requires Manager role.
    // @param _parcelId1 The ID of the first parcel.
    // @param _parcelId2 The ID of the second parcel.
    function breakEntanglementLink(uint256 _parcelId1, uint256 _parcelId2) external onlyManager parcelExists(_parcelId1) parcelExists(_parcelId2) {
         if (_parcelId1 == _parcelId2) revert CannotEntangleSelf();
         if (!_parcels[_parcelId1].entangledWith[_parcelId2]) revert NoEntanglementExists(_parcelId1, _parcelId2);

         delete _parcels[_parcelId1].entangledWith[_parcelId2];
         delete _parcels[_parcelId2].entangledWith[_parcelId1]; // Remove mutual link

         emit EntanglementBroken(_parcelId1, _parcelId2);
    }

     // @dev Simulate the propagation of a dynamic state change effect through entangled links.
     //      This is an internal function called by state change functions, or can be triggered by a manager.
     //      Propagates the 'state' attribute change to entangled parcels based on some logic.
     //      Requires Manager role if called externally, or internal call.
     // @param _sourceParcelId The ID of the parcel where the change originated.
    function propagateEntanglementEffect(uint256 _sourceParcelId) public onlyManager parcelExists(_sourceParcelId) { // Public to allow manager call, internal for internal triggers
        // ### SIMULATION of Propagation ###
        string memory sourceState = _parcels[_sourceParcelId].dynamicAttributes["state"];
        if (bytes(sourceState).length == 0) return; // No state to propagate

        // Iterate through potentially entangled parcels (simplified loop)
        // A more complex implementation might require tracking all parcel IDs or iterating over them
        // For this example, we'll check a range of possible parcel IDs
        uint256 maxParcelIdToCheck = _nextTokenId; // Check all minted parcels
        for (uint256 targetParcelId = 0; targetParcelId < maxParcelIdToCheck; targetParcelId++) {
             // Ensure target is a valid parcel and not the source
             if (_parcelExists[targetParcelId] && targetParcelId != _sourceParcelId) {
                 // Check if they are entangled
                 if (_parcels[_sourceParcelId].entangledWith[targetParcelId]) {
                     string memory targetState = _parcels[targetParcelId].dynamicAttributes["state"];
                     // Simulate a propagation effect: e.g., set target state to match source state 50% of the time
                     bytes32 seed = keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, _sourceParcelId, targetParcelId));
                     if (uint256(seed) % 2 == 0 && keccak256(abi.encodePacked(sourceState)) != keccak256(abi.encodePacked(targetState))) {
                          _parcels[targetParcelId].dynamicAttributes["state"] = sourceState;
                         emit DynamicAttributeUpdated(targetParcelId, "state", sourceState);
                         // Note: This could potentially trigger further propagation recursively, need safeguards
                         // For simplicity, this simulation does a single layer of propagation.
                     }
                 }
             }
        }
         // ### END SIMULATION ###
    }

    // @dev Get a list of parcels entangled with a given parcel.
    //      Note: This is a simplified implementation. Iterating over a mapping in Solidity is not direct.
    //      A real implementation would need to store entanglement links in an iterable structure.
    //      This function will simulate returning entangled IDs by checking a range.
    // @param _parcelId The ID of the parcel.
    // @return An array of entangled parcel IDs.
    function getEntangledParcels(uint256 _parcelId) external view parcelExists(_parcelId) returns (uint256[] memory) {
        uint256[] memory entangled; // This will be built by checking the mapping (simulation)
        uint256 count = 0;
        uint256 maxParcelIdToCheck = _nextTokenId; // Check all minted parcels

        // First pass to count how many are entangled
        for (uint256 targetParcelId = 0; targetParcelId < maxParcelIdToCheck; targetParcelId++) {
            if (_parcelExists[targetParcelId] && targetParcelId != _parcelId) {
                if (_parcels[_parcelId].entangledWith[targetParcelId]) {
                    count++;
                }
            }
        }

        // Second pass to populate the array
        entangled = new uint256[](count);
        uint256 index = 0;
         for (uint256 targetParcelId = 0; targetParcelId < maxParcelIdToCheck; targetParcelId++) {
            if (_parcelExists[targetParcelId] && targetParcelId != _parcelId) {
                if (_parcels[_parcelId].entangledWith[targetParcelId]) {
                    entangled[index] = targetParcelId;
                    index++;
                }
            }
        }

        return entangled;
    }


    // --- 14. Yield / Distribution Functions ---

    // @dev Allow the primary owner (or significant shareholder) to collect yield earned by a specific parcel.
    //      Yield could come from time slice bookings, etc. Requires parcel owner or manager.
    // @param _parcelId The ID of the parcel.
    function collectParcelYield(uint256 _parcelId) external onlyParcelOwner(_parcelId) parcelExists(_parcelId) {
        uint256 yieldAmount = _parcels[_parcelId].accumulatedYield;
        if (yieldAmount == 0) return;

        _parcels[_parcelId].accumulatedYield = 0; // Reset yield for the parcel

        // Transfer yield to the parcel owner
        (bool success, ) = payable(msg.sender).call{value: yieldAmount}("");
        require(success, "Yield transfer failed");

        emit YieldCollected(_parcelId, msg.sender, yieldAmount);
    }

    // @dev Claim accumulated yield from the pooled yield fund based on fractional share holdings.
    //      The pooled yield fund is conceptually where general income (like contract fees,
    //      or yield not collected per parcel) might go. Distribution is proportional to total shares held across *all* parcels.
    function claimPooledYield() external {
        uint256 totalSharesAcrossAllParcels = 0;
        // This calculation is gas-intensive as it iterates over all parcels and then all holders
        // In a real high-throughput system, a different yield distribution mechanism is needed (e.g., a separate distribution contract)
        // For simulation:
        uint256 maxParcelId = _nextTokenId;
        for (uint256 i = 0; i < maxParcelId; i++) {
            if (_parcelExists[i]) {
                 totalSharesAcrossAllParcels += _parcels[i].totalFractionalShares;
            }
        }

        if (totalSharesAcrossAllParcels == 0) return; // No shares outstanding

        uint256 claimableAmount = (_pooledYield * _getUsersTotalFractionalShares(msg.sender)) / totalSharesAcrossAllParcels;

        if (claimableAmount == 0) return;

        // This is a placeholder. The actual mechanism for decreasing _pooledYield and tracking per-user claims
        // would be complex. For this example, we just simulate claiming.
        // To make it work, _pooledYield would need to be increased elsewhere (e.g. from fees)
        // and we'd need mapping(address => uint256) claimedPooledYield to track who claimed what.

        // ### SIMULATION of Pooled Yield Claim ###
        // In a real contract:
        // require(_pooledYield >= claimableAmount, "Insufficient pooled yield"); // Should always be true if calculation is correct vs total
        // _pooledYield -= claimableAmount;
        // _claimedPooledYield[msg.sender] += claimableAmount; // Prevent double claiming

        // (bool success, ) = payable(msg.sender).call{value: claimableAmount}("");
        // require(success, "Pooled yield transfer failed");
        // ### END SIMULATION ###

        // For the simulation, we just emit the event without actual transfer
        emit PooledYieldClaimed(msg.sender, claimableAmount);

    }

     // Internal helper to calculate total shares held by a user across all parcels
     function _getUsersTotalFractionalShares(address _user) internal view returns (uint256) {
         uint256 total = 0;
         uint256 maxParcelId = _nextTokenId;
         for (uint256 i = 0; i < maxParcelId; i++) {
             if (_parcelExists[i]) {
                  total += _fractionalShareHoldings[i][_user];
             }
         }
         return total;
     }


    // --- 15. Governance / Proposal System Functions ---

    // @dev Create a new governance proposal to change a contract configuration.
    //      Requires Manager role.
    // @param _description Description of the proposal.
    // @param _data The encoded function call + parameters to execute if the proposal passes.
    // @return The ID of the created proposal.
    function proposeConfigChange(string calldata _description, bytes calldata _data) external onlyManager returns (uint256) {
        uint256 proposalId = _nextProposalId++;
        _proposals[proposalId] = Proposal({
            description: _description,
            data: _data,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriodDuration,
            hasVoted: new mapping(address => bool)(),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false,
            proposerVoteWeight: 1 // Simple weight for proposer
        });

        // Proposer votes automatically (optional logic)
        _proposals[proposalId].hasVoted[msg.sender] = true;
        _proposals[proposalId].votesFor = _proposals[proposalId].proposerVoteWeight;

        emit ProposalCreated(proposalId, msg.sender, _description);
        emit Voted(proposalId, msg.sender, true, _proposals[proposalId].proposerVoteWeight);

        return proposalId;
    }

     // @dev Cast a vote on an active governance proposal.
     //      Voting weight could be based on fractional shares/parcels held.
     // @param _proposalId The ID of the proposal to vote on.
     // @param _support True for a 'yes' vote, False for a 'no' vote.
     function voteOnProposal(uint256 _proposalId, bool _support) external {
         Proposal storage proposal = _proposals[_proposalId];
         if (proposal.creationTime == 0 && proposal.votingPeriodEnd == 0) revert ProposalDoesNotExist(_proposalId); // Basic check for existence
         if (block.timestamp >= proposal.votingPeriodEnd) revert ProposalVotingPeriodEnded(_proposalId);
         if (proposal.hasVoted[msg.sender]) revert VoteAlreadyCast(_proposalId, msg.sender);

         // ### SIMULATION of Voting Weight ###
         // Calculate voting weight based on total fractional shares held by the voter across ALL parcels
         uint256 voterWeight = _getUsersTotalFractionalShares(msg.sender);
         // Could also incorporate parcel ownership, number of parcels, staked tokens, etc.
         if (voterWeight == 0) voterWeight = 1; // Give minimum weight if no shares/parcels? Or require some stake? Let's give 1 if 0 shares for simulation

         proposal.hasVoted[msg.sender] = true;
         if (_support) {
             proposal.votesFor += voterWeight;
         } else {
             proposal.votesAgainst += voterWeight;
         }
         // ### END SIMULATION ###

         emit Voted(_proposalId, msg.sender, _support, voterWeight);
     }

     // @dev Attempt to execute a proposal if it has passed its voting period and met quorum/threshold.
     //      Any manager can attempt to execute after the voting period ends and grace period starts.
     // @param _proposalId The ID of the proposal to execute.
     function executeProposalIfPassed(uint256 _proposalId) external onlyManager {
         Proposal storage proposal = _proposals[_proposalId];
         if (proposal.creationTime == 0 && proposal.votingPeriodEnd == 0) revert ProposalDoesNotExist(_proposalId);
         if (block.timestamp < proposal.votingPeriodEnd) revert ProposalVotingPeriodActive(_proposalId);
         if (block.timestamp > proposal.votingPeriodEnd + proposalExecutionGracePeriod) revert ProposalVotingPeriodEnded(_proposalId); // Or separate 'ExecutionPeriodOver' error
         if (proposal.executed) revert ProposalAlreadyExecuted(_proposalId);

         // ### SIMULATION of Passing Logic (Quorum & Threshold) ###
         // Simple example: requires more 'for' votes than 'against' AND a minimum threshold of 'for' votes (e.g., 51% of SOME total or a fixed number)
         uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
         // Define a simple threshold and quorum (e.g., 50% + 1 vote threshold of cast votes, and a minimum quorum like 1000 total votes)
         uint256 quorumThreshold = 1000; // Example: Need at least 1000 total votes cast
         bool quorumMet = totalVotesCast >= quorumThreshold;
         bool thresholdMet = proposal.votesFor > proposal.votesAgainst; // Simple majority

         proposal.passed = quorumMet && thresholdMet;
         // ### END SIMULATION ###

         if (!proposal.passed) {
             // Proposal failed, mark as executed (no further attempts) but not passed
             proposal.executed = true;
             // Consider emitting a ProposalFailed event
             return;
         }

         // If passed, attempt to execute the payload data
         proposal.executed = true;
         (bool success, bytes memory result) = address(this).call(proposal.data);

         if (!success) {
             // Handle failed execution - maybe revert or just log
             // Reverting here means the state change (executed=true) is undone too, which might not be desired.
             // A better approach logs the failure and keeps executed=true.
             // For simplicity, we'll just require success.
             revert ExecutionFailed(_proposalId);
         }

         // Execution successful
         emit ProposalExecuted(_proposalId);
         // Optionally emit a more specific event based on what data was executed
     }

     // @dev Retrieve the details of a specific governance proposal.
     // @param _proposalId The ID of the proposal.
     // @return Proposal struct data.
     function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
         Proposal storage proposal = _proposals[_proposalId];
          if (proposal.creationTime == 0 && proposal.votingPeriodEnd == 0) revert ProposalDoesNotExist(_proposalId);
         // Note: Cannot return the `hasVoted` mapping directly from a public/external function.
         // Return a memory copy of the struct without the mapping.
         return Proposal({
             description: proposal.description,
             data: proposal.data,
             creationTime: proposal.creationTime,
             votingPeriodEnd: proposal.votingPeriodEnd,
             hasVoted: new mapping(address => bool)(), // Return empty mapping
             votesFor: proposal.votesFor,
             votesAgainst: proposal.votesAgainst,
             executed: proposal.executed,
             passed: proposal.passed,
             proposerVoteWeight: proposal.proposerVoteWeight
         });
     }


    // --- 16. Utility / Getters ---

    // @dev Get the current state of the contract's parcel counter.
    // @return The next available parcel ID.
    function getNextParcelId() external view returns (uint256) {
        return _nextTokenId;
    }

    // @dev Get the current state of the contract's proposal counter.
    // @return The next available proposal ID.
    function getNextProposalId() external view returns (uint256) {
        return _nextProposalId;
    }

     // @dev Generate a hash representing the current state of a parcel's dynamic attributes.
     //      Can be used for external verification or historical snapshots.
     // @param _parcelId The ID of the parcel.
     // @return A bytes32 hash of the parcel's dynamic state.
     function getCurrentQuantumStateHash(uint256 _parcelId) external view parcelExists(_parcelId) returns (bytes32) {
         // Hashing attributes from a mapping is tricky as iteration order isn't guaranteed.
         // A robust implementation would require storing attributes in an array or
         // sorting them before hashing. This is a simplified simulation.
         // We will hash the base URI + a selection of dynamic attributes in a fixed order (if they exist).
         // This is NOT a secure or comprehensive state hash for all possible attributes.

         bytes memory dataToHash;
         // Append base URI
         dataToHash = abi.encodePacked(dataToHash, _parcels[_parcelId].baseMetadataURI);

         // Append a few known potential dynamic attributes in a fixed order
         // This assumes expected attribute names, which might not always be the case.
         dataToHash = abi.encodePacked(dataToHash, _parcels[_parcelId].dynamicAttributes["state"]);
         dataToHash = abi.encodePacked(dataToHash, _parcels[_parcelId].dynamicAttributes["weather"]);
         dataToHash = abi.encodePacked(dataToHash, _parcels[_parcelId].dynamicAttributes["energy_level"]);

         // Add total shares and yield as part of 'state'
         dataToHash = abi.encodePacked(dataToHash, _parcels[_parcelId].totalFractionalShares);
         dataToHash = abi.encodePacked(dataToHash, _parcels[_parcelId].accumulatedYield);


         // Hash the combined data
         return keccak256(dataToHash);
     }


    // --- Fallback and Receive functions (optional but good practice) ---
    receive() external payable {
        // Optional: Handle direct ETH transfers, maybe add to pooled yield
        _pooledYield += msg.value;
    }

    fallback() external payable {
        // Optional: Handle calls to undefined functions, maybe revert or add to pooled yield
        _pooledYield += msg.value;
    }

}
```