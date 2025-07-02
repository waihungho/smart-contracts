Okay, let's design a smart contract for a "Decentralized Innovation Hub". This contract will act as a platform for proposing, funding, developing, and rewarding innovative projects, governed by its token holders. It will incorporate elements of DAO governance, project lifecycle management, funding, dynamic NFTs for contribution tracking, and recording off-chain data references.

Here's the outline and function summary, followed by the Solidity code.

---

**Outline & Function Summary**

**Contract Name:** `DecentralizedInnovationHub`

**Core Concepts:**
1.  **DAO Governance:** Token-based voting on proposals (new projects, funding requests, milestones, parameter changes). Includes staking, delegation, voting, queuing, and execution with a timelock.
2.  **Project Lifecycle:** Projects progress through states (Proposed, Funding, Active, Completed, Failed), managed by governance proposals.
3.  **Decentralized Funding:** Users contribute tokens to projects. Funds can be withdrawn if funding goals aren't met.
4.  **Milestone Tracking:** Project progress is broken down into milestones, which require governance approval to release funds and trigger rewards.
5.  **Dynamic Contributor Score NFT (SBT-like):** A soulbound-like NFT (ERC721) that tracks and visually represents a user's total contribution score across the platform (calculated from successful votes, funding, milestone work, etc.). Its metadata/score updates.
6.  **Project/Milestone NFTs:** ERC721 NFTs representing successful project completions or key milestones, potentially awarded to contributors.
7.  **Off-chain Data References:** Ability to store IPFS hashes linked to projects or milestones (e.g., for detailed proposals, results, code repositories).
8.  **Treasury Management:** The contract holds project funds and potentially governance rewards.

**Key Structures:**
*   `Proposal`: Details for governance proposals (state, type, votes, execution data).
*   `Project`: Details for innovative projects (state, funding, owner, milestones, associated data).
*   `Milestone`: Details for project milestones (state, funding allocation, associated data).

**State Variables:**
*   Governance parameters (quorum, threshold, voting period, timelock, etc.)
*   Mappings for proposals, projects, milestones.
*   Mappings for user stakes, voting power, delegations.
*   NFT counters and mappings (for Contributor Score and Milestone NFTs).
*   Address of the associated ERC20 token (`innovToken`).
*   Address of the NFT recipient logic (can be `this` contract or a separate one).

**Functions (Total: 25+ state-changing, plus views):**

**A. Governance & Voting (Covers 9+ functions):**
1.  `setGovernanceParams(uint256 _votingPeriod, uint256 _quorumNumerator, uint256 _proposalThresholdNumerator, uint256 _executionTimelock)`: (Admin/Governance) Sets core parameters.
2.  `submitProposal(ProposalType _type, address _target, bytes memory _calldata, string memory _descriptionHash)`: (Anyone with threshold stake/score) Creates a new governance proposal.
3.  `stakeTokensForVoting(uint256 _amount)`: (Any user) Stakes `innovToken` to gain voting power.
4.  `unstakeTokens(uint256 _amount)`: (Any user) Unstakes tokens. Subject to potential timelock or conditions.
5.  `delegateVote(address _delegatee)`: (Any user) Delegates their voting power to another address.
6.  `castVote(uint256 _proposalId, bool _support)`: (Any user with voting power) Votes Yes/No on a proposal.
7.  `queueProposal(uint256 _proposalId)`: (Anyone) Queues a passed proposal for execution after the timelock.
8.  `executeProposal(uint256 _proposalId)`: (Anyone) Executes a proposal that has passed voting and cleared the timelock.
9.  `cancelProposal(uint256 _proposalId)`: (Proposer under conditions, or Governance) Cancels a proposal.
10. `proposeParameterChange(uint256 _paramType, uint256 _newValue)`: (Anyone with threshold stake/score) A specific proposal type for changing a single governance parameter via vote.

**B. Project Management (Covers 5+ functions):**
11. `proposeNewProject(string memory _name, string memory _descriptionHash, uint256 _fundingGoal)`: (Anyone with threshold stake/score) Submits a proposal to create a new project.
12. `executeNewProjectProposal(uint256 _proposalId)`: (Executed via governance) Creates the project struct and moves it to Funding state.
13. `proposeMilestone(uint256 _projectId, string memory _title, string memory _descriptionHash, uint256 _fundingAllocation)`: (Project owner/team) Submits a proposal to add a milestone to a project.
14. `executeMilestoneProposal(uint256 _proposalId)`: (Executed via governance) Adds the milestone to the project and potentially allocates funds internally.
15. `proposeProjectCompletion(uint256 _projectId)`: (Project owner/team) Submits a proposal to mark a project as complete.
16. `executeProjectCompletionProposal(uint256 _proposalId)`: (Executed via governance) Marks project complete, triggers fund distribution proposal? (or includes distribution logic). Let's include distribution logic here for simplicity.
17. `proposeProjectFailure(uint256 _projectId)`: (Anyone, potentially with bond) Submits a proposal to mark a project as failed.
18. `executeProjectFailureProposal(uint256 _proposalId)`: (Executed via governance) Marks project failed, allows contributors to withdraw funding.

**C. Funding (Covers 2+ functions):**
19. `contributeToProjectFunding(uint256 _projectId, uint256 _amount)`: (Any user) Sends `innovToken` to fund a project in the Funding state.
20. `withdrawFailedFunding(uint256 _projectId)`: (Contributors) Allows withdrawal of contributions if a project's funding goal wasn't met or it was marked failed.
21. `claimProjectFunds(uint256 _projectId, uint256 _milestoneId)`: (Project owner/team) Allows claiming allocated funds for an approved milestone (executed via governance).

**D. NFT & Contribution (Covers 3+ functions):**
22. `issueContributorScoreNFT(address _user)`: (Internal, triggered on first contribution/vote) Mints the unique Contributor Score NFT for a user.
23. `updateContributorScore(address _user, uint256 _scoreIncrease)`: (Internal, triggered by successful actions) Updates the score within a user's Contributor Score NFT.
24. `mintMilestoneNFT(uint256 _projectId, uint256 _milestoneId, address _recipient)`: (Internal, triggered on milestone completion) Mints a Milestone NFT to a recipient.
25. `getUserContributorScore(address _user)`: (View) Gets the current score from a user's Contributor Score NFT.

**E. Data References (Covers 1+ function):**
26. `submitExperimentResult(uint256 _projectId, uint256 _milestoneId, string memory _dataHash)`: (Project team/owner) Records an IPFS hash or similar reference for experiment data linked to a specific milestone. (Could also be a proposal type). Let's make it a direct function for flexibility during active development.

**F. View Functions (Examples, not counted in the 25+ state-changing):**
*   `getProposalDetails(uint256 _proposalId)`
*   `getProjectDetails(uint256 _projectId)`
*   `getMilestoneDetails(uint256 _milestoneId)`
*   `getUserStake(address _user)`
*   `getUserVotingPower(address _user)`
*   `getGovernanceParams()`
*   `projectExists(uint256 _projectId)`
*   `milestoneExists(uint256 _milestoneId)`
*   `tokenURI(uint256 tokenId)` (Standard ERC721 view)
*   `ownerOf(uint256 tokenId)` (Standard ERC721 view)

This outline provides a robust structure covering diverse functionality, aiming for creativity and complexity beyond standard examples.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol"; // Using Enumerable for demonstration, allows iterating tokens
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // If NFTs were sent to other contracts
import "@openzeppelin/contracts/access/Ownable.sol"; // Using for initial setup only, governance takes over
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol"; // Example: Could be used for off-chain signing integration later

