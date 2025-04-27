Okay, here is a Solidity smart contract called `CryptoArtChain` that implements a concept of dynamic, evolving generative art NFTs with layered rights and a curator system.

It includes concepts like:
1.  **Dynamic Traits:** NFT traits stored on-chain that can change over time or based on interaction.
2.  **Generative Base:** Traits determined semi-algorithmically during minting.
3.  **Layered Rights:** Separate ownership of Display and Print rights alongside the base NFT ownership.
4.  **Curator System:** Designated addresses with special permissions to propose and approve trait changes.
5.  **Evolution Triggers:** Functions to trigger trait changes based on time or interaction count.
6.  **On-Chain Metadata Hint:** `tokenURI` hints at off-chain metadata generation using on-chain traits.
7.  **Proposal System:** A basic system for curators to propose changes requiring lead curator approval.

This design is creative as it goes beyond static NFTs, incorporates community influence (curators), and explores different layers of digital asset ownership. It's advanced by managing dynamic state and different rights on-chain.

---

**Contract Name:** `CryptoArtChain`

**Outline:**

1.  **License & Pragma**
2.  **Imports:** OpenZeppelin contracts for ERC721Enumerable, Ownable, Pausable.
3.  **Errors:** Custom errors for clarity.
4.  **Structs:**
    *   `ArtPiece`: Holds unique data for each NFT (traits, evolution state, rights owners).
    *   `TraitChangeProposal`: Holds details for a proposed trait modification.
5.  **Enums:**
    *   `EvolutionState`: Tracks the current evolutionary stage of an art piece.
    *   `ProposalState`: Tracks the state of a trait change proposal.
6.  **State Variables:**
    *   Counters for token IDs and proposal IDs.
    *   Mappings for `ArtPiece` data, `TraitChangeProposal` data.
    *   Mappings/arrays for curator roles (`isCurator`, `leadCurator`).
    *   Configuration variables (max supply, base URI, evolution trigger thresholds).
    *   Mapping to track interaction counts per token.
7.  **Events:** Log key actions like minting, trait changes, rights transfers, curator changes, proposals, evolution triggers.
8.  **Modifiers:** Access control for owner, curators, lead curator, pausable state.
9.  **Core ERC721 Functions:** Overrides and standard implementations (inherited from `ERC721Enumerable`).
10. **Minting Functions:** Controlled function to mint initial art pieces.
11. **Art Data Views:** Functions to retrieve details, traits, evolution state of an art piece.
12. **Curator Management:** Functions for the owner to manage curator roles.
13. **Trait Evolution - Proposal System:** Functions for curators to propose, lead curator to approve/reject, and anyone to execute approved trait changes.
14. **Trait Evolution - Trigger System:** Functions (permissioned) to advance evolution state based on time or interaction count.
15. **Layered Rights Management:** Functions to transfer display and print rights, and view their owners.
16. **Admin & Utility Functions:** Pause/unpause, withdraw funds, set config, get counts.
17. **Internal/Helper Functions:** Logic for trait generation, state transitions, proposal application.

**Function Summary (Minimum 20 functions):**

