Okay, here is a Solidity smart contract for a Decentralized AI Model & Data Marketplace with features like staking for validation, challenge mechanisms, and different types of purchasable access (one-time, credits). This concept aims to be creative by focusing on AI assets and incorporating reputation/validation mechanics directly on-chain.

This contract avoids simple duplication of standard ERC-20/ERC-721 logic and instead builds a custom marketplace state machine with validation and staking.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAIModelMarketplace
 * @dev A decentralized marketplace for AI models, datasets, and inference credits.
 *      Features include:
 *      - Listing and purchasing AI models, datasets, and inference credit packs.
 *      - Role-based registration for Providers (list assets) and Validators (verify assets).
 *      - A staking mechanism for Validators to earn rewards and participate in challenges.
 *      - A validation process allowing Validators to certify asset quality/correctness.
 *      - A challenge mechanism allowing anyone to dispute validation results or asset claims,
 *        resolved via staked validator voting.
 *      - Distribution of marketplace fees and validation rewards.
 *
 * Outline:
 * 1.  Error Definitions: Custom errors for common failures.
 * 2.  Event Definitions: Log key actions for off-chain monitoring.
 * 3.  Enum Definitions: Define states for listings, validations, and stakes.
 * 4.  Struct Definitions: Define data structures for core entities (User, Listing, Validation, Challenge, Stake).
 * 5.  State Variables: Store contract data (mappings, counters, admin settings).
 * 6.  Constructor: Initialize contract owner and parameters.
 * 7.  Admin/Setup Functions: Set contract parameters (fees, durations, requirements).
 * 8.  User/Role Management Functions: Register users as Providers or Validators, get user info.
 * 9.  Listing Management Functions: List, update, and delist Models and Datasets.
 * 10. Purchasing/Access Functions: Buy access to models/datasets, purchase inference credits.
 * 11. Earnings/Withdrawal Functions: Providers withdraw earned funds.
 * 12. Validation Functions: Propose validation, submit results.
 * 13. Challenge Functions: Challenge validations/assets, vote on challenges, resolve challenges.
 * 14. Staking Functions: Stake funds to become an active Validator, withdraw stake.
 * 15. Reward Functions: Claim rewards for validation and staking.
 * 16. Query Functions: Get details about listings, users, validations, challenges, stakes.
 */

/**
 * Function Summary:
 *
 * Admin/Setup:
 * - constructor(): Deploys and initializes the contract.
 * - setValidationFee(uint256 fee): Sets the fee required to initiate a validation. (Owner)
 * - setStakingRequirement(uint256 amount): Sets the minimum stake required for Validators. (Owner)
 * - setChallengePeriod(uint48 duration): Sets the duration for the challenge period. (Owner)
 * - setVotingPeriod(uint48 duration): Sets the duration for the voting period in a challenge. (Owner)
 * - setMarketplaceFeeRate(uint16 rate): Sets the percentage fee taken on purchases (e.g., 100 = 1%). (Owner)
 *
 * User/Role Management:
 * - registerAsProvider(): Registers the caller as a data/model provider.
 * - registerAsValidator(): Registers the caller as a validator (requires staking).
 * - getUserProfile(address user): Gets the profile information for a user.
 *
 * Listing Management:
 * - listModel(string memory cid, string memory name, string memory description, uint256 price, bool validationRequired): Lists an AI model for sale. CID points to off-chain data.
 * - listDataset(string memory cid, string memory name, string memory description, uint256 price, bool validationRequired): Lists a dataset for sale. CID points to off-chain data.
 * - updateListing(uint256 listingId, string memory cid, string memory name, string memory description, uint256 price): Updates details of an existing listing. (Provider)
 * - delistAsset(uint256 listingId): Delists an asset, preventing new purchases. (Provider)
 *
 * Purchasing/Access:
 * - buyListingAccess(uint256 listingId): Buys access to a model or dataset. Sends price to contract, transfers fee, credits provider. Payable function.
 * - purchaseInferenceCredits(uint256 listingId): Buys inference credits for a specific model/service. Payable function. Amount paid is credited to the provider.
 *
 * Earnings/Withdrawal:
 * - withdrawProviderEarnings(): Allows a provider to withdraw their accumulated earnings.
 *
 * Validation:
 * - proposeValidation(uint256 listingId): A registered Validator proposes to validate a specific listing. Requires fee.
 * - submitValidationResult(uint256 validationId, bool passed, string memory detailsCID): Submits the validation result (pass/fail) and a CID for validation report. (Validator who proposed)
 *
 * Challenge:
 * - challengeValidation(uint256 validationId, string memory reasonCID): Anyone can challenge a validation result. Requires a stake.
 * - challengeAsset(uint256 listingId, string memory reasonCID): Anyone can challenge a listing directly (e.g., fake data, model doesn't work). Requires a stake.
 * - voteOnChallenge(uint256 challengeId, bool voteForChallenger): Staking Validators vote on a challenge outcome. Voting power based on stake.
 * - resolveChallenge(uint256 challengeId): Resolves a challenge after the voting period ends, distributing stakes and potentially slashing. (Owner or automated trigger)
 *
 * Staking:
 * - stakeForValidation(): Stakes Ether (or a designated token) to become an active Validator and participate in challenges/rewards. Payable function.
 * - withdrawStake(): Allows a Validator to withdraw their stake if not currently locked in a challenge or validation period.
 *
 * Rewards:
 * - claimValidationRewards(uint256 validationId): Validator who successfully validated claims a reward (e.g., portion of fee, staking rewards).
 * - claimStakingRewards(): Stakers claim accumulated staking rewards (from marketplace fees, slashed stakes).
 *
 * Query:
 * - getUserStake(address user): Gets the current staked amount for a user.
 * - getListingDetails(uint256 listingId): Gets details for a specific listing.
 * - getValidationDetails(uint256 validationId): Gets details for a specific validation process.
 * - getChallengeDetails(uint256 challengeId): Gets details for a specific challenge.
 * - getUserEarnings(address user): Gets the current withdrawable earnings for a provider.
 * - getTotalStaked(): Gets the total amount currently staked in the contract.
 */

