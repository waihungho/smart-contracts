This smart contract, named `NexusIntellect`, introduces a novel concept for decentralized knowledge management. It focuses on "Knowledge Units" (K-Units), which are essentially dynamic NFTs representing pieces of knowledge, data, or intellectual property. Unlike static NFTs, K-Units are designed for continuous evolution, granular access control, and collaborative development, all underpinned by an integrated reputation system.

The core idea is to create a mesh where valuable information can be owned, licensed, updated, and validated in a decentralized manner, fostering a community-driven approach to intellectual property.

---

## Outline: NexusIntellect - A Decentralized Knowledge Mesh Protocol

This contract facilitates the creation, ownership, dynamic access, and collaborative evolution of "Knowledge Units" (K-Units). K-Units are non-fungible digital assets representing pieces of knowledge, data, or intellectual property. Unlike traditional NFTs, K-Units are designed for dynamic content updates, granular access control, and integrated reputation systems to ensure quality and value.

**I. Core K-Unit Management & Ownership (Functions 1-5)**
Manages the creation, metadata updates, transfer, and retrieval of K-Units. K-Units function like extended NFTs, with a focus on linked content hashes (IPFS/Arweave CIDs) that can change over time.

**II. Dynamic Access & Licensing (Functions 6-10)**
Allows K-Unit owners to define flexible access policies (free, paid, subscription, reputation-gated, collaborator-only). Users can purchase access, and owners can grant specific collaborator rights.

**III. Reputation & Quality Assurance (Functions 11-14)**
Enables users with access to review K-Units, influencing their ratings. Includes a foundational reputation system for users, which can be rewarded by the protocol for valuable contributions, potentially gating access to premium content.

**IV. Collaboration & Version Control (Functions 15-18)**
Supports collaborative development of K-Units. Collaborators can propose content updates, which the K-Unit owner must approve to become active, with a full version history maintained.

**V. Advanced & Protocol-Level Operations (Functions 19-20)**
Includes basic protocol governance for setting fee rates and withdrawing protocol fees, demonstrating a path towards decentralized governance.

---

## Function Summary

**I. Core K-Unit Management & Ownership**

1.  `createKnowledgeUnit(string calldata _name, string calldata _descriptionCID, string[] calldata _tags, string calldata _initialContentCID)`
    *   Mints a new Knowledge Unit (K-Unit) and assigns ownership to the caller.
    *   Stores initial metadata (name, description CID) and the first content hash (e.g., IPFS/Arweave CID).
2.  `updateKnowledgeUnitMetadata(uint256 _kUnitId, string calldata _newName, string calldata _newDescriptionCID, string[] calldata _newTags)`
    *   Allows the owner of a K-Unit to update its non-content metadata (name, description, tags).
3.  `transferKnowledgeUnit(address _from, address _to, uint256 _kUnitId)`
    *   Transfers ownership of a K-Unit from one address to another. Custom-implemented for this contract's specific context.
4.  `getKnowledgeUnitDetails(uint256 _kUnitId) view`
    *   Retrieves the core details (ID, name, owner, description CID, active content hash, tags, creation/update timestamps, average rating) of a K-Unit.
5.  `getKnowledgeUnitContentHash(uint256 _kUnitId) view`
    *   Returns the current active IPFS/Arweave CID for the content associated with a K-Unit.

**II. Dynamic Access & Licensing**

6.  `setAccessPolicy(uint256 _kUnitId, AccessPolicyType _policyType, uint256 _priceOrDuration, uint256 _minReputation)`
    *   Sets the access rules for a specific K-Unit. Can be free, pay-per-access (one-time), subscription-based (time-based), reputation-gated, or collaboration-only.
7.  `purchaseAccess(uint256 _kUnitId) payable`
    *   Allows a user to purchase access to a K-Unit based on its defined policy. Handles payment, protocol fees, and grants time-based or perpetual access.
8.  `grantCollaboratorAccess(uint256 _kUnitId, address _collaboratorAddress)`
    *   K-Unit owner grants an address collaborator status, allowing them to propose content updates.
9.  `revokeCollaboratorAccess(uint256 _kUnitId, address _collaboratorAddress)`
    *   K-Unit owner revokes collaborator status from an address.
10. `checkAccess(uint256 _kUnitId, address _user) view`
    *   Checks if a given user currently has access to a K-Unit based on its policy and granted access.