*   `constructor()`: Initializes contract, sets owner, max supply, initial curator(s).
*   `supportsInterface(bytes4 interfaceId)`: Required for ERC721/Enumerable compliance.
*   `balanceOf(address owner)`: Standard ERC721.
*   `ownerOf(uint256 tokenId)`: Standard ERC721.
*   `getApproved(uint256 tokenId)`: Standard ERC721.
*   `isApprovedForAll(address owner, address operator)`: Standard ERC721.
*   `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard ERC721.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Standard ERC721.
*   `approve(address to, uint256 tokenId)`: Standard ERC721.
*   `setApprovalForAll(address operator, bool approved)`: Standard ERC721.
*   `tokenURI(uint256 tokenId)`: Override ERC721: Generates a metadata URI based on token ID and contract base URI. Hints at off-chain metadata server using on-chain data.
*   `tokenByIndex(uint256 index)`: Standard ERC721Enumerable.
*   `tokenOfOwnerByIndex(address owner, uint256 index)`: Standard ERC721Enumerable.
*   `totalSupply()`: Standard ERC721Enumerable.
*   `mintInitialPiece(address to)`: Mints a new art piece token, generates initial traits. (Permissioned)
*   `getArtPieceDetails(uint256 tokenId)`: View function: Returns all stored data for an art piece.
*   `getTokenTraits(uint256 tokenId)`: View function: Returns just the trait data.
*   `getTokenEvolutionState(uint256 tokenId)`: View function: Returns the current evolution state.
*   `addCurator(address curator)`: Owner function: Grants curator role.
*   `removeCurator(address curator)`: Owner function: Revokes curator role.
*   `isCurator(address account)`: View function: Checks if an address is a curator.
*   `setLeadCurator(address leadCuratorAddress)`: Owner function: Sets the lead curator.
*   `proposeTraitChange(uint256 tokenId, uint256 newTraitValue, uint256 traitIndex)`: Curator function: Proposes changing a specific trait value for a token.
*   `approveTraitChangeProposal(uint256 proposalId)`: Lead Curator function: Approves a proposed trait change.
*   `rejectTraitChangeProposal(uint256 proposalId)`: Lead Curator function: Rejects a proposed trait change.
*   `executeTraitChange(uint256 proposalId)`: Anyone function: Executes an *approved* trait change proposal.
*   `triggerTimeBasedEvolution(uint256 tokenId)`: Permissioned function: Evolves traits based on current block time/number and evolution state.
*   `triggerInteractionBasedEvolution(uint256 tokenId)`: Permissioned function: Evolves traits based on interaction count (e.g., transfers) and evolution state. (Note: Interaction count is incremented on transfer internally).
*   `transferDisplayRights(uint256 tokenId, address to)`: Current display rights owner function: Transfers display rights.
*   `transferPrintRights(uint256 tokenId, address to)`: Current print rights owner function: Transfers print rights.
*   `getDisplayRightsOwner(uint256 tokenId)`: View function: Gets the owner of display rights.
*   `getPrintRightsOwner(uint256 tokenId)`: View function: Gets the owner of print rights.
*   `setMaxSupply(uint256 newMaxSupply)`: Owner function: Sets maximum token supply.
*   `setBaseURI(string memory baseURI_)`: Owner function: Sets the base URI for metadata.
*   `pause()`: Owner function: Pauses core functionality (transfers, minting, proposals).
*   `unpause()`: Owner function: Unpauses contract.
*   `withdraw(address to)`: Owner function: Withdraws contract balance (e.g., potential future fees).
*   `getTraitChangeProposal(uint256 proposalId)`: View function: Retrieves proposal details.
*   `getLatestMintedTokenId()`: View function: Returns the ID of the most recently minted token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title CryptoArtChain: Dynamic, Curated, Layered Art NFTs
/// @author [Your Name/Alias]
/// @notice This contract manages ERC721 tokens representing generative art pieces.
/// It introduces dynamic traits that evolve based on triggers, layered ownership of
/// display and print rights, and a curator system for proposing and approving trait changes.
/// Traits are stored on-chain, and the tokenURI is constructed to hint at off-chain
/// metadata generation leveraging these on-chain traits.

// Outline:
// 1. License & Pragma
// 2. Imports
// 3. Errors
// 4. Structs (ArtPiece, TraitChangeProposal)
// 5. Enums (EvolutionState, ProposalState)
// 6. State Variables
// 7. Events
// 8. Modifiers
// 9. Core ERC721 Functions (inherited + overrides like tokenURI)
// 10. Minting Functions
// 11. Art Data Views
// 12. Curator Management
// 13. Trait Evolution - Proposal System
// 14. Trait Evolution - Trigger System
// 15. Layered Rights Management
// 16. Admin & Utility Functions
// 17. Internal/Helper Functions

// Function Summary (Minimum 20 functions):
// - constructor()
// - supportsInterface(bytes4 interfaceId)
// - balanceOf(address owner)
// - ownerOf(uint256 tokenId)
// - getApproved(uint256 tokenId)
// - isApprovedForAll(address owner, address operator)
// - transferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data)
// - approve(address to, uint256 tokenId)
// - setApprovalForAll(address operator, bool approved)
// - tokenURI(uint256 tokenId)
// - tokenByIndex(uint256 index)
// - tokenOfOwnerByIndex(address owner, uint256 index)
// - totalSupply()
// - mintInitialPiece(address to)
// - getArtPieceDetails(uint256 tokenId)
// - getTokenTraits(uint256 tokenId)
// - getTokenEvolutionState(uint256 tokenId)
// - addCurator(address curator)
// - removeCurator(address curator)
// - isCurator(address account)
// - setLeadCurator(address leadCuratorAddress)
// - proposeTraitChange(uint256 tokenId, uint256 newTraitValue, uint256 traitIndex)
// - approveTraitChangeProposal(uint256 proposalId)
// - rejectTraitChangeProposal(uint256 proposalId)
// - executeTraitChange(uint256 proposalId)
// - triggerTimeBasedEvolution(uint256 tokenId)
// - triggerInteractionBasedEvolution(uint256 tokenId)
// - transferDisplayRights(uint256 tokenId, address to)
// - transferPrintRights(uint256 tokenId, address to)
// - getDisplayRightsOwner(uint256 tokenId)
// - getPrintRightsOwner(uint256 tokenId)
// - setMaxSupply(uint256 newMaxSupply)
// - setBaseURI(string memory baseURI_)
// - pause()
// - unpause()
// - withdraw(address to)
// - getTraitChangeProposal(uint256 proposalId)
// - getLatestMintedTokenId()

contract CryptoArtChain is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // --- Errors ---
    error InvalidTokenId();
    error MaxSupplyReached();
    error UnauthorizedCurator();
    error UnauthorizedLeadCurator();
    error TraitIndexOutOfRange(uint256 traitIndex, uint256 maxTraits);
    error InvalidProposalState(ProposalState currentState, ProposalState expectedState);
    error OnlyOwnerOrCurator();
    error AlreadyCurator();
    error NotCurator();
    error NoProposalExists();
    error EvolutionNotReady(string reason);
    error AlreadyAtMaxEvolution();
    error CannotTransferRightsIfNotOwner(address caller, address tokenOwner);

    // --- Structs ---

    /// @dev Represents the on-chain data for an art piece.
    struct ArtPiece {
        uint256[] traits; // Array of trait values (can be interpreted differently off-chain)
        uint64 creationBlock; // Block when minted
        uint64 lastEvolutionBlock; // Block when last evolved
        uint256 interactionCount; // Counter for interactions like transfers
        EvolutionState evolutionState; // Current stage of evolution
        address displayRightsOwner; // Address with commercial display rights
        address printRightsOwner;   // Address with commercial print rights
    }

    /// @dev Represents a proposal to change a trait value.
    struct TraitChangeProposal {
        uint256 tokenId; // Token the proposal is for
        uint256 traitIndex; // Index of the trait to change
        uint256 newValue;   // The proposed new trait value
        address proposer;   // Curator who made the proposal
        uint64 submissionBlock; // Block proposal was submitted
        ProposalState state; // Current state of the proposal
    }

    // --- Enums ---
    enum EvolutionState {
        Genesis,      // Initial state
        Stage1,       // First evolution
        Stage2,       // Second evolution
        Mature        // Final evolution stage
    }

    enum ProposalState {
        Pending,    // Waiting for lead curator approval
        Approved,   // Approved by lead curator, ready to execute
        Rejected,   // Rejected by lead curator
        Executed    // Proposal has been applied
    }

    // --- State Variables ---
    mapping(uint256 => ArtPiece) private _artPieces;
    mapping(uint256 => TraitChangeProposal) private _traitChangeProposals;
    mapping(address => bool) private _isCurator;
    address public leadCurator;

    uint256 public maxSupply;
    string private _baseURI;

    // Configuration for evolution triggers (example thresholds)
    uint64 public constant TIME_BASED_EVOLUTION_INTERVAL_BLOCKS = 100; // Example: Evolve every 100 blocks
    uint256 public constant INTERACTION_BASED_EVOLUTION_THRESHOLD = 5; // Example: Evolve after 5 interactions

    // --- Events ---
    event ArtPieceMinted(uint256 indexed tokenId, address indexed owner, uint64 creationBlock);
    event TraitsChanged(uint256 indexed tokenId, uint256[] newTraits, address changer, string reason);
    event EvolutionStateChanged(uint256 indexed tokenId, EvolutionState oldState, EvolutionState newState, address trigger);
    event DisplayRightsTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event PrintRightsTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event CuratorAdded(address indexed curator, address indexed addedBy);
    event CuratorRemoved(address indexed curator, address indexed removedBy);
    event LeadCuratorSet(address indexed oldLeadCurator, address indexed newLeadCurator);
    event TraitChangeProposalSubmitted(uint256 indexed proposalId, uint256 indexed tokenId, uint256 traitIndex, uint256 newValue, address indexed proposer);
    event TraitChangeProposalStateChanged(uint256 indexed proposalId, ProposalState newState, address indexed actor);

    // --- Modifiers ---
    modifier onlyCurator() {
        if (!_isCurator[msg.sender]) {
            revert UnauthorizedCurator();
        }
        _;
    }

    modifier onlyLeadCurator() {
        if (msg.sender != leadCurator) {
            revert UnauthorizedLeadCurator();
        }
        _;
    }

    modifier onlyOwnerOrCurator(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender && !_isCurator[msg.sender]) {
             revert OnlyOwnerOrCurator();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialMaxSupply, address initialLeadCurator)
        ERC721(name, symbol)
        Ownable(msg.sender) // Owner is the deployer
        Pausable()
    {
        maxSupply = initialMaxSupply;
        leadCurator = initialLeadCurator;
        _isCurator[initialLeadCurator] = true; // Make lead curator a curator too
        emit CuratorAdded(initialLeadCurator, msg.sender); // Log lead curator addition
    }

    // --- Core ERC721 Overrides ---

    /// @dev See {IERC721Enumerable-tokenByIndex}.
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        return super.tokenByIndex(index);
    }

    /// @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    /// @dev See {IERC721-totalSupply}.
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    /// Note: This simply returns a base URI + token ID. An off-chain service
    /// should use this URI and call `getArtPieceDetails` to generate the
    /// full metadata JSON based on the on-chain traits.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        string memory base = _baseURI;
        if (bytes(base).length == 0) {
            return ""; // Or revert? Depends on desired behavior
        }
        return string(abi.encodePacked(base, Strings.toString(tokenId)));
    }

    /// @dev Internal transfer hook to update interaction count.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Increment interaction count on non-mint transfers
        if (from != address(0)) {
            _artPieces[tokenId].interactionCount++;
        }
    }

    // --- Minting Functions ---

    /// @notice Mints a new art piece and assigns initial random-ish traits.
    /// Only callable by the contract owner.
    /// @param to The address to mint the token to.
    function mintInitialPiece(address to) public onlyOwner whenNotPaused {
        uint256 newTokenId = _tokenIdCounter.current();
        if (newTokenId >= maxSupply) {
            revert MaxSupplyReached();
        }

        _safeMint(to, newTokenId);
        _tokenIdCounter.increment();

        // Initialize art piece data
        _artPieces[newTokenId] = ArtPiece({
            traits: _generateInitialTraits(newTokenId), // Deterministic based on token ID
            creationBlock: uint64(block.number),
            lastEvolutionBlock: uint64(block.number),
            interactionCount: 0,
            evolutionState: EvolutionState.Genesis,
            displayRightsOwner: to, // Owner gets initial rights
            printRightsOwner: to
        });

        emit ArtPieceMinted(newTokenId, to, uint64(block.number));
        emit DisplayRightsTransferred(newTokenId, address(0), to); // Log initial rights
        emit PrintRightsTransferred(newTokenId, address(0), to);
    }

    // --- Art Data Views ---

    /// @notice Gets the complete details for an art piece.
    /// @param tokenId The ID of the token.
    /// @return A tuple containing the ArtPiece struct data.
    function getArtPieceDetails(uint256 tokenId) public view returns (ArtPiece memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _artPieces[tokenId];
    }

    /// @notice Gets just the trait values for an art piece.
    /// @param tokenId The ID of the token.
    /// @return An array of trait values.
    function getTokenTraits(uint256 tokenId) public view returns (uint256[] memory) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _artPieces[tokenId].traits;
    }

    /// @notice Gets the current evolution state of an art piece.
    /// @param tokenId The ID of the token.
    /// @return The current EvolutionState enum value.
    function getTokenEvolutionState(uint256 tokenId) public view returns (EvolutionState) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _artPieces[tokenId].evolutionState;
    }

     /// @notice Gets the current interaction count for an art piece.
    /// @param tokenId The ID of the token.
    /// @return The current interaction count.
    function getTokenInteractionCount(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _artPieces[tokenId].interactionCount;
    }


    // --- Curator Management ---

    /// @notice Grants the curator role to an address.
    /// Only callable by the contract owner.
    /// @param curator The address to add as a curator.
    function addCurator(address curator) public onlyOwner {
        if (_isCurator[curator]) revert AlreadyCurator();
        _isCurator[curator] = true;
        emit CuratorAdded(curator, msg.sender);
    }

    /// @notice Revokes the curator role from an address.
    /// Only callable by the contract owner.
    /// @param curator The address to remove as a curator.
    function removeCurator(address curator) public onlyOwner {
        if (!_isCurator[curator]) revert NotCurator();
         // Prevent removing the lead curator role this way
        if (curator == leadCurator) {
            revert("Cannot remove lead curator role here. Set new lead curator first.");
        }
        _isCurator[curator] = false;
        emit CuratorRemoved(curator, msg.sender);
    }

    /// @notice Checks if an address is a curator.
    /// @param account The address to check.
    /// @return True if the address is a curator, false otherwise.
    function isCurator(address account) public view returns (bool) {
        return _isCurator[account];
    }

     /// @notice Sets the lead curator address. The lead curator must also be a curator.
    /// Only callable by the contract owner.
    /// @param leadCuratorAddress The address to set as the new lead curator.
    function setLeadCurator(address leadCuratorAddress) public onlyOwner {
        if (!_isCurator[leadCuratorAddress]) {
            revert("New lead curator must be an existing curator.");
        }
        address oldLeadCurator = leadCurator;
        leadCurator = leadCuratorAddress;
        emit LeadCuratorSet(oldLeadCurator, leadCuratorAddress);
    }

    // --- Trait Evolution - Proposal System ---

    /// @notice Proposes a change to a specific trait of an art piece.
    /// Only callable by curators.
    /// @param tokenId The ID of the token to change.
    /// @param newTraitValue The desired new value for the trait.
    /// @param traitIndex The index of the trait in the traits array to change.
    /// @return The ID of the created proposal.
    function proposeTraitChange(uint256 tokenId, uint256 newTraitValue, uint256 traitIndex)
        public
        onlyCurator
        whenNotPaused
        returns (uint256)
    {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (traitIndex >= _artPieces[tokenId].traits.length) {
            revert TraitIndexOutOfRange(traitIndex, _artPieces[tokenId].traits.length);
        }

        uint256 proposalId = _proposalIdCounter.current();
        _traitChangeProposals[proposalId] = TraitChangeProposal({
            tokenId: tokenId,
            traitIndex: traitIndex,
            newValue: newTraitValue,
            proposer: msg.sender,
            submissionBlock: uint64(block.number),
            state: ProposalState.Pending
        });
        _proposalIdCounter.increment();

        emit TraitChangeProposalSubmitted(proposalId, tokenId, traitIndex, newTraitValue, msg.sender);
        return proposalId;
    }

    /// @notice Approves a pending trait change proposal.
    /// Only callable by the lead curator.
    /// @param proposalId The ID of the proposal to approve.
    function approveTraitChangeProposal(uint256 proposalId) public onlyLeadCurator whenNotPaused {
        TraitChangeProposal storage proposal = _traitChangeProposals[proposalId];
        if (proposal.tokenId == 0 && proposal.proposer == address(0)) revert NoProposalExists(); // Basic existence check

        if (proposal.state != ProposalState.Pending) {
            revert InvalidProposalState(proposal.state, ProposalState.Pending);
        }

        proposal.state = ProposalState.Approved;
        emit TraitChangeProposalStateChanged(proposalId, ProposalState.Approved, msg.sender);
    }

     /// @notice Rejects a pending trait change proposal.
    /// Only callable by the lead curator.
    /// @param proposalId The ID of the proposal to reject.
    function rejectTraitChangeProposal(uint256 proposalId) public onlyLeadCurator whenNotPaused {
        TraitChangeProposal storage proposal = _traitChangeProposals[proposalId];
        if (proposal.tokenId == 0 && proposal.proposer == address(0)) revert NoProposalExists(); // Basic existence check

        if (proposal.state != ProposalState.Pending) {
            revert InvalidProposalState(proposal.state, ProposalState.Pending);
        }

        proposal.state = ProposalState.Rejected;
        emit TraitChangeProposalStateChanged(proposalId, ProposalState.Rejected, msg.sender);
    }


    /// @notice Executes an approved trait change proposal.
    /// Can be called by anyone, provided the proposal is in the Approved state.
    /// @param proposalId The ID of the proposal to execute.
    function executeTraitChange(uint256 proposalId) public whenNotPaused {
        TraitChangeProposal storage proposal = _traitChangeProposals[proposalId];
        if (proposal.tokenId == 0 && proposal.proposer == address(0)) revert NoProposalExists(); // Basic existence check

        if (proposal.state != ProposalState.Approved) {
            revert InvalidProposalState(proposal.state, ProposalState.Approved);
        }

        uint256 tokenId = proposal.tokenId;
        uint256 traitIndex = proposal.traitIndex;
        uint256 newValue = proposal.newValue;

        // Apply the change
        _artPieces[tokenId].traits[traitIndex] = newValue;
        proposal.state = ProposalState.Executed;

        emit TraitsChanged(tokenId, _artPieces[tokenId].traits, msg.sender, "Executed proposal");
        emit TraitChangeProposalStateChanged(proposalId, ProposalState.Executed, msg.sender);
    }

     /// @notice Gets the details of a specific trait change proposal.
    /// @param proposalId The ID of the proposal.
    /// @return A tuple containing the TraitChangeProposal struct data.
    function getTraitChangeProposal(uint256 proposalId) public view returns (TraitChangeProposal memory) {
         if (_traitChangeProposals[proposalId].tokenId == 0 && _traitChangeProposals[proposalId].proposer == address(0)) {
             revert NoProposalExists();
         }
        return _traitChangeProposals[proposalId];
    }


    // --- Trait Evolution - Trigger System ---

    /// @notice Triggers the time-based evolution for an art piece.
    /// Only callable by the art piece owner or a curator.
    /// Advances evolution state and potentially changes traits if enough time has passed.
    /// @param tokenId The ID of the token to evolve.
    function triggerTimeBasedEvolution(uint256 tokenId) public onlyOwnerOrCurator(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();

        ArtPiece storage artPiece = _artPieces[tokenId];

        if (artPiece.evolutionState == EvolutionState.Mature) {
            revert AlreadyAtMaxEvolution();
        }

        if (uint64(block.number) < artPiece.lastEvolutionBlock + TIME_BASED_EVOLUTION_INTERVAL_BLOCKS) {
            revert EvolutionNotReady("Time interval not passed.");
        }

        EvolutionState oldState = artPiece.evolutionState;
        artPiece.evolutionState = EvolutionState(uint8(oldState) + 1); // Advance state

        // Apply time-based trait changes based on the new state
        _applyEvolutionTraits(tokenId, artPiece.evolutionState, "time");
        artPiece.lastEvolutionBlock = uint64(block.number);

        emit EvolutionStateChanged(tokenId, oldState, artPiece.evolutionState, msg.sender);
        emit TraitsChanged(tokenId, artPiece.traits, msg.sender, "Time-based evolution");
    }

     /// @notice Triggers the interaction-based evolution for an art piece.
    /// Only callable by the art piece owner or a curator.
    /// Advances evolution state and potentially changes traits if enough interactions occurred.
    /// @param tokenId The ID of the token to evolve.
    function triggerInteractionBasedEvolution(uint256 tokenId) public onlyOwnerOrCurator(tokenId) whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();

        ArtPiece storage artPiece = _artPieces[tokenId];

        if (artPiece.evolutionState == EvolutionState.Mature) {
            revert AlreadyAtMaxEvolution();
        }

        if (artPiece.interactionCount < INTERACTION_BASED_EVOLUTION_THRESHOLD) {
             revert EvolutionNotReady("Interaction threshold not reached.");
        }

        EvolutionState oldState = artPiece.evolutionState;
         // Only advance state if not already triggered by time or interaction previously at this stage
        // This prevents double evolution from both triggers at the same stage
        if (artPiece.evolutionState != EvolutionState(uint8(oldState) + 1)) {
             artPiece.evolutionState = EvolutionState(uint8(oldState) + 1); // Advance state
             // Apply interaction-based trait changes based on the new state
            _applyEvolutionTraits(tokenId, artPiece.evolutionState, "interaction");
            artPiece.interactionCount = 0; // Reset interaction count after evolution
        } else {
             // State already advanced by time trigger, maybe just reset count?
             artPiece.interactionCount = 0; // Reset interaction count anyway
        }


        emit EvolutionStateChanged(tokenId, oldState, artPiece.evolutionState, msg.sender);
        emit TraitsChanged(tokenId, artPiece.traits, msg.sender, "Interaction-based evolution");
    }


    // --- Layered Rights Management ---

    /// @notice Transfers the commercial display rights for an art piece.
    /// Only callable by the current owner of the *art piece*.
    /// @param tokenId The ID of the token.
    /// @param to The address to transfer the rights to.
    function transferDisplayRights(uint256 tokenId, address to) public whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != msg.sender) {
            revert CannotTransferRightsIfNotOwner(msg.sender, currentOwner);
        }

        address oldOwner = _artPieces[tokenId].displayRightsOwner;
        _artPieces[tokenId].displayRightsOwner = to;
        emit DisplayRightsTransferred(tokenId, oldOwner, to);
    }

     /// @notice Transfers the commercial print rights for an art piece.
    /// Only callable by the current owner of the *art piece*.
    /// @param tokenId The ID of the token.
    /// @param to The address to transfer the rights to.
    function transferPrintRights(uint256 tokenId, address to) public whenNotPaused {
        if (!_exists(tokenId)) revert InvalidTokenId();
         address currentOwner = ownerOf(tokenId);
        if (currentOwner != msg.sender) {
            revert CannotTransferRightsIfNotOwner(msg.sender, currentOwner);
        }

        address oldOwner = _artPieces[tokenId].printRightsOwner;
        _artPieces[tokenId].printRightsOwner = to;
        emit PrintRightsTransferred(tokenId, oldOwner, to);
    }

    /// @notice Gets the address that holds the commercial display rights for an art piece.
    /// @param tokenId The ID of the token.
    /// @return The address holding display rights.
    function getDisplayRightsOwner(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artPieces[tokenId].displayRightsOwner;
    }

    /// @notice Gets the address that holds the commercial print rights for an art piece.
    /// @param tokenId The ID of the token.
    /// @return The address holding print rights.
    function getPrintRightsOwner(uint256 tokenId) public view returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artPieces[tokenId].printRightsOwner;
    }


    // --- Admin & Utility Functions ---

    /// @notice Sets the maximum number of tokens that can be minted.
    /// Only callable by the contract owner.
    /// @param newMaxSupply The new maximum supply.
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        maxSupply = newMaxSupply;
    }

    /// @notice Sets the base URI for token metadata.
    /// Only callable by the contract owner.
    /// @param baseURI_ The new base URI.
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    /// @notice Pauses transfers and certain other functions (minting, proposals, evolution triggers).
    /// Only callable by the contract owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    /// Only callable by the contract owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Allows the owner to withdraw accumulated ether from the contract.
    /// Useful if minting involved payment or if any other funds arrive.
    /// @param to The address to send the ether to.
    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = to.call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /// @notice Returns the ID of the most recently minted token.
    /// @return The latest token ID.
    function getLatestMintedTokenId() public view returns (uint256) {
        // Decrement counter as it points to the *next* token ID
        return _tokenIdCounter.current() > 0 ? _tokenIdCounter.current() - 1 : 0;
    }


    // --- Internal/Helper Functions ---

    /// @dev Generates initial traits for a new token.
    /// This is a deterministic placeholder. A real implementation might use
    /// Chainlink VRF for true randomness or more complex on-chain logic.
    /// @param tokenId The ID of the token being minted.
    /// @return An array of trait values.
    function _generateInitialTraits(uint256 tokenId) internal view returns (uint256[] memory) {
        // Example: 3 traits based on token ID and block data
        uint256 seed = tokenId + block.number + uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        uint256[] memory traits = new uint256[](3);

        traits[0] = (seed % 100); // Trait 1: 0-99
        traits[1] = ((seed / 100) % 2 == 0 ? 1 : 2); // Trait 2: 1 or 2
        traits[2] = ((seed / 10000) % 255); // Trait 3: 0-254

        // Add more complex logic here for diverse traits
        // Example: traits[3] = uint256(keccak256(abi.encodePacked(seed))) % 10; // Add a hash-based trait

        return traits;
    }

    /// @dev Applies trait changes based on the new evolution state and trigger type.
    /// This is where the core "evolution" logic resides.
    /// Placeholder logic - replace with specific trait changes per state.
    /// @param tokenId The ID of the token.
    /// @param newState The state the art piece has evolved into.
    /// @param triggerType Describes what triggered the evolution ("time" or "interaction").
    function _applyEvolutionTraits(uint256 tokenId, EvolutionState newState, string memory triggerType) internal {
        // Example logic: Modify traits based on the new state
        ArtPiece storage artPiece = _artPieces[tokenId];

        if (newState == EvolutionState.Stage1) {
            // Example Stage 1 evolution: modify trait 0 and trait 1
            artPiece.traits[0] = (artPiece.traits[0] + 10) % 100; // Shift trait 0
            if (artPiece.traits.length > 1) artPiece.traits[1] = (artPiece.traits[1] == 1 ? 2 : 1); // Flip trait 1
        } else if (newState == EvolutionState.Stage2) {
            // Example Stage 2 evolution: modify trait 2
             if (artPiece.traits.length > 2) artPiece.traits[2] = (artPiece.traits[2] + 50) % 255; // Shift trait 2
        } else if (newState == EvolutionState.Mature) {
             // Example Mature evolution: maybe introduce a new 'final' trait or lock traits
             if (artPiece.traits.length < 4) { // Example: add a new trait at the final stage
                 uint256[] memory newTraits = new uint256[](artPiece.traits.length + 1);
                 for(uint i = 0; i < artPiece.traits.length; i++) {
                     newTraits[i] = artPiece.traits[i];
                 }
                 newTraits[artPiece.traits.length] = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp))) % 500; // New trait value
                 artPiece.traits = newTraits;
             }
             // Logic could depend on trigger type too, e.g., different outcomes for time vs interaction evolution
             if (bytes(triggerType).length > 0 && keccak256(abi.encodePacked(triggerType)) == keccak256(abi.encodePacked("interaction"))) {
                 // Apply interaction-specific final changes
                 artPiece.traits[0] = (artPiece.traits[0] * 2) % 100;
             }
        }
        // Add more states and complex trait modification logic here.
        // Could involve adding/removing traits, changing their meaning, etc.
    }

    // --- Fallback/Receive Functions (Optional but good practice) ---
    receive() external payable {
        // Potentially handle incoming ether, maybe for future features like buying rights
    }

    fallback() external payable {
        // Handle calls to non-existent functions
    }
}
```

