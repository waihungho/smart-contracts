```solidity
/**
 * @title Decentralized Idea Incubation Platform (DIIP)
 * @author Gemini AI Model
 * @dev A smart contract for a Decentralized Autonomous Organization (DAO) focused on idea incubation,
 *      leveraging advanced concepts like dynamic voting, skill-based mentorship, milestone-based funding,
 *      and reputation scoring to foster innovation and community-driven project development.
 *
 * Function Summary:
 *
 * **Idea Submission & Management:**
 * 1. submitIdea(string memory _title, string memory _description, string memory _category, uint256 _fundingGoal, string[] memory _milestones): Allows users to submit new project ideas.
 * 2. updateIdeaDetails(uint256 _ideaId, string memory _title, string memory _description, string memory _category, uint256 _fundingGoal, string[] memory _milestones): Allows idea creators to update their idea details before voting starts.
 * 3. getIdeaDetails(uint256 _ideaId): Retrieves detailed information about a specific idea.
 * 4. getAllIdeaIds(): Returns a list of all idea IDs in the platform.
 * 5. getIdeasByCategory(string memory _category): Returns a list of idea IDs belonging to a specific category.
 * 6. getIdeasByStatus(IdeaStatus _status): Returns a list of idea IDs with a specific status.
 * 7. setIdeaStatus(uint256 _ideaId, IdeaStatus _newStatus): Admin function to manually set the status of an idea (e.g., for edge cases).
 *
 * **Voting & Governance:**
 * 8. startVoting(uint256 _ideaId, uint256 _votingDuration): Starts the voting process for a submitted idea.
 * 9. voteForIdea(uint256 _ideaId): Allows registered members to vote in favor of an idea.
 * 10. voteAgainstIdea(uint256 _ideaId): Allows registered members to vote against an idea.
 * 11. tallyVotes(uint256 _ideaId): Calculates and finalizes the voting results for an idea.
 * 12. getVotingStatus(uint256 _ideaId): Retrieves the current voting status and details for an idea.
 * 13. setVotingQuorum(uint256 _newQuorumPercentage): Admin function to change the voting quorum percentage.
 *
 * **Funding & Milestones:**
 * 14. contributeToIdea(uint256 _ideaId) payable: Allows users to contribute funds to an approved idea.
 * 15. requestMilestoneCompletion(uint256 _ideaId, uint256 _milestoneIndex): Idea creator requests approval for milestone completion.
 * 16. approveMilestone(uint256 _ideaId, uint256 _milestoneIndex): Mentors or community members with sufficient reputation can approve a milestone.
 * 17. withdrawMilestoneFunds(uint256 _ideaId, uint256 _milestoneIndex): Idea creator can withdraw funds after milestone approval.
 * 18. getIdeaFundingStatus(uint256 _ideaId): Retrieves the funding status of an idea.
 *
 * **Mentorship & Reputation:**
 * 19. applyForMentorship(string memory _expertise): Users can apply to become mentors, specifying their expertise.
 * 20. assignMentorToIdea(uint256 _ideaId, address _mentorAddress): Admin or qualified community members can assign mentors to ideas.
 * 21. endorseMentor(address _mentorAddress): Registered members can endorse mentors to increase their reputation.
 * 22. getMentorReputation(address _mentorAddress): Retrieves the reputation score of a mentor.
 * 23. getMentorsByExpertise(string memory _expertise): Returns a list of mentor addresses with specific expertise.
 *
 * **Admin & Configuration:**
 * 24. addAdmin(address _newAdmin): Adds a new admin address.
 * 25. removeAdmin(address _adminToRemove): Removes an admin address.
 * 26. pauseContract(): Pauses core contract functionalities.
 * 27. unpauseContract(): Resumes contract functionalities.
 * 28. registerMember(): Allows users to register as members of the platform.
 * 29. isRegisteredMember(address _user): Checks if an address is a registered member.
 */
pragma solidity ^0.8.0;

contract DecentralizedIdeaIncubationPlatform {
    // -------- State Variables --------

    enum IdeaStatus { Submitted, Voting, Approved, Funding, InProgress, Completed, Rejected }
    enum VotingStatus { NotStarted, Active, Ended }

    struct Idea {
        uint256 ideaId;
        address creator;
        string title;
        string description;
        string category;
        IdeaStatus status;
        uint256 fundingGoal;
        uint256 currentFunding;
        string[] milestones;
        uint256 votesFor;
        uint256 votesAgainst;
        VotingStatus votingStatus;
        uint256 votingEndTime;
        address[] mentors;
        mapping(uint256 => MilestoneStatus) milestoneStatuses; // Milestone index to status
    }

    enum MilestoneStatus { PendingRequest, Approved, Rejected, Completed }

    struct Mentor {
        address mentorAddress;
        string expertise;
        uint256 reputationScore;
        bool isApproved;
    }

    uint256 public ideaCounter;
    mapping(uint256 => Idea) public ideas;
    mapping(address => Mentor) public mentors;
    mapping(address => bool) public registeredMembers;
    address[] public admins;
    uint256 public votingQuorumPercentage = 51; // Default quorum: 51%
    uint256 public defaultVotingDuration = 7 days; // Default voting duration: 7 days
    bool public contractPaused = false;

    // -------- Events --------

    event IdeaSubmitted(uint256 ideaId, address creator, string title);
    event IdeaUpdated(uint256 ideaId, string title);
    event VotingStarted(uint256 ideaId, uint256 votingDuration);
    event VoteCast(uint256 ideaId, address voter, bool voteFor);
    event VotingEnded(uint256 ideaId, IdeaStatus finalStatus, uint256 votesFor, uint256 votesAgainst);
    event IdeaApproved(uint256 ideaId);
    event IdeaRejected(uint256 ideaId);
    event FundingContributed(uint256 ideaId, address contributor, uint256 amount);
    event MilestoneRequested(uint256 ideaId, uint256 milestoneIndex);
    event MilestoneApproved(uint256 ideaId, uint256 milestoneIndex);
    event MilestoneFundsWithdrawn(uint256 ideaId, uint256 milestoneIndex, uint256 amount);
    event MentorApplied(address mentorAddress, string expertise);
    event MentorAssigned(uint256 ideaId, address mentorAddress);
    event MentorEndorsed(address mentorAddress, address endorser);
    event AdminAdded(address adminAddress);
    event AdminRemoved(address adminAddress);
    event ContractPaused();
    event ContractUnpaused();
    event MemberRegistered(address memberAddress);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "Only admins can perform this action.");
        _;
    }

    modifier onlyRegisteredMember() {
        require(registeredMembers[msg.sender], "Only registered members can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }

    modifier ideaExists(uint256 _ideaId) {
        require(ideas[_ideaId].ideaId == _ideaId, "Idea does not exist.");
        _;
    }

    modifier ideaInStatus(uint256 _ideaId, IdeaStatus _status) {
        require(ideas[_ideaId].status == _status, "Idea is not in the required status.");
        _;
    }

    modifier votingActive(uint256 _ideaId) {
        require(ideas[_ideaId].votingStatus == VotingStatus.Active, "Voting is not active for this idea.");
        require(block.timestamp <= ideas[_ideaId].votingEndTime, "Voting period has ended.");
        _;
    }

    modifier votingNotStarted(uint256 _ideaId) {
        require(ideas[_ideaId].votingStatus == VotingStatus.NotStarted, "Voting has already started.");
        _;
    }

    modifier votingEnded(uint256 _ideaId) {
        require(ideas[_ideaId].votingStatus == VotingStatus.Ended, "Voting has not ended yet.");
        _;
    }

    modifier isIdeaCreator(uint256 _ideaId) {
        require(ideas[_ideaId].creator == msg.sender, "You are not the creator of this idea.");
        _;
    }

    // -------- Functions --------

    constructor() {
        admins.push(msg.sender); // Deployer is the initial admin
    }

    // -------- Idea Submission & Management --------

    /// @notice Allows users to submit new project ideas.
    /// @param _title The title of the idea.
    /// @param _description A detailed description of the idea.
    /// @param _category The category of the idea (e.g., DeFi, NFT, Infrastructure).
    /// @param _fundingGoal The funding goal for the idea in Wei.
    /// @param _milestones An array of milestones for the project.
    function submitIdea(
        string memory _title,
        string memory _description,
        string memory _category,
        uint256 _fundingGoal,
        string[] memory _milestones
    ) external onlyRegisteredMember whenNotPaused {
        ideaCounter++;
        ideas[ideaCounter] = Idea({
            ideaId: ideaCounter,
            creator: msg.sender,
            title: _title,
            description: _description,
            category: _category,
            status: IdeaStatus.Submitted,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            milestones: _milestones,
            votesFor: 0,
            votesAgainst: 0,
            votingStatus: VotingStatus.NotStarted,
            votingEndTime: 0,
            mentors: new address[](0), // Initialize empty mentors array
            milestoneStatuses: mapping(uint256 => MilestoneStatus)() // Initialize empty milestoneStatuses mapping
        });

        emit IdeaSubmitted(ideaCounter, msg.sender, _title);
    }

    /// @notice Allows idea creators to update their idea details before voting starts.
    /// @param _ideaId The ID of the idea to update.
    /// @param _title The new title of the idea.
    /// @param _description The new description of the idea.
    /// @param _category The new category of the idea.
    /// @param _fundingGoal The new funding goal for the idea in Wei.
    /// @param _milestones The new array of milestones for the project.
    function updateIdeaDetails(
        uint256 _ideaId,
        string memory _title,
        string memory _description,
        string memory _category,
        uint256 _fundingGoal,
        string[] memory _milestones
    ) external ideaExists(_ideaId) isIdeaCreator(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Submitted) whenNotPaused {
        ideas[_ideaId].title = _title;
        ideas[_ideaId].description = _description;
        ideas[_ideaId].category = _category;
        ideas[_ideaId].fundingGoal = _fundingGoal;
        ideas[_ideaId].milestones = _milestones;
        emit IdeaUpdated(_ideaId, _title);
    }

    /// @notice Retrieves detailed information about a specific idea.
    /// @param _ideaId The ID of the idea.
    /// @return Idea struct containing idea details.
    function getIdeaDetails(uint256 _ideaId) external view ideaExists(_ideaId) returns (Idea memory) {
        return ideas[_ideaId];
    }

    /// @notice Returns a list of all idea IDs in the platform.
    /// @return An array of idea IDs.
    function getAllIdeaIds() external view returns (uint256[] memory) {
        uint256[] memory allIdeaIds = new uint256[](ideaCounter);
        for (uint256 i = 1; i <= ideaCounter; i++) {
            allIdeaIds[i - 1] = i;
        }
        return allIdeaIds;
    }

    /// @notice Returns a list of idea IDs belonging to a specific category.
    /// @param _category The category to filter by.
    /// @return An array of idea IDs in the specified category.
    function getIdeasByCategory(string memory _category) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= ideaCounter; i++) {
            if (keccak256(bytes(ideas[i].category)) == keccak256(bytes(_category))) {
                count++;
            }
        }
        uint256[] memory categoryIdeaIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= ideaCounter; i++) {
            if (keccak256(bytes(ideas[i].category)) == keccak256(bytes(_category))) {
                categoryIdeaIds[index] = i;
                index++;
            }
        }
        return categoryIdeaIds;
    }

    /// @notice Returns a list of idea IDs with a specific status.
    /// @param _status The IdeaStatus to filter by.
    /// @return An array of idea IDs with the specified status.
    function getIdeasByStatus(IdeaStatus _status) external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 1; i <= ideaCounter; i++) {
            if (ideas[i].status == _status) {
                count++;
            }
        }
        uint256[] memory statusIdeaIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 1; i <= ideaCounter; i++) {
            if (ideas[i].status == _status) {
                statusIdeaIds[index] = i;
                index++;
            }
        }
        return statusIdeaIds;
    }

    /// @notice Admin function to manually set the status of an idea (e.g., for edge cases).
    /// @param _ideaId The ID of the idea to update.
    /// @param _newStatus The new IdeaStatus to set.
    function setIdeaStatus(uint256 _ideaId, IdeaStatus _newStatus) external onlyAdmin ideaExists(_ideaId) whenNotPaused {
        ideas[_ideaId].status = _newStatus;
    }

    // -------- Voting & Governance --------

    /// @notice Starts the voting process for a submitted idea.
    /// @param _ideaId The ID of the idea to start voting for.
    /// @param _votingDuration The duration of the voting period in seconds.
    function startVoting(uint256 _ideaId, uint256 _votingDuration) external onlyAdmin ideaExists(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Submitted) votingNotStarted(_ideaId) whenNotPaused {
        ideas[_ideaId].status = IdeaStatus.Voting;
        ideas[_ideaId].votingStatus = VotingStatus.Active;
        ideas[_ideaId].votingEndTime = block.timestamp + _votingDuration;
        emit VotingStarted(_ideaId, _votingDuration);
    }

    /// @notice Starts the voting process for a submitted idea with default duration.
    /// @param _ideaId The ID of the idea to start voting for.
    function startVoting(uint256 _ideaId) external onlyAdmin ideaExists(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Submitted) votingNotStarted(_ideaId) whenNotPaused {
        startVoting(_ideaId, defaultVotingDuration);
    }

    /// @notice Allows registered members to vote in favor of an idea.
    /// @param _ideaId The ID of the idea to vote for.
    function voteForIdea(uint256 _ideaId) external onlyRegisteredMember ideaExists(_ideaId) votingActive(_ideaId) whenNotPaused {
        // Prevent double voting (simple implementation, can be improved with mapping for individual voters per idea)
        require(!hasVoted(msg.sender, _ideaId), "You have already voted for this idea.");
        ideas[_ideaId].votesFor++;
        markVoted(msg.sender, _ideaId); // Mark voter as voted
        emit VoteCast(_ideaId, msg.sender, true);
    }

    /// @notice Allows registered members to vote against an idea.
    /// @param _ideaId The ID of the idea to vote against.
    function voteAgainstIdea(uint256 _ideaId) external onlyRegisteredMember ideaExists(_ideaId) votingActive(_ideaId) whenNotPaused {
        // Prevent double voting (simple implementation, can be improved with mapping for individual voters per idea)
        require(!hasVoted(msg.sender, _ideaId), "You have already voted for this idea.");
        ideas[_ideaId].votesAgainst++;
        markVoted(msg.sender, _ideaId); // Mark voter as voted
        emit VoteCast(_ideaId, msg.sender, false);
    }

    // Simple double voting prevention using a global mapping (can be improved for scalability)
    mapping(address => mapping(uint256 => bool)) public hasVotedMap;

    function hasVoted(address _voter, uint256 _ideaId) internal view returns (bool) {
        return hasVotedMap[_voter][_ideaId];
    }

    function markVoted(address _voter, uint256 _ideaId) internal {
        hasVotedMap[_voter][_ideaId][_voter] = true; // Using voter address as a simple unique key
    }


    /// @notice Calculates and finalizes the voting results for an idea.
    /// @param _ideaId The ID of the idea to tally votes for.
    function tallyVotes(uint256 _ideaId) external onlyAdmin ideaExists(_ideaId) votingActive(_ideaId) whenNotPaused {
        require(block.timestamp > ideas[_ideaId].votingEndTime, "Voting period has not ended yet.");
        ideas[_ideaId].votingStatus = VotingStatus.Ended;

        uint256 totalVotes = ideas[_ideaId].votesFor + ideas[_ideaId].votesAgainst;
        uint256 quorumVotesNeeded = (totalVotes * votingQuorumPercentage) / 100;

        if (ideas[_ideaId].votesFor > ideas[_ideaId].votesAgainst && ideas[_ideaId].votesFor >= quorumVotesNeeded) {
            ideas[_ideaId].status = IdeaStatus.Approved;
            emit IdeaApproved(_ideaId);
            emit VotingEnded(_ideaId, IdeaStatus.Approved, ideas[_ideaId].votesFor, ideas[_ideaId].votesAgainst);
        } else {
            ideas[_ideaId].status = IdeaStatus.Rejected;
            emit IdeaRejected(_ideaId);
            emit VotingEnded(_ideaId, IdeaStatus.Rejected, ideas[_ideaId].votesFor, ideas[_ideaId].votesAgainst);
        }
    }

    /// @notice Retrieves the current voting status and details for an idea.
    /// @param _ideaId The ID of the idea.
    /// @return VotingStatus enum and voting end time.
    function getVotingStatus(uint256 _ideaId) external view ideaExists(_ideaId) returns (VotingStatus, uint256) {
        return (ideas[_ideaId].votingStatus, ideas[_ideaId].votingEndTime);
    }

    /// @notice Admin function to change the voting quorum percentage.
    /// @param _newQuorumPercentage The new quorum percentage (e.g., 51 for 51%).
    function setVotingQuorum(uint256 _newQuorumPercentage) external onlyAdmin whenNotPaused {
        require(_newQuorumPercentage <= 100, "Quorum percentage cannot exceed 100.");
        votingQuorumPercentage = _newQuorumPercentage;
    }

    // -------- Funding & Milestones --------

    /// @notice Allows users to contribute funds to an approved idea.
    /// @param _ideaId The ID of the idea to contribute to.
    function contributeToIdea(uint256 _ideaId) external payable ideaExists(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Approved) whenNotPaused {
        ideas[_ideaId].currentFunding += msg.value;
        emit FundingContributed(_ideaId, msg.sender, msg.value);
        if (ideas[_ideaId].currentFunding >= ideas[_ideaId].fundingGoal) {
            ideas[_ideaId].status = IdeaStatus.Funding; // Move to Funding status once goal is reached
        }
    }

    /// @notice Idea creator requests approval for milestone completion.
    /// @param _ideaId The ID of the idea.
    /// @param _milestoneIndex The index of the milestone to request completion for (0-indexed).
    function requestMilestoneCompletion(uint256 _ideaId, uint256 _milestoneIndex) external ideaExists(_ideaId) isIdeaCreator(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Funding) whenNotPaused {
        require(_milestoneIndex < ideas[_ideaId].milestones.length, "Invalid milestone index.");
        require(ideas[_ideaId].milestoneStatuses[_milestoneIndex] == MilestoneStatus.PendingRequest || ideas[_ideaId].milestoneStatuses[_milestoneIndex] == MilestoneStatus.Rejected, "Milestone completion already requested or approved/completed."); // Allow re-request after rejection
        ideas[_ideaId].milestoneStatuses[_milestoneIndex] = MilestoneStatus.PendingRequest;
        emit MilestoneRequested(_ideaId, _milestoneIndex);
    }

    /// @notice Mentors or community members with sufficient reputation can approve a milestone.
    /// @param _ideaId The ID of the idea.
    /// @param _milestoneIndex The index of the milestone to approve.
    function approveMilestone(uint256 _ideaId, uint256 _milestoneIndex) external ideaExists(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Funding) whenNotPaused {
        require(_milestoneIndex < ideas[_ideaId].milestones.length, "Invalid milestone index.");
        require(ideas[_ideaId].milestoneStatuses[_milestoneIndex] == MilestoneStatus.PendingRequest, "Milestone completion not requested or already approved/completed.");
        // Add logic for mentor/reputation based approval here if needed in future iterations.
        // For now, any registered member can approve (for simplicity in this example).
        require(registeredMembers[msg.sender], "Only registered members can approve milestones (for now)."); // Basic access control

        ideas[_ideaId].milestoneStatuses[_milestoneIndex] = MilestoneStatus.Approved;
        emit MilestoneApproved(_ideaId, _milestoneIndex);
    }

    /// @notice Idea creator can withdraw funds after milestone approval.
    /// @param _ideaId The ID of the idea.
    /// @param _milestoneIndex The index of the milestone to withdraw funds for.
    function withdrawMilestoneFunds(uint256 _ideaId, uint256 _milestoneIndex) external ideaExists(_ideaId) isIdeaCreator(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Funding) whenNotPaused {
        require(_milestoneIndex < ideas[_ideaId].milestones.length, "Invalid milestone index.");
        require(ideas[_ideaId].milestoneStatuses[_milestoneIndex] == MilestoneStatus.Approved, "Milestone not approved yet.");
        require(ideas[_ideaId].milestoneStatuses[_milestoneIndex] != MilestoneStatus.Completed, "Milestone funds already withdrawn.");

        // Calculate funds to withdraw (simple equal distribution per milestone for now)
        uint256 fundsPerMilestone = ideas[_ideaId].fundingGoal / ideas[_ideaId].milestones.length;
        uint256 withdrawAmount = fundsPerMilestone;

        // Ensure enough funds are available (important check)
        require(address(this).balance >= withdrawAmount, "Contract balance is insufficient for withdrawal.");
        require(ideas[_ideaId].currentFunding >= withdrawAmount, "Idea funding is insufficient for withdrawal.");

        ideas[_ideaId].currentFunding -= withdrawAmount; // Reduce idea's current funding
        ideas[_ideaId].milestoneStatuses[_milestoneIndex] = MilestoneStatus.Completed; // Mark milestone as completed
        payable(ideas[_ideaId].creator).transfer(withdrawAmount); // Transfer funds to creator

        emit MilestoneFundsWithdrawn(_ideaId, _milestoneIndex, withdrawAmount);

        // Check if all milestones are completed, then mark idea as InProgress or Completed
        bool allMilestonesCompleted = true;
        for (uint256 i = 0; i < ideas[_ideaId].milestones.length; i++) {
            if (ideas[_ideaId].milestoneStatuses[i] != MilestoneStatus.Completed) {
                allMilestonesCompleted = false;
                break;
            }
        }

        if (allMilestonesCompleted) {
            ideas[_ideaId].status = IdeaStatus.Completed; // Mark idea as Completed
        } else {
            ideas[_ideaId].status = IdeaStatus.InProgress; // Mark idea as InProgress
        }
    }

    /// @notice Retrieves the funding status of an idea.
    /// @param _ideaId The ID of the idea.
    /// @return Funding goal and current funding amount.
    function getIdeaFundingStatus(uint256 _ideaId) external view ideaExists(_ideaId) returns (uint256, uint256) {
        return (ideas[_ideaId].fundingGoal, ideas[_ideaId].currentFunding);
    }

    // -------- Mentorship & Reputation --------

    /// @notice Users can apply to become mentors, specifying their expertise.
    /// @param _expertise A string describing the mentor's expertise.
    function applyForMentorship(string memory _expertise) external onlyRegisteredMember whenNotPaused {
        require(!mentors[msg.sender].isApproved, "You are already a mentor or have applied."); // Prevent re-application if already approved or applied
        mentors[msg.sender] = Mentor({
            mentorAddress: msg.sender,
            expertise: _expertise,
            reputationScore: 0,
            isApproved: false // Initially not approved, admin needs to approve
        });
        emit MentorApplied(msg.sender, _expertise);
    }

    /// @notice Admin or qualified community members can assign mentors to ideas.
    /// @param _ideaId The ID of the idea.
    /// @param _mentorAddress The address of the mentor to assign.
    function assignMentorToIdea(uint256 _ideaId, address _mentorAddress) external onlyAdmin ideaExists(_ideaId) ideaInStatus(_ideaId, IdeaStatus.Funding) whenNotPaused {
        require(mentors[_mentorAddress].isApproved, "Mentor is not approved."); // Ensure mentor is approved
        // Optional: Check if mentor expertise matches idea category or needs

        ideas[_ideaId].mentors.push(_mentorAddress);
        emit MentorAssigned(_ideaId, _mentorAddress);
    }

    /// @notice Registered members can endorse mentors to increase their reputation.
    /// @param _mentorAddress The address of the mentor to endorse.
    function endorseMentor(address _mentorAddress) external onlyRegisteredMember whenNotPaused {
        require(mentors[_mentorAddress].mentorAddress == _mentorAddress, "Mentor address is invalid or mentor has not applied.");
        mentors[_mentorAddress].reputationScore++; // Simple reputation increase
        emit MentorEndorsed(_mentorAddress, msg.sender);
    }

    /// @notice Retrieves the reputation score of a mentor.
    /// @param _mentorAddress The address of the mentor.
    /// @return The reputation score of the mentor.
    function getMentorReputation(address _mentorAddress) external view returns (uint256) {
        return mentors[_mentorAddress].reputationScore;
    }

    /// @notice Returns a list of mentor addresses with specific expertise.
    /// @param _expertise The expertise to filter by.
    /// @return An array of mentor addresses with the specified expertise.
    function getMentorsByExpertise(string memory _expertise) external view returns (address[] memory) {
        uint256 count = 0;
        address[] memory mentorAddresses = new address[](ideaCounter); // Max possible mentors is ideaCounter (overestimation is fine for view func)
        uint256 index = 0;
        for (uint256 i = 1; i <= ideaCounter; i++) { // Iterate through ideaCounter as a proxy to check all potential mentors (not efficient for very large scale, needs optimization for real-world)
            if (mentors[address(uint160(i))].mentorAddress != address(0) && // Check if mentor struct exists (address(0) is default)
                mentors[address(uint160(i))].isApproved && // Check if mentor is approved
                keccak256(bytes(mentors[address(uint160(i))].expertise)) == keccak256(bytes(_expertise)) // Compare expertise
            ) {
                mentorAddresses[index] = mentors[address(uint160(i))].mentorAddress;
                index++;
                count++;
            }
        }
        // Resize array to actual count
        address[] memory resultMentors = new address[](count);
        for(uint256 i = 0; i < count; i++) {
            resultMentors[i] = mentorAddresses[i];
        }
        return resultMentors;
    }


    // -------- Admin & Configuration --------

    /// @notice Adds a new admin address.
    /// @param _newAdmin The address to add as admin.
    function addAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        for (uint256 i = 0; i < admins.length; i++) {
            require(admins[i] != _newAdmin, "Address is already an admin.");
        }
        admins.push(_newAdmin);
        emit AdminAdded(_newAdmin);
    }

    /// @notice Removes an admin address.
    /// @param _adminToRemove The address to remove from admins.
    function removeAdmin(address _adminToRemove) external onlyAdmin whenNotPaused {
        require(_adminToRemove != msg.sender, "Cannot remove yourself as admin."); // Prevent removing self
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _adminToRemove) {
                // Remove admin from array (shift elements)
                for (uint256 j = i; j < admins.length - 1; j++) {
                    admins[j] = admins[j + 1];
                }
                admins.pop();
                emit AdminRemoved(_adminToRemove);
                return;
            }
        }
        revert("Admin address not found.");
    }

    /// @notice Pauses core contract functionalities.
    function pauseContract() external onlyAdmin whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Resumes contract functionalities.
    function unpauseContract() external onlyAdmin whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows users to register as members of the platform.
    function registerMember() external whenNotPaused {
        require(!registeredMembers[msg.sender], "Already registered member.");
        registeredMembers[msg.sender] = true;
        emit MemberRegistered(msg.sender);
    }

    /// @notice Checks if an address is a registered member.
    /// @param _user The address to check.
    /// @return True if the address is a registered member, false otherwise.
    function isRegisteredMember(address _user) external view returns (bool) {
        return registeredMembers[_user];
    }

    // -------- Fallback and Receive (Optional for this contract, but good practice) --------

    receive() external payable {} // To receive ETH for contributions

    fallback() external {} // In case of non-matching function calls
}
```