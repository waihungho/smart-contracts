The following smart contract, **NexusMind**, is designed as a Decentralized AI-Assisted Innovation Network. It enables a community to collaboratively propose problems, develop solutions (optionally with AI assistance verifiable via ZK-proofs), validate them through voting, and potentially fund their development. It incorporates advanced concepts like a dynamic reputation system, placeholder ZK-proof integration for AI transparency, and non-transferable "Idea Genesis" NFTs for successful contributors.

---

### **Outline:**

**I. Core Infrastructure & Access Control**
    - Owner management, pausing functionality, and fee withdrawal mechanisms.
    - Registration and management of AI oracles for external AI services.

**II. Problem Statement (PS) Lifecycle**
    - Functions for users to propose new problem statements.
    - Community voting system for approving or rejecting problem statements.
    - Logic for finalizing the voting phase, including stake management (release or slashing).

**III. Solution Concept (SC) Lifecycle**
    - Functions for users to propose solutions to active problem statements.
    - Mechanism for submitting placeholder ZK-proof hashes for AI-generated solutions.
    - Community voting system for evaluating solution concepts.
    - Logic for finalizing solution concept voting, including stake management.
    - Minting of unique, non-transferable "Idea Genesis" NFTs (IGNs) for successful concept proposers.

**IV. Reputation & Metrics**
    - A dynamic reputation score (DRS) calculated based on user participation and success within the network.
    - View functions to retrieve the status and detailed information of problem statements, solution concepts, and AI oracles.

**V. Funding & Treasury Management**
    - Functions for users to contribute to a community funding pool.
    - Mechanisms for proposers of successful solution concepts to request and receive funding (subject to governance).

**VI. Administrative & Configuration**
    - Functions for the owner/governance to adjust protocol parameters, such as fees, voting thresholds, and DRS calculation weights.
    - Management of the Idea Genesis NFT (IGN) metadata URI.

---

### **Function Summary:**

1.  `constructor(address _initialOwner, address _nexusTokenAddress, string memory _ignName, string memory _ignSymbol)`
    - Initializes the contract, setting the owner, the address of the Nexus token (used for staking and fees), and the name/symbol for the Idea Genesis NFTs (IGNs).

2.  `registerAIOracle(address _oracleAddress, string memory _name, string memory _description)`
    - Allows the contract owner to register a new AI oracle. This oracle can then be referenced by solution concepts to signify AI assistance.

3.  `deregisterAIOracle(uint256 _oracleId)`
    - Allows the contract owner to deactivate an existing AI oracle, preventing it from being referenced in new solution concepts.

4.  `setProblemStatementFee(uint256 _fee)`
    - Sets the required amount of Nexus tokens that must be staked when proposing a new Problem Statement.

5.  `setSolutionConceptFee(uint256 _fee)`
    - Sets the required amount of Nexus tokens that must be staked when proposing a new Solution Concept.

6.  `proposeProblemStatement(string memory _title, string memory _description, uint256 _votingPeriodDays)`
    - Enables any user to propose a new problem, requiring them to stake the `problemStatementFee`. The proposal enters a voting phase.

7.  `voteOnProblemStatement(uint256 _psId, bool _isUpvote)`
    - Allows users to cast an upvote or downvote on a pending Problem Statement. Each user can vote only once per PS.

8.  `finalizeProblemStatementVoting(uint256 _psId)`
    - Concludes the voting phase for a Problem Statement. Based on the votes, the PS is either `Approved` (stake released) or `Rejected`/`Expired` (stake slashed).

9.  `proposeSolutionConcept(uint256 _psId, string memory _title, string memory _description, uint256 _votingPeriodDays, uint256 _aiOracleId)`
    - Enables users to propose a solution to an `Active` Problem Statement, requiring them to stake the `solutionConceptFee`. Can optionally link to a registered AI oracle.

10. `submitAIProofForSolution(uint256 _scId, bytes32 _proofHash)`
    - Allows the proposer of an AI-assisted Solution Concept to submit a placeholder hash (e.g., of a ZK-proof) verifying the AI's contribution.

11. `voteOnSolutionConcept(uint256 _scId, bool _isUpvote)`
    - Enables users to cast an upvote or downvote on a pending Solution Concept. Each user can vote only once per SC.

12. `finalizeSolutionConceptVoting(uint256 _scId)`
    - Concludes the voting phase for a Solution Concept. Based on the votes, the SC is either `Approved` (stake released) or `Rejected`/`Expired` (stake slashed).

13. `claimIdeaGenesisNFT(uint256 _scId)`
    - Allows the proposer of a successfully `Approved` Solution Concept to mint a unique, non-transferable Idea Genesis NFT (IGN), representing their contribution.

14. `depositToFundingPool(uint256 _amount)`
    - Allows any user to contribute Nexus tokens to a community-managed funding pool within the contract.

15. `requestFundingForSolution(uint256 _scId, uint256 _amount)`
    - Allows the proposer of an `Approved` Solution Concept to formally request a specific amount of funding from the pool. This initiates an internal record for potential distribution.

16. `distributeFunding(uint256 _scId, address _recipient, uint256 _amount)`
    - An owner-only or governance-controlled function to transfer requested funds from the protocol's funding pool to the designated recipient for a specific Solution Concept.

