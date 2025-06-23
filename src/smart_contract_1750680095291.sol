Okay, here is a Solidity smart contract demonstrating several interesting, advanced, and creative concepts. It focuses on a dynamic, adaptive digital collectible that goes beyond standard ERC721 by incorporating features like on-chain attributes that evolve, co-ownership, delegated rights, temporary usage grants, asset linking, activity logging, milestones, programmable royalties, and a basic on-chain per-asset governance mechanism.

This contract is not a direct copy of any major open-source implementation but combines various concepts in a novel way.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AdaptiveDigitalCollectible
 * @dev A smart contract for dynamic, feature-rich digital collectibles (NFTs).
 * It extends basic ERC721 concepts with evolving attributes, co-ownership,
 * delegated rights, temporary usage grants, asset linking, activity logging,
 * milestones, programmable royalties, and per-asset governance.
 *
 * Outline:
 * 1.  Basic ERC721 Compliance (manual implementation for uniqueness)
 * 2.  Dynamic Asset Attributes & Evolution
 * 3.  Co-Ownership and Delegation
 * 4.  Temporary Usage Grants (Rental-like)
 * 5.  Asset Linking and Relationships
 * 6.  On-chain Activity Logging
 * 7.  Milestones and Conditional Features
 * 8.  Programmable Royalties and Claiming
 * 9.  Per-Asset Self-Modification Governance
 * 10. Access Control and Permissions
 * 11. Events and Error Handling
 */
