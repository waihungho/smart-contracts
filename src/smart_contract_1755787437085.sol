This Solidity smart contract, **CogniCraftDAO**, envisions a decentralized platform for collaborative AI model development, ownership, and monetization. It introduces several advanced and creative concepts:

*   **Decentralized AI Model Marketplace:** Users can propose and fund bounties for specific AI models. Developers submit solutions, which are then evaluated via external oracles.
*   **Dynamic AI Model NFTs (CCAM-NFTs):** Each accepted AI model becomes a unique, dynamic ERC721 NFT. Its metadata, particularly performance metrics, can be updated on-chain, reflecting real-world usage and evaluations.
*   **Soulbound Reputation (CRSBTs):** A non-transferable ERC721 token (badge) signifies a user's reputation, while the numerical score is managed directly by the DAO contract, influencing voting power and platform privileges.
*   **Flash Loans of Access:** A novel concept allowing users to gain temporary, single-transaction access to a premium AI model, paying a fee, and ensuring the access is revoked within the same block. This enables quick, on-demand inferences without long-term subscriptions.
*   **Automated Royalty Distribution:** Earnings from model subscriptions and pay-per-inference are automatically split between the model owner (CCAM-NFT holder) and the DAO treasury.
*   **On-chain Governance (DAO):** A robust DAO structure allows members to propose, vote on, and execute decisions related to bounties, model acceptance, treasury management, and dispute resolution.
*   **Oracle Integration:** Leverages external oracles (e.g., Chainlink) for verifiable, off-chain AI model performance evaluations, bringing real-world data onto the blockchain.
*   **Dispute Resolution System:** Users can raise disputes regarding model performance or integrity, which are then resolved through DAO voting.

---

### **Outline**

**I. Core Infrastructure & DAO Management**
    *   **Constructor:** Initializes the DAO, sets up base tokens and roles.
    *   **Pausability & Admin:** Emergency stop and administrative control.
    *   **DAO Proposals & Voting:** General mechanism for creating and executing proposals (e.g., bounties, treasury withdrawals).

**II. AI Model Submission & Lifecycle**
    *   **Bounty Management:** Defining tasks for AI model development.
    *   **Model Submission:** Developers submit solutions.
    *   **Performance Evaluation:** Integration with external oracles (e.g., Chainlink) for verifiable metrics.
    *   **Model Acceptance & Minting:** Approved models become Dynamic NFTs.
    *   **Lifecycle Management:** Updates, retirement of models.

**III. Dynamic NFTs (CCAM-NFTs) & Soulbound Tokens (Reputation)**
    *   **CCAM-NFTs:** ERC721 tokens representing AI models, with mutable metadata based on performance/usage.
    *   **CRSBTs:** ERC721 non-transferable tokens (badges) for indicating a user's reputation.
    *   **Reputation System:** Granting and revoking numerical reputation scores.

**IV. Model Access & Monetization**
    *   **Subscription Model:** Users can subscribe for recurring access to models.
    *   **Pay-Per-Inference:** Users pay per use for specific models.
    *   **Flash Loan of Access:** A unique concept allowing temporary, single-transaction access to premium models.
    *   **Royalty Distribution:** Automated split of earnings between model owners and the DAO treasury.

**V. Dispute Resolution & Oracle Integration**
    *   **Dispute Mechanism:** Users can challenge model performance or behavior.
    *   **Decentralized Resolution:** DAO votes to resolve disputes.
    *   **Oracle Management:** Setting up and interacting with external data providers for objective evaluations.

---

### **Function Summary**

---
#### **I. Core Infrastructure & DAO Management**
1.  `constructor(address _initialOwner, address _daoToken, address _reputationSBT, address _aiModelNFT)`: Initializes the contract, sets up token addresses (DAO Token, Reputation SBT, AI Model NFT), and defines the initial admin.
2.  `emergencyPause()`: Allows the contract owner or DAO to pause critical functionalities in an emergency.
3.  `unpause()`: Unpauses the contract functionalities, allowing normal operations to resume.
4.  `proposeDAOAction(string memory _description, address _target, bytes memory _calldata, uint256 _value)`: Allows DAO members to propose a generic action (e.g., treasury withdrawal, setting change) for a vote. Caller must hold sufficient DAO tokens.
5.  `voteOnProposal(uint256 _proposalId, bool _support)`: DAO members cast their vote on an active proposal. Voting power is determined by their current DAO token balance.
6.  `executeProposal(uint256 _proposalId)`: Executes a proposal that has concluded its voting period and met the quorum and approval thresholds.
7.  `updateDaoSettings(uint256 _minVotingPower, uint256 _proposalQuorum, uint256 _votingPeriodBlocks)`: Allows the DAO to update its core governance parameters (min tokens for proposal, quorum percentage, voting duration). This function is only callable via a successful DAO proposal execution.

---
#### **II. AI Model Submission & Lifecycle**
8.  `proposeNewBounty(string memory _title, string memory _descriptionURI, uint256 _rewardAmount)`: DAO members propose a new AI model development bounty with an associated reward. This proposal then goes through the DAO voting process.
9.  `fundBounty(uint256 _bountyId)`: Allows anyone to deposit the full reward amount in DAO tokens into a specific, active bounty.
10. `submitModelSolution(uint256 _bountyId, string memory _modelURI, string memory _inferenceEndpoint)`: Developers submit their AI model solution for an active bounty, providing an IPFS URI for the model and an off-chain inference endpoint.
11. `requestOracleEvaluation(uint256 _submissionId, string memory _metricRequestData)`: Triggers an external oracle (e.g., Chainlink) to evaluate a submitted model's performance based on provided data.
12. `fulfillOracleEvaluation(bytes32 _requestId, bytes memory _responseData)`: A callback function, callable only by the designated oracle, to report the results of a model's performance evaluation.
13. `acceptModelSolution(uint256 _submissionId, uint256 _initialPerformanceScore)`: The DAO accepts a submitted model, mints its CCAM-NFT to the submitter, and distributes the bounty reward. Callable only via a successful DAO proposal.
14. `updateModelMetadata(uint256 _modelNFTId, string memory _newModelURI, string memory _newEndpoint)`: The owner of a CCAM-NFT can update the model's IPFS URI or inference endpoint.
15. `retireModel(uint256 _modelNFTId)`: Allows the DAO to vote to retire a poorly performing or deprecated AI model, disabling its future access. Callable only via a successful DAO proposal.

---
#### **III. Dynamic NFTs (CCAM-NFTs) & Soulbound Tokens (Reputation)**
16. `getCCAM_NFTDetails(uint256 _modelNFTId)`: Retrieves the dynamic metadata (model URI, inference endpoint, performance score, active status) of a specific CCAM-NFT.
17. `grantReputation(address _user, uint256 _amount)`: Allows the DAO to grant reputation points to a user. If the user's score goes from zero to positive, a non-transferable reputation badge (CRSBT) is minted. Callable only via a successful DAO proposal.
18. `revokeReputation(address _user, uint256 _amount)`: Allows the DAO to revoke reputation points from a user. If the user's score drops to zero, their reputation badge (CRSBT) is burned. Callable only via a successful DAO proposal.
19. `getReputationScore(address _user)`: Returns a user's current numerical reputation score.

---
#### **IV. Model Access & Monetization**
20. `subscribeToModel(uint256 _modelNFTId, uint256 _durationMonths)`: Users can subscribe to an AI model for a specified duration, paying with DAO tokens. Earnings are split between the model owner and the DAO.
21. `payPerInference(uint256 _modelNFTId)`: Users can pay for a single, one-off inference request from a model using DAO tokens. Earnings are split.
22. `flashLoanModelAccess(uint256 _modelNFTId, address _receiver, bytes memory _data)`: A novel function that grants temporary access to a model within a single transaction. The `_receiver` contract (which must implement `IFlashLoanReceiver`) receives a callback to utilize the access, which is then revoked immediately after the call returns. A fee is paid upfront.
23. `distributeRoyalties(uint256 _modelNFTId)`: Allows the CCAM-NFT owner to trigger the distribution of their accumulated royalties from model usage.
24. `isModelAccessible(uint256 _modelNFTId, address _user)`: Checks if a specific user currently has access to a given model via subscription or an active flash loan within the current transaction.

