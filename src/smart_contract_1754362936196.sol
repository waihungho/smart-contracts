This smart contract, **Decentralized Autonomous Research & Development Lab (DARD)**, introduces a novel ecosystem for decentralized research funding, execution, and intellectual property management. It goes beyond typical bounty systems by focusing on "Insight-Driven Bounties," leveraging "IP-NFTs" for verifiable intellectual property, and implementing a powerful "Synapse" mechanism that allows validated research outcomes to trigger actions in other smart contracts.

---

## Contract Outline

**I. Contract Setup & Ownership**
    - `constructor`: Initializes the DARD contract, sets up the associated IP-NFT contract, and designates the protocol fee recipient.
**II. Research Domain Management**
    - `addResearchDomain`: Defines new categories for research bounties.
    - `removeResearchDomain`: Deactivates a research domain.
**III. Researcher & Evaluator Management**
    - `setResearcherRegistryStatus`: Owner manages who can submit research.
    - `setEvaluatorRegistryStatus`: Owner manages who can evaluate research.
**IV. Insight Bounty Lifecycle**
    - `proposeInsightBounty`: Initiates a new research challenge.
    - `fundInsightBounty`: Contributors deposit funds into a bounty.
    - `cancelInsightBounty`: Allows the proposer (or owner) to cancel a bounty under specific conditions.
    - `reclaimUnusedFunds`: Enables funders to retrieve their contributions from canceled or expired bounties.
**V. Insight Submission & Evaluation**
    - `submitInsight`: Researchers submit their findings (e.g., IPFS hash to detailed reports).
    - `evaluateInsight`: Registered evaluators score submitted insights.
    - `finalizeBountyEvaluation`: Automates the process of determining the winning insight after the evaluation period.
**VI. Reward Distribution & Staking**
    - `distributeBountyRewards`: Pays out the bounty to the winning researcher and collects protocol fees.
    - `withdrawStakedFunds`: Allows non-winning researchers to reclaim their optional staked tokens.
**VII. Intellectual Property (IP-NFT) Management**
    - `mintIpNftForInsight`: Mints a non-fungible token (IP-NFT) representing the intellectual property of a validated winning insight.
    - `setIpNftRoyalties`: Sets a royalty percentage for the IP-NFT for future secondary sales.
**VIII. Knowledge Graph & Dynamic Parameters**
    - `linkInsightDependencies`: Allows insights to declare dependencies on previous winning insights, building an on-chain knowledge graph.
**IX. Synapse - External Contract Interaction**
    - `triggerSynapseAction`: A powerful function that allows a winning insight from a specifically marked bounty to trigger a predefined action in another smart contract.
**X. Protocol Fees & Fund Management**
    - `setProtocolFee`: Adjusts the percentage of funds collected by the DARD protocol.
    - `withdrawProtocolFees`: Enables the owner to withdraw accumulated protocol fees.
**XI. View Functions**
    - `getBountyDetails`: Retrieves detailed information about a specific bounty.
    - `getInsightSubmissionDetails`: Fetches details of a particular insight submission.
    - `getResearcherStatus`: Checks if an address is a registered researcher.
    - `getEvaluatorStatus`: Checks if an address is a registered evaluator.
    - `getDomainDetails`: Provides information about a research domain.
    - `getIpNftTokenId`: Gets the IP-NFT token ID for a given insight ID.
    - `getIpNftRoyalties`: Retrieves the royalty percentage for an IP-NFT.

---

## Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interface for contracts that can be targeted by Synapse actions.
interface ISynapseTarget {
    /**
     * @dev A function signature for external contracts to implement if they wish to receive
     *      Synapse triggers from the DARD contract.
     * @param insightId The ID of the winning insight that triggered this action.
     * @param contextData Any additional data relevant to the trigger, encoded as bytes.
     */
    function receiveSynapseTrigger(uint256 insightId, bytes memory contextData) external;
}

/**
 * @title Decentralized Autonomous Research & Development Lab (DARD)
 * @dev A novel smart contract platform for funding, managing, and rewarding decentralized research initiatives.
 *      It introduces "Insight-Driven Bounties," "IP-NFTs for intellectual property,"
 *      and a powerful "Synapse" mechanism to trigger external contract interactions
 *      based on validated research outcomes.
 */