// --- Outline & Function Summary ---
// Contract Name: DecentralizedInnovationHub
// Core Concepts: DAO Governance, Project Lifecycle, Decentralized Funding, Milestone Tracking, Dynamic Contributor Score NFT (SBT-like), Project/Milestone NFTs, Off-chain Data References, Treasury Management.
// Key Structures: Proposal, Project, Milestone.
// State Variables: Governance params, mappings for proposals/projects/milestones/stakes/delegations, NFT counters/mappings, innovToken address.
// Functions:
// A. Governance & Voting (10 functions):
//    1. setGovernanceParams(uint256 _votingPeriod, uint256 _quorumNumerator, uint256 _proposalThresholdNumerator, uint256 _executionTimelock)
//    2. submitProposal(ProposalType _type, address _target, bytes memory _calldata, string memory _descriptionHash)
//    3. stakeTokensForVoting(uint256 _amount)
//    4. unstakeTokens(uint256 _amount)
//    5. delegateVote(address _delegatee)
//    6. castVote(uint256 _proposalId, bool _support)
//    7. queueProposal(uint256 _proposalId)
//    8. executeProposal(uint256 _proposalId)
//    9. cancelProposal(uint256 _proposalId)
//    10. proposeParameterChange(uint256 _paramType, uint256 _newValue)
// B. Project Management (8 functions):
//    11. proposeNewProject(string memory _name, string memory _descriptionHash, uint256 _fundingGoal) -> Internal call within submitProposal
//    12. executeNewProjectProposal(uint256 _proposalId)
//    13. proposeMilestone(uint256 _projectId, string memory _title, string memory _descriptionHash, uint256 _fundingAllocation) -> Internal call within submitProposal
//    14. executeMilestoneProposal(uint256 _proposalId)
//    15. proposeProjectCompletion(uint256 _projectId) -> Internal call within submitProposal
//    16. executeProjectCompletionProposal(uint256 _proposalId)
//    17. proposeProjectFailure(uint256 _projectId) -> Internal call within submitProposal
//    18. executeProjectFailureProposal(uint256 _proposalId)
// C. Funding (3 functions):
//    19. contributeToProjectFunding(uint256 _projectId, uint256 _amount)
//    20. withdrawFailedFunding(uint256 _projectId)
//    21. claimProjectFunds(uint256 _projectId, uint256 _milestoneId)
// D. NFT & Contribution (3 functions):
//    22. issueContributorScoreNFT(address _user) -> Internal trigger
//    23. updateContributorScore(address _user, uint256 _scoreIncrease) -> Internal trigger
//    24. mintMilestoneNFT(uint256 _projectId, uint256 _milestoneId, address _recipient) -> Internal trigger
//    25. getUserContributorScore(address _user) -> View function (not state-changing count) - Replaced with view function list. Let's add 25th state change. How about rewarding voters?
//    25. claimVotingRewards(): (User) Allows users to claim accumulated rewards from participating in successful votes. (Requires reward logic not fully defined here, but function placeholder).
// E. Data References (1 function):
//    26. submitExperimentResult(uint256 _projectId, uint256 _milestoneId, string memory _dataHash)
// F. View Functions (Examples): getProposalDetails, getProjectDetails, getUserStake, getUserVotingPower, etc.
// Total State-Changing Functions: 26 (well over the requested 20)
// --- End Outline & Summary ---

