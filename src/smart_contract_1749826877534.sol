Okay, let's design a smart contract that goes beyond standard tokens or simple NFTs. We'll create a system based on dynamic, evolving digital artifacts and a shared, mutable on-chain state that participants can influence.

**Concept:** "Ethereum Chronicles"

A system where users own unique digital fragments (`ChronicleFragments`) representing pieces of a constantly evolving on-chain narrative or state (`The Chronicle`). These fragments have dynamic properties that change based on interactions and the global state. Users can manipulate their fragments, combine them, and use them to influence the Chronicle itself.

**Advanced Concepts Used:**

1.  **Dynamic On-Chain NFT State:** Fragment properties (Purity, Age, Affinity, Journal/History) are stored and mutated directly on-chain, not just via metadata links.
2.  **Algorithmic State Manipulation:** Chronicle state changes based on a combination of user actions (`attuneFragment`) and potentially internal logic.
3.  **Complex NFT Interactions:** Operations like `mergeFragments` involve consuming multiple NFTs to create a new one with derived properties. `setPact` creates temporary on-chain relationships between NFTs.
4.  **On-Chain Journaling/History:** Fragments maintain a limited history of significant actions directly within their state.
5.  **Shared, Mutable Global State:** The `ChronicleState` is a central set of variables that all participants can read and collectively influence.
6.  **Reputation/Influence System (Basic):** Tracking `totalAttunementInfluence` per user based on their interactions.
7.  **Algorithmic Property Derivation:** New fragment properties (e.g., after merging) are calculated based on specific on-chain rules.
8.  **State-Dependent Functionality:** Certain actions might only be possible if the Chronicle or Fragment state meets specific criteria.
9.  **Basic Access Control:** A designated authority for certain actions (like initial minting or setting global parameters).
10. **Archival Mechanism:** A state change for NFTs that might opt them out of certain interactions but perhaps qualify them for future passive benefits (concept, not fully implemented benefits here).

---

**Outline:**

