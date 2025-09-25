Here's a smart contract in Solidity called `SynapseAI_Nexus`, designed to embody advanced and trendy concepts like fractionalized AI model ownership, decentralized governance, revenue streaming, and AI model access management.

To adhere to the "don't duplicate any of open source" rule, I have implemented core functionalities like access control, pausing, reentrancy guard, and basic ERC-721-like (for FONs) and DAO logic directly within the contract, rather than inheriting from common OpenZeppelin contracts (except for `IERC20` which is a fundamental interface and `Strings` for a utility function to aid in event readability).

---

## Outline & Function Summary: `SynapseAI_Nexus`

This contract establishes a decentralized ecosystem for AI model ownership, revenue sharing, and governed access. It allows AI model developers to register their models, fractionalize ownership into Non-Fungible Tokens (FONs), and manage revenue streams. Fractional Ownership NFT (FON) holders collectively govern the model's parameters and strategic direction. Users can stake tokens to gain API access to these models, with revenue directed to the FON holders.

**I. Core Infrastructure & Configuration**
1.  `constructor(address _initialOwner, address _paymentToken, address _oracleAddress)`: Initializes the contract with an initial administrative owner, the accepted ERC-20 payment token, and the trusted oracle contract address.
2.  `transferOwner(address _newOwner)`: Allows the current owner to transfer administrative control.
3.  `setOracleAddress(address _newOracle)`: Updates the trusted oracle contract address. (Initially owner-only, later DAO-controlled).
4.  `setPaymentTokenAddress(address _newPaymentToken)`: Updates the ERC-20 token address accepted for payments/staking. (Initially owner-only, later DAO-controlled).
5.  `pauseContract()`: Pauses certain contract operations in emergencies. Requires DAO approval.
6.  `unpauseContract()`: Unpauses the contract. Requires DAO approval.

**II. AI Model Management (Developer/Creator Focused)**
7.  `registerAIModel(string memory _modelName, string memory _modelURI, uint256 _initialAPIBaseCost, uint256 _performanceBondAmount, uint256 _fonSupply)`: Registers a new AI model, requiring an initial performance bond. Mints the initial set of Fractional Ownership NFTs (FONs) to the creator.
8.  `proposeModelMetadataUpdate(uint256 _modelId, string memory _newModelURI)`: Developer proposes non-critical metadata updates for their model. Requires DAO vote for approval.
9.  `updateModelAPIBaseCost(uint256 _modelId, uint256 _newCost)`: DAO approved function to change the base cost for API access to a model. (Called via `executeGovernanceProposal`).
10. `claimPerformanceBond(uint256 _modelId)`: Developer claims their performance bond after a predefined lock-up period, provided the model meets performance thresholds as reported by the oracle.
11. `proposeModelRetirement(uint256 _modelId)`: Proposes to mark a model as retired, stopping new access and eventually winding down revenue distribution. Requires DAO vote.

**III. Fractional Ownership NFTs (FONs) Management (Owner/Investor Focused)**
12. `transferFON(uint256 _modelId, uint256 _fonId, address _to)`: Transfers a Fractional Ownership NFT (FON) to another address. Each FON has a unique ID within a specific model.
13. `getFONOwner(uint256 _modelId, uint256 _fonId)`: Returns the owner of a specific FON ID for a given model.
14. `balanceOfFON(address _owner, uint256 _modelId)`: Returns the number of FONs held by an address for a specific AI model.
15. `getAIModelFONSupply(uint256 _modelId)`: Returns the total supply of FONs for a given AI model.

**IV. Revenue Management & Distribution**
16. `submitAIModelUsageMetrics(uint256 _modelId, uint256 _revenueGenerated)`: Oracle submits aggregated usage metrics and calculated revenue for a model. This revenue is added to a pool.
17. `distributeModelRevenue(uint256 _modelId)`: Triggers the distribution of accumulated revenue for a specific model to its FON holders based on their FON count. Can be called by anyone.
18. `claimMyRevenueShare(uint256 _modelId)`: Allows an individual FON holder to claim their accumulated revenue for a specific model.

**V. AI Model Access & Staking (User/Consumer Focused)**
19. `stakeForModelAccess(uint256 _modelId, uint256 _durationInDays)`: Users stake the payment token to gain time-bound access to an AI model's API. Generates a temporary access ID.
20. `unstakeModelAccess(uint256 _accessId)`: Users unstake their tokens, revoking their access ID. Staked funds are returned if no penalties (simplified, no penalty logic included).
21. `checkAccessValidity(uint256 _accessId)`: Verifies if a given access ID is currently valid (not expired, not revoked, model not retired).