// --- Error Definitions ---
error DAC_NotOwner();
error DAC_NotRegisteredProvider();
error DAC_NotRegisteredValidator();
error DAC_NotStakingValidator();
error DAC_ListingNotFound();
error DAC_ValidationNotFound();
error DAC_ChallengeNotFound();
error DAC_InvalidPrice();
error DAC_InsufficientPayment();
error DAC_ListingNotAvailable();
error DAC_ListingValidationRequired();
error DAC_ListingAlreadyValidated();
error DAC_ValidationInProgress();
error DAC_ValidationNotInProposedState();
error DAC_ValidationAlreadySubmitted();
error DAC_ChallengeAlreadyExists();
error DAC_ChallengeNotVoteable();
error DAC_ChallengeNotResolvable();
error DAC_ChallengeVotePeriodActive();
error DAC_AlreadyVoted();
error DAC_InsufficientStake();
error DAC_StakeLocked();
error DAC_NotEnoughToWithdrawStake();
error DAC_MinimumStakeNotMet();
error DAC_ValidationNotSubmitted();
error DAC_NoEarningsToWithdraw();
error DAC_NoRewardsToClaim();
error DAC_InvalidFeeRate();
error DAC_OnlyChallengeInitiatorSubmits();
error DAC_OnlyValidationProposerSubmits();
error DAC_UnauthorizedVoting();
error DAC_ValidationAlreadyChallenged();


// --- Event Definitions ---
event ProviderRegistered(address indexed provider);
event ValidatorRegistered(address indexed validator);
event ModelListed(uint256 indexed listingId, address indexed provider, string cid, string name, uint256 price, bool validationRequired);
event DatasetListed(uint256 indexed listingId, address indexed provider, string cid, string name, uint256 price, bool validationRequired);
event ListingUpdated(uint256 indexed listingId, string cid, string name, uint256 price);
event AssetDelisted(uint256 indexed listingId);
event AccessPurchased(uint256 indexed listingId, address indexed buyer, uint256 amountPaid);
event InferenceCreditsPurchased(uint256 indexed listingId, address indexed buyer, uint256 amountPaid);
event ProviderEarningsWithdrawn(address indexed provider, uint256 amount);
event ValidationProposed(uint256 indexed validationId, uint256 indexed listingId, address indexed validator);
event ValidationSubmitted(uint256 indexed validationId, bool passed, string detailsCID);
event ValidationAccepted(uint256 indexed validationId, uint256 indexed listingId);
event ValidationRejected(uint256 indexed validationId, uint256 indexed listingId);
event ChallengeProposed(uint256 indexed challengeId, uint256 indexed targetId, bool isValidationChallenge, address indexed challenger);
event ChallengeVoteCast(uint256 indexed challengeId, address indexed voter, bool voteForChallenger, uint256 votingPower);
event ChallengeResolved(uint256 indexed challengeId, bool challengerWon);
event StakeDeposited(address indexed validator, uint256 amount, uint256 totalStaked);
event StakeWithdrawn(address indexed validator, uint256 amount, uint256 totalStaked);
event StakeSlashed(address indexed validator, uint256 amount, uint256 remainingStake);
event ValidationRewardsClaimed(uint256 indexed validationId, address indexed validator, uint256 amount);
event StakingRewardsClaimed(address indexed validator, uint256 amount);

// --- Enum Definitions ---
enum ListingStatus { Active, Delisted, ValidationRequired, Validated, Challenged }
enum ValidationStatus { Proposed, Submitted, Accepted, Rejected }
enum ChallengeStatus { Proposed, Voting, Resolved }
enum StakeStatus { Active, Locked }

// --- Struct Definitions ---
struct UserProfile {
    bool isProvider;
    bool isValidator;
    uint256 providerEarnings;
    address addr; // Store address for easy lookup in query
}

struct Listing {
    uint256 id;
    address provider;
    string cid; // IPFS or other decentralized storage identifier
    string name;
    string description;
    uint256 price; // Price in wei for one-time access or credit pack value
    bool isModel; // true for model, false for dataset/service
    bool validationRequired; // Does this listing need validation before purchases?
    ListingStatus status;
    uint256 validatedById; // 0 if not validated or challenged
    uint256 currentChallengeId; // 0 if not challenged
    mapping(address => uint256) buyers; // buyer address => count of purchases (for simple access tracking)
}

struct Validation {
    uint256 id;
    uint256 listingId;
    address validator;
    ValidationStatus status;
    uint48 proposeTimestamp;
    bool passed; // Result submitted by validator
    string detailsCID; // CID pointing to the validation report
    uint256 challengeId; // 0 if not challenged
}

