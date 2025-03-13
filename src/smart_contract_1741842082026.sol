```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Skill-Based DAO with Project Incubation
 * @author Gemini AI (Conceptual - Solidity Implementation by Bard)
 * @dev A Decentralized Autonomous Organization (DAO) that incorporates dynamic reputation,
 * skill-based roles, and a project incubation/funding mechanism. This DAO aims to
 * move beyond simple token-weighted voting and incorporate more nuanced governance
 * based on community contribution and expertise.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core DAO Configuration & Setup:**
 *    - `initializeDAO(string _daoName, address _governanceToken, uint256 _quorumPercentage, uint256 _votingDuration)`: Initializes the DAO with name, governance token address, quorum, and voting duration.
 *    - `updateDAOConfiguration(uint256 _newQuorumPercentage, uint256 _newVotingDuration)`: Allows DAO governance to update quorum and voting duration.
 *    - `setTokenContract(address _newTokenAddress)`:  Allows DAO governance to update the governance token contract address (in case of token migration).
 *    - `pauseDAO()`: Emergency function to pause core functionalities (proposals, voting) by DAO governance.
 *    - `unpauseDAO()`: Resumes DAO functionalities after pausing.
 *
 * **2. Membership & Reputation Management:**
 *    - `joinDAO()`: Allows users to become DAO members (potentially requires holding governance tokens).
 *    - `leaveDAO()`: Allows members to leave the DAO.
 *    - `getMemberReputation(address _member)`: Retrieves the reputation score of a member.
 *    - `increaseMemberReputation(address _member, uint256 _amount)`:  Function callable by reputation managers (or via governance) to increase member reputation.
 *    - `decreaseMemberReputation(address _member, uint256 _amount)`: Function callable by reputation managers (or via governance) to decrease member reputation.
 *    - `delegateReputation(address _delegatee)`: Allows members to delegate their reputation to another member for specific skill domains (future enhancement - currently delegates overall reputation weight for voting).
 *    - `revokeReputationDelegation()`: Revokes reputation delegation.
 *
 * **3. Skill-Based Roles & Badges (Future Enhancement - Basic Framework):**
 *    - `addSkillDomain(string _skillName)`:  Adds a new skill domain to the DAO (governance controlled).
 *    - `assignSkillBadge(address _member, string _skillName, string _badgeName)`: Assigns a skill badge to a member within a skill domain (reputation managers or governance).
 *    - `revokeSkillBadge(address _member, string _skillName, string _badgeName)`: Revokes a skill badge from a member.
 *    - `getMemberSkillBadges(address _member)`: Retrieves the skill badges held by a member.
 *
 * **4. Project Proposal & Funding:**
 *    - `proposeProject(string _projectName, string _projectDescription, uint256 _fundingGoal, uint256 _milestoneCount, string[] memory _milestoneDescriptions)`: Allows members to propose a new project with funding goals and milestones.
 *    - `voteOnProjectProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on project proposals. Voting weight is influenced by both governance tokens and reputation.
 *    - `fundProject(uint256 _proposalId)`:  Allows the DAO to fund an approved project from the treasury.
 *    - `submitProjectMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex)`: Project owners can submit a milestone completion for DAO approval.
 *    - `voteOnMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, bool _vote)`: Members vote on milestone completion.
 *    - `releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex)`: Releases funds for a completed and approved milestone.
 *    - `cancelProjectProposal(uint256 _proposalId)`: Allows the proposer to cancel a project proposal before voting ends.
 *    - `abortProject(uint256 _proposalId)`: DAO governance can abort a project if it fails to meet milestones or for other critical reasons.
 *
 * **5. Treasury Management (Simplified):**
 *    - `depositToTreasury()`: Allows anyone to deposit governance tokens or other whitelisted tokens into the DAO treasury.
 *    - `withdrawFromTreasury(address _recipient, uint256 _amount)`:  (Governance controlled) Allows withdrawal of tokens from the treasury to a specified recipient (primarily for project funding).
 *
 * **6. Emergency & Utility:**
 *    - `getDAOInfo()`: Returns basic DAO information like name, token address, quorum, voting duration.
 *    - `getProposalDetails(uint256 _proposalId)`: Returns detailed information about a specific project proposal.
 *
 * **Important Notes:**
 * - This contract is a conceptual framework and requires thorough auditing and security considerations before deployment.
 * - Reputation and skill-based systems are complex and require careful design to prevent manipulation and ensure fairness.
 * - Gas optimization and error handling are crucial for a production-ready smart contract.
 * - The skill-based roles and badges section is a basic framework and can be significantly expanded for richer functionality.
 * - Access control and role management (e.g., reputation managers, skill domain admins) would need to be implemented for a real-world DAO. For simplicity, this example uses `onlyGovernance` modifier for many admin functions.
 * - This contract assumes the existence of a separate governance token contract.
 */
