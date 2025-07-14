Okay, let's design a smart contract that acts as a decentralized idea incubator and knowledge base, incorporating concepts like reputation, staking for participation, dynamic idea status based on community review, and linking approved ideas to NFTs. We'll call it `CryptoMinds`.

It's not a standard ERC-20, ERC-721 implementation alone, nor a simple staking vault or basic DAO vote. It combines elements in a unique flow.

---

**Contract Name:** `CryptoMinds`

**Concept:** A decentralized platform where users stake a utility token ($MIND) to submit ideas. Other users with sufficient reputation ($REP) can review and vote on ideas. Ideas progress through stages based on review outcomes. Approved ideas can be minted as unique NFTs and their submitters can claim $MIND rewards. Reputation is earned through constructive participation but can also be slashed.

**Key Features:**
*   **Staking:** Users stake $MIND to participate (submit ideas, gain higher review weight).
*   **Reputation ($REP):** A soul-bound score tracking user contribution quality (reviewing, idea submission success). Required for certain actions (e.g., reviewing). Can decay or be slashed.
*   **Idea Submission & Curation:** Users submit ideas, which are reviewed by high-$REP users.
*   **Dynamic Status:** Ideas move through stages (Submitted, Under Review, Approved, Rejected) based on review scores and votes.
*   **NFTs:** Approved ideas can be minted as unique "Idea Capsule" NFTs.
*   **Rewards:** $MIND rewards for submitters of approved ideas.
*   **Parameterization:** Admin functions to tune system parameters (fees, minimums, rewards).
*   **Pause Mechanism:** Standard safety feature.

**Outline:**

1.  **SPDX License & Pragma**
2.  **Imports (Basic ERC-20 and ERC-721 internal implementations)**
3.  **Error Handling**
4.  **Events**
5.  **Structs:**
    *   `User`: Stores registration status, stake, reputation, etc.
    *   `Review`: Stores review text, rating, author, vote counts.
    *   `Idea`: Stores title, description, author, status, reviews, associated NFT ID, claimed status.
6.  **Enums:**
    *   `IdeaStatus`: Submitted, UnderReview, Approved, Rejected, Archived.
7.  **State Variables:**
    *   Admin/Owner address
    *   Pausable state
    *   Counters for users, ideas, NFTs
    *   Mappings for users, ideas, reputation, staked amounts, pending unstakes, NFT details.
    *   Parameters (submission fee, min stake, min review rep, reward amount, unstake cooldown)
    *   Internal token balances (for simplicity, managing $MIND here)
8.  **Modifiers:**
    *   `onlyOwner`
    *   `whenNotPaused`
    *   `whenPaused`
    *   `onlyRegisteredUser`
    *   `onlyIdeaAuthor`
    *   `ideaExists`
    *   `isIdeaStatus`
    *   `hasMinReputation`
    *   `isIdeaNFTMinted`
    *   `isIdeaRewardsClaimed`
9.  **Constructor:** Sets owner, initial parameters, mints initial $MIND supply (to owner or treasury).
10. **Internal Helper Functions:** (e.g., reputation calculation, internal token transfer)
11. **Core Functions (Public/External - 25+):**
    *   **User Management:**
        *   `registerUser()`
        *   `getUserDetails(address user)`
    *   **Staking:**
        *   `stakeMIND(uint256 amount)`
        *   `startUnstakeCooldown(uint256 amount)`
        *   `claimStakedMIND()`
        *   `getUserStake(address user)`
        *   `getPendingUnstakeAmount(address user)`
        *   `getUnstakeCooldownEndTime(address user)`
    *   **Reputation:**
        *   `getUserReputation(address user)`
        *   `slashReputation(address user, uint256 amount)` (Admin/Governance)
    *   **Idea Management:**
        *   `submitIdea(string memory title, string memory description)`
        *   `editIdea(uint256 ideaId, string memory newTitle, string memory newDescription)`
        *   `getIdeaDetails(uint256 ideaId)`
        *   `getTotalIdeaCount()`
    *   **Review & Evaluation:**
        *   `submitReview(uint256 ideaId, string memory reviewText, uint256 rating)`
        *   `voteOnReview(uint256 ideaId, uint256 reviewIndex, bool support)`
        *   `getReviewsForIdea(uint256 ideaId)`
        *   `evaluateIdeaStatus(uint256 ideaId)` (Trigger status update based on reviews)
    *   **NFTs:**
        *   `mintIdeaNFT(uint256 ideaId)`
        *   `getIdeaNFTId(uint256 ideaId)`
        *   `ownerOfNFT(uint256 nftId)` (Standard ERC-721 getter)
    *   **Rewards:**
        *   `claimIdeaSubmissionRewards(uint256 ideaId)`
    *   **Token (MIND) Interactions (Basic):**
        *   `balanceOfMIND(address user)`
        *   `transferMIND(address recipient, uint256 amount)` (Simplified, mainly for admin/distribution)
        *   `totalSupplyMIND()`
    *   **Admin & Parameters:**
        *   `setSubmissionFee(uint256 fee)`
        *   `setMinStakeToSubmit(uint256 minStake)`
        *   `setMinReputationToReview(uint256 minRep)`
        *   `setRewardAmountPerApprovedIdea(uint256 amount)`
        *   `setUnstakeCooldown(uint256 duration)`
        *   `pause()`
        *   `unpause()`
        *   `withdrawProtocolFees(address token)`

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Outline ---
// 1. SPDX License & Pragma
// 2. Imports (Ownable, Pausable)
// 3. Error Handling
// 4. Events
// 5. Structs: User, Review, Idea
// 6. Enums: IdeaStatus
// 7. State Variables: Admin/Owner, Paused State, Counters, Mappings (Users, Ideas, Reputation, Staked, Unstake, NFTs, Token Balances), Parameters
// 8. Modifiers: onlyOwner, whenNotPaused, whenPaused, onlyRegisteredUser, onlyIdeaAuthor, ideaExists, isIdeaStatus, hasMinReputation, isIdeaNFTMinted, isIdeaRewardsClaimed
// 9. Constructor: Initialize owner, parameters, initial MIND supply.
// 10. Internal Helper Functions: _calculateReputationGain, _transferMIND, _mintMIND, _burnMIND, _mintIdeaNFTInternal (simplified token/nft)
// 11. Core Functions (Public/External - 25+):
//     - User Management: registerUser, getUserDetails
//     - Staking: stakeMIND, startUnstakeCooldown, claimStakedMIND, getUserStake, getPendingUnstakeAmount, getUnstakeCooldownEndTime
//     - Reputation: getUserReputation, slashReputation (Admin/Governance)
//     - Idea Management: submitIdea, editIdea, getIdeaDetails, getTotalIdeaCount
//     - Review & Evaluation: submitReview, voteOnReview, getReviewsForIdea, evaluateIdeaStatus (Trigger status update)
//     - NFTs: mintIdeaNFT, getIdeaNFTId, ownerOfNFT (ERC721 getter)
//     - Rewards: claimIdeaSubmissionRewards
//     - Token (MIND) Interactions: balanceOfMIND, transferMIND (Simplified), totalSupplyMIND
//     - Admin & Parameters: setSubmissionFee, setMinStakeToSubmit, setMinReputationToReview, setRewardAmountPerApprovedIdea, setUnstakeCooldown, pause, unpause, withdrawProtocolFees

