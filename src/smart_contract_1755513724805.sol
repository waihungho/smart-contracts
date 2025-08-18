This smart contract, **ChronoNexus**, is designed as a decentralized protocol for managing access to digital assets or content streams (referred to as "Chronicles") based on a novel **Time-Weighted Staking** mechanism. Users stake CHRONO tokens, and their 'Temporal Access Rights' (TARs) are dynamically determined by both the *amount* staked and the *duration* of their stake. It incorporates a decentralized treasury, tiered access, and a basic governance system for protocol parameters and treasury management.

---

## ChronoNexus Smart Contract Outline & Function Summary

**Contract Name:** `ChronoNexus`

**Core Concepts:**
*   **Time-Weighted Staking:** User's effective stake for access calculations is `(stakedAmount * durationStaked)`.
*   **Dynamic Access Tiers:** Access duration and privileges are determined by the user's current time-weighted stake, allowing for flexible and escalating benefits.
*   **Decentralized Chronicle Registry:** On-chain registration and management of digital assets/content (Chronicles) with associated access rules.
*   **Protocol-Owned Value (Treasury):** Access fees are collected into a protocol treasury, managed by governance.
*   **Basic On-Chain Governance:** For modifying protocol parameters, managing access tiers, and treasury withdrawals.

---

**Function Summary (29 Functions):**

**I. Core Staking & Access Management (8 Functions)**
1.  `stakeCHRONO(uint256 _amount)`: Allows users to stake CHRONO tokens to gain access rights.
2.  `unstakeCHRONO(uint256 _amount)`: Allows users to withdraw their staked CHRONO tokens.
3.  `requestTemporalAccess(bytes32 _chronicleId, uint256 _duration)`: Allows users to request access to a specific Chronicle for a desired duration, paying an access fee.
4.  `extendTemporalAccess(bytes32 _chronicleId, uint256 _additionalDuration)`: Allows users to extend their existing access to a Chronicle.
5.  `checkTemporalAccess(address _user, bytes32 _chronicleId)`: View function to check if a user currently has access to a Chronicle.
6.  `getWeightedStake(address _user)`: View function to calculate a user's current time-weighted stake.
7.  `getAccessTier(address _user)`: View function to determine the user's current access tier based on their weighted stake.
8.  `revokeTemporalAccess(bytes32 _chronicleId, address _user)`: Owner/DAO can revoke access to a chronicle for a specific user (e.g., in case of abuse).

**II. Chronicle Registry Management (7 Functions)**
9.  `registerChronicle(bytes32 _chronicleId, string calldata _uri, address _creator, uint256 _baseAccessFee)`: Registers a new digital asset/Chronicle with its metadata and access fee.
10. `updateChronicleURI(bytes32 _chronicleId, string calldata _newUri)`: Allows the creator (or DAO) to update the URI of an existing Chronicle.
11. `updateChronicleAccessFee(bytes32 _chronicleId, uint256 _newFee)`: Allows the creator (or DAO) to update the access fee for a specific Chronicle.
12. `deactivateChronicle(bytes32 _chronicleId)`: Deactivates a Chronicle, preventing new access requests.
13. `reactivateChronicle(bytes32 _chronicleId)`: Reactivates a deactivated Chronicle.
14. `transferChronicleOwnership(bytes32 _chronicleId, address _newCreator)`: Allows the current creator to transfer ownership of a Chronicle.
15. `getChronicleDetails(bytes32 _chronicleId)`: View function to retrieve details of a registered Chronicle.

**III. Protocol Configuration & Governance (9 Functions)**
16. `setAccessTierConfig(uint256 _tierId, uint256 _minWeightedStake, uint256 _maxAccessDuration)`: Sets or updates the configuration for a specific access tier.
17. `removeAccessTier(uint256 _tierId)`: Removes an existing access tier.
18. `proposeParameterChange(bytes32 _paramId, bytes calldata _newValue, uint256 _executionDelay)`: Allows users to propose changes to protocol-level parameters (e.g., base access fee, min stake duration).
19. `voteOnProposal(bytes32 _proposalId, bool _support)`: Allows staked users to vote on active proposals.
20. `executeProposal(bytes32 _proposalId)`: Executes a successfully passed proposal after its execution delay.
21. `cancelProposal(bytes32 _proposalId)`: Allows the proposer or owner to cancel a proposal before its deadline.
22. `proposeTreasuryWithdrawal(bytes32 _proposalId, address _recipient, uint256 _amount)`: Creates a proposal specifically for withdrawing funds from the treasury.
23. `updateBaseAccessFee(uint256 _newFee)`: Allows DAO to update the global base access fee.
24. `updateMinStakeDuration(uint256 _newMinDuration)`: Allows DAO to update the minimum duration a user must stake.

