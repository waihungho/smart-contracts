Okay, let's design a smart contract centered around a "Reputation-Weighted Idea Curation" system. Users earn reputation within the system, stake that reputation on proposed ideas, and reputation is redistributed based on the ideas' outcomes and the stakers' predictions (implied by their stake). It incorporates concepts like internal tokens (reputation points), staking, time-based states, and outcome-based incentives without being a standard ERC-20, NFT, or complex DeFi/DAO clone.

We will aim for over 20 functions covering reputation, idea lifecycle, staking, parameters, and views.

---

**Smart Contract Outline and Function Summary**

*   **Contract Name:** `ReputationCurator`
*   **Purpose:** A decentralized platform for proposing and curating ideas based on reputation. Users earn and stake reputation on ideas, and successful outcomes lead to reputation rewards for participants, while failed outcomes incur penalties.
*   **Core Concepts:**
    *   **Reputation:** An internal, non-transferable score representing a user's influence and accuracy within the system.
    *   **Ideas:** Proposals put forward by users, requiring a reputation stake to initiate.
    *   **Staking:** Users stake their reputation on active ideas, acting as a vote of confidence or prediction of success.
    *   **Lifecycle:** Ideas progress through states (Proposed, Voting, Active, CompletedSuccess, CompletedFailure).
    *   **Finalization:** An external process (simulated here by an owner call for simplicity, but could be an oracle or trusted party in a real system) determines the idea's outcome.
    *   **Incentives:** Reputation is rewarded for successful ideas (especially the proposer) and returned (or partially penalized) for stakers based on the outcome.

*   **Key Data Structures:**
    *   `IdeaState` (enum): Represents the current phase of an idea.
    *   `Idea` (struct): Stores details about a proposed idea, including proposer, state, timestamps, stake amounts.
    *   `reputation`: Mapping of user addresses to their current reputation score.
    *   `ideaStakes`: Mapping storing how much reputation each user has staked on a specific idea.
    *   Parameters: Configurable values like minimum stake, voting duration, reward/penalty multipliers.

*   **Function Summary:**

    **Reputation Management:**
    1.  `getReputation(address user)`: View a user's current reputation.
    2.  `claimInitialReputation()`: Allows a new user to claim a starting amount of reputation (limited).
    3.  `_mintReputation(address user, uint256 amount)`: Internal function to increase reputation.
    4.  `_burnReputation(address user, uint256 amount)`: Internal function to decrease reputation.
    5.  `getAvailableReputation(address user)`: View reputation not currently staked on active ideas.

    **Idea Lifecycle & Proposal:**
    6.  `proposeIdea(string memory description, uint256 stakeAmount)`: Propose a new idea, requires reputation stake.
    7.  `getIdea(uint256 ideaId)`: View details of a specific idea.
    8.  `getIdeaState(uint256 ideaId)`: View the current state of an idea.
    9.  `updateIdeaDescription(uint256 ideaId, string memory newDescription)`: Update idea description before voting starts (proposer only).
    10. `startVotingPeriod(uint256 ideaId)`: (Owner only) Transitions idea from Proposed to Voting.
    11. `endVotingPeriod(uint256 ideaId)`: Callable by anyone after the voting duration ends. Transitions idea from Voting to Active.
    12. `finalizeIdea(uint256 ideaId, bool outcome)`: Callable by anyone after the active period ends (or voting ends if no active period), determines outcome (Success/Failure) and triggers initial reputation adjustments.

    **Staking & Unstaking:**
    13. `stakeOnIdea(uint256 ideaId, uint256 amount)`: Stake reputation on an idea during Proposed/Voting phase.
    14. `getTotalStakedOnIdea(uint256 ideaId)`: View total reputation staked on an idea.
    15. `getUserStakeOnIdea(uint256 ideaId, address user)`: View a user's stake amount on an idea.
    16. `unstakeProposerStake(uint256 ideaId)`: Proposer claims back/adjusts their initial stake after finalization.
    17. `unstakeStakerStake(uint256 ideaId)`: Stakers claim back/adjust their stake after finalization.

    **Parameter Management (Owner Only):**
    18. `setMinStakeAmount(uint256 amount)`: Set minimum reputation required to propose/stake.
    19. `setVotingPeriodDuration(uint256 duration)`: Set the duration of the voting phase.
    20. `setInitialReputationAmount(uint256 amount)`: Set the amount for `claimInitialReputation`.
    21. `setReputationRewardMultiplier(uint256 multiplier)`: Set the reward multiplier (e.g., 1000 = 1x, 1500 = 1.5x).
    22. `setReputationPenaltyMultiplier(uint256 multiplier)`: Set the penalty multiplier (e.g., 1000 = 100% loss, 500 = 50% loss).
    23. `transferOwnership(address newOwner)`: Transfer contract ownership.

    **View Functions (Parameters & Totals):**
    24. `getMinStakeAmount()`: View min stake parameter.
    25. `getVotingPeriodDuration()`: View voting duration parameter.
    26. `getInitialReputationAmount()`: View initial reputation parameter.
    27. `getReputationRewardMultiplier()`: View reward multiplier parameter.
    28. `getReputationPenaltyMultiplier()`: View penalty multiplier parameter.
    29. `getOwner()`: View contract owner.
    30. `getTotalIdeas()`: View the total number of ideas proposed.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Note: Using SafeMath explicitly for clarity, though Solidity 0.8+ has default overflow checks.

