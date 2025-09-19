Here's a smart contract written in Solidity, incorporating advanced concepts, creative functions, and trendy features, while aiming to be distinct from common open-source projects. It includes at least 20 functions as requested.

The central idea is a **"AetherForgeLab"**, a decentralized platform for AI-powered research and development. Users can submit research proposals, funded by ERC-20 tokens. Researchers can claim these proposals, submit their outputs (referenced by IPFS hashes), and then the output undergoes evaluation by a trusted AI oracle and human validators. A reputation system tracks participants' contributions, and rewards are distributed based on the outcome.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Outline and Function Summary:
// AetherForgeLab: A Decentralized AI-Powered Research & Development Platform.
// This contract facilitates a decentralized ecosystem where users can propose research tasks,
// researchers can claim and execute these tasks, and a combination of AI oracles and human
// validators assess the quality of the submitted work. The system incorporates a reputation
// mechanism to incentivize honest participation and uses ERC-20 tokens for funding and rewards.
// IPFS hashes are used to reference off-chain content (descriptions, outputs, audit reports, rationales).

// I. Core Infrastructure & Configuration:
// 1. constructor(): Initializes the contract with an admin, AI oracle address, and initial lab parameters.
// 2. updateLabConfig(): Allows the admin/governance to adjust global lab parameters such as fees,
//    minimum deposit, claim period, validation period, AI audit threshold, AI override threshold,
//    reward distribution percentages, and the fee recipient.
// 3. setAIOracleAddress(): Admin function to update the trusted AI Oracle's address.
// 4. pause(): Pauses all core operations of the lab (inherits from Pausable).
// 5. unpause(): Unpauses core operations (inherits from Pausable).

// II. Research Proposal Lifecycle:
// 6. submitResearchProposal(): Users create a new research proposal, providing a title,
//    IPFS hash for description, and funding it with ERC-20 tokens. An initial `proposalFee` is also charged.
// 7. fundExistingProposal(): Allows users to add more ERC-20 tokens to an already existing proposal's funding.
// 8. claimProposal(): Researchers can claim an 'Open' proposal to work on it, setting a deadline.
//    Proposers cannot claim their own proposals.
// 9. submitResearchOutput(): A claimed researcher submits the research output (referenced by IPFS hash)
//    within the `claimPeriod` and transitions the proposal to 'OutputSubmitted' state, automatically
//    signaling an off-chain AI oracle for an audit.
// 10. abandonClaim(): A researcher can abandon their claim on a proposal if they can no longer work on it,
//     returning the proposal to an 'Open' state.
// 11. withdrawUnclaimedFunds(): The original proposer can withdraw their funds if a proposal
//     expires without being claimed by any researcher within the `claimPeriod` from creation.
// 12. expireClaimedProposal(): Anyone can call this to expire a claimed proposal if the researcher
//     fails to submit an output within the `claimPeriod` from claiming. Funds are returned to the proposer,
//     and the inactive researcher incurs a reputation penalty.

// III. Validation, AI Audit & Resolution:
// 13. reportAIAuditResult(): Callable only by the designated AI Oracle, this function delivers
//     the AI's assessment score and an IPFS hash for the detailed audit report for a proposal.
//     Transitions proposal to 'AIAudited' state.
// 14. submitHumanValidationVote(): A participant with reputation can vote on the quality of a submitted output
//     (acceptable/unacceptable) and provide a rationale (IPFS hash). Vote weight is tied to their reputation.
//     Proposers and researchers cannot vote on their own proposals.
// 15. revokeHumanValidationVote(): Allows a participant to retract their human validation vote before resolution,
//     readjusting the proposal's vote counts.
// 16. resolveProposal(): This crucial function finalizes a proposal after the `validationPeriod`.
//     It evaluates the combined AI score and human votes using an advanced logic (AI override, human override, consensus),
//     distributes rewards to successful researchers (added to `earnedRewards`), and updates their reputation.
//     Validator token rewards are directed to the `communityFundBalance` (to avoid gas-intensive iteration),
//     while validator reputation updates are handled through other mechanisms (e.g., `penalizeParticipant` or future governance).
//     Any remaining funds go to the proposer (if unsuccessful) or the community fund.
// 17. withdrawRewards(): Allows researchers to withdraw their accumulated ERC-20 rewards from resolved proposals.
// 18. getParticipantReputation(): Retrieves the current reputation score of any given address in the lab.

