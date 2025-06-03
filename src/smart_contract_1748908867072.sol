Okay, here is a Solidity smart contract designed with several advanced and creative concepts around data validation, reputation, and staking. It avoids directly copying common patterns like ERC-20/ERC-721 definitions, simple staking pools, or basic access control by integrating these concepts into a unique "Knowledge Chamber" theme.

**Outline and Function Summary:**

This smart contract, named `KnowledgeChamber`, acts as a decentralized platform for users to submit data "claims", stake tokens to support or oppose the accuracy of these claims, earn reputation based on successful validation, and even delegate their validation influence.

1.  **Core Concepts:**
    *   **Claims:** Pieces of data submitted by users.
    *   **Validation Staking:** Users stake an ERC-20 token on a claim, indicating whether they *Support* or *Oppose* its accuracy.
    *   **Resolution:** After a challenge period, a claim can be resolved based on the majority stake (total tokens staked for Support vs. Oppose).
    *   **Reputation:** Users earn reputation points for successfully validating claims (staking on the winning side).
    *   **Delegation:** Users can delegate their earned reputation (validation influence) to another address.
    *   **Payouts:** Winning stakers can claim back their original stake plus a proportional share of the losing stakers' total stake (minus a small protocol fee).
    *   **Burn Reputation:** A placeholder function illustrating a potential future utility for reputation points.

2.  **State Variables:** Stores contract configuration, claim data, user stakes, reputation, and payout information.

3.  **Enums & Structs:** Defines the lifecycle status of a claim and the structure for storing claim details and individual staker information.

4.  **Events:** Logs significant actions like claim submission, staking, resolution, reputation changes, and payouts.

5.  **Modifiers:** Uses OpenZeppelin's `Ownable` and `Pausable` modifiers for access control and emergency stops, plus `ReentrancyGuard` for safe withdrawals.

6.  **Functions (Total: 25+ functions):**

    *   **Owner/Admin (7 functions):**
        *   `constructor`: Initializes the contract owner.
        *   `transferOwnership`: Standard Ownable function.
        *   `pauseContract`: Pauses key user interactions.
        *   `unpauseContract`: Unpauses the contract.
        *   `setStakingToken`: Sets the ERC-20 token address used for staking.
        *   `setMinimumStake`: Sets the minimum amount required to stake on a claim.
        *   `setChallengePeriod`: Sets the duration for the staking/challenge phase of a claim.
        *   `setResolutionFeeBasisPoints`: Sets the fee percentage taken from the losing stake pool during resolution.
        *   `withdrawContractFees`: Allows the owner to withdraw collected fees.

    *   **User Actions (8 functions):**
        *   `submitClaim`: Allows any user to submit a new data claim.
        *   `challengeOrSupportClaim`: Allows a user to stake tokens on a claim, indicating support or opposition. Requires prior token approval.
        *   `resolveClaim`: Callable by anyone after the challenge period ends. Determines the claim's final status based on majority stake, distributes stakes, updates reputation, and queues payouts.
        *   `claimPayout`: Allows a user to withdraw their entitled tokens after a claim they successfully staked on is resolved. Uses `nonReentrant`.
        *   `delegateReputation`: Allows a user to delegate their validation influence (reputation) to another address.
        *   `revokeReputationDelegation`: Allows a user to cancel their delegation.
        *   `burnReputation`: A conceptual function to burn reputation for a future utility (e.g., priority submission).
        *   `approveStakingToken`: (Implicit or explicit user action needed before `challengeOrSupportClaim` if using ERC20 - this function is on the *token* contract, not this one, but is a necessary user step).

    *   **View Functions (10+ functions):**
        *   `getClaimDetails`: Retrieves full details for a specific claim ID.
        *   `getClaimStatus`: Returns only the status of a claim.
        *   `getClaimStakeSummary`: Shows the total staked amounts for Support and Oppose on a claim.
        *   `getUserReputation`: Returns the reputation points for an address.
        *   `getUsersStakeOnClaim`: Returns the amount and type a specific user staked on a specific claim.
        *   `getDelegateeReputation`: Returns the address to which a user has delegated their reputation.
        *   `getDelegator`: Returns the address which has delegated reputation *to* a given address (inverse lookup).
        *   `getContractTokenBalance`: Returns the balance of the staking token held by the contract.
        *   `getTotalClaimsCount`: Returns the total number of claims submitted.
        *   `getCountByStatus`: Returns the count of claims for a given status.
        *   `getClaimResolutionTime`: Returns the timestamp when a claim can be resolved.
        *   `getMinimumStake`: Returns the current minimum stake amount.
        *   `getChallengePeriod`: Returns the challenge period duration.
        *   `getStakingToken`: Returns the address of the staking token.
        *   `getUserPendingPayout`: Returns the amount of tokens queued for withdrawal for a user.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although Solidity 0.8+ checks by default, explicit SafeMath can sometimes improve clarity or handle specific cases. Let's stick to built-in checks for modern solidity.

