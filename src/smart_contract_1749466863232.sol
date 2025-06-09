Okay, let's design a smart contract that acts as a decentralized registry for NFT marketplaces. This allows dApps, users, or other contracts to discover, verify information about, and interact indirectly with various registered marketplaces.

To make it advanced and creative, we can include features like:

1.  **Multi-Status Registration:** Marketplaces can be `Proposed`, `Approved`, `Paused`, or `Deregistered`.
2.  **Moderation:** A set of moderators alongside the owner to manage the registry.
3.  **Feature/Standard Tagging:** Marketplaces can declare supported NFT standards (ERC721, ERC1155, etc.) and features (Auctions, Direct Buy, Fractionalization, Royalties Enforcement). The registry can store and allow searching based on these tags.
4.  **Verification Status:** A manually assigned flag (`isVerified`) by moderators/owner.
5.  **Registration Fees:** A configurable fee to prevent spam.
6.  **Delegation:** Marketplace owners can delegate the right to update their registry entry to another address.
7.  **Proposed Updates:** Allow anyone to propose updates to a marketplace's information, which requires approval by moderators/owner.
8.  **Marketplace Linking:** Allow linking related marketplaces together with a specified relationship type (e.g., "integrates with", "provides analytics for").
9.  **Basic Health Check Signal:** A function for others to trigger a signal requesting a health check (assuming off-chain monitoring acts on this event).

This goes beyond a simple list by adding lifecycle management, roles, structured metadata, governance-like features (moderation, proposed updates), and basic relationship mapping.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTMarketplaceRegistry
 * @dev A decentralized registry for listing and managing information about NFT marketplaces.
 * Allows discovery, verification, and lookup based on features and standards.
 * Includes features like moderation, status lifecycle, fee-based registration,
 * delegation of update rights, proposed updates, and marketplace linking.
 */

/**
 * @notice Outline
 * 1. Enums for Marketplace Status, Marketplace Features, NFT Standards, Relationship Types
 * 2. Structs for Marketplace Info and Proposed Updates
 * 3. State Variables: Ownership, Moderators, Fee Configuration, Marketplace Data, Proposed Updates Data, Recognized Standards/Features, Links Data
 * 4. Events for all significant actions
 * 5. Modifiers for access control
 * 6. Core Admin Functions: Set owner, Add/Remove moderators, Set fees, Withdraw fees, Manage recognized standards/features
 * 7. Registration Lifecycle Functions: Propose, Approve, Reject, Deregister, Pause, Unpause
 * 8. Marketplace Management Functions (by owner/delegate): Update Info, Transfer Entry Ownership, Delegate Update Rights
 * 9. Proposed Update Functions: Propose Update, Approve Proposed Update, Reject Proposed Update
 * 10. Relationship Functions: Link Marketplaces, Remove Link
 * 11. Verification Function: Set Verification Status
 * 12. Health Check Function: Signal a health check
 * 13. Query Functions: Get marketplace details, Find by criteria, Check status/existence, Get counts, Get links, Get moderators, Get fees, Get recognized standards/features
 */

