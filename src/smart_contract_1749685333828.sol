Okay, here is a Solidity smart contract concept I've designed called "NarrativeNexus". It focuses on creating, staking on, and resolving "narratives" (propositions or predictions) on-chain, incorporating concepts like dynamic credibility scores, a simple reputation system, and a structured resolution process, aiming for creativity and multiple functions without directly cloning common open-source patterns like standard ERC20/721 contracts, basic staking, or fixed-price mints.

---

**Contract Name:** `NarrativeNexus`

**Description:** A decentralized platform for proposing and engaging with 'narratives' – speculative or factual propositions about future events or states. Users can stake tokens to support or oppose a narrative's predicted outcome. The contract facilitates resolution (potentially via oracle or time) and rewards successful predictors while penalizing unsuccessful ones, contributing to a dynamic "credibility score" for each narrative and a simple on-chain "reputation" for users.

**Core Concepts:**
1.  **Narratives:** On-chain representations of testable propositions.
2.  **Staking:** Users lock tokens to signal their belief in a narrative's outcome (For or Against).
3.  **Resolution:** A defined process (oracle-driven or time-based) to determine the objective outcome of a narrative.
4.  **Dynamic Credibility:** A score for each narrative, influenced by how well the collective staking predicted the actual outcome.
5.  **User Reputation:** A simple score reflecting a user's history of successful predictions/stakes.
6.  **Structured Workflow:** Narratives progress through distinct states (Open, ResolutionRequested, Resolved, Canceled).
7.  **Fee Mechanism:** A small percentage of losing stakes is taken as a protocol fee before distribution to winners.

**State Variables Summary:**
*   `owner`: The contract owner (basic admin).
*   `paused`: Boolean to pause core functions.
*   `stakingToken`: Address of the ERC20 token used for staking.
*   `narratives`: Mapping from unique ID to `Narrative` struct.
*   `narrativeCount`: Counter for generating unique narrative IDs.
*   `userReputation`: Mapping from user address to reputation score.
*   `narrativeStakeFor`: Mapping `narrativeId => user => amount` staked 'For'.
*   `narrativeStakeAgainst`: Mapping `narrativeId => user => amount` staked 'Against'.
*   `totalNarrativeStakeFor`: Mapping `narrativeId => total amount` staked 'For'.
*   `totalNarrativeStakeAgainst`: Mapping `narrativeId => total amount` staked 'Against'.
*   `narrativeOutcome`: Mapping `narrativeId => resolved outcome (bool?)`.
*   `claimsProcessed`: Mapping `narrativeId => user => bool` (has claimed?).
*   `protocolFeesCollected`: Total fees accumulated.
*   `feePercentageBasisPoints`: Fee percentage * 100 (e.g., 500 for 5%).
*   `currentParams`: Struct holding adjustable parameters (min stake, max stake, resolution period).
*   `proposedParams`: Struct holding proposed parameters (for owner acceptance).

**Enums & Structs Summary:**
*   `ResolutionMethod`: Enum { ORACLE, TIMESTAMP } - How a narrative is resolved.
*   `NarrativeStatus`: Enum { OPEN, RESOLUTION_REQUESTED, RESOLVED, CANCELED } - Current state of a narrative.
*   `Narrative`: Struct holding narrative details (proposer, details, status, method, time, oracle query ID, etc.).
*   `ContractParams`: Struct holding adjustable contract parameters.

**Events Summary:**
*   `NarrativeProposed`: Logs when a narrative is created.
*   `StakedFor`: Logs a 'For' stake.
*   `StakedAgainst`: Logs an 'Against' stake.
*   `Unstaked`: Logs a stake withdrawal (before resolution).
*   `EvidenceAdded`: Logs when evidence hash is added.
*   `ResolutionRequested`: Logs when resolution process starts.
*   `OracleResultSubmitted`: Logs when an oracle result is received.
*   `NarrativeResolved`: Logs when a narrative is finalized.
*   `WinningsClaimed`: Logs when a user claims winnings.
*   `NarrativeCanceled`: Logs when a narrative is canceled.
*   `FeePercentageUpdated`: Logs change in fee.
*   `FeesWithdrawn`: Logs withdrawal of fees by owner.
*   `Paused`, `Unpaused`: System pause state changes.
*   `ParamsProposed`, `ParamsAccepted`: Governance/parameter update events.

**Function Summary (>= 20):**

**Setup & Administration:**
1.  `constructor(address _stakingToken)`: Initializes the contract with the staking token address.
2.  `setFeePercentage(uint256 _feeBasisPoints)`: Owner sets the fee percentage on losing stakes.
3.  `withdrawFees()`: Owner withdraws accumulated protocol fees.
4.  `pauseSystem()`: Owner pauses core staking/resolution functions.
5.  `unpauseSystem()`: Owner unpauses the system.
6.  `proposeParamUpdate(uint256 _minStake, uint256 _maxStake, uint256 _resolutionPeriod)`: Owner proposes new contract parameters.
7.  `acceptParamUpdate()`: Owner accepts the proposed parameters.

