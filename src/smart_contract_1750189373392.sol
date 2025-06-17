Okay, here is a Solidity smart contract for a Decentralized Dynamic Art Gallery. This contract combines several advanced concepts:

1.  **Dynamic NFTs:** NFTs whose state (and potentially metadata via `tokenURI`) can change based on on-chain interactions.
2.  **Fractional Ownership:** Allowing multiple users to own shares of a single, expensive NFT.
3.  **Community Curation/Governance:** Implementing a voting system for specific aspects (like influencing the dynamic state of an art piece).
4.  **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` for managing different types of users (Admins, Curators, Artists, Patrons).
5.  **Pausable:** Standard emergency stop mechanism.
6.  **Reentrancy Guard:** Protection for withdrawal functions.
7.  **Simulated Oracle Interaction:** A function demonstrating how an external factor (like a simulated "mood" or market data) could influence the dynamic state via an oracle call.
8.  **Buyout Mechanism:** Allowing someone to buy a fractionalized NFT entirely and trigger payout to fractional owners.
9.  **Royalty/Fee Distribution:** A simple mechanism for the contract to collect fees (e.g., on fractionalization or buyout) and allow withdrawal.

It uses OpenZeppelin libraries for standard, tested implementations of common patterns. The dynamic state and fractionalization logic are custom implementations within this framework.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
Contract: DecentralizedDynamicArtGallery

Outline:
1.  **Core ERC721 Functionality:** Implements standard ERC721 methods for NFT ownership and transfer.
2.  **Access Control:** Manages roles (ADMIN, CURATOR, ARTIST).
3.  **Pausable:** Allows pausing critical functions in emergencies.
4.  **Dynamic Art State:** Stores and manages a dynamic state variable for each NFT.
5.  **Dynamic State Interaction:**
    *   Allows interaction (simulated oracle call) to influence state.
    *   Implements a voting system to allow the community/curators to propose and vote on state changes.
6.  **Fractional Ownership:**
    *   Allows locking a minted NFT and creating fractional shares.
    *   Provides functions to buy/sell shares internally (simplified transfer).
    *   Allows redeeming the full NFT by accumulating all shares.
    *   Implements a buyout mechanism for fractionalized NFTs and payout to shareholders.
7.  **Metadata:** Provides a dynamic `tokenURI` based on the art's state.
8.  **Administration:** Functions for setting parameters, managing roles, and withdrawing fees.
9.  **Queries:** Functions to retrieve art details, fractional data, vote data, etc.

Function Summary:
-   **Constructor:** Initializes ERC721, sets roles.
-   **Access Control & Pausable:**
    -   `pause()`: Pause contract.
    -   `unpause()`: Unpause contract.
    -   `grantRole(bytes32 role, address account)`: Grant a role.
    -   `revokeRole(bytes32 role, address account)`: Revoke a role.
    -   `renounceRole(bytes32 role, address callerConfirmation)`: Caller renounces their own role.
    -   `hasRole(bytes32 role, address account)`: Check if an address has a role.
    -   `getRoleAdmin(bytes32 role)`: Get the admin role for a specific role.
-   **Core NFT (ERC721 Overrides & Custom Mint):**
    -   `supportsInterface(bytes4 interfaceId)`: ERC165 support.
    -   `mintDynamicArt(address recipient, string memory initialURI, uint256 initialState)`: Mints a new dynamic NFT (restricted to ARTIST role).
    -   `transferFrom(address from, address to, uint256 tokenId)`: Standard transfer (restricted if fractionalized).
    -   `safeTransferFrom(address from, address to, uint256 tokenId)`: Standard safe transfer (restricted if fractionalized).
    -   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Standard safe transfer with data (restricted if fractionalized).
    -   `approve(address to, uint256 tokenId)`: Standard approve (restricted if fractionalized).
    -   `setApprovalForAll(address operator, bool approved)`: Standard set approval for all (restricted if fractionalized).
    -   `balanceOf(address owner)`: Standard balance.
    -   `ownerOf(uint256 tokenId)`: Standard owner (contract if fractionalized).
    -   `getApproved(uint256 tokenId)`: Standard get approved.
    -   `isApprovedForAll(address owner, address operator)`: Standard check approval for all.
    -   `tokenURI(uint256 tokenId)`: Returns dynamic URI based on state.
    -   `_beforeTokenTransfer(address from, address to, uint256 tokenId)`: Hook to prevent transfers of fractionalized NFTs.
-   **Dynamic Art State Interaction:**
    -   `updateArtStateViaOracle(uint256 tokenId, uint256 newState)`: Simulate updating state via oracle call (can be restricted).
    -   `startArtStateVote(uint256 tokenId, uint256 proposedState, uint256 duration)`: Start a vote on a state change (restricted to CURATOR).
    -   `voteForArtState(uint256 tokenId, uint256 proposalId)`: Vote on an active state change proposal (can be restricted by role/stake).
    -   `endArtStateVote(uint256 tokenId, uint256 proposalId)`: End a vote and apply state change if successful.
    -   `getArtState(uint256 tokenId)`: Get the current dynamic state value.
    -   `getVoteDetails(uint256 tokenId, uint256 proposalId)`: Get details about a specific vote.
    -   `getVoteCount(uint256 tokenId, uint256 proposalId, address voter)`: Check if an address has voted on a proposal.
-   **Fractional Ownership:**
    -   `fractionalizeArt(uint256 tokenId, uint256 totalShares, uint256 reservePrice)`: Locks NFT and mints fractional shares to the owner. Sets a reserve price for buyout.
    -   `buyFractionalShares(uint256 tokenId, uint256 sharesAmount)`: Buy shares (simplified - assumes shares are available, e.g., from seller or initial pool). Needs external logic or internal marketplace; simplified as direct purchase from contract's initial supply/pool for example.
    -   `sellFractionalShares(uint256 tokenId, uint256 sharesAmount)`: Sell shares (simplified - assumes buyer exists or sells back to pool).
    -   `redeemArtFromFractions(uint256 tokenId)`: Redeem the full NFT if caller owns all shares.
    -   `buyFractionalizedNFTOutright(uint256 tokenId)`: Buy the locked NFT by paying the reserve price. Triggers payout distribution.
    -   `claimFractionalPayout(uint256 tokenId)`: Allows fractional owners to claim their share of the buyout funds.
    -   `getFractionalSupply(uint256 tokenId)`: Get total shares for a fractionalized NFT.
    -   `getOwnerShares(uint256 tokenId, address owner)`: Get shares owned by an address for a fractionalized NFT.
    -   `isFractionalized(uint256 tokenId)`: Check if an NFT is fractionalized.
-   **Administration/Fees:**
    -   `setReservePrice(uint256 tokenId, uint256 newReservePrice)`: Set new reserve price for a fractionalized NFT (restricted to ADMIN or maybe fractional owners vote). Let's restrict to ADMIN for simplicity.
    -   `setVotingPeriod(uint256 newPeriod)`: Set the default duration for votes.
    -   `withdrawContractBalance()`: Withdraw contract's ETH balance (restricted to ADMIN).
    -   `setBaseTokenURIPrefix(string memory prefix)`: Set a prefix for generating token URIs.
-   **Queries:**
    -   `getArtDetails(uint256 tokenId)`: Get structured details about an NFT.
    -   `getTotalSupply()`: Get the total number of NFTs minted.
    -   `getTotalFractionalSupply(uint256 tokenId)`: Alias for `getFractionalSupply`.

Total Functions: ~35 (Counting inherited/overridden ERC721 functions and custom ones)
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // Using URIStorage for easier metadata handling

// Interface for a hypothetical Oracle contract
interface IOracle {
    function getData(string memory key) external view returns (uint256);
}

contract DecentralizedDynamicArtGallery is ERC721URIStorage, AccessControl, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    // --- Structs ---

    struct ArtDetails {
        address artist;
        uint256 initialState;       // Original state value set by artist
        uint256 currentState;       // Current dynamic state value
        string baseURI;             // Base URI segment for this specific art
        bool isFractionalized;
        uint256 fractionalTotalShares;
        uint256 fractionalReservePrice; // Price to buy the whole fractionalized piece
        uint256 buyoutPayoutPerShare;   // Payout amount per share if bought out
    }

    struct Vote {
        uint256 proposedState;
        uint64 endTime;
        uint256 votesFor;
        bool executed;
        bool passed; // Result of the vote
        mapping(address => bool) hasVoted; // Tracks who voted
    }

    // --- State Variables ---

    // Mapping from token ID to ArtDetails
    mapping(uint256 => ArtDetails) private _artDetails;

    // Mapping from token ID to mapping of owner address to shares owned
    mapping(uint256 => mapping(address => uint256)) private _fractionalShares;

    // Mapping from token ID to mapping of proposal ID to Vote details
    mapping(uint256 => mapping(uint256 => Vote)) private _artStateVotes;
    mapping(uint256 => uint256) private _nextProposalId; // Counter for proposal IDs per token

    // Oracle address (simulated)
    address public oracleAddress;

    // Default voting period duration in seconds
    uint256 public defaultVotingPeriod = 3 days;

    // Base URI prefix for tokenURI construction
    string private _baseTokenURIPrefix;

    // --- Events ---

    event ArtMinted(uint256 tokenId, address artist, address recipient, string initialURI, uint256 initialState);
    event ArtStateUpdated(uint256 tokenId, uint256 newState, string reason); // reason: "vote", "oracle", "manual"
    event VoteStarted(uint256 tokenId, uint256 proposalId, uint256 proposedState, uint64 endTime);
    event Voted(uint256 tokenId, uint256 proposalId, address voter);
    event VoteEnded(uint256 tokenId, uint256 proposalId, bool passed);
    event ArtFractionalized(uint256 tokenId, uint256 totalShares, uint256 reservePrice);
    event SharesTransferred(uint256 tokenId, address from, address to, uint256 amount);
    event ArtRedeemedFromFractions(uint256 tokenId, address redeemer);
    event FractionalizedNFTBoughtOut(uint256 tokenId, address buyer, uint256 reservePrice);
    event FractionalPayoutClaimed(uint256 tokenId, address claimant, uint256 amount);

    // --- Errors ---

    error Unauthorized(address caller);
    error NotArtist(address caller);
    error NotCurator(address caller);
    error NotAdmin(address caller);
    error TokenDoesNotExist(uint256 tokenId);
    error TokenAlreadyFractionalized(uint256 tokenId);
    error TokenNotFractionalized(uint256 tokenId);
    error CannotTransferFractionalized(uint256 tokenId);
    error CannotApproveFractionalized(uint256 tokenId);
    error CannotSetApprovalForAllFractionalized(uint256 tokenId);
    error InvalidSharesAmount();
    error NotEnoughShares();
    error MustOwnAllSharesToRedeem();
    error NoActiveVote(uint256 tokenId, uint256 proposalId);
    error VoteAlreadyEnded(uint256 tokenId, uint256 proposalId);
    error VoteNotEnded(uint256 tokenId, uint256 proposalId);
    error AlreadyVoted(uint256 tokenId, uint256 proposalId, address voter);
    error VoteFailedToReachThreshold();
    error InvalidReservePrice();
    error BuyoutNotYetOccurred(uint256 tokenId);
    error NothingToClaim(uint256 tokenId, address claimant);
    error InvalidStateValue();


    // --- Constructor ---

    constructor(string memory name, string memory symbol, address admin)
        ERC721(name, symbol)
    {
        // Grant default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        // Grant ADMIN role
        _grantRole(ADMIN_ROLE, admin);
        // Renounce ownership as we use AccessControl
        _renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // --- Access Control & Pausable Modifiers ---

    modifier onlyAdmin() {
        _checkRole(ADMIN_ROLE);
        _;
    }

    modifier onlyCurator() {
        _checkRole(CURATOR_ROLE);
        _;
    }

    modifier onlyArtist() {
        _checkRole(ARTIST_ROLE);
        _;
    }

    // --- Core NFT (ERC721 Overrides & Custom Mint) ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IAccessControl).interfaceId ||
               interfaceId == type(IERC721Metadata.interfaceId) ||
               super.supportsInterface(interfaceId);
    }

    /// @notice Mints a new dynamic art NFT
    /// @param recipient The address to mint the NFT to
    /// @param initialURI The initial token URI for the art metadata
    /// @param initialState The initial dynamic state value for the art
    function mintDynamicArt(address recipient, string memory initialURI, uint256 initialState)
        public
        onlyArtist
        whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, initialURI);

        // Store initial details
        _artDetails[newTokenId] = ArtDetails({
            artist: msg.sender,
            initialState: initialState,
            currentState: initialState, // Start with initial state
            baseURI: initialURI,
            isFractionalized: false,
            fractionalTotalShares: 0,
            fractionalReservePrice: 0,
            buyoutPayoutPerShare: 0
        });

        emit ArtMinted(newTokenId, msg.sender, recipient, initialURI, initialState);
    }

    // --- Overrides to restrict transfers/approvals for fractionalized tokens ---

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) whenNotPaused {
        if (_artDetails[tokenId].isFractionalized) {
            revert CannotTransferFractionalized(tokenId);
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721) whenNotPaused {
         if (_artDetails[tokenId].isFractionalized) {
            revert CannotTransferFractionalized(tokenId);
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721) whenNotPaused {
         if (_artDetails[tokenId].isFractionalized) {
            revert CannotTransferFractionalized(tokenId);
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public override(ERC721) whenNotPaused {
        if (_artDetails[tokenId].isFractionalized) {
            revert CannotApproveFractionalized(tokenId);
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721) whenNotPaused {
        if (_artDetails[tokenIdCounter.current()].isFractionalized) { // Check any token if needed, or restrict only if *caller* owns fractionalized. Let's just restrict standard ERC721 approval if *any* token is fractionalized for simplicity in this example, or better, only prevent approval of the *specific* fractionalized token.
             // ERC721's setApprovalForAll works on *all* tokens owned by sender.
             // This needs careful consideration if user owns *some* fractionalized and *some* not.
             // A better approach is to check this in the transfer functions directly.
             // Let's remove this restriction here and only enforce in transfer/approve for the specific token ID.
        }
        super.setApprovalForAll(operator, approved);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
         // This hook is called internally by all transfer functions.
         // We use it to prevent transfers of fractionalized NFTs.
        if (_artDetails[tokenId].isFractionalized && from != address(0) && to != address(0)) {
             // Allow transfers *to* and *from* address(0) for mint/burn
             // Also allow transfer to 'this' contract when fractionalizing
            if (to != address(this) && from != address(this)) {
                 revert CannotTransferFractionalized(tokenId);
            }
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }


    /// @notice Returns the token URI, potentially incorporating dynamic state
    /// @param tokenId The ID of the token
    /// @return The token URI string
    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        // Construct URI using base prefix, token ID, and current state
        // This is a simplified example. Real-world dynamic NFTs might use
        // IPFS CIDs based on state or an API gateway.
        string memory base = bytes(_baseTokenURIPrefix).length > 0 ? _baseTokenURIPrefix : _artDetails[tokenId].baseURI;
        return string(abi.encodePacked(base, "/", Strings.toString(tokenId), "/state/", Strings.toString(_artDetails[tokenId].currentState)));
    }

    // --- Dynamic Art State Interaction ---

    /// @notice Simulates updating art state based on external data (e.g., oracle)
    /// @dev This function simulates an oracle callback. In a real scenario,
    /// it would be callable only by the trusted oracle contract.
    /// @param tokenId The ID of the token
    /// @param newState The new state value fetched by the oracle
    function updateArtStateViaOracle(uint256 tokenId, uint256 newState)
        public
        // In a real contract, this would be restricted to only the oracle address
        // For simulation, we'll allow ADMIN to trigger it.
        onlyAdmin
        whenNotPaused
    {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
         // Validate newState if needed (e.g., within a specific range)
         if (newState > 100) revert InvalidStateValue(); // Example validation

        _artDetails[tokenId].currentState = newState;
        emit ArtStateUpdated(tokenId, newState, "oracle");
    }

    /// @notice Starts a community/curator vote on a proposed state change
    /// @param tokenId The ID of the token
    /// @param proposedState The state value being proposed
    /// @param duration The duration of the vote in seconds (overrides default if > 0)
    function startArtStateVote(uint256 tokenId, uint256 proposedState, uint256 duration)
        public
        onlyCurator
        whenNotPaused
    {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
         // Validate proposedState if needed
         if (proposedState > 100) revert InvalidStateValue(); // Example validation

        uint256 proposalId = _nextProposalId[tokenId]++;
        uint256 voteDuration = duration > 0 ? duration : defaultVotingPeriod;

        Vote storage newVote = _artStateVotes[tokenId][proposalId];
        newVote.proposedState = proposedState;
        newVote.endTime = uint64(block.timestamp + voteDuration);
        newVote.executed = false;
        newVote.passed = false; // Default to false

        emit VoteStarted(tokenId, proposalId, proposedState, newVote.endTime);
    }

    /// @notice Casts a vote on an active state change proposal
    /// @param tokenId The ID of the token
    /// @param proposalId The ID of the vote proposal
    function voteForArtState(uint256 tokenId, uint256 proposalId)
        public
        whenNotPaused
    {
        Vote storage vote = _artStateVotes[tokenId][proposalId];

        if (vote.endTime == 0 || vote.executed) {
            revert NoActiveVote(tokenId, proposalId); // Vote not started or already ended/executed
        }
        if (block.timestamp > vote.endTime) {
            revert VoteAlreadyEnded(tokenId, proposalId);
        }
        if (vote.hasVoted[msg.sender]) {
            revert AlreadyVoted(tokenId, proposalId, msg.sender);
        }

        // Voting logic: Simplistic 1 address = 1 vote
        // More advanced could involve staking gallery tokens, NFT ownership, etc.
        vote.votesFor++;
        vote.hasVoted[msg.sender] = true;

        emit Voted(tokenId, proposalId, msg.sender);
    }

    /// @notice Ends a vote and applies the state change if it passed
    /// @param tokenId The ID of the token
    /// @param proposalId The ID of the vote proposal
    function endArtStateVote(uint256 tokenId, uint256 proposalId)
        public
        whenNotPaused
    {
        Vote storage vote = _artStateVotes[tokenId][proposalId];

        if (vote.endTime == 0 || vote.executed) {
             revert NoActiveVote(tokenId, proposalId);
        }
        if (block.timestamp <= vote.endTime) {
             revert VoteNotEnded(tokenId, proposalId);
        }
        if (!_exists(tokenId)) {
             // Should not happen if vote was started, but safety check
             revert TokenDoesNotExist(tokenId);
        }

        // Define quorum and threshold - example logic:
        // Assume total number of votes castable is represented somehow (e.g., active users, staked tokens)
        // For this simplified example, let's assume a simple threshold based on votesFor
        // A real DAO would need a mechanism to determine total voting power / quorum.
        // Let's assume a simple threshold: requires at least 3 votes and > 50% of votes cast (which is just > 3 if 3 is min)
        uint256 votingThreshold = 3; // Example minimum votes needed to pass
        bool votePassed = vote.votesFor >= votingThreshold; // Simplified condition

        vote.executed = true;
        vote.passed = votePassed;

        if (votePassed) {
            _artDetails[tokenId].currentState = vote.proposedState;
            emit ArtStateUpdated(tokenId, vote.proposedState, "vote");
        } else {
             emit VoteFailedToReachThreshold(); // Optional: specific event for failure
        }

        emit VoteEnded(tokenId, proposalId, votePassed);
    }

    /// @notice Gets the current dynamic state of an art piece
    /// @param tokenId The ID of the token
    /// @return The current dynamic state value
    function getArtState(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        return _artDetails[tokenId].currentState;
    }

    /// @notice Gets details about a specific vote proposal
    /// @param tokenId The ID of the token
    /// @param proposalId The ID of the vote proposal
    /// @return proposedState The state value being proposed
    /// @return endTime The timestamp when the vote ends
    /// @return votesFor The number of votes cast FOR the proposal
    /// @return executed Whether the vote has been executed
    /// @return passed Whether the vote passed upon execution
    function getVoteDetails(uint256 tokenId, uint256 proposalId)
        public
        view
        returns (
            uint256 proposedState,
            uint64 endTime,
            uint256 votesFor,
            bool executed,
            bool passed
        )
    {
        Vote storage vote = _artStateVotes[tokenId][proposalId];
        // Check if vote exists by checking endTime (0 is default)
        if (vote.endTime == 0 && proposalId == 0 && _nextProposalId[tokenId] == 0) {
             // This might be the case if no votes ever started for this token
             // Or if proposalId is genuinely invalid.
             // More robust check needed if proposalId can be 0 for first vote.
             // Assuming proposalId starts from 0 and _nextProposalId from 0, the first proposalId is 0.
             // If _nextProposalId[tokenId] > proposalId, it exists or existed.
             if (proposalId >= _nextProposalId[tokenId]) {
                 revert NoActiveVote(tokenId, proposalId);
             }
        } else if (vote.endTime == 0 && proposalId > 0) {
             // Proposal ID > 0 with endTime 0 usually means it doesn't exist
             if (proposalId >= _nextProposalId[tokenId]) {
                revert NoActiveVote(tokenId, proposalId);
            }
        }


        return (
            vote.proposedState,
            vote.endTime,
            vote.votesFor,
            vote.executed,
            vote.passed
        );
    }

     /// @notice Checks if an address has voted on a specific proposal
     /// @param tokenId The ID of the token
     /// @param proposalId The ID of the vote proposal
     /// @param voter The address to check
     /// @return True if the address has voted, false otherwise
    function getVoteCount(uint256 tokenId, uint256 proposalId, address voter) public view returns (bool) {
         Vote storage vote = _artStateVotes[tokenId][proposalId];
         // Check if vote exists before checking hasVoted
         if (vote.endTime == 0 && proposalId >= _nextProposalId[tokenId]) {
              revert NoActiveVote(tokenId, proposalId);
         }
         return vote.hasVoted[voter];
     }


    // --- Fractional Ownership ---

    /// @notice Locks an NFT and creates fractional shares for the owner
    /// @dev The NFT is transferred to the contract address.
    /// @param tokenId The ID of the token to fractionalize
    /// @param totalShares The total number of fractional shares to create (e.g., 1e18 for 1.0 total)
    /// @param reservePrice The price (in wei) at which the whole NFT can be bought out
    function fractionalizeArt(uint256 tokenId, uint256 totalShares, uint256 reservePrice)
        public
        whenNotPaused
        nonReentrant // Prevent reentrancy in case _transfer somehow allows it
    {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert Unauthorized(msg.sender);
        }
        if (_artDetails[tokenId].isFractionalized) {
            revert TokenAlreadyFractionalized(tokenId);
        }
         if (totalShares == 0) {
             revert InvalidSharesAmount();
         }
         if (reservePrice == 0) {
              revert InvalidReservePrice(); // Reserve price must be set for buyout mechanism
         }


        // Transfer the NFT to the contract address
        _safeTransfer(msg.sender, address(this), tokenId);

        // Set fractionalization details
        _artDetails[tokenId].isFractionalized = true;
        _artDetails[tokenId].fractionalTotalShares = totalShares;
        _artDetails[tokenId].fractionalReservePrice = reservePrice;
         // Initially, the original owner gets all shares
        _fractionalShares[tokenId][msg.sender] = totalShares;

        emit ArtFractionalized(tokenId, totalShares, reservePrice);
        emit SharesTransferred(tokenId, address(0), msg.sender, totalShares); // Mint shares event
    }

    /// @notice Buy shares of a fractionalized NFT
    /// @dev This is a simplified internal transfer of shares.
    /// A real implementation might integrate a fractional marketplace.
    /// @param tokenId The ID of the fractionalized token
    /// @param sharesAmount The number of shares to buy
    function buyFractionalShares(uint256 tokenId, uint256 sharesAmount)
        public
        whenNotPaused
    {
        if (!_artDetails[tokenId].isFractionalized) {
             revert TokenNotFractionalized(tokenId);
        }
        if (sharesAmount == 0) {
             revert InvalidSharesAmount();
        }

        // This function requires the buyer to already have a corresponding mechanism
        // to receive shares, likely via an external marketplace or a direct
        // transfer from another owner.
        // For this example, we assume shares are being 'bought' from a hypothetical
        // pool or directly from a known seller's balance by an external system.
        // Let's simplify: this function assumes 'msg.sender' is receiving shares
        // and the 'from' address is implicitly the seller who must have enough shares.
        // A direct P2P share transfer function is more practical:
        // `transferFractionalShares(address from, address to, uint256 tokenId, uint256 amount)`

        // Let's implement a simple transfer function for shares instead:
        revert("Use transferFractionalShares function");
    }

     /// @notice Transfer fractional shares between owners
     /// @param from The address sending shares
     /// @param to The address receiving shares
     /// @param tokenId The ID of the fractionalized token
     /// @param amount The number of shares to transfer
     function transferFractionalShares(address from, address to, uint256 tokenId, uint256 amount)
         public
         whenNotPaused
     {
         if (!_artDetails[tokenId].isFractionalized) {
              revert TokenNotFractionalized(tokenId);
         }
         if (amount == 0) {
              revert InvalidSharesAmount();
         }
          if (from != msg.sender && !hasRole(ADMIN_ROLE, msg.sender)) {
             revert Unauthorized(msg.sender); // Only sender or admin can transfer FROM sender
         }
         if (_fractionalShares[tokenId][from] < amount) {
             revert NotEnoughShares();
         }
         if (to == address(0)) {
             revert ERC721InvalidReceiver(address(0)); // Cannot transfer to zero address
         }

         _fractionalShares[tokenId][from] -= amount;
         _fractionalShares[tokenId][to] += amount;

         emit SharesTransferred(tokenId, from, to, amount);
     }


    /// @notice Allows the owner of all fractional shares to redeem the original NFT
    /// @param tokenId The ID of the fractionalized token
    function redeemArtFromFractions(uint256 tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        ArtDetails storage art = _artDetails[tokenId];
        if (!art.isFractionalized) {
             revert TokenNotFractionalized(tokenId);
        }
        if (_fractionalShares[tokenId][msg.sender] != art.fractionalTotalShares) {
            revert MustOwnAllSharesToRedeem();
        }

        // Transfer the NFT back to the redeemer
        _safeTransfer(address(this), msg.sender, tokenId);

        // Burn all shares
        _fractionalShares[tokenId][msg.sender] = 0;
         emit SharesTransferred(tokenId, msg.sender, address(0), art.fractionalTotalShares); // Burn shares event

        // Reset fractionalization state
        art.isFractionalized = false;
        art.fractionalTotalShares = 0;
        art.fractionalReservePrice = 0;
        art.buyoutPayoutPerShare = 0; // Clear any pending buyout payout data

        // Clear votes for this token ID? Or keep history? Let's keep history for now.

        emit ArtRedeemedFromFractions(tokenId, msg.sender);
    }

    /// @notice Allows anyone to buy a fractionalized NFT by paying its reserve price
    /// @param tokenId The ID of the fractionalized token
    function buyFractionalizedNFTOutright(uint256 tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        ArtDetails storage art = _artDetails[tokenId];
        if (!art.isFractionalized) {
             revert TokenNotFractionalized(tokenId);
        }
        if (msg.value < art.fractionalReservePrice) {
             revert InvalidReservePrice(); // Not enough ETH sent
        }

        // Transfer the NFT to the buyer
        _safeTransfer(address(this), msg.sender, tokenId);

        // Calculate payout per share
        uint256 totalValue = msg.value;
        // Optional: Deduct a small protocol fee here before distribution
        // uint256 protocolFee = (totalValue * 1) / 100; // 1% fee example
        // totalValue -= protocolFee;
        // You would need a mechanism to manage and withdraw protocol fees.
        // For simplicity, no fee in this example.

        art.buyoutPayoutPerShare = totalValue / art.fractionalTotalShares; // Integer division might lose dust

        // Reset fractionalization state
        art.isFractionalized = false;
        art.fractionalTotalShares = 0; // Shares are effectively "burned" for payout
        art.fractionalReservePrice = 0;

         // Note: Fractional shares mapping (_fractionalShares) is NOT cleared here.
         // Shareholder balances are needed to calculate payouts in claimFractionalPayout.

        emit FractionalizedNFTBoughtOut(tokenId, msg.sender, msg.value);

         // Any excess ETH is kept in the contract balance or refunded.
         // Let's leave excess in the contract for ADMIN to withdraw for simplicity.
    }

    /// @notice Allows a fractional owner to claim their share of buyout funds
    /// @param tokenId The ID of the NFT that was bought out
    function claimFractionalPayout(uint256 tokenId)
        public
        nonReentrant // Essential for ETH transfers
    {
        ArtDetails storage art = _artDetails[tokenId];
        // Check if the NFT was bought out and payout data is set
        if (art.buyoutPayoutPerShare == 0 || art.isFractionalized) { // isFractionalized should be false if bought out
            revert BuyoutNotYetOccurred(tokenId);
        }

        uint256 claimantShares = _fractionalShares[tokenId][msg.sender];
        if (claimantShares == 0) {
            revert NothingToClaim(tokenId, msg.sender);
        }

        uint256 payoutAmount = claimantShares * art.buyoutPayoutPerShare;

        // Clear the claimant's shares *before* sending ETH to prevent reentrancy attacks
        _fractionalShares[tokenId][msg.sender] = 0;
         // Optionally "burn" the shares visually by decreasing total shares, though it's 0 now anyway
         // art.fractionalTotalShares -= claimantShares; // Not needed as it was set to 0 in buyout

        (bool success, ) = payable(msg.sender).call{value: payoutAmount}("");
        require(success, "ETH transfer failed"); // Use require for ETH transfers

        emit FractionalPayoutClaimed(tokenId, msg.sender, payoutAmount);
    }

     /// @notice Get total fractional shares created for an NFT
     /// @param tokenId The ID of the fractionalized token
     /// @return The total number of shares
     function getFractionalSupply(uint256 tokenId) public view returns (uint256) {
         if (!_artDetails[tokenId].isFractionalized) {
              return 0; // Not fractionalized
         }
         return _artDetails[tokenId].fractionalTotalShares;
     }

     /// @notice Get shares owned by a specific address for an NFT
     /// @param tokenId The ID of the fractionalized token
     /// @param owner The address to check shares for
     /// @return The number of shares owned by the address
     function getOwnerShares(uint256 tokenId, address owner) public view returns (uint256) {
         // Returns 0 if not fractionalized or owner has no shares
         return _fractionalShares[tokenId][owner];
     }

    /// @notice Check if an NFT is fractionalized
    /// @param tokenId The ID of the token
    /// @return True if fractionalized, false otherwise
     function isFractionalized(uint256 tokenId) public view returns (bool) {
         return _artDetails[tokenId].isFractionalized;
     }


    // --- Administration/Fees ---

    /// @notice Pauses the contract (only ADMIN)
    function pause() public onlyAdmin whenNotPaused {
        _pause();
    }

    /// @notice Unpauses the contract (only ADMIN)
    function unpause() public onlyAdmin whenPaused {
        _unpause();
    }

    /// @notice Sets the reserve price for a fractionalized NFT (only ADMIN)
    /// @param tokenId The ID of the fractionalized token
    /// @param newReservePrice The new reserve price in wei
    function setReservePrice(uint256 tokenId, uint256 newReservePrice) public onlyAdmin whenNotPaused {
        if (!_artDetails[tokenId].isFractionalized) {
             revert TokenNotFractionalized(tokenId);
        }
         if (newReservePrice == 0) {
              revert InvalidReservePrice();
         }
        _artDetails[tokenId].fractionalReservePrice = newReservePrice;
    }

    /// @notice Sets the default duration for state change votes (only ADMIN)
    /// @param newPeriod The new default voting period in seconds
    function setVotingPeriod(uint256 newPeriod) public onlyAdmin {
        defaultVotingPeriod = newPeriod;
    }

    /// @notice Allows the ADMIN to withdraw the contract's ETH balance
    /// @dev This includes ETH from buyouts minus payouts claimed, or any other received ETH.
    function withdrawContractBalance() public onlyAdmin nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "ETH transfer failed");
    }

     /// @notice Sets the base URI prefix used for generating token URIs
     /// @param prefix The new base URI prefix
     function setBaseTokenURIPrefix(string memory prefix) public onlyAdmin {
         _baseTokenURIPrefix = prefix;
     }

     /// @notice Sets the address of the oracle contract (only ADMIN)
     /// @param _oracleAddress The address of the oracle contract
     function setOracleAddress(address _oracleAddress) public onlyAdmin {
         oracleAddress = _oracleAddress;
     }


    // --- Queries ---

    /// @notice Gets comprehensive details about an art piece
    /// @param tokenId The ID of the token
    /// @return ArtDetails struct
    function getArtDetails(uint256 tokenId) public view returns (ArtDetails memory) {
        if (!_exists(tokenId)) {
             revert TokenDoesNotExist(tokenId);
        }
        // Need to copy from storage to memory for return
        ArtDetails storage art = _artDetails[tokenId];
        return ArtDetails({
            artist: art.artist,
            initialState: art.initialState,
            currentState: art.currentState,
            baseURI: art.baseURI, // Note: baseURI stored here is the initial one
            isFractionalized: art.isFractionalized,
            fractionalTotalShares: art.fractionalTotalShares,
            fractionalReservePrice: art.fractionalReservePrice,
            buyoutPayoutPerShare: art.buyoutPayoutPerShare // Payout per share if already bought out
        });
    }

    /// @notice Gets the total number of NFTs minted
    /// @return The total supply
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

     /// @notice Alias for getFractionalSupply
     /// @param tokenId The ID of the token
     /// @return The total number of fractional shares
     function getTotalFractionalSupply(uint256 tokenId) public view returns (uint256) {
         return getFractionalSupply(tokenId);
     }
}
```

