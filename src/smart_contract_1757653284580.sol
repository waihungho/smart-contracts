```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/*
    Smart Contract: Ethereal Echoes: Algorithmic Generative Content & Curation Network

    This contract establishes a decentralized platform for **Algorithmic Content Modules (ACMs)**.
    ACMs are external smart contracts that implement the `IEchoModule` interface. They are designed to
    generate unique "Echoes" (content hashes) based on user requests and dynamic parameters.

    The platform integrates advanced concepts:

    1.  Subscription-based Access: Users pay the native `ECHO` token to subscribe to ACMs,
        granting them the ability to generate Echoes from those modules.
    2.  Dynamic Module Evolution: ACM parameters can be influenced by DAO-like governance decisions
        (e.g., proposal voting for new modules, platform fee adjustments) and verifiable off-chain
        "AI Oracle" inputs (e.g., a conceptual "mood seed" or "trend" hash).
    3.  Proof-of-Curiosity Curation: Users can stake the native `ECHO` token on Echoes they find
        significant or promising. This mechanism acts as early-stage curation, signaling potential
        value. Successful early curators are rewarded from platform fees.
    4.  Content Lineage & Refinement: Users can create derivative Echoes from existing ones, providing
        new parameters. This establishes a traceable lineage, showing how content evolves.
    5.  Deflationary Boosting: Users can burn `ECHO` tokens to temporarily boost an ACM's visibility
        or influence its internal parameters, adding a unique deflationary mechanism.
    6.  Decentralized Governance: A lightweight governance system allows `ECHO` token holders to
        propose and vote on new ACMs. (For simplicity, `Ownable` is used for core administrative
        functions, but module approval is community-driven).

    ---

    Outline:

    1.  Pragma, License, Imports
    2.  Interfaces: `IEchoModule`
    3.  Errors
    4.  Events
    5.  Structs:
        *   `Module`: Details about an approved Algorithmic Content Module.
        *   `ModuleProposal`: Details for a module awaiting community approval.
        *   `Subscription`: User's access details for a specific module.
        *   `Echo`: Details of a generated content hash.
        *   `Curation`: User's stake on an Echo (Proof-of-Curiosity).
        *   `OracleInput`: Timestamped and signed data from an external oracle.
        *   `GovernanceParams`: Configurable parameters for module proposal voting.
    6.  State Variables: Core platform settings, counters, mappings for all structs.
    7.  Modifiers: Custom checks for subscription, module status, etc.
    8.  Constructor
    9.  Core Platform Management (Governance & Admin)
    10. Module Lifecycle & Configuration
    11. Echo Generation & Interaction
    12. Curation & Reward System
    13. Oracle Integration
    14. User & Information Retrieval (View Functions)

    ---

    Function Summary (24 Functions):

    I. Core Platform Management (Governance & Admin)
    1.  `constructor(address _echoTokenAddress)`: Initializes the contract with the native ECHO token.
    2.  `setPlatformFeeRate(uint256 _newFeeRate)`: Sets the percentage of subscription revenue taken as platform fees. (Owner)
    3.  `withdrawPlatformFees()`: Allows the owner to withdraw accumulated platform fees. (Owner)
    4.  `updateGovernanceParameters(uint256 _votingPeriod, uint256 _quorumPercentage, uint256 _minStakeForProposal)`: Updates parameters for module proposals (e.g., voting duration, quorum, proposal cost). (Owner)
    5.  `proposeModule(address _moduleAddress, string memory _name, string memory _description)`: Initiates a proposal for a new Algorithmic Content Module. Requires `_minStakeForProposal` ECHO to be staked.
    6.  `voteOnModuleProposal(uint256 _proposalId, bool _approve)`: Allows ECHO token holders to vote on active module proposals (approve or reject).
    7.  `finalizeModuleProposal(uint256 _proposalId)`: Finalizes a module proposal, approving or rejecting the module based on accumulated votes and quorum.

    II. Module Lifecycle & Configuration
    8.  `deprecateModule(uint256 _moduleId)`: Proposes to deprecate an existing ACM. (Owner/DAO function, simple for now)
    9.  `burnECHOForModuleBoost(uint256 _moduleId, uint256 _amount)`: Allows users to burn ECHO tokens to temporarily boost a module's visibility or influence its parameters.

    III. Echo Generation & Interaction
    10. `subscribeToModule(uint256 _moduleId, uint256 _duration)`: User pays ECHO to subscribe to a specific ACM for a duration.
    11. `subscribeToAllModules(uint256 _duration)`: User pays ECHO to subscribe to all approved ACMs for a duration (potentially discounted).
    12. `requestEcho(uint256 _moduleId, bytes memory _params)`: Requests a new Echo (content hash) from a subscribed module, passing specific parameters. The module's `generateEcho` function is called.
    13. `batchRequestEcho(uint256[] memory _moduleIds, bytes[] memory _params)`: Requests multiple Echoes from different modules in a single transaction.
    14. `refineEcho(uint256 _originalEchoId, uint256 _moduleId, bytes memory _refinementParams)`: Creates a derivative Echo from an existing one, providing new refinement parameters, establishing content lineage.

    IV. Curation & Reward System
    15. `curateEcho(uint256 _echoId, uint256 _stakeAmount)`: User stakes ECHO on an Echo they deem valuable or promising ("Proof-of-Curiosity").
    16. `claimCurationReward(uint256 _echoId)`: Allows successful curators to claim their share of rewards (e.g., from platform fees) if the Echo reaches a popularity threshold, and unstake their initial deposit.
    17. `revokeCuration(uint256 _echoId)`: Allows a curator to unstake their ECHO after a cooldown period, potentially with a small penalty if the Echo did not meet reward criteria.

    V. Oracle Integration
    18. `submitOracleInput(bytes32 _inputHash, uint256 _timestamp, bytes memory _signature)`: Allows a trusted oracle relay to submit a signed hash representing an off-chain AI input (e.g., "mood seed" or trend data). This input can influence module generation logic. (Owner-controlled for simplicity, but could be multi-sig/governance).

    VI. User & Information Retrieval (View Functions)
    19. `getModuleDetails(uint256 _moduleId)`: Returns detailed information about an ACM.
    20. `getModuleProposalDetails(uint256 _proposalId)`: Returns details about a pending module proposal.
    21. `getUserSubscriptionDetails(address _user, uint256 _moduleId)`: Checks the subscription status and expiry for a user and module.
    22. `getEchoDetails(uint256 _echoId)`: Retrieves all details related to a specific generated Echo.
    23. `getCurationDetails(uint256 _echoId, address _curator)`: Provides information about a specific user's curation on an Echo.
    24. `getLatestOracleInput()`: Returns the details of the most recently submitted oracle input.
*/

// Interfaces
interface IEchoModule {
    function generateEcho(
        address _caller,
        uint256 _echoId,
        bytes memory _params,
        bytes32 _latestOracleInputHash,
        uint256 _moduleBoostLevel
    ) external returns (bytes32 contentHash);

    function getModuleInfo() external view returns (string memory name, string memory description);
}

// Errors
error InvalidModuleAddress();
error ModuleNotApprovedOrDeprecated();
error SubscriptionNotFound();
error NotSubscribed();
error SubscriptionActive();
error SubscriptionExpired();
error InvalidDuration();
error NotEnoughECHO(uint256 required, uint256 has);
error TransferFailed();
error ModuleAlreadyProposed();
error ProposalNotFound();
error ProposalNotActive();
error VotingPeriodEnded();
error AlreadyVoted();
error NotEnoughVotes();
error QuorumNotReached();
error ProposalAlreadyFinalized();
error InvalidFeeRate();
error NoFeesToWithdraw();
error EchoNotFound();
error AlreadyCurated();
error CurationNotFound();
error CurationNotReadyToClaim();
error CurationCoolDownActive();
error InvalidOracleSignature();
error OracleInputTooRecent();

contract EtherealEchoesCore is Ownable {
    using SafeMath for uint256;

    IERC20 public immutable ECHO_TOKEN;

    // --- State Variables ---

    // Platform Configuration
    uint256 public platformFeeRate; // Percentage (e.g., 500 for 5%)
    uint256 public platformFeeBalance; // Accumulated fees in ECHO tokens

    // Counters for unique IDs
    uint256 public nextModuleId;
    uint256 public nextProposalId;
    uint256 public nextEchoId;

    // Structs definitions
    struct Module {
        address moduleAddress;
        string name;
        string description;
        bool approved;
        bool deprecated;
        uint256 createdAt;
        uint256 totalBoostBurned; // Total ECHO burned for this module
        uint256 lastBoostTimestamp; // Timestamp of last boost, for decay logic
    }

    struct ModuleProposal {
        address moduleAddress;
        string name;
        string description;
        uint256 proposer; // ID of the proposer
        uint256 proposedAt;
        uint256 votingEndsAt;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // User => hasVoted
        bool finalized;
        bool approved; // Final outcome
        uint256 stakeAmount; // ECHO staked by proposer
    }

    struct Subscription {
        uint256 moduleId;
        uint256 expiresAt;
    }

    struct Echo {
        uint256 echoId;
        uint256 moduleId;
        address creator;
        bytes32 contentHash; // The unique hash generated by the module
        uint256 createdAt;
        uint256 parentEchoId; // 0 if original, otherwise ID of the refined echo
        bytes params; // Parameters used to generate or refine this echo
    }

    struct Curation {
        uint256 echoId;
        address curator;
        uint256 stakeAmount;
        uint256 stakedAt;
        bool claimedReward;
        bool active; // True if stake is currently held
    }

    struct OracleInput {
        bytes32 inputHash;
        uint256 timestamp;
        bytes signature; // For verifying the oracle's authenticity
    }

    struct GovernanceParams {
        uint256 votingPeriod; // Duration in seconds for module proposals
        uint256 quorumPercentage; // Percentage of total ECHO supply needed for quorum (e.g., 1000 for 10%)
        uint256 minStakeForProposal; // Minimum ECHO required to propose a module
        uint256 subscriptionPricePerMonth; // Base price for 1 month subscription (e.g., in ECHO tokens)
        uint256 curationRewardPoolShare; // Percentage of platform fees allocated to curation rewards (e.g., 2000 for 20%)
        uint256 curationSuccessThreshold; // Number of curators an echo needs to reach to trigger rewards
        uint256 curationClaimPeriod; // How long after threshold is met curators have to claim
        uint256 curationCooldownPeriod; // How long after staking before unstaking is allowed without penalty
        uint256 curationPenaltyRate; // Percentage penalty for unstaking early without meeting criteria (e.g., 500 for 5%)
        uint256 allModulesSubscriptionDiscount; // Percentage discount for subscribing to all modules (e.g., 2000 for 20%)
    }

    // Mappings
    mapping(uint256 => Module) public modules; // moduleId => Module
    mapping(address => uint256) public moduleAddressToId; // moduleAddress => moduleId
    mapping(uint256 => ModuleProposal) public moduleProposals; // proposalId => ModuleProposal
    mapping(address => mapping(uint256 => Subscription)) public userModuleSubscriptions; // user => moduleId => Subscription
    mapping(address => uint256) public userAllModulesSubscriptionExpiresAt; // user => expiresAt for all modules
    mapping(uint256 => Echo) public echoes; // echoId => Echo
    mapping(uint256 => mapping(address => Curation)) public echoCurations; // echoId => curatorAddress => Curation
    mapping(uint256 => uint256) public echoCuratorCount; // echoId => number of active curators
    mapping(uint256 => uint256) public echoTotalCuratedStake; // echoId => total ECHO staked on this echo

    OracleInput public latestOracleInput;
    GovernanceParams public governanceParams;

    // --- Events ---
    event PlatformFeeRateUpdated(uint256 newFeeRate);
    event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
    event GovernanceParamsUpdated(
        uint256 votingPeriod,
        uint256 quorumPercentage,
        uint256 minStakeForProposal,
        uint256 subscriptionPricePerMonth,
        uint256 curationRewardPoolShare,
        uint256 curationSuccessThreshold,
        uint256 curationClaimPeriod,
        uint256 curationCooldownPeriod,
        uint256 curationPenaltyRate,
        uint256 allModulesSubscriptionDiscount
    );
    event ModuleProposed(
        uint256 indexed proposalId,
        address indexed moduleAddress,
        string name,
        address proposer
    );
    event ModuleVoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ModuleProposalFinalized(
        uint256 indexed proposalId,
        uint256 indexed moduleId,
        bool approved
    );
    event ModuleDeprecated(uint256 indexed moduleId, address indexed moduleAddress);
    event ModuleBoosted(uint256 indexed moduleId, address indexed booster, uint256 amountBurned);
    event ModuleSubscription(
        address indexed subscriber,
        uint256 indexed moduleId,
        uint256 expiresAt
    );
    event AllModulesSubscription(address indexed subscriber, uint256 expiresAt);
    event EchoGenerated(
        uint256 indexed echoId,
        uint256 indexed moduleId,
        address indexed creator,
        bytes32 contentHash,
        uint256 parentEchoId
    );
    event EchoCurated(
        uint256 indexed echoId,
        address indexed curator,
        uint256 stakeAmount,
        uint256 totalCurators
    );
    event CurationRewardClaimed(
        uint256 indexed echoId,
        address indexed curator,
        uint256 rewardAmount,
        uint256 stakeReturned
    );
    event CurationRevoked(
        uint256 indexed echoId,
        address indexed curator,
        uint256 amountReturned,
        uint256 penalty
    );
    event OracleInputSubmitted(bytes32 inputHash, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyActiveModule(uint256 _moduleId) {
        if (
            _moduleId == 0 ||
            !modules[_moduleId].approved ||
            modules[_moduleId].deprecated
        ) {
            revert ModuleNotApprovedOrDeprecated();
        }
        _;
    }

    modifier onlySubscribedToModule(uint256 _moduleId) {
        // Check specific module subscription
        if (
            userModuleSubscriptions[msg.sender][_moduleId].expiresAt < block.timestamp
        ) {
            // If specific module subscription expired, check all modules subscription
            if (userAllModulesSubscriptionExpiresAt[msg.sender] < block.timestamp) {
                revert NotSubscribed();
            }
        }
        _;
    }

    modifier onlyActiveProposal(uint256 _proposalId) {
        ModuleProposal storage proposal = moduleProposals[_proposalId];
        if (proposal.proposedAt == 0) revert ProposalNotFound();
        if (proposal.finalized) revert ProposalAlreadyFinalized();
        if (proposal.votingEndsAt < block.timestamp) revert VotingPeriodEnded();
        _;
    }

    constructor(address _echoTokenAddress) Ownable(msg.sender) {
        if (_echoTokenAddress == address(0)) revert InvalidModuleAddress();
        ECHO_TOKEN = IERC20(_echoTokenAddress);
        nextModuleId = 1;
        nextProposalId = 1;
        nextEchoId = 1;
        platformFeeRate = 500; // 5%
        platformFeeBalance = 0;

        // Initialize default governance parameters
        governanceParams = GovernanceParams({
            votingPeriod: 3 days,
            quorumPercentage: 1000, // 10%
            minStakeForProposal: 1000 ether, // 1000 ECHO
            subscriptionPricePerMonth: 100 ether, // 100 ECHO
            curationRewardPoolShare: 2000, // 20%
            curationSuccessThreshold: 5, // 5 curators
            curationClaimPeriod: 30 days, // 30 days to claim after success
            curationCooldownPeriod: 90 days, // 90 days before penalty-free unstake
            curationPenaltyRate: 500, // 5% penalty
            allModulesSubscriptionDiscount: 2000 // 20% discount
        });
    }

    // --- I. Core Platform Management (Governance & Admin) ---

    function setPlatformFeeRate(uint256 _newFeeRate) external onlyOwner {
        if (_newFeeRate > 10000) revert InvalidFeeRate(); // Max 100%
        platformFeeRate = _newFeeRate;
        emit PlatformFeeRateUpdated(_newFeeRate);
    }

    function withdrawPlatformFees() external onlyOwner {
        if (platformFeeBalance == 0) revert NoFeesToWithdraw();
        uint256 amount = platformFeeBalance;
        platformFeeBalance = 0;
        if (!ECHO_TOKEN.transfer(owner(), amount)) revert TransferFailed();
        emit PlatformFeesWithdrawn(owner(), amount);
    }

    function updateGovernanceParameters(
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        uint256 _minStakeForProposal,
        uint256 _subscriptionPricePerMonth,
        uint256 _curationRewardPoolShare,
        uint256 _curationSuccessThreshold,
        uint256 _curationClaimPeriod,
        uint256 _curationCooldownPeriod,
        uint256 _curationPenaltyRate,
        uint256 _allModulesSubscriptionDiscount
    ) external onlyOwner {
        if (_quorumPercentage > 10000 || _curationRewardPoolShare > 10000 || _curationPenaltyRate > 10000 || _allModulesSubscriptionDiscount > 10000) revert InvalidFeeRate();

        governanceParams = GovernanceParams({
            votingPeriod: _votingPeriod,
            quorumPercentage: _quorumPercentage,
            minStakeForProposal: _minStakeForProposal,
            subscriptionPricePerMonth: _subscriptionPricePerMonth,
            curationRewardPoolShare: _curationRewardPoolShare,
            curationSuccessThreshold: _curationSuccessThreshold,
            curationClaimPeriod: _curationClaimPeriod,
            curationCooldownPeriod: _curationCooldownPeriod,
            curationPenaltyRate: _curationPenaltyRate,
            allModulesSubscriptionDiscount: _allModulesSubscriptionDiscount
        });
        emit GovernanceParamsUpdated(
            _votingPeriod,
            _quorumPercentage,
            _minStakeForProposal,
            _subscriptionPricePerMonth,
            _curationRewardPoolShare,
            _curationSuccessThreshold,
            _curationClaimPeriod,
            _curationCooldownPeriod,
            _curationPenaltyRate,
            _allModulesSubscriptionDiscount
        );
    }

    function proposeModule(
        address _moduleAddress,
        string memory _name,
        string memory _description
    ) external {
        if (_moduleAddress == address(0)) revert InvalidModuleAddress();
        if (moduleAddressToId[_moduleAddress] != 0)
            revert ModuleAlreadyProposed(); // Or approved/deprecated

        uint256 requiredStake = governanceParams.minStakeForProposal;
        if (ECHO_TOKEN.balanceOf(msg.sender) < requiredStake)
            revert NotEnoughECHO(requiredStake, ECHO_TOKEN.balanceOf(msg.sender));
        if (!ECHO_TOKEN.transferFrom(msg.sender, address(this), requiredStake))
            revert TransferFailed();

        uint256 proposalId = nextProposalId++;
        moduleProposals[proposalId] = ModuleProposal({
            moduleAddress: _moduleAddress,
            name: _name,
            description: _description,
            proposer: proposalId, // Using proposalId as a simple unique identifier for proposer, not an actual user ID.
            proposedAt: block.timestamp,
            votingEndsAt: block.timestamp.add(governanceParams.votingPeriod),
            votesFor: 0,
            votesAgainst: 0,
            finalized: false,
            approved: false,
            stakeAmount: requiredStake
        });

        emit ModuleProposed(proposalId, _moduleAddress, _name, msg.sender);
    }

    function voteOnModuleProposal(uint256 _proposalId, bool _approve) external {
        ModuleProposal storage proposal = moduleProposals[_proposalId];
        if (proposal.proposedAt == 0) revert ProposalNotFound();
        if (proposal.finalized) revert ProposalAlreadyFinalized();
        if (proposal.votingEndsAt < block.timestamp) revert VotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voterBalance = ECHO_TOKEN.balanceOf(msg.sender);
        if (voterBalance == 0) revert NotEnoughVotes(); // Must hold ECHO to vote

        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(voterBalance);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterBalance);
        }
        proposal.hasVoted[msg.sender] = true;
        emit ModuleVoteCast(_proposalId, msg.sender, _approve);
    }

    function finalizeModuleProposal(uint256 _proposalId) external {
        ModuleProposal storage proposal = moduleProposals[_proposalId];
        if (proposal.proposedAt == 0) revert ProposalNotFound();
        if (proposal.finalized) revert ProposalAlreadyFinalized();
        if (proposal.votingEndsAt > block.timestamp) revert ProposalNotActive(); // Voting must have ended

        uint256 totalECHO_supply = ECHO_TOKEN.totalSupply();
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 requiredQuorum = totalECHO_supply.mul(
            governanceParams.quorumPercentage
        ).div(10000); // 10000 for 100%

        bool passed = false;
        if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
            // Proposal passes if quorum met AND more FOR votes
            passed = true;
        }

        // Return proposer's stake
        if (!ECHO_TOKEN.transfer(msg.sender, proposal.stakeAmount))
            revert TransferFailed();

        proposal.finalized = true;
        proposal.approved = passed;

        if (passed) {
            uint256 moduleId = nextModuleId++;
            modules[moduleId] = Module({
                moduleAddress: proposal.moduleAddress,
                name: proposal.name,
                description: proposal.description,
                approved: true,
                deprecated: false,
                createdAt: block.timestamp,
                totalBoostBurned: 0,
                lastBoostTimestamp: block.timestamp
            });
            moduleAddressToId[proposal.moduleAddress] = moduleId;
            emit ModuleProposalFinalized(
                _proposalId,
                moduleId,
                true
            );
        } else {
            emit ModuleProposalFinalized(
                _proposalId,
                0, // ModuleId 0 indicates rejection
                false
            );
        }
    }

    // --- II. Module Lifecycle & Configuration ---

    function deprecateModule(uint256 _moduleId) external onlyOwner onlyActiveModule(_moduleId) {
        modules[_moduleId].deprecated = true;
        // In a full DAO, this would also be a proposal/vote
        emit ModuleDeprecated(_moduleId, modules[_moduleId].moduleAddress);
    }

    function burnECHOForModuleBoost(uint256 _moduleId, uint256 _amount)
        external
        onlyActiveModule(_moduleId)
    {
        if (_amount == 0) revert NotEnoughECHO(1, 0); // Need to burn something

        if (ECHO_TOKEN.balanceOf(msg.sender) < _amount)
            revert NotEnoughECHO(_amount, ECHO_TOKEN.balanceOf(msg.sender));
        if (!ECHO_TOKEN.transferFrom(msg.sender, address(this), _amount))
            revert TransferFailed();

        // Simulate burning by sending to a burn address or just reducing supply virtually.
        // For simplicity here, tokens remain in the contract but are effectively "burned" from supply.
        // A more robust system would send them to address(0xdead).
        
        modules[_moduleId].totalBoostBurned = modules[_moduleId]
            .totalBoostBurned
            .add(_amount);
        modules[_moduleId].lastBoostTimestamp = block.timestamp;

        emit ModuleBoosted(_moduleId, msg.sender, _amount);
    }

    // --- III. Echo Generation & Interaction ---

    function _calculateSubscriptionCost(uint256 _duration) internal view returns (uint256) {
        // Duration in seconds, price per month
        uint256 months = _duration.div(30 days); // Approx months
        if (_duration % (30 days) != 0) months = months.add(1); // Round up partial month
        if (months == 0) months = 1; // Minimum 1 month
        return governanceParams.subscriptionPricePerMonth.mul(months);
    }

    function subscribeToModule(uint256 _moduleId, uint256 _duration)
        external
        onlyActiveModule(_moduleId)
    {
        if (_duration == 0) revert InvalidDuration();

        Subscription storage currentSub = userModuleSubscriptions[msg.sender][_moduleId];
        if (currentSub.expiresAt > block.timestamp) {
            revert SubscriptionActive();
        }

        uint256 cost = _calculateSubscriptionCost(_duration);
        if (ECHO_TOKEN.balanceOf(msg.sender) < cost)
            revert NotEnoughECHO(cost, ECHO_TOKEN.balanceOf(msg.sender));
        if (!ECHO_TOKEN.transferFrom(msg.sender, address(this), cost))
            revert TransferFailed();

        uint256 platformFee = cost.mul(platformFeeRate).div(10000);
        platformFeeBalance = platformFeeBalance.add(platformFee);

        // Module developer gets the rest
        uint256 moduleShare = cost.sub(platformFee);
        if (moduleShare > 0) {
            if (!ECHO_TOKEN.transfer(modules[_moduleId].moduleAddress, moduleShare))
                revert TransferFailed();
        }

        userModuleSubscriptions[msg.sender][_moduleId].moduleId = _moduleId;
        userModuleSubscriptions[msg.sender][_moduleId].expiresAt =
            block.timestamp.add(_duration);
        emit ModuleSubscription(
            msg.sender,
            _moduleId,
            userModuleSubscriptions[msg.sender][_moduleId].expiresAt
        );
    }

    function subscribeToAllModules(uint256 _duration) external {
        if (_duration == 0) revert InvalidDuration();

        if (userAllModulesSubscriptionExpiresAt[msg.sender] > block.timestamp) {
            revert SubscriptionActive();
        }

        // Calculate cost for a base number of months, then apply discount
        uint256 baseCost = _calculateSubscriptionCost(_duration);
        uint256 discountedCost = baseCost.mul(
            10000 - governanceParams.allModulesSubscriptionDiscount
        ).div(10000);

        if (ECHO_TOKEN.balanceOf(msg.sender) < discountedCost)
            revert NotEnoughECHO(discountedCost, ECHO_TOKEN.balanceOf(msg.sender));
        if (!ECHO_TOKEN.transferFrom(msg.sender, address(this), discountedCost))
            revert TransferFailed();

        platformFeeBalance = platformFeeBalance.add(discountedCost); // All to platform for all-module sub

        userAllModulesSubscriptionExpiresAt[msg.sender] = block.timestamp.add(_duration);
        emit AllModulesSubscription(
            msg.sender,
            userAllModulesSubscriptionExpiresAt[msg.sender]
        );
    }

    function requestEcho(uint256 _moduleId, bytes memory _params)
        external
        onlyActiveModule(_moduleId)
        onlySubscribedToModule(_moduleId)
        returns (uint256 echoId)
    {
        uint256 newEchoId = nextEchoId++;
        bytes32 contentHash = IEchoModule(modules[_moduleId].moduleAddress).generateEcho(
            msg.sender,
            newEchoId,
            _params,
            latestOracleInput.inputHash,
            modules[_moduleId].totalBoostBurned // Pass boost level to module
        );

        echoes[newEchoId] = Echo({
            echoId: newEchoId,
            moduleId: _moduleId,
            creator: msg.sender,
            contentHash: contentHash,
            createdAt: block.timestamp,
            parentEchoId: 0,
            params: _params
        });
        emit EchoGenerated(newEchoId, _moduleId, msg.sender, contentHash, 0);
        return newEchoId;
    }

    function batchRequestEcho(uint256[] memory _moduleIds, bytes[] memory _params)
        external
        returns (uint256[] memory newEchoIds)
    {
        if (_moduleIds.length != _params.length) revert InvalidModuleAddress(); // Simple check for array length mismatch.

        newEchoIds = new uint256[](_moduleIds.length);
        for (uint256 i = 0; i < _moduleIds.length; i++) {
            // This loop ensures each module is active and subscribed to
            // It might be gas-intensive for many requests.
            // Consider gas implications or allow partial failures/pre-checks off-chain.
            if (
                _moduleIds[i] == 0 ||
                !modules[_moduleIds[i]].approved ||
                modules[_moduleIds[i]].deprecated
            ) {
                revert ModuleNotApprovedOrDeprecated();
            }

            if (
                userModuleSubscriptions[msg.sender][_moduleIds[i]].expiresAt < block.timestamp
            ) {
                if (userAllModulesSubscriptionExpiresAt[msg.sender] < block.timestamp) {
                    revert NotSubscribed();
                }
            }

            uint256 newEchoId = nextEchoId++;
            bytes32 contentHash = IEchoModule(modules[_moduleIds[i]].moduleAddress).generateEcho(
                msg.sender,
                newEchoId,
                _params[i],
                latestOracleInput.inputHash,
                modules[_moduleIds[i]].totalBoostBurned
            );

            echoes[newEchoId] = Echo({
                echoId: newEchoId,
                moduleId: _moduleIds[i],
                creator: msg.sender,
                contentHash: contentHash,
                createdAt: block.timestamp,
                parentEchoId: 0,
                params: _params[i]
            });
            emit EchoGenerated(newEchoId, _moduleIds[i], msg.sender, contentHash, 0);
            newEchoIds[i] = newEchoId;
        }
    }

    function refineEcho(
        uint256 _originalEchoId,
        uint256 _moduleId,
        bytes memory _refinementParams
    )
        external
        onlyActiveModule(_moduleId)
        onlySubscribedToModule(_moduleId)
        returns (uint256 newEchoId)
    {
        if (echoes[_originalEchoId].echoId == 0) revert EchoNotFound();

        newEchoId = nextEchoId++;
        bytes32 contentHash = IEchoModule(modules[_moduleId].moduleAddress).generateEcho(
            msg.sender,
            newEchoId,
            _refinementParams,
            latestOracleInput.inputHash,
            modules[_moduleId].totalBoostBurned
        );

        echoes[newEchoId] = Echo({
            echoId: newEchoId,
            moduleId: _moduleId,
            creator: msg.sender,
            contentHash: contentHash,
            createdAt: block.timestamp,
            parentEchoId: _originalEchoId, // Link to the original
            params: _refinementParams
        });
        emit EchoGenerated(newEchoId, _moduleId, msg.sender, contentHash, _originalEchoId);
        return newEchoId;
    }

    // --- IV. Curation & Reward System (Proof-of-Curiosity) ---

    function curateEcho(uint256 _echoId, uint256 _stakeAmount) external {
        if (echoes[_echoId].echoId == 0) revert EchoNotFound();
        if (_stakeAmount == 0) revert NotEnoughECHO(1, 0);
        if (echoCurations[_echoId][msg.sender].active) revert AlreadyCurated();

        if (ECHO_TOKEN.balanceOf(msg.sender) < _stakeAmount)
            revert NotEnoughECHO(_stakeAmount, ECHO_TOKEN.balanceOf(msg.sender));
        if (!ECHO_TOKEN.transferFrom(msg.sender, address(this), _stakeAmount))
            revert TransferFailed();

        echoCurations[_echoId][msg.sender] = Curation({
            echoId: _echoId,
            curator: msg.sender,
            stakeAmount: _stakeAmount,
            stakedAt: block.timestamp,
            claimedReward: false,
            active: true
        });

        echoCuratorCount[_echoId]++;
        echoTotalCuratedStake[_echoId] = echoTotalCuratedStake[_echoId].add(_stakeAmount);

        emit EchoCurated(_echoId, msg.sender, _stakeAmount, echoCuratorCount[_echoId]);
    }

    function claimCurationReward(uint256 _echoId) external {
        Curation storage curation = echoCurations[_echoId][msg.sender];
        if (!curation.active) revert CurationNotFound();
        if (curation.claimedReward) revert CurationNotReadyToClaim();

        // Reward condition: Echo must have reached the success threshold
        if (echoCuratorCount[_echoId] < governanceParams.curationSuccessThreshold) {
            revert CurationNotReadyToClaim();
        }

        // Calculate reward: A portion of the platform fees, distributed among successful curators
        // For simplicity, let's say the first N curators (N = successThreshold) share a portion of fees.
        // Or, a small percentage of all platform fees are continuously added to a pool and distributed.
        // Here, we'll use a simplified model:
        // Reward = (curator's stake / total staked on this echo) * (pool share * platformFeeBalance)
        
        uint256 totalRewardPool = platformFeeBalance.mul(governanceParams.curationRewardPoolShare).div(10000);
        uint256 rewardAmount = curation.stakeAmount.mul(totalRewardPool).div(echoTotalCuratedStake[_echoId]);

        // Deduct from platformFeeBalance
        platformFeeBalance = platformFeeBalance.sub(rewardAmount);

        // Transfer reward + initial stake back
        uint256 totalTransfer = curation.stakeAmount.add(rewardAmount);
        if (!ECHO_TOKEN.transfer(msg.sender, totalTransfer)) revert TransferFailed();

        curation.claimedReward = true;
        curation.active = false; // Curation stake removed

        emit CurationRewardClaimed(
            _echoId,
            msg.sender,
            rewardAmount,
            curation.stakeAmount
        );
    }

    function revokeCuration(uint256 _echoId) external {
        Curation storage curation = echoCurations[_echoId][msg.sender];
        if (!curation.active) revert CurationNotFound();
        if (curation.claimedReward) revert CurationNotReadyToClaim(); // Already claimed or not applicable

        uint256 amountToReturn = curation.stakeAmount;
        uint256 penalty = 0;

        // Check for penalty if unstaking early and not successful
        if (
            echoCuratorCount[_echoId] < governanceParams.curationSuccessThreshold &&
            block.timestamp < curation.stakedAt.add(governanceParams.curationCooldownPeriod)
        ) {
            penalty = curation.stakeAmount.mul(governanceParams.curationPenaltyRate).div(10000);
            amountToReturn = amountToReturn.sub(penalty);
            platformFeeBalance = platformFeeBalance.add(penalty); // Penalty goes to platform fees
        }

        if (!ECHO_TOKEN.transfer(msg.sender, amountToReturn)) revert TransferFailed();

        curation.active = false;
        echoCuratorCount[_echoId]--;
        echoTotalCuratedStake[_echoId] = echoTotalCuratedStake[_echoId].sub(curation.stakeAmount);

        emit CurationRevoked(_echoId, msg.sender, amountToReturn, penalty);
    }

    // --- V. Oracle Integration ---

    // This function expects a signature from a trusted oracle.
    // In a real scenario, `_signature` would be verified against a known public key of the oracle.
    // For simplicity, this example assumes `owner()` is the trusted oracle relay.
    // A robust system would use ECDSA.recover and check against a predefined oracle address.
    function submitOracleInput(
        bytes32 _inputHash,
        uint256 _timestamp,
        bytes memory _signature
    ) external onlyOwner {
        // Basic check to prevent frequent updates - only once every 10 minutes for example.
        if (block.timestamp < latestOracleInput.timestamp.add(10 minutes)) {
            revert OracleInputTooRecent();
        }

        // --- CONCEPTUAL SIG VERIFICATION (placeholder) ---
        // In a real scenario:
        // bytes32 messageHash = keccak256(abi.encodePacked(_inputHash, _timestamp));
        // address signer = ECDSA.recover(messageHash, _signature);
        // require(signer == ORACLE_ADDRESS, "Invalid oracle signature");
        // For this example, we trust the owner to submit correct _signature,
        // which would be verified in a production environment.
        // --- END CONCEPTUAL SIG VERIFICATION ---

        latestOracleInput = OracleInput({
            inputHash: _inputHash,
            timestamp: _timestamp,
            signature: _signature
        });
        emit OracleInputSubmitted(_inputHash, _timestamp);
    }

    // --- VI. User & Information Retrieval (View Functions) ---

    function getModuleDetails(uint256 _moduleId)
        external
        view
        returns (
            address moduleAddress,
            string memory name,
            string memory description,
            bool approved,
            bool deprecated,
            uint256 createdAt,
            uint256 totalBoostBurned,
            uint256 lastBoostTimestamp
        )
    {
        Module storage m = modules[_moduleId];
        if (m.moduleAddress == address(0)) revert ModuleNotFound(); // Custom error likely needed

        return (
            m.moduleAddress,
            m.name,
            m.description,
            m.approved,
            m.deprecated,
            m.createdAt,
            m.totalBoostBurned,
            m.lastBoostTimestamp
        );
    }

    function getModuleProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            address moduleAddress,
            string memory name,
            string memory description,
            uint256 proposedAt,
            uint256 votingEndsAt,
            uint256 votesFor,
            uint256 votesAgainst,
            bool finalized,
            bool approved,
            uint256 stakeAmount
        )
    {
        ModuleProposal storage p = moduleProposals[_proposalId];
        if (p.proposedAt == 0) revert ProposalNotFound();

        return (
            p.moduleAddress,
            p.name,
            p.description,
            p.proposedAt,
            p.votingEndsAt,
            p.votesFor,
            p.votesAgainst,
            p.finalized,
            p.approved,
            p.stakeAmount
        );
    }

    function getUserSubscriptionDetails(address _user, uint256 _moduleId)
        external
        view
        returns (bool isSubscribed, uint256 expiresAt, bool isAllModulesSubscribed)
    {
        bool specificSubActive = userModuleSubscriptions[_user][_moduleId].expiresAt > block.timestamp;
        bool allModulesSubActive = userAllModulesSubscriptionExpiresAt[_user] > block.timestamp;

        return (
            specificSubActive || allModulesSubActive,
            specificSubActive ? userModuleSubscriptions[_user][_moduleId].expiresAt : 0,
            allModulesSubActive
        );
    }

    function getEchoDetails(uint256 _echoId)
        external
        view
        returns (
            uint256 echoId,
            uint256 moduleId,
            address creator,
            bytes32 contentHash,
            uint256 createdAt,
            uint256 parentEchoId,
            bytes memory params
        )
    {
        Echo storage e = echoes[_echoId];
        if (e.echoId == 0) revert EchoNotFound();

        return (
            e.echoId,
            e.moduleId,
            e.creator,
            e.contentHash,
            e.createdAt,
            e.parentEchoId,
            e.params
        );
    }

    function getCurationDetails(uint256 _echoId, address _curator)
        external
        view
        returns (
            uint256 stakeAmount,
            uint256 stakedAt,
            bool claimedReward,
            bool active
        )
    {
        Curation storage c = echoCurations[_echoId][_curator];
        if (!c.active) revert CurationNotFound();

        return (c.stakeAmount, c.stakedAt, c.claimedReward, c.active);
    }

    function getLatestOracleInput()
        external
        view
        returns (bytes32 inputHash, uint256 timestamp)
    {
        return (latestOracleInput.inputHash, latestOracleInput.timestamp);
    }
}
```