Okay, this is an exciting challenge! Let's design a smart contract system that incorporates several advanced, trendy, and non-trivial concepts beyond typical NFTs or DAOs.

I'll call this the **"Chronoscribe Nexus"**.

**Core Concept:** The Chronoscribe Nexus is a decentralized, verifiable, and time-sensitive attestation platform. It allows users to mint "Chronoscripts" – non-fungible tokens (NFTs) representing verifiable claims, achievements, or credentials. These Chronoscripts are dynamic, can expire, require renewal, and can be attested to by whitelisted entities (other users, DAOs, or even smart contracts). It builds a reputation layer based on these attestations and introduces epoch-based progression for periodic evaluations.

---

### **Chronoscribe Nexus: Smart Contract Outline & Function Summary**

**Contract Name:** `ChronoscribeNexus`

**Purpose:** To establish a decentralized, verifiable, and time-sensitive system for on-chain attestations, credentialing, and reputation building, leveraging dynamic NFTs.

**Key Advanced Concepts & Trends Integrated:**

1.  **Verifiable Credentials / Decentralized Identity (DID) Principles:** Chronoscripts act as self-sovereign, verifiable claims, with the contract providing the on-chain registry and attestation layer.
2.  **Dynamic NFTs:** Chronoscripts are NFTs whose metadata and validity state can change based on time, attestations, or renewal.
3.  **Time-Bound / Ephemeral Assets:** Chronoscripts have configurable expiry dates and require renewal or re-attestation, mimicking real-world credentials.
4.  **On-Chain Attestation Network:** A system for whitelisted entities to attest to the validity or truthfulness of a Chronoscript.
5.  **Reputation System:** A calculable on-chain reputation score derived from the quantity, quality, and validity of a user's Chronoscripts and their attestations.
6.  **Epoch-Based Progression:** Time is structured into epochs, enabling periodic events, reputation recalculations, or reward distributions (not implemented but enabled by the epoch system).
7.  **Configurable Claim Types:** The contract owner can define various types of claims, each with its own rules (e.g., expiry duration, required attestations, staking requirements).
8.  **Staking/Collateral for Claims:** Certain high-value or critical claims might require a token stake, proving commitment and potentially making them more trustworthy.
9.  **Gas Efficiency & Custom Errors:** Utilizing modern Solidity features for better error handling and potential gas savings.

---

**Function Modules & Summaries (25+ Functions):**

**I. ERC-721 Core Functions (Standard Implementations):**
1.  `balanceOf(address owner)`: Returns the number of Chronoscripts an owner has.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Chronoscript.
3.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a Chronoscript.
4.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Overloaded transfer function.
5.  `approve(address to, uint256 tokenId)`: Approves an address to transfer a specific Chronoscript.
6.  `getApproved(uint256 tokenId)`: Returns the approved address for a Chronoscript.
7.  `setApprovalForAll(address operator, bool approved)`: Approves/disapproves an operator for all Chronoscripts.
8.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all Chronoscripts.
9.  `tokenURI(uint256 tokenId)`: Returns the URI for the metadata JSON of a Chronoscript (dynamic).

**II. Chronoscript Management (Core Logic):**
10. `mintChronoscript(address to, bytes32 claimHash, uint256 claimTypeId, string calldata metadataURI)`: Mints a new Chronoscript for `to` with a hash representing off-chain claim data and a specified claim type. Requires meeting claim type criteria (e.g., stake).
11. `renewChronoscript(uint256 tokenId)`: Renews an expiring Chronoscript, extending its `expiresAt` based on its `ClaimType` and potentially requiring re-attestations or a new stake.
12. `revokeChronoscript(uint256 tokenId)`: Allows the owner of a Chronoscript to permanently revoke its validity.
13. `updateChronoscriptMetadataURI(uint256 tokenId, string calldata newURI)`: Allows the Chronoscript owner to update its metadata URI.
14. `burnChronoscript(uint256 tokenId)`: Permanently burns a Chronoscript (removes it from circulation).

**III. Attestation & Whitelisting:**
15. `attestChronoscript(uint256 tokenId)`: Allows a whitelisted attester to vouch for a Chronoscript, increasing its `attestationCount`. Only possible if `isChronoscriptValid` is true or nearly so.
16. `revokeAttestation(uint256 tokenId)`: Allows a whitelisted attester to retract their attestation.
17. `addWhitelistedAttester(address attesterAddress, string calldata name)`: Admin function to add a new entity to the list of approved attesters.
18. `removeWhitelistedAttester(address attesterAddress)`: Admin function to remove an attester.
19. `updateAttesterProfile(string calldata newName)`: Allows a whitelisted attester to update their registered name.