// --- Outline and Function Summary ---
// This smart contract, KnowledgeChamber, implements a decentralized system for submitting,
// validating, and resolving data claims using staking and a reputation system.
// Users submit claims, stake tokens (Support/Oppose), and earn reputation for successful validation.
// Key features include stake-weighted resolution, reputation delegation, and fee distribution.

// State Variables: Stores contract config, claims, stakes, reputation, payouts.
// Enums & Structs: Define claim status, claim data structure, and staker info.
// Events: Logs key actions (submit, stake, resolve, payout, reputation changes, delegation).
// Modifiers: Ownable, Pausable, ReentrancyGuard (from OpenZeppelin).

// Functions:
// Owner/Admin: constructor, transferOwnership, pauseContract, unpauseContract,
//              setStakingToken, setMinimumStake, setChallengePeriod,
//              setResolutionFeeBasisPoints, withdrawContractFees. (>= 9)
// User Actions: submitClaim, challengeOrSupportClaim, resolveClaim, claimPayout,
//               delegateReputation, revokeReputationDelegation, burnReputation. (>= 7)
// View Functions: getClaimDetails, getClaimStatus, getClaimStakeSummary,
//                 getUserReputation, getUsersStakeOnClaim, getDelegateeReputation,
//                 getDelegator, getContractTokenBalance, getTotalClaimsCount,
//                 getCountByStatus, getClaimResolutionTime, getMinimumStake,
//                 getChallengePeriod, getStakingToken, getUserPendingPayout. (>= 15)
// Total Functions: >= 31

// --- Contract Implementation ---

