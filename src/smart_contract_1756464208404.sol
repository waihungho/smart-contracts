Here's a smart contract in Solidity called "ChronoMetrics," designed with advanced concepts, a creative approach to protocol self-optimization, and trendy features like dynamic NFTs and adaptive governance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// No SafeMath needed for Solidity ^0.8.0 as it includes built-in overflow/underflow checks.

// --- Outline & Function Summary ---

// I. Core Infrastructure & Access Control
//    - Ownable: Standard administrative control for sensitive operations (e.g., emergency pause).
//    - Pausable: Allows the owner to pause/unpause critical functions during emergencies or upgrades.
//    - Events: For transparent logging of all significant actions, crucial for off-chain monitoring.
// II. Token Management (Native Token: `ChronoToken`)
//    - IERC20 token (`ChronoToken`): The primary utility, staking, and governance token of the protocol.
//    - `token`: Stores the address of the ChronoToken contract.
// III. Protocol Health Index (PHI) System
//    - `currentPHI`: A calculated score (0-10000 basis points) representing the overall health, engagement, and sustainability of the protocol. This is the core adaptive mechanism.
//    - `_epochMetrics`: Data structures to track various on-chain metrics (e.g., total staked volume, active stakers, governance participation) accumulated per epoch.
//    - `_userActivityMetrics`: Tracks individual user contributions to metrics for PHI calculation.
//    - `_updateUserActivityMetrics`: Internal function called on various user actions (staking, voting) to update metrics that feed into the PHI.
//    - `_calculateEpochPHI`: Core internal logic to aggregate epoch-specific metrics and derive the new PHI, acting as the "brain" for self-optimization.
// IV. Adaptive Parameters & Epoch Management
//    - `EpochManager`: Manages the progression of time in discrete "epochs," triggering PHI calculation and reward distribution.
//    - `protocolParameters`: A dynamic mapping storing key protocol settings (e.g., `stakingRewardRateBps`, `treasuryAllocationBps`, `proposalThresholdBps`) that can be adjusted.
//    - `proposeParameterAdjustment`: Allows qualified users or the system itself to suggest changes to these protocol parameters, often influenced by PHI performance.
//    - `voteOnParameterAdjustment`: Enables `ChronoToken` holders (with `ChronoFragment` bonuses) to vote on proposed parameter changes.
//    - `executeParameterAdjustment`: Applies the parameter change if the proposal passes governance.
// V. Staking & Rewards
//    - `stake`: Users deposit `ChronoToken` to participate, earn rewards, and gain voting power.
//    - `unstake`: Users withdraw their staked `ChronoToken`.
//    - `claimRewards`: Allows users to claim accumulated rewards from staking, calculated based on stake, epoch duration, PHI, and ChronoFragment power.
//    - `_globalRewardPerTokenAccumulator`: A global, continuously increasing value that tracks the total rewards per token staked over time, enabling a scalable "pull" reward system.
//    - `_userRewardDebt`: Tracks each user's last `_globalRewardPerTokenAccumulator` value to calculate their individual pending rewards.
//    - `_accumulateEpochRewards`: Internal function to update the global reward accumulator at the end of each epoch, reflecting PHI-adjusted reward rates.
// VI. ChronoFragment NFTs (Dynamic Reputation System)
//    - `ChronoFragments`: A custom `ERC721URIStorage` implementation for non-transferable, dynamic reputation NFTs. These signify user achievements and sustained positive behavior.
//    - `mintChronoFragment`: Awards a new `ChronoFragment` to a user for specific, predefined achievements (e.g., first 100 stakers, active voter).
//    - `upgradeChronoFragment`: Allows users to "evolve" or "level up" their `ChronoFragment` (changing its metadata/traits and associated power) based on continuous positive engagement.
//    - `getChronoFragmentPower`: Returns the additional voting power or reward multiplier conferred by a specific `ChronoFragment`.
//    - `_totalPowerHeldByAddress`: Stored within `ChronoFragments` to efficiently sum the power of all fragments held by a single address.
// VII. General Governance
//    - `createGeneralProposal`: Enables users to propose any general action or change not covered by parameter adjustments (e.g., treasury spending, external contract interactions).
//    - `voteOnGeneralProposal`: Standard voting mechanism for general proposals, also benefiting from `ChronoFragment` power.
//    - `executeGeneralProposal`: Executes the proposed action if the general proposal passes, utilizing low-level calls.
// VIII. Treasury Management
//    - `treasuryBalance`: Holds funds collected from protocol fees or other revenue streams, managed by governance.
//    - `_collectProtocolFees`: Internal function to accumulate fees into the treasury (placeholder, actual logic depends on fee sources).
//    - `initiateTreasuryWithdrawal`: Allows governance to withdraw funds from the treasury for approved initiatives (or emergency owner withdrawal).
// IX. View Functions
//    - A comprehensive set of public functions to query the state of the protocol, including current parameters, epoch details, user stakes, pending rewards, and `ChronoFragment` information.

// --- Function List (Total: 34 functions) ---
// I. Core Infrastructure & Access Control
// 1. constructor(address _tokenAddress, uint256 _initialEpochDuration)
// 2. pause()
// 3. unpause()
// 4. setMinStakeAmount(uint256 _amount)
// 5. setProposalQuorumBps(uint256 _quorumBps) - For parameter proposals
// 6. setGeneralProposalQuorumBps(uint256 _quorumBps) - For general proposals

