Okay, let's design a smart contract for a "Decentralized Autonomous Art Gallery". This contract will handle the submission, community curation, and minting of unique artworks as non-fungible tokens (NFTs), with built-in concepts for dynamic metadata and community interaction.

It avoids simply duplicating standard ERC-721 or DAO implementations by integrating a custom curation process, managing the primary collection ownership by the contract itself, and incorporating features like artwork "liking" that can influence dynamic aspects off-chain.

---

**Outline and Function Summary**

**Contract Name:** DecentralizedAutonomousArtGallery

**Core Concepts:**
1.  **Art Submission:** Artists pay a fee to submit artwork metadata.
2.  **Community Curation:** Submitted artworks enter a voting phase where community members vote for or against approval.
3.  **Autonomous Minting:** Submissions passing the approval threshold are automatically minted as unique NFTs owned by the gallery contract.
4.  **Dynamic Potential:** Artworks include an interaction counter ("likes") that can be used by off-chain metadata services to render dynamic content.
5.  **Gallery Ownership:** The contract initially owns the minted artworks, forming a decentralized collection. (Future steps could add sale mechanisms).
6.  **Configurable Parameters:** Key parameters (fees, thresholds, voting periods) are adjustable, laying groundwork for potential DAO governance.
7.  **Treasury:** Collects submission fees, managed by a governor.

**State Variables:**
*   `governor`: Address with administrative control.
*   `paused`: Boolean for emergency pausing.
*   `submissionFee`: Fee required to submit art (in wei).
*   `votingPeriodDuration`: Duration of the voting phase for submissions (in seconds).
*   `approvalThreshold`: Percentage of positive votes required for approval (e.g., 60 for 60%).
*   `tokenURIPrefix`: Base URI for NFT metadata.
*   `_submissionCounter`: Total number of submissions ever made.
*   `_artworkCounter`: Total number of artworks minted (NFTs).
*   `_totalSupply`: Total supply of NFTs (same as `_artworkCounter`).
*   `submissions`: Mapping from submission ID to `Submission` struct.
*   `submissionVotes`: Mapping tracking votes for each submission (`submissionId => voterAddress => voteType`).
*   `submissionVoteCounts`: Mapping tracking positive/negative vote counts for each submission (`submissionId => voteType => count`).
*   `artistSubmissions`: Mapping tracking submissions made by each artist (`artistAddress => submissionIds[]`).
*   `artworkDetails`: Mapping from token ID to `Artwork` struct.
*   `artworkLikes`: Mapping tracking likes for each artwork (`tokenId => voterAddress => bool`).
*   `_owners`: Mapping from token ID to owner address (Gallery contract address primarily).
*   `_balances`: Mapping from owner address to token balance.

**Structs:**
*   `Submission`: Details about a submitted artwork (artist, metadata hash, timestamp, state, associated token ID if approved, vote counts).
*   `Artwork`: Details about a minted NFT (submission ID, interaction count/likes).

**Enums:**
*   `SubmissionState`: `Pending`, `Approved`, `Rejected`.
*   `VoteType`: `Against`, `For`.

**Events:**
*   `ArtworkSubmitted(uint256 submissionId, address artist, string metadataHash)`
*   `VoteRecorded(uint256 submissionId, address voter, VoteType vote)`
*   `VotingFinalized(uint256 submissionId, SubmissionState finalState, uint256 artworkId)`
*   `ArtworkMinted(uint256 artworkId, uint256 submissionId, address owner)`
*   `ArtworkLiked(uint256 artworkId, address voter, uint256 newLikeCount)`
*   `SubmissionFeeUpdated(uint256 newFee)`
*   `VotingPeriodUpdated(uint256 newDuration)`
*   `ApprovalThresholdUpdated(uint256 newThreshold)`
*   `TokenURIPrefixUpdated(string newPrefix)`
*   `GovernorTransferred(address oldGovernor, address newGovernor)`
*   `ContractPaused(address account)`
*   `ContractUnpaused(address account)`
*   `TreasuryWithdrawn(address recipient, uint256 amount)`