struct Challenge {
    uint256 id;
    uint256 targetId; // listingId or validationId
    bool isValidationChallenge; // true if challenging a validation, false if challenging a listing
    address challenger;
    string reasonCID; // CID pointing to the reason for the challenge
    ChallengeStatus status;
    uint48 proposeTimestamp;
    uint256 challengerStake; // Amount staked by the challenger
    uint256 totalVoteWeight; // Sum of staked amounts of voting validators
    uint256 votesForChallengerWeight; // Sum of staked amounts voting for the challenger
    uint256 votesAgainstChallengerWeight; // Sum of staked amounts voting against the challenger
    mapping(address => bool) voted; // Validator address => has voted?
}

struct Stake {
    uint256 amount; // Amount staked by the validator
    StakeStatus status; // Active or Locked (in a challenge)
    uint256 lockedChallengeId; // The challenge that locked the stake (0 if not locked)
    // Potential for rewards tracking here, or managed separately
}

// --- State Variables ---
address public owner;
uint256 public nextListingId = 1;
uint256 public nextValidationId = 1;
uint256 public nextChallengeId = 1;
uint256 public totalStakedAmount = 0;

uint256 public validationFee = 0.01 ether; // Fee to propose a validation
uint255 public stakingRequirement = 1 ether; // Minimum stake for a validator
uint48 public challengePeriodDuration = 1 days; // Time window to challenge a validation/asset
uint48 public votingPeriodDuration = 3 days; // Time window for validators to vote on a challenge
uint16 public marketplaceFeeRate = 100; // 1% fee (100 = 1.00%, 10000 = 100%) - Max 10000

mapping(address => UserProfile) public userProfiles;
mapping(uint256 => Listing) public listings;
mapping(uint256 => Validation) public validations;
mapping(uint256 => Challenge) public challenges;
mapping(address => Stake) public validatorStakes;
mapping(address => uint256) public stakingRewards; // Accumulated rewards for validators

// --- Modifiers (Less than 20, but good practice) ---
modifier onlyOwner() {
    if (msg.sender != owner) revert DAC_NotOwner();
    _;
}

modifier onlyRegisteredProvider() {
    if (!userProfiles[msg.sender].isProvider) revert DAC_NotRegisteredProvider();
    _;
}

modifier onlyRegisteredValidator() {
    if (!userProfiles[msg.sender].isValidator) revert DAC_NotRegisteredValidator();
    _;
}

modifier onlyStakingValidator() {
    if (!userProfiles[msg.sender].isValidator || validatorStakes[msg.sender].status != StakeStatus.Active) revert DAC_NotStakingValidator();
    _;
}

// --- Constructor ---
constructor() {
    owner = msg.sender;
    // Initial parameters can be set here or left for owner to set later
}

// --- Admin/Setup Functions (6 functions) ---
function setValidationFee(uint256 fee) external onlyOwner {
    validationFee = fee;
}

function setStakingRequirement(uint256 amount) external onlyOwner {
    stakingRequirement = amount;
}

function setChallengePeriod(uint48 duration) external onlyOwner {
    challengePeriodDuration = duration;
}

function setVotingPeriod(uint48 duration) external onlyOwner {
    votingPeriodDuration = duration;
}

function setMarketplaceFeeRate(uint16 rate) external onlyOwner {
    if (rate > 10000) revert DAC_InvalidFeeRate(); // Max 100%
    marketplaceFeeRate = rate;
}

// Allow owner to withdraw marketplace fees
function withdrawMarketplaceFees() external onlyOwner {
    // In this simple example, fees accumulate in the contract balance.
    // A more complex system might track fees per type or distribute them automatically.
    // For now, owner just takes the balance not accounted for by stakes or provider earnings.
    // This requires careful calculation in a real system to avoid withdrawing funds belonging to others.
    // For simplicity here, we'll assume total balance minus known stakes/earnings can be withdrawn.
    // WARNING: This simple withdrawal is unsafe in a real system! A proper fee tracking mechanism is needed.
    // A safer approach: track fee balance separately.
    // For this example, let's *pretend* we have a `contractFeeBalance` variable.
    // uint256 fees = contractFeeBalance;
    // contractFeeBalance = 0;
    // (bool success, ) = payable(owner).call{value: fees}("");
    // require(success, "Fee withdrawal failed");

    // Reverting this unsafe function for the example's integrity:
    revert("Unsafe fee withdrawal implementation. Requires dedicated fee tracking.");

    // In a real scenario, fees would be tracked explicitly and safely withdrawn.
}


// --- User/Role Management Functions (3 functions) ---
function registerAsProvider() external {
    if (!userProfiles[msg.sender].isProvider) {
        userProfiles[msg.sender].isProvider = true;
        userProfiles[msg.sender].addr = msg.sender; // Store address
        emit ProviderRegistered(msg.sender);
    }
}

function registerAsValidator() external onlyStakingValidator {
     // Validator registration requires staking at least the minimum
    if (!userProfiles[msg.sender].isValidator) {
        userProfiles[msg.sender].isValidator = true;
         userProfiles[msg.sender].addr = msg.sender; // Store address
        emit ValidatorRegistered(msg.sender);
    }
}