17. `getDynamicReputationScore(address _user) view`
    - Calculates and returns a user's Dynamic Reputation Score (DRS) based on their successful proposals, participation in voting, and potential stake slashes.

18. `getProblemStatementStatus(uint256 _psId) view`
    - Returns the current `Status` enum value for a given Problem Statement ID.

19. `getSolutionConceptStatus(uint256 _scId) view`
    - Returns the current `Status` enum value for a given Solution Concept ID.

20. `getAIOracleStatus(uint256 _oracleId) view`
    - Returns whether a given AI Oracle is currently `active` or `inactive`.

21. `getProblemStatementDetails(uint256 _psId) view`
    - Retrieves a comprehensive struct containing all stored details about a specific Problem Statement.

22. `getSolutionConceptDetails(uint256 _scId) view`
    - Retrieves a comprehensive struct containing all stored details about a specific Solution Concept.

23. `updateMinimumVotesForPS(uint256 _minUpvotes, uint256 _minRatioBasisPoints)`
    - Allows the owner to set the minimum number of upvotes and the minimum upvote-to-total-vote ratio required for a Problem Statement to pass voting.

24. `updateMinimumVotesForSC(uint256 _minUpvotes, uint256 _minRatioBasisPoints)`
    - Allows the owner to set the minimum number of upvotes and the minimum upvote-to-total-vote ratio required for a Solution Concept to pass voting.

25. `updateDRSWeights(uint256 _psWeight, uint256 _scWeight, uint256 _voteWeight, uint256 _slashWeight)`
    - Allows the owner to adjust the weighting factors used in the Dynamic Reputation Score (DRS) calculation, influencing how different actions affect a user's score.

26. `withdrawProtocolFees()`
    - Allows the contract owner to withdraw accumulated protocol fees (from PS/SC proposals) in Nexus tokens to the owner's address.

27. `setBaseURI(string memory _newBaseURI)`
    - Sets the base URI for the metadata of the Idea Genesis NFTs (IGNs), typically pointing to an IPFS gateway or similar content addressable storage.

28. `_baseURI() internal view`
    - An internal view function (part of ERC721 standard) which returns the base URI for token metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath for extra safety on arithmetic

// Outline:
// I. Core Infrastructure & Access Control
//    - Owner management, pausing, fee withdrawal.
//    - AI Oracle registration and management.
// II. Problem Statement (PS) Lifecycle
//    - Proposing, voting, and finalizing Problem Statements.
// III. Solution Concept (SC) Lifecycle
//    - Proposing, AI proof submission, voting, and finalizing Solution Concepts.
//    - Minting Idea Genesis NFTs (IGNs) for successful concepts.
// IV. Reputation & Metrics
//    - Dynamic Reputation Score (DRS) calculation.
//    - Status retrieval for PS, SC, and AI Oracles.
// V. Funding & Treasury Management
//    - Managing the community funding pool and distribution.
// VI. Administrative & Configuration
//    - Setting fees, voting thresholds, and DRS parameters.

