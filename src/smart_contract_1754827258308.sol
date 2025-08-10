Okay, this is an exciting challenge! Creating something truly unique while still being technically feasible on-chain requires thinking about advanced concepts beyond standard token/NFT models.

Let's design a smart contract called **"ChronoNexus"**.

**Core Concept:** ChronoNexus is a **Temporal State Machine & Dynamic Asset Orchestrator**. It manages a living, evolving ecosystem where rules, asset utilities, and governance mechanisms adapt over predefined time-based "Epochs". It introduces concepts like dynamic asset utility, influence-based adaptive governance, on-chain scheduled task orchestration, and self-adaptive system parameters.

---

### ChronoNexus: Temporal State Machine & Dynamic Asset Orchestrator

**Outline:**

1.  **Introduction & Core Principles:**
    *   Time-based Epochs: The contract's state and rules evolve based on discrete time periods.
    *   Temporal Assets: Assets whose utility or properties change over time (e.g., decay, enhance).
    *   Adaptive Governance: Influence-weighted voting and self-correcting parameter adjustments.
    *   On-Chain Task Orchestration: Scheduling and executing future arbitrary function calls.
    *   Self-Evolution & Sunset Protocol: Mechanism for the contract to adapt or gracefully deprecate.

2.  **State Variables & Data Structures:**
    *   Epoch parameters, current epoch info.
    *   Temporal Asset data.
    *   Influence system data.
    *   Proposal/Directive data.
    *   Scheduled task queue.

3.  **Functions Categories:**
    *   **I. Epoch Management & Core Logic:** Managing the contract's temporal state.
    *   **II. Temporal Asset Orchestration:** Minting, managing, and interacting with time-sensitive assets.
    *   **III. Adaptive Governance & Influence:** Handling proposals, voting, and dynamic parameter adjustments based on influence.
    *   **IV. On-Chain Task Orchestration:** Scheduling and executing future contract interactions.
    *   **V. System Health & Self-Correction:** Monitoring and initiating emergency or sunset protocols.
    *   **VI. View Functions & Utilities:** Read-only data access and general utilities.

---

**Function Summary (20+ Functions):**

**I. Epoch Management & Core Logic:**
1.  `constructor()`: Initializes the contract with the first epoch parameters and duration.
2.  `advanceEpoch()`: Triggers the transition to the next epoch. Can be called by anyone but requires current epoch to be over. Distributes influence based on past activity.
3.  `setEpochDuration(uint256 newDuration)`: Allows governance to adjust the duration of future epochs.
4.  `getCurrentEpoch()`: Returns the details of the current active epoch.
5.  `getTimeRemainingInEpoch()`: Calculates the remaining time until the next epoch transition.

**II. Temporal Asset Orchestration:**
6.  `mintTemporalAsset(address receiver, string calldata metadataURI, uint256 initialUtility, uint256 decayRatePerEpoch)`: Mints a new Temporal Asset with a defined initial utility and a decay rate that applies each epoch.
7.  `burnTemporalAsset(uint256 tokenId)`: Allows a Temporal Asset holder to burn their asset.
8.  `transferTemporalAsset(address from, address to, uint256 tokenId)`: Transfers ownership of a Temporal Asset. Its utility continues to decay regardless of ownership.
9.  `getTemporalAssetUtility(uint256 tokenId)`: Returns the current calculated utility value of a Temporal Asset based on elapsed epochs and decay rate.
10. `delegateTemporalAssetUtility(uint256 tokenId, address delegatee, uint256 epochDuration)`: Allows a holder to delegate the *utility* of their Temporal Asset to another address for a specified number of epochs.

**III. Adaptive Governance & Influence:**
11. `stakeForInfluence(uint256 amount)`: Allows users to stake funds to gain Influence Points over time. Staked funds are locked.
12. `unstakeInfluence(uint256 amount)`: Allows users to withdraw staked funds and forfeit future influence accrual from that stake.
13. `getInfluenceScore(address user)`: Returns a user's current accumulated Influence Score. (Calculated based on staked time, active participation, and asset holdings.)
14. `proposeAdaptiveDirective(string calldata description, bytes calldata targetFunctionCall)`: Submits a proposal for a system parameter change or a specific function execution, weighted by influence.
15. `castInfluenceVote(uint256 proposalId, bool voteFor)`: Allows users to vote on an Adaptive Directive using their accumulated Influence Score.
16. `enactAdaptiveDirective(uint256 proposalId)`: Executes a successfully voted-on Adaptive Directive.