**III. Reputation & Quality Assurance**

11. `submitReview(uint256 _kUnitId, uint8 _rating, string calldata _reviewCID)`
    *   Allows users with access to a K-Unit to submit a review and rating (1-5 stars). Contributes to the K-Unit's average rating.
12. `getAverageRating(uint256 _kUnitId) view`
    *   Returns the calculated average rating for a specific K-Unit based on submitted reviews.
13. `getUserReputation(address _user) view`
    *   Retrieves the cumulative reputation score for a given user address.
14. `rewardReputation(address _user, uint256 _points, string calldata _reasonCID)`
    *   Protocol/Admin function to reward users with reputation points for valuable contributions.

**IV. Collaboration & Version Control**

15. `proposeContentUpdate(uint256 _kUnitId, string calldata _newContentCID, string calldata _rationaleCID)`
    *   A collaborator proposes an update to the content of a K-Unit. The proposal is pending owner approval.
16. `approveContentUpdate(uint256 _kUnitId, uint256 _proposalId)`
    *   K-Unit owner approves a pending content update proposal, making the new content CID active. The previous content CID is added to the version history.
17. `rejectContentUpdate(uint256 _kUnitId, uint256 _proposalId)`
    *   K-Unit owner rejects a pending content update proposal.
18. `getVersionHistory(uint256 _kUnitId) view`
    *   Retrieves a list of all historical content versions (CIDs) for a K-Unit, including their timestamps and contributing addresses.

**V. Advanced & Protocol-Level Operations**

19. `setProtocolFeeRate(uint256 _newFeePermil)`
    *   Sets the protocol fee rate (in permil, e.g., 100 for 10%) on access purchases. Callable by admin/governance.