/**
 * @notice Function Summary
 *
 * - **Admin & Configuration:**
 *   - `setOwner(address _newOwner)`: Sets the new contract owner.
 *   - `addModerator(address _moderator)`: Adds a moderator.
 *   - `removeModerator(address _moderator)`: Removes a moderator.
 *   - `setRegistrationFee(uint256 _fee)`: Sets the fee for proposing a marketplace.
 *   - `withdrawFees()`: Allows owner to withdraw accumulated fees.
 *   - `addRecognizedStandard(bytes32 _standard)`: Adds a recognized NFT standard tag.
 *   - `removeRecognizedStandard(bytes32 _standard)`: Removes a recognized standard tag.
 *   - `addRecognizedFeature(bytes32 _feature)`: Adds a recognized marketplace feature tag.
 *   - `removeRecognizedFeature(bytes32 _feature)`: Removes a recognized feature tag.
 *
 * - **Registration & Lifecycle:**
 *   - `proposeMarketplace(address _contractAddress, string memory _name, string memory _description, bytes32[] memory _supportedStandards, bytes32[] memory _features)`: Proposes a new marketplace entry (payable with fee).
 *   - `approveMarketplace(uint256 _marketplaceId)`: Owner/Moderator approves a proposed marketplace.
 *   - `rejectMarketplace(uint256 _marketplaceId, string memory _reason)`: Owner/Moderator rejects a proposed marketplace.
 *   - `deregisterMarketplace(uint256 _marketplaceId)`: Marketplace owner or Registry owner/moderator deregisters an entry.
 *   - `pauseMarketplace(uint256 _marketplaceId)`: Owner/Moderator pauses an approved marketplace entry.
 *   - `unpauseMarketplace(uint256 _marketplaceId)`: Owner/Moderator unpauses a paused marketplace entry.
 *
 * - **Marketplace Entry Management (by Entry Owner/Delegate):**
 *   - `updateMarketplaceInfo(uint256 _marketplaceId, string memory _name, string memory _description, bytes32[] memory _supportedStandards, bytes32[] memory _features)`: Allows the marketplace entry owner or a delegate to update its details.
 *   - `transferMarketplaceEntryOwnership(uint256 _marketplaceId, address _newOwner)`: Transfers ownership of a marketplace *entry* in the registry.
 *   - `delegateMarketplaceUpdateRights(uint256 _marketplaceId, address _delegate, bool _canUpdate)`: Grants or revokes update delegation rights for a specific marketplace entry.
 *
 * - **Proposed Updates (by Anyone):**
 *   - `proposeMarketplaceInfoUpdate(uint256 _marketplaceId, string memory _name, string memory _description, bytes32[] memory _supportedStandards, bytes32[] memory _features)`: Allows anyone to propose an update to an existing marketplace entry.
 *   - `approveProposedUpdate(uint256 _marketplaceId)`: Owner/Moderator approves a pending proposed update.
 *   - `rejectProposedUpdate(uint256 _marketplaceId)`: Owner/Moderator rejects a pending proposed update.
 *
 * - **Marketplace Linking:**
 *   - `linkRelatedMarketplaces(uint256 _marketplaceId1, uint256 _marketplaceId2, bytes32 _relationshipType)`: Creates a directed link between two registered marketplaces.
 *   - `removeMarketplaceLink(uint256 _marketplaceId1, uint256 _marketplaceId2, bytes32 _relationshipType)`: Removes a specific link.
 *
 * - **Verification:**
 *   - `setVerificationStatus(uint256 _marketplaceId, bool _isVerified)`: Owner/Moderator sets the verification flag for an entry.
 *
 * - **Health Check Signal:**
 *   - `triggerMarketplaceHealthCheck(uint256 _marketplaceId)`: Emits an event signaling a request for an off-chain health check.
 *
 * - **Query Functions (View/Pure):**
 *   - `getMarketplaceInfo(uint256 _marketplaceId)`: Gets full info for a marketplace ID.
 *   - `getMarketplaceIdByAddress(address _contractAddress)`: Gets ID from contract address.
 *   - `getMarketplaceCount(MarketplaceStatus _status)`: Gets count of marketplaces by status.
 *   - `getMarketplaceIdsByEntryOwner(address _owner)`: Gets IDs of marketplace entries owned by an address.
 *   - `findMarketplacesByStandard(bytes32 _standard)`: Finds IDs of marketplaces supporting a standard.
 *   - `findMarketplacesByFeature(bytes32 _feature)`: Finds IDs of marketplaces supporting a feature.
 *   - `isMarketplaceApproved(uint256 _marketplaceId)`: Checks if a marketplace is in Approved status.
 *   - `isMarketplaceRegistered(address _contractAddress)`: Checks if a contract address has an entry (any status).
 *   - `getModerators()`: Gets the list of current moderators.
 *   - `getRegistrationFee()`: Gets the current registration fee.
 *   - `getRecognizedStandards()`: Gets the list of recognized standards.
 *   - `getRecognizedFeatures()`: Gets the list of recognized features.
 *   - `getRelatedMarketplaces(uint256 _marketplaceId)`: Gets a list of marketplaces linked *from* a given ID.
 *   - `getPendingProposedUpdate(uint256 _marketplaceId)`: Gets info about a pending proposed update.
 */


