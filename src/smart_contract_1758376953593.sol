```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline and Function Summary:
//
// ChronoForge: An Adaptive Collective Intelligence Protocol
// This contract facilitates a decentralized, community-driven evolution of an abstract digital entity.
// Users contribute "Chronos" (native currency stake) to influence the entity's traits,
// propose evolutionary paths, and predict outcomes. Successful participation builds reputation
// and earns "Essence" (liquid reward token, convertible to native currency).
// The entity also has an internal "entropy" mechanism, causing self-evolution over time.
//
// I. Core Entity & Chronos Management (Functions: 1-7)
//    - Manages user deposits/withdrawals of Chronos (native token).
//    - Provides views for the entity's current traits and user Chronos balances.
//    - `triggerForgeSync` is the core heartbeat for epoch advancement and processing.
//
// II. Prediction & Influence System (Functions: 8-13)
//    - Allows users to propose specific changes (evolutionary paths) to the entity's traits.
//    - Users stake their Chronos on these proposals to show support/prediction.
//    - Rewards for accurate predictions are distributed as Essence.
//
// III. Reputation & Essence Rewards (Functions: 14-16)
//    - Tracks user reputation based on successful contributions and predictions.
//    - Essence is the reward token earned by users, convertible to native currency.
//
// IV. Governance & Parameterization (Functions: 17-21)
//    - Enables Chronos holders to propose and vote on key system parameters.
//    - A mechanism to execute successfully voted parameter changes.
//
// V. Administrative & Oracle-like Functions (Functions: 22-24)
//    - Functions for the owner/keepers to advance the forge state and inject external data.
//    - Adjustment of key system parameters like reputation decay.
//
// Function Summary:
// 1.  `constructor()`: Initializes the contract with an owner and initial forge parameters.
// 2.  `depositChronos(uint256 amount)`: User deposits native currency, increasing their Chronos score/stake.
// 3.  `withdrawStakedChronos(uint256 amount)`: User withdraws native currency, decreasing Chronos score/stake.
// 4.  `getEntityTrait(bytes32 traitKey)`: View a specific trait of the evolving entity.
// 5.  `getAllEntityTraits()`: View all current traits of the evolving entity.
// 6.  `getUserChronos(address user)`: View a user's active Chronos balance (stake/power).
// 7.  `getCurrentEpoch()`: View the current evolutionary epoch of the Forge.
// 8.  `proposeEvolutionPath(bytes32 traitKey, bytes32 proposedValue, string memory description)`: Users submit a proposal for how a specific entity trait should evolve.
// 9.  `stakeOnPath(uint256 proposalId, uint256 amount)`: Users stake their Chronos on a specific evolution proposal to back it.
// 10. `unstakeFromPath(uint256 proposalId, uint256 amount)`: Users can retrieve their Chronos from a proposal before it's evaluated.
// 11. `getProposalDetails(uint256 proposalId)`: View details of an active evolution proposal.
// 12. `getProposalStake(uint256 proposalId, address user)`: View a user's Chronos stake on a specific proposal.
// 13. `claimPredictionRewards(uint256[] memory successfulProposalIds)`: Users claim Essence rewards for accurately predicting successful evolution paths.
// 14. `getUserReputation(address user)`: View a user's global reputation score within the Forge.
// 15. `getEssenceBalance(address user)`: View a user's Essence token balance.
// 16. `withdrawEssence(uint256 amount)`: Users withdraw their Essence, converting it to native currency from the contract's balance.
// 17. `proposeForgeParameterChange(bytes32 paramKey, uint256 newValue, string memory description)`: Users with sufficient Chronos can propose changes to system parameters.
// 18. `voteOnParameterChange(uint256 proposalId, bool approve)`: Users vote on governance proposals using their Chronos power.
// 19. `getGovernanceProposalDetails(uint256 proposalId)`: View details of a governance proposal.
// 20. `executeForgeParameterChange(uint256 proposalId)`: The owner executes a successfully voted-on governance proposal.
// 21. `getForgeParameters()`: View all current configurable parameters of the Forge.
// 22. `triggerForgeSync()`: (Owner/Keeper) The core function to advance the Forge's epoch, process evolution proposals, apply entropy, and distribute rewards.
// 23. `submitExternalInfluence(bytes32 dataKey, uint256 dataValue)`: (Owner/Keeper - simulated oracle) Allows external data to influence entity evolution.
// 24. `updateReputationDecayRate(uint256 rate)`: (Owner) Adjusts the global rate at which user reputation naturally decays over time.

contract ChronoForge {
    address public immutable owner;

    // --- Enums ---
    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed }

    // --- Structs ---

    struct ForgeParameters {
        uint256 epochDuration;          // Duration of one epoch in seconds
        uint256 evolutionProposalDuration; // Duration for proposals to be active in seconds
        uint256 minChronosForProposal;  // Minimum Chronos to submit an evolution proposal
        uint256 minChronosForGovProposal; // Minimum Chronos to submit a governance proposal
        uint256 minChronosForGovVote;   // Minimum Chronos to vote on governance
        uint256 govVotingPeriod;        // Duration for governance voting in seconds
        uint256 predictionRewardMultiplier; // Multiplier for Essence rewards for correct predictions (e.g., 200 for 2x)
        uint256 epochRewardPoolFraction; // Fraction of Chronos pool released as epoch rewards (scaled by 10000)
        uint256 reputationDecayRate;    // Percentage decay per epoch (e.g., 50 = 0.5%)
        uint256 entityEntropyFactor;    // How much random self-evolution occurs (scaled by 100, e.g., 5 = 0.05% chance / intensity)
    }

    struct EntityTrait {
        bytes32 value; // The current value of the trait
        uint256 lastUpdatedEpoch; // When this trait was last updated
        string description; // Description of the trait
    }

    struct EvolutionProposal {
        uint256 id;
        address proposer;
        bytes32 traitKey;         // Key of the trait being proposed to change
        bytes32 proposedValue;    // The new value for the trait
        string description;       // Description of the proposed change
        uint256 creationTime;     // Timestamp when proposal was created
        uint256 endTime;          // Timestamp when proposal evaluation ends
        uint256 totalChronosStaked; // Total Chronos staked on this proposal
        mapping(address => uint256) stakers; // Chronos staked by each user
        ProposalStatus status;
        bool evaluated;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        bytes32 paramKey;        // Key of the parameter to change
        uint256 newValue;        // The new value for the parameter
        string description;      // Description of the governance proposal
        uint256 creationTime;    // Timestamp when proposal was created
        uint256 votingEndTime;   // Timestamp when voting ends
        uint256 votesFor;        // Total Chronos voted FOR
        uint256 votesAgainst;    // Total Chronos voted AGAINST
        mapping(address => bool) hasVoted; // Check if user has voted
        ProposalStatus status;
    }

    struct UserStats {
        uint256 reputation;       // Global reputation score
        uint256 lastReputationUpdate; // Timestamp of last reputation update
    }

    // --- State Variables ---

    ForgeParameters public forgeParameters;
    uint256 public currentEpoch;
    uint256 public lastForgeSyncTime;
    uint256 public totalChronosStaked; // Total native currency logically staked in the contract by users
    uint256 public totalEssenceSupply; // Total Essence minted

    mapping(bytes32 => EntityTrait) public entityTraits; // The evolving entity's state
    mapping(address => uint256) public userChronosBalances; // User's active Chronos (stake)
    mapping(address => uint256) public essenceBalances;     // User's Essence reward token balance
    mapping(address => UserStats) public userStats;        // User's reputation and other stats

    uint256 public nextEvolutionProposalId;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    uint256[] public activeEvolutionProposals; // List of active proposal IDs

    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256[] public activeGovernanceProposals; // List of active governance proposal IDs


    // --- Events ---
    event ChronosDeposited(address indexed user, uint256 amount);
    event ChronosWithdrawn(address indexed user, uint256 amount);
    event EntityTraitUpdated(bytes32 indexed traitKey, bytes32 newValue, uint256 epoch);
    event EvolutionProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 traitKey, bytes32 proposedValue);
    event ChronosStakedOnPath(uint256 indexed proposalId, address indexed staker, uint256 amount);
    event ChronosUnstakedFromPath(uint256 indexed proposalId, address indexed unstaker, uint256 amount);
    event PredictionRewardsClaimed(address indexed user, uint256 amountEssence, uint256[] proposalIds);
    event EssenceWithdrawn(address indexed user, uint256 amountEssence, uint256 amountNative);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, uint256 newValue);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 chronosUsed);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event ForgeSyncTriggered(uint256 indexed newEpoch, uint256 timestamp);
    event ExternalInfluenceSubmitted(bytes32 indexed dataKey, uint256 dataValue);
    event ReputationDecayRateUpdated(uint256 newRate);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        currentEpoch = 0;
        lastForgeSyncTime = block.timestamp;
        nextEvolutionProposalId = 1;
        nextGovernanceProposalId = 1;

        // Initialize default parameters
        forgeParameters = ForgeParameters({
            epochDuration: 1 days, // 1 day
            evolutionProposalDuration: 3 days, // 3 days for evolution proposals
            minChronosForProposal: 1000, // 1000 native units
            minChronosForGovProposal: 5000, // 5000 native units
            minChronosForGovVote: 100, // 100 native units
            govVotingPeriod: 7 days, // 7 days for governance voting
            predictionRewardMultiplier: 200, // 2x multiplier (200 / 100)
            epochRewardPoolFraction: 100, // 1% of the pool as epoch rewards (100 / 10000)
            reputationDecayRate: 50, // 0.5% decay per epoch (50 / 10000)
            entityEntropyFactor: 5 // 0.05% chance of random trait change / intensity of change (5 / 10000)
        });

        // Initialize some initial entity traits (example)
        entityTraits[keccak256("energy_level")] = EntityTrait({value: keccak256("stable"), lastUpdatedEpoch: 0, description: "Current energy state"});
        entityTraits[keccak256("growth_factor")] = EntityTrait({value: keccak256("slow"), lastUpdatedEpoch: 0, description: "Rate of inherent growth"});
        entityTraits[keccak256("adaptive_capacity")] = EntityTrait({value: keccak256("moderate"), lastUpdatedEpoch: 0, description: "Ability to adapt to changes"});
    }

    // --- I. Core Entity & Chronos Management ---

    /// @notice User deposits native currency to increase their Chronos score/stake.
    /// @param amount The amount of native currency to deposit.
    function depositChronos(uint256 amount) external payable {
        require(msg.value == amount, "Sent amount must match specified amount");
        require(amount > 0, "Amount must be greater than zero");

        userChronosBalances[msg.sender] += amount;
        totalChronosStaked += amount;
        emit ChronosDeposited(msg.sender, amount);
    }

    /// @notice User withdraws native currency, decreasing their Chronos score/stake.
    /// @param amount The amount of native currency to withdraw.
    function withdrawStakedChronos(uint256 amount) external {
        require(userChronosBalances[msg.sender] >= amount, "Insufficient Chronos balance");
        require(totalChronosStaked >= amount, "Insufficient total staked Chronos in contract");
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Contract has insufficient native funds");

        userChronosBalances[msg.sender] -= amount;
        totalChronosStaked -= amount;
        payable(msg.sender).transfer(amount);
        emit ChronosWithdrawn(msg.sender, amount);
    }

    /// @notice Views a specific trait of the evolving entity.
    /// @param traitKey The keccak256 hash of the trait name.
    /// @return The trait's value, last updated epoch, and description.
    function getEntityTrait(bytes32 traitKey) external view returns (bytes32 value, uint256 lastUpdatedEpoch, string memory description) {
        EntityTrait storage trait = entityTraits[traitKey];
        return (trait.value, trait.lastUpdatedEpoch, trait.description);
    }

    /// @notice Views all current traits of the evolving entity.
    /// @dev This function iterates through a predefined list of trait keys. For a production system,
    ///      a dynamic list or pagination would be better for potentially many traits.
    /// @return An array of trait keys, values, and descriptions.
    function getAllEntityTraits() external view returns (bytes32[] memory keys, bytes32[] memory values, string[] memory descriptions) {
        bytes32[] memory allKeys = new bytes32[](3); // Example: fixed keys
        allKeys[0] = keccak256("energy_level");
        allKeys[1] = keccak256("growth_factor");
        allKeys[2] = keccak256("adaptive_capacity");

        keys = new bytes32[](allKeys.length);
        values = new bytes32[](allKeys.length);
        descriptions = new string[](allKeys.length);

        for (uint256 i = 0; i < allKeys.length; i++) {
            EntityTrait storage trait = entityTraits[allKeys[i]];
            keys[i] = allKeys[i];
            values[i] = trait.value;
            descriptions[i] = trait.description;
        }
        return (keys, values, descriptions);
    }

    /// @notice View a user's active Chronos balance (stake/power).
    /// @param user The address of the user.
    /// @return The user's Chronos balance.
    function getUserChronos(address user) external view returns (uint256) {
        return userChronosBalances[user];
    }

    /// @notice View the current evolutionary epoch of the Forge.
    /// @return The current epoch number.
    function getCurrentEpoch() external view returns (uint252) {
        return currentEpoch;
    }

    // --- II. Prediction & Influence System ---

    /// @notice Users submit a proposal for how a specific entity trait should evolve.
    /// @param traitKey The key of the trait to be changed.
    /// @param proposedValue The new value for the trait.
    /// @param description A description of the proposed change.
    /// @return The ID of the newly created proposal.
    function proposeEvolutionPath(bytes32 traitKey, bytes32 proposedValue, string memory description) external returns (uint256) {
        require(userChronosBalances[msg.sender] >= forgeParameters.minChronosForProposal, "Insufficient Chronos to propose");
        require(entityTraits[traitKey].value != 0, "Trait key does not exist");
        require(proposedValue != 0, "Proposed value cannot be empty");

        uint256 proposalId = nextEvolutionProposalId++;
        EvolutionProposal storage proposal = evolutionProposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.traitKey = traitKey;
        proposal.proposedValue = proposedValue;
        proposal.description = description;
        proposal.creationTime = block.timestamp;
        proposal.endTime = block.timestamp + forgeParameters.evolutionProposalDuration;
        proposal.status = ProposalStatus.Active;
        proposal.evaluated = false;

        activeEvolutionProposals.push(proposalId);
        emit EvolutionProposalSubmitted(proposalId, msg.sender, traitKey, proposedValue);
        return proposalId;
    }

    /// @notice Users stake their Chronos on a specific evolution proposal to back it.
    /// @param proposalId The ID of the proposal to stake on.
    /// @param amount The amount of Chronos to stake.
    function stakeOnPath(uint256 proposalId, uint256 amount) external {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active for staking");
        require(block.timestamp < proposal.endTime, "Proposal staking period has ended");
        require(userChronosBalances[msg.sender] >= amount, "Insufficient Chronos balance");
        require(amount > 0, "Amount must be greater than zero");

        proposal.stakers[msg.sender] += amount;
        proposal.totalChronosStaked += amount;
        userChronosBalances[msg.sender] -= amount; // Move Chronos from active balance to staked
        emit ChronosStakedOnPath(proposalId, msg.sender, amount);
    }

    /// @notice Users can retrieve their Chronos from a proposal before it's evaluated.
    /// @param proposalId The ID of the proposal to unstake from.
    /// @param amount The amount of Chronos to unstake.
    function unstakeFromPath(uint256 proposalId, uint256 amount) external {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active for unstaking");
        require(block.timestamp < proposal.endTime, "Proposal staking period has ended");
        require(proposal.stakers[msg.sender] >= amount, "Insufficient staked Chronos on this proposal");
        require(amount > 0, "Amount must be greater than zero");

        proposal.stakers[msg.sender] -= amount;
        proposal.totalChronosStaked -= amount;
        userChronosBalances[msg.sender] += amount; // Move Chronos back to active balance
        emit ChronosUnstakedFromPath(proposalId, msg.sender, amount);
    }

    /// @notice View details of an active evolution proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Details of the proposal.
    function getProposalDetails(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            bytes32 traitKey,
            bytes32 proposedValue,
            string memory description,
            uint256 creationTime,
            uint256 endTime,
            uint256 totalChronosStaked,
            ProposalStatus status
        )
    {
        EvolutionProposal storage proposal = evolutionProposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.traitKey,
            proposal.proposedValue,
            proposal.description,
            proposal.creationTime,
            proposal.endTime,
            proposal.totalChronosStaked,
            proposal.status
        );
    }

    /// @notice View a user's Chronos stake on a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @param user The address of the user.
    /// @return The amount of Chronos the user has staked on the proposal.
    function getProposalStake(uint256 proposalId, address user) external view returns (uint256) {
        return evolutionProposals[proposalId].stakers[user];
    }

    /// @notice Users claim Essence rewards for accurately predicting successful evolution paths.
    /// @param successfulProposalIds An array of proposal IDs that the user staked on and were successful.
    function claimPredictionRewards(uint256[] memory successfulProposalIds) external {
        uint256 totalRewardEssence = 0;
        for (uint256 i = 0; i < successfulProposalIds.length; i++) {
            uint256 proposalId = successfulProposalIds[i];
            EvolutionProposal storage proposal = evolutionProposals[proposalId];

            require(proposal.evaluated, "Proposal has not been evaluated yet");
            require(proposal.status == ProposalStatus.Approved, "Proposal was not successful");
            uint256 stakedAmount = proposal.stakers[msg.sender];
            require(stakedAmount > 0, "You did not stake on this successful proposal or already claimed");

            // Calculate reward: staked amount * reputation multiplier * predictionRewardMultiplier
            // For simplicity, reputation provides a direct bonus to the reward multiplier.
            // (10000 + reputation) / 10000 scales reputation by 100x to get % bonus
            uint256 reputationMultiplier = (10000 + (userStats[msg.sender].reputation / 100)) / 100; 
            uint256 reward = (stakedAmount * forgeParameters.predictionRewardMultiplier * reputationMultiplier) / (100 * 100); 

            essenceBalances[msg.sender] += reward;
            totalEssenceSupply += reward;
            totalRewardEssence += reward;

            // Clear user's stake on this specific proposal after claiming to prevent double claims
            proposal.stakers[msg.sender] = 0;
            // Return the Chronos back to the user's active balance for future use.
            userChronosBalances[msg.sender] += stakedAmount; 
            proposal.totalChronosStaked -= stakedAmount; // Reduce total staked on proposal
        }
        require(totalRewardEssence > 0, "No rewards to claim for provided proposals");
        emit PredictionRewardsClaimed(msg.sender, totalRewardEssence, successfulProposalIds);
    }

    // --- III. Reputation & Essence Rewards ---

    /// @notice View a user's global reputation score within the Forge.
    /// @param user The address of the user.
    /// @return The user's reputation score.
    function getUserReputation(address user) external view returns (uint256) {
        // Implement lazy decay for reputation
        uint256 currentRep = userStats[user].reputation;
        uint256 lastUpdate = userStats[user].lastReputationUpdate;

        if (currentRep > 0 && lastUpdate < block.timestamp) {
            uint256 epochsPassed = (block.timestamp - lastUpdate) / forgeParameters.epochDuration;
            if (epochsPassed > 0) {
                for (uint256 i = 0; i < epochsPassed; i++) {
                    currentRep = (currentRep * (10000 - forgeParameters.reputationDecayRate)) / 10000;
                }
            }
        }
        return currentRep;
    }

    /// @notice View a user's Essence token balance.
    /// @param user The address of the user.
    /// @return The user's Essence balance.
    function getEssenceBalance(address user) external view returns (uint256) {
        return essenceBalances[user];
    }

    /// @notice Users withdraw their Essence, converting it to native currency from the contract's balance.
    /// @param amount The amount of Essence to withdraw.
    function withdrawEssence(uint256 amount) external {
        require(essenceBalances[msg.sender] >= amount, "Insufficient Essence balance");
        require(amount > 0, "Amount must be greater than zero");

        uint256 nativeAmount;
        if (totalEssenceSupply > 0) {
            // Essence represents a claim on the underlying Chronos pool (contract's native balance)
            // The value is proportional to the total Chronos staked vs. total Essence minted.
            nativeAmount = (amount * totalChronosStaked) / totalEssenceSupply;
        } else {
            nativeAmount = 0; 
        }
        
        require(address(this).balance >= nativeAmount, "Insufficient native balance in contract to fulfill withdrawal");

        essenceBalances[msg.sender] -= amount;
        totalEssenceSupply -= amount;
        
        payable(msg.sender).transfer(nativeAmount);
        emit EssenceWithdrawn(msg.sender, amount, nativeAmount);
    }

    // --- IV. Governance & Parameterization ---

    /// @notice Users with sufficient Chronos can propose changes to system parameters.
    /// @param paramKey The key of the parameter to change (e.g., keccak256("epochDuration")).
    /// @param newValue The new value for the parameter.
    /// @param description A description of the proposed change.
    /// @return The ID of the newly created governance proposal.
    function proposeForgeParameterChange(bytes32 paramKey, uint256 newValue, string memory description) external returns (uint256) {
        require(userChronosBalances[msg.sender] >= forgeParameters.minChronosForGovProposal, "Insufficient Chronos for governance proposal");
        require(paramKey != 0, "Parameter key cannot be empty");

        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.paramKey = paramKey;
        proposal.newValue = newValue;
        proposal.description = description;
        proposal.creationTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + forgeParameters.govVotingPeriod;
        proposal.status = ProposalStatus.Active;

        activeGovernanceProposals.push(proposalId);
        emit GovernanceProposalSubmitted(proposalId, msg.sender, paramKey, newValue);
        return proposalId;
    }

    /// @notice Users vote on governance proposals using their Chronos power.
    /// @param proposalId The ID of the governance proposal.
    /// @param approve True for 'For', false for 'Against'.
    function voteOnParameterChange(uint256 proposalId, bool approve) external {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Governance proposal not active for voting");
        require(block.timestamp < proposal.votingEndTime, "Governance voting period has ended");
        require(userChronosBalances[msg.sender] >= forgeParameters.minChronosForGovVote, "Insufficient Chronos to vote");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal");

        uint256 voteWeight = userChronosBalances[msg.sender];
        if (approve) {
            proposal.votesFor += voteWeight;
        } else {
            proposal.votesAgainst += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        emit GovernanceVoteCast(proposalId, msg.sender, approve, voteWeight);
    }

    /// @notice View details of a governance proposal.
    /// @param proposalId The ID of the governance proposal.
    /// @return Details of the governance proposal.
    function getGovernanceProposalDetails(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            bytes32 paramKey,
            uint256 newValue,
            string memory description,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalStatus status
        )
    {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.paramKey,
            proposal.newValue,
            proposal.description,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status
        );
    }

    /// @notice The owner executes a successfully voted-on governance proposal.
    /// @dev This function should ideally be called by a decentralized mechanism (e.g., DAO multisig or a keeper).
    ///      Here, for simplicity, it's `onlyOwner`.
    /// @param proposalId The ID of the governance proposal to execute.
    function executeForgeParameterChange(uint256 proposalId) external onlyOwner {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal not active or already executed/rejected");
        require(block.timestamp >= proposal.votingEndTime, "Voting period not yet ended");

        if (proposal.votesFor > proposal.votesAgainst) {
            // A simple majority is used here. More complex quorums could be implemented.
            _updateForgeParameter(proposal.paramKey, proposal.newValue);
            proposal.status = ProposalStatus.Executed;
            emit GovernanceProposalExecuted(proposalId, proposal.paramKey, proposal.newValue);
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        _removeGovernanceProposal(proposalId);
    }

    /// @notice View all current configurable parameters of the Forge.
    /// @return All parameters as a struct.
    function getForgeParameters() external view returns (ForgeParameters memory) {
        return forgeParameters;
    }

    // --- V. Administrative & Oracle-like Functions ---

    /// @notice The core function to advance the Forge's epoch, process evolution proposals, apply entropy, and distribute rewards.
    /// @dev This function is intended to be called periodically (e.g., once per epochDuration) by the owner or a trusted keeper.
    function triggerForgeSync() external onlyOwner {
        require(block.timestamp >= lastForgeSyncTime + forgeParameters.epochDuration, "Epoch duration has not passed yet");

        currentEpoch++;
        lastForgeSyncTime = block.timestamp;

        _applyEntityEntropy();          // Apply natural entity drift
        _evaluateEvolutionProposals();  // Process user evolution proposals
        _distributeEpochRewards();      // Distribute general rewards
        _applyReputationDecayInternal(); // Apply reputation decay internally for relevant users

        emit ForgeSyncTriggered(currentEpoch, block.timestamp);
    }

    /// @notice (Owner/Keeper - simulated oracle) Allows external data to influence entity evolution.
    /// @dev This simulates an oracle system. In a real scenario, this would integrate with Chainlink or similar.
    /// @param dataKey A key representing the type of external data (e.g., keccak256("market_sentiment")).
    /// @param dataValue The numerical value of the external data.
    function submitExternalInfluence(bytes32 dataKey, uint256 dataValue) external onlyOwner {
        // Example: External influence could directly update a trait or set a flag
        // For demonstration, let's say an "external_mood" trait is influenced
        if (dataKey == keccak256("market_sentiment")) {
            bytes32 mood;
            if (dataValue > 70) mood = keccak256("optimistic");
            else if (dataValue < 30) mood = keccak256("pessimistic");
            else mood = keccak256("neutral");

            entityTraits[keccak256("external_mood")] = EntityTrait({
                value: mood,
                lastUpdatedEpoch: currentEpoch,
                description: "Influenced by external market sentiment"
            });
            emit EntityTraitUpdated(keccak256("external_mood"), mood, currentEpoch);
        }
        // Further logic can be added here to dynamically update other traits
        emit ExternalInfluenceSubmitted(dataKey, dataValue);
    }

    /// @notice (Owner) Adjusts the global rate at which user reputation naturally decays over time.
    /// @dev This can also be changed via governance proposals.
    /// @param rate The new percentage decay rate (e.g., 100 for 1%, 50 for 0.5%, scaled by 10000).
    function updateReputationDecayRate(uint256 rate) external onlyOwner {
        require(rate <= 10000, "Decay rate cannot exceed 100%"); // Max 100% (10000 = 100%)
        forgeParameters.reputationDecayRate = rate;
        emit ReputationDecayRateUpdated(rate);
    }

    // --- Internal Logic Functions ---

    /// @dev Applies natural entropy/drift to the entity's traits.
    ///      This is a placeholder for actual entropy logic.
    ///      For demonstration, we use a deterministic "random" based on epoch and a small factor.
    function _applyEntityEntropy() internal {
        bytes32[] memory traitKeys = new bytes32[](3);
        traitKeys[0] = keccak256("energy_level");
        traitKeys[1] = keccak256("growth_factor");
        traitKeys[2] = keccak256("adaptive_capacity");

        uint256 randomIndex = currentEpoch % traitKeys.length;
        bytes32 keyToDrift = traitKeys[randomIndex];
        EntityTrait storage trait = entityTraits[keyToDrift];

        // Simulate a small "drift" based on entityEntropyFactor
        // A real system would need a robust RNG for true decentralization (e.g., Chainlink VRF).
        if (currentEpoch % 10000 < forgeParameters.entityEntropyFactor) { // small chance
            bytes32 newDriftValue;
            if (keyToDrift == keccak256("energy_level")) {
                if (trait.value == keccak256("stable")) newDriftValue = keccak256("fluctuating");
                else if (trait.value == keccak256("fluctuating")) newDriftValue = keccak256("unstable");
                else newDriftValue = keccak256("stable");
            } else if (keyToDrift == keccak256("growth_factor")) {
                if (trait.value == keccak256("slow")) newDriftValue = keccak256("moderate");
                else if (trait.value == keccak256("moderate")) newDriftValue = keccak256("rapid");
                else newDriftValue = keccak256("slow");
            } else { // adaptive_capacity
                 if (trait.value == keccak256("moderate")) newDriftValue = keccak256("high");
                 else if (trait.value == keccak256("high")) newDriftValue = keccak256("very_high");
                 else newDriftValue = keccak256("moderate");
            }
            if (newDriftValue != 0 && newDriftValue != trait.value) {
                trait.value = newDriftValue;
                trait.lastUpdatedEpoch = currentEpoch;
                emit EntityTraitUpdated(keyToDrift, newDriftValue, currentEpoch);
            }
        }
    }

    /// @dev Evaluates active evolution proposals, updating entity traits and awarding reputation.
    ///      This function might be gas-intensive if `activeEvolutionProposals` is very large.
    ///      A more scalable solution would involve off-chain processing or batching.
    function _evaluateEvolutionProposals() internal {
        uint256[] memory proposalsToKeep = new uint256[](activeEvolutionProposals.length);
        uint256 keepCount = 0;

        // Create a temporary mapping to find the winning proposal for each traitKey
        mapping(bytes32 => uint256) traitWinningProposalId;
        mapping(bytes32 => uint256) traitMaxStaked;

        for (uint256 i = 0; i < activeEvolutionProposals.length; i++) {
            uint256 proposalId = activeEvolutionProposals[i];
            EvolutionProposal storage proposal = evolutionProposals[proposalId];

            if (proposal.endTime <= block.timestamp && !proposal.evaluated) {
                // Proposal period has ended, consider for evaluation
                if (proposal.totalChronosStaked > traitMaxStaked[proposal.traitKey]) {
                    traitMaxStaked[proposal.traitKey] = proposal.totalChronosStaked;
                    traitWinningProposalId[proposal.traitKey] = proposal.id;
                }
            }
        }

        // Now iterate again to finalize evaluation
        for (uint256 i = 0; i < activeEvolutionProposals.length; i++) {
            uint256 proposalId = activeEvolutionProposals[i];
            EvolutionProposal storage proposal = evolutionProposals[proposalId];

            if (proposal.endTime <= block.timestamp && !proposal.evaluated) {
                proposal.evaluated = true;
                if (proposal.id == traitWinningProposalId[proposal.traitKey] && proposal.totalChronosStaked > 0) {
                    // This proposal is the winning one for its trait
                    entityTraits[proposal.traitKey].value = proposal.proposedValue;
                    entityTraits[proposal.traitKey].lastUpdatedEpoch = currentEpoch;
                    proposal.status = ProposalStatus.Approved;
                    emit EntityTraitUpdated(proposal.traitKey, proposal.proposedValue, currentEpoch);

                    // Award reputation to successful proposer
                    // (Simplified: A percentage of total staked on the winning proposal)
                    userStats[proposal.proposer].reputation += (proposal.totalChronosStaked * 100) / 10000; // e.g., 1% of total staked Chronos
                    userStats[proposal.proposer].lastReputationUpdate = block.timestamp;

                    // Staked Chronos remains in the proposal's `stakers` mapping until `claimPredictionRewards` is called.
                    // If a proposal is rejected, Chronos remains staked until a dedicated `reclaimStakedChronos` (not implemented here) is called.
                    // For this example, users of rejected proposals manually need to `unstakeFromPath` *before* `endTime`.
                    // A production system would have clear mechanisms for retrieving stakes from failed proposals.
                } else {
                    proposal.status = ProposalStatus.Rejected;
                    // Stakers of rejected proposals can unstake their Chronos
                    // For now, they must call `unstakeFromPath` before `endTime` or their Chronos is held.
                    // A proper system would allow them to reclaim their Chronos after evaluation if rejected.
                }
            }
            if (proposal.status == ProposalStatus.Active) {
                proposalsToKeep[keepCount++] = proposalId;
            }
        }
        activeEvolutionProposals = new uint256[](keepCount);
        for (uint256 i = 0; i < keepCount; i++) {
            activeEvolutionProposals[i] = proposalsToKeep[i];
        }
    }

    /// @dev Distributes Essence rewards to active Chronos stakers for the current epoch.
    ///      This function avoids iterating over all users by simply increasing `totalEssenceSupply`.
    ///      Users then withdraw their share of the contract's native balance via `withdrawEssence`.
    function _distributeEpochRewards() internal {
        if (totalChronosStaked == 0) return;

        // Calculate a portion of the total Chronos pool as rewards
        uint256 rewardPoolAmount = (totalChronosStaked * forgeParameters.epochRewardPoolFraction) / 10000; // e.g., 1%

        if (rewardPoolAmount == 0) return;

        // Increase total Essence supply. This Essence represents a claim on the contract's native balance.
        totalEssenceSupply += rewardPoolAmount; 
    }

    /// @dev Applies reputation decay internally for users that have had recent activity,
    ///      or ensures `lastReputationUpdate` is current. Actual calculation happens lazily in `getUserReputation`.
    function _applyReputationDecayInternal() internal {
        // This function would ideally update the `lastReputationUpdate` timestamp for *all* active users
        // that could potentially have reputation decay applied. However, iterating through `userStats`
        // mapping keys is not possible in Solidity.
        // Instead, the `getUserReputation` function already incorporates lazy decay calculation.
        // This internal call primarily serves as a hook for potential future batch processing or
        // to signify that a new decay period has conceptually begun.
        // For individual users, their reputation decay will be calculated when `getUserReputation` is called.
    }

    /// @dev Internal helper to update a forge parameter.
    function _updateForgeParameter(bytes32 paramKey, uint256 newValue) internal {
        if (paramKey == keccak256("epochDuration")) {
            forgeParameters.epochDuration = newValue;
        } else if (paramKey == keccak256("evolutionProposalDuration")) {
            forgeParameters.evolutionProposalDuration = newValue;
        } else if (paramKey == keccak256("minChronosForProposal")) {
            forgeParameters.minChronosForProposal = newValue;
        } else if (paramKey == keccak256("minChronosForGovProposal")) {
            forgeParameters.minChronosForGovProposal = newValue;
        } else if (paramKey == keccak256("minChronosForGovVote")) {
            forgeParameters.minChronosForGovVote = newValue;
        } else if (paramKey == keccak256("govVotingPeriod")) {
            forgeParameters.govVotingPeriod = newValue;
        } else if (paramKey == keccak256("predictionRewardMultiplier")) {
            forgeParameters.predictionRewardMultiplier = newValue;
        } else if (paramKey == keccak256("epochRewardPoolFraction")) {
            forgeParameters.epochRewardPoolFraction = newValue;
        } else if (paramKey == keccak256("reputationDecayRate")) {
            forgeParameters.reputationDecayRate = newValue;
        } else if (paramKey == keccak256("entityEntropyFactor")) {
            forgeParameters.entityEntropyFactor = newValue;
        }
        // Add more parameters here as needed
    }

    /// @dev Internal helper to remove a governance proposal from the active list.
    function _removeGovernanceProposal(uint256 proposalId) internal {
        for (uint256 i = 0; i < activeGovernanceProposals.length; i++) {
            if (activeGovernanceProposals[i] == proposalId) {
                activeGovernanceProposals[i] = activeGovernanceProposals[activeGovernanceProposals.length - 1];
                activeGovernanceProposals.pop();
                break;
            }
        }
    }

    // Fallback function to receive native token
    receive() external payable {
        // Native tokens sent to the contract are considered general funds,
        // which back the Chronos and Essence values.
    }
}
```