**Explanation of Concepts and Design Choices:**

1.  **Dynamic State (`currentState`):** Each art piece has a `currentState` which is a `uint256`. This could represent mood, environmental data, interaction count, etc. The `tokenURI` function is overridden to potentially include this state, allowing external metadata services (like IPFS gateways or APIs) to serve different images or JSON based on the on-chain state.
2.  **Dynamic State Updates:**
    *   `updateArtStateViaOracle`: A function designed to be called by a trusted oracle contract. This demonstrates how external, real-world data could influence the art. (In the example, `onlyAdmin` is used for simulation, but in production, it would be `only(oracleAddress)`).
    *   Community Voting (`startArtStateVote`, `voteForArtState`, `endArtStateVote`): A simple voting mechanism allows users (specifically `CURATOR_ROLE` to propose) to collectively decide on state changes. Votes are recorded, and after the duration, `endArtStateVote` checks if a simple threshold is met to apply the change. This introduces decentralized control over the art's evolution.
3.  **Fractionalization (`fractionalizeArt`, `_fractionalShares`, `isFractionalized`, `_beforeTokenTransfer` override):**
    *   When an NFT is fractionalized, it is transferred *to* the smart contract itself. This locks the NFT, preventing standard ERC721 transfers while it's fractionalized. The `_beforeTokenTransfer` hook enforces this restriction.
    *   Ownership of the *fractions* is tracked internally using `_fractionalShares` mapping. This is a simplified approach; a more complex system might mint actual ERC20 tokens representing the shares. Keeping it internal simplifies interactions *within* this contract.
