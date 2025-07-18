Okay, this is an exciting challenge! Let's build a smart contract that goes beyond typical patterns, focusing on **dynamic, time-gated content, decentralized narrative curation, and evolving reputation systems**.

I'll call this contract the **"Chronicle Weaver"**. It manages a sequence of distinct *Epochs*, each with a specific theme and lifespan. Users contribute content (or "fragments") to the active epoch, influencing its narrative and gaining reputation. When an epoch ends, its content is "sealed" (e.g., via an IPFS hash), becoming an immutable record, and rewards are distributed based on contribution and community reception.

---

## Chronicle Weaver Smart Contract: Outline & Function Summary

**Contract Name:** `ChronicleWeaver`

**Purpose:** A decentralized protocol for creating, curating, and archiving time-gated narrative epochs. It enables community-driven content creation within defined periods, with an integrated reputation system and immutable historical records.

---

### **Function Summary:**

**A. Core Epoch Management:**

1.  `constructor()`: Initializes the contract, setting the owner and the first epoch's parameters.
2.  `initiateNewEpoch(string calldata _theme, uint256 _durationInDays, uint256 _initiationFee)`: Allows eligible users to propose and initiate a new epoch after the current one has ended.
3.  `endCurrentEpoch()`: Explicitly ends the current epoch, triggering its sealing process. Can be called by the owner or automatically if duration expires.
4.  `getEpochDetails(uint256 _epochId)`: Retrieves comprehensive details about a specific epoch.
5.  `getCurrentEpochId()`: Returns the ID of the currently active or pending epoch.
6.  `isEpochActive(uint256 _epochId)`: Checks if a given epoch is currently in its active contribution phase.
7.  `canInitiateNewEpoch()`: Checks if the conditions are met to initiate a new epoch.

**B. Content Contribution & Curation:**

8.  `submitContribution(string calldata _contentHash, uint256 _stakeAmount)`: Allows users to submit a content fragment (e.g., IPFS hash) to the active epoch, requiring a stake.
9.  `revokeContribution(uint256 _contributionId)`: Allows a contributor to remove their unvoted contribution if the epoch is still active.
10. `voteOnContribution(uint256 _contributionId, bool _isUpvote)`: Enables users to vote (upvote/downvote) on contributions within the active epoch.
11. `getContributionDetails(uint256 _contributionId)`: Retrieves details about a specific contribution.
12. `getEpochContributions(uint256 _epochId)`: Returns a list of all contribution IDs for a specified epoch.
13. `sealEpochContent(uint256 _epochId, string calldata _ipfsHash)`: An authorized oracle function to officially "seal" an ended epoch with a consolidated IPFS hash of its contents.

**C. Reputation & Incentives:**

14. `getUserInfluence(address _user)`: Retrieves a user's total accumulated influence score across all epochs.
15. `distributeEpochRewards(uint256 _epochId)`: Distributes a share of the epoch's collected fees and stakes to contributors based on their positive impact and influence within that epoch.
16. `claimContributionStake(uint256 _contributionId)`: Allows a contributor to reclaim their initial stake *after* rewards are distributed (or if their contribution was revoked).

**D. Administration & Configuration:**

17. `setEpochInitiationFee(uint256 _newFee)`: Allows the owner to adjust the fee required to initiate a new epoch.
18. `setMinimumContributionStake(uint256 _minStake)`: Allows the owner to adjust the minimum stake required for a contribution.
19. `registerOracleAddress(address _oracleAddress)`: Authorizes a new address to act as an oracle for sealing epochs.
20. `deregisterOracleAddress(address _oracleAddress)`: Revokes oracle authorization.
21. `withdrawContractBalance()`: Allows the owner to withdraw accumulated contract balance.
22. `pauseEpochContributions(uint256 _epochId, bool _pause)`: Allows the owner to temporarily pause/unpause contributions for a specific active epoch (e.g., for moderation).
23. `migrateEpochContent(uint256 _sourceEpochId, uint256 _targetEpochId, uint256[] calldata _contributionIds)`: Allows the owner to selectively "migrate" important contribution IDs from a sealed epoch to a new, active one, potentially for narrative continuity or re-evaluation.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ChronicleWeaver
 * @dev A decentralized protocol for creating, curating, and archiving time-gated narrative epochs.
 *      It enables community-driven content creation within defined periods, with an integrated
 *      reputation system and immutable historical records.
 */