// II. Protocol Health Index (PHI) & Epoch Management
// 7. advanceEpoch()
// 8. getCurrentEpoch()
// 9. _calculateEpochPHI() (internal)
// 10. getEpochDetails(uint256 _epochId)
// 11. getCurrentPHI()

// III. Adaptive Parameter Adjustments
// 12. proposeParameterAdjustment(string memory _paramName, int256 _newValue, string memory _rationale)
// 13. voteOnParameterAdjustment(uint256 _proposalId, bool _support)
// 14. executeParameterAdjustment(uint256 _proposalId)
// 15. getParameterProposalDetails(uint256 _proposalId)
// 16. getProtocolParameter(string memory _paramName)

// IV. Staking & Rewards
// 17. stake(uint256 _amount)
// 18. unstake(uint256 _amount)
// 19. claimRewards()
// 20. getPendingRewards(address _user)
// 21. getTotalStaked()
// 22. getStakedAmount(address _user)
// 23. getVotingPower(address _user)

// V. ChronoFragment NFTs (Reputation)
// 24. mintChronoFragment(address _recipient, ChronoFragmentType _fragmentType, string memory _tokenURI)
// 25. upgradeChronoFragment(uint256 _tokenId, ChronoFragmentType _newFragmentType, string memory _newTokenURI)
// 26. getChronoFragmentPower(uint256 _tokenId)
// 27. tokenURI(uint256 tokenId) (inherited from ERC721URIStorage)
// 28. balanceOf(address owner) (inherited from ERC721)

// VI. General Governance
// 29. createGeneralProposal(string memory _description, bytes memory _calldata, address _target)
// 30. voteOnGeneralProposal(uint256 _proposalId, bool _support)
// 31. executeGeneralProposal(uint256 _proposalId)
// 32. getGeneralProposalDetails(uint256 _proposalId)

// VII. Treasury
// 33. initiateTreasuryWithdrawal(address _to, uint256 _amount)
// 34. getTreasuryBalance()


// --- ChronoFragmentType Enum ---
// Defines different types/levels of ChronoFragment NFTs.
// Each type confers a specific `fragmentTypePowerBps` (e.g., voting power multiplier, reward bonus).
enum ChronoFragmentType {
    NONE,               // Default/base type, should not be minted
    PARTICIPANT,        // Awarded for initial engagement (e.g., first stake)
    GOVERNOR,           // Awarded for active governance participation
    LONG_TERM_STAKER,   // Awarded for sustained staking over multiple epochs
    ECOSYSTEM_LEADER    // Highest tier, for significant, long-term contributions
}

// --- ChronoFragments NFT Contract ---
// This contract manages the non-transferable, dynamic reputation NFTs.
// It tracks their type, URI, and the total power they confer to their owner.
contract ChronoFragments is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter; // Counter for unique token IDs

    mapping(uint256 => ChronoFragmentType) private _fragmentTypes; // Maps token ID to its fragment type
    mapping(ChronoFragmentType => uint256) public fragmentTypePowerBps; // Base power for each fragment type (in basis points)
    mapping(address => uint256) private _totalPowerHeldByAddress; // Sum of power from all fragments held by an address

    // Custom errors for transfer and burn restrictions
    error ChronoFragment_NonTransferable();
    error ChronoFragment_BurnRestricted();

    constructor() ERC721("ChronoFragment", "CHRONOF") {
        // Initialize base power multipliers for each fragment type (10000 = 1x, 10100 = 1.01x, etc.)
        fragmentTypePowerBps[ChronoFragmentType.NONE] = 10000;
        fragmentTypePowerBps[ChronoFragmentType.PARTICIPANT] = 10100; // 1% bonus
        fragmentTypePowerBps[ChronoFragmentType.GOVERNOR] = 10250;    // 2.5% bonus
        fragmentTypePowerBps[ChronoFragmentType.LONG_TERM_STAKER] = 10500; // 5% bonus
        fragmentTypePowerBps[ChronoFragmentType.ECOSYSTEM_LEADER] = 11000; // 10% bonus
    }

    // Overrides ERC721's _transfer function to prevent any transfers, making tokens non-transferable.
    function _transfer(address from, address to, uint256 tokenId) internal pure override {
        revert ChronoFragment_NonTransferable();
    }

    // Overrides ERC721's _burn function.
    // Allows burning, but first adjusts the owner's total power.
    function _burn(uint256 tokenId) internal override {
        address owner_ = ownerOf(tokenId); // Get owner before burning
        require(owner_ != address(0), "ChronoFragment: Burn from the zero address");
        _totalPowerHeldByAddress[owner_] -= fragmentTypePowerBps[_fragmentTypes[tokenId]]; // Deduct power
        super._burn(tokenId); // Call parent burn
        delete _fragmentTypes[tokenId]; // Clean up fragment type mapping
    }

    // Mints a new ChronoFragment NFT. Only callable internally (e.g., by ChronoMetrics contract).
    function mint(address to, ChronoFragmentType fragmentType, string memory uri) internal returns (uint256) {
        require(fragmentType != ChronoFragmentType.NONE, "ChronoFragment: Cannot mint NONE type");
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId); // Mints the token
        _setTokenURI(newTokenId, uri); // Sets the metadata URI
        _fragmentTypes[newTokenId] = fragmentType; // Assigns the type
        _totalPowerHeldByAddress[to] += fragmentTypePowerBps[fragmentType]; // Update total power for owner
        return newTokenId;
    }

    // Upgrades an existing ChronoFragment NFT. Only callable internally.
    // Changes the fragment type and URI, and updates the owner's total power.
    function upgrade(uint256 tokenId, ChronoFragmentType newFragmentType, string memory newUri) internal {
        require(_exists(tokenId), "ChronoFragment: token not found");
        ChronoFragmentType oldFragmentType = _fragmentTypes[tokenId];
        require(uint256(newFragmentType) >= uint256(oldFragmentType), "ChronoFragment: cannot downgrade fragment or mint same type");

        address owner_ = ownerOf(tokenId);
        // Deduct old power and add new power for the owner
        _totalPowerHeldByAddress[owner_] -= fragmentTypePowerBps[oldFragmentType];
        _totalPowerHeldByAddress[owner_] += fragmentTypePowerBps[newFragmentType];

        _setTokenURI(tokenId, newUri); // Update metadata URI
        _fragmentTypes[tokenId] = newFragmentType; // Update fragment type
    }

    // Returns the ChronoFragmentType of a given token ID.
    function getFragmentType(uint256 tokenId) public view returns (ChronoFragmentType) {
        return _fragmentTypes[tokenId];
    }

    // Returns the total aggregated power of all ChronoFragments held by an address.
    function getTotalPowerOf(address _user) public view returns (uint256) {
        return _totalPowerHeldByAddress[_user];
    }

    // Base URI for token metadata. Individual token URIs are set upon minting/upgrading.
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://chronof_metadata/";
    }
}


