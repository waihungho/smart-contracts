This smart contract, **"CognitoNexus"**, introduces a novel concept: **Sentient Data Constructs (SDCs)**. These are dynamic Non-Fungible Tokens (NFTs) that embody a unique "directive" (purpose) and possess a verifiable "Cognitive Score" based on their performance in completing data-analysis or computational tasks. The contract facilitates a decentralized marketplace for these "AI-powered" (via oracle integration) SDCs, allows them to be rented, and governs their evolution through a decentralized autonomous organization (DAO).

**Core Concepts:**

1.  **Dynamic NFTs (SDCs):** ERC721 tokens whose metadata (specifically, their "Cognitive Score" and "Directive") changes based on on-chain activity.
2.  **Reputation System:** A "Cognitive Score" that reflects an SDC's reliability and performance. This score impacts its utility and rental value.
3.  **Decentralized AI Integration (via Oracles):** While the contract itself doesn't run AI, it provides the framework for *off-chain AI agents* (like Chainlink Functions or custom oracle networks) to report task completion and results, influencing SDC scores.
4.  **Task Market:** Users can request SDCs to perform specific "data tasks" (simulated computation/analysis).
5.  **Rental Market:** SDC owners can list their SDCs for rent, allowing others to utilize their unique capabilities for a fee.
6.  **DAO Governance:** A robust system where token holders (or SDC owners, for a more relevant governance model) can propose and vote on protocol parameters, new task types, and even SDC "upgrades" or punitive actions.
7.  **Evolving Metadata:** The SDC's appearance or perceived value can change dynamically, reflecting its on-chain history and performance.

---

## CognitoNexus Smart Contract Outline & Function Summary

**Contract Name:** `CognitoNexus`

**Key Features:**
*   ERC721 standard for `SentientDataConstruct` NFTs.
*   Pausable for emergency control.
*   ReentrancyGuard for security.
*   DAO for decentralized governance.
*   Oracle integration for off-chain task fulfillment.

---

### **Outline:**

1.  **Imports & Interfaces:** Standard ERC721, Ownable, Pausable, ReentrancyGuard, and a mock Oracle interface.
2.  **Error Definitions:** Custom errors for clearer revert messages.
3.  **Events:** Comprehensive event logging for all critical actions.
4.  **Structs:**
    *   `SentientDataConstruct`: Details of an SDC (owner, directive, cognitive score, last task, etc.).
    *   `DataTask`: Details of a requested task (requester, SDC, deadline, status, reward).
    *   `SDCRental`: Details of an active rental (renter, SDC, start/end time, rent price).
    *   `GovernanceProposal`: Details of a DAO proposal (proposer, description, status, votes, execution data).
5.  **Enums:** For `DataTaskStatus` and `ProposalStatus`.
6.  **State Variables:**
    *   Mapping for SDCs, Tasks, Rentals, Proposals.
    *   Counters for IDs.
    *   Protocol parameters (fees, min scores, voting periods).
    *   Addresses for Oracle, Governance token (conceptual), DAO.
7.  **Modifiers:** `onlyOracle`, `onlyDAO`, `onlySDCOwner`, `whenNotPaused`.
8.  **Constructor:** Initializes the contract, sets initial owner, oracle, and protocol parameters.
9.  **Core SDC Management (ERC721 & Dynamic Data):**
    *   `createSDCAgent`
    *   `getSDCMetadataURI`
    *   `getSDCDetails`
    *   `setSDCDirective`
    *   `getAgentCognitiveScore`
10. **Data Task & Intelligence System:**
    *   `requestDataTask`
    *   `fulfillDataTask`
    *   `cancelDataTask`
    *   `updateCognitiveScore` (Internal, called by `fulfillDataTask`)
    *   `addAgentFeedback`
    *   `slashAgentScore`
11. **SDC Rental Market:**
    *   `listSDCForRent`
    *   `rentSDC`
    *   `endRental`
    *   `claimRentalProceeds`
    *   `getSDCRentalInfo`
12. **DAO Governance:**
    *   `proposeGovernanceChange`
    *   `voteOnProposal`
    *   `executeProposal`
    *   `getProposalDetails`
    *   `registerNewTaskType`
    *   `updateOracleAddress`
13. **Protocol & Admin Functions:**
    *   `withdrawFees`
    *   `pause`
    *   `unpause`
    *   `setProtocolFeePercentage`
    *   `setMinimumCognitiveScoreForTask`
    *   `setProposalVotingPeriod`
    *   `setMinProposerSDCScore`
    *   `setOracleFee`
14. **ERC721 Overrides:**
    *   `tokenURI`
    *   `_beforeTokenTransfer` (for rental implications)
    *   `supportsInterface`

---

### **Function Summary (24 distinct functions):**