**IV. On-Chain Task Orchestration:**
17. `scheduleTimedTask(address targetContract, bytes calldata targetCallData, uint256 executionEpoch)`: Schedules an arbitrary function call on a target contract to be executed at a specific future epoch.
18. `executeScheduledTask(uint256 taskId)`: Allows anyone (e.g., a keeper bot) to trigger a scheduled task once its `executionEpoch` is reached. Includes reward for caller.
19. `cancelScheduledTask(uint256 taskId)`: Allows the task scheduler or governance to cancel a pending scheduled task.

**V. System Health & Self-Correction:**
20. `proposeSunsetProtocol(uint256 gracePeriodEpochs)`: Initiates a governance proposal to gracefully wind down the contract over a specified grace period, potentially allowing users to redeem assets.
21. `activateEmergencyBrake()`: An emergency function (callable by multi-sig governance) to pause critical contract functions in case of severe vulnerabilities or exploits.
22. `releaseEmergencyBrake()`: Reverses the emergency pause (also by multi-sig governance).

**VI. View Functions & Utilities:**
23. `getProposedDirective(uint256 proposalId)`: Returns details of a specific adaptive directive proposal.
24. `getScheduledTask(uint256 taskId)`: Returns details of a specific scheduled task.
25. `withdrawStakedFunds(uint256 stakeId)`: Allows withdrawal of specific stake amounts after their unlock period (if any).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For Temporal Assets (NFTs)
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For staking funds

/**
 * @title ChronoNexus: Temporal State Machine & Dynamic Asset Orchestrator
 * @dev This contract manages a living, evolving ecosystem where rules, asset utilities,
 *      and governance mechanisms adapt over predefined time-based "Epochs".
 *      It introduces concepts like dynamic asset utility, influence-based adaptive governance,
 *      on-chain scheduled task orchestration, and self-adaptive system parameters.
 *      It's designed to be a highly adaptive and evolving smart contract system.
 */
