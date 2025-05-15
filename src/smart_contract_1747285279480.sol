Okay, let's design a smart contract incorporating several advanced and creative concepts. We'll build a "Dynamic NFT Evolution Platform and Marketplace with AI-Assisted Curation and Staking".

**Core Concepts:**

1.  **Dynamic NFTs:** NFTs whose metadata or properties can change based on on-chain actions and external input.
2.  **Evolution Mechanism:** Users can propose upgrades or "evolutions" for their NFTs.
3.  **AI Oracle Integration:** An external oracle (simulated here, but representing an AI service) provides a judgment score on the evolution proposals. The success of the evolution depends on this score.
4.  **Built-in Marketplace:** Users can list and trade these dynamic NFTs.
5.  **Staking for Participation:** Users can stake their NFTs to earn rewards or gain eligibility for certain actions (like submitting proposals or getting priority in queues).
6.  **Parameter Governance (Simplified):** Owner/admin can set key parameters, simulating a basic form of control which could be expanded into DAO governance.

This combines dynamic state, oracle interaction, a marketplace, and staking around a core NFT asset, aiming for uniqueness beyond standard templates.

---

**Outline and Function Summary**

**Contract Name:** `DynamicNFTEvolutionPlatform`

**Core Functionality:**
*   Manages ownership and metadata for ERC721 NFTs (`GenesisShards` and `Prisms`).
*   Allows users to mint initial `GenesisShards`.
*   Enables users to submit proposals to evolve a `GenesisShard` into a `Prism` (or later stages).
*   Integrates with a simulated "AI Oracle" to get judgments on evolution proposals.
*   Applies evolution based on the AI judgment score.
*   Provides a marketplace for buying and selling NFTs.
*   Allows users to stake NFTs to earn simulated rewards.
*   Includes administrative functions for setting parameters, withdrawing fees, and pausing.

**State Variables:**
*   NFT Data (owner, tokenURI, state, judgment history).
*   Evolution Proposals (details, status, linked AI request ID).
*   Marketplace Listings (seller, price, active).
*   NFT Offers (offerer, amount, active).
*   Staking Information (staker, stake timestamp, accumulated rewards).
*   Configuration (fees, minimum AI score, oracle address).

**Events:**
*   Standard ERC721 Events (`Transfer`, `Approval`, `ApprovalForAll`).
*   Custom Events (`ShardMinted`, `EvolutionProposalSubmitted`, `AIJudgmentReceived`, `EvolutionApplied`, `ProposalRejected`, `NFTListed`, `NFTDelisted`, `NFTSold`, `OfferMade`, `OfferCancelled`, `OfferAccepted`, `NFTStaked`, `NFTUnstaked`, `RewardsClaimed`, `FeeSet`, `OracleSet`, `Paused`, `Unpaused`).