contract DynamicReputationDAO {
    // --- State Variables ---

    string public daoName;
    address public governanceToken; // Address of the governance token contract
    uint256 public quorumPercentage; // Percentage of votes required to pass a proposal (e.g., 51 for 51%)
    uint256 public votingDuration; // Voting duration in blocks

    bool public paused; // Pause state for emergency

    mapping(address => bool) public isMember; // Mapping to track DAO members
    mapping(address => uint256) public memberReputation; // Reputation score for each member
    mapping(address => address) public reputationDelegation; // Delegation of reputation

    mapping(string => bool) public skillDomains; // Track available skill domains (e.g., "Development", "Marketing")
    mapping(address => mapping(string => string[])) public memberSkillBadges; // Member -> Skill Domain -> List of Badges

    uint256 public proposalCount;
    mapping(uint256 => ProjectProposal) public proposals;

    struct ProjectProposal {
        string projectName;
        string projectDescription;
        address proposer;
        uint256 fundingGoal;
        uint256 milestoneCount;
        string[] milestoneDescriptions;
        uint256 currentMilestone; // Index of the current active milestone
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingEndTime;
        bool proposalPassed;
        bool proposalExecuted;
        bool proposalCancelled;
        mapping(address => bool) hasVoted; // Track members who have voted on this proposal
        mapping(uint256 => Milestone) milestones;
    }

    struct Milestone {
        string description;
        uint256 fundsReleased;
        bool completionSubmitted;
        bool completionApproved;
        uint256 completionVotesFor;
        uint256 completionVotesAgainst;
        uint256 completionVotingEndTime;
        mapping(address => bool) hasVotedCompletion;
    }


    address public daoTreasury; // Address of the DAO Treasury (this contract itself acts as treasury in this simplified example)
    address public daoGovernance; // Address that can perform governance actions (initially deployer)

    // --- Events ---
    event DAOInitialized(string daoName, address governanceToken, uint256 quorumPercentage, uint256 votingDuration, address daoGovernance);
    event DAOConfigurationUpdated(uint256 newQuorumPercentage, uint256 newVotingDuration);
    event TokenContractUpdated(address newTokenAddress);
    event DAOPaused();
    event DAOUnpaused();

    event MemberJoined(address member);
    event MemberLeft(address member);
    event ReputationIncreased(address member, uint256 amount);
    event ReputationDecreased(address member, uint256 amount);
    event ReputationDelegated(address delegator, address delegatee);
    event ReputationDelegationRevoked(address delegator);

    event SkillDomainAdded(string skillName);
    event SkillBadgeAssigned(address member, string skillName, string badgeName);
    event SkillBadgeRevoked(address member, string skillName, string badgeName);

    event ProjectProposed(uint256 proposalId, string projectName, address proposer, uint256 fundingGoal);
    event VoteCastOnProposal(uint256 proposalId, address voter, bool vote);
    event ProjectFunded(uint256 proposalId, uint256 fundingAmount);
    event MilestoneCompletionSubmitted(uint256 proposalId, uint256 milestoneIndex);
    event VoteCastOnMilestoneCompletion(uint256 proposalId, uint256 milestoneIndex, address voter, bool vote);
    event MilestoneFundsReleased(uint256 proposalId, uint256 milestoneIndex, uint256 amount);
    event ProjectProposalCancelled(uint256 proposalId);
    event ProjectAborted(uint256 proposalId);

    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyGovernance() {
        require(msg.sender == daoGovernance, "Only DAO Governance can call this function");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only DAO members can call this function");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is currently paused");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].votingEndTime > block.timestamp && !proposals[_proposalId].proposalCancelled && !proposals[_proposalId].proposalExecuted, "Proposal is not active");
        _;
    }

    modifier milestoneExists(uint256 _proposalId, uint256 _milestoneIndex) {
        require(_milestoneIndex > 0 && _milestoneIndex <= proposals[_proposalId].milestoneCount, "Milestone does not exist");
        _;
    }

    modifier milestoneCompletionNotSubmitted(uint256 _proposalId, uint256 _milestoneIndex) {
        require(!proposals[_proposalId].milestones[_milestoneIndex].completionSubmitted, "Milestone completion already submitted");
        _;
    }

    modifier milestoneCompletionActive(uint256 _proposalId, uint256 _milestoneIndex) {
        require(proposals[_proposalId].milestones[_milestoneIndex].completionVotingEndTime > block.timestamp && proposals[_proposalId].milestones[_milestoneIndex].completionSubmitted && !proposals[_proposalId].milestones[_milestoneIndex].completionApproved, "Milestone completion voting is not active");
        _;
    }

    modifier milestoneFundsNotReleased(uint256 _proposalId, uint256 _milestoneIndex) {
        require(proposals[_proposalId].milestones[_milestoneIndex].fundsReleased == 0, "Milestone funds already released");
        _;
    }

    modifier onlyProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == msg.sender, "Only proposer can call this function");
        _;
    }


    // --- Constructor ---
    constructor() {
        daoGovernance = msg.sender; // Deployer is initial DAO Governance
        daoTreasury = address(this); // This contract acts as its own treasury in this example
    }

    // --- 1. Core DAO Configuration & Setup ---
    function initializeDAO(string memory _daoName, address _governanceToken, uint256 _quorumPercentage, uint256 _votingDuration) external onlyGovernance {
        require(bytes(_daoName).length > 0, "DAO name cannot be empty");
        require(_governanceToken != address(0), "Governance token address cannot be zero");
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "Quorum percentage must be between 1 and 100");
        require(_votingDuration > 0, "Voting duration must be greater than 0");

        daoName = _daoName;
        governanceToken = _governanceToken;
        quorumPercentage = _quorumPercentage;
        votingDuration = _votingDuration;

        emit DAOInitialized(_daoName, _governanceToken, _quorumPercentage, _votingDuration, daoGovernance);
    }

    function updateDAOConfiguration(uint256 _newQuorumPercentage, uint256 _newVotingDuration) external onlyGovernance {
        require(_newQuorumPercentage > 0 && _newQuorumPercentage <= 100, "New quorum percentage must be between 1 and 100");
        require(_newVotingDuration > 0, "New voting duration must be greater than 0");

        quorumPercentage = _newQuorumPercentage;
        votingDuration = _newVotingDuration;

        emit DAOConfigurationUpdated(_newQuorumPercentage, _newVotingDuration);
    }

    function setTokenContract(address _newTokenAddress) external onlyGovernance {
        require(_newTokenAddress != address(0), "New token address cannot be zero");
        governanceToken = _newTokenAddress;
        emit TokenContractUpdated(_newTokenAddress);
    }

    function pauseDAO() external onlyGovernance {
        paused = true;
        emit DAOPaused();
    }

    function unpauseDAO() external onlyGovernance {
        paused = false;
        emit DAOUnpaused();
    }

    // --- 2. Membership & Reputation Management ---
    function joinDAO() external notPaused {
        require(!isMember[msg.sender], "Already a member");
        // In a real DAO, you might add logic to check for governance token holding or other criteria
        isMember[msg.sender] = true;
        memberReputation[msg.sender] = 1; // Initial reputation
        emit MemberJoined(msg.sender);
    }

    function leaveDAO() external onlyMember notPaused {
        isMember[msg.sender] = false;
        delete memberReputation[msg.sender];
        emit MemberLeft(msg.sender);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    function increaseMemberReputation(address _member, uint256 _amount) external onlyGovernance notPaused { // Governance controlled for simplicity, could be reputation managers
        require(isMember[_member], "Member does not exist");
        memberReputation[_member] += _amount;
        emit ReputationIncreased(_member, _amount);
    }

    function decreaseMemberReputation(address _member, uint256 _amount) external onlyGovernance notPaused { // Governance controlled for simplicity, could be reputation managers
        require(isMember[_member], "Member does not exist");
        require(memberReputation[_member] >= _amount, "Cannot decrease reputation below zero");
        memberReputation[_member] -= _amount;
        emit ReputationDecreased(_member, _amount);
    }

    function delegateReputation(address _delegatee) external onlyMember notPaused {
        require(isMember[_delegatee], "Delegatee must be a DAO member");
        require(_delegatee != msg.sender, "Cannot delegate to self");
        reputationDelegation[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    function revokeReputationDelegation() external onlyMember notPaused {
        require(reputationDelegation[msg.sender] != address(0), "No delegation to revoke");
        delete reputationDelegation[msg.sender];
        emit ReputationDelegationRevoked(msg.sender);
    }

    // --- 3. Skill-Based Roles & Badges (Basic Framework) ---
    function addSkillDomain(string memory _skillName) external onlyGovernance notPaused {
        require(!skillDomains[_skillName], "Skill domain already exists");
        skillDomains[_skillName] = true;
        emit SkillDomainAdded(_skillName);
    }

    function assignSkillBadge(address _member, string memory _skillName, string memory _badgeName) external onlyGovernance notPaused { // Governance controlled for simplicity
        require(isMember[_member], "Member is not a DAO member");
        require(skillDomains[_skillName], "Skill domain does not exist");
        memberSkillBadges[_member][_skillName].push(_badgeName);
        emit SkillBadgeAssigned(_member, _skillName, _badgeName);
    }

    function revokeSkillBadge(address _member, string memory _skillName, string memory _badgeName) external onlyGovernance notPaused { // Governance controlled for simplicity
        require(isMember[_member], "Member is not a DAO member");
        require(skillDomains[_skillName], "Skill domain does not exist");

        string[] storage badges = memberSkillBadges[_member][_skillName];
        for (uint256 i = 0; i < badges.length; i++) {
            if (keccak256(bytes(badges[i])) == keccak256(bytes(_badgeName))) {
                badges[i] = badges[badges.length - 1];
                badges.pop();
                emit SkillBadgeRevoked(_member, _skillName, _badgeName);
                return;
            }
        }
        revert("Badge not found for member and skill domain");
    }

    function getMemberSkillBadges(address _member) external view returns (mapping(string => string[]) memory) {
        return memberSkillBadges[_member];
    }


    // --- 4. Project Proposal & Funding ---
    function proposeProject(string memory _projectName, string memory _projectDescription, uint256 _fundingGoal, uint256 _milestoneCount, string[] memory _milestoneDescriptions) external onlyMember notPaused {
        require(bytes(_projectName).length > 0 && bytes(_projectDescription).length > 0, "Project name and description cannot be empty");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(_milestoneCount > 0 && _milestoneCount == _milestoneDescriptions.length, "Milestone count must be greater than zero and match descriptions");

        proposalCount++;
        ProjectProposal storage proposal = proposals[proposalCount];
        proposal.projectName = _projectName;
        proposal.projectDescription = _projectDescription;
        proposal.proposer = msg.sender;
        proposal.fundingGoal = _fundingGoal;
        proposal.milestoneCount = _milestoneCount;
        proposal.milestoneDescriptions = _milestoneDescriptions;
        proposal.votingEndTime = block.timestamp + votingDuration;

        for (uint256 i = 1; i <= _milestoneCount; i++) {
            proposal.milestones[i].description = _milestoneDescriptions[i-1];
        }

        emit ProjectProposed(proposalCount, _projectName, msg.sender, _fundingGoal);
    }

    function voteOnProjectProposal(uint256 _proposalId, bool _vote) external onlyMember notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        ProjectProposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        proposal.hasVoted[msg.sender] = true;

        // Voting power calculation - In this example, simplified to reputation + fixed token weight (can be more complex)
        uint256 votingPower = memberReputation[msg.sender] + 1; // Example: Reputation + token weight (simplified to 1 for token holding)
        if (reputationDelegation[msg.sender] != address(0)) {
            votingPower = memberReputation[reputationDelegation[msg.sender]] + 1; // Delegatee's reputation if delegated
        }

        if (_vote) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        emit VoteCastOnProposal(_proposalId, msg.sender, _vote);

        // Check if voting period ended and quorum is reached after vote cast
        if (block.timestamp >= proposal.votingEndTime) {
            _executeProjectProposal(_proposalId);
        }
    }


    function _executeProjectProposal(uint256 _proposalId) private proposalExists(_proposalId) {
        ProjectProposal storage proposal = proposals[_proposalId];
        if (proposal.proposalExecuted || proposal.proposalCancelled) return; // Prevent re-execution

        if (proposal.votesFor * 100 >= (proposal.votesFor + proposal.votesAgainst) * quorumPercentage) {
            proposal.proposalPassed = true;
            proposal.proposalExecuted = true;
            // Project is approved - further actions (like funding) can be triggered separately or automatically
        } else {
            proposal.proposalPassed = false;
            proposal.proposalExecuted = true; // Mark as executed even if failed
        }
    }

    function fundProject(uint256 _proposalId) external onlyGovernance notPaused proposalExists(_proposalId) {
        ProjectProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalPassed, "Project proposal not approved");
        require(!proposal.proposalExecuted, "Project already funded"); // Double check
        require(address(this).balance >= proposal.fundingGoal, "Insufficient DAO treasury balance"); // Assumes ETH for simplicity - adjust for token

        // Transfer funds to project proposer (in real scenario, might be a multisig or project wallet)
        (bool success, ) = proposal.proposer.call{value: proposal.fundingGoal}("");
        require(success, "Project funding transfer failed");

        proposal.proposalExecuted = true; // Mark as executed after funding
        emit ProjectFunded(_proposalId, proposal.fundingGoal);
        emit TreasuryWithdrawal(proposal.proposer, proposal.fundingGoal);
    }

    function submitProjectMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex) external onlyMember notPaused proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestoneCompletionNotSubmitted(_proposalId, _milestoneIndex) onlyProposer(_proposalId) {
        ProjectProposal storage proposal = proposals[_proposalId];
        require(proposal.proposalPassed, "Project proposal not approved");
        require(_milestoneIndex == proposal.currentMilestone + 1, "Submit milestones in sequential order"); // Enforce sequential milestone submission

        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        milestone.completionSubmitted = true;
        milestone.completionVotingEndTime = block.timestamp + votingDuration;
        emit MilestoneCompletionSubmitted(_proposalId, _milestoneIndex);
    }

    function voteOnMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex, bool _vote) external onlyMember notPaused proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestoneCompletionActive(_proposalId, _milestoneIndex) {
        ProjectProposal storage proposal = proposals[_proposalId];
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        require(!milestone.hasVotedCompletion[msg.sender], "Already voted on this milestone completion");
        milestone.hasVotedCompletion[msg.sender] = true;

        // Voting power calculation - same as project proposal voting
        uint256 votingPower = memberReputation[msg.sender] + 1; // Example: Reputation + token weight (simplified to 1 for token holding)
        if (reputationDelegation[msg.sender] != address(0)) {
            votingPower = memberReputation[reputationDelegation[msg.sender]] + 1; // Delegatee's reputation if delegated
        }

        if (_vote) {
            milestone.completionVotesFor += votingPower;
        } else {
            milestone.completionVotesAgainst += votingPower;
        }
        emit VoteCastOnMilestoneCompletion(_proposalId, _milestoneIndex, msg.sender, _vote);

        // Check if voting period ended and quorum reached for milestone approval
        if (block.timestamp >= milestone.completionVotingEndTime) {
            _executeMilestoneCompletion(_proposalId, _milestoneIndex);
        }
    }

    function _executeMilestoneCompletion(uint256 _proposalId, uint256 _milestoneIndex) private proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestoneCompletionNotSubmitted(_proposalId, _milestoneIndex) { // Added check to prevent execution if not submitted
        ProjectProposal storage proposal = proposals[_proposalId];
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        if (milestone.completionApproved || milestone.fundsReleased > 0) return; // Prevent re-execution or double release

        if (milestone.completionVotesFor * 100 >= (milestone.completionVotesFor + milestone.completionVotesAgainst) * quorumPercentage) {
            milestone.completionApproved = true;
            _releaseMilestoneFundsInternal(_proposalId, _milestoneIndex);
            proposal.currentMilestone = _milestoneIndex; // Update current milestone to track progress
        } else {
            milestone.completionApproved = false;
        }
    }

    function releaseMilestoneFunds(uint256 _proposalId, uint256 _milestoneIndex) external onlyGovernance notPaused proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestoneFundsNotReleased(_proposalId, _milestoneIndex) {
        Milestone storage milestone = proposals[_proposalId].milestones[_milestoneIndex];
        require(milestone.completionApproved, "Milestone completion not approved");
        _releaseMilestoneFundsInternal(_proposalId, _milestoneIndex);
    }

    function _releaseMilestoneFundsInternal(uint256 _proposalId, uint256 _milestoneIndex) private proposalExists(_proposalId) milestoneExists(_proposalId, _milestoneIndex) milestoneFundsNotReleased(_proposalId, _milestoneIndex) {
        ProjectProposal storage proposal = proposals[_proposalId];
        Milestone storage milestone = proposal.milestones[_milestoneIndex];
        uint256 milestoneFunding = proposal.fundingGoal / proposal.milestoneCount; // Simple equal distribution per milestone

        require(address(this).balance >= milestoneFunding, "Insufficient DAO treasury balance for milestone"); // Assumes ETH

        (bool success, ) = proposal.proposer.call{value: milestoneFunding}("");
        require(success, "Milestone funding transfer failed");

        milestone.fundsReleased = milestoneFunding;
        emit MilestoneFundsReleased(_proposalId, _milestoneIndex, milestoneFunding);
        emit TreasuryWithdrawal(proposal.proposer, milestoneFunding);
    }


    function cancelProjectProposal(uint256 _proposalId) external onlyProposer notPaused proposalExists(_proposalId) proposalActive(_proposalId) {
        ProjectProposal storage proposal = proposals[_proposalId];
        proposal.proposalCancelled = true;
        emit ProjectProposalCancelled(_proposalId);
    }

    function abortProject(uint256 _proposalId) external onlyGovernance notPaused proposalExists(_proposalId) {
        ProjectProposal storage proposal = proposals[_proposalId];
        require(!proposal.proposalCancelled && !proposal.proposalExecuted, "Project already cancelled or executed");
        proposal.proposalCancelled = true; // Mark as cancelled by governance
        emit ProjectAborted(_proposalId);
    }


    // --- 5. Treasury Management (Simplified) ---
    function depositToTreasury() external payable notPaused { // Accepts ETH deposits for simplicity
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(address _recipient, uint256 _amount) external onlyGovernance notPaused {
        require(_recipient != address(0), "Recipient address cannot be zero");
        require(address(this).balance >= _amount, "Insufficient treasury balance"); // Assumes ETH

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury withdrawal failed");
        emit TreasuryWithdrawal(_recipient, _amount);
    }


    // --- 6. Emergency & Utility ---
    function getDAOInfo() external view returns (string memory, address, uint256, uint256, bool) {
        return (daoName, governanceToken, quorumPercentage, votingDuration, paused);
    }

    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ProjectProposal memory) {
        return proposals[_proposalId];
    }

    // Fallback function to receive ETH
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```