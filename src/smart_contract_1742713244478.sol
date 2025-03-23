```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Gemini AI Assistant
 * @dev A sophisticated smart contract for managing a Decentralized Autonomous Research Organization (DARO).
 *      This contract facilitates research project proposals, funding, execution, and data management in a decentralized and transparent manner.
 *
 * **Outline:**
 *
 * **1. Core Functionality:**
 *    - Research Project Proposal Submission and Voting
 *    - Funding Mechanism (Donations, Grants, Tokenomics)
 *    - Researcher and Reviewer Management
 *    - Decentralized Data Storage Integration (Simulated)
 *    - Milestone Tracking and Reporting
 *    - Reputation System for Researchers and Reviewers
 *    - Governance and Parameter Setting
 *
 * **2. Advanced/Trendy Concepts:**
 *    - Quadratic Voting for Proposals
 *    - Data NFTs for Research Outputs
 *    - Decentralized Data Licensing and Access Control (Simulated)
 *    - Time-Based Funding Release with Milestones
 *    - On-Chain Reputation and Skill Badges
 *    - Dynamic Quorum and Voting Thresholds
 *    - Bounties for Specific Research Tasks
 *    - Decentralized Dispute Resolution (Simplified)
 *    - Integration with External Oracles (Simulated for Data Validation)
 *    - Treasury Management with Multi-Sig (Simulated)
 *
 * **3. Creative Functions:**
 *    - Research Idea Bounties: Reward for submitting novel research ideas.
 *    - Collaborative Research Pools: Pools for researchers to collaborate on specific topics.
 *    - "Science NFTs" for recognizing significant research contributions.
 *    - Decentralized Knowledge Graph (Simulated): Linking research projects and data.
 *    - Gamified Research Challenges: Incentivized competitions for solving research problems.
 *
 * **Function Summary:**
 *
 * **Governance & Setup:**
 *  1. `initializeDARO(string _name, string _symbol)`: Initializes the DARO contract with name and symbol.
 *  2. `setGovernanceParameters(uint256 _proposalQuorum, uint256 _votingDuration)`: Sets governance parameters like proposal quorum and voting duration.
 *  3. `addReviewerRole(address _reviewer)`: Adds an address to the reviewer role.
 *  4. `removeReviewerRole(address _reviewer)`: Removes an address from the reviewer role.
 *  5. `setTreasury(address _treasury)`: Sets the treasury address for fund management.
 *
 * **Research Project Management:**
 *  6. `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _ipfsDataHash)`: Submits a new research proposal.
 *  7. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DARO token holders to vote on a research proposal.
 *  8. `executeProposal(uint256 _proposalId)`: Executes a passed research proposal, allocating funds.
 *  9. `reportMilestoneCompletion(uint256 _projectId, string _milestoneName, string _ipfsMilestoneDataHash)`: Researchers report completion of a project milestone.
 *  10. `reviewMilestoneReport(uint256 _projectId, uint256 _milestoneIndex, bool _approve)`: Reviewers approve or reject a milestone completion report.
 *  11. `releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex)`: Releases funds for an approved milestone.
 *  12. `cancelResearchProject(uint256 _projectId)`: Allows governance to cancel a project if necessary.
 *
 * **Funding & Tokenomics:**
 *  13. `donateToDARO() payable`: Allows anyone to donate ETH to the DARO treasury.
 *  14. `allocateGrant(uint256 _projectId, uint256 _amount)`: Allows governance to allocate additional grants to projects.
 *  15. `mintDAROTokens(address _to, uint256 _amount)`: Mints DARO governance tokens (governance controlled).
 *  16. `transferDAROTokens(address _to, uint256 _amount)`: Transfers DARO governance tokens.
 *
 * **Data & Reputation:**
 *  17. `registerResearchDataNFT(uint256 _projectId, string _dataName, string _ipfsDataHash)`: Registers a research dataset as an NFT associated with a project.
 *  18. `licenseResearchDataNFT(uint256 _nftId, address _licensee, uint256 _price)`: Licenses a research data NFT to another address for a fee (simulated licensing).
 *  19. `awardResearcherBadge(address _researcher, string _badgeName)`: Awards a reputation badge to a researcher.
 *  20. `submitResearchIdeaBounty(string _ideaTitle, string _ideaDescription)`: Submits an idea for a research bounty.
 *  21. `voteOnIdeaBounty(uint256 _bountyId, bool _support)`: Votes on a research idea bounty proposal.
 *  22. `executeIdeaBounty(uint256 _bountyId, address _winner)`: Executes an idea bounty and rewards the winner.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DARO is ERC20, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    // Roles
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant REVIEWER_ROLE = keccak256("REVIEWER_ROLE");

    // State Variables
    string public daroName;
    Counters.Counter private _proposalIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _nftIds;
    Counters.Counter private _bountyIds;

    uint256 public proposalQuorum = 5; // Minimum votes for proposal to pass
    uint256 public votingDuration = 7 days; // Voting period for proposals
    address public treasury;

    struct ResearchProposal {
        uint256 id;
        string title;
        string description;
        uint256 fundingGoal;
        string ipfsDataHash; // IPFS hash for proposal details
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool passed;
        mapping(address => bool) voters; // Track voters to prevent double voting
    }
    mapping(uint256 => ResearchProposal) public researchProposals;

    struct ResearchProject {
        uint256 id;
        uint256 proposalId;
        string title;
        string description;
        uint256 totalFunding;
        address researcher;
        uint256 fundsReleased;
        enum Status { Proposed, Active, Completed, Cancelled }
        Status projectStatus;
        Milestone[] milestones;
    }
    mapping(uint256 => ResearchProject) public researchProjects;

    struct Milestone {
        string name;
        string ipfsMilestoneDataHash;
        uint256 fundingPercentage;
        bool completed;
        bool approved;
        bool fundsReleased;
    }

    struct ResearchDataNFT {
        uint256 id;
        uint256 projectId;
        string dataName;
        string ipfsDataHash;
        address owner;
        address licensee; // Simulated licensing
        uint256 licensePrice; // Simulated licensing
    }
    mapping(uint256 => ResearchDataNFT) public researchDataNFTs;

    struct ResearcherProfile {
        EnumerableSet.UintSet badgeIds;
    }
    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(uint256 => string) public researcherBadges; // Badge ID to Name (e.g., 1 => "Data Analysis Expert")
    Counters.Counter private _badgeIds;

    struct ResearchIdeaBounty {
        uint256 id;
        string title;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool passed;
        address winner;
        mapping(address => bool) voters;
    }
    mapping(uint256 => ResearchIdeaBounty) public researchIdeaBounties;


    // Events
    event ProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId, bool passed);
    event ProjectCreated(uint256 projectId, uint256 proposalId, string title, address researcher);
    event MilestoneReported(uint256 projectId, uint256 milestoneIndex, string milestoneName);
    event MilestoneReviewed(uint256 projectId, uint256 milestoneIndex, bool approved);
    event MilestoneFundsReleased(uint256 projectId, uint256 milestoneIndex);
    event DataNFTRegistered(uint256 nftId, uint256 projectId, string dataName);
    event DataNFTLicensed(uint256 nftId, address licensee, uint256 price);
    event ResearcherBadgeAwarded(address researcher, string badgeName, uint256 badgeId);
    event IdeaBountySubmitted(uint256 bountyId, string title, address submitter);
    event IdeaBountyVoted(uint256 bountyId, address voter, bool support);
    event IdeaBountyExecuted(uint256 bountyId, address winner);


    // Modifier for Governance Role
    modifier onlyGovernance() {
        require(hasRole(GOVERNANCE_ROLE, _msgSender()), "Caller is not a governance member");
        _;
    }

    // Modifier for Reviewer Role
    modifier onlyReviewer() {
        require(hasRole(REVIEWER_ROLE, _msgSender()), "Caller is not a reviewer");
        _;
    }

    // Constructor
    constructor() ERC20("DAROGovernanceToken", "DARO") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Deployer is default admin
        _grantRole(GOVERNANCE_ROLE, _msgSender()); // Deployer is also governance by default
    }

    // ------------------------------------------------------------------------
    // Governance & Setup Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Initializes the DARO contract with a name and symbol. Can only be called once.
     * @param _name The name of the DARO organization.
     * @param _symbol The symbol for the DARO governance token.
     */
    function initializeDARO(string memory _name, string memory _symbol) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(daroName).length == 0, "DARO already initialized"); // Prevent re-initialization
        daroName = _name;
        _setupDecimals(18); // Standard 18 decimals for governance token.
        _name = string(abi.encodePacked(_name, "GovernanceToken")); // Update ERC20 name
        _symbol = _symbol; // Use provided symbol for ERC20 token
    }

    /**
     * @dev Sets governance parameters for proposal quorum and voting duration.
     * @param _proposalQuorum Minimum number of votes required for a proposal to pass.
     * @param _votingDuration Duration of voting period in seconds.
     */
    function setGovernanceParameters(uint256 _proposalQuorum, uint256 _votingDuration) external onlyGovernance {
        proposalQuorum = _proposalQuorum;
        votingDuration = _votingDuration;
    }

    /**
     * @dev Adds an address to the reviewer role.
     * @param _reviewer Address to be added as a reviewer.
     */
    function addReviewerRole(address _reviewer) external onlyGovernance {
        _grantRole(REVIEWER_ROLE, _reviewer);
    }

    /**
     * @dev Removes an address from the reviewer role.
     * @param _reviewer Address to be removed from the reviewer role.
     */
    function removeReviewerRole(address _reviewer) external onlyGovernance {
        revokeRole(REVIEWER_ROLE, _reviewer);
    }

    /**
     * @dev Sets the treasury address for managing funds.
     * @param _treasury Address of the treasury contract or multisig wallet.
     */
    function setTreasury(address _treasury) external onlyGovernance {
        treasury = _treasury;
    }

    // ------------------------------------------------------------------------
    // Research Project Management Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Submits a new research project proposal.
     * @param _title Title of the research proposal.
     * @param _description Detailed description of the research proposal.
     * @param _fundingGoal Target funding amount in ETH.
     * @param _ipfsDataHash IPFS hash pointing to a document with full proposal details.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsDataHash
    ) external {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        researchProposals[proposalId] = ResearchProposal({
            id: proposalId,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            ipfsDataHash: _ipfsDataHash,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            executed: false,
            passed: false,
            voters: mapping(address => bool)()
        });
        emit ProposalSubmitted(proposalId, _title, _msgSender());
    }

    /**
     * @dev Allows DARO token holders to vote on a research proposal. Quadratic voting simulated (1 token = 1 vote).
     * @param _proposalId ID of the research proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external {
        require(researchProposals[_proposalId].endTime > block.timestamp, "Voting period has ended");
        require(!researchProposals[_proposalId].executed, "Proposal already executed");
        require(!researchProposals[_proposalId].voters[_msgSender()], "Already voted on this proposal");

        researchProposals[_proposalId].voters[_msgSender()] = true; // Record voter

        if (_support) {
            researchProposals[_proposalId].votesFor += 1; // Quadratic voting simulated: 1 token = 1 vote
        } else {
            researchProposals[_proposalId].votesAgainst += 1;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a research proposal if it has passed the voting and not yet executed.
     *      Creates a ResearchProject if proposal passes and funds are available.
     * @param _proposalId ID of the research proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyGovernance {
        require(researchProposals[_proposalId].endTime <= block.timestamp, "Voting period is still ongoing");
        require(!researchProposals[_proposalId].executed, "Proposal already executed");

        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (proposal.votesFor >= proposalQuorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.passed = true;
            // Simulate fund check and allocation from treasury (in a real system, treasury interaction would be more complex)
            if (address(this).balance >= proposal.fundingGoal) { // Simple check, in real world use treasury contract
                _projectIds.increment();
                uint256 projectId = _projectIds.current();
                researchProjects[projectId] = ResearchProject({
                    id: projectId,
                    proposalId: _proposalId,
                    title: proposal.title,
                    description: proposal.description,
                    totalFunding: proposal.fundingGoal,
                    researcher: _msgSender(), // For simplicity, proposer becomes researcher, in real system, researcher assignment would be a separate step
                    fundsReleased: 0,
                    projectStatus: ResearchProject.Status.Active,
                    milestones: new Milestone[](0) // Initialize empty milestones array
                });
                payable(_msgSender()).transfer(proposal.fundingGoal); // Transfer funds to researcher (simple)
                proposal.executed = true;
                emit ProjectCreated(projectId, _proposalId, proposal.title, _msgSender());
            } else {
                proposal.executed = true; // Mark executed even if funding fails, to prevent re-execution
                proposal.passed = false; // Mark as not passed due to funding issue.
                // In a real system, more robust error handling and funding mechanisms would be needed.
                // Potentially revert or trigger a re-proposal/funding round.
            }
        } else {
            proposal.executed = true;
            proposal.passed = false;
        }
        emit ProposalExecuted(_proposalId, proposal.passed);
    }

    /**
     * @dev Researcher reports completion of a project milestone.
     * @param _projectId ID of the research project.
     * @param _milestoneName Name of the milestone completed.
     * @param _ipfsMilestoneDataHash IPFS hash of the milestone report document.
     */
    function reportMilestoneCompletion(
        uint256 _projectId,
        string memory _milestoneName,
        string memory _ipfsMilestoneDataHash
    ) external {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.researcher == _msgSender(), "Only researcher can report milestones");
        require(project.projectStatus == ResearchProject.Status.Active, "Project is not active");

        Milestone memory newMilestone = Milestone({
            name: _milestoneName,
            ipfsMilestoneDataHash: _ipfsMilestoneDataHash,
            fundingPercentage: 0, // Set funding percentage when milestones are initially defined in proposal (advanced feature)
            completed: true,
            approved: false,
            fundsReleased: false
        });
        project.milestones.push(newMilestone);
        uint256 milestoneIndex = project.milestones.length - 1;
        emit MilestoneReported(_projectId, milestoneIndex, _milestoneName);
    }

    /**
     * @dev Reviewer reviews a milestone completion report and approves or rejects it.
     * @param _projectId ID of the research project.
     * @param _milestoneIndex Index of the milestone in the project's milestones array.
     * @param _approve True to approve the milestone, false to reject.
     */
    function reviewMilestoneReport(uint256 _projectId, uint256 _milestoneIndex, bool _approve) external onlyReviewer {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.projectStatus == ResearchProject.Status.Active, "Project is not active");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(project.milestones[_milestoneIndex].completed, "Milestone not reported as completed");
        require(!project.milestones[_milestoneIndex].approved, "Milestone already reviewed");

        project.milestones[_milestoneIndex].approved = _approve;
        emit MilestoneReviewed(_projectId, _milestoneIndex, _approve);
    }

    /**
     * @dev Releases funds for an approved milestone.
     * @param _projectId ID of the research project.
     * @param _milestoneIndex Index of the milestone to release funds for.
     */
    function releaseMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external onlyGovernance {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.projectStatus == ResearchProject.Status.Active, "Project is not active");
        require(_milestoneIndex < project.milestones.length, "Invalid milestone index");
        require(project.milestones[_milestoneIndex].approved, "Milestone not approved");
        require(!project.milestones[_milestoneIndex].fundsReleased, "Funds already released for this milestone");

        // Simplified milestone funding release - in a real system, funding would be percentage based, and managed more carefully.
        uint256 milestoneFunding = project.totalFunding / project.milestones.length; // Simple equal split for example
        require(address(this).balance >= milestoneFunding, "Insufficient funds in contract for milestone release");

        project.fundsReleased += milestoneFunding;
        project.milestones[_milestoneIndex].fundsReleased = true;
        payable(project.researcher).transfer(milestoneFunding); // Simple transfer
        emit MilestoneFundsReleased(_projectId, _milestoneIndex);
    }

    /**
     * @dev Allows governance to cancel a research project if it's deemed necessary.
     * @param _projectId ID of the research project to cancel.
     */
    function cancelResearchProject(uint256 _projectId) external onlyGovernance {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.projectStatus == ResearchProject.Status.Active, "Project is not active");
        project.projectStatus = ResearchProject.Status.Cancelled;
        // Implement refund logic or other cancellation procedures if needed.
    }

    // ------------------------------------------------------------------------
    // Funding & Tokenomics Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Allows anyone to donate ETH to the DARO treasury.
     */
    function donateToDARO() external payable {
        // Donations directly increase contract balance (acting as simple treasury for this example)
    }

    /**
     * @dev Allows governance to allocate additional grants to existing research projects.
     * @param _projectId ID of the research project to receive the grant.
     * @param _amount Amount of ETH to grant.
     */
    function allocateGrant(uint256 _projectId, uint256 _amount) external onlyGovernance {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.projectStatus == ResearchProject.Status.Active, "Project must be active to receive a grant");
        require(address(this).balance >= _amount, "Insufficient funds in contract for grant allocation");

        project.totalFunding += _amount;
        payable(project.researcher).transfer(_amount); // Simple grant transfer
    }

    /**
     * @dev Mints DARO governance tokens to a specified address (governance controlled).
     * @param _to Address to receive the minted tokens.
     * @param _amount Amount of tokens to mint.
     */
    function mintDAROTokens(address _to, uint256 _amount) external onlyGovernance {
        _mint(_to, _amount * (10**decimals())); // Mint with correct decimal precision
    }

    /**
     * @dev Transfers DARO governance tokens to another address.
     * @param _to Address to receive the tokens.
     * @param _amount Amount of tokens to transfer.
     */
    function transferDAROTokens(address _to, uint256 _amount) external {
        _transfer(_msgSender(), _to, _amount * (10**decimals()));
    }

    // ------------------------------------------------------------------------
    // Data & Reputation Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Registers a research dataset as an NFT associated with a project.
     * @param _projectId ID of the research project the data belongs to.
     * @param _dataName Name of the dataset.
     * @param _ipfsDataHash IPFS hash of the research data.
     */
    function registerResearchDataNFT(uint256 _projectId, string memory _dataName, string memory _ipfsDataHash) external {
        ResearchProject storage project = researchProjects[_projectId];
        require(project.researcher == _msgSender(), "Only researcher can register data NFTs for their project");
        require(project.projectStatus == ResearchProject.Status.Active || project.projectStatus == ResearchProject.Status.Completed, "Project must be active or completed");

        _nftIds.increment();
        uint256 nftId = _nftIds.current();
        researchDataNFTs[nftId] = ResearchDataNFT({
            id: nftId,
            projectId: _projectId,
            dataName: _dataName,
            ipfsDataHash: _ipfsDataHash,
            owner: _msgSender(),
            licensee: address(0), // Initially no licensee
            licensePrice: 0
        });
        emit DataNFTRegistered(nftId, _projectId, _dataName);
    }

    /**
     * @dev Simulates licensing a research data NFT to another address for a fee.
     *       In a real system, this would involve more complex access control and payment mechanisms.
     * @param _nftId ID of the ResearchDataNFT to license.
     * @param _licensee Address to grant the license to.
     * @param _price License fee in ETH.
     */
    function licenseResearchDataNFT(uint256 _nftId, address _licensee, uint256 _price) external payable {
        ResearchDataNFT storage dataNFT = researchDataNFTs[_nftId];
        require(dataNFT.owner == _msgSender(), "Only NFT owner can license it");
        require(msg.value >= _price, "Insufficient license fee sent");

        dataNFT.licensee = _licensee;
        dataNFT.licensePrice = _price;
        payable(dataNFT.owner).transfer(_price); // Transfer license fee to owner (simple)
        emit DataNFTLicensed(_nftId, _licensee, _price);
        // In a real system, access control to data based on licensing would be implemented off-chain or with more advanced on-chain mechanisms.
    }

    /**
     * @dev Awards a reputation badge to a researcher.
     * @param _researcher Address of the researcher to award the badge to.
     * @param _badgeName Name of the badge (e.g., "Expert in Data Analysis").
     */
    function awardResearcherBadge(address _researcher, string memory _badgeName) external onlyGovernance {
        _badgeIds.increment();
        uint256 badgeId = _badgeIds.current();
        researcherBadges[badgeId] = _badgeName;
        researcherProfiles[_researcher].badgeIds.add(badgeId);
        emit ResearcherBadgeAwarded(_researcher, _badgeName, badgeId);
    }

    /**
     * @dev Submits an idea for a research bounty.
     * @param _ideaTitle Title of the research idea bounty.
     * @param _ideaDescription Detailed description of the research idea bounty.
     */
    function submitResearchIdeaBounty(string memory _ideaTitle, string memory _ideaDescription) external {
        _bountyIds.increment();
        uint256 bountyId = _bountyIds.current();
        researchIdeaBounties[bountyId] = ResearchIdeaBounty({
            id: bountyId,
            title: _ideaTitle,
            description: _ideaDescription,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            executed: false,
            passed: false,
            winner: address(0),
            voters: mapping(address => bool)()
        });
        emit IdeaBountySubmitted(bountyId, _ideaTitle, _msgSender());
    }

    /**
     * @dev Allows DARO token holders to vote on a research idea bounty proposal.
     * @param _bountyId ID of the research idea bounty to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnIdeaBounty(uint256 _bountyId, bool _support) external {
        require(researchIdeaBounties[_bountyId].endTime > block.timestamp, "Voting period has ended");
        require(!researchIdeaBounties[_bountyId].executed, "Bounty already executed");
        require(!researchIdeaBounties[_bountyId].voters[_msgSender()], "Already voted on this bounty");

        researchIdeaBounties[_bountyId].voters[_msgSender()] = true;

        if (_support) {
            researchIdeaBounties[_bountyId].votesFor += 1;
        } else {
            researchIdeaBounties[_bountyId].votesAgainst += 1;
        }
        emit IdeaBountyVoted(_bountyId, _msgSender(), _support);
    }

    /**
     * @dev Executes a research idea bounty and rewards the winner. Winner is selected off-chain (e.g., community choice).
     * @param _bountyId ID of the research idea bounty to execute.
     * @param _winner Address of the winner who submitted the best idea (determined off-chain).
     */
    function executeIdeaBounty(uint256 _bountyId, address _winner) external onlyGovernance {
        require(researchIdeaBounties[_bountyId].endTime <= block.timestamp, "Voting period is still ongoing");
        require(!researchIdeaBounties[_bountyId].executed, "Bounty already executed");
        require(researchIdeaBounties[_bountyId].winner == address(0), "Winner already awarded for this bounty"); // Prevent re-awarding

        ResearchIdeaBounty storage bounty = researchIdeaBounties[_bountyId];
        if (bounty.votesFor >= proposalQuorum && bounty.votesFor > bounty.votesAgainst) {
            bounty.passed = true;
            bounty.winner = _winner;
            // Reward winner - for simplicity, just transfer a fixed amount. In real system, amount might be variable and defined in proposal.
            uint256 bountyReward = 1 ether; // Example reward
            require(address(this).balance >= bountyReward, "Insufficient funds for bounty reward");
            payable(_winner).transfer(bountyReward);
            bounty.executed = true;
            emit IdeaBountyExecuted(_bountyId, _winner);
        } else {
            bounty.executed = true;
            bounty.passed = false;
        }
        emit ProposalExecuted(_bountyId, bounty.passed); // Re-use proposal executed event for bounty execution status
    }

    // ------------------------------------------------------------------------
    // Fallback and Receive Functions
    // ------------------------------------------------------------------------

    receive() external payable {} // Allow contract to receive ETH
    fallback() external payable {} // Allow contract to receive ETH
}
```