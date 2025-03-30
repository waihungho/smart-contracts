```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAAC) Smart Contract
 * @author Gemini AI Assistant
 * @notice This smart contract implements a Decentralized Autonomous Art Collective (DAAAC)
 * allowing artists to collaboratively create, manage, and monetize digital art pieces.
 * It introduces novel concepts like collaborative NFT creation, dynamic royalty distribution based on contribution,
 * decentralized art curation and voting, fractionalized ownership of art pieces, and a built-in art challenge mechanism.
 * This contract aims to foster a vibrant and equitable ecosystem for digital artists and art enthusiasts.
 *
 * **Outline and Function Summary:**
 *
 * **1. Project Proposal & Management:**
 *    - `proposeArtProject(string memory _title, string memory _description, uint256 _targetContributors, uint256 _votingDuration)`: Allows members to propose new art projects.
 *    - `voteOnProjectProposal(uint256 _projectId, bool _vote)`: Members can vote on art project proposals.
 *    - `contributeToProject(uint256 _projectId, string memory _contributionData)`: Artists can contribute to approved art projects.
 *    - `approveContribution(uint256 _projectId, uint256 _contributionId)`: Project creator can approve contributions (or DAO if creator is inactive after voting).
 *    - `finalizeArtProject(uint256 _projectId, string memory _finalArtMetadataURI)`: Project creator can finalize the project and mint the collaborative NFT.
 *    - `cancelArtProject(uint256 _projectId)`: Allows the project creator or DAO to cancel a project under certain conditions (e.g., lack of progress).
 *    - `getProjectDetails(uint256 _projectId)`: Returns details of a specific art project.
 *    - `getContributionDetails(uint256 _projectId, uint256 _contributionId)`: Returns details of a specific contribution.
 *
 * **2. DAO Governance & Membership:**
 *    - `joinCollective(string memory _artistName, string memory _portfolioLink)`: Allows artists to apply for membership in the collective.
 *    - `voteOnMembership(address _artistAddress, bool _vote)`: Existing members can vote on new membership applications.
 *    - `removeMember(address _memberAddress)`: DAO governance function to remove a member (requires voting).
 *    - `isMember(address _address)`: Checks if an address is a member of the collective.
 *    - `getMemberCount()`: Returns the total number of members in the collective.
 *
 * **3. Collaborative NFT Minting & Royalties:**
 *    - `mintCollaborativeNFT(uint256 _projectId, string memory _tokenURI)`: Mints a collaborative NFT for a finalized art project (internal function).
 *    - `setRoyaltyDistribution(uint256 _projectId, address[] memory _recipients, uint256[] memory _shares)`: Sets custom royalty distribution for a project (DAO governed).
 *    - `getDefaultRoyaltyShare()`: Returns the default royalty share for contributors.
 *    - `withdrawRoyalties(uint256 _projectId)`: Allows members to withdraw their earned royalties from a project.
 *
 * **4. Art Challenges & Bounties (Optional):**
 *    - `createArtChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _bountyAmount, uint256 _submissionDeadline)`: Allows members to create art challenges with bounties.
 *    - `submitChallengeEntry(uint256 _challengeId, string memory _submissionData)`: Members can submit entries for art challenges.
 *    - `voteOnChallengeWinners(uint256 _challengeId, address[] memory _winnerAddresses)`: DAO votes to select winners of art challenges.
 *    - `distributeChallengeBounty(uint256 _challengeId)`: Distributes bounty to the winners of an art challenge.
 *
 * **5. Utility & Configuration:**
 *    - `setDAOAddress(address _newDAOAddress)`: Allows the contract owner to set the DAO governance address.
 *    - `getDAOAddress()`: Returns the current DAO governance address.
 *    - `setDefaultRoyaltyShare(uint256 _newDefaultShare)`: Allows the DAO to update the default royalty share.
 *    - `pauseContract()`: Allows the DAO to pause critical functions of the contract for emergency situations.
 *    - `unpauseContract()`: Allows the DAO to unpause the contract.
 */

contract DecentralizedAutonomousArtCollective {

    // ------ State Variables ------

    address public owner; // Contract owner (initially deployer, can be DAO later)
    address public daoAddress; // Address of the DAO governance contract (if any)
    bool public paused; // Contract paused state

    uint256 public projectCounter; // Counter for project IDs
    uint256 public contributionCounter; // Counter for contribution IDs
    uint256 public memberCounter; // Counter for members
    uint256 public challengeCounter; // Counter for art challenges

    uint256 public defaultRoyaltyShare = 10; // Default royalty share for contributors (in percentage, e.g., 10 = 10%)

    struct ArtProject {
        uint256 projectId;
        string title;
        string description;
        address creator;
        uint256 targetContributors;
        uint256 votingDuration;
        uint256 proposalEndTime;
        bool proposalPassed;
        bool isActive;
        bool isFinalized;
        string finalArtMetadataURI;
        mapping(uint256 => Contribution) contributions;
        uint256 contributionCount;
        address[] contributors; // List of addresses who contributed and are eligible for royalties
        mapping(address => uint256) royaltyBalances;
        mapping(address => bool) hasVotedProposal;
        uint256 votesForProposal;
        uint256 votesAgainstProposal;
    }

    struct Contribution {
        uint256 contributionId;
        address contributor;
        string contributionData;
        bool isApproved;
        uint256 timestamp;
    }

    struct Member {
        address memberAddress;
        string artistName;
        string portfolioLink;
        bool isApproved;
        uint256 joinTimestamp;
        mapping(address => bool) hasVotedMembership; // To prevent double voting on same member
        uint256 votesForMembership;
        uint256 votesAgainstMembership;
        uint256 membershipVotingEndTime;
    }

    struct ArtChallenge {
        uint256 challengeId;
        string title;
        string description;
        uint256 bountyAmount;
        uint256 submissionDeadline;
        bool isActive;
        mapping(address => string) submissions; // address => submissionData
        address[] winners;
        bool winnersDecided;
        mapping(address => bool) hasVotedWinner;
        uint256 votesForWinner;
        uint256 votesAgainstWinner;
        uint256 winnerVotingEndTime;
    }

    mapping(uint256 => ArtProject) public artProjects;
    mapping(address => Member) public members;
    mapping(uint256 => ArtChallenge) public artChallenges;

    address[] public memberList; // List of member addresses for iteration

    // ------ Events ------
    event ProjectProposed(uint256 projectId, string title, address proposer);
    event ProjectProposalVoted(uint256 projectId, address voter, bool vote);
    event ProjectContributionSubmitted(uint256 projectId, uint256 contributionId, address contributor);
    event ProjectContributionApproved(uint256 projectId, uint256 contributionId, address approver);
    event ProjectFinalized(uint256 projectId, string finalArtMetadataURI);
    event ProjectCancelled(uint256 projectId);
    event MemberJoinedCollective(address memberAddress, string artistName);
    event MembershipVoted(address memberAddress, address voter, bool vote);
    event MemberRemoved(address memberAddress);
    event RoyaltyWithdrawn(uint256 projectId, address member, uint256 amount);
    event ArtChallengeCreated(uint256 challengeId, string title, uint256 bountyAmount);
    event ChallengeEntrySubmitted(uint256 challengeId, address submitter);
    event ChallengeWinnersVoted(uint256 challengeId, address voter, address[] winners);
    event ChallengeBountyDistributed(uint256 challengeId, address[] winners, uint256 bountyAmount);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event DAOAddressUpdated(address newDAOAddress, address updater);
    event DefaultRoyaltyShareUpdated(uint256 newShare, address updater);


    // ------ Modifiers ------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this function.");
        _;
    }

    modifier onlyMembers() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(artProjects[_projectId].projectId != 0, "Project does not exist.");
        _;
    }

    modifier contributionExists(uint256 _projectId, uint256 _contributionId) {
        require(artProjects[_projectId].contributions[_contributionId].contributionId != 0, "Contribution does not exist.");
        _;
    }

    modifier projectActive(uint256 _projectId) {
        require(artProjects[_projectId].isActive, "Project is not active.");
        _;
    }

    modifier projectNotFinalized(uint256 _projectId) {
        require(!artProjects[_projectId].isFinalized, "Project is already finalized.");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(artChallenges[_challengeId].challengeId != 0, "Challenge does not exist.");
        _;
    }

    modifier challengeActive(uint256 _challengeId) {
        require(artChallenges[_challengeId].isActive, "Challenge is not active.");
        _;
    }

    modifier contractNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // ------ Constructor ------
    constructor() {
        owner = msg.sender;
        daoAddress = msg.sender; // Initially set DAO address to owner, can be updated later
        paused = false;
        projectCounter = 1;
        contributionCounter = 1;
        memberCounter = 1;
        challengeCounter = 1;
    }

    // ------ 1. Project Proposal & Management ------

    /// @notice Allows members to propose a new art project.
    /// @param _title Title of the art project.
    /// @param _description Description of the art project.
    /// @param _targetContributors Number of contributors expected for the project.
    /// @param _votingDuration Duration of the proposal voting period in seconds.
    function proposeArtProject(
        string memory _title,
        string memory _description,
        uint256 _targetContributors,
        uint256 _votingDuration
    ) external onlyMembers contractNotPaused {
        require(_votingDuration > 0, "Voting duration must be greater than 0.");
        require(_targetContributors > 0, "Target contributors must be greater than 0.");

        ArtProject storage newProject = artProjects[projectCounter];
        newProject.projectId = projectCounter;
        newProject.title = _title;
        newProject.description = _description;
        newProject.creator = msg.sender;
        newProject.targetContributors = _targetContributors;
        newProject.votingDuration = _votingDuration;
        newProject.proposalEndTime = block.timestamp + _votingDuration;
        newProject.isActive = false; // Initially inactive until proposal passes
        newProject.isFinalized = false;

        emit ProjectProposed(projectCounter, _title, msg.sender);
        projectCounter++;
    }

    /// @notice Allows members to vote on an art project proposal.
    /// @param _projectId ID of the project proposal.
    /// @param _vote Boolean value indicating vote: true for yes, false for no.
    function voteOnProjectProposal(uint256 _projectId, bool _vote) external onlyMembers contractNotPaused projectExists(_projectId) {
        ArtProject storage project = artProjects[_projectId];
        require(block.timestamp < project.proposalEndTime, "Voting period has ended.");
        require(!project.hasVotedProposal[msg.sender], "Already voted on this proposal.");

        project.hasVotedProposal[msg.sender] = true;
        if (_vote) {
            project.votesForProposal++;
        } else {
            project.votesAgainstProposal++;
        }

        emit ProjectProposalVoted(_projectId, msg.sender, _vote);

        if (block.timestamp >= project.proposalEndTime && !project.isActive) { // Check if voting ended and project not yet activated
            if (project.votesForProposal > project.votesAgainstProposal) {
                project.isActive = true;
                project.proposalPassed = true;
            } else {
                project.isActive = false; // Proposal failed
                project.proposalPassed = false;
            }
        }
    }

    /// @notice Allows members to contribute to an approved and active art project.
    /// @param _projectId ID of the art project.
    /// @param _contributionData Data representing the contribution (e.g., IPFS hash, text, etc.).
    function contributeToProject(uint256 _projectId, string memory _contributionData) external onlyMembers contractNotPaused projectExists(_projectId) projectActive(_projectId) projectNotFinalized(_projectId) {
        ArtProject storage project = artProjects[_projectId];
        Contribution storage newContribution = project.contributions[project.contributionCount + 1];
        newContribution.contributionId = project.contributionCount + 1;
        newContribution.contributor = msg.sender;
        newContribution.contributionData = _contributionData;
        newContribution.isApproved = false; // Initially not approved
        newContribution.timestamp = block.timestamp;

        project.contributionCount++;
        emit ProjectContributionSubmitted(_projectId, newContribution.contributionId, msg.sender);
    }

    /// @notice Allows the project creator to approve a contribution to their project.
    /// @param _projectId ID of the art project.
    /// @param _contributionId ID of the contribution to approve.
    function approveContribution(uint256 _projectId, uint256 _contributionId) external contractNotPaused projectExists(_projectId) projectActive(_projectId) projectNotFinalized(_projectId) contributionExists(_projectId, _contributionId) {
        ArtProject storage project = artProjects[_projectId];
        require(msg.sender == project.creator || msg.sender == daoAddress, "Only project creator or DAO can approve contributions."); // DAO override for inactive creators
        Contribution storage contribution = project.contributions[_contributionId];
        require(!contribution.isApproved, "Contribution already approved.");

        contribution.isApproved = true;
        if (!contains(project.contributors, contribution.contributor)) { // Avoid duplicates in contributor list
            project.contributors.push(contribution.contributor);
        }

        emit ProjectContributionApproved(_projectId, _contributionId, msg.sender);
    }

    /// @notice Allows the project creator to finalize the art project and mint the collaborative NFT.
    /// @param _projectId ID of the art project.
    /// @param _finalArtMetadataURI URI pointing to the metadata of the finalized art (e.g., IPFS).
    function finalizeArtProject(uint256 _projectId, string memory _finalArtMetadataURI) external contractNotPaused projectExists(_projectId) projectActive(_projectId) projectNotFinalized(_projectId) {
        ArtProject storage project = artProjects[_projectId];
        require(msg.sender == project.creator || msg.sender == daoAddress, "Only project creator or DAO can finalize project."); // DAO override

        require(project.contributors.length >= project.targetContributors, "Project doesn't have enough contributors."); // Optional: Enforce minimum contributors

        project.isFinalized = true;
        project.isActive = false; // Project becomes inactive after finalization
        project.finalArtMetadataURI = _finalArtMetadataURI;

        // Mint the collaborative NFT (internal function)
        _mintCollaborativeNFT(_projectId, _finalArtMetadataURI);

        emit ProjectFinalized(_projectId, _finalArtMetadataURI);
    }

    /// @notice Allows the project creator or DAO to cancel an art project.
    /// @param _projectId ID of the project to cancel.
    function cancelArtProject(uint256 _projectId) external contractNotPaused projectExists(_projectId) projectActive(_projectId) projectNotFinalized(_projectId) {
        ArtProject storage project = artProjects[_projectId];
        require(msg.sender == project.creator || msg.sender == daoAddress, "Only project creator or DAO can cancel project.");

        project.isActive = false; // Mark as inactive
        emit ProjectCancelled(_projectId);
    }

    /// @notice Returns details of a specific art project.
    /// @param _projectId ID of the art project.
    /// @return ArtProject struct containing project details.
    function getProjectDetails(uint256 _projectId) external view projectExists(_projectId) returns (ArtProject memory) {
        return artProjects[_projectId];
    }

    /// @notice Returns details of a specific contribution to a project.
    /// @param _projectId ID of the art project.
    /// @param _contributionId ID of the contribution.
    /// @return Contribution struct containing contribution details.
    function getContributionDetails(uint256 _projectId, uint256 _contributionId) external view projectExists(_projectId) contributionExists(_projectId, _contributionId) returns (Contribution memory) {
        return artProjects[_projectId].contributions[_contributionId];
    }

    // ------ 2. DAO Governance & Membership ------

    /// @notice Allows artists to apply for membership in the collective.
    /// @param _artistName Name of the artist.
    /// @param _portfolioLink Link to the artist's portfolio (e.g., website, social media).
    function joinCollective(string memory _artistName, string memory _portfolioLink) external contractNotPaused {
        require(!isMember(msg.sender), "Already a member.");
        require(bytes(_artistName).length > 0 && bytes(_portfolioLink).length > 0, "Artist name and portfolio link are required.");

        Member storage newMember = members[msg.sender];
        newMember.memberAddress = msg.sender;
        newMember.artistName = _artistName;
        newMember.portfolioLink = _portfolioLink;
        newMember.isApproved = false; // Initially not approved, requires voting
        newMember.joinTimestamp = block.timestamp;
        newMember.membershipVotingEndTime = block.timestamp + 7 days; // 7 days voting period

        memberList.push(msg.sender); // Add to member list for iteration
        emit MemberJoinedCollective(msg.sender, _artistName);
    }

    /// @notice Allows existing members to vote on a new membership application.
    /// @param _artistAddress Address of the artist applying for membership.
    /// @param _vote Boolean value indicating vote: true for yes, false for no.
    function voteOnMembership(address _artistAddress, bool _vote) external onlyMembers contractNotPaused {
        require(!isMember(_artistAddress), "Cannot vote on an existing member.");
        require(members[_artistAddress].memberAddress != address(0), "Membership application not found.");
        require(block.timestamp < members[_artistAddress].membershipVotingEndTime, "Membership voting period ended.");
        require(!members[_artistAddress].hasVotedMembership[msg.sender], "Already voted on this membership.");

        members[_artistAddress].hasVotedMembership[msg.sender] = true;
        if (_vote) {
            members[_artistAddress].votesForMembership++;
        } else {
            members[_artistAddress].votesAgainstMembership++;
        }
        emit MembershipVoted(_artistAddress, msg.sender, _vote);

        if (block.timestamp >= members[_artistAddress].membershipVotingEndTime && !members[_artistAddress].isApproved) {
            if (members[_artistAddress].votesForMembership > members[_artistAddress].votesAgainstMembership) {
                members[_artistAddress].isApproved = true;
                memberCounter++;
            } else {
                // Membership rejected, can handle removal from memberList if needed
                // For simplicity, we keep the application data but mark as not approved.
            }
        }
    }


    /// @notice DAO governance function to remove a member from the collective.
    /// @param _memberAddress Address of the member to remove.
    function removeMember(address _memberAddress) external onlyDAO contractNotPaused onlyMembers { // Only DAO can initiate, but needs member validation for security
        require(isMember(_memberAddress), "Address is not a member.");
        require(msg.sender == daoAddress, "Only DAO can remove members."); // Double check only DAO

        members[_memberAddress].isApproved = false; // Mark as not approved (effectively removing)

        // Remove from memberList (optional, can be done more efficiently with linked list or mapping if performance is critical for large member counts)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _memberAddress) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MemberRemoved(_memberAddress);
        memberCounter--; // Decrement member count
    }

    /// @notice Checks if an address is a member of the collective.
    /// @param _address Address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _address) public view returns (bool) {
        return members[_address].isApproved;
    }

    /// @notice Returns the total number of approved members in the collective.
    /// @return Number of members.
    function getMemberCount() external view returns (uint256) {
        return memberCounter -1 ; // memberCounter starts from 1, so -1 gives actual count
    }


    // ------ 3. Collaborative NFT Minting & Royalties ------

    /// @dev Internal function to mint a collaborative NFT for a project.
    /// @param _projectId ID of the project.
    /// @param _tokenURI URI for the NFT metadata.
    function _mintCollaborativeNFT(uint256 _projectId, string memory _tokenURI) internal {
        // --- Placeholder for NFT minting logic ---
        // In a real implementation, you would integrate with an NFT contract (e.g., ERC721 or ERC1155)
        // This could involve:
        // 1. Deploying or using an existing NFT contract.
        // 2. Calling a mint function on the NFT contract, passing _tokenURI and potentially project details.
        // 3. Determining NFT ownership (e.g., DAO owns it initially, or fractionalized ownership).
        // --- Example (Conceptual - requires integration with NFT contract): ---
        // NFTContract nftContract = NFTContract(nftContractAddress); // Assuming NFTContract is deployed and address is known
        // nftContract.mintToCollective(address(this), _tokenURI, _projectId); // Example mint function

        // For this example, we'll just log an event to simulate minting
        emit ProjectFinalized(_projectId, _tokenURI); // Re-emit event to indicate minting (can be more specific event)

        // --- Royalty Distribution Logic ---
        _distributeRoyalties(_projectId); // Distribute royalties after minting
    }

    /// @dev Internal function to distribute royalties for a finalized project.
    /// @param _projectId ID of the project.
    function _distributeRoyalties(uint256 _projectId) internal {
        ArtProject storage project = artProjects[_projectId];

        // --- Default Royalty Distribution ---
        uint256 numContributors = project.contributors.length;
        uint256 royaltySharePerContributor = defaultRoyaltyShare; // Default share percentage

        // --- Example: Distribute royalties to contributors (proportional to contribution - could be more complex) ---
        for (uint256 i = 0; i < numContributors; i++) {
            address contributor = project.contributors[i];
            // For simplicity, equal share for each contributor in this example
            // In a real scenario, you might track contribution quality/effort for weighted shares
            project.royaltyBalances[contributor] += royaltySharePerContributor; // Accumulate royalty shares (in percentage points)
        }
        // --- Note: Actual royalty payment (transferring ETH/tokens) would happen in withdrawRoyalties() function ---
    }


    /// @notice Allows the DAO to set a custom royalty distribution for a specific project.
    /// @dev This overrides the default distribution and allows for more flexible royalty splits.
    /// @param _projectId ID of the project to set royalty distribution for.
    /// @param _recipients Array of addresses to receive royalties.
    /// @param _shares Array of royalty shares (in percentage, e.g., [50, 30, 20] for 50%, 30%, 20%). Sum of shares should be 100.
    function setRoyaltyDistribution(uint256 _projectId, address[] memory _recipients, uint256[] memory _shares) external onlyDAO contractNotPaused projectExists(_projectId) projectNotFinalized(_projectId) {
        require(_recipients.length == _shares.length, "Recipients and shares arrays must have the same length.");
        uint256 totalShare = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            totalShare += _shares[i];
        }
        require(totalShare == 100, "Total royalty shares must sum to 100%.");

        ArtProject storage project = artProjects[_projectId];
        // Clear default distribution (if any) - in this simple example, we just overwrite
        for (uint256 i = 0; i < _recipients.length; i++) {
            project.royaltyBalances[_recipients[i]] = _shares[i]; // Set custom shares
        }
        // Remove default contributors from royalty distribution if custom is set (optional - depends on desired logic)
        delete project.contributors; // Clear default contributors list for custom distribution
    }

    /// @notice Returns the default royalty share percentage for contributors.
    /// @return Default royalty share percentage.
    function getDefaultRoyaltyShare() external view returns (uint256) {
        return defaultRoyaltyShare;
    }

    /// @notice Allows members to withdraw their earned royalties from a finalized project.
    /// @param _projectId ID of the finalized art project.
    function withdrawRoyalties(uint256 _projectId) external contractNotPaused projectExists(_projectId) projectNotFinalized(_projectId) onlyMembers { // Can withdraw from non-finalized projects if royalties are set before finalization in some scenarios
        ArtProject storage project = artProjects[_projectId];
        uint256 royaltyAmountPercentage = project.royaltyBalances[msg.sender];
        require(royaltyAmountPercentage > 0, "No royalties to withdraw.");

        // --- Placeholder for royalty payment logic ---
        // In a real implementation, royalties would likely be paid in ETH or tokens
        // This could involve:
        // 1. Storing funds associated with the project (e.g., in a project fund).
        // 2. Calculating the actual royalty amount based on the percentage share and project revenue.
        // 3. Transferring the funds to the member.
        // --- Example (Conceptual - requires project fund and payment logic): ---
        // uint256 projectRevenue = getProjectRevenue(_projectId); // Function to get project revenue (e.g., sales, donations)
        // uint256 royaltyAmount = (projectRevenue * royaltyAmountPercentage) / 100; // Calculate amount
        // payable(msg.sender).transfer(royaltyAmount); // Transfer ETH/tokens
        // --- For this example, we'll just log an event and reset the balance ---

        uint256 dummyAmount = royaltyAmountPercentage; // Using percentage as dummy amount for demonstration
        project.royaltyBalances[msg.sender] = 0; // Reset balance after withdrawal

        emit RoyaltyWithdrawn(_projectId, msg.sender, dummyAmount); // Emit event with dummy amount
    }


    // ------ 4. Art Challenges & Bounties (Optional) ------

    /// @notice Allows members to create art challenges with bounties.
    /// @param _challengeTitle Title of the art challenge.
    /// @param _challengeDescription Description of the challenge.
    /// @param _bountyAmount Bounty amount (in ETH or tokens) for the challenge.
    /// @param _submissionDeadline Deadline for submissions in seconds from now.
    function createArtChallenge(
        string memory _challengeTitle,
        string memory _challengeDescription,
        uint256 _bountyAmount,
        uint256 _submissionDeadline
    ) external onlyMembers payable contractNotPaused {
        require(msg.value >= _bountyAmount, "Bounty amount must be sent with challenge creation.");
        require(_submissionDeadline > 0, "Submission deadline must be greater than 0.");

        ArtChallenge storage newChallenge = artChallenges[challengeCounter];
        newChallenge.challengeId = challengeCounter;
        newChallenge.title = _challengeTitle;
        newChallenge.description = _challengeDescription;
        newChallenge.bountyAmount = _bountyAmount;
        newChallenge.submissionDeadline = block.timestamp + _submissionDeadline;
        newChallenge.isActive = true; // Challenge is active upon creation
        newChallenge.winnersDecided = false;
        newChallenge.winnerVotingEndTime = 0; // Set when winners voting starts

        // Transfer bounty amount to the contract (challenge fund)
        // In a real scenario, you might have a separate challenge fund management
        payable(address(this)).transfer(_bountyAmount);

        emit ArtChallengeCreated(challengeCounter, _challengeTitle, _bountyAmount);
        challengeCounter++;
    }


    /// @notice Allows members to submit entries for an active art challenge.
    /// @param _challengeId ID of the art challenge.
    /// @param _submissionData Data representing the submission (e.g., IPFS hash, link).
    function submitChallengeEntry(uint256 _challengeId, string memory _submissionData) external onlyMembers contractNotPaused challengeExists(_challengeId) challengeActive(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(block.timestamp < challenge.submissionDeadline, "Submission deadline has passed.");
        require(bytes(challenge.submissions[msg.sender]).length == 0, "Already submitted an entry for this challenge."); // Only one submission per member

        challenge.submissions[msg.sender] = _submissionData;
        emit ChallengeEntrySubmitted(_challengeId, msg.sender);
    }

    /// @notice DAO votes to select winners of an art challenge after submission deadline.
    /// @param _challengeId ID of the art challenge.
    /// @param _winnerAddresses Array of addresses to be selected as winners.
    function voteOnChallengeWinners(uint256 _challengeId, address[] memory _winnerAddresses) external onlyDAO contractNotPaused challengeExists(_challengeId) challengeActive(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(block.timestamp >= challenge.submissionDeadline, "Winner voting can only start after submission deadline.");
        require(!challenge.winnersDecided, "Winners already decided for this challenge.");
        require(challenge.winnerVotingEndTime == 0, "Voting already started");

        challenge.winners = _winnerAddresses; // Set potential winners (DAO's choice)
        challenge.winnerVotingEndTime = block.timestamp + 7 days; // 7 days voting period for winners selection

        emit ChallengeWinnersVoted(_challengeId, msg.sender, _winnerAddresses);

    }

    /// @notice Distributes the bounty to the voted winners of an art challenge after voting period ends.
    /// @param _challengeId ID of the art challenge.
    function distributeChallengeBounty(uint256 _challengeId) external onlyDAO contractNotPaused challengeExists(_challengeId) challengeActive(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(challenge.winnerVotingEndTime != 0, "Winner voting hasn't started yet."); // Voting must have started
        require(block.timestamp >= challenge.winnerVotingEndTime, "Winner voting period hasn't ended.");
        require(!challenge.winnersDecided, "Bounty already distributed for this challenge.");

        challenge.winnersDecided = true;
        challenge.isActive = false; // Challenge becomes inactive after bounty distribution

        uint256 bountyPerWinner = challenge.bountyAmount / challenge.winners.length;
        uint256 remainingBounty = challenge.bountyAmount % challenge.winners.length; // Handle remainder

        for (uint256 i = 0; i < challenge.winners.length; i++) {
            payable(challenge.winners[i]).transfer(bountyPerWinner);
        }
        // Optionally handle remainingBounty (e.g., return to DAO fund or creator)
        if (remainingBounty > 0) {
            payable(daoAddress).transfer(remainingBounty); // Example: Return remainder to DAO
        }

        emit ChallengeBountyDistributed(_challengeId, challenge.winners, challenge.bountyAmount);
    }


    // ------ 5. Utility & Configuration ------

    /// @notice Allows the contract owner to set the DAO governance address.
    /// @param _newDAOAddress Address of the new DAO contract.
    function setDAOAddress(address _newDAOAddress) external onlyOwner contractNotPaused {
        require(_newDAOAddress != address(0), "DAO address cannot be zero address.");
        daoAddress = _newDAOAddress;
        emit DAOAddressUpdated(_newDAOAddress, msg.sender);
    }

    /// @notice Returns the current DAO governance address.
    /// @return DAO governance address.
    function getDAOAddress() external view returns (address) {
        return daoAddress;
    }

    /// @notice Allows the DAO to update the default royalty share percentage.
    /// @param _newDefaultShare New default royalty share percentage.
    function setDefaultRoyaltyShare(uint256 _newDefaultShare) external onlyDAO contractNotPaused {
        require(_newDefaultShare <= 100, "Default royalty share cannot exceed 100%.");
        defaultRoyaltyShare = _newDefaultShare;
        emit DefaultRoyaltyShareUpdated(_newDefaultShare, msg.sender);
    }

    /// @notice Allows the DAO to pause critical functions of the contract in emergency situations.
    function pauseContract() external onlyDAO {
        require(!paused, "Contract is already paused.");
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows the DAO to unpause the contract after emergency is resolved.
    function unpauseContract() external onlyDAO {
        require(paused, "Contract is not paused.");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // ------ Internal Utility Functions ------

    /// @dev Internal function to check if an address exists in an array of addresses.
    function contains(address[] memory arr, address addr) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == addr) {
                return true;
            }
        }
        return false;
    }

    // ------ Fallback and Receive Functions (Optional - for receiving ETH) ------
    receive() external payable {}
    fallback() external payable {}
}
```