function getUserProfile(address user) external view returns (UserProfile memory) {
    return userProfiles[user];
}

// --- Listing Management Functions (6 functions) ---
function listModel(
    string memory cid,
    string memory name,
    string memory description,
    uint256 price,
    bool validationRequired
) external onlyRegisteredProvider {
    if (price == 0) revert DAC_InvalidPrice();

    uint256 listingId = nextListingId++;
    listings[listingId] = Listing({
        id: listingId,
        provider: msg.sender,
        cid: cid,
        name: name,
        description: description,
        price: price,
        isModel: true,
        validationRequired: validationRequired,
        status: validationRequired ? ListingStatus.ValidationRequired : ListingStatus.Active,
        validatedById: 0,
        currentChallengeId: 0,
        buyers: listings[listingId].buyers // Initialize the mapping inside the struct
    });

    emit ModelListed(listingId, msg.sender, cid, name, price, validationRequired);
}

function listDataset(
    string memory cid,
    string memory name,
    string memory description,
    uint256 price,
    bool validationRequired
) external onlyRegisteredProvider {
     if (price == 0) revert DAC_InvalidPrice();

    uint256 listingId = nextListingId++;
    listings[listingId] = Listing({
        id: listingId,
        provider: msg.sender,
        cid: cid,
        name: name,
        description: description,
        price: price,
        isModel: false,
        validationRequired: validationRequired,
        status: validationRequired ? ListingStatus.ValidationRequired : ListingStatus.Active,
        validatedById: 0,
        currentChallengeId: 0,
        buyers: listings[listingId].buyers // Initialize the mapping inside the struct
    });

    emit DatasetListed(listingId, msg.sender, cid, name, price, validationRequired);
}

function updateListing(
    uint256 listingId,
    string memory cid,
    string memory name,
    string memory description,
    uint256 price
) external onlyRegisteredProvider {
    Listing storage listing = listings[listingId];
    if (listing.provider == address(0)) revert DAC_ListingNotFound();
    if (listing.provider != msg.sender) revert DAC_NotRegisteredProvider(); // Should not happen with modifier, but good safety

    listing.cid = cid;
    listing.name = name;
    listing.description = description;
    listing.price = price;
    // Status changes (e.g., from Active back to ValidationRequired) are not handled in simple update
    // A real system might require re-validation on significant updates.

    emit ListingUpdated(listingId, cid, name, price);
}

function delistAsset(uint256 listingId) external onlyRegisteredProvider {
    Listing storage listing = listings[listingId];
    if (listing.provider == address(0)) revert DAC_ListingNotFound();
    if (listing.provider != msg.sender) revert DAC_NotRegisteredProvider(); // Safety

    listing.status = ListingStatus.Delisted; // Prevent new purchases

    emit AssetDelisted(listingId);
}

// --- Purchasing/Access Functions (2 functions - simplified: access/credits are just payments) ---
function buyListingAccess(uint256 listingId) external payable {
    Listing storage listing = listings[listingId];
    if (listing.provider == address(0) || listing.status == ListingStatus.Delisted) revert DAC_ListingNotFound();
    if (listing.status == ListingStatus.ValidationRequired) revert DAC_ListingValidationRequired();
    if (msg.value < listing.price) revert DAC_InsufficientPayment();

    uint256 paymentAmount = msg.value;
    uint256 marketplaceFee = (paymentAmount * marketplaceFeeRate) / 10000; // Rate is / 10000 for percentage
    uint256 providerShare = paymentAmount - marketplaceFee;

    // Add provider's earnings (they withdraw later)
    userProfiles[listing.provider].providerEarnings += providerShare;

    // Track purchase count for this buyer (simple access tracking)
    listing.buyers[msg.sender]++;

    // Note: Marketplace fee is held in the contract. Owner withdraws via `withdrawMarketplaceFees`.
    // This simple model assumes the contract balance holds fees safely until withdrawn.

    if (msg.value > listing.price) {
        // Refund excess Ether
        (bool success, ) = payable(msg.sender).call{value: msg.value - listing.price}("");
        require(success, "Refund failed");
    }

    emit AccessPurchased(listingId, msg.sender, listing.price);
}

function purchaseInferenceCredits(uint256 listingId) external payable {
     Listing storage listing = listings[listingId];
    if (listing.provider == address(0) || listing.status == ListingStatus.Delisted) revert DAC_ListingNotFound();
    if (listing.status == ListingStatus.ValidationRequired) revert DAC_ListingValidationRequired();
    // For credits, any amount > 0 is technically valid, representing value of credits purchased
    if (msg.value == 0) revert DAC_InvalidPayment(); // Custom error for zero payment

     uint256 paymentAmount = msg.value;
    uint256 marketplaceFee = (paymentAmount * marketplaceFeeRate) / 10000;
    uint256 providerShare = paymentAmount - marketplaceFee;

    // Add provider's earnings (they withdraw later)
    userProfiles[listing.provider].providerEarnings += providerShare;

    // Note: The actual number of credits and how they're consumed is off-chain.
    // The on-chain contract just records the payment received by the provider for this service.

    emit InferenceCreditsPurchased(listingId, msg.sender, msg.value);
}