---
#### **V. Dispute Resolution & Oracle Integration**
25. `raiseDispute(uint256 _modelNFTId, string memory _reasonURI)`: Users can raise a formal dispute against an AI model's performance or integrity, providing an IPFS URI for detailed reasons.
26. `voteOnDispute(uint256 _disputeId, bool _support)`: DAO members vote to resolve an active dispute.
27. `resolveDispute(uint256 _disputeId)`: Concludes a dispute after its voting period, marking it as resolved or rejected based on DAO votes.
28. `setOracleAddress(address _newOracle)`: Allows the DAO to update the address of the external oracle service used for model evaluations. Callable only via a successful DAO proposal.
29. `setFlashLoanFee(uint256 _newFee)`: Allows the DAO to set the fee for flash loan access to models. Callable only via a successful DAO proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interfaces for external contracts/services like Chainlink
// For a real Chainlink integration, this interface would be more specific (e.g., ChainlinkClient)
interface IOracle {
    // Simplified request; real Chainlink uses specific requests and fulfillments
    function request(bytes memory data) external returns (bytes32 requestId);
    function fulfill(bytes32 requestId, bytes memory response) external; // Callable only by the oracle
}

/**
 * @title CogniCraftDAO
 * @dev A decentralized platform for AI model development, ownership (Dynamic NFTs), and monetization.
 *      It integrates a DAO for governance, a reputation system (Soulbound Tokens), and
 *      novel "flash loans of access" for AI models.
 *
 * @outline
 * I. Core Infrastructure & DAO Management
 *    - Constructor: Initializes the DAO, sets up base tokens and roles.
 *    - Pausability & Admin: Emergency stop and administrative control.
 *    - DAO Proposals & Voting: General mechanism for creating and executing proposals (e.g., bounties, treasury withdrawals).
 *
 * II. AI Model Submission & Lifecycle
 *    - Bounty Management: Defining tasks for AI model development.
 *    - Model Submission: Developers submit solutions.
 *    - Performance Evaluation: Integration with external oracles (e.g., Chainlink) for verifiable metrics.
 *    - Model Acceptance & Minting: Approved models become Dynamic NFTs.
 *    - Lifecycle Management: Updates, retirement of models.
 *
 * III. Dynamic NFTs (CCAM-NFTs) & Soulbound Tokens (Reputation)
 *    - CCAM-NFTs: ERC721 tokens representing AI models, with mutable metadata based on performance/usage.
 *    - CRSBTs: ERC721 non-transferable tokens (badges) for tracking user reputation presence.
 *    - Reputation System: Granting and revoking numerical reputation scores.
 *
 * IV. Model Access & Monetization
 *    - Subscription Model: Users can subscribe for recurring access to models.
 *    - Pay-Per-Inference: Users pay per use for specific models.
 *    - Flash Loan of Access: A unique concept allowing temporary, single-transaction access to premium models.
 *    - Royalty Distribution: Automated split of earnings between model owners and the DAO treasury.
 *
 * V. Dispute Resolution & Oracle Integration
 *    - Dispute Mechanism: Users can challenge model performance or behavior.
 *    - Decentralized Resolution: DAO votes to resolve disputes.
 *    - Oracle Management: Setting up and interacting with external data providers for objective evaluations.
 *
 * @function_summary
 * --- I. Core Infrastructure & DAO Management ---
 * 1.  `constructor(address _initialOwner, address _daoToken, address _reputationSBT, address _aiModelNFT)`: Initializes the contract, sets up tokens, and defines the initial admin.
 * 2.  `emergencyPause()`: Allows the contract owner or DAO to pause critical functionalities.
 * 3.  `unpause()`: Unpauses the contract functionalities.
 * 4.  `proposeDAOAction(string memory _description, address _target, bytes memory _calldata, uint256 _value)`: Allows DAO members to propose a generic action, including treasury withdrawals or setting changes.
 * 5.  `voteOnProposal(uint256 _proposalId, bool _support)`: DAO members vote on an active proposal.
 * 6.  `executeProposal(uint256 _proposalId)`: Executes a proposal that has met the quorum and voting threshold.
 * 7.  `updateDaoSettings(uint256 _minVotingPower, uint256 _proposalQuorum, uint256 _votingPeriodBlocks)`: DAO-approved update for governance parameters.
 *
 * --- II. AI Model Submission & Lifecycle ---
 * 8.  `proposeNewBounty(string memory _title, string memory _descriptionURI, uint256 _rewardAmount)`: DAO members propose a new AI model development bounty with an associated reward.
 * 9.  `fundBounty(uint256 _bountyId)`: Allows DAO members to deposit funds into a specific bounty.
 * 10. `submitModelSolution(uint256 _bountyId, string memory _modelURI, string memory _inferenceEndpoint)`: Developers submit their AI model solution for an active bounty.
 * 11. `requestOracleEvaluation(uint256 _submissionId, string memory _metricRequestData)`: Triggers an external oracle evaluation of a submitted model's performance.
 * 12. `fulfillOracleEvaluation(bytes32 _requestId, bytes memory _responseData)`: Callback function for the oracle to report evaluation results.
 * 13. `acceptModelSolution(uint256 _submissionId, uint256 _initialPerformanceScore)`: DAO accepts a submitted model, mints its CCAM-NFT, and distributes bounty rewards.
 * 14. `updateModelMetadata(uint256 _modelNFTId, string memory _newModelURI, string memory _newEndpoint)`: CCAM-NFT owner can update the associated model's URI and inference endpoint.
 * 15. `retireModel(uint256 _modelNFTId)`: DAO can vote to retire a poorly performing or deprecated AI model, effectively disabling its access.
 *
 * --- III. Dynamic NFTs (CCAM-NFTs) & Soulbound Tokens (Reputation) ---
 * 16. `getCCAM_NFTDetails(uint256 _modelNFTId)`: Retrieves detailed, dynamic metadata for a specific CCAM-NFT.
 * 17. `grantReputation(address _user, uint256 _amount)`: DAO or specific role can grant reputation points to a user, minting their SBT badge if score becomes positive.
 * 18. `revokeReputation(address _user, uint256 _amount)`: DAO or specific role can revoke reputation points from a user, burning their SBT badge if score becomes zero.
 * 19. `getReputationScore(address _user)`: Returns a user's current reputation score.
 *
 * --- IV. Model Access & Monetization ---
 * 20. `subscribeToModel(uint252 _modelNFTId, uint256 _durationMonths)`: Users subscribe to a model for recurring access, paying with DAO tokens.
 * 21. `payPerInference(uint256 _modelNFTId)`: Users pay for a single inference request from a model.
 * 22. `flashLoanModelAccess(uint256 _modelNFTId, address _receiver, bytes memory _data)`: Allows temporary, single-transaction access to a model. The receiver must implement `IFlashLoanReceiver`.
 * 23. `distributeRoyalties(uint256 _modelNFTId)`: Allows the CCAM-NFT owner to trigger the distribution of accumulated royalties.
 * 24. `isModelAccessible(uint256 _modelNFTId, address _user)`: Checks if a specific user has access to a given model (subscription, flash loan, or direct payment in current block).
 *
 * --- V. Dispute Resolution & Oracle Integration ---
 * 25. `raiseDispute(uint256 _modelNFTId, string memory _reasonURI)`: Users can raise a dispute against an AI model's performance or integrity.
 * 26. `voteOnDispute(uint256 _disputeId, bool _support)`: DAO members vote to resolve a dispute.
 * 27. `resolveDispute(uint256 _disputeId)`: Executes the outcome of a dispute vote (e.g., penalize model, refund users).
 * 28. `setOracleAddress(address _newOracle)`: Admin or DAO can update the address of the external oracle service.
 * 29. `setFlashLoanFee(uint256 _newFee)`: Admin or DAO can set the fee for flash loan access.
 */