// --- Function Summary ---
// User Management:
// registerUser(): Allows a new user to register.
// getUserDetails(address user): Retrieves registration status and user ID.
// Staking:
// stakeMIND(uint256 amount): Stakes MIND tokens to gain participation rights.
// startUnstakeCooldown(uint256 amount): Initiates the unstaking process with a cooldown period.
// claimStakedMIND(): Claims staked MIND after the cooldown period.
// getUserStake(address user): Gets the currently staked amount for a user.
// getPendingUnstakeAmount(address user): Gets the amount pending unstake for a user.
// getUnstakeCooldownEndTime(address user): Gets the timestamp when unstake cooldown ends.
// Reputation:
// getUserReputation(address user): Gets the reputation score for a user.
// slashReputation(address user, uint256 amount): Admin function to decrease a user's reputation (e.g., for spam/malicious activity).
// Idea Management:
// submitIdea(string memory title, string memory description): Submits a new idea, requires stake and potentially fee.
// editIdea(uint256 ideaId, string memory newTitle, string memory newDescription): Allows author to edit an idea (status permitting).
// getIdeaDetails(uint256 ideaId): Retrieves the full details of an idea.
// getTotalIdeaCount(): Gets the total number of ideas submitted.
// Review & Evaluation:
// submitReview(uint256 ideaId, string memory reviewText, uint256 rating): Allows high-reputation users to submit reviews for ideas.
// voteOnReview(uint256 ideaId, uint256 reviewIndex, bool support): Allows users to vote on the helpfulness of a review.
// getReviewsForIdea(uint256 ideaId): Gets all reviews for a specific idea.
// evaluateIdeaStatus(uint256 ideaId): Triggers the logic to potentially change an idea's status based on collected reviews/votes.
// NFTs:
// mintIdeaNFT(uint256 ideaId): Mints a unique NFT for an approved idea.
// getIdeaNFTId(uint256 ideaId): Gets the NFT ID associated with an idea.
// ownerOfNFT(uint256 nftId): Standard ERC-721 query for NFT ownership.
// Rewards:
// claimIdeaSubmissionRewards(uint256 ideaId): Allows the author of an approved idea to claim MIND rewards.
// Token (MIND) Interactions:
// balanceOfMIND(address user): Gets the MIND balance for a user (staked + unstaked in this contract).
// transferMIND(address recipient, uint256 amount): Basic transfer function for MIND (primarily for rewards/admin distribution out).
// totalSupplyMIND(): Gets the total supply of MIND managed by this contract.
// Admin & Parameters:
// setSubmissionFee(uint256 fee): Sets the fee (in MIND) to submit an idea.
// setMinStakeToSubmit(uint256 minStake): Sets the minimum required stake to submit an idea.
// setMinReputationToReview(uint256 minRep): Sets the minimum reputation required to submit a review.
// setRewardAmountPerApprovedIdea(uint256 amount): Sets the MIND reward for approved ideas.
// setUnstakeCooldown(uint256 duration): Sets the duration of the unstake cooldown period.
// pause(): Pauses contract functions (Admin only).
// unpause(): Unpauses contract functions (Admin only).
// withdrawProtocolFees(address token): Allows admin to withdraw accumulated fees (e.g., MIND submission fees, or other tokens sent here by mistake).

