Here's a Solidity smart contract for an **"AxiomDAO: The Emergent Governance Protocol"**.

This contract introduces advanced concepts like:
1.  **Parameterized & Evolving Governance**: The DAO can vote to change its fundamental treasury allocation *algorithms* and their parameters, rather than just approving individual spending proposals.
2.  **Dynamic, Contribution-Weighted Influence**: Influence (voting power) is not just based on token holdings, but also decays over time, encouraging continuous engagement and making influence more fluid.
3.  **Epoch-Based System**: The DAO operates in defined epochs, at the end of which influence is recalculated, and other system parameters can be re-evaluated.
4.  **On-chain Algorithm Execution**: The contract includes basic templates for allocation algorithms that the DAO can switch between and configure.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline for AxiomDAO Smart Contract ---

// A decentralized autonomous organization focused on emergent governance, where the community
// collectively defines and refines the core 'axioms' (rules/algorithms) that govern resource
// allocation and influence within the DAO. Influence is dynamic, based on contribution and stake,
// and funds are disbursed via configurable algorithms voted on by the community.

// 1. Core Principles & Vision:
//    - Adaptive Governance: The DAO's economic and governance rules are not static but evolve.
//    - Dynamic Influence: Influence (voting power) is not just token-based but considers staking
//      duration, activity, and decays over time to encourage continuous engagement.
//    - Programmable Treasury: Funds are disbursed via algorithms that the DAO votes to adopt and configure.
//    - Epoch-Based Progression: The system operates in timed epochs, triggering re-evaluations.

// 2. Contract Structure (High-Level Modules):
//    - AxiomToken (AXM): Internal ERC-20 token for staking and governance.
//    - Influence Engine: Manages dynamic contributor influence scores.
//    - Treasury Manager: Handles ETH/WETH treasury and algorithm-driven disbursements.
//    - Governance Module: Manages various proposal types (algorithm changes, parameter updates, general actions), voting, and execution.
//    - Epoch Manager: Controls timed epochs and triggers system updates.
//    - Security & Access Control: Pausable, Ownable (for initial setup/emergency), ReentrancyGuard.

// --- Function Summary (27 functions) ---

// I. Core Token & Influence System:
//    1.  constructor(address _initialOwner): Initializes the contract, deploys internal AXM token, sets initial parameters.
//    2.  registerContributor(uint256 initialStake): Allows users to register and stake initial AXM to become contributors, gaining baseline influence.
//    3.  stakeForInfluence(uint256 amount): Allows existing contributors to stake more AXM, increasing their influence.
//    4.  unstakeFromInfluence(uint256 amount): Allows contributors to unstake AXM (with potential cooldown/penalties).
//    5.  getContributorInfluence(address contributor): Returns the current calculated influence score for a contributor.
//    6.  updateInfluenceDecayRate(uint256 newRate): Governance function to adjust how influence decays over time.
//    7.  syncInfluenceScores(address[] calldata contributors): Triggers influence decay calculation for specified contributors (batched).
//    8.  getTotalStakedAXM(): Returns the total AXM currently staked across all contributors.

// II. Treasury & Allocation Algorithms:
//    9.  depositToTreasury(): Allows anyone to deposit ETH/WETH into the DAO treasury.
//    10. submitAllocationAlgorithmProposal(AllocationAlgorithmType algorithmType, bytes memory parameters, string memory description): Proposes to switch to a different pre-defined algorithm type with specific parameters.
//    11. voteOnAlgorithmProposal(uint256 proposalId, bool support): Vote on a proposed allocation algorithm change.
//    12. activateAllocationAlgorithm(uint256 proposalId): Executes a successfully voted algorithm proposal, making it the active disbursement method.
//    13. executeCurrentAllocationAlgorithmRun(): Triggers a disbursement cycle based on the active algorithm's logic.
//    14. getCurrentAllocationAlgorithmParameters(): Returns the type and parameters of the currently active allocation algorithm.
//    15. updateActiveAlgorithmParameters(bytes memory newParameters): Allows for minor parameter tweaks to the *active* algorithm via a separate governance process.

// III. Governance & Proposals:
//    16. submitGeneralProposal(string memory description, bytes memory callData, address target): For general DAO operations, direct calls to other contracts, or text-based proposals.
//    17. voteOnProposal(uint256 proposalId, uint8 voteOption): Vote on any general proposal.
//    18. executeProposal(uint256 proposalId): Executes a successfully voted general proposal.
//    19. getProposalState(uint256 proposalId): Returns the current state of a proposal.
//    20. getVoteCountForProposal(uint256 proposalId): Returns the vote breakdown for a given proposal.

// IV. Epoch & System Management:
//    21. advanceEpoch(): Callable by a permissioned role (or anyone, if no specific role) at the end of an epoch to trigger epoch transition and influence decay.
//    22. getCurrentEpochData(): Returns the current epoch number and its start/end times.
//    23. setEpochDuration(uint256 newDuration): Governance function to adjust the length of an epoch.

// V. Emergency & Configuration:
//    24. setEmergencyPause(bool _paused): Emergency function to pause critical contract functionalities.
//    25. withdrawEmergencyFunds(address recipient, uint256 amount): Emergency function for fund withdrawals.
//    26. setMinimumInfluenceToPropose(uint256 minInfluence): Governance to adjust proposal threshold.
//    27. setVotingPeriodDuration(uint256 duration): Governance to adjust voting period.