**IV. Claim Type Configuration (Admin Only):**
20. `addClaimType(string calldata name, bool isRenewable, uint32 defaultExpiryDuration, uint8 minAttestationsRequired, uint256 requiredStakeAmount)`: Admin function to define new categories of Chronoscripts with specific rules.
21. `updateClaimType(uint256 claimTypeId, string calldata newName, bool newIsRenewable, uint32 newDefaultExpiryDuration, uint8 newMinAttestationsRequired, uint256 newRequiredStakeAmount)`: Admin function to modify existing claim types.
22. `deactivateClaimType(uint256 claimTypeId)`: Admin function to disable minting new Chronoscripts of a specific type.

**V. Reputation & Validation:**
23. `calculateUserReputation(address userAddress)`: Calculates a user's dynamic reputation score based on their active, valid, and attested Chronoscripts.
24. `getAttesterReputation(address attesterAddress)`: Returns the calculated reputation score for a whitelisted attester, based on their valid attestations.
25. `isChronoscriptValid(uint256 tokenId)`: A view function to check the current validity of a Chronoscript (active, not expired, sufficient attestations).

**VI. Epoch & Time Management (Admin Only):**
26. `startNewEpoch(string calldata description)`: Admin function to advance the contract into a new time-based epoch. Can trigger on-chain events or logic.
27. `endCurrentEpoch()`: Admin function to officially conclude the current epoch.

**VII. Staking & Value Layer:**
28. `stakeForChronoscript(uint256 tokenId) payable`: Allows a user to stake ETH for a Chronoscript if its `ClaimType` requires it.
29. `unstakeFromChronoscript(uint256 tokenId)`: Allows a user to retrieve their stake from a Chronoscript if it's no longer active or the stake requirement has been met/removed.

**VIII. Admin & Security:**
30. `pause()`: Pauses the contract, preventing certain state-changing operations (inherited from Pausable).
31. `unpause()`: Unpauses the contract (inherited from Pausable).
32. `transferOwnership(address newOwner)`: Transfers contract ownership (inherited from Ownable).
33. `withdrawFees()`: Allows the owner to withdraw collected fees (e.g., from staking or future fees).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title ChronoscribeNexus
 * @dev A decentralized, verifiable, and time-sensitive attestation platform for on-chain credentials.
 *      Allows users to mint dynamic "Chronoscripts" (NFTs) representing claims, which can expire,
 *      require renewal, and be attested by whitelisted entities. Includes a reputation layer,
 *      configurable claim types, and epoch-based progression.
 *
 * @outline
 * I. ERC-721 Core Functions: Standard NFT functionalities (balanceOf, ownerOf, transferFrom, approve, tokenURI).
 * II. Chronoscript Management: Minting, renewing, revoking, updating, and burning Chronoscripts.
 * III. Attestation & Whitelisting: System for whitelisted entities to attest to Chronoscripts and manage attester profiles.
 * IV. Claim Type Configuration: Admin-defined rules for different types of Chronoscripts (expiry, required attestations, stake).
 * V. Reputation & Validation: Dynamic calculation of user and attester reputation, and Chronoscript validity checks.
 * VI. Epoch & Time Management: Admin control over time-based epochs for contract progression.
 * VII. Staking & Value Layer: Mechanism for users to stake value against their Chronoscripts for enhanced credibility.
 * VIII. Admin & Security: Pause/unpause functionality and ownership management.
 */
