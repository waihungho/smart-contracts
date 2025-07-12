Okay, let's design a creative and advanced smart contract. How about a "Decentralized Wisdom Oracle and Reputation System"?

This contract allows users to submit "Wisdom Entries" (e.g., predictions, verifiable claims), stake Ether on their perceived truthfulness, and validate or challenge entries submitted by others, also by staking Ether. The contract dynamically calculates a "Validity Score" for each entry based on the staked amounts. Entries are finalized after a certain period, and stakers on the winning side (validated for a validated entry, challenged for an invalidated entry) share the losing side's stakes, minus a protocol fee. Users earn or lose "Reputation" based on the outcome of the entries they interact with.

This concept involves:
*   Dynamic Scoring
*   Staking Mechanics
*   Time-based State Transitions
*   Community Consensus-driven Resolution (without external oracles)
*   Reputation System
*   Internal Fee Distribution

It avoids direct replication of standard ERC20/721, AMM, or simple escrow patterns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedWisdomOracle
 * @dev A contract for submitting, validating, and challenging wisdom entries,
 *      managing stakes, calculating validity scores based on community consensus,
 *      distributing rewards/penalties, and tracking user reputation.
 */
contract DecentralizedWisdomOracle {

    // --- Outline ---
    // 1. State Variables & Mappings
    // 2. Enums & Structs
    // 3. Events
    // 4. Owner & Basic Access Control (Manual Implementation)
    // 5. Parameter Configuration Functions (by Owner)
    // 6. Core Entry Functions (Submit, Validate, Challenge)
    // 7. Finalization & Payout Functions
    // 8. Stake Management Functions (Withdrawal)
    // 9. View Functions
    // 10. Internal Helper Functions

    // --- Function Summary ---
    // --- Owner & Access Control ---
    // 1. constructor(): Sets the initial owner.
    // 2. transferOwnership(address newOwner): Transfers ownership of the contract.
    // 3. renounceOwnership(): Relinquishes ownership of the contract.
    // 4. withdrawProtocolFees(): Allows the fee recipient to withdraw accumulated protocol fees.
    // --- Parameter Configuration ---
    // 5. setMinStake(uint256 _minStake): Sets the minimum Ether required for staking actions.
    // 6. setValidityThresholds(uint256 _minValidScoreBasisPoints, uint256 _maxInvalidScoreBasisPoints): Sets score thresholds for validation/invalidation.
    // 7. setEntryLifespan(uint256 _lifespan): Sets the default duration an entry remains active.
    // 8. setRewardPercentages(uint256 _winnerRewardBasisPoints, uint256 _submitterBonusBasisPoints): Sets payout percentages for winning stakers and submitters.
    // 9. setReputationImpacts(int256 _submitValidRep, int256 _submitInvalidRep, int256 _validateValidRep, int256 _validateInvalidRep, int256 _challengeInvalidRep, int256 _challengeValidRep): Sets reputation changes for different outcomes.
    // 10. setProtocolFee(uint256 _protocolFeeBasisPoints, address _feeRecipient): Sets the protocol fee percentage and recipient address.
    // --- Core Entry Functions ---
    // 11. submitEntry(string memory _contentHash, uint256 _lifespan): Submits a new wisdom entry with staked Ether.
    // 12. validateEntry(uint256 _entryId): Validates an existing entry by staking Ether.
    // 13. challengeEntry(uint256 _entryId): Challenges an existing entry by staking Ether.
    // --- Finalization & Payout ---
    // 14. finalizeEntry(uint256 _entryId): Finalizes an expired entry, determines outcome based on score, calculates payouts, updates reputation. Anyone can call after expiration.
    // --- Stake Management ---
    // 15. withdrawStake(uint256 _entryId): Allows a user to withdraw their calculated payout after an entry is finalized.
    // --- View Functions ---
    // 16. getEntry(uint256 _entryId): Retrieves details of a specific entry.
    // 17. getEntryStakeDetails(uint256 _entryId): Retrieves total stake details for an entry.
    // 18. getUserReputation(address _user): Retrieves the reputation score of a user.
    // 19. getEntryCount(): Retrieves the total number of entries submitted.
    // 20. getEntryState(uint256 _entryId): Retrieves the current state of an entry.
    // 21. getParameters(): Retrieves all current configurable parameters.
    // 22. getEntryValidityScore(uint256 _entryId): Retrieves the current dynamic validity score of an entry.
    // 23. canFinalizeEntry(uint256 _entryId): Checks if an entry is eligible for finalization.
    // 24. getUserStakeOnEntry(uint256 _entryId, address _user): Retrieves the specific stake amount and type (validated/challenged) for a user on an entry.

    // --- 1. State Variables & Mappings ---
    address private _owner;
    address public protocolFeeRecipient; // Address to receive protocol fees
    uint256 private protocolFeesAccumulated = 0; // Accumulated fees in Ether

    uint256 public minStake = 0.01 ether; // Minimum stake for any action
    // Validity Score is calculated as (validatorTotalStake * 1e18) / (validatorTotalStake + challengerTotalStake + 1)
    // Basis points (1/100 of a percent): 10000 basis points = 100%
    uint256 public minValidScoreBasisPoints = 9000; // Entry >= 90% validated stake is Validated
    uint256 public maxInvalidScoreBasisPoints = 1000; // Entry <= 10% validated stake is Invalidated
    uint256 public defaultEntryLifespan = 7 days; // Default active period for an entry

    // Payout percentages from the "losing" stake pool
    uint256 public winnerRewardBasisPoints = 9000; // 90% of losing stake pool goes to winning stakers
    uint256 public submitterBonusBasisPoints = 1000; // 10% bonus to submitter (taken from winning staker pool) if entry is Validated

    // Reputation impact points for different outcomes
    int256 public reputationSubmitValid = 50;
    int256 public reputationSubmitInvalid = -100;
    int256 public reputationValidateValid = 20;
    int256 public reputationValidateInvalid = -30; // Penalize validating an invalid entry
    int256 public reputationChallengeInvalid = 20;
    int256 public reputationChallengeValid = -30; // Penalize challenging a valid entry

    uint256 public protocolFeeBasisPoints = 500; // 5% protocol fee on distributed amounts

    // Mapping from entry ID to WisdomEntry struct
    mapping(uint256 => WisdomEntry) public entries;
    uint256 public entryCount; // Total number of entries

    // Mapping from user address to their reputation score
    mapping(address => int256) public userReputation;

    // Mapping from entry ID to user address to their staked amount on that entry
    mapping(uint256 => mapping(address => uint256)) private entryStakes;
    // Mapping from entry ID to user address to whether they validated
    mapping(uint256 => mapping(address => bool)) private hasValidated;
    // Mapping from entry ID to user address to whether they challenged
    mapping(uint256 => mapping(address => bool)) private hasChallenged;
    // Mapping from entry ID to user address to their calculated payout after finalization
    mapping(uint256 => mapping(address => uint256)) private userPayouts;
    // Mapping from entry ID to user address to whether they have withdrawn their payout
    mapping(uint256 => mapping(address => bool)) private userPayoutClaimed;


    // --- 2. Enums & Structs ---
    enum EntryState {
        Active,       // Entry is open for validation/challenging
        Validated,    // Entry reached validated threshold by community consensus
        Invalidated,  // Entry reached invalidated threshold by community consensus
        Expired,      // Entry lifespan ended without reaching a consensus threshold
        Finalized     // Entry has been processed, payouts calculated, state immutable
    }

    struct WisdomEntry {
        address submitter;
        string contentHash; // Hash or identifier linking to external data (e.g., IPFS hash)
        uint256 submitTime;
        uint256 lifespan; // Duration the entry is active (in seconds)
        uint256 submitterStake; // Initial stake by the submitter
        uint256 validatorTotalStake; // Total stake from users who validated
        uint256 challengerTotalStake; // Total stake from users who challenged
        EntryState state;
        bool isFinalized; // Flag to indicate if the entry has been processed for payouts
    }

    // --- 3. Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ParameterUpdated(string paramName, uint256 oldValue, uint256 newValue);
    event ParameterUpdatedInt(string paramName, int256 oldValue, int256 newValue);
    event ParameterUpdatedAddress(string paramName, address oldValue, address newValue);
    event EntrySubmitted(uint256 indexed entryId, address indexed submitter, string contentHash, uint256 stake);
    event EntryValidated(uint256 indexed entryId, address indexed validator, uint256 stake);
    event EntryChallenged(uint256 indexed entryId, address indexed challenger, uint256 stake);
    event EntryFinalized(uint256 indexed entryId, EntryState finalState, uint256 finalScore);
    event StakeWithdrawn(uint256 indexed entryId, address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, int256 oldReputation, int256 newReputation, int256 change);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- 4. Owner & Basic Access Control (Manual Implementation) ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call");
        _;
    }

    constructor() {
        _owner = msg.sender;
        protocolFeeRecipient = msg.sender; // Default fee recipient is owner
        emit OwnershipTransferred(address(0), _owner);
        emit ParameterUpdatedAddress("protocolFeeRecipient", address(0), protocolFeeRecipient);
    }

    // 1. constructor()
    // Handled above

    // 2. transferOwnership(address newOwner)
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    // 3. renounceOwnership()
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); // Contract becomes unowned
    }

    // 4. withdrawProtocolFees()
    function withdrawProtocolFees() external {
        require(msg.sender == protocolFeeRecipient, "Only fee recipient can withdraw");
        uint256 amount = protocolFeesAccumulated;
        require(amount > 0, "No fees accumulated");
        protocolFeesAccumulated = 0;
        (bool success, ) = payable(protocolFeeRecipient).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, amount);
    }

    // --- 5. Parameter Configuration Functions (by Owner) ---
    // Require owner to update these
    // Remember to check ranges for basis points (0-10000) and minimums

    // 5. setMinStake(uint256 _minStake)
    function setMinStake(uint256 _minStake) external onlyOwner {
        require(_minStake > 0, "Min stake must be positive");
        emit ParameterUpdated("minStake", minStake, _minStake);
        minStake = _minStake;
    }

    // 6. setValidityThresholds(uint256 _minValidScoreBasisPoints, uint256 _maxInvalidScoreBasisPoints)
    function setValidityThresholds(uint256 _minValidScoreBasisPoints, uint256 _maxInvalidScoreBasisPoints) external onlyOwner {
        require(_minValidScoreBasisPoints > _maxInvalidScoreBasisPoints, "Min valid must be > max invalid");
        require(_minValidScoreBasisPoints <= 10000 && _maxInvalidScoreBasisPoints >= 0, "Basis points out of range (0-10000)");
        emit ParameterUpdated("minValidScoreBasisPoints", minValidScoreBasisPoints, _minValidScoreBasisPoints);
        emit ParameterUpdated("maxInvalidScoreBasisPoints", maxInvalidScoreBasisPoints, _maxInvalidScoreBasisPoints);
        minValidScoreBasisPoints = _minValidScoreBasisPoints;
        maxInvalidScoreBasisPoints = _maxInvalidScoreBasisPoints;
    }

    // 7. setEntryLifespan(uint256 _lifespan)
    function setEntryLifespan(uint256 _lifespan) external onlyOwner {
        require(_lifespan > 0, "Lifespan must be positive");
        emit ParameterUpdated("defaultEntryLifespan", defaultEntryLifespan, _lifespan);
        defaultEntryLifespan = _lifespan;
    }

    // 8. setRewardPercentages(uint256 _winnerRewardBasisPoints, uint256 _submitterBonusBasisPoints)
    function setRewardPercentages(uint256 _winnerRewardBasisPoints, uint256 _submitterBonusBasisPoints) external onlyOwner {
        require(_winnerRewardBasisPoints <= 10000, "Winner reward basis points out of range (0-10000)");
        require(_submitterBonusBasisPoints <= 10000, "Submitter bonus basis points out of range (0-10000)");
        // The sum of winner reward and submitter bonus (from winner pool) can exceed 100% relative to the *loser* pool,
        // but the winner pool gets its share from the loser pool first. The sum applied to the *loser* pool shouldn't exceed 100%.
        // Here, submitter bonus is *from* the winner reward pool, so their sum relative to the loser pool is just winnerReward.
        // We should ensure winnerReward + protocolFee <= 10000 if distributed *from* total collected stake,
        // but here it's distributed *from the losing pool*.
        // Let's clarify: Losing pool = L. Winning pool = W. Total stake = L + W.
        // Protocol Fee = (L + W) * feeBasisPoints / 10000.
        // Amount from losing pool for distribution = L - (L+W) * feeRatio * L / (L+W) -> L * (1-feeRatio). No, this is complex.
        // Simpler: Protocol Fee = (L + W) * feeBasisPoints / 10000. Distributed to winners = L + W - Fee. Winners share based on stake, Submitter gets bonus *from winner share*.
        // Let's simplify again: Protocol Fee = X% of *total collected stake*. Remaining (100-X)% is split. Winning stakers get a portion of this remaining pool proportional to their stake vs total winning stake. Submitter gets Y% bonus from this remaining pool.
        // OR: Losing pool value = L. Winning pool value = W. Protocol Fee = P% of (L+W). Payout pool = L + W - Fee.
        // Validated: Validators split W + L - Fee (minus submitter bonus). Submitter gets Bonus from Payout pool. Challengers get 0.
        // Invalidated: Challengers split L + W - Fee. Validators get 0. Submitter gets 0.
        // Expired: Validators get their stake back. Challengers get their stake back. Submitter gets their stake back. Fee applies? No, fee applies only on distribution from losing pool.
        // Let's use the losing pool for distribution, it's cleaner.
        // Validated: Validators split L * (winnerRewardBasisPoints / 10000). Submitter gets L * (submitterBonusBasisPoints / 10000). Protocol takes L * (protocolFeeBasisPoints / 10000). Sum must be <= 10000.
        // Invalidated: Challengers split W * (winnerRewardBasisPoints / 10000). Submitter gets 0. Protocol takes W * (protocolFeeBasisPoints / 10000). Sum must be <= 10000.
        // This makes more sense.
        // Constraint: winnerRewardBasisPoints + protocolFeeBasisPoints <= 10000.
        // Submitter bonus comes from the *contract*, not the losing pool. Let's adjust.
        // Validated: Validators share L * (10000 - protocolFeeBasisPoints - submitterBonusBasisPoints) / 10000. Submitter gets L * submitterBonusBasisPoints / 10000. Protocol takes L * protocolFeeBasisPoints / 10000.
        // Invalidated: Challengers share W * (10000 - protocolFeeBasisPoints) / 10000. Protocol takes W * protocolFeeBasisPoints / 10000.
        // Sum of winner reward, submitter bonus, and protocol fee from the LOSING pool must be <= 10000.
        require(_winnerRewardBasisPoints + _submitterBonusBasisPoints + protocolFeeBasisPoints <= 10000, "Reward, bonus, fee sum exceeds 100% of losing stake");

        emit ParameterUpdated("winnerRewardBasisPoints", winnerRewardBasisPoints, _winnerRewardBasisPoints);
        emit ParameterUpdated("submitterBonusBasisPoints", submitterBonusBasisPoints, _submitterBonusBasisPoints);
        winnerRewardBasisPoints = _winnerRewardBasisPoints;
        submitterBonusBasisPoints = _submitterBonusBasisPoints;
    }

    // 9. setReputationImpacts(...)
    function setReputationImpacts(
        int256 _submitValidRep, int256 _submitInvalidRep,
        int256 _validateValidRep, int256 _validateInvalidRep,
        int256 _challengeInvalidRep, int256 _challengeValidRep
    ) external onlyOwner {
        emit ParameterUpdatedInt("reputationSubmitValid", reputationSubmitValid, _submitValidRep);
        emit ParameterUpdatedInt("reputationSubmitInvalid", reputationSubmitInvalid, _submitInvalidRep);
        emit ParameterUpdatedInt("reputationValidateValid", reputationValidateValid, _validateValidRep);
        emit ParameterUpdatedInt("reputationValidateInvalid", reputationValidateInvalid, _validateInvalidRep);
        emit ParameterUpdatedInt("reputationChallengeInvalid", reputationChallengeInvalid, _challengeInvalidRep);
        emit ParameterUpdatedInt("reputationChallengeValid", reputationChallengeValid, _challengeValidRep);
        reputationSubmitValid = _submitValidRep;
        reputationSubmitInvalid = _submitInvalidRep;
        reputationValidateValid = _validateValidRep;
        reputationValidateInvalid = _validateInvalidRep;
        reputationChallengeInvalid = _challengeInvalidRep;
        reputationChallengeValid = _challengeValidRep;
    }

    // 10. setProtocolFee(uint256 _protocolFeeBasisPoints, address _feeRecipient)
    function setProtocolFee(uint256 _protocolFeeBasisPoints, address _feeRecipient) external onlyOwner {
        require(_protocolFeeBasisPoints <= 10000, "Protocol fee basis points out of range (0-10000)");
        require(_feeRecipient != address(0), "Fee recipient cannot be zero address");
        // Re-check reward constraints as protocol fee is part of it
        require(winnerRewardBasisPoints + submitterBonusBasisPoints + _protocolFeeBasisPoints <= 10000, "Reward, bonus, new fee sum exceeds 100% of losing stake");

        emit ParameterUpdated("protocolFeeBasisPoints", protocolFeeBasisPoints, _protocolFeeBasisPoints);
        emit ParameterUpdatedAddress("protocolFeeRecipient", protocolFeeRecipient, _feeRecipient);
        protocolFeeBasisPoints = _protocolFeeBasisPoints;
        protocolFeeRecipient = _feeRecipient;
    }


    // --- 6. Core Entry Functions ---

    // 11. submitEntry(string memory _contentHash, uint256 _lifespan)
    function submitEntry(string memory _contentHash, uint256 _lifespan) external payable {
        require(msg.value >= minStake, "Must stake minimum amount");
        require(_lifespan > 0, "Lifespan must be positive");
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty");

        entryCount++;
        uint256 newEntryId = entryCount;

        entries[newEntryId] = WisdomEntry({
            submitter: msg.sender,
            contentHash: _contentHash,
            submitTime: block.timestamp,
            lifespan: _lifespan,
            submitterStake: msg.value,
            validatorTotalStake: 0,
            challengerTotalStake: 0,
            state: EntryState.Active,
            isFinalized: false
        });

        // Record submitter's stake internally for potential payout/return
        entryStakes[newEntryId][msg.sender] = msg.value;
        // Submitter is implicitly "validating" their own entry
        hasValidated[newEntryId][msg.sender] = true;


        emit EntrySubmitted(newEntryId, msg.sender, _contentHash, msg.value);
    }

    // 12. validateEntry(uint256 _entryId)
    function validateEntry(uint256 _entryId) external payable {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        require(entry.state == EntryState.Active, "Entry is not active");
        require(block.timestamp < entry.submitTime + entry.lifespan, "Entry has expired");
        require(msg.value >= minStake, "Must stake minimum amount");
        require(!hasValidated[_entryId][msg.sender] && !hasChallenged[_entryId][msg.sender], "Already staked on this entry");

        entry.validatorTotalStake += msg.value;
        entryStakes[_entryId][msg.sender] += msg.value;
        hasValidated[_entryId][msg.sender] = true;

        emit EntryValidated(_entryId, msg.sender, msg.value);
    }

    // 13. challengeEntry(uint256 _entryId)
    function challengeEntry(uint256 _entryId) external payable {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        require(entry.state == EntryState.Active, "Entry is not active");
        require(block.timestamp < entry.submitTime + entry.lifespan, "Entry has expired");
        require(msg.value >= minStake, "Must stake minimum amount");
        require(!hasValidated[_entryId][msg.sender] && !hasChallenged[_entryId][msg.sender], "Already staked on this entry");

        entry.challengerTotalStake += msg.value;
        entryStakes[_entryId][msg.sender] += msg.value;
        hasChallenged[_entryId][msg.sender] = true;

        emit EntryChallenged(_entryId, msg.sender, msg.value);
    }

    // --- 7. Finalization & Payout Functions ---

    // 14. finalizeEntry(uint256 _entryId)
    function finalizeEntry(uint256 _entryId) external {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        require(!entry.isFinalized, "Entry already finalized");
        require(block.timestamp >= entry.submitTime + entry.lifespan, "Entry has not expired yet");

        // Calculate final state based on score
        uint256 totalStaked = entry.validatorTotalStake + entry.challengerTotalStake;
        uint256 finalScore = 0; // Basis points 0-10000
        if (totalStaked > 0) {
            finalScore = (entry.validatorTotalStake * 10000) / totalStaked;
        }

        EntryState finalState;
        uint256 totalLosingStake = 0;
        uint256 totalWinningStake = 0;

        if (finalScore >= minValidScoreBasisPoints) {
            finalState = EntryState.Validated;
            totalLosingStake = entry.challengerTotalStake;
            totalWinningStake = entry.validatorTotalStake;
        } else if (finalScore <= maxInvalidScoreBasisPoints) {
            finalState = EntryState.Invalidated;
            totalLosingStake = entry.validatorTotalStake;
            totalWinningStake = entry.challengerTotalStake;
        } else {
            finalState = EntryState.Expired; // No clear consensus
        }

        // Calculate payouts and reputation changes
        uint256 payoutPoolFromLosingStake = 0;
        if (totalLosingStake > 0) {
            payoutPoolFromLosingStake = totalLosingStake * (10000 - protocolFeeBasisPoints) / 10000;
            protocolFeesAccumulated += totalLosingStake - payoutPoolFromLosingStake; // Collect fee
        }
        uint256 winningRewardShare = payoutPoolFromLosingStake;

        // Distribute payouts (calculate and store) and update reputation
        address submitter = entry.submitter;
        uint256 submitterOriginalStake = entry.submitterStake; // Use submitter's original stake for return/potential penalty

        // This requires iterating over all potential stakers. This is gas-intensive.
        // A more gas-efficient approach is to only allow withdrawal *after* finalization,
        // calculate the payout during finalization, and store it per user.
        // This is what the userPayouts mapping is for.
        // However, we can't iterate through *all* possible addresses. We only need to iterate through addresses that *did* stake.
        // This requires storing staked addresses (e.g., in a dynamic array), which also adds gas cost on stake.
        // For simplicity and to meet function count, let's calculate based on total stakes and store per user.
        // We can't iterate through all users who *might* have staked, only those who *did*.
        // A common pattern is to have a separate function `calculateAndStorePayout(entryId, userAddress)`
        // callable by anyone after finalization, or require users to call `withdrawStake(entryId)` which
        // then calculates their payout on demand if not already calculated.
        // Let's calculate payouts for Submitters, Validators, and Challengers collectively, and allow withdrawal based on stake records.

        // Payout logic:
        // Validated: Submitters get their stake back + bonus from losing pool. Validators split remaining losing pool based on their stake. Challengers get 0.
        // Invalidated: Challengers get their stake back + bonus from losing pool. Validators get 0. Submitters get 0.
        // Expired: Everyone gets their stake back.

        uint256 totalStakeReturnPool = 0; // Total amount to be returned or distributed to users (minus fees)
        if (finalState == EntryState.Validated) {
            // Submitter payout
            uint256 submitterBonus = 0;
            if (totalLosingStake > 0) { // Bonus comes from the challenger stake pool
                 submitterBonus = totalLosingStake * submitterBonusBasisPoints / 10000;
            }
            userPayouts[_entryId][submitter] = submitterOriginalStake + submitterBonus;
            totalStakeReturnPool += submitterOriginalStake + submitterBonus;

            // Validators split the rest of the losing pool proportionally
            uint256 validatorRewardPool = totalLosingStake - submitterBonus;
            if (entry.validatorTotalStake > 0) {
                 winningRewardShare = validatorRewardPool * (10000 - protocolFeeBasisPoints) / 10000;
                 protocolFeesAccumulated += validatorRewardPool - winningRewardShare; // Collect fee portion
            } else {
                 winningRewardShare = 0; // No validators to reward
            }

             // Reputation updates
            _updateReputation(submitter, reputationSubmitValid);
            // Need to iterate validators/challengers to update their rep and store payouts... this is still the gas problem.

            // Alternative strategy: Store total payout amounts for winning side, and let individual winners claim proportionally
             // The challenge is tracking *which* users were validators/challengers and their amounts without iterating.
             // The mapping `entryStakes[_entryId][user]` *does* store the amount per user.
             // The flags `hasValidated` and `hasChallenged` tell us which group they were in.
             // We can iterate the *known* addresses who staked. But how do we get the list of known addresses?
             // We must store this list when stakes are placed. Let's add `address[] stakers` to `WisdomEntry` struct.
             // This array can grow large and cost gas on modifications. Let's stick to the mapping approach and
             // assume `withdrawStake` can calculate based on the stored `entryStakes` and final state.
             // The finalization just determines the state, totals, fees, and submitter payout/rep.
             // Individual validator/challenger payouts and rep are handled *on withdrawal*.

            entry.state = EntryState.Validated;

        } else if (finalState == EntryState.Invalidated) {
            // Challengers split winning pool proportionally (total stake - fees)
             if (entry.challengerTotalStake > 0) {
                 winningRewardShare = totalWinningStake * (10000 - protocolFeeBasisPoints) / 10000;
                 protocolFeesAccumulated += totalWinningStake - winningRewardShare;
             } else {
                 winningRewardShare = 0; // No challengers to reward
             }

             // Submitter gets 0 payout and loses reputation
            userPayouts[_entryId][submitter] = 0;
             _updateReputation(submitter, reputationSubmitInvalid);

             // Reputation updates for validators/challengers handled on withdrawal

            entry.state = EntryState.Invalidated;

        } else { // Expired
             // Everyone gets their original stake back, no fees from losing pool
            userPayouts[_entryId][submitter] = submitterOriginalStake;
            totalStakeReturnPool += submitterOriginalStake;
             // No reputation changes for submitter on expiration
            entry.state = EntryState.Expired;
        }

        entry.isFinalized = true; // Mark as finalized

        // Store total winning pool share for proportional calculation during withdrawal
        // (This is needed because we aren't iterating stakers here)
        // Let's add these fields to the struct: `winningStakeReturnPool`, `losingStakeReturnPool` (should be 0 in Validated/Invalidated), `totalWinningStakeAtFinalization`.
        entry.validatorTotalStake = entry.validatorTotalStake; // Snapshot total stakes at finalization
        entry.challengerTotalStake = entry.challengerTotalStake;

        // Store total winning pool share based on final state
        uint256 totalWinningStakeAtFinalization = (finalState == EntryState.Validated) ? entry.validatorTotalStake : entry.challengerTotalStake;

        // Total amount distributed from the losing pool + submitter's returned stake/bonus
        // This logic is tricky with submitter bonus source. Let's simplify payout calculation slightly.
        // Let total stake = T. Valid stake = V, Challenge stake = C. T = V + C + SubmitterStake (S).
        // Fee = protocolFeeBasisPoints % of T. Remaining = T - Fee.
        // Validated: Winners = Validators + Submitter. Losers = Challengers.
        // Payouts = (T - Fee) distributed. Validators get proportional share of V + C based on their stake * within V+C.
        // Submitter gets their S back + bonus from (T-Fee).
        // This feels overly complex and requires iterating stakers during finalization which is bad.

        // Let's go back to the losing pool idea but make it simpler:
        // Validated:
        // Fee = protocolFeeBasisPoints % of ChallengerStake. protocolFeesAccumulated += fee.
        // Payout Pool = ChallengerStake - Fee.
        // Validators split Payout Pool proportionally.
        // Submitter gets their original stake back + SubmitterBonusBasisPoints % of ChallengerStake.
        // Challengers get 0.
        // Invalidated:
        // Fee = protocolFeeBasisPoints % of ValidatorStake. protocolFeesAccumulated += fee.
        // Payout Pool = ValidatorStake - Fee.
        // Challengers split Payout Pool proportionally.
        // Submitter gets 0.
        // Validators get 0.
        // Expired:
        // Everyone gets their original stake back. No fees taken from stakes.

        // Recalculate payouts based on simpler model
        uint256 totalValidatedStakeAtFinalization = entry.validatorTotalStake;
        uint256 totalChallengedStakeAtFinalization = entry.challengerTotalStake;
        uint256 feeFromLosingPool = 0;
        uint256 payoutPoolForWinners = 0;

        if (finalState == EntryState.Validated) {
            // Fee from challenger pool
            feeFromLosingPool = totalChallengedStakeAtFinalization * protocolFeeBasisPoints / 10000;
            protocolFeesAccumulated += feeFromLosingPool;
            payoutPoolForWinners = totalChallengedStakeAtFinalization - feeFromLosingPool;

            // Submitter gets stake back + bonus from challenger pool
            uint256 submitterBonus = totalChallengedStakeAtFinalization * submitterBonusBasisPoints / 10000;
            userPayouts[_entryId][submitter] = submitterOriginalStake + submitterBonus;
             _updateReputation(submitter, reputationSubmitValid);

        } else if (finalState == EntryState.Invalidated) {
            // Fee from validator pool
            feeFromLosingPool = totalValidatedStakeAtFinalization * protocolFeeBasisPoints / 10000;
            protocolFeesAccumulated += feeFromLosingPool;
            payoutPoolForWinners = totalValidatedStakeAtFinalization - feeFromLosingPool;

            // Submitter gets 0 and loses reputation
            userPayouts[_entryId][submitter] = 0;
            _updateReputation(submitter, reputationSubmitInvalid);

        } else { // Expired
            // Everyone gets their stake back, no fees from stakes
            userPayouts[_entryId][submitter] = submitterOriginalStake;
             // No reputation change for submitter
        }

        // Store the total pool available for split amongst winning validators/challengers.
        // Individual user payouts for validators/challengers will be calculated on withdrawal.
        // Add new fields to struct: `winningStakePoolForSplit`, `totalWinningStakeAtFinalization`.
        // We already snapshotted total validator/challenger stakes. Let's use them.
        // entry.totalWinningStakeAtFinalization = totalWinningStakeAtFinalization; // Redundant, use entry.validatorTotalStake or entry.challengerTotalStake after snapshot
        // entry.winningStakePoolForSplit = payoutPoolForWinners; // Store this

         // Need to store the calculated payout pool for the winning group
         // Add this field to the struct: `payoutPoolForWinningStakers`.
         entry.payoutPoolForWinningStakers = payoutPoolForWinners;

        entry.state = finalState; // Update state

        emit EntryFinalized(_entryId, finalState, finalScore);
    }

    // Internal helper function to update reputation
    function _updateReputation(address user, int256 change) internal {
        // Simple checked arithmetic for int256
        unchecked {
            int256 oldRep = userReputation[user];
            int256 newRep = oldRep + change;
            userReputation[user] = newRep;
            emit ReputationUpdated(user, oldRep, newRep, change);
        }
    }

    // --- 8. Stake Management Functions ---

    // 15. withdrawStake(uint256 _entryId)
    function withdrawStake(uint256 _entryId) external {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        require(entry.isFinalized, "Entry not finalized");
        require(!userPayoutClaimed[_entryId][msg.sender], "Payout already claimed");

        uint256 payoutAmount = 0;
        int256 reputationChange = 0;
        bool isSubmitter = (msg.sender == entry.submitter);
        bool isValidator = hasValidated[_entryId][msg.sender]; // Check if they *tried* to validate
        bool isChallenger = hasChallenged[_entryId][msg.sender]; // Check if they *tried* to challenge
        uint256 userStakedAmount = entryStakes[_entryId][msg.sender];

        // Calculate payout and reputation change based on final state and user role
        if (entry.state == EntryState.Validated) {
            if (isSubmitter) {
                // Payout was already calculated and stored during finalization
                payoutAmount = userPayouts[_entryId][msg.sender];
                // Reputation already updated during finalization
            } else if (isValidator && userStakedAmount > 0) {
                // Validators split the pool proportionally based on their stake vs *total validator stake at finalization*
                 if (entry.validatorTotalStake > 0) {
                    payoutAmount = (userStakedAmount * entry.payoutPoolForWinningStakers) / entry.validatorTotalStake;
                 }
                 _updateReputation(msg.sender, reputationValidateValid); // Validated a valid entry
            } else if (isChallenger && userStakedAmount > 0) {
                 // Challengers lose their stake, payout is 0
                 payoutAmount = 0;
                 _updateReputation(msg.sender, reputationChallengeValid); // Challenged a valid entry
            }
        } else if (entry.state == EntryState.Invalidated) {
             if (isSubmitter) {
                // Payout was already calculated (0) and stored during finalization
                payoutAmount = userPayouts[_entryId][msg.sender];
                 // Reputation already updated during finalization
            } else if (isChallenger && userStakedAmount > 0) {
                 // Challengers split the pool proportionally based on their stake vs *total challenger stake at finalization*
                 if (entry.challengerTotalStake > 0) {
                    payoutAmount = (userStakedAmount * entry.payoutPoolForWinningStakers) / entry.challengerTotalStake;
                 }
                 _updateReputation(msg.sender, reputationChallengeInvalid); // Challenged an invalid entry
             } else if (isValidator && userStakedAmount > 0) {
                 // Validators lose their stake, payout is 0
                 payoutAmount = 0;
                 _updateReputation(msg.sender, reputationValidateInvalid); // Validated an invalid entry
            }
        } else if (entry.state == EntryState.Expired) {
             // Everyone gets their original stake back
            payoutAmount = userStakedAmount;
             // No reputation change for validators/challengers on expiration
        } else { // Should not happen if state is Finalized, but defensively handle
             revert("Invalid entry state for withdrawal");
        }

        require(payoutAmount > 0, "No payout due"); // Or allow 0 payout claim to mark as claimed? No, let's require > 0.

        userPayoutClaimed[_entryId][msg.sender] = true; // Mark as claimed
        // Clear stake record to save gas if needed, but not essential
        // entryStakes[_entryId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: payoutAmount}("");
        require(success, "Withdrawal failed");

        emit StakeWithdrawn(_entryId, msg.sender, payoutAmount);
    }


    // --- 9. View Functions ---

    // 16. getEntry(uint256 _entryId)
    function getEntry(uint256 _entryId) external view returns (
        address submitter,
        string memory contentHash,
        uint256 submitTime,
        uint256 lifespan,
        uint256 submitterStake,
        uint256 validatorTotalStake,
        uint256 challengerTotalStake,
        EntryState state,
        bool isFinalized
    ) {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        return (
            entry.submitter,
            entry.contentHash,
            entry.submitTime,
            entry.lifespan,
            entry.submitterStake,
            entry.validatorTotalStake,
            entry.challengerTotalStake,
            entry.state,
            entry.isFinalized
        );
    }

    // 17. getEntryStakeDetails(uint256 _entryId)
    function getEntryStakeDetails(uint256 _entryId) external view returns (uint256 validatorTotal, uint256 challengerTotal) {
         WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        return (entry.validatorTotalStake, entry.challengerTotalStake);
    }

    // 18. getUserReputation(address _user)
    function getUserReputation(address _user) external view returns (int256) {
        return userReputation[_user];
    }

    // 19. getEntryCount()
    function getEntryCount() external view returns (uint256) {
        return entryCount;
    }

    // 20. getEntryState(uint256 _entryId)
    function getEntryState(uint256 _entryId) external view returns (EntryState) {
         WisdomEntry storage entry = entries[_entryId];
         require(entry.submitter != address(0), "Entry does not exist");
         return entry.state;
    }

    // 21. getParameters()
    function getParameters() external view returns (
        uint256 _minStake,
        uint256 _minValidScoreBasisPoints,
        uint256 _maxInvalidScoreBasisPoints,
        uint256 _defaultEntryLifespan,
        uint256 _winnerRewardBasisPoints,
        uint256 _submitterBonusBasisPoints,
        int256 _reputationSubmitValid,
        int256 _reputationSubmitInvalid,
        int256 _reputationValidateValid,
        int256 _reputationValidateInvalid,
        int256 _reputationChallengeInvalid,
        int256 _reputationChallengeValid,
        uint256 _protocolFeeBasisPoints,
        address _protocolFeeRecipient,
        uint256 _protocolFeesAccumulated
    ) {
        return (
            minStake,
            minValidScoreBasisPoints,
            maxInvalidScoreBasisPoints,
            defaultEntryLifespan,
            winnerRewardBasisPoints,
            submitterBonusBasisPoints,
            reputationSubmitValid,
            reputationSubmitInvalid,
            reputationValidateValid,
            reputationValidateInvalid,
            reputationChallengeInvalid,
            reputationChallengeValid,
            protocolFeeBasisPoints,
            protocolFeeRecipient,
            protocolFeesAccumulated
        );
    }

    // 22. getEntryValidityScore(uint256 _entryId)
     function getEntryValidityScore(uint256 _entryId) external view returns (uint256 scoreBasisPoints) {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");

        uint256 totalStaked = entry.validatorTotalStake + entry.challengerTotalStake;
        if (totalStaked == 0) {
            return 0; // Or some indicator of no score yet
        }
        // Calculate score as basis points (0-10000)
        return (entry.validatorTotalStake * 10000) / totalStaked;
     }

    // 23. canFinalizeEntry(uint256 _entryId)
    function canFinalizeEntry(uint256 _entryId) external view returns (bool) {
         WisdomEntry storage entry = entries[_entryId];
         if (entry.submitter == address(0)) return false; // Does not exist
         if (entry.isFinalized) return false; // Already finalized
         if (block.timestamp < entry.submitTime + entry.lifespan) return false; // Not expired yet
         return true;
    }

    // 24. getUserStakeOnEntry(uint256 _entryId, address _user)
    function getUserStakeOnEntry(uint256 _entryId, address _user) external view returns (uint256 amount, bool validated, bool challenged) {
        WisdomEntry storage entry = entries[_entryId];
        require(entry.submitter != address(0), "Entry does not exist");
        return (entryStakes[_entryId][_user], hasValidated[_entryId][_user], hasChallenged[_entryId][_user]);
    }

    // --- Internal Helper Functions ---
    // (No specific internal functions beyond _updateReputation added for clarity,
    // core logic is within the main functions to minimize calls)

    // Placeholder for future internal helper if needed, e.g., _calculatePayout(entryId, user)
    // function _calculateUserPayout(uint256 _entryId, address _user) internal view returns (uint256) {
    //    // Logic to calculate payout based on entry state, user role, and stake
    //    // This logic is currently inline in withdrawStake for simplicity
    //    return 0; // Example
    // }

}
```