contract CogniCraftDAO is Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Strings for uint256;

    // --- State Variables ---

    // Token contracts
    IERC20 public immutable daoToken; // ERC-20 token for governance and payments
    CogniCraftReputationSBT public immutable reputationSBT; // ERC-721 Soulbound Token for reputation badge
    CogniCraftAIModelNFT public immutable aiModelNFT; // ERC-721 token for AI models (Dynamic NFT)

    address public oracleAddress; // Address of the external oracle service (e.g., Chainlink)

    // DAO Governance Parameters
    uint256 public minVotingPower; // Minimum DAO tokens to propose/vote
    uint256 public proposalQuorum; // Percentage of total voting power required for a proposal to pass (e.g., 51 for 51%)
    uint256 public votingPeriodBlocks; // Number of blocks for a proposal to be open for voting

    uint256 public flashLoanFee; // Fee for flash loan access, in basis points (e.g., 100 = 1%)

    // Fees for model access (in DAO tokens)
    uint256 public subscriptionPricePerMonth;
    uint256 public payPerInferenceFee;
    uint256 public DAO_ROYALTY_PERCENTAGE; // Percentage of model earnings that goes to the DAO (e.g., 10 for 10%)

    mapping(address => uint256) public reputationScores; // Numerical reputation score for each user

    // --- Structs & Enums ---

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        address target;
        bytes calldata;
        uint256 value; // Value to send to target (e.g., for treasury withdrawals)
        uint256 voteCountFor;
        uint256 voteCountAgainst;
        uint256 totalVotingPowerAtStart; // Snapshot of total supply for quorum
        mapping(address => bool) hasVoted; // Tracks who has voted
        uint256 startBlock;
        uint256 endBlock;
        ProposalState state;
        bool executed;
    }

    enum BountyState { Proposed, Active, InReview, Accepted, Retired, Failed }

    struct Bounty {
        uint256 id;
        string title;
        string descriptionURI; // IPFS URI for detailed description
        uint256 rewardAmount; // Reward in DAO tokens
        address proposer;
        BountyState state;
        uint256 proposalId; // ID of the DAO proposal that approved this bounty
    }

    enum SubmissionState { Submitted, Evaluating, Accepted, Rejected }

    struct ModelSubmission {
        uint256 id;
        uint256 bountyId;
        address submitter;
        string modelURI; // IPFS URI for the model files/metadata
        string inferenceEndpoint; // API endpoint for model usage (off-chain)
        SubmissionState state;
        bytes32 oracleRequestId; // Link to oracle request
        uint256 performanceScore; // Score provided by oracle
        uint256 modelNFTId; // Link to minted NFT if accepted
    }

    enum DisputeState { Active, Resolved, Rejected }

    struct Dispute {
        uint256 id;
        uint256 modelNFTId;
        address disputer;
        string reasonURI; // IPFS URI for detailed reason
        uint256 voteCountFor; // For resolving the dispute in favor of disputer/DAO
        uint256 voteCountAgainst; // Against the dispute
        uint256 totalVotingPowerAtStart;
        mapping(address => bool) hasVoted;
        uint256 startBlock;
        uint256 endBlock;
        DisputeState state;
        bool executed;
    }

    struct ModelAccessSubscription {
        uint256 modelNFTId;
        uint256 expiresAt; // Unix timestamp
    }

    // --- Mappings & Counters ---

    uint256 private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;

    uint256 private _bountyIdCounter;
    mapping(uint256 => Bounty) public bounties;

    uint256 private _submissionIdCounter;
    mapping(uint256 => ModelSubmission) public modelSubmissions;

    uint256 private _disputeIdCounter;
    mapping(uint256 => Dispute) public disputes;

    mapping(address => mapping(uint256 => ModelAccessSubscription)) public userSubscriptions; // user => modelNFTId => subscription details
    mapping(uint256 => uint256) public modelAccumulatedRoyalties; // modelNFTId => accumulated royalties
    mapping(address => EnumerableSet.UintSet) private _activeFlashLoanAccess; // User => set of modelNFTId they have current flash loan access

    // --- Events ---

    event ProposalCreated(uint256 indexed proposalId, string description, address proposer, address target, uint256 value);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId);

    event BountyProposed(uint256 indexed bountyId, string title, uint256 rewardAmount, address proposer);
    event BountyFunded(uint256 indexed bountyId, address funder, uint256 amount);
    event ModelSubmitted(uint256 indexed submissionId, uint256 indexed bountyId, address submitter, string modelURI);
    event OracleEvaluationRequested(uint256 indexed submissionId, bytes32 indexed requestId);
    event OracleEvaluationFulfilled(uint256 indexed submissionId, bytes32 indexed requestId, uint256 performanceScore);
    event ModelAccepted(uint256 indexed submissionId, uint256 indexed modelNFTId, address submitter, uint256 rewardAmount);
    event ModelRetired(uint256 indexed modelNFTId);
    event ModelMetadataUpdated(uint256 indexed modelNFTId, string newModelURI, string newEndpoint);

    event ReputationGranted(address indexed user, uint256 newScore);
    event ReputationRevoked(address indexed user, uint256 newScore);

    event ModelSubscribed(address indexed user, uint256 indexed modelNFTId, uint256 durationMonths, uint256 pricePaid);
    event InferencePaid(address indexed user, uint256 indexed modelNFTId, uint256 feePaid);
    event FlashLoanAccessGranted(address indexed user, uint256 indexed modelNFTId, uint256 fee);
    event RoyaltiesDistributed(uint256 indexed modelNFTId, address indexed owner, uint256 amount);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed modelNFTId, address indexed disputer);
    event DisputeResolved(uint256 indexed disputeId, DisputeState newState, bool executed);

    // --- Modifiers ---

    /**
     * @dev Restricts a function call to either the contract owner or as a result of a DAO proposal execution.
     *      In a production environment, `msg.sender == owner()` might be removed for pure DAO control.
     */
    modifier onlyDAO() {
        require(msg.sender == address(this) || msg.sender == owner(), "CogniCraftDAO: Only callable by DAO or owner for setup");
        _;
    }

    /**
     * @dev Restricts a function call to the designated oracle address.
     */
    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "CogniCraftDAO: Only callable by the designated oracle");
        _;
    }

    /**
     * @dev Ensures the specified AI model NFT exists and is active.
     * @param _modelNFTId The ID of the CCAM-NFT.
     */
    modifier ensureModelActive(uint256 _modelNFTId) {
        require(aiModelNFT.isModelActive(_modelNFTId), "CogniCraftDAO: Model is not active or does not exist");
        _;
    }

    /**
     * @dev Ensures the user has an active flash loan access for the specified model within the current transaction.
     *      This modifier is primarily for internal logic within the flash loan execution flow.
     * @param _user The address of the user.
     * @param _modelNFTId The ID of the model.
     */
    modifier whenFlashLoanActive(address _user, uint256 _modelNFTId) {
        require(_activeFlashLoanAccess[_user].contains(_modelNFTId), "CogniCraftDAO: Flash loan access not active for this model");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the CogniCraftDAO contract.
     * @param _initialOwner The address of the initial contract owner (admin).
     * @param _daoToken The address of the ERC20 token used for DAO governance and payments.
     * @param _reputationSBT The address of the CogniCraftReputationSBT contract.
     * @param _aiModelNFT The address of the CogniCraftAIModelNFT contract.
     */
    constructor(
        address _initialOwner,
        address _daoToken,
        address _reputationSBT,
        address _aiModelNFT
    )
        Ownable(_initialOwner)
        Pausable()
    {
        require(_daoToken != address(0), "CogniCraftDAO: DAO token address cannot be zero");
        require(_reputationSBT != address(0), "CogniCraftDAO: Reputation SBT address cannot be zero");
        require(_aiModelNFT != address(0), "CogniCraftDAO: AI Model NFT address cannot be zero");

        daoToken = IERC20(_daoToken);
        reputationSBT = CogniCraftReputationSBT(_reputationSBT);
        aiModelNFT = CogniCraftAIModelNFT(_aiModelNFT);

        // Initial DAO settings (can be changed by DAO later via `updateDaoSettings`)
        minVotingPower = 100 * (10 ** daoToken.decimals()); // Example: 100 DAO tokens
        proposalQuorum = 50; // 50%
        votingPeriodBlocks = 1000; // Approx 4-5 hours at 12s/block
        flashLoanFee = 100; // 1% (100 basis points, out of 10,000)
        subscriptionPricePerMonth = 10 * (10 ** daoToken.decimals()); // Example: 10 DAO tokens per month
        payPerInferenceFee = 1 * (10 ** daoToken.decimals()); // Example: 1 DAO token per inference
        DAO_ROYALTY_PERCENTAGE = 10; // 10%
    }

    // --- I. Core Infrastructure & DAO Management ---

    /**
     * @dev Allows the contract owner to pause critical functionalities.
     *      In a full DAO, this might be a multi-sig or highly controlled function,
     *      or even a DAO vote itself.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Allows the contract owner to unpause critical functionalities.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows DAO members to propose a generic action to be voted upon.
     *      Caller must have `minVotingPower` in DAO tokens.
     * @param _description A brief description of the proposal.
     * @param _target The address of the contract or account to call.
     * @param _calldata The encoded function call data for the target.
     * @param _value The amount of native tokens (ETH) to send with the call (0 for DAO token transfers).
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeDAOAction(
        string memory _description,
        address _target,
        bytes memory _calldata,
        uint256 _value
    ) external payable nonReentrant whenNotPaused returns (uint256) {
        require(daoToken.balanceOf(msg.sender) >= minVotingPower, "CogniCraftDAO: Insufficient voting power to propose");

        _proposalIdCounter++;
        uint256 currentId = _proposalIdCounter;

        Proposal storage p = proposals[currentId];
        p.id = currentId;
        p.description = _description;
        p.proposer = msg.sender;
        p.target = _target;
        p.calldata = _calldata;
        p.value = _value;
        p.startBlock = block.number;
        p.endBlock = block.number + votingPeriodBlocks;
        p.state = ProposalState.Active;
        p.totalVotingPowerAtStart = daoToken.totalSupply(); // Snapshot total supply for quorum calculation

        emit ProposalCreated(currentId, _description, msg.sender, _target, _value);
        return currentId;
    }

    /**
     * @dev Allows DAO members to vote on an active proposal.
     *      Caller's voting power is their current DAO token balance.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, False for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external nonReentrant whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.state == ProposalState.Active, "CogniCraftDAO: Proposal not active");
        require(block.number <= p.endBlock, "CogniCraftDAO: Voting period has ended");
        require(!p.hasVoted[msg.sender], "CogniCraftDAO: Already voted on this proposal");

        uint256 voterVotingPower = daoToken.balanceOf(msg.sender);
        require(voterVotingPower > 0, "CogniCraftDAO: Voter has no DAO tokens");

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.voteCountFor += voterVotingPower;
        } else {
            p.voteCountAgainst += voterVotingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterVotingPower);
    }

    /**
     * @dev Executes a proposal if it has succeeded.
     *      Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external nonReentrant whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.state != ProposalState.Executed, "CogniCraftDAO: Proposal already executed");
        require(block.number > p.endBlock, "CogniCraftDAO: Voting period not ended yet");

        if (p.state != ProposalState.Succeeded) { // Recalculate if not already Succeeded
            uint256 totalVotes = p.voteCountFor + p.voteCountAgainst;
            uint256 quorumThreshold = (p.totalVotingPowerAtStart * proposalQuorum) / 100;

            if (totalVotes >= quorumThreshold && p.voteCountFor > p.voteCountAgainst) {
                p.state = ProposalState.Succeeded;
            } else {
                p.state = ProposalState.Failed;
            }
            emit ProposalStateChanged(_proposalId, p.state);
        }

        require(p.state == ProposalState.Succeeded, "CogniCraftDAO: Proposal not succeeded");

        p.executed = true;
        // The call is made from this contract, so onlyDAO modifier will pass for target `this`.
        (bool success, ) = p.target.call{value: p.value}(p.calldata);
        require(success, "CogniCraftDAO: Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows the DAO to update core governance settings.
     *      This function can only be called via a successful DAO proposal.
     * @param _minVotingPower The new minimum voting power for proposals.
     * @param _proposalQuorum The new quorum percentage.
     * @param _votingPeriodBlocks The new voting period in blocks.
     */
    function updateDaoSettings(
        uint256 _minVotingPower,
        uint256 _proposalQuorum,
        uint256 _votingPeriodBlocks
    ) external onlyDAO {
        require(_proposalQuorum > 0 && _proposalQuorum <= 100, "CogniCraftDAO: Quorum must be between 1 and 100");
        minVotingPower = _minVotingPower;
        proposalQuorum = _proposalQuorum;
        votingPeriodBlocks = _votingPeriodBlocks;
    }

    // --- II. AI Model Submission & Lifecycle ---

    /**
     * @dev Allows DAO members to propose a new AI model development bounty.
     *      The bounty must be approved by the DAO before it becomes active.
     * @param _title The title of the bounty.
     * @param _descriptionURI IPFS URI for detailed bounty description.
     * @param _rewardAmount The reward amount in DAO tokens for completing the bounty.
     * @return bountyId The ID of the new bounty.
     */
    function proposeNewBounty(
        string memory _title,
        string memory _descriptionURI,
        uint256 _rewardAmount
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(daoToken.balanceOf(msg.sender) >= minVotingPower, "CogniCraftDAO: Insufficient voting power to propose");
        require(_rewardAmount > 0, "CogniCraftDAO: Bounty reward must be positive");

        _bountyIdCounter++;
        uint256 currentBountyId = _bountyIdCounter;

        // Propose this bounty creation as a DAO action
        bytes memory callData = abi.encodeWithSelector(
            this.acceptNewBountyProposal.selector,
            currentBountyId, _title, _descriptionURI, _rewardAmount, msg.sender
        );

        // This proposal will then need to be voted on by the DAO
        uint256 proposalId = proposeDAOAction(
            string(abi.encodePacked("Approve new bounty: ", _title)),
            address(this),
            callData,
            0 // No ETH value transferred for this internal call
        );

        bounties[currentBountyId] = Bounty({
            id: currentBountyId,
            title: _title,
            descriptionURI: _descriptionURI,
            rewardAmount: _rewardAmount,
            proposer: msg.sender,
            state: BountyState.Proposed,
            proposalId: proposalId
        });

        emit BountyProposed(currentBountyId, _title, _rewardAmount, msg.sender);
        return currentBountyId;
    }

    /**
     * @dev Internal function called only by `executeProposal` after a bounty creation is approved.
     *      Marks the bounty as active, ready for submissions.
     */
    function acceptNewBountyProposal(
        uint256 _bountyId,
        string memory _title,
        string memory _descriptionURI,
        uint256 _rewardAmount,
        address _proposer
    ) external onlyDAO {
        Bounty storage b = bounties[_bountyId];
        require(b.state == BountyState.Proposed, "CogniCraftDAO: Bounty not in Proposed state");
        require(
            keccak256(abi.encodePacked(b.title)) == keccak256(abi.encodePacked(_title)) &&
            keccak256(abi.encodePacked(b.descriptionURI)) == keccak256(abi.encodePacked(_descriptionURI)) &&
            b.rewardAmount == _rewardAmount &&
            b.proposer == _proposer,
            "CogniCraftDAO: Data mismatch for bounty proposal"
        );

        b.state = BountyState.Active; // Bounty is now active and ready for submissions
    }


    /**
     * @dev Allows anyone to fund an active bounty.
     * @param _bountyId The ID of the bounty to fund.
     */
    function fundBounty(uint256 _bountyId) external whenNotPaused {
        Bounty storage b = bounties[_bountyId];
        require(b.state == BountyState.Active, "CogniCraftDAO: Bounty is not active");

        uint256 amountToTransfer = b.rewardAmount; // Assume funding the exact reward amount
        // In a more complex system, this could allow partial funding or multiple funders
        require(daoToken.transferFrom(msg.sender, address(this), amountToTransfer), "CogniCraftDAO: Token transfer failed");

        emit BountyFunded(_bountyId, msg.sender, amountToTransfer);
    }


    /**
     * @dev Developers submit their AI model solution for an active bounty.
     * @param _bountyId The ID of the bounty the solution is for.
     * @param _modelURI IPFS URI pointing to the model files or relevant information.
     * @param _inferenceEndpoint An off-chain API endpoint where the model can be queried.
     * @return submissionId The ID of the new model submission.
     */
    function submitModelSolution(
        uint256 _bountyId,
        string memory _modelURI,
        string memory _inferenceEndpoint
    ) external nonReentrant whenNotPaused returns (uint256) {
        Bounty storage b = bounties[_bountyId];
        require(b.state == BountyState.Active, "CogniCraftDAO: Bounty not active for submissions");

        _submissionIdCounter++;
        uint256 currentId = _submissionIdCounter;

        modelSubmissions[currentId] = ModelSubmission({
            id: currentId,
            bountyId: _bountyId,
            submitter: msg.sender,
            modelURI: _modelURI,
            inferenceEndpoint: _inferenceEndpoint,
            state: SubmissionState.Submitted,
            oracleRequestId: bytes32(0),
            performanceScore: 0,
            modelNFTId: 0
        });

        // Optionally, mark bounty as in review only if it's the first submission, or if specific rules apply
        // For simplicity, we just allow submissions if active, and evaluations are requested separately.

        emit ModelSubmitted(currentId, _bountyId, msg.sender, _modelURI);
        return currentId;
    }

    /**
     * @dev Requests an external oracle (e.g., Chainlink) to evaluate a submitted model's performance.
     *      Callable by DAO or a designated 'Auditor' role (implied by `onlyDAO` or separate role logic).
     * @param _submissionId The ID of the model submission to evaluate.
     * @param _metricRequestData Specific data/parameters for the oracle request (e.g., benchmark dataset ID).
     */
    function requestOracleEvaluation(
        uint256 _submissionId,
        string memory _metricRequestData
    ) external nonReentrant whenNotPaused onlyDAO { // Only DAO can request evaluation
        ModelSubmission storage s = modelSubmissions[_submissionId];
        require(s.state == SubmissionState.Submitted, "CogniCraftDAO: Submission not in 'Submitted' state");
        require(oracleAddress != address(0), "CogniCraftDAO: Oracle address not set");

        s.state = SubmissionState.Evaluating;
        // In a real Chainlink integration, this would use ChainlinkClient's `requestBytes` or similar.
        bytes32 requestId = IOracle(oracleAddress).request(abi.encodePacked(_submissionId.toString(), _metricRequestData));
        s.oracleRequestId = requestId;

        emit OracleEvaluationRequested(_submissionId, requestId);
    }

    /**
     * @dev Callback function for the oracle to report evaluation results.
     *      Only the designated oracle can call this.
     * @param _requestId The request ID originally provided to the oracle.
     * @param _responseData The raw response from the oracle (expected to contain the score).
     */
    function fulfillOracleEvaluation(
        bytes32 _requestId,
        bytes memory _responseData
    ) external onlyOracle {
        uint256 submissionId;
        uint256 performanceScore;

        // Assumed parsing of _responseData from the oracle.
        // In a real scenario, this must match the oracle's output format.
        (submissionId, performanceScore) = abi.decode(_responseData, (uint256, uint256));

        ModelSubmission storage s = modelSubmissions[submissionId];
        require(s.oracleRequestId == _requestId, "CogniCraftDAO: Mismatched oracle request ID");
        require(s.state == SubmissionState.Evaluating, "CogniCraftDAO: Submission not in 'Evaluating' state");

        s.performanceScore = performanceScore;
        s.state = SubmissionState.Submitted; // Move back to Submitted, awaiting DAO action for acceptance

        emit OracleEvaluationFulfilled(submissionId, _requestId, performanceScore);
    }

    /**
     * @dev DAO accepts a submitted model, mints its CCAM-NFT, and distributes bounty rewards.
     *      This function is typically called via a DAO proposal.
     * @param _submissionId The ID of the model submission to accept.
     * @param _initialPerformanceScore The performance score verified by the DAO (or directly from oracle result).
     */
    function acceptModelSolution(
        uint256 _submissionId,
        uint256 _initialPerformanceScore
    ) external onlyDAO {
        ModelSubmission storage s = modelSubmissions[_submissionId];
        require(s.state == SubmissionState.Submitted, "CogniCraftDAO: Submission not awaiting acceptance");
        require(s.performanceScore == _initialPerformanceScore, "CogniCraftDAO: Provided score does not match oracle result");

        Bounty storage b = bounties[s.bountyId];
        require(b.state == BountyState.Active || b.state == BountyState.InReview, "CogniCraftDAO: Bounty not in active/review state");

        // Mint CCAM-NFT for the submitter
        uint256 newNFTId = aiModelNFT.mint(s.submitter, s.modelURI, s.inferenceEndpoint, s.performanceScore);
        s.modelNFTId = newNFTId;
        s.state = SubmissionState.Accepted;
        b.state = BountyState.Accepted; // Bounty completed

        // Transfer reward to submitter
        require(daoToken.transfer(s.submitter, b.rewardAmount), "CogniCraftDAO: Reward transfer failed");

        // Grant reputation to submitter
        grantReputation(s.submitter, 100); // Example: 100 reputation points for accepted model

        emit ModelAccepted(_submissionId, newNFTId, s.submitter, b.rewardAmount);
    }

    /**
     * @dev Allows the CCAM-NFT owner to update the associated model's URI or inference endpoint.
     *      Performance-related metadata updates would be triggered by new oracle evaluations,
     *      managed by `updatePerformanceScore` (called via DAO proposal).
     * @param _modelNFTId The ID of the CCAM-NFT.
     * @param _newModelURI The new IPFS URI for the model (can be empty string if not changing).
     * @param _newEndpoint The new inference endpoint (can be empty string if not changing).
     */
    function updateModelMetadata(
        uint256 _modelNFTId,
        string memory _newModelURI,
        string memory _newEndpoint
    ) external nonReentrant whenNotPaused {
        require(aiModelNFT.ownerOf(_modelNFTId) == msg.sender, "CogniCraftDAO: Not owner of this model NFT");
        require(aiModelNFT.isModelActive(_modelNFTId), "CogniCraftDAO: Model is not active");

        aiModelNFT.updateModelMetadata(_modelNFTId, _newModelURI, _newEndpoint);

        emit ModelMetadataUpdated(_modelNFTId, _newModelURI, _newEndpoint);
    }

    /**
     * @dev Allows the DAO to vote to retire a poorly performing or deprecated AI model.
     *      This function is typically called via a DAO proposal.
     * @param _modelNFTId The ID of the CCAM-NFT to retire.
     */
    function retireModel(uint256 _modelNFTId) external onlyDAO {
        require(aiModelNFT.isModelActive(_modelNFTId), "CogniCraftDAO: Model is already retired or non-existent");
        aiModelNFT.retireModel(_modelNFTId); // Set model to inactive
        // Optionally, penalize reputation of owner or refund subscribers via separate proposals
        emit ModelRetired(_modelNFTId);
    }

    // --- III. Dynamic NFTs (CCAM-NFTs) & Soulbound Tokens (Reputation) ---

    /**
     * @dev Retrieves detailed, dynamic metadata for a specific CCAM-NFT.
     *      Wrapper around `aiModelNFT.getMetadata`.
     * @param _modelNFTId The ID of the CCAM-NFT.
     * @return modelURI IPFS URI of the model.
     * @return inferenceEndpoint Off-chain inference endpoint.
     * @return performanceScore Current performance score.
     * @return isActive Whether the model is active.
     */
    function getCCAM_NFTDetails(uint256 _modelNFTId)
        external
        view
        returns (string memory modelURI, string memory inferenceEndpoint, uint256 performanceScore, bool isActive)
    {
        (modelURI, inferenceEndpoint, performanceScore, isActive) = aiModelNFT.getMetadata(_modelNFTId);
    }

    /**
     * @dev Allows the DAO or specific role to grant reputation points to a user.
     *      If the user's score transitions from 0 to >0, a non-transferable reputation badge (CRSBT) is minted.
     *      This function is typically called via a DAO proposal.
     * @param _user The address of the user to grant reputation to.
     * @param _amount The amount of reputation points to grant.
     */
    function grantReputation(address _user, uint256 _amount) public onlyDAO { // public for internal DAO calls
        require(_amount > 0, "CogniCraftDAO: Amount must be positive");
        
        uint256 oldScore = reputationScores[_user];
        reputationScores[_user] += _amount;
        
        if (oldScore == 0 && reputationScores[_user] > 0) {
            reputationSBT.mint(_user); // Mint a new SBT badge for the user
        }

        emit ReputationGranted(_user, reputationScores[_user]);
    }

    /**
     * @dev Allows the DAO or specific role to revoke reputation points from a user.
     *      If the user's score drops to 0, their non-transferable reputation badge (CRSBT) is burned.
     *      This function is typically called via a DAO proposal.
     * @param _user The address of the user to revoke reputation from.
     * @param _amount The amount of reputation points to revoke.
     */
    function revokeReputation(address _user, uint256 _amount) public onlyDAO { // public for internal DAO calls
        require(_amount > 0, "CogniCraftDAO: Amount must be positive");
        require(reputationScores[_user] >= _amount, "CogniCraftDAO: Insufficient reputation to revoke");
        
        reputationScores[_user] -= _amount;
        
        if (reputationScores[_user] == 0) {
            reputationSBT.burn(_user); // Burn the user's SBT badge
        }

        emit ReputationRevoked(_user, reputationScores[_user]);
    }

    /**
     * @dev Returns a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getReputationScore(address _user) public view returns (uint256) {
        return reputationScores[_user];
    }

    // --- IV. Model Access & Monetization ---

    /**
     * @dev Users subscribe to a model for recurring access.
     * @param _modelNFTId The ID of the model to subscribe to.
     * @param _durationMonths The number of months to subscribe for.
     */
    function subscribeToModel(uint256 _modelNFTId, uint256 _durationMonths) external nonReentrant whenNotPaused ensureModelActive(_modelNFTId) {
        require(_durationMonths > 0, "CogniCraftDAO: Subscription duration must be positive");

        uint256 totalCost = subscriptionPricePerMonth * _durationMonths;
        require(daoToken.transferFrom(msg.sender, address(this), totalCost), "CogniCraftDAO: Token transfer for subscription failed");

        ModelAccessSubscription storage sub = userSubscriptions[msg.sender][_modelNFTId];
        uint256 currentExpiry = sub.expiresAt;
        if (currentExpiry < block.timestamp) {
            currentExpiry = block.timestamp; // If expired or no previous sub, start from now
        }
        sub.expiresAt = currentExpiry + (_durationMonths * 30 days); // Approx 30 days per month

        // Accumulate royalties for the model owner and DAO
        uint256 ownerRoyalty = totalCost * (100 - DAO_ROYALTY_PERCENTAGE) / 100;
        uint256 daoRoyalty = totalCost - ownerRoyalty;

        modelAccumulatedRoyalties[_modelNFTId] += ownerRoyalty;
        require(daoToken.transfer(address(this), daoRoyalty), "CogniCraftDAO: DAO royalty transfer failed"); // Ensure DAO gets its cut instantly

        emit ModelSubscribed(msg.sender, _modelNFTId, _durationMonths, totalCost);
    }

    /**
     * @dev Users pay for a single inference request from a model.
     *      Intended for immediate, one-off access.
     * @param _modelNFTId The ID of the model for inference.
     */
    function payPerInference(uint256 _modelNFTId) external nonReentrant whenNotPaused ensureModelActive(_modelNFTId) {
        require(daoToken.transferFrom(msg.sender, address(this), payPerInferenceFee), "CogniCraftDAO: Token transfer for inference failed");

        // Accumulate royalties
        uint256 ownerRoyalty = payPerInferenceFee * (100 - DAO_ROYALTY_PERCENTAGE) / 100;
        uint256 daoRoyalty = payPerInferenceFee - ownerRoyalty;

        modelAccumulatedRoyalties[_modelNFTId] += ownerRoyalty;
        require(daoToken.transfer(address(this), daoRoyalty), "CogniCraftDAO: DAO royalty transfer failed");

        emit InferencePaid(msg.sender, _modelNFTId, payPerInferenceFee);
    }

    /**
     * @dev Allows temporary, single-transaction access to a model.
     *      The `_receiver` contract must implement `IFlashLoanReceiver` and
     *      utilize the access within the same transaction.
     * @param _modelNFTId The ID of the model to gain temporary access to.
     * @param _receiver The address of the contract to call back with access.
     * @param _data Arbitrary data for the receiver contract.
     */
    function flashLoanModelAccess(
        uint256 _modelNFTId,
        address _receiver,
        bytes memory _data
    ) external nonReentrant whenNotPaused ensureModelActive(_modelNFTId) {
        require(_receiver != address(0), "CogniCraftDAO: Receiver cannot be zero address");

        // Calculate fee in DAO tokens based on payPerInferenceFee and flashLoanFee percentage
        uint256 fee = payPerInferenceFee * flashLoanFee / 10000; // fee * percentage / 10000 (for 1% = 100)
        require(daoToken.transferFrom(msg.sender, address(this), fee), "CogniCraftDAO: Flash loan fee payment failed");

        // Grant temporary access for the duration of this transaction
        _activeFlashLoanAccess[msg.sender].add(_modelNFTId);

        // Call receiver to utilize the flash loan access
        IFlashLoanReceiver(_receiver).onFlashLoanAccess(msg.sender, _modelNFTId, fee, _data);

        // Access is automatically revoked after this call returns within the same transaction.
        _activeFlashLoanAccess[msg.sender].remove(_modelNFTId);

        // Accumulate royalties for the model owner and DAO
        uint256 ownerRoyalty = fee * (100 - DAO_ROYALTY_PERCENTAGE) / 100;
        uint256 daoRoyalty = fee - ownerRoyalty;

        modelAccumulatedRoyalties[_modelNFTId] += ownerRoyalty;
        require(daoToken.transfer(address(this), daoRoyalty), "CogniCraftDAO: DAO royalty transfer failed");

        emit FlashLoanAccessGranted(msg.sender, _modelNFTId, fee);
    }

    /**
     * @dev Allows the CCAM-NFT owner to trigger the distribution of accumulated royalties.
     *      Royalties are paid from the contract's DAO token balance.
     * @param _modelNFTId The ID of the model to distribute royalties for.
     */
    function distributeRoyalties(uint256 _modelNFTId) external nonReentrant whenNotPaused {
        address modelOwner = aiModelNFT.ownerOf(_modelNFTId);
        require(modelOwner == msg.sender, "CogniCraftDAO: Only model owner can distribute royalties");

        uint256 accumulated = modelAccumulatedRoyalties[_modelNFTId];
        require(accumulated > 0, "CogniCraftDAO: No royalties to distribute");

        modelAccumulatedRoyalties[_modelNFTId] = 0; // Reset before transfer to prevent re-entrancy issues

        require(daoToken.transfer(modelOwner, accumulated), "CogniCraftDAO: Royalty distribution failed");

        emit RoyaltiesDistributed(_modelNFTId, modelOwner, accumulated);
    }

    /**
     * @dev Checks if a specific user has access to a given model.
     * @param _modelNFTId The ID of the model.
     * @param _user The address of the user.
     * @return True if the user has active subscription or flash loan access, false otherwise.
     */
    function isModelAccessible(uint256 _modelNFTId, address _user) public view returns (bool) {
        // Check for subscription access
        if (userSubscriptions[_user][_modelNFTId].expiresAt > block.timestamp) {
            return true;
        }
        // Check for active flash loan access (within the same transaction context)
        if (_activeFlashLoanAccess[_user].contains(_modelNFTId)) {
            return true;
        }
        return false;
    }

    // --- V. Dispute Resolution & Oracle Integration ---

    /**
     * @dev Allows users to raise a dispute against an AI model's performance or integrity.
     * @param _modelNFTId The ID of the CCAM-NFT the dispute is against.
     * @param _reasonURI IPFS URI for detailed reason of the dispute.
     * @return disputeId The ID of the new dispute.
     */
    function raiseDispute(
        uint256 _modelNFTId,
        string memory _reasonURI
    ) external nonReentrant whenNotPaused returns (uint256) {
        require(aiModelNFT.exists(_modelNFTId), "CogniCraftDAO: Model NFT does not exist");
        _disputeIdCounter++;
        uint256 currentId = _disputeIdCounter;

        disputes[currentId] = Dispute({
            id: currentId,
            modelNFTId: _modelNFTId,
            disputer: msg.sender,
            reasonURI: _reasonURI,
            voteCountFor: 0,
            voteCountAgainst: 0,
            totalVotingPowerAtStart: daoToken.totalSupply(),
            startBlock: block.number,
            endBlock: block.number + votingPeriodBlocks,
            state: DisputeState.Active,
            executed: false
        });

        emit DisputeRaised(currentId, _modelNFTId, msg.sender);
        return currentId;
    }

    /**
     * @dev Allows DAO members to vote on a raised dispute.
     * @param _disputeId The ID of the dispute to vote on.
     * @param _support True to support the disputer/DAO, False to support the model owner.
     */
    function voteOnDispute(uint256 _disputeId, bool _support) external nonReentrant whenNotPaused {
        Dispute storage d = disputes[_disputeId];
        require(d.state == DisputeState.Active, "CogniCraftDAO: Dispute not active");
        require(block.number <= d.endBlock, "CogniCraftDAO: Voting period has ended");
        require(!d.hasVoted[msg.sender], "CogniCraftDAO: Already voted on this dispute");

        uint256 voterVotingPower = daoToken.balanceOf(msg.sender);
        require(voterVotingPower > 0, "CogniCraftDAO: Voter has no DAO tokens");

        d.hasVoted[msg.sender] = true;
        if (_support) {
            d.voteCountFor += voterVotingPower;
        } else {
            d.voteCountAgainst += voterVotingPower;
        }

        emit VoteCast(_disputeId, msg.sender, _support, voterVotingPower); // Re-use general VoteCast event
    }

    /**
     * @dev Resolves a dispute after the voting period ends based on DAO vote.
     *      Typically called via a DAO proposal or by anyone after vote ends.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external nonReentrant whenNotPaused {
        Dispute storage d = disputes[_disputeId];
        require(d.state != DisputeState.Resolved && d.state != DisputeState.Rejected, "CogniCraftDAO: Dispute already resolved/rejected");
        require(block.number > d.endBlock, "CogniCraftDAO: Voting period not ended yet");

        uint256 totalVotes = d.voteCountFor + d.voteCountAgainst;
        uint256 quorumThreshold = (d.totalVotingPowerAtStart * proposalQuorum) / 100; // Use same quorum as proposals

        if (totalVotes >= quorumThreshold && d.voteCountFor > d.voteCountAgainst) {
            d.state = DisputeState.Resolved;
            // Dispute supported by DAO: Further action (e.g., retireModel, revokeReputation, refund)
            // would need to be proposed and executed by the DAO based on this resolution.
        } else {
            d.state = DisputeState.Rejected;
            // Dispute not supported: No action taken against model owner.
        }

        d.executed = true; // Mark as processed
        emit DisputeResolved(_disputeId, d.state, d.executed);
    }

    /**
     * @dev Sets the address of the external oracle service.
     *      This function can only be called via a successful DAO proposal.
     * @param _newOracle The new address of the oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyDAO {
        require(_newOracle != address(0), "CogniCraftDAO: Oracle address cannot be zero");
        oracleAddress = _newOracle;
    }

    /**
     * @dev Sets the fee for flash loan access.
     *      This function can only be called via a successful DAO proposal.
     * @param _newFee The new flash loan fee in basis points (e.g., 100 for 1%).
     */
    function setFlashLoanFee(uint256 _newFee) external onlyDAO {
        require(_newFee <= 10000, "CogniCraftDAO: Flash loan fee cannot exceed 100%"); // Max 100% (10000 basis points)
        flashLoanFee = _newFee;
    }
}