20. `withdrawProtocolFees(address _to)`
    *   Allows the protocol treasury to withdraw accumulated fees to a specified address. Callable by admin/governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NexusIntellect {
    // --- State Variables ---

    // The address designated as the contract admin, responsible for
    // protocol-level configurations (e.g., fee rates, rewarding reputation).
    // In a production environment, this would likely be a DAO or a multisig.
    address public admin;

    // Counter for generating unique Knowledge Unit IDs.
    uint256 private _nextKUnitId;

    // Structure to hold the core data of a Knowledge Unit.
    struct KnowledgeUnit {
        string name;                // Human-readable name of the K-Unit.
        string descriptionCID;      // IPFS/Arweave CID for a detailed description.
        string[] tags;              // Keywords for categorization and search.
        address owner;              // Address of the current owner of the K-Unit.
        string activeContentCID;    // IPFS/Arweave CID for the current active content.
        uint256 createdAt;          // Timestamp of K-Unit creation.
        uint256 lastUpdatedAt;      // Timestamp of the last content or metadata update.
        uint256 totalRating;        // Sum of all review ratings received.
        uint256 numReviews;         // Count of reviews submitted.
    }
    // Mapping from K-Unit ID to its KnowledgeUnit struct.
    mapping(uint256 => KnowledgeUnit) public kUnits;
    // Mapping from owner address to an array of K-Unit IDs they own.
    mapping(address => uint256[]) public ownerKUnits;

    // Enum defining different types of access policies for a K-Unit.
    enum AccessPolicyType {
        Free,                 // Content is freely accessible to everyone.
        PayPerAccess,         // One-time payment grants perpetual access.
        Subscription,         // Recurring payment (or a single payment for duration) grants time-based access.
        ReputationGated,      // Access requires a minimum reputation score.
        CollaborationOnly     // Only explicit collaborators can access the content.
    }

    // Structure to define the access rules for a K-Unit.
    struct AccessPolicy {
        AccessPolicyType policyType;     // The type of access policy.
        uint256 price;                   // For PayPerAccess/Subscription (in wei).
        uint256 subscriptionDuration;    // For Subscription (in seconds).
        uint256 minReputation;           // For ReputationGated.
    }
    // Mapping from K-Unit ID to its AccessPolicy.
    mapping(uint256 => AccessPolicy) public kUnitAccessPolicies;

    // Structure to record a user's access grant to a K-Unit.
    struct AccessGrant {
        bool hasAccess;         // True if the user has access.
        uint256 validUntil;     // Timestamp for subscription expiry. `type(uint256).max` for perpetual access, 0 for no access or expired.
    }
    // Mapping from K-Unit ID to user address to their AccessGrant.
    mapping(uint256 => mapping(address => AccessGrant)) public userAccesses;

    // Mapping to track collaborators for each K-Unit.
    // kUnitId => collaboratorAddress => true/false
    mapping(uint256 => mapping(address => bool)) public collaborators;

    // Mapping to store the reputation score for each user.
    // userAddress => total reputation score
    mapping(address => uint256) public reputations;

    // Structure for a proposed content update.
    struct ContentUpdateProposal {
        uint256 proposalId;         // Unique ID for the proposal within the K-Unit.
        string newContentCID;       // IPFS/Arweave CID for the proposed new content.
        string rationaleCID;        // IPFS/Arweave CID for the explanation/justification of the update.
        address proposer;           // Address of the user who proposed the update.
        uint256 proposedAt;         // Timestamp when the proposal was made.
        bool approved;              // True if the proposal has been approved by the owner.
        bool rejected;              // True if the proposal has been rejected by the owner.
    }
    // Mapping from K-Unit ID to an array of its content update proposals.
    mapping(uint256 => ContentUpdateProposal[]) public kUnitUpdateProposals;
    // Counter for unique proposal IDs within each K-Unit.
    mapping(uint256 => uint256) private _nextProposalId;

    // Structure for storing historical versions of K-Unit content.
    struct ContentVersion {
        string contentCID;      // The IPFS/Arweave CID of the historical content.
        uint256 timestamp;      // When this version became active.
        address contributor;    // The address responsible for this version becoming active (owner or approver).
        string rationaleCID;    // Rationale for this version, if available from a proposal.
    }
    // Mapping from K-Unit ID to an array of its content version history.
    mapping(uint256 => ContentVersion[]) public kUnitVersionHistory;

    // Protocol Fees
    uint256 public protocolFeeRatePermil; // Fee rate in permil (parts per thousand, e.g., 50 = 5%).
    address public protocolTreasury;      // Address where protocol fees are accumulated.
    uint256 public totalProtocolFeesCollected; // Total fees collected by the protocol.

    // --- Events ---
    event KUnitCreated(uint256 indexed kUnitId, address indexed owner, string name, string initialContentCID);
    event KUnitMetadataUpdated(uint256 indexed kUnitId, address indexed updater, string newName);
    event KUnitTransferred(uint256 indexed kUnitId, address indexed from, address indexed to);
    event AccessPolicySet(uint256 indexed kUnitId, AccessPolicyType policyType, uint256 priceOrDuration, uint256 minReputation);
    event AccessPurchased(uint256 indexed kUnitId, address indexed purchaser, uint256 validUntil);
    event CollaboratorGranted(uint256 indexed kUnitId, address indexed owner, address indexed collaborator);
    event CollaboratorRevoked(uint256 indexed kUnitId, address indexed owner, address indexed collaborator);
    event ReviewSubmitted(uint256 indexed kUnitId, address indexed reviewer, uint8 rating, string reviewCID);
    event ReputationRewarded(address indexed user, uint256 points, string reasonCID);
    event ContentUpdateProposed(uint256 indexed kUnitId, uint256 indexed proposalId, address indexed proposer, string newContentCID);
    event ContentUpdateApproved(uint256 indexed kUnitId, uint256 indexed proposalId, address indexed approver, string newContentCID);
    event ContentUpdateRejected(uint256 indexed kUnitId, uint256 indexed proposalId, address indexed rejector);
    event ProtocolFeeRateUpdated(uint256 newRatePermil);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "NexusIntellect: Only admin can call this function");
        _;
    }

    modifier onlyKUnitOwner(uint256 _kUnitId) {
        require(kUnits[_kUnitId].owner == msg.sender, "NexusIntellect: Only K-Unit owner can call this function");
        _;
    }

    modifier onlyCollaborator(uint256 _kUnitId) {
        require(
            kUnits[_kUnitId].owner == msg.sender || collaborators[_kUnitId][msg.sender],
            "NexusIntellect: Only K-Unit owner or collaborator can call this function"
        );
        _;
    }

    // --- Constructor ---
    constructor(address _protocolTreasury) {
        admin = msg.sender; // Deployer is the initial admin
        protocolTreasury = _protocolTreasury;
        protocolFeeRatePermil = 50; // Initial protocol fee: 5% (50 permil)
        _nextKUnitId = 1;
    }

    // --- I. Core K-Unit Management & Ownership ---

    /**
     * @notice Mints a new Knowledge Unit (K-Unit) and assigns ownership to the caller.
     *         Stores initial metadata (name, description CID) and the first content hash.
     * @param _name The human-readable name of the K-Unit.
     * @param _descriptionCID IPFS/Arweave CID pointing to a detailed description of the K-Unit.
     * @param _tags An array of keywords or tags for categorization.
     * @param _initialContentCID IPFS/Arweave CID pointing to the initial content of the K-Unit.
     * @return The ID of the newly created K-Unit.
     */
    function createKnowledgeUnit(
        string calldata _name,
        string calldata _descriptionCID,
        string[] calldata _tags,
        string calldata _initialContentCID
    ) external returns (uint256) {
        require(bytes(_name).length > 0, "NexusIntellect: Name cannot be empty");
        require(bytes(_initialContentCID).length > 0, "NexusIntellect: Initial content CID cannot be empty");

        uint256 kUnitId = _nextKUnitId++;
        kUnits[kUnitId] = KnowledgeUnit({
            name: _name,
            descriptionCID: _descriptionCID,
            tags: _tags,
            owner: msg.sender,
            activeContentCID: _initialContentCID,
            createdAt: block.timestamp,
            lastUpdatedAt: block.timestamp,
            totalRating: 0,
            numReviews: 0
        });
        ownerKUnits[msg.sender].push(kUnitId);

        // Record the initial content as the first version in history.
        kUnitVersionHistory[kUnitId].push(ContentVersion({
            contentCID: _initialContentCID,
            timestamp: block.timestamp,
            contributor: msg.sender,
            rationaleCID: "" // No specific rationale for initial version
        }));

        emit KUnitCreated(kUnitId, msg.sender, _name, _initialContentCID);
        return kUnitId;
    }

    /**
     * @notice Allows the owner of a K-Unit to update its non-content metadata.
     * @param _kUnitId The ID of the K-Unit to update.
     * @param _newName The new human-readable name.
     * @param _newDescriptionCID The new IPFS/Arweave CID for the detailed description.
     * @param _newTags The new array of keywords or tags.
     */
    function updateKnowledgeUnitMetadata(
        uint256 _kUnitId,
        string calldata _newName,
        string calldata _newDescriptionCID,
        string[] calldata _newTags
    ) external onlyKUnitOwner(_kUnitId) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");
        require(bytes(_newName).length > 0, "NexusIntellect: Name cannot be empty");

        KnowledgeUnit storage kUnit = kUnits[_kUnitId];
        kUnit.name = _newName;
        kUnit.descriptionCID = _newDescriptionCID;
        kUnit.tags = _newTags;
        kUnit.lastUpdatedAt = block.timestamp;

        emit KUnitMetadataUpdated(_kUnitId, msg.sender, _newName);
    }

    /**
     * @notice Transfers ownership of a K-Unit from one address to another.
     * @param _from The current owner's address.
     * @param _to The address of the new owner.
     * @param _kUnitId The ID of the K-Unit to transfer.
     */
    function transferKnowledgeUnit(address _from, address _to, uint256 _kUnitId) external {
        // Allow either the current owner or an approved operator (msg.sender) to initiate transfer.
        // For simplicity, this contract allows only the owner or the `_from` address itself to call this.
        require(msg.sender == _from || msg.sender == kUnits[_kUnitId].owner, "NexusIntellect: Not authorized to transfer");
        require(_to != address(0), "NexusIntellect: Transfer to the zero address");
        require(kUnits[_kUnitId].owner == _from, "NexusIntellect: _from is not the current owner");

        // Remove K-Unit ID from the old owner's list
        uint256[] storage fromKUnits = ownerKUnits[_from];
        for (uint256 i = 0; i < fromKUnits.length; i++) {
            if (fromKUnits[i] == _kUnitId) {
                fromKUnits[i] = fromKUnits[fromKUnits.length - 1]; // Replace with last element
                fromKUnits.pop(); // Remove last element
                break;
            }
        }

        kUnits[_kUnitId].owner = _to; // Update K-Unit's owner
        ownerKUnits[_to].push(_kUnitId); // Add K-Unit ID to the new owner's list

        emit KUnitTransferred(_kUnitId, _from, _to);
    }

    /**
     * @notice Retrieves the core details of a K-Unit.
     * @param _kUnitId The ID of the K-Unit.
     * @return name, descriptionCID, tags, owner, activeContentCID, createdAt, lastUpdatedAt, averageRating
     */
    function getKnowledgeUnitDetails(uint256 _kUnitId)
        external
        view
        returns (
            string memory name,
            string memory descriptionCID,
            string[] memory tags,
            address owner,
            string memory activeContentCID,
            uint256 createdAt,
            uint256 lastUpdatedAt,
            uint256 averageRating
        )
    {
        KnowledgeUnit storage kUnit = kUnits[_kUnitId];
        require(bytes(kUnit.name).length > 0, "NexusIntellect: K-Unit does not exist");

        averageRating = kUnit.numReviews > 0 ? kUnit.totalRating / kUnit.numReviews : 0;

        return (
            kUnit.name,
            kUnit.descriptionCID,
            kUnit.tags,
            kUnit.owner,
            kUnit.activeContentCID,
            kUnit.createdAt,
            kUnit.lastUpdatedAt,
            averageRating
        );
    }

    /**
     * @notice Returns the current active IPFS/Arweave CID for the content of a K-Unit.
     * @param _kUnitId The ID of the K-Unit.
     * @return The active content CID.
     */
    function getKnowledgeUnitContentHash(uint256 _kUnitId) external view returns (string memory) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");
        return kUnits[_kUnitId].activeContentCID;
    }

    // --- II. Dynamic Access & Licensing ---

    /**
     * @notice Sets the access rules for a specific K-Unit.
     * @param _kUnitId The ID of the K-Unit.
     * @param _policyType The type of access policy (Free, PayPerAccess, Subscription, ReputationGated, CollaborationOnly).
     * @param _priceOrDuration For PayPerAccess/Subscription, this is the price in wei. For Subscription, it's also the duration in seconds.
     * @param _minReputation For ReputationGated, this is the minimum reputation score required.
     */
    function setAccessPolicy(
        uint256 _kUnitId,
        AccessPolicyType _policyType,
        uint256 _priceOrDuration,
        uint256 _minReputation
    ) external onlyKUnitOwner(_kUnitId) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");

        if (_policyType == AccessPolicyType.PayPerAccess) {
            require(_priceOrDuration > 0, "NexusIntellect: Price must be greater than zero for PayPerAccess");
        } else if (_policyType == AccessPolicyType.Subscription) {
            require(_priceOrDuration > 0, "NexusIntellect: Price and duration must be greater than zero for Subscription");
        } else if (_policyType == AccessPolicyType.ReputationGated) {
            require(_minReputation > 0, "NexusIntellect: Minimum reputation must be greater than zero for ReputationGated");
        }

        kUnitAccessPolicies[_kUnitId] = AccessPolicy({
            policyType: _policyType,
            price: (_policyType == AccessPolicyType.PayPerAccess || _policyType == AccessPolicyType.Subscription) ? _priceOrDuration : 0,
            subscriptionDuration: (_policyType == AccessPolicyType.Subscription) ? _priceOrDuration : 0, // Re-use _priceOrDuration as duration for subscription
            minReputation: (_policyType == AccessPolicyType.ReputationGated) ? _minReputation : 0
        });

        emit AccessPolicySet(_kUnitId, _policyType, _priceOrDuration, _minReputation);
    }

    /**
     * @notice Allows a user to purchase access to a K-Unit based on its defined policy.
     *         Handles payment and grants time-based or one-time (perpetual) access.
     * @param _kUnitId The ID of the K-Unit.
     */
    function purchaseAccess(uint256 _kUnitId) external payable {
        KnowledgeUnit storage kUnit = kUnits[_kUnitId];
        require(bytes(kUnit.name).length > 0, "NexusIntellect: K-Unit does not exist");
        AccessPolicy storage policy = kUnitAccessPolicies[_kUnitId];
        require(policy.policyType == AccessPolicyType.PayPerAccess || policy.policyType == AccessPolicyType.Subscription,
                "NexusIntellect: This K-Unit is not configured for purchase");

        uint256 accessValidUntil = 0; // 0 means no access initially

        if (policy.policyType == AccessPolicyType.PayPerAccess) {
            require(msg.value >= policy.price, "NexusIntellect: Insufficient payment for one-time access");
            accessValidUntil = type(uint256).max; // Perpetual access
        } else if (policy.policyType == AccessPolicyType.Subscription) {
            require(msg.value >= policy.price, "NexusIntellect: Insufficient payment for subscription");
            // If user already has access, extend it; otherwise, start new.
            uint256 currentValidUntil = userAccesses[_kUnitId][msg.sender].validUntil;
            uint256 startFrom = (currentValidUntil > block.timestamp) ? currentValidUntil : block.timestamp;
            accessValidUntil = startFrom + policy.subscriptionDuration;
        }

        uint256 protocolFee = (msg.value * protocolFeeRatePermil) / 1000;
        uint256 ownerPayment = msg.value - protocolFee;

        // Transfer funds
        if (ownerPayment > 0) {
            // It's important to use a low-level call or check `transfer` result in a more complex scenario.
            // For this example, `transfer` is sufficient, but it has a gas limit of 2300, which is generally safe.
            (bool success, ) = payable(kUnit.owner).call{value: ownerPayment}("");
            require(success, "NexusIntellect: Failed to transfer funds to K-Unit owner");
        }
        if (protocolFee > 0) {
            totalProtocolFeesCollected += protocolFee;
        }

        userAccesses[_kUnitId][msg.sender] = AccessGrant({
            hasAccess: true,
            validUntil: accessValidUntil
        });

        emit AccessPurchased(_kUnitId, msg.sender, accessValidUntil);
    }

    /**
     * @notice K-Unit owner grants an address collaborator status, allowing them to propose content updates.
     * @param _kUnitId The ID of the K-Unit.
     * @param _collaboratorAddress The address to grant collaborator status to.
     */
    function grantCollaboratorAccess(uint256 _kUnitId, address _collaboratorAddress) external onlyKUnitOwner(_kUnitId) {
        require(_collaboratorAddress != address(0), "NexusIntellect: Cannot grant collaborator access to zero address");
        require(_collaboratorAddress != msg.sender, "NexusIntellect: Cannot grant collaborator access to self");
        require(!collaborators[_kUnitId][_collaboratorAddress], "NexusIntellect: Address is already a collaborator");

        collaborators[_kUnitId][_collaboratorAddress] = true;
        emit CollaboratorGranted(_kUnitId, msg.sender, _collaboratorAddress);
    }

    /**
     * @notice K-Unit owner revokes collaborator status from an address.
     * @param _kUnitId The ID of the K-Unit.
     * @param _collaboratorAddress The address to revoke collaborator status from.
     */
    function revokeCollaboratorAccess(uint256 _kUnitId, address _collaboratorAddress) external onlyKUnitOwner(_kUnitId) {
        require(collaborators[_kUnitId][_collaboratorAddress], "NexusIntellect: Address is not a collaborator");
        collaborators[_kUnitId][_collaboratorAddress] = false;
        emit CollaboratorRevoked(_kUnitId, msg.sender, _collaboratorAddress);
    }

    /**
     * @notice Checks if a given user currently has access to a K-Unit.
     * @param _kUnitId The ID of the K-Unit.
     * @param _user The address of the user to check access for.
     * @return True if the user has access, false otherwise.
     */
    function checkAccess(uint256 _kUnitId, address _user) public view returns (bool) {
        KnowledgeUnit storage kUnit = kUnits[_kUnitId];
        require(bytes(kUnit.name).length > 0, "NexusIntellect: K-Unit does not exist");

        // Owner always has access
        if (_user == kUnit.owner) {
            return true;
        }

        AccessPolicy storage policy = kUnitAccessPolicies[_kUnitId];

        // Check explicit grants
        AccessGrant storage grant = userAccesses[_kUnitId][_user];
        if (grant.hasAccess) {
            if (grant.validUntil == type(uint256).max) {
                return true; // Perpetual access
            }
            if (grant.validUntil > block.timestamp) {
                return true; // Subscription access is active
            }
        }

        // Check policy-based access
        if (policy.policyType == AccessPolicyType.Free) {
            return true;
        } else if (policy.policyType == AccessPolicyType.ReputationGated) {
            return reputations[_user] >= policy.minReputation;
        } else if (policy.policyType == AccessPolicyType.CollaborationOnly) {
            return collaborators[_kUnitId][_user];
        }

        // For PayPerAccess and Subscription, access must be purchased and is covered by userAccesses check.
        return false;
    }

    // --- III. Reputation & Quality Assurance ---

    /**
     * @notice Allows users with access to a K-Unit to submit a review and rating (1-5 stars).
     * @param _kUnitId The ID of the K-Unit.
     * @param _rating The rating given (1-5).
     * @param _reviewCID IPFS/Arweave CID pointing to the full review text.
     */
    function submitReview(uint256 _kUnitId, uint8 _rating, string calldata _reviewCID) external {
        require(checkAccess(_kUnitId, msg.sender), "NexusIntellect: User does not have access to review this K-Unit");
        require(_rating >= 1 && _rating <= 5, "NexusIntellect: Rating must be between 1 and 5");
        require(bytes(_reviewCID).length > 0, "NexusIntellect: Review CID cannot be empty");

        KnowledgeUnit storage kUnit = kUnits[_kUnitId];
        require(bytes(kUnit.name).length > 0, "NexusIntellect: K-Unit does not exist"); // Ensure K-Unit exists

        kUnit.totalRating += _rating;
        kUnit.numReviews++;

        // In a more advanced system, this could also update the reviewer's reputation
        // or the creator's reputation based on the review. For simplicity, we only
        // update the K-Unit's rating here.

        emit ReviewSubmitted(_kUnitId, msg.sender, _rating, _reviewCID);
    }

    /**
     * @notice Returns the calculated average rating for a specific K-Unit.
     * @param _kUnitId The ID of the K-Unit.
     * @return The average rating (0 if no reviews).
     */
    function getAverageRating(uint256 _kUnitId) external view returns (uint256) {
        KnowledgeUnit storage kUnit = kUnits[_kUnitId];
        require(bytes(kUnit.name).length > 0, "NexusIntellect: K-Unit does not exist");
        if (kUnit.numReviews == 0) {
            return 0;
        }
        return kUnit.totalRating / kUnit.numReviews;
    }

    /**
     * @notice Retrieves the cumulative reputation score for a given user address.
     * @param _user The address of the user.
     * @return The reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return reputations[_user];
    }

    /**
     * @notice Protocol/Admin function to reward users with reputation points for valuable contributions
     *         (e.g., moderating, community support, high-quality content outside K-Units).
     * @param _user The address of the user to reward.
     * @param _points The number of reputation points to grant.
     * @param _reasonCID IPFS/Arweave CID explaining the reason for the reputation reward.
     */
    function rewardReputation(address _user, uint256 _points, string calldata _reasonCID) external onlyAdmin {
        require(_user != address(0), "NexusIntellect: Cannot reward zero address");
        require(_points > 0, "NexusIntellect: Points must be positive");
        
        reputations[_user] += _points;
        emit ReputationRewarded(_user, _points, _reasonCID);
    }

    // --- IV. Collaboration & Version Control ---

    /**
     * @notice A collaborator proposes an update to the content of a K-Unit.
     *         The proposal is pending owner approval.
     * @param _kUnitId The ID of the K-Unit.
     * @param _newContentCID IPFS/Arweave CID pointing to the new content.
     * @param _rationaleCID IPFS/Arweave CID explaining the reason for the update.
     * @return The ID of the created proposal.
     */
    function proposeContentUpdate(
        uint256 _kUnitId,
        string calldata _newContentCID,
        string calldata _rationaleCID
    ) external onlyCollaborator(_kUnitId) returns (uint256) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");
        require(bytes(_newContentCID).length > 0, "NexusIntellect: New content CID cannot be empty");
        require(bytes(_rationaleCID).length > 0, "NexusIntellect: Rationale CID cannot be empty");
        require(
            keccak256(abi.encodePacked(kUnits[_kUnitId].activeContentCID)) != keccak256(abi.encodePacked(_newContentCID)),
            "NexusIntellect: Proposed content is identical to the current active version"
        );

        uint256 proposalId = _nextProposalId[_kUnitId]++;
        kUnitUpdateProposals[_kUnitId].push(ContentUpdateProposal({
            proposalId: proposalId,
            newContentCID: _newContentCID,
            rationaleCID: _rationaleCID,
            proposer: msg.sender,
            proposedAt: block.timestamp,
            approved: false,
            rejected: false
        }));

        emit ContentUpdateProposed(_kUnitId, proposalId, msg.sender, _newContentCID);
        return proposalId;
    }

    /**
     * @notice K-Unit owner approves a pending content update proposal, making the new content CID active.
     *         The previous content CID is added to the version history.
     * @param _kUnitId The ID of the K-Unit.
     * @param _proposalId The ID of the proposal to approve.
     */
    function approveContentUpdate(uint256 _kUnitId, uint256 _proposalId) external onlyKUnitOwner(_kUnitId) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");
        require(_proposalId < kUnitUpdateProposals[_kUnitId].length, "NexusIntellect: Invalid proposal ID");

        ContentUpdateProposal storage proposal = kUnitUpdateProposals[_kUnitId][_proposalId];
        require(!proposal.approved && !proposal.rejected, "NexusIntellect: Proposal already processed");
        require(bytes(proposal.newContentCID).length > 0, "NexusIntellect: Proposal content CID is empty");
        
        // Add current active content to history before updating
        kUnitVersionHistory[_kUnitId].push(ContentVersion({
            contentCID: kUnits[_kUnitId].activeContentCID,
            timestamp: kUnits[_kUnitId].lastUpdatedAt,
            contributor: kUnits[_kUnitId].owner, // Previous active content was set by owner or approved by owner
            rationaleCID: "" // No specific rationale for historical snapshot beyond being the active version prior to this update
        }));

        kUnits[_kUnitId].activeContentCID = proposal.newContentCID;
        kUnits[_kUnitId].lastUpdatedAt = block.timestamp;
        proposal.approved = true;

        // Add the approved proposal's content as a new version with its specific rationale
        kUnitVersionHistory[_kUnitId].push(ContentVersion({
            contentCID: proposal.newContentCID,
            timestamp: block.timestamp,
            contributor: msg.sender, // The owner approved it
            rationaleCID: proposal.rationaleCID
        }));

        emit ContentUpdateApproved(_kUnitId, _proposalId, msg.sender, proposal.newContentCID);
    }

    /**
     * @notice K-Unit owner rejects a pending content update proposal.
     * @param _kUnitId The ID of the K-Unit.
     * @param _proposalId The ID of the proposal to reject.
     */
    function rejectContentUpdate(uint256 _kUnitId, uint256 _proposalId) external onlyKUnitOwner(_kUnitId) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");
        require(_proposalId < kUnitUpdateProposals[_kUnitId].length, "NexusIntellect: Invalid proposal ID");

        ContentUpdateProposal storage proposal = kUnitUpdateProposals[_kUnitId][_proposalId];
        require(!proposal.approved && !proposal.rejected, "NexusIntellect: Proposal already processed");

        proposal.rejected = true;
        emit ContentUpdateRejected(_kUnitId, _proposalId, msg.sender);
    }

    /**
     * @notice Retrieves a list of all historical content versions (CIDs) for a K-Unit.
     * @param _kUnitId The ID of the K-Unit.
     * @return An array of `ContentVersion` structs.
     */
    function getVersionHistory(uint256 _kUnitId) external view returns (ContentVersion[] memory) {
        require(bytes(kUnits[_kUnitId].name).length > 0, "NexusIntellect: K-Unit does not exist");
        return kUnitVersionHistory[_kUnitId];
    }

    // --- V. Advanced & Protocol-Level Operations ---

    /**
     * @notice Sets the protocol fee rate (in permil, e.g., 100 for 10%). Callable by admin/governance.
     *         This fee is taken from `purchaseAccess` transactions.
     * @param _newFeePermil The new fee rate in permil (0-1000, where 1000 is 100%).
     */
    function setProtocolFeeRate(uint256 _newFeePermil) external onlyAdmin {
        require(_newFeePermil <= 1000, "NexusIntellect: Fee rate cannot exceed 1000 permil (100%)");
        protocolFeeRatePermil = _newFeePermil;
        emit ProtocolFeeRateUpdated(_newFeePermil);
    }

    /**
     * @notice Allows the protocol treasury to withdraw accumulated fees to a specified address.
     *         Callable by admin/governance.
     * @param _to The address to send the withdrawn fees to.
     */
    function withdrawProtocolFees(address _to) external onlyAdmin {
        require(_to != address(0), "NexusIntellect: Cannot withdraw to zero address");
        require(totalProtocolFeesCollected > 0, "NexusIntellect: No fees to withdraw");

        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0; // Reset collected fees

        // It's important to use a low-level call or check `transfer` result in a more complex scenario.
        (bool success, ) = payable(_to).call{value: amount}("");
        require(success, "NexusIntellect: Failed to withdraw protocol fees");
        
        emit ProtocolFeesWithdrawn(_to, amount);
    }
}
```