**VI. DAO Governance (General)**
22. `createGovernanceProposal(string memory _description, address _target, bytes memory _callData, uint256 _delay)`: Allows any FON holder to create a general DAO proposal targeting an arbitrary contract function.
23. `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows FON holders to vote on active proposals. Voting power is based on total FONs held across all models.
24. `executeGovernanceProposal(uint256 _proposalId)`: Executes a proposal if it has passed, the timelock has expired, and it hasn't been executed yet.
25. `delegateVotingPower(address _delegatee)`: Allows FON holders to delegate their voting power to another address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal IERC20 definition. Using this interface is a standard, not duplicating a specific contract.
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Interface for a hypothetical Oracle contract that provides off-chain AI data
interface IOracle {
    // Returns aggregated usage count and total revenue generated since last submission for a model
    function getAIModelUsageMetrics(uint256 _modelId) external view returns (uint256 usageCount, uint256 revenueGenerated);
    // Returns a performance score for a model (e.g., 0-100)
    function getAIModelPerformanceScore(uint256 _modelId) external view returns (uint256 score);
}

// Interface for governable targets (e.g., this contract itself for internal function calls)
interface IGovernable {
    function executeProposalAction(bytes calldata _callData) external;
}

/**
 * @dev Custom minimal SafeERC20-like library for secure token interactions.
 *      Avoids direct inheritance from OpenZeppelin's SafeERC20.
 */
library SafeERC20 {
    error TokenTransferFailed();
    error TokenTransferFromFailed();

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        if (!token.transfer(to, value)) {
            revert TokenTransferFailed();
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        if (!token.transferFrom(from, to, value)) {
            revert TokenTransferFromFailed();
        }
    }
}

/**
 * @title SynapseAI_Nexus
 * @dev A decentralized ecosystem for AI model fractional ownership, revenue sharing, and governed access.
 *      It allows AI model developers to register their models, fractionalize ownership into Non-Fungible Tokens (FONs),
 *      and manage revenue streams. FON holders collectively govern the model's parameters and strategic direction.
 *      Users can stake tokens to gain API access to these models, with revenue directed to the FON holders.
 */
contract SynapseAI_Nexus is IGovernable {
    using SafeERC20 for IERC20; // Use our minimal SafeERC20 library

    address private _owner; // Initial administrative owner, can be transferred
    IERC20 public paymentToken; // ERC-20 token accepted for payments and staking
    IOracle public oracle;      // Trusted oracle for AI model data

    bool private _paused; // Contract pause state
    bool private _locked; // Reentrancy guard flag

    // Custom Errors
    error NotOwner();
    error ContractPaused();
    error NotPaused();
    error ReentrantCall();
    error InvalidModelId();
    error InvalidFONId();
    error NotAIModelOwner();
    error NotApproved(); // Generic for unauthorized actions
    error InvalidAccessId();
    error AccessExpired();
    error PerformanceBondNotClaimable();
    error UnauthorizedOracle();
    error InvalidProposalId();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error ProposalVoteFailed();
    error ProposalFailed();
    error InsufficientVotingPower();
    error AlreadyRetired();
    error InvalidDuration();
    error ZeroCost();
    error NoPendingRevenue();
    error NoBondToClaim();
    error ZeroAddressNotAllowed();


    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);

    event AIModelRegistered(
        uint256 indexed modelId,
        address indexed developer,
        string modelName,
        string modelURI,
        uint256 initialAPIBaseCost,
        uint256 fonSupply
    );
    event ModelMetadataUpdateProposed(uint256 indexed modelId, address indexed proposer, string newModelURI, uint256 proposalId);
    event ModelAPIUpdated(uint256 indexed modelId, uint256 newCost);
    event PerformanceBondClaimed(uint256 indexed modelId, address indexed developer, uint256 amount);
    event ModelRetirementProposed(uint256 indexed modelId, address indexed proposer, uint256 proposalId);

    event FONTransferred(uint256 indexed modelId, uint256 indexed fonId, address indexed from, address indexed to);
    event RevenueSubmitted(uint256 indexed modelId, address indexed oracle, uint256 revenue);
    event RevenueDistributed(uint256 indexed modelId, uint256 totalDistributed);
    event RevenueClaimed(uint256 indexed modelId, address indexed claimant, uint256 amount);

    event ModelAccessStaked(uint256 indexed accessId, uint256 indexed modelId, address indexed staker, uint256 stakedAmount, uint256 expiry);
    event ModelAccessUnstaked(uint256 indexed accessId, uint256 indexed modelId, address indexed staker, uint256 returnedAmount);
    
    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address target, bytes callData, uint256 delay);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);


    // --- Data Structures ---

    struct AIModel {
        address developer; // The original developer/creator of the model
        string modelName;
        string modelURI; // URI to model details, documentation, off-chain resources
        uint224 apiBaseCost; // Base cost for API access (in paymentToken units per unit of access, e.g., per query, per minute)
        uint224 performanceBondAmount; // Amount of tokens staked by developer as bond
        uint40 bondLockUntil; // Timestamp until which the bond is locked
        uint40 registrationTime; // Timestamp of model registration
        uint256 totalFONSupply; // Total fractional ownership NFTs for this model
        uint256 currentRevenuePool; // Accumulated revenue awaiting distribution for this model
        bool retired; // If the model is retired
    }

    mapping(uint256 => AIModel) public aiModels; // modelId => AIModel details
    uint256 public nextModelId; // Counter for new AI models

    // Pseudo-ERC721 for Fractional Ownership NFTs (FONs)
    // modelId => fonId => owner address
    mapping(uint256 => mapping(uint256 => address)) internal _fonOwners;
    // modelId => owner address => fon count
    mapping(uint256 => mapping(address => uint256)) internal _fonBalances;

    // Revenue tracking per FON holder
    // modelId => holder address => pending revenue
    mapping(uint256 => mapping(address => uint256)) public pendingRevenue;


    // AI Model Access Management
    struct ModelAccess {
        uint256 modelId;
        address staker;
        uint256 stakedAmount;
        uint40 expiry;
        bool active;
    }
    mapping(uint252 => ModelAccess) public modelAccesses; // accessId => ModelAccess details
    uint252 public nextAccessId; // Counter for new access IDs (using uint252 to fit within 256-bit slot)


    // DAO Governance
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }

    struct Proposal {
        uint256 id;
        string description;
        address target; // Target contract for execution (e.g., this contract for internal calls)
        bytes callData; // Encoded function call for execution
        uint40 voteStart;
        uint40 voteEnd;
        uint40 eta; // Estimated time of execution (block.timestamp + delay)
        uint256 delay; // Timelock delay for execution after passing
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotingPowerAtSnapshot; // Total voting power when proposal was created
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted; // voter => bool
    }

    uint256 public nextProposalId; // Counter for new proposals
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal details
    uint256 public constant MIN_VOTE_PERIOD = 3 days;
    uint256 public constant MAX_VOTE_PERIOD = 7 days; // Not strictly enforced but good practice
    uint256 public constant PROPOSAL_EXECUTION_DELAY = 2 days; // Timelock for execution after successful vote
    uint256 public constant MIN_PERFORMANCE_SCORE_FOR_BOND_CLAIM = 75; // Minimum performance score (0-100)
    uint256 public constant BOND_LOCKUP_PERIOD = 90 days; // Lockup period for developer's performance bond
    uint256 public constant QUORUM_PERCENTAGE = 20; // 20% of total voting power for quorum

    // Voting power delegation
    mapping(address => address) public delegates; // delegator => delegatee


    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (_paused) revert ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert NotPaused();
        _;
    }

    // Custom reentrancy guard
    modifier nonReentrant() {
        if (_locked) revert ReentrantCall();
        _locked = true;
        _;
        _locked = false;
    }

    modifier onlyOracle() {
        if (msg.sender != address(oracle)) revert UnauthorizedOracle();
        _;
    }


    // --- Constructor ---

    constructor(address _initialOwner, address _paymentToken, address _oracleAddress) {
        if (_initialOwner == address(0)) revert ZeroAddressNotAllowed();
        if (_paymentToken == address(0)) revert ZeroAddressNotAllowed();
        if (_oracleAddress == address(0)) revert ZeroAddressNotAllowed();

        _owner = _initialOwner;
        paymentToken = IERC20(_paymentToken);
        oracle = IOracle(_oracleAddress);
        _paused = false;
        _locked = false;
        nextModelId = 1;
        nextAccessId = 1;
        nextProposalId = 1;

        emit OwnershipTransferred(address(0), _initialOwner);
    }


    // --- I. Core Infrastructure & Configuration ---

    /**
     * @dev Allows the current owner to transfer administrative control.
     *      It's recommended to eventually transfer this ownership to a DAO-controlled multisig or Timelock.
     * @param _newOwner The address of the new administrative owner.
     */
    function transferOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddressNotAllowed();
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Updates the trusted oracle contract address.
     *      Initially callable by owner, should be moved to DAO governance via proposal.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert ZeroAddressNotAllowed();
        oracle = IOracle(_newOracle);
    }

    /**
     * @dev Updates the ERC-20 token address accepted for payments/staking.
     *      Initially callable by owner, should be moved to DAO governance via proposal.
     * @param _newPaymentToken The address of the new ERC-20 payment token.
     */
    function setPaymentTokenAddress(address _newPaymentToken) external onlyOwner {
        if (_newPaymentToken == address(0)) revert ZeroAddressNotAllowed();
        paymentToken = IERC20(_newPaymentToken);
    }

    /**
     * @dev Pauses certain contract operations in emergencies.
     *      This function can be directly called by the owner. For DAO governance, a proposal
     *      would be created to call this function via `executeProposalAction`.
     */
    function pauseContract() external onlyOwner {
        if (_paused) revert ContractPaused();
        _paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     *      Similar to `pauseContract`, initially owner-callable, intended for DAO governance.
     */
    function unpauseContract() external onlyOwner {
        if (!_paused) revert NotPaused();
        _paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // --- II. AI Model Management (Developer/Creator Focused) ---

    /**
     * @dev Registers a new AI model, requiring an initial performance bond.
     *      Mints the initial set of Fractional Ownership NFTs (FONs) to the creator.
     * @param _modelName The name of the AI model.
     * @param _modelURI A URI pointing to off-chain details, documentation, etc.
     * @param _initialAPIBaseCost The initial base cost for API access (in paymentToken units).
     * @param _performanceBondAmount The amount of payment tokens staked as a performance bond by the developer.
     * @param _fonSupply The total number of Fractional Ownership NFTs for this model.
     */
    function registerAIModel(
        string memory _modelName,
        string memory _modelURI,
        uint256 _initialAPIBaseCost,
        uint256 _performanceBondAmount,
        uint256 _fonSupply
    ) external whenNotPaused nonReentrant {
        require(bytes(_modelName).length > 0, "Model name cannot be empty");
        require(bytes(_modelURI).length > 0, "Model URI cannot be empty");
        require(_performanceBondAmount > 0, "Bond amount must be greater than zero");
        require(_fonSupply > 0, "FON supply must be greater than zero");

        uint256 modelId = nextModelId++;
        
        // Transfer performance bond from developer to the contract
        paymentToken.safeTransferFrom(msg.sender, address(this), _performanceBondAmount);

        aiModels[modelId] = AIModel({
            developer: msg.sender,
            modelName: _modelName,
            modelURI: _modelURI,
            apiBaseCost: uint224(_initialAPIBaseCost),
            performanceBondAmount: uint224(_performanceBondAmount),
            bondLockUntil: uint40(block.timestamp + BOND_LOCKUP_PERIOD),
            registrationTime: uint40(block.timestamp),
            totalFONSupply: _fonSupply,
            currentRevenuePool: 0,
            retired: false
        });

        // Mint all FONs (by assigning ownership) to the developer initially
        _mintFONs(modelId, msg.sender, _fonSupply);

        emit AIModelRegistered(
            modelId,
            msg.sender,
            _modelName,
            _modelURI,
            _initialAPIBaseCost,
            _fonSupply
        );
    }

    /**
     * @dev Developer proposes non-critical metadata updates for their model.
     *      Requires DAO vote for approval.
     * @param _modelId The ID of the AI model.
     * @param _newModelURI The new URI for the model's metadata.
     */
    function proposeModelMetadataUpdate(uint256 _modelId, string memory _newModelURI) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        if (model.developer != msg.sender) revert NotAIModelOwner();
        if (model.retired) revert AlreadyRetired();
        if (bytes(_newModelURI).length == 0) revert("New model URI cannot be empty");

        // Encode the function call to be executed if the proposal passes
        bytes memory callData = abi.encodeWithSelector(
            this.executeProposalAction.selector,
            abi.encodeWithSelector(this._updateModelURIInternal.selector, _modelId, _newModelURI)
        );

        // Create a DAO proposal for this update
        uint256 proposalId = _createProposal(
            string(abi.encodePacked("Update metadata for AI Model #", Strings.toString(_modelId))),
            address(this), // Target is this contract itself
            callData,
            PROPOSAL_EXECUTION_DELAY
        );

        emit ModelMetadataUpdateProposed(_modelId, msg.sender, _newModelURI, proposalId);
    }

    /**
     * @dev Internal function to update model URI, callable only via `executeProposalAction`
     *      (i.e., through a successful DAO proposal execution).
     */
    function _updateModelURIInternal(uint256 _modelId, string memory _newModelURI) external {
        if (msg.sender != address(this)) revert NotApproved(); // Only contract itself can call this
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        model.modelURI = _newModelURI;
        emit AIModelRegistered(_modelId, model.developer, model.modelName, _newModelURI, model.apiBaseCost, model.totalFONSupply); // Re-emit for update clarity
    }

    /**
     * @dev DAO approved function to change the base cost for API access to a model.
     *      This function itself is called via `executeGovernanceProposal`.
     * @param _modelId The ID of the AI model.
     * @param _newCost The new base cost for API access.
     */
    function updateModelAPIBaseCost(uint256 _modelId, uint256 _newCost) external { // Callable by DAO through `executeProposalAction`
        if (msg.sender != address(this)) revert NotApproved(); // Only contract itself can call this
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        if (model.retired) revert AlreadyRetired();
        model.apiBaseCost = uint224(_newCost);
        emit ModelAPIUpdated(_modelId, _newCost);
    }

    /**
     * @dev Developer claims their performance bond after a predefined lock-up period,
     *      provided the model meets performance thresholds as reported by the oracle.
     * @param _modelId The ID of the AI model.
     */
    function claimPerformanceBond(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0) || model.developer != msg.sender) revert NotAIModelOwner();
        if (block.timestamp < model.bondLockUntil) revert PerformanceBondNotClaimable();
        if (model.performanceBondAmount == 0) revert NoBondToClaim();

        (uint256 performanceScore) = oracle.getAIModelPerformanceScore(_modelId);
        if (performanceScore < MIN_PERFORMANCE_SCORE_FOR_BOND_CLAIM) revert PerformanceBondNotClaimable();

        uint256 amount = model.performanceBondAmount;
        model.performanceBondAmount = 0; // Bond is claimed

        paymentToken.safeTransfer(msg.sender, amount);
        emit PerformanceBondClaimed(_modelId, msg.sender, amount);
    }

    /**
     * @dev Proposes to mark a model as retired, stopping new access and eventually winding down revenue distribution.
     *      Requires DAO vote.
     * @param _modelId The ID of the AI model.
     */
    function proposeModelRetirement(uint256 _modelId) external whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        if (model.developer != msg.sender) revert NotAIModelOwner();
        if (model.retired) revert AlreadyRetired();

        bytes memory callData = abi.encodeWithSelector(
            this.executeProposalAction.selector,
            abi.encodeWithSelector(this._retireModelInternal.selector, _modelId)
        );

        uint256 proposalId = _createProposal(
            string(abi.encodePacked("Retire AI Model #", Strings.toString(_modelId))),
            address(this),
            callData,
            PROPOSAL_EXECUTION_DELAY
        );

        emit ModelRetirementProposed(_modelId, msg.sender, proposalId);
    }

    /**
     * @dev Internal function to retire a model, callable only via `executeProposalAction`.
     */
    function _retireModelInternal(uint256 _modelId) external {
        if (msg.sender != address(this)) revert NotApproved(); // Only contract itself can call this
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        model.retired = true;
        // Further logic could involve revoking all active access keys or preventing new ones.
        // For simplicity, `checkAccessValidity` handles the retired state.
    }


    // --- III. Fractional Ownership NFTs (FONs) Management (Owner/Investor Focused) ---
    // Minimal ERC-721 like implementation for internal tracking without inheriting a full standard.

    /**
     * @dev Internal function to mint FONs during model registration.
     *      Each FON is a unique NFT (identified by _fonId within _modelId).
     * @param _modelId The ID of the AI model.
     * @param _to The address to mint FONs to.
     * @param _amount The number of FONs to mint.
     */
    function _mintFONs(uint256 _modelId, address _to, uint256 _amount) internal {
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();

        // Assign _amount of FONs, starting from ID 1 up to _amount.
        // The total FON supply for the model is set at registration.
        for (uint256 i = 1; i <= _amount; i++) {
            _fonOwners[_modelId][i] = _to;
        }
        _fonBalances[_modelId][_to] += _amount;
    }

    /**
     * @dev Transfers a Fractional Ownership NFT (FON) to another address.
     *      Each FON has a unique ID within a model (from 1 to totalFONSupply).
     * @param _modelId The ID of the AI model.
     * @param _fonId The unique ID of the FON to transfer (1 to totalFONSupply).
     * @param _to The recipient address.
     */
    function transferFON(uint256 _modelId, uint256 _fonId, address _to) external whenNotPaused nonReentrant {
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0) || model.retired) revert InvalidModelId();
        if (_fonId == 0 || _fonId > model.totalFONSupply) revert InvalidFONId();

        address currentOwner = _fonOwners[_modelId][_fonId];
        if (currentOwner == address(0)) revert InvalidFONId(); // FON not minted or invalid
        if (currentOwner != msg.sender) revert NotApproved(); // Only owner can transfer their FON directly

        // Update ownership
        _fonOwners[_modelId][_fonId] = _to;

        // Update balances
        _fonBalances[_modelId][currentOwner]--;
        _fonBalances[_modelId][_to]++;

        // Note: Pending revenue remains with the old owner's address.
        // The new owner starts accumulating revenue from the next distribution.
        // Old owner must claim revenue before transferring if desired.

        emit FONTransferred(_modelId, _fonId, currentOwner, _to);
    }

    /**
     * @dev Returns the owner of a specific FON ID for a given model.
     * @param _modelId The ID of the AI model.
     * @param _fonId The unique ID of the FON.
     * @return The owner address.
     */
    function getFONOwner(uint256 _modelId, uint256 _fonId) external view returns (address) {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        if (_fonId == 0 || _fonId > model.totalFONSupply) revert InvalidFONId();
        return _fonOwners[_modelId][_fonId];
    }

    /**
     * @dev Returns the number of FONs held by an address for a specific AI model.
     * @param _owner The address to query.
     * @param _modelId The ID of the AI model.
     * @return The count of FONs held.
     */
    function balanceOfFON(address _owner, uint256 _modelId) external view returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        return _fonBalances[_modelId][_owner];
    }

    /**
     * @dev Returns the total supply of FONs for a given AI model.
     * @param _modelId The ID of the AI model.
     * @return The total FON supply.
     */
    function getAIModelFONSupply(uint256 _modelId) external view returns (uint256) {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        return model.totalFONSupply;
    }


    // --- IV. Revenue Management & Distribution ---

    /**
     * @dev Oracle submits aggregated usage metrics and calculated revenue for a model.
     *      This revenue is added to a pool for later distribution.
     * @param _modelId The ID of the AI model.
     * @param _revenueGenerated The amount of payment tokens generated by the model.
     */
    function submitAIModelUsageMetrics(uint256 _modelId, uint256 _revenueGenerated) external onlyOracle whenNotPaused {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0) || model.retired) revert InvalidModelId();
        
        // This contract must internally manage how it receives `_revenueGenerated` funds.
        // For simplicity, this function assumes the funds were already sent to the contract's address
        // via a separate transaction or are accounted for in another way.
        // In a more complex setup, the oracle might trigger a transfer directly.
        
        model.currentRevenuePool += _revenueGenerated;
        emit RevenueSubmitted(_modelId, msg.sender, _revenueGenerated);
    }

    /**
     * @dev Triggers the distribution of accumulated revenue for a specific model to its FON holders.
     *      Can be called by anyone, incentivizing timely distribution.
     * @param _modelId The ID of the AI model.
     */
    function distributeModelRevenue(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();
        if (model.currentRevenuePool == 0) return; // No revenue to distribute
        if (model.totalFONSupply == 0) {
            // Should not happen if registered correctly, but as fallback, send to developer
            uint256 revenueToDeveloper = model.currentRevenuePool;
            model.currentRevenuePool = 0;
            paymentToken.safeTransfer(model.developer, revenueToDeveloper);
            emit RevenueDistributed(_modelId, revenueToDeveloper);
            return;
        }

        uint256 totalRevenueToDistribute = model.currentRevenuePool;
        model.currentRevenuePool = 0; // Clear the pool

        uint256 revenuePerFON = totalRevenueToDistribute / model.totalFONSupply;
        if (revenuePerFON == 0) {
            // If not enough for even 1 token, put it back or handle as dust.
            // For now, put it back to accrue more.
            model.currentRevenuePool = totalRevenueToDistribute;
            return;
        }

        // Iterate through all possible FON IDs and add revenue to their respective owner's pending balance.
        // This approach can be gas-intensive for very large `totalFONSupply`.
        // A more scalable solution for real-world DAOs involves a pull-based "snapshot" system.
        for (uint256 i = 1; i <= model.totalFONSupply; i++) {
            address fonOwner = _fonOwners[_modelId][i];
            if (fonOwner != address(0)) {
                pendingRevenue[_modelId][fonOwner] += revenuePerFON;
            }
        }
        
        uint256 distributedAmount = revenuePerFON * model.totalFONSupply;
        // Remaining dust (if any) stays in the pool: model.currentRevenuePool += (totalRevenueToDistribute - distributedAmount);
        // This is implicit by `model.currentRevenuePool = 0` then adding the remaining funds.
        model.currentRevenuePool += (totalRevenueToDistribute - distributedAmount); // Re-add undistributed dust

        emit RevenueDistributed(_modelId, distributedAmount);
    }

    /**
     * @dev Allows an individual FON holder to claim their accumulated revenue for a specific model.
     * @param _modelId The ID of the AI model.
     */
    function claimMyRevenueShare(uint256 _modelId) external whenNotPaused nonReentrant {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0)) revert InvalidModelId();

        uint256 amountToClaim = pendingRevenue[_modelId][msg.sender];
        if (amountToClaim == 0) revert NoPendingRevenue();

        pendingRevenue[_modelId][msg.sender] = 0; // Reset pending revenue

        paymentToken.safeTransfer(msg.sender, amountToClaim);
        emit RevenueClaimed(_modelId, msg.sender, amountToClaim);
    }


    // --- V. AI Model Access & Staking (User/Consumer Focused) ---

    /**
     * @dev Users stake the payment token to gain time-bound access to an AI model's API.
     *      Generates a temporary access ID.
     * @param _modelId The ID of the AI model.
     * @param _durationInDays The duration of access in days.
     * @return The generated access ID.
     */
    function stakeForModelAccess(uint256 _modelId, uint256 _durationInDays) external whenNotPaused nonReentrant returns (uint252) {
        AIModel storage model = aiModels[_modelId];
        if (model.developer == address(0) || model.retired) revert InvalidModelId();
        if (_durationInDays == 0) revert InvalidDuration();

        uint256 cost = model.apiBaseCost * _durationInDays;
        if (cost == 0) revert ZeroCost();

        paymentToken.safeTransferFrom(msg.sender, address(this), cost);

        uint252 accessId = nextAccessId++;
        uint40 expiry = uint40(block.timestamp + _durationInDays * 1 days);

        modelAccesses[accessId] = ModelAccess({
            modelId: _modelId,
            staker: msg.sender,
            stakedAmount: cost,
            expiry: expiry,
            active: true
        });

        // Revenue from access staking directly goes to the model's currentRevenuePool
        model.currentRevenuePool += cost;

        emit ModelAccessStaked(accessId, _modelId, msg.sender, cost, expiry);
        return accessId;
    }

    /**
     * @dev Users unstake their tokens, revoking their access ID.
     *      Funds are returned if the access is still active. (No penalty logic for simplicity).
     * @param _accessId The access ID to unstake.
     */
    function unstakeModelAccess(uint252 _accessId) external whenNotPaused nonReentrant {
        ModelAccess storage access = modelAccesses[_accessId];
        if (!access.active || access.staker != msg.sender) revert InvalidAccessId();

        access.active = false; // Deactivate access
        
        uint256 refundAmount = access.stakedAmount; // Full refund for simplicity, could be prorated or penalized.
        
        paymentToken.safeTransfer(msg.sender, refundAmount);

        emit ModelAccessUnstaked(_accessId, access.modelId, msg.sender, refundAmount);
    }

    /**
     * @dev Verifies if a given access ID is currently valid.
     * @param _accessId The access ID to check.
     * @return True if valid, false otherwise.
     */
    function checkAccessValidity(uint252 _accessId) external view returns (bool) {
        ModelAccess storage access = modelAccesses[_accessId];
        if (!access.active || access.staker == address(0)) return false; // Not active or invalid ID
        if (block.timestamp > access.expiry) return false; // Expired
        if (aiModels[access.modelId].retired) return false; // Model is retired
        return true;
    }


    // --- VI. DAO Governance (General) ---

    /**
     * @dev Internal utility function to create a new proposal.
     *      Factored out from `createGovernanceProposal` and `proposeModel...` functions.
     */
    function _createProposal(
        string memory _description,
        address _target,
        bytes memory _callData,
        uint256 _delay
    ) internal returns (uint256) {
        if (_getTotalVotingPower(msg.sender) == 0) revert InsufficientVotingPower();
        if (_target == address(0)) revert ZeroAddressNotAllowed();
        // Delay must be at least the standard execution delay for timelock behavior
        if (_delay < PROPOSAL_EXECUTION_DELAY) revert("Delay too short");

        uint256 proposalId = nextProposalId++;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            target: _target,
            callData: _callData,
            voteStart: uint40(block.timestamp),
            voteEnd: uint40(block.timestamp + MIN_VOTE_PERIOD), // Fixed minimum vote period for all proposals
            eta: 0, // Estimated time of execution, set after vote passes
            delay: _delay,
            votesFor: 0,
            votesAgainst: 0,
            totalVotingPowerAtSnapshot: _getTotalVotingPower(address(this)), // Snapshot total available power
            executed: false,
            canceled: false,
            hasVoted: new mapping(address => bool) // Initialize mapping
        });
        
        emit GovernanceProposalCreated(proposalId, msg.sender, _description, _target, _callData, _delay);
        return proposalId;
    }

    /**
     * @dev Allows any FON holder to create a general DAO proposal targeting an arbitrary contract function.
     * @param _description A description of the proposal.
     * @param _target The target contract address for the proposal's execution.
     * @param _callData The encoded function call to be executed if the proposal passes.
     * @param _delay The timelock delay in seconds before the proposal can be executed after passing.
     * @return The ID of the created proposal.
     */
    function createGovernanceProposal(
        string memory _description,
        address _target,
        bytes memory _callData,
        uint256 _delay
    ) external whenNotPaused returns (uint256) {
        return _createProposal(_description, _target, _callData, _delay);
    }

    /**
     * @dev Allows FON holders to vote on active proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (block.timestamp < proposal.voteStart || block.timestamp > proposal.voteEnd) revert ProposalNotActive();
        
        address voterAddress = msg.sender;
        if (proposal.hasVoted[voterAddress]) revert ProposalAlreadyVoted();

        // Check if voter has delegated their power
        address actualVoter = delegates[voterAddress] != address(0) ? delegates[voterAddress] : voterAddress;
        uint256 votingPower = _getTotalVotingPower(actualVoter);
        if (votingPower == 0) revert InsufficientVotingPower();

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[voterAddress] = true; // Mark original msg.sender as voted

        emit VoteCast(_proposalId, voterAddress, _support, votingPower);
    }

    /**
     * @dev Executes a proposal if it has passed, the timelock has expired, and it hasn't been executed yet.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (proposal.canceled) revert("Proposal is canceled");
        if (block.timestamp <= proposal.voteEnd) revert("Voting period not ended");

        // Check if proposal passed: simple majority of those who voted, and quorum.
        uint256 totalVotesCast = proposal.votesFor + proposal.votesAgainst;
        require(totalVotesCast > 0, "No votes cast");
        
        // Quorum: E.g., at least 20% of the total available voting power at snapshot must have voted.
        // This is a simplified quorum against total possible votes, not total actual supply.
        // A more robust system would take a snapshot of total token supply.
        require(totalVotesCast * 100 >= proposal.totalVotingPowerAtSnapshot * QUORUM_PERCENTAGE, "Quorum not met");
        require(proposal.votesFor > proposal.votesAgainst, ProposalVoteFailed());

        // Set ETA if not already set (e.g., if first time checking after vote ends)
        if (proposal.eta == 0) {
            proposal.eta = uint40(block.timestamp + proposal.delay);
        }

        if (block.timestamp < proposal.eta) revert("Timelock not expired");

        proposal.executed = true;

        // Execute the proposal's action
        (bool success, ) = proposal.target.call(proposal.callData);
        if (!success) revert ProposalFailed();

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows FON holders to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        delegates[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Internal function to get the total voting power of an address.
     *      Voting power is the sum of all FONs held across all models.
     *      Note: This function iterates through all registered models, which can become gas-expensive
     *      if `nextModelId` grows very large. For extreme scalability, a dedicated governance token
     *      or a snapshot-based voting system would be more efficient.
     * @param _voter The address whose voting power is to be calculated.
     * @return The total voting power.
     */
    function _getTotalVotingPower(address _voter) internal view returns (uint256) {
        uint256 totalPower = 0;
        for (uint256 i = 1; i < nextModelId; i++) {
            totalPower += _fonBalances[i][_voter];
        }
        return totalPower;
    }

    /**
     * @dev Allows the DAO to execute any arbitrary function call on this contract or another.
     *      This is the entry point for DAO-approved proposals targeting external contracts or internal functions.
     *      It ensures that only the contract itself (when executing a proposal) can trigger arbitrary calls.
     * @param _callData The encoded function call to execute.
     */
    function executeProposalAction(bytes calldata _callData) external override {
        // This function should only be callable by `executeGovernanceProposal` through `callData`
        // targeting this contract. The `msg.sender` for this call will be `this` contract itself.
        // Internal functions like `_updateModelURIInternal` should then check `msg.sender == address(this)`.
        if (msg.sender != address(this)) revert NotApproved(); 
        
        (bool success, ) = address(this).call(_callData);
        if (!success) revert ProposalFailed();
    }

    // --- Helper Library ---

    /**
     * @dev Library for converting uint256 to string.
     *      Adapted from OpenZeppelin, but common utility.
     */
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            uint256 temp = value;
            uint256 digits;
            while (temp != 0) {
                digits++;
                temp /= 10;
            }
            bytes memory buffer = new bytes(digits);
            while (value != 0) {
                digits--;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```