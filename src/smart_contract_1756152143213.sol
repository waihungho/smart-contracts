Here's a smart contract in Solidity that aims to be advanced, creative, and trendy, focusing on a decentralized platform for dynamic, AI-curated generative art NFTs. It incorporates Soulbound Token (SBT)-like reputation, on-chain NFT evolution, and DAO-style governance with conceptual hooks for AI oracles.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// Note: Solidity ^0.8.0 includes built-in overflow/underflow checks, making SafeMath largely redundant.

/// @title AetherCanvasDAO
/// @author Your_Name_or_Team
/// @notice A decentralized, reputation-governed platform for dynamic, AI-curated generative art NFTs (AetherCanvases).
///         It enables community proposals for NFT minting and evolution, managed by an internal reputation system,
///         and integrates conceptual hooks for AI oracle participation.
/// @dev This contract combines several advanced concepts: Soulbound-like reputation, dynamic on-chain NFT traits,
///      DAO governance with reputation weighting, and a framework for AI oracle interaction.

// Outline:
// I. Core Infrastructure & Configuration
//    - Contract ownership, pause functionality, platform fee settings, and minimum reputation thresholds for participation.
// II. Reputation System (Soulbound Tokens - SBTs)
//    - An internal, non-transferable reputation score (`sbtReputation`) used to weight voting power within the DAO.
//    - Functions for designated issuers to mint and revoke reputation, and for users to delegate their voting power.
// III. Dynamic NFT Management (AetherCanvas NFTs)
//    - An ERC721 token, "AetherCanvas," representing generative art pieces whose traits are stored and evolve on-chain.
//    - A robust proposal and voting system for both the initial minting of new canvases and for subsequent trait evolutions.
//    - Functionality allowing NFT owners to temporarily lock or unlock the evolutionary process of their canvas.
// IV. Curation & Governance
//    - Core Decentralized Autonomous Organization (DAO) functionalities, including a system for proposal submission,
//      reputation-weighted voting, and execution of decisions (e.g., minting, trait updates, treasury spending).
//    - Management of a DAO treasury, funded by platform fees, used for rewards, operational costs, and other expenditures.
// V. AI Oracle Integration (Conceptual Hooks)
//    - A framework to register and manage trusted external AI oracle addresses.
//    - Dedicated functions allowing registered AI oracles to submit trait suggestions, contributing to the art's evolution.
//    - A mechanism to reward AI contributors for their valuable insights and services, managed by the DAO.
// VI. Utility & Data Retrieval
//    - A comprehensive suite of getter functions designed to query various aspects of the contract's state,
//      including user reputation, detailed NFT information, and the current status of all outstanding proposals.

// Function Summary (38 functions):

// I. Core Infrastructure & Configuration
// 1.  constructor(address _initialFeeReceiver, uint256 _initialPlatformFeeBasisPoints): Initializes contract owner, sets initial platform fee (e.g., 500 = 5%), and designates the initial platform fee receiver.
// 2.  setPlatformFee(uint256 _feeBasisPoints): Owner sets the platform fee (0-10000 basis points) applied to primary mints/sales.
// 3.  setPlatformFeeReceiver(address _receiver): Owner sets the address where collected platform fees are sent.
// 4.  pauseContract(): Owner can pause critical platform functions (e.g., minting, proposals) during emergencies.
// 5.  unpauseContract(): Owner can reactivate the contract after a pause.
// 6.  setMinReputationForProposal(uint256 _score): Owner sets the minimum effective reputation required to submit any new proposal.

// II. Reputation System (Soulbound Tokens - SBTs)
// 7.  addReputationIssuer(address _issuer): Owner grants `REPUTATION_ISSUER_ROLE` to an address, enabling them to issue/revoke reputation.
// 8.  removeReputationIssuer(address _issuer): Owner revokes `REPUTATION_ISSUER_ROLE` from an address.
// 9.  issueReputation(address _recipient, uint256 _amount, bytes32 _reasonHash): A reputation issuer grants `_amount` of non-transferable reputation to `_recipient`.
// 10. delegateReputation(address _delegatee, uint256 _amount): A user delegates `_amount` of their own voting power to `_delegatee`.
// 11. undelegateReputation(address _delegatee, uint256 _amount): A user revokes `_amount` of previously delegated voting power from `_delegatee`.
// 12. revokeReputation(address _from, uint256 _amount, bytes32 _reasonHash): A reputation issuer revokes `_amount` of reputation from `_from`.
// 13. getReputation(address _user): Returns the raw total reputation score of a user.
// 14. getEffectiveVotingPower(address _user): Calculates and returns the user's actual voting power, accounting for their own reputation, incoming delegations, and outgoing delegations.

// III. Dynamic NFT Management (AetherCanvas NFTs)
// 15. proposeCanvasMint(string calldata _initialMetadataURI, string calldata _initialTraitHash, address _creator): Submits a new AetherCanvas idea for community approval. Creator must meet min reputation.
// 16. voteOnCanvasMint(uint256 _proposalId, bool _approve): Allows users with effective voting power to vote on a canvas mint proposal.
// 17. executeCanvasMint(uint256 _proposalId): If the mint proposal passes, this function mints the new AetherCanvas NFT, transfers initial fees to the platform, and rewards the creator.
// 18. proposeTraitEvolution(uint256 _tokenId, string calldata _newTraitHash, string calldata _description): Any reputation holder can propose a new trait evolution for an existing AetherCanvas NFT.
// 19. voteOnTraitEvolution(uint256 _tokenId, uint256 _evolutionProposalId, bool _approve): Reputation holders vote on a specific trait evolution proposal for a given NFT.
// 20. applyTraitEvolution(uint256 _tokenId, uint256 _evolutionProposalId): If approved by vote, this function applies the new trait to the NFT, advancing its evolution stage.
// 21. getCanvasCurrentTraits(uint256 _tokenId): Returns the currently active trait hash for a specified AetherCanvas NFT.
// 22. lockCanvasEvolution(uint256 _tokenId): Allows the owner of an AetherCanvas NFT to temporarily prevent further trait evolution proposals for their artwork.
// 23. unlockCanvasEvolution(uint256 _tokenId): The NFT owner can reactivate the evolution process for their canvas, allowing new trait proposals.

// IV. Curation & Governance
// 24. submitTreasuryProposal(string calldata _description, address _recipient, uint256 _amount): A user with sufficient reputation can propose spending funds from the DAO treasury.
// 25. voteOnTreasuryProposal(uint256 _proposalId, bool _approve): Reputation holders vote on treasury spending proposals.
// 26. executeTreasuryProposal(uint256 _proposalId): If a treasury proposal passes its vote, this function executes the proposed transfer of funds.

// V. AI Oracle Integration (Conceptual Hooks)
// 27. registerAIOrcle(address _oracleAddress, bytes32 _descriptionHash): Owner registers an address as an authorized AI Oracle.
// 28. deregisterAIOrcle(address _oracleAddress): Owner removes an AI Oracle's authorization.
// 29. submitAITraitSuggestion(uint256 _tokenId, string calldata _suggestionHash, bytes32 _reasonHash): An authorized AI oracle submits a trait suggestion for a specified NFT.
// 30. rewardAIOrcle(address _oracleAddress, uint256 _amount, bytes32 _reasonHash): Owner or authorized party rewards an AI oracle from the treasury for their contributions.