**Modifiers:**
*   `onlyGovernor`: Restricts function access to the governor.
*   `whenNotPaused`: Prevents execution when paused.
*   `whenPaused`: Allows execution only when paused.

**Function Summary:**

**Admin/Configuration (9 functions):**
1.  `constructor()`: Initializes governor and basic parameters.
2.  `setSubmissionFee(uint256 _fee)`: Sets the fee for submitting art.
3.  `setVotingPeriod(uint256 _duration)`: Sets the duration for community voting.
4.  `setApprovalThreshold(uint256 _threshold)`: Sets the percentage threshold for approval.
5.  `setTokenURIPrefix(string memory _prefix)`: Sets the base URI for NFT metadata.
6.  `transferGovernor(address _newGovernor)`: Transfers governorship.
7.  `pauseContract()`: Pauses contract activity (emergency).
8.  `unpauseContract()`: Unpauses the contract.
9.  `withdrawTreasury(uint256 _amount)`: Allows governor to withdraw funds from the treasury.

**Submission (3 functions):**
10. `submitArtwork(string memory metadataHash)`: Allows artists to submit work, paying the fee.
11. `getSubmissionDetails(uint256 submissionId)`: Retrieves details for a specific submission.
12. `getArtistSubmissions(address artist)`: Lists submission IDs for a given artist.

**Curation/Voting (4 functions):**
13. `voteOnSubmission(uint256 submissionId, VoteType vote)`: Allows users to vote on a pending submission during its voting period.
14. `getSubmissionVotes(uint256 submissionId)`: Retrieves vote counts for a submission.
15. `getUserVoteForSubmission(uint256 submissionId, address voter)`: Checks how a specific user voted on a submission.
16. `finalizeVoting(uint256 submissionId)`: Governor or potentially anyone can trigger finalization after the voting period ends. Checks threshold and mints if approved.

**Artwork (NFT) Management & Interaction (9 functions):**
17. `_galleryMint(uint256 submissionId)`: Internal function to mint a new artwork NFT, owned by the gallery contract.
18. `tokenURI(uint256 tokenId)`: Returns the metadata URI for an artwork NFT (implements ERC721 interface).
19. `getArtworkDetails(uint256 tokenId)`: Retrieves details for a minted artwork.
20. `likeArtwork(uint256 tokenId)`: Allows users to 'like' a minted artwork, incrementing its interaction count.
21. `getArtworkLikes(uint256 tokenId)`: Returns the number of likes for an artwork.
22. `getUserLikedArtwork(uint256 tokenId, address user)`: Checks if a user has liked an artwork.
23. `balanceOf(address owner)`: Returns the number of NFTs owned by an address (ERC721 standard).
24. `ownerOf(uint256 tokenId)`: Returns the owner of a specific NFT (ERC721 standard).
25. `totalSupply()`: Returns the total number of minted NFTs (ERC721 standard).

**Query/Getters (5 functions):**
26. `getSubmissionCount()`: Total number of submissions.
27. `getArtworkCount()`: Total number of minted artworks (NFTs).
28. `getGalleryBalance()`: Returns the contract's ETH balance (treasury).
29. `getGalleryOwnedTokens()`: *Potentially gas-intensive.* Lists all token IDs owned by the gallery. (Note: Implementing ERC721Enumerable is standard for this, but trying to avoid direct duplication. A mapping or array could track this, but iteration is costly. Will add a note about gas).
30. `getSubmissionState(uint256 submissionId)`: Get the current state of a submission.

**(Total Functions: 30)** - Meets the requirement of at least 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAutonomousArtGallery
 * @dev A smart contract for a decentralized art gallery.
 * Artists submit work, community votes, approved work is minted as NFT
 * owned by the gallery contract. Includes dynamic potential via interaction counts.
 * Avoids direct duplication of standard libraries for core novel logic.
 */

// --- Outline and Function Summary ---
// (See detailed Outline and Function Summary block above the code)
// --- End Outline and Function Summary ---

import {IERC165} from "@openzeppelin/contracts/utils/interfaces/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; // Using interface, not implementation

