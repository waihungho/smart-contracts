This smart contract, **Aegis Nexus**, introduces a novel concept of a "Decentralized Autonomous Adaptive Ecosystem." It's designed to be a self-sustaining, community-governed treasury whose operational parameters (like fees, staking rewards, and even governance thresholds) *adapt dynamically* based on an internally calculated "Ecosystem Health Score" and external market data provided by oracles.

The core idea is to create a "living" contract that can evolve its economic and governance rules to maintain stability and growth, while incentivizing active and beneficial participation through a reputation system and dynamic rewards. It combines elements of DAOs, DeFi staking, oracle integration, and dynamic tokenomics in a unique adaptive framework.

---

### **Aegis Nexus Smart Contract Outline & Function Summary**

**Contract Name:** `AegisNexus`

**Purpose:** To establish a self-regulating, community-governed treasury that dynamically adjusts its operational parameters based on an internal Ecosystem Health Score, external data, and community proposals, fostering long-term stability and incentivizing beneficial participation.

**Core Concepts:**

*   **Adaptive Parameters:** Contract parameters (e.g., staking rewards APR, proposal thresholds, treasury fees) are not fixed but dynamically adjust based on predefined formulas and the Ecosystem Health Score.
*   **Ecosystem Health Score:** A composite metric derived from various on-chain data points (e.g., treasury balance, token velocity, governance participation) reflecting the overall well-being of the Aegis Nexus.
*   **Role-Based Governance:** Utilizes `AccessControl` for distinct roles (Guardian, Oracle, Arbiter) with specific permissions and responsibilities.
*   **Oracle Integration:** Leverages external data (e.g., market prices, volatility) provided by trusted oracles to inform adaptive decisions. Includes a challenge and arbitration mechanism for data integrity.
*   **Reputation System:** Beyond token holdings, active and beneficial participation contributes to a user's reputation, potentially influencing voting power, reward multipliers, or access to features.
*   **Dynamic Staking & Incentives:** Staking rewards are not fixed but adapt based on ecosystem health and available treasury, providing flexible incentives.

---

**Function Categories & Summary (30 Functions):**

**I. Setup & Core Configuration**
1.  `constructor()`: Initializes the contract, setting the deployer as owner and initial admin.
2.  `setEcosystemToken(IERC20 _token)`: Sets the primary AEGIS ecosystem token address.
3.  `setOracleAddress(address _oracleAddress)`: Sets the address of the trusted oracle contract/endpoint for external data.
4.  `setContractURI(string memory _uri)`: Sets a URI for contract metadata or information.
5.  `pause()`: Allows owner/admin to pause contract operations in an emergency.
6.  `unpause()`: Allows owner/admin to unpause the contract.

**II. Treasury Management & Deposits**
7.  `depositNativeToken(uint256 _amount)`: Users deposit the AEGIS ecosystem token into the treasury.
8.  `depositEther()`: Users deposit native Ether into the treasury.
9.  `depositERC20(address _token, uint256 _amount)`: Users deposit any specified ERC20 token into the treasury.
10. `withdrawTreasuryFunds(address _token, address _recipient, uint256 _amount)`: Guardians can initiate withdrawals for approved proposals.
11. `getTreasuryBalance(address _token)`: Returns the balance of a specific token held in the treasury.

**III. Adaptive Parameters & Health Score**
12. `getEcosystemHealthScore()`: Calculates and returns the current composite Ecosystem Health Score.
13. `getAdaptiveParameterValue(bytes32 _paramId)`: Returns the current, dynamically adjusted value of a specific adaptive parameter.
14. `proposeAdaptiveFormulaChange(bytes32 _paramId, AdaptiveFormulaType _type, uint256 _min, uint256 _max, uint256 _factor)`: Allows governance to propose changes to the adaptive formula/bounds for a parameter.
15. `updateAdaptiveParameters()`: Triggers the recalculation and adjustment of all adaptive parameters based on the latest health score and approved formulas.

**IV. Governance & Proposal System**
16. `proposeTextProposal(string memory _description, bytes memory _calldata)`: Allows users with sufficient reputation to propose a generic action, potentially with executable calldata.
17. `voteOnProposal(bytes32 _proposalId, bool _support)`: Casts a vote (for or against) on an active proposal.
18. `executeProposal(bytes32 _proposalId)`: Executes a passed and not yet executed proposal.
19. `cancelProposal(bytes32 _proposalId)`: Allows proposer or guardian to cancel a proposal before voting ends.

**V. Oracle & Arbitration System**
20. `submitExternalData(bytes32 _key, uint256 _value, uint256 _timestamp)`: Oracles submit specific external data points (e.g., market price, volume).
21. `challengeExternalData(bytes32 _dataKey, uint256 _submissionIndex, string memory _reason)`: Users can challenge a specific submission of oracle data.
22. `arbitrateDataChallenge(bytes32 _dataKey, uint256 _submissionIndex, bool _isValid)`: Arbiters resolve a data challenge, validating or invalidating the data point.
23. `getLatestOracleData(bytes32 _key)`: Retrieves the latest validated data point for a given key.

**VI. Staking & Incentives**
24. `stakeTokens(uint256 _amount)`: Users stake AEGIS tokens to earn rewards and reputation.
25. `unstakeTokens(uint256 _amount)`: Users unstake AEGIS tokens.
26. `claimStakingRewards()`: Allows stakers to claim their dynamically calculated rewards.
27. `getPendingStakingRewards(address _staker)`: Returns the amount of pending staking rewards for a given staker.