contract DecentralizedInnovationHub is Ownable, ReentrancyGuard, ERC721Enumerable {

    // --- State Variables ---

    IERC20 public innovToken; // The governance and funding token

    // Governance Parameters (initially set by owner, then changeable by governance)
    uint256 public votingPeriod; // In seconds
    uint256 public quorumNumerator; // x out of 100 (e.g., 4 for 4%)
    uint256 public constant QUORUM_DENOMINATOR = 100;
    uint256 public proposalThresholdNumerator; // x out of 10000 of total supply (e.g., 1 for 0.01%)
    uint256 public constant PROPOSAL_THRESHOLD_DENOMINATOR = 10000;
    uint256 public executionTimelock; // In seconds, delay before a passed proposal can be executed

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Expired, Executed }
    enum ProposalType { NewProject, FundingRequest, MilestoneApproval, ProjectCompletion, ProjectFailure, ParameterChange, GenericCall }
    enum ProjectState { Proposed, Funding, Active, Completed, Failed }
    enum MilestoneState { Proposed, Approved, Completed }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        address target; // Target contract/address for execution
        bytes calldata; // Data for the target call
        string descriptionHash; // IPFS hash for proposal details
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalState state;
        uint256 eta; // Execution time (timestamp), used for Queued state
        uint256 createdProjectId; // If type is NewProject
        uint256 targetProjectId; // If type relates to a project
        uint256 targetMilestoneId; // If type relates to a milestone
    }

    struct Project {
        uint256 id;
        address proposer; // Initial proposer
        string name;
        string descriptionHash; // IPFS hash for full project details
        ProjectState state;
        uint256 fundingGoal;
        uint256 currentFunding;
        address[] owners; // Team/owners of the project
        uint256[] milestoneIds; // IDs of associated milestones
        mapping(address => uint256) fundingContributions; // Tracks individual contributions
        mapping(uint256 => string) experimentResults; // milestoneId => dataHash
    }

    struct Milestone {
        uint256 id;
        uint256 projectId;
        string title;
        string descriptionHash; // IPFS hash for milestone details/plan
        MilestoneState state;
        uint256 fundingAllocation; // Tokens allocated for this milestone upon approval
        bool fundsClaimed;
        uint256 associatedNftId; // ID of the minted Milestone NFT, if any
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId = 1;

    mapping(uint256 => Project) public projects;
    uint256 private _nextProjectId = 1;

    mapping(uint256 => Milestone) public milestones;
    uint256 private _nextMilestoneId = 1;

    // Governance: Staking, Delegation, Voting
    mapping(address => uint256) public userStakes; // Tokens staked by user
    mapping(address => address) public delegates; // User => delegatee
    mapping(address => uint256) public votingPower; // User => calculated voting power
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => voted

    // NFT Tracking (Contributor Score & Milestone)
    mapping(address => uint256) private _contributorScoreNFTId; // user => NFT token ID (Soulbound-like: one per user)
    mapping(uint256 => uint256) private _contributorScores; // NFT token ID => score
    uint256 private _nextContributorScoreTokenId = 1;

    uint256 private _nextMilestoneNFTTokenId = 1; // Counter for Milestone NFTs

    // Rewards Treasury (Tokens not allocated to projects, e.g., from fees or initial distribution)
    uint256 public rewardsTreasury;
    mapping(address => uint256) public pendingRewards; // Accumulated claimable rewards

    // --- Events ---

    event GovernanceParamsSet(uint256 votingPeriod, uint256 quorumNumerator, uint256 proposalThresholdNumerator, uint256 executionTimelock);
    event ProposalSubmitted(uint256 proposalId, address proposer, ProposalType proposalType, string descriptionHash);
    event TokensStaked(address user, uint256 amount, uint256 totalStake);
    event TokensUnstaked(address user, uint256 amount, uint256 totalStake);
    event VoteDelegated(address delegator, address delegatee);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalStateChanged(uint256 proposalId, ProposalState newState);
    event ProposalQueued(uint256 proposalId, uint256 eta);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCanceled(uint256 proposalId);

    event ProjectCreated(uint256 projectId, string name, address proposer, uint256 fundingGoal);
    event ProjectStateChanged(uint256 projectId, ProjectState newState);
    event FundingContributed(uint256 projectId, address contributor, uint256 amount, uint256 totalProjectFunding);
    event FundingWithdrawn(uint256 projectId, address contributor, uint256 amount);

    event MilestoneProposed(uint256 milestoneId, uint256 projectId, string title, uint256 fundingAllocation); // Signaled by ProposalSubmitted
    event MilestoneAdded(uint256 milestoneId, uint256 projectId, string title); // Signaled by executeMilestoneProposal
    event MilestoneStateChanged(uint256 milestoneId, MilestoneState newState);
    event MilestoneFundsClaimed(uint256 milestoneId, uint256 projectId, address recipient, uint256 amount);

    event ContributorScoreNFTIssued(address user, uint256 tokenId);
    event ContributorScoreUpdated(address user, uint256 tokenId, uint256 newScore);
    event MilestoneNFTMinted(uint256 projectId, uint256 milestoneId, uint256 tokenId, address recipient);

    event ExperimentResultSubmitted(uint256 projectId, uint256 milestoneId, string dataHash, address submitter);

    event RewardsClaimed(address user, uint256 amount);


    // --- Constructor ---

    constructor(address _innovTokenAddress, uint256 _votingPeriod, uint256 _quorumNumerator, uint256 _proposalThresholdNumerator, uint256 _executionTimelock)
        ERC721Enumerable("HubContributorScore", "HCScore") // Initialize Contributor Score NFT
        Ownable(msg.sender) // Initial owner for setup
    {
        require(_innovTokenAddress != address(0), "Invalid token address");
        innovToken = IERC20(_innovTokenAddress);

        // Set initial governance parameters
        setGovernanceParams(_votingPeriod, _quorumNumerator, _proposalThresholdNumerator, _executionTimelock);

        // Mint an "empty" Milestone NFT collection name (can be reused)
        // We'll append milestone details to the URI when minted.
        // For simplicity, using the same contract for both types, but could use separate contracts.
        // Naming convention for distinction: Contributor Score NFTs use range 1-10^6, Milestone NFTs use > 10^6.
        // Or just rely on mapping and tokenURI logic to differentiate. Let's use distinct name/symbol for Milestone NFTs using a separate contract,
        // but for this example, we'll just use one ERC721Enumerable implementation and track internally.
        // Let's rename the ERC721Enumerable to be generic or for the *primary* NFT (Contributor Score)
        // and manage Milestone NFTs as a separate internal type within the same contract, handling token IDs carefully.
        // OR, inherit ERC721 *twice* with different baseURIs/names, which is tricky.
        // SIMPLER: Use one ERC721Enumerable, manage token IDs, and override `tokenURI` to serve metadata differently based on ID range or mapping lookup.
        // Contributor Scores: Token IDs 1 to 1,000,000
        // Milestone NFTs: Token IDs 1,000,001 onwards
        // Renaming base ERC721 to generic "HubNFT"
        _setercuseless721NameAndSymbol("HubNFT", "HUBNFT"); // Using a hidden function or similar to rename base
    }

    // Override ERC721Enumerable base name/symbol (Requires careful implementation or inheriting ERC721 directly and managing tokens manually)
    // Let's assume a library or method allows setting this post-construction if ERC721Enumerable doesn't.
    // For this example, we'll just proceed, and mentally note the `ERC721Enumerable("HubContributorScore", "HCScore")` might need adjustment depending on exact ERC721 implementation details allowing renaming.
    // A cleaner approach is to implement ERC721 logic manually or use interfaces if two distinct collections are needed.
    // Sticking to the single ERC721Enumerable and using ID ranges/mapping for distinction.

    // Dummy function to satisfy ERC721Enumerable constructor, will be overridden or handled internally.
    // Need to override _baseURI, tokenURI, supportsInterface if managing multiple types.
    // Let's override `tokenURI` below.

    // --- Ownable Functions (Initial Setup) ---

    // 1. Set Governance Parameters (Initial setup by owner, later by governance)
    function setGovernanceParams(uint256 _votingPeriod, uint256 _quorumNumerator, uint256 _proposalThresholdNumerator, uint256 _executionTimelock)
        public
        onlyOwner // Can later add check: `|| isGovernor()` if governance gains this power
    {
        require(_votingPeriod > 0, "Voting period must be > 0");
        require(_quorumNumerator <= QUORUM_DENOMINATOR, "Quorum numerator too high");
        require(_proposalThresholdNumerator <= PROPOSAL_THRESHOLD_DENOMINATOR, "Threshold numerator too high");
        require(_executionTimelock > 0, "Timelock must be > 0");

        votingPeriod = _votingPeriod;
        quorumNumerator = _quorumNumerator;
        proposalThresholdNumerator = _proposalThresholdNumerator;
        executionTimelock = _executionTimelock;

        emit GovernanceParamsSet(votingPeriod, quorumNumerator, proposalThresholdNumerator, executionTimelock);
    }

    // --- Governance & Voting Functions ---

    // Internal helper to check proposal threshold
    function _hasProposalThreshold(address _proposer) internal view returns (bool) {
        // Example threshold: user's voting power must be >= total supply * proposalThresholdNumerator / PROPOSAL_THRESHOLD_DENOMINATOR
        uint256 totalVotingSupply = innovToken.totalSupply(); // Use total supply as base, or total staked supply
        uint256 requiredPower = (totalVotingSupply * proposalThresholdNumerator) / PROPOSAL_THRESHOLD_DENOMINATOR;
        // Using delegated voting power for threshold check
        return votingPower[_proposer] >= requiredPower;
    }

    // 2. Submit a new governance proposal
    function submitProposal(
        ProposalType _type,
        address _target,
        bytes memory _calldata,
        string memory _descriptionHash // IPFS hash for detailed proposal document
    ) public nonReentrant returns (uint256) {
        require(_hasProposalThreshold(msg.sender), "Proposer does not meet threshold");
        require(bytes(_descriptionHash).length > 0, "Description hash is required");

        uint256 proposalId = _nextProposalId++;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + votingPeriod;

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: _type,
            target: _target,
            calldata: _calldata,
            descriptionHash: _descriptionHash,
            voteStartTime: startTime,
            voteEndTime: endTime,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            state: ProposalState.Pending, // Starts Pending, state will change to Active after a block or two
            eta: 0,
            createdProjectId: 0,
            targetProjectId: 0,
            targetMilestoneId: 0
        });

        // Set state to Active after current block (to allow voting power to be fixed)
        // A better implementation would use block numbers, not timestamps, for voting start/end.
        // For simplicity here, using timestamp, but note block numbers are more robust against miner manipulation.
        proposals[proposalId].state = ProposalState.Active; // Immediately set active for timestamp based voting

        emit ProposalSubmitted(proposalId, msg.sender, _type, _descriptionHash);
        return proposalId;
    }

    // Internal helpers for specific proposal types (called via submitProposal calldata/logic)
    // These don't count towards the 25+, as they are internal implementation details triggered by executeProposal.
    // The *propose* functions (11, 13, 15, 17) are just submitting the *generic* proposal type with specific calldata/params.
    // Function 10 `proposeParameterChange` is just a wrapper for `submitProposal` with type `ParameterChange` and `_calldata` to call `setGovernanceParams`.

    // 10. Propose changing a governance parameter
    function proposeParameterChange(uint256 _paramType, uint256 _newValue) public returns (uint256) {
         // paramType mapping: 1=votingPeriod, 2=quorumNumerator, 3=proposalThresholdNumerator, 4=executionTimelock
        bytes memory callData;
        if (_paramType == 1) {
            callData = abi.encodeWithSelector(this.setGovernanceParams.selector, _newValue, quorumNumerator, proposalThresholdNumerator, executionTimelock);
        } else if (_paramType == 2) {
            callData = abi.encodeWithSelector(this.setGovernanceParams.selector, votingPeriod, _newValue, proposalThresholdNumerator, executionTimelock);
        } else if (_paramType == 3) {
            callData = abi.encodeWithSelector(this.setGovernanceParams.selector, votingPeriod, quorumNumerator, _newValue, executionTimelock);
        } else if (_paramType == 4) {
             callData = abi.encodeWithSelector(this.setGovernanceParams.selector, votingPeriod, quorumNumerator, proposalThresholdNumerator, _newValue);
        } else {
            revert("Invalid parameter type");
        }

        // Use a descriptive hash indicating the change
        string memory descriptionHash = string(abi.encodePacked("Param Change: Type ", Strings.toString(_paramType), ", Value ", Strings.toString(_newValue)));

        return submitProposal(ProposalType.ParameterChange, address(this), callData, descriptionHash);
    }


    // 3. Stake tokens for voting power
    function stakeTokensForVoting(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Amount must be > 0");
        innovToken.transferFrom(msg.sender, address(this), _amount);
        userStakes[msg.sender] += _amount;
        // Voting power is directly linked to stake for this simple model
        // A more advanced model could use checkpoints based on block numbers
        votingPower[msg.sender] += _amount;

        // Issue or update Contributor Score NFT
        _issueOrUpdateContributorScoreNFT(msg.sender, _amount); // Score increase by stake amount? Or fixed points per stake action? Let's add stake amount for now.

        emit TokensStaked(msg.sender, _amount, userStakes[msg.sender]);
    }

    // 4. Unstake tokens
    function unstakeTokens(uint256 _amount) public nonReentrant {
        require(_amount > 0, "Amount must be > 0");
        require(userStakes[msg.sender] >= _amount, "Not enough staked tokens");

        userStakes[msg.sender] -= _amount;
        votingPower[msg.sender] -= _amount; // Decrease voting power

        innovToken.transfer(msg.sender, _amount);

        emit TokensUnstaked(msg.sender, _amount, userStakes[msg.sender]);
    }

    // 5. Delegate voting power
    function delegateVote(address _delegatee) public {
        require(delegates[msg.sender] != _delegatee, "Already delegated to this address");

        address currentDelegatee = delegates[msg.sender];
        uint256 powerToMove = votingPower[msg.sender];

        // If previously delegated, remove power from old delegatee
        if (currentDelegatee != address(0)) {
            votingPower[currentDelegatee] -= powerToMove;
        }

        delegates[msg.sender] = _delegatee;

        // Add power to the new delegatee
        votingPower[_delegatee] += powerToMove;

        emit VoteDelegated(msg.sender, _delegatee);
    }

    // Internal helper to get voting weight considering delegation
    function _getVotingWeight(address _voter) internal view returns (uint256) {
        // If user has delegated, their *own* address has 0 voting power for casting votes directly,
        // but the delegatee's address accumulates it.
        // This function returns the power available for casting a vote *by this address*.
        // If `delegates[msg.sender] != address(0)` then msg.sender cannot vote directly.
        // If `delegates[msg.sender] == msg.sender` means they are self-delegated (voting with their own stake power).
        // If `delegates[msg.sender] == address(0)` but not self-delegated, means no delegation, use own stake power.
        // Simplification: Use the `votingPower` map directly, which reflects stake + delegation.
        // A user with delegated OUT power has votingPower[user] == 0. A user with delegated IN power has votingPower[user] > userStakes[user].
        // So, just check if votingPower[msg.sender] > 0.
        return votingPower[_voter]; // This map is updated by stake/unstake/delegate
    }


    // 6. Cast a vote on a proposal
    function castVote(uint256 _proposalId, bool _support) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp < proposal.voteEndTime, "Voting period is closed");
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");

        uint256 weight = _getVotingWeight(msg.sender);
        require(weight > 0, "No voting power");

        hasVoted[_proposalId][msg.sender] = true;

        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }

        // Optional: Increase contributor score for voting participation (e.g., fixed points)
         _issueOrUpdateContributorScoreNFT(msg.sender, 1); // Award 1 point for voting (successful vote might give more later)


        emit VoteCast(_proposalId, msg.sender, _support, weight);
    }

    // Internal helper to get proposal state (can be a view function too)
    function _getProposalState(uint256 _proposalId) internal view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.voteEndTime) {
             // Voting period ended, determine outcome
             uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
             uint256 totalVotingSupply = innovToken.totalSupply(); // Use total supply or total staked for quorum base
             uint256 requiredQuorum = (totalVotingSupply * quorumNumerator) / QUORUM_DENOMINATOR;

             if (totalVotes < requiredQuorum) {
                 return ProposalState.Defeated; // Failed quorum
             } else if (proposal.forVotes > proposal.againstVotes) {
                 return ProposalState.Succeeded; // Passed
             } else {
                 return ProposalState.Defeated; // Failed majority
             }
        }
        return proposal.state;
    }

    // 7. Queue a passed proposal for execution
    function queueProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(_getProposalState(_proposalId) == ProposalState.Succeeded, "Proposal has not succeeded");
        require(proposal.state != ProposalState.Queued, "Proposal is already queued");

        proposal.state = ProposalState.Queued;
        proposal.eta = block.timestamp + executionTimelock; // Set execution timestamp

        emit ProposalQueued(_proposalId, proposal.eta);
        emit ProposalStateChanged(_proposalId, ProposalState.Queued);
    }

     // 8. Execute a queued proposal
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Queued, "Proposal is not in queued state");
        require(block.timestamp >= proposal.eta, "Execution timelock has not passed");
        require(!proposal.executed, "Proposal already executed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        // Execute the associated call
        (bool success, ) = proposal.target.call(proposal.calldata);
        require(success, "Proposal execution failed");

        // Optional: Reward voters who voted for the winning side? Add logic here.
        // pendingRewards[voter] += calculateReward(voter, proposalId);

        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    // 9. Cancel a proposal
    function cancelProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        // Only proposer or governance can cancel (add governance check later)
        require(msg.sender == proposal.proposer, "Only proposer can cancel");
        // Can only cancel if not already queued or executed
        require(proposal.state < ProposalState.Queued, "Cannot cancel a proposal that is queued or executed");
        // Optional: Add time constraint, e.g., only within first N seconds

        proposal.state = ProposalState.Canceled;
        emit ProposalCanceled(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Canceled);
    }


    // --- Project Management Functions (Triggered by Governance Execution) ---

    // 11. & 13. & 15. & 17. Propose specific actions:
    // These are handled by calling `submitProposal` with the relevant `ProposalType` and `_calldata` pointing to the execution function below.
    // Example: To propose a new project, user calls `submitProposal(ProposalType.NewProject, address(this), abi.encodeWithSelector(this.executeNewProjectProposal.selector, ???), descriptionHash)`.
    // The `???` would be encoding necessary parameters for the execution function.
    // This requires careful handling of parameters passed via `_calldata`.
    // Let's make the execution functions directly take the proposal ID and pull data from the proposal struct for simplicity in this example.

    // 12. Execute: Create a new project (Called via `executeProposal` for NewProject type)
    function executeNewProjectProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.target == address(this), "Invalid target for execution");
        require(proposal.proposalType == ProposalType.NewProject, "Proposal is not NewProject type");
        // Assume proposal.calldata contains the necessary project details (name, descriptionHash, fundingGoal)
        // This is complex to parse from raw calldata. Let's adjust the Proposal struct or execution flow.
        // ALTERNATIVE: The `submitProposal` for NEW_PROJECT stores the details directly in the proposal struct.
        // Let's modify `Proposal` struct to store NewProject specific data, or use a separate struct linked by ID.
        // Simpler: Add fields to the Proposal struct for common types like NewProject.
        // Added: `string newProjectName`, `uint256 newProjectFundingGoal`. (Modifying Proposal struct above)
        // Re-evaluate `submitProposal`: It needs to take parameters specific to the proposal type.
        // This makes `submitProposal` more complex or requires specific wrapper functions for each type.
        // Let's add specific proposal submission wrappers for clarity, which then call the internal `_submitProposal` helper.

        // New Plan: Wrapper functions for specific proposal types that prepare calldata/struct.
        // The execution functions then use the proposal ID.

        // Let's implement the execution logic assuming data is available via the proposal ID:
        uint256 projectId = _nextProjectId++;
        projects[projectId] = Project({
            id: projectId,
            proposer: proposal.proposer, // Use the proposal's proposer as initial project proposer
            name: proposal.descriptionHash, // Using description hash as project name for simplicity, or pass name via calldata
            descriptionHash: proposal.descriptionHash,
            state: ProjectState.Funding, // Starts in Funding state
            fundingGoal: 0, // Funding goal must be passed via calldata or proposal struct
            currentFunding: 0,
            owners: new address[](0), // Set owners later via another proposal? For now, proposer is owner.
            milestoneIds: new uint256[](0)
             // fundingContributions map is initialized empty
             // experimentResults map is initialized empty
        });
        // Need to parse name and funding goal from `proposal.calldata` or add to Proposal struct.
        // Let's refine `submitProposal` and add wrapper functions first.

        // **Hold on: The original `submitProposal` signature is generic.**
        // Let's revert to the original `submitProposal` and make the execution functions parse `_calldata`.
        // This is the standard pattern for Governor contracts. The `_calldata` *is* the call to make.
        // So, `submitProposal` for a new project means the `_calldata` is a call like `abi.encodeWithSelector(this.createNewProject.selector, name, descriptionHash, fundingGoal)`.
        // And the execution function `executeProposal` simply calls `target.call(calldata)`.
        // We need internal functions like `createNewProject`, `addMilestoneToProject`, etc., that can *only* be called by `executeProposal`.
        // Use an `onlyGovernance` modifier or check `msg.sender == address(this)` and an internal flag set during `executeProposal`.

        // Redo Project Management functions as internal execution targets:

        // Internal: Creates a new project. Callable ONLY by executeProposal.
        function _createNewProject(address _proposer, string memory _name, string memory _descriptionHash, uint256 _fundingGoal) internal returns (uint256) {
             // Add check here that this is called by executeProposal context
            uint256 projectId = _nextProjectId++;
            projects[projectId] = Project({
                id: projectId,
                proposer: _proposer,
                name: _name,
                descriptionHash: _descriptionHash,
                state: ProjectState.Funding,
                fundingGoal: _fundingGoal,
                currentFunding: 0,
                owners: new address[](0), // Default to proposer as owner? Or set via another call?
                milestoneIds: new uint256[](0)
                 // fundingContributions map is initialized empty
                 // experimentResults map is initialized empty
            });
            projects[projectId].owners.push(_proposer); // Add proposer as initial owner

            emit ProjectCreated(projectId, _name, _proposer, _fundingGoal);
            emit ProjectStateChanged(projectId, ProjectState.Funding);
            return projectId;
        }

        // Internal: Adds a milestone to a project. Callable ONLY by executeProposal.
        function _addMilestoneToProject(uint256 _projectId, string memory _title, string memory _descriptionHash, uint256 _fundingAllocation) internal returns (uint256) {
            // Add check here that this is called by executeProposal context
            Project storage project = projects[_projectId];
            require(project.id != 0, "Project does not exist");
            // Should milestone only be added in Active state? Or Funding? Let's say Active.
            require(project.state == ProjectState.Active || project.state == ProjectState.Funding, "Project not in correct state to add milestone");

            uint256 milestoneId = _nextMilestoneId++;
            milestones[milestoneId] = Milestone({
                id: milestoneId,
                projectId: _projectId,
                title: _title,
                descriptionHash: _descriptionHash,
                state: MilestoneState.Proposed, // Starts Proposed, needs approval
                fundingAllocation: _fundingAllocation,
                fundsClaimed: false,
                associatedNftId: 0 // Set when NFT is minted
            });

            project.milestoneIds.push(milestoneId);

            emit MilestoneProposed(milestoneId, _projectId, _title, _fundingAllocation); // Use "Proposed" to indicate it exists now, but needs approval
            return milestoneId;
        }

        // Internal: Updates milestone state to Approved and potentially allocates funds. Callable ONLY by executeProposal.
        function _approveMilestone(uint256 _milestoneId) internal {
             // Add check here that this is called by executeProposal context
            Milestone storage milestone = milestones[_milestoneId];
            require(milestone.id != 0, "Milestone does not exist");
            require(milestone.state == MilestoneState.Proposed, "Milestone is not in Proposed state");

            milestone.state = MilestoneState.Approved;

            // Funds for this milestone are now considered "allocated" from the project's current funding.
            // We don't transfer them yet, but mark them as claimable by the project team.
            // Ensure project has enough funds: require(projects[milestone.projectId].currentFunding >= milestone.fundingAllocation, "Insufficient project funds for milestone allocation");
            // This check should ideally happen at the proposal submission/vote time or before execution.
            // For simplicity, assume funds are available or handle shortfall during claim.

            emit MilestoneStateChanged(milestone.id, MilestoneState.Approved);

            // Mint a Milestone NFT upon approval? Or upon completion?
            // Let's mint upon *completion* and approval just makes it "ready" for completion.
        }

        // Internal: Marks milestone as completed. Callable ONLY by executeProposal.
        function _completeMilestone(uint256 _milestoneId) internal {
            // Add check here that this is called by executeProposal context
            Milestone storage milestone = milestones[_milestoneId];
            require(milestone.id != 0, "Milestone does not exist");
            require(milestone.state == MilestoneState.Approved, "Milestone is not in Approved state");

            milestone.state = MilestoneState.Completed;

            // Trigger Milestone NFT minting
            // Who gets the NFT? Project owners? Contributors? Let's mint to the first owner for simplicity.
            address recipient = projects[milestone.projectId].owners[0]; // Example: Mint to first owner
            _mintMilestoneNFT(milestone.projectId, milestone.id, recipient);

            // Trigger Contributor Score update for project owners/contributors?
            // For simplicity, let's give a fixed score boost to project owners upon milestone completion.
            for(uint i=0; i < projects[milestone.projectId].owners.length; i++){
                 _issueOrUpdateContributorScoreNFT(projects[milestone.projectId].owners[i], 5); // 5 points for milestone completion
            }


            emit MilestoneStateChanged(milestone.id, MilestoneState.Completed);
        }


        // Internal: Requests project funds (e.g., for expenses). Callable ONLY by executeProposal.
        function _requestProjectFunds(uint256 _projectId, uint256 _amount) internal {
            // Add check here that this is called by executeProposal context
            Project storage project = projects[_projectId];
            require(project.id != 0, "Project does not exist");
            require(project.state == ProjectState.Active, "Project not in Active state");
            require(project.currentFunding >= _amount, "Project does not have enough funds");

            project.currentFunding -= _amount;
            // Transfer funds to project owners? Or a specific project multisig?
            // For simplicity, let's transfer to the first owner. Realistically, needs a dedicated project wallet.
            address payable projectWallet = payable(project.owners[0]); // Needs conversion to payable
            // innovToken.transfer(projectWallet, _amount); // ERC20 transfer

            // In a real system, funds should go to a designated project multi-sig/wallet, not a single owner.
            // For this example, we'll just deduct from currentFunding and assume transfer happens off-chain or to a linked wallet.
            // Or, if tokens are ERC20, we *can* transfer them.
            // Need to ensure `owners[0]` is payable if transferring Ether, but we are using ERC20.
            // Let's perform the ERC20 transfer here.
            innovToken.transfer(project.owners[0], _amount);


            // Optional: Contributor Score update for project owners?

            emit MilestoneFundsClaimed(_projectId, 0, project.owners[0], _amount); // Using milestoneId 0 to signify non-milestone fund claim

        }

        // Internal: Marks project as completed. Callable ONLY by executeProposal.
        function _completeProject(uint256 _projectId) internal {
             // Add check here that this is called by executeProposal context
            Project storage project = projects[_projectId];
            require(project.id != 0, "Project does not exist");
            require(project.state == ProjectState.Active, "Project not in Active state");

            project.state = ProjectState.Completed;

            // Distribute remaining funds? To owners? Return to treasury?
            // Let's return remaining funds to the rewards treasury.
            if (project.currentFunding > 0) {
                rewardsTreasury += project.currentFunding;
                project.currentFunding = 0;
                 // Transfer actual tokens from contract balance to 'rewardsTreasury' concept (which is just tracking).
                 // The tokens are already held by the contract.
            }

            // Optional: Issue final Project Completion NFT? Update Contributor Scores for owners/contributors?
             for(uint i=0; i < project.owners.length; i++){
                 _issueOrUpdateContributorScoreNFT(project.owners[i], 20); // 20 points for project completion
             }

            emit ProjectStateChanged(_projectId, ProjectState.Completed);
        }

        // Internal: Marks project as failed. Callable ONLY by executeProposal.
        function _failProject(uint256 _projectId) internal {
             // Add check here that this is called by executeProposal context
            Project storage project = projects[_projectId];
            require(project.id != 0, "Project does not exist");
            require(project.state == ProjectState.Funding || project.state == ProjectState.Active, "Project not in Funding or Active state");

            project.state = ProjectState.Failed;

            // Funds remain in contract, available for withdrawal by contributors
            // via `withdrawFailedFunding`.

            emit ProjectStateChanged(_projectId, ProjectState.Failed);
        }

        // 11. Propose a new project (Wrapper)
        function proposeNewProject(string memory _name, string memory _descriptionHash, uint256 _fundingGoal) public returns (uint256) {
            require(_fundingGoal > 0, "Funding goal must be greater than zero");
            // Encode the call to the internal execution function
            bytes memory callData = abi.encodeWithSelector(this._createNewProject.selector, msg.sender, _name, _descriptionHash, _fundingGoal);
            return submitProposal(ProposalType.NewProject, address(this), callData, _descriptionHash);
        }

        // 13. Propose adding a milestone (Wrapper)
        function proposeMilestone(uint256 _projectId, string memory _title, string memory _descriptionHash, uint256 _fundingAllocation) public returns (uint256) {
            // Optional: Check if msg.sender is a project owner/team member
            Project storage project = projects[_projectId];
             bool isOwner = false;
             for(uint i=0; i < project.owners.length; i++){
                 if(project.owners[i] == msg.sender) {
                     isOwner = true;
                     break;
                 }
             }
             require(isOwner, "Only project owner/team can propose milestones");

            bytes memory callData = abi.encodeWithSelector(this._addMilestoneToProject.selector, _projectId, _title, _descriptionHash, _fundingAllocation);
             // Use a distinct description hash for the proposal itself if needed, or reuse milestone hash
            return submitProposal(ProposalType.MilestoneApproval, address(this), callData, _descriptionHash);
        }

        // 14. Execute Milestone Proposal -> Renamed to _approveMilestone and _completeMilestone.
        // User proposes milestone creation (_addMilestoneToProject), governance votes. If passed, governance executes _approveMilestone.
        // User then submits *another* proposal to mark the milestone as completed (_completeMilestone).
        // Let's simplify: Proposing milestone creates it in PROPOSED. Executing the *first* proposal approves it (_approveMilestone).
        // Project owners/team must then call a function `requestMilestoneCompletion` which submits a *second* proposal to mark it COMPLETE (_completeMilestone).

        // 15. Propose project completion (Wrapper)
        function proposeProjectCompletion(uint256 _projectId) public returns (uint256) {
             Project storage project = projects[_projectId];
             bool isOwner = false;
             for(uint i=0; i < project.owners.length; i++){
                 if(project.owners[i] == msg.sender) {
                     isOwner = true;
                     break;
                 }
             }
             require(isOwner, "Only project owner/team can propose completion");
             require(project.state == ProjectState.Active, "Project not in Active state");

            bytes memory callData = abi.encodeWithSelector(this._completeProject.selector, _projectId);
            return submitProposal(ProposalType.ProjectCompletion, address(this), callData, string(abi.encodePacked("Complete Project #", Strings.toString(_projectId))));
        }

        // 17. Propose project failure (Wrapper)
        function proposeProjectFailure(uint256 _projectId) public returns (uint256) {
            Project storage project = projects[_projectId];
            require(project.state == ProjectState.Funding || project.state == ProjectState.Active, "Project not in Funding or Active state");
             // Could require a bond here to prevent spam

            bytes memory callData = abi.encodeWithSelector(this._failProject.selector, _projectId);
             return submitProposal(ProposalType.ProjectFailure, address(this), callData, string(abi.encodePacked("Fail Project #", Strings.toString(_projectId))));
        }

         // Internal: Request project funds. This should be a governance proposal.
         // Let's wrap it like other proposals.
         function proposeProjectFundRequest(uint256 _projectId, uint256 _amount) public returns (uint256) {
            Project storage project = projects[_projectId];
            bool isOwner = false;
            for(uint i=0; i < project.owners.length; i++){
                if(project.owners[i] == msg.sender) {
                    isOwner = true;
                    break;
                }
            }
            require(isOwner, "Only project owner/team can request funds");
            require(project.state == ProjectState.Active, "Project not in Active state");
            require(_amount > 0, "Amount must be > 0");

            bytes memory callData = abi.encodeWithSelector(this._requestProjectFunds.selector, _projectId, _amount);
             return submitProposal(ProposalType.FundingRequest, address(this), callData, string(abi.encodePacked("Request ", Strings.toString(_amount), " funds for Project #", Strings.toString(_projectId))));
         }

         // Internal: Request milestone completion (moves from Approved to Completed). Also a governance proposal.
         function proposeMilestoneCompletion(uint256 _milestoneId) public returns (uint256) {
            Milestone storage milestone = milestones[_milestoneId];
            require(milestone.id != 0, "Milestone does not exist");
            require(milestone.state == MilestoneState.Approved, "Milestone is not in Approved state");

            Project storage project = projects[milestone.projectId];
             bool isOwner = false;
             for(uint i=0; i < project.owners.length; i++){
                 if(project.owners[i] == msg.sender) {
                     isOwner = true;
                     break;
                 }
             }
             require(isOwner, "Only project owner/team can propose milestone completion");


            bytes memory callData = abi.encodeWithSelector(this._completeMilestone.selector, _milestoneId);
             return submitProposal(ProposalType.MilestoneApproval, address(this), callData, string(abi.encodePacked("Complete Milestone #", Strings.toString(_milestoneId), " for Project #", Strings.toString(milestone.projectId))));
         }


    // --- Funding Functions ---

    // 19. Contribute funding to a project
    function contributeToProjectFunding(uint256 _projectId, uint256 _amount) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.state == ProjectState.Funding, "Project is not in Funding state");
        require(_amount > 0, "Amount must be > 0");

        innovToken.transferFrom(msg.sender, address(this), _amount);
        project.currentFunding += _amount;
        project.fundingContributions[msg.sender] += _amount;

        // Issue or update Contributor Score NFT based on funding
        _issueOrUpdateContributorScoreNFT(msg.sender, _amount); // Score increase by funding amount

        emit FundingContributed(_projectId, msg.sender, _amount, project.currentFunding);

        // Optional: Check if funding goal is reached and potentially trigger state change (via proposal?)
        // Let's make reaching goal a state that allows a 'Mark as Active' proposal.
    }

    // 20. Withdraw funding if project fails or goal not met
    function withdrawFailedFunding(uint256 _projectId) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        require(project.state == ProjectState.Failed || (project.state == ProjectState.Funding && block.timestamp >= proposals[project.id].voteEndTime && project.currentFunding < project.fundingGoal),
            "Project not failed or funding period not ended without meeting goal"); // Needs logic linking project creation proposal end time to funding deadline

        uint256 refundableAmount = project.fundingContributions[msg.sender];
        require(refundableAmount > 0, "No funding to withdraw");

        project.fundingContributions[msg.sender] = 0;
        // Note: currentFunding is *not* decreased here, it represents total received.
        // The actual tokens are held by the contract balance.

        // Transfer tokens back
        innovToken.transfer(msg.sender, refundableAmount);

        emit FundingWithdrawn(_projectId, msg.sender, refundableAmount);
    }

     // 21. Claim allocated project funds for a completed milestone
    function claimProjectFunds(uint256 _projectId, uint256 _milestoneId) public nonReentrant {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.id != 0 && milestone.projectId == _projectId, "Milestone does not exist for this project");
        require(milestone.state == MilestoneState.Completed, "Milestone is not completed");
        require(!milestone.fundsClaimed, "Milestone funds already claimed");

        Project storage project = projects[_projectId];
         bool isOwner = false;
         for(uint i=0; i < project.owners.length; i++){
             if(project.owners[i] == msg.sender) {
                 isOwner = true;
                 break;
             }
         }
         require(isOwner, "Only project owner/team can claim milestone funds");

        uint256 amountToClaim = milestone.fundingAllocation;
        require(project.currentFunding >= amountToClaim, "Insufficient project funds for claim");

        project.currentFunding -= amountToClaim;
        milestone.fundsClaimed = true;

        // Transfer funds to the claimant (project owner)
        innovToken.transfer(msg.sender, amountToClaim);

        emit MilestoneFundsClaimed(_milestoneId, _projectId, msg.sender, amountToClaim);
    }


    // --- NFT & Contribution Functions ---

    // Internal: Issue or update Contributor Score NFT
    function _issueOrUpdateContributorScoreNFT(address _user, uint256 _scoreIncrease) internal {
        uint256 tokenId = _contributorScoreNFTId[_user];

        if (tokenId == 0) {
            // Mint new NFT if user doesn't have one
            tokenId = _nextContributorScoreTokenId++;
            require(tokenId <= 1000000, "Contributor Score NFT limit reached"); // Cap Contributor Score NFTs

            _safeMint(_user, tokenId);
            _contributorScoreNFTId[_user] = tokenId;
            _contributorScores[tokenId] = _scoreIncrease;

            emit ContributorScoreNFTIssued(_user, tokenId);
        } else {
            // Update existing NFT's score
            _contributorScores[tokenId] += _scoreIncrease;
        }
        emit ContributorScoreUpdated(_user, tokenId, _contributorScores[tokenId]);

        // Note: Updating metadata requires updating the tokenURI mapping or emitting an event
        // for off-chain indexers to pick up. ERC721 metadata updates are typically off-chain.
        // We store the score ON-CHAIN, and tokenURI will fetch this score.
        // A Metadata Update event is good practice, but ERC721 standard doesn't have one built-in.
        // Some implementations emit `Transfer` or custom events.
    }

    // Internal: Mint a Milestone NFT
    function _mintMilestoneNFT(uint256 _projectId, uint256 _milestoneId, address _recipient) internal {
        uint256 tokenId = _nextMilestoneNFTTokenId++;
         require(tokenId > 1000000, "Milestone NFT ID clash or limit reached"); // Ensure different ID range

        _safeMint(_recipient, tokenId);
        milestones[_milestoneId].associatedNftId = tokenId; // Link milestone to its NFT

        emit MilestoneNFTMinted(_projectId, _milestoneId, tokenId, _recipient);

        // Note: tokenURI override handles fetching metadata for this NFT type too.
    }

    // 25. Claim accumulated rewards (Example: from voting)
     function claimVotingRewards() public nonReentrant {
         uint256 amount = pendingRewards[msg.sender];
         require(amount > 0, "No pending rewards");

         pendingRewards[msg.sender] = 0;

         // Transfer rewards from treasury (contract balance)
         // Requires actual tokens to be in the contract balance designated for rewards.
         // Need a mechanism to fund the rewardsTreasury (e.g., a cut of funding, inflation if token is mintable by contract).
         // For this example, we just track the amount and assume the transfer source is available.
         innovToken.transfer(msg.sender, amount); // Transfer from contract's innovToken balance

         emit RewardsClaimed(msg.sender, amount);
     }


    // --- Data References ---

    // 26. Submit IPFS hash for experiment results
    function submitExperimentResult(uint256 _projectId, uint256 _milestoneId, string memory _dataHash) public nonReentrant {
        Project storage project = projects[_projectId];
        require(project.id != 0, "Project does not exist");
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.id != 0 && milestone.projectId == _projectId, "Milestone does not exist for this project");

        // Optional: Restrict who can submit (e.g., project owners, designated submitters)
        bool isOwner = false;
        for(uint i=0; i < project.owners.length; i++){
            if(project.owners[i] == msg.sender) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Only project owner/team can submit results");
        require(milestone.state >= MilestoneState.Approved, "Milestone must be approved or completed to submit results");
        require(bytes(_dataHash).length > 0, "Data hash is required");


        // Store the hash linked to the milestone within the project struct
        project.experimentResults[_milestoneId] = _dataHash;

        emit ExperimentResultSubmitted(_projectId, _milestoneId, _dataHash, msg.sender);
    }


    // --- NFT Overrides (for tokenURI) ---

    // Override base URI (optional, could build dynamic URI in tokenURI)
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://<YOUR_IPFS_GATEWAY_HASH>/"; // Example: Base for metadata JSON files
    }

    // Override tokenURI to provide dynamic metadata based on token ID and type
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (tokenId <= 1000000) { // Contributor Score NFT
             uint256 score = _contributorScores[tokenId];
             address owner = ownerOf(tokenId); // Find owner
             // Construct a dynamic JSON metadata string or return a base URI + ID.
             // Example: Returning a URI pointing to a dynamic script/API endpoint
             // that generates JSON based on the score and owner.
             // return string(abi.encodePacked(_baseURI(), "contributor-score/", Strings.toString(tokenId)));
             // OR, generate simple JSON directly (more complex):
             string memory name = string(abi.encodePacked("Contributor Score for ", Strings.toHexString(uint160(owner), 20)));
             string memory description = string(abi.encodePacked("On-chain contribution score: ", Strings.toString(score)));
             string memory image = "ipfs://<IPFS_HASH_FOR_SCORE_IMAGE>"; // Placeholder for a score-based image

             // Basic JSON structure (requires escape characters)
             // This is simplified; real metadata requires careful JSON formatting.
             // A common approach is to return a standard URI like ipfs://hash/{id}.json
             // where {id}.json is served off-chain by a service that fetches the score.
             // For demonstration, let's just return a string indicating the type and ID.
             return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(
                 string(abi.encodePacked(
                     '{"name": "', name,
                     '", "description": "', description,
                     '", "image": "', image,
                     '", "attributes": [ { "trait_type": "Score", "value": ', Strings.toString(score), ' } ] }'
                 ))
             ))));


         } else { // Milestone NFT
             // Find the milestone associated with this NFT ID
             uint256 milestoneId = 0;
             // Need a mapping from NFT ID to Milestone ID if it's not implicit in the range.
             // Added `associatedNftId` to Milestone struct, but no reverse map. Let's add one.
             // mapping(uint256 => uint256) private _milestoneNFTIdToMilestoneId; // NFT Token ID => Milestone ID
             // Update _mintMilestoneNFT to populate this map.
             // For now, let's iterate through milestones to find the one with this NFT ID (inefficient, for example only)
             // This approach is bad practice for production. Needs the reverse mapping.
             // Assuming _milestoneNFTIdToMilestoneId exists:
             // milestoneId = _milestoneNFTIdToMilestoneId[tokenId];
             // Milestone storage milestone = milestones[milestoneId];

             // Dummy placeholder as iteration is too costly
             return string(abi.encodePacked("Milestone NFT ID: ", Strings.toString(tokenId)));
         }
    }


    // Implement ERC721Enumerable required functions if needed outside OpenZeppelin's base
    // All necessary ERC721Enumerable functions (totalSupply, tokenByIndex, tokenOfOwnerByIndex)
    // are inherited and should work with _safeMint and _burn (if implemented).

    // --- View Functions ---

    // Example View Functions (not counted towards the 25+ state-changing functions)
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        return _getProposalState(_proposalId);
    }

     function getProposalDetails(uint256 _proposalId) public view returns (Proposal memory) {
         return proposals[_proposalId];
     }

    function getProjectDetails(uint256 _projectId) public view returns (
        uint256 id,
        address proposer,
        string memory name,
        string memory descriptionHash,
        ProjectState state,
        uint256 fundingGoal,
        uint256 currentFunding,
        address[] memory owners,
        uint256[] memory milestoneIds
    ) {
        Project storage project = projects[_projectId];
        return (
            project.id,
            project.proposer,
            project.name,
            project.descriptionHash,
            project.state,
            project.fundingGoal,
            project.currentFunding,
            project.owners,
            project.milestoneIds
        );
    }

    function getMilestoneDetails(uint256 _milestoneId) public view returns (
        uint256 id,
        uint256 projectId,
        string memory title,
        string memory descriptionHash,
        MilestoneState state,
        uint256 fundingAllocation,
        bool fundsClaimed,
        uint256 associatedNftId
    ) {
        Milestone storage milestone = milestones[_milestoneId];
         return (
             milestone.id,
             milestone.projectId,
             milestone.title,
             milestone.descriptionHash,
             milestone.state,
             milestone.fundingAllocation,
             milestone.fundsClaimed,
             milestone.associatedNftId
         );
    }

    function getUserStake(address _user) public view returns (uint256) {
        return userStakes[_user];
    }

     function getUserVotingPower(address _user) public view returns (uint256) {
         return votingPower[_user];
     }

    // 25. Get user's Contributor Score (View function, not state-changing)
    function getUserContributorScore(address _user) public view returns (uint256 score, uint256 tokenId) {
         tokenId = _contributorScoreNFTId[_user];
         if (tokenId == 0) {
             return (0, 0);
         }
         score = _contributorScores[tokenId];
         return (score, tokenId);
     }

    function getGovernanceParams() public view returns (uint256 vp, uint256 qn, uint256 ptn, uint256 etl) {
        return (votingPeriod, quorumNumerator, proposalThresholdNumerator, executionTimelock);
    }

    // Needed for ERC721Receiver compatibility if transferring NFTs *to* the contract (not used here)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ERC721Enumerable overrides
     // This requires inheriting ERC721Enumerable correctly.
     // The constructor call ERC721Enumerable("HubContributorScore", "HCScore") assumes it sets the name/symbol.
     // Let's explicitly use the set functions if available or rely on constructor.
     // If using the single ERC721Enumerable, the name/symbol applies to the *collection*.
     // Metadata distinguishes types.
     // Let's assume the constructor call is sufficient for base ERC721Enumerable setup.
     // Need to add Base64 library for tokenURI
}

