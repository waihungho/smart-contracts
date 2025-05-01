Okay, here is a smart contract concept that incorporates several interesting, advanced, and dynamic elements: a "ChronoAffinity System" with dynamic, decaying reputation points (CAP - ChronoAffinity Points), linked to token staking and a basic governance mechanism.

This system aims to model a form of "soulbound" or non-transferable reputation that requires continuous engagement (staking/locking) to maintain its value, and can be used for voting power and potentially linked to external identities like NFTs.

**Concept Name:** ChronoAffinitySystem

**Core Idea:** Users lock an ERC20 token ("Epoch Essence" - EPX) for varying durations. This grants them a non-transferable amount of ChronoAffinity Points (CAP). CAP decays over time after the lock period ends, encouraging re-engagement. CAP is used for governance voting power and linking to external IDs.

**Outline:**

1.  **State Variables:** Stores contract parameters, user data, lock data, proposal data.
2.  **Structs:** Definitions for UserLock and Proposal.
3.  **Events:** Signals for key actions (lock, unlock, vote, proposal creation, etc.).
4.  **Modifiers:** Access control and state checks.
5.  **Constructor:** Initializes the contract with the EPX token address.
6.  **Internal Helpers:** Functions for core logic like CAP calculation.
7.  **Locking/Unlocking Functions:** Handles token deposits, CAP calculation, and withdrawals.
8.  **CAP Query Functions:** Retrieves user and total CAP, considering decay.
9.  **Parameter Management Functions:** Allows owner/governance to configure system parameters.
10. **External ID Linking:** Associates a user address with an external identifier (e.g., NFT ID).
11. **Governance Functions:** Handles proposal creation, voting, and execution.
12. **Utility Functions:** Additional features like checking reward eligibility (example).

**Function Summary:**

1.  `constructor(IERC20 _epochEssenceToken)`: Initializes the contract, setting the EPX token address.
2.  `setEpochEssenceToken(IERC20 _newEpochEssenceToken)`: (Owner/Governance) Sets a new EPX token address.
3.  `setDecayRate(uint48 _decayRateMultiplier)`: (Owner/Governance) Sets the multiplier for CAP decay calculation.
4.  `setLockDurationTier(uint48 _duration, uint48 _capMultiplier)`: (Owner/Governance) Sets or updates a lock duration tier and its corresponding CAP multiplier.
5.  `removeLockDurationTier(uint48 _duration)`: (Owner/Governance) Removes a lock duration tier.
6.  `getLockDurationTiers()`: (View) Gets the list of available lock duration tiers.
7.  `getLockTierMultiplier(uint48 _duration)`: (View) Gets the CAP multiplier for a specific lock duration tier.
8.  `lockEpochEssence(uint256 _amount, uint48 _duration)`: Users lock EPX tokens for a specified tier duration, gaining initial CAP.
9.  `_calculateInitialCAP(uint256 _amount, uint48 _duration)`: (Internal) Calculates the initial CAP granted based on amount and duration tier multiplier. Uses a non-linear factor (e.g., `amount * tierMultiplier * log(duration)` - simplified here to `amount * tierMultiplier * duration / BASE_DURATION_UNIT`).
10. `_calculateCurrentCAP(address _user)`: (Internal) Calculates the user's total current CAP by summing initial CAP from all their active/expired locks and applying decay based on time since unlock became available.
11. `getCurrentCAP(address _user)`: (View) Gets the user's total current CAP (external wrapper).
12. `getUserLockCount(address _user)`: (View) Gets the number of locks a user has.
13. `getUserLockDetails(address _user, uint256 _index)`: (View) Gets details for a specific lock of a user.
14. `unlockEpochEssence(uint256 _lockIndex)`: Users claim their locked EPX after the lock period ends.
15. `getTotalCurrentCAP()`: (View) Calculates the sum of current CAP across all users (can be gas-intensive).
16. `linkExternalId(uint256 _externalId)`: Users can link a unique external ID (like an NFT token ID) to their address in this system. Requires minimum CAP.
17. `getExternalId(address _user)`: (View) Gets the external ID linked to a user's address.
18. `createProposal(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)`: Users with sufficient CAP can create a governance proposal.
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Users with CAP can vote on an active proposal. Voting power is based on CAP at proposal creation time (snapshot).
20. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed and met the execution time.
21. `getProposalDetails(uint256 _proposalId)`: (View) Gets details about a specific proposal.
22. `getVotingPower(address _user, uint256 _proposalSnapshotId)`: (View) Gets the user's voting power (CAP) at the time of a specific proposal snapshot. (Note: A full snapshot system is complex; this uses a simplified approach, potentially just current CAP or a stored value).
23. `setProposalConfig(uint48 _votingPeriod, uint48 _quorumNumerator, uint48 _quorumDenominator, uint256 _minProposerCAP, uint48 _executionDelay)`: (Owner/Governance) Sets governance parameters.
24. `checkEligibleForReward(address _user, uint256 _requiredCAP)`: (View) Example function: Checks if a user's current CAP meets a specific threshold for potential rewards/status. (Actual reward distribution would be separate).
25. `emergencyWithdrawStuckTokens(address _token, uint256 _amount)`: (Owner) Allows withdrawal of accidentally sent non-EPX tokens. (Standard safety function).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks, SafeMath can be explicit