**VII. Role Management & Reputation**
28. `grantRole(bytes32 _role, address _account)`: Owner/Admin grants specific roles (Guardian, Oracle, Arbiter) to an address.
29. `revokeRole(bytes32 _role, address _account)`: Owner/Admin revokes specific roles from an address.
30. `getReputationScore(address _account)`: Returns the reputation score of a given address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// --- Aegis Nexus Smart Contract Outline & Function Summary ---
//
// Contract Name: `AegisNexus`
// Purpose: To establish a self-regulating, community-governed treasury that dynamically adjusts its operational parameters
//          based on an internal Ecosystem Health Score, external data, and community proposals, fostering long-term
//          stability and incentivizing beneficial participation.
//
// Core Concepts:
// - Adaptive Parameters: Contract parameters (e.g., staking rewards APR, proposal thresholds, treasury fees) are not fixed
//   but dynamically adjust based on predefined formulas and the Ecosystem Health Score.
// - Ecosystem Health Score: A composite metric derived from various on-chain data points (e.g., treasury balance,
//   token velocity, governance participation) reflecting the overall well-being of the Aegis Nexus.
// - Role-Based Governance: Utilizes `AccessControl` for distinct roles (Guardian, Oracle, Arbiter) with specific
//   permissions and responsibilities.
// - Oracle Integration: Leverages external data (e.g., market prices, volatility) provided by trusted oracles to
//   inform adaptive decisions. Includes a challenge and arbitration mechanism for data integrity.
// - Reputation System: Beyond token holdings, active and beneficial participation contributes to a user's reputation,
//   potentially influencing voting power, reward multipliers, or access to features.
// - Dynamic Staking & Incentives: Staking rewards are not fixed but adapt based on ecosystem health and available
//   treasury, providing flexible incentives.
//
// Function Categories & Summary (30 Functions):
//
// I. Setup & Core Configuration
// 1.  constructor(): Initializes the contract, setting the deployer as owner and initial admin.
// 2.  setEcosystemToken(IERC20 _token): Sets the primary AEGIS ecosystem token address.
// 3.  setOracleAddress(address _oracleAddress): Sets the address of the trusted oracle contract/endpoint for external data.
// 4.  setContractURI(string memory _uri): Sets a URI for contract metadata or information.
// 5.  pause(): Allows owner/admin to pause contract operations in an emergency.
// 6.  unpause(): Allows owner/admin to unpause the contract.
//
// II. Treasury Management & Deposits
// 7.  depositNativeToken(uint256 _amount): Users deposit the AEGIS ecosystem token into the treasury.
// 8.  depositEther(): Users deposit native Ether into the treasury.
// 9.  depositERC20(address _token, uint256 _amount): Users deposit any specified ERC20 token into the treasury.
// 10. withdrawTreasuryFunds(address _token, address _recipient, uint256 _amount): Guardians can initiate withdrawals for approved proposals.
// 11. getTreasuryBalance(address _token): Returns the balance of a specific token held in the treasury.
//
// III. Adaptive Parameters & Health Score
// 12. getEcosystemHealthScore(): Calculates and returns the current composite Ecosystem Health Score.
// 13. getAdaptiveParameterValue(bytes32 _paramId): Returns the current, dynamically adjusted value of a specific adaptive parameter.
// 14. proposeAdaptiveFormulaChange(bytes32 _paramId, AdaptiveFormulaType _type, uint256 _min, uint256 _max, uint256 _factor): Allows governance to propose changes to the adaptive formula/bounds for a parameter.
// 15. updateAdaptiveParameters(): Triggers the recalculation and adjustment of all adaptive parameters based on the latest health score and approved formulas.
//
// IV. Governance & Proposal System
// 16. proposeTextProposal(string memory _description, bytes memory _calldata): Allows users with sufficient reputation to propose a generic action, potentially with executable calldata.
// 17. voteOnProposal(bytes32 _proposalId, bool _support): Casts a vote (for or against) on an active proposal.
// 18. executeProposal(bytes32 _proposalId): Executes a passed and not yet executed proposal.
// 19. cancelProposal(bytes32 _proposalId): Allows proposer or guardian to cancel a proposal before voting ends.
//
// V. Oracle & Arbitration System
// 20. submitExternalData(bytes32 _key, uint256 _value, uint256 _timestamp): Oracles submit specific external data points (e.g., market price, volume).
// 21. challengeExternalData(bytes32 _dataKey, uint256 _submissionIndex, string memory _reason): Users can challenge a specific submission of oracle data.
// 22. arbitrateDataChallenge(bytes32 _dataKey, uint256 _submissionIndex, bool _isValid): Arbiters resolve a data challenge, validating or invalidating the data point.
// 23. getLatestOracleData(bytes32 _key): Retrieves the latest validated data point for a given key.
//
// VI. Staking & Incentives
// 24. stakeTokens(uint256 _amount): Users stake AEGIS tokens to earn rewards and reputation.
// 25. unstakeTokens(uint256 _amount): Users unstake AEGIS tokens.
// 26. claimStakingRewards(): Allows stakers to claim their dynamically calculated rewards.
// 27. getPendingStakingRewards(address _staker): Returns the amount of pending staking rewards for a given staker.
//
// VII. Role Management & Reputation
// 28. grantRole(bytes32 _role, address _account): Owner/Admin grants specific roles (Guardian, Oracle, Arbiter) to an address.
// 29. revokeRole(bytes32 _role, address _account): Owner/Admin revokes specific roles from an address.
// 30. getReputationScore(address _account): Returns the reputation score of a given address.