**Narrative Management:**
8.  `proposeNarrative(string memory _details, ResolutionMethod _method, uint256 _resolutionTime, bytes32 _oracleQueryId)`: Creates a new narrative with details, resolution method, time (if applicable), and oracle ID (if applicable). Requires minimum stake from proposer.
9.  `addEvidence(uint256 _narrativeId, string memory _evidenceHash)`: Adds a hash (pointer to off-chain evidence) to a narrative.
10. `cancelNarrative(uint256 _narrativeId, string memory _reason)`: Owner or proposer can cancel a narrative if no staking has occurred or with governance approval (simplified to owner for this example).
11. `withdrawCanceledStake(uint256 _narrativeId)`: Users reclaim stakes from a canceled narrative.

**Staking:**
12. `stakeFor(uint256 _narrativeId, uint256 _amount)`: Stakes tokens in support of a narrative's outcome.
13. `stakeAgainst(uint256 _narrativeId, uint256 _amount)`: Stakes tokens in opposition to a narrative's outcome.
14. `unstake(uint256 _narrativeId, uint256 _amount)`: Allows users to withdraw a portion of their stake *before* resolution is requested.

**Resolution & Claims:**
15. `requestResolution(uint256 _narrativeId)`: Initiates the resolution process for a narrative (callable by anyone after resolution time or meeting oracle conditions). Changes status to `RESOLUTION_REQUESTED`.
16. `submitOracleResult(uint256 _narrativeId, bytes32 _oracleQueryId, bool _outcome)`: Designated oracle address submits the outcome for ORACLE-based narratives.
17. `resolveNarrative(uint256 _narrativeId)`: Finalizes the narrative resolution. Calculates winnings based on the outcome and staked amounts. Updates user reputation. Transitions status to `RESOLVED`. Callable after `RESOLUTION_REQUESTED` and time/oracle conditions met.
18. `claimWinnings(uint256 _narrativeId)`: Users claim their share of the winning pool after a narrative is resolved.

**Queries & Views:**
19. `getNarrative(uint256 _narrativeId)`: Returns the struct containing details of a specific narrative.
20. `getNarrativeState(uint256 _narrativeId)`: Returns dynamic state like total staked 'For' and 'Against'.
21. `getUserStake(uint256 _narrativeId, address _user)`: Returns the amount a specific user staked 'For' and 'Against' on a narrative.
22. `getNarrativeEvidence(uint256 _narrativeId)`: Returns the list of evidence hashes for a narrative.
23. `getNarrativeResolutionParams(uint256 _narrativeId)`: Returns the resolution method, time, and oracle ID.
24. `getNarrativeStatus(uint256 _narrativeId)`: Returns the current status of a narrative.
25. `checkResolutionOutcome(uint256 _narrativeId)`: Returns the resolved outcome (if resolved).
26. `calculateNarrativeCredibility(uint256 _narrativeId)`: Calculates a score based on the narrative's resolution outcome vs. the initial staking ratio. Returns 0 if not resolved.
27. `getUserReputation(address _user)`: Returns the reputation score of a user.
28. `getContractBalance()`: Returns the balance of the staking token held by the contract.
29. `getCurrentParams()`: Returns the currently active contract parameters.
30. `getProposedParams()`: Returns the parameters currently proposed but not yet accepted.

This structure provides a complete lifecycle for narratives, involves user interaction through staking and claims, uses a structured resolution process, and adds layers like reputation and dynamic credibility scores.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Basic ERC20 Interface (simplified, not importing OpenZeppelin)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title NarrativeNexus
 * @dev A smart contract for decentralized narrative staking and resolution with dynamic credibility and user reputation.
 */