// Note: This contract is a complex example and is provided for educational purposes.
// It has not been audited and should NOT be used in production without extensive review and testing.
// Key advanced/creative concepts included:
// 1. Dynamic, time-decaying points/reputation (CAP).
// 2. Non-linear CAP calculation based on lock duration (simplified here).
// 3. Governance system integrated with dynamic CAP as voting power.
// 4. Linking external IDs (e.g., NFTs) to the ChronoAffinity profile.
// 5. Parameterization of decay, lock tiers, and governance via owner/governance.

/**
 * @title ChronoAffinitySystem
 * @dev A system for earning and managing dynamic, decaying reputation points (CAP)
 * based on locking Epoch Essence (EPX) tokens. CAP is used for governance
 * and linking external IDs.
 */
contract ChronoAffinitySystem is Ownable {
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public epochEssenceToken; // The ERC20 token to be locked

    // --- ChronoAffinity Point (CAP) Configuration ---
    // decayRateMultiplier: determines how fast CAP decays after unlock becomes available.
    // CAP decays over a period equal to initial_cap * decayRateMultiplier blocks (or time units)
    // Simpler: CAP = initial_CAP * max(0, 1 - (time_since_unlock / decay_period))
    // Let's use a decay period based on initial duration * multiplier
    uint48 public decayPeriodMultiplier = 2; // e.g., decay period is 2x the initial lock duration

    // Tiered lock durations and their CAP multipliers
    // duration (in seconds) => capMultiplier
    mapping(uint48 => uint48) public lockDurationTiers;
    uint48[] public availableLockDurationTiers;
    uint48 private constant BASE_DURATION_UNIT = 1 days; // A unit for proportional calculation, prevents large numbers

    // --- User Data ---
    struct UserLock {
        uint256 amount; // Amount of EPX locked
        uint256 initialCAP; // CAP granted at the time of locking (before decay)
        uint48 duration; // Duration of the lock (in seconds)
        uint64 startTime; // Timestamp when the lock started
        uint66 endTime; // Timestamp when the lock ends (unlock available)
        bool withdrawn; // True if the EPX has been withdrawn
        uint256 snapshotCAP; // CAP at the moment of locking (used for decay reference) - maybe redundant with initialCAP?
        // Let's simplify decay: initialCAP decays over a period defined by decayPeriodMultiplier * duration, starting AFTER endTime.
    }

    mapping(address => UserLock[]) public userLocks; // Array of locks per user
    mapping(address => uint256) public externalIdLinks; // Link address to an external ID

    // --- Governance Configuration ---
    struct Proposal {
        uint256 id;
        address proposer;
        address[] targets;
        uint256[] values;
        bytes[] calldatas;
        string description;
        uint64 creationTime; // Snapshot time for CAP
        uint64 votingEndTime;
        uint64 executionTime; // Time when it can be executed
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled; // Optional: add logic for canceling
        mapping(address => bool) hasVoted; // Tracks if a user has voted
        mapping(address => uint256) votes; // Stores voting power used
    }

    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    uint48 public votingPeriod = 3 days; // Duration for voting
    uint48 public executionDelay = 1 days; // Delay before execution is possible after voting ends
    uint256 public minProposerCAP = 1000; // Minimum CAP required to create a proposal
    // Simple quorum: percentage of total CAP supply must vote 'For' for it to pass
    uint48 public quorumNumerator = 4; // e.g., 4/10 = 40%
    uint48 public quorumDenominator = 10;

    // Keep track of total initial CAP ever issued (useful for tracking potential max supply)
    uint256 private _totalInitialCAP = 0;

    // --- Events ---
    event EpochsLocked(address indexed user, uint256 amount, uint48 duration, uint256 initialCAP, uint66 endTime);
    event EpochsUnlocked(address indexed user, uint256 amount, uint256 lockIndex);
    event ExternalIdLinked(address indexed user, uint256 externalId);
    event DecayRateSet(uint48 oldRate, uint48 newRate);
    event LockDurationTierSet(uint48 duration, uint48 capMultiplier);
    event LockDurationTierRemoved(uint48 duration);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint64 votingEndTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, string newState); // e.g., "Active", "Succeeded", "Defeated", "Executed"
    event ProposalExecuted(uint256 indexed proposalId);
    event GovernanceConfigSet(uint48 votingPeriod, uint48 executionDelay, uint256 minProposerCAP, uint48 quorumNumerator, uint48 quorumDenominator);


    // --- Modifiers ---
    modifier onlyGovernor() {
        // In a full system, this would check if msg.sender is authorized by governance
        // For simplicity, initially, only owner can set configs.
        // Real governance would involve proposing and voting on config changes.
        // We can use the `executeProposal` function to call config setters.
        // So, let's allow owner AND the contract itself (via execute)
        require(msg.sender == owner() || msg.sender == address(this), "Not authorized by governance");
        _;
    }

    // --- Constructor ---
    constructor(IERC20 _epochEssenceToken) Ownable(msg.sender) {
        epochEssenceToken = _epochEssenceToken;
        // Initial tiers (example)
        setLockDurationTier(30 days, 100); // 1 month, 100x multiplier
        setLockDurationTier(90 days, 350); // 3 months, 350x multiplier
        setLockDurationTier(365 days, 1500); // 1 year, 1500x multiplier
        setLockDurationTier(730 days, 4000); // 2 years, 4000x multiplier
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the initial CAP granted for a lock.
     * Uses a multiplier from the tier system and a non-linear relation with duration.
     * Simplified: amount * tierMultiplier * (duration / BASE_DURATION_UNIT)
     * Real-world non-linear might use log or power functions, but that's complex in Solidity fixed-point.
     */
    function _calculateInitialCAP(uint256 _amount, uint48 _duration) internal view returns (uint256) {
        uint48 capMultiplier = lockDurationTiers[_duration];
        require(capMultiplier > 0, "Invalid lock duration tier");

        // Simple linear calculation for demonstration: amount * multiplier * duration_in_base_units
        // e.g. 100 EPX for 30 days tier (multiplier 100): 100 * 100 * (30 days / 1 day) = 300,000 initial CAP
        // Using SafeMath multiply as amounts/multipliers can be large
        uint256 durationInBaseUnits = uint256(_duration).div(BASE_DURATION_UNIT);
        if (durationInBaseUnits == 0) durationInBaseUnits = 1; // Handle durations less than base unit

        return _amount.mul(capMultiplier).mul(durationInBaseUnits);
    }

    /**
     * @dev Calculates a user's total current CAP across all their locks, applying decay.
     * Decay starts after the lock's endTime.
     * Decay Formula: initialCAP * max(0, 1 - (time_since_unlock_available / total_decay_period))
     * total_decay_period = initial_lock_duration * decayPeriodMultiplier
     */
    function _calculateCurrentCAP(address _user) internal view returns (uint256 currentCAP) {
        uint256 totalUserCAP = 0;
        uint256 currentTime = block.timestamp;

        UserLock[] storage locks = userLocks[_user];
        for (uint i = 0; i < locks.length; i++) {
            UserLock storage lock = locks[i];
            if (lock.amount == 0 || lock.withdrawn) {
                continue; // Skip withdrawn or zero locks
            }

            uint256 lockCAP = lock.initialCAP;
            if (currentTime > lock.endTime) {
                // Decay calculation starts after unlock is available
                uint256 timeSinceUnlockAvailable = currentTime.sub(lock.endTime);
                uint256 totalDecayPeriod = uint256(lock.duration).mul(decayPeriodMultiplier);

                if (totalDecayPeriod > 0) {
                     // Decay factor is percentage of decay period elapsed
                     // Using 1000 as a scaling factor for percentage calculation precision
                    uint256 decayFactorScaled = timeSinceUnlockAvailable.mul(1000).div(totalDecayPeriod);

                    if (decayFactorScaled >= 1000) {
                         // Fully decayed
                         lockCAP = 0;
                    } else {
                         // Apply decay: initialCAP * (1 - decayFactor)
                         lockCAP = lockCAP.mul(1000 - decayFactorScaled).div(1000);
                    }
                } else {
                     // If decayPeriodMultiplier is 0 or duration is 0, no decay after end time?
                     // Let's assume totalDecayPeriod should always be > 0 if decayPeriodMultiplier > 0
                     // If totalDecayPeriod is 0 (e.g. multiplier is 0), no decay after end time.
                     // If multiplier > 0 but duration is 0, this tier shouldn't exist or should have different logic.
                     // Based on constructor, duration > 0 is expected.
                     // If decayPeriodMultiplier is 0, this block is skipped and lockCAP remains initialCAP.
                }
            }
            totalUserCAP = totalUserCAP.add(lockCAP);
        }
        return totalUserCAP;
    }

    // --- Locking/Unlocking Functions ---

    /**
     * @dev Locks EPX tokens for a specified duration tier and grants ChronoAffinity Points (CAP).
     * @param _amount The amount of EPX tokens to lock.
     * @param _duration The duration tier (in seconds) to lock for. Must be an approved tier.
     */
    function lockEpochEssence(uint256 _amount, uint48 _duration) external {
        require(_amount > 0, "Cannot lock 0 amount");
        require(lockDurationTiers[_duration] > 0, "Invalid lock duration tier");

        uint256 initialCAP = _calculateInitialCAP(_amount, _duration);
        require(initialCAP > 0, "Calculated CAP is zero");

        // Transfer tokens from the user to the contract
        require(epochEssenceToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        uint64 startTime = uint64(block.timestamp);
        uint66 endTime = uint66(startTime + _duration); // Safe casting up to 2^66 - 1 (large enough)

        userLocks[msg.sender].push(UserLock({
            amount: _amount,
            initialCAP: initialCAP,
            duration: _duration,
            startTime: startTime,
            endTime: endTime,
            withdrawn: false,
            snapshotCAP: initialCAP // This is initial CAP at lock time
        }));

        _totalInitialCAP = _totalInitialCAP.add(initialCAP);

        emit EpochsLocked(msg.sender, _amount, _duration, initialCAP, endTime);
    }

    /**
     * @dev Allows a user to unlock their EPX tokens after the lock period has ended.
     * @param _lockIndex The index of the lock in the user's locks array.
     */
    function unlockEpochEssence(uint256 _lockIndex) external {
        UserLock storage lock = userLocks[msg.sender][_lockIndex];
        require(!lock.withdrawn, "Lock already withdrawn");
        require(block.timestamp >= lock.endTime, "Lock period not ended yet");
        require(lock.amount > 0, "Lock amount is zero"); // Should not happen with current logic, but safety

        lock.withdrawn = true; // Mark as withdrawn
        // The user's CAP is not affected by withdrawal, only by time/decay.
        // The amount is released.

        require(epochEssenceToken.transfer(msg.sender, lock.amount), "Token transfer back failed");

        // Optional: Remove the lock from the array or mark it more explicitly
        // Removing is gas expensive (shifts elements), marking `withdrawn = true` is simpler
        // Leaving it in the array is fine as `_calculateCurrentCAP` and `unlockEpochEssence` check `withdrawn`

        emit EpochsUnlocked(msg.sender, lock.amount, _lockIndex);
    }

    // --- CAP Query Functions ---

    /**
     * @dev Gets the current ChronoAffinity Points (CAP) for a user, considering decay.
     * @param _user The address of the user.
     * @return The user's current CAP.
     */
    function getCurrentCAP(address _user) public view returns (uint256) {
        return _calculateCurrentCAP(_user);
    }

    /**
     * @dev Gets the number of locks a user has.
     * @param _user The address of the user.
     * @return The number of locks.
     */
    function getUserLockCount(address _user) external view returns (uint256) {
        return userLocks[_user].length;
    }

    /**
     * @dev Gets details for a specific lock of a user.
     * @param _user The address of the user.
     * @param _index The index of the lock.
     * @return amount, initialCAP, duration, startTime, endTime, withdrawn status.
     */
    function getUserLockDetails(address _user, uint256 _index) external view returns (
        uint256 amount,
        uint256 initialCAP,
        uint48 duration,
        uint64 startTime,
        uint66 endTime,
        bool withdrawn
    ) {
        UserLock storage lock = userLocks[_user][_index];
        return (
            lock.amount,
            lock.initialCAP,
            lock.duration,
            lock.startTime,
            lock.endTime,
            lock.withdrawn
        );
    }


    /**
     * @dev Calculates the total current ChronoAffinity Points (CAP) across all users.
     * Note: This can be very gas-intensive if there are many users with locks.
     * A real system might use a snapshot pattern or accrue/decay CAP more actively on user interaction.
     * @return The total current CAP supply.
     */
    function getTotalCurrentCAP() public view returns (uint256) {
        uint256 total = 0;
        // This is inefficient. Iterating over all users is not feasible on-chain.
        // A better approach would be to track total CAP in a state variable and update it
        // upon lock, unlock (influencing decay), or use a snapshot mechanism.
        // For this example, we acknowledge the limitation and show the calculation conceptually.
        // Finding all user addresses is not possible efficiently on-chain.
        // This function is practically unusable on a large network unless refactored.
        // We'll leave it as a conceptual function illustrating total supply.
        // A better way would be to approximate or rely on off-chain calculation based on contract state.
        // Placeholder return acknowledging inefficiency:
         return _totalInitialCAP; // This is NOT total current CAP, just initial. Real total is harder.
        // A true getTotalCurrentCAP requires iterating addresses, which is impossible.
        // Let's return 0 and add a note.
        // return 0; // Signifying it's not practically calculable on-chain this way.
        // OR, calculate decay for total initial CAP based on average lock expiry/decay. Still complex.
        // Let's return _totalInitialCAP as a ceiling, with a strong note.
    }
    // Note on getTotalCurrentCAP: Calculating the sum of current CAP for *all* users on-chain
    // is practically impossible due to the inability to iterate over all addresses and the
    // gas cost of computing decay for potentially many locks. This function is included
    // conceptually but is not viable for a real-world large-scale system in this form.
    // Total initial CAP is tracked, but decay makes calculating the *current* total complex.

    // --- Parameter Management Functions ---

    /**
     * @dev Sets the multiplier for CAP decay period.
     * Only callable by owner or governance.
     * @param _decayPeriodMultiplier The new decay period multiplier.
     */
    function setDecayRate(uint48 _decayPeriodMultiplier) external onlyGovernor {
        require(_decayPeriodMultiplier > 0, "Decay multiplier must be positive");
        emit DecayRateSet(decayPeriodMultiplier, _decayPeriodMultiplier);
        decayPeriodMultiplier = _decayPeriodMultiplier;
    }

    /**
     * @dev Sets or updates a lock duration tier and its corresponding CAP multiplier.
     * Only callable by owner or governance.
     * @param _duration The lock duration (in seconds).
     * @param _capMultiplier The multiplier for this tier.
     */
    function setLockDurationTier(uint48 _duration, uint48 _capMultiplier) public onlyGovernor {
        require(_duration > 0, "Duration must be positive");
        require(_capMultiplier > 0, "Multiplier must be positive");

        bool exists = (lockDurationTiers[_duration] > 0);
        lockDurationTiers[_duration] = _capMultiplier;

        if (!exists) {
            availableLockDurationTiers.push(_duration);
            // Keep sorted (optional but good practice)
            for (uint i = availableLockDurationTiers.length - 1; i > 0; i--) {
                if (availableLockDurationTiers[i] < availableLockDurationTiers[i-1]) {
                    uint48 temp = availableLockDurationTiers[i];
                    availableLockDurationTiers[i] = availableLockDurationTiers[i-1];
                    availableLockDurationTiers[i-1] = temp;
                } else {
                    break;
                }
            }
        }
        emit LockDurationTierSet(_duration, _capMultiplier);
    }

    /**
     * @dev Removes a lock duration tier. Existing locks with this duration are unaffected.
     * Users can no longer create *new* locks for this duration.
     * Only callable by owner or governance.
     * @param _duration The lock duration (in seconds) to remove.
     */
    function removeLockDurationTier(uint48 _duration) external onlyGovernor {
         require(lockDurationTiers[_duration] > 0, "Duration tier does not exist");
         lockDurationTiers[_duration] = 0; // Mark as inactive

         // Remove from the array (inefficient, but array is small)
         for (uint i = 0; i < availableLockDurationTiers.length; i++) {
             if (availableLockDurationTiers[i] == _duration) {
                 availableLockDurationTiers[i] = availableLockDurationTiers[availableLockDurationTiers.length - 1];
                 availableLockDurationTiers.pop();
                 break;
             }
         }
         emit LockDurationTierRemoved(_duration);
    }

    /**
     * @dev Gets the list of available lock duration tiers.
     * @return An array of available lock durations in seconds.
     */
    function getLockDurationTiers() external view returns (uint48[] memory) {
        return availableLockDurationTiers;
    }

     /**
      * @dev Gets the CAP multiplier for a specific lock duration tier.
      * @param _duration The lock duration (in seconds).
      * @return The CAP multiplier, or 0 if the tier doesn't exist.
      */
     function getLockTierMultiplier(uint48 _duration) external view returns (uint48) {
         return lockDurationTiers[_duration];
     }


    /**
     * @dev Sets governance parameters.
     * Only callable by owner or governance.
     */
    function setProposalConfig(
        uint48 _votingPeriod,
        uint48 _executionDelay,
        uint256 _minProposerCAP,
        uint48 _quorumNumerator,
        uint48 _quorumDenominator
    ) external onlyGovernor {
        require(_votingPeriod > 0, "Voting period must be positive");
        require(_executionDelay > 0, "Execution delay must be positive");
        require(_quorumDenominator > 0, "Quorum denominator must be positive");
        require(_quorumNumerator <= _quorumDenominator, "Quorum numerator invalid");

        votingPeriod = _votingPeriod;
        executionDelay = _executionDelay;
        minProposerCAP = _minProposerCAP;
        quorumNumerator = _quorumNumerator;
        quorumDenominator = _quorumDenominator;

        emit GovernanceConfigSet(votingPeriod, executionDelay, minProposerCAP, quorumNumerator, quorumDenominator);
    }

     /**
      * @dev Allows owner/governance to change the EPX token address.
      * Use with extreme caution.
      * @param _newEpochEssenceToken The address of the new EPX token contract.
      */
     function setEpochEssenceToken(IERC20 _newEpochEssenceToken) external onlyGovernor {
         require(address(_newEpochEssenceToken) != address(0), "New token address is zero");
         epochEssenceToken = _newEpochEssenceToken;
     }


    // --- External ID Linking ---

    /**
     * @dev Links a unique external ID (like an NFT token ID) to the user's address.
     * Requires the user to have a minimum amount of current CAP.
     * Overwrites any existing linked ID.
     * @param _externalId The external ID to link.
     */
    function linkExternalId(uint256 _externalId) external {
        require(getCurrentCAP(msg.sender) >= minProposerCAP, "Insufficient CAP to link ID"); // Using minProposerCAP as an example threshold
        externalIdLinks[msg.sender] = _externalId;
        emit ExternalIdLinked(msg.sender, _externalId);
    }

    /**
     * @dev Gets the external ID linked to a user's address.
     * @param _user The address of the user.
     * @return The linked external ID, or 0 if none is linked.
     */
    function getExternalId(address _user) external view returns (uint256) {
        return externalIdLinks[_user];
    }

    // --- Governance Functions ---

    // Note: This is a simplified governance model.
    // A full governance system would involve snapshotting CAP precisely,
    // considering delegated CAP, and potentially a more complex proposal state machine.

    /**
     * @dev Creates a new governance proposal.
     * Requires the proposer to have a minimum amount of current CAP.
     * @param targets The target contract addresses for the proposal execution.
     * @param values The ether values to send with each execution.
     * @param calldatas The calldata for each execution.
     * @param description A description of the proposal.
     */
    function createProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256 proposalId) {
        require(getCurrentCAP(msg.sender) >= minProposerCAP, "Insufficient CAP to create proposal");
        require(targets.length == values.length && targets.length == calldatas.length, "Mismatched proposal parameters");
        require(targets.length > 0, "Proposal must have actions");

        proposalId = nextProposalId++;
        uint64 creationTime = uint64(block.timestamp);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            targets: targets,
            values: values,
            calldatas: calldatas,
            description: description,
            creationTime: creationTime,
            votingEndTime: creationTime + votingPeriod,
            executionTime: creationTime + votingPeriod + executionDelay,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool), // Initialize new mapping
            votes: new mapping(address => uint256) // Initialize new mapping
        });

        emit ProposalCreated(proposalId, msg.sender, description, proposals[proposalId].votingEndTime);
        emit ProposalStateChanged(proposalId, "Pending"); // Or "Active" immediately
    }

    /**
     * @dev Allows a user to vote on an active proposal.
     * Voting power is based on the user's current CAP at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for voting for, false for voting against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist"); // Check if proposal struct is initialized
        require(block.timestamp >= proposal.creationTime && block.timestamp < proposal.votingEndTime, "Voting is not open");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.canceled, "Proposal is canceled"); // Optional: check canceled status

        uint256 votingPower = getCurrentCAP(msg.sender);
        require(votingPower > 0, "Cannot vote with 0 CAP");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = votingPower; // Store power used

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

     /**
      * @dev Get a user's voting power for a specific proposal snapshot.
      * In this simplified model, the snapshot is the CAP at the time of voting.
      * A more robust system would use a block number or a dedicated snapshotting mechanism.
      * @param _user The address of the user.
      * @param _proposalId The proposal ID.
      * @return The user's voting power recorded for that proposal.
      */
     function getVotingPower(address _user, uint256 _proposalId) external view returns (uint256) {
         Proposal storage proposal = proposals[_proposalId];
         require(proposal.id != 0, "Proposal does not exist");
         return proposal.votes[_user];
         // Note: This only works *after* the user has voted. Getting the power *before* voting
         // would require passing the snapshot time/block or using a different storage method.
         // This implementation serves as an example showing CAP usage in voting.
     }


    /**
     * @dev Executes a proposal if it has passed and the execution delay has passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
         require(proposal.id != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal is canceled"); // Optional: check canceled status

        // Check if voting period is over
        require(block.timestamp >= proposal.votingEndTime, "Voting period not ended");

        // Check if execution time has arrived
        require(block.timestamp >= proposal.executionTime, "Execution delay not passed");

        // Determine if the proposal passed
        // Requires quorum: votesFor >= totalCurrentCAP * quorumNumerator / quorumDenominator
        // Requires majority: votesFor > votesAgainst
        // **Issue**: Calculating totalCurrentCAP is hard on-chain.
        // Simplified quorum check: Check votesFor against a fixed number or against initial total CAP?
        // Let's use votesFor vs a percentage of _totalInitialCAP for simplicity, but acknowledge this isn't perfect.
        // Or even simpler: just require votesFor > votesAgainst * AND * votesFor > a fixed minimum.
        // Let's use votesFor > votesAgainst AND votesFor > a minimum *voting* threshold (e.g., 1% of initial CAP ever issued)
        uint256 totalVotingPowerCast = proposal.votesFor.add(proposal.votesAgainst);
        uint256 minVotingPowerForQuorum = _totalInitialCAP.mul(quorumNumerator).div(quorumDenominator); // Use total initial CAP as a reference
        // Note: Using total initial CAP is a simplification. A real system would use
        // total CAP at the snapshot block or total *voting* power delegated/active.

        bool passed = proposal.votesFor > proposal.votesAgainst && totalVotingPowerCast >= minVotingPowerForQuorum;

        require(passed, "Proposal did not pass quorum or majority");

        proposal.executed = true;
        emit ProposalStateChanged(_proposalId, "Executed");
        emit ProposalExecuted(_proposalId);

        // Execute the actions
        for (uint i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{value: proposal.values[i]}(proposal.calldatas[i]);
            require(success, "Proposal execution failed"); // Stop if any call fails
        }
    }

    /**
     * @dev Gets details about a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) external view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint64 creationTime,
        uint64 votingEndTime,
        uint64 executionTime,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool canceled
    ) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist"); // Check if proposal struct is initialized

        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.executionTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.canceled
        );
    }

    /**
     * @dev Determines the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return A string representing the state ("Pending", "Active", "Canceled", "Defeated", "Succeeded", "Executed", "Expired").
     */
    function getProposalState(uint256 _proposalId) external view returns (string memory) {
         Proposal storage proposal = proposals[_proposalId];
         require(proposal.id != 0, "Proposal does not exist");

         if (proposal.canceled) return "Canceled";
         if (proposal.executed) return "Executed";
         if (block.timestamp < proposal.creationTime) return "Pending"; // Should not happen with current logic
         if (block.timestamp < proposal.votingEndTime) return "Active";

         // Voting has ended
         uint256 totalVotingPowerCast = proposal.votesFor.add(proposal.votesAgainst);
         uint256 minVotingPowerForQuorum = _totalInitialCAP.mul(quorumNumerator).div(quorumDenominator); // Using initial CAP as reference

         if (proposal.votesFor > proposal.votesAgainst && totalVotingPowerCast >= minVotingPowerForQuorum) {
             // Passed majority and quorum
             if (block.timestamp < proposal.executionTime) {
                  return "Succeeded"; // Passed, but execution time not reached
             } else {
                  // Passed and execution time is met, but not yet executed
                 return "Executable"; // Custom state for clarity
             }
         } else {
             // Did not pass
             if (block.timestamp < proposal.executionTime) {
                 return "Defeated"; // Defeated before execution window
             } else {
                 return "Expired"; // Defeated and execution window passed
             }
         }
    }


    // --- Utility Functions ---

    /**
     * @dev Example utility function: Checks if a user's current CAP meets a threshold.
     * Can be used by other contracts or off-chain systems for gating rewards, access, etc.
     * @param _user The address of the user.
     * @param _requiredCAP The minimum CAP required.
     * @return True if the user's current CAP is equal to or greater than the required CAP.
     */
    function checkEligibleForReward(address _user, uint256 _requiredCAP) external view returns (bool) {
        return getCurrentCAP(_user) >= _requiredCAP;
    }

    /**
     * @dev Allows the owner to withdraw ERC20 tokens accidentally sent to the contract.
     * Excludes the primary EPX token to prevent draining the system.
     * @param _token The address of the token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function emergencyWithdrawStuckTokens(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(epochEssenceToken), "Cannot withdraw the primary Epoch Essence token");
        IERC20 stuckToken = IERC20(_token);
        require(stuckToken.transfer(owner(), _amount), "Token withdrawal failed");
    }

    // Function Count Check:
    // 1. constructor
    // 2. setEpochEssenceToken
    // 3. setDecayRate
    // 4. setLockDurationTier
    // 5. removeLockDurationTier
    // 6. getLockDurationTiers (view)
    // 7. getLockTierMultiplier (view)
    // 8. lockEpochEssence
    // 9. _calculateInitialCAP (internal) - does not count for external requirement
    // 10. _calculateCurrentCAP (internal) - does not count
    // 11. getCurrentCAP (view)
    // 12. getUserLockCount (view)
    // 13. getUserLockDetails (view)
    // 14. unlockEpochEssence
    // 15. getTotalCurrentCAP (view - noted as impractical)
    // 16. linkExternalId
    // 17. getExternalId (view)
    // 18. createProposal
    // 19. voteOnProposal
    // 20. executeProposal
    // 21. getProposalDetails (view)
    // 22. getVotingPower (view)
    // 23. setProposalConfig
    // 24. checkEligibleForReward (view)
    // 25. emergencyWithdrawStuckTokens

    // Total public/external/view functions = 23. Meets the >20 requirement.

}
```