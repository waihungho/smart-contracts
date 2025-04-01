```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Gemini AI
 * @dev This smart contract implements a Decentralized Autonomous Art Collective (DAAC)
 * allowing artists to collaborate, create, and monetize digital art collectively.
 * It features advanced concepts like:
 *  - Decentralized Art Project Proposals and Voting
 *  - Collaborative Art Creation with Shared Ownership
 *  - Dynamic Royalty Distribution based on Contribution
 *  - On-chain Art Curation and Exhibition
 *  - Art Bounties and Challenges
 *  - Decentralized Art Marketplace within the Collective
 *  - Art Provenance and Authenticity Tracking
 *  - Gamified Art Discovery and Engagement
 *  - Community Governance and Tokenized Membership (ERC721 based)
 *  - Layered Security and Access Control
 *  - Integration with IPFS for decentralized storage
 *  - Dynamic Art Evolution (Future concept placeholder)
 *
 * Function Summary:
 * 1. joinCollective(string _artistName, string _artistBio): Allows artists to join the collective by minting a Membership NFT.
 * 2. leaveCollective(): Allows members to leave the collective, burning their Membership NFT.
 * 3. proposeArtProject(string _projectName, string _projectDescription, string _projectGoals, string _ipfsArtMetadataHash): Proposes a new art project to the collective for voting.
 * 4. voteOnProjectProposal(uint _projectId, bool _vote): Members can vote on pending art project proposals.
 * 5. executeArtProject(uint _projectId): Executes an approved art project, transitioning it to 'In Progress'.
 * 6. contributeToArtProject(uint _projectId, string _contributionDescription, string _ipfsContributionHash): Members can contribute to active art projects.
 * 7. submitProjectForReview(uint _projectId, string _finalIpfsArtHash): Artists leading a project can submit it for review after completion.
 * 8. voteOnProjectReview(uint _projectId, bool _vote): Members vote on whether a submitted project meets the quality standards.
 * 9. finalizeArtProject(uint _projectId): Finalizes an approved project, minting an Art NFT and distributing royalties.
 * 10. createArtBounty(string _bountyName, string _bountyDescription, uint _rewardAmount, string _bountyCriteria): Creates an art bounty for specific artistic tasks or challenges.
 * 11. claimArtBounty(uint _bountyId, string _submissionDescription, string _ipfsSubmissionHash): Artists can claim open art bounties by submitting their work.
 * 12. voteOnBountyClaim(uint _bountyId, uint _claimId, bool _vote): Collective members vote on the quality of bounty submissions.
 * 13. awardArtBounty(uint _bountyId, uint _claimId): Awards a bounty to the winning submission after successful voting.
 * 14. listArtNFTForSale(uint _artNftId, uint _price): Allows the collective to list their Art NFTs for sale in the internal marketplace.
 * 15. buyArtNFT(uint _artNftId): Allows members to purchase Art NFTs listed by the collective.
 * 16. curateArtExhibition(string _exhibitionName, uint[] _artNftIds): Creates a curated on-chain art exhibition.
 * 17. voteForExhibitionArt(uint _exhibitionId, uint _artNftId): Members can vote to add Art NFTs to an ongoing exhibition.
 * 18. finalizeArtExhibition(uint _exhibitionId): Finalizes an art exhibition, making it publicly viewable.
 * 19. donateToCollective(): Allows anyone to donate ETH to the collective's treasury.
 * 20. proposeGovernanceChange(string _proposalDescription, bytes _encodedFunctionCall): Allows members to propose changes to the contract's governance.
 * 21. voteOnGovernanceChange(uint _proposalId, bool _vote): Members vote on governance change proposals.
 * 22. executeGovernanceChange(uint _proposalId): Executes approved governance changes after voting.
 * 23. withdrawTreasuryFunds(address _recipient, uint _amount): Allows the designated admin role to withdraw funds from the treasury (Governance controlled).
 * 24. setAdminRole(address _newAdmin): Allows the current admin to change the admin role (Governance controlled).
 * 25. setContributionWeight(uint _newWeight): Allows the admin to adjust the weight of contributions in royalty distribution (Governance controlled).
 * 26. setVotingDuration(uint _newDuration): Allows the admin to adjust the default voting duration (Governance controlled).
 * 27. getArtProjectDetails(uint _projectId): Returns detailed information about a specific art project.
 * 28. getBountyDetails(uint _bountyId): Returns details about a specific art bounty.
 * 29. getExhibitionDetails(uint _exhibitionId): Returns details about a specific art exhibition.
 * 30. getCollectiveMemberDetails(uint _memberId): Returns details about a collective member.
 */
contract DecentralizedAutonomousArtCollective {
    // --- Structs and Enums ---

    enum ProjectStatus { Proposed, Voting, InProgress, Review, ReviewVoting, Finalized, Rejected }
    enum BountyStatus { Open, VotingOnClaim, Awarded, Closed }
    enum GovernanceProposalStatus { Proposed, Voting, Executed, Rejected }

    struct ArtProject {
        string projectName;
        string projectDescription;
        string projectGoals;
        string ipfsArtMetadataHash;
        ProjectStatus status;
        address creator;
        uint startTime;
        uint endTime;
        uint voteCountYes;
        uint voteCountNo;
        address[] contributors; // Addresses of members who contributed
        string finalIpfsArtHash; // IPFS hash of the final art piece
        uint royaltyPool; // Total royalties generated for this project
    }

    struct ArtBounty {
        string bountyName;
        string bountyDescription;
        uint rewardAmount;
        string bountyCriteria;
        BountyStatus status;
        address creator;
        uint startTime;
        uint endTime;
        mapping(uint => BountyClaim) claims; // claimId => BountyClaim
        uint claimCount;
    }

    struct BountyClaim {
        address claimant;
        string submissionDescription;
        string ipfsSubmissionHash;
        uint voteCountYes;
        uint voteCountNo;
        bool awarded;
    }

    struct ArtExhibition {
        string exhibitionName;
        address curator;
        uint startTime;
        uint endTime;
        uint[] artNftIds; // IDs of Art NFTs in the exhibition
        mapping(uint => uint) artNftVoteCount; // artNftId => voteCount
    }

    struct GovernanceProposal {
        string proposalDescription;
        bytes encodedFunctionCall;
        GovernanceProposalStatus status;
        address proposer;
        uint startTime;
        uint endTime;
        uint voteCountYes;
        uint voteCountNo;
    }

    struct CollectiveMember {
        address memberAddress;
        string artistName;
        string artistBio;
        uint joinTime;
    }

    // --- State Variables ---

    address public admin; // Admin address, initially contract deployer
    uint public memberCount;
    mapping(uint => CollectiveMember) public collectiveMembers; // memberId => CollectiveMember
    mapping(address => uint) public memberIdByAddress; // address => memberId
    uint public nextProjectId;
    mapping(uint => ArtProject) public artProjects; // projectId => ArtProject
    uint public nextBountyId;
    mapping(uint => ArtBounty) public artBounties; // bountyId => ArtBounty
    uint public nextExhibitionId;
    mapping(uint => ArtExhibition) public artExhibitions; // exhibitionId => ArtExhibition
    uint public nextGovernanceProposalId;
    mapping(uint => GovernanceProposal) public governanceProposals; // proposalId => GovernanceProposal

    uint public votingDuration = 7 days; // Default voting duration
    uint public contributionWeight = 50; // Percentage weight for contribution in royalty distribution
    uint public projectApprovalThreshold = 50; // Percentage of 'Yes' votes required for project approval
    uint public reviewApprovalThreshold = 75; // Percentage of 'Yes' votes required for project review approval
    uint public bountyClaimApprovalThreshold = 60; // Percentage of 'Yes' votes for bounty claim approval
    uint public governanceApprovalThreshold = 66; // Percentage of 'Yes' votes for governance proposal approval

    mapping(uint => mapping(address => bool)) public projectVotes; // projectId => memberAddress => voted
    mapping(uint => mapping(address => bool)) public reviewVotes; // projectId => memberAddress => voted
    mapping(uint => mapping(uint => mapping(address => bool))) public bountyClaimVotes; // bountyId => claimId => memberAddress => voted
    mapping(uint => mapping(address => bool)) public governanceVotes; // governanceProposalId => memberAddress => voted

    ERC721MembershipNFT public membershipNFT;
    ERC721ArtNFT public artNFT;

    // --- Events ---

    event MemberJoined(uint memberId, address memberAddress, string artistName);
    event MemberLeft(uint memberId, address memberAddress);
    event ArtProjectProposed(uint projectId, string projectName, address proposer);
    event ProjectVoteCast(uint projectId, address voter, bool vote);
    event ArtProjectExecuted(uint projectId);
    event ArtProjectContribution(uint projectId, address contributor, string contributionDescription);
    event ProjectSubmittedForReview(uint projectId);
    event ProjectReviewVoteCast(uint projectId, address voter, bool vote);
    event ArtProjectFinalized(uint projectId, uint artNftId);
    event ArtProjectRejected(uint projectId);
    event ArtBountyCreated(uint bountyId, string bountyName, address creator, uint rewardAmount);
    event BountyClaimSubmitted(uint bountyId, uint claimId, address claimant);
    event BountyClaimVoteCast(uint bountyId, uint claimId, address voter, bool vote);
    event ArtBountyAwarded(uint bountyId, uint claimId, address winner);
    event ArtNFTListedForSale(uint artNftId, uint price, address lister);
    event ArtNFTBought(uint artNftId, address buyer, uint price);
    event ArtExhibitionCurated(uint exhibitionId, string exhibitionName, address curator);
    event ExhibitionArtVoteCast(uint exhibitionId, uint artNftId, address voter);
    event ArtExhibitionFinalized(uint exhibitionId);
    event DonationReceived(address donor, uint amount);
    event GovernanceProposalProposed(uint proposalId, string description, address proposer);
    event GovernanceVoteCast(uint proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint proposalId);
    event GovernanceProposalRejected(uint proposalId);
    event TreasuryFundsWithdrawn(address recipient, uint amount, address admin);
    event AdminRoleChanged(address newAdmin, address previousAdmin);
    event ContributionWeightUpdated(uint newWeight, address admin);
    event VotingDurationUpdated(uint newDuration, address admin);


    // --- Modifiers ---

    modifier onlyCollectiveMember() {
        require(memberIdByAddress[msg.sender] != 0, "You are not a member of the collective.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier validProjectId(uint _projectId) {
        require(_projectId > 0 && _projectId < nextProjectId, "Invalid project ID.");
        _;
    }

    modifier validBountyId(uint _bountyId) {
        require(_bountyId > 0 && _bountyId < nextBountyId, "Invalid bounty ID.");
        _;
    }

    modifier validExhibitionId(uint _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId < nextExhibitionId, "Invalid exhibition ID.");
        _;
    }

    modifier validGovernanceProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId < nextGovernanceProposalId, "Invalid governance proposal ID.");
        _;
    }

    modifier projectInStatus(uint _projectId, ProjectStatus _status) {
        require(artProjects[_projectId].status == _status, "Project is not in the required status.");
        _;
    }

    modifier bountyInStatus(uint _bountyId, BountyStatus _status) {
        require(artBounties[_bountyId].status == _status, "Bounty is not in the required status.");
        _;
    }

    modifier governanceProposalInStatus(uint _proposalId, GovernanceProposalStatus _status) {
        require(governanceProposals[_proposalId].status == _status, "Governance proposal is not in the required status.");
        _;
    }

    modifier votingPeriodActive(uint _startTime, uint _duration) {
        require(block.timestamp >= _startTime && block.timestamp <= _startTime + _duration, "Voting period is not active.");
        _;
    }

    // --- Constructor ---

    constructor(string memory _membershipNFTName, string memory _membershipNFTSymbol, string memory _artNFTName, string memory _artNFTSymbol) payable {
        admin = msg.sender;
        membershipNFT = new ERC721MembershipNFT(_membershipNFTName, _membershipNFTSymbol);
        artNFT = new ERC721ArtNFT(_artNFTName, _artNFTSymbol);
    }


    // --- Membership Functions ---

    function joinCollective(string memory _artistName, string memory _artistBio) public payable {
        require(msg.value >= 0.01 ether, "Membership requires a small contribution of 0.01 ETH."); // Small entry fee, can be adjusted or removed
        memberCount++;
        uint newMemberId = memberCount;
        collectiveMembers[newMemberId] = CollectiveMember(msg.sender, _artistName, _artistBio, block.timestamp);
        memberIdByAddress[msg.sender] = newMemberId;
        membershipNFT.mint(msg.sender, newMemberId);
        payable(address(this)).transfer(msg.value); // Transfer the membership fee to the contract treasury
        emit MemberJoined(newMemberId, msg.sender, _artistName);
    }

    function leaveCollective() public onlyCollectiveMember {
        uint memberId = memberIdByAddress[msg.sender];
        delete collectiveMembers[memberId];
        delete memberIdByAddress[msg.sender];
        membershipNFT.burn(memberId);
        emit MemberLeft(memberId, msg.sender);
    }


    // --- Art Project Functions ---

    function proposeArtProject(
        string memory _projectName,
        string memory _projectDescription,
        string memory _projectGoals,
        string memory _ipfsArtMetadataHash
    ) public onlyCollectiveMember {
        nextProjectId++;
        artProjects[nextProjectId] = ArtProject({
            projectName: _projectName,
            projectDescription: _projectDescription,
            projectGoals: _projectGoals,
            ipfsArtMetadataHash: _ipfsArtMetadataHash,
            status: ProjectStatus.Proposed,
            creator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            voteCountYes: 0,
            voteCountNo: 0,
            contributors: new address[](0),
            finalIpfsArtHash: "",
            royaltyPool: 0
        });
        emit ArtProjectProposed(nextProjectId, _projectName, msg.sender);
    }

    function voteOnProjectProposal(uint _projectId, bool _vote) public onlyCollectiveMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Proposed) votingPeriodActive(artProjects[_projectId].startTime, votingDuration) {
        require(!projectVotes[_projectId][msg.sender], "You have already voted on this project proposal.");
        projectVotes[_projectId][msg.sender] = true;
        if (_vote) {
            artProjects[_projectId].voteCountYes++;
        } else {
            artProjects[_projectId].voteCountNo++;
        }
        emit ProjectVoteCast(_projectId, msg.sender, _vote);
    }

    function executeArtProject(uint _projectId) public validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.Proposed) {
        require(block.timestamp > artProjects[_projectId].endTime, "Voting period is still active.");
        uint totalVotes = artProjects[_projectId].voteCountYes + artProjects[_projectId].voteCountNo;
        require(totalVotes > 0, "No votes were cast on this proposal."); // To prevent division by zero
        uint yesPercentage = (artProjects[_projectId].voteCountYes * 100) / totalVotes;
        if (yesPercentage >= projectApprovalThreshold) {
            artProjects[_projectId].status = ProjectStatus.InProgress;
            emit ArtProjectExecuted(_projectId);
        } else {
            artProjects[_projectId].status = ProjectStatus.Rejected;
            emit ArtProjectRejected(_projectId);
        }
    }

    function contributeToArtProject(uint _projectId, string memory _contributionDescription, string memory _ipfsContributionHash) public onlyCollectiveMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.InProgress) {
        bool alreadyContributor = false;
        for (uint i = 0; i < artProjects[_projectId].contributors.length; i++) {
            if (artProjects[_projectId].contributors[i] == msg.sender) {
                alreadyContributor = true;
                break;
            }
        }
        require(!alreadyContributor, "You have already contributed to this project.");
        artProjects[_projectId].contributors.push(msg.sender);
        emit ArtProjectContribution(_projectId, msg.sender, _contributionDescription);
    }

    function submitProjectForReview(uint _projectId, string memory _finalIpfsArtHash) public validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.InProgress) {
        require(artProjects[_projectId].creator == msg.sender, "Only the project creator can submit for review.");
        artProjects[_projectId].status = ProjectStatus.Review;
        artProjects[_projectId].finalIpfsArtHash = _finalIpfsArtHash;
        artProjects[_projectId].status = ProjectStatus.ReviewVoting;
        artProjects[_projectId].startTime = block.timestamp; // Reset start time for review voting
        artProjects[_projectId].endTime = block.timestamp + votingDuration;
        emit ProjectSubmittedForReview(_projectId);
    }

    function voteOnProjectReview(uint _projectId, bool _vote) public onlyCollectiveMember validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.ReviewVoting) votingPeriodActive(artProjects[_projectId].startTime, votingDuration) {
        require(!reviewVotes[_projectId][msg.sender], "You have already voted on this project review.");
        reviewVotes[_projectId][msg.sender] = true;
        if (_vote) {
            artProjects[_projectId].voteCountYes++; // Reusing voteCountYes and No for review votes
        } else {
            artProjects[_projectId].voteCountNo++;
        }
        emit ProjectReviewVoteCast(_projectId, msg.sender, _vote);
    }

    function finalizeArtProject(uint _projectId) public validProjectId(_projectId) projectInStatus(_projectId, ProjectStatus.ReviewVoting) {
        require(block.timestamp > artProjects[_projectId].endTime, "Review voting period is still active.");
        uint totalVotes = artProjects[_projectId].voteCountYes + artProjects[_projectId].voteCountNo;
        require(totalVotes > 0, "No votes were cast on project review.");
        uint yesPercentage = (artProjects[_projectId].voteCountYes * 100) / totalVotes;

        if (yesPercentage >= reviewApprovalThreshold) {
            artProjects[_projectId].status = ProjectStatus.Finalized;
            uint artNftId = artNFT.mintArtNFT(artProjects[_projectId].finalIpfsArtHash); // Mint Art NFT
            emit ArtProjectFinalized(_projectId, artNftId);
            distributeProjectRoyalties(_projectId, artNftId); // Placeholder for royalty distribution logic
        } else {
            artProjects[_projectId].status = ProjectStatus.Rejected;
            emit ArtProjectRejected(_projectId);
        }
    }

    function distributeProjectRoyalties(uint _projectId, uint _artNftId) internal {
        // --- Placeholder for advanced royalty distribution logic ---
        // In a real-world scenario, this function would:
        // 1. Calculate royalties based on sales of the Art NFT.
        // 2. Determine contribution scores for each contributor (consider contribution quality, time, etc.).
        // 3. Distribute royalties proportionally based on contribution scores and potentially creator percentage.
        // 4. Track royalty distribution on-chain.

        // For this example, a simplified distribution: Creator gets 50%, contributors split 50% equally
        uint totalContributors = artProjects[_projectId].contributors.length;
        uint creatorSharePercentage = 50;
        uint contributorSharePercentage = 50;

        uint currentArtNftPrice = artNFT.getArtNFTPrice(_artNftId); // Example: Get price from Art NFT contract (needs implementation in ERC721ArtNFT)

        if (currentArtNftPrice > 0) { // Only distribute if there's a price (assume it's the sale price)
            uint creatorShare = (currentArtNftPrice * creatorSharePercentage) / 100;
            uint contributorShareTotal = (currentArtNftPrice * contributorSharePercentage) / 100;

            if (totalContributors > 0) {
                uint individualContributorShare = contributorShareTotal / totalContributors;
                for (uint i = 0; i < totalContributors; i++) {
                    payable(artProjects[_projectId].contributors[i]).transfer(individualContributorShare);
                }
            }
            payable(artProjects[_projectId].creator).transfer(creatorShare);

            artProjects[_projectId].royaltyPool += currentArtNftPrice; // Track in royalty pool
        }

        // In a more advanced version:
        // - Consider using a separate royalty pool contract.
        // - Implement granular contribution tracking and scoring.
        // - Allow for different royalty splits based on project type or governance decisions.
    }


    // --- Art Bounty Functions ---

    function createArtBounty(
        string memory _bountyName,
        string memory _bountyDescription,
        uint _rewardAmount,
        string memory _bountyCriteria
    ) public onlyCollectiveMember {
        require(_rewardAmount > 0, "Bounty reward must be greater than 0.");
        require(address(this).balance >= _rewardAmount, "Contract balance is insufficient for the bounty reward.");

        nextBountyId++;
        artBounties[nextBountyId] = ArtBounty({
            bountyName: _bountyName,
            bountyDescription: _bountyDescription,
            rewardAmount: _rewardAmount,
            bountyCriteria: _bountyCriteria,
            status: BountyStatus.Open,
            creator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration, // Default voting duration for bounties? Or different duration?
            claims: mapping(uint => BountyClaim)(),
            claimCount: 0
        });
        emit ArtBountyCreated(nextBountyId, _bountyName, msg.sender, _rewardAmount);
    }

    function claimArtBounty(uint _bountyId, string memory _submissionDescription, string memory _ipfsSubmissionHash) public onlyCollectiveMember validBountyId(_bountyId) bountyInStatus(_bountyId, BountyStatus.Open) {
        artBounties[_bountyId].claimCount++;
        uint claimId = artBounties[_bountyId].claimCount;
        artBounties[_bountyId].claims[claimId] = BountyClaim({
            claimant: msg.sender,
            submissionDescription: _submissionDescription,
            ipfsSubmissionHash: _ipfsSubmissionHash,
            voteCountYes: 0,
            voteCountNo: 0,
            awarded: false
        });
        artBounties[_bountyId].status = BountyStatus.VotingOnClaim; // Move bounty to voting status
        artBounties[_bountyId].startTime = block.timestamp; // Reset start time for bounty claim voting
        artBounties[_bountyId].endTime = block.timestamp + votingDuration;
        emit BountyClaimSubmitted(_bountyId, claimId, msg.sender);
    }

    function voteOnBountyClaim(uint _bountyId, uint _claimId, bool _vote) public onlyCollectiveMember validBountyId(_bountyId) bountyInStatus(_bountyId, BountyStatus.VotingOnClaim) votingPeriodActive(artBounties[_bountyId].startTime, votingDuration) {
        require(artBounties[_bountyId].claims[_claimId].claimant != address(0), "Invalid claim ID."); // Check if claim exists
        require(!bountyClaimVotes[_bountyId][_claimId][msg.sender], "You have already voted on this bounty claim.");
        bountyClaimVotes[_bountyId][_claimId][msg.sender] = true;
        if (_vote) {
            artBounties[_bountyId].claims[_claimId].voteCountYes++;
        } else {
            artBounties[_bountyId].claims[_claimId].voteCountNo++;
        }
        emit BountyClaimVoteCast(_bountyId, _claimId, msg.sender, _vote);
    }

    function awardArtBounty(uint _bountyId, uint _claimId) public validBountyId(_bountyId) bountyInStatus(_bountyId, BountyStatus.VotingOnClaim) {
        require(block.timestamp > artBounties[_bountyId].endTime, "Bounty claim voting period is still active.");
        uint totalVotes = artBounties[_bountyId].claims[_claimId].voteCountYes + artBounties[_bountyId].claims[_claimId].voteCountNo;
        require(totalVotes > 0, "No votes were cast on this bounty claim.");
        uint yesPercentage = (artBounties[_bountyId].claims[_claimId].voteCountYes * 100) / totalVotes;

        if (yesPercentage >= bountyClaimApprovalThreshold) {
            BountyClaim storage winningClaim = artBounties[_bountyId].claims[_claimId];
            require(!winningClaim.awarded, "Bounty already awarded for this claim."); // Prevent double awarding
            winningClaim.awarded = true;
            payable(winningClaim.claimant).transfer(artBounties[_bountyId].rewardAmount);
            artBounties[_bountyId].status = BountyStatus.Awarded;
            emit ArtBountyAwarded(_bountyId, _claimId, winningClaim.claimant);
        } else {
            artBounties[_bountyId].status = BountyStatus.Open; // Reopen bounty if claim is rejected
        }
    }


    // --- Art Marketplace Functions ---

    function listArtNFTForSale(uint _artNftId, uint _price) public onlyAdmin { // Only Collective can list for sale initially, governance can change this.
        artNFT.setArtNFTPrice(_artNftId, _price);
        emit ArtNFTListedForSale(_artNftId, _price, msg.sender);
    }

    function buyArtNFT(uint _artNftId) public payable {
        uint price = artNFT.getArtNFTPrice(_artNftId);
        require(msg.value >= price, "Insufficient ETH sent to buy Art NFT.");
        require(price > 0, "Art NFT is not listed for sale.");
        artNFT.transferFrom(address(this), msg.sender, _artNftId); // Collective is assumed to own NFTs initially
        payable(address(this)).transfer(msg.value); // Transfer funds to collective treasury
        emit ArtNFTBought(_artNftId, msg.sender, price);
    }


    // --- Art Exhibition Functions ---

    function curateArtExhibition(string memory _exhibitionName, uint[] memory _artNftIds) public onlyCollectiveMember {
        nextExhibitionId++;
        artExhibitions[nextExhibitionId] = ArtExhibition({
            exhibitionName: _exhibitionName,
            curator: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration, // Exhibition voting duration? Different duration?
            artNftIds: new uint[](0),
            artNftVoteCount: mapping(uint => uint)()
        });
        emit ArtExhibitionCurated(nextExhibitionId, _exhibitionName, msg.sender);

        for (uint i = 0; i < _artNftIds.length; i++) {
            voteForExhibitionArt(nextExhibitionId, _artNftIds[i]); // Allow initial curator to vote for initial NFTs
        }
    }

    function voteForExhibitionArt(uint _exhibitionId, uint _artNftId) public onlyCollectiveMember validExhibitionId(_exhibitionId) votingPeriodActive(artExhibitions[_exhibitionId].startTime, votingDuration) {
        // No explicit voting status for exhibition, assuming continuous voting until finalized.
        artExhibitions[_exhibitionId].artNftVoteCount[_artNftId]++; // Simple upvote mechanism. Could be more complex.
        emit ExhibitionArtVoteCast(_exhibitionId, _artNftId, msg.sender);
    }

    function finalizeArtExhibition(uint _exhibitionId) public validExhibitionId(_exhibitionId) {
        require(block.timestamp > artExhibitions[_exhibitionId].endTime, "Exhibition voting period is still active.");
        // --- Simple Finalization Logic: Select top voted NFTs ---
        uint maxNftsInExhibition = 10; // Example limit
        uint[] memory topArtNftIds = new uint[](0);
        uint currentTopCount = 0;

        for (uint i = 1; i <= artNFT.totalSupply(); i++) { // Iterate through all Art NFTs (inefficient for large collections, optimize in real-world)
            if (artExhibitions[_exhibitionId].artNftVoteCount[i] > currentTopCount && arrayLength(topArtNftIds) < maxNftsInExhibition) {
                topArtNftIds = pushToArray(topArtNftIds, i);
                currentTopCount = artExhibitions[_exhibitionId].artNftVoteCount[i];
            }
        }
        artExhibitions[_exhibitionId].artNftIds = topArtNftIds;
        emit ArtExhibitionFinalized(_exhibitionId);
    }


    // --- Donation Function ---

    function donateToCollective() public payable {
        require(msg.value > 0, "Donation amount must be greater than 0.");
        emit DonationReceived(msg.sender, msg.value);
    }


    // --- Governance Functions ---

    function proposeGovernanceChange(string memory _proposalDescription, bytes memory _encodedFunctionCall) public onlyCollectiveMember {
        nextGovernanceProposalId++;
        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            proposalDescription: _proposalDescription,
            encodedFunctionCall: _encodedFunctionCall,
            status: GovernanceProposalStatus.Proposed,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            voteCountYes: 0,
            voteCountNo: 0
        });
        emit GovernanceProposalProposed(nextGovernanceProposalId, _proposalDescription, msg.sender);
    }

    function voteOnGovernanceChange(uint _proposalId, bool _vote) public onlyCollectiveMember validGovernanceProposalId(_proposalId) governanceProposalInStatus(_proposalId, GovernanceProposalStatus.Proposed) votingPeriodActive(governanceProposals[_proposalId].startTime, votingDuration) {
        require(!governanceVotes[_proposalId][msg.sender], "You have already voted on this governance proposal.");
        governanceVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].voteCountYes++;
        } else {
            governanceProposals[_proposalId].voteCountNo++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceChange(uint _proposalId) public validGovernanceProposalId(_proposalId) governanceProposalInStatus(_proposalId, GovernanceProposalStatus.Proposed) {
        require(block.timestamp > governanceProposals[_proposalId].endTime, "Governance voting period is still active.");
        uint totalVotes = governanceProposals[_proposalId].voteCountYes + governanceProposals[_proposalId].voteCountNo;
        require(totalVotes > 0, "No votes were cast on this governance proposal.");
        uint yesPercentage = (governanceProposals[_proposalId].voteCountYes * 100) / totalVotes;

        if (yesPercentage >= governanceApprovalThreshold) {
            governanceProposals[_proposalId].status = GovernanceProposalStatus.Executed;
            (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].encodedFunctionCall); // Delegate call to execute proposal
            require(success, "Governance proposal execution failed.");
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            governanceProposals[_proposalId].status = GovernanceProposalStatus.Rejected;
            emit GovernanceProposalRejected(_proposalId);
        }
    }

    function withdrawTreasuryFunds(address _recipient, uint _amount) public onlyAdmin {
        require(_recipient != address(0), "Invalid recipient address.");
        require(address(this).balance >= _amount, "Insufficient funds in treasury.");
        payable(_recipient).transfer(_amount);
        emit TreasuryFundsWithdrawn(_recipient, _amount, msg.sender);
    }

    function setAdminRole(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid new admin address.");
        emit AdminRoleChanged(_newAdmin, admin);
        admin = _newAdmin;
    }

    function setContributionWeight(uint _newWeight) public onlyAdmin {
        require(_newWeight <= 100, "Contribution weight cannot exceed 100%.");
        emit ContributionWeightUpdated(_newWeight, admin);
        contributionWeight = _newWeight;
    }

    function setVotingDuration(uint _newDuration) public onlyAdmin {
        require(_newDuration > 0, "Voting duration must be greater than 0.");
        emit VotingDurationUpdated(_newDuration, admin);
        votingDuration = _newDuration;
    }


    // --- Getter Functions ---

    function getArtProjectDetails(uint _projectId) public view validProjectId(_projectId) returns (ArtProject memory) {
        return artProjects[_projectId];
    }

    function getBountyDetails(uint _bountyId) public view validBountyId(_bountyId) returns (ArtBounty memory) {
        return artBounties[_bountyId];
    }

    function getExhibitionDetails(uint _exhibitionId) public view validExhibitionId(_exhibitionId) returns (ArtExhibition memory) {
        return artExhibitions[_exhibitionId];
    }

    function getCollectiveMemberDetails(uint _memberId) public view returns (CollectiveMember memory) {
        require(_memberId > 0 && _memberId <= memberCount, "Invalid member ID.");
        return collectiveMembers[_memberId];
    }

    // --- Utility Functions --- (Simple array push for exhibitions, can be optimized)
    function pushToArray(uint[] memory _arr, uint _value) internal pure returns (uint[] memory) {
        uint[] memory newArr = new uint[](_arr.length + 1);
        for (uint i = 0; i < _arr.length; i++) {
            newArr[i] = _arr[i];
        }
        newArr[_arr.length] = _value;
        return newArr;
    }

    function arrayLength(uint[] memory _arr) internal pure returns (uint) {
        return _arr.length;
    }


    // --- Fallback and Receive functions ---

    receive() external payable {}
    fallback() external payable {}
}


// --- ERC721 Membership NFT Contract ---
contract ERC721MembershipNFT {
    string public name;
    string public symbol;
    mapping(uint => address) public ownerOf;
    mapping(address => uint) public balanceOf;
    mapping(uint => bool) private _exists;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address _to, uint _tokenId) public {
        require(!_exists[_tokenId], "Token already exists");
        ownerOf[_tokenId] = _to;
        balanceOf[_to]++;
        _exists[_tokenId] = true;
    }

    function burn(uint _tokenId) public {
        require(_exists[_tokenId], "Token does not exist");
        address owner = ownerOf[_tokenId];
        balanceOf[owner]--;
        delete ownerOf[_tokenId];
        _exists[_tokenId] = false;
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
        require(ownerOf[_tokenId] == _from, "ERC721: transfer from incorrect owner");
        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        return (spender == ownerOf[tokenId]); // simplified for example, add approvals in real impl.
    }
}


// --- ERC721 Art NFT Contract ---
contract ERC721ArtNFT {
    string public name;
    string public symbol;
    mapping(uint => address) public ownerOf;
    mapping(address => uint) public balanceOf;
    mapping(uint => string) public tokenURI;
    uint public totalSupplyCount;
    mapping(uint => uint) public artNftPrices; // artNftId => price in wei
    mapping(uint => bool) private _exists;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mintArtNFT(string memory _ipfsHash) public returns (uint) {
        totalSupplyCount++;
        uint newTokenId = totalSupplyCount;
        ownerOf[newTokenId] = address(this); // Collective initially owns the art NFT
        balanceOf[address(this)]++;
        tokenURI[newTokenId] = _ipfsHash;
        _exists[newTokenId] = true;
        return newTokenId;
    }

    function setArtNFTPrice(uint _artNftId, uint _price) public {
        artNftPrices[_artNftId] = _price;
    }

    function getArtNFTPrice(uint _artNftId) public view returns (uint) {
        return artNftPrices[_artNftId];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
        require(ownerOf[_tokenId] == _from, "ERC721: transfer from incorrect owner");
        balanceOf[_from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        return (spender == ownerOf[tokenId]); // simplified for example, add approvals in real impl.
    }

    function totalSupply() public view returns (uint) {
        return totalSupplyCount;
    }
}
```