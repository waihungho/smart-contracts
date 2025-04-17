```solidity
/**
 * @title Decentralized Autonomous Organization for Idea Incubation (DAOII)
 * @author Gemini AI (Conceptual Smart Contract - Not for Production)
 * @dev This smart contract represents a DAO focused on incubating innovative ideas.
 * It includes advanced concepts such as skill-based member matching, staged idea funding,
 * reputation system, dynamic voting mechanisms, and decentralized dispute resolution.
 *
 * Outline and Function Summary:
 *
 * 1. **Membership Management:**
 *    - `joinDAO()`: Allow users to request membership in the DAO.
 *    - `approveMembership(address _member)`: Admin function to approve pending membership requests.
 *    - `rejectMembership(address _member)`: Admin function to reject pending membership requests.
 *    - `leaveDAO()`: Allow members to exit the DAO.
 *    - `assignRole(address _member, Role _role)`: Admin function to assign roles to members (e.g., Idea Curator, Fund Manager, Mentor).
 *    - `revokeRole(address _member, Role _role)`: Admin function to revoke roles from members.
 *
 * 2. **Idea Management:**
 *    - `submitIdea(string memory _title, string memory _description, string[] memory _requiredSkills)`: Members can submit new ideas with descriptions and required skills.
 *    - `voteOnIdea(uint256 _ideaId, bool _support)`: Members can vote on submitted ideas.
 *    - `getIdeaDetails(uint256 _ideaId)`: View function to retrieve detailed information about an idea.
 *    - `fundIdea(uint256 _ideaId, uint256 _amount)`: Members can contribute funds to support promising ideas.
 *    - `setIdeaStage(uint256 _ideaId, IdeaStage _stage)`: Admin/Curator function to update the stage of an idea (e.g., Idea, Proposal, Incubation, Active, Completed, Rejected).
 *    - `addIdeaMilestone(uint256 _ideaId, string memory _milestoneDescription, uint256 _fundingGoal)`: Idea creators/Curators can add milestones to track progress and funding.
 *    - `approveMilestone(uint256 _ideaId, uint256 _milestoneIndex)`: Members vote to approve completed milestones, releasing funds.
 *    - `rejectMilestone(uint256 _ideaId, uint256 _milestoneIndex)`: Members vote to reject milestones if not completed as expected.
 *    - `matchSkillsToIdea(uint256 _ideaId)`: Function to match DAO members' skills with the skills required for an idea.
 *
 * 3. **Skill Management:**
 *    - `addSkill(string memory _skillName)`: Admin function to add new skills to the DAO's skill registry.
 *    - `verifySkill(address _member, string memory _skillName)`: Members can verify skills of other members after assessment/collaboration.
 *    - `registerSkill(string memory _skillName)`: Members can register their skills in the DAO.
 *
 * 4. **Voting and Governance:**
 *    - `submitProposal(string memory _proposalDescription, bytes memory _calldata, address _targetContract)`: Members can submit general governance proposals to modify DAO parameters or execute contract functions.
 *    - `castVoteOnProposal(uint256 _proposalId, bool _support)`: Members can vote on governance proposals.
 *    - `executeProposal(uint256 _proposalId)`: If a proposal passes, execute the associated call data.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Admin function to set the default voting duration.
 *    - `setQuorumThreshold(uint256 _quorumPercentage)`: Admin function to set the quorum threshold for proposals to pass.
 *
 * 5. **Reputation and Rewards:**
 *    - `earnReputation(address _member, uint256 _reputationPoints)`: Admin/Curator function to award reputation points for contributions.
 *    - `burnReputation(address _member, uint256 _reputationPoints)`: Admin function to deduct reputation points.
 *    - `rewardContributor(address _member, uint256 _amount)`:  Function to reward members with tokens or ETH for significant contributions (governed by proposals).
 *
 * 6. **Dispute Resolution (Simplified):**
 *    - `raiseDispute(uint256 _ideaId, string memory _disputeReason)`: Members can raise disputes regarding idea progress or milestone completion.
 *    - `resolveDispute(uint256 _disputeId, DisputeResolution _resolution, string memory _resolutionDetails)`: Admin/Designated dispute resolvers can resolve disputes.
 *
 * 7. **Emergency Functions (For Security - Use with Caution):**
 *    - `pauseContract()`: Admin function to pause critical contract functions in case of emergency.
 *    - `emergencyWithdraw(address _recipient, uint256 _amount)`: Admin function for emergency withdrawal of funds (highly restricted and for exceptional cases).
 */
pragma solidity ^0.8.0;

contract DecentralizedIdeaIncubator {
    enum Role {
        MEMBER,
        ADMIN,
        IDEA_CURATOR,
        FUND_MANAGER,
        MENTOR // Example of other roles
    }

    enum IdeaStage {
        IDEA_SUBMITTED,
        PROPOSAL_PHASE,
        INCUBATION_PHASE,
        ACTIVE_PROJECT,
        COMPLETED,
        REJECTED
    }

    enum ProposalStatus {
        PENDING,
        ACTIVE,
        PASSED,
        REJECTED,
        EXECUTED
    }

    enum MilestoneStatus {
        PENDING,
        PROPOSED,
        APPROVED,
        REJECTED,
        FUNDED,
        COMPLETED
    }

    enum DisputeResolution {
        RESOLVED_IN_FAVOR_OF_IDEA_CREATOR,
        RESOLVED_IN_FAVOR_OF_DAO,
        PARTIAL_RESOLUTION
    }

    struct Idea {
        uint256 id;
        string title;
        string description;
        address creator;
        IdeaStage stage;
        uint256 fundingGoal;
        uint256 currentFunding;
        string[] requiredSkills;
        uint256 upvotes;
        uint256 downvotes;
        Milestone[] milestones;
        bool isActive; // Flag to indicate if the idea is currently being incubated/active
    }

    struct Milestone {
        uint256 index;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        MilestoneStatus status;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 votingDeadline;
        bool isFunded;
    }

    struct Member {
        address memberAddress;
        Role role;
        uint256 reputation;
        string[] skills;
        bool isApproved;
        bool isActiveMember;
    }

    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        ProposalStatus status;
        bytes calldataData;
        address targetContract;
        uint256 upvotes;
        uint256 downvotes;
        uint256 votingDeadline;
        uint256 quorumRequired;
    }

    struct Dispute {
        uint256 id;
        uint256 ideaId;
        address raisedBy;
        string reason;
        DisputeResolution resolution;
        string resolutionDetails;
        bool isResolved;
    }

    mapping(uint256 => Idea) public ideas;
    uint256 public ideaCount;
    mapping(address => Member) public members;
    address[] public pendingMembers;
    mapping(string => bool) public registeredSkills;
    string[] public skillList;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    mapping(uint256 => Dispute) public disputes;
    uint256 public disputeCount;
    address public admin;
    uint256 public votingDurationBlocks = 100; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage

    bool public contractPaused = false;

    event MembershipRequested(address memberAddress);
    event MembershipApproved(address memberAddress);
    event MembershipRejected(address memberAddress);
    event MemberLeft(address memberAddress);
    event RoleAssigned(address memberAddress, Role role);
    event RoleRevoked(address memberAddress, Role role);

    event IdeaSubmitted(uint256 ideaId, address creator, string title);
    event VoteCastOnIdea(uint256 ideaId, address voter, bool support);
    event IdeaStageUpdated(uint256 ideaId, IdeaStage newStage);
    event IdeaFunded(uint256 ideaId, uint256 amount, uint256 totalFunding);
    event IdeaMilestoneAdded(uint256 ideaId, uint256 milestoneIndex, string description);
    event MilestoneApproved(uint256 ideaId, uint256 milestoneIndex);
    event MilestoneRejected(uint256 ideaId, uint256 milestoneIndex);

    event SkillRegistered(string skillName);
    event SkillVerified(address memberAddress, string skillName);

    event ProposalSubmitted(uint256 proposalId, address proposer, string description);
    event VoteCastOnProposal(uint256 proposalId, address voter, bool support);
    event ProposalExecuted(uint256 proposalId);
    event VotingDurationSet(uint256 durationInBlocks);
    event QuorumThresholdSet(uint256 quorumPercentage);

    event ReputationEarned(address memberAddress, uint256 reputationPoints);
    event ReputationBurned(address memberAddress, uint256 reputationPoints);
    event ContributorRewarded(address memberAddress, uint256 amount);

    event DisputeRaised(uint256 disputeId, uint256 ideaId, address raisedBy, string reason);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution, string resolutionDetails);

    event ContractPaused();
    event ContractUnpaused();
    event EmergencyWithdrawal(address recipient, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender].isActiveMember, "Only members can call this function.");
        _;
    }

    modifier ideaExists(uint256 _ideaId) {
        require(_ideaId > 0 && _ideaId <= ideaCount, "Idea does not exist.");
        _;
    }

    modifier memberExists(address _member) {
        require(members[_member].memberAddress != address(0), "Member does not exist.");
        _;
    }

    modifier skillExists(string memory _skillName) {
        require(registeredSkills[_skillName], "Skill not registered.");
        _;
    }

    modifier notPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // -------------------- Membership Management --------------------

    function joinDAO() external notPaused {
        require(members[msg.sender].memberAddress == address(0), "Already a member or membership requested.");
        pendingMembers.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(!members[_member].isActiveMember && members[_member].memberAddress == address(0), "Member already approved or not requested.");
        bool found = false;
        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] == _member) {
                found = true;
                pendingMembers[i] = pendingMembers[pendingMembers.length - 1];
                pendingMembers.pop();
                break;
            }
        }
        require(found, "Member not found in pending list.");

        members[_member] = Member({
            memberAddress: _member,
            role: Role.MEMBER,
            reputation: 0,
            skills: new string[](0),
            isApproved: true,
            isActiveMember: true
        });
        emit MembershipApproved(_member);
    }

    function rejectMembership(address _member) external onlyAdmin notPaused {
        require(!members[_member].isActiveMember && members[_member].memberAddress == address(0), "Member already approved or not requested.");
        bool found = false;
        for (uint256 i = 0; i < pendingMembers.length; i++) {
            if (pendingMembers[i] == _member) {
                found = true;
                pendingMembers[i] = pendingMembers[pendingMembers.length - 1];
                pendingMembers.pop();
                break;
            }
        }
        require(found, "Member not found in pending list.");
        emit MembershipRejected(_member);
    }

    function leaveDAO() external onlyMember notPaused {
        members[msg.sender].isActiveMember = false;
        emit MemberLeft(msg.sender);
    }

    function assignRole(address _member, Role _role) external onlyAdmin notPaused memberExists(_member) {
        members[_member].role = _role;
        emit RoleAssigned(_member, _role);
    }

    function revokeRole(address _member, Role _role) external onlyAdmin notPaused memberExists(_member) {
        require(members[_member].role == _role, "Member does not have this role.");
        members[_member].role = Role.MEMBER; // Default to MEMBER role
        emit RoleRevoked(_member, _role);
    }

    // -------------------- Idea Management --------------------

    function submitIdea(string memory _title, string memory _description, string[] memory _requiredSkills) external onlyMember notPaused {
        ideaCount++;
        ideas[ideaCount] = Idea({
            id: ideaCount,
            title: _title,
            description: _description,
            creator: msg.sender,
            stage: IdeaStage.IDEA_SUBMITTED,
            fundingGoal: 0, // Can be set later or in a proposal
            currentFunding: 0,
            requiredSkills: _requiredSkills,
            upvotes: 0,
            downvotes: 0,
            milestones: new Milestone[](0),
            isActive: false
        });
        emit IdeaSubmitted(ideaCount, msg.sender, _title);
    }

    function voteOnIdea(uint256 _ideaId, bool _support) external onlyMember notPaused ideaExists(_ideaId) {
        require(ideas[_ideaId].stage == IdeaStage.IDEA_SUBMITTED || ideas[_ideaId].stage == IdeaStage.PROPOSAL_PHASE, "Voting only allowed in Idea Submission or Proposal Phase.");
        if (_support) {
            ideas[_ideaId].upvotes++;
        } else {
            ideas[_ideaId].downvotes++;
        }
        emit VoteCastOnIdea(_ideaId, msg.sender, _support);
        // Add logic for automatic stage change based on votes if desired (e.g., move to Proposal Phase if upvotes exceed a threshold)
    }

    function getIdeaDetails(uint256 _ideaId) external view ideaExists(_ideaId) returns (Idea memory) {
        return ideas[_ideaId];
    }

    function fundIdea(uint256 _ideaId) external payable notPaused ideaExists(_ideaId) {
        require(ideas[_ideaId].stage == IdeaStage.INCUBATION_PHASE || ideas[_ideaId].stage == IdeaStage.ACTIVE_PROJECT, "Funding only allowed in Incubation or Active Project Phase.");
        ideas[_ideaId].currentFunding += msg.value;
        emit IdeaFunded(_ideaId, msg.value, ideas[_ideaId].currentFunding);
    }

    function setIdeaStage(uint256 _ideaId, IdeaStage _stage) external onlyAdmin notPaused ideaExists(_ideaId) {
        ideas[_ideaId].stage = _stage;
        emit IdeaStageUpdated(_ideaId, _stage);
    }

    function addIdeaMilestone(uint256 _ideaId, string memory _milestoneDescription, uint256 _fundingGoal) external onlyMember notPaused ideaExists(_ideaId) {
        require(ideas[_ideaId].creator == msg.sender || members[msg.sender].role == Role.IDEA_CURATOR, "Only idea creator or curator can add milestones.");
        require(ideas[_ideaId].stage == IdeaStage.INCUBATION_PHASE || ideas[_ideaId].stage == IdeaStage.ACTIVE_PROJECT, "Milestones can only be added in Incubation or Active Project Phase.");
        ideas[_ideaId].milestones.push(Milestone({
            index: ideas[_ideaId].milestones.length,
            description: _milestoneDescription,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            status: MilestoneStatus.PROPOSED,
            approvalVotes: 0,
            rejectionVotes: 0,
            votingDeadline: block.number + votingDurationBlocks,
            isFunded: false
        }));
        emit IdeaMilestoneAdded(_ideaId, ideas[_ideaId].milestones.length - 1, _milestoneDescription);
    }

    function approveMilestone(uint256 _ideaId, uint256 _milestoneIndex) external onlyMember notPaused ideaExists(_ideaId) {
        Milestone storage milestone = ideas[_ideaId].milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.PROPOSED, "Milestone is not in proposed state.");
        require(block.number < milestone.votingDeadline, "Voting deadline for milestone passed.");

        milestone.approvalVotes++;
        // Simple majority, can be made more sophisticated with quorum
        if (milestone.approvalVotes > (getMemberCount() / 2)) {
            milestone.status = MilestoneStatus.APPROVED;
            emit MilestoneApproved(_ideaId, _milestoneIndex);
        }
    }

    function rejectMilestone(uint256 _ideaId, uint256 _milestoneIndex) external onlyMember notPaused ideaExists(_ideaId) {
        Milestone storage milestone = ideas[_ideaId].milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.PROPOSED, "Milestone is not in proposed state.");
        require(block.number < milestone.votingDeadline, "Voting deadline for milestone passed.");

        milestone.rejectionVotes++;
        // Simple rejection logic, can be refined
        if (milestone.rejectionVotes > (getMemberCount() / 2)) {
            milestone.status = MilestoneStatus.REJECTED;
            emit MilestoneRejected(_ideaId, _milestoneIndex);
        }
    }

    function fundMilestone(uint256 _ideaId, uint256 _milestoneIndex) external onlyAdmin notPaused ideaExists(_ideaId) {
        Milestone storage milestone = ideas[_ideaId].milestones[_milestoneIndex];
        require(milestone.status == MilestoneStatus.APPROVED, "Milestone must be approved to be funded.");
        require(!milestone.isFunded, "Milestone already funded.");
        require(ideas[_ideaId].currentFunding >= milestone.fundingGoal, "Idea does not have enough funds for this milestone.");

        payable(ideas[_ideaId].creator).transfer(milestone.fundingGoal);
        ideas[_ideaId].currentFunding -= milestone.fundingGoal;
        milestone.currentFunding = milestone.fundingGoal;
        milestone.status = MilestoneStatus.FUNDED;
        milestone.isFunded = true;
    }

    function matchSkillsToIdea(uint256 _ideaId) external view ideaExists(_ideaId) returns (address[] memory matchedMembers) {
        string[] memory requiredSkills = ideas[_ideaId].requiredSkills;
        address[] memory matches = new address[](0);
        uint256 matchCount = 0;

        for (uint256 i = 0; i < skillList.length; i++) {
            for (uint256 j = 0; j < requiredSkills.length; j++) {
                if (keccak256(bytes(skillList[i])) == keccak256(bytes(requiredSkills[j]))) {
                    for (address memberAddress : getMemberList()) {
                        Member storage member = members[memberAddress];
                        for (uint256 k = 0; k < member.skills.length; k++) {
                            if (keccak256(bytes(member.skills[k])) == keccak256(bytes(skillList[i]))) {
                                // Check if already added to avoid duplicates
                                bool alreadyAdded = false;
                                for (uint256 l = 0; l < matches.length; l++) {
                                    if (matches[l] == memberAddress) {
                                        alreadyAdded = true;
                                        break;
                                    }
                                }
                                if (!alreadyAdded) {
                                    matches.push(memberAddress);
                                    matchCount++;
                                }
                                break; // Move to next member's skill
                            }
                        }
                    }
                    break; // Move to next required skill
                }
            }
        }
        return matches;
    }


    // -------------------- Skill Management --------------------

    function addSkill(string memory _skillName) external onlyAdmin notPaused {
        require(!registeredSkills[_skillName], "Skill already registered.");
        registeredSkills[_skillName] = true;
        skillList.push(_skillName);
        emit SkillRegistered(_skillName);
    }

    function verifySkill(address _member, string memory _skillName) external onlyMember notPaused memberExists(_member) skillExists(_skillName) {
        bool skillExistsInMember = false;
        for (uint256 i = 0; i < members[_member].skills.length; i++) {
            if (keccak256(bytes(members[_member].skills[i])) == keccak256(bytes(_skillName))) {
                skillExistsInMember = true;
                break;
            }
        }
        require(!skillExistsInMember, "Skill already verified for member.");

        members[_member].skills.push(_skillName);
        emit SkillVerified(_member, _skillName);
    }

    function registerSkill(string memory _skillName) external onlyMember notPaused skillExists(_skillName) {
        bool skillExistsInMember = false;
        for (uint256 i = 0; i < members[msg.sender].skills.length; i++) {
            if (keccak256(bytes(members[msg.sender].skills[i])) == keccak256(bytes(_skillName))) {
                skillExistsInMember = true;
                break;
            }
        }
        require(!skillExistsInMember, "Skill already registered for you.");
        members[msg.sender].skills.push(_skillName);
    }


    // -------------------- Voting and Governance --------------------

    function submitProposal(string memory _proposalDescription, bytes memory _calldata, address _targetContract) external onlyMember notPaused {
        proposalCount++;
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            description: _proposalDescription,
            proposer: msg.sender,
            status: ProposalStatus.PENDING,
            calldataData: _calldata,
            targetContract: _targetContract,
            upvotes: 0,
            downvotes: 0,
            votingDeadline: block.number + votingDurationBlocks,
            quorumRequired: quorumPercentage
        });
        emit ProposalSubmitted(proposalCount, msg.sender, _proposalDescription);
    }

    function castVoteOnProposal(uint256 _proposalId, bool _support) external onlyMember notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.PENDING, "Proposal is not pending.");
        require(block.number < proposal.votingDeadline, "Voting deadline for proposal passed.");

        if (_support) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit VoteCastOnProposal(_proposalId, msg.sender, _support);

        if (block.number >= proposal.votingDeadline) {
            _finalizeProposal(_proposalId);
        }
    }

    function _finalizeProposal(uint256 _proposalId) private {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.PENDING) return; // Avoid re-finalization

        uint256 totalMembers = getMemberCount();
        uint256 quorum = (totalMembers * proposal.quorumRequired) / 100;

        if (proposal.upvotes >= quorum && proposal.upvotes > proposal.downvotes) {
            proposal.status = ProposalStatus.PASSED;
        } else {
            proposal.status = ProposalStatus.REJECTED;
        }
        proposal.status = ProposalStatus.ACTIVE; // Move to active status for execution
    }


    function executeProposal(uint256 _proposalId) external onlyAdmin notPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal must be active to execute.");
        proposal.status = ProposalStatus.EXECUTED; // Mark as executed before call to prevent reentrancy issues if target calls back

        (bool success, ) = proposal.targetContract.call(proposal.calldataData);
        require(success, "Proposal execution failed.");
        emit ProposalExecuted(_proposalId);
    }

    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin notPaused {
        votingDurationBlocks = _durationInBlocks;
        emit VotingDurationSet(_durationInBlocks);
    }

    function setQuorumThreshold(uint256 _quorumPercentage) external onlyAdmin notPaused {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _quorumPercentage;
        emit QuorumThresholdSet(_quorumPercentage);
    }

    // -------------------- Reputation and Rewards --------------------

    function earnReputation(address _member, uint256 _reputationPoints) external onlyAdmin notPaused memberExists(_member) {
        members[_member].reputation += _reputationPoints;
        emit ReputationEarned(_member, _reputationPoints);
    }

    function burnReputation(address _member, uint256 _reputationPoints) external onlyAdmin notPaused memberExists(_member) {
        require(members[_member].reputation >= _reputationPoints, "Not enough reputation points to burn.");
        members[_member].reputation -= _reputationPoints;
        emit ReputationBurned(_member, _reputationPoints);
    }

    function rewardContributor(address _member, uint256 _amount) external onlyAdmin notPaused memberExists(_member) {
        payable(_member).transfer(_amount);
        emit ContributorRewarded(_member, _amount);
    }


    // -------------------- Dispute Resolution --------------------

    function raiseDispute(uint256 _ideaId, string memory _disputeReason) external onlyMember notPaused ideaExists(_ideaId) {
        disputeCount++;
        disputes[disputeCount] = Dispute({
            id: disputeCount,
            ideaId: _ideaId,
            raisedBy: msg.sender,
            reason: _disputeReason,
            resolution: DisputeResolution.PARTIAL_RESOLUTION, // Default value
            resolutionDetails: "",
            isResolved: false
        });
        emit DisputeRaised(disputeCount, _ideaId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution, string memory _resolutionDetails) external onlyAdmin notPaused {
        require(!disputes[_disputeId].isResolved, "Dispute already resolved.");
        disputes[_disputeId].resolution = _resolution;
        disputes[_disputeId].resolutionDetails = _resolutionDetails;
        disputes[_disputeId].isResolved = true;
        emit DisputeResolved(_disputeId, _resolution, _resolutionDetails);
    }


    // -------------------- Emergency Functions --------------------

    function pauseContract() external onlyAdmin notPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyAdmin {
        contractPaused = false;
        emit ContractUnpaused();
    }

    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyAdmin notPaused {
        require(address(this).balance >= _amount, "Contract balance is less than withdrawal amount.");
        payable(_recipient).transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount);
    }

    // -------------------- Utility Functions --------------------
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory memberAddresses = getMemberList();
        for(uint256 i = 0; i < memberAddresses.length; i++){
            if(members[memberAddresses[i]].isActiveMember){
                count++;
            }
        }
        return count;
    }

    function getMemberList() public view returns (address[] memory) {
        address[] memory memberAddresses = new address[](0);
        uint256 index = 0;
        for (uint256 i = 0; i < skillList.length; i++) { // Iterate through skill list as a way to iterate through all members (not ideal in a real-world scenario, consider a separate member list)
            for (address memberAddress : getMembersWithSkill(skillList[i])){
                bool alreadyAdded = false;
                for(uint256 j=0; j< memberAddresses.length; j++){
                    if(memberAddresses[j] == memberAddress){
                        alreadyAdded = true;
                        break;
                    }
                }
                if(!alreadyAdded){
                    address[] memory temp = new address[](memberAddresses.length + 1);
                    for(uint256 k=0; k< memberAddresses.length; k++){
                        temp[k] = memberAddresses[k];
                    }
                    temp[memberAddresses.length] = memberAddress;
                    memberAddresses = temp;
                }
            }
        }
        return memberAddresses;
    }

    function getMembersWithSkill(string memory _skillName) public view skillExists(_skillName) returns (address[] memory) {
        address[] memory membersWithSkill = new address[](0);
        for (uint256 i = 0; i < skillList.length; i++) { // Iterate through skill list as a way to iterate through all members (not ideal, consider a separate member list)
            for (address memberAddress : getMemberList()) {
                Member storage member = members[memberAddress];
                for (uint256 j = 0; j < member.skills.length; j++) {
                    if (keccak256(bytes(member.skills[j])) == keccak256(bytes(_skillName))) {
                        bool alreadyAdded = false;
                        for (uint256 k = 0; k < membersWithSkill.length; k++) {
                            if (membersWithSkill[k] == memberAddress) {
                                alreadyAdded = true;
                                break;
                            }
                        }
                        if (!alreadyAdded) {
                            address[] memory temp = new address[](membersWithSkill.length + 1);
                            for (uint256 l = 0; l < membersWithSkill.length; l++) {
                                temp[l] = membersWithSkill[l];
                            }
                            temp[membersWithSkill.length] = memberAddress;
                            membersWithSkill = temp;
                        }
                        break;
                    }
                }
            }
        }
        return membersWithSkill;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```