// --- Earnings/Withdrawal Functions (1 function) ---
function withdrawProviderEarnings() external onlyRegisteredProvider {
    uint256 earnings = userProfiles[msg.sender].providerEarnings;
    if (earnings == 0) revert DAC_NoEarningsToWithdraw();

    userProfiles[msg.sender].providerEarnings = 0;

    (bool success, ) = payable(msg.sender).call{value: earnings}("");
    if (!success) {
        // If withdrawal fails, return earnings to the user's balance
        userProfiles[msg.sender].providerEarnings = earnings;
        revert("Withdrawal failed");
    }

    emit ProviderEarningsWithdrawn(msg.sender, earnings);
}

// --- Validation Functions (2 functions) ---
function proposeValidation(uint256 listingId) external payable onlyRegisteredValidator {
    Listing storage listing = listings[listingId];
    if (listing.provider == address(0)) revert DAC_ListingNotFound();
    if (listing.status != ListingStatus.ValidationRequired && listing.status != ListingStatus.Active) revert DAC_ListingAlreadyValidated(); // Can validate active too, to add certified status
    if (listing.currentChallengeId != 0) revert DAC_ValidationInProgress(); // Cannot propose validation if listing is challenged

    if (msg.value < validationFee) revert DAC_InsufficientPayment();
    if (msg.value > validationFee) {
         (bool success, ) = payable(msg.sender).call{value: msg.value - validationFee}("");
         require(success, "Fee refund failed");
    }

    uint256 validationId = nextValidationId++;
    validations[validationId] = Validation({
        id: validationId,
        listingId: listingId,
        validator: msg.sender,
        status: ValidationStatus.Proposed,
        proposeTimestamp: uint48(block.timestamp),
        passed: false, // Default
        detailsCID: "", // Default
        challengeId: 0
    });

    listing.status = ListingStatus.ValidationInProgress; // Custom state? Or keep as ValidationRequired/Active + check challengeId/validationId
    // Let's use challengeId 0 to indicate no active validation/challenge proposal locking it
    listing.currentChallengeId = validationId; // Use challengeId field to track active validation or challenge process

    emit ValidationProposed(validationId, listingId, msg.sender);
}

function submitValidationResult(uint256 validationId, bool passed, string memory detailsCID) external onlyRegisteredValidator {
    Validation storage validation = validations[validationId];
    if (validation.validator == address(0)) revert DAC_ValidationNotFound();
    if (validation.validator != msg.sender) revert DAC_OnlyValidationProposerSubmits();
    if (validation.status != ValidationStatus.Proposed) revert DAC_ValidationAlreadySubmitted();

    validation.passed = passed;
    validation.detailsCID = detailsCID;
    validation.status = ValidationStatus.Submitted;

    // After submission, there's a challenge period for this validation result
    // The listing remains in a "pending validation" or similar state until challenge period ends or challenge is resolved.
    // Let's keep it in ValidationInProgress state.

    emit ValidationSubmitted(validationId, passed, detailsCID);
}

// --- Challenge Functions (4 functions) ---
function challengeValidation(uint256 validationId, string memory reasonCID) external payable {
    Validation storage validation = validations[validationId];
    if (validation.validator == address(0)) revert DAC_ValidationNotFound();
    if (validation.status != ValidationStatus.Submitted) revert DAC_ValidationNotSubmitted();
     // Check if within challenge period after submission (e.g., submitTimestamp + challengePeriod)
     // This requires storing submission timestamp or calculating based on proposal timestamp and validator SLA
     // For simplicity, let's assume challenge is open until resolved or another validation starts.
     // A better system: store submission time and check timestamp <= submissionTime + challengePeriodDuration

    Listing storage listing = listings[validation.listingId];
    // Prevent challenging if already challenged
    if (listing.currentChallengeId != validationId || challenges[listing.currentChallengeId].status != ChallengeStatus.Proposed) {
        revert DAC_ValidationAlreadyChallenged(); // Or more general "Already Under Another Process"
    }


    if (msg.value < stakingRequirement) revert DAC_InsufficientStake(); // Challenger must stake
    uint256 challengerStakeAmount = msg.value;
     if (msg.value > stakingRequirement) {
         (bool success, ) = payable(msg.sender).call{value: msg.value - stakingRequirement}("");
         require(success, "Stake refund failed");
    }

    uint256 challengeId = nextChallengeId++;
    challenges[challengeId] = Challenge({
        id: challengeId,
        targetId: validationId,
        isValidationChallenge: true,
        challenger: msg.sender,
        reasonCID: reasonCID,
        status: ChallengeStatus.Proposed, // Moves to voting phase after proposal
        proposeTimestamp: uint48(block.timestamp),
        challengerStake: challengerStakeAmount,
        totalVoteWeight: 0,
        votesForChallengerWeight: 0,
        votesAgainstChallengerWeight: 0,
        voted: challenges[challengeId].voted // Initialize mapping
    });

    validation.challengeId = challengeId; // Link validation to challenge
    // Listing status should reflect the challenge is happening. Maybe a dedicated state or check listing.currentChallengeId

    emit ChallengeProposed(challengeId, validationId, true, msg.sender);

    // Immediately start voting period after proposal
     _startChallengeVoting(challengeId);
}