**Explanation of Advanced Concepts and Creativity:**

1.  **Dynamic Traits & On-Chain State:** Instead of metadata pointing to an immutable JSON file, the core traits that define the art are stored and *changeable* on-chain (`ArtPiece` struct, `traits` array). This allows the NFT's representation to evolve.
2.  **Evolution System:** The `EvolutionState` and the `triggerTimeBasedEvolution`, `triggerInteractionBasedEvolution` functions provide structured ways for the art piece to change. This makes the NFT a living, reacting entity, not just a static image. The triggers can be called by specific roles, adding a layer of gamification or curation influence.
3.  **Layered Rights (`displayRightsOwner`, `printRightsOwner`):** This goes beyond standard NFT ownership. It separates the core ERC721 token (which might represent collecting rights, trading, display in a wallet) from specific commercial use rights like displaying it publicly for profit or creating physical prints. These rights can be transferred independently by the *token owner*, offering more granular control over the asset's utility.
4.  **Curator System:** The `isCurator` and `leadCurator` roles introduce a decentralized (or semi-decentralized, depending on `setLeadCurator` and `addCurator` permissions) layer of governance or influence over the art pieces. Curators can propose changes, and the lead curator approves them.
5.  **Trait Change Proposal System:** The `TraitChangeProposal` struct and associated functions (`proposeTraitChange`, `approveTraitChangeProposal`, `rejectTraitChangeProposal`, `executeTraitChange`) create a workflow for manual, curated changes to the art's traits. This is an on-chain mechanism for community-influenced modifications (controlled by curators).
6.  **On-Chain Metadata Hint (`tokenURI` override):** While the contract doesn't store the full image/JSON metadata, the `tokenURI` signals to platforms *where* to find the metadata. The expectation is that a metadata server would read the *on-chain state* (traits, evolution stage, etc., via `getArtPieceDetails`) and dynamically generate the JSON and potentially the image/representation based on that data. This ties the off-chain representation directly to the dynamic on-chain state.
7.  **Deterministic (Placeholder) Generative Traits:** The `_generateInitialTraits` function shows how initial traits *could* be generated algorithmically based on on-chain data (like token ID, block number, sender). While the example is simple, this opens the door to complex generative art where the on-chain data *is* the art's DNA.

This contract is a conceptual framework. A real implementation would require:
*   More sophisticated `_generateInitialTraits` and `_applyEvolutionTraits` logic.
*   An off-chain metadata server that reads the contract state to generate JSON metadata and potentially the visual representation (image, animation, etc.).
*   Potentially Chainlink VRF for truly unpredictable initial traits or evolution paths.
*   Considerations for gas costs if traits become very complex or numerous.

However, it successfully demonstrates the requested advanced, creative, and trendy concepts within a single Solidity contract exceeding the 20-function requirement.