contract ChronoNexus is Ownable, Pausable, ERC721 {
    // --- I. Epoch Management & Core Logic ---

    uint256 public currentEpoch;
    uint256 public epochStartTime; // Timestamp when current epoch began
    uint256 public epochDuration;  // Duration of an epoch in seconds

    struct EpochParameters {
        uint256 epochId;
        uint256 startTime;
        uint256 duration;
        uint256 temporalAssetMintFee; // Fee for minting new temporal assets in this epoch
        uint256 influenceAccrualRate; // Rate at which influence points accrue per staked token per epoch
    }
    mapping(uint256 => EpochParameters) public epochHistory;

    // --- II. Temporal Asset Orchestration ---

    // Using ERC721 for Temporal Assets, where each asset has dynamic utility
    uint256 private _nextTokenId;

    struct TemporalAssetInfo {
        uint256 mintEpoch;       // The epoch when this asset was minted
        uint256 initialUtility;  // Initial utility score
        uint256 decayRatePerEpoch; // Percentage decay per epoch (e.g., 1000 for 10% decay)
        string metadataURI;      // URI for off-chain metadata (e.g., IPFS hash)
        address delegatedTo;     // Address to which utility is currently delegated
        uint256 delegationEndEpoch; // Epoch when delegation expires
    }
    mapping(uint256 => TemporalAssetInfo) public temporalAssets; // tokenId => TemporalAssetInfo

    // --- III. Adaptive Governance & Influence ---

    // Stake for Influence
    IERC20 public stakeToken; // ERC20 token used for staking
    uint256 public nextStakeId;

    struct Stake {
        address staker;
        uint256 amount;
        uint256 startEpoch;
        uint256 endEpoch; // If 0, stake is indefinite until unstaked
        bool isActive;
    }
    mapping(uint256 => Stake) public stakes; // stakeId => Stake
    mapping(address => uint256[]) public stakerStakes; // staker => array of stakeIds

    mapping(address => uint256) public influencePoints; // user => total accumulated influence points
    mapping(uint256 => mapping(address => bool)) public epochInfluenceClaimed; // epochId => user => claimed

    // Adaptive Directives (Proposals)
    uint256 public nextProposalId;

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Enacted }

    struct AdaptiveDirective {
        address proposer;
        string description;
        bytes targetFunctionCall; // calldata for the function to execute if proposal passes
        uint256 startEpoch;
        uint256 endEpoch; // Proposal voting window
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User => Voted or not
        ProposalStatus status;
        address targetContract; // Contract to call if directive passes
    }
    mapping(uint256 => AdaptiveDirective) public adaptiveDirectives;

    // --- IV. On-Chain Task Orchestration ---

    uint256 public nextTaskId;

    struct ScheduledTask {
        address proposer;
        address targetContract;
        bytes callData;
        uint256 executionEpoch; // The epoch in which this task is eligible for execution
        bool executed;
        uint256 rewardAmount; // ETH reward for the executor
    }
    mapping(uint256 => ScheduledTask) public scheduledTasks;

    // --- V. System Health & Self-Correction ---

    bool public sunsetProtocolActive;
    uint256 public sunsetGracePeriodEpochs;
    uint256 public sunsetStartEpoch;

    // --- Events ---
    event EpochAdvanced(uint256 indexed newEpochId, uint256 startTime, uint256 duration);
    event EpochDurationChanged(uint256 indexed oldDuration, uint256 newDuration);
    event TemporalAssetMinted(uint256 indexed tokenId, address indexed owner, uint256 initialUtility, uint256 mintEpoch);
    event TemporalAssetUtilityDelegated(uint256 indexed tokenId, address indexed delegatee, uint256 delegationEndEpoch);
    event InfluenceStaked(address indexed staker, uint256 amount, uint256 stakeId);
    event InfluenceUnstaked(address indexed staker, uint256 amount, uint256 stakeId);
    event InfluenceClaimed(address indexed user, uint256 epoch, uint256 claimedPoints);
    event DirectiveProposed(uint256 indexed proposalId, address indexed proposer, string description);
    event DirectiveVoted(uint256 indexed proposalId, address indexed voter, bool voteFor, uint256 influenceUsed);
    event DirectiveEnacted(uint256 indexed proposalId, address indexed proposer, bytes targetFunctionCall);
    event TaskScheduled(uint256 indexed taskId, address indexed proposer, address targetContract, uint256 executionEpoch);
    event TaskExecuted(uint256 indexed taskId, address indexed executor, uint256 reward);
    event TaskCancelled(uint256 indexed taskId, address indexed canceller);
    event SunsetProtocolProposed(uint256 indexed proposalId, uint256 gracePeriodEpochs);
    event SunsetProtocolActivated(uint256 indexed startEpoch, uint256 gracePeriodEpochs);
    event EmergencyBrakeActivated();
    event EmergencyBrakeReleased();


    // --- Modifiers ---
    modifier onlyActiveEpoch() {
        require(block.timestamp < epochStartTime + epochDuration, "Epoch is over, call advanceEpoch first.");
        _;
    }

    modifier onlyWhenSunsetNotActive() {
        require(!sunsetProtocolActive, "Sunset protocol is active, new operations restricted.");
        _;
    }

    /**
     * @dev Constructor initializes the ChronoNexus contract.
     * @param _initialEpochDuration The duration of the first epoch in seconds.
     * @param _stakeTokenAddress The address of the ERC20 token used for staking influence.
     */
    constructor(uint256 _initialEpochDuration, address _stakeTokenAddress)
        ERC721("ChronoNexusTemporalAsset", "CNTA")
        Ownable(msg.sender)
    {
        require(_initialEpochDuration > 0, "Epoch duration must be positive");
        require(_stakeTokenAddress != address(0), "Stake token address cannot be zero");

        epochDuration = _initialEpochDuration;
        epochStartTime = block.timestamp;
        currentEpoch = 1;

        epochHistory[currentEpoch] = EpochParameters({
            epochId: currentEpoch,
            startTime: epochStartTime,
            duration: epochDuration,
            temporalAssetMintFee: 100000000000000000, // 0.1 ETH example fee
            influenceAccrualRate: 10 // Example: 10 points per token per epoch
        });

        stakeToken = IERC20(_stakeTokenAddress);
    }

    receive() external payable {}

    // --- I. Epoch Management & Core Logic ---

    /**
     * @dev Triggers the transition to the next epoch.
     *      Anyone can call this, but it will only succeed if the current epoch has ended.
     *      It updates epoch parameters and distributes influence for the past epoch.
     */
    function advanceEpoch() public whenNotPaused {
        require(block.timestamp >= epochStartTime + epochDuration, "Current epoch has not ended yet.");
        require(!sunsetProtocolActive, "Cannot advance epoch during sunset protocol.");

        // Increment epoch, set new start time
        currentEpoch++;
        epochStartTime = block.timestamp;

        // Carry over or update epoch parameters for the new epoch
        EpochParameters storage prevParams = epochHistory[currentEpoch - 1];
        epochHistory[currentEpoch] = EpochParameters({
            epochId: currentEpoch,
            startTime: epochStartTime,
            duration: epochDuration, // Default to current global duration, can be changed by adaptive directive
            temporalAssetMintFee: prevParams.temporalAssetMintFee,
            influenceAccrualRate: prevParams.influenceAccrualRate
        });

        // Distribute influence for the past epoch (currentEpoch - 1)
        _distributeEpochInfluence(currentEpoch - 1);

        emit EpochAdvanced(currentEpoch, epochStartTime, epochDuration);
    }

    /**
     * @dev Allows governance (via Adaptive Directive) to adjust the duration of future epochs.
     * @param _newDuration The new duration in seconds for subsequent epochs.
     */
    function setEpochDuration(uint256 _newDuration) public onlyOwner whenNotPaused {
        require(_newDuration > 0, "Epoch duration must be positive.");
        // This change applies from the *next* epoch
        uint256 oldDuration = epochDuration;
        epochDuration = _newDuration;
        emit EpochDurationChanged(oldDuration, _newDuration);
    }

    /**
     * @dev Returns the details of the current active epoch.
     */
    function getCurrentEpoch() public view returns (EpochParameters memory) {
        return epochHistory[currentEpoch];
    }

    /**
     * @dev Calculates the remaining time until the next epoch transition.
     * @return The time in seconds remaining until the next epoch. Returns 0 if epoch already ended.
     */
    function getTimeRemainingInEpoch() public view returns (uint256) {
        uint256 epochEndTime = epochStartTime + epochDuration;
        if (block.timestamp >= epochEndTime) {
            return 0;
        }
        return epochEndTime - block.timestamp;
    }

    // --- II. Temporal Asset Orchestration ---

    /**
     * @dev Mints a new Temporal Asset with a defined initial utility and a decay rate.
     *      Requires payment of the current epoch's mint fee.
     * @param _receiver The address to receive the new Temporal Asset.
     * @param _metadataURI URI for off-chain metadata.
     * @param _initialUtility The starting utility score for the asset.
     * @param _decayRatePerEpoch Percentage decay per epoch (e.g., 1000 for 10% decay).
     */
    function mintTemporalAsset(address _receiver, string calldata _metadataURI, uint256 _initialUtility, uint256 _decayRatePerEpoch)
        public payable whenNotPaused onlyWhenSunsetNotActive
    {
        require(msg.value >= epochHistory[currentEpoch].temporalAssetMintFee, "Insufficient mint fee.");
        require(_initialUtility > 0, "Initial utility must be positive.");
        require(_decayRatePerEpoch <= 10000, "Decay rate cannot exceed 100%"); // 10000 = 100%

        uint256 tokenId = _nextTokenId++;
        _safeMint(_receiver, tokenId);

        temporalAssets[tokenId] = TemporalAssetInfo({
            mintEpoch: currentEpoch,
            initialUtility: _initialUtility,
            decayRatePerEpoch: _decayRatePerEpoch,
            metadataURI: _metadataURI,
            delegatedTo: address(0), // No delegation initially
            delegationEndEpoch: 0
        });

        emit TemporalAssetMinted(tokenId, _receiver, _initialUtility, currentEpoch);
    }

    /**
     * @dev Allows a Temporal Asset holder to burn their asset.
     * @param _tokenId The ID of the Temporal Asset to burn.
     */
    function burnTemporalAsset(uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not owner nor approved.");
        _burn(_tokenId);
        // Clear asset data
        delete temporalAssets[_tokenId];
    }

    /**
     * @dev Overrides ERC721's _transfer function to ensure additional checks if needed
     *      For ChronoNexus, standard transfer is fine as utility is time-bound, not holder-bound.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        // Clear any active delegation when asset is transferred
        temporalAssets[tokenId].delegatedTo = address(0);
        temporalAssets[tokenId].delegationEndEpoch = 0;
        super._transfer(from, to, tokenId);
    }

    /**
     * @dev Returns the current calculated utility value of a Temporal Asset.
     *      Utility decays based on elapsed epochs since minting.
     * @param _tokenId The ID of the Temporal Asset.
     * @return The current utility score.
     */
    function getTemporalAssetUtility(uint256 _tokenId) public view returns (uint256) {
        TemporalAssetInfo storage asset = temporalAssets[_tokenId];
        require(asset.mintEpoch != 0, "Temporal Asset does not exist.");

        uint256 epochsPassed = currentEpoch - asset.mintEpoch;
        uint256 currentUtility = asset.initialUtility;

        // Apply decay for each passed epoch
        for (uint256 i = 0; i < epochsPassed; i++) {
            currentUtility = currentUtility * (10000 - asset.decayRatePerEpoch) / 10000; // 10000 = 100%
        }
        return currentUtility;
    }

    /**
     * @dev Allows a holder to delegate the *utility* of their Temporal Asset to another address.
     *      The original owner retains ERC721 ownership.
     * @param _tokenId The ID of the Temporal Asset.
     * @param _delegatee The address to which utility is delegated.
     * @param _epochDuration The number of epochs for which the utility is delegated.
     */
    function delegateTemporalAssetUtility(uint256 _tokenId, address _delegatee, uint256 _epochDuration)
        public whenNotPaused onlyWhenSunsetNotActive
    {
        require(ownerOf(_tokenId) == msg.sender, "Caller is not the owner of the Temporal Asset.");
        require(_delegatee != address(0), "Delegatee cannot be zero address.");
        require(_epochDuration > 0, "Delegation duration must be positive.");

        temporalAssets[_tokenId].delegatedTo = _delegatee;
        temporalAssets[_tokenId].delegationEndEpoch = currentEpoch + _epochDuration;

        emit TemporalAssetUtilityDelegated(_tokenId, _delegatee, temporalAssets[_tokenId].delegationEndEpoch);
    }

    /**
     * @dev Internal helper to get the address currently deriving utility from an asset.
     */
    function _getTemporalAssetUtilityRecipient(uint256 _tokenId) internal view returns (address) {
        TemporalAssetInfo storage asset = temporalAssets[_tokenId];
        if (asset.delegatedTo != address(0) && currentEpoch < asset.delegationEndEpoch) {
            return asset.delegatedTo;
        }
        return ownerOf(_tokenId); // Default to owner if not delegated or delegation expired
    }

    // --- III. Adaptive Governance & Influence ---

    /**
     * @dev Allows users to stake funds (stakeToken) to gain Influence Points over time.
     *      Staked funds are locked.
     * @param _amount The amount of stakeToken to stake.
     */
    function stakeForInfluence(uint256 _amount) public whenNotPaused onlyWhenSunsetNotActive {
        require(_amount > 0, "Stake amount must be positive.");
        require(stakeToken.transferFrom(msg.sender, address(this), _amount), "Stake token transfer failed.");

        uint256 stakeId = nextStakeId++;
        stakes[stakeId] = Stake({
            staker: msg.sender,
            amount: _amount,
            startEpoch: currentEpoch,
            endEpoch: 0, // Indefinite stake
            isActive: true
        });
        stakerStakes[msg.sender].push(stakeId);

        emit InfluenceStaked(msg.sender, _amount, stakeId);
    }

    /**
     * @dev Allows users to withdraw staked funds and forfeit future influence accrual from that stake.
     * @param _stakeId The ID of the stake to withdraw.
     */
    function unstakeInfluence(uint256 _stakeId) public whenNotPaused {
        Stake storage stake = stakes[_stakeId];
        require(stake.staker == msg.sender, "You are not the owner of this stake.");
        require(stake.isActive, "Stake is not active.");

        stake.isActive = false; // Mark as inactive immediately
        stake.endEpoch = currentEpoch; // Mark the epoch it was unstaked

        // Transfer funds back
        require(stakeToken.transfer(msg.sender, stake.amount), "Unstake token transfer failed.");

        emit InfluenceUnstaked(msg.sender, stake.amount, _stakeId);
    }

    /**
     * @dev Calculates and claims accumulated Influence Points for the caller for past epochs.
     *      Influence is earned based on active stakes during an epoch.
     *      Can be called by anyone for themselves.
     */
    function _distributeEpochInfluence(uint256 _pastEpochId) internal {
        require(_pastEpochId < currentEpoch, "Cannot distribute influence for current or future epoch.");
        require(_pastEpochId >= 1, "Invalid epoch ID.");
        
        uint256 _accrualRate = epochHistory[_pastEpochId].influenceAccrualRate;

        // Iterate through all stakes
        for (uint256 i = 0; i < nextStakeId; i++) {
            Stake storage stake = stakes[i];
            if (stake.staker != address(0) && stake.isActive && stake.startEpoch <= _pastEpochId) {
                // Check if stake was active during the entire past epoch
                if (stake.endEpoch == 0 || stake.endEpoch > _pastEpochId) { // Stake active for full epoch
                    // Accrue influence for this stake for this past epoch
                    if (!epochInfluenceClaimed[_pastEpochId][stake.staker]) { // Ensure influence not already accounted for this epoch
                         uint256 accrued = stake.amount * _accrualRate;
                         influencePoints[stake.staker] += accrued;
                         // No specific event for *internal* distribution, handled by EpochAdvanced
                    }
                }
            }
        }
        // Mark influence as distributed for the epoch; specific users will still call claimInfluencePoints
    }


    /**
     * @dev Returns a user's current accumulated Influence Score.
     *      Influence is calculated based on past epoch's staking activity and is "claimable" by the user.
     * @param _user The address of the user.
     * @return The total influence score.
     */
    function getInfluenceScore(address _user) public view returns (uint256) {
        return influencePoints[_user];
    }

    /**
     * @dev Allows users to claim their accrued influence points for a given past epoch.
     *      This is separate from the internal distribution triggered by `advanceEpoch`.
     * @param _epochId The specific epoch for which to claim influence.
     */
    function claimInfluencePoints(uint256 _epochId) public {
        require(_epochId < currentEpoch, "Cannot claim influence for current or future epoch.");
        require(!epochInfluenceClaimed[_epochId][msg.sender], "Influence already claimed for this epoch.");

        uint256 accruedPointsForEpoch = 0;
        uint256 _accrualRate = epochHistory[_epochId].influenceAccrualRate;

        for (uint256 i = 0; i < stakerStakes[msg.sender].length; i++) {
            uint256 stakeId = stakerStakes[msg.sender][i];
            Stake storage stake = stakes[stakeId];

            if (stake.isActive && stake.startEpoch <= _epochId && (stake.endEpoch == 0 || stake.endEpoch > _epochId)) {
                // Stake was active for the entire _epochId
                accruedPointsForEpoch += (stake.amount * _accrualRate);
            }
        }

        require(accruedPointsForEpoch > 0, "No influence points to claim for this epoch.");

        influencePoints[msg.sender] += accruedPointsForEpoch;
        epochInfluenceClaimed[_epochId][msg.sender] = true;

        emit InfluenceClaimed(msg.sender, _epochId, accruedPointsForEpoch);
    }


    /**
     * @dev Submits a proposal for a system parameter change or a specific function execution,
     *      weighted by influence.
     * @param _description A human-readable description of the proposal.
     * @param _targetContract The address of the contract to call if the proposal passes (can be this contract).
     * @param _targetFunctionCall The calldata for the function to execute if proposal passes.
     */
    function proposeAdaptiveDirective(string calldata _description, address _targetContract, bytes calldata _targetFunctionCall)
        public whenNotPaused onlyWhenSunsetNotActive
    {
        require(bytes(_description).length > 0, "Description cannot be empty.");
        require(_targetContract != address(0), "Target contract cannot be zero address.");
        require(_targetFunctionCall.length > 0, "Target function call cannot be empty.");
        require(influencePoints[msg.sender] > 0, "Proposer must have influence points.");

        uint256 proposalId = nextProposalId++;
        adaptiveDirectives[proposalId] = AdaptiveDirective({
            proposer: msg.sender,
            description: _description,
            targetFunctionCall: _targetFunctionCall,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + 1, // Voting window: current epoch only
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            targetContract: _targetContract
        });

        emit DirectiveProposed(proposalId, msg.sender, _description);
    }

    /**
     * @dev Allows users to vote on an Adaptive Directive using their accumulated Influence Score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _voteFor True for 'yes', false for 'no'.
     */
    function castInfluenceVote(uint256 _proposalId, bool _voteFor) public whenNotPaused {
        AdaptiveDirective storage proposal = adaptiveDirectives[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(currentEpoch == proposal.startEpoch, "Voting is only allowed in the proposal's active epoch.");
        require(!proposal.hasVoted[msg.sender], "You have already voted on this proposal.");
        require(influencePoints[msg.sender] > 0, "You need influence points to vote.");

        uint256 userInfluence = influencePoints[msg.sender];
        if (_voteFor) {
            proposal.votesFor += userInfluence;
        } else {
            proposal.votesAgainst += userInfluence;
        }
        proposal.hasVoted[msg.sender] = true;

        // Reduce voter's influence after voting to prevent re-use within the same epoch
        // (Alternatively, could implement a 'voting power snapshot' per epoch)
        influencePoints[msg.sender] = 0; // For simplicity, consume all influence for this vote.
                                        // More complex systems might use a portion or a snapshot.

        emit DirectiveVoted(_proposalId, msg.sender, _voteFor, userInfluence);
    }

    /**
     * @dev Executes a successfully voted-on Adaptive Directive.
     *      Can be called by anyone once the voting period is over and proposal succeeded.
     * @param _proposalId The ID of the proposal to enact.
     */
    function enactAdaptiveDirective(uint256 _proposalId) public whenNotPaused {
        AdaptiveDirective storage proposal = adaptiveDirectives[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not in active state.");
        require(currentEpoch > proposal.endEpoch, "Voting period has not ended yet.");

        // Determine if proposal succeeded (simple majority for now)
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.status = ProposalStatus.Succeeded;
            (bool success, ) = proposal.targetContract.call(proposal.targetFunctionCall);
            require(success, "Directive execution failed.");
            proposal.status = ProposalStatus.Enacted;
            emit DirectiveEnacted(_proposalId, proposal.proposer, proposal.targetFunctionCall);
        } else {
            proposal.status = ProposalStatus.Failed;
        }
    }

    // --- IV. On-Chain Task Orchestration ---

    /**
     * @dev Schedules an arbitrary function call on a target contract to be executed at a specific future epoch.
     *      A small ETH reward is attached to incentivize execution by keeper bots.
     * @param _targetContract The address of the contract to call.
     * @param _callData The calldata for the function to execute.
     * @param _executionEpoch The epoch in which this task is eligible for execution.
     * @param _rewardAmount The ETH amount to reward the executor.
     */
    function scheduleTimedTask(address _targetContract, bytes calldata _callData, uint256 _executionEpoch, uint256 _rewardAmount)
        public payable whenNotPaused onlyWhenSunsetNotActive
    {
        require(_targetContract != address(0), "Target contract cannot be zero address.");
        require(_callData.length > 0, "Call data cannot be empty.");
        require(_executionEpoch > currentEpoch, "Execution epoch must be in the future.");
        require(msg.value >= _rewardAmount, "Insufficient ETH for reward.");

        uint256 taskId = nextTaskId++;
        scheduledTasks[taskId] = ScheduledTask({
            proposer: msg.sender,
            targetContract: _targetContract,
            callData: _callData,
            executionEpoch: _executionEpoch,
            executed: false,
            rewardAmount: _rewardAmount
        });

        // If there's excess ETH sent, refund it
        if (msg.value > _rewardAmount) {
            payable(msg.sender).transfer(msg.value - _rewardAmount);
        }

        emit TaskScheduled(taskId, msg.sender, _targetContract, _executionEpoch);
    }

    /**
     * @dev Allows anyone (e.g., a keeper bot) to trigger a scheduled task once its `executionEpoch` is reached.
     *      The caller receives the specified reward.
     * @param _taskId The ID of the task to execute.
     */
    function executeScheduledTask(uint256 _taskId) public whenNotPaused {
        ScheduledTask storage task = scheduledTasks[_taskId];
        require(task.proposer != address(0), "Task does not exist.");
        require(!task.executed, "Task already executed.");
        require(currentEpoch >= task.executionEpoch, "Task not yet eligible for execution.");

        task.executed = true; // Mark as executed before the call to prevent reentrancy

        (bool success, ) = task.targetContract.call(task.callData);
        require(success, "Scheduled task execution failed.");

        // Reward the caller
        if (task.rewardAmount > 0) {
            payable(msg.sender).transfer(task.rewardAmount);
        }

        emit TaskExecuted(_taskId, msg.sender, task.rewardAmount);
    }

    /**
     * @dev Allows the task scheduler or governance to cancel a pending scheduled task.
     *      Refunds any attached reward to the original proposer.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelScheduledTask(uint256 _taskId) public whenNotPaused {
        ScheduledTask storage task = scheduledTasks[_taskId];
        require(task.proposer != address(0), "Task does not exist.");
        require(!task.executed, "Task already executed.");
        require(task.proposer == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only proposer or admin can cancel.");
        require(currentEpoch < task.executionEpoch, "Cannot cancel a task in its execution epoch or past.");


        delete scheduledTasks[_taskId]; // Remove the task

        // Refund the reward
        if (task.rewardAmount > 0) {
            payable(task.proposer).transfer(task.rewardAmount);
        }

        emit TaskCancelled(_taskId, msg.sender);
    }

    // --- V. System Health & Self-Correction ---

    /**
     * @dev Initiates a governance proposal to gracefully wind down the contract over a specified grace period.
     *      During sunset, many operations might be restricted, allowing users to exit.
     * @param _gracePeriodEpochs The number of epochs for the sunset grace period.
     */
    function proposeSunsetProtocol(uint256 _gracePeriodEpochs) public onlyOwner whenNotPaused {
        require(!sunsetProtocolActive, "Sunset protocol is already active.");
        require(_gracePeriodEpochs > 0, "Grace period must be positive.");

        // This would typically trigger an adaptive directive that votes on this.
        // For simplicity, directly triggerable by owner for demonstration.
        sunsetProtocolActive = true;
        sunsetStartEpoch = currentEpoch;
        sunsetGracePeriodEpochs = _gracePeriodEpochs;

        emit SunsetProtocolProposed(0, _gracePeriodEpochs); // Using 0 as proposalId for direct owner call
        emit SunsetProtocolActivated(sunsetStartEpoch, sunsetGracePeriodEpochs);
    }

    /**
     * @dev Activates an emergency brake, pausing critical contract functions.
     *      Callable by the owner or a designated multi-sig for emergency.
     */
    function activateEmergencyBrake() public onlyOwner {
        _pause();
        emit EmergencyBrakeActivated();
    }

    /**
     * @dev Releases the emergency brake, unpausing contract functions.
     *      Callable by the owner or a designated multi-sig.
     */
    function releaseEmergencyBrake() public onlyOwner {
        _unpause();
        emit EmergencyBrakeReleased();
    }

    // --- VI. View Functions & Utilities ---

    /**
     * @dev Returns details of a specific adaptive directive proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposer, description, target function call, votes for/against, status, target contract.
     */
    function getProposedDirective(uint256 _proposalId)
        public view returns (
            address proposer,
            string memory description,
            bytes memory targetFunctionCall,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalStatus status,
            address targetContract
        )
    {
        AdaptiveDirective storage p = adaptiveDirectives[_proposalId];
        return (p.proposer, p.description, p.targetFunctionCall, p.votesFor, p.votesAgainst, p.status, p.targetContract);
    }

    /**
     * @dev Returns details of a specific scheduled task.
     * @param _taskId The ID of the task.
     * @return Proposer, target contract, call data, execution epoch, executed status, reward.
     */
    function getScheduledTask(uint256 _taskId)
        public view returns (
            address proposer,
            address targetContract,
            bytes memory callData,
            uint256 executionEpoch,
            bool executed,
            uint256 rewardAmount
        )
    {
        ScheduledTask storage task = scheduledTasks[_taskId];
        return (task.proposer, task.targetContract, task.callData, task.executionEpoch, task.executed, task.rewardAmount);
    }
    
    /**
     * @dev Withdraws ETH from the contract's balance. Only callable by the owner.
     *      Excludes funds locked for scheduled task rewards.
     */
    function withdrawEth(uint256 _amount) public onlyOwner {
        // Calculate total locked ETH for scheduled tasks
        uint256 lockedEth = 0;
        for(uint256 i = 0; i < nextTaskId; i++) {
            if (scheduledTasks[i].proposer != address(0) && !scheduledTasks[i].executed) {
                lockedEth += scheduledTasks[i].rewardAmount;
            }
        }
        require(address(this).balance - lockedEth >= _amount, "Insufficient withdrawable balance.");
        payable(msg.sender).transfer(_amount);
    }
}

```