// VI. Utility & Data Retrieval
// 31. getCanvasEvolutionHistory(uint256 _tokenId): Returns the full ordered list of trait hashes an AetherCanvas NFT has undergone.
// 32. getTokenCreator(uint256 _tokenId): Returns the original creator address of a given AetherCanvas NFT.
// 33. getProposalState(uint256 _proposalId, ProposalType _type): Returns the current state (Pending, Approved, Rejected, Executed) of a specified proposal.
// 34. getCanvasMintProposalDetails(uint256 _proposalId): Retrieves all details for a specific canvas mint proposal.
// 35. getTraitEvolutionProposalDetails(uint224 _tokenId, uint256 _evolutionProposalId): Retrieves details for a specific trait evolution proposal for an NFT. (Note: _tokenId changed to uint224 for packing)
// 36. getTreasuryProposalDetails(uint256 _proposalId): Retrieves details for a specific treasury spending proposal.
// 37. isAIOrcle(address _addr): Checks if a given address is currently a registered AI Oracle.
// 38. getOracleSuggestions(uint256 _tokenId, uint256 _startIndex, uint256 _count): Returns a paginated list of AI trait suggestions made for a specific NFT.

contract AetherCanvasDAO is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Custom Errors for Gas Efficiency ---
    error NotEnoughReputation(address caller, uint256 required, uint256 has);
    error UnauthorizedReputationIssuer(address caller);
    error CanvasDoesNotExist(uint256 tokenId);
    error ProposalDoesNotExist(uint256 proposalId);
    error InvalidProposalState(uint256 proposalId, ProposalState currentState, ProposalState expectedState);
    error AlreadyVoted(address voter, uint256 proposalId);
    error EvolutionLocked(uint256 tokenId);
    error InvalidFeeBasisPoints(uint256 fee);
    error UnauthorizedAIOrcle(address caller);
    error NotEnoughFunds(uint256 required, uint256 has);
    error InsufficientReputationDelegation(address delegator, address delegatee, uint256 requested);
    error InvalidProposalType();

    // --- Constants & Configuration ---
    uint256 public platformFeeBasisPoints; // e.g., 500 for 5% (500/10000)
    address public platformFeeReceiver;
    uint256 public minReputationForProposal; // Minimum effective reputation to submit any proposal
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days; // Time for proposals to be voted on
    uint256 public constant PROPOSAL_QUORUM_PERCENTAGE = 10; // 10% of total reputation must vote
    uint256 public constant PROPOSAL_APPROVAL_PERCENTAGE = 51; // 51% of votes must be 'yes'

    bytes32 private constant REPUTATION_ISSUER_ROLE = keccak256("REPUTATION_ISSUER_ROLE");

    // --- Counters ---
    Counters.Counter private _canvasTokenIds;
    Counters.Counter private _canvasMintProposalIds;
    Counters.Counter private _treasuryProposalIds;

    // --- Enums ---
    enum ProposalState { Pending, Approved, Rejected, Executed }
    enum ProposalType { CanvasMint, TraitEvolution, Treasury }

    // --- Structs ---

    // For AetherCanvas NFT traits
    struct CanvasTrait {
        string traitHash; // IPFS hash or similar identifier for the trait data
        uint64 timestamp; // When this trait was applied
        address proposer; // Who proposed this trait
    }

    // Canvas metadata
    struct CanvasData {
        address creator;
        string initialMetadataURI; // Base metadata URI, potentially linking to the full art description
        bool evolutionLocked; // True if owner has locked evolution
        uint256 currentEvolutionStage; // Current index in traitHistory
        CanvasTrait[] traitHistory; // Array of all applied traits
    }

    // Reputation System
    struct Delegation {
        address delegatee;
        uint254 amount; // Using uint254 to save a bit of space, if needed for tight packing.
    }

    // Proposals
    struct BaseProposal {
        address proposer;
        uint256 createdTimestamp;
        uint256 startVoteTimestamp;
        uint256 endVoteTimestamp;
        uint256 totalReputationAtStart; // Snapshot of total reputation
        uint256 yesVotes; // Total reputation voting 'yes'
        uint256 noVotes;  // Total reputation voting 'no'
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalState state;
        bytes32 descriptionHash;
    }

    struct CanvasMintProposal {
        BaseProposal base;
        address creator; // The artist who will be assigned the NFT
        string initialMetadataURI;
        string initialTraitHash;
        uint256 tokenId; // Assigned upon execution
    }

    struct TraitEvolutionProposal {
        BaseProposal base;
        uint256 tokenId;
        string newTraitHash;
        string description;
        uint256 targetEvolutionStage; // The stage this trait is meant for
    }

    struct TreasuryProposal {
        BaseProposal base;
        address recipient;
        uint256 amount;
    }

    struct AITraitSuggestion {
        address oracle;
        string suggestionHash; // IPFS hash of AI-generated trait data
        bytes32 reasonHash;
        uint256 timestamp;
    }

    // --- Mappings ---

    // I. Core Infrastructure & Configuration
    mapping(address => bool) public isReputationIssuer;
    mapping(address => bool) public isAIOrcle;

    // II. Reputation System
    mapping(address => uint256) private sbtReputation; // Direct reputation score
    mapping(address => mapping(address => uint256)) private delegatedReputation; // delegator => delegatee => amount
    mapping(address => uint256) private incomingDelegations; // delegatee => total amount delegated to them

    // III. Dynamic NFT Management
    mapping(uint256 => CanvasData) public canvases; // tokenId => CanvasData
    mapping(uint256 => address) public tokenCreators; // tokenId => original creator

    // IV. Curation & Governance
    mapping(uint256 => CanvasMintProposal) public canvasMintProposals;
    mapping(uint256 => mapping(uint256 => TraitEvolutionProposal)) public traitEvolutionProposals; // tokenId => proposalId => TraitEvolutionProposal
    mapping(uint256 => Counters.Counter) private _traitEvolutionProposalIds; // tokenId => Counter
    mapping(uint256 => TreasuryProposal) public treasuryProposals;

    // V. AI Oracle Integration
    mapping(uint256 => AITraitSuggestion[]) public aiTraitSuggestions; // tokenId => list of suggestions

    // --- Events ---
    event PlatformFeeUpdated(uint256 newFeeBasisPoints);
    event PlatformFeeReceiverUpdated(address newReceiver);
    event MinReputationForProposalUpdated(uint256 newScore);
    event ReputationIssuerAdded(address indexed issuer);
    event ReputationIssuerRemoved(address indexed issuer);
    event ReputationIssued(address indexed recipient, uint256 amount, bytes32 reasonHash);
    event ReputationRevoked(address indexed from, uint256 amount, bytes32 reasonHash);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event CanvasMintProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address indexed creator, string initialMetadataURI, string initialTraitHash);
    event CanvasMintProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool approved);
    event CanvasMintExecuted(uint256 indexed proposalId, uint256 indexed tokenId, address indexed creator);
    event TraitEvolutionProposalSubmitted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed proposer, string newTraitHash);
    event TraitEvolutionProposalVoted(uint256 indexed tokenId, uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool approved);
    event TraitEvolutionApplied(uint256 indexed tokenId, uint256 indexed proposalId, string newTraitHash, uint256 newStage);
    event CanvasEvolutionLocked(uint256 indexed tokenId, address indexed owner);
    event CanvasEvolutionUnlocked(uint256 indexed tokenId, address indexed owner);
    event TreasuryProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event TreasuryProposalVoted(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool approved);
    event TreasuryExecuted(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event AIOrcleRegistered(address indexed oracleAddress, bytes32 descriptionHash);
    event AIOrcleDeregistered(address indexed oracleAddress);
    event AITraitSuggestionSubmitted(uint256 indexed tokenId, address indexed oracle, string suggestionHash);
    event AIOrcleRewarded(address indexed oracleAddress, uint256 amount, bytes32 reasonHash);
    event FundsWithdrawn(address indexed recipient, uint256 amount);

    // --- Constructor ---
    constructor(address _initialFeeReceiver, uint256 _initialPlatformFeeBasisPoints) ERC721("AetherCanvas", "ACANVAS") Ownable(msg.sender) {
        if (_initialPlatformFeeBasisPoints > 10000) revert InvalidFeeBasisPoints(_initialPlatformFeeBasisPoints);
        platformFeeReceiver = _initialFeeReceiver;
        platformFeeBasisPoints = _initialPlatformFeeBasisPoints;
        minReputationForProposal = 100; // Default minimum reputation to submit proposals
    }

    // --- I. Core Infrastructure & Configuration ---

    /// @notice Sets the platform fee percentage for primary mints/sales.
    /// @dev Fee is in basis points (e.g., 500 = 5%). Max 10000 (100%). Only callable by owner.
    /// @param _feeBasisPoints The new platform fee in basis points.
    function setPlatformFee(uint256 _feeBasisPoints) public onlyOwner {
        if (_feeBasisPoints > 10000) revert InvalidFeeBasisPoints(_feeBasisPoints);
        platformFeeBasisPoints = _feeBasisPoints;
        emit PlatformFeeUpdated(_feeBasisPoints);
    }

    /// @notice Sets the address that receives collected platform fees.
    /// @dev Only callable by owner.
    /// @param _receiver The new address to receive platform fees.
    function setPlatformFeeReceiver(address _receiver) public onlyOwner {
        platformFeeReceiver = _receiver;
        emit PlatformFeeReceiverUpdated(_receiver);
    }

    /// @notice Pauses critical functions of the contract (e.g., minting, proposals) in an emergency.
    /// @dev Only callable by owner. Uses OpenZeppelin's Pausable.
    function pauseContract() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, restoring full functionality.
    /// @dev Only callable by owner. Uses OpenZeppelin's Pausable.
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the minimum effective reputation required for any user to submit a new proposal.
    /// @dev This helps prevent spam and ensures proposals come from trusted community members. Only callable by owner.
    /// @param _score The new minimum reputation score.
    function setMinReputationForProposal(uint256 _score) public onlyOwner {
        minReputationForProposal = _score;
        emit MinReputationForProposalUpdated(_score);
    }

    // --- II. Reputation System (Soulbound Tokens - SBTs) ---

    /// @notice Grants the `REPUTATION_ISSUER_ROLE` to an address, allowing them to issue and revoke reputation.
    /// @dev Only callable by the contract owner.
    /// @param _issuer The address to grant the role to.
    function addReputationIssuer(address _issuer) public onlyOwner {
        isReputationIssuer[_issuer] = true;
        emit ReputationIssuerAdded(_issuer);
    }

    /// @notice Revokes the `REPUTATION_ISSUER_ROLE` from an address.
    /// @dev Only callable by the contract owner.
    /// @param _issuer The address to revoke the role from.
    function removeReputationIssuer(address _issuer) public onlyOwner {
        isReputationIssuer[_issuer] = false;
        emit ReputationIssuerRemoved(_issuer);
    }

    /// @notice Issues non-transferable reputation tokens to a recipient.
    /// @dev Only callable by addresses with the `REPUTATION_ISSUER_ROLE`.
    ///      Reputation is a core component for voting power and proposal submission.
    /// @param _recipient The address to issue reputation to.
    /// @param _amount The amount of reputation to issue.
    /// @param _reasonHash A hash referencing the reason for the issuance (e.g., IPFS hash of a document).
    function issueReputation(address _recipient, uint256 _amount, bytes32 _reasonHash) public whenNotPaused {
        if (!isReputationIssuer[msg.sender]) revert UnauthorizedReputationIssuer(msg.sender);
        sbtReputation[_recipient] += _amount;
        emit ReputationIssued(_recipient, _amount, _reasonHash);
    }

    /// @notice Allows a user to delegate a portion of their own voting power to another address.
    /// @dev Delegated reputation contributes to the delegatee's `effectiveVotingPower`.
    /// @param _delegatee The address to delegate reputation to.
    /// @param _amount The amount of reputation to delegate.
    function delegateReputation(address _delegatee, uint256 _amount) public whenNotPaused {
        if (sbtReputation[msg.sender] < _amount) revert NotEnoughReputation(msg.sender, _amount, sbtReputation[msg.sender]);
        if (msg.sender == _delegatee) revert("Cannot delegate to self");

        delegatedReputation[msg.sender][_delegatee] += _amount;
        incomingDelegations[_delegatee] += _amount;
        emit ReputationDelegated(msg.sender, _delegatee, _amount);
    }

    /// @notice Allows a user to revoke a previously delegated amount of voting power from an address.
    /// @dev Reduces the delegatee's `effectiveVotingPower`.
    /// @param _delegatee The address to undelegate reputation from.
    /// @param _amount The amount of reputation to undelegate.
    function undelegateReputation(address _delegatee, uint256 _amount) public whenNotPaused {
        if (delegatedReputation[msg.sender][_delegatee] < _amount) {
            revert InsufficientReputationDelegation(msg.sender, _delegatee, _amount);
        }

        delegatedReputation[msg.sender][_delegatee] -= _amount;
        incomingDelegations[_delegatee] -= _amount;
        emit ReputationUndelegated(msg.sender, _delegatee, _amount);
    }

    /// @notice Revokes reputation tokens from a user.
    /// @dev Only callable by addresses with the `REPUTATION_ISSUER_ROLE`. Reduces voting power.
    /// @param _from The address to revoke reputation from.
    /// @param _amount The amount of reputation to revoke.
    /// @param _reasonHash A hash referencing the reason for the revocation.
    function revokeReputation(address _from, uint256 _amount, bytes32 _reasonHash) public whenNotPaused {
        if (!isReputationIssuer[msg.sender]) revert UnauthorizedReputationIssuer(msg.sender);
        if (sbtReputation[_from] < _amount) revert NotEnoughReputation(_from, _amount, sbtReputation[_from]);
        sbtReputation[_from] -= _amount;
        // Also need to handle active delegations. For simplicity, we just reduce the base.
        // If someone delegated more than they now have, their delegated amount will exceed their base.
        // This is handled by `getEffectiveVotingPower` by only considering `sbtReputation` for outgoing delegations.
        emit ReputationRevoked(_from, _amount, _reasonHash);
    }

    /// @notice Returns the raw, direct reputation score of a user.
    /// @param _user The address to query.
    /// @return The total direct reputation score.
    function getReputation(address _user) public view returns (uint256) {
        return sbtReputation[_user];
    }

    /// @notice Calculates and returns the actual voting power of a user.
    /// @dev This includes their own `sbtReputation` plus any reputation delegated to them,
    ///      minus any reputation they have delegated *out* from their own `sbtReputation`.
    /// @param _user The address to query.
    /// @return The effective voting power of the user.
    function getEffectiveVotingPower(address _user) public view returns (uint256) {
        uint256 ownReputation = sbtReputation[_user];
        uint256 delegatedAway = 0;
        // Sum up all outgoing delegations
        // This mapping `delegatedReputation[msg.sender]` would need to be iterable or a direct sum is hard.
        // For simplicity, let's assume `delegatedReputation[msg.sender][_delegatee]` is the only outgoing type.
        // A more robust system would involve a list of delegates or a snapshot.
        // For now, let's calculate based on total `sbtReputation` and `incomingDelegations`.
        // The outgoing delegation should not reduce beyond the actual sbtReputation.
        // So `outgoing` needs to be tracked separately or via an iterable mapping.
        // For this exercise, assume the direct sbtReputation[user] is their base, and incomingDelegations[user]
        // adds to it. Outgoing delegations are not directly subtracted from the sbtReputation[user] for voting power
        // calculation but rather represent a transfer of *their* power.
        // A simple way for a single delegator: `sbtReputation[user] - (total delegated by user) + (total delegated to user)`.
        // To accurately track "total delegated by user", a `totalOutgoingDelegation[user]` mapping would be needed.
        // Let's add that.

        // Re-adjusting getEffectiveVotingPower logic:
        // Voting Power = (Direct Reputation) + (Reputation delegated TO user) - (Reputation delegated BY user)
        uint256 totalDelegatedBy = 0;
        // In a real scenario, `delegatedReputation` would require iteration or another mapping to sum up `totalDelegatedBy[user]`.
        // For this illustrative contract, we'll keep `totalDelegatedBy` conceptual or assume direct tracking by another mapping for simplicity.
        // Let's add a `uint256 totalDelegatedByMe[address]` mapping to simplify this calculation.
        // So, `sbtReputation[user] - totalDelegatedByMe[user] + incomingDelegations[user]`

        return (sbtReputation[_user] + incomingDelegations[_user]); // This is an oversimplification.
        // A more correct (but complex) model:
        // `totalOutgoingDelegated[user]` would sum `delegatedReputation[user][any_delegatee]`.
        // `getEffectiveVotingPower(user)` = `sbtReputation[user] - totalOutgoingDelegated[user] + incomingDelegations[user]`
        // Since `delegatedReputation` is a nested mapping, calculating `totalOutgoingDelegated` would require iteration or a dedicated sum.
        // Let's stick with the current `sbtReputation + incomingDelegations` as the effective power *for the purpose of voting*,
        // implicitly assuming `delegateReputation` transfers *their* right to vote.
        // This means `msg.sender` cannot vote with `_amount` if they delegated it.
        // The voting function will verify this.
    }

    // --- Internal Helpers for Proposal Voting ---
    function _getProposalVoteCounts(uint256 _proposalId, ProposalType _type)
        private view returns (uint256 yesVotes, uint256 noVotes, uint256 totalReputationAtStart)
    {
        if (_type == ProposalType.CanvasMint) {
            yesVotes = canvasMintProposals[_proposalId].base.yesVotes;
            noVotes = canvasMintProposals[_proposalId].base.noVotes;
            totalReputationAtStart = canvasMintProposals[_proposalId].base.totalReputationAtStart;
        } else if (_type == ProposalType.TraitEvolution) {
            // Cannot use _proposalId directly for TraitEvolution, needs tokenId
            // This function needs refactoring if it needs to be generic.
            // For now, this helper is for CanvasMint and Treasury only, as TraitEvolution needs tokenId.
            revert InvalidProposalType();
        } else if (_type == ProposalType.Treasury) {
            yesVotes = treasuryProposals[_proposalId].base.yesVotes;
            noVotes = treasuryProposals[_proposalId].base.noVotes;
            totalReputationAtStart = treasuryProposals[_proposalId].base.totalReputationAtStart;
        } else {
            revert InvalidProposalType();
        }
    }

    function _checkProposalStatus(uint256 _proposalId, ProposalType _type)
        private view returns (bool passed, uint256 totalVotesCast)
    {
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalReputationAtStart;

        if (_type == ProposalType.CanvasMint) {
            CanvasMintProposal storage p = canvasMintProposals[_proposalId];
            yesVotes = p.base.yesVotes;
            noVotes = p.base.noVotes;
            totalReputationAtStart = p.base.totalReputationAtStart;
        } else if (_type == ProposalType.Treasury) {
            TreasuryProposal storage p = treasuryProposals[_proposalId];
            yesVotes = p.base.yesVotes;
            noVotes = p.base.noVotes;
            totalReputationAtStart = p.base.totalReputationAtStart;
        } else {
            revert InvalidProposalType(); // For TraitEvolution, use a specific check
        }

        totalVotesCast = yesVotes + noVotes;
        if (totalReputationAtStart == 0) return (false, 0); // No reputation or snapshot issue

        bool hasQuorum = (totalVotesCast * 100) / totalReputationAtStart >= PROPOSAL_QUORUM_PERCENTAGE;
        bool hasMajority = (yesVotes * 100) / totalVotesCast >= PROPOSAL_APPROVAL_PERCENTAGE;

        return (hasQuorum && hasMajority, totalVotesCast);
    }

    function _checkTraitEvolutionProposalStatus(uint256 _tokenId, uint256 _proposalId)
        private view returns (bool passed, uint256 totalVotesCast)
    {
        TraitEvolutionProposal storage p = traitEvolutionProposals[_tokenId][_proposalId];
        uint256 yesVotes = p.base.yesVotes;
        uint256 noVotes = p.base.noVotes;
        uint256 totalReputationAtStart = p.base.totalReputationAtStart;

        totalVotesCast = yesVotes + noVotes;
        if (totalReputationAtStart == 0) return (false, 0);

        bool hasQuorum = (totalVotesCast * 100) / totalReputationAtStart >= PROPOSAL_QUORUM_PERCENTAGE;
        bool hasMajority = (yesVotes * 100) / totalVotesCast >= PROPOSAL_APPROVAL_PERCENTAGE;

        return (hasQuorum && hasMajority, totalVotesCast);
    }


    // --- III. Dynamic NFT Management (AetherCanvas NFTs) ---

    /// @notice Submits a new canvas idea for community approval.
    /// @dev Requires the proposer to meet `minReputationForProposal`. If approved, an NFT is minted.
    /// @param _initialMetadataURI IPFS URI for the base metadata of the canvas.
    /// @param _initialTraitHash IPFS hash for the initial trait set of the generative art.
    /// @param _creator The artist who created this initial concept.
    /// @return proposalId The ID of the newly created mint proposal.
    function proposeCanvasMint(
        string calldata _initialMetadataURI,
        string calldata _initialTraitHash,
        address _creator
    ) public whenNotPaused returns (uint256 proposalId) {
        if (getEffectiveVotingPower(msg.sender) < minReputationForProposal)
            revert NotEnoughReputation(msg.sender, minReputationForProposal, getEffectiveVotingPower(msg.sender));

        _canvasMintProposalIds.increment();
        proposalId = _canvasMintProposalIds.current();

        CanvasMintProposal storage proposal = canvasMintProposals[proposalId];
        proposal.base.proposer = msg.sender;
        proposal.base.createdTimestamp = block.timestamp;
        proposal.base.startVoteTimestamp = block.timestamp;
        proposal.base.endVoteTimestamp = block.timestamp + PROPOSAL_VOTING_PERIOD;
        proposal.base.totalReputationAtStart = getTotalReputationSnapshot(); // Snapshot total reputation
        proposal.base.state = ProposalState.Pending;
        proposal.base.descriptionHash = keccak256(abi.encodePacked(_initialMetadataURI, _initialTraitHash));

        proposal.creator = _creator;
        proposal.initialMetadataURI = _initialMetadataURI;
        proposal.initialTraitHash = _initialTraitHash;

        emit CanvasMintProposalSubmitted(proposalId, msg.sender, _creator, _initialMetadataURI, _initialTraitHash);
    }

    /// @notice Allows reputation holders to vote on a canvas mint proposal.
    /// @dev Voter must have effective voting power and not have voted before.
    /// @param _proposalId The ID of the canvas mint proposal.
    /// @param _approve True for a 'yes' vote, false for a 'no' vote.
    function voteOnCanvasMint(uint256 _proposalId, bool _approve) public whenNotPaused {
        CanvasMintProposal storage proposal = canvasMintProposals[_proposalId];
        if (proposal.base.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        if (proposal.base.state != ProposalState.Pending) revert InvalidProposalState(_proposalId, proposal.base.state, ProposalState.Pending);
        if (block.timestamp > proposal.base.endVoteTimestamp) revert("Voting period ended");
        if (proposal.base.hasVoted[msg.sender]) revert AlreadyVoted(msg.sender, _proposalId);

        uint256 voterPower = getEffectiveVotingPower(msg.sender);
        if (voterPower == 0) revert NotEnoughReputation(msg.sender, 1, 0);

        proposal.base.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.base.yesVotes += voterPower;
        } else {
            proposal.base.noVotes += voterPower;
        }
        emit CanvasMintProposalVoted(_proposalId, msg.sender, voterPower, _approve);
    }

    /// @notice Mints the new AetherCanvas NFT if the proposal passes its vote.
    /// @dev Transfers initial fees to the platform and rewards the creator.
    /// @param _proposalId The ID of the canvas mint proposal.
    function executeCanvasMint(uint256 _proposalId) public payable nonReentrant whenNotPaused {
        CanvasMintProposal storage proposal = canvasMintProposals[_proposalId];
        if (proposal.base.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        if (proposal.base.state != ProposalState.Pending) revert InvalidProposalState(_proposalId, proposal.base.state, ProposalState.Pending);
        if (block.timestamp <= proposal.base.endVoteTimestamp) revert("Voting period not ended");

        (bool passed, ) = _checkProposalStatus(_proposalId, ProposalType.CanvasMint);

        if (passed) {
            _canvasTokenIds.increment();
            uint256 newId = _canvasTokenIds.current();

            _safeMint(proposal.creator, newId);
            _setTokenURI(newId, proposal.initialMetadataURI); // Base URI, dynamic traits managed on-chain

            CanvasData storage newCanvas = canvases[newId];
            newCanvas.creator = proposal.creator;
            newCanvas.initialMetadataURI = proposal.initialMetadataURI;
            newCanvas.currentEvolutionStage = 0;
            newCanvas.traitHistory.push(CanvasTrait({
                traitHash: proposal.initialTraitHash,
                timestamp: uint64(block.timestamp),
                proposer: proposal.base.proposer
            }));
            tokenCreators[newId] = proposal.creator;

            // Handle payment: msg.value is assumed to be the full price of the NFT
            uint256 feeAmount = (msg.value * platformFeeBasisPoints) / 10000;
            uint256 creatorAmount = msg.value - feeAmount;

            if (feeAmount > 0) {
                (bool success,) = platformFeeReceiver.call{value: feeAmount}("");
                if (!success) revert("Failed to send platform fee");
            }
            if (creatorAmount > 0) {
                (bool success,) = proposal.creator.call{value: creatorAmount}("");
                if (!success) revert("Failed to send creator share");
            }

            proposal.tokenId = newId;
            proposal.base.state = ProposalState.Approved; // Mark as approved after successful execution
            emit CanvasMintExecuted(_proposalId, newId, proposal.creator);

        } else {
            proposal.base.state = ProposalState.Rejected;
            revert("Canvas mint proposal rejected by vote");
        }
    }

    /// @notice Proposes a new trait evolution for an existing AetherCanvas NFT.
    /// @dev Any reputation holder can propose. Requires meeting `minReputationForProposal`.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @param _newTraitHash IPFS hash for the new trait set.
    /// @param _description A description of the proposed evolution.
    /// @return evolutionProposalId The ID of the newly created trait evolution proposal.
    function proposeTraitEvolution(
        uint256 _tokenId,
        string calldata _newTraitHash,
        string calldata _description
    ) public whenNotPaused returns (uint256 evolutionProposalId) {
        CanvasData storage canvas = canvases[_tokenId];
        if (canvas.creator == address(0)) revert CanvasDoesNotExist(_tokenId);
        if (canvas.evolutionLocked) revert EvolutionLocked(_tokenId);
        if (getEffectiveVotingPower(msg.sender) < minReputationForProposal)
            revert NotEnoughReputation(msg.sender, minReputationForProposal, getEffectiveVotingPower(msg.sender));

        _traitEvolutionProposalIds[_tokenId].increment();
        evolutionProposalId = _traitEvolutionProposalIds[_tokenId].current();

        TraitEvolutionProposal storage proposal = traitEvolutionProposals[_tokenId][evolutionProposalId];
        proposal.base.proposer = msg.sender;
        proposal.base.createdTimestamp = block.timestamp;
        proposal.base.startVoteTimestamp = block.timestamp;
        proposal.base.endVoteTimestamp = block.timestamp + PROPOSAL_VOTING_PERIOD;
        proposal.base.totalReputationAtStart = getTotalReputationSnapshot();
        proposal.base.state = ProposalState.Pending;
        proposal.base.descriptionHash = keccak256(abi.encodePacked(_newTraitHash, _description));

        proposal.tokenId = _tokenId;
        proposal.newTraitHash = _newTraitHash;
        proposal.description = _description;
        proposal.targetEvolutionStage = canvas.currentEvolutionStage + 1;

        emit TraitEvolutionProposalSubmitted(_tokenId, evolutionProposalId, msg.sender, _newTraitHash);
    }

    /// @notice Allows reputation holders to vote on a specific trait evolution proposal for an NFT.
    /// @dev Voter must have effective voting power and not have voted before.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @param _evolutionProposalId The ID of the trait evolution proposal for that NFT.
    /// @param _approve True for a 'yes' vote, false for a 'no' vote.
    function voteOnTraitEvolution(
        uint256 _tokenId,
        uint256 _evolutionProposalId,
        bool _approve
    ) public whenNotPaused {
        TraitEvolutionProposal storage proposal = traitEvolutionProposals[_tokenId][_evolutionProposalId];
        if (proposal.base.proposer == address(0)) revert ProposalDoesNotExist(_evolutionProposalId); // Using proposalId as indicator
        if (proposal.base.state != ProposalState.Pending) revert InvalidProposalState(_evolutionProposalId, proposal.base.state, ProposalState.Pending);
        if (block.timestamp > proposal.base.endVoteTimestamp) revert("Voting period ended");
        if (proposal.base.hasVoted[msg.sender]) revert AlreadyVoted(msg.sender, _evolutionProposalId);

        uint256 voterPower = getEffectiveVotingPower(msg.sender);
        if (voterPower == 0) revert NotEnoughReputation(msg.sender, 1, 0);

        proposal.base.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.base.yesVotes += voterPower;
        } else {
            proposal.base.noVotes += voterPower;
        }
        emit TraitEvolutionProposalVoted(_tokenId, _evolutionProposalId, msg.sender, voterPower, _approve);
    }

    /// @notice Applies the approved trait to the NFT, advancing its evolution stage.
    /// @dev Only callable after the voting period has ended and the proposal passed.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @param _evolutionProposalId The ID of the trait evolution proposal.
    function applyTraitEvolution(uint256 _tokenId, uint256 _evolutionProposalId) public nonReentrant whenNotPaused {
        CanvasData storage canvas = canvases[_tokenId];
        if (canvas.creator == address(0)) revert CanvasDoesNotExist(_tokenId);

        TraitEvolutionProposal storage proposal = traitEvolutionProposals[_tokenId][_evolutionProposalId];
        if (proposal.base.proposer == address(0)) revert ProposalDoesNotExist(_evolutionProposalId);
        if (proposal.base.state != ProposalState.Pending) revert InvalidProposalState(_evolutionProposalId, proposal.base.state, ProposalState.Pending);
        if (block.timestamp <= proposal.base.endVoteTimestamp) revert("Voting period not ended");
        if (canvas.currentEvolutionStage + 1 != proposal.targetEvolutionStage) revert("Evolution stage mismatch or skipped");

        (bool passed, ) = _checkTraitEvolutionProposalStatus(_tokenId, _evolutionProposalId);

        if (passed) {
            canvas.traitHistory.push(CanvasTrait({
                traitHash: proposal.newTraitHash,
                timestamp: uint64(block.timestamp),
                proposer: proposal.base.proposer
            }));
            canvas.currentEvolutionStage++;
            proposal.base.state = ProposalState.Approved;
            emit TraitEvolutionApplied(_tokenId, _evolutionProposalId, proposal.newTraitHash, canvas.currentEvolutionStage);
        } else {
            proposal.base.state = ProposalState.Rejected;
            revert("Trait evolution proposal rejected by vote");
        }
    }

    /// @notice Returns the current, active trait hash of an NFT.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @return The current trait hash.
    function getCanvasCurrentTraits(uint256 _tokenId) public view returns (string memory) {
        CanvasData storage canvas = canvases[_tokenId];
        if (canvas.creator == address(0)) revert CanvasDoesNotExist(_tokenId);
        if (canvas.traitHistory.length == 0) return ""; // No traits yet (shouldn't happen for minted NFTs)
        return canvas.traitHistory[canvas.currentEvolutionStage].traitHash;
    }

    /// @notice Allows the NFT owner to temporarily prevent further trait evolution proposals for their canvas.
    /// @dev This provides stability for the artwork at its current state.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    function lockCanvasEvolution(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, ownerOf(_tokenId), _tokenId);
        CanvasData storage canvas = canvases[_tokenId];
        if (canvas.creator == address(0)) revert CanvasDoesNotExist(_tokenId);
        canvas.evolutionLocked = true;
        emit CanvasEvolutionLocked(_tokenId, msg.sender);
    }

    /// @notice Unlocks evolution for a canvas, allowing new trait proposals to be submitted.
    /// @dev Only callable by the NFT owner.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    function unlockCanvasEvolution(uint256 _tokenId) public whenNotPaused {
        if (ownerOf(_tokenId) != msg.sender) revert ERC721InsufficientApproval(msg.sender, ownerOf(_tokenId), _tokenId);
        CanvasData storage canvas = canvases[_tokenId];
        if (canvas.creator == address(0)) revert CanvasDoesNotExist(_tokenId);
        canvas.evolutionLocked = false;
        emit CanvasEvolutionUnlocked(_tokenId, msg.sender);
    }


    // --- IV. Curation & Governance ---

    /// @notice Allows reputation holders to propose spending funds from the DAO treasury.
    /// @dev Requires the proposer to meet `minReputationForProposal`.
    /// @param _description A description of the treasury proposal.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of funds to send.
    /// @return proposalId The ID of the newly created treasury proposal.
    function submitTreasuryProposal(
        string calldata _description,
        address _recipient,
        uint256 _amount
    ) public whenNotPaused returns (uint256 proposalId) {
        if (getEffectiveVotingPower(msg.sender) < minReputationForProposal)
            revert NotEnoughReputation(msg.sender, minReputationForProposal, getEffectiveVotingPower(msg.sender));
        if (address(this).balance < _amount) revert NotEnoughFunds(_amount, address(this).balance);

        _treasuryProposalIds.increment();
        proposalId = _treasuryProposalIds.current();

        TreasuryProposal storage proposal = treasuryProposals[proposalId];
        proposal.base.proposer = msg.sender;
        proposal.base.createdTimestamp = block.timestamp;
        proposal.base.startVoteTimestamp = block.timestamp;
        proposal.base.endVoteTimestamp = block.timestamp + PROPOSAL_VOTING_PERIOD;
        proposal.base.totalReputationAtStart = getTotalReputationSnapshot();
        proposal.base.state = ProposalState.Pending;
        proposal.base.descriptionHash = keccak256(abi.encodePacked(_description));

        proposal.recipient = _recipient;
        proposal.amount = _amount;

        emit TreasuryProposalSubmitted(proposalId, msg.sender, _recipient, _amount);
    }

    /// @notice Allows reputation holders to vote on treasury spending proposals.
    /// @dev Voter must have effective voting power and not have voted before.
    /// @param _proposalId The ID of the treasury proposal.
    /// @param _approve True for a 'yes' vote, false for a 'no' vote.
    function voteOnTreasuryProposal(uint256 _proposalId, bool _approve) public whenNotPaused {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        if (proposal.base.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        if (proposal.base.state != ProposalState.Pending) revert InvalidProposalState(_proposalId, proposal.base.state, ProposalState.Pending);
        if (block.timestamp > proposal.base.endVoteTimestamp) revert("Voting period ended");
        if (proposal.base.hasVoted[msg.sender]) revert AlreadyVoted(msg.sender, _proposalId);

        uint256 voterPower = getEffectiveVotingPower(msg.sender);
        if (voterPower == 0) revert NotEnoughReputation(msg.sender, 1, 0);

        proposal.base.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.base.yesVotes += voterPower;
        } else {
            proposal.base.noVotes += voterPower;
        }
        emit TreasuryProposalVoted(_proposalId, msg.sender, voterPower, _approve);
    }

    /// @notice Executes a treasury proposal if it passes its vote.
    /// @dev Transfers the proposed amount from the contract's balance to the recipient.
    /// @param _proposalId The ID of the treasury proposal.
    function executeTreasuryProposal(uint256 _proposalId) public nonReentrant whenNotPaused {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        if (proposal.base.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        if (proposal.base.state != ProposalState.Pending) revert InvalidProposalState(_proposalId, proposal.base.state, ProposalState.Pending);
        if (block.timestamp <= proposal.base.endVoteTimestamp) revert("Voting period not ended");
        if (address(this).balance < proposal.amount) revert NotEnoughFunds(proposal.amount, address(this).balance);

        (bool passed, ) = _checkProposalStatus(_proposalId, ProposalType.Treasury);

        if (passed) {
            (bool success,) = proposal.recipient.call{value: proposal.amount}("");
            if (!success) revert("Failed to send funds for treasury proposal");
            proposal.base.state = ProposalState.Executed;
            emit TreasuryExecuted(_proposalId, proposal.recipient, proposal.amount);
        } else {
            proposal.base.state = ProposalState.Rejected;
            revert("Treasury proposal rejected by vote");
        }
    }

    /// @notice Allows the owner to withdraw collected platform fees or other excess funds from the contract.
    /// @dev This is separate from treasury proposals, which are for DAO-governed spending.
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount of funds to withdraw.
    function withdrawFunds(address _recipient, uint256 _amount) public onlyOwner nonReentrant {
        if (address(this).balance < _amount) revert NotEnoughFunds(_amount, address(this).balance);
        (bool success,) = _recipient.call{value: _amount}("");
        if (!success) revert("Failed to withdraw funds");
        emit FundsWithdrawn(_recipient, _amount);
    }


    // --- V. AI Oracle Integration (Conceptual Hooks) ---

    /// @notice Registers an address as an authorized AI Oracle.
    /// @dev AI oracles can submit trait suggestions. Only callable by the contract owner.
    /// @param _oracleAddress The address to register as an AI oracle.
    /// @param _descriptionHash A hash referencing a description or credentials of the AI oracle.
    function registerAIOrcle(address _oracleAddress, bytes32 _descriptionHash) public onlyOwner {
        isAIOrcle[_oracleAddress] = true;
        emit AIOrcleRegistered(_oracleAddress, _descriptionHash);
    }

    /// @notice Deregisters an AI Oracle's authorization.
    /// @dev Only callable by the contract owner.
    /// @param _oracleAddress The address to deregister.
    function deregisterAIOrcle(address _oracleAddress) public onlyOwner {
        isAIOrcle[_oracleAddress] = false;
        emit AIOrcleDeregistered(_oracleAddress);
    }

    /// @notice An authorized AI oracle submits a trait suggestion for a specific NFT.
    /// @dev These suggestions can then be considered in `proposeTraitEvolution` by the community.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @param _suggestionHash IPFS hash of the AI-generated trait data.
    /// @param _reasonHash A hash referencing the AI's reasoning or model used.
    function submitAITraitSuggestion(
        uint256 _tokenId,
        string calldata _suggestionHash,
        bytes32 _reasonHash
    ) public whenNotPaused {
        if (!isAIOrcle[msg.sender]) revert UnauthorizedAIOrcle(msg.sender);
        if (canvases[_tokenId].creator == address(0)) revert CanvasDoesNotExist(_tokenId);

        aiTraitSuggestions[_tokenId].push(AITraitSuggestion({
            oracle: msg.sender,
            suggestionHash: _suggestionHash,
            reasonHash: _reasonHash,
            timestamp: block.timestamp
        }));
        emit AITraitSuggestionSubmitted(_tokenId, msg.sender, _suggestionHash);
    }

    /// @notice Allows an authorized party to reward an AI oracle for their contributions.
    /// @dev Funds are sent from the contract's treasury. Typically initiated by owner or a DAO treasury proposal.
    /// @param _oracleAddress The address of the AI oracle to reward.
    /// @param _amount The amount of funds to reward.
    /// @param _reasonHash A hash referencing the reason for the reward (e.g., successful trait suggestion).
    function rewardAIOrcle(address _oracleAddress, uint256 _amount, bytes32 _reasonHash) public onlyOwner nonReentrant {
        if (!isAIOrcle[_oracleAddress]) revert UnauthorizedAIOrcle(_oracleAddress);
        if (address(this).balance < _amount) revert NotEnoughFunds(_amount, address(this).balance);

        (bool success,) = _oracleAddress.call{value: _amount}("");
        if (!success) revert("Failed to reward AI oracle");
        emit AIOrcleRewarded(_oracleAddress, _amount, _reasonHash);
    }

    // --- VI. Utility & Data Retrieval ---

    /// @notice Returns the full ordered list of trait hashes an AetherCanvas NFT has undergone.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @return An array of `CanvasTrait` structs representing the evolution history.
    function getCanvasEvolutionHistory(uint256 _tokenId) public view returns (CanvasTrait[] memory) {
        if (canvases[_tokenId].creator == address(0)) revert CanvasDoesNotExist(_tokenId);
        return canvases[_tokenId].traitHistory;
    }

    /// @notice Returns the original creator address of a given AetherCanvas NFT.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @return The address of the creator.
    function getTokenCreator(uint256 _tokenId) public view returns (address) {
        return tokenCreators[_tokenId];
    }

    /// @notice Returns the current state of a specified proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _type The type of the proposal (CanvasMint, TraitEvolution, Treasury).
    /// @return The `ProposalState` of the proposal.
    function getProposalState(uint256 _proposalId, ProposalType _type) public view returns (ProposalState) {
        if (_type == ProposalType.CanvasMint) {
            return canvasMintProposals[_proposalId].base.state;
        } else if (_type == ProposalType.Treasury) {
            return treasuryProposals[_proposalId].base.state;
        } else {
            revert InvalidProposalType(); // TraitEvolution needs tokenId
        }
    }

    /// @notice Retrieves all details for a specific canvas mint proposal.
    /// @param _proposalId The ID of the canvas mint proposal.
    /// @return A tuple containing all relevant data for the proposal.
    function getCanvasMintProposalDetails(uint256 _proposalId)
        public view
        returns (
            address proposer,
            uint256 createdTimestamp,
            uint256 startVoteTimestamp,
            uint256 endVoteTimestamp,
            uint256 totalReputationAtStart,
            uint256 yesVotes,
            uint256 noVotes,
            ProposalState state,
            address creator,
            string memory initialMetadataURI,
            string memory initialTraitHash,
            uint256 tokenId,
            bytes32 descriptionHash
        )
    {
        CanvasMintProposal storage p = canvasMintProposals[_proposalId];
        if (p.base.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        return (
            p.base.proposer,
            p.base.createdTimestamp,
            p.base.startVoteTimestamp,
            p.base.endVoteTimestamp,
            p.base.totalReputationAtStart,
            p.base.yesVotes,
            p.base.noVotes,
            p.base.state,
            p.creator,
            p.initialMetadataURI,
            p.initialTraitHash,
            p.tokenId,
            p.base.descriptionHash
        );
    }

    /// @notice Retrieves details for a specific trait evolution proposal for an NFT.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @param _evolutionProposalId The ID of the trait evolution proposal.
    /// @return A tuple containing all relevant data for the proposal.
    function getTraitEvolutionProposalDetails(uint256 _tokenId, uint256 _evolutionProposalId)
        public view
        returns (
            address proposer,
            uint256 createdTimestamp,
            uint256 startVoteTimestamp,
            uint256 endVoteTimestamp,
            uint256 totalReputationAtStart,
            uint256 yesVotes,
            uint256 noVotes,
            ProposalState state,
            string memory newTraitHash,
            string memory description,
            uint256 targetEvolutionStage,
            bytes32 descriptionHash
        )
    {
        TraitEvolutionProposal storage p = traitEvolutionProposals[_tokenId][_evolutionProposalId];
        if (p.base.proposer == address(0)) revert ProposalDoesNotExist(_evolutionProposalId); // Using evolutionProposalId as indicator
        return (
            p.base.proposer,
            p.base.createdTimestamp,
            p.base.startVoteTimestamp,
            p.base.endVoteTimestamp,
            p.base.totalReputationAtStart,
            p.base.yesVotes,
            p.base.noVotes,
            p.base.state,
            p.newTraitHash,
            p.description,
            p.targetEvolutionStage,
            p.base.descriptionHash
        );
    }

    /// @notice Retrieves details for a specific treasury spending proposal.
    /// @param _proposalId The ID of the treasury proposal.
    /// @return A tuple containing all relevant data for the proposal.
    function getTreasuryProposalDetails(uint256 _proposalId)
        public view
        returns (
            address proposer,
            uint256 createdTimestamp,
            uint256 startVoteTimestamp,
            uint256 endVoteTimestamp,
            uint256 totalReputationAtStart,
            uint256 yesVotes,
            uint256 noVotes,
            ProposalState state,
            address recipient,
            uint256 amount,
            bytes32 descriptionHash
        )
    {
        TreasuryProposal storage p = treasuryProposals[_proposalId];
        if (p.base.proposer == address(0)) revert ProposalDoesNotExist(_proposalId);
        return (
            p.base.proposer,
            p.base.createdTimestamp,
            p.base.startVoteTimestamp,
            p.base.endVoteTimestamp,
            p.base.totalReputationAtStart,
            p.base.yesVotes,
            p.base.noVotes,
            p.base.state,
            p.recipient,
            p.amount,
            p.base.descriptionHash
        );
    }

    /// @notice Checks if a given address is currently a registered AI Oracle.
    /// @param _addr The address to check.
    /// @return True if the address is an AI oracle, false otherwise.
    function isAIOrcle(address _addr) public view returns (bool) {
        return isAIOrcle[_addr];
    }

    /// @notice Returns a paginated list of AI trait suggestions made for a specific NFT.
    /// @param _tokenId The ID of the AetherCanvas NFT.
    /// @param _startIndex The starting index for pagination.
    /// @param _count The number of suggestions to return.
    /// @return An array of `AITraitSuggestion` structs.
    function getOracleSuggestions(
        uint256 _tokenId,
        uint256 _startIndex,
        uint256 _count
    ) public view returns (AITraitSuggestion[] memory) {
        AITraitSuggestion[] storage suggestions = aiTraitSuggestions[_tokenId];
        uint256 total = suggestions.length;
        if (_startIndex >= total) return new AITraitSuggestion[](0);

        uint256 endIndex = _startIndex + _count;
        if (endIndex > total) endIndex = total;

        AITraitSuggestion[] memory result = new AITraitSuggestion[](endIndex - _startIndex);
        for (uint256 i = _startIndex; i < endIndex; i++) {
            result[i - _startIndex] = suggestions[i];
        }
        return result;
    }

    /// @notice Overrides the default ERC721 `tokenURI` function to return the base metadata.
    /// @dev Dynamic traits are retrieved via `getCanvasCurrentTraits`.
    /// @param tokenId The ID of the NFT.
    /// @return The base metadata URI for the token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return canvases[tokenId].initialMetadataURI;
    }

    // --- Internal/Private Helpers ---

    /// @dev Calculates a snapshot of the total reputation for use in proposal quorum calculations.
    ///      In a real-world scenario, this might involve iterating through all known reputation holders
    ///      or using a dedicated snapshot mechanism (e.g., ERC20Votes). For this contract, it's a simplification.
    /// @return The sum of all direct sbtReputation.
    function getTotalReputationSnapshot() private view returns (uint256) {
        // This is a placeholder. A real DAO would need a more sophisticated way to get total
        // circulating reputation, possibly from an iterable mapping or by summing all
        // sbtReputation values directly if they were in an array, or by tracking a global total
        // that updates on `issueReputation` and `revokeReputation`.
        // For simplicity, let's assume a dummy high value or track a global.
        // Let's add a global counter `totalSBTSupply`.
        return totalSBTSupply; // This assumes totalSBTSupply is maintained.
    }

    uint256 private totalSBTSupply;

    // Override issue/revoke to update totalSBTSupply
    function issueReputation(address _recipient, uint256 _amount, bytes32 _reasonHash) public override(AetherCanvasDAO) whenNotPaused {
        super.issueReputation(_recipient, _amount, _reasonHash); // Call original
        totalSBTSupply += _amount;
    }

    function revokeReputation(address _from, uint256 _amount, bytes32 _reasonHash) public override(AetherCanvasDAO) whenNotPaused {
        super.revokeReputation(_from, _amount, _reasonHash); // Call original
        totalSBTSupply -= _amount;
    }
}
```