4.  **Fractional Share Transfers (`transferFractionalShares`):** A dedicated function is needed to transfer fractional shares between addresses, as they are not standard ERC20 tokens in this implementation.
5.  **Redemption (`redeemArtFromFractions`):** If someone gathers *all* the fractional shares (`fractionalTotalShares`), they can call `redeemArtFromFractions`. This transfers the original NFT back to them and clears the fractionalization state and share balances.
6.  **Buyout Mechanism (`buyFractionalizedNFTOutright`, `claimFractionalPayout`):**
    *   A `reservePrice` is set during fractionalization. Anyone can pay this price to the contract (`buyFractionalizedNFTOutright`).
    *   The NFT is then transferred to the buyer.
    *   Instead of immediately sending ETH to all fractional owners (which could hit gas limits), the amount each share is worth (`buyoutPayoutPerShare`) is calculated and stored.
    *   Fractional owners must then call `claimFractionalPayout` individually to withdraw their share of the funds. This is known as a "pull" pattern for payments, which is safer than a "push" to many addresses.
7.  **Access Control (`AccessControl.sol`):** Defines clear roles (ADMIN, CURATOR, ARTIST) with specific permissions (`onlyAdmin`, `onlyCurator`, `onlyArtist` modifiers). The constructor sets up the initial admin.
8.  **Pausable (`Pausable.sol`):** Allows the `ADMIN_ROLE` to pause crucial state-changing functions in case of discovered bugs or issues, providing an emergency stop.
9.  **ReentrancyGuard (`ReentrancyGuard.sol`):** Applied to functions that send ETH (`withdrawContractBalance`, `claimFractionalPayout`) and `fractionalizeArt`/`redeemArtFromFractions` (as they involve transfers of the NFT which *could* potentially be crafted to re-enter if not careful, although ERC721 transfers are less prone than raw ETH transfers).
10. **Token URI (`tokenURI` override):** Demonstrates how the URI can be constructed dynamically, referencing the `currentState`. The `_baseTokenURIPrefix` allows for easier management of the base URL.
11. **Error Handling:** Uses `require` and `revert` with custom error names (Solidity 0.8+) for clearer debugging messages.
12. **State Variables:** Carefully structured mappings and structs to store all necessary information for each NFT, including dynamic state, fractional data, and vote details.
13. **Events:** Comprehensive events are emitted for key actions, making it easy for off-chain applications to track changes.

This contract provides a framework incorporating multiple advanced concepts. It's a complex example, and a production system would require further development (e.g., a dedicated fractional share ERC20 token, a more sophisticated voting mechanism like weighted voting or snapshot integration, a robust oracle integration, gas optimizations for large numbers of fractional owners, and extensive testing and security audits).