/**
 * @title CogniCraftReputationSBT
 * @dev ERC721 token for representing a user's reputation badge.
 *      Non-transferable (Soulbound). Each user holds at most one such badge.
 *      The numerical reputation score is managed by the `CogniCraftDAO` contract, not in this NFT metadata.
 */
contract CogniCraftReputationSBT is ERC721URIStorage, Ownable {
    // Maps user addresses to their unique SBT tokenId
    mapping(address => uint256) private _userToTokenId;
    // Tracks the current next available tokenId for minting
    uint256 private _nextTokenId;

    /**
     * @dev Constructor initializes the ERC721 token and sets the `_daoAddress` as the owner.
     *      Only the `CogniCraftDAO` contract will be able to mint and burn these tokens.
     * @param _daoAddress The address of the CogniCraftDAO contract.
     */
    constructor(address _daoAddress) ERC721("CogniCraftReputationBadge", "CCRBT") Ownable(_daoAddress) {
        _nextTokenId = 1;
    }

    /**
     * @dev Internal function to prevent the transfer of Soulbound Tokens.
     */
    function _transfer(address, address, uint256) internal pure override {
        revert("CogniCraftReputationSBT: SBTs are non-transferable");
    }

    // Explicitly override public transfer functions to ensure non-transferability.
    function transferFrom(address, address, uint256) public pure override {
        revert("CogniCraftReputationSBT: SBTs are non-transferable");
    }

    function safeTransferFrom(address, address, uint256) public pure override {
        revert("CogniCraftReputationSBT: SBTs are non-transferable");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
        revert("CogniCraftReputationSBT: SBTs are non-transferable");
    }

    /**
     * @dev Mints a new reputation badge for a user. Callable only by the owner (CogniCraftDAO).
     *      A user can only have one badge.
     * @param _to The address of the user.
     * @return The tokenId of the minted badge.
     */
    function mint(address _to) external onlyOwner returns (uint256) {
        require(_to != address(0), "CCRBT: Cannot mint to the zero address");
        require(_userToTokenId[_to] == 0, "CCRBT: User already has a reputation badge");

        uint256 tokenId = _nextTokenId++;
        _mint(_to, tokenId);
        _userToTokenId[_to] = tokenId;
        // Set a generic URI for the badge, potentially dynamic with reputation info
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://QmcR5p1E4tX7Y0W2F8Z4m6J6B3H5N9D2L1C8V0S7Q6P5A3Z", tokenId.toString()))); 
        return tokenId;
    }

    /**
     * @dev Burns a user's reputation badge. Callable only by the owner (CogniCraftDAO).
     * @param _from The address of the user whose badge is to be burned.
     */
    function burn(address _from) external onlyOwner {
        require(_from != address(0), "CCRBT: Cannot burn from zero address");
        uint256 tokenId = _userToTokenId[_from];
        require(tokenId != 0, "CCRBT: User does not have a reputation badge to burn");

        _burn(tokenId);
        delete _userToTokenId[_from];
    }

    /**
     * @dev Returns the tokenId of a user's reputation badge.
     * @param _user The address of the user.
     * @return The tokenId, or 0 if the user does not have a badge.
     */
    function getTokenId(address _user) external view returns (uint256) {
        return _userToTokenId[_user];
    }
}

