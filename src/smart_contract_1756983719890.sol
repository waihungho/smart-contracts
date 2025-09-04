Here's a Solidity smart contract named `SyntheticaCollective` that incorporates advanced, creative, and trendy concepts like AI-assisted curation, dynamic reputation, DAO governance, and evolving NFTs. It aims to create a self-sustaining ecosystem for innovation and content creation.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // For unique IDs and enumeration
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
*   Contract Name: SyntheticaCollective
*
*   Purpose: A decentralized platform for fostering creative innovation and content generation,
*            powered by AI-assisted evaluation and community governance. Users submit proposals,
*            which are scored by a simulated AI oracle. Successful proposals receive funding
*            from a community treasury, and users earn dynamic "Synergy Sphere" NFTs and
*            reputation based on their contributions and the AI's assessment.
*
*   Core Concepts:
*   - AI-Assisted Curation: Proposals are initially scored by an external AI (simulated via
*     an oracle interface), providing objective data points for community voting and evaluation.
*   - Dynamic Reputation System: User reputation is a fluid metric, increasing with successful
*     proposals, positive AI feedback, and active governance participation. It decreases with
*     failed ventures or negative actions. This reputation directly influences voting power
*     and NFT evolution.
*   - Synergy Spheres (Dynamic NFTs): ERC-721 tokens that visually and functionally evolve
*     based on their owner's accumulated reputation, AI scores, and project successes. They
*     grant special privileges and multipliers within the ecosystem and serve as a visual
*     representation of a participant's impact. Their metadata URIs are dynamically updated
*     to reflect these changes.
*   - Community Treasury & DAO Governance: A treasury funded by users and protocol fees,
*     governed by participants whose voting power is enhanced by their reputation. The DAO
*     votes on proposals for funding, protocol parameter changes, and other critical decisions.
*   - Gamified Contribution: Incentivizes high-quality submissions, active participation,
*     and constructive community engagement through reputation and NFT rewards.
*/

/*
*   Function Summary:
*
*   I. Administration & Configuration (3 functions)
*   1.  constructor(): Initializes the contract with the deployer as owner and sets initial parameters.
*   2.  updateAIOracleAddress(address _newOracle): Sets the address of the external AI Oracle contract (only owner).
*   3.  setProtocolParameters(uint256 _submissionFee, uint256 _minReputationToVote, uint256 _votingDuration, uint256 _minReputationForSphereMint): Allows the owner or DAO to adjust key protocol parameters.
*
*   II. User & Reputation Management (4 functions)
*   4.  registerParticipant(): Allows a new user to register and receive a unique participant ID, starting with a base reputation.
*   5.  _adjustReputation(address _user, int256 _delta): Internal function to modify a user's reputation score, called by various system events (AI evaluation, vote participation, project success/failure).
*   6.  slashReputation(address _user, uint256 _amount): Allows DAO-approved action (via a passed governance vote, or owner for demo) to penalize a user by reducing their reputation.
*   7.  getParticipantReputation(address _user): Views the current reputation score of a participant.
*
*   III. Proposal & Content Lifecycle (5 functions)
*   8.  submitCreativeProposal(string calldata _ipfsHash, string calldata _title): Users submit ideas/projects by providing an IPFS hash to their detailed proposal, paying a submission fee.
*   9.  receiveAIEvaluation(uint256 _proposalId, uint256 _creativityScore, uint256 _impactScore, uint256 _sentimentScore, uint256 _riskScore): Called by the designated AI Oracle to deliver a multi-faceted evaluation for a submitted proposal. This data is stored and used for voting and reputation.
*   10. getProposalDetails(uint256 _proposalId): Retrieves all details of a proposal, including AI scores and current status.
*   11. proposeFunding(uint256 _proposalId): Initiates a governance vote specifically for funding a proposal that has received AI evaluation.
*   12. markProjectCompletion(uint256 _proposalId, bool _success): Called by the project creator (or DAO after verification) to mark a funded project as completed, triggering reputation updates and potential royalty distribution.
*
*   IV. DAO Governance & Treasury (5 functions)
*   13. depositToTreasury(): Allows any user to contribute funds (ETH) to the collective's treasury.
*   14. createGovernanceVote(string calldata _description, bytes calldata _callData, address _targetAddress, uint256 _duration): Allows participants (with sufficient reputation) to propose general governance actions (e.g., changing parameters, treasury withdrawals).
*   15. castVote(uint256 _voteId, bool _support): Participants vote on proposals. Voting power is calculated dynamically based on a base and their reputation.
*   16. finalizeVote(uint256 _voteId): Ends a voting period, executes the proposal if passed, and updates participant reputations (e.g., rewards for correct votes).
*   17. distributeProjectRoyalties(uint256 _proposalId, address _recipient, uint256 _amount): Allows the DAO to approve and distribute a set amount of royalties from the treasury to a successful project creator.
*
*   V. Synergy Spheres (Dynamic NFTs) (4 functions)
*   18. mintSynergySphere(): Allows a registered participant (meeting certain reputation/contribution criteria) to mint their unique, dynamic ERC-721 Synergy Sphere.
*   19. _updateSphereAttributes(address _owner, uint256 _tokenId): Internal function triggered by reputation changes or project successes, which updates the on-chain attributes (e.g., evolution level, trait modifiers) of a Synergy Sphere. This also refreshes its metadata URI.
*   20. getSphereEvolutionLevel(uint256 _tokenId): Retrieves the current evolution level or key dynamic attribute of a Synergy Sphere.
*   21. recalculateAllSphereURIs(): Admin/DAO callable function to trigger a full recalculation and update of all Sphere metadata URIs, perhaps after a major protocol upgrade or attribute change. (Assumes metadata is generated off-chain by a service pulling on-chain attributes).
*/