**IV. Treasury & Miscellaneous (5 Functions)**
25. `depositToTreasury()`: Allows anyone to send ETH to the protocol treasury.
26. `getProtocolTreasuryBalance()`: View function to get the current ETH balance of the protocol treasury.
27. `getUserStakeDetails(address _user)`: View function to retrieve a user's staking information.
28. `getTierConfig(uint256 _tierId)`: View function to retrieve details of an access tier.
29. `getProposalDetails(bytes32 _proposalId)`: View function to retrieve details of a governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For proposal param parsing if needed, though bytes is more flexible

/// @title ChronoNexus
/// @author YourNameHere
/// @notice A decentralized protocol for managing access to digital assets (Chronicles)
///         based on time-weighted staking and dynamic access tiers, featuring on-chain governance.
contract ChronoNexus is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---

    IERC20 public immutable CHRONO_TOKEN; // The ERC-20 token used for staking and fees
    uint256 public baseAccessFeePerSecond; // Default access fee per second (in CHRONO tokens)
    uint256 public minStakeDuration;       // Minimum duration a user must stake for their stake to count towards weighted access

    // --- Structs ---

    struct Stake {
        uint256 amount;
        uint256 startTime; // Timestamp when staking started
        uint256 lastUpdateTime; // Last time stake was updated (for weighted stake calculation)
    }

    struct Chronicle {
        address creator;
        string uri; // URI pointing to the digital asset/content metadata
        uint256 baseAccessFee; // Override for general baseAccessFeePerSecond
        bool isActive;
        uint256 createdAt;
    }

    struct TemporalAccessRight {
        uint256 expiryTime;
        uint256 grantedAt;
        uint256 originalDuration;
    }

    struct AccessTierConfig {
        uint256 minWeightedStake; // Minimum time-weighted stake (amount * seconds) to qualify for this tier
        uint256 maxAccessDuration; // Maximum access duration (in seconds) granted by this tier
        bool exists; // To check if a tier has been configured
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct GovernanceProposal {
        bytes32 proposalId;
        string description;
        address proposer;
        uint256 creationTime;
        uint256 deadline; // Time when voting ends
        uint256 quorumRequired; // Minimum total votes needed (e.g., percentage of total stake)
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalState state;
        bytes32 paramId; // Identifier for the parameter being changed (e.g., "baseFee", "tierConfig")
        bytes newValue; // New value for the parameter (ABI encoded)
        uint256 executionDelay; // Time after success until executable
        uint256 executionTime; // When it was executed
    }

    // --- Mappings ---

    mapping(address => Stake) public userStakes;
    mapping(bytes32 => Chronicle) public chronicleRegistry; // chronicleId => Chronicle details
    mapping(address => mapping(bytes32 => TemporalAccessRight)) public userAccessRights; // user => chronicleId => access details
    mapping(uint256 => AccessTierConfig) public accessTiers; // tierId => AccessTierConfig
    mapping(bytes32 => GovernanceProposal) public governanceProposals; // proposalId => GovernanceProposal
    mapping(bytes32 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => user => voted
    mapping(address => uint256) public totalStakedByAddress; // Total staked by a specific address (redundant if using userStakes.amount directly but can be useful)

    // --- Events ---

    event Staked(address indexed user, uint256 amount, uint256 newTotalStake);
    event Unstaked(address indexed user, uint256 amount, uint256 newTotalStake);
    event TemporalAccessGranted(address indexed user, bytes32 indexed chronicleId, uint256 expiryTime, uint256 duration);
    event TemporalAccessExtended(address indexed user, bytes32 indexed chronicleId, uint256 newExpiryTime, uint256 additionalDuration);
    event TemporalAccessRevoked(address indexed user, bytes32 indexed chronicleId);
    event ChronicleRegistered(bytes32 indexed chronicleId, address indexed creator, string uri, uint256 baseAccessFee);
    event ChronicleUpdated(bytes32 indexed chronicleId, string newUri, uint256 newFee);
    event ChronicleDeactivated(bytes32 indexed chronicleId);
    event ChronicleReactivated(bytes32 indexed chronicleId);
    event ChronicleOwnershipTransferred(bytes32 indexed chronicleId, address indexed oldCreator, address indexed newCreator);
    event AccessTierConfigured(uint256 indexed tierId, uint256 minWeightedStake, uint256 maxAccessDuration);
    event AccessTierRemoved(uint256 indexed tierId);
    event ProposalSubmitted(bytes32 indexed proposalId, address indexed proposer, string description, uint256 deadline);
    event Voted(bytes32 indexed proposalId, address indexed voter, bool support, uint256 votesFor, uint256 votesAgainst);
    event ProposalStateChanged(bytes32 indexed proposalId, ProposalState newState);
    event ProposalExecuted(bytes32 indexed proposalId);
    event ProtocolTreasuryDeposited(address indexed depositor, uint256 amount);
    event ProtocolParameterUpdated(bytes32 indexed paramId, bytes newValue);

    // --- Modifiers ---

    modifier onlyChronicleCreator(bytes32 _chronicleId) {
        require(chronicleRegistry[_chronicleId].creator == msg.sender, "ChronoNexus: Not chronicle creator");
        _;
    }

    modifier onlyActiveChronicle(bytes32 _chronicleId) {
        require(chronicleRegistry[_chronicleId].isActive, "ChronoNexus: Chronicle is not active");
        _;
    }

    modifier onlyStaked(address _user) {
        require(userStakes[_user].amount > 0, "ChronoNexus: User has no stake");
        _;
    }

    modifier proposalExists(bytes32 _proposalId) {
        require(governanceProposals[_proposalId].proposer != address(0), "ChronoNexus: Proposal does not exist");
        _;
    }

    modifier onlyProposalState(bytes32 _proposalId, ProposalState _expectedState) {
        require(governanceProposals[_proposalId].state == _expectedState, "ChronoNexus: Invalid proposal state");
        _;
    }

    modifier notVoted(bytes32 _proposalId, address _voter) {
        require(!hasVotedOnProposal[_proposalId][_voter], "ChronoNexus: Already voted on this proposal");
        _;
    }

    // --- Constructor ---

    constructor(address _chronoTokenAddress, uint256 _baseAccessFeePerSecond, uint256 _minStakeDuration) Ownable(msg.sender) {
        require(_chronoTokenAddress != address(0), "ChronoNexus: Invalid CHRONO token address");
        CHRONO_TOKEN = IERC20(_chronoTokenAddress);
        baseAccessFeePerSecond = _baseAccessFeePerSecond;
        minStakeDuration = _minStakeDuration;
    }

    // --- Internal/Pure Helper Functions ---

    /// @dev Calculates the time-weighted stake for a user.
    ///      Weighted Stake = Staked Amount * Effective Staking Duration.
    ///      Effective duration is capped by `block.timestamp - stake.startTime`.
    ///      Requires a minimum `minStakeDuration` for stake to count.
    /// @param _user The address of the user.
    /// @return The calculated time-weighted stake.
    function _calculateWeightedStake(address _user) internal view returns (uint256) {
        Stake storage userStake = userStakes[_user];
        if (userStake.amount == 0) {
            return 0;
        }

        uint256 effectiveStartTime = userStake.startTime;
        if (block.timestamp < effectiveStartTime.add(minStakeDuration)) {
            // Stake has not been held for minimum duration yet, so no weighted stake accrues
            return 0;
        }

        uint256 durationStaked = block.timestamp.sub(effectiveStartTime);
        return userStake.amount.mul(durationStaked);
    }

    /// @dev Determines the best access tier for a given weighted stake.
    /// @param _weightedStake The user's time-weighted stake.
    /// @return The tier ID and its configuration. Returns (0, 0, 0, false) if no tier found.
    function _getBestAccessTierConfig(uint256 _weightedStake) internal view returns (uint256 tierId, AccessTierConfig memory config) {
        tierId = 0;
        config = AccessTierConfig(0, 0, false);
        for (uint256 i = 1; i <= 10; i++) { // Assuming max 10 tiers for simplicity, can be dynamic
            AccessTierConfig memory currentTier = accessTiers[i];
            if (currentTier.exists && _weightedStake >= currentTier.minWeightedStake) {
                if (currentTier.maxAccessDuration > config.maxAccessDuration) {
                    config = currentTier;
                    tierId = i;
                }
            }
        }
        return (tierId, config);
    }

    /// @dev Calculates the access fee for a specific chronicle and duration.
    /// @param _chronicleId The ID of the chronicle.
    /// @param _duration The requested access duration in seconds.
    /// @return The total access fee in CHRONO tokens.
    function _calculateAccessFee(bytes32 _chronicleId, uint256 _duration) internal view returns (uint256) {
        Chronicle storage chronicle = chronicleRegistry[_chronicleId];
        uint256 feePerSecond = chronicle.baseAccessFee > 0 ? chronicle.baseAccessFee : baseAccessFeePerSecond;
        return feePerSecond.mul(_duration);
    }

    /// @dev Executes a protocol parameter change based on the proposal.
    /// @param _proposal The governance proposal struct.
    function _applyParameterChange(GovernanceProposal storage _proposal) internal {
        if (_proposal.paramId == keccak256("baseAccessFeePerSecond")) {
            baseAccessFeePerSecond = abi.decode(_proposal.newValue, (uint256));
            emit ProtocolParameterUpdated(_proposal.paramId, _proposal.newValue);
        } else if (_proposal.paramId == keccak256("minStakeDuration")) {
            minStakeDuration = abi.decode(_proposal.newValue, (uint256));
            emit ProtocolParameterUpdated(_proposal.paramId, _proposal.newValue);
        } else if (_proposal.paramId == keccak256("setAccessTierConfig")) {
            (uint256 tierId, uint256 minWeightedStake, uint256 maxAccessDuration) = abi.decode(_proposal.newValue, (uint256, uint256, uint256));
            accessTiers[tierId] = AccessTierConfig(minWeightedStake, maxAccessDuration, true);
            emit AccessTierConfigured(tierId, minWeightedStake, maxAccessDuration);
        } else if (_proposal.paramId == keccak256("removeAccessTier")) {
            uint256 tierId = abi.decode(_proposal.newValue, (uint256));
            delete accessTiers[tierId];
            emit AccessTierRemoved(tierId);
        } else if (_proposal.paramId == keccak256("treasuryWithdrawal")) {
            (address recipient, uint256 amount) = abi.decode(_proposal.newValue, (address, uint256));
            (bool success,) = recipient.call{value: amount}("");
            require(success, "ChronoNexus: ETH transfer failed");
            emit ProtocolTreasuryDeposited(recipient, amount); // Reusing event for clarity
        } else {
            revert("ChronoNexus: Unknown parameter ID for execution");
        }
    }

    // --- I. Core Staking & Access Management ---

    /// @notice Allows users to stake CHRONO tokens to gain access rights.
    /// @dev Tokens are transferred from msg.sender to the contract.
    /// @param _amount The amount of CHRONO tokens to stake.
    function stakeCHRONO(uint256 _amount) external nonReentrant {
        require(_amount > 0, "ChronoNexus: Stake amount must be greater than 0");
        
        Stake storage userStake = userStakes[msg.sender];
        if (userStake.amount == 0) {
            userStake.startTime = block.timestamp;
        }
        userStake.amount = userStake.amount.add(_amount);
        userStake.lastUpdateTime = block.timestamp;

        require(CHRONO_TOKEN.transferFrom(msg.sender, address(this), _amount), "ChronoNexus: CHRONO transfer failed");
        emit Staked(msg.sender, _amount, userStake.amount);
    }

    /// @notice Allows users to withdraw their staked CHRONO tokens.
    /// @dev User's weighted stake calculation will be affected.
    /// @param _amount The amount of CHRONO tokens to unstake.
    function unstakeCHRONO(uint256 _amount) external nonReentrant onlyStaked(msg.sender) {
        Stake storage userStake = userStakes[msg.sender];
        require(userStake.amount >= _amount, "ChronoNexus: Insufficient staked amount");

        userStake.amount = userStake.amount.sub(_amount);
        // Reset startTime if all tokens are unstaked, or update lastUpdateTime
        if (userStake.amount == 0) {
            userStake.startTime = 0;
            userStake.lastUpdateTime = 0;
        } else {
             userStake.lastUpdateTime = block.timestamp;
        }

        require(CHRONO_TOKEN.transfer(msg.sender, _amount), "ChronoNexus: CHRONO transfer failed");
        emit Unstaked(msg.sender, _amount, userStake.amount);
    }

    /// @notice Allows users to request access to a specific Chronicle for a desired duration, paying an access fee.
    /// @dev Access duration is capped by the user's access tier. Fees are paid in CHRONO tokens.
    /// @param _chronicleId The ID of the Chronicle to request access for.
    /// @param _duration The desired duration of access in seconds.
    function requestTemporalAccess(bytes32 _chronicleId, uint256 _duration) external nonReentrant onlyStaked(msg.sender) onlyActiveChronicle(_chronicleId) {
        require(_duration > 0, "ChronoNexus: Duration must be greater than 0");

        // Determine max allowed access duration based on user's weighted stake
        (uint256 tierId, AccessTierConfig memory tierConfig) = _getBestAccessTierConfig(_calculateWeightedStake(msg.sender));
        require(tierConfig.exists, "ChronoNexus: No suitable access tier found for your stake");
        require(_duration <= tierConfig.maxAccessDuration, "ChronoNexus: Requested duration exceeds your tier's maximum");

        uint256 accessFee = _calculateAccessFee(_chronicleId, _duration);
        require(CHRONO_TOKEN.transferFrom(msg.sender, address(this), accessFee), "ChronoNexus: CHRONO fee payment failed");

        userAccessRights[msg.sender][_chronicleId] = TemporalAccessRight(
            block.timestamp.add(_duration),
            block.timestamp,
            _duration
        );

        emit TemporalAccessGranted(msg.sender, _chronicleId, userAccessRights[msg.sender][_chronicleId].expiryTime, _duration);
    }

    /// @notice Allows users to extend their existing access to a Chronicle.
    /// @dev New access duration is capped by the user's current tier's max access duration.
    /// @param _chronicleId The ID of the Chronicle to extend access for.
    /// @param _additionalDuration The additional duration to extend access by.
    function extendTemporalAccess(bytes32 _chronicleId, uint256 _additionalDuration) external nonReentrant onlyStaked(msg.sender) onlyActiveChronicle(_chronicleId) {
        require(_additionalDuration > 0, "ChronoNexus: Additional duration must be greater than 0");
        TemporalAccessRight storage currentAccess = userAccessRights[msg.sender][_chronicleId];
        require(currentAccess.expiryTime > 0, "ChronoNexus: No active access to extend");

        (uint256 tierId, AccessTierConfig memory tierConfig) = _getBestAccessTierConfig(_calculateWeightedStake(msg.sender));
        require(tierConfig.exists, "ChronoNexus: No suitable access tier found for your stake to extend");

        uint256 newTotalDuration = (currentAccess.expiryTime.sub(currentAccess.grantedAt)).add(_additionalDuration);
        require(newTotalDuration <= tierConfig.maxAccessDuration, "ChronoNexus: Extended duration exceeds your tier's maximum");

        uint256 accessFee = _calculateAccessFee(_chronicleId, _additionalDuration);
        require(CHRONO_TOKEN.transferFrom(msg.sender, address(this), accessFee), "ChronoNexus: CHRONO fee payment failed");

        currentAccess.expiryTime = currentAccess.expiryTime.add(_additionalDuration);
        currentAccess.originalDuration = newTotalDuration; // Update original duration to reflect total granted
        
        emit TemporalAccessExtended(msg.sender, _chronicleId, currentAccess.expiryTime, _additionalDuration);
    }

    /// @notice View function to check if a user currently has access to a Chronicle.
    /// @param _user The address of the user.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return True if the user has active access, false otherwise.
    function checkTemporalAccess(address _user, bytes32 _chronicleId) external view returns (bool) {
        TemporalAccessRight storage access = userAccessRights[_user][_chronicleId];
        return access.expiryTime > block.timestamp;
    }

    /// @notice View function to calculate a user's current time-weighted stake.
    /// @param _user The address of the user.
    /// @return The calculated time-weighted stake.
    function getWeightedStake(address _user) external view returns (uint256) {
        return _calculateWeightedStake(_user);
    }

    /// @notice View function to determine the user's current access tier based on their weighted stake.
    /// @param _user The address of the user.
    /// @return The ID of the user's access tier. Returns 0 if no tier is met.
    function getAccessTier(address _user) external view returns (uint256) {
        (uint256 tierId, ) = _getBestAccessTierConfig(_calculateWeightedStake(_user));
        return tierId;
    }

    /// @notice Owner/DAO can revoke access to a chronicle for a specific user (e.g., in case of abuse or policy violation).
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _user The address of the user whose access is to be revoked.
    function revokeTemporalAccess(bytes32 _chronicleId, address _user) external onlyOwner {
        TemporalAccessRight storage access = userAccessRights[_user][_chronicleId];
        require(access.expiryTime > block.timestamp, "ChronoNexus: User does not have active access to revoke");
        
        delete userAccessRights[_user][_chronicleId]; // Clear the access right
        emit TemporalAccessRevoked(_user, _chronicleId);
    }

    // --- II. Chronicle Registry Management ---

    /// @notice Registers a new digital asset/Chronicle with its metadata and access fee.
    /// @dev `_chronicleId` should be a unique identifier (e.g., keccak256 hash of a title).
    /// @param _chronicleId The unique ID for the new Chronicle.
    /// @param _uri URI pointing to the digital asset/content metadata.
    /// @param _creator The address of the creator of this Chronicle.
    /// @param _baseAccessFee An optional override for the global baseAccessFeePerSecond. Set to 0 to use global.
    function registerChronicle(bytes32 _chronicleId, string calldata _uri, address _creator, uint256 _baseAccessFee) external onlyOwner {
        require(chronicleRegistry[_chronicleId].creator == address(0), "ChronoNexus: Chronicle ID already registered");
        require(_creator != address(0), "ChronoNexus: Creator address cannot be zero");

        chronicleRegistry[_chronicleId] = Chronicle(
            _creator,
            _uri,
            _baseAccessFee,
            true, // Active by default
            block.timestamp
        );
        emit ChronicleRegistered(_chronicleId, _creator, _uri, _baseAccessFee);
    }

    /// @notice Allows the creator (or DAO via governance) to update the URI of an existing Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _newUri The new URI for the Chronicle.
    function updateChronicleURI(bytes32 _chronicleId, string calldata _newUri) external onlyChronicleCreator(_chronicleId) {
        require(chronicleRegistry[_chronicleId].creator != address(0), "ChronoNexus: Chronicle not found");
        chronicleRegistry[_chronicleId].uri = _newUri;
        emit ChronicleUpdated(_chronicleId, _newUri, chronicleRegistry[_chronicleId].baseAccessFee);
    }

    /// @notice Allows the creator (or DAO via governance) to update the access fee for a specific Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _newFee The new base access fee per second for this Chronicle.
    function updateChronicleAccessFee(bytes32 _chronicleId, uint256 _newFee) external onlyChronicleCreator(_chronicleId) {
        require(chronicleRegistry[_chronicleId].creator != address(0), "ChronoNexus: Chronicle not found");
        chronicleRegistry[_chronicleId].baseAccessFee = _newFee;
        emit ChronicleUpdated(_chronicleId, chronicleRegistry[_chronicleId].uri, _newFee);
    }

    /// @notice Deactivates a Chronicle, preventing new access requests but not affecting existing ones.
    /// @param _chronicleId The ID of the Chronicle to deactivate.
    function deactivateChronicle(bytes32 _chronicleId) external onlyChronicleCreator(_chronicleId) {
        require(chronicleRegistry[_chronicleId].isActive, "ChronoNexus: Chronicle is already deactivated");
        chronicleRegistry[_chronicleId].isActive = false;
        emit ChronicleDeactivated(_chronicleId);
    }

    /// @notice Reactivates a deactivated Chronicle, allowing new access requests again.
    /// @param _chronicleId The ID of the Chronicle to reactivate.
    function reactivateChronicle(bytes32 _chronicleId) external onlyChronicleCreator(_chronicleId) {
        require(!chronicleRegistry[_chronicleId].isActive, "ChronoNexus: Chronicle is already active");
        chronicleRegistry[_chronicleId].isActive = true;
        emit ChronicleReactivated(_chronicleId);
    }

    /// @notice Allows the current creator to transfer ownership of a Chronicle to a new address.
    /// @param _chronicleId The ID of the Chronicle.
    /// @param _newCreator The address of the new creator.
    function transferChronicleOwnership(bytes32 _chronicleId, address _newCreator) external onlyChronicleCreator(_chronicleId) {
        require(_newCreator != address(0), "ChronoNexus: New creator address cannot be zero");
        address oldCreator = chronicleRegistry[_chronicleId].creator;
        chronicleRegistry[_chronicleId].creator = _newCreator;
        emit ChronicleOwnershipTransferred(_chronicleId, oldCreator, _newCreator);
    }

    /// @notice View function to retrieve details of a registered Chronicle.
    /// @param _chronicleId The ID of the Chronicle.
    /// @return creator, uri, baseAccessFee, isActive, createdAt.
    function getChronicleDetails(bytes32 _chronicleId)
        external
        view
        returns (address creator, string memory uri, uint256 baseAccessFee, bool isActive, uint256 createdAt)
    {
        Chronicle storage c = chronicleRegistry[_chronicleId];
        require(c.creator != address(0), "ChronoNexus: Chronicle not found");
        return (c.creator, c.uri, c.baseAccessFee, c.isActive, c.createdAt);
    }

    // --- III. Protocol Configuration & Governance ---

    /// @notice Sets or updates the configuration for a specific access tier.
    /// @dev Can only be called by the owner (or DAO via governance).
    /// @param _tierId The ID of the tier (e.g., 1, 2, 3...).
    /// @param _minWeightedStake The minimum time-weighted stake required for this tier.
    /// @param _maxAccessDuration The maximum access duration (in seconds) granted by this tier.
    function setAccessTierConfig(uint256 _tierId, uint256 _minWeightedStake, uint256 _maxAccessDuration) external onlyOwner {
        require(_tierId > 0, "ChronoNexus: Tier ID must be greater than 0");
        require(_maxAccessDuration > 0, "ChronoNexus: Max access duration must be greater than 0");
        accessTiers[_tierId] = AccessTierConfig(_minWeightedStake, _maxAccessDuration, true);
        emit AccessTierConfigured(_tierId, _minWeightedStake, _maxAccessDuration);
    }

    /// @notice Removes an existing access tier.
    /// @dev Can only be called by the owner (or DAO via governance).
    /// @param _tierId The ID of the tier to remove.
    function removeAccessTier(uint256 _tierId) external onlyOwner {
        require(accessTiers[_tierId].exists, "ChronoNexus: Tier does not exist");
        delete accessTiers[_tierId];
        emit AccessTierRemoved(_tierId);
    }

    /// @notice Allows users to propose changes to protocol-level parameters (e.g., base access fee, min stake duration).
    /// @dev Proposal is identified by _paramId (e.g., keccak256("baseAccessFeePerSecond")).
    ///      _newValue is the ABI-encoded new value for the parameter.
    ///      _executionDelay is the time (in seconds) after a successful vote before the proposal can be executed.
    /// @param _proposalId Unique ID for the proposal (e.g., keccak256 of description).
    /// @param _description A description of the proposal.
    /// @param _paramId Identifier for the parameter being changed (e.g., keccak256("baseAccessFeePerSecond")).
    /// @param _newValue ABI encoded new value for the parameter.
    /// @param _executionDelay Delay before execution (for user awareness).
    function proposeParameterChange(
        bytes32 _proposalId,
        string calldata _description,
        bytes32 _paramId,
        bytes calldata _newValue,
        uint256 _executionDelay
    ) external onlyStaked(msg.sender) {
        require(governanceProposals[_proposalId].proposer == address(0), "ChronoNexus: Proposal ID already exists");
        
        // Define quorum (e.g., 1% of total staked CHRONO) and voting period (e.g., 7 days)
        uint256 votingPeriod = 7 days;
        uint256 totalStakedCHRONO = userStakes[msg.sender].amount; // Simplistic quorum, should be sum of all staked
        uint256 quorum = totalStakedCHRONO.div(100); // 1% of the proposer's stake as a placeholder

        governanceProposals[_proposalId] = GovernanceProposal(
            _proposalId,
            _description,
            msg.sender,
            block.timestamp,
            block.timestamp.add(votingPeriod),
            quorum,
            0,
            0,
            ProposalState.Active,
            _paramId,
            _newValue,
            _executionDelay,
            0
        );
        emit ProposalSubmitted(_proposalId, msg.sender, _description, governanceProposals[_proposalId].deadline);
    }

    /// @notice Allows staked users to vote on active proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(bytes32 _proposalId, bool _support) external onlyStaked(msg.sender) proposalExists(_proposalId) notVoted(_proposalId, msg.sender) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.state == ProposalState.Active, "ChronoNexus: Proposal is not active for voting");
        require(block.timestamp <= proposal.deadline, "ChronoNexus: Voting period has ended");

        uint256 voterStake = userStakes[msg.sender].amount; // Vote weight is based on raw staked amount
        require(voterStake > 0, "ChronoNexus: Voter must have active stake");

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(voterStake);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterStake);
        }

        hasVotedOnProposal[_proposalId][msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _support, proposal.votesFor, proposal.votesAgainst);

        // Check if voting period ended or enough votes to determine outcome
        if (block.timestamp >= proposal.deadline) {
            _checkProposalState(_proposalId);
        }
    }

    /// @dev Internal function to check and update proposal state after voting period ends or sufficient votes.
    function _checkProposalState(bytes32 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Active) {
            return; // Already processed
        }

        // Only process if deadline passed or enough votes received
        if (block.timestamp < proposal.deadline) {
            return;
        }

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalVotes < proposal.quorumRequired) {
            proposal.state = ProposalState.Failed; // Not enough participation
        } else if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded; // Passed
        } else {
            proposal.state = ProposalState.Failed; // Failed or tie
        }
        emit ProposalStateChanged(_proposalId, proposal.state);
    }

    /// @notice Executes a successfully passed proposal after its execution delay.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(bytes32 _proposalId) external nonReentrant proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        _checkProposalState(_proposalId); // Ensure state is up-to-date

        require(proposal.state == ProposalState.Succeeded, "ChronoNexus: Proposal not in succeeded state");
        require(block.timestamp >= proposal.deadline.add(proposal.executionDelay), "ChronoNexus: Execution delay not met");
        require(proposal.executionTime == 0, "ChronoNexus: Proposal already executed");

        _applyParameterChange(proposal);
        proposal.state = ProposalState.Executed;
        proposal.executionTime = block.timestamp;
        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    /// @notice Allows the proposer or owner to cancel a proposal before its deadline.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(bytes32 _proposalId) external proposalExists(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer == msg.sender || owner() == msg.sender, "ChronoNexus: Not proposer or owner");
        require(proposal.state == ProposalState.Pending || proposal.state == ProposalState.Active, "ChronoNexus: Proposal cannot be canceled in its current state");
        require(block.timestamp < proposal.deadline, "ChronoNexus: Cannot cancel a proposal after its deadline");

        proposal.state = ProposalState.Canceled;
        emit ProposalStateChanged(_proposalId, ProposalState.Canceled);
    }

    /// @notice Creates a proposal specifically for withdrawing funds from the treasury.
    /// @dev This is a specific type of parameter change proposal.
    /// @param _proposalId Unique ID for the proposal.
    /// @param _recipient The address to send funds to.
    /// @param _amount The amount of ETH to withdraw.
    function proposeTreasuryWithdrawal(bytes32 _proposalId, address _recipient, uint256 _amount) external onlyStaked(msg.sender) {
        require(_recipient != address(0), "ChronoNexus: Recipient cannot be zero address");
        require(_amount > 0, "ChronoNexus: Withdrawal amount must be greater than zero");
        require(_amount <= address(this).balance, "ChronoNexus: Insufficient treasury balance");

        // ABI encode the recipient and amount for the newValue field
        bytes memory newValue = abi.encode(_recipient, _amount);
        string memory description = string(abi.encodePacked("Treasury Withdrawal to ", Strings.toHexString(uint160(_recipient)), " for ", _amount.toString(), " ETH"));
        
        // Use a standard delay for treasury withdrawals, e.g., 3 days
        proposeParameterChange(
            _proposalId,
            description,
            keccak256("treasuryWithdrawal"), // Specific paramId for treasury withdrawals
            newValue,
            3 days
        );
    }

    /// @notice Allows DAO to update the global base access fee.
    /// @dev This function would typically be called by the `executeProposal` after a governance vote.
    /// @param _newFee The new base access fee per second.
    function updateBaseAccessFee(uint256 _newFee) external onlyOwner { // Or remove onlyOwner and make it only callable via internal _applyParameterChange
        baseAccessFeePerSecond = _newFee;
        emit ProtocolParameterUpdated(keccak256("baseAccessFeePerSecond"), abi.encode(_newFee));
    }

    /// @notice Allows DAO to update the minimum duration a user must stake for their stake to count towards weighted access.
    /// @dev This function would typically be called by the `executeProposal` after a governance vote.
    /// @param _newMinDuration The new minimum stake duration in seconds.
    function updateMinStakeDuration(uint256 _newMinDuration) external onlyOwner { // Or remove onlyOwner and make it only callable via internal _applyParameterChange
        minStakeDuration = _newMinDuration;
        emit ProtocolParameterUpdated(keccak256("minStakeDuration"), abi.encode(_newMinDuration));
    }

    // --- IV. Treasury & Miscellaneous ---

    /// @notice Allows anyone to send ETH to the protocol treasury.
    function depositToTreasury() external payable {
        require(msg.value > 0, "ChronoNexus: Deposit amount must be greater than 0");
        emit ProtocolTreasuryDeposited(msg.sender, msg.value);
    }

    /// @notice View function to get the current ETH balance of the protocol treasury.
    /// @return The current ETH balance.
    function getProtocolTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice View function to retrieve a user's staking information.
    /// @param _user The address of the user.
    /// @return amount, startTime, lastUpdateTime.
    function getUserStakeDetails(address _user) external view returns (uint256 amount, uint256 startTime, uint256 lastUpdateTime) {
        Stake storage s = userStakes[_user];
        return (s.amount, s.startTime, s.lastUpdateTime);
    }

    /// @notice View function to retrieve details of an access tier.
    /// @param _tierId The ID of the tier.
    /// @return minWeightedStake, maxAccessDuration, exists.
    function getTierConfig(uint256 _tierId) external view returns (uint256 minWeightedStake, uint256 maxAccessDuration, bool exists) {
        AccessTierConfig storage tc = accessTiers[_tierId];
        return (tc.minWeightedStake, tc.maxAccessDuration, tc.exists);
    }

    /// @notice View function to retrieve details of a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return description, proposer, creationTime, deadline, quorumRequired, votesFor, votesAgainst, state, paramId, newValue, executionDelay, executionTime.
    function getProposalDetails(bytes32 _proposalId)
        external
        view
        returns (
            string memory description,
            address proposer,
            uint256 creationTime,
            uint256 deadline,
            uint256 quorumRequired,
            uint256 votesFor,
            uint256 votesAgainst,
            ProposalState state,
            bytes32 paramId,
            bytes memory newValue,
            uint256 executionDelay,
            uint256 executionTime
        )
    {
        GovernanceProposal storage p = governanceProposals[_proposalId];
        require(p.proposer != address(0), "ChronoNexus: Proposal does not exist");
        return (
            p.description,
            p.proposer,
            p.creationTime,
            p.deadline,
            p.quorumRequired,
            p.votesFor,
            p.votesAgainst,
            p.state,
            p.paramId,
            p.newValue,
            p.executionDelay,
            p.executionTime
        );
    }

    /// @notice View function to check if a user has voted on a specific proposal.
    /// @param _proposalId The ID of the proposal.
    /// @param _user The address of the user.
    /// @return True if the user has voted, false otherwise.
    function hasVotedOnProposal(bytes32 _proposalId, address _user) external view returns (bool) {
        return hasVotedOnProposal[_proposalId][_user];
    }
}
```