// --- ChronoMetrics Main Protocol Contract ---
// The core contract for the ChronoMetrics ecosystem.
contract ChronoMetrics is Ownable, Pausable {
    using Counters for Counters.Counter;

    IERC20 public immutable token; // The ChronoToken (ERC20) contract
    ChronoFragments public immutable chronoFragments; // The ChronoFragment (ERC721) contract

    // --- Epoch Management ---
    uint256 public currentEpoch; // Current epoch number
    uint256 public lastEpochAdvanceTime; // Timestamp of the last epoch advance
    uint256 public epochDuration; // Duration of an epoch in seconds

    // --- Protocol Parameters (Adaptive) ---
    mapping(string => uint256) public protocolParameters; // Stores dynamically adjustable parameters
    uint256 public constant BASIS_POINTS_DIVISOR = 10000; // Constant for basis point calculations (100% = 10000)

    // --- Staking ---
    mapping(address => uint256) public stakedAmounts; // User => Staked amount
    uint256 public totalStakedAmount; // Total amount of ChronoTokens staked in the protocol
    uint256 public minStakeAmount; // Minimum amount required to stake

    // --- Rewards (Pull-based system) ---
    mapping(address => uint256) public earnedRewards; // User => Unclaimed accumulated rewards
    uint256 private _globalRewardPerTokenAccumulator; // Global accumulator of rewards per token (scaled)
    mapping(address => uint256) private _userRewardDebt; // User's last `_globalRewardPerTokenAccumulator` value

    // --- Protocol Health Index (PHI) ---
    uint256 public currentPHI; // The Protocol Health Index for the *current* epoch (calculated from previous epoch's metrics)

    // Structure to store historical metrics for each epoch
    struct EpochMetrics {
        uint256 totalStakedVolume; // Snapshot of total staked at epoch end
        uint256 activeStakersCount; // Number of unique stakers in the epoch
        uint256 governanceParticipationCount; // Number of unique voters in the epoch
        uint256 estimatedTotalFragmentPower; // Estimated total power from fragments for PHI calculation
    }
    mapping(uint256 => EpochMetrics) public epochHistoricalMetrics; // Historical metrics for past epochs
    mapping(address => bool) private _activeStakersThisEpoch; // Tracks unique active stakers per epoch
    mapping(address => bool) private _votersThisEpoch; // Tracks unique voters per epoch
    Counters.Counter private _activeStakersCounter; // Counter for unique active stakers
    Counters.Counter private _votersCounter; // Counter for unique voters


    // --- Governance (Parameter Adjustments) ---
    Counters.Counter public parameterProposalCounter; // Counter for parameter adjustment proposals
    struct ParameterProposal {
        string paramName;
        int256 newValue; // Can be negative for percentage adjustments if logic supports it
        string rationale;
        uint256 startEpoch;
        uint256 endEpoch; // Epoch when voting ends
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User => If voted on this specific proposal
        bool executed;
        bool approved;
        address proposer;
    }
    mapping(uint256 => ParameterProposal) public parameterProposals;
    uint256 public parameterProposalQuorumBps; // Quorum required for parameter proposals (e.g., 2000 = 20%)

    // --- Governance (General Proposals) ---
    Counters.Counter public generalProposalCounter; // Counter for general proposals
    struct GeneralProposal {
        string description;
        address target; // Target contract for the execution call
        bytes calldataPayload; // Calldata for the execution call
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool approved;
        address proposer;
    }
    mapping(uint256 => GeneralProposal) public generalProposals;
    uint256 public generalProposalQuorumBps; // Quorum required for general proposals

    // --- Treasury ---
    uint256 public treasuryBalance; // Holds collected fees and allocations

    // --- Events ---
    event EpochAdvanced(uint256 indexed epochId, uint256 newPHI, uint256 timestamp);
    event TokensStaked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 newTotalStaked);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ParameterAdjustmentProposed(uint256 indexed proposalId, string paramName, int256 newValue, address indexed proposer);
    event ParameterAdjustmentVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterAdjustmentExecuted(uint256 indexed proposalId, string paramName, uint256 newValue);
    event GeneralProposalCreated(uint256 indexed proposalId, string description, address indexed target, address indexed proposer);
    event GeneralProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event GeneralProposalExecuted(uint256 indexed proposalId);
    event ChronoFragmentMinted(address indexed recipient, uint256 indexed tokenId, ChronoFragmentType fragmentType, string uri);
    event ChronoFragmentUpgraded(uint256 indexed tokenId, ChronoFragmentType oldType, ChronoFragmentType newType, string newUri);
    event TreasuryWithdrawalInitiated(uint256 indexed proposalId, address indexed to, uint256 amount);


    // --- Constructor ---
    // Initializes the ChronoMetrics protocol with its associated token and initial parameters.
    constructor(address _tokenAddress, uint256 _initialEpochDuration) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "ChronoMetrics: Token address cannot be zero");
        require(_initialEpochDuration > 0, "ChronoMetrics: Epoch duration must be positive");

        token = IERC20(_tokenAddress);
        chronoFragments = new ChronoFragments(); // Deploy ChronoFragment contract

        epochDuration = _initialEpochDuration; // e.g., 7 days (604800 seconds)
        currentEpoch = 0; // Initialize with epoch 0
        lastEpochAdvanceTime = block.timestamp;

        // Set initial adaptive protocol parameters
        protocolParameters["stakingRewardRateBps"] = 500; // 5% base reward rate (per epoch, annual, etc. depends on _accumulateEpochRewards logic)
        protocolParameters["treasuryAllocationBps"] = 1000; // 10% of collected fees go to treasury
        protocolParameters["proposalThresholdBps"] = 100; // 1% of total staked tokens needed to create a proposal
        protocolParameters["votingDurationEpochs"] = 1; // Proposals last for 1 epoch

        minStakeAmount = 100 * 10**18; // Example: 100 tokens (assuming 18 decimals)
        parameterProposalQuorumBps = 2000; // 20% quorum for parameter proposals
        generalProposalQuorumBps = 2500; // 25% quorum for general proposals
        currentPHI = 5000; // Initial PHI (e.g., 50% health, out of 10000 basis points)
    }

    // --- Core Infrastructure & Access Control (Functions 1-6) ---

    // 1. constructor: (See above)

    // 2. Pauses the protocol. Only callable by the owner.
    function pause() public override onlyOwner {
        _pause();
    }

    // 3. Unpauses the protocol. Only callable by the owner.
    function unpause() public override onlyOwner {
        _unpause();
    }

    // 4. Sets the minimum stake amount. Only callable by the owner.
    function setMinStakeAmount(uint256 _amount) public onlyOwner {
        minStakeAmount = _amount;
    }

    // 5. Sets the quorum percentage for parameter adjustment proposals. Only callable by owner.
    function setProposalQuorumBps(uint256 _quorumBps) public onlyOwner {
        require(_quorumBps <= BASIS_POINTS_DIVISOR, "ChronoMetrics: Quorum cannot exceed 100%");
        parameterProposalQuorumBps = _quorumBps;
    }
    
    // 6. Sets the quorum percentage for general proposals. Only callable by owner.
    function setGeneralProposalQuorumBps(uint256 _quorumBps) public onlyOwner {
        require(_quorumBps <= BASIS_POINTS_DIVISOR, "ChronoMetrics: Quorum cannot exceed 100%");
        generalProposalQuorumBps = _quorumBps;
    }

    // --- Internal User Activity Metric Update ---
    // Updates metrics contributing to PHI calculation when users stake or vote.
    function _updateUserActivityMetrics(address _user) internal {
        // Track unique active stakers for the current epoch
        if (!_activeStakersThisEpoch[_user]) {
            _activeStakersThisEpoch[_user] = true;
            _activeStakersCounter.increment();
        }
    }

    // Updates metrics for governance participation.
    function _updateVoterMetrics(address _user) internal {
        if (!_votersThisEpoch[_user]) {
            _votersThisEpoch[_user] = true;
            _votersCounter.increment();
        }
    }

    // --- Protocol Health Index (PHI) & Epoch Management (Functions 7-11) ---

    // 7. Advances the protocol to the next epoch. Can be called by anyone, but restricted by epoch duration.
    // Triggers PHI calculation, reward accumulation, and cleans up epoch metrics.
    function advanceEpoch() public whenNotPaused {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "ChronoMetrics: Epoch not yet ended.");

        // Before advancing, record metrics for the *just ended* epoch (which is `currentEpoch`)
        EpochMetrics storage currentEpochMetrics = epochHistoricalMetrics[currentEpoch];
        currentEpochMetrics.totalStakedVolume = totalStakedAmount; // Snapshot total staked
        currentEpochMetrics.activeStakersCount = _activeStakersCounter.current();
        currentEpochMetrics.governanceParticipationCount = _votersCounter.current();
        // Estimated total fragment power: for simplicity, we assume an average power for each active staker,
        // or a more complex oracle/snapshot would provide this.
        currentEpochMetrics.estimatedTotalFragmentPower = chronoFragments.getTotalPowerOf(address(this)); // This is a proxy. A true value needs to sum actual user's fragment power.

        // 9. Calculate the new PHI for the *upcoming* epoch based on the metrics of the *just ended* epoch
        currentPHI = _calculateEpochPHI(currentEpochMetrics);

        // Update the global reward per token accumulator for the just-ended epoch.
        // This makes rewards available for stakers to claim.
        _accumulateEpochRewards();

        currentEpoch++; // Advance to the next epoch
        lastEpochAdvanceTime = block.timestamp;

        // Reset metrics for the new epoch
        delete _activeStakersThisEpoch; // Reset mapping
        _activeStakersCounter.reset();
        delete _votersThisEpoch;
        _votersCounter.reset();

        emit EpochAdvanced(currentEpoch - 1, currentPHI, block.timestamp);
    }

    // 8. Returns the current epoch number.
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    // 9. Internal function to calculate the Protocol Health Index (PHI).
    // This is a simplified example; a real PHI would involve more complex weighting and normalization,
    // potentially with off-chain data via oracles.
    function _calculateEpochPHI(EpochMetrics memory metrics) internal view returns (uint256) {
        if (metrics.totalStakedVolume == 0 && metrics.activeStakersCount == 0) return 0; // Prevent division by zero

        // Example max values for normalization (these would ideally be dynamically adjusted or governance-set)
        uint256 maxStakedVolume = 1_000_000_000 * 10**18; // Example: 1 billion tokens
        uint256 maxActiveStakers = 100_000;
        uint256 maxGovernanceParticipation = 10_000;
        uint256 maxFragmentPower = maxActiveStakers * chronoFragments.fragmentTypePowerBps[ChronoFragmentType.ECOSYSTEM_LEADER]; // Max possible from leaders

        uint256 stakedScore = (metrics.totalStakedVolume * BASIS_POINTS_DIVISOR) / maxStakedVolume;
        uint256 activeScore = (metrics.activeStakersCount * BASIS_POINTS_DIVISOR) / maxActiveStakers;
        uint256 govScore = (metrics.governanceParticipationCount * BASIS_POINTS_DIVISOR) / maxGovernanceParticipation;
        uint256 fragmentScore = (metrics.estimatedTotalFragmentPower * BASIS_POINTS_DIVISOR) / maxFragmentPower;

        // Cap scores at BASIS_POINTS_DIVISOR (100%)
        stakedScore = stakedScore > BASIS_POINTS_DIVISOR ? BASIS_POINTS_DIVISOR : stakedScore;
        activeScore = activeScore > BASIS_POINTS_DIVISOR ? BASIS_POINTS_DIVISOR : activeScore;
        govScore = govScore > BASIS_POINTS_DIVISOR ? BASIS_POINTS_DIVISOR : govScore;
        fragmentScore = fragmentScore > BASIS_POINTS_DIVISOR ? BASIS_POINTS_DIVISOR : fragmentScore;

        // Weighted average for PHI (example weights, sum to BASIS_POINTS_DIVISOR = 10000)
        uint256 phi = (stakedScore * 3000 + // 30%
                       activeScore * 2500 + // 25%
                       govScore * 2500 +    // 25%
                       fragmentScore * 2000) // 20%
                       / BASIS_POINTS_DIVISOR; // Normalize back to 0-10000

        // Ensure PHI is within bounds (0-10000)
        return phi > BASIS_POINTS_DIVISOR ? BASIS_POINTS_DIVISOR : phi;
    }

    // 10. Returns detailed metrics for a specific epoch.
    function getEpochDetails(uint256 _epochId) public view returns (EpochMetrics memory) {
        require(_epochId <= currentEpoch, "ChronoMetrics: Epoch not yet started");
        return epochHistoricalMetrics[_epochId];
    }

    // 11. Returns the current Protocol Health Index (PHI).
    function getCurrentPHI() public view returns (uint256) {
        return currentPHI;
    }

    // --- Adaptive Parameter Adjustments (Functions 12-16) ---

    // 12. Proposes an adjustment to a protocol parameter.
    // Can be called by anyone meeting the `proposalThresholdBps` (staked tokens).
    function proposeParameterAdjustment(
        string memory _paramName,
        int256 _newValue,
        string memory _rationale
    ) public whenNotPaused {
        require(stakedAmounts[msg.sender] >= totalStakedAmount * protocolParameters["proposalThresholdBps"] / BASIS_POINTS_DIVISOR,
            "ChronoMetrics: Not enough staked tokens to propose.");
        require(bytes(_paramName).length > 0, "ChronoMetrics: Param name cannot be empty");

        parameterProposalCounter.increment();
        uint256 proposalId = parameterProposalCounter.current();

        parameterProposals[proposalId] = ParameterProposal({
            paramName: _paramName,
            newValue: _newValue,
            rationale: _rationale,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + protocolParameters["votingDurationEpochs"],
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize inline
            executed: false,
            approved: false,
            proposer: msg.sender
        });

        emit ParameterAdjustmentProposed(proposalId, _paramName, _newValue, msg.sender);
    }

    // 13. Allows users to vote on a parameter adjustment proposal.
    function voteOnParameterAdjustment(uint256 _proposalId, bool _support) public whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(bytes(proposal.paramName).length > 0, "ChronoMetrics: Proposal does not exist");
        require(currentEpoch >= proposal.startEpoch && currentEpoch < proposal.endEpoch, "ChronoMetrics: Voting period ended or not started");
        require(!proposal.hasVoted[msg.sender], "ChronoMetrics: Already voted on this proposal");
        require(stakedAmounts[msg.sender] > 0, "ChronoMetrics: Must have staked tokens to vote");

        // Voting power includes staked tokens and ChronoFragment bonus
        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "ChronoMetrics: User has no effective voting power");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;
        _updateVoterMetrics(msg.sender); // Update governance participation metric

        emit ParameterAdjustmentVoted(_proposalId, msg.sender, _support);
    }

    // 14. Executes a passed parameter adjustment proposal.
    // Can be called by anyone once the voting period has ended and conditions are met.
    function executeParameterAdjustment(uint256 _proposalId) public whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        require(bytes(proposal.paramName).length > 0, "ChronoMetrics: Proposal does not exist");
        require(currentEpoch >= proposal.endEpoch, "ChronoMetrics: Voting period not ended");
        require(!proposal.executed, "ChronoMetrics: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= totalStakedAmount * parameterProposalQuorumBps / BASIS_POINTS_DIVISOR, "ChronoMetrics: Quorum not met");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.approved = true;
            // Apply the parameter change based on the parameter name
            // For now, assume newValue is a direct replacement for positive parameters.
            // More complex logic (e.g., adding/subtracting for negative newValue) could be added here.
            require(proposal.newValue >= 0, "ChronoMetrics: New value for this parameter must be non-negative");
            protocolParameters[proposal.paramName] = uint256(proposal.newValue);
            emit ParameterAdjustmentExecuted(_proposalId, proposal.paramName, protocolParameters[proposal.paramName]);
        }
        proposal.executed = true;
    }

    // 15. Returns details of a parameter adjustment proposal.
    function getParameterProposalDetails(uint256 _proposalId) public view returns (
        string memory paramName,
        int256 newValue,
        string memory rationale,
        uint256 startEpoch,
267        uint256 endEpoch,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool approved,
        address proposer
    ) {
        ParameterProposal storage proposal = parameterProposals[_proposalId];
        return (
            proposal.paramName,
            proposal.newValue,
            proposal.rationale,
            proposal.startEpoch,
            proposal.endEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.approved,
            proposal.proposer
        );
    }

    // 16. Returns the current value of a protocol parameter.
    function getProtocolParameter(string memory _paramName) public view returns (uint256) {
        return protocolParameters[_paramName];
    }

    // --- Staking & Rewards (Functions 17-23) ---

    // Internal helper function to update user's reward debt and calculate pending rewards.
    // Must be called before any stake/unstake/claim action to ensure accurate reward calculation.
    function _updateUserRewardDebt(address _user) internal {
        // Only update if user has staked amount
        if (stakedAmounts[_user] > 0) {
            // Calculate rewards accrued since last update based on global accumulator
            uint256 currentAccRewards = stakedAmounts[_user] * (_globalRewardPerTokenAccumulator - _userRewardDebt[_user]) / BASIS_POINTS_DIVISOR;
            
            // Apply ChronoFragment bonus power as a reward multiplier
            uint256 fragmentBonusPowerBps = chronoFragments.getTotalPowerOf(_user); // Get total bonus power
            currentAccRewards = currentAccRewards * fragmentBonusPowerBps / BASIS_POINTS_DIVISOR;

            earnedRewards[_user] += currentAccRewards;
        }
        _userRewardDebt[_user] = _globalRewardPerTokenAccumulator; // Update user's debt to current global value
    }

    // Internal function to update the global reward per token accumulator.
    // Called at the end of each epoch to reflect epoch-specific rewards.
    function _accumulateEpochRewards() internal {
        uint256 baseRewardRateBps = protocolParameters["stakingRewardRateBps"];
        uint256 totalRewardPool = totalStakedAmount * baseRewardRateBps / BASIS_POINTS_DIVISOR;

        // Scale reward pool by current PHI: higher PHI implies more rewards generated
        uint256 effectiveTotalRewardPool = totalRewardPool * currentPHI / BASIS_POINTS_DIVISOR;

        if (totalStakedAmount == 0 || effectiveTotalRewardPool == 0) return;

        // Calculate how much reward to add per staked token to the global accumulator
        uint256 rewardPerTokenThisEpoch = effectiveTotalRewardPool * BASIS_POINTS_DIVISOR / totalStakedAmount;
        _globalRewardPerTokenAccumulator += rewardPerTokenThisEpoch;
    }

    // 17. Allows users to stake ChronoTokens.
    function stake(uint256 _amount) public whenNotPaused {
        _updateUserRewardDebt(msg.sender); // Update rewards before changing stake
        require(_amount >= minStakeAmount, "ChronoMetrics: Amount too low to stake");
        require(token.transferFrom(msg.sender, address(this), _amount), "ChronoMetrics: Token transfer failed");

        stakedAmounts[msg.sender] += _amount;
        totalStakedAmount += _amount;
        _updateUserActivityMetrics(msg.sender); // Update active staker metrics

        emit TokensStaked(msg.sender, _amount, totalStakedAmount);
    }

    // 18. Allows users to unstake ChronoTokens.
    function unstake(uint256 _amount) public whenNotPaused {
        _updateUserRewardDebt(msg.sender); // Update rewards before changing stake
        require(stakedAmounts[msg.sender] >= _amount, "ChronoMetrics: Insufficient staked amount");

        stakedAmounts[msg.sender] -= _amount;
        totalStakedAmount -= _amount;

        require(token.transfer(msg.sender, _amount), "ChronoMetrics: Token transfer failed");

        emit TokensUnstaked(msg.sender, _amount, totalStakedAmount);
    }

    // 19. Allows users to claim their accumulated rewards.
    function claimRewards() public whenNotPaused {
        _updateUserRewardDebt(msg.sender); // Ensure rewards are up-to-date
        uint256 rewards = earnedRewards[msg.sender];
        require(rewards > 0, "ChronoMetrics: No rewards to claim");

        earnedRewards[msg.sender] = 0; // Reset claimed rewards
        require(token.transfer(msg.sender, rewards), "ChronoMetrics: Reward transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }

    // 20. Returns the pending rewards for a specific user.
    function getPendingRewards(address _user) public view returns (uint256) {
        uint256 pending = earnedRewards[_user];
        if (stakedAmounts[_user] > 0) {
            // Calculate rewards accrued since last update (or beginning)
            uint256 currentAccRewards = stakedAmounts[_user] * (_globalRewardPerTokenAccumulator - _userRewardDebt[_user]) / BASIS_POINTS_DIVISOR;
            uint256 fragmentBonusPowerBps = chronoFragments.getTotalPowerOf(_user);
            currentAccRewards = currentAccRewards * fragmentBonusPowerBps / BASIS_POINTS_DIVISOR;
            pending += currentAccRewards;
        }
        return pending;
    }

    // 21. Returns the total amount of tokens staked in the protocol.
    function getTotalStaked() public view returns (uint256) {
        return totalStakedAmount;
    }

    // 22. Returns the amount of tokens staked by a specific user.
    function getStakedAmount(address _user) public view returns (uint256) {
        return stakedAmounts[_user];
    }

    // 23. Returns the total voting power of a user (staked amount + ChronoFragment bonus).
    function getVotingPower(address _user) public view returns (uint256) {
        // Base voting power is staked amount. Add bonus from ChronoFragments.
        return stakedAmounts[_user] + chronoFragments.getTotalPowerOf(_user);
    }

    // --- ChronoFragment NFTs (Reputation) (Functions 24-28) ---

    // 24. Mints a new ChronoFragment NFT to a recipient.
    // Callable only by the contract owner (ChronoMetrics itself or its governance).
    // The actual criteria for minting (e.g., active for X epochs) would be checked externally
    // or by a more complex governance process initiating this call.
    function mintChronoFragment(address _recipient, ChronoFragmentType _fragmentType, string memory _tokenURI) public onlyOwner whenNotPaused {
        require(_recipient != address(0), "ChronoMetrics: Recipient cannot be zero address");
        uint256 tokenId = chronoFragments.mint(_recipient, _fragmentType, _tokenURI);
        emit ChronoFragmentMinted(_recipient, tokenId, _fragmentType, _tokenURI);
    }

    // 25. Upgrades an existing ChronoFragment NFT.
    // Callable by the fragment owner (msg.sender) if they meet criteria, or by contract owner.
    // The criteria for upgrade (e.g., more active participation, sustained staking) would be
    // evaluated and `_newFragmentType` and `_newTokenURI` would be decided accordingly.
    function upgradeChronoFragment(uint256 _tokenId, ChronoFragmentType _newFragmentType, string memory _newTokenURI) public whenNotPaused {
        address fragmentOwner = chronoFragments.ownerOf(_tokenId);
        require(fragmentOwner == msg.sender || owner() == msg.sender, "ChronoMetrics: Not authorized to upgrade this fragment");
        
        // Ensure the upgrade is valid (e.g., `_newFragmentType` is a higher tier)
        ChronoFragmentType currentType = chronoFragments.getFragmentType(_tokenId);
        require(uint256(_newFragmentType) > uint256(currentType), "ChronoMetrics: Cannot downgrade or re-mint same fragment type");

        chronoFragments.upgrade(_tokenId, _newFragmentType, _newTokenURI);
        emit ChronoFragmentUpgraded(_tokenId, currentType, _newFragmentType, _newTokenURI);
    }

    // 26. Returns the base power (in basis points) conferred by a specific ChronoFragment type.
    function getChronoFragmentPower(uint256 _tokenId) public view returns (uint256) {
        return chronoFragments.fragmentTypePowerBps[chronoFragments.getFragmentType(_tokenId)];
    }

    // 27. tokenURI(uint256 tokenId) (Inherited from ERC721URIStorage and publically accessible)
    // 28. balanceOf(address owner) (Inherited from ERC721 and publically accessible)

    // --- General Governance (Functions 29-32) ---

    // 29. Creates a general proposal for actions like treasury spending or external contract calls.
    // Requires a minimum staked amount.
    function createGeneralProposal(
        string memory _description,
        bytes memory _calldata,
        address _target
    ) public whenNotPaused {
        require(stakedAmounts[msg.sender] >= totalStakedAmount * protocolParameters["proposalThresholdBps"] / BASIS_POINTS_DIVISOR,
            "ChronoMetrics: Not enough staked tokens to propose.");
        require(_target != address(0), "ChronoMetrics: Target address cannot be zero");
        require(bytes(_description).length > 0, "ChronoMetrics: Description cannot be empty");

        generalProposalCounter.increment();
        uint256 proposalId = generalProposalCounter.current();

        generalProposals[proposalId] = GeneralProposal({
            description: _description,
            target: _target,
            calldataPayload: _calldata,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + protocolParameters["votingDurationEpochs"],
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            approved: false,
            proposer: msg.sender
        });

        emit GeneralProposalCreated(proposalId, _description, _target, msg.sender);
    }

    // 30. Allows users to vote on a general proposal.
    function voteOnGeneralProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        GeneralProposal storage proposal = generalProposals[_proposalId];
        require(bytes(proposal.description).length > 0, "ChronoMetrics: Proposal does not exist");
        require(currentEpoch >= proposal.startEpoch && currentEpoch < proposal.endEpoch, "ChronoMetrics: Voting period ended or not started");
        require(!proposal.hasVoted[msg.sender], "ChronoMetrics: Already voted on this proposal");
        require(stakedAmounts[msg.sender] > 0, "ChronoMetrics: Must have staked tokens to vote");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "ChronoMetrics: User has no effective voting power");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;
        _updateVoterMetrics(msg.sender); // Update governance participation metric

        emit GeneralProposalVoted(_proposalId, msg.sender, _support);
    }

    // 31. Executes a passed general proposal.
    // For safety, execution logic is performed via a low-level call.
    function executeGeneralProposal(uint256 _proposalId) public whenNotPaused {
        GeneralProposal storage proposal = generalProposals[_proposalId];
        require(bytes(proposal.description).length > 0, "ChronoMetrics: Proposal does not exist");
        require(currentEpoch >= proposal.endEpoch, "ChronoMetrics: Voting period not ended");
        require(!proposal.executed, "ChronoMetrics: Proposal already executed");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= totalStakedAmount * generalProposalQuorumBps / BASIS_POINTS_DIVISOR, "ChronoMetrics: Quorum not met");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.approved = true;
            // Execute the payload on the target contract
            (bool success, ) = proposal.target.call(proposal.calldataPayload);
            require(success, "ChronoMetrics: Proposal execution failed");
            emit GeneralProposalExecuted(_proposalId);
        }
        proposal.executed = true;
    }

    // 32. Returns details of a general proposal.
    function getGeneralProposalDetails(uint256 _proposalId) public view returns (
        string memory description,
        address target,
        bytes memory calldataPayload,
        uint256 startEpoch,
        uint256 endEpoch,
        uint256 votesFor,
        uint256 votesAgainst,
        bool executed,
        bool approved,
        address proposer
    ) {
        GeneralProposal storage proposal = generalProposals[_proposalId];
        return (
            proposal.description,
            proposal.target,
            proposal.calldataPayload,
            proposal.startEpoch,
            proposal.endEpoch,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.approved,
            proposal.proposer
        );
    }

    // --- Treasury Management (Functions 33-34) ---

    // Internal function to collect fees from various protocol activities into the treasury.
    // This is a placeholder; actual fee collection logic would be integrated into specific actions.
    function _collectProtocolFees(uint256 _amount) internal {
        // Example: If a transaction generates `_amount` in fees, a percentage goes to the treasury.
        treasuryBalance += _amount * protocolParameters["treasuryAllocationBps"] / BASIS_POINTS_DIVISOR;
    }

    // 33. Initiates a withdrawal from the treasury.
    // This function is `onlyOwner` for emergency, but typically executed via a `GeneralProposal`
    // where `target` is this contract (`ChronoMetrics`) and `calldataPayload` calls this function.
    function initiateTreasuryWithdrawal(address _to, uint256 _amount) public onlyOwner whenNotPaused {
        require(_to != address(0), "ChronoMetrics: Recipient cannot be zero");
        require(treasuryBalance >= _amount, "ChronoMetrics: Insufficient treasury balance");

        treasuryBalance -= _amount;
        require(token.transfer(_to, _amount), "ChronoMetrics: Treasury withdrawal failed");

        emit TreasuryWithdrawalInitiated(0, _to, _amount); // Proposal ID 0 for direct owner withdrawal
    }

    // 34. Returns the current balance of the protocol treasury.
    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    // Allows the contract to receive native currency (e.g., ETH).
    // Not directly used by ChronoToken, but good practice for future extensibility.
    receive() external payable {
        // Can add logic here if ETH is expected, e.g., to convert to ChronoToken or transfer to treasury.
    }
}
```