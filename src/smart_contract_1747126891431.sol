Okay, let's design a smart contract around a concept that blends dynamic NFTs, on-chain reputation, governed collective actions, and time-based mechanics, without being a direct copy of standard ERCs, marketplaces, or simple DeFi protocols.

We'll call it `ReputationBoundCollective`. Users register, earn reputation through logged on-chain "activities", their reputation score influences a dynamic, soulbound (initially) NFT's level and appearance, and reputation/NFT level grants voting power in a collective that manages a treasury and system parameters. Reputation decays over time, encouraging continued participation.

This involves:
1.  **Dynamic NFT:** Metadata changes based on user state.
2.  **On-chain Reputation:** A score stored and updated.
3.  **Decay Mechanism:** Reputation naturally decreases over time.
4.  **Activity Logging:** Tracking specific user actions on-chain.
5.  **Reputation Staking/Boosting:** Users can lock reputation for temporary benefits.
6.  **Collective Treasury:** A pool of funds managed by token/reputation holders.
7.  **On-chain Governance:** Voting system for treasury spending and parameter changes.
8.  **Delegation:** Allowing users to delegate voting power.
9.  **Parameterization:** Admin/governance configurable system settings.

---

**Outline:**

1.  **License and Pragma**
2.  **Imports:** ERC721, ERC721URIStorage, Ownable, Pausable, Counters.
3.  **Custom Errors**
4.  **Events:** For user registration, activity logging, reputation updates, decay, staking, NFT level changes, treasury deposits, proposals, voting, execution, parameter changes, delegation, pausing.
5.  **Structs:** To define activity parameters, activity log entries, and governance proposals.
6.  **State Variables:** Mappings for reputation, staking, user->NFT ID, NFT ID->user, activity parameters, activity logs, governance proposals, voting state, delegation, system parameters (decay rate, thresholds, etc.), counters.
7.  **Modifiers:** Standard `onlyOwner`, `whenNotPaused`, `whenPaused`.
8.  **Constructor:** Initializes owner, base URI, initial parameters.
9.  **Core Logic Functions (>= 20):**
    *   User Registration & NFT Management
    *   Reputation Management (Earning, Decay, Staking)
    *   Activity Logging & Parameterization
    *   Dynamic NFT (URI generation, Level calculation)
    *   Collective Treasury Management (Deposit, Proposals, Voting, Execution)
    *   System Parameter Governance (Proposals, Voting, Execution)
    *   Voting & Delegation
    *   Admin & Utility

---

**Function Summary:**

1.  `constructor()`: Initializes the contract with essential parameters and the base URI for NFT metadata.
2.  `registerUser()`: Allows a new address to join, minting their unique ReputationBound NFT (soulbound initially).
3.  `logUserActivity(bytes32 _activityType, uint256 _value)`: Records a specific type of user activity, potentially updating their reputation based on configured parameters.
4.  `getCurrentReputation(address _user)`: Retrieves the current reputation score for a given user.
5.  `getUserActivityLog(address _user)`: Returns a list of recent activity log entries for a user. (Gas caution for long logs).
6.  `applyReputationDecay(address _user)`: Allows anyone (or a designated keeper) to trigger reputation decay for a specific user if the decay interval has passed.
7.  `stakeReputationForBoost(uint256 _amount)`: Locks a user's active reputation for a period to gain voting boost or other benefits.
8.  `unstakeReputationBoost()`: Allows a user to unlock their staked reputation after the required staking period.
9.  `getUserNFTId(address _user)`: Gets the token ID of the ReputationBound NFT owned by a user.
10. `tokenURI(uint256 tokenId)`: (Override) Generates the dynamic metadata URI for an NFT based on the owner's current reputation, level, and potentially other traits.
11. `getNFTLevel(address _user)`: Calculates the current level of a user's NFT based on their reputation and defined thresholds.
12. `claimLevelUpReward(address _user)`: Allows users to claim rewards (if any) when their NFT reaches a new level. (Requires a reward system implementation).
13. `depositToCollectiveTreasury()`: Allows anyone to deposit native currency (ETH) into the contract's collective treasury.
14. `getCollectiveTreasuryBalance()`: Checks the current native currency balance held in the treasury.
15. `proposeCollectiveAction(string memory _description, address _target, uint256 _value, bytes memory _callData)`: Creates a governance proposal for executing a specific action (e.g., sending funds from treasury, calling another contract).
16. `voteOnCollectiveAction(uint256 _proposalId, bool _support)`: Allows users with voting power (based on reputation/stake/NFT level) to cast a vote on an active collective action proposal.
17. `executeCollectiveAction(uint256 _proposalId)`: Executes a collective action proposal if it has passed and the voting period is over.
18. `proposeSystemParameterChange(string memory _description, bytes32 _paramKey, uint256 _newValue)`: Creates a governance proposal to change a core system parameter (like decay rate, thresholds).
19. `voteOnSystemParameterChange(uint256 _proposalId, bool _support)`: Allows users to vote on a system parameter change proposal.
20. `executeSystemParameterChange(uint256 _proposalId)`: Executes a system parameter change proposal if it has passed.
21. `getProposalDetails(uint256 _proposalId)`: Retrieves the details and current state of a specific proposal.
22. `delegateVotingPower(address _delegatee)`: Allows a user to delegate their voting power (based on their reputation/stake) to another address.
23. `addAllowedActivityType(bytes32 _activityType, uint256 _reputationGain, uint256 _cooldown, string memory _description)`: (Admin/Governance) Configures a new valid activity type that users can log.
24. `updateActivityTypeParameters(bytes32 _activityType, uint256 _reputationGain, uint256 _cooldown, string memory _description)`: (Admin/Governance) Modifies parameters of an existing activity type.
25. `pauseContractOperations()`: (Admin/Governance) Pauses user-facing activities like logging, staking, proposing, voting.
26. `unpauseContractOperations()`: (Admin/Governance) Unpauses the contract.

