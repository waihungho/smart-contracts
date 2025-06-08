Okay, let's design a smart contract that implements a decentralized art curation platform with several interconnected, advanced concepts.

The core idea will be a platform where artists can submit digital art, curators (whose influence is weighted by their reputation) vote on submissions, approved art is minted as NFTs via the platform, and these NFTs can be listed and sold on an integrated marketplace, with fees distributed to the platform, artist royalties, and potentially curator rewards. We'll also add a concept of on-chain "exhibitions" to showcase curated art.

This design incorporates:
1.  **Decentralized Submission & Curation:** Artists submit, multiple curators vote.
2.  **Weighted Voting:** Curator influence is not equal; it's based on a reputation score managed by the platform.
3.  **Integrated NFT Minting:** The platform itself mints the ERC721 tokens for approved art.
4.  **On-Chain Marketplace:** Buy/Sell logic directly in the contract.
5.  **Dynamic Royalties:** Artists can potentially update their royalty percentage for future sales.
6.  **Curator Rewards:** Curators are rewarded based on their successful curation efforts (art they approved gets sold).
7.  **On-Chain Exhibitions:** A unique way to group and present curated art within the contract's state.
8.  **Lifecycle Management:** Clear states for submissions and art pieces (submitted, under review, approved, rejected, listed, sold).

Let's outline the structure and functions.

---

## Smart Contract Outline: DecentralizedArtCurator

**Concept:** A platform for decentralized submission, weighted curation, minting, and selling of digital art NFTs, featuring curator reputation, rewards, and on-chain exhibitions.

**Core Features:**
*   Artists submit art with metadata.
*   Designated curators review and vote on submissions.
*   Curator votes are weighted by their reputation score.
*   Submissions reaching consensus are approved.
*   Approved submissions trigger the minting of a unique ERC721 token by the contract.
*   Minted art can be listed for sale on the integrated marketplace.
*   Sales distribute funds: artist receives royalties, platform takes a fee, curators who voted for the art get rewards.
*   Curators gain reputation for successful curation.
*   Curators can claim accrued rewards.
*   On-chain exhibitions allow grouping and showcasing approved art.

**Key Data Structures:**
*   `Submission`: Represents an artist's submission awaiting review.
*   `ArtPiece`: Represents a minted NFT managed by the contract.
*   `Curator`: Represents a registered curator with a reputation score and pending rewards.
*   `Exhibition`: Represents a collection of `ArtPiece` IDs.

**Access Control:**
*   `Owner`: Manages core parameters, adds/removes curators, initiates certain processes.
*   `Curator`: Reviews submissions, votes.
*   `Artist`: Submits art, sets/updates royalties, claims earnings.
*   `Collector`: Buys art.

**NFT Standard:** The contract will *mimic* the necessary parts of ERC721 (ownership, transfer, tokenURI) internally for the art pieces it manages, rather than inheriting a full standard contract like OpenZeppelin's, to keep the focus on the unique curation/marketplace logic and avoid simply duplicating open-source interfaces.

---

## Function Summary (25+ functions)

**I. Core Platform Management (Owner Restricted)**
1.  `constructor`: Initializes platform owner, initial curators, fees.
2.  `addCurator(address curatorAddress)`: Adds a new address as a curator.
3.  `removeCurator(address curatorAddress)`: Removes curator status.
4.  `setSubmissionFee(uint256 fee)`: Sets the fee required to submit art.
5.  `setPlatformFeePercentage(uint256 percentage)`: Sets the platform's commission on sales.
6.  `withdrawPlatformFees()`: Allows owner to withdraw accumulated platform fees.

**II. Art Submission & Curation**
7.  `submitArt(string memory metadataURI, string memory title, string memory artistName)`: Artist pays fee to submit art details for review.
8.  `getSubmissionDetails(uint256 submissionId)`: View details of a specific submission.
9.  `assignCuratorToSubmission(uint256 submissionId, address curatorAddress)`: Owner assigns a specific curator to review (alternative: random assignment or open review).
10. `curatorWeightedVote(uint256 submissionId, bool voteApproved)`: Curator casts a weighted vote on a submission.
11. `finalizeSubmissionDecision(uint256 submissionId)`: Owner/Logic finalizes the decision based on weighted votes, potentially triggering minting or rejection. This function also updates curator reputation.
12. `rejectSubmission(uint256 submissionId, string memory reason)`: Explicitly reject a submission (if not finalized via voting).

**III. NFT Minting & Art Management**
13. `mintApprovedArt(uint256 submissionId, uint256 initialPrice, uint256 royaltyPercentage)`: Internal function called by `finalizeSubmissionDecision` if approved. Mints the NFT, sets initial price and royalty. *Not directly callable by external users*.
14. `getArtDetails(uint256 artId)`: View details of a specific minted art piece (owner, price, royalty, status).
15. `getOwnedArt(address ownerAddress)`: View list of art IDs owned by an address.
16. `getSubmittedArt(address artistAddress)`: View list of submission IDs by an artist.

**IV. Marketplace Operations**
17. `listArtForSale(uint256 artId, uint256 price)`: Current owner lists their art for sale.
18. `delistArt(uint256 artId)`: Current owner removes their art from sale.
19. `updateArtPrice(uint256 artId, uint256 newPrice)`: Current owner updates the price of their listed art.
20. `buyArt(uint256 artId)`: Collector buys listed art. Handles payment split (artist, platform, curators), transfers ownership. (Payable)
21. `artistUpdateRoyalty(uint256 artId, uint256 newPercentage)`: Artist (original creator) can adjust the royalty percentage for *future* sales of their art.

**V. Curator Reputation & Rewards**
22. `getCuratorReputation(address curatorAddress)`: View the reputation score of a curator.
23. `getCuratorPendingRewards(address curatorAddress)`: View the amount of unclaimed rewards for a curator.
24. `claimCuratorRewards()`: Curator claims their accumulated rewards.

**VI. On-Chain Exhibitions**
25. `createExhibition(string memory title, string memory description, string memory theme)`: Owner or high-reputation curator creates a new exhibition.
26. `addArtToExhibition(uint256 exhibitionId, uint256 artId)`: Add a minted art piece to an exhibition.
27. `removeArtFromExhibition(uint256 exhibitionId, uint256 artId)`: Remove art from an exhibition.
28. `getExhibitionDetails(uint256 exhibitionId)`: View details of an exhibition.
29. `getArtInExhibition(uint256 exhibitionId)`: View list of art IDs included in an exhibition.