/**
 * @title CogniCraftAIModelNFT
 * @dev ERC721 token representing AI models.
 *      Dynamic: its metadata (e.g., performance score, URI) can be updated by the owner (CogniCraftDAO).
 */
contract CogniCraftAIModelNFT is ERC721URIStorage, Ownable {
    // Structure to hold dynamic data for each AI model NFT
    struct ModelData {
        string modelURI; // IPFS URI for the model files/metadata
        string inferenceEndpoint; // Off-chain API endpoint for model usage
        uint256 performanceScore; // Numerical score of the model's performance
        bool isActive; // Status of the model (active/retired)
    }

    mapping(uint256 => ModelData) private _modelData; // Maps tokenId to its ModelData
    uint256 private _nextTokenId; // Counter for unique token IDs

    /**
     * @dev Constructor initializes the ERC721 token and sets the `_daoAddress` as the owner.
     *      Only the `CogniCraftDAO` contract will be able to mint, update, and retire these NFTs.
     * @param _daoAddress The address of the CogniCraftDAO contract.
     */
    constructor(address _daoAddress) ERC721("CogniCraftAIModel", "CCAM-NFT") Ownable(_daoAddress) {
        _nextTokenId = 1;
    }

    /**
     * @dev Mints a new CCAM-NFT for an accepted AI model. Callable only by the owner (CogniCraftDAO).
     * @param _to The address of the model owner (typically the developer/submitter).
     * @param _modelURI IPFS URI for the model's data.
     * @param _inferenceEndpoint Off-chain API endpoint for the model.
     * @param _initialPerformanceScore Initial performance score verified by the DAO/oracle.
     * @return The tokenId of the minted CCAM-NFT.
     */
    function mint(
        address _to,
        string memory _modelURI,
        string memory _inferenceEndpoint,
        uint256 _initialPerformanceScore
    ) external onlyOwner returns (uint256) {
        require(_to != address(0), "CCAM-NFT: Cannot mint to the zero address");

        uint256 tokenId = _nextTokenId++;
        _mint(_to, tokenId);

        _modelData[tokenId] = ModelData({
            modelURI: _modelURI,
            inferenceEndpoint: _inferenceEndpoint,
            performanceScore: _initialPerformanceScore,
            isActive: true
        });

        // Set a generic URI for the NFT, specific token data is in _modelData
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://Qmb8t9Y2V3Q1R5T7W4H6J9K0L1M2N3B4V5C6X7Z8A9B", tokenId.toString()))); 

        return tokenId;
    }

    /**
     * @dev Updates the dynamic metadata (modelURI and inferenceEndpoint) of an AI model NFT.
     *      Callable only by the owner (CogniCraftDAO).
     * @param _tokenId The ID of the CCAM-NFT.
     * @param _newModelURI New IPFS URI for the model (empty string to keep current).
     * @param _newEndpoint New inference endpoint (empty string to keep current).
     */
    function updateModelMetadata(
        uint256 _tokenId,
        string memory _newModelURI,
        string memory _newEndpoint
    ) external onlyOwner {
        require(exists(_tokenId), "CCAM-NFT: Token does not exist");
        ModelData storage md = _modelData[_tokenId];

        if (bytes(_newModelURI).length > 0) {
            md.modelURI = _newModelURI;
        }
        if (bytes(_newEndpoint).length > 0) {
            md.inferenceEndpoint = _newEndpoint;
        }
    }

    /**
     * @dev Updates the performance score of an AI model NFT. Callable only by the owner (CogniCraftDAO).
     *      This would typically be triggered by a new oracle evaluation result.
     * @param _tokenId The ID of the CCAM-NFT.
     * @param _newScore The new performance score.
     */
    function updatePerformanceScore(uint256 _tokenId, uint256 _newScore) external onlyOwner {
        require(exists(_tokenId), "CCAM-NFT: Token does not exist");
        _modelData[_tokenId].performanceScore = _newScore;
    }

    /**
     * @dev Retires an AI model NFT, setting its active status to false. Callable only by the owner (CogniCraftDAO).
     * @param _tokenId The ID of the CCAM-NFT to retire.
     */
    function retireModel(uint256 _tokenId) external onlyOwner {
        require(exists(_tokenId), "CCAM-NFT: Token does not exist");
        _modelData[_tokenId].isActive = false;
    }

    /**
     * @dev Returns the detailed dynamic metadata for a given AI model NFT.
     * @param _tokenId The ID of the CCAM-NFT.
     * @return modelURI IPFS URI of the model.
     * @return inferenceEndpoint Off-chain inference endpoint.
     * @return performanceScore Current performance score.
     * @return isActive Whether the model is active.
     */
    function getMetadata(uint256 _tokenId)
        external
        view
        returns (string memory modelURI, string memory inferenceEndpoint, uint256 performanceScore, bool isActive)
    {
        require(exists(_tokenId), "CCAM-NFT: Token does not exist");
        ModelData storage md = _modelData[_tokenId];
        return (md.modelURI, md.inferenceEndpoint, md.performanceScore, md.isActive);
    }

    /**
     * @dev Checks if a model NFT exists and is currently active.
     * @param _tokenId The ID of the CCAM-NFT.
     * @return True if the model is active, false otherwise.
     */
    function isModelActive(uint256 _tokenId) external view returns (bool) {
        return exists(_tokenId) && _modelData[_tokenId].isActive;
    }

    /**
     * @dev Overrides the base URI for the ERC721. Specific token URIs are set per token.
     */
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://cognicraft-ai-models/";
    }
}

/**
 * @title IFlashLoanReceiver
 * @dev Interface for contracts that can receive a "flash loan" of model access from CogniCraftDAO.
 *      The receiving contract must implement this function to utilize the temporary access.
 */
interface IFlashLoanReceiver {
    /**
     * @dev Callback function invoked by `CogniCraftDAO` to grant temporary model access.
     *      This function must execute all logic requiring the flash loan access within this single call.
     * @param caller The address that initiated the flash loan.
     * @param modelNFTId The ID of the AI model NFT to which access is granted.
     * @param fee The fee paid for the flash loan.
     * @param data Arbitrary data passed from the `flashLoanModelAccess` caller.
     */
    function onFlashLoanAccess(address caller, uint256 modelNFTId, uint256 fee, bytes calldata data) external;
}
```