Okay, here is a Solidity smart contract incorporating generative art parameters, dynamic traits, NFT-based governance, and integrated royalties, aiming for a unique and relatively advanced structure beyond typical examples. It won't replicate standard OpenZeppelin contracts entirely for its unique logic, though it will adhere to ERC standards where necessary for interoperability.

We'll call it `DecentralizedAutonomousArtFactory` (DAAF).

**Concept:**
A smart contract that acts as a factory for generative art NFTs. Art parameters are determined semi-randomly on-chain during minting, based on weighted traits managed by the community (NFT holders). The art itself can have dynamic properties that change based on owner interaction or time. NFT holders also govern key factory parameters and trait additions/changes via a proposal and voting system.

**Key Advanced/Trendy/Creative Concepts:**
1.  **On-Chain Generative Parameters:** Parameters for art generation (traits, colors, etc.) are determined by on-chain logic during minting.
2.  **Weighted Trait System:** Admins/Governors define possible traits and their relative weights/rarity.
3.  **NFT-Based Governance:** Holders of the factory's NFTs have voting power (1 NFT = 1 vote) to propose and vote on changes to factory parameters, trait weights, or even adding new traits.
4.  **Dynamic Art Traits:** NFTs can have state that changes *after* minting based on owner interactions or time. This state influences the art's metadata (via the `tokenURI`).
5.  **Integrated Royalty Splits:** Custom royalty mechanism built-in, configurable via governance.
6.  **Role-Based Access Control:** Custom roles for administrative functions (not using OpenZeppelin's AccessControl to avoid direct duplication, but implementing the pattern).
7.  **Treasury Management:** Minting fees accumulate in the contract and can be withdrawn via governance proposal.
8.  **IPFS Metadata via Base URI + Token ID:** Standard pattern, but necessary for the dynamic art aspect (metadata server needs token state).
9.  **Proposal System with State:** Tracks proposals through creation, voting, and execution/cancellation stages.
10. **Trait Curation Governance:** A specific type of proposal allows adding entirely new trait types or values.

---

**Outline and Function Summary**

**Contract Name:** DecentralizedAutonomousArtFactory (DAAF)

**Core Functionality:**
*   ERC721 Non-Fungible Token Standard compliance.
*   On-chain generation of art parameters based on weighted traits.
*   Dynamic state for each minted art piece.
*   Governance system based on NFT ownership.
*   Role-based access control.
*   Integrated royalty payments.
*   Treasury management.

**Modules:**
1.  **ERC721 Core:** Standard NFT functions (`balanceOf`, `ownerOf`, `approve`, etc.).
2.  **Access Control (Roles):** Define and manage different roles (Admin, Minter, Governor, Trait Curator).
3.  **Minting & Supply:** Control the creation of new art NFTs, set limits, handle mint fees.
4.  **Generative Art Logic:** Define traits, weights, and the on-chain process to determine a token's specific parameters.
5.  **Dynamic Art Elements:** Store and update per-token state that affects its appearance/metadata.
6.  **DAO Governance:** Proposal creation, voting, and execution for factory parameters and trait curation.
7.  **Royalty:** ERC2981 implementation.
8.  **Treasury:** Manage collected fees.

**Function Summary:**

*   **ERC721 & Core (8+):**
    *   `constructor(string name, string symbol, address initialAdmin)`: Initializes contract, sets names, assigns initial admin role.
    *   `balanceOf(address owner) view`: Returns the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId) view`: Returns the owner of a specific token.
    *   `approve(address to, uint256 tokenId)`: Grants approval for one token.
    *   `getApproved(uint256 tokenId) view`: Gets the approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for all tokens.
    *   `isApprovedForAll(address owner, address operator) view`: Checks if an operator is approved for all tokens.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers a token.
    *   `tokenURI(uint256 tokenId) view`: Returns the metadata URI for a token (includes dynamic state).
    *   `supportsInterface(bytes4 interfaceId) view`: ERC165 support for ERC721 and ERC2981.

*   **Access Control (Roles) (3+):**
    *   `grantRole(bytes32 role, address account)`: Grants a role (Admin only).
    *   `revokeRole(bytes32 role, address account)`: Revokes a role (Admin only).
    *   `hasRole(bytes32 role, address account) view`: Checks if an address has a role.
    *   `renounceRole(bytes32 role)`: Renounces a role (Self-service).

*   **Minting & Supply (3+):**
    *   `mintArt(uint256 quantity) payable`: Mints new art tokens. Requires mint fee, triggers parameter generation. (Minter role or potentially public based on config).
    *   `setMaxSupply(uint256 _maxSupply)`: Sets the total supply cap (Admin only).
    *   `getCurrentSupply() view`: Returns the number of tokens minted so far.
    *   `setMintPrice(uint256 _mintPrice)`: Sets the price to mint a token (Admin/Governance).

*   **Generative Art Logic (4+):**
    *   `defineTraitType(uint8 traitTypeId, string name)`: Defines a category of traits (e.g., "Background", "Eyes") (Trait Curator role).
    *   `addTraitValue(uint8 traitTypeId, uint8 traitValueId, string value, uint16 weight)`: Adds a specific trait value within a category and assigns a weight (Trait Curator role).
    *   `setTraitWeight(uint8 traitTypeId, uint8 traitValueId, uint16 newWeight)`: Adjusts the weight of an existing trait value (Trait Curator role or Governance).
    *   `getArtParameters(uint256 tokenId) view`: Retrieves the generated parameters for a specific token.
    *   `getTraitDetails(uint8 traitTypeId, uint8 traitValueId) view`: Get details about a specific trait value.
    *   `getTraitTypeDetails(uint8 traitTypeId) view`: Get details about a specific trait type.

*   **Dynamic Art Elements (2+):**
    *   `interactWithArt(uint256 tokenId, bytes data)`: Allows owner to interact, potentially changing dynamic state (e.g., 'feed' the art). Emits an event.
    *   `getArtState(uint256 tokenId) view`: Retrieves the current dynamic state of a token.

*   **DAO Governance (7+):**
    *   `proposeParameterChange(uint256 proposalId, string description, bytes callData)`: Creates a proposal to call a function on the contract (e.g., `setMintPrice`, `setTraitWeight`, `setMaxSupply`). Requires Governor role.
    *   `proposeTraitCuration(uint256 proposalId, string description, bytes callData)`: Creates a proposal specifically for trait management functions (`addTraitValue`, `setTraitWeight`). Requires Governor role. (Could potentially be combined, but separating adds clarity).
    *   `voteOnProposal(uint256 proposalId, bool support)`: Casts a vote (requires NFT ownership, 1 NFT = 1 vote).
    *   `executeProposal(uint256 proposalId)`: Executes a successful proposal (Anyone can call after voting period ends and threshold/quorum met).
    *   `cancelProposal(uint256 proposalId)`: Cancels a proposal before voting ends (Proposer or Admin/Governor).
    *   `getProposalState(uint256 proposalId) view`: Returns the current state of a proposal.
    *   `getProposalDetails(uint256 proposalId) view`: Returns details about a proposal (description, call data, votes, etc.).
    *   `setVotingPeriod(uint64 _votingPeriod)`: Sets the duration proposals are open for voting (Governance).
    *   `setVotingThresholds(uint256 minVotes, uint256 quorum)`: Sets parameters for proposal success (Governance).

*   **Royalty (2):**
    *   `setDefaultRoyalty(address receiver, uint96 feeNumerator)`: Sets the default royalty for the collection (Admin/Governance).
    *   `royaltyInfo(uint256 tokenId, uint256 salePrice) view`: ERC2981 standard function to get royalty details for a sale.

*   **Treasury (1):**
    *   `withdrawTreasury(address recipient, uint256 amount)`: Withdraws funds from the contract treasury (Only via successful Governance proposal execution).

*   **Utility/Internal (Many):**
    *   `_generateArtParameters(uint256 seed) internal`: Internal logic to generate parameters based on weights and randomness.
    *   `_resolveTrait(uint8 traitTypeId, uint256 randomNumber) internal view`: Internal logic to select a trait value based on weights and a random number.
    *   `_stateIdCounter`, `_traitTypeCounter`, `_proposalIdCounter`: Internal counters.
    *   Standard ERC721 internal helpers (`_safeMint`, `_beforeTokenTransfer`, etc., if not inheriting fully).

Total external/public functions: ~35+. This meets the requirement of at least 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/interfaces/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/token/ERC721/extensions/IERC2981.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

// --- OUTLINE & FUNCTION SUMMARY ---
// Contract Name: DecentralizedAutonomousArtFactory (DAAF)
// Concept: A smart contract that acts as a factory for generative art NFTs. Art parameters are determined
//          semi-randomly on-chain during minting, based on weighted traits managed by the community (NFT holders).
//          The art itself can have dynamic properties that change based on owner interaction or time.
//          NFT holders also govern key factory parameters and trait additions/changes via a proposal and voting system.
//
// Key Advanced/Trendy/Creative Concepts:
// - On-Chain Generative Parameters: Parameters for art generation determined by on-chain logic.
// - Weighted Trait System: Admins/Governors define traits and their relative weights.
// - NFT-Based Governance: Holders of the factory's NFTs have voting power (1 NFT = 1 vote).
// - Dynamic Art Traits: NFTs can have state that changes post-minting, affecting metadata.
// - Integrated Royalty Splits: Custom royalty mechanism configurable via governance.
// - Role-Based Access Control: Custom roles for administrative functions.
// - Treasury Management: Minting fees accrue and are withdrawable via governance.
// - IPFS Metadata via Base URI + Token ID: Metadata points to dynamic service.
// - Proposal System with State: Tracks governance proposals.
// - Trait Curation Governance: Specific proposal type for managing traits.
//
// Modules & Function Summary:
// 1. ERC721 Core:
//    - constructor(string name, string symbol, address initialAdmin): Initializes contract, roles.
//    - balanceOf(address owner) view: Get owner's token count.
//    - ownerOf(uint256 tokenId) view: Get token owner.
//    - approve(address to, uint256 tokenId): Approve single token transfer.
//    - getApproved(uint256 tokenId) view: Get approved address for token.
//    - setApprovalForAll(address operator, bool approved): Approve/revoke operator for all tokens.
//    - isApprovedForAll(address owner, address operator) view: Check operator approval.
//    - transferFrom(address from, address to, uint256 tokenId): Transfer token.
//    - safeTransferFrom(address from, address to, uint256 tokenId): Safe token transfer.
//    - tokenURI(uint256 tokenId) view: Get metadata URI, includes dynamic state.
//    - supportsInterface(bytes4 interfaceId) view: ERC165 support.
// 2. Access Control (Roles):
//    - DEFAULT_ADMIN_ROLE, MINTER_ROLE, GOVERNOR_ROLE, TRAIT_CURATOR_ROLE: Role identifiers.
//    - grantRole(bytes32 role, address account): Grant role (Admin only).
//    - revokeRole(bytes32 role, address account): Revoke role (Admin only).
//    - hasRole(bytes32 role, address account) view: Check if address has role.
//    - renounceRole(bytes32 role): Self-renounce role.
// 3. Minting & Supply:
//    - mintArt(uint256 quantity) payable: Mints new tokens, pays fee, generates parameters.
//    - setMaxSupply(uint256 _maxSupply): Set total supply cap (Admin only).
//    - getCurrentSupply() view: Get current minted count.
//    - setMintPrice(uint256 _mintPrice): Set mint price (Admin/Governance).
// 4. Generative Art Logic:
//    - ArtParameters struct: Stores parameters for a token.
//    - Trait struct: Defines a trait value (value string, weight).
//    - TraitType struct: Defines a trait category (name, totalWeight, values).
//    - defineTraitType(uint8 traitTypeId, string name): Define a trait category (Trait Curator).
//    - addTraitValue(uint8 traitTypeId, uint8 traitValueId, string value, uint16 weight): Add trait value (Trait Curator).
//    - setTraitWeight(uint8 traitTypeId, uint8 traitValueId, uint16 newWeight): Adjust weight (Trait Curator/Governance).
//    - getArtParameters(uint256 tokenId) view: Get generated parameters for a token.
//    - getTraitDetails(uint8 traitTypeId, uint8 traitValueId) view: Get details for a trait value.
//    - getTraitTypeDetails(uint8 traitTypeId) view: Get details for a trait category.
// 5. Dynamic Art Elements:
//    - ArtState struct: Stores dynamic state for a token (interaction count, last interaction time).
//    - interactWithArt(uint256 tokenId, bytes data): Owner interaction, updates state, emits event.
//    - getArtState(uint256 tokenId) view: Get dynamic state for a token.
// 6. DAO Governance:
//    - ProposalState enum: CREATED, VOTING, SUCCEEDED, EXECUTED, CANCELED, DEFEATED.
//    - Proposal struct: Stores proposal details (proposer, target, calldata, votes, etc.).
//    - proposeParameterChange(uint256 proposalId, string description, bytes callData): Create proposal for contract parameters (Governor).
//    - proposeTraitCuration(uint256 proposalId, string description, bytes callData): Create proposal for trait changes (Governor).
//    - voteOnProposal(uint256 proposalId, bool support): Cast vote based on NFT ownership.
//    - executeProposal(uint256 proposalId): Execute successful proposal.
//    - cancelProposal(uint256 proposalId): Cancel proposal (Proposer/Admin/Governor).
//    - getProposalState(uint256 proposalId) view: Get state of proposal.
//    - getProposalDetails(uint256 proposalId) view: Get details of proposal.
//    - setVotingPeriod(uint64 _votingPeriod): Set voting duration (Governance).
//    - setVotingThresholds(uint256 minVotes, uint256 quorum): Set proposal success thresholds (Governance).
// 7. Royalty:
//    - setDefaultRoyalty(address receiver, uint96 feeNumerator): Set default royalty (Admin/Governance).
//    - royaltyInfo(uint256 tokenId, uint256 salePrice) view: ERC2981 standard function.
// 8. Treasury:
//    - withdrawTreasury(address recipient, uint256 amount): Withdraw funds (Only via governance execution).
//
// Total Public/External Functions: ~35+

contract DecentralizedAutonomousArtFactory is IERC721, IERC2981, ERC165 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ERC721 Standard
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    Counters.Counter private _tokenIdCounter;

    // Supply & Minting
    uint256 private _maxSupply = 0; // 0 means no cap initially
    uint256 private _mintPrice = 0;
    string private _baseTokenURI = ""; // Base URI for metadata server

    // Generative Art Data
    struct ArtParameters {
        mapping(uint8 => uint8) traits; // TraitType ID => TraitValue ID
        uint256 mintTimestamp;
        uint256 randomnessSeed; // Seed used for generation
    }
    mapping(uint256 => ArtParameters) private _tokenParameters;

    struct Trait {
        uint8 id;
        string value;
        uint16 weight; // Relative weight/rarity
    }

    struct TraitType {
        string name;
        uint256 totalWeight; // Sum of weights of all values in this type
        mapping(uint8 => Trait) values; // TraitValue ID => Trait
        uint8[] valueIds; // Keep track of value IDs for iteration
    }
    mapping(uint8 => TraitType) private _traitTypes; // TraitType ID => TraitType
    uint8[] private _traitTypeIds; // Keep track of trait type IDs for iteration
    uint8 private _traitTypeCounter = 0;
    uint8 private _traitValueCounter = 0; // Counter for value IDs within a type

    // Dynamic Art State
    struct ArtState {
        uint256 interactionCount;
        uint40 lastInteractionTimestamp; // Using uint40 to save space, ~34 trillion years max
        // Add other dynamic properties here
        bytes dynamicData; // Placeholder for custom dynamic data
    }
    mapping(uint256 => ArtState) private _tokenState;
    uint256 private _stateIdCounter = 0; // Counter for tracking dynamic state changes per token

    // Role-Based Access Control
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00; // Admin can grant/revoke roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); // Can call mintArt
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // Can propose/execute governance actions
    bytes32 public constant TRAIT_CURATOR_ROLE = keccak256("TRAIT_CURATOR_ROLE"); // Can define/add traits
    mapping(bytes32 => mapping(address => bool)) private _roles;

    // Royalty
    address public defaultRoyaltyReceiver;
    uint96 public defaultRoyaltyFeeNumerator; // e.g., 250 for 2.5% (250/10000)

    // Governance
    enum ProposalState {
        CREATED,
        VOTING,
        SUCCEEDED,
        EXECUTED,
        CANCELED,
        DEFEATED
    }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        address target; // Address of the contract/target for the call
        bytes callData; // The function call data to execute
        uint64 votingPeriodEndTimestamp;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks voters
        ProposalState state;
        uint256 totalVotingPowerAtStart; // Snapshot of total supply when proposal starts
    }
    mapping(uint256 => Proposal) private _proposals;
    Counters.Counter private _proposalIdCounter;

    uint64 public votingPeriodDuration = 7 days; // Default voting period
    uint256 public minVotesForProposal = 1; // Minimum votes to consider a proposal
    uint256 public quorumRequired = 0; // Percentage of total voting power (supply) needed to reach quorum (e.g., 500 for 5%)

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ArtMinted(address indexed owner, uint256 indexed tokenId, uint256 quantity);
    event ArtParametersGenerated(uint256 indexed tokenId, uint256 randomnessSeed);
    event ArtStateUpdated(uint256 indexed tokenId, uint256 indexed newStateId, bytes data);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event TraitTypeDefined(uint8 indexed traitTypeId, string name);
    event TraitValueAdded(uint8 indexed traitTypeId, uint8 indexed traitValueId, string value, uint16 weight);
    event TraitWeightUpdated(uint8 indexed traitTypeId, uint8 indexed traitValueId, uint16 newWeight);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address target, bytes callData, uint64 votingEnds);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event MaxSupplyUpdated(uint256 newMaxSupply);
    event MintPriceUpdated(uint256 newMintPrice);
    event VotingPeriodUpdated(uint64 newDuration);
    event VotingThresholdsUpdated(uint256 newMinVotes, uint256 newQuorum);
    event RoyaltyInfoUpdated(address indexed receiver, uint96 feeNumerator);

    // Custom Errors
    error CallerNotAuthorized(bytes32 role);
    error ApprovalCallerIsNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error TransferCallerIsNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToZeroAddress();
    error TransferToERC721ReceiverRejected();
    error MintingSupplyLimitReached();
    error InsufficientPayment(uint256 required, uint256 sent);
    error TraitTypeAlreadyExists(uint8 traitTypeId);
    error TraitTypeNotFound(uint8 traitTypeId);
    error TraitValueAlreadyExists(uint8 traitTypeId, uint8 traitValueId);
    error TraitValueNotFound(uint8 traitTypeId, uint8 traitValueId);
    error NoTraitsDefinedForType(uint8 traitTypeId);
    error ZeroTotalTraitWeight(uint8 traitTypeId);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotInState(ProposalState requiredState, ProposalState currentState);
    error AlreadyVoted(uint256 proposalId);
    error VotingPeriodNotEnded(uint64 endTime);
    error ProposalFailedThresholds(uint256 votesFor, uint256 totalVotingPower, uint256 minVotes, uint256 quorum);
    error ExecutionFailed();
    error TreasuryWithdrawalFailed();
    error OnlyCallableViaGovernance();
    error InvalidCallData(); // Used for governance calls
    error CannotRenounceAdminRole();

    // --- Modifiers ---

    modifier onlyRole(bytes32 role) {
        if (!_roles[role][msg.sender]) {
            revert CallerNotAuthorized(role);
        }
        _;
    }

    modifier onlyGovernance() {
        if (msg.sender != address(this)) { // Ensures the call came from an executed proposal
             revert OnlyCallableViaGovernance();
        }
        _;
    }

    // --- Constructor ---

    constructor(string memory name, string memory symbol, address initialAdmin) ERC165() {
        _name = name;
        _symbol = symbol;
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin); // Assigns admin role
        _grantRole(MINTER_ROLE, initialAdmin); // Admin can also mint initially
        _grantRole(GOVERNOR_ROLE, initialAdmin); // Admin can also govern initially
        _grantRole(TRAIT_CURATOR_ROLE, initialAdmin); // Admin can also curate traits initially
    }

    // --- Access Control (Roles) ---

    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function grantRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function revokeRole(bytes32 role, address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function renounceRole(bytes32 role) external {
        if (role == DEFAULT_ADMIN_ROLE && _roles[DEFAULT_ADMIN_ROLE][msg.sender] && balanceOf(msg.sender) > 0) {
             revert CannotRenounceAdminRole(); // Prevent renouncing admin role if you hold NFTs (to avoid abandoning governance)
        }
        _revokeRole(role, msg.sender);
    }

    // --- ERC165 Support ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        // ERC721, ERC721Metadata, ERC2981
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    // --- ERC721 Core Functions ---

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
            revert ApprovalQueryForNonexistentToken();
        }
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ApprovalCallerIsNotOwnerNorApproved();
        }
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) {
             revert ApprovalQueryForNonexistentToken();
        }
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferCallerIsNotOwnerNorApproved();
        }
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert TransferCallerIsNotOwnerNorApproved();
        }
        _safeTransfer(from, to, tokenId, data);
    }

    // --- ERC721 Internal Helper Functions ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if not exists
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

     function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) { // ownerOf checks existence
            revert TransferFromIncorrectOwner();
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        _approve(address(0), tokenId); // Clear approvals from the previous owner

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (to.code.length > 0) { // Check if 'to' is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert TransferToERC721ReceiverRejected();
                }
            } catch Error(string memory reason) {
                 // Handle potential errors from the receiver contract
                 revert(string(abi.encodePacked("TransferToERC721ReceiverRejected: ", reason)));
            } catch {
                 // Handle other unexpected errors
                 revert TransferToERC721ReceiverRejected();
            }
        }
    }

    function _safeMint(address to, uint256 tokenId) internal {
        if (_exists(tokenId)) {
            revert("ERC721: token already minted"); // Should not happen with Counter
        }
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }

        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;

        // Initialize dynamic state and parameters
        _tokenState[tokenId] = ArtState({
            interactionCount: 0,
            lastInteractionTimestamp: uint40(block.timestamp),
            dynamicData: ""
        });
        _tokenParameters[tokenId].mintTimestamp = block.timestamp;

        // Trigger parameter generation (using block data as a simple seed)
        // NOTE: Block data is not truly random and is susceptible to miner manipulation.
        // For production, integrate with Chainlink VRF or a similar decentralized oracle.
        uint256 randomnessSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, tx.origin)));
        _tokenParameters[tokenId].randomnessSeed = randomnessSeed;
        _generateArtParameters(tokenId, randomnessSeed); // Generate and store parameters

        emit Transfer(address(0), to, tokenId);
        emit ArtMinted(to, tokenId, 1); // Emit for single token, quantity logic handled in mintArt caller
    }


    // --- Metadata ---

    // For dynamic metadata, this tokenURI should point to a server/service
    // that can fetch the token's state from the contract (using getArtParameters and getArtState)
    // and generate the appropriate JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ApprovalQueryForNonexistentToken(); // Using ERC721 standard error
        }

        // The base URI should end with a /, and the server should handle the token ID and state
        // Example: ipfs://QmVault.../metadata/{tokenId}
        // The server at this URI would then call back to the contract to get token parameters and state.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), ".json")); // Or just append tokenId
    }

    function setBaseTokenURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = uri;
    }


    // --- Minting & Supply ---

    function mintArt(uint256 quantity) external payable onlyRole(MINTER_ROLE) {
        uint256 currentSupply = _tokenIdCounter.current();
        if (_maxSupply > 0 && currentSupply + quantity > _maxSupply) {
            revert MintingSupplyLimitReached();
        }

        uint256 totalPrice = _mintPrice.mul(quantity);
        if (msg.value < totalPrice) {
            revert InsufficientPayment(totalPrice, msg.value);
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = _tokenIdCounter.next();
            _safeMint(msg.sender, newTokenId);
            // Note: ArtMinted event is emitted inside _safeMint for each token
        }

        // Refund excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function setMaxSupply(uint256 _maxSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxSupply = _maxSupply;
        emit MaxSupplyUpdated(_maxSupply);
    }

    function getCurrentSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setMintPrice(uint256 _mintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintPrice = _mintPrice;
        emit MintPriceUpdated(_mintPrice);
    }

    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    // --- Generative Art Logic ---

    function defineTraitType(uint8 traitTypeId, string memory name) external onlyRole(TRAIT_CURATOR_ROLE) {
        if (_traitTypes[traitTypeId].totalWeight > 0 || _traitTypes[traitTypeId].valueIds.length > 0) {
             revert TraitTypeAlreadyExists(traitTypeId);
        }
        _traitTypes[traitTypeId].name = name;
        _traitTypeIds.push(traitTypeId); // Add to list of type IDs
        emit TraitTypeDefined(traitTypeId, name);
    }

    function addTraitValue(uint8 traitTypeId, uint8 traitValueId, string memory value, uint16 weight) external onlyRole(TRAIT_CURATOR_ROLE) {
        if (_traitTypes[traitTypeId].valueIds.length == 0 && _traitTypes[traitTypeId].totalWeight == 0) {
             revert TraitTypeNotFound(traitTypeId);
        }
         if (_traitTypes[traitTypeId].values[traitValueId].weight > 0) {
             revert TraitValueAlreadyExists(traitTypeId, traitValueId);
         }

        _traitTypes[traitTypeId].values[traitValueId] = Trait({
            id: traitValueId,
            value: value,
            weight: weight
        });
        _traitTypes[traitTypeId].totalWeight = _traitTypes[traitTypeId].totalWeight.add(weight);
        _traitTypes[traitTypeId].valueIds.push(traitValueId); // Add to list of value IDs for this type

        emit TraitValueAdded(traitTypeId, traitValueId, value, weight);
    }

    function setTraitWeight(uint8 traitTypeId, uint8 traitValueId, uint16 newWeight) external onlyRole(TRAIT_CURATOR_ROLE) {
         if (_traitTypes[traitTypeId].valueIds.length == 0 && _traitTypes[traitTypeId].totalWeight == 0) {
             revert TraitTypeNotFound(traitTypeId);
        }
         if (_traitTypes[traitTypeId].values[traitValueId].weight == 0) {
             revert TraitValueNotFound(traitTypeId, traitValueId);
         }

        uint256 oldWeight = _traitTypes[traitTypeId].values[traitValueId].weight;
        _traitTypes[traitTypeId].totalWeight = _traitTypes[traitTypeId].totalWeight.sub(oldWeight).add(newWeight);
        _traitTypes[traitTypeId].values[traitValueId].weight = newWeight;

        emit TraitWeightUpdated(traitTypeId, traitValueId, newWeight);
    }

    // Internal function to generate and store parameters for a token
    function _generateArtParameters(uint256 tokenId, uint256 randomnessSeed) internal {
        // Iterate through each defined trait type and select a value based on weight
        uint256 currentRandomness = randomnessSeed;
        for (uint i = 0; i < _traitTypeIds.length; i++) {
            uint8 traitTypeId = _traitTypeIds[i];
            uint8 selectedValueId = _resolveTrait(traitTypeId, currentRandomness);
            _tokenParameters[tokenId].traits[traitTypeId] = selectedValueId;

            // Update randomness for the next trait
            currentRandomness = uint256(keccak256(abi.encodePacked(currentRandomness, tokenId, traitTypeId)));
        }

        emit ArtParametersGenerated(tokenId, randomnessSeed);
    }

    // Internal function to select a trait value based on weights and randomness
    function _resolveTrait(uint8 traitTypeId, uint256 randomNumber) internal view returns (uint8) {
        TraitType storage traitType = _traitTypes[traitTypeId];
        if (traitType.valueIds.length == 0) {
            revert NoTraitsDefinedForType(traitTypeId);
        }
         if (traitType.totalWeight == 0) {
            revert ZeroTotalTraitWeight(traitTypeId);
         }

        uint256 roll = randomNumber % traitType.totalWeight;
        uint256 cumulativeWeight = 0;

        // Iterate through value IDs and find the selected trait
        for (uint i = 0; i < traitType.valueIds.length; i++) {
            uint8 valueId = traitType.valueIds[i];
            cumulativeWeight = cumulativeWeight.add(traitType.values[valueId].weight);
            if (roll < cumulativeWeight) {
                return valueId;
            }
        }

        // Fallback (should not happen if totalWeight is > 0)
        return traitType.valueIds[0];
    }

    // View function to get the generated parameters for a token
    function getArtParameters(uint256 tokenId) public view returns (mapping(uint8 => uint8) storage traits, uint256 mintTimestamp, uint256 randomnessSeed) {
        if (!_exists(tokenId)) {
            revert ApprovalQueryForNonexistentToken();
        }
        ArtParameters storage params = _tokenParameters[tokenId];
        return (params.traits, params.mintTimestamp, params.randomnessSeed);
    }

    // View function to get details about a specific trait value
    function getTraitDetails(uint8 traitTypeId, uint8 traitValueId) public view returns (string memory value, uint16 weight) {
         if (_traitTypes[traitTypeId].values[traitValueId].weight == 0) {
             revert TraitValueNotFound(traitTypeId, traitValueId);
         }
         Trait storage trait = _traitTypes[traitTypeId].values[traitValueId];
         return (trait.value, trait.weight);
    }

    // View function to get details about a specific trait type
    function getTraitTypeDetails(uint8 traitTypeId) public view returns (string memory name, uint256 totalWeight, uint8[] memory valueIds) {
        if (_traitTypes[traitTypeId].valueIds.length == 0 && _traitTypes[traitTypeId].totalWeight == 0) {
             revert TraitTypeNotFound(traitTypeId);
        }
         TraitType storage traitType = _traitTypes[traitTypeId];
         return (traitType.name, traitType.totalWeight, traitType.valueIds);
    }

    // View function to list all defined trait type IDs
    function getAllTraitTypeIds() public view returns (uint8[] memory) {
        return _traitTypeIds;
    }


    // --- Dynamic Art Elements ---

    function interactWithArt(uint256 tokenId, bytes calldata data) external {
        address tokenOwner = ownerOf(tokenId); // Checks existence
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender)) {
            revert TransferCallerIsNotOwnerNorApproved(); // Re-using error for owner/approved check
        }

        ArtState storage state = _tokenState[tokenId];
        state.interactionCount = state.interactionCount.add(1);
        state.lastInteractionTimestamp = uint40(block.timestamp);
        state.dynamicData = data; // Store interaction data
        _stateIdCounter = _stateIdCounter.add(1); // Increment state ID globally or per token? Let's do globally for simplicity.

        emit ArtStateUpdated(tokenId, _stateIdCounter, data);
    }

    function getArtState(uint256 tokenId) public view returns (uint256 interactionCount, uint40 lastInteractionTimestamp, bytes memory dynamicData) {
        if (!_exists(tokenId)) {
            revert ApprovalQueryForNonexistentToken();
        }
        ArtState storage state = _tokenState[tokenId];
        return (state.interactionCount, state.lastInteractionTimestamp, state.dynamicData);
    }

    // Note: Art age is derived from mintTimestamp in ArtParameters struct, which is fetched by getArtParameters.


    // --- DAO Governance ---

    function proposeParameterChange(uint256 proposalId, string memory description, address target, bytes memory callData) external onlyRole(GOVERNOR_ROLE) {
        if (_proposals[proposalId].state != ProposalState.CREATED) {
            revert("Proposal ID already used or proposal exists.");
        }
        if (target == address(0)) {
            revert InvalidCallData(); // Target must be specified
        }
        // Basic validation: Check if the callData is trying to call a function that is only callable via governance
        // Or add a list of allowed function selectors if being very strict.
        // For simplicity here, we assume Governors propose valid calls to this contract.

        _proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            proposer: msg.sender,
            target: target,
            callData: callData,
            votingPeriodEndTimestamp: uint64(block.timestamp) + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: mapping(address => bool), // Initialize mapping
            state: ProposalState.VOTING, // Starts in voting state
            totalVotingPowerAtStart: getCurrentSupply() // Snapshot supply
        });

        _proposalIdCounter.increment(); // Increment counter (alternative to using external proposalId)
        emit ProposalCreated(proposalId, msg.sender, description, target, callData, _proposals[proposalId].votingPeriodEndTimestamp);
        emit ProposalStateChanged(proposalId, ProposalState.VOTING);
    }

    // Can potentially use the same propose function with specific callData logic,
    // but separating highlights the different types of governance actions.
     function proposeTraitCuration(uint256 proposalId, string memory description, bytes memory callData) external onlyRole(GOVERNOR_ROLE) {
        if (_proposals[proposalId].state != ProposalState.CREATED) {
            revert("Proposal ID already used or proposal exists.");
        }
         if (address(this) != msg.sender && target != address(this)) {
             revert("Trait curation proposals must target this contract.");
         }
        // Add checks here if specific trait curation functions are allowed via governance
        // e.g., check function selector within callData

         _proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            proposer: msg.sender,
            target: address(this), // Trait curation calls modify this contract
            callData: callData,
            votingPeriodEndTimestamp: uint64(block.timestamp) + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: mapping(address => bool),
            state: ProposalState.VOTING,
            totalVotingPowerAtStart: getCurrentSupply()
        });

        _proposalIdCounter.increment();
        emit ProposalCreated(proposalId, msg.sender, description, address(this), callData, _proposals[proposalId].votingPeriodEndTimestamp);
        emit ProposalStateChanged(proposalId, ProposalState.VOTING);
     }


    function voteOnProposal(uint256 proposalId, bool support) external {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.VOTING) {
            revert ProposalNotInState(ProposalState.VOTING, proposal.state);
        }
         if (block.timestamp > proposal.votingPeriodEndTimestamp) {
             revert VotingPeriodNotEnded(proposal.votingPeriodEndTimestamp);
         }
        if (proposal.hasVoted[msg.sender]) {
            revert AlreadyVoted(proposalId);
        }

        // Voting power is based on NFT balance at the time of voting
        // A more advanced system might use a snapshot block at proposal creation.
        uint256 votingPower = balanceOf(msg.sender);
        if (votingPower == 0) {
             revert("Voter has no voting power (owns no NFTs).");
        }

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.VOTING) {
            revert ProposalNotInState(ProposalState.VOTING, proposal.state);
        }
        if (block.timestamp <= proposal.votingPeriodEndTimestamp) {
             revert("Voting period has not ended.");
        }

        // Check thresholds/quorum *against snapshot supply* or current supply?
        // Snapshot is safer against gaming the system by transferring NFTs.
        // Let's use snapshot supply taken at proposal creation time.
        uint256 totalVotingPower = proposal.totalVotingPowerAtStart;
        uint256 votesCasted = proposal.votesFor.add(proposal.votesAgainst);

        // Check minimum votes cast
        if (votesCasted < minVotesForProposal) {
            proposal.state = ProposalState.DEFEATED;
             emit ProposalStateChanged(proposalId, ProposalState.DEFEATED);
            revert ProposalFailedThresholds(proposal.votesFor, totalVotingPower, minVotesForProposal, quorumRequired);
        }

        // Check quorum (percentage of total supply cast as votes)
        // Calculate quorum percentage: (votesCasted * 10000) / totalVotingPower >= quorumRequired * 100
        // Avoid division by zero if totalVotingPower is 0
        if (totalVotingPower > 0 && votesCasted.mul(10000) / totalVotingPower < quorumRequired.mul(100)) {
             proposal.state = ProposalState.DEFEATED;
             emit ProposalStateChanged(proposalId, ProposalState.DEFEATED);
            revert ProposalFailedThresholds(proposal.votesFor, totalVotingPower, minVotesForProposal, quorumRequired);
        }

        // Check if votesFor exceeds votesAgainst
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.SUCCEEDED;
            emit ProposalStateChanged(proposalId, ProposalState.SUCCEEDED);

            // Execute the proposal call
            (bool success, ) = proposal.target.call(proposal.callData);
            if (!success) {
                // This is a critical point: execution failure.
                // Depending on desired behavior, could log, pause, or revert.
                // Reverting prevents state change and keeps proposal in SUCCEEDED state for inspection.
                 // A more robust system might allow retries or delegate execution.
                proposal.state = ProposalState.DEFEATED; // Mark as defeated if execution fails
                emit ProposalStateChanged(proposalId, ProposalState.DEFEATED);
                revert ExecutionFailed();
            }

            proposal.state = ProposalState.EXECUTED;
            emit ProposalStateChanged(proposalId, ProposalState.EXECUTED);

        } else {
            proposal.state = ProposalState.DEFEATED;
            emit ProposalStateChanged(proposalId, ProposalState.DEFEATED);
        }
    }

    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.CREATED && proposal.state != ProposalState.VOTING) {
            revert ProposalNotInState(ProposalState.CREATED, proposal.state);
        }
         if (block.timestamp > proposal.votingPeriodEndTimestamp) {
             revert VotingPeriodNotEnded(proposal.votingPeriodEndTimestamp);
         }
        // Only proposer or Admin/Governor role can cancel
        if (msg.sender != proposal.proposer && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(GOVERNOR_ROLE, msg.sender)) {
            revert CallerNotAuthorized(GOVERNOR_ROLE); // Using Governor role error as a proxy
        }

        proposal.state = ProposalState.CANCELED;
        emit ProposalStateChanged(proposalId, ProposalState.CANCELED);
    }

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        return _proposals[proposalId].state;
    }

     function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        string memory description,
        address proposer,
        address target,
        bytes memory callData,
        uint64 votingPeriodEndTimestamp,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state,
        uint256 totalVotingPowerAtStart
     ) {
        Proposal storage proposal = _proposals[proposalId];
         if (proposal.state == ProposalState.CREATED) {
             revert ProposalNotFound(proposalId); // Treat as not found if not created
         }
         return (
             proposal.id,
             proposal.description,
             proposal.proposer,
             proposal.target,
             proposal.callData,
             proposal.votingPeriodEndTimestamp,
             proposal.votesFor,
             proposal.votesAgainst,
             proposal.state,
             proposal.totalVotingPowerAtStart
         );
    }

    // Governance functions callable ONLY via proposal execution
    function setVotingPeriod(uint64 _votingPeriod) external onlyGovernance {
        votingPeriodDuration = _votingPeriod;
        emit VotingPeriodUpdated(_votingPeriod);
    }

     function setVotingThresholds(uint256 minVotes, uint256 quorum) external onlyGovernance {
         // Quorum is percentage * 100, e.g., 500 for 5%, 5000 for 50%
         if (quorum > 10000) revert("Quorum percentage cannot exceed 100%");
         minVotesForProposal = minVotes;
         quorumRequired = quorum;
         emit VotingThresholdsUpdated(minVotes, quorum);
     }


    // --- Royalty (ERC2981) ---

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Could also be made governance controlled
        defaultRoyaltyReceiver = receiver;
        defaultRoyaltyFeeNumerator = feeNumerator;
        emit RoyaltyInfoUpdated(receiver, feeNumerator);
    }

    function royaltyInfo(uint256, uint256 salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        // Applies the default royalty to all tokens
        receiver = defaultRoyaltyReceiver;
        // royaltyAmount = (salePrice * feeNumerator) / 10000 (ERC2981 standard)
        royaltyAmount = salePrice.mul(defaultRoyaltyFeeNumerator) / 10000;
        return (receiver, royaltyAmount);
    }


    // --- Treasury ---

    // Funds sent to this contract (e.g., mint fees) accumulate here.
    receive() external payable {} // Allows receiving ether

    // This function should ONLY be callable via a successful governance proposal execution
    function withdrawTreasury(address payable recipient, uint256 amount) external payable onlyGovernance {
        if (amount == 0) return; // No-op if 0 amount
        if (address(this).balance < amount) {
             revert TreasuryWithdrawalFailed(); // Not enough balance
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert TreasuryWithdrawalFailed(); // Transfer failed
        }
        emit TreasuryWithdrawal(recipient, amount);
    }
}

// Minimal SafeMath library (or import from OpenZeppelin)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// Minimal Strings library for uint256 conversion (or import from OpenZeppelin)
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```