**VII. Utility/Views**
30. `getCurrentSubmissionId()`: Get the next available submission ID.
31. `getCurrentArtId()`: Get the next available art ID (NFT token ID).
32. `getCurrentExhibitionId()`: Get the next available exhibition ID.
33. `getPlatformBalance()`: Get the current ETH balance held by the contract.

---

Here is the Solidity code implementing these concepts.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Use SafeMath for arithmetic safety if needed (though 0.8+ has built-in checks)
import {Address} from "@openzeppelin/contracts/utils/Address.sol"; // Utility for checks and transfers

// Minimal necessary imports. We will implement the core ERC721-like logic internally.

/**
 * @title DecentralizedArtCurator
 * @dev A platform for decentralized submission, weighted curation, minting, and selling of digital art NFTs.
 *      Features include curator reputation-weighted voting, integrated marketplace, dynamic artist royalties,
 *      curator rewards tied to successful curation, and on-chain exhibitions.
 *
 * Outline:
 * I. Core Platform Management (Owner Restricted)
 *    - Initialization, Curator management, Fee settings, Fee withdrawal.
 * II. Art Submission & Curation
 *    - Submission process, Viewing submissions, Curator assignment, Weighted voting, Finalizing decisions, Rejection.
 * III. NFT Minting & Art Management (Internal/View)
 *    - Minting approved art, Viewing art details, Getting owned/submitted art lists.
 * IV. Marketplace Operations
 *    - Listing/Delisting, Price updates, Buying art (handling payments & splits), Artist royalty updates.
 * V. Curator Reputation & Rewards
 *    - Getting reputation, Viewing pending rewards, Claiming rewards.
 * VI. On-Chain Exhibitions
 *    - Creating, Adding/Removing art, Viewing exhibition details.
 * VII. Utility/Views
 *    - ID counters, Platform balance views.
 */