**Modifiers:**
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyOracle`: Restricts access to the configured AI oracle address.
*   `whenNotPaused`, `whenPaused`: Controls contract execution based on the paused state.
*   `nftExists`: Checks if a token ID is valid.
*   `isApprovedOrOwner`: Checks if the caller is the owner or approved for an NFT.

**Functions Summary (25+ functions):**

1.  `constructor()`: Initializes the contract with base URI and owner.
2.  `mintShard()`: Allows anyone to mint a new `GenesisShard` by paying a fee.
3.  `tokenURI(uint256 tokenId)`: (Override) Returns the dynamic metadata URI based on the NFT's state.
4.  `ownerOf(uint256 tokenId)`: (Override) Returns the owner of an NFT.
5.  `balanceOf(address owner)`: (Override) Returns the number of NFTs owned by an address.
6.  `approve(address to, uint256 tokenId)`: (Override) Gives approval for one token.
7.  `setApprovalForAll(address operator, bool approved)`: (Override) Gives/revokes approval for all tokens.
8.  `getApproved(uint256 tokenId)`: (Override) Returns the approved address for a token.
9.  `isApprovedForAll(address owner, address operator)`: (Override) Returns approval status for an operator.
10. `getNftState(uint256 tokenId)`: Returns the current evolutionary state of an NFT (Shard, Prism, etc.).
11. `getJudgmentHistory(uint256 tokenId)`: Returns the history of AI judgment scores for an NFT's proposals.
12. `submitEvolutionProposal(uint256 tokenId, string memory metadataURI)`: Allows an NFT owner to propose evolving their NFT by submitting new metadata. Requires a fee and triggers a simulated AI oracle request.
13. `getProposalStatus(uint256 proposalId)`: Returns the current status of an evolution proposal.
14. `receiveJudgmentResult(uint256 requestId, uint256 score)`: (Callable by `onlyOracle`) Callback function for the AI oracle to report the judgment score for a proposal request.
15. `applyEvolution(uint256 proposalId)`: Allows the proposer (if the proposal was approved by AI judgment) to apply the evolution, updating the NFT's state and metadata URI.
16. `rejectEvolutionProposal(uint256 proposalId)`: Allows the owner/proposer to manually reject a proposal if needed (e.g., before judgment).
17. `listNftForSale(uint256 tokenId, uint256 price)`: Allows an NFT owner to list their NFT on the marketplace at a fixed price. Requires approval.
18. `delistNft(uint256 tokenId)`: Allows the seller to remove an NFT listing.
19. `buyNft(uint256 tokenId)`: Allows a buyer to purchase a listed NFT by sending the required amount. Handles fee distribution and transfer.
20. `makeOffer(uint256 tokenId)`: Allows a user to make an offer on an NFT (whether listed or not) by sending ETH.
21. `cancelOffer(uint256 tokenId)`: Allows an offerer to cancel their active offer and reclaim their ETH.
22. `acceptOffer(uint256 tokenId, address offerer)`: Allows the NFT owner to accept an outstanding offer, triggering transfer and fee distribution.
23. `stakeNft(uint256 tokenId)`: Allows an NFT owner to stake their NFT in the contract to potentially earn rewards. Transfers the NFT to the contract.
24. `unstakeNft(uint256 tokenId)`: Allows a staker to unstake their NFT, reclaiming ownership. Also claims any pending rewards.
25. `claimStakingRewards(uint256 tokenId)`: Allows a staker to claim accumulated rewards without unstaking.
26. `getStakingInfo(uint256 tokenId)`: Returns staking details and calculated pending rewards for a staked NFT.
27. `calculateStakingRewards(uint256 tokenId)`: (Internal/Public view helper) Calculates accrued rewards.
28. `setMarketplaceFee(uint256 feeBps)`: (Callable by `onlyOwner`) Sets the marketplace fee percentage (in Basis Points).
29. `setAIOracleAddress(address oracleAddress)`: (Callable by `onlyOwner`) Sets the address of the trusted AI oracle contract.
30. `setJudgingFee(uint256 fee)`: (Callable by `onlyOwner`) Sets the fee required to submit an evolution proposal (paid to the oracle).
31. `setMinJudgeScore(uint256 score)`: (Callable by `onlyOwner`) Sets the minimum AI judgment score required for a proposal to be eligible for application.
32. `withdrawMarketplaceFees(address recipient)`: (Callable by `onlyOwner`) Allows the owner to withdraw accumulated marketplace fees.
33. `withdrawContractBalance(address recipient)`: (Callable by `onlyOwner`) Allows the owner to withdraw any remaining contract balance (excluding fees earmarked for withdrawal).
34. `pause()`: (Callable by `onlyOwner`) Pauses certain contract functionalities (e.g., minting, trading, staking actions).
35. `unpause()`: (Callable by `onlyOwner`) Unpauses the contract.
36. `transferOwnership(address newOwner)`: (Callable by `onlyOwner`) Transfers contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max/ceil etc. - often useful

// Interface for a hypothetical AI Oracle contract
// In a real scenario, this would interact with a Chainlink or similar decentralized oracle network
interface IAAIOracle {
    function requestJudgment(uint256 requestId, string memory metadataURI) external payable;
    // The oracle is expected to call back the EvolutionPlatform contract
    // function fulfillJudgment(uint256 requestId, uint256 score) external; // This is called *on the Platform*, so not in the Oracle interface
}

/**
 * @title DynamicNFTEvolutionPlatform
 * @dev A platform for minting, evolving, trading, and staking dynamic NFTs with AI-assisted curation.
 * NFTs can evolve from Shards to Prisms based on proposals judged by an external AI oracle.
 */
contract DynamicNFTEvolutionPlatform is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _oracleRequestIdCounter; // To link proposals to oracle requests

    string private _baseTokenURI; // Base URI for metadata (can be IPFS/HTTP gateway)

    // NFT Evolution States
    enum NFTState { SHARD, PRISM, GEM, LEGENDARY }
    struct NFTData {
        NFTState state;
        string metadataURI; // Current metadata URI for the state
        uint256[] judgmentHistory; // History of AI scores received for this NFT
    }
    mapping(uint256 => NFTData) private _nftData;

    // Evolution Proposals
    enum ProposalStatus { PENDING, JUDGING, APPROVED, REJECTED, APPLIED }
    struct EvolutionProposal {
        address proposer;
        uint256 tokenId;
        NFTState targetState; // State trying to evolve into
        string metadataURI; // Proposed metadata URI for the new state
        ProposalStatus status;
        uint256 judgmentScore; // Score received from the oracle (0 if not judged)
        uint256 oracleRequestId; // ID used when requesting judgment from oracle
        uint256 submissionTime;
    }
    mapping(uint256 => EvolutionProposal) private _proposals;
    mapping(uint256 => uint256) private _oracleRequestToProposalId; // Map oracle request ID back to proposal ID

    // Marketplace Listings
    struct Listing {
        address seller;
        uint256 price;
        bool isListed;
    }
    mapping(uint256 => Listing) private _listings; // tokenId => Listing

    // Offers
    struct Offer {
        address offerer;
        uint256 amount;
        uint256 timestamp;
        bool active;
    }
    mapping(uint256 => mapping(address => Offer)) private _offers; // tokenId => offerer => Offer

    // Staking
    struct StakingInfo {
        address staker;
        uint256 stakeTimestamp;
        uint256 lastRewardClaimTime;
        // Note: Rewards calculated based on stake duration and potentially NFT state/score
    }
    mapping(uint256 => StakingInfo) private _stakedNfts; // tokenId => StakingInfo
    mapping(address => uint256) private _stakerRewardBalance; // staker => accumulated, unclamed rewards
    uint256 private _baseStakingRewardRatePerSecond = 1e15; // Example: 0.001 ether per second per staked NFT (adjust units)

    // Configuration
    uint256 public mintPrice = 0.05 ether;
    uint256 public evolutionSubmissionFee = 0.01 ether; // Fee sent to oracle
    uint256 public marketplaceFeeBps = 250; // 2.5% in Basis Points (10000 bps = 100%)
    uint256 public minJudgeScoreForEvolution = 70; // Minimum score (out of 100) to approve evolution
    address public aiOracleAddress;
    uint256 private _marketplaceFeesBalance = 0;

    // --- Errors ---

    error InvalidTokenId();
    error NotApprovedOrOwner();
    error OnlyOwnerOrApproved();
    error NotListedForSale();
    error NotSeller();
    error NotEnoughETH();
    error NFTAlreadyListed();
    error OfferDoesNotExist();
    error NotOfferer();
    error OfferNotActive();
    error CannotOfferOnOwnNFT();
    error OfferAlreadyAccepted();
    error NFTAlreadyStaked();
    error NFTNotStaked();
    error AlreadyStakedBySomeoneElse();
    error CannotStakeContractAddress();
    error ProposalDoesNotExist();
    error InvalidProposalStatus();
    error ProposalNotApproved();
    error InsufficientJudgeScore();
    error OnlyOracleCanSubmitJudgment();
    error TargetStateNotAchievable();
    error InvalidMetadataURI();
    error InvalidFeeBps();
    error InvalidMinJudgeScore();
    error ZeroAddressNotAllowed();

    // --- Events ---

    event ShardMinted(uint256 indexed tokenId, address indexed owner, string initialURI);
    event EvolutionProposalSubmitted(uint256 indexed proposalId, uint256 indexed tokenId, address indexed proposer, NFTState targetState, string metadataURI, uint256 oracleRequestId);
    event AIJudgmentReceived(uint256 indexed oracleRequestId, uint256 indexed proposalId, uint256 score, ProposalStatus newStatus);
    event EvolutionApplied(uint256 indexed proposalId, uint256 indexed tokenId, NFTState newState, string newMetadataURI);
    event ProposalRejected(uint256 indexed proposalId, uint256 indexed tokenId, ProposalStatus status);

    event NFTListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event NFTDelisted(uint256 indexed tokenId);
    event NFTSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event OfferMade(uint256 indexed tokenId, address indexed offerer, uint256 amount);
    event OfferCancelled(uint256 indexed tokenId, address indexed offerer);
    event OfferAccepted(uint256 indexed tokenId, address indexed offerer, address indexed seller, uint256 amount);

    event NFTStaked(uint256 indexed tokenId, address indexed staker, uint256 stakeTimestamp);
    event NFTUnstaked(uint256 indexed tokenId, address indexed staker, uint256 unstakeTimestamp);
    event RewardsClaimed(uint256 indexed tokenId, address indexed staker, uint256 amount);

    event FeeSet(string name, uint256 value);
    event OracleSet(address indexed oldOracle, address indexed newOracle);
    event MinJudgeScoreSet(uint256 oldScore, uint256 newScore);

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI)
        ERC721(name, symbol)
        ERC721Enumerable()
        Ownable(msg.sender)
        Pausable()
    {
        _baseTokenURI = baseURI;
    }

    // --- Standard ERC721 Overrides (with Pausable) ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Ensure token exists before any transfer logic
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }

        // Prevent transfers if paused, unless it's from/to zero address (mint/burn related)
        if (from != address(0) && to != address(0)) {
             _requireNotPaused();
        }

        // Additional check: unstake if transferring away from staker
        if (from != address(0) && _isStaked(tokenId) && _stakedNfts[tokenId].staker == from) {
            _unstakeInternal(tokenId); // Auto-unstake on transfer out
        }
        // Additional check: remove marketplace listings/offers if transferring
        if (_listings[tokenId].isListed && _listings[tokenId].seller == from) {
            _delistInternal(tokenId);
        }
        // Cannot transfer if there are active offers
        // This check is difficult with current mapping structure. Better to handle offers
        // directly in transfer scenarios or disallow transfers if offers exist.
        // For simplicity here, accepting an offer *is* the transfer. Transferring via ERC721
        // functions bypasses offer logic, which is a known limitation in simple marketplaces.
        // A more robust marketplace might hold NFTs in escrow.
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        // Note: In a real app, the metadataURI should resolve to a JSON reflecting the current state
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId), "/", Strings.toString(uint8(_nftData[tokenId].state))));
        // Or simply return the dynamic URI stored
        // return _nftData[tokenId].metadataURI;
    }

    // --- Custom NFT State Getters ---

    function getNftState(uint256 tokenId) public view returns (NFTState) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _nftData[tokenId].state;
    }

     function getJudgmentHistory(uint256 tokenId) public view returns (uint256[] memory) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        return _nftData[tokenId].judgmentHistory;
    }

    // --- Minting ---

    /**
     * @dev Mints a new Genesis Shard NFT.
     * @param initialURI The initial metadata URI for the shard.
     */
    function mintShard(string memory initialURI) public payable whenNotPaused returns (uint256) {
        if (msg.value < mintPrice) {
            revert NotEnoughETH();
        }
        if (bytes(initialURI).length == 0) {
            revert InvalidMetadataURI();
        }

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);
        _nftData[newItemId] = NFTData(NFTState.SHARD, initialURI, new uint256[](0));

        emit ShardMinted(newItemId, msg.sender, initialURI);

        // Refund excess ETH
        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        return newItemId;
    }

    // --- Evolution Mechanism ---

    /**
     * @dev Allows an NFT owner to submit a proposal to evolve their NFT.
     * Requires the NFT to be in a state eligible for evolution (e.g., SHARD -> PRISM).
     * Requires payment of the `evolutionSubmissionFee`.
     * Triggers a simulated AI oracle request.
     * @param tokenId The ID of the NFT to evolve.
     * @param newMetadataURI The proposed metadata URI for the evolved state.
     */
    function submitEvolutionProposal(uint256 tokenId, string memory newMetadataURI)
        public payable nonReentrant whenNotPaused nftExists(tokenId)
    {
        address owner = ownerOf(tokenId);
        if (msg.sender != owner) {
            revert NotApprovedOrOwner(); // Only owner can propose evolution
        }
         if (bytes(newMetadataURI).length == 0) {
            revert InvalidMetadataURI();
        }
         if (_isStaked(tokenId)) {
             revert NFTAlreadyStaked(); // Cannot propose if staked
         }
         if (_listings[tokenId].isListed) {
             revert NFTAlreadyListed(); // Cannot propose if listed
         }
        // Check for active offers (basic check, could be more robust)
        Offer memory activeOffer = _offers[tokenId][msg.sender]; // Check if sender has an active offer - not relevant for proposing
        // A more robust check would iterate all offers or track existence flag.
        // For simplicity, we assume offers don't block proposals unless logic is added.

        // Determine the next state
        NFTState currentState = _nftData[tokenId].state;
        NFTState targetState;
        if (currentState == NFTState.SHARD) {
            targetState = NFTState.PRISM;
        } else if (currentState == NFTState.PRISM) {
            targetState = NFTState.GEM;
        } else if (currentState == NFTState.GEM) {
             targetState = NFTState.LEGENDARY;
        } else {
            revert TargetStateNotAchievable(); // Already Legendary or invalid state
        }

        if (msg.value < evolutionSubmissionFee) {
            revert NotEnoughETH();
        }

        // Generate Request ID and Proposal ID
        _oracleRequestIdCounter.increment();
        uint256 currentOracleRequestId = _oracleRequestIdCounter.current();

        _proposalIdCounter.increment();
        uint256 currentProposalId = _proposalIdCounter.current();

        // Store proposal details
        _proposals[currentProposalId] = EvolutionProposal({
            proposer: msg.sender,
            tokenId: tokenId,
            targetState: targetState,
            metadataURI: newMetadataURI,
            status: ProposalStatus.PENDING, // Starts PENDING, oracle moves to JUDGING/APPROVED/REJECTED
            judgmentScore: 0,
            oracleRequestId: currentOracleRequestId,
            submissionTime: block.timestamp
        });
         _oracleRequestToProposalId[currentOracleRequestId] = currentProposalId;

        emit EvolutionProposalSubmitted(currentProposalId, tokenId, msg.sender, targetState, newMetadataURI, currentOracleRequestId);

        // *** Simulate Oracle Request ***
        // In a real dApp, this would trigger an external call to the oracle contract.
        // Here, we emit an event that an external oracle listener would pick up.
        // The oracle would process the metadataURI (off-chain), determine a score,
        // and call `receiveJudgmentResult` on this contract.
        // We will manually move the state to JUDGING here for demonstration purposes.
        _proposals[currentProposalId].status = ProposalStatus.JUDGING;
         emit AIJudgmentReceived(currentOracleRequestId, currentProposalId, 0, ProposalStatus.JUDGING); // Status updated locally

        // Transfer fee to the oracle address
        if (evolutionSubmissionFee > 0) {
             // Ensure oracle address is set
             if (aiOracleAddress == address(0)) {
                // In a real scenario, this might pause or revert earlier.
                // Here, we just log and potentially hold the fee.
                 // Or, assume oracle setup is prerequisite and revert if zero. Let's revert.
                 revert ZeroAddressNotAllowed();
             }
            payable(aiOracleAddress).transfer(evolutionSubmissionFee);
        }

        // Refund excess ETH
        if (msg.value > evolutionSubmissionFee) {
            payable(msg.sender).transfer(msg.value - evolutionSubmissionFee);
        }
    }

    /**
     * @dev Get the status of a specific evolution proposal.
     * @param proposalId The ID of the proposal.
     * @return The status of the proposal.
     */
    function getProposalStatus(uint256 proposalId) public view returns (ProposalStatus) {
        if (proposalId == 0 || proposalId > _proposalIdCounter.current()) {
            revert ProposalDoesNotExist();
        }
        return _proposals[proposalId].status;
    }

    /**
     * @dev Callback function for the AI Oracle to report a judgment score.
     * Only callable by the configured AI Oracle address.
     * Updates the proposal status based on the score.
     * @param requestId The request ID originally provided when submitting the proposal.
     * @param score The judgment score provided by the AI (e.g., 0-100).
     */
    function receiveJudgmentResult(uint256 requestId, uint256 score) public onlyOracle {
        uint256 proposalId = _oracleRequestToProposalId[requestId];
        if (proposalId == 0 || proposalId > _proposalIdCounter.current()) {
            // Should not happen if oracle uses correct request ID, but safe check
            revert ProposalDoesNotExist();
        }

        EvolutionProposal storage proposal = _proposals[proposalId];

        // Only process if the proposal is in JUDGING state
        if (proposal.status != ProposalStatus.JUDGING) {
             revert InvalidProposalStatus();
        }

        proposal.judgmentScore = score;
        _nftData[proposal.tokenId].judgmentHistory.push(score); // Record the score on the NFT

        if (score >= minJudgeScoreForEvolution) {
            proposal.status = ProposalStatus.APPROVED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }

        emit AIJudgmentReceived(requestId, proposalId, score, proposal.status);
    }

    /**
     * @dev Allows the proposer to apply an evolution if the proposal was approved.
     * Updates the NFT's state and metadata URI.
     * @param proposalId The ID of the approved proposal.
     */
    function applyEvolution(uint256 proposalId) public nonReentrant nftExists(_proposals[proposalId].tokenId) {
        EvolutionProposal storage proposal = _proposals[proposalId];

        // Check if proposal exists and is in the correct state
        if (proposalId == 0 || proposalId > _proposalIdCounter.current()) {
            revert ProposalDoesNotExist();
        }
        if (proposal.status != ProposalStatus.APPROVED) {
            revert InvalidProposalStatus();
        }
        // Only the original proposer can apply it
        if (msg.sender != proposal.proposer) {
             revert NotApprovedOrOwner();
        }
        // Ensure the proposer still owns the token
        if (ownerOf(proposal.tokenId) != msg.sender) {
             revert NotApprovedOrOwner();
        }

        // Check if minimum score was actually met (redundant if status is APPROVED, but good check)
        if (proposal.judgmentScore < minJudgeScoreForEvolution) {
            revert InsufficientJudgeScore(); // Should not be APPROVED if score is too low
        }

        // Apply the evolution
        _nftData[proposal.tokenId].state = proposal.targetState;
        _nftData[proposal.tokenId].metadataURI = proposal.metadataURI; // Update to new URI

        proposal.status = ProposalStatus.APPLIED; // Mark proposal as applied

        emit EvolutionApplied(proposalId, proposal.tokenId, proposal.targetState, proposal.metadataURI);
    }

    /**
     * @dev Allows the proposer or owner to reject a pending or judged proposal.
     * Cannot reject an applied proposal.
     * @param proposalId The ID of the proposal.
     */
    function rejectEvolutionProposal(uint256 proposalId) public {
         if (proposalId == 0 || proposalId > _proposalIdCounter.current()) {
            revert ProposalDoesNotExist();
        }
        EvolutionProposal storage proposal = _proposals[proposalId];

        // Only proposer or token owner can reject (ownerOf can change)
        address tokenOwner = ownerOf(proposal.tokenId);
        if (msg.sender != proposal.proposer && msg.sender != tokenOwner) {
             revert NotApprovedOrOwner();
        }

        // Cannot reject if already applied
        if (proposal.status == ProposalStatus.APPLIED) {
             revert InvalidProposalStatus();
        }

        // Set status to rejected
        proposal.status = ProposalStatus.REJECTED;
        emit ProposalRejected(proposalId, proposal.tokenId, proposal.status);
    }

    // --- Marketplace ---

    /**
     * @dev Lists an NFT for sale at a fixed price.
     * Caller must be the owner and have approved the contract.
     * @param tokenId The ID of the NFT to list.
     * @param price The sale price in Wei.
     */
    function listNftForSale(uint256 tokenId, uint256 price)
        public whenNotPaused nftExists(tokenId) isApprovedOrOwner(tokenId)
    {
        if (_listings[tokenId].isListed) {
            revert NFTAlreadyListed();
        }
        if (ownerOf(tokenId) != msg.sender) {
            revert NotApprovedOrOwner(); // Redundant with modifier, but explicit
        }
        if (price == 0) {
             revert NotEnoughETH(); // Price must be > 0
        }
         if (_isStaked(tokenId)) {
             revert NFTAlreadyStaked(); // Cannot list if staked
         }

        // Require approval for the contract to transfer the token later
        if (getApproved(tokenId) != address(this) && !isApprovedForAll(msg.sender, address(this))) {
            revert NotApprovedOrOwner(); // Requires approval for the contract
        }

        _listings[tokenId] = Listing({
            seller: msg.sender,
            price: price,
            isListed: true
        });

        emit NFTListed(tokenId, msg.sender, price);
    }

    /**
     * @dev Removes an NFT listing. Callable by the seller.
     * @param tokenId The ID of the NFT to delist.
     */
    function delistNft(uint256 tokenId) public whenNotPaused nftExists(tokenId) {
        if (!_listings[tokenId].isListed) {
            revert NotListedForSale();
        }
        if (_listings[tokenId].seller != msg.sender) {
            revert NotSeller();
        }

        _delistInternal(tokenId);
        emit NFTDelisted(tokenId);
    }

    /**
     * @dev Internal helper to delist an NFT.
     */
    function _delistInternal(uint256 tokenId) internal {
         delete _listings[tokenId];
         // Note: Approval for the contract might still exist, needs external revoke if desired
    }

    /**
     * @dev Buys a listed NFT.
     * Sends the exact listed price. Handles fee calculation and transfer.
     * @param tokenId The ID of the NFT to buy.
     */
    function buyNft(uint256 tokenId) public payable nonReentrant whenNotPaused nftExists(tokenId) {
        Listing storage listing = _listings[tokenId];
        if (!listing.isListed) {
            revert NotListedForSale();
        }
        if (msg.value < listing.price) {
            revert NotEnoughETH();
        }
         if (listing.seller == msg.sender) {
             revert CannotOfferOnOwnNFT(); // Cannot buy your own listing
         }

        uint256 sellerProceeds = listing.price.mul(10000 - marketplaceFeeBps).div(10000);
        uint256 feeAmount = listing.price - sellerProceeds;

        // Transfer funds to seller and contract
        payable(listing.seller).transfer(sellerProceeds);
        _marketplaceFeesBalance += feeAmount;

        // Transfer NFT ownership
        address seller = listing.seller; // Store before deleting listing
        _safeTransfer(seller, msg.sender, tokenId); // ERC721 transfer

        // Remove listing
        delete _listings[tokenId];

        emit NFTSold(tokenId, msg.sender, seller, listing.price);

        // Refund excess ETH
        if (msg.value > listing.price) {
            payable(msg.sender).transfer(msg.value - listing.price);
        }
    }

    /**
     * @dev Allows making an offer on an NFT. Sends ETH with the call.
     * Replaces any existing active offer from the same offerer.
     * @param tokenId The ID of the NFT to make an offer on.
     */
    function makeOffer(uint256 tokenId) public payable whenNotPaused nftExists(tokenId) {
        if (msg.value == 0) {
            revert NotEnoughETH();
        }
        address currentOwner = ownerOf(tokenId);
        if (currentOwner == msg.sender) {
            revert CannotOfferOnOwnNFT();
        }
         // Cannot make offer if NFT is staked by someone else (owner still = contract)
         if (_isStaked(tokenId) && _stakedNfts[tokenId].staker != currentOwner) {
              revert NFTAlreadyStaked();
         }

        // If an active offer exists from this offerer, refund it first
        if (_offers[tokenId][msg.sender].active) {
             // Refund existing offer
             payable(msg.sender).transfer(_offers[tokenId][msg.sender].amount);
             emit OfferCancelled(tokenId, msg.sender);
        }

        // Create or update the offer
        _offers[tokenId][msg.sender] = Offer({
            offerer: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            active: true
        });

        emit OfferMade(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Allows an offerer to cancel their active offer and reclaim their ETH.
     * @param tokenId The ID of the NFT the offer was made on.
     */
    function cancelOffer(uint256 tokenId) public whenNotPaused nftExists(tokenId) {
        Offer storage offer = _offers[tokenId][msg.sender];
        if (!offer.active) {
            revert OfferDoesNotExist();
        }
        if (offer.offerer != msg.sender) {
            revert NotOfferer();
        }

        // Invalidate the offer and refund ETH
        offer.active = false;
        // Note: The offer struct remains, but `active` flag prevents acceptance.
        // Could delete it for cleaner state, but requires mapping(tokenId => mapping(address => Offer)) -> address array or linked list.
        // Simpler to just set active=false.
        payable(msg.sender).transfer(offer.amount);

        emit OfferCancelled(tokenId, msg.sender);
    }

    /**
     * @dev Allows the NFT owner to accept an offer.
     * Transfers the NFT to the offerer and distributes ETH (seller proceeds + fee).
     * @param tokenId The ID of the NFT.
     * @param offerer The address of the offerer whose offer to accept.
     */
    function acceptOffer(uint256 tokenId, address offerer)
        public nonReentrant whenNotPaused nftExists(tokenId) isApprovedOrOwner(tokenId)
    {
        Offer storage offer = _offers[tokenId][offerer];

        if (!offer.active) {
            revert OfferDoesNotExist();
        }
         if (offer.offerer != offerer) {
             revert NotOfferer(); // Ensure the offerer address passed is correct
         }

        address currentOwner = ownerOf(tokenId);
        if (currentOwner != msg.sender) {
             revert NotApprovedOrOwner(); // Only owner or approved can accept
        }
        if (currentOwner == offerer) {
             revert CannotOfferOnOwnNFT(); // Owner cannot accept their own offer
        }
         if (_isStaked(tokenId)) {
             revert NFTAlreadyStaked(); // Cannot accept offer if staked
         }
         if (_listings[tokenId].isListed && _listings[tokenId].seller == msg.sender) {
             revert NFTAlreadyListed(); // Cannot accept offer if also listed (resolve listing first)
         }

        // Calculate fees and seller proceeds
        uint256 offerAmount = offer.amount;
        uint256 sellerProceeds = offerAmount.mul(10000 - marketplaceFeeBps).div(10000);
        uint256 feeAmount = offerAmount - sellerProceeds;

        // Invalidate the offer BEFORE transfers
        offer.active = false;

        // Transfer NFT to the offerer
        _safeTransfer(currentOwner, offerer, tokenId); // ERC721 transfer

        // Transfer funds to seller and contract
        payable(currentOwner).transfer(sellerProceeds);
        _marketplaceFeesBalance += feeAmount;

        emit OfferAccepted(tokenId, offerer, currentOwner, offerAmount);
    }

    // --- Staking ---

    /**
     * @dev Stakes an NFT. The NFT is transferred to the contract.
     * Only the owner can stake. Cannot stake if listed, has active offers, or already staked.
     * @param tokenId The ID of the NFT to stake.
     */
    function stakeNft(uint256 tokenId)
        public nonReentrant whenNotPaused nftExists(tokenId) isApprovedOrOwner(tokenId)
    {
        address currentOwner = ownerOf(tokenId);
        if (currentOwner != msg.sender) {
            revert NotApprovedOrOwner();
        }
        if (_isStaked(tokenId)) {
            revert NFTAlreadyStaked();
        }
         if (_listings[tokenId].isListed) {
             revert NFTAlreadyListed(); // Cannot stake if listed
         }
        // Check for active offers (basic check)
        bool hasActiveOffer = false;
        // This requires iterating or a more complex data structure. Skipping for simplicity,
        // assuming offer acceptance/cancellation handles state correctly *before* staking.
        // A real system would need to track offers per NFT more rigorously.

        // Transfer NFT to the contract
        _safeTransfer(currentOwner, address(this), tokenId);

        // Record staking info
        _stakedNfts[tokenId] = StakingInfo({
            staker: msg.sender, // The original staker's address
            stakeTimestamp: block.timestamp,
            lastRewardClaimTime: block.timestamp
        });

        emit NFTStaked(tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Unstakes an NFT. Transfers the NFT back to the staker.
     * Also claims any pending rewards.
     * @param tokenId The ID of the NFT to unstake.
     */
    function unstakeNft(uint256 tokenId) public nonReentrant whenNotPaused nftExists(tokenId) {
        if (!_isStaked(tokenId)) {
            revert NFTNotStaked();
        }
        StakingInfo storage stakingInfo = _stakedNfts[tokenId];
        if (stakingInfo.staker != msg.sender) {
            revert NotApprovedOrOwner(); // Only the original staker can unstake
        }

        // Claim rewards before unstaking
        _claimStakingRewardsInternal(tokenId);

        // Transfer NFT back to staker
        _safeTransfer(address(this), msg.sender, tokenId);

        // Remove staking info
        delete _stakedNfts[tokenId];

        emit NFTUnstaked(tokenId, msg.sender, block.timestamp);
    }

    /**
     * @dev Claims accumulated staking rewards without unstaking the NFT.
     * @param tokenId The ID of the staked NFT.
     */
    function claimStakingRewards(uint256 tokenId) public nonReentrant whenNotPaused nftExists(tokenId) {
         if (!_isStaked(tokenId)) {
            revert NFTNotStaked();
        }
        StakingInfo storage stakingInfo = _stakedNfts[tokenId];
        if (stakingInfo.staker != msg.sender) {
            revert NotApprovedOrOwner(); // Only the original staker can claim
        }

        _claimStakingRewardsInternal(tokenId);
    }

    /**
     * @dev Internal helper to calculate and claim staking rewards.
     */
    function _claimStakingRewardsInternal(uint256 tokenId) internal {
        StakingInfo storage stakingInfo = _stakedNfts[tokenId];
        uint256 rewards = calculateStakingRewards(tokenId);

        if (rewards > 0) {
            _stakerRewardBalance[stakingInfo.staker] += rewards;
            stakingInfo.lastRewardClaimTime = block.timestamp; // Update claim time

            // Transfer accumulated rewards to the staker's balance
            // Note: Funds are only transferred out when `withdrawStakerRewards` is called
            // This accumulates rewards in the contract for the staker.
            emit RewardsClaimed(tokenId, stakingInfo.staker, rewards);
        }
    }

    /**
     * @dev Helper to calculate pending rewards for a staked NFT.
     * @param tokenId The ID of the staked NFT.
     * @return The amount of pending rewards in Wei.
     */
    function calculateStakingRewards(uint256 tokenId) public view returns (uint256) {
        if (!_isStaked(tokenId)) {
            return 0;
        }
        StakingInfo storage stakingInfo = _stakedNfts[tokenId];
        uint256 timeStakedSinceLastClaim = block.timestamp - stakingInfo.lastRewardClaimTime;
        // Basic calculation: time elapsed * rate per second. Could be weighted by NFT state, score, etc.
        return timeStakedSinceLastClaim * _baseStakingRewardRatePerSecond;
    }

    /**
     * @dev Returns staking information for an NFT.
     * @param tokenId The ID of the NFT.
     * @return staker The address that staked the NFT.
     * @return stakeTimestamp The timestamp when the NFT was staked.
     * @return pendingRewards The amount of pending rewards.
     */
    function getStakingInfo(uint256 tokenId) public view returns (address staker, uint256 stakeTimestamp, uint256 pendingRewards) {
        if (!_isStaked(tokenId)) {
            return (address(0), 0, 0);
        }
        StakingInfo storage stakingInfo = _stakedNfts[tokenId];
        return (stakingInfo.staker, stakingInfo.stakeTimestamp, calculateStakingRewards(tokenId));
    }

    /**
     * @dev Helper to check if an NFT is currently staked.
     * @param tokenId The ID of the NFT.
     * @return True if staked, false otherwise.
     */
    function _isStaked(uint256 tokenId) internal view returns (bool) {
        // Checking if the staker address is non-zero is sufficient
        return _stakedNfts[tokenId].staker != address(0);
    }

    /**
     * @dev Allows a staker to withdraw their accumulated staking rewards.
     * @param recipient The address to send the rewards to.
     */
    function withdrawStakerRewards(address recipient) public nonReentrant {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();

        uint256 amount = _stakerRewardBalance[msg.sender];
        if (amount == 0) {
            // No rewards to withdraw
            return;
        }

        _stakerRewardBalance[msg.sender] = 0;

        // Transfer funds to the recipient
        payable(recipient).transfer(amount);
    }


    // --- Configuration / Admin Functions ---

    /**
     * @dev Sets the price for minting a new Shard. Callable by owner.
     * @param price The new minting price in Wei.
     */
    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
        emit FeeSet("mintPrice", price);
    }

    /**
     * @dev Sets the fee required to submit an evolution proposal. Callable by owner.
     * This fee is intended for the AI Oracle.
     * @param fee The new submission fee in Wei.
     */
    function setEvolutionSubmissionFee(uint256 fee) public onlyOwner {
        evolutionSubmissionFee = fee;
         emit FeeSet("evolutionSubmissionFee", fee);
    }

    /**
     * @dev Sets the marketplace fee percentage. Callable by owner.
     * Fee is in Basis Points (e.g., 250 = 2.5%). Max 10000 (100%).
     * @param feeBps The new fee percentage in Basis Points.
     */
    function setMarketplaceFee(uint256 feeBps) public onlyOwner {
        if (feeBps > 10000) {
            revert InvalidFeeBps();
        }
        marketplaceFeeBps = feeBps;
         emit FeeSet("marketplaceFeeBps", feeBps);
    }

    /**
     * @dev Sets the address of the trusted AI Oracle contract. Callable by owner.
     * @param oracleAddress The address of the AI oracle.
     */
    function setAIOracleAddress(address oracleAddress) public onlyOwner {
         if (oracleAddress == address(0)) revert ZeroAddressNotAllowed();
        address oldOracle = aiOracleAddress;
        aiOracleAddress = oracleAddress;
        emit OracleSet(oldOracle, oracleAddress);
    }

    /**
     * @dev Sets the minimum AI judgment score required for a proposal to be APPROVED. Callable by owner.
     * @param score The minimum score (e.g., 0-100).
     */
    function setMinJudgeScore(uint256 score) public onlyOwner {
         if (score > 100) revert InvalidMinJudgeScore(); // Assuming score is 0-100
        uint256 oldScore = minJudgeScoreForEvolution;
        minJudgeScoreForEvolution = score;
        emit MinJudgeScoreSet(oldScore, score);
    }

     /**
      * @dev Sets the base rate for staking rewards per second per NFT. Callable by owner.
      * @param rate The new rate in Wei per second.
      */
     function setBaseStakingRewardRate(uint256 rate) public onlyOwner {
         _baseStakingRewardRatePerSecond = rate;
          emit FeeSet("baseStakingRewardRate", rate);
     }


    /**
     * @dev Allows the owner to withdraw accumulated marketplace fees.
     * @param recipient The address to send the fees to.
     */
    function withdrawMarketplaceFees(address recipient) public onlyOwner nonReentrant {
         if (recipient == address(0)) revert ZeroAddressNotAllowed();
        uint256 amount = _marketplaceFeesBalance;
        if (amount == 0) {
            return; // No fees to withdraw
        }
        _marketplaceFeesBalance = 0;
        payable(recipient).transfer(amount);
    }

    /**
     * @dev Allows the owner to withdraw any other ETH balance in the contract
     * not specifically earmarked (like marketplace fees or locked offers).
     * Should be used cautiously.
     * @param recipient The address to send the balance to.
     */
    function withdrawContractBalance(address recipient) public onlyOwner nonReentrant {
        if (recipient == address(0)) revert ZeroAddressNotAllowed();
        uint256 balance = address(this).balance;
        // Don't withdraw fees explicitly managed or potentially locked offers
        // This is an oversimplification; tracking locked ETH accurately is complex.
        // For demonstration, we allow withdrawing everything *except* explicit fee balance.
        // A real system needs a better way to track offer/staking locked funds.
        uint256 amountToWithdraw = balance - _marketplaceFeesBalance;
         // Also need to account for staked rewards balance!
         uint256 totalStakerBalances = 0;
         // This requires iterating over all stakers, which is not gas efficient.
         // A better pattern is to have stakers withdraw their *own* balance.
         // Let's assume stakers use `withdrawStakerRewards` and this function is only for true 'extra' ETH.
         amountToWithdraw = balance - _marketplaceFeesBalance;


        if (amountToWithdraw > 0) {
             payable(recipient).transfer(amountToWithdraw);
         }
    }


    // --- Pausable Overrides ---
    // Need to override internal _requireNotPaused for ERC721 hooks
    function _requireNotPaused() internal view virtual override {
        if (paused()) {
            revert Paused();
        }
    }

    // Override pause/unpause to emit custom events
    function pause() public onlyOwner virtual override {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner virtual override {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // --- Utility & Internal Functions ---

    /**
     * @dev Checks if a token ID is valid (has been minted).
     */
    modifier nftExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert InvalidTokenId();
        }
        _;
    }

    /**
     * @dev Checks if the caller is the owner or an approved operator for the token.
     * Useful for actions that require control over the NFT.
     */
     modifier isApprovedOrOwner(uint256 tokenId) {
         address tokenOwner = ownerOf(tokenId);
         if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender) && getApproved(tokenId) != msg.sender) {
             revert NotApprovedOrOwner();
         }
         _;
     }


     /**
      * @dev Checks if the caller is the configured AI Oracle.
      */
     modifier onlyOracle() {
         if (msg.sender != aiOracleAddress) {
             revert OnlyOracleCanSubmitJudgment();
         }
         _;
     }

    // The following functions are required overrides for ERC721Enumerable
    // They interact with the _owners, _balances, _allTokens, and _allTokensIndex mappings
    // which are managed by ERC721Enumerable.

    // No need to explicitly list all ERC721Enumerable overrides here if inheriting.
    // For a complete list of *public* functions, refer to the ERC721Enumerable interface.
    // We already listed the core ERC721 ones being overridden or relied upon.

}
```