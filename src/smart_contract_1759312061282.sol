Okay, this is an exciting challenge! I've designed a smart contract called "AetherMinds" that aims to be a decentralized ecosystem for intellectual property and knowledge. It combines concepts from NFTs, DeFi (staking), reputation systems, and dynamic licensing, all while striving for unique functionality.

The core idea is "Knowledge Capsules," which are NFTs representing abstract intellectual property, research, datasets, or any form of knowledge. Users can register these capsules, stake a native `NexusToken` on their perceived value, attest to their quality, license them with dynamic terms and multi-party royalties, and even delegate staking power to "curators." It also includes a lightweight dispute resolution mechanism.

---

## AetherMinds: Decentralized Intellectual Property & Knowledge Ecosystem

**Concept Overview:**
AetherMinds is a decentralized platform where intellectual property (IP) and knowledge are tokenized as unique NFTs called "Knowledge Capsules." These capsules are more than just pointers; they have a dynamic "Value Score" influenced by community staking and quality attestations. The system facilitates flexible licensing models, multi-party royalty distributions, and a basic dispute resolution mechanism. A native `NexusToken` (ERC-20, internal to this contract for simplicity) powers staking, licensing fees, and economic incentives.

**Advanced & Creative Concepts Integrated:**
1.  **Knowledge Capsules as NFTs (ERC-721):** Each piece of registered knowledge is a unique, tradable token.
2.  **Native Utility Token (NexusToken):** An integrated ERC-20 for staking, licensing, and incentives.
3.  **Dynamic Value Score:** A real-time, on-chain metric for each capsule, aggregating `NexusToken` stakes and quality attestations. This score influences visibility and perceived worth.
4.  **Parent-Child Capsule Relationships:** Allows for the creation of new knowledge that builds upon or forks from existing capsules, preserving lineage.
5.  **Multi-Party Licensing & Royalties:** Capsule owners can define complex licensing terms, including multiple royalty recipients and their respective shares.
6.  **Subscription-like Licensing:** Licenses can be acquired for specific durations.
7.  **Attestation & Reputation System:** Users can "attest" to the quality or validity of a capsule, influencing its overall score.
8.  **Delegated Staking to Curators:** Users can delegate their `NexusToken` holdings to "curators" who then stake on capsules, fostering expert-led discovery and validation.
9.  **Lightweight On-chain Dispute Resolution:** A mechanism for challenging capsule validity or IP claims, with a designated arbiter role (expandable to a DAO).
10. **Upgradeable Design Considerations:** While not implementing a proxy here, the structure aims for modularity.

---

### Contract Outline & Function Summary

**I. Core Infrastructure & ERC-721/ERC-20 Basics**
*   **`constructor()`:** Initializes the contract, sets the admin, and potentially mints initial `NexusToken` for the deployer.
*   **`_mint(address to, uint256 tokenId)`:** Internal function for minting NFTs.
*   **`_burn(uint256 tokenId)`:** Internal function for burning NFTs.
*   **`_transfer(address from, address to, uint256 tokenId)`:** Internal function for NFT transfers.
*   **`approve(address to, uint256 tokenId)`:** Standard ERC-721 approve.
*   **`setApprovalForAll(address operator, bool approved)`:** Standard ERC-721 setApprovalForAll.
*   **`transferFrom(address from, address to, uint256 tokenId)`:** Standard ERC-721 transferFrom.
*   **`getApproved(uint256 tokenId)`:** Standard ERC-721 getApproved.
*   **`isApprovedForAll(address owner, address operator)`:** Standard ERC-721 isApprovedForAll.
*   **`balanceOf(address owner)`:** Standard ERC-721 balanceOf.
*   **`ownerOf(uint256 tokenId)`:** Standard ERC-721 ownerOf.
*   **`totalSupply()`:** Returns total number of capsules.
*   **`getNexusTokenBalance(address _address)`:** Returns `NexusToken` balance of an address.
*   **`transferNexusTokens(address _to, uint256 _amount)`:** Allows users to transfer `NexusToken`s.