This structure provides a complex interplay between user activity, on-chain state (reputation, NFT), time (decay), and decentralized governance, going beyond simple token standards or single-purpose contracts. Note: Implementing all nuances like gas efficiency for decay on large user bases, complex voting mechanics (quadratic, weighted), and robust metadata generation requires significant detail, but the outline and function list cover the core requirements.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline:
// 1. License and Pragma
// 2. Imports
// 3. Custom Errors
// 4. Events
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Core Logic Functions (>= 20) - See Function Summary below

// Function Summary:
// 1. constructor(): Initializes contract parameters.
// 2. registerUser(): Mints a ReputationBound NFT for a new user.
// 3. logUserActivity(bytes32 _activityType, uint256 _value): Records user activity affecting reputation.
// 4. getCurrentReputation(address _user): Gets current reputation score.
// 5. getUserActivityLog(address _user): Retrieves user's activity history.
// 6. applyReputationDecay(address _user): Triggers reputation decay for a user.
// 7. stakeReputationForBoost(uint256 _amount): Stakes reputation for temporary benefits.
// 8. unstakeReputationBoost(): Unstakes previously staked reputation.
// 9. getUserNFTId(address _user): Gets the NFT token ID for a user.
// 10. tokenURI(uint256 tokenId): Generates dynamic NFT metadata URI.
// 11. getNFTLevel(address _user): Calculates NFT level based on reputation.
// 12. claimLevelUpReward(address _user): Claims rewards for reaching new NFT levels (requires reward system).
// 13. depositToCollectiveTreasury(): Allows depositing native currency.
// 14. getCollectiveTreasuryBalance(): Gets treasury balance.
// 15. proposeCollectiveAction(string memory _description, address _target, uint256 _value, bytes memory _callData): Creates a treasury spending/action proposal.
// 16. voteOnCollectiveAction(uint256 _proposalId, bool _support): Votes on a collective action proposal.
// 17. executeCollectiveAction(uint256 _proposalId): Executes a passed collective action proposal.
// 18. proposeSystemParameterChange(string memory _description, bytes32 _paramKey, uint256 _newValue): Creates a system parameter change proposal.
// 19. voteOnSystemParameterChange(uint256 _proposalId, bool _support): Votes on a parameter change proposal.
// 20. executeSystemParameterChange(uint256 _proposalId): Executes a passed parameter change proposal.
// 21. getProposalDetails(uint256 _proposalId): Retrieves details of a proposal.
// 22. delegateVotingPower(address _delegatee): Delegates voting power.
// 23. addAllowedActivityType(bytes32 _activityType, uint256 _reputationGain, uint256 _cooldown, string memory _description): Configures a new activity type.
// 24. updateActivityTypeParameters(bytes32 _activityType, uint256 _reputationGain, uint256 _cooldown, string memory _description): Updates activity type parameters.
// 25. pauseContractOperations(): Pauses core operations.
// 26. unpauseContractOperations(): Unpauses the contract.