/**
 * @title ReputationCurator
 * @dev A smart contract for a reputation-weighted idea curation and incubation system.
 * Users propose ideas by staking reputation, stake on existing ideas to signal confidence,
 * and earn/lose reputation based on idea outcomes.
 */
contract ReputationCurator is Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    // Reputation mapping: user address => reputation score
    mapping(address => uint256) private _reputation;

    // Keep track of staked reputation for each user across all ideas
    // This allows calculating available reputation easily: total - staked
    mapping(address => uint256) private _totalStakedReputationByUser;

    // Counter for unique idea IDs
    Counters.Counter private _ideaIds;

    // Idea states
    enum IdeaState {
        Proposed,           // Idea is proposed, open for initial staking/voting
        Voting,             // Official voting/staking period is active
        Active,             // Voting ended, idea is being assessed/implemented off-chain
        CompletedSuccess,   // Idea was successful, reputation rewards/returns apply
        CompletedFailure    // Idea failed, reputation penalties apply
    }

    // Idea structure
    struct Idea {
        address proposer;              // The address that proposed the idea
        string description;            // Short description of the idea
        IdeaState state;               // Current state of the idea
        uint64 creationTime;           // Timestamp of creation
        uint64 votingStartTime;        // Timestamp voting starts (0 if not started)
        uint64 votingEndTime;          // Timestamp voting ends (0 if not started)
        uint256 proposerStake;         // Amount of reputation initially staked by the proposer
        uint256 totalStakedReputation; // Total reputation staked by all users (including proposer)
        bool proposerStakeClaimed;     // Flag to prevent double claiming/burning of proposer stake
    }

    // Mapping: Idea ID => Idea details
    mapping(uint256 => Idea) public ideas;

    // Mapping: Idea ID => Staker Address => Amount Staked
    mapping(uint256 => mapping(address => uint256)) private _ideaStakes;

    // Parameters governing the system (owner-configurable)
    uint256 private _minStakeAmount;             // Minimum reputation needed to propose or stake
    uint64 private _votingPeriodDuration;       // Duration of the voting phase in seconds
    uint256 private _initialReputationAmount;    // Amount of reputation new users can claim
    uint256 private _reputationRewardMultiplier; // Multiplier for rewards (e.g., 1000 = 1x)
    uint256 private _reputationPenaltyMultiplier; // Multiplier for penalties (e.g., 1000 = 100% loss, 500 = 50% loss)

    // Mapping to track if a user has claimed initial reputation
    mapping(address => bool) private _initialReputationClaimed;

    // --- Events ---

    event ReputationMinted(address indexed user, uint256 amount);
    event ReputationBurned(address indexed user, uint256 amount);
    event IdeaProposed(uint256 indexed ideaId, address indexed proposer, uint256 stakeAmount, string description);
    event ReputationStaked(uint256 indexed ideaId, address indexed staker, uint256 amount);
    event VotingPeriodStarted(uint256 indexed ideaId, uint64 startTime, uint64 endTime);
    event VotingPeriodEnded(uint256 indexed ideaId);
    event IdeaFinalized(uint256 indexed ideaId, bool outcome);
    event ReputationUnstaked(uint256 indexed ideaId, address indexed user, uint256 amountReturned);
    event ProposerStakeUnstaked(uint256 indexed ideaId, address indexed proposer, uint256 amountReturned);

    // Parameter Update Events
    event MinStakeAmountUpdated(uint256 newAmount);
    event VotingPeriodDurationUpdated(uint64 newDuration);
    event InitialReputationAmountUpdated(uint256 newAmount);
    event ReputationRewardMultiplierUpdated(uint256 newMultiplier);
    event ReputationPenaltyMultiplierUpdated(uint256 newMultiplier);

    // --- Constructor ---

    constructor(
        uint256 minStake,
        uint64 votingDuration,
        uint256 initialReputation,
        uint256 rewardMultiplier,
        uint256 penaltyMultiplier
    ) {
        require(rewardMultiplier <= 2000, "Reward multiplier too high"); // Limit reward multiplier for safety
        require(penaltyMultiplier <= 1000, "Penalty multiplier cannot exceed 100%"); // 1000 means 100% loss
        _minStakeAmount = minStake;
        _votingPeriodDuration = votingDuration;
        _initialReputationAmount = initialReputation;
        _reputationRewardMultiplier = rewardMultiplier; // e.g., 1000 for 1x, 1500 for 1.5x
        _reputationPenaltyMultiplier = penaltyMultiplier; // e.g., 1000 for 100% loss, 500 for 50% loss
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Mints reputation for a user. Internal only.
     */
    function _mintReputation(address user, uint256 amount) internal {
        if (amount > 0) {
            _reputation[user] = _reputation[user].add(amount);
            emit ReputationMinted(user, amount);
        }
    }

    /**
     * @dev Burns reputation from a user. Internal only.
     * @param user The user's address.
     * @param amount The amount of reputation to burn.
     */
    function _burnReputation(address user, uint256 amount) internal {
        if (amount > 0) {
            require(_reputation[user] >= amount, "Insufficient reputation to burn");
            _reputation[user] = _reputation[user].sub(amount);
            emit ReputationBurned(user, amount);
        }
    }

    // --- Reputation Management Functions ---

    /**
     * @dev Gets the total reputation balance of a user.
     * @param user The address of the user.
     * @return The total reputation score.
     */
    function getReputation(address user) public view returns (uint256) {
        return _reputation[user];
    }

    /**
     * @dev Allows a new user to claim an initial amount of reputation once.
     */
    function claimInitialReputation() public {
        require(!_initialReputationClaimed[msg.sender], "Initial reputation already claimed");
        require(_initialReputationAmount > 0, "Initial reputation amount is zero");
        _initialReputationClaimed[msg.sender] = true;
        _mintReputation(msg.sender, _initialReputationAmount);
    }

    /**
     * @dev Gets the available reputation balance of a user (total minus staked).
     * @param user The address of the user.
     * @return The available reputation score.
     */
    function getAvailableReputation(address user) public view returns (uint256) {
        return _reputation[user].sub(_totalStakedReputationByUser[user]);
    }

    // --- Idea Lifecycle & Proposal Functions ---

    /**
     * @dev Proposes a new idea, requiring the proposer to stake reputation.
     * @param description The description of the idea.
     * @param stakeAmount The amount of reputation to stake on the idea.
     */
    function proposeIdea(string memory description, uint256 stakeAmount) public {
        require(bytes(description).length > 0, "Description cannot be empty");
        require(stakeAmount >= _minStakeAmount, "Stake amount below minimum");
        require(getAvailableReputation(msg.sender) >= stakeAmount, "Insufficient available reputation to stake");

        _ideaIds.increment();
        uint256 newIdeaId = _ideaIds.current();

        ideas[newIdeaId] = Idea({
            proposer: msg.sender,
            description: description,
            state: IdeaState.Proposed,
            creationTime: uint64(block.timestamp),
            votingStartTime: 0, // Not started yet
            votingEndTime: 0,   // Not started yet
            proposerStake: stakeAmount,
            totalStakedReputation: stakeAmount,
            proposerStakeClaimed: false // Proposer stake not yet claimed/processed
        });

        // Transfer reputation to the staked pool
        _totalStakedReputationByUser[msg.sender] = _totalStakedReputationByUser[msg.sender].add(stakeAmount);
        // Record proposer's stake separately for unstaking logic
        _ideaStakes[newIdeaId][msg.sender] = _ideaStakes[newIdeaId][msg.sender].add(stakeAmount);


        emit IdeaProposed(newIdeaId, msg.sender, stakeAmount, description);
    }

    /**
     * @dev Gets the details of a specific idea.
     * @param ideaId The ID of the idea.
     * @return Idea struct details.
     */
    function getIdea(uint256 ideaId) public view returns (Idea memory) {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        return ideas[ideaId];
    }

    /**
     * @dev Gets the current state of a specific idea.
     * @param ideaId The ID of the idea.
     * @return The current IdeaState.
     */
    function getIdeaState(uint256 ideaId) public view returns (IdeaState) {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        return ideas[ideaId].state;
    }

    /**
     * @dev Allows the proposer to update the idea description before the voting period starts.
     * @param ideaId The ID of the idea.
     * @param newDescription The new description for the idea.
     */
    function updateIdeaDescription(uint256 ideaId, string memory newDescription) public {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.proposer == msg.sender, "Only the proposer can update description");
        require(idea.state == IdeaState.Proposed, "Can only update description in Proposed state");
        require(bytes(newDescription).length > 0, "Description cannot be empty");

        idea.description = newDescription;
    }


    /**
     * @dev Owner transitions an idea from Proposed to Voting state.
     * This starts the official voting/staking period.
     * @param ideaId The ID of the idea.
     */
    function startVotingPeriod(uint256 ideaId) public onlyOwner {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.state == IdeaState.Proposed, "Idea must be in Proposed state");

        idea.state = IdeaState.Voting;
        idea.votingStartTime = uint64(block.timestamp);
        idea.votingEndTime = uint64(block.timestamp + _votingPeriodDuration);

        emit VotingPeriodStarted(ideaId, idea.votingStartTime, idea.votingEndTime);
    }

    /**
     * @dev Allows anyone to transition an idea out of the Voting state once the period ends.
     * Transitions to Active state.
     * @param ideaId The ID of the idea.
     */
    function endVotingPeriod(uint256 ideaId) public {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.state == IdeaState.Voting, "Idea must be in Voting state");
        require(block.timestamp >= idea.votingEndTime, "Voting period has not ended yet");

        idea.state = IdeaState.Active;

        emit VotingPeriodEnded(ideaId);
    }

    /**
     * @dev Finalizes an idea's outcome (Success/Failure).
     * Can be called by anyone after the voting period ends.
     * Handles initial reputation adjustments for the proposer based on outcome.
     * @param ideaId The ID of the idea.
     * @param outcome True for Success, False for Failure.
     */
    function finalizeIdea(uint256 ideaId, bool outcome) public {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.state == IdeaState.Active || (idea.state == IdeaState.Voting && block.timestamp >= idea.votingEndTime),
                "Idea must be in Active state or Voting state with period ended");

        // Set the final state
        if (outcome) {
            idea.state = IdeaState.CompletedSuccess;
        } else {
            idea.state = IdeaState.CompletedFailure;
        }

        // Handle proposer's reputation adjustment immediately based on outcome
        if (!idea.proposerStakeClaimed) {
            if (outcome) {
                // Proposer gets rewarded based on total staked amount
                uint256 reward = idea.totalStakedReputation.mul(_reputationRewardMultiplier).div(1000);
                _mintReputation(idea.proposer, reward);
            } else {
                // Proposer loses their initial stake
                _burnReputation(idea.proposer, idea.proposerStake);
            }
            idea.proposerStakeClaimed = true; // Mark proposer stake as processed
        }


        emit IdeaFinalized(ideaId, outcome);
    }

    // --- Staking & Unstaking Functions ---

    /**
     * @dev Stakes reputation on an idea.
     * Can only be done when the idea is in Proposed or Voting state.
     * @param ideaId The ID of the idea.
     * @param amount The amount of reputation to stake.
     */
    function stakeOnIdea(uint256 ideaId, uint256 amount) public {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.state == IdeaState.Proposed || idea.state == IdeaState.Voting, "Can only stake on ideas in Proposed or Voting state");
        require(amount >= _minStakeAmount, "Stake amount below minimum");
        require(getAvailableReputation(msg.sender) >= amount, "Insufficient available reputation to stake");

        // Record the stake
        _ideaStakes[ideaId][msg.sender] = _ideaStakes[ideaId][msg.sender].add(amount);
        // Update total staked amounts
        _totalStakedReputationByUser[msg.sender] = _totalStakedReputationByUser[msg.sender].add(amount);
        idea.totalStakedReputation = idea.totalStakedReputation.add(amount);

        emit ReputationStaked(ideaId, msg.sender, amount);
    }

    /**
     * @dev Gets the total reputation staked on a specific idea.
     * @param ideaId The ID of the idea.
     * @return The total staked reputation amount.
     */
    function getTotalStakedOnIdea(uint256 ideaId) public view returns (uint256) {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        return ideas[ideaId].totalStakedReputation;
    }

    /**
     * @dev Gets the amount of reputation a user has staked on a specific idea.
     * @param ideaId The ID of the idea.
     * @param user The address of the staker.
     * @return The amount of reputation staked by the user on the idea.
     */
    function getUserStakeOnIdea(uint256 ideaId, address user) public view returns (uint256) {
         require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        return _ideaStakes[ideaId][user];
    }

    /**
     * @dev Allows the proposer to claim back their initial stake or confirms its burning.
     * Can only be called after the idea has been finalized.
     * Handles the proposer's initial stake based on the final outcome.
     * The proposer's reward (if any) is handled in finalizeIdea.
     * This function handles the return of the initial `proposerStake` only.
     * @param ideaId The ID of the idea.
     */
    function unstakeProposerStake(uint256 ideaId) public {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.proposer == msg.sender, "Only the proposer can call this function");
        require(idea.state == IdeaState.CompletedSuccess || idea.state == IdeaState.CompletedFailure,
                "Idea must be in a completed state");
        require(idea.proposerStake > 0, "Proposer did not stake on this idea, or stake already processed");
        // Note: proposerStakeClaimed flag is set in finalizeIdea to prevent double processing of the *reward/burn*,
        // but the actual return of the initial stake needs a separate mechanism/flag here if we didn't zero out idea.proposerStake

        // Check if this specific proposer stake has been unstaked already
        uint256 stakeAmount = idea.proposerStake;
        // To prevent double claim, we can zero out the proposerStake *after* this function.
        // However, finalizeIdea already handles the burn on failure or rewards on success.
        // Let's rethink: finalizeIdea handles the *consequence* (reward/burn BEYOND the initial stake for success,
        // or BURNING the initial stake on failure). Unstaking should JUST return the original stake
        // on success, and return nothing on failure (because it was burned).
        // The idea.proposerStakeClaimed flag ensures the reward/burn logic in finalizeIdea runs once.
        // We need a separate way to track if the *original stake* has been returned.

        // Let's use the _ideaStakes mapping entry for the proposer as the source of truth
        // for whether the *initial stake* has been returned.
        uint256 currentProposerStake = _ideaStakes[ideaId][msg.sender];
        require(currentProposerStake > 0, "Proposer stake already unstaked");

        uint256 amountToReturn = 0;

        if (idea.state == IdeaState.CompletedSuccess) {
             // On success, proposer gets their original stake back
            amountToReturn = currentProposerStake;
            _mintReputation(msg.sender, amountToReturn);
        }
        // On failure, the initial stake was burned in finalizeIdea, so amountToReturn is 0

        // Remove stake from tracking mappings
        _ideaStakes[ideaId][msg.sender] = 0;
        _totalStakedReputationByUser[msg.sender] = _totalStakedReputationByUser[msg.sender].sub(currentProposerStake);
        idea.totalStakedReputation = idea.totalStakedReputation.sub(currentProposerStake);

        emit ProposerStakeUnstaked(ideaId, msg.sender, amountToReturn);
    }


    /**
     * @dev Allows a staker (other than the proposer, or proposer claiming non-initial stakes)
     * to claim back their stake after the idea has been finalized.
     * Reputation is returned/penalized based on the outcome.
     * @param ideaId The ID of the idea.
     */
    function unstakeStakerStake(uint256 ideaId) public {
         require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        Idea storage idea = ideas[ideaId];
        require(idea.state == IdeaState.CompletedSuccess || idea.state == IdeaState.CompletedFailure,
                "Idea must be in a completed state");

        uint256 stakedAmount = _ideaStakes[ideaId][msg.sender];
        require(stakedAmount > 0, "No stake found for this user on this idea");

        uint256 amountToReturn = 0;

        if (idea.state == IdeaState.CompletedSuccess) {
            // On success, staker gets their full staked amount back
            amountToReturn = stakedAmount;
            _mintReputation(msg.sender, amountToReturn);

        } else if (idea.state == IdeaState.CompletedFailure) {
            // On failure, staker loses a percentage of their stake
            amountToReturn = stakedAmount.mul(1000 - _reputationPenaltyMultiplier).div(1000);
             if (amountToReturn > 0) {
                 _mintReputation(msg.sender, amountToReturn);
             }
            // The amount not returned is effectively burned by not being minted back
        }

        // Remove stake from tracking mappings
        _ideaStakes[ideaId][msg.sender] = 0;
        _totalStakedReputationByUser[msg.sender] = _totalStakedReputationByUser[msg.sender].sub(stakedAmount);
        idea.totalStakedReputation = idea.totalStakedReputation.sub(stakedAmount); // Total staked goes down regardless of outcome

        emit ReputationUnstaked(ideaId, msg.sender, amountToReturn);
    }

    // --- Parameter Management Functions (Owner Only) ---

    /**
     * @dev Sets the minimum reputation required to propose or stake on an idea.
     * @param amount The new minimum stake amount.
     */
    function setMinStakeAmount(uint256 amount) public onlyOwner {
        require(amount > 0, "Minimum stake must be greater than zero");
        _minStakeAmount = amount;
        emit MinStakeAmountUpdated(amount);
    }

    /**
     * @dev Sets the duration of the voting period in seconds.
     * @param duration The new voting period duration.
     */
    function setVotingPeriodDuration(uint64 duration) public onlyOwner {
        require(duration > 0, "Voting duration must be greater than zero");
        _votingPeriodDuration = duration;
        emit VotingPeriodDurationUpdated(duration);
    }

    /**
     * @dev Sets the amount of initial reputation claimable by new users.
     * @param amount The new initial reputation amount.
     */
    function setInitialReputationAmount(uint256 amount) public onlyOwner {
        _initialReputationAmount = amount;
        emit InitialReputationAmountUpdated(amount);
    }

    /**
     * @dev Sets the multiplier for reputation rewards on successful ideas.
     * Multiplier is in parts per 1000 (e.g., 1000 = 1x, 1500 = 1.5x).
     * @param multiplier The new reward multiplier (<= 2000).
     */
    function setReputationRewardMultiplier(uint256 multiplier) public onlyOwner {
        require(multiplier <= 2000, "Reward multiplier too high (max 2000)");
        _reputationRewardMultiplier = multiplier;
        emit ReputationRewardMultiplierUpdated(multiplier);
    }

    /**
     * @dev Sets the multiplier for reputation penalties on failed ideas.
     * Multiplier is in parts per 1000 (e.g., 1000 = 100% loss, 500 = 50% loss).
     * @param multiplier The new penalty multiplier (<= 1000).
     */
    function setReputationPenaltyMultiplier(uint256 multiplier) public onlyOwner {
        require(multiplier <= 1000, "Penalty multiplier cannot exceed 100% (max 1000)");
        _reputationPenaltyMultiplier = multiplier;
        emit ReputationPenaltyMultiplierUpdated(multiplier);
    }

    // --- View Functions (Parameters & Totals) ---

    /**
     * @dev Gets the current minimum stake amount parameter.
     * @return The minimum stake amount.
     */
    function getMinStakeAmount() public view returns (uint256) {
        return _minStakeAmount;
    }

    /**
     * @dev Gets the current voting period duration parameter.
     * @return The voting period duration in seconds.
     */
    function getVotingPeriodDuration() public view returns (uint64) {
        return _votingPeriodDuration;
    }

    /**
     * @dev Gets the current initial reputation amount parameter.
     * @return The initial reputation amount.
     */
    function getInitialReputationAmount() public view returns (uint256) {
        return _initialReputationAmount;
    }

    /**
     * @dev Gets the current reputation reward multiplier parameter.
     * @return The reputation reward multiplier.
     */
    function getReputationRewardMultiplier() public view returns (uint256) {
        return _reputationRewardMultiplier;
    }

    /**
     * @dev Gets the current reputation penalty multiplier parameter.
     * @return The reputation penalty multiplier.
     */
    function getReputationPenaltyMultiplier() public view returns (uint256) {
        return _reputationPenaltyMultiplier;
    }

    /**
     * @dev Gets the current owner of the contract. (Inherited from Ownable)
     * @return The owner address.
     */
    function getOwner() public view returns (address) {
        return owner(); // Provided by Ownable
    }

    /**
     * @dev Gets the total number of ideas proposed.
     * @return The total count of ideas.
     */
    function getTotalIdeas() public view returns (uint256) {
        return _ideaIds.current();
    }

     /**
     * @dev Gets the reputation amount initially staked by the proposer on an idea.
     * @param ideaId The ID of the idea.
     * @return The proposer's initial stake amount.
     */
    function getProposerStake(uint256 ideaId) public view returns (uint256) {
        require(ideaId > 0 && ideaId <= _ideaIds.current(), "Invalid idea ID");
        return ideas[ideaId].proposerStake;
    }

    // Fallback and Receive functions (optional, good practice)
    receive() external payable {
        // Reject direct Ether transfers
        revert("Cannot receive Ether directly");
    }

    fallback() external payable {
         // Reject calls to undefined functions with Ether
        revert("Cannot receive Ether or call undefined function");
    }
}
```