contract AegisNexus is Ownable, AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- Roles ---
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE"); // Can manage treasury, execute proposals
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");     // Can submit external data
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");   // Can resolve data challenges

    // --- Ecosystem Token ---
    IERC20 public aegisToken; // The native ecosystem token

    // --- Treasury ---
    // The contract itself holds the funds. Balances can be checked via getTreasuryBalance.

    // --- Adaptive Parameters ---
    enum AdaptiveFormulaType { Linear, Step, InverseLinear }

    struct AdaptiveParameter {
        uint256 value;      // Current calculated value
        AdaptiveFormulaType formulaType; // How it adapts (e.g., Linear, Step, InverseLinear)
        uint256 minThreshold; // Minimum value for the parameter
        uint256 maxThreshold; // Maximum value for the parameter
        uint256 adaptationFactor; // Factor used in the formula calculation (e.g., slope, step size)
        uint256 lastUpdatedBlock; // Last block this parameter was updated
        bytes32 proposalId; // ID of the proposal that defined this formula
    }

    mapping(bytes32 => AdaptiveParameter) public adaptiveParameters;
    EnumerableSet.Bytes32Set private _adaptiveParameterIds; // To iterate through all adaptive parameters

    bytes32 public constant PARAM_STAKING_APR = keccak256("STAKING_APR");
    bytes32 public constant PARAM_PROPOSAL_THRESHOLD = keccak256("PROPOSAL_THRESHOLD");
    bytes32 public constant PARAM_VOTING_PERIOD = keccak256("VOTING_PERIOD");
    bytes32 public constant PARAM_TREASURY_FEE = keccak256("TREASURY_FEE"); // % taken on deposits/withdrawals

    // --- Ecosystem Health Score ---
    // Placeholder. In a real scenario, this would involve complex logic combining multiple metrics.
    // For this example, we'll use a simplified aggregate of treasury balance and active stakers.
    uint256 public healthScoreMultiplier = 1e18; // 1.0 for calculations

    // --- Governance & Proposals ---
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed, Canceled }

    struct Proposal {
        bytes32 id;
        string description;
        address proposer;
        uint256 votingPeriodEndBlock;
        uint256 quorumThreshold;     // Minimum votes needed
        uint256 yesVotes;
        uint256 noVotes;
        uint256 reputationRequired; // Minimum reputation to propose
        bytes callData;              // Optional calldata for execution
        address target;              // Target contract for execution
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Voter tracking
    }

    mapping(bytes32 => Proposal) public proposals;
    uint256 public nextProposalId = 1; // Used to generate unique proposal IDs

    // --- Oracle Data & Arbitration ---
    struct OracleDataPoint {
        uint256 value;
        uint256 timestamp;
        address submitter;
        bool isValidated; // true if validated, false if challenged and not yet arbitrated / invalid
    }

    enum ChallengeStatus { Pending, Validated, Invalidated }

    struct Challenge {
        bytes32 dataKey;
        uint256 submissionIndex;
        address challenger;
        string reason;
        ChallengeStatus status;
    }

    mapping(bytes32 => OracleDataPoint[]) public oracleDataSubmissions; // key -> array of submissions
    mapping(bytes32 => mapping(uint256 => bytes32)) public challengeIdsForData; // dataKey -> submissionIndex -> challengeId
    mapping(bytes32 => Challenge) public challenges; // challengeId -> Challenge struct
    uint256 public nextChallengeId = 1;

    // --- Staking & Incentives ---
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 rewardDebt; // Tracks rewards claimed vs. accumulated based on APR changes
        uint256 lastStakeBlock; // Block number of last stake/unstake
    }

    mapping(address => StakerInfo) public stakers;
    uint256 public totalStakedAmount;

    // --- Reputation System ---
    // Reputation can influence voting power, reward multipliers, or access to certain features.
    // For simplicity, it's a direct score. Guardians can update it based on actions.
    mapping(address => uint256) public reputationScores;

    // --- Utility ---
    string public contractURI;

    // --- Events ---
    event EcosystemTokenSet(address indexed _token);
    event OracleAddressSet(address indexed _oracleAddress);
    event ContractURISet(string _uri);
    event Deposited(address indexed _token, address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _token, address indexed _recipient, uint256 _amount);
    event ParameterValueUpdated(bytes32 indexed _paramId, uint256 _newValue, uint256 _block);
    event AdaptiveFormulaProposed(bytes32 indexed _paramId, bytes32 indexed _proposalId, AdaptiveFormulaType _type, uint256 _min, uint256 _max, uint256 _factor);
    event ProposalCreated(bytes32 indexed _proposalId, address indexed _proposer, string _description);
    event Voted(bytes32 indexed _proposalId, address indexed _voter, bool _support);
    event ProposalExecuted(bytes32 indexed _proposalId);
    event ProposalCanceled(bytes32 indexed _proposalId);
    event ExternalDataSubmitted(bytes32 indexed _key, uint256 _value, uint256 _timestamp, address indexed _submitter);
    event ExternalDataChallenged(bytes32 indexed _dataKey, uint256 _submissionIndex, bytes32 indexed _challengeId, address indexed _challenger);
    event DataChallengeArbitrated(bytes32 indexed _challengeId, bool _isValid);
    event TokensStaked(address indexed _staker, uint256 _amount);
    event TokensUnstaked(address indexed _staker, uint256 _amount);
    event StakingRewardsClaimed(address indexed _staker, uint256 _amount);
    event ReputationUpdated(address indexed _account, uint256 _newScore);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // --- Errors ---
    error InvalidAmount();
    error ZeroAddress();
    error TokenNotSet();
    error OracleNotSet();
    error NotEnoughBalance();
    error ProposalNotFound();
    error ProposalNotActive();
    error AlreadyVoted();
    error QuorumNotReached();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error InsufficientReputation();
    error InvalidVotingPeriod();
    error DataNotFound();
    error NotOracle();
    error DataAlreadyChallenged();
    error NotArbiter();
    error ChallengeNotFound();
    error ChallengeNotPending();
    error StakingAmountInvalid();
    error NotStaked();
    error RewardsNotAvailable();
    error WithdrawFailed();
    error InvalidParameterId();
    error NoAdaptiveParameterValue();
    error InsufficientPermissions();

    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GUARDIAN_ROLE, msg.sender); // Grant deployer guardian role initially
        _setRoleAdmin(GUARDIAN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ORACLE_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ARBITER_ROLE, DEFAULT_ADMIN_ROLE);

        // Initialize default adaptive parameters
        _initializeAdaptiveParameter(PARAM_STAKING_APR, AdaptiveFormulaType.Linear, 100, 1000, 50, "INITIAL_STAKING_APR"); // 1% to 10% APR
        _initializeAdaptiveParameter(PARAM_PROPOSAL_THRESHOLD, AdaptiveFormulaType.InverseLinear, 100, 5000, 10, "INITIAL_PROPOSAL_THRESHOLD"); // e.g., 100 to 5000 AEGIS to propose
        _initializeAdaptiveParameter(PARAM_VOTING_PERIOD, AdaptiveFormulaType.Step, 100, 10000, 200, "INITIAL_VOTING_PERIOD"); // Blocks
        _initializeAdaptiveParameter(PARAM_TREASURY_FEE, AdaptiveFormulaType.InverseLinear, 1, 100, 5, "INITIAL_TREASURY_FEE"); // 0.01% to 1%
    }

    // --- I. Setup & Core Configuration ---

    /// @notice Sets the primary AEGIS ecosystem token address.
    /// @param _token The address of the AEGIS ERC20 token.
    function setEcosystemToken(IERC20 _token) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(_token) == address(0)) revert ZeroAddress();
        aegisToken = _token;
        emit EcosystemTokenSet(address(_token));
    }

    /// @notice Sets the address of the trusted external oracle contract/endpoint.
    /// @dev This contract does not interact with the oracle directly, but assumes `submitExternalData`
    ///      is used by a trusted source.
    /// @param _oracleAddress The address of the oracle contract.
    address public trustedOracleAddress; // Placeholder, not used for direct calls within this contract

    function setOracleAddress(address _oracleAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_oracleAddress == address(0)) revert ZeroAddress();
        trustedOracleAddress = _oracleAddress;
        emit OracleAddressSet(_oracleAddress);
    }

    /// @notice Sets a URI for contract metadata or information.
    /// @param _uri The URI string.
    function setContractURI(string memory _uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
        emit ContractURISet(_uri);
    }

    /// @notice Pauses contract operations.
    /// @dev Only DEFAULT_ADMIN_ROLE can call this.
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses contract operations.
    /// @dev Only DEFAULT_ADMIN_ROLE can call this.
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice Returns the contract version (utility).
    function version() public pure returns (string memory) {
        return "Aegis Nexus v1.0";
    }

    // --- II. Treasury Management & Deposits ---

    /// @notice Users deposit the AEGIS ecosystem token into the treasury.
    /// @param _amount The amount of AEGIS tokens to deposit.
    function depositNativeToken(uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (address(aegisToken) == address(0)) revert TokenNotSet();

        aegisToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(address(aegisToken), msg.sender, _amount);
    }

    /// @notice Users deposit native Ether into the treasury.
    function depositEther() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        emit Deposited(address(0), msg.sender, msg.value);
    }

    /// @notice Users deposit any specified ERC20 token into the treasury.
    /// @param _token The address of the ERC20 token.
    /// @param _amount The amount of ERC20 tokens to deposit.
    function depositERC20(address _token, uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (_token == address(0)) revert ZeroAddress();

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(_token, msg.sender, _amount);
    }

    /// @notice Guardians can initiate withdrawals of funds for approved purposes (e.g., after a passed proposal).
    /// @param _token The address of the token to withdraw (address(0) for Ether).
    /// @param _recipient The address to send the funds to.
    /// @param _amount The amount to withdraw.
    function withdrawTreasuryFunds(address _token, address _recipient, uint256 _amount)
        public
        onlyRole(GUARDIAN_ROLE)
        whenNotPaused
        nonReentrant
    {
        if (_amount == 0) revert InvalidAmount();
        if (_recipient == address(0)) revert ZeroAddress();

        if (_token == address(0)) {
            // Withdraw Ether
            if (address(this).balance < _amount) revert NotEnoughBalance();
            (bool success,) = _recipient.call{value: _amount}("");
            if (!success) revert WithdrawFailed();
        } else {
            // Withdraw ERC20
            if (IERC20(_token).balanceOf(address(this)) < _amount) revert NotEnoughBalance();
            IERC20(_token).safeTransfer(_recipient, _amount);
        }
        emit Withdrawn(_token, _recipient, _amount);
    }

    /// @notice Returns the balance of a specific token held in the treasury.
    /// @param _token The address of the token (address(0) for Ether).
    /// @return The balance of the token in the treasury.
    function getTreasuryBalance(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    // --- III. Adaptive Parameters & Health Score ---

    /// @dev Internal helper to initialize adaptive parameters from constructor.
    function _initializeAdaptiveParameter(
        bytes32 _paramId,
        AdaptiveFormulaType _type,
        uint256 _min,
        uint256 _max,
        uint256 _factor,
        string memory _proposalIdStr
    ) private {
        adaptiveParameters[_paramId] = AdaptiveParameter({
            value: (_min + _max) / 2, // Start with a mid-range value
            formulaType: _type,
            minThreshold: _min,
            maxThreshold: _max,
            adaptationFactor: _factor,
            lastUpdatedBlock: block.number,
            proposalId: keccak256(abi.encodePacked(_proposalIdStr)) // Simple ID for initial setup
        });
        _adaptiveParameterIds.add(_paramId);
    }


    /// @notice Calculates and returns the current composite Ecosystem Health Score.
    /// @dev This is a simplified example. A real DAASE would use multiple on-chain metrics,
    ///      potentially with weighted averages or more complex logic.
    /// @return The calculated Ecosystem Health Score.
    function getEcosystemHealthScore() public view returns (uint256) {
        uint256 treasuryBalance = getTreasuryBalance(address(aegisToken));
        uint256 totalStakers = EnumerableSet.AddressSet(getRoleMember(GUARDIAN_ROLE)).length(); // Placeholder for active stakers
        // Example calculation: (Treasury Balance + (Total Staked * 10)) / (100 * total stakers)
        // Adjust for decimals, assuming aegisToken has 18 decimals and health score is a value between 0-1000
        uint256 healthScore;
        if (totalStakedAmount > 0) {
            healthScore = (treasuryBalance.add(totalStakedAmount.mul(10))).div(totalStakedAmount.mul(100)).mul(healthScoreMultiplier);
        } else {
            healthScore = treasuryBalance.div(1e18).mul(10).mul(healthScoreMultiplier); // Simplified if no staking
        }

        // Cap health score for reasonable range, e.g., 0 to 1000 * multiplier
        if (healthScore > 1000 * healthScoreMultiplier) {
            healthScore = 1000 * healthScoreMultiplier;
        }

        return healthScore;
    }

    /// @notice Returns the current, dynamically adjusted value of a specific adaptive parameter.
    /// @param _paramId The ID of the adaptive parameter (e.g., PARAM_STAKING_APR).
    /// @return The current value of the parameter.
    function getAdaptiveParameterValue(bytes32 _paramId) public view returns (uint256) {
        if (!_adaptiveParameterIds.contains(_paramId)) revert InvalidParameterId();
        return adaptiveParameters[_paramId].value;
    }

    /// @notice Allows governance to propose changes to the adaptive formula/bounds for a parameter.
    /// @dev This creates a proposal that, if passed, updates the AdaptiveParameter struct.
    /// @param _paramId The ID of the adaptive parameter.
    /// @param _type The new AdaptiveFormulaType.
    /// @param _min The new minimum threshold for the parameter.
    /// @param _max The new maximum threshold for the parameter.
    /// @param _factor The new adaptation factor.
    function proposeAdaptiveFormulaChange(
        bytes32 _paramId,
        AdaptiveFormulaType _type,
        uint256 _min,
        uint256 _max,
        uint256 _factor
    ) public whenNotPaused {
        if (!_adaptiveParameterIds.contains(_paramId)) revert InvalidParameterId();
        // Here, reputationRequired could be used for proposing new rules.
        // For simplicity, using a default threshold.
        uint256 proposalThreshold = getAdaptiveParameterValue(PARAM_PROPOSAL_THRESHOLD);
        if (getTreasuryBalance(address(aegisToken)) < proposalThreshold) revert InsufficientReputation(); // Simplified for now

        // Create a new proposal for this formula change
        bytes32 propId = keccak256(abi.encodePacked(nextProposalId, msg.sender, _paramId, block.timestamp));
        Proposal storage newProposal = proposals[propId];
        newProposal.id = propId;
        newProposal.description = string(abi.encodePacked("Change adaptive formula for ", Strings.toString(uint256(_paramId))));
        newProposal.proposer = msg.sender;
        newProposal.votingPeriodEndBlock = block.number + getAdaptiveParameterValue(PARAM_VOTING_PERIOD);
        newProposal.quorumThreshold = 1; // Simplified quorum
        newProposal.reputationRequired = 0; // Not checking reputation for proposing formula changes directly here

        // The calldata for this proposal will be to update the formula directly in the `executeProposal`
        // For simplicity, we directly store the proposed values in a temporary mapping or as part of the proposal description.
        // A more robust system would encode specific calldata to a setter function.
        // For this example, let's assume `executeProposal` directly reads the values from this proposal struct.
        // This is a simplification. A real implementation would use dynamic calldata.
        newProposal.status = ProposalStatus.Active;
        // Store parameters for potential update. This is tricky with existing struct.
        // A more advanced approach: store these as `bytes` in calldata and decode in `executeProposal`.
        // For now, assume this function itself implies the update, or we need a helper struct.
        // Let's modify the `Proposal` struct slightly for this specific type of proposal.
        // For a generic `proposeTextProposal`, the `_calldata` would handle this.
        // This function will just create a textual proposal, and `executeProposal` will need to be smart.
        // Or, more simply, we use _calldata:
        newProposal.target = address(this);
        newProposal.callData = abi.encodeWithSelector(
            this.updateAdaptiveParameterFormula.selector,
            _paramId, _type, _min, _max, _factor, propId
        );


        nextProposalId++;
        emit AdaptiveFormulaProposed(_paramId, propId, _type, _min, _max, _factor);
        emit ProposalCreated(propId, msg.sender, newProposal.description);
    }

    /// @dev Internal function to be called by `executeProposal` to apply formula changes.
    function updateAdaptiveParameterFormula(
        bytes32 _paramId,
        AdaptiveFormulaType _type,
        uint256 _min,
        uint256 _max,
        uint256 _factor,
        bytes32 _formulaProposalId
    ) public onlyRole(GUARDIAN_ROLE) { // Only Guardian can execute this (via a passed proposal)
        if (!_adaptiveParameterIds.contains(_paramId)) revert InvalidParameterId();

        AdaptiveParameter storage param = adaptiveParameters[_paramId];
        param.formulaType = _type;
        param.minThreshold = _min;
        param.maxThreshold = _max;
        param.adaptationFactor = _factor;
        param.proposalId = _formulaProposalId; // Link to the proposal that approved this formula
        // Value not updated here, it's updated by `updateAdaptiveParameters`
    }

    /// @notice Triggers the recalculation and adjustment of all adaptive parameters based on the latest health score and approved formulas.
    /// @dev Can be called by anyone (or by a Chainlink Keeper) to keep parameters up-to-date.
    function updateAdaptiveParameters() public whenNotPaused {
        uint256 healthScore = getEcosystemHealthScore();

        for (uint256 i = 0; i < _adaptiveParameterIds.length(); i++) {
            bytes32 paramId = _adaptiveParameterIds.at(i);
            AdaptiveParameter storage param = adaptiveParameters[paramId];

            uint256 newValue;
            // Example adaptation logic (simplified)
            if (param.formulaType == AdaptiveFormulaType.Linear) {
                // Higher healthScore -> higher value
                newValue = param.minThreshold.add(
                    (param.maxThreshold.sub(param.minThreshold)).mul(healthScore).div(1000 * healthScoreMultiplier) // Normalize healthScore to 0-1
                );
            } else if (param.formulaType == AdaptiveFormulaType.InverseLinear) {
                // Higher healthScore -> lower value
                newValue = param.maxThreshold.sub(
                    (param.maxThreshold.sub(param.minThreshold)).mul(healthScore).div(1000 * healthScoreMultiplier)
                );
            } else if (param.formulaType == AdaptiveFormulaType.Step) {
                // Adjust based on health score ranges (e.g., 3 steps)
                if (healthScore < 333 * healthScoreMultiplier) {
                    newValue = param.minThreshold;
                } else if (healthScore < 666 * healthScoreMultiplier) {
                    newValue = (param.minThreshold.add(param.maxThreshold)).div(2);
                } else {
                    newValue = param.maxThreshold;
                }
            } else {
                // Default to min threshold if formula type is unknown
                newValue = param.minThreshold;
            }

            // Ensure value stays within bounds
            if (newValue < param.minThreshold) newValue = param.minThreshold;
            if (newValue > param.maxThreshold) newValue = param.maxThreshold;

            if (param.value != newValue) {
                param.value = newValue;
                param.lastUpdatedBlock = block.number;
                emit ParameterValueUpdated(paramId, newValue, block.number);
            }
        }
    }


    // --- IV. Governance & Proposal System ---

    /// @notice Allows users with sufficient reputation to propose a generic action.
    /// @param _description A clear description of the proposal.
    /// @param _calldata Optional calldata for direct contract execution if the proposal passes.
    /// @dev The `target` for `_calldata` execution defaults to this contract.
    function proposeTextProposal(string memory _description, bytes memory _calldata) public whenNotPaused {
        uint256 reputationScore = reputationScores[msg.sender];
        uint256 proposalReputationThreshold = getAdaptiveParameterValue(PARAM_PROPOSAL_THRESHOLD); // Using parameter for proposal cost

        if (reputationScore < proposalReputationThreshold) revert InsufficientReputation();

        bytes32 propId = keccak256(abi.encodePacked(nextProposalId, msg.sender, block.timestamp));
        Proposal storage newProposal = proposals[propId];
        newProposal.id = propId;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.votingPeriodEndBlock = block.number + getAdaptiveParameterValue(PARAM_VOTING_PERIOD);
        newProposal.quorumThreshold = 1; // Simplified quorum: 1 vote
        newProposal.reputationRequired = proposalReputationThreshold;
        newProposal.callData = _calldata;
        newProposal.target = address(this); // Default target is this contract
        newProposal.status = ProposalStatus.Active;

        nextProposalId++;
        emit ProposalCreated(propId, msg.sender, _description);
    }

    /// @notice Casts a vote (for or against) on an active proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yes', false for 'no'.
    function voteOnProposal(bytes32 _proposalId, bool _support) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.number > proposal.votingPeriodEndBlock) revert InvalidVotingPeriod();
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 voterReputation = reputationScores[msg.sender];
        // Voting power could be based on reputation, staked tokens, or a combination.
        // For simplicity, 1 reputation = 1 vote.
        uint256 votingPower = voterReputation > 0 ? voterReputation : 1; // Minimum 1 vote for any participant

        if (_support) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }
        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a passed and not yet executed proposal.
    /// @dev Can be called by anyone, but requires the proposal to have passed the voting period,
    ///      met quorum, and have more yes votes than no votes.
    ///      Only Guardians can execute proposals with calldata.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(bytes32 _proposalId) public whenNotPaused onlyRole(GUARDIAN_ROLE) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status == ProposalStatus.Executed) revert ProposalAlreadyExecuted();
        if (block.number <= proposal.votingPeriodEndBlock) revert ProposalNotActive(); // Voting period not ended

        // Check if proposal succeeded
        if (proposal.yesVotes <= proposal.noVotes) {
            proposal.status = ProposalStatus.Failed;
            revert ProposalNotSucceeded();
        }
        if (proposal.yesVotes.add(proposal.noVotes) < proposal.quorumThreshold) {
            proposal.status = ProposalStatus.Failed;
            revert QuorumNotReached();
        }

        // Execute calldata if provided
        if (proposal.target != address(0) && proposal.callData.length > 0) {
            (bool success,) = proposal.target.call(proposal.callData);
            if (!success) revert WithdrawFailed(); // Using generic error for failed execution
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Allows the proposer or a guardian to cancel a proposal before voting ends.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(bytes32 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.status != ProposalStatus.Active) revert ProposalNotActive();
        if (block.number > proposal.votingPeriodEndBlock) revert InvalidVotingPeriod(); // Already ended

        if (msg.sender != proposal.proposer && !hasRole(GUARDIAN_ROLE, msg.sender)) {
            revert InsufficientPermissions();
        }

        proposal.status = ProposalStatus.Canceled;
        emit ProposalCanceled(_proposalId);
    }

    // --- V. Oracle & Arbitration System ---

    /// @notice Oracles submit specific external data points.
    /// @param _key A unique identifier for the data point (e.g., keccak256("ETH_PRICE")).
    /// @param _value The submitted data value.
    /// @param _timestamp The timestamp of the data point.
    function submitExternalData(bytes32 _key, uint256 _value, uint256 _timestamp) public onlyRole(ORACLE_ROLE) whenNotPaused {
        oracleDataSubmissions[_key].push(OracleDataPoint({
            value: _value,
            timestamp: _timestamp,
            submitter: msg.sender,
            isValidated: true // Assume valid until challenged
        }));
        emit ExternalDataSubmitted(_key, _value, _timestamp, msg.sender);
    }

    /// @notice Users can challenge a specific submission of oracle data.
    /// @param _dataKey The key of the data point.
    /// @param _submissionIndex The index of the specific submission in the `oracleDataSubmissions` array.
    /// @param _reason A string explaining the reason for the challenge.
    function challengeExternalData(bytes32 _dataKey, uint256 _submissionIndex, string memory _reason) public whenNotPaused {
        if (_submissionIndex >= oracleDataSubmissions[_dataKey].length) revert DataNotFound();
        OracleDataPoint storage dataPoint = oracleDataSubmissions[_dataKey][_submissionIndex];

        if (challengeIdsForData[_dataKey][_submissionIndex] != 0) revert DataAlreadyChallenged();

        bytes32 challengeId = keccak256(abi.encodePacked(nextChallengeId, msg.sender, _dataKey, _submissionIndex));
        challenges[challengeId] = Challenge({
            dataKey: _dataKey,
            submissionIndex: _submissionIndex,
            challenger: msg.sender,
            reason: _reason,
            status: ChallengeStatus.Pending
        });
        challengeIdsForData[_dataKey][_submissionIndex] = challengeId;
        dataPoint.isValidated = false; // Mark as invalid until arbitrated
        nextChallengeId++;
        emit ExternalDataChallenged(_dataKey, _submissionIndex, challengeId, msg.sender);
    }

    /// @notice Arbiters resolve a data challenge, validating or invalidating the data point.
    /// @param _challengeId The ID of the challenge to arbitrate.
    /// @param _isValid True if the data point is deemed valid, false otherwise.
    function arbitrateDataChallenge(bytes32 _challengeId, bool _isValid) public onlyRole(ARBITER_ROLE) whenNotPaused {
        Challenge storage challenge = challenges[_challengeId];
        if (challenge.dataKey == 0) revert ChallengeNotFound();
        if (challenge.status != ChallengeStatus.Pending) revert ChallengeNotPending();

        OracleDataPoint storage dataPoint = oracleDataSubmissions[challenge.dataKey][challenge.submissionIndex];
        dataPoint.isValidated = _isValid; // Update validation status

        challenge.status = _isValid ? ChallengeStatus.Validated : ChallengeStatus.Invalidated;
        emit DataChallengeArbitrated(_challengeId, _isValid);
    }

    /// @notice Retrieves the latest validated data point for a given key.
    /// @param _key The key of the data point.
    /// @return The value of the latest validated data, its timestamp, and the submitter.
    function getLatestOracleData(bytes32 _key) public view returns (uint256 value, uint256 timestamp, address submitter) {
        OracleDataPoint[] storage submissions = oracleDataSubmissions[_key];
        for (int i = int(submissions.length) - 1; i >= 0; i--) {
            if (submissions[uint256(i)].isValidated) {
                return (submissions[uint256(i)].value, submissions[uint256(i)].timestamp, submissions[uint256(i)].submitter);
            }
        }
        revert DataNotFound();
    }


    // --- VI. Staking & Incentives ---

    /// @notice Users stake AEGIS tokens to earn rewards and reputation.
    /// @param _amount The amount of AEGIS tokens to stake.
    function stakeTokens(uint256 _amount) public whenNotPaused nonReentrant {
        if (address(aegisToken) == address(0)) revert TokenNotSet();
        if (_amount == 0) revert StakingAmountInvalid();

        _updateStakingRewards(msg.sender); // Calculate and add pending rewards
        aegisToken.safeTransferFrom(msg.sender, address(this), _amount);

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.add(_amount);
        totalStakedAmount = totalStakedAmount.add(_amount);
        stakers[msg.sender].lastStakeBlock = block.number;

        // Optionally, increase reputation for staking
        reputationScores[msg.sender] = reputationScores[msg.sender].add(_amount.div(1e18).div(10)); // Example: 1 reputation for every 10 AEGIS staked

        emit TokensStaked(msg.sender, _amount);
        emit ReputationUpdated(msg.sender, reputationScores[msg.sender]);
    }

    /// @notice Users unstake AEGIS tokens.
    /// @param _amount The amount of AEGIS tokens to unstake.
    function unstakeTokens(uint256 _amount) public whenNotPaused nonReentrant {
        if (address(aegisToken) == address(0)) revert TokenNotSet();
        if (_amount == 0) revert StakingAmountInvalid();
        if (stakers[msg.sender].stakedAmount < _amount) revert NotStaked();

        _updateStakingRewards(msg.sender); // Calculate and add pending rewards before unstake

        stakers[msg.sender].stakedAmount = stakers[msg.sender].stakedAmount.sub(_amount);
        totalStakedAmount = totalStakedAmount.sub(_amount);
        stakers[msg.sender].lastStakeBlock = block.number;

        aegisToken.safeTransfer(msg.sender, _amount);

        // Optionally, decrease reputation for unstaking, or if staking amount drops
        reputationScores[msg.sender] = reputationScores[msg.sender].sub(_amount.div(1e18).div(20)); // Example: half the rate of gaining

        emit TokensUnstaked(msg.sender, _amount);
        emit ReputationUpdated(msg.sender, reputationScores[msg.sender]);
    }

    /// @notice Allows stakers to claim their dynamically calculated rewards.
    function claimStakingRewards() public whenNotPaused nonReentrant {
        if (address(aegisToken) == address(0)) revert TokenNotSet();
        if (stakers[msg.sender].stakedAmount == 0 && stakers[msg.sender].rewardDebt == 0) revert NotStaked();

        _updateStakingRewards(msg.sender); // Final update for rewards

        uint256 rewards = stakers[msg.sender].rewardDebt;
        if (rewards == 0) revert RewardsNotAvailable();

        stakers[msg.sender].rewardDebt = 0; // Reset debt after claiming

        // Ensure contract has enough balance to pay rewards
        if (aegisToken.balanceOf(address(this)) < rewards) {
            // In a real system, this might trigger a governance proposal for treasury top-up
            // Or use a reward pool. For this example, we'll revert if insufficient.
            revert NotEnoughBalance();
        }

        aegisToken.safeTransfer(msg.sender, rewards);
        emit StakingRewardsClaimed(msg.sender, rewards);
    }

    /// @notice Returns the amount of pending staking rewards for a given staker.
    /// @param _staker The address of the staker.
    /// @return The amount of pending rewards.
    function getPendingStakingRewards(address _staker) public view returns (uint256) {
        if (address(aegisToken) == address(0)) return 0; // or revert TokenNotSet()
        StakerInfo storage staker = stakers[_staker];
        if (staker.stakedAmount == 0) return 0;

        uint256 currentAPR = getAdaptiveParameterValue(PARAM_STAKING_APR); // In basis points (e.g., 100 = 1%)
        uint256 blocksSinceLastUpdate = block.number.sub(staker.lastStakeBlock);

        // Calculate rewards for blocks passed
        // APR is per year. Need to convert to per block.
        // Assuming ~2.5M blocks per year (Ethereum ~13s block time)
        uint256 blocksPerYear = 2500000;
        uint256 rewardsPerBlock = staker.stakedAmount.mul(currentAPR).div(10000).div(blocksPerYear); // currentAPR is in BP, so /10000 for percentage
        uint256 accumulatedRewards = rewardsPerBlock.mul(blocksSinceLastUpdate);

        return staker.rewardDebt.add(accumulatedRewards);
    }

    /// @dev Internal helper function to update a staker's rewards.
    function _updateStakingRewards(address _staker) private {
        StakerInfo storage staker = stakers[_staker];
        if (staker.stakedAmount == 0) return;

        uint256 pendingRewards = getPendingStakingRewards(_staker);
        staker.rewardDebt = pendingRewards;
        staker.lastStakeBlock = block.number; // Update last updated block to current
    }


    // --- VII. Role Management & Reputation ---

    /// @notice Owner/Admin grants specific roles (Guardian, Oracle, Arbiter) to an address.
    /// @param _role The role to grant (e.g., GUARDIAN_ROLE).
    /// @param _account The address to grant the role to.
    function grantRole(bytes32 _role, address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(_role, _account);
        emit RoleGranted(_role, _account, msg.sender);
    }

    /// @notice Owner/Admin revokes specific roles from an address.
    /// @param _role The role to revoke.
    /// @param _account The address to revoke the role from.
    function revokeRole(bytes32 _role, address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(_role, _account);
        emit RoleRevoked(_role, _account, msg.sender);
    }

    /// @notice Returns the reputation score of a given address.
    /// @param _account The address to query.
    /// @return The reputation score.
    function getReputationScore(address _account) public view returns (uint256) {
        return reputationScores[_account];
    }

    /// @notice Allows a guardian to manually adjust reputation scores (e.g., for positive/negative actions identified by governance).
    /// @param _account The address whose reputation to adjust.
    /// @param _newScore The new reputation score.
    function updateReputationScore(address _account, uint256 _newScore) public onlyRole(GUARDIAN_ROLE) {
        reputationScores[_account] = _newScore;
        emit ReputationUpdated(_account, _newScore);
    }

    // Fallback function to receive Ether for deposits
    receive() external payable {
        if (msg.value > 0) {
            depositEther();
        }
    }
}
```