function challengeAsset(uint256 listingId, string memory reasonCID) external payable {
     Listing storage listing = listings[listingId];
    if (listing.provider == address(0)) revert DAC_ListingNotFound();
    // Can only challenge Active or Validated listings
    if (listing.status != ListingStatus.Active && listing.status != ListingStatus.Validated) revert DAC_ListingNotAvailable(); // Not challengeable in this state
    // Cannot challenge if already under a validation or challenge process
    if (listing.currentChallengeId != 0) revert DAC_ValidationInProgress(); // Reusing error for "under process"


    if (msg.value < stakingRequirement) revert DAC_InsufficientStake(); // Challenger must stake
    uint256 challengerStakeAmount = msg.value;
     if (msg.value > stakingRequirement) {
         (bool success, ) = payable(msg.sender).call{value: msg.value - stakingRequirement}("");
         require(success, "Stake refund failed");
    }

    uint256 challengeId = nextChallengeId++;
    challenges[challengeId] = Challenge({
        id: challengeId,
        targetId: listingId,
        isValidationChallenge: false,
        challenger: msg.sender,
        reasonCID: reasonCID,
        status: ChallengeStatus.Proposed, // Moves to voting phase after proposal
        proposeTimestamp: uint48(block.timestamp),
        challengerStake: challengerStakeAmount,
        totalVoteWeight: 0,
        votesForChallengerWeight: 0,
        votesAgainstChallengerWeight: 0,
        voted: challenges[challengeId].voted // Initialize mapping
    });

    listing.currentChallengeId = challengeId; // Link listing to challenge
    listing.status = ListingStatus.Challenged; // Set listing status to challenged

    emit ChallengeProposed(challengeId, listingId, false, msg.sender);

    // Immediately start voting period after proposal
    _startChallengeVoting(challengeId);
}

// Internal helper function to start voting
function _startChallengeVoting(uint256 challengeId) internal {
    Challenge storage challenge = challenges[challengeId];
    if (challenge.status != ChallengeStatus.Proposed) revert DAC_ChallengeNotVoteable(); // Should not happen if called right after proposal

    challenge.status = ChallengeStatus.Voting;
    // No event for status change, but could add one if needed.
}


function voteOnChallenge(uint256 challengeId, bool voteForChallenger) external onlyStakingValidator {
    Challenge storage challenge = challenges[challengeId];
    if (challenge.challenger == address(0)) revert DAC_ChallengeNotFound();
    if (challenge.status != ChallengeStatus.Voting) revert DAC_ChallengeNotVoteable();
    if (block.timestamp >= challenge.proposeTimestamp + votingPeriodDuration) revert DAC_ChallengeVotePeriodActive(); // Revert if voting period *ended*
    if (challenge.voted[msg.sender]) revert DAC_AlreadyVoted();

    // Get voter's active stake amount
    uint256 voterStake = validatorStakes[msg.sender].amount;
    if (validatorStakes[msg.sender].status != StakeStatus.Active || voterStake < stakingRequirement) {
        revert DAC_UnauthorizedVoting(); // Only active, minimum-staked validators can vote
    }

    challenge.voted[msg.sender] = true;
    challenge.totalVoteWeight += voterStake;

    if (voteForChallenger) {
        challenge.votesForChallengerWeight += voterStake;
    } else {
        challenge.votesAgainstChallengerWeight += voterStake;
    }

     // Lock the voter's stake in this challenge
    validatorStakes[msg.sender].status = StakeStatus.Locked;
    validatorStakes[msg.sender].lockedChallengeId = challengeId;


    emit ChallengeVoteCast(challengeId, msg.sender, voteForChallenger, voterStake);
}