contract KnowledgeChamber is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Enums ---
    enum ClaimStatus { Pending, Validated, Rejected }
    enum StakeType { Support, Oppose }

    // --- Structs ---
    struct Staker {
        address stakerAddress;
        uint256 amount;
        StakeType stakeType;
    }

    struct Claim {
        uint256 id; // Unique identifier
        address author;
        bytes32 dataHash; // Hash representing the claim's data
        ClaimStatus status;
        uint64 submissionTime; // Using uint64 for gas efficiency if fits
        uint64 resolutionTime; // When it can be resolved
        uint256 totalSupportStake;
        uint256 totalOpposeStake;
        mapping(address => Staker) stakers; // Map staker address to their staking info
        address[] stakerAddresses; // Array to iterate stakers (might be gas intensive for many stakers)
    }

    // --- State Variables ---
    uint256 private _nextClaimId;
    mapping(uint256 => Claim) public claims;
    uint256 public totalClaimsCount; // Counter for total claims submitted

    mapping(address => uint256) public userReputation;
    // Mapping: delegator => delegatee
    mapping(address => address) public delegatedReputation;
    // Mapping: delegatee => total reputation delegated *to* them
    mapping(address => uint256) public reputationDelegatedTo;

    IERC20 public stakingToken;
    uint256 public minimumStake;
    uint64 public challengePeriod; // Duration in seconds
    uint256 public resolutionFeeBasisPoints; // Fee taken from losing pool, in 0.01% (e.g., 100 = 1%)

    // Mapping: user => pending payout amount
    mapping(address => uint256) public userPendingPayout;

    uint256 public totalResolutionFeesCollected; // Total fees accumulated

    // --- Events ---
    event ClaimSubmitted(uint256 indexed claimId, address indexed author, bytes32 dataHash, uint64 submissionTime);
    event StakedOnClaim(uint256 indexed claimId, address indexed staker, uint256 amount, StakeType stakeType);
    event ClaimResolved(uint256 indexed claimId, ClaimStatus finalStatus, uint256 totalSupportStake, uint256 totalOpposeStake, uint256 feesCollected, uint256 distributedAmount);
    event PayoutClaimed(address indexed user, uint256 amount);
    event ReputationIncreased(address indexed user, uint256 newReputation); // Or amount added
    event ReputationBurned(address indexed user, uint256 amount);
    event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 reputationAmount); // Amount delegated (conceptual: total current reputation)
    event ReputationDelegationRevoked(address indexed delegator, address indexed previousDelegatee);
    event StakingTokenSet(address indexed token);
    event MinimumStakeSet(uint256 amount);
    event ChallengePeriodSet(uint64 duration);
    event ResolutionFeeSet(uint256 basisPoints);
    event FeesWithdrawn(address indexed owner, uint256 amount);

    // --- Constructor ---
    constructor(address initialStakingToken, uint256 initialMinimumStake, uint64 initialChallengePeriod, uint256 initialResolutionFeeBasisPoints) Ownable(msg.sender) Pausable(false) {
        // Basic checks
        require(initialStakingToken != address(0), "Invalid staking token address");
        require(initialMinimumStake > 0, "Minimum stake must be greater than zero");
        require(initialChallengePeriod > 0, "Challenge period must be greater than zero");
        require(initialResolutionFeeBasisPoints <= 10000, "Fee basis points cannot exceed 10000 (100%)");

        stakingToken = IERC20(initialStakingToken);
        minimumStake = initialMinimumStake;
        challengePeriod = initialChallengePeriod;
        resolutionFeeBasisPoints = initialResolutionFeeBasisPoints; // Max 10000 = 100% fee

        _nextClaimId = 1; // Start claim IDs from 1
        totalClaimsCount = 0; // Initialize count
    }

    // --- Owner Functions ---

    /// @notice Transfers ownership of the contract.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    /// @notice Pauses contract operations. Can only be called by the owner.
    function pauseContract() public onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    /// @notice Unpauses contract operations. Can only be called by the owner.
    function unpauseContract() public onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    /// @notice Sets the ERC-20 token address used for staking.
    /// @param _stakingToken The address of the new staking token.
    function setStakingToken(address _stakingToken) public onlyOwner whenNotPaused {
        require(_stakingToken != address(0), "Invalid staking token address");
        stakingToken = IERC20(_stakingToken);
        emit StakingTokenSet(_stakingToken);
    }

    /// @notice Sets the minimum required amount to stake on a claim.
    /// @param _minimumStake The new minimum stake amount.
    function setMinimumStake(uint256 _minimumStake) public onlyOwner whenNotPaused {
        require(_minimumStake > 0, "Minimum stake must be greater than zero");
        minimumStake = _minimumStake;
        emit MinimumStakeSet(_minimumStake);
    }

    /// @notice Sets the duration of the challenge period for claims.
    /// @param _challengePeriod The new challenge period duration in seconds.
    function setChallengePeriod(uint64 _challengePeriod) public onlyOwner whenNotPaused {
        require(_challengePeriod > 0, "Challenge period must be greater than zero");
        challengePeriod = _challengePeriod;
        emit ChallengePeriodSet(_challengePeriod);
    }

    /// @notice Sets the percentage of the losing stake pool collected as a protocol fee.
    /// @param _basisPoints Fee in basis points (0-10000, where 100 = 1%).
    function setResolutionFeeBasisPoints(uint256 _basisPoints) public onlyOwner whenNotPaused {
        require(_basisPoints <= 10000, "Fee basis points cannot exceed 10000");
        resolutionFeeBasisPoints = _basisPoints;
        emit ResolutionFeeSet(_basisPoints);
    }

    /// @notice Allows the owner to withdraw accumulated protocol fees.
    function withdrawContractFees() public onlyOwner nonReentrant {
        uint256 fees = totalResolutionFeesCollected;
        require(fees > 0, "No fees collected yet");
        totalResolutionFeesCollected = 0; // Reset balance before transfer
        stakingToken.safeTransfer(owner(), fees);
        emit FeesWithdrawn(owner(), fees);
    }

    // --- User Actions ---

    /// @notice Submits a new data claim to the chamber.
    /// @param _dataHash A bytes32 hash representing the claim's data.
    /// @return claimId The ID of the newly submitted claim.
    function submitClaim(bytes32 _dataHash) public whenNotPaused returns (uint256 claimId) {
        claimId = _nextClaimId++;
        totalClaimsCount++;

        Claim storage newClaim = claims[claimId];
        newClaim.id = claimId;
        newClaim.author = msg.sender;
        newClaim.dataHash = _dataHash;
        newClaim.status = ClaimStatus.Pending;
        newClaim.submissionTime = uint64(block.timestamp);
        newClaim.resolutionTime = uint64(block.timestamp + challengePeriod); // Set resolution time
        newClaim.totalSupportStake = 0;
        newClaim.totalOpposeStake = 0;

        emit ClaimSubmitted(claimId, msg.sender, _dataHash, newClaim.submissionTime);
    }

    /// @notice Stakes tokens on a claim to either support or oppose it.
    /// Requires the user to have pre-approved this contract to spend the staking tokens.
    /// @param _claimId The ID of the claim to stake on.
    /// @param _stakeType The type of stake (Support or Oppose).
    /// @param _amount The amount of tokens to stake. Must be >= minimumStake.
    function challengeOrSupportClaim(uint256 _claimId, StakeType _stakeType, uint256 _amount) public whenNotPaused {
        Claim storage claim = claims[_claimId];

        require(claim.id != 0, "Claim does not exist"); // Check if claim exists
        require(claim.status == ClaimStatus.Pending, "Claim is not pending resolution");
        require(block.timestamp < claim.resolutionTime, "Claim challenge period has ended");
        require(_amount >= minimumStake, "Stake amount too low");

        // Check if user already staked - disallow changing stake or type after first stake
        require(claim.stakers[msg.sender].stakerAddress == address(0), "Already staked on this claim");

        // Pull tokens from the user
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Record the stake
        claim.stakers[msg.sender] = Staker({
            stakerAddress: msg.sender,
            amount: _amount,
            stakeType: _stakeType
        });
        claim.stakerAddresses.push(msg.sender); // Add to iterable list

        if (_stakeType == StakeType.Support) {
            claim.totalSupportStake += _amount;
        } else {
            claim.totalOpposeStake += _amount;
        }

        emit StakedOnClaim(_claimId, msg.sender, _amount, _stakeType);
    }

    /// @notice Resolves a claim based on the majority stake after the challenge period.
    /// Distributes stakes, updates reputation, and queues payouts. Callable by anyone.
    /// @param _claimId The ID of the claim to resolve.
    function resolveClaim(uint256 _claimId) public whenNotPaused nonReentrant {
        Claim storage claim = claims[_claimId];

        require(claim.id != 0, "Claim does not exist");
        require(claim.status == ClaimStatus.Pending, "Claim is not pending resolution");
        require(block.timestamp >= claim.resolutionTime, "Claim challenge period has not ended");

        ClaimStatus finalStatus;
        uint256 totalWinningStake;
        uint256 totalLosingStake;
        StakeType winningStakeType;

        if (claim.totalSupportStake > claim.totalOpposeStake) {
            finalStatus = ClaimStatus.Validated;
            winningStakeType = StakeType.Support;
            totalWinningStake = claim.totalSupportStake;
            totalLosingStake = claim.totalOpposeStake;
        } else if (claim.totalOpposeStake > claim.totalSupportStake) {
            finalStatus = ClaimStatus.Rejected;
            winningStakeType = StakeType.Oppose;
            totalWinningStake = claim.totalOpposeStake;
            totalLosingStake = claim.totalSupportStake;
        } else {
            // Tie condition - return all stakes? Let's make it Rejected for simplicity.
            // Or distribute stakes proportionally? Let's go with Rejected and return all stakes.
            // If tie, return all stakes, no reputation change, no fees.
            finalStatus = ClaimStatus.Rejected; // Or another status like Tied
            totalWinningStake = 0; // No clear winner
            totalLosingStake = 0; // No clear loser
            // For tie, iterate all stakers and queue their stake back
            for (uint i = 0; i < claim.stakerAddresses.length; i++) {
                address stakerAddr = claim.stakerAddresses[i];
                uint256 stakeAmount = claim.stakers[stakerAddr].amount;
                 // Queue the original stake amount back
                userPendingPayout[stakerAddr] += stakeAmount;
            }
             // Update status and emit event
            claim.status = finalStatus;
             emit ClaimResolved(_claimId, finalStatus, claim.totalSupportStake, claim.totalOpposeStake, 0, claim.totalSupportStake + claim.totalOpposeStake);
            return; // Exit early for tie
        }

        // Non-tie resolution logic
        uint256 totalPool = totalWinningStake + totalLosingStake;
        uint256 fees;
        uint256 distributableLoserStake;

        if (resolutionFeeBasisPoints > 0) {
             // Calculate fees from the losing stake pool
            fees = (totalLosingStake * resolutionFeeBasisPoints) / 10000;
            distributableLoserStake = totalLosingStake - fees;
            totalResolutionFeesCollected += fees;
        } else {
            distributableLoserStake = totalLosingStake;
        }

        // Distribute winning stakes and share of losing stake pool
        for (uint i = 0; i < claim.stakerAddresses.length; i++) {
            address stakerAddr = claim.stakerAddresses[i];
            Staker storage staker = claim.stakers[stakerAddr];

            if (staker.stakeType == winningStakeType) {
                // Winner: gets original stake back + proportional share of losing pool
                uint256 winningStake = staker.amount;
                uint256 payoutAmount = winningStake; // Get original stake back

                if (totalWinningStake > 0 && distributableLoserStake > 0) {
                    // Add proportional share of the distributable losing stake pool
                    // (stake / totalWinningStake) * distributableLoserStake
                    // Use checked arithmetic for safety, though 0.8+ does this
                     payoutAmount += (winningStake * distributableLoserStake) / totalWinningStake;
                }

                userPendingPayout[stakerAddr] += payoutAmount;

                // Increase reputation for winning stakers
                // Reputation gain could be proportional to stake or fixed per win
                // Let's add reputation based on their stake amount
                uint256 reputationGained = winningStake; // Simple 1:1 or scale it
                address effectiveReputationHolder = delegatedReputation[stakerAddr] != address(0) ? delegatedReputation[stakerAddr] : stakerAddr;
                userReputation[effectiveReputationHolder] += reputationGained;
                if (effectiveReputationHolder != stakerAddr) {
                     // If delegated, track reputation increase for the delegatee as well
                     reputationDelegatedTo[effectiveReputationHolder] += reputationGained;
                }
                emit ReputationIncreased(effectiveReputationHolder, userReputation[effectiveReputationHolder]); // Emits total new reputation
            } else {
                // Loser: gets nothing from this resolution (stake is absorbed into the pool)
                 // No payout is queued for losers.
            }
            // Note: Stakes recorded in `claim.stakers` remain there for historical record,
            // but the tokens are now either in userPendingPayout or feesCollected.
        }

        // Update claim status
        claim.status = finalStatus;

        emit ClaimResolved(_claimId, finalStatus, claim.totalSupportStake, claim.totalOpposeStake, fees, totalPool - fees);
    }

    /// @notice Allows a user to withdraw their pending payout balance.
    function claimPayout() public nonReentrant {
        uint256 amount = userPendingPayout[msg.sender];
        require(amount > 0, "No pending payout");

        userPendingPayout[msg.sender] = 0; // Reset balance before transfer
        stakingToken.safeTransfer(msg.sender, amount);

        emit PayoutClaimed(msg.sender, amount);
    }

    /// @notice Allows a user to delegate their reputation (validation influence) to another address.
    /// This means any reputation earned by the delegator will be assigned to the delegatee.
    /// Only one delegation per user is allowed at a time.
    /// @param _delegatee The address to delegate reputation to. Address(0) revokes delegation.
    function delegateReputation(address _delegatee) public whenNotPaused {
        require(msg.sender != _delegatee, "Cannot delegate reputation to yourself");

        address currentDelegatee = delegatedReputation[msg.sender];

        if (currentDelegatee != address(0)) {
             // Revoke existing delegation first (optional, but good practice to avoid confusion)
             // Or require revoking first? Let's allow overriding.
             // Need to update the reputationDelegatedTo count correctly:
             // Remove the *current* reputation of the delegator from the *current* delegatee's total
             // Add the *current* reputation of the delegator to the *new* delegatee's total
             // This gets complex if reputation can change rapidly.
             // Simpler approach: Delegation only affects *future* reputation accrual OR
             // delegation means the delegatee *can act on behalf* of the delegator's current reputation.
             // Let's go with the "future accrual" interpretation, simpler state management.
             // The `effectiveReputationHolder` logic in `resolveClaim` handles this.
             // So, when delegating, update the counter for the old delegatee (subtract delegator's current rep)
             // and the new delegatee (add delegator's current rep).

            if(currentDelegatee != _delegatee) {
                 uint256 currentRep = userReputation[msg.sender];
                 if (reputationDelegatedTo[currentDelegatee] >= currentRep) {
                     reputationDelegatedTo[currentDelegatee] -= currentRep;
                 } else {
                     // Should not happen if logic is correct, but defensive coding
                     reputationDelegatedTo[currentDelegatee] = 0;
                 }
                 emit ReputationDelegationRevoked(msg.sender, currentDelegatee);
            } else {
                 // Delegating to the same address again is a no-op
                 return;
            }
        }

        delegatedReputation[msg.sender] = _delegatee;
        uint256 currentRep = userReputation[msg.sender];
        reputationDelegatedTo[_delegatee] += currentRep;

        emit ReputationDelegated(msg.sender, _delegatee, currentRep); // Log current reputation delegated
    }

    /// @notice Revokes an existing reputation delegation. Reputation earned *after* this point
    /// will accrue directly to the revoking user.
    function revokeReputationDelegation() public whenNotPaused {
        address currentDelegatee = delegatedReputation[msg.sender];
        require(currentDelegatee != address(0), "No active delegation to revoke");

        // Update the reputationDelegatedTo counter
        uint256 currentRep = userReputation[msg.sender];
         if (reputationDelegatedTo[currentDelegatee] >= currentRep) {
            reputationDelegatedTo[currentDelegatee] -= currentRep;
        } else {
             reputationDelegatedTo[currentDelegatee] = 0;
        }

        delegatedReputation[msg.sender] = address(0);

        emit ReputationDelegationRevoked(msg.sender, currentDelegatee);
    }

    /// @notice Allows a user to burn their reputation points.
    /// This is a conceptual function; the actual utility of burning reputation
    /// would be implemented here or elsewhere.
    /// @param _amount The amount of reputation to burn.
    function burnReputation(uint256 _amount) public whenNotPaused {
        require(userReputation[msg.sender] >= _amount, "Insufficient reputation");
        userReputation[msg.sender] -= _amount;
        // If delegated, also update the delegatee's counter
        address delegatee = delegatedReputation[msg.sender];
        if (delegatee != address(0)) {
             if (reputationDelegatedTo[delegatee] >= _amount) {
                 reputationDelegatedTo[delegatee] -= _amount;
             } else {
                 reputationDelegatedTo[delegatee] = 0;
             }
        }
        emit ReputationBurned(msg.sender, _amount);
        // Add logic here for what burning reputation unlocks (e.g., priority claim, governance power, etc.)
    }

    // --- View Functions ---

    /// @notice Gets the details of a specific claim.
    /// @param _claimId The ID of the claim.
    /// @return Claim struct excluding the stakers mapping/array (mapping not iterable in Solidity views).
    function getClaimDetails(uint256 _claimId) public view returns (uint256 id, address author, bytes32 dataHash, ClaimStatus status, uint64 submissionTime, uint64 resolutionTime, uint256 totalSupportStake, uint256 totalOpposeStake) {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "Claim does not exist");
        return (
            claim.id,
            claim.author,
            claim.dataHash,
            claim.status,
            claim.submissionTime,
            claim.resolutionTime,
            claim.totalSupportStake,
            claim.totalOpposeStake
        );
    }

     /// @notice Gets the status of a specific claim.
     /// @param _claimId The ID of the claim.
     /// @return The status of the claim.
    function getClaimStatus(uint256 _claimId) public view returns (ClaimStatus) {
         Claim storage claim = claims[_claimId];
         require(claim.id != 0, "Claim does not exist");
         return claim.status;
    }

    /// @notice Gets the summary of staked amounts for a claim.
    /// @param _claimId The ID of the claim.
    /// @return supportStake Total amount staked for Support.
    /// @return opposeStake Total amount staked for Oppose.
    function getClaimStakeSummary(uint256 _claimId) public view returns (uint256 supportStake, uint256 opposeStake) {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "Claim does not exist");
        return (claim.totalSupportStake, claim.totalOpposeStake);
    }

    /// @notice Gets the reputation points for a user.
    /// @param _user The address of the user.
    /// @return The user's reputation points.
    function getUserReputation(address _user) public view returns (uint256) {
        return userReputation[_user];
    }

    /// @notice Gets the stake details for a specific user on a specific claim.
    /// @param _claimId The ID of the claim.
    /// @param _user The address of the user.
    /// @return amount The amount staked by the user.
    /// @return stakeType The type of stake (Support or Oppose).
    function getUsersStakeOnClaim(uint256 _claimId, address _user) public view returns (uint256 amount, StakeType stakeType) {
        Claim storage claim = claims[_claimId];
        require(claim.id != 0, "Claim does not exist");
        Staker storage staker = claim.stakers[_user];
         // If stakerAddress is address(0), the user hasn't staked.
        if (staker.stakerAddress == address(0)) {
            return (0, StakeType.Support); // Return default values or signal not staked
        }
        return (staker.amount, staker.stakeType);
    }

    /// @notice Gets the address to which a user has delegated their reputation.
    /// Returns address(0) if no delegation is active.
    /// @param _delegator The address of the user who might have delegated.
    /// @return The delegatee address, or address(0).
    function getDelegateeReputation(address _delegator) public view returns (address) {
        return delegatedReputation[_delegator];
    }

    /// @notice Gets the total amount of reputation that has been delegated *to* a specific address.
    /// This reflects the sum of the current reputations of all users who have delegated to this address.
    /// Note: This value is updated when delegation changes or the delegator's reputation changes.
    /// @param _delegatee The address receiving delegations.
    /// @return The total amount of reputation delegated to this address.
    function getDelegator(address _delegatee) public view returns (uint256) {
         // The state variable `reputationDelegatedTo` directly stores this.
        return reputationDelegatedTo[_delegatee];
    }


    /// @notice Gets the current balance of the staking token held by the contract.
    /// @return The token balance.
    function getContractTokenBalance() public view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    /// @notice Gets the total number of claims submitted.
    /// @return The total count.
    function getTotalClaimsCount() public view returns (uint256) {
        return totalClaimsCount;
    }

    /// @notice Gets the count of claims in a specific status. (Requires iteration - potentially gas-heavy if called off-chain)
    /// NOTE: For large numbers of claims, this would be inefficient on-chain. Better for off-chain indexing.
    /// @param _status The status to count.
    /// @return The count of claims with the specified status.
    function getCountByStatus(ClaimStatus _status) public view returns (uint256 count) {
         // Iterating over all claims is expensive. A mapping(Status => uint256) counter updated
         // during status changes would be more gas efficient for on-chain calls.
         // This view function is primarily for off-chain use.
        count = 0;
        for (uint i = 1; i <= totalClaimsCount; i++) {
            if (claims[i].id != 0 && claims[i].status == _status) { // Check id!=0 in case of future deletion logic
                count++;
            }
        }
    }

    /// @notice Gets the timestamp when a specific claim can be resolved.
    /// @param _claimId The ID of the claim.
    /// @return The resolution timestamp.
    function getClaimResolutionTime(uint256 _claimId) public view returns (uint64) {
         Claim storage claim = claims[_claimId];
         require(claim.id != 0, "Claim does not exist");
         return claim.resolutionTime;
    }

    /// @notice Gets the current minimum stake amount.
    /// @return The minimum stake amount.
    function getMinimumStake() public view returns (uint256) {
        return minimumStake;
    }

    /// @notice Gets the current challenge period duration in seconds.
    /// @return The challenge period duration.
    function getChallengePeriod() public view returns (uint64) {
        return challengePeriod;
    }

     /// @notice Gets the address of the staking token contract.
     /// @return The staking token address.
    function getStakingToken() public view returns (address) {
        return address(stakingToken);
    }

     /// @notice Gets the amount of tokens currently pending withdrawal for a user.
     /// @param _user The address of the user.
     /// @return The amount of pending payout.
    function getUserPendingPayout(address _user) public view returns (uint256) {
        return userPendingPayout[_user];
    }

    // --- Internal Functions (Helper functions) ---
    // (None needed beyond basic OpenZeppelin overrides for Pausable)

    // The `_beforeTokenTransfer` hook in Pausable would be used if the contract
    // itself was an ERC20 token, which it isn't.
    // The `_pause()` and `_unpause()` calls handle the Pausable state updates.
}
```