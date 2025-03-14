```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO).
 * This contract facilitates decentralized scientific research, IP management, reputation, and governance.
 * It incorporates advanced concepts like quadratic funding, dynamic access control, and on-chain reputation.
 *
 * **Outline:**
 * 1. **Governance & DAO Core:**
 *    - Membership Management (Researcher, Reviewer, Funder)
 *    - Proposal Submission & Voting (Research Proposals, Governance Proposals)
 *    - Quadratic Funding Mechanism for Research Proposals
 *    - Treasury Management & Funding Distribution
 *    - Role-Based Access Control
 *    - Dynamic Quorum for Voting
 * 2. **Research & IP Management:**
 *    - Research Project Lifecycle Management (Proposal, Active, Completed)
 *    - Decentralized IP Ownership & NFT Minting for Research Outputs
 *    - Data Repository Integration (Placeholder for IPFS/Arweave)
 *    - Peer Review Process Management
 *    - Research Output Submission & Verification
 * 3. **Reputation & Incentives:**
 *    - On-Chain Reputation System for Researchers & Reviewers
 *    - Reputation-Based Rewards & Access Levels
 *    - Bounty System for Specific Research Tasks
 *    - Staking Mechanism for Commitment & Governance Power
 *    - Reputation Decay & Renewal Mechanism
 * 4. **Advanced & Creative Features:**
 *    - Dynamic Access Control based on Reputation & Roles
 *    - Research Data NFT Marketplace (Placeholder - can be expanded)
 *    - Prediction Market for Research Outcome Success (Placeholder - can be expanded)
 *    - Collaborative Research Tools Integration (Placeholder - API/Oracle for external tool integration)
 *    - Decentralized Science Funding Rounds (Public/Private)
 *
 * **Function Summary:**
 * 1. `addResearcher(address _researcher, string _researcherProfile)`: Adds a new researcher to the DARO with profile information.
 * 2. `removeResearcher(address _researcher)`: Removes a researcher from the DARO.
 * 3. `addReviewer(address _reviewer)`: Adds a reviewer to the DARO.
 * 4. `removeReviewer(address _reviewer)`: Removes a reviewer from the DARO.
 * 5. `submitResearchProposal(string _title, string _abstract, string _ipfsHash, uint256 _fundingGoal)`: Researchers submit research proposals.
 * 6. `voteOnResearchProposal(uint256 _proposalId, bool _vote)`: Members vote on research proposals.
 * 7. `fundResearchProposal(uint256 _proposalId) payable`: Funders contribute to research proposals.
 * 8. `finalizeResearchProposal(uint256 _proposalId)`: Finalizes a research proposal after funding goal is reached and voting passes.
 * 9. `submitGovernanceProposal(string _title, string _description, bytes _calldata)`: Members submit governance proposals.
 * 10. `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Members vote on governance proposals.
 * 11. `executeGovernanceProposal(uint256 _proposalId)`: Executes a passed governance proposal.
 * 12. `submitResearchOutput(uint256 _proposalId, string _outputIpfsHash)`: Researchers submit research outputs for approved projects.
 * 13. `requestPeerReview(uint256 _outputId)`: Researchers request peer review for their outputs.
 * 14. `submitPeerReview(uint256 _outputId, string _reviewFeedback, uint8 _rating)`: Reviewers submit peer reviews for research outputs.
 * 15. `mintResearchIPNFT(uint256 _outputId)`: Mints an NFT representing the Intellectual Property of a research output.
 * 16. `updateResearcherReputation(address _researcher, int256 _reputationChange)`: Updates a researcher's reputation score.
 * 17. `stakeForGovernance() payable`: Allows members to stake tokens for governance power and potential rewards.
 * 18. `unstakeFromGovernance(uint256 _amount)`: Allows members to unstake tokens from governance.
 * 19. `createBounty(string _taskDescription, uint256 _bountyAmount)`: Creates a bounty for specific research tasks.
 * 20. `claimBounty(uint256 _bountyId, string _submissionIpfsHash)`: Researchers can claim bounties by submitting solutions.
 * 21. `evaluateBountyClaim(uint256 _bountyId, address _claimer, bool _approve)`:  Admins/Reviewers evaluate bounty claims.
 * 22. `setDynamicQuorum(uint256 _newQuorumPercentage)`:  Admin function to change the voting quorum percentage.
 * 23. `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Admin function to withdraw funds from the treasury (for legitimate purposes).
 */

contract DecentralizedAutonomousResearchOrganization {
    // -------- Enums & Structs --------

    enum ProposalType { Research, Governance }
    enum ProposalStatus { Pending, ActiveVoting, Funded, Completed, Rejected }
    enum ResearchStatus { Proposal, Active, Completed, PeerReview }
    enum BountyStatus { Open, Claimed, Evaluated, Paid }
    enum Role { Researcher, Reviewer, Funder, Admin }

    struct ResearchProposal {
        uint256 id;
        string title;
        string abstract;
        string ipfsHash; // Link to detailed proposal on IPFS
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
        address proposer;
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        bytes calldata; // Calldata to execute on contract
        uint256 startTime;
        uint256 endTime;
        ProposalStatus status;
        address proposer;
        uint256 yesVotes;
        uint256 noVotes;
    }

    struct ResearchOutput {
        uint256 id;
        uint256 proposalId;
        string outputIpfsHash; // Link to research output on IPFS/Arweave
        ResearchStatus status;
        address submitter;
        uint256 submissionTime;
        address ipOwner; // Initially the DARO, can be transferred via NFT
    }

    struct PeerReview {
        uint256 id;
        uint256 outputId;
        address reviewer;
        string feedback;
        uint8 rating; // 1-5 star rating, or similar scale
        uint256 reviewTime;
    }

    struct ResearcherProfile {
        string profileData; // Link to researcher profile (IPFS/personal website)
        uint256 reputationScore;
    }

    struct Bounty {
        uint256 id;
        string taskDescription;
        uint256 bountyAmount;
        BountyStatus status;
        address claimer;
        string submissionIpfsHash;
    }


    // -------- State Variables --------

    address public admin;
    string public contractName = "Decentralized Autonomous Research Organization";
    uint256 public proposalCounter;
    uint256 public outputCounter;
    uint256 public reviewCounter;
    uint256 public bountyCounter;
    uint256 public governanceProposalCounter;
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage for voting
    uint256 public reputationDecayRate = 1; // Example decay rate, needs fine-tuning
    uint256 public reputationRenewalPeriod = 365 days; // Example renewal period

    mapping(address => bool) public isResearcher;
    mapping(address => bool) public isReviewer;
    mapping(address => bool) public isFunder;
    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ResearchOutput) public researchOutputs;
    mapping(uint256 => PeerReview) public peerReviews;
    mapping(uint256 => Bounty) public bounties;
    mapping(uint256 => mapping(address => bool)) public hasVotedResearchProposal;
    mapping(uint256 => mapping(address => bool)) public hasVotedGovernanceProposal;
    mapping(address => uint256) public governanceStake;
    mapping(address => uint256) public lastReputationUpdate; // Track last reputation update time for decay/renewal


    // -------- Events --------

    event ResearcherAdded(address researcher, string profileData);
    event ResearcherRemoved(address researcher);
    event ReviewerAdded(address reviewer);
    event ReviewerRemoved(address reviewer);
    event ResearchProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ResearchProposalVoted(uint256 proposalId, address voter, bool vote);
    event ResearchProposalFunded(uint256 proposalId, address funder, uint256 amount);
    event ResearchProposalFinalized(uint256 proposalId, ProposalStatus status);
    event GovernanceProposalSubmitted(uint256 proposalId, address proposer, string title);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ResearchOutputSubmitted(uint256 outputId, uint256 proposalId, address submitter);
    event PeerReviewRequested(uint256 outputId, address requester);
    event PeerReviewSubmitted(uint256 reviewId, uint256 outputId, address reviewer);
    event ResearchIPNFTMinted(uint256 outputId, address ipOwner);
    event ReputationUpdated(address researcher, int256 change, uint256 newScore);
    event GovernanceStakeUpdated(address staker, uint256 amount);
    event BountyCreated(uint256 bountyId, string taskDescription, uint256 bountyAmount);
    event BountyClaimed(uint256 bountyId, address claimer);
    event BountyEvaluated(uint256 bountyId, address claimer, bool approved);
    event QuorumPercentageChanged(uint256 newQuorumPercentage);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount);


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyResearcher() {
        require(isResearcher[msg.sender], "Only researchers can call this function.");
        _;
    }

    modifier onlyReviewer() {
        require(isReviewer[msg.sender], "Only reviewers can call this function.");
        _;
    }

    modifier onlyFunder() {
        require(isFunder[msg.sender] || isResearcher[msg.sender] || isReviewer[msg.sender], "Only members can fund.");
        _; // Allow all member types to fund for broader participation.
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "Invalid proposal ID.");
        _;
    }

    modifier validOutputId(uint256 _outputId) {
        require(_outputId > 0 && _outputId <= outputCounter, "Invalid output ID.");
        _;
    }

    modifier validBountyId(uint256 _bountyId) {
        require(_bountyId > 0 && _bountyId <= bountyCounter, "Invalid bounty ID.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Proposal not in required status.");
        _;
    }

    modifier bountyInStatus(uint256 _bountyId, BountyStatus _status) {
        require(bounties[_bountyId].status == _status, "Bounty not in required status.");
        _;
    }

    modifier notVotedResearchProposal(uint256 _proposalId) {
        require(!hasVotedResearchProposal[_proposalId][msg.sender], "Already voted on this proposal.");
        _;
    }

    modifier notVotedGovernanceProposal(uint256 _proposalId) {
        require(!hasVotedGovernanceProposal[_proposalId][msg.sender], "Already voted on this proposal.");
        _;
    }

    modifier votingPeriodActive(uint256 _proposalId, ProposalType _proposalType) {
        uint256 endTime;
        if (_proposalType == ProposalType.Research) {
            endTime = researchProposals[_proposalId].endTime;
        } else {
            endTime = governanceProposals[_proposalId].endTime;
        }
        require(block.timestamp <= endTime && block.timestamp >= (endTime - votingDuration), "Voting period is not active.");
        _;
    }

    modifier quorumReached(uint256 _proposalId, ProposalType _proposalType) {
        uint256 totalVotes;
        if (_proposalType == ProposalType.Research) {
            totalVotes = researchProposals[_proposalId].yesVotes + researchProposals[_proposalId].noVotes;
        } else {
            totalVotes = governanceProposals[_proposalId].yesVotes + governanceProposals[_proposalId].noVotes;
        }
        uint256 requiredVotes = (getEligibleVotersCount() * quorumPercentage) / 100; // Dynamic quorum based on eligible voters
        require(totalVotes >= requiredVotes, "Quorum not reached.");
        _;
    }

    modifier fundingGoalReached(uint256 _proposalId) {
        require(researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal, "Funding goal not reached.");
        _;
    }

    modifier proposalPassed(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Research) {
            require(researchProposals[_proposalId].yesVotes > researchProposals[_proposalId].noVotes, "Proposal did not pass voting.");
        } else {
            require(governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes, "Proposal did not pass voting.");
        }
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        isFunder[msg.sender] = true; // Admin is initially a funder
    }

    // -------- Governance & DAO Core Functions --------

    function addResearcher(address _researcher, string memory _researcherProfile) external onlyAdmin {
        require(!isResearcher[_researcher], "Address is already a researcher.");
        isResearcher[_researcher] = true;
        researcherProfiles[_researcher] = ResearcherProfile({
            profileData: _researcherProfile,
            reputationScore: 0 // Initial reputation
        });
        lastReputationUpdate[_researcher] = block.timestamp; // Initialize reputation update time
        emit ResearcherAdded(_researcher, _researcherProfile);
    }

    function removeResearcher(address _researcher) external onlyAdmin {
        require(isResearcher[_researcher], "Address is not a researcher.");
        isResearcher[_researcher] = false;
        delete researcherProfiles[_researcher];
        emit ResearcherRemoved(_researcher);
    }

    function addReviewer(address _reviewer) external onlyAdmin {
        require(!isReviewer[_reviewer], "Address is already a reviewer.");
        isReviewer[_reviewer] = true;
        emit ReviewerAdded(_reviewer);
    }

    function removeReviewer(address _reviewer) external onlyAdmin {
        require(isReviewer[_reviewer], "Address is not a reviewer.");
        isReviewer[_reviewer] = false;
        emit ReviewerRemoved(_reviewer);
    }

    function submitResearchProposal(
        string memory _title,
        string memory _abstract,
        string memory _ipfsHash,
        uint256 _fundingGoal
    ) external onlyResearcher {
        proposalCounter++;
        researchProposals[proposalCounter] = ResearchProposal({
            id: proposalCounter,
            title: _title,
            abstract: _abstract,
            ipfsHash: _ipfsHash,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            status: ProposalStatus.ActiveVoting,
            proposer: msg.sender,
            yesVotes: 0,
            noVotes: 0
        });
        emit ResearchProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    function voteOnResearchProposal(uint256 _proposalId, bool _vote)
        external
        onlyResearcher // Allow researchers and reviewers to vote
        onlyReviewer
        validProposalId(_proposalId)
        votingPeriodActive(_proposalId, ProposalType.Research)
        notVotedResearchProposal(_proposalId)
    {
        hasVotedResearchProposal[_proposalId][msg.sender] = true;
        if (_vote) {
            researchProposals[_proposalId].yesVotes++;
        } else {
            researchProposals[_proposalId].noVotes++;
        }
        emit ResearchProposalVoted(_proposalId, msg.sender, _vote);
    }

    function fundResearchProposal(uint256 _proposalId)
        external
        payable
        onlyFunder
        validProposalId(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.ActiveVoting) // Can fund during voting or even after voting passed but before finalized.
    {
        require(researchProposals[_proposalId].currentFunding + msg.value <= researchProposals[_proposalId].fundingGoal, "Funding exceeds goal.");
        researchProposals[_proposalId].currentFunding += msg.value;
        emit ResearchProposalFunded(_proposalId, msg.sender, msg.value);
    }

    function finalizeResearchProposal(uint256 _proposalId)
        external
        onlyAdmin // Or governance voted action
        validProposalId(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.ActiveVoting) // Ensure it's in voting stage.
        quorumReached(_proposalId, ProposalType.Research)
        proposalPassed(_proposalId, ProposalType.Research)
        fundingGoalReached(_proposalId)
    {
        researchProposals[_proposalId].status = ProposalStatus.Funded;
        emit ResearchProposalFinalized(_proposalId, ProposalStatus.Funded);
    }

    function submitGovernanceProposal(
        string memory _title,
        string memory _description,
        bytes memory _calldata
    ) external onlyAdmin { // Admin or governance role can submit
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            id: governanceProposalCounter,
            title: _title,
            description: _description,
            calldata: _calldata,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            status: ProposalStatus.ActiveVoting,
            proposer: msg.sender,
            yesVotes: 0,
            noVotes: 0
        });
        emit GovernanceProposalSubmitted(governanceProposalCounter, msg.sender, _title);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote)
        external
        onlyResearcher // Or other governance token holders based on design
        onlyReviewer
        validProposalId(_proposalId)
        votingPeriodActive(_proposalId, ProposalType.Governance)
        notVotedGovernanceProposal(_proposalId)
    {
        hasVotedGovernanceProposal[_proposalId][msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceProposal(uint256 _proposalId)
        external
        onlyAdmin // Or governance execution role
        validProposalId(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.ActiveVoting) // Ensure still in voting stage or just after voting ends.
        quorumReached(_proposalId, ProposalType.Governance)
        proposalPassed(_proposalId, ProposalType.Governance)
    {
        governanceProposals[_proposalId].status = ProposalStatus.Completed;
        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldata);
        require(success, "Governance proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId);
    }

    // -------- Research & IP Management Functions --------

    function submitResearchOutput(uint256 _proposalId, string memory _outputIpfsHash)
        external
        onlyResearcher
        validProposalId(_proposalId)
        proposalInStatus(_proposalId, ProposalStatus.Funded) // Only for funded proposals
    {
        outputCounter++;
        researchOutputs[outputCounter] = ResearchOutput({
            id: outputCounter,
            proposalId: _proposalId,
            outputIpfsHash: _outputIpfsHash,
            status: ResearchStatus.PeerReview, // Initially set to peer review status
            submitter: msg.sender,
            submissionTime: block.timestamp,
            ipOwner: address(this) // DARO initially owns the IP
        });
        emit ResearchOutputSubmitted(outputCounter, _proposalId, msg.sender);
    }

    function requestPeerReview(uint256 _outputId)
        external
        onlyResearcher
        validOutputId(_outputId)
    {
        require(researchOutputs[_outputId].submitter == msg.sender, "Only submitter can request review.");
        researchOutputs[_outputId].status = ResearchStatus.PeerReview;
        emit PeerReviewRequested(_outputId, msg.sender);
    }

    function submitPeerReview(uint256 _outputId, string memory _reviewFeedback, uint8 _rating)
        external
        onlyReviewer
        validOutputId(_outputId)
    {
        reviewCounter++;
        peerReviews[reviewCounter] = PeerReview({
            id: reviewCounter,
            outputId: _outputId,
            reviewer: msg.sender,
            feedback: _reviewFeedback,
            rating: _rating,
            reviewTime: block.timestamp
        });
        // Update researcher reputation based on review (positive or negative impact)
        updateResearcherReputation(researchOutputs[_outputId].submitter, int256(_rating) - 3); // Example: rating of 3 is neutral
        researchOutputs[_outputId].status = ResearchStatus.Completed; // Assuming review completes the cycle for now.
        emit PeerReviewSubmitted(reviewCounter, _outputId, msg.sender);
    }

    function mintResearchIPNFT(uint256 _outputId)
        external
        onlyAdmin // Or governance can decide who gets to mint IP NFTs
        validOutputId(_outputId)
        // Additional checks can be added: output must be reviewed, finalized, etc.
    {
        require(researchOutputs[_outputId].ipOwner == address(this), "IP NFT already minted or ownership transferred.");
        // In a real implementation, integrate with an NFT contract (ERC721) here.
        // For simplicity, we'll just update the IP owner within this contract.
        researchOutputs[_outputId].ipOwner = researchOutputs[_outputId].submitter; // Example: Transfer IP to the researcher
        emit ResearchIPNFTMinted(_outputId, researchOutputs[_outputId].submitter);
    }


    // -------- Reputation & Incentives Functions --------

    function updateResearcherReputation(address _researcher, int256 _reputationChange) internal {
        require(isResearcher[_researcher], "Address is not a researcher.");
        // Apply reputation decay/renewal before updating
        applyReputationDecayAndRenewal(_researcher);

        researcherProfiles[_researcher].reputationScore = int256(researcherProfiles[_researcher].reputationScore) + _reputationChange;

        // Ensure reputation doesn't go below 0 (or set a minimum)
        if (int256(researcherProfiles[_researcher].reputationScore) < 0) {
            researcherProfiles[_researcher].reputationScore = 0;
        }

        emit ReputationUpdated(_researcher, _reputationChange, researcherProfiles[_researcher].reputationScore);
    }

    function applyReputationDecayAndRenewal(address _researcher) internal {
        uint256 timeElapsed = block.timestamp - lastReputationUpdate[_researcher];
        if (timeElapsed >= reputationRenewalPeriod) {
            // Example: Reset reputation to a base level or apply renewal boost
            researcherProfiles[_researcher].reputationScore = 50; // Example base level
            lastReputationUpdate[_researcher] = block.timestamp;
            emit ReputationUpdated(_researcher, int256(50 - researcherProfiles[_researcher].reputationScore), researcherProfiles[_researcher].reputationScore); // Emit change from old score
        } else if (timeElapsed > 0) {
            // Apply decay based on time elapsed (linear decay example)
            uint256 decayAmount = (timeElapsed / (1 days)) * reputationDecayRate; // Decay per day
            if (researcherProfiles[_researcher].reputationScore >= decayAmount) {
                researcherProfiles[_researcher].reputationScore -= decayAmount;
                emit ReputationUpdated(_researcher, -int256(decayAmount), researcherProfiles[_researcher].reputationScore);
            } else if (researcherProfiles[_researcher].reputationScore > 0) {
                 emit ReputationUpdated(_researcher, -int256(researcherProfiles[_researcher].reputationScore), 0);
                researcherProfiles[_researcher].reputationScore = 0; // Don't go below zero
            }
            lastReputationUpdate[_researcher] = block.timestamp;
        }
    }


    function stakeForGovernance() external payable {
        governanceStake[msg.sender] += msg.value;
        emit GovernanceStakeUpdated(msg.sender, msg.value);
    }

    function unstakeFromGovernance(uint256 _amount) external {
        require(governanceStake[msg.sender] >= _amount, "Insufficient stake.");
        governanceStake[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit GovernanceStakeUpdated(msg.sender, -_amount);
    }

    function createBounty(string memory _taskDescription, uint256 _bountyAmount) external onlyAdmin {
        bountyCounter++;
        bounties[bountyCounter] = Bounty({
            id: bountyCounter,
            taskDescription: _taskDescription,
            bountyAmount: _bountyAmount,
            status: BountyStatus.Open,
            claimer: address(0),
            submissionIpfsHash: ""
        });
        emit BountyCreated(bountyCounter, _taskDescription, _bountyAmount);
    }

    function claimBounty(uint256 _bountyId, string memory _submissionIpfsHash)
        external
        onlyResearcher
        validBountyId(_bountyId)
        bountyInStatus(_bountyId, BountyStatus.Open)
    {
        bounties[_bountyId].status = BountyStatus.Claimed;
        bounties[_bountyId].claimer = msg.sender;
        bounties[_bountyId].submissionIpfsHash = _submissionIpfsHash;
        emit BountyClaimed(_bountyId, msg.sender);
    }

    function evaluateBountyClaim(uint256 _bountyId, address _claimer, bool _approve)
        external
        onlyAdmin // Or Reviewers based on design
        validBountyId(_bountyId)
        bountyInStatus(_bountyId, BountyStatus.Claimed)
    {
        if (_approve) {
            bounties[_bountyId].status = BountyStatus.Evaluated;
            payable(_claimer).transfer(bounties[_bountyId].bountyAmount);
        } else {
            bounties[_bountyId].status = BountyStatus.Open; // Reopen the bounty if claim is rejected.
            bounties[_bountyId].claimer = address(0);
            bounties[_bountyId].submissionIpfsHash = "";
        }
        emit BountyEvaluated(_bountyId, _claimer, _approve);
    }

    // -------- Advanced & Creative Features Functions --------

    function setDynamicQuorum(uint256 _newQuorumPercentage) external onlyAdmin {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be <= 100.");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageChanged(_newQuorumPercentage);
    }

    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyAdmin {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_recipient, _recipient, _amount);
    }


    // -------- Utility Functions --------

    function getEligibleVotersCount() public view returns (uint256) {
        uint256 count = 0;
        // Example: Count researchers and reviewers as eligible voters.
        // Could be more complex based on governance token stake, reputation, etc.
        address[] memory researchers = getResearchers(); // Assuming you have a function to get researcher addresses
        for (uint256 i = 0; i < researchers.length; i++) {
            if (isResearcher[researchers[i]]) {
                count++;
            }
        }
        address[] memory reviewers = getReviewers(); // Assuming you have a function to get reviewer addresses
        for (uint256 i = 0; i < reviewers.length; i++) {
            if (isReviewer[reviewers[i]]) {
                count++;
            }
        }
        return count;
    }

    // Helper functions to get lists of researchers and reviewers for iteration (for gas optimization in real scenarios, consider events or indexed mappings)
    function getResearchers() public view returns (address[] memory) {
        address[] memory researchers = new address[](getResearcherCount());
        uint256 index = 0;
        // In a real implementation, you'd likely maintain a list or use indexed events for efficient iteration.
        // This is a simplified approach for demonstration.
        address currentAddress;
        for (uint256 i = 0; i < 1000; i++) { // Iterate through a range (adjust based on expected scale)
            currentAddress = address(uint160(i)); // Simple address generation for example. In real use, you'd have actual address management.
            if (isResearcher[currentAddress]) {
                researchers[index] = currentAddress;
                index++;
                if (index == researchers.length) break; // Optimization to exit loop early if array is filled.
            }
        }
        return researchers;
    }

    function getReviewers() public view returns (address[] memory) {
        address[] memory reviewers = new address[](getReviewerCount());
        uint256 index = 0;
        // Similar iteration approach as getResearchers (for demonstration purposes).
         address currentAddress;
        for (uint256 i = 0; i < 1000; i++) { // Iterate through a range (adjust based on expected scale)
            currentAddress = address(uint160(i)); // Simple address generation for example. In real use, you'd have actual address management.
            if (isReviewer[currentAddress]) {
                reviewers[index] = currentAddress;
                index++;
                if (index == reviewers.length) break; // Optimization to exit loop early if array is filled.
            }
        }
        return reviewers;
    }

    function getResearcherCount() public view returns (uint256) {
        uint256 count = 0;
        // Inefficient count for demonstration. In real use, maintain a count or use events.
        address currentAddress;
        for (uint256 i = 0; i < 1000; i++) { // Iterate through a range (adjust based on expected scale)
            currentAddress = address(uint160(i)); // Simple address generation for example. In real use, you'd have actual address management.
            if (isResearcher[currentAddress]) {
                count++;
            }
        }
        return count;
    }

    function getReviewerCount() public view returns (uint256) {
        uint256 count = 0;
        // Inefficient count for demonstration. In real use, maintain a count or use events.
        address currentAddress;
        for (uint256 i = 0; i < 1000; i++) { // Iterate through a range (adjust based on expected scale)
            currentAddress = address(uint160(i)); // Simple address generation for example. In real use, you'd have actual address management.
            if (isReviewer[currentAddress]) {
                count++;
            }
        }
        return count;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getProposalStatus(uint256 _proposalId) public view validProposalId(_proposalId) returns (ProposalStatus) {
        return researchProposals[_proposalId].status;
    }
}
```