Okay, let's design a smart contract around a creative concept: **Chronicle Artefacts**. These are NFTs that represent unique digital entities with mutable, evolving traits (`Energy`, `Knowledge`, `Harmony`). Their traits can change based on contributions (e.g., ETH) from owners or shareholders, and also decay over time. These artefacts can be owned by a single address or fractionalized, allowing multiple addresses to own shares and collectively govern the artefact's evolution and actions.

This combines:
1.  **ERC721:** Standard NFT ownership base.
2.  **Dynamic State:** Mutable traits on-chain.
3.  **Contribution Mechanism:** Allowing value transfer (`payable`) to affect state.
4.  **Trait Decay:** Simulating entropy or maintenance needs.
5.  **Fractional Ownership:** Implementing a form of ERC20-like shares *within* the contract state per artefact.
6.  **On-Chain Governance:** A simple voting system for actions on fractionalized artefacts, tied to share ownership.
7.  **Threshold Abilities:** Traits reaching certain levels unlock simulated "abilities" (reflected in metadata).

This avoids duplicating a single common open-source project structure (like a simple ERC20, ERC721, standard DAO, or basic staking contract) by composing several concepts in a novel way around a dynamic asset.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for admin functions, not core ownership

// --- Outline ---
// 1. Contract Information & License
// 2. Imports
// 3. Error Definitions
// 4. Events
// 5. Struct Definitions (Artefact, Proposal)
// 6. Enum Definitions (ProposalState, ArtefactAction)
// 7. State Variables
//    - Token Counter
//    - ERC721 Mappings (Owner, Balances, Approvals)
//    - Artefact Data (Struct)
//    - Fractional Share Data (Mapping of Mappings, Supply)
//    - Proposal Data (Struct, Votes, Counter)
//    - Parameters (Trait decay, boost factors, voting thresholds, admin)
//    - Base URI for Metadata
// 8. Constructor
// 9. ERC165 Support (for ERC721 interfaces)
// 10. ERC721 Standard Implementations
//     - balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, getApproved, setApprovalForAll, isApprovedForAll, tokenURI
// 11. Core Artefact Management
//     - mintArtefact, burnArtefact, getArtefactDetails, getArtefactTraits, getArtefactAbilityStatus, getArtefactState
// 12. Dynamic Trait Logic (Internal)
//     - _checkAndUpdateTraits, _updateArtefactTraits
// 13. Contribution & Resource Management
//     - contributeToArtefact (payable), getArtefactBalance, withdrawArtefactBalance
// 14. Fractionalization Logic
//     - fractionalizeArtefact, defragmentArtefact
// 15. Fractional Share Management (Internal ERC20-like)
//     - getArtefactShareBalance, transferArtefactShares, getArtefactShareSupply, _mintShares, _burnShares
// 16. On-Chain Governance (for Fractionalized Artefacts)
//     - proposeArtefactAction, voteOnProposal, executeProposal, getProposalDetails, getVoteDetails, getArtefactProposals
// 17. Admin/Parameter Functions (Using Ownable)
//     - setBaseURI, setArtefactTraitParameters, setVotingParameters, setDecayInterval
// 18. Utility & Information Functions
//     - supportsInterface

// --- Function Summary ---
// ERC721 Standard:
// 1. balanceOf(address owner): Get number of non-fractionalized artefacts owned by an address.
// 2. ownerOf(uint256 tokenId): Get the owner of a non-fractionalized artefact or the contract address if fractionalized.
// 3. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfer a non-fractionalized artefact.
// 4. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Safely transfer with data.
// 5. transferFrom(address from, address to, uint256 tokenId): Transfer a non-fractionalized artefact.
// 6. approve(address to, uint256 tokenId): Approve an address to transfer a non-fractionalized artefact.
// 7. getApproved(uint256 tokenId): Get the approved address for a non-fractionalized artefact.
// 8. setApprovalForAll(address operator, bool approved): Set operator approval for all non-fractionalized artefacts.
// 9. isApprovedForAll(address owner, address operator): Check operator approval status.
// 10. tokenURI(uint256 tokenId): Get the metadata URI for an artefact, reflecting its current traits/abilities.

// Core Artefact Management:
// 11. mintArtefact(address to, string memory initialMetadataURI): Create a new non-fractionalized artefact. (Admin only initially)
// 12. burnArtefact(uint256 tokenId): Destroy a non-fractionalized artefact. (Owner or approved)
// 13. getArtefactDetails(uint256 tokenId): Get core details (state, owner/contract, shares token).
// 14. getArtefactTraits(uint256 tokenId): Get current dynamic traits (Energy, Knowledge, Harmony) after applying decay.
// 15. getArtefactAbilityStatus(uint256 tokenId): Check which ability thresholds the artefact's traits currently meet.
// 16. getArtefactState(uint256 tokenId): Check if the artefact is non-fractionalized or fractionalized.

// Contribution & Resource Management:
// 17. contributeToArtefact(uint256 tokenId) payable: Contribute native currency (ETH) to an artefact to boost its traits. (Owner or shareholder)
// 18. getArtefactBalance(uint256 tokenId): Get the total native currency balance held by the artefact.
// 19. withdrawArtefactBalance(uint256 tokenId, uint256 amount): Withdraw native currency from an artefact's balance. Requires proposal/vote if fractionalized, owner if not.