**Explanation and Notes:**

1.  **ERC721 Implementation:** This code provides a basic, manual implementation of the core ERC721 functions and state (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`) rather than inheriting the full OpenZeppelin `ERC721` contract directly. This fits the "don't duplicate *any* of open source" while still adhering to the *standard*. The `_safeMint`, `_transfer`, etc., helpers are derived from the standard pattern.
2.  **Role-Based Access Control:** Instead of OpenZeppelin's `AccessControl`, a simple `_roles` mapping and `onlyRole` modifier are used. This is a common pattern but implemented manually here.
3.  **Generative Parameters:** The `_generateArtParameters` function uses block data (`block.timestamp`, `block.difficulty`, etc.) as a simple, deterministic-but-hard-to-predict-perfectly seed. **IMPORTANT:** This method is *not* suitable for high-value randomness in production as miners can influence it. A robust system *must* use a decentralized oracle like Chainlink VRF. The code includes a placeholder note about this. `_resolveTrait` implements the weighted selection logic.
4.  **Dynamic Art State:** The `ArtState` struct and `interactWithArt` function demonstrate storing and updating state per token. This state (`interactionCount`, `lastInteractionTimestamp`, `dynamicData`) is accessible via `getArtState` and intended to be fetched by the off-chain metadata server pointed to by `tokenURI` to generate dynamic JSON metadata.
5.  **NFT-Based Governance:** The `Proposal` struct and related functions (`proposeParameterChange`, `voteOnProposal`, `executeProposal`, `cancelProposal`) form a simple DAO. Voting power is based on the caller's `balanceOf(address(this))` (i.e., how many Factory NFTs they own). Proposals target the contract itself (`address(this)`) and use `callData` to specify which function to call (e.g., `setMintPrice(1 ether)` encoded). Execution requires the voting period to end and proposal success based on thresholds and quorum against a snapshot of the total supply. Functions intended only for governance execution (like `setVotingPeriod`, `withdrawTreasury`) use the `onlyGovernance` modifier, which checks if the caller is the contract address itself.
6.  **Trait Curation Governance:** `defineTraitType`, `addTraitValue`, `setTraitWeight` are functions initially available to the `TRAIT_CURATOR_ROLE`. However, governance proposals (`proposeTraitCuration`) allow the community (Governors) to propose changes to these traits via the DAO mechanism, enabling decentralized curation over time.
7.  **Royalty:** ERC2981 is implemented via `royaltyInfo`. A default receiver and fee numerator are stored and can be set by Admin or potentially via governance.
8.  **Treasury:** The `receive()` function allows the contract to accept Ether (from minting fees). `withdrawTreasury` allows these funds to be sent out, but *only* if called from the contract itself via a successful governance proposal.
9.  **Function Count:** The contract includes numerous external/public functions across ERC721 core, roles, minting, generative logic, dynamic state, governance, and royalty, totaling well over the requested 20.
10. **OpenZeppelin Usage:** Minimal OpenZeppelin imports are used (`IERC721`, `IERC721Receiver`, `IERC165`, `IERC2981`, `ERC165` for interface adherence and introspection, `Counters`, `SafeMath` - though basic `SafeMath` is included manually). The core logic (generative art, dynamic state, governance structure, custom roles) is implemented within the contract to be distinct from standard library implementations.

This contract provides a foundation for a complex, community-driven generative art project with evolving traits and dynamic NFTs. Remember that deploying such a contract requires careful testing, gas optimization, and consideration of off-chain components (like the metadata server).