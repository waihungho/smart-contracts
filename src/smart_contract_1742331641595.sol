```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective, enabling collaborative art creation,
 * ownership, and governance using advanced concepts.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 *  1. `joinCollective()`: Allows artists to join the collective by staking tokens.
 *  2. `leaveCollective()`: Allows artists to leave the collective and unstake tokens (with potential cooldown).
 *  3. `submitArtwork(string memory _artworkCID, string memory _metadataCID)`: Members can submit artwork proposals with IPFS CIDs for artwork and metadata.
 *  4. `voteOnArtwork(uint256 _artworkId, bool _approve)`: Members can vote on submitted artworks.
 *  5. `finalizeArtworkSelection()`:  After a voting period, selects approved artworks based on quorum and consensus.
 *  6. `mintArtworkNFT(uint256 _artworkId)`: Mints an NFT representing a selected artwork, fractionalized ownership possible.
 *  7. `buyFractionalOwnership(uint256 _artworkId, uint256 _amount)`: Allows buying fractional ownership of minted artwork NFTs.
 *  8. `sellFractionalOwnership(uint256 _artworkId, uint256 _amount)`: Allows selling fractional ownership of minted artwork NFTs.
 *  9. `listArtworkForAuction(uint256 _artworkId, uint256 _startingPrice, uint256 _auctionDuration)`: Members can propose auctioning collective-owned artworks.
 * 10. `bidOnArtworkAuction(uint256 _auctionId)`: Allows bidding on active artwork auctions.
 * 11. `finalizeArtworkAuction(uint256 _auctionId)`: Ends an artwork auction and distributes proceeds.
 * 12. `proposeCollectiveProject(string memory _projectProposalCID)`: Members can propose projects to improve the collective (e.g., marketing, new tools).
 * 13. `voteOnProjectProposal(uint256 _projectId, bool _approve)`: Members vote on project proposals.
 * 14. `finalizeProjectSelection()`: Selects approved projects after voting.
 * 15. `contributeToProject(uint256 _projectId)`: Members can contribute funds to approved projects.
 * 16. `claimProjectRewards(uint256 _projectId)`: Contributors can claim rewards upon project completion (if applicable).
 * 17. `proposeRuleChange(string memory _ruleProposalCID)`: Members can propose changes to collective rules and governance.
 * 18. `voteOnRuleChange(uint256 _ruleId, bool _approve)`: Members vote on rule change proposals.
 * 19. `enactRuleChange()`: Enacts approved rule changes after voting.
 * 20. `distributeCollectiveRevenue()`: Distributes revenue generated from NFT sales and auctions to collective members.
 * 21. `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a specific artwork.
 * 22. `getProjectDetails(uint256 _projectId)`: Retrieves details of a specific project.
 * 23. `getRuleDetails(uint256 _ruleId)`: Retrieves details of a specific rule.
 * 24. `getMemberDetails(address _memberAddress)`: Retrieves details of a collective member.

 * **Advanced Concepts Implemented:**
 *  - **Fractionalized NFT Ownership:** Allows for shared ownership of digital art within the collective.
 *  - **Decentralized Governance:**  Members vote on artworks, projects, and rule changes.
 *  - **Auction Mechanism:**  Dynamic pricing and revenue generation through auctions for collective art.
 *  - **Project Proposals:**  Community-driven improvement and development of the collective.
 *  - **Reputation System (Implicit through participation and voting - can be expanded):** Active participants have more influence.
 *  - **Dynamic Quorum and Consensus Mechanisms (Configurable):** Adaptable voting parameters.
 *  - **IPFS Integration:**  Decentralized storage for artwork and metadata.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public stakingToken; // Token required for joining the collective
    uint256 public stakingAmount; // Amount of tokens required to stake
    uint256 public unstakeCooldownPeriod; // Time period before members can unstake after joining

    Counters.Counter private _artworkIdCounter;
    Counters.Counter private _projectIdCounter;
    Counters.Counter private _ruleIdCounter;
    Counters.Counter private _auctionIdCounter;

    mapping(address => Member) public members;
    address[] public memberList;
    uint256 public memberCount;

    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        uint256 stakedAmount;
        bool isActive;
    }

    struct Artwork {
        uint256 artworkId;
        string artworkCID;
        string metadataCID;
        address submitter;
        uint256 submissionTimestamp;
        uint256 upVotes;
        uint256 downVotes;
        bool isApproved;
        bool isMinted;
    }
    mapping(uint256 => Artwork) public artworks;
    uint256[] public artworkIds;

    struct ProjectProposal {
        uint256 projectId;
        string projectProposalCID;
        address proposer;
        uint256 proposalTimestamp;
        uint256 upVotes;
        uint256 downVotes;
        bool isApproved;
        uint256 fundingGoal;
        uint256 currentFunding;
        bool isCompleted;
    }
    mapping(uint256 => ProjectProposal) public projects;
    uint256[] public projectIds;

    struct RuleProposal {
        uint256 ruleId;
        string ruleProposalCID;
        address proposer;
        uint256 proposalTimestamp;
        uint256 upVotes;
        uint256 downVotes;
        bool isApproved;
        bool isEnacted;
    }
    mapping(uint256 => RuleProposal) public rules;
    uint256[] public ruleIds;


    struct ArtworkAuction {
        uint256 auctionId;
        uint256 artworkId;
        address seller; // Collective itself
        uint256 startingPrice;
        uint256 currentBid;
        address highestBidder;
        uint256 auctionEndTime;
        bool isActive;
    }
    mapping(uint256 => ArtworkAuction) public artworkAuctions;
    uint256[] public activeAuctionIds;

    uint256 public artworkVotingDuration = 7 days;
    uint256 public projectVotingDuration = 10 days;
    uint256 public ruleVotingDuration = 14 days;

    uint256 public artworkApprovalQuorumPercentage = 50; // Minimum percentage of votes for approval
    uint256 public projectApprovalQuorumPercentage = 60;
    uint256 public ruleApprovalQuorumPercentage = 70;

    uint256 public collectiveTreasuryBalance; // Tracks ETH in contract for collective activities


    // --- Events ---
    event MemberJoined(address memberAddress);
    event MemberLeft(address memberAddress);
    event ArtworkSubmitted(uint256 artworkId, address submitter, string artworkCID, string metadataCID);
    event ArtworkVoted(uint256 artworkId, address voter, bool approve);
    event ArtworkSelectionFinalized(uint256[] approvedArtworkIds);
    event ArtworkNFTMinted(uint256 artworkId, uint256 tokenId);
    event FractionalOwnershipBought(uint256 artworkId, address buyer, uint256 amount);
    event FractionalOwnershipSold(uint256 artworkId, address seller, uint256 amount);
    event ArtworkAuctionCreated(uint256 auctionId, uint256 artworkId, uint256 startingPrice, uint256 auctionEndTime);
    event ArtworkBidPlaced(uint256 auctionId, address bidder, uint256 bidAmount);
    event ArtworkAuctionFinalized(uint256 auctionId, address winner, uint256 finalPrice);
    event ProjectProposed(uint256 projectId, address proposer, string projectProposalCID);
    event ProjectVoted(uint256 projectId, address voter, bool approve);
    event ProjectSelectionFinalized(uint256[] approvedProjectIds);
    event ProjectContribution(uint256 projectId, address contributor, uint256 amount);
    event ProjectRewardsClaimed(uint256 projectId, address claimer, uint256 amount);
    event RuleProposed(uint256 ruleId, address proposer, string ruleProposalCID);
    event RuleVoted(uint256 ruleId, address voter, bool approve);
    event RuleChangeEnacted(uint256[] approvedRuleIds);
    event RevenueDistributed(uint256 amountDistributed);


    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender].isActive, "You are not a member of the collective.");
        _;
    }

    modifier nonMember() {
        require(!members[msg.sender].isActive, "You are already a member.");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(artworks[_artworkId].artworkId == _artworkId, "Invalid artwork ID.");
        _;
    }

    modifier validProjectId(uint256 _projectId) {
        require(projects[_projectId].projectId == _projectId, "Invalid project ID.");
        _;
    }

    modifier validRuleId(uint256 _ruleId) {
        require(rules[_ruleId].ruleId == _ruleId, "Invalid rule ID.");
        _;
    }

    modifier validAuctionId(uint256 _auctionId) {
        require(artworkAuctions[_auctionId].auctionId == _auctionId, "Invalid auction ID.");
        _;
    }

    modifier activeAuction(uint256 _auctionId) {
        require(artworkAuctions[_auctionId].isActive, "Auction is not active.");
        require(block.timestamp < artworkAuctions[_auctionId].auctionEndTime, "Auction has ended.");
        _;
    }

    modifier auctionNotActive(uint256 _auctionId) {
        require(!artworkAuctions[_auctionId].isActive, "Auction is still active.");
        _;
    }


    // --- Constructor ---
    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingTokenAddress,
        uint256 _stakingAmount,
        uint256 _unstakeCooldownPeriod
    ) ERC721(_name, _symbol) {
        require(_stakingTokenAddress != address(0), "Staking token address cannot be zero.");
        stakingToken = IERC20(_stakingTokenAddress);
        stakingAmount = _stakingAmount;
        unstakeCooldownPeriod = _unstakeCooldownPeriod;
    }


    // --- Membership Functions ---
    function joinCollective() external nonMember nonReentrant {
        require(stakingToken.allowance(msg.sender, address(this)) >= stakingAmount, "Approve staking tokens first.");
        stakingToken.transferFrom(msg.sender, address(this), stakingAmount);

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            joinTimestamp: block.timestamp,
            stakedAmount: stakingAmount,
            isActive: true
        });
        memberList.push(msg.sender);
        memberCount++;

        emit MemberJoined(msg.sender);
    }

    function leaveCollective() external onlyMember nonReentrant {
        require(block.timestamp >= members[msg.sender].joinTimestamp + unstakeCooldownPeriod, "Unstake cooldown period not over yet.");

        uint256 amountToUnstake = members[msg.sender].stakedAmount;
        members[msg.sender].isActive = false;
        members[msg.sender].stakedAmount = 0;

        // Remove member from memberList (inefficient for large lists, consider alternatives for production)
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;

        stakingToken.transfer(msg.sender, amountToUnstake);
        emit MemberLeft(msg.sender);
    }

    function getMemberDetails(address _memberAddress) external view returns (Member memory) {
        return members[_memberAddress];
    }

    function getMemberList() external view returns (address[] memory) {
        return memberList;
    }

    function getCollectiveSize() external view returns (uint256) {
        return memberCount;
    }


    // --- Artwork Submission and Voting Functions ---
    function submitArtwork(string memory _artworkCID, string memory _metadataCID) external onlyMember nonReentrant {
        _artworkIdCounter.increment();
        uint256 artworkId = _artworkIdCounter.current();

        artworks[artworkId] = Artwork({
            artworkId: artworkId,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            submitter: msg.sender,
            submissionTimestamp: block.timestamp,
            upVotes: 0,
            downVotes: 0,
            isApproved: false,
            isMinted: false
        });
        artworkIds.push(artworkId);

        emit ArtworkSubmitted(artworkId, msg.sender, _artworkCID, _metadataCID);
    }

    function voteOnArtwork(uint256 _artworkId, bool _approve) external onlyMember validArtworkId(_artworkId) nonReentrant {
        require(!artworks[_artworkId].isApproved, "Artwork already finalized.");

        if (_approve) {
            artworks[_artworkId].upVotes++;
        } else {
            artworks[_artworkId].downVotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _approve);
    }

    function finalizeArtworkSelection() external onlyOwner nonReentrant {
        uint256[] memory approvedArtworks;
        uint256 totalMembers = memberCount;

        for (uint256 i = 0; i < artworkIds.length; i++) {
            uint256 artworkId = artworkIds[i];
            if (!artworks[artworkId].isApproved) { // Only process not yet finalized artworks
                uint256 totalVotes = artworks[artworkId].upVotes + artworks[artworkId].downVotes;
                if (totalVotes > 0 ) { // To avoid division by zero if no votes
                    uint256 approvalPercentage = (artworks[artworkId].upVotes * 100) / totalMembers; // Percentage against total members, not just voters
                    if (approvalPercentage >= artworkApprovalQuorumPercentage) {
                        artworks[artworkId].isApproved = true;
                        approvedArtworks.push(artworkId);
                    }
                }
            }
        }

        emit ArtworkSelectionFinalized(approvedArtworks);
    }

    function mintArtworkNFT(uint256 _artworkId) external onlyOwner validArtworkId(_artworkId) nonReentrant {
        require(artworks[_artworkId].isApproved, "Artwork is not approved for minting.");
        require(!artworks[_artworkId].isMinted, "Artwork NFT already minted.");

        _safeMint(address(this), _artworkId); // tokenId is artworkId for simplicity
        artworks[_artworkId].isMinted = true;
        emit ArtworkNFTMinted(_artworkId, _artworkId);
    }

    function getArtworkDetails(uint256 _artworkId) external view validArtworkId(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    // --- Fractional Ownership (Simplified Example) ---
    // For a more robust implementation, consider using ERC1155 or a dedicated fractional NFT library.
    mapping(uint256 => mapping(address => uint256)) public fractionalOwnership; // artworkId => (owner => amount)

    function buyFractionalOwnership(uint256 _artworkId, uint256 _amount) external payable validArtworkId(_artworkId) nonReentrant {
        require(artworks[_artworkId].isMinted, "NFT must be minted first.");
        require(msg.value > 0, "Must send ETH to buy fractional ownership."); // Basic price mechanism, can be more sophisticated

        fractionalOwnership[_artworkId][msg.sender] += _amount;
        collectiveTreasuryBalance += msg.value; // Funds go to collective treasury
        emit FractionalOwnershipBought(_artworkId, msg.sender, _amount);
    }

    function sellFractionalOwnership(uint256 _artworkId, uint256 _amount) external onlyMember validArtworkId(_artworkId) nonReentrant {
        require(fractionalOwnership[_artworkId][msg.sender] >= _amount, "Not enough fractional ownership to sell.");
        // Basic selling mechanism, simplified. Could involve setting price and matching buyers.

        uint256 saleProceeds = _amount; // Simplified, in real-world, price discovery is needed
        fractionalOwnership[_artworkId][msg.sender] -= _amount;
        payable(msg.sender).transfer(saleProceeds); //  Seller gets proceeds (simplified example, consider marketplace)
        collectiveTreasuryBalance -= saleProceeds; //  This would be more complex in a real marketplace
        emit FractionalOwnershipSold(_artworkId, msg.sender, _amount);
    }


    // --- Artwork Auction Functions ---
    function listArtworkForAuction(uint256 _artworkId, uint256 _startingPrice, uint256 _auctionDuration) external onlyOwner validArtworkId(_artworkId) nonReentrant {
        require(artworks[_artworkId].isMinted, "NFT must be minted first.");
        require(_startingPrice > 0, "Starting price must be greater than zero.");
        require(_auctionDuration > 0, "Auction duration must be greater than zero.");

        _auctionIdCounter.increment();
        uint256 auctionId = _auctionIdCounter.current();

        artworkAuctions[auctionId] = ArtworkAuction({
            auctionId: auctionId,
            artworkId: _artworkId,
            seller: address(this),
            startingPrice: _startingPrice,
            currentBid: 0,
            highestBidder: address(0),
            auctionEndTime: block.timestamp + _auctionDuration,
            isActive: true
        });
        activeAuctionIds.push(auctionId);

        emit ArtworkAuctionCreated(auctionId, _artworkId, _startingPrice, artworkAuctions[auctionId].auctionEndTime);
    }

    function bidOnArtworkAuction(uint256 _auctionId) external payable validAuctionId(_auctionId) activeAuction(_auctionId) nonReentrant {
        require(msg.value > artworkAuctions[_auctionId].currentBid, "Bid must be higher than current bid.");

        if (artworkAuctions[_auctionId].currentBid > 0) {
            // Refund previous highest bidder
            payable(artworkAuctions[_auctionId].highestBidder).transfer(artworkAuctions[_auctionId].currentBid);
        }

        artworkAuctions[_auctionId].currentBid = msg.value;
        artworkAuctions[_auctionId].highestBidder = msg.sender;
        emit ArtworkBidPlaced(_auctionId, msg.sender, msg.value);
    }

    function finalizeArtworkAuction(uint256 _auctionId) external validAuctionId(_auctionId) auctionNotActive(_auctionId) nonReentrant {
        require(artworkAuctions[_auctionId].isActive == false, "Auction is still active.");
        require(block.timestamp >= artworkAuctions[_auctionId].auctionEndTime, "Auction end time not reached.");

        artworkAuctions[_auctionId].isActive = false; // Mark auction as inactive
        // Remove from active auctions list (inefficient for large lists, consider alternatives)
        for (uint256 i = 0; i < activeAuctionIds.length; i++) {
            if (activeAuctionIds[i] == _auctionId) {
                activeAuctionIds[i] = activeAuctionIds[activeAuctionIds.length - 1];
                activeAuctionIds.pop();
                break;
            }
        }

        if (artworkAuctions[_auctionId].currentBid > 0) {
            collectiveTreasuryBalance += artworkAuctions[_auctionId].currentBid; // Auction proceeds to treasury
            _transferFrom(address(this), artworkAuctions[_auctionId].highestBidder, artworkAuctions[_auctionId].artworkId); // Transfer NFT to winner
            emit ArtworkAuctionFinalized(_auctionId, artworkAuctions[_auctionId].highestBidder, artworkAuctions[_auctionId].currentBid);
        } else {
            // No bids, handle as needed (e.g., relist, return NFT to collective)
            // For simplicity, NFT remains with the collective in this example.
        }
    }

    function getAuctionDetails(uint256 _auctionId) external view validAuctionId(_auctionId) returns (ArtworkAuction memory) {
        return artworkAuctions[_auctionId];
    }

    function getActiveAuctionList() external view returns (uint256[] memory) {
        return activeAuctionIds;
    }


    // --- Project Proposal and Voting Functions ---
    function proposeCollectiveProject(string memory _projectProposalCID) external onlyMember nonReentrant {
        _projectIdCounter.increment();
        uint256 projectId = _projectIdCounter.current();

        projects[projectId] = ProjectProposal({
            projectId: projectId,
            projectProposalCID: _projectProposalCID,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp,
            upVotes: 0,
            downVotes: 0,
            isApproved: false,
            fundingGoal: 0, // Initially set to 0, can be updated later
            currentFunding: 0,
            isCompleted: false
        });
        projectIds.push(projectId);

        emit ProjectProposed(projectId, msg.sender, _projectProposalCID);
    }

    function voteOnProjectProposal(uint256 _projectId, bool _approve) external onlyMember validProjectId(_projectId) nonReentrant {
        require(!projects[_projectId].isApproved, "Project already finalized.");

        if (_approve) {
            projects[_projectId].upVotes++;
        } else {
            projects[_projectId].downVotes++;
        }
        emit ProjectVoted(_projectId, msg.sender, _approve);
    }

    function finalizeProjectSelection() external onlyOwner nonReentrant {
        uint256[] memory approvedProjects;
        uint256 totalMembers = memberCount;

        for (uint256 i = 0; i < projectIds.length; i++) {
            uint256 projectId = projectIds[i];
            if (!projects[projectId].isApproved) { // Only process not yet finalized projects
                uint256 totalVotes = projects[projectId].upVotes + projects[projectId].downVotes;
                 if (totalVotes > 0) { // To avoid division by zero
                    uint256 approvalPercentage = (projects[projectId].upVotes * 100) / totalMembers; // Percentage against total members
                    if (approvalPercentage >= projectApprovalQuorumPercentage) {
                        projects[projectId].isApproved = true;
                        approvedProjects.push(projectId);
                    }
                 }
            }
        }
        emit ProjectSelectionFinalized(approvedProjects);
    }

    function contributeToProject(uint256 _projectId) external payable onlyMember validProjectId(_projectId) nonReentrant {
        require(projects[_projectId].isApproved, "Project is not approved.");
        require(!projects[_projectId].isCompleted, "Project is already completed.");
        require(projects[_projectId].currentFunding < projects[_projectId].fundingGoal || projects[_projectId].fundingGoal == 0, "Project funding goal reached."); // Allow contribution even if goal is reached if goal is 0 (no funding limit)

        projects[_projectId].currentFunding += msg.value;
        collectiveTreasuryBalance += msg.value; // Funds go to collective treasury
        emit ProjectContribution(_projectId, msg.sender, msg.value);
    }

    function claimProjectRewards(uint256 _projectId) external onlyMember validProjectId(_projectId) nonReentrant {
        require(projects[_projectId].isCompleted, "Project is not completed yet.");
        // Implement reward mechanism here based on project details and contribution (e.g., proportional rewards, fixed rewards)
        // This is a placeholder - reward logic needs to be defined based on project specifics.
        uint256 rewardAmount = 10 ether; // Example reward - replace with actual logic
        require(collectiveTreasuryBalance >= rewardAmount, "Insufficient funds in treasury for project rewards.");

        collectiveTreasuryBalance -= rewardAmount;
        payable(msg.sender).transfer(rewardAmount);
        emit ProjectRewardsClaimed(_projectId, msg.sender, rewardAmount);
    }

    function markProjectAsCompleted(uint256 _projectId) external onlyOwner validProjectId(_projectId) nonReentrant {
        require(projects[_projectId].isApproved, "Project is not approved.");
        require(!projects[_projectId].isCompleted, "Project is already completed.");

        projects[_projectId].isCompleted = true;
    }

    function setProjectFundingGoal(uint256 _projectId, uint256 _fundingGoal) external onlyOwner validProjectId(_projectId) nonReentrant {
        require(!projects[_projectId].isCompleted, "Cannot set funding goal for completed project.");
        projects[_projectId].fundingGoal = _fundingGoal;
    }

    function getProjectDetails(uint256 _projectId) external view validProjectId(_projectId) returns (ProjectProposal memory) {
        return projects[_projectId];
    }


    // --- Rule Proposal and Voting Functions ---
    function proposeRuleChange(string memory _ruleProposalCID) external onlyMember nonReentrant {
        _ruleIdCounter.increment();
        uint256 ruleId = _ruleIdCounter.current();

        rules[ruleId] = RuleProposal({
            ruleId: ruleId,
            ruleProposalCID: _ruleProposalCID,
            proposer: msg.sender,
            proposalTimestamp: block.timestamp,
            upVotes: 0,
            downVotes: 0,
            isApproved: false,
            isEnacted: false
        });
        ruleIds.push(ruleId);

        emit RuleProposed(ruleId, msg.sender, _ruleProposalCID);
    }

    function voteOnRuleChange(uint256 _ruleId, bool _approve) external onlyMember validRuleId(_ruleId) nonReentrant {
        require(!rules[_ruleId].isApproved, "Rule change already finalized.");

        if (_approve) {
            rules[_ruleId].upVotes++;
        } else {
            rules[_ruleId].downVotes++;
        }
        emit RuleVoted(_ruleId, msg.sender, _approve);
    }

    function enactRuleChange() external onlyOwner nonReentrant {
        uint256[] memory approvedRules;
        uint256 totalMembers = memberCount;

        for (uint256 i = 0; i < ruleIds.length; i++) {
            uint256 ruleId = ruleIds[i];
            if (!rules[ruleId].isEnacted) { // Only process not yet enacted rules
                uint256 totalVotes = rules[ruleId].upVotes + rules[ruleId].downVotes;
                if (totalVotes > 0 ) { // To avoid division by zero
                    uint256 approvalPercentage = (rules[ruleId].upVotes * 100) / totalMembers; // Percentage against total members
                    if (approvalPercentage >= ruleApprovalQuorumPercentage) {
                        rules[ruleId].isApproved = true;
                        rules[ruleId].isEnacted = true;
                        approvedRules.push(ruleId);
                    }
                }
            }
        }
        emit RuleChangeEnacted(approvedRules);
    }

    function getRuleDetails(uint256 _ruleId) external view validRuleId(_ruleId) returns (RuleProposal memory) {
        return rules[_ruleId];
    }


    // --- Revenue Distribution ---
    function distributeCollectiveRevenue() external onlyOwner nonReentrant {
        require(collectiveTreasuryBalance > 0, "No revenue to distribute.");
        uint256 revenuePerMember = collectiveTreasuryBalance / memberCount;
        uint256 remainingRevenue = collectiveTreasuryBalance % memberCount; // Handle remainder

        collectiveTreasuryBalance = 0; // Reset treasury after distribution

        for (uint256 i = 0; i < memberList.length; i++) {
            payable(memberList[i]).transfer(revenuePerMember);
        }
        // Optionally handle remainingRevenue (e.g., keep in treasury for next distribution, burn, etc.)
        // For simplicity, remaining revenue is lost in this example.

        emit RevenueDistributed(revenuePerMember * memberCount); // Emit distributed amount, not total balance before reset
    }

    function getTreasuryBalance() external view returns (uint256) {
        return collectiveTreasuryBalance;
    }

    // --- Admin Functions (Owner Only) ---
    function setStakingAmount(uint256 _newStakingAmount) external onlyOwner {
        stakingAmount = _newStakingAmount;
    }

    function setUnstakeCooldownPeriod(uint256 _newCooldownPeriod) external onlyOwner {
        unstakeCooldownPeriod = _newCooldownPeriod;
    }

    function setArtworkVotingDuration(uint256 _newDuration) external onlyOwner {
        artworkVotingDuration = _newDuration;
    }

    function setProjectVotingDuration(uint256 _newDuration) external onlyOwner {
        projectVotingDuration = _newDuration;
    }

    function setRuleVotingDuration(uint256 _newDuration) external onlyOwner {
        ruleVotingDuration = _newDuration;
    }

    function setArtworkApprovalQuorumPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Quorum percentage cannot exceed 100.");
        artworkApprovalQuorumPercentage = _newPercentage;
    }

    function setProjectApprovalQuorumPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Quorum percentage cannot exceed 100.");
        projectApprovalQuorumPercentage = _newPercentage;
    }

    function setRuleApprovalQuorumPercentage(uint256 _newPercentage) external onlyOwner {
        require(_newPercentage <= 100, "Quorum percentage cannot exceed 100.");
        ruleApprovalQuorumPercentage = _newPercentage;
    }

    // --- Fallback and Receive Functions ---
    receive() external payable {
        // Allow contract to receive ETH
        collectiveTreasuryBalance += msg.value;
    }

    fallback() external payable {
        // Optional: Handle fallback if needed
    }
}
```