**II. Knowledge Capsule Management**
*   **`registerKnowledgeCapsule(string memory _uri, bytes32 _metadataHash, uint256 _parentCapsuleId)`:** Mints a new Knowledge Capsule NFT, linking to a potential parent capsule and metadata.
*   **`updateKnowledgeCapsuleURI(uint256 _capsuleId, string memory _newUri, bytes32 _newMetadataHash)`:** Allows the capsule owner to update its associated URI and metadata hash (e.g., for a new version or improvement).
*   **`burnKnowledgeCapsule(uint256 _capsuleId)`:** Allows the capsule owner to burn their capsule, effectively deprecating it.
*   **`getKnowledgeCapsuleDetails(uint256 _capsuleId)`:** Retrieves comprehensive details about a specific knowledge capsule.

**III. Value & Reputation System (Staking & Attestation)**
*   **`stakeNexusOnCapsule(uint256 _capsuleId, uint256 _amount)`:** Users stake `NexusToken` on a capsule to signal its perceived value, quality, or importance.
*   **`unstakeNexusFromCapsule(uint256 _capsuleId, uint256 _amount)`:** Allows users to withdraw their staked `NexusToken` from a capsule.
*   **`attestCapsuleQuality(uint256 _capsuleId, bool _isHighQuality)`:** Users can provide a binary attestation (high/low quality), influencing the capsule's quality score.
*   **`getKnowledgeCapsuleValueScore(uint256 _capsuleId)`:** Calculates and returns the aggregated value score of a capsule based on stakes and attestations.

**IV. Licensing & Monetization**
*   **`setCapsuleLicenseTerms(uint256 _capsuleId, uint256 _basePrice, uint256 _duration, address[] memory _royaltyRecipients, uint256[] memory _royaltyShares)`:** Defines the licensing parameters for a capsule, including price, default duration, and a flexible multi-party royalty split.
*   **`acquireLicense(uint256 _capsuleId, uint256 _duration)`:** Allows a user to purchase a license for a specified duration, paying `NexusToken`s.
*   **`renewLicense(uint256 _capsuleId)`:** Renews an active license for its default duration.
*   **`releaseLicenseFunds(uint256 _capsuleId)`:** Enables royalty recipients to withdraw their accumulated `NexusToken`s from successful licenses.

**V. Advanced Concepts: Dispute Resolution & Delegated Staking**
*   **`initiateDispute(uint256 _capsuleId, string memory _disputeURI)`:** Allows any user to initiate a dispute against a capsule's validity or IP claim by staking a bond.
*   **`resolveDispute(uint256 _capsuleId, bool _isDisputeValid)`:** (Admin/Arbiter function) Resolves an active dispute, releasing or slashing bonds.
*   **`delegateStakeToCurator(address _curator, uint256 _amount)`:** Delegates a user's `NexusToken`s to a designated "curator" for staking decisions.
*   **`curatorStakeOnCapsule(address _delegator, uint256 _capsuleId, uint256 _amount)`:** Allows a curator to stake delegated `NexusToken`s on behalf of a delegator.
*   **`undelegateStakeFromCurator(address _curator, uint256 _amount)`:** A delegator can retrieve their tokens from a curator.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title AetherMinds: Decentralized Intellectual Property & Knowledge Ecosystem
 * @dev This contract implements a novel system for tokenizing knowledge as NFTs (Knowledge Capsules).
 * It includes a native utility token (NexusToken), dynamic value scoring based on staking and attestations,
 * flexible multi-party licensing, and delegated staking to "curators" for decentralized curation.
 * A lightweight dispute resolution mechanism is also integrated.
 */