// Function Summary:
// 1.  constructor(address _initialOwner, address _nexusTokenAddress, string memory _ignName, string memory _ignSymbol)
//     - Initializes the contract, sets the owner, the Nexus token (for staking/fees), and Idea Genesis NFT (IGN) details.
// 2.  registerAIOracle(address _oracleAddress, string memory _name, string memory _description)
//     - Registers a new AI oracle, making it available for reference in Solution Concepts.
// 3.  deregisterAIOracle(uint256 _oracleId)
//     - Deactivates an existing AI oracle, preventing it from being referenced in new Solution Concepts.
// 4.  setProblemStatementFee(uint256 _fee)
//     - Sets the required token fee for proposing a Problem Statement.
// 5.  setSolutionConceptFee(uint256 _fee)
//     - Sets the required token fee for proposing a Solution Concept.
// 6.  proposeProblemStatement(string memory _title, string memory _description, uint256 _votingPeriodDays)
//     - Allows users to propose a new problem, staking the `problemStatementFee`.
// 7.  voteOnProblemStatement(uint256 _psId, bool _isUpvote)
//     - Enables users to vote (upvote/downvote) on a pending Problem Statement.
// 8.  finalizeProblemStatementVoting(uint256 _psId)
//     - Concludes the voting phase for a Problem Statement, updating its status based on votes.
//     - Stakes are released for approved PS, or slashed for rejected/expired.
// 9.  proposeSolutionConcept(uint256 _psId, string memory _title, string memory _description, uint256 _votingPeriodDays, uint256 _aiOracleId)
//     - Allows users to propose a solution to an active PS, staking the `solutionConceptFee`.
//     - Can optionally link to a registered AI oracle.
// 10. submitAIProofForSolution(uint256 _scId, bytes32 _proofHash)
//     - Allows the proposer of an AI-assisted Solution Concept to submit a mock ZK-proof hash.
// 11. voteOnSolutionConcept(uint256 _scId, bool _isUpvote)
//     - Enables users to vote (upvote/downvote) on a pending Solution Concept.
// 12. finalizeSolutionConceptVoting(uint256 _scId)
//     - Concludes the voting phase for a Solution Concept, updating its status.
//     - Stakes are released for approved SC, or slashed for rejected/expired.
// 13. claimIdeaGenesisNFT(uint256 _scId)
//     - Allows the proposer of a successfully approved Solution Concept to mint a unique Idea Genesis NFT (IGN).
// 14. depositToFundingPool(uint256 _amount)
//     - Allows any user to contribute Nexus tokens to the protocol's funding pool.
// 15. requestFundingForSolution(uint256 _scId, uint256 _amount)
//     - Allows the proposer of an 'Approved' Solution Concept to request funds from the pool.
//     - This function is designed for a simplified governance where the owner/DAO approves distribution.
// 16. distributeFunding(uint256 _scId, address _recipient, uint256 _amount)
//     - Owner/DAO function to actually transfer funds from the pool to a successful solution concept.
// 17. getDynamicReputationScore(address _user) view
//     - Calculates and returns a user's Dynamic Reputation Score (DRS) based on their activity.
// 18. getProblemStatementStatus(uint256 _psId) view
//     - Returns the current status of a Problem Statement.
// 19. getSolutionConceptStatus(uint256 _scId) view
//     - Returns the current status of a Solution Concept.
// 20. getAIOracleStatus(uint256 _oracleId) view
//     - Returns the current status (active/inactive) of a registered AI Oracle.
// 21. getProblemStatementDetails(uint256 _psId) view
//     - Retrieves all details of a specific Problem Statement.
// 22. getSolutionConceptDetails(uint256 _scId) view
//     - Retrieves all details of a specific Solution Concept.
// 23. updateMinimumVotesForPS(uint256 _minUpvotes, uint256 _minRatioBasisPoints)
//     - Sets the minimum upvotes and upvote-to-total-vote ratio required for a Problem Statement to pass.
// 24. updateMinimumVotesForSC(uint256 _minUpvotes, uint256 _minRatioBasisPoints)
//     - Sets the minimum upvotes and upvote-to-total-vote ratio required for a Solution Concept to pass.
// 25. updateDRSWeights(uint256 _psWeight, uint256 _scWeight, uint256 _voteWeight, uint256 _slashWeight)
//     - Allows the owner to adjust the weights used in the Dynamic Reputation Score calculation.
// 26. withdrawProtocolFees()
//     - Allows the owner to withdraw accumulated protocol fees.
// 27. setBaseURI(string memory _newBaseURI)
//     - Sets the base URI for Idea Genesis NFT metadata.
// 28. _baseURI() internal view (Part of ERC721)
//     - Internal view function (part of ERC721 standard) which returns the base URI for token metadata.