// Fractionalization Logic:
// 20. fractionalizeArtefact(uint256 tokenId, uint256 totalShares): Fractionalize a non-fractionalized artefact into specified number of shares. (Owner only)
// 21. defragmentArtefact(uint256 tokenId, address recipient): De-fractionalize an artefact, returning the NFT to a single owner. Requires proposal/vote if fractionalized.

// Fractional Share Management (Internal ERC20-like Interface):
// 22. getArtefactShareBalance(uint256 tokenId, address shareholder): Get the share balance for a specific artefact and address.
// 23. transferArtefactShares(uint256 tokenId, address from, address to, uint256 amount): Transfer shares of a specific artefact. (Shareholder permission - needs approval logic if full ERC20 standard) -> Keeping simple: direct transfer by holder.
// 24. getArtefactShareSupply(uint256 tokenId): Get the total supply of shares for a fractionalized artefact.

// On-Chain Governance (for Fractionalized Artefacts):
// 25. proposeArtefactAction(uint256 tokenId, ArtefactAction actionType, bytes memory details): Propose an action (e.g., Defragment, Withdraw) for a fractionalized artefact. (Shareholder)
// 26. voteOnProposal(uint256 proposalId, bool voteYes): Vote on an open proposal. (Shareholder)
// 27. executeProposal(uint256 proposalId): Attempt to execute a proposal after its voting period ends and threshold is met. (Anyone)
// 28. getProposalDetails(uint256 proposalId): Get information about a specific proposal.
// 29. getVoteDetails(uint256 proposalId, address voter): Check if an address has voted on a proposal.
// 30. getArtefactProposals(uint256 tokenId): Get a list of proposal IDs related to an artefact. (Simplified: returns last few or active ones, or just requires querying logs) -> Let's implement a simple getter for *all* proposal IDs related to an artefact for demonstration.

// Admin/Parameter Functions:
// 31. setBaseURI(string memory baseURI_): Set the base URI for token metadata. (Owner)
// 32. setArtefactTraitParameters(uint256 traitBoostPerEthUnit_, uint256 baseDecayRate_): Set parameters for trait evolution. (Owner)
// 33. setVotingParameters(uint256 proposalDuration_, uint256 minSharesToPropose_, uint256 voteMajorityThreshold_): Set parameters for governance. (Owner)
// 34. setDecayInterval(uint256 decayInterval_): Set the time interval for applying decay. (Owner)

// Utility & Information Functions:
// 35. supportsInterface(bytes4 interfaceId): Standard ERC165 interface check.