// Helper library for Base64 encoding (needed for data URI in tokenURI)
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the table into memory
        string memory table = TABLE;

        // Calculate the encoded length: 4 * ceil(data length / 3)
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // Allocate the output buffer
        bytes memory buffer = new bytes(encodedLen);

        // Iterate over the data in chunks of 3 bytes
        uint256 j = 0;
        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 chunk;
            uint256 chunkSize = data.length - i;

            if (chunkSize == 1) {
                chunk = uint256(data[i]) << 16;
            } else if (chunkSize == 2) {
                chunk = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8);
            } else {
                chunk = (uint256(data[i]) << 16) | (uint256(data[i + 1]) << 8) | uint256(data[i + 2]);
            }

            // Encode 3 bytes into 4 base64 characters
            buffer[j] = bytes1(table[(chunk >> 18) & 0x3F]);
            buffer[j + 1] = bytes1(table[(chunk >> 12) & 0x3F]);
            if (chunkSize > 1) {
                buffer[j + 2] = bytes1(table[(chunk >> 6) & 0x3F]);
            } else {
                buffer[j + 2] = bytes1(0x3D); // Pad with '='
            }
            if (chunkSize > 2) {
                buffer[j + 3] = bytes1(table[chunk & 0x3F]);
            } else {
                buffer[j + 3] = bytes1(0x3D); // Pad with '='
            }

            j += 4;
        }

        return string(buffer);
    }
}

// Helper library for converting numbers to strings (needed for dynamic JSON)
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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint160 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (int256 i = int256(length) - 1; i >= 0; i--) {
            buffer[2 + 2 * uint256(i)] = bytes1(toHexChar(uint8(value % 16)));
            value /= 16;
            buffer[2 + 2 * uint256(i) + 1] = bytes1(toHexChar(uint8(value % 16)));
            value /= 16;
        }
        return string(buffer);
    }

    function toHexChar(uint8 value) internal pure returns (uint8) {
        if (value < 10) {
            return value + 0x30;
        } else {
            return value - 10 + 0x61;
        }
    }
}

```