contract ReputationBoundCollective is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Custom Errors ---
    error UserAlreadyRegistered();
    error UserNotRegistered();
    error ActivityTypeNotAllowed(bytes32 activityType);
    error ActivityOnCooldown(address user);
    error InsufficientReputation(uint256 required, uint256 current);
    error ReputationStakeTooLow(uint256 required, uint256 staked);
    error ReputationStakeCooldownActive(uint256 remainingTime);
    error NoStakeToUnstake();
    error ProposalNotFound(uint256 proposalId);
    error ProposalVotingPeriodNotActive(uint256 proposalId);
    error ProposalAlreadyVoted(address voter, uint256 proposalId);
    error ProposalNotExecutable(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);
    error NoVotingPower(address voter);
    error InvalidProposalState(uint256 proposalId);
    error CannotDelegateToSelf();
    error ActivityTypeAlreadyExists(bytes32 activityType);
    error ActivityTypeNotFound(bytes32 activityType);
    error DecayIntervalNotPassed(uint256 remainingTime);

    // --- Events ---
    event UserRegistered(address indexed user, uint256 tokenId);
    event ActivityLogged(address indexed user, bytes32 indexed activityType, uint256 value, uint256 newReputation);
    event ReputationUpdated(address indexed user, uint256 oldReputation, uint256 newReputation, string reason);
    event ReputationDecayApplied(address indexed user, uint256 oldReputation, uint256 newReputation);
    event ReputationStaked(address indexed user, uint256 amount, uint256 newStakedAmount);
    event ReputationUnstaked(address indexed user, uint256 amount, uint256 newStakedAmount);
    event NFTLevelUp(address indexed user, uint256 tokenId, uint256 oldLevel, uint256 newLevel);
    event CollectiveDeposit(address indexed depositor, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event ParameterChangeProposed(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, uint256 newValue);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event AllowedActivityTypeAdded(bytes32 indexed activityType, uint256 reputationGain, uint256 cooldown);
    event AllowedActivityTypeUpdated(bytes32 indexed activityType, uint256 reputationGain, uint256 cooldown);
    event Paused(address account);
    event Unpaused(address account);

    // --- Structs ---
    struct ActivityParameters {
        uint256 reputationGain; // Reputation gained per activity unit/event
        uint256 cooldown;       // Cooldown period in seconds
        string description;     // Description of the activity type
    }

    struct ActivityLogEntry {
        bytes32 activityType;
        uint256 value;
        uint64 timestamp;
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        // For CollectiveAction:
        address target;
        uint256 value;
        bytes callData; // The data to call on the target contract
        // For ParameterChange:
        bytes32 paramKey;
        uint256 newValue;
        // Voting State:
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes; // Optional: add abstain votes
        // State
        ProposalState state;
        bool isCollectiveAction; // true for CollectiveAction, false for ParameterChange
        mapping(address => bool) hasVoted; // Record voters
    }

    // --- State Variables ---
    Counters.Counter private _tokenIds;
    Counters.Counter private _proposalIds;

    // User Data
    mapping(address => uint256) private _userReputation; // Current active reputation
    mapping(address => uint256) private _userStakedReputation; // Staked reputation for boosts/voting
    mapping(address => uint256) private _userNFTId; // User address to their NFT ID
    mapping(uint256 => address) private _nftOwner; // NFT ID to owner address (redundant with ERC721 owner mapping, but for clarity/quick lookup if needed)
    mapping(address => ActivityLogEntry[]) private _userActivityLogs; // Log of user activities
    mapping(address => uint64) private _userLastDecayTime; // Timestamp of the last reputation decay for a user
    mapping(address => uint64) private _userStakingCooldownEnd; // Timestamp when staking cooldown ends

    // System Parameters (Configurable via Governance)
    mapping(bytes32 => ActivityParameters) private _allowedActivityTypes; // Configured activity types
    uint256[] public reputationLevelThresholds; // Reputation needed for each NFT level (e.g., [0, 100, 500, 1000])
    uint256 public reputationDecayRatePerSecond = 1; // How much reputation decays per second per point (scaled, e.g., 1 = 0.01%)
    uint256 public reputationDecayInterval = 1 days; // Minimum time between decay applications per user
    uint256 public minReputationToPropose = 100; // Minimum reputation to create a proposal
    uint256 public proposalVotingPeriod = 3 days; // Duration of the voting period
    uint256 public proposalExecutionDelay = 1 days; // Delay between proposal passing and being executable
    uint256 public proposalThresholdQuorum = 50; // Percentage of total voting power needed for quorum (e.g., 50 = 50%)
    uint256 public proposalPassThreshold = 51; // Percentage of votes needed to pass (e.g., 51 = >50%)

    // Governance Data
    mapping(uint256 => Proposal) private _proposals; // All governance proposals
    mapping(address => address) private _delegates; // User to their delegatee address

    // Constants (Initial values or non-governable parameters)
    uint256 private constant INITIAL_REPUTATION = 1; // Starting reputation upon registration
    uint256 private constant REPUTATION_DECAY_SCALE = 10000; // Scale factor for decay rate (e.g., 1 = 1/10000 = 0.01%)
    uint256 private constant STAKING_COOLDOWN = 7 days; // Cooldown after unstaking reputation

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256[] memory _initialLevelThresholds
    ) ERC721(name, symbol) ERC721URIStorage(baseTokenURI) Ownable(msg.sender) Pausable() {
        reputationLevelThresholds = _initialLevelThresholds;
        // Ensure thresholds are sorted and start at 0
        require(reputationLevelThresholds.length > 0 && reputationLevelThresholds[0] == 0, "Invalid initial thresholds");
        for(uint i = 0; i < reputationLevelThresholds.length - 1; i++) {
            require(reputationLevelThresholds[i] < reputationLevelThresholds[i+1], "Thresholds must be strictly increasing");
        }
    }

    // --- Pausable Overrides ---
    function pauseContractOperations() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContractOperations() public onlyOwner whenPaused {
        _unpause();
    }

    // --- User Registration & NFT Management ---
    function registerUser() public whenNotPaused {
        address user = msg.sender;
        if (_userReputation[user] > 0 || _userNFTId[user] > 0) {
            revert UserAlreadyRegistered();
        }

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(user, newTokenId);
        _userNFTId[user] = newTokenId;
        _nftOwner[newTokenId] = user; // Store owner mapping (redundant with ERC721, but helpful)

        _userReputation[user] = INITIAL_REPUTATION;
        _userLastDecayTime[user] = uint64(block.timestamp); // Set last decay time on registration

        emit UserRegistered(user, newTokenId);
        emit ReputationUpdated(user, 0, INITIAL_REPUTATION, "Registration");
    }

    // ERC721 required function - crucial for Soulbound concept initially, though transfer could be enabled later
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Prevent transfers after mint, making it Soulbound
        if (from != address(0) && to != address(0)) {
             revert ERC721InsufficientApproval(from, tokenId); // Or a custom error like SoulboundTokenCannotBeTransferred
        }
         // Note: ERC721 standard allows burning (to address(0)) and minting (from address(0)).
         // Our registerUser handles minting. No explicit burn function provided here, but could be added.
    }

    function getUserNFTId(address _user) public view returns (uint256) {
         uint256 tokenId = _userNFTId[_user];
         if (tokenId == 0) revert UserNotRegistered();
         return tokenId;
    }

    // --- Reputation Management ---

    function logUserActivity(bytes32 _activityType, uint256 _value) public whenNotPaused {
        address user = msg.sender;
        if (_userNFTId[user] == 0) { // Check if user is registered
            revert UserNotRegistered();
        }

        ActivityParameters memory activityParams = _allowedActivityTypes[_activityType];
        if (activityParams.cooldown == 0 && activityParams.reputationGain == 0 && bytes(activityParams.description).length == 0) {
             revert ActivityTypeNotFound(_activityType); // Check if activity type is configured
        }

        // Check cooldown for this activity type (simplified: one cooldown per user for any activity)
        // A more complex system would track cooldown per activity type per user.
        // For simplicity here, we'll use a single last activity timestamp.
        // mapping(address => mapping(bytes32 => uint64)) private _userActivityCooldowns;
        // uint64 lastActivityTime = _userActivityCooldowns[user][_activityType];
        // if (block.timestamp < lastActivityTime + activityParams.cooldown) {
        //    revert ActivityOnCooldown(user);
        // }
        // _userActivityCooldowns[user][_activityType] = uint64(block.timestamp);

        // Log activity
        _userActivityLogs[user].push(ActivityLogEntry(_activityType, _value, uint64(block.timestamp)));
        // Limit log size? Requires more complex array management (e.g., ring buffer or truncation)

        // Calculate reputation change
        // Example: gain is based on activityParams.reputationGain * _value
        uint256 reputationIncrease = activityParams.reputationGain.mul(_value);

        uint256 oldReputation = _userReputation[user];
        _userReputation[user] = oldReputation.add(reputationIncrease);
        emit ReputationUpdated(user, oldReputation, _userReputation[user], string(abi.encodePacked("Activity Logged: ", activityParams.description)));
        emit ActivityLogged(user, _activityType, _value, _userReputation[user]);

        // Trigger NFT state update check
        _checkAndEmitNFTLevelUp(user, oldReputation, _userReputation[user]);
    }

    function getCurrentReputation(address _user) public view returns (uint256) {
        if (_userNFTId[_user] == 0) {
            revert UserNotRegistered();
        }
        // Note: This returns the *stored* reputation. To be fully accurate with decay,
        // the decay should be applied implicitly here, but that's gas-intensive
        // or requires more complex state/virtualization. We use explicit decay calls.
        return _userReputation[_user];
    }

     function getUserActivityLog(address _user) public view returns (ActivityLogEntry[] memory) {
        if (_userNFTId[_user] == 0) {
            revert UserNotRegistered();
        }
        // Warning: Returning large arrays is gas-intensive. Consider pagination for production.
        return _userActivityLogs[_user];
     }


    // Note on applyReputationDecay: This design requires users or a keeper to call it
    // for decay to occur. An alternative is to calculate decay virtually in `getCurrentReputation`,
    // but that requires storing the last update timestamp for each user and is computationally heavy.
    // Another alternative is batch processing by admin, but that can hit gas limits.
    function applyReputationDecay(address _user) public { // Made public so anyone can trigger for a user (encourages ecosystem upkeep)
        if (_userNFTId[_user] == 0) {
            revert UserNotRegistered();
        }

        uint64 lastDecay = _userLastDecayTime[_user];
        uint64 currentTime = uint64(block.timestamp);

        if (currentTime < lastDecay + reputationDecayInterval) {
             revert DecayIntervalNotPassed(lastDecay + reputationDecayInterval - currentTime);
        }

        uint256 currentReputation = _userReputation[_user];
        if (currentReputation <= INITIAL_REPUTATION) { // Don't decay below initial reputation
            _userLastDecayTime[_user] = currentTime; // Reset decay time even if no decay happens
            return;
        }

        uint256 timeElapsed = currentTime - lastDecay;
        // Decay amount = reputation * decay_rate_per_second * time_elapsed / scale
        uint256 decayAmount = currentReputation.mul(reputationDecayRatePerSecond).mul(timeElapsed).div(REPUTATION_DECAY_SCALE);

        uint256 newReputation = currentReputation.sub(decayAmount > currentReputation ? currentReputation - INITIAL_REPUTATION : decayAmount);
        if (newReputation < INITIAL_REPUTATION) newReputation = INITIAL_REPUTATION; // Ensure minimum initial reputation

        _userReputation[_user] = newReputation;
        _userLastDecayTime[_user] = currentTime; // Update last decay time

        emit ReputationDecayApplied(_user, currentReputation, newReputation);
        emit ReputationUpdated(_user, currentReputation, newReputation, "Decay");

        _checkAndEmitNFTLevelUp(_user, currentReputation, newReputation); // Level might go down
    }

    function stakeReputationForBoost(uint256 _amount) public whenNotPaused {
        address user = msg.sender;
        uint256 currentRep = _userReputation[user];
        if (currentRep == 0 || _userNFTId[user] == 0) revert UserNotRegistered();
        if (_amount == 0) revert InsufficientReputation(1, 0);
        if (currentRep < _amount) revert InsufficientReputation(_amount, currentRep);

        _userReputation[user] = currentRep.sub(_amount);
        _userStakedReputation[user] = _userStakedReputation[user].add(_amount);
        // Set cooldown only if it's the first time staking or if previous stake finished
        if (_userStakingCooldownEnd[user] < block.timestamp) {
             _userStakingCooldownEnd[user] = uint64(block.timestamp + STAKING_COOLDOWN);
        }

        emit ReputationStaked(user, _amount, _userStakedReputation[user]);
        emit ReputationUpdated(user, currentRep, _userReputation[user], "Stake");
    }

    function unstakeReputationBoost() public whenNotPaused {
        address user = msg.sender;
        uint256 stakedRep = _userStakedReputation[user];
        if (stakedRep == 0) revert NoStakeToUnstake();

        uint64 cooldownEnd = _userStakingCooldownEnd[user];
        if (block.timestamp < cooldownEnd) {
             revert ReputationStakeCooldownActive(cooldownEnd - uint64(block.timestamp));
        }

        _userStakedReputation[user] = 0;
        _userReputation[user] = _userReputation[user].add(stakedRep);
        // No need to reset cooldown here, it's only set when *adding* stake

        emit ReputationUnstaked(user, stakedRep, 0);
        emit ReputationUpdated(user, _userReputation[user].sub(stakedRep), _userReputation[user], "Unstake");
    }


    // --- Dynamic NFT ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        address ownerAddress = ownerOf(tokenId); // Use ERC721 ownerOf
        if (_userNFTId[ownerAddress] != tokenId) {
             // Should not happen if userNFTId mapping is correctly maintained
             revert UserNotRegistered();
        }

        uint256 reputation = _userReputation[ownerAddress];
        uint256 level = getNFTLevel(ownerAddress);

        // Construct a base URI with parameters that an external service can use
        // Example: baseURI/tokenID?reputation=X&level=Y&traits=...
        // A more advanced approach would encode state into a data URI:
        // data:application/json;base64,...
        // For this example, we'll generate a simple string indicator.

        string memory base = _baseURI();
        string memory levelIndicator = string(abi.encodePacked("Level-", Strings.toString(level)));
        string memory repIndicator = string(abi.encodePacked("Reputation-", Strings.toString(reputation)));
        string memory tokenIdStr = Strings.toString(tokenId);

        // Concatenate into a simple string format for dynamic URI
        // e.g., "https://mydynamicnft.xyz/metadata/1?level=5&rep=1234"
        // A real implementation would likely point to an API endpoint that
        // generates JSON metadata based on these parameters.
        return string(abi.encodePacked(base, tokenIdStr, "?level=", Strings.toString(level), "&rep=", Strings.toString(reputation)));
    }

    function getNFTLevel(address _user) public view returns (uint256) {
        uint256 reputation = getCurrentReputation(_user); // Uses registered check
        uint256 level = 0;
        for (uint i = 0; i < reputationLevelThresholds.length; i++) {
            if (reputation >= reputationLevelThresholds[i]) {
                level = i; // Level is the index (0-based)
            } else {
                break;
            }
        }
        return level;
    }

    // Internal helper to check and emit level up/down events
    function _checkAndEmitNFTLevelUp(address _user, uint256 _oldReputation, uint256 _newReputation) internal {
        uint256 oldLevel = 0;
         for (uint i = 0; i < reputationLevelThresholds.length; i++) {
            if (_oldReputation >= reputationLevelThresholds[i]) {
                oldLevel = i;
            } else {
                break;
            }
        }

        uint256 newLevel = getNFTLevel(_user);
        if (newLevel != oldLevel) {
             emit NFTLevelUp(_user, _userNFTId[_user], oldLevel, newLevel);
        }
    }

    // Function to claim rewards (Requires a separate reward distribution mechanism or logic)
    // This is a placeholder. A real implementation needs a reward source (e.g., contract balance, external token)
    // and logic to track claimed rewards per level per user.
    // Example: mapping(address => mapping(uint256 => bool)) private _levelRewardClaimed;
    function claimLevelUpReward(address _user) public whenNotPaused {
        // This is a placeholder. Implement reward logic here.
        // Example: Check current level, check _levelRewardClaimed for this level,
        // send reward, set _levelRewardClaimed to true.
        revert("Reward claiming not yet implemented");
        address user = _user; // Use parameter for potential external trigger (e.g., UI helper)
        uint256 currentLevel = getNFTLevel(user);
        // ... reward logic based on level ...
        // emit RewardClaimed(user, currentLevel, rewardAmount, rewardToken);
    }

    // --- Collective Treasury ---

    receive() external payable {
        emit CollectiveDeposit(msg.sender, msg.value);
    }

    function depositToCollectiveTreasury() public payable whenNotPaused {
        emit CollectiveDeposit(msg.sender, msg.value);
    }

    function getCollectiveTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Governance ---

    function getVotingPower(address _user) public view returns (uint256) {
        // Voting power could be based on active reputation, staked reputation, or NFT level.
        // Let's use a simple model: active reputation + staked reputation.
        address delegator = _user;
        // Resolve delegation chain
        while (_delegates[delegator] != address(0) && _delegates[delegator] != delegator) {
            delegator = _delegates[delegator];
        }
        if (delegator != _user) {
            // Return delegated power if exists and not self-delegated
             return _userReputation[delegator].add(_userStakedReputation[delegator]);
        }
        // Return own power if no valid delegation or self-delegated
        return _userReputation[_user].add(_userStakedReputation[_user]);
    }

    function delegateVotingPower(address _delegatee) public whenNotPaused {
        address delegator = msg.sender;
        if (delegator == _delegatee) revert CannotDelegateToSelf();
        if (_userNFTId[delegator] == 0) revert UserNotRegistered(); // Only registered users can delegate

        _delegates[delegator] = _delegatee;
        emit VotingPowerDelegated(delegator, _delegatee);
    }

    function proposeCollectiveAction(
        string memory _description,
        address _target,
        uint256 _value,
        bytes memory _callData
    ) public whenNotPaused returns (uint256 proposalId) {
        address proposer = msg.sender;
        if (_userNFTId[proposer] == 0) revert UserNotRegistered();
        if (getCurrentReputation(proposer) < minReputationToPropose) {
            revert InsufficientReputation(minReputationToPropose, getCurrentReputation(proposer));
        }

        _proposalIds.increment();
        proposalId = _proposalIds.current();

        uint64 voteStart = uint64(block.timestamp);
        uint64 voteEnd = voteStart + uint64(proposalVotingPeriod);

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: proposer,
            description: _description,
            target: _target,
            value: _value,
            callData: _callData,
            paramKey: bytes32(0), // Not a parameter change proposal
            newValue: 0,          // Not a parameter change proposal
            voteStart: voteStart,
            voteEnd: voteEnd,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Active,
            isCollectiveAction: true,
            hasVoted: new mapping(address => bool)() // Initialize empty mapping
        });

        emit ProposalCreated(proposalId, proposer, _description);
        return proposalId;
    }

    function proposeSystemParameterChange(
        string memory _description,
        bytes32 _paramKey,
        uint256 _newValue
    ) public whenNotPaused returns (uint256 proposalId) {
        address proposer = msg.sender;
         if (_userNFTId[proposer] == 0) revert UserNotRegistered();
        if (getCurrentReputation(proposer) < minReputationToPropose) {
            revert InsufficientReputation(minReputationToPropose, getCurrentReputation(proposer));
        }

        // Basic validation for paramKey (check if it's one we allow governance to change)
        // This is a simplified check; a real system would use a registry of governable params.
        bytes32[] memory allowedParams = new bytes32[](6);
        allowedParams[0] = "reputationDecayRatePerSecond";
        allowedParams[1] = "reputationDecayInterval";
        allowedParams[2] = "minReputationToPropose";
        allowedParams[3] = "proposalVotingPeriod";
        allowedParams[4] = "proposalExecutionDelay";
        allowedParams[5] = "proposalThresholdQuorum";
        // allowedParams[6] = "proposalPassThreshold"; // Pass threshold is sensitive, maybe keep admin only or higher quorum/pass rate?

        bool isAllowedParam = false;
        for(uint i = 0; i < allowedParams.length; i++) {
            if (_paramKey == allowedParams[i]) {
                isAllowedParam = true;
                break;
            }
        }
        require(isAllowedParam, "Parameter key not governable");


        _proposalIds.increment();
        proposalId = _proposalIds.current();

        uint64 voteStart = uint64(block.timestamp);
        uint64 voteEnd = voteStart + uint64(proposalVotingPeriod);

        _proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: proposer,
            description: _description,
            target: address(0), // Not a collective action proposal
            value: 0,           // Not a collective action proposal
            callData: "",       // Not a collective action proposal
            paramKey: _paramKey,
            newValue: _newValue,
            voteStart: voteStart,
            voteEnd: voteEnd,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            state: ProposalState.Active,
            isCollectiveAction: false,
            hasVoted: new mapping(address => bool)()
        });

        emit ParameterChangeProposed(proposalId, proposer, _paramKey, _newValue);
        emit ProposalCreated(proposalId, proposer, _description); // Also emit generic proposal event
        return proposalId;
    }


    function voteOnCollectiveAction(uint256 _proposalId, bool _support) public whenNotPaused {
        address voter = msg.sender;
        if (_userNFTId[voter] == 0) revert UserNotRegistered();

        Proposal storage proposal = _proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId); // Check if proposal exists

        if (proposal.state != ProposalState.Active || block.timestamp < proposal.voteStart || block.timestamp > proposal.voteEnd) {
             revert ProposalVotingPeriodNotActive(_proposalId);
        }

        if (proposal.hasVoted[voter]) {
            revert ProposalAlreadyVoted(voter, _proposalId);
        }

        uint256 votingPower = getVotingPower(voter);
        if (votingPower == 0) {
            revert NoVotingPower(voter);
        }

        proposal.hasVoted[voter] = true;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }

        emit Voted(voter, _proposalId, _support);
    }

    function voteOnSystemParameterChange(uint256 _proposalId, bool _support) public whenNotPaused {
        address voter = msg.sender;
         if (_userNFTId[voter] == 0) revert UserNotRegistered();

        Proposal storage proposal = _proposals[_proposalId];
        if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);

        if (proposal.state != ProposalState.Active || block.timestamp < proposal.voteStart || block.timestamp > proposal.voteEnd) {
             revert ProposalVotingPeriodNotActive(_proposalId);
        }
         if (proposal.isCollectiveAction) revert InvalidProposalState(_proposalId); // Ensure it's a param change proposal

        if (proposal.hasVoted[voter]) {
            revert ProposalAlreadyVoted(voter, _proposalId);
        }

        uint256 votingPower = getVotingPower(voter);
        if (votingPower == 0) {
            revert NoVotingPower(voter);
        }

        proposal.hasVoted[voter] = true;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(votingPower);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votingPower);
        }

        emit Voted(voter, _proposalId, _support);
    }

    // Internal helper to check if a proposal has passed
    function _checkProposalState(uint256 _proposalId) internal view returns (ProposalState) {
        Proposal storage proposal = _proposals[_proposalId];
         if (proposal.id == 0 && _proposalId != 0) return ProposalState.NotFound; // Indicate not found state

        if (proposal.state != ProposalState.Active) {
            return proposal.state; // Already decided or cancelled
        }

        if (block.timestamp <= proposal.voteEnd) {
            return ProposalState.Active; // Still in voting period
        }

        // Voting period is over, determine outcome
        // Calculate total votes cast (for + against)
        uint256 totalVotesCast = proposal.forVotes.add(proposal.againstVotes).add(proposal.abstainVotes); // Include abstain if used
        // Total voting power in the system at the start of the vote is hard to track precisely
        // A simpler approach uses a minimum quorum based on *cast* votes or requires a snapshot
        // of token/reputation supply at proposal creation time.
        // Let's use a simple quorum based on total cast votes vs a hypothetical max possible power (or a static value)
        // A more robust DAO would snapshot voting power or use a token supply oracle.
        // Simple quorum check: total votes cast meets a threshold compared to *some* baseline.
        // For simplicity, let's just require a minimum number of votes or a percentage of *participating* votes.
        // Option 1: Simple majority with minimum participants:
        // if (totalVotesCast < minVotesForQuorum) return ProposalState.Defeated;
        // Option 2: Percentage quorum based on a baseline (requires snapshot/oracle) - too complex for this example.
        // Option 3: Quorum based on percentage of *cast* votes reaching threshold (less secure).
        // Let's implement a basic quorum check relative to *total* voting power if we could sum it up easily,
        // or a simple minimum required `for` votes.

        // A realistic simple quorum check might be based on *registered users* count * base_power, or total reputation at a snapshot.
        // Without a snapshot mechanism, let's use a simple check:
        // If the total votes cast *meets* a minimum threshold, AND the 'for' votes *exceed* the 'against' votes by a margin.

        // Let's assume Quorum is checked against *votes cast* for simplicity in this demo.
        // Quorum check: Are total votes cast >= a percentage of *something*?
        // Or simpler: Is the number of 'for' votes >= a percentage of *total votes cast* AND >= a simple majority of (for+against)?
        // Quorum: (For + Against) / (For + Against + Abstain) >= proposalThresholdQuorum
        // Pass: For / (For + Against) >= proposalPassThreshold (ignoring abstain for pass rate, or factor it in)

        uint256 effectiveTotalVotes = proposal.forVotes.add(proposal.againstVotes); // Quorum and Pass based on For + Against

        // Basic Quorum Check: Is sum of FOR + AGAINST votes >= a percentage (e.g. 50%) of TOTAL_VOTING_POWER_SNAPSHOT?
        // Since we don't have a snapshot, let's redefine quorum slightly for this example:
        // Quorum: (forVotes + againstVotes) >= MIN_VOTES_NEEDED // A fixed number OR
        // Quorum: (forVotes + againstVotes) >= total_voting_power_at_start_of_vote * proposalThresholdQuorum / 100 // Requires snapshot
        // Let's use a simpler pass condition for this example: requires minimum FOR votes AND FOR > AGAINST.
        // A real DAO needs a proper quorum definition.

        // Simplified Pass Condition: For votes > Against votes AND For votes >= minimum threshold (e.g. 1 vote)
        // A common pattern: For votes > Against votes AND total votes (for+against) >= Quorum
        // Let's use a simplified quorum based on percentage of *cast* votes (less secure but simple):
        // Quorum met if total votes cast >= a percentage *of cast votes itself* (meaningful if total cast > 0).
        // Let's require a simple majority of (for + against) AND a minimum number of participants for quorum.

        // Let's define quorum as (forVotes + againstVotes) must be >= a *minimum number* of votes.
        // Let's define pass as forVotes > againstVotes AND total (for+against) meets quorum.
        // For this example, we don't have a global total voting power snapshot.
        // Let's make it: forVotes > againstVotes AND forVotes >= a simple minimum value (e.g., 1 vote).
        // This is very basic, not a robust DAO quorum.

        // Simple majority of *participating* (for+against) votes:
        if (proposal.forVotes > proposal.againstVotes) {
             // Check if enough total votes were cast to meet a conceptual "quorum"
             // For this demo, let's use a minimal quorum like requiring *some* total votes, e.g., > 0.
             // A real system would need a snapshot or other method for quorum calculation.
             if (effectiveTotalVotes > 0) { // Simple check that someone voted
                 // Passed voting period and simple majority check
                 // Now check execution delay
                 if (block.timestamp >= proposal.voteEnd + proposalExecutionDelay) {
                      return ProposalState.Succeeded; // Succeeded and ready for execution
                 } else {
                      return ProposalState.Queued; // Succeeded but in execution delay
                 }
             } else {
                 return ProposalState.Defeated; // No votes or not enough votes to pass threshold (simplified)
             }
        } else {
            return ProposalState.Defeated; // Did not get simple majority 'for' votes
        }
    }

    function executeCollectiveAction(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[_proposalId];
         if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);
         if (!proposal.isCollectiveAction) revert InvalidProposalState(_proposalId);

        ProposalState currentState = _checkProposalState(_proposalId);

        if (currentState == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);
        if (currentState != ProposalState.Succeeded) revert ProposalNotExecutable(_proposalId);

        // Execute the action
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, success);

        // Handle failure? Revert? Log? Depends on desired behavior.
        // require(success, "Proposal execution failed"); // Optional: revert on execution failure
    }

    function executeSystemParameterChange(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[_proposalId];
         if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);
        if (proposal.isCollectiveAction) revert InvalidProposalState(_proposalId); // Ensure it's a param change proposal

        ProposalState currentState = _checkProposalState(_proposalId);

        if (currentState == ProposalState.Executed) revert ProposalAlreadyExecuted(_proposalId);
        if (currentState != ProposalState.Succeeded) revert ProposalNotExecutable(_proposalId);

        // Apply the parameter change based on paramKey
        bytes32 paramKey = proposal.paramKey;
        uint256 newValue = proposal.newValue;

        // This part requires careful handling and a lookup for what paramKey corresponds to what state variable.
        // Using if/else or a mapping from bytes32 to a setter function/variable reference.
        // Example mapping: bytes32 -> function pointer (requires Solidity 0.8.11+) or using abi.encodeCall.
        // Simpler for demo: explicit checks:
        if (paramKey == "reputationDecayRatePerSecond") {
             reputationDecayRatePerSecond = newValue;
        } else if (paramKey == "reputationDecayInterval") {
             reputationDecayInterval = newValue;
        } else if (paramKey == "minReputationToPropose") {
             minReputationToPropose = newValue;
        } else if (paramKey == "proposalVotingPeriod") {
             proposalVotingPeriod = newValue;
        } else if (paramKey == "proposalExecutionDelay") {
             proposalExecutionDelay = newValue;
        } else if (paramKey == "proposalThresholdQuorum") {
             proposalThresholdQuorum = newValue;
        }
        // Add other governable parameters here

        proposal.state = ProposalState.Executed;
        emit ParameterChangeExecuted(_proposalId, paramKey, newValue);
        emit ProposalExecuted(_proposalId, true); // Also emit generic success
    }

     function getProposalDetails(uint256 _proposalId) public view returns (
         uint256 id,
         address proposer,
         string memory description,
         address target,
         uint256 value,
         bytes memory callData,
         bytes32 paramKey,
         uint256 newValue,
         uint256 voteStart,
         uint256 voteEnd,
         uint256 forVotes,
         uint256 againstVotes,
         uint256 abstainVotes,
         ProposalState state,
         bool isCollectiveAction
     ) {
         Proposal storage proposal = _proposals[_proposalId];
          if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);

         return (
             proposal.id,
             proposal.proposer,
             proposal.description,
             proposal.target,
             proposal.value,
             proposal.callData,
             proposal.paramKey,
             proposal.newValue,
             proposal.voteStart,
             proposal.voteEnd,
             proposal.forVotes,
             proposal.againstVotes,
             proposal.abstainVotes,
             _checkProposalState(_proposalId), // Return calculated state
             proposal.isCollectiveAction
         );
     }

    // --- Admin & Utility ---

     function addAllowedActivityType(
         bytes32 _activityType,
         uint256 _reputationGain,
         uint256 _cooldown,
         string memory _description
     ) public onlyOwner { // Could make this governance controlled instead of onlyOwner
         if (_allowedActivityTypes[_activityType].cooldown != 0 || _allowedActivityTypes[_activityType].reputationGain != 0 || bytes(_allowedActivityTypes[_activityType].description).length != 0) {
              revert ActivityTypeAlreadyExists(_activityType);
         }
         _allowedActivityTypes[_activityType] = ActivityParameters(_reputationGain, _cooldown, _description);
         emit AllowedActivityTypeAdded(_activityType, _reputationGain, _cooldown);
     }

    function updateActivityTypeParameters(
         bytes32 _activityType,
         uint256 _reputationGain,
         uint256 _cooldown,
         string memory _description
     ) public onlyOwner { // Could make this governance controlled
          if (_allowedActivityTypes[_activityType].cooldown == 0 && _allowedActivityTypes[_activityType].reputationGain == 0 && bytes(_allowedActivityTypes[_activityType].description).length == 0) {
               revert ActivityTypeNotFound(_activityType);
          }
          _allowedActivityTypes[_activityType] = ActivityParameters(_reputationGain, _cooldown, _description);
          emit AllowedActivityTypeUpdated(_activityType, _reputationGain, _cooldown);
     }

    function getAllowedActivityType(bytes32 _activityType) public view returns (ActivityParameters memory) {
        ActivityParameters memory params = _allowedActivityTypes[_activityType];
        if (params.cooldown == 0 && params.reputationGain == 0 && bytes(params.description).length == 0 && _activityType != bytes32(0)) {
             revert ActivityTypeNotFound(_activityType);
        }
        return params;
    }

    function setBaseReputationThresholds(uint256[] memory _newThresholds) public onlyOwner { // Could make this governance controlled
        require(_newThresholds.length > 0 && _newThresholds[0] == 0, "Invalid thresholds");
        for(uint i = 0; i < _newThresholds.length - 1; i++) {
            require(_newThresholds[i] < _newThresholds[i+1], "Thresholds must be strictly increasing");
        }
        reputationLevelThresholds = _newThresholds;
        // Consider triggering re-evaluation/event for all users or levels might change
    }

    // Example Admin function (use with caution, could bypass governance)
    // function grantReputation(address _user, uint256 _amount) public onlyOwner {
    //     if (_userNFTId[_user] == 0) revert UserNotRegistered();
    //     uint256 oldRep = _userReputation[_user];
    //     _userReputation[_user] = oldRep.add(_amount);
    //     emit ReputationUpdated(_user, oldRep, _userReputation[_user], "Admin Grant");
    //     _checkAndEmitNFTLevelUp(_user, oldRep, _userReputation[_user]);
    // }

     // ERC721Metadata required function (supportsInterface)
     function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
         return interfaceId == type(IERC721).interfaceId ||
                interfaceId == type(IERC721Metadata).interfaceId ||
                super.supportsInterface(interfaceId);
     }

}
```