contract DARD is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables & Data Structures ---

    Counters.Counter private _bountyIds;
    Counters.Counter private _submissionIds;
    Counters.Counter private _domainIds;
    Counters.Counter private _ipNftTokenIds; // For ERC-721 token IDs

    // Configuration parameters
    uint256 public evaluationQuorum = 3; // Minimum evaluators required for a bounty to be finalized
    uint256 public insightSubmissionPeriod = 7 days; // Default submission period (7 days)
    uint256 public evaluationPeriod = 3 days;        // Default evaluation period (3 days)
    uint256 public protocolFeePermille = 50; // 50 permille = 5% fee (e.g., 50/1000)
    address public protocolFeeRecipient;     // Address to receive protocol fees

    // Registries for researchers and evaluators (managed by owner)
    mapping(address => bool) public isResearcher;
    mapping(address => bool) public isEvaluator;

    // Research Domain Structure
    struct ResearchDomain {
        uint256 id;
        string name;
        bool isActive;
    }
    mapping(uint256 => ResearchDomain) public researchDomains;
    mapping(string => uint256) private _domainNameToId; // For quick lookup by name

    // Bounty Status Enum
    enum BountyStatus {
        Proposed,       // Just created, awaiting funding
        Funded,         // Funded, open for submissions (or in progress if submissions started)
        InProgress,     // Submission period active
        Evaluating,     // Submissions closed, open for evaluation
        Completed,      // Evaluation finalized, rewards distributed
        Canceled,       // Canceled by proposer or owner
        Expired         // No winner or action within timeframe
    }

    // Insight Bounty Structure
    struct InsightBounty {
        uint256 id;
        address proposer;
        uint256 domainId;
        string description;
        uint256 targetFunding;
        uint256 currentFunding;
        address fundingToken; // ERC20 token address used for funding
        BountyStatus status;
        uint256 submissionPeriodEnd; // Timestamp when submission period ends
        uint256 evaluationPeriodEnd; // Timestamp when evaluation period ends
        uint256 winningInsightId;    // ID of the winning submission
        bool requiresSynapseTrigger; // True if a winning insight can enable a Synapse action
        bool synapseTriggered;       // True if the Synapse action for this bounty has been executed
        uint256 totalEvaluatorVotes; // Number of unique evaluators who have scored submissions for this bounty
        uint256 totalEvaluatorScore; // Sum of scores from evaluators (across all submissions for this bounty)
        mapping(address => bool) hasEvaluated; // Tracks which evaluators have voted for this bounty
        mapping(address => uint256) funderAmounts; // Tracks individual funder contributions
    }
    mapping(uint256 => InsightBounty) public insightBounties;
    mapping(uint256 => uint256[]) public bountySubmissions; // bountyId => array of submission IDs for that bounty

    // Insight Submission Structure
    struct InsightSubmission {
        uint256 id;
        uint256 bountyId;
        address researcher;
        string ipfsHash; // IPFS hash pointing to the research findings (e.g., report, model)
        uint256 submissionTime;
        uint256 totalScore;     // Aggregated score from evaluators for this specific submission
        uint256 numEvaluations; // Number of evaluators who scored this specific submission
        uint256 stakedAmount;   // Tokens staked by the researcher for this submission
        bool isAccepted;        // True if this is the winning insight
    }
    mapping(uint256 => InsightSubmission) public insightSubmissions;
    mapping(uint256 => uint256[]) public insightDependencies; // insightId => array of parent insight IDs (for knowledge graph)

    // IP-NFT related structs/mappings
    DARD_IP_NFT public ipNftContract; // Instance of the IP-NFT ERC721 contract
    mapping(uint256 => uint256) public insightToIpNftTokenId; // insightId => IP-NFT tokenId
    mapping(uint256 => uint96) public ipNftRoyaltiesPermille; // IP-NFT tokenId => royalty percentage (permille)

    // Event Declarations
    event ResearchDomainAdded(uint256 indexed domainId, string name);
    event ResearchDomainRemoved(uint256 indexed domainId);
    event ResearcherStatusUpdated(address indexed researcher, bool status);
    event EvaluatorStatusUpdated(address indexed evaluator, bool status);
    event InsightBountyProposed(uint256 indexed bountyId, address indexed proposer, uint256 domainId, uint256 targetFunding, address fundingToken);
    event InsightBountyFunded(uint256 indexed bountyId, address indexed funder, uint256 amount);
    event InsightBountyStatusUpdated(uint256 indexed bountyId, BountyStatus newStatus);
    event InsightSubmissionMade(uint256 indexed submissionId, uint256 indexed bountyId, address indexed researcher, string ipfsHash);
    event InsightEvaluated(uint256 indexed bountyId, uint256 indexed submissionId, address indexed evaluator, uint256 score);
    event BountyEvaluationFinalized(uint256 indexed bountyId, uint256 winningInsightId, uint256 winningScore);
    event BountyRewardsDistributed(uint256 indexed bountyId, uint256 winningInsightId, uint256 researcherReward, uint256 evaluatorsReward);
    event IpNftMinted(uint256 indexed insightId, uint256 indexed tokenId, address indexed owner);
    event IpNftRoyaltiesSet(uint256 indexed tokenId, uint96 royaltyPermille);
    event InsightDependenciesLinked(uint256 indexed insightId, uint256[] parentInsightIds);
    event SynapseActionTriggered(uint256 indexed bountyId, uint256 indexed insightId, address indexed targetContract, bytes callData);
    event FundsReclaimed(uint256 indexed bountyId, address indexed funder, uint256 amount);
    event StakedFundsWithdrawn(uint256 indexed submissionId, address indexed researcher, uint256 amount);
    event ProtocolFeeWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event ParameterUpdated(string paramName, uint256 oldValue, uint256 newValue);


    // --- Modifiers ---
    modifier onlyResearcher() {
        require(isResearcher[msg.sender], "DARD: Caller is not a registered researcher");
        _;
    }

    modifier onlyEvaluator() {
        require(isEvaluator[msg.sender], "DARD: Caller is not a registered evaluator");
        _;
    }

    // --- I. Contract Setup & Ownership ---
    /**
     * @dev Constructor to initialize the DARD contract.
     * @param _name The name for the ERC-721 IP-NFT contract.
     * @param _symbol The symbol for the ERC-721 IP-NFT contract.
     * @param _protocolFeeRecipient The address where protocol fees will be sent.
     */
    constructor(string memory _name, string memory _symbol, address _protocolFeeRecipient) Ownable(msg.sender) {
        ipNftContract = new DARD_IP_NFT(_name, _symbol, address(this)); // DARD contract is the minter
        protocolFeeRecipient = _protocolFeeRecipient;
        require(protocolFeeRecipient != address(0), "DARD: Fee recipient cannot be zero address");
    }

    // --- II. Research Domain Management ---
    /**
     * @dev Adds a new research domain. Only callable by the owner.
     * @param _name The name of the new research domain.
     */
    function addResearchDomain(string memory _name) external onlyOwner {
        require(_domainNameToId[_name] == 0, "DARD: Domain with this name already exists");
        _domainIds.increment();
        uint256 newId = _domainIds.current();
        researchDomains[newId] = ResearchDomain(newId, _name, true);
        _domainNameToId[_name] = newId;
        emit ResearchDomainAdded(newId, _name);
    }

    /**
     * @dev Deactivates an existing research domain. Only callable by the owner.
     *      Active bounties in this domain will continue, but no new bounties can be proposed for it.
     * @param _domainId The ID of the research domain to remove.
     */
    function removeResearchDomain(uint256 _domainId) external onlyOwner {
        require(researchDomains[_domainId].isActive, "DARD: Domain is already inactive or does not exist");
        researchDomains[_domainId].isActive = false;
        emit ResearchDomainRemoved(_domainId);
    }

    // --- III. Researcher & Evaluator Management ---
    /**
     * @dev Sets the registration status of a researcher. Only callable by the owner.
     *      This provides a centralized way to onboard/offboard qualified individuals.
     * @param _researcher The address of the researcher.
     * @param _status True to register, false to deregister.
     */
    function setResearcherRegistryStatus(address _researcher, bool _status) external onlyOwner {
        require(_researcher != address(0), "DARD: Zero address invalid");
        isResearcher[_researcher] = _status;
        emit ResearcherStatusUpdated(_researcher, _status);
    }

    /**
     * @dev Sets the registration status of an evaluator. Only callable by the owner.
     * @param _evaluator The address of the evaluator.
     * @param _status True to add, false to remove.
     */
    function setEvaluatorRegistryStatus(address _evaluator, bool _status) external onlyOwner {
        require(_evaluator != address(0), "DARD: Zero address invalid");
        isEvaluator[_evaluator] = _status;
        emit EvaluatorStatusUpdated(_evaluator, _status);
    }

    // --- IV. Insight Bounty Lifecycle ---
    /**
     * @dev Proposes a new research bounty. The bounty starts in 'Proposed' state.
     *      It requires target funding in a specified ERC-20 token.
     * @param _domainId The ID of the research domain for this bounty.
     * @param _description A description of the research bounty.
     * @param _targetFunding The target amount of funding required for the bounty.
     * @param _requiresSynapseTrigger If true, a winning insight can enable a Synapse action via the owner.
     * @param _fundingToken The ERC-20 token address used to fund this bounty.
     */
    function proposeInsightBounty(
        uint256 _domainId,
        string memory _description,
        uint256 _targetFunding,
        bool _requiresSynapseTrigger,
        address _fundingToken
    ) external {
        require(researchDomains[_domainId].isActive, "DARD: Invalid or inactive domain");
        require(_targetFunding > 0, "DARD: Target funding must be greater than zero");
        require(_fundingToken != address(0), "DARD: Funding token cannot be zero address");

        _bountyIds.increment();
        uint256 newId = _bountyIds.current();

        insightBounties[newId] = InsightBounty({
            id: newId,
            proposer: msg.sender,
            domainId: _domainId,
            description: _description,
            targetFunding: _targetFunding,
            currentFunding: 0,
            fundingToken: _fundingToken,
            status: BountyStatus.Proposed,
            submissionPeriodEnd: 0, // Set once funded
            evaluationPeriodEnd: 0, // Set once submissions closed
            winningInsightId: 0,
            requiresSynapseTrigger: _requiresSynapseTrigger,
            synapseTriggered: false,
            totalEvaluatorVotes: 0,
            totalEvaluatorScore: 0
        });
        emit InsightBountyProposed(newId, msg.sender, _domainId, _targetFunding, _fundingToken);
    }

    /**
     * @dev Funds an existing insight bounty. Tokens are transferred from msg.sender to this contract.
     *      When fully funded, the bounty transitions to 'Funded' status and the submission period starts.
     * @param _bountyId The ID of the bounty to fund.
     * @param _amount The amount of tokens to fund.
     */
    function fundInsightBounty(uint256 _bountyId, uint256 _amount) external nonReentrant {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.status == BountyStatus.Proposed || bounty.status == BountyStatus.Funded, "DARD: Bounty is not in a fundable state");
        require(_amount > 0, "DARD: Amount must be greater than zero");
        require(bounty.fundingToken != address(0), "DARD: Funding token not set for bounty");

        IERC20 token = IERC20(bounty.fundingToken);
        require(token.transferFrom(msg.sender, address(this), _amount), "DARD: Token transfer failed");

        bounty.currentFunding += _amount;
        bounty.funderAmounts[msg.sender] += _amount;

        if (bounty.currentFunding >= bounty.targetFunding && bounty.status == BountyStatus.Proposed) {
            bounty.status = BountyStatus.Funded;
            bounty.submissionPeriodEnd = block.timestamp + insightSubmissionPeriod;
            emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Funded);
        }
        emit InsightBountyFunded(_bountyId, msg.sender, _amount);
    }

    /**
     * @dev Allows the bounty proposer or contract owner to cancel a bounty.
     *      Can only be canceled if:
     *      1. Still in 'Proposed' state (not fully funded).
     *      2. In 'Funded' state, but no submissions yet, and submission period has not ended.
     *      3. In 'Evaluating' state, evaluation period has ended, and no winner was determined.
     * @param _bountyId The ID of the bounty to cancel.
     */
    function cancelInsightBounty(uint256 _bountyId) external {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.proposer == msg.sender || owner() == msg.sender, "DARD: Only proposer or owner can cancel bounty");
        require(bounty.status != BountyStatus.Completed && bounty.status != BountyStatus.Canceled, "DARD: Bounty cannot be canceled in its current state");

        bool canCancel = (bounty.status == BountyStatus.Proposed) ||
                         (bounty.status == BountyStatus.Funded && bountySubmissions[_bountyId].length == 0) ||
                         (bounty.status == BountyStatus.InProgress && bountySubmissions[_bountyId].length == 0) ||
                         (bounty.status == BountyStatus.Evaluating && block.timestamp > bounty.evaluationPeriodEnd && bounty.winningInsightId == 0);

        require(canCancel, "DARD: Bounty cannot be canceled at this time");

        bounty.status = BountyStatus.Canceled;
        emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Canceled);
    }

    /**
     * @dev Allows funders to reclaim their deposited funds if a bounty is canceled or expired without a winner.
     * @param _bountyId The ID of the bounty from which to reclaim funds.
     */
    function reclaimUnusedFunds(uint256 _bountyId) external nonReentrant {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.status == BountyStatus.Canceled ||
                (bounty.status == BountyStatus.Expired && bounty.winningInsightId == 0),
                "DARD: Bounty is not in a state for fund reclamation");
        
        uint256 amountToReclaim = bounty.funderAmounts[msg.sender];
        require(amountToReclaim > 0, "DARD: No funds to reclaim for this bounty");

        bounty.funderAmounts[msg.sender] = 0; // Clear the amount to prevent double reclamation

        IERC20 token = IERC20(bounty.fundingToken);
        require(token.transfer(msg.sender, amountToReclaim), "DARD: Token transfer failed during reclaim");

        bounty.currentFunding -= amountToReclaim; // Adjust current funding to reflect reclaimed amount
        emit FundsReclaimed(_bountyId, msg.sender, amountToReclaim);
    }

    // --- V. Insight Submission & Evaluation ---
    /**
     * @dev A registered researcher submits their findings for a bounty.
     *      Optionally, the researcher can stake tokens to signal confidence in their submission.
     * @param _bountyId The ID of the bounty.
     * @param _ipfsHash IPFS hash pointing to the detailed research findings (e.g., Qm...).
     * @param _stakedAmount Optional amount of the bounty's funding token to stake.
     */
    function submitInsight(uint256 _bountyId, string memory _ipfsHash, uint256 _stakedAmount) external onlyResearcher nonReentrant {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.status == BountyStatus.Funded || bounty.status == BountyStatus.InProgress, "DARD: Bounty is not open for submissions");
        require(block.timestamp <= bounty.submissionPeriodEnd, "DARD: Submission period has ended");
        require(bytes(_ipfsHash).length > 0, "DARD: IPFS hash cannot be empty");

        _submissionIds.increment();
        uint256 newId = _submissionIds.current();

        if (_stakedAmount > 0) {
            IERC20 token = IERC20(bounty.fundingToken);
            require(token.transferFrom(msg.sender, address(this), _stakedAmount), "DARD: Staking token transfer failed. Check allowance.");
        }

        insightSubmissions[newId] = InsightSubmission({
            id: newId,
            bountyId: _bountyId,
            researcher: msg.sender,
            ipfsHash: _ipfsHash,
            submissionTime: block.timestamp,
            totalScore: 0,
            numEvaluations: 0,
            stakedAmount: _stakedAmount,
            isAccepted: false
        });

        bountySubmissions[_bountyId].push(newId);

        // Transition bounty status if it's the first submission
        if (bounty.status == BountyStatus.Funded) {
             bounty.status = BountyStatus.InProgress;
             emit InsightBountyStatusUpdated(_bountyId, BountyStatus.InProgress);
        }

        emit InsightSubmissionMade(newId, _bountyId, msg.sender, _ipfsHash);
    }

    /**
     * @dev A registered evaluator scores a submitted insight for a bounty.
     *      Each evaluator can only score a specific bounty once across all its submissions.
     * @param _bountyId The ID of the bounty.
     * @param _submissionId The ID of the insight submission to evaluate.
     * @param _score The score given to the insight (e.g., 1-100).
     */
    function evaluateInsight(uint256 _bountyId, uint256 _submissionId, uint256 _score) external onlyEvaluator {
        InsightBounty storage bounty = insightBounties[_bountyId];
        InsightSubmission storage submission = insightSubmissions[_submissionId];

        require(submission.bountyId == _bountyId, "DARD: Submission does not belong to this bounty");
        
        // If evaluation period hasn't started, initiate it
        if (bounty.status == BountyStatus.InProgress && block.timestamp > bounty.submissionPeriodEnd) {
             bounty.status = BountyStatus.Evaluating;
             bounty.evaluationPeriodEnd = block.timestamp + evaluationPeriod;
             emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Evaluating);
        }

        require(bounty.status == BountyStatus.Evaluating, "DARD: Bounty is not in evaluation period or has no submissions.");
        require(block.timestamp <= bounty.evaluationPeriodEnd, "DARD: Evaluation period has ended");
        require(!bounty.hasEvaluated[msg.sender], "DARD: Caller has already evaluated this bounty");
        require(_score > 0, "DARD: Score must be greater than zero"); // Adjust score range as needed (e.g., 1-100)

        submission.totalScore += _score;
        submission.numEvaluations++;
        bounty.hasEvaluated[msg.sender] = true;
        bounty.totalEvaluatorVotes++;
        // bounty.totalEvaluatorScore += _score; // This line is not needed for determining winner, only submission.totalScore matters

        emit InsightEvaluated(_bountyId, _submissionId, msg.sender, _score);
    }

    /**
     * @dev Finalizes the evaluation of a bounty, determining the winning insight.
     *      Callable by anyone after the evaluation period ends.
     *      Requires a minimum number of evaluators (quorum) if there are submissions.
     * @param _bountyId The ID of the bounty to finalize.
     */
    function finalizeBountyEvaluation(uint256 _bountyId) external {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.status == BountyStatus.Evaluating || (bounty.status == BountyStatus.InProgress && block.timestamp > bounty.submissionPeriodEnd), "DARD: Bounty is not ready for finalization");
        
        // If submissions period ended but evaluation period hasn't officially started (e.g., no evaluators yet)
        if (bounty.status == BountyStatus.InProgress && block.timestamp > bounty.submissionPeriodEnd) {
             bounty.status = BountyStatus.Evaluating;
             bounty.evaluationPeriodEnd = block.timestamp + evaluationPeriod;
             emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Evaluating);
        }

        require(bounty.status == BountyStatus.Evaluating, "DARD: Bounty must be in Evaluating status");
        require(block.timestamp > bounty.evaluationPeriodEnd, "DARD: Evaluation period has not ended");

        // If no submissions, mark as expired immediately
        if (bountySubmissions[_bountyId].length == 0) {
            bounty.status = BountyStatus.Expired;
            emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Expired);
            return;
        }

        // Ensure minimum evaluators if any submissions were made
        require(bounty.totalEvaluatorVotes >= evaluationQuorum, "DARD: Not enough evaluators for quorum");

        uint256 highestScore = 0;
        uint256 winningId = 0;

        for (uint256 i = 0; i < bountySubmissions[_bountyId].length; i++) {
            uint256 submissionId = bountySubmissions[_bountyId][i];
            InsightSubmission storage submission = insightSubmissions[submissionId];
            if (submission.totalScore > highestScore) {
                highestScore = submission.totalScore;
                winningId = submissionId;
            } else if (submission.totalScore == highestScore && winningId != 0 && submission.submissionTime < insightSubmissions[winningId].submissionTime) {
                // Tie-breaking: earlier submission wins if scores are equal
                winningId = submissionId;
            }
        }

        if (winningId != 0) {
            insightSubmissions[winningId].isAccepted = true;
            bounty.winningInsightId = winningId;
            bounty.status = BountyStatus.Completed; // Transition to Completed
            emit BountyEvaluationFinalized(_bountyId, winningId, highestScore);
            emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Completed);
        } else {
            bounty.status = BountyStatus.Expired; // No winner found (e.g., all scores were 0 or no submissions were properly evaluated)
            emit InsightBountyStatusUpdated(_bountyId, BountyStatus.Expired);
        }
    }

    // --- VI. Reward Distribution & Staking ---
    /**
     * @dev Distributes the bounty rewards to the winning researcher and collects protocol fees.
     *      Callable by anyone after the bounty has been finalized as 'Completed'.
     * @param _bountyId The ID of the bounty for which to distribute rewards.
     */
    function distributeBountyRewards(uint256 _bountyId) external nonReentrant {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.status == BountyStatus.Completed, "DARD: Bounty not yet completed or already distributed");
        require(bounty.winningInsightId != 0, "DARD: No winning insight found for this bounty");
        require(bounty.currentFunding > 0, "DARD: No funds to distribute for this bounty"); // Ensure there are funds

        InsightSubmission storage winningSubmission = insightSubmissions[bounty.winningInsightId];

        uint256 totalBountyAmount = bounty.currentFunding;
        uint256 protocolFee = (totalBountyAmount * protocolFeePermille) / 1000;
        uint256 netBountyAmount = totalBountyAmount - protocolFee;

        // Researcher reward: All of netBountyAmount goes to the winner (including their staked amount if any)
        uint256 researcherReward = netBountyAmount + winningSubmission.stakedAmount; // Staked amount is returned as part of reward
        
        // Zero out staked amount for the winner to prevent withdrawal
        winningSubmission.stakedAmount = 0; 

        IERC20 token = IERC20(bounty.fundingToken);

        // Transfer to winner
        require(token.transfer(winningSubmission.researcher, researcherReward), "DARD: Failed to transfer researcher reward");

        // Transfer fees to protocol recipient
        if (protocolFee > 0) {
            require(token.transfer(protocolFeeRecipient, protocolFee), "DARD: Failed to transfer protocol fee");
        }

        // Clear bounty's current funding
        bounty.currentFunding = 0; 

        emit BountyRewardsDistributed(_bountyId, bounty.winningInsightId, researcherReward, 0); // No separate evaluator reward in this version
    }

    /**
     * @dev Allows a researcher to withdraw their staked funds if their insight did not win.
     *      Can be called once the bounty is completed, expired, or canceled.
     * @param _submissionId The ID of the insight submission.
     */
    function withdrawStakedFunds(uint256 _submissionId) external nonReentrant {
        InsightSubmission storage submission = insightSubmissions[_submissionId];
        require(submission.researcher == msg.sender, "DARD: Caller is not the submitter");

        InsightBounty storage bounty = insightBounties[submission.bountyId];
        require(bounty.status == BountyStatus.Completed || bounty.status == BountyStatus.Expired || bounty.status == BountyStatus.Canceled, "DARD: Bounty not yet finalized or still active");
        require(!submission.isAccepted, "DARD: Winning insight cannot withdraw staked funds, they are part of the reward.");
        require(submission.stakedAmount > 0, "DARD: No staked funds to withdraw");

        uint256 amountToWithdraw = submission.stakedAmount;
        submission.stakedAmount = 0; // Prevent double withdrawal

        IERC20 token = IERC20(bounty.fundingToken);
        require(token.transfer(msg.sender, amountToWithdraw), "DARD: Failed to transfer staked funds");

        emit StakedFundsWithdrawn(_submissionId, msg.sender, amountToWithdraw);
    }

    // --- VII. Intellectual Property (IP-NFT) Management ---
    /**
     * @dev Mints an ERC-721 IP-NFT representing the intellectual property of a winning insight.
     *      Only callable once per winning insight, by the insight's researcher.
     * @param _insightId The ID of the winning insight.
     */
    function mintIpNftForInsight(uint256 _insightId) external nonReentrant {
        InsightSubmission storage insight = insightSubmissions[_insightId];
        require(insight.researcher == msg.sender, "DARD: Only the winning researcher can mint the IP-NFT");
        require(insight.isAccepted, "DARD: Insight is not a winning insight");
        require(insightToIpNftTokenId[_insightId] == 0, "DARD: IP-NFT already minted for this insight");

        _ipNftTokenIds.increment();
        uint256 newIpNftTokenId = _ipNftTokenIds.current();

        ipNftContract.mint(msg.sender, newIpNftTokenId, insight.ipfsHash);
        insightToIpNftTokenId[_insightId] = newIpNftTokenId;

        emit IpNftMinted(_insightId, newIpNftTokenId, msg.sender);
    }

    /**
     * @dev Sets the royalty percentage for an IP-NFT, applied on future secondary sales.
     *      Only callable by the current owner of the IP-NFT.
     * @param _insightId The ID of the insight associated with the IP-NFT.
     * @param _royaltyPermille The royalty percentage in permille (e.g., 50 for 5%). Max 1000 (100%).
     */
    function setIpNftRoyalties(uint256 _insightId, uint96 _royaltyPermille) external {
        uint256 tokenId = insightToIpNftTokenId[_insightId];
        require(tokenId != 0, "DARD: No IP-NFT minted for this insight");
        require(ipNftContract.ownerOf(tokenId) == msg.sender, "DARD: Only IP-NFT owner can set royalties");
        require(_royaltyPermille <= 1000, "DARD: Royalty percentage cannot exceed 100%"); // 1000 permille = 100%

        ipNftRoyaltiesPermille[tokenId] = _royaltyPermille;
        emit IpNftRoyaltiesSet(tokenId, _royaltyPermille);
    }

    // --- VIII. Knowledge Graph & Dynamic Parameters ---
    /**
     * @dev Allows a winning insight to declare conceptual dependencies on other *winning* insights.
     *      This builds a rudimentary on-chain knowledge graph, showing how research builds on previous work.
     * @param _insightId The ID of the insight that is declaring dependencies.
     * @param _parentInsightIds An array of IDs of parent insights that this insight builds upon.
     */
    function linkInsightDependencies(uint256 _insightId, uint256[] memory _parentInsightIds) external {
        InsightSubmission storage insight = insightSubmissions[_insightId];
        require(insight.researcher == msg.sender, "DARD: Only the insight's researcher can link dependencies");
        require(insight.isAccepted, "DARD: Only winning insights can declare dependencies");

        for (uint256 i = 0; i < _parentInsightIds.length; i++) {
            uint256 parentId = _parentInsightIds[i];
            require(insightSubmissions[parentId].isAccepted, "DARD: Parent insight must be a winning insight");
            require(parentId != _insightId, "DARD: Cannot link to self"); // Prevent circular dependencies

            // Add dependency only if it doesn't already exist to avoid duplicates
            bool found = false;
            for (uint256 j = 0; j < insightDependencies[_insightId].length; j++) {
                if (insightDependencies[_insightId][j] == parentId) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                insightDependencies[_insightId].push(parentId);
            }
        }
        emit InsightDependenciesLinked(_insightId, _parentInsightIds);
    }

    // --- IX. Synapse - External Contract Interaction ---
    /**
     * @dev Triggers an external contract call, enabled by a winning insight that was marked for Synapse.
     *      This is a powerful function allowing validated research outcomes to interact with other DApps
     *      (e.g., update a governance parameter, initiate a collateral rebalance, execute a new strategy).
     *      Only callable by the DARD contract owner after a Synapse-enabled bounty is completed and its insight has won.
     * @param _bountyId The ID of the bounty that enabled this Synapse action.
     * @param _targetContract The address of the external contract to call.
     * @param _callData The encoded function call data for the external contract (e.g., `abi.encodeWithSignature("foo(uint256,string)", 123, "bar")`).
     */
    function triggerSynapseAction(uint256 _bountyId, address _targetContract, bytes memory _callData) external onlyOwner nonReentrant {
        InsightBounty storage bounty = insightBounties[_bountyId];
        require(bounty.status == BountyStatus.Completed, "DARD: Bounty must be completed to trigger Synapse");
        require(bounty.requiresSynapseTrigger, "DARD: This bounty does not enable Synapse actions");
        require(!bounty.synapseTriggered, "DARD: Synapse action for this bounty already triggered");
        require(bounty.winningInsightId != 0, "DARD: No winning insight for this bounty");
        require(_targetContract != address(0), "DARD: Target contract cannot be zero address");
        require(bytes(_callData).length > 0, "DARD: Call data cannot be empty");

        // Mark that the Synapse action has been triggered for this bounty
        bounty.synapseTriggered = true;

        // Perform the external call
        (bool success, bytes memory returndata) = _targetContract.call(_callData);
        // If the target contract implements ISynapseTarget, it might be more specific:
        // (bool success, ) = ISynapseTarget(_targetContract).receiveSynapseTrigger(bounty.winningInsightId, _callData);
        require(success, string(abi.encodePacked("DARD: Synapse action failed - ", returndata)));

        emit SynapseActionTriggered(_bountyId, bounty.winningInsightId, _targetContract, _callData);
    }

    // --- X. Protocol Fees & Fund Management ---
    /**
     * @dev Sets the general DARD protocol fee percentage. Only callable by the owner.
     * @param _feePermille The fee percentage in permille (e.g., 10 for 1%). Capped at 100 permille (10%).
     */
    function setProtocolFee(uint256 _feePermille) external onlyOwner {
        require(_feePermille <= 100, "DARD: Protocol fee cannot exceed 10%");
        uint256 oldFee = protocolFeePermille;
        protocolFeePermille = _feePermille;
        emit ParameterUpdated("protocolFeePermille", oldFee, _feePermille);
    }

    /**
     * @dev Sets the evaluation quorum for bounties. Only callable by the owner.
     * @param _quorum The new minimum number of evaluators required.
     */
    function setEvaluationQuorum(uint256 _quorum) external onlyOwner {
        require(_quorum > 0, "DARD: Quorum must be greater than zero");
        uint256 oldQuorum = evaluationQuorum;
        evaluationQuorum = _quorum;
        emit ParameterUpdated("evaluationQuorum", oldQuorum, _quorum);
    }

    /**
     * @dev Sets the default insight submission period. Only callable by the owner.
     * @param _period The new submission period in seconds.
     */
    function setInsightSubmissionPeriod(uint256 _period) external onlyOwner {
        require(_period > 0, "DARD: Period must be greater than zero");
        uint256 oldPeriod = insightSubmissionPeriod;
        insightSubmissionPeriod = _period;
        emit ParameterUpdated("insightSubmissionPeriod", oldPeriod, _period);
    }

    /**
     * @dev Sets the default evaluation period. Only callable by the owner.
     * @param _period The new evaluation period in seconds.
     */
    function setEvaluationPeriod(uint256 _period) external onlyOwner {
        require(_period > 0, "DARD: Period must be greater than zero");
        uint256 oldPeriod = evaluationPeriod;
        evaluationPeriod = _period;
        emit ParameterUpdated("evaluationPeriod", oldPeriod, _period);
    }

    /**
     * @dev Allows the owner to withdraw accumulated protocol fees for a specific token.
     *      NOTE: This function assumes fees are collected and stored by the contract, and any
     *      remaining balance of a given token that is not part of an *active* bounty
     *      (i.e., not yet distributed) constitutes fees. A more robust system would
     *      explicitly track `mapping(address => uint256) public collectedFees;`.
     * @param _tokenAddress The address of the ERC-20 token to withdraw.
     */
    function withdrawProtocolFees(address _tokenAddress) external onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "DARD: Token address cannot be zero");
        IERC20 token = IERC20(_tokenAddress);
        
        uint256 totalContractBalance = token.balanceOf(address(this));
        
        // Calculate funds held for active bounties that are not yet distributed
        uint256 activeBountyFunds = 0;
        for (uint256 i = 1; i <= _bountyIds.current(); i++) {
            InsightBounty storage b = insightBounties[i];
            if (b.fundingToken == _tokenAddress && (
                b.status == BountyStatus.Proposed ||
                b.status == BountyStatus.Funded ||
                b.status == BountyStatus.InProgress ||
                b.status == BountyStatus.Evaluating
            )) {
                activeBountyFunds += b.currentFunding;
            }
        }
        
        // The amount available for withdrawal as fees is the total balance minus active bounty funds
        uint256 actualFeesToWithdraw = totalContractBalance > activeBountyFunds ? (totalContractBalance - activeBountyFunds) : 0;
        
        require(actualFeesToWithdraw > 0, "DARD: No fees to withdraw for this token.");
        require(token.transfer(protocolFeeRecipient, actualFeesToWithdraw), "DARD: Failed to transfer protocol fees");

        emit ProtocolFeeWithdrawn(_tokenAddress, protocolFeeRecipient, actualFeesToWithdraw);
    }

    // --- XI. View Functions ---
    /**
     * @dev Returns comprehensive details of a specific insight bounty.
     * @param _bountyId The ID of the bounty.
     * @return A tuple containing bounty details: (id, proposer, domainId, description, targetFunding, currentFunding, fundingToken, status,
     *                 submissionPeriodEnd, evaluationPeriodEnd, winningInsightId, requiresSynapseTrigger, synapseTriggered)
     */
    function getBountyDetails(uint256 _bountyId)
        public view returns (
            uint256 id,
            address proposer,
            uint256 domainId,
            string memory description,
            uint256 targetFunding,
            uint256 currentFunding,
            address fundingToken,
            BountyStatus status,
            uint256 submissionPeriodEnd,
            uint256 evaluationPeriodEnd,
            uint256 winningInsightId,
            bool requiresSynapseTrigger,
            bool synapseTriggered
        )
    {
        InsightBounty storage bounty = insightBounties[_bountyId];
        return (
            bounty.id,
            bounty.proposer,
            bounty.domainId,
            bounty.description,
            bounty.targetFunding,
            bounty.currentFunding,
            bounty.fundingToken,
            bounty.status,
            bounty.submissionPeriodEnd,
            bounty.evaluationPeriodEnd,
            bounty.winningInsightId,
            bounty.requiresSynapseTrigger,
            bounty.synapseTriggered
        );
    }

    /**
     * @dev Returns details of a specific insight submission.
     * @param _submissionId The ID of the insight submission.
     * @return A tuple containing submission details: (id, bountyId, researcher, ipfsHash, submissionTime, totalScore, numEvaluations, stakedAmount, isAccepted)
     */
    function getInsightSubmissionDetails(uint256 _submissionId)
        public view returns (
            uint256 id,
            uint256 bountyId,
            address researcher,
            string memory ipfsHash,
            uint256 submissionTime,
            uint256 totalScore,
            uint256 numEvaluations,
            uint256 stakedAmount,
            bool isAccepted
        )
    {
        InsightSubmission storage submission = insightSubmissions[_submissionId];
        return (
            submission.id,
            submission.bountyId,
            submission.researcher,
            submission.ipfsHash,
            submission.submissionTime,
            submission.totalScore,
            submission.numEvaluations,
            submission.stakedAmount,
            submission.isAccepted
        );
    }

    /**
     * @dev Returns the registration status of an address as a researcher.
     * @param _addr The address to check.
     * @return True if registered as researcher, false otherwise.
     */
    function getResearcherStatus(address _addr) public view returns (bool) {
        return isResearcher[_addr];
    }

    /**
     * @dev Returns the registration status of an address as an evaluator.
     * @param _addr The address to check.
     * @return True if registered as evaluator, false otherwise.
     */
    function getEvaluatorStatus(address _addr) public view returns (bool) {
        return isEvaluator[_addr];
    }

    /**
     * @dev Returns details about a research domain.
     * @param _domainId The ID of the research domain.
     * @return A tuple containing domain details: (id, name, isActive)
     */
    function getDomainDetails(uint256 _domainId)
        public view returns (uint256 id, string memory name, bool isActive)
    {
        ResearchDomain storage domain = researchDomains[_domainId];
        return (domain.id, domain.name, domain.isActive);
    }

    /**
     * @dev Returns the IP-NFT token ID associated with a winning insight.
     * @param _insightId The ID of the insight.
     * @return The token ID of the minted IP-NFT, or 0 if not minted.
     */
    function getIpNftTokenId(uint256 _insightId) public view returns (uint256) {
        return insightToIpNftTokenId[_insightId];
    }

    /**
     * @dev Returns the royalty percentage for a given IP-NFT token ID.
     * @param _tokenId The token ID of the IP-NFT.
     * @return The royalty percentage in permille.
     */
    function getIpNftRoyalties(uint256 _tokenId) public view returns (uint96) {
        return ipNftRoyaltiesPermille[_tokenId];
    }

    /**
     * @dev Returns the IDs of insights that a given insight depends upon.
     * @param _insightId The ID of the insight whose dependencies are sought.
     * @return An array of parent insight IDs.
     */
    function getInsightDependencies(uint256 _insightId) public view returns (uint256[] memory) {
        return insightDependencies[_insightId];
    }
}