// Error definitions for cleaner code and better UX
error NotRegisteredParticipant();
error InsufficientReputation(uint256 required, uint256 present);
error ProposalNotFound();
error NotAIOracle();
error ProposalAlreadyEvaluated();
error InvalidProposalState();
error NotProjectCreator();
error ProjectAlreadyMarkedComplete();
error VoteNotFound();
error VoteAlreadyEnded();
error AlreadyVoted();
error InvalidVoteDuration();
error NotYetActive();
error NotEligibleToMintSphere(uint256 required, uint256 present);
error NoSphereToUpdate();
error InvalidAIOracleAddress();
error ProposalNotYetEvaluated();
error NotEnoughFundsInTreasury(uint256 required, uint256 present);
error AccessDenied();
error InsufficientSubmissionFee();
error TokenAlreadyOwned();
error NotEnoughFunds();
error FundingTransferFailed();
error GovernanceActionFailed(bytes reason); // Custom error to include revert reason from target contract


contract SyntheticaCollective is Ownable, Pausable, ERC721Enumerable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Contract Parameters
    address public aiOracleAddress;
    uint256 public proposalSubmissionFee;
    uint256 public minReputationToVote;
    uint256 public votingDurationSeconds;
    uint256 public minReputationForSphereMint;
    uint256 public baseReputationForNewParticipant;
    uint256 public constant MAX_REPUTATION = 1_000_000_000; // Arbitrary high limit for reputation
    uint256 public constant MIN_REPUTATION = -1_000_000_000; // Arbitrary low limit

    // Participant Data
    struct Participant {
        bool isRegistered;
        int256 reputation; // Can be negative for penalization
        uint256 sphereTokenId; // ID of the minted sphere (0 if none)
    }
    mapping(address => Participant) public participants;

    // Proposal Data
    struct Proposal {
        uint256 id;
        address creator;
        string ipfsHash;
        string title;
        uint256 submissionTimestamp;
        bool aiEvaluated;
        uint256 creativityScore; // 0-100
        uint256 impactScore;     // 0-100
        uint256 sentimentScore;  // 0-100 (e.g., 0-50 negative, 50 neutral, 50-100 positive)
        uint256 riskScore;       // 0-100 (lower is better)
        bool fundingProposed;
        bool funded;
        bool projectCompleted;
        bool projectSuccessful; // Only relevant if funded and completed
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;

    // Governance Vote Data
    enum VoteType { FundingProposal, GovernanceAction }
    enum VoteStatus { Active, Passed, Failed, Executed }

    struct Vote {
        uint256 id;
        VoteType voteType;
        uint256 targetId; // proposalId for FundingProposal, 0 for GovernanceAction (if no specific target)
        string description;
        bytes callData;      // For GovernanceAction
        address targetAddress; // For GovernanceAction
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        VoteStatus status;
        uint256 snapshotReputationTotal; // Total reputation at vote start (for quorum calculation)
    }
    Counters.Counter private _voteIds;
    mapping(uint256 => Vote) public votes;

    // Treasury (receives funds directly via `receive` function)

    // ERC721 properties for Synergy Spheres
    Counters.Counter private _sphereTokenIds;
    // We store custom token URIs per token, allowing dynamic updates
    mapping(uint256 => string) private _tokenURIs;
    string private _baseURIValue; // For a global base path if needed

    // --- Events ---
    event AIOracleAddressUpdated(address indexed newAddress);
    event ProtocolParametersUpdated(uint256 submissionFee, uint256 minReputationToVote, uint256 votingDuration, uint256 minReputationForSphereMint);
    event ParticipantRegistered(address indexed participant);
    event ReputationAdjusted(address indexed participant, int256 oldReputation, int256 newReputation);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed creator, string ipfsHash, string title);
    event AIEvaluated(uint256 indexed proposalId, uint256 creativityScore, uint256 impactScore, uint256 sentimentScore, uint256 riskScore);
    event FundingVoteProposed(uint256 indexed proposalId, uint256 indexed voteId);
    event ProjectCompleted(uint256 indexed proposalId, bool success);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event GovernanceVoteCreated(uint256 indexed voteId, VoteType voteType, string description);
    event VoteCast(uint256 indexed voteId, address indexed voter, bool support, uint256 votingPower);
    event VoteFinalized(uint256 indexed voteId, VoteStatus status);
    event ProposalFunded(uint256 indexed proposalId, uint256 amount);
    event RoyaltiesDistributed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event SynergySphereMinted(uint256 indexed tokenId, address indexed owner);
    event SynergySphereAttributesUpdated(uint256 indexed tokenId, uint256 newEvolutionLevel, string newURI);

    // --- Modifiers ---
    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert NotAIOracle();
        }
        _;
    }

    modifier onlyRegistered() {
        if (!participants[msg.sender].isRegistered) {
            revert NotRegisteredParticipant();
        }
        _;
    }

    modifier onlyProposalCreator(uint256 _proposalId) {
        if (proposals[_proposalId].creator == address(0)) {
            revert ProposalNotFound();
        }
        if (proposals[_proposalId].creator != msg.sender) {
            revert NotProjectCreator();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _aiOracleAddress,
        uint256 _submissionFee,
        uint256 _minReputationToVote,
        uint256 _votingDurationSeconds,
        uint256 _minReputationForSphereMint,
        uint256 _baseReputationForNewParticipant,
        string memory _baseTokenURI
    ) Ownable(msg.sender) ERC721("SynergySphere", "SYN_SPHERE") {
        if (_aiOracleAddress == address(0)) {
            revert InvalidAIOracleAddress();
        }
        aiOracleAddress = _aiOracleAddress;
        proposalSubmissionFee = _submissionFee;
        minReputationToVote = _minReputationToVote;
        votingDurationSeconds = _votingDurationSeconds;
        minReputationForSphereMint = _minReputationForSphereMint;
        baseReputationForNewParticipant = _baseReputationForNewParticipant;
        _baseURIValue = _baseTokenURI; // Set the global base URI for NFTs
    }

    // This function allows the contract to receive ETH, funding the treasury
    receive() external payable whenNotPaused {
        if (msg.value == 0) {
            revert NotEnoughFunds();
        }
        emit FundsDeposited(msg.sender, msg.value);
    }

    // --- I. Administration & Configuration ---

    /// @notice Updates the address of the external AI Oracle contract.
    /// @dev Only the contract owner can call this.
    /// @param _newOracle The new address for the AI Oracle.
    function updateAIOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) {
            revert InvalidAIOracleAddress();
        }
        aiOracleAddress = _newOracle;
        emit AIOracleAddressUpdated(_newOracle);
    }

    /// @notice Sets key protocol parameters.
    /// @dev Can be called by the owner or later by a DAO governance vote.
    /// @param _submissionFee Fee to submit a proposal.
    /// @param _minReputationToVote Minimum reputation required to cast a vote.
    /// @param _votingDuration Number of seconds a vote remains open.
    /// @param _minReputationForSphereMint Minimum reputation to mint a Synergy Sphere.
    function setProtocolParameters(
        uint256 _submissionFee,
        uint256 _minReputationToVote,
        uint256 _votingDuration,
        uint256 _minReputationForSphereMint
    ) external onlyOwner { // TODO: Implement DAO-governed execution for this
        proposalSubmissionFee = _submissionFee;
        minReputationToVote = _minReputationToVote;
        votingDurationSeconds = _votingDuration;
        minReputationForSphereMint = _minReputationForSphereMint;
        emit ProtocolParametersUpdated(_submissionFee, _minReputationToVote, _votingDuration, _minReputationForSphereMint);
    }

    // --- II. User & Reputation Management ---

    /// @notice Allows a new user to register and receive a unique participant ID, starting with a base reputation.
    function registerParticipant() external whenNotPaused {
        if (participants[msg.sender].isRegistered) {
            revert("Participant already registered.");
        }
        participants[msg.sender].isRegistered = true;
        participants[msg.sender].reputation = int256(baseReputationForNewParticipant);
        emit ParticipantRegistered(msg.sender);
        emit ReputationAdjusted(msg.sender, 0, int256(baseReputationForNewParticipant));
    }

    /// @notice Internal function to modify a user's reputation score.
    /// @dev Called by various system events (AI evaluation, vote participation, project success/failure).
    /// @param _user The address whose reputation is being adjusted.
    /// @param _delta The amount to add (positive) or subtract (negative) from reputation.
    function _adjustReputation(address _user, int256 _delta) internal {
        if (!participants[_user].isRegistered) {
            return; // Only adjust reputation for registered participants.
        }
        int256 oldRep = participants[_user].reputation;
        int256 newRep = oldRep + _delta;

        // Cap reputation to prevent overflow and enforce reasonable limits
        if (newRep > MAX_REPUTATION) newRep = MAX_REPUTATION;
        if (newRep < MIN_REPUTATION) newRep = MIN_REPUTATION;

        participants[_user].reputation = newRep;
        emit ReputationAdjusted(_user, oldRep, newRep);

        // Potentially trigger Sphere attribute update if the user owns one
        if (participants[_user].sphereTokenId != 0) {
            _updateSphereAttributes(_user, participants[_user].sphereTokenId);
        }
    }

    /// @notice Allows DAO-approved action (via a passed governance vote, or owner for demo) to penalize a user by reducing their reputation.
    /// @dev This function should only be called as a result of a successfully passed governance vote.
    /// @param _user The address of the participant to slash.
    /// @param _amount The amount of reputation to deduct.
    function slashReputation(address _user, uint256 _amount) external onlyRegistered whenNotPaused {
        // In a real DAO, this would be callable only by the `_execute` function of a passed governance vote
        // For this example, let's assume `owner` can call it for demonstration or via initial DAO setup
        if (msg.sender != owner()) { // Temporary: For a full DAO, this would be executed via `finalizeVote`
            revert AccessDenied();
        }
        _adjustReputation(_user, -int256(_amount));
    }

    /// @notice Views the current reputation score of a participant.
    /// @param _user The address of the participant.
    /// @return The reputation score.
    function getParticipantReputation(address _user) external view returns (int256) {
        return participants[_user].reputation;
    }

    // --- III. Proposal & Content Lifecycle ---

    /// @notice Users submit ideas/projects by providing an IPFS hash to their detailed proposal, paying a submission fee.
    /// @param _ipfsHash IPFS hash pointing to proposal details.
    /// @param _title Short title for the proposal.
    function submitCreativeProposal(string calldata _ipfsHash, string calldata _title) external payable onlyRegistered whenNotPaused {
        if (msg.value < proposalSubmissionFee) {
            revert InsufficientSubmissionFee();
        }

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        proposals[newId] = Proposal({
            id: newId,
            creator: msg.sender,
            ipfsHash: _ipfsHash,
            title: _title,
            submissionTimestamp: block.timestamp,
            aiEvaluated: false,
            creativityScore: 0,
            impactScore: 0,
            sentimentScore: 0,
            riskScore: 0,
            fundingProposed: false,
            funded: false,
            projectCompleted: false,
            projectSuccessful: false
        });

        emit ProposalSubmitted(newId, msg.sender, _ipfsHash, _title);
    }

    /// @notice Called by the designated AI Oracle to deliver a multi-faceted evaluation for a submitted proposal.
    /// @dev Only the registered AI Oracle address can call this. This data is stored and used for voting and reputation.
    /// @param _proposalId The ID of the proposal being evaluated.
    /// @param _creativityScore Score 0-100 for creativity.
    /// @param _impactScore Score 0-100 for potential impact.
    /// @param _sentimentScore Score 0-100 for overall sentiment (e.g., public perception).
    /// @param _riskScore Score 0-100 for risk (lower is better).
    function receiveAIEvaluation(
        uint256 _proposalId,
        uint256 _creativityScore,
        uint256 _impactScore,
        uint256 _sentimentScore,
        uint256 _riskScore
    ) external onlyAIOracle whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) { // Checks if proposal exists
            revert ProposalNotFound();
        }
        if (proposal.aiEvaluated) {
            revert ProposalAlreadyEvaluated();
        }

        proposal.aiEvaluated = true;
        proposal.creativityScore = _creativityScore;
        proposal.impactScore = _impactScore;
        proposal.sentimentScore = _sentimentScore;
        proposal.riskScore = _riskScore;

        // Adjust creator's reputation based on AI scores
        // Simple example: Higher creativity/impact/sentiment, lower risk -> higher rep gain
        int256 reputationGain = int256(_creativityScore + _impactScore + _sentimentScore) - int256(_riskScore);
        _adjustReputation(proposal.creator, reputationGain / 10); // Scale down the impact

        emit AIEvaluated(_proposalId, _creativityScore, _impactScore, _sentimentScore, _riskScore);
    }

    /// @notice Retrieves all details of a proposal, including AI scores and current status.
    /// @param _proposalId The ID of the proposal.
    /// @return A tuple containing all proposal details.
    function getProposalDetails(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            address creator,
            string memory ipfsHash,
            string memory title,
            uint256 submissionTimestamp,
            bool aiEvaluated,
            uint256 creativityScore,
            uint256 impactScore,
            uint256 sentimentScore,
            uint256 riskScore,
            bool fundingProposed,
            bool funded,
            bool projectCompleted,
            bool projectSuccessful
        )
    {
        Proposal storage p = proposals[_proposalId];
        if (p.creator == address(0)) {
            revert ProposalNotFound();
        }
        return (
            p.id,
            p.creator,
            p.ipfsHash,
            p.title,
            p.submissionTimestamp,
            p.aiEvaluated,
            p.creativityScore,
            p.impactScore,
            p.sentimentScore,
            p.riskScore,
            p.fundingProposed,
            p.funded,
            p.projectCompleted,
            p.projectSuccessful
        );
    }

    /// @notice Initiates a governance vote specifically for funding a proposal that has received AI evaluation.
    /// @dev Requires a participant to have minimum reputation.
    /// @param _proposalId The ID of the proposal to fund.
    function proposeFunding(uint256 _proposalId) external onlyRegistered whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) {
            revert ProposalNotFound();
        }
        if (!proposal.aiEvaluated) {
            revert ProposalNotYetEvaluated();
        }
        if (proposal.fundingProposed) {
            revert("Funding vote already proposed for this proposal.");
        }
        if (participants[msg.sender].reputation < int256(minReputationToVote)) {
            revert InsufficientReputation(minReputationToVote, uint256(participants[msg.sender].reputation));
        }

        _voteIds.increment();
        uint256 newVoteId = _voteIds.current();

        votes[newVoteId] = Vote({
            id: newVoteId,
            voteType: VoteType.FundingProposal,
            targetId: _proposalId,
            description: string(abi.encodePacked("Fund proposal: ", proposal.title)),
            callData: "", // Not applicable for funding proposals (executed internally)
            targetAddress: address(0), // Not applicable
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + votingDurationSeconds,
            forVotes: 0,
            againstVotes: 0,
            status: VoteStatus.Active,
            hasVoted: new mapping(address => bool)(), // Initialize a new mapping
            snapshotReputationTotal: _calculateTotalActiveReputation() // Snapshot total reputation for quorum
        });

        proposal.fundingProposed = true;
        emit FundingVoteProposed(_proposalId, newVoteId);
    }

    /// @notice Called by the project creator (or DAO after verification) to mark a funded project as completed.
    /// @dev Triggers reputation updates for the creator based on project success.
    /// @param _proposalId The ID of the completed proposal.
    /// @param _success True if the project was successful, false otherwise.
    function markProjectCompletion(uint256 _proposalId, bool _success) external onlyProposalCreator(_proposalId) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (!proposal.funded) {
            revert("Project not funded yet.");
        }
        if (proposal.projectCompleted) {
            revert ProjectAlreadyMarkedComplete();
        }

        proposal.projectCompleted = true;
        proposal.projectSuccessful = _success;

        if (_success) {
            _adjustReputation(proposal.creator, 500); // Significant reputation boost for success
        } else {
            _adjustReputation(proposal.creator, -200); // Reputation penalty for failure
        }
        emit ProjectCompleted(_proposalId, _success);
    }

    // --- IV. DAO Governance & Treasury ---

    /// @notice Allows any user to contribute funds (ETH) to the collective's treasury.
    /// @dev Uses the `receive()` fallback function to handle incoming ETH.
    function depositToTreasury() external payable whenNotPaused {
        // The receive() function handles this. This function merely provides an explicit entry point.
        if (msg.value == 0) {
            revert NotEnoughFunds();
        }
    }

    /// @notice Allows participants (with sufficient reputation) to propose general governance actions.
    /// @dev Examples: changing parameters, treasury withdrawals, slashing reputation.
    /// @param _description A brief description of the governance action.
    /// @param _callData The encoded function call to be executed if the vote passes.
    /// @param _targetAddress The target contract address for the `_callData`.
    /// @param _duration Number of seconds the vote will be active.
    function createGovernanceVote(
        string calldata _description,
        bytes calldata _callData,
        address _targetAddress,
        uint256 _duration
    ) external onlyRegistered whenNotPaused {
        if (participants[msg.sender].reputation < int256(minReputationToVote)) {
            revert InsufficientReputation(minReputationToVote, uint256(participants[msg.sender].reputation));
        }
        if (_duration == 0 || _duration > 30 days) { // Example limits
            revert InvalidVoteDuration();
        }

        _voteIds.increment();
        uint256 newVoteId = _voteIds.current();

        votes[newVoteId] = Vote({
            id: newVoteId,
            voteType: VoteType.GovernanceAction,
            targetId: 0, // Not applicable for general governance
            description: _description,
            callData: _callData,
            targetAddress: _targetAddress,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + _duration,
            forVotes: 0,
            againstVotes: 0,
            status: VoteStatus.Active,
            hasVoted: new mapping(address => bool)(), // Initialize a new mapping
            snapshotReputationTotal: _calculateTotalActiveReputation()
        });

        emit GovernanceVoteCreated(newVoteId, VoteType.GovernanceAction, _description);
    }

    /// @notice Participants vote on proposals. Voting power is calculated dynamically based on reputation.
    /// @dev Requires minimum reputation. Users can only vote once per vote.
    /// @param _voteId The ID of the vote.
    /// @param _support True for 'for' vote, false for 'against'.
    function castVote(uint256 _voteId, bool _support) external onlyRegistered whenNotPaused {
        Vote storage vote = votes[_voteId];
        if (vote.id == 0) {
            revert VoteNotFound();
        }
        if (vote.status != VoteStatus.Active) {
            revert VoteAlreadyEnded();
        }
        if (block.timestamp >= vote.endTimestamp) {
            revert VoteAlreadyEnded(); // Should be finalized, but protect against late votes
        }
        if (vote.hasVoted[msg.sender]) {
            revert AlreadyVoted();
        }
        if (participants[msg.sender].reputation < int256(minReputationToVote)) {
            revert InsufficientReputation(minReputationToVote, uint256(participants[msg.sender].reputation));
        }

        uint256 votingPower = _calculateVotingPower(msg.sender);
        if (_support) {
            vote.forVotes += votingPower;
        } else {
            vote.againstVotes += votingPower;
        }
        vote.hasVoted[msg.sender] = true;

        // Reward voters with reputation for participation
        _adjustReputation(msg.sender, 5);

        emit VoteCast(_voteId, msg.sender, _support, votingPower);
    }

    /// @notice Ends a voting period, executes the proposal if passed, and updates participant reputations.
    /// @param _voteId The ID of the vote to finalize.
    function finalizeVote(uint256 _voteId) external whenNotPaused {
        Vote storage vote = votes[_voteId];
        if (vote.id == 0) {
            revert VoteNotFound();
        }
        if (vote.status != VoteStatus.Active) {
            revert VoteAlreadyEnded();
        }
        if (block.timestamp < vote.endTimestamp) {
            revert NotYetActive(); // Vote still ongoing
        }

        // Quorum and Threshold logic (example: 10% of snapshot reputation, 60% simple majority)
        uint256 totalVotesCast = vote.forVotes + vote.againstVotes;
        // In a real system, snapshotReputationTotal would be accurately maintained.
        // For this example, if no participants or only a few, 1 unit is a fallback to allow any vote to pass quorum if it reaches 10% of a minimal "active" base.
        uint256 effectiveSnapshotReputationTotal = vote.snapshotReputationTotal > 0 ? vote.snapshotReputationTotal : 100; // Fallback for quorum if no participants

        bool quorumMet = (totalVotesCast * 100) >= (effectiveSnapshotReputationTotal * 10); // 10% quorum
        bool passed = false;

        if (quorumMet && (vote.forVotes * 100) >= (totalVotesCast * 60)) { // 60% majority
            passed = true;
        }

        if (passed) {
            vote.status = VoteStatus.Passed;
            // Execute action based on vote type
            if (vote.voteType == VoteType.FundingProposal) {
                Proposal storage proposal = proposals[vote.targetId];
                if (proposal.creator == address(0)) { // Should not happen if `proposeFunding` validated
                    revert ProposalNotFound();
                }
                // Example funding amount: 1 ETH
                uint256 fundingAmount = 1 ether;
                if (address(this).balance < fundingAmount) {
                    revert NotEnoughFundsInTreasury(fundingAmount, address(this).balance);
                }
                
                // Transfer funds to the project creator
                (bool success, ) = payable(proposal.creator).call{value: fundingAmount}("");
                if (!success) {
                    revert FundingTransferFailed();
                }
                proposal.funded = true;
                emit ProposalFunded(proposal.id, fundingAmount);
                _adjustReputation(proposal.creator, 100); // Initial rep for being funded
            } else if (vote.voteType == VoteType.GovernanceAction) {
                // Execute arbitrary call data
                (bool success, bytes memory result) = vote.targetAddress.call(vote.callData);
                if (!success) {
                    // Revert with the error from the called contract if possible
                    if (result.length > 0) {
                        assembly {
                            let revertReason := add(32, result)
                            let revertReasonLength := mload(result)
                            revert(revertReason, revertReasonLength)
                        }
                    } else {
                        revert GovernanceActionFailed("");
                    }
                }
                vote.status = VoteStatus.Executed; // Mark as executed if successful
            }
        } else {
            vote.status = VoteStatus.Failed;
        }

        // Optionally, reward voters whose votes matched the outcome
        // This would require iterating through all voters, which is gas intensive for large DAOs.
        // For a simple example, we'll stick to the participation reward in `castVote`.

        emit VoteFinalized(_voteId, vote.status);
    }

    /// @notice Allows the DAO to approve and distribute a set amount of royalties from the treasury to a successful project creator.
    /// @dev This function can only be called as a result of a successfully passed governance vote (via `_execute` in `finalizeVote`).
    /// @param _proposalId The ID of the successful proposal.
    /// @param _recipient The address to receive the royalties.
    /// @param _amount The amount of ETH to distribute.
    function distributeProjectRoyalties(uint256 _proposalId, address _recipient, uint256 _amount) external payable {
        // This function would typically be called via a governance action by `finalizeVote`
        // For this example, allow owner to call for testing/initial setup
        if (msg.sender != owner()) { // Temporary: For a full DAO, this would be executed via `finalizeVote`
             revert AccessDenied();
        }

        Proposal storage proposal = proposals[_proposalId];
        if (proposal.creator == address(0)) {
            revert ProposalNotFound();
        }
        if (!proposal.projectSuccessful) {
            revert("Project not marked successful for royalties.");
        }
        if (address(this).balance < _amount) {
            revert NotEnoughFundsInTreasury(_amount, address(this).balance);
        }

        (bool success, ) = payable(_recipient).call{value: _amount}("");
        if (!success) {
            revert("Royalty transfer failed.");
        }
        emit RoyaltiesDistributed(_proposalId, _recipient, _amount);
    }

    // --- V. Synergy Spheres (Dynamic NFTs) ---

    /// @notice Allows a registered participant (meeting certain reputation/contribution criteria) to mint their unique, dynamic ERC-721 Synergy Sphere.
    /// @dev Each participant can only mint one Sphere.
    function mintSynergySphere() external onlyRegistered whenNotPaused {
        if (participants[msg.sender].sphereTokenId != 0) {
            revert TokenAlreadyOwned();
        }
        if (participants[msg.sender].reputation < int256(minReputationForSphereMint)) {
            revert NotEligibleToMintSphere(minReputationForSphereMint, uint256(participants[msg.sender].reputation));
        }

        _sphereTokenIds.increment();
        uint256 newId = _sphereTokenIds.current();

        _mint(msg.sender, newId);
        participants[msg.sender].sphereTokenId = newId; // Map participant to their sphere

        // Set initial URI for the sphere
        string memory initialURI = _buildTokenURI(newId, participants[msg.sender].reputation);
        _setTokenURI(newId, initialURI);

        emit SynergySphereMinted(newId, msg.sender);
        emit SynergySphereAttributesUpdated(newId, getSphereEvolutionLevel(newId), initialURI);
    }

    /// @notice Internal function triggered by reputation changes or project successes.
    /// @dev Updates the on-chain attributes (e.g., evolution level, trait modifiers) of a Synergy Sphere
    ///      and refreshes its off-chain metadata URI.
    /// @param _owner The owner of the sphere.
    /// @param _tokenId The ID of the Synergy Sphere.
    function _updateSphereAttributes(address _owner, uint256 _tokenId) internal {
        // Ensure the token exists and belongs to the owner.
        // No need for ownerOf check as we use `participants[_owner].sphereTokenId` for internal consistency.
        if (participants[_owner].sphereTokenId != _tokenId) {
            revert NoSphereToUpdate(); // Should not happen if called correctly
        }
        
        uint256 newEvolutionLevel = _calculateEvolutionLevel(participants[_owner].reputation);
        string memory newURI = _buildTokenURI(_tokenId, participants[_owner].reputation);
        _setTokenURI(_tokenId, newURI);
        emit SynergySphereAttributesUpdated(_tokenId, newEvolutionLevel, newURI);
    }

    /// @notice Retrieves the current evolution level or key dynamic attribute of a Synergy Sphere.
    /// @param _tokenId The ID of the Synergy Sphere.
    /// @return The calculated evolution level.
    function getSphereEvolutionLevel(uint256 _tokenId) public view returns (uint256) {
        address sphereOwner = ownerOf(_tokenId); // ERC721 ownerOf
        if (sphereOwner == address(0) || !participants[sphereOwner].isRegistered) {
            revert NoSphereToUpdate(); // Or a more specific error for non-existent/unregistered owner
        }
        return _calculateEvolutionLevel(participants[sphereOwner].reputation);
    }

    /// @notice Admin/DAO callable function to trigger a full recalculation and update of all Sphere metadata URIs.
    /// @dev Useful after a major protocol upgrade or attribute logic change, ensuring all NFTs reflect new logic.
    function recalculateAllSphereURIs() external onlyOwner whenNotPaused { // TODO: Make this DAO governed
        uint256 totalSpheres = totalSupply(); // From ERC721Enumerable
        for (uint256 i = 0; i < totalSpheres; i++) {
            uint256 tokenId = tokenByIndex(i); // From ERC721Enumerable
            address sphereOwner = ownerOf(tokenId);
            if (sphereOwner != address(0) && participants[sphereOwner].isRegistered) {
                string memory newURI = _buildTokenURI(tokenId, participants[sphereOwner].reputation);
                _setTokenURI(tokenId, newURI);
                emit SynergySphereAttributesUpdated(tokenId, getSphereEvolutionLevel(tokenId), newURI);
            }
        }
    }


    // --- Internal/Helper Functions ---

    /// @dev Calculates voting power for a user. Example: 1 base vote + (reputation / 100).
    /// @param _user The address of the participant.
    /// @return The calculated voting power.
    function _calculateVotingPower(address _user) internal view returns (uint256) {
        int256 currentRep = participants[_user].reputation;
        if (currentRep < 0) currentRep = 0; // Negative reputation doesn't reduce base voting power
        return 1 + (uint256(currentRep) / 100); // 1 base vote + 1 vote per 100 reputation
    }

    /// @dev Calculates a simplified total reputation of all registered participants for quorum.
    ///      In a production system, this would be a more robustly maintained global sum,
    ///      or a snapshot of a governance token's total supply.
    /// @return A (simplified) sum of all registered participants' reputation.
    function _calculateTotalActiveReputation() internal view returns (uint256) {
        // This is a placeholder. For a truly scalable and decentralized DAO with dynamic reputation,
        // maintaining an accurate sum on-chain for all participants is a known challenge due to gas costs
        // for iteration. A common approach is:
        // 1. Maintain a running sum updated on each reputation change.
        // 2. Use a governance token's total supply as proxy (if a token exists).
        // 3. Use an off-chain oracle to provide this sum to the contract.
        // For this example, we return a fixed, large number to simulate a active collective.
        return 10_000_000; // Placeholder: Assumed total active reputation in the system.
    }

    /// @dev Helper function to determine the evolution level of a sphere based on reputation.
    /// @param _reputation The owner's reputation.
    /// @return The calculated evolution level (0-5).
    function _calculateEvolutionLevel(int256 _reputation) internal pure returns (uint256) {
        if (_reputation < 0) return 0; // Devolved state for negative reputation
        if (_reputation < 500) return 1;
        if (_reputation < 1500) return 2;
        if (_reputation < 3000) return 3;
        if (_reputation < 6000) return 4;
        return 5; // Max evolution level
    }

    /// @dev Constructs the metadata URI for a Synergy Sphere based on its ID and owner's reputation.
    /// @param _tokenId The ID of the token.
    /// @param _reputation The owner's current reputation.
    /// @return The constructed metadata URI.
    function _buildTokenURI(uint252 _tokenId, int256 _reputation) internal pure returns (string memory) {
        uint256 evolutionLevel = _calculateEvolutionLevel(_reputation);
        // In a real dApp, this would point to an IPFS gateway or a dedicated metadata server.
        // The server would then serve JSON metadata based on these on-chain attributes (tokenId, evolutionLevel).
        // Example format: "ipfs://<CID>/<tokenId>/level_<level>.json"
        return string(abi.encodePacked("ipfs://QmTg", Strings.toString(_tokenId), "/level_", Strings.toString(evolutionLevel), ".json"));
    }

    // Overriding ERC721's _baseURI and tokenURI to implement dynamic URIs
    // The baseURI can be set by the owner, but individual token URIs can be customized.
    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    // Custom internal function to set individual token URIs
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        _tokenURIs[tokenId] = _tokenURI;
    }

    // Public getter for token URI, as required by ERC721
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is owned
        string memory customURI = _tokenURIs[tokenId];
        
        // If a custom URI is set, use it. Otherwise, fall back to default ERC721 behavior with baseURI.
        if (bytes(customURI).length > 0) {
            return customURI;
        }
        // Fallback to OpenZeppelin's default, which appends tokenId to _baseURI()
        return super.tokenURI(tokenId);
    }
    
    // --- Pausable override ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Enumerable, Pausable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (paused()) {
            revert Paused();
        }
    }

    // Required for multiple inheritance diamond problem from OpenZeppelin 0.8.20+
    // If you uncommented transfer/safeTransfer functions in ERC721,
    // you would need to add `ERC721` to the list here.
    function _increaseBalance(address account, uint128 value) internal pure override {}
}

```