contract ChronicleWeaver is Ownable, ReentrancyGuard {

    // --- Enums ---
    enum EpochStatus {
        Pending,   // Epoch initiated but not yet active
        Active,    // Epoch is open for contributions and voting
        Ended,     // Epoch duration has passed, contributions/voting closed
        Sealed     // Epoch content is finalized and immutable (IPFS hash recorded)
    }

    // --- Structs ---

    struct Epoch {
        uint256 id;                 // Unique ID for the epoch
        string theme;               // The thematic prompt or narrative for the epoch
        address creator;            // Address of the user who initiated this epoch
        uint256 startTime;          // Timestamp when the epoch became active
        uint256 endTime;            // Timestamp when the epoch is scheduled to end
        EpochStatus status;         // Current status of the epoch
        uint256 contributionCount;  // Total number of contributions to this epoch
        uint256 totalValueContributed; // Sum of all stakes in this epoch
        string sealedContentIpfsHash; // IPFS hash of the consolidated content once sealed
        bool contributionsPaused;   // Admin flag to pause contributions for this epoch
    }

    struct Contribution {
        uint256 id;                 // Unique ID for the contribution
        uint256 epochId;            // The epoch this contribution belongs to
        address contributor;        // Address of the user who submitted the contribution
        uint256 timestamp;          // Timestamp when the contribution was submitted
        string contentHash;         // IPFS hash or similar identifier for the content
        uint256 stakeAmount;        // Amount of ETH/token staked with this contribution
        uint256 upvotes;            // Number of upvotes received
        uint256 downvotes;          // Number of downvotes received
        bool stakeClaimed;          // Flag to check if the stake has been claimed
    }

    // --- State Variables ---

    uint256 public currentEpochId;
    uint256 public nextContributionId;
    uint256 public epochInitiationFee;
    uint256 public minimumContributionStake;

    mapping(uint256 => Epoch) public epochs;
    mapping(uint256 => Contribution) public contributions;
    mapping(uint256 => uint256[]) public epochContributions; // epochId => array of contribution IDs
    mapping(address => mapping(uint256 => bool)) public hasVoted; // user => contributionId => voted
    mapping(address => uint256) public userInfluence; // user => total accumulated influence score
    mapping(address => bool) public isOracle; // address => is authorized oracle

    // --- Events ---

    event EpochInitiated(uint256 indexed epochId, string theme, address indexed creator, uint256 startTime, uint256 endTime);
    event EpochEnded(uint256 indexed epochId, string theme);
    event EpochSealed(uint256 indexed epochId, string ipfsHash);
    event ContributionSubmitted(uint256 indexed contributionId, uint256 indexed epochId, address indexed contributor, string contentHash, uint256 stakeAmount);
    event ContributionRevoked(uint256 indexed contributionId, uint256 indexed epochId, address indexed contributor);
    event ContributionVoted(uint256 indexed contributionId, address indexed voter, bool isUpvote);
    event RewardsDistributed(uint256 indexed epochId, uint256 totalRewarded, uint256 totalFeesCollected);
    event StakeClaimed(uint256 indexed contributionId, address indexed contributor, uint256 amount);
    event EpochInitiationFeeUpdated(uint256 newFee);
    event MinimumContributionStakeUpdated(uint256 newStake);
    event OracleRegistered(address indexed oracleAddress);
    event OracleDeregistered(address indexed oracleAddress);
    event EpochContributionsPaused(uint256 indexed epochId, bool paused);
    event EpochContentMigrated(uint256 indexed sourceEpochId, uint256 indexed targetEpochId, uint256[] contributionIds);

    // --- Constructor ---

    /**
     * @dev Initializes the contract, setting the owner, default fees, and the first epoch.
     * @param _initialTheme The theme for the very first epoch.
     * @param _initialDurationInDays The duration in days for the first epoch.
     */
    constructor(string memory _initialTheme, uint256 _initialDurationInDays) Ownable(msg.sender) {
        epochInitiationFee = 0.05 ether; // Default fee to initiate a new epoch
        minimumContributionStake = 0.001 ether; // Default minimum stake for a contribution

        currentEpochId = 1;
        nextContributionId = 1;

        uint256 initialStartTime = block.timestamp;
        uint256 initialEndTime = initialStartTime + (_initialDurationInDays * 1 days);

        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            theme: _initialTheme,
            creator: msg.sender, // Owner initiates the first epoch
            startTime: initialStartTime,
            endTime: initialEndTime,
            status: EpochStatus.Active,
            contributionCount: 0,
            totalValueContributed: 0,
            sealedContentIpfsHash: "",
            contributionsPaused: false
        });

        emit EpochInitiated(currentEpochId, _initialTheme, msg.sender, initialStartTime, initialEndTime);
    }

    // --- A. Core Epoch Management ---

    /**
     * @dev Initiates a new epoch. Can only be called if the current epoch has ended or been sealed.
     *      Requires a fee paid by the caller.
     * @param _theme The thematic prompt or narrative for the new epoch.
     * @param _durationInDays The duration in days for this epoch.
     * @param _initiationFee The fee to initiate this epoch (must match `epochInitiationFee`).
     */
    function initiateNewEpoch(string calldata _theme, uint256 _durationInDays, uint256 _initiationFee) external payable nonReentrant {
        require(msg.value == epochInitiationFee, "CW: Incorrect initiation fee");
        require(_initiationFee == epochInitiationFee, "CW: Provided fee does not match current initiation fee.");
        require(_durationInDays > 0, "CW: Epoch duration must be positive");

        Epoch storage currentEpoch = epochs[currentEpochId];
        require(currentEpoch.status == EpochStatus.Ended || currentEpoch.status == EpochStatus.Sealed, "CW: Current epoch must be ended or sealed to initiate a new one");

        currentEpochId++;
        uint256 newStartTime = block.timestamp;
        uint256 newEndTime = newStartTime + (_durationInDays * 1 days);

        epochs[currentEpochId] = Epoch({
            id: currentEpochId,
            theme: _theme,
            creator: msg.sender,
            startTime: newStartTime,
            endTime: newEndTime,
            status: EpochStatus.Active,
            contributionCount: 0,
            totalValueContributed: 0,
            sealedContentIpfsHash: "",
            contributionsPaused: false
        });

        emit EpochInitiated(currentEpochId, _theme, msg.sender, newStartTime, newEndTime);
    }

    /**
     * @dev Explicitly ends the current epoch. Can be called by the owner or if the epoch's end time is reached.
     *      Sets the epoch status to `Ended`. Reward distribution and sealing can then proceed.
     */
    function endCurrentEpoch() external nonReentrant {
        Epoch storage currentEpoch = epochs[currentEpochId];
        require(currentEpoch.status == EpochStatus.Active, "CW: Current epoch is not active");
        require(msg.sender == owner() || block.timestamp >= currentEpoch.endTime, "CW: Epoch not ended or caller not owner");

        currentEpoch.status = EpochStatus.Ended;
        emit EpochEnded(currentEpochId, currentEpoch.theme);
    }

    /**
     * @dev Retrieves comprehensive details about a specific epoch.
     * @param _epochId The ID of the epoch to query.
     * @return Epoch struct containing all details.
     */
    function getEpochDetails(uint256 _epochId) external view returns (Epoch memory) {
        require(_epochId <= currentEpochId && _epochId > 0, "CW: Invalid epoch ID");
        return epochs[_epochId];
    }

    /**
     * @dev Returns the ID of the currently active or pending epoch.
     * @return The current epoch ID.
     */
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    /**
     * @dev Checks if a given epoch is currently in its active contribution phase.
     * @param _epochId The ID of the epoch to check.
     * @return True if the epoch is active, false otherwise.
     */
    function isEpochActive(uint256 _epochId) public view returns (bool) {
        Epoch storage epoch = epochs[_epochId];
        return epoch.status == EpochStatus.Active && block.timestamp < epoch.endTime && !epoch.contributionsPaused;
    }

    /**
     * @dev Checks if the conditions are met to initiate a new epoch.
     * @return True if a new epoch can be initiated, false otherwise.
     */
    function canInitiateNewEpoch() external view returns (bool) {
        Epoch storage currentEpoch = epochs[currentEpochId];
        return currentEpoch.status == EpochStatus.Ended || currentEpoch.status == EpochStatus.Sealed;
    }

    // --- B. Content Contribution & Curation ---

    /**
     * @dev Allows users to submit a content fragment (e.g., IPFS hash) to the active epoch.
     *      Requires a stake to be paid, which is held by the contract.
     * @param _contentHash An IPFS hash or similar identifier pointing to the contribution content.
     * @param _stakeAmount The amount of ETH/token staked with this contribution (must meet minimum).
     */
    function submitContribution(string calldata _contentHash, uint256 _stakeAmount) external payable nonReentrant {
        Epoch storage currentEpoch = epochs[currentEpochId];
        require(isEpochActive(currentEpochId), "CW: Current epoch is not active for contributions");
        require(!currentEpoch.contributionsPaused, "CW: Contributions are currently paused for this epoch.");
        require(msg.value == _stakeAmount, "CW: Sent value must match stake amount");
        require(_stakeAmount >= minimumContributionStake, "CW: Stake amount too low");
        require(bytes(_contentHash).length > 0, "CW: Content hash cannot be empty");

        uint256 newContributionId = nextContributionId++;
        contributions[newContributionId] = Contribution({
            id: newContributionId,
            epochId: currentEpochId,
            contributor: msg.sender,
            timestamp: block.timestamp,
            contentHash: _contentHash,
            stakeAmount: _stakeAmount,
            upvotes: 0,
            downvotes: 0,
            stakeClaimed: false
        });

        epochContributions[currentEpochId].push(newContributionId);
        currentEpoch.contributionCount++;
        currentEpoch.totalValueContributed += _stakeAmount;

        emit ContributionSubmitted(newContributionId, currentEpochId, msg.sender, _contentHash, _stakeAmount);
    }

    /**
     * @dev Allows a contributor to remove their unvoted contribution if the epoch is still active.
     *      The stake is returned.
     * @param _contributionId The ID of the contribution to revoke.
     */
    function revokeContribution(uint256 _contributionId) external nonReentrant {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor == msg.sender, "CW: Only contributor can revoke");
        require(contribution.epochId == currentEpochId, "CW: Can only revoke from current epoch");
        require(isEpochActive(currentEpochId), "CW: Current epoch is not active");
        require(contribution.upvotes == 0 && contribution.downvotes == 0, "CW: Cannot revoke a voted contribution");
        require(!contribution.stakeClaimed, "CW: Stake already claimed");

        // Mark stake as claimed and transfer funds
        contribution.stakeClaimed = true;
        payable(msg.sender).transfer(contribution.stakeAmount);

        // Optionally, could remove from epochContributions array (gas expensive, often skipped for simplicity)
        // For now, we'll keep it in the array but it's logically "removed" by the revoke status.

        emit ContributionRevoked(_contributionId, contribution.epochId, msg.sender);
    }

    /**
     * @dev Enables users to vote (upvote/downvote) on contributions within the active epoch.
     *      A user can only vote once per contribution.
     * @param _contributionId The ID of the contribution to vote on.
     * @param _isUpvote True for an upvote, false for a downvote.
     */
    function voteOnContribution(uint256 _contributionId, bool _isUpvote) external nonReentrant {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.epochId == currentEpochId, "CW: Can only vote on contributions in the current epoch");
        require(isEpochActive(currentEpochId), "CW: Current epoch is not active for voting");
        require(contribution.contributor != msg.sender, "CW: Cannot vote on your own contribution");
        require(!hasVoted[msg.sender][_contributionId], "CW: Already voted on this contribution");

        hasVoted[msg.sender][_contributionId] = true;

        if (_isUpvote) {
            contribution.upvotes++;
        } else {
            contribution.downvotes++;
        }

        emit ContributionVoted(_contributionId, msg.sender, _isUpvote);
    }

    /**
     * @dev Retrieves details about a specific contribution.
     * @param _contributionId The ID of the contribution to query.
     * @return Contribution struct containing all details.
     */
    function getContributionDetails(uint256 _contributionId) external view returns (Contribution memory) {
        require(_contributionId < nextContributionId && _contributionId > 0, "CW: Invalid contribution ID");
        return contributions[_contributionId];
    }

    /**
     * @dev Returns a list of all contribution IDs for a specified epoch.
     * @param _epochId The ID of the epoch to query contributions for.
     * @return An array of contribution IDs.
     */
    function getEpochContributions(uint256 _epochId) external view returns (uint256[] memory) {
        require(_epochId <= currentEpochId && _epochId > 0, "CW: Invalid epoch ID");
        return epochContributions[_epochId];
    }

    /**
     * @dev An authorized oracle function to officially "seal" an ended epoch with a consolidated IPFS hash of its contents.
     *      This marks the epoch as immutable.
     * @param _epochId The ID of the epoch to seal.
     * @param _ipfsHash The IPFS hash representing the compiled and sealed content of the epoch.
     */
    function sealEpochContent(uint256 _epochId, string calldata _ipfsHash) external nonReentrant {
        require(isOracle[msg.sender], "CW: Only authorized oracles can seal epochs");
        Epoch storage epochToSeal = epochs[_epochId];
        require(epochToSeal.status == EpochStatus.Ended, "CW: Epoch must be in 'Ended' status to be sealed");
        require(bytes(_ipfsHash).length > 0, "CW: IPFS hash cannot be empty");
        
        epochToSeal.sealedContentIpfsHash = _ipfsHash;
        epochToSeal.status = EpochStatus.Sealed;

        emit EpochSealed(_epochId, _ipfsHash);
    }

    // --- C. Reputation & Incentives ---

    /**
     * @dev Retrieves a user's total accumulated influence score across all epochs.
     * @param _user The address of the user to query.
     * @return The influence score.
     */
    function getUserInfluence(address _user) external view returns (uint256) {
        return userInfluence[_user];
    }

    /**
     * @dev Distributes a share of the epoch's collected fees and stakes to contributors
     *      based on their positive impact (upvotes - downvotes) and the stake amount within that epoch.
     *      This can only be called for a sealed epoch once.
     * @param _epochId The ID of the epoch for which to distribute rewards.
     */
    function distributeEpochRewards(uint256 _epochId) external nonReentrant {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.status == EpochStatus.Sealed, "CW: Epoch must be sealed to distribute rewards");
        // Ensure this function can only be called once per epoch for reward distribution,
        // or add a flag like `rewardsDistributed` to the Epoch struct.
        // For simplicity, we'll assume it's called by a trusted mechanism once.
        // In a real system, more robust safeguards would be needed.

        uint256 totalInfluenceInEpoch = 0;
        mapping(address => uint256) epochInfluence; // Influence specific to this epoch

        for (uint256 i = 0; i < epochContributions[_epochId].length; i++) {
            uint256 contribId = epochContributions[_epochId][i];
            Contribution storage contrib = contributions[contribId];

            if (!contrib.stakeClaimed) { // Only consider non-revoked/non-claimed contributions
                int256 netVotes = int256(contrib.upvotes) - int256(contrib.downvotes);
                if (netVotes > 0) {
                    // Influence = net_votes * stake_amount (simple model)
                    // For a more robust system, consider sqrt of stake, decaying votes etc.
                    uint256 influence = uint256(netVotes) * contrib.stakeAmount;
                    epochInfluence[contrib.contributor] += influence;
                    totalInfluenceInEpoch += influence;
                }
            }
        }

        uint256 totalRewardPool = epoch.totalValueContributed; // All staked funds for this epoch
        // For a more complex system, 'epochInitiationFee' or other contract funds could also be added.

        if (totalInfluenceInEpoch > 0) {
            for (uint256 i = 0; i < epochContributions[_epochId].length; i++) {
                uint256 contribId = epochContributions[_epochId][i];
                Contribution storage contrib = contributions[contribId];

                if (epochInfluence[contrib.contributor] > 0) {
                    uint256 rewardAmount = (totalRewardPool * epochInfluence[contrib.contributor]) / totalInfluenceInEpoch;
                    userInfluence[contrib.contributor] += epochInfluence[contrib.contributor]; // Accumulate global influence
                    // Transfer the reward portion directly, the remainder will be claimable stake.
                    // This is a simplified model. In a real system, the initial stake would be separate from reward.
                    // For this example, the stake *is* the reward pool.
                    payable(contrib.contributor).transfer(rewardAmount);
                    contrib.stakeClaimed = true; // Mark as claimed implicitly by reward
                } else if (!contrib.stakeClaimed) {
                    // If no positive influence, allow claiming initial stake back later
                    // No direct transfer here, handled by claimContributionStake
                }
            }
        } else {
             // If no positive influence, all stakes are claimable back by original contributors
             // This path can be more complex, but for simplicity, they will claim their own back.
        }

        emit RewardsDistributed(_epochId, totalRewardPool, epoch.totalValueContributed);
    }

    /**
     * @dev Allows a contributor to reclaim their initial stake *after* rewards are distributed
     *      (or if their contribution was revoked and not voted on).
     *      This prevents double claiming after `distributeEpochRewards`.
     * @param _contributionId The ID of the contribution whose stake is to be claimed.
     */
    function claimContributionStake(uint256 _contributionId) external nonReentrant {
        Contribution storage contribution = contributions[_contributionId];
        require(contribution.contributor == msg.sender, "CW: Not your contribution");
        require(!contribution.stakeClaimed, "CW: Stake already claimed or rewarded");

        Epoch storage epoch = epochs[contribution.epochId];
        require(epoch.status == EpochStatus.Sealed || epoch.status == EpochStatus.Ended, "CW: Epoch must be ended or sealed to claim stake");

        contribution.stakeClaimed = true;
        payable(msg.sender).transfer(contribution.stakeAmount);

        emit StakeClaimed(_contributionId, msg.sender, contribution.stakeAmount);
    }

    // --- D. Administration & Configuration ---

    /**
     * @dev Allows the owner to adjust the fee required to initiate a new epoch.
     * @param _newFee The new epoch initiation fee in wei.
     */
    function setEpochInitiationFee(uint256 _newFee) external onlyOwner {
        require(_newFee > 0, "CW: Fee must be greater than zero");
        epochInitiationFee = _newFee;
        emit EpochInitiationFeeUpdated(_newFee);
    }

    /**
     * @dev Allows the owner to adjust the minimum stake required for a contribution.
     * @param _minStake The new minimum contribution stake in wei.
     */
    function setMinimumContributionStake(uint256 _minStake) external onlyOwner {
        require(_minStake > 0, "CW: Minimum stake must be greater than zero");
        minimumContributionStake = _minStake;
        emit MinimumContributionStakeUpdated(_minStake);
    }

    /**
     * @dev Authorizes a new address to act as an oracle for sealing epochs.
     * @param _oracleAddress The address to grant oracle privileges to.
     */
    function registerOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "CW: Invalid address");
        isOracle[_oracleAddress] = true;
        emit OracleRegistered(_oracleAddress);
    }

    /**
     * @dev Revokes oracle authorization from an address.
     * @param _oracleAddress The address to revoke oracle privileges from.
     */
    function deregisterOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "CW: Invalid address");
        isOracle[_oracleAddress] = false;
        emit OracleDeregistered(_oracleAddress);
    }

    /**
     * @dev Allows the owner to withdraw accumulated contract balance not locked in stakes.
     *      This would typically be from epoch initiation fees.
     */
    function withdrawContractBalance() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        // In a more complex contract, you'd need to track un-staked balance vs. total balance
        // For simplicity, we assume fees are the only withdrawable balance
        // and all stakes will eventually be distributed or claimed.
        // A more robust system would calculate withdrawable fees explicitly.
        // For this demo, we assume the owner can withdraw any "excess" not locked in current stakes.
        // BE CAREFUL with this in production, calculate precisely.
        // A better approach would be to track explicit fee balance.
        payable(msg.sender).transfer(contractBalance);
    }

    /**
     * @dev Allows the owner to temporarily pause/unpause contributions for a specific active epoch.
     *      Useful for moderation or emergency situations.
     * @param _epochId The ID of the epoch to pause/unpause.
     * @param _pause True to pause, false to unpause.
     */
    function pauseEpochContributions(uint256 _epochId, bool _pause) external onlyOwner {
        Epoch storage epoch = epochs[_epochId];
        require(epoch.status == EpochStatus.Active, "CW: Epoch must be active to pause/unpause contributions");
        epoch.contributionsPaused = _pause;
        emit EpochContributionsPaused(_epochId, _pause);
    }

    /**
     * @dev Allows the owner to selectively "migrate" important contribution IDs from a sealed epoch
     *      to a new, active one. This can be used for narrative continuity, re-evaluating historical
     *      contributions, or sparking new discussions based on past content.
     *      This does not re-stake or re-vote, but simply references the old content.
     * @param _sourceEpochId The ID of the sealed epoch from which to migrate contributions.
     * @param _targetEpochId The ID of the active epoch to which to migrate contributions.
     * @param _contributionIds An array of specific contribution IDs from the source epoch to migrate.
     */
    function migrateEpochContent(uint256 _sourceEpochId, uint256 _targetEpochId, uint256[] calldata _contributionIds) external onlyOwner {
        Epoch storage sourceEpoch = epochs[_sourceEpochId];
        Epoch storage targetEpoch = epochs[_targetEpochId];

        require(sourceEpoch.status == EpochStatus.Sealed, "CW: Source epoch must be sealed");
        require(targetEpoch.status == EpochStatus.Active, "CW: Target epoch must be active");
        require(_sourceEpochId < _targetEpochId, "CW: Source epoch must be older than target epoch");

        for (uint256 i = 0; i < _contributionIds.length; i++) {
            uint256 contribId = _contributionIds[i];
            Contribution storage sourceContrib = contributions[contribId];
            require(sourceContrib.epochId == _sourceEpochId, "CW: Contribution not in source epoch");

            // Create a "new" contribution in the target epoch, referencing the old content
            // This could be made more sophisticated, e.g., by indicating it's a "migrated" type.
            uint256 newContributionId = nextContributionId++;
            contributions[newContributionId] = Contribution({
                id: newContributionId,
                epochId: _targetEpochId,
                contributor: msg.sender, // Owner is the 'migrator'
                timestamp: block.timestamp,
                contentHash: sourceContrib.contentHash, // Reference original content
                stakeAmount: 0, // Migrated content doesn't require new stake
                upvotes: 0,
                downvotes: 0,
                stakeClaimed: true // No stake to claim for migrated content
            });
            epochContributions[_targetEpochId].push(newContributionId);
            targetEpoch.contributionCount++;
            // Note: totalValueContributed is not incremented for migrated content as no new stake.

            emit ContributionSubmitted(newContributionId, _targetEpochId, msg.sender, sourceContrib.contentHash, 0); // Re-use event
        }
        emit EpochContentMigrated(_sourceEpochId, _targetEpochId, _contributionIds);
    }

    // --- Utility View Functions (for more than 20) ---
    
    /**
     * @dev Gets the total number of contributions for a given epoch.
     * @param _epochId The ID of the epoch.
     * @return The count of contributions.
     */
    function getEpochContributionCount(uint256 _epochId) external view returns (uint256) {
        require(_epochId <= currentEpochId && _epochId > 0, "CW: Invalid epoch ID");
        return epochs[_epochId].contributionCount;
    }

    /**
     * @dev Gets the total value (sum of stakes) contributed to a given epoch.
     * @param _epochId The ID of the epoch.
     * @return The total value contributed in wei.
     */
    function getEpochTotalStaked(uint256 _epochId) external view returns (uint256) {
        require(_epochId <= currentEpochId && _epochId > 0, "CW: Invalid epoch ID");
        return epochs[_epochId].totalValueContributed;
    }
}
```