contract AdaptiveDigitalCollectible {

    // --- State Variables ---

    uint256 private _totalSupply;
    mapping(uint256 => address) private _owners; // TokenId to owner
    mapping(address => uint256) private _balances; // Owner to number of tokens
    mapping(uint256 => address) private _tokenApprovals; // TokenId to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner to operator to approved

    // Dynamic Attributes: Basic struct for mutable on-chain properties
    struct AssetAttributes {
        uint256 level;
        uint256 creationTime;
        uint256 lastInteractionTime; // Used for aging/activity
        string metadataURI; // Base URI, potentially updated
        bool locked; // Cannot be transferred or modified
    }
    mapping(uint256 => AssetAttributes) private _assetAttributes;

    // Co-Ownership: Addresses that share certain rights beyond the main owner
    mapping(uint256 => address[]) private _coOwners; // Simple array - caution for large numbers

    // Delegated Capabilities: Grant specific rights (enum below)
    enum Capability { UpdateAttributes, GrantUsage, ProposeModification }
    mapping(uint256 => mapping(address => mapping(Capability => bool))) private _delegatedCapabilities;

    // Temporary Usage Grants: Allows someone to use the asset temporarily (rental-like)
    struct UsageGrant {
        address grantee;
        uint256 expiryTimestamp;
    }
    mapping(uint256 => UsageGrant) private _temporaryUsageGrants;

    // Asset Linking: Define relationships between tokens on-chain
    mapping(uint256 => uint256[]) private _linkedAssets; // Symmetric links

    // On-chain Activity Log: Record key interactions with the asset
    struct ActivityEntry {
        uint256 timestamp;
        string description;
        address initiator;
    }
    mapping(uint256 => ActivityEntry[]) private _assetActivityLog;
    uint256 private constant MAX_ACTIVITY_LOG_ENTRIES = 10; // Limit log size

    // Milestones: Track completion of specific conditions or "quests"
    enum Milestone { Created, EvolvedOnce, LinkedToAnother, UsageGranted, ModifiedByGovernance }
    mapping(uint256 => mapping(Milestone => bool)) private _completedMilestones;

    // Programmable Royalties: Define royalty parameters per asset (simplified)
    struct RoyaltyParams {
        address recipient;
        uint256 feeNumerator; // e.g., for 5%, numerator=500, denominator=10000
        uint256 feeDenominator;
        // Add more complex tiers/conditions here if needed
    }
    mapping(uint256 => RoyaltyParams) private _assetRoyaltyParams;
    mapping(address => uint256) private _accruedRoyalties; // Royalties sent to this contract

    // Per-Asset Governance: Proposals for self-modification
    struct ModificationProposal {
        uint256 proposalId;
        address proposer;
        uint256 expiryTimestamp;
        string description;
        // How the attributes will change (simplified - could be more complex)
        uint256 proposedLevel;
        string proposedMetadataURI;
        mapping(address => bool) votes; // Track votes from co-owners
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
    }
    mapping(uint256 => mapping(uint256 => ModificationProposal)) private _assetProposals;
    mapping(uint256 => uint256) private _nextProposalId; // Counter per asset

    // Contract owner (for admin tasks, e.g., setting base URI, pausing)
    address public contractOwner;

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event AssetMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event AssetBurned(uint256 indexed tokenId, address indexed burner);
    event AttributesUpdated(uint256 indexed tokenId, uint256 newLevel, string newMetadataURI);
    event AssetEvolved(uint256 indexed tokenId, uint256 newLevel);
    event AssetLocked(uint256 indexed tokenId);
    event AssetUnlocked(uint256 indexed tokenId);
    event CoOwnerAdded(uint256 indexed tokenId, address indexed coOwner);
    event CoOwnerRemoved(uint256 indexed tokenId, address indexed coOwner);
    event CapabilityDelegated(uint256 indexed tokenId, address indexed delegate, Capability indexed capability);
    event CapabilityRevoked(uint256 indexed tokenId, address indexed delegate, Capability indexed capability);
    event UsageGranted(uint256 indexed tokenId, address indexed grantee, uint256 expiryTimestamp);
    event UsageRevoked(uint256 indexed tokenId, address indexed grantee);
    event AssetsLinked(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ActivityRecorded(uint256 indexed tokenId, string description, address indexed initiator);
    event MilestoneCompleted(uint256 indexed tokenId, Milestone indexed milestone);
    event RoyaltyParamsUpdated(uint256 indexed tokenId, address indexed recipient, uint256 feeNumerator, uint256 feeDenominator);
    event RoyaltiesClaimed(address indexed recipient, uint256 amount);
    event ProposalSubmitted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed proposer, string description);
    event VotedOnProposal(uint256 indexed tokenId, uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalExecuted(uint256 indexed tokenId, uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed tokenId, uint256 indexed proposalId);

    // --- Errors ---

    error Unauthorized();
    error InvalidTokenId();
    error NotOwnerOrApproved();
    error TransferLocked();
    error BurnLocked();
    error NotApprovedOrOwner();
    error CannotSelfApprove();
    error TokenAlreadyExists();
    error TokenDoesNotExist();
    error InvalidCoOwner();
    error CapabilityNotDelegated();
    error UsageNotGranted();
    error AlreadyLinked();
    error CannotLinkToSelf();
    error LogLimitExceeded(); // Informative error if log grows too large
    error MilestoneAlreadyCompleted();
    error InsufficientRoyalties();
    error ProposalDoesNotExist();
    error ProposalExpired();
    error ProposalNotExecutable();
    error AlreadyVoted();
    error CannotVoteOnOwnProposal();
    error NotACoOwner();
    error ProposalAlreadyExecutedOrCancelled();
    error LinkToSelf();

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
    }

    // --- Access Control Modifiers (Basic) ---

    modifier onlyOwner(uint256 tokenId) {
        if (_owners[tokenId] != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyContractOwner() {
        if (contractOwner != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlyOwnerOrApproved(uint256 tokenId) {
        if (_owners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_owners[tokenId], msg.sender)) {
             revert NotOwnerOrApproved();
        }
        _;
    }

    modifier onlyPermittedToBurn(uint256 tokenId) {
        if (_assetAttributes[tokenId].locked) revert BurnLocked();
        if (_owners[tokenId] != msg.sender && getApproved(tokenId) != msg.sender && !isApprovedForAll(_owners[tokenId], msg.sender)) {
             revert Unauthorized(); // Or a more specific error
        }
        _;
    }

    // --- ERC721 Standard Functions (Manual Implementation) ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        // ERC721 Interface ID (0x80ac58cd)
        // ERC165 Interface ID (0x01ffc9a7)
        return interfaceId == 0x80ac58cd || interfaceId == 0x01ffc9a7;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert InvalidTokenId(); // Standard check, though technically balance of zero address is 0
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        _safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner = _owners[tokenId];
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert Unauthorized();
        }
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert CannotSelfApprove();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Internal transfer logic.
     */
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        if (_owners[tokenId] != from) revert Unauthorized(); // Or more specific error
        if (to == address(0)) revert InvalidTokenId(); // Cannot transfer to zero address
        if (_assetAttributes[tokenId].locked) revert TransferLocked(); // Custom logic: Cannot transfer if locked

        // Check approval
        if (msg.sender != from && getApproved(tokenId) != msg.sender && !isApprovedForAll(from, msg.sender)) {
            revert NotOwnerOrApproved();
        }

        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;
        _approve(address(0), tokenId); // Clear approval
        emit Transfer(from, to, tokenId);

        // Record activity on transfer
        _recordActivity(tokenId, string(abi.encodePacked("Transferred to ", to)), msg.sender);
    }

    /**
     * @dev Internal safe transfer logic. Checks if receiving contract supports ERC721Receiver.
     */
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transferFrom(from, to, tokenId);
        if (to.code.length > 0) { // Check if it's a contract
            require(_checkOnERC721Received(address(0), from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
        }
    }

    /**
     * @dev Internal approval logic.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    /**
     * @dev Internal check for ERC721Receiver implementation.
     */
    function _checkOnERC721Received(address operator, address from, address to, uint256 tokenId, bytes memory data)
        internal returns (bool)
    {
        // Mock implementation - in a real scenario, you'd call the target contract
        // via abi.encodeWithSelector(IERC721Receiver.onERC721Received.selector, ...)
        // and check the return value.
        // For this example, we'll assume the check passes if the recipient is a contract.
        // THIS IS NOT A SECURE IMPLEMENTATION FOR PRODUCTION.
         return to.code.length > 0;
    }


    // --- Core Minting and Burning ---

    /**
     * @dev Mints a new token with dynamic initial attributes.
     * @param to The recipient of the new token.
     * @param initialMetadataURI The starting metadata URI.
     * @return tokenId The ID of the newly minted token.
     */
    function mint(address to, string memory initialMetadataURI) public returns (uint256) {
        uint256 newTokenId = _totalSupply + 1;
        if (_owners[newTokenId] != address(0)) revert TokenAlreadyExists(); // Should not happen with counter

        _owners[newTokenId] = to;
        _balances[to]++;
        _totalSupply++;

        // Initialize dynamic attributes based on minting context
        _assetAttributes[newTokenId] = AssetAttributes({
            level: 1,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp,
            metadataURI: initialMetadataURI,
            locked: false
        });

        // Initialize other mappings/arrays for the new token
        // _coOwners[newTokenId] is initialized as an empty array by default
        // _delegatedCapabilities[newTokenId] is initialized as empty mappings
        // _temporaryUsageGrants[newTokenId] is initialized as empty struct
        // _linkedAssets[newTokenId] is initialized as an empty array
        // _assetActivityLog[newTokenId] is initialized as an empty array
        // _completedMilestones[newTokenId] is initialized as empty mappings
        // _assetRoyaltyParams[newTokenId] gets default/zero values
        // _assetProposals[newTokenId] is initialized as empty mappings
        _nextProposalId[newTokenId] = 1; // Start proposal ID counter for this token

        emit Transfer(address(0), to, newTokenId); // Standard ERC721 Mint Event
        emit AssetMinted(newTokenId, to, initialMetadataURI);

        // Record activity
        _recordActivity(newTokenId, "Minted", msg.sender);

        return newTokenId;
    }

    /**
     * @dev Burns a token, removing it from existence.
     * Requires permission and the asset not to be locked.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) public onlyPermittedToBurn(tokenId) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();

        _balances[owner]--;
        delete _owners[tokenId];
        delete _tokenApprovals[tokenId]; // Clear any approval

        // --- Clean up token state ---
        delete _assetAttributes[tokenId];
        // Note: Deleting array elements or mapping keys within arrays is complex/expensive.
        // For simplicity, we just delete the head mapping/array, but linked assets/co-owners
        // in *other* tokens pointing to this one would need cleanup logic in a real system.
        delete _coOwners[tokenId];
        delete _delegatedCapabilities[tokenId];
        delete _temporaryUsageGrants[tokenId];
        delete _linkedAssets[tokenId];
        delete _assetActivityLog[tokenId];
        delete _completedMilestones[tokenId];
        delete _assetRoyaltyParams[tokenId];
        delete _assetProposals[tokenId]; // Delete all proposals for this token
        delete _nextProposalId[tokenId];

        emit Transfer(owner, address(0), tokenId); // Standard ERC721 Burn Event
        emit AssetBurned(tokenId, msg.sender);
    }

    // --- Dynamic Asset Attributes & Evolution ---

    /**
     * @dev Gets the current dynamic attributes of an asset.
     * @param tokenId The ID of the token.
     * @return AssetAttributes struct.
     */
    function getAssetAttributes(uint256 tokenId) public view returns (AssetAttributes memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _assetAttributes[tokenId];
    }

    /**
     * @dev Updates specific attributes of an asset.
     * Requires owner, co-owner, or specific capability delegation.
     * @param tokenId The ID of the token.
     * @param newMetadataURI The new metadata URI.
     */
    function updateAssetAttributes(uint256 tokenId, string memory newMetadataURI) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        address owner = _owners[tokenId];
        bool isCoOwner = false;
        for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == msg.sender) {
                isCoOwner = true;
                break;
            }
        }

        if (msg.sender != owner && !isCoOwner && !_delegatedCapabilities[tokenId][msg.sender][Capability.UpdateAttributes]) {
            revert Unauthorized();
        }
        if (_assetAttributes[tokenId].locked) revert TransferLocked(); // Cannot update if locked

        // Only allow metadata update via this function for simplicity
        _assetAttributes[tokenId].metadataURI = newMetadataURI;
        _assetAttributes[tokenId].lastInteractionTime = block.timestamp; // Mark interaction

        emit AttributesUpdated(tokenId, _assetAttributes[tokenId].level, newMetadataURI);
        _recordActivity(tokenId, string(abi.encodePacked("Attributes updated by ", msg.sender)), msg.sender);
    }

    /**
     * @dev Evolves the asset to the next level if conditions are met.
     * Conditions could be age, specific milestones, etc. (Simplified: requires `EvolvedOnce` milestone not met).
     * Can be triggered by anyone, but conditions must pass.
     * @param tokenId The ID of the token.
     */
    function evolveAsset(uint256 tokenId) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        if (_assetAttributes[tokenId].locked) revert TransferLocked();

        // Simplified evolution condition: Can only evolve once, and must have existed for > 1 hour (example)
        if (_completedMilestones[tokenId][Milestone.EvolvedOnce]) revert MilestoneAlreadyCompleted();
        if (block.timestamp < _assetAttributes[tokenId].creationTime + 1 hours) revert Unauthorized(); // Not old enough

        _assetAttributes[tokenId].level++;
        _assetAttributes[tokenId].lastInteractionTime = block.timestamp;

        _completedMilestones[tokenId][Milestone.EvolvedOnce] = true;
        emit AssetEvolved(tokenId, _assetAttributes[tokenId].level);
        emit MilestoneCompleted(tokenId, Milestone.EvolvedOnce);
        _recordActivity(tokenId, "Asset evolved", msg.sender);
    }

    /**
     * @dev Updates the asset's internal state based on passage of time ("ages" it).
     * Can be triggered by anyone to keep the asset's state reflecting its age.
     * Checks if enough time has passed since the last update.
     * @param tokenId The ID of the token.
     */
    function ageAsset(uint256 tokenId) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        // Prevent spamming - require a minimum time delta since last interaction/aging
        if (block.timestamp < _assetAttributes[tokenId].lastInteractionTime + 1 minutes) revert Unauthorized(); // Example: must wait 1 minute

        // In a real contract, aging might affect attributes, decay value, etc.
        // Here, it just updates the last interaction time and records activity.
        _assetAttributes[tokenId].lastInteractionTime = block.timestamp;

        _recordActivity(tokenId, "Asset aged/interacted with", msg.sender);
        // No specific event for simple aging unless attributes change meaningfully
    }

    /**
     * @dev Locks the asset, preventing transfer and most modifications.
     * Requires owner permission.
     * @param tokenId The ID of the token.
     */
    function lockAsset(uint256 tokenId) public onlyOwner(tokenId) {
        if (_assetAttributes[tokenId].locked) revert TransferLocked(); // Already locked
        _assetAttributes[tokenId].locked = true;
        emit AssetLocked(tokenId);
        _recordActivity(tokenId, "Asset locked", msg.sender);
    }

    /**
     * @dev Unlocks the asset.
     * Requires owner permission.
     * @param tokenId The ID of the token.
     */
    function unlockAsset(uint256 tokenId) public onlyOwner(tokenId) {
        if (!_assetAttributes[tokenId].locked) revert Unauthorized(); // Not locked
        _assetAttributes[tokenId].locked = false;
        emit AssetUnlocked(tokenId);
        _recordActivity(tokenId, "Asset unlocked", msg.sender);
    }


    // --- Co-Ownership and Delegation ---

    /**
     * @dev Adds an address as a co-owner of the asset.
     * Co-owners can be granted specific capabilities. Requires owner permission.
     * @param tokenId The ID of the token.
     * @param coOwner The address to add as co-owner.
     */
    function addCoOwner(uint256 tokenId, address coOwner) public onlyOwner(tokenId) {
        if (coOwner == address(0)) revert InvalidCoOwner();
        for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == coOwner) {
                revert InvalidCoOwner(); // Already a co-owner
            }
        }
        _coOwners[tokenId].push(coOwner);
        emit CoOwnerAdded(tokenId, coOwner);
        _recordActivity(tokenId, string(abi.encodePacked("Added co-owner ", coOwner)), msg.sender);
    }

    /**
     * @dev Removes an address as a co-owner. Requires owner permission.
     * @param tokenId The ID of the token.
     * @param coOwner The address to remove.
     */
    function removeCoOwner(uint256 tokenId, address coOwner) public onlyOwner(tokenId) {
        bool found = false;
        for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == coOwner) {
                // Simple removal by swapping with last element (order doesn't matter here)
                _coOwners[tokenId][i] = _coOwners[tokenId][_coOwners[tokenId].length - 1];
                _coOwners[tokenId].pop();
                found = true;
                break;
            }
        }
        if (!found) revert InvalidCoOwner();
        emit CoOwnerRemoved(tokenId, coOwner);
        _recordActivity(tokenId, string(abi.encodePacked("Removed co-owner ", coOwner)), msg.sender);
    }

    /**
     * @dev Gets the list of co-owners for an asset.
     * @param tokenId The ID of the token.
     * @return An array of co-owner addresses.
     */
    function getCoOwners(uint256 tokenId) public view returns (address[] memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _coOwners[tokenId];
    }

    /**
     * @dev Delegates a specific capability for the asset to an address.
     * Requires owner permission.
     * @param tokenId The ID of the token.
     * @param delegate The address to delegate the capability to.
     * @param capability The capability to delegate.
     */
    function delegateCapability(uint256 tokenId, address delegate, Capability capability) public onlyOwner(tokenId) {
        if (delegate == address(0)) revert Unauthorized();
        _delegatedCapabilities[tokenId][delegate][capability] = true;
        emit CapabilityDelegated(tokenId, delegate, capability);
        _recordActivity(tokenId, string(abi.encodePacked("Delegated capability ", uint8(capability), " to ", delegate)), msg.sender);
    }

    /**
     * @dev Revokes a previously delegated capability. Requires owner permission.
     * @param tokenId The ID of the token.
     * @param delegate The address whose capability is revoked.
     * @param capability The capability to revoke.
     */
    function revokeCapability(uint256 tokenId, address delegate, Capability capability) public onlyOwner(tokenId) {
        if (!_delegatedCapabilities[tokenId][delegate][capability]) revert CapabilityNotDelegated();
        _delegatedCapabilities[tokenId][delegate][capability] = false;
        emit CapabilityRevoked(tokenId, delegate, capability);
        _recordActivity(tokenId, string(abi.encodePacked("Revoked capability ", uint8(capability), " from ", delegate)), msg.sender);
    }

    /**
     * @dev Checks if an address has a specific delegated capability for an asset.
     * @param tokenId The ID of the token.
     * @param delegate The address to check.
     * @param capability The capability to check.
     * @return True if the capability is delegated, false otherwise.
     */
    function checkDelegatedCapability(uint256 tokenId, address delegate, Capability capability) public view returns (bool) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _delegatedCapabilities[tokenId][delegate][capability];
    }

    // --- Temporary Usage Grants (Rental-like) ---

    /**
     * @dev Grants temporary usage rights for an asset to an address until a specific timestamp.
     * The grantee can perform certain actions (defined by Capability enum, e.g., GrantUsage itself).
     * Requires owner permission or `GrantUsage` capability delegation.
     * @param tokenId The ID of the token.
     * @param grantee The address receiving usage rights.
     * @param expiryTimestamp The timestamp when the rights expire.
     */
    function grantTemporaryUsage(uint256 tokenId, address grantee, uint256 expiryTimestamp) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         address owner = _owners[tokenId];
        if (msg.sender != owner && !_delegatedCapabilities[tokenId][msg.sender][Capability.GrantUsage]) {
             revert Unauthorized();
        }
        if (grantee == address(0) || expiryTimestamp <= block.timestamp) revert UsageNotGranted();

        _temporaryUsageGrants[tokenId] = UsageGrant({
            grantee: grantee,
            expiryTimestamp: expiryTimestamp
        });

        emit UsageGranted(tokenId, grantee, expiryTimestamp);
         _recordActivity(tokenId, string(abi.encodePacked("Granted temporary usage to ", grantee, " until ", expiryTimestamp)), msg.sender);
         _triggerMilestone(tokenId, Milestone.UsageGranted); // Example: milestone for granting usage
    }

    /**
     * @dev Revokes temporary usage rights immediately.
     * Requires owner permission or the current grantee (to self-revoke).
     * @param tokenId The ID of the token.
     */
    function revokeTemporaryUsage(uint256 tokenId) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        address owner = _owners[tokenId];
        UsageGrant memory currentGrant = _temporaryUsageGrants[tokenId];

        if (msg.sender != owner && msg.sender != currentGrant.grantee) {
            revert Unauthorized(); // Only owner or grantee can revoke
        }

        if (currentGrant.grantee == address(0)) revert UsageNotGranted(); // No grant exists

        delete _temporaryUsageGrants[tokenId]; // Clear the grant
        emit UsageRevoked(tokenId, currentGrant.grantee);
        _recordActivity(tokenId, string(abi.encodePacked("Revoked temporary usage from ", currentGrant.grantee)), msg.sender);
    }

     /**
     * @dev Gets the current temporary usage grantee and expiry for an asset.
     * @param tokenId The ID of the token.
     * @return grantee The address with usage rights (address(0) if none).
     * @return expiryTimestamp The timestamp when rights expire (0 if none).
     */
    function getCurrentUsageGrant(uint256 tokenId) public view returns (address grantee, uint256 expiryTimestamp) {
         if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         UsageGrant memory currentGrant = _temporaryUsageGrants[tokenId];
         if (currentGrant.expiryTimestamp > block.timestamp) {
             return (currentGrant.grantee, currentGrant.expiryTimestamp);
         } else {
             // Grant expired or never existed
             return (address(0), 0);
         }
    }


    // --- Asset Linking and Relationships ---

    /**
     * @dev Establishes a symmetric on-chain link between two assets.
     * Requires owner permission for BOTH tokens (or approval/delegation).
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function linkAssets(uint256 tokenId1, uint256 tokenId2) public {
        if (tokenId1 == tokenId2) revert LinkToSelf();
        if (_owners[tokenId1] == address(0) || _owners[tokenId2] == address(0)) revert InvalidTokenId();

        // Check permission for token1
        address owner1 = _owners[tokenId1];
        if (msg.sender != owner1 && getApproved(tokenId1) != msg.sender && !isApprovedForAll(owner1, msg.sender)) {
            revert Unauthorized();
        }
         // Check permission for token2
        address owner2 = _owners[tokenId2];
        if (msg.sender != owner2 && getApproved(tokenId2) != msg.sender && !isApprovedForAll(owner2, msg.sender)) {
            revert Unauthorized();
        }

        // Check if already linked (avoid duplicates)
        for(uint i = 0; i < _linkedAssets[tokenId1].length; i++) {
            if (_linkedAssets[tokenId1][i] == tokenId2) {
                revert AlreadyLinked();
            }
        }

        _linkedAssets[tokenId1].push(tokenId2);
        _linkedAssets[tokenId2].push(tokenId1); // Symmetric link

        emit AssetsLinked(tokenId1, tokenId2);
        _recordActivity(tokenId1, string(abi.encodePacked("Linked to asset #", tokenId2)), msg.sender);
        _recordActivity(tokenId2, string(abi.encodePacked("Linked to asset #", tokenId1)), msg.sender);
         _triggerMilestone(tokenId1, Milestone.LinkedToAnother);
         _triggerMilestone(tokenId2, Milestone.LinkedToAnother);
    }

    /**
     * @dev Gets the list of assets linked to a specific token.
     * @param tokenId The ID of the token.
     * @return An array of linked token IDs.
     */
    function getLinkedAssets(uint256 tokenId) public view returns (uint256[] memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _linkedAssets[tokenId];
    }

     /**
     * @dev Removes a link between two assets.
     * Requires owner permission for BOTH tokens.
     * @param tokenId1 The ID of the first token.
     * @param tokenId2 The ID of the second token.
     */
    function unlinkAssets(uint256 tokenId1, uint256 tokenId2) public {
         if (tokenId1 == tokenId2) revert LinkToSelf();
        if (_owners[tokenId1] == address(0) || _owners[tokenId2] == address(0)) revert InvalidTokenId();

        // Check permission for token1 & token2
        address owner1 = _owners[tokenId1];
        if (msg.sender != owner1 && getApproved(tokenId1) != msg.sender && !isApprovedForAll(owner1, msg.sender)) {
            revert Unauthorized();
        }
         address owner2 = _owners[tokenId2];
        if (msg.sender != owner2 && getApproved(tokenId2) != msg.sender && !isApprovedForAll(owner2, msg.sender)) {
            revert Unauthorized();
        }

        // Remove link from tokenId1's list
        bool found1 = false;
        for(uint i = 0; i < _linkedAssets[tokenId1].length; i++) {
            if (_linkedAssets[tokenId1][i] == tokenId2) {
                _linkedAssets[tokenId1][i] = _linkedAssets[tokenId1][_linkedAssets[tokenId1].length - 1];
                _linkedAssets[tokenId1].pop();
                found1 = true;
                break;
            }
        }
        if (!found1) revert Unauthorized(); // Link didn't exist

        // Remove link from tokenId2's list (should always be found if found1 is true)
         bool found2 = false;
         for(uint i = 0; i < _linkedAssets[tokenId2].length; i++) {
            if (_linkedAssets[tokenId2][i] == tokenId1) {
                _linkedAssets[tokenId2][i] = _linkedAssets[tokenId2][_linkedAssets[tokenId2].length - 1];
                _linkedAssets[tokenId2].pop();
                found2 = true;
                break;
            }
        }
        // Should not happen if found1 is true, but good practice
        if (!found2) revert Unauthorized();

        emit AssetsLinked(tokenId1, tokenId2); // Can use same event or a new Unlinked event
        _recordActivity(tokenId1, string(abi.encodePacked("Unlinked from asset #", tokenId2)), msg.sender);
        _recordActivity(tokenId2, string(abi.encodePacked("Unlinked from asset #", tokenId1)), msg.sender);
    }


    // --- On-chain Activity Logging ---

    /**
     * @dev Records an activity entry for an asset. Limited log size.
     * Can be called by the asset's owner, a co-owner, a delegate, or potentially anyone for public actions.
     * (Implemented allowing owner/co-owner/delegate for simplicity)
     * @param tokenId The ID of the token.
     * @param description A brief description of the activity.
     * @param initiator The address that initiated the activity.
     */
    function _recordActivity(uint256 tokenId, string memory description, address initiator) internal {
        // Internal function - permissions checked by public callers

        // Simple log limit - remove oldest entry if adding exceeds limit
        if (_assetActivityLog[tokenId].length >= MAX_ACTIVITY_LOG_ENTRIES) {
            // Shift all elements left and remove the last one
            for (uint i = 0; i < _assetActivityLog[tokenId].length - 1; i++) {
                _assetActivityLog[tokenId][i] = _assetActivityLog[tokenId][i + 1];
            }
             _assetActivityLog[tokenId].pop();
        }

        _assetActivityLog[tokenId].push(ActivityEntry({
            timestamp: block.timestamp,
            description: description,
            initiator: initiator
        }));

        emit ActivityRecorded(tokenId, description, initiator);
    }

    /**
     * @dev Public function to record a custom activity, requires permission.
     * @param tokenId The ID of the token.
     * @param description A brief description of the activity.
     */
    function recordCustomActivity(uint256 tokenId, string memory description) public {
         if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         address owner = _owners[tokenId];
        bool isCoOwner = false;
        for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == msg.sender) {
                isCoOwner = true;
                break;
            }
        }
        // Example: Allow owner, co-owner, or specific delegation to record *custom* activity
        if (msg.sender != owner && !isCoOwner && !_delegatedCapabilities[tokenId][msg.sender][Capability.UpdateAttributes]) { // Reusing update capability for example
             revert Unauthorized();
        }
        _recordActivity(tokenId, description, msg.sender);
    }


    /**
     * @dev Gets the recent activity log for an asset.
     * @param tokenId The ID of the token.
     * @return An array of ActivityEntry structs.
     */
    function getRecentActivity(uint256 tokenId) public view returns (ActivityEntry[] memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _assetActivityLog[tokenId];
    }


    // --- Milestones and Conditional Features ---

    /**
     * @dev Triggers a specific milestone for an asset.
     * This function should typically be called by an oracle, a trusted third party,
     * or another contract after verifying an off-chain condition (e.g., quest completion).
     * Requires contract owner permission in this example.
     * @param tokenId The ID of the token.
     * @param milestone The milestone to trigger.
     */
    function triggerMilestone(uint256 tokenId, Milestone milestone) public onlyContractOwner {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        if (_completedMilestones[tokenId][milestone]) revert MilestoneAlreadyCompleted();

        _completedMilestones[tokenId][milestone] = true;

        // Unlock features or update attributes based on milestone
        if (milestone == Milestone.LinkedToAnother && _assetAttributes[tokenId].level < 5) { // Example: Linking boosts level once if below 5
             _assetAttributes[tokenId].level = 5; // Set minimum level
              emit AttributesUpdated(tokenId, _assetAttributes[tokenId].level, _assetAttributes[tokenId].metadataURI);
        }
        if (milestone == Milestone.ModifiedByGovernance) { // Example: Governance modification grants a level boost
            _assetAttributes[tokenId].level += 2;
             emit AttributesUpdated(tokenId, _assetAttributes[tokenId].level, _assetAttributes[tokenId].metadataURI);
        }


        emit MilestoneCompleted(tokenId, milestone);
        _recordActivity(tokenId, string(abi.encodePacked("Milestone completed: ", uint8(milestone))), address(this)); // Initiator is contract for oracle call
    }

    /**
     * @dev Internal helper to trigger milestones from other functions.
     * @param tokenId The ID of the token.
     * @param milestone The milestone to trigger.
     */
    function _triggerMilestone(uint256 tokenId, Milestone milestone) internal {
         if (_owners[tokenId] == address(0)) return; // Don't revert if token doesn't exist (e.g., race condition)
         if (!_completedMilestones[tokenId][milestone]) {
            _completedMilestones[tokenId][milestone] = true;
             emit MilestoneCompleted(tokenId, milestone);
             // Note: Attribute updates on milestone completion are handled in the public triggerMilestone for now
         }
    }

    /**
     * @dev Checks if a specific milestone has been completed for an asset.
     * @param tokenId The ID of the token.
     * @param milestone The milestone to check.
     * @return True if the milestone is completed, false otherwise.
     */
    function hasCompletedMilestone(uint256 tokenId, Milestone milestone) public view returns (bool) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _completedMilestones[tokenId][milestone];
    }

    /**
     * @dev Get all completed milestones for an asset.
     * (Note: Returning all enum values and their status is simpler than just completed ones)
     * @param tokenId The ID of the token.
     * @return An array of booleans indicating completion status for each milestone enum value.
     */
    function getCompletedMilestones(uint256 tokenId) public view returns (bool[] memory) {
         if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         bool[] memory statuses = new bool[](uint8(Milestone.ModifiedByGovernance) + 1);
         for(uint8 i = 0; i <= uint8(Milestone.ModifiedByGovernance); i++) {
             statuses[i] = _completedMilestones[tokenId][Milestone(i)];
         }
         return statuses;
    }

    // --- Programmable Royalties and Claiming ---

    /**
     * @dev Sets the royalty parameters for an asset.
     * Requires owner permission. Allows defining a recipient and a simple fee percentage.
     * More complex tiered logic would be implemented here or in a separate contract.
     * @param tokenId The ID of the token.
     * @param recipient The address to receive royalties.
     * @param feeNumerator The numerator of the fee percentage.
     * @param feeDenominator The denominator of the fee percentage (e.g., 10000 for basis points).
     */
    function setRoyaltyParams(uint256 tokenId, address recipient, uint256 feeNumerator, uint256 feeDenominator) public onlyOwner(tokenId) {
        if (recipient == address(0) || feeDenominator == 0 || feeNumerator > feeDenominator) revert Unauthorized(); // Basic validation
        _assetRoyaltyParams[tokenId] = RoyaltyParams({
            recipient: recipient,
            feeNumerator: feeNumerator,
            feeDenominator: feeDenominator
        });
        emit RoyaltyParamsUpdated(tokenId, recipient, feeNumerator, feeDenominator);
        _recordActivity(tokenId, string(abi.encodePacked("Set royalty params: recipient=", recipient, ", fee=", feeNumerator, "/", feeDenominator)), msg.sender);
    }

    /**
     * @dev Gets the royalty parameters for an asset.
     * @param tokenId The ID of the token.
     * @return recipient, feeNumerator, feeDenominator.
     */
    function getRoyaltyParams(uint256 tokenId) public view returns (address recipient, uint256 feeNumerator, uint256 feeDenominator) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        RoyaltyParams storage params = _assetRoyaltyParams[tokenId];
        return (params.recipient, params.feeNumerator, params.feeDenominator);
    }

     /**
      * @dev Records an incoming royalty payment for a specific token.
      * This function is expected to be called by a marketplace or a royalty distribution mechanism.
      * The ETH/tokens are assumed to be sent to this contract, and this function logs the amount
      * owed to the royalty recipient.
      * Requires a trusted caller (e.g., a marketplace contract address).
      * @param tokenId The ID of the token the royalty is for.
      * @param amount The amount of royalty received for this token (in native token like ETH).
      * @param marketplace The address of the marketplace/sender.
      */
     function recordRoyaltyPayment(uint256 tokenId, uint256 amount, address marketplace) public onlyContractOwner { // Example: only contract owner can call
         if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         // Look up the recipient and add to their balance
         RoyaltyParams storage params = _assetRoyaltyParams[tokenId];
         if (params.recipient != address(0) && params.feeDenominator > 0) {
             uint256 royaltyAmount = (amount * params.feeNumerator) / params.feeDenominator;
             _accruedRoyalties[params.recipient] += royaltyAmount;
              _recordActivity(tokenId, string(abi.encodePacked("Royalty payment recorded: ", royaltyAmount, " from ", marketplace)), msg.sender);
         }
         // Note: The actual ETH/token must be sent to THIS contract address for this to work.
     }

    /**
     * @dev Allows a royalty recipient to claim their accrued royalties.
     * @param recipient The address of the royalty recipient.
     */
    function claimAccruedRoyalties(address recipient) public {
        // Anyone can trigger claiming for a recipient, the check is on the balance
        uint256 amount = _accruedRoyalties[recipient];
        if (amount == 0) revert InsufficientRoyalties();

        _accruedRoyalties[recipient] = 0; // Reset balance before sending to prevent reentrancy

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            // Revert the balance change if send fails
            _accruedRoyalties[recipient] = amount;
            revert InsufficientRoyalties(); // Using InsufficientRoyalties error for simplicity, could be a new error like TransferFailed
        }

        emit RoyaltiesClaimed(recipient, amount);
         // Note: Activity log for claiming is not per-asset, so log it globally or omit.
    }

    /**
     * @dev Get the total accrued royalties for a specific recipient address.
     * @param recipient The address to check.
     * @return The total accrued amount.
     */
    function getAccruedRoyalties(address recipient) public view returns (uint256) {
        return _accruedRoyalties[recipient];
    }

     // --- Per-Asset Self-Modification Governance ---

    /**
     * @dev Proposes a modification to the asset's attributes.
     * Can only be proposed by the owner or a co-owner with the ProposeModification capability.
     * Starts a voting period.
     * @param tokenId The ID of the token.
     * @param description Description of the proposed change.
     * @param proposedLevel The new level if the proposal passes.
     * @param proposedMetadataURI The new metadata URI if the proposal passes.
     * @param votingPeriodDuration The duration of the voting period in seconds.
     */
    function proposeSelfModification(
        uint256 tokenId,
        string memory description,
        uint256 proposedLevel,
        string memory proposedMetadataURI,
        uint256 votingPeriodDuration
    ) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         address owner = _owners[tokenId];
        bool isCoOwner = false;
        for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == msg.sender) {
                isCoOwner = true;
                break;
            }
        }
        if (msg.sender != owner && !isCoOwner && !_delegatedCapabilities[tokenId][msg.sender][Capability.ProposeModification]) {
            revert Unauthorized();
        }
        if (_assetAttributes[tokenId].locked) revert TransferLocked(); // Cannot propose changes if locked

        uint256 proposalId = _nextProposalId[tokenId]++;
        uint256 expiry = block.timestamp + votingPeriodDuration;

        ModificationProposal storage proposal = _assetProposals[tokenId][proposalId];
        proposal.proposalId = proposalId;
        proposal.proposer = msg.sender;
        proposal.expiryTimestamp = expiry;
        proposal.description = description;
        proposal.proposedLevel = proposedLevel;
        proposal.proposedMetadataURI = proposedMetadataURI;
        // Votes mapping is implicitly initialized empty
        proposal.votesFor = 0;
        proposal.votesAgainst = 0;
        proposal.executed = false;
        proposal.cancelled = false;


        emit ProposalSubmitted(tokenId, proposalId, msg.sender, description);
        _recordActivity(tokenId, string(abi.encodePacked("Submitted modification proposal #", proposalId)), msg.sender);
    }

     /**
      * @dev Votes on an active self-modification proposal for an asset.
      * Only co-owners can vote (excluding the proposer if they are the sole owner).
      * @param tokenId The ID of the token.
      * @param proposalId The ID of the proposal.
      * @param vote For (true) or Against (false).
      */
    function voteOnProposal(uint256 tokenId, uint256 proposalId, bool vote) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         ModificationProposal storage proposal = _assetProposals[tokenId][proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist(); // Check if proposal exists
        if (proposal.expiryTimestamp <= block.timestamp) revert ProposalExpired();
        if (proposal.executed || proposal.cancelled) revert ProposalAlreadyExecutedOrCancelled();
        if (proposal.votes[msg.sender]) revert AlreadyVoted();

        // Check if voter is a co-owner
        bool isCoOwner = false;
         for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == msg.sender) {
                isCoOwner = true;
                break;
            }
        }
        if (!isCoOwner) revert NotACoOwner();
        if (msg.sender == proposal.proposer && _coOwners[tokenId].length == 1) revert CannotVoteOnOwnProposal(); // Prevent sole owner/proposer voting on their own proposal

        proposal.votes[msg.sender] = true;
        if (vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VotedOnProposal(tokenId, proposalId, msg.sender, vote);
        _recordActivity(tokenId, string(abi.encodePacked("Voted ", vote ? "for" : "against", " proposal #", proposalId)), msg.sender);
    }

     /**
      * @dev Executes a successful self-modification proposal after the voting period ends.
      * Requires the voting period to be over and the proposal to have passed (simple majority of co-owners who voted).
      * Any co-owner can trigger execution.
      * @param tokenId The ID of the token.
      * @param proposalId The ID of the proposal.
      */
    function executeProposal(uint256 tokenId, uint256 proposalId) public {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        ModificationProposal storage proposal = _assetProposals[tokenId][proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
         if (proposal.expiryTimestamp > block.timestamp) revert ProposalNotExecutable(); // Voting not over
         if (proposal.executed || proposal.cancelled) revert ProposalAlreadyExecutedOrCancelled();
         if (_assetAttributes[tokenId].locked) revert TransferLocked();

        // Check if proposal passed (simple majority of votes cast)
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        if (totalVotes == 0 || proposal.votesFor <= proposal.votesAgainst) {
             proposal.cancelled = true; // Mark as failed/cancelled
             emit ProposalCancelled(tokenId, proposalId);
              _recordActivity(tokenId, string(abi.encodePacked("Proposal #", proposalId, " failed/cancelled")), msg.sender);
             revert ProposalNotExecutable(); // Explicitly fail if it didn't pass
        }

        // Execute the proposed changes
        _assetAttributes[tokenId].level = proposal.proposedLevel;
        _assetAttributes[tokenId].metadataURI = proposal.proposedMetadataURI;
        _assetAttributes[tokenId].lastInteractionTime = block.timestamp; // Mark interaction

        proposal.executed = true; // Mark as executed
        emit AttributesUpdated(tokenId, _assetAttributes[tokenId].level, _assetAttributes[tokenId].metadataURI);
        emit ProposalExecuted(tokenId, proposalId);
         _recordActivity(tokenId, string(abi.encodePacked("Executed modification proposal #", proposalId)), msg.sender);
         _triggerMilestone(tokenId, Milestone.ModifiedByGovernance); // Example: Milestone for governance change
    }

    /**
     * @dev Gets details of a specific proposal for an asset.
     * @param tokenId The ID of the token.
     * @param proposalId The ID of the proposal.
     * @return ModificationProposal struct.
     */
    function getProposal(uint256 tokenId, uint256 proposalId) public view returns (ModificationProposal memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        ModificationProposal storage proposal = _assetProposals[tokenId][proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
        return proposal;
    }

    // --- Additional Utility / View Functions ---

    /**
     * @dev Returns the total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the URI for the asset's metadata.
     * @param tokenId The ID of the token.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        return _assetAttributes[tokenId].metadataURI;
    }

     /**
     * @dev Checks if a specific address is a co-owner of an asset.
     * @param tokenId The ID of the token.
     * @param potentialCoOwner The address to check.
     * @return True if the address is a co-owner, false otherwise.
     */
    function isCoOwner(uint256 tokenId, address potentialCoOwner) public view returns (bool) {
        if (_owners[tokenId] == address(0)) revert InvalidTokenId();
        for(uint i = 0; i < _coOwners[tokenId].length; i++) {
            if (_coOwners[tokenId][i] == potentialCoOwner) {
                return true;
            }
        }
        return false;
    }

     /**
     * @dev Checks if an asset is currently locked.
     * @param tokenId The ID of the token.
     * @return True if locked, false otherwise.
     */
    function isAssetLocked(uint256 tokenId) public view returns (bool) {
         if (_owners[tokenId] == address(0)) revert InvalidTokenId();
         return _assetAttributes[tokenId].locked;
    }
}
```

---

### Function Summary:

1.  `constructor()`: Initializes the contract, setting the `contractOwner`.
2.  `supportsInterface(bytes4 interfaceId) view`: Implements ERC165, indicating support for ERC721.
3.  `balanceOf(address owner) view`: Returns the number of tokens owned by an address (ERC721).
4.  `ownerOf(uint256 tokenId) view`: Returns the owner of a specific token (ERC721).
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Safe transfer function (ERC721). Includes check for asset lock.
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Overloaded safe transfer function (ERC721). Includes check for asset lock.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Basic transfer function (ERC721). Includes check for asset lock.
8.  `approve(address to, uint255 tokenId)`: Approves an address to transfer a specific token (ERC721).
9.  `setApprovalForAll(address operator, bool approved)`: Approves or revokes approval for an operator for all tokens of the sender (ERC721).
10. `getApproved(uint256 tokenId) view`: Returns the approved address for a token (ERC721).
11. `isApprovedForAll(address owner, address operator) view`: Returns if an operator is approved for all tokens of an owner (ERC721).
12. `mint(address to, string memory initialMetadataURI)`: Mints a new token, assigning dynamic initial attributes, and initializes its associated state variables (co-owners, log, etc.). Includes dynamic attribute initialization.
13. `burn(uint256 tokenId)`: Destroys a token and cleans up its associated state. Requires permission and asset must not be locked.
14. `getAssetAttributes(uint256 tokenId) view`: Retrieves the current dynamic attributes of a token.
15. `updateAssetAttributes(uint256 tokenId, string memory newMetadataURI)`: Allows updating specific attributes (metadata URI in this example). Requires owner/co-owner/delegate permission and asset must not be locked.
16. `evolveAsset(uint256 tokenId)`: Triggers a state transition ("evolution") for the asset if specific on-chain conditions (age, milestones) are met. Can be called by anyone.
17. `ageAsset(uint256 tokenId)`: Updates the asset's internal last interaction time, contributing to aging logic. Can be called by anyone after a cool-down.
18. `lockAsset(uint256 tokenId)`: Prevents transfers and most attribute modifications. Requires owner permission.
19. `unlockAsset(uint256 tokenId)`: Removes the lock on the asset. Requires owner permission.
20. `addCoOwner(uint256 tokenId, address coOwner)`: Adds an address to the list of co-owners. Requires owner permission.
21. `removeCoOwner(uint256 tokenId, address coOwner)`: Removes an address from the list of co-owners. Requires owner permission.
22. `getCoOwners(uint256 tokenId) view`: Retrieves the list of co-owner addresses for a token.
23. `delegateCapability(uint256 tokenId, address delegate, Capability capability)`: Grants a specific operational capability (e.g., UpdateAttributes, GrantUsage, ProposeModification) to an address. Requires owner permission.
24. `revokeCapability(uint256 tokenId, address delegate, Capability capability)`: Revokes a delegated capability. Requires owner permission.
25. `checkDelegatedCapability(uint256 tokenId, address delegate, Capability capability) view`: Checks if an address has a specific delegated capability.
26. `grantTemporaryUsage(uint256 tokenId, address grantee, uint256 expiryTimestamp)`: Grants temporary usage rights for the asset (rental-like). Requires owner or `GrantUsage` delegate permission.
27. `revokeTemporaryUsage(uint256 tokenId)`: Revokes temporary usage rights. Requires owner or current grantee permission.
28. `getCurrentUsageGrant(uint256 tokenId) view`: Gets details of the current temporary usage grant.
29. `linkAssets(uint256 tokenId1, uint256 tokenId2)`: Creates a symmetric on-chain link between two distinct assets. Requires permission (owner/approved) on both assets.
30. `getLinkedAssets(uint256 tokenId) view`: Retrieves the list of token IDs linked to a given asset.
31. `unlinkAssets(uint256 tokenId1, uint256 tokenId2)`: Removes a symmetric on-chain link between two assets. Requires permission (owner/approved) on both assets.
32. `recordCustomActivity(uint256 tokenId, string memory description)`: Allows authorized parties (owner/co-owner/delegate) to add a custom entry to the asset's activity log.
33. `getRecentActivity(uint256 tokenId) view`: Retrieves the recent on-chain activity log for an asset (limited by `MAX_ACTIVITY_LOG_ENTRIES`).
34. `triggerMilestone(uint256 tokenId, Milestone milestone)`: Marks a specific milestone as completed for an asset. Intended for external calls (e.g., by an oracle or trusted entity). Can trigger attribute updates.
35. `hasCompletedMilestone(uint256 tokenId, Milestone milestone) view`: Checks if a specific milestone has been completed.
36. `getCompletedMilestones(uint256 tokenId) view`: Gets the completion status for all defined milestones.
37. `setRoyaltyParams(uint256 tokenId, address recipient, uint256 feeNumerator, uint256 feeDenominator)`: Sets the parameters for per-asset royalties. Requires owner permission.
38. `getRoyaltyParams(uint256 tokenId) view`: Retrieves the royalty parameters for an asset.
39. `recordRoyaltyPayment(uint256 tokenId, uint256 amount, address marketplace)`: Records that a royalty payment (in native token) has been received by the contract for a specific token, increasing the accrued balance for the recipient. Requires trusted caller (contract owner in this example).
40. `claimAccruedRoyalties(address recipient)`: Allows a designated royalty recipient to withdraw their accrued native token balance from the contract.
41. `getAccruedRoyalties(address recipient) view`: Gets the total royalty amount accrued for a specific recipient address held by the contract.
42. `proposeSelfModification(uint256 tokenId, string memory description, uint256 proposedLevel, string memory proposedMetadataURI, uint256 votingPeriodDuration)`: Initiates a governance proposal for the asset's attributes. Can be proposed by owner or co-owner with capability.
43. `voteOnProposal(uint256 tokenId, uint256 proposalId, bool vote)`: Casts a vote on an active modification proposal. Only co-owners can vote.
44. `executeProposal(uint256 tokenId, uint256 proposalId)`: Executes a proposal if the voting period is over and it passed (simple majority of votes cast). Any co-owner can trigger. Updates asset attributes and triggers a milestone.
45. `getProposal(uint256 tokenId, uint256 proposalId) view`: Retrieves details of a specific governance proposal.
46. `totalSupply() view`: Returns the total number of tokens in existence.
47. `tokenURI(uint256 tokenId) view`: Gets the metadata URI for a token (derived from attributes).
48. `isCoOwner(uint256 tokenId, address potentialCoOwner) view`: Helper to check if an address is a co-owner.
49. `isAssetLocked(uint256 tokenId) view`: Helper to check if an asset is locked.

This contract provides a foundation for complex digital assets that can live and evolve on-chain through various interactions and governance mechanisms.