1.  SPDX License and Pragma
2.  Error Definitions
3.  Imports (Using a simplified ERC721 implementation internally for uniqueness)
4.  Interfaces (Minimal ERC721 required)
5.  Library (Optional - for complex math, but keeping it simple for clarity)
6.  Structs (`FragmentData`, `ChronicleState`, `Pact`)
7.  Events
8.  Contract Definition (`EthereumChronicles` implements ERC721)
9.  State Variables
    *   ERC721 required state (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`)
    *   Custom Fragment State (`_fragments`, `_tokenCounter`)
    *   Global Chronicle State (`_chronicleState`)
    *   System Authorities (`_mintingAuthority`, `_admin`)
    *   Archived Status (`_isArchived`)
    *   Fragment Pacts (`_fragmentPacts`)
    *   User Influence (`_attunementInfluence`)
    *   Name and Symbol (`_name`, `_symbol`)
    *   Mapping from owner to list of owned tokens (helper for ERC721 enumeration - omitted for complexity, focusing on core functions).
10. Constructor
11. Modifiers (`onlyMintingAuthority`, `onlyAdmin`, `onlyFragmentOwnerOrApproved`, `notArchived`)
12. Internal / Helper Functions (e.g., `_safeTransfer`, `_exists`, `_isApprovedOrOwner`, `_addFragmentToOwnerList`, `_removeFragmentFromOwnerList`)
13. ERC721 Required Functions (`balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll`, `transferFrom`, `safeTransferFrom`, `supportsInterface`, `name`, `symbol`) - *Implementing these counts towards the 20+ function count.*
14. Custom Chronicle Functions (20+ functions total including ERC721):
    *   Minting (`mintFragment`)
    *   Fragment State Getters (`getFragmentDetails`, `getFragmentPurity`, `getFragmentAge`, `getFragmentAffinity`, `getFragmentJournal`)
    *   Fragment State Mutators (`refineFragment`, `ageFragment`, `engraveFragment`, `archiveFragment`, `unarchiveFragment`)
    *   Complex Fragment Interactions (`mergeFragments`, `setPact`, `breakPact`, `getFragmentPacts`)
    *   Chronicle Interaction (`attuneFragmentToChronicle`, `witnessChronicle`)
    *   Chronicle State Getters (`getChronicleState`, `getTotalFragmentsMinted`, `getTotalAttunementInfluence`)
    *   Admin/Authority Functions (`setMintingAuthority`, `updateChronicleParameter`, `setFragmentAffinityByAdmin`)
    *   Utility/View Functions (`calculateMergeOutcome`, `calculateAttunementInfluence`)

---

**Function Summary:**

*   **ERC721 Standard (Basic Implementation):**
    *   `balanceOf(address owner)`: Get number of tokens owned by address.
    *   `ownerOf(uint256 tokenId)`: Get owner of a token.
    *   `approve(address to, uint256 tokenId)`: Grant approval for a specific token.
    *   `getApproved(uint256 tokenId)`: Get approved address for a token.
    *   `setApprovalForAll(address operator, bool approved)`: Grant/revoke approval for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Check if operator is approved for all tokens.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token (basic).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfer token (safer, checks receiver).
    *   `supportsInterface(bytes4 interfaceId)`: Check if contract supports an interface.
    *   `name()`: Get token name.
    *   `symbol()`: Get token symbol.
*   **Chronicle & Fragment Custom Functions:**
    *   `constructor(string memory name, string memory symbol, address initialMintingAuthority)`: Deploys the contract, sets name, symbol, and initial authority.
    *   `mintFragment(address to, uint8 initialAffinity)`: Mints a new fragment, callable only by `_mintingAuthority`. Initializes fragment state.
    *   `getFragmentDetails(uint256 tokenId)`: View details (Purity, Age, Affinity, Journal, Pacts, Archived status) of a fragment.
    *   `getFragmentPurity(uint256 tokenId)`: View the Purity score of a fragment.
    *   `getFragmentAge(uint256 tokenId)`: View the Age counter of a fragment.
    *   `getFragmentAffinity(uint256 tokenId)`: View the Affinity type of a fragment.
    *   `getFragmentJournal(uint256 tokenId)`: View the history journal entries of a fragment.
    *   `refineFragment(uint256 tokenId, uint8 refinementFactor)`: Modifies a fragment's Purity and Age based on a factor. Requires ownership/approval.
    *   `ageFragment(uint256 tokenId)`: Increases the Age counter of a fragment. Requires ownership/approval. Might have cooldowns (not implemented for brevity).
    *   `engraveFragment(uint256 tokenId, string memory entry)`: Adds a short text entry to the fragment's journal. Limited journal size. Requires ownership/approval.
    *   `archiveFragment(uint256 tokenId)`: Marks a fragment as archived. Requires ownership/approval.
    *   `unarchiveFragment(uint256 tokenId)`: Unmarks a fragment as archived. Requires ownership/approval.
    *   `mergeFragments(uint256 tokenId1, uint256 tokenId2)`: Burns two fragments and mints a new one with properties derived from the inputs. Requires ownership/approval of both.
    *   `setPact(uint256 tokenId1, uint256 tokenId2)`: Creates a temporary on-chain link (Pact) between two fragments owned/approved by the caller.
    *   `breakPact(uint256 tokenId1, uint256 tokenId2)`: Removes a Pact between two fragments. Requires ownership/approval of both.
    *   `getFragmentPacts(uint256 tokenId)`: View all Pacts involving a specific fragment.
    *   `attuneFragmentToChronicle(uint256 tokenId)`: Uses a fragment to influence the global Chronicle state. Consumes some fragment Purity, increases Chronicle Energy, and grants user Attunement Influence. Requires ownership/approval and fragment not archived.
    *   `witnessChronicle()`: A low-cost interaction to signify participation or read latest Chronicle state (simplified: just triggers an event or allows reading state).
    *   `getChronicleState()`: View the current global state of The Chronicle (Energy, Narrative Index).
    *   `getTotalFragmentsMinted()`: View the total number of fragments ever minted.
    *   `getTotalAttunementInfluence(address user)`: View the accumulated influence a user has gained through attunement.
    *   `setMintingAuthority(address authority)`: Sets the address allowed to call `mintFragment`. Only callable by admin.
    *   `updateChronicleParameter(uint8 parameterIndex, uint256 newValue)`: Admin function to directly adjust a Chronicle state parameter (simplified: uses index). Only callable by admin.
    *   `setFragmentAffinityByAdmin(uint256 tokenId, uint8 newAffinity)`: Allows admin to forcefully change a fragment's affinity (e.g., for balancing or events).
    *   `calculateMergeOutcome(uint256 tokenId1, uint256 tokenId2)`: View function to preview the potential properties of a new fragment if two specified fragments were merged. Does not consume tokens.
    *   `calculateAttunementInfluence(uint256 tokenId)`: View function to preview how much influence attuning a specific fragment would grant.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Error definitions to save gas and improve readability
error ERC721InvalidOwner(address owner);
error ERC721NonexistentToken(uint256 tokenId);
error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
error ERC721InsufficientApproval();
error ERC721InvalidApprover();
error ERC721InvalidOperator();
error ERC721InvalidReceiver(address receiver);
error Chronicle_NotMintingAuthority();
error Chronicle_NotAdmin();
error Chronicle_TokenAlreadyArchived();
error Chronicle_TokenNotArchived();
error Chronicle_InvalidRefinementFactor();
error Chronicle_JournalFull();
error Chronicle_InsufficientFragmentsForMerge();
error Chronicle_CannotMergeSelf();
error Chronicle_PactAlreadyExists();
error Chronicle_PactDoesNotExist();
error Chronicle_FragmentCannotBeAttuned(uint256 tokenId); // e.g., purity too low, archived

// Minimal ERC721 interface for compliance reference
interface IERC721 {
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    // function tokenURI(uint256 tokenId) external view returns (string memory); // Omitting tokenURI for simpler on-chain state example
}

contract EthereumChronicles is IERC721Metadata, IERC165 {

    // --- Structs ---

    // Represents the dynamic state of a single Chronicle Fragment (NFT)
    struct FragmentData {
        uint64 mintTimestamp; // When the fragment was created
        uint32 ageCounter;    // Tracks interactions or time passed (simplified as counter)
        uint16 purity;        // A score representing integrity (e.g., 0-1000)
        uint8 affinity;       // Elemental or thematic type (e.g., 0: Earth, 1: Fire, 2: Water, 3: Air, 4: Spirit)
        string[] journal;     // On-chain history log (limited size)
    }

    // Represents the global state of The Chronicle
    struct ChronicleState {
        uint256 currentEnergy;     // A global resource/metric influenced by fragment interactions
        uint256 narrativeIndex;    // A simplified index tracking narrative progression
        // More global parameters could be added here
    }

    // Represents a temporary link between two fragments
    struct Pact {
        uint256 fragmentId1;
        uint256 fragmentId2;
        uint64 creationTimestamp;
        // Could add expiration, type, etc.
    }

    // --- State Variables ---

    // ERC721 Core Mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Custom Fragment Storage
    mapping(uint256 => FragmentData) private _fragments;
    uint256 private _tokenCounter; // Tracks the total number of tokens ever minted

    // Global Chronicle State
    ChronicleState private _chronicleState;

    // System Authorities
    address private _mintingAuthority; // Address allowed to mint new fragments
    address private _admin;            // Contract administrator (can change minting authority, update parameters)

    // Fragment Status
    mapping(uint256 => bool) private _isArchived; // True if fragment is archived

    // Fragment Pacts
    mapping(uint256 => uint256[]) private _fragmentPacts; // Maps fragment ID to list of pact IDs it's involved in
    mapping(uint256 => Pact) private _pactDetails;      // Stores details of each pact
    uint256 private _pactCounter;                      // Counter for unique pact IDs

    // User Influence
    mapping(address => uint256) private _attunementInfluence; // Tracks influence gained by users

    // Contract Metadata
    string private _name;
    string private _symbol;

    // Constants
    uint8 public constant MAX_JOURNAL_SIZE = 5; // Limit journal entries to prevent excessive gas costs
    uint16 public constant MAX_PURITY = 1000;
    uint16 public constant MIN_PURITY_FOR_ATTUNE = 100; // Example threshold

    // --- Events ---

    // ERC721 Events (declared in interface, re-declared here for clarity or if not importing interface directly)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Custom Chronicle Events
    event FragmentMinted(address indexed owner, uint256 indexed tokenId, uint8 initialAffinity);
    event FragmentStateChanged(uint256 indexed tokenId, string stateChangeType); // e.g., "Refined", "Aged", "Engraved"
    event FragmentArchived(uint256 indexed tokenId);
    event FragmentUnarchived(uint256 indexed tokenId);
    event FragmentsMerged(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed newTokenId); // token1, token2 burned, newTokenId minted
    event PactCreated(uint256 indexed pactId, uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed creator);
    event PactBroken(uint256 indexed pactId);
    event FragmentAttuned(uint256 indexed tokenId, address indexed attuner, uint256 chronicleEnergyIncreased, uint256 attunementInfluenceGained);
    event ChronicleStateUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event MintingAuthorityUpdated(address indexed oldAuthority, address indexed newAuthority);
    event Witnessed(address indexed participant); // Low-cost interaction event

    // --- Modifiers ---

    modifier onlyMintingAuthority() {
        if (msg.sender != _mintingAuthority) revert Chronicle_NotMintingAuthority();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert Chronicle_NotAdmin();
        _;
    }

    modifier onlyFragmentOwnerOrApproved(uint256 tokenId) {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721InsufficientApproval();
        _;
    }

    modifier notArchived(uint256 tokenId) {
        if (_isArchived[tokenId]) revert Chronicle_TokenAlreadyArchived();
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, address initialMintingAuthority_) {
        _name = name_;
        _symbol = symbol_;
        _admin = msg.sender; // Deployer is initial admin
        _mintingAuthority = initialMintingAuthority_;
        _tokenCounter = 0; // Token IDs start from 1 typically, counter from 0 for next ID.
        _pactCounter = 0;

        // Initialize Chronicle State
        _chronicleState = ChronicleState({
            currentEnergy: 0,
            narrativeIndex: 0
        });

        // Interface support (ERC721, ERC165)
        _registerInterface(bytes4(keccak256("ERC721")));
        _registerInterface(bytes4(keccak256("ERC165")));
        _registerInterface(bytes4(keccak256("ERC721Metadata")));
    }

    // --- Internal / Helper Functions (Minimal ERC721 Implementation) ---

    bytes4 private _supportedInterfaces;

    function _registerInterface(bytes4 interfaceId) internal virtual {
        _supportedInterfaces ^= interfaceId;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Uses the public ownerOf
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert ERC721IncorrectOwner(from, tokenId, ownerOf(tokenId));
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
         _transfer(from, to, tokenId);
         // In a real contract, this would also include `require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");`
         // Omitting _checkOnERC721Received for simplicity and self-containment, assuming standard addresses.
    }

     function _mint(address to, uint256 tokenId, uint8 initialAffinity) internal {
        if (to == address(0)) revert ERC721InvalidReceiver(address(0));
        if (_exists(tokenId)) revert ERC721NonexistentToken(tokenId); // Should not happen with _tokenCounter

        _balances[to] += 1;
        _owners[tokenId] = to;

        // Initialize custom fragment data
        _fragments[tokenId] = FragmentData({
            mintTimestamp: uint64(block.timestamp),
            ageCounter: 0,
            purity: MAX_PURITY, // Starts with max purity
            affinity: initialAffinity,
            journal: new string[](0) // Start with empty journal
        });
        _isArchived[tokenId] = false; // Initially not archived

        emit Transfer(address(0), to, tokenId);
        emit FragmentMinted(to, tokenId, initialAffinity);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // uses public getter

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _fragments[tokenId]; // Delete fragment data
        delete _isArchived[tokenId]; // Remove archived status

        // Clean up pacts related to this fragment (basic cleanup, could be more robust)
        uint256[] memory pactIds = _fragmentPacts[tokenId];
        for(uint i = 0; i < pactIds.length; i++) {
            // Simply delete the pact details. _fragmentPacts mappings need more complex update if removing elements.
            // For simplicity here, we'll leave remnants in _fragmentPacts which is acceptable for this example.
             delete _pactDetails[pactIds[i]];
        }
        delete _fragmentPacts[tokenId]; // Delete the list of pact IDs for the burned token

        emit Transfer(owner, address(0), tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    // --- ERC721 Standard Functions ---

    // 1
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert ERC721InvalidOwner(address(0));
        return _balances[owner];
    }

    // 2
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert ERC721NonexistentToken(tokenId);
        return owner;
    }

    // 3
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId); // Checks existence
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ERC721InsufficientApproval();
        }
        _approve(to, tokenId);
    }

    // 4
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
         return _tokenApprovals[tokenId];
    }

    // 5
    function setApprovalForAll(address operator, bool approved) public virtual override {
         if (operator == msg.sender) revert ERC721InvalidOperator();
         _operatorApprovals[msg.sender][operator] = approved;
         emit ApprovalForAll(msg.sender, operator, approved);
    }

    // 6
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
         return _operatorApprovals[owner][operator];
    }

    // 7
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721InsufficientApproval();
         _transfer(from, to, tokenId);
    }

    // 8
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    // 9
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public virtual override {
         if (!_isApprovedOrOwner(msg.sender, tokenId)) revert ERC721InsufficientApproval();
         _safeTransfer(from, to, tokenId, data);
    }

    // 10
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x01ffc9a7 || // ERC165
               (interfaceId & _supportedInterfaces) == interfaceId; // Supported interfaces
    }

    // 11
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // 12
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // --- Custom Chronicle & Fragment Functions ---

    // 13: Mint a new fragment (Authority Function)
    function mintFragment(address to, uint8 initialAffinity) external onlyMintingAuthority returns (uint256) {
        _tokenCounter += 1;
        uint256 newTokenId = _tokenCounter;
        _mint(to, newTokenId, initialAffinity); // Calls internal mint function

        return newTokenId;
    }

    // 14: Get all details of a fragment (View Function)
    function getFragmentDetails(uint256 tokenId) public view returns (
        uint64 mintTimestamp,
        uint32 ageCounter,
        uint16 purity,
        uint8 affinity,
        string[] memory journal,
        bool isArchived,
        uint256[] memory currentPactIds
    ) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        FragmentData storage fragment = _fragments[tokenId];
        return (
            fragment.mintTimestamp,
            fragment.ageCounter,
            fragment.purity,
            fragment.affinity,
            fragment.journal,
            _isArchived[tokenId],
            _fragmentPacts[tokenId] // Returns the array of pact IDs
        );
    }

    // 15: Get Purity score (View Function)
    function getFragmentPurity(uint256 tokenId) public view returns (uint16) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _fragments[tokenId].purity;
    }

    // 16: Get Age counter (View Function)
    function getFragmentAge(uint256 tokenId) public view returns (uint32) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _fragments[tokenId].ageCounter;
    }

    // 17: Get Affinity type (View Function)
    function getFragmentAffinity(uint256 tokenId) public view returns (uint8) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        return _fragments[tokenId].affinity;
    }

    // 18: Get Journal entries (View Function)
    function getFragmentJournal(uint256 tokenId) public view returns (string[] memory) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
         return _fragments[tokenId].journal;
    }

    // 19: Refine a fragment (Mutator)
    function refineFragment(uint256 tokenId, uint8 refinementFactor) public onlyFragmentOwnerOrApproved(tokenId) notArchived(tokenId) {
        if (refinementFactor == 0) revert Chronicle_InvalidRefinementFactor();

        FragmentData storage fragment = _fragments[tokenId];

        // Example complex logic: refinement increases purity, but also increases age faster
        uint256 purityIncrease = refinementFactor * 10; // Example scaling
        uint256 ageIncrease = refinementFactor / 2; // Example scaling

        fragment.purity = uint16(Math.min(uint256(fragment.purity) + purityIncrease, MAX_PURITY));
        fragment.ageCounter += uint32(Math.max(uint256(ageIncrease), 1)); // Ensure age increases by at least 1

        emit FragmentStateChanged(tokenId, "Refined");
    }

     // 20: Age a fragment (Mutator)
    function ageFragment(uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) notArchived(tokenId) {
        FragmentData storage fragment = _fragments[tokenId];

        // Example logic: simply increments age counter. Could add time checks later.
        fragment.ageCounter += 1;

        emit FragmentStateChanged(tokenId, "Aged");
    }

    // 21: Engrave a short message onto a fragment's journal (Mutator)
    function engraveFragment(uint256 tokenId, string memory entry) public onlyFragmentOwnerOrApproved(tokenId) notArchived(tokenId) {
        FragmentData storage fragment = _fragments[tokenId];

        if (fragment.journal.length >= MAX_JOURNAL_SIZE) revert Chronicle_JournalFull();

        fragment.journal.push(entry);

        emit FragmentStateChanged(tokenId, "Engraved");
    }

    // 22: Archive a fragment (Mutator)
    function archiveFragment(uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) {
        if (_isArchived[tokenId]) revert Chronicle_TokenAlreadyArchived();
        _isArchived[tokenId] = true;
        // Potential future: Remove from active interactions, maybe qualify for passive rewards.
        emit FragmentArchived(tokenId);
    }

    // 23: Unarchive a fragment (Mutator)
    function unarchiveFragment(uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) {
        if (!_isArchived[tokenId]) revert Chronicle_TokenNotArchived();
        _isArchived[tokenId] = false;
        emit FragmentUnarchived(tokenId);
    }

    // 24: Merge two fragments into a new one (Complex Interaction)
    // Burns two tokens, mints one new token with derived properties.
    function mergeFragments(uint256 tokenId1, uint256 tokenId2) public onlyFragmentOwnerOrApproved(tokenId1) notArchived(tokenId1) {
        // Ensure caller owns/is approved for both tokens
        if (!_isApprovedOrOwner(msg.sender, tokenId2)) revert ERC721InsufficientApproval(); // Checked for tokenId1 in modifier
        if (!_exists(tokenId2)) revert ERC721NonexistentToken(tokenId2); // Check existence of second token explicitly
        if (tokenId1 == tokenId2) revert Chronicle_CannotMergeSelf();

        FragmentData storage fragment1 = _fragments[tokenId1];
        FragmentData storage fragment2 = _fragments[tokenId2];

        // --- Algorithmic Property Derivation (Example Logic) ---
        // New Purity: Average of inputs + bonus based on affinity match?
        uint16 newPurity = uint16((fragment1.purity + fragment2.purity) / 2);
        if (fragment1.affinity == fragment2.affinity) {
            newPurity = uint16(Math.min(uint256(newPurity) + 100, MAX_PURITY)); // Bonus for matching affinity
        }
        // New Age: Sum of inputs? Max of inputs?
        uint32 newAge = fragment1.ageCounter + fragment2.ageCounter;
        // New Affinity: Based on dominance? Random? Combined?
        uint8 newAffinity = fragment1.affinity; // Simple: inherits first token's affinity

        // --- Burn the original tokens ---
        _burn(tokenId1);
        _burn(tokenId2);

        // --- Mint a new token ---
        _tokenCounter += 1;
        uint256 newTokenId = _tokenCounter;
        _mint(msg.sender, newTokenId, newAffinity); // Mint to the caller

        // Set derived properties for the new fragment
        FragmentData storage newFragment = _fragments[newTokenId];
        newFragment.purity = newPurity;
        newFragment.ageCounter = newAge;
        // Journal could be empty or a combination, let's leave empty for gas
        // newFragment.journal = ...;

        emit FragmentsMerged(tokenId1, tokenId2, newTokenId);
    }

    // 25: Create a Pact between two fragments (Complex Interaction)
    function setPact(uint256 tokenId1, uint256 tokenId2) public onlyFragmentOwnerOrApproved(tokenId1) notArchived(tokenId1) {
        if (!_isApprovedOrOwner(msg.sender, tokenId2)) revert ERC721InsufficientApproval(); // Check for tokenId2
        if (!_exists(tokenId2)) revert ERC721NonexistentToken(tokenId2);
        if (_isArchived[tokenId2]) revert Chronicle_TokenAlreadyArchived(); // Cannot pact with archived tokens
        if (tokenId1 == tokenId2) revert Chronicle_CannotMergeSelf(); // Cannot pact with self

        // Check if pact already exists (order-insensitive check)
        uint256[] storage pacts1 = _fragmentPacts[tokenId1];
        for(uint i = 0; i < pacts1.length; i++) {
             uint256 pactId = pacts1[i];
             if (_pactDetails[pactId].fragmentId1 == tokenId2 || _pactDetails[pactId].fragmentId2 == tokenId2) {
                 revert Chronicle_PactAlreadyExists();
             }
        }

        _pactCounter += 1;
        uint256 pactId = _pactCounter;

        _pactDetails[pactId] = Pact({
            fragmentId1: tokenId1,
            fragmentId2: tokenId2,
            creationTimestamp: uint64(block.timestamp)
        });

        _fragmentPacts[tokenId1].push(pactId);
        _fragmentPacts[tokenId2].push(pactId);

        emit PactCreated(pactId, tokenId1, tokenId2, msg.sender);
    }

    // 26: Break a Pact between two fragments (Complex Interaction)
     function breakPact(uint256 tokenId1, uint256 tokenId2) public onlyFragmentOwnerOrApproved(tokenId1) {
        // Note: We only need approval/ownership for one token to break a pact involving it.
        // We don't need to check archiving status here, pacts can be broken even if one side is archived.

        uint256 pactIdToBreak = 0;
        uint256[] storage pacts1 = _fragmentPacts[tokenId1];

        // Find the pact ID
        for(uint i = 0; i < pacts1.length; i++) {
             uint256 currentPactId = pacts1[i];
             if (_pactDetails[currentPactId].fragmentId1 == tokenId2 || _pactDetails[currentPactId].fragmentId2 == tokenId2) {
                 pactIdToBreak = currentPactId;
                 break;
             }
        }

        if (pactIdToBreak == 0) revert Chronicle_PactDoesNotExist();

        // Delete pact details
        delete _pactDetails[pactIdToBreak];

        // Basic removal from fragmentPacts arrays (simplified - leaves empty slots or requires complex loop/copy)
        // A production contract would implement a more efficient way to remove from dynamic arrays.
        // For this example, we just clear the entire mapping entry for simplicity.
        // This means getFragmentPacts might return pactIds that are now deleted in _pactDetails.
        // A better approach would be to iterate and build a new array, or use linked lists (more complex).
        // Let's just delete the pactDetails and keep the ID in the arrays for simplicity in this example.
        // A slightly better way: find index and swap with last, then pop. Implementing that for cleanliness.
        _removePactIdFromFragmentPacts(tokenId1, pactIdToBreak);
        _removePactIdFromFragmentPacts(tokenId2, pactIdToBreak);


        emit PactBroken(pactIdToBreak);
     }

    // Internal helper to remove a pact ID from a fragment's pact list
    function _removePactIdFromFragmentPacts(uint256 tokenId, uint256 pactIdToRemove) internal {
        uint256[] storage pactIds = _fragmentPacts[tokenId];
        for (uint i = 0; i < pactIds.length; i++) {
            if (pactIds[i] == pactIdToRemove) {
                // Swap with the last element and pop
                if (i != pactIds.length - 1) {
                    pactIds[i] = pactIds[pactsIds.length - 1];
                }
                pactIds.pop();
                break; // Found and removed, exit loop
            }
        }
    }


    // 27: View Pacts involving a fragment (View Function)
     function getFragmentPacts(uint256 tokenId) public view returns (Pact[] memory) {
         if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);

         uint256[] storage pactIds = _fragmentPacts[tokenId];
         Pact[] memory activePacts = new Pact[](pactIds.length);
         uint currentCount = 0;

         for(uint i = 0; i < pactIds.length; i++) {
             uint256 pactId = pactIds[i];
             Pact storage pact = _pactDetails[pactId];
             // Check if pact details still exist (not broken already via another fragment)
             if (pact.fragmentId1 != 0 || pact.fragmentId2 != 0) {
                 activePacts[currentCount] = pact;
                 currentCount++;
             }
         }

         // Resize array if some pacts were already broken
         if (currentCount < activePacts.length) {
             Pact[] memory sizedPacts = new Pact[](currentCount);
             for(uint i = 0; i < currentCount; i++) {
                 sizedPacts[i] = activePacts[i];
             }
             return sizedPacts;
         } else {
             return activePacts;
         }
     }


    // 28: Attune a fragment to the Chronicle (Complex Interaction)
    // Influences global state, consumes fragment purity, grants user influence.
    function attuneFragmentToChronicle(uint256 tokenId) public onlyFragmentOwnerOrApproved(tokenId) notArchived(tokenId) {
        FragmentData storage fragment = _fragments[tokenId];

        if (fragment.purity < MIN_PURITY_FOR_ATTUNE) revert Chronicle_FragmentCannotBeAttuned(tokenId);

        // --- Algorithmic State Change (Example Logic) ---
        // Influence on Chronicle Energy: based on fragment purity and age
        uint256 energyIncrease = (uint256(fragment.purity) * (uint256(fragment.ageCounter) + 1)) / 100; // Scale down example

        // Purity Consumption: Attuning reduces purity
        uint16 purityConsumed = uint16(Math.min(uint256(fragment.purity), uint256(fragment.purity) / 5 + 10)); // Consume min 10, or 20%
        fragment.purity -= purityConsumed;

        // Grant User Influence: based on energy contributed
        uint256 influenceGained = energyIncrease / 10; // Scale down example

        _chronicleState.currentEnergy += energyIncrease;
        _attunementInfluence[msg.sender] += influenceGained;

        // Simple Narrative Progression: Increment narrative index every X energy?
        _chronicleState.narrativeIndex = _chronicleState.currentEnergy / 1000; // Example threshold

        emit FragmentStateChanged(tokenId, "Attuned");
        emit FragmentAttuned(tokenId, msg.sender, energyIncrease, influenceGained);
        emit ChronicleStateUpdated("currentEnergy", _chronicleState.currentEnergy - energyIncrease, _chronicleState.currentEnergy);
        emit ChronicleStateUpdated("narrativeIndex", _chronicleState.narrativeIndex - (energyIncrease / 1000), _chronicleState.narrativeIndex);
    }

    // 29: Witness the Chronicle (Low-Cost Interaction / View Event)
    function witnessChronicle() public {
        // This function primarily serves as a low-cost on-chain action
        // It doesn't change fragment state but signifies user engagement.
        // Could potentially provide small passive benefits or qualify for future airdrops.
        // Here, it just emits an event.
        emit Witnessed(msg.sender);
        // Could optionally return getChronicleState()
    }

    // 30: Get global Chronicle State (View Function)
    function getChronicleState() public view returns (uint256 currentEnergy, uint256 narrativeIndex) {
        return (_chronicleState.currentEnergy, _chronicleState.narrativeIndex);
    }

    // 31: Get total fragments minted (View Function)
    function getTotalFragmentsMinted() public view returns (uint256) {
        return _tokenCounter;
    }

    // 32: Get total attunement influence for a user (View Function)
    function getTotalAttunementInfluence(address user) public view returns (uint256) {
        return _attunementInfluence[user];
    }

    // 33: Set the Minting Authority (Admin Function)
    function setMintingAuthority(address authority) public onlyAdmin {
        address oldAuthority = _mintingAuthority;
        _mintingAuthority = authority;
        emit MintingAuthorityUpdated(oldAuthority, authority);
    }

    // 34: Update a Chronicle parameter (Admin Function)
    // Simplified: allows setting one of the state variables by index.
    function updateChronicleParameter(uint8 parameterIndex, uint256 newValue) public onlyAdmin {
        if (parameterIndex == 0) {
            uint256 oldValue = _chronicleState.currentEnergy;
            _chronicleState.currentEnergy = newValue;
            emit ChronicleStateUpdated("currentEnergy", oldValue, newValue);
        } else if (parameterIndex == 1) {
            uint256 oldValue = _chronicleState.narrativeIndex;
             _chronicleState.narrativeIndex = newValue;
            emit ChronicleStateUpdated("narrativeIndex", oldValue, newValue);
        }
        // Could add more parameters here
    }

    // 35: Set fragment affinity (Admin/Specific Condition Function)
    // Allows admin to change affinity, potentially for game balance or event purposes.
    function setFragmentAffinityByAdmin(uint256 tokenId, uint8 newAffinity) public onlyAdmin {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
        uint8 oldAffinity = _fragments[tokenId].affinity;
        _fragments[tokenId].affinity = newAffinity;
        emit FragmentStateChanged(tokenId, string(abi.encodePacked("AffinityChanged:", uint256(oldAffinity), "->", uint256(newAffinity))));
    }

    // 36: Calculate the outcome of a potential merge (View Function)
    // Provides a preview without executing the state change.
    function calculateMergeOutcome(uint256 tokenId1, uint256 tokenId2) public view returns (
        uint16 potentialPurity,
        uint32 potentialAge,
        uint8 potentialAffinity
    ) {
        if (!_exists(tokenId1)) revert ERC721NonexistentToken(tokenId1);
        if (!_exists(tokenId2)) revert ERC721NonexistentToken(tokenId2);
        if (tokenId1 == tokenId2) revert Chronicle_CannotMergeSelf();

        FragmentData storage fragment1 = _fragments[tokenId1];
        FragmentData storage fragment2 = _fragments[tokenId2];

         uint16 newPurity = uint16((fragment1.purity + fragment2.purity) / 2);
        if (fragment1.affinity == fragment2.affinity) {
            newPurity = uint16(Math.min(uint256(newPurity) + 100, MAX_PURITY)); // Bonus for matching affinity
        }
        uint32 newAge = fragment1.ageCounter + fragment2.ageCounter;
        uint8 newAffinity = fragment1.affinity; // Simple: inherits first token's affinity

        return (newPurity, newAge, newAffinity);
    }

    // 37: Calculate potential attunement influence (View Function)
     // Provides a preview of influence gained without executing the state change.
    function calculateAttunementInfluence(uint256 tokenId) public view returns (uint256 potentialInfluence) {
        if (!_exists(tokenId)) revert ERC721NonexistentToken(tokenId);
         FragmentData storage fragment = _fragments[tokenId];

        if (fragment.purity < MIN_PURITY_FOR_ATTUNE) return 0; // Cannot attune if purity too low

        uint256 energyIncrease = (uint256(fragment.purity) * (uint256(fragment.ageCounter) + 1)) / 100;
        uint256 influenceGained = energyIncrease / 10;

        return influenceGained;
    }


    // --- Simple Math Library (Manual Implementation to avoid import) ---
    library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
        function max(uint256 a, uint256 b) internal pure returns (uint256) {
            return a > b ? a : b;
        }
    }
}
```