contract ChronoscribeNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    uint256 public constant SECONDS_IN_DAY = 86400; // For easy duration calculations

    // Structs
    struct Chronoscript {
        address owner;
        bytes32 claimHash; // Hash of the off-chain verifiable claim data
        uint256 claimTypeId;
        uint64 issuedAt;
        uint64 expiresAt; // 0 for perpetual, otherwise timestamp
        bool isActive; // Can be revoked or become inactive if not renewed/attested
        uint256 attestationCount;
        mapping(address => bool) hasAttested; // attesterAddress => true
        uint256 stakedAmount; // Amount staked against this specific Chronoscript
    }

    struct ClaimType {
        string name;
        bool isRenewable;
        uint32 defaultExpiryDurationDays; // In days
        uint8 minAttestationsRequired;
        uint256 requiredStakeAmount; // In wei
        bool isActive; // Can be deactivated by admin
    }

    struct AttesterProfile {
        string name;
        bool isWhitelisted;
        uint256 attestationSuccessCount; // Number of currently active/valid Chronoscripts they attested to
        uint256 attestationFailureCount; // Number of revoked/expired Chronoscripts they attested to
    }

    struct Epoch {
        uint256 id;
        uint64 startTime;
        uint64 endTime;
        string description;
    }

    // Mappings
    mapping(uint256 => Chronoscript) public chronoscripts;
    mapping(uint256 => ClaimType) public claimTypes;
    mapping(address => AttesterProfile) public attesterProfiles;
    mapping(address => uint256[]) public userChronoscripts; // owner => list of tokenIds

    // Epochs
    uint256 public currentEpochId;
    mapping(uint256 => Epoch) public epochs;

    // Counters for unique IDs
    Counters.Counter private _claimTypeCounter;

    // --- Events ---
    event ChronoscriptMinted(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 indexed claimTypeId,
        bytes32 claimHash,
        uint64 expiresAt
    );
    event ChronoscriptRenewed(uint256 indexed tokenId, uint64 newExpiresAt);
    event ChronoscriptRevoked(uint256 indexed tokenId, address indexed revoker);
    event AttestationAdded(
        uint256 indexed tokenId,
        address indexed attester,
        uint256 newAttestationCount
    );
    event AttestationRevoked(
        uint256 indexed tokenId,
        address indexed attester,
        uint256 newAttestationCount
    );
    event AttesterWhitelisted(address indexed attester, string name);
    event AttesterRemoved(address indexed attester);
    event ClaimTypeAdded(
        uint256 indexed claimTypeId,
        string name,
        uint256 requiredStake
    );
    event ClaimTypeUpdated(uint256 indexed claimTypeId, string name);
    event ClaimTypeDeactivated(uint256 indexed claimTypeId);
    event EpochStarted(uint256 indexed epochId, uint64 startTime, string description);
    event EpochEnded(uint256 indexed epochId, uint64 endTime);
    event StakedForChronoscript(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event UnstakedFromChronoscript(uint256 indexed tokenId, address indexed unstaker, uint256 amount);

    // --- Custom Errors (for gas efficiency and clarity) ---
    error ChronoscriptNotFound(uint256 tokenId);
    error NotChronoscriptOwner(uint256 tokenId, address caller);
    error ChronoscriptExpired(uint256 tokenId);
    error ChronoscriptNotRenewable(uint256 tokenId);
    error ChronoscriptNotActive(uint256 tokenId);
    error ClaimTypeNotFound(uint256 claimTypeId);
    error ClaimTypeInactive(uint256 claimTypeId);
    error NotWhitelistedAttester(address caller);
    error AlreadyAttested(uint256 tokenId, address attester);
    error NoAttestationFound(uint256 tokenId, address attester);
    error InsufficientStake(uint256 required, uint256 provided);
    error NotStakedForThisChronoscript(uint256 tokenId, address caller);
    error EpochAlreadyActive(uint256 epochId);
    error EpochNotActive(uint256 epochId);

    // --- Constructor ---
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        _setBaseURI(baseURI_);
        // Initialize the first epoch
        currentEpochId = 1;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: uint64(block.timestamp),
            endTime: 0, // Unended
            description: "Genesis Epoch"
        });
        emit EpochStarted(currentEpochId, uint64(block.timestamp), "Genesis Epoch");
    }

    // --- Modifiers ---
    modifier ifChronoscriptExists(uint256 tokenId) {
        if (chronoscripts[tokenId].owner == address(0)) {
            revert ChronoscriptNotFound(tokenId);
        }
        _;
    }

    modifier ifClaimTypeExists(uint256 claimTypeId) {
        if (!claimTypes[claimTypeId].isActive) { // Check if it's active implies it exists
            revert ClaimTypeNotFound(claimTypeId);
        }
        _;
    }

    modifier onlyWhitelistedAttester() {
        if (!attesterProfiles[msg.sender].isWhitelisted) {
            revert NotWhitelistedAttester(msg.sender);
        }
        _;
    }

    // --- I. ERC-721 Core Functions (Standard) ---
    // Inherited from ERC721, no explicit implementation needed here for basic functions
    // tokenURI, supportsInterface, approve, getApproved, setApprovalForAll, isApprovedForAll
    // balanceOf, ownerOf, transferFrom, safeTransferFrom

    function tokenURI(uint256 tokenId)
        public
        view
        override
        ifChronoscriptExists(tokenId)
        returns (string memory)
    {
        // This can be overridden to point to a dynamic API endpoint that returns JSON metadata
        // based on the Chronoscript's on-chain state (e.g., active, expired, attestation count).
        // For simplicity, we return the baseURI + tokenId. This implies the real dynamism
        // is handled by an off-chain metadata service.
        return string(abi.encodePacked(super.tokenURI(tokenId), Strings.toString(tokenId)));
    }

    // --- II. Chronoscript Management (Core Logic) ---

    /**
     * @dev Mints a new Chronoscript.
     * @param to The address to mint the Chronoscript to.
     * @param claimHash A bytes32 hash representing the off-chain verifiable claim data.
     * @param claimTypeId The ID of the ClaimType this Chronoscript belongs to.
     * @param metadataURI The initial URI for the Chronoscript's metadata.
     */
    function mintChronoscript(
        address to,
        bytes32 claimHash,
        uint256 claimTypeId,
        string calldata metadataURI
    ) public payable whenNotPaused ifClaimTypeExists(claimTypeId) returns (uint256) {
        ClaimType storage claimType = claimTypes[claimTypeId];
        if (!claimType.isActive) {
            revert ClaimTypeInactive(claimTypeId);
        }
        if (msg.value < claimType.requiredStakeAmount) {
            revert InsufficientStake(claimType.requiredStakeAmount, msg.value);
        }

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        uint64 expiresAt_ = 0;
        if (claimType.defaultExpiryDurationDays > 0) {
            expiresAt_ = uint64(block.timestamp + claimType.defaultExpiryDurationDays * SECONDS_IN_DAY);
        }

        chronoscripts[newTokenId] = Chronoscript({
            owner: to,
            claimHash: claimHash,
            claimTypeId: claimTypeId,
            issuedAt: uint64(block.timestamp),
            expiresAt: expiresAt_,
            isActive: true,
            attestationCount: 0,
            stakedAmount: msg.value
        });
        userChronoscripts[to].push(newTokenId);

        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, metadataURI); // Note: dynamic URI implies this changes off-chain
        emit ChronoscriptMinted(newTokenId, to, claimTypeId, claimHash, expiresAt_);
        emit StakedForChronoscript(newTokenId, msg.sender, msg.value); // Even if msg.sender != to

        return newTokenId;
    }

    /**
     * @dev Renews an existing Chronoscript, extending its validity.
     * @param tokenId The ID of the Chronoscript to renew.
     */
    function renewChronoscript(
        uint256 tokenId
    ) public payable whenNotPaused ifChronoscriptExists(tokenId) {
        Chronoscript storage script = chronoscripts[tokenId];
        if (script.owner != msg.sender) {
            revert NotChronoscriptOwner(tokenId, msg.sender);
        }

        ClaimType storage claimType = claimTypes[script.claimTypeId];
        if (!claimType.isRenewable) {
            revert ChronoscriptNotRenewable(tokenId);
        }
        if (msg.value < claimType.requiredStakeAmount) {
            revert InsufficientStake(claimType.requiredStakeAmount, msg.value);
        }

        // Refund previous stake if any and update with new stake
        if (script.stakedAmount > 0) {
            payable(msg.sender).transfer(script.stakedAmount); // Refund existing stake
        }
        script.stakedAmount = msg.value; // Update with new stake

        // Reset attestation count, assuming renewal implies re-verification might be needed
        // This is a design choice: could also require re-attestation from existing ones.
        script.attestationCount = 0;
        // Clear existing attestations for re-attestation if needed
        // (This would require iterating a map, which is expensive. Better to just reset count and have new ones come in).
        // A more complex system might store attester addresses in a dynamic array for easy clearing.

        script.expiresAt = uint64(block.timestamp + claimType.defaultExpiryDurationDays * SECONDS_IN_DAY);
        script.isActive = true; // Mark as active on renewal
        emit ChronoscriptRenewed(tokenId, script.expiresAt);
        emit StakedForChronoscript(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Revokes a Chronoscript, rendering it inactive permanently.
     * @param tokenId The ID of the Chronoscript to revoke.
     */
    function revokeChronoscript(
        uint256 tokenId
    ) public whenNotPaused ifChronoscriptExists(tokenId) {
        Chronoscript storage script = chronoscripts[tokenId];
        if (script.owner != msg.sender) {
            revert NotChronoscriptOwner(tokenId, msg.sender);
        }
        if (!script.isActive) {
            revert ChronoscriptNotActive(tokenId);
        }

        script.isActive = false;
        // If there was a stake, refund it on revocation
        if (script.stakedAmount > 0) {
            payable(msg.sender).transfer(script.stakedAmount);
            emit UnstakedFromChronoscript(tokenId, msg.sender, script.stakedAmount);
            script.stakedAmount = 0;
        }

        emit ChronoscriptRevoked(tokenId, msg.sender);
    }

    /**
     * @dev Allows the owner of a Chronoscript to update its metadata URI.
     * @param tokenId The ID of the Chronoscript.
     * @param newURI The new URI for the metadata.
     */
    function updateChronoscriptMetadataURI(
        uint256 tokenId,
        string calldata newURI
    ) public whenNotPaused ifChronoscriptExists(tokenId) {
        if (chronoscripts[tokenId].owner != msg.sender) {
            revert NotChronoscriptOwner(tokenId, msg.sender);
        }
        _setTokenURI(tokenId, newURI);
    }

    /**
     * @dev Burns a Chronoscript, removing it from circulation.
     * @param tokenId The ID of the Chronoscript to burn.
     */
    function burnChronoscript(
        uint256 tokenId
    ) public whenNotPaused ifChronoscriptExists(tokenId) {
        if (chronoscripts[tokenId].owner != msg.sender) {
            revert NotChronoscriptOwner(tokenId, msg.sender);
        }
        // Refund stake if any
        if (chronoscripts[tokenId].stakedAmount > 0) {
            payable(msg.sender).transfer(chronoscripts[tokenId].stakedAmount);
            emit UnstakedFromChronoscript(tokenId, msg.sender, chronoscripts[tokenId].stakedAmount);
            chronoscripts[tokenId].stakedAmount = 0;
        }

        _burn(tokenId);
        chronoscripts[tokenId].isActive = false; // Mark as inactive/burned
        delete chronoscripts[tokenId]; // Clean up storage
        // Also remove from userChronoscripts array (expensive if not sorted, but for compliance)
        // For simplicity, we skip array removal here to avoid high gas cost for a burning operation.
        // A more gas-optimized approach for `userChronoscripts` might use a linked list or simply iterate on demand.
    }

    // --- III. Attestation & Whitelisting ---

    /**
     * @dev Allows a whitelisted attester to attest to a Chronoscript.
     * @param tokenId The ID of the Chronoscript to attest to.
     */
    function attestChronoscript(
        uint256 tokenId
    ) public whenNotPaused onlyWhitelistedAttester ifChronoscriptExists(tokenId) {
        Chronoscript storage script = chronoscripts[tokenId];
        if (!script.isActive || (script.expiresAt != 0 && script.expiresAt < block.timestamp)) {
            revert ChronoscriptExpired(tokenId); // Cannot attest to expired or inactive scripts
        }
        if (script.hasAttested[msg.sender]) {
            revert AlreadyAttested(tokenId, msg.sender);
        }

        script.hasAttested[msg.sender] = true;
        script.attestationCount++;
        attesterProfiles[msg.sender].attestationSuccessCount++;

        emit AttestationAdded(tokenId, msg.sender, script.attestationCount);
    }

    /**
     * @dev Allows a whitelisted attester to revoke their attestation for a Chronoscript.
     * @param tokenId The ID of the Chronoscript.
     */
    function revokeAttestation(
        uint256 tokenId
    ) public whenNotPaused onlyWhitelistedAttester ifChronoscriptExists(tokenId) {
        Chronoscript storage script = chronoscripts[tokenId];
        if (!script.hasAttested[msg.sender]) {
            revert NoAttestationFound(tokenId, msg.sender);
        }

        script.hasAttested[msg.sender] = false;
        script.attestationCount--;
        // Decrease success count if the script is still considered 'active' by the system
        // Otherwise, it implies the attester correctly revoked a potentially invalid claim
        // This logic can be more complex, reflecting the attester's judgment.
        if (script.isActive && (script.expiresAt == 0 || script.expiresAt >= block.timestamp)) {
             attesterProfiles[msg.sender].attestationSuccessCount--;
        } else {
             attesterProfiles[msg.sender].attestationFailureCount++; // Revoking an already invalid one
        }


        emit AttestationRevoked(tokenId, msg.sender, script.attestationCount);
    }

    /**
     * @dev Admin function to add a new address to the list of whitelisted attesters.
     * @param attesterAddress The address to whitelist.
     * @param name The name of the attester.
     */
    function addWhitelistedAttester(
        address attesterAddress,
        string calldata name
    ) public onlyOwner whenNotPaused {
        attesterProfiles[attesterAddress] = AttesterProfile({
            name: name,
            isWhitelisted: true,
            attestationSuccessCount: 0,
            attestationFailureCount: 0
        });
        emit AttesterWhitelisted(attesterAddress, name);
    }

    /**
     * @dev Admin function to remove an address from the list of whitelisted attesters.
     * @param attesterAddress The address to remove.
     */
    function removeWhitelistedAttester(
        address attesterAddress
    ) public onlyOwner whenNotPaused {
        if (!attesterProfiles[attesterAddress].isWhitelisted) {
            revert NotWhitelistedAttester(attesterAddress);
        }
        attesterProfiles[attesterAddress].isWhitelisted = false;
        // Optionally, clear their attestation counts or transfer them.
        emit AttesterRemoved(attesterAddress);
    }

    /**
     * @dev Allows a whitelisted attester to update their profile name.
     * @param newName The new name for the attester.
     */
    function updateAttesterProfile(
        string calldata newName
    ) public onlyWhitelistedAttester whenNotPaused {
        attesterProfiles[msg.sender].name = newName;
    }


    // --- IV. Claim Type Configuration (Admin Only) ---

    /**
     * @dev Admin function to add a new type of Chronoscript claim.
     * @param name The name of the claim type (e.g., "Verified Skill", "Project Contributor").
     * @param isRenewable True if Chronoscripts of this type can be renewed.
     * @param defaultExpiryDurationDays Default expiry duration in days (0 for perpetual).
     * @param minAttestationsRequired Minimum attestations needed for a Chronoscript of this type to be considered fully valid.
     * @param requiredStakeAmount Amount of ETH required to stake when minting this claim type.
     */
    function addClaimType(
        string calldata name,
        bool isRenewable,
        uint32 defaultExpiryDurationDays,
        uint8 minAttestationsRequired,
        uint256 requiredStakeAmount
    ) public onlyOwner whenNotPaused returns (uint256) {
        _claimTypeCounter.increment();
        uint256 newClaimTypeId = _claimTypeCounter.current();
        claimTypes[newClaimTypeId] = ClaimType({
            name: name,
            isRenewable: isRenewable,
            defaultExpiryDurationDays: defaultExpiryDurationDays,
            minAttestationsRequired: minAttestationsRequired,
            requiredStakeAmount: requiredStakeAmount,
            isActive: true
        });
        emit ClaimTypeAdded(newClaimTypeId, name, requiredStakeAmount);
        return newClaimTypeId;
    }

    /**
     * @dev Admin function to update an existing ClaimType.
     * @param claimTypeId The ID of the ClaimType to update.
     * @param newName The new name for the claim type.
     * @param newIsRenewable New renewable status.
     * @param newDefaultExpiryDurationDays New default expiry duration in days.
     * @param newMinAttestationsRequired New minimum attestations required.
     * @param newRequiredStakeAmount New required stake amount.
     */
    function updateClaimType(
        uint256 claimTypeId,
        string calldata newName,
        bool newIsRenewable,
        uint32 newDefaultExpiryDurationDays,
        uint8 newMinAttestationsRequired,
        uint256 newRequiredStakeAmount
    ) public onlyOwner whenNotPaused ifClaimTypeExists(claimTypeId) {
        ClaimType storage claimType = claimTypes[claimTypeId];
        claimType.name = newName;
        claimType.isRenewable = newIsRenewable;
        claimType.defaultExpiryDurationDays = newDefaultExpiryDurationDays;
        claimType.minAttestationsRequired = newMinAttestationsRequired;
        claimType.requiredStakeAmount = newRequiredStakeAmount;
        emit ClaimTypeUpdated(claimTypeId, newName);
    }

    /**
     * @dev Admin function to deactivate a ClaimType, preventing new Chronoscripts from being minted with it.
     * Existing Chronoscripts of this type remain valid according to their own rules.
     * @param claimTypeId The ID of the ClaimType to deactivate.
     */
    function deactivateClaimType(
        uint256 claimTypeId
    ) public onlyOwner whenNotPaused ifClaimTypeExists(claimTypeId) {
        claimTypes[claimTypeId].isActive = false;
        emit ClaimTypeDeactivated(claimTypeId);
    }


    // --- V. Reputation & Validation ---

    /**
     * @dev Calculates a user's reputation score based on their active, valid, and attested Chronoscripts.
     * The score is a simple sum of `attestationCount` for valid Chronoscripts.
     * More complex algorithms could be implemented (e.g., weighted by claim type, attester reputation).
     * @param userAddress The address of the user.
     * @return The calculated reputation score.
     */
    function calculateUserReputation(
        address userAddress
    ) public view returns (uint256 score) {
        score = 0;
        // This iterates through ALL Chronoscripts, which can be expensive for many.
        // In a real dApp, this would likely be off-chain computation or aggregate for specific queries.
        // For the sake of demonstrating the concept, we'll iterate.
        // Better: userChronoscripts array contains owned tokens for faster lookup.
        for (uint256 i = 0; i < userChronoscripts[userAddress].length; i++) {
            uint256 tokenId = userChronoscripts[userAddress][i];
            if (isChronoscriptValid(tokenId)) {
                score += chronoscripts[tokenId].attestationCount;
            }
        }
        return score;
    }

    /**
     * @dev Returns the current attester profile and a derived reputation score for a whitelisted attester.
     * @param attesterAddress The address of the attester.
     * @return name, isWhitelisted, successCount, failureCount, calculatedReputation.
     */
    function getAttesterReputation(
        address attesterAddress
    ) public view returns (string memory name, bool isWhitelisted, uint256 successCount, uint256 failureCount, uint256 calculatedReputation) {
        AttesterProfile storage profile = attesterProfiles[attesterAddress];
        return (
            profile.name,
            profile.isWhitelisted,
            profile.attestationSuccessCount,
            profile.attestationFailureCount,
            profile.attestationSuccessCount * 10 - profile.attestationFailureCount * 5 // Simple weighted formula
        );
    }

    /**
     * @dev Checks the current validity status of a Chronoscript.
     * @param tokenId The ID of the Chronoscript.
     * @return True if the Chronoscript is currently active, not expired, and has met minimum attestation requirements.
     */
    function isChronoscriptValid(
        uint256 tokenId
    ) public view ifChronoscriptExists(tokenId) returns (bool) {
        Chronoscript storage script = chronoscripts[tokenId];
        if (!script.isActive) {
            return false;
        }
        if (script.expiresAt != 0 && script.expiresAt < block.timestamp) {
            return false; // Expired
        }
        ClaimType storage claimType = claimTypes[script.claimTypeId];
        if (script.attestationCount < claimType.minAttestationsRequired) {
            return false; // Not enough attestations
        }
        return true;
    }

    // --- VI. Epoch & Time Management (Admin Only) ---

    /**
     * @dev Starts a new epoch. The previous epoch (if any) is automatically ended.
     * @param description A descriptive name for the new epoch.
     */
    function startNewEpoch(string calldata description) public onlyOwner whenNotPaused {
        if (epochs[currentEpochId].endTime == 0) { // If previous epoch is still running
            epochs[currentEpochId].endTime = uint64(block.timestamp);
            emit EpochEnded(currentEpochId, uint64(block.timestamp));
        }

        currentEpochId++;
        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            startTime: uint64(block.timestamp),
            endTime: 0,
            description: description
        });
        emit EpochStarted(currentEpochId, uint64(block.timestamp), description);
    }

    /**
     * @dev Ends the current active epoch.
     */
    function endCurrentEpoch() public onlyOwner whenNotPaused {
        if (epochs[currentEpochId].endTime != 0) {
            revert EpochNotActive(currentEpochId); // Epoch is already ended
        }
        epochs[currentEpochId].endTime = uint64(block.timestamp);
        emit EpochEnded(currentEpochId, uint64(block.timestamp));
    }

    /**
     * @dev Returns details of a specific epoch.
     * @param epochId The ID of the epoch.
     */
    function getEpochDetails(
        uint256 epochId
    ) public view returns (uint256 id, uint64 startTime, uint64 endTime, string memory description) {
        Epoch storage epoch = epochs[epochId];
        return (epoch.id, epoch.startTime, epoch.endTime, epoch.description);
    }

    // --- VII. Staking & Value Layer ---

    /**
     * @dev Allows a user to stake ETH for a Chronoscript to meet its requiredStakeAmount.
     * Can be called by the Chronoscript owner or another party.
     * @param tokenId The ID of the Chronoscript to stake for.
     */
    function stakeForChronoscript(
        uint256 tokenId
    ) public payable whenNotPaused ifChronoscriptExists(tokenId) {
        Chronoscript storage script = chronoscripts[tokenId];
        ClaimType storage claimType = claimTypes[script.claimTypeId];

        uint256 currentStaked = script.stakedAmount;
        uint256 required = claimType.requiredStakeAmount;
        uint256 remainingNeeded = (required > currentStaked) ? (required - currentStaked) : 0;

        if (remainingNeeded == 0 && msg.value == 0) {
            // Already met or no stake required and no new stake provided
            return;
        }

        if (msg.value < remainingNeeded) {
            revert InsufficientStake(remainingNeeded, msg.value);
        }

        script.stakedAmount += msg.value;
        emit StakedForChronoscript(tokenId, msg.sender, msg.value);

        // If over-staked, refund the excess
        if (script.stakedAmount > required) {
            uint256 excess = script.stakedAmount - required;
            script.stakedAmount = required;
            payable(msg.sender).transfer(excess);
        }
    }

    /**
     * @dev Allows the Chronoscript owner to unstake ETH if the Chronoscript is no longer valid,
     * or if the stake requirement for its type has been removed/reduced to zero.
     * @param tokenId The ID of the Chronoscript to unstake from.
     */
    function unstakeFromChronoscript(
        uint256 tokenId
    ) public whenNotPaused ifChronoscriptExists(tokenId) {
        Chronoscript storage script = chronoscripts[tokenId];
        if (script.owner != msg.sender) {
            revert NotChronoscriptOwner(tokenId, msg.sender);
        }
        if (script.stakedAmount == 0) {
            revert NotStakedForThisChronoscript(tokenId, msg.sender);
        }

        ClaimType storage claimType = claimTypes[script.claimTypeId];

        // Allow unstaking if the script is not active OR if its claim type no longer requires a stake
        // This prevents users from retrieving stakes from currently valid, stake-requiring Chronoscripts.
        if (isChronoscriptValid(tokenId) && claimType.requiredStakeAmount > 0) {
            revert("Cannot unstake from an active, stake-requiring Chronoscript.");
        }

        uint256 amountToUnstake = script.stakedAmount;
        script.stakedAmount = 0;
        payable(msg.sender).transfer(amountToUnstake);
        emit UnstakedFromChronoscript(tokenId, msg.sender, amountToUnstake);
    }

    // --- VIII. Admin & Security ---

    /**
     * @dev Pauses the contract, preventing certain state-changing operations.
     * Requires `Ownable` permission.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * Requires `Ownable` permission.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw any ETH accumulated in the contract
     * from staking or fees (if fees were implemented).
     */
    function withdrawFees() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Internal function to set the base URI for token metadata.
     * Used by constructor and potentially for future updates by owner.
     */
    function _setBaseURI(string memory baseURI_) internal {
        _baseURI = baseURI_;
    }

    // --- View Functions for Data Retrieval ---

    /**
     * @dev Returns the details of a specific Chronoscript.
     */
    function getChronoscriptDetails(
        uint256 tokenId
    ) public view ifChronoscriptExists(tokenId) returns (
        address owner,
        bytes32 claimHash,
        uint256 claimTypeId,
        uint64 issuedAt,
        uint64 expiresAt,
        bool isActive,
        uint256 attestationCount,
        uint256 stakedAmount
    ) {
        Chronoscript storage s = chronoscripts[tokenId];
        return (
            s.owner,
            s.claimHash,
            s.claimTypeId,
            s.issuedAt,
            s.expiresAt,
            s.isActive,
            s.attestationCount,
            s.stakedAmount
        );
    }

    /**
     * @dev Returns the details of a specific ClaimType.
     */
    function getClaimTypeDetails(
        uint256 claimTypeId
    ) public view ifClaimTypeExists(claimTypeId) returns (
        string memory name,
        bool isRenewable,
        uint32 defaultExpiryDurationDays,
        uint8 minAttestationsRequired,
        uint256 requiredStakeAmount,
        bool isActive
    ) {
        ClaimType storage ct = claimTypes[claimTypeId];
        return (
            ct.name,
            ct.isRenewable,
            ct.defaultExpiryDurationDays,
            ct.minAttestationsRequired,
            ct.requiredStakeAmount,
            ct.isActive
        );
    }

    /**
     * @dev Returns an array of Chronoscript token IDs owned by a specific address.
     * Note: This array might contain "gaps" if tokens are burned, but `isChronoscriptValid` or `getChronoscriptDetails`
     * will correctly identify non-existent or inactive ones. For large numbers of NFTs, iterating this can be costly.
     */
    function getUserChronoscripts(address userAddress) public view returns (uint256[] memory) {
        return userChronoscripts[userAddress];
    }

    /**
     * @dev Checks if a given address is a whitelisted attester.
     */
    function isAttesterWhitelisted(address addr) public view returns (bool) {
        return attesterProfiles[addr].isWhitelisted;
    }
}
```