// Additional/Utility Functions:
//    28. getTreasuryBalance(): Returns the current balance of the DAO treasury.


// --- Data Structures (Structs, Enums, Mappings) ---

// AxiomToken: The internal ERC-20 token for staking and governance.
contract AxiomToken is ERC20 {
    constructor(address initialOwner) ERC20("Axiom DAO Token", "AXM") {
        // Mint an initial supply to the initial owner (which can then transfer to the DAO or distribute)
        _mint(initialOwner, 100_000_000 * 10**decimals()); 
    }
}

contract AxiomDAO is Ownable, Pausable, ReentrancyGuard {
    // --- State Variables ---

    // Token & Influence System
    AxiomToken public immutable AXM;
    uint256 public constant MIN_INFLUENCE_DECIMALS = 18; // For consistent influence calculation, same as AXM decimals
    uint256 public influenceDecayRatePerEpoch; // Percentage, e.g., 500 for 5% decay (500 / 10000)
    uint256 public minInfluenceToPropose; // Minimum influence a contributor needs to submit a proposal

    // Represents a contributor's state within the DAO
    struct Contributor {
        uint256 stakedAmount; // AXM tokens staked by this contributor
        uint256 lastInfluenceUpdateEpoch; // Last epoch influence was calculated or updated
        uint256 rawInfluence; // Base influence from staking (scaled by amount). Decays over time.
    }
    mapping(address => Contributor) public contributors;
    mapping(address => bool) public isContributor; // True if address is a registered contributor
    address[] public activeContributors; // A dynamic array to keep track of active contributors for batch updates/iterations

    // Treasury & Allocation
    // Defines the types of treasury allocation algorithms the DAO can choose from
    enum AllocationAlgorithmType {
        NONE,               // No active algorithm
        LINEAR_DISTRIBUTION, // Distributes an equal amount to a specified number of top contributors
        STAKED_PROPORTIONAL // Distributes funds proportionally based on contributors' staked AXM / influence
    }

    // Stores the currently active allocation algorithm and its configuration
    struct AllocationAlgorithm {
        AllocationAlgorithmType algoType; // The type of the active algorithm
        bytes parameters; // ABI encoded parameters specific to the algorithm (e.g., number of recipients, percentage)
        uint256 lastRunEpoch; // Last epoch this algorithm was executed
    }
    AllocationAlgorithm public activeAllocationAlgorithm;

    // Governance & Proposals
    // States a proposal can be in
    enum ProposalState {
        Pending,   // Just created, awaiting voting period start (or becomes Active immediately)
        Active,    // Open for voting
        Succeeded, // Voting ended, met thresholds, awaiting execution
        Failed,    // Voting ended, did not meet thresholds
        Executed   // Proposal successfully executed
    }

    // Possible options for voting
    enum VoteOption {
        Against,
        For,
        Abstain
    }

    // Structure for general-purpose proposals (e.g., calling other contracts, parameter changes)
    struct GeneralProposal {
        string description;            // Human-readable description
        bytes callData;                // ABI encoded function call data for execution
        address target;                // The contract address to call (address(0) for text-only proposals)
        uint256 proposerInfluenceAtCreation; // Influence of proposer at the time of creation
        uint256 startEpoch;            // Epoch when voting begins
        uint256 endEpoch;              // Epoch when voting ends
        uint256 quorumThreshold;       // % of total influence needed for quorum (e.g., 2000 for 20%)
        uint256 approvalThreshold;     // % of 'for' votes out of total non-abstain votes (e.g., 5000 for 50%)
        uint256 forVotes;              // Sum of influence of 'For' voters
        uint256 againstVotes;          // Sum of influence of 'Against' voters
        uint256 abstainVotes;          // Sum of influence of 'Abstain' voters
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        ProposalState state;           // Current state of the proposal
        uint256 totalVotesCastInfluence; // Sum of influence of all voters (For + Against + Abstain)
    }
    mapping(uint256 => GeneralProposal) public generalProposals;
    uint256 public nextGeneralProposalId; // Counter for unique proposal IDs
    uint256 public votingPeriodEpochs; // Duration of voting period in epochs

    // Structure for proposals specifically for changing the treasury allocation algorithm
    struct AlgorithmProposal {
        AllocationAlgorithmType newAlgoType; // The proposed new algorithm type
        bytes newParameters;                 // Proposed parameters for the new algorithm
        string description;                  // Description of the algorithm change
        uint256 proposerInfluenceAtCreation;
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 quorumThreshold;
        uint256 approvalThreshold;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
        uint256 totalVotesCastInfluence;
    }
    mapping(uint256 => AlgorithmProposal) public algorithmProposals;
    uint256 public nextAlgorithmProposalId; // Counter for unique algorithm proposal IDs

    // Epoch Management
    uint256 public currentEpoch;        // Current epoch number
    uint256 public epochStartTime;      // Timestamp when the current epoch began
    uint256 public epochDuration;       // Duration of an epoch in seconds

    // --- Events ---
    event ContributorRegistered(address indexed contributor, uint256 initialStake);
    event StakedForInfluence(address indexed contributor, uint256 amount);
    event UnstakedFromInfluence(address indexed contributor, uint256 amount);
    event InfluenceDecayed(address indexed contributor, uint256 oldInfluence, uint256 newInfluence, uint256 epoch);
    event TreasuryDeposited(address indexed depositor, uint256 amount);
    event FundsDisbursed(address indexed recipient, uint256 amount, AllocationAlgorithmType algoType, uint256 epoch);
    event GeneralProposalSubmitted(uint256 indexed proposalId, address indexed proposer);
    event AlgorithmProposalSubmitted(uint256 indexed proposalId, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint8 voteOption, uint256 influenceUsed);
    event GeneralProposalExecuted(uint256 indexed proposalId);
    event AlgorithmProposalActivated(uint256 indexed proposalId, AllocationAlgorithmType newAlgoType);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 epochStartTimestamp);
    event EmergencyPaused(bool status);
    event EmergencyFundsWithdrawn(address indexed recipient, uint256 amount);
    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue); // For uint256 parameters
    event BytesParameterUpdated(string parameterName); // For bytes parameters where old/new value too complex for event

    // --- Modifiers ---
    modifier onlyContributor() {
        require(isContributor[msg.sender], "AxiomDAO: Not a registered contributor");
        _;
    }

    modifier onlyIfActiveAlgorithm() {
        require(activeAllocationAlgorithm.algoType != AllocationAlgorithmType.NONE, "AxiomDAO: No active allocation algorithm");
        _;
    }

    // This modifier is used for functions that should only be callable by a successful proposal execution.
    // In a real system, this would involve checking `msg.sender` against a specific role or direct internal call
    // from the `executeProposal` function. For this example, we allow the `owner` to call it for testing
    // and initial setup, but its primary intent is for internal DAO governance calls.
    modifier onlyProposedAndExecuted() {
        require(msg.sender == owner() || msg.sender == address(this), "AxiomDAO: Function can only be called by successful proposal execution or owner (for test/init).");
        _;
    }

    // --- Constructor ---
    /**
     * @dev Initializes the AxiomDAO contract, deploys the AXM token, and sets initial parameters.
     * @param _initialOwner The address of the initial owner (often a multi-sig or DAO governance itself).
     */
    constructor(address _initialOwner) Ownable(_initialOwner) {
        AXM = new AxiomToken(_initialOwner); // Deploy AXM token and mint initial supply to owner
        // In a more complex setup, AXM ownership might be transferred to AxiomDAO for minting/burning capabilities by the DAO.
        // AXM.transferOwnership(address(this)); 

        influenceDecayRatePerEpoch = 500; // 5% decay per epoch (500 / 10000)
        minInfluenceToPropose = 10000 * (10**MIN_INFLUENCE_DECIMALS); // 10,000 influence units
        epochDuration = 7 days; // 1 week per epoch
        votingPeriodEpochs = 2; // Proposals vote for 2 epochs

        currentEpoch = 0;
        epochStartTime = block.timestamp; // Set the start time of the first epoch
        activeAllocationAlgorithm.algoType = AllocationAlgorithmType.NONE; // No active algorithm initially

        nextGeneralProposalId = 1;
        nextAlgorithmProposalId = 1;

        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    // --- Internal Helpers ---

    /**
     * @dev Calculates the decayed influence for a contributor based on the current epoch.
     * @param _contributor The address of the contributor.
     * @return The current influence score after applying decay.
     */
    function _calculateDecayedInfluence(address _contributor) internal view returns (uint256) {
        Contributor storage c = contributors[_contributor];
        if (c.rawInfluence == 0) return 0; // No influence if raw is zero

        // Calculate epochs passed since last update
        uint256 epochsPassed = currentEpoch - c.lastInfluenceUpdateEpoch;
        uint256 currentInfluence = c.rawInfluence;

        // Apply decay for each epoch passed
        for (uint256 i = 0; i < epochsPassed; i++) {
            currentInfluence = (currentInfluence * (10000 - influenceDecayRatePerEpoch)) / 10000;
        }
        return currentInfluence;
    }

    /**
     * @dev Updates the raw influence and last update epoch for a contributor.
     * This function should be called when staking/unstaking or during epoch advancement.
     * @param _contributor The address of the contributor.
     * @param _newRawInfluence The new raw influence value.
     */
    function _updateContributorInfluence(address _contributor, uint256 _newRawInfluence) internal {
        Contributor storage c = contributors[_contributor];
        uint256 oldInfluence = c.rawInfluence; // Raw influence before update
        c.rawInfluence = _newRawInfluence;
        c.lastInfluenceUpdateEpoch = currentEpoch; // Set update epoch to current epoch
        emit InfluenceDecayed(_contributor, oldInfluence, c.rawInfluence, currentEpoch);
    }

    /**
     * @dev Checks if a proposal meets quorum and approval thresholds.
     * @param _forVotes The sum of influence for 'For' votes.
     * @param _againstVotes The sum of influence for 'Against' votes.
     * @param _totalInfluenceCast The sum of influence for all votes (For, Against, Abstain).
     * @param _quorumThreshold The percentage (scaled by 10000) of total influence needed for quorum.
     * @param _approvalThreshold The percentage (scaled by 10000) of 'for' votes out of total non-abstain votes.
     * @return bool True if the proposal passed, false otherwise.
     */
    function _checkProposalPass(
        uint256 _forVotes,
        uint256 _againstVotes,
        uint256 _totalInfluenceCast,
        uint256 _quorumThreshold,
        uint256 _approvalThreshold
    ) internal view returns (bool) {
        uint256 totalAvailableInfluence = _calculateTotalActiveInfluence(); // Dynamic total influence based on current state

        // Check quorum: total influence cast must be at least quorumThreshold % of total active influence
        if (_totalInfluenceCast * 10000 < totalAvailableInfluence * _quorumThreshold) {
            return false;
        }

        // Check approval: 'for' votes must be at least approvalThreshold % of 'for' + 'against' votes
        if (_forVotes == 0 && _againstVotes == 0) return false; // No effective votes means it cannot pass
        return (_forVotes * 10000 >= (_forVotes + _againstVotes) * _approvalThreshold);
    }

    /**
     * @dev Calculates the total active influence of all registered contributors.
     * Iterates through `activeContributors` to sum up their decayed influence.
     * Note: For very large `activeContributors` arrays, this can be gas intensive.
     * A more scalable solution might involve a Merkle tree of influences updated off-chain,
     * or a system where influence is only calculated upon request/interaction.
     */
    function _calculateTotalActiveInfluence() internal view returns (uint256 totalInfluence) {
        for (uint256 i = 0; i < activeContributors.length; i++) {
            address contributorAddr = activeContributors[i];
            totalInfluence += _calculateDecayedInfluence(contributorAddr);
        }
    }

    // --- I. Core Token & Influence System (8 functions) ---

    /**
     * @dev Registers a new contributor and stakes initial AXM for influence.
     * @param initialStake The amount of AXM to stake initially.
     */
    function registerContributor(uint256 initialStake) external whenNotPaused nonReentrant {
        require(!isContributor[msg.sender], "AxiomDAO: Already a registered contributor");
        require(initialStake > 0, "AxiomDAO: Initial stake must be greater than zero");
        require(AXM.transferFrom(msg.sender, address(this), initialStake), "AxiomDAO: AXM transfer failed");

        contributors[msg.sender].stakedAmount = initialStake;
        contributors[msg.sender].rawInfluence = initialStake; // Initial influence is linearly tied to stake
        contributors[msg.sender].lastInfluenceUpdateEpoch = currentEpoch;
        isContributor[msg.sender] = true;
        activeContributors.push(msg.sender); // Add to list for iteration (for epoch decay)

        emit ContributorRegistered(msg.sender, initialStake);
    }

    /**
     * @dev Allows an existing contributor to stake more AXM for increased influence.
     * @param amount The amount of AXM to stake.
     */
    function stakeForInfluence(uint256 amount) external onlyContributor whenNotPaused nonReentrant {
        require(amount > 0, "AxiomDAO: Stake amount must be greater than zero");
        require(AXM.transferFrom(msg.sender, address(this), amount), "AxiomDAO: AXM transfer failed");

        // Sync influence for the sender immediately before adding new stake to reflect current decayed value
        syncInfluenceScores(new address[](1), currentEpoch); 
        
        Contributor storage c = contributors[msg.sender];
        c.stakedAmount += amount;
        c.rawInfluence += amount; // Raw influence increases linearly with new stake
        c.lastInfluenceUpdateEpoch = currentEpoch; // Reset decay clock for the contributor's total raw influence
        
        emit StakedForInfluence(msg.sender, amount);
    }

    /**
     * @dev Allows a contributor to unstake AXM.
     * This reduces their staked amount and raw influence. The remaining influence will continue to decay.
     * @param amount The amount of AXM to unstake.
     */
    function unstakeFromInfluence(uint256 amount) external onlyContributor whenNotPaused nonReentrant {
        Contributor storage c = contributors[msg.sender];
        require(amount > 0, "AxiomDAO: Unstake amount must be greater than zero");
        require(c.stakedAmount >= amount, "AxiomDAO: Insufficient staked amount");

        // Sync influence for the sender immediately before unstaking
        syncInfluenceScores(new address[](1), currentEpoch);

        c.stakedAmount -= amount;
        c.rawInfluence -= amount; // Decrease raw influence (could be more complex, e.g., prorated decay of remaining)
        c.lastInfluenceUpdateEpoch = currentEpoch; // Update last epoch for the remaining influence

        require(AXM.transfer(msg.sender, amount), "AxiomDAO: AXM transfer failed");

        // If staked amount becomes 0, the contributor's influence will eventually decay to 0.
        // For simplicity, we don't remove them from `activeContributors` array directly here.
        // A separate cleanup function or a different data structure could optimize this for large numbers of users.
        emit UnstakedFromInfluence(msg.sender, amount);
    }

    /**
     * @dev Returns the current calculated influence score for a contributor, applying decay.
     * @param contributor The address of the contributor.
     * @return The current influence score.
     */
    function getContributorInfluence(address contributor) public view returns (uint256) {
        if (!isContributor[contributor]) return 0;
        return _calculateDecayedInfluence(contributor);
    }

    /**
     * @dev Governance function to update the influence decay rate.
     * Callable only via a successful general proposal.
     * @param newRate The new decay rate (e.g., 500 for 5%, 10000 for 100%).
     */
    function updateInfluenceDecayRate(uint256 newRate) external onlyProposedAndExecuted {
        require(newRate <= 10000, "AxiomDAO: Decay rate cannot exceed 100%"); // 10000 = 100%
        emit ParameterUpdated("influenceDecayRatePerEpoch", influenceDecayRatePerEpoch, newRate);
        influenceDecayRatePerEpoch = newRate;
    }

    /**
     * @dev Triggers influence decay calculation for a batch of contributors.
     * This function helps manage gas costs by allowing partial updates.
     * It's expected to be called by an off-chain bot or keeper service.
     * @param contributorsToSync An array of contributor addresses to sync.
     * @param targetEpoch The epoch for which to sync influence.
     */
    function syncInfluenceScores(address[] calldata contributorsToSync, uint256 targetEpoch) public {
        require(targetEpoch <= currentEpoch, "AxiomDAO: Cannot sync for future epochs");
        for (uint256 i = 0; i < contributorsToSync.length; i++) {
            address contributorAddr = contributorsToSync[i];
            // Only decay if it hasn't been decayed for the target epoch yet and is a registered contributor
            if (isContributor[contributorAddr] && contributors[contributorAddr].lastInfluenceUpdateEpoch < targetEpoch) {
                _updateContributorInfluence(contributorAddr, _calculateDecayedInfluence(contributorAddr));
            }
        }
    }

    /**
     * @dev Returns the total amount of AXM currently staked across all contributors (held by the DAO contract).
     * @return The total staked amount.
     */
    function getTotalStakedAXM() public view returns (uint256) {
        return AXM.balanceOf(address(this));
    }


    // --- II. Treasury & Allocation Algorithms (7 functions) ---

    /**
     * @dev Allows anyone to deposit ETH/WETH into the DAO treasury.
     */
    receive() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    function depositToTreasury() public payable {
        require(msg.value > 0, "AxiomDAO: Deposit amount must be greater than zero");
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Submits a proposal to switch the active treasury allocation algorithm.
     * Only contributors with sufficient influence can propose.
     * @param algorithmType The type of the new allocation algorithm (from `AllocationAlgorithmType` enum).
     * @param parameters ABI-encoded parameters for the new algorithm (e.g., `abi.encode(N, amountPerRecipient)` for LINEAR_DISTRIBUTION).
     * @param description A description of the proposal.
     */
    function submitAllocationAlgorithmProposal(
        AllocationAlgorithmType algorithmType,
        bytes memory parameters,
        string memory description
    ) external onlyContributor whenNotPaused returns (uint256 proposalId) {
        require(algorithmType != AllocationAlgorithmType.NONE, "AxiomDAO: Invalid algorithm type");
        require(getContributorInfluence(msg.sender) >= minInfluenceToPropose, "AxiomDAO: Insufficient influence to propose");

        proposalId = nextAlgorithmProposalId++;
        AlgorithmProposal storage proposal = algorithmProposals[proposalId];
        proposal.newAlgoType = algorithmType;
        proposal.newParameters = parameters;
        proposal.description = description;
        proposal.proposerInfluenceAtCreation = getContributorInfluence(msg.sender);
        proposal.startEpoch = currentEpoch;
        proposal.endEpoch = currentEpoch + votingPeriodEpochs; // Voting lasts for `votingPeriodEpochs`
        proposal.state = ProposalState.Active;
        proposal.quorumThreshold = 1000; // 10% of total active influence
        proposal.approvalThreshold = 5000; // 50% of (For + Against) votes

        emit AlgorithmProposalSubmitted(proposalId, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows a contributor to vote on a treasury allocation algorithm proposal.
     * @param proposalId The ID of the proposal.
     * @param support True for 'For', False for 'Against'. Abstain votes not directly supported here, but could be added.
     */
    function voteOnAlgorithmProposal(uint256 proposalId, bool support) external onlyContributor whenNotPaused {
        AlgorithmProposal storage proposal = algorithmProposals[proposalId];
        require(proposal.state == ProposalState.Active, "AxiomDAO: Proposal is not active");
        require(currentEpoch <= proposal.endEpoch, "AxiomDAO: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AxiomDAO: Already voted on this proposal");

        uint256 voterInfluence = getContributorInfluence(msg.sender);
        require(voterInfluence > 0, "AxiomDAO: Voter has no influence");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalVotesCastInfluence += voterInfluence;

        if (support) {
            proposal.forVotes += voterInfluence;
            emit ProposalVoted(proposalId, msg.sender, uint8(VoteOption.For), voterInfluence);
        } else {
            proposal.againstVotes += voterInfluence;
            emit ProposalVoted(proposalId, msg.sender, uint8(VoteOption.Against), voterInfluence);
        }
    }

    /**
     * @dev Activates a successfully voted treasury allocation algorithm proposal.
     * Can only be called after the voting period ends and if the proposal succeeded.
     * @param proposalId The ID of the proposal to activate.
     */
    function activateAllocationAlgorithm(uint256 proposalId) external whenNotPaused nonReentrant {
        AlgorithmProposal storage proposal = algorithmProposals[proposalId];
        require(proposal.state != ProposalState.Executed, "AxiomDAO: Proposal already executed");
        require(currentEpoch > proposal.endEpoch, "AxiomDAO: Voting period not yet ended");

        if (_checkProposalPass(
            proposal.forVotes,
            proposal.againstVotes,
            proposal.totalVotesCastInfluence,
            proposal.quorumThreshold,
            proposal.approvalThreshold
        )) {
            activeAllocationAlgorithm.algoType = proposal.newAlgoType;
            activeAllocationAlgorithm.parameters = proposal.newParameters;
            activeAllocationAlgorithm.lastRunEpoch = currentEpoch; // Reset last run for the new algorithm
            proposal.state = ProposalState.Executed;
            emit AlgorithmProposalActivated(proposalId, proposal.newAlgoType);
        } else {
            proposal.state = ProposalState.Failed;
            revert("AxiomDAO: Proposal failed to pass quorum or approval thresholds");
        }
    }

    /**
     * @dev Executes a disbursement cycle based on the currently active allocation algorithm.
     * Can be called by anyone (or by an automated bot/keeper) if `currentEpoch` is past `lastRunEpoch`.
     * The logic for each algorithm type is embedded here.
     * Note: The sorting for LINEAR_DISTRIBUTION is simplistic and could be very gas-expensive
     * for a large number of active contributors. Real-world solutions might use off-chain sorting
     * and on-chain verification (e.g., Merkle proof) or more gas-efficient data structures/methods.
     */
    function executeCurrentAllocationAlgorithmRun() external onlyIfActiveAlgorithm whenNotPaused nonReentrant {
        require(currentEpoch > activeAllocationAlgorithm.lastRunEpoch, "AxiomDAO: Allocation already run for this epoch");
        
        uint256 treasuryBalance = address(this).balance;
        require(treasuryBalance > 0, "AxiomDAO: Treasury is empty");

        if (activeAllocationAlgorithm.algoType == AllocationAlgorithmType.LINEAR_DISTRIBUTION) {
            // Expected parameters: (uint256 numRecipients, uint256 amountPerRecipient)
            (uint256 numRecipients, uint256 amountPerRecipient) = abi.decode(activeAllocationAlgorithm.parameters, (uint256, uint256));
            require(numRecipients > 0 && amountPerRecipient > 0, "AxiomDAO: Invalid LINEAR_DISTRIBUTION parameters");
            require(treasuryBalance >= numRecipients * amountPerRecipient, "AxiomDAO: Insufficient treasury balance for linear distribution");

            // Simple "bubble-sort" for top contributors by influence for demonstration.
            // This is HIGHLY INNEFFICIENT for many contributors (O(n^2)).
            // For production, consider using a limited list or off-chain sorting with proof.
            address[] memory topContributors = new address[](numRecipients);
            uint224[] memory topInfluences = new uint224[](numRecipients); // uint224 for safety, should fit influence

            // Populate initial top list with a placeholder to avoid issues with empty slots
            for (uint256 i = 0; i < numRecipients; i++) {
                topInfluences[i] = 0;
            }

            for (uint256 i = 0; i < activeContributors.length; i++) {
                address current = activeContributors[i];
                uint256 currentInf = getContributorInfluence(current);

                if (currentInf == 0) continue; // Skip contributors with no influence

                for (uint256 j = 0; j < numRecipients; j++) {
                    if (currentInf > topInfluences[j]) {
                        // Shift elements to make space for the new top contributor
                        for (uint256 k = numRecipients - 1; k > j; k--) {
                            topInfluences[k] = topInfluences[k-1];
                            topContributors[k] = topContributors[k-1];
                        }
                        topInfluences[j] = uint224(currentInf); // Cast to uint224
                        topContributors[j] = current;
                        break;
                    }
                }
            }

            for (uint256 i = 0; i < numRecipients; i++) {
                if (topContributors[i] != address(0)) { // Ensure it's a valid contributor found
                    (bool success, ) = topContributors[i].call{value: amountPerRecipient}("");
                    require(success, "AxiomDAO: Failed to disburse funds (LINEAR)");
                    emit FundsDisbursed(topContributors[i], amountPerRecipient, AllocationAlgorithmType.LINEAR_DISTRIBUTION, currentEpoch);
                }
            }
        } else if (activeAllocationAlgorithm.algoType == AllocationAlgorithmType.STAKED_PROPORTIONAL) {
            // Expected parameters: (uint256 distributionPercentage) (e.g., 1000 for 10%)
            (uint256 distributionPercentage) = abi.decode(activeAllocationAlgorithm.parameters, (uint256));
            require(distributionPercentage > 0 && distributionPercentage <= 10000, "AxiomDAO: Invalid STAKED_PROPORTIONAL percentage");

            uint256 totalPoolToDistribute = (treasuryBalance * distributionPercentage) / 10000;
            uint256 totalInfluence = _calculateTotalActiveInfluence();

            require(totalInfluence > 0, "AxiomDAO: No active influence for proportional distribution");

            for (uint256 i = 0; i < activeContributors.length; i++) {
                address contributorAddr = activeContributors[i];
                uint256 contributorInfluence = getContributorInfluence(contributorAddr);
                if (contributorInfluence > 0) {
                    uint256 share = (totalPoolToDistribute * contributorInfluence) / totalInfluence;
                    if (share > 0) {
                        (bool success, ) = contributorAddr.call{value: share}("");
                        require(success, "AxiomDAO: Failed to disburse funds (PROPORTIONAL)");
                        emit FundsDisbursed(contributorAddr, share, AllocationAlgorithmType.STAKED_PROPORTIONAL, currentEpoch);
                    }
                }
            }
        } else {
            revert("AxiomDAO: Unknown or unimplemented allocation algorithm");
        }
        activeAllocationAlgorithm.lastRunEpoch = currentEpoch; // Mark algorithm as run for this epoch
    }


    /**
     * @dev Returns the type and parameters of the currently active allocation algorithm.
     * @return The algorithm type and its parameters.
     */
    function getCurrentAllocationAlgorithmParameters() public view returns (AllocationAlgorithmType, bytes memory) {
        return (activeAllocationAlgorithm.algoType, activeAllocationAlgorithm.parameters);
    }

    /**
     * @dev Allows for minor parameter tweaks to the *active* allocation algorithm via a general proposal.
     * This function itself is executable by a successful `GeneralProposal`.
     * @param newParameters ABI-encoded new parameters for the active algorithm.
     */
    function updateActiveAlgorithmParameters(bytes memory newParameters) external onlyProposedAndExecuted {
        require(activeAllocationAlgorithm.algoType != AllocationAlgorithmType.NONE, "AxiomDAO: No active algorithm to update");
        activeAllocationAlgorithm.parameters = newParameters;
        emit BytesParameterUpdated("activeAllocationAlgorithmParameters"); // Emit event for byte array updates
    }

    // --- III. Governance & Proposals (5 functions) ---

    /**
     * @dev Submits a general proposal for DAO operations (e.g., calling other contracts, updating parameters) or text-based decisions.
     * @param description A description of the proposal.
     * @param callData The ABI encoded function call data for execution (if target is not address(0)).
     * @param target The address of the contract to call if this is an executable proposal (address(0) for text-only).
     */
    function submitGeneralProposal(
        string memory description,
        bytes memory callData,
        address target
    ) external onlyContributor whenNotPaused returns (uint256 proposalId) {
        require(getContributorInfluence(msg.sender) >= minInfluenceToPropose, "AxiomDAO: Insufficient influence to propose");

        proposalId = nextGeneralProposalId++;
        GeneralProposal storage proposal = generalProposals[proposalId];
        proposal.description = description;
        proposal.callData = callData;
        proposal.target = target;
        proposal.proposerInfluenceAtCreation = getContributorInfluence(msg.sender);
        proposal.startEpoch = currentEpoch;
        proposal.endEpoch = currentEpoch + votingPeriodEpochs; // Voting lasts for `votingPeriodEpochs`
        proposal.state = ProposalState.Active;
        proposal.quorumThreshold = 1000; // 10% of total active influence
        proposal.approvalThreshold = 5000; // 50% of (For + Against) votes

        emit GeneralProposalSubmitted(proposalId, msg.sender);
        return proposalId;
    }

    /**
     * @dev Allows a contributor to vote on any general proposal.
     * @param proposalId The ID of the proposal.
     * @param voteOption The chosen vote option (VoteOption.For, VoteOption.Against, VoteOption.Abstain).
     */
    function voteOnProposal(uint256 proposalId, uint8 voteOption) external onlyContributor whenNotPaused {
        GeneralProposal storage proposal = generalProposals[proposalId];
        require(proposal.state == ProposalState.Active, "AxiomDAO: Proposal is not active");
        require(currentEpoch <= proposal.endEpoch, "AxiomDAO: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "AxiomDAO: Already voted on this proposal");
        require(voteOption <= uint8(VoteOption.Abstain), "AxiomDAO: Invalid vote option");

        uint256 voterInfluence = getContributorInfluence(msg.sender);
        require(voterInfluence > 0, "AxiomDAO: Voter has no influence");

        proposal.hasVoted[msg.sender] = true;
        proposal.totalVotesCastInfluence += voterInfluence;

        if (voteOption == uint8(VoteOption.For)) {
            proposal.forVotes += voterInfluence;
        } else if (voteOption == uint8(VoteOption.Against)) {
            proposal.againstVotes += voterInfluence;
        } else if (voteOption == uint8(VoteOption.Abstain)) {
            proposal.abstainVotes += voterInfluence;
        }

        emit ProposalVoted(proposalId, msg.sender, voteOption, voterInfluence);
    }

    /**
     * @dev Executes a successfully voted general proposal.
     * Can only be called after the voting period ends and if the proposal succeeded.
     * This function performs the `callData` on the `target` address if specified.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused nonReentrant {
        GeneralProposal storage proposal = generalProposals[proposalId];
        require(proposal.state == ProposalState.Active, "AxiomDAO: Proposal is not active");
        require(currentEpoch > proposal.endEpoch, "AxiomDAO: Voting period not yet ended");

        if (_checkProposalPass(
            proposal.forVotes,
            proposal.againstVotes,
            proposal.totalVotesCastInfluence,
            proposal.quorumThreshold,
            proposal.approvalThreshold
        )) {
            proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution attempt
            if (proposal.target != address(0) && proposal.callData.length > 0) {
                // Execute the call to the target contract
                // Using low-level call allows interaction with any contract/function.
                // Critical for upgradeability or calling other DAO-controlled contracts.
                (bool success, ) = proposal.target.call(proposal.callData);
                require(success, "AxiomDAO: Proposal execution failed");
            }
            proposal.state = ProposalState.Executed; // Mark as executed after successful call (if applicable)
            emit GeneralProposalExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Failed;
            revert("AxiomDAO: Proposal failed to pass quorum or approval thresholds");
        }
    }

    /**
     * @dev Returns the current state of a general proposal.
     * Updates the state from Active to Succeeded/Failed if voting period has ended.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal.
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        GeneralProposal storage proposal = generalProposals[proposalId];
        // If still active but voting period ended, calculate final state
        if (proposal.state == ProposalState.Active && currentEpoch > proposal.endEpoch) {
            if (_checkProposalPass(
                proposal.forVotes,
                proposal.forVotes, // Use forVotes again here to represent total votes for approval threshold calculation
                proposal.totalVotesCastInfluence,
                proposal.quorumThreshold,
                proposal.approvalThreshold
            )) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Failed;
            }
        }
        return proposal.state;
    }

    /**
     * @dev Returns the vote breakdown for a given general proposal.
     * @param proposalId The ID of the proposal.
     * @return forVotes, againstVotes, abstainVotes, totalVotesCastInfluence
     */
    function getVoteCountForProposal(uint256 proposalId)
        public
        view
        returns (uint256 forVotes, uint256 againstVotes, uint256 abstainVotes, uint256 totalVotesCastInfluence)
    {
        GeneralProposal storage proposal = generalProposals[proposalId];
        return (proposal.forVotes, proposal.againstVotes, proposal.abstainVotes, proposal.totalVotesCastInfluence);
    }


    // --- IV. Epoch & System Management (3 functions) ---

    /**
     * @dev Advances the current epoch.
     * This function can be called by anyone but only processes if enough time has passed since the last epoch start.
     * It triggers influence decay for all active contributors (which can be gas-heavy, see `syncInfluenceScores`).
     */
    function advanceEpoch() external nonReentrant {
        require(block.timestamp >= epochStartTime + epochDuration, "AxiomDAO: Epoch duration not yet passed");

        currentEpoch++;
        epochStartTime = block.timestamp;

        // Trigger influence decay for all currently active contributors.
        // This could be very gas expensive if activeContributors is large.
        // In a real dApp, this might be handled by an off-chain bot calling `syncInfluenceScores` in batches,
        // or a more sophisticated system where decay is only applied on interaction.
        syncInfluenceScores(activeContributors, currentEpoch);

        emit EpochAdvanced(currentEpoch, epochStartTime);
    }

    /**
     * @dev Returns data about the current epoch.
     * @return epochNumber The current epoch number.
     * @return epochStartTimestamp The timestamp when the current epoch began.
     * @return epochEndTimestamp The timestamp when the current epoch is expected to end.
     */
    function getCurrentEpochData() public view returns (uint256 epochNumber, uint256 epochStartTimestamp, uint256 epochEndTimestamp) {
        return (currentEpoch, epochStartTime, epochStartTime + epochDuration);
    }

    /**
     * @dev Governance function to adjust the length of an epoch.
     * Callable only via a successful general proposal.
     * @param newDuration The new duration of an epoch in seconds.
     */
    function setEpochDuration(uint256 newDuration) external onlyProposedAndExecuted {
        require(newDuration > 0, "AxiomDAO: Epoch duration must be greater than zero");
        emit ParameterUpdated("epochDuration", epochDuration, newDuration);
        epochDuration = newDuration;
    }


    // --- V. Emergency & Configuration (4 functions) ---

    /**
     * @dev Pauses/Unpauses the contract in case of an emergency. Only callable by the owner (initial admin).
     * This allows stopping critical functions to prevent damage during exploits or bugs.
     * @param _paused True to pause, false to unpause.
     */
    function setEmergencyPause(bool _paused) external onlyOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
        emit EmergencyPaused(_paused);
    }

    /**
     * @dev Allows the owner to withdraw funds from the treasury in an emergency.
     * This function should be guarded by very strict multi-sig/DAO guardrails in a production system.
     * For this example, it's owner-only but imagine it requires a 3-of-5 multi-sig.
     * @param recipient The address to send funds to.
     * @param amount The amount of ETH/WETH to withdraw.
     */
    function withdrawEmergencyFunds(address recipient, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "AxiomDAO: Insufficient treasury balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "AxiomDAO: Emergency withdrawal failed");
        emit EmergencyFundsWithdrawn(recipient, amount);
    }

    /**
     * @dev Governance function to set the minimum influence required to submit a proposal.
     * Callable only via a successful general proposal.
     * @param minInfluence The new minimum influence required (in influence units).
     */
    function setMinimumInfluenceToPropose(uint256 minInfluence) external onlyProposedAndExecuted {
        emit ParameterUpdated("minInfluenceToPropose", minInfluenceToPropose, minInfluence);
        minInfluenceToPropose = minInfluence;
    }

    /**
     * @dev Governance function to set the duration of the voting period for proposals in epochs.
     * Callable only via a successful general proposal.
     * @param duration The new duration in epochs.
     */
    function setVotingPeriodDuration(uint256 duration) external onlyProposedAndExecuted {
        require(duration > 0, "AxiomDAO: Voting period must be greater than zero");
        emit ParameterUpdated("votingPeriodEpochs", votingPeriodEpochs, duration);
        votingPeriodEpochs = duration;
    }
    
    // --- Additional/Utility Functions ---

    /**
     * @dev Returns the current balance of the DAO treasury (ETH/WETH).
     * @return The treasury balance in wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
```