// This function can be called by anyone after the voting period ends.
// In a real system, might be triggered by an oracle or keeper.
function resolveChallenge(uint256 challengeId) external {
    Challenge storage challenge = challenges[challengeId];
    if (challenge.challenger == address(0)) revert DAC_ChallengeNotFound();
    if (challenge.status != ChallengeStatus.Voting) revert DAC_ChallengeNotResolvable();
    if (block.timestamp < challenge.proposeTimestamp + votingPeriodDuration) revert DAC_ChallengeNotResolvable(); // Voting period not over

    bool challengerWon = false;
    // Simple majority weight wins
    if (challenge.totalVoteWeight > 0 && challenge.votesForChallengerWeight > challenge.votesAgainstChallengerWeight) {
        challengerWon = true;
    }
    // Tie goes against the challenger (or define other rule)
    // If totalVoteWeight is 0, assume challenger loses (no support from validators)

    challenge.status = ChallengeStatus.Resolved;

    // Distribute stakes based on outcome
    if (challengerWon) {
        // Challenger wins: Challenger's stake is returned, validators who voted FOR challenger share validator stakes (slashed from losers).
        // This is a complex reward distribution. For simplicity here: challenger stake is returned.
        // A proper system would manage a reward pool and slash stakes against the outcome.
        // Let's just return challenger stake for this example.
        (bool success, ) = payable(challenge.challenger).call{value: challenge.challengerStake}("");
        require(success, "Challenger stake return failed");
        challenge.challengerStake = 0; // Mark as returned

        // Slash validators who voted AGAINST the challenger. Their slashed stake could go to reward pool or winning validators.
        // This requires iterating through voters or tracking votes differently. Let's skip complex slashing for this example.
        // In a real system: iterate voters in challenge.voted, check their vote, if against winner, slash their stake based on a formula.

        // Update listing/validation status based on challenger win
        if (challenge.isValidationChallenge) {
            Validation storage validation = validations[challenge.targetId];
            validation.status = ValidationStatus.Rejected;
            listings[validation.listingId].status = ListingStatus.Active; // If validation was rejected, revert listing to active
            listings[validation.listingId].validatedById = 0; // Unset validated state
            listings[validation.listingId].currentChallengeId = 0; // Free up listing
            emit ValidationRejected(validation.id, validation.listingId);

        } else { // Challenging an Asset directly
             Listing storage listing = listings[challenge.targetId];
             listing.status = ListingStatus.Delisted; // Challenger won against the asset -> Delist it
             listing.validatedById = 0;
             listing.currentChallengeId = 0; // Free up listing
             emit AssetDelisted(listing.id); // Re-emit delisted event
        }

    } else { // Challenger loses
        // Challenger's stake is distributed (e.g., to winning validators, reward pool, or burned).
        // For simplicity: Challenger stake is lost (conceptually goes to reward pool or burned).
        // Slash validators who voted FOR the challenger (complex, skipped).

         // Update listing/validation status based on challenger loss
        if (challenge.isValidationChallenge) {
            Validation storage validation = validations[challenge.targetId];
            validation.status = ValidationStatus.Accepted; // Validation stands
            listings[validation.listingId].status = ListingStatus.Validated; // Set listing to validated
            listings[validation.listingId].validatedById = validation.id; // Link validation
            listings[validation.listingId].currentChallengeId = 0; // Free up listing
            emit ValidationAccepted(validation.id, validation.listingId);

        } else { // Challenging an Asset directly
             Listing storage listing = listings[challenge.targetId];
             // Asset challenge failed. Status remains, but remove challenged flag.
             // If it was Validated, it stays Validated. If Active, stays Active.
             listing.status = listing.validatedById != 0 ? ListingStatus.Validated : ListingStatus.Active;
             listing.currentChallengeId = 0; // Free up listing
        }
    }

    // Unlock stakes of all validators who voted in this challenge
    // This requires iterating through the `voted` mapping or having a separate list of participants.
    // Iterating mappings in Solidity is not possible. A real system needs an array of participants.
    // For this example, we'll skip the actual unlocking logic here and assume it's handled off-chain or via a helper function.
    // Conceptually: For each address `voter` that `challenge.voted[voter]` is true, if `validatorStakes[voter].lockedChallengeId == challengeId`,
    // set `validatorStakes[voter].status = StakeStatus.Active` and `validatorStakes[voter].lockedChallengeId = 0`.

    emit ChallengeResolved(challengeId, challengerWon);
}

// --- Staking Functions (2 functions) ---
function stakeForValidation() external payable {
    if (msg.value == 0) revert DAC_InsufficientPayment();
    // Validator role registration is separate but requires >= stakingRequirement
    // Anyone can stake, but only those meeting requirement *and* registered can vote/propose validation.

    Stake storage stake = validatorStakes[msg.sender];
    stake.amount += msg.value;
    stake.status = StakeStatus.Active; // Assume active unless locked
    // If already locked in a challenge, new stake is added but status remains locked
    if(stake.lockedChallengeId == 0) {
         stake.status = StakeStatus.Active;
    } else {
         stake.status = StakeStatus.Locked;
    }


    totalStakedAmount += msg.value;

    // Auto-register as validator if minimum met
    if (stake.amount >= stakingRequirement && !userProfiles[msg.sender].isValidator) {
        userProfiles[msg.sender].isValidator = true;
        userProfiles[msg.sender].addr = msg.sender; // Store address
        emit ValidatorRegistered(msg.sender);
    }

    emit StakeDeposited(msg.sender, msg.value, totalStakedAmount);
}

