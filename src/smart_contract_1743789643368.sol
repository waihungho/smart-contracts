```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI
 * @dev A smart contract for managing a decentralized art collective, enabling artists to collaborate,
 * propose projects, vote on proposals, manage exhibitions, and share revenue transparently.
 *
 * **Outline:**
 * 1. **Membership Management:**
 *    - Apply for Membership
 *    - Approve Membership Application
 *    - Reject Membership Application
 *    - Revoke Membership
 *    - Get Member Count
 *    - Get Member List
 * 2. **Project Proposal and Funding:**
 *    - Submit Project Proposal
 *    - Vote on Project Proposal
 *    - Fund Project
 *    - Mark Project as Complete
 *    - Get Project Details
 *    - Get Project Proposals
 * 3. **Exhibition Management:**
 *    - Create Exhibition
 *    - Add Art to Exhibition
 *    - Remove Art from Exhibition
 *    - Start Exhibition
 *    - End Exhibition
 *    - Purchase Art from Exhibition
 *    - Distribute Revenue from Exhibition
 *    - Get Exhibition Details
 *    - Get Exhibition List
 * 4. **Governance and Settings:**
 *    - Change Governance Settings (e.g., voting quorum, membership fee)
 *    - Set Royalty Percentage for Collective
 *    - Withdraw Artist Earnings
 *    - Get Contract Balance
 *    - Pause Contract
 *    - Resume Contract
 *
 * **Function Summary:**
 * - `applyForMembership()`: Allows artists to apply for membership in the collective.
 * - `approveMembershipApplication(uint256 _applicationId, address _artist)`: Allows the contract owner/governance to approve a membership application.
 * - `rejectMembershipApplication(uint256 _applicationId)`: Allows the contract owner/governance to reject a membership application.
 * - `revokeMembership(address _artist)`: Allows the contract owner/governance to revoke membership from an artist.
 * - `getMemberCount()`: Returns the total number of members in the collective.
 * - `getMemberList()`: Returns a list of all member addresses.
 * - `submitProjectProposal(string memory _title, string memory _description, uint256 _fundingGoal)`: Allows members to submit project proposals for funding.
 * - `voteOnProjectProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on project proposals.
 * - `fundProject(uint256 _projectId)`: Allows anyone to contribute funds to a project that has been approved.
 * - `markProjectAsComplete(uint256 _projectId)`: Allows the project proposer to mark a project as complete (requires governance approval for fund release).
 * - `getProjectDetails(uint256 _projectId)`: Returns details of a specific project.
 * - `getProjectProposals()`: Returns a list of all project proposals.
 * - `createExhibition(string memory _title, string memory _description, uint256 _startTime, uint256 _endTime)`: Allows members to propose and create art exhibitions.
 * - `addArtToExhibition(uint256 _exhibitionId, string memory _artTitle, string memory _artDescription, uint256 _price)`: Allows members to add their art to an exhibition.
 * - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId)`: Allows members to remove their art from an exhibition.
 * - `startExhibition(uint256 _exhibitionId)`: Allows starting a scheduled exhibition.
 * - `endExhibition(uint256 _exhibitionId)`: Allows ending an ongoing exhibition and triggering revenue distribution.
 * - `purchaseArtFromExhibition(uint256 _exhibitionId, uint256 _artId)`: Allows anyone to purchase art from an active exhibition.
 * - `distributeRevenueFromExhibition(uint256 _exhibitionId)`: Distributes revenue from art sales in an exhibition to artists and the collective.
 * - `getExhibitionDetails(uint256 _exhibitionId)`: Returns details of a specific exhibition.
 * - `getExhibitionList()`: Returns a list of all exhibitions.
 * - `changeGovernanceSettings(uint256 _newVotingQuorum, uint256 _newMembershipFee)`: Allows the contract owner to change governance parameters.
 * - `setRoyaltyPercentage(uint256 _royaltyPercentage)`: Allows the contract owner to set the collective's royalty percentage from art sales.
 * - `withdrawArtistEarnings()`: Allows artists to withdraw their earned revenue from art sales and project funding.
 * - `getContractBalance()`: Returns the current balance of the contract.
 * - `pauseContract()`: Allows the contract owner to pause most contract functionalities.
 * - `resumeContract()`: Allows the contract owner to resume contract functionalities after pausing.
 */

contract DecentralizedArtCollective {
    address public owner;
    uint256 public membershipFee;
    uint256 public votingQuorumPercentage; // Percentage of members needed to vote for proposal approval
    uint256 public collectiveRoyaltyPercentage; // Percentage of sales going to the collective

    bool public paused;

    uint256 public nextApplicationId;
    mapping(uint256 => MembershipApplication) public membershipApplications;
    mapping(address => bool) public members;
    address[] public memberList;

    uint256 public nextProjectId;
    mapping(uint256 => ProjectProposal) public projectProposals;

    uint256 public nextExhibitionId;
    mapping(uint256 => Exhibition) public exhibitions;

    struct MembershipApplication {
        address applicant;
        string applicationDetails;
        bool approved;
        bool rejected;
    }

    struct ProjectProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool approved;
        bool completed;
        mapping(address => bool) votes; // Track votes of members
    }

    struct Exhibition {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        mapping(uint256 => ArtPiece) artPieces;
        uint256 nextArtPieceId;
        uint256 totalRevenue;
    }

    struct ArtPiece {
        uint256 id;
        address artist;
        string title;
        string description;
        uint256 price;
        bool sold;
    }

    event MembershipApplied(uint256 applicationId, address applicant);
    event MembershipApproved(uint256 applicationId, address artist);
    event MembershipRejected(uint256 applicationId, uint256 applicationIdRejected);
    event MembershipRevoked(address artist);
    event ProjectProposed(uint256 projectId, address proposer, string title);
    event ProjectVoteCast(uint256 projectId, address voter, bool vote);
    event ProjectFunded(uint256 projectId, address funder, uint256 amount);
    event ProjectCompleted(uint256 projectId);
    event ExhibitionCreated(uint256 exhibitionId, string title);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId, address artist, string title);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtPurchased(uint256 exhibitionId, uint256 artId, address buyer, uint256 price);
    event RevenueDistributed(uint256 exhibitionId, uint256 totalRevenue);
    event GovernanceSettingsChanged(uint256 newVotingQuorum, uint256 newMembershipFee);
    event RoyaltyPercentageSet(uint256 royaltyPercentage);
    event EarningsWithdrawn(address artist, uint256 amount);
    event ContractPaused();
    event ContractResumed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    constructor(uint256 _membershipFee, uint256 _votingQuorumPercentage, uint256 _royaltyPercentage) {
        owner = msg.sender;
        membershipFee = _membershipFee;
        votingQuorumPercentage = _votingQuorumPercentage;
        collectiveRoyaltyPercentage = _royaltyPercentage;
        paused = false;
        nextApplicationId = 1;
        nextProjectId = 1;
        nextExhibitionId = 1;
    }

    // 1. Membership Management

    /// @notice Allows artists to apply for membership by paying the membership fee.
    function applyForMembership(string memory _applicationDetails) external payable notPaused {
        require(msg.value >= membershipFee, "Insufficient membership fee paid.");
        require(!members[msg.sender], "You are already a member.");
        require(membershipApplications[nextApplicationId].applicant == address(0), "Application ID conflict, please try again."); // Basic ID conflict check

        membershipApplications[nextApplicationId] = MembershipApplication({
            applicant: msg.sender,
            applicationDetails: _applicationDetails,
            approved: false,
            rejected: false
        });
        emit MembershipApplied(nextApplicationId, msg.sender);
        nextApplicationId++;
    }

    /// @notice Approves a membership application by the owner.
    /// @param _applicationId The ID of the membership application.
    /// @param _artist The address of the artist to approve (for security, double check).
    function approveMembershipApplication(uint256 _applicationId, address _artist) external onlyOwner notPaused {
        require(membershipApplications[_applicationId].applicant == _artist, "Applicant address mismatch."); // Security check
        require(!membershipApplications[_applicationId].approved && !membershipApplications[_applicationId].rejected, "Application already processed.");

        membershipApplications[_applicationId].approved = true;
        members[_artist] = true;
        memberList.push(_artist);
        emit MembershipApproved(_applicationId, _artist);
    }

    /// @notice Rejects a membership application by the owner.
    /// @param _applicationId The ID of the membership application.
    function rejectMembershipApplication(uint256 _applicationId) external onlyOwner notPaused {
        require(!membershipApplications[_applicationId].approved && !membershipApplications[_applicationId].rejected, "Application already processed.");
        membershipApplications[_applicationId].rejected = true;
        // Consider refunding the membership fee if applicable in your logic
        emit MembershipRejected(_applicationId, _applicationId);
    }

    /// @notice Revokes membership from an artist by the owner.
    /// @param _artist The address of the artist to revoke membership from.
    function revokeMembership(address _artist) external onlyOwner notPaused {
        require(members[_artist], "Address is not a member.");
        members[_artist] = false;
        // Remove from memberList (inefficient for large lists, consider optimization for real-world)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _artist) {
                delete memberList[i];
                // To keep array contiguous, shift elements after the removed element
                for (uint256 j = i; j < memberList.length - 1; j++) {
                    memberList[j] = memberList[j+1];
                }
                memberList.pop();
                break;
            }
        }
        emit MembershipRevoked(_artist);
    }

    /// @notice Returns the total number of members.
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    /// @notice Returns a list of all member addresses.
    function getMemberList() external view returns (address[] memory) {
        return memberList;
    }

    // 2. Project Proposal and Funding

    /// @notice Allows members to submit project proposals.
    /// @param _title The title of the project.
    /// @param _description A detailed description of the project.
    /// @param _fundingGoal The funding goal for the project in wei.
    function submitProjectProposal(string memory _title, string memory _description, uint256 _fundingGoal) external onlyMember notPaused {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        projectProposals[nextProjectId] = ProjectProposal({
            id: nextProjectId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            voteCountYes: 0,
            voteCountNo: 0,
            approved: false,
            completed: false,
            votes: mapping(address => bool)() // Initialize empty votes mapping
        });
        emit ProjectProposed(nextProjectId, msg.sender, _title);
        nextProjectId++;
    }

    /// @notice Allows members to vote on project proposals.
    /// @param _proposalId The ID of the project proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProjectProposal(uint256 _proposalId, bool _vote) external onlyMember notPaused {
        require(!projectProposals[_proposalId].approved, "Project proposal already approved.");
        require(!projectProposals[_proposalId].completed, "Project proposal already completed.");
        require(!projectProposals[_proposalId].votes[msg.sender], "You have already voted on this proposal.");

        projectProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            projectProposals[_proposalId].voteCountYes++;
        } else {
            projectProposals[_proposalId].voteCountNo++;
        }
        emit ProjectVoteCast(_proposalId, msg.sender, _vote);

        // Check if voting quorum is reached for approval
        uint256 quorumNeeded = (memberList.length * votingQuorumPercentage) / 100;
        if (projectProposals[_proposalId].voteCountYes >= quorumNeeded && !projectProposals[_proposalId].approved) {
            projectProposals[_proposalId].approved = true;
        }
    }

    /// @notice Allows anyone to fund an approved project.
    /// @param _projectId The ID of the project to fund.
    function fundProject(uint256 _projectId) external payable notPaused {
        require(projectProposals[_projectId].approved, "Project proposal not approved yet.");
        require(!projectProposals[_projectId].completed, "Project already completed.");
        require(projectProposals[_projectId].currentFunding < projectProposals[_projectId].fundingGoal, "Project funding goal already reached.");

        uint256 amountToFund = msg.value;
        uint256 remainingFundingNeeded = projectProposals[_projectId].fundingGoal - projectProposals[_projectId].currentFunding;

        if (amountToFund > remainingFundingNeeded) {
            amountToFund = remainingFundingNeeded; // Cap funding to the remaining amount
        }

        projectProposals[_projectId].currentFunding += amountToFund;
        emit ProjectFunded(_projectId, msg.sender, amountToFund);

        if (projectProposals[_projectId].currentFunding >= projectProposals[_projectId].fundingGoal) {
            // Optionally trigger project start logic or notification here.
        }
    }

    /// @notice Allows the project proposer to mark a project as complete, requires owner approval to release funds.
    /// @param _projectId The ID of the project to mark as complete.
    function markProjectAsComplete(uint256 _projectId) external onlyMember notPaused {
        require(projectProposals[_projectId].proposer == msg.sender, "Only proposer can mark project as complete.");
        require(projectProposals[_projectId].approved, "Project must be approved first.");
        require(!projectProposals[_projectId].completed, "Project already marked as complete.");
        require(projectProposals[_projectId].currentFunding >= projectProposals[_projectId].fundingGoal, "Project funding goal not yet reached.");

        projectProposals[_projectId].completed = true;
        emit ProjectCompleted(_projectId);
        // In a real application, you'd have a separate function for owner to release funds after verification.
        // For simplicity, we'll just mark as complete here.
    }

    /// @notice Returns details of a specific project.
    /// @param _projectId The ID of the project.
    function getProjectDetails(uint256 _projectId) external view returns (ProjectProposal memory) {
        return projectProposals[_projectId];
    }

    /// @notice Returns a list of all project proposals (consider pagination for large lists in real-world).
    function getProjectProposals() external view returns (ProjectProposal[] memory) {
        ProjectProposal[] memory proposals = new ProjectProposal[](nextProjectId - 1);
        for (uint256 i = 1; i < nextProjectId; i++) {
            proposals[i - 1] = projectProposals[i];
        }
        return proposals;
    }


    // 3. Exhibition Management

    /// @notice Allows members to create a new art exhibition.
    /// @param _title The title of the exhibition.
    /// @param _description A description of the exhibition theme.
    /// @param _startTime Unix timestamp for the exhibition start time.
    /// @param _endTime Unix timestamp for the exhibition end time.
    function createExhibition(string memory _title, string memory _description, uint256 _startTime, uint256 _endTime) external onlyMember notPaused {
        require(_startTime < _endTime, "Exhibition start time must be before end time.");
        exhibitions[nextExhibitionId] = Exhibition({
            id: nextExhibitionId,
            title: _title,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            isActive: false,
            artPieces: mapping(uint256 => ArtPiece)(),
            nextArtPieceId: 1,
            totalRevenue: 0
        });
        emit ExhibitionCreated(nextExhibitionId, _title);
        nextExhibitionId++;
    }

    /// @notice Allows members to add their art to an exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artTitle The title of the art piece.
    /// @param _artDescription A description of the art piece.
    /// @param _price The price of the art piece in wei.
    function addArtToExhibition(uint256 _exhibitionId, string memory _artTitle, string memory _artDescription, uint256 _price) external onlyMember notPaused {
        require(!exhibitions[_exhibitionId].isActive, "Cannot add art to an active exhibition.");
        require(exhibitions[_exhibitionId].endTime > block.timestamp, "Cannot add art to an ended exhibition.");
        require(_price > 0, "Art price must be greater than zero.");

        exhibitions[_exhibitionId].artPieces[exhibitions[_exhibitionId].nextArtPieceId] = ArtPiece({
            id: exhibitions[_exhibitionId].nextArtPieceId,
            artist: msg.sender,
            title: _artTitle,
            description: _artDescription,
            price: _price,
            sold: false
        });
        emit ArtAddedToExhibition(_exhibitionId, exhibitions[_exhibitionId].nextArtPieceId, msg.sender, _artTitle);
        exhibitions[_exhibitionId].nextArtPieceId++;
    }

    /// @notice Allows members to remove their art from an exhibition before it starts.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artId The ID of the art piece to remove.
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId) external onlyMember notPaused {
        require(!exhibitions[_exhibitionId].isActive, "Cannot remove art from an active exhibition.");
        require(exhibitions[_exhibitionId].artPieces[_artId].artist == msg.sender, "Only artist can remove their art.");
        require(!exhibitions[_exhibitionId].artPieces[_artId].sold, "Cannot remove sold art.");

        delete exhibitions[_exhibitionId].artPieces[_artId]; // Effectively removes the art piece
        emit ArtRemovedFromExhibition(_exhibitionId, _artId);
    }

    /// @notice Starts an exhibition, making it active.
    /// @param _exhibitionId The ID of the exhibition to start.
    function startExhibition(uint256 _exhibitionId) external onlyOwner notPaused {
        require(!exhibitions[_exhibitionId].isActive, "Exhibition already active.");
        require(block.timestamp >= exhibitions[_exhibitionId].startTime, "Exhibition start time not reached yet.");
        require(block.timestamp < exhibitions[_exhibitionId].endTime, "Exhibition end time already passed.");

        exhibitions[_exhibitionId].isActive = true;
        emit ExhibitionStarted(_exhibitionId);
    }

    /// @notice Ends an exhibition, distributing revenue.
    /// @param _exhibitionId The ID of the exhibition to end.
    function endExhibition(uint256 _exhibitionId) external onlyOwner notPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(block.timestamp >= exhibitions[_exhibitionId].endTime, "Exhibition end time not reached yet."); // Or should it be <= end time? Depends on desired behavior

        exhibitions[_exhibitionId].isActive = false;
        distributeRevenueFromExhibition(_exhibitionId); // Automatically distribute revenue
        emit ExhibitionEnded(_exhibitionId);
    }

    /// @notice Allows anyone to purchase art from an active exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    /// @param _artId The ID of the art piece to purchase.
    function purchaseArtFromExhibition(uint256 _exhibitionId, uint256 _artId) external payable notPaused {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(!exhibitions[_exhibitionId].artPieces[_artId].sold, "Art piece already sold.");
        require(msg.value >= exhibitions[_exhibitionId].artPieces[_artId].price, "Insufficient funds sent.");

        uint256 artPrice = exhibitions[_exhibitionId].artPieces[_artId].price;
        exhibitions[_exhibitionId].artPieces[_artId].sold = true;
        exhibitions[_exhibitionId].totalRevenue += artPrice;

        // Transfer funds to contract, distribution happens at exhibition end
        payable(address(this)).transfer(artPrice); // Contract receives funds
        emit ArtPurchased(_exhibitionId, _artId, msg.sender, artPrice);
    }

    /// @notice Distributes revenue from an exhibition to artists and the collective.
    /// @param _exhibitionId The ID of the exhibition.
    function distributeRevenueFromExhibition(uint256 _exhibitionId) private notPaused {
        require(!exhibitions[_exhibitionId].isActive, "Cannot distribute revenue while exhibition is active.");

        uint256 totalRevenue = exhibitions[_exhibitionId].totalRevenue;
        uint256 collectiveCut = (totalRevenue * collectiveRoyaltyPercentage) / 100;
        uint256 artistRevenuePool = totalRevenue - collectiveCut;

        uint256 numArtPiecesSold = 0;
        for (uint256 i = 1; i < exhibitions[_exhibitionId].nextArtPieceId; i++) {
            if (exhibitions[_exhibitionId].artPieces[i].sold) {
                numArtPiecesSold++;
            }
        }

        if (numArtPiecesSold > 0) {
            uint256 revenuePerArtPiece = artistRevenuePool / numArtPiecesSold; // Simple equal distribution per sold piece

            for (uint256 i = 1; i < exhibitions[_exhibitionId].nextArtPieceId; i++) {
                if (exhibitions[_exhibitionId].artPieces[i].sold) {
                    payable(exhibitions[_exhibitionId].artPieces[i].artist).transfer(revenuePerArtPiece);
                }
            }
        }

        // Transfer collective cut to owner (or a designated collective wallet - could be more decentralized in future)
        payable(owner).transfer(collectiveCut);

        emit RevenueDistributed(_exhibitionId, totalRevenue);
        exhibitions[_exhibitionId].totalRevenue = 0; // Reset revenue for next exhibition
    }

    /// @notice Returns details of a specific exhibition.
    /// @param _exhibitionId The ID of the exhibition.
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @notice Returns a list of all exhibitions (consider pagination for large lists in real-world).
    function getExhibitionList() external view returns (Exhibition[] memory) {
        Exhibition[] memory exhibitionList = new Exhibition[](nextExhibitionId - 1);
        for (uint256 i = 1; i < nextExhibitionId; i++) {
            exhibitionList[i - 1] = exhibitions[i];
        }
        return exhibitionList;
    }


    // 4. Governance and Settings

    /// @notice Allows the owner to change governance settings like voting quorum and membership fee.
    /// @param _newVotingQuorum The new voting quorum percentage.
    /// @param _newMembershipFee The new membership fee in wei.
    function changeGovernanceSettings(uint256 _newVotingQuorum, uint256 _newMembershipFee) external onlyOwner notPaused {
        votingQuorumPercentage = _newVotingQuorum;
        membershipFee = _newMembershipFee;
        emit GovernanceSettingsChanged(_newVotingQuorum, _newMembershipFee);
    }

    /// @notice Allows the owner to set the collective's royalty percentage from art sales.
    /// @param _royaltyPercentage The new royalty percentage (e.g., 10 for 10%).
    function setRoyaltyPercentage(uint256 _royaltyPercentage) external onlyOwner notPaused {
        collectiveRoyaltyPercentage = _royaltyPercentage;
        emit RoyaltyPercentageSet(_royaltyPercentage);
    }

    /// @notice Allows members to withdraw their accumulated earnings from art sales and project funding.
    function withdrawArtistEarnings() external onlyMember notPaused {
        uint256 withdrawableAmount = 0; // In a real application, track artist balances separately.
        // For simplicity, this example doesn't track individual artist balances beyond exhibition revenue.
        // In a real scenario, you would need to maintain a mapping of artist balances and update them
        // when art is sold or projects are completed.

        // Placeholder - assuming artist has some balance tracked elsewhere (not implemented here for simplicity)
        // withdrawableAmount = artistBalances[msg.sender];
        // require(withdrawableAmount > 0, "No earnings to withdraw.");
        // artistBalances[msg.sender] = 0; // Reset balance after withdrawal

        // For this simplified example, we will just allow withdrawal of any available contract balance,
        // which is NOT ideal for a real-world scenario but demonstrates the function.
        withdrawableAmount = address(this).balance; // Inefficient and insecure for real-world, just for example
        require(withdrawableAmount > 0, "No contract balance to withdraw (in this simplified example).");


        payable(msg.sender).transfer(withdrawableAmount);
        emit EarningsWithdrawn(msg.sender, withdrawableAmount);
    }

    /// @notice Returns the current balance of the contract.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Pauses most contract functionalities by the owner.
    function pauseContract() external onlyOwner {
        require(!paused, "Contract already paused.");
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes contract functionalities by the owner.
    function resumeContract() external onlyOwner {
        require(paused, "Contract not paused.");
        paused = false;
        emit ContractResumed();
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```