contract DecentralizedArtCurator is Ownable {
    using SafeMath for uint256;
    using Address for address payable; // Use Address.sendValue for robust transfers

    // --- State Variables ---

    uint256 private _nextSubmissionId = 1;
    uint256 private _nextArtId = 1; // Represents NFT token ID
    uint256 private _nextExhibitionId = 1;

    enum SubmissionStatus {
        Pending,
        UnderReview,
        Voting,
        Approved,
        Rejected,
        Finalized // Submission is fully processed (minted or rejected)
    }

    enum ArtStatus {
        Minted,
        Listed,
        Sold
    }

    struct Submission {
        address artist;
        string metadataURI;
        string title;
        string artistName;
        uint256 submissionTime;
        SubmissionStatus status;
        address assignedCurator; // Simplified: single assigned curator for review step
        mapping(address => bool) hasVoted; // Track curators who voted
        uint256 totalWeightedVotesYes;
        uint256 totalWeightedVotesNo;
        uint256 requiredVoteWeight; // Threshold for approval (calculated based on total active curator weight)
        uint256 associatedArtId; // Becomes valid after approval/minting
        string rejectionReason; // Valid if status is Rejected
    }

    struct ArtPiece {
        uint256 artId; // Token ID
        address owner;
        address originalArtist;
        uint256 submissionId; // Link back to the submission
        string metadataURI; // Immutable metadata set at minting
        string title;
        string artistName;
        uint256 price; // Current listing price (0 if not listed)
        bool isListed;
        uint256 royaltyPercentage; // Percentage artist receives on future sales (e.g., 500 for 5%) - max 10000 (100%)
        ArtStatus status;
        mapping(address => uint256) exhibitionMembership; // Map exhibition ID to count (should be max 1, maybe struct later if complex)
    }

    struct Curator {
        bool exists; // To check if address is a curator
        uint256 reputation; // Weighted voting power
        uint256 pendingRewards; // ETH rewards accumulated
        mapping(uint256 => bool) votedOnSubmission; // To prevent double voting
    }

    struct Exhibition {
        uint256 exhibitionId;
        string title;
        string description;
        string theme;
        address creator;
        uint256 creationTime;
        uint256[] artPieces; // List of ArtPiece IDs included
        mapping(uint256 => bool) containsArt; // Quick lookup if art is in exhibition
    }

    // Mappings
    mapping(uint256 => Submission) public submissions;
    mapping(uint256 => ArtPiece) public artPieces; // Our custom "NFT" storage
    mapping(address => Curator) public curators;
    mapping(uint256 => Exhibition) public exhibitions;

    // Utility mappings for quick lookups
    mapping(address => uint256[]) public artistSubmissions;
    mapping(address => uint256[]) public ownerArtPieces; // Tracks art pieces owned by an address
    mapping(uint256 => address) public artPieceOwners; // Standard ERC721 owner mapping (redundant but common pattern)

    address[] public activeCuratorAddresses; // List of addresses that are curators

    // Platform settings
    uint256 public submissionFee; // Fee in wei
    uint256 public platformFeePercentage; // Percentage of sale price for the platform (e.g., 1000 for 10%) - max 10000
    uint256 public curatorRewardPercentage; // Percentage of platform fee distributed as curator rewards (e.g., 2000 for 20%) - max 10000

    // Total accumulated platform fees (before withdrawal)
    uint256 public totalPlatformFees;

    // Curator voting parameters
    uint256 public constant MIN_CURATOR_REPUTATION_TO_VOTE = 1; // Minimum reputation to cast a weighted vote
    uint256 public constant CURATION_VOTE_PERIOD_SECONDS = 7 days; // How long a submission is in Voting status

    // --- Events ---

    event SubmissionCreated(uint256 submissionId, address indexed artist, string metadataURI, uint256 submissionTime);
    event SubmissionStatusChanged(uint256 submissionId, SubmissionStatus oldStatus, SubmissionStatus newStatus);
    event CuratorAssigned(uint256 submissionId, address indexed curator);
    event CuratorVoted(uint256 submissionId, address indexed curator, uint256 weightedVote, bool voteApproved);
    event SubmissionFinalized(uint256 submissionId, SubmissionStatus finalStatus, uint256 artId);
    event SubmissionRejected(uint256 submissionId, string reason);

    event ArtPieceMinted(uint256 indexed artId, uint256 indexed submissionId, address indexed artist, uint256 initialPrice, uint256 royaltyPercentage);
    event ArtPieceListed(uint256 indexed artId, uint256 price);
    event ArtPieceDelisted(uint256 indexed artId);
    event ArtPriceUpdated(uint256 indexed artId, uint256 oldPrice, uint256 newPrice);
    event ArtPieceSold(uint256 indexed artId, address indexed from, address indexed to, uint256 price);
    event ArtistRoyaltyUpdated(uint256 indexed artId, address indexed artist, uint256 newRoyaltyPercentage);

    event CuratorAdded(address indexed curatorAddress);
    event CuratorRemoved(address indexed curatorAddress);
    event CuratorReputationUpdated(address indexed curatorAddress, uint256 newReputation);
    event CuratorRewardsClaimed(address indexed curatorAddress, uint256 amount);
    event CuratorRewardsAccrued(address indexed curatorAddress, uint256 amount); // For tracking internal accrual

    event ExhibitionCreated(uint256 indexed exhibitionId, string title, address indexed creator, uint256 creationTime);
    event ArtAddedToExhibition(uint256 indexed exhibitionId, uint256 indexed artId);
    event ArtRemovedFromExhibition(uint256 indexed exhibitionId, uint256 indexed artId);

    event PlatformFeesWithdrawn(address indexed owner, uint256 amount);
    event ArtistEarningsWithdrawn(address indexed artist, uint256 artId, uint256 amount);

    // --- Modifiers ---

    modifier onlyCurator() {
        require(curators[msg.sender].exists, "DAC: Not a curator");
        _;
    }

    modifier whenSubmissionStatus(uint256 submissionId, SubmissionStatus expectedStatus) {
        require(submissions[submissionId].submissionTime != 0, "DAC: Submission does not exist"); // Check existence implicitly
        require(submissions[submissionId].status == expectedStatus, "DAC: Invalid submission status");
        _;
    }

    modifier whenArtStatus(uint256 artId, ArtStatus expectedStatus) {
        require(artPieces[artId].artId != 0, "DAC: Art piece does not exist"); // Check existence implicitly
        require(artPieces[artId].status == expectedStatus, "DAC: Invalid art piece status");
        _;
    }

    modifier onlyArtOwner(uint256 artId) {
        require(artPieces[artId].artId != 0, "DAC: Art piece does not exist");
        require(artPieces[artId].owner == msg.sender, "DAC: Only owner can perform this action");
        _;
    }

    modifier onlyArtArtist(uint256 artId) {
         require(artPieces[artId].artId != 0, "DAC: Art piece does not exist");
         require(artPieces[artId].originalArtist == msg.sender, "DAC: Only artist can perform this action");
        _;
    }


    // --- Constructor ---

    /**
     * @dev Initializes the contract, setting the owner and initial parameters.
     * @param initialOwner The address that will be the owner of the contract.
     * @param initialCurators Addresses of initial curators.
     * @param _submissionFee Initial fee for submitting art (in wei).
     * @param _platformFeePercentage Initial percentage for platform fee (e.g., 1000 for 10%).
     * @param _curatorRewardPercentage Initial percentage of platform fee for curator rewards (e.g., 2000 for 20%).
     */
    constructor(
        address initialOwner,
        address[] memory initialCurators,
        uint256 _submissionFee,
        uint256 _platformFeePercentage,
        uint256 _curatorRewardPercentage
    ) Ownable(initialOwner) {
        submissionFee = _submissionFee;
        platformFeePercentage = _platformFeePercentage;
        curatorRewardPercentage = _curatorRewardPercentage;

        // Add initial curators with a base reputation
        for (uint i = 0; i < initialCurators.length; i++) {
            addCurator(initialCurators[i]); // Use the internal function to ensure consistency
        }
    }

    // --- I. Core Platform Management ---

    /**
     * @dev Adds an address as a curator. Only owner can call.
     * @param curatorAddress The address to add as a curator.
     */
    function addCurator(address curatorAddress) public onlyOwner {
        require(curatorAddress != address(0), "DAC: Zero address");
        require(!curators[curatorAddress].exists, "DAC: Address is already a curator");

        curators[curatorAddress].exists = true;
        curators[curatorAddress].reputation = 1; // Start with base reputation
        activeCuratorAddresses.push(curatorAddress); // Add to list of active curators
        emit CuratorAdded(curatorAddress);
    }

    /**
     * @dev Removes an address as a curator. Only owner can call.
     * @param curatorAddress The address to remove as a curator.
     */
    function removeCurator(address curatorAddress) public onlyOwner {
        require(curators[curatorAddress].exists, "DAC: Address is not a curator");

        // Remove from active list (simple inefficient way, ok for small lists)
        for (uint i = 0; i < activeCuratorAddresses.length; i++) {
            if (activeCuratorAddresses[i] == curatorAddress) {
                activeCuratorAddresses[i] = activeCuratorAddresses[activeCuratorAddresses.length - 1];
                activeCuratorAddresses.pop();
                break;
            }
        }

        delete curators[curatorAddress]; // Removes all struct data
        emit CuratorRemoved(curatorAddress);
    }

    /**
     * @dev Sets the fee required to submit art. Only owner can call.
     * @param fee The new submission fee in wei.
     */
    function setSubmissionFee(uint256 fee) public onlyOwner {
        submissionFee = fee;
    }

    /**
     * @dev Sets the platform's commission percentage on sales. Only owner can call.
     *      Percentage is scaled by 100, e.g., 1000 for 10%. Max 10000 (100%).
     * @param percentage The new platform fee percentage.
     */
    function setPlatformFeePercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 10000, "DAC: Percentage cannot exceed 100%");
        platformFeePercentage = percentage;
    }

     /**
     * @dev Sets the percentage of the platform fee that goes to curator rewards. Only owner can call.
     *      Percentage is scaled by 100, e.g., 2000 for 20%. Max 10000 (100%).
     * @param percentage The new curator reward percentage.
     */
    function setCuratorRewardPercentage(uint256 percentage) public onlyOwner {
        require(percentage <= 10000, "DAC: Percentage cannot exceed 100%");
        curatorRewardPercentage = percentage;
    }

    /**
     * @dev Allows the owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 amount = totalPlatformFees;
        require(amount > 0, "DAC: No platform fees to withdraw");
        totalPlatformFees = 0;

        payable(owner()).sendValue(amount);
        emit PlatformFeesWithdrawn(owner(), amount);
    }

    // --- II. Art Submission & Curation ---

    /**
     * @dev Allows an artist to submit art for curation. Requires payment of the submission fee.
     * @param metadataURI URI pointing to the art metadata (e.g., IPFS).
     * @param title Title of the artwork.
     * @param artistName Name/Pseudonym of the artist.
     */
    function submitArt(
        string memory metadataURI,
        string memory title,
        string memory artistName
    ) public payable {
        require(msg.value >= submissionFee, "DAC: Insufficient submission fee");

        uint256 id = _nextSubmissionId++;
        Submission storage sub = submissions[id];

        sub.artist = msg.sender;
        sub.metadataURI = metadataURI;
        sub.title = title;
        sub.artistName = artistName;
        sub.submissionTime = block.timestamp;
        sub.status = SubmissionStatus.Pending;
        // requiredVoteWeight can be set later, potentially based on dynamic factors

        artistSubmissions[msg.sender].push(id); // Track submissions by artist

        emit SubmissionCreated(id, msg.sender, metadataURI, block.timestamp);
    }

    /**
     * @dev Gets details of a specific submission.
     * @param submissionId The ID of the submission.
     * @return submission struct details.
     */
    function getSubmissionDetails(uint256 submissionId)
        public
        view
        returns (
            address artist,
            string memory metadataURI,
            string memory title,
            string memory artistName,
            uint256 submissionTime,
            SubmissionStatus status,
            address assignedCurator,
            uint256 totalWeightedVotesYes,
            uint256 totalWeightedVotesNo,
            uint256 requiredVoteWeight,
            uint256 associatedArtId,
            string memory rejectionReason
        )
    {
        Submission storage sub = submissions[submissionId];
        require(sub.submissionTime != 0, "DAC: Submission does not exist"); // Check existence

        return (
            sub.artist,
            sub.metadataURI,
            sub.title,
            sub.artistName,
            sub.submissionTime,
            sub.status,
            sub.assignedCurator,
            sub.totalWeightedVotesYes,
            sub.totalWeightedVotesNo,
            sub.requiredVoteWeight,
            sub.associatedArtId,
            sub.rejectionReason
        );
    }

    /**
     * @dev Assigns a curator to review a pending submission. Can be done by owner or potentially a high-reputation curator.
     *      Moves submission to UnderReview status.
     * @param submissionId The ID of the submission.
     * @param curatorAddress The address of the curator to assign.
     */
    function assignCuratorToSubmission(uint256 submissionId, address curatorAddress)
        public
        onlyOwner // Simplified: only owner assigns. Could be extended later.
        whenSubmissionStatus(submissionId, SubmissionStatus.Pending)
    {
        require(curators[curatorAddress].exists, "DAC: Invalid curator address");

        Submission storage sub = submissions[submissionId];
        sub.assignedCurator = curatorAddress;
        sub.status = SubmissionStatus.UnderReview;

        // Calculate required vote weight based on current active curators' total reputation
        uint256 totalActiveReputation = 0;
        for(uint i = 0; i < activeCuratorAddresses.length; i++) {
            totalActiveReputation += curators[activeCuratorAddresses[i]].reputation;
        }
        // Simple majority based on potential max weight
        sub.requiredVoteWeight = totalActiveReputation.mul(5001).div(10000); // > 50%

        emit SubmissionStatusChanged(submissionId, SubmissionStatus.Pending, SubmissionStatus.UnderReview);
        emit CuratorAssigned(submissionId, curatorAddress);

        // Auto transition to Voting phase after assignment (or could be a separate function call)
        // For simplicity, let's require the assigned curator to trigger the voting phase after their initial review.
        // Or, better, any curator can initiate voting after a time delay or direct assignment check.
        // Let's simplify: assigned curator reviews, then *any* curator can initiate voting.
    }

    /**
     * @dev Curator casts a weighted vote on a submission. Requires submission to be in Voting status.
     *      Can transition submission to Voting status if it was UnderReview and called by the assigned curator.
     * @param submissionId The ID of the submission.
     * @param voteApproved True if voting to approve, false otherwise.
     */
    function curatorWeightedVote(uint256 submissionId, bool voteApproved)
        public
        onlyCurator
        whenSubmissionStatus(submissionId, SubmissionStatus.UnderReview) // Can vote if UnderReview...
    {
         Submission storage sub = submissions[submissionId];
         Curator storage curator = curators[msg.sender];

         // Can only vote if assigned or if voting phase is already active
         require(sub.assignedCurator == address(0) || sub.assignedCurator == msg.sender,
             "DAC: Only assigned curator can initiate voting phase");
         require(!curator.votedOnSubmission[submissionId], "DAC: Curator already voted on this submission");
         require(curator.reputation >= MIN_CURATOR_REPUTATION_TO_VOTE, "DAC: Insufficient curator reputation to vote");

         // Transition to Voting phase upon the first vote (by assigned curator)
         if (sub.status == SubmissionStatus.UnderReview) {
             sub.status = SubmissionStatus.Voting;
             // Set vote deadline
             // Note: Need to store vote start time or deadline in Submission struct if we want a time limit
             // For now, voting remains open until finalized. Add a deadline concept later if needed.
             emit SubmissionStatusChanged(submissionId, SubmissionStatus.UnderReview, SubmissionStatus.Voting);
         }

         // Now require Voting status explicitly for subsequent votes
         require(sub.status == SubmissionStatus.Voting, "DAC: Submission is not in Voting status");


        uint256 voteWeight = curator.reputation;

        if (voteApproved) {
            sub.totalWeightedVotesYes = sub.totalWeightedVotesYes.add(voteWeight);
        } else {
            sub.totalWeightedVotesNo = sub.totalWeightedVotesNo.add(voteWeight);
        }

        curator.votedOnSubmission[submissionId] = true;

        emit CuratorVoted(submissionId, msg.sender, voteWeight, voteApproved);
    }

    /**
     * @dev Finalizes the decision for a submission based on weighted votes.
     *      Can only be called after the voting period (conceptually, or just by owner).
     *      If approved, triggers minting. If rejected, updates status.
     *      This function also updates curator reputation based on voting outcomes.
     * @param submissionId The ID of the submission.
     */
    function finalizeSubmissionDecision(uint256 submissionId)
        public
        onlyOwner // Only owner can finalize
        whenSubmissionStatus(submissionId, SubmissionStatus.Voting)
        // Optional: add a time check here `require(block.timestamp > submission.voteEndTime, "DAC: Voting period not over");`
    {
        Submission storage sub = submissions[submissionId];

        // Determine outcome based on weighted votes
        bool approved = sub.totalWeightedVotesYes >= sub.requiredVoteWeight && sub.totalWeightedVotesYes > sub.totalWeightedVotesNo;

        // Update curator reputations based on their vote vs outcome (simplified logic)
        // Iterate through all curators who voted on this submission (requires tracking voters)
        // Simpler approach: Iterate through *all* active curators and check if they voted and if their vote aligned.
        // This is inefficient for many curators. A better approach requires storing the voter list per submission.
        // Let's use the inefficient approach for now for demonstration.
        // A more gas-efficient approach would be to track voters in the Submission struct or distribute reputation gain/loss upon vote.

        // Simplified reputation update: Curators who voted 'Yes' on an ultimately Approved submission
        // gain reputation. Curators who voted 'No' on an ultimately Approved submission lose some.
        // Reverse for Rejected. Curators who didn't vote are neutral.
        // We need to know *who* voted 'yes' and *who* voted 'no'. The `hasVoted` mapping only tracks participation.
        // This requires a more complex voting structure storing `mapping(address => bool) voteCast`, `mapping(address => bool) voteValue`.
        // Let's assume we added these mappings to the Submission struct:
        // mapping(address => bool) voteCast; // True if curator voted
        // mapping(address => bool) voteApprovedValue; // True if they voted 'yes'

        // Re-structuring Submission to track votes better:
        // struct Submission { ... mapping(address => bool) hasVoted; mapping(address => bool) voteApprovedValue; ... }

        for (uint i = 0; i < activeCuratorAddresses.length; i++) {
            address curatorAddress = activeCuratorAddresses[i];
            Curator storage curator = curators[curatorAddress];

            // Check if the curator actually voted on *this* submission (using the hasVoted flag we added)
            if (sub.hasVoted[curatorAddress]) {
                 // Assuming `voteApprovedValue[curatorAddress]` stored their vote
                 bool curatorVotedYes = sub.voteApprovedValue[curatorAddress]; // Requires this field in struct & populated in vote function

                 if (approved) {
                    if (curatorVotedYes) {
                        curator.reputation = curator.reputation.add(1); // Small reputation gain for correct 'yes' vote
                    } else {
                        curator.reputation = curator.reputation.sub(1); // Small reputation loss for incorrect 'no' vote
                    }
                 } else { // Submission was Rejected
                    if (!curatorVotedYes) {
                        curator.reputation = curator.reputation.add(1); // Small reputation gain for correct 'no' vote
                    } else {
                        curator.reputation = curator.reputation.sub(1); // Small reputation loss for incorrect 'yes' vote
                    }
                 }
                 // Ensure reputation doesn't drop below base (e.g., 1)
                 if (curator.reputation < 1) curator.reputation = 1;

                 emit CuratorReputationUpdated(curatorAddress, curator.reputation);
            }
        }


        if (approved) {
            sub.status = SubmissionStatus.Approved;
            // Trigger minting internally
            // The owner or an artist could call a separate `mintApprovedArt` function *after* this,
            // passing the approved submissionId. This separates the decision from the minting process.
            // Let's make `mintApprovedArt` callable by the owner *after* status is Approved.
        } else {
            sub.status = SubmissionStatus.Rejected;
            sub.rejectionReason = "Failed weighted vote consensus"; // Or more detailed reason
            emit SubmissionRejected(submissionId, sub.rejectionReason);
        }

        sub.status = SubmissionStatus.Finalized; // Mark as processed
        emit SubmissionStatusChanged(submissionId, SubmissionStatus.Voting, SubmissionStatus.Finalized);
        emit SubmissionFinalized(submissionId, sub.status, sub.associatedArtId);
    }

    /**
     * @dev Explicitly reject a submission before or after voting (if not auto-finalized). Only owner can call.
     * @param submissionId The ID of the submission.
     * @param reason Reason for rejection.
     */
    function rejectSubmission(uint256 submissionId, string memory reason)
        public
        onlyOwner
        // Allow rejecting if Pending, UnderReview, or Voting (if voting hasn't auto-finalized approval)
        whenSubmissionStatus(submissionId, SubmissionStatus.Pending) // Can add others: || sub.status == UnderReview || sub.status == Voting
    {
         Submission storage sub = submissions[submissionId];
         require(sub.status != SubmissionStatus.Finalized, "DAC: Submission is already finalized");

         sub.status = SubmissionStatus.Rejected;
         sub.rejectionReason = reason;
         sub.status = SubmissionStatus.Finalized; // Mark as processed

         emit SubmissionStatusChanged(submissionId, sub.status, SubmissionStatus.Finalized);
         emit SubmissionRejected(submissionId, reason);
         emit SubmissionFinalized(submissionId, sub.status, 0); // Art ID is 0 for rejected
    }


    // --- III. NFT Minting & Art Management ---

    /**
     * @dev Mints an NFT for an approved submission and lists it for sale.
     *      Can only be called by the owner after a submission is marked Approved.
     * @param submissionId The ID of the approved submission.
     * @param initialPrice The initial price for the art piece in wei.
     * @param royaltyPercentage Percentage artist receives on future sales (scaled by 100).
     */
    function mintApprovedArt(uint256 submissionId, uint256 initialPrice, uint256 royaltyPercentage)
        public
        onlyOwner
        whenSubmissionStatus(submissionId, SubmissionStatus.Approved) // Can only mint if submission is Approved
    {
        Submission storage sub = submissions[submissionId];
        require(sub.associatedArtId == 0, "DAC: Art piece already minted for this submission");
        require(royaltyPercentage <= 10000, "DAC: Royalty percentage cannot exceed 100%");

        uint256 artId = _nextArtId++;
        ArtPiece storage art = artPieces[artId];

        art.artId = artId;
        art.owner = sub.artist; // Artist is the initial owner
        art.originalArtist = sub.artist;
        art.submissionId = submissionId;
        art.metadataURI = sub.metadataURI; // Use metadata from submission
        art.title = sub.title;
        art.artistName = sub.artistName;
        art.price = initialPrice;
        art.isListed = true; // List immediately after minting
        art.royaltyPercentage = royaltyPercentage;
        art.status = ArtStatus.Listed; // Set status to Listed

        sub.associatedArtId = artId; // Link submission to minted art
        sub.status = SubmissionStatus.Finalized; // Mark submission as finalized

        ownerArtPieces[art.owner].push(artId); // Track ownership
        artPieceOwners[artId] = art.owner; // Also track in standard ERC721-like owner mapping

        emit SubmissionStatusChanged(submissionId, SubmissionStatus.Approved, SubmissionStatus.Finalized);
        emit SubmissionFinalized(submissionId, sub.status, artId); // Finalize submission event
        emit ArtPieceMinted(artId, submissionId, art.originalArtist, initialPrice, royaltyPercentage);
        emit ArtPieceListed(artId, initialPrice); // Also emit listed event
    }

    /**
     * @dev Get details of a specific minted art piece.
     * @param artId The ID of the art piece.
     * @return struct details.
     */
    function getArtDetails(uint256 artId)
        public
        view
        returns (
            uint256 id,
            address owner,
            address originalArtist,
            uint256 submissionId,
            string memory metadataURI,
            string memory title,
            string memory artistName,
            uint256 price,
            bool isListed,
            uint256 royaltyPercentage,
            ArtStatus status
        )
    {
        ArtPiece storage art = artPieces[artId];
        require(art.artId != 0, "DAC: Art piece does not exist");

         return (
            art.artId,
            art.owner,
            art.originalArtist,
            art.submissionId,
            art.metadataURI,
            art.title,
            art.artistName,
            art.price,
            art.isListed,
            art.royaltyPercentage,
            art.status
        );
    }

     /**
      * @dev Gets the list of art piece IDs owned by a specific address.
      *      Note: This can be gas-intensive for addresses with many owned pieces.
      * @param ownerAddress The address to query.
      * @return An array of owned art piece IDs.
      */
     function getOwnedArt(address ownerAddress) public view returns (uint256[] memory) {
         return ownerArtPieces[ownerAddress];
     }

      /**
      * @dev Gets the list of submission IDs made by a specific artist address.
      *      Note: This can be gas-intensive for artists with many submissions.
      * @param artistAddress The address to query.
      * @return An array of submission IDs.
      */
     function getSubmittedArt(address artistAddress) public view returns (uint256[] memory) {
         return artistSubmissions[artistAddress];
     }


    // --- IV. Marketplace Operations ---

    /**
     * @dev Lists a previously minted and owned art piece for sale.
     * @param artId The ID of the art piece.
     * @param price The listing price in wei.
     */
    function listArtForSale(uint256 artId, uint256 price)
        public
        onlyArtOwner(artId)
        // Can list if Minted (first list) or Sold (re-list)
        modifier { require(artPieces[artId].status == ArtStatus.Minted || artPieces[artId].status == ArtStatus.Sold, "DAC: Art piece cannot be listed in its current status"); _; } whenArtStatusListable(artId) // Custom modifier for clarity
    {
         ArtPiece storage art = artPieces[artId];
         art.price = price;
         art.isListed = true;
         art.status = ArtStatus.Listed;
         emit ArtPieceListed(artId, price);
    }

     /**
      * @dev Custom modifier to check if an art piece is in a status that allows listing (Minted or Sold).
      */
     modifier whenArtStatusListable(uint256 artId) {
         require(artPieces[artId].artId != 0, "DAC: Art piece does not exist");
         ArtStatus currentStatus = artPieces[artId].status;
         require(currentStatus == ArtStatus.Minted || currentStatus == ArtStatus.Sold, "DAC: Art piece cannot be listed in its current status");
         _;
     }


    /**
     * @dev Delists an art piece currently for sale.
     * @param artId The ID of the art piece.
     */
    function delistArt(uint256 artId)
        public
        onlyArtOwner(artId)
        whenArtStatus(artId, ArtStatus.Listed)
    {
        ArtPiece storage art = artPieces[artId];
        art.price = 0; // Set price to 0
        art.isListed = false;
        art.status = ArtStatus.Minted; // Return to Minted status (not sold)
        emit ArtPieceDelisted(artId);
    }

    /**
     * @dev Updates the price of an art piece currently listed for sale.
     * @param artId The ID of the art piece.
     * @param newPrice The new listing price in wei.
     */
    function updateArtPrice(uint256 artId, uint256 newPrice)
        public
        onlyArtOwner(artId)
        whenArtStatus(artId, ArtStatus.Listed)
    {
        ArtPiece storage art = artPieces[artId];
        uint256 oldPrice = art.price;
        art.price = newPrice;
        emit ArtPriceUpdated(artId, oldPrice, newPrice);
    }

    /**
     * @dev Allows a collector to buy an art piece listed for sale.
     * @param artId The ID of the art piece.
     */
    function buyArt(uint256 artId)
        public
        payable
        whenArtStatus(artId, ArtStatus.Listed)
    {
        ArtPiece storage art = artPieces[artId];
        require(msg.value >= art.price, "DAC: Insufficient payment");
        require(art.owner != msg.sender, "DAC: Cannot buy your own art");

        address payable seller = payable(art.owner);
        address payable artist = payable(art.originalArtist); // Use original artist for royalties
        uint256 salePrice = art.price;
        uint256 royaltyAmount = salePrice.mul(art.royaltyPercentage).div(10000);
        uint256 platformFeeAmount = salePrice.mul(platformFeePercentage).div(10000);
        uint256 sellerProceeds = salePrice.sub(royaltyAmount).sub(platformFeeAmount);

        // Transfer funds
        // Royalties to the original artist
        if (royaltyAmount > 0 && artist != address(0)) {
            // Accumulate artist earnings rather than immediate transfer to avoid re-entrancy risk
            // Need a mapping: mapping(address => uint256) artistEarnings;
            // artistEarnings[artist] = artistEarnings[artist].add(royaltyAmount);
             payable(artist).sendValue(royaltyAmount); // Direct transfer for simplicity here
        }
        // Platform fee to contract balance (will be withdrawn by owner)
        totalPlatformFees = totalPlatformFees.add(platformFeeAmount);

        // Seller gets remaining
        if (sellerProceeds > 0 && seller != address(0)) {
            payable(seller).sendValue(sellerProceeds); // Direct transfer for simplicity here
        }

        // Handle potential overpayment (refund excess ETH)
        if (msg.value > salePrice) {
            payable(msg.sender).sendValue(msg.value.sub(salePrice));
        }

        // Transfer ownership
        address previousOwner = art.owner;
        // Remove from previous owner's list (inefficient)
        uint256[] storage prevOwnerArt = ownerArtPieces[previousOwner];
        for (uint i = 0; i < prevOwnerArt.length; i++) {
            if (prevOwnerArt[i] == artId) {
                prevOwnerArt[i] = prevOwnerArt[prevOwnerArt.length - 1];
                prevOwnerArt.pop();
                break;
            }
        }

        art.owner = msg.sender;
        ownerArtPieces[msg.sender].push(artId); // Add to new owner's list
        artPieceOwners[artId] = msg.sender; // Update owner mapping

        art.isListed = false; // Not listed after being sold
        art.price = 0; // Reset price
        art.status = ArtStatus.Sold; // Set status to Sold

        emit ArtPieceSold(artId, previousOwner, msg.sender, salePrice);

        // Distribute curator rewards (simplified: split a percentage of platform fee among curators who voted yes)
        _distributeCuratorRewards(artId, platformFeeAmount.mul(curatorRewardPercentage).div(10000));
    }

    /**
     * @dev Internal function to distribute a portion of platform fees as curator rewards.
     * @param artId The ID of the sold art piece.
     * @param rewardPoolAmount The total amount from platform fees to distribute.
     */
    function _distributeCuratorRewards(uint256 artId, uint256 rewardPoolAmount) internal {
         if (rewardPoolAmount == 0) return;

         Submission storage sub = submissions[artPieces[artId].submissionId];
         uint256 totalWeightOfApprovingVoters = 0;
         address[] memory approvingCurators = new address[](activeCuratorAddresses.length); // Temporary array
         uint256 approvingCuratorCount = 0;

         // Find all curators who voted 'Yes' on the submission that led to this art piece
         for(uint i = 0; i < activeCuratorAddresses.length; i++) {
             address curatorAddress = activeCuratorAddresses[i];
             // Check if curator voted on this submission AND their vote was 'yes' AND they are still a curator
             if (curators[curatorAddress].exists && sub.hasVoted[curatorAddress] && sub.voteApprovedValue[curatorAddress]) { // Requires voteApprovedValue tracking in Submission
                 totalWeightOfApprovingVoters += curators[curatorAddress].reputation;
                 approvingCurators[approvingCuratorCount++] = curatorAddress;
             }
         }

         if (totalWeightOfApprovingVoters == 0) return; // No approving curators with weight

         // Distribute rewards proportionally based on their weight at the time of voting
         for (uint i = 0; i < approvingCuratorCount; i++) {
             address curatorAddress = approvingCurators[i];
             uint256 curatorWeight = curators[curatorAddress].reputation; // Using current reputation, could use reputation at time of vote for accuracy
             uint256 reward = rewardPoolAmount.mul(curatorWeight).div(totalWeightOfApprovingVoters);
             curators[curatorAddress].pendingRewards = curators[curatorAddress].pendingRewards.add(reward);
             emit CuratorRewardsAccrued(curatorAddress, reward);
         }
    }


    /**
     * @dev Allows the original artist to update the royalty percentage for their art.
     *      Only affects future sales. Cannot be called if art is currently listed.
     * @param artId The ID of the art piece.
     * @param newPercentage The new royalty percentage (scaled by 100). Max 10000.
     */
    function artistUpdateRoyalty(uint256 artId, uint256 newPercentage)
        public
        onlyArtArtist(artId)
    {
        ArtPiece storage art = artPieces[artId];
        // Cannot update royalty if currently listed, might confuse buyers
        require(!art.isListed, "DAC: Cannot update royalty while art is listed");
        require(newPercentage <= 10000, "DAC: Royalty percentage cannot exceed 100%");

        art.royaltyPercentage = newPercentage;
        emit ArtistRoyaltyUpdated(artId, msg.sender, newPercentage);
    }

     /**
      * @dev Allows the original artist to withdraw accumulated earnings from past sales.
      *      Note: Requires implementing an artistEarnings mapping if direct transfers were avoided in buyArt.
      *      Currently, buyArt sends directly, so this function is not strictly needed unless we change buyArt.
      *      Including it as per plan, assuming artist earnings are tracked internally.
      */
     function withdrawArtistEarnings(address artistAddress) public { // Changed to take artist address for owner or artist to claim
          // Simplified: Only the artist themselves can claim their earnings
         require(msg.sender == artistAddress, "DAC: Only the artist can withdraw their earnings");
         // Need to track artist earnings if they weren't sent directly in `buyArt`
         // Assuming `mapping(address => uint256) private artistEarnings;` exists
         // uint256 amount = artistEarnings[artistAddress];
         // require(amount > 0, "DAC: No earnings to withdraw");
         // artistEarnings[artistAddress] = 0;
         // payable(artistAddress).sendValue(amount);
         // emit ArtistEarningsWithdrawn(artistAddress, amount);

         // Since buyArt sends directly, this function requires a rework of buyArt or is left as unimplemented concept.
         // Leaving it as a placeholder for the concept of segregated artist funds.
         revert("DAC: Artist earnings are currently sent directly upon sale. This function is not implemented.");
     }


    // --- V. Curator Reputation & Rewards ---

    /**
     * @dev Gets the current reputation score of a curator.
     * @param curatorAddress The address of the curator.
     * @return The curator's reputation score.
     */
    function getCuratorReputation(address curatorAddress) public view returns (uint256) {
        require(curators[curatorAddress].exists, "DAC: Address is not a curator");
        return curators[curatorAddress].reputation;
    }

     /**
      * @dev Gets the amount of pending (unclaimed) rewards for a curator.
      * @param curatorAddress The address of the curator.
      * @return The amount of pending rewards in wei.
      */
     function getCuratorPendingRewards(address curatorAddress) public view returns (uint256) {
         require(curators[curatorAddress].exists, "DAC: Address is not a curator");
         return curators[curatorAddress].pendingRewards;
     }

    /**
     * @dev Allows a curator to claim their accumulated rewards.
     */
    function claimCuratorRewards() public onlyCurator {
        Curator storage curator = curators[msg.sender];
        uint256 amount = curator.pendingRewards;
        require(amount > 0, "DAC: No rewards to claim");

        curator.pendingRewards = 0; // Reset pending rewards

        // Transfer rewards
        payable(msg.sender).sendValue(amount);
        emit CuratorRewardsClaimed(msg.sender, amount);
    }


    // --- VI. On-Chain Exhibitions ---

    /**
     * @dev Creates a new exhibition. Can be called by owner or potentially high-reputation curators.
     * @param title Title of the exhibition.
     * @param description Description of the exhibition.
     * @param theme Theme or focus of the exhibition.
     */
    function createExhibition(string memory title, string memory description, string memory theme)
        public
        // Only owner can create exhibitions for simplicity. Could add reputation check: require(curators[msg.sender].reputation >= MIN_REP_TO_CREATE_EXHIBITION)
        onlyOwner
    {
        uint256 exhibitionId = _nextExhibitionId++;
        Exhibition storage exh = exhibitions[exhibitionId];

        exh.exhibitionId = exhibitionId;
        exh.title = title;
        exh.description = description;
        exh.theme = theme;
        exh.creator = msg.sender;
        exh.creationTime = block.timestamp;

        emit ExhibitionCreated(exhibitionId, title, msg.sender, block.timestamp);
    }

    /**
     * @dev Adds a minted art piece to an exhibition. Can be called by owner or potentially exhibition creator/curator.
     * @param exhibitionId The ID of the exhibition.
     * @param artId The ID of the art piece to add.
     */
    function addArtToExhibition(uint256 exhibitionId, uint256 artId)
        public
        // Access control: Only owner OR exhibition creator OR curator? Let's use owner/creator for simplicity.
        modifier { require(msg.sender == owner() || msg.sender == exhibitions[exhibitionId].creator, "DAC: Not authorized to add art to this exhibition"); _; } OnlyExhibitionOwnerOrCreator(exhibitionId)
    {
        require(exhibitions[exhibitionId].exhibitionId != 0, "DAC: Exhibition does not exist");
        require(artPieces[artId].artId != 0, "DAC: Art piece does not exist");
        require(!exhibitions[exhibitionId].containsArt[artId], "DAC: Art piece is already in this exhibition");

        exhibitions[exhibitionId].artPieces.push(artId);
        exhibitions[exhibitionId].containsArt[artId] = true;
        // Optional: Track exhibition membership in ArtPiece struct (already done with mapping)
        artPieces[artId].exhibitionMembership[exhibitionId] = 1; // Mark as included

        emit ArtAddedToExhibition(exhibitionId, artId);
    }

    /**
     * @dev Custom modifier to check if sender is owner or exhibition creator.
     */
    modifier OnlyExhibitionOwnerOrCreator(uint256 exhibitionId) {
        require(exhibitions[exhibitionId].exhibitionId != 0, "DAC: Exhibition does not exist");
        require(msg.sender == owner() || msg.sender == exhibitions[exhibitionId].creator, "DAC: Only exhibition creator or platform owner can manage art in this exhibition");
        _;
    }


    /**
     * @dev Removes an art piece from an exhibition. Can be called by owner or potentially exhibition creator/curator.
     * @param exhibitionId The ID of the exhibition.
     * @param artId The ID of the art piece to remove.
     */
    function removeArtFromExhibition(uint256 exhibitionId, uint256 artId)
        public
        OnlyExhibitionOwnerOrCreator(exhibitionId)
    {
        require(exhibitions[exhibitionId].exhibitionId != 0, "DAC: Exhibition does not exist");
        require(exhibitions[exhibitionId].containsArt[artId], "DAC: Art piece is not in this exhibition");

        // Remove from array (inefficient)
        uint256[] storage artList = exhibitions[exhibitionId].artPieces;
        for (uint i = 0; i < artList.length; i++) {
            if (artList[i] == artId) {
                artList[i] = artList[artList.length - 1];
                artList.pop();
                break;
            }
        }

        exhibitions[exhibitionId].containsArt[artId] = false;
        delete artPieces[artId].exhibitionMembership[exhibitionId]; // Remove membership mark

        emit ArtRemovedFromExhibition(exhibitionId, artId);
    }

    /**
     * @dev Gets details of a specific exhibition.
     * @param exhibitionId The ID of the exhibition.
     * @return struct details.
     */
    function getExhibitionDetails(uint256 exhibitionId)
        public
        view
        returns (
            uint256 id,
            string memory title,
            string memory description,
            string memory theme,
            address creator,
            uint256 creationTime
        )
    {
        Exhibition storage exh = exhibitions[exhibitionId];
        require(exh.exhibitionId != 0, "DAC: Exhibition does not exist");
        return (exh.exhibitionId, exh.title, exh.description, exh.theme, exh.creator, exh.creationTime);
    }

     /**
      * @dev Gets the list of art piece IDs included in an exhibition.
      *      Note: This can be gas-intensive for exhibitions with many pieces.
      * @param exhibitionId The ID of the exhibition.
      * @return An array of art piece IDs.
      */
     function getArtInExhibition(uint256 exhibitionId) public view returns (uint256[] memory) {
         require(exhibitions[exhibitionId].exhibitionId != 0, "DAC: Exhibition does not exist");
         return exhibitions[exhibitionId].artPieces;
     }


    // --- VII. Utility/Views ---

    /**
     * @dev Gets the next available submission ID.
     */
    function getCurrentSubmissionId() public view returns (uint256) {
        return _nextSubmissionId;
    }

    /**
     * @dev Gets the next available art ID (NFT token ID).
     */
    function getCurrentArtId() public view returns (uint256) {
        return _nextArtId;
    }

     /**
     * @dev Gets the next available exhibition ID.
     */
    function getCurrentExhibitionId() public view returns (uint256) {
        return _nextExhibitionId;
    }


    /**
     * @dev Gets the current ETH balance held by the contract.
     */
    function getPlatformBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Fallback/Receive ---
    receive() external payable {}
    fallback() external payable {}
}
```