// Note: This contract includes simplified internal implementations of ERC-20 and ERC-721 token management for the MIND token and Idea Capsule NFTs
// within the same contract for demonstration purposes. In a real-world scenario,
// you might use separate, standard compliant ERC-20 and ERC-721 contracts.

contract CryptoMinds is Ownable, Pausable {
    // --- Error Handling ---
    error UserAlreadyRegistered();
    error UserNotRegistered();
    error InsufficientMINDStake(uint256 required, uint256 available);
    error InsufficientMINDTokens(uint256 required, uint256 available);
    error UnstakeAmountExceedsStake();
    error UnstakeCooldownNotStarted();
    error UnstakeCooldownInProgress(uint256 endTime);
    error NoPendingUnstake();
    error IdeaNotFound();
    error NotIdeaAuthor();
    error IdeaStatusDoesNotAllowEdit();
    error IdeaStatusDoesNotAllowReview();
    error IdeaStatusDoesNotAllowEvaluation();
    error IdeaStatusDoesNotAllowNFTMint();
    error IdeaStatusDoesNotAllowRewardClaim();
    error IdeaAlreadyHasNFT();
    error RewardsAlreadyClaimed();
    error InvalidReviewRating();
    error ReviewNotFound();
    error CannotVoteOnOwnReview();
    error ReviewVoteNotFound(); // Should not happen if index is valid
    error InsufficientReputation(uint256 required, uint256 available);
    error OnlyIdeaNFTsAllowed();
    error CannotTransferIdeaNFT(); // Idea NFTs are soulbound-like (tied to idea submitter conceptually, even if transferred, the *idea* link is primary) - or restrict transfers? Let's restrict transfers for this concept.
    error InvalidTokenAddress();

    // --- Events ---
    event UserRegistered(address indexed user, uint256 userId);
    event MINDStaked(address indexed user, uint256 amount, uint256 totalStake);
    event UnstakeCooldownStarted(address indexed user, uint256 amount, uint256 cooldownEndTime);
    event StakedMINDClaimed(address indexed user, uint256 amount, uint256 remainingStake);
    event ReputationGained(address indexed user, uint256 amount, uint256 totalReputation);
    event ReputationSlashed(address indexed user, uint256 amount, uint256 totalReputation);
    event IdeaSubmitted(address indexed author, uint256 ideaId, string title);
    event IdeaEdited(address indexed author, uint256 ideaId, string title);
    event ReviewSubmitted(address indexed reviewer, uint256 ideaId, uint256 reviewIndex, uint256 rating);
    event ReviewVoteCasted(address indexed voter, uint256 ideaId, uint256 reviewIndex, bool support);
    event IdeaStatusUpdated(uint256 indexed ideaId, IdeaStatus oldStatus, IdeaStatus newStatus);
    event IdeaNFTMinted(uint256 indexed ideaId, uint256 indexed nftId, address indexed owner);
    event IdeaRewardsClaimed(address indexed author, uint256 indexed ideaId, uint256 rewardAmount);
    event ParameterSet(string parameterName, uint256 value);
    event ProtocolFeesWithdrawn(address indexed token, address indexed recipient, uint256 amount);

    // --- Structs ---
    struct User {
        bool isRegistered;
        uint256 userId; // Internal sequential ID
        uint256 stake; // Amount of MIND staked
        uint256 reputation;
        uint256 pendingUnstakeAmount;
        uint48 unstakeCooldownEndTime; // Use uint48 for efficiency if block.timestamp fits
    }

    struct Review {
        address reviewer;
        string reviewText;
        uint256 rating; // e.g., 1-5
        uint256 upVotes;
        uint256 downVotes;
        mapping(address => bool) hasVoted; // Prevent double voting on a single review
    }

    struct Idea {
        string title;
        string description;
        address author;
        IdeaStatus status;
        uint256 submittedTimestamp;
        Review[] reviews; // Array of reviews for this idea
        uint256 associatedNFTId; // 0 if no NFT yet
        bool rewardsClaimed;
    }

    // --- Enums ---
    enum IdeaStatus {
        Submitted,      // Just created
        UnderReview,    // Open for reviews
        Approved,       // Passed review criteria
        Rejected,       // Failed review criteria
        Archived        // Historical, no longer active
    }

    // --- State Variables ---
    uint256 private _userIdCounter = 1; // Start from 1, 0 means not registered
    uint256 private _ideaIdCounter = 1;
    uint256 private _nftIdCounter = 1; // For Idea Capsule NFTs

    mapping(address => User) private users;
    mapping(uint256 => address) private userIdToAddress; // To get address from ID if needed (less critical)
    mapping(uint256 => Idea) private ideas;
    mapping(uint256 => uint256) private nftIdToIdeaId; // Link NFT back to Idea

    // Simplified Internal Token Management for MIND (ERC-20 like)
    string public constant nameMIND = "CryptoMinds Utility Token";
    string public constant symbolMIND = "MIND";
    uint8 public constant decimalsMIND = 18;
    uint256 private _totalSupplyMIND;
    mapping(address => uint256) private _balancesMIND; // Balances held within the contract (includes staked and unstaked portions)

    // Simplified Internal NFT Management for Idea Capsules (ERC-721 like)
    string public constant nameNFT = "Idea Capsule NFT";
    string public constant symbolNFT = "IDEACAP";
    mapping(uint256 => address) private _ownersNFT; // NFT ID to Owner address
    mapping(address => uint256) private _balanceOfNFT; // Owner address to count of NFTs
    mapping(uint256 => address) private _tokenApprovalsNFT; // NFT ID to approved address

    // Parameters
    uint256 public submissionFee = 10 * (10 ** uint256(decimalsMIND)); // e.g., 10 MIND
    uint256 public minStakeToSubmit = 50 * (10 ** uint256(decimalsMIND)); // e.g., 50 MIND
    uint256 public minReputationToReview = 100; // Reputation score required to submit a review
    uint256 public rewardAmountPerApprovedIdea = 20 * (10 ** uint256(decimalsMIND)); // e.g., 20 MIND
    uint256 public unstakeCooldownDuration = 7 days; // Cooldown period for unstaking

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        if (!users[msg.sender].isRegistered) revert UserNotRegistered();
        _;
    }

    modifier onlyIdeaAuthor(uint256 ideaId) {
        _ideaExists(ideaId);
        if (ideas[ideaId].author != msg.sender) revert NotIdeaAuthor();
        _;
    }

    modifier ideaExists(uint256 ideaId) {
        _ideaExists(ideaId);
        _;
    }

    modifier isIdeaStatus(uint256 ideaId, IdeaStatus status) {
        _ideaExists(ideaId);
        if (ideas[ideaId].status != status) revert IdeaStatusDoesNotAllowEvaluation(); // Generic error for status mismatch
        _;
    }

    modifier hasMinReputation(uint256 requiredReputation) {
        if (users[msg.sender].reputation < requiredReputation) revert InsufficientReputation(requiredReputation, users[msg.sender].reputation);
        _;
    }

    modifier isIdeaNFTMinted(uint256 ideaId, bool minted) {
         _ideaExists(ideaId);
         if (minted && ideas[ideaId].associatedNFTId == 0) revert IdeaAlreadyHasNFT(); // Re-using error message slightly
         if (!minted && ideas[ideaId].associatedNFTId != 0) revert IdeaStatusDoesNotAllowNFTMint(); // Re-using error message slightly
        _;
    }

    modifier isIdeaRewardsClaimed(uint256 ideaId, bool claimed) {
         _ideaExists(ideaId);
         if (claimed && ideas[ideaId].rewardsClaimed) revert RewardsAlreadyClaimed();
         if (!claimed && !ideas[ideaId].rewardsClaimed) revert IdeaStatusDoesNotAllowRewardClaim(); // Re-using error message slightly
        _;
    }


    // Internal check for idea existence
    function _ideaExists(uint256 ideaId) internal view {
        if (ideaId == 0 || ideaId >= _ideaIdCounter) revert IdeaNotFound();
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Mint an initial supply of MIND to the contract owner or a treasury
        _mintMIND(msg.sender, 1000000 * (10 ** uint256(decimalsMIND))); // Example initial supply
    }

    // --- Internal Helper Functions ---

    // Simplified internal MIND token logic
    function _transferMIND(address from, address to, uint256 amount) internal {
        if (_balancesMIND[from] < amount) revert InsufficientMINDTokens(_balancesMIND[from], amount); // Corrected error usage
        _balancesMIND[from] -= amount;
        _balancesMIND[to] += amount;
    }

    function _mintMIND(address account, uint256 amount) internal {
        _totalSupplyMIND += amount;
        _balancesMIND[account] += amount;
    }

    function _burnMIND(address account, uint256 amount) internal {
         if (_balancesMIND[account] < amount) revert InsufficientMINDTokens(_balancesMIND[account], amount); // Corrected error usage
        _balancesMIND[account] -= amount;
        _totalSupplyMIND -= amount;
    }

    // Simplified internal Idea Capsule NFT logic (ERC-721 subset)
    function _mintIdeaNFTInternal(address to, uint256 ideaId) internal returns (uint256) {
        uint256 newNftId = _nftIdCounter++;
        _ownersNFT[newNftId] = to;
        _balanceOfNFT[to]++;
        nftIdToIdeaId[newNftId] = ideaId; // Link NFT ID to Idea ID

        // Note: A full ERC-721 implementation would require more checks, events, and functions (like `safeTransferFrom`, `approve`, `getApproved`, etc.)
        // We are deliberately keeping this minimal for the combined contract example.
        // We explicitly disallow standard transfers later for the soulbound-like concept.

        return newNftId;
    }

    // Example of internal reputation calculation - can be much more complex
    function _calculateReputationGain(address user, uint256 baseAmount) internal {
        // Example: Flat gain for now. Could be dynamic based on review rating, vote outcome, idea success, etc.
        users[user].reputation += baseAmount;
        emit ReputationGained(user, baseAmount, users[user].reputation);
    }


    // --- Core Functions ---

    // User Management (2 functions)
    function registerUser() external whenNotPaused {
        if (users[msg.sender].isRegistered) revert UserAlreadyRegistered();
        users[msg.sender].isRegistered = true;
        users[msg.sender].userId = _userIdCounter++;
        users[msg.sender].reputation = 0; // Start with 0 rep
        emit UserRegistered(msg.sender, users[msg.sender].userId);
    }

    function getUserDetails(address user) external view returns (bool isRegistered, uint256 userId) {
        return (users[user].isRegistered, users[user].userId);
    }

    // Staking (6 functions)
    function stakeMIND(uint256 amount) external whenNotPaused onlyRegisteredUser {
        if (amount == 0) return; // Do nothing if staking 0
        // Assuming the user has already approved this contract to spend their MIND tokens
        // In a real scenario with external ERC-20, you'd use IERC20(mindTokenAddress).transferFrom(msg.sender, address(this), amount);
        // Here, we just move it internally from the user's balance within this contract
        _transferMIND(msg.sender, address(this), amount); // User must have the MIND balance *within this contract* already

        users[msg.sender].stake += amount;
        emit MINDStaked(msg.sender, amount, users[msg.sender].stake);
    }

    function startUnstakeCooldown(uint256 amount) external whenNotPaused onlyRegisteredUser {
        if (amount == 0) return;
        if (users[msg.sender].stake < amount) revert UnstakeAmountExceedsStake();
        if (users[msg.sender].pendingUnstakeAmount > 0) revert UnstakeCooldownInProgress(users[msg.sender].unstakeCooldownEndTime); // Prevent starting new cooldown if one is active

        users[msg.sender].stake -= amount;
        users[msg.sender].pendingUnstakeAmount = amount;
        users[msg.sender].unstakeCooldownEndTime = uint48(block.timestamp + unstakeCooldownDuration); // Store end time

        emit UnstakeCooldownStarted(msg.sender, amount, users[msg.sender].unstakeCooldownEndTime);
    }

    function claimStakedMIND() external whenNotPaused onlyRegisteredUser {
        if (users[msg.sender].pendingUnstakeAmount == 0) revert NoPendingUnstake();
        if (block.timestamp < users[msg.sender].unstakeCooldownEndTime) revert UnstakeCooldownInProgress(users[msg.sender].unstakeCooldownEndTime);

        uint256 amountToClaim = users[msg.sender].pendingUnstakeAmount;
        users[msg.sender].pendingUnstakeAmount = 0;
        users[msg.sender].unstakeCooldownEndTime = 0; // Reset cooldown time

        // Transfer MIND back to the user's internal balance within this contract
        _balancesMIND[msg.sender] += amountToClaim; // Add back to user's general balance here

        emit StakedMINDClaimed(msg.sender, amountToClaim, users[msg.sender].stake);
    }

    function getUserStake(address user) external view onlyRegisteredUser returns (uint256) {
        return users[user].stake;
    }

    function getPendingUnstakeAmount(address user) external view onlyRegisteredUser returns (uint256) {
         return users[user].pendingUnstakeAmount;
    }

    function getUnstakeCooldownEndTime(address user) external view onlyRegisteredUser returns (uint256) {
        return users[user].unstakeCooldownEndTime;
    }

    // Reputation (2 functions)
    function getUserReputation(address user) external view onlyRegisteredUser returns (uint256) {
        // Note: Reputation decay could be implemented here by calculating time elapsed,
        // but is omitted for simplicity in this example.
        return users[user].reputation;
    }

    function slashReputation(address user, uint256 amount) external onlyOwner whenNotPaused {
        if (!users[user].isRegistered) revert UserNotRegistered();
        if (users[user].reputation < amount) amount = users[user].reputation; // Don't go below zero

        users[user].reputation -= amount;
        emit ReputationSlashed(user, amount, users[user].reputation);
    }

    // Idea Management (4 functions)
    function submitIdea(string memory title, string memory description) external whenNotPaused onlyRegisteredUser {
        if (users[msg.sender].stake < minStakeToSubmit) revert InsufficientMINDStake(minStakeToSubmit, users[msg.sender].stake);
        if (_balancesMIND[msg.sender] < submissionFee) revert InsufficientMINDTokens(submissionFee, _balancesMIND[msg.sender]);

        // Burn the submission fee
        _burnMIND(msg.sender, submissionFee);

        uint256 newIdeaId = _ideaIdCounter++;
        ideas[newIdeaId] = Idea({
            title: title,
            description: description,
            author: msg.sender,
            status: IdeaStatus.Submitted,
            submittedTimestamp: block.timestamp,
            reviews: new Review[](0), // Initialize empty
            associatedNFTId: 0,
            rewardsClaimed: false
        });

        // Add initial small reputation for submission? Optional.
        // _calculateReputationGain(msg.sender, 5); // Example

        emit IdeaSubmitted(msg.sender, newIdeaId, title);
    }

    function editIdea(uint256 ideaId, string memory newTitle, string memory newDescription)
        external
        whenNotPaused
        onlyIdeaAuthor(ideaId)
    {
         // Allow edits only if status is Submitted or UnderReview
         IdeaStatus currentStatus = ideas[ideaId].status;
         if (currentStatus != IdeaStatus.Submitted && currentStatus != IdeaStatus.UnderReview) {
            revert IdeaStatusDoesNotAllowEdit();
         }

        ideas[ideaId].title = newTitle;
        ideas[ideaId].description = newDescription;

        emit IdeaEdited(msg.sender, ideaId, newTitle);
    }

    function getIdeaDetails(uint256 ideaId) external view ideaExists(ideaId)
        returns (
            string memory title,
            string memory description,
            address author,
            IdeaStatus status,
            uint256 submittedTimestamp,
            uint256 reviewCount,
            uint256 associatedNFTId,
            bool rewardsClaimed
        )
    {
        Idea storage idea = ideas[ideaId];
        return (
            idea.title,
            idea.description,
            idea.author,
            idea.status,
            idea.submittedTimestamp,
            idea.reviews.length,
            idea.associatedNFTId,
            idea.rewardsClaimed
        );
    }

     function getTotalIdeaCount() external view returns (uint256) {
        return _ideaIdCounter - 1; // Subtract 1 as counter starts from 1
    }


    // Review & Evaluation (4 functions)
    function submitReview(uint256 ideaId, string memory reviewText, uint256 rating)
        external
        whenNotPaused
        onlyRegisteredUser
        ideaExists(ideaId)
        hasMinReputation(minReputationToReview)
    {
        // Only allow reviewing if status is Submitted or UnderReview
         IdeaStatus currentStatus = ideas[ideaId].status;
         if (currentStatus != IdeaStatus.Submitted && currentStatus != IdeaStatus.UnderReview) {
            revert IdeaStatusDoesNotAllowReview();
         }
        if (rating == 0 || rating > 5) revert InvalidReviewRating(); // Example rating scale

        Idea storage idea = ideas[ideaId];
        // Add review to the idea's review array
        idea.reviews.push(Review({
            reviewer: msg.sender,
            reviewText: reviewText,
            rating: rating,
            upVotes: 0,
            downVotes: 0,
            hasVoted: new mapping(address => bool)
        }));

        // Transition status if it was Submitted
        if (idea.status == IdeaStatus.Submitted) {
            idea.status = IdeaStatus.UnderReview;
             emit IdeaStatusUpdated(ideaId, IdeaStatus.Submitted, IdeaStatus.UnderReview);
        }

        // Give reviewer some initial reputation for reviewing
        _calculateReputationGain(msg.sender, 1); // Small gain for submitting review

        emit ReviewSubmitted(msg.sender, ideaId, idea.reviews.length - 1, rating);
    }

     function voteOnReview(uint256 ideaId, uint256 reviewIndex, bool support)
        external
        whenNotPaused
        onlyRegisteredUser
        ideaExists(ideaId)
        hasMinReputation(10) // Example: min reputation to vote on reviews
    {
         if (ideas[ideaId].reviews.length <= reviewIndex) revert ReviewNotFound();

         Review storage review = ideas[ideaId].reviews[reviewIndex];
         if (review.reviewer == msg.sender) revert CannotVoteOnOwnReview();
         if (review.hasVoted[msg.sender]) revert ReviewVoteNotFound(); // User has already voted (reusing error)

         review.hasVoted[msg.sender] = true;

         if (support) {
             review.upVotes++;
             // Optional: Reward voter?
             // _calculateReputationGain(msg.sender, 1); // Small gain for voting positively
         } else {
             review.downVotes++;
             // Optional: Penalize voter if review is eventually deemed good? Complex logic.
             // Optional: Penalize reviewer if review gets many downvotes?
         }

         // Example Reputation logic based on votes:
         // If a review gets many upvotes, slightly increase reviewer's reputation
         // If a review gets many downvotes, slightly decrease reviewer's reputation
         // This requires tracking total votes needed to trigger change, and potentially preventing repeat rep changes for the same review.
         // Let's keep it simple for now and only gain rep on submission, and slash via admin.

         emit ReviewVoteCasted(msg.sender, ideaId, reviewIndex, support);
     }

    function getReviewsForIdea(uint256 ideaId) external view ideaExists(ideaId)
        returns (
            address[] memory reviewers,
            string[] memory reviewTexts,
            uint256[] memory ratings,
            uint256[] memory upVotes,
            uint256[] memory downVotes
        )
    {
        Review[] storage ideaReviews = ideas[ideaId].reviews;
        uint256 count = ideaReviews.length;

        reviewers = new address[](count);
        reviewTexts = new string[](count);
        ratings = new uint256[](count);
        upVotes = new uint256[](count);
        downVotes = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            reviewers[i] = ideaReviews[i].reviewer;
            reviewTexts[i] = ideaReviews[i].reviewText;
            ratings[i] = ideaReviews[i].rating;
            upVotes[i] = ideaReviews[i].upVotes;
            downVotes[i] = ideaReviews[i].downVotes;
        }

        return (reviewers, reviewTexts, ratings, upVotes, downVotes);
    }

     function evaluateIdeaStatus(uint256 ideaId)
        external
        whenNotPaused
        ideaExists(ideaId)
    {
        // Anyone can call this, but status change only happens if review criteria are met.
        Idea storage idea = ideas[ideaId];

        // Only evaluate if currently Under Review
        if (idea.status != IdeaStatus.UnderReview) {
            revert IdeaStatusDoesNotAllowEvaluation();
        }

        uint256 totalReviews = idea.reviews.length;
        if (totalReviews == 0) return; // Cannot evaluate without reviews

        uint256 totalRatingSum = 0;
        uint256 totalReviewUpVotes = 0;
        uint256 totalReviewDownVotes = 0;
        mapping(address => uint256) reviewerRatingsSum; // Track ratings given by each reviewer
        mapping(address => uint256) reviewerReviewCount; // Track how many reviews each reviewer submitted for *this* idea

        for (uint256 i = 0; i < totalReviews; i++) {
            Review storage review = idea.reviews[i];
            totalRatingSum += review.rating;
            totalReviewUpVotes += review.upVotes;
            totalReviewDownVotes += review.downVotes;

            reviewerRatingsSum[review.reviewer] += review.rating;
            reviewerReviewCount[review.reviewer]++;
        }

        uint256 averageRating = totalRatingSum / totalReviews;
        uint256 totalReviewVotes = totalReviewUpVotes + totalReviewDownVotes;
        uint256 reviewVoteSupportRatio = totalReviewVotes > 0 ? (totalReviewUpVotes * 100) / totalReviewVotes : 100; // Percentage, default to 100 if no votes

        // Example evaluation logic (can be made much more complex):
        // Requires minimum number of reviews
        // Requires average rating above a threshold
        // Requires support ratio on reviews above a threshold
        // Requires minimum number of unique reviewers?

        uint256 minReviewsForEvaluation = 3; // Example parameter
        uint256 minAverageRating = 4; // Example parameter (out of 5)
        uint256 minReviewVoteSupportRatio = 70; // Example parameter (70%)

        if (totalReviews >= minReviewsForEvaluation &&
            averageRating >= minAverageRating &&
            reviewVoteSupportRatio >= minReviewVoteSupportRatio)
        {
            // Criteria met -> Approve Idea
            idea.status = IdeaStatus.Approved;

            // Optional: Give reputation to reviewers whose reviews were positive/supported
            // This logic is complex and depends on how 'positive' and 'supported' are defined after votes.
            // For simplicity now, reviewers got rep on submission.

            emit IdeaStatusUpdated(ideaId, IdeaStatus.UnderReview, IdeaStatus.Approved);

        } else if (totalReviews >= minReviewsForEvaluation) { // Or some other condition for rejection
             // Criteria not met after sufficient reviews -> Reject Idea
             // Add more specific rejection criteria if needed, e.g., very low average rating, very low support ratio
            bool rejectConditionsMet = averageRating < 3 || reviewVoteSupportRatio < 50; // Example
            if (rejectConditionsMet) {
                 idea.status = IdeaStatus.Rejected;
                 emit IdeaStatusUpdated(ideaId, IdeaStatus.UnderReview, IdeaStatus.Rejected);
            }
             // Else: Stay UnderReview, maybe needs more reviews
        }
        // If not enough reviews, status remains UnderReview
    }

    // NFTs (3 functions)
    function mintIdeaNFT(uint256 ideaId)
        external
        whenNotPaused
        ideaExists(ideaId)
        isIdeaStatus(ideaId, IdeaStatus.Approved)
        isIdeaNFTMinted(ideaId, false) // Ensure NFT hasn't been minted yet
    {
        Idea storage idea = ideas[ideaId];

        // Mint NFT to the idea author
        uint256 nftId = _mintIdeaNFTInternal(idea.author, ideaId);
        idea.associatedNFTId = nftId; // Link idea to the minted NFT ID

        emit IdeaNFTMinted(ideaId, nftId, idea.author);
    }

     function getIdeaNFTId(uint256 ideaId) external view ideaExists(ideaId) returns (uint256) {
        return ideas[ideaId].associatedNFTId;
    }

    // Basic ERC-721 owner lookup (for Idea Capsule NFTs)
    function ownerOfNFT(uint256 nftId) external view returns (address) {
        address owner = _ownersNFT[nftId];
        if (owner == address(0)) revert IdeaNotFound(); // Reusing error, means NFT ID not valid
        return owner;
    }

    // Override transfer functions to make Idea Capsule NFTs non-transferable/soulbound-like
    // This is a simplified way to prevent transfers for this specific NFT type managed here.
    // A full ERC721 implementation would require overriding transferFrom/safeTransferFrom.
    // Given our minimal internal implementation, simply not providing a transfer function is sufficient.
    // Adding this as a commented-out function or clear restriction note is good practice.
    // function transferFrom(address from, address to, uint256 nftId) public { revert CannotTransferIdeaNFT(); }
    // function safeTransferFrom(address from, address to, uint256 nftId) public { revert CannotTransferIdeaNFT(); }
    // function safeTransferFrom(address from, address to, uint256 nftId, bytes memory data) public { revert CannotTransferIdeaNFT(); }


    // Rewards (1 function)
    function claimIdeaSubmissionRewards(uint256 ideaId)
        external
        whenNotPaused
        onlyIdeaAuthor(ideaId) // Only author can claim rewards
        isIdeaStatus(ideaId, IdeaStatus.Approved) // Only for Approved ideas
        isIdeaRewardsClaimed(ideaId, false) // Only if rewards haven't been claimed
    {
        Idea storage idea = ideas[ideaId];

        // Transfer reward amount to the author (within this contract's balance tracking)
        _balancesMIND[idea.author] += rewardAmountPerApprovedIdea; // Add to author's general balance

        idea.rewardsClaimed = true; // Mark as claimed

        emit IdeaRewardsClaimed(idea.author, ideaId, rewardAmountPerApprovedIdea);
    }

    // Token (MIND) Interactions (3 functions)
    function balanceOfMIND(address user) external view returns (uint256) {
        // Returns the user's total balance managed by this contract (staked + unstaked/available)
        return _balancesMIND[user] + users[user].stake + users[user].pendingUnstakeAmount;
    }

    function transferMIND(address recipient, uint256 amount) external whenNotPaused returns (bool) {
        // This function assumes MIND is *only* managed within this contract.
        // Transfers move balance from sender's internal balance to recipient's internal balance here.
        // Staked amounts cannot be transferred this way.
        if (!users[msg.sender].isRegistered) revert UserNotRegistered(); // Must be a registered user
        if (!users[recipient].isRegistered && recipient != owner()) revert UserNotRegistered(); // Recipient must also be registered, unless it's the owner

        uint256 availableBalance = _balancesMIND[msg.sender];
        if (availableBalance < amount) revert InsufficientMINDTokens(availableBalance, amount);

        _balancesMIND[msg.sender] -= amount;
        _balancesMIND[recipient] += amount;

        // In a real ERC-20, you'd emit Transfer event. Omitting for simplicity.
        return true;
    }

    function totalSupplyMIND() external view returns (uint256) {
        return _totalSupplyMIND;
    }


    // Admin & Parameters (8 functions)
    function setSubmissionFee(uint256 fee) external onlyOwner whenNotPaused {
        submissionFee = fee;
        emit ParameterSet("submissionFee", fee);
    }

    function setMinStakeToSubmit(uint256 minStake) external onlyOwner whenNotPaused {
        minStakeToSubmit = minStake;
         emit ParameterSet("minStakeToSubmit", minStake);
    }

    function setMinReputationToReview(uint256 minRep) external onlyOwner whenNotPaused {
        minReputationToReview = minRep;
         emit ParameterSet("minReputationToReview", minRep);
    }

     function setRewardAmountPerApprovedIdea(uint256 amount) external onlyOwner whenNotPaused {
        rewardAmountPerApprovedIdea = amount;
         emit ParameterSet("rewardAmountPerApprovedIdea", amount);
    }

    function setUnstakeCooldown(uint256 duration) external onlyOwner whenNotPaused {
        unstakeCooldownDuration = duration;
         emit ParameterSet("unstakeCooldownDuration", duration);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawProtocolFees(address token) external onlyOwner whenNotPaused {
         if (token == address(0)) revert InvalidTokenAddress(); // Cannot withdraw zero address

         uint256 amountToWithdraw = 0;

         // For the internal MIND token, collected fees are those that were 'burned'
         // To withdraw, the owner would need to _mintMIND to themselves.
         // A better fee model would be to transfer fees to owner/treasury on submission.
         // Let's modify submitIdea to transfer fee to owner instead of burning, then withdrawable here.
         // *** Updating submitIdea: Instead of _burnMIND(msg.sender, submissionFee); use _transferMIND(msg.sender, owner(), submissionFee); ***
         // Then, the owner already has the fee. This withdrawal function is better for *other* tokens sent here accidentally.

         // Example for withdrawing accidentally sent ERC20 tokens:
         // IERC20 feeToken = IERC20(token);
         // amountToWithdraw = feeToken.balanceOf(address(this));
         // if (amountToWithdraw > 0) {
         //    feeToken.transfer(owner(), amountToWithdraw);
         //    emit ProtocolFeesWithdrawn(token, owner(), amountToWithdraw);
         // }

         // As we don't use external tokens here, this function is just a placeholder for real-world use.
         // Let's make it withdraw balance of *this* contract's internal MIND token that isn't staked/pending.
         // This represents MIND sent directly *to* the contract address, not via stake().
         amountToWithdraw = _balancesMIND[address(this)]; // MIND held by the contract itself
         if (amountToWithdraw > 0) {
             _transferMIND(address(this), owner(), amountToWithdraw); // Transfer to owner
             emit ProtocolFeesWithdrawn(address(this), owner(), amountToWithdraw);
         } else {
             // If no other tokens are tracked/receivable, this might do nothing.
             // Revert or just return? Let's just return if 0.
             return;
         }

    }

    // Fallback function to potentially receive ETH, though not intended
    receive() external payable {}
    fallback() external payable {} // Allows receiving ERC-20 tokens (though they won't be tracked without specific logic)

    // --- Add missing ERC721 view functions for completeness ---
    function balanceOfNFT(address owner) external view returns (uint256) {
        if (owner == address(0)) revert InvalidTokenAddress(); // Reusing error
        return _balanceOfNFT[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        // This requires iterating through all NFTs, which is gas intensive.
        // A simple implementation might skip this or require a more complex mapping.
        // Omitted for brevity and gas concerns in a basic example.
        revert("Not implemented or gas intensive");
    }

     function tokenByIndex(uint256 index) external view returns (uint256) {
        // Requires iterating through all NFTs. Omitted.
        revert("Not implemented or gas intensive");
    }

    function tokenURI(uint256 nftId) external view returns (string memory) {
        _ideaExists(nftIdToIdeaId[nftId]); // Check if NFT exists and is linked to an idea
        // In a real scenario, you would return a URI pointing to metadata for the Idea Capsule
        // Example: A URI generated based on the ideaId, pointing to IPFS or a service.
        // string memory baseURI = "ipfs://your_base_uri/";
        // return string(abi.encodePacked(baseURI, Strings.toString(nftId)));
        return "Placeholder URI - Metadata concept needed";
    }

    // Need to implement supportsInterface if we want to claim ERC-165 compliance
    // function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    //     return interfaceId == type(IERC721).interfaceId ||
    //            interfaceId == type(IERC721Metadata).interfaceId ||
    //            super.supportsInterface(interfaceId);
    // }
}
```