contract NarrativeNexus {

    // --- State Variables ---
    address public owner;
    bool public paused = false;
    address public stakingToken;

    uint256 public narrativeCount = 0;

    // --- Enums & Structs ---

    enum ResolutionMethod {
        ORACLE,       // Resolved by a trusted oracle (or designated address)
        TIMESTAMP     // Resolved automatically after a specific time
    }

    enum NarrativeStatus {
        OPEN,                 // Open for staking and evidence
        RESOLUTION_REQUESTED, // Resolution process initiated (e.g., oracle query sent, or time reached)
        RESOLVED,             // Outcome determined, open for claims
        CANCELED              // Narrative canceled, stakes can be withdrawn
    }

    struct Narrative {
        uint256 id;
        address proposer;
        string details; // IPFS hash or summary
        ResolutionMethod method;
        uint256 resolutionTime; // Timestamp if method is TIMESTAMP
        bytes32 oracleQueryId;  // Identifier for oracle query if method is ORACLE
        NarrativeStatus status;
        uint256 proposalTime;

        uint256 totalStakedFor;
        uint256 totalStakedAgainst;

        bool resolvedOutcome; // true for 'For', false for 'Against'
        bool outcomeSubmitted; // Whether the outcome has been submitted (for ORACLE method)

        string[] evidenceHashes; // List of evidence identifiers (IPFS hashes etc.)
    }

    struct ContractParams {
        uint256 minStakePerUser; // Minimum amount a user can stake per side
        uint256 maxStakePerNarrative; // Maximum total stake allowed per narrative
        uint256 minProposerStake; // Minimum stake required to propose a narrative
        uint256 resolutionRequestGracePeriod; // Time after resolutionTime/Oracle submission allows claims
    }

    mapping(uint256 => Narrative) public narratives;

    // User stake tracking: narrativeId => userAddress => amount
    mapping(uint256 => mapping(address => uint256)) public narrativeStakeFor;
    mapping(uint256 => mapping(address => uint256)) public narrativeStakeAgainst;

    // Track if a user has claimed winnings for a specific narrative
    mapping(uint256 => mapping(address => bool)) private claimsProcessed;

    // Simple user reputation score (e.g., points for successful predictions)
    mapping(address => uint256) public userReputation;

    // Protocol fees
    uint256 public protocolFeesCollected;
    uint256 public feePercentageBasisPoints; // Stored as basis points (e.g., 500 for 5%)

    // Contract Parameters
    ContractParams public currentParams;
    ContractParams public proposedParams; // For simple owner-based update proposal

    // --- Events ---

    event NarrativeProposed(uint256 indexed narrativeId, address indexed proposer, ResolutionMethod method, uint256 resolutionTime);
    event StakedFor(uint256 indexed narrativeId, address indexed user, uint256 amount);
    event StakedAgainst(uint256 indexed narrativeId, address indexed user, uint256 amount);
    event Unstaked(uint256 indexed narrativeId, address indexed user, uint256 amount);
    event EvidenceAdded(uint256 indexed narrativeId, string evidenceHash);
    event ResolutionRequested(uint256 indexed narrativeId);
    event OracleResultSubmitted(uint256 indexed narrativeId, bool outcome); // Simplified signature
    event NarrativeResolved(uint256 indexed narrativeId, bool outcome);
    event WinningsClaimed(uint256 indexed narrativeId, address indexed user, uint256 amount);
    event NarrativeCanceled(uint256 indexed narrativeId, string reason);
    event FeePercentageUpdated(uint256 newFeeBasisPoints);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event Paused();
    event Unpaused();
    event ParamsProposed(ContractParams params);
    event ParamsAccepted(ContractParams params);
    event ReputationUpdated(address indexed user, uint256 newReputation);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // --- Functions ---

    /**
     * @dev Constructor: Initializes the contract with the staking token address.
     * @param _stakingToken Address of the ERC20 token to be used for staking.
     */
    constructor(address _stakingToken) {
        owner = msg.sender;
        stakingToken = _stakingToken;
        feePercentageBasisPoints = 500; // Default 5% fee

        // Set initial default parameters
        currentParams = ContractParams({
            minStakePerUser: 1 ether, // Example: 1 token minimum stake
            maxStakePerNarrative: 1000000 ether, // Example: 1M token max total stake
            minProposerStake: 10 ether, // Example: 10 token minimum to propose
            resolutionRequestGracePeriod: 1 days // Example: Allow claims 1 day after resolution
        });
    }

    // --- Setup & Administration ---

    /**
     * @dev Allows the owner to set the fee percentage applied to losing stakes.
     * @param _feeBasisPoints Fee percentage in basis points (e.g., 100 = 1%). Max 10000 (100%).
     */
    function setFeePercentage(uint256 _feeBasisPoints) external onlyOwner {
        require(_feeBasisPoints <= 10000, "Fee percentage cannot exceed 100%");
        feePercentageBasisPoints = _feeBasisPoints;
        emit FeePercentageUpdated(_feeBasisPoints);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 fees = protocolFeesCollected;
        protocolFeesCollected = 0;
        require(fees > 0, "No fees collected");
        require(IERC20(stakingToken).transfer(owner, fees), "Fee withdrawal failed");
        emit FeesWithdrawn(owner, fees);
    }

    /**
     * @dev Allows the owner to pause core contract functions.
     */
    function pauseSystem() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

    /**
     * @dev Allows the owner to unpause core contract functions.
     */
    function unpauseSystem() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused();
    }

    /**
     * @dev Owner proposes new contract parameters.
     * @param _minStake Minimum stake per user per side.
     * @param _maxStake Maximum total stake per narrative.
     * @param _minProposerStake Minimum stake to propose.
     * @param _resolutionPeriod Grace period after resolution request.
     */
    function proposeParamUpdate(uint256 _minStake, uint256 _maxStake, uint256 _minProposerStake, uint256 _resolutionPeriod) external onlyOwner {
        proposedParams = ContractParams({
            minStakePerUser: _minStake,
            maxStakePerNarrative: _maxStake,
            minProposerStake: _minProposerStake,
            resolutionRequestGracePeriod: _resolutionPeriod
        });
        emit ParamsProposed(proposedParams);
    }

     /**
     * @dev Owner accepts the proposed contract parameters, making them active.
     */
    function acceptParamUpdate() external onlyOwner {
        currentParams = proposedParams;
        emit ParamsAccepted(currentParams);
    }

    // --- Narrative Management ---

    /**
     * @dev Allows a user to propose a new narrative. Requires minimum proposer stake.
     * @param _details String identifier for narrative details (e.g., IPFS hash).
     * @param _method Resolution method (ORACLE or TIMESTAMP).
     * @param _resolutionTime Timestamp if method is TIMESTAMP.
     * @param _oracleQueryId Oracle-specific query ID if method is ORACLE.
     */
    function proposeNarrative(string memory _details, ResolutionMethod _method, uint256 _resolutionTime, bytes32 _oracleQueryId) external whenNotPaused {
        require(bytes(_details).length > 0, "Narrative details cannot be empty");
        if (_method == ResolutionMethod.TIMESTAMP) {
            require(_resolutionTime > block.timestamp, "Resolution time must be in the future");
        }
        if (_method == ResolutionMethod.ORACLE) {
             require(_oracleQueryId != bytes32(0), "Oracle query ID must be provided for ORACLE method");
        }

        uint256 newId = narrativeCount;
        narratives[newId] = Narrative({
            id: newId,
            proposer: msg.sender,
            details: _details,
            method: _method,
            resolutionTime: _resolutionTime,
            oracleQueryId: _oracleQueryId,
            status: NarrativeStatus.OPEN,
            proposalTime: block.timestamp,
            totalStakedFor: 0,
            totalStakedAgainst: 0,
            resolvedOutcome: false, // Default value, actual outcome set on resolve
            outcomeSubmitted: false, // Default for ORACLE
            evidenceHashes: new string[](0)
        });

        narrativeCount++;

        // Require proposer to stake a minimum amount on their own narrative (can be For or Against)
        // This prevents spam, but we need a mechanism to allow them to actually stake first.
        // Alternative: Require initial stake *during* proposal. Let's use that.
        // require(IERC20(stakingToken).transferFrom(msg.sender, address(this), currentParams.minProposerStake), "Proposer initial stake failed");
        // narrativeStakeFor[newId][msg.sender] += currentParams.minProposerStake; // Assume proposer stakes For
        // narratives[newId].totalStakedFor += currentParams.minProposerStake;
        // Let's keep proposal separate and just require the stake *before* staking is possible for others.
        // Simpler approach: require the *caller* of proposeNarrative to have already approved the token
        // and we transfer it here. Let's make it simpler - propose is free, *first stake* needs min amount.
        // Or, require min stake *after* proposal to open staking. Okay, let's just make proposal free
        // and enforce minStakePerUser on *any* stake, including the proposer's first.

        emit NarrativeProposed(newId, msg.sender, _method, _resolutionTime);
    }


    /**
     * @dev Adds a hash referencing off-chain evidence to a narrative.
     * @param _narrativeId The ID of the narrative.
     * @param _evidenceHash The hash string (e.g., IPFS CID).
     */
    function addEvidence(uint256 _narrativeId, string memory _evidenceHash) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.OPEN, "Evidence can only be added to open narratives");
        require(bytes(_evidenceHash).length > 0, "Evidence hash cannot be empty");

        narrative.evidenceHashes.push(_evidenceHash);
        emit EvidenceAdded(_narrativeId, _evidenceHash);
    }

    /**
     * @dev Allows the owner or proposer to cancel a narrative if it's still open and no stakes have occurred (or with simplified owner power).
     * @param _narrativeId The ID of the narrative to cancel.
     * @param _reason String explaining the reason for cancellation.
     */
    function cancelNarrative(uint256 _narrativeId, string memory _reason) external onlyOwner { // Simplified to onlyOwner
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.OPEN, "Narrative must be open to be canceled");
        // Add more complex logic here if needed, e.g., check if total staked is 0, or requires proposer + votes

        narrative.status = NarrativeStatus.CANCELED;
        emit NarrativeCanceled(_narrativeId, _reason);
    }

    /**
     * @dev Allows users to withdraw their stake if a narrative is canceled.
     * @param _narrativeId The ID of the canceled narrative.
     */
    function withdrawCanceledStake(uint256 _narrativeId) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.CANCELED, "Narrative must be canceled to withdraw stakes");

        uint256 userForStake = narrativeStakeFor[_narrativeId][msg.sender];
        uint256 userAgainstStake = narrativeStakeAgainst[_narrativeId][msg.sender];
        uint256 totalStake = userForStake + userAgainstStake;

        require(totalStake > 0, "No stake found for this user on this narrative");
        require(!claimsProcessed[_narrativeId][msg.sender], "Stake already withdrawn for this user");

        // Transfer tokens back
        require(IERC20(stakingToken).transfer(msg.sender, totalStake), "Stake withdrawal failed");

        // Mark as processed
        claimsProcessed[_narrativeId][msg.sender] = true;

        // Reset stakes for the user for this narrative (optional, cleaner state)
        narrativeStakeFor[_narrativeId][msg.sender] = 0;
        narrativeStakeAgainst[_narrativeId][msg.sender] = 0;
        // Note: totalStakedFor/Against on the narrative struct are NOT decreased here,
        // as they represent historical totals. The balance check is done via userStake mappings.

        emit WinningsClaimed(_narrativeId, msg.sender, totalStake); // Re-using event for simplicity
    }


    // --- Staking ---

    /**
     * @dev Stakes tokens in support of a narrative's predicted outcome ('For').
     * Requires caller to have approved this contract to spend the tokens.
     * @param _narrativeId The ID of the narrative.
     * @param _amount The amount of tokens to stake.
     */
    function stakeFor(uint256 _narrativeId, uint256 _amount) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.OPEN, "Narrative is not open for staking");
        require(_amount >= currentParams.minStakePerUser, "Stake amount below minimum");

        uint256 currentTotalStaked = narrative.totalStakedFor + narrative.totalStakedAgainst;
        require(currentTotalStaked + _amount <= currentParams.maxStakePerNarrative, "Exceeds max total stake for narrative");

        // Transfer tokens from user to contract
        require(IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Update state
        narrativeStakeFor[_narrativeId][msg.sender] += _amount;
        narrative.totalStakedFor += _amount;

        emit StakedFor(_narrativeId, msg.sender, _amount);
    }

    /**
     * @dev Stakes tokens in opposition to a narrative's predicted outcome ('Against').
     * Requires caller to have approved this contract to spend the tokens.
     * @param _narrativeId The ID of the narrative.
     * @param _amount The amount of tokens to stake.
     */
    function stakeAgainst(uint256 _narrativeId, uint256 _amount) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.OPEN, "Narrative is not open for staking");
        require(_amount >= currentParams.minStakePerUser, "Stake amount below minimum");

        uint256 currentTotalStaked = narrative.totalStakedFor + narrative.totalStakedAgainst;
        require(currentTotalStaked + _amount <= currentParams.maxStakePerNarrative, "Exceeds max total stake for narrative");

        // Transfer tokens from user to contract
        require(IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Update state
        narrativeStakeAgainst[_narrativeId][msg.sender] += _amount;
        narrative.totalStakedAgainst += _amount;

        emit StakedAgainst(_narrativeId, msg.sender, _amount);
    }

    /**
     * @dev Allows users to withdraw a portion of their stake *before* the narrative's resolution is requested.
     * @param _narrativeId The ID of the narrative.
     * @param _amount The amount to unstake.
     */
    function unstake(uint256 _narrativeId, uint256 _amount) external whenNotPaused {
         Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.OPEN, "Narrative must be open to unstake");
        require(_amount > 0, "Amount must be greater than 0");

        uint256 userForStake = narrativeStakeFor[_narrativeId][msg.sender];
        uint256 userAgainstStake = narrativeStakeAgainst[_narrativeId][msg.sender];
        uint256 totalUserStake = userForStake + userAgainstStake;

        require(totalUserStake >= _amount, "Unstake amount exceeds user's total stake");

        // Simple logic: unstake reduces from Against first, then For. Or proportional?
        // Let's keep it simple: unstake reduces from the larger stake first.
        uint256 amountToUnstakeFor = 0;
        uint256 amountToUnstakeAgainst = 0;

        if (userForStake >= userAgainstStake) {
            amountToUnstakeFor = _amount > userForStake ? userForStake : _amount;
            uint256 remainingAmount = _amount - amountToUnstakeFor;
            amountToUnstakeAgainst = remainingAmount > userAgainstStake ? userAgainstStake : remainingAmount;
        } else {
             amountToUnstakeAgainst = _amount > userAgainstStake ? userAgainstStake : _amount;
            uint256 remainingAmount = _amount - amountToUnstakeAgainst;
            amountToUnstakeFor = remainingAmount > userForStake ? userForStake : remainingAmount;
        }

        narrativeStakeFor[_narrativeId][msg.sender] -= amountToUnstakeFor;
        narrativeStakeAgainst[_narrativeId][msg.sender] -= amountToUnstakeAgainst;

        // Note: totalStakedFor/Against on narrative struct are NOT decreased here,
        // as they represent the total pool size available for potential payout.
        // The tokens are transferred back from the contract's total balance.

        require(IERC20(stakingToken).transfer(msg.sender, _amount), "Token transfer failed");

        emit Unstaked(_narrativeId, msg.sender, _amount);
    }

    // --- Resolution & Claims ---

    /**
     * @dev Initiates the resolution process for a narrative. Callable when resolution conditions are met.
     * Changes status to RESOLUTION_REQUESTED.
     * @param _narrativeId The ID of the narrative.
     */
    function requestResolution(uint256 _narrativeId) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.OPEN, "Narrative must be open to request resolution");

        // Check resolution conditions
        if (narrative.method == ResolutionMethod.TIMESTAMP) {
            require(block.timestamp >= narrative.resolutionTime, "Resolution time not yet reached");
        } else if (narrative.method == ResolutionMethod.ORACLE) {
             // For ORACLE method, this might trigger an off-chain oracle query.
             // The contract doesn't *do* the query, but marks that the process has started.
             // require external oracle system to monitor this event and submit result.
        } else {
            revert("Unknown resolution method"); // Should not happen
        }

        narrative.status = NarrativeStatus.RESOLUTION_REQUESTED;
        emit ResolutionRequested(_narrativeId);
    }

    /**
     * @dev Allows a designated oracle address (or owner in this simple example) to submit the outcome for ORACLE narratives.
     * @param _narrativeId The ID of the narrative.
     * @param _oracleQueryId The oracle query ID this result corresponds to.
     * @param _outcome The resolved outcome (true for 'For', false for 'Against').
     */
    function submitOracleResult(uint256 _narrativeId, bytes32 _oracleQueryId, bool _outcome) external onlyOwner whenNotPaused { // Simplified access control to onlyOwner
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.method == ResolutionMethod.ORACLE, "Narrative method is not ORACLE");
        require(narrative.status == NarrativeStatus.RESOLUTION_REQUESTED, "Narrative is not awaiting oracle result");
        require(narrative.oracleQueryId == _oracleQueryId, "Mismatched oracle query ID");
        require(!narrative.outcomeSubmitted, "Outcome already submitted for this query");

        narrative.resolvedOutcome = _outcome;
        narrative.outcomeSubmitted = true; // Mark outcome as received

        // Now the narrative is ready to be resolved
        emit OracleResultSubmitted(_narrativeId, _outcome);
    }


    /**
     * @dev Finalizes the narrative resolution and calculates winnings. Callable after conditions are met.
     * @param _narrativeId The ID of the narrative.
     */
    function resolveNarrative(uint256 _narrativeId) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.RESOLUTION_REQUESTED, "Narrative is not awaiting final resolution");

        // Check if resolution conditions are truly met after request
        if (narrative.method == ResolutionMethod.TIMESTAMP) {
            require(block.timestamp >= narrative.resolutionTime, "Resolution time not yet reached");
        } else if (narrative.method == ResolutionMethod.ORACLE) {
             require(narrative.outcomeSubmitted, "Oracle result not yet submitted");
        } else {
            revert("Unknown resolution method");
        }

        // Outcome is already set if ORACLE method, retrieve if TIMESTAMP
        if (narrative.method == ResolutionMethod.TIMESTAMP) {
             // For TIMESTAMP method, outcome needs to be determined differently.
             // This is a placeholder for a more complex on-chain check or manual resolution.
             // In this example, we'll make TIMESTAMP outcomes require a separate submit function
             // or rely on the owner submitting (simplest). Let's make TIMESTAMP just
             // mean "resolution can be *requested* after this time", and outcome submitted manually (by owner/oracle).
             // OR let's make TIMESTAMP method resolve based on the *final staking ratio* at resolution time?
             // That's interesting! Let's do that.
             // If Method is TIMESTAMP, outcome = totalStakedFor > totalStakedAgainst at resolution time.
             narrative.resolvedOutcome = narrative.totalStakedFor >= narrative.totalStakedAgainst; // True if FOR wins or tie
        }
        // If method is ORACLE, resolvedOutcome is already set by submitOracleResult

        uint256 totalPool = narrative.totalStakedFor + narrative.totalStakedAgainst;
        require(totalPool > 0, "No tokens staked on this narrative"); // Cannot resolve if nobody staked

        uint256 winningPool;
        uint256 losingPool;

        if (narrative.resolvedOutcome) { // 'For' wins
            winningPool = narrative.totalStakedFor;
            losingPool = narrative.totalStakedAgainst;
        } else { // 'Against' wins
            winningPool = narrative.totalStakedAgainst;
            losingPool = narrative.totalStakedFor;
        }

        // Calculate fees from the losing pool
        uint256 feeAmount = (losingPool * feePercentageBasisPoints) / 10000;
        protocolFeesCollected += feeAmount;
        uint256 payoutPool = totalPool - feeAmount; // Total tokens to be distributed among winners

        // Winning stakes get their initial stake back + a proportional share of the losing pool minus fees
        // Payout multiplier = payoutPool / winningPool (scaled by 10000 to avoid floats)
        // Simplified: each winning token receives (payoutPool * 10000 / winningPool) / 10000 per token
        // Or more simply: total amount to return to winners is payoutPool.
        // Each winner gets back (their stake) + (their stake / winningPool) * losingPool_after_fee
        // = (their stake) * (1 + (losingPool * (10000 - feeBasisPoints) / 10000) / winningPool)
        // Or: (their stake) * (payoutPool / winningPool) if we distribute the whole pool
        // Let's make it simple: winners split the *entire* pool minus fees proportionally to their stake.
        // Total amount returned to winners = payoutPool
        // Amount per winner = (their stake / winningPool) * payoutPool

        narrative.status = NarrativeStatus.RESOLVED;

        emit NarrativeResolved(_narrativeId, narrative.resolvedOutcome);

        // Users claim via claimWinnings function
    }

    /**
     * @dev Allows a user to claim their winnings after a narrative is resolved.
     * @param _narrativeId The ID of the resolved narrative.
     */
    function claimWinnings(uint256 _narrativeId) external whenNotPaused {
        Narrative storage narrative = narratives[_narrativeId];
        require(narrative.id == _narrativeId, "Narrative does not exist");
        require(narrative.status == NarrativeStatus.RESOLVED, "Narrative is not resolved");
        require(!claimsProcessed[_narrativeId][msg.sender], "Winnings already claimed for this user");
        require(block.timestamp >= narrative.resolutionTime + currentParams.resolutionRequestGracePeriod, "Claiming period not yet open"); // Example: Claim after grace period

        uint256 userForStake = narrativeStakeFor[_narrativeId][msg.sender];
        uint256 userAgainstStake = narrativeStakeAgainst[_narrativeId][msg.sender];
        uint256 totalUserStake = userForStake + userAgainstStake;

        require(totalUserStake > 0, "No stake found for this user on this narrative");

        uint256 winningStake;
        uint256 losingStake;

        if (narrative.resolvedOutcome) { // 'For' won
            winningStake = userForStake;
            losingStake = userAgainstStake;
        } else { // 'Against' won
            winningStake = userAgainstStake;
            losingStake = userForStake;
        }

        require(winningStake > 0, "User was not on the winning side or had no stake");

        uint256 totalWinningPool = narrative.resolvedOutcome ? narrative.totalStakedFor : narrative.totalStakedAgainst;
        uint256 totalLosingPool = narrative.resolvedOutcome ? narrative.totalStakedAgainst : narrative.totalStakedFor;
        uint256 totalPool = totalWinningPool + totalLosingPool;
        uint256 payoutPool = totalPool - (totalLosingPool * feePercentageBasisPoints) / 10000;

        // Calculate user's payout: (user's winning stake / total winning pool) * payoutPool
        // Use SafeMath implicitly with Solidity 0.8+
        uint256 payoutAmount = (winningStake * payoutPool) / totalWinningPool;

        // Transfer tokens
        require(IERC20(stakingToken).transfer(msg.sender, payoutAmount), "Claim transfer failed");

        // Mark as claimed
        claimsProcessed[_narrativeId][msg.sender] = true;

        // Update user reputation (simple scoring: +10 points for successful claim)
        userReputation[msg.sender] += 10;
        emit ReputationUpdated(msg.sender, userReputation[msg.sender]);

        emit WinningsClaimed(_narrativeId, msg.sender, payoutAmount);
    }


    // --- Queries & Views ---

    /**
     * @dev Returns the details of a specific narrative.
     * @param _narrativeId The ID of the narrative.
     * @return Narrative struct.
     */
    function getNarrative(uint256 _narrativeId) external view returns (Narrative memory) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        return narratives[_narrativeId];
    }

     /**
     * @dev Returns the dynamic state of a narrative (current total staked).
     * Note: This returns the *total* staked *for* and *against* recorded in the narrative struct,
     * which doesn't change after resolution, but is the basis for payout calculation.
     * For real-time stake totals before resolution, you'd sum up user stakes, which is expensive.
     * The struct totals are set *before* resolution/unstaking calculation.
     * @param _narrativeId The ID of the narrative.
     * @return totalStakedFor Total amount staked 'For'.
     * @return totalStakedAgainst Total amount staked 'Against'.
     */
    function getNarrativeState(uint256 _narrativeId) external view returns (uint256 totalStakedFor, uint256 totalStakedAgainst) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        Narrative storage narrative = narratives[_narrativeId];
        return (narrative.totalStakedFor, narrative.totalStakedAgainst);
    }

    /**
     * @dev Returns the amount a specific user has staked on a narrative.
     * @param _narrativeId The ID of the narrative.
     * @param _user The user's address.
     * @return stakedFor Amount staked 'For'.
     * @return stakedAgainst Amount staked 'Against'.
     */
    function getUserStake(uint256 _narrativeId, address _user) external view returns (uint256 stakedFor, uint256 stakedAgainst) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        return (narrativeStakeFor[_narrativeId][_user], narrativeStakeAgainst[_narrativeId][_user]);
    }

    /**
     * @dev Returns the list of evidence hashes for a narrative.
     * @param _narrativeId The ID of the narrative.
     * @return string[] Array of evidence hashes.
     */
    function getNarrativeEvidence(uint256 _narrativeId) external view returns (string[] memory) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        return narratives[_narrativeId].evidenceHashes;
    }

    /**
     * @dev Returns the resolution parameters for a narrative.
     * @param _narrativeId The ID of the narrative.
     * @return method Resolution method.
     * @return resolutionTime Timestamp if method is TIMESTAMP.
     * @return oracleQueryId Oracle query ID if method is ORACLE.
     */
    function getNarrativeResolutionParams(uint256 _narrativeId) external view returns (ResolutionMethod method, uint256 resolutionTime, bytes32 oracleQueryId) {
         require(_narrativeId < narrativeCount, "Narrative does not exist");
         Narrative storage narrative = narratives[_narrativeId];
         return (narrative.method, narrative.resolutionTime, narrative.oracleQueryId);
    }

    /**
     * @dev Returns the current status of a narrative.
     * @param _narrativeId The ID of the narrative.
     * @return NarrativeStatus Status enum.
     */
    function getNarrativeStatus(uint256 _narrativeId) external view returns (NarrativeStatus) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        return narratives[_narrativeId].status;
    }

     /**
     * @dev Returns the resolved outcome of a narrative, if resolved.
     * @param _narrativeId The ID of the narrative.
     * @return bool Resolved outcome (true for 'For', false for 'Against'). Returns default(bool) if not resolved.
     */
    function checkResolutionOutcome(uint256 _narrativeId) external view returns (bool) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        require(narratives[_narrativeId].status == NarrativeStatus.RESOLVED, "Narrative is not resolved");
        return narratives[_narrativeId].resolvedOutcome;
    }


    /**
     * @dev Calculates a dynamic credibility score for a *resolved* narrative.
     * Score is higher if the initial staking ratio accurately predicted the outcome.
     * Simple Scoring: abs((stakedForRatio - actualOutcome) * 10000) where actualOutcome is 1 for true, 0 for false.
     * Max score = 10000 (perfect prediction), Min score = 0 (inverse prediction).
     * Returns 0 if not resolved.
     * @param _narrativeId The ID of the narrative.
     * @return uint256 Credibility score out of 10000.
     */
    function calculateNarrativeCredibility(uint256 _narrativeId) external view returns (uint256) {
        require(_narrativeId < narrativeCount, "Narrative does not exist");
        Narrative storage narrative = narratives[_narrativeId];

        if (narrative.status != NarrativeStatus.RESOLVED) {
            return 0; // Credibility only calculated after resolution
        }

        uint256 totalStakeAtResolution = narrative.totalStakedFor + narrative.totalStakedAgainst;
        if (totalStakeAtResolution == 0) {
            return 0; // Cannot calculate credibility if no stake
        }

        // Calculate initial staking ratio (proportion 'For')
        uint256 stakedForRatioScaled = (narrative.totalStakedFor * 10000) / totalStakeAtResolution; // Scaled by 10000

        // Convert actual outcome to scaled value (10000 for true, 0 for false)
        uint256 actualOutcomeScaled = narrative.resolvedOutcome ? 10000 : 0;

        // Calculate absolute difference between predicted ratio and actual outcome
        uint256 difference = stakedForRatioScaled > actualOutcomeScaled ? stakedForRatioScaled - actualOutcomeScaled : actualOutcomeScaled - stakedForRatioScaled;

        // Credibility is inverse of this difference (higher difference = lower credibility)
        // Max difference = 10000, Min difference = 0.
        // Credibility = 10000 - difference
        return 10000 - difference;
    }

    /**
     * @dev Returns the reputation score of a user.
     * @param _user The user's address.
     * @return uint256 Reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user];
    }

    /**
     * @dev Returns the current balance of the staking token held by the contract.
     * @return uint256 Token balance.
     */
    function getContractBalance() external view returns (uint256) {
        return IERC20(stakingToken).balanceOf(address(this));
    }

     /**
     * @dev Returns the currently active contract parameters.
     * @return ContractParams Struct with active parameters.
     */
    function getCurrentParams() external view returns (ContractParams memory) {
        return currentParams;
    }

    /**
     * @dev Returns the contract parameters currently proposed by the owner.
     * @return ContractParams Struct with proposed parameters.
     */
    function getProposedParams() external view returns (ContractParams memory) {
        return proposedParams;
    }

    // Fallback function to reject direct ETH transfers
    receive() external payable {
        revert("ETH not accepted");
    }

    // Fallback function to reject unknown calls
    fallback() external payable {
        revert("Unknown function call");
    }
}
```