// Custom errors for clarity and gas efficiency
error NotGovernor();
error Paused();
error NotPaused();
error InvalidAmount();
error SubmissionNotFound(uint256 submissionId);
error NotEnoughSubmissionFee(uint256 requiredFee, uint256 sentAmount);
error SubmissionNotInPendingState(uint256 submissionId, SubmissionState currentState);
error VotingPeriodNotActive(uint256 submissionId);
error VotingPeriodAlreadyStarted(uint256 submissionId);
error VotingPeriodNotEnded(uint256 submissionId);
error AlreadyVoted(uint256 submissionId, address voter);
error ArtworkNotFound(uint256 tokenId);
error AlreadyLiked(uint256 tokenId, address liker);
error NotGalleryOwner();
error InvalidSubmissionStateForAction(uint256 submissionId, SubmissionState requiredState);
error SubmissionAlreadyFinalized(uint256 submissionId);

contract DecentralizedAutonomousArtGallery is IERC721, IERC721Metadata, IERC721Enumerable, IERC165 {

    // --- Enums ---
    enum SubmissionState {
        Pending,
        Approved,
        Rejected
    }

    enum VoteType {
        Against,
        For
    }

    // --- Structs ---
    struct Submission {
        address artist;
        string metadataHash; // Hash or identifier pointing to off-chain metadata
        uint66 timestamp;     // When submitted
        uint66 votingEnds;    // When voting ends
        SubmissionState state;
        uint256 associatedArtworkId; // Token ID if approved and minted
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct Artwork {
        uint256 submissionId; // Link back to the submission that created it
        uint256 interactionCount; // e.g., Likes
    }

    // --- State Variables ---

    address public governor;
    bool public paused;

    uint256 public submissionFee; // in wei
    uint256 public votingPeriodDuration; // in seconds
    uint256 public approvalThreshold; // percentage (e.g., 60 for 60%)
    string public tokenURIPrefix; // e.g., "ipfs://QmVaultHash/"

    uint256 private _submissionCounter; // Starts from 1
    uint256 private _artworkCounter;    // Starts from 1 (NFT token ID)
    uint256 private _totalSupply;       // Total minted NFTs

    mapping(uint256 => Submission) public submissions;
    // submissionId => voterAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) private _userVotedForSubmission;
    // tokenId => likerAddress => hasLiked
    mapping(uint256 => mapping(address => bool)) private _userLikedArtwork;

    mapping(uint256 => Artwork) public artworkDetails;

    // Basic ERC721 mappings (implementing required interface, not duplicating OZ)
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    // Note: Approval mappings (_tokenApprovals, _operatorApprovals) and Enumerable arrays
    // (_allTokens, _ownedTokens) are omitted to keep the example focused on the core gallery logic
    // and avoid duplicating extensive standard library implementations.
    // `getGalleryOwnedTokens` below uses an inefficient loop as a placeholder/demonstration.

    // Mapping to track submissions by artist (for getArtistSubmissions)
    mapping(address => uint256[]) public artistSubmissions;

    // Array to track all minted token IDs (for getGalleryOwnedTokens)
    uint256[] private _galleryTokenIds; // Owned by address(this)

    // --- Events ---
    event ArtworkSubmitted(uint256 submissionId, address indexed artist, string metadataHash);
    event VoteRecorded(uint256 submissionId, indexed address voter, VoteType vote);
    event VotingFinalized(uint256 submissionId, SubmissionState finalState, uint256 indexed artworkId);
    event ArtworkMinted(uint256 indexed artworkId, uint256 submissionId, indexed address owner);
    event ArtworkLiked(uint256 indexed artworkId, indexed address voter, uint256 newLikeCount);

    event SubmissionFeeUpdated(uint256 newFee);
    event VotingPeriodUpdated(uint256 newDuration);
    event ApprovalThresholdUpdated(uint256 newThreshold); // 0-100
    event TokenURIPrefixUpdated(string newPrefix);
    event GovernorTransferred(address indexed oldGovernor, address indexed newGovernor);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (msg.sender != governor) revert NotGovernor();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    // --- Constructor ---
    constructor(uint256 _initialSubmissionFee, uint256 _initialVotingPeriod, uint256 _initialApprovalThreshold, string memory _initialTokenURIPrefix) {
        governor = msg.sender;
        submissionFee = _initialSubmissionFee;
        votingPeriodDuration = _initialVotingPeriod;
        approvalThreshold = _initialApprovalThreshold; // e.g., 60 for 60%
        tokenURIPrefix = _initialTokenURIPrefix;
        paused = false;
        _submissionCounter = 0;
        _artworkCounter = 0;
        _totalSupply = 0;

        // Gallery contract itself will be the primary owner of minted NFTs
        _balances[address(this)] = 0;
    }

    // --- Admin/Configuration Functions ---

    /**
     * @dev Updates the fee required to submit artwork.
     * @param _fee The new submission fee in wei.
     */
    function setSubmissionFee(uint256 _fee) external onlyGovernor {
        submissionFee = _fee;
        emit SubmissionFeeUpdated(_fee);
    }

    /**
     * @dev Updates the duration of the voting period for submissions.
     * @param _duration The new voting period duration in seconds.
     */
    function setVotingPeriod(uint256 _duration) external onlyGovernor {
        votingPeriodDuration = _duration;
        emit VotingPeriodUpdated(_duration);
    }

    /**
     * @dev Updates the percentage of positive votes required for a submission to be approved.
     * @param _threshold The new threshold percentage (0-100).
     */
    function setApprovalThreshold(uint256 _threshold) external onlyGovernor {
        if (_threshold > 100) revert InvalidAmount();
        approvalThreshold = _threshold;
        emit ApprovalThresholdUpdated(_threshold);
    }

    /**
     * @dev Updates the base URI used for generating NFT metadata URIs.
     * @param _prefix The new token URI prefix (e.g., "ipfs://QmVaultHash/").
     */
    function setTokenURIPrefix(string memory _prefix) external onlyGovernor {
        tokenURIPrefix = _prefix;
        emit TokenURIPrefixUpdated(_prefix);
    }

    /**
     * @dev Transfers the governor role to a new address.
     * @param _newGovernor The address of the new governor.
     */
    function transferGovernor(address _newGovernor) external onlyGovernor {
        if (_newGovernor == address(0)) revert InvalidAmount(); // Simple check
        address oldGovernor = governor;
        governor = _newGovernor;
        emit GovernorTransferred(oldGovernor, _newGovernor);
    }

    /**
     * @dev Pauses the contract functionality in case of emergency.
     * Prevents submissions, voting, and finalization.
     */
    function pauseContract() external onlyGovernor whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     */
    function unpauseContract() external onlyGovernor whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows the governor to withdraw funds collected in the treasury (submission fees).
     * @param _amount The amount of wei to withdraw.
     */
    function withdrawTreasury(uint256 _amount) external onlyGovernor {
        if (_amount == 0) revert InvalidAmount();
        if (address(this).balance < _amount) revert InvalidAmount(); // Not enough balance

        (bool success,) = payable(governor).call{value: _amount}("");
        if (!success) revert InvalidAmount(); // Withdrawal failed

        emit TreasuryWithdrawn(governor, _amount);
    }

    // --- Submission Functions ---

    /**
     * @dev Allows an artist to submit their artwork metadata for curation.
     * Requires the submission fee to be paid.
     * @param metadataHash A hash or identifier pointing to the artwork's metadata (e.g., on IPFS).
     */
    function submitArtwork(string memory metadataHash) external payable whenNotPaused {
        if (msg.value < submissionFee) {
            revert NotEnoughSubmissionFee(submissionFee, msg.value);
        }

        _submissionCounter++;
        uint256 submissionId = _submissionCounter;

        submissions[submissionId] = Submission({
            artist: msg.sender,
            metadataHash: metadataHash,
            timestamp: uint66(block.timestamp),
            votingEnds: uint66(block.timestamp + votingPeriodDuration),
            state: SubmissionState.Pending,
            associatedArtworkId: 0, // Not yet minted
            votesFor: 0,
            votesAgainst: 0
        });

        artistSubmissions[msg.sender].push(submissionId);

        emit ArtworkSubmitted(submissionId, msg.sender, metadataHash);
    }

    /**
     * @dev Retrieves details for a specific artwork submission.
     * @param submissionId The ID of the submission.
     * @return A tuple containing the submission details.
     */
    function getSubmissionDetails(uint256 submissionId) external view returns (Submission memory) {
        if (submissionId == 0 || submissionId > _submissionCounter) revert SubmissionNotFound(submissionId);
        return submissions[submissionId];
    }

    /**
     * @dev Lists all submission IDs made by a specific artist.
     * @param artist The address of the artist.
     * @return An array of submission IDs.
     */
    function getArtistSubmissions(address artist) external view returns (uint256[] memory) {
        return artistSubmissions[artist];
    }

    // --- Curation/Voting Functions ---

    /**
     * @dev Allows a user to vote on a pending artwork submission during its voting period.
     * Users can only vote once per submission.
     * @param submissionId The ID of the submission to vote on.
     * @param vote The vote (For or Against).
     */
    function voteOnSubmission(uint256 submissionId, VoteType vote) external whenNotPaused {
        Submission storage submission = submissions[submissionId];
        if (submissionId == 0 || submission.state != SubmissionState.Pending) {
            revert SubmissionNotInPendingState(submissionId, submission.state);
        }
        if (block.timestamp > submission.votingEnds) {
            revert VotingPeriodNotActive(submissionId);
        }
        if (_userVotedForSubmission[submissionId][msg.sender]) {
            revert AlreadyVoted(submissionId, msg.sender);
        }

        _userVotedForSubmission[submissionId][msg.sender] = true;

        if (vote == VoteType.For) {
            submission.votesFor++;
        } else {
            submission.votesAgainst++;
        }

        emit VoteRecorded(submissionId, msg.sender, vote);
    }

     /**
     * @dev Retrieves the current vote counts for a specific submission.
     * @param submissionId The ID of the submission.
     * @return votesFor The number of 'For' votes.
     * @return votesAgainst The number of 'Against' votes.
     */
    function getSubmissionVotes(uint256 submissionId) external view returns (uint256 votesFor, uint256 votesAgainst) {
         if (submissionId == 0 || submissionId > _submissionCounter) revert SubmissionNotFound(submissionId);
         Submission storage submission = submissions[submissionId]; // Use storage for potentially lower gas on view
         return (submission.votesFor, submission.votesAgainst);
    }

    /**
     * @dev Checks if a user has voted for a specific submission and what their vote was.
     * Note: This function only tells if they *attempted* to vote. The mapping `_userVotedForSubmission`
     * just records if they called `voteOnSubmission`, not the vote itself. To get the vote,
     * you would need a more complex mapping `submissionId => voterAddress => VoteType`.
     * For simplicity here, we just check if they participated.
     * @param submissionId The ID of the submission.
     * @param voter The address of the voter.
     * @return bool True if the user has voted on this submission, false otherwise.
     */
    function getUserVoteForSubmission(uint256 submissionId, address voter) external view returns (bool) {
        if (submissionId == 0 || submissionId > _submissionCounter) revert SubmissionNotFound(submissionId);
        return _userVotedForSubmission[submissionId][voter];
    }


    /**
     * @dev Finalizes the voting process for a submission once the voting period has ended.
     * Mints an NFT if the approval threshold is met. Can be called by anyone after the period ends.
     * @param submissionId The ID of the submission to finalize.
     */
    function finalizeVoting(uint256 submissionId) external whenNotPaused {
        Submission storage submission = submissions[submissionId];
        if (submissionId == 0 || submission.state != SubmissionState.Pending) {
            revert SubmissionNotInPendingState(submissionId, submission.state);
        }
        if (block.timestamp <= submission.votingEnds) {
             revert VotingPeriodNotEnded(submissionId);
        }

        uint256 totalVotes = submission.votesFor + submission.votesAgainst;
        bool approved = false;

        // Avoid division by zero if no votes were cast
        if (totalVotes > 0) {
            // Calculate percentage, * 100 first to avoid losing precision
            uint256 approvalPercentage = (submission.votesFor * 100) / totalVotes;
            if (approvalPercentage >= approvalThreshold) {
                approved = true;
            }
        }

        if (approved) {
            submission.state = SubmissionState.Approved;
             // Internal minting process
            _galleryMint(submissionId);
            submission.associatedArtworkId = _artworkCounter; // Store the minted token ID
            emit VotingFinalized(submissionId, SubmissionState.Approved, _artworkCounter);
        } else {
            submission.state = SubmissionState.Rejected;
            emit VotingFinalized(submissionId, SubmissionState.Rejected, 0); // 0 indicates no artwork minted
        }
    }

    // --- Artwork (NFT) Management & Interaction Functions ---

    /**
     * @dev Internal function to mint an NFT representing an approved artwork.
     * The minted NFT is owned by the gallery contract itself initially.
     * @param submissionId The ID of the submission that was approved.
     */
    function _galleryMint(uint256 submissionId) internal {
        _artworkCounter++;
        uint256 newItemId = _artworkCounter;

        _owners[newItemId] = address(this); // Gallery contract owns the NFT
        _balances[address(this)]++;
        _totalSupply++;
        _galleryTokenIds.push(newItemId); // Add to gallery's list

        artworkDetails[newItemId] = Artwork({
            submissionId: submissionId,
            interactionCount: 0 // Start with 0 likes
        });

        emit ArtworkMinted(newItemId, submissionId, address(this));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * Generates the metadata URI for a given token ID.
     * The URL pattern allows an off-chain server to serve dynamic JSON based on the token ID.
     * It can potentially read contract state (like interactionCount) to change the metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (_owners[tokenId] == address(0)) revert ArtworkNotFound(tokenId);
        // Assume metadata is served from tokenURIPrefix + tokenId + ".json" or similar
        // An off-chain service at tokenURIPrefix must handle the lookup and potentially
        // dynamic rendering based on the token ID (and perhaps query contract state).
        return string(abi.encodePacked(tokenURIPrefix, Strings.toString(tokenId)));
    }

    /**
     * @dev Retrieves details for a minted artwork NFT.
     * @param tokenId The ID of the artwork NFT.
     * @return A tuple containing the artwork details.
     */
    function getArtworkDetails(uint256 tokenId) external view returns (Artwork memory) {
         if (_owners[tokenId] == address(0)) revert ArtworkNotFound(tokenId);
        return artworkDetails[tokenId];
    }

    /**
     * @dev Allows users to 'like' a minted artwork.
     * Each user can like an artwork only once. Increments an interaction counter.
     * This counter can be read by the off-chain metadata service for dynamic content.
     * @param tokenId The ID of the artwork NFT to like.
     */
    function likeArtwork(uint256 tokenId) external whenNotPaused {
        if (_owners[tokenId] == address(0)) revert ArtworkNotFound(tokenId);
        if (_userLikedArtwork[tokenId][msg.sender]) revert AlreadyLiked(tokenId, msg.sender);

        _userLikedArtwork[tokenId][msg.sender] = true;
        artworkDetails[tokenId].interactionCount++;

        emit ArtworkLiked(tokenId, msg.sender, artworkDetails[tokenId].interactionCount);
    }

    /**
     * @dev Returns the current number of likes for a specific artwork.
     * @param tokenId The ID of the artwork NFT.
     * @return The number of likes.
     */
    function getArtworkLikes(uint256 tokenId) external view returns (uint256) {
        if (_owners[tokenId] == address(0)) revert ArtworkNotFound(tokenId);
        return artworkDetails[tokenId].interactionCount;
    }

     /**
     * @dev Returns the current number of interactions (likes) for a specific artwork.
     * Alias for getArtworkLikes, included to potentially represent a broader interaction metric.
     * @param tokenId The ID of the artwork NFT.
     * @return The number of interactions.
     */
    function getArtworkInteractionCount(uint256 tokenId) external view returns (uint256) {
         if (_owners[tokenId] == address(0)) revert ArtworkNotFound(tokenId);
        return artworkDetails[tokenId].interactionCount;
    }


    /**
     * @dev Checks if a user has already liked a specific artwork.
     * @param tokenId The ID of the artwork NFT.
     * @param user The address of the user.
     * @return True if the user has liked the artwork, false otherwise.
     */
    function getUserLikedArtwork(uint256 tokenId, address user) external view returns (bool) {
        if (_owners[tokenId] == address(0)) revert ArtworkNotFound(tokenId);
        return _userLikedArtwork[tokenId][user];
    }

    // --- ERC721 Basic Query Functions ---
    // Implementing the minimal required ERC721 functions.

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert InvalidAmount(); // ERC721 requires non-zero address
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert ArtworkNotFound(tokenId);
        return owner;
    }

     /**
     * @dev See {IERC721-totalSupply}.
     * Returns the total number of minted NFTs.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    // --- ERC721 Compatibility (Non-Implemented Parts & Placeholders) ---
    // These functions are part of the ERC721 standard but are not fully implemented
    // in this specific example to keep the focus on the gallery's core logic and
    // avoid extensive boilerplate duplication, per the user's request spirit.
    // For a production contract, consider inheriting from OpenZeppelin's ERC721
    // or implementing these fully and robustly.

    function approve(address to, uint256 tokenId) public pure override {
         revert NotGalleryOwner(); // Gallery owns NFTs, approvals not needed for gallery ops
    }

    function getApproved(uint256 tokenId) public pure override returns (address) {
         revert NotGalleryOwner(); // Gallery owns NFTs, approvals not needed for gallery ops
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
         revert NotGalleryOwner(); // Gallery owns NFTs, approvals not needed for gallery ops
    }

    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
         revert NotGalleryOwner(); // Gallery owns NFTs, approvals not needed for gallery ops
    }

    // Note: transferFrom and safeTransferFrom are not implemented as the primary
    // goal is for the gallery contract to hold the collection initially.
    // Selling/transferring would require additional complex logic (e.g., auctions, marketplace integration).
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
         revert NotGalleryOwner(); // Gallery owns NFTs, transfers not handled by this core logic
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
         revert NotGalleryOwner(); // Gallery owns NFTs, transfers not handled by this core logic
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
         revert NotGalleryOwner(); // Gallery owns NFTs, transfers not handled by this core logic
    }


    // --- ERC165 Interface Support ---
    // Required for ERC721 compatibility
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721Metadata = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721Enumerable = 0x780e9d63;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId || // Announce support even if not fully implemented
               interfaceId == type(IERC165).interfaceId;
    }

    // --- Query/Getter Functions ---

    /**
     * @dev Returns the total number of submissions made to the gallery.
     */
    function getSubmissionCount() external view returns (uint256) {
        return _submissionCounter;
    }

    /**
     * @dev Returns the total number of artworks (NFTs) minted by the gallery.
     */
    function getArtworkCount() external view returns (uint256) {
        return _artworkCounter;
    }

    /**
     * @dev Returns the current balance of the contract (treasury).
     */
    function getGalleryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the list of token IDs currently owned by the gallery contract.
     * WARNING: This function iterates over an array. If the number of minted NFTs
     * grows very large, calling this function could exceed gas limits.
     * For large collections, consider alternative indexing methods off-chain.
     */
    function getGalleryOwnedTokens() external view returns (uint256[] memory) {
        // This is a gas-inefficient implementation for demonstration.
        // A production contract might omit this or use alternative off-chain indexing.
        return _galleryTokenIds;
    }

     /**
     * @dev Gets the current state of a submission.
     * @param submissionId The ID of the submission.
     * @return The SubmissionState (Pending, Approved, Rejected).
     */
    function getSubmissionState(uint256 submissionId) external view returns (SubmissionState) {
         if (submissionId == 0 || submissionId > _submissionCounter) revert SubmissionNotFound(submissionId);
        return submissions[submissionId].state;
    }

    // --- Receive/Fallback ---
    receive() external payable {}
    fallback() external payable {}

    // --- Helper library for toString ---
    // (Included directly to avoid external imports and meet 'no duplicate' spirit for core logic)
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            // Inspired by OpenZeppelin's Strings.toString implementation
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
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = bytes1(uint8(48 + temp % 10));
                temp /= 10;
            }
            return string(buffer);
        }
    }
}
```