```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Gemini AI
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO) that facilitates collaborative research,
 *      funding, peer review, and intellectual property management in a transparent and decentralized manner.
 *
 * Outline:
 * 1.  Research Proposal Submission & Voting: Allow researchers to submit proposals and DAO members to vote on them.
 * 2.  Funding Mechanism: Enable funding of approved research proposals through DAO contributions or external sources.
 * 3.  Task Assignment & Completion: Break down research projects into tasks, assign them to researchers, and track progress.
 * 4.  Peer Review System: Implement a decentralized peer review system for research outputs and task completions.
 * 5.  Reputation & Reward System: Reward researchers based on contributions, peer reviews, and task completions.
 * 6.  Intellectual Property Management:  Decentralized registration and management of research outputs as intellectual property.
 * 7.  Data Storage & Access Control: Manage access to research data and outputs in a decentralized manner.
 * 8.  Dispute Resolution: Mechanism for resolving disputes related to research contributions or intellectual property.
 * 9.  Governance & DAO Management: Functions for DAO governance, membership management, and parameter adjustments.
 * 10. Emergency Stop & Upgradeability: Safety mechanisms for contract upgrades and emergency situations.
 * 11. Dynamic Task Pricing: Automatically adjust task rewards based on demand and complexity.
 * 12. Decentralized Identity for Researchers: Integrate with a decentralized identity solution for researcher profiles.
 * 13. Research Output NFTs: Mint NFTs representing research outputs for provenance and ownership tracking.
 * 14. Quadratic Funding for Research Proposals: Implement quadratic funding to democratize funding allocation.
 * 15. Bounty System for Specific Research Tasks: Offer bounties for solving specific research challenges.
 * 16. Decentralized Data Marketplace for Research Outputs: Create a marketplace for researchers to share and monetize their data.
 * 17. Reputation-Based Access to Advanced Research: Tiered access to research data and tools based on researcher reputation.
 * 18. AI-Assisted Proposal Review (Off-chain Oracle Integration): Use an oracle to integrate AI for initial proposal screening.
 * 19. Dynamic Reward Adjustment based on Research Impact (Oracle): Adjust future rewards based on the real-world impact of research (via oracle).
 * 20. Collaborative Document Editing & Version Control (Off-chain Integration): Integrate with off-chain decentralized document editing tools, with smart contract tracking.
 *
 * Function Summary:
 * 1.  `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _ipfsHash)`: Allows researchers to submit research proposals with details, funding goals, and IPFS links.
 * 2.  `voteOnProposal(uint256 _proposalId, bool _vote)`: DAO members can vote for or against research proposals.
 * 3.  `fundProposal(uint256 _proposalId)`: Allows anyone to contribute ETH to fund an approved research proposal.
 * 4.  `createResearchTask(uint256 _proposalId, string _taskDescription, uint256 _taskReward)`:  Principal investigators can create tasks within funded research projects.
 * 5.  `assignTask(uint256 _taskId, address _researcher)`: Assigns a research task to a specific researcher.
 * 6.  `submitTaskCompletion(uint256 _taskId, string _ipfsHash)`: Researchers submit completed tasks with links to their work.
 * 7.  `requestTaskReview(uint256 _taskId)`: Researcher requests a peer review for their completed task.
 * 8.  `submitTaskReview(uint256 _taskId, uint8 _rating, string _reviewComment)`: Reviewers submit reviews for completed tasks, including ratings and comments.
 * 9.  `approveTaskCompletion(uint256 _taskId)`: DAO (or project lead) approves a task completion after successful review.
 * 10. `rewardResearcher(uint256 _taskId)`:  Distributes rewards to researchers upon successful task completion.
 * 11. `registerIntellectualProperty(string _ipDescription, string _ipfsHash)`: Researchers can register intellectual property related to their research.
 * 12. `accessResearchData(uint256 _proposalId, string _dataIdentifier)`: Allows authorized researchers to access research data based on access control rules.
 * 13. `raiseDispute(uint256 _disputeId, string _disputeDescription)`: Allows participants to raise disputes related to research or IP.
 * 14. `resolveDispute(uint256 _disputeId, string _resolution)`: DAO (or designated arbitrators) can resolve disputes.
 * 15. `proposeDAOParameterChange(string _parameterName, uint256 _newValue)`: DAO members can propose changes to DAO parameters (e.g., voting quorum).
 * 16. `voteOnParameterChange(uint256 _proposalId, bool _vote)`: DAO members vote on proposed parameter changes.
 * 17. `executeParameterChange(uint256 _proposalId)`: Executes approved DAO parameter changes.
 * 18. `emergencyStop()`:  Emergency stop function to pause contract functionality in critical situations (governance controlled).
 * 19. `upgradeContract(address _newContractAddress)`: Function for upgrading the contract to a new implementation (governance controlled).
 * 20. `dynamicTaskPricing(uint256 _taskId)`:  (Illustrative - would require more complex logic and potentially oracle data). Example function for dynamic task pricing.
 * 21. `registerResearcherProfile(string _identityHash)`: Researchers register their decentralized identity profile.
 * 22. `mintResearchOutputNFT(uint256 _taskId, string _nftMetadataURI)`: Mints an NFT representing a research output.
 * 23. `quadraticFundingContribution(uint256 _proposalId)`:  Allows contributions to proposals using a quadratic funding mechanism.
 * 24. `createResearchBounty(string _bountyDescription, uint256 _bountyReward, string _ipfsDetails)`: Creates a bounty for specific research problems.
 * 25. `claimResearchBounty(uint256 _bountyId, string _solutionIpfsHash)`: Researchers can claim bounties by submitting solutions.
 * 26. `purchaseResearchData(uint256 _dataNftId)`: Allows users to purchase access to research data NFTs.
 * 27. `grantTieredAccess(address _researcher, uint8 _accessTier)`: Grants tiered access to researchers based on reputation.
 * 28. `requestAIProposalScreening(uint256 _proposalId)`: Requests an AI-based initial screening of a research proposal (oracle call).
 * 29. `recordResearchImpact(uint256 _researchOutputId, uint256 _impactScore)`: Records the real-world impact score of research (via oracle).
 * 30. `collaborateOnDocument(uint256 _documentId, string _offChainDocumentId)`: (Illustrative - Off-chain integration).  Tracks collaborative document editing.
 */

contract DARO {
    // --- Structs ---
    struct ResearchProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string ipfsHash; // IPFS hash for detailed proposal document
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool proposalApproved;
        bool proposalExecuted;
    }

    struct ResearchTask {
        uint256 id;
        uint256 proposalId;
        string description;
        uint256 reward;
        address assignedResearcher;
        bool taskCompleted;
        string completionIpfsHash;
        uint8 reviewRating; // Average rating from reviews
        bool taskApproved;
    }

    struct Review {
        uint256 taskId;
        address reviewer;
        uint8 rating;
        string comment;
    }

    struct IntellectualProperty {
        uint256 id;
        address researcher;
        string description;
        string ipfsHash;
        uint256 registrationTime;
    }

    struct DAOParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool proposalApproved;
        bool proposalExecuted;
    }

    struct Dispute {
        uint256 id;
        string description;
        string resolution;
        bool resolved;
    }

    struct ResearcherProfile {
        address researcherAddress;
        string identityHash; // IPFS hash to decentralized identity profile
        uint256 reputationScore;
        uint8 accessTier;
    }

    struct ResearchBounty {
        uint256 id;
        string description;
        uint256 reward;
        string detailsIpfsHash;
        bool bountyClaimed;
        address claimer;
        string solutionIpfsHash;
    }

    struct ResearchOutputNFT {
        uint256 id;
        uint256 taskId;
        address minter;
        string metadataURI;
        uint256 mintTime;
    }

    // --- State Variables ---
    ResearchProposal[] public researchProposals;
    ResearchTask[] public researchTasks;
    Review[] public reviews;
    IntellectualProperty[] public intellectualProperties;
    DAOParameterChangeProposal[] public parameterChangeProposals;
    Dispute[] public disputes;
    mapping(address => ResearcherProfile) public researcherProfiles;
    ResearchBounty[] public researchBounties;
    ResearchOutputNFT[] public researchOutputNFTs;

    uint256 public proposalCounter;
    uint256 public taskCounter;
    uint256 public ipCounter;
    uint256 public parameterProposalCounter;
    uint256 public disputeCounter;
    uint256 public bountyCounter;
    uint256 public nftCounter;

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals (50%)
    address public daoGovernor; // Address of the DAO governor
    bool public contractPaused = false; // Emergency stop flag

    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => voted
    mapping(uint256 => mapping(address => bool)) public parameterProposalVotes; // parameterProposalId => voter => voted
    mapping(uint256 => mapping(address => bool)) public taskReviewsGiven; // taskId => reviewer => reviewed

    // --- Events ---
    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalFunded(uint256 proposalId, address funder, uint256 amount);
    event TaskCreated(uint256 taskId, uint256 proposalId, string description, uint256 reward);
    event TaskAssigned(uint256 taskId, address researcher);
    event TaskCompletionSubmitted(uint256 taskId, address researcher);
    event TaskReviewRequested(uint256 taskId, address researcher);
    event TaskReviewSubmitted(uint256 taskId, uint256 reviewId, address reviewer, uint8 rating);
    event TaskCompletionApproved(uint256 taskId);
    event ResearcherRewarded(uint256 taskId, address researcher, uint256 reward);
    event IPSubmitted(uint256 ipId, address researcher, string description);
    event DisputeRaised(uint256 disputeId, string description);
    event DisputeResolved(uint256 disputeId, string resolution);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event ContractPaused();
    event ContractUpgraded(address newContractAddress);
    event ResearcherProfileRegistered(address researcherAddress, string identityHash);
    event ResearchOutputNFTMinted(uint256 nftId, uint256 taskId, address minter, string metadataURI);
    event ResearchBountyCreated(uint256 bountyId, string description, uint256 reward);
    event ResearchBountyClaimed(uint256 bountyId, address claimer, string solutionIpfsHash);
    event ResearchDataPurchased(uint256 nftId, address purchaser);
    event TieredAccessGranted(address researcher, uint8 accessTier);
    event AIProposalScreeningRequested(uint256 proposalId);
    event ResearchImpactRecorded(uint256 researchOutputId, uint256 impactScore);
    event DocumentCollaborationStarted(uint256 documentId, string offChainDocumentId);


    // --- Modifiers ---
    modifier onlyDAO() {
        require(msg.sender == daoGovernor, "Only DAO Governor can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < researchProposals.length, "Proposal does not exist.");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(_taskId < researchTasks.length, "Task does not exist.");
        _;
    }

    modifier ipExists(uint256 _ipId) {
        require(_ipId < intellectualProperties.length, "IP does not exist.");
        _;
    }

    modifier parameterProposalExists(uint256 _proposalId) {
        require(_proposalId < parameterChangeProposals.length, "Parameter proposal does not exist.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(_disputeId < disputes.length, "Dispute does not exist.");
        _;
    }

    modifier bountyExists(uint256 _bountyId) {
        require(_bountyId < researchBounties.length, "Bounty does not exist.");
        _;
    }

    modifier nftExists(uint256 _nftId) {
        require(_nftId < researchOutputNFTs.length, "NFT does not exist.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposal proposer can call this.");
        _;
    }

    modifier onlyAssignedResearcher(uint256 _taskId) {
        require(researchTasks[_taskId].assignedResearcher == msg.sender, "Only assigned researcher can call this.");
        _;
    }

    modifier onlyTaskReviewer(uint256 _taskId) {
        // In a real system, reviewer selection would be more sophisticated.
        // Here, any DAO member can review.
        // You might want to add logic for selecting reviewers based on expertise, reputation, etc.
        // For simplicity, let's assume any DAO member can be a reviewer.
        require(msg.sender != researchTasks[_taskId].assignedResearcher, "Researcher cannot review their own task.");
        _;
    }


    // --- Constructor ---
    constructor() {
        daoGovernor = msg.sender; // Deployer is initial DAO Governor
    }

    // --- 1. Research Proposal Submission & Voting ---
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHash
    ) public whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_description).length > 0 && bytes(_ipfsHash).length > 0, "Proposal details cannot be empty.");
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");

        researchProposals.push(ResearchProposal({
            id: proposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            ipfsHash: _ipfsHash,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            proposalApproved: false,
            proposalExecuted: false
        }));

        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
        proposalCounter++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote)
        public
        whenNotPaused
        proposalExists(_proposalId)
    {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        require(block.timestamp <= researchProposals[_proposalId].voteEndTime, "Voting period has ended.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            researchProposals[_proposalId].yesVotes++;
        } else {
            researchProposals[_proposalId].noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);

        _checkProposalOutcome(_proposalId); // Check if proposal outcome is reached after each vote
    }

    function _checkProposalOutcome(uint256 _proposalId) private {
        uint256 totalVotes = researchProposals[_proposalId].yesVotes + researchProposals[_proposalId].noVotes;
        if (totalVotes > 0) { // To prevent division by zero
            uint256 yesPercentage = (researchProposals[_proposalId].yesVotes * 100) / totalVotes;
            if (yesPercentage >= quorumPercentage && block.timestamp > researchProposals[_proposalId].voteEndTime) {
                researchProposals[_proposalId].proposalApproved = true;
            }
        }
    }

    // --- 2. Funding Mechanism ---
    function fundProposal(uint256 _proposalId)
        public
        payable
        whenNotPaused
        proposalExists(_proposalId)
    {
        require(researchProposals[_proposalId].proposalApproved, "Proposal is not approved yet.");
        require(!researchProposals[_proposalId].proposalExecuted, "Proposal already executed (funded).");
        require(researchProposals[_proposalId].currentFunding < researchProposals[_proposalId].fundingGoal, "Proposal already fully funded.");

        uint256 amountToFund = msg.value;
        uint256 remainingFundingNeeded = researchProposals[_proposalId].fundingGoal - researchProposals[_proposalId].currentFunding;

        if (amountToFund > remainingFundingNeeded) {
            amountToFund = remainingFundingNeeded;
            payable(msg.sender).transfer(msg.value - amountToFund); // Return excess funds
        }

        researchProposals[_proposalId].currentFunding += amountToFund;
        emit ProposalFunded(_proposalId, msg.sender, amountToFund);

        if (researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal) {
            researchProposals[_proposalId].proposalExecuted = true;
            // In a real system, you would likely trigger further actions here,
            // such as setting up project wallets, notifying researchers, etc.
        }
    }

    // --- 3. Task Assignment & Completion ---
    function createResearchTask(
        uint256 _proposalId,
        string memory _taskDescription,
        uint256 _taskReward
    ) public whenNotPaused proposalExists(_proposalId) onlyProposalProposer(_proposalId) {
        require(researchProposals[_proposalId].proposalExecuted, "Proposal must be funded before creating tasks.");
        require(bytes(_taskDescription).length > 0, "Task description cannot be empty.");
        require(_taskReward > 0, "Task reward must be greater than zero.");

        researchTasks.push(ResearchTask({
            id: taskCounter,
            proposalId: _proposalId,
            description: _taskDescription,
            reward: _taskReward,
            assignedResearcher: address(0), // Initially unassigned
            taskCompleted: false,
            completionIpfsHash: "",
            reviewRating: 0,
            taskApproved: false
        }));

        emit TaskCreated(taskCounter, _proposalId, _taskDescription, _taskReward);
        taskCounter++;
    }

    function assignTask(uint256 _taskId, address _researcher)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyDAO // Or project lead based on proposal structure
    {
        require(researchTasks[_taskId].assignedResearcher == address(0), "Task already assigned.");
        researchTasks[_taskId].assignedResearcher = _researcher;
        emit TaskAssigned(_taskId, _researcher);
    }

    function submitTaskCompletion(uint256 _taskId, string memory _ipfsHash)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyAssignedResearcher(_taskId)
    {
        require(!researchTasks[_taskId].taskCompleted, "Task already marked as completed.");
        require(bytes(_ipfsHash).length > 0, "Completion IPFS hash cannot be empty.");

        researchTasks[_taskId].taskCompleted = true;
        researchTasks[_taskId].completionIpfsHash = _ipfsHash;
        emit TaskCompletionSubmitted(_taskId, msg.sender);
    }

    // --- 4. Peer Review System ---
    function requestTaskReview(uint256 _taskId)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyAssignedResearcher(_taskId)
    {
        require(researchTasks[_taskId].taskCompleted, "Task must be marked as completed to request review.");
        emit TaskReviewRequested(_taskId, msg.sender);
        // In a more complex system, you might trigger notifications to potential reviewers here.
    }

    function submitTaskReview(uint256 _taskId, uint8 _rating, string memory _reviewComment)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyTaskReviewer(_taskId)
    {
        require(researchTasks[_taskId].taskCompleted, "Task must be marked as completed to submit a review.");
        require(!taskReviewsGiven[_taskId][msg.sender], "Researcher has already submitted a review for this task.");
        require(_rating >= 1 && _rating <= 5, "Review rating must be between 1 and 5."); // Example rating scale

        reviews.push(Review({
            taskId: _taskId,
            reviewer: msg.sender,
            rating: _rating,
            comment: _reviewComment
        }));
        taskReviewsGiven[_taskId][msg.sender] = true;
        emit TaskReviewSubmitted(_taskId, reviews.length - 1, msg.sender, _rating);

        _updateTaskReviewRating(_taskId);
    }

    function _updateTaskReviewRating(uint256 _taskId) private {
        uint256 totalRating = 0;
        uint256 reviewCount = 0;
        for (uint256 i = 0; i < reviews.length; i++) {
            if (reviews[i].taskId == _taskId) {
                totalRating += uint256(reviews[i].rating);
                reviewCount++;
            }
        }
        if (reviewCount > 0) {
            researchTasks[_taskId].reviewRating = uint8(totalRating / reviewCount); // Average rating
        }
    }

    function approveTaskCompletion(uint256 _taskId)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyDAO // Or project lead, or based on review outcome
    {
        require(researchTasks[_taskId].taskCompleted, "Task must be marked as completed to approve.");
        require(!researchTasks[_taskId].taskApproved, "Task already approved.");
        researchTasks[_taskId].taskApproved = true;
        emit TaskCompletionApproved(_taskId);
    }

    // --- 5. Reputation & Reward System ---
    function rewardResearcher(uint256 _taskId)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyDAO // Or project lead
    {
        require(researchTasks[_taskId].taskApproved, "Task must be approved before rewarding researcher.");
        require(researchTasks[_taskId].reward > 0, "Task reward must be greater than zero.");
        require(address(this).balance >= researchTasks[_taskId].reward, "Contract balance insufficient to reward researcher.");

        uint256 rewardAmount = researchTasks[_taskId].reward;
        researchTasks[_taskId].reward = 0; // Prevent double rewarding

        payable(researchTasks[_taskId].assignedResearcher).transfer(rewardAmount);
        emit ResearcherRewarded(_taskId, researchTasks[_taskId].assignedResearcher, rewardAmount);
        _increaseResearcherReputation(researchTasks[_taskId].assignedResearcher, 10); // Example reputation increase
    }

    function _increaseResearcherReputation(address _researcher, uint256 _reputationPoints) private {
        if (researcherProfiles[_researcher].researcherAddress == address(0)) {
            // If researcher profile doesn't exist, create a basic one initially
            registerResearcherProfile("", _researcher); // Register with empty identityHash initially
        }
        researcherProfiles[_researcher].reputationScore += _reputationPoints;
        _updateResearcherAccessTier(_researcher); // Update access tier based on reputation
    }

    function _updateResearcherAccessTier(address _researcher) private {
        uint256 reputation = researcherProfiles[_researcher].reputationScore;
        if (reputation >= 1000) {
            researcherProfiles[_researcher].accessTier = 3; // Advanced Tier
        } else if (reputation >= 500) {
            researcherProfiles[_researcher].accessTier = 2; // Intermediate Tier
        } else if (reputation >= 100) {
            researcherProfiles[_researcher].accessTier = 1; // Basic Tier
        } else {
            researcherProfiles[_researcher].accessTier = 0; // Entry Tier
        }
        emit TieredAccessGranted(_researcher, researcherProfiles[_researcher].accessTier);
    }


    // --- 6. Intellectual Property Management ---
    function registerIntellectualProperty(string memory _ipDescription, string memory _ipfsHash)
        public
        whenNotPaused
    {
        require(bytes(_ipDescription).length > 0 && bytes(_ipfsHash).length > 0, "IP details cannot be empty.");
        intellectualProperties.push(IntellectualProperty({
            id: ipCounter,
            researcher: msg.sender,
            description: _ipDescription,
            ipfsHash: _ipfsHash,
            registrationTime: block.timestamp
        }));
        emit IPSubmitted(ipCounter, msg.sender, _ipDescription);
        ipCounter++;
    }

    // --- 7. Data Storage & Access Control ---
    // (Conceptual - Real decentralized data storage and access control are more complex and often involve off-chain solutions or specialized libraries)
    function accessResearchData(uint256 _proposalId, string memory _dataIdentifier)
        public
        view
        whenNotPaused
        proposalExists(_proposalId)
    {
        // Example Access Control Logic (Simple - Expand for real use cases)
        ResearcherProfile storage profile = researcherProfiles[msg.sender];
        require(profile.researcherAddress != address(0), "Researcher profile not registered.");

        // Example: Allow access to Tier 1 and above researchers for all proposal data
        if (profile.accessTier >= 1) {
            // In a real system, you would return data or pointers to data based on _dataIdentifier.
            // Here we are just checking access.
            // You might use IPFS hashes, decentralized databases, or other mechanisms.
            // For simplicity, we just emit an event indicating access granted.
            emit DocumentCollaborationStarted(_proposalId, _dataIdentifier); // Just as a placeholder
            return; // Access granted
        }

        revert("Access denied. Insufficient access tier.");
    }

    // --- 8. Dispute Resolution ---
    function raiseDispute(string memory _disputeDescription) public whenNotPaused {
        require(bytes(_disputeDescription).length > 0, "Dispute description cannot be empty.");
        disputes.push(Dispute({
            id: disputeCounter,
            description: _disputeDescription,
            resolution: "",
            resolved: false
        }));
        emit DisputeRaised(disputeCounter, _disputeDescription);
        disputeCounter++;
    }

    function resolveDispute(uint256 _disputeId, string memory _resolution)
        public
        whenNotPaused
        disputeExists(_disputeId)
        onlyDAO // Or designated arbitrators
    {
        require(!disputes[_disputeId].resolved, "Dispute already resolved.");
        require(bytes(_resolution).length > 0, "Resolution cannot be empty.");
        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].resolved = true;
        emit DisputeResolved(_disputeId, _resolution);
    }

    // --- 9. Governance & DAO Management ---
    function proposeDAOParameterChange(string memory _parameterName, uint256 _newValue)
        public
        whenNotPaused
        onlyDAO // Or allow any DAO member to propose
    {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");
        parameterChangeProposals.push(DAOParameterChangeProposal({
            id: parameterProposalCounter,
            parameterName: _parameterName,
            newValue: _newValue,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            proposalApproved: false,
            proposalExecuted: false
        }));
        emit ParameterChangeProposed(parameterProposalCounter, _parameterName, _newValue);
        parameterProposalCounter++;
    }

    function voteOnParameterChange(uint256 _proposalId, bool _vote)
        public
        whenNotPaused
        parameterProposalExists(_proposalId)
    {
        require(!parameterProposalVotes[_proposalId][msg.sender], "Already voted on this parameter change proposal.");
        require(block.timestamp <= parameterChangeProposals[_proposalId].voteEndTime, "Voting period has ended.");

        parameterProposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            parameterChangeProposals[_proposalId].yesVotes++;
        } else {
            parameterChangeProposals[_proposalId].noVotes++;
        }
        emit ParameterChangeVoted(_proposalId, msg.sender, _vote);

        _checkParameterChangeOutcome(_proposalId);
    }

    function _checkParameterChangeOutcome(uint256 _proposalId) private {
        uint256 totalVotes = parameterChangeProposals[_proposalId].yesVotes + parameterChangeProposals[_proposalId].noVotes;
        if (totalVotes > 0) {
            uint256 yesPercentage = (parameterChangeProposals[_proposalId].yesVotes * 100) / totalVotes;
            if (yesPercentage >= quorumPercentage && block.timestamp > parameterChangeProposals[_proposalId].voteEndTime) {
                parameterChangeProposals[_proposalId].proposalApproved = true;
            }
        }
    }

    function executeParameterChange(uint256 _proposalId)
        public
        whenNotPaused
        parameterProposalExists(_proposalId)
        onlyDAO
    {
        require(parameterChangeProposals[_proposalId].proposalApproved, "Parameter change proposal not approved.");
        require(!parameterChangeProposals[_proposalId].proposalExecuted, "Parameter change already executed.");

        DAOParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];

        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("votingPeriod"))) {
            votingPeriod = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("quorumPercentage"))) {
            quorumPercentage = proposal.newValue;
        } else {
            revert("Invalid parameter name for change.");
        }

        parameterChangeProposals[_proposalId].proposalExecuted = true;
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue);
    }

    function setDAOGovernor(address _newGovernor) public onlyDAO {
        require(_newGovernor != address(0), "New governor address cannot be zero.");
        daoGovernor = _newGovernor;
    }

    // --- 10. Emergency Stop & Upgradeability ---
    function emergencyStop() public onlyDAO {
        contractPaused = true;
        emit ContractPaused();
    }

    function resumeContract() public onlyDAO {
        contractPaused = false;
    }

    function upgradeContract(address _newContractAddress) public onlyDAO {
        require(_newContractAddress != address(0), "New contract address cannot be zero.");
        // In a real upgradeable contract pattern (e.g., Proxy pattern), this would
        // update the proxy contract to point to the new implementation contract.
        // For simplicity in this example, we just emit an event and assume off-chain
        // mechanisms handle the actual upgrade process.
        emit ContractUpgraded(_newContractAddress);
        // In a proxy pattern, you would usually delegatecall to the new contract here.
        // For this simplified example, we just assume external governance will handle the upgrade.
    }

    // --- 11. Dynamic Task Pricing (Illustrative - simplified example) ---
    function dynamicTaskPricing(uint256 _taskId) public view taskExists(_taskId) returns (uint256) {
        // This is a very basic illustrative example.
        // In a real system, dynamic pricing would be based on more factors like:
        // - Task complexity (estimated effort)
        // - Researcher demand (number of researchers available for this skill set)
        // - Urgency of the research
        // - Current funding levels

        uint256 baseReward = 100 ether; // Example base reward
        uint256 complexityFactor = 1; // Assume complexity is somehow pre-defined or estimated

        // Example: Increase reward if task is unassigned for too long (simple time-based increase)
        uint256 timeSinceCreation = block.timestamp - researchTasks[_taskId].id; // Using task ID as a proxy for creation time (not ideal in real-world)
        uint256 timeFactor = timeSinceCreation / (7 days); // Increase factor every 7 days

        uint256 dynamicReward = baseReward * complexityFactor * (1 + timeFactor);
        return dynamicReward;
    }

    // --- 12. Decentralized Identity for Researchers ---
    function registerResearcherProfile(string memory _identityHash, address _researcherAddress) public {
        require(bytes(_identityHash).length < 256, "Identity hash too long."); // Basic length limit
        require(researcherProfiles[_researcherAddress].researcherAddress == address(0), "Profile already registered for this address.");

        researcherProfiles[_researcherAddress] = ResearcherProfile({
            researcherAddress: _researcherAddress,
            identityHash: _identityHash,
            reputationScore: 0,
            accessTier: 0
        });
        emit ResearcherProfileRegistered(_researcherAddress, _identityHash);
    }

    function updateResearcherIdentityHash(string memory _newIdentityHash) public {
        require(researcherProfiles[msg.sender].researcherAddress != address(0), "Researcher profile not registered.");
        require(bytes(_newIdentityHash).length < 256, "Identity hash too long.");
        researcherProfiles[msg.sender].identityHash = _newIdentityHash;
        emit ResearcherProfileRegistered(msg.sender, _newIdentityHash); // Re-emit event to reflect update
    }


    // --- 13. Research Output NFTs ---
    function mintResearchOutputNFT(uint256 _taskId, string memory _nftMetadataURI)
        public
        whenNotPaused
        taskExists(_taskId)
        onlyAssignedResearcher(_taskId)
    {
        require(researchTasks[_taskId].taskApproved, "Task must be approved before minting NFT.");
        require(bytes(_nftMetadataURI).length > 0, "NFT metadata URI cannot be empty.");

        researchOutputNFTs.push(ResearchOutputNFT({
            id: nftCounter,
            taskId: _taskId,
            minter: msg.sender,
            metadataURI: _nftMetadataURI,
            mintTime: block.timestamp
        }));
        emit ResearchOutputNFTMinted(nftCounter, _taskId, msg.sender, _nftMetadataURI);
        nftCounter++;
    }

    // --- 14. Quadratic Funding for Research Proposals (Illustrative) ---
    function quadraticFundingContribution(uint256 _proposalId) public payable whenNotPaused proposalExists(_proposalId) {
        require(researchProposals[_proposalId].proposalApproved, "Proposal must be approved for funding.");
        require(!researchProposals[_proposalId].proposalExecuted, "Proposal already executed (funded).");
        require(researchProposals[_proposalId].currentFunding < researchProposals[_proposalId].fundingGoal, "Proposal already fully funded.");

        uint256 contributionAmount = msg.value;
        require(contributionAmount > 0, "Contribution must be greater than zero.");

        // In a simplified quadratic funding example, we directly add to proposal funding.
        // A real quadratic funding implementation is more complex and usually involves matching pools and coordination across multiple proposals.
        // This is a simplified illustration.

        uint256 remainingFundingNeeded = researchProposals[_proposalId].fundingGoal - researchProposals[_proposalId].currentFunding;
        uint256 actualContribution = contributionAmount;

        if (actualContribution > remainingFundingNeeded) {
            actualContribution = remainingFundingNeeded;
            payable(msg.sender).transfer(contributionAmount - actualContribution); // Return excess funds
        }

        researchProposals[_proposalId].currentFunding += actualContribution;
        emit ProposalFunded(_proposalId, msg.sender, actualContribution);

        if (researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal) {
            researchProposals[_proposalId].proposalExecuted = true;
        }
    }

    // --- 15. Bounty System for Specific Research Tasks ---
    function createResearchBounty(string memory _bountyDescription, uint256 _bountyReward, string memory _ipfsDetails)
        public
        whenNotPaused
        onlyDAO // Or project leads, or community members with sufficient reputation
    {
        require(bytes(_bountyDescription).length > 0 && bytes(_ipfsDetails).length > 0, "Bounty details cannot be empty.");
        require(_bountyReward > 0, "Bounty reward must be greater than zero.");

        researchBounties.push(ResearchBounty({
            id: bountyCounter,
            description: _bountyDescription,
            reward: _bountyReward,
            detailsIpfsHash: _ipfsDetails,
            bountyClaimed: false,
            claimer: address(0),
            solutionIpfsHash: ""
        }));
        emit ResearchBountyCreated(bountyCounter, _bountyDescription, _bountyReward);
        bountyCounter++;
    }

    function claimResearchBounty(uint256 _bountyId, string memory _solutionIpfsHash)
        public
        whenNotPaused
        bountyExists(_bountyId)
    {
        require(!researchBounties[_bountyId].bountyClaimed, "Bounty already claimed.");
        require(bytes(_solutionIpfsHash).length > 0, "Solution IPFS hash cannot be empty.");
        require(address(this).balance >= researchBounties[_bountyId].reward, "Contract balance insufficient for bounty reward.");

        researchBounties[_bountyId].bountyClaimed = true;
        researchBounties[_bountyId].claimer = msg.sender;
        researchBounties[_bountyId].solutionIpfsHash = _solutionIpfsHash;

        uint256 bountyAmount = researchBounties[_bountyId].reward;
        researchBounties[_bountyId].reward = 0; // Prevent double claiming

        payable(msg.sender).transfer(bountyAmount);
        emit ResearchBountyClaimed(_bountyId, msg.sender, _solutionIpfsHash);
    }

    // --- 16. Decentralized Data Marketplace for Research Outputs (Illustrative - NFT based access) ---
    function purchaseResearchData(uint256 _dataNftId) public payable whenNotPaused nftExists(_dataNftId) {
        ResearchOutputNFT storage dataNFT = researchOutputNFTs[_dataNftId];
        // Example pricing - fixed price for data access
        uint256 dataAccessPrice = 0.1 ether; // Example price

        require(msg.value >= dataAccessPrice, "Insufficient payment for data access.");
        payable(dataNFT.minter).transfer(dataAccessPrice); // Send payment to NFT minter (researcher)
        emit ResearchDataPurchased(_dataNftId, msg.sender);

        // In a real system, you would handle access to the data itself.
        // This might involve decrypting data, providing access keys, etc.
        // For this example, we are just simulating purchase and assume off-chain data access management.
    }

    // --- 18. AI-Assisted Proposal Review (Off-chain Oracle Integration - Example) ---
    function requestAIProposalScreening(uint256 _proposalId) public whenNotPaused proposalExists(_proposalId) onlyDAO {
        // This function would trigger an off-chain oracle request to an AI service.
        // The oracle would analyze the research proposal (e.g., from IPFS link) and return a screening score or summary.
        // The oracle response would need to be handled in a separate function (oracle callback).

        // For this example, we just emit an event to simulate the request.
        emit AIProposalScreeningRequested(_proposalId);
        // In a real system, you would use a library like Chainlink or Tellor to make an oracle request.
    }

    // --- 19. Dynamic Reward Adjustment based on Research Impact (Oracle - Example) ---
    function recordResearchImpact(uint256 _researchOutputId, uint256 _impactScore) public whenNotPaused onlyDAO {
        // This function would be called by an oracle that provides real-world impact scores for research outputs.
        // The oracle would analyze citations, media mentions, real-world applications, etc., and return an impact score.

        // For this example, we are just recording the impact score and could use it to adjust future rewards.
        emit ResearchImpactRecorded(_researchOutputId, _impactScore);
        // In a real system, you would use this impact score to:
        // - Increase reputation of researchers
        // - Adjust funding for future research in related areas
        // - Provide bonuses for high-impact research
    }

    // --- 20. Collaborative Document Editing & Version Control (Off-chain Integration - Example) ---
    function collaborateOnDocument(uint256 _documentId, string memory _offChainDocumentId) public whenNotPaused {
        // This function would be used to track collaborative document editing happening off-chain.
        // _offChainDocumentId would be a reference to a document in a decentralized document editing system (e.g., based on IPFS, Filecoin, etc.).

        emit DocumentCollaborationStarted(_documentId, _offChainDocumentId);
        // In a real system, you would integrate with off-chain document editing tools.
        // You might track versions, contributions, permissions, etc., using events and state updates in the smart contract.
    }

    // --- Fallback function to receive ETH for funding proposals ---
    receive() external payable {}
}
```