contract NexusMind is Ownable, Pausable, ERC721 {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public immutable nexusToken; // The token used for fees and staking

    // --- Problem Statement (PS) Management ---
    struct ProblemStatement {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 feeStaked;
        uint256 proposalTimestamp;
        uint256 votingEndsTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        Status status;
        bool stakeClaimed; // To prevent double claim/slash
    }

    Counters.Counter private _psIds;
    mapping(uint256 => ProblemStatement) public problemStatements;
    mapping(uint256 => mapping(address => bool)) private hasVotedOnPS; // psId => voterAddress => voted

    uint256 public problemStatementFee;
    uint256 public minVotesForPS;
    uint256 public minUpvoteRatioBasisPointsForPS; // e.g., 6000 for 60%

    // --- Solution Concept (SC) Management ---
    struct SolutionConcept {
        uint256 id;
        uint256 problemStatementId; // Link to PS
        address proposer;
        string title;
        string description;
        uint256 feeStaked;
        uint256 proposalTimestamp;
        uint256 votingEndsTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        uint256 aiOracleId; // 0 if not AI-assisted
        bytes32 aiProofHash; // Placeholder for ZK proof hash
        Status status;
        bool funded;
        bool stakeClaimed; // To prevent double claim/slash
        bool ignMinted; // To track if NFT has been minted
        uint256 fundingRequestedAmount; // Amount requested by proposer
    }

    Counters.Counter private _scIds;
    mapping(uint256 => SolutionConcept) public solutionConcepts;
    mapping(uint256 => mapping(address => bool)) private hasVotedOnSC; // scId => voterAddress => voted

    uint256 public solutionConceptFee;
    uint256 public minVotesForSC;
    uint256 public minUpvoteRatioBasisPointsForSC; // e.g., 6000 for 60%

    // --- AI Oracle Management ---
    struct AIOracle {
        uint256 id;
        address oracleAddress; // Address of the off-chain oracle service/identity
        string name;
        string description;
        bool active;
        uint256 registrationTimestamp;
    }

    Counters.Counter private _aiOracleIds;
    mapping(uint256 => AIOracle) public aiOracles;

    // --- Reputation System (DRS) ---
    // Raw counts for DRS calculation (actual score calculated on-the-fly)
    mapping(address => uint256) public successfulPSProposalsCount;
    mapping(address => uint256) public successfulSCProposalsCount;
    mapping(address => uint256) public successfulVotesCastedCount; // For any type of vote
    mapping(address => uint256) public slashedStakesCount;

    // Weights for DRS calculation (adjustable by owner)
    uint256 public drsWeightPS;    // Weight for successful PS proposal
    uint256 public drsWeightSC;    // Weight for successful SC proposal
    uint256 public drsWeightVote;  // Weight for casting a vote on a successful proposal
    uint256 public drsWeightSlash; // Penalty for having stake slashed

    // --- Protocol Fees & Funding Pool ---
    uint256 public protocolFeesCollected;
    uint256 public fundingPoolBalance; // Nexus tokens held in the contract for funding solutions

    // --- Idea Genesis NFT (IGN) Management ---
    Counters.Counter private _ignTokenIds; // ERC721 token IDs
    string private _baseTokenURI;

    // --- Enums ---
    enum Status {
        PendingApproval, // Initial state for PS/SC, currently in voting
        Active,          // Approved PS, ready for solutions
        Approved,        // Approved SC, ready for funding/IGN minting
        Rejected,        // Rejected PS/SC
        Funded,          // Approved SC that has received funding
        Expired          // Voting period ended for PS/SC without meeting criteria
    }

    // --- Events ---
    event ProblemStatementProposed(uint256 indexed psId, address indexed proposer, string title, uint256 fee);
    event ProblemStatementVoted(uint256 indexed psId, address indexed voter, bool isUpvote);
    event ProblemStatementFinalized(uint256 indexed psId, Status newStatus);
    event SolutionConceptProposed(uint256 indexed scId, uint256 indexed psId, address indexed proposer, string title, uint256 fee, uint256 aiOracleId);
    event AIProofSubmitted(uint256 indexed scId, bytes32 proofHash);
    event SolutionConceptVoted(uint256 indexed scId, address indexed voter, bool isUpvote);
    event SolutionConceptFinalized(uint256 indexed scId, Status newStatus);
    event IdeaGenesisNFTMinted(uint256 indexed scId, address indexed owner, uint256 tokenId);
    event AIOracleRegistered(uint256 indexed oracleId, address oracleAddress, string name);
    event AIOracleDeregistered(uint256 indexed oracleId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundingRequested(uint256 indexed scId, address indexed proposer, uint256 amount);
    event FundingDistributed(uint256 indexed scId, address indexed recipient, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed owner, uint256 amount);
    event FeeUpdated(string indexed feeType, uint256 newFee);
    event VotingThresholdsUpdated(string indexed typeName, uint256 minUpvotes, uint256 minRatio);
    event DRSWeightsUpdated(uint256 psWeight, uint256 scWeight, uint256 voteWeight, uint256 slashWeight);

    // --- Constructor ---
    constructor(address _initialOwner, address _nexusTokenAddress, string memory _ignName, string memory _ignSymbol)
        Ownable(_initialOwner)
        ERC721(_ignName, _ignSymbol)
    {
        require(_nexusTokenAddress != address(0), "Nexus token address cannot be zero");
        nexusToken = IERC20(_nexusTokenAddress);

        // Initial fees and voting thresholds
        problemStatementFee = 100 * 10**18; // Example: 100 tokens
        solutionConceptFee = 50 * 10**18; // Example: 50 tokens
        minVotesForPS = 5;
        minUpvoteRatioBasisPointsForPS = 6000; // 60%
        minVotesForSC = 3;
        minUpvoteRatioBasisPointsForSC = 7000; // 70%

        // Initial DRS weights
        drsWeightPS = 10;
        drsWeightSC = 20;
        drsWeightVote = 1;
        drsWeightSlash = 5; // Penalty value
    }

    // --- Modifiers ---
    modifier onlyAIOracleProposer(uint256 _scId) {
        require(solutionConcepts[_scId].proposer == msg.sender, "Only SC proposer can submit proof");
        require(solutionConcepts[_scId].aiOracleId != 0, "SC not linked to an AI oracle");
        require(solutionConcepts[_scId].aiProofHash == bytes32(0), "AI proof already submitted");
        _;
    }

    modifier onlyIfStakeNotClaimedPS(uint256 _psId) {
        require(!problemStatements[_psId].stakeClaimed, "Problem Statement stake already processed.");
        _;
    }

    modifier onlyIfStakeNotClaimedSC(uint256 _scId) {
        require(!solutionConcepts[_scId].stakeClaimed, "Solution Concept stake already processed.");
        _;
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Registers a new AI oracle. Only owner.
     * @param _oracleAddress The on-chain address associated with the off-chain AI oracle service.
     * @param _name The name of the AI oracle.
     * @param _description A brief description of the AI oracle's capabilities.
     */
    function registerAIOracle(address _oracleAddress, string memory _name, string memory _description)
        public
        onlyOwner
        whenNotPaused
    {
        require(_oracleAddress != address(0), "Oracle address cannot be zero");
        _aiOracleIds.increment();
        uint256 newId = _aiOracleIds.current();
        aiOracles[newId] = AIOracle({
            id: newId,
            oracleAddress: _oracleAddress,
            name: _name,
            description: _description,
            active: true,
            registrationTimestamp: block.timestamp
        });
        emit AIOracleRegistered(newId, _oracleAddress, _name);
    }

    /**
     * @dev Deactivates an existing AI oracle. Only owner.
     *      Existing solution concepts referencing this oracle will still show the reference,
     *      but new ones cannot use it.
     * @param _oracleId The ID of the AI oracle to deregister.
     */
    function deregisterAIOracle(uint256 _oracleId) public onlyOwner whenNotPaused {
        require(_oracleId > 0 && _oracleId <= _aiOracleIds.current(), "Invalid oracle ID");
        require(aiOracles[_oracleId].active, "AI oracle is already inactive");
        aiOracles[_oracleId].active = false;
        emit AIOracleDeregistered(_oracleId);
    }

    /**
     * @dev Pauses the contract. Emergency function, only owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Emergency function, only owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw collected protocol fees.
     */
    function withdrawProtocolFees() public onlyOwner {
        uint256 amount = protocolFeesCollected;
        require(amount > 0, "No fees to withdraw");
        protocolFeesCollected = 0; // Reset before transfer
        nexusToken.transfer(owner(), amount);
        emit ProtocolFeesWithdrawn(owner(), amount);
    }

    // --- II. Problem Statement (PS) Lifecycle ---

    /**
     * @dev Allows a user to propose a new Problem Statement.
     * Requires staking `problemStatementFee` in Nexus tokens.
     * @param _title The title of the problem statement.
     * @param _description A detailed description of the problem.
     * @param _votingPeriodDays The number of days for the voting period.
     */
    function proposeProblemStatement(
        string memory _title,
        string memory _description,
        uint256 _votingPeriodDays
    ) public whenNotPaused {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_votingPeriodDays > 0, "Voting period must be at least 1 day");
        require(
            nexusToken.transferFrom(msg.sender, address(this), problemStatementFee),
            "Problem statement fee transfer failed"
        );

        _psIds.increment();
        uint256 newId = _psIds.current();

        problemStatements[newId] = ProblemStatement({
            id: newId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            feeStaked: problemStatementFee,
            proposalTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp.add(_votingPeriodDays.mul(1 days)),
            upvotes: 0,
            downvotes: 0,
            status: Status.PendingApproval,
            stakeClaimed: false
        });

        protocolFeesCollected = protocolFeesCollected.add(problemStatementFee); // Fees go to protocol
        emit ProblemStatementProposed(newId, msg.sender, _title, problemStatementFee);
    }

    /**
     * @dev Allows a user to vote on a Problem Statement.
     * Each user can vote only once per Problem Statement.
     * @param _psId The ID of the Problem Statement to vote on.
     * @param _isUpvote True for upvote, false for downvote.
     */
    function voteOnProblemStatement(uint256 _psId, bool _isUpvote) public whenNotPaused {
        ProblemStatement storage ps = problemStatements[_psId];
        require(ps.status == Status.PendingApproval, "Problem Statement is not in pending approval status");
        require(block.timestamp <= ps.votingEndsTimestamp, "Voting period has ended");
        require(!hasVotedOnPS[_psId][msg.sender], "Already voted on this Problem Statement");

        if (_isUpvote) {
            ps.upvotes = ps.upvotes.add(1);
        } else {
            ps.downvotes = ps.downvotes.add(1);
        }
        hasVotedOnPS[_psId][msg.sender] = true;
        emit ProblemStatementVoted(_psId, msg.sender, _isUpvote);
    }

    /**
     * @dev Finalizes the voting process for a Problem Statement.
     * Releases or slashes the proposer's stake based on voting outcome.
     * Anyone can call this after the voting period ends.
     * @param _psId The ID of the Problem Statement to finalize.
     */
    function finalizeProblemStatementVoting(uint256 _psId) public whenNotPaused onlyIfStakeNotClaimedPS(_psId) {
        ProblemStatement storage ps = problemStatements[_psId];
        require(ps.status == Status.PendingApproval, "Problem Statement is not pending approval");
        require(block.timestamp > ps.votingEndsTimestamp, "Voting period has not ended yet");

        uint256 totalVotes = ps.upvotes.add(ps.downvotes);
        bool passed = false;

        if (totalVotes >= minVotesForPS) {
            uint256 upvoteRatio = totalVotes > 0 ? ps.upvotes.mul(10000).div(totalVotes) : 0;
            if (upvoteRatio >= minUpvoteRatioBasisPointsForPS) {
                passed = true;
            }
        }

        if (passed) {
            ps.status = Status.Active;
            nexusToken.transfer(ps.proposer, ps.feeStaked); // Return stake
            successfulPSProposalsCount[ps.proposer] = successfulPSProposalsCount[ps.proposer].add(1);
            // Reward voters for successful PS
            // This would require iterating through voters, which is gas intensive.
            // A more scalable approach would be off-chain distribution or a claim function.
            // For now, only proposer's DRS is updated.
        } else {
            ps.status = Status.Rejected; // Or Expired if not enough votes
            if (totalVotes < minVotesForPS && block.timestamp > ps.votingEndsTimestamp) {
                ps.status = Status.Expired;
            }
            // Stake is slashed (remains in contract's protocolFeesCollected balance)
            slashedStakesCount[ps.proposer] = slashedStakesCount[ps.proposer].add(1);
        }
        ps.stakeClaimed = true; // Mark stake as processed
        emit ProblemStatementFinalized(_psId, ps.status);
    }

    // --- III. Solution Concept (SC) Lifecycle ---

    /**
     * @dev Allows a user to propose a Solution Concept for an active Problem Statement.
     * Requires staking `solutionConceptFee` in Nexus tokens.
     * Can optionally link to a registered AI oracle.
     * @param _psId The ID of the Problem Statement the solution addresses.
     * @param _title The title of the solution concept.
     * @param _description A detailed description of the solution.
     * @param _votingPeriodDays The number of days for the voting period.
     * @param _aiOracleId The ID of the AI oracle used (0 if none).
     */
    function proposeSolutionConcept(
        uint256 _psId,
        string memory _title,
        string memory _description,
        uint256 _votingPeriodDays,
        uint256 _aiOracleId
    ) public whenNotPaused {
        require(problemStatements[_psId].status == Status.Active, "Problem Statement is not active");
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_votingPeriodDays > 0, "Voting period must be at least 1 day");

        if (_aiOracleId != 0) {
            require(_aiOracleId > 0 && _aiOracleId <= _aiOracleIds.current(), "Invalid AI oracle ID");
            require(aiOracles[_aiOracleId].active, "AI oracle is not active");
        }

        require(
            nexusToken.transferFrom(msg.sender, address(this), solutionConceptFee),
            "Solution concept fee transfer failed"
        );

        _scIds.increment();
        uint256 newId = _scIds.current();

        solutionConcepts[newId] = SolutionConcept({
            id: newId,
            problemStatementId: _psId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            feeStaked: solutionConceptFee,
            proposalTimestamp: block.timestamp,
            votingEndsTimestamp: block.timestamp.add(_votingPeriodDays.mul(1 days)),
            upvotes: 0,
            downvotes: 0,
            aiOracleId: _aiOracleId,
            aiProofHash: bytes32(0), // No proof initially
            status: Status.PendingApproval,
            funded: false,
            stakeClaimed: false,
            ignMinted: false,
            fundingRequestedAmount: 0
        });

        protocolFeesCollected = protocolFeesCollected.add(solutionConceptFee); // Fees go to protocol
        emit SolutionConceptProposed(newId, _psId, msg.sender, _title, solutionConceptFee, _aiOracleId);
    }

    /**
     * @dev Allows the proposer of an AI-assisted Solution Concept to submit a mock ZK-proof hash.
     * This hash would typically be verified off-chain.
     * @param _scId The ID of the Solution Concept.
     * @param _proofHash The hash representing the ZK-proof (e.g., proof ID, commitment).
     */
    function submitAIProofForSolution(uint256 _scId, bytes32 _proofHash)
        public
        whenNotPaused
        onlyAIOracleProposer(_scId)
    {
        solutionConcepts[_scId].aiProofHash = _proofHash;
        emit AIProofSubmitted(_scId, _proofHash);
    }

    /**
     * @dev Allows a user to vote on a Solution Concept.
     * Each user can vote only once per Solution Concept.
     * @param _scId The ID of the Solution Concept to vote on.
     * @param _isUpvote True for upvote, false for downvote.
     */
    function voteOnSolutionConcept(uint256 _scId, bool _isUpvote) public whenNotPaused {
        SolutionConcept storage sc = solutionConcepts[_scId];
        require(sc.status == Status.PendingApproval, "Solution Concept is not in pending approval status");
        require(block.timestamp <= sc.votingEndsTimestamp, "Voting period has ended");
        require(!hasVotedOnSC[_scId][msg.sender], "Already voted on this Solution Concept");

        if (_isUpvote) {
            sc.upvotes = sc.upvotes.add(1);
        } else {
            sc.downvotes = sc.downvotes.add(1);
        }
        hasVotedOnSC[_scId][msg.sender] = true;
        successfulVotesCastedCount[msg.sender] = successfulVotesCastedCount[msg.sender].add(1); // Update DRS for voter
        emit SolutionConceptVoted(_scId, msg.sender, _isUpvote);
    }

    /**
     * @dev Finalizes the voting process for a Solution Concept.
     * Releases or slashes the proposer's stake based on voting outcome.
     * Anyone can call this after the voting period ends.
     * @param _scId The ID of the Solution Concept to finalize.
     */
    function finalizeSolutionConceptVoting(uint256 _scId) public whenNotPaused onlyIfStakeNotClaimedSC(_scId) {
        SolutionConcept storage sc = solutionConcepts[_scId];
        require(sc.status == Status.PendingApproval, "Solution Concept is not pending approval");
        require(block.timestamp > sc.votingEndsTimestamp, "Voting period has not ended yet");

        uint256 totalVotes = sc.upvotes.add(sc.downvotes);
        bool passed = false;

        if (totalVotes >= minVotesForSC) {
            uint256 upvoteRatio = totalVotes > 0 ? sc.upvotes.mul(10000).div(totalVotes) : 0;
            if (upvoteRatio >= minUpvoteRatioBasisPointsForSC) {
                passed = true;
            }
        }

        if (passed) {
            sc.status = Status.Approved;
            nexusToken.transfer(sc.proposer, sc.feeStaked); // Return stake
            successfulSCProposalsCount[sc.proposer] = successfulSCProposalsCount[sc.proposer].add(1);
        } else {
            sc.status = Status.Rejected; // Or Expired if not enough votes
            if (totalVotes < minVotesForSC && block.timestamp > sc.votingEndsTimestamp) {
                sc.status = Status.Expired;
            }
            // Stake is slashed (remains in contract's protocolFeesCollected balance)
            slashedStakesCount[sc.proposer] = slashedStakesCount[sc.proposer].add(1);
        }
        sc.stakeClaimed = true; // Mark stake as processed
        emit SolutionConceptFinalized(_scId, sc.status);
    }

    /**
     * @dev Allows the proposer of an approved Solution Concept to mint their Idea Genesis NFT.
     * This NFT is non-transferable (represents a unique contribution).
     * @param _scId The ID of the approved Solution Concept.
     */
    function claimIdeaGenesisNFT(uint256 _scId) public whenNotPaused {
        SolutionConcept storage sc = solutionConcepts[_scId];
        require(sc.status == Status.Approved || sc.status == Status.Funded, "Solution Concept not approved or funded");
        require(sc.proposer == msg.sender, "Only the proposer can mint the IGN");
        require(!sc.ignMinted, "Idea Genesis NFT already minted for this concept");

        _ignTokenIds.increment();
        uint256 newTokenId = _ignTokenIds.current();
        _safeMint(msg.sender, newTokenId);
        // Note: _setTokenURI would be called here if each IGN had unique metadata beyond baseURI
        // For simplicity, we just use the baseURI.
        sc.ignMinted = true;
        emit IdeaGenesisNFTMinted(_scId, msg.sender, newTokenId);
    }

    // --- IV. Reputation & Metrics ---

    /**
     * @dev Calculates a user's Dynamic Reputation Score (DRS).
     * This is a calculated value based on their contributions and actions.
     * @param _user The address of the user.
     * @return The calculated DRS.
     */
    function getDynamicReputationScore(address _user) public view returns (uint256) {
        uint256 score = 0;
        score = score.add(successfulPSProposalsCount[_user].mul(drsWeightPS));
        score = score.add(successfulSCProposalsCount[_user].mul(drsWeightSC));
        score = score.add(successfulVotesCastedCount[_user].mul(drsWeightVote));

        // Penalty for slashed stakes, ensure score doesn't go below zero
        if (slashedStakesCount[_user] > 0) {
            uint256 penalty = slashedStakesCount[_user].mul(drsWeightSlash);
            score = score > penalty ? score.sub(penalty) : 0;
        }

        return score;
    }

    /**
     * @dev Returns the current status of a Problem Statement.
     * @param _psId The ID of the Problem Statement.
     * @return The status enum value.
     */
    function getProblemStatementStatus(uint256 _psId) public view returns (Status) {
        require(_psId > 0 && _psId <= _psIds.current(), "Invalid Problem Statement ID");
        return problemStatements[_psId].status;
    }

    /**
     * @dev Returns the current status of a Solution Concept.
     * @param _scId The ID of the Solution Concept.
     * @return The status enum value.
     */
    function getSolutionConceptStatus(uint256 _scId) public view returns (Status) {
        require(_scId > 0 && _scId <= _scIds.current(), "Invalid Solution Concept ID");
        return solutionConcepts[_scId].status;
    }

    /**
     * @dev Returns the active status of an AI Oracle.
     * @param _oracleId The ID of the AI Oracle.
     * @return True if active, false otherwise.
     */
    function getAIOracleStatus(uint256 _oracleId) public view returns (bool) {
        require(_oracleId > 0 && _oracleId <= _aiOracleIds.current(), "Invalid AI Oracle ID");
        return aiOracles[_oracleId].active;
    }

    /**
     * @dev Retrieves all details of a specific Problem Statement.
     * @param _psId The ID of the Problem Statement.
     * @return A ProblemStatement struct containing all its details.
     */
    function getProblemStatementDetails(uint256 _psId) public view returns (ProblemStatement memory) {
        require(_psId > 0 && _psId <= _psIds.current(), "Invalid Problem Statement ID");
        return problemStatements[_psId];
    }

    /**
     * @dev Retrieves all details of a specific Solution Concept.
     * @param _scId The ID of the Solution Concept.
     * @return A SolutionConcept struct containing all its details.
     */
    function getSolutionConceptDetails(uint256 _scId) public view returns (SolutionConcept memory) {
        require(_scId > 0 && _scId <= _scIds.current(), "Invalid Solution Concept ID");
        return solutionConcepts[_scId];
    }

    // --- V. Funding & Treasury Management ---

    /**
     * @dev Allows any user to deposit Nexus tokens into the contract's funding pool.
     * These funds can later be distributed to approved solution concepts.
     * @param _amount The amount of Nexus tokens to deposit.
     */
    function depositToFundingPool(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(nexusToken.transferFrom(msg.sender, address(this), _amount), "Token transfer to funding pool failed");
        fundingPoolBalance = fundingPoolBalance.add(_amount);
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @dev Allows the proposer of an 'Approved' Solution Concept to request funding.
     * This merely registers the request; actual distribution needs `distributeFunding`.
     * @param _scId The ID of the Solution Concept.
     * @param _amount The amount of funding requested.
     */
    function requestFundingForSolution(uint256 _scId, uint256 _amount) public whenNotPaused {
        SolutionConcept storage sc = solutionConcepts[_scId];
        require(sc.status == Status.Approved, "Solution Concept must be approved to request funding");
        require(sc.proposer == msg.sender, "Only the proposer can request funding for their solution");
        require(_amount > 0, "Requested amount must be greater than zero");
        sc.fundingRequestedAmount = _amount; // Stores the request
        emit FundingRequested(_scId, msg.sender, _amount);
    }

    /**
     * @dev Distributes funds from the contract's funding pool to an approved Solution Concept.
     * This function is owner-controlled, simulating a simplified DAO approval or direct owner decision.
     * In a full DAO, this would be part of a governance proposal.
     * @param _scId The ID of the Solution Concept to fund.
     * @param _recipient The address to send the funds to (usually the proposer).
     * @param _amount The amount to distribute.
     */
    function distributeFunding(uint256 _scId, address _recipient, uint256 _amount) public onlyOwner whenNotPaused {
        SolutionConcept storage sc = solutionConcepts[_scId];
        require(sc.status == Status.Approved || sc.status == Status.Funded, "Solution Concept must be approved or already funded");
        require(_amount > 0, "Amount must be greater than zero");
        require(fundingPoolBalance >= _amount, "Insufficient funds in pool");

        fundingPoolBalance = fundingPoolBalance.sub(_amount);
        nexusToken.transfer(_recipient, _amount);
        sc.funded = true; // Mark as funded
        sc.status = Status.Funded; // Update status
        emit FundingDistributed(_scId, _recipient, _amount);
    }

    // --- VI. Administrative & Configuration ---

    /**
     * @dev Sets the required token fee for proposing a Problem Statement. Only owner.
     * @param _fee The new fee amount.
     */
    function setProblemStatementFee(uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than zero");
        problemStatementFee = _fee;
        emit FeeUpdated("ProblemStatementFee", _fee);
    }

    /**
     * @dev Sets the required token fee for proposing a Solution Concept. Only owner.
     * @param _fee The new fee amount.
     */
    function setSolutionConceptFee(uint256 _fee) public onlyOwner {
        require(_fee > 0, "Fee must be greater than zero");
        solutionConceptFee = _fee;
        emit FeeUpdated("SolutionConceptFee", _fee);
    }

    /**
     * @dev Sets the minimum votes and upvote ratio required for a Problem Statement to pass. Only owner.
     * @param _minUpvotes Minimum absolute upvotes required.
     * @param _minRatioBasisPoints Minimum upvote ratio in basis points (e.g., 6000 for 60%).
     */
    function updateMinimumVotesForPS(uint256 _minUpvotes, uint256 _minRatioBasisPoints) public onlyOwner {
        require(_minRatioBasisPoints <= 10000, "Ratio cannot exceed 10000 (100%)");
        minVotesForPS = _minUpvotes;
        minUpvoteRatioBasisPointsForPS = _minRatioBasisPoints;
        emit VotingThresholdsUpdated("ProblemStatement", _minUpvotes, _minRatioBasisPoints);
    }

    /**
     * @dev Sets the minimum votes and upvote ratio required for a Solution Concept to pass. Only owner.
     * @param _minUpvotes Minimum absolute upvotes required.
     * @param _minRatioBasisPoints Minimum upvote ratio in basis points (e.g., 7000 for 70%).
     */
    function updateMinimumVotesForSC(uint256 _minUpvotes, uint256 _minRatioBasisPoints) public onlyOwner {
        require(_minRatioBasisPoints <= 10000, "Ratio cannot exceed 10000 (100%)");
        minVotesForSC = _minUpvotes;
        minUpvoteRatioBasisPointsForSC = _minRatioBasisPoints;
        emit VotingThresholdsUpdated("SolutionConcept", _minUpvotes, _minRatioBasisPoints);
    }

    /**
     * @dev Updates the weights used in the Dynamic Reputation Score (DRS) calculation. Only owner.
     * Allows adjusting the impact of different user actions on their reputation.
     * @param _psWeight Weight for successful Problem Statement proposals.
     * @param _scWeight Weight for successful Solution Concept proposals.
     * @param _voteWeight Weight for successful votes cast.
     * @param _slashWeight Penalty weight for stake slashes.
     */
    function updateDRSWeights(uint256 _psWeight, uint256 _scWeight, uint256 _voteWeight, uint256 _slashWeight)
        public
        onlyOwner
    {
        drsWeightPS = _psWeight;
        drsWeightSC = _scWeight;
        drsWeightVote = _voteWeight;
        drsWeightSlash = _slashWeight;
        emit DRSWeightsUpdated(_psWeight, _scWeight, _voteWeight, _slashWeight);
    }

    /**
     * @dev Sets the base URI for Idea Genesis NFT metadata.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @dev Internal function to retrieve the base URI for ERC721 metadata.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // The ERC721 `tokenURI` function is implicitly available and will combine _baseURI() with tokenId.
    // If complex, per-token URI generation is needed, this function would be overridden.
}
```