// IV. Reputation & Admin Functions:
// 19. penalizeParticipant(): Admin function to deduct reputation points from a participant
//     due to malicious activity or confirmed misconduct.
// 20. withdrawCommunityFund(): Admin function to withdraw funds accumulated in the community
//     fund (e.g., from fees, residual funds from resolved proposals, or pooled validator rewards).
// 21. getProposalDetails(): A public read-only function to fetch comprehensive details of a specific proposal.
// 22. getHumanVoteDetails(): A public read-only helper to fetch a specific validator's vote on a proposal.

contract AetherForgeLab is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Events ---
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 fundingAmount, string title);
    event ProposalFunded(uint256 indexed proposalId, address indexed funder, uint256 additionalAmount);
    event ProposalClaimed(uint256 indexed proposalId, address indexed researcher);
    event ResearchOutputSubmitted(uint256 indexed proposalId, address indexed researcher, string outputIPFSHash);
    event ClaimAbandoned(uint256 indexed proposalId, address indexed researcher);
    event ProposalExpired(uint256 indexed proposalId, address indexed refunder);
    event AIAuditReported(uint256 indexed proposalId, int256 aiScore, string auditReportIPFSHash);
    event HumanVoteSubmitted(uint256 indexed proposalId, address indexed validator, bool isAcceptable);
    event HumanVoteRevoked(uint256 indexed proposalId, address indexed validator);
    event ProposalResolved(uint256 indexed proposalId, bool success, address indexed winnerResearcher, uint256 researcherReward, uint256 communityFundAmount);
    event RewardsWithdrawn(address indexed participant, uint256 amount);
    event ReputationUpdated(address indexed participant, int256 newReputation);
    event LabConfigUpdated(uint256 newProposalFee, uint256 newMinDeposit, uint256 newClaimPeriod, uint256 newValidationPeriod, int256 newAiAuditThreshold, address newFeeRecipient);
    event AIOracleAddressUpdated(address newOracleAddress);
    event CommunityFundWithdrawn(address indexed recipient, uint256 amount);
    event ParticipantPenalized(address indexed participant, uint256 penaltyAmount);

    // --- State Variables ---

    IERC20 public immutable AFL_TOKEN; // The ERC-20 token used for funding and rewards

    address public aiOracleAddress; // Address of the trusted AI Oracle
    address public feeRecipient;    // Address to receive protocol fees

    uint256 public proposalFee;      // Fee in AFL_TOKEN for submitting a proposal
    uint256 public minProposalDeposit; // Minimum AFL_TOKEN required for a proposal
    uint256 public claimPeriod;      // Time (in seconds) a researcher has to submit output after claiming
    uint256 public validationPeriod; // Time (in seconds) for human validation after output submission
    int256 public aiAuditThreshold; // AI score threshold for 'passing' AI audit (e.g., 60 for 60/100)
    int256 public aiOverrideThreshold; // AI score for AI to strongly override negative human votes (e.g., 90+)
    uint256 public researcherRewardShareNumerator; // Numerator for researcher reward percentage (e.g., 60 for 60%)
    uint256 public researcherRewardShareDenominator; // Denominator (e.g., 100)
    uint256 public validatorRewardShareNumerator; // Numerator for validator reward percentage
    uint256 public validatorRewardShareDenominator; // Denominator (e.g., 100)
    uint256 public communityFundShareNumerator; // Numerator for community fund percentage (including pooled validator rewards)
    uint256 public communityFundShareDenominator; // Denominator (e.g., 100)
    uint256 public proposerRefundShareNumerator; // Numerator for proposer refund percentage (if unsuccessful)
    uint256 public proposerRefundShareDenominator; // Denominator (e.g., 100)

    uint256 private _nextProposalId; // Counter for unique proposal IDs

    enum ProposalStatus {
        Open,            // Available for claiming
        Claimed,         // Claimed by a researcher, awaiting output
        OutputSubmitted, // Output submitted, awaiting AI audit (and human validation)
        AIAudited,       // AI audit received, awaiting human validation or final resolution
        Resolved,        // Fully resolved, funds distributed, reputation updated
        Abandoned,       // Researcher abandoned claim, proposal back to open
        Expired          // Claim period expired, funds returned to proposer
    }

    struct Proposal {
        uint256 id;
        address proposer;
        address researcher; // Who claimed it
        string title;
        string descriptionIPFSHash;
        string outputIPFSHash; // Submitted output
        string aiAuditReportIPFSHash; // IPFS hash for AI audit report
        uint256 totalFunds; // Total funding for this proposal (excluding initial proposal fee)
        uint256 createdAt;
        uint256 claimedAt;
        uint256 outputSubmittedAt;
        ProposalStatus status;
        int256 aiScore; // AI audit score, e.g., -100 to 100, or 0 if not audited
        uint256 totalPositiveReputationVotes; // Sum of reputation points from 'acceptable' human votes
        uint256 totalNegativeReputationVotes; // Sum of reputation points from 'unacceptable' human votes
        uint256 totalUniqueValidators; // Count of unique human validators
        bool aiAuditRequested; // Signals off-chain AI oracle (becomes true upon output submission)
        bool aiAuditReceived;  // True once AI oracle reports results
    }

    mapping(uint256 => Proposal) public proposals; // All research proposals
    mapping(uint256 => mapping(address => bool)) private _humanVoted; // proposalId => validatorAddress => hasVoted
    mapping(uint256 => mapping(address => bool)) private _humanVoteAcceptable; // proposalId => validatorAddress => isAcceptable
    mapping(uint256 => mapping(address => string)) private _humanVoteRationale; // proposalId => validatorAddress => rationaleIPFSHash

    mapping(address => int256) public participantReputation; // Reputation score for researchers and validators
    mapping(address => uint256) public earnedRewards; // Accumulated AFL_TOKEN rewards for participants (researchers)

    uint256 public communityFundBalance; // Funds reserved for community initiatives, penalties, and pooled validator rewards

    // --- Constructor ---
    constructor(
        address _aflTokenAddress,
        address _aiOracleAddress,
        address _feeRecipient
    ) Ownable(msg.sender) {
        require(_aflTokenAddress != address(0), "Invalid token address");
        require(_aiOracleAddress != address(0), "Invalid AI oracle address");
        require(_feeRecipient != address(0), "Invalid fee recipient address");

        AFL_TOKEN = IERC20(_aflTokenAddress);
        aiOracleAddress = _aiOracleAddress;
        feeRecipient = _feeRecipient;

        _nextProposalId = 1;
        // Default values for configuration. These can be updated by admin.
        proposalFee = 100 * (10 ** 18); // Example: 100 tokens (assuming 18 decimals)
        minProposalDeposit = 500 * (10 ** 18); // Example: 500 tokens
        claimPeriod = 7 days; // 7 days for researcher to submit output
        validationPeriod = 3 days; // 3 days for human validation after output
        aiAuditThreshold = 60; // AI score of 60 or higher is considered a pass (out of 100)
        aiOverrideThreshold = 90; // If AI score is 90+, it can strongly override negative human votes
        researcherRewardShareNumerator = 60; // 60% of total funds
        researcherRewardShareDenominator = 100;
        validatorRewardShareNumerator = 20; // 20% pooled for validators (goes to community fund)
        validatorRewardShareDenominator = 100;
        communityFundShareNumerator = 10; // 10%
        communityFundShareDenominator = 100;
        proposerRefundShareNumerator = 90; // 90% refund if unsuccessful (after fees/community shares)
        proposerRefundShareDenominator = 100;
    }

    // --- I. Core Infrastructure & Configuration ---

    // 2. updateLabConfig()
    function updateLabConfig(
        uint256 _newProposalFee,
        uint256 _newMinDeposit,
        uint256 _newClaimPeriod,
        uint256 _newValidationPeriod,
        int256 _newAiAuditThreshold,
        int256 _newAiOverrideThreshold,
        uint256 _newResearcherShareNum,
        uint256 _newResearcherShareDen,
        uint256 _newValidatorShareNum,
        uint256 _newValidatorShareDen,
        uint256 _newCommunityShareNum,
        uint256 _newCommunityShareDen,
        uint256 _newProposerRefundShareNum,
        uint256 _newProposerRefundShareDen,
        address _newFeeRecipient
    ) external onlyOwner {
        require(_newClaimPeriod > 0, "Claim period must be positive");
        require(_newValidationPeriod > 0, "Validation period must be positive");
        require(_newResearcherShareDen > 0 && _newValidatorShareDen > 0 && _newCommunityShareDen > 0 && _newProposerRefundShareDen > 0, "Denominator cannot be zero");
        // Ensure total shares for researcher + validator + community are not more than 100%
        require(_newResearcherShareNum.add(_newValidatorShareNum).add(_newCommunityShareNum) <= _newResearcherShareDen, "Total reward shares exceed 100%");
        require(_newFeeRecipient != address(0), "Invalid fee recipient");

        proposalFee = _newProposalFee;
        minProposalDeposit = _newMinDeposit;
        claimPeriod = _newClaimPeriod;
        validationPeriod = _newValidationPeriod;
        aiAuditThreshold = _newAiAuditThreshold;
        aiOverrideThreshold = _newAiOverrideThreshold;
        researcherRewardShareNumerator = _newResearcherShareNum;
        researcherRewardShareDenominator = _newResearcherShareDen;
        validatorRewardShareNumerator = _newValidatorShareNum;
        validatorRewardShareDenominator = _newValidatorShareDen;
        communityFundShareNumerator = _newCommunityShareNum;
        communityFundShareDenominator = _newCommunityShareDen;
        proposerRefundShareNumerator = _newProposerRefundShareNum;
        proposerRefundShareDenominator = _newProposerRefundShareDen;
        feeRecipient = _newFeeRecipient;

        emit LabConfigUpdated(_newProposalFee, _newMinDeposit, _newClaimPeriod, _newValidationPeriod, _newAiAuditThreshold, _newFeeRecipient);
    }

    // 3. setAIOracleAddress()
    function setAIOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "Invalid AI oracle address");
        aiOracleAddress = _newOracle;
        emit AIOracleAddressUpdated(_newOracle);
    }

    // 4. pause() & 5. unpause() are inherited from OpenZeppelin's Pausable
    //   `pause()` is onlyOwner
    //   `unpause()` is onlyOwner

    // --- II. Research Proposal Lifecycle ---

    // 6. submitResearchProposal()
    function submitResearchProposal(
        string memory _title,
        string memory _descriptionIPFSHash,
        uint256 _fundingAmount
    ) external whenNotPaused nonReentrant {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_descriptionIPFSHash).length > 0, "Description IPFS hash cannot be empty");
        require(_fundingAmount >= minProposalDeposit, "Funding amount too low");
        require(AFL_TOKEN.transferFrom(msg.sender, address(this), _fundingAmount.add(proposalFee)), "Token transfer failed for funding and fee");

        uint256 currentId = _nextProposalId++;
        proposals[currentId] = Proposal({
            id: currentId,
            proposer: msg.sender,
            researcher: address(0), // No researcher assigned yet
            title: _title,
            descriptionIPFSHash: _descriptionIPFSHash,
            outputIPFSHash: "",
            aiAuditReportIPFSHash: "",
            totalFunds: _fundingAmount, // Only the core funding, fee goes to communityFundBalance
            createdAt: block.timestamp,
            claimedAt: 0,
            outputSubmittedAt: 0,
            status: ProposalStatus.Open,
            aiScore: 0,
            totalPositiveReputationVotes: 0,
            totalNegativeReputationVotes: 0,
            totalUniqueValidators: 0,
            aiAuditRequested: false,
            aiAuditReceived: false
        });

        communityFundBalance = communityFundBalance.add(proposalFee);
        emit ProposalSubmitted(currentId, msg.sender, _fundingAmount, _title);
    }

    // 7. fundExistingProposal()
    function fundExistingProposal(uint256 _proposalId, uint256 _additionalAmount) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Open || proposal.status == ProposalStatus.Claimed, "Proposal not in fundable state (must be Open or Claimed)");
        require(_additionalAmount > 0, "Additional amount must be positive");
        require(AFL_TOKEN.transferFrom(msg.sender, address(this), _additionalAmount), "Token transfer failed for additional funding");

        proposal.totalFunds = proposal.totalFunds.add(_additionalAmount);
        emit ProposalFunded(_proposalId, msg.sender, _additionalAmount);
    }

    // 8. claimProposal()
    function claimProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Open, "Proposal not open for claiming");
        require(msg.sender != proposal.proposer, "Proposer cannot claim their own proposal");
        require(participantReputation[msg.sender] >= 0, "Only participants with non-negative reputation can claim"); // Basic gate

        proposal.researcher = msg.sender;
        proposal.claimedAt = block.timestamp;
        proposal.status = ProposalStatus.Claimed;
        emit ProposalClaimed(_proposalId, msg.sender);
    }

    // 9. submitResearchOutput()
    function submitResearchOutput(uint256 _proposalId, string memory _outputIPFSHash) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Claimed, "Proposal not in claimed state");
        require(msg.sender == proposal.researcher, "Only the assigned researcher can submit output");
        require(block.timestamp <= proposal.claimedAt.add(claimPeriod), "Claim period has expired");
        require(bytes(_outputIPFSHash).length > 0, "Output IPFS hash cannot be empty");

        proposal.outputIPFSHash = _outputIPFSHash;
        proposal.outputSubmittedAt = block.timestamp;
        proposal.status = ProposalStatus.OutputSubmitted;
        proposal.aiAuditRequested = true; // Signals off-chain AI oracle to perform audit
        // The oracle will call `reportAIAuditResult` when its analysis is complete.

        emit ResearchOutputSubmitted(_proposalId, msg.sender, _outputIPFSHash);
    }

    // 10. abandonClaim()
    function abandonClaim(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Claimed, "Proposal not in claimed state");
        require(msg.sender == proposal.researcher, "Only the assigned researcher can abandon claim");

        proposal.researcher = address(0);
        proposal.claimedAt = 0;
        proposal.status = ProposalStatus.Open;
        emit ClaimAbandoned(_proposalId, msg.sender);
    }

    // 11. withdrawUnclaimedFunds()
    function withdrawUnclaimedFunds(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Open, "Proposal is not in an open state");
        require(msg.sender == proposal.proposer, "Only the proposer can withdraw unclaimed funds");
        require(block.timestamp > proposal.createdAt.add(claimPeriod), "Claim period has not expired for unclaimed proposal (from creation)");

        uint256 amountToRefund = proposal.totalFunds;
        proposal.totalFunds = 0; // Clear funds from proposal
        proposal.status = ProposalStatus.Expired; // Mark as expired
        require(AFL_TOKEN.transfer(msg.sender, amountToRefund), "Refund transfer failed");
        emit ProposalExpired(_proposalId, msg.sender);
    }

    // 12. expireClaimedProposal()
    function expireClaimedProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.Claimed, "Proposal not in claimed state or already expired");
        require(block.timestamp > proposal.claimedAt.add(claimPeriod), "Claim period has not expired yet");

        uint256 amountToRefund = proposal.totalFunds;
        proposal.totalFunds = 0; // Clear funds from proposal
        proposal.status = ProposalStatus.Expired; // Mark as expired
        
        // Penalize researcher for not submitting in time
        participantReputation[proposal.researcher] = participantReputation[proposal.researcher].sub(50); // Example penalty
        emit ReputationUpdated(proposal.researcher, participantReputation[proposal.researcher]);
        
        // Clear researcher, but note the penalty.
        address prevResearcher = proposal.researcher;
        proposal.researcher = address(0);

        require(AFL_TOKEN.transfer(proposal.proposer, amountToRefund), "Refund transfer failed");
        emit ProposalExpired(_proposalId, proposal.proposer);
    }

    // --- III. Validation, AI Audit & Resolution ---

    // 13. reportAIAuditResult()
    function reportAIAuditResult(
        uint256 _proposalId,
        int256 _aiScore,
        string memory _auditReportIPFSHash
    ) external whenNotPaused nonReentrant {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can report audit results");

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.OutputSubmitted, "Proposal not in output submitted state, awaiting AI audit");
        require(proposal.aiAuditRequested, "AI audit was not requested for this proposal");
        require(!proposal.aiAuditReceived, "AI audit already received"); // Ensure single audit report
        require(bytes(_auditReportIPFSHash).length > 0, "Audit report IPFS hash cannot be empty");

        proposal.aiScore = _aiScore;
        proposal.aiAuditReportIPFSHash = _auditReportIPFSHash;
        proposal.aiAuditReceived = true;
        proposal.status = ProposalStatus.AIAudited; // Now ready for human validation and resolution

        emit AIAuditReported(_proposalId, _aiScore, _auditReportIPFSHash);
    }

    // 14. submitHumanValidationVote()
    function submitHumanValidationVote(
        uint256 _proposalId,
        bool _isAcceptable,
        string memory _rationaleIPFSHash
    ) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.OutputSubmitted || proposal.status == ProposalStatus.AIAudited, "Proposal not in votable state");
        require(msg.sender != proposal.proposer, "Proposer cannot vote on their own proposal");
        require(msg.sender != proposal.researcher, "Researcher cannot vote on their own output");
        require(participantReputation[msg.sender] >= 0, "Only participants with non-negative reputation can vote");
        require(!_humanVoted[_proposalId][msg.sender], "Already voted on this proposal");
        require(block.timestamp < proposal.outputSubmittedAt.add(validationPeriod), "Validation period has expired");

        _humanVoted[_proposalId][msg.sender] = true;
        _humanVoteAcceptable[_proposalId][msg.sender] = _isAcceptable;
        _humanVoteRationale[_proposalId][msg.sender] = _rationaleIPFSHash;

        uint256 voteWeight = uint256(participantReputation[msg.sender] >= 0 ? participantReputation[msg.sender] : 0).add(1); // At least 1 weight
        if (_isAcceptable) {
            proposal.totalPositiveReputationVotes = proposal.totalPositiveReputationVotes.add(voteWeight);
        } else {
            proposal.totalNegativeReputationVotes = proposal.totalNegativeReputationVotes.add(voteWeight);
        }
        proposal.totalUniqueValidators = proposal.totalUniqueValidators.add(1);

        emit HumanVoteSubmitted(_proposalId, msg.sender, _isAcceptable);
    }

    // 15. revokeHumanValidationVote()
    function revokeHumanValidationVote(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.OutputSubmitted || proposal.status == ProposalStatus.AIAudited, "Proposal not in votable state");
        require(_humanVoted[_proposalId][msg.sender], "Have not voted on this proposal");
        require(block.timestamp < proposal.outputSubmittedAt.add(validationPeriod), "Validation period has expired");

        uint256 voteWeight = uint256(participantReputation[msg.sender] >= 0 ? participantReputation[msg.sender] : 0).add(1);
        if (_humanVoteAcceptable[_proposalId][msg.sender]) {
            proposal.totalPositiveReputationVotes = proposal.totalPositiveReputationVotes.sub(voteWeight);
        } else {
            proposal.totalNegativeReputationVotes = proposal.totalNegativeReputationVotes.sub(voteWeight);
        }
        proposal.totalUniqueValidators = proposal.totalUniqueValidators.sub(1);

        delete _humanVoted[_proposalId][msg.sender];
        delete _humanVoteAcceptable[_proposalId][msg.sender];
        delete _humanVoteRationale[_proposalId][msg.sender];

        emit HumanVoteRevoked(_proposalId, msg.sender);
    }

    // 16. resolveProposal()
    function resolveProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.status == ProposalStatus.OutputSubmitted || proposal.status == ProposalStatus.AIAudited, "Proposal not in resolvable state");
        require(proposal.aiAuditReceived, "AI audit results not yet received"); // Must have AI audit
        require(block.timestamp >= proposal.outputSubmittedAt.add(validationPeriod), "Validation period not over yet");

        proposal.status = ProposalStatus.Resolved; // Set status early to prevent re-resolution

        bool aiPassed = proposal.aiScore >= aiAuditThreshold;
        bool humanPassed = proposal.totalPositiveReputationVotes > proposal.totalNegativeReputationVotes;

        bool success = false;
        // Advanced resolution logic combining AI and human input:
        // 1. Strong Consensus: Both AI and humans agree.
        // 2. AI Override: AI score is very high, overriding negative human votes.
        // 3. Human Override: Human consensus is overwhelmingly positive, overriding a neutral/negative AI score.
        if (aiPassed && humanPassed) {
            success = true; // Strong consensus
        } else if (aiPassed && !humanPassed && proposal.aiScore >= aiOverrideThreshold) {
            success = true; // AI score is high enough to override negative human votes
        } else if (!aiPassed && humanPassed && proposal.totalPositiveReputationVotes > proposal.totalNegativeReputationVotes.mul(2)) { // Human votes overwhelmingly positive (2x negative)
            success = true; // Human consensus overrides AI
        }

        uint256 totalAvailableFunds = proposal.totalFunds;
        uint256 researcherReward = 0;
        uint256 validatorRewardPool = 0;
        uint256 communityShare = 0;
        uint256 proposerRefund = 0;
        uint256 remainingFunds = totalAvailableFunds;

        if (success) {
            // Researcher rewards: tokens and reputation
            researcherReward = totalAvailableFunds.mul(researcherRewardShareNumerator).div(researcherRewardShareDenominator);
            earnedRewards[proposal.researcher] = earnedRewards[proposal.researcher].add(researcherReward);
            participantReputation[proposal.researcher] = participantReputation[proposal.researcher].add(100); // Example: +100 reputation for success
            emit ReputationUpdated(proposal.researcher, participantReputation[proposal.researcher]);
            remainingFunds = remainingFunds.sub(researcherReward);

            // Validator rewards: tokens are pooled to community fund, reputation not updated in this function
            // (due to gas limits for iterating all voters). Validator reputation updates can be handled via
            // a separate mechanism (e.g., governance or a claim function which verifies votes).
            validatorRewardPool = totalAvailableFunds.mul(validatorRewardShareNumerator).div(validatorRewardShareDenominator);
            communityFundBalance = communityFundBalance.add(validatorRewardPool); // Pooled for community/future distribution
            remainingFunds = remainingFunds.sub(validatorRewardPool);

            // Community share from successful proposals
            communityShare = totalAvailableFunds.mul(communityFundShareNumerator).div(communityFundShareDenominator);
            communityFundBalance = communityFundBalance.add(communityShare);
            remainingFunds = remainingFunds.sub(communityShare);

            // Any dust left goes to community fund
            communityFundBalance = communityFundBalance.add(remainingFunds);

        } else { // Proposal failed
            // Researcher penalty (if not already handled by expireClaimedProposal)
            participantReputation[proposal.researcher] = participantReputation[proposal.researcher].sub(50); // Example: -50 reputation for failure
            emit ReputationUpdated(proposal.researcher, participantReputation[proposal.researcher]);
            
            // Proposer refund for failed proposals
            proposerRefund = totalAvailableFunds.mul(proposerRefundShareNumerator).div(proposerRefundShareDenominator);
            remainingFunds = remainingFunds.sub(proposerRefund);
            require(AFL_TOKEN.transfer(proposal.proposer, proposerRefund), "Proposer refund failed");

            // Remaining funds to community (e.g., the part not refunded to proposer, small shares from penalties)
            communityFundBalance = communityFundBalance.add(remainingFunds);
        }

        proposal.totalFunds = 0; // Clear proposal funds after distribution
        emit ProposalResolved(_proposalId, success, proposal.researcher, researcherReward, communityFundBalance);
    }

    // 17. withdrawRewards()
    function withdrawRewards() external nonReentrant {
        uint256 amount = earnedRewards[msg.sender];
        require(amount > 0, "No rewards to withdraw");

        earnedRewards[msg.sender] = 0; // Reset balance before transfer to prevent re-entrancy issues
        require(AFL_TOKEN.transfer(msg.sender, amount), "Reward transfer failed");
        emit RewardsWithdrawn(msg.sender, amount);
    }

    // 18. getParticipantReputation()
    function getParticipantReputation(address _participant) public view returns (int256) {
        return participantReputation[_participant];
    }

    // --- IV. Reputation & Admin Functions ---

    // 19. penalizeParticipant()
    function penalizeParticipant(address _participant, uint256 _penaltyAmount) external onlyOwner {
        require(_participant != address(0), "Invalid participant address");
        require(_penaltyAmount > 0, "Penalty amount must be positive");

        int256 currentRep = participantReputation[_participant];
        // Using SafeMath for uint, need to cast int to uint then back to int.
        // A direct `sub` on `int256` is safe against underflow by definition (goes more negative).
        participantReputation[_participant] = currentRep - int256(_penaltyAmount);
        emit ParticipantPenalized(_participant, _penaltyAmount);
        emit ReputationUpdated(_participant, participantReputation[_participant]);
    }

    // 20. withdrawCommunityFund()
    function withdrawCommunityFund() external onlyOwner nonReentrant {
        uint256 amount = communityFundBalance;
        require(amount > 0, "No funds in community balance");

        communityFundBalance = 0;
        require(AFL_TOKEN.transfer(owner(), amount), "Community fund transfer failed"); // Owner can withdraw community funds
        emit CommunityFundWithdrawn(owner(), amount);
    }

    // 21. getProposalDetails()
    function getProposalDetails(uint256 _proposalId)
        public view
        returns (
            uint256 id,
            address proposer,
            address researcher,
            string memory title,
            string memory descriptionIPFSHash,
            string memory outputIPFSHash,
            string memory aiAuditReportIPFSHash,
            uint256 totalFunds,
            uint256 createdAt,
            uint256 claimedAt,
            uint256 outputSubmittedAt,
            ProposalStatus status,
            int256 aiScore,
            uint256 totalPositiveReputationVotes,
            uint256 totalNegativeReputationVotes,
            uint256 totalUniqueValidators
        )
    {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "Proposal does not exist");
        return (
            p.id,
            p.proposer,
            p.researcher,
            p.title,
            p.descriptionIPFSHash,
            p.outputIPFSHash,
            p.aiAuditReportIPFSHash,
            p.totalFunds,
            p.createdAt,
            p.claimedAt,
            p.outputSubmittedAt,
            p.status,
            p.aiScore,
            p.totalPositiveReputationVotes,
            p.totalNegativeReputationVotes,
            p.totalUniqueValidators
        );
    }

    // 22. getHumanVoteDetails()
    function getHumanVoteDetails(uint256 _proposalId, address _validator)
        public view
        returns (bool hasVoted, bool isAcceptable, string memory rationaleIPFSHash)
    {
        return (_humanVoted[_proposalId][_validator], _humanVoteAcceptable[_proposalId][_validator], _humanVoteRationale[_proposalId][_validator]);
    }
}
```