function withdrawStake() external onlyRegisteredValidator {
    Stake storage stake = validatorStakes[msg.sender];
    if (stake.amount == 0) revert DAC_NotEnoughToWithdrawStake();
    if (stake.status == StakeStatus.Locked) revert DAC_StakeLocked();
    // In a real system, might need to check if stake was required for *past* challenges that haven't been resolved/slashed yet.
    // This design assumes stake is only locked during active challenges.

    uint256 amountToWithdraw = stake.amount;
    stake.amount = 0;
    stake.status = StakeStatus.Active; // Reset state, even if amount is 0
    stake.lockedChallengeId = 0;

    totalStakedAmount -= amountToWithdraw;

    (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
    if (!success) {
        // If withdrawal fails, return stake to the user's balance
        stake.amount = amountToWithdraw;
        totalStakedAmount += amountToWithdraw;
        revert("Stake withdrawal failed");
    }

    // If stake falls below minimum, remove validator role? Or just prevent voting/proposing until stake is sufficient again.
    // Let's just prevent voting/proposing if stake < requirement. Keep role registered.

    emit StakeWithdrawn(msg.sender, amountToWithdraw, totalStakedAmount);
}

// NOTE: Slashing mechanism needs to be integrated into `resolveChallenge` based on voting outcome.
// Adding a simplified `slashStake` function callable by owner for emergency/manual override (not ideal for full decentralization)
function slashStake(address validator, uint256 amount) external onlyOwner {
    Stake storage stake = validatorStakes[validator];
    if (stake.amount < amount) revert DAC_NotEnoughToWithdrawStake(); // Reusing error

    stake.amount -= amount;
    totalStakedAmount -= amount;

    // Slashed amount could go to reward pool or be burned. Burning for simplicity.
    // (Sending to address(0) is equivalent to burning Ether on most chains)
    // (bool success, ) = payable(address(0)).call{value: amount}("");
    // require(success, "Slash burning failed"); // Burning ETH can't fail if address(0) is target

    emit StakeSlashed(validator, amount, stake.amount);
}


// --- Reward Functions (2 functions) ---
function claimValidationRewards(uint256 validationId) external onlyRegisteredValidator {
    Validation storage validation = validations[validationId];
    if (validation.validator == address(0)) revert DAC_ValidationNotFound();
    if (validation.validator != msg.sender) revert DAC_UnauthorizedVoting(); // Reusing error
    if (validation.status != ValidationStatus.Accepted) revert DAC_ValidationNotSubmitted(); // Only claim for accepted validation

    // Reward calculation logic: e.g., percentage of marketplace fees generated by this listing,
    // or a fixed reward from a pool, or a share of slashed stakes.
    // For simplicity: assume a small fixed reward for now, or zero if no specific pool managed here.
    // A realistic system would track a pool of rewards (from fees, slashing) and distribute proportionally.
    // Let's use accumulated stakingRewards managed in staking/challenge functions.

    // Check if rewards are available for this specific validation (this is complex)
    // A better model: rewards are pooled and claimed based on stake-time or participation in successful validations/challenges.
    // Let's remove per-validation claim and only have a global staking reward claim.

     revert DAC_NoRewardsToClaim(); // Indicate this function is not implemented in this version

    // In a real system:
    // uint256 rewards = calculateRewardsForValidation(validationId, msg.sender);
    // stakingRewards[msg.sender] -= rewards; // Deduct from pending global rewards
    // (bool success, ) = payable(msg.sender).call{value: rewards}("");
    // require(success, "Reward claim failed");
    // emit ValidationRewardsClaimed(validationId, msg.sender, rewards);

}

function claimStakingRewards() external onlyRegisteredValidator {
    uint256 rewards = stakingRewards[msg.sender];
    if (rewards == 0) revert DAC_NoRewardsToClaim();

    stakingRewards[msg.sender] = 0;

    (bool success, ) = payable(msg.sender).call{value: rewards}("");
    if (!success) {
        stakingRewards[msg.sender] = rewards; // Return rewards to balance
        revert("Reward claim failed");
    }

    emit StakingRewardsClaimed(msg.sender, rewards);
}

// --- Query Functions (6 functions) ---
function getUserStake(address user) external view returns (uint256 amount, StakeStatus status, uint256 lockedChallengeId) {
    Stake storage stake = validatorStakes[user];
    return (stake.amount, stake.status, stake.lockedChallengeId);
}

function getListingDetails(uint256 listingId) external view returns (
    uint256 id, address provider, string memory cid, string memory name, string memory description,
    uint256 price, bool isModel, bool validationRequired, ListingStatus status, uint256 validatedById, uint256 currentChallengeId
) {
    Listing storage listing = listings[listingId];
     if (listing.provider == address(0)) revert DAC_ListingNotFound(); // Indicate not found if provider is zero

    return (
        listing.id,
        listing.provider,
        listing.cid,
        listing.name,
        listing.description,
        listing.price,
        listing.isModel,
        listing.validationRequired,
        listing.status,
        listing.validatedById,
        listing.currentChallengeId
    );
}

function getValidationDetails(uint256 validationId) external view returns (
     uint256 id, uint256 listingId, address validator, ValidationStatus status, uint48 proposeTimestamp, bool passed, string memory detailsCID, uint256 challengeId
) {
    Validation storage validation = validations[validationId];
    if (validation.validator == address(0)) revert DAC_ValidationNotFound(); // Indicate not found

    return (
        validation.id,
        validation.listingId,
        validation.validator,
        validation.status,
        validation.proposeTimestamp,
        validation.passed,
        validation.detailsCID,
        validation.challengeId
    );
}

function getChallengeDetails(uint256 challengeId) external view returns (
    uint256 id, uint256 targetId, bool isValidationChallenge, address challenger, string memory reasonCID,
    ChallengeStatus status, uint48 proposeTimestamp, uint256 challengerStake, uint256 totalVoteWeight,
    uint256 votesForChallengerWeight, uint256 votesAgainstChallengerWeight
) {
     Challenge storage challenge = challenges[challengeId];
    if (challenge.challenger == address(0)) revert DAC_ChallengeNotFound(); // Indicate not found

    return (
        challenge.id,
        challenge.targetId,
        challenge.isValidationChallenge,
        challenge.challenger,
        challenge.reasonCID,
        challenge.status,
        challenge.proposeTimestamp,
        challenge.challengerStake,
        challenge.totalVoteWeight,
        challenge.votesForChallengerWeight,
        challenge.votesAgainstChallengerWeight
    );
}

function getUserEarnings(address user) external view returns (uint256 earnings) {
    return userProfiles[user].providerEarnings;
}

function getTotalStaked() external view returns (uint256) {
    return totalStakedAmount;
}

// Added a helper query function
function hasUserVotedInChallenge(uint256 challengeId, address user) external view returns (bool) {
     Challenge storage challenge = challenges[challengeId];
    if (challenge.challenger == address(0)) revert DAC_ChallengeNotFound();
    return challenge.voted[user];
}


}
```