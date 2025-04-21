```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that facilitates collaborative art creation,
 * curation, fractional ownership, and innovative community engagement within the digital art space.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 * 1. `createArtProject(string memory _title, string memory _description, uint256 _maxCollaborators, uint256 _collaborationFee)`: Allows the creation of a new collaborative art project with specific parameters.
 * 2. `joinArtProject(uint256 _projectId)`: Allows artists to join an open art project by paying a collaboration fee.
 * 3. `submitArtContribution(uint256 _projectId, string memory _contributionURI)`: Artists can submit their art contributions (URI to IPFS or similar) to a project.
 * 4. `voteOnContribution(uint256 _projectId, uint256 _contributionId, bool _approve)`: Members of a project can vote to approve or reject submitted contributions.
 * 5. `finalizeArtProject(uint256 _projectId)`: Finalizes an art project after voting, minting a collective NFT representing the artwork.
 * 6. `mintFractionalNFTs(uint256 _projectId, uint256 _numberOfFractions)`: Mints fractional NFTs representing ownership of the finalized artwork.
 * 7. `buyFractionalNFT(uint256 _fractionalNFTId)`: Allows users to purchase fractional NFTs from the primary market or from other holders.
 * 8. `sellFractionalNFT(uint256 _fractionalNFTId, uint256 _price)`: Allows fractional NFT holders to list their NFTs for sale.
 * 9. `withdrawProjectFunds(uint256 _projectId)`: Allows project creators to withdraw funds accumulated from collaboration fees and NFT sales (governed by project settings).
 * 10. `setProjectRoyalty(uint256 _projectId, uint256 _royaltyPercentage)`: Allows project creators to set a royalty percentage for secondary sales of fractional NFTs.
 * 11. `claimRoyalties(uint256 _projectId)`: Allows project creators to claim accumulated royalties from secondary sales.

 * **Governance and Community Features:**
 * 12. `proposeProjectParameterChange(uint256 _projectId, string memory _parameterName, string memory _newValue)`: Allows project members to propose changes to project parameters (e.g., royalty, collaboration fee).
 * 13. `voteOnProposal(uint256 _projectId, uint256 _proposalId, bool _approve)`: Members can vote on proposed parameter changes.
 * 14. `executeProposal(uint256 _projectId, uint256 _proposalId)`: Executes an approved project parameter change proposal.
 * 15. `donateToProject(uint256 _projectId)`: Allows anyone to donate ETH to support a specific art project.
 * 16. `createCommunityPoll(string memory _pollQuestion, string[] memory _options, uint256 _durationInBlocks)`: Allows project creators to create community polls for decision-making or feedback.
 * 17. `voteInPoll(uint256 _pollId, uint256 _optionIndex)`: Members can vote in active community polls.

 * **Advanced & Trendy Features:**
 * 18. `setContributionDeadline(uint256 _projectId, uint256 _deadlineBlock)`: Sets a deadline block for art contribution submissions to a project.
 * 19. `burnFractionalNFT(uint256 _fractionalNFTId)`: Allows fractional NFT holders to burn their NFTs (potentially for reputation or governance points).
 * 20. `createArtChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _rewardAmount)`: Allows the community to create art challenges with ETH rewards for winning submissions.
 * 21. `submitChallengeEntry(uint256 _challengeId, string memory _entryURI)`: Artists can submit entries for active art challenges.
 * 22. `voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _approve)`: Community can vote on challenge entries to determine winners.
 * 23. `finalizeArtChallenge(uint256 _challengeId)`: Finalizes an art challenge, distributes rewards to winners based on voting.
 */

contract DecentralizedAutonomousArtCollective {

    // --- Structs and Enums ---

    enum ProjectStatus { OPEN, IN_PROGRESS, VOTING, FINALIZED }
    enum ProposalStatus { PENDING, ACTIVE, PASSED, REJECTED, EXECUTED }
    enum PollStatus { ACTIVE, CLOSED }
    enum ChallengeStatus { ACTIVE, VOTING, FINALIZED }

    struct ArtProject {
        string title;
        string description;
        address creator;
        ProjectStatus status;
        uint256 maxCollaborators;
        uint256 collaborationFee;
        uint256 royaltyPercentage;
        uint256 contributionDeadlineBlock;
        uint256 projectBalance;
        uint256 fractionalNFTSupply;
        mapping(address => bool) collaborators;
        Contribution[] contributions;
        Proposal[] proposals;
        uint256[] fractionalNFTIds; // Track fractional NFTs for this project
    }

    struct Contribution {
        uint256 id;
        address artist;
        string contributionURI;
        uint256 upVotes;
        uint256 downVotes;
        bool approved;
    }

    struct Proposal {
        uint256 id;
        string parameterName;
        string newValue;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct CommunityPoll {
        uint256 id;
        string question;
        string[] options;
        PollStatus status;
        uint256 endTimeBlock;
        mapping(address => uint256) votes; // address to option index
        uint256[] voteCounts; // Count for each option
    }

    struct ArtChallenge {
        uint256 id;
        string title;
        string description;
        ChallengeStatus status;
        uint256 rewardAmount;
        Entry[] entries;
        uint256 endTimeBlock;
        address winner;
    }

    struct Entry {
        uint256 id;
        address artist;
        string entryURI;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct FractionalNFT {
        uint256 id;
        uint256 projectId;
        address owner;
        uint256 price; // Price if listed for sale, 0 if not
        bool onSale;
    }


    // --- State Variables ---

    uint256 public nextProjectId;
    mapping(uint256 => ArtProject) public artProjects;
    uint256 public nextProposalId;
    uint256 public nextContributionId;
    uint256 public nextPollId;
    mapping(uint256 => CommunityPoll) public communityPolls;
    uint256 public nextChallengeId;
    mapping(uint256 => ArtChallenge) public artChallenges;
    uint256 public nextFractionalNFTId;
    mapping(uint256 => FractionalNFT) public fractionalNFTs;
    uint256 public platformFeePercentage = 5; // Platform fee for primary sales
    address payable public platformFeeRecipient;


    // --- Events ---

    event ProjectCreated(uint256 projectId, string title, address creator);
    event ProjectJoined(uint256 projectId, address artist);
    event ContributionSubmitted(uint256 projectId, uint256 contributionId, address artist);
    event ContributionVoted(uint256 projectId, uint256 contributionId, address voter, bool approved);
    event ProjectFinalized(uint256 projectId, uint256 fractionalNFTSupply);
    event FractionalNFTMinted(uint256 fractionalNFTId, uint256 projectId, address owner);
    event FractionalNFTBought(uint256 fractionalNFTId, address buyer, uint256 price);
    event FractionalNFTListedForSale(uint256 fractionalNFTId, uint256 price);
    event FractionalNFTSaleCancelled(uint256 fractionalNFTId);
    event ProjectFundsWithdrawn(uint256 projectId, address recipient, uint256 amount);
    event ProjectRoyaltySet(uint256 projectId, uint256 royaltyPercentage);
    event RoyaltiesClaimed(uint256 projectId, address recipient, uint256 amount);
    event ProposalCreated(uint256 projectId, uint256 proposalId, string parameterName);
    event ProposalVoted(uint256 projectId, uint256 proposalId, address voter, bool approved);
    event ProposalExecuted(uint256 projectId, uint256 proposalId, string parameterName);
    event DonationReceived(uint256 projectId, address donor, uint256 amount);
    event CommunityPollCreated(uint256 pollId, string question);
    event PollVoted(uint256 pollId, address voter, uint256 optionIndex);
    event ArtChallengeCreated(uint256 challengeId, string title, uint256 rewardAmount);
    event ChallengeEntrySubmitted(uint256 challengeId, uint256 entryId, address artist);
    event ChallengeEntryVoted(uint256 challengeId, uint256 entryId, address voter, bool approved);
    event ArtChallengeFinalized(uint256 challengeId, address winner, uint256 rewardAmount);
    event FractionalNFTBurned(uint256 fractionalNFTId, address burner);


    // --- Modifiers ---

    modifier onlyProjectCreator(uint256 _projectId) {
        require(artProjects[_projectId].creator == msg.sender, "Only project creator allowed.");
        _;
    }

    modifier onlyProjectCollaborator(uint256 _projectId) {
        require(artProjects[_projectId].collaborators[msg.sender], "Only project collaborators allowed.");
        _;
    }

    modifier validProjectStatus(uint256 _projectId, ProjectStatus _status) {
        require(artProjects[_projectId].status == _status, "Invalid project status.");
        _;
    }

    modifier validProposalStatus(uint256 _projectId, uint256 _proposalId, ProposalStatus _status) {
        require(artProjects[_projectId].proposals[_proposalId].status == _status, "Invalid proposal status.");
        _;
    }

    modifier validPollStatus(uint256 _pollId, PollStatus _status) {
        require(communityPolls[_pollId].status == _status, "Invalid poll status.");
        _;
    }

    modifier validChallengeStatus(uint256 _challengeId, ChallengeStatus _status) {
        require(artChallenges[_challengeId].status == _status, "Invalid challenge status.");
        _;
    }

    modifier fractionalNFTExists(uint256 _fractionalNFTId) {
        require(fractionalNFTs[_fractionalNFTId].id != 0, "Fractional NFT does not exist.");
        _;
    }

    modifier fractionalNFTOnSale(uint256 _fractionalNFTId) {
        require(fractionalNFTs[_fractionalNFTId].onSale, "Fractional NFT is not on sale.");
        _;
    }

    // --- Constructor ---
    constructor(address payable _platformFeeRecipient) {
        platformFeeRecipient = _platformFeeRecipient;
    }


    // --- Core Functionality ---

    function createArtProject(
        string memory _title,
        string memory _description,
        uint256 _maxCollaborators,
        uint256 _collaborationFee
    ) public payable returns (uint256 projectId) {
        projectId = nextProjectId++;
        artProjects[projectId] = ArtProject({
            title: _title,
            description: _description,
            creator: msg.sender,
            status: ProjectStatus.OPEN,
            maxCollaborators: _maxCollaborators,
            collaborationFee: _collaborationFee,
            royaltyPercentage: 10, // Default royalty 10%
            contributionDeadlineBlock: 0, // No deadline by default
            projectBalance: msg.value, // Initial funds from creator
            fractionalNFTSupply: 0,
            collaborators: mapping(address => bool)(),
            contributions: new Contribution[](0),
            proposals: new Proposal[](0),
            fractionalNFTIds: new uint256[](0)
        });
        emit ProjectCreated(projectId, _title, msg.sender);
        return projectId;
    }

    function joinArtProject(uint256 _projectId) public payable validProjectStatus(_projectId, ProjectStatus.OPEN) {
        ArtProject storage project = artProjects[_projectId];
        require(!project.collaborators[msg.sender], "Already a collaborator.");
        require(project.getCollaboratorCount() < project.maxCollaborators, "Project is full.");
        require(msg.value >= project.collaborationFee, "Insufficient collaboration fee.");

        project.collaborators[msg.sender] = true;
        project.projectBalance += msg.value;
        emit ProjectJoined(_projectId, msg.sender);
    }

    function submitArtContribution(uint256 _projectId, string memory _contributionURI)
        public
        validProjectStatus(_projectId, ProjectStatus.IN_PROGRESS)
        onlyProjectCollaborator(_projectId)
    {
        ArtProject storage project = artProjects[_projectId];
        require(block.number <= project.contributionDeadlineBlock || project.contributionDeadlineBlock == 0, "Contribution deadline passed.");

        uint256 contributionId = nextContributionId++;
        project.contributions.push(Contribution({
            id: contributionId,
            artist: msg.sender,
            contributionURI: _contributionURI,
            upVotes: 0,
            downVotes: 0,
            approved: false
        }));
        emit ContributionSubmitted(_projectId, contributionId, msg.sender);
    }

    function voteOnContribution(uint256 _projectId, uint256 _contributionId, bool _approve)
        public
        validProjectStatus(_projectId, ProjectStatus.VOTING)
        onlyProjectCollaborator(_projectId)
    {
        ArtProject storage project = artProjects[_projectId];
        require(_contributionId < project.contributions.length, "Invalid contribution ID.");
        Contribution storage contribution = project.contributions[_contributionId];
        require(contribution.artist != msg.sender, "Artist cannot vote on their own contribution."); // Optional, but good practice

        if (_approve) {
            contribution.upVotes++;
        } else {
            contribution.downVotes++;
        }
        emit ContributionVoted(_projectId, _contributionId, msg.sender, _approve);
    }

    function finalizeArtProject(uint256 _projectId)
        public
        validProjectStatus(_projectId, ProjectStatus.VOTING)
        onlyProjectCreator(_projectId)
    {
        ArtProject storage project = artProjects[_projectId];
        project.status = ProjectStatus.FINALIZED;

        uint256 approvedContributionsCount = 0;
        for (uint256 i = 0; i < project.contributions.length; i++) {
            if (project.contributions[i].upVotes > project.contributions[i].downVotes) { // Simple majority vote
                project.contributions[i].approved = true;
                approvedContributionsCount++;
            }
        }

        project.fractionalNFTSupply = approvedContributionsCount > 0 ? approvedContributionsCount * 100 : 100; // Example supply logic
        mintFractionalNFTs(_projectId, project.fractionalNFTSupply);

        emit ProjectFinalized(_projectId, project.fractionalNFTSupply);
    }

    function mintFractionalNFTs(uint256 _projectId, uint256 _numberOfFractions) private {
        ArtProject storage project = artProjects[_projectId];
        for (uint256 i = 0; i < _numberOfFractions; i++) {
            uint256 fractionalNFTId = nextFractionalNFTId++;
            fractionalNFTs[fractionalNFTId] = FractionalNFT({
                id: fractionalNFTId,
                projectId: _projectId,
                owner: project.creator, // Initially owned by project creator, can be changed
                price: 0,
                onSale: false
            });
            project.fractionalNFTIds.push(fractionalNFTId);
            emit FractionalNFTMinted(fractionalNFTId, _projectId, project.creator);
        }
    }

    function buyFractionalNFT(uint256 _fractionalNFTId)
        public
        payable
        fractionalNFTExists(_fractionalNFTId)
        fractionalNFTOnSale(_fractionalNFTId)
    {
        FractionalNFT storage nft = fractionalNFTs[_fractionalNFTId];
        require(msg.value >= nft.price, "Insufficient funds.");

        address previousOwner = nft.owner;
        address payable seller = payable(previousOwner);

        // Platform fee on primary sales (first sale from creator)
        uint256 platformFee = 0;
        if (seller == artProjects[nft.projectId].creator) { // Assuming initial owner is creator
            platformFee = (nft.price * platformFeePercentage) / 100;
            (bool success, ) = platformFeeRecipient.call{value: platformFee}("");
            require(success, "Platform fee transfer failed.");
        }

        uint256 sellerAmount = nft.price - platformFee;
        (bool successSeller, ) = seller.call{value: sellerAmount}("");
        require(successSeller, "Seller payment failed.");

        nft.owner = msg.sender;
        nft.onSale = false;
        nft.price = 0; // Reset price after sale

        emit FractionalNFTBought(_fractionalNFTId, msg.sender, nft.price);
    }

    function sellFractionalNFT(uint256 _fractionalNFTId, uint256 _price)
        public
        fractionalNFTExists(_fractionalNFTId)
    {
        FractionalNFT storage nft = fractionalNFTs[_fractionalNFTId];
        require(nft.owner == msg.sender, "Not NFT owner.");
        require(_price > 0, "Price must be greater than zero.");

        nft.price = _price;
        nft.onSale = true;
        emit FractionalNFTListedForSale(_fractionalNFTId, _price);
    }

    function cancelSellFractionalNFT(uint256 _fractionalNFTId)
        public
        fractionalNFTExists(_fractionalNFTId)
    {
        FractionalNFT storage nft = fractionalNFTs[_fractionalNFTId];
        require(nft.owner == msg.sender, "Not NFT owner.");
        require(nft.onSale, "NFT is not for sale.");

        nft.onSale = false;
        nft.price = 0;
        emit FractionalNFTSaleCancelled(_fractionalNFTId);
    }

    function withdrawProjectFunds(uint256 _projectId)
        public
        onlyProjectCreator(_projectId)
        validProjectStatus(_projectId, ProjectStatus.FINALIZED)
    {
        ArtProject storage project = artProjects[_projectId];
        uint256 amountToWithdraw = project.projectBalance;
        project.projectBalance = 0; // Reset balance

        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");
        emit ProjectFundsWithdrawn(_projectId, msg.sender, amountToWithdraw);
    }

    function setProjectRoyalty(uint256 _projectId, uint256 _royaltyPercentage)
        public
        onlyProjectCreator(_projectId)
    {
        require(_royaltyPercentage <= 50, "Royalty percentage too high."); // Example limit
        artProjects[_projectId].royaltyPercentage = _royaltyPercentage;
        emit ProjectRoyaltySet(_projectId, _royaltyPercentage);
    }

    function claimRoyalties(uint256 _projectId) public onlyProjectCreator(_projectId) {
        // In a real implementation, you'd track royalties per NFT sale and accumulate them.
        // This is a simplified example - Royalty tracking is complex and often handled off-chain or in dedicated marketplace contracts.
        // For this example, we'll assume royalties are magically accumulated in projectBalance (not realistic).

        ArtProject storage project = artProjects[_projectId];
        uint256 royaltyAmount = project.projectBalance; // Example - Replace with actual royalty tracking logic
        project.projectBalance = 0; // Reset royalty balance

        (bool success, ) = payable(msg.sender).call{value: royaltyAmount}("");
        require(success, "Royalty claim failed.");
        emit RoyaltiesClaimed(_projectId, msg.sender, royaltyAmount);
    }


    // --- Governance and Community Features ---

    function proposeProjectParameterChange(uint256 _projectId, string memory _parameterName, string memory _newValue)
        public
        onlyProjectCollaborator(_projectId)
        validProjectStatus(_projectId, ProjectStatus.IN_PROGRESS) // Example: Proposals during project in progress
    {
        ArtProject storage project = artProjects[_projectId];
        uint256 proposalId = nextProposalId++;
        project.proposals.push(Proposal({
            id: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            status: ProposalStatus.PENDING,
            upVotes: 0,
            downVotes: 0
        }));
        emit ProposalCreated(_projectId, proposalId, _parameterName);
    }

    function voteOnProposal(uint256 _projectId, uint256 _proposalId, bool _approve)
        public
        onlyProjectCollaborator(_projectId)
        validProjectStatus(_projectId, ProjectStatus.IN_PROGRESS) // Example: Voting during project in progress
        validProposalStatus(_projectId, _proposalId, ProposalStatus.PENDING)
    {
        ArtProject storage project = artProjects[_projectId];
        Proposal storage proposal = project.proposals[_proposalId];

        if (_approve) {
            proposal.upVotes++;
        } else {
            proposal.downVotes++;
        }
        proposal.status = ProposalStatus.ACTIVE; // Move to active after first vote
        emit ProposalVoted(_projectId, _proposalId, msg.sender, _approve);
    }

    function executeProposal(uint256 _projectId, uint256 _proposalId)
        public
        onlyProjectCreator(_projectId) // Or governance could be more decentralized
        validProjectStatus(_projectId, ProjectStatus.IN_PROGRESS) // Example: Execution during project in progress
        validProposalStatus(_projectId, _proposalId, ProposalStatus.ACTIVE)
    {
        ArtProject storage project = artProjects[_projectId];
        Proposal storage proposal = project.proposals[_proposalId];

        require(proposal.upVotes > proposal.downVotes, "Proposal not passed."); // Simple majority

        if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("royaltyPercentage"))) {
            uint256 newRoyalty = StringToUint(proposal.newValue);
            project.royaltyPercentage = newRoyalty;
        } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("collaborationFee"))) {
            uint256 newFee = StringToUint(proposal.newValue);
            project.collaborationFee = newFee;
        } // ... add more parameter changes as needed

        proposal.status = ProposalStatus.EXECUTED;
        emit ProposalExecuted(_projectId, _proposalId, proposal.parameterName);
    }

    function donateToProject(uint256 _projectId) public payable {
        artProjects[_projectId].projectBalance += msg.value;
        emit DonationReceived(_projectId, msg.sender, msg.value);
    }

    function createCommunityPoll(string memory _pollQuestion, string[] memory _options, uint256 _durationInBlocks)
        public
        onlyProjectCreator(0) // Example: Only platform admin can create global polls (projectId 0 for platform level)
    {
        uint256 pollId = nextPollId++;
        communityPolls[pollId] = CommunityPoll({
            id: pollId,
            question: _pollQuestion,
            options: _options,
            status: PollStatus.ACTIVE,
            endTimeBlock: block.number + _durationInBlocks,
            votes: mapping(address => uint256)(),
            voteCounts: new uint256[](_options.length)
        });
        emit CommunityPollCreated(pollId, _pollQuestion);
    }

    function voteInPoll(uint256 _pollId, uint256 _optionIndex)
        public
        validPollStatus(_pollId, PollStatus.ACTIVE)
    {
        CommunityPoll storage poll = communityPolls[_pollId];
        require(block.number <= poll.endTimeBlock, "Poll is closed.");
        require(_optionIndex < poll.options.length, "Invalid option index.");
        require(poll.votes[msg.sender] == 0, "Already voted."); // Allow only one vote per address initially

        poll.votes[msg.sender] = _optionIndex + 1; // Store option index + 1 to distinguish from no vote (0)
        poll.voteCounts[_optionIndex]++;
        emit PollVoted(_pollId, msg.sender, _optionIndex);

        if (block.number >= poll.endTimeBlock) {
            poll.status = PollStatus.CLOSED;
        }
    }


    // --- Advanced & Trendy Features ---

    function setContributionDeadline(uint256 _projectId, uint256 _deadlineBlock)
        public
        onlyProjectCreator(_projectId)
        validProjectStatus(_projectId, ProjectStatus.OPEN) // Can set deadline when project is open
    {
        artProjects[_projectId].contributionDeadlineBlock = _deadlineBlock;
    }

    function burnFractionalNFT(uint256 _fractionalNFTId)
        public
        fractionalNFTExists(_fractionalNFTId)
    {
        FractionalNFT storage nft = fractionalNFTs[_fractionalNFTId];
        require(nft.owner == msg.sender, "Not NFT owner.");

        delete fractionalNFTs[_fractionalNFTId]; // Effectively burns the NFT
        emit FractionalNFTBurned(_fractionalNFTId, msg.sender);
    }

    function createArtChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _rewardAmount)
        public
        payable
        onlyProjectCreator(0) // Example: Platform level challenges
    {
        require(msg.value >= _rewardAmount, "Insufficient reward deposit.");
        uint256 challengeId = nextChallengeId++;
        artChallenges[challengeId] = ArtChallenge({
            id: challengeId,
            title: _challengeTitle,
            description: _challengeDescription,
            status: ChallengeStatus.ACTIVE,
            rewardAmount: _rewardAmount,
            entries: new Entry[](0),
            endTimeBlock: block.number + 1000, // Example duration
            winner: address(0)
        });
        emit ArtChallengeCreated(challengeId, _challengeTitle, _rewardAmount);
    }

    function submitChallengeEntry(uint256 _challengeId, string memory _entryURI)
        public
        validChallengeStatus(_challengeId, ChallengeStatus.ACTIVE)
    {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(block.number <= challenge.endTimeBlock, "Challenge entry deadline passed.");

        uint256 entryId = nextContributionId++; // Reuse contribution ID counter for simplicity, or create separate counter
        challenge.entries.push(Entry({
            id: entryId,
            artist: msg.sender,
            entryURI: _entryURI,
            upVotes: 0,
            downVotes: 0
        }));
        emit ChallengeEntrySubmitted(_challengeId, entryId, msg.sender);
    }

    function voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _approve)
        public
        validChallengeStatus(_challengeId, ChallengeStatus.VOTING)
    {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(_entryId < challenge.entries.length, "Invalid entry ID.");
        Entry storage entry = challenge.entries[_entryId];
        require(entry.artist != msg.sender, "Artist cannot vote on their own entry.");

        if (_approve) {
            entry.upVotes++;
        } else {
            entry.downVotes++;
        }
        emit ChallengeEntryVoted(_challengeId, _entryId, msg.sender, _approve);
    }

    function finalizeArtChallenge(uint256 _challengeId)
        public
        onlyProjectCreator(0) // Example: Platform admin finalizes challenges
        validChallengeStatus(_challengeId, ChallengeStatus.VOTING)
    {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        challenge.status = ChallengeStatus.FINALIZED;

        uint256 winningEntryIndex = 0;
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < challenge.entries.length; i++) {
            if (challenge.entries[i].upVotes > maxVotes) {
                maxVotes = challenge.entries[i].upVotes;
                winningEntryIndex = i;
            }
        }

        if (challenge.entries.length > 0) { // Ensure there are entries
            challenge.winner = challenge.entries[winningEntryIndex].artist;
            (bool success, ) = payable(challenge.winner).call{value: challenge.rewardAmount}("");
            require(success, "Reward transfer failed.");
            emit ArtChallengeFinalized(_challengeId, challenge.winner, challenge.rewardAmount);
        }
    }


    // --- Helper Functions ---

    function StringToUint(string memory _str) internal pure returns (uint256) {
        uint256 result = 0;
        bytes memory strBytes = bytes(_str);
        for (uint256 i = 0; i < strBytes.length; i++) {
            uint8 digit = uint8(strBytes[i]) - 48; // ASCII '0' is 48
            require(digit <= 9, "Invalid digit in string.");
            result = result * 10 + digit;
        }
        return result;
    }

    function getCollaboratorCount(uint256 _projectId) public view returns (uint256) {
        uint256 count = 0;
        ArtProject storage project = artProjects[_projectId];
        for (uint256 i = 0; i < project.maxCollaborators; i++) { // Iterate up to maxCollaborators for efficiency, though map iteration isn't ordered.
            for (address collaborator : project.collaborators) {
                if (project.collaborators[collaborator]) {
                    count++;
                }
            }
            break; // Exit after one iteration of the outer loop, map iteration handles all collaborators
        }
        return count;
    }

    function getProjectStatusString(uint256 _projectId) public view returns (string memory) {
        ProjectStatus status = artProjects[_projectId].status;
        if (status == ProjectStatus.OPEN) return "OPEN";
        if (status == ProjectStatus.IN_PROGRESS) return "IN_PROGRESS";
        if (status == ProjectStatus.VOTING) return "VOTING";
        if (status == ProjectStatus.FINALIZED) return "FINALIZED";
        return "UNKNOWN";
    }

    function getProposalStatusString(uint256 _projectId, uint256 _proposalId) public view returns (string memory) {
        ProposalStatus status = artProjects[_projectId].proposals[_proposalId].status;
        if (status == ProposalStatus.PENDING) return "PENDING";
        if (status == ProposalStatus.ACTIVE) return "ACTIVE";
        if (status == ProposalStatus.PASSED) return "PASSED";
        if (status == ProposalStatus.REJECTED) return "REJECTED";
        if (status == ProposalStatus.EXECUTED) return "EXECUTED";
        return "UNKNOWN";
    }

    function getPollStatusString(uint256 _pollId) public view returns (string memory) {
        PollStatus status = communityPolls[_pollId].status;
        if (status == PollStatus.ACTIVE) return "ACTIVE";
        if (status == PollStatus.CLOSED) return "CLOSED";
        return "UNKNOWN";
    }

    function getChallengeStatusString(uint256 _challengeId) public view returns (string memory) {
        ChallengeStatus status = artChallenges[_challengeId].status;
        if (status == ChallengeStatus.ACTIVE) return "ACTIVE";
        if (status == ChallengeStatus.VOTING) return "VOTING";
        if (status == ChallengeStatus.FINALIZED) return "FINALIZED";
        return "UNKNOWN";
    }

    function getFractionalNFTDetails(uint256 _fractionalNFTId) public view returns (
        uint256 id,
        uint256 projectId,
        address owner,
        uint256 price,
        bool onSale
    ) {
        FractionalNFT storage nft = fractionalNFTs[_fractionalNFTId];
        return (nft.id, nft.projectId, nft.owner, nft.price, nft.onSale);
    }
}
```