/**
 * @title DARD_IP_NFT
 * @dev A simple ERC721 contract for representing Intellectual Property generated by DARD insights.
 *      Minting is strictly restricted to the DARD contract address.
 */
contract DARD_IP_NFT is ERC721 {
    address private immutable _dardContract;
    mapping(uint256 => string) private _tokenIpfsUris; // Store IPFS hash as URI for each token

    /**
     * @dev Constructor to deploy the IP-NFT contract.
     * @param name The full name of the NFT collection.
     * @param symbol The symbol for the NFT collection.
     * @param dardContractAddress The address of the main DARD contract, which will be the sole minter.
     */
    constructor(string memory name, string memory symbol, address dardContractAddress) ERC721(name, symbol) {
        _dardContract = dardContractAddress;
    }

    /**
     * @dev Modifier to ensure only the DARD contract can call restricted functions.
     */
    modifier onlyDARD() {
        require(msg.sender == _dardContract, "DARD_IP_NFT: Only DARD contract can perform this action");
        _;
    }

    /**
     * @dev Mints a new IP-NFT. Callable only by the DARD contract.
     * @param to The recipient of the NFT.
     * @param tokenId The unique identifier for the NFT.
     * @param ipfsUri The IPFS URI pointing to the insight's full content (e.g., a detailed research report).
     */
    function mint(address to, uint256 tokenId, string memory ipfsUri) external onlyDARD {
        _mint(to, tokenId);
        _setTokenURI(tokenId, ipfsUri); // Set the ERC721 metadata URI
        _tokenIpfsUris[tokenId] = ipfsUri; // Store internally for direct lookup if needed
    }

    /**
     * @dev Overrides the standard ERC721 `tokenURI` function to return the IPFS hash as the URI.
     * @param tokenId The ID of the NFT.
     * @return The IPFS URI string.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenIpfsUris[tokenId];
    }
}
```