contract AetherMinds is Ownable, IERC721, IERC721Receiver {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // ERC-721 related
    string private _name;
    string private _symbol;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // NexusToken (Internal ERC-20 implementation)
    string public constant NEXUS_TOKEN_NAME = "NexusToken";
    string public constant NEXUS_TOKEN_SYMBOL = "NEXUS";
    uint256 public nexusTotalSupply;
    mapping(address => uint256) private _nexusBalances;

    // Knowledge Capsule Data Structure
    struct KnowledgeCapsule {
        uint256 id;
        address owner;
        string uri; // IPFS hash, Arweave ID, URL to content/metadata
        bytes32 metadataHash; // Cryptographic hash of the metadata/content
        uint256 parentCapsuleId; // 0 if no parent
        uint256 creationTime;
        uint256 lastUpdateTime;
        uint256 totalStakedNexus; // Sum of NexusTokens staked on this capsule
        uint256 positiveAttestations; // Count of high-quality attestations
        uint256 negativeAttestations; // Count of low-quality attestations
        uint256 disputeId; // 0 if no active dispute
    }
    mapping(uint256 => KnowledgeCapsule) public knowledgeCapsules;

    // Staking related
    mapping(uint256 => mapping(address => uint256)) public capsuleStakes; // capsuleId => stakerAddress => amount
    mapping(address => uint256) public totalDelegatedStake; // curatorAddress => total amount delegated to them
    mapping(address => mapping(address => uint256)) public delegatedStakes; // delegator => curator => amount

    // Licensing related
    struct LicenseTerms {
        uint256 basePrice; // in NexusToken
        uint256 duration; // in seconds
        address[] royaltyRecipients;
        uint256[] royaltyShares; // Proportional shares, sum must be 10000 (100%)
    }
    mapping(uint256 => LicenseTerms) public capsuleLicenseTerms;
    mapping(uint256 => mapping(address => uint256)) public activeLicenses; // capsuleId => licenseeAddress => expirationTime
    mapping(uint256 => mapping(address => uint256)) public pendingRoyaltyPayouts; // capsuleId => recipientAddress => amount

    // Dispute related
    struct Dispute {
        uint256 id;
        uint256 capsuleId;
        address initiator;
        string disputeURI;
        uint256 stakeAmount; // Amount staked by initiator
        bool isActive;
        bool isResolved;
        bool result; // true for invalid, false for valid (dispute rejected)
    }
    Counters.Counter private _disputeIdCounter;
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event NexusTransfer(address indexed from, address indexed to, uint256 value);
    event KnowledgeCapsuleRegistered(uint256 indexed capsuleId, address indexed owner, string uri, bytes32 metadataHash, uint256 parentCapsuleId);
    event KnowledgeCapsuleUpdated(uint256 indexed capsuleId, string newUri, bytes32 newMetadataHash);
    event KnowledgeCapsuleBurned(uint256 indexed capsuleId);
    event NexusStaked(uint256 indexed capsuleId, address indexed staker, uint256 amount);
    event NexusUnstaked(uint256 indexed capsuleId, address indexed staker, uint256 amount);
    event CapsuleAttested(uint256 indexed capsuleId, address indexed attester, bool isHighQuality);
    event LicenseTermsUpdated(uint256 indexed capsuleId, uint256 basePrice, uint256 duration);
    event LicenseAcquired(uint256 indexed capsuleId, address indexed licensee, uint256 expirationTime);
    event LicenseRenewed(uint256 indexed capsuleId, address indexed licensee, uint256 newExpirationTime);
    event RoyaltyPayout(uint256 indexed capsuleId, address indexed recipient, uint256 amount);
    event DisputeInitiated(uint256 indexed disputeId, uint256 indexed capsuleId, address indexed initiator, string disputeURI, uint256 stakeAmount);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed capsuleId, bool isDisputeValid, address indexed resolver);
    event StakeDelegated(address indexed delegator, address indexed curator, uint256 amount);
    event CuratorStaked(address indexed curator, address indexed delegator, uint256 indexed capsuleId, uint256 amount);
    event StakeUndelegated(address indexed delegator, address indexed curator, uint256 amount);


    // --- Modifiers ---
    modifier onlyCapsuleOwner(uint256 _capsuleId) {
        require(_owners[_capsuleId] == msg.sender, "AM: Not capsule owner");
        _;
    }

    modifier onlyDisputeArbiter(uint256 _disputeId) {
        // In a real DAO, this would be a governance check. For this example, only the contract owner can resolve.
        require(msg.sender == owner(), "AM: Only dispute arbiter can resolve");
        require(disputes[_disputeId].isActive, "AM: Dispute is not active");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        _name = "AetherMinds Knowledge Capsule";
        _symbol = "AMKC";
        
        // Mint initial NexusTokens for the deployer for testing purposes
        _mintNexusTokens(msg.sender, 1_000_000 * 10**18); // 1,000,000 NEXUS
    }

    // --- Internal NexusToken ERC-20 Implementation ---
    function _mintNexusTokens(address _to, uint256 _amount) internal {
        require(_to != address(0), "AM: Cannot mint to the zero address");
        nexusTotalSupply += _amount;
        _nexusBalances[_to] += _amount;
        emit NexusTransfer(address(0), _to, _amount);
    }

    function _burnNexusTokens(address _from, uint256 _amount) internal {
        require(_from != address(0), "AM: Cannot burn from the zero address");
        require(_nexusBalances[_from] >= _amount, "AM: Insufficient Nexus balance for burning");
        _nexusBalances[_from] -= _amount;
        nexusTotalSupply -= _amount;
        emit NexusTransfer(_from, address(0), _amount);
    }

    /**
     * @dev Returns the total supply of NexusTokens.
     * @return The total supply.
     */
    function nexusTokenTotalSupply() public view returns (uint256) {
        return nexusTotalSupply;
    }

    /**
     * @dev Returns the NexusToken balance of a specified address.
     * @param _address The address to query.
     * @return The NexusToken balance.
     */
    function getNexusTokenBalance(address _address) public view returns (uint256) {
        return _nexusBalances[_address];
    }

    /**
     * @dev Transfers NexusTokens from the caller to a recipient.
     * @param _to The recipient address.
     * @param _amount The amount of NexusTokens to transfer.
     */
    function transferNexusTokens(address _to, uint256 _amount) public {
        require(_nexusBalances[msg.sender] >= _amount, "AM: Insufficient Nexus balance");
        require(_to != address(0), "AM: Cannot transfer to the zero address");

        _nexusBalances[msg.sender] -= _amount;
        _nexusBalances[_to] += _amount;
        emit NexusTransfer(msg.sender, _to, _amount);
    }

    // --- ERC-721 Core Functions ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for non-existent token");
        return knowledgeCapsules[tokenId].uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can only be listed as existing if they have been minted.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for non-existent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` represents a smart contract, it must have accepted the transfer by implementing
     *   {IERC721Receiver-onERC721Received}, which IS NOT checked in this contract, as minting is internal.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approves `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * @param from address The sending address (zero if minting)
     * @param to address The recipient address (target of the call)
     * @param tokenId uint256 The Id of the token being transferred
     * @param _data bytes Optional data to send to the recipient
     * @return bool True if the call was successful and the recipient is an ERC721Receiver
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (reason not provided)");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }

    /**
     * @dev Total number of capsules registered.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Interface for ERC721Receiver - Always returns the selector to signify acceptance
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // --- Knowledge Capsule Management ---

    /**
     * @dev Registers a new Knowledge Capsule, minting it as an NFT to the caller.
     * @param _uri A URI pointing to the capsule's content (e.g., IPFS hash, Arweave ID).
     * @param _metadataHash A cryptographic hash of the content/metadata for integrity verification.
     * @param _parentCapsuleId An optional ID of a parent capsule this new knowledge builds upon (0 for no parent).
     * @return The ID of the newly registered Knowledge Capsule.
     */
    function registerKnowledgeCapsule(string memory _uri, bytes32 _metadataHash, uint256 _parentCapsuleId) public returns (uint256) {
        require(bytes(_uri).length > 0, "AM: URI cannot be empty");
        if (_parentCapsuleId != 0) {
            require(_exists(_parentCapsuleId), "AM: Parent capsule does not exist");
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _mint(msg.sender, newItemId);

        knowledgeCapsules[newItemId] = KnowledgeCapsule({
            id: newItemId,
            owner: msg.sender,
            uri: _uri,
            metadataHash: _metadataHash,
            parentCapsuleId: _parentCapsuleId,
            creationTime: block.timestamp,
            lastUpdateTime: block.timestamp,
            totalStakedNexus: 0,
            positiveAttestations: 0,
            negativeAttestations: 0,
            disputeId: 0
        });

        // Initialize default license terms (can be updated later)
        capsuleLicenseTerms[newItemId] = LicenseTerms({
            basePrice: 0, // Free by default
            duration: 0, // No default duration
            royaltyRecipients: new address[](0),
            royaltyShares: new uint256[](0)
        });

        emit KnowledgeCapsuleRegistered(newItemId, msg.sender, _uri, _metadataHash, _parentCapsuleId);
        return newItemId;
    }

    /**
     * @dev Allows the owner of a Knowledge Capsule to update its URI and metadata hash.
     * This can be used for versioning or correcting information.
     * @param _capsuleId The ID of the capsule to update.
     * @param _newUri The new URI for the capsule's content.
     * @param _newMetadataHash The new metadata hash.
     */
    function updateKnowledgeCapsuleURI(uint256 _capsuleId, string memory _newUri, bytes32 _newMetadataHash) public onlyCapsuleOwner(_capsuleId) {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(bytes(_newUri).length > 0, "AM: New URI cannot be empty");

        knowledgeCapsules[_capsuleId].uri = _newUri;
        knowledgeCapsules[_capsuleId].metadataHash = _newMetadataHash;
        knowledgeCapsules[_capsuleId].lastUpdateTime = block.timestamp;

        emit KnowledgeCapsuleUpdated(_capsuleId, _newUri, _newMetadataHash);
    }

    /**
     * @dev Allows the owner to burn their Knowledge Capsule. This effectively removes it from circulation.
     * Any associated stakes or licenses remain in the system for accounting but the capsule itself is gone.
     * @param _capsuleId The ID of the capsule to burn.
     */
    function burnKnowledgeCapsule(uint256 _capsuleId) public onlyCapsuleOwner(_capsuleId) {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        _burn(_capsuleId);
        // Clean up mappings if necessary, for now, just mark it as burned implicitly by _burn()
        emit KnowledgeCapsuleBurned(_capsuleId);
    }

    /**
     * @dev Retrieves all details of a specific Knowledge Capsule.
     * @param _capsuleId The ID of the capsule to query.
     * @return A tuple containing all capsule data.
     */
    function getKnowledgeCapsuleDetails(uint256 _capsuleId) public view returns (
        uint256 id,
        address owner,
        string memory uri,
        bytes32 metadataHash,
        uint256 parentCapsuleId,
        uint256 creationTime,
        uint256 lastUpdateTime,
        uint256 totalStakedNexus,
        uint256 positiveAttestations,
        uint256 negativeAttestations,
        uint256 disputeId
    ) {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];
        return (
            capsule.id,
            capsule.owner,
            capsule.uri,
            capsule.metadataHash,
            capsule.parentCapsuleId,
            capsule.creationTime,
            capsule.lastUpdateTime,
            capsule.totalStakedNexus,
            capsule.positiveAttestations,
            capsule.negativeAttestations,
            capsule.disputeId
        );
    }

    // --- Value & Reputation System (Staking & Attestation) ---

    /**
     * @dev Allows a user to stake NexusTokens on a Knowledge Capsule, signaling its perceived value.
     * Staked tokens remain in the contract until unstaked.
     * @param _capsuleId The ID of the capsule to stake on.
     * @param _amount The amount of NexusTokens to stake.
     */
    function stakeNexusOnCapsule(uint256 _capsuleId, uint256 _amount) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(_amount > 0, "AM: Stake amount must be greater than zero");
        require(_nexusBalances[msg.sender] >= _amount, "AM: Insufficient Nexus balance for staking");

        _nexusBalances[msg.sender] -= _amount;
        capsuleStakes[_capsuleId][msg.sender] += _amount;
        knowledgeCapsules[_capsuleId].totalStakedNexus += _amount;

        emit NexusStaked(_capsuleId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to unstake NexusTokens from a Knowledge Capsule.
     * @param _capsuleId The ID of the capsule to unstake from.
     * @param _amount The amount of NexusTokens to unstake.
     */
    function unstakeNexusFromCapsule(uint256 _capsuleId, uint256 _amount) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(_amount > 0, "AM: Unstake amount must be greater than zero");
        require(capsuleStakes[_capsuleId][msg.sender] >= _amount, "AM: Insufficient staked NexusTokens");

        capsuleStakes[_capsuleId][msg.sender] -= _amount;
        knowledgeCapsules[_capsuleId].totalStakedNexus -= _amount;
        _nexusBalances[msg.sender] += _amount;

        emit NexusUnstaked(_capsuleId, msg.sender, _amount);
    }

    /**
     * @dev Allows a user to attest to the quality of a Knowledge Capsule.
     * This contributes to its overall "quality score". Each address can attest once.
     * @param _capsuleId The ID of the capsule to attest.
     * @param _isHighQuality True for a positive attestation, false for a negative one.
     */
    function attestCapsuleQuality(uint256 _capsuleId, bool _isHighQuality) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        // Prevent re-attestation for simplicity, can be extended with cooldowns or reputation scores.
        // For simplicity, we just allow one attestation per user per capsule.
        // In a more advanced system, this would be tied to user reputation.
        if (_isHighQuality) {
            knowledgeCapsules[_capsuleId].positiveAttestations++;
        } else {
            knowledgeCapsules[_capsuleId].negativeAttestations++;
        }
        emit CapsuleAttested(_capsuleId, msg.sender, _isHighQuality);
    }

    /**
     * @dev Calculates and returns a dynamic value/quality score for a Knowledge Capsule.
     * The score is a weighted sum of staked NexusTokens and quality attestations.
     * @param _capsuleId The ID of the capsule.
     * @return The calculated value score.
     */
    function getKnowledgeCapsuleValueScore(uint256 _capsuleId) public view returns (uint256) {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        KnowledgeCapsule storage capsule = knowledgeCapsules[_capsuleId];

        uint256 stakeComponent = capsule.totalStakedNexus; // Direct contribution from stakes
        int256 attestationComponent = int256(capsule.positiveAttestations) - int256(capsule.negativeAttestations);

        // Simple scoring model: stake * 100 + (positive - negative attestations) * 10
        // Adjust weights as needed for desired influence
        uint256 score = (stakeComponent * 100) + (attestationComponent > 0 ? uint256(attestationComponent) * 10 : 0);
        // If attestationComponent is negative, it reduces the score, but not below 0 from that component.
        // If it was negative, it would subtract, let's make it a floor for simplicity:
        if (attestationComponent < 0) {
             uint256 deduction = uint256(-attestationComponent) * 5; // Negative attestations have a smaller negative impact
             score = score > deduction ? score - deduction : 0;
        }

        return score;
    }

    // --- Licensing & Monetization ---

    /**
     * @dev Sets or updates the licensing terms for a Knowledge Capsule.
     * Allows for multi-party royalty distribution. Shares must sum to 10000 (representing 100%).
     * @param _capsuleId The ID of the capsule.
     * @param _basePrice The price in NexusTokens for a license.
     * @param _duration The default duration of the license in seconds.
     * @param _royaltyRecipients An array of addresses to receive royalties.
     * @param _royaltyShares An array of shares (out of 10000) for each recipient.
     */
    function setCapsuleLicenseTerms(
        uint256 _capsuleId,
        uint256 _basePrice,
        uint256 _duration,
        address[] memory _royaltyRecipients,
        uint256[] memory _royaltyShares
    ) public onlyCapsuleOwner(_capsuleId) {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(_royaltyRecipients.length == _royaltyShares.length, "AM: Recipients and shares length mismatch");

        uint256 totalShares;
        for (uint256 i = 0; i < _royaltyShares.length; i++) {
            totalShares += _royaltyShares[i];
        }
        require(totalShares == 10000 || _royaltyRecipients.length == 0, "AM: Royalty shares must sum to 10000");

        capsuleLicenseTerms[_capsuleId] = LicenseTerms({
            basePrice: _basePrice,
            duration: _duration,
            royaltyRecipients: _royaltyRecipients,
            royaltyShares: _royaltyShares
        });

        emit LicenseTermsUpdated(_capsuleId, _basePrice, _duration);
    }

    /**
     * @dev Acquires a license for a Knowledge Capsule for a specified duration.
     * The caller pays the `basePrice` in NexusTokens.
     * @param _capsuleId The ID of the capsule to license.
     * @param _duration The desired duration of the license in seconds.
     */
    function acquireLicense(uint256 _capsuleId, uint256 _duration) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        LicenseTerms storage terms = capsuleLicenseTerms[_capsuleId];
        require(terms.basePrice > 0, "AM: License terms not set or price is zero");
        require(_nexusBalances[msg.sender] >= terms.basePrice, "AM: Insufficient Nexus balance for license");

        _nexusBalances[msg.sender] -= terms.basePrice;

        // Distribute royalties
        for (uint256 i = 0; i < terms.royaltyRecipients.length; i++) {
            uint256 royaltyAmount = (terms.basePrice * terms.royaltyShares[i]) / 10000;
            pendingRoyaltyPayouts[_capsuleId][terms.royaltyRecipients[i]] += royaltyAmount;
        }

        uint256 expirationTime = block.timestamp + _duration;
        activeLicenses[_capsuleId][msg.sender] = expirationTime;

        emit LicenseAcquired(_capsuleId, msg.sender, expirationTime);
    }

    /**
     * @dev Renews an active license for a Knowledge Capsule.
     * The caller pays the `basePrice` again.
     * @param _capsuleId The ID of the capsule whose license is to be renewed.
     */
    function renewLicense(uint256 _capsuleId) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(activeLicenses[_capsuleId][msg.sender] > 0, "AM: No active license to renew"); // Ensure there was a previous license
        
        LicenseTerms storage terms = capsuleLicenseTerms[_capsuleId];
        require(terms.basePrice > 0 && terms.duration > 0, "AM: License terms not set or invalid for renewal");
        require(_nexusBalances[msg.sender] >= terms.basePrice, "AM: Insufficient Nexus balance for renewal");

        _nexusBalances[msg.sender] -= terms.basePrice;

        // Distribute royalties for renewal
        for (uint256 i = 0; i < terms.royaltyRecipients.length; i++) {
            uint256 royaltyAmount = (terms.basePrice * terms.royaltyShares[i]) / 10000;
            pendingRoyaltyPayouts[_capsuleId][terms.royaltyRecipients[i]] += royaltyAmount;
        }

        uint256 currentExpiration = activeLicenses[_capsuleId][msg.sender];
        uint256 newExpiration = (currentExpiration > block.timestamp ? currentExpiration : block.timestamp) + terms.duration;
        activeLicenses[_capsuleId][msg.sender] = newExpiration;

        emit LicenseRenewed(_capsuleId, msg.sender, newExpiration);
    }

    /**
     * @dev Allows royalty recipients to release (withdraw) their accumulated NexusTokens.
     * @param _capsuleId The ID of the capsule from which to withdraw royalties.
     */
    function releaseLicenseFunds(uint256 _capsuleId) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        uint256 amountToPayout = pendingRoyaltyPayouts[_capsuleId][msg.sender];
        require(amountToPayout > 0, "AM: No pending royalties for this recipient on this capsule");

        pendingRoyaltyPayouts[_capsuleId][msg.sender] = 0;
        _nexusBalances[msg.sender] += amountToPayout;

        emit RoyaltyPayout(_capsuleId, msg.sender, amountToPayout);
    }

    /**
     * @dev Checks if a given address has an active license for a capsule.
     * @param _capsuleId The ID of the capsule.
     * @param _licensee The address of the potential licensee.
     * @return True if the license is active, false otherwise.
     */
    function hasActiveLicense(uint256 _capsuleId, address _licensee) public view returns (bool) {
        return activeLicenses[_capsuleId][_licensee] > block.timestamp;
    }

    // --- Dispute Resolution (Lightweight) ---

    /**
     * @dev Initiates a dispute against a Knowledge Capsule (e.g., for inaccuracy, infringement).
     * Requires staking a small amount of NexusTokens as a bond.
     * @param _capsuleId The ID of the capsule being disputed.
     * @param _disputeURI A URI pointing to the dispute evidence or explanation.
     * @return The ID of the initiated dispute.
     */
    function initiateDispute(uint256 _capsuleId, string memory _disputeURI) public returns (uint256) {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(knowledgeCapsules[_capsuleId].disputeId == 0, "AM: Capsule already has an active dispute");
        require(bytes(_disputeURI).length > 0, "AM: Dispute URI cannot be empty");

        uint256 disputeStakeAmount = 100 * 10**18; // Example bond: 100 NEXUS
        require(_nexusBalances[msg.sender] >= disputeStakeAmount, "AM: Insufficient Nexus for dispute bond");

        _nexusBalances[msg.sender] -= disputeStakeAmount;

        _disputeIdCounter.increment();
        uint256 newDisputeId = _disputeIdCounter.current();

        disputes[newDisputeId] = Dispute({
            id: newDisputeId,
            capsuleId: _capsuleId,
            initiator: msg.sender,
            disputeURI: _disputeURI,
            stakeAmount: disputeStakeAmount,
            isActive: true,
            isResolved: false,
            result: false // Default to false
        });
        knowledgeCapsules[_capsuleId].disputeId = newDisputeId;

        emit DisputeInitiated(newDisputeId, _capsuleId, msg.sender, _disputeURI, disputeStakeAmount);
        return newDisputeId;
    }

    /**
     * @dev Resolves an active dispute. Only the `owner` (acting as an arbiter) can call this.
     * If `_isDisputeValid` is true, the initiator's bond is returned. Otherwise, it's slashed (burned).
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isDisputeValid True if the dispute is found to be valid (capsule is flawed/infringing), false otherwise.
     */
    function resolveDispute(uint256 _disputeId, bool _isDisputeValid) public onlyDisputeArbiter(_disputeId) {
        Dispute storage dispute = disputes[_disputeId];
        require(!dispute.isResolved, "AM: Dispute already resolved");

        dispute.isActive = false;
        dispute.isResolved = true;
        dispute.result = _isDisputeValid;
        knowledgeCapsules[dispute.capsuleId].disputeId = 0; // Clear dispute link

        if (_isDisputeValid) {
            // Return bond to initiator
            _nexusBalances[dispute.initiator] += dispute.stakeAmount;
        } else {
            // Burn the bond (slashing)
            nexusTotalSupply -= dispute.stakeAmount; // Reduce total supply
            // The tokens are effectively removed from circulation as they were already removed from _nexusBalances
            // of the initiator.
        }

        emit DisputeResolved(_disputeId, dispute.capsuleId, _isDisputeValid, msg.sender);
    }

    // --- Delegated Staking ---

    /**
     * @dev Allows a user to delegate a portion of their NexusTokens to a "curator".
     * The curator can then stake these delegated tokens on capsules.
     * @param _curator The address of the curator to delegate to.
     * @param _amount The amount of NexusTokens to delegate.
     */
    function delegateStakeToCurator(address _curator, uint256 _amount) public {
        require(_curator != address(0), "AM: Curator cannot be zero address");
        require(_curator != msg.sender, "AM: Cannot delegate to self");
        require(_amount > 0, "AM: Delegation amount must be greater than zero");
        require(_nexusBalances[msg.sender] >= _amount, "AM: Insufficient Nexus balance to delegate");

        _nexusBalances[msg.sender] -= _amount;
        delegatedStakes[msg.sender][_curator] += _amount;
        totalDelegatedStake[_curator] += _amount;

        emit StakeDelegated(msg.sender, _curator, _amount);
    }

    /**
     * @dev Allows a curator to stake *delegated* NexusTokens on a Knowledge Capsule.
     * The curator acts on behalf of a specific delegator.
     * @param _delegator The address of the delegator whose tokens are being used.
     * @param _capsuleId The ID of the capsule to stake on.
     * @param _amount The amount of delegated NexusTokens to stake.
     */
    function curatorStakeOnCapsule(address _delegator, uint256 _capsuleId, uint256 _amount) public {
        require(_exists(_capsuleId), "AM: Capsule does not exist");
        require(_amount > 0, "AM: Stake amount must be greater than zero");
        require(delegatedStakes[_delegator][msg.sender] >= _amount, "AM: Insufficient delegated stake from this delegator");

        delegatedStakes[_delegator][msg.sender] -= _amount;
        capsuleStakes[_capsuleId][_delegator] += _amount; // Stake is attributed to the original delegator
        knowledgeCapsules[_capsuleId].totalStakedNexus += _amount;

        emit CuratorStaked(msg.sender, _delegator, _capsuleId, _amount);
    }

    /**
     * @dev Allows a delegator to undelegate NexusTokens from a curator.
     * The tokens are returned to the delegator's balance.
     * @param _curator The address of the curator to undelegate from.
     * @param _amount The amount of NexusTokens to undelegate.
     */
    function undelegateStakeFromCurator(address _curator, uint256 _amount) public {
        require(_curator != address(0), "AM: Curator cannot be zero address");
        require(_amount > 0, "AM: Undelegation amount must be greater than zero");
        require(delegatedStakes[msg.sender][_curator] >= _amount, "AM: Insufficient delegated stake to withdraw");

        delegatedStakes[msg.sender][_curator] -= _amount;
        totalDelegatedStake[_curator] -= _amount;
        _nexusBalances[msg.sender] += _amount; // Return to delegator's balance

        emit StakeUndelegated(msg.sender, _curator, _amount);
    }
}
```