contract NFTMarketplaceRegistry {

    address private _owner;
    mapping(address => bool) private _moderators;
    uint256 private _registrationFee;

    enum MarketplaceStatus {
        None,       // Default uninitialized state
        Proposed,   // Proposed by anyone, pending approval
        Approved,   // Approved by owner/moderator, active
        Paused,     // Temporarily paused by owner/moderator
        Rejected,   // Rejected by owner/moderator
        Deregistered // Deregistered by entry owner or registry owner/moderator
    }

    struct MarketplaceInfo {
        uint256 id;
        address contractAddress;
        address entryOwner; // The address that registered/manages this entry
        string name;
        string description;
        bytes32[] supportedStandards; // e.g., "ERC721", "ERC1155"
        bytes32[] features;           // e.g., "Auctions", "DirectBuy", "Fractionalization"
        uint255 registrationTimestamp;
        MarketplaceStatus status;
        bool isVerified; // Verified by registry moderators/owner
        address updateDelegate; // Address allowed to call updateMarketplaceInfo
        uint256 proposedUpdateId; // ID of pending proposed update, 0 if none
    }

    struct ProposedUpdate {
         uint256 id; // Matches marketplaceId
         string name;
         string description;
         bytes32[] supportedStandards;
         bytes32[] features;
         address proposer;
         uint255 proposalTimestamp;
    }

    // --- State Variables ---
    uint256 private _nextMarketplaceId = 1;
    mapping(uint256 => MarketplaceInfo) private _marketplaces;
    mapping(address => uint256) private _marketplaceIdByAddress; // Maps contract address to ID (only for entries in non-None status)
    mapping(address => uint255[]) private _marketplaceIdsByEntryOwner; // List of IDs for entries owned by an address

    mapping(uint256 => ProposedUpdate) private _pendingProposedUpdates;

    mapping(bytes32 => bool) private _recognizedStandards;
    mapping(bytes32 => bool) private _recognizedFeatures;

    // Simplified Graph: marketplaceId1 => list of {marketplaceId2, relationshipType}
    mapping(uint255 => bytes32[]) private _linkedRelationshipTypes;
    mapping(uint255 => mapping(bytes32 => uint255[])) private _linkedMarketplaceIds; // marketplaceId1 => relationshipType => list of marketplaceId2

    // --- Events ---
    event OwnerTransferred(address indexed previousOwner, address indexed newOwner);
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);
    event RegistrationFeeSet(uint256 oldFee, uint256 newFee);
    event FeesWithdrawal(address indexed recipient, uint256 amount);

    event MarketplaceProposed(uint256 indexed marketplaceId, address indexed contractAddress, address indexed proposer);
    event MarketplaceApproved(uint256 indexed marketplaceId, address indexed contractAddress, address indexed approver);
    event MarketplaceRejected(uint256 indexed marketplaceId, address indexed contractAddress, address indexed rejector, string reason);
    event MarketplaceDeregistered(uint256 indexed marketplaceId, address indexed contractAddress, address indexed remover);
    event MarketplacePaused(uint256 indexed marketplaceId, address indexed contractAddress, address indexed pauser);
    event MarketplaceUnpaused(uint256 indexed marketplaceId, address indexed contractAddress, address indexed unpauser);

    event MarketplaceInfoUpdated(uint256 indexed marketplaceId, address indexed contractAddress, address indexed updater);
    event MarketplaceEntryOwnershipTransferred(uint256 indexed marketplaceId, address indexed oldOwner, address indexed newOwner);
    event MarketplaceUpdateDelegateSet(uint256 indexed marketplaceId, address indexed delegate, bool canUpdate);

    event MarketplaceUpdateProposed(uint256 indexed marketplaceId, address indexed proposer);
    event ProposedUpdateApproved(uint256 indexed marketplaceId, address indexed approver);
    event ProposedUpdateRejected(uint256 indexed marketplaceId, address indexed rejector);

    event MarketplacesLinked(uint256 indexed marketplaceId1, uint256 indexed marketplaceId2, bytes32 relationshipType);
    event MarketplaceLinkRemoved(uint256 indexed marketplaceId1, uint256 indexed marketplaceId2, bytes32 relationshipType);

    event VerificationStatusSet(uint256 indexed marketplaceId, address indexed setter, bool isVerified);
    event HealthCheckTriggered(uint256 indexed marketplaceId);

    event RecognizedStandardAdded(bytes32 standard);
    event RecognizedStandardRemoved(bytes32 standard);
    event RecognizedFeatureAdded(bytes32 feature);
    event RecognizedFeatureRemoved(bytes32 feature);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    modifier onlyOwnerOrModerator() {
        require(msg.sender == _owner || _moderators[msg.sender], "Only owner or moderator");
        _;
    }

    modifier onlyMarketplaceEntryOwner(uint256 _marketplaceId) {
        require(_marketplaces[_marketplaceId].entryOwner == msg.sender, "Only marketplace entry owner");
        _;
    }

     modifier onlyMarketplaceEntryOwnerOrDelegate(uint256 _marketplaceId) {
        require(_marketplaces[_marketplaceId].entryOwner == msg.sender || _marketplaces[_marketplaceId].updateDelegate == msg.sender, "Only marketplace entry owner or delegate");
        _;
    }

     modifier onlyMarketplaceEntryOwnerOrRegistryAdmin(uint256 _marketplaceId) {
        require(_marketplaces[_marketplaceId].entryOwner == msg.sender || msg.sender == _owner || _moderators[msg.sender], "Only marketplace entry owner or registry admin");
        _;
    }

    modifier marketplaceMustExist(uint256 _marketplaceId) {
        require(_marketplaces[_marketplaceId].status != MarketplaceStatus.None, "Marketplace does not exist");
        _;
    }

    modifier marketplaceMustBeApproved(uint256 _marketplaceId) {
        require(_marketplaces[_marketplaceId].status == MarketplaceStatus.Approved, "Marketplace must be Approved");
        _;
    }

    modifier marketplaceMustNotHavePendingUpdate(uint256 _marketplaceId) {
         require(_marketplaces[_marketplaceId].proposedUpdateId == 0, "Marketplace has a pending update proposal");
         _;
    }

     modifier marketplaceMustHavePendingUpdate(uint256 _marketplaceId) {
         require(_marketplaces[_marketplaceId].proposedUpdateId != 0, "Marketplace does not have a pending update proposal");
         _;
     }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        // Initialize some common standards/features (optional)
        _recognizedStandards["ERC721"] = true;
        _recognizedStandards["ERC1155"] = true;
        _recognizedFeatures["Auctions"] = true;
        _recognizedFeatures["DirectBuy"] = true;
        _recognizedFeatures["Fractionalization"] = true;
        _recognizedFeatures["CreatorRoyalties"] = true;
    }

    // --- Admin & Configuration Functions ---

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        emit OwnerTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    function addModerator(address _moderator) external onlyOwner {
        require(_moderator != address(0), "Zero address");
        require(!_moderators[_moderator], "Already a moderator");
        _moderators[_moderator] = true;
        emit ModeratorAdded(_moderator);
    }

    function removeModerator(address _moderator) external onlyOwner {
         require(_moderators[_moderator], "Not a moderator");
        _moderators[_moderator] = false;
        emit ModeratorRemoved(_moderator);
    }

    function setRegistrationFee(uint256 _fee) external onlyOwnerOrModerator {
        uint256 oldFee = _registrationFee;
        _registrationFee = _fee;
        emit RegistrationFeeSet(oldFee, _fee);
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        // Use call instead of transfer/send to avoid reentrancy issues with gas limits
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawal(msg.sender, balance);
    }

    function addRecognizedStandard(bytes32 _standard) external onlyOwnerOrModerator {
        require(_standard != bytes32(0), "Standard cannot be empty");
        require(!_recognizedStandards[_standard], "Standard already recognized");
        _recognizedStandards[_standard] = true;
        emit RecognizedStandardAdded(_standard);
    }

    function removeRecognizedStandard(bytes32 _standard) external onlyOwnerOrModerator {
        require(_recognizedStandards[_standard], "Standard not recognized");
        _recognizedStandards[_standard] = false;
        emit RecognizedStandardRemoved(_standard);
    }

    function addRecognizedFeature(bytes32 _feature) external onlyOwnerOrModerator {
        require(_feature != bytes32(0), "Feature cannot be empty");
        require(!_recognizedFeatures[_feature], "Feature already recognized");
        _recognizedFeatures[_feature] = true;
        emit RecognizedFeatureAdded(_feature);
    }

    function removeRecognizedFeature(bytes32 _feature) external onlyOwnerOrModerator {
        require(_recognizedFeatures[_feature], "Feature not recognized");
        _recognizedFeatures[_feature] = false;
        emit RecognizedFeatureRemoved(_feature);
    }


    // --- Registration Lifecycle Functions ---

    function proposeMarketplace(
        address _contractAddress,
        string memory _name,
        string memory _description,
        bytes32[] memory _supportedStandards,
        bytes32[] memory _features
    ) external payable marketplaceMustNotHavePendingUpdate(0) { // Cannot propose address 0 or if it's already proposed/registered
        require(_contractAddress != address(0), "Contract address cannot be zero");
        require(_marketplaceIdByAddress[_contractAddress] == 0, "Marketplace address already has an entry");
        require(msg.value >= _registrationFee, "Insufficient fee");

        // Optional: check if standards/features are recognized? Or allow any?
        // Let's allow any for flexibility, but provide the recognized list for filtering/guidance.

        uint256 marketplaceId = _nextMarketplaceId++;
        _marketplaces[marketplaceId] = MarketplaceInfo({
            id: marketplaceId,
            contractAddress: _contractAddress,
            entryOwner: msg.sender,
            name: _name,
            description: _description,
            supportedStandards: _supportedStandards,
            features: _features,
            registrationTimestamp: uint255(block.timestamp),
            status: MarketplaceStatus.Proposed,
            isVerified: false,
            updateDelegate: address(0),
            proposedUpdateId: 0
        });
        _marketplaceIdByAddress[_contractAddress] = marketplaceId;
        _marketplaceIdsByEntryOwner[msg.sender].push(uint255(marketplaceId));

        emit MarketplaceProposed(marketplaceId, _contractAddress, msg.sender);
    }

    function approveMarketplace(uint256 _marketplaceId) external onlyOwnerOrModerator marketplaceMustExist(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        require(marketplace.status == MarketplaceStatus.Proposed, "Marketplace must be in Proposed status");

        marketplace.status = MarketplaceStatus.Approved;
        emit MarketplaceApproved(_marketplaceId, marketplace.contractAddress, msg.sender);
    }

     function rejectMarketplace(uint256 _marketplaceId, string memory _reason) external onlyOwnerOrModerator marketplaceMustExist(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        require(marketplace.status == MarketplaceStatus.Proposed, "Marketplace must be in Proposed status");

        marketplace.status = MarketplaceStatus.Rejected;
        // Note: We don't delete the entry, just mark it as Rejected.
        // The registration fee is kept.
        emit MarketplaceRejected(_marketplaceId, marketplace.contractAddress, msg.sender, _reason);
    }

    function deregisterMarketplace(uint256 _marketplaceId) external onlyMarketplaceEntryOwnerOrRegistryAdmin(_marketplaceId) marketplaceMustExist(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        require(marketplace.status != MarketplaceStatus.Deregistered, "Marketplace already deregistered");

        // Remove address lookup (only keep for active/relevant statuses)
        if (_marketplaceIdByAddress[marketplace.contractAddress] == _marketplaceId) {
             _marketplaceIdByAddress[marketplace.contractAddress] = 0; // Clear mapping entry
        }
         // Note: We don't remove from _marketplaceIdsByEntryOwner as it's an append-only list.
         // Status indicates current state.

        marketplace.status = MarketplaceStatus.Deregistered;
        // Clear pending update if any
        if (marketplace.proposedUpdateId != 0) {
            delete _pendingProposedUpdates[marketplace.proposedUpdateId];
             marketplace.proposedUpdateId = 0;
        }

        emit MarketplaceDeregistered(_marketplaceId, marketplace.contractAddress, msg.sender);
    }

    function pauseMarketplace(uint256 _marketplaceId) external onlyOwnerOrModerator marketplaceMustBeApproved(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        marketplace.status = MarketplaceStatus.Paused;
        emit MarketplacePaused(_marketplaceId, marketplace.contractAddress, msg.sender);
    }

    function unpauseMarketplace(uint256 _marketplaceId) external onlyOwnerOrModerator marketplaceMustExist(_marketplaceId) {
         MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        require(marketplace.status == MarketplaceStatus.Paused, "Marketplace must be in Paused status");
        marketplace.status = MarketplaceStatus.Approved;
        emit MarketplaceUnpaused(_marketplaceId, marketplace.contractAddress, msg.sender);
    }


    // --- Marketplace Entry Management (by Entry Owner/Delegate) ---

    function updateMarketplaceInfo(
        uint256 _marketplaceId,
        string memory _name,
        string memory _description,
        bytes32[] memory _supportedStandards,
        bytes32[] memory _features
    ) external onlyMarketplaceEntryOwnerOrDelegate(_marketplaceId) marketplaceMustExist(_marketplaceId) {
        // Allow updates even if paused/proposed/etc. Registry info can be updated.
        // Approval is only for the initial 'Approved' status.
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];

        marketplace.name = _name;
        marketplace.description = _description;
        marketplace.supportedStandards = _supportedStandards; // Replaces existing array
        marketplace.features = _features; // Replaces existing array

        emit MarketplaceInfoUpdated(_marketplaceId, marketplace.contractAddress, msg.sender);
    }

     function transferMarketplaceEntryOwnership(uint256 _marketplaceId, address _newOwner) external onlyMarketplaceEntryOwner(_marketplaceId) marketplaceMustExist(_marketplaceId) {
        require(_newOwner != address(0), "New owner is the zero address");
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        address oldOwner = marketplace.entryOwner;
        marketplace.entryOwner = _newOwner;

        // Update list of IDs for owners - expensive to remove, better to just track status
        // Alternatively, could add the new ID to the new owner's list, and leave the old one.
        // Let's stick to status check for ownership.

        emit MarketplaceEntryOwnershipTransferred(_marketplaceId, oldOwner, _newOwner);
     }

     function delegateMarketplaceUpdateRights(uint256 _marketplaceId, address _delegate, bool _canUpdate) external onlyMarketplaceEntryOwner(_marketplaceId) marketplaceMustExist(_marketplaceId) {
        require(_delegate != address(0), "Delegate address cannot be zero");
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];

        if (_canUpdate) {
             require(marketplace.updateDelegate == address(0), "Update rights already delegated");
             marketplace.updateDelegate = _delegate;
        } else {
            require(marketplace.updateDelegate == _delegate, "Delegate address does not have update rights");
            marketplace.updateDelegate = address(0);
        }

        emit MarketplaceUpdateDelegateSet(_marketplaceId, _delegate, _canUpdate);
     }


    // --- Proposed Update Functions (by Anyone) ---

     function proposeMarketplaceInfoUpdate(
        uint256 _marketplaceId,
        string memory _name,
        string memory _description,
        bytes32[] memory _supportedStandards,
        bytes32[] memory _features
    ) external marketplaceMustExist(_marketplaceId) marketplaceMustNotHavePendingUpdate(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        // Use the same ID for the proposed update for simplicity
        uint256 proposedId = _marketplaceId;

        _pendingProposedUpdates[proposedId] = ProposedUpdate({
            id: proposedId,
            name: _name,
            description: _description,
            supportedStandards: _supportedStandards,
            features: _features,
            proposer: msg.sender,
            proposalTimestamp: uint255(block.timestamp)
        });

        marketplace.proposedUpdateId = proposedId; // Link proposal to marketplace
        emit MarketplaceUpdateProposed(_marketplaceId, msg.sender);
    }

     function approveProposedUpdate(uint256 _marketplaceId) external onlyOwnerOrModerator marketplaceMustHavePendingUpdate(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        ProposedUpdate storage proposed = _pendingProposedUpdates[marketplace.proposedUpdateId];

        marketplace.name = proposed.name;
        marketplace.description = proposed.description;
        marketplace.supportedStandards = proposed.supportedStandards;
        marketplace.features = proposed.features;

        delete _pendingProposedUpdates[marketplace.proposedUpdateId];
        marketplace.proposedUpdateId = 0;

        emit ProposedUpdateApproved(_marketplaceId, msg.sender);
        emit MarketplaceInfoUpdated(_marketplaceId, marketplace.contractAddress, address(0)); // Update signaled, updater is registry admin
     }

     function rejectProposedUpdate(uint256 _marketplaceId) external onlyOwnerOrModerator marketplaceMustHavePendingUpdate(_marketplaceId) {
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        delete _pendingProposedUpdates[marketplace.proposedUpdateId];
        marketplace.proposedUpdateId = 0;

        emit ProposedUpdateRejected(_marketplaceId, msg.sender);
     }


    // --- Marketplace Linking ---

    function linkRelatedMarketplaces(uint256 _marketplaceId1, uint256 _marketplaceId2, bytes32 _relationshipType) external marketplaceMustBeApproved(_marketplaceId1) marketplaceMustBeApproved(_marketplaceId2) {
        require(_marketplaceId1 != _marketplaceId2, "Cannot link a marketplace to itself");
        require(_relationshipType != bytes32(0), "Relationship type cannot be empty");

        // Check if this specific link already exists (simple iteration for now)
        bool linkExists = false;
        bytes32[] storage types = _linkedRelationshipTypes[_marketplaceId1];
        mapping(bytes32 => uint255[]) storage linkedIds = _linkedMarketplaceIds[_marketplaceId1];

        for(uint i = 0; i < types.length; i++) {
            if (types[i] == _relationshipType) {
                uint255[] storage ids = linkedIds[types[i]];
                for(uint j = 0; j < ids.length; j++) {
                    if (ids[j] == _marketplaceId2) {
                        linkExists = true;
                        break;
                    }
                }
                if (linkExists) break;
            }
        }
        require(!linkExists, "Link already exists");

        // Add the link
        bool typeExists = false;
         for(uint i = 0; i < types.length; i++) {
             if (types[i] == _relationshipType) {
                 typeExists = true;
                 break;
             }
         }
         if (!typeExists) {
            types.push(_relationshipType);
         }

        linkedIds[_relationshipType].push(uint255(_marketplaceId2));

        emit MarketplacesLinked(_marketplaceId1, _marketplaceId2, _relationshipType);
    }

    // Note: Removing a link requires knowing all 3 components: id1, id2, type.
    // This implementation is simplified and assumes no duplicate links for the *exact* same type and pair.
    // Removing from array is inefficient - a real-world system might use mappings for links or graph database off-chain.
    // This is a placeholder illustrating the concept.
    function removeMarketplaceLink(uint256 _marketplaceId1, uint256 _marketplaceId2, bytes32 _relationshipType) external marketplaceMustBeApproved(_marketplaceId1) marketplaceMustBeApproved(_marketplaceId2) {
        bytes32[] storage types = _linkedRelationshipTypes[_marketplaceId1];
        mapping(bytes32 => uint255[]) storage linkedIds = _linkedMarketplaceIds[_marketplaceId1];

        bool linkFoundAndRemoved = false;
        uint typeIndex = types.length;

        // Find the relationship type index
        for(uint i = 0; i < types.length; i++) {
            if (types[i] == _relationshipType) {
                typeIndex = i;
                break;
            }
        }
        require(typeIndex < types.length, "Relationship type not found for this source marketplace");

        uint255[] storage ids = linkedIds[_relationshipType];
        uint targetIndex = ids.length;

        // Find and remove the target ID from the list for this type
        for(uint j = 0; j < ids.length; j++) {
            if (ids[j] == _marketplaceId2) {
                // Simple removal by swapping with last element (order doesn't matter here)
                ids[j] = ids[ids.length - 1];
                ids.pop();
                linkFoundAndRemoved = true;
                targetIndex = j; // Store index if needed later (not currently)
                break;
            }
        }
        require(linkFoundAndRemoved, "Specific link not found");

        // If the list for this relationship type is now empty, remove the type from the types list
        if (ids.length == 0) {
             types[typeIndex] = types[types.length - 1];
             types.pop();
        }

        emit MarketplaceLinkRemoved(_marketplaceId1, _marketplaceId2, _relationshipType);
    }


    // --- Verification ---

    function setVerificationStatus(uint256 _marketplaceId, bool _isVerified) external onlyOwnerOrModerator marketplaceMustExist(_marketplaceId) {
        // Allow setting verification status regardless of lifecycle status
        MarketplaceInfo storage marketplace = _marketplaces[_marketplaceId];
        require(marketplace.isVerified != _isVerified, "Verification status is already set to this value");
        marketplace.isVerified = _isVerified;
        emit VerificationStatusSet(_marketplaceId, msg.sender, _isVerified);
    }


    // --- Health Check Signal ---

    function triggerMarketplaceHealthCheck(uint256 _marketplaceId) external marketplaceMustExist(_marketplaceId) {
        // This function doesn't perform the check, it just emits an event
        // that off-chain services (like a monitoring bot) can listen to and act upon.
        // Can be called by anyone to signal that a check is needed.
        emit HealthCheckTriggered(_marketplaceId);
    }


    // --- Query Functions (View/Pure) ---

    function getMarketplaceInfo(uint256 _marketplaceId) external view marketplaceMustExist(_marketplaceId) returns (MarketplaceInfo memory) {
        return _marketplaces[_marketplaceId];
    }

    function getMarketplaceIdByAddress(address _contractAddress) external view returns (uint256) {
         // Returns 0 if not registered or if entry status doesn't use this mapping (currently, all non-None entries use it)
        return _marketplaceIdByAddress[_contractAddress];
    }

    function getMarketplaceCount(MarketplaceStatus _status) external view returns (uint256 count) {
        // Note: Iterating over a mapping is not possible.
        // Counting requires iterating through all possible IDs up to _nextMarketplaceId - 1.
        // This can be expensive for a large number of entries.
        // A better approach for counting by status would be to maintain separate counters or lists per status.
        // For this example, we'll use iteration to demonstrate, but acknowledge the gas cost.
        for (uint256 i = 1; i < _nextMarketplaceId; i++) {
            if (_marketplaces[i].status == _status) {
                count++;
            }
        }
    }

     function getMarketplaceIdsByEntryOwner(address _owner) external view returns (uint255[] memory) {
        // Note: This returns the *historical* list of entries owned by the address.
        // Check the status of each returned ID to see if it's currently active/relevant.
        return _marketplaceIdsByEntryOwner[_owner];
     }

    function findMarketplacesByStandard(bytes32 _standard) external view returns (uint255[] memory) {
        // Iterating through all marketplaces to find matches - also potentially expensive.
        // A more scalable approach would involve reverse mappings (standard => list of marketplace IDs)
        // maintained when entries are added/updated.
        uint256[] memory matchingIds = new uint256[](0);
        for (uint256 i = 1; i < _nextMarketplaceId; i++) {
             MarketplaceInfo storage marketplace = _marketplaces[i];
             // Only include Approved marketplaces in search results for standards/features
             if (marketplace.status == MarketplaceStatus.Approved) {
                for (uint j = 0; j < marketplace.supportedStandards.length; j++) {
                    if (marketplace.supportedStandards[j] == _standard) {
                         // Append to dynamic array
                         uint currentLength = matchingIds.length;
                         bytes memory temp = new bytes(currentLength * 32 + 32);
                         assembly {
                             let oldptr := add(matchingIds, 0x20)
                             let newptr := add(temp, 0x20)
                             // Copy existing data
                             if gt(currentLength, 0) {
                                 datacopy(newptr, oldptr, mul(currentLength, 0x20))
                             }
                             // Add new element at the end
                             mstore(add(newptr, mul(currentLength, 0x20)), i) // Store ID as uint255 (fits in bytes32)
                             // Set new length
                             mstore(temp, add(currentLength, 1))
                         }
                         matchingIds = abi.decode(temp, (uint255[])); // Recast to uint255[]
                         break; // Found the standard, move to next marketplace
                    }
                }
             }
        }
        return matchingIds;
    }

     function findMarketplacesByFeature(bytes32 _feature) external view returns (uint255[] memory) {
         // Similar logic to findMarketplacesByStandard, iterates through all.
         uint256[] memory matchingIds = new uint256[](0);
         for (uint256 i = 1; i < _nextMarketplaceId; i++) {
             MarketplaceInfo storage marketplace = _marketplaces[i];
              if (marketplace.status == MarketplaceStatus.Approved) {
                for (uint j = 0; j < marketplace.features.length; j++) {
                    if (marketplace.features[j] == _feature) {
                        // Append to dynamic array (same technique as above)
                        uint currentLength = matchingIds.length;
                         bytes memory temp = new bytes(currentLength * 32 + 32);
                         assembly {
                             let oldptr := add(matchingIds, 0x20)
                             let newptr := add(temp, 0x20)
                             if gt(currentLength, 0) {
                                 datacopy(newptr, oldptr, mul(currentLength, 0x20))
                             }
                             mstore(add(newptr, mul(currentLength, 0x20)), i)
                             mstore(temp, add(currentLength, 1))
                         }
                         matchingIds = abi.decode(temp, (uint255[]));
                        break;
                    }
                }
             }
         }
         return matchingIds;
     }


    function isMarketplaceApproved(uint256 _marketplaceId) external view returns (bool) {
        if (_marketplaceId == 0 || _marketplaceId >= _nextMarketplaceId) return false;
        return _marketplaces[_marketplaceId].status == MarketplaceStatus.Approved;
    }

    function isMarketplaceRegistered(address _contractAddress) external view returns (bool) {
         // Checks if *any* entry exists for this address, regardless of status
        return _marketplaceIdByAddress[_contractAddress] != 0;
    }

    function getModerators() external view returns (address[] memory) {
        // Cannot iterate mapping directly. Need a separate list of moderators if this must be on-chain.
        // Returning a placeholder or requiring off-chain lookup for a full list.
        // For demonstration, we'll just show the concept. In a real contract needing this,
        // maintain an array of moderators alongside the mapping.
        // Example: Maintain `address[] public moderatorList;` and update it.
        // Placeholder return:
        return new address[](0); // Requires off-chain tracking or a list state var
    }

    function getRegistrationFee() external view returns (uint256) {
        return _registrationFee;
    }

    function getRecognizedStandards() external view returns (bytes32[] memory) {
        // Cannot iterate mapping directly. Need a separate list state var.
        // Placeholder return:
         return new bytes32[](0); // Requires off-chain tracking or a list state var
    }

    function getRecognizedFeatures() external view returns (bytes32[] memory) {
        // Cannot iterate mapping directly. Need a separate list state var.
        // Placeholder return:
        return new bytes32[](0); // Requires off-chain tracking or a list state var
    }

    function getRelatedMarketplaces(uint256 _marketplaceId) external view marketplaceMustExist(_marketplaceId) returns (bytes32[] memory relationshipTypes, uint255[][] memory relatedIds) {
        // Returns relationship types and the list of linked IDs for each type FROM _marketplaceId
        relationshipTypes = _linkedRelationshipTypes[_marketplaceId];
        relatedIds = new uint255[][](relationshipTypes.length);

        for(uint i = 0; i < relationshipTypes.length; i++) {
            relatedIds[i] = _linkedMarketplaceIds[_marketplaceId][relationshipTypes[i]];
        }
        return (relationshipTypes, relatedIds);
    }

    function getPendingProposedUpdate(uint256 _marketplaceId) external view marketplaceMustExist(_marketplaceId) returns (ProposedUpdate memory) {
         require(_marketplaces[_marketplaceId].proposedUpdateId != 0, "No pending update for this marketplace");
         return _pendingProposedUpdates[_marketplaces[_marketplaceId].proposedUpdateId];
    }

    // Helper function to get marketplace status (useful for off-chain)
    function getMarketplaceStatus(uint256 _marketplaceId) external view returns (MarketplaceStatus) {
        if (_marketplaceId == 0 || _marketplaceId >= _nextMarketplaceId) return MarketplaceStatus.None;
        return _marketplaces[_marketplaceId].status;
    }
}
```