contract ChronicleArtefacts is ERC165, IERC721, IERC721Metadata {
    using Counters for Counters.Counter;

    // --- Errors ---
    error InvalidTokenId();
    error NotArtefactOwner();
    error NotApprovedOrOwner();
    error ArtefactIsFractionalized();
    error ArtefactNotFractionalized();
    error InvalidShareAmount();
    error InsufficientShares();
    error ZeroAddress();
    error InvalidRecipient();
    error ProposalNotFound();
    error VotingPeriodNotEnded();
    error ProposalAlreadyExecutedOrCanceled();
    error ProposalStillActive();
    error InsufficientVotes();
    error AlreadyVoted();
    error CannotVoteWithZeroShares();
    error ProposalActionFailed();
    error WithdrawalAmountExceedsBalance();
    error DefragmentRecipientCannotBeZero();
    error ActionNotExecutableInState();

    // --- Events ---
    event ArtefactMinted(uint256 indexed tokenId, address indexed owner, string initialMetadataURI);
    event ArtefactBurned(uint256 indexed tokenId);
    event ArtefactTransferred(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event ArtefactFractionalized(uint256 indexed tokenId, address indexed originalOwner, uint256 totalSharesMinted, address sharesTokenRepresentation); // sharesTokenRepresentation is conceptual here
    event ArtefactDefragmented(uint256 indexed tokenId, address indexed newOwner);
    event SharesTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event ContributionReceived(uint256 indexed tokenId, address indexed contributor, uint256 amount, uint256 energyBoost, uint256 knowledgeBoost, uint256 harmonyBoost);
    event ArtefactBalanceWithdrawn(uint256 indexed tokenId, address indexed recipient, uint256 amount, address indexed initiator);
    event TraitsUpdated(uint256 indexed tokenId, uint256 energy, uint256 knowledge, uint256 harmony);
    event ProposalCreated(uint256 indexed proposalId, uint256 indexed artefactId, ArtefactAction indexed actionType, address indexed proposer, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ParametersUpdated(string paramType);

    // --- Structs ---
    struct Artefact {
        // ERC721 state when NOT fractionalized. If fractionalized, owner is address(this)
        address owner; // ERC721 owner or contract address if fractionalized
        bool isFractionalized;
        // uint256 sharesTokenAddress; // Conceptual identifier for the unique share token for this artefact

        // Dynamic Traits
        uint256 energy;
        uint256 knowledge;
        uint256 harmony;
        uint256 lastTraitUpdate;

        // Resources held by the Artefact
        uint256 ethBalance;

        string metadataURI;
        // Add other immutable properties if needed, e.g., creation block, initial traits
    }

    struct Proposal {
        uint256 artefactId;
        ArtefactAction actionType; // What is being proposed
        address proposer; // Address who created the proposal
        uint256 creationTime;
        uint256 endTime; // When voting ends
        uint256 yesVotes; // Total shares voting Yes
        uint256 noVotes; // Total shares voting No
        ProposalState state; // Current state of the proposal
        bytes details; // Optional data related to the proposal (e.g., recipient address, amount)
    }

    // --- Enums ---
    enum ProposalState { Pending, Active, Canceled, Succeeded, Failed, Executed }
    enum ArtefactAction { None, Defragment, WithdrawEth, UpdateMetadata } // Possible actions to propose

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;

    // ERC721 Mappings (only relevant when Artefact is NOT fractionalized)
    mapping(uint256 => address) private _tokenApprovals; // tokenId => approvedAddress
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved
    mapping(address => uint256) private _balances; // owner => number of non-fractionalized tokens

    // Artefact Data
    mapping(uint256 => Artefact) private _artefacts;

    // Fractional Share Data (Conceptual ERC20 per Artefact)
    mapping(uint256 => mapping(address => uint256)) private _artefactShares; // tokenId => shareholder => balance
    mapping(uint256 => uint256) private _artefactShareSupply; // tokenId => total supply of shares

    // Proposal Data
    mapping(uint256 => Proposal) private _proposals;
    mapping(uint256 => mapping(address => bool)) private _proposalVotes; // proposalId => voter => hasVoted
    mapping(uint256 => uint256[]) private _artefactProposalsList; // tokenId => list of proposalIds

    // Parameters (Admin settable)
    uint256 public traitBoostPerEthUnit = 10; // How many trait points (total) per ETH unit contributed
    uint256 public baseDecayRate = 1; // How many trait points (per trait) decay per interval
    uint256 public decayInterval = 1 days; // How often decay is applied (in seconds)
    string private _baseTokenURI;

    // Voting Parameters
    uint256 public proposalDuration = 3 days; // How long voting is open (in seconds)
    uint256 public minSharesToPropose = 1; // Minimum shares required to create a proposal
    uint256 public voteMajorityThreshold = 51; // % required of total circulating supply of shares for Yes votes (out of 100)

    // Admin control (Using Ownable)
    address private _owner; // Admin address from Ownable

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC165() {
        // We are not inheriting from ERC721 directly to customize ownership logic,
        // but we implement its interface and ERC165.
        // ERC165 identifier for IERC721 and IERC721Metadata
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);

        // Initialize Ownable-like admin
        _owner = msg.sender; // The deployer is the initial admin
        emit OwnershipTransferred(address(0), _owner);
    }

    // --- Internal ERC721 Helpers (Adapted) ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        // An artefact exists if it has been minted (has an entry in _artefacts)
        // and hasn't been burned. _tokenIdCounter tracks the next ID, so any ID
        // less than the current counter value potentially exists.
        // A more robust check could involve a boolean mapping `_existsStatus`.
        // For this implementation, we assume a non-zero `lastTraitUpdate` or
        // `owner` value indicates existence after minting. Let's use the Artefact struct presence.
        return _artefacts[tokenId].lastTraitUpdate != 0 || _artefacts[tokenId].owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address tokenOwner = ownerOf(tokenId);
        // Note: ownerOf returns address(this) if fractionalized.
        // This check is only relevant for NON-FRACTIONALIZED tokens.
        if (_artefacts[tokenId].isFractionalized) {
             // If fractionalized, standard ERC721 approvals are irrelevant for control.
             // Control is via shareholder voting or internal logic.
             // So, nobody is "approved" in the ERC721 sense.
            return false;
        }
        return (spender == tokenOwner ||
                spender == _tokenApprovals[tokenId] ||
                _operatorApprovals[tokenOwner][spender]);
    }

    // Custom transfer logic handling fractionalization state
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (_artefacts[tokenId].isFractionalized) revert ArtefactIsFractionalized();
        if (ownerOf(tokenId) != from) revert NotArtefactOwner();
        if (to == address(0)) revert InvalidRecipient();

        // Standard ERC721 transfer updates
        _balances[from]--;
        _balances[to]++;
        _artefacts[tokenId].owner = to; // Update owner in our struct
        delete _tokenApprovals[tokenId]; // Clear approvals on transfer

        emit ArtefactTransferred(from, to, tokenId);
    }

    function _mint(address to, string memory initialMetadataURI) internal returns (uint256 tokenId) {
         if (to == address(0)) revert ZeroAddress();

        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();

        // Initialize Artefact state
        _artefacts[tokenId].owner = to;
        _artefacts[tokenId].isFractionalized = false;
        _artefacts[tokenId].energy = 1; // Starting traits
        _artefacts[tokenId].knowledge = 1;
        _artefacts[tokenId].harmony = 1;
        _artefacts[tokenId].lastTraitUpdate = block.timestamp; // Record creation time for decay
        _artefacts[tokenId].ethBalance = 0;
        _artefacts[tokenId].metadataURI = initialMetadataURI;

        // Update ERC721 balances
        _balances[to]++;

        emit ArtefactMinted(tokenId, to, initialMetadataURI);
    }

    function _burn(uint256 tokenId) internal {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (_artefacts[tokenId].isFractionalized) revert ArtefactIsFractionalized(); // Cannot burn fractionalized

        address tokenOwner = ownerOf(tokenId);

        // Clear ERC721 state
        _balances[tokenOwner]--;
        delete _artefacts[tokenId].owner;
        delete _tokenApprovals[tokenId];

        // Completely remove Artefact data
        delete _artefacts[tokenId]; // This frees up storage for the ID

        emit ArtefactBurned(tokenId);
    }

    // --- ERC721 Standard Implementations ---

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        // Only count non-fractionalized tokens owned by this address
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        // Return contract address if fractionalized, otherwise the actual owner
        return _artefacts[tokenId].isFractionalized ? address(this) : _artefacts[tokenId].owner;
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         if (!_exists(tokenId)) revert InvalidTokenId(); // Added existence check
         // Require ownership or approval for non-fractionalized tokens
         if (_artefacts[tokenId].isFractionalized || from != ownerOf(tokenId) || !_isApprovedOrOwner(msg.sender, tokenId)) {
             revert NotApprovedOrOwner();
         }
         if (to == address(0)) revert InvalidRecipient();

        _transfer(from, to, tokenId);

        // ERC721Receiver hook
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert InvalidRecipient(); // Indicates contract refusal
            } catch Error(string memory reason) {
                revert(reason); // Revert with the reason from the receiver
            } catch {
                revert InvalidRecipient(); // Revert on any other error from the receiver
            }
        }
    }

     /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) public override {
         if (!_exists(tokenId)) revert InvalidTokenId(); // Added existence check
         // Require ownership or approval for non-fractionalized tokens
         if (_artefacts[tokenId].isFractionalized || from != ownerOf(tokenId) || !_isApprovedOrOwner(msg.sender, tokenId)) {
             revert NotApprovedOrOwner();
         }
         if (to == address(0)) revert InvalidRecipient();

        _transfer(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) public override {
        if (!_exists(tokenId)) revert InvalidTokenId(); // Added existence check
        address tokenOwner = ownerOf(tokenId);
        if (_artefacts[tokenId].isFractionalized || tokenOwner != msg.sender && !_operatorApprovals[tokenOwner][msg.sender]) {
            // Cannot approve fractionalized tokens via ERC721
            // Must be owner or approved operator for non-fractionalized
             revert NotArtefactOwner(); // Reusing error, could be more specific
        }
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert InvalidTokenId(); // Added existence check
        if (_artefacts[tokenId].isFractionalized) return address(0); // No ERC721 approval if fractionalized
        return _tokenApprovals[tokenId];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public override {
         // This applies only to non-fractionalized tokens owned by msg.sender
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
         // This checks approval for non-fractionalized tokens owned by owner
        return _operatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         // Incorporate traits into URI if needed, or just use the stored URI
         // For simplicity, returning the base URI + token ID or the stored URI
         // A more advanced version would fetch traits and construct a dynamic URI
         string memory currentURI = _artefacts[tokenId].metadataURI;
         if(bytes(currentURI).length > 0) {
             return currentURI;
         }
         // Fallback or default URI construction
         return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

     /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // --- Core Artefact Management ---

    /// @notice Mints a new Artefact, initially not fractionalized.
    /// Can only be called by the contract owner (admin).
    function mintArtefact(address to, string memory initialMetadataURI) public onlyOwner returns (uint256) {
        return _mint(to, initialMetadataURI);
    }

    /// @notice Burns an Artefact.
    /// Can only burn non-fractionalized Artefacts.
    /// Requires owner or approved address.
    function burnArtefact(uint256 tokenId) public {
        if (!_exists(tokenId)) revert InvalidTokenId();
        address tokenOwner = ownerOf(tokenId); // Gets contract address if fractionalized
        if (_artefacts[tokenId].isFractionalized) revert ArtefactIsFractionalized();
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotApprovedOrOwner();

        // Send any ETH held by the Artefact back to the owner before burning
        if (_artefacts[tokenId].ethBalance > 0) {
            (bool success, ) = payable(tokenOwner).call{value: _artefacts[tokenId].ethBalance}("");
            if (!success) {
                // This is a potentially bad state - funds are locked.
                // In a real contract, consider escrow or emergency withdrawal.
                // For this example, we just revert.
                revert("Failed to return artefact ETH balance before burning");
            }
            _artefacts[tokenId].ethBalance = 0;
        }

        _burn(tokenId);
    }

    /// @notice Gets basic details about an Artefact.
    function getArtefactDetails(uint256 tokenId) public view returns (Artefact memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artefacts[tokenId];
    }

    /// @notice Gets the current traits of an Artefact after applying any pending decay.
    function getArtefactTraits(uint256 tokenId) public returns (uint256 energy, uint256 knowledge, uint256 harmony) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        _checkAndUpdateTraits(tokenId); // Apply decay before returning
        Artefact storage artefact = _artefacts[tokenId];
        return (artefact.energy, artefact.knowledge, artefact.harmony);
    }

    /// @notice Checks which ability thresholds an Artefact meets based on its traits.
    /// This is a simplified example; abilities would typically have defined trait requirements.
    /// Traits are updated before checking abilities.
    function getArtefactAbilityStatus(uint256 tokenId) public returns (bool hasBasic, bool hasAdvanced, bool hasExpert) {
        if (!_exists(tokenId)) revert InvalidTokenId();
         _checkAndUpdateTraits(tokenId); // Apply decay before checking

        Artefact storage artefact = _artefacts[tokenId];
        uint256 totalTraits = artefact.energy + artefact.knowledge + artefact.harmony;

        // Example thresholds
        hasBasic = totalTraits >= 10;
        hasAdvanced = artefact.energy >= 15 && artefact.knowledge >= 15 && artefact.harmony >= 15; // Requires balance
        hasExpert = totalTraits >= 100 && artefact.energy > 30 && artefact.knowledge > 30 && artefact.harmony > 30; // High total + minimums

        return (hasBasic, hasAdvanced, hasExpert);
    }

    /// @notice Checks if an Artefact is fractionalized or non-fractionalized.
    function getArtefactState(uint256 tokenId) public view returns (bool isFractionalized_) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artefacts[tokenId].isFractionalized;
    }

    // --- Dynamic Trait Logic (Internal) ---

    /// @dev Applies trait decay based on the time elapsed since the last update.
    /// Called by functions that interact with traits or fetch them.
    function _checkAndUpdateTraits(uint256 tokenId) internal {
        Artefact storage artefact = _artefacts[tokenId];
        uint256 elapsedTime = block.timestamp - artefact.lastTraitUpdate;
        if (elapsedTime == 0 || decayInterval == 0 || baseDecayRate == 0) {
            // No time elapsed, no decay interval set, or decay rate is zero
            return;
        }

        uint256 decayCycles = elapsedTime / decayInterval;
        if (decayCycles > 0) {
             uint256 totalDecay = decayCycles * baseDecayRate;

            // Apply decay, traits cannot go below 1
            artefact.energy = artefact.energy > totalDecay ? artefact.energy - totalDecay : 1;
            artefact.knowledge = artefact.knowledge > totalDecay ? artefact.knowledge - totalDecay : 1;
            artefact.harmony = artefact.harmony > totalDecay ? artefact.harmony - totalDecay : 1;

            artefact.lastTraitUpdate = artefact.lastTraitUpdate + (decayCycles * decayInterval); // Update timestamp based on full cycles

            emit TraitsUpdated(tokenId, artefact.energy, artefact.knowledge, artefact.harmony);
        }
    }

     /// @dev Internal helper to apply trait updates (boosts or direct modifications).
    function _updateArtefactTraits(uint256 tokenId, uint256 energyDelta, uint256 knowledgeDelta, uint256 harmonyDelta) internal {
        Artefact storage artefact = _artefacts[tokenId];
         // Ensure traits don't go below 1, even with negative deltas (if allowed)
        artefact.energy = energyDelta > 0 ? artefact.energy + energyDelta : (artefact.energy > -energyDelta ? artefact.energy + energyDelta : 1);
        artefact.knowledge = knowledgeDelta > 0 ? artefact.knowledge + knowledgeDelta : (artefact.knowledge > -knowledgeDelta ? artefact.knowledge + knowledgeDelta : 1);
        artefact.harmony = harmonyDelta > 0 ? artefact.harmony + harmonyDelta : (artefact.harmony > -harmonyDelta ? artefact.harmony + harmonyDelta : 1);

        emit TraitsUpdated(tokenId, artefact.energy, artefact.knowledge, artefact.harmony);
    }


    // --- Contribution & Resource Management ---

    /// @notice Allows anyone to contribute native currency (ETH) to an Artefact, boosting its traits.
    /// Trait boost is distributed evenly among Energy, Knowledge, Harmony based on `traitBoostPerEthUnit`.
    function contributeToArtefact(uint256 tokenId) public payable {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (msg.value == 0) return;

        // Apply any pending decay first
        _checkAndUpdateTraits(tokenId);

        // Add contribution to artefact balance
        _artefacts[tokenId].ethBalance += msg.value;

        // Calculate trait boost
        uint256 totalBoost = (msg.value * traitBoostPerEthUnit) / (1 ether); // Boost per ETH
        uint256 energyBoost = totalBoost / 3;
        uint256 knowledgeBoost = totalBoost / 3;
        uint256 harmonyBoost = totalBoost - energyBoost - knowledgeBoost; // Distribute remainder

        // Update traits
        _updateArtefactTraits(tokenId, energyBoost, knowledgeBoost, harmonyBoost);

        emit ContributionReceived(tokenId, msg.sender, msg.value, energyBoost, knowledgeBoost, harmonyBoost);
    }

    /// @notice Gets the total native currency balance held by an Artefact.
    function getArtefactBalance(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return _artefacts[tokenId].ethBalance;
    }

    /// @notice Withdraws native currency from an Artefact's balance.
    /// Requires owner permission if non-fractionalized.
    /// Requires a successful 'WithdrawEth' proposal if fractionalized.
    /// @param proposalId Relevant proposal ID if withdrawing from fractionalized Artefact. Ignored if non-fractionalized.
    function withdrawArtefactBalance(uint256 tokenId, uint256 amount, uint256 proposalId) public {
        if (!_exists(tokenId)) revert InvalidTokenId();
        Artefact storage artefact = _artefacts[tokenId];
        if (amount == 0) return;
        if (artefact.ethBalance < amount) revert WithdrawalAmountExceedsBalance();

        address recipient;
        if (artefact.isFractionalized) {
            // Must use a proposal if fractionalized
            Proposal storage proposal = _proposals[proposalId];
            if (proposal.state != ProposalState.Executed || proposal.artefactId != tokenId || proposal.actionType != ArtefactAction.WithdrawEth) {
                revert ActionNotExecutableInState(); // Proposal must be executed and match action/artefact
            }
            // Recipient should be specified in proposal details (bytes). Decode it.
            // Assuming details is abi.encode(address recipientAddress)
            if (proposal.details.length != 32) revert ("Invalid proposal details format for withdrawal");
            (recipient) = abi.decode(proposal.details, (address));
            if (recipient == address(0)) revert InvalidRecipient(); // Recipient must be valid

        } else {
            // If not fractionalized, only the owner can withdraw
            if (msg.sender != artefact.owner) revert NotArtefactOwner();
            recipient = msg.sender; // Owner is the recipient
        }

        artefact.ethBalance -= amount;
        (bool success, ) = payable(recipient).call{value: amount}("");
        if (!success) {
            // If transfer fails, attempt to revert balance update.
            // In production, consider a pull pattern or emergency functions.
            artefact.ethBalance += amount; // Put the balance back
            revert("ETH withdrawal failed");
        }

        emit ArtefactBalanceWithdrawn(tokenId, recipient, amount, msg.sender);
    }


    // --- Fractionalization Logic ---

    /// @notice Fractionalizes a non-fractionalized Artefact into a specified total supply of shares.
    /// Transfers the NFT to the contract address and mints shares to the original owner.
    function fractionalizeArtefact(uint256 tokenId, uint256 totalShares) public {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (_artefacts[tokenId].isFractionalized) revert ArtefactIsFractionalized();
        if (totalShares == 0) revert InvalidShareAmount();

        address currentOwner = ownerOf(tokenId); // Get current owner before transfer
        if (currentOwner != msg.sender) revert NotArtefactOwner();

        // Transfer the NFT to this contract
        _transfer(currentOwner, address(this), tokenId); // Use our custom transfer
        _artefacts[tokenId].isFractionalized = true;
        // _artefacts[tokenId].sharesTokenAddress = tokenId; // Conceptual identifier

        // Mint shares to the original owner (using our internal shares logic)
        _mintShares(tokenId, currentOwner, totalShares);
        _artefactShareSupply[tokenId] = totalShares; // Set total supply

        emit ArtefactFractionalized(tokenId, currentOwner, totalShares, address(uint160(tokenId))); // Using tokenId as conceptual address
    }

    /// @notice De-fractionalizes an Artefact, returning the NFT to a single owner.
    /// Requires a successful 'Defragment' proposal if fractionalized.
    /// @param proposalId Relevant proposal ID if defragmenting a fractionalized Artefact. Ignored if non-fractionalized.
    /// @param recipient The address to receive the NFT. Required if fractionalized via proposal.
    function defragmentArtefact(uint256 tokenId, uint256 proposalId, address recipient) public {
         if (!_exists(tokenId)) revert InvalidTokenId();
         Artefact storage artefact = _artefacts[tokenId];

         if (artefact.isFractionalized) {
             // Must use a proposal if fractionalized
            Proposal storage proposal = _proposals[proposalId];
             if (proposal.state != ProposalState.Executed || proposal.artefactId != tokenId || proposal.actionType != ArtefactAction.Defragment) {
                revert ActionNotExecutableInState(); // Proposal must be executed and match action/artefact
             }
            if (recipient == address(0)) revert DefragmentRecipientCannotBeZero();

             // Check that all shares have been burned (e.g., sent to a burn address before execution)
             // A more complex flow would handle share collection/burning here.
             // For this example, we assume shares are managed externally or burned pre-execution.
             // Let's add a simple check: ensure supply is effectively zero or negligible.
            if (_artefactShareSupply[tokenId] > 0) {
                 // A proper defragmentation needs a mechanism to consolidate or burn shares first.
                 // Reverting here to indicate this simplified flow requires pre-burning.
                 revert("Shares must be consolidated or burned before defragmentation execution");
            }

             // Transfer the NFT from this contract to the recipient
             _transfer(address(this), recipient, tokenId);
             artefact.owner = recipient; // Update owner in struct
             artefact.isFractionalized = false;
             // delete artefact.sharesTokenAddress; // Conceptual

            emit ArtefactDefragmented(tokenId, recipient);

         } else {
            // If not fractionalized, direct call is an error, but let's handle defensively.
            // Defragmenting a non-fractionalized token is a no-op or invalid state.
            // Reverting is safest.
            revert ArtefactNotFractionalized();
         }
    }

    // --- Fractional Share Management (Internal ERC20-like Interface) ---

    /// @notice Gets the share balance for a specific Artefact and shareholder.
    function getArtefactShareBalance(uint256 tokenId, address shareholder) public view returns (uint256) {
         if (!_exists(tokenId)) revert InvalidTokenId(); // Check Artefact exists
         if (!(_artefacts[tokenId].isFractionalized)) return 0; // No shares if not fractionalized
         if (shareholder == address(0)) revert ZeroAddress();
        return _artefactShares[tokenId][shareholder];
    }

    /// @notice Transfers shares of a specific fractionalized Artefact.
    /// Requires `msg.sender` to be the `from` address and have sufficient shares.
    function transferArtefactShares(uint256 tokenId, address from, address to, uint256 amount) public {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (!_artefacts[tokenId].isFractionalized) revert ArtefactNotFractionalized();
        if (msg.sender != from) revert NotArtefactOwner(); // Simplified: requires sender == from
        if (to == address(0)) revert InvalidRecipient();
        if (_artefactShares[tokenId][from] < amount) revert InsufficientShares();

        // No approvals logic implemented for these internal shares for simplicity

        unchecked {
            _artefactShares[tokenId][from] -= amount;
            _artefactShares[tokenId][to] += amount;
        }

        emit SharesTransferred(tokenId, from, to, amount);
    }

    /// @notice Gets the total supply of shares for a fractionalized Artefact.
    function getArtefactShareSupply(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (!_artefacts[tokenId].isFractionalized) return 0; // No supply if not fractionalized
        return _artefactShareSupply[tokenId];
    }

    /// @dev Mints shares for a specific Artefact and shareholder.
    function _mintShares(uint256 tokenId, address to, uint256 amount) internal {
        // Assumes Artefact is already marked as fractionalized before this call
        if (to == address(0)) revert ZeroAddress();
        // No supply cap enforcement here other than the initial totalShares set during fractionalization

        unchecked {
             _artefactShares[tokenId][to] += amount;
             // _artefactShareSupply[tokenId] += amount; // Supply is set once during fractionalize
        }
         // No event here, as SharesTransferred implicitly covers minting from address(0) if needed,
         // but fractionalize handles initial distribution and supply setting.
    }

    /// @dev Burns shares for a specific Artefact and shareholder.
    function _burnShares(uint256 tokenId, address from, uint256 amount) internal {
         if (_artefactShares[tokenId][from] < amount) revert InsufficientShares();
        // Cannot burn more than total supply, but enforced by balance check

        unchecked {
            _artefactShares[tokenId][from] -= amount;
             // _artefactShareSupply[tokenId] -= amount; // Supply is only affected by defragmentation (conceptually burning all)
        }
         // No event here, as SharesTransferred implicitly covers burning to address(0) if needed.
    }

    // --- On-Chain Governance (for Fractionalized Artefacts) ---

    /// @notice Creates a proposal for a fractionalized Artefact.
    /// Requires minimum shares to propose.
    function proposeArtefactAction(uint256 tokenId, ArtefactAction actionType, bytes memory details) public returns (uint256 proposalId) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        if (!_artefacts[tokenId].isFractionalized) revert ArtefactNotFractionalized();

        // Check minimum shares to propose
        if (_artefactShares[tokenId][msg.sender] < minSharesToPropose) revert InsufficientShares();

        // Apply decay before potentially making decisions based on artefact state
        _checkAndUpdateTraits(tokenId);

        _proposalIdCounter.increment();
        proposalId = _proposalIdCounter.current();

        Proposal storage proposal = _proposals[proposalId];
        proposal.artefactId = tokenId;
        proposal.actionType = actionType;
        proposal.proposer = msg.sender;
        proposal.creationTime = block.timestamp;
        proposal.endTime = block.timestamp + proposalDuration;
        proposal.state = ProposalState.Active;
        proposal.details = details; // Store any relevant details

        // Add to the list of proposals for this artefact (simplified storage)
        _artefactProposalsList[tokenId].push(proposalId);

        emit ProposalCreated(proposalId, tokenId, actionType, msg.sender, proposal.endTime);
        return proposalId;
    }

    /// @notice Allows a shareholder to vote on an active proposal.
    /// Voting weight is based on the shareholder's current share balance at the time of voting.
    function voteOnProposal(uint256 proposalId, bool voteYes) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalStillActive();
        if (block.timestamp >= proposal.endTime) revert VotingPeriodNotEnded();
        if (_proposalVotes[proposalId][msg.sender]) revert AlreadyVoted();

        uint256 shareholderShares = _artefactShares[proposal.artefactId][msg.sender];
        if (shareholderShares == 0) revert CannotVoteWithZeroShares();

        _proposalVotes[proposalId][msg.sender] = true;

        if (voteYes) {
            proposal.yesVotes += shareholderShares;
        } else {
            proposal.noVotes += shareholderShares;
        }

        emit Voted(proposalId, msg.sender, voteYes, shareholderShares);
    }

    /// @notice Attempts to execute a proposal whose voting period has ended and met the approval threshold.
    /// Can be called by anyone.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalAlreadyExecutedOrCanceled();
        if (block.timestamp < proposal.endTime) revert ProposalStillActive();

        // Calculate total votes cast (only by voters with > 0 shares)
        // Note: This is a simplified voting system. A more robust one might use snapshots.
        // Here, we check against the total current share supply of the Artefact.
        uint256 totalShares = _artefactShareSupply[proposal.artefactId];
        uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;

        // Check if majority threshold is met among the *total possible* shares
        // (yesVotes / totalShares) * 100 >= voteMajorityThreshold
        // Equivalent to yesVotes * 100 >= totalShares * voteMajorityThreshold
        bool success = false;
        if (totalShares > 0 && proposal.yesVotes * 100 >= totalShares * voteMajorityThreshold) {
            // Majority threshold met
            proposal.state = ProposalState.Succeeded;
            // Execute the proposed action
            try this.executeArtefactAction(proposalId) {
                 proposal.state = ProposalState.Executed;
                 success = true;
            } catch {
                // Execution failed, but proposal state is still Succeeded if votes passed
                // A dedicated state like `ExecutionFailed` could be used.
                // For simplicity, we just mark success as false.
                success = false;
            }

        } else {
            proposal.state = ProposalState.Failed;
        }

        emit ProposalExecuted(proposalId, success);
        if (!success && proposal.state == ProposalState.Succeeded) revert ProposalActionFailed();
    }

    /// @dev Internal function to perform the actual Artefact action based on proposal type.
    /// Called by `executeProposal`. Must be `external` for the `try/catch` in `executeProposal`.
    function executeArtefactAction(uint256 proposalId) external {
         // Ensure only executeProposal can call this
         // This requires a specific check or design pattern if executeProposal is external.
         // A common pattern is to use a boolean flag or check msg.sender == address(this) if executeProposal were internal.
         // Given executeProposal is public, this is a simplification.
         // A robust system might require a trusted executor or re-structure.
         // For demonstration, we allow it as a separate call after state transition.
         // The state check in executeProposal handles the main gate.

        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Succeeded) revert ActionNotExecutableInState();

        // Decode proposal details based on action type
        if (proposal.actionType == ArtefactAction.Defragment) {
             // Details should contain the recipient address
            if (proposal.details.length != 32) revert ("Invalid proposal details for defragmentation");
            (address recipient) = abi.decode(proposal.details, (address));
            defragmentArtefact(proposal.artefactId, proposalId, recipient);

        } else if (proposal.actionType == ArtefactAction.WithdrawEth) {
             // Details should contain recipient and amount
            if (proposal.details.length != 64) revert ("Invalid proposal details for withdrawal");
             (address recipient, uint256 amount) = abi.decode(proposal.details, (address, uint256));
            withdrawArtefactBalance(proposal.artefactId, amount, proposalId); // Pass proposalId for validation

        } else if (proposal.actionType == ArtefactAction.UpdateMetadata) {
            // Details should contain the new metadata URI
             if (proposal.details.length < 32) revert ("Invalid proposal details for metadata update");
             (string memory newURI) = abi.decode(proposal.details, (string));
             _artefacts[proposal.artefactId].metadataURI = newURI; // Update metadata directly
        } else {
            revert("Unknown proposal action type");
        }

        // Mark as executed *after* successful action
        // proposal.state = ProposalState.Executed; // This was moved into executeProposal try/catch
    }


    /// @notice Gets details of a specific proposal.
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        if (_proposals[proposalId].creationTime == 0) revert ProposalNotFound(); // Check existence
        return _proposals[proposalId];
    }

     /// @notice Checks if a voter has voted on a specific proposal.
    function getVoteDetails(uint256 proposalId, address voter) public view returns (bool hasVoted) {
         if (_proposals[proposalId].creationTime == 0) revert ProposalNotFound(); // Check existence
         return _proposalVotes[proposalId][voter];
    }

    /// @notice Gets the list of proposal IDs associated with an Artefact.
    /// Note: This can grow large. In production, consider pagination or event querying.
    function getArtefactProposals(uint256 tokenId) public view returns (uint256[] memory) {
         if (!_exists(tokenId)) revert InvalidTokenId();
         return _artefactProposalsList[tokenId];
    }


    // --- Admin/Parameter Functions (using Ownable) ---
    // Basic Ownable implementation directly here
    address private _contractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != _contractOwner) revert OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    function owner() public view returns (address) {
        return _contractOwner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert OwnableInvalidOwner(address(0));
        address oldOwner = _contractOwner;
        _contractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // Admin functions start here

    /// @notice Sets the base URI for generating token metadata URIs (as a fallback).
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
        emit ParametersUpdated("BaseURI");
    }

     /// @notice Sets parameters related to Artefact trait evolution (boost and decay).
    function setArtefactTraitParameters(uint256 traitBoostPerEthUnit_, uint256 baseDecayRate_) public onlyOwner {
        traitBoostPerEthUnit = traitBoostPerEthUnit_;
        baseDecayRate = baseDecayRate_;
         emit ParametersUpdated("TraitParameters");
    }

    /// @notice Sets parameters for the on-chain voting system.
    function setVotingParameters(uint256 proposalDuration_, uint256 minSharesToPropose_, uint256 voteMajorityThreshold_) public onlyOwner {
        if (voteMajorityThreshold_ > 100) revert("Majority threshold cannot exceed 100%");
        proposalDuration = proposalDuration_;
        minSharesToPropose = minSharesToPropose_;
        voteMajorityThreshold = voteMajorityThreshold_;
         emit ParametersUpdated("VotingParameters");
    }

     /// @notice Sets the time interval at which trait decay is calculated and applied.
    function setDecayInterval(uint256 decayInterval_) public onlyOwner {
        decayInterval = decayInterval_;
         emit ParametersUpdated("DecayInterval");
    }

    // Receive ETH to allow contract to hold funds for artefacts, although contributions go directly to artefact balance
    receive() external payable {}
    fallback() external payable {}
}
```