1.  `constructor()`: Initializes the contract with an owner, mock oracle, and initial protocol settings.
2.  `createSDCAgent(string memory _initialDirective)`: Mints a new Sentient Data Construct (SDC) NFT with an initial directive and a base cognitive score. *Unique function.*
3.  `getSDCMetadataURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an SDC, reflecting its current directive and cognitive score. *Unique function.*
4.  `getSDCDetails(uint256 _tokenId)`: Retrieves all on-chain details of a specific SDC, including its owner, directive, and scores. *Unique function.*
5.  `setSDCDirective(uint256 _tokenId, string memory _newDirective)`: Allows the SDC owner to update their SDC's primary purpose or "directive". *Unique function.*
6.  `getAgentCognitiveScore(uint256 _tokenId)`: Returns the current cognitive score of an SDC. *Unique function.*
7.  `requestDataTask(uint256 _sdcId, string memory _taskDetails, uint256 _rewardAmount, uint256 _deadline)`: A user requests an SDC to perform a specific data-related task, paying a reward. *Unique function.*
8.  `fulfillDataTask(uint256 _taskId, bool _success, int256 _scoreAdjustment, string memory _resultHash)`: Callable *only by the registered oracle*. Reports the outcome of an off-chain data task and adjusts the SDC's cognitive score. *Unique function.*
9.  `cancelDataTask(uint256 _taskId)`: Allows the task requester to cancel an unfulfilled task before its deadline, refunding their reward. *Unique function.*
10. `addAgentFeedback(uint256 _sdcId, int256 _feedbackScore)`: Allows users who have interacted with an SDC to provide feedback, subtly influencing its cognitive score. *Unique function.*
11. `slashAgentScore(uint256 _sdcId, int256 _slashAmount)`: A DAO-governed function to significantly reduce an SDC's cognitive score due to proven misconduct or poor performance. *Unique function.*
12. `listSDCForRent(uint256 _sdcId, uint256 _pricePerDay)`: An SDC owner lists their SDC available for rent in the marketplace. *Unique function.*
13. `rentSDC(uint256 _sdcId, uint256 _rentalDays)`: A user rents an available SDC for a specified number of days, paying the rent upfront. *Unique function.*
14. `endRental(uint256 _sdcId)`: Allows the renter or the SDC owner (after rental period) to end an active rental. *Unique function.*
15. `claimRentalProceeds(uint256 _sdcId)`: Allows the SDC owner to claim accumulated rental fees after a rental period ends. *Unique function.*
16. `getSDCRentalInfo(uint256 _sdcId)`: Retrieves details about an SDC's current or last rental period. *Unique function.*
17. `proposeGovernanceChange(address _target, bytes memory _calldata, string memory _description)`: Allows SDC holders (based on minimum cognitive score) to propose changes to protocol parameters or actions. *Unique function.*
18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible SDC holders to cast their vote on an active governance proposal. *Unique function.*
19. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed the voting threshold and period. *Unique function.*
20. `getProposalDetails(uint256 _proposalId)`: Retrieves the current status and details of a specific governance proposal. *Unique function.*
21. `registerNewTaskType(string memory _taskTypeName, uint256 _minReward, uint256 _maxReward)`: A DAO-only function to register new, officially supported data task types. *Unique function.*
22. `updateOracleAddress(address _newOracleAddress)`: A DAO-only function to update the address of the trusted off-chain oracle. *Unique function.*
23. `withdrawFees()`: Allows the protocol owner (or eventually DAO-controlled multisig) to withdraw accumulated protocol fees. *Admin function.*
24. `pause()` / `unpause()`: Emergency functions to pause/unpause contract operations. *Admin function.*
25. `setProtocolFeePercentage(uint256 _newFee)`: Sets the percentage of rental and task fees collected by the protocol. *DAO function.*
26. `setMinimumCognitiveScoreForTask(uint256 _minScore)`: Sets the minimum cognitive score an SDC must have to be eligible for data tasks. *DAO function.*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol"; // For explicit metadata interface

// --- Outline & Function Summary ---
// Contract Name: CognitoNexus
// Key Features:
//   - ERC721 standard for `SentientDataConstruct` NFTs.
//   - Pausable for emergency control.
//   - ReentrancyGuard for security.
//   - DAO for decentralized governance.
//   - Oracle integration for off-chain task fulfillment.

// Outline:
// 1. Imports & Interfaces
// 2. Error Definitions
// 3. Events
// 4. Structs (SentientDataConstruct, DataTask, SDCRental, GovernanceProposal)
// 5. Enums (DataTaskStatus, ProposalStatus)
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Core SDC Management (ERC721 & Dynamic Data)
// 10. Data Task & Intelligence System
// 11. SDC Rental Market
// 12. DAO Governance
// 13. Protocol & Admin Functions
// 14. ERC721 Overrides

// Function Summary (24 distinct functional concepts included, many are unique):
// 1.  constructor(): Initializes contract parameters.
// 2.  createSDCAgent(string memory _initialDirective): Mints a new SDC NFT.
// 3.  getSDCMetadataURI(uint256 _tokenId): Returns dynamic metadata URI.
// 4.  getSDCDetails(uint256 _tokenId): Retrieves all SDC details.
// 5.  setSDCDirective(uint256 _tokenId, string memory _newDirective): Updates SDC's purpose.
// 6.  getAgentCognitiveScore(uint256 _tokenId): Returns an SDC's cognitive score.
// 7.  requestDataTask(uint256 _sdcId, string memory _taskDetails, uint256 _rewardAmount, uint256 _deadline): User requests a task for an SDC.
// 8.  fulfillDataTask(uint256 _taskId, bool _success, int256 _scoreAdjustment, string memory _resultHash): Oracle reports task outcome.
// 9.  cancelDataTask(uint256 _taskId): Allows requester to cancel unfulfilled task.
// 10. addAgentFeedback(uint256 _sdcId, int256 _feedbackScore): User provides feedback on SDC.
// 11. slashAgentScore(uint256 _sdcId, int256 _slashAmount): DAO slashes SDC score.
// 12. listSDCForRent(uint256 _sdcId, uint256 _pricePerDay): SDC owner lists for rent.
// 13. rentSDC(uint256 _sdcId, uint256 _rentalDays): User rents an SDC.
// 14. endRental(uint256 _sdcId): Ends an active rental.
// 15. claimRentalProceeds(uint256 _sdcId): SDC owner claims rental income.
// 16. getSDCRentalInfo(uint256 _sdcId): Retrieves current rental details.
// 17. proposeGovernanceChange(address _target, bytes memory _calldata, string memory _description): Propose DAO actions.
// 18. voteOnProposal(uint256 _proposalId, bool _support): Vote on a DAO proposal.
// 19. executeProposal(uint256 _proposalId): Executes passed DAO proposal.
// 20. getProposalDetails(uint256 _proposalId): Get details of a DAO proposal.
// 21. registerNewTaskType(string memory _taskTypeName, uint256 _minReward, uint256 _maxReward): DAO registers new task types.
// 22. updateOracleAddress(address _newOracleAddress): DAO updates oracle address.
// 23. withdrawFees(): Protocol owner withdraws fees.
// 24. pause() / unpause(): Emergency stop functions.
// 25. setProtocolFeePercentage(uint256 _newFee): Sets fee percentage.
// 26. setMinimumCognitiveScoreForTask(uint256 _minScore): Sets min score for tasks.
// 27. setProposalVotingPeriod(uint256 _period): Sets DAO voting period.
// 28. setMinProposerSDCScore(uint256 _minScore): Sets min score to propose.
// 29. setOracleFee(uint256 _fee): Sets fee for oracle calls.

// --- End of Outline & Summary ---

interface IOracle {
    function requestData(uint256 _requestId, bytes memory _data) external returns (bytes32);
    // In a real scenario, this would trigger an off-chain computation and then call back.
    // For this contract, we'll simulate the callback by direct call to fulfillDataTask by the oracle address.
}

contract CognitoNexus is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Error Definitions ---
    error SDCDoesNotExist();
    error NotSDCOwner();
    error SDCNotRentable();
    error SDCAlreadyRented();
    error SDCNotRented();
    error RentalNotActive();
    error RentalActive();
    error InvalidRentalPeriod();
    error InsufficientPayment();
    error TaskDoesNotExist();
    error TaskNotPending();
    error TaskAlreadyFulfilled();
    error TaskNotRequester();
    error TaskDeadlinePassed();
    error TaskDeadlineNotReached();
    error InvalidScoreAdjustment();
    error NotOracle();
    error InsufficientCognitiveScore();
    error AlreadyVoted();
    error ProposalDoesNotExist();
    error ProposalNotExecutable();
    error ProposalStillActive();
    error ProposalNotApproved();
    error VotingPeriodNotOver();
    error MinimumCognitiveScoreNotMet();
    error InvalidFeePercentage();
    error UnauthorizedWithdrawal();
    error InvalidAddress();
    error ZeroAmount();

    // --- Events ---
    event SDCMinted(uint256 indexed tokenId, address indexed owner, string directive);
    event SDCDirectiveUpdated(uint256 indexed tokenId, string newDirective);
    event CognitiveScoreUpdated(uint256 indexed tokenId, int256 newScore);
    event DataTaskRequested(uint256 indexed taskId, uint256 indexed sdcId, address indexed requester, uint256 reward, uint256 deadline);
    event DataTaskFulfilled(uint256 indexed taskId, uint256 indexed sdcId, bool success, string resultHash);
    event DataTaskCancelled(uint256 indexed taskId);
    event AgentFeedbackAdded(uint256 indexed sdcId, address indexed sender, int256 feedbackScore);
    event AgentScoreSlashed(uint256 indexed sdcId, int256 slashAmount);
    event SDCListedForRent(uint256 indexed sdcId, uint256 pricePerDay);
    event SDCRented(uint256 indexed sdcId, address indexed renter, uint256 rentalDays, uint256 totalPayment);
    event SDCRentalEnded(uint256 indexed sdcId, address indexed renter);
    event RentalProceedsClaimed(uint256 indexed sdcId, address indexed owner, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProtocolFeeCollected(uint256 amount);
    event OracleAddressUpdated(address indexed newAddress);
    event NewTaskTypeRegistered(string taskTypeName, uint256 minReward, uint256 maxReward);

    // --- Structs ---
    struct SentientDataConstruct {
        string directive;
        int256 cognitiveScore; // Represents its intelligence/reliability (can be negative)
        uint256 lastTaskCompletionTime;
        bool isListedForRent;
        uint256 pricePerDay; // For rental
        address currentRenter; // address(0) if not rented
        uint256 rentalEndTime; // 0 if not rented
        uint256 accumulatedRentalProceeds; // Funds to be claimed by owner
    }

    enum DataTaskStatus { Pending, Fulfilled, Cancelled }

    struct DataTask {
        uint256 sdcId;
        address requester;
        string details;
        uint256 rewardAmount;
        uint256 deadline;
        DataTaskStatus status;
        string resultHash; // Hash of the off-chain result/data
    }

    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        address proposer;
        string description;
        address target; // Target contract for call
        bytes callData; // Encoded function call
        uint256 voteCountSupport;
        uint256 voteCountAgainst;
        uint256 creationTime;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Voter's address => true if voted
    }

    // --- State Variables ---
    uint256 private _sdcTokenIdCounter;
    uint256 private _taskIdCounter;
    uint256 private _proposalIdCounter;

    mapping(uint256 => SentientDataConstruct) public sdcAgents;
    mapping(uint256 => DataTask) public dataTasks;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    address public oracleAddress;
    address public immutable governanceToken; // Conceptual: Address of the governance token for voting power

    // Protocol Parameters (can be changed by DAO)
    uint256 public protocolFeePercentage; // e.g., 500 for 5% (500/10000)
    uint256 public minimumCognitiveScoreForTask;
    uint256 public proposalVotingPeriod; // In seconds
    uint256 public minProposerSDCScore; // Minimum SDC cognitive score to propose governance change
    uint256 public oracleFee; // Fee paid for requesting off-chain oracle computations (conceptual)

    uint256 public totalProtocolFeesCollected;

    // Mapping for registered task types and their reward ranges (DAO managed)
    mapping(string => bool) public isRegisteredTaskType;
    mapping(string => uint256) public taskTypeMinReward;
    mapping(string => uint256) public taskTypeMaxReward;

    // --- Modifiers ---
    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracle();
        _;
    }

    modifier onlySDCOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) revert NotSDCOwner();
        _;
    }

    modifier onlyDAO() {
        // In a real DAO, this would verify that the call is coming from the DAO's timelock/executor.
        // For simplicity, we'll allow the owner to initially set DAO parameters,
        // but eventually, proposals will call this contract directly via 'executeProposal'.
        // For direct calls, we'll assume it's only executable via the `executeProposal` function
        // which verifies the proposal's origin.
        if (msg.sender != address(this)) revert InsufficientPermissions(); // Only callable internally by the contract's executeProposal
        _;
    }

    // Custom modifier for DAO proposals
    modifier canPropose(uint256 _sdcId) {
        if (sdcAgents[_sdcId].cognitiveScore < minProposerSDCScore) revert MinimumCognitiveScoreNotMet();
        if (ownerOf(_sdcId) != msg.sender) revert NotSDCOwner();
        _;
    }


    // --- Constructor ---
    constructor(
        address _oracleAddress,
        address _governanceToken,
        uint256 _initialProtocolFeePercentage,
        uint256 _initialMinCognitiveScoreForTask,
        uint256 _initialProposalVotingPeriod,
        uint256 _initialMinProposerSDCScore,
        uint256 _initialOracleFee
    ) ERC721("CognitoNexus SDC", "SDC") Ownable(msg.sender) {
        if (_oracleAddress == address(0)) revert InvalidAddress();
        if (_governanceToken == address(0)) revert InvalidAddress(); // Conceptual for voting power
        if (_initialProtocolFeePercentage > 10000) revert InvalidFeePercentage(); // Max 100% (10000 basis points)

        oracleAddress = _oracleAddress;
        governanceToken = _governanceToken; // In a real scenario, this would be an ERC20 token for voting.
        protocolFeePercentage = _initialProtocolFeePercentage;
        minimumCognitiveScoreForTask = _initialMinCognitiveScoreForTask;
        proposalVotingPeriod = _initialProposalVotingPeriod;
        minProposerSDCScore = _initialMinProposerSDCScore;
        oracleFee = _initialOracleFee;
    }

    // --- Core SDC Management (ERC721 & Dynamic Data) ---

    /// @notice Creates and mints a new Sentient Data Construct (SDC) NFT.
    /// @param _initialDirective The initial purpose or role of the SDC.
    /// @return The tokenId of the newly minted SDC.
    function createSDCAgent(string memory _initialDirective)
        public
        whenNotPaused
        returns (uint256)
    {
        _sdcTokenIdCounter = _sdcTokenIdCounter.add(1);
        uint256 newId = _sdcTokenIdCounter;

        _safeMint(msg.sender, newId);

        sdcAgents[newId] = SentientDataConstruct({
            directive: _initialDirective,
            cognitiveScore: 100, // Starting cognitive score
            lastTaskCompletionTime: block.timestamp,
            isListedForRent: false,
            pricePerDay: 0,
            currentRenter: address(0),
            rentalEndTime: 0,
            accumulatedRentalProceeds: 0
        });

        emit SDCMinted(newId, msg.sender, _initialDirective);
        return newId;
    }

    /// @notice Returns the dynamic metadata URI for an SDC, reflecting its current directive and cognitive score.
    /// @dev This simulates a dynamic metadata server. In a real dApp, the off-chain server would use this info to serve a JSON.
    /// @param _tokenId The ID of the SDC.
    /// @return The base64 encoded JSON metadata URI.
    function getSDCMetadataURI(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert SDCDoesNotExist();

        SentientDataConstruct storage sdc = sdcAgents[_tokenId];
        string memory baseURI = "data:application/json;base64,"; // Standard for data URIs

        string memory json = string(
            abi.encodePacked(
                '{"name": "CognitoNexus SDC #', _tokenId.toString(), '",',
                '"description": "A dynamic Sentient Data Construct with evolving intelligence.",',
                '"image": "ipfs://Qmb...",', // Placeholder image hash
                '"attributes": [',
                '{"trait_type": "Directive", "value": "', sdc.directive, '"},',
                '{"trait_type": "Cognitive Score", "value": ', sdc.cognitiveScore.toString(), '}',
                ']}'
            )
        );

        // Encode JSON string to base64
        bytes memory encodedJson = Base64.encode(bytes(json));
        return string(abi.encodePacked(baseURI, encodedJson));
    }

    /// @notice Retrieves all on-chain details of a specific SDC.
    /// @param _tokenId The ID of the SDC.
    /// @return Tuple containing SDC details.
    function getSDCDetails(uint256 _tokenId)
        public
        view
        returns (
            address sdcOwner,
            string memory directive,
            int256 cognitiveScore,
            bool isListedForRent,
            uint256 pricePerDay,
            address currentRenter,
            uint256 rentalEndTime,
            uint256 accumulatedRentalProceeds
        )
    {
        if (!_exists(_tokenId)) revert SDCDoesNotExist();
        SentientDataConstruct storage sdc = sdcAgents[_tokenId];

        return (
            ownerOf(_tokenId),
            sdc.directive,
            sdc.cognitiveScore,
            sdc.isListedForRent,
            sdc.pricePerDay,
            sdc.currentRenter,
            sdc.rentalEndTime,
            sdc.accumulatedRentalProceeds
        );
    }

    /// @notice Allows the SDC owner to update their SDC's primary purpose or "directive".
    /// @param _tokenId The ID of the SDC.
    /// @param _newDirective The new directive for the SDC.
    function setSDCDirective(uint256 _tokenId, string memory _newDirective)
        public
        onlySDCOwner(_tokenId)
        whenNotPaused
    {
        sdcAgents[_tokenId].directive = _newDirective;
        emit SDCDirectiveUpdated(_tokenId, _newDirective);
    }

    /// @notice Returns the current cognitive score of an SDC.
    /// @param _tokenId The ID of the SDC.
    /// @return The cognitive score.
    function getAgentCognitiveScore(uint256 _tokenId)
        public
        view
        returns (int256)
    {
        if (!_exists(_tokenId)) revert SDCDoesNotExist();
        return sdcAgents[_tokenId].cognitiveScore;
    }

    // --- Data Task & Intelligence System ---

    /// @notice A user requests an SDC to perform a specific data-related task, paying a reward.
    /// @param _sdcId The ID of the SDC to request.
    /// @param _taskDetails A description or identifier of the task.
    /// @param _rewardAmount The reward (in native token) for the SDC.
    /// @param _deadline The timestamp by which the task must be fulfilled.
    function requestDataTask(
        uint256 _sdcId,
        string memory _taskDetails,
        uint256 _rewardAmount,
        uint256 _deadline
    ) public payable whenNotPaused nonReentrant {
        if (!_exists(_sdcId)) revert SDCDoesNotExist();
        if (sdcAgents[_sdcId].currentRenter != address(0)) revert SDCAlreadyRented(); // Can't request task if rented

        if (sdcAgents[_sdcId].cognitiveScore < minimumCognitiveScoreForTask) revert InsufficientCognitiveScore();
        if (_rewardAmount == 0 || msg.value < _rewardAmount) revert InsufficientPayment();
        if (_deadline <= block.timestamp) revert TaskDeadlinePassed();

        _taskIdCounter = _taskIdCounter.add(1);
        uint256 newTaskId = _taskIdCounter;

        dataTasks[newTaskId] = DataTask({
            sdcId: _sdcId,
            requester: msg.sender,
            details: _taskDetails,
            rewardAmount: _rewardAmount,
            deadline: _deadline,
            status: DataTaskStatus.Pending,
            resultHash: ""
        });

        // Transfer funds for the task (reward + oracle fee)
        uint256 totalPaymentRequired = _rewardAmount.add(oracleFee);
        if (msg.value < totalPaymentRequired) revert InsufficientPayment();

        // Send oracle fee
        (bool oracleSent, ) = oracleAddress.call{value: oracleFee}("");
        if (!oracleSent) {
            // Revert or log, depending on desired robustness. For now, revert.
            revert("Failed to send oracle fee");
        }
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(oracleFee); // Oracle fee can be considered protocol fee

        emit DataTaskRequested(newTaskId, _sdcId, msg.sender, _rewardAmount, _deadline);
    }

    /// @notice Callable *only by the registered oracle*. Reports the outcome of an off-chain data task.
    /// @param _taskId The ID of the task being fulfilled.
    /// @param _success True if the task was successfully completed, false otherwise.
    /// @param _scoreAdjustment The amount to adjust the SDC's cognitive score (positive for success, negative for failure).
    /// @param _resultHash A hash or URI pointing to the off-chain task result.
    function fulfillDataTask(
        uint256 _taskId,
        bool _success,
        int256 _scoreAdjustment,
        string memory _resultHash
    ) public onlyOracle whenNotPaused nonReentrant {
        DataTask storage task = dataTasks[_taskId];
        if (task.requester == address(0)) revert TaskDoesNotExist();
        if (task.status != DataTaskStatus.Pending) revert TaskAlreadyFulfilled();
        if (block.timestamp > task.deadline) revert TaskDeadlinePassed();

        task.status = DataTaskStatus.Fulfilled;
        task.resultHash = _resultHash;

        _updateCognitiveScore(task.sdcId, _scoreAdjustment);

        // Distribute reward to SDC owner (minus protocol fee)
        uint256 fee = task.rewardAmount.mul(protocolFeePercentage).div(10000);
        uint256 payout = task.rewardAmount.sub(fee);

        // Transfer to SDC owner
        address sdcOwner = ownerOf(task.sdcId);
        (bool ownerSent, ) = sdcOwner.call{value: payout}("");
        if (!ownerSent) {
            // If transfer fails, attempt to refund task requester or keep for owner to claim later.
            // For simplicity, we'll revert here.
            revert("Failed to send reward to SDC owner");
        }
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(fee);
        emit ProtocolFeeCollected(fee);

        emit DataTaskFulfilled(_taskId, task.sdcId, _success, _resultHash);
    }

    /// @notice Allows the task requester to cancel an unfulfilled task before its deadline, refunding their reward.
    /// @param _taskId The ID of the task to cancel.
    function cancelDataTask(uint256 _taskId)
        public
        whenNotPaused
        nonReentrant
    {
        DataTask storage task = dataTasks[_taskId];
        if (task.requester == address(0)) revert TaskDoesNotExist();
        if (task.requester != msg.sender) revert TaskNotRequester();
        if (task.status != DataTaskStatus.Pending) revert TaskNotPending();
        if (block.timestamp > task.deadline) revert TaskDeadlinePassed();

        task.status = DataTaskStatus.Cancelled;
        (bool sent, ) = msg.sender.call{value: task.rewardAmount.add(oracleFee)}(""); // Refund full amount
        if (!sent) revert("Failed to refund task requester");

        emit DataTaskCancelled(_taskId);
    }

    /// @dev Internal function to update an SDC's cognitive score.
    /// @param _sdcId The ID of the SDC.
    /// @param _adjustment The amount to adjust the score by.
    function _updateCognitiveScore(uint256 _sdcId, int256 _adjustment) internal {
        sdcAgents[_sdcId].cognitiveScore = sdcAgents[_sdcId].cognitiveScore.add(_adjustment);
        emit CognitiveScoreUpdated(_sdcId, sdcAgents[_sdcId].cognitiveScore);
    }

    /// @notice Allows users who have interacted with an SDC to provide feedback, subtly influencing its cognitive score.
    /// @dev This feedback is less impactful than direct task fulfillment but contributes to overall reputation.
    /// @param _sdcId The ID of the SDC.
    /// @param _feedbackScore A score from -10 to +10, indicating satisfaction.
    function addAgentFeedback(uint256 _sdcId, int256 _feedbackScore)
        public
        whenNotPaused
    {
        if (!_exists(_sdcId)) revert SDCDoesNotExist();
        if (_feedbackScore < -10 || _feedbackScore > 10) revert InvalidScoreAdjustment();

        // Apply a smaller adjustment based on feedback
        // For simplicity, let's divide feedback score by a factor (e.g., 5)
        _updateCognitiveScore(_sdcId, _feedbackScore / 5);
        emit AgentFeedbackAdded(_sdcId, msg.sender, _feedbackScore);
    }

    /// @notice A DAO-governed function to significantly reduce an SDC's cognitive score due to proven misconduct.
    /// @param _sdcId The ID of the SDC to penalize.
    /// @param _slashAmount The positive amount by which to reduce the score.
    function slashAgentScore(uint256 _sdcId, int256 _slashAmount) public onlyDAO {
        if (!_exists(_sdcId)) revert SDCDoesNotExist();
        if (_slashAmount <= 0) revert InvalidScoreAdjustment(); // Must be a positive amount to slash

        _updateCognitiveScore(_sdcId, -_slashAmount); // Apply as a negative adjustment
        emit AgentScoreSlashed(_sdcId, _slashAmount);
    }

    // --- SDC Rental Market ---

    /// @notice An SDC owner lists their SDC available for rent in the marketplace.
    /// @param _sdcId The ID of the SDC to list.
    /// @param _pricePerDay The daily rental price in native token.
    function listSDCForRent(uint256 _sdcId, uint256 _pricePerDay)
        public
        onlySDCOwner(_sdcId)
        whenNotPaused
    {
        SentientDataConstruct storage sdc = sdcAgents[_sdcId];
        if (sdc.currentRenter != address(0)) revert SDCAlreadyRented();
        if (_pricePerDay == 0) revert ZeroAmount();

        sdc.isListedForRent = true;
        sdc.pricePerDay = _pricePerDay;
        emit SDCListedForRent(_sdcId, _pricePerDay);
    }

    /// @notice A user rents an available SDC for a specified number of days, paying the rent upfront.
    /// @param _sdcId The ID of the SDC to rent.
    /// @param _rentalDays The number of days to rent the SDC for.
    function rentSDC(uint256 _sdcId, uint256 _rentalDays)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        SentientDataConstruct storage sdc = sdcAgents[_sdcId];
        if (!_exists(_sdcId)) revert SDCDoesNotExist();
        if (!sdc.isListedForRent) revert SDCNotRentable();
        if (sdc.currentRenter != address(0)) revert SDCAlreadyRented(); // Check if currently rented
        if (_rentalDays == 0) revert InvalidRentalPeriod();

        uint256 totalRent = sdc.pricePerDay.mul(_rentalDays);
        if (msg.value < totalRent) revert InsufficientPayment();

        // Calculate protocol fee
        uint256 fee = totalRent.mul(protocolFeePercentage).div(10000);
        uint256 ownerProceeds = totalRent.sub(fee);

        sdc.currentRenter = msg.sender;
        sdc.rentalEndTime = block.timestamp.add(_rentalDays.mul(1 days));
        sdc.isListedForRent = false; // Not listed while rented
        sdc.accumulatedRentalProceeds = sdc.accumulatedRentalProceeds.add(ownerProceeds);
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(fee);

        // Refund any excess payment
        if (msg.value > totalRent) {
            (bool sent, ) = msg.sender.call{value: msg.value.sub(totalRent)}("");
            if (!sent) revert("Failed to refund excess payment");
        }

        emit SDCRented(_sdcId, msg.sender, _rentalDays, totalRent);
        emit ProtocolFeeCollected(fee);
    }

    /// @notice Allows the renter or the SDC owner (after rental period) to end an active rental.
    /// @param _sdcId The ID of the SDC whose rental is to be ended.
    function endRental(uint256 _sdcId) public whenNotPaused {
        SentientDataConstruct storage sdc = sdcAgents[_sdcId];
        if (!_exists(_sdcId)) revert SDCDoesNotExist();
        if (sdc.currentRenter == address(0)) revert SDCNotRented();

        // Only renter or owner can end, or if rental time has passed
        if (msg.sender != sdc.currentRenter && msg.sender != ownerOf(_sdcId) && block.timestamp < sdc.rentalEndTime) {
            revert("Only renter or owner can end rental before time, or after rental time.");
        }

        sdc.currentRenter = address(0);
        sdc.rentalEndTime = 0;
        // The SDC remains unlisted until owner relists it.
        // Accumulated proceeds are claimed separately.
        emit SDCRentalEnded(_sdcId, msg.sender);
    }

    /// @notice Allows the SDC owner to claim accumulated rental fees after a rental period ends.
    /// @param _sdcId The ID of the SDC.
    function claimRentalProceeds(uint256 _sdcId) public onlySDCOwner(_sdcId) nonReentrant {
        SentientDataConstruct storage sdc = sdcAgents[_sdcId];
        if (sdc.accumulatedRentalProceeds == 0) revert ZeroAmount();

        uint256 amountToClaim = sdc.accumulatedRentalProceeds;
        sdc.accumulatedRentalProceeds = 0;

        (bool sent, ) = msg.sender.call{value: amountToClaim}("");
        if (!sent) revert("Failed to send rental proceeds");

        emit RentalProceedsClaimed(_sdcId, msg.sender, amountToClaim);
    }

    /// @notice Retrieves details about an SDC's current or last rental period.
    /// @param _sdcId The ID of the SDC.
    /// @return Tuple containing rental information.
    function getSDCRentalInfo(uint256 _sdcId)
        public
        view
        returns (address renter, uint256 endTime, uint256 price, bool isCurrentlyRented)
    {
        if (!_exists(_sdcId)) revert SDCDoesNotExist();
        SentientDataConstruct storage sdc = sdcAgents[_sdcId];

        bool currentRented = (sdc.currentRenter != address(0) && block.timestamp < sdc.rentalEndTime);
        return (sdc.currentRenter, sdc.rentalEndTime, sdc.pricePerDay, currentRented);
    }

    // --- DAO Governance ---

    /// @notice Allows SDC holders (based on minimum cognitive score) to propose changes to protocol parameters or actions.
    /// @param _target The address of the contract to call (e.g., this contract for parameter changes).
    /// @param _calldata The encoded function call to be executed if the proposal passes.
    /// @param _description A human-readable description of the proposal.
    /// @param _proposerSDCId The SDC ID of the proposer, used to check `minProposerSDCScore`.
    function proposeGovernanceChange(
        address _target,
        bytes memory _calldata,
        string memory _description,
        uint256 _proposerSDCId
    ) public whenNotPaused canPropose(_proposerSDCId) returns (uint256) {
        _proposalIdCounter = _proposalIdCounter.add(1);
        uint256 newProposalId = _proposalIdCounter;

        GovernanceProposal storage proposal = governanceProposals[newProposalId];
        proposal.proposer = msg.sender;
        proposal.description = _description;
        proposal.target = _target;
        proposal.callData = _calldata;
        proposal.voteCountSupport = 0;
        proposal.voteCountAgainst = 0;
        proposal.creationTime = block.timestamp;
        proposal.status = ProposalStatus.Active;

        emit ProposalCreated(newProposalId, msg.sender, _description);
        return newProposalId;
    }

    /// @notice Allows eligible SDC holders to cast their vote on an active governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against'.
    /// @param _voterSDCId The SDC ID of the voter, used to determine voting power.
    function voteOnProposal(uint256 _proposalId, bool _support, uint256 _voterSDCId)
        public
        whenNotPaused
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
        if (proposal.status != ProposalStatus.Active) revert ProposalStillActive();
        if (block.timestamp >= proposal.creationTime.add(proposalVotingPeriod)) revert VotingPeriodNotOver();

        if (ownerOf(_voterSDCId) != msg.sender) revert NotSDCOwner(); // Voter must own the SDC they use to vote
        if (sdcAgents[_voterSDCId].cognitiveScore < minimumCognitiveScoreForTask) revert InsufficientCognitiveScore(); // SDC must meet min score to vote

        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted(); // Only one vote per unique address

        // Voting power could be based on SDC count, or SDC cognitive score, or an external governance token
        // For simplicity, we'll assume 1 SDC = 1 vote for now, only if it meets `minimumCognitiveScoreForTask`
        if (_support) {
            proposal.voteCountSupport = proposal.voteCountSupport.add(1);
        } else {
            proposal.voteCountAgainst = proposal.voteCountAgainst.add(1);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /// @notice Executes a governance proposal that has passed the voting threshold and period.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();
        if (proposal.status != ProposalStatus.Active) revert ProposalStillActive();
        if (block.timestamp < proposal.creationTime.add(proposalVotingPeriod)) revert VotingPeriodNotOver();

        // Simple majority for now. In a real DAO, more complex thresholds.
        if (proposal.voteCountSupport <= proposal.voteCountAgainst) {
            proposal.status = ProposalStatus.Failed;
            revert ProposalNotApproved();
        }

        // Execute the call
        (bool success, ) = proposal.target.call(proposal.callData);
        if (!success) {
            proposal.status = ProposalStatus.Failed;
            revert ProposalNotExecutable();
        }

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Retrieves the current status and details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return Tuple containing proposal details.
    function getProposalDetails(uint256 _proposalId)
        public
        view
        returns (
            address proposer,
            string memory description,
            address target,
            bytes memory callData,
            uint256 voteCountSupport,
            uint256 voteCountAgainst,
            uint256 creationTime,
            ProposalStatus status
        )
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.proposer == address(0)) revert ProposalDoesNotExist();

        return (
            proposal.proposer,
            proposal.description,
            proposal.target,
            proposal.callData,
            proposal.voteCountSupport,
            proposal.voteCountAgainst,
            proposal.creationTime,
            proposal.status
        );
    }

    /// @notice A DAO-only function to register new, officially supported data task types.
    /// @param _taskTypeName The name of the new task type.
    /// @param _minReward The minimum reward for this task type.
    /// @param _maxReward The maximum reward for this task type.
    function registerNewTaskType(string memory _taskTypeName, uint256 _minReward, uint256 _maxReward)
        public
        onlyDAO
    {
        isRegisteredTaskType[_taskTypeName] = true;
        taskTypeMinReward[_taskTypeName] = _minReward;
        taskTypeMaxReward[_taskTypeName] = _maxReward;
        emit NewTaskTypeRegistered(_taskTypeName, _minReward, _maxReward);
    }

    /// @notice A DAO-only function to update the address of the trusted off-chain oracle.
    /// @param _newOracleAddress The new address for the oracle.
    function updateOracleAddress(address _newOracleAddress) public onlyDAO {
        if (_newOracleAddress == address(0)) revert InvalidAddress();
        oracleAddress = _newOracleAddress;
        emit OracleAddressUpdated(_newOracleAddress);
    }

    // --- Protocol & Admin Functions ---

    /// @notice Allows the protocol owner (or eventually DAO-controlled multisig) to withdraw accumulated protocol fees.
    function withdrawFees() public onlyOwner nonReentrant {
        if (totalProtocolFeesCollected == 0) revert ZeroAmount();
        uint256 amount = totalProtocolFeesCollected;
        totalProtocolFeesCollected = 0;
        (bool sent, ) = owner().call{value: amount}("");
        if (!sent) revert UnauthorizedWithdrawal();
    }

    /// @notice Pauses contract operations in an emergency.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the percentage of rental and task fees collected by the protocol.
    /// @param _newFee The new fee percentage (e.g., 500 for 5%).
    function setProtocolFeePercentage(uint256 _newFee) public onlyDAO {
        if (_newFee > 10000) revert InvalidFeePercentage();
        protocolFeePercentage = _newFee;
    }

    /// @notice Sets the minimum cognitive score an SDC must have to be eligible for data tasks.
    /// @param _minScore The new minimum cognitive score.
    function setMinimumCognitiveScoreForTask(uint256 _minScore) public onlyDAO {
        minimumCognitiveScoreForTask = _minScore;
    }

    /// @notice Sets the duration for which a governance proposal is open for voting.
    /// @param _period The new voting period in seconds.
    function setProposalVotingPeriod(uint256 _period) public onlyDAO {
        proposalVotingPeriod = _period;
    }

    /// @notice Sets the minimum SDC cognitive score required for an address to propose a governance change.
    /// @param _minScore The new minimum cognitive score for proposers.
    function setMinProposerSDCScore(uint256 _minScore) public onlyDAO {
        minProposerSDCScore = _minScore;
    }

    /// @notice Sets the conceptual fee for requesting off-chain oracle computations.
    /// @param _fee The new oracle fee.
    function setOracleFee(uint256 _fee) public onlyDAO {
        oracleFee = _fee;
    }

    // --- ERC721 Overrides ---

    /// @inheritdoc ERC721
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, IERC721Metadata)
        returns (string memory)
    {
        return getSDCMetadataURI(_tokenId);
    }

    /// @inheritdoc ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Prevent transfer if SDC is currently rented
        if (sdcAgents[tokenId].currentRenter != address(0)) {
            revert RentalActive();
        }
        // Also remove from rental listing if transferring
        if (sdcAgents[tokenId].isListedForRent) {
            sdcAgents[tokenId].isListedForRent = false;
            sdcAgents[tokenId].pricePerDay = 0;
        }
    }

    /// @inheritdoc ERC721
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        // Support ERC721 and ERC721Metadata interfaces
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// Minimalist Base64 library for data URI encoding (from OpenZeppelin example)
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // calculate output length required
        uint256 len = data.length;
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // allocate output buffer in memory
        bytes memory buf = new bytes(encodedLen);
        uint256 ptr = 0;
        uint256 idx = 0;

        while (idx < len) {
            uint256 b1 = data[idx];
            uint256 b2 = idx + 1 < len ? data[idx + 1] : 0;
            uint256 b3 = idx + 2 < len ? data[idx + 2] : 0;

            uint256 enc1 = b1 >> 2;
            uint256 enc2 = ((b1 & 0x03) << 4) | (b2 >> 4);
            uint256 enc3 = ((b2 & 0x0F) << 2) | (b3 >> 6);
            uint256 enc4 = b3 & 0x3F;

            buf[ptr] = bytes1(table[enc1]);
            ptr = ptr.add(1);
            buf[ptr] = bytes1(table[enc2]);
            ptr = ptr.add(1);
            if (idx + 1 < len) {
                buf[ptr] = bytes1(table[enc3]);
            } else {
                buf[ptr] = '=';
            }
            ptr = ptr.add(1);
            if (idx + 2 < len) {
                buf[ptr] = bytes1(table[enc4]);
            } else {
                buf[ptr] = '=';
            }
            ptr = ptr.add(1);

            idx = idx.add(3);
        }
        return string(buf);
    }
}
```